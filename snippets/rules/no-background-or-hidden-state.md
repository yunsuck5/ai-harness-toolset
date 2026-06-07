# Rule: No autonomous or hidden execution (supervised background is allowed)

ai-harness-toolset is explicit-prompt, local-first, and deterministic. It introduces no autonomous execution and no hidden per-user state. Background or parallel execution is permitted only as operator-supervised, explicitly launched, and fully joined work — never as autonomous, hidden, or fire-and-forget execution. The two axes below — what may *trigger* work, and how that work may *run* — are separate; do not collapse them.

## Trigger: explicit prompt only (invariant)

- No daemon, watcher, scheduler, cron, hook, or self-triggering task. Every lifecycle action (review, Brief save / restore, install / update) starts only on an explicit prompt.
- A rule is never implemented via a hook to compensate for weak instruction or skill design. Hooks are forbidden-by-default and out of scope.
- No queue system and no autonomous scheduler.

## Execution: supervised background / parallel allowed; autonomous / unjoined forbidden

- Background or parallel execution is allowed **only when all hold**: (a) it is launched inside an explicit operator goal; (b) the work is **read-only with respect to the reviewed inputs and the repo / global / user surfaces** — its only permitted write is each unit's own isolated output per (c) (e.g., a per-pass `result.md`), never a mutation of source, global, or user files; (c) each unit's output is **isolated** (e.g., a per-purpose `log/` path or a per-pass review directory); (d) the operator **records the expected member set and joins every member** before any conclusion or closeout.
- **MUST NOT** background or parallelize a **mutating** step — edits, writes to shared paths, install / update / uninstall, git operations, or any global / user filesystem mutation. Worktree-isolated mutating parallelism is out of scope and requires a separate explicit approval boundary.
- **MUST NOT** conclude, report "done", or close out while any expected member is still running or has incomplete or stale artifacts. No fire-and-forget; no unjoined background work.
- **Validity is independent of launch mode.** A unit is valid only by artifact completeness, exit code, verifier pass, disclosure-body inspection, and fresh source / input binding — never because it ran (or "looks done" because it ran) foreground, background, or in parallel. A timeout or budget is an operating allowance, not a validity guarantee; a partial / aborted artifact, or the mere existence of an output file, is not success; never raise a timeout, narrow scope, or drop a member to make a run finish or "pass".
- **MUST NOT** sleep- or poll-loop to wait on runtime-tracked background work; rely on completion notification.
- Concurrency is bounded by **join / reduce capacity** — how many results the operator can fully read and cross-check — **not** by how many tasks can be forked. Prefer fewer, well-grouped launches over a wide fan-out.

The per-flow mechanics — canary-first for a new run shape, the concrete concurrency cap, the fan-out unit (independent concern / blast-radius, not file count), and the join checks — live with the deployed skill that owns the flow (e.g., `ai-harness-review`), which is itself an active surface; this rule and that skill, not any `docs/**` page, are the authority for this behavior.

## No sidecar state machine

- No `BF_STATE.json` or any sidecar state-machine file, and no sidecar scheduler or join-tracking state. The Brief (`<ProjectRoot>/log/brief/BRIEF.md`) is the manual, human-readable recovery artifact; there is no automated state file, daemon, or scheduler behind it. Brief automation beyond manual save / restore is not implemented.

## No per-user partitioning or ownership metadata

- No per-user / per-operator log partitioning, operator-id, machine-id, or ownership metadata. Runtime artifacts are partitioned by **purpose** under `<ProjectRoot>/log/` (`log/review/`, `log/evidence/`, `log/chatlog/`, `log/brief/`), never by operator identity.
