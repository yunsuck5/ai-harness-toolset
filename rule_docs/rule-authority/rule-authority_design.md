# rule-authority — whole-rule disposition handoff Design

> 이 문서는 existing `rule-authority`의 whole-rule 처분 handoff를 보강하는 임시 Design이다. 이 체인이 끝나면 clause 처분과 terminal identity 전체 처분을 구분하고 후자를 DWM owner-local lifecycle로 넘길 수 있다. 이 문서는 live rule, 실제 처분, mutation/commit/push 승인이 아니며 closeout에서 삭제된다.

## 왜 바꾸는가 / 무엇을 바꾸는가

현행 규칙은 권위를 clause × scope × enforcement path로 평가하고 사용자 결정 뒤 유지·축소·강등·quarantine·제거·이관을 허용한다. 또한 claim 변경·제거 시 active owner와 enforcement를 함께 바꾸도록 한다.

그러나 특정 clause를 처분하면서 terminal identity를 유지하는 경우와 terminal rule 전체를 retire/repeal/replacement하는 경우를 구분하지 않고, 후자의 artifact lifecycle을 어느 owner가 수행하는지 명시하지 않는다. 이번 변경은 그 얇은 구분과 DWM handoff만 추가한다.

## Owner surface model

- `rule-authority`는 exact clause·scope·enforcement의 자격과 사용자 처분을 소유한다.
- DWM은 whole terminal identity의 Design/Plan, owner absorption, terminal source/backlog/planning home, stale reference, closeout과 resume를 소유한다.
- retiring rule은 처분 발효 전까지 자기 claim을 소유한다.
- replacement owner는 retained meaning을 자기 lifecycle로 흡수한다.
- distribution/install owner는 distributed source projection과 runtime materialization을 별도로 소유한다.

## 수정 대상

- `rules/rule-authority.md`의 `## 충돌과 처분`

artifact 순서, file path, backlog, index/trigger, install/activation 의미는 이 rule의 수정 대상이 아니다.

## 하지 않을 것 (non-goals)

- DWM lifecycle이나 distribution 절차를 복제하지 않는다.
- terminal rule별 보호 성질과 claim을 흡수하지 않는다.
- clause 처분 taxonomy를 새 상태기계로 확장하지 않는다.
- actual rule 처분, 중앙 registry, semantic scanner, permanent audit form을 만들지 않는다.
- domain lifecycle과 terminology owner 결정을 바꾸지 않는다.

## Plan readiness / open risks

방향 결정은 닫혔으며 Plan으로 내려갈 수 있다.

- handoff가 너무 자세하면 DWM semantics를 복제하고, 너무 약하면 whole-rule 정상채널이 다시 끊어진다.
- DWM revision과 같은 changeset에서 interface를 1:1 대조하되 두 rule의 독립 owner를 유지한다.
- actual whole-rule 처분은 미실증이므로 이 rule 변경을 성공 사례로 과장하지 않는다.
