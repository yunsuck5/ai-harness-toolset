# Review external-path direct-read Design

## Header

이 Design은 caller가 지정한 repo 밖 directory/file을 canonical reviewer가 직접 읽게 하는 최소 transport 변경을 소유한다. 결과 상태는 input 본문 복제 없이 exact path를 전달하고, load-bearing 자료를 읽지 못하면 verdict를 만들지 않는 것이다. 이 문서는 mutation·commit·push 승인이 아니다.

## 왜 바꾸는가 / 무엇을 바꾸는가

현행 runner에는 repo 밖 path를 명시하는 입력이 없어, caller가 load-bearing 자료를 input에 다시 복제해야 한다. 이는 framing과 재구성 비용을 키운다. Runner에 external directory/file parameter를 추가하고, 절대·존재·type·정규화·중복만 기계 확인한 뒤 reviewer에게 선언 경로와 adapter-local read transport를 전달한다.

## Owner surface model

- `scripts/review-run.ps1`: parameter 검증, 정규화·중복 제거, ProjectRoot/CWD 결박, Codex adapter transport, reviewer preamble을 소유한다.
- `snippets/claude-skills/ai-harness-review/SKILL.md`와 `templates/review-input.md`: caller가 exact external path를 전달하고 직접 읽기 실패를 review unavailable로 처리하는 사용 계약만 소유한다. Codex 전용 argv나 permission 표현은 소유하지 않는다.
- `docs/review/review_spec.md`: 위 active surface의 목표 상태와 owner 경계를 대조한다.
- 기존 runner/input 계약 테스트가 외부 관찰 행동을 검증한다.

## 수정 대상

정확한 후보는 Review lifecycle 3경로와 active/test 5경로, 총 8경로다: `docs/review/review_design.md`, `docs/review/review_plan.md`, `docs/review/review_spec.md`, `scripts/review-run.ps1`, `snippets/claude-skills/ai-harness-review/SKILL.md`, `templates/review-input.md`, `tests/review-run.Tests.ps1`, `tests/review-input-verify.Tests.ps1`.

## 하지 않을 것 (non-goals)

- selected-path confinement, adversarial reviewer/Codex/OS 우회 방지, permission 보증을 만들지 않는다.
- per-path self-attestation, requested/effective path 재서술, access trace/event parser, 새 schema·gate·helper·sidecar를 만들지 않는다.
- external 자료를 input·proxy·staging·workspace copy로 우회 제조하지 않는다.
- result 형식이나 verdict 어휘, safety negtest, config/schema, 다른 domain/rule을 바꾸지 않는다.
- 이번 작업에서 발견되는 기존 잠복 결함을 규칙 순증가로 흡수하지 않는다.

## Plan readiness / open risks

방향 결정은 닫혔다. Broad read는 selected-only 경계가 아닌 caller-declared direct-read transport이며, 실제 접근 성공을 보증하지 않는다. Load-bearing 자료 접근 실패는 기존 no-verdict/review-unavailable 경로로 닫는다. 이 경계를 넘는 요구가 생기면 확대하지 않고 보고한다.
