# {{DOMAIN}} Design

> 사용법: 이 형틀은 Design의 권장 기본 구조다. `<domain>_design.md` 로 복제해 필요한 의미를 채우되, 의미가 보존되면 heading을 합치거나 조정할 수 있다. Design은 영구 live가 아니며 closeout에서 흡수 후 삭제된다. 이 Design은 mutation/commit/push 승인이 아니다(1회 진술).

## Header

{{이 문서는 무엇의 Design 인가 — 3줄 이내}}
{{이 체인이 끝나면 무엇이 되는가 — 3줄 이내}}
{{이 문서가 아닌 것 — 3줄 이내}}

## 왜 바꾸는가 / 무엇을 바꾸는가

{{현행 live Spec·구현의 어떤 문제를 푸는가 / 변경의 큰 그림(정확한 boundary 는 Spec 의 일)}}

## Owner surface model

{{이 변경 후 어떤 active surface 가 무엇을 소유하는가. rules 는 class/invariant/approval boundary 만 명명하고 behavior 를 흡수하지 않는다}}

## 수정 대상

{{이 변경이 수정·대체하는 기존 live Spec·구현·구조물}}

## 하지 않을 것 (non-goals)

{{명시적으로 하지 않는 것 — rejected terms/domains 부활 · broad cleanup · scope creep 차단}}

## Plan readiness / open risks

{{이 Design이 Plan으로 내려가도 되는가 + 방향 결정을 위해 남은 open risk와 close 지점}}
