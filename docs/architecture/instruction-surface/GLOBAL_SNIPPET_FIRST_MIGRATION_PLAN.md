# Global Snippet First — Migration Plan

**Status: plan stage. NOT an implementation-approval document, NOT a snippet/spec edit, and NOT a re-classification of any snippet section.** This is the **plan** layer of the design → plan → spec → implementation sequence defined by the controlling authority `GLOBAL_SNIPPET_FIRST_MIGRATION_DESIGN.md` (the *design*). It translates that design into an **ordered migration batch sequence** with per-batch hard boundaries and review gates. It implements nothing, edits no global snippet, writes no spec, creates no `rules/` catalog, and deletes no docs. Each batch below is a **separate scoped goal + its own spec (where it edits the snippet or deletes docs) + Codex review gate + explicit user approval**; **this plan approves none of them.**

**Controlling authority.** `docs/architecture/instruction-surface/GLOBAL_SNIPPET_FIRST_MIGRATION_DESIGN.md` is the architecture-level migration authority. This plan obeys it and does not redefine it: the keep-by-proof criteria (design §7), the deployment-boundary constraint (§6), the owner-surface absorption order (§8), the source-of-truth conflict order (§4), the `rules/` deferral (§9), and the stage model (§10) all live in the design — this plan only sequences their application. Where this plan and the design appear to differ, the **design governs** and this plan is the stale surface to fix.

**Existing docs are evidence, not blocking source-of-truth (design §2, carried).** During this migration the prior instruction-surface docs (Track A/B/C, the skill plan) are **evidence**, not an automatic veto. A prior "global keep" disposition is a **re-judgment candidate**, not a settled keep (design §3). This plan must not be read as licence to ignore them — it weighs them and absorbs their live content into the right owner — but it does not let an un-flipped status doc or a conservative prior default *block* a batch.

**Placement / routing.** Co-located with the design + the Track A/B/C docs in `docs/architecture/instruction-surface/`. Routing: `docs/current/SOURCE_OF_TRUTH.md` Q11. Layer registration: `docs/architecture/README.md`. Authorities obeyed (not redefined): `docs/README.md` (placement; §4 always-on bar), `docs/policies/DOCS_OPERATING_MODEL.md` (single-home-plus-pointers §1; §4 durable-pointer rule; §7 two-level closeout; §12 git-history preservation), `docs/contracts/review/REVIEW_RESULT_CONTRACT.md` (review verdict/artifact). It states its decisions directly and does not durable-point at the out-of-repo direction note that seeded it.

---

## 1. Relationship to the existing batch/track orders (no renumber, no re-own)

This migration introduces its **own** batch namespace — `GSF-B1 … GSF-B4` — deliberately distinct from the two existing numbered orders so nothing is renumbered or silently re-owned:

| Existing order | Status | This plan's relationship |
|---|---|---|
| Skill plan §8 — `Batch 1…4` | Batch 1/2 landed; **Batch 3** (Chatlog / BF-lv3 removal) + **Batch 4** (review-polishing) deferred | **Not re-owned.** Skill-plan Batch 3/4 stay authoritative under `FUNCTION_LEVEL_SKILL_ARCHITECTURE_PLAN.md` §8. GSF-B1 (§2) coordinates with skill Batch 3 but does not renumber or absorb it (design §3). |
| Instruction-surface §14 — `Track A…G` | A–D landed; **Track E** (ToolRoot) + Track F (= skill Batch 3) + Track G (= skill Batch 4) deferred | **Track D was the conservative-default snippet pass; GSF-B1 is the aggressive continuation that re-opens that default** (design §3). Track E (ToolRoot) is a separate decision surface, untouched here. |

`GSF-Bn` are migration batches; `Batch n` always means the skill plan; `Track X` always means the instruction-surface plan §14. Where they overlap (the snippet), the skill plan stays the authority for the Chatlog/BF-lv3 deletions and this plan stays the authority for the keep-by-proof re-judgment of the remaining sections.

---

## 2. Ordered migration batch sequence

Ordered lowest-coupling-first. Each batch is sequential where a later batch assumes an earlier one's owner-migration already happened. **No batch is approved by this plan.**

