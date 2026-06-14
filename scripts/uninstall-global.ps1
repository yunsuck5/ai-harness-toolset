[CmdletBinding()]
param(
    [string] $InstallArea,
    [string] $ClaudeHome,
    [string] $CodexHome,
    # NOTE: there is intentionally NO operator-facing -ExpectedInstallArea parameter. The expected
    # canonical install area for the destructive path guard is ALWAYS computed internally from
    # Get-StableInstallAreaCandidate (%USERPROFILE%\ai-harness-toolset) and can never be injected by the
    # caller — otherwise an operator could pass a matching expected area and bypass the canonical guard.
    # Test isolation is via the lower-level boundary (Get-StableInstallAreaCandidate reads
    # %USERPROFILE%; Get-UninstallPlan / the finalizer take the resolved value directly), never via a
    # public CLI parameter.
    # -Apply performs the DESTRUCTIVE uninstall (IU-B-08 batch 3). Without it the default run is a
    # READ-ONLY dry-run. Approval is the explicit -Apply invocation itself — this uninstall step's own
    # apply-time decision, distinct from update-source's "command-implied approval" namespace (INSTALL.md §13.8).
    [switch] $Apply,
    # Root under which the temp finalizer run-id dir is created (default %TEMP%). Overridable so tests
    # keep all finalizer temp artifacts inside TestDrive and never touch the real %TEMP%.
    [string] $FinalizerTempRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# IU-B-08 uninstall entrypoint.
#
#   default (no -Apply) : READ-ONLY dry-run — classify every uninstall target and report; no mutation.
#   -Apply              : DESTRUCTIVE — preflight-all-then-act, then:
#                           (1) managed-block removal on the EFFECTIVE Claude/Codex surfaces via the
#                               shared hardened scripts/apply-managed-block.ps1 -Remove (marker span
#                               excised, marker-outside content preserved, .amb-backup/rollback reused,
#                               file never deleted); non-effective Codex stale markers are detect-warn
#                               only and never removed;
#                           (2) owned skill MIRROR DIRECTORY removal (skills/<name> per owned source
#                               skill, path-guarded; sibling skills + the skills/ parent untouched);
#                           (3) install-root deletion DELEGATED to a self-contained temp finalizer
#                               (the main entrypoint may run from inside the install root, so it cannot
#                               delete that tree itself) — this entrypoint only creates + launches it.
#
# Success criterion = global ai-harness footprint zero (install root absent + skill dir absent + 0
# marker pairs on the effective instruction files). project-local log/, source repo / ToolRoot clone,
# sibling skills, and marker-outside instruction content are NON-targets.

. (Join-Path $PSScriptRoot 'lib/encoding.ps1')
. (Join-Path $PSScriptRoot 'lib/path.ps1')
. (Join-Path $PSScriptRoot 'lib/managed-block.ps1')
. (Join-Path $PSScriptRoot 'lib/activation-surface.ps1')
. (Join-Path $PSScriptRoot 'lib/install-pipeline-core.ps1')
. (Join-Path $PSScriptRoot 'lib/native-process.ps1')
. (Join-Path $PSScriptRoot 'lib/uninstall-target.ps1')

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
    # %USERPROFILE%\ai-harness-toolset). NOT derived from $ClaudeHome.
    $InstallArea = Get-StableInstallAreaCandidate
}
# Expected canonical install area for the path guard — ALWAYS the canonical
# Get-StableInstallAreaCandidate, never an operator-supplied value. This is what makes the guard a real
# canonical pin: the operator can choose WHICH InstallArea to point at (-InstallArea), but cannot choose
# what counts as canonical, so a non-canonical InstallArea is always refused.
$expectedInstallAreaResolved = [System.IO.Path]::GetFullPath((Get-StableInstallAreaCandidate))
if ([string]::IsNullOrEmpty($FinalizerTempRoot)) {
    $FinalizerTempRoot = $env:TEMP
}

