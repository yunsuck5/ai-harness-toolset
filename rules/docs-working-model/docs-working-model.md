# Rule: Documentation working model (repo-only)

Applies to developing the `ai-harness-toolset` repository — the binding rules for *where a doc belongs in the `docs/` tree (placement)*, *how a docs change flows through it*, and *what makes a feature/system closeout "done" in the docs*. **Rationale / derivation:** `docs/policies/DOCS_OPERATING_MODEL.md` (change/closeout why + record) and `docs/README.md` (docs-tree orientation / placement map + rationale) — the rules below are the binding active-surface form (per the root *Final hard rule*), not a restatement of those records. Per-question routing (`docs/current/REPO_READING_GUIDE.md`) is a separate orientation surface this rule does not redefine.

Read this rule **before** changing `docs/` content or closing out work; the root `CLAUDE.md` / `AGENTS.md` *Docs trigger map* (`Source / docs` row) wires that trigger. The file existing is not what makes it apply — it applies because the root instruction files trigger it.

> **Package note.** This file is the operative home of the `rules/docs-working-model` rule package (`rules/docs-working-model/`). The package now carries a `templates/` set (Design / Plan / Spec — `templates/docs-working-model_design_template.md` / `_plan_template.md` / `_spec_template.md`) and a `checklists/` set (Design / Plan / Spec conformance + closeout — `checklists/docs-working-model_design_checklist.md` / `_plan_checklist.md` / `_spec_checklist.md` / `_closeout_checklist.md`), and the Design / Plan / Spec lifecycle rules are incorporated below. With this the package is **operationally complete (Batch A package transition + Batch B templates/checklists introduction)**. Package entry / routing is via `rules/README.md`; the package-internal templates / checklists are routed from *Template / checklist conformance gate* below. (Applying the model to a first domain, and any later residue cleanup, are separate follow-on work and are not implied by this completion.)

## When this rule applies

- Any task that **places, moves, changes, or closes out** `docs/` content.
- Any task that produces or revises a repo document / normative artifact through the **Design → Plan → Spec lifecycle** (below) — authoring a Design / Plan / Spec, closing one out, or retiring an absorbed Design / Plan.
- It governs docs **placement and the change/closeout process**. It does not re-decide per-question routing (→ `docs/current/REPO_READING_GUIDE.md`, an orientation surface).

## Top-down operating model

A docs change is decided from the top-level structure downward, never bottom-up from whichever file the work happened to touch:

1. **Structure first.** Before adding or moving content, confirm placement (see *Docs placement* below; the folder map is `docs/README.md` §5). New always-on rules do not go in `docs/`; they go in `snippets/**` / the managed block, or — for repo-only rules — the repo-local root `CLAUDE.md` / `AGENTS.md` and the `rules/**` they point to.
2. **Authority next.** Confirm which layer *owns* the fact you are changing (its single home — see *single-home-plus-pointers*).
3. **Down into current + per-system.** Propagate the change into the layers whose role is affected — `docs/current/` for question→read-first routing, and the relevant `docs/systems/<system>/` files for subsystem state. Project-current *state* is answered on demand (see *On-demand status-briefing model*), not mirrored in a committed file.
4. **Closeout gate last.** When the change closes out work, run the two-level closeout reconciliation (below) before declaring the docs closeout complete.

**single-home-plus-pointers.** Every fact has exactly one authoritative home; all other mentions are pointers to it, never copies. Prefer one authoritative statement plus pointers over repeated prose. (Why duplication is the staleness engine: `docs/policies/DOCS_OPERATING_MODEL.md` §1.)

## Doc-vs-doc precedence

- On **placement**, this rule's *Docs placement* section is the operative home; `docs/README.md` is its orientation map / rationale, not a competing authority.
- On an **artifact's shape**, the relevant `docs/contracts/**` contract is the specification of record and the operative authority is the **active surface** (the verifier scripts / templates / skill the contract records) — neither doc outranks the active surface.
- On the docs **change/closeout process**, this rule is the home.

## Docs placement

Where a doc belongs in the `docs/` tree (the orientation map / rationale for these rules is `docs/README.md`):

