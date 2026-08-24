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

Disclose every deliberate omission under `## Known concerns`. Do not shrink scope for cost, latency, or an easier verdict. Ask at most one clarification only if the named subsystem does not resolve, spans unrelated trees, or Mode A/B intent is genuinely ambiguous.

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

Use `<ToolRoot>/templates/review-input.md` as the writing reference. The input verifier requires these five H2 bodies to be non-empty: `Context`, `Required inspection paths`, `Review questions`, `Constraints`, and `Final verdict`. The last body must retain the literal string `yes / no / yes with risk` required by the existing input gate; leave that string in place and do not write a verdict there. Replace every active `AI_TO_FILL_*` placeholder before running; the input verifier rejects any that remains. The runner preamble—not this packet—owns the reviewer output runtime instruction.

Fill the compact informational positions when relevant:

- **Stage / Purpose / Review perspective / Target files:** identify this unit and exact artifact boundary. Do not merge planning approval with implementation corrected-state acceptance.
- **Artifact persistence:** require `Constraints` to tell the reviewer to state persistence in finding prose when it affects severity or closure. Transience alone does not make a finding non-blocking, and a committed temporary artifact remains a real review target while it exists. Do not add a verdict, H2, parser field, or tag for this.
- **Task-grade adjudication:** use a user-supplied task-grade table only when it was actually provided; invent no default. After results, do not lower its threshold or automatically reclassify a blocking finding as non-blocking. A false-positive dismissal requires evidence and an explicit user decision.
- **Validation evidence:** cite a reviewer-readable Markdown bundle under `log/evidence/**` when making execution claims, otherwise say N/A. Evidence is supporting material, not re-execution, a truth oracle, freshness binding, or source-of-truth. The reviewer reads it by default; broad build/test reproduction requires explicit authorization with the exact command, cwd, expected writes, allowed output path, dependencies, timeout, interpretation boundary, and sandbox-failure reporting. Non-reproduction is a limitation, not automatically target risk. Validation scope is proportional to change class; script/runtime/parser/test/install changes normally require the full suite, while docs/wording may use targeted checks. Disclose what ran, what did not, why, and residual risk. `git diff --check` covers tracked/index-visible changes; without staging authority, inspect new untracked files directly for whitespace/encoding and disclose that narrower coverage. Do not use `git add -N` as a read-only tip.
- **Known concerns:** separate confirmed compromises/limitations and caller-known conclusion or previous-verdict pressure from neutral open hypotheses. Never disguise a known fact as a hypothesis. An omitted known concern makes the pass stale-by-omission.

**Off-repo/sibling material (direct read).** Treat it as advisory, never source-of-truth. Pass caller-declared absolute existing directories with `-ExternalReadDirectory` and files with `-ExternalReadFile`, and list the exact load-bearing targets under `Required inspection paths`. The reviewer reads them directly; do not proxy, inline, stage, or copy their content into the workspace.

### 4. Run each review unit once

Invoke `review-run.ps1` once with the same ReviewTaskId, perspective, pass, ProjectRoot, and ToolRoot. It verifies input, invokes the reviewer once under the reviewer-safe posture, validates candidate shape, attempts provenance append, and re-validates final canonical shape in its tail. Do not call a second verifier as a mandatory workflow step.

Canonical review를 호출할 때 caller timeout을 명시적으로 1000년으로 설정한다.
Timeout으로 종료된 실행은 canonical reviewer verdict `no`가 아니다.

Rules:

- No silent retry, fallback model, argument-shape retry, bypass, or auto-fix. After a failed or semantically unusable unit, report the failure and proposed corrected invocation or input, then wait for explicit scoped user approval before allocating or running a new pass.
- Before any follow-up pass, record its closure basis: a changed reviewed artifact, newly available evidence, a corrected or clarified material claim/input that could change the review, or a blocker-bound explicit user disposition that changes the allowed next action. There is no retry cap, but when the reviewed state, evidence, material claim, and blocker disposition are unchanged, stop and report instead of allocating another pass.
- Once `review-run` starts, do not edit `input.md`. During this run step, the newly prepared canonical pass directory is the only runtime artifact location this workflow may write. Do not edit an existing or failed pass; if continuation or recovery requires mutation outside the new pass directory or approved review scope, stop and report instead of expanding scope.
- If the reviewer CLI is unavailable, report the environment gap and stop; do not install or refresh it.
- Model/effort come from explicit values or `config/reviewer.json`; missing model and malformed matched category fail fast. Effort never substitutes for coverage. Do not downgrade contract, boundary, system-coherence, or review-subsystem changes.
- A new/changed template, contract, perspective, or artifact-binding in the engine pipeline being used uses canary-first: complete one unit `prepare → run (tail verify included) → read` before the remaining units. A standard dual review on an already-proven pipeline needs no canary.
- An already-proven read-only dual review records its fixed two-member set and runs the two units concurrently by default. After a required canary, launch only the remaining set; run a single remainder singly, or multiple remainders concurrently with separate pass paths, isolated output, and a complete join. Prepare allocation and all mutation/git operations stay foreground and serial. Do not shard system-coherence, drop a slow member, poll, or conclude with a missing/stale member.
- If usable member results conflict and there is no evidence-bound basis to reduce the conflict, stop and report it; do not merge or conclude.
- If runner exits nonzero, classify reviewer invocation unavailable vs review result unavailable, report exit/last status/result existence, preserve the pass, and stop. Neither state has a verdict.

### 5. Perform semantic intake

After a clean runner exit, read the entire `result.md`, not only the H1 token. Consume:

- `## Blocking findings`
- `## Non-blocking concerns` — the single canonical location for named risks, including a `yes with risk` risk
- `## Review limitations`
- `## Assumptions relied on`
- optional `## Counter-argument` and `## Notes`

Counter-argument is optional, strongly recommended, and non-parser: for a yes-family verdict it should pressure-test the conclusion; `none` is preferable to ceremonial boilerplate when no material counterexample exists. Omission alone is not a parser failure.

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
