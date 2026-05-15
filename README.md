# ai-harness-toolset

Project-local deterministic toolset for Claude / Codex workflows.

ai-harness-toolset is a project-local deterministic toolset. It is not an orchestrator, not an installer, and not packaged. Operation is CLI-only. The current adoption model is the **shared / global stable runtime ToolRoot** (channel 3): lifecycle scripts run from a global stable install at `%USERPROFILE%\.claude\ai-harness-toolset\current`, resolved per invocation, and runtime output is written under the target project's `<project-root>/log/`. A legacy project-local copy mode (channel 5), in which the source folders are copied into a `.ai-harness/` payload at the target project root, remains supported for backward compatibility but is not the recommended adoption shape for new projects.

> **Current adoption model.** The current adoption and default direction is the **shared / global stable runtime ToolRoot** — channel 3, the global stable install at `%USERPROFILE%\.claude\ai-harness-toolset\current`, resolved per invocation (see `docs/roadmap/SHARED_GLOBAL_INVOCATION_CONTRACT.md` and `docs/roadmap/GLOBAL_INSTALL_UPDATE_MODEL.md`). The **legacy project-local copy mode** (channel 5) — the `.ai-harness/` payload covered in its own subsection below — is still supported for backward compatibility, but is not the recommended adoption shape for new projects. Source-repo dogfooding resolves the ToolRoot to the repo root (channel 4), but channel 4 is only reached when no channel 3 global stable install is present; on a machine that has one, pass an explicit `-ToolRoot <repo-root>` (channel 1) so channel 3 does not shadow it. Full mode boundaries: `docs/OPERATOR_GUIDE_KR.md` §2.

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

Review record retention is human-managed at `<run-id>` directory granularity. Full contract: `docs/REVIEW_RESULT_CONTRACT.md`.

## Single-shot review cycle

The default user-facing entrypoint for `코덱스 리뷰 진행해` is `review-cycle.ps1`. It runs one full cycle in a single command: prepare a packet, fill the input sections, verify input readiness, invoke Codex CLI once, parse the verdict, write `result.json`, and run both modes of `review-verify`.

The script path depends on the resolved ToolRoot. In the current shared / global mode (channel 3) it is `$env:USERPROFILE\.claude\ai-harness-toolset\current\scripts\review-cycle.ps1`. The `scripts/review-cycle.ps1` form used in the examples below is the source-repo dogfooding path; the legacy project-local copy mode uses `.ai-harness/scripts/review-cycle.ps1`. The argument contract is identical across all three — `docs/OPERATOR_GUIDE_KR.md` §9 shows each form.

Single-file target — pass the one repo-relative path directly with `-TargetFiles`:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/review-cycle.ps1 `
    -Stage <design|implementation|test|review|release> `
    -Purpose '<short purpose string>' `
    -TargetFiles <single-relative-file> `
    -Context '<context>' `
    -RequiredInspectionPaths '<paths>' `
    -ReviewQuestions '<questions>' `
    -Constraints '<constraints>'
```

Two or more target files — write a newline-separated list file under `<project-root>/log/review-targets/` (one repo-relative path per line, forward slashes), then pass it with `-TargetFilesPath`:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/review-cycle.ps1 `
    -Stage <design|implementation|test|review|release> `
    -Purpose '<short purpose string>' `
    -TargetFilesPath log/review-targets/<purpose-or-timestamp>.list `
    -Context '<context>' `
    -RequiredInspectionPaths '<paths>' `
    -ReviewQuestions '<questions>' `
    -Constraints '<constraints>'
```

