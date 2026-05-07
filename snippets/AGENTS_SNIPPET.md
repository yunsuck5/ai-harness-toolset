# ai-harness-toolset instructions for Codex / generic agents

This is a manually adopted AI instruction payload for Codex CLI and other agent-style assistants. The user has copied it into the project root `AGENTS.md` inside a managed block delimited by `<!-- BEGIN ai-harness-toolset:AGENTS_SNIPPET.md -->` and `<!-- END ai-harness-toolset:AGENTS_SNIPPET.md -->`. Treat its content as authoritative for ai-harness workflows in this project.

## Adoption rules

- This payload is inserted only inside the managed block in root `AGENTS.md`.
- Whole-file overwrite of root `AGENTS.md` is forbidden.
- Project-specific instructions outside the managed block must be preserved verbatim.
- Updating means replacing only the managed block content; removing means deleting only the managed block.

## Project layout

- `.ai-harness/` is the project-local, copy-only payload. No global files are modified.
- Runtime output root is `<project-root>/log/`. `log/` must not be committed; ensure the target project's `.gitignore` includes it.
- Review records live at `log/review/<run-id>/`. Inspect them and report the verdict.
- Keep `log/review/`, `log/evidence/`, and `log/chatlog/` separate.
- Reviewer config comes from `.ai-harness/config/reviewer.json`.

## Review flow

- Default user-facing entrypoint is the single-shot CLI `.ai-harness/scripts/review-cycle.ps1`. Run it once per user-triggered review request.
- `review-cycle.ps1` runs Codex CLI exactly once per call and stops.
- The component scripts `.ai-harness/scripts/review-prepare.ps1` and `.ai-harness/scripts/review-verify.ps1` are available for explicit, deliberate use (preparing a packet without immediately running Codex, or verifying an existing run). Stale review packets (any `targetFiles[]` entry whose SHA-256 changed since prepare) must fail.
- Reviewer artifacts live only under `log/review/<run-id>/`. Do not create a root `codex-review-input.md` or root `codex-review-result*.json`.

## Result verdict vocabulary

The only valid final verdict values for this toolset are exactly:

- `yes`
- `no`
- `yes with risk`

A reviewer verdict does not approve commit, push, publish, merge, or release.

## Chatlog session protocol

Chatlog is a first-class subsystem of ai-harness-toolset. It is not a reviewer byproduct.

- Before resuming meaningful work, read `log/chatlog/current/resume.md` first. If absent, read `summary.md`, then `decisions.md`, then `raw-transcript.md` only when source wording matters.
- Treat chatlog as human-first. Write it so a human can resume the project before an AI reconstructs context.
- Do not mix user-original text with AI-authored summaries, judgments, decisions, or change summaries. Keep them in separate sections or separate files.
- Do not summarize, compress, rephrase, translate, or interpret user-original text when preserving it as original. Keep verbatim quotes short and place AI judgment on a separate line.
- After meaningful work changes session state, update `log/chatlog/current/summary.md` and `resume.md` before handoff. Read-only exploration that did not change session state does not require an update.

## Other rules

- Commit and push require explicit user approval.
- `.ps1` files must be UTF-8 with BOM + CRLF.
