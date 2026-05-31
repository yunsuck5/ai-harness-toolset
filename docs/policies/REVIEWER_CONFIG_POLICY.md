# Reviewer Config Policy

## Config location

The effective reviewer config is `<ToolRoot>/config/reviewer.json`, where `<ToolRoot>` is resolved per invocation (see `docs/contracts/global-invocation/SHARED_GLOBAL_INVOCATION_CONTRACT.md`). `review-prepare.ps1` reads it from the resolved ToolRoot.

| Role | Path |
|---|---|
| Canonical source config | `config/reviewer.json` in the ai-harness-toolset source repo. In shared/global mode this is the build input materialized into the resolved runtime ToolRoot. |
| Effective config — shared/global mode | `<ToolRoot>/config/reviewer.json` of the resolved runtime ToolRoot (for example, the global stable install). This is the current adoption shape. |
| Effective config — legacy project-local copy mode | `<project-root>/.ai-harness/config/reviewer.json`. This path applies only to the legacy project-local copy mode, not to current shared/global adoption. |

The adjacent schema `config/reviewer.schema.json` documents this file's keys regardless of which ToolRoot resolves it.

## Precedence

```
explicit CLI parameter > config/reviewer.json > built-in safe default
```

## Defaults

- Default model: `gpt-5.5`
- Fallback model: `gpt-5.4`
- Default reasoning effort: `medium`
- High effort is recommended for high-risk architecture, migration, release, or security-sensitive review.
- `xhigh` is not a default because it is model-dependent.

## Constraints

- Reviewer model and effort must remain config-driven.
- Script-level hardcoding of model / effort / timeout / sandbox is forbidden except as a final fallback.

The bullets above state the intended policy direction. The section below records the current as-built enforcement status, which does not yet match that intent for every key.

## Config key schema and enforcement status

`config/reviewer.json` must stay pure JSON with no comments. The per-key documentation lives in the adjacent schema `config/reviewer.schema.json`, which carries a `description` for every key covering its nominal meaning, where it is read, and its current runtime enforcement status.

Current as-built status of each key (in terms of the canonical operator-facing flow — config → Codex invocation / `input.md`):

| key | status |
|---|---|
| `model` | **Enforced** — passed to the Codex CLI as `--model`. |
| `provider` | Metadata-only — informational; not passed to the Codex invocation. |
| `fallbackModel` | Metadata-only — kept for config-schema compatibility; the single-shot run does not use it. |
| `reasoningEffort` | Metadata-only — config-schema compatibility; not surfaced into the canonical AI-authored `input.md` and not a Codex CLI flag. |
| `sandbox` | Metadata-only — informational; the Codex invocation hardcodes `--sandbox read-only`. |
| `timeoutSeconds` | **Metadata-only / unenforced** — see below. |
| `outputFormat`, `resultFile` | Dead config — read by no script. |

> The canonical operator-facing artifact set is exactly `<ProjectRoot>/log/review/<review-task-id>/pass-NN/input.md` + `result.md` (`docs/contracts/review/REVIEW_RESULT_CONTRACT.md`). Current scripts emit this canonical layout directly; sidecar files outside that pair (for example `meta.json`, `target-files.list`, `result.json`) are not produced on the operator path and are not part of the contract. Historical references to those removed-legacy artifacts are preserved in git history and are not operator paths.

### `timeoutSeconds` status

`timeoutSeconds` is currently **metadata-only and unenforced**. The single-shot run executes the Codex CLI with no process timeout, so the value does not bound the Codex review process.

`timeoutSeconds` is explicitly **not**:

- a review quality or completeness guarantee — review validity is judged by the canonical artifact pair (`input.md`, `result.md`) and the deterministic gates listed in `docs/contracts/review/REVIEW_RESULT_CONTRACT.md` §4;
- the Claude Code harness tool timeout — that is a separate harness-level value that governs the shell tool call and can trigger harness auto-background conversion;
- a background-conversion control — it has no effect on whether a run is foregrounded or backgrounded.

Whether to enforce, demote to explicit metadata-only, or remove `timeoutSeconds` is a separate future decision tracked as review backlog candidate RV-B-02 (`docs/systems/review/BACKLOG.md`). This document does not decide it.

## Output location

Reviewer output lives under `<ProjectRoot>/log/review/<review-task-id>/pass-NN/` — the canonical two-level layout that current scripts emit directly (`docs/contracts/review/REVIEW_RESULT_CONTRACT.md`). A root `codex-review-input.md` or `codex-review-result*.json` is forbidden.

## Reviewer boundary

- `-Reviewer codex` is the only supported reviewer.
- The canonical review entry is the two-step `scripts/review-prepare.ps1 -ReviewTaskId <id> [-Pass <pass-NN>]` → AI authors the pass `input.md` at `<ProjectRoot>/log/review/<review-task-id>/pass-NN/input.md` → `scripts/review-run.ps1 -ReviewTaskId <id> -Pass <pass-NN>` flow. Codex CLI is invoked exactly once per `review-run.ps1` call.
- `fallbackModel` is kept for config-schema compatibility; the single-shot run does not use it.
- reviewer verdict is not approval for commit / push / publish / merge / release / deployment.

Canonical artifact set and verdict semantics are defined in `docs/contracts/review/REVIEW_RESULT_CONTRACT.md`.

## Diagnostic Codex invocation reference

For diagnosing Codex CLI invocation compatibility, the equivalent command shape (matching what `scripts/review-run.ps1` runs internally against the canonical pass directory) is:

```powershell
# Paths below use the canonical <review-task-id>/pass-NN/ layout per
# docs/contracts/review/REVIEW_RESULT_CONTRACT.md.
Get-Content -Raw -LiteralPath "log/review/<review-task-id>/pass-NN/input.md" |
  codex --ask-for-approval never exec --sandbox read-only --model <model> -c web_search=disabled --output-last-message "log/review/<review-task-id>/pass-NN/result.md" -
```

The normal path for a completed review record is the two-step `review-prepare.ps1` + `review-run.ps1` flow. The canonical contract is `docs/contracts/review/REVIEW_RESULT_CONTRACT.md`.
