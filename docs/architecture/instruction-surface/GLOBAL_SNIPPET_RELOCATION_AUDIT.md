# Global Snippet Residual Relocation Audit — Track B

**Status: design-stage audit / classification source. NOT an implementation-approval document and NOT a snippet edit.** This file classifies every remaining section (and meaningful sub-block) of the always-loaded global snippet (`snippets/CLAUDE_SNIPPET.md` / `snippets/AGENTS_SNIPPET.md`) into a relocation disposition, so a later implementation batch can act on a decided map instead of re-deriving it. It changes no snippet, skill, script, runtime, or behavior. The relocation/reduction it proposes is **Track D** (and the deletions are skill-plan **Batch 3**); each of those is a separate scoped goal + Codex review gate + explicit user approval. **This document approves none of them.**

**Placement / location.** This is Track B of `docs/architecture/instruction-surface/INSTRUCTION_SURFACE_PLAN.md` §14. The plan does **not** name a specific Track B artifact file, so this audit is placed in the plan's own subfolder under the agreed name `GLOBAL_SNIPPET_RELOCATION_AUDIT.md` — co-located with the plan it serves, consistent with how `docs/systems/skills/` holds the skill plan plus its STATUS in one subfolder. Authorities obeyed (not redefined): `docs/architecture/instruction-surface/INSTRUCTION_SURFACE_PLAN.md` (§2 trigger-tier model, §3 global policy, §4 snippet responsibility, §9 classification criteria); `docs/systems/skills/FUNCTION_LEVEL_SKILL_ARCHITECTURE_PLAN.md` §4/§5/§8 (snippet↔skill split + Batch 3/4 order); `docs/README.md` §4 (always-on bar); `docs/policies/DOCS_OPERATING_MODEL.md` §1 (single-home-plus-pointers).

**Audit basis.** Snippet content as of repo `HEAD == ea61048`. Both snippets carry **11 H2 sections** at that snapshot; each is classified per-section in §3 below.

---

## 1. Method

Each section/sub-block is classified by the §2 trigger-tier model: the tier with the **narrowest sufficient presence** wins, and anything that can be owned by a skill `description` / `SKILL.md` / `docs/contracts` / install docs / repo-local instruction without breaking global-adopter behavior must not stay in the always-loaded snippet (`INSTRUCTION_SURFACE_PLAN.md` §3). Disposition vocabulary (this batch): **global keep**, **repo-local CLAUDE.md/AGENTS.md candidate**, **skill `description` candidate**, **`SKILL.md` candidate**, **`docs/contracts` candidate**, **install/update docs candidate**, **delete**, **Batch 3 defer**, **Track D defer**, **out of scope**.

Two recurring distinctions used below:
- **Authority vs operative residue.** Several invariants have a single-home *authority* in a non-deployed `docs/**` doc, but the snippet keeps a compact *operative* statement because `docs/**` is **not deployed** to a global adopter (only `config/`/`scripts/`/`snippets/`/`templates/` are). Such items are **global keep** with a noted authority pointer — not a move, because moving the only deployed copy would break the adopter.
- **Delete vs defer.** Outright deletes of non-current items are owned by skill-plan **Batch 3** (the user excluded Batch 3 implementation here), so non-current sections are **Batch 3 defer**, not **delete**, in this audit. This extends to any **boundary note that references a Batch-3-removed concept** (e.g. the `## Forbidden` no-auto-mirror bullet): per `FUNCTION_LEVEL_SKILL_ARCHITECTURE_PLAN.md` §7/§8 the end snippet retains "no non-current section, capability claim, **or boundary note**", so such a bullet is **Batch 3 defer**, not unconditional global-keep — its substance may survive only as a generic form that Batch 3 decides (3.10).

