[CmdletBinding()]
param(
    [string] $ReviewTaskId,

    [string] $Pass,

    [string] $Reviewer = 'codex',
    [string] $Model,
    [string] $ProjectRoot,
    [string] $ToolRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrEmpty($ReviewTaskId)) {
    Write-Host 'review-run: FAIL -ReviewTaskId is required.'
    exit 1
}
if ([string]::IsNullOrEmpty($Pass)) {
    Write-Host 'review-run: FAIL -Pass is required (e.g., pass-01).'
    exit 1
}

. (Join-Path $PSScriptRoot 'lib/encoding.ps1')
. (Join-Path $PSScriptRoot 'lib/path.ps1')
. (Join-Path $PSScriptRoot 'lib/json.ps1')
. (Join-Path $PSScriptRoot 'lib/resolve-script.ps1')

function Invoke-CodexExec {
    param(
        [string] $InputPath,
        [string] $Model,
        [string] $ResultMdPath
    )

    $content = Read-Utf8 -Path $InputPath

    # Reviewer-mode shield (deterministic, applied to every review-run invocation).
    # The prepared input.md is a COMPLETE review task. Codex runs non-interactively
    # under whatever global/user instruction file is installed (e.g. a Codex AGENTS.md
    # managed block that carries a session restore-offer / BRIEF protocol). Without an
    # explicit reviewer-mode declaration in the message, that operator-side restore-offer
    # can fire and the reviewer writes a "no BRIEF.md — how should I proceed?" question
    # instead of a canonical verdict, which then fails verdict parsing. This preamble
    # declares reviewer mode in-band so the review-result contract takes precedence over
    # any restore/session protocol — for ALL installed/global review usage, not one task.
    # It is prepended only to the piped stdin; input.md on disk is unchanged (canonical
    # artifact + write-once preserved; review-input-verify still validates the real file).
    $reviewerPreamble = @'
===== AI-HARNESS-TOOLSET CODEX REVIEWER MODE (do not deviate) =====
You are running as the ai-harness-toolset Codex REVIEWER, invoked non-interactively by review-run.ps1.
The text after the BEGIN REVIEW INPUT marker below is a COMPLETE, self-contained review task (the prepared input.md). Treat it as the entire task.

These reviewer-mode rules take PRECEDENCE over any global/user instruction, including any CLAUDE.md / AGENTS.md restore-offer, BRIEF / session-restore, or checkpoint protocol:
- Do NOT look for, read, or require <ProjectRoot>/log/brief/BRIEF.md or any Brief. Its absence is irrelevant in reviewer mode and is NOT a reason to pause.
- Do NOT perform restore-offer, BRIEF bootstrap, session recovery, or any session/restore protocol.
- Do NOT ask the user any question, and do NOT request clarification. There is no interactive user in this run.
- ALWAYS produce a canonical review result as your final message: exactly one top-level "## Verdict" heading whose first non-empty following line is EXACTLY one of: yes | no | yes with risk. You may also add "## Findings", "## Risks", "## Notes".
- ALWAYS include each of these four H2 disclosure headings exactly once in result.md, case-sensitive (parser-required by review-verify -RequireResult since RV-B-05 V2): "## Blocking findings", "## Non-blocking concerns", "## Review limitations", "## Assumptions relied on". If a section has no substance, set its body to the single word "none".
- If the input is insufficient to approve, do NOT ask — return "no" or "yes with risk" and record the missing evidence under "## Findings" / "## Risks".
- Writing a question, a restore-offer, or any final message without a canonical "## Verdict" heading is a review FAILURE.
===== BEGIN REVIEW INPUT (input.md) =====
'@
    $payload = $reviewerPreamble + "`n" + $content

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
            # Pipe the same reviewer-mode payload the real CLI receives, so the stub can
            # assert the reviewer-mode preamble is present on stdin (regression coverage).
            $null = $payload | & powershell.exe @stubArgs
            $code = $LASTEXITCODE
        }
        finally {
            if (Test-Path -LiteralPath $argsTempPath) {
                Remove-Item -LiteralPath $argsTempPath -Force -ErrorAction SilentlyContinue
            }
        }
    }
    else {
        $null = $payload | & $codexCmd @codexArgs
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

        # Lowercase-exact verdict match. `Yes`, `YES`, `Yes with risk` etc. are
        # rejected — must match what review-verify.ps1 Test-VerdictShape accepts.
        if ($candidate -ceq 'yes' -or $candidate -ceq 'no' -or $candidate -ceq 'yes with risk') {
            return $candidate
        }
        return ''
    }
    return ''
}

