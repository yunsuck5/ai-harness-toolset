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

`log/` is a runtime artifact root. It is not source payload. It is gitignored by default and is not part of any source snapshot.

## Prepare and verify a review packet

The review subsystem is the quality-control gate. It is built around two scripts.

`review-prepare.ps1` creates a fresh review packet:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/review-prepare.ps1 `
    -TargetPath <relative-or-absolute-target-path> `
    -Stage <design|implementation|test|review|release> `
    -Purpose '<short purpose string>'
```

This generates a new `<run-id>` and writes:

```
<project-root>/log/review/<run-id>/meta.json
<project-root>/log/review/<run-id>/input.md
```

`meta.json` records the target file SHA-256, the source repo HEAD, the reviewer config (resolved from `<tool-root>/config/reviewer.json` if present), and a freshness policy. `input.md` is rendered from `templates/review-input.md` and is the file a reviewer reads.

`review-verify.ps1` checks an existing run.

Default mode verifies that the prepared packet is still bound to the current target file:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/review-verify.ps1 -RunId <run-id>
```

A target whose SHA-256 has changed since the packet was prepared fails verification (stale packet).

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

The toolset does not modify any `CLAUDE.md` or `AGENTS.md`, global or project-local. It only ships text snippets the user may choose to paste manually:

- `snippets/CLAUDE_SNIPPET.md`
- `snippets/AGENTS_SNIPPET.md`

Pasting is a deliberate user action. Nothing in this toolset auto-updates either file, and the snippets explicitly forbid auto-mutation when copied.

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
- No review-run wrapper. The reviewer (Codex CLI, ChatGPT Web, a human, or another tool) is invoked outside this toolset.
- No evidence runner, wrapper, or schema validator.
- No chatlog hook, parser, browser automation, DB, or retention automation.
- No CI integration, handoff generator, or workflow engine.
- No source snapshot zip or changed-files snapshot zip generation built into the toolset.
- Commits and pushes always require explicit user approval. Reviewer verdicts do not approve commits, pushes, or publishes.

## Suggested first target-project dry run

The first time the toolset is adopted into a real target project, validate it manually by walking through the flow above on that project:

1. Copy the four source folders into `<project-root>/.ai-harness/`.
2. Run `.ai-harness/scripts/log-init.ps1` and confirm `log/chatlog/`, `log/evidence/`, `log/review/` exist.
3. Run `.ai-harness/scripts/review-prepare.ps1` against a real file in the target project and confirm `meta.json` and `input.md` appear under `log/review/<run-id>/`.
4. Run `.ai-harness/scripts/review-verify.ps1 -RunId <run-id>` and confirm a default-mode `PASS`.
5. Modify the target file and re-run verify; confirm a stale-packet failure.
6. Capture one evidence case under `log/evidence/<scope>/<case>/` by hand following the source repo's `docs/EVIDENCE_CONTRACT.md`.
7. Write a minimal `log/chatlog/current/summary.md` and `resume.md` by hand following the source repo's `docs/CHATLOG_CONTRACT.md`.

There is no dry-run script, and one is not planned. The dry run is the manual flow itself, executed by the user against a real project.

## Documentation

See `docs/` for scope, environment assumptions, tooling position, PowerShell policy, reviewer config policy, evidence contract, chatlog contract, review result contract, legacy knowledge transfer, decisions, and migration inventory summary.
