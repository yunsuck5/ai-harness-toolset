[CmdletBinding()]
param(
    [string] $ProjectRoot,
    [string] $BriefPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'lib/encoding.ps1')
. (Join-Path $PSScriptRoot 'lib/path.ps1')
. (Join-Path $PSScriptRoot 'lib/native-process.ps1')

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
    Write-Host ('brief-status: FAIL BriefPath outside ProjectRoot: {0}' -f $BriefPath)
    exit 1
}

if (-not (Test-Path -LiteralPath $BriefPath -PathType Leaf)) {
    Write-Host ('brief-status: FAIL BRIEF.md not found: {0}' -f $BriefPath)
    exit 1
}

$briefCheckScript = Join-Path $PSScriptRoot 'brief-check.ps1'
if (-not (Test-Path -LiteralPath $briefCheckScript -PathType Leaf)) {
    Write-Host ('brief-status: FAIL brief-check.ps1 not found: {0}' -f $briefCheckScript)
    exit 1
}

$checkProc = Invoke-NativeProcess -Executable 'powershell.exe' -Arguments @(
    '-NoProfile', '-ExecutionPolicy', 'Bypass',
    '-File', $briefCheckScript,
    '-ProjectRoot', $project,
    '-BriefPath', $BriefPath
)
$checkExitCode = $checkProc.ExitCode
$checkLines = @(($checkProc.Stdout + $checkProc.Stderr) -split "`r?`n")

foreach ($line in $checkLines) {
    if (-not [string]::IsNullOrWhiteSpace($line)) {
        Write-Host ('brief-status: brief-check: {0}' -f $line.TrimEnd())
    }
}

if ($checkExitCode -ne 0) {
    Write-Host ('brief-status: FAIL shape validation (delegated to brief-check.ps1; exit {0})' -f $checkExitCode)
    exit $checkExitCode
}

$content = Read-Utf8 -Path $BriefPath
$lines = $content -split "`r?`n"

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

$koreanLabels = @{
    '## Current state'          = '현재 상태'
    '## Last completed action'  = '마지막 완료 action'
    '## Current scope'          = '현재 scope'
    '## Next single action'     = '다음 단일 action'
    '## Do not do'              = 'Do not do'
    '## Files to inspect first' = '먼저 읽을 파일'
    '## Open risks'             = 'Open risks'
    '## Pending user decision'  = 'Pending user decision'
}

$headingPositions = @{}
for ($i = 0; $i -lt $lines.Count; $i++) {
    $trimmed = $lines[$i].TrimEnd()
    foreach ($h in $requiredHeadings) {
        if ($trimmed -eq $h) {
            if (-not $headingPositions.ContainsKey($h)) {
                $headingPositions[$h] = $i
            }
        }
    }
}

foreach ($h in $requiredHeadings) {
    if (-not $headingPositions.ContainsKey($h)) {
        Write-Host ('brief-status: FAIL internal: required heading missing after brief-check PASS: {0}' -f $h)
        exit 1
    }
}

$nextHeadingPattern = '^##\s'
$sortedHeadings = $requiredHeadings | Sort-Object { $headingPositions[$_] }

Write-Host ('brief-status: PASS {0}' -f $BriefPath)
Write-Host 'brief-status: summary (Korean labels)'

foreach ($heading in $sortedHeadings) {
    $start = $headingPositions[$heading] + 1
    $end = $lines.Count
    for ($j = $start; $j -lt $lines.Count; $j++) {
        if ($lines[$j] -match $nextHeadingPattern) {
            $end = $j
            break
        }
    }

    $firstLine = $null
    for ($l = $start; $l -lt $end; $l++) {
        $candidate = $lines[$l].Trim()
        if (-not [string]::IsNullOrEmpty($candidate)) {
            $firstLine = $candidate
            break
        }
    }

    if ($null -eq $firstLine) {
        $firstLine = '(empty)'
    }

    Write-Host ('brief-status: {0}: {1}' -f $koreanLabels[$heading], $firstLine)
}

exit 0
