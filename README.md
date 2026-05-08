# ai-harness-toolset

Project-local deterministic toolset for Claude / Codex workflows.

ai-harness-toolset is a project-local deterministic toolset. It is not an orchestrator, not an installer, and not packaged. Adoption is copy-only and CLI-only. Source folders are copied into a `.ai-harness/` payload at the target project root, and runtime output is written under `<project-root>/log/`.

## Quick start: copy-only target project adoption

There is no installer. Manually copy four source folders from this repo into the target project:

| Source repo | Target payload |
|---|---|
| `config/` | `<project-root>/.ai-harness/config/` |
| `scripts/` | `<project-root>/.ai-harness/scripts/` |
| `snippets/` | `<project-root>/.ai-harness/snippets/` |
| `templates/` | `<project-root>/.ai-harness/templates/` |

Rules:

- Copy only the four folders above. Do not copy `docs/`, `.git/`, `log/`, or repo-level files such as `README.md` or `.gitattributes`.
- Do not modify any global file.
- The `.ai-harness/` payload lives entirely inside the target project root and can be removed by deleting that directory.
- After copying, `<project-root>/.ai-harness/scripts/` becomes the script root for that project.

`docs/`, `tests/`, and `log/` are source-repo only. When this README references `docs/*.md` files, read those files from this source repo, not from the target project.

## Initialize runtime log layout

Once the payload is in place (or when working inside this source repo), create the runtime log tree.

From the source repo root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/log-init.ps1
```

From a target project root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .ai-harness/scripts/log-init.ps1
```

This creates `<project-root>/log/`, `log/chatlog/`, `log/evidence/`, `log/review/`. `log/` is a runtime artifact root and must not be committed; ensure the target project's `.gitignore` includes `log/`.

Review record retention is human-managed at `<run-id>` directory granularity. Full contract: `docs/REVIEW_RESULT_CONTRACT.md`.

## Single-shot review cycle

The default user-facing entrypoint for `코덱스 리뷰 진행해` is `review-cycle.ps1`. It runs one full cycle in a single command: prepare a packet, fill the input sections, verify input readiness, invoke Codex CLI once, parse the verdict, write `result.json`, and run both modes of `review-verify`.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/review-cycle.ps1 `
    -Stage <design|implementation|test|review|release> `
    -Purpose '<short purpose string>' `
    -TargetFiles file1,file2 `
    -Context '<context>' `
    -RequiredInspectionPaths '<paths>' `
    -ReviewQuestions '<questions>' `
    -Constraints '<constraints>'
```

From a deployed target project, replace `scripts/review-cycle.ps1` with `.ai-harness/scripts/review-cycle.ps1`.

- Single-shot, user-triggered. One Codex CLI execution per call. No retry, no fallback model use, no auto-fix loop.
- Verdict (`yes` / `no` / `yes with risk`) does not approve commit, push, publish, merge, or release.
- Provide `-TargetFiles` for deterministic target selection.

Cycle/result mechanics, parse failure semantics, and binding rules: `docs/REVIEW_RESULT_CONTRACT.md`. CLI/runtime dependency boundary: `docs/CLI_ENVIRONMENT_ASSUMPTIONS.md`.

## Component scripts

`review-prepare.ps1` creates a review packet without invoking Codex; `review-verify.ps1` checks an existing run.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/review-prepare.ps1 -TargetFiles file1,file2 -Stage <stage> -Purpose '<purpose>'
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/review-verify.ps1 -RunId <run-id>
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/review-verify.ps1 -RunId <run-id> -RequireResult
```

Behavior, field set, and binding rules: `docs/REVIEW_RESULT_CONTRACT.md`.

## Evidence and chatlog

- `log/evidence/<scope>/<case>/` captures command, test, and execution facts. Contract: `docs/EVIDENCE_CONTRACT.md`.
- `log/chatlog/current/` captures session `summary.md` and `resume.md`. Contract: `docs/CHATLOG_CONTRACT.md`.

## Snippets for CLAUDE.md / AGENTS.md

ai-harness-toolset does not overwrite global or project-local `CLAUDE.md` / `AGENTS.md`. It only ships AI-facing English payloads the user may choose to adopt manually:

- `snippets/CLAUDE_SNIPPET.md` — payload for Claude Code root `CLAUDE.md`.
- `snippets/AGENTS_SNIPPET.md` — payload for Codex / generic agent root `AGENTS.md`.

Adoption is a deliberate user action: append the matching snippet into the root instruction file inside a managed block delimited by these markers.

For `CLAUDE.md`:

````markdown
<!-- BEGIN ai-harness-toolset:CLAUDE_SNIPPET.md -->
<contents of snippets/CLAUDE_SNIPPET.md>
<!-- END ai-harness-toolset:CLAUDE_SNIPPET.md -->
````

For `AGENTS.md`:

````markdown
<!-- BEGIN ai-harness-toolset:AGENTS_SNIPPET.md -->
<contents of snippets/AGENTS_SNIPPET.md>
<!-- END ai-harness-toolset:AGENTS_SNIPPET.md -->
````

Updating means replacing only the matching managed block; removing means deleting only the matching managed block. Whole-file overwrite of root `CLAUDE.md` / `AGENTS.md` is forbidden.

## Optional Claude Code skill

`snippets/claude-skills/ai-harness-review/SKILL.md` is an optional, copy-only Claude Code skill template. It defines the natural-language entrypoint for `review-cycle.ps1` (for example, `현재 진행한 작업 코덱스 리뷰 진행해`) so the user does not need to type raw PowerShell. Adoption is a deliberate user action — copy it to `<project-root>/.claude/skills/ai-harness-review/SKILL.md` (project-local, recommended) or `~/.claude/skills/ai-harness-review/SKILL.md` (global, opt-in only). Nothing is auto-installed. Details: `docs/MVP_OPERATOR_GUIDE_KR.md` sections 7–8.

## What this toolset does not do

- No global install. No system-wide CLI, no PATH mutation, no `~/.claude/` files written.
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
| `docs/CHATLOG_CONTRACT.md` | active operational | `log/chatlog/` layout and `summary.md` / `resume.md` canonical headings. |
| `docs/CLI_ENVIRONMENT_ASSUMPTIONS.md` | active operational | Canonical CLI/runtime dependency boundary. |
| `docs/DECISIONS.md` | mixed decision log | Bootstrap-era and active policy decisions. |
| `docs/EVIDENCE_CONTRACT.md` | active operational | `log/evidence/<scope>/<case>/` minimal capture contract. |
| `docs/LEGACY_KNOWLEDGE_TRANSFER.md` | historical reference | Legacy `ai-harness` → v1 migration mapping table. |
| `docs/MIGRATION_INVENTORY_SUMMARY.md` | historical reference | Frozen migration inventory counts. |
| `docs/MVP_OPERATOR_GUIDE_KR.md` | active operational | Korean operator guide for MVP flow, CLI usage, diagrams, and acceptance checklist. |
| `docs/POWERSHELL_POLICY.md` | active operational | Encoding, line-ending, file IO, and collection return rules. |
| `docs/REVIEWER_CONFIG_POLICY.md` | active operational | Reviewer config location, precedence, defaults, and MVP reviewer boundary. |
| `docs/REVIEW_RESULT_CONTRACT.md` | active operational | `result.md` / `result.json` minimum fields and `review-verify -RequireResult` binding rules. |
| `docs/TOOLING_POSITION.md` | active reference | Position statements for adjacent tools. |
