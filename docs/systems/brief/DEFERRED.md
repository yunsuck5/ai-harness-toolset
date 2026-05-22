# brief — deferred

Consciously-postponed Brief items. Every entry has a reopen condition (v2 §9.3). Nothing here is auto-approved; BF Level 3 implementation requires a separate design + scoped approval.

| ID | Deferred item | Deferred because | Reopen condition | Detail |
|---|---|---|---|---|
| BR-D-01 | BF Level 3 — deterministic save/update writer | manual BF Level 1/2 discipline is the current operating model; automation is allowed-but-unimplemented | a scoped BF Level 3 design + approval | `POST_MVP_PLAN.md` §5; `docs/BRIEF_CONTRACT.md` ("BF Level …") |
| BR-D-02 | BF Level 3 — restore-offer source-side automation | depends on BR-D-01 deterministic writer | BR-D-01 design approved | `POST_MVP_PLAN.md` §5 |
| BR-D-03 | BF Level 3 — stale warning + session-start guidance | same as BR-D-01 | BR-D-01 design approved | `POST_MVP_PLAN.md` §5 |

Explicitly **forbidden** under the BF Level 3 name (not deferred — disallowed): daemon, watcher, scheduler, `BF_STATE.json`-style separate state-machine file, automatic decision-maker (`POST_MVP_PLAN.md` §5, §8).
