---
name: ai-harness-review
description: Run an ai-harness-toolset review on the user's current in-progress work. Trigger this skill on natural-language Korean or English intents that ask for a Codex / 코덱스 review of the current work, optionally preceded by a caller self-review. Examples that should trigger this skill — "현재 진행한 작업 코덱스 리뷰 진행해", "지금까지 한 작업 리뷰해 줘", "코덱스로 리뷰 돌려", "현재 구현된 서버의 소켓 라이브러리를 니가 직접 리뷰하고, 그후에 코덱스 리뷰로 한번 더 리뷰 후 최종 결론 도출해", "review what I just did with codex", "self-review then codex review and give the final verdict". Do NOT trigger on `/review`, `/security-review`, or any non-ai-harness review. Do not require the user to provide review CLI arguments — derive them from the current work.
---

# ai-harness-review

This skill drives the canonical `prepare → author → run → semantic intake` flow. One review record is `<ProjectRoot>/log/review/<review-task-id>/<perspective>/pass-NN/{input.md,result.md}`. A `review unit` means one `(perspective, pass-NN)` pair; each unit is write-once and permits exactly one reviewer invocation. A dual-perspective review therefore has two units, not one invocation shared across both.

Canonical dual-perspective coverage consists of two focused units: `local-correctness` and `system-coherence`. If either perspective is intentionally omitted or reduced, report `coverage-limited` with the omitted or reduced perspective and rationale. If no reviewable change exists, issue a caller-side `no-reviewable-change` report, not a verdict.

The calling agent performs the workflow. The user does not supply CLI arguments.

## Supported intents

1. **Reviewer-only (Mode A).** Review the current work; skip caller self-review.
2. **Caller self-review + reviewer (Mode B).** Review the named subsystem yourself, carry your findings into the packet, then merge only two usable judgments: `no` if either is `no`, otherwise `yes with risk` if either is that value, and `yes` only if both are `yes`. If reviewer judgment is unavailable, issue no merged verdict.

Review style and target scope are independent. Follow an explicit mixed request.

## Required workflow

### 0. Preserve context and resolve roots

- Inspect `git status --porcelain=v1` and `git diff`. Do not restart, rebase, switch, stash, reset, stage, or edit source merely to run review.
- `<ProjectRoot>` is the inspected repo. Resolve `<ToolRoot>` in order: explicit argument → `AI_HARNESS_TOOL_ROOT` → `%USERPROFILE%\ai-harness-toolset\current` → source-repo dogfooding → stop. Do not auto-install.
- When the target changes review machinery (runner/verifier/skill/templates/config or its contract), use the global stable ToolRoot or a pre-change independent checkout. Never use the in-development runner as its own review engine; if the stable engine fails, stop without fallback.

### 1. Bind the target accurately

**Mode A:** use the tracked changed set, excluding `log/`, generated artifacts, `.gitignore`-only noise, and genuinely unrelated edits. Untracked files are included only when user intent clearly covers them. If no reviewable change exists, report that and stop.

**Mode B:** resolve the named subsystem from `git ls-files`, regardless of dirty state. Prefer a directory match, then filename match; exclude tests/fixtures only when the request does not cover them. Current diff is context and must not redefine the named subsystem.

Cross-check the chosen files against status/diff. Disclose every deliberate omission under `## Known concerns`. Do not shrink scope for cost, latency, or an easier verdict. Ask at most one clarification only if the named subsystem does not resolve, spans unrelated trees, or Mode A/B intent is genuinely ambiguous.

Use repo-relative forward-slash paths and never list `log/` runtime artifacts as target files.

### 2. Allocate one write-once unit

Choose a task-stable `<review-task-id>` and explicit viewpoint `<perspective>`. Invoke once:

```powershell
<ToolRoot>/scripts/review-prepare.ps1 `
  -ReviewTaskId <id> -Perspective <viewpoint> [-Pass <pass-NN>] `
  -Stage <stage> -Purpose <line> -ProjectRoot <ProjectRoot> -ToolRoot <ToolRoot>
```

Prepare creates an empty `input.md`. Author it in the next step. If the pass already exists or an earlier pass is wrong/stale, allocate the next pass under the same task/perspective; never repair an old pass in place.

### 3. Author `input.md`

Use `<ToolRoot>/templates/review-input.md` as the writing reference. The input verifier requires these five H2 bodies to be non-empty: `Context`, `Required inspection paths`, `Review questions`, `Constraints`, and `Final verdict`. The last body retains the literal `yes / no / yes with risk` required by the existing input gate. The runner preamble—not this packet—owns the reviewer output runtime instruction.

Fill the compact informational positions when relevant:

