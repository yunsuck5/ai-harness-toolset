# blind-advisory Design

> Design은 변경의 방향성 문서다. 영구 live 문서가 아니며, closeout에서 current-bearing 내용이 Spec 또는 올바른 owner surface로 흡수된 뒤 retire한다. 이 Design은 mutation/commit/push 승인이 아니다.

## Header

- 이 문서 = 아직 closeout되지 않은 `blind-advisory` promoted lifecycle을 현재 규칙과 실제 transport 한계에 맞추는 corrective Design이다.
- 이 체인이 끝나면 = 결론유도 framing을 제한적으로 제거한 current-state defect prefilter와, capability 실패에서도 verbatim 전달을 보존하는 B-owned delivery 경계가 Spec과 skill에 1:1로 정렬된다.
- 이 문서가 아닌 것 = canonical verdict 절차·일반 AI 협업 규칙·다른 advisory domain의 의미·실행 기록이 아니다.

## 왜 바꾸는가 / 무엇을 바꾸는가

- **원래 문제.** operator의 완료·해결·검증통과 주장에 기대지 않고 현재 변경 상태에서 결함 후보를 조기에 찾으며, 결과를 승인 효과 없이 verbatim으로 전달하는 단일 owner가 필요하다. 이 활동을 verdict gate나 일반 skeptical review로 흡수하면 권한과 산출 경계가 흐려진다.
- **현재 정체성 결함.** 현 Design·Spec·skill은 “모든 framing 제거”를 주장하지만 실제 입력은 변경 파일 선택, 인접 surface 포함, 파일 유형과 search class라는 lens를 가진다. framing이 0이라는 절대주장은 input contract 및 “framing-breaker가 아니다”라는 자기 한계와 양립하지 않는다.
- **현재 transport 결함.** transporter는 full verbatim 전달을 약속하지만, 현 skill은 Codex의 최종 message와 trace/progress를 분리하지 않은 채 대형 응답 transcript를 다른 domain의 선례에 기대고, inline 반환이 불가능할 때의 canonical 위치·무변형성·완전성·retention을 B 스스로 닫지 않는다. 동시에 timeout 때 observation window를 늘리는 문구가 supervised JOIN 규칙과 충돌하고, binary/NUL target은 full-current-state 계약 아래 처리 분기가 없다.
- **방향 결정.** blind-advisory의 blindness는 **열거된 operator 결론·stance framing을 제거하는 제한된 blindness**다. 제거 목록은 operator intent/preferred outcome, prior verdict/advisory conclusion, worker self-evaluation, resolved/fixed/complete/clean/almost-done narrative, suspected location, pass/fail expectation, severity hint, test outcome claim이다. 남는 mechanical lens, target·adjacent-evidence selection, authority-criteria selection과 실제 inspection 범위는 숨기지 않는다. reviewer는 현재 상태만으로 확인 가능한 결함과 standing obligation만 판단하고, delta/history 또는 operator 판단이 필요한 지점은 추정하지 않는다.
- **authority/payload 결정.** applicable active instructions와 rules는 reviewer의 판단 기준으로 별도 제공하고 그 목록을 공개한다. 검토 대상 파일·로그·출력과 기계적으로 발견한 caller/interface/reference 같은 adjacent evidence는 untrusted payload다. reviewer process는 target repo 밖의 neutral cwd에서 시작하고 full current content를 stdin으로 받아 target repo의 project config·instruction loading을 target selection과 분리한다. reference Codex host가 자동 주입하는 user-global instruction은 제거됐다고 주장하지 않고, 남는 authority lens로 식별·목록화한다. 이 격리를 “authority가 없다”는 뜻으로 사용하지 않는다.
- **delivery 결정.** full verbatim inline 전달이 기본이다. Codex 기본 non-JSON 실행에서 최종 message인 stdout만 결과로 소비하고, stderr의 trace·progress·prompt echo·token usage는 결과에서 제외한다. 실제 호출/transport capability 때문에 전문 inline 반환이 불가능할 때만 final-message 전용 출력을 B-owned `log/blind-advisory/<run-id>/result.md`에 write-once로 두고, inline에는 run facts만 전달한다. artifact는 capsule·reducer·summary나 전체 process transcript가 아니라 reviewer final message 자체다. `result.md`에는 별도 표지·목차·요약·메타데이터 절·status 복제·finding 재배열을 두지 않는다. 즉 템플릿을 채우는 문서가 아니라, inline으로 보냈을 같은 완전한 message를 한 번 담는 최소 전달면이다. stdout emitter와 file writer의 terminal-newline 차이는 carrier framing으로 공개하며 두 carrier의 raw byte identity를 주장하지 않는다. background/parallel execution 또는 recovery가 있었으면 carrier와 무관하게 expected/joined member set을 별도 operator note 한 줄로 공개한다.
- **단일 닻.** 범위는 current changed-state defect-candidate prefilter다. “모든 skeptical review”, 합의 독립성 검사 일반, 모든 AI 결함 탐색, quality gate 일반으로 넓히지 않는다.

