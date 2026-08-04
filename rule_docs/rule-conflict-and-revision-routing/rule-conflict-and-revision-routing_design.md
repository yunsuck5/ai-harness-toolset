# rule-conflict-and-revision-routing Design

> 이 Design은 `rule-conflict-and-revision-routing`을 충돌 진입과 사용자 선택 경계로 축소하는 방향성 문서다. 영구 live surface가 아니며 closeout에서 의미를 terminal rule에 흡수한 뒤 삭제된다. 이 문서는 mutation/commit/push/adoption/activation 승인이 아니다.

## Header

- 대상은 adopter-universal distributed rule인 `snippets/rules/rule-conflict-and-revision-routing.md`다.
- 변경 목적은 실제 충돌을 안전하게 드러내되, 그 이후의 처분·추적·종결 lifecycle을 공통 규칙이 선점하지 않도록 authority를 좁히는 것이다.
- 이전 planning anchor가 제안한 공통 terminal outcome과 owner backlog 확장은 채택하지 않는다. 그 판단과 이전 문면은 git history에 보존한다.

## 왜 바꾸는가 / 무엇을 바꾸는가

이 규칙의 필요한 역할은 단순하다. 적용 중인 active rule과 구체 작업 또는 acceptance condition을 어떤 compliant path로도 함께 만족시킬 수 없을 때, 현재 rule을 우회하지 않고 정확한 충돌 범위를 공개한 뒤 사용자가 다음 방향을 선택하게 해야 한다.

현행 문면은 이 목적을 넘어 conflict set, same-tier scope, 고정 disclosure 항목, revision owner interface를 공통 규칙이 정의한다. 이전 revision 방향은 여기에 수신 outcome과 원 작업 종결 상태까지 더하려 했다. 이런 확장은 서로 다른 owner의 lifecycle을 공통 taxonomy로 묶고, 보고를 새 상태기계나 영구 추적 의무로 바꿀 위험이 있다.

따라서 terminal rule은 다음 네 의미만 보존한다.

1. identified active-rule owner와 concrete required operation 또는 acceptance condition 사이에 compliant path가 없을 때만 이 규칙에 진입한다.
2. 승인된 revision이 실제로 반영되기 전까지 적용 rule과 명시된 compliant branch는 계속 binding이다.
3. 충돌 보고는 owner, 막힌 작업·acceptance condition, exact incompatibility, affected scope, 확인한 compliant alternative만 운반하며 예외·우선순위·완료 상태를 만들지 않는다.
4. 사용자는 compliant rescope, hold/drop, 또는 해당 owner의 revision lifecycle 시작 중 하나를 선택한다. revision 시작 자체는 어떤 downstream 승인도 부여하지 않는다.

## Owner surface model

- 이 terminal rule은 충돌의 admission, 현재 rule의 지속적 binding, 최소 공개, 사용자 선택 경계만 소유한다.
- 충돌 대상 active owner는 자기 규칙의 의미, 실제 revision lifecycle, 승인 및 종결 조건을 소유한다.
- 원 작업 또는 workflow owner는 자기 작업의 pause/resume/completion과 필요한 추적을 소유한다.
- DWM은 이 repo에서 rule revision의 Design/Plan/closeout lifecycle만 소유한다. 이 distributed rule은 DWM 절차를 adopter에게 복제하지 않는다.
- 공통 enum, registry, queue, scanner, checklist, owner interface 또는 cross-owner terminal protocol은 만들지 않는다.

## 선택한 trade-off

- **정밀한 진입 조건을 유지한다.** 단순 비용·불편·선호·노후화·해석 질문은 conflict가 아니다. applicability가 불명확하면 해당 owner에게 묻는다.
- **고정 양식보다 필요한 사실을 유지한다.** 보고에 필요한 다섯 사실은 남기되, 별도 schema나 필드 이름을 요구하지 않는다.
- **미결 추적의 일반 보장을 포기한다.** 모든 owner에 공통 종결 장치를 강제하지 않는 대신, 실제 작업의 연속성과 close point는 그 작업과 owner가 책임진다.
- **우회는 계속 금지한다.** 규칙을 좁히는 것은 conflict를 곧바로 waiver로 바꾸거나 사용자가 승인하지 않은 mutation을 허용하는 것이 아니다.

## 하지 않을 것 (non-goals)

- conflict를 비용·편의·일반 해석 문제까지 넓히지 않는다.
- conflict-isolated/unit-blocking, same-tier conflict set, 고정 9필드 disclosure, 네 가지 terminal outcome 같은 공통 taxonomy를 유지하거나 새로 만들지 않는다.
- revision handoff 이후 foreign owner의 durable record, close point, 원 작업 status 형식을 이 규칙에서 규정하지 않는다.
- bootstrap의 trigger route나 managed adoption 문면을 바꾸지 않는다.
- `DWM-B-20`, `GFM-B-05`, `PFE-B-05`를 이번 변경의 잔여로 등재하지 않는다.
- runtime helper, schema, checker, test-only gate를 새로 만들지 않는다.

## Semantic target

최종 rule은 짧고 자족적이어야 한다. 읽는 사람은 그 문면만으로 진입 조건, 우회 금지, 공개할 근거, 사용자가 선택할 다음 방향을 복원할 수 있어야 한다. 반대로 수신 owner의 lifecycle·상태 vocabulary·종결 책임은 그 문면만으로 추론되거나 강제되어서는 안 된다.

## Plan readiness / open risks

사용자가 narrow-retain 방향과 planning anchor 뒤 terminal landing 구조를 승인했으므로 Plan으로 내려갈 준비가 됐다.

- **과소 규정 위험:** 공통 종결 보장을 제거하면서 실제 workflow가 미결을 잃을 수 있다. 이는 필요한 경우 해당 workflow/owner에서 다룰 문제이며 이 rule의 공통 lifecycle 확장으로 선제 해결하지 않는다.
- **과대 해석 위험:** `ask the user`가 모든 모호성의 중앙 arbitration으로 읽힐 수 있다. genuine conflict admission과 owner applicability 질문을 분리한다.
- **우회 위험:** revision 착수를 임시 예외로 읽을 수 있다. landing 문면에서 binding과 downstream 승인 부재를 명시한다.
- **역사 왜곡 위험:** 이전 B04 방향을 조용히 덮지 않는다. planning anchor와 seal은 외부 evidence 및 git history에 보존하고 새 Design은 supersession을 명시한다.
