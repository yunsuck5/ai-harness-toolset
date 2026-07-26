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

### Rule add/change entry와 placement

- 신규 rule은 incubation promotion으로, 기존 terminal rule의 의미 변경은 그 identity의 승인된 revision으로 Design에 진입한다. 의미 보존 direct edit와 normative revision의 구분은 *Proportionality*를 그대로 사용하며 제3 경로를 만들지 않는다.
- Plan은 terminal landing 전에 repo-only와 global-distribution placement를 선택하고 해당 tier owner의 admission·discovery route를 확인한다. Terminal meaning은 rule 본문이, form/checker/test 같은 직접 dependency는 그 active surface가 소유한다.
- concrete active-rule conflict에서 진입한 revision은 `rule-conflict-and-revision-routing`의 containment와 disclosure를 복제하지 않는다. DWM lifecycle은 owner-local revision target, 보존된 affected unit, compatible active state 뒤의 resume 또는 drop/rescope terminal만 이어받는다.
- Closeout은 entry, placement, terminal meaning, 직접 dependency, governing text, 원 작업의 terminal/resume를 재구성한다. Governance self-revision은 *Self-amendment*의 pre-revision governing text를 계속 따른다.

### 같은 identity의 terminal placement 변경

같은 rule identity를 유지하면서 terminal placement를 바꾸는 작업은 identity retire가 아니라 별도 source-placement transition이다. Owner·actor만 바뀌고 placement가 유지되는 일반 revision과도 구분한다.

- Plan은 old/new placement와 tier owner를 특정하고, new placement의 admission·discovery route와 old placement의 source disposition을 같은 transition에 둔다.
- Landing은 old terminal source와 old tier 전용 index/trigger를 제거하거나 이관하고 new terminal source와 route를 활성화한다. Old/new placement가 같은 identity의 동시 active owner로 남지 않는다.
- Repo-only ↔ global-distribution 이동은 source file rename만으로 닫히지 않는다. Distributed side가 생기거나 사라지면 installed payload와 activation의 별도 후속 상태를 보고하며, source changeset만으로 runtime 완료를 주장하지 않는다.
- 성공 terminal은 new placement가 identity의 유일한 active terminal이고 old source placement·전용 route가 닫힌 상태다. 필요한 tier admission이나 replacement route가 준비되지 않으면 old placement를 먼저 제거하지 않고 재개 조건을 남긴다.

### Terminal rule 전체 retire/replacement

Clause·scope·enforcement 처분 뒤에도 같은 rule identity와 placement가 active terminal로 남으면 owner·actor 변경을 포함해 일반 rule revision이다. 같은 identity의 placement 변경은 앞 절을 사용한다. Old rule identity 자체를 active terminal에서 제거하고, retained meaning이 있으면 다른 identity나 owner가 흡수하는 경우에만 아래 lifecycle을 사용한다.

1. **Entry and current binding state.** 사용자 처분은 exact terminal identity와 placement, current owner/enforcement, replacement 유무, 직접 영향 surface를 특정한다. 처분 changeset이 닫히기 전까지 old terminal rule은 계속 binding이며, planning 시작 자체는 예외나 제거 효력을 만들지 않는다.
2. **Absorb or discard.** 유지할 normative meaning은 replacement 또는 다른 active owner가 자기 lifecycle로 흡수한다. 폐기 claim은 history 문서나 tombstone에 current authority로 복제하지 않는다. Meaning이 여러 owner로 나뉘면 각 owner를 독립적으로 닫고 하나의 새 terminal로 강제 통합하지 않는다.
3. **Dispose source ownership.** Old terminal path, rule 전용 source enforcement·form·checker·test, tier index와 owner-declared bootstrap route, rule backlog와 idle `rule_docs/<id>/` folder, 실제로 stale해진 inbound reference를 제거하거나 새 owner로 이관한다. Glossary는 그 owner의 de-adoption/collision/revival trigger가 실제로 발생할 때만 연다. Git hash와 역사적 path citation은 active dependency가 아니다.
4. **Close or resume.** 성공 terminal은 old identity가 active terminal owner로 남지 않고, old 전용 source enforcement/discovery route와 planning/backlog residue가 없으며, retained meaning마다 destination owner가 있고, affected work마다 새 owner interface의 resume 또는 명시적 drop/rescope terminal이 있는 상태다. Replacement나 필요한 owner absorption이 준비되지 않으면 그 retained meaning과 직접 필요한 old owner/enforcement를 선제 제거하지 않고 중단 지점과 재개 조건을 planning owner에 남긴다. 별도 clause 처분은 applicable owner가 독립성을 입증한 경우 일반 revision으로 닫을 수 있다. Concrete active-rule conflict라면 독립성은 `rule-conflict-and-revision-routing` owner의 containment 결과를 그대로 소비하며, 어느 경우에도 별도 clause closeout이 terminal identity 전체 처분의 부분 완료를 만들지는 않는다.

