---
name: ai-harness-review
description: Run an ai-harness-toolset review on the user's current in-progress work. Trigger this skill on natural-language Korean or English intents that ask for a Codex / 코덱스 review of the current work, optionally preceded by a Claude self-review. Examples that should trigger this skill — "현재 진행한 작업 코덱스 리뷰 진행해", "지금까지 한 작업 리뷰해 줘", "코덱스로 리뷰 돌려", "현재 구현된 서버의 소켓 라이브러리를 니가 직접 리뷰하고, 그후에 코덱스 리뷰로 한번 더 리뷰 후 최종 결론 도출해", "review what I just did with codex", "self-review then codex review and give the final verdict". Do NOT trigger on `/review`, `/security-review`, or any non-ai-harness review. Do not require the user to provide review CLI arguments — derive them from the current work.
---

# ai-harness-review

This skill drives the ai-harness-toolset canonical review flow. The canonical review artifact layout is one pass directory per Codex attempt, grouped under one task directory per review task:

```text
<ProjectRoot>/log/review/<review-task-id>/
  pass-01/
    input.md   AI-authored from templates/review-input.md
    result.md  Codex-authored
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

Before finalizing the target set, verify it against the actual changed file set per the target-file accuracy rule (`docs/contracts/review/REVIEW_RESULT_CONTRACT.md` §5a.1): cross-check `git status --porcelain=v1` and `git diff` against your Mode A / Mode B selection. Do not silently drop a changed file or silently include an unrelated file. If you deliberately omit a changed file from the review (for example, an obviously unrelated incidental edit), disclose that decision under `## Known concerns` so the reviewer sees the omission rather than inferring it. The reviewer reads only what `## Target files` lists; an inaccurate target set produces a verdict on the wrong surface.

### 3. Allocate the pass directory

Pick a `<review-task-id>` for this work: a stable string identifying the `/goal` task or review gate (for example, `topology-simplification-2026-05-16`). Reuse the same `<review-task-id>` for every pass of the same task; pick a new one only when the task itself changes. Determine the `pass-NN` for this attempt: `pass-01` for the first Codex attempt of this task; `pass-02`, `pass-03`, ... for subsequent corrective-loop attempts. You may pass `-Pass <pass-NN>` explicitly, or omit it to let `review-prepare.ps1` auto-allocate the next pass under the same task directory.

Invoke `<ToolRoot>/scripts/review-prepare.ps1 -ReviewTaskId <id> [-Pass <pass-NN>] -Stage <stage> -Purpose <line>` once. The script creates the canonical pass directory `<ProjectRoot>/log/review/<review-task-id>/pass-NN/` and seeds `input.md` from `templates/review-input.md`.

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
- `## Validation evidence` — when this round makes validation execution claims (e.g., Pester pass count, `verify-ps1` PASS, `git diff --check` clean), reference the Markdown evidence file path under `<ProjectRoot>/log/evidence/<scope>/<case>/validation-evidence.md` (or equivalent `.md` path under `log/evidence/`) so the reviewer can read its body in the read-only sandbox. If this round makes no such claims, put a short literal note such as `N/A — no validation execution claims in this round.` The evidence file is reviewer-readable runtime supporting material — not command re-execution, not deterministic truth oracle, not freshness binding, not source-of-truth. `scripts/review-input-verify.ps1` does not currently lint the presence or shape of this section; populating it is operator convention.
- `## Known concerns` — disclose any compromise / convention deviation / skipped alternative / baseline failure / validation limitation / operator assumption that you (the operator) already know about before calling Codex. Recommended sub-categories: convention deviation, skipped alternatives, validation limitations, baseline failures, direct verification not performed, operator assumptions. If you know something might affect the reviewer's judgment and you don't write it here, the resulting verdict can be invalidated ex-post by stale-by-omission — the verdict becomes unfit for commit/push judgment until a new pass with the omitted concerns disclosed is run. If you genuinely have no such concerns this round, write a short literal note such as `N/A — no known concerns disclosed.` `scripts/review-input-verify.ps1` does not currently lint the presence or shape of this section either.

