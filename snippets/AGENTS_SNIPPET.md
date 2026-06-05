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

- When acting as **reviewer**, treat only the role-neutral parts of this payload as binding: ToolRoot / ProjectRoot path concepts, reviewer artifact location (`<ProjectRoot>/log/review/<review-task-id>/<perspective>/pass-NN/`), verdict vocabulary, BRIEF semantics, the no-overwrite contract for global files, and the source-of-truth priority. Form the verdict from the artifact evidence in the prepared packet itself; do not treat operator-supplied summaries as a substitute for that evidence, and do not infer commit / push approval from a verdict. In reviewer mode do not run the operator-side Brief / session-restore protocols, do not pause for a missing `BRIEF.md`, and do not ask a restore / session / clarification question — produce the canonical review `result.md` verdict instead (the review-result contract takes precedence).
- The operator-side protocols described below — BF save triggers and the `review-prepare` / `review-run` review flow — apply only when acting as **operator**.
- Nothing in this payload forces accept / approve. Nothing in it weakens reviewer independence. Nothing in it permits whole-file overwrite of a global instruction file.

## Project layout

`<ToolRoot>` is where the toolset's own `scripts/`, `config/`, `templates/`, and `snippets/` live. `<ProjectRoot>` is the target project repo root. Toolset-owned files live under `<ToolRoot>`; target-owned project files and runtime artifacts live under `<ProjectRoot>`.

`<ToolRoot>` is resolved per invocation in this channel order: explicit `-ToolRoot` argument → `AI_HARNESS_TOOL_ROOT` env var (override) → global stable install `%USERPROFILE%\.claude\ai-harness-toolset\current` (absent skips to the next channel; present but incomplete fails fast) → `<ProjectRoot>/.ai-harness/` fallback → explicit error.

Runtime artifact paths under `<ProjectRoot>`:

- `<ProjectRoot>/log/` — runtime output root. `log/` must not be committed; ensure the target project's `.gitignore` includes it.
- `<ProjectRoot>/log/review/<review-task-id>/<perspective>/pass-NN/` — canonical review record. Inspect `input.md` + `result.md` and report the verdict.
- Keep `log/review/`, `log/evidence/`, and `log/chatlog/` separate.

Reviewer config lives at `<ToolRoot>/config/reviewer.json`.

## Review flow

- A Codex review of in-progress work is an **explicit-prompt-triggered** capability owned end to end by the on-demand `ai-harness-review` skill. When the user asks for a Codex / 코덱스 review of the current work, that skill owns the full lifecycle — `review-prepare.ps1` → `review-run.ps1` → `review-verify.ps1`, `-Perspective` selection (e.g. `local-correctness` / `system-coherence`, required), `input.md` / `result.md` authoring, validation-evidence and known-concerns handling, and the corrective loop. This always-loaded payload only routes to the skill; it does not restate that procedure. A public adopter installs the `ai-harness-review` skill alongside this snippet.
- Canonical review artifacts live only under `<ProjectRoot>/log/review/<review-task-id>/<perspective>/pass-NN/` (see *Project layout*) as the two-file pair `input.md` + `result.md` — no sidecar JSON, hash-binding, or external staging file is part of the record. The artifact, verdict, and `result.md`-section shape is owned by the canonical review contract, which the skill mirrors.

## Result verdict vocabulary

The only valid final verdict values for this toolset are exactly:

- `yes`
- `no`
- `yes with risk`

A reviewer verdict does not approve commit, push, publish, merge, release, upload, or adoption. `yes` means no blocking finding in the reviewed scope and the user still decides the next step; `no` means a blocking finding exists and a corrective action is needed (classify whether the fix is within or outside the approved scope before acting); `yes with risk` means no blocking finding but disclosed risks require explicit user / supervisor risk acceptance before commit / push — it is not the automatic equivalent of `yes`. Detailed verdict → next-action mapping and result-consumption guidance live in the ai-harness-review skill (steps 6–7) and the canonical review contract — they are intentionally not duplicated here.

