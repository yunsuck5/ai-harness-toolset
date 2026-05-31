# install-update — backlog (open candidates)

Open, not-yet-started install / update / operational candidates. **This file is the open-work entrypoint for the install-update subsystem** — each row (ID + candidate + direction note) is the triage-level entry, sufficient to scope a future goal. The original full analysis is preserved as historical provenance in `docs/archive/backlog/operations.md` (not a current dependency). None is approved for implementation; each needs a separate scoped goal + review. The parallel "operations backlog track" relationship to `docs/decisions/POST_MVP_PLAN.md` §11 is noted in `docs/roadmap/CURRENT_MILESTONES.md`.

## Open candidates

| ID | Open candidate | Direction (triage) | Historical provenance |
|---|---|---|---|
| IU-B-01 | Smoke evidence preservation | scope-defined; runbook-only / helper-script / archive-manifest choice deferred to a scoped goal | `docs/archive/backlog/operations.md` |
| IU-B-02 | Project-local copy model docs vs global stable runtime ToolRoot model | docs-debt candidate (legacy channel-5 vs current channel-3 wording reconciliation) | `docs/archive/backlog/operations.md` |
| IU-B-03 | Path normalization edge-case hardening (cross-cutting) | `scripts/lib/path.ps1` edge-case hardening; used by install + review | `docs/archive/backlog/operations.md` |
| IU-B-04 | Install validation report evidence hygiene | strongly-preserved polishing backlog; separate PASS verdict from anomalous wrapper signal in closeout reports | `docs/archive/backlog/operations.md` |
| IU-B-05 | Snapshot auxiliary evidence exactness wording | wording-accuracy polishing for snapshot / evidence reports | `docs/archive/backlog/operations.md` |
| IU-B-06 | Long-lived docs commit hash hygiene (cross-cutting) | low-priority doc hygiene; keep literal commit hashes out of long-lived docs; spans roadmap + install docs | `docs/archive/backlog/operations.md` |

## Closed / retired (tombstones)

One-line tombstones for ID continuity only. The authoritative closed record is the `docs/systems/install-update/STATUS.md` completed ledger; detailed narrative is in `docs/archive/old-roadmaps/INSTALL_UPDATE_LIFECYCLE_NARRATIVE.md` and the uninstall design doc. These are not open work.

- **[RETIRED]** IU-B-07 — one-shot natural-language update completion / safe activation auto-apply; removed from the post-MVP work list (2026-05-31), not implemented, reopen only by a separate explicit decision. See STATUS "Accepted residual risks"; idea-only detail `docs/systems/install-update/IDEAS.md` item 1.
- **[CLOSED]** IU-B-08 — uninstall / teardown lifecycle (footprint-zero `uninstall-global.ps1`; isolated-machine `-Apply` + clean-reinstall dogfood cleared). See STATUS ledger IU-B-08; design `docs/systems/install-update/UNINSTALL_LIFECYCLE_DESIGN.md` (§13); narrative §3.
- **[CLOSED]** IU-B-09 — fresh-install entrypoint split + first-time managed-block insertion (`install-global.ps1` / `update-global.ps1`; IU-B-09.1 routing; notebook routing dogfood cleared). See STATUS ledger IU-B-09; narrative §4–§5.
- **[CLOSED]** IU-B-10 — uninstall package-discovery docs hardening (installed-root README "Uninstalling this install" section; snippets untouched). See STATUS ledger IU-B-10; design §14; narrative §6.
- **[CLOSED]** IU-B-12 — install bootstrap-clone cleanup enforcement (`INSTALL.md` §6.1 fresh-install cleanup rule; snippets untouched, no code change). See STATUS ledger IU-B-12; narrative §6.

(There is no IU-B-11; the next free ID is IU-B-13.)

## Where closed/operational items are recorded

Closed install/update milestones and operations-backlog closeouts are in `docs/systems/install-update/STATUS.md` — the **Completed ledger** (IU-01..IU-13, IU-B-08/09/10/12, IU-14/IU-15) and the **Operational closeout ledger** (IU-OPS-01..05). The classification index is `docs/backlog/INDEX.md`. All closed-item full detail is preserved in `docs/archive/backlog/operations.md` (operations bodies) and `docs/archive/old-roadmaps/INSTALL_UPDATE_LIFECYCLE_NARRATIVE.md` (lifecycle phase/dogfood/incident/closeout narrative). Deferred items with reopen conditions: `docs/systems/install-update/DEFERRED.md`.
