# Review tool-native report consumption Design

## Header

이 Design은 reviewer가 tool-native raw report를 재서술본 대신 직접 소비할 때 필요한 최소 판단 규약을 소유한다. 결과 상태는 report-native 근거와 다른 출처의 주장을 분리하고, 보고서가 말하지 않는 값을 제조하지 않는 것이다. 이 문서는 mutation·commit·push 승인이 아니다.

## 왜 바꾸는가 / 무엇을 바꾸는가

현행 계약은 validation evidence를 supporting material로 읽고 truth oracle로 승격하지 않는 경계를 갖지만, raw report를 실제로 소비할 때 어떤 native 근거를 지목하고 어디까지 추론할지는 명시하지 않는다. W-27 관측에서 직접 소비의 실현 가능성과 source 재서술 대비 이점이 확인됐으므로, 원본 소비와 추론 한계를 한 compact pair로 추가한다.

## Owner surface model

- Review SKILL은 operator가 packet에 넣을 원본 소비·추론 한계 규약을 소유한다.
- `templates/review-input.md`는 `Required inspection paths`와 validation evidence를 작성하는 point-of-use 안내를 소유한다.
- `docs/review/review_spec.md`는 active surface와 대조되는 target-state 의미를 기록한다.

## 수정 대상

후보는 Review lifecycle 3경로와 active 2경로, 총 5경로다: `docs/review/review_design.md`, `docs/review/review_plan.md`, `docs/review/review_spec.md`, `snippets/claude-skills/ai-harness-review/SKILL.md`, `templates/review-input.md`.

## 하지 않을 것 (non-goals)

- raw report format·vendor·XML/Pester/NUnit 사례별 규칙이나 parser/schema/H2를 만들지 않는다.
- report를 canonical artifact, source-of-truth, freshness/correctness proof로 승격하지 않는다.
- 접근 실패나 미관측 failure/skip branch를 추가 specimen·retry·case별 예외로 증명하지 않는다.
- hash·preimage·byte binding·tamper-proof, runner/permission transport, result format을 추가하지 않는다.
- 판단 문면을 literal로 고정하는 새 test assertion이나 기계 gate를 추가하지 않는다.
- W-26, Q-12, subtraction-turn 또는 기존 잠복 문제를 이 후보에 섞지 않는다.

## Plan readiness / open risks

방향 결정은 닫혔다. 원본에서 결정적인 native field/case를 지목하고 report/run provenance/source context를 분리하며, 별도 근거 없이 없는 값을 만들지 않는 두 의미만 추가한다. Load-bearing 접근 실패는 기존 review-unavailable 계약을 그대로 사용한다. 이 경계를 넘어서는 요구가 생기면 확대하지 않고 보고한다.
