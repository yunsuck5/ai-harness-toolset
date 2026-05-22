# Next Actions

The **active queue** only — what is being worked now and the single next thing after it. This file deliberately does not duplicate the full backlog (that lives in `docs/backlog/`) and does not restate the whole remaining roadmap order (that lives in `docs/roadmap/POST_MVP_PLAN.md` §11). Keeping this short is the point: it must not blur "the current next single action."

---

## Active now

**Nothing is auto-selected.** The **docs taxonomy / source-of-truth reset** (additive `docs/current/` entrypoints, low-risk archive moves, `POST_MVP_PLAN.md` decomposition, roadmap contract route/relabel, backlog consolidation, README routing, protected-area stale-wording audit) has been **applied, committed, and pushed to `origin/main`** and is no longer in progress. The next single milestone action is a pending user decision (below) — it is not auto-started.

## Candidate next actions (per POST_MVP_PLAN §11 — user-selected, sequencing is a pending decision)

The remaining numbered roadmap work is governed by `docs/roadmap/POST_MVP_PLAN.md` §11 and routed (with status) in `docs/roadmap/CURRENT_MILESTONES.md`; deferred items with reopen conditions are in `docs/systems/install-update/DEFERRED.md`. Step 4 install/update validation is closed, but two items still precede a clean "next single action" and their order is a pending user decision (see below):

1. **Step 3 install/update implementation — deferred remainder** (`docs/roadmap/global-install-update/STEP3_INSTALL_UPDATE_DECISION_GUIDE.md` §13.2): git-url actual network fetch, source-cut actual handling, actual global/user filesystem apply, etc. These remain open in the numbered order even though Step 4 closed.
2. **Step 5 self-adoption** (`docs/roadmap/GLOBAL_INSTALL_UPDATE_MODEL.md` §9, `POST_MVP_PLAN.md` §11 step 5): `ai-harness-toolset` self-adoption. Not started; requires a separate scoped, explicit user-approved goal.

Do not assert either of the above as "the" next single action until the user sequences them — `POST_MVP_PLAN.md` §11 is the authority for the numbered order.

## Standing constraints on every action above

- All actual global / user filesystem mutation (global `current/` refresh, managed-block apply, Claude skill install/update) requires a separate explicit user-approved scoped step.
- Commit / push / publish / merge / release always require explicit user approval; no review verdict auto-approves them.

---

## Pending user decisions

- Sequencing of the Step 3 deferred remainder (`STEP3_INSTALL_UPDATE_DECISION_GUIDE.md` §13.2) relative to Step 5.
- Timing of global `current/` / managed-block / skill refresh for any source changes landed since the last global apply.
