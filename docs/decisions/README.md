# docs/decisions/ — Active Decision Records

This folder holds **active decision records** — read when checking "what was decided and why" for decisions that still carry current authority. Superseded/historical decisions live in `docs/archive/`.

| File | Scope |
|---|---|
| `DECISIONS.md` | active policy decisions + MVP-closeout pointer (bootstrap/historical decisions are extracted to `docs/archive/legacy-mvp/BOOTSTRAP_DECISIONS.md`) |
| `POST_MVP_PLAN.md` | post-MVP decision record (§1–§9) and the authority for the numbered remaining order (§11); current status/next-action live in `docs/current/**`, `docs/systems/**`, and `docs/roadmap/CURRENT_MILESTONES.md`, which route to §11 |
| `GLOBAL_ADOPTION_DECISION.md` | operating-layer transition decision + managed-block marker policy (§6); install/update current status routes from `docs/systems/install-update/STATUS.md` |

## What does not belong here

Current status (→ `docs/systems/**`, `docs/current/`), contracts (→ `docs/contracts/`), execution policy (→ `docs/policies/`), and superseded/historical decisions (→ `docs/archive/`).
