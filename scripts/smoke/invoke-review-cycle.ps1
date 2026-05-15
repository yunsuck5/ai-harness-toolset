# invoke-review-cycle.ps1 — thin wrapper for review-cycle.ps1 (smoke driver use case only)
#
# Purpose: reliable invocation of scripts/review-cycle.ps1 from smoke drivers, by avoiding
# PowerShell 5.1 patterns that have caused driver-layer failures in earlier smoke rounds —
# specifically `Start-Process -ArgumentList <array>` (array form does not preserve quoting
# of multi-word substitution values) and `& $cycle ... 2>&1 | Select-Object -Last <N>`
# (2>&1 with pipe converts native Codex stderr lines to PowerShell NativeCommandError
# records, killing the pipeline at the first banner line).
#
# Responsibility (intentionally narrow):
#   - Accept the same parameter contract as scripts/review-cycle.ps1.
#   - Resolve the target review-cycle.ps1 path (default: ../review-cycle.ps1 relative to
#     this wrapper) or honor an explicit -ReviewCyclePath override.
#   - Forward the parameters to review-cycle.ps1 via PowerShell parameter splatting (`@args`),
#     which preserves each value — including multi-word strings — as exactly one argument
#     regardless of the value's word count or embedded quoting.
#   - Pass the child's exit code through verbatim.
#
# Out of scope (DO NOT add):
#   - Modifying review-cycle.ps1's parameter contract.
#   - Reformatting, summarizing, filtering, or rewriting the child's stdout / stderr.
#   - 2>&1, Out-String, Select-Object, ForEach-Object wrapping of the child invocation.
#   - Start-Process or any indirect child launch.
#   - Retry, fallback model, auto-fix, or auto-recovery logic.
#   - Generic PowerShell quoting framework or cross-shell quoting helper.
#   - daemon / watcher / scheduler / background automation.
#   - Anything outside the smoke driver invocation use case.
#
# This wrapper is governed by the PowerShell smoke invocation quoting hardening backlog
# item in docs/backlog/operations.md (option W). It does not approve install/update
# automation, CH3-D execution, or any criteria change.

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('design', 'implementation', 'test', 'review', 'release')]
    [string] $Stage,

    [Parameter(Mandatory = $true)]
    [string] $Purpose,

    [string[]] $TargetFiles,
    [string]   $TargetFilesPath,
    [string]   $Context,
    [string]   $RequiredInspectionPaths,
    [string]   $ReviewQuestions,
    [string]   $Constraints,
    [string]   $Reviewer,
    [string]   $RunId,
    [string]   $ProjectRoot,
    [string]   $ToolRoot,

    # Override for the child review-cycle.ps1 path. Default: ../review-cycle.ps1 relative
    # to this wrapper. Tests use this to point at a fake child script.
    [string] $ReviewCyclePath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Resolve the child review-cycle.ps1 path.
if ([string]::IsNullOrEmpty($ReviewCyclePath)) {
    $ReviewCyclePath = Join-Path $PSScriptRoot '..\review-cycle.ps1'
}

if (-not (Test-Path -LiteralPath $ReviewCyclePath -PathType Leaf)) {
    [Console]::Error.WriteLine("invoke-review-cycle: review-cycle.ps1 not found at: $ReviewCyclePath")
    exit 2
}

# Build a splat hashtable from bound parameters. Unbound / empty parameters are not
# forwarded, so review-cycle.ps1 sees the same value set as if the operator had called it
# directly. PowerShell parameter splatting preserves each value as a single argument
# regardless of whitespace, embedded quotes, or word count — which is the entire point
# of this wrapper.
$childArgs = [ordered]@{}
$childArgs['Stage']   = $Stage
$childArgs['Purpose'] = $Purpose

$optionalParams = @(
    'TargetFiles', 'TargetFilesPath', 'Context', 'RequiredInspectionPaths',
    'ReviewQuestions', 'Constraints', 'Reviewer', 'RunId', 'ProjectRoot', 'ToolRoot'
)
foreach ($name in $optionalParams) {
    if (-not $PSBoundParameters.ContainsKey($name)) { continue }
    $value = $PSBoundParameters[$name]
    if ($null -eq $value) { continue }
    if ($value -is [string] -and [string]::IsNullOrEmpty($value)) { continue }
    if ($value -is [array] -and $value.Count -eq 0) { continue }
    $childArgs[$name] = $value
}

# Invoke the child with splatting. Native stdout/stderr stream unchanged to the host.
# No 2>&1 redirect, no pipeline wrapper — both have historically killed smoke driver
# invocations on the first stderr line from Codex.
& $ReviewCyclePath @childArgs

# Pass the child's exit code through verbatim. PowerShell sets $LASTEXITCODE from a
# .ps1 invocation when the child calls `exit N`; we forward N as our own exit code.
exit $LASTEXITCODE
