# Instruction Surface Architecture — Plan / Audit

**Status: design-stage planning / audit source. NOT an implementation-approval document.** This file decides the *target instruction-surface architecture* for `ai-harness-toolset` — how operating rules are partitioned across instruction tiers (global instruction, repo-local always-on instruction, skill `description`, `SKILL.md`, `docs/contracts`, memory, hooks) and which tier owns which rule — **before** any repo-local instruction file is created or any further global-snippet reduction is implemented. It changes no implementation, script, runtime, snippet, skill, or behavior. Each implementation step named here (repo-local instruction creation, global-snippet residual relocation, snippet reduction, ToolRoot relocation) requires its own scoped goal, Codex review gate, and explicit user approval; **this document approves none of them.**

**Scope of this batch.** Docs-only planning/audit. The only artifacts this batch produces are this plan, a short `docs/architecture/` layer README, a minimal `docs/README.md` registration of the new layer, and a `docs/current/SOURCE_OF_TRUTH.md` routing entry. No `CLAUDE.md` / `AGENTS.md` / `.claude/` / `.codex/` is created; no snippet / skill / script / test is edited; no `/init` is run; no memory is inspected or mutated; no hook or Codex Rule is created; no ToolRoot is moved; no commit/push.

**Placement.** This doc opens a new `docs/architecture/` layer because instruction-surface architecture is a **cross-cutting structural decision that spans multiple subsystems and surfaces** (global snippet, repo-local instruction, skills, contracts, memory, hooks, ToolRoot) — it is not the current operational state of any one subsystem, so it does not belong under `docs/systems/<system>/`, and it is not a single settled decision record, so it does not belong under `docs/decisions/`. The layer distinction is recorded in `docs/README.md` §5 and `docs/architecture/README.md`.

**Authorities this plan obeys (does not redefine).** Docs placement → `docs/README.md`; docs change/closeout flow + single-home-plus-pointers → `docs/policies/DOCS_OPERATING_MODEL.md`; per-question routing → `docs/current/SOURCE_OF_TRUTH.md`; review artifact/verdict contract → `docs/contracts/review/REVIEW_RESULT_CONTRACT.md`; the deployed snippet↔skill responsibility split + batch order → `docs/systems/skills/FUNCTION_LEVEL_SKILL_ARCHITECTURE_PLAN.md` (§8) and `docs/systems/skills/STATUS.md`. This plan sits **above** the skill plan: the skill plan governs the snippet↔skill split inside one tier; this plan governs the full tier set. Where they overlap (global-snippet residual, Batch 3/4), the skill plan §8 remains the authority for the skill-subsystem batches and this plan only re-situates them in a broader track order (§14).

---

## 1. Why a missing repo-local instruction surface caused leak

`ai-harness-toolset` was developed without a repo-local Claude Code / Codex instruction surface for the toolset's *own* repository. The toolset builds an always-loaded global payload (`snippets/CLAUDE_SNIPPET.md` / `snippets/AGENTS_SNIPPET.md`, adopted into a `CLAUDE.md` / `AGENTS.md` managed block) and a per-subsystem `docs/` tree, but it never had a `<ProjectRoot>/CLAUDE.md` / `<ProjectRoot>/AGENTS.md` that an agent loads when working *on this repo*.

The failure chain that produced the leak:

1. **No home for repo-operation rules.** Rules needed only to develop/operate/review/close out *this repo* (which docs to read for which task, which mutation boundaries apply, what the closeout discipline is) had no repo-local always-on surface to live in.
2. **`docs/` is source-of-truth but not auto-loaded.** `docs/` holds the authoritative facts, but an agent does not read `docs/` automatically — it must be *told when* to read which doc. There was no trigger layer mapping a task class to its required docs/gates/boundaries.
3. **The agent had to re-derive docs-access every task.** With no trigger map, each session re-inferred which docs were relevant; inference failures meant docs were skipped or read stale.
4. **The vacuum pulled repo-specific rules into the global snippet.** To make the rules visible at all, repo-development and docs-access guidance migrated into the always-loaded snippet — the one surface guaranteed to load.
5. **Every global adopter pays for repo-internal rules.** Because the snippet is adopted into *every* project's `CLAUDE.md` / `AGENTS.md`, rules that only matter when developing `ai-harness-toolset` itself became always-on context cost for unrelated adopter projects, and the global snippet grew beyond minimal adopter invariants.

