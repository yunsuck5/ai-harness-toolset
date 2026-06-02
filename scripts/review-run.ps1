[CmdletBinding()]
param(
    [string] $ReviewTaskId,

    [string] $Pass,

    [string] $Reviewer = 'codex',
    [string] $Model,
    [string] $Effort,
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
        [string] $Effort,
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
- ALWAYS produce a canonical review result as your final message: exactly one top-level "## Verdict" heading whose first non-empty following line is EXACTLY one of: yes | no | yes with risk. You may also add "## Findings", "## Risks", "## Counter-argument", "## Notes".
- ALWAYS include each of these four H2 disclosure headings exactly once in result.md, case-sensitive (parser-required by review-verify -RequireResult since RV-B-05 V2): "## Blocking findings", "## Non-blocking concerns", "## Review limitations", "## Assumptions relied on". If a section has no substance, set its body to the single word "none".
- Before issuing the final verdict, articulate the strongest case AGAINST your own conclusion in "## Counter-argument" (especially when the verdict is "yes" or "yes with risk") — this is the dedicated pressure-test surface per docs/contracts/review/REVIEW_RESULT_CONTRACT.md §3c. If no material counter-argument exists after deliberate pressure-test, use a short literal such as "none" or "no material counter-argument identified" — avoid ceremonial boilerplate. "## Counter-argument" is optional and strongly-recommended (NOT parser-required); "## Notes" remains available for general observations, framing self-audit, evidence pointers, or other reviewer narrative.
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
        # Reviewer-safe invocation hardening (Batch C). --ignore-user-config makes the
        # reviewer-safe posture STRUCTURAL rather than dependent on flag-precedence over a
        # permissive global config: the reviewer tool's $CODEX_HOME/config.toml (which may carry
        # operator-convenience permissive settings such as sandbox_mode=danger-full-access /
        # approval_policy=never) is NOT loaded at all, so it cannot weaken the explicit
        # --sandbox read-only / --ask-for-approval never below. Auth still uses $CODEX_HOME.
        # Everything review-run depends on (model, reasoning effort, web_search, sandbox,
        # approval) is passed explicitly here, so dropping config.toml does not change behavior;
        # the disclosed trade-off is that a user config carrying a custom model provider /
        # base_url would also be dropped (docs/policies/REVIEWER_CONFIG_POLICY.md). reviewer-safe
        # precedence is verified for tested write vectors only (scripts/review-safety-negtest.ps1),
        # not a blanket guarantee. reviewer-tool-specific: re-derive if the reviewer tool changes.
        '--ignore-user-config',
        '--model', $Model,
        '-c', 'web_search=disabled',
        '-c', ('model_reasoning_effort={0}' -f $Effort),
        '--output-last-message', $ResultMdPath,
        '-'
    )

    $stderrTemp = [System.IO.Path]::GetTempFileName()
    $appliedEffort = ''
    $prevPref = $ErrorActionPreference
    # Native stderr must be captured to a file (not merged) so the Codex exec
    # header line "reasoning effort: <value>" can be read back as the applied-effort
    # run-fact. Under file-level $ErrorActionPreference = 'Stop', capturing native
    # stderr promotes the first stderr line to a terminating NativeCommandError
    # before $LASTEXITCODE can be read (docs/policies/POWERSHELL_POLICY.md), so the
    # capture is wrapped in EAP=Continue save/restore.
    $ErrorActionPreference = 'Continue'
    try {
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
                $null = $payload | & powershell.exe @stubArgs 2> $stderrTemp
                $code = $LASTEXITCODE
            }
            finally {
                if (Test-Path -LiteralPath $argsTempPath) {
                    Remove-Item -LiteralPath $argsTempPath -Force -ErrorAction SilentlyContinue
                }
            }
        }
        else {
            $null = $payload | & $codexCmd @codexArgs 2> $stderrTemp
            $code = $LASTEXITCODE
        }
    }
    finally {
        $ErrorActionPreference = $prevPref
    }

    # Read the captured native stderr back and extract the applied reasoning-effort
    # run-fact. PowerShell wraps native stderr lines as NativeCommandError records
    # ("<exe> : <line>") when redirected with 2>, so the match is intentionally not
    # line-anchored and is restricted to the known effort value set; this finds the
    # Codex exec header "reasoning effort: <value>" whether or not it carries the
    # PowerShell error-record prefix. Absence is surfaced by the caller as an
    # unobserved run-fact, never as a silent success. On a non-zero exit the captured
    # stderr is echoed for diagnosis; on success it is not, to keep run output clean.
    if (Test-Path -LiteralPath $stderrTemp) {
        $errEnc = New-Object System.Text.UTF8Encoding($false)
        $errText = [System.IO.File]::ReadAllText($stderrTemp, $errEnc)
        if ($errText -match 'reasoning effort:\s*(none|minimal|low|medium|high|xhigh)\b') {
            $appliedEffort = $matches[1]
        }
        if ($code -ne 0 -and -not [string]::IsNullOrEmpty($errText)) {
            [Console]::Error.Write($errText)
        }
        Remove-Item -LiteralPath $stderrTemp -Force -ErrorAction SilentlyContinue
    }

    return [pscustomobject]@{ ExitCode = $code; AppliedEffort = $appliedEffort }
}

