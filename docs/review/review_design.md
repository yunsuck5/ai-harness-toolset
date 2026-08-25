# Review caller timeout and cancellation Design

## Header

이 Design은 canonical review caller의 timeout 의무와 진행 중 호출의 취소 권한을 수정하는 review-domain lifecycle 기록이다. target-state 의미는 Review Spec, point-of-use 의무는 review Skill이 소유한다. 이 문서는 commit·push·배포 승인이 아니다.

## 문제와 근거

현행 `1000년` timeout은 약 3.156e13ms라 int32 millisecond 상한을 넘는 caller에서 표현할 수 없다. 반대로 `7day`는 604,800,000ms로 표현 가능하면서, 관측된 장시간 canonical review(최대 1,085초)에 비해 충분히 크다.

현행 두 번째 문장은 timeout 종료 뒤 verdict 분류만 다뤄 caller가 진행 중인 호출을 임의 종료하는 것을 막지 않는다. 그 경우 유료 reviewer 사용량이 결과 없이 소모될 수 있으므로, 취소 권한을 사용자 지시에 결박한다.

## 결정과 owner model

- caller는 timeout을 `7day`로 설정한다.
- 사용자의 지시 없이는 진행 중인 canonical review 호출을 취소하지 않는다.
- `docs/review/review_spec.md`는 위 behavior와 권한 경계의 target-state 의미를 소유한다.
- `snippets/claude-skills/ai-harness-review/SKILL.md`는 caller가 소비하는 exact point-of-use 문면을 소유한다.
- `tests/review-input-verify.Tests.ps1`의 기존 test case는 새 문면의 존재만 확인한다. runner는 timeout 값을 소유하지 않는다.

## Trade-offs와 non-goals

`7day`는 무한대가 아니라 caller가 표현할 수 있는 큰 유한값이다. timeout 도달 자체가 취소 권한을 만들지는 않는다. runner timeout parameter, 새 rule·H2·gate·test case, install/global surface 변경, 과거 문구 전면 금지 gate는 만들지 않는다. W-37A의 guide/README 정리는 이 lifecycle 밖이다.

## Semantic target과 Plan readiness

Spec과 Skill에서 동일한 timeout behavior와 사용자 소유 취소 권한을 복원할 수 있고, 기존 positive assertion이 exact 문면을 확인하면 목표가 충족된다. 이 결정은 Plan으로 진행 가능하다.