**Core diagnosis.** `docs/` is source-of-truth but **not** an auto-loaded instruction surface. The fix is **not** to copy docs into a repo-local file; it is a thin **trigger map** — *task class → required source-of-truth docs → validation/review gate → mutation boundary → closeout condition* — that lives in a repo-local always-on surface and points at `docs/`, never duplicating it.

---

## 2. The trigger-tier model

The organizing question is not "which file" but "which trigger tier." Each rule is classified by *when it is present*, *what triggers it*, *whether the model must infer it or the host injects it deterministically*, and *whether it is source-of-truth, procedure, recall, or automation*.

### 2.1 Tier overview

| Tier | Presence / trigger | Nature | Target disposition |
|---|---|---|---|
| **Global instruction** (`%USERPROFILE%\.claude\CLAUDE.md` / Codex user-global `AGENTS.md` managed block) | every global session, every project, always loaded | minimal invariants applying to *all* adopters | **minimize** to adopter-universal invariants |
| **Repo-local always-on instruction** (`<ProjectRoot>/CLAUDE.md` / `<ProjectRoot>/AGENTS.md`) | every session *in this repo*, always loaded | this repo's always-on defense line: docs trigger map + hard boundaries + review/closeout discipline | **introduce** as the home for repo-operation rules |
| **Skill `description`** | skill index / metadata, matched by intent | per-capability discovery / trigger | owns trigger / discovery |
| **`SKILL.md`** | loaded when the skill's trigger fires | full invoked procedure / workflow | owns procedure |
| **`docs/` + `docs/contracts/`** | inspected when a task needs them | source-of-truth facts / artifact contracts | stays source-of-truth; referenced by pointer, not duplicated |
| **Memory** (Claude memory / Codex memories) | recall-dependent, model-surfaced | auxiliary recall | **not** a delivery surface (§10) |
| **Hooks** | lifecycle event, host-executed | automation | out of scope / forbidden-by-default (§11) |
| **Codex Rules** | Codex-specific command-permission policy | command approval | excluded from this batch (§12) |

### 2.2 Classification questions

Each retained sentence/rule is classified by:

1. Must this be visible *before any skill triggers*, on every task?
2. Does it apply to *every global adopter*, or only when developing *this repo*?
3. Is it skill-discovery `description` material, or post-trigger `SKILL.md` procedure?
4. Can it be a `docs/`/contract source-of-truth fact that a repo-local trigger map merely *points at*?
5. Would reproducibility break if it lived only in memory?
6. Is it leaking into an automation/permission surface (hook / Codex Rule) instead of an instruction surface?

The tier with the **narrowest sufficient presence** wins. A rule that can be owned by a skill `description`, `SKILL.md`, `docs/contracts`, install docs, or repo-local instruction without breaking global-adopter behavior must **not** remain in the global snippet.

---

## 3. Global instruction policy

The global `CLAUDE.md` / `AGENTS.md` managed block is paid by every session of every adopter project. It keeps **only minimal global adopter invariants.**

**Keep (global invariant test — all three must hold):**

- Applies to *every* global adopter, not only to developing this repo.
- Must be visible *before* any skill triggers (a skill cannot be relied on to carry it).
- Its absence causes a concrete, repeatable failure (not merely "safer to repeat").

**Do not keep in the global snippet:**

- `ai-harness-toolset` repo-development / repo-operation rules → repo-local instruction (§4) or `docs/`.
- Wholesale docs summaries → `docs/` (pointer only).
- A **skill index / routing table / trigger fallback** → owned by each skill's `description` (§8 of the skill plan; the routing-pointer-removal batch already dropped these — do not reintroduce).
- A **repo development guide** → repo-local instruction.
- Duplicate "nice to have / safer if repeated" rules already owned elsewhere.

**Decision rule (single-home test).** If a sentence can be owned by a skill `description`, `SKILL.md`, `docs/contracts`, install docs, or repo-local instruction without breaking global-adopter behavior, it must not remain in the global snippet. The global snippet is **not** a skill index, **not** a routing table, **not** a trigger fallback, and **not** a repo development guide.

