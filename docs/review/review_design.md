# Reviewer session trace pointer Design

## Header

이 Design은 canonical `result.md`에서 그 verdict를 만든 reviewer session을 필요할 때 되짚을 수 있게 하는 review-domain lifecycle 기록이다. target-state 의미는 Review Spec이, 실행 관측과 기록은 runner가 소유한다. 이 문서는 commit·push·배포 승인이 아니다.

## 왜 바꾸는가 / 무엇을 바꾸는가

현행 provenance는 reviewer·model·effort·engine 경로를 남기지만 reviewer session pointer는 남기지 않는다. 따라서 verdict가 부조리하거나 `result.md`의 근거가 부족해도 결과만으로 정확한 reviewer session을 찾을 수 없다.

같은 reviewer invocation에서 관측한 session id를 기존 provenance 안에 공개·정보성 trace pointer로 기록한다. 사용자는 필요할 때 이 값을 수동으로 소비할 수 있고, 평상시 review 흐름에는 자동 후속 행동을 추가하지 않는다.

## Owner surface model

- `scripts/review-run.ps1`은 같은 Codex invocation의 machine event에서 session id를 관측하고, 기존 H1 run-fact와 `result.md` provenance에 `reviewer-session-id`로 기록한다.
- `docs/review/review_spec.md`는 공개 pointer의 목적·권한 부재·기존 identity 금지 경계와의 관계를 target state로 명세한다.
- 기존 canonical pass의 보존·write-once·retention 경계가 pointer의 lifecycle도 함께 소유한다. 별도 저장소나 identity owner를 만들지 않는다.

## 수정 대상

live Review Spec의 result/provenance 및 hidden identity 경계, `review-run.ps1`의 Codex invocation·provenance run-fact, 해당 동작을 검증하는 기존 runner test를 수정한다.

## 하지 않을 것 (non-goals)

resume 결과의 parent pass·source seal·stale/fresh·confirmatory/non-canonical 지위는 정의하지 않는다. 자동 resume/fork, verdict 기반 후속 trigger, session-log 탐색, sidecar, 새 canonical H2·parser gate·schema·rule, campaign key나 권한 token으로의 session id 사용은 도입하지 않는다. 실제 유료 reviewer 호출을 사실 확인용으로 추가하지 않는다.

## Plan readiness / open risks

Codex의 동일 invocation JSONL event가 session id를 제공하고 기존 runner가 stdout/stderr/exit code를 분리해 보유하므로 Plan으로 진행할 수 있다. event가 관측되지 않는 비정상 경로는 기존 provenance 정직성 관례대로 `not-observed`로 공개하고 새 verdict gate로 승격하지 않는다. 이 선택과 공개 metadata가 `hidden session identity`에 해당하지 않는다는 경계는 Spec에서 닫는다.
