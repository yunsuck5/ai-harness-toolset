<!-- BEGIN AI_HARNESS_TOOLSET_GLOBAL -->
# ai-harness-toolset instructions for CLAUDE.md-compatible agents

This is a manually adopted AI instruction payload for Claude Code and other CLAUDE.md-compatible agent assistants. The user has copied it into the destination `CLAUDE.md` inside a managed block delimited by `<!-- BEGIN AI_HARNESS_TOOLSET_GLOBAL -->` and `<!-- END AI_HARNESS_TOOLSET_GLOBAL -->`. Treat its content as authoritative for ai-harness workflows in this project.

## Adoption destination

The valid destinations for this payload are exactly:

- **Project-root `CLAUDE.md`** — `<ProjectRoot>/CLAUDE.md`.
- **User-global Claude `CLAUDE.md`** — `%USERPROFILE%\.claude\CLAUDE.md`.

The forbidden destination is `%USERPROFILE%\.claude\AGENTS.md`. That path is not a recognized global instruction location for any agent, and ai-harness must never create it. The Codex user-global instruction path is `%USERPROFILE%\.codex\AGENTS.md` by default, or `%CODEX_HOME%\AGENTS.md` if `CODEX_HOME` is set, and is the destination for `snippets/AGENTS_SNIPPET.md` — it is not under `.claude\`.

## Adoption rules

- This payload lives only inside the `AI_HARNESS_TOOLSET_GLOBAL` managed block of one of the destinations above. Replacing the content inside that managed block is the standard, allowed way to adopt or update it.
- Whole-file overwrite of either destination is forbidden. Content outside the managed block — project-specific or user instructions — must be preserved verbatim.
- Adopting or updating this payload in any destination above is an explicit, user-approved global / user config mutation, never an implicit or automatic action.
- If the marker pair is already present, only the block between the markers may be replaced. Inserting the block into an existing file that has no marker, and creating a missing destination file, are each separate explicit-approval boundaries.
- An incomplete marker pair, duplicated markers, or a malformed block is a fail-fast / manual-review condition: stop and do not edit the file.

## Role neutrality

This payload is loaded regardless of the agent's current role. The same agent may operate as **operator** (making changes, running `review-prepare.ps1` / `review-run.ps1`), **reviewer** (reading a prepared packet and emitting a verdict), **auditor**, or **supervisor**. Role-specific behavior is decided by `/goal`, the review input, the skill prompt, or the command invocation — not by this global payload.

- When acting as **reviewer** or **auditor**, treat only the role-neutral parts of this payload as binding: ToolRoot / ProjectRoot path concepts, reviewer artifact location (`<ProjectRoot>/log/review/<review-task-id>/pass-NN/`), verdict vocabulary, BRIEF semantics, the no-overwrite contract for global files, and the source-of-truth priority. Form any verdict from the artifact evidence in the prepared packet itself; do not treat operator-supplied summaries as a substitute for that evidence, and do not infer commit / push approval from a verdict.
- The operator-side protocols described below — BF save triggers, new-session restore-offer, `review-prepare` / `review-run` execution discipline — apply only when acting as **operator**.
- Nothing in this payload forces accept / approve. Nothing in it weakens reviewer independence. Nothing in it permits whole-file overwrite of a global instruction file.

## Project layout

`<ToolRoot>` is where the toolset's own `scripts/`, `config/`, `templates/`, and `snippets/` live. `<ProjectRoot>` is the target project repo root. Toolset-owned files live under `<ToolRoot>`; target-owned project files and runtime artifacts live under `<ProjectRoot>`.

`<ToolRoot>` is resolved per invocation in this channel order: explicit `-ToolRoot` argument → `AI_HARNESS_TOOL_ROOT` env var (override) → global stable install `%USERPROFILE%\.claude\ai-harness-toolset\current` (absent skips to the next channel; present but incomplete fails fast) → `<ProjectRoot>/.ai-harness/` fallback → explicit error.

Runtime artifact paths under `<ProjectRoot>`:

- `<ProjectRoot>/log/` — runtime output root. `log/` must not be committed; ensure the target project's `.gitignore` includes it.
- `<ProjectRoot>/log/review/<review-task-id>/pass-NN/` — canonical review record. Inspect `input.md` + `result.md` and report the verdict.
- Keep `log/review/`, `log/evidence/`, and `log/chatlog/` separate.

Reviewer config lives at `<ToolRoot>/config/reviewer.json`.

## Review flow

- The canonical operator entry points are two scripts, called in order: `<ToolRoot>/scripts/review-prepare.ps1 -ReviewTaskId <id> [-Pass <pass-NN>] -Stage <stage> -Purpose <line>` allocates the pass directory and seeds `input.md`; then `<ToolRoot>/scripts/review-run.ps1 -ReviewTaskId <id> -Pass <pass-NN>` runs Codex CLI exactly once and writes `result.md`.
- `<ToolRoot>/scripts/review-verify.ps1 -ReviewTaskId <id> -Pass <pass-NN> [-RequireResult]` is the post-hoc canonical-artifact check. It does not invoke Codex.
- Reviewer artifacts live only under `<ProjectRoot>/log/review/<review-task-id>/pass-NN/`, as the two canonical files `input.md` + `result.md`. Do not create root-level review inputs or results outside that pass directory, and do not invent sidecar JSON, hash-binding files, or external staging folders. Anything beyond the canonical pair is outside the contract.
- Bash callers may invoke `<ToolRoot>/scripts/review-{prepare,run,verify}.sh` as thin adapters that forward to the canonical `.ps1`; they accept the same PowerShell-style parameters (`-ReviewTaskId`, `-Pass`, `-Stage`, `-Purpose`, `-ProjectRoot`, `-ToolRoot`, `-RequireResult`) — no Bash-style long options. The `.ps1` files remain the canonical implementation; the `.sh` adapters are not part of the channel 3 payload completeness marker.
- When `input.md` makes validation execution claims (e.g., Pester pass count, `verify-ps1` PASS, `git diff --check` clean), the operator may reference a Markdown evidence file at `<ProjectRoot>/log/evidence/<scope>/<case>/validation-evidence.md` from `input.md`'s `## Validation evidence` informational section so the reviewer can read its body in the read-only sandbox. This evidence is reviewer-readable runtime supporting material — not command re-execution, not deterministic truth oracle, not freshness binding, not source-of-truth, and not a sidecar inside the pass directory. The `## Validation evidence` referencing target is a **single Markdown bundle** (`validation-evidence.md`). Multi-file evidence forms (a case directory holding `command.txt` / `exit-code.txt` / `stdout.txt` / `stderr.txt` / `notes.md`) remain valid as general evidence but are not the `## Validation evidence` referencing target; if a reviewer must inspect such a case directory, list its path under `## Required inspection paths` instead.
- `input.md` carries a `## Known concerns` informational section where the operator must pre-disclose every compromise / convention deviation / skipped alternative / baseline failure / validation limitation / operator assumption known before invoking Codex; omission of a known concern invalidates the verdict for commit/push judgment ex-post — the verdict becomes stale-by-omission and a new review pass with the omitted concerns disclosed is required. `## Review questions` should use neutral, open-ended phrasing rather than confirmation-seeking, and should include a final recommended question asking the reviewer to flag any framing tilt in `## Notes`. Verdict meaning is narrowed: `yes` = no blocking finding (not commit/push approval), `no` = blocking finding exists, `yes with risk` = no blocking finding but disclosed risks require explicit supervisor/user acceptance before commit/push (not the automatic equivalent of `yes`). Reviewer `result.md` must carry `## Blocking findings`, `## Non-blocking concerns`, `## Review limitations`, and `## Assumptions relied on` — each exactly once (parser-enforced by `scripts/review-verify.ps1 -RequireResult`); a section with no substance uses the literal body `none`.

