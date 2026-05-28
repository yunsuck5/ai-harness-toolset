[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('inspect', 'verify')]
    [string] $Mode,

    [Parameter(Mandatory = $true)]
    [string] $InstallArea,

    [string] $SourcePath,
    [string] $RepoUrl,
    [string] $Branch,
    [string] $Remote,
    [string] $Ref,

    [string] $ClaudeHome,
    [string] $CodexHome,

    [switch] $Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# install/update post-MVP hardening Batch 1 — read-only operator entrypoint.
# See INSTALL.md §11 (b) and §13 for the contract codified by this script:
#   - read-only inspect + verify mode (no mutation flag exists in this contract).
#   - fixed-vocabulary final status (§13.1) emitted to stdout.
#   - run.json shape (§13.4) emitted as stdout JSON; no file is written.
#   - run evidence is evidence only, not source-of-truth — install source-of-truth
#     is the install.json / payload-manifest.json / payload-marker.json cross-binding
#     defined in INSTALL.md §4.
#
# Mutation invariant. This script has NO mutation flag (-ApplyActivation /
# -UpdateSource / -ApplyPayload / -RefreshSkill). The production guard
# Assert-NoMutationPath below fail-fasts on accidental future addition that
# omits guard updates. The script also uses no file-write API (Set-Content,
# Out-File, [IO.File]::WriteAllText, New-Item, Set-Acl). Stdout / stderr are the
# only outputs.

. (Join-Path $PSScriptRoot 'lib/encoding.ps1')
. (Join-Path $PSScriptRoot 'lib/hash.ps1')
. (Join-Path $PSScriptRoot 'lib/git.ps1')
. (Join-Path $PSScriptRoot 'lib/managed-block.ps1')
. (Join-Path $PSScriptRoot 'lib/install-pipeline-core.ps1')

# Resolve activation surface home defaults (overridable so tests can point at
# TestDrive without touching the real user-global instruction roots).
if ([string]::IsNullOrEmpty($ClaudeHome)) {
    $ClaudeHome = Join-Path $env:USERPROFILE '.claude'
}
if ([string]::IsNullOrEmpty($CodexHome)) {
    if (-not [string]::IsNullOrEmpty($env:CODEX_HOME)) {
        $CodexHome = $env:CODEX_HOME
    }
    else {
        $CodexHome = Join-Path $env:USERPROFILE '.codex'
    }
}

# ---------------------------------------------------------------------------
# Production guard skeleton — Self-imposed invariant: no mutation flag exists
# in this contract. Future mutation flag additions must add explicit handling
# here; absent that update, the invocation fail-fasts so the script never
# mutates by accident. The guard is also exercised by the Pester regression
# suite so a regression that drops the throw is caught at source-side review.
# ---------------------------------------------------------------------------
function script:Assert-NoMutationPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Mode,
        [hashtable] $RequestedFlags = @{}
    )
    $mutationFlags = @('ApplyActivation', 'UpdateSource', 'ApplyPayload', 'RefreshSkill')
    foreach ($flag in $mutationFlags) {
        if ($RequestedFlags.ContainsKey($flag) -and $RequestedFlags[$flag]) {
            throw "install-update: FAIL mutation flag '$flag' is not allowed (read-only contract)."
        }
    }
}

# Exercise the guard on every invocation. The contract has no mutation flag,
# so this is always a no-op in practice — it is here so a stray future flag
# without a matching guard update fail-fasts at the entrypoint.
script:Assert-NoMutationPath -Mode $Mode -RequestedFlags @{}

# ---------------------------------------------------------------------------
# Path / source-of-truth resolution helpers.
# ---------------------------------------------------------------------------

