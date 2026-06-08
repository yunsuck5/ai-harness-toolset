# docs/decisions/ — Active Decision Records

This folder holds **active decision records** — read when checking "what was decided and why" for decisions that still carry current authority. Superseded/historical decisions are preserved in git history.

| File | Scope |
|---|---|
| `DECISIONS.md` | active policy decisions + MVP-closeout pointer (bootstrap/historical decisions were extracted out of this file and are preserved in git history) |
| `POST_MVP_PLAN.md` | post-MVP decision record (§1–§9) and the authority for the numbered remaining order (§11); current status lives in `docs/systems/**` and the numbered-order view `docs/roadmap/CURRENT_MILESTONES.md`, and "what's next" is answered on demand (`docs/policies/DOCS_OPERATING_MODEL.md` §6), which route to §11 |
| `GLOBAL_ADOPTION_DECISION.md` | operating-layer transition decision + managed-block marker policy (§6); install/update current status routes from `docs/systems/install-update/STATUS.md` |

## What does not belong here

Current status (→ `docs/systems/**`; question→read-first routing → `docs/current/REPO_READING_GUIDE.md`), contracts (→ `docs/contracts/`), execution policy (→ `docs/policies/`), and superseded/historical decisions (→ git history).
