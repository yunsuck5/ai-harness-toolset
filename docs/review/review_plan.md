# Review tool-native report consumption Plan

## Header

이 Plan은 Design의 compact consumption/inference-limit pair를 exact 5경로에 구현·검증한다. Work Packet은 필요하지 않다. 이 문서는 mutation·commit·push 승인이 아니다.

## Batch 순서와 의존

1. Review Spec을 target-state 의미로 동기화하고 lifecycle marker를 `sync-required`로 둔다.
2. Review SKILL과 input template의 기존 point-of-use 문단에 compact pair를 추가한다.
3. 기존 affected test와 형식 진단을 실행하고 corrected-state fresh dual review로 5경로를 검토한다.

## Batch 정의

- **Exact scope:** `docs/review/review_design.md`, `docs/review/review_plan.md`, `docs/review/review_spec.md`, `snippets/claude-skills/ai-harness-review/SKILL.md`, `templates/review-input.md`.
- **Consumption:** `Required inspection paths`에 tool-native raw report가 있으면 원본을 직접 읽고 결정적인 report-native field/case identifier를 지목하며 report-derived, run-provenance, source-context 주장을 구분한다.
- **Inference limit:** 실제 존재하는 field/case만 소비한다. 보고서에 없는 failure/skip detail이나 보고서 단독으로 성립하지 않는 timing/exit/source/full-suite/canonical 주장은 별도 근거 없이 만들지 않고, 접근 실패·부재 branch는 limitation으로 남긴다. Load-bearing 접근 실패에는 기존 review-unavailable 계약을 적용한다.
- **Validation:** unchanged affected `tests/review-input-verify.Tests.ps1`, `scripts/verify-ps1.ps1`, DWM diagnostic, encoding/whitespace 검사를 수행한 뒤 corrected-state dual review를 실행한다. 판단 문면의 literal test binding이나 새 parser·gate·specimen은 만들지 않는다. 추가로 시도한 full suite가 scope 밖 host/tooling 실패를 드러내면 그 사실은 limitation으로 공개하되 W-28 후보에 흡수하지 않는다.
- **Work Packet:** 조사성 미확정 작업이 없으므로 불필요하다.

## Open decision 의 close 지점

Raw report는 noncanonical supporting material로 유지하고, source correctness·freshness·full-suite·canonical authority에는 별도 근거가 필요하다는 결정이 이 batch에서 닫힌다. Format/vendor별 소비 규칙과 미관측 branch 추가 관측은 결정하지 않는다.

## Stage rewind 조건

5경로 밖 mutation, 새 runner/parser/schema/H2/result format, report format별 예외, 추가 specimen, byte-binding 또는 B2/Q-12 의미가 필요해지면 구현을 멈추고 보고한다. Candidate가 Design 경계를 바꾸면 Design으로, Spec/implementation이 Plan을 넘으면 Plan으로 되돌린다. Commit·push·deploy는 수행하지 않는다.
