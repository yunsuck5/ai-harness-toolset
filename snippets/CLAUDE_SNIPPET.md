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
- The full marker-state apply policy is governed by `docs/roadmap/GLOBAL_ADOPTION_DECISION.md` §6.

## Role neutrality

This payload is loaded regardless of the agent's current role. The same agent may operate as **operator** (making changes, running `review-cycle.ps1`), **reviewer** (reading a prepared packet and emitting a verdict), **auditor**, or **supervisor**. Role-specific behavior is decided by `/goal`, the review input, the skill prompt, or the command invocation — not by this global payload.

- When acting as **reviewer** or **auditor**, treat only the role-neutral parts of this payload as binding: ToolRoot / ProjectRoot path concepts, reviewer artifact location (`<ProjectRoot>/log/review/<run-id>/`), verdict vocabulary, BRIEF semantics, the no-overwrite contract for global files, and the source-of-truth priority. Form any verdict from the artifact evidence in the prepared packet itself; do not treat operator-supplied summaries as a substitute for that evidence, and do not infer commit / push approval from a verdict.
- The operator-side protocols described below — BF save triggers, new-session restore-offer, `review-cycle.ps1` execution discipline — apply only when acting as **operator**. Do not perform them when reading a review packet, when auditing existing artifacts, or when supervising another agent's work.
- Nothing in this payload forces accept / approve. Nothing in it weakens reviewer independence. Nothing in it permits whole-file overwrite of a global instruction file.

## Project layout

Path layout uses two conceptual roots: `<ToolRoot>` is where the toolset's own
`scripts/`, `config/`, `templates/`, and `snippets/` live, and `<ProjectRoot>`
is the target project repo root. Toolset-owned source/config/template/snippet
files live under `<ToolRoot>`. Target-owned project files and runtime artifacts
live under `<ProjectRoot>`.

The toolset supports three modes. They differ only in where `<ToolRoot>` resolves
to.

- **Shared / global mode** — preferred direction. `<ToolRoot>` is independent of
  `<ProjectRoot>`. The default mechanism is a global stable install at
  `%USERPROFILE%\.claude\ai-harness-toolset\current`, materialized once and
  shared across projects. The `AI_HARNESS_TOOL_ROOT` environment variable is an
  override of that default — for debug / development validation, for example
  pointing at a development checkout of `ai-harness-toolset` — and is not the
  default mechanism. In either case the target project does not carry a copy of
  the toolset payload.
- **Project-local copy mode** — transitional / legacy. `<ToolRoot>` is
  `<ProjectRoot>/.ai-harness/`, a copied payload sitting alongside the
  target's own source. Still supported for backward compatibility but not the
  recommended adoption shape for new projects.
- **Self-target / dogfooding mode** — source repo operators only. `<ToolRoot>`
  and `<ProjectRoot>` are the same path (the `ai-harness-toolset` source repo
  itself). Target consumers do not use this mode.

`<ToolRoot>` is resolved per invocation in this channel order (see
`docs/roadmap/SHARED_GLOBAL_INVOCATION_CONTRACT.md` for the formal contract):
explicit `-ToolRoot` argument → `AI_HARNESS_TOOL_ROOT` env var (override / debug
/ development validation) → global stable install
`%USERPROFILE%\.claude\ai-harness-toolset\current` (absent skips to the next
channel; present but incomplete fails fast) → dogfooding multi-marker on
`<ProjectRoot>` → legacy `<ProjectRoot>/.ai-harness/` → explicit error. For the
AI-guided adoption / update procedure, see
`docs/roadmap/GLOBAL_ADOPTION_PROCEDURE.md`.

Runtime artifact paths under `<ProjectRoot>`:

- `<ProjectRoot>/log/` — runtime output root. `log/` must not be committed;
  ensure the target project's `.gitignore` includes it.
- `<ProjectRoot>/log/review/<run-id>/` — review records. Inspect them and
  report the verdict.
- Keep `log/review/`, `log/evidence/`, and `log/chatlog/` separate.

