# Review direct-inspection and three-verdict Design

## Header

이 Design은 reviewer invocation 성립 뒤 정상 판단을 `yes` / `yes with risk` / `no`로 닫고, reviewer가 가용한 read-only material을 직접 확인하도록 책임을 재배치한다. caller의 intended target·authority·hidden fact 책임은 유지하되 중복 확인·기록 의무는 감산한다. 이 문서는 mutation·commit·push 승인이 아니다.

## 왜 바꾸는가 / 무엇을 바꾸는가

현행 계약은 reviewer에게 evidence 재구성을 금지하면서 불충분하거나 inaccessible한 material에 의도적 no-verdict 출구를 준다. 그 결과 가용한 직접 확인을 limitation으로 대체할 수 있고 caller가 원문·count·report·reference sweep을 이중 증명한다. 기존 문면을 직접 확인 의무와 materiality 기반 3-verdict 처분으로 교체하고 caller 중복을 삭제한다.

## Owner surface model

- `scripts/review-run.ps1` preamble은 직접 확인, rational blocker, 3-verdict와 외부 target의 bounded fallback instruction을 소유한다.
- `snippets/claude-skills/ai-harness-review/SKILL.md`와 `templates/review-input.md`는 intended target·authority·hidden fact·외부 path 전달 같은 caller 책임만 소유한다.
- `templates/review-result.md`는 이미 3-token과 limitation 위치에 정렬되어 있어 byte 변경 없이 유지한다.
- `docs/review/review_spec.md`는 active surface와 대조되는 target state와 validation expectation을 기록한다.
- 기존 input/runner test case는 감산된 authoring surface와 external shape 3종의 preamble/profile 결박을 검증한다.

## 수정 대상

C2 byte target은 lifecycle 2경로와 Spec·runner·Skill·input template·기존 test 2경로의 총 8경로다. result template은 alignment 확인 대상이지만 변경하지 않는다.

## 하지 않을 것 (non-goals)

- permission profile, runner mechanical tail, parser/verifier, install을 바꾸거나 stage·commit·push·배포·lifecycle closeout을 수행하지 않는다.
- 새 H2·verdict·gate·parser field·추가 evidence artifact·test case를 만들지 않는다.
- caller의 engine eligibility·target/base/omission·campaign·authority·validation·known concern·off-repo transport·intake·outer timeout 책임을 reviewer로 옮기지 않는다.
- 예기치 않은 model/tool failure를 정상 verdict로 가장하거나 `yes with risk`를 미확인 대체 토큰으로 쓰지 않는다.
## Plan readiness / open risks

방향 결정은 닫혔다. stable pre-change engine의 legacy no-verdict가 실제 발생하면 재시도 없이 정지하며, timeout 조항만 사용자 재정에 따라 별도 authority 경계를 적용한다.