## Operator stance

Stay within the user-approved review / `/goal` scope. If a finding or fix would cross a source / runtime / sibling-report / user-global / global-install / commit-push boundary, stop and report instead of silently absorbing it. If you discover an earlier judgment of yours was wrong, retract it explicitly rather than overwriting it. The full operator stance (target-file accuracy, off-repo material handling, stop/report vs self-correct, retraction protocol, scope discipline) lives in the ai-harness-review skill and the canonical review contract — not duplicated here.

## Brief

- **Brief** is a project's durable restore source-of-truth. The current operator — or a new AI agent session — reads it as the local restore entrypoint **when an explicit Brief restore is requested**, not as an unsolicited session-start auto-read. It is not a shared project handoff document.
- **Canonical Brief** = `<ProjectRoot>/log/brief/BRIEF.md`. That single path is the canonical reading position when restoring. It is a project-local, operator-local runtime artifact under `<ProjectRoot>/log/` (gitignored by default and not a commit / push target).
- **Rejected locations**: root `<ProjectRoot>/brief/BRIEF.md` is not the canonical Brief. Any user-home operator-local runtime root is also not the canonical Brief.
- The operator is the trigger / approve / reject / discard owner and does not hand-edit the Brief. Brief content is written or updated by the agent (an explicit AI-assisted command flow on operator trigger) or by deterministic tooling.
- BF Level 3 — automated Brief management — is not implemented in this toolset. Do not claim that capability.
- Brief shape validation is a narrow primitive only. It is not a reviewer verdict and does not approve or block commit, push, merge, release, or adoption.
- The toolset does not automatically mutate the project's `.gitignore`. Treating the canonical Brief as untracked under `<ProjectRoot>/log/` is the standing assumption.

## Chatlog

- **Chatlog ≠ Brief.** Chatlog is the history / decision rationale / Brief reconstruction evidence area at `<ProjectRoot>/log/chatlog/`. It is **not** the current restore source and is **not** the default-restore target for a new session.
- The current restore source is **Brief** (`<ProjectRoot>/log/brief/BRIEF.md`).
- Chatlog may be consulted when Brief is missing, corrupted, or stale, as **reconstruction evidence only**. Chatlog is never promoted into Brief's seat.

## BF save / checkpoint protocol

Treat any of the following user phrases as manual save intent (Korean, verbatim):

- `현재 진행 지점을 복구 시점으로 저장해`
- `BF 저장해`
- `복구 지점 저장해`
- `handoff 지점 만들어줘`
- `다음 세션에서 이어갈 수 있게 정리해`
- `현재 phase checkpoint 남겨줘`

When detected:

1. Inspect repo state.
2. Update `<ProjectRoot>/log/brief/BRIEF.md` (canonical Brief — project-local runtime artifact, gitignored under `log/`) with current state, last completed action, next single action, do-not-do, pending user decision. The operator triggers and approves; the agent writes the file directly; the operator does not hand-edit it. Do not create `<ProjectRoot>/brief/` — that root location is rejected.
3. Keep Brief compact and reference review / evidence / Chatlog details by path only — do not inline review payloads, evidence body, or cumulative Chatlog content into Brief.
4. Report the updated file and any remaining risks.

These triggers exercise manual save discipline only. They do not invoke any deterministic writer, daemon, watcher, scheduler, or BF Level 3 automation.

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
- `.ps1` files must be UTF-8 with BOM + CRLF.
- When capturing a native executable's output for correctness checks (e.g. `powershell.exe`, `git`, `codex`), keep stdout, stderr, and exit code separate. `2>&1`, `Out-String`, `Out-Null`, and other merged-stream captures collapse the signal — under Windows PowerShell 5.1 with `$ErrorActionPreference = 'Stop'` they also abort the call before the exit code is read.
- Temporary files created solely for command execution should be cleaned up by the operator before closeout. Evidence, snapshots, logs, source changes, or user-requested artifacts are not temporary files.
<!-- END AI_HARNESS_TOOLSET_GLOBAL -->