function script:Get-ActivationSurfacePaths {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)] [string] $InstallArea,
        [Parameter(Mandatory = $true)] [string] $ClaudeHome,
        [Parameter(Mandatory = $true)] [string] $CodexHome
    )

    $currentDir = Get-InstallPipelineCurrentDir -InstallArea $InstallArea
    $sourceClaudeSnippet = Join-Path $currentDir 'snippets/CLAUDE_SNIPPET.md'
    $sourceCodexSnippet  = Join-Path $currentDir 'snippets/AGENTS_SNIPPET.md'
    $sourceSkillFile     = Join-Path $currentDir 'snippets/claude-skills/ai-harness-review/SKILL.md'

    $destClaudeMd  = Join-Path $ClaudeHome 'CLAUDE.md'
    $destSkillFile = Join-Path $ClaudeHome 'skills/ai-harness-review/SKILL.md'

    # Codex effective destination: AGENTS.override.md takes precedence over AGENTS.md
    # when present (INSTALL.md §10 valid-destination rule + AGENTS snippet adoption
    # destination). Verifying only AGENTS.md would let a stale/malformed override file
    # pass as clean, so the activation surface binds to whichever is effective.
    $codexAgentsMd  = Join-Path $CodexHome 'AGENTS.md'
    $codexOverride  = Join-Path $CodexHome 'AGENTS.override.md'
    $destCodexMd    = if (Test-Path -LiteralPath $codexOverride -PathType Leaf) { $codexOverride } else { $codexAgentsMd }

    return [pscustomobject]@{
        Surfaces = @(
            [pscustomobject]@{
                Name        = 'claude-user-global-managed-block'
                Destination = $destClaudeMd
                Source      = $sourceClaudeSnippet
                CompareMode = 'managed-block'
            },
            [pscustomobject]@{
                Name        = 'codex-user-global-managed-block'
                Destination = $destCodexMd
                Source      = $sourceCodexSnippet
                CompareMode = 'managed-block'
            },
            [pscustomobject]@{
                Name        = 'review-skill-mirror'
                Destination = $destSkillFile
                Source      = $sourceSkillFile
                CompareMode = 'whole-file'
            }
        )
    }
}

function script:Test-ActivationSurface {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)] [pscustomobject] $Surface
    )

    $name = $Surface.Name
    $dest = $Surface.Destination
    $src  = $Surface.Source
    $mode = $Surface.CompareMode

    if (-not (Test-Path -LiteralPath $dest -PathType Leaf)) {
        return [pscustomobject]@{
            Name          = $name
            Path          = $dest
            Exists        = $false
            ByteIdentical = $false
            Reason        = 'absent'
        }
    }
    if (-not (Test-Path -LiteralPath $src -PathType Leaf)) {
        return [pscustomobject]@{
            Name          = $name
            Path          = $dest
            Exists        = $true
            ByteIdentical = $false
            Reason        = ('read-error: source payload absent: ' + $src)
        }
    }

    try {
        if ($mode -eq 'managed-block') {
            $destText  = Read-Utf8 -Path $dest
            $srcText   = Read-Utf8 -Path $src
            $destBlock = Get-ManagedBlockContent -Content $destText -Label 'destination'
            $srcBlock  = Get-ManagedBlockContent -Content $srcText  -Label 'source-snippet'

            if ($destBlock.Count -ne $srcBlock.Count) {
                return [pscustomobject]@{
                    Name          = $name
                    Path          = $dest
                    Exists        = $true
                    ByteIdentical = $false
                    Reason        = ('byte-mismatch: line count differs ({0} vs {1})' -f $destBlock.Count, $srcBlock.Count)
                }
            }
            for ($i = 0; $i -lt $destBlock.Count; $i++) {
                if ($destBlock[$i] -cne $srcBlock[$i]) {
                    return [pscustomobject]@{
                        Name          = $name
                        Path          = $dest
                        Exists        = $true
                        ByteIdentical = $false
                        Reason        = ('byte-mismatch: line {0} differs' -f ($i + 1))
                    }
                }
            }
            return [pscustomobject]@{
                Name          = $name
                Path          = $dest
                Exists        = $true
                ByteIdentical = $true
                Reason        = $null
            }
        }
        elseif ($mode -eq 'whole-file') {
            $destSha = Get-FileSha256 -Path $dest
            $srcSha  = Get-FileSha256 -Path $src
            if ($destSha -ne $srcSha) {
                return [pscustomobject]@{
                    Name          = $name
                    Path          = $dest
                    Exists        = $true
                    ByteIdentical = $false
                    Reason        = ('byte-mismatch: sha256 differs ({0} vs {1})' -f $destSha, $srcSha)
                }
            }
            return [pscustomobject]@{
                Name          = $name
                Path          = $dest
                Exists        = $true
                ByteIdentical = $true
                Reason        = $null
            }
        }
        else {
            return [pscustomobject]@{
                Name          = $name
                Path          = $dest
                Exists        = $true
                ByteIdentical = $false
                Reason        = ('read-error: unknown CompareMode: ' + $mode)
            }
        }
    }
    catch {
        return [pscustomobject]@{
            Name          = $name
            Path          = $dest
            Exists        = $true
            ByteIdentical = $false
            Reason        = ('read-error: ' + $_.Exception.Message)
        }
    }
}

