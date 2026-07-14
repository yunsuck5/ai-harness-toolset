# blind-advisory Plan

> Plan은 승인 대상 결정만 담는다. 조사·대조는 Work Packet, 실행 결과는 `log/**`의 operator report가 소유한다. 이 Plan은 mutation/commit/push 승인이 아니다.

## Header

- 이 문서는 아직 closeout되지 않은 `blind-advisory` promoted lifecycle의 corrective Plan이다.
- Design이 정한 제한된 blindness, B-owned delivery fallback, failure closure를 Spec과 skill에 1:1로 반영한다.
- 기존 promotion 단계의 실행 순서나 과거 완료 주장을 승계하지 않는다.

## Batch order and dependency

이번 corrective는 한 owner-local batch이며 별도 batch 사이의 선후 의존은 없다. 제한된 blindness, 입력 fidelity, result transport와 failure closure가 하나의 Spec↔skill 계약이므로 분리하면 중간 상태가 서로 다른 의미를 갖게 되어 단일 batch로 묶는다.

상류 의미가 바뀌면 하류 문서와 skill의 선행 판단은 stale이다. Design 변경은 Plan부터, Plan 변경은 Spec부터, Spec 변경은 skill부터 다시 대조한다.

## Batch definition

- **목적**: B를 결론유도 framing을 제한적으로 제거한 read-only current-state defect-candidate prefilter로 정렬하고, full verbatim 전달이 capability상 불가능한 경우에도 같은 결과를 최소 비용으로 운반한다.
- **대상**: `blind-advisory_design.md`, `blind-advisory_plan.md`, `blind-advisory_spec.md`, `blind-advisory_work_packet.md`, 새 `blind-advisory_backlog.md`, `ai-harness-blind-advisory/SKILL.md`, `docs/README.md`의 prelive backlog route까지 정확히 7개 path다.
- **owner**: active behavior는 B skill, durable target은 B Spec, 회차 판단은 Design/Plan/WP, future work는 B backlog가 소유한다.
- **종료 상태**: 7개 path가 같은 의미를 가지는 uncommitted corrected tree와 검증 근거를 만든다. closeout, live 승격, glossary finalization, activation은 수행하지 않는다.

## Approved decisions

### Identity and input

- blindness는 operator intent/preferred outcome, prior verdict/advisory conclusion, worker self-evaluation, resolved/fixed/complete/clean/almost-done narrative, suspected location, pass/fail expectation, severity hint, test outcome claim을 제거하는 데 한정한다.
- changed-file 선택, adjacent-evidence 선택, 파일 유형, search class, authority-criteria 선택과 host가 자동 주입하는 user-global instruction은 남는 lens다. 요청은 선택 목록과 rationale 및 자동 authority 목록을, 결과는 실제 inspection 범위와 limitations를 공개한다.
- current state와 제공된 standing obligation만 판단한다. delta/history 또는 제공 범위 밖 validation evidence가 필요하면 `inconclusive`의 `validation-evidence` trigger로, operator의 scope-membership 판단이 필요하면 `scope-curation` trigger로 닫는다.
- applicable active instructions/rules는 검토 대상 payload와 분리한 authority criteria로 제공하며 목록을 공개한다. reference host가 자동 주입하는 user-global instruction도 제거됐다고 가정하지 않고 authority manifest에 출처와 함께 공개한다. 필수 authority 선택이나 자동 주입 목록이 불명확하면 누락하지 않고 `inconclusive`로 닫으며 `scope-curation` trigger를 밝힌다.
- 기계적으로 발견한 caller/interface/reference는 authority가 아닌 disclosed adjacent evidence로 포함할 수 있다. `scope-curation`은 ordinary evidence 탐색이 아니라 standing obligation의 적용 또는 target membership 자체가 operator 판단을 요구할 때만 사용한다.
- reviewer는 target repo 밖 neutral cwd에서 시작하며, operator가 full current content와 authority criteria를 byte-faithful UTF-8 stdin으로 전달한다. reviewer가 target repo를 cwd로 열거나 그 repo의 project config·instruction을 자동 로드하는 path-list posture는 사용하지 않는다. PowerShell 5.1의 text pipeline처럼 encoding을 암묵 변환하는 carrier는 허용하지 않는다.
- changed path가 없으면 `unavailable(no-changed-files)`로 닫는다.
- 입력은 dispatch 시 path와 byte hash로 메모리에 결박한다. 결과 수용 전과 carrier recovery 전에 다시 확인하며 변경됐으면 동일 run을 재사용하지 않는다.
- deleted path는 현재 tombstone으로, rename은 destination의 현재 내용과 기계적 rename 식별자로 표현한다. 과거 내용이 필요하면 추정하지 않는다.
- binary 또는 NUL target이 하나라도 있으면 대상 path를 열거하고 `unavailable(binary-or-nul-target)`로 닫는다. skip이나 일반 status는 금지한다.

