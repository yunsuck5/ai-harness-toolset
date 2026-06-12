# ai-harness-toolset

Project-local deterministic toolset for Claude / Codex workflows.

ai-harness-toolset is a project-local deterministic toolset. It is not an orchestrator, not an installer, and not packaged. Operation is CLI-only. The current adoption model is the **shared / global stable runtime ToolRoot** (channel 3): lifecycle scripts run from a global stable install at `%USERPROFILE%\.claude\ai-harness-toolset\current`, resolved per invocation, and runtime output is written under the target project's `<project-root>/log/`. A legacy project-local copy mode (channel 5), in which the source folders are copied into a `.ai-harness/` payload at the target project root, remains supported for backward compatibility but is not the recommended adoption shape for new projects.

> **Current adoption model.** The current adoption and default direction is the **shared / global stable runtime ToolRoot** — channel 3, the global stable install at `%USERPROFILE%\.claude\ai-harness-toolset\current`, resolved per invocation (see `docs/install-update/install-update_spec.md` — the install-update domain spec carrying the invocation-channel and layer invariants). The **legacy project-local copy mode** (channel 5) — the `.ai-harness/` payload covered in its own subsection below — is still supported for backward compatibility, but is not the recommended adoption shape for new projects. Source-repo dogfooding resolves the ToolRoot to the repo root (channel 4), but channel 4 is only reached when no channel 3 global stable install is present; on a machine that has one, pass an explicit `-ToolRoot <repo-root>` (channel 1) so channel 3 does not shadow it.
## Install

[`INSTALL.md`](INSTALL.md) 가 unified install guide 다. GitHub repo URL 과 local clone path 의 두 source input 을 같은 model 로 설명하며, prerequisites / fresh install / update · reinstall / failure handling 까지 본문에 포함되어 self-contained 하다. 본 도구는 system-wide CLI / productized installer 가 없고, install operator 는 Claude Code 다. install identity 는 source 문자열이 아니라 resolved commit SHA 다. 실제 `%USERPROFILE%\.claude\ai-harness-toolset\current\` materialize / refresh 는 explicit user-approved global / user filesystem mutation scope 이며, trigger 한 줄로 자동 실행되지 않는다.

## Quick start

The current adoption model is the **shared / global stable runtime ToolRoot** (channel 3). There is no installer and no system-wide CLI: lifecycle scripts run from a global stable install at `%USERPROFILE%\.claude\ai-harness-toolset\current`, and every invocation resolves that path automatically — you do not pass `-ToolRoot` or set `AI_HARNESS_TOOL_ROOT`. Runtime output is always written under the target project's `<project-root>/log/`, never back into the install.

Day-to-day, the entrypoint is the Claude Code natural-language UX (e.g. `설치해줘` / `업데이트해줘` / `언인스톨해줘`, handled per `INSTALL.md`); the raw PowerShell commands in the sections below are the fallback / reference shape. Materializing and updating the channel 3 install follows `INSTALL.md` (the self-contained operative contract; domain invariants: `docs/install-update/install-update_spec.md`).

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

## Runtime log layout

The runtime log tree lives at `<project-root>/log/`; its subdirectories — `log/brief/`, `log/evidence/`, `log/review/` — are created on demand by the primitives that write into them (`scripts/brief-init.ps1` seeds `log/brief/BRIEF.md`, `scripts/review-prepare.ps1` creates `log/review/<review-task-id>/<perspective>/pass-NN/`, and evidence files are written under `log/evidence/`). No separate initialization step is required. `log/` is a runtime artifact root and must not be committed; ensure the target project's `.gitignore` includes `log/`.

Review record retention is human-managed at `<review-task-id>/` directory (or per-`pass-NN/`) granularity. Spec-of-record: `docs/review/review_spec.md`.

## Review artifact contract

The canonical review artifact layout is **three-level** — one pass directory per Codex attempt, under one perspective directory per review viewpoint, under one task directory per review task:

```text
<ProjectRoot>/log/review/<review-task-id>/<perspective>/
  pass-01/
    input.md   AI-authored from templates/review-input.md
    result.md  reviewer-adapter body + runner-appended provenance block (dual-authored)
  pass-02/    (only if the corrective loop adds another attempt)
    input.md
    result.md