### GSF-B1 — Global snippet minimization with direct owner-surface absorption
**This is the batch that performs global snippet minimization.** It is the **first implementation batch**; its acceptance criteria are the **spec** stage (design §10), which must be written and approved **before** GSF-B1 runs.

- **Goal.** Apply the design per snippet section: for each remaining section/sentence, run keep-by-proof (design §7); if it fails, route it by the owner-surface order (design §8) — absorb into a **deployed** executable surface (`scripts` / skill `SKILL.md`+`description` / `tests`) or the repo-local root `CLAUDE.md`/`AGENTS.md`, with at most non-deployed reference/rationale left in `docs/**` — or delete it. Honor the deployment boundary (design §6): `docs/**` is never the fallback owner.
- **What it re-opens.** The Track B audit's "global keep" default and skill plan §4 "what STAYS always-on" (design §3). Each prior keep becomes a re-judgment candidate; survival must be proven, not inherited.
- **Coordination with skill-plan Batch 3 (hard).** GSF-B1 does **not** re-own the Chatlog / BF-lv3 removal — that is skill-plan Batch 3 (= Track F). The spec decides the interleave (skill Batch 3 may run first, in parallel, or as a co-reviewed companion edit), but ownership/numbering of the Chatlog/BF-lv3 deletions stays with the skill plan §8.
- **Hard boundaries.** Edits `snippets/CLAUDE_SNIPPET.md` + `snippets/AGENTS_SNIPPET.md` **symmetrically** (snippet symmetry preserved). May extend a deployed owner surface only to *carry an absorbed invariant*; it must **not** change runtime behavior, install/update behavior, or skill-procedure semantics — if absorption would require any of those, **stop/report** (§4) and seek separate approval. No `rules/` catalog. No docs deletion. No ToolRoot move.
- **Review gate.** Spec first (approved). Then full `Invoke-Pester -Path .\tests`; `scripts/verify-ps1.ps1` if any `.ps1` changed; the repo-local parity guard if root files change; Codex **local-correctness + system-coherence**; plus the snippet-invariant check (no dropped hard boundary / adoption / path-topology / role-binding / verdict invariant — only owned-elsewhere content moved). `review-verify -RequireResult`.

### GSF-B2 — docs legacy policy-warehouse audit (classification only)
- **Goal.** Audit `docs/**` for content acting as **active instruction / runtime policy / skill fallback / global-snippet-rationale warehouse** that should be narrowed to **reference / contract / decision-record / rationale** (design §1–§2). Produce a per-section classification (migrate / absorb / compress / delete / retire candidate) with the owner surface each live fact maps to — the docs analogue of the Track B snippet audit.
- **Hard boundaries.** **Classification + owner-mapping only — no docs deletion, compression, or body rewrite in this batch.** A contract keeps its artifact authority (design §4 note); the audit only re-judges *role and authority weight*, not the artifact definition.
- **Review gate.** Codex **system-coherence** (the question is cross-surface role coherence, not local correctness); `review-verify -RequireResult`. A docs-classification round does not require the full Pester suite (no code/test/snippet/template change) — state the change class in the review input.

### GSF-B3 — `rules/` extraction MVP consideration (decision batch)
- **Goal.** With the rule candidates classified in GSF-B1/B2 in hand, decide whether to extract a **minimal** `rules/` surface (design §9), using the three rule kinds (global-distributed / repo-local / global-always-on) for classification. May conclude "defer further — not yet worth a surface."
- **Hard boundaries.** **No broad `rules/` catalog.** If a candidate is an immediately-needed deterministic guard, prefer fixing it as a `tests`/verifier first (design §8 step 3). Shipped-globally ≠ applied-always-on (design §9).
- **Review gate.** Codex **system-coherence**; `review-verify -RequireResult`.

