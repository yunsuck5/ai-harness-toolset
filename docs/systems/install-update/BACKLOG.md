# install-update — backlog (open candidates)

Open, not-yet-started install / update / operational candidates. **This file is the open-work entrypoint for the install-update subsystem** — each row (ID + candidate + direction note) is the triage-level entry, sufficient to scope a future goal. The original full analysis is preserved as historical provenance in `docs/archive/backlog/operations.md` (not a current dependency). None is approved for implementation; each needs a separate scoped goal + review. The parallel "operations backlog track" relationship to `docs/decisions/POST_MVP_PLAN.md` §11 is noted in `docs/roadmap/CURRENT_MILESTONES.md`.

| ID | Open candidate | Direction (triage) | Historical provenance |
|---|---|---|---|
| IU-B-01 | Smoke evidence preservation | scope-defined; runbook-only / helper-script / archive-manifest choice deferred to a scoped goal | `docs/archive/backlog/operations.md` |
| IU-B-02 | Project-local copy model docs vs global stable runtime ToolRoot model | docs-debt candidate (legacy channel-5 vs current channel-3 wording reconciliation) | `docs/archive/backlog/operations.md` |
| IU-B-03 | Path normalization edge-case hardening (cross-cutting) | `scripts/lib/path.ps1` edge-case hardening; used by install + review | `docs/archive/backlog/operations.md` |
| IU-B-04 | Install validation report evidence hygiene | strongly-preserved polishing backlog; separate PASS verdict from anomalous wrapper signal in closeout reports | `docs/archive/backlog/operations.md` |
| IU-B-05 | Snapshot auxiliary evidence exactness wording | wording-accuracy polishing for snapshot / evidence reports | `docs/archive/backlog/operations.md` |
| IU-B-06 | Long-lived docs commit hash hygiene (cross-cutting) | low-priority doc hygiene; keep literal commit hashes out of long-lived docs; spans roadmap + install docs | `docs/archive/backlog/operations.md` |

Closed install/update/operational items are recorded in `docs/systems/install-update/STATUS.md` — the main milestones in the **Completed ledger** (IU-01..IU-12, incl. Aggregate digest reproducibility = IU-11) and the operations-backlog closeouts in the **Operational closeout ledger** (IU-OPS-01 PowerShell smoke invocation quoting hardening (W, `c183c6b`), IU-OPS-02 Managed block marker detection, IU-OPS-03 Global instruction file path semantics, IU-OPS-04 Channel 3 smoke validation closeout, IU-OPS-05 Activation managed-block apply tooling hardening). "Brief / Chatlog location reconciliation" is a brief-system closeout (`docs/systems/brief/STATUS.md`). All closed-item full detail is preserved in `docs/archive/backlog/operations.md` as historical record. Deferred items with reopen conditions: `docs/systems/install-update/DEFERRED.md`.
