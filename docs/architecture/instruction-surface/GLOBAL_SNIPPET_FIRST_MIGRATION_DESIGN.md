# Global Snippet First — Migration Authority (Design)

**Status: architecture-level migration authority, design stage. NOT an implementation-approval document, NOT a snippet/docs edit, and NOT a re-classification of any snippet section.** This document establishes the *authority and criteria* by which the existing instruction surfaces of `ai-harness-toolset` — the always-loaded global snippet, `docs/**`, skills (`description` / `SKILL.md`), scripts, tests/verifiers, the repo-local root `CLAUDE.md` / `AGENTS.md`, and a future `rules/` surface — are re-judged for ownership under a **Global Snippet First** model. It changes no snippet, no docs body other than the minimal routing/placement registrations named in §13, no skill, no script, no test, and no behavior. The per-section migration sequence is the **plan** stage; the first batch's acceptance criteria are the **spec** stage; the actual snippet minimization is **implementation** — each is a separate scoped goal with its own Codex review gate and explicit user approval. **This document approves none of them.**

**Why this is an authority, not a reference.** A normal `docs/architecture/` doc *records* a structural target and routes to the subsystem surfaces that own current state. This document does that, but it also asserts a **precedence claim during the migration**: where an existing doc conflicts with the Global Snippet First model, the existing doc is treated as **evidence, not as automatically blocking source-of-truth** — it becomes a legacy candidate for migration, absorption, compression, deletion, or retirement, not a reason to stop. That precedence claim is the substance of this document and the reason it exists as its own surface rather than as another note inside the existing plan.

**Placement.** Co-located with the existing instruction-surface architecture docs in `docs/architecture/instruction-surface/` — it is a cross-cutting structural decision spanning the same surfaces those docs already span (global snippet, repo-local instruction, skills, contracts, scripts, tests, future rules), so it belongs in that subfolder, not under any single `docs/systems/<system>/`. Routing entry: `docs/current/REPO_READING_GUIDE.md` Q11. Layer registration: `docs/architecture/README.md`.

**Authorities this design obeys (does not redefine).** Docs placement → `docs/README.md`; docs change/closeout flow + single-home-plus-pointers + the durable-pointer rule → `docs/policies/DOCS_OPERATING_MODEL.md`; per-question routing → `docs/current/REPO_READING_GUIDE.md`; review artifact/verdict contract → `docs/contracts/review/REVIEW_RESULT_CONTRACT.md`. It states its own decisions directly rather than pointing at the out-of-repo direction note that seeded it (`DOCS_OPERATING_MODEL.md` §4 forbids a committed doc from durable-pointing at a gitignored/scratch path).

---

## 1. The problem this authority addresses

The presenting problem is **not** merely that the global snippet is long. The deeper problem is **surface-role drift across the instruction surfaces**, plus a **legacy gravity** in the existing docs that pulls every new decision back toward the drifted state.

These surfaces should hold different things:

```
global snippet  →  minimal managed-block marker (+ at most an optional interaction baseline)
docs/**         →  reference / contract / decision record / rationale
skills          →  intent-triggered workflow + invoked procedure
scripts         →  command / runtime behavior, install/update, file mutation, verification
tests/verifiers →  deterministic guard
repo-local      →  ai-harness-toolset repo-development instruction (root CLAUDE.md / AGENTS.md)
future rules    →  policy / prohibition / allowance / verifiable conditions (a later surface)
```

In the prior structure, feature descriptions, procedures, policy, fallbacks, routing, and status accreted into the **global snippet** and **`docs/**`**. The consequences:

1. The global snippet behaves like a **feature-behavior / procedure / policy warehouse**, paid by every adopter session for every task.
2. `docs/**` behaves like **active instruction / runtime policy / skill fallback**, rather than reference/contract/rationale.
3. Content that an **executable surface** (skill / script / test) should own is duplicated into docs or the snippet.
4. **Stale docs act as source-of-truth for later work**, steering each new decision back toward the global-snippet-heavy, docs-as-policy-warehouse model.

The first purpose of this migration is to **break that gravity**. `ai-harness-toolset` is a **tool, not a framework**; feature behavior must be owned by an *executable* surface (skill / script / test), not by always-on prose.

