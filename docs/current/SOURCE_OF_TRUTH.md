# Source of Truth

This file routes a question to the document you read **first**, and gives the priority order when documents disagree. It is a current routing entrypoint, not a contract: it does not redefine any contract, and it never grants commit / push / release approval.

How to read each entry:

- **Primary** — read this first; it is authoritative for the question.
- **Secondary** — supporting current context.
- **Implementation** — the code / template / config that enforces or realizes the contract.
- **Historical** — where the past framing lives; useful only for historical context.
- **Do not use** — framing or identifiers that look current but are superseded / removed-legacy; do not treat as current guidance.

> **Archive authority.** Material under `docs/archive/` is historical or superseded. Do not use it as current implementation, operation, install, or review guidance unless a task explicitly asks for historical context. Current source-of-truth lives under `docs/current/` and the per-system status documents (`docs/systems/<system>/STATUS.md`).
>
> **The docs taxonomy / source-of-truth reset has been applied.** The Primary/Secondary pointers below already point at the routed locations under `docs/systems/**` and `docs/archive/**`. The question→authority mapping itself is stable; update a pointer here only if a future change relocates one of the routed documents.
>
> **Root `docs/*.md` contract-layer policy (Policy A).** The active contracts and policies that live directly under `docs/` — `BRIEF_CONTRACT.md`, `REVIEW_RESULT_CONTRACT.md`, `CHATLOG_CONTRACT.md`, `EVIDENCE_CONTRACT.md`, `REVIEWER_CONFIG_POLICY.md`, `CLI_ENVIRONMENT_ASSUMPTIONS.md`, `POWERSHELL_POLICY.md`, `AI_HARNESS_TOOLSET_SCOPE.md`, `TOOLING_POSITION.md`, `OPERATOR_GUIDE_KR.md`, `DECISIONS.md` — are intentionally kept at the `docs/` root as a **stable cross-system contract layer**, not relocated into `docs/systems/<system>/` or a `docs/contracts/` folder. They are cross-cutting, heavily inbound-referenced (README, `snippets/**`, `scripts/**` comments, and other docs), and the per-system `STATUS.md` documents **route to** them as the authoritative source rather than replacing them. This is the committed policy for the current structure; relocating any of them is a separate scoped decision that would also require updating those inbound references.

---

## Q1. install / update actual behavior

- **Primary:** `INSTALL.md` — self-contained operative contract (anti-coupling: install behavior does not depend on `docs/`).
- **Secondary:** `docs/systems/install-update/STATUS.md` (current system status + completed-ledger) and `DEFERRED.md`; `docs/roadmap/GLOBAL_INSTALL_UPDATE_MODEL.md` (operating model / design), `docs/roadmap/global-install-update/STEP3_INSTALL_UPDATE_DECISION_GUIDE.md` (Step 3 implementation planning).
- **Implementation:** `scripts/install-pipeline.ps1`, `scripts/lib/install-pipeline-core.ps1`, `scripts/apply-managed-block.ps1`, `scripts/activate-global.ps1`.
- **Historical:** `docs/roadmap/GLOBAL_ADOPTION_DECISION.md` (copy / link / pinned-link enumeration), `docs/roadmap/TOOLROOT_PROJECTROOT_AUDIT.md`.
- **Do not use:** the source-cache / persistent-ToolRoot / `brief/` 1st·2nd-framing remnants inside `GLOBAL_INSTALL_UPDATE_MODEL.md` (isolated by its top reconciliation note).

## Q2. review workflow

- **Primary:** `docs/OPERATOR_GUIDE_KR.md` §7 (natural-language UX), `snippets/claude-skills/ai-harness-review/SKILL.md`.
- **Secondary:** `docs/systems/review/STATUS.md` (current review system status), `docs/roadmap/REVIEW_EFFORT_GUIDE.md`.
- **Implementation:** `scripts/review-prepare.ps1` → `scripts/review-run.ps1` → `scripts/review-verify.ps1` (input gate: `scripts/review-input-verify.ps1`).
- **Historical:** `docs/backlog/review.md` (removed-legacy), `docs/backlog/operations.md` (quoting hardening historical), `docs/roadmap/CLEAN_TARGET_SMOKE_CRITERIA.md` SC5/CH3 review-cycle body.
- **Do not use:** `review-cycle.ps1`, `meta.json`, `result.json`, `target-files.list`, `<run-id>` flat layout, `-TargetFilesPath`, `-ReviewRequestPath` (all removed-legacy).

## Q3. review result contract

- **Primary:** `docs/REVIEW_RESULT_CONTRACT.md`.
- **Secondary:** `docs/REVIEWER_CONFIG_POLICY.md`, `docs/systems/review/STATUS.md`.
- **Implementation:** `templates/review-input.md`, `templates/review-result.md`, `scripts/review-verify.ps1`, `config/reviewer.json`.
- **Historical:** removed-legacy identifiers in `docs/backlog/review.md` / `docs/backlog/operations.md`.
- **Do not use:** sidecar JSON / hash-binding files / external staging folders (outside the canonical contract).

