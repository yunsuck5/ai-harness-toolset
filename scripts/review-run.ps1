[CmdletBinding()]
param(
    [string] $ReviewTaskId,

    [string] $Pass,

    # Required review viewpoint (strict C1 canonical layout). Resolves the three-level pass
    # dir log/review/<review-task-id>/<perspective>/pass-NN/. There is no two-level fallback
    # and no inference; empty / missing fails fast.
    [string] $Perspective,

    [string] $Reviewer = 'codex',
    [string] $Model,
    [string] $Effort,
    # Explicit, operator-chosen review category (U9 config-backed category->{model,effort}
    # policy). The operator chooses the category (judgment); config/reviewer.json categoryPolicy
    # supplies its {model, reasoningEffort} (mechanical lookup); this runner applies it. There is
    # NO automatic category inference here (not from changed files, not from -Stage, not LLM-based).
    # A category not present in categoryPolicy is a soft miss (falls back to the scalar config), not
    # a hard failure. Precedence per axis: explicit -Model/-Effort > matched category entry >
    # scalar config > (effort) built-in xhigh / (model) fail-fast.
    [string] $EffortCategory,
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
if ([string]::IsNullOrEmpty($Perspective)) {
    Write-Host 'review-run: FAIL -Perspective is required. The canonical review artifact layout is log/review/<review-task-id>/<perspective>/pass-NN/; there is no two-level fallback. Pass the same -Perspective used at review-prepare.'
    exit 1
}

. (Join-Path $PSScriptRoot 'lib/encoding.ps1')
. (Join-Path $PSScriptRoot 'lib/path.ps1')
. (Join-Path $PSScriptRoot 'lib/json.ps1')
. (Join-Path $PSScriptRoot 'lib/resolve-script.ps1')

function Get-CodexAdapterVersion {
    # Adapter-specific (codex) version-reporting READER. The ACTIVE reviewer adapter's
    # version is a RUNTIME OBSERVATION, not a caller declaration: it is read from the
    # version banner the codex CLI prints to stderr on exec (the same banner that already
    # yields the applied reasoning-effort run-fact), so no extra process is spawned and the
    # observation is consistent with the applied-effort capture. No concrete version is
    # hardcoded here — whatever version the adapter reports is captured; when the banner
    # carries no parseable version the caller reports 'not-observed' (no silent success).
    # reviewer-tool-specific: a different reviewer adapter supplies its OWN version-reporting
    # reader; this function is only the codex adapter's path and is NOT a general durable
    # rule. Keep the vendor-specific banner shape isolated behind this helper.
    param([string] $StderrText)

    if ([string]::IsNullOrEmpty($StderrText)) {
        return ''
    }
    # Capture a semantic version that follows a codex / "OpenAI Codex" banner marker, so a
    # model name or other digit-bearing banner line (e.g. the model: line) cannot be
    # mistaken for the adapter version. The version literal itself is captured at runtime,
    # never hardcoded as a default or expectation.
    if ($StderrText -match '(?im)(?:codex[-\s]cli|OpenAI\s+Codex|codex)\s+v?(\d+\.\d+\.\d+(?:[-+.][0-9A-Za-z.-]+)?)') {
        return $matches[1]
    }
    return ''
}

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
    # managed block that carries an operator-side session-restore / Brief / continuation protocol). Without an
    # explicit reviewer-mode declaration in the message, that operator-side session-restore protocol
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

These reviewer-mode rules take PRECEDENCE over any global/user instruction, including any CLAUDE.md / AGENTS.md operator-side session-restore, Brief restore, continuation, or checkpoint protocol:
- Do NOT look for, read, or require <ProjectRoot>/log/brief/BRIEF.md or any Brief. Its absence is irrelevant in reviewer mode and is NOT a reason to pause.
- Do NOT perform any operator-side Brief restore, session restore, continuation, or session-recovery protocol, and do NOT proactively offer to restore from a Brief.
- Do NOT ask the user any question, and do NOT request clarification. There is no interactive user in this run.
- ALWAYS produce a canonical review result as your final message: exactly one top-level "## Verdict" heading whose first non-empty following line is EXACTLY one of: yes | no | yes with risk. You may also add "## Findings", "## Risks", "## Counter-argument", "## Notes".
- ALWAYS include each of these four H2 disclosure headings exactly once in result.md, case-sensitive (parser-required by review-verify -RequireResult since RV-B-05 V2): "## Blocking findings", "## Non-blocking concerns", "## Review limitations", "## Assumptions relied on". If a section has no substance, set its body to the single word "none".
- Before issuing the final verdict, articulate the strongest case AGAINST your own conclusion in "## Counter-argument" (especially when the verdict is "yes" or "yes with risk") — this is the dedicated pressure-test surface for the verdict. If no material counter-argument exists after deliberate pressure-test, use a short literal such as "none" or "no material counter-argument identified" — avoid ceremonial boilerplate. "## Counter-argument" is optional and strongly-recommended (NOT parser-required); "## Notes" remains available for general observations, framing self-audit, evidence pointers, or other reviewer narrative.
- If the input is insufficient to approve, do NOT ask — return "no" or "yes with risk" and record the missing evidence under "## Findings" / "## Risks".
- Writing a question, an operator-side Brief / session-restore or continuation message, or any final message without a canonical "## Verdict" heading is a review FAILURE.
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

    # Reviewer-safe posture run-fact (Batch D2): the STRUCTURAL safety flags actually
    # present in $codexArgs for THIS invocation, surfaced for operator debugging. Derived
    # from $codexArgs (not a free-floating literal) so it cannot drift from what is really
    # sent to the reviewer CLI. This is the posture flags only — it is NOT a blanket safety
    # guarantee; reviewer-safe precedence is verified for tested write vectors only
    # (scripts/review-safety-negtest.ps1), and that tested-vectors-only caveat is kept in the
    # final report / docs layer (docs/policies/REVIEWER_CONFIG_POLICY.md), never asserted here.
    $postureParts = @()
    $approvalIdx = [array]::IndexOf($codexArgs, '--ask-for-approval')
    if ($approvalIdx -ge 0 -and $approvalIdx + 1 -lt $codexArgs.Count) {
        $postureParts += ('--ask-for-approval {0}' -f $codexArgs[$approvalIdx + 1])
    }
    $sandboxIdx = [array]::IndexOf($codexArgs, '--sandbox')
    if ($sandboxIdx -ge 0 -and $sandboxIdx + 1 -lt $codexArgs.Count) {
        $postureParts += ('--sandbox {0}' -f $codexArgs[$sandboxIdx + 1])
    }
    if ($codexArgs -contains '--ignore-user-config') {
        $postureParts += '--ignore-user-config'
    }
    if ($codexArgs -contains 'web_search=disabled') {
        $postureParts += 'web_search=disabled'
    }
    $reviewerSafePosture = ($postureParts -join ' ')

    $stderrTemp = [System.IO.Path]::GetTempFileName()
    $appliedEffort = ''
    $reviewerVersion = ''
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
        # Adapter version run-fact (P2): runtime-observed from the same reviewer run banner.
        # Isolated behind the codex adapter reader; absence -> '' (caller reports not-observed).
        $reviewerVersion = Get-CodexAdapterVersion -StderrText $errText
        if ($code -ne 0 -and -not [string]::IsNullOrEmpty($errText)) {
            [Console]::Error.Write($errText)
        }
        Remove-Item -LiteralPath $stderrTemp -Force -ErrorAction SilentlyContinue
    }

    return [pscustomobject]@{ ExitCode = $code; AppliedEffort = $appliedEffort; ReviewerSafePosture = $reviewerSafePosture; ReviewerVersion = $reviewerVersion }
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

