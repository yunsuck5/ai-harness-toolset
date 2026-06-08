# review — backlog (open candidates)

Open, not-yet-started review-subsystem candidates. **This file is the open-work entrypoint for the review subsystem** — each row (ID + candidate + direction note) is the triage-level entry, sufficient to scope a future goal. The original full analysis of each item is preserved in git history (historical provenance only, not a current dependency). None of these is approved for implementation; each needs a separate scoped goal + review.

| ID | Open candidate | Direction (triage) | Historical provenance |
|---|---|---|---|
| RV-B-01 | Review 2-pass / profile for user-facing instruction text | trial/profile concept; not adopted — decide whether a second profiling pass adds value | git history |
| RV-B-03 | Review result wrapper / fence artifact hygiene | artifact-level (`result.md` on-disk shape): when Codex `--output-last-message` dumps the last message, a fenced/wrapper rendering can appear. Decide whether to normalize it. NOT a `## Verdict` shape change. | git history |
| RV-B-04 | Review subsystem no-exec / no-write reviewer contract | contract-level reviewer-role boundary: explicitly frame what the reviewer does **not** do (no exec, no write). Distinct from RV-B-03 (artifact-level). R1 first batch (Markdown evidence convention) is **closed** (`2997bb3`; STATUS ledger RV-B-04(R1)); open residual = the remaining role-boundary framing. NOT a `## Verdict` shape change. | git history |
| RV-B-05 | Review input governance (open channel) | input.md / result.md wording + informational dimensions + verdict-semantics governance. Open residual = accumulated review-method governance signals once a clear pattern emerges + verdict-vocabulary migration beyond the current narrowing. Closed incremental batches (LTS Phase 1 / 1A / IDEAS gov) are in STATUS completed-ledger; deterministic-lint ideas stay non-goals (`REVIEW_RESULT_CONTRACT.md` §10 / §3c.5; Counter-argument Option A not introduced); devil's-advocate / multi-reviewer = idea-only (`IDEAS.md`). | git history |
| **[CLOSED]** RV-B-06 | Reviewer runtime provenance in the result artifact | Closed — see STATUS ledger RV-B-06. | git history |
| **[CLOSED]** RV-B-07 | U9 config-backed category-effort policy | Closed — see STATUS ledger RV-B-07. | git history |
| **[CLOSED]** RV-B-08 | Review artifact perspective layout — strict C1 canonical | Closed `460ee3e` — see STATUS ledger RV-B-08. | git history |

Closed review-subsystem items are recorded in `docs/systems/review/STATUS.md` (completed-ledger). Removed-legacy review artifacts (review-cycle / `meta.json` / `result.json` / `target-files.list` / `<run-id>` flat layout) are historical-reason only (preserved in git history), never operator paths.