## Result verdict vocabulary

The only valid final verdict values for this toolset are exactly:

- `yes`
- `no`
- `yes with risk`

A reviewer verdict does not approve commit, push, publish, merge, release, upload, or adoption. `yes` means no blocking finding in the reviewed scope and the user still decides the next step; `no` means a blocking finding exists and a corrective action is needed (classify whether the fix is within or outside the approved scope before acting); `yes with risk` means no blocking finding but disclosed risks require explicit user / supervisor risk acceptance before commit / push — it is not the automatic equivalent of `yes`. Detailed verdict → next-action mapping and result-consumption guidance live in `snippets/claude-skills/ai-harness-review/SKILL.md` step 6 + step 7 and `docs/contracts/review/REVIEW_RESULT_CONTRACT.md` §6a — they are intentionally not duplicated here.

## Brief

- **Brief** is a project's durable restore source-of-truth. The current operator — or a new AI agent session — reads it first as a local restore entrypoint when (re)starting work. It is not a shared project handoff document.
- **Canonical Brief** = `<ProjectRoot>/log/brief/BRIEF.md`. That single path is the canonical reading position for any session. It is a project-local, operator-local runtime artifact under `<ProjectRoot>/log/` (gitignored by default and not a commit / push target).
- **Rejected locations**: root `<ProjectRoot>/brief/BRIEF.md` is not the canonical Brief. Any user-home operator-local runtime root is also not the canonical Brief.
- The operator is the trigger / approve / reject / discard owner and does not hand-edit the Brief. Brief content is written or updated by the agent (an explicit AI-assisted command flow on operator trigger) or by deterministic tooling.
- BF Level 3 — automated Brief management — is not implemented in this toolset. Do not claim that capability.
- Brief shape validation is a narrow primitive only. It is not a reviewer verdict and does not approve or block commit, push, merge, release, or adoption.
- The toolset does not automatically mutate the project's `.gitignore`. Treating the canonical Brief as untracked under `<ProjectRoot>/log/` is the standing assumption.