**Binding status of this audit.** This audit is the **binding Track B output** (`INSTRUCTION_SURFACE_PLAN.md` §14). The plan's own §9 carries a **non-binding first-pass disposition** that explicitly invited the Track B audit to "re-derive and apply" it. Where this audit differs from that first pass — notably the `## Other rules` PowerShell-authoring rules, which the §9 first pass listed as global-keep cross-task invariants and this audit reclassifies as **repo-local candidates** under the trigger-tier narrowest-presence test (3.11) — **this audit governs** and the §9 first pass is the superseded hypothesis. Question routing: `docs/current/REPO_READING_GUIDE.md` Q11 (Primary = the plan; this audit = the binding Track B classification).

## 2. Claude/Codex symmetry baseline

A direct line diff of the two snippets shows the differences are confined to **four loci**; **all eight other sections are byte-identical**:

1. **Intro (title line + first paragraph)** — tool name and destination filename: "CLAUDE.md-compatible agents … Claude Code … destination `CLAUDE.md`" vs "AGENTS.md-compatible agents … Codex CLI … destination `AGENTS.md`". Expected.
2. **`## Adoption destination`** (whole section) — necessarily tool-specific: Claude lists `CLAUDE.md` root + `%USERPROFILE%\.claude\CLAUDE.md` (2 destinations); Codex lists `AGENTS.md` root + `%USERPROFILE%\.codex\AGENTS.md` / `%CODEX_HOME%\AGENTS.md` + the `AGENTS.override.md` precedence note (3 destinations). Both share the forbidden `%USERPROFILE%\.claude\AGENTS.md` rule; each names the *other* tool's path.
3. **`## Adoption rules`** — one phrase, a direct consequence of the locus-2 destination-count difference: "Whole-file overwrite of **either** destination" (Claude, 2 destinations) vs "**any of those** destinations" (Codex, 3 destinations).
4. **`## Role neutrality`** — two phrases: Claude binds "reviewer **or auditor**" and "Form **any** verdict"; Codex binds "reviewer" and "Form **the** verdict". (Otherwise identical.)

**Default symmetry rule for relocation:** keep the two snippets structurally symmetric. The tool-specific paths/names in the intro and `## Adoption destination` (loci 1–2) stay per-tool, and the locus-3 wording is a justified consequence of the destination count. Everything else should move/keep identically in both, and any single-snippet edit to a byte-identical section is itself an asymmetry defect. The locus-4 Role-neutrality differences ("or auditor", "any/the verdict") read as minor unintended drift and are a **Track D** symmetry-reconciliation candidate (pick one canonical wording for both), not a relocation.

---

## 3. Per-section classification

### 3.0 Managed-block header (lines 2–4)
- **Text (summary):** "This is a manually adopted AI instruction payload … inside a managed block … Treat its content as authoritative for ai-harness workflows in this project."
- **Disposition:** **global keep.** Payload self-description; orients any adopter to the managed-block model before anything else.
- **Trigger-tier rationale:** global-instruction tier — adopter-universal, pre-skill, present every session.
- **Duplicated?** Conceptually with `docs/decisions/GLOBAL_ADOPTION_DECISION.md` §6 (managed-block policy authority), but this is the deployed operative header.
- **Prerequisite to move?** N/A. **Symmetry:** intro title + paragraph differ in tool name and destination filename (expected; §2 locus 1). **Risk if removed early:** medium (adopter loses managed-block framing). **Next action:** keep.

### 3.1 `## Adoption destination`
- **Text (summary):** valid destinations (tool root + user-global); the forbidden `%USERPROFILE%\.claude\AGENTS.md`; the other tool's path.
- **Disposition:** **global keep.**
- **Trigger-tier rationale:** adopter-universal hard adoption discipline that must be visible before any skill triggers; its absence enables a wrong-destination or forbidden-path write. No `ai-harness-toolset`-only specifics are present, so no repo-local split is warranted.
- **Duplicated?** Authority = `docs/decisions/GLOBAL_ADOPTION_DECISION.md` §6 (non-deployed). The forbidden `.claude\AGENTS.md` also appears in `## Forbidden` (intra-snippet duplication — see 3.10 / Track D dedup note).
- **Prerequisite to move?** N/A. **Symmetry:** **tool-specific by necessity** — must stay per-tool. **Risk if removed early:** high (whole-file/forbidden-path write). **Next action:** keep; Track D may dedup the `.claude\AGENTS.md` overlap with `## Forbidden` into one home.

