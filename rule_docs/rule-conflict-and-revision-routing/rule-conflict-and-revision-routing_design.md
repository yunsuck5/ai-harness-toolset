# rule-conflict-and-revision-routing Design

> Design은 변경의 방향성 문서이며 영구 live surface가 아니다. current-bearing 내용은 terminal rule에 흡수되고 promoted-lifecycle closeout에서 이 문서는 삭제된다. 이 Design은 mutation/commit/push/adoption/activation 승인이 아니다.

## Header

- 이 문서는 active rule과 구체 작업의 genuine conflict를 격리·공개하고 owner-local revision 결정으로 운반하는 global-distribution rule의 Design이다.
- 이 체인이 끝나면 `snippets/rules/rule-conflict-and-revision-routing.md`가 conflict event의 containment / disclosure / revision handoff를 자족적으로 소유한다.
- 이 문서는 rule precedence, 예외 허가, owner별 의미, source-repo revision 절차 또는 최종 normative wording을 소유하지 않는다.

## 왜 바꾸는가 / 무엇을 바꾸는가

현재 distributed rules는 각자 자기 safety property와 mutation boundary를 소유하지만, 적용 중인 rule을 지키면서 요청된 operation 또는 acceptance condition을 달성할 수 없을 때 공통으로 사용할 revision handoff는 갖지 않는다. 그 공백에서는 다음 두 실패가 대칭으로 생긴다.

1. 현재 문면을 완전한 불변식처럼 취급해 정당한 rule 재검토까지 위반으로 닫는다.
2. 오래됐거나 불편하다는 판단만으로 현재 binding state를 즉석 예외·완화 해석·force로 우회한다.

변경은 이 둘 사이의 타협 규칙을 만들지 않는다. 보통의 operating rule은 개정 가능하지만, 개정 가능성은 현재 rule을 자동 약화하지 않는다. genuine conflict를 입증한 뒤 현재 rule을 binding으로 유지하고, dependency facts로 영향 범위를 제한하며, blocked 상태와 대안을 공개한 다음 사용자가 compliant alternative 또는 해당 owner의 정규 revision을 선택할 수 있게 하는 한 개의 transport rule을 만든다.

## 설계 결정

- **진입 조건:** applicable active-rule owner, 구체 operation/acceptance condition, compliant path로는 둘을 함께 만족할 수 없다는 incompatibility가 모두 식별될 때만 genuine conflict다. 비용·불편·선호·노후 주장·단순 해석 질문은 단독 trigger가 아니다.
- **현재 binding state:** conflict 발견이나 원 작업 승인은 exception이 아니다. applicable owner가 이미 제공하는 정상 branch 또는 scoped exception이 있으면 그것을 먼저 따르고, owner 의미가 불명확하면 적용 범위를 G가 추정하지 않는다.
- **dependency containment:** `conflict-isolated`는 pre-existing 또는 명시적으로 미래 지향 재범위된 독립 단위가 blocked output/state/assumption, shared invariant, owner contract, validator, transaction·commit boundary, acceptance gate, coherence unit을 공유하지 않고 독립 evidence·acceptance·status를 가질 때만 성립한다. 하나라도 의존하거나 독립성이 불명확하면 `conflict-unit-blocking`이다.
- **상태 정직성:** isolated work가 계속돼도 blocked branch와 전체 task의 완료·canonical readiness·commit readiness를 세탁하지 않는다. 사후 scope 축소는 과거 blocked unit을 소급 완료시키지 않는다.
- **owner-local 우선:** owner-specific path가 containment, disclosure, terminal disposition 또는 revision handoff까지 자족하면 중복 절차를 얹지 않는다. 일부만 제공하면 G는 빠진 transport 단계만 보충하고 owner schema나 의미를 복제하지 않는다.
- **동일 계층 conflict:** 임의 precedence를 만들지 않고 conflict set을 하나의 affected unit으로 드러낸다. 여러 owner revision을 한 batch로 강제하지 않으며, 각 owner lifecycle은 독립적으로 진행하되 호환되는 active state가 성립할 때까지 affected unit은 blocked로 남는다.
- **공개와 결정:** 기본 report는 현재 대화에 인라인으로 남기고, applicable owner, 충돌 operation/acceptance, exact incompatibility, affected scope, dependency classification, 확인한 compliant alternative, current binding state, 계속 가능한 work, 필요한 user decision을 한 번에 드러낸다. 각 필드는 evidence/status transport이며 completion claim이 아니다. 사용자는 compliant rescope, 보류·포기, owner-local revision 착수 중 하나를 선택하며, revision 착수는 실제 mutation/commit/push/adoption/activation 승인을 대신하지 않는다.
- **경량성:** sidecar state, queue, registry, hook, scheduler 또는 자동 mutation을 만들지 않는다. trigger는 conflict 또는 binding rule 때문에 막힌 작업의 revision 요청으로 한정하고 정상적인 rule 해석마다 항상 로드하지 않는다.

