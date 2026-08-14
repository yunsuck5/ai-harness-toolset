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
  → optional Work Packet → implementation → meaning reconciliation / absorption / reference correction
  → corrected-state review → user-approved retirement-only closeout
  → Design/Plan/Work Packet retire + Spec marker flip → Spec/rule + implementation live
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
- **`sync-required`** when a previously-live Spec has been updated and remains before the approved closeout that returns the revised target-state/implementation alignment to `live`;
- **`live`** after the approved retirement-only closeout.

Exactly one bolded lifecycle marker appears in the Spec's Lifecycle state meaning area. A `prelive` Spec is governance-discoverable but is not closeout-verified implementation authority.

A Spec carries eight meaning areas: Header, 목표 상태, Owner surface 지도, Durable boundary, Cross-domain interface, Validation expectation, Review focus, and Lifecycle state. The package template presents these as eight headings for consistent authoring, but heading count is a form diagnostic rather than an independent lifecycle blocker. Durable target-state meaning and exactly one lifecycle marker remain required.

A Spec does not carry round-scoped file inventories, execution/staging procedures, review results, readiness judgments, or point-in-time work status beyond compact lifecycle markers. It does not copy backlog IDs or next-ID allocation; a terminal rule likewise does not copy its rule backlog inventory.

## Work Packet

A Work Packet is a round-scoped, non-authoritative temporary artifact for line-level classification, investigation, implementation notes, evidence proposals, reviewer-question preparation, and edge cases.

- It is not an approval target, live document, or Spec/rule substitute.
- It does not carry command sequences, staging procedures, review/validation results, or readiness judgments.
- Its normal path is `docs/<domain>/<domain>_work_packet.md` or `rule_docs/<id>/<id>_work_packet.md`; subfolder lifecycle evasion is not allowed.
- A Plan declares its purpose, absorption target, and retire condition.
- Before the final corrected-state review, current-bearing content is absorbed into the correct owner/report; the Work Packet is then deleted only by the promoted-lifecycle closeout.
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

For a live domain, Design → Plan updates the live Spec in place to the new target state and marks it `sync-required`. Reconciliation, validation, and corrected-state review occur before closeout; the approved closeout returns the marker to `live`. A first Spec uses `prelive`.

## Proportionality

Typos, stale pointers, and meaning-preserving clarification may be edited directly. A change to allow/forbid boundaries, behavior, ownership, or validation expectation invokes the lifecycle.

A direct edit states that it is meaning-preserving. If unresolved doubt concerns normative meaning, use the lifecycle conservatively. Pure style or wording preference is not such doubt.

## Closeout — two-level inspection

Inspection and reporting are unconditional; updating is conditional. For every listed surface the closeout report says `updated: <file> — <what>` or `checked: <file> — no change required`. Silent omission fails closeout.

Retirement-only closeout을 목표로 할 때 이 inspection에서 발견된 conditional update는 최종 corrected-state review **전에** candidate에 반영한다. Review 뒤에 새 content update가 필요해지면 closeout을 계속하지 않고 candidate 단계로 되돌린다. Closeout 시점의 report는 이미 검토된 처분을 확인할 뿐 source content를 새로 고치지 않는다.

- **Level 1 — orientation:** `docs/README.md` and any affected unmigrated orientation surface.
- **Level 2 — owner-local:** domain Spec/backlog, or terminal rule and its existing rule backlog.

Current-correctness blockers are resolved before landing. Not-yet-started future work goes to the owner backlog with a reopen condition.

When a rule changes a form-bound statement, only forms/checks that directly embody or enforce that statement synchronize in the same changeset. Keyword similarity is not a dependency; uncertainty is resolved by identifying the call/field/meaning correspondence. The listed surfaces are reported individually.

## Lifecycle closeout

### Readiness와 closeout의 분리

Promoted-lifecycle closeout은 두 번째 content-correction 단계가 아니다. 다음 content readiness는 최종 corrected-state review 전에 candidate 안에서 완료한다.

- target-state meaning과 implementation의 1:1 reconciliation;
- Design/Plan/Work Packet의 current-bearing 의미를 Spec/rule, active owner, operator report 또는 backlog에 흡수;
- 실제 stale해지는 inbound reference와 필요한 orientation/backlog 처분의 정정;
- candidate 판단에 필요한 적용 가능한 validation·실사용 확인.

이 readiness가 반영된 candidate를 최종 corrected-state review한 뒤, 사용자가 lifecycle closeout을 명시 승인해야 retirement를 수행할 수 있다. 그 승인은 commit/push/publish/deploy 권한을 대신하지 않는다. Review 뒤에 source content를 더 고쳐야 하면 closeout이 아니라 candidate correction이며, 그 corrected candidate가 ordinary review 대상이다.

### `retirement-only closeout` exact shape

`retirement-only closeout`은 **promoted-lifecycle closeout의 좁은 하위 분류**다. Candidate promotion/discard/withdrawal에는 적용하지 않는다. 판정 대상은 readiness가 끝난 뒤 제안된 **closeout transaction 자체의 전체 source delta**다.

다음 조건을 모두 충족해야 한다.

