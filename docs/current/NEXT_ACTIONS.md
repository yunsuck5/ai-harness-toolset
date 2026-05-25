# Next Actions

The **active queue** only — what is being worked now and the single next thing after it. This file deliberately does not duplicate the backlog (open work lives in the per-system `docs/systems/*/BACKLOG.md`, routed by `docs/backlog/INDEX.md`; full historical bodies are in `docs/archive/backlog/`) and does not restate the whole remaining roadmap order (that lives in `docs/decisions/POST_MVP_PLAN.md` §11). Keeping this short is the point: it must not blur "the current next single action."

---

## Active now

**Nothing is auto-selected.** The **docs taxonomy / source-of-truth reset** (additive `docs/current/` entrypoints, low-risk archive moves, `docs/decisions/POST_MVP_PLAN.md` decomposition, roadmap contract route/relabel, backlog consolidation, README routing, protected-area stale-wording audit) has been **applied, committed, and pushed to `origin/main`** and is no longer in progress. The next single milestone action is a pending user decision (below) — it is not auto-started.

## Candidate next actions (per `docs/decisions/POST_MVP_PLAN.md` §11 — user-selected, sequencing is a pending decision)

The remaining numbered roadmap work is governed by `docs/decisions/POST_MVP_PLAN.md` §11 and routed (with status) in `docs/roadmap/CURRENT_MILESTONES.md`; deferred items with reopen conditions are in `docs/systems/install-update/DEFERRED.md`. Step 4 install/update validation is closed, and **Step 5 self-adoption is closed** at resolved HEAD `8293878d` (apply 2026-05-25; `docs/systems/install-update/STATUS.md` IU-13, "Self-adoption (Step 5) — performed"). The remaining candidate near-term work is:

1. **Step 3 install/update implementation — deferred remainder** (`docs/systems/install-update/STEP3_INSTALL_UPDATE_DECISION_GUIDE.md` §13.2): git-url actual network fetch, source-cut actual handling, etc. This remains open in the numbered order even though Step 4 and Step 5 closed.

Do not assert the above as "the" next single action until the user sequences it — `docs/decisions/POST_MVP_PLAN.md` §11 is the authority for the numbered order.

## Standing constraints on every action above

- All actual global / user filesystem mutation (global `current/` refresh, managed-block apply, Claude skill install/update) requires a separate explicit user-approved scoped step.
- Commit / push / publish / merge / release always require explicit user approval; no review verdict auto-approves them.

---

## Pending user decisions

- Whether to take up the Step 3 deferred remainder (`docs/systems/install-update/STEP3_INSTALL_UPDATE_DECISION_GUIDE.md` §13.2) as the next milestone.
- Timing of any future global `current/` / managed-block / skill refresh beyond the 2026-05-25 Step 5 closeout (`docs/systems/install-update/STATUS.md` IU-13).
