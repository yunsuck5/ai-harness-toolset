---
name: ai-harness-review
description: Run an ai-harness-toolset review on the user's current in-progress work. Trigger this skill on natural-language Korean or English intents that ask for a Codex / 코덱스 review of the current work, optionally preceded by a caller self-review. Examples that should trigger this skill — "현재 진행한 작업 코덱스 리뷰 진행해", "지금까지 한 작업 리뷰해 줘", "코덱스로 리뷰 돌려", "현재 구현된 서버의 소켓 라이브러리를 니가 직접 리뷰하고, 그후에 코덱스 리뷰로 한번 더 리뷰 후 최종 결론 도출해", "review what I just did with codex", "self-review then codex review and give the final verdict". Do NOT trigger on `/review`, `/security-review`, or any non-ai-harness review. Do not require the user to provide review CLI arguments — derive them from the current work.
---

# ai-harness-review

This skill drives the canonical `prepare → author → run → semantic intake` flow. One review record is `<ProjectRoot>/log/review/<review-task-id>/<perspective>/pass-NN/{input.md,result.md}`. A `review unit` means one `(perspective, pass-NN)` pair; each unit is write-once and permits exactly one reviewer invocation. A dual-perspective review therefore has two units, not one invocation shared across both.

Canonical dual-perspective coverage consists of two focused units: `local-correctness` and `system-coherence`. If either perspective is intentionally omitted or reduced, report `coverage-limited` with the omitted or reduced perspective and rationale. If no reviewable change exists, issue a caller-side `no-reviewable-change` report, not a verdict.

The calling agent performs the workflow. The user does not supply CLI arguments.

Only a semantically usable reviewer-unit result produced through `review-run.ps1` supplies a canonical reviewer verdict; caller self-review supplies packet context and a separate caller judgment, never a substitute reviewer verdict.

## Supported intents

1. **Reviewer-only (Mode A).** Review the current work; skip caller self-review.
2. **Caller self-review + reviewer (Mode B).** Review the named subsystem yourself, carry your findings into the packet, then merge only two usable judgments: `no` if either is `no`, otherwise `yes with risk` if either is that value, and `yes` only if both are `yes`. If reviewer judgment is unavailable, issue no merged verdict.

Review style and target scope are independent. Follow an explicit mixed request.

## Required workflow

### 0. Preserve context and resolve roots

- Inspect `git status --porcelain=v1` and `git diff`. Do not restart, rebase, switch, stash, reset, stage, or edit source merely to run review.
- `<ProjectRoot>` is the inspected repo. Resolve `<ToolRoot>` in order: explicit argument → `AI_HARNESS_TOOL_ROOT` → `%USERPROFILE%\ai-harness-toolset\current` → source-repo dogfooding → stop. Do not auto-install.
- When the target changes review machinery (runner/verifier/skill/templates/config or its contract), establish engine eligibility from existing facts available through authorized read-only inspection: repository status/diff/history, the candidate engine payload, installation metadata, and any already-existing user-provided checkout. When this gate applies to a global stable installation, read the three named provenance files from the stable InstallArea that contains its `current/` ToolRoot, then confirm and record the current payload-head provenance through `payload-manifest.json.head == payload-marker.json.head == install.json.lastUpdatedHead`; `install.json.installedHead` is initial-install history, and the cross-binding proves only the payload head jointly named by that metadata. Use an engine only when the available facts affirmatively establish that it is a usable pre-change engine excluding every included review-machinery change; an engine shown to contain an included change is in-development and ineligible. Prefer an eligible global stable ToolRoot, then an already-existing user-provided pre-change independent checkout. Do not create a checkout or generate or persist a hash, preimage, byte/content binding, comparison artifact, or evidence bundle solely to prove engine eligibility. If the existing facts do not establish an eligible engine—including because provenance is missing, unreadable, unequal, or otherwise insufficient—stop and report an engine-eligibility gap; do not manufacture additional proof or fall back to the in-development runner.

### 1. Bind the target accurately

**Mode A:** follow the user's stated target: use the uncommitted working-tree changed set and/or the committed delta against a stated base (for example, `main..HEAD`), excluding `log/`, generated artifacts, `.gitignore`-only noise, and genuinely unrelated edits. Include untracked files only when user intent clearly covers them. If no reviewable change exists, report that and stop.

**Mode B:** resolve the named subsystem from `git ls-files`, regardless of dirty state. Prefer a directory match, then filename match; exclude tests/fixtures only when the request does not cover them. Current diff is context and must not redefine the named subsystem.

