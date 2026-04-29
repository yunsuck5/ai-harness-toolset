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

$runDir = Join-Path -Path $logRoot -ChildPath ('review/' + $RunId)
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
