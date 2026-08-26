# Reviewer run-banner provenance correction Design

## Header

이 Design은 canonical review 한 번의 공개 run-fact 세트에서 reviewer session pointer·adapter version·applied effort를 함께 관측하도록 W-39의 adapter transport 선택을 바로잡는 review-domain lifecycle 기록이다. target-state 의미는 Review Spec이, 실행 관측과 기록은 runner가 소유한다. 이 문서는 commit·push·배포 승인이 아니다.

## 왜 바꾸는가 / 무엇을 바꾸는가

W-39는 `--json`의 `thread.started.thread_id`를 session pointer source로 선택하면서 기존 run-fact 관측과 양립한다고 전제했다. 그러나 runner-equivalent 실제 CLI 관측에서 `--json`은 stdout을 JSONL event stream으로 바꾸는 동시에 기존 `stderr` run banner를 내보내지 않았다. 그 결과 session pointer는 얻었지만 이미 같은 banner에서 관측하던 `reviewer-version`과 `applied-effort`가 실제 canonical review에서 `not-observed`로 퇴행했다.

W-39의 공개 trace pointer 목표와 hidden-identity/authority 경계는 유지한다. transport만 비-JSON 단일 invocation으로 되돌리고, 같은 `stderr` run banner의 `session id:` line을 기존 version·effort와 함께 읽는다. 관측할 수 없는 값은 각자 `not-observed`로 공개한다.

## Owner surface model

- `scripts/review-run.ps1`은 동일 비-JSON Codex invocation의 완결된 `stderr` banner envelope에서 session id·adapter version·applied effort를 관측하고, 기존 H1 run-fact와 `result.md` provenance에 기록한다.
- `docs/review/review_spec.md`는 세 run-fact의 동일-invocation co-observation과 공개 pointer의 권한 부재를 target state로 명세한다.
- `tests/review-run.Tests.ps1`의 controlled stub은 실제 non-JSON banner shape와 argv 경계를 모사하며, 관측 성공과 `not-observed` 정직성 경로를 검증한다.

## 수정 대상

live Review Spec의 run-fact 공존 의미, `review-run.ps1`의 Codex argv와 banner reader, 해당 동작을 검증하는 기존 runner test를 수정한다. Design/Plan은 이 revision의 committed-temporary lifecycle artifact다.

## 하지 않을 것 (non-goals)

별도 `codex --version` 호출, session-log 탐색, JSONL event parser 유지, sidecar/schema/parser gate, 새 canonical H2·rule, resume status contract, campaign key·권한 token·자동 trigger로의 session id 사용은 도입하지 않는다. reviewer version이나 applied effort run-fact도 제거하지 않는다.

## Plan readiness / open risks

동일 runner posture의 실제 CLI에서 일반 모드 `stderr` banner가 version·reasoning effort·session id를 함께 제공하고, 기존 runner는 stderr/stdout/exit code를 분리 보유한다. 같은 stderr는 닫는 banner separator 뒤에 사용자 prompt도 echo하므로 세 reader는 두 번째 separator까지 확인된 공통 banner envelope만 관측해 prompt decoy를 배제한다. 따라서 추가 process나 persistence 없이 Plan으로 진행할 수 있다. banner field가 관측되지 않거나 banner가 완결되지 않은 경로는 기존 provenance 정직성 관례대로 해당 값을 `not-observed`로 남기며 새 verdict gate로 승격하지 않는다.
