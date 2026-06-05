---
name: ai-harness-brief
description: Reserved on-demand skill (Batch 2C-1 skeleton) for the ai-harness-toolset manual Brief workflow — save / checkpoint / user-requested restore / update of the canonical Brief (<ProjectRoot>/log/brief/BRIEF.md). It is the designated future home for those explicit-prompt intents (e.g. "BF 저장해", "복구 지점 저장해", "현재 진행 지점을 복구 시점으로 저장해", "handoff 지점 만들어줘", "다음 세션에서 이어갈 수 있게 정리해", "현재 phase checkpoint 남겨줘", "브리프로 세션 복원해", "save a recovery point", "restore from the brief"), but it carries NO procedure yet. Until Batch 2C-2 extracts the steps and routes the snippet to it, the always-loaded snippet still owns and handles the Brief workflow and this skeleton only points back to it. Explicit-prompt only — never an unsolicited session-start restore-offer (discarded) — and operator-mode only (never reviewer mode).
---

# ai-harness-brief

This skill is the **reserved** on-demand home (a Batch 2C-1 skeleton — see the Status section below) for the ai-harness-toolset **manual Brief workflow** — save / checkpoint / **user-requested** restore / update of the project's canonical Brief. That workflow covers the current BF Level 1/2 manual-discipline capabilities: the operator triggers / approves / rejects / discards, the agent writes the Brief body, and the operator does **not** hand-edit it. BF Level 3 automation (deterministic writer, stale warning, session-start guidance) is **deferred and out of scope** here — `docs/systems/brief/DEFERRED.md` (BR-D-01 / BR-D-03).

The canonical Brief is the single path `<ProjectRoot>/log/brief/BRIEF.md` — a project-local, operator-local, gitignored runtime artifact under `log/`, **not** a commit / push target and **not** a shared handoff document. Root `<ProjectRoot>/brief/` and any user-home operator-local runtime root are **rejected** locations.

## Status — Batch 2C-1 skeleton (procedure not yet extracted)

This file is the **minimal deployed skill surface** created in Batch 2C-1. It reserves the `ai-harness-brief` skill so the install / update / uninstall lifecycle force-mirrors and finally verifies it at its runtime destination (`<ClaudeHome>/skills/ai-harness-brief/SKILL.md`), per the generic deployed-extension activation-surface model that landed in Batch 2C-0 (`docs/systems/install-update/GLOBAL_INSTALL_UPDATE_MODEL.md` §8A).

The detailed step-by-step save / checkpoint / restore / update procedure is **not yet here**. Extracting it from the always-loaded snippet into this skill is **Batch 2C-2** — a separate scoped goal + Codex review + explicit approval. Until 2C-2 lands:

- The authoritative procedure remains in the **always-loaded snippet** — its `## Brief` and `## BF save / checkpoint protocol` sections (`snippets/CLAUDE_SNIPPET.md` / `snippets/AGENTS_SNIPPET.md`). Follow that procedure; this skeleton does **not** restate or replace it.
- The snippet's explicit-prompt trigger routing is unchanged. Creating this source skill adds **no** new runtime behavior on its own (it is inert until installed, and 2C-2 is what routes the snippet to it).

## Scope and boundaries

- **Explicit-prompt only.** The capabilities are the manual save / checkpoint phrases, an explicit user-requested restore, and an explicit update. There is **no** situation trigger and **no** unsolicited session-start restore-offer — that auto-offer is discarded (`docs/systems/skills/FUNCTION_LEVEL_SKILL_ARCHITECTURE_PLAN.md` §3; `docs/systems/brief/DEFERRED.md` BR-D-02 retired).
- **Operator-mode only.** This skill is never invoked in reviewer mode.
- **No hand-edited Brief, no automation.** No daemon / watcher / scheduler / hook, no `.gitignore` mutation, no `BF_STATE.json`-style state file, no BF Level 3 writer (deferred).
- **Not a review / commit / push gate.** The Brief is neither input nor output of the review subsystem and does not gate commit / push / release.

## Authoritative references (single homes — not restated here)

- **Brief contract** (responsibilities, canonical path, BF Levels, heading set): `docs/contracts/brief/BRIEF_CONTRACT.md`.
- **Brief template** (canonical heading set + per-section guidance): `templates/brief/BRIEF.md`.
- **Brief system status + deferred BF Level 3 items:** `docs/systems/brief/STATUS.md`, `docs/systems/brief/DEFERRED.md`.
- **Source-side primitives:** `scripts/brief-init.ps1` (seed), `scripts/brief-check.ps1` (shape check), `scripts/brief-status.ps1` (restore-summary input).

This skeleton intentionally does **not** re-describe the Brief heading set or the BF Level definitions — those live in the references above (single-home-plus-pointers).