function Resolve-ReviewerCategory {
    param(
        [string] $Category,
        [string] $ToolPath
    )

    # U9 category->{model,effort} lookup. Reads config/reviewer.json categoryPolicy ONCE and
    # reports the lookup outcome plus the matched entry object (or $null). Match values:
    #   'none'    — no -EffortCategory supplied (not a lookup).
    #   'matched' — supplied category key exists under categoryPolicy.
    #   'missed'  — supplied category key is absent (no categoryPolicy at all, or key not found).
    # A miss is a SOFT fallback to the scalar config (handled by the model/effort resolvers via a
    # $null entry); it never fails hard here. The returned Entry is passed to Get-ReviewerModel /
    # Get-ReviewerEffort so the category read happens in exactly one place and the run-facts cannot
    # drift from what the resolvers actually use. reviewer-tool-agnostic: this is config policy.
    if ([string]::IsNullOrEmpty($Category)) {
        return [pscustomobject]@{ Category = ''; Match = 'none'; Entry = $null }
    }

    $entry = $null
    $keyPresent = $false
    $configPath = Join-Path -Path $ToolPath -ChildPath 'config/reviewer.json'
    if (Test-Path -LiteralPath $configPath -PathType Leaf) {
        $cfg = Read-JsonFile -Path $configPath
        if ($null -ne $cfg -and $null -ne $cfg.PSObject.Properties['categoryPolicy']) {
            $cp = $cfg.categoryPolicy
            if ($null -ne $cp -and $null -ne $cp.PSObject.Properties[$Category]) {
                $keyPresent = $true
                # The value MAY be $null (JSON `"key": null`) — ConvertFrom-Json keeps the property
                # with a null value. Match is decided by KEY PRESENCE below, not by entry non-null.
                $entry = $cp.PSObject.Properties[$Category].Value
            }
        }
    }

    # Match by KEY PRESENCE, not by entry non-null. A present key whose value is null (or otherwise
    # malformed) is a matched-but-malformed category — the caller fails fast — NOT a soft miss.
    # Reporting it as 'missed' would silently fall back to the scalar config and hide a category
    # config typo (the same class this hardening closes). 'missed' is reserved for a genuinely
    # absent key. The returned Entry may be $null when matched-but-null; the caller handles that.
    if ($keyPresent) {
        return [pscustomobject]@{ Category = $Category; Match = 'matched'; Entry = $entry }
    }
    return [pscustomobject]@{ Category = $Category; Match = 'missed'; Entry = $null }
}

