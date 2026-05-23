# Current Milestones

The post-MVP **remaining-order** milestones, carried 1:1 from `docs/decisions/POST_MVP_PLAN.md` §11. This is the current routing view of the numbered order; the authority for the order itself (and the rule that reordering / adding / removing a step needs separate scoped approval) remains `docs/decisions/POST_MVP_PLAN.md` §11. Per-step status detail lives in `docs/systems/install-update/STATUS.md` and `docs/systems/install-update/DEFERRED.md`; the active queue is `docs/current/NEXT_ACTIONS.md`.

> The numbering below is preserved exactly as in `docs/decisions/POST_MVP_PLAN.md` §11. It is not reordered, extended, or trimmed here.

| # | Milestone | Status | Authority / detail |
|---|---|---|---|
| 1 | `docs/systems/install-update/GLOBAL_INSTALL_UPDATE_MODEL.md` finalized (model as current source-of-truth) | done — baseline checkpoint | `docs/systems/install-update/GLOBAL_INSTALL_UPDATE_MODEL.md`; STATUS IU-08 |
| 2 | Manual global activation / controlled materialization — global behavior validation (four-axis) | done | STATUS IU-10; `docs/decisions/POST_MVP_PLAN.md` §11 step 2 |
| 3 | Install/update implementation (`docs/systems/install-update/GLOBAL_INSTALL_UPDATE_MODEL.md` §3–§5) | partial-progress closeout; deferred remainder open | STATUS IU-11; DEFERRED IU-D-01/02/03; `docs/systems/install-update/STEP3_INSTALL_UPDATE_DECISION_GUIDE.md` §13 |
| 4 | Install/update validation (Tier A / Tier B) | done — closed | STATUS IU-12; `docs/decisions/POST_MVP_PLAN.md` §11.1 |
| 5 | `ai-harness-toolset` self-adoption (`docs/systems/install-update/GLOBAL_INSTALL_UPDATE_MODEL.md` §9) | deferred — not started | DEFERRED IU-D-04; `docs/systems/install-update/STATUS.md` "Self-adoption" |
| 6 | Post-MVP closeout decision | deferred | DEFERRED IU-D-05 |
| 7 | New GJMNet repo clean adoption (after step 5 + step 2) | deferred | DEFERRED IU-D-06; `docs/decisions/POST_MVP_PLAN.md` §7 |

Operations backlog track (`docs/archive/backlog/operations.md`) runs parallel to this numbered order; items 2·3 there support step 2 / step 5.
