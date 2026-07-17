# blind-advisory Design

> Design은 변경 방향을 정한다. 이 문서는 실행 기록이나 영구 runtime authority가 아니며, closeout에서 current-bearing 내용이 Spec과 skill에 흡수되면 retire한다. 이 Design은 mutation·commit·push 승인이 아니다.

## Header

- 선행 blind-advisory lifecycle은 closeout 전 실사용 평가 단계였고, 평가 결과 closeout 조건을 충족하지 못했다. 따라서 같은 role-slot의 미종결 작업을 이 revision에서 계속하되, 사용자 의도와 다르게 비대해진 기존 계약은 폐기하고 원래 의도인 경량 정적 결함 prefilter로 전면 재작성한다.
- 새 의미의 owner는 얇은 독립 skill이다. Design·Plan·Spec·Work Packet은 그 의미와 회차 판단을 기록할 뿐 runtime dependency가 아니다.
- canonical review와 consultation의 동작·계약, 일반 협업 규칙, install/update 배포 mechanics는 이 revision의 대상이 아니다. 구 review backlog의 cross-owner 질문은 Blind 절반을 폐기하고 consultation-only review-consumer 질문으로 좁힌다.

## 방향 결정

### 얇은 독립 skill을 유지한다

두 선택지를 대조했다.

- **얇은 독립 skill**은 사용자가 명시 호출할 수 있고, fresh reviewer 호출·최소 prompt·재귀 차단을 한곳에서 소유한다.
- **prompt template 또는 상시 rule로 격하**하면 호출 시점과 fresh reviewer 경계를 소유하지 못하거나, ordinary work에 불필요한 규칙을 항상 적재한다.

따라서 blind-advisory는 독립 skill로 유지하되, 기능을 아래 최소 계약으로 제한한다. skill은 일반 review 문구나 이름 인용으로 암묵 호출되지 않고 사용자 또는 ordinary caller가 이 skill 실행을 명시적으로 요청한 경우에만 실행한다.

### 새 최소 계약

1. 현재 repo를 직접 읽는 fresh reviewer 한 명을 호출한다.
2. reviewer는 read-only 정적 검토만 한다. 파일 변경, 테스트 실행, ai-harness-toolset skill 호출을 금지한다.
3. 입력은 실제 검토 범위를 넣은 첫 줄, 파일 변경·테스트 실행·ai-harness-toolset skill 사용을 금지하는 둘째 줄, 작업 목적 한 줄, 현재 위치 한 줄, 위치와 이유가 붙은 결함 후보 요청 한 줄로 이루어진 6줄 prompt다.
4. 기본은 단일 reviewer다. 작업량이 클 때만 같은 경계를 받은 ordinary read-only subagent를 한 단계 사용하며 추가 위임하지 않는다.
5. 자신이 ai-harness-toolset skill 실행으로 생성된 lineage임을 아는 caller는 Blind를 포함한 ai-harness-toolset skill을 다시 호출하지 않는다. Blind reviewer의 자식은 추가 위임하지 않는다.
6. reviewer final message를 가공하지 않고 그대로 반환한다.
7. reviewer final message를 얻지 못했거나 금지된 변경·테스트·toolset 재호출이 호스트나 호출자에게 관측되면 `unavailable(<짧은 실제 사유>)`로만 보고한다.

입력에는 worker report, 이전 verdict, 예상 결론, 의심 위치, test 통과·실패 주장처럼 결론을 유도하는 설명을 넣지 않는다. 반면 repo 자체, repo에 적용되는 instruction, 코드와 문서는 reviewer가 직접 읽는다. 별도 authority manifest나 full-content bundle을 조립하지 않는다.

### 출력은 reviewer final message만 남긴다

- reviewer는 host의 final-message-only/no-trace 결과 경로로만 호출한다. 해당 경로를 사용할 수 없으면 reviewer를 시작하지 않고 `unavailable(output-isolation-unavailable)`만 반환한다.
- reviewer final message를 요약·선별·재구성하지 않고 그대로 반환한다.
- skill 전용 `result.md`, output template, hash manifest, carrier 상태기계를 만들지 않는다.