- **Stage / Purpose / Review perspective / Target files:** identify this unit and exact artifact boundary. Do not merge planning approval with implementation corrected-state acceptance.
- **Claim provenance / freshness:** before quoting a load-bearing prior or external record, open its original path and section and confirm the exact text. Recalculate mutable counts against current state immediately before authoring; when either check is unavailable, mark the claim unverified.
- **Artifact persistence:** require `Constraints` to tell the reviewer to state persistence in finding prose when it affects severity or closure. Transience alone does not make a finding non-blocking, and a committed temporary artifact remains a real review target while it exists. Do not add a verdict, H2, parser field, or tag for this.
- **Task-grade adjudication:** use a user-supplied task-grade table only when it was actually provided; invent no default. After results, do not lower its threshold or automatically reclassify a blocking finding as non-blocking. A false-positive dismissal requires evidence and an explicit user decision.
- **Validation evidence:** cite a reviewer-readable Markdown bundle under `log/evidence/**` when making execution claims, otherwise say N/A. Evidence is supporting material, not re-execution, a truth oracle, freshness binding, or source-of-truth. The reviewer reads it by default; broad build/test reproduction requires explicit authorization with the exact command, cwd, expected writes, allowed output path, dependencies, timeout, interpretation boundary, and sandbox-failure reporting. Non-reproduction is a limitation, not automatically target risk. Validation scope is proportional to change class; script/runtime/parser/test/install changes normally require the full suite, while docs/wording may use targeted checks. Disclose what ran, what did not, why, and residual risk. `git diff --check` covers tracked/index-visible changes; without staging authority, inspect new untracked files directly for whitespace/encoding and disclose that narrower coverage. Do not use `git add -N` as a read-only tip.
- **Known concerns:** separate confirmed compromises/limitations from neutral open hypotheses. Never disguise a known fact as a hypothesis. An omitted known concern makes the pass stale-by-omission.
- **Framing self-check:** record remaining conclusion pressure, previous-verdict/closeout pressure, and wording neutralization. Write review questions open-endedly and ask the reviewer to surface input tilt without turning that tilt into a verdict.
- **Reference sweep:** for rename/move/delete/identifier/structure/wording reconciliation, record the searched patterns/paths and four classes: path references, bare tokens/IDs, folder-as-bucket wording, and semantic phrasing. Deletions require case/variant/bare-section checks.

Before stating a regex/parser/script behavior as fact, run a narrow reproducible check or disclose it as unverified.

**Off-repo/sibling material (B2 hold).** Treat it as advisory, never source-of-truth. The read-only reviewer can often access additional sibling and `log/` paths: attempt the exact path read first and report the actual outcome/error rather than assuming denial. Because the current runner has no explicit external-root transport, also inline the verbatim body of any load-bearing off-repo material inside `Context` so a path failure cannot change the evidence base. Keep this fallback until the separately gated external-path integration lands.

### 4. Run each review unit once

Invoke `review-run.ps1` once with the same task, perspective, pass, ProjectRoot, and ToolRoot. It verifies input, invokes the reviewer once under the reviewer-safe posture, validates candidate shape, attempts provenance append, and re-validates final canonical shape in its tail. Do not call a second verifier as a mandatory workflow step.

Rules:

- No silent retry, fallback model, argument-shape retry, bypass, or auto-fix. After a failed or semantically unusable unit, report the failure and proposed corrected invocation or input, then wait for explicit scoped user approval before allocating or running a new pass.
- Once `review-run` starts, do not edit `input.md`. During this run step, the newly prepared canonical pass directory is the only runtime artifact location this workflow may write. Do not edit an existing or failed pass; if continuation or recovery requires mutation outside the new pass directory or approved review scope, stop and report instead of expanding scope.
- If the reviewer CLI is unavailable, report the environment gap and stop; do not install or refresh it.
- Model/effort come from explicit values or `config/reviewer.json`; missing model and malformed matched category fail fast. Effort never substitutes for coverage. Do not downgrade contract, boundary, system-coherence, or review-subsystem changes.
- A new/changed template, contract, perspective, or artifact-binding uses canary-first: complete one unit `prepare → run (tail verify included) → read` before the remaining units. A standard dual review on an already-proven pipeline needs no canary.
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

Shape validity is not semantic usability. A `no` with no blocking finding, or `yes with risk` without named risk substance under Non-blocking concerns, is review result unavailable: preserve the actual provenance, consume no verdict, and do not create a fourth verdict. Treat limitation/assumption/risk-bearing content as part of next-action judgment.

Read runner provenance as machine run facts, not reviewer judgment. For review-system self-modification, confirm stable engine identity, reviewer-safe posture, applied effort, and any anomaly. Do not reproduce normal stdout/provenance as a long ceremonial report.

If source/docs/templates/tests change after a unit, that unit is stale. If a prior claim, citation, count, framing, scope, or verdict intake proves wrong, explicitly retract what was wrong, why, and the current state.

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
- `no`: classify blockers as inside/outside approved scope. Propose in-scope correction + corrected-state re-review; ask separately for out-of-scope work.
- `yes with risk`: surface named risks from Non-blocking concerns and require explicit acceptance or a re-review closure path. It is not automatic `yes`.

Never let a verdict authorize commit, push, publish, merge, release, deployment, adoption, global/user-file mutation, or stable-install refresh. This skill never performs those actions.

## Failure and non-goals

- Do not edit target code merely to obtain a favorable verdict, average multiple cycles, impose a retry cap, or weaken a user-supplied finding threshold after results.
- Do not modify user-global instruction/skill/config homes or git config, and do not clean canonical review/evidence artifacts.
- Do not promote runtime evidence or off-repo planning material to source authority.
- Do not invent a result, pass, model/version, validation claim, or reviewer judgment.