1. **Domain variant:** affected owner 각각의 stable role path에서 Design·Plan을 완전히 삭제하고, 해당 revision에 Work Packet이 존재했다면 그것도 완전히 삭제한다. 그 revision의 target-state content가 corrected-state review에 포함된 Spec은 affected Spec이며 marker disposition은 아래 공통 규칙을 따른다.
2. **Terminal-rule variant:** affected rule owner의 `rule_docs/<id>/` stable role path에서 Design·Plan을 완전히 삭제하고, 존재했다면 Work Packet도 삭제한다. Terminal rule은 byte·mode·path가 동일하다. Proposed transaction에서 retire되는 각 terminal-rule revision에 대해, final corrected-state reviewed candidate가 실제로 직접 동기화한 foreign-Spec thin-interface path set과 그 Plan이 aggregate/dependency 목록과 구별해 명시한 **foreign-Spec direct-sync target** path set은 빈 집합을 포함해 정확히 같아야 한다. 누락·stale/false·extra·오지정 declaration이 하나라도 있으면 `not retirement-only`로 candidate correction/review에 되돌린다. 일치한 set의 Spec만 affected Spec이며 marker disposition은 아래 공통 규칙을 따른다. 이 분류는 foreign Spec의 meaning ownership을 terminal-rule Plan에 이전하지 않는다. 그 Spec의 marker 외 byte·mode·path와 다른 surviving file은 동일하다.
3. **Affected Spec marker disposition:** proposed closeout transaction에 포함된 모든 stable-role planning artifact 삭제를 적용한 post-transaction state를 기준으로 각 affected Spec을 판정한다. 해당 Spec의 domain-local Design·Plan·Work Packet이 하나라도 남으면, 유일한 bold marker token은 기존 `**prelive**` 또는 `**sync-required**`로 유지하고 Spec whole-file의 byte·mode·path를 바꾸지 않는다. Domain-local lifecycle이 하나도 남지 않아 marker 전이 자격을 판정할 때는 각 surviving open terminal-rule revision에 대해 그 Plan이 해당 Spec을 **foreign-Spec direct-sync target**으로 명시했는지와 그 revision의 current candidate가 해당 Spec을 실제로 직접 동기화했는지를 current candidate와 active surface에서 각각 재구성한다. 재구성할 수 없거나 판정이 모호하거나 두 membership이 다르면 현재 transaction은 `not retirement-only`이며, 그 open revision을 reconcile하거나 현재 closeout을 보류한 뒤 다시 판정한다. 두 membership이 모두 참인 revision이 하나라도 surviving 상태라면 marker만 유지한 채 현재 closeout을 끝내지 않는다. 그 revision을 같은 proposed transaction에서 함께 retire하거나 먼저 별도 correction으로 claim을 제거한 뒤 전체 transaction을 다시 판정한다. Aggregate/dependency scope에만 Spec을 나열해 두 membership이 모두 거짓인 revision은 claimant가 아니다. Domain-local lifecycle과 surviving terminal claimant가 모두 0일 때만 단일 `## Lifecycle state` 절의 유일한 marker token을 `**live**`로 정확히 한 번 반드시 치환한다. 같은 Spec을 scope한 여러 claimant revision을 한 transaction에서 함께 retire할 때도 이 post-transaction 판정을 한 번 적용한다.
4. **No other delta:** 위 삭제와 marker disposition이 요구한 치환 외 tracked/index/source-managed untracked change가 0이다. Addition·rename·copy·archive 이동, README/backlog/reference/active-owner/test 수정, lifecycle marker line의 다른 문면 수정은 허용하지 않는다. `log/**` operator report/evidence는 source delta가 아니다.

이 predicate는 사람과 도구가 제안된 transaction의 전체 source delta를 대조할 수 있는 binding decision rule이지 새 checker·automatic stale detector·hard gate를 도입하는 명령이 아니다. 조건 하나라도 어긋나면 `not retirement-only`로 분류하고 변경을 candidate 단계로 되돌려 validation과 corrected-state review를 수행한다.

Exact retirement-only closeout은 이미 검토된 target-state meaning을 바꾸지 않고 temporary lifecycle artifact를 retire하며 Spec lifecycle state만 전이하므로 canonical review 대상이 아니고 기존 corrected-state review를 stale하게 만들지 않는다. Review workflow는 pass를 만들지 않고 caller-side `no-reviewable-change`를 보고한다.

Candidate promotion/discard는 candidate lifecycle을 먼저 닫는다. Promoted-lifecycle closeout은 위 readiness와 exact retirement transaction으로 Design/Plan/Work Packet을 처분한다. 각 temporary artifact는 자기 closeout에서 삭제되며 archive/`consumed/` folder를 만들지 않는다.

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

The normal corrected-state review gate applies from Design through the final content-bearing candidate. It does not apply to `_incubation.md` during incubation; public-safe/no-secrets and explicit commit approval still apply there. A DWM-qualified retirement-only closeout has no reviewable content and does not re-run that gate; any predicate miss returns to the candidate stage and ordinary staleness/review instead.

## Tier

This is a repo-development rule for this repository only. It is not adopter-universal and is not distributed under `snippets/rules/`. Historical rationale and predecessor wording remain in git history.