## 기존 E4 결정의 전면 폐기

기존 Design E4의 adopted/rejected corpus는 이번 revision의 출발점이나 기본값으로 승계하지 않는다.

- **adopted conclusion**: read-only defect-candidate prefilter, non-verdict, 결론유도 narrative 축소, single-shot, final message 무가공 반환과 실패 비세탁을 새 최소 계약으로 채택한다.
- **rejected alternatives**: closed status·trigger·severity, finding 필드 gate, authority manifest, neutral cwd·full-content stdin adapter, byte binding, binary/tombstone transport, artifact·hash·retention, timeout·retry·recovery·JOIN 상태기계와 reason catalog를 폐기한다.
- **judgment-changing evidence type**: 짧은 direct-repo prompt는 위치·이유 후보를 만들었고, 기존 skill 경로는 암묵 중첩·대량 trace·응답 구성 실패·후가공 비용을 만들었다.
- **scope**: Blind lifecycle 5문서와 source skill을 다시 쓰고, 구 Blind status·출력 계약이 glossary·orchestration candidate·review backlog·docs-working-model planning에 남긴 전용 결박을 제거하며 consultation-only review-consumer 질문은 review backlog에 좁혀 유지한다. orchestration의 generic cheap-first 순서, 이름 기반 install·discovery surface와 일반 candidate 검사는 유지한다.
- **failure/discard criteria**: ordinary review 암묵 호출, toolset 재귀, 다단 fan-out, canonical급 비용 또는 응답 후가공이 반복되면 이 설계를 다시 줄이거나 폐기한다.
- **known negative evidence**: direct reviewer도 repo instruction과 모델 편향의 lens를 받으며 correctness·coverage를 보장하지 않는다. optional fan-out은 시간·context 비용을 늘릴 수 있고 vendor별 explicit-trigger 기계 지원도 동일하지 않다.

새 계약의 `read-only`, `non-verdict`, `unavailable`은 기존 계약을 상속한 것이 아니라 사용자 승인 최소 목적에 따라 새로 채택한 결정이다.

## 수정 대상

- Blind owner surface: target-state Spec와 source skill을 새 최소 계약에 1:1로 정렬한다.
- Blind lifecycle support surface: Design·Plan·Work Packet·Backlog를 같은 방향에 맞추고 구 확장 backlog 항목을 제거한다.
- cross-owner residue surface: glossary·orchestration·canonical-review·docs-working-model에 남은 구 Blind 전용 status·출력 결박만 제거하거나 새 lifecycle gate로 재지정한다.
- review owner surface: consultation 자료의 canonical intake/reporting 질문을 consultation-only consumer interface로 좁혀 backlog에 유지한다.

기존 backlog의 BA-01·BA-02·BA-03은 구계약 확장 또는 cross-owner 결박이므로 제거하고, 이력 단조성을 위해 `next ID: BA-04`만 유지한다.

## 하지 않을 것

- 기존 Blind의 transport·authority·status machinery를 축소판으로 재도입하지 않는다.
- diff-only, selected-file bundle, full-content packaging을 기본 검토면으로 만들지 않는다.
- canonical verdict나 consultation synthesis를 흉내 내지 않는다.
- 결과 파일, schema, helper, adapter script, registry, telemetry ledger를 추가하지 않는다.
- reviewer가 테스트를 실행하거나 mutable 작업을 하게 하지 않는다.
- install/update/uninstall, global mirror, 일반 candidate 검사와 다른 owner의 독자 semantics를 수정하지 않는다.
- closeout, activation, commit, push를 수행하지 않는다.

## Plan readiness

방향은 닫혔다. Plan은 위 최소 계약을 문서와 skill에 1:1로 반영하고, 기존 무거운 계약의 잔여 문구가 남지 않았는지를 검증 대상으로 삼는다.

## Future-work pointer

현재 시작하지 않는 blind-advisory 소유 future work의 단일 home은 `blind-advisory_backlog.md`다.
