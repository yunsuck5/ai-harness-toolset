# Rule: Documentation working model (repo-only)

Applies to developing the `ai-harness-toolset` repository — the binding rules for the repo's **document artifact classes**, the **Design → Plan → Spec lifecycle**, **docs placement (end-state + transition)**, **Spec ↔ implementation synchronization**, and the **closeout gate**. This rule is self-contained: it does not delegate its meaning to any `docs/**` page. Read this rule **before** changing `docs/` content, producing a lifecycle document, or closing out work; the root `CLAUDE.md` / `AGENTS.md` *Docs trigger map* (`Source / docs` row) wires that trigger.

> **Package note.** This file is the operative home of the `rules/docs-working-model/` rule package. The package carries `templates/` (Design / Plan / Spec — `templates/docs-working-model_design_template.md` / `_plan_template.md` / `_spec_template.md`) and `checklists/` (Design / Plan / Spec conformance + closeout — `checklists/docs-working-model_design_checklist.md` / `_plan_checklist.md` / `_spec_checklist.md` / `_closeout_checklist.md`). Package entry / routing is via `rules/README.md`; this operative home routes to the package-internal forms (see *Template / checklist conformance gate*).

## When this rule applies

- Any task that **places, moves, changes, or closes out** `docs/` content.
- Any task that produces or revises a repo document through the **Design → Plan → Spec lifecycle** — authoring a Design / Plan / Spec, updating a live Spec, closing one out, or retiring an absorbed Design / Plan.
- Any creation or disposal of a temporary work artifact (Work Packet) or a future-work queue entry.

## Document artifact classes (five)

Every repo document artifact belongs to exactly one class; mixing roles across classes is a defect:

1. **Planning artifacts** — Design / Plan / Spec (lifecycle below). Only the Spec stays live after closeout.
2. **Temporary work artifacts (Work Packet)** — round-scoped execution aids (see *Work Packet*). Never committed to the repo.
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
```

- **Execution is per-domain-batch only.** This declaration creates no immediate mutation; each legacy structure migrates in its own scoped batch with owner absorption proof + reference sweep + review gate.
- **End-state wins conflicts.** When a new decision conflicts with a legacy structure, decide toward the end-state; execute in that domain's batch.
- **Legacy structures persist but do not grow.** Do not add new narrative/items to retirement-bound structures (STATUS narratives, decision bodies, architecture residue); unavoidable corrections stay at proportionality-rule level.
- **Transition orientation.** During the mixed period, **new** orientation/routing content lands in `docs/README.md` only — it is the single orientation source for the transition and the Level-1 gate surface. Legacy routing surfaces (e.g. `docs/current/REPO_READING_GUIDE.md`) are unmigrated residue: they keep serving their **existing** read-first routing until their own migration batch, but no new routing content is added to them (they are not a home for *new* routing). Each domain batch's closeout verifies `docs/README.md` reflects the mixed state (see *Closeout — reduced two-level gate*).

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
- **Plan** — **approval-target decisions only**: batch order / per-batch scope / hard boundaries / validation expectations / review focus / Work Packet declarations (purpose, absorption target, retire condition) / open-decision close points. A Plan is not a work memo — investigation results and execution sequences belong in a Work Packet.
- **Spec** — the domain's **target-state specification** (identity below). Live after closeout.
- **Implementation** — built from the **final Spec only** (no direct Design/Plan reference); it may consult a Work Packet, which never substitutes for the Spec. At closeout the Spec and the implementation are reconciled 1:1.

## Spec identity — target state + durable boundary

A Spec's meaning is time-phased: at writing completion it is the **blueprint of the target state to implement**; during implementation it is the implementer's reference; after closeout it is the **live specification 1:1-synchronized with the implementation**.

A Spec carries (the spec template fixes these as its eight sections): **Header** (what this document is / chain outcome / what it is not — each within 3 lines) · **목표 상태** (what the domain is/must be, in normative sentences) · **Owner surface 지도** · **Durable boundary** (standing allow/forbid boundaries; rules and specs own the *class/invariant*, concrete path values are owned by the active surface / `INSTALL.md`) · **Cross-domain interface** (interfaces only, never another domain's semantics) · **Validation expectation** · **Review focus** · **Lifecycle state**.

**A Spec must not contain:** round-scoped candidate-file lists, execution command sequences, staging procedures, review results, readiness judgments, or point-in-time work status (the lifecycle-state section's compact markers excepted). Those belong to the Work Packet or operator reports.

## Work Packet (temporary work artifact)

- **Role**: round-scoped execution aid — application order, investigation results, edge-case notes, reviewer questions, candidate-file worklists, execution checklists. **Not an approval target.**
- **Location**: `<ProjectRoot>/log/work/<topic>/` (runtime area). **Never committed to the repo**; committed docs never durable-point into it.
- **Lifecycle**: created only when needed (a Plan may declare its necessity, absorption target, and retire condition); at closeout its current-bearing content is absorbed into the Spec / the correct owner surface / the closeout report; then it is **deleted**.
- Boundary aid (when the Spec/Work-Packet line wavers): "is it still true after this round ends?" — true → Spec; false → Work Packet.

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

- Domain documents use **domain-prefixed role filenames**: `<domain>_design.md` / `<domain>_plan.md` / `<domain>_spec.md` / `<domain>_backlog.md`. Re-creating after deletion reuses the same role filename. Forbidden: `<topic>_*.md` topic-named files, filename-evading subfolder splitting, per-feature design/plan/spec proliferation inside one domain.
- Auxiliary role docs (`_policy` / `_contract` / `_state` / `_status` / `_guide`) are **deferred** — not created by default; introduced only by an explicit Design/Plan decision.
- **Package-local form vs domain form.** This package's `templates/` / `checklists/` files carry the package prefix `docs-working-model_` and a `_template` / `_checklist` role suffix: they are **forms that produce another domain's** documents, not a domain's own artifacts.

## Domain-local closure and top-down reference

- **Domain-local closure** — each domain document is understandable from its own folder + its own live Spec + its own active surface + the stable interfaces it explicitly depends on. If understanding it requires reading another domain's semantics, the Spec has failed.
- **Top-down reference** — root `README.md` → `rules/README.md` → this rule package → a domain folder → the domain Spec. A lower layer does not complete its meaning by holding a durable pointer up to a routing document.

## Cross-domain semantics restriction

- Domain↔domain **semantics** references are forbidden by default. Narrowly allowed: a stable path / interface, schema, contract boundary, marker / payload-root / lifecycle boundary, or a domain whose essence is a cross-domain mechanism (install-update) — and even then only the **interface**, never a restatement of the other domain's semantics.
- Test: "if the target domain's implementation changes, does this reference change too?" yes = semantics (forbidden); no = interface (allowed).

## On-demand status-briefing model

There is **no committed project-current mirror file** — no committed active queue and no committed project-current summary. "What is done / what remains / what should I do next" is answered **on demand** by the agent reading the authoritative surfaces — after migration, each domain's `<domain>_spec.md` (lifecycle state) + `<domain>_backlog.md`; until then, the not-yet-migrated domain's current surfaces (`docs/systems/*/STATUS.md` / `BACKLOG.md` / `DEFERRED.md`) — then synthesizing a conversational briefing. The user selects the next task conversationally; no mirror file is written.

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