$plan = Get-UninstallPlan -InstallArea $InstallArea -ClaudeHome $ClaudeHome -CodexHome $CodexHome -ExpectedInstallArea $expectedInstallAreaResolved

function script:Write-UninstallPlanReport {
    param([string] $Mode)
    Write-Host ('uninstall-global: mode={0}' -f $Mode)
    Write-Host ('uninstall-global: installArea={0}' -f $plan.InstallAreaPath)
    Write-Host ('uninstall-global: installRootPresent={0}' -f $plan.InstallRootPresent)
    $managedByDisplay = if ($null -ne $plan.ManagedBy -and $plan.ManagedBy -ne '') { $plan.ManagedBy } else { '(none)' }
    Write-Host ('uninstall-global: managedBy={0} managedByOk={1}' -f $managedByDisplay, $plan.ManagedByOk)
    Write-Host ('uninstall-global: installRootExpectedLocation={0} (canonical install-area path guard; expected={1})' -f $plan.ExpectedLocation, $expectedInstallAreaResolved)
    foreach ($t in $plan.Targets) {
        Write-Host ('uninstall-global: target name={0} kind={1} status={2} wouldRemove={3} blocked={4}' -f $t.Name, $t.Kind, $t.Status, $t.WouldRemove, $t.Blocked)
        Write-Host ('uninstall-global:   path   {0}' -f $t.Path)
        Write-Host ('uninstall-global:   reason {0}' -f $t.Reason)
    }
    $removable = @($plan.Targets | Where-Object { $_.WouldRemove }).Count
    $blocked   = @($plan.Targets | Where-Object { $_.Blocked }).Count
    $warned    = @($plan.Targets | Where-Object { $_.Status -eq 'warn' }).Count
    Write-Host ('uninstall-global: SUMMARY targets={0} wouldRemove={1} blocked={2} warn={3}' -f $plan.Targets.Count, $removable, $blocked, $warned)
}

# ---------------------------------------------------------------------------------------------------
# DRY-RUN (default): read-only inspection.
# ---------------------------------------------------------------------------------------------------
if (-not $Apply) {
    script:Write-UninstallPlanReport -Mode 'DRY-RUN (read-only; no deletion, no managed-block write, no .amb-backup, no mutation)'
    Write-Host ('uninstall-global: uninstallStatus={0}' -f $plan.OverallStatus)
    if ($plan.OverallStatus -eq 'uninstall_blocked') {
        Write-Host 'uninstall-global: NOTE blocked target(s) present — -Apply WOULD refuse until they are resolved. This dry-run performed no mutation.'
    }
    Write-Host 'uninstall-global: PASS (read-only dry-run completed)'
    exit 0
}

# ---------------------------------------------------------------------------------------------------
# APPLY (destructive): preflight-all-then-act.
# ---------------------------------------------------------------------------------------------------
script:Write-UninstallPlanReport -Mode 'APPLY (destructive)'

# Preflight: a single blocked target (malformed/duplicate/incomplete managed block, unexpected
# install-root content, managedBy mismatch, skill-path-shape failure) refuses the WHOLE apply.
$blockedTargets = @($plan.Targets | Where-Object { $_.Blocked })
if ($blockedTargets.Count -gt 0) {
    foreach ($b in $blockedTargets) {
        Write-Host ('uninstall-global: BLOCKED target name={0} reason={1}' -f $b.Name, $b.Reason)
    }
    Write-Host 'uninstall-global: uninstallStatus=uninstall_blocked'
    Write-Host 'uninstall-global: FAIL preflight blocked; no mutation performed.'
    exit 1
}
# Install-area path guard is ENFORCED for apply (it is evidence-only in dry-run). The supplied
# InstallArea must be EXACTLY the canonical install area (Get-StableInstallAreaCandidate; there is no
# operator override — test isolation is via the %USERPROFILE% the canonical function reads). This is
# checked REGARDLESS of whether the install root is present: apply also removes the destructive
# activation surfaces (managed blocks + skill mirrors under the homes), which are independent of the
# install root — so a non-canonical InstallArea must be refused BEFORE any surface removal, even when
# its (wrong) root happens to be absent. Gating on InstallRootPresent here would let a
# mismatched-but-absent target strip activation surfaces.
if (-not $plan.ExpectedLocation) {
    Write-Host ('uninstall-global: uninstallStatus=uninstall_blocked')
    Write-Host ('uninstall-global: FAIL install-area path guard failed (expected canonical install area {0}): {1}; no mutation performed.' -f $expectedInstallAreaResolved, $plan.InstallAreaPath)
    exit 1
}

