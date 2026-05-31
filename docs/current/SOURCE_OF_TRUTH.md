# Source of Truth

This file routes a question to the document you read **first**, and gives the priority order when documents disagree. It is a current routing entrypoint, not a contract: it does not redefine any contract, and it never grants commit / push / release approval.

How to read each entry:

- **Primary** — read this first; it is authoritative for the question.
- **Secondary** — supporting current context.
- **Implementation** — the code / template / config that enforces or realizes the contract.
- **Historical** — where the past framing lives; useful only for historical context.
- **Do not use** — framing or identifiers that look current but are superseded / removed-legacy; do not treat as current guidance.

> **Historical preservation.** Superseded / historical material is preserved in **git history**, not maintained as current docs (there is no separate archive docs tree). Current source-of-truth lives in the active docs — routed per question by this file (`docs/current/SOURCE_OF_TRUTH.md`); per-system current status lives in `docs/systems/<system>/STATUS.md`.
>
> **The docs taxonomy / source-of-truth reset and the access-pattern restructure have been applied.** The Primary/Secondary pointers below point at the final access-pattern locations: artifact/protocol contracts under `docs/contracts/<area>/`, task-scoped policies under `docs/policies/`, project docs under `docs/project/`, active decisions under `docs/decisions/`, the human guide under `docs/user_guide/`, and per-system status under `docs/systems/**`. `docs/roadmap/` now holds milestone routing only (`INDEX.md`, `CURRENT_MILESTONES.md`); the operating-layer decision moved to `docs/decisions/GLOBAL_ADOPTION_DECISION.md` and the Step 3 implementation-planning guide to `docs/systems/install-update/STEP3_INSTALL_UPDATE_DECISION_GUIDE.md`.
>
> **Docs are organized by access pattern (supersedes "Policy A").** The earlier "Policy A" — keeping active contracts and policies directly under `docs/` root as a flat cross-system layer — is **superseded** by the placement policy in `docs/README.md`: `docs/` root holds only `README.md`, and each document belongs in the scope folder matching its access pattern (contracts → `docs/contracts/<area>/`, execution policies → `docs/policies/`, project identity → `docs/project/`, active decisions → `docs/decisions/`, human guide → `docs/user_guide/`). The per-system `STATUS.md` documents still **route to** these as the authoritative source rather than replacing them. The docs placement/structure policy authority is `docs/README.md`.

---

## Q1. install / update actual behavior

- **Primary:** `INSTALL.md` — self-contained operative contract (anti-coupling: install behavior does not depend on `docs/`).
- **Secondary:** `docs/systems/install-update/STATUS.md` (current system status + completed-ledger) and `DEFERRED.md`; `docs/systems/install-update/GLOBAL_INSTALL_UPDATE_MODEL.md` (operating model / design), `docs/systems/install-update/STEP3_INSTALL_UPDATE_DECISION_GUIDE.md` (Step 3 implementation planning).
- **Implementation:** `scripts/lib/install-pipeline-core.ps1` (deterministic core library — resolver / materialization / dispatcher / verify; verify helper `Invoke-InstallPipelineVerify` is the canonical operator-side verify entry per `INSTALL.md` §5.1), `scripts/apply-managed-block.ps1`, `scripts/activate-global.ps1`. The fixture / test harness CLI for the install-pipeline core contract lives at `tests/support/install-pipeline-fixture.ps1` (moved from the former `scripts/install-pipeline.ps1` path; fixture-only — `Assert-NotForbiddenInstallArea` guard rejects production global install paths, see `INSTALL.md` §5.1).
- **Historical:** `docs/decisions/GLOBAL_ADOPTION_DECISION.md` (copy / link / pinned-link enumeration); earlier ToolRoot/ProjectRoot path-handling audit detail is preserved in git history.
- **Do not use:** the source-cache / persistent-ToolRoot / `brief/` 1st·2nd-framing remnants inside `docs/systems/install-update/GLOBAL_INSTALL_UPDATE_MODEL.md` (isolated by its top reconciliation note).

## Q2. review workflow

