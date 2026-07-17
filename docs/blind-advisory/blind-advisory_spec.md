# blind-advisory Spec

> Spec은 목표 상태 명세다. active behavior는 skill이 소유하며, closeout 후 둘은 1:1로 유지된다. 이 Spec은 mutation·commit·push 승인이 아니다.

## Header

- blind-advisory는 사용자가 명시 호출하는 경량 defect-candidate prefilter다.
- 체인 종료 상태는 새 최소 계약과 source skill의 1:1 정렬, 구계약 전용 결박 제거, 검증 전 `prelive`다.
- canonical verdict, consultation synthesis, mutable 검증 또는 일반 협업 규칙이 아니다.

## 목표 상태

- 사용자 또는 ordinary caller가 skill 실행을 명시적으로 요청한 경우에만 실행한다. 이름 인용·설명·검토와 ordinary/fresh/independent/generic blind review 문구는 invocation이 아니다.
- fresh reviewer는 current repo에 직접 위치하고 repo 상태와 적용되는 instruction을 스스로 읽는다. full-content bundle, authority manifest, hash inventory를 받지 않는다.
- reviewer prompt는 다음 정보만 담는다: 실제 검토 범위가 들어간 read-only 정적 검토, 파일 변경·테스트 실행·ai-harness-toolset skill 사용 금지, 작업 목적, 현재 위치, 위치와 이유가 붙은 결함 후보 요청.
- 사용자 지정 scope가 없으면 검토를 diff-only나 selected-file-only로 축소하지 않는다.
- 기본은 reviewer 한 명이다. 작업량이 클 때만 같은 경계를 받은 ordinary read-only child reviewer를 한 단계 사용할 수 있으며 child는 추가 위임하지 않는다.
- reviewer와 그 child가 모두 끝나거나 명시적으로 중단된 뒤 결과를 받는다.
- main session과 ordinary subagent는 Blind를 명시 호출할 수 있다. current caller가 자신이 ai-harness-toolset skill 실행으로 생성된 lineage임을 알고 있으면 reviewer를 시작하지 않고 `unavailable(<짧은 실제 사유>)`로 닫는다.
- reviewer final message를 요약·선별·재구성하지 않고 그대로 반환한다.
- reviewer는 host의 final-message-only/no-trace 결과 경로로만 호출한다. 해당 경로를 사용할 수 없으면 reviewer를 시작하지 않고 `unavailable(output-isolation-unavailable)`로 닫는다. skill 전용 result artifact는 만들지 않는다.
- reviewer final message를 얻지 못하거나 금지된 변경·테스트·toolset 재호출이 호스트나 호출자에게 관측되면 `unavailable(<짧은 실제 사유>)`를 반환한다.

## Owner surface 지도

- `snippets/claude-skills/ai-harness-blind-advisory/SKILL.md`가 explicit trigger, 최소 prompt, fresh reviewer 호출, one-layer topology, 원응답 반환과 failure closure를 소유한다.
- 이 Spec은 durable 의미와 경계를 소유하지만 runtime dependency가 아니다.
- Design과 Plan은 변경 방향과 승인 결정을, Work Packet은 이번 회차 분석을, Backlog는 아직 시작하지 않은 future work를 소유한다.
- vendor별 설치·업데이트·제거와 global mirror는 install-update owner의 범위다.

## Durable boundary

허용:

- current repo의 read-only 정적 inspection
- 실제 검토 범위가 들어간 read-only 정적 검토, 파일 변경·테스트 실행·ai-harness-toolset skill 사용 금지, 작업 목적, 현재 위치, 위치와 이유가 붙은 결함 후보 요청만 담는 최소 prompt
- 단일 fresh reviewer와 조건부 one-layer ordinary fan-out
- 위치·이유가 붙은 결함 후보
- 짧은 `unavailable(<짧은 실제 사유>)`

금지:

- 파일 변경, 테스트 실행, stage·commit·push·activation
- 자신이 ai-harness-toolset skill 실행으로 생성된 lineage임을 아는 caller의 skill 재호출과 reviewer child의 추가 fan-out
- 이전 verdict, worker self-report, 예상 finding, test 결과를 reviewer framing으로 주입
- neutral cwd용 full-content packaging, authority manifest, byte/hash binding
- closed status·severity·finding schema, result template, trace 보존, 중복 요약
- retry·recovery·retention을 Blind 고유 상태기계로 만드는 것
- canonical verdict나 consultation synthesis를 대체하는 것

## Cross-domain interface

- canonical review는 Blind 결과와 별개의 권위·절차를 가진다. Blind는 canonical pass 가능성이나 coverage를 주장하지 않는다.
- consultation, Brief, review skill을 호출하거나 그 결과를 Blind 입력으로 소비하지 않는다.
- ordinary main/subagent의 명시 호출은 허용하지만, 자신이 ai-harness-toolset skill 실행으로 생성된 lineage임을 아는 caller는 다른 ai-harness-toolset workflow로 재진입하지 않는다.
- Blind는 반환한 원응답의 소비·판단·후속 조치를 규정하지 않는다.

## Validation expectation

- Design·Plan·Spec·SKILL의 문장 대조로 최소 계약이 1:1인지 확인한다.
- skill frontmatter가 explicit invocation만 허용하고 일반 review 문구를 배제하는지 확인한다.
- 기본 prompt가 빈 줄을 포함해 6줄이고 대규모 조건부 fan-out이 한 줄만 추가되는지 확인한다.
- current repo direct review, no mutation, no tests, no toolset recursion, child no-fan-out을 확인한다.
- 기존 authority/status/transport machinery가 current surface에 남지 않았는지 확인한다.
- 구조 checker와 repo 밖 공식 skill-creator의 `quick_validate.py`(또는 동등 정적 검사) 통과는 보조 근거이며, 경량성·호출 경계의 수동 검토를 대체하지 않는다.

## Review focus

- skill이 경량 prefilter를 넘어 기존 authority/status/transport machinery를 다시 도입했는가?
- prompt에 목적·위치 외 narrative나 schema가 다시 붙었는가?
- explicit-only 문구가 ordinary review를 다시 가로채는가?
- fresh reviewer가 current repo 대신 operator가 고른 bundle만 보는가?
- 정적 리뷰인데 테스트나 mutable tool을 실행할 여지가 있는가?
- fan-out이 한 단계를 넘거나 toolset skill 재귀를 허용하는가?
- reviewer final message를 선별·요약·재구성하는 후처리가 생겼는가?
- `unavailable`이 reason catalog나 복잡한 recovery branch로 다시 자라는가?

## Lifecycle state

- **prelive** — 새 최소 계약과 source skill은 아직 검증·closeout·global activation 전이다.
