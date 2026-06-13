# docs/policies/ — Task-Scoped Execution Policies

This folder holds **task-scoped AI/operator execution policies**: rules an agent follows *while doing a task in that policy's domain*. They are not always-on priming (the always-on payload lives in `snippets/**` / the adopted managed block and the repo-local root `CLAUDE.md` / `AGENTS.md`, not here) and not artifact contracts (the former artifact-contract layer was absorbed into the domain specs — `docs/review/review_spec.md` · `docs/install-update/install-update_spec.md`).

## Access pattern

Read a policy when your task touches its domain — each is **conditional**, not universal.

| File | Read when |
|---|---|
| `POWERSHELL_POLICY.md` | editing `.ps1` (encoding, EOL, file IO, collection-return rules) |
| `CLI_ENVIRONMENT_ASSUMPTIONS.md` | reasoning about CLI/runtime dependencies (PowerShell, Codex, Git tiers) |

The former reviewer policies (`REVIEWER_CONFIG_POLICY.md`, `REVIEW_EFFORT_GUIDE.md`) are **absorbed into the review domain spec** — read `docs/review/review_spec.md` (config invariants live with the active surface: `config/reviewer.schema.json` + `scripts/review-run.ps1`).

## What does not belong here

Always-on cross-cutting rules (those live in `snippets/**` / the global managed block or the repo-local root `CLAUDE.md` / `AGENTS.md`, not `docs/`), artifact/protocol contracts (absorbed into the domain specs), and project philosophy (→ `docs/project/`).
