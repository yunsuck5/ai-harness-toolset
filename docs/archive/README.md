# docs/archive — historical and superseded material

Files under `docs/archive/` are **historical or superseded** material. They record what was decided, attempted, or true at an earlier point in the project.

**Authority restriction.** Do not use anything under `docs/archive/` as current implementation, operation, install, or review guidance unless a task explicitly asks for historical context. When archive material disagrees with current source-of-truth, current source-of-truth wins, always.

**Current source-of-truth lives elsewhere:**

- `docs/current/` — `PROJECT_STATE.md` (top-level current summary), `SOURCE_OF_TRUTH.md` (question → authoritative document), `NEXT_ACTIONS.md` (active queue).
- `docs/systems/<system>/STATUS.md` — per-system current status (added by the roadmap/backlog routing batches of the docs taxonomy reset).
- The active contracts in `docs/` (e.g. `docs/contracts/review/REVIEW_RESULT_CONTRACT.md`, `docs/contracts/brief/BRIEF_CONTRACT.md`, `docs/contracts/chatlog/CHATLOG_CONTRACT.md`, `docs/contracts/evidence/EVIDENCE_CONTRACT.md`) and `INSTALL.md` for install/update execution.

## Layout

This directory is populated by the migration batches. Subfolders are created only when material is actually moved into them:

- `legacy-mvp/` — pre/early-MVP migration-era material.
- `superseded/` — designs and framings that a later decision replaced.
- `audits/` — completed read-only audit records.
- `old-roadmaps/` — historical roadmap / cursor narrative that has been decomposed into current entrypoints.
- `backlog/` — the original mixed backlog item bodies (`operations.md`, `review.md`) moved out of `docs/backlog/`; open work now lives self-contained in `docs/systems/*/BACKLOG.md` and closed items in the per-system `STATUS.md` ledgers, so these are historical provenance only.

An empty subfolder is not created in advance — its absence means nothing has been archived under it yet.
