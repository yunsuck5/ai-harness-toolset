# Global Snippet First — GSF-B3 Rules Loading Model Decision

**Status: binding GSF-B3 decision record. Decision-only — creates no rules surface, no rules files, no `@import`, and edits no global snippet / root instruction body.** This is the reviewable artifact the migration plan (`GLOBAL_SNIPPET_FIRST_MIGRATION_PLAN.md` §2 GSF-B3) requires: with the GSF-B1/B2 rule-candidate classifications in hand, decide whether to extract a `rules/` surface — and, ahead of that, fix the **vendor-neutral rules loading model** so any future extraction is built on a correct understanding of how each surface is (and is not) loaded. The migration plan §2 GSF-B3 explicitly permits the conclusion "defer further — not yet worth a surface"; **this record reaches exactly that conclusion** and records the loading model + future adoption conditions that govern any later reversal.

**Controlling authorities (obeyed, not redefined).** `GLOBAL_SNIPPET_FIRST_MIGRATION_DESIGN.md` §9 (`rules/` deferred; the three rule kinds; **shipped-globally ≠ applied-always-on**) and §8 step 5 (a rule candidate is *classified*, not built); `GLOBAL_SNIPPET_FIRST_MIGRATION_PLAN.md` §2 GSF-B3 (decision batch; no broad catalog; a deterministic-guard candidate prefers `tests`/verifier first); `INSTRUCTION_SURFACE_PLAN.md` §11 (hooks forbidden-by-default; do **not** use a hook to compensate for weak instruction/skill design) and §12 (Codex Rules excluded — a Codex-specific command-permission surface, not a vendor-neutral instruction abstraction) — note the `rules/`-later-stage + three-rule-kinds material is owned by the GSF design §8/§9 above, **not** by `INSTRUCTION_SURFACE_PLAN.md` §9 (whose §9 is the *remaining global-snippet section classification criteria*); `docs/README.md` §4 (always-on bar — always-on rules live in the snippet/managed-block or the repo-local root files, never under `docs/`); `docs/policies/DOCS_OPERATING_MODEL.md` §1/§4/§7.

**Basis.** Repo state at `HEAD == 5822a97` (post GSF-B2). The **loading-model claims** in §2/§3 (how each surface is or is not loaded by Claude / Codex) come from **user-side research with Codex and Claude Code**, supplied to this batch as the decision input — they are **not** independently repo-verifiable (a read-only reviewer cannot exercise the external Claude/Codex loaders), and this record attributes them as research rather than asserting them as repo-verified facts. What this record *decides* — to create no rules surface now, and the conditions that would change that — is a repo decision and does not depend on the exact vendor internals.

---

## 1. Decision (one line)

> **Superseded — decision reversed by the hard-minimization corrective (loading model retained).** The decision below — "create no rules surface now" — has been **superseded**. Under explicit user direction, the hard-minimization corrective (`GLOBAL_SNIPPET_HARD_MINIMIZATION_CORRECTIVE.md`) created a **two-tier rules architecture**: global-distribution `snippets/rules/*.md` (shipped because it sits under the `snippets/` payload root, so it installs to `<ToolRoot>/snippets/rules/` — it is **distributed**, not the non-distributed repo-root `/rules/` this decision worried about) and repo-only `<repo-root>/rules/*.md`, one rule group per file. GSF-B3's **loading model** (§2–§3: `rules/*.md` is not auto-loaded — instructed-read; a truly-always-on rule stays in the bootstrap) and its **vendor-specific boundary** (§4: no `.claude/rules/`, `.codex/rules/`, or `@import`) are **retained and followed**. Read §2–§4 and §6 as the still-valid model; read §1 / §5 "create nothing now" as superseded.

**Create no rules surface and no rules files in GSF-B3.** Keep the only always-loaded surfaces as today (the deployed snippet/managed-block + the repo-local root `CLAUDE.md` / `AGENTS.md` bootstrap); record the vendor-neutral rules loading model and the future adoption conditions; defer any `/rules/*.md`, `.claude/rules/`, or `.codex/rules/` to a separately-approved future batch that meets those conditions.

This is consistent with GSF-B2's result: **GSF-B2 found zero future AI-native rule candidates requiring immediate rule extraction**, so there is nothing to extract. GSF-B3 fixes the *model* (so a future "yes" is built correctly) without building anything.

---

## 2. Surface taxonomy — four distinct surfaces, not to be conflated

