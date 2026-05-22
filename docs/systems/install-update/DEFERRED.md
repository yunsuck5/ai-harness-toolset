# install-update — deferred

Consciously-postponed items for the install / update / global-adoption system. Every entry has a **reopen condition** (v2 §9.3); an item without one is not deferred (it would be backlog, archive, or delete-candidate). Deferred ≠ backlog: these are postponed by decision, not merely not-yet-started.

All actual global / user filesystem mutation (global `current/` refresh, managed-block apply, Claude skill install/update) requires a separate explicit user-approved scoped step. Nothing here is auto-approved.

| ID | Deferred item | Deferred because | Reopen condition | Detail |
|---|---|---|---|---|
| IU-D-01 | Install/update automation deferred remainder — git-url actual network fetch / clone / credential / auth / proxy | current skeleton is local-clone + local-git(bare fixture) only; no external network reachability | a scoped goal to implement real network source acquisition is approved | `STEP3_INSTALL_UPDATE_DECISION_GUIDE.md` §13.2, §16.6 |
| IU-D-02 | Source-cut path actual handling | anchored as `deferred with exact boundary` (detection-only now; resolver detection / dispatcher non-process / STOP / byte-identity preserve) | a scoped goal to implement the reinstall/metadata-mutation handler is approved | `STEP3_INSTALL_UPDATE_DECISION_GUIDE.md` §17.5 |
| IU-D-03 | Actual global / user filesystem apply (global `current/` materialize/refresh, managed-block apply, Claude skill install/update) beyond Step 4 validation | Step 4 validated determinism; further routine apply is a separate global mutation | explicit user-approved scoped step for a specific apply | `INSTALL.md` §9–§11, `GLOBAL_ADOPTION_PROCEDURE.md` |
| IU-D-04 | Step 5 — `ai-harness-toolset` self-adoption | depends on the toolset operating itself via the global model; not started | a scoped, explicit user-approved self-adoption goal | `GLOBAL_INSTALL_UPDATE_MODEL.md` §9, `POST_MVP_PLAN.md` §11 step 5 |
| IU-D-05 | Step 6 — post-MVP closeout decision | kept as a deliberate roadmap step before GJMNet | reached after self-adoption (step 5) | `POST_MVP_PLAN.md` §11 step 6 |
| IU-D-06 | Step 7 — new GJMNet repo clean adoption | gated on Brief system / BF Level 3 / packaging direction being ready, and after self-adoption + global behavior validation | the three foundation items are ready and step 5 is done | `POST_MVP_PLAN.md` §7, §11 step 7 |
| IU-D-07 | `package-toolset.ps1` copy-bundle packaging | needed only if a packaging step is later required; boundary is sibling to adoption-mode decision | a scoped packaging goal is approved | `POST_MVP_PLAN.md` §6 |
| IU-D-08 | `literal ? (0x3F) non-increase` encoding regression gate | Step 4 base scope excludes it | a scoped goal adds the encoding regression gate | `POST_MVP_PLAN.md` §11.1.3 |

## Not deferred — explicitly not work candidates (out of scope by decision)

The following are **not** deferred items (no reopen condition is implied) and must not be read as postponed work. The payload-integrity minimum contract adopted the per-file manifest (`docs/backlog/operations.md` "Aggregate digest reproducibility" candidate (b), now closed); the alternatives below were decided **out of scope** in `STEP3_INSTALL_UPDATE_DECISION_GUIDE.md` §15.6 ("작업 후보 아님"):

- aggregate digest algorithm (candidate (a)),
- manifest `schemaVersion` bump migration writer,
- manifest external verification tool / linter,
- channel-3 active hook actual-implementation expansion, entrypoint-set finalize, target-adoption manifest.

Pursuing any of these would require a fresh scoped decision that first reopens the §15.6 out-of-scope stance — it is not on a deferred queue.