이 작업의 타당성은 합의의 강도가 아니라 위 세 결함이 current owner surface에서 직접 재현되는지로 판단했다. strict no-file 문구를 그대로 두면 capability 실패에서 verbatim 약속과 충돌하고, artifact를 항상 쓰거나 요약을 도입하면 transporter 정체성이 무너진다. 따라서 owner-local한 단일 fallback과 framing 절대주장 축소가 가장 좁은 교정이다.

## Owner surface model

- **정규 owner surface는 skill이다.** 대상 수집, 결론유도 framing 제거, mechanical lens·target/adjacent-evidence/authority-criteria selection 공개, reviewer 호출, status/finding parsing, verbatim delivery, artifact fallback, failure termination을 소유한다.
- **Design/Spec은 의미와 durable boundary를 정한다.** active behavior는 skill이 소유하고 문서는 이를 명세·대조한다.
- **supervised execution rule은 실행 class를 제한한다.** launch 전 operator-visible in-memory expected member set, isolated output, completion notification, 전원 JOIN이라는 상위 조건을 B가 약화하지 않는다. background/parallel execution 또는 recovery가 있었으면 expected/joined set을 carrier 밖의 한 줄 note로 공개한다. sidecar ledger는 만들지 않으며 timeout은 완료나 retry 권한이 아니다.
- **artifact는 B run의 목적별 output이다.** path·write-once·무변형·완전성·retention 공개는 B가 소유한다. 파일 본문은 reviewer 원문 외의 구조를 갖지 않으며, path·bytes·hash·retention·failure 같은 실행 사실은 파일 밖 인라인 보고에만 둔다. shared schema/helper/registry나 다른 domain의 output mode를 도입하지 않는다.
- **transport와 downstream 사용은 분리된다.** B는 자기 결과를 verbatim으로 전달하는 데서 끝난다. 다른 owner가 그 결과를 어떻게 소비하는지는 B가 현재 계약으로 가정하거나 재서술하지 않는다.
- **cross-domain 관계는 name-only negative boundary다.** `consultation`을 호출하지 않고 그 산출을 입력으로 소비하지 않는다는 B 자신의 경계만 남긴다.

## 수정 대상

- 동일 promoted lifecycle의 `blind-advisory_design.md`를 현재 semantic target에 맞춘다.
- 기존 promotion Plan을 현재 corrective의 승인 대상 결정으로 재시작한다.
- `blind-advisory_spec.md`와 repo source `ai-harness-blind-advisory/SKILL.md`를 1:1로 갱신한다.
- round-scoped 분석은 `blind-advisory_work_packet.md`로 교체한다.
- 첫 실제 future-work item과 함께 `blind-advisory_backlog.md`를 생성하고, `docs/README.md`에는 prelive backlog route만 추가한다.

## 하지 않을 것 (non-goals)

- canonical review verdict·coverage·pass를 발급하거나 대체하지 않는다.
- `consultation`의 동작원리, status, synthesis, output lifecycle을 설명하거나 이식하지 않는다.
- capsule, reducer, summary, partial synthesis, 다중 packaging mode, shared helper/schema/registry를 만들지 않는다.
- prompt input file fallback을 새로 만들지 않는다. reference adapter의 prompt는 stdin으로 전달하며, 안전한 stdin delivery가 불가능하면 기계 실패로 닫는다.
- artifact fallback을 편의상·항상-on으로 사용하지 않는다. full inline verbatim이 실제 capability상 불가능하다는 조건에만 결박한다.
- retry 수를 늘리거나 timeout을 retry/완료 근거로 쓰지 않는다. background member를 남긴 채 결과를 반환하지 않는다.
- downstream interface 신설, 다른 owner surface 수정, global activation, install/update, instruction-trigger 변경, shared rule/helper, glossary, Brief/handoff 또는 closeout 작업을 포함하지 않는다.
- blind-at-close scope 확장과 framing-governance 일반화는 이번 semantic target에 흡수하지 않는다.

## E4 absorption — 계속 보존되는 결정과 이번 corrective