```

`<perspective>` is **required** (the scripts fail fast without it; there is no two-level fallback). Legacy two-level `<review-task-id>/pass-NN/` records from before strict C1 may still exist on disk and can be read manually, but the current scripts require `-Perspective` and the canonical layout is three-level — those legacy records are not tool-supported, not migrated, and not deleted.

- `<review-task-id>` identifies one Claude Code `/goal` task or one review gate. It is **not** a Claude Code chat / session id. A single session may contain multiple `<review-task-id>` directories for different `/goal` tasks. Operator / AI passes it explicitly via `scripts/review-prepare.ps1 -ReviewTaskId <id>`.
- `<perspective>` (**required**) is a review viewpoint passed explicitly via `scripts/review-prepare.ps1 -Perspective <viewpoint>` (no automatic inference; omitting it fails fast). It is a separate path segment between `<review-task-id>` and `pass-NN`, validated as a single safe segment (no `..` / `/` / `\` / `pass-NN` shape; safe charset / length).
- `pass-NN` (zero-padded two-digit) identifies one Codex review attempt inside the corrective loop. The first attempt is `pass-01`; subsequent corrective passes are `pass-02`, `pass-03`, and so on. `review-prepare.ps1 -Pass <pass-NN>` selects it explicitly; omitting `-Pass` auto-allocates the next pass under the same perspective directory (pass numbering is per-perspective).
- Each `pass-NN/` is write-once. If the input or result is wrong or stale, allocate a fresh `pass-NN/` under the same `<review-task-id>/<perspective>/`; do not edit the old pass to close the review.

`input.md` is authored by Claude Code (the operator-role AI). It contains the target files, context, required inspection paths, review questions, constraints, and the final verdict instruction, in five required H2 sections (`## Context`, `## Required inspection paths`, `## Review questions`, `## Constraints`, `## Final verdict`) plus recommended informational sections (`## Stage`, `## Purpose`, `## Target files`). The user does not type CLI arguments; the natural-language entrypoint and run orchestration is the review skill `snippets/claude-skills/ai-harness-review/SKILL.md`.

`result.md` is **dual-authored**: the verdict/disclosure body is authored by the active reviewer adapter (current MVP adapter: codex, via `--output-last-message`), and `scripts/review-run.ps1` then appends a runner-authored `## Reviewer run provenance` block (a machine run-fact, not reviewer judgment; spec-of-record: `docs/review/review_spec.md`). The reviewer-authored body must contain exactly one top-level `## Verdict` heading whose first non-empty body line is one of `yes`, `no`, `yes with risk` (lowercase, no qualifier, no inline form), plus four required disclosure H2s — `## Blocking findings`, `## Non-blocking concerns`, `## Review limitations`, `## Assumptions relied on` — each exactly once, with `none` as the body when a section has no substance. Additional sections (`## Findings`, `## Risks`, `## Counter-argument`, `## Notes`) are free-form. `## Counter-argument` is optional and strongly-recommended (non-parser) — the reviewer's dedicated position for the strongest case AGAINST a `yes` / `yes with risk` verdict (convention specified in `docs/review/review_spec.md`).

The toolset script that drives a pass performs only deterministic gates: pass-directory containment under `<ProjectRoot>/log/review/` (and, because `<perspective>` is operator-supplied, containment within the intended `<review-task-id>/` task root so a perspective cannot traverse into a sibling task), the five required headings in `input.md`, exactly one Codex execution, the existence of `result.md`, the `## Verdict` allowed-value check, and the four required disclosure H2s each present exactly once in `result.md` (the disclosure check is the `-RequireResult` mode of `scripts/review-verify.ps1`). It does not interpret findings, decide correction scope, or trigger commit / push / publish / merge / release.