## Chatlog

- **Chatlog ≠ Brief.** Chatlog is the history / decision rationale / Brief reconstruction evidence area at `<ProjectRoot>/log/chatlog/`. It is **not** the current restore source and is **not** the default-restore target for a new session.
- The current restore source is **Brief** (`<ProjectRoot>/log/brief/BRIEF.md`).
- Chatlog may be consulted when Brief is missing, corrupted, or stale, as **reconstruction evidence only**. Chatlog is never promoted into Brief's seat.

## New session restore-offer

> **Reviewer-mode exclusion.** This restore-offer protocol is **operator-mode only**. When acting as a reviewer — for example the Codex reviewer invoked by `review-run.ps1` with a prepared `log/review/<review-task-id>/pass-NN/input.md` — do **not** perform any step below: do not read or require `BRIEF.md`, do not treat its absence as a reason to pause, and do not ask any restore / session / clarification question. In reviewer mode the review-result contract takes precedence over this protocol — produce the canonical `result.md` verdict instead (exactly one `## Verdict` heading with `yes` / `no` / `yes with risk`, and the four required disclosure H2s `## Blocking findings` / `## Non-blocking concerns` / `## Review limitations` / `## Assumptions relied on` each exactly once with `none` as the body when empty; if evidence is insufficient, return `no` or `yes with risk` with the gap recorded under the appropriate disclosure section, never a question).

At the start of meaningful work, read the canonical Brief at `<ProjectRoot>/log/brief/BRIEF.md`. This is the single canonical location — there is no fallback location and no read-order chain. Do not look for or read `<ProjectRoot>/brief/BRIEF.md` (rejected) or any user-home operator-local runtime root. Referenced review / evidence / Chatlog artifacts are read only when the canonical Brief points to them.

Then:

1. Summarize the restore point in Korean, covering current state, next single action, do-not-do, and pending user decision.
2. Ask the user whether to resume from that point. The canonical prompt is `이 복구 지점에서 이어서 진행할까요?`.
3. Proceed only after the user confirms.

Missing-file handling:

- If `<ProjectRoot>/log/brief/BRIEF.md` is missing, do **not** default-restore from Chatlog. Report the absence and ask the user how to proceed. If the user explicitly asks for reconstruction from Chatlog, treat Chatlog as evidence and produce a draft Brief for the user's review rather than restoring blindly. Do not write a fresh Brief without user confirmation.

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

## Execution discipline

- Run lifecycle commands — `review-prepare.ps1` / `review-run.ps1` and the Codex review in particular — in the foreground, and wait for completion. Do not spawn detached background work, and do not run a review and other work in parallel.
- A timeout or budget is only an operating allowance for a foreground attempt; it is not a correctness guarantee. Never raise a timeout as a way to make a review "valid." Review validity is judged by complete run artifacts, valid result binding, and `review-verify -RequireResult` — not by how the run was launched.
- Review scope is set by the review purpose and the artifact boundary. Never shrink it artificially to avoid a long-running or background run.
- If the harness silently auto-converts a foreground run to background, do not report it as a clean foreground execution. Report that the auto-conversion happened.
- An auto-converted run is still acceptable as conditional review evidence only when the session waited for it with no parallel work, the run artifacts are complete, the result binding is valid, and `review-verify -RequireResult` passes. Output loss, incomplete artifacts, a missing result, stale binding, or a `review-verify` failure disqualifies it as closeout evidence.
- If a run leaves temp output clutter, report its path. Delete it only after separate explicit user approval.

## Other rules

- Commit and push require explicit user approval.
- `.ps1` files must be UTF-8 with BOM + CRLF.
- When capturing a native executable's output for correctness checks (e.g. `powershell.exe`, `git`, `codex`), keep stdout, stderr, and exit code separate. `2>&1`, `Out-String`, `Out-Null`, and other merged-stream captures collapse the signal — under Windows PowerShell 5.1 with `$ErrorActionPreference = 'Stop'` they also abort the call before the exit code is read. Detailed semantics: `docs/policies/POWERSHELL_POLICY.md`.
<!-- END AI_HARNESS_TOOLSET_GLOBAL -->
