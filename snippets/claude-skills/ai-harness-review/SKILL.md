---
name: ai-harness-review
description: Run an ai-harness-toolset review on the user's current in-progress work. Trigger this skill on natural-language Korean or English intents that ask for a Codex / 코덱스 review of the current work, optionally preceded by a Claude self-review. Examples that should trigger this skill — "현재 진행한 작업 코덱스 리뷰 진행해", "지금까지 한 작업 리뷰해 줘", "코덱스로 리뷰 돌려", "현재 구현된 서버의 소켓 라이브러리를 니가 직접 리뷰하고, 그후에 코덱스 리뷰로 한번 더 리뷰 후 최종 결론 도출해", "review what I just did with codex", "self-review then codex review and give the final verdict". Do NOT trigger on `/review`, `/security-review`, or any non-ai-harness review. Do not require the user to provide review CLI arguments — derive them from the current work.
---

# ai-harness-review

This skill drives the ai-harness-toolset canonical review flow. The canonical review artifact layout is one pass directory per Codex attempt, grouped under one task directory per review task:

```text
<ProjectRoot>/log/review/<review-task-id>/
  pass-01/
    input.md   AI-authored from <ToolRoot>/templates/review-input.md
    result.md  reviewer-adapter body + runner-appended provenance block (dual-authored)
  pass-02/    (only if the corrective loop adds another attempt)
    input.md
    result.md
```

- `<review-task-id>` identifies one Claude Code `/goal` task or one review gate. It is **not** a Claude Code chat / session id. A single session may contain multiple `<review-task-id>` directories for different `/goal` tasks.
- `pass-NN` (zero-padded two-digit) identifies one Codex review attempt inside the corrective loop for that task. The first attempt is `pass-01`; the next is `pass-02`; and so on.
- Each `pass-NN/` is write-once. If the input or result is wrong or stale, allocate a new `pass-NN/` under the same `<review-task-id>/`; do not edit the old pass to close the review. If the underlying review task changes (different `/goal` or different gate), use a new `<review-task-id>/`.

The scripts emit the canonical two-level `<review-task-id>/pass-NN/` layout directly; the only on-disk record per pass is the `input.md` + `result.md` pair.

Adoption path: copy this file to `<ProjectRoot>/.claude/skills/ai-harness-review/SKILL.md` (project-local, recommended) or `%USERPROFILE%\.claude\skills\ai-harness-review\SKILL.md` (user-global, opt-in). No file is auto-installed.

## Two supported intents

1. **Codex review only.** The user wants a Codex review of the current work with no subsystem named.
   - Examples: "현재 진행한 작업 코덱스 리뷰 진행해", "코덱스 리뷰 돌려", "review what I just did with codex".
   - Use Mode A target selection. Skip the Claude self-review.

2. **Claude self-review, then Codex review, then a single merged final verdict.** The user names a subsystem and wants you to read it yourself first, then run Codex, then merge into one verdict.
   - Examples: "현재 구현된 서버의 소켓 라이브러리를 니가 직접 리뷰하고, 그후에 코덱스 리뷰로 한번 더 리뷰 후 최종 결론 도출해", "self-review then codex review and give the final verdict".
   - Use Mode B target selection. The subsystem is reviewed even if the working tree has no current changes. Carry your own findings into the `## Context` and `## Review questions` sections of `input.md`. Merge both readings into one final verdict (`no` if either is `no`; `yes with risk` if either is `yes with risk`; only `yes` if both are `yes`).

Two dimensions (review style / target scope) are independent in principle. The canonical pairings above cover the usual case. If the user clearly mixes them, follow what they said.

## Required behavior

You — Claude Code — perform every step below. The user does not type CLI arguments.

### 0. Preserve current context

Do not abandon the conversation state. Do not restart, rebase, switch branch, stash, or reset. Do not edit source files just to make the review run. The review reads what is already on disk.

### 1. Inspect repo state and resolve roots

- Run `git status --porcelain=v1` and `git diff` to see what is changed and untracked.
- `<ProjectRoot>` is the directory `git status` was run in.
- Resolve `<ToolRoot>` in this channel order: explicit `-ToolRoot` argument → `AI_HARNESS_TOOL_ROOT` env var → global stable install `%USERPROFILE%\.claude\ai-harness-toolset\current` (absent skips to the next channel; present but incomplete fails fast) → `<ProjectRoot>/.ai-harness/` fallback → explicit error. If no channel resolves, stop and tell the user the toolset is not available; do not auto-install.
- **Review-engine independence when the work under review modifies the review system itself.** If the target files include the review machinery — `scripts/review-run.ps1`, `scripts/review-verify.ps1`, `scripts/review-input-verify.ps1`, this `SKILL.md`, the reviewer policy / contract / status docs, or `config/reviewer.json` — do **not** run the Codex review through the in-development, uncommitted repo-local runner you are changing (`-ToolRoot <repo>`); that makes the engine review its own unverified self-modification (a self-review circularity). Resolve `<ToolRoot>` to the global stable install (`%USERPROFILE%\.claude\ai-harness-toolset\current`) or a pre-change independent checkout, and run the review there. Use the in-dev runner only for feature smoke / run-fact evidence, never as the review engine. If the global stable runner fails, stop and report — do not fall back to the in-dev runner.