## 판단 근거와 한계

### 채택을 지지한 evidence type

- 서로 다른 작업 맥락에서 over-stop과 instant bypass가 모두 반복 관측됐고, 현재 distributed source set에는 이를 owner 의미 복제 없이 revision decision으로 운반하는 single home이 없다.
- 서로 독립된 owner rule을 대상으로 한 정적 counterexample set에서 정상 exception과 genuine conflict, 독립 조사와 필수 산출, user bypass, same-tier/machine invariant, 오래된-rule 주장, partial reuse와 사후 scope 분할, 금지된 evidence 실험을 같은 containment model의 경계로 다룰 수 있었다.
- promotion 근거에는 실제 revision 사례가 필수는 아니다. 여러 owner에 걸친 정적 반례가 두 실패 방향을 모두 공격하고 foreign semantics 없이 같은 경계를 재현하면 충분하다.

### known negative evidence / residual risk

- originating case 밖의 live use에서 분류 안정성과 인지 비용이 아직 장기간 실증되지는 않았다.
- conservative default가 불필요한 stop을 늘리거나, 반대로 shared semantic dependency를 놓칠 수 있다.
- 특정 세션에서 같은 문제가 재현되지 않았다는 사실만으로 반복 운용 관측과 사용자 제공 맥락이 반증되지는 않는다.
- 이 한계는 promotion blocker가 아니라 좁은 trigger, fail-closed unknown, static negative cases, 이후 실제 사건에서의 정상 revision으로 관리할 residual risk다. 별도 hidden telemetry나 상시 pilot은 만들지 않는다.

### 기각한 대안

- 현재 rule 문면을 수정 불가능한 최종 목적처럼 다루는 hard-immutability 해석.
- 사용자의 원 작업 승인·노후 주장·선호를 즉석 exception 또는 force 권한으로 바꾸는 방식.
- 이 transport를 기존 owner rule 하나에 graft하거나 여러 owner rule에 복제하는 방식.
- generic precedence engine, policy arbitration, owner registry 또는 umbrella governance로 확장하는 방식.
- hidden queue/state, 자동 mutation, hook/scheduler로 revision을 진행시키는 방식.
- 모든 owner revision을 한 changeset으로 묶거나, 반대로 batch 분리만으로 blocked work에 permission이 생긴다고 보는 방식.
- live cross-owner revision 사례가 생길 때까지 promotion을 무조건 보류하는 방식.

## Failure / rewind criteria

다음 evidence가 나오면 현재 Design을 유지한 채 terminal landing하지 않고 promotion-withdrawal 또는 Design revision으로 되돌린다.

- 실제 conflict 사례가 각 owner-local path만으로 containment·disclosure·revision handoff까지 반복해서 자족해 별도 cross-cutting gap이 사라진다.
- 두 classification이 dependency facts보다 정책 선호·결과 맞추기·사후 scope 재분할에 좌우된다.
- 작동을 위해 precedence, exception authority, owner registry, hidden state, automatic mutation 또는 source-repo governance가 필요해진다.
- partial continuation이 completion laundering이나 shared-invariant 누락을 반복하고 terminal negative cases로 경계를 안정화할 수 없다.
- always-on 인지 비용과 false stop이 owner-local 중복 제거 이득보다 커지거나 distributed admission/public-safe/self-contained 조건을 만족하지 못한다.

## Owner surface model

- 새 terminal rule은 **conflict event transport**만 소유한다: 진입 조건, dependency containment, disclosure, user revision handoff.
- 각 active rule은 자기 trigger, safety property, default, exception, validation과 실제 revision의 의미를 계속 단독 소유한다.
- `snippets/rules/README.md`는 distributed-tier admission과 index를, 두 snippet의 trigger gate는 action class에서 terminal rule로의 load routing만 소유한다.
- source repository의 `docs-working-model`은 이 저장소에서 rule을 추가·개정하는 lifecycle을 소유하지만 distributed runtime rule의 의존성은 아니다.
- glossary는 후보가 도입한 이름의 분류와 최종 상태만 소유하며 full semantics는 terminal rule에 남는다.
- repository/global mutation owners와 host instruction priority는 그대로 유지된다. G는 그 승인 또는 우선순위를 재정의하지 않는다.

