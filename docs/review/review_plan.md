# review Plan

> 이 문서는 review campaign identity와 atomic pass allocation Design을 dependency-atomic candidate로 내리는 Plan이다. target-state Spec, active behavior, tests와 사용자 설명을 같은 의미로 맞추고 affected-first 검증과 corrected-state review를 거쳐 landing 가능한 상태를 만든다. 이 문서는 mutation/commit/push 승인이 아니며 closeout에서 흡수 후 삭제된다.

## Batch 순서와 의존

1. **Lifecycle anchor** — Design/Plan을 두고 live Spec을 target state로 갱신해 `sync-required`로 만든다.
2. **Active implementation** — SKILL의 point-of-use 계약과 prepare/path의 new/continue·exclusive allocation을 구현하고 직접 영향받는 tests와 user guide를 동기화한다.
3. **Candidate validation/review** — 새 반례를 targeted로 먼저 닫고 affected 범위, repo 진단, fresh dual 순서로 corrected candidate를 검증한다.
4. **Landing closeout** — 별도 사용자 landing gate 뒤 final-boundary full suite와 closeout reconciliation을 수행하고 Spec을 live로 돌린 뒤 Design/Plan을 삭제한다.

campaign admission과 pass allocation 중 하나만 먼저 착륙하면 독립 campaign 혼입 또는 overwrite 경쟁이 남으므로 하나의 dependency-atomic change로 취급한다. Work Packet은 만들지 않는다.

## Batch 정의

### Batch 1 — lifecycle anchor와 active implementation

정확한 scope는 다음 10경로다.

| 상태 | 경로 | 역할 |
|---|---|---|
| A | `docs/review/review_design.md` | campaign model·trade-off·non-goal |
| A | `docs/review/review_plan.md` | scope·validation·rewind·closeout 결정 |
| M | `docs/review/review_spec.md` | target-state 의미와 `sync-required` lifecycle |
| M | `snippets/claude-skills/ai-harness-review/SKILL.md` | campaign key와 prepare point-of-use 규율 |
| M | `user_guide/review-system_ko.md` | operator-facing compact 의미 동기화 |
| M | `scripts/review-prepare.ps1` | new/continue admission·단일 후보·empty input 성공 계약 |
| M | `scripts/lib/path.ps1` | exclusive pass-directory claim·0-byte no-clobber input allocation과 range owner |
| M | `tests/review-prepare.Tests.ps1` | campaign·entrypoint·orphan·range acceptance |
| M | `tests/path.Tests.ps1` | deterministic two-process allocation 경쟁 |
| M | `tests/review-run.Tests.ps1` | corrective prepare 호출의 continuation 동기화 |

Hard boundary는 three-level layout, per-perspective numbering, pass당 `input.md`/`result.md` 두 파일, write-once와 no-sidecar 유지다. `Purpose`를 identity binding으로 승격하지 않고 template/verifier/review-run/config/encoding helper를 수정하지 않는다. 첫 mutation 전 project log root→task ancestry와 continuation/write 전 task·canonical anchor·선택 write ancestry의 static reparse entry·wrong-shape entry를 fail-closed하고, hostile mid-invocation replacement 방어는 이 batch의 보안 목표로 확대하지 않는다. product parameter나 environment test hook을 만들지 않으며, concurrent test의 barrier는 test process가 소유한다.

Review focus는 default new와 explicit continuation이 같은 campaign의 두 perspective·corrective pass를 허용하면서 독립 campaign collision을 막는지, project log root부터 선택 write parent까지의 static existing reparse/wrong-shape ancestry가 mutation 전에 거부되는지, 같은 preselected 좌표 경쟁의 loser가 nonzero이고 무덮어쓰기·무자동 retry인지다. 서로 다른 좌표를 정상 선택한 allocation의 동시 성공을 collision failure로 오판하지 않고, lower allocation과 concurrent pass-99의 terminal ordering·점유 확인 시 orphan 보존, inspection-unavailable의 무단 원인·잔존 단정 금지, legacy/orphan과 선택 perspective의 pass-99 exhaustion이 다른 perspective numbering을 막지 않는지도 본다.