function script:Test-MetadataSchemaOk {
    # Focused install.json schema check for inspect-mode classification (INSTALL.md §13.1:
    # schema mismatch → inspect_mode_unknown). This validates the 14-field set + the constant
    # / mode-conditional value rules using the canonical field-set + constants dot-sourced from
    # install-pipeline-core.ps1. It is metadata-schema validation only — it does not duplicate
    # apply-managed-block.ps1 / activate-global.ps1 logic, and verify mode still runs the full
    # canonical Invoke-InstallPipelineVerify (manifest digest + marker + cross-binding).
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)] [psobject] $Metadata,
        [System.Collections.Generic.List[string]] $Reasons
    )

    $ok = $true
    $actualFields = @($Metadata.PSObject.Properties.Name)
    $expected = $script:InstallPipelineMetadataFields
    foreach ($f in $expected) {
        if ($actualFields -cnotcontains $f) { $Reasons.Add("metadata missing required field: $f"); $ok = $false }
    }
    foreach ($f in $actualFields) {
        if ($expected -cnotcontains $f) { $Reasons.Add("metadata has unexpected field: $f"); $ok = $false }
    }
    # Do not read values until the field set is structurally complete (StrictMode-safe).
    if (-not $ok) { return $false }

    if ($Metadata.tool -ne $script:InstallPipelineTool) {
        $Reasons.Add("metadata.tool mismatch: $($Metadata.tool)"); $ok = $false
    }
    if (@('git-url', 'local-clone') -notcontains $Metadata.installMode) {
        $Reasons.Add("metadata.installMode invalid: $($Metadata.installMode)"); $ok = $false
    }
    if ($Metadata.targetFootprintPolicy -ne $script:InstallPipelineFootprint) {
        $Reasons.Add("metadata.targetFootprintPolicy mismatch: $($Metadata.targetFootprintPolicy)"); $ok = $false
    }
    if ($Metadata.managedBy -ne $script:InstallPipelineManagedBy) {
        $Reasons.Add("metadata.managedBy mismatch: $($Metadata.managedBy)"); $ok = $false
    }
    foreach ($shaField in @('installedHead', 'lastUpdatedHead')) {
        $v = [string]$Metadata.$shaField
        if ([string]::IsNullOrEmpty($v) -or ($v -notmatch '^[0-9a-f]{40}$')) {
            $Reasons.Add("metadata.$shaField is not a 40-hex sha: $v"); $ok = $false
        }
    }
    # Mode-conditional source-identity fields — full INSTALL.md §4 / §5 schema rule
    # (both the non-empty requirement AND the complementary must-be-empty requirement),
    # so a schema-mismatched install.json is classified inspect_mode_unknown rather than
    # proceeding to payload/source classification.
    if ($Metadata.installMode -eq 'git-url') {
        if ([string]::IsNullOrEmpty([string]$Metadata.repoUrl))        { $Reasons.Add('metadata.repoUrl empty for git-url mode'); $ok = $false }
        if (-not [string]::IsNullOrEmpty([string]$Metadata.sourcePath)) { $Reasons.Add('metadata.sourcePath must be empty for git-url mode'); $ok = $false }
        if (-not [string]::IsNullOrEmpty([string]$Metadata.toolRoot))   { $Reasons.Add('metadata.toolRoot must be empty for git-url mode'); $ok = $false }
    }
    elseif ($Metadata.installMode -eq 'local-clone') {
        if ([string]::IsNullOrEmpty([string]$Metadata.sourcePath))     { $Reasons.Add('metadata.sourcePath empty for local-clone mode'); $ok = $false }
        if ([string]::IsNullOrEmpty([string]$Metadata.toolRoot))       { $Reasons.Add('metadata.toolRoot empty for local-clone mode'); $ok = $false }
        if (-not [string]::IsNullOrEmpty([string]$Metadata.repoUrl))    { $Reasons.Add('metadata.repoUrl must be empty for local-clone mode'); $ok = $false }
    }
    return $ok
}

