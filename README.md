# ai-harness-toolset

Project-local deterministic toolset for Claude / Codex workflows.

ai-harness-toolset is a project-local deterministic toolset. It is not an orchestrator, not an installer, and not packaged. Adoption is copy-only and CLI-only. Source folders are copied into a `.ai-harness/` payload at the target project root, and runtime output is written under `<project-root>/log/`. Legacy knowledge is explicitly transferred, never wholesale copied.

## Quick start: copy-only target project adoption

There is no installer. The user (or the user's AI agent under explicit instruction) manually copies four source folders into the target project.

From this source repo:

```
config/
scripts/
snippets/
templates/
```

Into the target project:

```
<project-root>/.ai-harness/config/
<project-root>/.ai-harness/scripts/
<project-root>/.ai-harness/snippets/
<project-root>/.ai-harness/templates/
```

Rules:

- Copy only the four folders above. Do not copy `docs/`, `.git/`, `log/`, or repo-level files such as `README.md` or `.gitattributes`.
- Do not modify any global file. No `~/.claude/`, no global `CLAUDE.md`, no global `AGENTS.md`.
- The `.ai-harness/` payload lives entirely inside the target project root and can be removed by deleting that directory.
- After copying, `<project-root>/.ai-harness/scripts/` becomes the script root for that project. The source repo's `scripts/` is no longer used by the target project.

## Source repo to target payload mapping

| Source repo | Target payload |
|---|---|
| `config/` | `<project-root>/.ai-harness/config/` |
| `scripts/` | `<project-root>/.ai-harness/scripts/` |
| `snippets/` | `<project-root>/.ai-harness/snippets/` |
| `templates/` | `<project-root>/.ai-harness/templates/` |

`docs/`, `tests/`, `log/`, and repo metadata are source-repo only and are not part of the deployed payload. In particular, `docs/` is never copied into `<project-root>/.ai-harness/`. When this README or the dry run below refers to `docs/EVIDENCE_CONTRACT.md`, `docs/CHATLOG_CONTRACT.md`, `docs/REVIEW_RESULT_CONTRACT.md`, or any other `docs/*.md`, read those files from this source repo, not from the target project.

## Initialize runtime log layout

Once the payload is in place (or when working inside this source repo), create the runtime log tree.

From the source repo root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/log-init.ps1
```

From a target project root (after the copy step above):

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .ai-harness/scripts/log-init.ps1
```

This creates:

```
<project-root>/log/
<project-root>/log/chatlog/
<project-root>/log/evidence/
<project-root>/log/review/
```

`log/` is a runtime artifact root. It is not source payload. It is not part of any source snapshot.

This source repo already gitignores `log/`. Target projects do not inherit that `.gitignore` automatically. Target adopters must manually ensure the target project's own `.gitignore` contains `log/`. The toolset never edits a target project `.gitignore`, and no script in this toolset creates or modifies one.

There is no automatic retention or pruning for `log/review/<run-id>/`. Each `<run-id>` directory is a self-contained review record. Cleanup is manual: delete an entire `<run-id>` directory when it is no longer needed for audit, handoff, or debugging. The full retention policy lives in `docs/REVIEW_RESULT_CONTRACT.md`.

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

Boundaries:

- Single-shot only. Not a watcher, hook, daemon, workflow engine, or productized `review-run`.
- One Codex CLI execution. No retry, no fallback model use, no auto-fix loop.
- Never auto-commits, auto-pushes, or auto-publishes. Verdict is not commit/push/publish/merge/release approval.
- Only `-Reviewer codex` is supported in MVP. Other reviewers fail explicitly.
- `result.md` verdict must be exactly one of `yes`, `no`, `yes with risk`. On parse failure, `review-cycle.ps1` exits non-zero and does not create `result.json`; the human resolves it via the manual recipe below.

If `-TargetFiles` is omitted, `review-cycle.ps1` resolves tracked changed files from `git status`. Untracked files outside `log/` cause an explicit failure that requests an explicit `-TargetFiles` list.

## Prepare and verify a review packet (component view)

The component scripts under `review-cycle.ps1` are still callable directly. This is the manual / debug path used when `review-cycle.ps1` cannot run end to end (for example, when verdict parsing fails and the human completes `result.md` and `result.json` by hand).

`review-prepare.ps1` creates a fresh review packet:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/review-prepare.ps1 `
    -TargetPath <relative-or-absolute-target-path> `
    -Stage <design|implementation|test|review|release> `
    -Purpose '<short purpose string>'
```

For a multi-file change-set, pass `-TargetFiles` instead of (or in addition to) `-TargetPath`:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/review-prepare.ps1 `
    -TargetFiles file1,file2,file3 `
    -Stage implementation `
    -Purpose '<short purpose string>'
```

The first `-TargetFiles` entry becomes the primary target unless `-TargetPath` is also supplied. All entries are recorded under `meta.targetFiles[]` as repo-relative forward-slash paths with lowercase SHA-256.

This generates a new `<run-id>` and writes:

```
<project-root>/log/review/<run-id>/meta.json
<project-root>/log/review/<run-id>/input.md
```

`meta.json` records the primary target file SHA-256, the reviewed change-set under `targetFiles[]` (each entry has a repo-relative `path` and a lowercase `sha256`), the source repo HEAD, the reviewer config (resolved from `<tool-root>/config/reviewer.json` if present), and a freshness policy. `input.md` is rendered from `templates/review-input.md` and is the file a reviewer reads.

`review-verify.ps1` checks an existing run.

Default mode verifies that the prepared packet is still bound to the current target file:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/review-verify.ps1 -RunId <run-id>
```

A target whose SHA-256 has changed since the packet was prepared fails verification (stale packet). When `meta.targetFiles[]` is non-empty, `review-verify.ps1` rehashes every entry in addition to the primary target; the first stale path is reported.

`-RequireResult` mode additionally enforces a completed review record (`result.md` + `result.json` written by a human after the reviewer judgment is in):

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/review-verify.ps1 -RunId <run-id> -RequireResult
```

The exact binding rules and the `result.json` minimum field set are defined in `docs/REVIEW_RESULT_CONTRACT.md`. From a deployed target project, replace `scripts/...` with `.ai-harness/scripts/...` in the commands above.

## Manual evidence capture

The evidence subsystem records command, test, and execution facts. There is no runner, wrapper, or schema validator in MVP.

A captured case lives at:

```
<project-root>/log/evidence/<scope>/<case>/
```

Recommended files inside a case directory:

- `command.txt` — the exact command line that was executed
- `exit-code.txt` — the process exit code on a single line
- `stdout.txt` — captured standard output (optional but kept as a 0-byte file if the stream was empty)
- `stderr.txt` — captured standard error (same 0-byte rule)
- `notes.md` — free-form human notes, environment fingerprint, repro conditions
- `files/` — input/output snapshots when needed

The full procedure (what to capture, when, and how to preserve `$LASTEXITCODE` correctly) is documented in `docs/EVIDENCE_CONTRACT.md`. Evidence is project-local runtime artifact only and is never committed.

## Manual chatlog retention

The chatlog subsystem preserves AI-assisted session work in a form a future agent or human can pick up. It is a retention and resume tool, not a quality gate.

Layout:

```
<project-root>/log/chatlog/current/
  resume.md
  summary.md

<project-root>/log/chatlog/<session-id>/
  resume.md
  summary.md
```

Two files are the minimum bar:

- `summary.md` — what this session decided and changed (past tense). Canonical headings: `## Context`, `## Decisions`, `## Evidence`, `## Next action`, `## Carry-over`.
- `resume.md` — what the next agent should do first (present/future tense). Canonical headings: `## Current state`, `## Last completed action`, `## Current scope`, `## Next single action`, `## Do not do`, `## Files to inspect first`, `## Open risks`, `## Pending user decision`.

`current/` is the active session workspace. Promotion to `<session-id>/` is a manual decision and is not automated. Templates live under `templates/`. Full rules and the optional sections (`decisions.md`, `phases/`, `raw-transcript.md`) are in `docs/CHATLOG_CONTRACT.md`.

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

Adoption rules:

- The managed block body is copied from the source snippet as-is. No ad-hoc summary, translation, or rewrite during adoption.
- Updating means replacing only the matching managed block.
- Removing means deleting only the matching managed block.
- Content outside the managed block must not be changed.
- Whole-file overwrite of root `CLAUDE.md` / `AGENTS.md` is forbidden.

## review / evidence / chatlog boundary

The three runtime trees under `log/` have separate responsibilities and do not enforce each other:

- **review** — quality-control gate. Driven by `review-prepare.ps1` / `review-verify.ps1`. Centered on reviewer input freshness and artifact binding.
- **evidence** — command, test, and execution facts. Manual minimal capture contract. No runner exists.
- **chatlog** — retention, restoration, and session reconstruction. Centered on `summary.md` / `resume.md`. Not a quality gate.

A chatlog summary may reference an evidence path or a review run-id, but cross-tree integrity is not validated by any script.

## What this toolset does not do

- No global install. No system-wide CLI, no PATH mutation, no `~/.claude/` files written.
- No automatic global rollback or uninstall flow.
- No automatic mutation of any global `CLAUDE.md` or global `AGENTS.md`.
- No automatic mutation of project-root `CLAUDE.md` or `AGENTS.md`. Snippets are pasted manually by the user.
- No review-run productization wrapper, watcher, hook, daemon, or workflow engine. `review-cycle.ps1` is a single-shot user-triggered CLI; it is not productized into a long-running runner.
- No auto-fix loop, auto-commit, or auto-push. `review-cycle.ps1` runs Codex once and stops; commit/push remain explicit user actions.
- No multi-reviewer orchestration. Only `-Reviewer codex` is supported in MVP.
- No evidence runner, wrapper, or schema validator.
- No chatlog hook, parser, browser automation, DB, or retention automation.
- No CI integration, handoff generator, or scheduled runner.
- No source snapshot zip or changed-files snapshot zip generation built into the toolset.
- Commits and pushes always require explicit user approval. Reviewer verdicts do not approve commits, pushes, publishes, merges, releases, or deployments.

## Suggested first target-project dry run

The first time the toolset is adopted into a real target project, validate it manually by walking through the flow above on that project:

1. Copy the four source folders into `<project-root>/.ai-harness/`.
2. Run `.ai-harness/scripts/log-init.ps1` and confirm `log/chatlog/`, `log/evidence/`, `log/review/` exist.
3. Run `.ai-harness/scripts/review-cycle.ps1 -Stage implementation -Purpose 'adoption smoke' -TargetFiles <file> -Context ... -RequiredInspectionPaths ... -ReviewQuestions ... -Constraints ...` against a real file and confirm `review-cycle: PASS` plus `result.json` under `log/review/<run-id>/`. (If Codex CLI is unavailable, skip to step 4 and exercise the components individually.)
4. Run `.ai-harness/scripts/review-prepare.ps1` against a real file in the target project and confirm `meta.json` and `input.md` appear under `log/review/<run-id>/`.
5. Run `.ai-harness/scripts/review-verify.ps1 -RunId <run-id>` and confirm a default-mode `PASS`.
6. Modify the target file and re-run verify; confirm a stale-packet failure.
7. Capture one evidence case under `log/evidence/<scope>/<case>/` by hand following the source repo's `docs/EVIDENCE_CONTRACT.md`.
8. Write a minimal `log/chatlog/current/summary.md` and `resume.md` by hand following the source repo's `docs/CHATLOG_CONTRACT.md`.

There is no dry-run script, and one is not planned. The dry run is the manual flow itself, executed by the user against a real project.

## Documentation map

Each file under `docs/` has a fixed role. Tags:

- `active operational` — current source-of-truth for tool behavior, contracts, or policy.
- `active reference` — current but advisory or boundary-only; not a binding rule by itself.
- `mixed decision log` — active and historical decisions are interleaved; read each entry on its own merits.
- `historical reference` — migration-era record; not a source-of-truth for current behavior.

| File | Role | One-line role |
|---|---|---|
| `docs/AI_HARNESS_TOOLSET_SCOPE.md` | active operational | Project nature, in/out of scope, source-vs-target payload mapping. |
| `docs/CHATLOG_CONTRACT.md` | active operational | Recommended `log/chatlog/` layout and `summary.md` / `resume.md` canonical headings. |
| `docs/CLI_ENVIRONMENT_ASSUMPTIONS.md` | active reference | External CLI / MCP tooling that may exist but is not depended on. |
| `docs/DECISIONS.md` | mixed decision log | Bootstrap-era and active policy decisions are interleaved. |
| `docs/EVIDENCE_CONTRACT.md` | active operational | `log/evidence/<scope>/<case>/` minimal capture contract and manual recipe. |
| `docs/LEGACY_KNOWLEDGE_TRANSFER.md` | historical reference | Legacy `ai-harness` → v1 migration mapping table. |
| `docs/MIGRATION_INVENTORY_SUMMARY.md` | historical reference | Frozen migration inventory counts from the legacy `ai-harness.zip` source. |
| `docs/POWERSHELL_POLICY.md` | active operational | Encoding, line-ending, file IO, and collection return rules. |
| `docs/REVIEWER_CONFIG_POLICY.md` | active operational | Reviewer config location, precedence, defaults, MVP boundary, and manual Codex recipe. |
| `docs/REVIEW_RESULT_CONTRACT.md` | active operational | `result.md` / `result.json` minimum fields and `review-verify -RequireResult` binding rules. |
| `docs/TOOLING_POSITION.md` | active reference | Position statements for adjacent tools (Superpowers, Serena, Sequential Thinking, Codex CLI, ChatGPT Web). |
