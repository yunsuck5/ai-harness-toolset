# Backlog

본 폴더는 `ai-harness-toolset` 의 **repo-visible backlog index** 다. handoff-only backlog 가 packet 사이에서 유실되는 risk 를 막기 위해, open 상태의 후보 항목을 repo 안에 명시적으로 남기는 자리다.

본 폴더는 다음이 **아니다**.

- implementation 승인이 아니다.
- 일정 / scheduling 승인이 아니다.
- release / publish / merge 승인이 아니다.
- 구체적 구현은 본 폴더의 항목만으로 진행되지 않는다. 별도 scoped goal 과 review 가 필요하다.

본 폴더의 모든 항목은 "현재 open 후보" 상태일 때만 유지된다. 어느 항목이 별도 scoped goal 로 진행되어 commit/push 되거나, 별도 결정으로 close 되면 해당 항목은 본 폴더에서 제거 또는 close 표시한다.

---

## 탐색 규칙

- backlog 확인 시에는 본 `README.md` 를 먼저 읽고, 관련 category file 을 본다.
- 오래된 handoff packet 안에 남아 있는 backlog 표현과 본 repo backlog 가 충돌하면, **repo backlog 가 우선** 한다.
- 본 폴더의 항목은 design contract 가 아니다. 충돌 시 `docs/` 안의 다른 contract 문서 (예: `docs/REVIEW_RESULT_CONTRACT.md`, `docs/BRIEF_CONTRACT.md`, `docs/CHATLOG_CONTRACT.md`, `docs/AI_HARNESS_TOOLSET_SCOPE.md`, `docs/roadmap/SHARED_GLOBAL_INVOCATION_CONTRACT.md`, `docs/roadmap/POST_MVP_PLAN.md`) 가 우선한다.

---

## Placement rule

backlog / future-decision 항목의 기록 위치는 다음 우선순위를 따른다.

- 기존 docs (guide / contract / operator manual 등) 의 목적과 자연스럽게 맞으면 그 기존 문서 안에 기록한다.
- 기존 문서의 본질이 흐려질 risk 가 있으면 본 `docs/backlog/` 아래 최소 category file 을 사용한다 (없으면 minimum scope 로 새로 만든다).
- 새 파일 생성을 피하려는 이유만으로 다른 문서의 본질이 다른 자리에 backlog 항목을 억지로 끼워 넣지 않는다.
- `docs/` 폴더 taxonomy 전체 재설계는 별도 scoped goal 없이는 수행하지 않는다.

회색지대일 때는 `docs/backlog/` 안의 minimum category file 을 default 로 본다.

---

## 현재 category

- [`review.md`](./review.md) — review subsystem / review operation 후보.
