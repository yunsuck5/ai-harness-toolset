# Repo-Local Instruction Surface — Decision / Implementation Plan (Track C)

> **당시-경로 주석 (review 도메인 이주, batch R).** 본 기록 안의 review 문서 경로·식별자(`docs/contracts/review/**` · `docs/contracts/evidence/**` · `docs/policies/REVIEWER_CONFIG_POLICY.md` · `docs/policies/REVIEW_EFFORT_GUIDE.md` · `docs/systems/review/**`)는 작성 시점 경로다 — review 도메인은 이후 `docs/review/`(spec-of-record `review_spec.md` · queue `review_backlog.md`)로 이주했고 구계열 본문은 git history 에 보존된다.

**Status: design-stage decision + implementation plan. NOT an implementation-approval document, and it creates NO instruction file.** This is Track C of `INSTRUCTION_SURFACE_PLAN.md` §14. It **decides** whether and how `ai-harness-toolset` should carry a repo-local always-on instruction surface for developing the toolset *itself*, and specifies the content for a later implementation batch. It creates **no** `<ProjectRoot>/CLAUDE.md` / `AGENTS.md` / `.claude/` / `.codex/`, edits no snippet/skill/script/test, runs no `/init`, and changes no behavior. Creating the actual files is a **separate Track C implementation batch** (scoped goal + Codex review + explicit user approval); **this document approves it no more than any other batch.**

**Relationship to Tracks A/B.** Track A (`INSTRUCTION_SURFACE_PLAN.md`) set the trigger-tier model and named root `CLAUDE.md` / `AGENTS.md` as the primary repo-local candidates (§4) with relationship Options A/B/C (§6). Track B (`GLOBAL_SNIPPET_RELOCATION_AUDIT.md`) classified the two `## Other rules` PowerShell-authoring rules as **repo-local candidates**, gated on this surface existing first. This plan **resolves** the plan's Open Decisions **1** (the `CLAUDE.md`/`AGENTS.md` relationship → Option A) and **2** (the `.claude/*` secondary option → out of scope), and defines the exact future movement of the two PowerShell rules (the Track C→Track D handoff). The plan's "Open decisions" section is **annotated** (a minimal Track C reconciliation) to mark Decisions 1–2 resolved and point here; the binding decision and its rationale live in this plan, routed via `REPO_READING_GUIDE.md` Q11. The broader plan's architecture role is unchanged — only status pointers were added.

**Placement / location.** Co-located with the Track A plan and Track B audit in `docs/architecture/instruction-surface/`, under the agreed name `REPO_LOCAL_INSTRUCTION_SURFACE_PLAN.md`. The plan §14 does not name a Track C artifact file, so this co-location matches how the subfolder already holds the plan + audit for one cross-cutting concern. Authorities obeyed (not redefined): `INSTRUCTION_SURFACE_PLAN.md` §2/§4/§6/§7/§8; `GLOBAL_SNIPPET_RELOCATION_AUDIT.md` §3.11/§5; `docs/README.md` §4 (always-on bar); `docs/policies/DOCS_OPERATING_MODEL.md` §1/§4 (single-home-plus-pointers; durable-pointer rule); `docs/policies/POWERSHELL_POLICY.md` + `docs/policies/CLI_ENVIRONMENT_ASSUMPTIONS.md` (PowerShell-rule authorities).

---

## 1. Decisions at a glance