### Result and transport

- 정상 기본은 reviewer output 전문의 inline verbatim 전달이다.
- background/parallel execution 또는 recovery가 있었으면 carrier와 무관하게 expected/joined member set을 별도 operator note 한 줄로 공개한다. 이 note는 reviewer 본문을 요약하거나 복제하지 않는다.
- 전문 inline 전달이 실제 capability상 불가능할 때만 `<ProjectRoot>/log/blind-advisory/<run-id>/result.md`를 사용한다. path는 run별 고유하고 사전에 없어야 하며 overwrite·append하지 않는다.
- `result.md` 본문은 inline과 같은 완전한 reviewer final message만 담는다. 표지·목차·요약·메타데이터 절·status 복제·finding 재구성·빈 템플릿 절을 만들지 않는다. stdout emitter와 final-message file writer가 terminal newline을 다르게 표현할 수 있으므로 carrier 간 raw byte identity를 요구하지 않는다.
- artifact mode는 final-message 전용 출력을 파일에 쓰며 process transcript를 보존하지 않는다. inline 보고는 `status` 또는 `unavailable`, path, bytes, SHA-256, retention, failure reason이 필요한 경우의 그 사유만 담는다. reviewer 내용이나 trace를 요약·복제하지 않는다.
- artifact는 전달을 위해 `retained-for-consumption`으로 명시한다. 소비 전 자동 삭제하지 않으며, 이후 정리는 별도 안전 경계를 따른다.
- capsule, reducer, synthesis, partial result, 여러 packaging 양식, shared result schema/helper는 도입하지 않는다.

### Result validity and findings

- status closed set은 `no-concerns-reported`, `concerns-reported`, `inconclusive`다. `inconclusive` trigger closed set은 `added-framing`, `scope-curation`, `validation-evidence`다. 정상 결과 첫 줄은 status token 하나와 정확히 같아야 한다. collection·invocation·transport·result-contract failure는 status가 아니며 `unavailable(<reason-id>)` 문법으로 닫는다. reason-id 어휘는 간결하고 정확한 실패 진단을 위한 open set이며 정상-result 의미, 승인 또는 downstream 분기 권한을 만들지 않는다. 응답 구성 실패처럼 처분에 필요한 경우에는 누락 field 같은 최소 실패 사실을 함께 밝힌다.
- severity closed set은 `blocking`, `non-blocking`, `question`이다.
- 정상 결과는 exit code 0, stdout/stderr 분리, 선택한 result carrier(inline이면 stdout, artifact면 final-message file)의 완전한 message, 첫 줄의 정확히 한 status, 필수 field, 대상 completeness, 모든 member JOIN을 모두 만족해야 한다. artifact mode에서는 stdout을 결과로 소비하지 않는다. stderr trace·progress는 결과에 합치거나 기본 보존하지 않고 failure classification 뒤 폐기하며, `--json` event stream도 결과 채널로 쓰지 않는다.
- finding은 location, observation, expected condition 또는 rationale, severity, confidence, assumption을 가진다.
- `blocking`은 최종 verdict가 아니다. 관찰과 가정이 확인되면 landing을 막을 수 있는 candidate severity다.
- `no-concerns-reported`는 실제 inspection 범위와 limitations를 동반하며, collection/invocation/transport/result-contract failure나 불충분한 입력을 숨기지 않는다.

