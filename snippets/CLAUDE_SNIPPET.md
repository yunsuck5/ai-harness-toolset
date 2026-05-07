# ai-harness-toolset instructions for Claude Code

This is a manually adopted AI instruction payload for Claude Code. The user has copied it into the project root `CLAUDE.md` inside a managed block delimited by `<!-- BEGIN ai-harness-toolset:CLAUDE_SNIPPET.md -->` and `<!-- END ai-harness-toolset:CLAUDE_SNIPPET.md -->`. Treat its content as authoritative for ai-harness workflows in this project.

## Adoption rules

- This payload is inserted only inside the managed block in root `CLAUDE.md`.
- Whole-file overwrite of root `CLAUDE.md` is forbidden.
- Project-specific instructions outside the managed block must be preserved verbatim.
- Updating means replacing only the managed block content; removing means deleting only the managed block.

## Project layout

- `.ai-harness/` is the project-local, copy-only payload. No global files are modified.
- Runtime output root is `<project-root>/log/`. `log/` is project-local runtime artifact and must not be committed.
- Ensure the target project's own `.gitignore` includes `log/`. The toolset never auto-edits `.gitignore`.
- There is no automatic retention or pruning for `log/review/<run-id>/`. Manual cleanup is per-`<run-id>` directory deletion.
- Keep `log/review/`, `log/evidence/`, and `log/chatlog/` separate.
- Review packets live under `log/review/<run-id>/`.
- Reviewer config comes from `.ai-harness/config/reviewer.json`.

## Review flow

- Default user-facing entrypoint is the single-shot CLI `.ai-harness/scripts/review-cycle.ps1`. Run it once per user-triggered review request (for example, when the user says `코덱스 리뷰 진행해`).
- `review-cycle.ps1` is single-shot and user-triggered. It is not a watcher, git hook, daemon, workflow engine, or productized `review-run`. It runs Codex CLI exactly once and stops; it never auto-commits, auto-pushes, auto-merges, auto-publishes, or auto-deploys.
- The component scripts `.ai-harness/scripts/review-prepare.ps1` and `.ai-harness/scripts/review-verify.ps1` remain available for manual / debug paths. Stale review packets (any `targetFiles[]` entry whose SHA-256 changed since prepare) must fail.
- Do not create a root `codex-review-input.md` or root `codex-review-result*.json`. Reviewer artifacts live only under `log/review/<run-id>/`.
- `run-codex-review.ps1`, `review-run` productization wrappers, and CI integration are post-MVP and must not be invented in the target project. Only `review-cycle.ps1` (single-shot, user-triggered) is in MVP scope.

## Manual Codex reviewer recipe (fallback)

`review-cycle.ps1` is the default path. The recipe below is the fallback used when `review-cycle.ps1` cannot finish (for example, when verdict parsing fails) or when the human deliberately runs the components by hand.

```
$runId = "<run-id>"
$model = "<model-from-reviewer.json>"
Get-Content -Raw -LiteralPath "log/review/$runId/input.md" |
  codex --ask-for-approval never exec --sandbox read-only --model $model -c web_search=disabled --output-last-message "log/review/$runId/result.md" -
```

- `--ask-for-approval never` is a top-level Codex flag and must appear **before** the `exec` subcommand.
- `--output-last-message` writes the final reviewer message to `log/review/<run-id>/result.md`.
- After `result.md`, create `log/review/<run-id>/result.json` using `.ai-harness/templates/review-result.json` as the shape, then run `.ai-harness/scripts/review-verify.ps1 -RunId <run-id> -RequireResult`.

## Result verdict vocabulary

The only valid final verdict values for this toolset are exactly:

- `yes`
- `no`
- `yes with risk`

A reviewer verdict does not approve commit, push, publish, merge, or release.

## Chatlog session protocol

Chatlog is a first-class subsystem of ai-harness-toolset. It is not a reviewer byproduct. Claude Code is the secondary reader; the primary reader is the human who picks up the project next.

- Before resuming meaningful work, read `log/chatlog/current/resume.md` first. If absent, read `summary.md`, then `decisions.md`, then `raw-transcript.md` only when source wording matters.
- Treat chatlog as human-first. Write it so a human can resume the project before an AI (including Claude Code itself in a future session) reconstructs context.
- Do not mix user-original text with AI-authored summaries, judgments, decisions, or change summaries. Keep them in separate sections or separate files.
- Do not summarize, compress, rephrase, translate, or interpret user-original text when preserving it as original. If the user wrote in Korean, keep the Korean verbatim — do not paraphrase into English (or vice versa). Keep verbatim quotes short and place AI judgment on a separate line.
- After meaningful work changes session state, update `log/chatlog/current/summary.md` and `resume.md` before handoff. Read-only exploration that did not change session state does not require an update.
- Do not write chatlog content into auto-memory. Memory persists across projects; chatlog is project-local under `log/chatlog/`.

## Other rules

- Commit and push require explicit user approval.
- `.ps1` files must be UTF-8 with BOM + CRLF.
