# Decisions

## Bootstrap and historical decisions

- repo name: ai-harness-toolset
- remote created
- local clone created
- branch: main
- previous v0.1 seed attempt discarded
- ai-harness.zip is the initial migration source only
- legacy knowledge transfer must be explicit
- `.gitattributes` policy migrated from legacy ai-harness
- PowerShell encoding/codepage rules migrated as policy
- reviewer config externalized into `config/reviewer.json`
- no Claude Code project init
- no Codex project init
- v2 bootstrap packet remains archival/reference

## Active policy decisions

- new human-facing docs are Korean by default (technical identifiers stay English)
- evidence capture is a manual convention first (`docs/EVIDENCE_CONTRACT.md`) — no script, wrapper, or schema enforcement in MVP
- chatlog retention is summary-first and resume-first (`docs/CHATLOG_CONTRACT.md`)
- raw transcript retention is optional
- handoff.md is an external Web/session handoff artifact, not a repo source artifact
- context-pressure trigger / pre-compact capture is a future optional candidate, not MVP implementation
- dependency boundary is canonical in `docs/CLI_ENVIRONMENT_ASSUMPTIONS.md`
- review result record contract is canonical in `docs/REVIEW_RESULT_CONTRACT.md`
- `review-cycle.ps1` is the MVP user-facing review entrypoint
- `review-cycle.ps1` uses strict verdict parsing; failed parse preserves the run as evidence
- `review-prepare.ps1` is write-once per `<run-id>`: a pre-existing run directory is rejected and the seeded `meta.json` is never overwritten; recovery is a fresh run-id
- `review-verify -RequireResult` validates completed-record binding
- review record retention is human-managed at `<run-id>` directory granularity
- adoption smoke test, actual reviewer workflow test, and actual development workflow usage test are separate milestones
- broader review result policies remain future candidates (`docs/REVIEW_RESULT_CONTRACT.md`)

## MVP closeout

- CLI-only MVP is closed. Closeout does not approve post-MVP implementation, scope expansion, or commit/push/release.
- Codex review subsystem moves to maintenance mode after closeout; new features require separate scoped approval.
- Post-MVP decisions (Brief system as post-MVP core, Chatlog system not yet implemented, BF Level 3 boundary, packaging via `package-toolset.ps1`, GJMNet adoption deferred) are recorded in `docs/roadmap/POST_MVP_PLAN.md`. That document is a record, not an implementation authorization.