### Completion and recovery

- observation yield 만료는 hard timeout도 retry 근거도 아니다. 동일 invocation의 completion notification을 기다리고 JOIN한다.
- hard timeout이면 기존 실행을 종료하고 JOIN한 뒤 `unavailable(timeout)`으로 닫는다. timeout은 retry를 허가하지 않는다.
- launch 전에 expected member set을 operator-visible in-memory run state에 기록하고, recovery member는 launch 전에 추가한다. 각 member의 isolated output과 JOIN을 확인하며 sidecar ledger는 만들지 않는다.
- recovery는 이전 execution의 종료가 기계적으로 확인되고 해당 member가 JOIN된 뒤 input binding이 unchanged임을 재확인한 경우에만 한 번 허용한다. 허용 사유는 이미 확보한 완전한 reviewer message의 carrier 전환, 또는 reviewer reasoning이 시작되지 않았음이 확인된 pre-reasoning launch/input 기계 실패로 한정한다.
- reviewer가 message를 생성했거나 reasoning 시작 여부가 불명확하면 다시 호출하지 않는다. parse failure, unexpected truncation, abnormal completion은 해당 `unavailable(<reason-id>)`으로 닫는다.
- background member, 부분 stdout, stale input, 읽지 못한 target을 정상 status로 포장하지 않는다.

## Hard boundary

- canonical review verdict·coverage·pass를 발급하거나 대체하지 않는다.
- `consultation`은 이름만 언급하고, B가 consultation을 호출하지 않으며 그 output을 소비하지 않는다는 negative boundary만 둔다.
- 다른 advisory의 synthesis/recovery/status/session 의미, 다른 lifecycle의 promoted-state 의미, wholesale upstream patch, instruction trigger 변경, shared helper/rule, glossary, activation, Brief/handoff 또는 closeout을 포함하지 않는다.
- prompt file fallback, artifact always-on, output 템플릿, fixed response-size threshold, timeout 상승, 반복 설득 loop를 만들지 않는다.
- staging, commit, push, install, global/user mutation은 사용자 별도 승인 전 금지한다.

## Validation and review focus

- 문서 checklist와 docs-working-model checker로 lifecycle shape·placement·backlog next ID를 확인한다.
- Spec↔skill 1:1 대조, closed status/severity, authority/payload 분리, input binding, binary/deleted/rename, inline/artifact, timeout/recovery를 수동·독립 감사한다.
- fresh dogfood는 최소 inline 성공, artifact fallback, binary/NUL fail-closed, timeout/abnormal/parse failure, stale binding, expected-member JOIN을 대상으로 한다. 결과 파일을 만들기 위한 형식 작업이 dogfood의 주목적이 되어서는 안 된다.
- affected Pester와 full Pester는 generic regression 근거이며 B 의미 검증을 대신하지 않는다.
- canonical review는 relay supervisor의 corrected-tree cross-check 뒤 fresh input으로 수행한다. 과거 review는 현재 결합 후보에 사용하지 않는다.

## Work Packet declaration

Work Packet이 필요하다. 이번 회차의 gap matrix, decision→surface mapping, failure-path 대조, 반례·오탐 질문을 보유한다. identity/direction은 Design, 승인 대상 결정은 Plan, standing contract는 Spec, mechanics는 skill, future work는 backlog로 흡수한다. 실행 명령, 실행 결과, readiness, commit 절차는 담지 않으며 위 흡수 확인 뒤 closeout에서 retire한다.

## Stage rewind

- Plan이 Design을 위반하면 Design을 재설계하고 Plan을 재시작한다.
- Spec이 Plan을 위반하면 Spec을 재작성한다.
- skill이 Spec을 위반하면 구현과 이후 검증을 stale 처리한다.
- owner 밖 수정이 필요해지면 확장하지 않고 별도 unit으로 보고한다.