- **adopted conclusion**: read-only current-state defect prefilter · non-verdict status · operator=transporter · single-shot · untrusted payload · 정상 result가 성립하지 않는 run/result-validation failure와 `inconclusive` 분리를 유지한다. status closed set은 `no-concerns-reported` / `concerns-reported` / `inconclusive`, `inconclusive` trigger closed set은 `added-framing` / `scope-curation` / `validation-evidence`, severity closed set은 `blocking` / `non-blocking` / `question`이다. collection·invocation·transport·result-contract failure는 `unavailable(<reason-id>)` 문법으로 닫되 reason-id 어휘는 진단 정확성을 위한 open set이며 승인·정상-result 분기 의미를 갖지 않는다. changed path가 없으면 `unavailable(no-changed-files)`로 닫는다. finding은 location/observation/expected condition 또는 rationale/severity/confidence/assumption을 가진다. `blocking`은 최종 blocker 판정이 아니라 관찰과 가정이 확인될 때 landing을 막을 수 있는 defect candidate severity다. 이번 corrective는 blindness를 위 방향 결정의 열거 목록으로 한정하고, remaining lens·selection rationale·actual coverage 공개를 추가한다. delivery는 inline-default이며 capability-impossible일 때만 purpose-isolated raw-result artifact로 전환한다.
- **rejected alternatives**: `clear`/`issues-found` status · collection/invocation/transport/result-contract failure를 `inconclusive`로 추정 · multi-round rebuttal loop · strict no-file을 유지하며 transcript를 숨기거나 절단 · artifact always-on · capsule/reducer/synthesis · timeout 상승 또는 미종료 실행과 병행한 retry · binary/NUL silent skip · 다른 domain의 semantics나 output modes를 B의 근거로 삼는 방식을 채택하지 않는다.
- **judgment-changing evidence type**: target 선택 자체가 lens라는 반례, current-state-only 입력으로 delta-trigger를 항상 판별할 수 없다는 반례, 대형 reviewer output의 inline 전문 반환 실패, 현 timeout 문구와 active JOIN rule의 직접 충돌, 비텍스트 target에서 full-current-state 계약이 성립하지 않는 사례다.
- **scope**: B의 planning artifacts, source skill, B backlog와 prelive route로 닫힌 owner-local corrective다.
- **failure/discard criteria**: 결론유도 framing을 다시 넣어야만 유용함 · 결과가 승인 신호로 소비됨 · operator가 요약/선별해야만 전달 가능함 · raw artifact가 기능 source-of-truth 또는 장기 hidden state로 변함 · owner-local하게 닫히지 않고 다른 domain 예외를 요구함 · false positive 비용이 조기 발견 가치를 지속적으로 초과함.
- **known negative evidence**: B는 framing-free나 framing-breaker가 아니다. target·adjacent-evidence·authority-criteria selection과 search class가 만드는 lens를 없애지 못한다. current state만으로 obligation membership을 결정할 수 없는 경우가 있으며 그때는 status를 억지로 만들지 않는다. applicable authority를 operator가 누락할 위험도 남으므로 제공 목록과 limitations를 공개한다. artifact fallback의 실제 필요 빈도와 retention 비용은 아직 운용 측정이 부족하다.

## Plan readiness / open risks

- **Plan으로 진행 가능하다.** 현재 결함은 B owner surface 안에서 재현되고 semantic target은 좁게 닫힌다.
- Plan은 authority/payload/adjacent-evidence 분리, 자동 user-global authority 공개, neutral-cwd byte-faithful stdin delivery, current-state input binding, evidence-bearing finding shape, artifact fallback 조건·run-fact set·retention disclosure, expected-member 기록/JOIN, carrier 또는 proven pre-reasoning failure에 한정한 1회 recovery와 binary/NUL branch를 승인 대상 결정으로 고정한다.
- Spec은 target set, adjacent-evidence/authority-criteria selection·remaining-lens disclosure, status/failure branch, raw-result validity와 delivery semantics를 durable normative 문장으로 소유한다.
- skill은 stdin delivery, prompt shape, artifact mechanics, parse/transport, failure handling을 구현한다.
- artifact retention 비용과 실제 fallback 빈도는 blocker가 아니다. 기능을 일반화하지 않고 관측 가능한 run facts로 남기며, 반복 사용이나 cleanup burden이 관측될 때만 backlog 조건으로 재개한다.

## Future-work pointer

현재 시작하지 않는 blind-advisory 소유 future work의 단일 home은 `blind-advisory_backlog.md`다. 이 Design은 backlog ID나 item 문구를 복제하지 않는다. cross-domain framing governance와 다른 owner의 interface 도입 여부는 B backlog가 소유하지 않는다.
