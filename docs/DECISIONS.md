# Decisions

This is the **active** decision record. Bootstrap-era / historical decisions have been moved to `docs/archive/legacy-mvp/BOOTSTRAP_DECISIONS.md` (historical context only — not current guidance). For question→authority routing see `docs/current/SOURCE_OF_TRUTH.md`.

## Active policy decisions

- new human-facing docs are Korean by default (technical identifiers stay English)
- evidence capture is a manual convention first (`docs/EVIDENCE_CONTRACT.md`) — no script, wrapper, or schema enforcement in MVP
- chatlog retention is summary-first and resume-first (`docs/CHATLOG_CONTRACT.md`)
- Brief: canonical Brief is `<ProjectRoot>/log/brief/BRIEF.md` — a project-local, operator-local, source-control-excluded runtime artifact under `<ProjectRoot>/log/` (gitignored). Root `<ProjectRoot>/brief/` is **rejected**, and so is any user-home operator-local runtime root (e.g. `%USERPROFILE%\.ai-harness\projects\<project-key>\...`). Target persistent footprint = `<ProjectRoot>/log/` only — BRIEF, Chatlog, Evidence, and Review all live under that single runtime root. `scripts/brief-init.ps1` writes there and `scripts/brief-check.ps1` validates there; the primitives' destinations already match the canonical location. BF Level is save/restore capability maturity (not a path); BF Level 1/2 is manual save/restore discipline; BF Level 3 (deterministic Brief maintenance / validation / stale warning / session-start guidance / restore-offer) remains future scoped work — canonical in `docs/BRIEF_CONTRACT.md`. (This entry is the 3rd reconciliation. It supersedes the 2nd-reconciliation entry — "target repo product canonical Brief is `<ProjectRoot>/brief/BRIEF.md`; `<ProjectRoot>/log/brief/BRIEF.md` is the current source-side primitive seed destination, not promoted to product canonical" — which had itself superseded the 1st-reconciliation entry — "BRIEF (BF Level 3) is operator-local runtime state at `log/brief/BRIEF.md`; root `brief/` is forbidden". The 1st and 2nd entries are preserved as historical lineage; the 3rd is current. See `docs/BRIEF_CONTRACT.md` §"canonical Brief 자리" Historical lineage for the same three-step record.)
- raw transcript retention is optional
- handoff.md is an external Web/session handoff artifact, not a repo source artifact
- context-pressure trigger / pre-compact capture is a future optional candidate, not MVP implementation
- dependency boundary is canonical in `docs/CLI_ENVIRONMENT_ASSUMPTIONS.md`
- review result record contract is canonical in `docs/REVIEW_RESULT_CONTRACT.md`
- The canonical user-facing review entry is the two-step `scripts/review-prepare.ps1` + `scripts/review-run.ps1` flow (the legacy single-shot `review-cycle.ps1` driver has been removed from the operator path; see `docs/backlog/review.md` "Removed legacy review artifacts" and `docs/roadmap/POST_MVP_PLAN.md` §10 Completed `c81fe45` for the historical reason)
- `review-run.ps1` uses strict `## Verdict` parsing; failed parse preserves the failed `pass-NN/` on disk as evidence
- each pass directory `<ProjectRoot>/log/review/<review-task-id>/pass-NN/` is write-once: a pre-existing pass is rejected; recovery is allocating a fresh `pass-NN` under the same `<review-task-id>`
- `review-verify -RequireResult` validates completed-record binding against the canonical `input.md` + `result.md` pair
- review record retention is human-managed at `<review-task-id>/` directory (or per-`pass-NN/`) granularity
- adoption smoke test, actual reviewer workflow test, and actual development workflow usage test are separate milestones
- broader review result policies remain future candidates (`docs/REVIEW_RESULT_CONTRACT.md`)

## MVP closeout

- CLI-only MVP is closed. Closeout does not approve post-MVP implementation, scope expansion, or commit/push/release.
- Codex review subsystem moves to maintenance mode after closeout; new features require separate scoped approval.
- Post-MVP decisions (Brief system as post-MVP core, Chatlog system not yet implemented, BF Level 3 boundary, packaging via `package-toolset.ps1`, GJMNet adoption deferred) are recorded in `docs/roadmap/POST_MVP_PLAN.md`. That document is a record, not an implementation authorization.
