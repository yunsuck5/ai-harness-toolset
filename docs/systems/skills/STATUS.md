# skills — system status

Current status for the deployed instruction-surface architecture: the always-loaded snippet payload (`snippets/CLAUDE_SNIPPET.md` / `snippets/AGENTS_SNIPPET.md`) plus on-demand function-level skills (`snippets/claude-skills/**`). The **design source** is `docs/systems/skills/FUNCTION_LEVEL_SKILL_ARCHITECTURE_PLAN.md` (design-stage plan; it approves no batch by itself). Routing: `docs/current/SOURCE_OF_TRUTH.md` (Q10). Review artifact/verdict contract: `docs/contracts/review/REVIEW_RESULT_CONTRACT.md`.

This subsystem owns the snippet↔skill responsibility split (what stays always-loaded vs what becomes an on-demand skill). It does **not** own install / update / uninstall (LTS — `docs/systems/install-update/**`, routes via Q1), Brief (Q4), or Chatlog.

## Current state

- **One existing function-level skill:** `snippets/claude-skills/ai-harness-review/SKILL.md` (review-only; owns the full review lifecycle).
- **Always-loaded payload responsibility (per the plan):** for current implemented capabilities only — hard boundaries / forbidden rules, adoption discipline, path/topology invariants, role neutrality + reviewer-mode exclusion, the verdict quick reference, cross-task execution invariants, and explicit-prompt trigger routing. Review *procedure* is not restated in the payload; it lives in the `ai-harness-review` skill + the review contract, referenced by pointer.
- **Batch 1 landed** (commit `56de8d3`) as the first implementation batch. **Batch 2 is partially landed in this working tree** — 2B (BR-D-02 restore-offer-component retirement) + 2A (unsolicited session-start restore-offer removal); 2C (manual brief-skill extraction) and 2D (closeout) remain (see *Not yet done*). Batches 3–4 (plan §8) are not implemented. The plan approves no batch by itself; each is a separate scoped goal + review gate + explicit user approval.

## Completed ledger

| ID | Item | Closed at | Current meaning | Detail |
|---|---|---|---|---|
| SK-00 | Function-level skill architecture plan | `936969f` | design-stage plan source; approves no batch | `docs/systems/skills/FUNCTION_LEVEL_SKILL_ARCHITECTURE_PLAN.md` |
| SK-01 | Batch 1 — snippet review-procedure de-duplication | `56de8d3` | `snippets/CLAUDE_SNIPPET.md` / `AGENTS_SNIPPET.md` `## Review flow` reduced to routing + pointer to the `ai-harness-review` skill + the review contract, and the `## Execution discipline` section **removed entirely** (launch discipline owned by the skill step 5, review-scope-integrity relocated to the skill step 2, temporary-file cleanup generalized to `## Other rules`); the verdict quick reference (`## Result verdict vocabulary`) is retained as the single in-snippet home; no hard boundary / routing invariant dropped (review still fully specified via skill + contract) | plan §8 Batch 1; `docs/contracts/review/REVIEW_RESULT_CONTRACT.md` |

## Not yet done

Each is a separate scoped goal + Codex review gate + explicit user approval (plan §8); none is approved by the plan or by this status file.

- **Batch 2** — restore-offer removal + manual brief-skill extraction. *(2B — BR-D-02 restore-offer-component retirement — and 2A — unsolicited session-start restore-offer removal from the snippet + active surfaces — landed in this working tree; 2C manual brief-skill extraction remains. Full Batch 2 closeout (STATUS done-flip / SK-02 ledger) is deferred to 2D.)* **Batch 2C now carries a lifecycle prerequisite: 2C-0 (generic deployed-extension mirror + verification) must land before `ai-harness-brief` is snippet-routed** — a snippet routing to a skill the lifecycle does not force-mirror + verify would break current behavior; missing `ai-harness-brief` at its runtime destination after install/update is an install/update failure. Sequence: 2C-0 → 2C-1 (create skill) → 2C-2 (extract procedure; no large snippet fallback) → 2D. Governing policy: `docs/systems/install-update/GLOBAL_INSTALL_UPDATE_MODEL.md` §8A (plan §7 / §8).
- **Batch 3** — remove non-current items (Chatlog section, BF Level 3 note) from the snippet.
- **Batch 4** — review-polishing selective-capture vehicle decision (instruction vs skill; non-hook).

## Accepted residual risks

none — the Batch 1 `## Execution discipline` facts were resolved in-batch, not carried as a residual:

- The foreground→background **auto-conversion** reporting rule was **removed** (not relocated).
- The **review-scope-integrity** rule ("do not shrink a review's scope to avoid a long-running run") was **relocated** into `snippets/claude-skills/ai-harness-review/SKILL.md` (step 2, review scope integrity discipline).
- **Temporary-file cleanup** is now a general operator-hygiene rule in the snippet's `## Other rules` (the prior "delete only after separate explicit user approval" meaning was intentionally dropped); it is not review-specific.

The snippet's `## Execution discipline` section was therefore **removed entirely** (the review-run launch discipline is owned by `ai-harness-review` SKILL step 5). Managed-block section structure / H2 count is not a frozen invariant — a function-specific procedure section is removed once its procedure is owned by a function-level skill.