---

## 2. Primary purpose — block legacy docs gravity

**The primary purpose of the Global Snippet First design → plan → spec sequence is to prevent stale docs from anchoring Claude/Codex back to the previous global-snippet-heavy and docs-as-policy-warehouse model.**

Existing docs are **evidence**, but not automatically **blocking source-of-truth** during this migration. If an existing doc conflicts with this Global Snippet First migration authority, classify it as a **legacy candidate** for migration, absorption, compression, deletion, or retirement — **not** as a reason to keep the snippet heavy or to keep extending docs as a policy warehouse.

This is **not** a license to discard docs. It narrows what `docs/**` is *for* — from `active instruction / runtime policy / skill fallback / global-snippet rationale warehouse` down to `reference / contract / decision record / rationale`. The body of a doc may survive intact; what changes is its *role* and its *authority weight during the migration*.

### 2.1 Correct vs incorrect conflict handling

**Correct** (the legacy-gravity-breaking reading):

```
an existing doc conflicts with the Global Snippet First model
→ the new model is not presumed wrong; the existing doc may be stale
→ classify that doc/section as a legacy candidate
→ absorb its live content into the owner surface, or compress / delete / retire it
```

**Incorrect** (the legacy-gravity-restoring reading — explicitly rejected):

```
an existing doc names the global snippet as owner            → therefore keep the snippet content
an existing doc describes a skill fallback in the snippet    → therefore keep a review/brief blurb in the snippet
an existing doc reads like a policy warehouse                → therefore write more policy into docs
an existing status doc has not been flipped yet              → therefore postpone the design shift
weaken snippet minimization so an existing doc is not broken
```

Each incorrect reading lets a stale surface veto the migration. None is a valid basis for a keep/defer decision under this authority.

---

## 3. Document standing and relationship to the existing instruction-surface docs

This design sits **above** the existing instruction-surface architecture docs for the duration of the migration, and **re-opens their default**, while preserving them as the prior decision record.

| Existing doc | Role under this authority |
|---|---|
| `INSTRUCTION_SURFACE_PLAN.md` (Track A) | **Retained evidence.** Its trigger-tier model, tier set, memory/hooks/Codex-Rules policy, and §13 ToolRoot-as-separate-surface remain valid. Its §9 first-pass dispositions and §14 track framing are re-judged here (see below). |
| `GLOBAL_SNIPPET_RELOCATION_AUDIT.md` (Track B) | **Retained evidence, snapshot-pinned** to its `ea61048` audit basis. Its per-section *analysis* (duplication map, deployment-boundary distinction, symmetry baseline) is high-value input. Its **default disposition** — "global keep" for almost every section, with the headline finding that only the two PowerShell rules leave the snippet — is **re-opened**: that default is the conservative-keep posture this migration is escalating away from, not a settled keep. |
| `REPO_LOCAL_INSTRUCTION_SURFACE_PLAN.md` (Track C) | **Retained and live.** The repo-local root `CLAUDE.md` / `AGENTS.md` surface it created is a primary *absorption target* of this migration (an executable/always-on owner surface that is not the global snippet and not `docs/**`). Option A (parallel byte-identical body + thin header) and the mirror-edit discipline are unchanged. |
| `FUNCTION_LEVEL_SKILL_ARCHITECTURE_PLAN.md` + `docs/systems/skills/STATUS.md` (Q10) | **Retained, authoritative for the skill-subsystem batch order (its §8).** Its §4 "what STAYS always-on" list is the conservative-keep statement this design re-opens: those sections become keep-by-proof candidates (§7), not presumptive keeps. The Batch 3 (Chatlog / BF-lv3) ownership stays with the skill plan §8; this design re-situates it, it does not renumber or re-own it. |

**The escalation, stated plainly.** The existing Track B audit and skill plan §4 default to **keep almost everything in the snippet**, moving out only the two PowerShell-authoring rules. This design **inverts the default**: the default disposition becomes **delete / move / absorb / compress**, and **keep is the exception that must be proven** (§7). This is a deliberate directional change, not a contradiction to be hidden — the prior conservative default is exactly the "legacy gravity" §2 names. The prior audit's *analysis* is kept as evidence; its *default* is superseded for the migration.