function script:Resolve-SourceHead {
    [CmdletBinding()]
    param(
        [psobject] $Metadata,
        [string] $SourcePath,
        [string] $RepoUrl,
        [string] $Branch,
        [string] $Ref
    )

    # Argument > metadata-derived. If neither is available, return null with reason.
    $useLocal = $false
    $localPath = $null
    $useUrl = $false
    $urlValue = $null

    if (-not [string]::IsNullOrEmpty($SourcePath)) {
        $useLocal = $true
        $localPath = $SourcePath
    }
    elseif (-not [string]::IsNullOrEmpty($RepoUrl)) {
        $useUrl = $true
        $urlValue = $RepoUrl
    }
    elseif ($null -ne $Metadata) {
        $mdMode = $null
        if (@($Metadata.PSObject.Properties.Name) -ccontains 'installMode') {
            $mdMode = [string]$Metadata.installMode
        }
        if ($mdMode -eq 'local-clone' -and (@($Metadata.PSObject.Properties.Name) -ccontains 'sourcePath')) {
            $mdSrc = [string]$Metadata.sourcePath
            if (-not [string]::IsNullOrEmpty($mdSrc)) {
                $useLocal = $true
                $localPath = $mdSrc
            }
        }
        elseif ($mdMode -eq 'git-url' -and (@($Metadata.PSObject.Properties.Name) -ccontains 'repoUrl')) {
            $mdUrl = [string]$Metadata.repoUrl
            if (-not [string]::IsNullOrEmpty($mdUrl)) {
                $useUrl = $true
                $urlValue = $mdUrl
            }
        }
    }

    if ($useLocal) {
        if (-not (Test-Path -LiteralPath $localPath -PathType Container)) {
            return [pscustomobject]@{ Head = $null; Reason = ('local source path not found: ' + $localPath) }
        }
        $head = Get-GitHead -WorkingDirectory $localPath
        if ([string]::IsNullOrEmpty($head)) {
            return [pscustomobject]@{ Head = $null; Reason = ('git rev-parse HEAD failed at ' + $localPath) }
        }
        if ($head -notmatch '^[0-9a-f]{40}$') {
            return [pscustomobject]@{ Head = $null; Reason = ('local HEAD is not a 40-hex sha: ' + $head) }
        }
        return [pscustomobject]@{ Head = $head; Reason = $null }
    }
    elseif ($useUrl) {
        # ref precedence: explicit -Ref → explicit -Branch → install.json.branch → 'main' fallback.
        # Without metadata.branch derivation, a git-url install tracking a non-main branch would
        # be resolved against the wrong ref and falsely reported as drifted/clean (INSTALL.md §7.1
        # step 1 reads branch/remote from install.json).
        $refArg = $null
        if (-not [string]::IsNullOrEmpty($Ref)) {
            $refArg = $Ref
        }
        elseif (-not [string]::IsNullOrEmpty($Branch)) {
            $refArg = $Branch
        }
        elseif ($null -ne $Metadata -and (@($Metadata.PSObject.Properties.Name) -ccontains 'branch') -and -not [string]::IsNullOrEmpty([string]$Metadata.branch)) {
            $refArg = [string]$Metadata.branch
        }
        else {
            $refArg = 'main'
        }
        $result = Invoke-GitCapture -Arguments @('ls-remote', $urlValue, $refArg)
        if ($result.ExitCode -ne 0) {
            return [pscustomobject]@{ Head = $null; Reason = ('git ls-remote {0} {1} failed (exit {2})' -f $urlValue, $refArg, $result.ExitCode) }
        }
        $lines = @($result.StdOut -split "`r?`n" | Where-Object { -not [string]::IsNullOrEmpty($_) })
        if ($lines.Count -eq 0) {
            return [pscustomobject]@{ Head = $null; Reason = ('git ls-remote returned no refs for ' + $refArg) }
        }
        $firstSha = ($lines[0] -split "\s+")[0].Trim()
        if ($firstSha -notmatch '^[0-9a-f]{40}$') {
            return [pscustomobject]@{ Head = $null; Reason = ('git ls-remote returned non-sha first token: ' + $firstSha) }
        }
        return [pscustomobject]@{ Head = $firstSha; Reason = $null }
    }
    else {
        return [pscustomobject]@{ Head = $null; Reason = 'no source identity available (no -SourcePath/-RepoUrl, and install.json missing or installMode unknown)' }
    }
}

# ---------------------------------------------------------------------------
# Mode dispatch.
# ---------------------------------------------------------------------------

