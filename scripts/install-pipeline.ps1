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
# Actual global apply is a separate explicit user-approved scope per
# INSTALL.md §10 (Approval boundaries) and GLOBAL_ADOPTION_DECISION.md §6.
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

# Run-scoped temporary work area policy (INSTALL.md §2 / §6 / §7 / §9).
# For git-url actions the entry script creates an in-InstallArea work area (the
# `source-cache/` directory) at action start and removes it at action end.
# `$script:CleanupCache` toggles on once we attempt the clone; the top-level
# `finally` block performs the cleanup and logs leftover state on failure.
$script:CleanupCache = $false

$exitCode = 0
try {
    Assert-NotForbiddenInstallArea -Path $InstallArea

    if (-not (Test-Path -LiteralPath $InstallArea -PathType Container)) {
        throw ('install-pipeline: FAIL InstallArea directory not found: {0}. Operator must create it explicitly (no auto-create at temp-only skeleton).' -f $InstallArea)
    }

    # Resolve invocation context: D1 runtime ToolRoot + D9 ProjectRoot.
    # This is invocation context, separate from the resolved tuple field `toolRoot`
    # (= source-side canonical local ToolRoot per parent §6 Layer 1 / §11.1).
    $project = Get-ProjectRoot -ProjectRoot $ProjectRoot

    $runtimeTool = '(unresolved)'
    if (-not [string]::IsNullOrEmpty($RuntimeToolRoot)) {
        if (-not (Test-Path -LiteralPath $RuntimeToolRoot -PathType Container)) {
            throw ('install-pipeline: FAIL -RuntimeToolRoot directory not found: {0}' -f $RuntimeToolRoot)
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
        $existing = Read-InstallPipelineMetadata -InstallArea $InstallArea
        if ($null -eq $existing) {
            throw ("install-pipeline: FAIL {0} requires existing install metadata at {1}. Run -Action install first." -f $Action, (Get-InstallPipelineMetadataPath -InstallArea $InstallArea))
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
            throw 'install-pipeline: STOP source-cut detected. Invocation params differ from install metadata in one or more of: installMode / repoUrl / sourcePath / toolRoot / branch / remote. Source-cut handling is a separate explicit user-approved scope and is not auto-resolved here. Reconcile metadata and invocation, or run a separate scoped source-cut workflow.'
        }
    }

    # Resolve mode and sourceLocation.
    $mode = $InstallMode
    if ([string]::IsNullOrEmpty($mode) -and $null -ne $existing) {
        $mode = [string]$existing.installMode
    }
    if ([string]::IsNullOrEmpty($mode)) {
        throw 'install-pipeline: FAIL -InstallMode is required for the install action; for update / restore the existing metadata must declare it.'
    }

    # Reject git-url + update-current early (INSTALL.md §7): GitHub URL has no
    # persistent source to "re-materialize at current HEAD"; the reinstall path
    # for git-url is `update-source` which performs a fresh run-scoped acquisition.
    if ($mode -eq 'git-url' -and $Action -eq 'update-current') {
        throw "install-pipeline: FAIL git-url + update-current is not supported. GitHub URL source has no persistent local source to re-materialize from; use update-source for git-url reinstall (INSTALL.md section 7)."
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
        throw 'install-pipeline: FAIL could not resolve sourceLocation. Provide -RepoUrl (git-url) or -SourcePath (local-clone), or run after metadata install.'
    }

    # Dogfooding mutation protection for update-source (local-clone only).
    # Dogfooding semantics require ProjectRoot == source repo path, which is a
    # local-clone concept; git-url's materialization source is a transient
    # run-scoped work area, never a user dev checkout.
    if ($Action -eq 'update-source' -and $mode -eq 'local-clone') {
        $isDogfood = Test-InstallPipelineDogfoodingSource -SourcePath $sourceLoc -ProjectRoot $project
        if ($isDogfood -and -not $AllowDogfoodSource) {
            throw ('install-pipeline: FAIL update-source against a dogfooding source (= ProjectRoot is a source repo) is refused by default to prevent silent mutation of user dev checkout. ProjectRoot={0} SourcePath={1}. Pass -AllowDogfoodSource only when you explicitly accept that source-side fetch/pull may be performed against your dev checkout in a future implementation.' -f $project, $sourceLoc)
        }
    }

    # Resolve the source-side ToolRoot for this action's tuple:
    # - local-clone: tuple.toolRoot = absolute path of user-supplied sourcePath (persistent identity).
    # - git-url    : tuple.toolRoot = absolute path of the run-scoped temporary work area
    #                (`<InstallArea>/source-cache`). This path is transient — cleanup happens in
    #                the top-level `finally`. metadata.toolRoot is intentionally left empty for
    #                git-url (New-InstallPipelineMetadata).
    $tuplePath = ''
    if ($mode -eq 'local-clone') {
        $tuplePath = [System.IO.Path]::GetFullPath($sourceLoc)
    }
    elseif ($mode -eq 'git-url') {
        # Refuse upfront if a leftover transient source-cache from a prior failed action is
        # present. The top-level `finally` cleanup must NOT remove an operator-visible
        # leftover (INSTALL.md §9: cleanup failure produces a leftover that requires explicit
        # user-approved cleanup, not silent auto-removal on the next action).
        $cacheDir = Get-InstallPipelineSourceCacheDir -InstallArea $InstallArea
        if (Test-Path -LiteralPath $cacheDir) {
            $any = Get-ChildItem -LiteralPath $cacheDir -Force -ErrorAction SilentlyContinue
            if ($null -ne $any) {
                throw ('install-pipeline: FAIL leftover transient source-cache at {0}. Per INSTALL.md §9 cleanup-failure leftover policy, explicit operator cleanup is required before re-running. Installed payload identity (if present) is unchanged by this refusal.' -f $cacheDir)
            }
        }
        # No leftover. Mark cleanup needed BEFORE attempting the clone so a partial work
        # area from a failed clone (`git clone` exits non-zero after creating the dir) is
        # also cleaned up in the top-level `finally`.
        $script:CleanupCache = $true
        $tuplePath = Invoke-InstallPipelineGitUrlClone -InstallArea $InstallArea -RepoUrl $sourceLoc
    }

    # Resolve ref. install / update-source / restore each take a different path.
    $refSha = ''
    $refKind = 'commit'
    switch ($Action) {
        'restore' {
            if ([string]::IsNullOrEmpty($Ref)) {
                throw "install-pipeline: FAIL restore action requires -Ref <commit|tag|branch>. Metadata-derived known-good fallback is forbidden (INSTALL.md §8 / §9)."
            }
            $refSha  = Resolve-InstallPipelineRef -SourceLocation $tuplePath -Ref $Ref
            $refKind = if ($Ref -match '^[0-9a-f]{7,40}$') { 'commit' } else { 'unknown' }
        }
        'update-source' {
            if ($mode -eq 'git-url') {
                # Fresh clone already populated origin/<branch> refs; resolve that head.
                $branchForHead = $Branch
                if ([string]::IsNullOrEmpty($branchForHead) -and $null -ne $existing) {
                    $branchForHead = [string]$existing.branch
                }
                $remoteForHead = $Remote
                if ([string]::IsNullOrEmpty($remoteForHead) -and $null -ne $existing) {
                    $remoteForHead = [string]$existing.remote
                }
                if (-not [string]::IsNullOrEmpty($branchForHead)) {
                    $refSha = Get-InstallPipelineGitUrlRemoteHead -InstallArea $InstallArea -Remote $remoteForHead -Branch $branchForHead
                }
                else {
                    # No branch recorded — fall back to the fresh clone's HEAD (= remote
                    # default branch tip). INSTALL.md does not require -Branch for git-url.
                    $refSha = Get-InstallPipelineSourceHead -SourceLocation $tuplePath
                }
            }
            else {
                $refSha = Get-InstallPipelineSourceHead -SourceLocation $tuplePath
            }
            $refKind = 'commit'
        }
        default {
            # install — use HEAD of materialization source. For git-url that is the
            # fresh clone's HEAD (= remote default branch tip); for local-clone it is
            # the user-supplied path's HEAD.
            if ($mode -eq 'git-url') {
                $branchForHead = $Branch
                if ([string]::IsNullOrEmpty($branchForHead) -and $null -ne $existing) {
                    $branchForHead = [string]$existing.branch
                }
                $remoteForHead = $Remote
                if ([string]::IsNullOrEmpty($remoteForHead) -and $null -ne $existing) {
                    $remoteForHead = [string]$existing.remote
                }
                if (-not [string]::IsNullOrEmpty($branchForHead)) {
                    $refSha = Get-InstallPipelineGitUrlRemoteHead -InstallArea $InstallArea -Remote $remoteForHead -Branch $branchForHead
                }
                else {
                    $refSha = Get-InstallPipelineSourceHead -SourceLocation $tuplePath
                }
            }
            else {
                $refSha = Get-InstallPipelineSourceHead -SourceLocation $tuplePath
            }
            $refKind = 'commit'
        }
    }

    # sourceUpdatePolicy: update-source flags fetch-and-update; others are read-current-only.
    $policy = if ($Action -eq 'update-source') { 'fetch-and-update' } else { 'read-current-only' }

    # Build resolved tuple. tuple.sourceLocation = user-facing identifier (URL or local path);
    # tuple.toolRoot = source-side ToolRoot used during this action (transient for git-url,
    # persistent user-supplied path for local-clone).
    $tuple = New-InstallPipelineTuple `
        -Action $Action `
        -InstallMode $mode `
        -SourceLocation $sourceLoc `
        -ResolvedRefSha $refSha `
        -RefKind $refKind `
        -ToolRoot $tuplePath `
        -ProjectRoot $project `
        -SourceUpdatePolicy $policy `
        -SourceCutDetected $false

    Invoke-InstallPipelineDispatch -Tuple $tuple -InstallArea $InstallArea -Branch $Branch -Remote $Remote

    $verifyResult = Invoke-InstallPipelineVerify -InstallArea $InstallArea
    if (-not $verifyResult.ok) {
        $details = New-Object System.Collections.Generic.List[string]
        foreach ($e in $verifyResult.errors) { $details.Add("  - $e") }
        throw ("install-pipeline: FAIL verify reported errors:`n" + ($details -join "`n"))
    }

    Write-Host ('install-pipeline: PASS action={0} installArea={1} sourceLocation={2} resolvedRefSha={3} sourceUpdatePolicy={4}' -f $Action, $InstallArea, $sourceLoc, $refSha, $policy)
    Write-Host ('install-pipeline: invocation-context runtimeToolRoot={0} projectRoot={1}' -f $runtimeTool, $project)
    if ($mode -eq 'git-url') {
        Write-Host ('install-pipeline: tuple-toolRoot (transient run-scoped work area, cleaned up at action end) = {0}' -f $tuplePath)
    }
    else {
        Write-Host ('install-pipeline: tuple-toolRoot (source-side ToolRoot, parent §6 Layer 1) = {0}' -f $tuplePath)
    }
}
catch {
    Write-Host $_.Exception.Message
    $exitCode = 1
}
finally {
    # Run-scoped temporary work area cleanup (INSTALL.md §2 / §9).
    # `$script:CleanupCache` is set once the clone has been attempted; cleanup
    # removes the cache regardless of success / failure. Cleanup failure is
    # logged as a leftover; it does NOT change the installed payload identity.
    if ($script:CleanupCache) {
        $cache = Get-InstallPipelineSourceCacheDir -InstallArea $InstallArea
        if (Test-Path -LiteralPath $cache) {
            try {
                Remove-Item -LiteralPath $cache -Recurse -Force -ErrorAction Stop
                Write-Host ('install-pipeline: cleanup ok; removed transient source-cache at {0}' -f $cache)
            }
            catch {
                Write-Host ('install-pipeline: WARNING transient source-cache cleanup failed; leftover at {0}; reason: {1}. Installed payload identity is unaffected — operator action required to remove leftover.' -f $cache, $_.Exception.Message)
            }
        }
    }
}
exit $exitCode