**Crucial scope limit.** Re-opening the default is **not** re-classifying the sections. This design fixes the *default*, the *criteria* (§7), the *owner-surface order* (§8), and the *conflict order* (§4). **Which specific sections end up kept vs absorbed is plan/spec work**, decided by applying these criteria section by section under a later review gate — not asserted here. This document must not be read as having decided that any particular section (operator stance, verdict vocabulary, project layout, adoption rules, forbidden catalog, …) is removed; it has decided only that each is a **re-judgment candidate** under a default-delete/keep-by-proof regime.

---

## 4. Source-of-truth conflict order during the migration

When an existing doc and this migration authority disagree, resolve in this order (highest first):

```
1. the current user instruction
2. project instructions / repo-local CLAUDE.md / AGENTS.md
3. Global Snippet First design / plan / spec (this family)
4. the executable surfaces: skills / scripts / tests / verifiers / repo-local instruction
5. existing docs / status / contracts
6. historical / stale / retired docs
```

Notes:

- This order applies **only to the migration’s ownership/keep/absorb judgments**. It does **not** override the standing safety hard boundaries (commit/push approval, no global/user file mutation, no whole-file overwrite of a global instruction file, no hooks, reviewer independence, verdict-approves-nothing). Those are invariants, not legacy candidates, and rank above any migration convenience.
- Levels 5–6 (existing docs / contracts / status) are **evidence**: consulted, weighed, and where live, absorbed into the right owner — but they do not *block* a level-3/4 decision merely by existing.
- A contract under `docs/contracts/**` keeps its authority **for the artifact/protocol it governs** (e.g. the review-result shape). The migration re-judges where the snippet’s *operative copy* of a contract fact should live; it does not rewrite the contract’s artifact definition.

---

## 5. Global Snippet First principle

The first work axis is **not** `rules/` design. It is:

> **Global snippet minimization with direct owner-surface absorption, under legacy docs gravity.**

The principle:

- **Empty the global snippet first.** Treat its content as removal-by-default, not keep-by-default.
- **Do not relocate blindly into docs or rules.** Removed content is not automatically dumped into `docs/**` or a new `rules/` catalog. Each removed item gets a real **owner surface** (§8).
- **Absorb directly into the owner surface.** Where the owner is an executable surface (skill / script / test) or the repo-local instruction, the removed content is absorbed there, with at most a non-deployed reference/rationale left in docs.
- **Treat the current docs structure as audit-target.** It is tracked source, but under the new model it carries legacy gravity; it is re-judged, not presumed authoritative.
- **Defer `rules/`.** A `rules/` surface is a meaningful later surface, but it is **not** the goal of the first batch (§9).

**Snippet keep exceptions** (the only things that may remain always-on, and each only if it passes §7):

```
- minimal managed-block marker
- an optional interaction baseline
```

