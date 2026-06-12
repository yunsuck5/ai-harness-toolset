# Global Snippet First — GSF-B1 Classification Record

> **당시-경로 주석 (review 도메인 이주, batch R).** 본 기록 안의 review 문서 경로·식별자(`docs/contracts/review/**` · `docs/contracts/evidence/**` · `docs/policies/REVIEWER_CONFIG_POLICY.md` · `docs/policies/REVIEW_EFFORT_GUIDE.md` · `docs/systems/review/**`)는 작성 시점 경로다 — review 도메인은 이후 `docs/review/`(spec-of-record `review_spec.md` · queue `review_backlog.md`)로 이주했고 구계열 본문은 git history 에 보존된다.

**Status: binding GSF-B1 per-item classification record + implementation log.** This is the reviewable artifact the GSF-B1 spec (`GLOBAL_SNIPPET_FIRST_MIGRATION_SPEC_GSF_B1.md` §4) requires: a keep-by-proof disposition for every current snippet inventory item, plus the snippet-invariant check result. It is the decision record for the GSF-B1 snippet edit (a docs decision-record, sibling to the Track B `GLOBAL_SNIPPET_RELOCATION_AUDIT.md`; placed here rather than in gitignored `log/` so the rationale is durable and reviewable). Authorities obeyed: the design / plan / spec (controlling), `docs/policies/DOCS_OPERATING_MODEL.md` (single-home-plus-pointers).

**Basis.** Snippet content as of `HEAD == 6ca0e63` (pre-GSF-B1): `snippets/CLAUDE_SNIPPET.md` / `snippets/AGENTS_SNIPPET.md`, managed-block header + 11 H2 sections.

**Headline outcome.** GSF-B1 makes **one** snippet change: **compress** — fold `## Review record` into `## Project layout` (removing the standalone section, preserving the no-sidecar two-file record invariant), eliminating the review-record-path duplication between the two sections (single-home-plus-pointers). Every other non-deferred item is **keep**, proven under keep-by-proof. `## Brief` (BF-lv3 non-claim), another non-current section, and the no-auto-mirror `## Forbidden` bullet are **defer → skill-plan Batch 3 / Track F** (not re-owned, not edited here). Snippet section count **11 → 10 H2**.

**Why mostly keep (deviation from "keep is the exception", justified per spec §1).** The big absorb candidates the design named — review procedure, Brief procedure, install/update procedure, skill routing/fallback, docs pointers — are **already absent** from the snippet (extracted to the `ai-harness-review` / `ai-harness-brief` skills + removed by Batch 1/2 and the routing-pointer-removal batch, PowerShell rules moved to the repo-local root files by Track D). What remains is the irreducible adopter-universal invariant core. For each, keep-by-proof KP2 fails to find a *better deployed* owner: `docs/**` is not deployed (design §6), the skills are capability-specific and not loaded in all reviewer/auditor modes, and the repo-local root files are repo-development-only (not adopter-universal). So these are genuine **(a)** keeps (design §6), not operative-residue parked for lack of effort. The honest GSF-B1 minimization is therefore the one duplication-removing fold + the Batch-3 defers; the substantive section removals (the non-current sections) are Batch-3-owned.

---

## Per-item classification

Disposition vocabulary: `keep` / `absorb` / `move` / `compress` / `delete` / `defer` / `stop/report` (spec §4). Loading-class only for rule-like candidates (spec §6); else `n/a`.

### 0. Managed-block header (intro)
- **disposition:** keep
- **owner-surface:** snippet · **loading-class:** n/a
- **keep-by-proof:** KP1 (not a feature) ✓; KP2 (no better owner — orientation text) ✓; KP3 (every adopter, pre-skill — must frame the managed block before anything) ✓; KP4 (self-contained) ✓; KP5 (low drift) ✓; KP6 (public default) ✓.
- **invariant-impact:** none dropped (orientation only). **rationale:** payload self-description; tool-name/destination intro is a §2 symmetry locus (per-tool). Authority: `docs/decisions/GLOBAL_ADOPTION_DECISION.md` §6 (non-deployed).

