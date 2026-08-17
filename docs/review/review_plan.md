# Review external direct-read fallback Plan

## Header

이 Plan은 Design의 target별 bounded fallback을 exact 5경로에 구현·검증한다. Work Packet은 필요하지 않다. 이 문서는 mutation·commit·push 승인이 아니다.

## Batch 순서와 의존

1. Review Spec을 target-state 의미로 동기화하고 lifecycle marker를 `sync-required`로 둔다.
2. Runner preamble을 교체하고 기존 external-path integration case에 instruction assertion 한 줄을 추가한다.
3. affected/full validation과 corrected-state review를 수행하고, 별도 수행자 축의 external-path availability 관측은 preamble 전달 증거와 구분한다.

## Batch 정의

- **Exact scope:** `docs/review/review_design.md`, `docs/review/review_plan.md`, `docs/review/review_spec.md`, `scripts/review-run.ps1`, `tests/review-run.Tests.ps1`.
- **Fallback:** 각 load-bearing target의 첫 rejected read/list는 inconclusive다. Reviewer는 더 단순한 direct read/list를 한 번 시도하고, 그 target이 계속 inaccessible일 때만 `## Verdict` 없는 review-unavailable로 끝낸다.
- **Boundary:** policy 분류·exit-code heuristic·vendor/tool literal·권한 확대·per-declared-target 재시도·합성 rejection을 도입하지 않는다. `SKILL.md`, template, parser, schema, config, permission transport, runner logging은 불변이다.
- **Validation:** affected `tests/review-run.Tests.ps1`, Windows PowerShell 5.1 full Pester, `scripts/verify-ps1.ps1`, DWM diagnostic, strict encoding/EOL과 `git diff --check`를 수행한다. 기존 `AC-RR11e` assertion은 instruction 전달만 검증하며 reviewer의 실제 준수나 fallback 발동을 증명하지 않는다.
- **Live observation:** 같은 invocation에 caller-supplied external directory 하나와 그 안의 exact file 둘을 전달해 directory discovery와 multi-path array를 분리 관측한다. Runner를 통과한 Codex 축만 preamble 전달·행동을 관측한다. Runner를 통과하지 않는 별도 수행자 축은 availability·문면 판단만 관측하고 그 한계를 결과에 남긴다. 첫 시도가 성공하면 fallback은 미관측으로 기록하며 재시도하지 않는다.
- **Work Packet:** 조사성 미확정 작업이 없으므로 불필요하다.

## Open decision 의 close 지점

첫 거부의 원인을 durable하게 분류하지 않고 target별 한 번의 더 단순한 direct read/list로 확인한다는 결정이 이 batch에서 닫힌다. Pronoun ambiguity를 피하기 위해 runtime 문면은 `that target`을 사용한다. 이 명료화는 합의된 W2 의미를 바꾸지 않는다.

## Stage rewind 조건

5경로 밖 source mutation, 새 SKILL/template/parser/schema/H2/test case, permission·logging 변경, policy/vendor/exit-code 결박, 합성 rejection 또는 반복 retry가 필요해지면 구현을 멈추고 보고한다. Candidate가 Design 경계를 바꾸면 Design으로, Spec/implementation이 Plan을 넘으면 Plan으로 되돌린다. Commit·push·deploy·lifecycle closeout은 수행하지 않는다.
