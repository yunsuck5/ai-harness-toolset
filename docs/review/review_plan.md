# Review direct-inspection and three-verdict Plan

## Header

이 Plan은 Design의 책임 재배치와 3-verdict target state를 한 C2 working tree에 구현·검증한다. Work Packet은 필요하지 않으며 착륙은 별도 사용자 게이트다.

## Batch 순서와 의존

1. Design/Plan을 두고 Review Spec target state와 lifecycle marker를 동기화한다.
2. runner preamble 기존 문장을 직접 확인·3-verdict로 치환한다.
3. Skill/input template의 caller 중복을 삭제하고 timeout 두 줄만 둔다.
4. 기존 test case를 갱신한 뒤 full validation과 stable pre-change canonical dual을 수행한다.

## Batch 정의

- **Exact byte scope:** `docs/review/review_design.md`, `docs/review/review_plan.md`, `docs/review/review_spec.md`, `scripts/review-run.ps1`, `snippets/claude-skills/ai-harness-review/SKILL.md`, `templates/review-input.md`, `tests/review-run.Tests.ps1`, `tests/review-input-verify.Tests.ps1`.
- **Adjudication:** caller packet의 required-contract 결손은 `no`, reviewer capability 결손은 materiality에 따라 limitation+정상 verdict 또는 acceptance breach를 지목한 `no`로 닫는다.
- **Caller subtraction:** intended target·authority·hidden fact와 B의 9개 책임은 유지하고 원문/count/report/reference/probe 이중 증명과 per-pass framing H2를 제거한다.
- **External shape:** 기존 `AC-RR11e` 한 case 안에서 `dir+file` / `dir-only` / `file-only` 각각의 preamble 주입과 broad-read profile 선택을 함께 검증한다.
- **Validation:** affected tests, Windows PowerShell 5.1 full Pester, `scripts/verify-ps1.ps1`, DWM diagnostic, skill validation, strict encoding/EOL, `git diff --check`를 수행한다.
- **Canonical review:** 설치본 `e0bf1b8`의 provenance를 기존 metadata로 확인하고 candidate engine 없이 dual을 실행한다. caller timeout은 1000년이다.
- **No-delta inspection:** `templates/review-result.md`는 기존 limitation/3-token 계약이 이미 맞는지 확인하고 중복 문면을 추가하지 않는다.
- **Open decision:** 없음 — Design의 방향 결정은 닫혔고 각 batch는 승인된 A~F를 추적한다.
- **Work Packet:** 조사성 미확정 작업이 없어 만들지 않는다.

## Stage rewind 조건

permission·runner tail·install·다른 domain Spec·새 schema/H2/test case가 필요하면 정지한다. legacy no-verdict가 나오면 재실행하지 않으며, commit·push·deploy·closeout은 수행하지 않는다.
