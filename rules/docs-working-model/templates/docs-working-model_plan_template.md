# {{DOMAIN}} Plan

> 사용법: 이 형틀은 Plan의 권장 기본 구조다. `<domain>_plan.md` 로 복제해 승인 대상 결정을 채우되, 의미가 보존되면 heading을 합치거나 조정할 수 있다. 조사 결과는 Work Packet, 실행 기록은 `log/**` 소관이다. Plan이 Design 결정을 바꾸면 rewind한다. 이 Plan은 closeout에서 흡수 후 삭제되며 mutation/commit/push 승인이 아니다(1회 진술).

## Header

{{이 문서는 무엇의 Plan 인가 — 3줄 이내}}
{{이 체인이 끝나면 무엇이 되는가 — 3줄 이내}}
{{이 문서가 아닌 것 — 3줄 이내}}

## Batch 순서와 의존

{{batch 순서 + 순서 근거(의존 관계). 통합/분리 근거}}

## Batch 정의

{{각 batch의 목적 / scope / hard boundary / validation expectation / review focus / Work Packet 필요 여부. Work Packet이 필요하면 목적·흡수 대상·retire 조건을 선언}}

## Open decision 의 close 지점

{{상위 Design 의 open decision 각각이 어느 batch 에서 닫히는지 배정. Plan 자신이 닫는 결정이 있으면 명시}}

## Stage rewind 조건

{{이 Plan 이 Design 위반 시 / 하위 Spec 이 이 Plan 위반 시 / 구현이 Spec boundary 초과 시의 stop·rewind 경로}}
