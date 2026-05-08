---
name: ai-harness-review
description: Run an ai-harness-toolset review cycle on the user's current in-progress work. Trigger this skill on natural-language Korean or English intents that ask for a Codex / 코덱스 review of the current work, optionally preceded by a Claude self-review. Examples that should trigger this skill — "현재 진행한 작업 코덱스 리뷰 진행해", "지금까지 한 작업 리뷰해 줘", "코덱스로 리뷰 돌려", "현재 구현된 서버의 소켓 라이브러리를 니가 직접 리뷰하고, 그후에 코덱스 리뷰로 한번 더 리뷰 후 최종 결론 도출해", "review what I just did with codex", "self-review then codex review and give the final verdict". Do NOT trigger on `/review`, `/security-review`, or any non-ai-harness review. Do not require the user to provide review-cycle CLI arguments — derive them from the current work.
---

# ai-harness-review

This skill runs the ai-harness-toolset single-shot review cycle (`review-cycle.ps1`) on the user's currently in-progress work. It is the natural-language entrypoint for the toolset's review flow. The user is not expected to type raw PowerShell arguments.

This skill is the optional, copied counterpart to `snippets/CLAUDE_SNIPPET.md`. Adoption path: copy this file to `<project-root>/.claude/skills/ai-harness-review/SKILL.md` (or `~/.claude/skills/ai-harness-review/SKILL.md` for personal use). Do not create global files automatically.

## Two supported intents

Recognize and handle both of these without asking the user for CLI arguments. Each intent maps to a TargetFiles mode (defined in step 2 below): Mode A for current-work, Mode B for explicit subsystem.

1. **Codex review only.** The user just wants a Codex review of the current work — no subsystem named.
   - Examples: "현재 진행한 작업 코덱스 리뷰 진행해", "코덱스 리뷰 돌려", "review what I just did with codex".
   - Skip any Claude-side review. Use TargetFiles **Mode A** (changed files). Go straight to step 2 and onward.

2. **Claude self-review, then Codex review, then a single final verdict.** The user names a subsystem and wants you to inspect it yourself first, then run the Codex cycle, then merge both into one final conclusion.
   - Examples: "현재 구현된 서버의 소켓 라이브러리를 니가 직접 리뷰하고, 그후에 코덱스 리뷰로 한번 더 리뷰 후 최종 결론 도출해", "self-review then codex review and give the final verdict".
   - Use TargetFiles **Mode B** (tracked subsystem files). The subsystem is reviewed even if the working tree has no current changes.
   - Run a focused Claude code-reading pass on the same TargetFiles before invoking `review-cycle.ps1`, summarize what you found in plain language, and feed those findings into the `-Context` and `-ReviewQuestions` arguments so Codex's pass benefits from your reading. After Codex returns, merge your reading and Codex's verdict into one final yes / no / yes with risk.

The two dimensions (review style: Codex-only vs self-review+Codex / target scope: Mode A vs Mode B) are in principle independent. The two example phrases above are the canonical pairings, but if the user clearly mixes them (for example, "이번에 만진 소켓 코드만 코덱스 리뷰" — Codex only + Mode B), follow what they said. If genuinely ambiguous, use the single clarification rule in step 2 below.

## Required behavior

You — Claude Code — perform every step below. The user does not type any PowerShell.

### 0. Preserve current context

Do not abandon the conversation's working state. Do not restart, rebase, switch branch, stash, or reset. Do not modify source files for the purpose of running the review. The review reads what is already on disk.

### 1. Inspect repo state

- Run `git status --porcelain=v1` and `git diff` to see what is changed and untracked.
- Identify the active script root:
  - If `<project-root>/.ai-harness/scripts/review-cycle.ps1` exists, that is the script root (target payload mode).
  - Otherwise, if running inside the `ai-harness-toolset` source repo itself, use `<repo-root>/scripts/review-cycle.ps1` (source repo mode).
