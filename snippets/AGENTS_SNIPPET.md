<!-- BEGIN AI_HARNESS_TOOLSET_GLOBAL -->
# ai-harness-toolset instructions for Codex / generic agents

This is a manually adopted AI instruction payload for Codex CLI and other agent-style assistants. The user has copied it into the destination `AGENTS.md` (project root or global) inside a managed block delimited by `<!-- BEGIN AI_HARNESS_TOOLSET_GLOBAL -->` and `<!-- END AI_HARNESS_TOOLSET_GLOBAL -->`. Treat its content as authoritative for ai-harness workflows in this project.

## Adoption rules

- This payload is inserted only inside the managed block in root `AGENTS.md`.
- Whole-file overwrite of root `AGENTS.md` is forbidden.
- Project-specific instructions outside the managed block must be preserved verbatim.
- Updating means replacing only the managed block content; removing means deleting only the managed block.

## Project layout

- `.ai-harness/` is the project-local, copy-only payload. No global files are modified.
- Runtime output root is `<project-root>/log/`. `log/` must not be committed; ensure the target project's `.gitignore` includes it.
- Review records live at `log/review/<run-id>/`. Inspect them and report the verdict.
- Keep `log/review/`, `log/evidence/`, and `log/chatlog/` separate.
- Reviewer config comes from `.ai-harness/config/reviewer.json`.

## Review flow

- Default user-facing entrypoint is the single-shot CLI `.ai-harness/scripts/review-cycle.ps1`. Run it once per user-triggered review request.
- `review-cycle.ps1` runs Codex CLI exactly once per call and stops.
- The component scripts `.ai-harness/scripts/review-prepare.ps1` and `.ai-harness/scripts/review-verify.ps1` are available for explicit, deliberate use (preparing a packet without immediately running Codex, or verifying an existing run). Stale review packets (any `targetFiles[]` entry whose SHA-256 changed since prepare) must fail.
- Reviewer artifacts live only under `log/review/<run-id>/`. Do not create a root `codex-review-input.md` or root `codex-review-result*.json`.

## Result verdict vocabulary

The only valid final verdict values for this toolset are exactly:

- `yes`
- `no`
- `yes with risk`

A reviewer verdict does not approve commit, push, publish, merge, release, upload, or adoption.

## Brief (BF Level 3)

- `<project-root>/brief/BRIEF.md` is the **durable project restore file** (BF Level 3). A new collaborator or a new agent reads it first to understand the project.
- `log/chatlog/current/resume.md` is the **volatile current-session restore file** (BF Level 1/2). It lives at a different time scale than BRIEF.
- Both coexist. The toolset does not mirror between them. A human decides which side to update.
- `.ai-harness/templates/brief/BRIEF.md` is the source-side template. `.ai-harness/scripts/brief-init.ps1` seeds `<project-root>/brief/BRIEF.md` one-shot and refuses to overwrite an existing file. `.ai-harness/scripts/brief-check.ps1` validates BRIEF shape only (required heading set, no unfilled placeholders).
- `brief-check.ps1` PASS or FAIL is **not** a reviewer verdict. It does not approve or block commit, push, publish, merge, release, upload, or adoption.
- BRIEF is not a review input or a review output. It is not a commit gate, push gate, or release gate.
- BF Level 1/2 save triggers (see below) update `resume.md` / `summary.md` only. They do not auto-write `brief/BRIEF.md`. BF Level 3 is human-edited or seeded by an explicit `brief-init.ps1` call.
- `<project-root>/brief/BRIEF.md` is expected to be **tracked by default** in the target repo so a fresh clone has the durable restore file available.
- The toolset does **not** automatically mutate the target project's `.gitignore`. The adopter decides tracked-vs-ignored.
- If a target repo currently ignores `brief/`, treat that as a target adoption policy decision and report it as such. Do not classify it as a `brief-init.ps1` or `brief-check.ps1` failure.

## Chatlog (BF Level 1/2 and CL)

- Use `log/chatlog/current/resume.md` as the current BF Level 1/2 restore point.
- Use `log/chatlog/current/summary.md` as its compact companion.
- Treat other files under `log/chatlog/` as CL / history context, referenced only when needed.
- Keep BF Level 1/2 compact and reference review / evidence / CL details by path only.

## New session restore-offer

At the start of meaningful work, read in this order:

1. `<project-root>/brief/BRIEF.md` — durable project restore (BF Level 3).
2. `log/chatlog/current/resume.md` — current-session restore (BF Level 1/2).
3. `log/chatlog/current/summary.md` — compact companion / fallback.
4. Referenced review / evidence / CL artifacts only when BRIEF or `resume.md` points to them.

Then:

1. Summarize the restore point in Korean, covering current state, next single action, do-not-do, and pending user decision. The human-facing summary must be in Korean so the human reader can pick up immediately; agent-internal reasoning may be in any language.
2. Ask the user whether to resume from that point. The canonical prompt is `이 복구 지점에서 이어서 진행할까요?`.
3. Proceed only after the user confirms.

Missing-file handling:

- If `brief/BRIEF.md` is missing, report the gap and fall back to `resume.md`.
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
2. Update `log/chatlog/current/resume.md` with current state, last completed action, next single action, do-not-do, pending user decision.
3. Update `log/chatlog/current/summary.md` as its compact companion.
4. Keep BF Level 1/2 compact and reference review / evidence / CL details by path only.
5. Report the updated files and any remaining risks.

These triggers update BF Level 1/2 only. They do **not** auto-write `brief/BRIEF.md`. BF Level 3 is human-edited; the toolset never auto-generates BRIEF content.

## Forbidden in this toolset

- No source repo root `brief/` runtime state.
- No `log/brief/`.
- No `BF_STATE.json` or sidecar state-machine file.
- No daemon, watcher, scheduler, hook, or background task.
- No global `CLAUDE.md` mutation.
- No global `AGENTS.md` mutation.
- No `~/.claude/` mutation.
- No automatic mirror between `brief/BRIEF.md` and `log/chatlog/current/resume.md`.
- No automatic target `.gitignore` mutation.

## Other rules

- Commit and push require explicit user approval.
- `.ps1` files must be UTF-8 with BOM + CRLF.
<!-- END AI_HARNESS_TOOLSET_GLOBAL -->