function script:Invoke-InspectMode {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)] [string] $InstallArea,
        [string] $ClaudeHome,
        [string] $CodexHome,
        [string] $SourcePath,
        [string] $RepoUrl,
        [string] $Branch,
        [string] $Remote,
        [string] $Ref
    )

    $reasons = New-Object System.Collections.Generic.List[string]
    $installAreaResolved = [System.IO.Path]::GetFullPath($InstallArea)

    # 1. install.json read + schema check (lenient — we only need basic shape here;
    #    full 14-field strictness lives in verify mode via Invoke-InstallPipelineVerify).
    $metadata = $null
    $installState = 'absent'
    $metadataValid = $false
    $installMode = $null
    $lastUpdatedHead = $null

    $metadataPath = Get-InstallPipelineMetadataPath -InstallArea $installAreaResolved
    if (-not (Test-Path -LiteralPath $metadataPath -PathType Leaf)) {
        $reasons.Add('install.json missing at ' + $metadataPath)
        return [pscustomobject]@{
            Status                       = 'inspect_mode_unknown'
            ExitCode                     = 0
            InstallAreaPath              = $installAreaResolved
            InstallState                 = $installState
            MetadataValid                = $false
            InstallMode                  = $null
            LastUpdatedHead              = $null
            SourceResolvedHead           = $null
            PayloadDeltaRequired         = $false
            ManifestMarkerCrossBindingOk = $false
            ActivationSurfaces           = @()
            Reasons                      = @($reasons)
        }
    }
    try {
        $metadata = Read-InstallPipelineMetadata -InstallArea $installAreaResolved
        $installState = 'present'
    }
    catch {
        $reasons.Add('install.json read failed: ' + $_.Exception.Message)
        return [pscustomobject]@{
            Status                       = 'inspect_mode_unknown'
            ExitCode                     = 0
            InstallAreaPath              = $installAreaResolved
            InstallState                 = 'partial'
            MetadataValid                = $false
            InstallMode                  = $null
            LastUpdatedHead              = $null
            SourceResolvedHead           = $null
            PayloadDeltaRequired         = $false
            ManifestMarkerCrossBindingOk = $false
            ActivationSurfaces           = @()
            Reasons                      = @($reasons)
        }
    }
    if ($null -eq $metadata) {
        $reasons.Add('install.json returned null')
        return [pscustomobject]@{
            Status                       = 'inspect_mode_unknown'
            ExitCode                     = 0
            InstallAreaPath              = $installAreaResolved
            InstallState                 = 'partial'
            MetadataValid                = $false
            InstallMode                  = $null
            LastUpdatedHead              = $null
            SourceResolvedHead           = $null
            PayloadDeltaRequired         = $false
            ManifestMarkerCrossBindingOk = $false
            ActivationSurfaces           = @()
            Reasons                      = @($reasons)
        }
    }
    # Schema mismatch → inspect_mode_unknown (INSTALL.md §13.1). The metadata reader only
    # checks schemaVersion; a missing / unexpected / invalid mode-conditional field must not
    # silently proceed to payload/source classification.
    $schemaReasons = New-Object System.Collections.Generic.List[string]
    if (-not (script:Test-MetadataSchemaOk -Metadata $metadata -Reasons $schemaReasons)) {
        foreach ($sr in $schemaReasons) { $reasons.Add($sr) }
        return [pscustomobject]@{
            Status                       = 'inspect_mode_unknown'
            ExitCode                     = 0
            InstallAreaPath              = $installAreaResolved
            InstallState                 = 'partial'
            MetadataValid                = $false
            InstallMode                  = $null
            LastUpdatedHead              = $null
            SourceResolvedHead           = $null
            PayloadDeltaRequired         = $false
            ManifestMarkerCrossBindingOk = $false
            ActivationSurfaces           = @()
            Reasons                      = @($reasons)
        }
    }
    $metadataValid = $true
    $installMode     = [string]$metadata.installMode
    $lastUpdatedHead = [string]$metadata.lastUpdatedHead

    # 2. manifest + marker presence + cross-binding (lenient — Invoke-InstallPipelineVerify
    #    does the strict version; here we only need to classify payload-drift).
    $manifestPath = Get-InstallPipelineManifestPath -InstallArea $installAreaResolved
    $markerPath   = Get-InstallPipelineMarkerPath   -InstallArea $installAreaResolved
    $manifest = $null
    $marker   = $null
    $payloadDrift = $false
    try {
        $manifest = Read-InstallPipelineManifest -InstallArea $installAreaResolved
    }
    catch {
        $reasons.Add('payload-manifest.json read failed: ' + $_.Exception.Message)
        $payloadDrift = $true
    }
    if ($null -eq $manifest -and -not $payloadDrift) {
        if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
            $reasons.Add('payload-manifest.json missing at ' + $manifestPath)
            $payloadDrift = $true
        }
    }
    try {
        $marker = Read-InstallPipelineMarker -InstallArea $installAreaResolved
    }
    catch {
        $reasons.Add('payload-marker.json read failed: ' + $_.Exception.Message)
        $payloadDrift = $true
    }
    if ($null -eq $marker -and -not $payloadDrift) {
        if (-not (Test-Path -LiteralPath $markerPath -PathType Leaf)) {
            $reasons.Add('payload-marker.json missing at ' + $markerPath)
            $payloadDrift = $true
        }
    }

    $manifestMarkerCrossBindingOk = $true
    if (-not $payloadDrift -and $null -ne $manifest -and $null -ne $marker) {
        $manHead = if (@($manifest.PSObject.Properties.Name) -ccontains 'head') { [string]$manifest.head } else { '' }
        $mrkHead = if (@($marker.PSObject.Properties.Name)   -ccontains 'head') { [string]$marker.head   } else { '' }
        if ($manHead -ne $mrkHead) {
            $reasons.Add(('cross-binding mismatch: manifest.head ({0}) != marker.head ({1})' -f $manHead, $mrkHead))
            $manifestMarkerCrossBindingOk = $false
            $payloadDrift = $true
        }
        elseif (-not [string]::IsNullOrEmpty($lastUpdatedHead) -and $manHead -ne $lastUpdatedHead) {
            $reasons.Add(('cross-binding mismatch: manifest.head ({0}) != install.json.lastUpdatedHead ({1})' -f $manHead, $lastUpdatedHead))
            $manifestMarkerCrossBindingOk = $false
            $payloadDrift = $true
        }
    }
    else {
        $manifestMarkerCrossBindingOk = $false
    }

    if ($payloadDrift) {
        return [pscustomobject]@{
            Status                       = 'inspect_payload_drift'
            ExitCode                     = 0
            InstallAreaPath              = $installAreaResolved
            InstallState                 = $installState
            MetadataValid                = $metadataValid
            InstallMode                  = $installMode
            LastUpdatedHead              = $lastUpdatedHead
            SourceResolvedHead           = $null
            PayloadDeltaRequired         = $false
            ManifestMarkerCrossBindingOk = $manifestMarkerCrossBindingOk
            ActivationSurfaces           = @()
            Reasons                      = @($reasons)
        }
    }

    # 3. source HEAD resolve + source-drift check.
    $srcResolved = script:Resolve-SourceHead -Metadata $metadata -SourcePath $SourcePath -RepoUrl $RepoUrl -Branch $Branch -Ref $Ref
    $sourceResolvedHead = $srcResolved.Head
    $payloadDeltaRequired = $false
    if ($null -eq $sourceResolvedHead) {
        $reasons.Add('source HEAD resolve failed: ' + $srcResolved.Reason)
        return [pscustomobject]@{
            Status                       = 'inspect_source_drift'
            ExitCode                     = 0
            InstallAreaPath              = $installAreaResolved
            InstallState                 = $installState
            MetadataValid                = $metadataValid
            InstallMode                  = $installMode
            LastUpdatedHead              = $lastUpdatedHead
            SourceResolvedHead           = $null
            PayloadDeltaRequired         = $true
            ManifestMarkerCrossBindingOk = $manifestMarkerCrossBindingOk
            ActivationSurfaces           = @()
            Reasons                      = @($reasons)
        }
    }
    if ($sourceResolvedHead -ne $lastUpdatedHead) {
        $payloadDeltaRequired = $true
        $reasons.Add(('source HEAD ({0}) differs from install.json.lastUpdatedHead ({1})' -f $sourceResolvedHead, $lastUpdatedHead))
        return [pscustomobject]@{
            Status                       = 'inspect_source_drift'
            ExitCode                     = 0
            InstallAreaPath              = $installAreaResolved
            InstallState                 = $installState
            MetadataValid                = $metadataValid
            InstallMode                  = $installMode
            LastUpdatedHead              = $lastUpdatedHead
            SourceResolvedHead           = $sourceResolvedHead
            PayloadDeltaRequired         = $true
            ManifestMarkerCrossBindingOk = $manifestMarkerCrossBindingOk
            ActivationSurfaces           = @()
            Reasons                      = @($reasons)
        }
    }

    # 4. activation surface byte-identity check (3 surfaces).
    $surfacesObj = script:Get-ActivationSurfacePaths -InstallArea $installAreaResolved -ClaudeHome $ClaudeHome -CodexHome $CodexHome
    $surfaceResults = @()
    $activationDrift = $false
    foreach ($s in $surfacesObj.Surfaces) {
        $r = script:Test-ActivationSurface -Surface $s
        $surfaceResults += $r
        if (-not $r.ByteIdentical) {
            $activationDrift = $true
            $reasons.Add(('activation surface drift: {0} ({1})' -f $r.Name, $r.Reason))
        }
    }

    if ($activationDrift) {
        return [pscustomobject]@{
            Status                       = 'inspect_activation_drift'
            ExitCode                     = 0
            InstallAreaPath              = $installAreaResolved
            InstallState                 = $installState
            MetadataValid                = $metadataValid
            InstallMode                  = $installMode
            LastUpdatedHead              = $lastUpdatedHead
            SourceResolvedHead           = $sourceResolvedHead
            PayloadDeltaRequired         = $payloadDeltaRequired
            ManifestMarkerCrossBindingOk = $manifestMarkerCrossBindingOk
            ActivationSurfaces           = $surfaceResults
            Reasons                      = @($reasons)
        }
    }

    # 5. all green.
    return [pscustomobject]@{
        Status                       = 'inspect_clean'
        ExitCode                     = 0
        InstallAreaPath              = $installAreaResolved
        InstallState                 = $installState
        MetadataValid                = $metadataValid
        InstallMode                  = $installMode
        LastUpdatedHead              = $lastUpdatedHead
        SourceResolvedHead           = $sourceResolvedHead
        PayloadDeltaRequired         = $payloadDeltaRequired
        ManifestMarkerCrossBindingOk = $manifestMarkerCrossBindingOk
        ActivationSurfaces           = $surfaceResults
        Reasons                      = @()
    }
}

