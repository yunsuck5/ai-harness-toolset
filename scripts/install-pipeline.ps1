[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('install', 'update-source', 'update-current', 'restore')]
    [string] $Action,

    [Parameter(Mandatory = $true)]
    [string] $InstallArea,

    [ValidateSet('git-url', 'local-clone')]
    [string] $InstallMode,

    [string] $RepoUrl,
    [string] $SourcePath,
    [string] $Branch,
    [string] $Remote,
    [string] $Ref,

    [string] $ProjectRoot,
    [string] $RuntimeToolRoot,

    [switch] $AllowDogfoodSource
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'lib/encoding.ps1')
. (Join-Path $PSScriptRoot 'lib/path.ps1')
. (Join-Path $PSScriptRoot 'lib/install-pipeline-core.ps1')

# Temp-only entry: reject any InstallArea that points at the global stable
# install area or any path under %USERPROFILE%\.claude or %USERPROFILE%\.codex.
# This entry is a Step 3 skeleton — actual global apply is a separate explicit
# user-approved scope per STEP3 guide §10.6 / §12.10 and GLOBAL_ADOPTION_DECISION.md §6.
function Assert-NotForbiddenInstallArea {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path
    )

    $userProfile = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::UserProfile)
    $forbidden = @()
    if (-not [string]::IsNullOrEmpty($userProfile)) {
        $forbidden += (Join-Path $userProfile '.claude')
        $forbidden += (Join-Path $userProfile '.codex')
    }
    $stable = Get-StableToolRootCandidate
    if (-not [string]::IsNullOrEmpty($stable)) {
        $forbidden += $stable
        $forbidden += (Split-Path -Parent $stable)
    }

    $full = [System.IO.Path]::GetFullPath($Path)
    $cmp = [System.StringComparison]::OrdinalIgnoreCase
    foreach ($fb in $forbidden) {
        if ([string]::IsNullOrEmpty($fb)) { continue }
        $fbFull = [System.IO.Path]::GetFullPath($fb)
        if ([string]::Equals($full, $fbFull, $cmp)) {
            throw "install-pipeline: FAIL InstallArea is a forbidden path for this temp-only skeleton: $full (matches $fbFull). Pick a temp directory."
        }
        $prefix = $fbFull.TrimEnd([System.IO.Path]::DirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar
        if ($full.StartsWith($prefix, $cmp)) {
            throw "install-pipeline: FAIL InstallArea is under a forbidden global / user instruction scope: $full (descendant of $fbFull). Pick a temp directory."
        }
    }
}

try {
    Assert-NotForbiddenInstallArea -Path $InstallArea
}
catch {
    Write-Host $_.Exception.Message
    exit 1
}

if (-not (Test-Path -LiteralPath $InstallArea -PathType Container)) {
    Write-Host ('install-pipeline: FAIL InstallArea directory not found: {0}. Operator must create it explicitly (no auto-create at temp-only skeleton).' -f $InstallArea)
    exit 1
}

# Resolve invocation context: D1 runtime ToolRoot + D9 ProjectRoot.
# This is invocation context, separate from the resolved tuple field `toolRoot`
# (= source-side canonical local ToolRoot per parent §6 Layer 1 / §11.1).
$project = Get-ProjectRoot -ProjectRoot $ProjectRoot

$runtimeTool = '(unresolved)'
if (-not [string]::IsNullOrEmpty($RuntimeToolRoot)) {
    if (-not (Test-Path -LiteralPath $RuntimeToolRoot -PathType Container)) {
        Write-Host ('install-pipeline: FAIL -RuntimeToolRoot directory not found: {0}' -f $RuntimeToolRoot)
        exit 1
    }
    $runtimeTool = [System.IO.Path]::GetFullPath($RuntimeToolRoot)
}
else {
    try {
        $runtimeTool = Get-ToolRoot -ToolRoot $null -ProjectRoot $project
    }
    catch {
        # Channel chain unresolved is acceptable in this skeleton context (the
        # skeleton's pipeline does not require a resolvable D1 ToolRoot to operate
        # on a temp InstallArea). The unresolved status is reported back to the
        # operator so the channel state is visible, not silently hidden.
        $runtimeTool = '(unresolved: ' + $_.Exception.Message + ')'
    }
}

# Read existing install metadata (for update / restore).
$existing = $null
if ($Action -in @('update-source', 'update-current', 'restore')) {
    try {
        $existing = Read-InstallPipelineMetadata -InstallArea $InstallArea
    }
    catch {
        Write-Host ('install-pipeline: FAIL {0}' -f $_.Exception.Message)
        exit 1
    }
    if ($null -eq $existing) {
        Write-Host ("install-pipeline: FAIL {0} requires existing install metadata at {1}. Run -Action install first." -f $Action, (Get-InstallPipelineMetadataPath -InstallArea $InstallArea))
        exit 1
    }
}

# Build invocation params hashtable for source-cut detection.
$invocation = @{}
if (-not [string]::IsNullOrEmpty($InstallMode)) { $invocation['installMode'] = $InstallMode }
if (-not [string]::IsNullOrEmpty($RepoUrl))     { $invocation['repoUrl']     = $RepoUrl }
if (-not [string]::IsNullOrEmpty($SourcePath))  { $invocation['sourcePath']  = [System.IO.Path]::GetFullPath($SourcePath) }
if (-not [string]::IsNullOrEmpty($Branch))      { $invocation['branch']      = $Branch }
if (-not [string]::IsNullOrEmpty($Remote))      { $invocation['remote']      = $Remote }

