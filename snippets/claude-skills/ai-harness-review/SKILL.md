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

Source-of-truth for the contract is `docs/REVIEW_RESULT_CONTRACT.md`. This skill mirrors that contract. The scripts emit the canonical two-level `<review-task-id>/pass-NN/` layout directly; the only on-disk record per pass is the `input.md` + `result.md` pair.

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
- Resolve `<ToolRoot>` using `docs/roadmap/SHARED_GLOBAL_INVOCATION_CONTRACT.md` §5.1 (channel 1 explicit `-ToolRoot` → channel 2 `AI_HARNESS_TOOL_ROOT` env var → channel 3 global stable install `%USERPROFILE%\.claude\ai-harness-toolset\current` → channel 4 source-repo dogfooding multi-marker → channel 5 legacy `<ProjectRoot>/.ai-harness/` → channel 6 stop). If channel 6 is reached, stop and tell the user the toolset is not available; do not auto-install.

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

### 3. Allocate the pass directory

Pick a `<review-task-id>` for this work: a stable string identifying the `/goal` task or review gate (for example, `topology-simplification-2026-05-16`). Reuse the same `<review-task-id>` for every pass of the same task; pick a new one only when the task itself changes. Determine the `pass-NN` for this attempt: `pass-01` for the first Codex attempt of this task; `pass-02`, `pass-03`, ... for subsequent corrective-loop attempts. You may pass `-Pass <pass-NN>` explicitly, or omit it to let `review-prepare.ps1` auto-allocate the next pass under the same task directory.

Invoke `<ToolRoot>/scripts/review-prepare.ps1 -ReviewTaskId <id> [-Pass <pass-NN>] -Stage <stage> -Purpose <line>` once. The script creates the canonical pass directory `<ProjectRoot>/log/review/<review-task-id>/pass-NN/` and seeds `input.md` from `templates/review-input.md`.

Hard rules for step 3:

- The seeded `input.md` is the template body verbatim, not the actual review request. You will overwrite it in step 4. Do not invoke Codex yet.
- Each `<review-task-id>/pass-NN/` is write-once. If a pass already exists for the chosen `pass-NN`, the script refuses; allocate a new `pass-NN` under the same `<review-task-id>`.

### 4. Author the pass `input.md`

Open `<ProjectRoot>/log/review/<review-task-id>/pass-NN/input.md` (the file just seeded by step 3) and overwrite its body with the actual review request. Keep `templates/review-input.md` as the shape reference.

The file must contain these required H2 headings (exact text), each with non-empty body:

- `## Context`
- `## Required inspection paths`
- `## Review questions`
- `## Constraints`
- `## Final verdict` — body must contain the literal string `yes / no / yes with risk`.

Add these informational headings as well (recommended):

- `## Stage` — one of `design`, `implementation`, `test`, `review`, `release`. Default `implementation` for ordinary code changes.
- `## Purpose` — one short line in the user's working language. Name the artifact when possible.
- `## Target files` — bulleted list of repo-relative forward-slash paths chosen in step 2.

Author the body content yourself from conversation context, diff, and any active task or plan in this session. `scripts/review-input-verify.ps1` rejects unfilled `{{TOKEN}}` patterns and the forbidden-phrase substrings declared in its `$forbidden` array. Do not invent runtime details (no fake commit hashes, no fake reviewer model names).

If you ran a Claude self-review (intent 2), summarize your own findings inside `## Context` and put your unresolved doubts into `## Review questions` so Codex's pass builds on your reading.

### 5. Run the reviewer exactly once

Invoke `<ToolRoot>/scripts/review-run.ps1 -ReviewTaskId <id> -Pass <pass-NN>` once. It calls `scripts/review-input-verify.ps1` against the `input.md` you wrote, invokes Codex CLI once (`--ask-for-approval never`, `--sandbox read-only`, `--output-last-message <review-task-id>/pass-NN/result.md`), validates the `## Verdict` shape, and exits.

Hard rules for step 5:

- One invocation per user request. No retry on failure. No fallback model. No auto-fix loop.
- Do not bypass `scripts/review-input-verify.ps1`.
- Do not edit `input.md` once `review-run.ps1` has started. If the input needs correction, allocate a new pass for the same `<review-task-id>` (go back to step 3 with a new `pass-NN`).

If `review-run.ps1` exits non-zero, stop. Report the exit code and the last status line printed. Report whether `result.md` exists in the pass directory. Do not silently retry, even by adjusting argument shape — surface a corrected proposed invocation and wait for explicit go-ahead.

### 6. Read `result.md` and confirm the verdict

After clean exit, read `log/review/<review-task-id>/pass-NN/result.md`:

- Confirm exactly one `## Verdict` heading exists.
- Confirm the first non-empty line after `## Verdict` (whitespace-trimmed) is exactly one of `yes`, `no`, `yes with risk` — lowercase, no qualifier, no inline form.
- Read `## Findings`, `## Risks` (if present), `## Notes` (if present) to understand reviewer reasoning.

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
8. The user's next decision points (the verdict does not approve commit, push, publish, merge, or release).

### 8. Never commit or push

This skill must never run `git commit`, `git push`, `git tag`, `git merge`, or any release / publish command. The verdict is informational. The user decides commit / push / release / adoption explicitly, in a separate request, in their own words.

## Failure handling

- Entry-point non-zero exit: report exit code and the last status line. Do not retry without explicit scoped user approval; present the corrected invocation first and wait for go-ahead. This applies to every flavor (input-verify, Codex error, verdict parse error).
- Codex CLI not installed or not on PATH: report that the CLI environment is not ready and point to `docs/CLI_ENVIRONMENT_ASSUMPTIONS.md`. Do not attempt to install anything.
- Verdict parse failure: the failed pass directory is preserved on disk. Report its canonical path `log/review/<review-task-id>/pass-NN/` and stop. Do not edit files inside that pass directory.
- If `input.md` and `result.md` both exist but the pass is older than the source / docs / template / snippet content it covers, that pass is stale. Allocate a fresh `pass-NN` under the same `<review-task-id>` rather than reusing the stale pass's verdict.

## Out of scope

- Editing code to make the verdict pass.
- Running multiple cycles to "average out" verdicts.
- Translating the verdict into other vocabulary.
- Auto-committing, auto-pushing, auto-merging, auto-releasing, auto-deploying.
- Modifying `%USERPROFILE%\.claude\`, `%USERPROFILE%\.codex\`, `%USERPROFILE%\.claude\CLAUDE.md`, `%USERPROFILE%\.codex\AGENTS.md` (or `%CODEX_HOME%\AGENTS.md` or `AGENTS.override.md` at the Codex user-global scope), project-root `CLAUDE.md` / `AGENTS.md`, or the user's git config. `%USERPROFILE%\.claude\AGENTS.md` is forbidden. Managed-block insert / replace in those global files is a separate explicit user-approved scope (`docs/roadmap/GLOBAL_ADOPTION_DECISION.md` §6).
- Cleaning up `log/review/<review-task-id>/` or `log/review/<review-task-id>/pass-NN/` directories.
- Producing, reading, or relying on any artifact outside the canonical `input.md` + `result.md` pair. Sidecar JSON, hash-binding files, and external staging folders are not part of the canonical contract. If such files exist on disk from earlier transitional implementations, treat them as runtime noise, not as review record (`docs/backlog/review.md`).
