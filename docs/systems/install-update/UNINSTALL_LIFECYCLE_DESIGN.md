# install-update — uninstall / teardown lifecycle (design + as-built)

> **Status: implemented (IU-B-08 batches 1–3); this document is the governing design AND the as-built reference.** The code matches the design below; where wording is dated "design draft", it has been reconciled to the actual implementation.
>
> - **`Remove-ManagedBlock` primitive — implemented** (batch 1, commit `2fe5328`) in `scripts/lib/managed-block.ps1`; the removal IO reuses `scripts/apply-managed-block.ps1 -Remove` (§4).
> - **Read-only dry-run target resolver — implemented** (batch 2, commit `d43f784`): `scripts/lib/uninstall-target.ps1` (`Get-UninstallPlan`) + `scripts/uninstall-global.ps1` (default dry-run).
> - **Destructive apply + temp finalizer — implemented** (batch 3, commit `fc1c6a7`): `scripts/uninstall-global.ps1 -Apply` + the self-contained `scripts/uninstall-finalizer.ps1`.
> - **Isolated non-primary machine real `-Apply` dogfood — CLEARED** (§13). The real apply + footprint-zero verification + clean reinstall were exercised against a real `%USERPROFILE%` install on an **isolated non-primary machine** only; the **primary work machine was not mutated** and a real **primary-machine `-Apply`** was a **separate, explicit approval boundary not performed as of this dogfood** — it has **since been performed on the main PC under explicit per-action approval** in the later main PC lifecycle retest (see the §13 "Update (main PC lifecycle retest ...)" note + `STATUS.md` completed-ledger IU-15; full narrative preserved in git history; the per-environment separate-approval boundary still stands). Before the dogfood, all behavior was exercised only in TestDrive / fixture sandboxes.
>
> **Provenance.** Distilled from an advisory parallel-investigation report (an out-of-repo, pre-commit local-scratch artifact — not source-of-truth and not a committed-doc pointer target); only the policies and decisions are carried here. Where this design and that report diverge, this document (reconciled to the implementation) governs.

## 1. Scope and relationship to install/update/activation

Uninstall is the teardown counterpart to the install / update (`INSTALL.md` §6/§7, `scripts/install-update.ps1`) and activation (`INSTALL.md` §10, `scripts/activate-global.ps1`) flows. It is **not** a symmetric inverse of install: removal splits into two classes with fundamentally different safety models, mirroring the two apply classes (`INSTALL.md` §9.1 / §10).

**Separate entrypoint — do not fold into install/update.** Uninstall is designed as a standalone entrypoint `scripts/uninstall-global.ps1`, parallel to `scripts/activate-global.ps1`, **not** a new mode on `scripts/install-update.ps1`. Rationale:

- `install-update.ps1`'s mutation surface is deliberately narrow (`inspect`/`verify`/`update-source`) with a hard production guard against stray mutation flags (`Assert-NoMutationPath`). Adding a destructive teardown mode would broaden that surface and blur its source-of-truth (the install metadata cross-binding).
- Uninstall's destructive footprint, finalizer trampoline (§3), and footprint-zero success criterion (§2) are unlike anything in the install/update flow; keeping them in a separate script keeps each entrypoint single-purpose and independently reviewable.

## 2. Success criterion — global ai-harness footprint zero

Uninstall succeeds **iff the global/user ai-harness-toolset footprint is reduced to zero**, while every non-target (§7) is left untouched:

1. Install root `%USERPROFILE%\.claude\ai-harness-toolset\` — absent (including `current/`, `install.json`, `payload-manifest.json`, `payload-marker.json`, the managed root `README.md`, and any in-root run-evidence tree).
2. Owned skill mirrors `%USERPROFILE%\.claude\skills\<name>\` (one per source skill in the installed payload; currently the single shipped `ai-harness-review`) — absent.
3. Claude managed-block surface `%USERPROFILE%\.claude\CLAUDE.md` — **zero** `AI_HARNESS_TOOLSET_GLOBAL` marker pairs (the file itself may remain, carrying the user's marker-outside content).
4. Codex managed-block surface `%USERPROFILE%\.codex\AGENTS.md` (or `%CODEX_HOME%\AGENTS.md`; `AGENTS.override.md` precedence per `scripts/lib/activation-surface.ps1`) — **zero** marker pairs (file may remain).

Footprint-zero for the Codex managed-block target is defined over the **effective** surface chosen by the shared resolver (the same one activation applies to), not over every Codex file. A stale marker pair sitting in a *non-effective* Codex file (e.g. an `AGENTS.md` shadowed by an `AGENTS.override.md`) is **detect-warned, not removed** (resolved as O7, §11): the default targets only the effective surface so uninstall mirrors what activation actually wrote.

"Footprint zero" is the *verified* end state, not merely "delete commands issued". Because the install-root deletion is delegated to a finalizer trampoline (§3), the footprint-zero verification for target (1) is the finalizer's responsibility; the main entrypoint verifies targets (2)–(4).

## 3. Self-deletion problem and the temp finalizer trampoline

**Problem.** Uninstall can be invoked from *inside* the installed global payload — i.e. the running script is `%USERPROFILE%\.claude\ai-harness-toolset\current\scripts\uninstall-global.ps1`. On Windows a process cannot reliably delete the directory tree that contains its own executing script files (open/locked handles). A naive in-process recursive delete of the install root would therefore fail or leave a partial tree precisely in the common case.

**Solution — temp finalizer trampoline.** Split uninstall into a main entrypoint and a detached finalizer that lives outside the install root:

### 3.1 Main entrypoint (`scripts/uninstall-global.ps1`) responsibilities

The main entrypoint does **only**:

1. **Preflight (all surfaces, no mutation).** Resolve all targets via the read-only resolver `scripts/lib/uninstall-target.ps1` (`Get-UninstallPlan`, which uses the shared `scripts/lib/activation-surface.ps1` for the effective surfaces) plus the install-root footprint enumeration (§5). Apply the preflight-all-then-act discipline (mirrors `activate-global.ps1`): if any fail-fast condition holds (unexpected install-root content, malformed/ambiguous marker, pre-existing `.amb-backup`, managedBy mismatch, install-root path-guard failure), **remove nothing** and report `uninstall_blocked`.
2. **Managed-block removal** of the two instruction-file surfaces (§4) — marker-span excision only, outside content preserved.
3. **Skill mirror removal** — delete each owned `%USERPROFILE%\.claude\skills\<name>\` directory (one per source skill in the installed payload; currently the single shipped `ai-harness-review`) (§6).
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

**`Remove-ManagedBlock` primitive (implemented, batch 1).** `scripts/lib/managed-block.ps1` provides `Remove-ManagedBlock` alongside `Set-ManagedBlock`. Removal is **not** faked as "`Set-ManagedBlock` with an empty snippet" (that would leave an empty marker pair, violating footprint-zero) — the marker lines themselves are excised. Marker-count branch ordering: `Resolve-ManagedBlockSpan` fail-fasts on 0 pairs, but the 0-pair state must be an idempotent no-op (not a failure) for removal, so the primitive first counts markers via `Find-ManagedBlockMarkers` — 0 pairs → no-op (`Removed = $false`, content unchanged); 2+/incomplete/ordering-violation → fail-fast (throw); exactly 1 → `Resolve-ManagedBlockSpan` → excise. It does not call the exact-1 resolver before establishing exactly one pair exists.

**State machine** (per surface):

| Marker state | Behavior |
|---|---|
| 0 pairs | **Idempotent no-op** (`absent`) — never adopted, or already removed. Not a failure. |
| exactly 1 pair | Excise BEGIN..END inclusive; **all other bytes preserved verbatim** (the `before + after` splice keeps each surviving segment's original line terminator — no blank-line normalization, no EOL rewrite). File retained even if the excision empties it (empty-string content, never deleted). |
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

Delete the OWNED skill directories `%USERPROFILE%\.claude\skills\<name>\` — one per source skill in the installed payload (`current/snippets/claude-skills/*`), currently the single shipped `ai-harness-review` — then verify absence. This is the direct application of the existing skill-removal rule already documented in `INSTALL.md` §10 ("Skill adoption 규칙" → removal): propose each `<name>/` directory and its file list, on approval delete **only those directories** (no files outside them), verify absence; the source repo's `snippets/claude-skills/<name>/` is unaffected. The owned set is enumerated from the installed payload, so sibling skills under `skills/` that are NOT in the payload, and the `skills/` parent, are never touched (§7). Already-absent is an idempotent no-op success.

## 7. Non-targets (never touched)

Uninstall is a **global/user** teardown of the ai-harness footprint and explicitly does **not** touch:

- **Project-local `<ProjectRoot>/log/`** — Brief (`log/brief/`), Chatlog (`log/chatlog/`), review records (`log/review/`), evidence (`log/evidence/`). These are user runtime work products, not install footprint. Global uninstall never operates on any project root.
- **Source repo / ToolRoot clone** — the repository the user installed from (and any `-ToolRoot` / `AI_HARNESS_TOOL_ROOT` clone). Uninstall removes the *installed* footprint, not the source.
- **Sibling skills** under `%USERPROFILE%\.claude\skills\` that are not owned by this install (i.e. not in the installed payload's `current/snippets/claude-skills/*`).
- **Marker-outside instruction content** in `CLAUDE.md` / `AGENTS.md`, and the instruction files themselves (§4).
- **Non-toolset files** under `.claude` / `.codex`, and those directories themselves.
- **Project-root managed blocks** (project-specific adoption per `INSTALL.md` §10) — a separate explicit scope, not part of global uninstall.
- The forbidden path `%USERPROFILE%\.claude\AGENTS.md` is never created and therefore never a removal target; the forbidden-path guard is nevertheless retained on the uninstall path.

## 8. Dry-run / apply / verify separation

Mirrors `activate-global.ps1` and the inspect/apply split of the install flow:

- **Dry-run (default, no `-Apply`).** Read-only. Enumerate every target and classify each as `present` / `absent` / `blocked` (malformed marker, unexpected install-root content, pre-existing `.amb-backup`). Show exactly what would be removed and excised. No write, no finalizer launch. Terminal status `uninstall_preview`.
- **Apply (`-Apply`).** Preflight-all-then-act: if any surface is in a fail-fast state, remove nothing (`uninstall_blocked`). Otherwise perform managed-block excision + skill removal, then create/launch the finalizer and exit. Approval is **command-implied** (the explicit `-Apply` invocation is the decision). This is a global/user filesystem mutation and is bound by `INSTALL.md` §10 approval boundaries; the install-root path guard (canonical `…\.claude\ai-harness-toolset`) is **hard-enforced** in apply preflight (evidence-only in dry-run). (No interactive `-ConfirmInteractive` selector is implemented; if a direct-terminal confirm is later wanted it is a separate additive change.)
- **Verify (post-removal).** The main entrypoint verifies targets (2)–(4) (skill dir absent; zero marker pairs in both instruction files). The finalizer verifies target (1) (install root absent). Footprint-zero (§2) holds only when all four verify clean.

### 8.1 Status vocabulary (as-built; standalone, decision O5)

Per decision O5 (§11), the uninstall vocabulary is **standalone** (analogous to `activate-global.ps1`'s `activationStatus`); integration into `INSTALL.md` §13 is deferred to a later stabilization. There are two emitters: the main entrypoint's stdout `uninstallStatus=`, and the finalizer's result-JSON `status` (the finalizer runs detached after the entrypoint exits, so its outcome is reported in `<FinalizerTempRoot>\ai-harness-uninstall-<runid>.result.json`, not on the entrypoint's stdout).

**Main entrypoint (`scripts/uninstall-global.ps1`) `uninstallStatus`:**

| Status | Exit | Meaning |
|---|---|---|
| `uninstall_preview` | 0 | Dry-run (default, no `-Apply`); all targets classified, nothing removed. |
| `uninstall_blocked` | 1 | Apply preflight fail-fast — a blocked target (unexpected install-root content / malformed-ambiguous marker / pre-existing `.amb-backup` / managedBy mismatch / skill-path-shape) or an install-root path-guard failure; **nothing removed**. |
| `uninstall_partial` | 1 | Post-preflight: a surface removal failed, or finalizer setup/launch failed, after some surface(s) were already removed; the install root is **not** deleted (left intact for a re-run). No cross-surface transaction. |
| `uninstall_finalizer_launched` | 0 | Apply success: managed-block + skill surfaces removed + verified, install-root deletion **delegated** to the launched detached finalizer (terminal for the entrypoint; the finalizer's result file carries the deletion outcome). |
| `uninstalled` | 0 | Apply success when the install root was already absent: surfaces removed, nothing to delegate. |

**Finalizer (`scripts/uninstall-finalizer.ps1`) result-JSON `status`:**

| Status | Meaning |
|---|---|
| `uninstalled` | Install root deleted + absence-verified; temp self-clean succeeded. |
| `uninstalled_with_finalizer_leftover` | Install root deleted + verified, but the finalizer could not self-clean its own temp dir; the exact temp path is reported (`selfCleanLeftover`). Non-fatal. |
| `finalizer_parent_wait_timeout` | Parent (entrypoint) still alive after the wait timeout; refused to delete. |
| `finalizer_path_guard_failed` | Install-root path is not the canonical `…\.claude\ai-harness-toolset`; refused to delete. |
| `finalizer_unexpected_content` | Unexpected top-level content appeared in the install root since preflight; refused to delete. |
| `finalizer_delete_failed` | `Remove-Item` of the install root threw. |
| `finalizer_delete_verify_failed` | Delete ran but the install root is still present (absence verify failed). |

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
- **Post-removal verify failure** — a removal ran but absence was not confirmed: the finalizer reports `finalizer_delete_verify_failed` for the install root (and refuses-without-deleting variants `finalizer_path_guard_failed` / `finalizer_unexpected_content` / `finalizer_parent_wait_timeout` / `finalizer_delete_failed`); a surface-side verify failure rolls into the entrypoint's `uninstall_partial`.
- **Finalizer self-cleanup failure** — non-fatal to the uninstall outcome; the finalizer reports `uninstalled_with_finalizer_leftover` with the exact temp path (`selfCleanLeftover`).

## 10. Governance — §11(b) deterministic narrow entrypoint (implemented)

`INSTALL.md` §11's self-imposed boundary invariant requires that introducing a new entrypoint be a deliberate, scoped redefinition of §11 (a deterministic narrow entrypoint must not grow into the §11(a) productization/uninstaller-framework class). Accordingly:

- `INSTALL.md` §11(b) lists **uninstall (`scripts/uninstall-global.ps1`)** as a deterministic narrow entrypoint — now **implemented** (batches 1–3) as a dry-run + `-Apply` + finalizer entrypoint, kept narrow and single-purpose. A large/interactive uninstaller framework, doctor/repair teardown, or any productized uninstaller remains §11(a) out-of-scope and the boundary invariant still holds.
- The promotion gate that authorized implementation was satisfied: the `BACKLOG.md` IU-B-08 entry, scoped `/goal`s per batch, and a Codex review gate on each batch. The real-environment **dogfood** (isolated non-primary machine) of `-Apply` + reinstall verification is now **cleared** (§13); the entrypoint stays narrow and single-purpose. The install/update lifecycle subsystem **LTS readiness is now CLOSED** (`STATUS.md` completed-ledger IU-14; full narrative preserved in git history); the Phase 4b one-shot candidate is **RETIRED** (`BACKLOG.md` IU-B-07 [RETIRED]). Nothing remains for this uninstall entrypoint.

## 11. Decisions (resolved; as-built)

These were the implementation-prep open decisions (review task `20260529-uninstall-impl-prep`); all are now resolved and reflected in the code, except O6 which remains a deliberate non-target.

- **O1 — resolved (retain).** After managed-block excision empties an instruction file, the file is **retained** (empty content, never deleted). Implemented in `Remove-ManagedBlock` / `apply-managed-block.ps1 -Remove`.
- **O2 — resolved.** `Remove-ManagedBlock` is a function in `scripts/lib/managed-block.ps1`; the IO-safety (`.amb-backup` / rollback / post-write verify) is **reused** via `apply-managed-block.ps1 -Remove` (no separate/drifting removal IO, no extra wrapper script).
- **O3 — resolved (enumerate + fail-fast).** Install-root removal uses expected-footprint enumeration + unexpected-content fail-fast. Expected set: `current/`, `install.json`, `payload-manifest.json`, `payload-marker.json`, `README.md`, `source-cache/` (known-transient), `log/` (reserved run-evidence). Single-sourced via `Get-UninstallExpectedRootEntries` and passed to the finalizer.
- **O4 — resolved (temp finalizer).** Implemented as `scripts/uninstall-finalizer.ps1`: `%TEMP%`/run-id dir (overridable via `-FinalizerTempRoot`), parent-PID poll + timeout, install-root path re-guard, expected-footprint re-check, delete + absence verify, best-effort self-clean with exact-temp-path report. Detached launch quotes its `-File`/`-InputPath` args (spaces-safe).
- **O5 — resolved (standalone, defer §13).** Status vocabulary is standalone (§8.1); `INSTALL.md` §13 integration deferred to later stabilization.
- **O6 — NOT adopted (deliberate non-target).** Uninstall does **not** offer a project-scope teardown (project-root managed blocks / project-local skills); global uninstall stays the scope (§7). A separate project-scope mode remains a future option only.
- **O7 — resolved (effective surface only + detect-warn).** Footprint-zero targets only the **effective** Codex surface; a stale marker pair in a *non-effective* Codex file is **detect-warned**, not removed (§2). Implemented in the resolver.

## 12. Relationship to other surfaces

- `INSTALL.md` — operative install/activation contract; §11(b) carries the uninstall narrow entrypoint (implemented), §9.1/§10 the two mutation/removal classes and managed-block/skill rules this implementation reuses.
- `docs/systems/install-update/STATUS.md` — records IU-B-08 (batches 1–3 + isolated-machine dogfood cleared) as a completed-ledger row, and the install/update lifecycle subsystem LTS readiness (ledger IU-14); detailed narrative preserved in git history.
- `docs/systems/install-update/BACKLOG.md` — IU-B-08 is tombstoned there (CLOSED; ID continuity only); no IU-B-08 remainder.
- `docs/systems/install-update/GLOBAL_INSTALL_UPDATE_MODEL.md` — operating model; a teardown/uninstall mention there is a candidate follow-up, not part of this doc-sync.

## 13. Isolated non-primary machine `-Apply` dogfood (as-run; cleared)

The first real `-Apply` of `scripts/uninstall-global.ps1` against a real `%USERPROFILE%` install was exercised end-to-end on an **isolated non-primary machine** only. The **primary work machine was not mutated**; a real **primary-machine `-Apply`** remains a **separate, explicit approval boundary that was not performed**. The dogfood machine was first global-updated to current main HEAD `4b4e9dc`. The run is recorded here as the as-run dogfood evidence; it is not a re-runnable spec and no behavior changed in this doc-sync.

> **Update (main PC lifecycle retest — primary apply since performed under explicit approval).** The "primary work machine was not mutated / primary-machine `-Apply` not performed" statements in this §13 and in the §0 status header are **as-of this isolated-machine dogfood** and are **superseded for the main PC** by the later **main PC lifecycle retest**: a real main-PC uninstall `-Apply` (official `uninstall-global.ps1` discovered → dry-run → `-Apply` → finalizer → footprint-zero, `CLAUDE.md`/`AGENTS.md` 0 markers, review skill removed, unrelated `diary-harness` preserved), plus a real update `-Apply` and a clean install, were performed **under explicit per-action approval** and cleared. See `STATUS.md` completed-ledger IU-15; full narrative preserved in git history. The standing per-environment boundary is unchanged — each environment's real apply still requires separate explicit approval, and that retest does **not** auto-authorize any future apply.

### 13.1 As-run result

| Step | Result |
|---|---|
| Dogfood-machine global update | latest source, HEAD `4b4e9dc` |
| Uninstall **dry-run** (default, no `-Apply`) | `uninstall_preview`; `blocked=0`, `warn=0`, `wouldRemove=9` |
| Uninstall **`-Apply`** | success, exit 0 |
| Finalizer result-JSON | `status=uninstalled`, `installRootDeleted=true`, no self-clean leftover |

**Footprint-zero verification (§2) — all clean:**

- `%USERPROFILE%\.claude\ai-harness-toolset\` — absent (target 1).
- `%USERPROFILE%\.claude\skills\ai-harness-review\` — absent (target 2).
- `%USERPROFILE%\.claude\CLAUDE.md` — **0** marker pairs (target 3); file retained.
- `%USERPROFILE%\.codex\AGENTS.md` — **0** marker pairs (target 4); file retained.
- No `.amb-backup` leftover beside either instruction file (the apply closed cleanly — a leftover would have signalled an apply that did not close, per §4 / `INSTALL.md` §10).

**Clean reinstall (post-uninstall) — verified:** a latest-source bootstrap clone at HEAD `4b4e9dc` reinstalled the payload (`verify_pass` + cross-binding OK) and the skill mirror re-activated successfully; the final `install-update.ps1 -Mode verify` returned `verify_pass`.

Temp / evidence / bootstrap-clone paths from the dogfood were **preserved and not auto-deleted**; their removal is a separate operator decision under explicit approval.

### 13.2 Discovered boundary — post-uninstall reinstall is a first-time managed-block INSERTION

Uninstall **excises the marker pairs completely** (footprint-zero, §2 / §4: 0 marker pairs remain in `CLAUDE.md` / `AGENTS.md`). The activation tooling, however, is built for the steady-state **replacement** case: `scripts/activate-global.ps1` / `scripts/apply-managed-block.ps1` (apply mode) compute the new content via `Set-ManagedBlock` → `Resolve-ManagedBlockSpan`, which **fail-fasts on a 0-pair target** ("expected exactly 1"). The apply-mode tooling therefore **only replaces an existing single marker pair**; it does **not** perform the first-time insertion.

Consequently, a clean reinstall **after a full uninstall** re-enters the **0-pair → first-time managed-block insertion** case — the `INSTALL.md` §10 "Managed-block apply 규칙" branch *"matching marker pair 0개 → 삽입 지점을 propose … snippet 전체 (marker 포함) 삽입"*. This first-time insertion is a **separate explicit user-approved boundary**, distinct from a steady-state 1-pair replacement, and is not automated by the apply tooling.

On the dogfood machine this boundary was crossed deliberately: the first-time insertion was **explicitly user-approved (isolated-machine first-time insertion)** and applied from the source snippets `current\snippets\CLAUDE_SNIPPET.md` (Claude) / `current\snippets\AGENTS_SNIPPET.md` (Codex), yielding exactly **1** marker pair in each of `CLAUDE.md` / `AGENTS.md`. The final `install-update.ps1 -Mode verify` = `verify_pass` confirmed the reinstalled steady state.

At the time of the IU-B-08 closeout this was a documentation finding only; no script behavior was changed, and folding the 0-pair first-time insertion into deterministic tooling (vs. keeping it an operator-performed manual splice) was flagged as a separate scoped decision.

> **Update (IU-B-09 — boundary CLOSED).** That separate scoped decision was taken and implemented as **IU-B-09**. First-time insertion is no longer a manual operator splice: `scripts/lib/managed-block.ps1` adds the pure `Add-ManagedBlock` primitive and `scripts/apply-managed-block.ps1` adds an `-Insert` mode (absent target → create a 1-pair file; 0-pair target → append the snippet block preserving marker-outside content byte-for-byte; 1-pair → fail-fast back to the replace path; malformed / pre-existing `.amb-backup` / BOM / U+FFFD → fail-fast), reusing this tool's hardened IO. The fresh-install entrypoint `scripts/install-global.ps1` drives this insertion during its activation bootstrap, so a clean reinstall after a full uninstall (the 0-pair case above) is now closed by deterministic tooling — **still under explicit install approval**, just no longer hand-spliced. The steady-state replacement tooling (`activate-global.ps1` / `apply-managed-block.ps1` default mode) is unchanged: `-Insert` and the default (replace) mode are mutually exclusive, each fail-fasting in the other's domain, preserving replace-only semantics. See `INSTALL.md` §6.1 / §10 / §11 (b) and `STATUS.md` completed-ledger IU-B-09 (full narrative preserved in git history).

## 14. Main-PC manual partial uninstall incident — package-discovery hardening (IU-B-10)

This section records a **primary-work-machine uninstall incident** and its docs hardening. It is **not** an official uninstall dogfood; it is the opposite — a manual partial uninstall that bypassed the official uninstaller. It is recorded so the root cause is classified honestly and the fix is bound to it.

### 14.1 What happened (as-reported)

On the **primary work machine**, after a successful global update to the latest payload, the operator was asked to uninstall (`ai-harness-toolset 언인스톨해줘`). The official `scripts/uninstall-global.ps1` was **not discovered or run**. Instead:

- The operator inspected only the **install-root top level** (`%USERPROFILE%\.claude\ai-harness-toolset\current\`) and **did not descend into `current\scripts\`**, where the official uninstaller actually lives.
- The operator **did not read** the installed root `README.md` / `INSTALL.md`, so the official uninstaller flow (dry-run → `-Apply`, footprint-zero, the two managed-block surfaces) was never surfaced.
- The teardown was performed as a **manual cleanup** (hand deletion / rewrite), which **missed the Codex `%USERPROFILE%\.codex\AGENTS.md` managed block** — a stale marker span was left behind.
- A subsequent **corrective cleanup** removed the leftover `AGENTS.md` marker span.

The end state was eventually footprint-zero, but **only after a corrective pass**, and the path taken was a manual partial uninstall, not the official uninstaller.

### 14.2 Root-cause classification

The root cause is a **installed-package-hierarchy discovery failure**, **not**:

- **not** a snippets / global-instruction deficiency — the role-neutral `snippets/CLAUDE_SNIPPET.md` / `snippets/AGENTS_SNIPPET.md` payload is not the place for an operator uninstall procedure (it carries none, by design), so adding uninstall prose there would have been the wrong fix and is explicitly **not** done;
- **not** a code-behavior bug — `scripts/uninstall-global.ps1` + `scripts/uninstall-finalizer.ps1` already implement footprint-zero across both managed-block surfaces (including the Codex effective surface) and the §13 isolated-machine dogfood cleared; the official uninstaller, had it been run, would have removed the Codex block too.

The actual gap: just as install/update succeed because the operator follows the installed root `README.md` / package docs into `current\scripts\`, **uninstall had no equally discoverable landing-page pointer** — so the official uninstaller in `current\scripts\` was not found from the install-root top level.

### 14.3 Fix — docs/template/test hardening (no code behavior change)

IU-B-10 closes the gap with discovery hardening only (the uninstall code is unchanged):

- The **installed root README template** (`templates/install-root/AI_HARNESS_TOOLSET_ROOT_README.md`) gains an **"Uninstalling this install"** section that, symmetric to the update landing-page guidance, makes the official uninstaller discoverable from the same package hierarchy: it names `current\scripts\uninstall-global.ps1` (and that it lives **under `current\scripts\`**, not at the install-root top level), the dry-run(default) → `-Apply` flow, the footprint-zero scope, the **Codex surface target set** (default `%USERPROFILE%\.codex\AGENTS.md`, `%CODEX_HOME%\AGENTS.md` when `CODEX_HOME` is set, `AGENTS.override.md` precedence), the **block-only `AGENTS.md` → 0-byte is the correct footprint-zero outcome (not corruption)** note, and the **manual-cleanup-is-a-fallback-not-a-dogfood** rule (with the legacy-payload in-contract route = clone latest source and run its `uninstall-global.ps1 -InstallArea <this dir>`).
- `INSTALL.md` §7.3 is extended to state that the README landing page carries this uninstall discovery guidance (parallel to update), so the contract and the materialized artifact stay in sync.
- Tests lock the README/contract wording and assert the snippets remain uninstall-procedure-free.

This is a **maintenance-scoped** change under the install/update lifecycle subsystem's LTS posture (`STATUS.md` LTS closeout: changes require a scoped `/goal` + Codex review gate). It asserts **no** new dogfood and performs **no** real install/update/uninstall.