### 2. Determine target files

Pick the smallest concrete file set the review should bind to.

**Mode A — current-work review.** Use when the user said "review the work I just did" with no subsystem named.

- Target files = tracked changed file set from `git status --porcelain=v1` (modified / added / renamed / copied), excluding `log/`, generated artifacts, `.gitignore`-only changes, unrelated noise.
- Untracked files are not auto-included. If the user clearly intends them, include them explicitly.
- If the changed set is empty, stop and tell the user there is nothing to review. Do not silently fall back to Mode B.

**Mode B — explicit subsystem review.** Use when the user named a subsystem, module, library, or path — even with no current changes.

- Target files = tracked files matching the named subsystem, regardless of dirty state.
  - Try a directory match first, then a filename-substring match in likely roots.
  - Enumerate with `git ls-files`; exclude untracked / ignored.
  - Exclude tests, fixtures, generated files, unrelated noise unless the user explicitly asked for them.
- Current diff is supplementary context. Surface it in `## Context`, but do not let it shrink or expand the subsystem set.

**Single clarification rule.** Ask the user at most once, and only when (a) Mode B scope is too broad (>~20 files or unrelated trees), (b) Mode B name does not resolve, or (c) intent is genuinely ambiguous between Mode A and Mode B. After one clarification, proceed.

Common rules: use repo-relative forward-slash paths. Always exclude `log/`. The chosen target set is what `input.md`'s `## Target files` section will list and what the reviewer is asked to read.

Before finalizing the target set, verify it against the actual changed file set per the target-file accuracy rule: cross-check `git status --porcelain=v1` and `git diff` against your Mode A / Mode B selection. Do not silently drop a changed file or silently include an unrelated file. If you deliberately omit a changed file from the review (for example, an obviously unrelated incidental edit), disclose that decision under `## Known concerns` so the reviewer sees the omission rather than inferring it. The reviewer reads only what `## Target files` lists; an inaccurate target set produces a verdict on the wrong surface.

### 3. Allocate the pass directory

Pick a `<review-task-id>` for this work: a stable string identifying the `/goal` task or review gate (for example, `topology-simplification-2026-05-16`). Reuse the same `<review-task-id>` for every pass of the same task; pick a new one only when the task itself changes. Determine the `pass-NN` for this attempt: `pass-01` for the first Codex attempt of this task; `pass-02`, `pass-03`, ... for subsequent corrective-loop attempts. You may pass `-Pass <pass-NN>` explicitly, or omit it to let `review-prepare.ps1` auto-allocate the next pass under the same task directory.

Invoke `<ToolRoot>/scripts/review-prepare.ps1 -ReviewTaskId <id> [-Pass <pass-NN>] -Stage <stage> -Purpose <line>` once. The script creates the canonical pass directory `<ProjectRoot>/log/review/<review-task-id>/pass-NN/` and seeds `input.md` from `<ToolRoot>/templates/review-input.md`.

Hard rules for step 3:

- The seeded `input.md` is the template body verbatim, not the actual review request. You will overwrite it in step 4. Do not invoke Codex yet.
- Each `<review-task-id>/pass-NN/` is write-once. If a pass already exists for the chosen `pass-NN`, the script refuses; allocate a new `pass-NN` under the same `<review-task-id>`.

### 4. Author the pass `input.md`

Open `<ProjectRoot>/log/review/<review-task-id>/pass-NN/input.md` (the file just seeded by step 3) and overwrite its body with the actual review request.

The file must contain these required H2 headings (exact text), each with non-empty body:

- `## Context`
- `## Required inspection paths`
- `## Review questions`
- `## Constraints`
- `## Final verdict` — body must contain the literal string `yes / no / yes with risk`.

Add these informational headings as well (recommended):

