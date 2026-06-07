# Rule: No background execution or hidden state

ai-harness-toolset is explicit-prompt, local-first, and deterministic. It introduces no autonomous execution and no hidden per-user state.

## No background execution

- No daemon, watcher, scheduler, hook, or background task. Lifecycle actions (review, Brief save / restore, install / update) run only on an explicit prompt.
- A rule is never implemented via a hook to compensate for weak instruction or skill design. Hooks are forbidden-by-default and out of scope.

## No sidecar state machine

- No `BF_STATE.json` or any sidecar state-machine file. The Brief (`<ProjectRoot>/log/brief/BRIEF.md`) is the manual, human-readable recovery artifact; there is no automated state file, daemon, or scheduler behind it. Brief automation beyond manual save / restore is not implemented.

## No per-user partitioning or ownership metadata

- No per-user / per-operator log partitioning, operator-id, machine-id, or ownership metadata. Runtime artifacts are partitioned by **purpose** under `<ProjectRoot>/log/` (`log/review/`, `log/evidence/`, `log/chatlog/`, `log/brief/`), never by operator identity.
