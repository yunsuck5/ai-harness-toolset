# Tooling Position

## Superpowers

Preferred CLI-only workflow reference, not a dependency.

## Serena

Early evaluation target for large game-development repos, not a core dependency.

## Sequential Thinking

Manual escalation only.

## Codex CLI

Default reviewer for `scripts/review-cycle.ps1`. The cycle invokes Codex CLI exactly once per user-triggered run with `--ask-for-approval never`, `--sandbox read-only`, `-c web_search=disabled`, and `--output-last-message`. No retry, no fallback model use, no auto-fix loop. `-Reviewer codex` is the only supported value in MVP; other reviewers fail explicitly. Manual Codex invocation outside `review-cycle.ps1` remains supported as a fallback recipe.

## ChatGPT Web

Milestone auditor.

## ai-harness-toolset

Deterministic project-local toolset.
