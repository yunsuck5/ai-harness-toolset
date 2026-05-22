# review — backlog (open candidates)

Open, not-yet-started review-subsystem candidates (v2 §9.2 — open work only). Each item routes to the full text in `docs/backlog/review.md` / `docs/backlog/operations.md`; that full text is the detailed source and is not duplicated here. None of these is approved for implementation; each needs a separate scoped goal + review.

| ID | Open candidate | Source item | Note |
|---|---|---|---|
| RV-B-01 | Review 2-pass / profile for user-facing instruction text | `docs/backlog/review.md` "Review 2-pass / profile for user-facing instruction text" | trial/profile concept; not adopted |
| RV-B-02 | `timeoutSeconds` enforcement decision debt | `docs/backlog/operations.md` "`timeoutSeconds` enforcement decision debt" | decide enforce / demote-to-metadata-only / remove (`docs/REVIEWER_CONFIG_POLICY.md` defers it) |
| RV-B-03 | Review result wrapper / fence artifact hygiene | `docs/backlog/operations.md` "Review result wrapper / fence artifact hygiene" | artifact-level fix candidate (one observed wrapper case) |
| RV-B-04 | Review subsystem no-exec / no-write reviewer contract | `docs/backlog/operations.md` "Review subsystem no-exec / no-write reviewer contract" | contract-level reviewer-role definition candidate; kept separate from RV-B-03 |

Closed review-subsystem items are recorded in `docs/systems/review/STATUS.md` (completed-ledger). Removed-legacy review artifacts (review-cycle / `meta.json` / `result.json` / `target-files.list` / `<run-id>` flat layout) are historical-reason only in `docs/backlog/review.md` / `operations.md`, never operator paths.
