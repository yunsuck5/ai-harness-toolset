# skills — system status

Current status for the deployed instruction-surface architecture: the always-loaded snippet payload (`snippets/CLAUDE_SNIPPET.md` / `snippets/AGENTS_SNIPPET.md`) plus on-demand function-level skills (`snippets/claude-skills/**`). The **design source** is `docs/systems/skills/FUNCTION_LEVEL_SKILL_ARCHITECTURE_PLAN.md` (design-stage plan; it approves no batch by itself). Routing: `docs/current/SOURCE_OF_TRUTH.md` (Q10). Review artifact/verdict contract: `docs/contracts/review/REVIEW_RESULT_CONTRACT.md`.

This subsystem owns the snippet↔skill responsibility split (what stays always-loaded vs what becomes an on-demand skill). It does **not** own install / update / uninstall (LTS — `docs/systems/install-update/**`, routes via Q1), Brief (Q4), or Chatlog.

## Current state

- **Two source function-level skills:** `snippets/claude-skills/ai-harness-review/SKILL.md` (review-only; owns the full review lifecycle) and `snippets/claude-skills/ai-harness-brief/SKILL.md` (owns the manual Brief **save / checkpoint / user-requested restore / update** procedure, as of **Batch 2C-2**). Batch 2C-2 moved the procedure out of the snippet (the `## BF save / checkpoint protocol` section was **removed**); the **routing-pointer-removal batch** then dropped the skill-routing pointers entirely — `## Brief` now carries only the BF-lv3 non-claim (pending Batch 3) and `## Review flow` only the review-record hard boundary, with **no** skill-routing pointer in the snippet. Each skill's `description` owns its own discovery.
- **Always-loaded payload responsibility (per the plan):** for current implemented capabilities only — hard boundaries / forbidden rules, adoption discipline, path/topology invariants, role neutrality + reviewer-mode exclusion, the verdict quick reference, and cross-task execution invariants. The snippet carries **no** skill-routing pointers, skill index, or trigger/routing table — skill discovery is owned by each skill's `description`. Review *procedure* is not restated in the payload; it lives in the `ai-harness-review` skill + the review contract, referenced by pointer.
- **Batch 1 landed** (commit `56de8d3`) as the first implementation batch. **Batch 2 is fully landed and closed out** — 2A/2B (unsolicited session-start restore-offer removal + BR-D-02 retirement) + 2C-0 (generic mirror) + 2C-1 (skill skeleton) + 2C-2 (Brief/BF procedure extraction + snippet minimization) + the routing-pointer-removal follow-up (snippet skill-routing pointers dropped) all landed by `a75ffa4`, and the 2D closeout (this STATUS done-flip + SK-02 ledger + `SOURCE_OF_TRUTH.md` Q10 reconciliation) is recorded below. Batches 3–4 (plan §8) are not implemented. The plan approves no batch by itself; each is a separate scoped goal + review gate + explicit user approval.

## Completed ledger

| ID | Item | Closed at | Current meaning | Detail |
|---|---|---|---|---|
| SK-00 | Function-level skill architecture plan | `936969f` | design-stage plan source; approves no batch | `docs/systems/skills/FUNCTION_LEVEL_SKILL_ARCHITECTURE_PLAN.md` |
| SK-01 | Batch 1 — snippet review-procedure de-duplication | `56de8d3` | `snippets/CLAUDE_SNIPPET.md` / `AGENTS_SNIPPET.md` `## Review flow` reduced (Batch 1 left a routing pointer to the `ai-harness-review` skill + the review contract; the later routing-pointer-removal batch removed that pointer, leaving only the review-record hard boundary), and the `## Execution discipline` section **removed entirely** (launch discipline owned by the skill step 5, review-scope-integrity relocated to the skill step 2, temporary-file cleanup generalized to `## Other rules`); the verdict quick reference (`## Result verdict vocabulary`) is retained as the single in-snippet home; no hard boundary / routing invariant dropped (review still fully specified via skill + contract) | plan §8 Batch 1; `docs/contracts/review/REVIEW_RESULT_CONTRACT.md` |
| SK-02 | Batch 2 — restore-offer removal + manual brief-skill extraction + snippet minimization | `a75ffa4` (Batch 2 impl complete); 2D doc-closeout = this row's commit | unsolicited session-start restore-offer **removed** (discarded, not relocated) and the BF-lv3 restore-offer component (BR-D-02) retired; the manual Brief **save / checkpoint / user-requested restore / update** procedure extracted to the `ai-harness-brief` skill; snippet `## BF save / checkpoint protocol` section removed, `## Brief` reduced to the BF-lv3 non-claim, and skill-routing pointers dropped (discovery via each skill's `description`); remaining BF lv3 components stay deferred. **Behavior-change scope:** this 2D closeout round is doc-only, but the Batch 2 *implementation arc* did change install / activation / uninstall + reviewer-guard scripts and tests (notably 2C-0 `832377e` generic activation-surface enumeration, the §8A lifecycle prerequisite; also `52f2e1b`, `68b177f`) — so "no runtime/script change" is scoped to the 2D closeout, not to Batch 2 as a whole. Out of scope (separate user-directed follow-up): post-batch snippet cleanup, incl. the `## Review flow` title/content mismatch | plan §8 Batch 2; commit arc `4b7b58f` (2A/2B) → `a75ffa4` — key landings: `4b7b58f` 2A/2B + BR-D-02 retire, `52f2e1b` reviewer-mode restore guard, `6a4bef5` §8A activation-surface policy, `832377e` 2C-0, `68b177f` 2C-1, `0d40f2d` 2C-2, `a75ffa4` routing-pointer-removal; lifecycle prerequisite `docs/systems/install-update/GLOBAL_INSTALL_UPDATE_MODEL.md` §8A |

## Not yet done

Each is a separate scoped goal + Codex review gate + explicit user approval (plan §8); none is approved by the plan or by this status file.

- **Batch 3** — remove non-current items (Chatlog section, BF Level 3 note) from the snippet.
- **Batch 4** — review-polishing selective-capture vehicle decision (instruction vs skill; non-hook).

## Accepted residual risks

none — the Batch 1 `## Execution discipline` facts were resolved in-batch, not carried as a residual:

- The foreground→background **auto-conversion** reporting rule was **removed** (not relocated).
- The **review-scope-integrity** rule ("do not shrink a review's scope to avoid a long-running run") was **relocated** into `snippets/claude-skills/ai-harness-review/SKILL.md` (step 2, review scope integrity discipline).
- **Temporary-file cleanup** is now a general operator-hygiene rule in the snippet's `## Other rules` (the prior "delete only after separate explicit user approval" meaning was intentionally dropped); it is not review-specific.

The snippet's `## Execution discipline` section was therefore **removed entirely** (the review-run launch discipline is owned by `ai-harness-review` SKILL step 5). Managed-block section structure / H2 count is not a frozen invariant — a function-specific procedure section is removed once its procedure is owned by a function-level skill.