---

## 4. Repo-local instruction candidates

A repo-local always-on instruction surface is for an AI operator working on the `ai-harness-toolset` repo *itself*. It is always-on *for this repo only*, so it does not burden unrelated adopters.

### 4.1 Primary candidates (root-level tracked files)

```
<ProjectRoot>/CLAUDE.md     — Claude Code primary repo-local surface
<ProjectRoot>/AGENTS.md     — Codex primary repo-local surface
```

Rationale (from tool behavior; see §5 for the `/init` caveat): Claude Code loads a repo-root `CLAUDE.md`, and Codex loads a repo-root `AGENTS.md`, as always-on project instruction. Neither is the global/user-global instruction file, so a repo-root file is the natural home for repo-operation rules without touching any global file. Both are public-safe candidates *only* under the §7 boundary.

### 4.2 Secondary candidates (only if evidence supports)

```
<ProjectRoot>/.claude/CLAUDE.md
<ProjectRoot>/.claude/AGENTS.md
```

`.claude/*` is **not** assumed canonical. It is considered only if concrete repo/tool evidence (loader behavior, precedence, or a need to keep the repo root uncluttered) justifies it. This plan does not adopt it.

### 4.3 Role (trigger map, not docs copy)

The repo-local surface provides, per task class: `required source-of-truth docs → validation/review gate → mutation boundary → closeout condition`. It does **not** restate doc bodies. The concrete map is §8.

---

## 5. Claude `/init` and Codex `/init` policy

**Neither `/init` is run in this batch.** Both appear to create a root-level scaffold (Claude `/init` → a repo-root `CLAUDE.md` codebase summary; Codex `/init` → a current-directory `AGENTS.md` scaffold) and are therefore **filesystem mutations**, not read-only discovery. Observed from tool documentation/help (not executed here): neither appears to mutate the global/user-global instruction file directly, but each writes into the repo working tree, and Codex runtime state may persist under `~/.codex`.

**Policy:**

- Claude `/init`: **no** (this batch).
- Codex `/init`: **no** (this batch).
- A generic `/init` scaffold must **not** be adopted as source-of-truth without planning — its output is a generic codebase summary, not this repo's deliberately-partitioned trigger map.
- Allowed now: read-only discovery only (help output, docs/conventions, existing artifacts). Forbidden now: running either init, creating `CLAUDE.md` / `AGENTS.md` / `.claude/` / `.codex/`, mutating any global file, or moving ToolRoot.
- An actual `/init` experiment, if ever wanted, is a **separate filesystem-mutation boundary** with its own approval — its scaffold would be an *input* to the §4/§6 decision, never an auto-adopted source-of-truth.

---

## 6. `CLAUDE.md` / `AGENTS.md` relationship — options

If both Claude and Codex get a repo-local surface (the vendor-neutral target), their relationship must be decided. Three options:

### Option A — parallel tracked files
Both `CLAUDE.md` and `AGENTS.md` are tracked, sharing one policy model but written for each tool's loading convention.
- **Pro:** respects each tool's canonical root file; allows tool-specific phrasing.
- **Risk:** drift between the two; the same policy is maintained twice (an N-place sweep on every change — the staleness engine `DOCS_OPERATING_MODEL.md` §1 warns about).

### Option B — one canonical source + synchronized outputs
One canonical repo-local instruction source; `CLAUDE.md` and `AGENTS.md` are generated or manually synchronized from it.
- **Pro:** drift-resistant; one ownership home.
- **Risk:** the generation/sync mechanism is itself a new maintenance surface; may be over-engineering at this stage (and a generator is close to the tooling this project deliberately keeps thin).

### Option C — one file first, other deferred
Track one tool-specific root file first; defer the other until evidence shows it is needed.
- **Pro:** smallest, simplest.
- **Risk:** conflicts with the vendor-neutral goal; one tool is left without a repo-local trigger map.

