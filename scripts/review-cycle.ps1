[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('design', 'implementation', 'test', 'review', 'release')]
    [string] $Stage,

    [Parameter(Mandatory = $true)]
    [string] $Purpose,

    [string[]] $TargetFiles,
    [string] $TargetFilesPath,
    [string] $Context,
    [string] $RequiredInspectionPaths,
    [string] $ReviewQuestions,
    [string] $Constraints,
    [string] $Reviewer = 'codex',
    [string] $RunId,
    [string] $ProjectRoot,
    [string] $ToolRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'lib/encoding.ps1')
. (Join-Path $PSScriptRoot 'lib/path.ps1')
. (Join-Path $PSScriptRoot 'lib/hash.ps1')
. (Join-Path $PSScriptRoot 'lib/git.ps1')
. (Join-Path $PSScriptRoot 'lib/json.ps1')
. (Join-Path $PSScriptRoot 'lib/resolve-script.ps1')

function Invoke-CodexExec {
    param(
        [string] $InputPath,
        [string] $Model,
        [string] $ResultMdPath
    )

    $content = Read-Utf8 -Path $InputPath

    $codexCmd = $env:AI_HARNESS_CODEX_COMMAND
    if ([string]::IsNullOrEmpty($codexCmd)) {
        $codexCmd = 'codex'
    }

    $codexArgs = @(
        '--ask-for-approval', 'never',
        'exec',
        '--sandbox', 'read-only',
        '--model', $Model,
        '-c', 'web_search=disabled',
        '--output-last-message', $ResultMdPath,
        '-'
    )

    # Stub-args-file protocol is Pester-only opt-in; selecting it by .ps1 suffix misclassifies the npm Windows codex.ps1 shim, which is a real CLI and must take the stdin-pipe branch.
    if ($env:AI_HARNESS_CODEX_ARGS_FILE_STUB -eq '1') {
        $argsTempPath = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), ('codex-stub-argv-' + [guid]::NewGuid().ToString('N') + '.json'))
        $argsObj = [ordered]@{ argv = $codexArgs }
        $argsJson = ($argsObj | ConvertTo-Json -Depth 8) -replace "`r`n", "`n"
        $stubEnc = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($argsTempPath, $argsJson, $stubEnc)

        try {
            $stubArgs = @(
                '-NoProfile', '-ExecutionPolicy', 'Bypass',
                '-File', $codexCmd,
                '-CodexArgsFile', $argsTempPath
            )
            & powershell.exe @stubArgs
            $code = $LASTEXITCODE
        }
        finally {
            if (Test-Path -LiteralPath $argsTempPath) {
                Remove-Item -LiteralPath $argsTempPath -Force -ErrorAction SilentlyContinue
            }
        }
    }
    else {
        $null = $content | & $codexCmd @codexArgs
        $code = $LASTEXITCODE
    }

    return [pscustomobject]@{ ExitCode = $code }
}

function Get-VerdictFromResultMd {
    param([string] $Path)

    $text = Read-Utf8 -Path $Path
    $lines = $text -split "`r?`n"

    $headingPositions = @()
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i].TrimEnd() -eq '## Verdict') {
            $headingPositions += $i
        }
    }
    if ($headingPositions.Count -ne 1) {
        return ''
    }

    $start = $headingPositions[0] + 1
    for ($i = $start; $i -lt $lines.Count; $i++) {
        $candidate = $lines[$i].Trim()
        if ([string]::IsNullOrEmpty($candidate)) { continue }

        $lower = $candidate.ToLowerInvariant()
        if ($lower -eq 'yes' -or $lower -eq 'no' -or $lower -eq 'yes with risk') {
            return $lower
        }
        return ''
    }
    return ''
}