- Single-shot, user-triggered. One Codex CLI execution per call. No retry, no fallback model use, no auto-fix loop.
- Verdict (`yes` / `no` / `yes with risk`) does not approve commit, push, publish, merge, or release.
- Provide `-TargetFiles` (single file) or `-TargetFilesPath` (multi-file list) for deterministic target selection. Joining multiple paths into a single comma-separated `-TargetFiles` value (for example `-TargetFiles "a.txt,b.txt"`) is rejected before any reviewer runs (`FAIL TargetFiles appears to be a comma-separated single string`); use `-TargetFilesPath` for two or more files. A literal filename containing a comma is allowed in the single-file shape.
- Free-text argv quoting discipline (Stage 1 docs-only mitigation): on PowerShell 5.1, keep `-Context` / `-ReviewQuestions` / `-Constraints` / `-RequiredInspectionPaths` values single-line, single-quoted, and free of literal ASCII double-quote (`"`) characters. Multi-line here-strings and embedded double-quotes have caused wrapper-level failures (`PathTooLongException` in `review-prepare`, or `-Reviewer` mis-binding to a body token) before Codex CLI is invoked. If a request cannot be expressed under this discipline, simplify the wording or split the request rather than reaching for the smoke wrapper or any other workaround — `scripts/smoke/invoke-review-cycle.ps1` is smoke-driver-only and is not an operator-direct fallback. Stage 2 — a simple operator-direct PowerShell wrapper, or a cmd/batch helper — is **not adopted as a safe solution** (it cannot honestly guarantee embedded-double-quote / quote-heavy free-text robustness across the parent → wrapper argv boundary; see `docs/backlog/operations.md` §"Review-cycle invocation quoting hardening" §"Stage 2 / Stage 3 decision (2026-05-16)"). PowerShell 7.3+ native argument passing and `-EncodedCommand` / `-EncodedArguments` launchers are acknowledged official escape hatches but are not selected here (runtime dependency / readability cost; tracked under a later portability / possible Python · Node porting track). Stage 3 — file-backed review request input on `scripts/review-cycle.ps1` (e.g. `-ReviewRequestPath`, integrating with `docs/backlog/review.md` §"Review-cycle file-backed request input") — is the **next primary implementation candidate** and remains deferred until a separate scoped goal defines the parameter shape, file format, containment, conflict rules, tests, and docs alignment.

Cycle/result mechanics, parse failure semantics, and binding rules: `docs/REVIEW_RESULT_CONTRACT.md`. CLI/runtime dependency boundary: `docs/CLI_ENVIRONMENT_ASSUMPTIONS.md`. Multi-file list-file build steps and the full free-text argv quoting discipline: `docs/OPERATOR_GUIDE_KR.md` §9.

## Component scripts

`review-prepare.ps1` creates a review packet without invoking Codex; `review-run.ps1` runs the reviewer for an already-prepared `log/review/<run-id>/` packet; `review-verify.ps1` checks an existing run.

`review-cycle.ps1` is the one-shot path: prepare + run + verify in a single call. `review-run.ps1` is the run-only path for an existing prepared packet — use it when `log/review/<run-id>/input.md` is already seeded and edited (no new run-id is created and `meta.json` / `input.md` are not mutated). Compatible with the same result-binding contract as `review-cycle.ps1`.

```powershell
# review-prepare, single-file target
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/review-prepare.ps1 -TargetFiles <single-relative-file> -Stage <stage> -Purpose '<purpose>'

# review-prepare, multi-file target via list file under log/review-targets/
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/review-prepare.ps1 -TargetFilesPath log/review-targets/<purpose-or-timestamp>.list -Stage <stage> -Purpose '<purpose>'

# review-run, for an already-prepared run-id
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/review-run.ps1 -RunId <run-id>
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/review-run.ps1 -RunId <run-id> -Force

powershell -NoProfile -ExecutionPolicy Bypass -File scripts/review-verify.ps1 -RunId <run-id>
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/review-verify.ps1 -RunId <run-id> -RequireResult
```

`review-run.ps1` requires `meta.json` and `input.md` to exist under `log/review/<run-id>/`, calls `review-input-verify.ps1` before invoking Codex, executes Codex once in read-only sandbox, writes `result.md` / `result.json`, and runs `review-verify.ps1` in both default and `-RequireResult` modes. Existing `result.md` / `result.json` cause FAIL by default; pass `-Force` to overwrite. It does not mutate `meta.json` or `input.md`, does not touch `log/chatlog/` or `log/evidence/`, and does not approve commit, push, publish, merge, or release.

