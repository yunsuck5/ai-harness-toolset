# Project State

Top-level current summary of `ai-harness-toolset`. This is a compact current entrypoint — it states what is closed, what is active now, and where the per-topic detail lives. It is not a history document and not a full closeout narrative; for those, follow the pointers.

Conflict rule: when this summary disagrees with the detailed source it points to, the detailed source wins. Routing of "which document answers which question" lives in `docs/current/SOURCE_OF_TRUTH.md`.

---

## Current active priority

The **docs taxonomy / source-of-truth reset** has been **applied, committed, and pushed to `origin/main`**: `docs/**` now separates current source-of-truth (`docs/current/`, per-system `docs/systems/<system>/STATUS.md`), roadmap, backlog, deferred, completed-ledger, and historical/superseded material (`docs/archive/`) instead of interleaving them. Its baseline was the Batch 0 audit (`polishing/docs_taxonomy_audit/docs_taxonomy_batch0_inventory_20260522.md`). The structural reset is no longer in progress, and these current entrypoints reflect the committed state.

There is **no auto-selected next active priority.** The next project action is chosen by the user (see `docs/current/NEXT_ACTIONS.md`). The numbered remaining order in `docs/roadmap/POST_MVP_PLAN.md` §11 still carries the Step 3 install/update implementation **deferred remainder** (`STEP3_INSTALL_UPDATE_DECISION_GUIDE.md` §13.2) ahead of Step 5 self-adoption; their sequencing is a pending user decision, not a settled next milestone.

---

## Completed milestones (compact ledger)

Compact per-system completed-ledgers live in the system status documents (`docs/systems/install-update/STATUS.md`, `docs/systems/review/STATUS.md`, `docs/systems/brief/STATUS.md`); the detailed commit-bound closeout narrative is archived at `docs/archive/old-roadmaps/POST_MVP_COMPLETED_NARRATIVE.md`. This is a one-line-each summary, not the narrative.

- **CLI-only MVP** — closed (`POST_MVP_PLAN.md` §1; `docs/DECISIONS.md` "MVP closeout").
- **Codex review subsystem** — operational, in maintenance mode; canonical review task/pass topology adopted (record = `<ProjectRoot>/log/review/<review-task-id>/pass-NN/{input.md,result.md}`). Contract: `docs/REVIEW_RESULT_CONTRACT.md`.
- **Brief narrow source-side primitive** — implemented (`scripts/brief-init.ps1`, `scripts/brief-check.ps1`, `scripts/brief-status.ps1`, `templates/brief/BRIEF.md`). This is not the full BF Level 3 capability. Contract: `docs/BRIEF_CONTRACT.md`.
- **Global adoption operating layer** — decided; shared / global stable runtime ToolRoot (channel 3) is the current default adoption shape (`docs/roadmap/GLOBAL_ADOPTION_DECISION.md`, `docs/roadmap/SHARED_GLOBAL_INVOCATION_CONTRACT.md`).
- **Global install / update / self-adoption operating model** — documented as current source-of-truth for the model (`docs/roadmap/GLOBAL_INSTALL_UPDATE_MODEL.md`). Install **execution** source-of-truth remains `INSTALL.md`.
- **Step 3 install / update automation** — partial-progress closeout: anchored decisions (3-0/3-1/3-2~3-5/3-6), temp-only install-pipeline skeleton, dry-run coverage, payload integrity manifest + completeness marker, git-url minimum source acquisition, source-cut decision (deferred-with-boundary), dogfooding enforcement final shape, D-atomicity reinstall-first policy. Deferred remainder: `STEP3_INSTALL_UPDATE_DECISION_GUIDE.md` §13.2.
- **Step 4 install / update validation** — **closed.** Tier A fixture-local determinism 100/100 PASS; Tier B real installed-state validation on two hosts (mainpc, vanilla pc) PASS, both converging to resolved HEAD `0a07d90`. Detail: `POST_MVP_PLAN.md` §10 / §11 step 4 + §11.1.

---

## Active / deferred top issues

- **docs taxonomy / source-of-truth reset** — applied, committed, and pushed to `origin/main`; not in progress as a structural reset, and no follow-on milestone is auto-selected.
- **Step 5 self-adoption** — not performed; deferred (`POST_MVP_PLAN.md` §11 step 5, `GLOBAL_INSTALL_UPDATE_MODEL.md` §9). No current implementation basis.
- **Step 6 post-MVP closeout decision** — deferred (`POST_MVP_PLAN.md` §11 step 6).
- **Step 7 GJMNet clean adoption** — deferred (`POST_MVP_PLAN.md` §7, §11 step 7).
- **Step 3 deferred remainder** — git-url actual network fetch, source-cut actual handling, actual global/user apply, etc. (`STEP3_INSTALL_UPDATE_DECISION_GUIDE.md` §13.2).
- **Operations backlog track** — parallel operational-quality items (`docs/backlog/operations.md`).

---

## Per-system status

Per-system current status lives in the system status documents below. They hold the compact completed-ledgers and deferred queues; the contracts and the model/design docs remain the authoritative sources they route to.

| Topic | System status | Authoritative contract / model |
|---|---|---|
| review | `docs/systems/review/STATUS.md` | `docs/REVIEW_RESULT_CONTRACT.md`, `docs/REVIEWER_CONFIG_POLICY.md`, `docs/roadmap/REVIEW_EFFORT_GUIDE.md` |
| install-update | `docs/systems/install-update/STATUS.md` + `DEFERRED.md` | `INSTALL.md` (execution), `docs/roadmap/GLOBAL_INSTALL_UPDATE_MODEL.md` (model), `STEP3_INSTALL_UPDATE_DECISION_GUIDE.md` (Step 3) |
| brief | `docs/systems/brief/STATUS.md` + `DEFERRED.md` | `docs/BRIEF_CONTRACT.md`, `docs/CHATLOG_CONTRACT.md` |
| self-adoption | `docs/systems/install-update/STATUS.md` "Self-adoption" (sub-topic) | `GLOBAL_INSTALL_UPDATE_MODEL.md` §9, `POST_MVP_PLAN.md` §11 step 5 (not implemented) |

The numbered remaining-order milestones (steps 1–7) are routed in `docs/roadmap/CURRENT_MILESTONES.md` (authority for the order itself: `POST_MVP_PLAN.md` §11).
