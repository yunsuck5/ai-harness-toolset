# Rule: Project terminology glossary

This file is the **single, self-contained home of project term meaning** for developing the `ai-harness-toolset` repository. It is a flat repo-only rule in the repo-only rules tier — a sibling of `powershell-and-file-encoding.md`, routed read-first from the root `CLAUDE.md` / `AGENTS.md` *Docs trigger map* (`Project terminology` row) and listed in `rules/README.md`. **This file is itself the terminology source** — a repo worker learns what a project term means by reading this file alone, and never needs to read any external or out-of-repo document to know a term's meaning here; the file carries **no durable pointer** to any out-of-repo workspace. It is **not** adopter-universal — it is not shipped under `snippets/rules/` and is never installed to an adopter's `<ToolRoot>`. It is **not** a `rules/docs-working-model` package-local file — terminology is a cross-cutting concern across docs / spec / review / brief / planning, outside that package's domain-local closure.

## How to use this glossary

- This is the **single home** of what a project term means. When a term defined here appears in any docs / spec / rule / review / brief / planning work, use it consistently and do **not** re-explain an **accepted** term in local prose — if a reader needs the meaning, route them here instead of copying the definition.
- A **pending / owner-pending** term is *candidate vocabulary*, not settled. Do not use it as if it were final; it closes only in its named owner domain under its named close condition.
- A **rejected** term is not adopted. Do not revive a rejected term under a new name or as an accepted-looking heading anywhere outside the `## Rejected terms` section.
- One root word may carry **two distinct facets** in two different states, each a separate entry. A facet naming a *specific sub-question* may be pending while the same root word *as a broad domain* is rejected — e.g. `instruction-surface mechanism location` (pending) vs the broad-domain facet (rejected, in the Rejected section). The single-state rule applies per exact term/facet, not per root word; each entry states its facet to avoid confusion.
- This glossary records meaning and classification **only**. It grants **no mutation, commit, or push approval**, and no review verdict — those remain separate explicit user approvals. It does **not** weaken the `INSTALL.md` self-contained install / update / uninstall operative contract, and it does not own any other system's semantics.

## Status vocabulary

