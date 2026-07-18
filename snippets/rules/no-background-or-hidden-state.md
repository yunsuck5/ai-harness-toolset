# Rule: Explicit authority and accountable execution

Trigger authority and execution mode are separate axes. A direct prompt does not make every background mutation safe, and a named mechanism is not unsafe merely because it is a hook, watcher, scheduler, daemon, sidecar, or background task. This rule supplies atomic admission and accountability properties; it approves no particular mechanism and does not replace a flow owner's stricter policy.

## Trigger authority and prospective admission

- **MUST NOT** create or rely on an unowned, undisclosed, or self-authorizing trigger. An action starts from an authorized direct goal unless an active owner surface has already adopted a `managed trigger`.
- A **managed trigger** is an adopted condition or invocation that starts, resumes, or automatically advances an ai-harness-owned action without a new direct prompt for that firing. Before adoption, its active owner must declare its name and purpose; separate explicit user approval or standing delegation that covers adoption; trigger, executor, location, mutation scope, and the expected continuation set or closed continuation bound for each firing; inspect, disable, and remove paths; failure, residual, retention, cleanup, and terminal-accounting rules; and an owner revision path.
- Any change affecting authority, trigger, executor, behavior, mutation scope, continuation authority or bound, or terminal meaning requires that owner revision path. Any expansion of authority or scope additionally requires explicit re-approval.
- A rule, instruction, running process, result artifact, stable path, or payload update cannot authorize itself, name itself as an exception, or silently broaden an adopted trigger's authority, mutation scope, continuations, or completion meaning.
- A rule is not implemented through a hook merely to compensate for weak instruction, skill, or active-owner design.

An **authorized direct goal** is traceable to the current user's explicit request or to an unrevoked standing delegation whose scope covers the action. An **active owner surface** is an inspectable instruction, skill, rule, or runtime contract that owns the mechanism before execution and can be revised independently from the running instance.

A new mechanism is decided through its owner's normal adoption channel against these properties. A mechanism class alone is neither approval nor rejection, and an unchanged firing inside an adopted contract needs no new per-run adoption decision unless that contract requires one.

## Execution and terminal accounting

- Foreground, serial execution is the default for mutation.
- Background or parallel read-only work may run under an authorized direct goal or an adopted managed trigger when outputs are isolated and the owning flow fixes the expected member set and terminal accounting before launch.
- Background or parallel mutation is prohibited by default. It may be admitted only as a predeclared, named, bounded exception in an active owner surface under separate explicit authority. Its owner-defined result artifact must account for the trigger and executor, mutation targets, fixed continuation set, member outcomes, residuals, cleanup, and terminal predicate; hidden sidecar state cannot substitute for that accounting.
- For each bounded firing or control operation, a launch acknowledgement is not terminal completion. Every expected member must be accounted as terminal, launch-failed, or not launched with its reason, and every launched continuation must reach an owner-defined terminal outcome. An unobserved continuation makes execution unresolved; unresolved execution prevents terminal success and closeout.
- An owner-declared persistent active state may be the terminal outcome of an enable or control operation, but it is not a claim that the mechanism has terminated. Its continuing trigger authority and each later firing remain separately accountable.
- **Validity is independent of launch mode.** Artifact completeness, fresh input binding, required verification, and the owner's success predicate decide validity. Do not raise a timeout, narrow scope, drop a member, discard a failure, or relabel a partial outcome to manufacture success.
- Concurrency is bounded by join and reduce capacity, not by the number of tasks that can be forked.

Concrete concurrency limits, notification or wait mechanics, result vocabulary, retention, cleanup, and flow-specific verification belong to the active owner. This rule neither requires nor forbids polling as a universal mechanism.

## State and identity

- **MUST NOT** use hidden authority, lifecycle, scheduler, or join state to grant permission or manufacture completion.
- Named, owner-visible run state, recovery material, and artifact, source, revision, role, or member identity are allowed when their purpose, location, and lifecycle role are disclosed. Concrete shape, retention, and cleanup remain with the active owner, and metadata grants no authority by itself.
- Shared, distributed, or public-safe surfaces **MUST NOT** partition instructions, authority, correctness, or required evidence by person, operator, user, or machine identity in a way that breaks portability or hides behavior. Public, purpose-bound metadata is allowed.

## Owner-local closure and non-retroactivity

The active flow owner defines concrete mechanics and may impose a stricter policy. This rule defines admission and accountability properties only; it does not define review, consultation, Brief, install, update, uninstall, finalizer, trigger, scheduler, state, or cleanup mechanics.

This rule does not retroactively approve or certify a pre-existing mechanism, close any known gap, or take ownership of that risk from the mechanism's active owner. It does not require a project-wide finite audit of every unchanged pre-existing mechanism.