# Source-cut detection — resolver level only; never auto-resolve.
if ($null -ne $existing) {
    $cut = Test-InstallPipelineSourceCut -Metadata $existing -InvocationParams $invocation
    if ($cut) {
        Write-Host 'install-pipeline: STOP source-cut detected. Invocation params differ from install metadata in one or more of: installMode / repoUrl / sourcePath / toolRoot / branch / remote.'
        Write-Host 'install-pipeline: source-cut handling is a separate explicit user-approved scope and is not auto-resolved here. Reconcile metadata and invocation, or run a separate scoped source-cut workflow.'
        exit 1
    }
}

# Resolve mode and sourceLocation.
$mode = $InstallMode
if ([string]::IsNullOrEmpty($mode) -and $null -ne $existing) {
    $mode = [string]$existing.installMode
}
if ([string]::IsNullOrEmpty($mode)) {
    Write-Host 'install-pipeline: FAIL -InstallMode is required for the install action; for update / restore the existing metadata must declare it.'
    exit 1
}

$sourceLoc = ''
if ($mode -eq 'git-url') {
    if (-not [string]::IsNullOrEmpty($RepoUrl)) { $sourceLoc = $RepoUrl }
    elseif ($null -ne $existing)                { $sourceLoc = [string]$existing.repoUrl }
}
elseif ($mode -eq 'local-clone') {
    if (-not [string]::IsNullOrEmpty($SourcePath)) { $sourceLoc = [System.IO.Path]::GetFullPath($SourcePath) }
    elseif ($null -ne $existing)                   { $sourceLoc = [string]$existing.sourcePath }
}

if ([string]::IsNullOrEmpty($sourceLoc)) {
    Write-Host ('install-pipeline: FAIL could not resolve sourceLocation. Provide -RepoUrl (git-url) or -SourcePath (local-clone), or run after metadata install.')
    exit 1
}

# Dogfooding mutation protection for update-source.
if ($Action -eq 'update-source') {
    $isDogfood = Test-InstallPipelineDogfoodingSource -SourcePath $sourceLoc -ProjectRoot $project
    if ($isDogfood -and -not $AllowDogfoodSource) {
        Write-Host ('install-pipeline: FAIL update-source against a dogfooding source (= ProjectRoot is a source repo) is refused by default to prevent silent mutation of user dev checkout.')
        Write-Host ('install-pipeline: ProjectRoot={0} SourcePath={1}. Pass -AllowDogfoodSource only when you explicitly accept that source-side fetch/pull may be performed against your dev checkout in a future implementation.' -f $project, $sourceLoc)
        exit 1
    }
}

# Resolve ref. install / update-* / restore have different ref policies.
$refSha = ''
$refKind = 'commit'
try {
    switch ($Action) {
        'restore' {
            if ([string]::IsNullOrEmpty($Ref)) {
                throw "install-pipeline: FAIL restore action requires -Ref <commit|tag|branch>. Metadata-derived known-good fallback is forbidden (STEP3 guide §11.4 / §12.3)."
            }
            $refSha  = Resolve-InstallPipelineRef -SourceLocation $sourceLoc -Ref $Ref
            $refKind = if ($Ref -match '^[0-9a-f]{7,40}$') { 'commit' } else { 'unknown' }
        }
        default {
            # install / update-source / update-current — resolve current source HEAD.
            $refSha  = Get-InstallPipelineSourceHead -SourceLocation $sourceLoc
            $refKind = 'commit'
        }
    }
}
catch {
    Write-Host $_.Exception.Message
    exit 1
}

# sourceUpdatePolicy: update-source flags fetch-and-update; others are read-current-only.
# In this temp-only skeleton no network fetch is actually performed; the policy is
# recorded so a future implementation distinguishes the two semantics deterministically.
$policy = if ($Action -eq 'update-source') { 'fetch-and-update' } else { 'read-current-only' }

# Build resolved tuple. tuple.toolRoot = source-side canonical local ToolRoot (Layer 1).
$tuple = New-InstallPipelineTuple `
    -Action $Action `
    -InstallMode $mode `
    -SourceLocation $sourceLoc `
    -ResolvedRefSha $refSha `
    -RefKind $refKind `
    -ToolRoot ([System.IO.Path]::GetFullPath($sourceLoc)) `
    -ProjectRoot $project `
    -SourceUpdatePolicy $policy `
    -SourceCutDetected $false

try {
    Invoke-InstallPipelineDispatch -Tuple $tuple -InstallArea $InstallArea -Branch $Branch -Remote $Remote
}
catch {
    Write-Host ('install-pipeline: FAIL dispatch: {0}' -f $_.Exception.Message)
    exit 1
}

$verifyResult = Invoke-InstallPipelineVerify -InstallArea $InstallArea
if (-not $verifyResult.ok) {
    Write-Host 'install-pipeline: FAIL verify reported errors:'
    foreach ($e in $verifyResult.errors) {
        Write-Host ("  - {0}" -f $e)
    }
    exit 1
}

Write-Host ('install-pipeline: PASS action={0} installArea={1} sourceLocation={2} resolvedRefSha={3} sourceUpdatePolicy={4}' -f $Action, $InstallArea, $sourceLoc, $refSha, $policy)
Write-Host ('install-pipeline: invocation-context runtimeToolRoot={0} projectRoot={1}' -f $runtimeTool, $project)
Write-Host ('install-pipeline: tuple-toolRoot (source-side canonical local ToolRoot, parent §6 Layer 1) = {0}' -f ([System.IO.Path]::GetFullPath($sourceLoc)))
exit 0