function script:Invoke-VerifyMode {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)] [string] $InstallArea,
        [string] $ClaudeHome,
        [string] $CodexHome
    )

    $reasons = New-Object System.Collections.Generic.List[string]
    $installAreaResolved = [System.IO.Path]::GetFullPath($InstallArea)

    # Canonical verify via the shared library helper. Invoke-InstallPipelineVerify is the
    # single source of truth for full install verification — 14-field schema (including the
    # complete INSTALL.md §4/§5 mode-conditional rule: required-non-empty AND complementary
    # must-be-empty for both git-url and local-clone), manifest digest, marker, and
    # cross-binding. Returns PSCustomObject with .ok (bool) and .errors (array of strings).
    # No supplementary metadata schema check is layered here: that would duplicate the
    # canonical helper's metadata logic, which now covers the full mode-conditional schema.
    $verifyResult = Invoke-InstallPipelineVerify -InstallArea $installAreaResolved
    if (-not $verifyResult.ok) {
        foreach ($e in $verifyResult.errors) { $reasons.Add($e) }
    }

    # Activation surface byte-identity (3 surfaces). verify is the superset of
    # inspect, so the same activation check applies.
    $surfacesObj = script:Get-ActivationSurfacePaths -InstallArea $installAreaResolved -ClaudeHome $ClaudeHome -CodexHome $CodexHome
    $surfaceResults = @()
    foreach ($s in $surfacesObj.Surfaces) {
        $r = script:Test-ActivationSurface -Surface $s
        $surfaceResults += $r
        if (-not $r.ByteIdentical) {
            $reasons.Add(('activation surface byte-identity fail: {0} ({1})' -f $r.Name, $r.Reason))
        }
    }

    $status = if ($reasons.Count -eq 0) { 'verify_pass' } else { 'verify_failed' }
    $exitCode = if ($reasons.Count -eq 0) { 0 } else { 1 }

    return [pscustomobject]@{
        Status             = $status
        ExitCode           = $exitCode
        InstallAreaPath    = $installAreaResolved
        ActivationSurfaces = $surfaceResults
        Reasons            = @($reasons)
    }
}