### 1. `## Adoption destination`
- **disposition:** keep · **owner-surface:** snippet · **loading-class:** n/a
- **keep-by-proof:** KP1 ✓ (adoption discipline, not executable behavior); KP2 ✓ (apply-managed-block.ps1 *enforces* mechanics but the destination policy is instruction the AI follows before/while adopting; no deployed instruction owner — `docs/**` not deployed); KP3 ✓ (pre-skill; absence → wrong-destination/forbidden-path write); KP4 ✓; KP5 ✓; KP6 ✓.
- **invariant-impact:** adoption/path-topology invariant (check #2) preserved. **rationale:** hard adoption discipline; tool-specific destinations are a §2 symmetry locus. Authority: `GLOBAL_ADOPTION_DECISION.md` §6.

### 2. `## Adoption rules`
- **disposition:** keep · **owner-surface:** snippet · **loading-class:** n/a
- **keep-by-proof:** KP1–KP6 ✓ (managed-block-only adoption / no whole-file overwrite / marker fail-fast are adopter-universal hard boundaries; the script is a guard, the rules are the instruction).
- **invariant-impact:** adoption invariant (check #2) + the no-whole-file-overwrite hard boundary (check #1) preserved. **rationale:** keep; "either"/"any of those" is a §2 symmetry locus.

### 3. `## Role neutrality`
- **disposition:** keep (spec §4.1 "keep or compress; impl-determined" → **determined: keep**)
- **owner-surface:** snippet · **loading-class:** n/a
- **keep-by-proof:** KP1 ✓; KP2 — the reviewer-mode exclusion is *also* enforced by `scripts/review-run.ps1`'s in-band reviewer preamble (a deployed partial owner), **but** an auditor/reviewer loading the global file *outside* `review-run` has no other reachable deployed source (belt-and-suspenders; audit §3.3), so no single deployed surface fully owns it → KP2 ✓ for keep; KP3 ✓ (role-binding must bind before any skill, in every role); KP4 ✓; KP5 ✓ (Track D just aligned it); KP6 ✓.
- **invariant-impact:** role-binding invariant (check #3) preserved. **rationale:** kept whole (not compressed) — trimming the reviewer-mode exclusion risks dropping role-binding for non-`review-run` reviewer flows. Brief/session-restore *references* inside it are role-binding statements, not Brief capability claims; any Brief-reference cleanup is Batch 3's, not GSF-B1's.

### 4. `## Project layout`
- **disposition:** keep (+ receives the folded Review-record content, see item 5) · **owner-surface:** snippet · **loading-class:** n/a
- **keep-by-proof:** KP1 ✓; KP2 ✓ (scripts *use* ToolRoot/ProjectRoot resolution but the topology is instruction-tier knowledge an AI needs to locate things; authority `SHARED_GLOBAL_INVOCATION_CONTRACT.md` is non-deployed); KP3 ✓ (ToolRoot resolution precedes any skill); KP4 ✓; KP5 ✓; KP6 ✓.
- **invariant-impact:** path-topology invariant (check #2) preserved; **gains** the no-sidecar review-record invariant from the item-5 fold (preserved, check #4). **rationale:** the ToolRoot path-**string** value is out of scope (Track E / "do not move ToolRoot"); untouched here.

### 5. `## Review record`
- **disposition:** **compress** (fold into `## Project layout`; standalone section removed)
- **owner-surface:** snippet (folded into Project layout) — the result.md/verdict/section *shape* remains owned by the non-deployed `docs/contracts/review/REVIEW_RESULT_CONTRACT.md` (pointer kept) · **loading-class:** n/a
- **keep-by-proof:** the no-sidecar two-file record boundary is a genuine invariant (kept); but the section duplicated the canonical-review-record path already in `## Project layout` (KP — single-home pressure). The deployed `review-run.ps1` owns record *creation*; the snippet keeps only the minimal always-on no-sidecar statement, folded to remove duplication.
- **invariant-impact:** the no-sidecar / two-file review-record invariant (check #4) is **preserved** inside the Project-layout canonical-review-record bullet; the contract pointer is preserved. No verdict/review invariant dropped.
- **rationale + pointer:** re-opens Track D's "rename, don't fold" (evidence, not binding — design §3); folding removes the path duplication between the two sections (`DOCS_OPERATING_MODEL.md` §1 single-home). New home: `## Project layout` runtime-artifact-paths bullet for `…/pass-NN/`.

### 6. `## Result verdict vocabulary`
- **disposition:** keep (spec §4.1 "keep core; compress residual" → **determined: keep**) · **owner-surface:** snippet · **loading-class:** n/a
- **keep-by-proof:** KP1 ✓; KP2 — the *detailed* next-action mapping is already pointer-referenced out to the skill + contract (already compressed); the residual (three values + "verdict approves nothing" + `yes with risk` ≠ `yes`) is reviewer-critical and reachable from the global file in reviewer mode where the skill may not be loaded → no better deployed owner; KP3 ✓; KP4 ✓; KP5 ✓; KP6 ✓.
- **invariant-impact:** verdict invariant (check #4) preserved. **rationale:** already compressed (detail pointer-referenced); the core is a reviewer-critical always-on boundary (Track D declined trimming it — consistent).

### 7. `## Operator stance`
- **disposition:** keep · **owner-surface:** snippet · **loading-class:** n/a
- **keep-by-proof:** KP1 ✓; KP2 — the full stance is pointer-referenced to the `ai-harness-review` skill + contract, but the compact residue is **cross-task** operator discipline (not review-only), so the review skill is not a complete owner and no other deployed surface covers all operator tasks → KP2 ✓ for the compact keep; KP3 ✓; KP4 ✓; KP5 ✓; KP6 ✓.
- **invariant-impact:** the stop/report-at-boundary + retraction operator invariant preserved. **rationale:** kept compact (already pointer-referenced).

### 8. `## Brief` (BF Level 3 non-claim line)
- **disposition:** **defer → skill-plan Batch 3 / Track F** · **owner-surface:** n/a (GSF-B1 does not touch) · **loading-class:** n/a
- **keep-by-proof:** non-current-capability note (a `delete` target under the current-capability-only rule) — but the deletion is **owned by skill-plan Batch 3**, not GSF-B1 (design §3; plan §1; spec §8).
- **invariant-impact:** none (unchanged). **rationale:** authoritative deferred record = 당시 brief DEFERRED 기록(현 `docs/brief/brief_backlog.md`; non-deployed). GSF-B1 leaves it in place; Batch 3 removes it.

### 10. `## Forbidden in this toolset` (7 bullets)
- **6 safety bullets** (no per-user log partitioning · no `BF_STATE.json`/sidecar · no daemon/watcher/scheduler/hook · no implicit/whole-file global-instruction mutation · no creation of `.claude\AGENTS.md` · no auto `.gitignore` mutation): **disposition: keep** · owner-surface: snippet · loading-class: each is an **always-on root instruction candidate** (rule-like; tagged for GSF-B3 only — no rules surface built here).
  - **keep-by-proof:** KP1–KP6 ✓ — adopter-universal safety hard boundaries with no deployed instruction owner (`docs/**` not deployed; some are enforced-by-absence). **invariant-impact:** hard boundaries (check #1) preserved. The `.claude\AGENTS.md` ↔ Adoption-destination overlap is **not** deduped (Track D declined; dedup would weaken a hard boundary).
- **no-auto-mirror Forbidden bullet:** **disposition: defer → skill-plan Batch 3 / Track F** (boundary note referencing a Batch-3-removed concept; spec §8; audit §3.10). owner-surface: n/a. **rationale:** its substance may survive only as a generic auto-mirror guardrail — Batch 3 decides; GSF-B1 leaves it.

### 11. `## Other rules` (2 bullets)
- **Commit/push requires explicit approval:** keep · snippet · loading-class **always-on root instruction candidate** (tagged for GSF-B3). keep-by-proof KP1–KP6 ✓ (adopter-universal hard boundary). invariant-impact: commit/push hard boundary (check #1) preserved.
- **Temporary-file cleanup before closeout:** keep · snippet · loading-class n/a. keep-by-proof ✓ (generic operator hygiene, adopter-universal). invariant-impact: none.

---

## Snippet-invariant check (spec §11) — result

1. **No hard boundary dropped** — ✓ all Forbidden safety bullets + commit/push approval + no-whole-file-overwrite retained (only Review-record *folded*, not dropped).
2. **No adoption / path-topology invariant dropped** — ✓ Adoption destination/rules, ToolRoot/ProjectRoot/`log/` topology, canonical review-record path (now in Project layout), forbidden `.claude\AGENTS.md` all retained.
3. **No role-binding invariant dropped** — ✓ Role neutrality + reviewer-mode exclusion kept whole.
4. **No verdict/review invariant dropped without an owner** — ✓ verdict vocabulary kept; the no-sidecar review-record boundary preserved (folded into Project layout) with the contract pointer.
5. **CLAUDE/AGENTS snippet symmetry preserved** — ✓ the fold is byte-identical in both snippets; the only differences remain the intended tool-specific loci (intro tool-name, Adoption destination, Adoption rules "either"/"any of those").
6. **Every removed item has an owner-surface or rationale** — ✓ the only removal is the `## Review record` *section header* (its content folded into Project layout, no-sidecar invariant + contract pointer preserved). No content deleted. Brief/mirror = defer (untouched).

**Stop/report boundaries (spec §13):** none encountered. The fold required no runtime/install/skill-procedure/ToolRoot/hook/memory/global-file change, no rules surface, and no docs deletion.

**Deferred to skill-plan Batch 3 / Track F (not executed, not re-owned, not renumbered):** `## Brief` BF-lv3 non-claim, another non-current section, and the no-auto-mirror `## Forbidden` bullet.
