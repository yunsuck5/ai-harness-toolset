# CLAUDE.md snippet (manual copy)

This snippet may be manually copied into a project's CLAUDE.md by the user.

- Do not auto-mutate the global / root CLAUDE.md.
- Use the project-local log root at `<project-root>/log/`.
- Keep `log/review/`, `log/evidence/`, and `log/chatlog/` separate.
- Use `.ai-harness/scripts/` only within the project root.
- PowerShell IO must follow `docs/POWERSHELL_POLICY.md`.
- `.ps1` source files must be UTF-8 with BOM + CRLF.
- Temporary `.ps1` execution files must follow the same rule.
- Do not create a root `codex-review-input.md`.
- Commit and push require explicit user approval.

## Manual reviewer invocation

This is a manual recipe, not a project-local adapter. Use it as the recommended example only after confirming local `codex exec --help` once.

- Current MVP does not ship a `run-codex-review.ps1` adapter or `review-run` wrapper. Reviewer execution happens outside the toolset after `review-prepare`.
- `codex exec` is the non-interactive Codex subcommand. Interactive `codex` requires a TTY and is not appropriate for non-interactive Claude Code shells.
- PowerShell / Claude Code shell example:

  ```
  $runId = "<run-id>"
  $model = "<model-from-config>"
  Get-Content -Raw -LiteralPath "log/review/$runId/input.md" |
    codex --ask-for-approval never exec --sandbox read-only --model $model -c web_search=disabled --output-last-message "log/review/$runId/result.md" -
  ```

- `--output-last-message` writes the final reviewer message to `result.md`. Avoid stdout redirection as the default. If the installed CLI supports only the short form `-o`, substitute `-o "log/review/$runId/result.md"` based on local `codex exec --help`.
- `--ask-for-approval never` is a top-level Codex flag and must appear **before** the `exec` subcommand. Codex CLI 0.125.0's `exec` parser rejects `codex exec --ask-for-approval ...` as an unexpected argument. If the installed Codex CLI accepts the flag in no position, stop and use a real terminal or an approved fallback.
- `<model-from-config>` comes from `<project-root>/.ai-harness/config/reviewer.json` when deployed. In the source `ai-harness-toolset` repo, the equivalent source config is `config/reviewer.json`. Use another model only when the user explicitly overrides it.
- Do not write root `codex-review-input.md` or root `codex-review-result*.json`.
- After `result.md` exists, hand-author `log/review/<run-id>/result.json` per `docs/REVIEW_RESULT_CONTRACT.md` (`runId` / `targetPath` / `targetSha256` / `sourceHead` from `meta.json`; `inputSha256` and `resultMarkdownSha256` from the actual files; `createdAtUtc` in the exact contract shape).
- Run `scripts/review-verify.ps1 -RequireResult` only after both `result.md` and `result.json` exist.
- For robust Windows/PowerShell automation, a future post-MVP adapter should follow the legacy `-File` wrapper pattern. Do not use `-Command` for such a wrapper.
- A reviewer verdict does not approve commit, push, publish, merge, or release.
