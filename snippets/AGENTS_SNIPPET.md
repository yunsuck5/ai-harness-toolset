# ai-harness-toolset instructions for Codex / generic agents

This is a manually adopted AI instruction payload for Codex CLI and other agent-style assistants. The user has copied it into the project root `AGENTS.md` inside a managed block delimited by `<!-- BEGIN ai-harness-toolset:AGENTS_SNIPPET.md -->` and `<!-- END ai-harness-toolset:AGENTS_SNIPPET.md -->`. Treat its content as authoritative for ai-harness workflows in this project.

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

A reviewer verdict does not approve commit, push, publish, merge, or release.

## Chatlog (BF and CL)

- Use `log/chatlog/current/resume.md` as the current BF restore point.
- Use `log/chatlog/current/summary.md` as its compact companion.
- Treat other files under `log/chatlog/` as CL / history context, referenced only when needed.
- Keep BF compact and reference review / evidence / CL details by path only.

## New session restore-offer

At the start of meaningful work:

1. Read `log/chatlog/current/resume.md` if it exists.
2. Summarize the restore point in Korean, covering current state, next single action, do-not-do, and pending user decision. The summary must be in Korean so the human reader can pick up immediately; agent-internal reasoning may be in any language.
3. Ask the user whether to resume from that point.
4. Proceed only after the user confirms.
5. If `resume.md` is missing, fall back to `summary.md` and report the gap.

## BF save / checkpoint protocol

Treat any of the following user phrases as BF save intent (Korean, verbatim):

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
4. Keep BF compact and reference review / evidence / CL details by path only.
5. Report the updated files and any remaining risks.

## Other rules

- Commit and push require explicit user approval.
- `.ps1` files must be UTF-8 with BOM + CRLF.