Put target/scope and required-evidence omissions under `## Known concerns`. Do not shrink scope for cost, latency, or an easier verdict. Ask at most one clarification only if the named subsystem does not resolve, spans unrelated trees, or Mode A/B intent is genuinely ambiguous.

Before allocating a unit, apply any active project rule that defines a retirement-only closeout transaction predicate. Inspect the proposed closeout transaction itself and its complete source delta. If it exactly matches the rule's allowed retirement shape, issue `no-reviewable-change` and stop without prepare/run. If the predicate is missing or cannot be applied, or any additional changed path, byte, mode, or source-managed untracked artifact exists, treat the change as an ordinary content-bearing target; do not run a closeout review to legitimize the mismatch.

Use repo-relative forward-slash paths and never list `log/` runtime artifacts as target files.

### 2. Allocate one write-once unit

Choose a public, purpose/gate-bound `<review-task-id>` for one independent review campaign and an explicit viewpoint `<perspective>`. One external task may have multiple campaigns; reuse the key only for another perspective or corrective/stale pass in the same campaign, and choose a new key for an independent review or a materially different purpose, gate, or Stage. Do not use person, machine, session, or process identity as the key. Invoke once:

```powershell
<ToolRoot>/scripts/review-prepare.ps1 `
  -ReviewTaskId <id> -Perspective <viewpoint> [-Pass <pass-NN>] [-ContinueCampaign] `
  -Stage <stage> -Purpose <line> -ProjectRoot <ProjectRoot> -ToolRoot <ToolRoot>
```

Use `design`, `implementation`, `test`, `review`, or `release` for `<stage>`; choose `implementation` for an ordinary code change unless a more specific review stage applies.

Without `-ContinueCampaign`, prepare claims a new campaign and fails if the task root already exists. Use `-ContinueCampaign` only after inspecting the existing canonical record and asserting that this is the same campaign: the first perspective starts without it; a second perspective or corrective/stale pass uses it. The switch is not authority or machine proof of purpose equality. `Purpose` is descriptive and printed for confirmation, but is not persisted or identity-binding.

Continuation requires at least one existing canonical `input.md`; task-root-only or input-less legacy/crash residue is not adopted. Before the first mutation, prepare checks the existing ancestry from the project log root through the task entry; before continuation or write, it also checks the canonical anchor and the ancestry from the task entry to the selected write parent. It fails closed on a reparse entry or wrong directory/file shape. This guards static existing entries, not a hostile mid-invocation path replacement.

Prepare chooses one explicit or auto candidate, exclusively claims that pass directory, and creates a new empty `input.md` without clobbering. Exactly one winner is required only when invocations compete for the same preselected pass coordinate. If an explicit claim takes `pass-02` before a later auto scan legitimately selects `pass-03`, both distinct allocations may succeed; the auto call did not retry a collision. A same-coordinate collision or incomplete allocation fails nonzero with no next-pass retry or automatic cleanup, and an orphan remains occupied. If `pass-99` is already occupied for the selected perspective, stop only that perspective and report range exhaustion; an explicit lower number cannot bypass it, while another perspective keeps its independent numbering. A lower allocation rechecks `pass-99` before publishing success. Confirmed concurrent occupancy makes the lower call nonzero and preserves its claimed pass as an occupied orphan. If the parent or enumeration cannot be inspected, the call is also nonzero but does not claim `pass-99` occupancy or lower-artifact persistence; inspect state manually and do not auto-retry or clean up. Do not roll over automatically to a new campaign key.

Author the new empty `input.md` in the next step. Never repair an old pass in place.

### 3. Author `input.md`

Use `<ToolRoot>/templates/review-input.md`; per duty, not H2: machine-required=shape-only; semantics default=always.

