# Rule: Documentation working model (repo-only)

This rule owns the repository's document artifact roles, Design → Plan → Spec / terminal-rule lifecycle, placement, synchronization, and closeout. It is self-contained and does not delegate active meaning to `docs/**`.

Read it before changing DWM-owned normative meaning, document placement, lifecycle, or closeout behavior. Ordinary read-only inspection and non-authoritative reporting do not invoke it.

> **Package.** The rule package includes `templates/` for Design / Plan / Spec and `checklists/` for Design / Plan / Spec / Work Packet / closeout / promotion. The forms are authoring and self-review aids; this rule remains their semantic owner.

## Document artifact roles

Every repo document has a primary role. The five roles are an ownership taxonomy, not a closed filename test: a file is defective when it claims competing authority or incompatible lifecycle, not merely because it carries a local pointer or short contextual summary.

1. **Planning artifact** — Design / Plan / Spec. Only the closeout-reconciled Spec stays live.
2. **Temporary work artifact** — committed-temporary Design / Plan / Work Packet / `_incubation` content, deleted at its applicable closeout and preserved by git history.
3. **Operator report / evidence** — execution, review, validation, and point-in-time state under `<ProjectRoot>/log/**`.
4. **Active implementation surface** — scripts, skills, snippets, templates, config, tests, root instructions, and `rules/**`. Behavior is owned here, never by a narrative `docs/**` page.
5. **Future-work queue** — non-authoritative domain/rule backlog for not-yet-started work.

## End-state placement and transition

The `docs/` end-state is:

```text
docs/
  README.md
  <domain>/
    <domain>_spec.md
    <domain>_backlog.md
    <domain>_design.md
    <domain>_plan.md
    <domain>_work_packet.md
```

- Migration is per-domain only; this declaration creates no project-wide mutation.
- A new decision resolves conflicts toward this end-state in that domain's scoped batch.
- A retirement-bound legacy structure receives no new authoritative meaning. Meaning-preserving correction and maintenance of a current user path remain allowed until migration.
- `docs/README.md` is the single home for new orientation/routing. Unmigrated routing residue may continue serving its existing path but does not grow new authority.

### Single home and durable pointers

A normative fact or decision has one authoritative home. Other surfaces may carry pointers, interface summaries, examples, or local acceptance criteria so long as they do not become an independent authoritative copy. If two mentions must change together to preserve one decision, one is normally not a second home.

A committed document does not durably point to gitignored/local/runtime paths such as `log/**`, `polishing/**`, repo-sibling scratch, or user/global files. Durable pointers resolve to tracked files or git history. Path-class explanations are allowed.

## Design → Plan → Spec / terminal-rule lifecycle

A durable normative change follows:

```text
live Spec + implementation → Design → Plan → target-state Spec/rule
  → optional Work Packet → implementation → closeout sync
  → Design/Plan/Work Packet retire → Spec/rule + implementation live
```

A rule is its own spec-of-record and therefore has no duplicate rule Spec.

### Altitude and approval ownership

- Direction rationale, conceptual model, chosen trade-offs, ownership boundary, non-goals, and semantic target belong in **Design**.
- Approval-target batch order, scope, boundaries, validation, and decision close points belong in **Plan**.
- Round-scoped investigation and implementation notes belong in **Work Packet**.
- Durable target-state wording belongs in the **Spec** or terminal rule.

A defect exists when lower-altitude detail pre-decides an approval choice, an approval decision is hidden in a Work Packet, or duplicate current-bearing meaning competes with its owner. Decision-critical identifiers, representative boundary examples, and short explanations needed to understand an artifact are allowed.

Decision-shaped grammar alone is not an approval defect. A lower artifact is defective only when it makes a new decision, changes an approved decision, or treats its own wording as approval. Explicitly tracing an approved decision is allowed.

### Artifact identities

- **Design** — why / what / owner model / trade-offs / non-goals / semantic target. It becomes defective when it pre-decides Plan choices or reproduces exhaustive round/line inventory.
- **Plan** — approval-target batches / scope / hard boundaries / validation / review focus / Work Packet declaration / open-decision close points. Investigation or execution detail is defective when it substitutes for the approval decision.
- **Spec** — durable target-state specification. It becomes live only after closeout.
- **Implementation** — built from the final Spec or terminal rule. A Work Packet may assist but never substitutes for the target-state owner.

