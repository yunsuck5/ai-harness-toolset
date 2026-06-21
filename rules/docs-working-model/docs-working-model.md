# Rule: Documentation working model (repo-only)

Applies to developing the `ai-harness-toolset` repository — the binding rules for the repo's **document artifact classes**, the **Design → Plan → Spec lifecycle**, **docs placement (end-state + transition)**, **Spec ↔ implementation synchronization**, and the **closeout gate**. This rule is self-contained: it does not delegate its meaning to any `docs/**` page. Read this rule **before** changing `docs/` content, producing a lifecycle document, or closing out work; the root `CLAUDE.md` / `AGENTS.md` *Docs trigger map* (`Source / docs` row) wires that trigger.

> **Package note.** This file is the operative home of the `rules/docs-working-model/` rule package. The package carries `templates/` (Design / Plan / Spec — `templates/docs-working-model_design_template.md` / `_plan_template.md` / `_spec_template.md`) and `checklists/` (Design / Plan / Spec conformance + closeout — `checklists/docs-working-model_design_checklist.md` / `_plan_checklist.md` / `_spec_checklist.md` / `_closeout_checklist.md`). Package entry / routing is via `rules/README.md`; this operative home routes to the package-internal forms (see *Template / checklist conformance gate*).

## When this rule applies

- Any task that **places, moves, changes, or closes out** `docs/` content.
- Any task that produces or revises a repo document through the **Design → Plan → Spec lifecycle** — authoring a Design / Plan / Spec, updating a live Spec, closing one out, or retiring an absorbed Design / Plan.
- Any creation or disposal of a temporary work artifact (Work Packet or `_incubation` document) or a future-work queue entry.

## Document artifact classes (five)

Every repo document artifact belongs to exactly one class; mixing roles across classes is a defect:

1. **Planning artifacts** — Design / Plan / Spec (lifecycle below). Only the Spec stays live after closeout.
2. **Temporary work artifacts** — **committed temporary documents** carried by git until closeout, then deleted (preservation = git history): the **Work Packet** (round-scoped; see *Work Packet*) and, for a pre-promotion candidate (a domain **or** rule candidate), the **`_incubation` document** (candidate-lifecycle-scoped, not round-scoped; see *Incubation tier*).
3. **Operator reports / closeout evidence** — execution results, review results, validation evidence, point-in-time states. Live under `<ProjectRoot>/log/**` (runtime area), never in planning-artifact bodies.
4. **Active implementation surfaces** — scripts, skills, snippets, templates, config, tests, root instruction files, `rules/**`. The active surface owns behavior; a doc describes it (root *Final hard rule*).
5. **Future-work queue** — per-domain `<domain>_backlog.md` (see *Future-work queue*).

## End-state placement and transition

**End-state (declared now; executed only per-domain).** The `docs/` tree converges to domain folders directly under `docs/`:

```text
docs/
  README.md                      # the only orientation map (placement + minimal routing)
  <domain>/
    <domain>_spec.md             # live — the domain's spec-of-record
    <domain>_backlog.md          # compact future-work queue
    <domain>_design.md           # exists only during a change (retired at closeout)
    <domain>_plan.md             # exists only during a change (retired at closeout)
    <domain>_work_packet.md      # exists only during a change (deleted at closeout)
```

- **Execution is per-domain-batch only.** This declaration creates no immediate mutation; each legacy structure migrates in its own scoped batch with owner absorption proof + reference sweep + review gate.
- **End-state wins conflicts.** When a new decision conflicts with a legacy structure, decide toward the end-state; execute in that domain's batch.
- **Legacy structures persist but do not grow.** Do not add new narrative/items to retirement-bound structures (STATUS narratives, decision bodies, architecture residue); unavoidable corrections stay at proportionality-rule level.
- **Transition orientation.** During the mixed period, **new** orientation/routing content lands in `docs/README.md` only — it is the single orientation source for the transition and the Level-1 gate surface. The per-question read-first routing has since converged into `docs/README.md` §7 (the former `docs/current/REPO_READING_GUIDE.md` routing surface has been retired). Any legacy routing surface still awaiting its migration batch remains unmigrated residue: it keeps serving its **existing** read-first routing until that batch, but no new routing content is added to it (it is not a home for *new* routing). Each domain batch's closeout verifies `docs/README.md` reflects the mixed state (see *Closeout — reduced two-level gate*).