| # | Question | Decision |
|---|---|---|
| 1 | Track root `<ProjectRoot>/CLAUDE.md`? | **Yes** (§2). |
| 2 | Track root `<ProjectRoot>/AGENTS.md`? | **Yes** (§2), in parallel with CLAUDE.md (vendor-neutral). |
| 3 | Parallel / generated-synced / phased? | **Option A — parallel tracked files**, byte-identical shared body + a thin tool-specific header; **no generator** (§3). Resolves plan Open Decision 1. |
| 4 | Drift prevention? | Byte-identical shared body + mirror-edit rule + an **optional parity Pester** in the implementation batch (§4). |
| 5 | `.claude/*` role? | **Out of scope** for the instruction surface; root files are primary; revisit only on concrete loader/clutter evidence (§5). Resolves plan Open Decision 2. |
| 6 | Public-safe vs private contents? | Tracked = public-safe repo-dev guidance only; **nothing** private/gitignored/runtime in the tracked files (§6). |
| 7 | Initial docs trigger map? | Defined in §7 (seven task classes → inspect-first docs → gate → boundary). |
| 8 | Home for the two PowerShell rules? | Repo-local files' "repo execution conventions", **pointer-authority `POWERSHELL_POLICY.md`** (§8). |
| 9 | Track C → Track D handoff? | Track D removes the two rules from the snippet **only after** the repo-local files exist and carry them (§9). |
| 10 | Implement root files now or later? | **Later** — separate implementation batch; **this batch is the plan only** (§10). |

---

## 2. Decisions 1–2 — track root `CLAUDE.md` and `AGENTS.md`

**Decision: track both** `<ProjectRoot>/CLAUDE.md` (Claude Code) and `<ProjectRoot>/AGENTS.md` (Codex), as the repo-local always-on instruction surface for developing `ai-harness-toolset` itself. Both are public-safe (a contributor reads them) and are the loader-native repo-root files for each tool (`INSTRUCTION_SURFACE_PLAN.md` §4.1). Tracking both — rather than one — serves the vendor-neutral goal (§3).

**Critical clarification — these are repo-local surfaces, NOT a snippet adoption target.** The global snippet's *Adoption destination* lists "Project-root `CLAUDE.md` / `AGENTS.md`" as a place a **generic adopter** may install the always-loaded managed block. This repo's root files are a **different thing**: they hold **repo-development-only** content (the docs trigger map, repo mutation boundaries, repo execution conventions) and do **not** embed the `AI_HARNESS_TOOLSET_GLOBAL` managed block. Rationale:
- The adopter-universal global invariants are already delivered to an operator via the **global** `%USERPROFILE%\.claude\CLAUDE.md` / Codex user-global `AGENTS.md` managed block (self-adoption performed — `REPO_READING_GUIDE.md` Q7 / install-update STATUS IU-13). Re-embedding the snippet into this repo's root files would create a **third** copy of the payload to keep in sync (source snippet ↔ global adoption ↔ repo copy) — the staleness engine single-home-plus-pointers exists to prevent.
- Therefore the repo-local files are **additive** and reference (do not duplicate) the global invariants. A short header line may note "adopter-universal ai-harness invariants live in the global managed block (`snippets/CLAUDE_SNIPPET.md` / `AGENTS_SNIPPET.md`); this file adds repo-development guidance only" — a pointer, not a copy.

**Forbidden-path note (unchanged):** the global hard boundary "never create `%USERPROFILE%\.claude\AGENTS.md`" is about the **user-global** scope and is unrelated to a repo-root `<ProjectRoot>/AGENTS.md`, which is the Codex repo-local file and is allowed/tracked.

## 3. Decision 3 — relationship: Option A (parallel), shared body + thin header

**Decision: Option A — two parallel tracked files** sharing a **byte-identical repo-local body**, differing only in a small **tool-specific header** (tool name; any tool-specific path/precedence note, e.g. Codex `AGENTS.override.md` precedence). **No generator / sync mechanism** is introduced.

This resolves `INSTRUCTION_SURFACE_PLAN.md` Open Decision 1. Why A over B/C:
- **vs C (one file first):** rejected — conflicts with the vendor-neutral goal; one tool would lack a repo-local trigger map.
- **vs B (one canonical source + generated/synced outputs):** rejected **for now** — a generator is a new maintenance surface and close to the tooling this project deliberately keeps thin (`INSTRUCTION_SURFACE_PLAN.md` §6). The shared body is small and changes rarely, so manual mirror-edit + a parity check is cheaper than owning a generator. (B remains a future option if the shared body grows enough that manual drift risk dominates.)
- **A precedent already works here:** `snippets/CLAUDE_SNIPPET.md` / `AGENTS_SNIPPET.md` are maintained exactly this way — byte-identical except four small loci (the intro tool-name/destination line, the tool-specific `## Adoption destination`, and two short wording phrases in `## Adoption rules` and `## Role neutrality`), per `GLOBAL_SNIPPET_RELOCATION_AUDIT.md` §2. The repo-local files reuse that proven manual-mirror discipline.

