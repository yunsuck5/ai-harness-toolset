# Tooling Position

## Superpowers

Preferred CLI-only workflow reference, not a dependency.

## Serena

Early evaluation target for large game-development repos, not a core dependency.

## Sequential Thinking

Manual escalation only.

## Codex CLI

Default reviewer for the canonical two-step entry — `scripts/review-prepare.ps1` allocates the pass directory and seeds `input.md`; `scripts/review-run.ps1` invokes Codex CLI exactly once per user-triggered run with `--ask-for-approval never`, `--sandbox read-only`, `-c web_search=disabled`, and `--output-last-message`. No retry, no fallback model use, no auto-fix loop. `-Reviewer codex` is the only supported value; other reviewers fail explicitly. A diagnostic Codex invocation reference for invocation-compatibility checks is documented in `docs/policies/REVIEWER_CONFIG_POLICY.md`.

## ChatGPT Web

Milestone auditor.

## ai-harness-toolset

Deterministic project-local toolset.