## 수정 대상

- global-distribution rules tier: 새 terminal rule, tier index, action-class trigger map.
- terminology surface: promotion 중 노출되는 candidate-introduced 이름의 thin reservation과 terminal landing의 finalization decision.
- validation surface: docs-working lifecycle 구조, snippet symmetry, trigger routing, counterexample 경계를 검증하는 기존 또는 비례적인 새 검사.
- `rule_docs/rule-conflict-and-revision-routing/`: promotion transition 동안 Design / Plan / Work Packet을 보유하고 terminal landing closeout에서 idle rule-folder 상태로 전환.

## 하지 않을 것 (non-goals)

- 기존 `repository-change-safety`, `no-background-or-hidden-state`, `global-file-mutation-boundary`의 owner 의미 또는 schema 수정.
- C/B/IU 등 별도 domain의 behavior·status·session·synthesis 의미를 이 rule로 끌어올리기.
- 모든 문서·의견·policy 차이를 conflict로 취급하거나 correctness verdict를 발급하기.
- source-repo Design/Plan 절차를 adopter runtime에 강제하기.
- project-local evidence, review trace, `docs/**`, `rule_docs/**`, `log/**` 또는 glossary를 runtime dependency로 만들기.
- global/user instruction 파일의 adoption·activation 또는 root `CLAUDE.md` / `AGENTS.md` mutation.

## Incubation open-question 처분

| 질문 | Design 처분 | 남은 close 지점 |
|---|---|---|
| 정적 cross-owner evidence만으로 충분한가 | **해결:** 서로 다른 owner의 counterexample이 bypass와 over-stop을 함께 공격하면 충분하다. live revision 사례는 필수 promotion gate가 아니다. | terminal review에서 선택한 counterexample coverage를 재확인 |
| 분류가 과도하게 보수적이거나 shared dependency를 놓치는가 | **해결:** all-of isolated 조건 + unknown의 unit-blocking default + prospective user rescope를 채택한다. | terminal wording과 negative cases |
| owner-local path가 자족하는 기준 | **해결:** containment + disclosure + terminal disposition/revision handoff의 기능적 완결성을 기준으로 하고, G는 누락 단계만 보충한다. | terminal wording의 재현 가능성 |
| same-tier conflict가 owner revision을 한 batch로 강제하는가 | **해결:** conflict set은 함께 공개하되 owner lifecycle은 분리할 수 있다. affected unit의 unblock은 호환 active state에 결박한다. | terminal wording과 multi-owner case |
| candidate id와 두 분류값의 glossary 처리 | **해결:** promotion 문서 노출 시 thin `pending` reservation을 두고 terminal landing에서 항목별 finalization을 결정한다. | terminal landing의 glossary decision |
| bootstrap trigger action class | **해결:** genuine conflict 감지 또는 binding rule 때문에 막힌 operation의 revision 요청으로 좁힌다. | 두 snippet의 최종 trigger 문면 |
| promotion 전에 더 필요한 evidence | **해결:** 지정된 정적 cross-owner 반례가 promotion threshold를 충족한다. live-use 부재는 공개 residual risk로 남긴다. | 별도 blocker 없음 |

## Plan readiness / open risks

Plan으로 내려갈 준비가 됐다. candidate identity, semantic target, owner model, rejected alternatives, evidence threshold와 모든 incubation open question의 처분이 결정됐다.

- **terminal wording risk:** trigger가 넓어져 정상 해석 질문까지 잡거나, owner-local fallback 기준이 모호해질 수 있다. terminal landing batch의 문안·반례 검증에서 닫는다.
- **taxonomy risk:** 두 분류값이 permission 또는 severity처럼 읽힐 수 있다. terminal rule과 glossary finalization에서 dependency-containment 분류임을 닫는다.
- **distribution risk:** source-repo residue나 vendor-specific mechanics가 섞일 수 있다. terminal landing의 universal-core/project-residue split과 corrected-state review에서 닫는다.
- **live-use residual risk:** 별도 선행 작업으로 보류하지 않는다. 실제 충돌이 새로운 evidence를 만들면 그 owner 사건과 이 rule의 정상 revision lifecycle에서 재평가한다.