function Get-ReviewerModel {
    param(
        [string] $ExplicitModel,
        [string] $ToolPath
    )

    if (-not [string]::IsNullOrEmpty($ExplicitModel)) {
        return $ExplicitModel
    }

    $configPath = Join-Path -Path $ToolPath -ChildPath 'config/reviewer.json'
    if (Test-Path -LiteralPath $configPath -PathType Leaf) {
        $cfg = Read-JsonFile -Path $configPath
        if ($null -ne $cfg -and $null -ne $cfg.PSObject.Properties['model']) {
            $m = [string]$cfg.model
            if (-not [string]::IsNullOrEmpty($m)) {
                return $m
            }
        }
    }

    return 'gpt-5.5'
}

if ($Reviewer -ne 'codex') {
    Write-Host ('review-run: FAIL only -Reviewer codex is supported in MVP; got {0}' -f $Reviewer)
    exit 1
}

try {
    [void] (Assert-ValidReviewTaskId -Value $ReviewTaskId)
}
catch {
    Write-Host ('review-run: FAIL invalid ReviewTaskId: {0}' -f $ReviewTaskId)
    exit 1
}

try {
    [void] (Assert-ValidPass -Value $Pass)
}
catch {
    Write-Host ('review-run: FAIL invalid Pass: {0}' -f $Pass)
    exit 1
}

$project = Get-ProjectRoot -ProjectRoot $ProjectRoot
$tool    = Get-ToolRoot -ToolRoot $ToolRoot -ProjectRoot $project
$logRoot = Get-ProjectLogRoot -ProjectRoot $project

$passDir = Get-ReviewPassDir -ProjectLogRoot $logRoot -ReviewTaskId $ReviewTaskId -Pass $Pass
try {
    [void] (Assert-InReviewRoot -Path $passDir -ProjectLogRoot $logRoot)
}
catch {
    Write-Host ('review-run: FAIL pass directory outside review root: {0}' -f $passDir)
    exit 1
}

if (-not (Test-Path -LiteralPath $passDir -PathType Container)) {
    Write-Host ('review-run: FAIL pass directory not prepared; run review-prepare first: {0}' -f $passDir)
    exit 1
}

$inputPath = Join-Path -Path $passDir -ChildPath 'input.md'
if (-not (Test-Path -LiteralPath $inputPath -PathType Leaf)) {
    Write-Host ('review-run: FAIL input.md not found: {0}' -f $inputPath)
    exit 1
}

$resultMdPath = Join-Path -Path $passDir -ChildPath 'result.md'
if (Test-Path -LiteralPath $resultMdPath -PathType Leaf) {
    Write-Host ('review-run: FAIL result.md already exists in pass directory: {0}. Each pass is write-once; allocate a new pass-NN under the same ReviewTaskId for another attempt.' -f $resultMdPath)
    exit 1
}

$model = Get-ReviewerModel -ExplicitModel $Model -ToolPath $tool
if ([string]::IsNullOrEmpty($model)) {
    Write-Host 'review-run: FAIL reviewer model could not be resolved (config/reviewer.json missing model field and no -Model override).'
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
    Write-Host ('review-run: FAIL input.md not ready (review-input-verify exit {0}). Allocate a new pass-NN under the same ReviewTaskId with a corrected input.md.' -f $verifyInputExit)
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
    Write-Host ('review-run: FAIL. Could not parse verdict from {0}. The failed pass is preserved on disk; allocate a new pass-NN under the same ReviewTaskId after fixing the reviewer output, prompt, or tooling.' -f $resultMdPath)
    exit 1
}

$relPass = (Resolve-ProjectRelativePath -Path $passDir -ProjectRoot $project) -replace '\\', '/'
$relResult = (Resolve-ProjectRelativePath -Path $resultMdPath -ProjectRoot $project) -replace '\\', '/'

Write-Host ('review-run: PASS')
Write-Host ('review-task-id: {0}' -f $ReviewTaskId)
Write-Host ('pass: {0}' -f $Pass)
Write-Host ('verdict: {0}' -f $verdict)
Write-Host ('pass-dir: {0}' -f $relPass)
Write-Host ('result: {0}' -f $relResult)
exit 0
