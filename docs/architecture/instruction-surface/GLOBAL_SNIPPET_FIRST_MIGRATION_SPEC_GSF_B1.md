# Global Snippet First — GSF-B1 Spec (snippet minimization + direct owner-surface absorption)

**Status: spec stage for batch GSF-B1. NOT an implementation, NOT a snippet edit, and NOT an approval to run GSF-B1.** This is the **spec** layer of the design → plan → spec → implementation sequence. It fixes the **acceptance criteria** the future GSF-B1 implementation must meet; it edits no global snippet payload, removes no section, and changes no behavior. GSF-B1 implementation is a separate scoped goal + Codex review gate + explicit user approval; **this spec approves none of it.**

**Controlling authorities (obeyed, not redefined).**
- **Migration authority (design):** `GLOBAL_SNIPPET_FIRST_MIGRATION_DESIGN.md` — keep-by-proof default (design §7), deployment-boundary constraint (§6), owner-surface order (§8), source-of-truth conflict order (§4), `rules/` deferral (§9), stage model (§10). Where this spec and the design appear to differ, the **design governs** and this spec is the stale surface to fix.
- **Batch sequence (plan):** `GLOBAL_SNIPPET_FIRST_MIGRATION_PLAN.md` — GSF-B1 is the first implementation batch (plan §2); the no-renumber/no-re-own boundary (plan §1) and per-batch stop/report boundaries (plan §4) bind here.
- **Stage reconciliation.** The design §10 and plan §2/§8 refer to this spec as the "spec stage" / "still-unwritten spec." This document now fulfils that stage **as an unapproved draft acceptance contract** — the design/plan phrasings were authoring-moment statements; their *requirement that the spec be written and approved before GSF-B1 runs* is unchanged. Live routing status is reconciled in `docs/current/REPO_READING_GUIDE.md` Q11; the design/plan bodies are left intact (their stage tables are authoring-moment snapshots, not a live ledger).

**Placement / routing.** Co-located with the design + plan + Track A/B/C under `docs/architecture/instruction-surface/`. Routing: `REPO_READING_GUIDE.md` Q11. Layer registration: `docs/architecture/README.md`. Authorities also obeyed: `docs/README.md` (placement; §4 always-on bar), `docs/policies/DOCS_OPERATING_MODEL.md` (single-home-plus-pointers; durable-pointer rule; two-level closeout), `docs/contracts/review/REVIEW_RESULT_CONTRACT.md`. States decisions directly; no durable pointer to the out-of-repo direction note.

---

## 1. What this spec is / is not

- **Is:** the acceptance contract for GSF-B1 — the inventory it must cover, the keep-by-proof criteria, the per-item classification output contract, owner-surface assignment rules, the rule-candidate loading-class taxonomy, the invariant checks, the allowed edits, the stop/report boundaries, and the validation + review gates.
- **Is not:** the executed classification. GSF-B1 implementation **produces the binding per-item classification record** (an artifact, §4) and the actual snippet edit, and is reviewed against this spec. This spec inspects the current snippet and supplies **acceptance targets + the procedure**; where a target is marked *implementation-determined*, the spec fixes the criteria and the bar, not the outcome. A reviewed deviation from a non-binding target is permitted only with a recorded keep-by-proof justification that passes §3 (keep-by-proof) and the §11 invariant check.

---

## 2. Snippet inventory (current scope, inspected at HEAD 28239de)

Both `snippets/CLAUDE_SNIPPET.md` and `snippets/AGENTS_SNIPPET.md` carry the managed-block header + **11 H2 sections**:

| # | Block | Substance (summary) |
|---|---|---|
| 0 | Managed-block header (intro) | payload self-description; orients the adopter to the managed-block model |
| 1 | `## Adoption destination` | valid destinations: **project-root** `CLAUDE.md`/`AGENTS.md` + user-global (`%USERPROFILE%\.claude\CLAUDE.md` / Codex `%USERPROFILE%\.codex\AGENTS.md` or `%CODEX_HOME%\AGENTS.md`); the forbidden `%USERPROFILE%\.claude\AGENTS.md`; the other tool's path (Codex side also notes `AGENTS.override.md` precedence). Distinct from `<ToolRoot>` (item 4) |
| 2 | `## Adoption rules` | managed-block-only adoption; no whole-file overwrite; explicit-approval mutation; marker fail-fast |
| 3 | `## Role neutrality` | role-neutral payload; operator/reviewer/auditor/supervisor; reviewer-mode binding subset + reviewer-mode exclusion; operator-side protocols apply only as operator; nothing forces approve |
| 4 | `## Project layout` | ToolRoot/ProjectRoot definitions; ToolRoot channel-resolution order; `log/` layout; canonical review-record path; reviewer-config path |
| 5 | `## Review record` | canonical artifact location + the no-sidecar two-file record boundary; shape owned by the review contract |
| 6 | `## Result verdict vocabulary` | the three values; "verdict approves nothing"; per-value meaning; next-action mapping pointer |
| 7 | `## Operator stance` | stay in approved scope; stop/report at boundaries; explicit retraction; full stance pointer-referenced |
| 8 | `## Brief` | the BF Level 3 non-claim line only |
| 9 | `## Chatlog` | Chatlog ≠ Brief; Chatlog area path; current restore source = Brief; reconstruction-evidence-only |
| 10 | `## Forbidden in this toolset` | 7 bullets: no per-user log partitioning; no `BF_STATE.json`; no daemon/watcher/scheduler/hook; no implicit/whole-file global-instruction mutation; no creation of `.claude\AGENTS.md`; no auto Brief↔Chatlog mirror; no auto `.gitignore` mutation |
| 11 | `## Other rules` | commit/push needs explicit approval; temp-file cleanup before closeout |

**Symmetry baseline.** The two snippets are byte-identical except the **intended tool-specific loci**: the intro tool-name/destination line, `## Adoption destination` (tool-specific destinations), and the `## Adoption rules` "either"/"any of those" phrase. GSF-B1 must preserve this symmetry (§11).

**Granularity.** Keep-by-proof runs at **section and sentence/bullet** level — a section may split (some bullets keep, some absorb/defer), e.g. `## Forbidden` bullets and `## Other rules` bullets are evaluated individually.

---

## 3. Section/sentence keep-by-proof criteria

GSF-B1 applies the design §7 keep-by-proof to every inventory item. **Default disposition is `delete / move / absorb / compress`; keep is the exception**, retained only if **all six** hold (design §7):

```
KP1  not a feature behavior / rule procedure / routing-fallback an executable surface should own
KP2  no better owner surface among scripts / skill / tests / repo-local instruction / future rule candidate / docs-reference
KP3  needed by every adopter, always, before any skill triggers
KP4  self-contained — understood without reading docs/** (docs/** is not deployed)
KP5  leaving it always-on carries low future-drift risk
KP6  does not conflate a public default with a user/profile-specific preference
```

Two design constraints bind the proof:
- **Deployment boundary (design §6).** `docs/`, `tests/`, `log/` are not deployed; only `config/` + `scripts/` + `snippets/` + skills (separately adopted to `~/.claude/skills/`) reach an adopter. So an invariant whose only deployed home is the snippet may pass KP2 *only* if no deployed executable surface (script / skill / test) can own it. KP2 must explicitly test "could a deployed executable surface own this?" — the audit's "operative residue → keep" ruling is re-judged here, not inherited.
- **Reviewer-mode reachability.** Items binding in reviewer/auditor mode (role neutrality, verdict vocabulary, review-record boundary) are loaded from the **global file** when a reviewer runs outside `review-run.ps1`; a keep argument for these must state whether a deployed surface (the skill) is actually reachable in that mode, or whether the snippet copy is the only reachable deployed home.

---

## 4. Per-item classification output contract

For **every** inventory item (§2), at section and sub-bullet granularity where they differ, the GSF-B1 implementation must emit a classification record with these fields:

- **disposition** — exactly one of:
  - `keep` — stays in the snippet, passed all six KP.
  - `absorb` — its live content moves into a **deployed** owner surface; snippet copy dropped.
  - `move` — relocated to a non-snippet surface that is not "absorption into executable behavior" (e.g. repo-local instruction).
  - `compress` — stays in the snippet but reduced to the minimal invariant + a pointer (no procedure/detail).
  - `delete` — not a current capability; removed with a deletion rationale, no placeholder.
  - `defer` — owned by another batch/track (e.g. skill-plan Batch 3 / Track F); GSF-B1 does not touch it (§8).
  - `stop/report` — touching it would cross a §13 boundary; GSF-B1 halts and reports instead of acting.
- **owner-surface** — the §5 surface that receives the content (for `absorb`/`move`/`compress`-pointer-target), or `n/a` (`keep`/`delete`/`defer`).
- **loading-class** — for any rule-like candidate, the §6 class(es); else `n/a`.
- **keep-by-proof** — the KP1–KP6 result (which passed/failed) justifying the disposition.
- **invariant-impact** — which §11 invariant(s) the item carries, and how the disposition preserves them.
- **rationale + pointer** — one line; for `absorb`/`move`/`compress` a concrete pointer to the new single home; for `delete` why it is non-current.

The record is the reviewable artifact for GSF-B1; the reviewer confirms each disposition against §3 and §11. (The record is a GSF-B1 runtime artifact — it is not created by this spec.)

### 4.1 Per-section acceptance frame (targets, not executed dispositions)

Acceptance targets the implementation must achieve **or** justify a reviewed deviation from (per §1). `impl-determined` means the spec fixes the procedure + bar, not the outcome.

| Item | KP focus | Acceptance target | Candidate owner-surface |
|---|---|---|---|
| 0 Header | KP3/KP4 strong | `keep` (compress only if redundant with inventory items 1/2 — Adoption destination/rules) | snippet |
| 1 Adoption destination | KP1–KP6 likely pass (adopter-universal hard adoption discipline; not executable) | `keep` | snippet (authority pointer: `GLOBAL_ADOPTION_DECISION.md`) |
| 2 Adoption rules | as #1 | `keep` | snippet |
| 3 Role neutrality | reviewer-mode reachability (§3) | `keep` or `compress`; **impl-determined** whether the reviewer-mode exclusion can be owned by the deployed skill vs must stay always-on | snippet / skill (impl-determined) |
| 4 Project layout | KP2 deployment-boundary; ToolRoot path-string is **out of scope** (Track E) | `keep` or `compress`; ToolRoot path-string untouched | snippet (authority: `SHARED_GLOBAL_INVOCATION_CONTRACT.md`) |
| 5 Review record | no-sidecar boundary is an invariant; reviewer-mode reachability | `keep` or `compress`; **impl-determined** vs skill+contract ownership | snippet / skill+contract (impl-determined) |
| 6 Result verdict vocabulary | "approves nothing" is reviewer-critical; next-action detail already pointer-referenced | `keep` core invariant; `compress` any residual detail | snippet / skill (impl-determined) |
| 7 Operator stance | already compact + pointer-referenced | `compress` or `keep`; **impl-determined** | snippet / skill |
| 8 Brief (BF-lv3 non-claim) | non-current capability note | **`defer` → skill-plan Batch 3 / Track F** (§8) | n/a (GSF-B1 does not touch) |
| 9 Chatlog | non-current capability section | **`defer` → skill-plan Batch 3 / Track F** (§8) | n/a (GSF-B1 does not touch) |
| 10 Forbidden — 6 safety bullets | hard boundaries; KP3 strong | `keep` (per-bullet) | snippet (rule-candidate tagging allowed, §6) |
| 10 Forbidden — Brief↔Chatlog-mirror bullet | references a Batch-3 concept | **`defer` → skill-plan Batch 3 / Track F** (§8) | n/a |
| 11 Other rules — commit/push approval | hard boundary; KP3 strong | `keep` | snippet |
| 11 Other rules — temp-file cleanup | generic operator hygiene | `keep` | snippet |