### 3.2 `## Adoption rules`
- **Text (summary):** managed-block-only adoption; no whole-file overwrite; explicit-approval mutation; marker fail-fast.
- **Disposition:** **global keep.**
- **Trigger-tier rationale:** core adoption hard boundary, adopter-universal, pre-skill. Removing it risks whole-file overwrite of a global instruction file.
- **Duplicated?** Authority = `GLOBAL_ADOPTION_DECISION.md` §6 (non-deployed); overlaps the "no whole-file mutation" bullet in `## Forbidden`.
- **Prerequisite to move?** N/A. **Symmetry:** near-identical ("either"/"any of those" destinations); keep symmetric. **Risk if removed early:** high. **Next action:** keep.

### 3.3 `## Role neutrality`
- **Text (summary):** payload is role-neutral; operator/reviewer/auditor/supervisor; reviewer-mode binding subset + reviewer-mode exclusion (no Brief/restore, no questions, produce the canonical verdict); operator-side protocols apply only as operator; nothing forces approve.
- **Disposition:** **global keep.**
- **Trigger-tier rationale:** role-binding + reviewer-mode exclusion is an always-on invariant that must hold before any skill loads — a reviewer reading the global file must not fire operator-side restore/questions. Genuinely adopter-universal.
- **Duplicated?** The reviewer-mode exclusion is **also** enforced by `scripts/review-run.ps1`'s in-band reviewer preamble (deployed) and `docs/contracts/review/REVIEW_RESULT_CONTRACT.md` (non-deployed). The snippet copy still matters for reviewer/auditor flows that load the global file outside `review-run` (belt-and-suspenders).
- **Prerequisite to move?** N/A (keep). **Symmetry:** **asymmetry (§2 locus 4)** — Claude binds "reviewer **or auditor**" + "Form **any** verdict"; Codex binds "reviewer" + "Form **the** verdict" → **Track D defer** (align to one canonical wording). **Risk if removed early:** high (verdict-parse failures, operator-side prompts in reviewer mode). **Next action:** keep global; Track D align the auditor + verdict-article wording across both snippets.

### 3.4 `## Project layout`
- **Text (summary):** `<ToolRoot>`/`<ProjectRoot>` definitions; ToolRoot channel-resolution order (incl. `%USERPROFILE%\.claude\ai-harness-toolset\current`); `log/` layout; canonical review-record path; reviewer-config path.
- **Disposition:** **global keep** (section) — **with one out-of-scope carve-out:** the literal global-stable ToolRoot path **string** value is governed by the vendor-neutral ToolRoot decision (§13 of the plan / Track E) and is **out of scope** here ("do not move ToolRoot").
- **Trigger-tier rationale:** path/topology invariants hold independently of any skill invocation and are needed always-on; `docs/**` (the authority) is non-deployed, so the operative copy must stay.
- **Duplicated?** Authority = `docs/contracts/global-invocation/SHARED_GLOBAL_INVOCATION_CONTRACT.md` (D1–D9, ToolRoot/ProjectRoot resolution) + `docs/policies/REVIEWER_CONFIG_POLICY.md` (config path), both non-deployed. The canonical review-record path also restates in `## Review flow` (see 3.5 — fold candidate).
- **Prerequisite to move?** N/A (keep). **Symmetry:** byte-identical; keep symmetric. **Risk if removed early:** high (ToolRoot mis-resolution). **Next action:** keep; the ToolRoot path-string value is tracked by Track E (out of scope here); Track D may absorb the `## Review flow` record-path overlap into this section.

