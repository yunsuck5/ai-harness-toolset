# review — system status

Current status for the Codex review subsystem. The **canonical artifact contract** is `docs/contracts/review/REVIEW_RESULT_CONTRACT.md`; reviewer **config** is `docs/policies/REVIEWER_CONFIG_POLICY.md`; effort/cost operating guidance is `docs/policies/REVIEW_EFFORT_GUIDE.md`. Routing: `docs/current/SOURCE_OF_TRUTH.md` (Q2, Q3).

## Current state

- **Maintenance mode.** No new feature / reviewer adapter / multi-reviewer orchestration / review-history DB / cross-run aggregation / automatic retention without a separate scoped approval. Bug fix and contract clarification are in-scope.
- **Canonical task/pass topology** is the current shape: one Codex attempt per `pass-NN`, grouped under one `<review-task-id>` directory; record = `<ProjectRoot>/log/review/<review-task-id>/pass-NN/input.md` (AI-authored) + `result.md` (Codex-authored). No sidecar JSON, no hash-binding files, no external staging, no flat run-id layout.
- **Operator entrypoint:** `scripts/review-prepare.ps1` → `scripts/review-run.ps1` (one Codex execution per call), with `scripts/review-verify.ps1` as the post-hoc canonical-artifact check and `scripts/review-input-verify.ps1` as the input gate. Natural-language UX: `docs/user_guide/OPERATOR_GUIDE_KR.md` §7 + `snippets/claude-skills/ai-harness-review/SKILL.md`.
- Verdict (`yes` / `no` / `yes with risk`) never auto-approves commit / push / publish / merge / release.

## Completed ledger

| ID | Item | Closed at | Current meaning | Detail |
|---|---|---|---|---|
| RV-01 | Codex review subsystem operational; entered maintenance mode | — | review flow stable; maintenance scope only | `docs/decisions/POST_MVP_PLAN.md` §2 |
| RV-02 | Canonical review task/pass topology — contract alignment | `a5d94a5` | source-of-truth wording aligned to task/pass shape | `docs/decisions/POST_MVP_PLAN.md` §10 |
| RV-03 | Canonical review task/pass topology — implementation | `c81fe45` | script/template/I-O shape aligned to RV-02; removed-legacy sidecar artifacts dropped from normal path | `docs/decisions/POST_MVP_PLAN.md` §10 |
| RV-04 | Review effort/cost operating guide added | — | advisory only; introduces no automatic gate | `docs/policies/REVIEW_EFFORT_GUIDE.md` |

## Open / historical

- Open review-subsystem backlog candidates are consolidated in `docs/systems/review/BACKLOG.md` (RV-B-01..RV-B-04); their full text and the removed-legacy historical items remain in `docs/archive/backlog/review.md` / `docs/archive/backlog/operations.md` (classification index: `docs/backlog/INDEX.md`). Removed-legacy review-cycle / `meta.json` / `result.json` / `target-files.list` / `<run-id>` identifiers are historical reason only, never operator paths.
