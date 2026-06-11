# docs/policies/ — Task-Scoped Execution Policies

This folder holds **task-scoped AI/operator execution policies**: rules an agent follows *while doing a task in that policy's domain*. They are not always-on priming (the always-on payload lives in `snippets/**` / the adopted managed block and the repo-local root `CLAUDE.md` / `AGENTS.md`, not here) and not artifact contracts (→ `docs/contracts/`).

## Access pattern

Read a policy when your task touches its domain — each is **conditional**, not universal.

| File | Read when |
|---|---|
| `POWERSHELL_POLICY.md` | editing `.ps1` (encoding, EOL, file IO, collection-return rules) |
| `CLI_ENVIRONMENT_ASSUMPTIONS.md` | reasoning about CLI/runtime dependencies (PowerShell, Codex, Git tiers) |
| `REVIEWER_CONFIG_POLICY.md` | configuring or running the reviewer (config location, precedence, defaults, enforcement status) |
| `REVIEW_EFFORT_GUIDE.md` | deciding review effort/cost for a Codex review |
| `DOCS_OPERATING_MODEL.md` | orienting to the docs change/closeout model — its rationale/record (why top-down + single-home, the removed project-current mirror files) and the layer-role map. It is a non-authority record, **not** the operative rule: the rule itself (top-down flow, STATUS/BACKLOG shape, on-demand status-briefing, two-level closeout gate) lives on the active surface at `rules/docs-working-model/docs-working-model.md`, which the root `CLAUDE.md` / `AGENTS.md` *Docs trigger map* triggers before a docs change/closeout |

## What does not belong here

Always-on cross-cutting rules (those live in `snippets/**` / the global managed block or the repo-local root `CLAUDE.md` / `AGENTS.md`, not `docs/`), artifact/protocol contracts (→ `docs/contracts/`), and project philosophy (→ `docs/project/`).