- **Primary:** `docs/user_guide/OPERATOR_GUIDE_KR.md` §7 (natural-language UX), `snippets/claude-skills/ai-harness-review/SKILL.md`.
- **Secondary:** `docs/systems/review/STATUS.md` (current review system status), `docs/policies/REVIEW_EFFORT_GUIDE.md`.
- **Implementation:** `scripts/review-prepare.ps1` → `scripts/review-run.ps1` → `scripts/review-verify.ps1` (input gate: `scripts/review-input-verify.ps1`).
- **Historical:** removed-legacy review-cycle / quoting-hardening / clean-target smoke-criteria detail is preserved in git history.
- **Do not use:** `review-cycle.ps1`, `meta.json`, `result.json`, `target-files.list`, `<run-id>` flat layout, `-TargetFilesPath`, `-ReviewRequestPath` (all removed-legacy).

## Q3. review result contract

- **Primary:** `docs/contracts/review/REVIEW_RESULT_CONTRACT.md`.
- **Secondary:** `docs/policies/REVIEWER_CONFIG_POLICY.md`, `docs/systems/review/STATUS.md`.
- **Implementation:** `templates/review-input.md`, `templates/review-result.md`, `scripts/review-verify.ps1`, `config/reviewer.json`.
- **Historical:** removed-legacy identifiers are preserved in git history.
- **Do not use:** sidecar JSON / hash-binding files / external staging folders (outside the canonical contract).

## Q4. Brief primitive

- **Primary:** `docs/contracts/brief/BRIEF_CONTRACT.md` (3rd reconciliation; canonical Brief = `<ProjectRoot>/log/brief/BRIEF.md`).
- **Secondary:** `docs/systems/brief/STATUS.md` + `DEFERRED.md` (current status + BF Level 3 deferred), `docs/contracts/chatlog/CHATLOG_CONTRACT.md` (Brief↔Chatlog boundary), `docs/user_guide/OPERATOR_GUIDE_KR.md` §7b.
- **Implementation:** `scripts/brief-init.ps1`, `scripts/brief-check.ps1`, `scripts/brief-status.ps1`, `templates/brief/BRIEF.md`.
- **Historical:** `docs/contracts/brief/BRIEF_CONTRACT.md` Historical lineage (1st·2nd), and the superseded brief wording inside `docs/systems/install-update/GLOBAL_INSTALL_UPDATE_MODEL.md` / `docs/contracts/global-invocation/SHARED_GLOBAL_INVOCATION_CONTRACT.md` / `docs/decisions/GLOBAL_ADOPTION_DECISION.md`.
- **Do not use:** root `<ProjectRoot>/brief/` (rejected), any user-home operator-local runtime root (rejected), `log/chatlog/current/resume.md` / `summary.md` as a restore source (deprecation candidate).

## Q5. current progress / remaining work / next action

Answered **on demand**, not from a committed project-current mirror (see `docs/policies/DOCS_OPERATING_MODEL.md` §6, the on-demand status-briefing model). The agent inspects the authoritative surfaces below and reports; the user selects the next task conversationally.

- **Primary:** the per-system surfaces — `docs/systems/*/STATUS.md` completed-ledgers + current-state/LTS sections (what is done), `docs/systems/*/BACKLOG.md` (open work, via `docs/backlog/INDEX.md`), `docs/systems/*/DEFERRED.md` (postponed + reopen conditions) — together with `docs/roadmap/CURRENT_MILESTONES.md` ↔ `docs/decisions/POST_MVP_PLAN.md` §11 (numbered remaining order). The briefing model itself is `docs/policies/DOCS_OPERATING_MODEL.md` §6.
- **Secondary:** the canonical Brief `<ProjectRoot>/log/brief/BRIEF.md` — **runtime restore evidence only when present** (the currently selected action / session-transition anchor); not a committed source-of-truth and not always present.
- **Implementation:** n/a (milestone / plan documents have no code implementation).
- **Historical:** `docs/decisions/POST_MVP_PLAN.md` §10 (completed closeout summary; full per-commit narrative preserved in git history).
- **Do not use:** a committed active-queue or project-current summary file — there is none. The former `docs/current/NEXT_ACTIONS.md` and `docs/current/PROJECT_STATE.md` project-current mirrors have been **removed**; do not look for or recreate them. Use the on-demand status-briefing model instead (`docs/policies/DOCS_OPERATING_MODEL.md` §6). Also do not read `docs/decisions/POST_MVP_PLAN.md` completed items as active instructions, or its deferred items as open backlog.

