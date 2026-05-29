[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)] [string] $InputPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# SELF-CONTAINED uninstall temp finalizer (IU-B-08 batch 3, decision O4).
#
# Runs from a %TEMP% run-id directory AFTER the uninstall main entrypoint (scripts/uninstall-global.ps1
# -Apply) has exited. It deletes the global install ROOT, which the still-running main entrypoint
# could NOT delete because it executed from inside that tree (a process cannot reliably delete the
# directory holding its own running scripts on Windows).
#
# SELF-CONTAINED INVARIANT: this script dot-sources NOTHING from the install root (that tree is about
# to be deleted) — every helper is inline here. Its only input is a small JSON file written OUTSIDE
# the install root by the main entrypoint.
#
# Input JSON fields:
#   installRoot     : the install ROOT to delete (e.g. %USERPROFILE%\.claude\ai-harness-toolset)
#   parentPid       : PID of the main entrypoint to wait for (delete only after it exits)
#   expectedEntries : top-level footprint allow-list (from lib/uninstall-target.ps1's single source
#                     of truth; used for a defensive unexpected-content re-check before deleting)
#   resultPath      : where to write the outcome JSON (MUST be OUTSIDE selfDir so it survives self-clean)
#   selfDir         : the finalizer's own temp dir to best-effort self-clean
#   timeoutSec      : max seconds to wait for the parent to exit (default 60)
#   pollMs          : parent-exit poll interval (default 250)
#
# It NEVER deletes anything but the resolved install root (after a re-guard), and NEVER touches
# ClaudeHome/CodexHome/skills/instruction files — those are handled by the main entrypoint before
# this finalizer is launched.

$cfg = Get-Content -LiteralPath $InputPath -Raw | ConvertFrom-Json
$cfgNames    = @($cfg.PSObject.Properties.Name)
$installRoot = [System.IO.Path]::GetFullPath([string]$cfg.installRoot)
$parentPid   = [int]$cfg.parentPid
$expected    = @($cfg.expectedEntries)
$resultPath  = [string]$cfg.resultPath
$selfDir     = [string]$cfg.selfDir
$timeoutSec  = if ($cfgNames -contains 'timeoutSec') { [int]$cfg.timeoutSec } else { 60 }
$pollMs      = if ($cfgNames -contains 'pollMs') { [int]$cfg.pollMs } else { 250 }

function script:Write-FinalizerResult {
    param([string] $Status, [bool] $Deleted, [string] $Leftover)
    if (-not [string]::IsNullOrEmpty($resultPath)) {
        try {
            $parent = Split-Path -Parent $resultPath
            if (-not [string]::IsNullOrEmpty($parent) -and -not (Test-Path -LiteralPath $parent)) {
                $null = New-Item -ItemType Directory -Path $parent -Force
            }
            $obj = [ordered]@{
                status             = $Status
                installRoot        = $installRoot
                installRootDeleted = $Deleted
                selfCleanLeftover  = $Leftover
                finishedAt         = (Get-Date).ToString('o')
            }
            ($obj | ConvertTo-Json -Depth 6) | Out-File -LiteralPath $resultPath -Encoding utf8
        }
        catch { }
    }
    $leftoverDisplay = if (-not [string]::IsNullOrEmpty($Leftover)) { $Leftover } else { '(none)' }
    Write-Host ('uninstall-finalizer: status={0} installRootDeleted={1} selfCleanLeftover={2}' -f $Status, $Deleted, $leftoverDisplay)
}

function script:Invoke-BestEffortSelfClean {
    # Best-effort removal of the finalizer's own temp dir. Failure is NON-FATAL: report the exact
    # temp path as leftover (it may fail because this very script file lives inside selfDir and is
    # still held by the running process — an accepted, documented limitation).
    if ([string]::IsNullOrEmpty($selfDir) -or -not (Test-Path -LiteralPath $selfDir)) { return $null }
    try {
        Remove-Item -LiteralPath $selfDir -Recurse -Force -ErrorAction Stop
        if (Test-Path -LiteralPath $selfDir) { return $selfDir }
        return $null
    }
    catch {
        return $selfDir
    }
}

# 1. Wait for the parent (main entrypoint) to exit, so the install-root scripts are no longer loaded.
$deadline = (Get-Date).AddSeconds($timeoutSec)
while ((Get-Date) -lt $deadline) {
    if ($null -eq (Get-Process -Id $parentPid -ErrorAction SilentlyContinue)) { break }
    Start-Sleep -Milliseconds $pollMs
}
if ($null -ne (Get-Process -Id $parentPid -ErrorAction SilentlyContinue)) {
    # Parent still alive after the timeout: refuse to delete (the whole point is to wait it out).
    script:Write-FinalizerResult -Status 'finalizer_parent_wait_timeout' -Deleted $false -Leftover (script:Invoke-BestEffortSelfClean)
    exit 1
}

# 2. Re-guard the install-root path (self-contained): normalize, then require the canonical
#    <...>\.claude\ai-harness-toolset shape. Never delete a path that fails this guard.
$leaf       = Split-Path -Leaf $installRoot
$parentLeaf = Split-Path -Leaf (Split-Path -Parent $installRoot)
if (-not ($leaf -ieq 'ai-harness-toolset' -and $parentLeaf -ieq '.claude')) {
    script:Write-FinalizerResult -Status 'finalizer_path_guard_failed' -Deleted $false -Leftover (script:Invoke-BestEffortSelfClean)
    exit 1
}

# 3. Already absent -> idempotent success.
if (-not (Test-Path -LiteralPath $installRoot -PathType Container)) {
    script:Write-FinalizerResult -Status 'uninstalled' -Deleted $true -Leftover (script:Invoke-BestEffortSelfClean)
    exit 0
}

# 4. Defensive re-check: refuse if unexpected top-level content appeared since the main entrypoint's
#    preflight (do NOT delete an install root that now holds something outside the expected footprint).
$unexpected = @(Get-ChildItem -LiteralPath $installRoot -Force | Where-Object { $expected -inotcontains $_.Name })
if ($unexpected.Count -gt 0) {
    script:Write-FinalizerResult -Status 'finalizer_unexpected_content' -Deleted $false -Leftover (script:Invoke-BestEffortSelfClean)
    exit 1
}

# 5. Delete the install root, then verify absence.
try {
    Remove-Item -LiteralPath $installRoot -Recurse -Force -ErrorAction Stop
}
catch {
    script:Write-FinalizerResult -Status 'finalizer_delete_failed' -Deleted $false -Leftover (script:Invoke-BestEffortSelfClean)
    exit 1
}
if (Test-Path -LiteralPath $installRoot) {
    script:Write-FinalizerResult -Status 'finalizer_delete_verify_failed' -Deleted $false -Leftover (script:Invoke-BestEffortSelfClean)
    exit 1
}

# 6. Success. Best-effort self-clean; a leftover temp dir is non-fatal and reported with its path.
$leftover = script:Invoke-BestEffortSelfClean
$status = if ([string]::IsNullOrEmpty($leftover)) { 'uninstalled' } else { 'uninstalled_with_finalizer_leftover' }
script:Write-FinalizerResult -Status $status -Deleted $true -Leftover $leftover
exit 0
