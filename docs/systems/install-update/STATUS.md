# install-update — system status

Current status and completed-ledger for the install / update / global-adoption system. This is the current source-of-truth for "what is done and where the system stands"; the **install execution** contract remains `INSTALL.md`, and the operating **model/design** is `docs/systems/install-update/GLOBAL_INSTALL_UPDATE_MODEL.md`.

- Routing for "which doc answers which question": `docs/current/SOURCE_OF_TRUTH.md` (Q1).
- Deferred items (with reopen conditions): `docs/systems/install-update/DEFERRED.md`.
- Remaining roadmap order (steps 1–7): `docs/roadmap/CURRENT_MILESTONES.md`.
- Decision-rationale record and the full closeout narrative: `docs/decisions/POST_MVP_PLAN.md` (§1–§9 decisions) and `docs/archive/old-roadmaps/POST_MVP_COMPLETED_NARRATIVE.md` (detailed commit-bound closeout text).

## Current state

- Current default adoption shape: **shared / global stable runtime ToolRoot (channel 3)** — lifecycle scripts run from `%USERPROFILE%\.claude\ai-harness-toolset\current`, resolved per invocation; runtime output under the target's `<project-root>/log/`. Legacy project-local copy mode (channel 5) is supported for backward compatibility only.
- Install/update automation exists as a temp-only local-clone + git-url(local-git) skeleton with a payload integrity manifest + completeness marker; recovery policy is **reinstall-first** (detection-only, deterministic overwrite from trusted source identity = resolved commit SHA). Deferred remainder: `DEFERRED.md`.
- **Step 4 install/update validation is closed** (see ledger IU-12). Step 5 self-adoption is **not** performed (see "Self-adoption" below).

## Completed ledger

Compact ledger (v2 §9.1). "Detail" points to the authoritative narrative; full per-commit text is in `docs/archive/old-roadmaps/POST_MVP_COMPLETED_NARRATIVE.md` and `docs/decisions/POST_MVP_PLAN.md` §10.

| ID | Item | Closed at | Current meaning | Detail |
|---|---|---|---|---|
| IU-01 | Global adoption operating-layer direction decided | — | shared/global operating layer is the preferred direction; `.ai-harness/` copy is not the default shape | `docs/decisions/GLOBAL_ADOPTION_DECISION.md` §1, §4 |
| IU-02 | Managed-block marker (`AI_HARNESS_TOOLSET_GLOBAL`) applied to snippets | — | canonical marker form governs CLAUDE.md/AGENTS.md managed-block apply | `GLOBAL_ADOPTION_DECISION.md` §6 |
| IU-03 | Claude skill global adopt/update/removal procedure documented | — | procedure exists for skill lifecycle | `docs/user_guide/GLOBAL_ADOPTION_PROCEDURE.md` |
| IU-04 | ToolRoot/ProjectRoot path-handling audit documented | — | path resolution channels + self-target/dogfooding collision audited | `docs/archive/audits/TOOLROOT_PROJECTROOT_AUDIT.md` |
| IU-05 | Shared/global invocation contract designed (D1–D9) | — | channel chain + as-built invocation contract | `docs/contracts/global-invocation/SHARED_GLOBAL_INVOCATION_CONTRACT.md` |
| IU-06 | Shared/global mode implemented (8 split units) | `bd0ac83`,`9130c68`,`8234bf1`,`df09bf5`,`dadff4d`,`67430c4`,`14ce6c9`,`bebe7ab`/`043b0e0` | source-side path/invocation behavior in place; NOT actual global activation | `docs/contracts/global-invocation/SHARED_GLOBAL_INVOCATION_CONTRACT.md` §6 |
| IU-07 | Clean-target smoke criteria SC1–SC7 defined + full run PASS | `85433e5`,`9af5f62`,`24d2010` | smoke baseline; SC5 full Codex CLI path; `<SourceRepoRoot>` read-only invariant held | `docs/archive/audits/CLEAN_TARGET_SMOKE_CRITERIA.md` |
| IU-08 | Global install/update/self-adoption operating model documented | — | current source-of-truth for the model (execution SoT = `INSTALL.md`) | `docs/systems/install-update/GLOBAL_INSTALL_UPDATE_MODEL.md` |
| IU-09 | Deployable payload hygiene (docs-dependency zero) | `f8e698e` | deployable roots carry no source-repo docs dependency; clean post-refresh global invocation smoke PASS | `docs/decisions/POST_MVP_PLAN.md` §10 |
| IU-10 | Step 2 closeout — global behavior validation (four-axis) | `d557580` baseline | global entrypoint / ToolRoot·ProjectRoot split / target footprint / runtime artifact location bound to existing evidence | `docs/decisions/POST_MVP_PLAN.md` §10, §11 step 2 |
| IU-11 | Step 3 install/update automation — partial-progress closeout | `c055ea5`,`bb9b832`,`f11ed27`,`84d1126`,`3bff209`,`9cf2000`,`1273afe`,`9308f3d` (+carry) | anchored decisions 3-0/3-1/3-2~3-5/3-6, temp-only skeleton, dry-run, manifest+marker, git-url min source acquisition, source-cut deferred-with-boundary, dogfooding final shape, D-atomicity reinstall-first | `docs/systems/install-update/STEP3_INSTALL_UPDATE_DECISION_GUIDE.md` §13.1 |
| IU-12 | **Step 4 install/update validation — closed** | resolved HEAD `0a07d90` (+`63ca6ec` discipline) | Tier A fixture-local 100/100 PASS; Tier B real installed-state on mainpc + vanilla pc PASS (cross-binding + source fidelity verified); PV-1..4 triaged as non-repo-owned | `docs/decisions/POST_MVP_PLAN.md` §10 / §11 step 4 + §11.1 |

