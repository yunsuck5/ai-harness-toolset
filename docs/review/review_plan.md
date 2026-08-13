# review B4a 정보 배선 복원 Plan

## Header

이 문서는 Design이 정한 Stage 호출 전 정보와 canonical verdict 주체 경계를 하나의 coherence batch로 Spec·SKILL에 동기화하는 Plan이다. 결과는 corrected-state review를 거친 working-tree candidate이며, 이 문서는 mutation·commit·push·배포 승인이 아니다.

## Batch 순서와 의존

live Spec을 target state와 `sync-required`로 전환하고 배포 SKILL의 두 point-of-use 문장을 같은 batch에서 맞춘다. 그 뒤 기존 affected validation과 corrected-state dual-perspective review로 의미·owner 정합을 확인한다. Design/Plan closeout은 별도 사용자 착륙 게이트 뒤의 후속 단계다.

## Batch 정의

- 목적: operator가 첫 prepare 호출 전에 유효 Stage 값을 알고, canonical reviewer verdict의 유일한 출처와 caller self-review의 비대체 경계를 진입부에서 알게 한다.
- scope: `docs/review/review_design.md`, `docs/review/review_plan.md`, `docs/review/review_spec.md`, `snippets/claude-skills/ai-harness-review/SKILL.md`, `tests/review-input-verify.Tests.ps1`.
- hard boundary: test mutation은 기존 `AC-IV-OC2`가 F8/F15 두 canonical contract line을 각 intended section에서 정확히 1회 찾아 case-sensitive exact retention하는 것으로 한정한다. surrounding SKILL prose·동의어 grammar·whole file은 snapshot하지 않고, 그 밖의 script·template·config·test mutation, 새 parser/runtime gate, B4b 이후 roadmap 의미, commit·push·stable/global mutation을 포함하지 않는다.
- validation expectation: `scripts/verify-ps1.ps1`, affected `review-input-verify`와 `review-prepare` suites, full Pester, DWM lifecycle/marker 진단, encoding, diff/status 검사를 수행한다.
- review focus: closed Stage 값과 caller-side ordinary-code 기본 선택의 구분, canonical result source의 단일성, caller judgment와 reviewer verdict의 분리, 문면 최소성, Spec↔active owner 복원 가능성, 두 contract line만 의도적으로 exact retention하고 주변 prose나 자연어 의미동등성까지 결박하지 않는 회귀 검사.
- Work Packet: line-level 조사나 별도 회차 분석 owner가 필요하지 않으므로 만들지 않는다.

## Open decision 의 close 지점

Design의 세 위험은 corrected-state local-correctness와 system-coherence review에서 함께 닫는다. 이 batch는 새 제품 선택이나 future-work disposition을 만들지 않는다.

## Stage rewind 조건

Stage의 기계 값·default 동작, reviewer invocation/result contract, parser·template 또는 승인된 compact-core 의미 원자 밖의 test contract를 바꿔야 하거나 다섯 파일 밖 제품 scope가 필요하면 진행을 멈추고 Design/Plan을 다시 조정한다. corrected-state review 뒤 reviewed artifact가 바뀌면 기존 review를 stale로 처리한다. 후속 사용자 착륙 게이트 전에는 Spec을 `live`로 복귀하거나 Design/Plan을 retire하지 않는다.
