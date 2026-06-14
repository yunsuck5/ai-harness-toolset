[CmdletBinding()]
param(
    # The install ROOT (the directory that will CONTAIN current/, install.json, payload-manifest.json,
    # payload-marker.json, and the managed root README). Default %USERPROFILE%\ai-harness-toolset
    # (the single source of truth is Get-StableInstallAreaCandidate in lib/path.ps1).
    # Overridable so tests never touch the real %USERPROFILE%.
    [string] $InstallArea,

    # Source — exactly one of:
    #   -SourcePath <local git repo>  (local-clone install)
    #   -RepoUrl    <git url>         (git-url install)
    [string] $SourcePath,
    [string] $RepoUrl,
    [string] $Branch,
    [string] $Remote,

    # Activation-surface homes (overridable so tests point at TestDrive, never the real user-global
    # instruction roots).
    [string] $ClaudeHome,
    [string] $CodexHome,

    [switch] $SkipSmoke
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# IU-B-09 FRESH global install entrypoint.
#
# This restores the deterministic fresh-install bootstrap path that drifted during update polishing:
# install-update.ps1 is an EXISTING-install update entrypoint (its mutation mode is update-source) and
# does NOT materialize a fresh install, so fresh install previously required the operator to dot-source
# Invoke-InstallPipelineDispatch -Action install by hand and then hand-splice the two managed blocks.
# install-global.ps1 closes that gap as a single named CLI. It is NOT a new productized installer
# framework / wizard / doctor / repair system; it wraps the SAME canonical pipeline library the rest of
# the lifecycle already uses.
#
# Lifecycle entrypoint split (IU-B-09):
#   - scripts/install-global.ps1   : FRESH global install (this script).
#   - scripts/update-global.ps1    : EXISTING-install update (operator-facing wrapper over install-update.ps1).
#   - scripts/uninstall-global.ps1 : global uninstall / teardown (unchanged).
#   - scripts/install-update.ps1   : retained as the existing-update / internal / compat implementation.
#
# What it does (all via the canonical library, so the operator never calls the library directly):
#   1. fail-fast if an install already exists at -InstallArea (no overwrite; use update-global.ps1).
#   2. acquire source (local-clone or git-url) + resolve the 40-hex HEAD.
#   3. New-InstallPipelineTuple -Action install -> Invoke-InstallPipelineDispatch: materialize current/,
#      install.json, payload-manifest.json, payload-marker.json, and the managed root README.
#   4. Invoke-InstallPipelineVerify: payload schema / manifest / marker / cross-binding.
#   5. activation bootstrap from the MATERIALIZED payload (current/snippets/...):
#        - Claude + Codex managed blocks: FIRST-TIME insertion via the sibling
#          scripts/apply-managed-block.ps1 -Insert (create absent target / append into a 0-pair target;
#          a pre-existing managed block fail-fasts with replace guidance — it does NOT silently splice).
#        - each skill mirror: canonical-overwrite create from the payload + post-write SHA-256 verify.
#   6. final canonical verify: scripts/install-update.ps1 -Mode verify must reach verify_pass
#      (payload + all activation surfaces byte-identical: two managed blocks + one mirror per source skill).
#   7. optional operational smoke (reuses the shared lib/operational-smoke.ps1 helper).
#
# Mutation scope: only -InstallArea (payload) and the resolved activation surfaces under
# -ClaudeHome / -CodexHome. Real %USERPROFILE% is never touched in tests — every destructive path is
# exercised against TestDrive / temp fixtures via the overridable -InstallArea / -ClaudeHome / -CodexHome.

. (Join-Path $PSScriptRoot 'lib/encoding.ps1')
. (Join-Path $PSScriptRoot 'lib/hash.ps1')
. (Join-Path $PSScriptRoot 'lib/git.ps1')
. (Join-Path $PSScriptRoot 'lib/path.ps1')
. (Join-Path $PSScriptRoot 'lib/managed-block.ps1')
. (Join-Path $PSScriptRoot 'lib/install-pipeline-core.ps1')
. (Join-Path $PSScriptRoot 'lib/native-process.ps1')
. (Join-Path $PSScriptRoot 'lib/activation-surface.ps1')
. (Join-Path $PSScriptRoot 'lib/operational-smoke.ps1')

# Home / install-area defaults (overridable so tests never touch the real %USERPROFILE%).
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
if ([string]::IsNullOrEmpty($InstallArea)) {
    # Default install area = the single source of truth in lib/path.ps1 (vendor-neutral,
    # %USERPROFILE%\ai-harness-toolset). NOT derived from $ClaudeHome — the install area is
    # decoupled from the Claude activation home so it does not live under .claude.
    $InstallArea = Get-StableInstallAreaCandidate
}

$applyScript  = Join-Path $PSScriptRoot 'apply-managed-block.ps1'
$verifyScript = Join-Path $PSScriptRoot 'install-update.ps1'

function script:Stop-Install {
    param([string] $Message)
    Write-Host ('install-global: FAIL ' + $Message)
    Write-Host 'install-global: installStatus=install_failed'
    Write-Host 'install-global: FAIL'
    exit 1
}

# ---------------------------------------------------------------------------------------------------
# 1. Source argument validation — exactly one of -SourcePath / -RepoUrl.
# ---------------------------------------------------------------------------------------------------
$hasSource = -not [string]::IsNullOrEmpty($SourcePath)
$hasUrl    = -not [string]::IsNullOrEmpty($RepoUrl)
if ($hasSource -and $hasUrl) {
    script:Stop-Install 'specify only one of -SourcePath (local-clone) or -RepoUrl (git-url), not both.'
}
if (-not $hasSource -and -not $hasUrl) {
    script:Stop-Install 'a source is required: -SourcePath <local git repo> or -RepoUrl <git url>.'
}
$installMode = if ($hasUrl) { 'git-url' } else { 'local-clone' }

$installAreaResolved = [System.IO.Path]::GetFullPath($InstallArea)
Write-Host 'install-global: mode=INSTALL (fresh global install)'
Write-Host ('install-global: installArea={0}' -f $installAreaResolved)
Write-Host ('install-global: installMode={0}' -f $installMode)

# ---------------------------------------------------------------------------------------------------
# 2. Existing-install guard — fresh install NEVER overwrites. No clean-reinstall/overwrite option here
#    (intentional: a destructive overwrite is a separate, future decision).
# ---------------------------------------------------------------------------------------------------
if (Test-Path -LiteralPath $installAreaResolved -PathType Leaf) {
    script:Stop-Install ('InstallArea path exists as a FILE (expected a directory or an absent path): ' + $installAreaResolved)
}
if (Test-Path -LiteralPath $installAreaResolved -PathType Container) {
    $existingMd = Join-Path $installAreaResolved 'install.json'
    if (Test-Path -LiteralPath $existingMd -PathType Leaf) {
        script:Stop-Install ('an existing install is already present (install.json found) at ' + $installAreaResolved + '. Fresh install refuses to overwrite it. Use scripts/update-global.ps1 (or scripts/install-update.ps1 -Mode update-source) to update an existing install.')
    }
    $children = @(Get-ChildItem -LiteralPath $installAreaResolved -Force -ErrorAction SilentlyContinue)
    if ($children.Count -gt 0) {
        script:Stop-Install ('InstallArea exists and is not empty (no install.json, but ' + $children.Count + ' entr(y/ies) present): ' + $installAreaResolved + '. Remove it or choose an empty target; fresh install does not overwrite existing content.')
    }
}
else {
    $null = New-Item -ItemType Directory -Path $installAreaResolved -Force
}

# ---------------------------------------------------------------------------------------------------
# 3. Acquire source + resolve HEAD + materialize via the canonical tuple/dispatch pipeline.
# ---------------------------------------------------------------------------------------------------
$cleanupCache   = $false
$cacheDir       = $null
$sourceLocation = $null
$tupleToolRoot  = $null
$resolvedHead   = $null
try {
    if ($installMode -eq 'local-clone') {
        $sourceLocation = [System.IO.Path]::GetFullPath($SourcePath)
        $resolvedHead   = Get-InstallPipelineSourceHead -SourceLocation $sourceLocation
        $tupleToolRoot  = $sourceLocation
    }
    else {
        # git-url: full clone into the run-scoped source-cache work area (under the install area),
        # cleaned up after the run regardless of outcome.
        $cacheDir     = Invoke-InstallPipelineGitUrlClone -InstallArea $installAreaResolved -RepoUrl $RepoUrl
        $cleanupCache = $true
        if (-not [string]::IsNullOrEmpty($Branch)) {
            $resolvedHead = Get-InstallPipelineGitUrlRemoteHead -InstallArea $installAreaResolved -Remote $Remote -Branch $Branch
        }
        else {
            $resolvedHead = Get-InstallPipelineSourceHead -SourceLocation $cacheDir
        }
        $sourceLocation = $RepoUrl
        $tupleToolRoot  = $cacheDir
    }

    if ([string]::IsNullOrEmpty($resolvedHead) -or ($resolvedHead -notmatch '^[0-9a-f]{40}$')) {
        throw ('could not resolve a 40-hex source HEAD for install (got: ' + $resolvedHead + ')')
    }

    $tuple = New-InstallPipelineTuple `
        -Action 'install' `
        -InstallMode $installMode `
        -SourceLocation $sourceLocation `
        -ResolvedRefSha $resolvedHead `
        -RefKind 'commit' `
        -ToolRoot $tupleToolRoot `
        -ProjectRoot $installAreaResolved `
        -SourceUpdatePolicy 'fetch-and-update'
    Invoke-InstallPipelineDispatch -Tuple $tuple -InstallArea $installAreaResolved -Branch $Branch -Remote $Remote
}
catch {
    if ($cleanupCache -and $null -ne $cacheDir -and (Test-Path -LiteralPath $cacheDir)) {
        Remove-Item -LiteralPath $cacheDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    script:Stop-Install ('install materialization failed: ' + $_.Exception.Message)
}

# Cleanup the run-scoped git-url source-cache (best-effort; report a leftover, never silently delete).
$leftoverCache = $null
if ($cleanupCache -and $null -ne $cacheDir) {
    try {
        if (Test-Path -LiteralPath $cacheDir) { Remove-Item -LiteralPath $cacheDir -Recurse -Force }
        if (Test-Path -LiteralPath $cacheDir) { $leftoverCache = $cacheDir }
    }
    catch { $leftoverCache = $cacheDir }
}

Write-Host ('install-global: payload materialized at {0} (head {1})' -f $installAreaResolved, $resolvedHead)

# ---------------------------------------------------------------------------------------------------
# 4. Payload verify (canonical pipeline verify — schema / manifest / marker / cross-binding).
# ---------------------------------------------------------------------------------------------------
$payloadVerify = Invoke-InstallPipelineVerify -InstallArea $installAreaResolved
if (-not $payloadVerify.ok) {
    foreach ($e in $payloadVerify.errors) { Write-Host ('install-global:   payload-verify: ' + $e) }
    script:Stop-Install 'post-install payload verify failed (schema/manifest/marker/cross-binding).'
}
Write-Host 'install-global: payload verify OK (schema/manifest/marker/cross-binding)'

# ---------------------------------------------------------------------------------------------------
# 5. Activation bootstrap from the MATERIALIZED payload (current/snippets/...). Sourcing from current/
#    (not this repo's snippets) keeps activation byte-identical to what was just installed, which is
#    exactly what the final verify_pass checks.
# ---------------------------------------------------------------------------------------------------
$currentDir = Get-InstallPipelineCurrentDir -InstallArea $installAreaResolved
$surfaces   = Get-ActivationSurfacePlan -PayloadRoot $currentDir -ClaudeHome $ClaudeHome -CodexHome $CodexHome

$activationFailed = $false
foreach ($s in $surfaces) {
    # Normalize so the forbidden-path guard below cannot be bypassed with . / .. segments.
    $targetFull = [System.IO.Path]::GetFullPath($s.Destination)

    # Forbidden destination (mirror activate-global.ps1 §10): never target %USERPROFILE%\.claude\AGENTS.md.
    $leaf   = Split-Path -Leaf $targetFull
    $parent = Split-Path -Leaf (Split-Path -Parent $targetFull)
    if ($leaf -ieq 'AGENTS.md' -and $parent -ieq '.claude') {
        Write-Host ('install-global: [{0}] FAIL forbidden destination (no agent uses %USERPROFILE%\.claude\AGENTS.md): {1}' -f $s.Name, $targetFull)
        $activationFailed = $true
        continue
    }
    if (-not (Test-Path -LiteralPath $s.Source -PathType Leaf)) {
        Write-Host ('install-global: [{0}] FAIL activation source not found in payload: {1}' -f $s.Name, $s.Source)
        $activationFailed = $true
        continue
    }

    if ($s.Class -eq 'managed-block') {
        # First-time insertion via the sibling hardened tool. Sibling (not the just-installed copy) so
        # -Insert is guaranteed available even when installing an older source. A pre-existing managed
        # block (1 marker pair) fail-fasts inside apply-managed-block -Insert -> reported here.
        Write-Host ('install-global: [{0}] first-time managed-block insertion -> {1}' -f $s.Name, $targetFull)
        $proc = Invoke-NativeProcess -Executable 'powershell.exe' -Arguments @(
            '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $applyScript,
            '-Insert', '-SnippetPath', $s.Source, '-TargetPath', $targetFull
        )
        $combined = ($proc.Stdout + $proc.Stderr).TrimEnd("`r", "`n")
        if (-not [string]::IsNullOrEmpty($combined)) {
            foreach ($line in ($combined -split "`r?`n")) { Write-Host ('install-global:   ' + $line) }
        }
        if ($proc.ExitCode -ne 0) {
            Write-Host ('install-global: [{0}] managed-block insertion FAILED (exit {1})' -f $s.Name, $proc.ExitCode)
            $activationFailed = $true
        }
    }
    else {
        # canonical-overwrite (per-source-skill mirror): whole-file copy from the payload + post-write
        # SHA-256 verify. Creating the parent dir + file is allowed (canonical artifact, NOT a
        # managed-block destination create). No merge, no backup, no rollback (the payload is the
        # recovery source).
        try {
            $parentDir = Split-Path -Parent $targetFull
            if (-not [string]::IsNullOrEmpty($parentDir) -and -not (Test-Path -LiteralPath $parentDir -PathType Container)) {
                $null = New-Item -ItemType Directory -Path $parentDir -Force
            }
            $bytes = [System.IO.File]::ReadAllBytes($s.Source)
            [System.IO.File]::WriteAllBytes($targetFull, $bytes)
            $srcSha = Get-FileSha256 -Path $s.Source
            $dstSha = Get-FileSha256 -Path $targetFull
            if ($srcSha -cne $dstSha) {
                throw ('post-write hash mismatch (src=' + $srcSha + ' dst=' + $dstSha + ')')
            }
            Write-Host ('install-global: [{0}] skill mirror created -> {1} (post-write hash verified)' -f $s.Name, $targetFull)
        }
        catch {
            Write-Host ('install-global: [{0}] skill mirror FAILED: {1}' -f $s.Name, $_.Exception.Message)
            $activationFailed = $true
        }
    }
}

if ($activationFailed) {
    Write-Host 'install-global: installStatus=activation_failed'
    Write-Host 'install-global: FAIL one or more activation surfaces failed (payload IS installed; resolve activation — e.g. for a pre-existing managed block use scripts/activate-global.ps1 to replace it).'
    exit 1
}

# ---------------------------------------------------------------------------------------------------
# 6. Final canonical verify via scripts/install-update.ps1 -Mode verify -> must reach verify_pass
#    (payload + all activation surfaces byte-identical: two managed blocks + one mirror per source
#    skill). Sibling install-update is used (guaranteed to carry the verify mode).
# ---------------------------------------------------------------------------------------------------
Write-Host 'install-global: running final canonical verify (install-update.ps1 -Mode verify)...'
$vproc = Invoke-NativeProcess -Executable 'powershell.exe' -Arguments @(
    '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $verifyScript,
    '-Mode', 'verify', '-InstallArea', $installAreaResolved, '-ClaudeHome', $ClaudeHome, '-CodexHome', $CodexHome
)
$vcombined = ($vproc.Stdout + $vproc.Stderr).TrimEnd("`r", "`n")
if (-not [string]::IsNullOrEmpty($vcombined)) {
    foreach ($line in ($vcombined -split "`r?`n")) { Write-Host ('install-global:   ' + $line) }
}
if ($vproc.ExitCode -ne 0) {
    Write-Host 'install-global: installStatus=verify_failed'
    Write-Host 'install-global: FAIL final verify did not reach verify_pass.'
    exit 1
}
Write-Host 'install-global: final verify reached verify_pass (payload + all activation surfaces byte-identical: two managed blocks + one mirror per source skill)'

# ---------------------------------------------------------------------------------------------------
# 7. Optional operational smoke (reuses the shared helper). Skipped with -SkipSmoke.
# ---------------------------------------------------------------------------------------------------
if (-not $SkipSmoke) {
    $smokeResult = Invoke-OperationalSmoke -PayloadRoot $currentDir
    $smokeReason = if (-not [string]::IsNullOrEmpty($smokeResult.Reason)) { ' (' + $smokeResult.Reason + ')' } else { '' }
    Write-Host ('install-global: smoke={0}{1}' -f $smokeResult.Smoke, $smokeReason)
    if ($smokeResult.Smoke -eq 'fail') {
        Write-Host 'install-global: installStatus=smoke_failed'
        Write-Host 'install-global: FAIL operational smoke failed.'
        exit 1
    }
}
else {
    Write-Host 'install-global: smoke=skip (-SkipSmoke)'
}

# ---------------------------------------------------------------------------------------------------
# 8. Success.
# ---------------------------------------------------------------------------------------------------
if ($null -ne $leftoverCache) {
    Write-Host ('install-global: NOTE source-cache cleanup left a leftover path (reported, not deleted): {0}' -f $leftoverCache)
}
Write-Host ('install-global: installedHead={0}' -f $resolvedHead)
Write-Host 'install-global: installStatus=installed'
Write-Host 'install-global: PASS (payload installed, activation bootstrapped, verify_pass)'
exit 0