- **docs root holds only `README.md`.** No other markdown lives at `docs/` root (this applies to the `docs/` folder only — not the repo-root `README.md` or `INSTALL.md`).
- **A folder is a scope boundary, not a storage bucket.** Markdown in one folder must be interpretable, read together, under one purpose. Create a new folder only to narrow scope — not to mix unrelated scope, and not merely because the taxonomy looks complete.
- **Structure follows access pattern** (how a doc is read, not how many topics it touches): always-on/priming rules that apply to *every* task consolidate **outside** `docs/` (the snippet / managed block, or the repo-local root `CLAUDE.md` / `AGENTS.md` + the `rules/**` they point to) — there is no `docs/priming/`; task-scoped/lookup docs partition so opening one task's folder does not drag in unrelated scope (anti-mixing); always-read or tightly-coupled material is not scattered into a dense reference web (anti-fragmentation).
- **Where a new doc belongs** — ask in order: (1) always-on for every task? → an always-on surface outside `docs/`. (2) otherwise, which single access pattern / scope does it serve? → that layer (`docs/README.md` §5). (3) would co-locating it pull unrelated scope into a task search? → partition. (4) would splitting it create a dense reference chain? → keep consolidated. Never create an empty folder in advance.
- **What not to do:** do not place artifact contracts under `policies/`; do not put task-scoped / conditional policy into always-on priming; do not leave any markdown at `docs/` root except `README.md`; do not preserve a location merely because it was recently committed or heavily referenced.
- **Reference-update-on-move:** moving or splitting a doc requires updating every inbound reference (in `docs/**`, `README.md`, and — path-only — protected root files when they reference the moved path); a document's section anchors referenced elsewhere must be preserved or explicitly remapped.

## Layer shape constraints (must-not-absorb)

A closeout must not let a layer absorb what it must not become:

- `docs/current/` — `REPO_READING_GUIDE.md` only (question→read-first routing). Must not become a second status ledger, a roadmap, a closeout diary, an incident log, or a committed active-action / project-state mirror.
- `docs/systems/*/STATUS.md` — must not become an incident-narrative / dogfood-transcript / build-diary store, a full closeout report, an implementation plan, or a design contract (those are pointed to, not inlined).
- `docs/systems/*/BACKLOG.md` — must not become a second status/archive surface (see the tombstone rule).
- `docs/systems/*/DEFERRED.md` — an item without a reopen condition is not deferred (it is backlog, archive, or delete-candidate). Must not duplicate BACKLOG or store closed items.
- `docs/roadmap/` — must not hold decision/design/planning bodies or redefine the order (order authority = `docs/decisions/POST_MVP_PLAN.md` §11).
- `docs/backlog/` — must not hold item bodies (routing/classification index only).
- `docs/decisions/` — must not become a current-status surface (status → `docs/systems/**`).

## Per-system STATUS.md shape / altitude

A `STATUS.md` answers exactly one question: the subsystem's current operational posture and where the authoritative details are. It is written at decision altitude (what the subsystem *is*), not build-diary altitude (how it got there). Reference shape: `docs/systems/review/STATUS.md` and `docs/systems/brief/STATUS.md`. New or revised STATUS content conforms to that shape, not a longer journal form.

**Belongs in STATUS.md:**
- Current state / posture — compact bullets.
- Authoritative contract / model pointers.
- A compact completed-ledger table — columns: ID / item / closed-at / current meaning / detail-pointer; one row per closed item (the row is a summary, the detail lives behind the pointer).
- Accepted residual risks carried into maintenance, each with a reopen pointer.
- Explicit non-claims where a closeout could be over-read.
- Maintenance posture.
- Pointers to BACKLOG / DEFERRED / design.

**Does NOT belong in STATUS.md (point to it instead):**
- Open backlog item bodies (→ BACKLOG.md).
- Deferred item bodies already in DEFERRED.md.
- Long incident / root-cause narratives, full closeout reports, dogfood / retest transcripts (not maintained as current docs — git history is the preservation mechanism).
- Implementation plans, design contracts (→ their authority doc).
- Multi-paragraph reconciliation essays (record the supersession as a one-line ledger/pointer change, not an essay).

**Durable-pointer prohibition.** A committed doc must never use a durable pointer to a gitignored / local / scratch / runtime path (`log/**`, `polishing/**`, `repo_snapshot/**`, repo-sibling artifacts, runtime evidence, user/global files); durable pointers resolve only to git-tracked files or git commit/history. Externalized historical detail is preserved by git history, not by a durable sink — if a past decision is still operationally relevant, the active doc states the decision directly (derived from current implemented behavior and current git-tracked docs).

**Altitude ceiling.** If a current-state bullet has grown into multiple paragraphs of history, the narrative moves behind a pointer and the bullet shrinks to current posture. This shape governs **new and revised** STATUS content; it does not by itself authorize a retroactive rewrite of any existing STATUS doc (that is a separate scoped batch).

## BACKLOG.md closed-row tombstone