- **Machine-required:** H2 `Context`/`Required inspection paths`/`Review questions`/`Constraints`/`Final verdict` once each; packet-wide no active `AI_TO_FILL_*`. Post-required-H2→next required H2/EOF: non-Final trim-nonblank; Final contains `yes / no / yes with risk` case-insensitively; exact-case forbidden substrings absent.
- **Always:** Stage/Purpose/Review perspective/Target files/Context: unit/stage/exact artifact boundary; planning approval is not implementation corrected-state acceptance. Required paths: exact path+role; distinguish source target/runtime evidence/off-repo context. Questions: open-ended. Constraints: mutation/scope/authority. Validation states proportional scope/ran/not-run/reason/residual risk (script/runtime/parser/test/install normally full suite; docs/wording may be targeted). Evidence is support, not re-execution/truth oracle/freshness binding/source-of-truth; reviewer direct-read is default. Non-reproduction is target risk only on independent grounds, e.g. missing/stale evidence, scope mismatch, static contradiction, or explicit high-risk gap. `git diff --check`: tracked/index-visible only; never `git add -N`. Known concerns: unweakened facts/limits apart from questions; no caller conclusions/expected or prior verdicts/advocacy. Final: literal/no verdict; output instruction: runner preamble only.
- **Conditional (complete):** Context fact/open question only if material; external claim: exact provenance plus `unverified` if caller-unverified; persistence affecting severity/closure: finding prose states transience/committed-temporary boundary, no new verdict/H2/parser field/tag; task-grade only if user-supplied; never invent defaults, lower thresholds post-result, or auto-soften blockers. A false-positive dismissal requires evidence and an explicit user decision. Execution claim: cite reviewer-readable Markdown under `log/evidence/**`; broad reproduction: explicitly authorize exact command/cwd/expected read-write/allowed output/dependencies/timeout/interpretation boundary/sandbox-failure reporting; tool-native raw report: original path+claim in Required paths; new untracked file, no staging authority: direct whitespace/encoding check+narrow-coverage disclosure; Known concerns: material fact/compromise/validation limit/open question or target/scope/required-evidence omission; omitting that material/evidence or omission fact stales the pass; prior target/required-evidence artifact: exact direct-read path, no paraphrase; that off-repo/sibling material: advisory/never source-of-truth, caller-declared existing absolute directories with `-ExternalReadDirectory` and files with `-ExternalReadFile`, exact load-bearing targets in Required paths, no proxy/inline/stage/workspace copy. The reviewer reads them directly.
- **N/A-allowed (complete):** Validation evidence only when no execution/validation claim or related content; Known concerns only when no material concern/omission. Applicable-but-unperformed validation discloses not-run/reason/uncertainty. No other semantic location allows N/A.

### 모델·effort 선정

`<ToolRoot>/config/reviewer.json`의 기본값과 `categoryPolicy`의 용도 설명을 읽고 선택한다. 구체 모델 버전·기본 조합·운영/전문 대안은 그 config가 소유한다. 매 호출의 모델 순위 탐색이나 자동 대체는 하지 않는다.

- **목적부터:** 기획·보고서·절차·설계·코드 모두에서 무엇을 검증하는지 고른다. 파일 수·확장자만으로 분류하지 않는다. 의미 보존·논리·완전성·근거·수치·실현성·계약·경계·정합성·절차·코드 수명/데이터·검증 탐지력 등 실제 질문에 맞는 entry의 description을 읽는다. 여러 목적의 상호작용이 중심이면 `complex-broad`, 목적·영향이 모호하면 `default`다. category는 주목적이며 다른 관련 질문이나 canonical perspective의 coverage를 줄이지 않는다. 기존 키도 유효하고 자동 번역하지 않으며 새 호출에는 더 구체적인 목적을 고른다.
- **품질 여유:** 통상 xhigh를 중심으로 효율 지점보다 한 단계 여유를 둔다. 중요한 계약·권한·안전·데이터 손실·외부 의사결정·system-coherence·review 판단 경계에는 config의 `default`가 지정한 최상위 모델과 xhigh를 기준으로 한다. 국소·문구·수치·테스트라는 낮은 기본값이 중요한 영향을 가리지 않게 같은 목적 category에 명시 조합을 전달한다. 명시 사용자 축과 구체적으로 선택한 전문 대안은 별도로 존중하며 중요 영향만으로 무조건 ultra를 선택하지 않는다.
- **운영·전문 대안:** 결과 대기를 우선하면 high의 절충, 사용량 우선이면 문맥과 조건이 명확한 대안, 유휴시간이면 긴 인과·예외·소유권 추적에 xhigh/max 대안을 검토한다. description에 있는 조합과 조건으로 판단하고, 유휴라는 이유만으로 일괄 max를 적용하지 않는다. 중요한 영향을 속도·사용량 조건만으로 자동 하향하지 않는다. 하위 모델의 높은 effort가 항상 빠르거나 저렴하다고 보장하지 않으며 API 단가·구독 크레딧 환산·실제 계정 한도 차감률을 혼동하지 않는다. 실전 관측, 다른 용도로의 적용 가설, 품질 여유를 둔 운영 선택을 구별한다.
- **대안 전달:** 같은 검증 목적의 `-EffortCategory`를 유지하고 선택한 대안의 두 값을 `-Model`·`-Effort`로 명시해 기본 조합과 섞이지 않게 한다. 사용자가 한 축을 지정했다면 그 축을 우선하고 다른 축만 선택한 대안에서 채운다. 대안을 선택하지 않았다면 사용자가 지정한 축만 명시하고 나머지는 기존 category/scalar 해소에 둔다. description이나 적절한 대안이 없는 custom entry도 기존 기본값을 사용한다. description은 자유문 정보이며 runner가 파싱하는 실행 규칙이 아니다.
- **명시 최고·커스텀 요청:** 현존 최고 수준을 명시하면 `highest`의 최상위 모델·ultra를 선택하고 실제 검증 목적·범위를 함께 유지한다. 특정 모델의 최고 effort 요청은 범용 최고 요청과 구별한다. 구체 모델·effort 명시값은 각 축에서 우선하며, 추천 밖의 기존 effort 입력도 제거하지 않는다. 최고 요청을 이행할 설정이 없으면 그 상태를 설명하고 알고 있는 구체 명시값으로 적용한다. category miss의 scalar fallback을 최고 요청 이행으로 보고하지 않는다. 속도·절약·최고 요구가 충돌해 우선순위를 정할 수 없으면 충돌을 설명한다.