- If neither exists, stop and tell the user the toolset payload has not been copied to this project. Do not attempt to install it.

### 2. Determine TargetFiles

Pick the smallest concrete set of files the review should bind to. There are two distinct modes — choose one based on the user's intent, do not mix them.

**Mode A — current-work review (changed-files mode).** Use this when the user's intent is "review the work I just did" with no specific subsystem named.

- Examples that select Mode A: "현재 진행한 작업 코덱스 리뷰 진행해", "지금까지 한 작업 리뷰해 줘", "review what I just did".
- TargetFiles = the tracked changed file set from `git status --porcelain=v1` (modified / added / renamed / copied), excluding `log/`, generated artifacts, `.gitignore`-only changes, and unrelated noise.
- Untracked files are not auto-included by `review-cycle.ps1`. If the user clearly intends untracked files, list them explicitly in `-TargetFiles`.
- If the changed set is empty, stop and tell the user there is nothing to review in Mode A. Do not silently fall back to Mode B. Do not invent target files.

**Mode B — explicit subsystem review (named-scope mode).** Use this when the user names a subsystem, module, library, or path — even if there are no current changes. The review binds to the existing tracked files of that subsystem.

- Examples that select Mode B: "현재 구현된 서버의 소켓 라이브러리를 니가 직접 리뷰하고, 그후에 코덱스 리뷰로 한번 더 리뷰 후 최종 결론 도출해", "auth 모듈 코덱스 리뷰", "review the websocket layer".
- TargetFiles = tracked files in the repo that match the named subsystem, regardless of whether they are currently dirty.
  - Resolve the name against the repo: try a directory match first (`scripts/sockets/`, `server/socket/`, etc.), then a filename-substring match within likely roots (`scripts/`, `src/`, `server/`, `lib/`).
  - Use `git ls-files` to enumerate; do not include untracked or ignored files.
  - Exclude tests, fixtures, generated files, and unrelated noise unless the user explicitly asked for them.
- The current diff is supplementary context only. Surface it in `-Context`, but do not let it shrink or expand the subsystem set.
- If the user named explicit file paths verbatim, honor that list as-is and skip the resolution heuristic.

**Single clarification rule.** Ask the user at most once, and only when one of these conditions holds:

- Mode B subsystem scope is too broad (resolves to more than ~20 files, or spans clearly unrelated trees).
- Mode B subsystem name does not resolve to any tracked file.
- Intent itself is genuinely ambiguous between Mode A and Mode B.

After one clarification, proceed without re-asking. Do not chain multiple clarification rounds. Do not ask the user to type CLI arguments — ask only the minimal question needed to disambiguate scope (e.g., "소켓 라이브러리는 `scripts/server/sockets/` 와 `lib/net/socket-*.ps1` 둘 다 있는데 어느 쪽?").

**Common rules (both modes).**

- Use repo-relative paths with forward slashes.
- Exclude `log/` always.
- The chosen TargetFiles list is what `-TargetFiles` and the freshness binding in `meta.json` will key off of. Pick it deliberately.

### 3. Build review-cycle arguments yourself

The user must not be asked for these. Synthesize them from the conversation, the diff, and any active task or plan in this session.

- `-Stage` — choose one of `design`, `implementation`, `test`, `review`, `release` based on what the current change actually is. Default to `implementation` for ordinary code changes.
- `-Purpose` — one short line describing what the change is, in the user's working language. Quote a concrete artifact name when possible (e.g., `'review socket library implementation in scripts/server-sockets.ps1'`).
- `-TargetFiles` — comma-separated list from step 2.
- `-Context` — short paragraph of background the reviewer needs. If you ran a Claude self-review, include your own findings here in compressed form.
- `-RequiredInspectionPaths` — paths Codex must read; usually the same as `-TargetFiles`, plus any directly coupled file the diff implies.
- `-ReviewQuestions` — concrete questions you want Codex to answer. If you ran a Claude self-review, prioritize the open questions or doubts you could not resolve.
- `-Constraints` — explicit constraints the reviewer must respect (project conventions, encoding rules, public API stability, etc.).