- `## Stage` — one of `design`, `implementation`, `test`, `review`, `release`. Default `implementation` for ordinary code changes.
- `## Purpose` — one short line in the user's working language. Name the artifact when possible.
- `## Target files` — bulleted list of repo-relative forward-slash paths chosen in step 2. Source-managed files only; do not list `log/` runtime artifacts here.
- `## Validation evidence` — when this round makes validation execution claims (e.g., Pester pass count, `verify-ps1` PASS, `git diff --check` clean), reference the Markdown evidence file path under `<ProjectRoot>/log/evidence/<scope>/<case>/validation-evidence.md` (or equivalent `.md` path under `log/evidence/`) so the reviewer can read its body in the read-only sandbox. If this round makes no such claims, put a short literal note such as `N/A — no validation execution claims in this round.` The evidence file is reviewer-readable runtime supporting material — not command re-execution, not deterministic truth oracle, not freshness binding, not source-of-truth. `scripts/review-input-verify.ps1` does not currently lint the presence or shape of this section; populating it is operator convention. The reviewer's default is to *read* this evidence, not to re-run the operator's validation / build / test commands — reviewer reproduction is opt-in, not an opportunistic default just because the read-only sandbox can execute commands. If you want the reviewer to actually re-run a command, authorize it explicitly in the input and state at minimum the exact command, working directory, expected read/write behavior, allowed temp/output path, dependency assumptions, timeout expectation, interpretation boundary, and how to report a sandbox limitation. Without that authorization the reviewer inspects local evidence and reports any non-reproduction as a `## Review limitations` entry, not as target risk (escalation to target risk needs independent grounds such as missing or stale local evidence, scope mismatch, a static contradiction, or an explicit high-risk gap). Target-project validation such as Visual Studio / MSBuild / C++ / CMake / Unity / Unreal / network restore / generated-output builds / repo-external SDKs is not a default reproduction target even when the read-only sandbox appears capable of running it. Validation scope is by change class, not full-suite-for-everything: a docs-only or planning round usually needs only a targeted check (`git diff --check`, the review-system Pester subset), while a script / runtime / parser-gate / test-infrastructure / install-path change is where the full `Invoke-Pester -Path .\tests` suite is expected. If you did not run the full suite, state the change class, the validation you ran, the validation you did not run, the reason, and any residual risk — not running it is fine when disclosed, but silently implying full coverage is not. Note that `git diff --check` covers only tracked / staged files, so a new / untracked file needs `git add -N <path>` (or staging) before the check actually covers it. The reviewer reads this evidence and the scope rationale; the reviewer does not run the full suite itself — that is the operator's job, and reviewer reproduction stays the separate opt-in described above.
- `## Known concerns` — disclose any compromise / convention deviation / skipped alternative / baseline failure / validation limitation / operator assumption that you (the operator) already know about before calling Codex. Recommended sub-categories: convention deviation, skipped alternatives, validation limitations, baseline failures, direct verification not performed, operator assumptions. If you know something might affect the reviewer's judgment and you don't write it here, the resulting verdict can be invalidated ex-post by stale-by-omission — the verdict becomes unfit for commit/push judgment until a new pass with the omitted concerns disclosed is run. If you genuinely have no such concerns this round, write a short literal note such as `N/A — no known concerns disclosed.` `scripts/review-input-verify.ps1` does not currently lint the presence or shape of this section either. This section holds two kinds of items. **(1) Confirmed disclosures** — things you actually know (the sub-categories above: a compromise you made, a real baseline failure, a validation limitation you are aware of); state them as fact, and stale-by-omission applies in full. **(2) Open concerns / hypotheses to verify** — things you suspect but have not confirmed; phrase these neutrally as `verify whether…` / `check whether…` rather than asserting them as settled defects, so the reviewer evaluates them independently instead of confirming a presumed finding (parallel to the `## Review questions` neutral-phrasing convention). **Guard:** a genuine known compromise / limitation must be written as a confirmed disclosure and must not be softened or disguised as a hypothesis — hypothesis phrasing is for unconfirmed suspicions only, never a way to escape the stale-by-omission disclosure duty.

Author the body content yourself from conversation context, diff, and any active task or plan in this session. `scripts/review-input-verify.ps1` rejects unfilled `{{AI_TO_FILL_*}}` active placeholders (regex `\{\{AI_TO_FILL_[A-Za-z0-9_]+\}\}`) and the forbidden-phrase substrings declared in its `$forbidden` array. Active review-input placeholders use the `AI_TO_FILL_` prefix; generic double-brace forms such as `{{TOKEN}}` or `{{example}}` are documentation literals and are not rejected. Do not invent runtime details (no fake commit hashes, no fake reviewer model names).

Write `## Review questions` in **neutral phrasing** — open-ended (`How many X were migrated, and is that the intended scope?`) rather than confirmation-seeking (`Are exactly N X migrated?`). Reviewers naturally drift toward `yes` when prompts are leading. Include, as the last recommended question, a reviewer self-audit on framing — e.g., `Does the input above nudge the reviewer toward a particular verdict? If so, surface the tilt in ## Notes.` The reviewer's framing-tilt answer goes into `## Notes`, not into the verdict itself.

When the review input references off-repo or sibling material (for example, a planning anchor under `polishing/`, a handoff doc, a snapshot or manifest, or user-provided text), do not promote it to source-of-truth. Reference it as advisory / planning / user-provided context and disclose its role explicitly in `## Context`. The reviewer's read-only sandbox can often read repo-sibling and `log/` paths (Codex CLI v0.130.0 on Windows has been observed to do so for `polishing/` and `log/` subtrees); do not assume it cannot. Attempt the read first and record the exact path and error only if the read actually fails. Independently of sandbox capability, when the off-repo material is itself review-relevant — for example, the body of an anchor doc that the verdict depends on — inline its body verbatim inside `## Context` (or a dedicated subsection such as `## Anchor draft body`) so the verdict does not depend on the sandbox path read. Citing only the off-repo path while leaving its body unreadable inside the sandbox produces verdicts on the wrong base when the sandbox read actually fails.

