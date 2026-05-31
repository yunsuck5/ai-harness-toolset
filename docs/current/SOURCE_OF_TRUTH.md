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
> **The docs taxonomy / source-of-truth reset and the access-pattern restructure have been applied.** The Primary/Secondary pointers below point at the final access-pattern locations: artifact/protocol contracts under `docs/contracts/<area>/`, task-scoped policies under `docs/policies/`, project docs under `docs/project/`, active decisions under `docs/decisions/`, the human guide under `docs/user_guide/`, per-system status under `docs/systems/**`, and historical material under `docs/archive/**`. `docs/roadmap/` now holds milestone routing only (`INDEX.md`, `CURRENT_MILESTONES.md`); the operating-layer decision moved to `docs/decisions/GLOBAL_ADOPTION_DECISION.md` and the Step 3 implementation-planning guide to `docs/systems/install-update/STEP3_INSTALL_UPDATE_DECISION_GUIDE.md`.
>
> **Docs are organized by access pattern (supersedes "Policy A").** The earlier "Policy A" — keeping active contracts and policies directly under `docs/` root as a flat cross-system layer — is **superseded** by the placement policy in `docs/README.md`: `docs/` root holds only `README.md`, and each document belongs in the scope folder matching its access pattern (contracts → `docs/contracts/<area>/`, execution policies → `docs/policies/`, project identity → `docs/project/`, active decisions → `docs/decisions/`, human guide → `docs/user_guide/`). The per-system `STATUS.md` documents still **route to** these as the authoritative source rather than replacing them. The docs placement/structure policy authority is `docs/README.md`.

---

## Q1. install / update actual behavior

- **Primary:** `INSTALL.md` — self-contained operative contract (anti-coupling: install behavior does not depend on `docs/`).
- **Secondary:** `docs/systems/install-update/STATUS.md` (current system status + completed-ledger) and `DEFERRED.md`; `docs/systems/install-update/GLOBAL_INSTALL_UPDATE_MODEL.md` (operating model / design), `docs/systems/install-update/STEP3_INSTALL_UPDATE_DECISION_GUIDE.md` (Step 3 implementation planning).
- **Implementation:** `scripts/lib/install-pipeline-core.ps1` (deterministic core library — resolver / materialization / dispatcher / verify; verify helper `Invoke-InstallPipelineVerify` is the canonical operator-side verify entry per `INSTALL.md` §5.1), `scripts/apply-managed-block.ps1`, `scripts/activate-global.ps1`. The fixture / test harness CLI for the install-pipeline core contract lives at `tests/support/install-pipeline-fixture.ps1` (moved from the former `scripts/install-pipeline.ps1` path; fixture-only — `Assert-NotForbiddenInstallArea` guard rejects production global install paths, see `INSTALL.md` §5.1).
- **Historical:** `docs/decisions/GLOBAL_ADOPTION_DECISION.md` (copy / link / pinned-link enumeration), `docs/archive/audits/TOOLROOT_PROJECTROOT_AUDIT.md`.
- **Do not use:** the source-cache / persistent-ToolRoot / `brief/` 1st·2nd-framing remnants inside `docs/systems/install-update/GLOBAL_INSTALL_UPDATE_MODEL.md` (isolated by its top reconciliation note).

## Q2. review workflow

- **Primary:** `docs/user_guide/OPERATOR_GUIDE_KR.md` §7 (natural-language UX), `snippets/claude-skills/ai-harness-review/SKILL.md`.
- **Secondary:** `docs/systems/review/STATUS.md` (current review system status), `docs/policies/REVIEW_EFFORT_GUIDE.md`.
- **Implementation:** `scripts/review-prepare.ps1` → `scripts/review-run.ps1` → `scripts/review-verify.ps1` (input gate: `scripts/review-input-verify.ps1`).
- **Historical:** `docs/archive/backlog/review.md` (removed-legacy), `docs/archive/backlog/operations.md` (quoting hardening historical), `docs/archive/audits/CLEAN_TARGET_SMOKE_CRITERIA.md` SC5/CH3 review-cycle body.
- **Do not use:** `review-cycle.ps1`, `meta.json`, `result.json`, `target-files.list`, `<run-id>` flat layout, `-TargetFilesPath`, `-ReviewRequestPath` (all removed-legacy).

## Q3. review result contract

- **Primary:** `docs/contracts/review/REVIEW_RESULT_CONTRACT.md`.
- **Secondary:** `docs/policies/REVIEWER_CONFIG_POLICY.md`, `docs/systems/review/STATUS.md`.
- **Implementation:** `templates/review-input.md`, `templates/review-result.md`, `scripts/review-verify.ps1`, `config/reviewer.json`.
- **Historical:** removed-legacy identifiers in `docs/archive/backlog/review.md` / `docs/archive/backlog/operations.md`.
- **Do not use:** sidecar JSON / hash-binding files / external staging folders (outside the canonical contract).

## Q4. Brief primitive

- **Primary:** `docs/contracts/brief/BRIEF_CONTRACT.md` (3rd reconciliation; canonical Brief = `<ProjectRoot>/log/brief/BRIEF.md`).
- **Secondary:** `docs/systems/brief/STATUS.md` + `DEFERRED.md` (current status + BF Level 3 deferred), `docs/contracts/chatlog/CHATLOG_CONTRACT.md` (Brief↔Chatlog boundary), `docs/user_guide/OPERATOR_GUIDE_KR.md` §7b.
- **Implementation:** `scripts/brief-init.ps1`, `scripts/brief-check.ps1`, `scripts/brief-status.ps1`, `templates/brief/BRIEF.md`.
- **Historical:** `docs/contracts/brief/BRIEF_CONTRACT.md` Historical lineage (1st·2nd), and the superseded brief wording inside `docs/systems/install-update/GLOBAL_INSTALL_UPDATE_MODEL.md` / `docs/contracts/global-invocation/SHARED_GLOBAL_INVOCATION_CONTRACT.md` / `docs/archive/audits/TOOLROOT_PROJECTROOT_AUDIT.md` / `docs/decisions/GLOBAL_ADOPTION_DECISION.md`.
- **Do not use:** root `<ProjectRoot>/brief/` (rejected), any user-home operator-local runtime root (rejected), `log/chatlog/current/resume.md` / `summary.md` as a restore source (deprecation candidate).

