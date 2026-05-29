# install-update — uninstall / teardown lifecycle design

> **Design-only / not implemented.** This document specifies the *design* of the uninstall lifecycle. It is **not** an implementation, and nothing here authorizes execution.
>
> - **No `scripts/uninstall-global.ps1` exists.** The entrypoint named throughout is the documented design target, not a shipped script.
> - **No `Remove-ManagedBlock` primitive exists.** Managed-block removal depends on a primitive that is not implemented (see §4).
> - **No real uninstall / dry-run / apply has been run.** No global/user filesystem mutation, snapshot, or manifest has been produced from this design.
> - Promotion to implementation requires the standard gate: a backlog entry (`BACKLOG.md` IU-B-08), a separate scoped `/goal`, and a Codex review gate. See §10.
>
> **Provenance.** Distilled from the advisory parallel-investigation report (out-of-repo `polishing/install/20260529-uninstall-lifecycle-report.md`, review task `20260529-uninstall-lifecycle-design`). That report is an advisory artifact, not source-of-truth; only the policies and open decisions are carried here. Where this design and the report diverge, this document governs.

## 1. Scope and relationship to install/update/activation

Uninstall is the teardown counterpart to the install / update (`INSTALL.md` §6/§7, `scripts/install-update.ps1`) and activation (`INSTALL.md` §10, `scripts/activate-global.ps1`) flows. It is **not** a symmetric inverse of install: removal splits into two classes with fundamentally different safety models, mirroring the two apply classes (`INSTALL.md` §9.1 / §10).

**Separate entrypoint — do not fold into install/update.** Uninstall is designed as a standalone entrypoint `scripts/uninstall-global.ps1`, parallel to `scripts/activate-global.ps1`, **not** a new mode on `scripts/install-update.ps1`. Rationale:

- `install-update.ps1`'s mutation surface is deliberately narrow (`inspect`/`verify`/`update-source`) with a hard production guard against stray mutation flags (`Assert-NoMutationPath`). Adding a destructive teardown mode would broaden that surface and blur its source-of-truth (the install metadata cross-binding).
- Uninstall's destructive footprint, finalizer trampoline (§3), and footprint-zero success criterion (§2) are unlike anything in the install/update flow; keeping them in a separate script keeps each entrypoint single-purpose and independently reviewable.

## 2. Success criterion — global ai-harness footprint zero

Uninstall succeeds **iff the global/user ai-harness-toolset footprint is reduced to zero**, while every non-target (§7) is left untouched:

1. Install root `%USERPROFILE%\.claude\ai-harness-toolset\` — absent (including `current/`, `install.json`, `payload-manifest.json`, `payload-marker.json`, the managed root `README.md`, and any in-root run-evidence tree).
2. Skill mirror `%USERPROFILE%\.claude\skills\ai-harness-review\` — absent.
3. Claude managed-block surface `%USERPROFILE%\.claude\CLAUDE.md` — **zero** `AI_HARNESS_TOOLSET_GLOBAL` marker pairs (the file itself may remain, carrying the user's marker-outside content).
4. Codex managed-block surface `%USERPROFILE%\.codex\AGENTS.md` (or `%CODEX_HOME%\AGENTS.md`; `AGENTS.override.md` precedence per `scripts/lib/activation-surface.ps1`) — **zero** marker pairs (file may remain).

Footprint-zero for the Codex managed-block target is defined over the **effective** surface chosen by the shared resolver (the same one activation applies to), not over every Codex file. Whether a stale marker pair sitting in a *non-effective* Codex file (e.g. an `AGENTS.md` shadowed by an `AGENTS.override.md`) must also be cleared is left as an open decision (§11, O7); the default here targets only the effective surface so uninstall mirrors what activation actually wrote.

"Footprint zero" is the *verified* end state, not merely "delete commands issued". Because the install-root deletion is delegated to a finalizer trampoline (§3), the footprint-zero verification for target (1) is the finalizer's responsibility; the main entrypoint verifies targets (2)–(4).

## 3. Self-deletion problem and the temp finalizer trampoline

**Problem.** Uninstall can be invoked from *inside* the installed global payload — i.e. the running script is `%USERPROFILE%\.claude\ai-harness-toolset\current\scripts\uninstall-global.ps1`. On Windows a process cannot reliably delete the directory tree that contains its own executing script files (open/locked handles). A naive in-process recursive delete of the install root would therefore fail or leave a partial tree precisely in the common case.

**Solution — temp finalizer trampoline.** Split uninstall into a main entrypoint and a detached finalizer that lives outside the install root:

### 3.1 Main entrypoint (`scripts/uninstall-global.ps1`) responsibilities

The main entrypoint does **only**:

1. **Preflight (all surfaces, no mutation).** Resolve all four targets via the shared resolver (`scripts/lib/activation-surface.ps1`) plus the install-root footprint enumeration (§5). Apply the preflight-all-then-act discipline (mirrors `activate-global.ps1`): if any fail-fast condition holds (unexpected install-root content, malformed/ambiguous marker, pre-existing `.amb-backup`), **remove nothing** and report `uninstall_blocked`.
2. **Managed-block removal** of the two instruction-file surfaces (§4) — marker-span excision only, outside content preserved.
3. **Skill mirror removal** — delete `%USERPROFILE%\.claude\skills\ai-harness-review\` only (§6).
4. **Create and launch the temp finalizer**, passing it the resolved install-root path and the parent process id, then **exit**. The main entrypoint does **not** delete the install root itself.

Targets (2)–(4 launch) all happen outside the install root and are not blocked by the running process's own file handles.

### 3.2 Temp finalizer responsibilities

The finalizer is a small self-contained script copied to a temp location (e.g. under `%TEMP%`) and launched detached. It:

1. **Waits for the parent process to exit** (poll the passed parent pid until gone), so the install-root scripts are no longer loaded.
2. **Deletes the global install root**, re-applying the same expected-footprint enumeration + unexpected-content fail-fast guard (§5) and the path-normalization leaf/parent guard (§5) defensively before deleting.
3. **Verifies absence** of the install root (footprint-zero for target (1)).
4. **Self-cleans best-effort.** The finalizer attempts to remove its own temp copy last. Self-cleanup failure is non-fatal to the uninstall outcome, but the finalizer **reports the exact temp path** so the operator can remove it manually.

### 3.3 Trampoline invariants

- The finalizer never runs while the parent is alive (no race on the install-root scripts).
- The finalizer re-guards the install-root path itself (it does not blindly trust the path handed in); a path that fails the §5 guard aborts the delete and reports, rather than deleting an unexpected location.
- The finalizer's temp copy is the only acceptable runtime clutter of the uninstall flow; its path is always reported on self-cleanup failure and is not treated as a canonical artifact.

## 4. Managed-block removal — marker-span excision, not file deletion

The instruction-file surfaces (`CLAUDE.md`, effective `AGENTS.md`) carry user-owned content **outside** the `AI_HARNESS_TOOLSET_GLOBAL` marker pair. Removal therefore **excises only the marker-bounded span (BEGIN..END, marker lines inclusive)** and preserves everything else byte-for-byte. The file is **never deleted**, even if excision leaves it empty (deleting a user-owned file would be over-reach).

**Required (not-yet-implemented) primitive.** Today `scripts/lib/managed-block.ps1` exposes `Set-ManagedBlock` (replace/insert) but **no `Remove-ManagedBlock`**. Removal must not be faked as "`Set-ManagedBlock` with an empty snippet" — that leaves an empty marker pair, violating footprint-zero. A new deterministic `Remove-ManagedBlock` primitive is required. Note the marker-count branch ordering: `Resolve-ManagedBlockSpan` itself fail-fasts on 0 pairs, but the 0-pair state must be an idempotent no-op (not a failure) for removal. So the primitive first counts markers via `Find-ManagedBlockMarkers` — 0 pairs → no-op return; 2+/incomplete/ordering-violation → fail-fast; exactly 1 → call `Resolve-ManagedBlockSpan` to get the span and excise it. It does not call the exact-1 resolver before establishing that exactly one pair exists.

**State machine** (per surface):

| Marker state | Behavior |
|---|---|
| 0 pairs | **Idempotent no-op** (`absent`) — never adopted, or already removed. Not a failure. |
| exactly 1 pair | Excise BEGIN..END inclusive + normalize adjacent blank lines; preserve all other bytes. File retained even if emptied. |
| 2+ pairs / incomplete (one marker missing) / malformed / nested | **Fail-fast** — report, do not edit the file (same posture as `apply-managed-block.ps1`). At the orchestrator level this is a **preflight** fail-fast that blocks the *whole* apply (`uninstall_blocked`, §8/§9), not a per-surface "proceed with the others" condition. |

**Safety mechanisms reused from apply** (`scripts/apply-managed-block.ps1` / `INSTALL.md` §10): UTF-8-no-BOM read/write, BOM-prefixed target refused, U+FFFD corruption-sentinel gate, a pre-write `.amb-backup` with rollback on any failure, and a post-write verify. The verify's *success criterion differs*: apply verifies "destination block == snippet block"; removal verifies "**zero marker pairs remain**".

**Pre-existing `.amb-backup`.** A leftover `<target>.amb-backup` (signalling a prior apply/rollback that did not close cleanly) is detected in preflight and is a **fail-fast / report-only** condition for that surface — it may be the sole copy of the user's original bytes, so uninstall does not overwrite or auto-delete it (consistent with `apply-managed-block.ps1`'s refusal to overwrite an existing backup). Its disposition is a separate user decision.

## 5. Install-root removal — enumerate expected footprint, fail-fast on unexpected

Install-root removal is a canonical-overwrite-class teardown (no user content inside), but it is **not** a broad blind recursive delete of `%USERPROFILE%\.claude\ai-harness-toolset\`. Because the target lives under `.claude`, the cost of an over-broad delete is high. Policy:

1. **Path guard on every destructive op.** Normalize with `[System.IO.Path]::GetFullPath` (collapsing `.` / `..`), then require the leaf to be exactly `ai-harness-toolset` and the parent to be exactly `.claude`. `.claude` itself, `skills/` and its parent, and any path failing this guard are never deleted. (Same shape as `activate-global.ps1`'s forbidden-path guard.)
2. **Expected-footprint enumeration.** Enumerate the install root and classify each entry against the known managed footprint: `current/`, `install.json`, `payload-manifest.json`, `payload-marker.json`, root `README.md`, and the in-root run-evidence tree (e.g. `log/install-update/`).
3. **Unexpected content → fail-fast.** If the install root contains anything outside the expected footprint, **abort and report** rather than deleting it. The operator resolves the unexpected content explicitly; uninstall does not silently sweep it.
4. **Delete then verify absence.** Only when the footprint matches expectations, remove the install root and verify its absence (footprint-zero for target (1)). Already-absent is an idempotent no-op success.

The actual root deletion executes in the finalizer (§3.2); this enumeration/guard is applied both in the main-entrypoint preflight (gate before any removal) and again defensively in the finalizer (before the delete).

## 6. Skill mirror removal

Delete the skill directory `%USERPROFILE%\.claude\skills\ai-harness-review\` only, then verify absence. This is the direct application of the existing skill-removal rule already documented in `INSTALL.md` §10 ("Skill adoption 규칙" → removal): propose the `<name>/` directory and its file list, on approval delete **only that directory** (no files outside it), verify absence; the source repo's `snippets/claude-skills/<name>/` is unaffected. Sibling skills under `skills/` and the `skills/` parent are never touched (§7). Already-absent is an idempotent no-op success.

## 7. Non-targets (never touched)

Uninstall is a **global/user** teardown of the ai-harness footprint and explicitly does **not** touch:

- **Project-local `<ProjectRoot>/log/`** — Brief (`log/brief/`), Chatlog (`log/chatlog/`), review records (`log/review/`), evidence (`log/evidence/`). These are user runtime work products, not install footprint. Global uninstall never operates on any project root.
- **Source repo / ToolRoot clone** — the repository the user installed from (and any `-ToolRoot` / `AI_HARNESS_TOOL_ROOT` clone). Uninstall removes the *installed* footprint, not the source.
- **Sibling skills** under `%USERPROFILE%\.claude\skills\` other than `ai-harness-review/`.
- **Marker-outside instruction content** in `CLAUDE.md` / `AGENTS.md`, and the instruction files themselves (§4).
- **Non-toolset files** under `.claude` / `.codex`, and those directories themselves.
- **Project-root managed blocks** (project-specific adoption per `INSTALL.md` §10) — a separate explicit scope, not part of global uninstall.
- The forbidden path `%USERPROFILE%\.claude\AGENTS.md` is never created and therefore never a removal target; the forbidden-path guard is nevertheless retained on the uninstall path.

## 8. Dry-run / apply / verify separation

Mirrors `activate-global.ps1` and the inspect/apply split of the install flow:

- **Dry-run (default, no `-Apply`).** Read-only. Enumerate every target and classify each as `present` / `absent` / `blocked` (malformed marker, unexpected install-root content, pre-existing `.amb-backup`). Show exactly what would be removed and excised. No write, no finalizer launch. Terminal status `uninstall_preview`.
- **Apply (`-Apply`).** Preflight-all-then-act: if any surface is in a fail-fast state, remove nothing (`uninstall_blocked`). Otherwise perform managed-block excision + skill removal, then create/launch the finalizer and exit. Approval is **command-implied** (the explicit `-Apply` invocation), with an optional `-ConfirmInteractive` two-choice (Yes/No) selector for direct-terminal use (no third option, no timeout auto-yes). This is a global/user filesystem mutation and is bound by `INSTALL.md` §10 approval boundaries.
- **Verify (post-removal).** The main entrypoint verifies targets (2)–(4) (skill dir absent; zero marker pairs in both instruction files). The finalizer verifies target (1) (install root absent). Footprint-zero (§2) holds only when all four verify clean.

### 8.1 Status vocabulary (design draft — pending `INSTALL.md` §13 alignment)

This is a draft vocabulary for the standalone uninstall entrypoint, analogous to `activate-global.ps1`'s `activationStatus`. Final naming and any `INSTALL.md` §13 integration are an open decision (§9, O6).

| Status | Meaning |
|---|---|
| `uninstall_preview` | Dry-run; all targets classified, nothing removed. |
| `uninstall_finalizer_launched` | Apply: targets (2)–(4) removed + verified, install-root deletion delegated to the launched finalizer (terminal for the main entrypoint). |
| `uninstalled` | Footprint-zero verified (finalizer-reported end state for target (1) plus the main entrypoint's (2)–(4)). |
| `uninstall_blocked` | Preflight fail-fast (unexpected install-root content / malformed-ambiguous marker / pre-existing `.amb-backup`); nothing removed. |
| `uninstall_partial` | Some surfaces removed, at least one not (e.g. a managed-block rollback after the skill dir was already removed); honest per-surface report, no cross-surface transaction. |
| `uninstall_verify_failed` | A removal was performed but a post-removal absence/zero-pair verify failed. |
| `uninstall_finalizer_cleanup_failed_with_leftover` | Finalizer completed the uninstall but could not remove its own temp copy; the exact temp path is reported. |
| `failed` | General failure not covered above. |

## 9. Failure policy

Two distinct failure tiers — do not conflate them:

- **Preflight tier (statically detectable → blocks the whole apply, removes nothing).** Every statically-detectable fail-fast condition is evaluated in the main entrypoint's preflight (§3.1, §8) under preflight-all-then-act: if **any** holds, **nothing is removed** and the run reports `uninstall_blocked`. There is no "block this surface but proceed with the others" path for these conditions. The preflight conditions are: a malformed / ambiguous / 2+ / incomplete / nested marker on **any** managed-block surface, unexpected install-root content (§5), and a pre-existing `.amb-backup` (§4).
- **Post-preflight tier (runtime failure after preflight passed → per-surface partial).** Only failures that preflight could not predict — e.g. a managed-block excision that passed preflight but threw at write time and rolled back, after the skill dir was already removed — produce a partial state. These follow `activate-global.ps1`'s per-surface (non-transactional) model: report per-surface results plus the aggregate `uninstall_partial`, never a fused cross-surface rollback. `uninstall_partial` therefore arises **only** from this tier, never from a preflight-detectable condition.

Specific conditions:

- **Malformed / ambiguous marker (any surface)** — preflight tier: fail-fast in preflight, **whole apply blocked** (`uninstall_blocked`), no surface removed, all files untouched. (Resolves the earlier ambiguity: a bad instruction-file marker does not let skill / install-root removal proceed into a partial state.)
- **Unexpected install-root content** — preflight tier: fail-fast in preflight, nothing removed (`uninstall_blocked`); the operator resolves it explicitly (§5).
- **Pre-existing `.amb-backup`** — preflight tier: fail-fast / report-only, never auto-deleted (§4). Disposition is a separate user decision; the whole apply is blocked until resolved.
- **Already-absent targets** — idempotent no-op success. Uninstall must be safely re-runnable.
- **Post-preflight runtime failure** — per-surface partial (`uninstall_partial`) as above; honest per-surface report, no cross-surface transaction.
- **Post-removal verify failure** — a removal completed but the absence / zero-pair verify did not confirm footprint-zero (`uninstall_verify_failed`).
- **Finalizer self-cleanup failure** — non-fatal to the uninstall outcome; report the exact temp path (`uninstall_finalizer_cleanup_failed_with_leftover`).

## 10. Governance — §11(b) deterministic narrow entrypoint candidate

`INSTALL.md` §11's self-imposed boundary invariant requires that introducing a new entrypoint be a deliberate, scoped redefinition of §11 (a deterministic narrow entrypoint must not grow into the §11(a) productization/uninstaller-framework class). Accordingly:

- `INSTALL.md` §11(b) now lists **uninstall (`scripts/uninstall-global.ps1`)** as a deterministic narrow entrypoint **candidate**, design-doc'd here and **not yet implemented**. A large/interactive uninstaller framework, doctor/repair teardown, or any productized uninstaller remains §11(a) out-of-scope.
- This document is the design step. Implementation still requires: `BACKLOG.md` IU-B-08 entry, a separate scoped `/goal`, and a Codex review gate (same promotion gate as other §11(b) entrypoints).

## 11. Open decisions (require user sign-off before implementation)

- **O1.** After managed-block excision leaves an instruction file empty — retain the file (this design's recommendation) vs delete it.
- **O2.** `Remove-ManagedBlock` placement/name — a new function in `scripts/lib/managed-block.ps1` plus a wrapper, symmetric with `apply-managed-block.ps1`.
- **O3.** Install-root removal — confirmed here as enumerate-expected + fail-fast (defensive) over a clean recursive delete; confirm the expected-footprint set (esp. the run-evidence tree shape).
- **O4.** Finalizer mechanics — temp location, parent-exit wait strategy (poll interval / timeout), and detached-launch method on Windows PowerShell 5.1.
- **O5.** Uninstall status vocabulary (§8.1) — final names and whether/how they integrate with `INSTALL.md` §13 vs staying an `activate-global`-style standalone vocabulary.
- **O6.** Whether uninstall should also offer a project-scope teardown (project-root managed blocks / project-local skills) as a *separate* explicit mode — currently out of scope for global uninstall (§7).
- **O7.** Whether footprint-zero must also clear a stale marker pair in a *non-effective* Codex file (an `AGENTS.md` shadowed by an `AGENTS.override.md`, or vice versa). Default (§2): target only the effective resolver surface; clearing non-effective stale blocks would need an explicit decision.

## 12. Relationship to other surfaces

- `INSTALL.md` — operative install/activation contract; §11(b) carries the uninstall narrow-entrypoint candidate, §9.1/§10 the two mutation/removal classes and managed-block/skill rules this design reuses.
- `docs/systems/install-update/STATUS.md` — records this design doc under the remaining-lifecycle (uninstall) item.
- `docs/systems/install-update/BACKLOG.md` — IU-B-08 is the implementation-candidate entry pointing here.
- `docs/systems/install-update/GLOBAL_INSTALL_UPDATE_MODEL.md` — operating model; if/when uninstall is implemented, the model doc is updated then (not in this design batch).