Author the body content yourself from conversation context, diff, and any active task or plan in this session. `scripts/review-input-verify.ps1` rejects unfilled `{{AI_TO_FILL_*}}` active placeholders (regex `\{\{AI_TO_FILL_[A-Za-z0-9_]+\}\}`) and the forbidden-phrase substrings declared in its `$forbidden` array. Active review-input placeholders use the `AI_TO_FILL_` prefix; generic double-brace forms such as `{{TOKEN}}` or `{{example}}` are documentation literals and are not rejected. Do not invent runtime details (no fake commit hashes, no fake reviewer model names).

Write `## Review questions` in **neutral phrasing** — open-ended (`How many X were migrated, and is that the intended scope?`) rather than confirmation-seeking (`Are exactly N X migrated?`). Reviewers naturally drift toward `yes` when prompts are leading. Include, as the last recommended question, a reviewer self-audit on framing — e.g., `Does the input above nudge the reviewer toward a particular verdict? If so, surface the tilt in ## Notes.` The reviewer's framing-tilt answer goes into `## Notes`, not into the verdict itself.

When the review input references off-repo or sibling material (for example, a planning anchor under `polishing/`, a handoff doc, a snapshot or manifest, or user-provided text), do not promote it to source-of-truth. Reference it as advisory / planning / user-provided context and disclose its role explicitly in `## Context` (`docs/contracts/review/REVIEW_RESULT_CONTRACT.md` §5a.2). The reviewer's read-only sandbox can often read repo-sibling and `log/` paths (Codex CLI v0.130.0 on Windows has been observed to do so for `polishing/` and `log/` subtrees); do not assume it cannot. Attempt the read first and record the exact path and error only if the read actually fails. Independently of sandbox capability, when the off-repo material is itself review-relevant — for example, the body of an anchor doc that the verdict depends on — inline its body verbatim inside `## Context` (or a dedicated subsection such as `## Anchor draft body`) so the verdict does not depend on the sandbox path read. Citing only the off-repo path while leaving its body unreadable inside the sandbox produces verdicts on the wrong base when the sandbox read actually fails.