## Q4. Brief primitive

- **Primary:** `docs/BRIEF_CONTRACT.md` (3rd reconciliation; canonical Brief = `<ProjectRoot>/log/brief/BRIEF.md`).
- **Secondary:** `docs/systems/brief/STATUS.md` + `DEFERRED.md` (current status + BF Level 3 deferred), `docs/CHATLOG_CONTRACT.md` (Brief↔Chatlog boundary), `docs/OPERATOR_GUIDE_KR.md` §7b.
- **Implementation:** `scripts/brief-init.ps1`, `scripts/brief-check.ps1`, `scripts/brief-status.ps1`, `templates/brief/BRIEF.md`.
- **Historical:** `BRIEF_CONTRACT.md` Historical lineage (1st·2nd), and the superseded brief wording inside `GLOBAL_INSTALL_UPDATE_MODEL.md` / `SHARED_GLOBAL_INVOCATION_CONTRACT.md` / `TOOLROOT_PROJECTROOT_AUDIT.md` / `GLOBAL_ADOPTION_DECISION.md`.
- **Do not use:** root `<ProjectRoot>/brief/` (rejected), any user-home operator-local runtime root (rejected), `log/chatlog/current/resume.md` / `summary.md` as a restore source (deprecation candidate).

## Q5. current milestone / next action

- **Primary:** `docs/current/NEXT_ACTIONS.md` (active queue), then `docs/current/PROJECT_STATE.md` (top-level current summary).
- **Secondary:** `docs/roadmap/CURRENT_MILESTONES.md` (steps 1–7 routed with status), `docs/systems/install-update/STATUS.md` / `DEFERRED.md`; `docs/roadmap/POST_MVP_PLAN.md` §11 (authority for the numbered order) + §10 (status summary).
- **Implementation:** n/a (milestone / plan documents have no code implementation).
- **Historical:** `POST_MVP_PLAN.md` §10 Completed closeout narrative.
- **Do not use:** reading `POST_MVP_PLAN.md` completed items as active instructions, or its deferred items as open backlog.

## Q6. historical MVP decisions

- **Primary:** `docs/DECISIONS.md` "MVP closeout" block + `docs/roadmap/POST_MVP_PLAN.md` §1.
- **Secondary:** `docs/AI_HARNESS_TOOLSET_SCOPE.md` (MVP scope source-of-truth).
- **Implementation:** n/a (historical decision records; the MVP-era implementation is absorbed into current `scripts/**`, so no separate historical implementation pointer is needed).
- **Historical:** `docs/archive/legacy-mvp/LEGACY_KNOWLEDGE_TRANSFER.md`, `docs/archive/legacy-mvp/MIGRATION_INVENTORY_SUMMARY.md`, `docs/archive/legacy-mvp/BOOTSTRAP_DECISIONS.md` (bootstrap/historical decisions extracted from `docs/DECISIONS.md`).
- **Do not use:** archive material as current implementation / operation / install / review guidance.

## Q7. self-adoption / Step 5

- **Primary:** `docs/roadmap/GLOBAL_INSTALL_UPDATE_MODEL.md` §9 (self-adoption model), `docs/roadmap/POST_MVP_PLAN.md` §11 step 5.
- **Secondary:** `docs/systems/install-update/STATUS.md` "Self-adoption" (sub-topic status: not implemented), `docs/OPERATOR_GUIDE_KR.md` §17 (GJMNet / self-adoption operating notes).
- **Implementation:** **not implemented.** install / update validation (Step 4) is closed; Step 5 self-adoption is not performed (`POST_MVP_PLAN.md` §10 Deferred). There is no current implementation basis.
- **Historical:** the 1st·2nd framing in `GLOBAL_INSTALL_UPDATE_MODEL.md` §9 BRIEF wording note.
- **Do not use:** any reading that self-adoption has actually been performed (`POST_MVP_PLAN.md` states it has not).

## Q8. backlog / deferred / completed items

- **Primary (open work):** `docs/systems/review/BACKLOG.md`, `docs/systems/install-update/BACKLOG.md` (consolidated open candidates), with `docs/backlog/INDEX.md` as the classification index. The full item text lives in `docs/backlog/operations.md` / `docs/backlog/review.md` (route-in-place; those files also retain closed/historical items, marked).
- **Secondary:** for **completed** items the per-system completed-ledgers in `docs/systems/*/STATUS.md`; for **deferred** items (with reopen conditions) `docs/systems/install-update/DEFERRED.md` / `docs/systems/brief/DEFERRED.md`; `docs/roadmap/POST_MVP_PLAN.md` §10 (status summary).
- **Implementation:** n/a (backlog / deferred are records of not-yet-started work; the implementation basis for closed items is the commit pointers in `POST_MVP_PLAN.md` §10 Completed plus current `scripts/**` / `tests/**`).
- **Historical:** removed-legacy / closeout items inside the two backlog files.
- **Do not use:** reading closeout / completed items in the backlog folder as open work.
