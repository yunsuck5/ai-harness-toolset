# AGENTS.md snippet (manual copy)

This snippet may be manually copied into a project's AGENTS.md by the user.

- Do not auto-mutate the root AGENTS.md.
- Review packets must live under `<project-root>/log/review/<run-id>/`.
- A stale review must fail.
- Do not use a root `codex-review-input.md`.
- A reviewer verdict does not approve commit, push, or publish.
- Reviewer config comes from `<project-root>/.ai-harness/config/reviewer.json` when deployed.
