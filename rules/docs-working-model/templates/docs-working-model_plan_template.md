# {{DOMAIN}} Plan

> 사용법: 이 형틀을 복제해 `<domain>_plan.md` 로 채운다. 모든 `{{...}}` 를 치환한다. Plan 은 **승인 대상인 의사결정만** 담는다 — 작업 메모가 아니다. 조사 결과·line 분류·candidate-file 분석·구현 노트는 Work Packet(`docs/<domain>/<domain>_work_packet.md` — committed temporary, closeout 시 삭제) 소관이고, 실행 명령 시퀀스·staging 절차·실행 기록은 operator report(`log/**`) 소관. Plan 이 Design 을 위반하면 stop → Design 재설계 후 재시작(rewind). Plan 은 영구 live 아님 — closeout 시 흡수 후 retire(삭제). 이 Plan 은 mutation/commit/push 승인이 아니다(1회 진술).

## Header

{{이 문서는 무엇의 Plan 인가 — 3줄 이내}}
{{이 체인이 끝나면 무엇이 되는가 — 3줄 이내}}
{{이 문서가 아닌 것 — 3줄 이내}}

## Batch 순서와 의존

{{batch 순서 + 순서 근거(의존 관계). 통합/분리 근거}}

## Batch 정의

{{각 batch 마다: 목적(한 줄) / scope(다루는 것·다루지 않는 것) / hard boundary(불가침 표면) / validation expectation(무엇이 성립해야 하는가) / review focus / Work Packet 필요 여부(필요 시 목적·흡수 대상·retire 조건 3요소 선언)}}

## Open decision 의 close 지점

{{상위 Design 의 open decision 각각이 어느 batch 에서 닫히는지 배정. Plan 자신이 닫는 결정이 있으면 명시}}

## Stage rewind 조건

{{이 Plan 이 Design 위반 시 / 하위 Spec 이 이 Plan 위반 시 / 구현이 Spec boundary 초과 시의 stop·rewind 경로}}
