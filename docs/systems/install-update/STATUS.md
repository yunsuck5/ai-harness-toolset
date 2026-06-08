# install-update — system status

Current state board for the install / update / global-adoption system: current posture + compact completed ledger + accepted residual risks + pointers. The **install execution** contract is `INSTALL.md`; the operating **model/design** is `docs/systems/install-update/GLOBAL_INSTALL_UPDATE_MODEL.md`; the uninstall design + as-built reference is `docs/systems/install-update/UNINSTALL_LIFECYCLE_DESIGN.md`.

- Routing for "which doc answers which question": `docs/current/REPO_READING_GUIDE.md` (Q1).
- Open work: `docs/systems/install-update/BACKLOG.md`. Deferred (with reopen conditions): `docs/systems/install-update/DEFERRED.md`.
- Remaining roadmap order (steps 1–6): `docs/roadmap/CURRENT_MILESTONES.md`.
- Decision-rationale record: `docs/decisions/POST_MVP_PLAN.md` (§1–§9). Detailed phase / dogfood / incident / closeout narrative and full per-commit completed text are preserved in **git history** (commit pointers in the ledger below).

## Current state

- **The install/update/uninstall lifecycle subsystem is in LTS maintenance** (closed at `main` HEAD `69ef433`, confirmatory Pester 440/440; ledger IU-14). The main PC (primary work machine) natural-language lifecycle retest — update / uninstall / clean install — was subsequently cleared under explicit per-action approval (ledger IU-15).
- **Lifecycle entrypoint split (intended architecture, not a merged mega-CLI):** `scripts/install-global.ps1` (fresh install), `scripts/update-global.ps1` (existing-install update → underlying `scripts/install-update.ps1 -Mode update-source`), `scripts/uninstall-global.ps1` (footprint-zero teardown), and `scripts/activate-global.ps1` (generic activation apply: two managed blocks + one mirror per source skill, Batch 2C-0). Activation apply stays a **separate explicit step** — a natural-language update does not auto-apply it.
- **Default adoption shape:** shared / global stable runtime ToolRoot (channel 3) — lifecycle scripts run from `%USERPROFILE%\.claude\ai-harness-toolset\current`, resolved per invocation; runtime output under the target's `<project-root>/log/`. Legacy project-local copy mode (channel 5) is backward-compatibility only.
- **Recovery = reinstall-first** (detection-only, deterministic overwrite from trusted source identity = resolved commit SHA); payload integrity = per-file manifest + completeness marker; managed-block paths = replace (`apply-managed-block.ps1`) / remove (`-Remove`) / first-time insertion (`-Insert`).
- Change discipline: further lifecycle changes require a scoped `/goal` + Codex review gate (no drive-by edits); no expansion into an installer-framework / wizard / doctor / repair / health-check class without separate scoped approval (`INSTALL.md` §11).
- **Deployed runtime extension activation-surface policy** (governance; single home `GLOBAL_INSTALL_UPDATE_MODEL.md` §8A): any source-managed deployed runtime extension (skills, future hooks / extension types) must be runtime-mirrored and verified — payload copy alone is not "installed"; a missing/drifted runtime destination after install/update is a failure; uninstall must reclaim owned surfaces without orphaning. Activation surfaces resolve generically via `scripts/lib/activation-surface.ps1` (two managed blocks + one `canonical-overwrite` mirror per source skill `snippets/claude-skills/*/SKILL.md`); apply / verify / uninstall all flow through that resolver. Current shipped skills `ai-harness-review` + `ai-harness-brief` → concrete surface count 4. Adding / removing an extension goes through the change discipline above.

## Completed ledger

Compact ledger. "Detail" points to the authoritative source; full historical narrative (lifecycle phases / dogfood / incident / closeout; per-commit completed text) is preserved in **git history** (see the "Closed at" commit pointers).