When a backlog row closes:
- The authoritative closed record moves to the subsystem `STATUS.md` completed ledger (compact row); any long narrative is not migrated into current docs — git history preserves it.
- In `BACKLOG.md` the row is reduced to a one-line tombstone for ID continuity: `**[CLOSED]** <ID> — <one-line outcome>; see STATUS ledger <ID>.`
- A `**[RETIRED]**` row (closed by a not-doing decision) uses the same one-line tombstone form with a pointer to where the retirement rationale lives.
- A tombstone carries no closeout/incident narrative.

This rule does not retroactively tombstone existing closed rows (that is a separate scoped batch).

## On-demand status-briefing model

There is **no committed project-current mirror file** — no committed active queue and no committed project-current summary. "What is done / what remains / what should I do next" is answered **on demand** by the agent, not maintained as a committed summary that goes stale between closeouts.

When asked, the agent:
1. **Reads the authoritative surfaces** — per-system `docs/systems/*/STATUS.md` completed-ledgers + current-state/LTS sections (done), `docs/systems/*/BACKLOG.md` (open, via `docs/backlog/INDEX.md`), `docs/systems/*/DEFERRED.md` (postponed + reopen conditions), and `docs/roadmap/CURRENT_MILESTONES.md` ↔ `docs/decisions/POST_MVP_PLAN.md` §11 (numbered remaining order); plus the canonical Brief as runtime restore evidence when present.
2. **Synthesizes a conversational briefing** at the altitude asked for (whole-project or one subsystem).
3. **The user selects the next task conversationally.** No project-current mirror is written.

The single home of "what remains" is the per-system STATUS/BACKLOG/DEFERRED + roadmap/decisions surfaces; the single home of "the currently selected action" is the conversation + the canonical Brief.

## Closeout reconciliation — two-level gate

A feature/system closeout is **not "done" in the docs** until **both** levels below pass. Both are mandatory; the listing order is the verification order (orient from the top first), not a priority ranking — the system-local edits are usually written first, then verified upward.

**Level 1 — project-current / upward impact check (top-down).** Check, and reconcile if affected, the top-level orientation surfaces a new reader hits first — only when their authority / routing / order actually changes:
- `docs/current/REPO_READING_GUIDE.md` — did any question's authoritative home change (including how "current progress / next action" routes)?
- `docs/roadmap/CURRENT_MILESTONES.md` — did a numbered-milestone status change?
- `docs/decisions/POST_MVP_PLAN.md` — only if the numbered-order authority itself changed.

**Level 2 — system-local impact check.** Check, and reconcile if affected, the subsystem's own surfaces:
- `docs/systems/<system>/STATUS.md` — completed-ledger row added; current-state posture updated; accepted-residual-risk / non-claim updated; intra-system supersessions recorded as one-line ledger/pointer changes.
- `docs/systems/<system>/BACKLOG.md` — closed row tombstoned.
- `docs/systems/<system>/DEFERRED.md` — updated only if a reopen condition changed or an item resolved.
- Any subsystem design/contract pointer that the closeout invalidated.

**Inspect-all, report-each.** For every doc listed in Level 1 and Level 2, the closeout report must state one of:
- `updated: <file> — <what changed>`, or
- `checked: no change required — <file>`.

Silently skipping a listed doc is a gate failure — a doc that was never mentioned is indistinguishable from a doc that was forgotten. (Why both levels exist: `docs/policies/DOCS_OPERATING_MODEL.md` §7.)

## Scope of an application + review gate

- This rule defines the docs change/closeout **process**; applying it to any specific surface is its own scoped batch. It does not restructure folders, move/archive existing narrative, or collapse routing layers — those need their own scoped decisions governed by `docs/README.md`.
- It does **not** approve any commit / push / publish / merge / release, or any global/user filesystem mutation.
- Any source/doc change governed by this model goes through the normal Codex review gate (`scripts/review-prepare.ps1` → `scripts/review-run.ps1` → `scripts/review-verify.ps1 -RequireResult`, or the equivalent `ai-harness-review` skill). A verdict (`yes` / `no` / `yes with risk`) does not auto-approve commit / push / publish / merge / release / adoption.

## Design / Plan / Spec lifecycle

A repo document / normative change is produced through a fixed lifecycle, not authored ad hoc:

```text
live Spec + live Implementation → 변경 필요 → Design → Plan → Spec
  → Implementation (final Spec only) → closeout sync
  → Design/Plan 의 current-bearing 내용 Spec 흡수 → Design/Plan retire
  → Spec live · Implementation live
```

