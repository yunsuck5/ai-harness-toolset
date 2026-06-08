# brief — system status

Current status for the Brief primitive. The **contract** is `docs/contracts/brief/BRIEF_CONTRACT.md`; the Brief↔Chatlog boundary is `docs/contracts/chatlog/CHATLOG_CONTRACT.md`. Routing: `docs/current/REPO_READING_GUIDE.md` (Q4). Deferred (BF Level 3): `docs/systems/brief/DEFERRED.md`.

## Current state

- **Canonical Brief = `<ProjectRoot>/log/brief/BRIEF.md`** (3rd reconciliation) — project-local, operator-local, source-control-excluded runtime artifact under `<ProjectRoot>/log/` (gitignored). Root `<ProjectRoot>/brief/` is rejected; any user-home operator-local runtime root is rejected.
- **BF Level = save/restore capability maturity, not a path.** BF Level 1/2 = manual save/restore discipline (operative now). BF Level 3 = deterministic automation = future scoped work (`DEFERRED.md`).
- `log/chatlog/current/resume.md` / `summary.md` are **not** canonical — failed intermediate / legacy migration source / deprecation candidate; not a restore source.

## Completed ledger

| ID | Item | Closed at | Current meaning | Detail |
|---|---|---|---|---|
| BR-01 | Narrow source-side primitive implemented | — | `scripts/brief-init.ps1` (seed), `scripts/brief-check.ps1` (validate), `scripts/brief-status.ps1`, `templates/brief/BRIEF.md`; writer destination == canonical Brief path | `docs/decisions/POST_MVP_PLAN.md` §3, §5; `docs/contracts/brief/BRIEF_CONTRACT.md` |
| BR-02 | Snippets aligned to 3rd-reconciliation framing | — | the snippets' Brief/Chatlog framing has since been minimized out (Batch 2) and the `## Brief` / `## Chatlog` sections **removed entirely by Batch 3** (`docs/systems/skills/STATUS.md` SK-05); the canonical-Brief / rejected-locations / deprecation-candidate framing now lives only in the docs contracts (`docs/contracts/brief/BRIEF_CONTRACT.md` / `docs/contracts/chatlog/CHATLOG_CONTRACT.md`) + the `ai-harness-brief` skill — the contract is authoritative over any applied managed block | `docs/decisions/POST_MVP_PLAN.md` §3, §10 |
| BR-03 | Target-payload source-side primitive smoke test | — | primitive is operable in a target | `docs/decisions/POST_MVP_PLAN.md` §3, §5 |

These mean the **narrow primitive** is operable — not that the full BF Level 3 capability exists.
