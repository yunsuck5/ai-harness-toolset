# docs/roadmap/ — Index & Milestone Routing

`docs/roadmap/` is a **milestone routing layer only**. After the access-pattern restructure (2026-05-23) it contains exactly two files — this `INDEX.md` and `CURRENT_MILESTONES.md`. It holds no design, model, decision, contract, audit, or planning bodies; those were relocated to their access-pattern homes (see below). The docs placement orientation map is `docs/README.md` (binding placement rules → `rules/docs-working-model.md`); this INDEX is a routing note that follows it and does not redefine it.

This INDEX's existence does not by itself approve any implementation, source/doc mutation, install/update/restore, global/user filesystem mutation, or commit/push/publish/merge/release/adoption.

## 1. Where current state lives

- install/update/global-adoption current state → `docs/systems/install-update/STATUS.md` + `DEFERRED.md`
- review → `docs/systems/review/STATUS.md`; brief → `docs/systems/brief/STATUS.md` + `DEFERRED.md`
- overall entrypoint → `docs/current/REPO_READING_GUIDE.md` (question→read-first routing); current progress / remaining work / next action is answered on demand (`docs/policies/DOCS_OPERATING_MODEL.md` §6), not from a committed mirror (the former `docs/current/PROJECT_STATE.md` / `NEXT_ACTIONS.md` mirrors were removed)
- post-MVP numbered remaining order routing view → `docs/roadmap/CURRENT_MILESTONES.md` (authority = `docs/decisions/POST_MVP_PLAN.md` §11)

## 2. Relocated docs (formerly in `docs/roadmap/`)

The former root-level roadmap docs now live in their access-pattern scope folders. Each relocated design/model/record doc carries a top routing banner to its system STATUS; current status lives in the system STATUS docs, not in those design docs.

| Doc | New location |
|---|---|
| post-MVP decision record + numbered-order authority (§11) | `docs/decisions/POST_MVP_PLAN.md` |
| operating-layer / managed-block decision | `docs/decisions/GLOBAL_ADOPTION_DECISION.md` |
| install/update operating model/design (execution SoT = `INSTALL.md`) | `docs/systems/install-update/GLOBAL_INSTALL_UPDATE_MODEL.md` |
| Step 3 implementation planning guide | `docs/systems/install-update/STEP3_INSTALL_UPDATE_DECISION_GUIDE.md` |
| shared/global invocation contract (D1–D9) | `docs/contracts/global-invocation/SHARED_GLOBAL_INVOCATION_CONTRACT.md` |
| review effort/cost guide | `docs/policies/REVIEW_EFFORT_GUIDE.md` |
| skill global adopt/update/remove procedure | `INSTALL.md` §10; `docs/systems/install-update/STATUS.md` IU-03 |

## 3. Remaining roadmap doc

- `CURRENT_MILESTONES.md` — the §11 numbered-order status routing view (authority = `docs/decisions/POST_MVP_PLAN.md` §11).

## 4. Former topic namespace — `global-install-update/` (dissolved)

`docs/roadmap/global-install-update/` was once a temporary topic namespace holding `STEP3_INSTALL_UPDATE_DECISION_GUIDE.md`. In the risk-resolution pass (2026-05-23) the STEP3 guide moved to `docs/systems/install-update/STEP3_INSTALL_UPDATE_DECISION_GUIDE.md`, so the namespace was emptied and **dissolved**. `docs/roadmap/` now has no topic subfolders. If a future large, parent-subordinate planning guide ever needs a subfolder again, that is a separate scoped decision governed by `docs/README.md`'s placement policy — not auto-approved by this INDEX.

## 5. Codex review gate

Any source/doc change under `docs/roadmap/` goes through the normal Codex review gate (`scripts/review-prepare.ps1` → `scripts/review-run.ps1` → `scripts/review-verify.ps1 -RequireResult`). A verdict (`yes` / `no` / `yes with risk`) does not auto-approve commit/push/publish/merge/release/adoption; all mutation/global apply/commit/push after a verdict is an explicit user decision.

## 6. Source-of-truth relationship

- The docs placement orientation map is `docs/README.md` (binding placement rules → `rules/docs-working-model.md`); question→read-first routing lives in `docs/current/REPO_READING_GUIDE.md`, and current status lives in the per-system `docs/systems/<system>/STATUS.md`.
- This INDEX is a routing note for `docs/roadmap/` only; it does not override any relocated doc's contract/decision.