Do not invent runtime details (no fake commit hashes, no fake reviewer model names). If you do not know a value, leave it short and honest.

### 4. Run review-cycle.ps1 exactly once

Invoke the script in `-File` mode, never `-Command`:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File <script-root>/review-cycle.ps1 `
    -Stage <stage> `
    -Purpose '<purpose>' `
    -TargetFiles <file1>,<file2> `
    -Context '<context>' `
    -RequiredInspectionPaths '<paths>' `
    -ReviewQuestions '<questions>' `
    -Constraints '<constraints>'
```

Hard rules:

- One invocation per user request. No retry on failure. No fallback model. No auto-fix loop.
- Do not reuse an existing `<run-id>`. Let `review-cycle.ps1` allocate a fresh one.
- Do not bypass `review-input-verify` or `review-verify`.

If the script exits non-zero, stop and report the exit and the last `review-cycle:` line. Do not re-run.

### 5. Inspect result.md and result.json

After exit 0, read both:

- `log/review/<run-id>/result.md` — the reviewer's free-form markdown. Look at the `## Verdict` section and any findings, risks, or required changes.
- `log/review/<run-id>/result.json` — the machine record. Confirm `verdict` is exactly one of `yes`, `no`, `yes with risk`.

If `result.json.verdict` is missing or any other value, treat the run as failed and report that. Do not paraphrase the verdict into a different word.

### 6. Confirm review-verify -RequireResult

`review-cycle.ps1` already runs both modes of `review-verify` before exiting 0, so a clean exit is sufficient. If you want to re-confirm explicitly, run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File <script-root>/review-verify.ps1 -RunId <run-id> -RequireResult
```

A non-zero exit here means the binding is broken; report it and stop.

### 7. Report the final verdict

End your response to the user with a clearly labeled final verdict, exactly one of:

- `yes`
- `no`
- `yes with risk`

For intent 1 (Codex only), this is the value from `result.json.verdict`.

For intent 2 (Claude self-review + Codex), produce a single merged final verdict using this rule:

- If either side is `no`, the merged verdict is `no`.
- If either side is `yes with risk`, the merged verdict is `yes with risk`. Carry the named risks forward.
- Only if both sides are `yes` is the merged verdict `yes`.

Always include in the report:

- `<run-id>`
- path to `result.json`
- the Codex verdict verbatim
- if intent 2: your own self-review summary in 3–6 lines and the merged final verdict
- the user's next decision points (the verdict does not approve commit, push, publish, merge, or release)

### 8. Never commit or push

This skill must never run `git commit`, `git push`, `git tag`, `git merge`, or any release/publish command. The verdict is informational. The user decides commit / push / release explicitly, in a separate step, in their own words.

If the user asks you to commit or push *after* seeing the verdict, that is a separate request handled outside this skill.

## Failure handling

- `review-cycle.ps1` non-zero exit: report the exit code and the last `review-cycle:` line printed. Do not retry.
- Codex CLI not installed or not on PATH: report that the CLI environment is not ready and point to `docs/CLI_ENVIRONMENT_ASSUMPTIONS.md`. Do not attempt to install anything.
- Verdict parse failure: the failed `<run-id>` is preserved on disk. Report the path and stop. Do not edit files inside that `<run-id>` directory.
- Stale review packet (a `targetFiles[]` SHA changed since prepare): report it as a stale-binding failure. Do not re-fabricate the packet.

## Out of scope

- Editing code to make the verdict pass.
- Running multiple cycles to "average out" verdicts.
- Translating the verdict into other vocabulary.
- Auto-committing, auto-pushing, auto-merging, auto-releasing, auto-deploying.
- Modifying `~/.claude/`, global `CLAUDE.md`, global `AGENTS.md`, or the user's git config.
- Cleaning up `log/review/<run-id>/` directories.