Global-distribution rule은 source terminal, distribution index, bootstrap route를 source-side에서 함께 닫는다. Committed source의 closeout은 installed payload나 user-global activation의 완료가 아니다. Payload materialization과 activation은 `INSTALL.md`와 그 active implementation owner의 별도 승인·검증을 따르며, 그 증거가 없으면 runtime follow-up을 미완 상태로 보고한다.

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
- **Level 2 — owner-local:** identity를 유지하는 domain 변경은 Spec/backlog를, live-domain terminal은 old Spec disposition과 아래 lifecycle의 behavior/routing/runtime 후속·successor/destination owner·old backlog identity를, terminal rule 변경은 그 rule과 existing rule backlog를 검사한다.

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
- A promoted-but-not-live artifact may be withdrawn through a recorded `promotion-withdrawal` changeset that disposes its promoted artifacts and reopens `_incubation`. The correction sweep is limited to references/status claims that actually become stale. Once live, identity 종료는 아래 live-domain lifecycle을 사용한다.

## Live domain retire·repeal·supersede

Candidate discard는 *Incubation (pre-promotion)*을, promoted `prelive`의 `promotion-withdrawal`은 *State migration*을 사용한다. Live domain의 같은 identity가 계속 active라면 일반 revision과 `sync-required → live` reconciliation을 사용한다. Previously-live Spec이 `sync-required`인 동안 처분 결정이 나면 기존 revision을 *State migration*과 *Stage rewind*에 따라 명시적으로 처분하거나 같은 owner slot에서 terminal 목표로 재계획한 뒤 아래 lifecycle로 전환하며, 그동안 old active behavior owner를 보존한다. Old live identity 자체가 active target-state/behavior owner에서 사라지는 retire·repeal, successor로 대체되는 supersede, rename/rehome은 아래 lifecycle을 사용한다. Spec 파일 삭제만으로 domain 종료를 주장하지 않는다.

1. **Entry and current binding state.** 명시적 사용자 처분은 exact domain identity와 current lifecycle state(`live` 또는 previously-live `sync-required`), retire·repeal·supersede·rename/rehome 중 disposition, successor 유무, retained meaning·stable interface, current Spec·active implementation·backlog·routing·direct consumer와 열린 planning slot을 특정한다. 처분 changeset이 닫히기 전까지 old target state와 active behavior owner는 current로 남는다.
2. **Absorb or discard.** Successor 유무와 무관하게 유지할 target meaning·stable interface와 아직 유효한 future work는 successor 또는 명명된 destination owner의 Spec·implementation·backlog lifecycle에서 흡수한다. 유지하지 않을 meaning/interface는 명시적으로 discard하고 future work는 rehome 또는 drop한다. Meaning이 여러 owner로 나뉘면 각 owner를 독립적으로 닫고 broad replacement domain을 만들지 않는다. 폐기 meaning은 archive·tombstone 문서에 current authority로 복제하지 않는다. Rename/rehome은 successor identity transition이며, new Spec path·backlog identity·routing이 준비된 뒤 old identity에서 단방향으로 전환한다.
3. **Dispose old ownership.** Old Spec, domain-local Design·Plan·Work Packet, old backlog identity와 남은 무효 row, domain 전용 implementation·trigger·routing·fixture, docs orientation, 실제로 stale해진 inbound reference를 제거하거나 새 owner로 이관한다. Shared implementation과 foreign owner meaning은 해당 owner 경계 밖에서 삭제하지 않는다. Glossary는 공용 term의 도입·의미/분류 변경·실제 collision·rejected revival trigger가 발생할 때만 연다. Git hash와 역사적 path citation은 active dependency가 아니다.
4. **Close or resume.** No-successor source-side terminal은 old identity의 Spec·backlog·전용 behavior/discovery route가 없고, retained meaning·interface가 없거나 각 destination owner가 active이며, 유효 future work가 rehome/drop되고 dependent work가 명시적으로 drop/rescope된 상태다. Successor source-side terminal은 retained meaning·interface·future work의 destination owner가 active이고 old/new identity의 active 병존이 없으며 dependent work가 새 interface에서 resume하거나 drop/rescope된 상태다. 필요한 absorption·disposal·validation이 준비되지 않으면 old owner를 먼저 제거하지 않고 affected material을 보존한 채 중단 지점과 재개 조건을 current planning owner에 남긴다.

Committed source의 closeout은 installed payload나 user-global activation의 완료가 아니다. Domain 처분이 deployed surface를 바꾸면 payload materialization과 activation은 `INSTALL.md`와 그 active implementation owner의 별도 승인·검증을 따르며, 그 증거가 없으면 runtime follow-up을 미완 상태로 보고한다.

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