**Drift vs solo-maintainability trade-off.** This repo is solo-maintained, so the real cost of Option A is the manual two-file sweep on every policy change; the real cost of Option B is owning a sync mechanism; Option C trades vendor-neutrality for the least near-term work. The Track-A recommendation was **A or B** (C conflicts with vendor-neutral operation), with the A-vs-B choice turning on whether the shared body is large enough that manual two-file drift risk outweighs the cost of a sync mechanism. **Resolved (Track C): Option A** (parallel tracked files) — see the Open decisions list and `REPO_LOCAL_INSTRUCTION_SURFACE_PLAN.md`, routed by Q11.

---

## 7. Public-safe vs private / gitignored boundaries

A repo-local instruction file is **tracked** (public for an open-source adopter who reads the repo), so it must carry only public-safe content.

**May be tracked (public-safe):**

- Repo-local development instruction; docs-access trigger map (§8); per-subsystem source-of-truth routing; mutation boundaries; review-gate / closeout discipline; deterministic workflow notes; AI-operator guidance a public contributor may read.

**Must not be tracked:**

- Personal paths, accounts, tokens, secrets; specific-PC state; local model endpoints; session-restore state; `log/brief/BRIEF.md` content; private handoff; user personal decision history; runtime evidence / log payloads.

**Already-enforced constraints that carry over:** a committed doc must never use a **durable pointer to a gitignored / local / scratch / runtime path** (`log/**`, `polishing/**`, repo-sibling artifacts, user/global files) — durable pointers resolve only to git-tracked files or git history (`DOCS_OPERATING_MODEL.md` §4). This plan therefore states its decisions directly rather than pointing at the out-of-repo direction note that seeded it. A repo-local instruction file inherits the same rule.

---

## 8. Task-class → required-docs trigger map (repo-local AI operation)

This is the substance a repo-local instruction surface would carry: for each task class, *which docs to inspect, which gate to run, which boundary holds*. It points at single-home authorities; it does not restate them. (Reproduced here as the planning target — the implementing batch, not this one, would place it in the repo-local file.)

| Task class | Inspect first (source-of-truth) | Validation / review gate | Mutation boundary |
|---|---|---|---|
| Review scripts / contract / skill | `docs/contracts/review/REVIEW_RESULT_CONTRACT.md`; `snippets/claude-skills/ai-harness-review/SKILL.md`; `docs/systems/review/STATUS.md` (if status changes) | Codex local-correctness + system-coherence review; `review-verify -RequireResult` | review machinery is maintenance-mode; verdict approves no commit/push |
| Install / update / uninstall | `INSTALL.md`; `docs/systems/install-update/GLOBAL_INSTALL_UPDATE_MODEL.md` (+ §8A activation surface); `docs/systems/install-update/STATUS.md` | relevant Pester lifecycle suites | LTS subsystem; no global/user filesystem mutation without explicit approval |
| Snippets (global payload) | `docs/systems/skills/FUNCTION_LEVEL_SKILL_ARCHITECTURE_PLAN.md` + `STATUS.md`; this plan §3/§9 | full Pester (`Invoke-Pester -Path .\tests`) on snippet/script/template/test change; Codex review | classify every retained sentence by the §3 single-home test; no skill-routing pointers |
| Brief behavior | `docs/contracts/brief/BRIEF_CONTRACT.md`; `snippets/claude-skills/ai-harness-brief/SKILL.md` | Codex review | do not change `brief-*.ps1` unless explicitly scoped |
| Docs change / closeout | `docs/README.md` (placement); `docs/current/SOURCE_OF_TRUTH.md` (routing); `docs/policies/DOCS_OPERATING_MODEL.md` (flow + two-level closeout gate) | Codex review on corrected working tree | placement → README; routing → SoT; process → operating model |
| Repo-local / global instruction surface | this plan; `docs/README.md` §4 (always-on bar) | Codex review | global-file mutation only via managed-block per the adoption rules; no whole-file overwrite |

**Invariant for any source/doc edit:** a source/doc edit made *after* a Codex review makes that review stale — re-run on the corrected working tree.

---

## 9. Remaining global-snippet section classification criteria