Whether an "interaction baseline" is a **public default** (belongs in the deployed snippet) or a **user/profile-specific overlay** (belongs in the operator's own global file, not the deployed payload) is itself a judgment the plan/spec must make — it is not assumed to be snippet content.

---

## 6. The deployment boundary — why "absorb into docs" is not the answer

A naïve reading of "minimize the snippet" would move snippet text into `docs/**`. That is **wrong on two counts**, and this design states both as binding constraints on §7/§8:

1. **`docs/` is not a fallback owner.** Even when an item is genuinely a rule/contract fact, `docs/**` is reference/contract/rationale — not an active-instruction warehouse. Moving always-on behavior into docs re-creates the docs-as-policy-warehouse pattern this migration exists to end (`docs/README.md` §4: always-on rules never live under `docs/`).
2. **`docs/` is not deployed.** The global adopter receives only `config/` + `scripts/` + `snippets/` + `templates/` (mirrored to the install root); `docs/`, `tests/`, `log/` are **not** mirrored. So an invariant whose only *deployed* operative home is the snippet **cannot** be "moved to a doc" without dropping it for every adopter. The Track B audit identified this precisely as the **authority vs operative residue** distinction, and used it to justify keeping operative copies in the snippet.

**This design engages that constraint rather than dismissing it.** The deployment boundary is real evidence, not legacy gravity — but it does not, by itself, justify *keep*. When an item is currently snippet-resident *only because its authority doc is non-deployed and no deployed executable surface owns it*, the keep-by-proof test (§7) forces a choice in the plan/spec stage:

```
(a) it is a true adopter-universal invariant with no better deployed owner  → genuine snippet keep (passes §7)
(b) its real owner is behavior a deployed skill/script/test should perform   → move the owner to that deployed surface, then drop the snippet copy
(c) it is repo-development-only                                              → repo-local root CLAUDE.md / AGENTS.md (deployed-irrelevant; tracked)
(d) it is not a current implemented capability                              → delete (no future/deferred placeholder)
```

The migration’s ambition is to convert as much (b)/(c)/(d) as the evidence supports, leaving the snippet with only genuine (a) plus the §5 marker/baseline. The audit’s "operative residue → keep" rulings are re-judged against (b): *could a deployed executable surface own this instead of always-on prose?* That re-judgment is plan/spec work; this design only fixes that it must happen and that "park it in docs" is not an allowed answer.

---

## 7. Keep / delete classification criteria

**Default disposition:** `delete / move / absorb / compress`.

**Keep is the exception.** A snippet item is kept always-on **only if all of the following hold** (keep-by-proof):

```
1. it is not a feature behavior, rule procedure, or routing/fallback that an executable surface should own;
2. there is no better owner surface among skill / script / test / repo-local instruction / future rules / docs-reference;
3. it is needed by every adopter, always, before any skill triggers;
4. it is self-contained — understood without reading docs/** (because docs/** is not deployed);
5. leaving it always-on carries low future-drift risk;
6. it does not conflate a public default with a user/profile-specific preference.
```

If any one fails, the item is **not** a snippet keep — it is a move/absorb/compress/delete candidate routed by §8.

**Delete / absorb candidates (illustrative, non-binding — the plan/spec re-judges each).** The direction this migration takes is that the following are *candidates* for leaving the snippet, against the conservative-keep default — listed to show the intended ambition, **not** to pre-decide any outcome:

```
review procedure · Brief procedure · Chatlog reconstruction behavior · install/update procedure ·
ToolRoot resolution behavior · review-record creation behavior · skill routing / skill fallback ·
docs pointer · forbidden catalog · operator stance · reviewer stance · verdict vocabulary ·
project layout / log layout · adoption destination / adoption rules
```

Several of these the Track B audit ruled "global keep"; under this authority they are re-judgment candidates, each tested against §6(a–d) and §7(1–6). Some will survive as genuine (a) keeps; the point is that survival must be **proven**, not inherited from the prior default. The standing safety hard boundaries (§4 notes) are not on this candidate list as removals — but *where* they are best owned (snippet vs a deployed verifier/script vs repo-local) is still a legitimate owner-surface question.

---

## 8. Owner-surface absorption order

For each item that leaves (or might leave) the snippet, decide its owner in this order:

```
1. Is there a script that actually performs the behavior?            → scripts own it (behavior is executable, not prose)
2. Is it an intent-triggered workflow?                               → skill description / SKILL.md owns it
3. Is it a deterministic guard?                                      → tests / verifier owns it
4. Is it ai-harness-toolset repo-development guidance?               → root CLAUDE.md / AGENTS.md owns it
5. Is it a policy / prohibition / allowance / verifiable condition,
   not a feature?                                                    → future rules/ candidate (classify only; §9)
6. Is it rationale / contract / decision record?                    → docs as reference/rationale (NOT active instruction)
7. Is it not a current capability, or a stale note?                 → delete
```

Binding rules on this order:

- **`docs/` is never the fallback owner** (§6). It is chosen at step 6 only for genuinely non-active reference/contract/rationale, and even then the snippet keeps at most a pointer or nothing — never a relocated active rule.
- **An owner can be a not-yet-sufficient surface.** If the right owner is a deployed executable surface that does not yet carry the behavior (e.g. a script/skill/test that would need extending so the snippet can drop the item), that extension is **plan/spec/implementation** work with its own boundary and approval — it is not done here, and it must respect the standing stop boundaries (no runtime-behavior change, no install/update change, no skill-procedure-semantics change without separate approval).
- **Direct absorption beats parking.** Where step 1–4 yields a deployed owner that can carry the item now, the migration prefers absorbing it there over leaving it in the snippet "until later."

---

## 9. `rules/` extraction is a later stage

A `rules/` surface is a meaningful follow-on, but **explicitly not the first batch’s goal**. This design only fixes its *standing*, not its content:

- The first batch does **not** create a broad `rules/` catalog. Discovering a rule candidate means **classifying** it (record that it is a rules candidate and of which kind), not building the catalog.
- If a rule candidate is *also* an immediately-needed deterministic guard, it may be fixed as a **test/verifier** first (step 3 of §8), independent of any `rules/` surface.
- Rule kinds, for classification only (carried from the existing plan, not re-decided here):

| Kind | Meaning | Current judgment |
|---|---|---|
| global distributed rule library | reusable rules shipped with the toolset but **opt-in** per target project | classify candidates only |
| repo-local rule | active rules for developing `ai-harness-toolset` itself | needed (root files already host some) |
| global always-on rule | rules auto-applied to every installed environment | currently almost none |

Key distinction the plan/spec must honor: **shipped globally ≠ applied always-on to every project.** A rule can be distributed by the toolset and still require explicit per-project adoption.

---

## 10. Stage model and the design-stage boundary

This is the **design** stage of a four-stage sequence. Each stage is a separate scoped goal + review gate + explicit approval.

| Stage | Produces | This authority’s role |
|---|---|---|
| **Design** (this doc) | the migration authority: purpose, conflict order, principle, deployment-boundary constraint, keep-by-proof criteria, owner-surface order, rules deferral | establishes criteria; re-opens the conservative default; re-classifies nothing |
| **Plan** (later) | the ordered migration batch sequence — which snippet content / which legacy docs are re-judged in what order, each batch’s hard boundary and review gate | applies the conflict order + keep/absorb criteria to produce a sequence; **not written yet** |
| **Spec** (later) | the first implementation batch’s acceptance criteria — keep-proof per item, marker/baseline proof, owner-surface assignment, allowed skill/script/test edits, stop boundaries, validation + review criteria | fixes batch-1 execution truth; **not written yet** |
| **Implementation** (later) | the actual snippet minimization + direct owner-surface absorption | follows the **spec** (not design/plan); out-of-spec scope is stop/report, never silent expansion |

**Allowed in the design stage:** reviewing the direction input; inspecting the repo-local instruction-surface docs and the routing/status/source-of-truth surfaces; writing this design document; reflecting the minimum routing/placement coherence (§13).

**Forbidden in the design stage** (each is a later stage or a separately-approved surface):

```
- reducing the global snippet payload
- changing skill procedure semantics
- changing runtime behavior
- changing install / update / uninstall behavior
- creating a rules/ catalog
- mass docs deletion
- moving ToolRoot
- inspecting / exporting / editing / cleaning up memory
- introducing hooks
- creating vendor-specific Codex Rules
- mutating any global / user file
- creating any snapshot / manifest
- commit / push
```

---

## 11. What this design changes in the repo

Only two kinds of change accompany this document, both minimal-coherence registrations (§13), never content relocation:

1. **This design document** is created under `docs/architecture/instruction-surface/`.
2. **Routing/placement registration** so the new authority is discoverable from the entrypoints an operator actually starts from: `docs/current/REPO_READING_GUIDE.md` Q11 and `docs/architecture/README.md`.

No snippet, skill, script, test, contract body, or existing architecture-doc body is edited. In particular, the existing Track A/B/C/skill-plan docs are **left intact as prior evidence** — their relationship to this authority is declared here (§3) and surfaced via Q11, rather than by editing their bodies (which would be plan-stage re-judgment or scope creep). The repo-local root `CLAUDE.md` / `AGENTS.md` trigger-map wiring (so snippet-task operators inspect this authority) is **deferred to the plan/implementation stage** — until the plan/spec make the migration operative, the existing audit remains the operative guidance for any snippet work, and wiring an inactive authority into the always-on repo-local surface would be premature (and would touch the mirror-edited surface under the parity guard).

---

## 12. Anti-patterns this authority forbids during the migration

```
- "the existing doc says snippet owns it, so keep it"                 (legacy gravity; re-judge instead — §2.1)
- "minimize the snippet by moving text into docs/**"                  (docs is not a deployed owner — §6)
- "park removed content in a new rules/ catalog now"                  (rules is deferred — §9)
- "weaken minimization so an existing doc stays consistent"           (the doc is the legacy candidate, not the brake — §2.1)
- "the status doc hasn't flipped, so defer the design shift"          (status flips follow the change; they don't gate the design — §2.1)
- "design decided section X is removed"                               (design fixes default+criteria; section disposition is plan/spec — §3)
- expanding beyond the spec during implementation                     (stop/report, never silent expansion — §10)
```

---

## 13. Coherence registrations made with this document

Per the two-level closeout gate (`DOCS_OPERATING_MODEL.md` §7), inspect-all / report-each:

**Level 1 (top-down orientation):**
- `docs/current/REPO_READING_GUIDE.md` — **updated** (Q11): registers this design as the migration authority and states its relationship to the existing Track A/B/C plan/audit (evidence, snapshot-pinned; default re-opened).
- `docs/roadmap/CURRENT_MILESTONES.md` — *checked: no change required* (the numbered post-MVP order is unchanged; this is a design-stage architecture doc, not a numbered milestone).
- `docs/decisions/POST_MVP_PLAN.md` — *checked: no change required* (the numbered-order authority is unchanged; this design explicitly does not rewrite it).

**Level 2 (system-local):**
- `docs/architecture/README.md` — **updated** (instruction-surface subfolder row): lists this design doc alongside the existing three.
- `docs/README.md` §5 — *checked: no change required* (the `docs/architecture/` layer description and its single example are unchanged by adding a fourth doc in the existing subfolder).
- `docs/systems/skills/STATUS.md` — *checked: no change required* (design-stage; no snippet/skill content changed, so no SK ledger row and no current-state flip — the snippet’s current contents are still accurately described there until an implementation batch lands).
- existing `INSTRUCTION_SURFACE_PLAN.md` / `GLOBAL_SNIPPET_RELOCATION_AUDIT.md` / `REPO_LOCAL_INSTRUCTION_SURFACE_PLAN.md` / `FUNCTION_LEVEL_SKILL_ARCHITECTURE_PLAN.md` — *checked: intentionally not edited* (preserved as prior evidence; relationship declared in §3 and routed via Q11).

---

## 14. Approval boundaries

- This document **approves nothing.** It is a design-stage migration authority, not an implementation, adoption, or commit/push approval.
- It **re-classifies no snippet section**; it fixes the default, criteria, conflict order, and owner-surface order under which the plan/spec will re-classify.
- Producing or revising it does not authorize: editing the global snippet; creating a `rules/` catalog; editing skills/scripts/tests; changing runtime / install / update / uninstall / skill-procedure semantics; moving ToolRoot; inspecting/exporting/editing/cleaning memory; creating hooks or Codex Rules; mutating any global/user file; creating any snapshot/manifest; mass docs deletion; or commit/push.
- A Codex review verdict (`yes` / `no` / `yes with risk`) on this design does not auto-approve the plan stage, any batch, or any commit/push — each remains an explicit user decision.

---

## 15. One-line summary

Establish, inside the repo, a design → plan → spec sequence whose **design** layer (this document) is an **architecture-level migration authority**: it blocks stale docs from anchoring work to the old global-snippet-heavy / docs-as-policy-warehouse model, makes existing docs **evidence rather than blocking source-of-truth**, inverts the snippet default to **delete/move/absorb/compress with keep-by-proof**, requires **direct owner-surface absorption** (never docs-as-fallback, honoring the deployment boundary), and **defers `rules/`** — while re-classifying no section, which is plan/spec/implementation work.