function Get-ReviewerModel {
    param(
        [string] $ExplicitModel,
        [string] $ToolPath,
        $CategoryEntry
    )

    # Returns the resolved model AND the actual resolver branch as Source (never an
    # inferred string): 'explicit' for -Model, 'category' for a matched categoryPolicy entry
    # carrying a non-empty 'model', 'config' for the scalar config/reviewer.json 'model', and ''
    # (empty model) for the fail-fast case. Mirrors Get-ReviewerEffort's shape so the
    # model-source run-fact is symmetric with effort-source.
    if (-not [string]::IsNullOrEmpty($ExplicitModel)) {
        return [pscustomobject]@{ Model = $ExplicitModel; Source = 'explicit' }
    }

    # Matched category entry MAY carry a per-category model override. 'model' is optional in a
    # category entry (schema): when present and non-empty it wins over the scalar config model;
    # when absent the scalar config model applies (a deliberate simplicity choice — no new model
    # fail-fast is introduced for a matched-but-model-less entry; effort is the primary lever).
    if ($null -ne $CategoryEntry -and $null -ne $CategoryEntry.PSObject.Properties['model']) {
        $cm = [string]$CategoryEntry.model
        if (-not [string]::IsNullOrEmpty($cm)) {
            return [pscustomobject]@{ Model = $cm; Source = 'category' }
        }
    }

    $configPath = Join-Path -Path $ToolPath -ChildPath 'config/reviewer.json'
    if (Test-Path -LiteralPath $configPath -PathType Leaf) {
        $cfg = Read-JsonFile -Path $configPath
        if ($null -ne $cfg -and $null -ne $cfg.PSObject.Properties['model']) {
            $m = [string]$cfg.model
            if (-not [string]::IsNullOrEmpty($m)) {
                return [pscustomobject]@{ Model = $m; Source = 'config' }
            }
        }
    }

    # No built-in model fallback. A concrete model version (a specific released model identifier) is
    # tied to an external lifecycle, so hardcoding one as a default/fallback would silently mask a
    # missing source-of-truth. The model must come from config/reviewer.json 'model' (or an explicit
    # -Model); returning an empty Model makes the caller fail-fast. fallbackModel is NOT auto-used.
    return [pscustomobject]@{ Model = ''; Source = '' }
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
        [string] $ToolPath,
        $CategoryEntry
    )

    # Precedence (docs/policies/REVIEWER_CONFIG_POLICY.md):
    # explicit CLI -Effort > matched categoryPolicy entry reasoningEffort >
    # scalar config/reviewer.json reasoningEffort > built-in safe default.
    # Source is the actual resolver branch: 'explicit' / 'category' / 'config' / 'default'.
    # The resolved effort (whatever its source) is validated against the allowed set by the
    # caller; an out-of-enum value from a matched category fails fast there with source: category.
    if (-not [string]::IsNullOrEmpty($ExplicitEffort)) {
        return [pscustomobject]@{ Effort = $ExplicitEffort; Source = 'explicit' }
    }

    # A matched category entry MUST carry a usable reasoningEffort (schema-required). When the
    # category is matched, this branch is authoritative for effort and does NOT silently fall back
    # to the scalar config on a missing/empty value — that would hide a category-config typo while
    # still reporting effort-policy-match: matched. So a matched entry always returns Source
    # 'category'; the caller fails fast when the resolved value is empty (missing reasoningEffort)
    # or out-of-enum. Only an UNMATCHED category (CategoryEntry $null) falls through to the scalar
    # config below (the soft-miss path). model stays optional per Get-ReviewerModel; effort does not.
    if ($null -ne $CategoryEntry) {
        $ce = ''
        if ($null -ne $CategoryEntry.PSObject.Properties['reasoningEffort']) {
            $ce = [string]$CategoryEntry.reasoningEffort
        }
        return [pscustomobject]@{ Effort = $ce; Source = 'category' }
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

function Add-ReviewerProvenanceBlock {
    # P3: persist runtime-observed reviewer provenance INSIDE the canonical result.md, as a
    # clearly demarcated, runner-appended block. This makes result.md self-describing for "what
    # run produced this verdict" WITHOUT a sidecar file (contract §1/§10) and WITHOUT any
    # input.md caller declaration. The block is MACHINE-EMITTED by the runner — it is NOT
    # authored by the reviewer adapter and NOT a reviewer verdict/judgment (contract §3
    # dual-authorship). All values are runtime / config / active-adapter / self-report
    # observations resolved earlier in this run; no concrete vendor/tool/model/version is
    # hardcoded (the observed value is written as-is, and an unobserved value is recorded
    # literally as not-observed). The block heading and its key:value body never collide with
    # the parser-gated headings (`## Verdict` + the four disclosure H2s), so the appended block
    # cannot change what review-verify.ps1 counts; it adds no parser gate of its own.
    param(
        [string] $ResultMdPath,
        [string] $Reviewer,
        [string] $ReviewerVersion,
        [string] $Model,
        [string] $ModelSource,
        [string] $RequestedEffort,
        [string] $EffortSource,
        [string] $AppliedEffort,
        [string] $EffortCategory,
        [string] $EffortPolicyMatch,
        [string] $ReviewerSafePosture,
        [string] $ToolRoot,
        [string] $ProjectRoot,
        [string] $ToolRootSource
    )

    $verVal = if ([string]::IsNullOrEmpty($ReviewerVersion)) { 'not-observed' } else { $ReviewerVersion }
    $appliedVal = if ([string]::IsNullOrEmpty($AppliedEffort)) { 'not-observed' } else { $AppliedEffort }

    $note = '_Machine-emitted by `review-run.ps1` (runner-appended). Runtime-observed run facts identifying this review run -- NOT authored by the reviewer adapter and NOT a reviewer verdict/judgment. Source: runtime / config / active reviewer adapter / reviewer self-report (never `input.md` caller declaration). Informational only; `review-verify.ps1` does not gate on it._'

    $body = @()
    $body += '## Reviewer run provenance'
    $body += ''
    $body += $note
    $body += ''
    $body += '```text'
    $body += ('reviewer: {0}' -f $Reviewer)
    $body += ('reviewer-version: {0}' -f $verVal)
    $body += ('model: {0}' -f $Model)
    $body += ('model-source: {0}' -f $ModelSource)
    $body += ('requested-effort: {0}' -f $RequestedEffort)
    $body += ('effort-source: {0}' -f $EffortSource)
    $body += ('applied-effort: {0}' -f $appliedVal)
    $body += ('effort-category: {0}' -f $EffortCategory)
    $body += ('effort-policy-match: {0}' -f $EffortPolicyMatch)
    $body += ('reviewer-safe-posture: {0}' -f $ReviewerSafePosture)
    $body += ('tool-root: {0}' -f $ToolRoot)
    $body += ('project-root: {0}' -f $ProjectRoot)
    $body += ('tool-root-source: {0}' -f $ToolRootSource)
    $body += '```'
    $blockText = ($body -join "`n") + "`n"

    # Preserve the reviewer-authored content byte-for-byte; only APPEND. The boundary is one
    # blank line + a thematic break (---) so the runner block is visually separated from the
    # reviewer body. Existing trailing-newline state is honored so no content is altered.
    $enc = New-Object System.Text.UTF8Encoding($false)
    $existing = [System.IO.File]::ReadAllText($ResultMdPath, $enc)
    $boundary = if ($existing.EndsWith("`n")) { "`n---`n`n" } else { "`n`n---`n`n" }
    [System.IO.File]::WriteAllText($ResultMdPath, ($existing + $boundary + $blockText), $enc)
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

try {
    [void] (Assert-ValidPerspective -Value $Perspective)
}
catch {
    Write-Host ('review-run: FAIL invalid Perspective: {0}' -f $Perspective)
    exit 1
}

$project = Get-ProjectRoot -ProjectRoot $ProjectRoot
$tool    = Get-ToolRoot -ToolRoot $ToolRoot -ProjectRoot $project
$logRoot = Get-ProjectLogRoot -ProjectRoot $project

$passDir = Get-ReviewPassDir -ProjectLogRoot $logRoot -ReviewTaskId $ReviewTaskId -Pass $Pass -Perspective $Perspective
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
    Write-Host ('review-run: FAIL result.md already exists in pass directory: {0}. Each pass is write-once; allocate a new pass-NN under the same ReviewTaskId/Perspective for another attempt.' -f $resultMdPath)
    exit 1
}

# U9: resolve the operator-chosen review category ONCE (soft-miss falls back to scalar config).
# The matched entry (or $null) is threaded into both axis resolvers so the category read happens
# in one place and the effort-category / effort-policy-match run-facts cannot drift from what the
# resolvers actually applied.
$categoryResolved = Resolve-ReviewerCategory -Category $EffortCategory -ToolPath $tool
$effortCategory = if ([string]::IsNullOrEmpty($EffortCategory)) { 'none' } else { $EffortCategory }
$effortPolicyMatch = $categoryResolved.Match

$allowedEfforts = Get-AllowedReasoningEfforts

# A matched category (key present) must be a WELL-FORMED config entry — validated UNCONDITIONALLY
# here, before the resolvers and INDEPENDENT of any explicit -Effort/-Model override. Naming a
# category whose entry is malformed is a config/usage error worth surfacing even when an explicit
# override would otherwise win the value, so a malformed matched entry can never be silently
# bypassed (by an override) nor silently downgraded to the scalar default. A matched entry must be
# a non-null object carrying a required, allowed-set reasoningEffort (model stays optional — a
# matched entry without model falls back to the scalar model). Only a genuinely absent key (Match
# 'missed') soft-falls-back to the scalar config; a present-but-malformed key fails fast here.
if ($effortPolicyMatch -eq 'matched') {
    if ($null -eq $categoryResolved.Entry) {
        Write-Host ('review-run: FAIL effort category ''{0}'' is present in config/reviewer.json categoryPolicy but its entry is null (a category entry must be an object with at least reasoningEffort). No silent fallback for a matched-but-malformed category.' -f $EffortCategory)
        exit 1
    }
    $matchedEffort = ''
    if ($null -ne $categoryResolved.Entry.PSObject.Properties['reasoningEffort']) {
        $matchedEffort = [string]$categoryResolved.Entry.reasoningEffort
    }
    if ([string]::IsNullOrEmpty($matchedEffort)) {
        Write-Host ('review-run: FAIL matched effort category ''{0}'' has no usable reasoningEffort in config/reviewer.json categoryPolicy (a category entry''s reasoningEffort is required). No silent fallback to the scalar default for a matched-but-malformed category; fix the category entry.' -f $EffortCategory)
        exit 1
    }
    if ($allowedEfforts -cnotcontains $matchedEffort) {
        Write-Host ('review-run: FAIL invalid reasoning effort ''{1}'' (source: category) in matched effort category ''{0}''. Allowed values (case-sensitive): {2}. No silent fallback; fix the category entry.' -f $EffortCategory, $matchedEffort, ($allowedEfforts -join ', '))
        exit 1
    }
}

$modelResolved = Get-ReviewerModel -ExplicitModel $Model -ToolPath $tool -CategoryEntry $categoryResolved.Entry
$model = $modelResolved.Model
$modelSource = $modelResolved.Source
if ([string]::IsNullOrEmpty($model)) {
    Write-Host 'review-run: FAIL reviewer model could not be resolved. Set "model" in config/reviewer.json (or pass -Model). There is no built-in model fallback: a concrete model version is tied to an external lifecycle and must come from the config source-of-truth.'
    exit 1
}

$effortResolved = Get-ReviewerEffort -ExplicitEffort $Effort -ToolPath $tool -CategoryEntry $categoryResolved.Entry
$effort = $effortResolved.Effort
$effortSource = $effortResolved.Source
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
    Write-Host ('review-run: FAIL input.md not ready (review-input-verify exit {0}). Allocate a new pass-NN under the same ReviewTaskId/Perspective with a corrected input.md.' -f $verifyInputExit)
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
    Write-Host ('review-run: FAIL. Could not parse verdict from {0}. The failed pass is preserved on disk; allocate a new pass-NN under the same ReviewTaskId/Perspective after fixing the reviewer output, prompt, or tooling.' -f $resultMdPath)
    exit 1
}