### 3.5 `## Review flow`
- **Text (summary):** canonical review artifacts live only under `…/<perspective>/pass-NN/` as the `input.md` + `result.md` pair; no sidecar JSON/hash-binding/external-staging; shape owned by `REVIEW_RESULT_CONTRACT.md`.
- **Disposition (content):** **global keep** — the **no-sidecar / two-file record hard boundary** is a genuine invariant. **Disposition (section as a unit):** **Track D defer** — the title "Review flow" mismatches the content (a *record boundary*, not a *flow*), and the record-path already restates `## Project layout`. Track D should **rename or fold** this into `## Project layout` (the SK-02 follow-up), preserving the no-sidecar invariant.
- **Trigger-tier rationale:** the no-sidecar record boundary is a hard boundary (global keep); the *procedure*/verdict-meaning correctly already lives in the skill + contract (not here).
- **Duplicated?** Yes — `## Project layout` (record path), `REVIEW_RESULT_CONTRACT.md` Q3 / `REPO_READING_GUIDE.md` Q3 (no-sidecar). Single-home pressure favors folding.
- **Prerequisite to move?** None beyond Track D care to not drop the no-sidecar invariant. **Symmetry:** byte-identical; fold/rename in both symmetrically. **Risk if removed early:** medium (careless fold could drop the no-sidecar hard boundary). **Next action:** **Track D** — fold into `## Project layout` or rename to `## Review record`; keep the no-sidecar invariant intact.

### 3.6 `## Result verdict vocabulary`
- **Text (summary):** the three values; "verdict approves nothing"; concise per-value meaning (yes / no / yes-with-risk distinctions); next-action mapping pointer to skill + contract.
- **Disposition:** **global keep.**
- **Trigger-tier rationale:** verdict semantics are reviewer-critical always-on (esp. "approves nothing" and `yes with risk` ≠ `yes`); the *detailed* next-action mapping is already pointer-referenced out (correct). The contract is non-deployed, so the quick-reference must stay.
- **Duplicated?** Authority = `REVIEW_RESULT_CONTRACT.md` (non-deployed) + `ai-harness-review` `SKILL.md` + `REPO_READING_GUIDE.md` Q3. Snippet keeps only the quick-reference.
- **Prerequisite to move?** N/A. **Symmetry:** byte-identical; keep symmetric. **Risk if removed early:** high (verdict misuse as commit approval). **Next action:** keep; **Track D** may trim the per-value meaning paragraph if it proves redundant with the kept "approves nothing" invariant (conservative — keep by default).

### 3.7 `## Operator stance`
- **Text (summary):** stay in approved scope; stop/report at a source/runtime/global/commit-push boundary; explicit retraction over silent overwrite; full stance lives in the skill + contract.
- **Disposition:** **global keep** (compact).
- **Trigger-tier rationale:** cross-task operator boundary stance, applies to every operator task (not just review); adopter-universal; the full stance is already pointer-referenced to the skill/contract.
- **Duplicated?** Full stance = `ai-harness-review` `SKILL.md` + `REVIEW_RESULT_CONTRACT.md`; the snippet keeps the compact always-on residue. (Not a toolset-dev-only rule, so not repo-local.)
- **Prerequisite to move?** N/A. **Symmetry:** byte-identical; keep symmetric. **Risk if removed early:** medium (out-of-scope absorption, silent overwrite). **Next action:** keep compact.

### 3.8 `## Brief`
- **Text (exact):** "BF Level 3 — automated Brief management — is not implemented in this toolset. Do not claim that capability."
- **Disposition:** **Batch 3 defer.**
- **Trigger-tier rationale:** a non-current-capability note; the plan's current-capability-only rule says the snippet must not retain an unimplemented item even as a "future/deferred" note (`INSTRUCTION_SURFACE_PLAN.md` §9; skill plan §7/§8 Batch 3). Its authoritative deferred record is `docs/systems/brief/DEFERRED.md` (non-deployed).
- **Duplicated?** Yes — `docs/systems/brief/DEFERRED.md` + `POST_MVP_PLAN.md` §5 (BF lv3 deferred).
- **Prerequisite to move?** None — it is a delete, owned by **Batch 3** (not done here). **Symmetry:** byte-identical; Batch 3 removes from both. **Risk if removed early:** low, but removing it outside the Batch 3 scoped goal bypasses that gate. **Next action:** **Batch 3 defer** (no action in Track B).