Behavior, field set, and binding rules: `docs/REVIEW_RESULT_CONTRACT.md`.

## Evidence and chatlog

- `log/evidence/<scope>/<case>/` captures command, test, and execution facts. Contract: `docs/EVIDENCE_CONTRACT.md`.
- The current restore source for any project is **Brief**, not Chatlog. Brief lives at `<ProjectRoot>/log/brief/BRIEF.md` — a project-local, operator-local, source-control-excluded runtime artifact under `<ProjectRoot>/log/`, gitignored by default and never a commit/push target (`docs/BRIEF_CONTRACT.md`). `<ProjectRoot>/brief/BRIEF.md` (root `brief/`) is **rejected**, and so is any user-home operator-local runtime root (e.g. `%USERPROFILE%\.ai-harness\projects\...`). "Project-local" here means inside each operator's local checkout of the target repo (because `log/` is gitignored); it does not mean repo-tracked. `log/chatlog/current/resume.md` and `log/chatlog/current/summary.md` are **not** canonical artifacts — they are failed intermediate / legacy migration source / deprecation candidate, kept only as wording legacy until a separately approved migration step (`docs/CHATLOG_CONTRACT.md`).
- BF Level is save/restore capability maturity, not a path. BF Level 1/2 is manual save/restore discipline. BF Level 3 (deterministic Brief maintenance, validation, stale warning, session-start guidance, restore-offer) is future scoped work; `scripts/brief-init.ps1` / `scripts/brief-check.ps1` are narrow source-side primitives, not the full BF Level 3 implementation.
- Chatlog is history / decision rationale / Brief reconstruction evidence. Chatlog is not the current restore source. If Brief is corrupted / missing / stale, Chatlog can be used as evidence to reconstruct it, but Chatlog itself never gets promoted into Brief's seat.
- Brief stays compact and references Chatlog / review / evidence artifacts by path only. Do not inline full review results, evidence payloads, or cumulative chat content into Brief.
- Snippet protocols in `snippets/CLAUDE_SNIPPET.md` and `snippets/AGENTS_SNIPPET.md` activate only when the user has manually adopted those snippets into a destination `CLAUDE.md` / `AGENTS.md`. There is no automatic global install, no hook, no auto-injection, no automatic transcript or prompt capture, no transcript JSONL parser, no Claude JSONL parser, and no `BF_STATE.json` or other separate state-machine file.
- **Source snippet alignment.** The source `snippets/CLAUDE_SNIPPET.md` and `snippets/AGENTS_SNIPPET.md` were previously aligned with an interim framing that placed target product canonical Brief at `<ProjectRoot>/brief/BRIEF.md`. The current contracts in `docs/BRIEF_CONTRACT.md` and `docs/CHATLOG_CONTRACT.md` supersede that: BF Level is save/restore capability maturity (not a path), Brief is the project-local runtime artifact at `<ProjectRoot>/log/brief/BRIEF.md` (gitignored under `log/`, seeded by `scripts/brief-init.ps1` and validated by `scripts/brief-check.ps1`), root `<ProjectRoot>/brief/` is rejected, and `log/chatlog/current/resume.md` / `summary.md` are failed intermediate / legacy migration source / deprecation candidate. Source snippets themselves are not refreshed in this docs round — that is deferred. **Previously-applied managed blocks** in any destination `CLAUDE.md` / `AGENTS.md` (project-root or user-global) still contain whichever snippet body was last applied, until the operator explicitly refreshes them; that refresh is a separate user-approved managed-block replacement step (`docs/roadmap/GLOBAL_ADOPTION_DECISION.md` §6), and ai-harness does not perform it automatically. When the docs contracts and any applied managed block disagree, the docs contracts are authoritative.

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