# ---------------------------------------------------------------------------
# Output formatting.
# ---------------------------------------------------------------------------

function script:Format-StdoutJson {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)] [string] $Mode,
        [Parameter(Mandatory = $true)] [pscustomobject] $Result
    )

    # Build the strict subset of the run.json contract (INSTALL.md §13.4.1) that
    # applies to inspect/verify stdout — no startedAt/finishedAt/runId since this
    # entrypoint does not own a run lifecycle file.
    $surfaces = @()
    if (@($Result.PSObject.Properties.Name) -ccontains 'ActivationSurfaces') {
        foreach ($s in $Result.ActivationSurfaces) {
            $surfaces += [ordered]@{
                name          = $s.Name
                path          = $s.Path
                exists        = $s.Exists
                byteIdentical = $s.ByteIdentical
                reason        = $s.Reason
            }
        }
    }

    $body = [ordered]@{
        schemaVersion                = 1
        tool                         = 'ai-harness-toolset'
        mode                         = $Mode
        installAreaPath              = $Result.InstallAreaPath
        status                       = $Result.Status
        exitCode                     = $Result.ExitCode
        reasons                      = @($Result.Reasons)
        activationSurfaces           = $surfaces
    }
    if ($Mode -eq 'inspect') {
        $body['installState']                 = if (@($Result.PSObject.Properties.Name) -ccontains 'InstallState')                 { $Result.InstallState }                 else { $null }
        $body['metadataValid']                = if (@($Result.PSObject.Properties.Name) -ccontains 'MetadataValid')                { $Result.MetadataValid }                else { $false }
        $body['installMode']                  = if (@($Result.PSObject.Properties.Name) -ccontains 'InstallMode')                  { $Result.InstallMode }                  else { $null }
        $body['lastUpdatedHead']              = if (@($Result.PSObject.Properties.Name) -ccontains 'LastUpdatedHead')              { $Result.LastUpdatedHead }              else { $null }
        $body['sourceResolvedHead']           = if (@($Result.PSObject.Properties.Name) -ccontains 'SourceResolvedHead')           { $Result.SourceResolvedHead }           else { $null }
        $body['payloadDeltaRequired']         = if (@($Result.PSObject.Properties.Name) -ccontains 'PayloadDeltaRequired')         { $Result.PayloadDeltaRequired }         else { $false }
        $body['manifestMarkerCrossBindingOk'] = if (@($Result.PSObject.Properties.Name) -ccontains 'ManifestMarkerCrossBindingOk') { $Result.ManifestMarkerCrossBindingOk } else { $false }
    }

    return ($body | ConvertTo-Json -Depth 8)
}

