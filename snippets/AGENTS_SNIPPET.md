# AGENTS.md snippet (manual copy)

This snippet may be manually copied into a project's AGENTS.md by the user.

- Do not auto-mutate the root AGENTS.md.
- Review packets must live under `<project-root>/log/review/<run-id>/`.
- A stale review must fail.
- Do not use a root `codex-review-input.md`.
- A reviewer verdict does not approve commit, push, or publish.
- Reviewer config comes from `<project-root>/.ai-harness/config/reviewer.json` when deployed.

## Manual reviewer invocation

This is a manual recipe, not a project-local adapter. Treat it as the recommended example only after confirming local `codex exec --help` once.

- The current MVP has no `run-codex-review.ps1` adapter and no `review-run` wrapper. Reviewer execution occurs outside the toolset after `review-prepare`.
- `codex exec` is the non-interactive Codex subcommand. Interactive `codex` requires a TTY and is not appropriate for non-interactive Claude Code shells.
- PowerShell / Claude Code shell example to produce `log/review/<run-id>/result.md`:

  ```
  $runId = "<run-id>"
  $model = "<model-from-config>"
  Get-Content -Raw -LiteralPath "log/review/$runId/input.md" |
    codex --ask-for-approval never exec --sandbox read-only --model $model -c web_search=disabled --output-last-message "log/review/$runId/result.md" -
  ```

- `--output-last-message` writes the reviewer's final message to `result.md`; avoid stdout redirection as the default. If only `-o` is supported on the installed CLI, substitute `-o "log/review/$runId/result.md"` based on local `codex exec --help`.
- `--ask-for-approval never` is a top-level Codex flag and must appear **before** the `exec` subcommand. Codex CLI 0.125.0's `exec` parser rejects `codex exec --ask-for-approval ...` as an unexpected argument. If the installed Codex CLI accepts the flag in no position, stop and use a real terminal or an approved fallback.
- `<model-from-config>` is taken from `<project-root>/.ai-harness/config/reviewer.json` when deployed. In the source `ai-harness-toolset` repo, the equivalent source config is `config/reviewer.json`. Use another model only when the user explicitly overrides it.
- Do not introduce root `codex-review-input.md` or root `codex-review-result*.json` files.
- The canonical machine-readable result is `log/review/<run-id>/result.json`, hand-authored per `docs/REVIEW_RESULT_CONTRACT.md` after `result.md` exists.
- `scripts/review-verify.ps1 -RequireResult` is the binding check, and is run only after both `result.md` and `result.json` are present.
- A reviewer verdict does not approve commit, push, publish, merge, or release.
- For robust Windows/PowerShell automation, a future post-MVP adapter should follow the legacy `-File` wrapper pattern. Do not use `-Command` for such a wrapper. A project-local Codex adapter is a post-MVP candidate, not part of the current MVP.