### Batch 2 — validation과 corrected-state review

검증은 다음 경계를 지킨다.

1. 신규 campaign/reparse/wrong-shape/per-perspective exhaustion case와 allocation helper case를 targeted로 먼저 실행한다. concurrency의 deterministic 증거는 helper-level same-candidate barrier와 entrypoint explicit/explicit same-coordinate 경쟁으로 닫으며, direct auto/explicit entrypoint barrier를 실행했다고 주장하지 않는다. explicit 선점 뒤 auto가 새 scan에서 다른 좌표를 선택하는 경우는 두 성공을 허용하는 별도 반례로 둔다. lower claim 뒤에는 pass-99 점유를 주입한 entrypoint의 orphan 보존·nonzero/no-PASS와 inspection-unavailable entrypoint의 nonzero/no-PASS·무단 상태 단정 금지를 분리해 닫는다.
2. targeted correction이 닫힌 exact candidate에서 affected review-system suites와 `tests/path.Tests.ps1`을 실행한다.
3. `scripts/verify-ps1.ps1`, DWM diagnostic의 disclosed subset, diff/encoding/reference 검사를 수행한다.
4. current pre-change engine eligibility를 확인하고 changed pipeline의 canary-first 규율에 따라 fresh dual review를 수행한다.
5. full Pester는 landing final boundary까지 보류한다. 작은 수정마다 반복하거나 candidate review 전에 선행하지 않는다.

Commit·push·배포·global/stable mutation은 이 Plan의 승인이 아니며 각각 별도 사용자 gate다.

### Batch 3 — landing closeout

별도 landing 승인 뒤 final-boundary full suite를 1회 수행하고, target-state Spec과 implementation의 의미 1:1 및 Level 1 `docs/README.md`, Level 2 `review_spec.md`/`review_backlog.md`를 개별 확인한다. current-bearing 의미를 Spec·active surface·tests·사용자 가이드에 흡수하고 Design/Plan을 삭제하며 Spec의 lifecycle을 live로 되돌린다. Work Packet은 생성하지 않았으므로 retire 대상이 없다.

## Open decision의 close 지점

- 같은 preselected 좌표의 exclusive directory create exactly-one 성질은 Batch 2의 helper-level deterministic same-candidate barrier와 entrypoint explicit/explicit 경쟁에서 닫는다. direct auto/explicit entrypoint barrier는 validation claim이 아니다.
- legacy task root와 crash orphan 처리는 canonical input anchor·명시적 continuation 반례에서 닫는다.
- project log root→task와 task→selected write parent의 static existing ancestry 및 canonical anchor의 reparse/wrong-shape 거부는 mutation-before/after 상태 반례에서 닫는다. hostile mid-invocation replacement는 비목표로 남긴다.
- pass exhaustion은 선택 perspective의 `pass-98 → pass-99 → stop`, explicit lower-number 우회 거부, concurrent pass-99 뒤 lower post-claim 실패·orphan 보존, post-check inspection-unavailable의 무단 점유·잔존 단정 금지, 다른 perspective의 독립 `pass-01` 성공 반례에서 닫고 rollover는 도입하지 않는다.
- machine-verified purpose equality나 strict pre-contract 판별이 필요하다는 증거가 나오면 이 Plan에서 닫지 않고 Design rewind와 scope 재정을 요청한다.

## Stage rewind 조건

- Plan이 공개 purpose/gate-bound key, default new, explicit continuation, no-sidecar·no-hidden-identity 결정을 바꾸면 Design으로 돌아간다.
- Spec이 Plan의 campaign/admission/orphan/range 의미를 바꾸면 Spec 작성을 멈추고 Plan으로 돌아간다.
- 구현이 exact 10-path scope를 넘거나 input seed·sidecar·parser/run/config·test hook을 요구하면 mutation 전에 정지하고 사용자에게 scope를 상신한다.
- 같은 preselected 좌표의 collision loser가 자동 retry하거나 orphan cleanup/reuse, perspective pass rollover를 도입해야만 test를 통과하거나 static reparse guard를 제거해야 한다면 성공으로 완화하지 않고 정지한다.
