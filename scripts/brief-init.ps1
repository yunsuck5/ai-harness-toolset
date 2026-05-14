[CmdletBinding()]
param(
    [string] $ProjectRoot,
    [string] $ToolRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'lib/encoding.ps1')
. (Join-Path $PSScriptRoot 'lib/path.ps1')

$project = Get-ProjectRoot -ProjectRoot $ProjectRoot
$tool    = Get-ToolRoot -ToolRoot $ToolRoot -ProjectRoot $project

$templatePath = Join-Path -Path $tool -ChildPath 'templates/brief/BRIEF.md'
if (-not (Test-Path -LiteralPath $templatePath -PathType Leaf)) {
    Write-Host ('brief-init: FAIL template not found: {0}' -f $templatePath)
    Write-Host ('brief-init: ToolRoot={0}. Ensure templates/brief/BRIEF.md exists under ToolRoot.' -f $tool)
    exit 1
}

$briefDir  = Join-Path -Path $project -ChildPath 'log/brief'
$briefPath = Join-Path -Path $briefDir -ChildPath 'BRIEF.md'

[void] (Assert-InProjectRoot -Path $briefDir  -ProjectRoot $project)
[void] (Assert-InProjectRoot -Path $briefPath -ProjectRoot $project)

if (Test-Path -LiteralPath $briefPath -PathType Leaf) {
    Write-Host ('brief-init: refused. BRIEF.md already exists: {0}' -f $briefPath)
    Write-Host 'brief-init: existing BRIEF.md is not overwritten. Edit it by hand or remove it explicitly before re-running.'
    exit 1
}

if (-not (Test-Path -LiteralPath $briefDir -PathType Container)) {
    $null = New-Item -ItemType Directory -Path $briefDir -Force
    Write-Host ('brief-init: created directory {0}' -f $briefDir)
}

$content = Read-Utf8 -Path $templatePath
Write-Utf8NoBom -Path $briefPath -Content $content

Write-Host ('brief-init: seeded {0}' -f $briefPath)
Write-Host ('brief-init: source template {0}' -f $templatePath)
Write-Host 'brief-init: PASS'
exit 0