## 4. Decision 4 — drift prevention between `CLAUDE.md` and `AGENTS.md`

1. **Byte-identical shared body.** Everything below the tool-specific header is identical across the two files. The header is minimal (tool name + tool-specific path/precedence note) and is the *only* sanctioned divergence.
2. **Mirror-edit rule.** Any change to the shared body of one file must be applied to the other in the same change; a single-file edit to the shared body is an **asymmetry defect** (the same rule Track B set for the snippets, `GLOBAL_SNIPPET_RELOCATION_AUDIT.md` §2).
3. **Optional parity check (implementation batch).** A small Pester test asserting the two files' shared bodies match (after stripping the tool-header) is **recommended** for the Track C implementation batch. It requires a `tests/**` addition, so it is **separately approved as part of that batch** (not this plan, and not a snippet/skill/script change to the existing surface).
4. **Self-referential guard in the trigger map.** The §7 *Repo-local instruction surface* task-class row instructs the operator, when editing `CLAUDE.md` / `AGENTS.md`, to edit both files' shared body symmetrically.

## 5. Decision 5 — `.claude/*` role

**Decision: `.claude/CLAUDE.md` / `.claude/AGENTS.md` are out of scope** as the repo-local instruction surface. Root `<ProjectRoot>/CLAUDE.md` / `AGENTS.md` are the primary and sole instruction surfaces decided here. This resolves `INSTRUCTION_SURFACE_PLAN.md` Open Decision 2.
- No repo/tool evidence requires a `.claude/`-nested instruction file; the root file is loader-native and sufficient, and nesting adds path indirection without benefit (`INSTRUCTION_SURFACE_PLAN.md` §4.2).
- Revisit **only** on concrete evidence (a loader precedence need, or a decision to keep the repo root uncluttered). This decision is narrowly about the **instruction surface** — it says nothing about a `.claude/` directory used for unrelated purposes (e.g. tool settings), which is a separate concern outside this plan.

## 6. Decision 6 — public-safe vs private/gitignored contents

The root files are **tracked** (public for any contributor reading the repo), so they carry only public-safe content (`INSTRUCTION_SURFACE_PLAN.md` §7):

**May be tracked:** repo-local development instruction; the docs-access trigger map (§7); per-subsystem source-of-truth routing; mutation boundaries; review-gate / closeout discipline; the repo execution conventions (incl. the two PowerShell rules, §8); AI-operator guidance a public contributor may read.

**Must NOT be tracked (anywhere in these files):** personal paths, accounts, tokens, secrets, specific-PC state, local model endpoints, session-restore state, `log/brief/BRIEF.md` content, private handoff, user decision history, runtime evidence / `log/**` payloads.

**No private companion file is created.** The repo-local instruction is fully public-safe; there is no operator-private instruction file. Any operator-private note belongs in the gitignored Brief or a local scratch file, never in the tracked instruction surface. **Durable-pointer rule** (`DOCS_OPERATING_MODEL.md` §4): the tracked files must not durable-point to gitignored/local/runtime paths (`log/**`, `polishing/**`, user/global files); durable pointers resolve only to git-tracked files or git history.

## 7. Decision 7 — initial repo-local docs trigger map

The body the implementation batch will place in the repo-local files. It **points at** single-home authorities (it does not restate them). Format per task class: *inspect first → validation/review gate → mutation boundary.*

