# AI Harness Toolset — Scope

## Project nature

ai-harness-toolset is a project-local deterministic toolset.

It is not:

- an installer
- a rollback framework
- a global config manager
- an orchestrator
- a self-hosting workflow engine
- a Claude / SuperClaude / Superpowers dependency
- an MCP-first product

## Source repo vs target project payload

The source repo is the development home of this toolset. The current adoption model is the **shared / global stable runtime ToolRoot** (channel 3): lifecycle scripts run from a global stable install at `%USERPROFILE%\.claude\ai-harness-toolset\current`, resolved per invocation, and no payload is copied into the target project. Channel resolution, mode boundaries, and the global install / update model invariants are canonical in the install-update domain spec `docs/install-update/install-update_spec.md` (the former global-invocation contract and operating model docs are preserved in git history). The payload mapping below describes the **legacy project-local copy mode** only, and is not the primary source-of-truth for current channel-3 adoption judgment.

In the legacy project-local copy mode (channel 5) — still supported for backward compatibility, but not the recommended adoption shape for new projects — only `config/`, `scripts/`, `snippets/`, and `templates/` are copied into a `.ai-harness/` payload at the target project root.

| Source repo path | Target project path (legacy channel 5 copy mode) |
|---|---|
| `config/` | `<project-root>/.ai-harness/config/` |
| `scripts/` | `<project-root>/.ai-harness/scripts/` |
| `snippets/` | `<project-root>/.ai-harness/snippets/` |
| `templates/` | `<project-root>/.ai-harness/templates/` |

## Subsystems

The runtime output is partitioned by subsystem and is never mixed with payload:

- `<project-root>/log/evidence/` — evidence captures
- `<project-root>/log/review/` — review packets

These are generated artifacts. They are not part of the toolset payload.

## Path concepts

- `ProjectRoot` — the root of the project being operated on.
- `ToolRoot` — the root of the ai-harness-toolset files, resolved per invocation by the channel chain (specified in `docs/install-update/install-update_spec.md`; implemented in `scripts/lib/path.ps1`). In the current shared / global mode it is the channel 3 global stable install (`%USERPROFILE%\.claude\ai-harness-toolset\current`); in source-repo dogfooding it is the repo root; in the legacy project-local copy mode it is `<project-root>/.ai-harness/`.
- `ProjectLogRoot` — `<ProjectRoot>/log`.

## Cross-cutting boundaries

- CLI/runtime dependency boundary is canonical in `docs/policies/CLI_ENVIRONMENT_ASSUMPTIONS.md`.
- `<project-root>/log/` is the runtime factual record root. Generated records are preserved for inspection and traceability; later corrections are captured as new records under the relevant subsystem contract.
- The review record model is specified in `docs/review/review_spec.md` (the review domain spec-of-record).

## Out of scope

The following are explicitly out of scope for this toolset:

- installer roadmap
- rollback framework roadmap
- global config mutation roadmap
- self-hosting orchestrator roadmap
