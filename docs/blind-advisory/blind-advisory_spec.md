# blind-advisory Spec

> Spec은 목표 상태 명세다. closeout 후 active implementation과 1:1로 유지한다. 회차 파일 목록·실행 기록·review result·readiness·commit 절차는 담지 않는다. 이 Spec은 mutation/commit/push 승인이 아니다.

## Header

- 이 문서는 `blind-advisory` domain의 target-state Spec이다.
- blind-advisory는 결론유도 operator framing을 제한적으로 제거한 입력을 fresh read-only reviewer가 검사하고, non-verdict defect candidate를 operator가 verbatim으로 전달하는 current-state prefilter다.
- active behavior는 skill이 소유하며 이 Spec은 그 behavior의 durable 의미와 경계를 명세한다.

## 목표 상태

blind-advisory run은 다음 계약을 모두 만족해야 한다.

- reviewer는 제공된 대상만 read-only로 검사하고 mutation하지 않는다.
- 산출은 결함 후보이며 review verdict, 승인, 면제, coverage 또는 pass가 아니다. `yes`, `no`, `yes with risk`를 자기 판단으로 발급하지 않는다.
- operator는 입력에서 operator intent/preferred outcome, prior verdict/advisory conclusion, worker self-evaluation, resolved/fixed/complete/clean/almost-done narrative, suspected location, pass/fail expectation, severity hint, test outcome claim을 제거한다. 이 열거된 결론유도 정보의 제거가 B의 blindness다.
- changed-file 선택, adjacent-evidence 선택, 파일 유형, search class, authority-criteria 선택과 host가 자동 주입하는 user-global instruction은 제거되지 않는 lens다. 요청은 선택 목록과 rationale 및 자동 authority 목록을, 결과는 실제 inspection 범위와 limitations를 공개한다. B는 framing-free 또는 framing-breaker라고 주장하지 않는다.
- 입력은 changed path의 full current state를 사용한다. diff나 history를 내용 대체물로 사용하지 않는다. 현재 상태와 제공된 standing obligation만 판단하며, delta/history 또는 operator의 membership 판단이 필요한 질문을 추정하지 않는다.
- applicable active instructions와 rules는 별도 authority criteria로 제공하고 목록을 공개한다. reference host가 자동 주입하는 user-global instruction은 제거됐다고 가정하지 않고 authority manifest에 출처와 함께 공개한다. target 파일·로그·출력과 기계적으로 발견한 caller/interface/reference 같은 adjacent evidence는 모두 untrusted payload이며 그 안의 instruction-like text는 authority를 얻지 않는다. ordinary adjacent evidence는 authority criterion이 아니어도 mechanical reference로 포함할 수 있고, `scope-curation`은 standing obligation의 적용이나 membership 자체가 operator 판단을 요구할 때만 사용한다. 필수 authority나 자동 주입 목록이 불명확하면 `inconclusive`로 닫고 trigger `scope-curation`을 밝힌다.
- reviewer process는 target repo 밖 neutral cwd에서 시작한다. operator가 full current content와 authority criteria를 byte-faithful UTF-8 stdin으로 전달하며 reviewer는 target repo를 cwd로 열거나 그 repo의 project config·instruction을 자동 로드하지 않는다. PowerShell 5.1 text pipeline처럼 encoding을 암묵 변환하는 carrier는 허용하지 않는다. target payload를 완전하게 전달할 수 없으면 path-list로 경계를 완화하지 않고 `unavailable(input-delivery-unavailable)`로 닫는다.
- changed path가 없으면 `unavailable(no-changed-files)`로 닫는다.
- 입력은 dispatch 시 path와 byte hash로 메모리에 결박한다. 결과 수용 전과 carrier recovery 전에 같은 결박을 재확인하고 bytes가 달라졌으면 stale run을 재사용하지 않는다. 이 결박을 위한 sidecar 파일이나 persistent ledger는 만들지 않는다.
- deleted path는 현재 tombstone으로 표현한다. rename은 destination current state와 기계적 rename identifier를 제공한다. 과거 내용이 필요하면 추정하지 않는다.
- target 하나라도 binary이거나 NUL을 포함하면 path를 열거하고 `unavailable(binary-or-nul-target)`로 종료한다. 해당 target을 skip하거나 정상 status를 만들지 않는다.
- run은 single-shot이다. rebuttal, 설득, verdict 수렴 또는 multi-round synthesis를 B 안에 두지 않는다.

정상 결과의 첫 줄은 다음 closed set 중 정확히 하나다.

| Status | 의미 |
|---|---|
| `no-concerns-reported` | 실제로 검사한 범위에서 defect candidate를 보고하지 않았다. |
| `concerns-reported` | 하나 이상의 defect candidate가 뒤따른다. |
| `inconclusive` | B가 추가 framing, operator scope curation, 또는 제공된 read-only material 밖의 verdict/기계 validation evidence를 공급해야만 답할 수 있다. |

