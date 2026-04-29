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