### 3.10 `## Forbidden in this toolset`
Seven bullets — **six are global keep** (core safety hard boundaries); the seventh (the no-auto-mirror bullet) is **Batch 3 defer** because it is a boundary note referencing a Batch-3-removed concept. Per-bullet notes:
- *No per-user/operator log partitioning / operator-id / machine-id / ownership metadata* — **global keep** (runtime-log hard boundary applying in any adopter project). Also a toolset-design invariant; conservatively global.
- *No `BF_STATE.json` / sidecar state-machine file* — **global keep** (forbidden-design invariant; also `POST_MVP_PLAN.md` §5/§8).
- *No daemon / watcher / scheduler / hook / background task* — **global keep, critical** (the no-hook invariant the whole architecture relies on).
- *No implicit/whole-file global-instruction mutation (enumerated paths)* — **global keep, critical**; overlaps `## Adoption rules`.
- *No creation of `%USERPROFILE%\.claude\AGENTS.md`* — **global keep**; **intra-snippet duplication** with `## Adoption destination` → **Track D** dedup candidate (one home).
- *No automatic auto-mirror of the Brief* — **Batch 3 defer (not unconditional global-keep).** It forbids a real automation, but it is a **boundary note that references a Batch-3-removed concept**, and skill plan §8 keeps "no non-current section, capability claim, or boundary note" in the end snippet — so this audit must not pre-classify it as global-keep. Its *substance* (a no-auto-mirror automation guardrail) is a candidate to survive only in a **generic form**, and that decision is **Batch 3's** (drop if already covered by the no-daemon/no-auto rules, or keep a generic Brief-mirror guardrail) — owned by skill plan §8, not pre-empted here.
- *No automatic target `.gitignore` mutation* — **global keep**.
- **Duplicated?** `POST_MVP_PLAN.md` §8 (hard guardrails), §5 (BF); `## Adoption rules` / `## Adoption destination` (overlaps noted). Snippet is the deployed operative home.
- **Prerequisite to move?** N/A for the six global-keep bullets. **Symmetry:** byte-identical; keep/defer symmetric across both snippets. **Risk if removed early:** **very high** for the six safety boundaries (keep); for the mirror bullet, low — but its disposition belongs to Batch 3, not this audit. **Next action:** keep the six; **defer the no-auto-mirror bullet to Batch 3** (reconcile to a generic guardrail or drop); Track D dedup the `.claude\AGENTS.md` overlap with `## Adoption destination`.