- Single-shot, user-triggered. One Codex CLI execution per `review-run.ps1` call. No retry, no fallback model use, no auto-fix loop.
- Verdict (`yes` / `no` / `yes with risk`) does not approve commit, push, publish, merge, or release. The user decides the next action explicitly.
- No external staging folders, no sidecar JSON, no hash-binding files, and no flat single-level run-id layout are part of the canonical contract. Historical references to removed-legacy artifact shapes are preserved in git history and are not operator paths.
- AI-to-Codex transport is Markdown inside `input.md`. Multi-line content, Korean, ASCII double-quotes, and bullet lists live inside the file. PowerShell argv quoting is not the transport.

When reading `result.md`, Claude Code treats it as a structured artifact — the `## Verdict` line alone is not sufficient for the next action, and the four required disclosure H2s are read alongside it. The verdict → next-action mapping (`yes` / `no` / `yes with risk` each map to a different operator response) is specified in `docs/review/review_spec.md`; the operator-facing operative home lives in the review skill (`snippets/claude-skills/ai-harness-review/SKILL.md` step 6 + step 7).

Spec-of-record: `docs/review/review_spec.md`. Day-to-day natural-language UX, modes A/B, and the acceptance checklist: the review skill `snippets/claude-skills/ai-harness-review/SKILL.md`. CLI / runtime dependency boundary: `docs/policies/CLI_ENVIRONMENT_ASSUMPTIONS.md`.

## Evidence and Brief

- `log/evidence/<scope>/<case>/` captures command, test, and execution facts. The evidence file-format convention (5-file recipe / single-Markdown bundle) is specified in `docs/review/review_spec.md`.
- The current restore source for any project is **Brief** — it is the only restore source. Brief lives at `<ProjectRoot>/log/brief/BRIEF.md` — a project-local, operator-local, source-control-excluded runtime artifact under `<ProjectRoot>/log/`, gitignored by default and never a commit/push target (`docs/brief/brief_spec.md`). `<ProjectRoot>/brief/BRIEF.md` (root `brief/`) is **rejected**, and so is any user-home operator-local runtime root (e.g. `%USERPROFILE%\.ai-harness\projects\...`). "Project-local" here means inside each operator's local checkout of the target repo (because `log/` is gitignored); it does not mean repo-tracked.
- BF Level is save/restore capability maturity, not a path. BF Level 1/2 is manual save/restore discipline. BF Level 3 (deterministic Brief maintenance, validation, stale warning, session-start guidance) is future scoped work; `scripts/brief-init.ps1` / `scripts/brief-check.ps1` are narrow source-side primitives, not the full BF Level 3 implementation. The unsolicited session-start restore-offer source-side automation is **retired**, not a deferred BF Level 3 component (`docs/brief/brief_spec.md`); only an explicit, user-requested Brief restore remains.
- Brief stays compact and references review / evidence artifacts by path only. Do not inline full review results, evidence payloads, or cumulative session content into Brief.
- Snippet protocols in `snippets/CLAUDE_SNIPPET.md` and `snippets/AGENTS_SNIPPET.md` activate only when the user has manually adopted those snippets into a destination `CLAUDE.md` / `AGENTS.md`. There is no automatic global install, no hook, no auto-injection, no automatic transcript or prompt capture, no transcript JSONL parser, no Claude JSONL parser, and no `BF_STATE.json` or other separate state-machine file.
- **Source snippet alignment.** The source `snippets/CLAUDE_SNIPPET.md` and `snippets/AGENTS_SNIPPET.md` no longer carry the legacy Brief framing — the `## Brief` section was removed by the Batch 3 / Track F snippet minimization (`docs/systems/skills/STATUS.md` SK-05). The current (3rd-reconciliation) Brief framing — BF Level is save/restore capability maturity (not a path), canonical Brief is the project-local runtime artifact at `<ProjectRoot>/log/brief/BRIEF.md` (gitignored under `log/`, seeded by `scripts/brief-init.ps1` and validated by `scripts/brief-check.ps1`), root `<ProjectRoot>/brief/` is rejected, and Brief is the only restore source — is recorded in `docs/brief/brief_spec.md` and realized by the active Brief surface (the `ai-harness-brief` skill, `scripts/brief-init.ps1` / `scripts/brief-check.ps1`, and `templates/brief/BRIEF.md`). **Previously-applied managed blocks** in any destination `CLAUDE.md` / `AGENTS.md` (project-root or user-global) still contain whichever snippet body was last applied at that destination, until the operator explicitly refreshes them; that refresh is a separate user-approved managed-block replacement step (`docs/decisions/GLOBAL_ADOPTION_DECISION.md` §6), and ai-harness does not perform it automatically. When a previously-applied managed block disagrees with the current framing, the applied block is the stale one — the current Brief framing lives in the active brief skill / `brief-*.ps1` / `templates/brief/BRIEF.md` (recorded in `docs/brief/brief_spec.md`), not in the old managed block.