No row here removes a section by itself — these are targets the reviewed implementation must satisfy. Items 8/9 and the mirror bullet are **defer-only** for GSF-B1 (§8).

---

## 5. Owner-surface assignment rules

For any item not kept, the implementation assigns an owner by the design §8 order, choosing the **narrowest deployed sufficient** surface:

1. **scripts** — the behavior is actually performed by a script (`scripts/**`): the script (its code, and its help/validation text or comments) owns it.
2. **skill `description` / `SKILL.md`** — intent-triggered workflow/procedure: the owning skill (`snippets/claude-skills/**`). Discovery via `description`; procedure via `SKILL.md`.
3. **tests / verifier** — a deterministic guard: a `tests/**` test or a `scripts/verify-*.ps1` verifier.
4. **repo-local `CLAUDE.md` / `AGENTS.md`** — `ai-harness-toolset` repo-development-only guidance (deployed-irrelevant; tracked). Mirror-edited (§12).
5. **future AI-native rule candidate** — policy/prohibition/allowance/verifiable condition that is not a feature: **tag with a §6 loading-class only**; do not build it (deferred to GSF-B3, §6).
6. **docs reference / rationale** — non-active reference/contract/decision-record/rationale: a `docs/**` doc. **docs is never the fallback owner** (§10); chosen only when the content is genuinely non-active and the snippet keeps at most a pointer.
7. **delete** — not a current capability; removed with rationale.

**Binding rule:** an absorb/move target must be a real single home; the snippet then keeps **at most a pointer or nothing**, never a duplicate. If the chosen owner is a deployed surface that does not yet carry the content, extending it is allowed only within §13 (no semantic behavior/procedure change) — otherwise `stop/report`.

---

## 6. Loading-class taxonomy for rule-like candidates (classify-only)

When an item is a rule-like candidate (§5 step 5), GSF-B1 **tags** it with one or more loading classes below. **Tagging is classification metadata only** — GSF-B1 builds none of these:

| Loading class | Meaning |
|---|---|
| always-on root instruction candidate | belongs always-on in a root instruction file (global snippet or repo-local root `CLAUDE.md`/`AGENTS.md`) |
| always-on @import candidate | could be a separate file pulled in always-on via an import directive |
| Claude path-scoped rule candidate | a rule that should apply only under certain paths/contexts on the Claude side |
| Codex `AGENTS.md` instruction candidate | content for Codex's `AGENTS.md` instruction surface |
| Codex command/sandbox rule candidate | a Codex command-permission / sandbox-approval rule (vendor-specific permission surface; `INSTRUCTION_SURFACE_PLAN.md` §12 excluded it from instruction-surface scope) |
| skill candidate | intent-triggered → a skill |
| hook candidate | lifecycle automation → a hook (forbidden-by-default; tag only, never build) |
| test / verifier candidate | a deterministic guard |
| docs reference / rationale candidate | non-active reference/rationale |
| delete candidate | not a current capability |

**Hard limit (GSF-B1).** GSF-B1 may **classify** AI-native rule candidates into these classes but must **not** create `.claude/rules/`, `.codex/rules/`, any vendor-neutral rules source folder, any hook, or a broad rules catalog. The **vendor-neutral vs vendor-native rule loading strategy is deferred to GSF-B3** (`rules/` MVP consideration). If GSF-B1 finds a candidate that is *also* an immediately-needed deterministic guard, the only allowed action now is to fix it as a `tests`/verifier (class above), not to open a rules surface.

---

## 7. Marker / optional interaction baseline keep proof

The design §5 names the only content that may remain always-on as the **minimal managed-block marker** and **an optional interaction baseline**. GSF-B1 acceptance:

- **Managed-block marker / header (item 0).** `keep` is justified only by KP3 (every adopter must see the managed-block framing before anything else) + KP4 (self-contained). Acceptance: kept at minimal size; any duplicate of `## Adoption *` content is compressed to a pointer.
- **Optional interaction baseline.** If GSF-B1 proposes retaining or introducing any interaction-baseline text, it must prove (a) it is a **public default** (not a user/profile-specific preference — KP6), and (b) it passes KP1–KP5. If it is user/profile-specific, the disposition is **not** snippet-keep — it belongs in the operator's own global file, out of the deployed payload. Absent a proof, no interaction baseline is added (GSF-B1 is minimization, not feature addition).

---

## 8. Coordination with skill-plan Batch 3 / Track F (no re-own, no renumber)

Items 8 (`## Brief` BF-lv3 non-claim), 9 (`## Chatlog`), and the `## Forbidden` Brief↔Chatlog-mirror bullet are **owned by skill-plan Batch 3 (= instruction-surface Track F)** (design §3; plan §1; audit §3.8–§3.10, §5). GSF-B1 acceptance:

- GSF-B1 classifies these as **`defer`** and does **not** delete, edit, or renumber them. It does not absorb Track F into GSF-B1.
- If GSF-B1's snippet edit is sequenced to run together with skill-plan Batch 3 (the plan allows an interleave), the Chatlog/BF-lv3 deletions remain **attributed to skill-plan Batch 3** in the classification record and the closeout (skill plan §8 stays authoritative; `STATUS.md` SK ledger records them as Batch 3).
- The Batch-3 reconciliation dependencies (preserve "current restore source = Brief" elsewhere if still wanted; decide the mirror bullet's generic-vs-drop fate) are **Batch 3's**, not GSF-B1's — GSF-B1 must not pre-empt them.

---

## 9. Direct owner-surface absorption requirements

For every `absorb`/`move` disposition (design §5 "direct owner-surface absorption"):

- The content must land in its owner surface **in the same GSF-B1 change** (or an earlier landed surface), with a concrete pointer recorded — not "parked" for a later batch and not left only as a snippet deletion.
- Absorption into a deployed executable surface (`scripts`/skill/`tests`) is preferred over leaving an invariant in the snippet "until later" (design §8 "direct absorption beats parking").
- An absorption that would require a **semantic** change to runtime/install/skill-procedure behavior to carry the content is **`stop/report`** (§13), not a silent in-batch expansion.
- After absorption, the snippet retains at most a pointer or nothing; the owner surface is the single home (no duplication — `DOCS_OPERATING_MODEL.md` §1).

---

## 10. docs-as-reference-only

`docs/**` may receive content **only** as reference / contract / decision-record / rationale, never as a relocated always-on rule (design §6; `docs/README.md` §4: always-on rules never live under `docs/`). **docs is not the fallback owner** — if an item is still active always-on guidance, its owner is a deployed surface (snippet keep, repo-local instruction, or a deployed executable surface), not a doc. Moving active behavior into `docs/**` to "shrink the snippet" is the docs-as-policy-warehouse anti-pattern this migration exists to end and is a review-blocking outcome.

---

## 11. Snippet-invariant check criteria (acceptance gate)

GSF-B1 passes only if, after the edit, all hold (the reviewer confirms each):

1. **No hard boundary dropped** — every safety boundary (no daemon/watcher/scheduler/hook; no implicit/whole-file global-instruction mutation; no auto `.gitignore` mutation; no `BF_STATE.json`/sidecar; no per-user log partitioning; commit/push needs approval) survives in an owner surface (snippet or another deployed surface) with a pointer.
2. **No adoption / path-topology invariant dropped** — managed-block-only adoption, no whole-file overwrite, marker fail-fast, the forbidden `%USERPROFILE%\.claude\AGENTS.md`, ToolRoot/ProjectRoot/`log/` topology, canonical review-record path — each still reachable for every adopter.
3. **No role-binding invariant dropped** — role neutrality + the reviewer-mode exclusion still bind before any skill loads (reviewer-mode reachability, §3).
4. **No verdict/review invariant dropped without an owner surface** — the three verdict values + "verdict approves nothing" + the no-sidecar review-record boundary either stay in the snippet or have a confirmed reachable deployed owner (not docs-only, given reviewer-mode + deployment boundary).
5. **CLAUDE/AGENTS snippet symmetry preserved** — both snippets edited symmetrically; byte-identical except the intended tool-specific loci (§2). A single-snippet shared-content edit is an asymmetry defect.
6. **Every removed item has an owner-surface or a deletion rationale** — no content silently vanishes; the classification record (§4) accounts for each removal as `absorb`/`move`/`compress`-pointer-target/`delete`-with-rationale/`defer`.

---

## 12. Allowed implementation edits (GSF-B1)

GSF-B1 implementation may edit **only**:

- `snippets/CLAUDE_SNIPPET.md` and `snippets/AGENTS_SNIPPET.md` — symmetrically (the minimization itself).
- directly related skill `SKILL.md` / skill `description` — **only** to *receive* absorbed discovery/procedure content, without changing skill **procedure semantics** (§13).
- directly related `scripts/**` **help / validation text or comments** — only to carry absorbed operative text; **no script logic / runtime behavior change** (§13).
- directly related `tests/**` / verifiers — to add/adjust a deterministic guard for a relocated invariant (and to keep the suite green).
- root `CLAUDE.md` / `AGENTS.md` — **only if** an item is assigned the repo-local owner surface, and **only** mirror-edited (byte-identical shared body) with the parity guard run (§14/§15).
- directly related `docs/**` routing / status / reference — the coherence registrations (Q11, architecture README, skills `STATUS.md` if the snippet surface posture changes) and any reference/rationale landing per §10.

Anything outside this list is out of scope for GSF-B1.

---

## 13. Stop/report boundaries (GSF-B1)

If GSF-B1 would cross any of these, it **stops and reports**; it does not silently expand (design §10/§12; plan §4):

```
- runtime behavior semantic change
- install / update / uninstall behavior semantic change
- skill procedure semantic change
- ToolRoot move
- hooks (creation of any)
- memory inspect / export / edit / cleanup
- global / user file mutation (except an explicit managed-block adoption — not part of GSF-B1)
- rules catalog creation (.claude/rules/, .codex/rules/, vendor-neutral rules folder, broad catalog)
- docs deletion / compression / retirement (that is GSF-B4; GSF-B1 does not delete docs)
- snapshot / manifest creation
- commit / push (separate explicit approval)
```

An owner-surface extension (§9) that *looks like* it needs one of these is allowed only within non-semantic bounds; the moment it would change runtime/install/skill-procedure semantics it is `stop/report`.

---

## 14. Validation criteria (future GSF-B1 implementation)

GSF-B1 implementation closeout must run, and the review input must report:

- **full `Invoke-Pester -Path .\tests`** — snippet/template/test change expects the full suite green (run `-PassThru`, **not `-CI`**, to avoid the `testResults.xml` byproduct).
- **`scripts/verify-ps1.ps1`** — if any `.ps1` was touched (UTF-8 BOM+CRLF + native-stream rules).
- **`tests/repo-local-instruction-parity.Tests.ps1`** — if root `CLAUDE.md`/`AGENTS.md` were touched (shared-body byte-identity).
- **snippet symmetry / managed-block parsing / adoption-safety checks** — if a dedicated test/verifier exists for snippet symmetry, managed-block marker parsing, or adoption safety, run it; otherwise the §11.5 symmetry check + the reviewer confirmation stand in, and the gap is disclosed in the review input.
- **`git diff --check`** — whitespace/EOL integrity (new/untracked files need `git add -N` first to be covered).
- `.md` artifacts stay LF/no-BOM; `.ps1` stays UTF-8 BOM+CRLF.

## 15. Codex review criteria (future GSF-B1 implementation)

- **local-correctness review** — factual accuracy of the classification record, reference integrity, snippet symmetry byte-identity, no broken pointers.
- **system-coherence review** — the minimization coheres with the design/plan, owner-surface assignments are sound, docs is not used as fallback owner, Batch-3 coordination is respected, single-home-plus-pointers holds.
- **snippet-invariant check** — the §11 six-point gate, confirmed by the reviewer.
- **corrected-state re-review** — any source/doc edit *after* a review makes that review stale; re-run on the corrected tree (a new `pass-NN`), per the controlling review contract. A verdict approves no commit/push.

---

## 16. Coherence registrations made with this spec

Per the two-level closeout gate (`DOCS_OPERATING_MODEL.md` §7), inspect-all / report-each:

**Level 1:**
- `docs/current/REPO_READING_GUIDE.md` — **updated** (Q11): registers this spec as the GSF-B1 acceptance contract and reconciles the "still-unwritten spec" wording (the spec now exists, pending approval).
- `docs/roadmap/CURRENT_MILESTONES.md` — *checked: no change required* (numbered post-MVP order unchanged; `GSF-Bn` is its own namespace).
- `docs/decisions/POST_MVP_PLAN.md` — *checked: no change required* (numbered-order authority unchanged).

**Level 2:**
- `docs/architecture/README.md` — **updated** (instruction-surface row): lists this spec.
- `docs/README.md` §5 — *checked: no change required* (layer description + single example unchanged by adding a file in the existing subfolder).
- `docs/systems/skills/STATUS.md` — *checked: no change required* (spec stage; no snippet/skill content changed — no SK ledger row, no current-state flip; the snippet's current contents remain accurately described until GSF-B1 lands).
- root `CLAUDE.md` / `AGENTS.md` — *checked: no change required this batch* (the trigger-map "Snippet (global payload)" row already routes to the design + plan as controlling authority and states "no snippet minimization without an approved migration batch (spec)"; the plan/design route to this spec, so no re-wiring is required at spec stage — adding every per-batch spec to the always-on root row would bloat it against the "not a policy warehouse" rule).
- existing `INSTRUCTION_SURFACE_PLAN.md` / `GLOBAL_SNIPPET_RELOCATION_AUDIT.md` / `REPO_LOCAL_INSTRUCTION_SURFACE_PLAN.md` / `FUNCTION_LEVEL_SKILL_ARCHITECTURE_PLAN.md` — *checked: intentionally not edited* (prior evidence; relationship via design §3 + plan §1, routed by Q11).

---

## 17. Approval boundaries

- This spec **approves nothing** and **edits no global snippet**. It is the GSF-B1 acceptance contract; the classification it frames is produced and executed by the GSF-B1 implementation under its own review + approval.
- Producing it does not authorize: editing the snippet; removing any section; changing skill-procedure / runtime / install/update semantics; moving ToolRoot; creating `.claude/rules/` / `.codex/rules/` / vendor-neutral rules folders / hooks / a broad rules catalog; deleting/compressing/retiring docs; inspecting/editing memory; mutating global/user files; snapshot/manifest; or commit/push.
- A Codex review verdict (`yes` / `no` / `yes with risk`) on this spec does not auto-approve GSF-B1 implementation or any commit/push — each remains an explicit user decision.

---

## 18. One-line summary

Fix the GSF-B1 acceptance criteria — inventory the 11 snippet sections + header, run section/sentence keep-by-proof (default delete/absorb, keep-by-proof exception, honoring the deployment boundary and reviewer-mode reachability), emit a per-item classification record (`keep`/`absorb`/`move`/`compress`/`delete`/`defer`/`stop-report`) with owner-surface assignment and rule-candidate loading-class **tagging only** (no rules folders/hooks/catalog; strategy deferred to GSF-B3), defer Chatlog/BF-lv3 to skill-plan Batch 3 / Track F (no re-own), absorb directly into deployed owners (docs never the fallback owner), and pass the six-point snippet-invariant check under full validation + dual-perspective Codex review — while implementing nothing here.
