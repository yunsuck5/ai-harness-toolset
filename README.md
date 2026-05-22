# ai-harness-toolset

Project-local deterministic toolset for Claude / Codex workflows.

ai-harness-toolset is a project-local deterministic toolset. It is not an orchestrator, not an installer, and not packaged. Operation is CLI-only. The current adoption model is the **shared / global stable runtime ToolRoot** (channel 3): lifecycle scripts run from a global stable install at `%USERPROFILE%\.claude\ai-harness-toolset\current`, resolved per invocation, and runtime output is written under the target project's `<project-root>/log/`. A legacy project-local copy mode (channel 5), in which the source folders are copied into a `.ai-harness/` payload at the target project root, remains supported for backward compatibility but is not the recommended adoption shape for new projects.

> **Current adoption model.** The current adoption and default direction is the **shared / global stable runtime ToolRoot** — channel 3, the global stable install at `%USERPROFILE%\.claude\ai-harness-toolset\current`, resolved per invocation (see `docs/roadmap/SHARED_GLOBAL_INVOCATION_CONTRACT.md` and `docs/roadmap/GLOBAL_INSTALL_UPDATE_MODEL.md`). The **legacy project-local copy mode** (channel 5) — the `.ai-harness/` payload covered in its own subsection below — is still supported for backward compatibility, but is not the recommended adoption shape for new projects. Source-repo dogfooding resolves the ToolRoot to the repo root (channel 4), but channel 4 is only reached when no channel 3 global stable install is present; on a machine that has one, pass an explicit `-ToolRoot <repo-root>` (channel 1) so channel 3 does not shadow it. Full mode boundaries: `docs/OPERATOR_GUIDE_KR.md` §2.

## Install