function Get-TrackedChangedFiles {
    param([string] $WorkingDirectory)

    $statusRes = Invoke-GitCapture -Arguments @('status', '--porcelain=v1') -WorkingDirectory $WorkingDirectory
    if ($statusRes.ExitCode -ne 0) {
        return [pscustomobject]@{
            Tracked   = @()
            Untracked = @()
            Failed    = $true
        }
    }

    $tracked = New-Object System.Collections.Generic.List[string]
    $untracked = New-Object System.Collections.Generic.List[string]

    $rawLines = $statusRes.StdOut -split "`r?`n"
    foreach ($ln in $rawLines) {
        if ([string]::IsNullOrEmpty($ln)) { continue }
        if ($ln.Length -lt 4) { continue }

        $code = $ln.Substring(0, 2)
        $rest = $ln.Substring(3)
        if ($rest.Contains(' -> ')) {
            $rest = $rest.Substring($rest.IndexOf(' -> ') + 4)
        }
        $rest = $rest.Trim()
        if ($rest.StartsWith('"') -and $rest.EndsWith('"') -and $rest.Length -ge 2) {
            $rest = $rest.Substring(1, $rest.Length - 2)
        }

        if ($code -eq '??') {
            if ($rest -eq 'log' -or $rest.StartsWith('log/') -or $rest.StartsWith('log\')) {
                continue
            }
            $untracked.Add($rest) | Out-Null
            continue
        }

        $codeChars = $code.ToCharArray()
        $isReviewable = $false
        foreach ($c in $codeChars) {
            if ($c -eq 'M' -or $c -eq 'A' -or $c -eq 'R' -or $c -eq 'C') {
                $isReviewable = $true
                break
            }
        }
        if ($isReviewable) {
            if (-not $tracked.Contains($rest)) {
                $tracked.Add($rest) | Out-Null
            }
        }
    }

    return [pscustomobject]@{
        Tracked   = $tracked.ToArray()
        Untracked = $untracked.ToArray()
        Failed    = $false
    }
}

if ($Reviewer -ne 'codex') {
    Write-Host ('review-cycle: FAIL only -Reviewer codex is supported in MVP; got {0}' -f $Reviewer)
    exit 1
}

$project = Get-ProjectRoot -ProjectRoot $ProjectRoot
$tool    = Get-ToolRoot -ToolRoot $ToolRoot -ProjectRoot $project
$logRoot = Get-ProjectLogRoot -ProjectRoot $project

if (-not [string]::IsNullOrEmpty($TargetFilesPath)) {
    if (-not (Test-Path -LiteralPath $TargetFilesPath -PathType Leaf)) {
        Write-Host ('review-cycle: FAIL TargetFilesPath not found: {0}' -f $TargetFilesPath)
        exit 1
    }
    try {
        [void] (Assert-InProjectLogRoot -Path $TargetFilesPath -ProjectLogRoot $logRoot)
    }
    catch {
        Write-Host ('review-cycle: FAIL TargetFilesPath outside ProjectLogRoot: {0}' -f $_.Exception.Message)
        exit 1
    }
    $listText = Read-Utf8 -Path $TargetFilesPath
    foreach ($ln in ($listText -split "`r?`n")) {
        $trim = $ln.Trim()
        if (-not [string]::IsNullOrEmpty($trim)) {
            if ($null -eq $TargetFiles) { $TargetFiles = @() }
            $TargetFiles = $TargetFiles + $trim
        }
    }
}

$resolvedTargets = @()
if ($null -ne $TargetFiles -and $TargetFiles.Count -gt 0) {
    foreach ($tf in $TargetFiles) {
        if (-not [string]::IsNullOrEmpty($tf)) {
            $resolvedTargets += $tf
        }
    }
}

# Reject the bad multi-file CLI shape `-TargetFiles "a.txt,b.txt"` early, before run-id allocation
# or any review-prepare invocation, while leaving real comma-containing single paths intact (AC-CY5).
if ($resolvedTargets.Count -eq 1 -and $resolvedTargets[0].Contains(',')) {
    $candidate = $resolvedTargets[0]
    if ([System.IO.Path]::IsPathRooted($candidate)) {
        $literalCandidate = $candidate
    }
    else {
        $literalCandidate = Join-Path -Path $project -ChildPath $candidate
    }
    if (-not (Test-Path -LiteralPath $literalCandidate -PathType Leaf)) {
        Write-Host 'review-cycle: FAIL TargetFiles appears to be a comma-separated single string. Use -TargetFilesPath with one target path per line for multi-file reviews.'
        exit 1
    }
}

if ($resolvedTargets.Count -eq 0) {
    $detection = Get-TrackedChangedFiles -WorkingDirectory $project
    if ($detection.Failed) {
        Write-Host 'review-cycle: FAIL git status failed; pass -TargetFiles explicitly'
        exit 1
    }
    if ($detection.Untracked.Count -gt 0) {
        Write-Host ('review-cycle: FAIL untracked files outside log/; pass -TargetFiles explicitly. Untracked: {0}' -f ($detection.Untracked -join ', '))
        exit 1
    }
    if ($detection.Tracked.Count -eq 0) {
        Write-Host 'review-cycle: FAIL no tracked changes detected; pass -TargetFiles explicitly'
        exit 1
    }
    $resolvedTargets = $detection.Tracked
}

if ([string]::IsNullOrEmpty($RunId)) {
    $stamp = (Get-Date).ToUniversalTime().ToString('yyyyMMdd-HHmmss')
    $suffix = ([guid]::NewGuid().ToString('N')).Substring(0, 6).ToLowerInvariant()
    $RunId = "$stamp-$suffix"
}
[void] (Assert-ValidRunId -Value $RunId)

$runDir = Join-Path -Path $logRoot -ChildPath ('review/' + $RunId)
if (Test-Path -LiteralPath $runDir -PathType Container) {
    Write-Host ('review-cycle: FAIL run directory already exists: {0}. Use a fresh run-id.' -f $runDir)
    exit 1
}

$toolRootSource = Get-ToolRootSource -ToolRoot $ToolRoot
$prepareScript = Resolve-CycleScript -Tool $tool -RelativePath 'scripts/review-prepare.ps1' -LocalDir $PSScriptRoot -ToolRootSource $toolRootSource
$verifyInputScript = Resolve-CycleScript -Tool $tool -RelativePath 'scripts/review-input-verify.ps1' -LocalDir $PSScriptRoot -ToolRootSource $toolRootSource
$verifyScript = Resolve-CycleScript -Tool $tool -RelativePath 'scripts/review-verify.ps1' -LocalDir $PSScriptRoot -ToolRootSource $toolRootSource

$targetListPath = Join-Path -Path $logRoot -ChildPath ('review-cycle-targets-' + $RunId + '.list')
$targetListContent = ($resolvedTargets -join "`n") + "`n"
Write-Utf8NoBom -Path $targetListPath -Content $targetListContent

$prepareArgs = @(
    '-NoProfile', '-ExecutionPolicy', 'Bypass',
    '-File', $prepareScript,
    '-Stage', $Stage,
    '-Purpose', $Purpose,
    '-Reviewer', $Reviewer,
    '-RunId', $RunId,
    '-ProjectRoot', $project,
    '-ToolRoot', $tool,
    '-TargetFilesPath', $targetListPath
)

& powershell.exe @prepareArgs
$prepareExit = $LASTEXITCODE
if (Test-Path -LiteralPath $targetListPath) {
    Remove-Item -LiteralPath $targetListPath -Force -ErrorAction SilentlyContinue
}
if ($prepareExit -ne 0) {
    Write-Host ('review-cycle: FAIL review-prepare exit {0}' -f $prepareExit)
    exit 1
}

$inputPath = Join-Path -Path $runDir -ChildPath 'input.md'
if (-not (Test-Path -LiteralPath $inputPath -PathType Leaf)) {
    Write-Host ('review-cycle: FAIL input.md not produced: {0}' -f $inputPath)
    exit 1
}

$inputText = Read-Utf8 -Path $inputPath
if (-not [string]::IsNullOrEmpty($Context)) {
    $inputText = $inputText.Replace('(Replace this placeholder with review context.)', $Context)
}
if (-not [string]::IsNullOrEmpty($RequiredInspectionPaths)) {
    $inputText = $inputText.Replace('(Replace this placeholder with paths the reviewer must inspect.)', $RequiredInspectionPaths)
}
if (-not [string]::IsNullOrEmpty($ReviewQuestions)) {
    $inputText = $inputText.Replace('(Replace this placeholder with review questions.)', $ReviewQuestions)
}
if (-not [string]::IsNullOrEmpty($Constraints)) {
    $inputText = $inputText.Replace('(Replace this placeholder with explicit constraints.)', $Constraints)
}
Write-Utf8NoBom -Path $inputPath -Content $inputText

$verifyInputArgs = @(
    '-NoProfile', '-ExecutionPolicy', 'Bypass',
    '-File', $verifyInputScript,
    '-InputPath', $inputPath
)
& powershell.exe @verifyInputArgs
$verifyInputExit = $LASTEXITCODE
if ($verifyInputExit -ne 0) {
    Write-Host ('review-cycle: FAIL input.md not ready (review-input-verify exit {0}). Start a new review run with corrected CLI arguments.' -f $verifyInputExit)
    exit 1
}

$metaPath = Join-Path -Path $runDir -ChildPath 'meta.json'
$meta = Read-JsonFile -Path $metaPath

$model = ''
if ($null -ne $meta.PSObject.Properties['reviewerConfig']) {
    $rc = $meta.reviewerConfig
    if ($null -ne $rc -and $null -ne $rc.PSObject.Properties['model']) {
        $model = [string]$rc.model
    }
}
if ([string]::IsNullOrEmpty($model)) {
    Write-Host 'review-cycle: FAIL reviewer model missing in meta.json'
    exit 1
}

$resultMdPath = Join-Path -Path $runDir -ChildPath 'result.md'

$codexResult = Invoke-CodexExec -InputPath $inputPath -Model $model -ResultMdPath $resultMdPath
if ($codexResult.ExitCode -ne 0) {
    Write-Host ('review-cycle: FAIL Codex CLI exit {0}' -f $codexResult.ExitCode)
    exit 1
}

if (-not (Test-Path -LiteralPath $resultMdPath -PathType Leaf)) {
    Write-Host ('review-cycle: FAIL result.md was not produced: {0}' -f $resultMdPath)
    exit 1
}

$verdict = Get-VerdictFromResultMd -Path $resultMdPath
if ([string]::IsNullOrEmpty($verdict)) {
    Write-Host ('review-cycle: FAIL. Could not parse verdict from {0}. result.json was not created. The failed run is preserved for inspection; start a new review run after fixing the reviewer output, prompt/tooling, or source issue.' -f $resultMdPath)
    exit 1
}

$inputSha = Get-FileSha256 -Path $inputPath
$resultMdSha = Get-FileSha256 -Path $resultMdPath
$invariant = [System.Globalization.CultureInfo]::InvariantCulture
$createdAt = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffffffZ', $invariant)

$metaSourceHead = $null
if ($null -ne $meta.PSObject.Properties['sourceHead']) {
    $metaSourceHead = $meta.sourceHead
}
$metaTargetSha = ''
if ($null -ne $meta.PSObject.Properties['targetSha256']) {
    $metaTargetSha = [string]$meta.targetSha256
}
$metaTargetPath = ''
if ($null -ne $meta.PSObject.Properties['targetPath']) {
    $metaTargetPath = [string]$meta.targetPath
}
$metaStage = ''
if ($null -ne $meta.PSObject.Properties['stage']) {
    $metaStage = [string]$meta.stage
}
$metaPurpose = ''
if ($null -ne $meta.PSObject.Properties['purpose']) {
    $metaPurpose = [string]$meta.purpose
}
$metaReviewer = ''
if ($null -ne $meta.PSObject.Properties['reviewer']) {
    $metaReviewer = [string]$meta.reviewer
}

$resultObj = [ordered]@{
    schemaVersion        = 1
    runId                = $RunId
    createdAtUtc         = $createdAt
    reviewer             = $metaReviewer
    verdict              = $verdict
    targetPath           = $metaTargetPath
    targetSha256         = $metaTargetSha
    sourceHead           = $metaSourceHead
    stage                = $metaStage
    purpose              = $metaPurpose
    inputSha256          = $inputSha
    resultMarkdownSha256 = $resultMdSha
    notes                = @()
}

$resultJsonPath = Join-Path -Path $runDir -ChildPath 'result.json'
Write-JsonFile -Path $resultJsonPath -Value $resultObj

$verifyDefaultArgs = @(
    '-NoProfile', '-ExecutionPolicy', 'Bypass',
    '-File', $verifyScript,
    '-RunId', $RunId,
    '-ProjectRoot', $project
)
& powershell.exe @verifyDefaultArgs
$verifyDefaultExit = $LASTEXITCODE
if ($verifyDefaultExit -ne 0) {
    Write-Host ('review-cycle: FAIL review-verify default exit {0}' -f $verifyDefaultExit)
    exit 1
}

$verifyRequireArgs = @(
    '-NoProfile', '-ExecutionPolicy', 'Bypass',
    '-File', $verifyScript,
    '-RunId', $RunId,
    '-ProjectRoot', $project,
    '-RequireResult'
)
& powershell.exe @verifyRequireArgs
$verifyRequireExit = $LASTEXITCODE
if ($verifyRequireExit -ne 0) {
    Write-Host ('review-cycle: FAIL review-verify -RequireResult exit {0}' -f $verifyRequireExit)
    exit 1
}

Write-Host 'review-cycle: PASS'
Write-Host ('run-id: {0}' -f $RunId)
Write-Host ('verdict: {0}' -f $verdict)
$relRun = (Resolve-ProjectRelativePath -Path $resultJsonPath -ProjectRoot $project) -replace '\\', '/'
Write-Host ('result: {0}' -f $relRun)
Write-Host 'review-verify: PASS'
exit 0
