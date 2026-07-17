# blind-advisory Work Packet

> 이번 전면 재작성의 조사·대조 packet이다. 승인 결정은 Plan, 목표 상태는 Spec, active behavior는 skill이 소유한다. 이 문서는 실행 결과·readiness·commit 절차를 담지 않으며 closeout에서 retire한다.

## Round purpose and boundary

- 목적: 기존 Blind가 왜 경량 prefilter 정체성을 잃었는지 실측을 바탕으로 분해하고, 새 최소 계약 외의 요구를 제거한다.
- 입력 lens: 짧은 static-review prompt 실험, 기존 Design/Plan/Spec/SKILL의 비용 구조, 사용자 확정 호출 topology.
- 제외: IU 구현, canonical review 자체 개선, consultation 구현·문서 재설계, install/global mirror 수정.
- 기존 Blind 문면은 승계 근거가 아니라 제거 대상 inventory로만 사용한다.

## 실험 관측

| 관측 | 의미 |
|---|---|
| 짧은 목적·현재 위치·정적 read-only prompt만으로도 위치와 이유가 붙은 후보가 반복 반환됨 | full-content bundle과 고정 schema는 유의미한 후보 생성의 필요조건이 아님 |
| 일반 fresh-review 요청이 기존 Blind를 암묵 호출해 대량 trace와 `unavailable`을 남김 | explicit-only trigger와 toolset 재진입 차단이 필요함 |
| “수정하지 말라”만 준 reviewer가 테스트를 실행하고 결과 파일을 만들었음 | `파일 변경·테스트 실행, ai-harness-toolset 스킬을 쓰지 마라`처럼 금지 대상을 병렬로 명시해야 함 |
| subagent 허용·강제의 효과가 모델과 작업량에 따라 달랐음 | 기본 단일 reviewer, 큰 작업에서만 조건부 fan-out이 적합함 |
| fan-out reviewer가 일부 child를 쓰면서도 간결한 후보를 반환함 | one-layer ordinary fan-out은 허용 가능하나 추가 fan-out은 불필요함 |

후보 수와 모델 간 수렴은 correctness verdict가 아니다. 이 관측은 운용 형태와 비용 경계 판단의 근거이며, 채택 결정은 Design·Plan이 소유한다.

## 폐기 대조

| 기존 Blind 요소 | 처분 | 새 대응 |
|---|---|---|
| neutral cwd + full-content stdin packaging | 폐기 | reviewer가 current repo를 직접 읽음 |
| authority manifest·selection rationale 재진술 | 폐기 | repo instruction을 reviewer가 정상적으로 읽음 |
| 3-status·trigger·severity·finding 필드 schema | 폐기 | 위치와 이유가 붙은 자연어 후보 |
| hash binding·target inventory | 폐기 | reviewer의 current repo inspection |
| inline/artifact carrier·result.md·SHA·retention | 폐기 | host의 보통 final-message 전달 |
| timeout·retry·recovery·JOIN 상태기계 | 폐기 | reviewer와 child 종료 뒤 final message만 수신 |
| implicit natural-language trigger | 폐기 | skill 명시 호출 |
| 일반 subagent 차단 | 폐기 | ordinary main/subagent의 명시 호출 허용 |
| `transporter`·Blind status glossary 예약 | 폐기 | Blind identity term만 유지 |
| O의 cheap-first 순서에 결박된 구 Blind status·결합 schema | Blind 전용 결박만 폐기 | O는 generic cheap-first 순서와 최소 evidence만 소유하고 각 workflow semantics는 해당 owner가 소유 |
| review backlog의 Blind·consultation 결과 소비 interface | Blind 절반 폐기, consultation-only review-consumer 질문 유지 | Blind와 canonical은 독립이고 consultation 자료의 canonical intake/reporting 여부는 review owner backlog가 소유 |
| docs-working-model closeout의 구 B Implementation 재리뷰 leg | 재지정 | 재작성된 B lifecycle의 리뷰 게이트 종결 |
| consultation→Blind→O 강제 promotion 순서 | 폐기 | 각 owner lifecycle에서 독립 판정 |
| docs-working-model의 old Blind realignment 대상 이름 열거 | 제거 | generic transition 면제 규칙은 존속 |

## Topology 대조

| 호출 위치 | 허용 |
|---|---|
| ordinary main session이 Blind를 명시 호출 | 예 |
| ordinary subagent가 Blind를 명시 호출 | 예 |
| Blind가 fresh ordinary reviewer를 호출 | 예 |
| Blind reviewer가 큰 작업에서 ordinary child를 한 단계 호출 | 예 |
| Blind reviewer 또는 child가 ai-harness-toolset skill을 호출 | 아니오 |
| reviewer child가 추가 reviewer를 호출 | 아니오 |

## Independent audit questions

- 기존 계약을 “안전장치”라는 이름으로 다시 붙였는가?
- prompt가 사용자 확정 6줄보다 길어졌는가?
- current repo direct inspection을 bundle 전달로 바꿨는가?
- reviewer가 tests나 mutable 작업을 실행할 수 있는가?
- ordinary subagent의 명시 호출까지 막았는가?
- 반대로 자신이 ai-harness-toolset skill 실행으로 생성된 lineage임을 아는 caller의 skill 재진입을 열어두었는가?
- 결과를 verdict나 pass처럼 표현했는가?
- trace, status table, output template, result artifact를 다시 요구했는가?
- `unavailable`이 실패 원인 한 줄을 넘어 새 상태기계로 자랐는가?

## Absorption and retire

- 방향과 기존 E4 폐기는 Design에 흡수한다.
- 승인 결정은 Plan에 흡수한다.
- durable 최소 계약은 Spec에 흡수한다.
- 실행 mechanics는 SKILL에 흡수한다.
- Backlog의 구계약 확장 row는 제거하고 `next ID`만 유지한다.
- 이 Work Packet은 closeout에서 삭제한다.