## Spec identity

A domain Spec is:

- **`prelive`** after its first target-state writing and before first closeout;
- **`sync-required`** when a previously-live Spec has been updated and implementation is catching up;
- **`live`** after closeout reconciliation.

Exactly one bolded lifecycle marker appears in the Spec's Lifecycle state meaning area. A `prelive` Spec is governance-discoverable but is not closeout-verified implementation authority.

A Spec carries eight meaning areas: Header, 목표 상태, Owner surface 지도, Durable boundary, Cross-domain interface, Validation expectation, Review focus, and Lifecycle state. The package template presents these as eight headings for consistent authoring, but heading count is a form diagnostic rather than an independent lifecycle blocker. Durable target-state meaning and exactly one lifecycle marker remain required.

A Spec does not carry round-scoped file inventories, execution/staging procedures, review results, readiness judgments, or point-in-time work status beyond compact lifecycle markers. It does not copy backlog IDs or next-ID allocation; a terminal rule likewise does not copy its rule backlog inventory.

## Work Packet

A Work Packet is a round-scoped, non-authoritative temporary artifact for line-level classification, investigation, implementation notes, evidence proposals, reviewer-question preparation, and edge cases.

- It is not an approval target, live document, or Spec/rule substitute.
- It does not carry command sequences, staging procedures, review/validation results, or readiness judgments.
- Its normal path is `docs/<domain>/<domain>_work_packet.md` or `rule_docs/<id>/<id>_work_packet.md`; subfolder lifecycle evasion is not allowed.
- A Plan declares its purpose, absorption target, and retire condition.
- At promoted-lifecycle closeout, current-bearing content is absorbed into the correct owner/report and the Work Packet is deleted.
- The regular lifecycle, including its optional Work Packet role, begins at Design; before then `_incubation.md` is the candidate's planning home.

## Incubation (pre-promotion)

A candidate is a possible domain or rule that the user is still deciding whether to promote. Incubation gives that thought one tracked, non-authoritative home without turning early notes into a domain, rule, or approval.

1. **Identity and authority.** The only mandatory authored content is enough identity to say what candidate is being registered. Problem statement, shape, owner, review date, discard criteria, headings, and template fields are optional aids. The document's only positive authority is the user's intent to register a candidate; it grants no implementation or canonical authority.
2. **Light duplicate check.** While writing or discussing a candidate, compare it in-session with existing domain/rule names; repeat that short comparison before commit. A complete duplicate is not registered. A partial overlap is reported to the user as a soft ownership question. No registry, scanner, or separate review ceremony is created.
3. **Single home and freedom wall.** A domain candidate uses `docs/<candidate>/<candidate>_incubation.md`; a rule candidate uses `rule_docs/<candidate>/<candidate>_incubation.md`. It is the free-form planning home before the regular lifecycle begins at Design; no mandatory header or `_design` / `_plan` / `_spec` sibling is created during incubation.
4. **Lifecycle.** Incubation starts as free notes and may be revised without the regular lifecycle. On promotion, the entry Design absorbs the identity and current-bearing ideas that actually survive; raw logs, abandoned thoughts, and a closed evidence-field list need not be carried. The promotion changeset removes/renames `_incubation.md` and creates `_design.md`. The regular lifecycle applies from Design onward. On discard, the incubation file is deleted; a discarded rule candidate's empty folder is removed.
5. **Commit and review boundary.** Incubation content remains subject to the repo public-safe/no-secrets boundary and explicit user commit approval. Review applicability is owned by §Scope and review. Diagnostics prove only their implemented subset and are not a secret scanner. This boundary approves no mutation, commit, push, or promotion.
6. **No forced form or round cap.** Incubation has no template, fixed section set, production-polish requirement, or round limit. Candidate-local names are not pre-registered; the glossary's own trigger applies only when project-wide terminology is actually introduced, changed, collided, or revived.

### Freedom-wall invariants

- **E1 — no canonical discovery or authority.** A candidate folder or name is not a canonical domain/rule discovery target and is not implementation authority. A status-honest name-only mention may identify it as a non-authoritative candidate, but gives it no discovery or behavioral status. Runtime dogfooding of a promoted-but-not-live artifact does not upgrade its governance status.
- **E2 — no durable candidate-document input.** Canonical rules, indexes, templates, skills, and checklists do not depend on or durably link to an `_incubation.md`. Meaning needed by a promoted artifact is absorbed rather than linked back.
- **E3 — no canonical consumption or sibling.** While `_incubation.md` exists, neither it nor its renamed lineage is a default/input of a canonical surface, and no `_design` / `_plan` / `_spec` sibling exists. Promotion atomically performs the `_incubation` → `_design` swap.

