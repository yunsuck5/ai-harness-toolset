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
- The first seed must not call Codex automatically.

## Output location

Future reviewer output must live under `<project-root>/log/review/<run-id>/`.

A root `codex-review-input.md` or `codex-review-result*.json` is forbidden.
