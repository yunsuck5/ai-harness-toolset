<!-- BEGIN AI_HARNESS_TOOLSET_GLOBAL -->
# ai-harness-toolset instructions for Codex / generic agents

This is a manually adopted AI instruction payload for Codex CLI and other agent-style assistants. The user has copied it into the destination `AGENTS.md` (project root or global) inside a managed block delimited by `<!-- BEGIN AI_HARNESS_TOOLSET_GLOBAL -->` and `<!-- END AI_HARNESS_TOOLSET_GLOBAL -->`. Treat its content as authoritative for ai-harness workflows in this project.

## Adoption rules

- This payload is inserted only inside the managed block in root `AGENTS.md`.
- Whole-file overwrite of root `AGENTS.md` is forbidden.
- Project-specific instructions outside the managed block must be preserved verbatim.
- Updating means replacing only the managed block content; removing means deleting only the managed block.

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

1. Summarize the restore point in Korean, covering current state, next single action, do-not-do, and pending user decision. The human-facing summary must be in Korean so the human reader can pick up immediately; agent-internal reasoning may be in any language.
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
- No global `CLAUDE.md` mutation.
- No global `AGENTS.md` mutation.
- No `~/.claude/` mutation.
- No automatic mirror between `log/brief/BRIEF.md` and `log/chatlog/current/resume.md`.
- No automatic target `.gitignore` mutation.

## Other rules

- Commit and push require explicit user approval.
- `.ps1` files must be UTF-8 with BOM + CRLF.
<!-- END AI_HARNESS_TOOLSET_GLOBAL -->
