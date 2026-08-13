# review B4a 정보 배선 복원 Design

## Header

이 문서는 canonical review의 호출 전 Stage 정보와 canonical reviewer verdict 발급 주체를 active operator 표면에 복원하는 Design이다. 체인이 끝나면 durable target meaning은 review Spec에, 실행 가능한 operator 계약은 배포 SKILL에 동기화된다. 이 문서는 mutation·commit·push·배포 승인이 아니다.

## 왜 바꾸는가 / 무엇을 바꾸는가

review 기계 표면은 prepare가 허용하는 Stage 값과 review-run이 생성하는 reviewer-unit result를 이미 구분하지만, 배포 SKILL은 호출 전에 Stage의 닫힌 값 집합을 알려 주지 않았고 caller self-review와 canonical reviewer verdict의 주체 경계를 진입부에서 명시하지 않았다. 전자는 유효한 첫 호출 전에 알 수 있어야 하는 행동 계약이고, 후자는 caller 판단이 reviewer verdict를 대체하지 못하게 하는 ownership 경계다. 둘 다 외부에서 관찰되는 규범 의미이므로 meaning-preserving direct edit로 처리하지 않고 active SKILL과 target-state Spec에 함께 표현한다.

## Owner surface model

- `review-prepare.ps1`는 허용 Stage 값의 기계 검증을 소유하고, 배포 SKILL은 그 값을 prepare 호출 전에 operator가 알 수 있게 하며 ordinary code change의 기본 선택을 안내한다.
- `review-run.ps1`가 호출한 reviewer unit의 semantically usable result만 canonical reviewer verdict의 출처가 된다. caller self-review는 packet context와 별도 caller 판단일 뿐 그 result를 대체하지 않는다.
- review Spec은 이 행동·ownership의 durable target meaning을 기록하고, active behavior는 script와 SKILL이 소유한다.
- 기존 source-SKILL compact-core 검사는 SKILL이 소유하는 두 짧은 canonical contract line의 위치와 정확한 retention을 고정해 이후 압축·재작성에서의 유실을 탐지한다. 자연어 의미동등성 parser를 흉내 내지 않으며, 의미보존 재문장도 해당 test를 같은 변경에서 의도적으로 갱신해야 한다. 이는 새 runtime gate가 아니라 기존 validation owner의 범위 확장이다.

## 수정 대상

기존 live `docs/review/review_spec.md`를 target state와 `sync-required` 상태로 갱신하고, `snippets/claude-skills/ai-harness-review/SKILL.md`의 기존 진입부와 prepare point-of-use에 최소 문장을 두며, 기존 source-SKILL compact-core test에 두 의미 원자의 회귀 검사를 둔다. temporary Design/Plan은 corrected-state review와 후속 closeout 전까지 존치한다.

## 하지 않을 것 (non-goals)

- Stage parser·ValidateSet·runner·template·result shape·verdict vocabulary를 바꾸지 않는다.
- caller self-review를 없애거나 canonical reviewer unit으로 승격하지 않는다.
- 새 runtime gate·sidecar·orchestration·자연어 parser를 추가하지 않고, 두 canonical contract line 밖의 SKILL prose를 snapshot하지 않는다.
- B4b, B2, B3, B5, F14 또는 다른 roadmap 항목을 이 batch에 포함하지 않는다.
- commit·push·stable/global 설치 갱신을 수행하지 않는다.

## Plan readiness / open risks

owner와 target meaning이 닫혀 있어 하나의 coherence batch로 Plan에 내릴 수 있고 Work Packet은 필요하지 않다. 검토에서 닫을 위험은 `implementation`이 script의 암묵 default로 오해되지 않는지, caller의 별도 판단과 canonical reviewer verdict가 섞이지 않는지, 두 문장이 기존 owner 의미를 중복 확장하지 않는지다.
