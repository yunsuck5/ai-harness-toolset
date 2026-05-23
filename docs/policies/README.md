# docs/policies/ — Task-Scoped Execution Policies

This folder holds **task-scoped AI/operator execution policies**: rules an agent follows *while doing a task in that policy's domain*. They are not always-on priming (the always-on payload lives in `snippets/**` / the adopted managed block, not here) and not artifact contracts (→ `docs/contracts/`).

## Access pattern

Read a policy when your task touches its domain — each is **conditional**, not universal.

| File | Read when |
|---|---|
| `POWERSHELL_POLICY.md` | editing `.ps1` (encoding, EOL, file IO, collection-return rules) |
| `CLI_ENVIRONMENT_ASSUMPTIONS.md` | reasoning about CLI/runtime dependencies (PowerShell, Codex, Git tiers) |
| `REVIEWER_CONFIG_POLICY.md` | configuring or running the reviewer (config location, precedence, defaults, enforcement status) |
| `REVIEW_EFFORT_GUIDE.md` | deciding review effort/cost for a Codex review |

## What does not belong here

Always-on cross-cutting rules (those live in `snippets/**` / global managed block, not `docs/`), artifact/protocol contracts (→ `docs/contracts/`), release-facing user guides (→ `docs/user_guide/`), and project philosophy (→ `docs/project/`).