## Q6. historical MVP decisions

- **Primary:** `docs/decisions/DECISIONS.md` "MVP closeout" block + `docs/decisions/POST_MVP_PLAN.md` §1.
- **Secondary:** `docs/project/AI_HARNESS_TOOLSET_SCOPE.md` (MVP scope source-of-truth).
- **Implementation:** n/a (historical decision records; the MVP-era implementation is absorbed into current `scripts/**`, so no separate historical implementation pointer is needed).
- **Historical:** bootstrap / legacy-MVP migration decisions (knowledge transfer, migration inventory, bootstrap decisions, extracted out of `docs/decisions/DECISIONS.md`) are preserved in git history.
- **Do not use:** superseded / historical material (preserved in git history) as current implementation / operation / install / review guidance.

## Q7. self-adoption / Step 5

- **Primary:** `docs/systems/install-update/GLOBAL_INSTALL_UPDATE_MODEL.md` §9 (self-adoption model), `docs/decisions/POST_MVP_PLAN.md` §11 step 5.
- **Secondary:** `docs/systems/install-update/STATUS.md` completed-ledger IU-13 (self-adoption sub-topic; full narrative preserved in git history), `docs/user_guide/OPERATOR_GUIDE_KR.md` §17 (post-MVP CLI-only operating notes).
- **Implementation:** **performed** at resolved HEAD `8293878d20465aba1132c1bca189fa4a53bc0d43` (apply 2026-05-25). Performed via `INSTALL.md` §2A AI-guided operational install — no productized installer / wrapper was adopted. Activation surfaces (Claude / Codex managed blocks + Claude `ai-harness-review` skill) were already in canonical steady-state at apply time and recorded as no-op. Closeout ledger: `docs/systems/install-update/STATUS.md` IU-13.
- **Historical:** the 1st·2nd framing in `docs/systems/install-update/GLOBAL_INSTALL_UPDATE_MODEL.md` §9 BRIEF wording note; the previous "not implemented" status that pre-dates the 2026-05-25 closeout.
- **Do not use:** the previous "not implemented" framing — self-adoption was performed as of 2026-05-25 (`docs/systems/install-update/STATUS.md` IU-13). Also do not read this closeout as auto-approval of commit / push / publish / release or of any further global mutation; each remains a separate explicit user-approved decision.

## Q8. backlog / deferred / completed items

- **Primary (open work):** `docs/systems/review/BACKLOG.md`, `docs/systems/install-update/BACKLOG.md` (consolidated open candidates), with `docs/backlog/INDEX.md` as the classification index. The full historical item text is preserved in git history (the per-system `BACKLOG.md` triage rows are the current entrypoint).
- **Secondary:** for **completed** items the per-system completed-ledgers in `docs/systems/*/STATUS.md`; for **deferred** items (with reopen conditions) `docs/systems/install-update/DEFERRED.md` / `docs/systems/brief/DEFERRED.md`; `docs/decisions/POST_MVP_PLAN.md` §10 (status summary).
- **Implementation:** n/a (backlog / deferred are records of not-yet-started work; the implementation basis for closed items is the commit pointers in `docs/decisions/POST_MVP_PLAN.md` §10 Completed plus current `scripts/**` / `tests/**`).
- **Historical:** removed-legacy / closeout items inside the two backlog files.
- **Do not use:** reading closeout / completed items in the backlog folder as open work.

## Q9. how a docs change / closeout flows through the docs tree

For "how should a docs change or a feature/system closeout propagate top-down through the docs tree, and what is the closeout reconciliation gate?"

- **Primary:** `docs/policies/DOCS_OPERATING_MODEL.md` (docs change/closeout flow; per-system `STATUS.md` shape/altitude contract; `BACKLOG.md` closed-row tombstone rule; the on-demand status-briefing model that replaces committed project-current mirrors; two-level closeout reconciliation gate).
- **Secondary:** `docs/README.md` (folder placement / structure authority); this file (per-question authority routing).
- **Implementation:** n/a (an operating-model / process document; no code implementation).
- **Historical:** n/a.
- **Do not use:** `docs/policies/DOCS_OPERATING_MODEL.md` as a placement authority (placement → `docs/README.md`) or as commit / push approval (a review verdict approves neither).
