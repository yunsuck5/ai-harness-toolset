# blind-advisory Plan

> Plan은 이번 revision에서 승인된 결정과 범위를 담는다. 조사 근거는 Work Packet, 목표 상태는 Spec, active behavior는 skill이 소유한다. 이 Plan은 mutation·commit·push 승인이 아니다.

## Header

- 같은 role-slot의 미종결 선행 blind-advisory lifecycle을 이 revision에서 계속한다. 승인된 작업은 기존 계약을 폐기하고 동일 이름의 최소 경량 skill로 전면 교체하는 것이며, 이 계속 결정의 승인 provenance는 changeset 기록이 소유한다.
- 기존 계약은 current authority로 승계하지 않는다.
- closeout과 global activation은 이번 batch 밖이다.

## Batch definition

- **목적**: 명시 호출된 fresh reviewer가 current repo를 read-only 정적으로 훑고, 위치와 이유가 붙은 결함 후보만 간결하게 반환하는 skill을 만든다.
- **대상**: Design, Plan, Spec, Work Packet, Backlog, source SKILL과 구계약 전용 glossary·orchestration·review·docs-working-model 결박, review backlog의 consultation-only consumer-interface 한 행이다.
- **owner**: active behavior는 SKILL, durable target은 Spec, 회차 판단은 Design·Plan·Work Packet, future work는 Backlog가 소유한다.
- **종료 상태**: 새 최소 계약이 1:1로 정렬되고 구계약 전용 용어·status·출력 결합 규칙이 제거되며 orchestration의 generic cheap-first 순서는 보존된 uncommitted working tree와 자체 검토 근거를 만든다.

## Approved decisions

### 호출과 입력

- 사용자 또는 ordinary caller가 `$ai-harness-blind-advisory`, `ai-harness-blind-advisory`, 또는 Blind skill 실행을 명시적으로 요청한 경우에만 실행한다. 이름 인용·설명·검토는 invocation이 아니다.
- ordinary review, fresh review, independent review, 일반 “블라인드 리뷰” 문구만으로는 암묵 호출하지 않는다.
- reviewer는 별도 bundle을 받지 않고 current repo에 직접 위치한다.
- prompt는 실제 검토 범위가 들어간 정적 read-only 경계·작업 목적·현재 위치·결함 후보 요청만 담는 6줄 구조다.
- worker narrative, 이전 verdict, 예상 finding, test 결과 주장을 넣지 않는다.
- 사용자가 별도 scope를 정하지 않았다면 diff-only나 selected-file-only로 축소하지 않는다.

### 실행 topology

- 기본은 fresh reviewer 한 명이다.
- 작업량이 클 때만 reviewer가 ordinary read-only subagent를 한 단계 사용할 수 있다.
- main session과 ordinary subagent 모두 Blind를 명시 호출할 수 있다.
- 자신이 ai-harness-toolset skill 실행으로 생성된 lineage임을 아는 caller는 Blind를 포함한 ai-harness-toolset skill을 다시 호출하지 않는다.
- reviewer child는 추가 reviewer를 만들지 않는다.
- reviewer와 그 child가 모두 끝나거나 명시적으로 중단된 뒤 결과를 받는다.
- reviewer와 child는 파일 변경과 테스트 실행을 하지 않는다.

### 결과

- reviewer final message를 요약·선별·재구성하지 않고 그대로 반환한다.
- reviewer는 host의 final-message-only/no-trace 결과 경로로만 호출한다. 해당 경로를 사용할 수 없으면 reviewer를 시작하지 않고 `unavailable(output-isolation-unavailable)`로 닫는다. skill 전용 result artifact는 만들지 않는다.
- final message를 얻지 못하거나 금지된 변경·테스트·toolset 재호출이 호스트나 호출자에게 관측되면 `unavailable(<짧은 실제 사유>)`로 닫는다.

## Hard boundary

- 기존 authority manifest, full-content stdin packaging, hash binding, closed status/severity, finding 필드 강제, carrier·retention·retry·recovery machinery를 재도입하지 않는다.
- canonical review·consultation의 동작/계약, Brief, install/update/uninstall, global/user surface와 일반 candidate 검사를 수정하거나 호출하지 않는다. review backlog는 consultation-only consumer-interface 한 행만 수정한다.
- staging, commit, push, activation은 사용자 별도 승인 전 금지한다.

## Validation focus

- Design·Plan·Spec·SKILL의 최소 계약이 1:1인지 확인한다.
- frontmatter가 explicit invocation만 허용하고 ordinary review trigger를 배제하는지 확인한다.
- prompt가 기본 6줄과 대규모 조건부 1줄을 넘어서 비대해지지 않았는지 확인한다.
- current repo direct review, no mutation, no tests, no toolset recursion, one-layer fan-out이 함께 유지되는지 확인한다.
- 기존 status·authority·transport machinery와 BA-01~03 잔여가 없는지 검색한다.
- glossary의 `transporter`·Blind status, O에 결박된 구 Blind status·출력 결합, review backlog의 Blind interface가 제거되고 O의 generic cheap-first 순서는 보존됐는지 확인한다. consultation-only consumer 질문이 review backlog에 좁혀 유지되는지, docs-working-model의 B leg가 새 lifecycle 리뷰 게이트로 재지정됐는지도 확인한다.
- docs-working-model checker와 repo 밖 공식 skill-creator의 `quick_validate.py`(또는 동등 정적 검사)는 구조 근거로 사용하되 의미 검토를 대체하지 않는다.

## Work Packet declaration

Work Packet은 실험 관측, 기존 계약 요소별 회차성 분류표, topology 대조와 독립 감사 질문만 담는다. 채택 결정은 Design·Plan, durable 계약은 Spec, 실행 mechanics는 SKILL에 흡수하며 실행 결과·readiness·commit 절차는 담지 않고 closeout에서 retire한다.

## Stage rewind

- Plan이 Design의 최소 계약을 넓히면 Plan을 다시 줄인다.
- Spec이 Plan보다 더 많은 상태나 절차를 만들면 Spec을 다시 작성한다.
- SKILL이 Spec보다 더 많은 입력·출력·오케스트레이션을 요구하면 구현과 이후 검토를 stale 처리한다.
- 새 최소 계약 또는 구계약 잔재 제거 밖의 owner 의미를 바꾸게 되면 중단한다.
