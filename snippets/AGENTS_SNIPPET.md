# ai-harness-toolset instructions for Codex / generic agents

This is a manually adopted AI instruction payload for Codex CLI and other agent-style assistants. The user has copied it into the project root `AGENTS.md` inside a managed block delimited by `<!-- BEGIN ai-harness-toolset:AGENTS_SNIPPET.md -->` and `<!-- END ai-harness-toolset:AGENTS_SNIPPET.md -->`. Treat its content as authoritative for ai-harness workflows in this project.

## Adoption rules

- This payload is inserted only inside the managed block in root `AGENTS.md`.
- Whole-file overwrite of root `AGENTS.md` is forbidden.
- Project-specific instructions outside the managed block must be preserved verbatim.
- Updating means replacing only the managed block content; removing means deleting only the managed block.

## Project layout

- `.ai-harness/` is the project-local, copy-only payload. No global files are modified.
- Runtime output root is `<project-root>/log/`.
- Keep `log/review/`, `log/evidence/`, and `log/chatlog/` separate.
- Review packets live under `log/review/<run-id>/`.
- Reviewer config comes from `.ai-harness/config/reviewer.json`.

## Review flow

- Prepare a packet with `.ai-harness/scripts/review-prepare.ps1`.
- Verify with `.ai-harness/scripts/review-verify.ps1`. Stale review packets (target SHA-256 changed since prepare) must fail.
- Do not create a root `codex-review-input.md` or root `codex-review-result*.json`. Reviewer artifacts live only under `log/review/<run-id>/`.
- `run-codex-review.ps1` and `review-run` are post-MVP and must not be invented in the target project.

## Manual Codex reviewer recipe

Reviewer execution happens outside the toolset after `review-prepare`:

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

## Other rules

- Commit and push require explicit user approval.
- `.ps1` files must be UTF-8 with BOM + CRLF.