## Operational closeout ledger (from `docs/archive/backlog/operations.md`)

Closed operational-quality items that originated in the operations backlog. Detail (full closeout text) remains in `docs/archive/backlog/operations.md` as historical record; this is the compact status ledger.

| ID | Item | Closed at | Current meaning | Detail |
|---|---|---|---|---|
| IU-OPS-01 | PowerShell smoke invocation quoting hardening | `c183c6b` | (W) wrapper `scripts/smoke/invoke-review-cycle.ps1` + Pester test; (R)/(S) not adopted | `operations.md` "PowerShell smoke invocation quoting hardening" |
| IU-OPS-02 | Managed block marker detection (whole-line trim match) | — | marker counting algorithm fixed in `GLOBAL_ADOPTION_DECISION.md` §6 | `operations.md` "Managed block marker detection" |
| IU-OPS-03 | Global instruction file path semantics (Codex vs Claude; forbidden `.claude\AGENTS.md`) | — | valid destinations + forbidden path settled; docs/snippet wording aligned | `operations.md` "Global instruction file path semantics" |
| IU-OPS-04 | Channel 3 smoke validation closeout (CH3-A/B/C) | — | CH3 observations doc'd into `docs/archive/audits/CLEAN_TARGET_SMOKE_CRITERIA.md` §2A; CH3-D still deferred | `operations.md` "Channel 3 smoke validation closeout" |
| IU-OPS-05 | Activation managed-block apply tooling hardening | — | reinstall-first activation tooling closeout | `operations.md` "Activation managed-block apply tooling hardening" |

(Aggregate digest reproducibility closeout is ledgered as IU-11 above. "Brief / Chatlog location reconciliation" is a brief-system closeout — see `docs/systems/brief/STATUS.md`.)

## Self-adoption (Step 5) — not implemented

Self-adoption is tracked here as an install-update sub-topic rather than a separate near-empty system (v2 §6 anti-empty-skeleton). Status: **not performed.** Install/update validation (Step 4) is closed, but actual `ai-harness-toolset` self-adoption (`docs/systems/install-update/GLOBAL_INSTALL_UPDATE_MODEL.md` §9, `docs/decisions/POST_MVP_PLAN.md` §11 step 5) has not been done and requires a separate scoped, explicit user-approved goal. There is no current implementation basis. Deferred entry: `DEFERRED.md` (IU-D-04).