`snippets/claude-skills/ai-harness-review/SKILL.md` is an optional, copy-only Claude Code skill template. It defines the natural-language entrypoint for `review-cycle.ps1` (for example, `현재 진행한 작업 코덱스 리뷰 진행해`) so the user does not need to type raw PowerShell. Adoption is a deliberate user action — copy it to `<project-root>/.claude/skills/ai-harness-review/SKILL.md` (project-local, recommended) or `~/.claude/skills/ai-harness-review/SKILL.md` (global, opt-in only). Nothing is auto-installed. Details: `docs/OPERATOR_GUIDE_KR.md` sections 7–8.

## What this toolset does not do

- No automatic or system-wide install. No system-wide CLI, no PATH mutation. (The channel 3 global stable runtime ToolRoot lives under `%USERPROFILE%\.claude\ai-harness-toolset\current`, but it is a deliberate, user-requested materialization — not an auto-install, not a PATH change, and not a system-wide CLI; see `docs/roadmap/GLOBAL_INSTALL_UPDATE_MODEL.md` and `docs/OPERATOR_GUIDE_KR.md` §15.)
- No automatic mutation of any global or project-root `CLAUDE.md` / `AGENTS.md`.
- No watcher, hook, daemon, workflow engine, or productized `review-run`.
- No auto-fix loop, auto-commit, auto-push, auto-publish, auto-merge, auto-release, or auto-deployment.
- No CI integration, scheduled runner, or handoff generator.
- Commits and pushes always require explicit user approval.

## Documentation map

Tags: `active operational` (current source-of-truth), `active reference` (advisory), `mixed decision log` (active and historical interleaved), `historical reference` (migration-era).

| File | Role | One-line role |
|---|---|---|
| `docs/AI_HARNESS_TOOLSET_SCOPE.md` | active operational | Project nature, in/out of scope, source-vs-target payload mapping. |
| `docs/BRIEF_CONTRACT.md` | active operational | Brief contract: BF Level as save/restore capability maturity, project-local runtime Brief at `<ProjectRoot>/log/brief/BRIEF.md` (gitignored under `log/`, not a commit/push target), root `<ProjectRoot>/brief/` rejected, and the `brief-init.ps1` / `brief-check.ps1` source-side primitive responsibility boundary. |
| `docs/CHATLOG_CONTRACT.md` | active operational | Chatlog responsibility (history / decision rationale / Brief reconstruction evidence) and the demotion of `log/chatlog/current/resume.md` / `summary.md` to failed intermediate / legacy migration source / deprecation candidate. |
| `docs/CLI_ENVIRONMENT_ASSUMPTIONS.md` | active operational | Canonical CLI/runtime dependency boundary. |
| `docs/DECISIONS.md` | mixed decision log | Bootstrap-era and active policy decisions. |
| `docs/EVIDENCE_CONTRACT.md` | active operational | `log/evidence/<scope>/<case>/` minimal capture contract. |
| `docs/LEGACY_KNOWLEDGE_TRANSFER.md` | historical reference | Legacy `ai-harness` → v1 migration mapping table. |
| `docs/MIGRATION_INVENTORY_SUMMARY.md` | historical reference | Frozen migration inventory counts. |
| `docs/OPERATOR_GUIDE_KR.md` | active operational | Current Korean operator guide for shared/global operation, CLI usage, legacy mode appendix, and acceptance checklist. |
| `docs/POWERSHELL_POLICY.md` | active operational | Encoding, line-ending, file IO, and collection return rules. |
| `docs/REVIEWER_CONFIG_POLICY.md` | active operational | Reviewer config location, precedence, defaults, and MVP reviewer boundary. |
| `docs/REVIEW_RESULT_CONTRACT.md` | active operational | `result.md` / `result.json` minimum fields and `review-verify -RequireResult` binding rules. |
| `docs/TOOLING_POSITION.md` | active reference | Position statements for adjacent tools. |