When `input.md` cross-references a prior review record (another `<review-task-id>/pass-NN/result.md`, another batch's polishing log, or a section/line in a planning anchor), verify the citation provenance directly before quoting — open the cited path, confirm the exact text and section, and quote from that source rather than transitively through an intermediate planning document. Likewise, when stating counts in `## Context` or `## Known concerns` (file count, line count, pass count, recurrence count, etc.), run a mechanical check (Glob, grep, `wc -l`, or equivalent) immediately before writing the number — do not carry a count from an earlier document if the underlying state may have changed since that document was written. These two disciplines mitigate operator narrow-scope over-confidence; when a wrong citation or wrong count is discovered after a review has run, apply the retraction protocol (`docs/contracts/review/REVIEW_RESULT_CONTRACT.md` §5a.4) — surface what was wrong, why, and the current state — rather than silently overwriting the prior claim.

The reviewer is also instructed (per the H1 reviewer-mode preamble in `scripts/review-run.ps1`) to articulate the strongest case **against** its own conclusion in `## Counter-argument` before issuing the final verdict, especially when the verdict is `yes` or `yes with risk` — this is the dedicated pressure-test surface per `docs/contracts/review/REVIEW_RESULT_CONTRACT.md` §3c (Counter-argument convention). Treat that section as a substantive pressure-test surface when you read the result — it is not a courtesy aside. If deliberate pressure-test finds no material counter-argument, the reviewer leaves a short literal (`none` or `no material counter-argument identified`) rather than ceremonial boilerplate. `## Counter-argument` is **optional and strongly-recommended (NOT parser-required)** — `scripts/review-verify.ps1 -RequireResult` still enforces only the four V2 H2s, and omission is not a parser FAIL. `## Notes` remains available as the freeform reviewer-narrative bucket (framing-tilt self-audit, evidence pointers, follow-up inspection, general observations). Heavier mechanisms beyond §3c — a devil's-advocate pre-pass or multi-reviewer consensus — remain idea-only per `docs/systems/review/IDEAS.md` (not implementation backlog).

Generic double-brace forms such as `{{TOKEN}}`, `{{REAL}}`, or `{{example}}` can be cited directly in `input.md` prose (including inside inline backticks) as documentation literals — they are not rejected by the verifier, because the input-verify regex `\{\{AI_TO_FILL_[A-Za-z0-9_]+\}\}` only matches the active `AI_TO_FILL_` namespace. When you need to refer to a specific active placeholder by name (e.g., `AI_TO_FILL_VALIDATION_EVIDENCE`), use the brace-less identifier form so the verifier does not see an unfilled active placeholder in your prose. The earlier wildcard and backslash-escape workaround conventions are no longer required.

Before stating a **mechanical behavior claim** in `input.md` — a claim about how a specific regex, parser, verifier, or script actually behaves on specific input — verify it with a **minimal reproducible check** rather than relying on reasoning alone. A minimal reproducible check is narrow: a tiny regex match against a literal string, a small parser input, a small verifier fixture, an isolated string / character inspection in any available scripting environment, a one-line shell exit-code check. It is not the full test suite — it is a check just narrow enough to reduce the chance that prose-stated mechanics are wrong. The same discipline applies when about to commit such a claim into any template, snippet, or contract surface; reasoning-only mechanical claims have repeatedly led to corrective loops in this toolset, and the check is cheap while the corrective is expensive. If the claim cannot be verified in the current environment, disclose it as unverified under `## Known concerns` so the reviewer can decide how to treat it.

Tell the reviewer in `input.md` (e.g., as a constraint or in the `## Final verdict` instruction) that `result.md` must contain these four H2 headings, each exactly once: `## Blocking findings`, `## Non-blocking concerns`, `## Review limitations`, `## Assumptions relied on`. If a section has no substance, the reviewer should still emit the heading with `none` as the body. `scripts/review-verify.ps1 -RequireResult` rejects the pass when any of the four is missing or duplicated (mechanical presence/count check; no sub-shape lint). Without this instruction in `input.md`, the reviewer may omit one of the sections and force a corrective pass.

Also tell the reviewer in `input.md` (alongside the four-H2 instruction or in the `## Final verdict` body) that when the verdict is `yes` or `yes with risk`, `result.md` should include a `## Counter-argument` H2 articulating the strongest case AGAINST the verdict. This section is **optional and strongly-recommended; non-parser** — `scripts/review-verify.ps1 -RequireResult` does not check for it, omission is not a parser FAIL, and the body should be the short literal `none` or `no material counter-argument identified` when deliberate pressure-test finds nothing material rather than ceremonial boilerplate ("the alternative interpretation is X, but I dismiss it because Y" with no substance). When the verdict is `no`, `## Counter-argument` may be omitted since `## Blocking findings` is already the case-against-yes articulation. Full convention (substance contract, position relative to `## Notes`, boilerplate-degeneration mitigation) lives in `docs/contracts/review/REVIEW_RESULT_CONTRACT.md` §3c.

If you ran a Claude self-review (intent 2), summarize your own findings inside `## Context` and put your unresolved doubts into `## Review questions` so Codex's pass builds on your reading.

### 5. Run the reviewer exactly once

Invoke `<ToolRoot>/scripts/review-run.ps1 -ReviewTaskId <id> -Pass <pass-NN>` once. It calls `scripts/review-input-verify.ps1` against the `input.md` you wrote, invokes Codex CLI once (`--ask-for-approval never`, `--sandbox read-only`, `--output-last-message <review-task-id>/pass-NN/result.md`), validates the `## Verdict` shape, and exits.

Hard rules for step 5:

- One invocation per user request. No retry on failure. No fallback model. No auto-fix loop.
- Run `review-run.ps1` in the foreground and wait for completion. Do not spawn it as detached or background work, and do not run the review concurrently with other work. A timeout or budget is only an operating allowance for a foreground attempt; it is not a correctness guarantee, and review validity is judged by complete run artifacts, valid result binding, and the step-6 verification, not by how the run was launched.
- Do not bypass `scripts/review-input-verify.ps1`.
- Do not edit `input.md` once `review-run.ps1` has started. If the input needs correction, allocate a new pass for the same `<review-task-id>` (go back to step 3 with a new `pass-NN`).

If `review-run.ps1` exits non-zero, stop. Report the exit code and the last status line printed. Report whether `result.md` exists in the pass directory. Do not silently retry, even by adjusting argument shape — surface a corrected proposed invocation and wait for explicit go-ahead.

The stop/report-vs-self-correct boundary (`docs/contracts/review/REVIEW_RESULT_CONTRACT.md` §5a.3) applies here too: if running `review-run.ps1` would require touching anything outside the review's approved scope — for example user-global files under `%USERPROFILE%\.claude\` or `%USERPROFILE%\.codex\`, the channel 3 install payload under `%USERPROFILE%\.claude\ai-harness-toolset\current\`, the `<ProjectRoot>/log/` runtime tree beyond the prepared pass directory, or any repo-outside material — stop and report instead of silently expanding scope. The reviewer pass directory is the only runtime artifact you write to in this step.

### 6. Verify the canonical artifacts and confirm the verdict

After step 5 exits cleanly, invoke `<ToolRoot>/scripts/review-verify.ps1 -ReviewTaskId <id> -Pass <pass-NN> -RequireResult` once. This is the post-hoc canonical-artifact check; it does **not** invoke Codex. It re-validates `input.md` shape, the `## Verdict` shape inside `result.md`, and the presence (each exactly once) of the four required disclosure H2 headings in `result.md`: `## Blocking findings`, `## Non-blocking concerns`, `## Review limitations`, `## Assumptions relied on`. If it exits non-zero, stop and report the exit code and the last status line. Do not edit files in the pass directory to make it pass — allocate a new `pass-NN` under the same `<review-task-id>` with a corrected `input.md` (typically: re-emphasize the four required H2s to the reviewer).

After `review-verify.ps1` exits cleanly, read `log/review/<review-task-id>/pass-NN/result.md` as a **structured review artifact** — the verdict line is necessary but not sufficient for the next-action judgment, and you must read the disclosure sections alongside it:

- Confirm exactly one `## Verdict` heading exists.
- Confirm the first non-empty line after `## Verdict` (whitespace-trimmed) is exactly one of `yes`, `no`, `yes with risk` — lowercase, no qualifier, no inline form.
- Read the four V2 required disclosure H2 sections (each present exactly once, with `none` as the body when empty): `## Blocking findings`, `## Non-blocking concerns`, `## Review limitations`, `## Assumptions relied on`.
- Also read optional sections (`## Findings`, `## Risks`, `## Counter-argument`, `## Notes`) if present. The four required H2s are the mechanical-enforced disclosure positions; the optional sections are free-form reviewer narrative. `## Counter-argument` is the dedicated verdict pressure-test position (strongly-recommended for `yes` / `yes with risk` verdicts per `docs/contracts/review/REVIEW_RESULT_CONTRACT.md` §3c) — read its substance, and evaluate whether the body is substantive or ceremonial boilerplate. Recurring boilerplate or omission across many passes is escalation evidence input for a separate later batch decision (parser-required gate or heavier mechanism); a single boilerplate / omission case is not by itself a blocking finding. **Precedence rule**: when `## Blocking findings` and a free-form `## Findings` section disagree on whether something is blocking, `## Blocking findings` is the source of truth. If `result.md` passes the shape gate (`review-verify -RequireResult`) but the body discloses a limitation, assumption, or risk that affects commit fitness, surface it to the user — shape PASS is not an automatic commit-fitness guarantee.

The verdict has a narrowed meaning — `yes` = no blocking finding (not commit/push approval); `no` = blocking finding exists (corrective needed); `yes with risk` = no blocking finding but the risks under `## Risks` (and any flagged limitations / assumptions) require explicit supervisor or user acceptance before commit / push. `yes with risk` is not the automatic equivalent of `yes` for the next step. The full verdict → next-action mapping lives in `docs/contracts/review/REVIEW_RESULT_CONTRACT.md` §6a; this step is the practical operator-side mirror of that mapping. When reporting back to the user, report the verdict verbatim plus the four disclosure sections so the user has the same surface the reviewer surfaced.

When the verdict depends on a mechanical behavior claim made in `input.md` (about a regex, parser, verifier, or script), expect the reviewer to have attempted a **minimal reproducible check** of that claim where feasible in the read-only sandbox (a tiny regex match against a literal string, a small parser input, a small verifier fixture, an isolated string / character inspection in any available scripting environment, a one-line shell exit-code check). If the result.md surfaces such a check under `## Notes` or `## Assumptions relied on`, treat the verdict as load-bearing on that point. If the reviewer recorded under `## Review limitations` that the check was infeasible in its sandbox, treat the prose claim as unverified and adjust your downstream judgment accordingly even if the verdict is `yes` or `yes with risk`.

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

Always include in the report, kept visually distinct:

1. **Entry-point error** — none, or the exit code plus the last status line. State whether a pass directory was allocated and whether `result.md` exists for it.
2. **Retry decision** — none, or what was retried, why, and whether explicit scoped re-approval was sought.
3. **Review task** — `<review-task-id>` for this work.
4. **Final pass** — the final `pass-NN` (e.g., `pass-01`, `pass-03`) and the canonical path `log/review/<review-task-id>/pass-NN/result.md`.
5. **Corrective loop count** — the number of passes consumed in this review task (1 if `pass-01` succeeded; N if the final pass was `pass-NN`).
6. **Final reviewer result** — the Codex verdict verbatim from the final pass's `result.md`.
7. For intent 2: your own self-review summary in 3–6 lines and the merged final verdict.
8. **Next-action handling per verdict** — apply the verdict → next-action mapping (`docs/contracts/review/REVIEW_RESULT_CONTRACT.md` §6a) to this result:
   - `yes` — surface `## Non-blocking concerns` / `## Review limitations` / `## Assumptions relied on` to the user; commit / push / release / next batch are separate explicit user decisions, not automatic.
   - `no` — classify each `## Blocking findings` item as within or outside the user-approved scope. Propose a scoped corrective patch + corrected-state re-review for in-scope items; stop and request separate approval for out-of-scope items. Do not close the batch on `no` without concrete re-review evidence.
   - `yes with risk` — summarize the risks (`## Risks` plus any risk-bearing entries under `## Review limitations` / `## Assumptions relied on` / `## Non-blocking concerns`) and ask the user for explicit risk acceptance. Do not treat `yes with risk` as `yes`; do not commit / push before acceptance.
9. The user's next decision points (the verdict does not approve commit, push, publish, merge, or release).

If, during this review or in any subsequent turn, you discover that an earlier judgment, input wording, validation execution claim, review framing, scope classification, or target-file selection you made was wrong, **do not hide it** — apply the retraction / correction reporting protocol (`docs/contracts/review/REVIEW_RESULT_CONTRACT.md` §5a.4). Surface (a) what you are retracting or correcting, (b) why the prior judgment was wrong, and (c) what the current state is. This pairs with the §7 stale-by-omission rule on the ex-post side — §7 covers pre-call disclosure, §5a.4 covers in-progress / post-discovery retraction. Silently overwriting prior judgments breaks the operator-honesty invariant the verdict relies on.

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
