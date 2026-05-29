[CmdletBinding()]
param(
    [string] $InstallArea,
    [string] $ClaudeHome,
    [string] $CodexHome,
    # NOT implemented in this batch. -Apply (or any accidental apply intent) FAIL-FASTS so a
    # read-only dry-run entrypoint can never silently perform a destructive action. The actual
    # uninstall apply / finalizer path is a separate later batch.
    [switch] $Apply
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# IU-B-08 batch 2: READ-ONLY uninstall target resolver + dry-run ONLY.
#
# This entrypoint inspects what a future destructive uninstall WOULD touch and reports it. It
# performs NO deletion, NO managed-block removal write, NO .amb-backup, NO instruction-file
# mutation, NO finalizer. There is intentionally no working apply path here.

. (Join-Path $PSScriptRoot 'lib/encoding.ps1')
. (Join-Path $PSScriptRoot 'lib/managed-block.ps1')
. (Join-Path $PSScriptRoot 'lib/activation-surface.ps1')
. (Join-Path $PSScriptRoot 'lib/install-pipeline-core.ps1')
. (Join-Path $PSScriptRoot 'lib/uninstall-target.ps1')

# Accidental-apply guard: refuse -Apply fail-fast (this batch ships dry-run only).
if ($Apply) {
    Write-Host 'uninstall-global: FAIL -Apply is not implemented in this batch (read-only dry-run only).'
    Write-Host 'uninstall-global: the destructive uninstall apply / finalizer path is a separate later batch; refusing to proceed.'
    Write-Host 'uninstall-global: uninstallStatus=apply_not_implemented'
    Write-Host 'uninstall-global: FAIL'
    exit 1
}

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
    $InstallArea = Join-Path $ClaudeHome 'ai-harness-toolset'
}

$plan = Get-UninstallPlan -InstallArea $InstallArea -ClaudeHome $ClaudeHome -CodexHome $CodexHome

Write-Host 'uninstall-global: mode=DRY-RUN (read-only; no deletion, no managed-block write, no .amb-backup, no mutation)'
Write-Host ('uninstall-global: installArea={0}' -f $plan.InstallAreaPath)
Write-Host ('uninstall-global: installRootPresent={0}' -f $plan.InstallRootPresent)
$managedByDisplay = if ($null -ne $plan.ManagedBy -and $plan.ManagedBy -ne '') { $plan.ManagedBy } else { '(none)' }
Write-Host ('uninstall-global: managedBy={0} managedByOk={1}' -f $managedByDisplay, $plan.ManagedByOk)
Write-Host ('uninstall-global: installRootExpectedLocation={0} (.claude\ai-harness-toolset path-guard evidence for the future destructive op)' -f $plan.ExpectedLocation)

foreach ($t in $plan.Targets) {
    Write-Host ('uninstall-global: target name={0} kind={1} status={2} wouldRemove={3} blocked={4}' -f $t.Name, $t.Kind, $t.Status, $t.WouldRemove, $t.Blocked)
    Write-Host ('uninstall-global:   path   {0}' -f $t.Path)
    Write-Host ('uninstall-global:   reason {0}' -f $t.Reason)
}

$removable = @($plan.Targets | Where-Object { $_.WouldRemove }).Count
$blocked   = @($plan.Targets | Where-Object { $_.Blocked }).Count
$warned    = @($plan.Targets | Where-Object { $_.Status -eq 'warn' }).Count
Write-Host ('uninstall-global: SUMMARY targets={0} wouldRemove={1} blocked={2} warn={3}' -f $plan.Targets.Count, $removable, $blocked, $warned)
Write-Host ('uninstall-global: uninstallStatus={0}' -f $plan.OverallStatus)
if ($plan.OverallStatus -eq 'uninstall_blocked') {
    Write-Host 'uninstall-global: NOTE blocked target(s) present — a future apply WOULD refuse until they are resolved. This dry-run performed no mutation.'
}
# A dry-run is a read-only inspection: a completed inspection is exit 0 regardless of whether the
# (hypothetical) future apply would be blocked. uninstallStatus carries the preview/blocked signal.
Write-Host 'uninstall-global: PASS (read-only dry-run completed)'
exit 0
