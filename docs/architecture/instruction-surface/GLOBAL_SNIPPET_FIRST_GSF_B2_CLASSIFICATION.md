# Global Snippet First — GSF-B2 Classification Record (docs legacy policy-warehouse audit)

**Status: binding GSF-B2 docs-audit classification record. Classification only — no docs deletion, compression, retirement, or body rewrite.** This is the reviewable artifact the migration plan (`GLOBAL_SNIPPET_FIRST_MIGRATION_PLAN.md` §2 GSF-B2) requires: a per-finding classification of `docs/**` content that behaves like **active instruction / runtime policy / skill fallback / global-snippet-rationale warehouse / stale blocking source-of-truth**, narrowing each toward its proper role (`reference / contract / decision-record / rationale`) and mapping each live fact to its owner surface. It is the docs analogue of the Track B snippet audit (`GLOBAL_SNIPPET_RELOCATION_AUDIT.md`). It edits **no docs body** — the only changes accompanying it are the minimal routing/status registrations recorded in *Coherence registrations (two-level closeout)* below.

**Controlling authorities (obeyed, not redefined).** `GLOBAL_SNIPPET_FIRST_MIGRATION_DESIGN.md` (design — keep-by-proof default, deployment boundary, owner-surface order, conflict order, `rules/` deferral); `GLOBAL_SNIPPET_FIRST_MIGRATION_PLAN.md` §2 (GSF-B2 = classify, don't delete); `docs/policies/DOCS_OPERATING_MODEL.md` (single-home-plus-pointers §1; durable-pointer rule §4; STATUS shape/altitude §4; two-level closeout §7); `docs/README.md` (placement / §4 always-on bar); `docs/current/SOURCE_OF_TRUTH.md` (per-question routing).

> **Corrective note (current).** This classification record and its *Relationship to GSF-B4 (closed out)* framing predate the global-snippet hard-minimization corrective (`GLOBAL_SNIPPET_HARD_MINIMIZATION_CORRECTIVE.md`). The snippet is no longer at 8 H2 — it is a 2-H2 always-loaded bootstrap backed by a two-tier rules architecture (global-distribution `snippets/rules/*.md` + repo-only `<repo-root>/rules/*.md`), and the whole distribution is `docs/`-free. This **supersedes** GSF-B3's "create no rules surface" decision (the user directed the rules tiers; GSF-B3's loading model is retained). This findings ledger remains valid **as evidence**; its `docs/**` findings (B2-F01…F10) are not invalidated, but the GSF-B4 "complete with intentional residuals" objective-completion framing it records is superseded by that corrective.

**Basis.** `docs/**` as of `HEAD == 2400bd0` (post Batch 3 / Track F; snippet at 8 H2). Inspection method: priority surfaces read line-by-line (`docs/policies/**`, the main `docs/contracts/**`, `docs/architecture/instruction-surface/**`, `docs/systems/skills/**`, `docs/systems/brief/**`, `docs/current/SOURCE_OF_TRUTH.md`, `docs/user_guide/OPERATOR_GUIDE_KR.md`); cross-cutting public-safe / durable-pointer patterns swept repo-wide by grep (machine-specific paths, `log/**` durable pointers, username leak, `polishing/` / `repo_snapshot/`); the remaining surfaces (decision records, roadmap/backlog routing, per-system STATUS, review-system plan bodies) category-classified with grep-confirmed line items. The audit is **keep-by-default** for `docs/**` (design §2: existing docs are evidence, not automatically blocking source-of-truth; their *role* narrows, their *body* survives) — only the findings below deviate, and none is edited in this batch.

---

## Classification vocabulary

Per the GSF-B2 charter, each finding is one of: `remain (reference/contract/decision-record/rationale)` · `migrate → skill` · `migrate → script` · `migrate → tests/verifier` · `migrate → repo-local CLAUDE/AGENTS` · `future AI-native rule candidate` · `compress candidate` · `delete candidate` · `retire candidate` · `defer / needs separate batch` · `stop/report boundary`. Per finding: source path/section · current role · why legacy/active/stale/duplicated · proposed owner · owner evidence · owner-migration status · GSF-B4 eligibility · risk/boundary.

**Standing boundary (design §6 / plan §2).** `docs/**` is never the fallback owner for active instruction. A contract keeps its **artifact/protocol authority** for the thing it governs (design §4 note) — the audit re-judges only *role and authority weight*, never the artifact definition. No `rules/` catalog is built here (design §9; a `future AI-native rule candidate` tag is classification only). No deletion/compression/retirement is executed here — that is **GSF-B4, owner-migration-gated** (plan §2 GSF-B4).

---

## Headline outcome

Most of `docs/**` is **correctly-roled and remains** (§6): the artifact/protocol contracts (`review` / `brief` / `chatlog` / `evidence` / `global-invocation`) are owner surfaces — several are precisely where GSF-B1 / Batch 3 migrated facts *into* — and the design/plan/decision/status docs are decision-records / rationale that the GSF design §3 already classifies as retained evidence. The audit produces **10 findings (B2-F01…B2-F10)**, none requiring a snippet edit, all classification-only:

- **1 high-priority defect** (B2-F01): a dangling, machine-specific, invalid durable pointer used as corrective-pass *authority* — `docs/policies/REVIEW_EFFORT_GUIDE.md:180` → `H:\Work\CLAUDE.md`.
- **1 medium durable-pointer defect** (B2-F03): a `log/**` (gitignored) durable pointer in a tracked plan doc.
- **1 medium duplication** (B2-F04): the review-effort guide restating verdict→next-action / verdict-vocabulary that the review contract + skill own.
- **1 low public-safe-cleanliness cluster** (B2-F02): labeled machine-specific `H:\Work\...` example paths across 5 docs (incl. `INSTALL.md`).
- **5 low compress/stale-isolated/remain items** (B2-F05…B2-F09) + **1 cross-doc altitude note** (B2-F10).

No finding is an `active instruction that docs must stop owning and an executable surface must start owning` requiring a behavior change — the executable/contract owners already exist; the findings are duplication, staleness, and pointer-hygiene, fixable by compression/redirection in GSF-B4, not by migrating live behavior out of docs.

---

## Findings

### B2-F01 — `REVIEW_EFFORT_GUIDE.md:180` dangling `H:\Work\CLAUDE.md` durable pointer  **[priority: HIGH]**
- **source:** `docs/policies/REVIEW_EFFORT_GUIDE.md` §9 (Verdict handling), line 180.
- **current role:** stale external/user-machine durable pointer used as corrective-pass guidance — the line asserts the no-auto-corrective-pass procedure "is consistent with the 'Codex review 후 corrective pass 규칙' in `H:\Work\CLAUDE.md`".
- **why a defect (triple):** (1) **machine-specific absolute path** in a public-safe tracked doc (violates the repo-local *Public-safe boundary*, `REPO_LOCAL_INSTRUCTION_SURFACE_PLAN.md` §7); (2) **invalid durable pointer to a non-source-of-truth user/global file** (`DOCS_OPERATING_MODEL.md` §4 — durable pointers resolve only to git-tracked files or git history); (3) **dangling** — the target does not exist (file-existence checked). Before this record was written it was the **only occurrence of `H:\Work\CLAUDE.md` in pre-existing repo source** (grep at `HEAD == 2400bd0`); this GSF-B2 record now necessarily quotes the string when describing the finding, so the "only occurrence" property holds for *pre-existing docs outside this record*, not the current tree verbatim.
- **classification:** `delete candidate` (the pointer) + redirect to a tracked authority.
- **proposed owner:** a tracked review authority — `docs/contracts/review/REVIEW_RESULT_CONTRACT.md` §6a (Verdict → next-action mapping, the `no` subsection) + its operator mirror `snippets/claude-skills/ai-harness-review/SKILL.md` step 7 (verdict → next-action `no` handling). (Note: the skill's *retry discipline* — one-invocation / no-retry-on-failure — is runner-failure retry, a different concept from corrective-pass-after-a-`no`-verdict; the corrective-pass owner is §6a `no` + skill step 7.)
- **owner evidence:** the same corrective-pass discipline is already owned by the review contract §6a + the review skill; `REVIEW_EFFORT_GUIDE.md` §9 itself routes verdict handling there. The owner is git-tracked and deployed-reachable.
- **owner-migration status:** **owner-migration applied (GSF-B4-A).** The `H:\Work\CLAUDE.md` pointer at `REVIEW_EFFORT_GUIDE.md:180` was replaced with the tracked authority — `REVIEW_RESULT_CONTRACT.md` §6a (`no` → corrective-pass next-action: no auto-progress, scoped approval, corrected-state re-review) and its operator-facing mirror `snippets/claude-skills/ai-harness-review/SKILL.md` step 7 (verdict → next-action `no` handling).
- **proposed future action:** **done (GSF-B4-A)** — the narrow fix batch replaced the dangling reference; no further action for B2-F01.
- **GSF-B4 eligibility:** **resolved (GSF-B4-A)** — was eligible; the fix landed as the narrow GSF-B4-A batch ahead of the full GSF-B4 cleanup.
- **risk/boundary:** user-confirmed **classification-only** for GSF-B2 — **do not edit `REVIEW_EFFORT_GUIDE.md` in this batch.** Surfaced to the user this session; option 1 (record only) selected.

### B2-F02 — machine-specific `H:\Work\...` example-path cluster  **[priority: LOW]**
- **source / sections** (the historical finding locations — **all normalized in GSF-B4-C**, see owner-migration status below; basis: repo-wide grep `H:[\\/]{1,2}(Work|tmp)` — the `{1,2}` catches both `H:\Work` and the JSON-escaped `H:\\Work` forms — excluding this record's own quotations and `tests/**` test-data, see *out of scope* below):
  - `INSTALL.md:103, 168` — `H:\Work\ai-harness-toolset\ai-harness-toolset` (example `local-clone` source path, "예:").
  - `docs/user_guide/OPERATOR_GUIDE_KR.md:414` — `H:/tmp/ai-harness-trial/` (illustrative *to-be-created* temp-repo example, "예:").
  - `docs/user_guide/GLOBAL_ADOPTION_PROCEDURE.md:60` — `H:/Work/ai-harness-toolset/ai-harness-toolset` (example ToolRoot, "예:").
  - `docs/decisions/GLOBAL_ADOPTION_DECISION.md:298, 312, 320` — `H:/Work/...` in example commands.
  - `docs/systems/install-update/GLOBAL_INSTALL_UPDATE_MODEL.md:33, 83, 194, 195, 222, 244, 245, 411` — `H:\Work\...` as labeled "현재 system example" (lines 194/195 in JSON-escaped `H:\\Work\\...` form — the `sourcePath` and `toolRoot` fields of the example install-state JSON); line 245 also `...-mvp-test-acceptance` (sibling test-repo path).
- **current role:** illustrative example values for ToolRoot / ProjectRoot / source path.
- **why legacy/cleanliness:** machine-specific paths in public-safe tracked docs are a public-readiness wart (an open-source adopter sees the maintainer's drive layout). **Distinct from B2-F01:** these are labeled *examples*, not authority pointers — the repo-root example paths exist on the author's machine, **except** `OPERATOR_GUIDE_KR.md:414`'s `H:/tmp/ai-harness-trial/`, which is an illustrative *to-be-created* temp path (does **not** exist on disk, by design — the step tells the reader to create it). None is a dangling *durable authority pointer* the way B2-F01 is. And `GLOBAL_INSTALL_UPDATE_MODEL.md:32–33` already establishes the generalized convention (`<canonical-local-toolroot>` placeholder + `%USERPROFILE%` / `C:\Users\<USER>` form, "실제 Windows 사용자 폴더명은 본 문서에 쓰지 않는다") — so the concrete `H:\Work\...` examples are a *consistency* gap against the doc's own stated convention, not a §4 durable-pointer violation.
- **classification:** `compress candidate` (normalize concrete examples to the existing `<canonical-local-toolroot>` / `<ToolRoot>` placeholder convention).
- **proposed owner:** the docs themselves (self-normalization to the install-model's placeholder convention) — no migration to another surface.
- **owner-migration status:** **applied (GSF-B4-C).** All B2-F02 concrete maintainer-local example paths (`H:\Work\...` / `H:/tmp/...`, incl. the JSON-escaped `H:\\Work` forms) across the 5 docs were normalized to the public-safe placeholder convention (`<canonical-local-toolroot>` / `<local-clone>` / `<temp-project>` / `<sibling-test-projectroot>`), and the install-model path-notation convention now mirrors its own username rule (실제 경로는 본 문서에 쓰지 않는다). **LTS: example notation only — no install/update/uninstall/ToolRoot-resolution semantics changed.**
- **GSF-B4 eligibility:** **resolved (GSF-B4-C)** — the public-safe normalization landed as the narrow GSF-B4-C batch (a separate concern from GSF-B4's docs-removal scope, handled as its own mutation batch).
- **risk/boundary:** low; cosmetic/public-safe. Some maintainers intentionally keep a concrete "현재 system example" for clarity — confirm intent before normalizing.

### B2-F03 — `log/**` durable pointer in a tracked plan doc  **[priority: MEDIUM]**
- **source:** `docs/systems/review/REVIEW_ARTIFACT_PERSPECTIVE_LAYOUT_PLAN.md:184` — table row that **pointed at** `log/review_polishing/deferred/revpolish-plan-local-2026-06-02/pass-01.md` as an "S6 origin 신호(read-only)" (historical defect description; the pointer has since been removed — GSF-B4-B; see owner-migration status below).
- **current role:** provenance pointer (where a planning signal originated) inside a design plan's impact table.
- **why a defect:** durable pointer to a **gitignored `log/**` runtime path** in a tracked doc — `DOCS_OPERATING_MODEL.md` §4 forbids durable pointers to `log/**` / scratch / runtime paths (resolve only to git-tracked files or git history). The same rule is restated in `INSTRUCTION_SURFACE_PLAN.md:160`.
- **classification:** `delete candidate` / `compress candidate` (remove the live `log/**` path or describe the provenance without a durable runtime pointer).
- **proposed owner:** the plan doc itself (self-fix) — state the origin in prose / git-history terms rather than a live `log/**` path.
- **owner-migration status:** **applied (GSF-B4-B).** Both `log/**` durable pointers to the same gitignored review-polishing artifact in this plan were removed — `REVIEW_ARTIFACT_PERSPECTIVE_LAYOUT_PLAN.md:184` (impact-table row) and `:24` (the friction-origin evidence bullet). The GSF-B2 audit cited only `:184`; `:24` is the same defect (the same `log/**` durable pointer in the same doc) and was found + fixed in GSF-B4-B. Both now describe the S6 origin as a gitignored / ephemeral review-polishing runtime artifact (not a durable source-of-truth), and the durable S6 record is redirected to the tracked owner `docs/systems/review/STATUS.md` RV-B-08 (commit `460ee3e`) + git history.
- **GSF-B4 eligibility:** **resolved (GSF-B4-B)** — was eligible; the fix landed as the narrow GSF-B4-B batch (a review-system plan doc, adjacent to the core instruction-surface focus).
- **risk/boundary:** medium; a tracked→`log/**` durable pointer is exactly the §4 staleness/portability failure mode.

### B2-F04 — `REVIEW_EFFORT_GUIDE.md` §9/§12 verdict-handling restatement  **[priority: MEDIUM]**
- **source:** `docs/policies/REVIEW_EFFORT_GUIDE.md` §9 (Verdict handling table) + §12 (Final rules re-statement); supporting restatement in §3 (Review cost principles) + §10 (checklist).
- **current role:** a task-scoped **operating recommendation** (the doc self-classifies as "사용자 운용 권고이며 tooling 의 자동 게이트가 아니다") — a legitimate reference role.
- **why duplicated:** §9/§12 restate the verdict→next-action mapping + verdict vocabulary + commit/push-not-approval that are single-homed in `REVIEW_RESULT_CONTRACT.md` §6a/§6/§3 (non-deployed contract) and mirrored operationally by the `ai-harness-review` skill. This is the single-home-plus-pointers tension (`DOCS_OPERATING_MODEL.md` §1): the guide both *points at* the contract and *copies* the table, so a verdict-semantics change needs an N-place sweep.
- **classification:** `compress candidate` (reduce §9/§12 to the cost/effort-specific guidance + a pointer to `REVIEW_RESULT_CONTRACT.md` §6a, dropping the duplicated verdict mapping) — **the bulk of the guide remains** as a legitimate cost/effort reference.
- **proposed owner:** verdict semantics → `REVIEW_RESULT_CONTRACT.md` §6/§6a + the `ai-harness-review` skill (steps 6–7); the guide keeps only effort/cost operating guidance.
- **owner-migration status:** **owner already exists** (contract §6a + skill); the guide's copies are residual duplication, not unowned content.
- **GSF-B4 eligibility:** **yes** (compression with the contract pointer preserved).
- **risk/boundary:** low; compressing verdict restatement must keep the cost/effort guidance and the contract pointer intact (no verdict-semantics change). Reviewer-critical verdict vocabulary is not lost (it lives in the contract + the snippet's `## Result verdict vocabulary`).

### B2-F05 — `OPERATOR_GUIDE_KR.md` review-procedure / verdict restatement  **[priority: LOW]**
- **source:** `docs/user_guide/OPERATOR_GUIDE_KR.md` §5/§6 (pipeline + sequence diagrams), §9 (raw-command quickstart), §11 (verdict-handling table).
- **current role:** human-facing operator tutorial (`docs/user_guide/` = release-facing guide / tutorial) — a legitimate reference role for a human audience.
- **why duplicated:** restates the review procedure (owned by `scripts/review-*.ps1` + the `ai-harness-review` skill + `REVIEW_RESULT_CONTRACT.md` §4a) and the verdict→next-action table (§11 — which itself cites `REVIEW_RESULT_CONTRACT.md §6a` as source-of-truth yet reproduces the full table). Points-and-copies, same single-home tension as B2-F04.
- **classification:** `compress candidate` (low) — but a human tutorial legitimately restates procedure at tutorial altitude for its audience, so this is a *softer* compress than B2-F04. §10 already shows the correct pattern ("전체 계약은 REVIEW_RESULT_CONTRACT.md … 본 절은 중복 정의하지 않고 routing").
- **proposed owner:** procedure → skill + scripts + contract §4a; verdict mapping → contract §6a. Guide keeps the human-facing narrative + pointers.
- **owner-migration status:** owner exists; restatement is audience-justified residue.
- **GSF-B4 eligibility:** **partial** — compressing the §11 table toward §10's pointer pattern is eligible; the §5/§6 tutorial diagrams are reasonable to keep for the human audience (compress only if drift appears).
- **risk/boundary:** low; user_guide is a deliberately human-readable surface — over-compressing a tutorial harms its purpose. Keep as remain-with-watch unless it drifts.

### B2-F06 — `REVIEWER_CONFIG_POLICY.md` diagnostic Codex-invocation reference  **[priority: LOW]**
- **source:** `docs/policies/REVIEWER_CONFIG_POLICY.md` "Diagnostic Codex invocation reference" (lines ~114–125; the inline `codex … exec …` command block).
- **current role:** a debugging reference reproducing the exact Codex CLI command shape that `scripts/review-run.ps1` builds internally.
- **why duplicated:** the operative command shape is owned by `scripts/review-run.ps1` (script = behavior); restating it in docs risks drift if the runner's flags change.
- **classification:** `remain` (low-value `compress candidate`) — the doc explicitly frames it as a *diagnostic* reference and points the normal path to the two-step flow + `REVIEW_RESULT_CONTRACT.md`; a human-readable command echo for debugging is a legitimate reference.
- **proposed owner:** `scripts/review-run.ps1` (canonical); doc keeps a clearly-labeled diagnostic echo.
- **owner-migration status:** owner exists (script); doc copy is intentional debug reference.
- **GSF-B4 eligibility:** optional (compress only if it drifts from the runner).
- **risk/boundary:** low.

### B2-F07 — `CLI_ENVIRONMENT_ASSUMPTIONS.md` Tier 3 operator retry discipline  **[priority: LOW]**
- **source:** `docs/policies/CLI_ENVIRONMENT_ASSUMPTIONS.md` Tier 3 (line ~31): "any non-zero exit → no auto-rerun; report wrapper failure; separate scoped approval; natural-language path follows `SKILL.md` retry discipline".
- **current role:** CLI-dependency Tier reference that also states an operator runtime behavior.
- **why borderline:** the retry/wrapper-failure behavior is runtime operator discipline co-owned by the `ai-harness-review` skill (retry discipline) + the scripts (fail-fast exit). The doc already *points* at the skill for the natural-language path, so it is mostly correctly-pointered reference.
- **classification:** `remain` (reference) — it points to the skill rather than fully restating procedure.
- **proposed owner:** skill (retry discipline) + scripts (fail-fast); doc remains the Tier-dependency reference.
- **owner-migration status:** owner exists; doc correctly references it.
- **GSF-B4 eligibility:** no (no removal needed).
- **risk/boundary:** none material.

### B2-F08 — `GLOBAL_INSTALL_UPDATE_MODEL.md` stale 1차/2차 + source-cache/persistent-ToolRoot remnants (isolated)  **[priority: LOW]**
- **source:** `docs/systems/install-update/GLOBAL_INSTALL_UPDATE_MODEL.md` — the §9 / §9.3 1차·2차 brief-path framing remnants and source-cache / persistent-ToolRoot wording, isolated by the file's top reconciliation note.
- **current role:** install/update operating model (design/model) carrying superseded historical framing behind an isolation note.
- **why stale:** `SOURCE_OF_TRUTH.md` Q1 + Q4 already flag these as **"Do not use"** (superseded, isolated by the top reconciliation note); current truth lives in `docs/systems/install-update/STATUS.md` + `BRIEF_CONTRACT.md` (3rd reconciliation).
- **classification:** `remain` (decision/model record; stale-but-isolated) + `compress candidate` for GSF-B4.
- **proposed owner:** current state → `install-update/STATUS.md`; brief framing → `BRIEF_CONTRACT.md`. The model doc remains the design/model authority for live install behavior.
- **owner-migration status:** **partially applied (GSF-B4-D, bounded compression under separate scoped approval).** The redundant full-lineage *re-statements* of the 1차/2차/3차 brief reconciliation in the §6 Layer 4 superseded note + the §9 BRIEF wording note were compressed to pointers to the single-home lineage record (§1 3rd-reconciliation note + §9.3 reconciliation list), preserving all current (3차) facts, the isolation marking, cross-references, and **all install/update/ToolRoot semantics**. **Kept by design (single-home):** the §1 authoritative supersede notes + the §9.3 reconciliation list. **Deliberately left isolated (out of this bounded batch — compressing them would risk LTS install/ToolRoot semantics):** the scattered source-cache / persistent-ToolRoot framing in the §4.2/§10.2 install-flow prose, and the already-minimal per-line "이전 라운드 … superseded" asides.
- **GSF-B4 eligibility:** **partially resolved (GSF-B4-D)** — the safe brief-lineage duplication was compressed under separate scoped approval; the residual stale framing remains safely isolated (LTS, semantics-adjacent), preserved in git history + the §1/§9.3 single-home.
- **risk/boundary:** **LTS subsystem** — do not edit install-update docs without separate scoped approval (plan §4 stop/report). Classification only here.

### B2-F09 — `SHARED_GLOBAL_INVOCATION_CONTRACT.md` superseded review-cycle wording (isolated)  **[priority: LOW]**
- **source:** `docs/contracts/global-invocation/SHARED_GLOBAL_INVOCATION_CONTRACT.md` — §2 inputs, §4 D2/D6, §5.4, §6 wording written against the removed-legacy `scripts/review-cycle.ps1` + sidecars (`meta.json`, `result.json`, `<run-id>` flat layout, `-TargetFiles*`), isolated by the top "Review-cycle wording supersede note".
- **current role:** shared/global invocation **design** record (D1–D9). The D-decisions remain valid; the review-cycle/sidecar *wording* is superseded (current path = two-step `review-prepare`/`review-run`, canonical three-level record).
- **why stale:** the doc's own supersede note + `SOURCE_OF_TRUTH.md` Q2 "Do not use" mark `review-cycle.ps1` / `meta.json` / `result.json` / `<run-id>` flat layout as removed-legacy.
- **classification:** `remain` (design/decision record; stale-but-isolated) + `compress candidate` for GSF-B4.
- **proposed owner:** current review record/flow → `REVIEW_RESULT_CONTRACT.md` + `review-*.ps1`; the contract remains the D1–D9 invocation-design authority (ToolRoot resolution topology the snippet `## Project layout` points to).
- **owner-migration status:** **minimally applied (GSF-B4-E).** The one safely-compressible spot — the §2 inputs list that presented `scripts/review-cycle.ps1` as a current lifecycle script — was reframed to mark it **removed-legacy** (design-time input; pointing to the top supersede note). The rest of the review-cycle / sidecar wording is **D1–D9-decision-integral** (D1 channel-3 entrypoint-completeness check, D6 `meta.json` ToolRoot binding, D7 `review-cycle.ps1` untracked detection, the §5/§6 formal specs) and was **deliberately left unchanged** — compressing it would alter the D-decision / contract authority (forbidden); it stays isolated by the top "Review-cycle wording supersede note".
- **GSF-B4 eligibility:** **minimally resolved (GSF-B4-E)** — the §2 inputs reframe applied under the contract boundary; the D1–D9-integral review-cycle wording remains (must not alter the D-decisions), isolated by the top note + preserved in git history.
- **risk/boundary:** medium-care — the doc is the ToolRoot-topology authority referenced by the snippet; trim only the superseded review-cycle prose, never the D-decisions.

### B2-F10 — design/plan docs accumulating "since landed" current-state annotations  **[priority: LOW]**
- **source:** the instruction-surface family (`INSTRUCTION_SURFACE_PLAN.md`, `FUNCTION_LEVEL_SKILL_ARCHITECTURE_PLAN.md`) + the GSF family (`..._MIGRATION_DESIGN/PLAN/SPEC_GSF_B1/GSF_B1_CLASSIFICATION.md`) — inline "(Landed — SK-0x)", "(since removed by Batch 3)", past-tense reconciliation annotations.
- **current role:** design/plan/decision records (GSF design §3: retained evidence) interleaving current-state status pointers.
- **why borderline:** `DOCS_OPERATING_MODEL.md` §4 keeps current-state in `STATUS.md`, not in design bodies; the accreting "since landed" annotations are current-state tracking creeping into design docs (the staleness vector the GSF design itself warns about — and the exact class that forced 6 corrective review loops in Batch 3).
- **classification:** `remain` (decision-record / rationale) + weak `compress candidate` — the annotations are legitimate status pointers (they route to `STATUS.md` SK-rows), so this is a low-severity altitude note, not a removal.
- **proposed owner:** current state → `docs/systems/skills/STATUS.md` (SK ledger); design docs keep the *decision*, pointing to STATUS for status.
- **owner-migration status:** owner exists (STATUS SK-00…SK-05); design docs over-annotate but route correctly.
- **GSF-B4 eligibility:** optional (low-value compression; high re-staling risk if edited — these docs are exactly where Batch 3's stale-present-tense findings clustered).
- **risk/boundary:** **editing these is high re-staling risk** (Batch 3 open-risk lesson: line-by-line + present-tense-verb sweep required). Leave as remain unless a dedicated altitude batch is approved.

---

## Remain-by-category (the bulk of `docs/**`)

These surfaces are **correctly roled and remain** as `reference / contract / decision-record / rationale`. Listed by category with the reason each is not a policy-warehouse / active-instruction finding:

- **Artifact/protocol contracts (owner surfaces) — remain.** `docs/contracts/review/REVIEW_RESULT_CONTRACT.md`, `brief/BRIEF_CONTRACT.md`, `chatlog/CHATLOG_CONTRACT.md`, `evidence/EVIDENCE_CONTRACT.md`, `global-invocation/SHARED_GLOBAL_INVOCATION_CONTRACT.md`. Each keeps artifact authority (design §4 note). `BRIEF_CONTRACT.md` (BF Level table), `brief/DEFERRED.md` (BR-D-01/03; BR-D-02 retired), and `CHATLOG_CONTRACT.md` are exactly the **owner surfaces GSF-B1 / Batch 3 migrated facts into** — owner-migration **complete**; reconfirm, do not re-migrate. Operator-stance / AI-responsibility prose in `REVIEW_RESULT_CONTRACT.md` §5/§5a/§6a is the contract single-home the snippet + skill point to (correct direction, not a finding).
- **Cross-cutting architecture decision/plan docs — remain (retained evidence; GSF design §3).** `INSTRUCTION_SURFACE_PLAN.md` (Track A), `GLOBAL_SNIPPET_RELOCATION_AUDIT.md` (Track B — the snapshot-pinned snippet-rationale warehouse; intended role, snapshot-pinned to `ea61048`), `REPO_LOCAL_INSTRUCTION_SURFACE_PLAN.md` (Track C), the GSF `DESIGN/PLAN/SPEC_GSF_B1/GSF_B1_CLASSIFICATION` family. These are the legitimate home of global-snippet rationale; the design authority already declared them evidence-not-blocking. (Altitude note: B2-F10.)
- **Skill-subsystem plan/status — remain.** `FUNCTION_LEVEL_SKILL_ARCHITECTURE_PLAN.md` (design plan), `docs/systems/skills/STATUS.md` (current-state authority, SK-00…SK-05). STATUS is the correct single-home for "since landed" status.
- **Task-scoped process/policy authorities — remain.** `DOCS_OPERATING_MODEL.md` (docs change/closeout process), `POWERSHELL_POLICY.md` (PowerShell authority — its deterministic encoding/EOL rules are **co-owned by the `scripts/verify-ps1.ps1` verifier**, so the *guard* aspect is already test/verifier-owned; the doc remains the rationale authority the repo-local root files point to), `REVIEWER_CONFIG_POLICY.md` (config reference + enforcement-status record; dead-config notes `fallbackModel`/`outputFormat`/`resultFile` are config-cleanup candidates, not docs content), `docs/policies/README.md` / `docs/contracts/README.md` / `docs/architecture/README.md` (folder access-pattern indexes that enforce the "what does not belong here" boundaries — a structural defense against policy-warehousing, keep).
- **Decision records / project identity / routing — remain.** `docs/decisions/**` (POST_MVP_PLAN, DECISIONS, GLOBAL_ADOPTION_DECISION — settled decision records; GLOBAL_ADOPTION_DECISION carries the B2-F02 example paths), `docs/project/**` (scope/philosophy), `docs/roadmap/**` + `docs/backlog/**` (routing-only per `DOCS_OPERATING_MODEL.md` §3), per-system `STATUS.md` / `BACKLOG.md` / `DEFERRED.md`, `docs/current/SOURCE_OF_TRUTH.md` (per-question routing; its "Do not use" rows are the mechanism that already isolates B2-F08/F09 stale framing).
- **Review-system plan/spec bodies — remain (Batch-4 / RV-B decision records).** `docs/systems/review/REVIEW_POLISHING_*`, `REVIEW_*_PLAN.md`, `STATUS.md`. (One carried the B2-F03 `log/**` pointer — **resolved by GSF-B4-B**.)

---

## Checked, explicitly NOT a finding

- **`yunsuck5` in GitHub URLs** (`INSTALL.md:102/167`, `config/reviewer.schema.json:3`, `GLOBAL_INSTALL_UPDATE_MODEL.md:193/217/466`) — this is the project's **own public GitHub repo URL** (`github.com/yunsuck5/ai-harness-toolset`), the canonical remote source-of-truth. A repo's own published URL is inherently public; **not** a public-safe leak. (Distinct from the *local* `H:\Work\...` paths in B2-F02.)
- **`polishing/` / `repo_snapshot/` definitional mentions** in `REVIEW_RESULT_CONTRACT.md` (§ defining them as repo-outside, not-source-of-truth, not-mutation-target) and `INSTRUCTION_SURFACE_PLAN.md:160` (citing the §4 rule) — these correctly *define/cite the boundary*; not durable pointers into those paths.
- **README/INSTALL snippet-adoption references** — legitimate pointers to the snippet payload + adoption procedure (skill plan §9 adoption story); not a snippet-rationale warehouse.

## Out of GSF-B2 scope (recorded, routed elsewhere)

- **Deployed-surface (`snippets/` / `config/` / `scripts/`) public-readiness pointers** — the off-repo `polishing/` example in the deployed `SKILL.md` and deployed→non-deployed provenance pointers in `config/` / `scripts/`, already recorded in `FUNCTION_LEVEL_SKILL_ARCHITECTURE_PLAN.md` §3/§9 as public-readiness friction. **Out of GSF-B2's `docs/**` scope** — route to a deployed-surface cleanup batch, not GSF-B2 / GSF-B4 (which is docs-only).
- **Machine-path strings in `tests/**`** — `tests/install-update.Tests.ps1:313` (path-normalization test data `'H:\Work\','H:/Work/','/h/Work/'`) and `tests/review-adapter.Tests.ps1:253` (a path-conversion comment). These are test fixtures/comments, not docs, and the `H:\Work` forms are deliberate test inputs — **out of GSF-B2's `docs/**` scope**; route to a test-hygiene pass if ever wanted, not GSF-B2 / GSF-B4.

---

## Findings summary

| ID | Source | Classification | Priority | Owner-migration | GSF-B4 |
|---|---|---|---|---|---|
| B2-F01 | `REVIEW_EFFORT_GUIDE.md:180` | delete candidate + redirect | **HIGH** | **applied (GSF-B4-A)** | **done (GSF-B4-A)** |
| B2-F02 | `H:\Work\...` example cluster (5 docs) | compress candidate (normalize) | low | **applied (GSF-B4-C)** | **done (GSF-B4-C)** |
| B2-F03 | `REVIEW_ARTIFACT_PERSPECTIVE_LAYOUT_PLAN.md:184` | delete/compress candidate | medium | **applied (GSF-B4-B)** | **done (GSF-B4-B)** |
| B2-F04 | `REVIEW_EFFORT_GUIDE.md` §9/§12 | compress candidate | medium | owner exists (contract §6a + skill) | yes |
| B2-F05 | `OPERATOR_GUIDE_KR.md` §5/§6/§11 | compress candidate (soft) | low | owner exists | partial |
| B2-F06 | `REVIEWER_CONFIG_POLICY.md` diagnostic ref | remain / opt. compress | low | owner exists (script) | optional |
| B2-F07 | `CLI_ENVIRONMENT_ASSUMPTIONS.md` Tier 3 | remain (reference) | low | owner exists (skill) | no |
| B2-F08 | `GLOBAL_INSTALL_UPDATE_MODEL.md` stale framing | remain + compress (LTS) | low | **partially applied (GSF-B4-D)** | **partial (GSF-B4-D); residual isolated remains** |
| B2-F09 | `SHARED_GLOBAL_INVOCATION_CONTRACT.md` review-cycle wording | remain + compress | low | **minimally applied (GSF-B4-E)** | **minimal (GSF-B4-E); D1–D9-integral remainder remains** |
| B2-F10 | design/plan "since landed" annotations | remain + weak compress | low | owner exists (STATUS) | optional (high re-stale risk) |

**By disposition:** `delete candidate` 2 (B2-F01, B2-F03) · `compress candidate` 5 (B2-F02, B2-F04, B2-F05, F08/F09 as compress-within-remain) · `remain` (dominant — all of §6 + B2-F06/F07 + the remain half of F08/F09/F10) · `migrate` 0 · `retire candidate` 0 · `future AI-native rule candidate` 0 · `stop/report boundary` raised for LTS (B2-F08) and contract-authority (B2-F09) edits. **No `docs/**` content was found that an executable surface must newly own** — every duplication/staleness finding already has a tracked/deployed owner; the fixes are compression/redirection, not behavior migration.

## Major migration / delete / compress / retire candidates (for GSF-B4)

- **delete/redirect:** B2-F01 (`H:\Work\CLAUDE.md` dangling pointer → contract §6a / skill) — **highest priority; RESOLVED by GSF-B4-A** (replaced with `REVIEW_RESULT_CONTRACT.md` §6a + `ai-harness-review` skill step 7); B2-F03 (`log/**` durable pointer) **RESOLVED by GSF-B4-B** (removed the durable path; S6 origin reframed as a gitignored runtime artifact, durable record → `STATUS.md` RV-B-08 + git history).
- **compress:** B2-F04 (effort-guide verdict restatement → contract pointer); B2-F02 (machine-path examples → placeholder convention) **— RESOLVED by GSF-B4-C**; B2-F08 (install-update brief-lineage duplication **— partially compressed by GSF-B4-D**: §6/§9 re-statements → §1/§9.3 single-home; residual source-cache + per-line asides remain isolated, LTS); B2-F09 (contract review-cycle wording **— minimally compressed by GSF-B4-E**: §2 inputs reframed to removed-legacy; D1–D9-decision-integral remainder remains isolated, contract-authority boundary).
- **retire:** none (no doc section is wholly obsolete with no live content).
- **migrate to executable surface:** none required (owners already exist).

## Stop/report boundaries encountered

- **None crossed.** Classification only; no docs body edited, no snippet edit, no `rules/` surface, no runtime/install/skill-procedure change, no ToolRoot move, no memory action, no global/user-file mutation, no commit/push.
- **Flagged for downstream batches:** B2-F08 touches **LTS** install-update docs (separate approval required even in GSF-B4); B2-F09 touches a **contract** (compress role/wording only, never the D1–D9 artifact authority); B2-F01/F02 involve **public-safe** path hygiene the user has scoped to classification-only for this batch.

## Coherence registrations (two-level closeout)

Per the two-level closeout gate (`DOCS_OPERATING_MODEL.md` §7), inspect-all / report-each. GSF-B2 is classification-only (one new record + pointer registrations; no docs body edited, no snippet/skill/code change):

**Level 1 (top-down orientation):**
- `docs/current/SOURCE_OF_TRUTH.md` — **updated** (Q11): registers this classification record as landed (classification-only) and reconciles the Q11 Implementation line so GSF-B2 is no longer listed among the *remaining* implementing tracks (GSF-B3/B4 remain).
- `docs/roadmap/CURRENT_MILESTONES.md` — *checked: no change required* (no numbered-milestone status changed; `GSF-Bn` is the migration's own namespace, not a numbered milestone).
- `docs/decisions/POST_MVP_PLAN.md` — *checked: no change required* (numbered-order authority unchanged).

**Level 2 (system-local):**
- `docs/architecture/README.md` — **updated** (instruction-surface row): lists this GSF-B2 record alongside the design / plan / spec / GSF-B1 records.
- `docs/architecture/instruction-surface/GLOBAL_SNIPPET_FIRST_MIGRATION_PLAN.md` — **updated** (§2 GSF-B2 "classification record landed" status bullet; the §"Stage flow" line reconciled so GSF-B2 is no longer a purely-future stage).
- `docs/systems/skills/STATUS.md` — *checked: no change required* (GSF-B2 changed no snippet / skill / deployed surface, so no SK ledger row and no current-state flip — the SK-00…SK-05 ledger remains accurate).
- existing `INSTRUCTION_SURFACE_PLAN.md` / `GLOBAL_SNIPPET_RELOCATION_AUDIT.md` / `REPO_LOCAL_INSTRUCTION_SURFACE_PLAN.md` / `FUNCTION_LEVEL_SKILL_ARCHITECTURE_PLAN.md` / the GSF design / spec / GSF-B1 classification — *checked: intentionally not edited* (preserved as prior evidence; this record routes to them).

## Relationship to GSF-B4 (closed out — landed with intentional residuals)

GSF-B4 (owner-migration-gated docs deletion/compression/retirement, plan §2) consumes this record: each `delete/compress` candidate above is eligible **only** with its named owner-migration evidence (B2-F01/F03 owners exist; B2-F04 owner = contract §6a; B2-F02 owner = placeholder convention) and after the four-class reference sweep (path/token/folder/semantic) the GSF-B4 charter requires. GSF-B4 executes nothing this record does not classify; this record approves no edit. (B2-F01's fix may also run as a standalone quick-fix batch ahead of GSF-B4, per user direction.)

**GSF-B4 closeout (landed with intentional residuals).** GSF-B4 has landed as five narrow owner-migration-gated fix slices — GSF-B4-A (B2-F01, `3fa20a9`), GSF-B4-B (B2-F03, `76e50a2`), GSF-B4-C (B2-F02, `8686c42`), GSF-B4-D (B2-F08 **partial**, `7c93f5a`), GSF-B4-E (B2-F09 **minimal**, `6557f47`) — each with both Codex perspectives + explicit approval. The per-finding *Owner-migration* / *GSF-B4* columns in the *Findings summary* above are the **final disposition of record** for this closeout. **Intentional residuals (not blockers; isolated by their docs' top supersede notes + git history):** B2-F08 source-cache / persistent-ToolRoot §4.2/§10.2 prose + per-line asides (compressing risks **LTS install/ToolRoot semantics**) and B2-F09 D1–D9-integral review-cycle wording (compressing would alter **contract authority**). **Remaining GSF-B4 candidates left unactioned — not split further:** B2-F04, B2-F05, B2-F06, B2-F07, B2-F10 — their per-finding dispositions and priorities stand exactly as the *Findings summary* above records them (B2-F04 `compress candidate`, **medium**, GSF-B4-eligible `yes` — the clearest remaining candidate, *not* a low/optional item; B2-F05 `compress candidate (soft)`, low, GSF-B4 `partial`; B2-F06 `remain` / optional compress, low; B2-F07 `remain`, low; B2-F10 `remain` / weak compress, low), and this closeout **reclassifies none of them and does not downgrade B2-F04**. Each has an existing owner; this closeout actions none and decides not to split them into further batches now — reopen one (B2-F04 first) only if a concrete future need makes it worth a scoped batch, not as routine cleanup. This closeout is **not** authority for arbitrary docs cleanup, does **not** change the migration default (existing docs are **evidence, not automatically blocking source-of-truth**), and does **not** alter the GSF-B3 decision (**no rules surface**). The authoritative closeout record is `GLOBAL_SNIPPET_FIRST_MIGRATION_PLAN.md` §2 (GSF-B4 status + Stage flow); with GSF-B1…B4 all landed, the Global Snippet First migration sequence is **complete with intentional residuals** (Track E ToolRoot + skill-plan Batch 4 are separate, unstarted tracks).