When `input.md` cross-references a prior review record (another `<review-task-id>/pass-NN/result.md`, another batch's polishing log, or a section/line in a planning anchor), verify the citation provenance directly before quoting — open the cited path, confirm the exact text and section, and quote from that source rather than transitively through an intermediate planning document. Likewise, when stating counts in `## Context` or `## Known concerns` (file count, line count, pass count, recurrence count, etc.), run a mechanical check (Glob, grep, `wc -l`, or equivalent) immediately before writing the number — do not carry a count from an earlier document if the underlying state may have changed since that document was written. These two disciplines mitigate operator narrow-scope over-confidence; when a wrong citation or wrong count is discovered after a review has run, apply the retraction protocol — surface what was wrong, why, and the current state — rather than silently overwriting the prior claim.

The reviewer is also instructed (per the H1 reviewer-mode preamble in `scripts/review-run.ps1`) to articulate the strongest case **against** its own conclusion in `## Counter-argument` before issuing the final verdict, especially when the verdict is `yes` or `yes with risk` — this is the dedicated pressure-test surface (the Counter-argument convention). Treat that section as a substantive pressure-test surface when you read the result — it is not a courtesy aside. If deliberate pressure-test finds no material counter-argument, the reviewer leaves a short literal (`none` or `no material counter-argument identified`) rather than ceremonial boilerplate. `## Counter-argument` is **optional and strongly-recommended (NOT parser-required)** — `scripts/review-verify.ps1 -RequireResult` still enforces only the four V2 H2s, and omission is not a parser FAIL. `## Notes` remains available as the freeform reviewer-narrative bucket (framing-tilt self-audit, evidence pointers, follow-up inspection, general observations). Heavier mechanisms beyond this convention — a devil's-advocate pre-pass or multi-reviewer consensus — remain idea-only (not implementation backlog).

Generic double-brace forms such as `{{TOKEN}}`, `{{REAL}}`, or `{{example}}` can be cited directly in `input.md` prose (including inside inline backticks) as documentation literals — they are not rejected by the verifier, because the input-verify regex `\{\{AI_TO_FILL_[A-Za-z0-9_]+\}\}` only matches the active `AI_TO_FILL_` namespace. When you need to refer to a specific active placeholder by name (e.g., `AI_TO_FILL_VALIDATION_EVIDENCE`), use the brace-less identifier form so the verifier does not see an unfilled active placeholder in your prose. The earlier wildcard and backslash-escape workaround conventions are no longer required.

Before stating a **mechanical behavior claim** in `input.md` — a claim about how a specific regex, parser, verifier, or script actually behaves on specific input — verify it with a **minimal reproducible check** rather than relying on reasoning alone. A minimal reproducible check is narrow: a tiny regex match against a literal string, a small parser input, a small verifier fixture, an isolated string / character inspection in any available scripting environment, a one-line shell exit-code check. It is not the full test suite — it is a check just narrow enough to reduce the chance that prose-stated mechanics are wrong. The same discipline applies when about to commit such a claim into any template, snippet, or contract surface; reasoning-only mechanical claims have repeatedly led to corrective loops in this toolset, and the check is cheap while the corrective is expensive. If the claim cannot be verified in the current environment, disclose it as unverified under `## Known concerns` so the reviewer can decide how to treat it.

When this round is a **wording reconciliation, terminology cleanup, or framing cleanup** (meaning-preserving edits that touch sibling sections), run a relevant anti-pattern grep sweep across all candidate files **before the first re-review**, rather than fixing one section and re-reviewing. Such cleanups tend to leave sibling residuals that surface one-per-pass and turn a single edit into a re-review cascade; a full grep sweep for the terms being changed (the old phrasing, the deprecated default, the framing being removed) collapses that cascade into one pass. This is operator judgment discipline, not an automated gate.

Tell the reviewer in `input.md` (e.g., as a constraint or in the `## Final verdict` instruction) that `result.md` must contain these four H2 headings, each exactly once: `## Blocking findings`, `## Non-blocking concerns`, `## Review limitations`, `## Assumptions relied on`. If a section has no substance, the reviewer should still emit the heading with `none` as the body. `scripts/review-verify.ps1 -RequireResult` rejects the pass when any of the four is missing or duplicated (mechanical presence/count check; no sub-shape lint). Without this instruction in `input.md`, the reviewer may omit one of the sections and force a corrective pass.

Also tell the reviewer in `input.md` (alongside the four-H2 instruction or in the `## Final verdict` body) that when the verdict is `yes` or `yes with risk`, `result.md` should include a `## Counter-argument` H2 articulating the strongest case AGAINST the verdict. This section is **optional and strongly-recommended; non-parser** — `scripts/review-verify.ps1 -RequireResult` does not check for it, omission is not a parser FAIL, and the body should be the short literal `none` or `no material counter-argument identified` when deliberate pressure-test finds nothing material rather than ceremonial boilerplate ("the alternative interpretation is X, but I dismiss it because Y" with no substance). When the verdict is `no`, `## Counter-argument` may be omitted since `## Blocking findings` is already the case-against-yes articulation. The full convention covers the substance contract, the position relative to `## Notes`, and boilerplate-degeneration mitigation.

If you ran a Claude self-review (intent 2), summarize your own findings inside `## Context` and put your unresolved doubts into `## Review questions` so Codex's pass builds on your reading.

### 5. Run the reviewer exactly once

Invoke `<ToolRoot>/scripts/review-run.ps1 -ReviewTaskId <id> -Pass <pass-NN>` once. It calls `scripts/review-input-verify.ps1` against the `input.md` you wrote, invokes Codex CLI once (`--ask-for-approval never`, `--sandbox read-only`, `--output-last-message <review-task-id>/pass-NN/result.md`), validates the `## Verdict` shape, and exits.

`review-run.ps1` resolves the reviewer **model** and **reasoning effort** by precedence: model = explicit `-Model` > `config/reviewer.json` `model` > **fail-fast** (there is no built-in model default or fallback; an absent or empty model stops the run before Codex is invoked — the config is the source of truth, and no concrete model version is baked into a script as a default or fallback); effort = explicit `-Effort` > `config/reviewer.json` `reasoningEffort` > the policy safe-default `xhigh`. Leave effort at the configured / safe-default value for the normal case. Pass an explicit `-Effort` downgrade **only** for a packet that is clearly simple local-correctness (a small, mechanical, unambiguous surface); do **not** downgrade for system-coherence, contract, boundary, or otherwise ambiguous reviews. `-Effort` is a cost / latency control, not a coverage-reduction lever — a lower effort never narrows what the reviewer must cover and never substitutes for a weaker packet (effort ⟂ coverage).

Hard rules for step 5:

- One invocation per user request. No retry on failure. No fallback model. No auto-fix loop.
- Run `review-run.ps1` in the foreground and wait for completion. Do not spawn it as detached or background work, and do not run the review concurrently with other work. A timeout or budget is only an operating allowance for a foreground attempt; it is not a correctness guarantee, and review validity is judged by complete run artifacts, valid result binding, and the step-6 verification, not by how the run was launched.
- Do not bypass `scripts/review-input-verify.ps1`.
- Do not edit `input.md` once `review-run.ps1` has started. If the input needs correction, allocate a new pass for the same `<review-task-id>` (go back to step 3 with a new `pass-NN`).

If `review-run.ps1` exits non-zero, stop. Report the exit code and the last status line printed. Report whether `result.md` exists in the pass directory. Do not silently retry, even by adjusting argument shape — surface a corrected proposed invocation and wait for explicit go-ahead.

The stop/report-vs-self-correct boundary applies here too: if running `review-run.ps1` would require touching anything outside the review's approved scope — for example user-global files under `%USERPROFILE%\.claude\` or `%USERPROFILE%\.codex\`, the channel 3 install payload under `%USERPROFILE%\.claude\ai-harness-toolset\current\`, the `<ProjectRoot>/log/` runtime tree beyond the prepared pass directory, or any repo-outside material — stop and report instead of silently expanding scope. The reviewer pass directory is the only runtime artifact you write to in this step.

### 6. Verify the canonical artifacts and confirm the verdict

After step 5 exits cleanly, invoke `<ToolRoot>/scripts/review-verify.ps1 -ReviewTaskId <id> -Pass <pass-NN> -RequireResult` once. This is the post-hoc canonical-artifact check; it does **not** invoke Codex. It re-validates `input.md` shape, the `## Verdict` shape inside `result.md`, and the presence (each exactly once) of the four required disclosure H2 headings in `result.md`: `## Blocking findings`, `## Non-blocking concerns`, `## Review limitations`, `## Assumptions relied on`. If it exits non-zero, stop and report the exit code and the last status line. Do not edit files in the pass directory to make it pass — allocate a new `pass-NN` under the same `<review-task-id>` with a corrected `input.md` (typically: re-emphasize the four required H2s to the reviewer).

After `review-verify.ps1` exits cleanly, read `log/review/<review-task-id>/pass-NN/result.md` as a **structured review artifact** — the verdict line is necessary but not sufficient for the next-action judgment, and you must read the disclosure sections alongside it:

- Confirm exactly one `## Verdict` heading exists.
- Confirm the first non-empty line after `## Verdict` (whitespace-trimmed) is exactly one of `yes`, `no`, `yes with risk` — lowercase, no qualifier, no inline form.
- Read the four V2 required disclosure H2 sections (each present exactly once, with `none` as the body when empty): `## Blocking findings`, `## Non-blocking concerns`, `## Review limitations`, `## Assumptions relied on`.
- Also read optional sections (`## Findings`, `## Risks`, `## Counter-argument`, `## Notes`) if present. The four required H2s are the mechanical-enforced disclosure positions; the optional sections are free-form reviewer narrative. `## Counter-argument` is the dedicated verdict pressure-test position (strongly-recommended for `yes` / `yes with risk` verdicts) — read its substance, and evaluate whether the body is substantive or ceremonial boilerplate. Recurring boilerplate or omission across many passes is escalation evidence input for a separate later batch decision (parser-required gate or heavier mechanism); a single boilerplate / omission case is not by itself a blocking finding. **Precedence rule**: when `## Blocking findings` and a free-form `## Findings` section disagree on whether something is blocking, `## Blocking findings` is the source of truth. If `result.md` passes the shape gate (`review-verify -RequireResult`) but the body discloses a limitation, assumption, or risk that affects commit fitness, surface it to the user — shape PASS is not an automatic commit-fitness guarantee.
- Also read the `## Reviewer run provenance` block if `review-run.ps1` appended one. This is a **runner-appended, machine-emitted run-fact block — NOT reviewer judgment and NOT parser-gated** (it does not affect `review-verify`'s `## Verdict` + four-H2 count; `review-verify` does not gate on it). It records the runtime provenance of *this* run — reviewer adapter kind, reviewer version (or `not-observed`), model / model-source, requested-effort / effort-source / applied-effort, reviewer-safe posture, and engine identity (tool-root / project-root / tool-root-source) — sourced from runtime / config / active reviewer adapter / reviewer self-report, **never `input.md` caller declaration**. Surface its values in step 7's **reviewer guard status**. The two authorship layers are distinct: the reviewer-adapter **verdict/disclosure body** is the reviewer's judgment, while the runner-appended **provenance block** is machine run-fact (`docs/contracts/review/REVIEW_RESULT_CONTRACT.md` §3, result.md dual-authorship).

The verdict has a narrowed meaning — `yes` = no blocking finding (not commit/push approval); `no` = blocking finding exists (corrective needed); `yes with risk` = no blocking finding but the risks under `## Risks` (and any flagged limitations / assumptions) require explicit supervisor or user acceptance before commit / push. `yes with risk` is not the automatic equivalent of `yes` for the next step. The full verdict → next-action mapping is applied in step 7 (Report the final verdict); this step is the practical operator-side mirror of that mapping. When reporting back to the user, report the verdict verbatim plus the four disclosure sections so the user has the same surface the reviewer surfaced.

When the verdict depends on a mechanical behavior claim made in `input.md` (about a regex, parser, verifier, or script), expect the reviewer to have attempted a **minimal reproducible check** of that claim where feasible in the read-only sandbox (a tiny regex match against a literal string, a small parser input, a small verifier fixture, an isolated string / character inspection in any available scripting environment, a one-line shell exit-code check). If the result.md surfaces such a check under `## Notes` or `## Assumptions relied on`, treat the verdict as load-bearing on that point. If the reviewer recorded under `## Review limitations` that the check was infeasible in its sandbox, treat the prose claim as unverified and adjust your downstream judgment accordingly even if the verdict is `yes` or `yes with risk`. That minimal reproducible check is a narrow, reviewer-constructed inspection probe (a few seconds; not the full test suite or a build) — it is distinct from broad validation / build / test reproduction. The reviewer does not run the operator's validation / build / test commands by default merely because the read-only sandbox can execute commands; broad reproduction happens only when the input explicitly authorizes it (with the command, working directory, read/write behavior, allowed temp/output path, dependency assumptions, timeout, interpretation boundary, and how to report a sandbox limitation). When the reviewer could not or did not reproduce, that is a `## Review limitations` entry, not automatically target risk — it becomes a risk only on independent grounds such as missing or stale local evidence, scope mismatch, a static contradiction, or an explicit high-risk gap.

If, after the review closes, you discover that you (the operator) knew about a compromise or limitation before the run but omitted it from `## Known concerns`, treat the pass as stale-by-omission and allocate a new `pass-NN` with the omitted concerns disclosed. Do not edit the prior pass directory to backfill the omission.

If the verdict line is anything other than the three values, treat the run as failed and report it. Do not paraphrase or normalize the verdict into a different word.

### 7. Report the final verdict

End your response with a clearly labeled final verdict, exactly one of:

- `yes`
- `no`
- `yes with risk`

For intent 1 (Codex only), this is the verdict line from `result.md`.

For intent 2 (Claude self-review + Codex), produce a single merged final verdict:

- If either side is `no`, merged = `no`.
- If either side is `yes with risk`, merged = `yes with risk`. Carry the named risks forward.
- Only if both sides are `yes`, merged = `yes`.

Always include the operator final report fields below, kept visually distinct. These are the operator's human closeout report fields. This is a human report — **not** the on-disk `result.md` shape (the four parser-enforced disclosure H2s) and **not** something `scripts/review-verify.ps1` checks; emitting these fields is operator discipline, not a deterministic check. Keep these three axes distinct — do not collapse them into a single "pass-NN yes" token: invocation count, artifact pass count, and corrective loop count are different things.

**Final report schema fields:**

1. **Perspective coverage** — `dual-perspective coverage`, `coverage-limited review` (name the omitted / reduced perspective and rationale), or `no-reviewable-change report`.
2. **Invocation packaging** — `single-invocation dual-perspective packet`, `two focused invocations`, or other disclosed packaging shape.
3. **Invocation count** — how many times the reviewer was actually invoked. Not a quality guarantee; a different axis from fields 4 and 5.
4. **Artifact pass count** — the number of `artifact pass-NN` attempts on disk. If this workflow produced none, write `N/A — no artifact pass-NN` (do not invent one).
5. **Corrective loop count** — how many `corrective review loop` (corrected-state re-review) iterations ran. A different axis from invocation count and artifact pass count: a clean first attempt is one artifact pass with zero corrective loops; a single corrective loop may or may not coincide with a new artifact pass.
6. **Re-review status** — one of `not needed`, `needed`, `completed`, `stale due to mutation`, `not applicable`.
7. **Verdict / risk handling** — the verdict verbatim and how it is consumed (`yes with risk` is not the automatic equivalent of `yes`). Apply the verdict → next-action mapping:
   - `yes` — surface `## Non-blocking concerns` / `## Review limitations` / `## Assumptions relied on` to the user; commit / push / release / next batch are separate explicit user decisions, not automatic.
   - `no` — classify each `## Blocking findings` item as within or outside the user-approved scope. Propose a scoped corrective patch + corrected-state re-review for in-scope items; stop and request separate approval for out-of-scope items. Do not close the batch on `no` without concrete re-review evidence.
   - `yes with risk` — summarize the risks (`## Risks` plus any risk-bearing entries under `## Review limitations` / `## Assumptions relied on` / `## Non-blocking concerns`) and ask the user for explicit risk acceptance. Do not treat `yes with risk` as `yes`; do not commit / push before acceptance.
8. **Validation evidence** — the validation evidence used and its limitations. Report validation scope by change class: if you did not run the full `Invoke-Pester -Path .\tests` suite, state the change class, validation run, validation not run, reason not run, and residual risk. The reviewer inspects this evidence — it does not run the full suite for you.
9. **Final git status** — the final worktree state and changed files.
10. **Commit/push recommendation** — a next-action recommendation only; the verdict does not approve commit, push, publish, merge, release, deployment, upload, or adoption.

**Reviewer guard status** — surface the reviewer run provenance into this H2 report field, reporting each item with its observable source, without overstating. The values come from two equivalent sources: the **H1 run-facts `review-run.ps1` printed in step 5**, and **(P3) the persisted `## Reviewer run provenance` block inside `result.md`** (read in step 6) — the persisted block is the durable record that travels with the canonical artifact, so prefer it when present and fall back to the step-5 stdout otherwise. The block is a runner-appended **machine run-fact, not reviewer judgment and not parser-gated** (`review-verify.ps1` does not check it). This is **recommended whenever the runner emitted these run-facts / appended the block** (the normal case); it is optional for a trivial non-self-modification review, and **expected for a review-subsystem self-modification closeout** (engine identity + reviewer-safe posture + applied-effort), pairing with the review-engine independence rule (step 1). It is operator reporting discipline, not a `review-verify.ps1` gate. Carrying the run-fact into the H2 report does not make the report a copy of the runner's stdout or of the provenance block — it is the operator's report:

- **reviewer adapter kind** — the active reviewer adapter (`reviewer:` run-fact / provenance block; MVP allows codex only). A runtime-resolved fact, not a caller declaration.
- **reviewer version** — the adapter version observed at runtime (`reviewer-version:` run-fact / provenance block), or `not-observed` when the active adapter reported no parseable version. A runtime observation; never bake a concrete version into the report as a durable expectation — cite the runtime-resolved value (`config/reviewer.json` / vendor lifecycle are not pinned here).
- **reviewer execution guard** — `read-only` or `mutation-capable + disclosed`.
- **effort** — `requested-effort` / `effort-source` / `applied-effort`, from the `review-run.ps1` run-fact lines when present (Batch B emits these today; `applied-effort` is `not-observed` when the reviewer ran in-process).
- **model / model-source** — the runner resolves the model and emits `model:` + `model-source:` run-facts (Batch D2; `model-source` is the actual resolver branch, `explicit` / `config`, and a missing/empty model fails fast). Report from those run-facts. Never bake a concrete model version into the report — cite the runtime-resolved value the runner printed; `config/reviewer.json` is the source of truth.
- **reviewer-safe posture** — `--sandbox read-only` / `--ask-for-approval never` / `--ignore-user-config`; verified for the tested vectors (create / modify-tracked / modify-existing) only, not a blanket guarantee. The runner emits these as a `reviewer-safe-posture:` run-fact (Batch D2; posture flags only). Report from the run-fact, keeping the tested-vectors-only caveat — the run-fact is the posture flags, not a blanket guarantee.
- **review engine identity** — engine ToolRoot / ProjectRoot / tool-root-source. For review-subsystem self-modification the engine must be the global stable ToolRoot (the review-engine independence rule, step 1). The runner emits `tool-root:` / `project-root:` / `tool-root-source:` run-facts (Batch D2); report from those (and/or your own invocation knowledge) as operator-debugging facts, not source-of-truth claims.

**Run / process reporting** (kept visually distinct):

- **Entry-point error** — none, or the exit code plus the last status line. State whether a pass directory was allocated and whether `result.md` exists for it.
- **Retry decision** — none, or what was retried, why, and whether explicit scoped re-approval was sought.
- **Review task** — `<review-task-id>` for this work.
- **Final pass** — the final `pass-NN` (e.g., `pass-01`, `pass-03`) and the canonical path `log/review/<review-task-id>/pass-NN/result.md`.
- **Final reviewer result** — the Codex verdict verbatim from the final pass's `result.md`.
- For intent 2: your own self-review summary in 3–6 lines and the merged final verdict.

If, during this review or in any subsequent turn, you discover that an earlier judgment, input wording, validation execution claim, review framing, scope classification, or target-file selection you made was wrong, **do not hide it** — apply the retraction / correction reporting protocol. Surface (a) what you are retracting or correcting, (b) why the prior judgment was wrong, and (c) what the current state is. This pairs with the stale-by-omission rule on the ex-post side — the stale-by-omission rule covers pre-call disclosure, while this retraction protocol covers in-progress / post-discovery correction. Silently overwriting prior judgments breaks the operator-honesty invariant the verdict relies on.

### 8. Never commit or push

This skill must never run `git commit`, `git push`, `git tag`, `git merge`, or any release / publish command. The verdict is informational. The user decides commit / push / release / adoption explicitly, in a separate request, in their own words.

## Failure handling

- Entry-point non-zero exit: report exit code and the last status line. Do not retry without explicit scoped user approval; present the corrected invocation first and wait for go-ahead. This applies to every flavor (input-verify, Codex error, verdict parse error).
- Codex CLI not installed or not on PATH: report that the CLI environment is not ready (the Codex CLI must be installed and resolvable on the user's PATH). Do not attempt to install anything.
- Verdict parse failure: the failed pass directory is preserved on disk. Report its canonical path `log/review/<review-task-id>/pass-NN/` and stop. Do not edit files inside that pass directory.
- If `input.md` and `result.md` both exist but the pass is older than the source / docs / template / snippet content it covers, that pass is stale. Allocate a fresh `pass-NN` under the same `<review-task-id>` rather than reusing the stale pass's verdict.

## Out of scope

- Editing code to make the verdict pass.
- Running multiple cycles to "average out" verdicts.
- Translating the verdict into other vocabulary.
- Auto-committing, auto-pushing, auto-merging, auto-releasing, auto-deploying.
- Modifying `%USERPROFILE%\.claude\`, `%USERPROFILE%\.codex\`, `%USERPROFILE%\.claude\CLAUDE.md`, `%USERPROFILE%\.codex\AGENTS.md` (or `%CODEX_HOME%\AGENTS.md` or `AGENTS.override.md` at the Codex user-global scope), project-root `CLAUDE.md` / `AGENTS.md`, or the user's git config. `%USERPROFILE%\.claude\AGENTS.md` is forbidden. Managed-block insert / replace in those global files is a separate explicit user-approved scope.
- Cleaning up `log/review/<review-task-id>/` or `log/review/<review-task-id>/pass-NN/` directories.
- Producing, reading, or relying on any non-canonical artifact inside `log/review/<review-task-id>/pass-NN/` as part of the canonical review record. Sidecar JSON, hash-binding files, and external staging folders are not part of the canonical contract; if such files exist in the pass directory, treat them as runtime noise, not as review record. **Exception**: reviewer-readable validation evidence at `<ProjectRoot>/log/evidence/<scope>/<case>/validation-evidence.md` (or equivalent `.md` under `log/evidence/`), referenced from `input.md`'s `## Validation evidence` informational section, is reviewer-readable runtime supporting material — it is not command re-execution, not deterministic truth oracle, not freshness binding, not a canonical review record artifact, not promoted to source-of-truth, and not a sidecar inside the pass directory.