### `rule_docs/` planning workspace

`rule_docs/<id>/` is the persistent planning home for one existing rule or one rule candidate. The terminal rule remains its own spec-of-record.

- The default role files are `.gitkeep` and `<id>_{incubation,design,plan,work_packet,backlog}.md`. This is a convention and checker diagnostic, not a ban on a future same-owner role admitted through Design/Plan.
- A child folder does not mix owner ids, hide lifecycle work in a subfolder/archive, or claim authority without an incubation candidate, active lifecycle work, or corresponding terminal rule. These are blockers. A same-owner auxiliary role is judged semantically; absence from the default list alone is not.
- An existing rule's idle folder may keep `.gitkeep` and its backlog. Active revision files are deleted at promoted-lifecycle closeout. A discarded candidate keeps no idle folder.
- A backlog belongs only to an existing rule or is created at its terminal landing. Incubation questions stay in `_incubation.md`; promoted questions stay in Design/Plan until the rule exists.
- Distribution-tier admission is owned by `snippets/rules/README.md`. When distributed rule work puts project residue in play, the lifecycle re-homes or explicitly discards it before planning artifacts are deleted; closeout does not lose it silently.

## Future-work queue

Each domain/rule normally has at most one backlog. A backlog is non-authoritative future work, never a decision ledger, incident log, status report, or implementation approval.

- A row is concise by default and carries a reopen/start condition. More detail is allowed when needed to preserve that condition, but narrative authority or incident history belongs elsewhere.
- Closed rows are deleted; a one-line tombstone remains only for a live inbound ID reference that cannot be rewritten.
- There is no row-count/age cap. Long or old queues are soft review signals.
- The header carries a monotonically increasing `next ID: <PREFIX>-NN`; IDs are not reused after deletion.
- The file is created with its first queued item and then persists so the ID floor survives. A rule backlog is removed only with the whole rule/folder, not at ordinary closeout.

## Spec / rule ↔ implementation synchronization

Synchronization is meaning-level, not line or sentence mirroring.

- Every durable behavior/owner statement in the Spec or rule is verifiable in implementation.
- Every externally observable behavior and ownership boundary in implementation has corresponding target-state meaning.
- Internal decomposition, naming, and algorithm choice are not 1:1 targets.
- “Reconstructibility” is a review aid: the same behavior and normative meaning should be recoverable, not identical prose or code.
- If a change alters no target-state sentence meaning, it is refactoring; otherwise the Spec/rule changes with it.

For a live domain, Design → Plan updates the live Spec in place to the new target state and marks it `sync-required`; closeout returns it to `live`. A first Spec uses `prelive`.

## Proportionality

Typos, stale pointers, and meaning-preserving clarification may be edited directly. A change to allow/forbid boundaries, behavior, ownership, or validation expectation invokes the lifecycle.

A direct edit states that it is meaning-preserving. If unresolved doubt concerns normative meaning, use the lifecycle conservatively. Pure style or wording preference is not such doubt.

## Closeout — two-level inspection

Inspection and reporting are unconditional; updating is conditional. For every listed surface the closeout report says `updated: <file> — <what>` or `checked: <file> — no change required`. Silent omission fails closeout.

- **Level 1 — orientation:** `docs/README.md` and any affected unmigrated orientation surface.
- **Level 2 — owner-local:** domain Spec/backlog, or terminal rule and its existing rule backlog.

Current-correctness blockers are resolved before landing. Not-yet-started future work goes to the owner backlog with a reopen condition.

When a rule changes a form-bound statement, only forms/checks that directly embody or enforce that statement synchronize in the same changeset. Keyword similarity is not a dependency; uncertainty is resolved by identifying the call/field/meaning correspondence. The listed surfaces are reported individually.

## Lifecycle closeout

Closeout requires:

- target-state meaning and implementation reconciled 1:1;
- current-bearing Design/Plan/Work Packet meaning absorbed into the Spec/rule, active owner, report, or backlog;
- inbound references corrected;
- Design and Plan retired by deletion;
- Work Packet deleted.

