# Reviewer Config Policy

## Config location

The effective reviewer config is `<ToolRoot>/config/reviewer.json`, where `<ToolRoot>` is resolved per invocation (see `docs/roadmap/SHARED_GLOBAL_INVOCATION_CONTRACT.md`). `review-prepare.ps1` reads it from the resolved ToolRoot.

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

Current as-built status of each key:

| key | status |
|---|---|
| `model` | **Enforced** — flows config → `meta.json` → Codex CLI `--model`. |
| `provider` | Metadata-only — recorded in `meta.json`, not passed to the Codex invocation. |
| `fallbackModel` | Metadata-only — recorded in `meta.json`; the single-shot cycle does not use it. |
| `reasoningEffort` | Metadata-only — recorded in `meta.json` and substituted into `input.md` as reviewer-visible prompt text; not a Codex CLI flag. |
| `sandbox` | Metadata-only — recorded in `meta.json`; the Codex invocation hardcodes `--sandbox read-only`. |
| `timeoutSeconds` | **Metadata-only / unenforced** — see below. |
| `outputFormat`, `resultFile` | Dead config — read by no script. |

### `timeoutSeconds` status

`timeoutSeconds` is currently **metadata-only and unenforced**. `review-prepare.ps1` records it into `meta.json` `reviewerConfig.timeoutSeconds`, but no script reads it back: `Invoke-CodexExec` in `review-run.ps1` / `review-cycle.ps1` runs the Codex CLI with no process timeout. The value does not bound the Codex review process.

`timeoutSeconds` is explicitly **not**:

- a review quality or completeness guarantee — review validity is judged by complete run artifacts, valid result binding, and `review-verify -RequireResult`;
- the Claude Code harness tool timeout — that is a separate harness-level value that governs the shell tool call and can trigger harness auto-background conversion;
- a background-conversion control — it has no effect on whether a run is foregrounded or backgrounded.

Whether to enforce, demote to explicit metadata-only, or remove `timeoutSeconds` is a separate future decision tracked in `docs/backlog/operations.md`. This document does not decide it.

## Output location

Reviewer output lives under `<project-root>/log/review/<run-id>/`. A root `codex-review-input.md` or `codex-review-result*.json` is forbidden.

## MVP reviewer boundary

- `-Reviewer codex` is the only supported reviewer in MVP.
- `review-cycle.ps1`은 user-triggered single-shot CLI이며, Codex CLI를 1회만 실행한다.
- `fallbackModel`은 config 형식 호환을 위해 유지되며, 현재 cycle은 사용하지 않는다.
- reviewer verdict는 commit / push / publish / merge / release / deployment 승인이 아니다.

Cycle 동작과 result 생성 contract는 `docs/REVIEW_RESULT_CONTRACT.md`에서 정의한다.

## Diagnostic Codex invocation reference

For diagnosing Codex CLI invocation compatibility, the cycle-equivalent command shape is:

```powershell
Get-Content -Raw -LiteralPath "log/review/<run-id>/input.md" |
  codex --ask-for-approval never exec --sandbox read-only --model <model> -c web_search=disabled --output-last-message "log/review/<run-id>/result.md" -
```

`review-cycle.ps1` remains the normal path for completed review records. Result generation and verification semantics are defined in `docs/REVIEW_RESULT_CONTRACT.md`.
