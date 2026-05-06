[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $InputPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'lib/encoding.ps1')

if ([string]::IsNullOrEmpty($InputPath)) {
    Write-Host 'review-input-verify: FAIL InputPath is empty'
    exit 1
}
if (-not (Test-Path -LiteralPath $InputPath -PathType Leaf)) {
    Write-Host ('review-input-verify: FAIL input not found: {0}' -f $InputPath)
    exit 1
}

$content = Read-Utf8 -Path $InputPath

$requiredHeadings = @(
    '## Context',
    '## Required inspection paths',
    '## Review questions',
    '## Constraints',
    '## Final verdict'
)

$lines = $content -split "`r?`n"

$headingPositions = @{}
for ($i = 0; $i -lt $lines.Count; $i++) {
    $trimmed = $lines[$i].TrimEnd()
    foreach ($h in $requiredHeadings) {
        if ($trimmed -eq $h) {
            if ($headingPositions.ContainsKey($h)) {
                Write-Host ('review-input-verify: FAIL duplicate heading: {0}' -f $h)
                exit 1
            }
            $headingPositions[$h] = $i
        }
    }
}

foreach ($h in $requiredHeadings) {
    if (-not $headingPositions.ContainsKey($h)) {
        Write-Host ('review-input-verify: FAIL missing heading: {0}' -f $h)
        exit 1
    }
}

$tokenMatch = [regex]::Match($content, '\{\{[A-Za-z_][A-Za-z0-9_]*\}\}')
if ($tokenMatch.Success) {
    Write-Host ('review-input-verify: FAIL unreplaced template token: {0}' -f $tokenMatch.Value)
    exit 1
}

$forbidden = @(
    'Replace this placeholder',
    '(Provide context here.)',
    '(Provide review questions here.)'
)

$sortedHeadings = $requiredHeadings | Sort-Object { $headingPositions[$_] }
$verdictHeading = '## Final verdict'

for ($idx = 0; $idx -lt $sortedHeadings.Count; $idx++) {
    $heading = $sortedHeadings[$idx]
    $start = $headingPositions[$heading] + 1
    if ($idx -lt $sortedHeadings.Count - 1) {
        $end = $headingPositions[$sortedHeadings[$idx + 1]]
    }
    else {
        $end = $lines.Count
    }

    $bodyLines = @()
    for ($l = $start; $l -lt $end; $l++) {
        $bodyLines += $lines[$l]
    }
    $bodyText = ($bodyLines -join "`n").Trim()

    if ($heading -eq $verdictHeading) {
        if ($bodyText -notmatch [regex]::Escape('yes / no / yes with risk')) {
            Write-Host 'review-input-verify: FAIL Final verdict section missing "yes / no / yes with risk"'
            exit 1
        }
        foreach ($f in $forbidden) {
            if ($bodyText.Contains($f)) {
                Write-Host ('review-input-verify: FAIL placeholder remains in {0}: {1}' -f $heading, $f)
                exit 1
            }
        }
        continue
    }

    if ([string]::IsNullOrWhiteSpace($bodyText)) {
        Write-Host ('review-input-verify: FAIL section is empty: {0}' -f $heading)
        exit 1
    }

    foreach ($f in $forbidden) {
        if ($bodyText.Contains($f)) {
            Write-Host ('review-input-verify: FAIL placeholder remains in {0}: {1}' -f $heading, $f)
            exit 1
        }
    }
}

Write-Host 'review-input-verify: PASS'
exit 0