**single-home-plus-pointers.** Every fact has exactly one authoritative home; all other mentions are pointers to it, never copies. Duplication is the staleness engine: a duplicated fact needs an N-place sweep on every change, and any missed place silently goes stale.

**Durable-pointer prohibition.** A committed doc must never use a durable pointer to a gitignored / local / scratch / runtime path (`log/**`, `polishing/**`, `repo_snapshot/**`, repo-sibling artifacts, runtime evidence, user/global files); durable pointers resolve only to git-tracked files or git commit/history. Externalized historical detail is preserved by git history — if a past decision is still operationally relevant, the active doc states the decision directly.

## Design / Plan / Spec lifecycle

A repo document / normative change is produced through a fixed lifecycle, not authored ad hoc:

```text
live Spec + live Implementation → 변경 필요 → Design → Plan → live Spec 을 목표 상태로 갱신
  → (필요 시 Work Packet) → Implementation (final Spec only) → closeout sync
  → Design/Plan/Work Packet 의 current-bearing 내용 흡수 → Design/Plan retire · Work Packet 삭제
  → Spec live · Implementation live
```

- **Design** — why / what / owner-surface model / non-goals / which live Spec or implementation it modifies. Not permanently live.
- **Plan** — **approval-target decisions only**: batch order / per-batch scope / hard boundaries / validation expectations / review focus / Work Packet declarations (purpose, absorption target, retire condition) / open-decision close points. A Plan is not a work memo — investigation results and round-scoped analysis belong in a Work Packet; execution sequences and execution records belong in operator reports under `log/**`.
- **Spec** — the domain's **target-state specification** (identity below). Live after closeout.
- **Implementation** — built from the **final Spec only** (no direct Design/Plan reference); it may consult a Work Packet, which never substitutes for the Spec. At closeout the Spec and the implementation are reconciled 1:1.

## Spec identity — target state + durable boundary

A Spec's meaning is time-phased: at writing completion it is the **blueprint of the target state to implement**; during implementation it is the implementer's reference; after closeout it is the **live specification 1:1-synchronized with the implementation**.