- **accepted (stable / operative)** — a settled term; used consistently as defined.
- **accepted with owner boundary** — settled, but carrying an application boundary (which owner surface's self-contained re-explanation it must not weaken).
- **pending / owner-pending** — candidate vocabulary, not final; closed only by its owner domain under a stated close condition.
- **rejected** — not adopted (typically a broad mixed-owner domain / bucket); must not be revived under another name.

## Accepted terms

Each definition is a complete one-line meaning, self-contained in this file. Where a term also names an operative *procedure* that has its own home rule (e.g. the docs-working-model rule), the division of labor is: **the term's meaning lives here; the operative procedure lives in that rule.** This entry states the meaning and names that rule so a reader can find the procedure; it does not duplicate the rule's body, and a reader does not need that rule to understand what the term *means*.

- **`Design`** — the lifecycle artifact stating why / what / the owner-surface model / non-goals / which live Spec or implementation it modifies; not permanently live (retired after closeout).
- **`Plan`** — decomposes a Design into batch order / scope / hard boundaries / validation expectations / review focus / Work Packet declarations — **approval-target decisions only**, never a work memo (round-scoped analysis / investigation / classification belongs in a Work Packet; execution mechanics / records belong in operator reports under `log/**`).
- **`Spec`** — the domain's **target-state specification**: target state (normative sentences) + owner-surface map + durable boundary + validation expectation + review focus. At writing completion it is the blueprint of the target state; after closeout it is the live specification 1:1-synchronized with the implementation at the normative-sentence level.
- **`Implementation`** — built from the final Spec only; reconciled 1:1 with the Spec at closeout.
- **`final Spec only`** — an implementation references the closed final Spec alone, never the Design / Plan directly and never a separate document.
- **`stage rewind`** — when a lower lifecycle stage violates the stage above it, stop and restart from the higher stage (Plan violates Design → redesign; Spec violates Plan → re-plan; Implementation exceeds the Spec boundary → stop and ask the user, never silently widen scope).
- **`owner surface`** — the active surface that actually defines a behavior (script / test / template / snippet / skill / `config` / root instruction / `rules`), as opposed to a `docs/**` page that only describes it.
- **`source-of-truth` (single home)** — every fact has exactly one authoritative home; every other mention is a pointer to it, never a copy.
- **`stable filename rule`** — domain documents use domain-prefixed role filenames (`<domain>_design.md` / `_plan.md` / `_spec.md` / `_backlog.md` / `_work_packet.md`), reused after deletion; topic-named files and filename-evading subfolder splitting are forbidden. Operative home: `rules/docs-working-model/docs-working-model.md`.
- **`Work Packet`** — a round-scoped, non-approval-target temporary work document (line-level reference classification, investigation notes, implementation notes, evidence proposals, reviewer-question preparation; execution mechanics / records are forbidden in it and belong to operator reports under `log/**`) living at `docs/<domain>/<domain>_work_packet.md` as a **committed temporary document**; not a live document, absorbed into the Spec / owner surface / closeout report at closeout, then deleted (preservation = git history). Operative home: `rules/docs-working-model/docs-working-model.md`.
- **`sync-required`** — the domain state after a live Spec has been updated in place to a new target state but before implementation closeout re-establishes the 1:1 sync (marked in the Spec's lifecycle-state section).
- **`future-work queue`** — the fifth document artifact class: a per-domain `<domain>_backlog.md` whose items are one line + a reopen/start condition, with a monotonically increasing `next ID` header line; closed rows are deleted by default (git history preserves them).
- **`proportionality rule`** — edits that preserve normative meaning (typos, stale pointers, wording cleanup) may be applied directly under the normal review gate, with a meaning-preserving change description; any normative-meaning change (boundary / behavior / owner mapping / validation expectation) requires the full Design→Plan→Spec lifecycle. Operative home: `rules/docs-working-model/docs-working-model.md`.
- **`domain-local closure`** — a domain document is understandable from its own folder + its own live Spec + its own active surface + the stable interfaces it explicitly depends on; needing another domain's semantics to understand it is a failure.
- **`top-down reference`** — references flow downward (root `README.md` → `rules/README.md` → a rule package → a classification / domain index → a domain Spec); a lower layer does not complete its meaning with a durable backlink up to a routing document.
- **`owner absorption proof`** — before retiring a Design / Plan, every current-bearing decision is shown to be expressed in the Spec (or the correct owner surface), so no unique live meaning remains only in the Design / Plan.
- **`4-class reference sweep`** — before and after a mutation, sweep references in four classes (filename / path, bare-token / ID, folder-as-bucket, semantic-phrasing) to confirm no stale or wrong reference remains.
- **`corrected-state Codex review`** — the Codex review is run on the corrected working tree (after fixes), not on the pre-fix state; a later source / doc / rules edit makes the review stale and forces a re-run.
- **`mutation approval`** — explicit user approval to apply a repo file change. A Spec, this glossary, and a review verdict each grant none of it.
- **`commit / push approval`** — commit approval and push approval are each a separate explicit approval, distinct from mutation approval and from each other.
- **`package-local template / checklist`** — a form (template / checklist) carrying a package-name prefix plus a `_template` / `_checklist` role suffix, used to produce another domain's Design / Plan / Spec; it is a form, not a domain's own artifact.
- **`external workspace baseline`** — a classification for out-of-repo, pinned, read-only material the repo may consult as **advisory** input (e.g. restore / handoff / planning material). It is **not** a repo terminology dependency — project term meaning is self-contained in this file, not derived from such material — and the repo never references it by a durable pointer.
- **`checkpoint`** — an explicit-prompt save of a recoverable progress point in the Brief workflow (the save / checkpoint trigger family). Owner = brief (`docs/brief/brief_spec.md`); closed in the brief pilot.
- **`restore point`** — the saved point an explicit, user-requested Brief restore resumes from (the restore-summary + confirm step of the Brief workflow). Owner = brief (`docs/brief/brief_spec.md`); closed in the brief pilot.

## Accepted terms with owner boundary

- **`INSTALL.md as protected root-level self-contained install / update / uninstall operative contract`** — `INSTALL.md` is the self-contained operative contract for install / update / uninstall; this glossary and the `rules/**` tier must not pointerize it, treat it as a docs-cleanup target, or move its execution contract elsewhere. Its intentional in-context re-explanation of invariants is deliberate, not stale duplication.
- **`contextual duplication`** — an *intended* in-context restatement of an invariant (e.g. `INSTALL.md` re-explaining a hard boundary so it stays self-contained); deliberate, and not treated as stale duplication to be removed.
- **`brief owner surface`** — the brief system owns its own semantics; other surfaces reference its interface, not its semantics.
- **`review owner surface`** — the review system owns its own semantics; other surfaces reference its interface, not its semantics.
- **`install-update interface vs semantics`** — a cross-domain mention inside install-update docs keeps the *interface* (stable path / boundary) and routes *semantics* back to the owner domain. Test: if the owner's implementation changes, does the reference change too? yes = semantics (route to owner); no = interface (may stay).

## Pending / owner-pending terms

Candidate vocabulary only — each entry names its owner domain and its close condition; nothing here is finalized. This batch *classifies* these terms; it does **not** rewrite their existing repo usage — that is each owner domain's work.

- **`instruction-surface mechanism location`** — candidate (where the live instruction-surface mechanism is specified). Owner = **architecture / instruction-surface** follow-on work; close = after owner absorption in that work. *(Facet note: this is the pending sub-question facet; the broad-domain facet is rejected — see Rejected terms.)*
- **`concrete-path value vs normative boundary`** — candidate (whether a concrete path is itself the value or only a normative boundary). Owner = the **`snippets/rules/` concrete-path audit** (a separate scoped audit); close = that audit's decision. Carried over until that audit closes.

## Rejected terms

Not adopted — typically a broad mixed-owner domain / bucket with no proven narrow owner / lifecycle / domain-local closure. Each entry: what it is + why rejected + do-not-revive-as. Rejected terms appear as headings **only** within this section.

### instruction-surface as independent domain
A broad standalone "instruction-surface" domain/bucket. Rejected: it mixes owners and proves no narrow owner / lifecycle / closure. Do not revive it as an independent domain under another name. (The narrow pending facet `instruction-surface mechanism location` is a separate entry.)

### global-invocation as independent domain
A broad standalone "global-invocation" domain. Rejected for the same broad-bucket reason. Do not revive as an independent domain. (The narrow facet `global-invocation single-home` has since **closed** in the install-update domain migration — the single home is the install-update domain spec.)

### evidence umbrella as independent domain
A broad "evidence" umbrella domain / system / shared contract. Rejected as a broad bucket. Do not revive evidence as a domain / system / shared contract. (Narrow pending facet: `evidence contract absorption`.)

### managed-block as independent domain
A standalone "managed-block" domain. Rejected: the managed block is a marker / payload boundary owned by the install and instruction surfaces, not its own domain. Do not revive it as a domain.

### manifest as broad domain
"manifest" as a broad domain. Rejected: no broad-domain owner or lifecycle. Do not revive it as a broad domain.

### packaging as broad owner
"packaging" as a broad owner concept. Rejected: this toolset is not packaged. Do not revive packaging as a broad owner.

### project folder as broad owner
A `docs/project/`-style folder kept as a long-term broad owner. Rejected: do not preserve a project folder as a long-term broad owner.

### handoff/snapshot as repo feature domain
"handoff / snapshot" elevated into a repo feature domain. Rejected: there is no handoff/snapshot repo feature domain. Do not revive it as one. (The `handoff` *wording* was separately closed in the brief pilot as **not adopted as canonical brief vocabulary** — it survives only as a trigger synonym in the brief skill's example phrases. `continuation` was likewise **not adopted** as a project term in the same close — it remains free ordinary wording with no glossary entry.)

### docs/domains broad taxonomy
A broad `docs/domains/` taxonomy. Rejected when it would revive bucket sprawl (a folder used as a storage bucket rather than a scope boundary). Do not recreate a broad docs taxonomy that revives bucket sprawl.

### architecture broad bucket as long-term owner
A `docs/architecture/`-style broad mixed-owner classification kept as a long-term owner. Rejected **as a long-term broad mixed-owner bucket** — but this is a boundary, **not** an immediate delete approval. A narrow architecture domain is allowed only when it proves a narrow owner, lifecycle, domain-local closure, reference model, and active-surface relationship; any such absorption is handled separately and owner-absorption-gated.

### repo consumed/ archive lifecycle
A repo `consumed/` folder or a separate archive folder used as a retire lifecycle. Rejected: retire = deletion, with git history as the preservation mechanism. Do not revive a separate archive / `consumed/` folder as a repo pattern.

## Term ownership and close conditions

- **Accepted** terms have no open owner action — they are used consistently as defined above.
- **Accepted-with-owner-boundary** terms stay within their stated boundary; the owner surface (`INSTALL.md`, brief, review, install-update) keeps its own self-contained semantics and this glossary does not override it.
- **Pending / owner-pending** terms close only in their named owner domain under their named close condition: `instruction-surface mechanism location` closes in its later owner work after absorption; `concrete-path value vs normative boundary` closes in the separate `snippets/rules/` concrete-path audit. (The formerly-pending install-update-owned entries closed in the install-update domain migration: `global-invocation single-home` **closed** — the single home is the install-update domain spec `docs/install-update/install-update_spec.md`, with no separate contract-document role; `run diagnostics` **not adopted** — no project-term entry and no rename mandate, `INSTALL.md` operative wording stays as-is.) (The formerly-pending brief-owned wording closed in the brief pilot: `checkpoint` / `restore point` accepted above; `continuation` not adopted; `handoff` not adopted as canonical — see the Rejected `handoff/snapshot` entry's note. The formerly-pending review-owned entries closed in the review domain migration: `review-support naming` **not adopted** — the canonical names are owned by the artifact layout and scripts, and no live usage required an umbrella term; `evidence contract absorption` **closed** by absorbing the evidence file-format convention into the review domain spec (`docs/review/review_spec.md`) while the generic `log/` footprint stays an install-update interface — the rejected evidence-umbrella entry stands unchanged.)
- This glossary records classification and close conditions only. It does **not** rewrite the existing repo usage of any pending token (`run diagnostics` / …) — that wording cleanup belongs to each owner domain, not to this glossary.

## Do-not-repeat rule

- An **accepted** term is defined once, here. Other docs / spec / rules / skills use the term consistently and, if a reader needs its meaning, route to this glossary instead of re-explaining it. Repeated prose definitions of the same accepted term are the staleness engine this rule exists to prevent.
- This glossary does **not** duplicate an operative rule that already has a home (e.g. the `stable filename rule` body lives in `rules/docs-working-model/docs-working-model.md`); it gives the one-line meaning and points to that home.
- A **rejected** umbrella term must not reappear as an accepted-looking heading or a renamed synonym outside the `## Rejected terms` section. A **pending** term must not be written as if final.
- This glossary is route-only authority for *meaning*. It confers no mutation / commit / push approval and weakens no owner surface's self-contained contract (notably `INSTALL.md`).
