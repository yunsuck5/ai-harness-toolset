# ai-harness-toolset

Project-local deterministic toolset for Claude / Codex workflows.

- ai-harness-toolset is a project-local deterministic toolset.
- It is not an orchestrator.
- It is not an installer.
- It is copy-only / CLI-only / project-local.
- Source repo folders map to target `.ai-harness/` payload.
- Runtime output root is `<project-root>/log/`.
- Legacy knowledge is explicitly transferred, not wholesale copied.
- No global install.
- No global rollback.
- No automatic CLAUDE.md / AGENTS.md mutation.

## Source repo to target payload mapping

| Source repo | Target payload |
|---|---|
| `config/` | `<project-root>/.ai-harness/config/` |
| `scripts/` | `<project-root>/.ai-harness/scripts/` |
| `snippets/` | `<project-root>/.ai-harness/snippets/` |
| `templates/` | `<project-root>/.ai-harness/templates/` |

## Runtime output

Generated at runtime under `<project-root>/log/`:

- `log/chatlog/` — session chat logs (see `docs/CHATLOG_CONTRACT.md`)
- `log/evidence/` — evidence captures (see `docs/EVIDENCE_CONTRACT.md`)
- `log/review/<run-id>/` — review packets and review records (see `docs/REVIEW_RESULT_CONTRACT.md`)

## Documentation

See `docs/` for scope, environment assumptions, tooling position, PowerShell policy, reviewer config policy, legacy knowledge transfer, decisions, and migration inventory summary.
