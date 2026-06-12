# Current Milestones

The post-MVP **remaining-order** milestones, carried 1:1 from `docs/decisions/POST_MVP_PLAN.md` §11. This is the current routing view of the numbered order; the authority for the order itself (and the rule that reordering / adding / removing a step needs separate scoped approval) remains `docs/decisions/POST_MVP_PLAN.md` §11. Per-step status detail lives in git history (the former install-update STATUS/DEFERRED ledgers) and in `docs/install-update/install-update_spec.md` + `install-update_backlog.md`; "what to do next" is answered on demand (`rules/docs-working-model/docs-working-model.md`, *On-demand status-briefing model*), not from a committed active queue.

> The numbering below is preserved exactly as in `docs/decisions/POST_MVP_PLAN.md` §11. It is not reordered, extended, or trimmed here.

| # | Milestone | Status | Authority / detail |
|---|---|---|---|
| 1 | Install/update operating model finalized (model as then source-of-truth) | done — baseline checkpoint | current invariants: `docs/install-update/install-update_spec.md`; the then model doc + ledger row IU-08: git history |
| 2 | Manual global activation / controlled materialization — global behavior validation (four-axis) | done | ledger row IU-10 (git history); `docs/decisions/POST_MVP_PLAN.md` §11 step 2 |
| 3 | Install/update implementation (operating model §3–§5 of the then model doc) | partial-progress closeout; deferred remainder open | ledger row IU-11 (git history); deferred rows IU-D-01/02/03: `docs/install-update/install-update_backlog.md` |
| 4 | Install/update validation (Tier A / Tier B) | done — closed | ledger row IU-12 (git history); `docs/decisions/POST_MVP_PLAN.md` §11.1 |
| 5 | `ai-harness-toolset` self-adoption | done — closed (resolved HEAD `8293878d`, apply 2026-05-25) | self-adoption posture: `docs/install-update/install-update_spec.md`; ledger row IU-13: git history |
| 6 | Post-MVP closeout decision | done — closed | `docs/decisions/DECISIONS.md` "Post-MVP closeout" block; `docs/decisions/POST_MVP_PLAN.md` §11 step 6 |

Operations backlog track (open items consolidated in `docs/install-update/install-update_backlog.md`) runs parallel to this numbered order; its items support step 2 / step 5.
