# Backlog — Index & classification (routing only)

`docs/backlog/` is a **routing/classification index only**. The open-work entrypoints are the per-domain backlog files (`docs/review/review_backlog.md` · `docs/install-update/install-update_backlog.md` · `docs/brief/brief_backlog.md`); the original full backlog bodies are preserved in **git history** (historical provenance only). This folder exists so open candidates are not lost between handoff packets — but it holds no item bodies of its own.

This folder is **not**: implementation / scheduling / release·publish·merge approval. Concrete work needs a separate scoped goal + review.

> **Routing (access-pattern restructure, 2026-05-23; brief·review·install-update domains migrated since).** Open backlog work lives in the per-domain backlog files: review → `docs/review/review_backlog.md`; install-update → `docs/install-update/install-update_backlog.md`; brief → `docs/brief/brief_backlog.md`. Each is a self-contained triage entrypoint. The original mixed bodies were superseded by these triage entrypoints; their full historical text is preserved in git history — not current authority and not the open-work entrypoint. Closed items: migrated domains preserve closed-item detail (ledgers) in git history.

## 탐색 규칙

- open work → per-domain backlog (`docs/review/review_backlog.md` · `docs/install-update/install-update_backlog.md` · `docs/brief/brief_backlog.md`) 를 본다. 이들이 self-contained 진입점이다.
- closed item → 이주된 도메인(brief·review·install-update)은 git history 가 ledger 를 보존.
- 원본 full body / removed-legacy historical reason → git history (historical provenance only; 현행 entrypoint 는 per-domain backlog 의 triage row).
- backlog 항목은 design contract 가 아니다. 충돌 시 각 도메인 spec / `docs/decisions/POST_MVP_PLAN.md` 등 authority 문서가 우선.

## Classification (where each item went)

### Open candidates → per-domain backlog (self-contained)

- review: RV-B-01 (Review 2-pass/profile), RV-B-03 (review result wrapper/fence hygiene), RV-B-04 (no-exec/no-write reviewer contract), RV-B-05 (Review input governance) + 수용된 잔여 위험·idea-only 행 → `docs/review/review_backlog.md` (source-of-truth for the current open candidate set).
- install-update: IU-B-01 (smoke evidence preservation), IU-B-02 (project-local vs global ToolRoot docs debt), IU-B-03 (path normalization hardening), IU-B-04 (install validation report evidence hygiene), IU-B-05 (snapshot auxiliary evidence wording), IU-B-06 (long-lived docs commit-hash hygiene), IU-B-13 (`snippets/rules/` concrete-path audit) + deferred rows (IU-D-*) + idea-only [RETIRED] row → `docs/install-update/install-update_backlog.md`.

### Closed → ledgers preserved in git history

- install-update (구 `STATUS.md` completed/operational ledger — full detail in git history): IU-01..15 lifecycle milestones; IU-OPS-01..05 operational closeouts; lifecycle closeout rows IU-B-08 (uninstall/teardown lifecycle), IU-B-09 (fresh-install entrypoint split + first-time managed-block insertion), IU-B-10 (uninstall package-discovery docs hardening), IU-B-12 (install bootstrap-clone cleanup enforcement); IU-B-07 **[RETIRED]** (one-shot natural-language update completion — retained as an idea-only row in `docs/install-update/install-update_backlog.md`).
- review (closed items — full detail in git history; 당시 ledger = 구 `docs/systems/review/STATUS.md`): RV-B-06 (reviewer runtime provenance in the result artifact — P1 spec `77691c2` / P2 `fdde410` / P3 `fbd295e` / P4 `cfac1ed`); RV-B-07 (U9 config-backed category-effort policy); RV-B-08 (review artifact perspective layout — strict C1 canonical, `460ee3e`).
- brief: Brief location reconciliation — closed (full historical detail in git history; current spec-of-record: `docs/brief/brief_spec.md`).

### Historical / removed-legacy (historical reason only, never operator paths)

- Review-cycle invocation quoting hardening; Review-cycle file-backed request input; Removed legacy review artifacts — full historical bodies in git history.

## Placement rule (where new backlog items go)

- review 도메인의 open work → `docs/review/review_backlog.md`; install-update 도메인의 open work → `docs/install-update/install-update_backlog.md` (self-contained entry).
- 기존 docs (guide / contract) 의 목적과 자연스럽게 맞으면 그 문서 안에 기록.
- `docs/backlog/` 는 routing index 일 뿐 — 새 item 본문을 여기에 두지 않는다.