[`INSTALL.md`](INSTALL.md) 가 unified install guide 다. GitHub repo URL 과 local clone path 의 두 source input 을 같은 model 로 설명하며, prerequisites / fresh install / update · reinstall / failure handling 까지 본문에 포함되어 self-contained 하다. 본 도구는 system-wide CLI / productized installer 가 없고, install operator 는 Claude Code 다. install identity 는 source 문자열이 아니라 resolved commit SHA 다. 실제 `%USERPROFILE%\.claude\ai-harness-toolset\current\` materialize / refresh 는 explicit user-approved global / user filesystem mutation scope 이며, trigger 한 줄로 자동 실행되지 않는다.

## Quick start

The current adoption model is the **shared / global stable runtime ToolRoot** (channel 3). There is no installer and no system-wide CLI: lifecycle scripts run from a global stable install at `%USERPROFILE%\.claude\ai-harness-toolset\current`, and every invocation resolves that path automatically — you do not pass `-ToolRoot` or set `AI_HARNESS_TOOL_ROOT`. Runtime output is always written under the target project's `<project-root>/log/`, never back into the install.

Day-to-day, the entrypoint is the Claude Code natural-language UX (`docs/OPERATOR_GUIDE_KR.md` §7); the raw PowerShell commands in the sections below are the fallback / reference shape. Materializing and updating the channel 3 install follows `docs/roadmap/GLOBAL_INSTALL_UPDATE_MODEL.md`.

`docs/`, `tests/`, and `log/` are source-repo only — they are never part of the resolved ToolRoot payload. When this README references `docs/*.md` files, read those files from this source repo, not from a target project.

### Legacy project-local copy mode (channel 5)

The project-local copy mode is still supported for backward compatibility but is not the recommended adoption shape for new projects. It has no global install; instead, four source folders are manually copied from this repo into the target project:

| Source repo | Target payload (legacy channel 5) |
|---|---|
| `config/` | `<project-root>/.ai-harness/config/` |
| `scripts/` | `<project-root>/.ai-harness/scripts/` |
| `snippets/` | `<project-root>/.ai-harness/snippets/` |
| `templates/` | `<project-root>/.ai-harness/templates/` |

Rules (legacy mode):

- Copy only the four folders above. Do not copy `docs/`, `.git/`, `log/`, or repo-level files such as `README.md` or `.gitattributes`.
- Do not modify any global file.
- The `.ai-harness/` payload lives entirely inside the target project root and can be removed by deleting that directory.
- After copying, `<project-root>/.ai-harness/scripts/` becomes the script root (channel 5 ToolRoot) for that project.

## Initialize runtime log layout

Create the runtime log tree once. This creates `<project-root>/log/`, `log/chatlog/`, `log/evidence/`, `log/review/`. `log/` is a runtime artifact root and must not be committed; ensure the target project's `.gitignore` includes `log/`.

Shared / global mode (channel 3) — run from inside the target project root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
    -File "$env:USERPROFILE\.claude\ai-harness-toolset\current\scripts\log-init.ps1"
```

Source-repo dogfooding — run from the source repo root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/log-init.ps1
```

Legacy project-local copy mode (channel 5) — run from a target project root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .ai-harness/scripts/log-init.ps1
```

Review record retention is human-managed at `<review-task-id>/` directory (or per-`pass-NN/`) granularity. Full contract: `docs/REVIEW_RESULT_CONTRACT.md`.

## Review artifact contract

The canonical review artifact layout is one pass directory per Codex attempt, grouped under one task directory per review task:

```text
<ProjectRoot>/log/review/<review-task-id>/
  pass-01/
    input.md   AI-authored from templates/review-input.md
    result.md  Codex-authored
  pass-02/    (only if the corrective loop adds another attempt)
    input.md
    result.md
```

- `<review-task-id>` identifies one Claude Code `/goal` task or one review gate. It is **not** a Claude Code chat / session id. A single session may contain multiple `<review-task-id>` directories for different `/goal` tasks. Operator / AI passes it explicitly via `scripts/review-prepare.ps1 -ReviewTaskId <id>`.
- `pass-NN` (zero-padded two-digit) identifies one Codex review attempt inside the corrective loop for that task. The first attempt is `pass-01`; subsequent corrective passes are `pass-02`, `pass-03`, and so on. `review-prepare.ps1 -Pass <pass-NN>` selects it explicitly; omitting `-Pass` auto-allocates the next pass under the same task directory.
- Each `pass-NN/` is write-once. If the input or result is wrong or stale, allocate a fresh `pass-NN/` under the same `<review-task-id>/`; do not edit the old pass to close the review.

`input.md` is authored by Claude Code (the operator-role AI). It contains the target files, context, required inspection paths, review questions, constraints, and the final verdict instruction, in five required H2 sections (`## Context`, `## Required inspection paths`, `## Review questions`, `## Constraints`, `## Final verdict`) plus recommended informational sections (`## Stage`, `## Purpose`, `## Target files`). The user does not type CLI arguments; the natural-language entrypoint is `docs/OPERATOR_GUIDE_KR.md` §7, and the skill that orchestrates the run is `snippets/claude-skills/ai-harness-review/SKILL.md`.

`result.md` is authored by Codex CLI (`--output-last-message`). It must contain exactly one top-level `## Verdict` heading whose first non-empty body line is one of `yes`, `no`, `yes with risk` (lowercase, no qualifier, no inline form). Other sections (`## Findings`, `## Risks`, `## Notes`) are free-form.

The toolset script that drives a pass performs only deterministic gates: pass-directory containment under `<ProjectRoot>/log/review/`, the five required headings in `input.md`, exactly one Codex execution, the existence of `result.md`, and the `## Verdict` allowed-value check. It does not interpret findings, decide correction scope, or trigger commit / push / publish / merge / release.

- Single-shot, user-triggered. One Codex CLI execution per `review-run.ps1` call. No retry, no fallback model use, no auto-fix loop.
- Verdict (`yes` / `no` / `yes with risk`) does not approve commit, push, publish, merge, or release. The user decides the next action explicitly.
- No external staging folders, no sidecar JSON, no hash-binding files, and no flat single-level run-id layout are part of the canonical contract. Historical references to removed-legacy artifact shapes live only in `docs/backlog/review.md` and `docs/backlog/operations.md` and are not operator paths.
- AI-to-Codex transport is Markdown inside `input.md`. Multi-line content, Korean, ASCII double-quotes, and bullet lists live inside the file. PowerShell argv quoting is not the transport.

Full contract: `docs/REVIEW_RESULT_CONTRACT.md`. Day-to-day natural-language UX, modes A/B, and the acceptance checklist: `docs/OPERATOR_GUIDE_KR.md` §7, §10, §13. CLI / runtime dependency boundary: `docs/CLI_ENVIRONMENT_ASSUMPTIONS.md`.

## Evidence and chatlog

- `log/evidence/<scope>/<case>/` captures command, test, and execution facts. Contract: `docs/EVIDENCE_CONTRACT.md`.
- The current restore source for any project is **Brief**, not Chatlog. Brief lives at `<ProjectRoot>/log/brief/BRIEF.md` — a project-local, operator-local, source-control-excluded runtime artifact under `<ProjectRoot>/log/`, gitignored by default and never a commit/push target (`docs/BRIEF_CONTRACT.md`). `<ProjectRoot>/brief/BRIEF.md` (root `brief/`) is **rejected**, and so is any user-home operator-local runtime root (e.g. `%USERPROFILE%\.ai-harness\projects\...`). "Project-local" here means inside each operator's local checkout of the target repo (because `log/` is gitignored); it does not mean repo-tracked. `log/chatlog/current/resume.md` and `log/chatlog/current/summary.md` are **not** canonical artifacts — they are failed intermediate / legacy migration source / deprecation candidate, kept only as wording legacy until a separately approved migration step (`docs/CHATLOG_CONTRACT.md`).
- BF Level is save/restore capability maturity, not a path. BF Level 1/2 is manual save/restore discipline. BF Level 3 (deterministic Brief maintenance, validation, stale warning, session-start guidance, restore-offer) is future scoped work; `scripts/brief-init.ps1` / `scripts/brief-check.ps1` are narrow source-side primitives, not the full BF Level 3 implementation.
- Chatlog is history / decision rationale / Brief reconstruction evidence. Chatlog is not the current restore source. If Brief is corrupted / missing / stale, Chatlog can be used as evidence to reconstruct it, but Chatlog itself never gets promoted into Brief's seat.
- Brief stays compact and references Chatlog / review / evidence artifacts by path only. Do not inline full review results, evidence payloads, or cumulative chat content into Brief.
- Snippet protocols in `snippets/CLAUDE_SNIPPET.md` and `snippets/AGENTS_SNIPPET.md` activate only when the user has manually adopted those snippets into a destination `CLAUDE.md` / `AGENTS.md`. There is no automatic global install, no hook, no auto-injection, no automatic transcript or prompt capture, no transcript JSONL parser, no Claude JSONL parser, and no `BF_STATE.json` or other separate state-machine file.
- **Source snippet alignment.** The source `snippets/CLAUDE_SNIPPET.md` and `snippets/AGENTS_SNIPPET.md` carry the current (3rd-reconciliation) framing: BF Level is save/restore capability maturity (not a path), canonical Brief is the project-local runtime artifact at `<ProjectRoot>/log/brief/BRIEF.md` (gitignored under `log/`, seeded by `scripts/brief-init.ps1` and validated by `scripts/brief-check.ps1`), root `<ProjectRoot>/brief/` is rejected, and `log/chatlog/current/resume.md` / `summary.md` are failed intermediate / legacy migration source / deprecation candidate. **Previously-applied managed blocks** in any destination `CLAUDE.md` / `AGENTS.md` (project-root or user-global) still contain whichever snippet body was last applied at that destination, until the operator explicitly refreshes them; that refresh is a separate user-approved managed-block replacement step (`docs/roadmap/GLOBAL_ADOPTION_DECISION.md` §6), and ai-harness does not perform it automatically. When the docs contracts and any applied managed block disagree, the docs contracts are authoritative.

## Snippets for CLAUDE.md / AGENTS.md

ai-harness-toolset does not overwrite global or project-local `CLAUDE.md` / `AGENTS.md`. It only ships AI-facing English payloads the user may choose to adopt manually:

- `snippets/CLAUDE_SNIPPET.md` — payload for a CLAUDE.md-compatible agent (Claude Code and similar). Valid destinations: `<project-root>/CLAUDE.md` (project-root) or `%USERPROFILE%\.claude\CLAUDE.md` (user-global).
- `snippets/AGENTS_SNIPPET.md` — payload for an AGENTS.md-compatible agent (Codex CLI and similar). Valid destinations: `<project-root>/AGENTS.md` (project-root) or the Codex user-global path `%USERPROFILE%\.codex\AGENTS.md` by default, or `%CODEX_HOME%\AGENTS.md` if the `CODEX_HOME` environment variable is set. At the Codex user-global scope, `AGENTS.override.md` (e.g., `%USERPROFILE%\.codex\AGENTS.override.md`) takes precedence over `AGENTS.md` when both exist; the managed block lives in whichever file is the effective Codex source of truth in that environment.

`%USERPROFILE%\.claude\AGENTS.md` is **forbidden**: that path is not a recognized global instruction location for any agent, and ai-harness must never create it. The Codex user-global instruction path is under `.codex\`, not `.claude\`.

Both snippets are written **dual-role safe** — they apply regardless of whether the loading agent is currently acting as operator, reviewer, auditor, or supervisor. Role-specific behavior is set by `/goal`, the review input, the skill prompt, or the command invocation, not by these global payloads. See each snippet's `Role neutrality` section.

Adoption is a deliberate user action: append the matching snippet into one of the valid destination files inside the single canonical managed block delimited by the `AI_HARNESS_TOOLSET_GLOBAL` markers. The canonical marker form is identical for both `CLAUDE.md` and `AGENTS.md` (the snippet files themselves carry these markers literally — see the first / last lines of `snippets/CLAUDE_SNIPPET.md` and `snippets/AGENTS_SNIPPET.md`):

````markdown
<!-- BEGIN AI_HARNESS_TOOLSET_GLOBAL -->
<contents of snippets/CLAUDE_SNIPPET.md or snippets/AGENTS_SNIPPET.md>
<!-- END AI_HARNESS_TOOLSET_GLOBAL -->
````

The marker text `AI_HARNESS_TOOLSET_GLOBAL` is the canonical form for both snippet types, governed by `docs/roadmap/GLOBAL_ADOPTION_DECISION.md` §6. Updating means replacing only the content inside this managed block; removing means deleting only the entire managed block. Whole-file overwrite of any destination listed above is forbidden.

## Optional Claude Code skill

`snippets/claude-skills/ai-harness-review/SKILL.md` is an optional, copy-only Claude Code skill template. It defines the natural-language entrypoint for the canonical two-step review flow — `scripts/review-prepare.ps1 -ReviewTaskId <id> [-Pass <pass-NN>]` → AI authors the pass `input.md` at `log/review/<review-task-id>/pass-NN/input.md` → `scripts/review-run.ps1 -ReviewTaskId <id> -Pass <pass-NN>` — that natural-language triggers like `현재 진행한 작업 코덱스 리뷰 진행해` resolve to. Adoption is a deliberate user action — copy it to `<project-root>/.claude/skills/ai-harness-review/SKILL.md` (project-local, recommended) or `~/.claude/skills/ai-harness-review/SKILL.md` (global, opt-in only). Nothing is auto-installed. Details: `docs/OPERATOR_GUIDE_KR.md` sections 7–8.

## What this toolset does not do

- No automatic or system-wide install. No system-wide CLI, no PATH mutation. (The channel 3 global stable runtime ToolRoot lives under `%USERPROFILE%\.claude\ai-harness-toolset\current`, but it is a deliberate, user-requested materialization — not an auto-install, not a PATH change, and not a system-wide CLI; see `docs/roadmap/GLOBAL_INSTALL_UPDATE_MODEL.md` and `docs/OPERATOR_GUIDE_KR.md` §15.)
- No automatic mutation of any global or project-root `CLAUDE.md` / `AGENTS.md`.
- No watcher, hook, daemon, workflow engine, or productized `review-run`.
- No auto-fix loop, auto-commit, auto-push, auto-publish, auto-merge, auto-release, or auto-deployment.
- No CI integration, scheduled runner, or handoff generator.
- Commits and pushes always require explicit user approval.

## Documentation map

**Start here for current state.** `docs/current/SOURCE_OF_TRUTH.md` routes any question to the document that answers it (with priority on conflict); `docs/current/PROJECT_STATE.md` is the top-level current summary; `docs/current/NEXT_ACTIONS.md` is the active queue. Per-system status lives under `docs/systems/<system>/STATUS.md` (+ `BACKLOG.md` / `DEFERRED.md`). Historical / superseded material lives under `docs/archive/` (not current guidance — see `docs/archive/README.md`).

The contracts and policies below are the authoritative active operational docs they route to.

Tags: `active operational` (current source-of-truth), `active reference` (advisory), `mixed decision log` (active and historical interleaved), `historical reference` (migration-era).

| File | Role | One-line role |
|---|---|---|
| `docs/AI_HARNESS_TOOLSET_SCOPE.md` | active operational | Project nature, in/out of scope, source-vs-target payload mapping. |
| `docs/BRIEF_CONTRACT.md` | active operational | Brief contract: BF Level as save/restore capability maturity, project-local runtime Brief at `<ProjectRoot>/log/brief/BRIEF.md` (gitignored under `log/`, not a commit/push target), root `<ProjectRoot>/brief/` rejected, and the `brief-init.ps1` / `brief-check.ps1` source-side primitive responsibility boundary. |
| `docs/CHATLOG_CONTRACT.md` | active operational | Chatlog responsibility (history / decision rationale / Brief reconstruction evidence) and the demotion of `log/chatlog/current/resume.md` / `summary.md` to failed intermediate / legacy migration source / deprecation candidate. |
| `docs/CLI_ENVIRONMENT_ASSUMPTIONS.md` | active operational | Canonical CLI/runtime dependency boundary. |
| `docs/DECISIONS.md` | active operational | Active policy decisions + MVP-closeout pointer (bootstrap/historical decisions archived to `docs/archive/legacy-mvp/BOOTSTRAP_DECISIONS.md`). |
| `docs/EVIDENCE_CONTRACT.md` | active operational | `log/evidence/<scope>/<case>/` minimal capture contract. |
| `docs/archive/legacy-mvp/LEGACY_KNOWLEDGE_TRANSFER.md` | historical reference | Legacy `ai-harness` → v1 migration mapping table (archived). |
| `docs/archive/legacy-mvp/MIGRATION_INVENTORY_SUMMARY.md` | historical reference | Frozen migration inventory counts (archived). |
| `docs/OPERATOR_GUIDE_KR.md` | active operational | Current Korean operator guide for shared/global operation, CLI usage, legacy mode appendix, and acceptance checklist. |
| `docs/POWERSHELL_POLICY.md` | active operational | Encoding, line-ending, file IO, and collection return rules. |
| `docs/REVIEWER_CONFIG_POLICY.md` | active operational | Reviewer config location, precedence, defaults, and MVP reviewer boundary. |
| `docs/REVIEW_RESULT_CONTRACT.md` | active operational | Canonical review artifact contract — `log/review/<review-task-id>/pass-NN/input.md` (AI-authored) + `result.md` (Codex-authored) only; deterministic gates and verdict vocabulary. |
| `docs/TOOLING_POSITION.md` | active reference | Position statements for adjacent tools. |

### Current state, systems, roadmap, and archive

| Path | Role |
|---|---|
| `docs/current/SOURCE_OF_TRUTH.md` | active operational | Question → authoritative document (Primary / Secondary / Implementation / Historical / Do-not-use). |
| `docs/current/PROJECT_STATE.md` | active operational | Top-level current summary + compact completed-milestone ledger. |
| `docs/current/NEXT_ACTIONS.md` | active operational | Active queue only. |
| `docs/systems/install-update/STATUS.md` (+ `DEFERRED.md`, `BACKLOG.md`) | active operational | install/update/global-adoption status, deferred, and open backlog. |
| `docs/systems/review/STATUS.md` (+ `BACKLOG.md`) | active operational | review subsystem status and open backlog. |
| `docs/systems/brief/STATUS.md` (+ `DEFERRED.md`) | active operational | Brief primitive status and BF Level 3 deferred. |
| `docs/roadmap/INDEX.md` | active reference | roadmap-area index + interim routing; routes design/model/record docs to system STATUS. |
| `docs/roadmap/CURRENT_MILESTONES.md` | active reference | post-MVP numbered remaining order (steps 1–7), 1:1 routing view (authority: `docs/roadmap/POST_MVP_PLAN.md` §11). |
| `docs/roadmap/POST_MVP_PLAN.md` | mixed decision log | post-MVP decision record (§1–§9) + numbered-order authority (§11); status/completed/deferred routed to current/system homes. |
| `docs/archive/README.md` | historical reference | archive authority restriction; archive is not current guidance. |

Note: the `docs/roadmap/` design/model/record docs (`GLOBAL_INSTALL_UPDATE_MODEL.md`, `global-install-update/STEP3_INSTALL_UPDATE_DECISION_GUIDE.md`, `GLOBAL_ADOPTION_DECISION.md`, `GLOBAL_ADOPTION_PROCEDURE.md`, `SHARED_GLOBAL_INVOCATION_CONTRACT.md`, `TOOLROOT_PROJECTROOT_AUDIT.md`, `CLEAN_TARGET_SMOKE_CRITERIA.md`, `REVIEW_EFFORT_GUIDE.md`) each carry a top routing banner to their system STATUS; current status lives in the system STATUS docs, not in those design docs.
