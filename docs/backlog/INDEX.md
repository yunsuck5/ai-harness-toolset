# Backlog — Index & classification

본 폴더는 `ai-harness-toolset` 의 **repo-visible backlog index** 다 (이전 `docs/backlog/README.md` 를 흡수). handoff-only backlog 가 packet 사이에서 유실되는 risk 를 막기 위해, open 상태의 후보 항목을 repo 안에 명시적으로 남기는 자리다.

본 폴더는 다음이 **아니다**: implementation 승인 / scheduling 승인 / release·publish·merge 승인. 구체적 구현은 본 폴더의 항목만으로 진행되지 않는다 — 별도 scoped goal 과 review 가 필요하다.

> **현행 routing (docs taxonomy reset).** open backlog 항목은 docs taxonomy reset 이후 per-system BACKLOG 로 consolidate 되었다 — review subsystem 은 `docs/systems/review/BACKLOG.md`, install/update/operational 은 `docs/systems/install-update/BACKLOG.md` 가 현행 open-work 진입점이다. 본 INDEX 는 그 분류와 함께, `operations.md` / `review.md` 안의 **closed / historical / removed-legacy** 항목이 open work 로 오독되지 않도록 status 를 명시한다. `operations.md` 와 `review.md` 는 (다수 contract/README inbound reference 때문에) 제자리에 유지되며, 본 reset 은 그 안의 closed/historical 항목 본문을 **route-in-place** (banner + 본 INDEX 분류) 로 다룬다 (물리적 archive 이동은 별도 batch 판단 — contract relocation 과 동일 원칙).

## 탐색 규칙

- open work 는 system BACKLOG (`docs/systems/review/BACKLOG.md`, `docs/systems/install-update/BACKLOG.md`) 를 먼저 본다. 그다음 본 INDEX 의 분류 표, 그리고 `operations.md` / `review.md` 의 항목 본문.
- 오래된 handoff packet 의 backlog 표현과 repo backlog 가 충돌하면 **repo backlog 가 우선**.
- backlog 항목은 design contract 가 아니다. 충돌 시 `docs/` 의 contract 문서 (`docs/REVIEW_RESULT_CONTRACT.md`, `docs/BRIEF_CONTRACT.md`, `docs/CHATLOG_CONTRACT.md`, `docs/AI_HARNESS_TOOLSET_SCOPE.md`, `docs/roadmap/SHARED_GLOBAL_INVOCATION_CONTRACT.md`, `docs/roadmap/POST_MVP_PLAN.md`) 가 우선.

## Classification — `operations.md` / `review.md` 항목 status

open candidate 만 system BACKLOG 에 carry 한다. closed 는 system STATUS completed-ledger 가 authoritative 이고, removed-legacy 는 historical reason 으로만 보존된다.

### Open candidates (→ system BACKLOG)

- `review.md` "Review 2-pass / profile for user-facing instruction text" → `systems/review/BACKLOG.md` RV-B-01.
- `operations.md` "`timeoutSeconds` enforcement decision debt" → `systems/review/BACKLOG.md` RV-B-02.
- `operations.md` "Review result wrapper / fence artifact hygiene" → `systems/review/BACKLOG.md` RV-B-03.
- `operations.md` "Review subsystem no-exec / no-write reviewer contract" → `systems/review/BACKLOG.md` RV-B-04.
- `operations.md` "Smoke evidence preservation" → `systems/install-update/BACKLOG.md` IU-B-01.
- `operations.md` "Project-local copy model docs vs global stable runtime ToolRoot model" → `systems/install-update/BACKLOG.md` IU-B-02.
- `operations.md` "Path normalization edge-case hardening" → `systems/install-update/BACKLOG.md` IU-B-03 (cross-cutting).
- `operations.md` "Install validation report evidence hygiene" → `systems/install-update/BACKLOG.md` IU-B-04.
- `operations.md` "Snapshot auxiliary evidence exactness wording" → `systems/install-update/BACKLOG.md` IU-B-05.
- `operations.md` "Long-lived docs commit hash hygiene" → `systems/install-update/BACKLOG.md` IU-B-06 (cross-cutting).

### Closed (→ system STATUS completed-ledger; detail stays in-place as historical record)

- `operations.md` "PowerShell smoke invocation quoting hardening" — closed ((W) wrapper, `c183c6b`).
- `operations.md` "Brief / Chatlog location reconciliation" — docs-only correction done.
- `operations.md` "Aggregate digest reproducibility" — closed (STEP3 §15 candidate (b), `1273afe`).
- `operations.md` "Managed block marker detection" — closed (`GLOBAL_ADOPTION_DECISION.md` §6).
- `operations.md` "Global instruction file path semantics" — closed.
- `operations.md` "Channel 3 smoke validation closeout" — closed.
- `operations.md` "Activation managed-block apply tooling hardening" — closed.

### Historical / removed-legacy (historical reason only, never operator paths)

- `operations.md` "Review-cycle invocation quoting hardening" — historical/closeout (review-cycle removed-legacy).
- `review.md` "Review-cycle file-backed request input" — integrated closeout with the above.
- `review.md` "Removed legacy review artifacts (historical reason only)" — historical reason.

## Placement rule

backlog / future-decision 항목의 기록 위치 우선순위:

- 기존 docs (guide / contract / operator manual) 의 목적과 자연스럽게 맞으면 그 문서 안에 기록한다.
- review/install-update system 의 open work 는 해당 system 의 `BACKLOG.md` 에 둔다.
- 회색지대일 때는 `docs/backlog/` 안의 minimum category file (`operations.md` / `review.md`) 을 default 로 본다.
- `docs/` 폴더 taxonomy 전체 재설계는 별도 scoped goal 없이는 수행하지 않는다 (본 reset 이 그 scoped goal 이다).

## 현재 category file

- [`review.md`](./review.md) — review subsystem / review operation 후보 + removed-legacy historical reason.
- [`operations.md`](./operations.md) — smoke 운영, docs hygiene, evidence preservation 등 + closed/historical operational 기록.