When these classification criteria were written, the always-loaded snippet (CLAUDE/AGENTS, near-identical) carried **11 H2 sections**: Adoption destination · Adoption rules · Role neutrality · Project layout · Review record · Result verdict vocabulary · Operator stance · Brief · Chatlog · Forbidden in this toolset · Other rules. (The fifth section was named *Review flow* when this list was written; Track D renamed it *Review record*, and **GSF-B1** then folded it into *Project layout*; **Batch 3 / Track F** then deleted *Brief* + *Chatlog* (and the `no Brief↔Chatlog mirror` *Forbidden* bullet) — the **current** snippet is **8 H2 sections**; current-state authority `docs/systems/skills/STATUS.md` SK-05.)

This plan does **not** edit the snippet (that is the later relocation/reduction batch). It defines the **classification criteria** the audit batch will apply to each remaining section. Each section/sentence is classified into exactly one disposition:

| Disposition | Criterion |
|---|---|
| **Global keep** | Passes the §3 three-part global-invariant test (every adopter; pre-skill; concrete failure if absent). |
| **Repo-local move** | Applies only when developing/operating *this repo* (docs trigger map, repo review/closeout discipline). |
| **Skill `description` move** | Is trigger/discovery phrasing for a capability → owned by that skill's `description`. |
| **`SKILL.md` move** | Is post-trigger procedure → owned by that skill's `SKILL.md`. |
| **`docs/contracts` move** | Is an artifact/protocol fact whose single home is a contract; snippet keeps at most a pointer (or nothing). |
| **Install-docs move** | Is adoption/installation guidance → `INSTALL.md` / `GLOBAL_ADOPTION_PROCEDURE.md`. |
| **Delete** | Is not a current implemented capability (no future/deferred placeholder retained). |
| **Batch 3 defer** | Specifically the `## Chatlog` section and the `## Brief` BF-Level-3 non-claim line — already owned by the skill plan §8 Batch 3; **not** reclassified or removed here. |

**Pre-classified, non-binding first-pass disposition (to be confirmed by the audit batch, not applied here):**

- *Adoption destination*, *Adoption rules* — **global keep** (adopter-universal managed-block discipline) with a repo-local-move candidate for any `ai-harness-toolset`-only adoption-destination specifics.
- *Role neutrality* — **global keep** (operator vs reviewer binding is adopter-universal and reviewer-mode relevant).
- *Project layout* — **global keep** for ToolRoot/ProjectRoot/`log/` topology invariants; the ToolRoot *path string* itself interacts with §13 (vendor-neutral ToolRoot) and may change there.
- *Review flow* (now *Review record*) — review-record hard boundary is a **global keep** candidate; the title/content mismatch was **resolved by Track D** (renamed to `## Review record`, no-sidecar invariant preserved; skill plan SK-03); verdict-meaning is **`docs/contracts`/skill** owned.
- *Result verdict vocabulary* — **global keep** (the three values + "verdict approves nothing" invariant); the next-action mapping is **`docs/contracts`/skill** owned.
- *Operator stance* — **global keep** for the cross-task boundary stance; any review-specific detail is **skill** owned.
- *Brief* — BF-lv3 non-claim line is **Batch 3 defer** (since removed — `docs/systems/skills/STATUS.md` SK-05); the canonical-Brief path was a **global keep** candidate in this non-binding first pass, but the binding Track B audit §5 superseded it — the restore-source pointer is owned by `BRIEF_CONTRACT.md` + the `ai-harness-brief` skill, and Batch 3 did **not** relocate it into the snippet.
- *Chatlog* — **Batch 3 defer** (delete target, skill plan §8 Batch 3).
- *Forbidden in this toolset*, *Other rules* — **global keep** (hard boundaries + cross-task execution invariants: managed-block-only mutation, no daemon/hook, commit/push needs approval). *(The two PowerShell rules — `.ps1` = UTF-8 BOM+CRLF, native-stream separate capture — that this non-binding first pass placed here were **superseded**: the Track B audit §3.11 reclassified them repo-local and Track D moved them out of the snippet to the root `CLAUDE.md`/`AGENTS.md`.)*

These dispositions are a **planning hypothesis**, not an edit and not an approval; the audit batch (§14 Track B) re-derives and applies them under its own review gate.

---

## 10. Memory policy

Memory (Claude memory / Codex memories) is **not a delivery surface.**

