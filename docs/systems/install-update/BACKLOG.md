# install-update — backlog (open candidates)

Open, not-yet-started install / update / operational candidates (v2 §9.2 — open work only). Each routes to the full text in `docs/backlog/operations.md`; that full text is the detailed source and is not duplicated here. None is approved for implementation; each needs a separate scoped goal + review. The parallel "operations backlog track" relationship to `POST_MVP_PLAN.md` §11 is noted in `docs/roadmap/CURRENT_MILESTONES.md`.

| ID | Open candidate | Source item | Note |
|---|---|---|---|
| IU-B-01 | Smoke evidence preservation | `docs/backlog/operations.md` "Smoke evidence preservation" | scope-defined; runbook-only / helper-script / archive-manifest choice deferred to a scoped goal |
| IU-B-02 | Project-local copy model docs vs global stable runtime ToolRoot model | `docs/backlog/operations.md` "Project-local copy model docs vs global stable runtime ToolRoot model" | docs-debt candidate (legacy channel-5 vs current channel-3 wording) |
| IU-B-03 | Path normalization edge-case hardening | `docs/backlog/operations.md` "Path normalization edge-case hardening" | `scripts/lib/path.ps1` edge-case hardening (cross-cutting: used by install + review) |
| IU-B-04 | Install validation report evidence hygiene | `docs/backlog/operations.md` "Install validation report evidence hygiene" | strongly-preserved polishing backlog; separate PASS verdict from anomalous wrapper signal in closeout reports |
| IU-B-05 | Snapshot auxiliary evidence exactness wording | `docs/backlog/operations.md` "Snapshot auxiliary evidence exactness wording" | wording-accuracy polishing for snapshot / evidence reports |
| IU-B-06 | Long-lived docs commit hash hygiene (cross-cutting) | `docs/backlog/operations.md` "Long-lived docs commit hash hygiene" | low-priority doc hygiene; keep literal commit hashes out of long-lived docs; spans roadmap + install docs |

Closed install/update/operational items are recorded in `docs/systems/install-update/STATUS.md` — the main milestones in the **Completed ledger** (IU-01..IU-12, incl. Aggregate digest reproducibility = IU-11) and the operations-backlog closeouts in the **Operational closeout ledger** (IU-OPS-01 PowerShell smoke invocation quoting hardening (W, `c183c6b`), IU-OPS-02 Managed block marker detection, IU-OPS-03 Global instruction file path semantics, IU-OPS-04 Channel 3 smoke validation closeout, IU-OPS-05 Activation managed-block apply tooling hardening). "Brief / Chatlog location reconciliation" is a brief-system closeout (`docs/systems/brief/STATUS.md`). All closed-item detail remains in `docs/backlog/operations.md` as historical record. Deferred items with reopen conditions: `docs/systems/install-update/DEFERRED.md`.