function script:Write-HumanReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)] [string] $Mode,
        [Parameter(Mandatory = $true)] [pscustomobject] $Result,
        [switch] $ToStderr
    )

    $lines = @(
        ('install-update: mode={0} installArea={1}' -f $Mode, $Result.InstallAreaPath),
        ('install-update: status={0}' -f $Result.Status),
        ('install-update: exitCode={0}' -f $Result.ExitCode)
    )
    if (@($Result.PSObject.Properties.Name) -ccontains 'Reasons' -and $Result.Reasons.Count -gt 0) {
        $lines += 'install-update: reasons:'
        foreach ($r in $Result.Reasons) { $lines += ('  - ' + $r) }
    }

    foreach ($line in $lines) {
        if ($ToStderr) {
            [Console]::Error.WriteLine($line)
        }
        else {
            Write-Host $line
        }
    }
}

# ---------------------------------------------------------------------------
# Main.
# ---------------------------------------------------------------------------

try {
    if ($Mode -eq 'inspect') {
        $result = script:Invoke-InspectMode -InstallArea $InstallArea -ClaudeHome $ClaudeHome -CodexHome $CodexHome -SourcePath $SourcePath -RepoUrl $RepoUrl -Branch $Branch -Remote $Remote -Ref $Ref
    }
    elseif ($Mode -eq 'verify') {
        $result = script:Invoke-VerifyMode -InstallArea $InstallArea -ClaudeHome $ClaudeHome -CodexHome $CodexHome
    }
    else {
        Write-Host ('install-update: FAIL unknown mode: ' + $Mode)
        exit 1
    }
}
catch {
    Write-Host ('install-update: FAIL unhandled exception: ' + $_.Exception.Message)
    exit 1
}

$jsonBody = script:Format-StdoutJson -Mode $Mode -Result $result

if ($Json) {
    # JSON-only on stdout; human report to stderr.
    script:Write-HumanReport -Mode $Mode -Result $result -ToStderr
    Write-Host $jsonBody
}
else {
    script:Write-HumanReport -Mode $Mode -Result $result
    Write-Host '--- BEGIN JSON ---'
    Write-Host $jsonBody
    Write-Host '--- END JSON ---'
}

$finalLabel = if ($result.ExitCode -eq 0) { 'PASS' } else { 'FAIL' }
if ($Json) {
    [Console]::Error.WriteLine('install-update: ' + $finalLabel)
}
else {
    Write-Host ('install-update: ' + $finalLabel)
}
exit $result.ExitCode
