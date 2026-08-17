# Review external direct-read fallback Design

## Header

이 Design은 reviewer가 외부 load-bearing target을 직접 읽을 때 첫 read/list 거부를 곧바로 접근 불가로 오판하지 않도록 하는 최소 fallback 의미를 소유한다. 결과 상태는 target별로 더 단순한 direct read/list를 한 번 확인한 뒤에만 기존 review-unavailable 경계를 적용하는 것이다. 이 문서는 mutation·commit·push 승인이 아니다.

## 왜 바꾸는가 / 무엇을 바꾸는가

현행 runner preamble은 load-bearing target의 직접 읽기와 접근 실패 시 no-verdict 처분을 지시하지만, reviewer가 선택한 read/list 형태가 실행 계층에서 거부된 경우와 target 자체가 inaccessible인 경우를 구분하지 않는다. 이를 특정 policy 문자열·exit-code·도구별 예외로 분류하지 않고, 각 load-bearing target의 첫 read/list 거부는 inconclusive로 두며 더 단순한 direct read/list를 정확히 한 번 시도하는 일반 절차로 바꾼다.

## Owner surface model

- `scripts/review-run.ps1`의 reviewer preamble은 실제 reviewer에게 전달되는 fallback instruction을 소유한다.
- `docs/review/review_spec.md`는 active surface와 대조되는 target-state 의미와 validation expectation을 기록한다.
- `tests/review-run.Tests.ps1`의 기존 external-path integration case는 새 instruction이 reviewer stdin에 전달되는지를 검증한다. 실제 reviewer 준수나 fallback 발동을 기계적으로 증명하지 않는다.
- Review SKILL과 input/result template은 기존 target 선언·direct-read·review-unavailable 계약이 그대로 참이므로 변경하지 않는다.

## 수정 대상

후보는 Review lifecycle 3경로와 active 2경로, 총 5경로다: `docs/review/review_design.md`, `docs/review/review_plan.md`, `docs/review/review_spec.md`, `scripts/review-run.ps1`, `tests/review-run.Tests.ps1`.

## 하지 않을 것 (non-goals)

- policy rule ID·vendor 문자열·exit-code 형태·명령 이름별 예외를 규칙으로 만들지 않는다.
- 권한 profile·외부 경로 parameter·runner logging·SKILL·template·parser·schema·H2·test case를 추가하거나 바꾸지 않는다.
- 모든 declared target이나 이미 성공한 target을 재시도하지 않고 load-bearing target의 첫 거부만 한 번 확인한다.
- 합성 rejection, 자동 retry loop, selected-path confinement·permission 보증, 추가 evidence artifact를 만들지 않는다.
- commit·push·배포·lifecycle closeout을 이 후보에서 수행하지 않는다.

## Plan readiness / open risks

방향 결정은 닫혔다. 첫 read/list 거부의 원인을 분류하지 않고 inconclusive로 두며, 각 load-bearing target에 더 단순한 direct read/list를 한 번만 시도한 뒤에도 inaccessible일 때 기존 no-verdict/review-unavailable로 끝낸다. Live 검증에서 첫 시도가 성공하면 availability 성공과 fallback 미관측을 분리하고, fallback을 재현하려고 policy rejection을 제조하지 않는다.
