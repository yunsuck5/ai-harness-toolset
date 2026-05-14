[CmdletBinding()]
param(
    [string] $ProjectRoot,
    [string] $BriefPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'lib/encoding.ps1')
. (Join-Path $PSScriptRoot 'lib/path.ps1')

$project = Get-ProjectRoot -ProjectRoot $ProjectRoot

if ([string]::IsNullOrEmpty($BriefPath)) {
    $BriefPath = Join-Path -Path $project -ChildPath 'log/brief/BRIEF.md'
}
elseif (-not [System.IO.Path]::IsPathRooted($BriefPath)) {
    $BriefPath = Join-Path -Path $project -ChildPath $BriefPath
}
$BriefPath = [System.IO.Path]::GetFullPath($BriefPath)

try {
    [void] (Assert-InProjectRoot -Path $BriefPath -ProjectRoot $project)
}
catch {
    Write-Host ('brief-check: FAIL BriefPath outside ProjectRoot: {0}' -f $BriefPath)
    exit 1
}

if (-not (Test-Path -LiteralPath $BriefPath -PathType Leaf)) {
    Write-Host ('brief-check: FAIL BRIEF.md not found: {0}' -f $BriefPath)
    exit 1
}

$content = Read-Utf8 -Path $BriefPath

$requiredHeadings = @(
    '## Current state',
    '## Last completed action',
    '## Current scope',
    '## Next single action',
    '## Do not do',
    '## Files to inspect first',
    '## Open risks',
    '## Pending user decision'
)

$lines = $content -split "`r?`n"

$headingPositions = @{}
for ($i = 0; $i -lt $lines.Count; $i++) {
    $trimmed = $lines[$i].TrimEnd()
    foreach ($h in $requiredHeadings) {
        if ($trimmed -eq $h) {
            if ($headingPositions.ContainsKey($h)) {
                Write-Host ('brief-check: FAIL duplicate required heading: {0}' -f $h)
                exit 1
            }
            $headingPositions[$h] = $i
        }
    }
}

foreach ($h in $requiredHeadings) {
    if (-not $headingPositions.ContainsKey($h)) {
        Write-Host ('brief-check: FAIL missing required heading: {0}' -f $h)
        exit 1
    }
}

$tokenMatch = [regex]::Match($content, '\{\{[A-Za-z_][A-Za-z0-9_]*\}\}')
if ($tokenMatch.Success) {
    Write-Host ('brief-check: FAIL unreplaced placeholder marker: {0}' -f $tokenMatch.Value)
    exit 1
}

$forbidden = @(
    '(Replace this section with project-specific content.)'
)

$sortedHeadings = $requiredHeadings | Sort-Object { $headingPositions[$_] }

$nextHeadingPattern = '^##\s'

for ($idx = 0; $idx -lt $sortedHeadings.Count; $idx++) {
    $heading = $sortedHeadings[$idx]
    $start = $headingPositions[$heading] + 1
    $end = $lines.Count
    for ($j = $start; $j -lt $lines.Count; $j++) {
        if ($lines[$j] -match $nextHeadingPattern) {
            $end = $j
            break
        }
    }

    $bodyLines = @()
    for ($l = $start; $l -lt $end; $l++) {
        $bodyLines += $lines[$l]
    }
    $bodyText = ($bodyLines -join "`n").Trim()

    if ([string]::IsNullOrWhiteSpace($bodyText)) {
        Write-Host ('brief-check: FAIL required section is empty: {0}' -f $heading)
        exit 1
    }

    foreach ($f in $forbidden) {
        if ($bodyText.Contains($f)) {
            Write-Host ('brief-check: FAIL replace-me sentinel remains in {0}' -f $heading)
            exit 1
        }
    }
}

Write-Host ('brief-check: PASS {0}' -f $BriefPath)
exit 0
