# {{DOMAIN}} Plan

> 사용법: 이 형틀은 Plan의 권장 기본 구조다. `<domain>_plan.md` 로 복제해 승인 대상 결정을 채우되, 의미가 보존되면 heading을 합치거나 조정할 수 있다. 조사 결과는 Work Packet, 실행 기록은 `log/**` 소관이다. Plan이 Design 결정을 바꾸면 rewind한다. Plan의 still-relevant 의미는 최종 corrected-state review 전에 owner에 흡수되고, Plan 자체는 retirement-only closeout에서 삭제된다. 이 Plan은 mutation/commit/push 승인이 아니다(1회 진술).

## Header

{{이 문서는 무엇의 Plan 인가 — 3줄 이내}}
{{이 체인이 끝나면 무엇이 되는가 — 3줄 이내}}
{{이 문서가 아닌 것 — 3줄 이내}}

## Batch 순서와 의존

{{batch 순서 + 순서 근거(의존 관계). 통합/분리 근거}}

## Batch 정의

{{각 batch의 목적 / scope / hard boundary / validation expectation / review focus / Work Packet 필요 여부. Work Packet이 필요하면 목적·흡수 대상·retire 조건을 선언. 각 terminal-rule revision은 최종 corrected-state review 전에 actual foreign-Spec thin-interface direct-sync path set과 Plan의 declared foreign-Spec direct-sync-target path set을 빈 집합까지 정확히 reconcile하고, 그 declaration과 reconciliation을 reviewed pre-transaction Plan/current candidate에 포함. Review 뒤 해당 set·declaration·target-relevant meaning이 바뀌면 retirement-only로 진행하지 않고 candidate correction/review로 복귀. Actual set이 비어 있지 않으면 그 target을 aggregate/dependency 목록과 구별해 exact scope에 명시. 다른 closeout에서 domain-local lifecycle이 0인 affected Spec의 marker disposition을 판정할 때 surviving open revision별 declared membership과 current actual membership을 재구성해 정확히 비교하고, 재구성 불가·모호·불일치이면 `not retirement-only`로 open revision을 reconcile하거나 closeout을 보류한 뒤 재판정. 둘 다 참인 surviving revision이 있으면 같은 transaction에서 함께 retire하거나 claim을 먼저 제거할 때까지 현재 closeout을 끝내지 않음}}

## Open decision 의 close 지점

{{상위 Design 의 open decision 각각이 어느 batch 에서 닫히는지 배정. Plan 자신이 닫는 결정이 있으면 명시}}

## Stage rewind 조건

{{이 Plan 이 Design 위반 시 / 하위 Spec 이 이 Plan 위반 시 / 구현이 Spec boundary 초과 시의 stop·rewind 경로}}
