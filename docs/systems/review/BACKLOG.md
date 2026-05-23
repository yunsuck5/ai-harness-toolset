# review — backlog (open candidates)

Open, not-yet-started review-subsystem candidates. **This file is the open-work entrypoint for the review subsystem** — each row (ID + candidate + direction note) is the triage-level entry, sufficient to scope a future goal. The original full analysis of each item is preserved as historical provenance in `docs/archive/backlog/` (not a current dependency). None of these is approved for implementation; each needs a separate scoped goal + review.

| ID | Open candidate | Direction (triage) | Historical provenance |
|---|---|---|---|
| RV-B-01 | Review 2-pass / profile for user-facing instruction text | trial/profile concept; not adopted — decide whether a second profiling pass adds value | `docs/archive/backlog/review.md` |
| RV-B-02 | `timeoutSeconds` enforcement decision debt | decide: enforce / demote-to-metadata-only / remove (`docs/policies/REVIEWER_CONFIG_POLICY.md` currently defers it; it is metadata-only/unenforced) | `docs/archive/backlog/operations.md` |
| RV-B-03 | Review result wrapper / fence artifact hygiene | artifact-level (`result.md` on-disk shape). When Codex `--output-last-message` dumps the reviewer's last message, a fenced/wrapper rendering can appear (e.g. if the Codex sandbox rejects a write tool). Decide whether to normalize that fence/wrapper rendering. NOT a change to the `## Verdict` shape contract. | `docs/archive/backlog/operations.md` |
| RV-B-04 | Review subsystem no-exec / no-write reviewer contract | contract-level reviewer-role boundary: explicitly frame what the reviewer does **not** do (no exec, no write). Distinct from RV-B-03 (that is artifact-level; this is the role contract). NOT a change to the `## Verdict` shape contract. | `docs/archive/backlog/operations.md` |

Closed review-subsystem items are recorded in `docs/systems/review/STATUS.md` (completed-ledger). Removed-legacy review artifacts (review-cycle / `meta.json` / `result.json` / `target-files.list` / `<run-id>` flat layout) are historical-reason only in `docs/archive/backlog/review.md` / `operations.md`, never operator paths.