- No global-adopter behavior, review/closeout policy, install/update behavior, skill routing/discovery, project-local docs trigger map, or source-of-truth fact required for reproducibility may depend on memory. If a deployed-behavior fact lives only in memory, reproducibility is already broken.
- Any useful memory-derived behavior must be represented in a **tracked** surface — snippet, skill, `docs/`, contract, or test — to count as real.
- Memory is limited to: personal preference, transient development context, repeated non-critical observation, recall not required for correctness.
- **This batch does not inspect, export, edit, or clean up memory.** Memory cleanup is out of scope and separately approved. Pre-existing memory-only content is treated as private / stale / test-only / non-source-of-truth until represented in a tracked surface — but no memory action is taken here.

---

## 11. Hooks policy

Hooks are **lifecycle automation surfaces** (host-executed scripts on a lifecycle event). They are **out of scope and forbidden-by-default** unless separately approved. This aligns with the toolset's standing invariant: explicit prompt, local-first, deterministic artifact, no hidden daemon/watcher/scheduler/hook (`snippets` Forbidden; `POST_MVP_PLAN.md` §5/§8).

- Do not create hooks in this batch.
- Do not design the instruction-surface architecture *around* hooks.
- **Do not use a hook to compensate for weak instruction/skill design.** An under-triggering skill is a `description` problem to fix, not a reason to add a hook; a missing docs-access habit is a repo-local trigger-map problem, not a reason to automate via hook.

---

## 12. Codex Rules exclusion

Codex Rules are **excluded** from this batch. They are Codex-specific command-permission controls (a security/approval surface), not a vendor-neutral instruction abstraction shared by Claude Code and Codex. Mixing them into instruction-surface architecture would couple a vendor-specific permission policy into a vendor-neutral structural decision.

- Do not include Codex Rules in this planning scope.
- Do not create or modify Codex Rules.
- Do not treat Codex Rules as a docs trigger map, source-of-truth, or global delivery surface.

A Codex command-permission decision, if ever needed, is its own separate security decision surface.

---

## 13. Vendor-neutral ToolRoot — separate decision surface

The current global stable ToolRoot is `%USERPROFILE%\.claude\ai-harness-toolset\current` (the channel-3 global stable install; its parent `%USERPROFILE%\.claude\ai-harness-toolset` is the install area/base, **not** the ToolRoot) — under the Claude vendor namespace. If Codex is also meant to resolve this ToolRoot, the Claude-namespaced location conflicts with vendor-neutral operation. Neutral install-area candidates (`%USERPROFILE%\ai-harness-toolset`, `%USERPROFILE%\.ai-harness-toolset`, `%LOCALAPPDATA%\ai-harness-toolset`, each with the ToolRoot being its `\current` child) exist, but relocation has large install / update / uninstall / migration / backward-compatibility impact.

- ToolRoot relocation is a **separate decision surface**, **not** mixed into instruction-surface planning or snippet-cleanup implementation.
- Do not move ToolRoot in this batch.
- This plan only records the dependency: the snippet's *Project layout* ToolRoot path string (§9) is the one place where this plan and the ToolRoot decision touch — that string would be revised by the ToolRoot decision, not by the instruction-surface batches.

---

## 14. Reordered remaining work

The instruction-surface direction reorders the remaining toolset work into the following tracks. This is a **recommended order within the design-stage plan**; it does **not** rewrite the authoritative numbered order. The install-update numbered milestones (`docs/decisions/POST_MVP_PLAN.md` §11, steps 1–6) are a *separate, already-closed* track and are unchanged by this plan; the skill-subsystem batch order (`FUNCTION_LEVEL_SKILL_ARCHITECTURE_PLAN.md` §8, Batch 1–4) remains the authority for the skill-subsystem batches, which Tracks B/D/F/G below re-situate but do not renumber. Reordering/adding/removing an authoritative-order step remains a separate scoped approval.

