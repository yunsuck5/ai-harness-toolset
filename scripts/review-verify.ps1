[CmdletBinding()]
param(
    [string] $ReviewTaskId,

    [string] $Pass,

    [string] $ProjectRoot,
    [string] $ToolRoot,

    [switch] $RequireResult
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrEmpty($ReviewTaskId)) {
    Write-Host 'review-verify: FAIL -ReviewTaskId is required.'
    exit 1
}
if ([string]::IsNullOrEmpty($Pass)) {
    Write-Host 'review-verify: FAIL -Pass is required (e.g., pass-01).'
    exit 1
}

. (Join-Path $PSScriptRoot 'lib/encoding.ps1')
. (Join-Path $PSScriptRoot 'lib/path.ps1')
. (Join-Path $PSScriptRoot 'lib/resolve-script.ps1')

function Test-VerdictShape {
    param([string] $Path)

    $text = Read-Utf8 -Path $Path
    $lines = $text -split "`r?`n"

    $headingPositions = @()
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i].TrimEnd() -ceq '## Verdict') {
            $headingPositions += $i
        }
    }
    if ($headingPositions.Count -eq 0) {
        return [pscustomobject]@{ Ok = $false; Reason = 'no "## Verdict" heading found'; Verdict = '' }
    }
    if ($headingPositions.Count -gt 1) {
        return [pscustomobject]@{ Ok = $false; Reason = ('multiple "## Verdict" headings found (count={0})' -f $headingPositions.Count); Verdict = '' }
    }

    $start = $headingPositions[0] + 1
    for ($i = $start; $i -lt $lines.Count; $i++) {
        $candidate = $lines[$i].Trim()
        if ([string]::IsNullOrEmpty($candidate)) { continue }
        $lower = $candidate.ToLowerInvariant()
        if ($lower -ceq 'yes' -or $lower -ceq 'no' -or $lower -ceq 'yes with risk') {
            if ($candidate -ceq $lower) {
                return [pscustomobject]@{ Ok = $true; Reason = ''; Verdict = $lower }
            }
            return [pscustomobject]@{ Ok = $false; Reason = ('verdict line must be lowercase exact: "{0}"' -f $candidate); Verdict = '' }
        }
        return [pscustomobject]@{ Ok = $false; Reason = ('first non-empty line after "## Verdict" is not one of yes / no / yes with risk: "{0}"' -f $candidate); Verdict = '' }
    }
    return [pscustomobject]@{ Ok = $false; Reason = 'no non-empty content after "## Verdict" heading'; Verdict = '' }
}

function Test-DisclosureSections {
    param([string] $Path)

    $text = Read-Utf8 -Path $Path
    $lines = $text -split "`r?`n"

    $required = @(
        '## Blocking findings',
        '## Non-blocking concerns',
        '## Review limitations',
        '## Assumptions relied on'
    )

    $counts = @{}
    foreach ($h in $required) { $counts[$h] = 0 }
    foreach ($line in $lines) {
        $trimmed = $line.TrimEnd()
        foreach ($h in $required) {
            if ($trimmed -ceq $h) {
                $counts[$h] = $counts[$h] + 1
            }
        }
    }

    foreach ($h in $required) {
        if ($counts[$h] -eq 0) {
            return [pscustomobject]@{ Ok = $false; Reason = ('missing required disclosure heading: {0}' -f $h) }
        }
        if ($counts[$h] -gt 1) {
            return [pscustomobject]@{ Ok = $false; Reason = ('duplicate required disclosure heading: {0} (count={1})' -f $h, $counts[$h]) }
        }
    }

    return [pscustomobject]@{ Ok = $true; Reason = '' }
}

try {
    [void] (Assert-ValidReviewTaskId -Value $ReviewTaskId)
}
catch {
    Write-Host ('review-verify: FAIL invalid ReviewTaskId: {0}' -f $ReviewTaskId)
    exit 1
}