호출 전에 목적·중요 영향·운영 조건과 선택한 category·모델·effort의 이유를 짧게 설명한다. runner의 `explicit` source는 CLI 인자에서 해소됐다는 사실이며 사용자 원문이 해당 값을 직접 지정했다는 증거가 아니다. 모델·effort를 높여도 자료 부족이나 coverage 누락이 보완된 것으로 간주하지 않는다.
### 4. Run each review unit once

Invoke `review-run.ps1` once with the same ReviewTaskId, perspective, pass, ProjectRoot, and ToolRoot. It verifies input, invokes the reviewer once under the reviewer-safe posture, validates candidate shape, attempts provenance append, and re-validates final canonical shape in its tail. Do not call a second verifier as a mandatory workflow step.

timeout은 7day로 설정한다.   사용자 지시 없이 호출 취소는 금지한다

Rules:

- No silent retry, fallback model, argument-shape retry, bypass, or auto-fix. After a failed or semantically unusable unit, report the failure and proposed corrected invocation or input, then wait for explicit scoped user approval before allocating or running a new pass.
- Before any follow-up pass, record its closure basis: a changed reviewed artifact, newly available evidence, a corrected or clarified material claim/input that could change the review, or a blocker-bound explicit user disposition that changes the allowed next action. There is no retry cap, but when the reviewed state, evidence, material claim, and blocker disposition are unchanged, stop and report instead of allocating another pass.
- Once `review-run` starts, do not edit `input.md`. During this run step, the newly prepared canonical pass directory is the only runtime artifact location this workflow may write. Do not edit an existing or failed pass; if continuation or recovery requires mutation outside the new pass directory or approved review scope, stop and report instead of expanding scope.
- If the reviewer CLI is unavailable, report the environment gap and stop; do not install or refresh it.
- 모델·effort는 아래 선정 기준으로 정하고 기존 `-EffortCategory`·`-Model`·`-Effort`로 전달한다. 모델 결손과 malformed matched category는 fail-fast이며 지원 실패를 조용한 모델 교체로 숨기지 않는다.
- A new/changed template, contract, perspective, or artifact-binding in the used engine pipeline requires canary-first: complete one unit `prepare → run (tail verify included) → read` before the remainder. Canary is outside the same wave; a usable result cannot drop/reshape the remainder. A proven pipeline needs no canary.
- A proven read-only dual fixes two members, runs them concurrently with isolated output, and joins terminal/launch-failed/not-launched-with-reason accounting before any result's semantic use. After a canary, run the remainder only. Allocation and mutation/git stay foreground serial. An early result cannot cancel/reshape a member; do not shard system-coherence, drop a slow member, poll, or conclude before fixed-set accounting and then member-failure handling.
- If usable member results conflict and there is no evidence-bound basis to reduce the conflict, stop and report it; do not merge or conclude.
- If runner exits nonzero, classify reviewer invocation unavailable vs review result unavailable, report exit/last status/result existence, preserve the pass, and stop. Neither state has a verdict.

### 5. Perform semantic intake

After clean exit, read authored `input.md` with full `result.md`, not H1 alone. Unaddressed material fact/question stays unresolved without becoming an echo gate. Consume:

- `## Blocking findings`
- `## Non-blocking concerns` — the single canonical location for named risks, including a `yes with risk` risk
- `## Review limitations`
- `## Assumptions relied on`
- optional `## Counter-argument` and `## Notes`

Counter-argument is optional, strongly recommended, and non-parser. For yes-family, pressure-test the conclusion; use `none` instead of boilerplate. Omission is not a parser failure.

Shape validity is not semantic usability. A `no` is semantically usable only when every blocking finding identifies (1) a concrete failure mode or path, or a direct contract or acceptance breach, (2) the affected consumer or decision, and (3) the failed function, outcome, or contract. Unknown or missing information, or an unperformed check, is not by itself a blocker unless that absence directly breaches an explicit contract requirement. A `no` without this rational blocker basis, or `yes with risk` without named risk substance under Non-blocking concerns, is review result unavailable: preserve the actual provenance, consume no verdict, and do not create a fourth verdict. Treat limitation/assumption/risk-bearing content as part of next-action judgment.

Classify every rational blocker into exactly one operator disposition: `in-scope correction`, `out-of-scope stop`, `reviewer overreach`, or `false-positive or evidence gap`. The last two require an evidence-bound explanation and explicit user disposition; neither automatically dismisses the finding or converts `no` into another verdict. Preserve the prior `no` and its findings in the write-once canonical pass as historical fact even when a later correction, challenge, or review changes the current decision basis.

Read runner provenance as machine run facts, not reviewer judgment. For review-system self-modification, confirm stable engine identity, reviewer-safe posture, applied effort, and any anomaly. Do not reproduce normal stdout/provenance as a long ceremonial report.

If the review-bound source-managed artifact set changes after a unit, or any reviewed artifact changes in source-managed bytes/content, path, Git mode, or target-relevant meaning, that unit is stale. An exact project-rule-qualified retirement-only closeout changes no reviewed target-state meaning; the project rule classifies its bounded lifecycle-artifact retirement and marker transition as no-reviewable, so it neither stales the unit nor creates a new review target. A predicate miss or any other change to the review-bound artifact set, source-managed bytes/content, path, Git mode, or target-relevant meaning uses ordinary staleness and returns to the corrected candidate; do not allocate a closeout pass as a substitute. If a prior claim, citation, count, framing, scope, or verdict intake proves wrong, explicitly retract what was wrong, why, and the current state.

### 6. Reduce and report

Use a reviewer verdict only when the final unit is semantically usable. For Mode B, apply the merge table under Supported intents. Report `Reviewer verdict: N/A — no usable reviewer judgment issued` when unavailable; do not normalize another token into a verdict.

Keep the final report compact but include:

- perspective coverage and invocation packaging;
- invocation count, artifact pass count per perspective/final path, and corrective-loop count as separate axes;
- usable verdict plus the four disclosure bodies, named risk handling, stale/re-review status;
- validation evidence/scope and limitations;
- Notes에 관측된 서브에이전트 역할·모델·effort·깊이가 있으면 그 범위를 전달한다. 모르는 값은 unknown으로 두며 관측이 없다는 이유로 추가 조회나 필수 결과 항목을 만들지 않는다;
- final git status and exact target/omission boundary;
- reviewer guard anomaly or, for review-system self-modification, stable engine identity/posture/effort;
- recommended next action and its authority boundary.

Verdict mapping:

- `yes`: surface non-blocking concerns/limitations/assumptions; any mutation or next batch still needs its own authority.
- `no`: apply the four-way blocker disposition. For `in-scope correction`, correct within authority and use a closure-based corrected-state re-review; for `out-of-scope stop`, stop and request scope. For `reviewer overreach` or `false-positive or evidence gap`, present the evidence-bound disposition for explicit user decision without rewriting the prior result.
- `yes with risk`: surface named risks from Non-blocking concerns and require explicit acceptance or a re-review closure path. It is not automatic `yes`.

Never let a verdict authorize commit, push, publish, merge, release, deployment, adoption, global/user-file mutation, or stable-install refresh. This skill never performs those actions.

## Failure and non-goals

- Do not edit target code merely to obtain a favorable verdict, average multiple cycles, impose a retry cap, repeat a pass with unchanged reviewed state/evidence/material claim/blocker disposition, or weaken a user-supplied finding threshold after results.
- Do not modify user-global instruction/skill/config homes or git config, and do not clean canonical review/evidence artifacts.
- Do not promote runtime evidence or off-repo planning material to source authority.
- Do not invent a result, pass, model/version, validation claim, or reviewer judgment.