- **Design** — why / what / owner-surface model / non-goals / which live Spec or implementation it modifies. Not permanently live.
- **Plan** — decomposes the Design into batches / scope / hard boundaries / validation / review gate.
- **Spec** — implementation boundary / allowed-forbidden active-surface changes / validation + review criteria / reconstructibility. Live after closeout.
- **Implementation** — built from the **final Spec only** (no direct Design/Plan reference, no separate document); at closeout the Spec and the implementation are reconciled 1:1.

The package-local templates and checklists for these stages live under this package's `templates/` and `checklists/` (see *Template / checklist conformance gate*).

## Stage rewind

- **Plan violates the Design** → stop, redesign the Design, restart the Plan.
- **Spec violates the Plan** → stop, re-plan, restart the Spec.
- **Implementation exceeds the Spec boundary** → stop and ask the user; do not silently widen scope.

## Lifecycle closeout — absorption and retire

This is the lifecycle-artifact closeout. It is a different dimension from *Closeout reconciliation — two-level gate* (which reconciles a docs-tree change top-down across orientation and per-system surfaces); the two govern different closeout aspects and neither restates the other. A Design/Plan/Spec lifecycle closeout is not done until **all** hold:

- Spec ↔ implementation reconciled 1:1.
- Every current-bearing Design decision is expressed in the Spec (or the correct owner surface).
- Every still-relevant Plan batch/boundary decision is expressed in the Spec (or owner).
- No unique live meaning remains only in the Design or Plan.
- Inbound references are updated / removed.
- The Design and Plan can be **retired** — retire is **deletion** (repo lifecycle); non-current historical detail is preserved by **git history**, never by an archive / `consumed/` folder.

## Stable filename rule

- Design / Plan / Spec for a domain use **domain-prefixed role filenames**: `<domain>_design.md` / `<domain>_plan.md` / `<domain>_spec.md`. Re-creating after deletion reuses the same role filename. Forbidden: `<topic>_*.md` topic-named files, filename-evading subfolder splitting, per-feature design/plan/spec proliferation inside one domain.
- Auxiliary role docs (`_policy` / `_contract` / `_state` / `_status` / `_guide`) are **deferred** — not created by default; introduced only by an explicit Design/Plan decision.
- **Package-local form vs domain form.** This package's own `templates/` / `checklists/` files carry the package-name prefix `docs-working-model_` and the `_template` / `_checklist` role suffix, marking them as **forms used to produce another domain's** Design/Plan/Spec — they are not themselves a domain's Design/Plan/Spec. So `docs-working-model_spec_template.md` (a form) is a different kind from a future `<domain>_spec.md` (an actual Spec); the former produces the latter.

## Domain-local closure and top-down reference

- **Domain-local closure** — each domain document is understandable from its own folder + its own live Spec + its own active surface + the stable interfaces it explicitly depends on. If understanding it requires reading another domain's semantics, the Spec has failed.
- **Top-down reference** — root `README.md` → `rules/README.md` → this rule package → a classification / domain index (when needed) → a domain Spec. A lower layer does not complete its meaning by holding a durable pointer up to a routing document (no backlink); it may identify its own scope/owner, but must close without its parent.

## Cross-domain semantics restriction

- Domain↔domain **semantics** references are forbidden by default. Narrowly allowed: a stable path / interface, schema, contract boundary, marker / payload-root / lifecycle boundary, or a domain whose essence is a cross-domain mechanism (install-update) — and even then only the **interface**, never a restatement of the other domain's semantics.
- Test: "if the target domain's implementation changes, does this reference change too?" yes = semantics (forbidden); no = interface (allowed).

## Template / checklist conformance gate

- Each produced Design / Plan / Spec must pass its corresponding checklist, and a lifecycle closeout must pass the closeout checklist. Conformance is recorded as "present / absent + one-line evidence", not enforced prose.
- This package's lifecycle forms live package-internally: templates at `templates/docs-working-model_design_template.md` / `_plan_template.md` / `_spec_template.md`, and checklists at `checklists/docs-working-model_design_checklist.md` / `_plan_checklist.md` / `_spec_checklist.md` / `_closeout_checklist.md`. `rules/README.md` routes to this package; this operative home routes to those forms.
- A produced Spec is **not itself operative authority** over the active surface it specifies — the active surface owns behavior (root *Final hard rule*); the Spec specifies it and is reconciled against it.

## Tier note

This is a repo-development rule for this repo only; it is **not** adopter-universal and **not** part of the global distribution (an adopter project may use a different docs authority model). It is not duplicated into `snippets/rules/`. Its rationale, removal record, and role-of-layers orientation live in `docs/policies/DOCS_OPERATING_MODEL.md`.
