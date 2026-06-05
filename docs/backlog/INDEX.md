# Backlog — Index & classification (routing only)

`docs/backlog/` is a **routing/classification index only**. The open-work entrypoints are the per-system backlog files; the original full backlog bodies are preserved in **git history** (historical provenance only). This folder exists so open candidates are not lost between handoff packets — but it holds no item bodies of its own.

This folder is **not**: implementation / scheduling / release·publish·merge approval. Concrete work needs a separate scoped goal + review.

> **Routing (access-pattern restructure, 2026-05-23).** Open backlog work lives in the per-system backlog files: review subsystem → `docs/systems/review/BACKLOG.md`; install/update/operational → `docs/systems/install-update/BACKLOG.md`. Each is a self-contained triage entrypoint. The original mixed bodies were superseded by these per-system triage entrypoints; their full historical text is preserved in git history — not current authority and not the open-work entrypoint. Closed items are authoritative in the per-system `STATUS.md` completed-ledgers.

## 탐색 규칙

- open work → per-system BACKLOG (`docs/systems/review/BACKLOG.md`, `docs/systems/install-update/BACKLOG.md`) 를 본다. 이들이 self-contained 진입점이다.
- closed item → per-system `STATUS.md` completed-ledger 가 authoritative.
- 원본 full body / removed-legacy historical reason → git history (historical provenance only; 현행 entrypoint 는 per-system `BACKLOG.md` triage row).
- backlog 항목은 design contract 가 아니다. 충돌 시 `docs/contracts/**` / `docs/decisions/POST_MVP_PLAN.md` 등 authority 문서가 우선.

## Classification (where each item went)

### Open candidates → per-system BACKLOG (self-contained)

- review: RV-B-01 (Review 2-pass/profile), RV-B-03 (review result wrapper/fence hygiene), RV-B-04 (no-exec/no-write reviewer contract), RV-B-05 (Review input governance) → `docs/systems/review/BACKLOG.md` (source-of-truth for the current open candidate set).
- install-update: IU-B-01 (smoke evidence preservation), IU-B-02 (project-local vs global ToolRoot docs debt), IU-B-03 (path normalization hardening), IU-B-04 (install validation report evidence hygiene), IU-B-05 (snapshot auxiliary evidence wording), IU-B-06 (long-lived docs commit-hash hygiene) → `docs/systems/install-update/BACKLOG.md`.

### Closed → per-system STATUS completed-ledger (full historical detail in git history)

- `docs/systems/install-update/STATUS.md`: PowerShell smoke invocation quoting hardening (IU-OPS-01, `c183c6b`); Aggregate digest reproducibility (IU-11, `1273afe`); Managed block marker detection (IU-OPS-02); Global instruction file path semantics (IU-OPS-03); Channel 3 smoke validation closeout (IU-OPS-04); Activation managed-block apply tooling hardening (IU-OPS-05).
- `docs/systems/install-update/STATUS.md` (lifecycle closeouts; one-line **tombstones** in `docs/systems/install-update/BACKLOG.md`; full historical narrative in git history): IU-B-08 (uninstall/teardown lifecycle); IU-B-09 (fresh-install entrypoint split + first-time managed-block insertion); IU-B-10 (uninstall package-discovery docs hardening); IU-B-12 (install bootstrap-clone cleanup enforcement); IU-B-07 **[RETIRED]** (one-shot natural-language update completion). Lifecycle closeouts IU-14 (subsystem LTS readiness) and IU-15 (main PC lifecycle retest) are ledger rows there.
- `docs/systems/review/STATUS.md` (completed-ledger rows; one-line **tombstones** in `docs/systems/review/BACKLOG.md`; full narrative in git history): RV-B-06 (reviewer runtime provenance in the result artifact — P1 spec `77691c2` / P2 `fdde410` / P3 `fbd295e` / P4 `cfac1ed`); RV-B-07 (U9 config-backed category-effort policy); RV-B-08 (review artifact perspective layout — strict C1 canonical, `460ee3e`).
- `docs/systems/brief/STATUS.md`: Brief / Chatlog location reconciliation.

### Historical / removed-legacy (historical reason only, never operator paths)

- Review-cycle invocation quoting hardening; Review-cycle file-backed request input; Removed legacy review artifacts — full historical bodies in git history.

## Placement rule (where new backlog items go)

- review/install-update system 의 open work → 해당 system 의 `BACKLOG.md` (self-contained entry).
- 기존 docs (guide / contract) 의 목적과 자연스럽게 맞으면 그 문서 안에 기록.
- `docs/backlog/` 는 routing index 일 뿐 — 새 item 본문을 여기에 두지 않는다.