try {
    [void] (Assert-ValidPass -Value $Pass)
}
catch {
    Write-Host ('review-verify: FAIL invalid Pass: {0}' -f $Pass)
    exit 1
}

$project = Get-ProjectRoot -ProjectRoot $ProjectRoot
$logRoot = Get-ProjectLogRoot -ProjectRoot $project

# Re-resolve ToolRoot at runtime to fail fast on environments missing the canonical payload.
$tool = ''
try {
    $tool = Get-ToolRoot -ToolRoot $ToolRoot -ProjectRoot $project
}
catch {
    Write-Host ('review-verify: FAIL toolRoot could not be resolved at runtime: {0}' -f $_.Exception.Message)
    exit 1
}

$passDir = Get-ReviewPassDir -ProjectLogRoot $logRoot -ReviewTaskId $ReviewTaskId -Pass $Pass
try {
    [void] (Assert-InReviewRoot -Path $passDir -ProjectLogRoot $logRoot)
}
catch {
    Write-Host ('review-verify: FAIL pass directory outside review root: {0}' -f $passDir)
    exit 1
}

if (-not (Test-Path -LiteralPath $passDir -PathType Container)) {
    Write-Host ('review-verify: FAIL pass directory not found: {0}' -f $passDir)
    exit 1
}

$inputPath = Join-Path -Path $passDir -ChildPath 'input.md'
if (-not (Test-Path -LiteralPath $inputPath -PathType Leaf)) {
    Write-Host ('review-verify: FAIL input.md missing: {0}' -f $inputPath)
    exit 1
}

$toolRootSource = Get-ToolRootSource -ToolRoot $ToolRoot
$verifyInputScript = Resolve-RunScript -Tool $tool -RelativePath 'scripts/review-input-verify.ps1' -LocalDir $PSScriptRoot -ToolRootSource $toolRootSource

$verifyInputArgs = @(
    '-NoProfile', '-ExecutionPolicy', 'Bypass',
    '-File', $verifyInputScript,
    '-InputPath', $inputPath
)
& powershell.exe @verifyInputArgs
$verifyInputExit = $LASTEXITCODE
if ($verifyInputExit -ne 0) {
    Write-Host ('review-verify: FAIL input.md shape invalid (review-input-verify exit {0}).' -f $verifyInputExit)
    exit 1
}

$resultPath = Join-Path -Path $passDir -ChildPath 'result.md'

if ($RequireResult) {
    if (-not (Test-Path -LiteralPath $resultPath -PathType Leaf)) {
        Write-Host ('review-verify: FAIL result.md missing: {0}' -f $resultPath)
        exit 1
    }
    $shape = Test-VerdictShape -Path $resultPath
    if (-not $shape.Ok) {
        Write-Host ('review-verify: FAIL result.md verdict shape invalid: {0}' -f $shape.Reason)
        exit 1
    }
    Write-Host ('review-verify: result.md verdict shape valid (verdict={0})' -f $shape.Verdict)
    $disc = Test-DisclosureSections -Path $resultPath
    if (-not $disc.Ok) {
        Write-Host ('review-verify: FAIL result.md disclosure sections invalid: {0}' -f $disc.Reason)
        exit 1
    }
    Write-Host 'review-verify: result.md disclosure sections present (## Blocking findings / ## Non-blocking concerns / ## Review limitations / ## Assumptions relied on)'
}
else {
    if (Test-Path -LiteralPath $resultPath -PathType Leaf) {
        Write-Host 'review-verify: result.md present (informational)'
    }
    else {
        Write-Host 'review-verify: result.md not present (informational)'
    }
}

$relPass = (Resolve-ProjectRelativePath -Path $passDir -ProjectRoot $project) -replace '\\', '/'
Write-Host ('review-verify: PASS')
Write-Host ('review-task-id: {0}' -f $ReviewTaskId)
Write-Host ('pass: {0}' -f $Pass)
Write-Host ('pass-dir: {0}' -f $relPass)
exit 0
