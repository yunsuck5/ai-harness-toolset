# Review external-path direct-read Plan

## Header

이 Plan은 Design의 최소 direct-read transport를 exact 8경로에 구현·검증한다. Work Packet은 필요하지 않다. 이 문서는 mutation·commit·push 승인이 아니다.

## Batch 순서와 의존

1. Review Spec을 target-state 의미로 동기화하고 lifecycle marker를 `sync-required`로 둔다.
2. Runner와 SKILL/template을 같은 계약으로 구현한다.
3. 기존 두 테스트 표면으로 affected validation을 수행하고 `scripts/verify-ps1.ps1`을 실행한다.
4. corrected-state fresh dual review로 exact 8경로를 검토한다.

## Batch 정의

- **Exact scope:** `docs/review/review_design.md`, `docs/review/review_plan.md`, `docs/review/review_spec.md`, `scripts/review-run.ps1`, `snippets/claude-skills/ai-harness-review/SKILL.md`, `templates/review-input.md`, `tests/review-run.Tests.ps1`, `tests/review-input-verify.Tests.ps1`.
- **Runner:** optional repeated external directory/file parameters; absolute·existing·type validation; normalized stable dedupe; external path가 있을 때만 adapter-local broad-read transport; ProjectRoot/CWD binding; declared paths를 compact preamble로 전달한다.
- **Consumer contract:** load-bearing path를 직접 읽지 못하면 `## Verdict` 없이 concise failure를 반환해 기존 review-unavailable 경로를 사용한다. Inline/proxy/staging/copy fallback은 금지한다.
- **Validation:** affected Pester는 `tests/review-run.Tests.ps1`과 `tests/review-input-verify.Tests.ps1`; 이어 repo root 계약의 full Pester, `scripts/verify-ps1.ps1`, `git diff --check`를 수행한다. 새 parser/security proof/safety-negtest는 만들거나 확대하지 않는다.
- **Work Packet:** 조사성 미확정 작업이 없으므로 불필요하다.

## Open decision 의 close 지점

Codex adapter는 external path가 있을 때 현재 CLI의 고정 broad-read/read-only permission profile을 runner 내부에서만 사용하고 legacy sandbox와 합성하지 않는다. External path가 없는 기존 호출은 현행 sandbox posture를 보존한다. Selected-only confinement과 적대적 우회 방지는 명시적 비목표이며 추가 결정을 만들지 않는다.

## Stage rewind 조건

8경로 밖 mutation, 새 gate/helper/config/rule/domain, per-path attestation, access proof, result-format 확대, case-by-case 오류 기계가 필요해지면 구현을 멈추고 보고한다. Affected validation 또는 review가 현 범위 안의 직접 결함을 찾으면 최소 수정 후 같은 검증으로 복귀한다. Commit·push·deploy는 수행하지 않는다.
