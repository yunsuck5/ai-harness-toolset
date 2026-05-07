# Reviewer Config Policy

## Config location

| Layout | Path |
|---|---|
| Source repo | `config/reviewer.json` |
| Target project | `<project-root>/.ai-harness/config/reviewer.json` |

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
