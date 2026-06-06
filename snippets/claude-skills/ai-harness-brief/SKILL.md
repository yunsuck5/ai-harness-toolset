---
name: ai-harness-brief
description: Owns the ai-harness-toolset manual Brief workflow (BF Level 1/2) — explicit-prompt save / checkpoint / user-requested restore / update of the canonical Brief (<ProjectRoot>/log/brief/BRIEF.md). Trigger on explicit user intents to save or checkpoint a recovery point (e.g. "BF 저장해", "복구 지점 저장해", "현재 진행 지점을 복구 시점으로 저장해", "handoff 지점 만들어줘", "다음 세션에서 이어갈 수 있게 정리해", "현재 phase checkpoint 남겨줘"), to restore from the Brief (e.g. "브리프로 세션 복원해", "이 복구 지점에서 이어서 진행할까"), or to update the Brief. Explicit-prompt only — NOT an unsolicited session-start restore-offer (discarded) — and operator-mode only (never reviewer mode). The agent writes the Brief body; the operator triggers / approves / rejects / discards and does not hand-edit it.
---

# ai-harness-brief

This skill owns the ai-harness-toolset **manual Brief workflow** — explicit-prompt **save / checkpoint**, **user-requested restore**, and **update** of the project's canonical Brief. It is the procedure home for the current BF Level 1/2 manual-discipline capabilities. **Discovery / trigger is owned by this skill's `description`** (Claude Code matches skills by their description) — the always-loaded snippet does **not** carry a routing pointer to this skill and is not required for it to fire.

Operating model: the **operator** is the trigger / approve / reject / discard owner and does **not** hand-edit the Brief; the **agent** (you) writes the Brief body on the operator's trigger. BF Level 3 automation (deterministic writer, stale warning, session-start guidance) is **deferred and out of scope** — `docs/systems/brief/DEFERRED.md` (BR-D-01 / BR-D-03).

Canonical Brief = the single path `<ProjectRoot>/log/brief/BRIEF.md` — a project-local, operator-local, gitignored runtime artifact under `log/`, **never** a commit / push target and **not** a shared handoff document. Root `<ProjectRoot>/brief/` and any user-home operator-local runtime root are **rejected** locations; there is no fallback location. The canonical heading set, BF Level definitions, and shape contract live in `docs/contracts/brief/BRIEF_CONTRACT.md` (and the seed template `templates/brief/BRIEF.md`) — this skill does not restate them.

## When this skill applies

- **Explicit-prompt only.** Trigger only on an explicit user save / checkpoint / restore / update intent (the `description` lists the canonical phrases). There is **no** situation trigger and **no** unsolicited session-start restore-offer — that auto-offer is discarded (`docs/systems/skills/FUNCTION_LEVEL_SKILL_ARCHITECTURE_PLAN.md` §3; `docs/systems/brief/DEFERRED.md` BR-D-02 retired). Do not read or offer to restore the Brief on your own initiative at session start.
- **Operator-mode only — reviewer-mode exclusion.** Never run this workflow in reviewer mode. A reviewer invoked with a prepared `log/review/<review-task-id>/<perspective>/pass-NN/input.md` does **not** read or require `BRIEF.md`, does not pause for a missing Brief, and does not ask a restore / session / clarification question — it produces the canonical review `result.md` verdict instead.
- **Not a gate.** The Brief is neither input nor output of the review subsystem and does not gate commit / push / merge / release. `brief-check.ps1` PASS/FAIL is a shape result, not a verdict and not a commit approval.

## Save / checkpoint

Triggered by an explicit save / checkpoint intent (e.g. `BF 저장해`, `복구 지점 저장해`, `현재 진행 지점을 복구 시점으로 저장해`, `handoff 지점 만들어줘`, `다음 세션에서 이어갈 수 있게 정리해`, `현재 phase checkpoint 남겨줘`).