### 3.11 `## Other rules`
Four bullets — **split disposition**:
- *Commit and push require explicit user approval* — **global keep, critical** (the commit/push gate; adopter-universal hard boundary; also `POST_MVP_PLAN.md` §8).
- *`.ps1` files must be UTF-8 with BOM + CRLF* — **repo-local CLAUDE.md/AGENTS.md candidate.** This is a **PowerShell-authoring convention**: always-on for *this* repo (all scripts are `.ps1`) but conditional/irrelevant for a generic adopter with no PowerShell. It is exactly the kind of repo-development rule the plan says leaked into the global payload (`INSTRUCTION_SURFACE_PLAN.md` §1). Authority/detail = `docs/policies/POWERSHELL_POLICY.md` (non-deployed).
- *Native-exe output: keep stdout/stderr/exit separate (no `2>&1`/`Out-String`/…)* — **repo-local CLAUDE.md/AGENTS.md candidate** (same PowerShell-specific reasoning; authority `docs/policies/POWERSHELL_POLICY.md` + `docs/policies/CLI_ENVIRONMENT_ASSUMPTIONS.md`).
- *Temporary files cleaned up by the operator before closeout* — **global keep** (generic operator hygiene, adopter-universal).
- **Duplicated?** The two PowerShell rules are authored in `docs/policies/POWERSHELL_POLICY.md` (authority); commit/push approval overlaps `POST_MVP_PLAN.md` §8.
- **Known wording tension to reconcile:** `FUNCTION_LEVEL_SKILL_ARCHITECTURE_PLAN.md` §4 (and this plan's §9 non-binding first pass) currently call the `.ps1`/native-stream rules "cross-task execution invariants" that "genuinely apply to every task" — i.e. global-keep. This audit deliberately **refines** that to repo-local (the rules bite only in PowerShell work; a non-PowerShell adopter never needs them — the trigger-tier narrowest-presence test). Per the §1 binding-status note this audit governs; the skill plan §4 wording is reconciled (or explicitly subordinated to this classification) **when Track C lands**, not in this audit.
- **Prerequisite to move?** **Yes — the two PowerShell rules require the repo-local instruction surface (Track C) to exist first.** Until a `<ProjectRoot>/CLAUDE.md` / `AGENTS.md` exists, they must stay in the global snippet (removing them early would drop the convention for the toolset's own development — drift to wrong encoding/merged-stream capture). **Symmetry:** byte-identical; move in both symmetrically. **Risk if removed early:** medium (toolset-dev convention loss before Track C lands). **Next action:** commit/push + temp-cleanup = global keep; the two PowerShell rules = **repo-local candidate**, executed in **Track C**, gated on the repo-local surface existing.

---

## 4. Classification summary by destination

| Destination | Sections / sub-blocks |
|---|---|
| **global keep** | Managed-block header (3.0); Adoption destination (3.1); Adoption rules (3.2); Role neutrality (3.3); Project layout (3.4, except ToolRoot path-string value); Review flow *content* — the no-sidecar record boundary (3.5); Result verdict vocabulary (3.6); Operator stance (3.7); Forbidden — 6 of 7 bullets (3.10); Other rules — commit/push approval + temp-file cleanup (3.11) |
| **repo-local CLAUDE.md/AGENTS.md candidate** | Other rules — `.ps1` UTF-8 BOM+CRLF + native-stream separate-capture (3.11). *Prerequisite: Track C (repo-local surface must exist first); authority `docs/policies/POWERSHELL_POLICY.md`.* |
| **skill `description` candidate** | none — discovery already owned by each skill's `description`; the snippet correctly carries no routing pointer/index/table (do not reintroduce). |
| **`SKILL.md` candidate** | none — review/Brief procedures already extracted to `ai-harness-review` / `ai-harness-brief`. |
| **`docs/contracts` candidate (move)** | none to *move* — the contract authorities already exist (`SHARED_GLOBAL_INVOCATION_CONTRACT.md`, `REVIEW_RESULT_CONTRACT.md`, `BRIEF_CONTRACT.md`); the snippet keeps only *operative residue* because `docs/**` is non-deployed. (Listed as authority pointers, not relocations.) |
| **install/update docs candidate (move)** | none to *move* — Adoption destination/rules are operative adopter discipline; `GLOBAL_ADOPTION_DECISION.md` §6 is the authority but the snippet must keep the deployed operative copy. |
| **delete (now)** | none — outright deletes are Batch-3-owned (below). |
| **Batch 3 defer** | Brief — BF-lv3 non-claim (3.8); another non-current section; Forbidden — the no-auto-mirror bullet (a boundary note referencing a Batch-3-removed concept; substance may survive only in generic form, Batch 3's call) (3.10). |
| **Track D defer** | Review-flow rename/fold into Project layout, preserving no-sidecar (3.5); Role-neutrality wording symmetry alignment — "or auditor" + "any/the verdict" (3.3); `.claude\AGENTS.md` intra-snippet dedup across Adoption destination + Forbidden (3.1/3.10); optional verdict-meaning trim (3.6). |
| **out of scope** | Project-layout ToolRoot path-**string** value → vendor-neutral ToolRoot decision / Track E ("do not move ToolRoot" this batch). |

**Headline finding.** The only *content* that should leave the global snippet for a *new* home is the two PowerShell-authoring rules in `## Other rules` → **repo-local instruction (Track C)**. Everything else is either a genuine global invariant (keep), a Batch-3-owned non-current-item removal (Brief + another non-current section), or a Track-D in-snippet cleanup (fold/dedup/symmetry). No section is a skill-`description` / `SKILL.md` / contract / install-docs *relocation* target — those surfaces already own their procedures, and the snippet's overlaps are deployed operative residue of non-deployed authorities, not duplications to move.

## 5. Sections requiring Track C / D / F follow-up (with dependencies)

> **Execution status (post-audit; current status of record = `docs/systems/skills/STATUS.md` SK-03).** Track C landed (root `CLAUDE.md` / `AGENTS.md` created). **Track D then landed** items (a) — `## Review flow` **renamed** `## Review record` (the *rename* option was chosen over fold; no-sidecar invariant preserved) — and (b) the Role-neutrality wording **aligned** symmetric, plus the PowerShell-rule **removal** from `## Other rules` (the Track C→D handoff). Items (c) the `.claude\AGENTS.md` dedup and (d) the verdict-meaning trim were **declined** (would weaken a hard boundary / the always-on verdict boundary). **Track F (Batch 3)** and **Track E** remain deferred. The classification/recommendations below are preserved as the binding Track B rationale, pinned to the §"Audit basis" snapshot.

- **Track C (repo-local instruction implementation):** move the two PowerShell-authoring rules (3.11) into the approved `<ProjectRoot>/CLAUDE.md` / `AGENTS.md` surface, then drop them from the global snippet. **Hard dependency:** the repo-local surface must exist *before* the snippet drops them (do not remove early).
- **Track D (global snippet aggressive reduction / in-snippet cleanup):** (a) fold/rename `## Review flow` into `## Project layout` keeping the no-sidecar invariant (3.5 / SK-02); (b) align the Role-neutrality wording across Claude/Codex — "reviewer or auditor" vs "reviewer", and "Form any verdict" vs "Form the verdict" (3.3); (c) dedup the `.claude\AGENTS.md` rule between Adoption destination and Forbidden (3.1/3.10); (d) optionally trim the verdict-meaning paragraph (3.6). All symmetric across both snippets.
- **Track F = skill-plan Batch 3:** delete `## Brief` (BF-lv3 non-claim, 3.8) and another non-current section, **plus decide the `## Forbidden` no-auto-mirror bullet** (3.10 classifies it Batch 3 defer, not global-keep). **Reconciliation dependencies inside Batch 3:** preserve the "current restore source = Brief" pointer elsewhere if still wanted (owned by `ai-harness-brief` / `BRIEF_CONTRACT.md`); and for the mirror bullet, either **drop** it (if the no-daemon/no-auto rules already cover it) or **keep a generic Brief-mirror guardrail** so the boundary survives. This bullet's disposition is owned by skill plan §8, not pre-empted by this audit.
- **Track E (vendor-neutral ToolRoot, separate decision surface):** the ToolRoot path-**string** in `## Project layout` (3.4) — out of scope here.

**Sequencing note.** Track D and Batch 3 both edit the snippet and overlap (Batch 3 deletes the non-current sections; Track D folds/dedups around them); the safe order is Batch 3 first (remove non-current sections) then Track D (cleanup of what remains), or run them as one combined snippet-edit batch with a single Codex review. Track C is independent of the symmetry/fold work but must precede the PowerShell-rule removal. None of these is executed or approved here.

## 6. Approval boundaries

- This document **approves nothing** and edits **no** snippet/skill/script/test. It is a classification source for Track C/D and Batch 3.
- Producing it does not authorize: snippet/skill/script/test edits; creating `CLAUDE.md`/`AGENTS.md`/`.claude`/`.codex`; running `/init`; moving ToolRoot; implementing Batch 3/4; memory inspection/export/cleanup; hooks or Codex Rules; snapshot/manifest; or commit/push.
- A Codex review verdict on this audit (`yes` / `no` / `yes with risk`) does not auto-approve any relocation/reduction batch or any commit/push — each remains an explicit user decision.