Reviewer config lives at `<ToolRoot>/config/reviewer.json`.

## Review flow

- Default user-facing entrypoint is the single-shot CLI `<ToolRoot>/scripts/review-cycle.ps1`. Run it once per user-triggered review request.
- `review-cycle.ps1` runs Codex CLI exactly once per call and stops.
- The component scripts `<ToolRoot>/scripts/review-prepare.ps1` and `<ToolRoot>/scripts/review-verify.ps1` are available for explicit, deliberate use (preparing a packet without immediately running Codex, or verifying an existing run). Stale review packets (any `targetFiles[]` entry whose SHA-256 changed since prepare) must fail.
- Reviewer artifacts live only under `<ProjectRoot>/log/review/<run-id>/`. Do not create a root `codex-review-input.md` or root `codex-review-result*.json`.

## Result verdict vocabulary

The only valid final verdict values for this toolset are exactly:

- `yes`
- `no`
- `yes with risk`

A reviewer verdict does not approve commit, push, publish, merge, release, upload, or adoption.

## Brief (BF Level 3)

- `<ProjectRoot>/log/brief/BRIEF.md` is the **operator-local durable restore state** (BF Level 3). The current operator — or a new AI agent session — reads it first as a local restore entrypoint when (re)starting work. It is not a shared project source-of-truth or a human handoff document.
- `<ProjectRoot>/log/chatlog/current/resume.md` is the **volatile current-session restore file** (BF Level 1/2). It lives at a different time scale than BRIEF.
- Both coexist. The toolset does not mirror between them. A human decides which side to update.
- `<ToolRoot>/templates/brief/BRIEF.md` is the source-side template. `<ToolRoot>/scripts/brief-init.ps1` seeds `<ProjectRoot>/log/brief/BRIEF.md` one-shot and refuses to overwrite an existing file. `<ToolRoot>/scripts/brief-check.ps1` validates BRIEF shape only (required heading set, no unfilled placeholders).
- `brief-check.ps1` PASS or FAIL is **not** a reviewer verdict. It does not approve or block commit, push, publish, merge, release, upload, or adoption.
- BRIEF is not a review input or a review output. It is not a commit gate, push gate, or release gate.
- BF Level 1/2 save triggers (see below) update `resume.md` / `summary.md` only. They do not auto-write `log/brief/BRIEF.md`. BF Level 3 is human-edited or seeded by an explicit `brief-init.ps1` call.
- `<ProjectRoot>/log/brief/BRIEF.md` is **operator-local runtime state** under `log/`. It is gitignored by default (via the `log/` rule) and is not a shared project source-of-truth. Root `<ProjectRoot>/brief/` is forbidden for ai-harness usage; the canonical BRIEF location is `log/brief/` only.
- The toolset does **not** automatically mutate the project's `.gitignore`. If an operator chooses to track `log/brief/BRIEF.md` explicitly, that is their decision and their responsibility.

## Chatlog (BF Level 1/2 and CL)

- Use `<ProjectRoot>/log/chatlog/current/resume.md` as the current BF Level 1/2 restore point.
- Use `<ProjectRoot>/log/chatlog/current/summary.md` as its compact companion.
- Treat other files under `<ProjectRoot>/log/chatlog/` as CL / history context, referenced only when needed.
- Keep BF Level 1/2 compact and reference review / evidence / CL details by path only.

## New session restore-offer

At the start of meaningful work, read in this order:

1. `<ProjectRoot>/log/brief/BRIEF.md` — operator-local durable restore state (BF Level 3).
2. `<ProjectRoot>/log/chatlog/current/resume.md` — current-session restore (BF Level 1/2).
3. `<ProjectRoot>/log/chatlog/current/summary.md` — compact companion / fallback.
4. Referenced review / evidence / CL artifacts only when BRIEF or `resume.md` points to them.

Then:

1. Summarize the restore point in Korean, covering current state, next single action, do-not-do, and pending user decision.
2. Ask the user whether to resume from that point. The canonical prompt is `이 복구 지점에서 이어서 진행할까요?`.
3. Proceed only after the user confirms.