function Get-VerdictFromResultMd {
    param([string] $Path)

    $text = Read-Utf8 -Path $Path
    $lines = $text -split "`r?`n"

    $headingPositions = @()
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i].TrimEnd() -ceq '## Verdict') {
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

    # No built-in model fallback. A concrete model version (a specific released model identifier) is
    # tied to an external lifecycle, so hardcoding one as a default/fallback would silently mask a
    # missing source-of-truth. The model must come from config/reviewer.json 'model' (or an explicit
    # -Model); returning empty makes the caller fail-fast. fallbackModel is NOT auto-used.
    return ''
}

function Get-AllowedReasoningEfforts {
    # Allowed model_reasoning_effort values accepted by the current reviewer tool
    # (Codex CLI), enumerated by Batch A investigation (the CLI rejects out-of-set
    # values at config-load with a non-zero exit). review-run validates against this
    # set so an invalid effort fails fast here with a clear message rather than only
    # surfacing as a downstream Codex error. reviewer-tool-specific: re-derive if the
    # reviewer tool changes.
    return @('none', 'minimal', 'low', 'medium', 'high', 'xhigh')
}

function Get-ReviewerEffort {
    param(
        [string] $ExplicitEffort,
        [string] $ToolPath
    )

    # Precedence (docs/policies/REVIEWER_CONFIG_POLICY.md):
    # explicit CLI -Effort > config/reviewer.json reasoningEffort > built-in safe default.
    if (-not [string]::IsNullOrEmpty($ExplicitEffort)) {
        return [pscustomobject]@{ Effort = $ExplicitEffort; Source = 'explicit' }
    }

    $configPath = Join-Path -Path $ToolPath -ChildPath 'config/reviewer.json'
    if (Test-Path -LiteralPath $configPath -PathType Leaf) {
        $cfg = Read-JsonFile -Path $configPath
        if ($null -ne $cfg -and $null -ne $cfg.PSObject.Properties['reasoningEffort']) {
            $e = [string]$cfg.reasoningEffort
            if (-not [string]::IsNullOrEmpty($e)) {
                return [pscustomobject]@{ Effort = $e; Source = 'config' }
            }
        }
    }

    # Built-in safe default per the adopted decision record
    # (docs/systems/review/REVIEW_POLISHING_DECISION_RECORD.md): default = latest
    # model + xhigh; only clearly-simple local-correctness packets downgrade via an
    # explicit -Effort. This is the safe-default, not an operational U9 claim.
    return [pscustomobject]@{ Effort = 'xhigh'; Source = 'default' }
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
    Write-Host 'review-run: FAIL reviewer model could not be resolved. Set "model" in config/reviewer.json (or pass -Model). There is no built-in model fallback: a concrete model version is tied to an external lifecycle and must come from the config source-of-truth.'
    exit 1
}

$effortResolved = Get-ReviewerEffort -ExplicitEffort $Effort -ToolPath $tool
$effort = $effortResolved.Effort
$effortSource = $effortResolved.Source
$allowedEfforts = Get-AllowedReasoningEfforts
# Case-SENSITIVE membership: the reviewer tool's allowed values are exact lowercase
# (Batch A). PowerShell -notcontains is case-insensitive, so a wrong-case value such as
# 'XHIGH' would slip past and reach Codex (which then rejects it downstream) instead of
# failing fast here before any Codex invocation. -cnotcontains enforces the fail-fast.
if ($allowedEfforts -cnotcontains $effort) {
    Write-Host ('review-run: FAIL invalid reasoning effort ''{0}'' (source: {1}). Allowed values (case-sensitive): {2}. No silent fallback; correct -Effort or config/reviewer.json reasoningEffort.' -f $effort, $effortSource, ($allowedEfforts -join ', '))
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

$codexResult = Invoke-CodexExec -InputPath $inputPath -Model $model -Effort $effort -ResultMdPath $resultMdPath
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
Write-Host ('requested-effort: {0}' -f $effort)
Write-Host ('effort-source: {0}' -f $effortSource)
if ([string]::IsNullOrEmpty($codexResult.AppliedEffort)) {
    # Run-fact not observed in the Codex stderr header. Reported as such, not as a
    # silent success: do not infer that the requested effort was applied.
    Write-Host 'applied-effort: not-observed'
}
elseif ($codexResult.AppliedEffort -ne $effort) {
    Write-Host ('applied-effort: {0} (WARNING: differs from requested {1})' -f $codexResult.AppliedEffort, $effort)
}
else {
    Write-Host ('applied-effort: {0}' -f $codexResult.AppliedEffort)
}
Write-Host ('pass-dir: {0}' -f $relPass)
Write-Host ('result: {0}' -f $relResult)
exit 0