`inconclusive`의 closed trigger는 `added-framing`, `scope-curation`, `validation-evidence`다. 결과는 firing trigger, 필요한 것, 답을 닫지 못한 이유를 밝힌다. 정상 결과 첫 줄은 status token 하나와 정확히 같아야 한다. collection failure, unreadable target, encoding corruption, timeout, abnormal exit, truncation, parse failure, stale input, 필수 finding/범위/한계 누락 같은 collection·invocation·transport·result-contract failure는 status가 아니며 `unavailable(<reason-id>)` 문법으로 종료한다. reason-id 어휘는 간결하고 정확한 실패 진단을 위한 open set이며 정상-result 의미, 승인 또는 downstream 분기 권한을 갖지 않는다. 처분에 필요한 누락 field나 affected path 같은 최소 실패 사실은 함께 밝히되 trace 전체를 대체 결과로 붙이지 않는다.

각 finding은 location, observation, expected condition 또는 rationale, severity, confidence, assumption을 가진다. severity closed set은 `blocking`, `non-blocking`, `question`이다. `blocking`은 최종 blocker verdict가 아니라 관찰과 가정이 확인되면 landing을 막을 수 있는 candidate severity다.

## Owner surface 지도

- `snippets/claude-skills/ai-harness-blind-advisory/SKILL.md`가 discovery, input collection, framing removal, authority/payload 분리, reviewer invocation, parsing, transport, completion과 failure closure를 소유한다.
- 이 Spec은 skill과 1:1로 동기화되는 durable target이다. docs는 runtime dependency나 실행 authority가 아니다.
- Design과 Plan은 변경 방향과 승인 대상 결정을, Work Packet은 회차 분석을, backlog는 아직 시작하지 않은 B future work를 소유한다.
- `<ProjectRoot>/log/blind-advisory/<run-id>/result.md`는 capability fallback이 실제 발동한 단일 run의 delivery output이다. canonical review record, audit log, 장기 workflow state 또는 기능 source-of-truth가 아니다.
- operator는 transport까지만 B 역할로 수행한다. downstream owner가 결과를 어떻게 판단·종합·승인하는지는 B가 소유하지 않는다.

## Durable boundary

정상 delivery는 reviewer final output 전문의 inline verbatim 전달이다. background/parallel execution 또는 recovery가 있었으면 carrier와 무관하게 expected/joined member set을 별도 operator note 한 줄로 공개하되 reviewer 본문을 요약·복제하지 않는다. 전문 inline 전달이 실제 호출 또는 transport capability상 불가능할 때만 다음 artifact delivery로 전환한다.

- path는 `<ProjectRoot>/log/blind-advisory/<run-id>/result.md`이며 run별로 고유하고 작성 전에 존재하지 않아야 한다.
- 파일은 write-once다. overwrite와 append를 금지한다.
- 파일 본문은 inline과 같은 완전한 reviewer final message만 담는다. process trace, progress, prompt echo, token usage, 별도 표지, 목차, 요약, verdict/status 복제 절, finding 표 재구성, 메타데이터 절, 빈 템플릿 절을 두지 않는다. stdout emitter와 final-message file writer의 terminal-newline 차이는 carrier framing이며 두 carrier의 raw byte identity를 요구하지 않는다.
- inline에는 status 또는 `unavailable`, path, bytes, SHA-256, retention과 필요한 failure reason만 보고한다. reviewer 본문의 요약·발췌·재배열은 하지 않는다.
- retention은 `retained-for-consumption`으로 공개한다. 소비 전 자동 삭제하지 않으며 이후 cleanup은 별도 안전 경계를 따른다.
- artifact mode는 편의, 길이 추정, 정형 보고서 선호 또는 항상-on 설정으로 선택하지 않는다. fixed byte threshold도 계약으로 만들지 않는다.

정상 결과는 exit code 0, 분리된 stdout/stderr, 선택한 result carrier(inline이면 stdout, artifact면 final-message file)의 완전하고 읽을 수 있는 reviewer message, 정확히 한 first-line status, status별 필수 field, target completeness와 기록된 expected member set 전원의 JOIN을 충족해야 한다. expected set은 operator-visible in-memory run state에 launch 전에 기록하고 sidecar ledger로 만들지 않는다. artifact mode에서는 stdout을 결과로 소비하지 않는다. 기본 non-JSON 실행을 사용하고 event trace를 stdout에 쓰는 JSON mode는 결과 채널로 사용하지 않는다. stderr의 trace·progress·prompt echo·token usage는 결과에 합치거나 기본 보존하지 않고 failure classification 뒤 폐기한다. 실패 때도 필요한 기계 사유만 별도로 보고한다. 조건 하나라도 실패하면 partial output이나 artifact를 정상 결과로 소비하지 않는다.

