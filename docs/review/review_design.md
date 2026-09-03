# Canonical review packet lens 감산 Design

## Header

이 Design은 canonical dual review의 packet 저작과 결과 소비가 만드는 framing lens를 줄이고, 같은 wave의 결과를 모두 받은 뒤 의미를 소비하도록 F10·F11·F13을 정리하는 review-domain lifecycle 기록이다. 다섯 관측 표본의 사실과 한계를 자족적으로 흡수하며, target-state 의미는 Review Spec이, operator 절차는 배포 review skill과 input template이 소유한다.

완료 상태는 caller 결론·prior verdict·tilt 자기신고를 packet의 방어 장치로 쓰지 않고, 원 evidence·material fact·open question은 보존하며, proven concurrent wave는 모든 member의 terminal accounting 뒤에만 semantic intake하는 것이다. 이 문서는 구현·commit·push·배포 승인이 아니다.

## 왜 바꾸는가 / 무엇을 바꾸는가

Review packet은 target·관점·질문·검사 경로를 선택하므로 중립 evidence가 될 수 없다. 현재 표면은 exact target과 원본 직접 읽기를 요구하는 한편, `Known concerns`에 caller 결론과 previous-verdict pressure까지 넣고 `Review questions`에서 framing tilt 자기신고를 요구한다. 이 두 요구는 회피 가능한 앵커를 packet에 추가하면서도 그 영향을 방어하지 못한다.

반대 방향의 누락도 있다. 현재 semantic intake는 `result.md` 전문만 읽도록 시작하므로, reviewer가 직접 닫지 못한 material open question이 원 `input.md`에만 남은 채 verdict 소비에서 사라질 수 있다. 또한 proven dual의 동시 실행과 complete join은 정하지만 먼저 끝난 member의 result를 언제 읽을지는 정하지 않는다.

따라서 중립성을 보장한다는 주장을 버리고 다음 세 축만 바꾼다.

1. packet에는 검증 가능한 target 사실·material open question·원 evidence 경로를 남기고 caller의 결론·선호안·prior verdict는 correctness 입력에서 뺀다.
2. caller가 이미 작성한 `input.md`와 전체 `result.md`를 함께 semantic intake해 unresolved disclosure가 verdict 뒤에서 사라지지 않게 한다.
3. canary-first와 proven same-wave를 구분하고, same-wave에서는 모든 member가 terminal outcome에 도달하기 전 어느 result도 의미상 소비하지 않는다.

### 표본과 HEAD 원문 대조

| 표본 | HEAD에서 lens 또는 경계를 만드는 현재 표면 | 설계 처분 | 닫히는 부분 / 남는 한계 |
|---|---|---|---|
| S1 — packet 차이만 있는 동일 대상에서 상반된 dual verdict가 관측됨 | 배포 skill `Author input.md`는 caller가 packet 전체를 쓰게 하고, input template의 `Review questions`는 마지막에 framing tilt 자기신고를 요청한다. runner는 그 packet을 reviewer-mode의 완전한 task boundary로 전달한다. | tilt 자기신고 요구와 caller 결론 주입 요구를 감산한다. runner의 task-boundary shield와 repository 직접 검사는 유지한다. | ceremonial self-clearance와 명시적 결론 앵커는 줄지만 target·질문·경로 선택이라는 불가피한 lens는 남는다. 원 paired packet이 없어 flip의 단일 인과나 개선 효능은 확정하지 않는다. |
| S2 — caller가 “의미 보존 direct edit·Spec 불변”으로 선분류한 packet에서 semantic sync 누락이 승인됨 | skill·template·Spec의 `Known concerns`가 confirmed fact·open hypothesis와 caller conclusion·previous-verdict pressure를 한 통로에 싣는다. runner는 관련 repository context 직접 검사를 별도로 요구한다. | 검증된 사실과 material open question은 유지하되 lifecycle·correctness 선분류, 기대 결론, prior verdict는 packet에서 제외한다. prior artifact 자체가 target 또는 required evidence일 때만 exact path로 직접 읽게 하고 verdict를 대리 요약하지 않는다. | caller의 잠정 분류를 review 전제로 승인하는 경로를 줄인다. Reviewer가 applicable owner를 실제로 놓치는 가능성과 target selection lens까지 제거하지는 않는다. |
| S3 — 같은 reviewer session에 근거를 다시 물었을 때 기존 `no`의 failure path가 유지되지 않음 | canonical skill은 same-session resume를 verdict 경로로 두지 않고, prior `no` 보존·후속 pass closure basis·동일 상태 반복 중단을 요구한다. session id는 정보성 provenance다. | 제품 표면을 늘리지 않는다. Resume 답변은 원 verdict를 대체하지 않는 evidence-bound 질의라는 기존 경계를 유지한다. | canonical verdict 덮어쓰기는 계속 금지된다. workflow 밖 수동 resume의 framing은 B5가 구조적으로 닫지 않는다. |
| S4 — packet의 material open hypothesis가 result-only intake와 축약 과정에서 탈락함 | skill의 semantic intake는 clean runner exit 뒤 전체 `result.md`를 읽는 것으로 시작하고 result disclosure만 열거한다. verifier는 result shape만 검사한다. | 같은 intake 문장을 원 `input.md`와 전체 `result.md`를 함께 읽는 의미로 교체한다. 입력의 unresolved material fact/question은 verdict가 닫은 것으로 간주하지 않고 기존 limitation·risk·next-action 보고 안에서 보존한다. | input에서 result로 조용히 사라지는 경로는 줄인다. hypothesis의 참·거짓이나 runtime 관측은 제조하지 않으며 새 parser gate를 만들지 않는다. |
| S5 — 실제 CLI evidence의 원 형태를 직접 제공했을 때 두 reviewer가 concrete failure path를 찾음 | skill·template·runner는 raw report와 off-repo material의 exact path·direct read·no proxy/copy·비-truth-oracle 경계를 소유한다. | 원본 직접 읽기와 provenance 경계를 감산 대상에서 제외한다. Caller narrative가 원 evidence를 대체하지 못하게 하는 기존 경계를 유지한다. | 재서술 과정의 정보 손실은 줄지만 evidence freshness·대표성·target 적용 가능성은 별도 판단으로 남는다. |

