# Rule: Rule conflict and revision routing

## Admission

- Load this rule only when an applicable active-rule owner, a concrete required operation or acceptance condition, and an actual incompatibility are identified such that no compliant path can satisfy both; also load it when revision is requested because a binding rule blocks that work.
- Cost, inconvenience, preference, age, a claim that a rule is obsolete, or an ordinary interpretation question is not enough. If applicability is unclear, ask for owner clarification instead of declaring a conflict.

## Current binding state

- The current owner rule and any explicit owner-provided exception or compliant branch remain binding while the conflict is handled. Use that path first when it applies.
- Detecting a conflict, approving the surrounding task, or requesting revision grants no exception, waiver, force permission, or completion claim.

## Dependency containment

- `conflict-isolated` means the affected work unit shares no blocked output, state, assumption, invariant, owner contract, validator, transaction or commit boundary, acceptance gate, or coherence unit, and has independent evidence, acceptance, and status.
- If every isolation condition is not established, classify the affected unit as `conflict-unit-blocking`. These tokens describe dependency containment, not permission or severity.
- A user may prospectively rescope future work, but a later split cannot retroactively complete a blocked unit. Continuing isolated work does not make the blocked branch or whole task complete, canonical-ready, or commit-ready.

## Same-tier conflict set

- Surface conflicting rules at the same tier as one affected conflict set; do not invent precedence or use this rule recursively to bypass either owner.
- Each owner may revise through an independent lifecycle rather than a forced joint batch, but the affected unit stays blocked until compatible active states exist.

## Disclosure

- Report inline by default: the applicable owner; blocked operation or acceptance; exact incompatibility; affected scope; dependency classification and supporting facts; compliant alternatives checked; current binding state; work that may continue; and the user decision required.
- These fields transport evidence and status. They do not certify completion. Use an owner-required artifact instead only when that owner already requires one.

## Revision handoff

- Present the bounded choices: compliant rescope, hold or drop the blocked work, or start an owner-local revision. Do not choose an exception or revision outcome for the user.
- Starting revision changes no binding state by itself. Downstream mutation, commit, push, adoption, activation, and other owner gates remain separately required.

## Owner interfaces

- Prefer an owner-local path that already provides containment, disclosure, and terminal disposition or revision handoff. Do not add a duplicate procedure.
- If that path is partial, supply only the missing transport step. Do not copy the owner's schema or semantics, and follow the owner's lifecycle for the actual revision.

## Non-goals

- This rule is not a priority engine, policy arbitrator, exception authority, hidden state or queue, hook, scheduler, automatic mutation mechanism, or source-repository governance dependency.
- It does not redefine another rule's meaning, require all owners to revise together, or authorize work merely because it was separated into another batch.
