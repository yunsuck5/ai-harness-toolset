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

The source repo is the development home of this toolset. When the toolset is copied into another project, only `config/`, `scripts/`, `snippets/`, and `templates/` are copied into a `.ai-harness/` payload at the target project root.

| Source repo path | Target project path |
|---|---|
| `config/` | `<project-root>/.ai-harness/config/` |
| `scripts/` | `<project-root>/.ai-harness/scripts/` |
| `snippets/` | `<project-root>/.ai-harness/snippets/` |
| `templates/` | `<project-root>/.ai-harness/templates/` |

## Subsystems

The runtime output is partitioned by subsystem and is never mixed with payload:

- `<project-root>/log/chatlog/` — session chat logs
- `<project-root>/log/evidence/` — evidence captures
- `<project-root>/log/review/` — review packets

These are generated artifacts. They are not part of the toolset payload.

## Path concepts

- `ProjectRoot` — the root of the project being operated on.
- `ToolRoot` — the root of the ai-harness-toolset files. In the source repo this is the repo root; after deployment it is `<project-root>/.ai-harness/`.
- `ProjectLogRoot` — `<ProjectRoot>/log`.

## Out of scope

The following are explicitly out of scope for this toolset:

- installer roadmap
- rollback framework roadmap
- global config mutation roadmap
- self-hosting orchestrator roadmap