$relPass = (Resolve-ProjectRelativePath -Path $passDir -ProjectRoot $project) -replace '\\', '/'
$relResult = (Resolve-ProjectRelativePath -Path $resultMdPath -ProjectRoot $project) -replace '\\', '/'

# Persist runtime-observed reviewer provenance into result.md (P3). Only reached after the
# reviewer body was produced AND its verdict shape is usable, so provenance is never fabricated
# for a failed/absent review result. Provenance is a SUPPLEMENTARY record: per the spec's
# append-failure design, a persistence failure here must NOT invalidate an otherwise valid
# verdict, but it is reported loudly (provenance-persisted: FAILED ...) — never a silent success.
$provenancePersisted = $true
$provenanceError = ''
try {
    Add-ReviewerProvenanceBlock -ResultMdPath $resultMdPath `
        -Reviewer $Reviewer -ReviewerVersion $codexResult.ReviewerVersion `
        -Model $model -ModelSource $modelSource `
        -RequestedEffort $effort -EffortSource $effortSource -AppliedEffort $codexResult.AppliedEffort `
        -EffortCategory $effortCategory -EffortPolicyMatch $effortPolicyMatch `
        -ReviewerSafePosture $codexResult.ReviewerSafePosture `
        -ToolRoot $tool -ProjectRoot $project -ToolRootSource $toolRootSource
}
catch {
    $provenancePersisted = $false
    $provenanceError = $_.Exception.Message
}