| ID | Item | Closed at | Current meaning | Detail |
|---|---|---|---|---|
| IU-01 | Global adoption operating-layer direction decided | — | shared/global operating layer is the preferred direction; `.ai-harness/` copy is not the default shape | `docs/decisions/GLOBAL_ADOPTION_DECISION.md` §1, §4 |
| IU-02 | Managed-block marker (`AI_HARNESS_TOOLSET_GLOBAL`) applied to snippets | — | canonical marker form governs CLAUDE.md/AGENTS.md managed-block apply | `GLOBAL_ADOPTION_DECISION.md` §6 |
| IU-03 | Claude skill global adopt/update/removal procedure documented | — | procedure exists for skill lifecycle | `docs/user_guide/GLOBAL_ADOPTION_PROCEDURE.md` |
| IU-04 | ToolRoot/ProjectRoot path-handling audit documented | — | path resolution channels + self-target/dogfooding collision audited; decisions now carried in the invocation contract + path lib | `docs/contracts/global-invocation/SHARED_GLOBAL_INVOCATION_CONTRACT.md`, `scripts/lib/path.ps1` |
| IU-05 | Shared/global invocation contract designed (D1–D9) | — | channel chain + as-built invocation contract | `docs/contracts/global-invocation/SHARED_GLOBAL_INVOCATION_CONTRACT.md` |
| IU-06 | Shared/global mode implemented (8 split units) | `bd0ac83`,`9130c68`,`8234bf1`,`df09bf5`,`dadff4d`,`67430c4`,`14ce6c9`,`bebe7ab`/`043b0e0` | source-side path/invocation behavior in place; NOT actual global activation | `SHARED_GLOBAL_INVOCATION_CONTRACT.md` §6 |
| IU-07 | Clean-target smoke criteria SC1–SC7 defined + full run PASS | `85433e5`,`9af5f62`,`24d2010` | smoke baseline; SC5 full Codex CLI path; `<SourceRepoRoot>` read-only invariant held | git history (commits in Closed at) |
| IU-08 | Global install/update/self-adoption operating model documented | — | current source-of-truth for the model (execution SoT = `INSTALL.md`) | `docs/systems/install-update/GLOBAL_INSTALL_UPDATE_MODEL.md` |
| IU-09 | Deployable payload hygiene (docs-dependency zero) | `f8e698e` | deployable roots carry no source-repo docs dependency; clean post-refresh global invocation smoke PASS | `docs/decisions/POST_MVP_PLAN.md` §10 |
| IU-10 | Step 2 closeout — global behavior validation (four-axis) | `d557580` baseline | global entrypoint / ToolRoot·ProjectRoot split / target footprint / runtime artifact location bound to existing evidence | `docs/decisions/POST_MVP_PLAN.md` §10, §11 step 2 |
| IU-11 | Step 3 install/update automation — partial-progress closeout | `c055ea5`,`bb9b832`,`f11ed27`,`84d1126`,`3bff209`,`9cf2000`,`1273afe`,`9308f3d` (+carry) | anchored decisions 3-0..3-6, temp-only skeleton, dry-run, manifest+marker, git-url min source acquisition, source-cut deferred-with-boundary, dogfooding final shape, D-atomicity reinstall-first | `docs/systems/install-update/STEP3_INSTALL_UPDATE_DECISION_GUIDE.md` §13.1 |
| IU-12 | **Step 4 install/update validation — closed** | resolved HEAD `0a07d90` (+`63ca6ec`) | Tier A fixture-local 100/100 PASS; Tier B real installed-state on mainpc + vanilla pc PASS (cross-binding + source fidelity verified) | `docs/decisions/POST_MVP_PLAN.md` §10 / §11 step 4 + §11.1 |
| IU-13 | **Step 5 self-adoption — closed** | resolved HEAD `8293878d` (apply 2026-05-25) | base payload `0a07d90`→`8293878d` via `INSTALL.md` §2A AI-guided operational install (no productized wrapper); activation surfaces already byte-identical (no-op steady-state); operational smoke PASS | `INSTALL.md` §2A; `POST_MVP_PLAN.md` §10/§11 step 5; git history |
| IU-B-08 | Uninstall / teardown lifecycle | `2fe5328`,`d43f784`,`fc1c6a7` | footprint-zero `uninstall-global.ps1` (preflight-all-then-act; temp-finalizer trampoline); isolated-machine real `-Apply` + clean-reinstall dogfood cleared; post-uninstall 0-pair reinstall boundary closed by IU-B-09 | `UNINSTALL_LIFECYCLE_DESIGN.md` (§13 dogfood); git history |
| IU-B-09 | Fresh-install entrypoint split + first-time managed-block insertion | code+tests | `install-global.ps1` / `update-global.ps1` + `Add-ManagedBlock` / `apply-managed-block.ps1 -Insert`; restores the deterministic fresh-install path (not an installer framework); IU-B-09.1 routes operator-facing primary = `update-global.ps1`; notebook natural-language routing dogfood cleared | `INSTALL.md` §6.1/§7.1.1/§10/§11(b); git history |
| IU-B-10 | Uninstall package-discovery docs hardening | docs/template/test | installed root README "Uninstalling this install" section (discovery of `current\scripts\uninstall-global.ps1`, Codex target set, block-only `AGENTS.md`→0-byte normal); root cause = discovery failure, not a code bug; snippets untouched; main-PC retest effective | `UNINSTALL_LIFECYCLE_DESIGN.md` §14; git history |
| IU-B-12 | Install bootstrap-clone cleanup enforcement | docs/template/test | `INSTALL.md` §6.1 fresh-install "Operator bootstrap clone cleanup 규칙" (auto-delete on success, don't ask; operator-workflow rule, not mechanized); root cause = discipline gap, not a code bug; snippets untouched; main-PC retest effective | `INSTALL.md` §6.1; git history |
| IU-14 | Install/update lifecycle LTS readiness (subsystem closeout) | `main` HEAD `69ef433` (Pester 440/440) | the subsystem entered LTS maintenance; **subsystem-only** decision (NOT whole-project LTS, NOT Phase 4b complete, NOT by itself a primary-machine apply claim) | git history; the whole-project Step 6 closeout is a separate decision — `docs/decisions/DECISIONS.md` "Post-MVP closeout" block |
| IU-15 | Main PC lifecycle retest (post-IU-B-10/IU-B-12) | — (docs/status closeout) | primary-machine update / uninstall / clean-install cleared under explicit per-action approval; supersedes "primary unmutated" wording for the main PC; per-environment separate-approval boundary unchanged | git history |

## Operational closeout ledger

Closed operational-quality items that originated in the operations backlog. Full closeout text is preserved in **git history**; this is the compact status ledger.

| ID | Item | Closed at | Current meaning | Detail |
|---|---|---|---|---|
| IU-OPS-01 | PowerShell smoke invocation quoting hardening | `c183c6b` | (W) wrapper `scripts/smoke/invoke-review-cycle.ps1` + Pester test; (R)/(S) not adopted | git history |
| IU-OPS-02 | Managed block marker detection (whole-line trim match) | — | marker counting algorithm fixed in `GLOBAL_ADOPTION_DECISION.md` §6 | git history |
| IU-OPS-03 | Global instruction file path semantics (Codex vs Claude; forbidden `.claude\AGENTS.md`) | — | valid destinations + forbidden path settled; docs/snippet wording aligned | git history |
| IU-OPS-04 | Channel 3 smoke validation closeout (CH3-A/B/C) | — | CH3 observations recorded at closeout; CH3-D still deferred | git history |
| IU-OPS-05 | Activation managed-block apply tooling hardening | — | reinstall-first activation tooling closeout | git history |

(Aggregate digest reproducibility closeout is ledgered as IU-11. "Brief / Chatlog location reconciliation" is a brief-system closeout — `docs/systems/brief/STATUS.md`.)

## Accepted residual risks (LTS maintenance)

Each retains its documented reopen condition; none is an LTS-readiness blocker.

- **Phase 4b / IU-B-07 — RETIRED** (one-shot natural-language update completion / safe activation auto-apply): removed from the post-MVP work list, not handled in the LTS version. Activation as a **separate explicit step** is the retained intended behavior; auto-applying activation crosses a global-mutation auto-approval boundary this retirement closes (not implemented; no claim it is feasible or safe). Reopen only by a separate explicit decision. Tombstoned in `BACKLOG.md` IU-B-07; idea-only detail `IDEAS.md` item 1.
- **Primary / main work machine real apply** — a per-environment **separate-explicit-approval boundary by design**. The main PC apply has since been performed under per-action approval (IU-15), but one environment's dogfood does not auto-authorize another's apply, and no future apply on any machine is auto-authorized.
- **Deferred residue** stays deferred with reopen conditions (`DEFERRED.md`): IU-D-01 git-url hardening residue, IU-D-02 source-cut actual handling (detection-only now), IU-D-07 packaging, IU-D-08 literal `?` (0x3F) encoding regression gate, and the `-AcquisitionClonePath` / URL-normalization decision.
- **Optional hygiene** stays optional / non-blocking (`BACKLOG.md` open candidates IU-B-01..06): smoke evidence preservation, channel-5/channel-3 copy-model docs reconciliation, `lib/path.ps1` edge-case hardening, evidence-wording polish, long-lived-docs commit-hash hygiene.
- **D8 external test signal** — the `verify-ps1.Tests.ps1` AC-VPS1-D8-* fixture fragility (system `core.autocrlf` + native-exe stderr promotion under `$ErrorActionPreference = 'Stop'`) is **resolved**: the git fixtures were migrated to the `Invoke-NativeProcess` containment shim (`scripts/lib/native-process.ps1`; mitigation home `docs/policies/POWERSHELL_POLICY.md`), and the full Pester suite is green on a `core.autocrlf=true` machine. **Narrowed residual (non-blocking):** the verify-ps1 Step F lint still *allows* the merged-stderr discard form in `tests/**` (a lint-scope decision that blocks only capture-for-use reintroduction, not an assertion the discard form is a true mitigation under EAP=Stop), and the remaining git-setup fixture builders use that guarded discard form (they set `core.autocrlf/safecrlf false` first, so the abort-path warning is suppressed — form stays fragile, practical risk lowered). **Reopen** only by a separate decision to tighten the Step F lint / policy or migrate the remaining guarded fixtures to `Invoke-NativeProcess`. (full incident / resolution detail in git history + `POWERSHELL_POLICY.md`.)

## Non-claims (what the LTS closeout and retest do NOT assert)

- Not a whole-project LTS declaration: the IU-14 subsystem closeout was a scoped portion of the broader roadmap Step 6, not itself the project-wide closeout, and it closes the install/update lifecycle subsystem only. (The whole-project post-MVP closeout has since been recorded as a *separate* decision — `docs/decisions/DECISIONS.md` "Post-MVP closeout" block. That separate decision likewise authorizes no global / user mutation, implementation, or release without a further explicit scoped step.)
- Not a "Phase 4b complete" claim (IU-B-07 is RETIRED, not done).
- Does **not** authorize any future global / user filesystem mutation (`%USERPROFILE%\.claude` / `.codex`, managed-block apply, skill install) without a separate explicit user-approved scoped step.