$applyScript = Join-Path $PSScriptRoot 'apply-managed-block.ps1'
$surfaceFailed = $false

# (1) managed-block removal on the effective surfaces (removable only) via the shared hardened tool.
foreach ($t in @($plan.Targets | Where-Object { $_.Kind -eq 'managed-block' -and $_.WouldRemove })) {
    Write-Host ('uninstall-global: removing managed block from {0} (apply-managed-block -Remove)...' -f $t.Path)
    $proc = Invoke-NativeProcess -Executable 'powershell.exe' -Arguments @(
        '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $applyScript, '-Remove', '-TargetPath', $t.Path
    )
    $combined = ($proc.Stdout + $proc.Stderr).TrimEnd("`r", "`n")
    if (-not [string]::IsNullOrEmpty($combined)) {
        foreach ($line in ($combined -split "`r?`n")) { Write-Host ('uninstall-global:   ' + $line) }
    }
    if ($proc.ExitCode -ne 0) {
        Write-Host ('uninstall-global: managed-block removal FAILED for {0} (exit {1})' -f $t.Path, $proc.ExitCode)
        $surfaceFailed = $true
    }
}

# (2) owned skill MIRROR DIRECTORY removal (removable only), path-guarded per owned skill name.
foreach ($t in @($plan.Targets | Where-Object { $_.Kind -eq 'skill-mirror' -and $_.WouldRemove })) {
    $dir = [System.IO.Path]::GetFullPath($t.Path)
    $dLeaf   = Split-Path -Leaf $dir
    $dParent = Split-Path -Leaf (Split-Path -Parent $dir)
    # Guard against the owned skill's OWN name (skills/<name>), never a hardcoded skill: the dir leaf
    # must equal the plan target's SkillName and sit directly under a skills/ parent. This keeps the
    # removal bound to owned skills only (sibling skills under skills/ are never in the plan).
    $expectedLeaf = $t.SkillName
    if ([string]::IsNullOrEmpty($expectedLeaf) -or -not ($dLeaf -ieq $expectedLeaf -and $dParent -ieq 'skills')) {
        Write-Host ('uninstall-global: skill-mirror path guard FAILED (expected skills\{0}): {1}' -f $expectedLeaf, $dir)
        $surfaceFailed = $true
        continue
    }
    Write-Host ('uninstall-global: removing skill mirror directory {0}...' -f $dir)
    try {
        Remove-Item -LiteralPath $dir -Recurse -Force -ErrorAction Stop
        if (Test-Path -LiteralPath $dir) { throw 'skill mirror directory still present after removal' }
        Write-Host ('uninstall-global: removed skill mirror directory {0}' -f $dir)
    }
    catch {
        Write-Host ('uninstall-global: skill-mirror removal FAILED for {0}: {1}' -f $dir, $_.Exception.Message)
        $surfaceFailed = $true
    }
}

# A post-preflight runtime failure on any surface halts BEFORE the install-root deletion (no
# cross-surface transaction; the most destructive step is not taken in a partial state).
if ($surfaceFailed) {
    Write-Host 'uninstall-global: uninstallStatus=uninstall_partial'
    Write-Host 'uninstall-global: FAIL one or more surfaces failed to remove; install root NOT deleted (resolve and re-run).'
    exit 1
}