A Spec carries (the spec template fixes these as its eight sections): **Header** (what this document is / chain outcome / what it is not — each within 3 lines) · **목표 상태** (what the domain is/must be, in normative sentences) · **Owner surface 지도** · **Durable boundary** (standing allow/forbid boundaries; rules and specs own the *class/invariant*, concrete path values are owned by the active surface / `INSTALL.md`) · **Cross-domain interface** (interfaces only, never another domain's semantics) · **Validation expectation** · **Review focus** · **Lifecycle state**.

**A Spec must not contain:** round-scoped candidate-file lists, execution command sequences, staging procedures, review results, readiness judgments, or point-in-time work status (the lifecycle-state section's compact markers excepted). Those compact markers are limited to **state markers** (e.g. live / sync-required, capability maturity, lifecycle-doc presence) and must **not** copy a backlog's item ID enumeration or its next-ID allotment — those are owned by the backlog as their single home and are referenced by pointer only (per *single-home-plus-pointers*). Round-scoped **analysis** (candidate-file classification, investigation notes) belongs to the Work Packet; execution mechanics and records (command sequences, staging procedures, review / validation results, readiness judgments, point-in-time status) belong to operator reports under `log/**` (the *Work Packet* content boundary below).

## Work Packet (temporary work artifact)

- **Role**: a round-scoped temporary work document — line-level reference classification, investigation notes, implementation notes, evidence proposals, reviewer-question preparation, edge-case notes. **Not an approval target, not a live domain document, never a substitute for the Spec.**
- **Content boundary (forbidden in a Work Packet)**: execution command sequences, staging procedures, review results, validation results, readiness judgments — these are execution mechanics / records and belong to operator reports under `<ProjectRoot>/log/**` (or are not recorded at all).
- **Location**: `docs/<domain>/<domain>_work_packet.md` — a **committed temporary document** in the domain folder, carried by git until closeout. No subfolder evasion (`docs/<domain>/work/` is forbidden; the *Stable filename rule* applies). Being tracked makes it transferable, not live or authoritative.
- **Lifecycle**: created only when needed (a Plan may declare its necessity, absorption target, and retire condition); at closeout its current-bearing content is absorbed into the Spec / the correct owner surface / the closeout report; then the file is **deleted** — preservation is git history, like a Design/Plan retire.
- Boundary aid (when the Spec/Work-Packet line wavers): "is it still true after this round ends?" — true → Spec; false → Work Packet.

## Incubation tier (pre-promotion candidate stage)

A **candidate** — a capability or operating discipline under evaluation for whether it should become a promoted **domain** or a promoted **rule** — develops in a governed pre-promotion stage: in-repo but non-authoritative, neither an out-of-repo sprawl nor a premature domain/rule.

- **Admission.** A candidate enters incubation only with: a specific problem an existing domain/rule cannot cover, a candidate shape (expected single-home, not a bucket, the success-absorption artifact and the failure-deletion target named), an owner, a review-date, and discard criteria. Missing any → it stays out-of-repo scratch.
- **Incubation document.** One committed-temporary `<candidate>_incubation.md` per candidate, located by candidate kind: a **domain candidate** at `docs/<candidate>/`, a **rule candidate** at `rule_incubation/<candidate>/` (a candidate-only space separate from the domain-scoped `docs/` tree, holding only items **1:1-bound to a specific rule candidate whose terminal output is a rule file** — operating-philosophy / project-architecture / branching-strategy / domain documents are out of scope, a broad mixed-owner bucket there being the rejected `docs/architecture/` shape under a new name). It is candidate-local (a class-2 lifecycle role, deleted at promote or discard) and the candidate's **single, self-sufficient planning home**: a session or subagent can start work from this document alone — no separate seed document is required. The incubation tier produces **no separate `_design` / `_plan` / `_spec` file**; canonical role filenames (and authority) begin only at promotion, and at promotion a **rule candidate writes its terminal rule file directly** (Design → Plan → rule, **no separate Spec** — a rule is its own spec-of-record) while a **domain candidate** enters the full Design → Plan → Spec lifecycle. Header carries `non-authoritative` / `not referenced by canonical rules/indexes` / `owner` / `review-date` / `open questions`. The `_incubation` role joins the *Stable filename rule* as a committed-temporary candidate lifecycle role, not a canonical domain/rule identity.
- **Candidate lifecycle.** (optional ephemeral **seed** brainstorm — in conversation or out-of-repo scratch, not a required layer) → **incubation anchoring** (the consistency-checked incubation document lands in-repo at its first *approved* commit; the anchor is the meaning of that approved commit, **not** a self-commit licence — commit / push stay separate explicit approvals) → formalize (the incubation document matures to canonical *form*, still **non-authoritative**) → dev/test/pilot. At each **review-date** the candidate is decided: **promote** (a domain candidate enters the *Design / Plan / Spec lifecycle* with canonical filenames; a rule candidate writes its terminal rule file via Design → Plan → rule), **discard** (a closeout — delete), or **continue** (remain in incubation with a **new review-date** — no candidate continues without a live review-date; a review-date that passes undecided leaves the candidate non-conformant, stale until decided). On **promote**, a domain candidate's `docs/<candidate>/` becomes the new domain's home (renamed to the final name if it differs) and a rule candidate's content is absorbed into its `rules/` or `snippets/rules/` rule file; either way the incubation document's current-bearing content is absorbed (E4) into the promoted artifacts, then the `_incubation.md` (and, for a rule candidate, its now-empty `rule_incubation/<candidate>/` folder) is deleted. On **discard** the document is deleted with no absorption into any canonical surface; the discard rationale (the negative evidence that ended it) is stated in the discard commit message (preserved by git history), so a later re-proposal can find why it was rejected. The incubation document follows the lifecycle form and *Stage rewind* but remains non-authoritative.
- **Mandatory terminology registration.** At **incubation anchoring**, every *meaning-bearing* term the candidate introduces (one a follow-up session or subagent could otherwise read two ways) is registered in `rules/terminology-glossary.md` as **`pending`**, each carrying owner / facet / close condition / not-this / promotion target; convenience labels and one-off phase names stay self-contained in the incubation document, not the glossary (over-registering re-makes the glossary a planning document). A `pending` registration is a **reservation** (the term plus that metadata and at most a one-line gloss), **not** a relocation of the term's meaning home: the **full domain-local definition stays in the incubation document during incubation**, and the glossary becomes the single home of the term's **final** meaning only **at promotion**. At promotion or discard the terms are finalized (**accepted** / **accepted-with-owner-boundary** / **rejected**). Term finalization is **decoupled from candidate promotion** — a term may reach `accepted-with-owner-boundary` while its candidate still incubates, and a candidate may promote while one of its terms is rejected; the two are not one transaction. **Transition (already-anchored candidates).** This mandatory `pending` registration binds candidates that reach incubation anchoring **from this rule forward**; candidates already anchored before it (the existing `docs/consultation/` and `docs/blind-advisory/` candidates) are **not** retroactively required to backfill `pending` registrations — they keep their domain-local vocabulary during incubation and finalize at promotion exactly as their incubation documents already state, so the rule and those self-sufficient candidate docs agree rather than conflict.
- **Form early, authority late (the core invariant).** A candidate artifact may use canonical *form* but holds no canonical *authority* — a candidate's formalized content is never interpreted as a §*Spec identity* canonical Spec. Header text alone does not hold this; E1–E5 below bind as **rule requirements now** (conformance is manual until their checks exist — the checks are a separate implementation change):
  - **E1** — domain discovery is by promoted canonical artifact, never by `docs/<candidate>/` existence (a folder holding only `_incubation.md` is a non-domain candidate container; `docs/<candidate>/` is not an *End-state placement* domain home and not a discovery target before promotion). No new central registry — at most thin candidate-tracking metadata (name / owner / review-date) on an existing index/manifest, insufficient by itself to locate or use the candidate as a canonical input or discovery index (candidate tracking, not the durable reference E2 forbids).
  - **E2** — canonical rules/indexes must not durably reference a candidate `_incubation` document (its formalized content included); a canonical→candidate reference is only an **absorbed-conclusion summary** (satisfying E4, re-reviewable without the candidate path/link).
  - **E3** — before promotion a candidate artifact is not a default or input of any canonical surface (rules, indexes, templates, skills, reviewer checklists, Work Packet generator/input); no canonical-looking sibling (`_design` / `_plan` / `_spec`) is created during incubation.
  - **E4** — absorption into a tracked file carries: adopted conclusion / rejected alternatives / the evidence type that changed the judgment / scope / failure (discard) criteria / known negative evidence — so "why this survived" is re-reviewable without raw links.
  - **E5** — this rule's own incubation-tier addition, **and its generalization from pre-domain to pre-promotion (adding rule candidates)**, is a one-time bootstrap (incubation cannot incubate itself), not a precedent for later candidates.
- **Data separation (seed / log / tracked).** A candidate's **seed** is an *optional, ephemeral* brainstorm (conversation or out-of-repo scratch), advisory only and never a durable pointer (*Durable-pointer prohibition*) — it is **not a required layer**, and once the work reaches incubation anchoring the in-repo incubation document is the self-sufficient home, so no separate seed document need persist; measurement accumulates under `log/**` (gitignored, never git-tracked); a tracked file carries only self-contained absorbed decisions. Candidate planning while incubating is committed-temporary, never a permanent shadow of any active surface.
- **Incubation vs Work Packet.** Work Packet = the domain already exists (round work inside it); incubation = the promotion target (a domain or a rule) does not yet exist (deciding whether it should).
- **Absorption is a commit-boundary crossing.** Moving seed/scratch content into a tracked file is subject to the same content scrutiny as any other committed change — the absorption step is not a side channel that bypasses the repo's commit gate.
- **No round cap.** Incubation has no fixed cycle/round limit; it ends on convergence or on the operator/user judging the candidate ready or dead — never on a count.

## Future-work queue (`<domain>_backlog.md`)

- One file per domain. Each item = **one line + a reopen/start condition**. No narrative, no incident logs, no closeout reports.
- **Closed items: delete the row** (preservation = git history). Exception — a one-line tombstone is kept **only when** a live inbound reference to the closed ID remains and cannot be rewritten as a direct decision statement; the exception is determined by the bare-token/ID class of the reference sweep, not by discretion.
- **ID reuse prevention**: the file header carries one line `next ID: <PREFIX>-NN`, monotonically increasing (never decreased or reused after row deletion). `<PREFIX>` continues the domain's established ID prefix convention (BR / RV / IU / SK …); a new domain picks a short domain abbreviation.

## Spec ↔ implementation 1:1 synchronization

- The unit of 1:1 is the **normative sentence**, not lines or code (a Spec is never a prose mirror of scripts).
- Direction 1: every normative sentence in the Spec must be verifiable in the implementation.
- Direction 2: every externally observable behavior and ownership boundary of the implementation must have a corresponding Spec sentence. Internal implementation detail (function decomposition, naming, algorithm choice) is not a 1:1 target.
- **Reconstructibility** = from the Spec alone, an implementation with the *same behavior* can be rewritten (not the same code); from the implementation alone, the Spec's *normative meaning* can be reconstructed (meaning-level, not sentence-mirroring).
- Operating test: if an implementation change requires no Spec-sentence change, it is a refactoring (no sync needed); if it does, it is a behavior change (Spec update mandatory).

## Live-Spec update — the sync-required transition

For further development on a domain with a live Spec: after Design → Plan, **update the live Spec in place to the new target state** (no copies, no delta documents — single home). From that moment the domain state is **sync-required** (marked in the Spec's lifecycle-state section); implementation catches up; closeout re-verifies 1:1 and returns the state to **live**.

## Proportionality rule

Edits that do not change normative meaning (typos, stale pointers, wording cleanup) may be applied directly without Design/Plan — the normal review gate still applies. The moment normative meaning changes — an allow/forbid boundary, a behavior statement, an owner mapping, a validation expectation — the full lifecycle is required. The arbiter is the operating test above.

**Abuse guard** — so "wording cleanup" cannot smuggle meaning changes: (a) a direct edit's change description must state it is **meaning-preserving**; (b) if editor and reviewer disagree, or doubt remains, escalate to the lifecycle.

## Closeout — reduced two-level gate

A change's docs closeout is not done until both levels pass. **Inspection and reporting are unconditional; only updating is conditional.** For every listed surface the closeout report states `updated: <file> — <what>` or `checked: <file> — no change required`; silently skipping a listed surface is a gate failure.

- **Level 1 — orientation**: `docs/README.md` (routing/order reflects the change and the current mixed state), plus any not-yet-retired legacy orientation surface the change affects.
- **Level 2 — domain-local**: the domain's `<domain>_spec.md` (1:1 sync verified; lifecycle state updated) and `<domain>_backlog.md` (rows added/closed per the queue rule). For a not-yet-migrated domain, its current authoritative surfaces stand in until its migration batch.

## Lifecycle closeout — absorption and retire

A Design/Plan/Spec lifecycle closeout is not done until **all** hold:

- Spec ↔ implementation reconciled 1:1 (normative-sentence correspondence recorded as evidence in the closeout report / `log/evidence/**`, not in checklists).
- Every current-bearing Design decision and still-relevant Plan decision is expressed in the Spec (or the correct owner surface); no unique live meaning remains only in the Design / Plan / Work Packet.
- Inbound references are updated / removed.
- The Design and Plan are **retired** — retire is **deletion** (repo lifecycle); git history is the preservation mechanism, never an archive / `consumed/` folder.
- The Work Packet is deleted.

## Stage rewind

- **Plan violates the Design** → stop, redesign the Design, restart the Plan.
- **Spec violates the Plan** → stop, re-plan, restart the Spec.
- **Implementation exceeds the Spec boundary** → stop and ask the user; never silently widen scope.

## Stable filename rule

- Domain documents use **domain-prefixed role filenames**: `<domain>_design.md` / `<domain>_plan.md` / `<domain>_spec.md` / `<domain>_backlog.md` / `<domain>_work_packet.md` (the last is the class-2 temporary work document — a lifecycle role filename existing only during a change, deleted at closeout; not an auxiliary role doc). A pre-promotion candidate additionally uses `<candidate>_incubation.md` (*Incubation tier* — likewise a class-2 committed-temporary lifecycle role, deleted at closeout), located at `docs/<candidate>/` for a domain candidate or `rule_incubation/<candidate>/` for a rule candidate. Re-creating after deletion reuses the same role filename. Forbidden: `<topic>_*.md` topic-named files, filename-evading subfolder splitting (e.g. `docs/<domain>/work/`), per-feature design/plan/spec proliferation inside one domain.
- Auxiliary role docs (`_policy` / `_contract` / `_state` / `_status` / `_guide`) are **deferred** — not created by default; introduced only by an explicit Design/Plan decision.
- **Package-local form vs domain form.** This package's `templates/` / `checklists/` files carry the package prefix `docs-working-model_` and a `_template` / `_checklist` role suffix: they are **forms that produce another domain's** documents, not a domain's own artifacts.

## Authoring language

- New human-facing docs are **Korean by default**; technical identifiers (file / function / flag names, code, CLI tokens) stay English. This is a repo-development authoring convention for this repo's own docs — an adopter project chooses its own language.

## Domain-local closure and top-down reference

- **Domain-local closure** — each domain document is understandable from its own folder + its own live Spec + its own active surface + the stable interfaces it explicitly depends on. If understanding it requires reading another domain's semantics, the Spec has failed.
- **Top-down reference** — root `README.md` → `rules/README.md` → this rule package → a domain folder → the domain Spec. A lower layer does not complete its meaning by holding a durable pointer up to a routing document.

## Cross-domain semantics restriction

- Domain↔domain **semantics** references are forbidden by default. Narrowly allowed: a stable path / interface, schema, contract boundary, marker / payload-root / lifecycle boundary, or a domain whose essence is a cross-domain mechanism (install-update) — and even then only the **interface**, never a restatement of the other domain's semantics.
- Test: "if the target domain's implementation changes, does this reference change too?" yes = semantics (forbidden); no = interface (allowed).

## On-demand status-briefing model

There is **no committed project-current mirror file** — no committed active queue and no committed project-current summary. "What is done / what remains / what should I do next" is answered **on demand** by the agent reading the authoritative surfaces — after migration, each domain's `<domain>_spec.md` (lifecycle state) + `<domain>_backlog.md`; for a not-yet-migrated domain, its current authoritative surfaces stand in until its migration batch — then synthesizing a conversational briefing. The user selects the next task conversationally; no mirror file is written.

## Template / checklist conformance gate

- Each produced Design / Plan / Spec must pass its corresponding checklist, and a lifecycle closeout must pass the closeout checklist. Checklists test **meaning, not section presence** ("is the target state stated in normative sentences", "is round-scoped content zero", "are boundaries standing rather than per-round"). A judgment is recorded as "충족/미충족 + one-line evidence" — and **evidence is not accumulated in checklist bodies**: execution/closeout evidence belongs to operator reports / closeout reports.
- Templates and checklists must not generate boilerplate disclaimers or work-control prose; an approval boundary is stated **once per document**, never per section.
- The package forms live at `templates/docs-working-model_design_template.md` / `_plan_template.md` / `_spec_template.md` and `checklists/docs-working-model_design_checklist.md` / `_plan_checklist.md` / `_spec_checklist.md` / `_closeout_checklist.md`.
- A produced Spec is **not itself operative authority** over the active surface it specifies — the active surface owns behavior (root *Final hard rule*); the Spec specifies it and is reconciled against it.

## Scope of an application + review gate

- This rule defines the model; applying it to any specific legacy surface (domain migration, structure retirement) is its own scoped batch with owner absorption proof + reference sweep + review gate. The rule itself approves no commit / push / publish / merge / release, and no global/user filesystem mutation.
- Any change governed by this model goes through the normal Codex review gate (the globally installed review pipeline, corrected working tree). A verdict (`yes` / `no` / `yes with risk`) approves none of the above.

## Tier note

This is a repo-development rule for this repo only; it is **not** adopter-universal and **not** part of the global distribution (an adopter project may use a different docs authority model). It is not duplicated into `snippets/rules/`. Historical rationale and the predecessor model are preserved in git history.