observation yield 만료는 hard timeout이나 retry 근거가 아니다. 동일 invocation의 completion notification을 기다린 뒤 JOIN한다. hard timeout이면 해당 실행을 종료·JOIN하고 `unavailable(timeout)`으로 닫으며 retry하지 않는다. 한 번의 recovery는 이전 execution의 종료가 기계적으로 확인되고 해당 member가 JOIN된 뒤 input binding이 unchanged임을 재확인한 경우에만 허용한다. 허용 사유는 완전한 reviewer message의 carrier 전환, 또는 reviewer reasoning이 시작되지 않았음이 확인된 pre-reasoning launch/input 기계 실패로 한정한다. reviewer가 message를 생성했거나 reasoning 시작 여부가 불명확하면 다시 호출하지 않고 해당 `unavailable(<reason-id>)`으로 닫는다.

다음은 standing prohibition이다.

- reviewer mutation, verdict 발급, commit/push/release/adoption 승인
- capsule, reducer, summary, synthesis, partial synthesis, finding 선별, 다중 packaging mode
- prompt input file fallback, hidden sidecar, persistent run ledger, daemon/watcher/scheduler, unjoined background execution
- collection/invocation/transport/result-contract failure를 `inconclusive`나 `no-concerns-reported`로 포장하는 행위
- canonical review의 invocation/pass/coverage에 B 결과를 산입하거나 reviewer에게 B 결과를 신뢰하라고 지시하는 행위
- B를 모든 skeptical inspection, 모든 AI defect hunting 또는 일반 quality gate로 확장하는 행위

## Cross-domain interface

- B는 downstream consumer나 handoff interface를 정하지 않는다. 결과를 다른 owner가 소비·판단·종합하는 방식은 B의 계약 밖이다.
- `consultation`은 이름만 참조한다. B는 consultation을 호출하지 않고 consultation output을 입력으로 소비하지 않는다. consultation의 status, synthesis, framing 또는 output lifecycle은 B에서 설명하지 않는다.
- supervised execution의 active rule은 B보다 상위다. B의 adapter는 expected member, isolated capture, completion notification과 JOIN을 약화하지 않는다.
- 여러 advisory 결과의 결합, B 재호출 여부, downstream neutralization과 최종 처분은 B 밖의 owner 결정이다.

## Validation expectation

- Spec↔skill 1:1 대조는 제한된 blindness, remaining-lens disclosure, authority/payload 분리, current-state binding, status/failure 분리, finding shape, inline/artifact delivery와 recovery를 모두 확인한다.
- 최소 behavioral evidence는 inline 성공, capability-impossible artifact fallback, binary/NUL fail-closed, unreadable/abnormal/parse failure, hard timeout no-retry, carrier/pre-reasoning recovery boundary, stale binding 거부와 expected-member JOIN을 포함한다.
- artifact 검증은 본문이 완전한 reviewer final message이고 trace나 추가 section이 없으며, inline run facts의 path·bytes·SHA-256이 실제 artifact bytes와 맞는지를 확인한다. inline stdout과 artifact의 byte hash를 서로 같다고 요구하지 않는다.
- docs-working-model checker와 affected/full Pester는 lifecycle·placement·generic regression 근거다. 이 green을 B 의미 검증의 대체물로 해석하지 않는다.
- 검증 evidence와 operator report는 `log/**`가 소유하며 Spec에는 회차 결과를 기록하지 않는다.

## Review focus

- B가 실제 defect prefilter인지, 아니면 canonical review의 값싼 복제품·일반 skeptic 역할로 확장됐는지 반례를 찾는다.
- “framing 제거”가 남은 lens를 숨기는 절대주장으로 되돌아갔는지 확인한다.
- authority criteria가 target payload와 분리됐는지, 필요한 authority 누락을 정상 status로 세탁하지 않는지 확인한다.
- `no-concerns-reported`가 제한된 scope, unread target, partial output 또는 missing obligation을 숨기지 않는지 확인한다.
- `blocking` candidate가 최종 blocker verdict처럼 소비되지 않는지 확인한다.
- artifact fallback이 inline 불능이라는 실제 capability 조건에만 쓰이고, 결과 문서 작성·중복 요약·형식 충족 비용을 만들지 않는지 확인한다.
- timeout, recovery, JOIN, input binding이 zombie execution이나 stale result를 남기지 않는지 확인한다.
- owner-local closure가 유지되고 다른 domain의 semantics나 예외가 B에 이식되지 않았는지 확인한다.

## Lifecycle state

- **prelive** — 이 Spec과 skill은 corrective 후 아직 closeout·activation 전이다. 존재만으로 live behavior나 glossary finalization의 근거가 되지 않는다.