Candidate promotion/discard closes the candidate lifecycle first. Promoted-lifecycle closeout later disposes Design/Plan/Work Packet. Each temporary artifact is deleted at its own closeout.

## Stage rewind

- Plan changes the Design decision → stop, redesign, restart Plan.
- Spec changes the Plan decision → stop, re-plan, restart Spec.
- Implementation exceeds the Spec/rule boundary → stop and ask the user.

## State migration

- In the same owner and role slot, a prior revision's unretired planning artifacts are disposed or explicitly continued before a competing revision starts. Independent owner/role-slot work is not blocked.
- A carried-over artifact is non-authoritative until reused, reverified, or discarded; this creates no archive or extra role file.
- A promoted-but-not-live artifact may be withdrawn through a recorded `promotion-withdrawal` changeset that disposes its promoted artifacts and reopens `_incubation`. The correction sweep is limited to references/status claims that actually become stale. Once live, change uses the normal repeal/supersede lifecycle.

## Self-amendment

A new governance mechanism does not retroactively govern its introducing changeset. A lifecycle/governance self-revision is governed through its own closeout by the pre-revision text; post-revision text governs later work.

Even while a rule is being revised, a pre-amendment structural check that already applies continues to apply to that changeset. This is distinct from using the new mechanism retroactively and must be recorded in closeout.

## Stable filenames and physical roles

The default domain roles are `<domain>_{design,plan,spec,backlog,work_packet}.md`; incubation adds `<candidate>_incubation.md`. Package forms use the `docs-working-model_` prefix and template/checklist suffixes.

These names are a stable convention, not a permanently closed role universe. A same-owner auxiliary role may be introduced through Design/Plan. Splitting a canonical role across competing files, using another owner id, or hiding lifecycle work in a subfolder/archive is a blocker. Checker output over the default set is diagnostic and does not by itself prove lifecycle approval or rejection.

## Authoring language

Human-facing repo prose language is owned by the root `CLAUDE.md` / `AGENTS.md` shared body. This rule only points to that owner.

## Domain-local closure and cross-domain semantics

A domain is understandable from its own Spec, active surface, and explicitly named stable interfaces. A lower layer does not complete its meaning by depending on a routing document.

Foreign normative behavior must not be redefined as local authority. Stable interfaces, owner names, identity contrast, and thin pointers are allowed. “Would a target implementation change require this sentence to change?” is a useful heuristic, not an irrebuttable test; owner/evidence analysis resolves counterexamples.

An incubating candidate may define its identity by contrast without copying another domain's vocabulary, lifecycle, permissions, completion semantics, schema, or procedure. Fix an overreach by narrowing the candidate's own claim or naming the foreign owner, not by importing more foreign definition.

## On-demand status

There is no committed project-current mirror. Current status is synthesized on demand from live domain Specs/backlogs and revised rule backlogs; unmigrated owner surfaces stand in until their batch. The user chooses future work conversationally.

## Templates, checklists, and diagnostics

Templates provide defaults. Checklists are omission-detection and self-review aids; a missed checkbox is not an independent blocker. A blocker requires evidence that the underlying rule meaning is violated. Checklist observations are recorded outside checklist bodies.

The package forms live at:

- `templates/docs-working-model_{design,plan,spec}_template.md`
- `checklists/docs-working-model_{design,plan,spec,work_packet,closeout,promotion}_checklist.md`

A produced Spec does not own implementation behavior. The active surface owns behavior and is reconciled with the Spec.

When a direct form/check dependency changes, the corresponding template/checklist/checker/test changes in the same changeset. `scripts/docs-working-model-check.ps1` is a manually invoked deterministic diagnostic, not a lifecycle transition gate. Its output proves only its disclosed mechanical subset. The eight-heading template shape is diagnostic; lifecycle marker meaning remains binding.

## Scope and review

Applying this rule to a legacy surface is a scoped batch with owner absorption, relevant reference correction, and review. A verdict grants no mutation, commit, push, publish, merge, release, or global/user-file approval.

The normal corrected-state review gate applies from Design onward. It does not apply to `_incubation.md` during incubation; public-safe/no-secrets and explicit commit approval still apply there.

## Tier

This is a repo-development rule for this repository only. It is not adopter-universal and is not distributed under `snippets/rules/`. Historical rationale and predecessor wording remain in git history.