The presenting confusion this decision removes is treating "rules" as one surface. There are four, with different owners, loading semantics, and audiences:

| Surface | What it is | Loaded how (per user research) | Audience / nature |
|---|---|---|---|
| **vendor-neutral `/rules/*.md`** (repo-root `rules/` folder) | a **shared Markdown rule source** — team/workflow rules written once, readable by any tool | **NOT auto-loaded** by Claude or Codex by default; it is an inert Markdown source until something reads it | vendor-neutral, human- and agent-readable; public-safe team guidance |
| **root `CLAUDE.md` / `AGENTS.md`** | **bootstrap + instructed-read loaders** — the always-on repo-local instruction surface | **auto-loaded** by each tool at its repo root (Claude reads `CLAUDE.md`, Codex reads `AGENTS.md`) | the always-on defense line for developing *this* repo; mirror-edited shared body |
| **Claude `.claude/rules/*.md`** | **Claude-native path-scoped context rules** — rules Claude applies scoped to matching paths/contexts | Claude-native loading (path/context-scoped), **vendor-specific** | Claude-only; not a vendor-neutral source |
| **Codex `.codex/rules/*.rules`** | **Codex-native command execution policy** — command approval / permission policy | Codex-native command-policy loading, **vendor-specific** | Codex-only; **command-policy territory, NOT Markdown team/workflow guidance** |

The first two are the **vendor-neutral** axis (a shared Markdown source + symmetric bootstrap loaders). The last two are **vendor-specific** surfaces. **Do not conflate vendor-neutral shared Markdown rules with vendor-specific rules surfaces** — they differ in owner, loading, file format (`.md` prose vs `.rules` command policy), and audience.

---

## 3. Loading-model facts that drive the decision

(Per user research; attributed, not repo-verified — see *Basis*.)