1. Inspect repo state (e.g. `git status`, the current `/goal` / task, open risks).
2. Write the canonical Brief at `<ProjectRoot>/log/brief/BRIEF.md`, filling the canonical required headings (the heading set is owned by `docs/contracts/brief/BRIEF_CONTRACT.md` / `templates/brief/BRIEF.md` — at minimum: current state, last completed action, next single action, do-not-do, pending user decision). If the Brief does not exist yet, seed it first with `scripts/brief-init.ps1` (which writes the template to the canonical path; it refuses to overwrite an existing Brief), then fill the sections. The agent writes the file directly; the operator does not hand-edit it. Do **not** create `<ProjectRoot>/brief/` — that root location is rejected.
3. Keep the Brief **compact**: reference review / evidence / Chatlog details by **path only** — do not inline review payloads, evidence bodies, or cumulative Chatlog content.
4. Report the updated file path and any remaining risks.

A save is a **manual** discipline only: it invokes no deterministic writer, daemon, watcher, scheduler, or BF Level 3 automation.

## User-requested restore

Triggered only when the user **explicitly** asks to restore (e.g. `브리프로 세션 복원해`, `이 복구 지점에서 이어서 진행할까`). Never an unsolicited session-start offer.

1. Confirm the canonical Brief exists at `<ProjectRoot>/log/brief/BRIEF.md` (single location; no fallback). `scripts/brief-status.ps1` is an optional read-only deterministic input — it reports file presence + shape (delegated to `brief-check.ps1`) + the first non-empty line of each required heading with a Korean label. Reading the Brief body directly and summarizing it is equally valid; the helper is not mandatory, and call-timing / confirm UX / staleness judgment remain yours, not the helper's.
2. Summarize the restore point in **Korean**: current state, next single action, do-not-do, and pending user decision.
3. Ask the user `이 복구 지점에서 이어서 진행할까요?`.
4. Proceed **only after** the user confirms.

**Missing-file handling.** If `<ProjectRoot>/log/brief/BRIEF.md` is missing, do **not** default-restore from Chatlog. Report the absence and ask how to proceed. Only if the user explicitly asks for reconstruction from Chatlog, treat Chatlog (`<ProjectRoot>/log/chatlog/`) as **evidence** and produce a **draft** Brief for the user's review — do not author a fresh Brief or restore blindly. Chatlog is never promoted into Brief's seat.

## Update

Triggered by an explicit update intent. Update the existing canonical Brief in place using the same write discipline as save (agent writes; operator does not hand-edit; compact; path-only references; canonical headings). Do not relocate the Brief or change its shape contract — the shape is owned by `BRIEF_CONTRACT.md`.

## Source-side primitives

- `scripts/brief-init.ps1` — seed the canonical Brief once from `templates/brief/BRIEF.md`; refuses to overwrite an existing Brief. Use before the first save when no Brief exists.
- `scripts/brief-check.ps1` — read-only shape check (8 canonical headings present, no duplicate / empty required section, no leftover `{{TOKEN}}` / sentinel). PASS/FAIL is a shape result only — not a verdict, not a commit gate.
- `scripts/brief-status.ps1` — read-only restore-summary input (presence + delegated shape + per-heading first line with Korean labels). Optional deterministic input for restore; it does not automate call-timing or confirm UX.

This skill does not change the behavior of these primitives.

## Boundaries

- No hand-edited Brief; the operator triggers / approves / rejects / discards and the agent writes the body.
- No daemon / watcher / scheduler / hook / background task; no `BF_STATE.json`-style state file; no `.gitignore` mutation; no BF Level 3 writer (deferred).
- No unsolicited session-start restore-offer (discarded — situation triggers are out of scope).
- No commit / push / publish / merge / release — those are separate explicit user decisions; this skill never runs them.
- No automatic Brief↔Chatlog mirror.

## Authoritative references (single homes — not restated here)

- **Brief contract** (responsibilities, canonical path, BF Levels, heading set, primitive contracts): `docs/contracts/brief/BRIEF_CONTRACT.md`.
- **Brief template** (canonical heading set + per-section guidance): `templates/brief/BRIEF.md`.
- **Brief system status + deferred BF Level 3 items:** `docs/systems/brief/STATUS.md`, `docs/systems/brief/DEFERRED.md`.
- **Chatlog boundary** (Brief↔Chatlog separation, reconstruction-evidence role): `docs/contracts/chatlog/CHATLOG_CONTRACT.md`.