## Snippets for CLAUDE.md / AGENTS.md

ai-harness-toolset does not overwrite global or project-local `CLAUDE.md` / `AGENTS.md`. It only ships AI-facing English payloads the user may choose to adopt manually:

- `snippets/CLAUDE_SNIPPET.md` — payload for a CLAUDE.md-compatible agent (Claude Code and similar). Valid destinations: `<project-root>/CLAUDE.md` (project-root) or `%USERPROFILE%\.claude\CLAUDE.md` (user-global).
- `snippets/AGENTS_SNIPPET.md` — payload for an AGENTS.md-compatible agent (Codex CLI and similar). Valid destinations: `<project-root>/AGENTS.md` (project-root) or the Codex user-global path `%USERPROFILE%\.codex\AGENTS.md` by default, or `%CODEX_HOME%\AGENTS.md` if the `CODEX_HOME` environment variable is set. At the Codex user-global scope, `AGENTS.override.md` (e.g., `%USERPROFILE%\.codex\AGENTS.override.md`) takes precedence over `AGENTS.md` when both exist; the managed block lives in whichever file is the effective Codex source of truth in that environment.

`%USERPROFILE%\.claude\AGENTS.md` is **forbidden**: that path is not a recognized global instruction location for any agent, and ai-harness must never create it. The Codex user-global instruction path is under `.codex\`, not `.claude\`.

Both snippets are written **dual-role safe** — they apply regardless of whether the loading agent is currently acting as operator, reviewer, auditor, or supervisor. Role-specific behavior is set by `/goal`, the review input, the skill prompt, or the command invocation, not by these global payloads. This role-neutral framing is stated in each snippet's intro; the binding operator-vs-reviewer-mode distinction lives in the `ai-harness-review` and `ai-harness-brief` skills. The snippets are a **minimal always-loaded bootstrap** (a safety floor plus a pointer to the distributed rules tier `snippets/rules/`), not a policy bundle; the reusable rules ship in `snippets/rules/` (global) and `rules/` (repo-only), and the whole distribution carries no `docs/` dependency — see `docs/architecture/instruction-surface/GLOBAL_SNIPPET_HARD_MINIMIZATION_CORRECTIVE.md`.

Adoption is a deliberate user action: append the matching snippet into one of the valid destination files inside the single canonical managed block delimited by the `AI_HARNESS_TOOLSET_GLOBAL` markers. The canonical marker form is identical for both `CLAUDE.md` and `AGENTS.md` (the snippet files themselves carry these markers literally — see the first / last lines of `snippets/CLAUDE_SNIPPET.md` and `snippets/AGENTS_SNIPPET.md`):

````markdown
<!-- BEGIN AI_HARNESS_TOOLSET_GLOBAL -->
<contents of snippets/CLAUDE_SNIPPET.md or snippets/AGENTS_SNIPPET.md>
<!-- END AI_HARNESS_TOOLSET_GLOBAL -->
````

The marker text `AI_HARNESS_TOOLSET_GLOBAL` is the canonical form for both snippet types — the snippet files carry it literally (the operative form), and the decision is recorded in `docs/decisions/GLOBAL_ADOPTION_DECISION.md` §6. Updating means replacing only the content inside this managed block; removing means deleting only the entire managed block. Whole-file overwrite of any destination listed above is forbidden.

## Optional Claude Code skills

The toolset ships two optional, copy-only Claude Code skill templates under `snippets/claude-skills/`: `ai-harness-review/SKILL.md` (the review flow below) and `ai-harness-brief/SKILL.md` (the manual Brief save / checkpoint / user-requested restore / update workflow). Each is discovered by its own `description`; copy the one(s) you want to `<project-root>/.claude/skills/<name>/SKILL.md` (project-local, recommended) or `~/.claude/skills/<name>/SKILL.md` (global, opt-in). Nothing is auto-installed.

`snippets/claude-skills/ai-harness-review/SKILL.md` is an optional, copy-only Claude Code skill template. It defines the natural-language entrypoint for the canonical two-step review flow — `scripts/review-prepare.ps1 -ReviewTaskId <id> -Perspective <viewpoint> [-Pass <pass-NN>]` → AI authors the pass `input.md` at `log/review/<review-task-id>/<perspective>/pass-NN/input.md` → `scripts/review-run.ps1 -ReviewTaskId <id> -Perspective <viewpoint> -Pass <pass-NN>` — that natural-language triggers like `현재 진행한 작업 코덱스 리뷰 진행해` resolve to. Adoption is a deliberate user action — copy it to `<project-root>/.claude/skills/ai-harness-review/SKILL.md` (project-local, recommended) or `~/.claude/skills/ai-harness-review/SKILL.md` (global, opt-in only). Nothing is auto-installed.
## What this toolset does not do

- No automatic or system-wide install. No system-wide CLI, no PATH mutation. (The channel 3 global stable runtime ToolRoot lives under `%USERPROFILE%\.claude\ai-harness-toolset\current`, but it is a deliberate, user-requested materialization — not an auto-install, not a PATH change, and not a system-wide CLI; see `docs/install-update/install-update_spec.md`.)
- No automatic mutation of any global or project-root `CLAUDE.md` / `AGENTS.md`.
- No watcher, hook, daemon, workflow engine, or productized `review-run`.
- No auto-fix loop, auto-commit, auto-push, auto-publish, auto-merge, auto-release, or auto-deployment.
- No CI integration, scheduled runner, or handoff generator.
- Commits and pushes always require explicit user approval.

## Documentation map

**Start here for current state.** `docs/current/REPO_READING_GUIDE.md` routes any question to the document that answers it (with priority on conflict). "What is done / what remains / what to do next" is answered **on demand** — ask the local agent for a status briefing, or read the per-domain status surfaces directly (the on-demand status-briefing model is the operative rule `rules/docs-working-model/docs-working-model.md`). Current status lives in the per-domain spec/backlog files (`docs/brief/` · `docs/review/` · `docs/install-update/`) and the remaining per-system board `docs/systems/skills/STATUS.md`; the numbered remaining order is `docs/roadmap/CURRENT_MILESTONES.md`. (There is no committed project-current summary or active-queue file — the former `docs/current/PROJECT_STATE.md` / `NEXT_ACTIONS.md` mirrors were removed.) Superseded / historical material is preserved in git history, not as current docs.

The docs below are organized by **access pattern** under `docs/` scope folders — the docs placement orientation map is `docs/README.md` (its binding placement rules live on the active surface at `rules/docs-working-model/docs-working-model.md`). Artifact/protocol contracts live under `docs/contracts/<area>/`, task-scoped execution policies under `docs/policies/`, project identity under `docs/project/`, and active decisions under `docs/decisions/`; `docs/` root holds only `README.md`. The per-system `STATUS.md` docs route to these as the read-first home for their topic rather than replacing them (see `docs/current/REPO_READING_GUIDE.md`). These docs explain, record, and orient — the operative authority for active behavior (execution / validation / routing / approval / behavior contract) lives on the active surface (`scripts/**`, `templates/**`, `snippets/**`, `rules/**`, `snippets/claude-skills/**`, `config/**`, `tests/**`, and the root instructions), which the docs route to and describe rather than override. The earlier flat-root "Policy A" layer is superseded by this access-pattern structure.

Tags: `active operational` (current, actively-maintained docs), `active reference` (advisory), `mixed decision log` (active and historical interleaved), `historical reference` (migration-era).

| File | Role | One-line role |
|---|---|---|
| `docs/project/AI_HARNESS_TOOLSET_SCOPE.md` | active operational | Project nature, in/out of scope, source-vs-target payload mapping. |
| `docs/brief/brief_spec.md` | active operational | Brief spec-of-record: BF Level as save/restore capability maturity, single canonical runtime Brief location (project-local `<ProjectRoot>/log/brief/BRIEF.md`, gitignored under `log/`, not a commit/push target), root `<ProjectRoot>/brief/` rejected, Brief is the only restore source, and the primitive / workflow behavior boundary. |
| `docs/policies/CLI_ENVIRONMENT_ASSUMPTIONS.md` | active operational | Canonical CLI/runtime dependency boundary. |
| `docs/decisions/DECISIONS.md` | active operational | Active policy decisions + MVP-closeout pointer (bootstrap/historical decisions preserved in git history). |
| `docs/policies/POWERSHELL_POLICY.md` | active operational | Encoding, line-ending, file IO, and collection return rules. |
| `docs/review/review_spec.md` | active operational | review domain spec-of-record — canonical three-level review artifact model (`input.md` AI-authored + `result.md` dual-authored, `<perspective>` required), verdict vocabulary, deterministic gates, reviewer-safe invocation, config-driven model/effort, and the `log/evidence/<scope>/<case>/` validation-evidence file-format convention (absorbing the former review/evidence contracts and reviewer policies). |
| `docs/project/TOOLING_POSITION.md` | active reference | Position statements for adjacent tools. |

### Current state, systems, and roadmap

| Path | Role | One-line role |
|---|---|---|
| `docs/current/REPO_READING_GUIDE.md` | active operational | Question → read-first document (Primary / Secondary / Implementation / Historical / Do-not-use). The only file under `docs/current/`. |
| `docs/install-update/install-update_spec.md` (+ `install-update_backlog.md`) | active domain docs | install-update domain target-state spec and future-work queue (open + deferred rows). |
| `docs/review/review_backlog.md` | active operational | review future-work queue (open candidates, accepted residual risks, idea-only rows). |
| `docs/brief/brief_backlog.md` | active operational | Brief future-work queue (BF Level 3 deferred candidates). |
| `docs/roadmap/INDEX.md` | active reference | roadmap milestone-routing index; `docs/roadmap/` is routing-only (`INDEX.md` + `CURRENT_MILESTONES.md`). Lists where the former roadmap design/model/decision docs were relocated and where current state lives. |
| `docs/roadmap/CURRENT_MILESTONES.md` | active reference | post-MVP numbered remaining order (steps 1–6), 1:1 routing view (authority: `docs/decisions/POST_MVP_PLAN.md` §11). |
| `docs/decisions/POST_MVP_PLAN.md` | mixed decision log | post-MVP decision record (§1–§9) + numbered-order authority (§11); status/completed/deferred routed to current/system homes. |

Note: as part of the access-pattern restructure, the former `docs/roadmap/` design/model/decision/record docs moved to their then scope homes — `docs/decisions/POST_MVP_PLAN.md`, `docs/decisions/GLOBAL_ADOPTION_DECISION.md`, the then install-update system docs (operating model, STEP3 guide) and the then global-invocation contract (all since absorbed into `docs/install-update/install-update_spec.md` in the install-update domain migration; bodies preserved in git history), and the then `docs/policies/REVIEW_EFFORT_GUIDE.md` (since absorbed into `docs/review/review_spec.md`). `docs/roadmap/` now holds **milestone routing only** (`INDEX.md`, `CURRENT_MILESTONES.md`); current status lives in the per-domain spec/backlog homes, not in design docs.
