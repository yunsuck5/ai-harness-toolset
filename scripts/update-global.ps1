[CmdletBinding()]
param(
    # The install ROOT to update. Default %USERPROFILE%\ai-harness-toolset (single source of truth =
    # Get-StableInstallAreaCandidate in lib/path.ps1). Overridable so tests never touch the real
    # %USERPROFILE%.
    [string] $InstallArea,

    # Forwarded to install-update.ps1 -Mode update-source (source identity / ref selection).
    [string] $SourcePath,
    [string] $RepoUrl,
    [string] $Branch,
    [string] $Remote,
    [string] $Ref,

    [string] $ClaudeHome,
    [string] $CodexHome,

    [switch] $SkipSmoke,
    [switch] $ConfirmInteractive,
    [switch] $Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# IU-B-09 operator-facing EXISTING-install update entrypoint.
#
# This is a THIN wrapper that makes "update an existing global install" reachable by name, alongside
# scripts/install-global.ps1 (fresh install) and scripts/uninstall-global.ps1 (teardown). It does NOT
# reimplement update-source logic: it fail-fasts when there is no valid existing install, then delegates
# to scripts/install-update.ps1 -Mode update-source, which remains the existing-update / internal /
# compat implementation. install-update.ps1 behavior is unchanged by this wrapper.
#
#   - install area missing / no install.json  -> fail-fast, point the user to scripts/install-global.ps1.
#   - install.json present but invalid         -> fail-fast (point to a fresh install or `-Mode verify`).
#   - valid existing install                   -> delegate to install-update.ps1 -Mode update-source,
#                                                 forwarding the source/ref/home/smoke arguments and
#                                                 returning its exit code + output verbatim.

. (Join-Path $PSScriptRoot 'lib/encoding.ps1')
. (Join-Path $PSScriptRoot 'lib/path.ps1')
. (Join-Path $PSScriptRoot 'lib/install-pipeline-core.ps1')
. (Join-Path $PSScriptRoot 'lib/native-process.ps1')

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

$installAreaResolved = [System.IO.Path]::GetFullPath($InstallArea)
$installUpdateScript = Join-Path $PSScriptRoot 'install-update.ps1'

Write-Host 'update-global: mode=UPDATE (existing-install update)'
Write-Host ('update-global: installArea={0}' -f $installAreaResolved)

function script:Stop-Update {
    param([string] $Message)
    Write-Host ('update-global: FAIL ' + $Message)
    Write-Host 'update-global: updateStatus=update_failed'
    Write-Host 'update-global: FAIL'
    exit 1
}

# ---------------------------------------------------------------------------------------------------
# 1. Existing-install precheck — update-global is EXISTING-install only.
# ---------------------------------------------------------------------------------------------------
if (-not (Test-Path -LiteralPath $installAreaResolved -PathType Container)) {
    script:Stop-Update ('no install area found at ' + $installAreaResolved + '. There is nothing to update. Use scripts/install-global.ps1 for a fresh install.')
}
$metadataPath = Join-Path $installAreaResolved 'install.json'
if (-not (Test-Path -LiteralPath $metadataPath -PathType Leaf)) {
    script:Stop-Update ('no install.json under ' + $installAreaResolved + ' — this is not a valid install. Use scripts/install-global.ps1 for a fresh install.')
}
try {
    $md = Read-InstallPipelineMetadata -InstallArea $installAreaResolved
}
catch {
    script:Stop-Update ('install.json is present but invalid (' + $_.Exception.Message + '). Use scripts/install-global.ps1 for a fresh install, or inspect with scripts/install-update.ps1 -Mode verify.')
}
if ($null -eq $md) {
    script:Stop-Update ('install.json could not be read under ' + $installAreaResolved + '. Use scripts/install-global.ps1 for a fresh install.')
}
# Structural validity: a parseable install.json with the right schemaVersion but a missing required
# field (e.g. installMode) is INVALID, not silently delegated — and must be checked before any field
# is dereferenced (Set-StrictMode would otherwise throw an uncaught terminating error on the missing
# property instead of emitting the controlled update_failed guidance). The canonical field set is
# provided by the dot-sourced install-pipeline-core.ps1.
$mdFields = @($md.PSObject.Properties.Name)
$missingFields = @($script:InstallPipelineMetadataFields | Where-Object { $mdFields -cnotcontains $_ })
if ($missingFields.Count -gt 0) {
    script:Stop-Update ('install.json is present but invalid (missing required field(s): ' + ($missingFields -join ', ') + '). Use scripts/install-global.ps1 for a fresh install, or inspect with scripts/install-update.ps1 -Mode verify.')
}
Write-Host ('update-global: existing install detected (installMode={0}); delegating to install-update.ps1 -Mode update-source' -f [string]$md.installMode)

# ---------------------------------------------------------------------------------------------------
# 2. Delegate to install-update.ps1 -Mode update-source (the canonical update implementation). Forward
#    only the arguments the operator supplied; install-update applies its own guards (source-cut,
#    metadata identity, resolved HEAD, command-implied approval).
# ---------------------------------------------------------------------------------------------------
$childArgs = @(
    '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $installUpdateScript,
    '-Mode', 'update-source',
    '-InstallArea', $installAreaResolved,
    '-ClaudeHome', $ClaudeHome,
    '-CodexHome', $CodexHome
)
if (-not [string]::IsNullOrEmpty($SourcePath)) { $childArgs += @('-SourcePath', $SourcePath) }
if (-not [string]::IsNullOrEmpty($RepoUrl))    { $childArgs += @('-RepoUrl', $RepoUrl) }
if (-not [string]::IsNullOrEmpty($Branch))     { $childArgs += @('-Branch', $Branch) }
if (-not [string]::IsNullOrEmpty($Remote))     { $childArgs += @('-Remote', $Remote) }
if (-not [string]::IsNullOrEmpty($Ref))        { $childArgs += @('-Ref', $Ref) }
if ($SkipSmoke)          { $childArgs += '-SkipSmoke' }
if ($ConfirmInteractive) { $childArgs += '-ConfirmInteractive' }
if ($Json)               { $childArgs += '-Json' }

$proc = Invoke-NativeProcess -Executable 'powershell.exe' -Arguments $childArgs

# Re-emit the delegate's output verbatim (stdout then stderr) and forward its exit code, so the
# wrapper is transparent — it adds the lifecycle name, not new behavior.
if (-not [string]::IsNullOrEmpty($proc.Stdout)) {
    foreach ($line in ($proc.Stdout.TrimEnd("`r", "`n") -split "`r?`n")) { Write-Host $line }
}
if (-not [string]::IsNullOrEmpty($proc.Stderr)) {
    foreach ($line in ($proc.Stderr.TrimEnd("`r", "`n") -split "`r?`n")) { [Console]::Error.WriteLine($line) }
}

if ($proc.ExitCode -eq 0) {
    Write-Host 'update-global: updateStatus=delegated_ok'
    Write-Host 'update-global: PASS (delegated to install-update.ps1 -Mode update-source)'
}
else {
    Write-Host ('update-global: updateStatus=delegated_nonzero (install-update.ps1 exit {0})' -f $proc.ExitCode)
    Write-Host 'update-global: FAIL (delegate reported a non-zero exit; see its output above)'
}
exit $proc.ExitCode
