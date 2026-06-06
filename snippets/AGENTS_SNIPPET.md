<!-- BEGIN AI_HARNESS_TOOLSET_GLOBAL -->
# ai-harness-toolset instructions for AGENTS.md-compatible agents

This is a manually adopted AI instruction payload for Codex CLI and other AGENTS.md-compatible agent assistants. The user has copied it into the destination `AGENTS.md` inside a managed block delimited by `<!-- BEGIN AI_HARNESS_TOOLSET_GLOBAL -->` and `<!-- END AI_HARNESS_TOOLSET_GLOBAL -->`. Treat its content as authoritative for ai-harness workflows in this project.

## Adoption destination

The valid destinations for this payload are exactly:

- **Project-root `AGENTS.md`** — `<ProjectRoot>/AGENTS.md`.
- **User-global Codex `AGENTS.md`** — `%USERPROFILE%\.codex\AGENTS.md` by default, or `%CODEX_HOME%\AGENTS.md` if the `CODEX_HOME` environment variable is set.
- At the Codex user-global scope, `AGENTS.override.md` (e.g., `%USERPROFILE%\.codex\AGENTS.override.md`) takes precedence over `AGENTS.md` when both exist. The managed block lives in whichever file is the effective Codex source of truth in that environment.

The forbidden destination is `%USERPROFILE%\.claude\AGENTS.md`. That path is not a recognized global instruction location for any agent, and ai-harness must never create it. The Claude global instruction path is `%USERPROFILE%\.claude\CLAUDE.md` (covered by `CLAUDE_SNIPPET.md`), not an `AGENTS.md` sibling under `.claude\`.

## Adoption rules

- This payload lives only inside the `AI_HARNESS_TOOLSET_GLOBAL` managed block of one of the destinations above. Replacing the content inside that managed block is the standard, allowed way to adopt or update it.
- Whole-file overwrite of any of those destinations is forbidden. Content outside the managed block — project-specific or user instructions — must be preserved verbatim.
- Adopting or updating this payload in any destination above is an explicit, user-approved global / user config mutation, never an implicit or automatic action.
- If the marker pair is already present, only the block between the markers may be replaced. Inserting the block into an existing file that has no marker, and creating a missing destination file, are each separate explicit-approval boundaries.
- An incomplete marker pair, duplicated markers, or a malformed block is a fail-fast / manual-review condition: stop and do not edit the file.

## Role neutrality

This payload is loaded regardless of the agent's current role. The same agent may operate as **operator** (making changes, running `review-prepare.ps1` / `review-run.ps1`), **reviewer** (reading a prepared packet and emitting a verdict), **auditor**, or **supervisor**. Role-specific behavior is decided by `/goal`, the review input, the skill prompt, or the command invocation — not by this global payload.

- When acting as **reviewer** or **auditor**, treat only the role-neutral parts of this payload as binding: ToolRoot / ProjectRoot path concepts, reviewer artifact location (`<ProjectRoot>/log/review/<review-task-id>/<perspective>/pass-NN/`), verdict vocabulary, BRIEF semantics, the no-overwrite contract for global files, and the source-of-truth priority. Form any verdict from the artifact evidence in the prepared packet itself; do not treat operator-supplied summaries as a substitute for that evidence, and do not infer commit / push approval from a verdict. In reviewer mode do not run the operator-side Brief / session-restore protocols, do not pause for a missing `BRIEF.md`, and do not ask a restore / session / clarification question — produce the canonical review `result.md` verdict instead (the review-result contract takes precedence).
- The operator-side protocols — the Brief save / checkpoint / restore / update workflow, and the `review-prepare` / `review-run` review flow — apply only when acting as **operator**.
- Nothing in this payload forces accept / approve. Nothing in it weakens reviewer independence. Nothing in it permits whole-file overwrite of a global instruction file.

## Project layout

`<ToolRoot>` is where the toolset's own `scripts/`, `config/`, `templates/`, and `snippets/` live. `<ProjectRoot>` is the target project repo root. Toolset-owned files live under `<ToolRoot>`; target-owned project files and runtime artifacts live under `<ProjectRoot>`.

`<ToolRoot>` is resolved per invocation in this channel order: explicit `-ToolRoot` argument → `AI_HARNESS_TOOL_ROOT` env var (override) → global stable install `%USERPROFILE%\.claude\ai-harness-toolset\current` (absent skips to the next channel; present but incomplete fails fast) → `<ProjectRoot>/.ai-harness/` fallback → explicit error.

Runtime artifact paths under `<ProjectRoot>`:

- `<ProjectRoot>/log/` — runtime output root. `log/` must not be committed; ensure the target project's `.gitignore` includes it.
- `<ProjectRoot>/log/review/<review-task-id>/<perspective>/pass-NN/` — canonical review record: the two-file pair `input.md` + `result.md` only — no sidecar JSON, hash-binding, or external staging file is part of the record. Inspect `input.md` + `result.md` and report the verdict; the artifact / verdict / `result.md`-section shape is owned by the canonical review contract (`docs/contracts/review/REVIEW_RESULT_CONTRACT.md`).
- Keep `log/review/`, `log/evidence/`, and `log/chatlog/` separate.

Reviewer config lives at `<ToolRoot>/config/reviewer.json`.

## Result verdict vocabulary

The only valid final verdict values for this toolset are exactly:

- `yes`
- `no`
- `yes with risk`

A reviewer verdict does not approve commit, push, publish, merge, release, upload, or adoption. `yes` means no blocking finding in the reviewed scope and the user still decides the next step; `no` means a blocking finding exists and a corrective action is needed (classify whether the fix is within or outside the approved scope before acting); `yes with risk` means no blocking finding but disclosed risks require explicit user / supervisor risk acceptance before commit / push — it is not the automatic equivalent of `yes`. Detailed verdict → next-action mapping and result-consumption guidance live in the ai-harness-review skill (steps 6–7) and the canonical review contract — they are intentionally not duplicated here.

## Operator stance

Stay within the user-approved review / `/goal` scope. If a finding or fix would cross a source / runtime / sibling-report / user-global / global-install / commit-push boundary, stop and report instead of silently absorbing it. If you discover an earlier judgment of yours was wrong, retract it explicitly rather than overwriting it. The full operator stance (target-file accuracy, off-repo material handling, stop/report vs self-correct, retraction protocol, scope discipline) lives in the ai-harness-review skill and the canonical review contract — not duplicated here.

## Brief

- BF Level 3 — automated Brief management — is not implemented in this toolset. Do not claim that capability.

## Chatlog

- **Chatlog ≠ Brief.** Chatlog is the history / decision rationale / Brief reconstruction evidence area at `<ProjectRoot>/log/chatlog/`. It is **not** the current restore source and is **not** the default-restore target for a new session.
- The current restore source is **Brief** (`<ProjectRoot>/log/brief/BRIEF.md`).
- Chatlog may be consulted when Brief is missing, corrupted, or stale, as **reconstruction evidence only**. Chatlog is never promoted into Brief's seat.

## Forbidden in this toolset

- No per-user / per-operator log partitioning, operator-id, machine-id, or ownership metadata.
- No `BF_STATE.json` or sidecar state-machine file.
- No daemon, watcher, scheduler, hook, or background task.
- No implicit, automatic, or whole-file mutation of a global instruction file. Specifically: `%USERPROFILE%\.claude\CLAUDE.md` (Claude), `%USERPROFILE%\.codex\AGENTS.md` (Codex default), `%CODEX_HOME%\AGENTS.md` (Codex with `CODEX_HOME` set), `AGENTS.override.md` at the Codex user-global scope, and any project-root `CLAUDE.md` / `AGENTS.md`. Explicit user-approved managed-block insert / replace per `Adoption rules` is the one governed exception. No file is auto-created under `~/.claude/` or `~/.codex/`.
- No creation of `%USERPROFILE%\.claude\AGENTS.md`. That path is not a recognized global instruction location for any agent; ai-harness never writes to it.
- No automatic mirror between Brief (`<ProjectRoot>/log/brief/BRIEF.md`) and Chatlog (`<ProjectRoot>/log/chatlog/`).
- No automatic target `.gitignore` mutation.

## Other rules

- Commit and push require explicit user approval.
- Temporary files created solely for command execution should be cleaned up by the operator before closeout. Evidence, snapshots, logs, source changes, or user-requested artifacts are not temporary files.
<!-- END AI_HARNESS_TOOLSET_GLOBAL -->