Runner의 “complete, self-contained review task” 문구는 packet을 correctness proof로 승격하기 위한 것이 아니라 글로벌 operator 복원 절차가 reviewer run에 오발동하지 않게 하는 reviewer-mode shield다. 같은 preamble이 declared target과 relevant repository context의 직접 검사를 요구하므로 이 문구와 runner/verifier는 이번 감산 대상에서 제외한다.

## F10·F11·F13 결정

### F10 — 중립화가 아니라 회피 가능한 앵커 감산

- `Review questions`의 framing tilt 자기신고 요구를 삭제한다. 자기신고의 존재를 verdict 신뢰 근거로 사용하지 않는다.
- `Known concerns`에 caller conclusion·previous verdict·advocacy pressure를 싣게 하는 요구를 제거한다.
- 불가피한 lens는 새 field가 아니라 기존 `Purpose`, `Perspective`, `Target files`, `Required inspection paths`, open-ended `Review questions`, 의도적 omission 경계로 드러낸다.
- packet이 neutral하다고 주장하지 않고, reviewer의 repository·원 evidence 직접 검사를 그대로 보존한다.

### F11 — 사실 개시와 앵커 회피의 조건부 경계

- Target 판단에 material한 confirmed fact·compromise·validation limitation과 검증 가능한 open question은 숨기지 않는다. 확정 사실을 hypothesis로 약화하지 않는다.
- Caller의 lifecycle/correctness 결론, 기대 verdict, 다른 reviewer의 verdict는 material fact가 아니며 packet에서 제외한다.
- 이전 review artifact 자체가 target contract나 required evidence이면 존재만 알리고 접근을 막지 않는다. Exact path를 required inspection으로 제공해 직접 읽게 하며, caller가 verdict나 결론을 대신 요약하지 않는다.
- “다른 결과의 존재는 개시하되 Constraints로 접근을 차단”하는 패턴은 채택하지 않는다. Load-bearing이면 직접 검사하고, 아니면 correctness packet에 넣지 않는 두 경계만 둔다.

### F13 — terminal join 뒤 semantic consumption

- 이미 검증된 dual pipeline은 고정된 member set을 격리 실행하고 모든 member를 terminal·launch-failed·not-launched 사유까지 accounting한 뒤 result body·H1 verdict를 읽는다.
- Pending member가 있는 동안 먼저 끝난 result를 판정·취소·scope 변경·두 번째 member 해석의 근거로 소비하지 않는다. 실패 member가 있어도 이미 시작한 다른 member를 진행 압력으로 취소하거나 누락하지 않는다.
- Canary-first는 pipeline 변화 자체를 먼저 확인해야 하므로 유일한 선독 예외다. Canary는 same-wave member가 아니며, 그 결과는 remaining unit을 생략하거나 favorable packet으로 고치는 권한이 아니다.
- 이 순서는 operator skill이 소유한다. Runner/verifier에 cross-unit state, sidecar, parser 또는 orchestration을 추가하지 않는다.