Write-Host ('review-run: PASS')
Write-Host ('review-task-id: {0}' -f $ReviewTaskId)
Write-Host ('perspective: {0}' -f $Perspective)
Write-Host ('pass: {0}' -f $Pass)
Write-Host ('verdict: {0}' -f $verdict)
# Reviewer adapter identity run-facts (P2). H1 stdout run-facts, additive to the Batch D2
# set below. reviewer = the active reviewer adapter kind (runtime-resolved; MVP allows codex
# only). reviewer-version = the adapter version observed from the run banner, or not-observed
# when the active adapter reported no parseable version (no silent success, never hardcoded).
Write-Host ('reviewer: {0}' -f $Reviewer)
if ([string]::IsNullOrEmpty($codexResult.ReviewerVersion)) {
    Write-Host 'reviewer-version: not-observed'
}
else {
    Write-Host ('reviewer-version: {0}' -f $codexResult.ReviewerVersion)
}
Write-Host ('model: {0}' -f $model)
Write-Host ('model-source: {0}' -f $modelSource)
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
# U9 category policy run-facts (additive H1 run-facts). effort-category = the operator-chosen
# category (or 'none' when -EffortCategory was not supplied). effort-policy-match = the lookup
# outcome (none / matched / missed); 'missed' means the category was supplied but not present in
# config categoryPolicy, so the scalar config default applied (soft fallback, not a hard failure).
# When matched, effort-source above reads 'category'; model-source reads 'category' only when the
# matched entry carries a 'model' (else 'config' — category model is optional). explicit -Effort /
# -Model still win per axis even when a category matched.
Write-Host ('effort-category: {0}' -f $effortCategory)
Write-Host ('effort-policy-match: {0}' -f $effortPolicyMatch)
Write-Host ('reviewer-safe-posture: {0}' -f $codexResult.ReviewerSafePosture)
Write-Host ('tool-root: {0}' -f $tool)
Write-Host ('project-root: {0}' -f $project)
Write-Host ('tool-root-source: {0}' -f $toolRootSource)
Write-Host ('pass-dir: {0}' -f $relPass)
Write-Host ('result: {0}' -f $relResult)
# P3 provenance-persistence status (additive H1 run-fact; the P2/Batch D2 lines above are
# unchanged). On success the runtime provenance block is now inside result.md; on failure the
# verdict still stands but the persistence miss is surfaced, not swallowed.
if ($provenancePersisted) {
    Write-Host ('provenance-persisted: {0}' -f $relResult)
}
else {
    Write-Host ('provenance-persisted: FAILED -- {0}' -f $provenanceError)
}
exit 0