### GSF-B4 — docs deletion / compression / retirement (owner-migration-gated)
- **Goal.** Execute the removal decisions from the GSF-B2 audit: delete / compress / retire the docs sections that the audit classified as such.
- **Owner-migration evidence required before deletion (hard).** A doc section may be deleted/compressed/retired **only when** its live content has a **confirmed owner surface** (already migrated/absorbed in GSF-B1/B2/B3, with a concrete pointer to where it now lives) **or** is genuinely obsolete (no live content). No deletion of content whose only home is the doc being deleted. Git history is the preservation mechanism (`DOCS_OPERATING_MODEL.md` §12) — superseded narrative is not migrated into a new archive doc.
- **Hard boundaries.** No deletion without owner-migration evidence; a four-class reference sweep (path / token / folder-bucket / semantic) for dangling references before the review; inbound references updated.
- **Review gate.** Codex **local-correctness** (dangling-reference / deletion sweep is the primary review surface) **+ system-coherence**; `review-verify -RequireResult`.

**Stage flow.** design (committed, `4f31cd9`) → **this plan** → spec for GSF-B1 (next) → GSF-B1 implementation → (GSF-B2, then GSF-B3, then GSF-B4, each with its own scoped goal + spec-where-it-mutates + review + approval).

---

## 3. Trigger-map wiring decision (resolves the design's deferred item + the carried review risk)

**Decision: wire now, at the plan stage.** The design (§11) deferred the root `CLAUDE.md`/`AGENTS.md` "Snippet (global payload)" trigger-map wiring to the "plan/implementation stage," because at design time the migration was not yet a navigable, gated sequence and routing operators to an inactive authority would be premature. **This plan makes the sequence navigable** (§2: GSF-B1…B4 with boundaries and gates), so the migration is now operative *as a routing target* — and the system-coherence review of the design flagged the un-wired state as the main risk to accept before commit. Therefore this plan, as part of its own change set, wires the row.

- **What the wiring does.** The "Snippet (global payload)" row's *inspect-first* now names `GLOBAL_SNIPPET_FIRST_MIGRATION_DESIGN.md` + `GLOBAL_SNIPPET_FIRST_MIGRATION_PLAN.md` as the **controlling migration authority** (keep-by-proof default; existing docs are evidence), with the Track A/B audit retained as the **per-section classification of record until a migration batch lands**. The mutation-boundary cell states: re-judge under the migration criteria + owner-surface absorption, and **no snippet minimization without an approved migration batch (spec)**.
- **What the wiring does NOT do.** It does **not** make snippet minimization operative, does not re-classify any section, and does not tell an operator to apply default-delete now. Until GSF-B1's spec is approved and lands, the per-section classification an operator applies for any actual snippet edit is still the Track B audit's; the migration authority controls only the *default and criteria* for the upcoming re-judgment.
- **How it is done.** Both root files are edited **symmetrically** (shared body byte-identical; only the per-tool header differs), per the mirror-edit rule; the `tests/repo-local-instruction-parity.Tests.ps1` guard is run as part of this change's validation. This touches the repo-local instruction surface (not the global snippet payload), which is permitted.

This is the one place this plan edits an always-on surface; it is a **pointer addition**, consistent with the design's "states decisions directly / routes operators to the authority" posture.

---

## 4. Stop/report boundaries (apply to every batch)

These are not migration legacy candidates and not negotiable by any batch. If a batch would cross one, **stop and report; do not silently expand scope** (design §10/§12; conflict-order §4 note):

```
- runtime behavior change                         → stop/report; separate approval
- install / update / uninstall behavior change    → stop/report (LTS subsystem); separate approval
- skill procedure semantic change                 → stop/report; separate approval
- ToolRoot move                                   → separate decision surface (Track E); not in this migration
- hooks introduction                              → forbidden-by-default; separate approval
- memory inspect / export / edit / cleanup        → out of scope; separate approval
- global / user file mutation                     → forbidden except an explicit managed-block adoption
- snapshot / manifest creation                    → out of scope
- commit / push                                   → explicit user approval per change set
```

An owner-surface absorption (design §8) that *looks like* it needs one of these (e.g. extending a script so the snippet can drop an invariant) is allowed **only** if it stays within non-semantic bounds; the moment it would change runtime/install/skill-procedure semantics, it is a stop/report, not a silent in-batch expansion.

---

## 5. Per-batch review-gate summary