## Owner surface model

- `snippets/claude-skills/ai-harness-review/SKILL.md`는 packet admissibility, input+result semantic intake, canary/same-wave consumption 순서와 최종 omission 보고를 소유한다.
- `templates/review-input.md`는 Context·Review questions·Known concerns의 compact 저작 힌트만 소유하며 새 H2나 required field를 만들지 않는다.
- `docs/review/review_spec.md`는 위 의미의 durable target state와 owner 경계를 명세한다. Planning 승인 뒤 target state를 쓸 때 `sync-required`로 전이한다.
- `scripts/review-run.ps1`와 `scripts/review-verify.ps1`는 각각 단일 unit 실행과 shape 검증만 계속 소유하며 이번 구현에서는 바꾸지 않는다.

## 수정 대상

기존 live Review Spec의 input/operator/coverage 의미, 배포 review skill의 packet·semantic intake·parallel join 문단, input template의 Context·Review questions·Known concerns 안내를 수정한다. 이 Design과 Plan은 해당 revision의 committed-temporary lifecycle artifact다.

물리적 문면 감소와 semantic duty 감소를 함께 본다. 새 H2·bullet class·checklist·parser·artifact·caller phase를 만들지 않고, 삭제되는 prior-verdict/tilt 의무 대신 기존 semantic intake가 원 input과 result를 함께 소비하도록 한 문장을 교체한다. Required H2와 placeholder shape는 그대로 둔다.

## 하지 않을 것 (non-goals)

No-retry/no-averaging, verdict 비제조, prior `no` 보존, 사용자 gate, tilt 자기신고의 비방어성은 바꾸지 않는다. `reviewer-version`·`applied-effort`·`reviewer-session-id`·`reviewer-safe-posture` 네 run-fact는 감산하지 않는다.

F14의 machine-required/always/conditional/N/A authoring matrix, required H2·placeholder·verifier shape, 새 checklist나 semantic parser는 산출하지 않는다. Same-session resume contract, multi-reviewer orchestration, automatic join state, dashboard/telemetry, DWM 대폭 개정이나 subtraction-turn, Q-05·Q-07·Q-08·Q-12·Q-13, backup·격리 사본 처분도 포함하지 않는다.

S1의 paired 원문을 재구성할 수 없으므로 controlled paired-packet exercise를 B5 acceptance로 만들지 않는다. 해당 관측이 필요해지면 명시적 consumer와 실패 경로를 둔 별도 read-only evidence goal로 승인받아야 하며, 결과는 verdict나 B5 correctness proof로 소비하지 않는다.

## Plan readiness / open risks

현재 HEAD에서 F10/F11은 skill·input template·Spec, F13은 skill·Spec이 직접 소유하고 runner/verifier에는 semantic owner가 없다. Exact owner와 감산 방향이 식별됐으므로 Plan으로 진행할 수 있으며 Work Packet은 필요하지 않다.

사용자 검토에서 닫을 결정은 다음 네 가지다.

1. Material fact/open question은 유지하되 caller conclusion·prior verdict·advocacy를 packet에서 제외하는가.
2. Tilt 자기신고 요구를 삭제하고 packet neutrality를 주장하지 않는가.
3. Result-only intake를 input+result intake로 교체하고 same-wave terminal join 뒤에만 의미를 소비하는가.
4. Paired-packet exercise는 B5에서 제외하고 S1의 causal attribution을 미확정으로 남기는가.

남는 위험과 영향은 다음과 같다.

- Target·질문·경로 선택 lens는 reviewer의 독립적인 target 해석과 사용자의 gate 판단에서 관련 맥락을 누락시킬 수 있다. Repository와 원 evidence 직접 검사를 유지하되 완전 제거를 주장하지 않는다.
- Caller가 prior artifact의 load-bearing 여부를 잘못 분류하면 reviewer의 required inspection completeness가 실패할 수 있다. Target contract와 required evidence 여부로만 대조한다.
- Caller가 원 input을 다시 읽으며 자기 hypothesis를 사실처럼 과대평가하면 next-action 처분이 왜곡될 수 있다. Hypothesis는 verdict가 닫지 않은 unresolved question으로만 유지한다.
- 먼저 끝난 member에서 blocker가 보여도 same-wave 종료를 기다리므로 operator의 review 완료가 늦어질 수 있다. 이는 fixed coverage와 terminal accounting을 보존하는 운용 비용이며 correctness blocker로 승격하지 않는다.