Missing-file handling:

- If `log/brief/BRIEF.md` is missing, report the gap and fall back to `resume.md`.
- If `resume.md` is also missing, fall back to `summary.md`.
- If all three are missing, report no restore point and ask the user how to proceed.

## BF save / checkpoint protocol

Treat any of the following user phrases as BF Level 1/2 save intent (Korean, verbatim):

- `현재 진행 지점을 복구 시점으로 저장해`
- `BF 저장해`
- `복구 지점 저장해`
- `handoff 지점 만들어줘`
- `다음 세션에서 이어갈 수 있게 정리해`
- `현재 phase checkpoint 남겨줘`

When detected:

1. Inspect repo state.
2. Update `<ProjectRoot>/log/chatlog/current/resume.md` with current state, last completed action, next single action, do-not-do, pending user decision.
3. Update `<ProjectRoot>/log/chatlog/current/summary.md` as its compact companion.
4. Keep BF Level 1/2 compact and reference review / evidence / CL details by path only.
5. Report the updated files and any remaining risks.

These triggers update BF Level 1/2 only. They do **not** auto-write `log/brief/BRIEF.md`. BF Level 3 is human-edited; the toolset never auto-generates BRIEF content.

## Forbidden in this toolset

- No root `<ProjectRoot>/brief/` directory for ai-harness usage; BRIEF lives only under `log/brief/`.
- No per-user / per-operator log partitioning, operator-id, machine-id, or ownership metadata.
- No `BF_STATE.json` or sidecar state-machine file.
- No daemon, watcher, scheduler, hook, or background task.
- No implicit, automatic, or whole-file mutation of a global instruction file. Specifically: `%USERPROFILE%\.claude\CLAUDE.md` (Claude), `%USERPROFILE%\.codex\AGENTS.md` (Codex default), `%CODEX_HOME%\AGENTS.md` (Codex with `CODEX_HOME` set), `AGENTS.override.md` at the Codex user-global scope, and any project-root `CLAUDE.md` / `AGENTS.md`. Explicit user-approved managed-block insert / replace per `Adoption rules` is the one governed exception. No file is auto-created under `~/.claude/` or `~/.codex/`.
- No creation of `%USERPROFILE%\.claude\AGENTS.md`. That path is not a recognized global instruction location for any agent; ai-harness never writes to it.
- No automatic mirror between `log/brief/BRIEF.md` and `log/chatlog/current/resume.md`.
- No automatic target `.gitignore` mutation.

## Execution discipline

- Run lifecycle commands — `review-cycle.ps1` and its Codex review in particular — in the foreground, and wait for completion. Do not spawn detached background work, and do not run a review and other work in parallel.
- A timeout or budget is only an operating allowance for a foreground attempt; it is not a correctness guarantee. Never raise a timeout as a way to make a review "valid." Review validity is judged by complete run artifacts, valid result binding, and `review-verify -RequireResult` — not by how the run was launched.
- Review scope is set by the review purpose and the artifact boundary. Never shrink it artificially to avoid a long-running or background run.
- If the harness silently auto-converts a foreground run to background, do not report it as a clean foreground execution. Report that the auto-conversion happened.
- An auto-converted run is still acceptable as conditional review evidence only when the session waited for it with no parallel work, the run artifacts are complete, the result binding is valid, and `review-verify -RequireResult` passes. Output loss, incomplete artifacts, a missing result, stale binding, or a `review-verify` failure disqualifies it as closeout evidence.
- Background execution by itself does not invalidate review quality or result validity. What is forbidden is detached background work, parallel background work, silent (unreported) background conversion, evidence ambiguity, and output loss — not the conversion event alone.
- If a run leaves temp output clutter, report its path. Delete it only after separate explicit user approval.

## Other rules

- Commit and push require explicit user approval.
- `.ps1` files must be UTF-8 with BOM + CRLF.
<!-- END AI_HARNESS_TOOLSET_GLOBAL -->
