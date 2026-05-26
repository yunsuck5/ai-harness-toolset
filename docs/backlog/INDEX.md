# Backlog — Index & classification (routing only)

`docs/backlog/` is a **routing/classification index only**. The open-work entrypoints are the per-system backlog files; the original full backlog bodies are historical provenance under `docs/archive/backlog/`. This folder exists so open candidates are not lost between handoff packets — but it holds no item bodies of its own.

This folder is **not**: implementation / scheduling / release·publish·merge approval. Concrete work needs a separate scoped goal + review.

> **Routing (access-pattern restructure, 2026-05-23).** Open backlog work lives in the per-system backlog files: review subsystem → `docs/systems/review/BACKLOG.md`; install/update/operational → `docs/systems/install-update/BACKLOG.md`. Each is a self-contained triage entrypoint. The original mixed bodies (`operations.md`, `review.md`) were **moved to `docs/archive/backlog/`** as historical provenance — they are not current authority and not the open-work entrypoint. Closed items are authoritative in the per-system `STATUS.md` completed-ledgers.

## 탐색 규칙

- open work → per-system BACKLOG (`docs/systems/review/BACKLOG.md`, `docs/systems/install-update/BACKLOG.md`) 를 본다. 이들이 self-contained 진입점이다.
- closed item → per-system `STATUS.md` completed-ledger 가 authoritative.
- 원본 full body / removed-legacy historical reason → `docs/archive/backlog/operations.md`, `docs/archive/backlog/review.md` (historical provenance only).
- backlog 항목은 design contract 가 아니다. 충돌 시 `docs/contracts/**` / `docs/decisions/POST_MVP_PLAN.md` 등 authority 문서가 우선.

## Classification (where each item went)

### Open candidates → per-system BACKLOG (self-contained)

- review: RV-B-01 (Review 2-pass/profile), RV-B-02 (`timeoutSeconds` enforcement debt), RV-B-03 (review result wrapper/fence hygiene), RV-B-04 (no-exec/no-write reviewer contract), RV-B-05 (Review input governance) → `docs/systems/review/BACKLOG.md` (source-of-truth for the current open candidate set).
- install-update: IU-B-01 (smoke evidence preservation), IU-B-02 (project-local vs global ToolRoot docs debt), IU-B-03 (path normalization hardening), IU-B-04 (install validation report evidence hygiene), IU-B-05 (snapshot auxiliary evidence wording), IU-B-06 (long-lived docs commit-hash hygiene) → `docs/systems/install-update/BACKLOG.md`.

### Closed → per-system STATUS completed-ledger (full detail in `docs/archive/backlog/`)

- `docs/systems/install-update/STATUS.md`: PowerShell smoke invocation quoting hardening (IU-OPS-01, `c183c6b`); Aggregate digest reproducibility (IU-11, `1273afe`); Managed block marker detection (IU-OPS-02); Global instruction file path semantics (IU-OPS-03); Channel 3 smoke validation closeout (IU-OPS-04); Activation managed-block apply tooling hardening (IU-OPS-05).
- `docs/systems/brief/STATUS.md`: Brief / Chatlog location reconciliation.

### Historical / removed-legacy (historical reason only, never operator paths)

- Review-cycle invocation quoting hardening; Review-cycle file-backed request input; Removed legacy review artifacts — full bodies in `docs/archive/backlog/review.md` / `docs/archive/backlog/operations.md`.

## Placement rule (where new backlog items go)

- review/install-update system 의 open work → 해당 system 의 `BACKLOG.md` (self-contained entry).
- 기존 docs (guide / contract) 의 목적과 자연스럽게 맞으면 그 문서 안에 기록.
- `docs/backlog/` 는 routing index 일 뿐 — 새 item 본문을 여기에 두지 않는다.
