# brief — deferred

Consciously-postponed Brief items. Every entry has a reopen condition (v2 §9.3). Nothing here is auto-approved; BF Level 3 implementation requires a separate design + scoped approval.

| ID | Deferred item | Deferred because | Reopen condition | Detail |
|---|---|---|---|---|
| BR-D-01 | BF Level 3 — deterministic save/update writer | manual BF Level 1/2 discipline is the current operating model; automation is allowed-but-unimplemented | a scoped BF Level 3 design + approval | `docs/decisions/POST_MVP_PLAN.md` §5; `docs/contracts/brief/BRIEF_CONTRACT.md` ("BF Level …") |
| BR-D-03 | BF Level 3 — stale warning + session-start guidance | same as BR-D-01 | BR-D-01 design approved | `docs/decisions/POST_MVP_PLAN.md` §5 |

**Retired (no longer deferred) — BR-D-02: BF Level 3 restore-offer source-side automation.** The unsolicited session-start restore-offer is **discarded entirely** (not future automation) — `docs/systems/skills/FUNCTION_LEVEL_SKILL_ARCHITECTURE_PLAN.md` §3 / Batch 2. An explicit, user-requested Brief restore remains a current manual capability (BF Level 1/2), so there is no restore-offer automation left to defer. Only the restore-offer component is retired; **BR-D-01 (deterministic save/update writer) and BR-D-03 (stale warning + session-start guidance) remain deferred.**

Explicitly **forbidden** under the BF Level 3 name (not deferred — disallowed): daemon, watcher, scheduler, `BF_STATE.json`-style separate state-machine file, automatic decision-maker (`docs/decisions/POST_MVP_PLAN.md` §5, §8).
