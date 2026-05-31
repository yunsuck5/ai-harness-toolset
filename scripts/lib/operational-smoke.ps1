Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Shared operational smoke helper.
#
# Extracted from scripts/install-update.ps1 (IU-B-09) so both the existing-install update path
# (install-update.ps1 update-source) and the fresh-install path (install-global.ps1) reuse ONE
# smoke implementation rather than each carrying its own. Behavior is unchanged from the original
# install-update.ps1 helper: it runs the payload's brief-init in a throwaway temp workspace and
# asserts the seeded BRIEF.md is byte-identical (SHA-256) to the payload's BRIEF template, isolated
# and cleaned up on pass, preserved-for-debug on fail.
#
# Dependencies (dot-sourced by callers): lib/native-process.ps1 (Invoke-NativeProcess),
# lib/hash.ps1 (Get-FileSha256).
#
# This is NOT a global/user mutation: the only filesystem writes are under a per-run temp workspace
# (%TEMP%\iu-smoke-<guid>\log\), removed on pass and reported (not silently deleted) on fail.

function Invoke-OperationalSmoke {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)] [string] $PayloadRoot
    )

    $briefInit   = Join-Path $PayloadRoot 'scripts/brief-init.ps1'
    $templateRel = 'templates/brief/BRIEF.md'
    $template    = Join-Path $PayloadRoot $templateRel

    if (-not (Test-Path -LiteralPath $briefInit -PathType Leaf) -or -not (Test-Path -LiteralPath $template -PathType Leaf)) {
        return [pscustomobject]@{ Smoke = 'skip'; Reason = ('smoke prerequisites missing under payload (' + $briefInit + ' / ' + $templateRel + ')'); WorkspacePath = $null }
    }

    $workspace = Join-Path ([System.IO.Path]::GetTempPath()) ('iu-smoke-' + [Guid]::NewGuid().ToString('N'))
    # On smoke FAILURE the throwaway workspace is PRESERVED for debugging and its path is reported
    # (in the result WorkspacePath + in the failure Reason, which the caller folds into reasons[]),
    # mirroring the cleanup_failed_with_leftover "report, don't silently delete" contract (I14).
    # It is removed only on pass. The path is surfaced so a failing smoke can be inspected.
    $preserveForDebug = $false
    try {
        $null = New-Item -ItemType Directory -Path $workspace -Force
        # brief-init resolves ToolRoot from the payload and seeds <ProjectRoot>/log/brief/BRIEF.md.
        $proc = Invoke-NativeProcess -Executable 'powershell.exe' -Arguments @(
            '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $briefInit,
            '-ToolRoot', $PayloadRoot, '-ProjectRoot', $workspace
        )
        if ($proc.ExitCode -ne 0) {
            $preserveForDebug = $true
            return [pscustomobject]@{ Smoke = 'fail'; Reason = ('brief-init exit ' + $proc.ExitCode + ' (workspace preserved: ' + $workspace + '): ' + (($proc.Stdout + ' ' + $proc.Stderr).Trim())); WorkspacePath = $workspace }
        }
        $seeded = Join-Path $workspace 'log/brief/BRIEF.md'
        if (-not (Test-Path -LiteralPath $seeded -PathType Leaf)) {
            $preserveForDebug = $true
            return [pscustomobject]@{ Smoke = 'fail'; Reason = ('seeded BRIEF.md not found at ' + $seeded + ' (workspace preserved: ' + $workspace + ')'); WorkspacePath = $workspace }
        }
        $seededSha   = Get-FileSha256 -Path $seeded
        $templateSha = Get-FileSha256 -Path $template
        if ($seededSha -ne $templateSha) {
            $preserveForDebug = $true
            return [pscustomobject]@{ Smoke = 'fail'; Reason = ('seeded BRIEF.md sha256 differs from payload template (' + $seededSha + ' vs ' + $templateSha + ') (workspace preserved: ' + $workspace + ')'); WorkspacePath = $workspace }
        }
        # Isolation: the only runtime artifact must be under <workspace>/log/.
        $outsideLog = @(Get-ChildItem -LiteralPath $workspace -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne 'log' })
        if ($outsideLog.Count -gt 0) {
            $preserveForDebug = $true
            return [pscustomobject]@{ Smoke = 'fail'; Reason = ('smoke produced artifacts outside log/: ' + (($outsideLog | ForEach-Object { $_.Name }) -join ', ') + ' (workspace preserved: ' + $workspace + ')'); WorkspacePath = $workspace }
        }
        return [pscustomobject]@{ Smoke = 'pass'; Reason = $null; WorkspacePath = $null }
    }
    catch {
        $preserveForDebug = $true
        return [pscustomobject]@{ Smoke = 'fail'; Reason = ('smoke exception: ' + $_.Exception.Message + ' (workspace preserved: ' + $workspace + ')'); WorkspacePath = $workspace }
    }
    finally {
        if (-not $preserveForDebug -and (Test-Path -LiteralPath $workspace)) {
            Remove-Item -LiteralPath $workspace -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