| Task class | Inspect first (source-of-truth) | Validation / review gate | Mutation boundary |
|---|---|---|---|
| **Review** subsystem | `docs/contracts/review/REVIEW_RESULT_CONTRACT.md`; `snippets/claude-skills/ai-harness-review/SKILL.md`; `docs/systems/review/STATUS.md` (if status changes) | Codex local-correctness + system-coherence; `review-verify -RequireResult` | review machinery is maintenance-mode; a verdict approves no commit/push |
| **Install/update/uninstall** | `INSTALL.md`; `docs/systems/install-update/GLOBAL_INSTALL_UPDATE_MODEL.md` (+ §8A activation surface); `docs/systems/install-update/STATUS.md` | relevant Pester lifecycle suites; `verify-ps1` | LTS; no global/user filesystem mutation without explicit approval |
| **Snippet** (global payload) | `docs/architecture/instruction-surface/INSTRUCTION_SURFACE_PLAN.md` + `GLOBAL_SNIPPET_RELOCATION_AUDIT.md`; `docs/systems/skills/FUNCTION_LEVEL_SKILL_ARCHITECTURE_PLAN.md` + `STATUS.md` | full Pester (`Invoke-Pester -Path .\tests`); Codex review | classify every retained sentence by the §3 single-home test; **no** skill-routing pointers; keep CLAUDE/AGENTS snippet symmetry |
| **Brief** | `docs/brief/brief_spec.md`; `snippets/claude-skills/ai-harness-brief/SKILL.md` | Codex review | do not change `brief-*.ps1` unless explicitly scoped |
| **Source/docs** | `docs/README.md` (placement); `docs/current/REPO_READING_GUIDE.md` (routing); `docs/policies/DOCS_OPERATING_MODEL.md` (flow + two-level closeout gate) | Codex review on the **corrected** working tree | a source/doc edit **after** a review makes that review stale — re-run |
| **PowerShell / script** | `docs/policies/POWERSHELL_POLICY.md`; `docs/policies/CLI_ENVIRONMENT_ASSUMPTIONS.md` | affected Pester + full suite; `scripts/verify-ps1.ps1` | `.ps1` = UTF-8 BOM+CRLF; native-exe output keeps stdout/stderr/exit separate; controlled IO via `scripts/lib/encoding.ps1` |
| **Repo-local instruction surface** (editing `CLAUDE.md` / `AGENTS.md`) | this plan; `docs/architecture/instruction-surface/GLOBAL_SNIPPET_RELOCATION_AUDIT.md` | Codex review | edit the shared body of `CLAUDE.md` **and** `AGENTS.md` symmetrically — a single-file edit to the shared body is an asymmetry defect (§4); tracked = public-safe only (§6) |

