[CmdletBinding()]
param(
    [string] $ProjectRoot,
    [switch] $Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'lib/path.ps1')
. (Join-Path $PSScriptRoot 'lib/encoding.ps1')

$project = Get-ProjectRoot -ProjectRoot $ProjectRoot
$logRoot = Get-ProjectLogRoot -ProjectRoot $project

$dirs = @(
    $logRoot,
    (Join-Path $logRoot 'chatlog'),
    (Join-Path $logRoot 'evidence'),
    (Join-Path $logRoot 'review')
)

foreach ($d in $dirs) {
    [void] (Assert-InProjectLogRoot -Path $d -ProjectLogRoot $logRoot)
    if (-not (Test-Path -LiteralPath $d -PathType Container)) {
        $null = New-Item -ItemType Directory -Path $d -Force
        Write-Host ('log-init: created {0}' -f $d)
    }
    else {
        Write-Host ('log-init: exists  {0}' -f $d)
    }
}

Write-Host ('log-init: done. ProjectRoot={0}' -f $project)
exit 0
