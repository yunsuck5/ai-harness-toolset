[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $RunId,

    [string] $ProjectRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'lib/encoding.ps1')
. (Join-Path $PSScriptRoot 'lib/path.ps1')
. (Join-Path $PSScriptRoot 'lib/hash.ps1')
. (Join-Path $PSScriptRoot 'lib/json.ps1')

$project = Get-ProjectRoot -ProjectRoot $ProjectRoot
$logRoot = Get-ProjectLogRoot -ProjectRoot $project

try {
    [void] (Assert-ValidRunId -Value $RunId)
}
catch {
    Write-Host ('review-verify: FAIL invalid RunId: {0}' -f $RunId)
    exit 1
}

$runDir = Join-Path -Path $logRoot -ChildPath ('review/' + $RunId)
try {
    [void] (Assert-InReviewRunRoot -Path $runDir -ProjectLogRoot $logRoot)
}
catch {
    Write-Host ('review-verify: FAIL run directory outside review root: {0}' -f $runDir)
    exit 1
}

if (-not (Test-Path -LiteralPath $runDir -PathType Container)) {
    Write-Host ('review-verify: FAIL run directory not found: {0}' -f $runDir)
    exit 1
}

$metaPath = Join-Path -Path $runDir -ChildPath 'meta.json'
if (-not (Test-Path -LiteralPath $metaPath -PathType Leaf)) {
    Write-Host ('review-verify: FAIL meta.json not found: {0}' -f $metaPath)
    exit 1
}

$meta = Read-JsonFile -Path $metaPath

$metaProjectRoot = ''
if ($null -ne $meta.PSObject.Properties['projectRoot']) {
    $metaProjectRoot = [string]$meta.projectRoot
}
if ([string]::IsNullOrEmpty($metaProjectRoot)) {
    Write-Host 'review-verify: FAIL meta.projectRoot missing'
    exit 1
}

$metaProjectLogRoot = ''
if ($null -ne $meta.PSObject.Properties['projectLogRoot']) {
    $metaProjectLogRoot = [string]$meta.projectLogRoot
}
if ([string]::IsNullOrEmpty($metaProjectLogRoot)) {
    Write-Host 'review-verify: FAIL meta.projectLogRoot missing'
    exit 1
}

$sep = [System.IO.Path]::DirectorySeparatorChar
$metaProjectFull = ([System.IO.Path]::GetFullPath($metaProjectRoot)).TrimEnd($sep)
$metaLogFull     = ([System.IO.Path]::GetFullPath($metaProjectLogRoot)).TrimEnd($sep)
$projectNorm     = $project.TrimEnd($sep)
$logRootNorm     = $logRoot.TrimEnd($sep)
$cmp = [System.StringComparison]::OrdinalIgnoreCase

if (-not [string]::Equals($metaProjectFull, $projectNorm, $cmp)) {
    Write-Host ('review-verify: FAIL projectRoot mismatch. meta={0} runtime={1}' -f $metaProjectFull, $projectNorm)
    exit 1
}
if (-not [string]::Equals($metaLogFull, $logRootNorm, $cmp)) {
    Write-Host ('review-verify: FAIL projectLogRoot mismatch. meta={0} runtime={1}' -f $metaLogFull, $logRootNorm)
    exit 1
}

$targetPath = [string]$meta.targetPath
if (-not (Test-Path -LiteralPath $targetPath -PathType Leaf)) {
    Write-Host ('review-verify: FAIL target file not found: {0}' -f $targetPath)
    exit 1
}

try {
    [void] (Assert-InProjectRoot -Path $targetPath -ProjectRoot $project)
}
catch {
    Write-Host ('review-verify: FAIL target outside ProjectRoot: {0}' -f $targetPath)
    exit 1
}

$expectedSha = [string]$meta.targetSha256
$actualSha   = Get-FileSha256 -Path $targetPath
if ($expectedSha -ne $actualSha) {
    Write-Host ('review-verify: FAIL stale. expected={0} actual={1}' -f $expectedSha, $actualSha)
    exit 1
}

$resultPath = Join-Path -Path $runDir -ChildPath 'result.md'
if (Test-Path -LiteralPath $resultPath -PathType Leaf) {
    Write-Host 'review-verify: result.md present (informational)'
}
else {
    Write-Host 'review-verify: result.md not present (informational)'
}

Write-Host ('review-verify: PASS run-id {0}' -f $RunId)
exit 0