(This map follows the same inspect-first / gate / boundary shape as `INSTRUCTION_SURFACE_PLAN.md` §8 and covers the same subsystems, and is reproduced here as the concrete content the implementation batch installs, pointing at the same single-home authorities. It **differs** from §8 in two deliberate Track-C additions: a dedicated *PowerShell / script* row — the home of the two relocated rules (§8 of this plan) — and the *Repo-local instruction surface* row above — the drift self-guard (§4); §8's combined "Repo-local / global instruction surface" row is split/specialized here accordingly.)

## 8. Decision 8 — exact home for the two PowerShell rules

The two rules Track B classified repo-local (`GLOBAL_SNIPPET_RELOCATION_AUDIT.md` §3.11):
- **`.ps1` files must be UTF-8 with BOM + CRLF**
- **native-exe output must keep stdout / stderr / exit code separate**

**Home:** a short **"repo execution conventions"** block in the shared body of the root `CLAUDE.md` / `AGENTS.md` (and, equivalently, the "PowerShell / script" trigger-map row, §7). They appear as **concise always-on conventions with a pointer**, not a restatement — the **single-home authority stays `docs/policies/POWERSHELL_POLICY.md`** (the *Encoding and line endings* table for the first rule; the *Native command invocation under `$ErrorActionPreference = 'Stop'`* section for the second), with `CLI_ENVIRONMENT_ASSUMPTIONS.md` Tier 1 as the why (PS 5.1 compatibility). They are **public-safe and tracked**.

**Why repo-local, not global:** the toolset's own canonical scripts are all `.ps1` (`CLI_ENVIRONMENT_ASSUMPTIONS.md` Tier 1), so these rules are always-on for *this* repo; a generic adopter using the toolset in a non-PowerShell project never needs them (the trigger-tier narrowest-presence test). **Consequence to state plainly:** once Track D removes them from the global snippet (§9), a generic adopter no longer carries them — that is **intended**; they are toolset-development conventions whose authority (`POWERSHELL_POLICY.md`) is itself a toolset doc.

**Known wording tension (carried from Track B):** `FUNCTION_LEVEL_SKILL_ARCHITECTURE_PLAN.md` §4 (and `INSTRUCTION_SURFACE_PLAN.md` §9's non-binding first pass) still call these "cross-task execution invariants". The binding classification (Track B audit, routed by Q11) reclassifies them repo-local; that skill-plan wording is reconciled when Track C **implements** (a future batch may add a one-line note to the skill plan), not in this planning batch.

## 9. Decision 9 — Track C → Track D handoff (sequencing invariant)

> **Status: both tracks have landed — handoff complete.** Track C created the root files carrying the rules; **Track D then removed the two rules from both snippets**, so the sequence below executed as specified and the transient both-surfaces period is closed (the rules now live only in the root files). Current status of record: `docs/systems/skills/STATUS.md` SK-03. The sequencing spec below is preserved as the rationale.

1. **Track C (this plan, then the implementation batch)** creates the root `CLAUDE.md` / `AGENTS.md` carrying the two PowerShell rules (§8) plus the trigger map (§7).
2. **Only after** those files exist and carry the rules does **Track D** remove the two rules from the global snippet — **symmetrically** from both `snippets/CLAUDE_SNIPPET.md` and `snippets/AGENTS_SNIPPET.md`. That removal is a **snippet edit = Track D**, a separate scoped goal with its own Codex review and explicit approval.
3. **Sequencing invariant (hard):** never remove the rules from the snippet before the repo-local home exists (`GLOBAL_SNIPPET_RELOCATION_AUDIT.md` "do not remove early"). Until Track D runs, the rules **stay** in the global snippet — so there is a deliberate, temporary period where the rules live in **both** the global snippet and the new repo-local files; that transient duplication is acceptable and is resolved the moment Track D lands.
4. When Track D removes them, the global snippet's `## Other rules` **keeps** commit/push approval + temp-file cleanup (global keep); only the two PowerShell rules leave.
5. **No snippet edit in this batch** (or in the Track C implementation batch) — the snippet change belongs to Track D.

## 10. Decision 10 — implement now or later

**Later — a separate Track C implementation batch.** This batch produces the **plan/decision artifact only**; it creates no `CLAUDE.md` / `AGENTS.md`. The implementation batch (separately approved) will: create the two root files from §2–§8; verify public-safe (§6); optionally add the parity Pester (§4); and is the prerequisite the §9 handoff depends on. Splitting plan from implementation keeps the file-creation (a tracked-file addition with its own review) cleanly gated, and lets this decision be reviewed before any file exists.

## 11. Constraints honored / non-goals

- Global snippets are **not** a skill index, routing table, trigger fallback, or repo development guide — the repo development guide is the new repo-local surface, distinct from the always-loaded snippet.
- **Memory is not a delivery surface** — none of the repo-local content depends on memory; it is fully represented in tracked files.
- **Hooks** out of scope / forbidden-by-default; **Codex Rules** excluded; no `/init` run.
- No `CLAUDE.md` / `AGENTS.md` / `.claude/` / `.codex/` created; no snippet/skill/script/test edit; no ToolRoot move; no Batch 3/4; no memory access; no hooks/Codex Rules; no snapshot/manifest; no commit/push — all deferred to their own approved batches.

## 12. Approval boundaries

- This document **approves nothing** and creates no instruction file. It is a decision + implementation-spec source for the Track C implementation batch and the Track D snippet removal.
- The Track C implementation batch (create root files) and Track D (remove the rules from the snippet) are each a separate scoped goal + Codex review gate + explicit user approval.
- A Codex review verdict on this plan (`yes` / `no` / `yes with risk`) does not auto-approve file creation, snippet edits, or any commit/push — each remains an explicit user decision.