1. **`/rules/*.md` is not auto-loaded by either vendor by default.** A repo-root `rules/` folder is an inert Markdown source. Putting a rule there does **not** make any agent read it automatically; something must point at it and instruct the read.
2. **Instructed-read through the root bootstrap is weaker than automatic inline loading, but it preserves vendor symmetry and keeps always-on token cost low.** The pattern would be: root `CLAUDE.md` / `AGENTS.md` (auto-loaded) names a `/rules/X.md` file and the condition under which to read it; the agent reads it on demand. This is *weaker* than auto-inlining (the agent may not read it if the trigger is missed — the same under-triggering risk skills carry) but it (a) works identically for Claude and Codex (vendor symmetry) and (b) costs only the one-line pointer in always-on context, not the rule body.
3. **Any truly always-on, pre-read rule must remain in the root `CLAUDE.md` / `AGENTS.md` bootstrap, kept extremely small.** If a rule genuinely must be present before any task and cannot tolerate instructed-read's miss risk, its only correct home is the auto-loaded bootstrap (or, for adopter-universal invariants, the deployed snippet/managed-block per `docs/README.md` §4) — **not** `/rules/*.md` (which is not auto-loaded). The bootstrap must stay tiny; it is not a rule warehouse (that would re-create the policy-warehouse pattern GSF exists to end).
4. **Claude `@rules/*.md` import is possible but asymmetrical and increases always-on context cost; not adopted now.** Claude can `@`-import a file into `CLAUDE.md` so it is inlined into always-on context. That defeats the low-always-on-cost goal (it pays the full rule body every session) and is **asymmetrical** (Codex `AGENTS.md` has no equivalent `@import`, so the two tools would diverge — breaking the mirror-edit symmetry). **`@import` is not adopted in GSF-B3** (and is on this batch's forbidden list).

**Coherence with design §9 "shipped-globally ≠ applied-always-on."** Because `/rules/*.md` is not auto-loaded, it can be *shipped* (distributed with the toolset, or present in a repo) without being *applied always-on*. The three rule kinds map onto the surfaces accordingly: a **global-always-on** rule cannot live in `/rules/` (not auto-loaded) — it must be in the deployed snippet/managed-block; a **repo-local** rule belongs in the root bootstrap (tiny, always-on) or `/rules/*.md` (instructed-read) for *this* repo; a **global-distributed** rule library is the natural `/rules/*.md` use — shipped but opt-in per project, never auto-applied.

---

## 4. Vendor-specific surfaces — separate approval, no conflation

- **`.claude/rules/` and `.codex/rules/` are vendor-specific surfaces and require separate explicit approval if ever introduced.** They are not part of GSF-B3 and are not created here. Introducing either is its own scoped decision with its own approval (and `.claude/` / `.codex/` directories are on this batch's forbidden list).
- **Codex `.codex/rules/*.rules` must not be used for Markdown team/workflow rules.** It is **command execution policy** territory (command approval / permission), not prose workflow guidance. This aligns with `INSTRUCTION_SURFACE_PLAN.md` §12 (Codex Rules are a vendor-specific command-permission surface, excluded from the instruction-surface architecture and not to be treated as a docs trigger map / source-of-truth / global delivery surface). A team workflow rule never belongs in `.codex/rules/*.rules`.
- **The no-hook hard boundary still holds.** A rule is never implemented via a hook to compensate for weak instruction/skill design (`INSTRUCTION_SURFACE_PLAN.md` §11). Hooks remain forbidden-by-default and out of scope.

---

## 5. Why GSF-B3 creates nothing now

- **GSF-B2 found zero immediate rule candidates.** The GSF-B2 audit (`GLOBAL_SNIPPET_FIRST_GSF_B2_CLASSIFICATION.md`) classified `docs/**` and tagged **zero** `future AI-native rule candidate` items; its findings are duplication / staleness / pointer-hygiene with existing tracked owners, not unowned rules needing a new surface. GSF-B1 likewise surfaced no rule that needed a `rules/` home (the snippet's hard-boundary bullets were classified keep / GSF-B3-tagged loading-class only, never extracted). With no candidate, there is nothing to extract.
- **Building a `rules/` surface with no rule is the broad-catalog anti-pattern** the design (§9) and plan (§2) forbid. An empty or speculative `rules/` folder is exactly the "park removed content in a new rules/ catalog now" anti-pattern (design §12). GSF-B3 therefore builds nothing and only records the model + conditions.
- **A deterministic-guard candidate would go to `tests`/verifier first** (plan §2; design §8 step 3), not to `rules/`. None exists now either.

---

## 6. Future adoption conditions

These conditions govern any later reversal. None is met today.

### 6.1 Creating a vendor-neutral `/rules/*.md` requires ALL of:

1. an **actual, repeated team rule with a clear owner** (an observed recurring rule, not a speculative one);
2. **unsuitable for docs reference only** (it is an active rule to follow, not reference/contract/decision-record/rationale — otherwise it stays in `docs/**`);
3. **unsuitable for a skill / script / test / verifier** (it is not an intent-triggered procedure, executable behavior, or deterministic guard — those owners win first, per design §8);
4. **small enough to be read on demand** (instructed-read viable; not so large it must be auto-inlined);
5. **useful to both Claude and Codex** (vendor-neutral — otherwise it is a vendor-specific surface, §6.2);
6. **public-safe and vendor-neutral** (tracked, no machine/user-specific or vendor-coupled content — `REPO_LOCAL_INSTRUCTION_SURFACE_PLAN.md` §7).

If a candidate meets all six, the adoption batch also decides its loading wiring (instructed-read pointer in the root bootstrap — never `@import`, never auto-load assumption) and stays within the no-broad-catalog limit (one real rule, not a speculative set).

### 6.2 Creating a vendor-specific rules surface requires (separately, explicitly):

- **`.claude/rules/`** — only for **Claude path-scoped context rules**, and only when **path-scoped loading is materially useful** (a rule that genuinely benefits from Claude applying it scoped to matching paths, where a vendor-neutral instructed-read would be materially worse). Claude-specific; separate approval.
- **`.codex/rules/`** — only for **Codex command execution policy**, **never** for prose / workflow guidance. Command-policy territory (`INSTRUCTION_SURFACE_PLAN.md` §12). Codex-specific; separate approval; not a substitute for vendor-neutral Markdown rules.

A rule that is useful to both tools is vendor-neutral (§6.1), not a reason to create two divergent vendor-specific copies.

---

## 7. Relationship to GSF-B2 and GSF-B4

- **GSF-B2's zero-rule-candidates result is preserved.** This decision does not re-open or re-classify GSF-B2; it confirms that, with zero candidates, no rules surface is warranted, and records the model for any future candidate.
- **GSF-B4 may consume GSF-B2 findings without needing `/rules/` first.** GSF-B4 (owner-migration-gated docs deletion/compression/retirement) acts on the GSF-B2 findings' existing tracked owners (contracts, skills, scripts, the root bootstrap, the deployed snippet) — none of which is a `rules/` surface. **GSF-B4 is not blocked on GSF-B3 creating any rules file**, and GSF-B3 creating nothing does not constrain GSF-B4. The two are independent; GSF-B4 remains its own separately-approved batch with its owner-migration-evidence + four-class-reference-sweep gate.

---

## 8. What this decision does NOT do (boundaries)

- Creates no `/rules/`, no `.claude/`, no `.codex/`, no `.claude/rules/`, no `.codex/rules/`, no `.rules` files, no Markdown rule files.
- Adds no `@import` directive; adopts no auto-load wiring.
- Edits no global snippet payload and no root `CLAUDE.md` / `AGENTS.md` body (the loading model is recorded here as a decision; it routes operators via the registrations in §9 — it does not require a bootstrap edit, and none is made).
- Builds no hook; changes no runtime / install / update / uninstall / skill-procedure behavior; moves no ToolRoot; inspects no memory; creates no snapshot/manifest; does not commit/push.
- Does not implement, or unblock, any GSF-B4 delete/compress/retire fix, and does not fix B2-F01 or any GSF-B2 finding.

---

## 9. Coherence registrations (two-level closeout)

Per the two-level closeout gate (`DOCS_OPERATING_MODEL.md` §7), inspect-all / report-each. GSF-B3 is decision-only (one new record + pointer registrations; no rules surface, no body edit, no snippet/skill/code change):

**Level 1 (top-down orientation):**
- `docs/current/SOURCE_OF_TRUTH.md` — **updated** (Q11): registers this decision record as landed (decision-only) and reconciles the Q11 lines so GSF-B3 is no longer listed among the *remaining* implementing tracks (only GSF-B4 + Track E remain).
- `docs/roadmap/CURRENT_MILESTONES.md` — *checked: no change required* (no numbered-milestone status changed; `GSF-Bn` is the migration's own namespace).
- `docs/decisions/POST_MVP_PLAN.md` — *checked: no change required* (numbered-order authority unchanged).

**Level 2 (system-local):**
- `docs/architecture/README.md` — **updated** (instruction-surface row): lists this GSF-B3 decision record alongside the design / plan / spec / GSF-B1 / GSF-B2 records.
- `docs/architecture/instruction-surface/GLOBAL_SNIPPET_FIRST_MIGRATION_PLAN.md` — **updated** (§2 GSF-B3 "decision landed" status bullet; the §"Stage flow" line reconciled so GSF-B3 is no longer a purely-future stage).
- `docs/systems/skills/STATUS.md` — *checked: no change required* (GSF-B3 changed no snippet / skill / deployed surface, so no SK ledger row and no current-state flip; SK-00…SK-05 remain accurate).
- existing `INSTRUCTION_SURFACE_PLAN.md` / `GLOBAL_SNIPPET_RELOCATION_AUDIT.md` / `REPO_LOCAL_INSTRUCTION_SURFACE_PLAN.md` / `FUNCTION_LEVEL_SKILL_ARCHITECTURE_PLAN.md` / the GSF design / spec / GSF-B1 / GSF-B2 records — *checked: intentionally not edited* (preserved as prior evidence; this record routes to them — esp. `INSTRUCTION_SURFACE_PLAN.md` §11/§12 and the design §8/§9, which this decision applies without redefining).

---

## 10. Approval boundaries

- This document **approves nothing** beyond recording the decision "create no rules surface now" + the loading model + the future conditions. It is decision-only.
- It creates no rules surface and authorizes none. Any future `/rules/*.md`, `.claude/rules/`, or `.codex/rules/` is a separate scoped goal meeting §6's conditions, with its own Codex review and explicit user approval.
- A Codex review verdict (`yes` / `no` / `yes with risk`) on this decision does not auto-approve any rules surface, any GSF-B4 action, or any commit/push — each remains an explicit user decision.

## 11. One-line summary

Fix the vendor-neutral rules **loading model** — `/rules/*.md` is a not-auto-loaded shared Markdown source, the root `CLAUDE.md`/`AGENTS.md` are the auto-loaded bootstrap + instructed-read loaders (truly always-on rules stay there, tiny; `@import` rejected as asymmetrical/costly), and `.claude/rules/` / `.codex/rules/*.rules` are vendor-specific surfaces (the latter command-policy, never Markdown workflow) needing separate approval — and **decide to create nothing now** (GSF-B2 found zero rule candidates), recording the six `/rules/` adoption conditions and confirming GSF-B4 can proceed on GSF-B2 findings without any `rules/` surface.