# (3) install-root deletion delegated to the self-contained temp finalizer.
if (-not $plan.InstallRootPresent) {
    Write-Host 'uninstall-global: install root already absent; surfaces removed.'
    Write-Host 'uninstall-global: uninstallStatus=uninstalled'
    Write-Host 'uninstall-global: PASS'
    exit 0
}

# Finalizer setup + launch run AFTER the surfaces are already removed. A throw ANYWHERE here —
# including run-id / path construction, temp-dir create, copy, input write, or Start-Process — must
# NOT crash uncaught (that would leave surfaces removed with no report). The ENTIRE setup, path
# construction included, is inside this try; on any failure report uninstall_partial with the
# attempted finalizer path and exit 1 (the install root is left intact for a re-run).
$selfDir = '(finalizer temp dir not yet created)'
try {
    $runId      = [Guid]::NewGuid().ToString('n')
    $selfDir    = Join-Path $FinalizerTempRoot ('ai-harness-uninstall-' + $runId)
    $resultPath = Join-Path $FinalizerTempRoot ('ai-harness-uninstall-' + $runId + '.result.json')
    $null = New-Item -ItemType Directory -Path $selfDir -Force
    $finalizerSrc  = Join-Path $PSScriptRoot 'uninstall-finalizer.ps1'
    $finalizerCopy = Join-Path $selfDir 'uninstall-finalizer.ps1'
    Copy-Item -LiteralPath $finalizerSrc -Destination $finalizerCopy -Force
    $inputPath  = Join-Path $selfDir 'finalizer-input.json'
    $inputObj = [ordered]@{
        installRoot         = $plan.InstallAreaPath
        expectedInstallArea = $expectedInstallAreaResolved
        parentPid           = $PID
        expectedEntries     = @(Get-UninstallExpectedRootEntries)
        resultPath          = $resultPath
        selfDir             = $selfDir
        timeoutSec          = 60
        pollMs              = 250
    }
    ($inputObj | ConvertTo-Json -Depth 6) | Out-File -LiteralPath $inputPath -Encoding utf8

    # Launch the finalizer DETACHED (no -Wait): it waits for THIS process (parentPid) to exit, then
    # deletes the install root and absence-verifies. Hidden window, no profile.
    # Start-Process -ArgumentList joins the array into ONE command line WITHOUT quoting each element,
    # so the -File / -InputPath paths MUST be explicitly double-quoted — otherwise a temp/user path
    # containing a space breaks the child's argument parsing and the finalizer silently never runs
    # (a false "launched" success after the surfaces are already removed).
    Start-Process -FilePath 'powershell.exe' -WindowStyle Hidden -ArgumentList @(
        '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', ('"{0}"' -f $finalizerCopy), '-InputPath', ('"{0}"' -f $inputPath)
    ) | Out-Null
}
catch {
    Write-Host ('uninstall-global: finalizer setup/launch FAILED: {0}' -f $_.Exception.Message)
    Write-Host ('uninstall-global: attempted finalizer temp dir={0}' -f $selfDir)
    Write-Host 'uninstall-global: uninstallStatus=uninstall_partial'
    Write-Host 'uninstall-global: FAIL surfaces were removed but the install-root finalizer could not be launched; install root left intact for a re-run.'
    exit 1
}

Write-Host ('uninstall-global: surfaces removed; install-root deletion delegated to the temp finalizer.')
Write-Host ('uninstall-global: finalizer={0}' -f $finalizerCopy)
Write-Host ('uninstall-global: finalizerResult={0} (written after the install root is deleted; check it for the outcome + any temp leftover path)' -f $resultPath)
Write-Host 'uninstall-global: uninstallStatus=uninstall_finalizer_launched'
Write-Host 'uninstall-global: PASS (managed-block + skill removed; install-root finalizer launched)'
exit 0
