# install-update — deferred

Consciously-postponed items for the install / update / global-adoption system. Every entry has a **reopen condition** (v2 §9.3); an item without one is not deferred (it would be backlog, archive, or delete-candidate). Deferred ≠ backlog: these are postponed by decision, not merely not-yet-started.

All actual global / user filesystem mutation (global `current/` refresh, managed-block apply, Claude skill install/update) requires a separate explicit user-approved scoped step. Nothing here is auto-approved.

| ID | Deferred item | Deferred because | Reopen condition | Detail |
|---|---|---|---|---|
| IU-D-01 | Install/update automation git-url hardening residue — credential / auth / proxy / external network reachability / clone recovery / multi-cache / per-ref subdir / fetch retry / submodules / cache identity verification | minimum git-url path (install / update-source / restore, each performing a run-scoped fresh acquisition; `update-current` is intentionally unsupported for git-url per `INSTALL.md` §7) is implemented per `INSTALL.md` §2A and `docs/systems/install-update/STEP3_INSTALL_UPDATE_DECISION_GUIDE.md` §13.1 / §16, with local-git bare fixture tests; the hardening surface listed above is the deferred residue per `docs/systems/install-update/STEP3_INSTALL_UPDATE_DECISION_GUIDE.md` §16.6 | a scoped goal to implement git-url hardening (credential / auth / proxy / external network reachability / recovery) is approved | `docs/systems/install-update/STEP3_INSTALL_UPDATE_DECISION_GUIDE.md` §13.2, §16.6 |
| IU-D-02 | Source-cut path actual handling | anchored as `deferred with exact boundary` (detection-only now; resolver detection / dispatcher non-process / STOP / byte-identity preserve) | a scoped goal to implement the reinstall/metadata-mutation handler is approved | `docs/systems/install-update/STEP3_INSTALL_UPDATE_DECISION_GUIDE.md` §17.5 |
| IU-D-03 | Actual global / user filesystem apply (global `current/` materialize/refresh, managed-block apply, Claude skill install/update) beyond Step 4 validation | Step 4 validated determinism; further routine apply is a separate global mutation | explicit user-approved scoped step for a specific apply | `INSTALL.md` §9–§11, `docs/user_guide/GLOBAL_ADOPTION_PROCEDURE.md` |
| IU-D-04 | Step 5 — `ai-harness-toolset` self-adoption — **Resolved** at resolved HEAD `8293878d` (apply 2026-05-25; STATUS IU-13) | originally: depends on the toolset operating itself via the global model; not started | reopen condition met — a scoped, explicit user-approved self-adoption goal was applied (`INSTALL.md` §2A AI-guided operational install; no productized wrapper) | STATUS IU-13; `docs/systems/install-update/STATUS.md` "Self-adoption (Step 5) — performed"; `INSTALL.md` §2A |
| IU-D-05 | Step 6 — post-MVP closeout decision | kept as a deliberate roadmap step before GJMNet | reached after self-adoption (step 5) | `docs/decisions/POST_MVP_PLAN.md` §11 step 6 |
| IU-D-06 | Step 7 — new GJMNet repo clean adoption | gated on Brief system / BF Level 3 / packaging direction being ready, and after self-adoption + global behavior validation | the three foundation items are ready and step 5 is done | `docs/decisions/POST_MVP_PLAN.md` §7, §11 step 7 |
| IU-D-07 | `package-toolset.ps1` copy-bundle packaging | needed only if a packaging step is later required; boundary is sibling to adoption-mode decision | a scoped packaging goal is approved | `docs/decisions/POST_MVP_PLAN.md` §6 |
| IU-D-08 | `literal ? (0x3F) non-increase` encoding regression gate | Step 4 base scope excludes it | a scoped goal adds the encoding regression gate | `docs/decisions/POST_MVP_PLAN.md` §11.1.3 |

## Not deferred — explicitly not work candidates (out of scope by decision)

The following are **not** deferred items (no reopen condition is implied) and must not be read as postponed work. The payload-integrity minimum contract adopted the per-file manifest (`docs/archive/backlog/operations.md` "Aggregate digest reproducibility" candidate (b), now closed); the alternatives below were decided **out of scope** in `docs/systems/install-update/STEP3_INSTALL_UPDATE_DECISION_GUIDE.md` §15.6 ("작업 후보 아님"):

- aggregate digest algorithm (candidate (a)),
- manifest `schemaVersion` bump migration writer,
- manifest external verification tool / linter,
- channel-3 active hook actual-implementation expansion, entrypoint-set finalize, target-adoption manifest.

Pursuing any of these would require a fresh scoped decision that first reopens the §15.6 out-of-scope stance — it is not on a deferred queue.