## Q5. current milestone / next action

- **Primary:** `docs/current/NEXT_ACTIONS.md` (active queue), then `docs/current/PROJECT_STATE.md` (top-level current summary).
- **Secondary:** `docs/roadmap/CURRENT_MILESTONES.md` (steps 1–6 routed with status), `docs/systems/install-update/STATUS.md` / `DEFERRED.md`; `docs/decisions/POST_MVP_PLAN.md` §11 (authority for the numbered order) + §10 (status summary).
- **Implementation:** n/a (milestone / plan documents have no code implementation).
- **Historical:** `docs/decisions/POST_MVP_PLAN.md` §10 Completed closeout narrative.
- **Do not use:** reading `docs/decisions/POST_MVP_PLAN.md` completed items as active instructions, or its deferred items as open backlog.

## Q6. historical MVP decisions

- **Primary:** `docs/decisions/DECISIONS.md` "MVP closeout" block + `docs/decisions/POST_MVP_PLAN.md` §1.
- **Secondary:** `docs/project/AI_HARNESS_TOOLSET_SCOPE.md` (MVP scope source-of-truth).
- **Implementation:** n/a (historical decision records; the MVP-era implementation is absorbed into current `scripts/**`, so no separate historical implementation pointer is needed).
- **Historical:** `docs/archive/legacy-mvp/LEGACY_KNOWLEDGE_TRANSFER.md`, `docs/archive/legacy-mvp/MIGRATION_INVENTORY_SUMMARY.md`, `docs/archive/legacy-mvp/BOOTSTRAP_DECISIONS.md` (bootstrap/historical decisions extracted from `docs/decisions/DECISIONS.md`).
- **Do not use:** archive material as current implementation / operation / install / review guidance.

## Q7. self-adoption / Step 5

- **Primary:** `docs/systems/install-update/GLOBAL_INSTALL_UPDATE_MODEL.md` §9 (self-adoption model), `docs/decisions/POST_MVP_PLAN.md` §11 step 5.
- **Secondary:** `docs/systems/install-update/STATUS.md` "Self-adoption (Step 5) — performed" (sub-topic status; ledger IU-13), `docs/user_guide/OPERATOR_GUIDE_KR.md` §17 (post-MVP CLI-only operating notes).
- **Implementation:** **performed** at resolved HEAD `8293878d20465aba1132c1bca189fa4a53bc0d43` (apply 2026-05-25). Performed via `INSTALL.md` §2A AI-guided operational install — no productized installer / wrapper was adopted. Activation surfaces (Claude / Codex managed blocks + Claude `ai-harness-review` skill) were already in canonical steady-state at apply time and recorded as no-op. Closeout ledger: `docs/systems/install-update/STATUS.md` IU-13.
- **Historical:** the 1st·2nd framing in `docs/systems/install-update/GLOBAL_INSTALL_UPDATE_MODEL.md` §9 BRIEF wording note; the previous "not implemented" status that pre-dates the 2026-05-25 closeout.
- **Do not use:** the previous "not implemented" framing — self-adoption was performed as of 2026-05-25 (`docs/systems/install-update/STATUS.md` IU-13). Also do not read this closeout as auto-approval of commit / push / publish / release or of any further global mutation; each remains a separate explicit user-approved decision.

## Q8. backlog / deferred / completed items

- **Primary (open work):** `docs/systems/review/BACKLOG.md`, `docs/systems/install-update/BACKLOG.md` (consolidated open candidates), with `docs/backlog/INDEX.md` as the classification index. The full item text lives in `docs/archive/backlog/operations.md` / `docs/archive/backlog/review.md` (route-in-place; those files also retain closed/historical items, marked).
- **Secondary:** for **completed** items the per-system completed-ledgers in `docs/systems/*/STATUS.md`; for **deferred** items (with reopen conditions) `docs/systems/install-update/DEFERRED.md` / `docs/systems/brief/DEFERRED.md`; `docs/decisions/POST_MVP_PLAN.md` §10 (status summary).
- **Implementation:** n/a (backlog / deferred are records of not-yet-started work; the implementation basis for closed items is the commit pointers in `docs/decisions/POST_MVP_PLAN.md` §10 Completed plus current `scripts/**` / `tests/**`).
- **Historical:** removed-legacy / closeout items inside the two backlog files.
- **Do not use:** reading closeout / completed items in the backlog folder as open work.

## Q9. how a docs change / closeout flows through the docs tree

For "how should a docs change or a feature/system closeout propagate top-down through the docs tree, and what is the closeout reconciliation gate?"

- **Primary:** `docs/policies/DOCS_OPERATING_MODEL.md` (docs change/closeout flow; per-system `STATUS.md` shape/altitude contract; `BACKLOG.md` closed-row tombstone rule; `NEXT_ACTIONS.md` selected-action-only rule; two-level closeout reconciliation gate).
- **Secondary:** `docs/README.md` (folder placement / structure authority); this file (per-question authority routing).
- **Implementation:** n/a (an operating-model / process document; no code implementation).
- **Historical:** n/a.
- **Do not use:** `docs/policies/DOCS_OPERATING_MODEL.md` as a placement authority (placement → `docs/README.md`) or as commit / push approval (a review verdict approves neither).