| Track | Work | Relationship to existing authority |
|---|---|---|
| **A — Instruction surface / trigger-tier planning** | this document | new; sits above skill plan §8 |
| **B — Global snippet residual relocation audit** | apply §9 classification to all 11 sections; decide global-keep / repo-local / skill / contract / install-docs / delete / Batch-3-defer per sentence | overlaps skill plan §8 Batch 3 scope; §8 stays authoritative for the Chatlog/BF-lv3 deletions |
| **C — Repo-local instruction implementation** | create the approved §4/§6 repo-local surface(s) with the §8 trigger map; public-safe verify (§7) | new; depends on A; the §6 relationship + `.claude/*` sub-decisions are **resolved** (Track C: Option A; `.claude/*` out of scope) |
| **D — Global snippet aggressive reduction** | remove what B relocated; resolve the Review-flow title/content mismatch | **Landed** (`STATUS.md` SK-03): PowerShell rules removed, `## Review flow`→`## Review record`, Role-neutrality symmetry aligned; ran **separately** — did **not** absorb Track F (Batch 3) |
| **E — Vendor-neutral ToolRoot decision** | evaluate current vs neutral roots; migration / backward-compat / uninstall plan (§13) | separate decision surface; independent of A–D ordering |
| **F — Batch 3** | remove snippet `## Chatlog` + BF-lv3 non-claim | **= skill plan §8 Batch 3** (authority there); **Landed** (`docs/systems/skills/STATUS.md` SK-05 — `## Brief` + `## Chatlog` deleted, the `no Brief↔Chatlog mirror` *Forbidden* bullet removed, snippet 10 → 8 H2); ran **separately** from Track D (SK-03) |
| **G — Batch 4** | review-polishing selective-capture vehicle decision (instruction vs skill; non-hook) | **= skill plan §8 Batch 4** |

Track ordering is a recommendation, not an approval; each track is a separate scoped goal + Codex review + explicit user approval.

---

## Open decisions

Items are annotated inline as later, separately-approved tracks resolve them; a resolved item's binding home is the named track, routed via `docs/current/SOURCE_OF_TRUTH.md` Q11. Unannotated `(open)` items remain open. These annotations are status pointers — the decision rationale below is unchanged.

1. **`CLAUDE.md` / `AGENTS.md` relationship** — **Resolved (Track C): Option A — parallel tracked files** (`docs/architecture/instruction-surface/REPO_LOCAL_INSTRUCTION_SURFACE_PLAN.md`, routed by Q11). Original framing: A (parallel) vs B (one source + sync) vs C (one first); C dispreferred (conflicts with vendor-neutral), A-vs-B turning on shared-body size vs sync-mechanism cost (§6).
2. **`.claude/*` as a secondary location** — **Resolved (Track C): out of scope** for the instruction surface (root files are the sole surfaces; revisit only on concrete loader/clutter evidence) — `REPO_LOCAL_INSTRUCTION_SURFACE_PLAN.md`, routed by Q11. Original: adopted only on concrete repo/tool evidence (§4.2).
3. **Exact global-keep vs repo-local-move split** per snippet section — **Resolved (Track B): the binding split is `docs/architecture/instruction-surface/GLOBAL_SNIPPET_RELOCATION_AUDIT.md`** (routed by Q11), superseding the §9 non-binding first pass. §9 supplies the criteria + that first pass.
4. **Vendor-neutral ToolRoot target** — **(open)** — separate decision surface (§13); not decided here.
5. **Whether Track D absorbs Track F (Batch 3)** or they run separately — **Resolved (Track D): ran separately** — Track D landed (`docs/systems/skills/STATUS.md` SK-03) without absorbing Track F; Batch 3 (Brief/Chatlog removal) **has since landed separately** (`docs/systems/skills/STATUS.md` SK-05; §14 Track F).

---

## Approval boundaries

- This document **approves nothing.** It is a design/plan source, not an implementation, adoption, or commit/push approval.
- Each implementation track (§14) is a separate scoped goal + Codex review gate + explicit user approval.
- Producing or revising this plan does not authorize: creating any `CLAUDE.md` / `AGENTS.md` / `.claude/` / `.codex/`; editing snippets / skills / scripts / tests; running any `/init`; mutating any global/user file; moving ToolRoot; implementing skill plan Batch 3 or Batch 4; inspecting/exporting/editing/cleaning memory; creating hooks or Codex Rules; creating any snapshot/manifest; or commit/push.
- A Codex review verdict (`yes` / `no` / `yes with risk`) on this plan does not auto-approve any track or any commit/push; that remains an explicit user decision.