| Batch | Mutates | Spec needed? | Validation | Codex perspectives |
|---|---|---|---|---|
| **GSF-B1** | global snippet (both) + owner surfaces | **Yes** (acceptance criteria) | full Pester; `verify-ps1` if `.ps1`; parity guard if root files | local-correctness **+** system-coherence + snippet-invariant check |
| **GSF-B2** | a classification record only — no docs deletion / compression / body rewrite | No | targeted (`git diff --check`); no full suite needed (state change class) | system-coherence |
| **GSF-B3** | nothing (decision), or a `tests`/verifier MVP | only if it adds a guard | full Pester if a test/verifier lands | system-coherence |
| **GSF-B4** | docs deletion/compression/retirement | per the GSF-B2 record | reference sweep; targeted check | local-correctness **+** system-coherence |

Every gate is `review-prepare.ps1` → `review-run.ps1` → `review-verify.ps1 -RequireResult` (or the `ai-harness-review` skill). A verdict approves no commit/push (design §14).

---

## 6. Coherence registrations made with this plan

Per the two-level closeout gate (`DOCS_OPERATING_MODEL.md` §7), inspect-all / report-each:

**Level 1 (top-down orientation):**
- `docs/current/SOURCE_OF_TRUTH.md` — **updated** (Q11): registers this plan as the migration plan layer under the design authority.
- `docs/roadmap/CURRENT_MILESTONES.md` — *checked: no change required* (numbered post-MVP order unchanged; this is a design-stage architecture plan, not a numbered milestone).
- `docs/decisions/POST_MVP_PLAN.md` — *checked: no change required* (numbered-order authority unchanged; this plan introduces its own `GSF-Bn` namespace and does not rewrite the numbered order).

**Level 2 (system-local):**
- `docs/architecture/README.md` — **updated** (instruction-surface subfolder row): lists this plan alongside the design + Track A/B/C.
- root `CLAUDE.md` + `AGENTS.md` — **updated** (the §3 trigger-map wiring, mirror-edited; parity guard run).
- `docs/README.md` §5 — *checked: no change required* (the `docs/architecture/` layer description + single example are unchanged by adding a file in the existing subfolder).
- `docs/systems/skills/STATUS.md` — *checked: no change required* (plan stage; no snippet/skill content changed — no SK ledger row, no current-state flip; the snippet's current contents remain accurately described there until GSF-B1 lands).
- existing `INSTRUCTION_SURFACE_PLAN.md` / `GLOBAL_SNIPPET_RELOCATION_AUDIT.md` / `REPO_LOCAL_INSTRUCTION_SURFACE_PLAN.md` / `FUNCTION_LEVEL_SKILL_ARCHITECTURE_PLAN.md` — *checked: intentionally not edited* (preserved as prior evidence; relationship declared in the design §3 and this plan §1, routed via Q11).

---

## 7. Approval boundaries

- This plan **approves nothing** and **re-classifies no snippet section**. It defines the batch sequence, boundaries, and gates under which the spec/implementation will act.
- The one always-on edit it makes is the §3 trigger-map pointer wiring (repo-local instruction surface, mirror-edited, parity-guarded) — not a global snippet edit and not snippet minimization.
- Producing it does not authorize: editing the global snippet payload; writing the spec; creating a `rules/` catalog; deleting/compressing/retiring any doc; editing skills/scripts/tests beyond what a separately-approved batch scopes; changing runtime / install / update / uninstall / skill-procedure semantics; moving ToolRoot; inspecting/editing memory; creating hooks or Codex Rules; mutating any global/user file; creating any snapshot/manifest; or commit/push.
- A Codex review verdict (`yes` / `no` / `yes with risk`) on this plan does not auto-approve any batch, the spec, or any commit/push — each remains an explicit user decision.

---

## 8. One-line summary

Translate the Global Snippet First design authority into an ordered, gated batch sequence — **GSF-B1** snippet minimization with direct owner-surface absorption (its acceptance criteria are the next, still-unwritten spec), **GSF-B2** docs policy-warehouse audit (classify, don't delete), **GSF-B3** `rules/` MVP consideration (no broad catalog), **GSF-B4** docs deletion/compression/retirement (only with owner-migration evidence) — wire the root trigger map to the controlling authority now (resolving the carried risk), keep existing docs as evidence rather than blocking source-of-truth, and re-classify nothing here, which is spec/implementation work.
