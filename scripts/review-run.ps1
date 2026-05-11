[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $RunId,

    [string] $Reviewer = 'codex',
    [string] $ProjectRoot,
    [string] $ToolRoot,
    [switch] $Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'lib/encoding.ps1')
. (Join-Path $PSScriptRoot 'lib/path.ps1')
. (Join-Path $PSScriptRoot 'lib/hash.ps1')
. (Join-Path $PSScriptRoot 'lib/json.ps1')

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

    # Stub-args-file protocol is Pester-only opt-in; selecting it by .ps1 suffix would misclassify the npm Windows codex.ps1 shim, which is a real CLI and must take the stdin-pipe branch.
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

function Resolve-RunScript {
    param(
        [string] $Tool,
        [string] $RelativePath,
        [string] $LocalDir
    )
    $candidate = Join-Path -Path $Tool -ChildPath $RelativePath
    if (Test-Path -LiteralPath $candidate -PathType Leaf) {
        return $candidate
    }
    $local = Join-Path -Path $LocalDir -ChildPath (Split-Path -Leaf $RelativePath)
    if (Test-Path -LiteralPath $local -PathType Leaf) {
        return $local
    }
    throw ('review-run: required script not found: ' + $RelativePath)
}

if ($Reviewer -ne 'codex') {
    Write-Host ('review-run: FAIL only -Reviewer codex is supported in MVP; got {0}' -f $Reviewer)
    exit 1
}

try {
    [void] (Assert-ValidRunId -Value $RunId)
}
catch {
    Write-Host ('review-run: FAIL invalid RunId: {0}' -f $RunId)
    exit 1
}

$project = Get-ProjectRoot -ProjectRoot $ProjectRoot
$tool    = Get-ToolRoot -ToolRoot $ToolRoot -ProjectRoot $project
$logRoot = Get-ProjectLogRoot -ProjectRoot $project

$runDir = Join-Path -Path $logRoot -ChildPath ('review/' + $RunId)
try {
    [void] (Assert-InReviewRunRoot -Path $runDir -ProjectLogRoot $logRoot)
}
catch {
    Write-Host ('review-run: FAIL run directory outside review root: {0}' -f $runDir)
    exit 1
}

if (-not (Test-Path -LiteralPath $runDir -PathType Container)) {
    Write-Host ('review-run: FAIL run not prepared; run review-prepare first: {0}' -f $runDir)
    exit 1
}

$metaPath = Join-Path -Path $runDir -ChildPath 'meta.json'
if (-not (Test-Path -LiteralPath $metaPath -PathType Leaf)) {
    Write-Host ('review-run: FAIL meta.json not found: {0}' -f $metaPath)
    exit 1
}

$inputPath = Join-Path -Path $runDir -ChildPath 'input.md'
if (-not (Test-Path -LiteralPath $inputPath -PathType Leaf)) {
    Write-Host ('review-run: FAIL input.md not found: {0}' -f $inputPath)
    exit 1
}

$meta = $null
try {
    $meta = Read-JsonFile -Path $metaPath
}
catch {
    Write-Host ('review-run: FAIL meta.json invalid JSON: {0}' -f $metaPath)
    exit 1
}

$model = ''
if ($null -ne $meta.PSObject.Properties['reviewerConfig']) {
    $rc = $meta.reviewerConfig
    if ($null -ne $rc -and $null -ne $rc.PSObject.Properties['model']) {
        $model = [string]$rc.model
    }
}
if ([string]::IsNullOrEmpty($model)) {
    Write-Host 'review-run: FAIL reviewer model missing in meta.json'
    exit 1
}

$resultMdPath = Join-Path -Path $runDir -ChildPath 'result.md'
$resultJsonPath = Join-Path -Path $runDir -ChildPath 'result.json'
$existingResultMd = Test-Path -LiteralPath $resultMdPath -PathType Leaf
$existingResultJson = Test-Path -LiteralPath $resultJsonPath -PathType Leaf
if (($existingResultMd -or $existingResultJson) -and -not $Force) {
    Write-Host ('review-run: FAIL existing result.md/result.json present; pass -Force to overwrite or start a new review run with a fresh run-id.')
    exit 1
}
if ($Force) {
    if ($existingResultMd) {
        Remove-Item -LiteralPath $resultMdPath -Force -ErrorAction Stop
    }
    if ($existingResultJson) {
        Remove-Item -LiteralPath $resultJsonPath -Force -ErrorAction Stop
    }
}

$verifyInputScript = Resolve-RunScript -Tool $tool -RelativePath 'scripts/review-input-verify.ps1' -LocalDir $PSScriptRoot
$verifyScript      = Resolve-RunScript -Tool $tool -RelativePath 'scripts/review-verify.ps1'       -LocalDir $PSScriptRoot

$verifyInputArgs = @(
    '-NoProfile', '-ExecutionPolicy', 'Bypass',
    '-File', $verifyInputScript,
    '-InputPath', $inputPath
)
& powershell.exe @verifyInputArgs
$verifyInputExit = $LASTEXITCODE
if ($verifyInputExit -ne 0) {
    Write-Host ('review-run: FAIL input.md not ready (review-input-verify exit {0}). Edit input.md to fill the required sections, or start a new review run with corrected CLI arguments.' -f $verifyInputExit)
    exit 1
}

$codexResult = Invoke-CodexExec -InputPath $inputPath -Model $model -ResultMdPath $resultMdPath
if ($codexResult.ExitCode -ne 0) {
    Write-Host ('review-run: FAIL Codex CLI exit {0}' -f $codexResult.ExitCode)
    exit 1
}

if (-not (Test-Path -LiteralPath $resultMdPath -PathType Leaf)) {
    Write-Host ('review-run: FAIL result.md was not produced: {0}' -f $resultMdPath)
    exit 1
}

$verdict = Get-VerdictFromResultMd -Path $resultMdPath
if ([string]::IsNullOrEmpty($verdict)) {
    Write-Host ('review-run: FAIL. Could not parse verdict from {0}. result.json was not created. The failed run is preserved for inspection; start a new review run after fixing the reviewer output, prompt/tooling, or source issue.' -f $resultMdPath)
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
    Write-Host ('review-run: FAIL review-verify default exit {0}' -f $verifyDefaultExit)
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
    Write-Host ('review-run: FAIL review-verify -RequireResult exit {0}' -f $verifyRequireExit)
    exit 1
}

Write-Host 'review-run: PASS'
Write-Host ('run-id: {0}' -f $RunId)
Write-Host ('verdict: {0}' -f $verdict)
$relRun = (Resolve-ProjectRelativePath -Path $resultJsonPath -ProjectRoot $project) -replace '\\', '/'
Write-Host ('result: {0}' -f $relRun)
Write-Host 'review-verify: PASS'
exit 0
