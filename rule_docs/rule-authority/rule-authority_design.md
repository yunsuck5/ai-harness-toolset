# rule-authority Design

> 이 Design은 이미 존재하는 `rule-authority` 규칙을 현재 시점의 lifecycle로 재수용하는 방향성 문서다. 과거 신설 당시 Design이 존재했던 것처럼 소급 기록하지 않으며, closeout에서 current-bearing 내용이 올바른 owner surface에 있음을 확인한 뒤 삭제한다. 이 문서는 mutation/commit/push 승인이 아니다.

## Header

- 이 문서는 `rule-authority` 규칙의 누락된 1:1 planning home을 만들고 현행 의미를 재수용하는 Design이다.
- 이 체인이 끝나면 terminal rule의 현재 의미와 routing을 대조하고, rule folder는 후속 queue를 가진 idle 상태로 남는다.
- 이 문서는 terminal rule 재설계, 과거 lifecycle 재현 또는 다른 규칙의 개정이 아니다.

## 왜 바꾸는가 / 무엇을 바꾸는가

`rules/rule-authority.md`는 규칙 조항의 권위 자격과 충돌 시 처분을 정의하지만, 처음 추가될 때 `rule_docs/rule-authority/` lifecycle을 거치지 않았다. 규칙의 현재 의미를 바꾸지 않고 현 시점에서 Design → Plan 대조를 수행해 owner 경계와 non-goal을 다시 확인하고, 이후 개정을 위한 영속 planning home과 실제 future-work queue를 만든다.

이 재수용은 누락 사실을 숨기지 않는다. 현재 terminal rule이 Design의 semantic target을 이미 충족하는 경우 본문을 그대로 유지하고, 실제 결함이 발견되면 이 lifecycle에 몰래 흡수하지 않고 별도 재정을 위해 중단한다.

## Owner surface model

- `rules/rule-authority.md`는 clause × scope × enforcement path 단위의 권위 자격, 등급, 충돌 시 처분을 계속 단독 소유한다.
- root `CLAUDE.md` / `AGENTS.md`와 `rules/README.md`는 좁은 read-first routing만 소유하며 terminal 의미를 복제하지 않는다.
- `rule-conflict-and-revision-routing`은 genuine conflict의 containment·disclosure·revision handoff를 소유하며 권위 등급이나 처분 의미를 대체하지 않는다.
- `rule_docs/rule-authority/`는 이 규칙의 lifecycle planning과 아직 시작하지 않은 후속 queue만 소유한다.

## 수정 대상

- `rule_docs/rule-authority/`: 현재 lifecycle의 Design/Plan과 closeout 뒤 영속 idle anchor 및 backlog.
- `rules/rule-authority.md`, root routing, `rules/README.md`: 변경 대상이 아니라 의미·경계 대조 대상. 실제 불일치가 확인되면 이 범위를 중단한다.

## 하지 않을 것 (non-goals)

- terminal rule의 권위 등급·자격·처분·전칭 stress 의미를 다시 설계하지 않는다.
- managed-block primitive, parity checker, global-file-mutation-boundary lifecycle을 수정하지 않는다.
- 영구 rubric·registry·scanner·checklist나 ordinary task의 필수 load를 만들지 않는다.
- 다른 규칙의 owner 의미, 도메인 behavior 또는 external 작업 기록을 이 rule이나 backlog로 복제하지 않는다.
- 과거 신설 시점의 Design/Plan을 사후에 존재했던 것처럼 주장하지 않는다.

## Plan readiness / open risks

Plan으로 내려갈 준비가 됐다. owner 경계와 terminal-rule 무변경 원칙이 정해졌다.

- **terminal mismatch risk:** 현행 terminal rule이 이 Design의 owner 경계나 권위 분류를 충족하지 않으면 Plan의 대조 batch에서 중단하고 별도 rule revision 재정을 요청한다.
- **future-work inflation risk:** 상류 사전 절차 후보는 아직 시작하지 않은 한 행으로만 backlog에 남기고, 이번 lifecycle에서 normative 절차로 승격하지 않는다.
- **closeout risk:** Design/Plan에만 남은 current-bearing 의미가 없음을 terminal rule·routing·backlog와 대조한 뒤에만 retire한다.
