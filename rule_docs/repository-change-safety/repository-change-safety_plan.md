# Repository change safety Plan

> 이 문서는 commit-readiness의 직접 source/Git 사실 사용과 완료 review 재증명 산출물 금지를 exact10 aggregate candidate 안에서 구현·검증하는 terminal-rule Plan이다. Work Packet은 만들지 않는다. 이 Plan은 mutation/commit/push/deploy/adoption 승인이 아니다.

## Header

Design에서 선택한 좁은 allow/forbid 경계를 `snippets/rules/repository-change-safety.md`에 반영한다. Terminal rule 본문은 영어를 유지하고, source-repo planning prose는 한국어로 작성한다. 이 Plan은 terminal-rule 3경로의 owner-local lifecycle을 소유하며, 함께 진행되는 Review 7경로의 의미 소유권을 가져오지 않는다.

## Batch 순서와 의존

W-23은 하나의 dependency-atomic exact10 candidate로 진행한다.

1. Review owner와 repository-change-safety owner의 Design·Plan을 각각 current-bearing planning surface로 둔다.
2. Review 7경로와 terminal-rule 3경로를 각 owner의 target state에 맞춰 동기화한다.
3. Affected-first validation, DWM·encoding·diff·reference 진단을 aggregate corrected state에서 수행한다.
4. 같은 corrected state를 fresh canonical dual review로 검토한다.
5. Full Pester와 landing은 별도 landing boundary로 보류한다.

Commit-readiness rule만 먼저 단독 착륙시키거나 Review owner 문면을 이 Plan에서 재정의하지 않는다. 두 owner는 사용자가 승인한 W-23 outcome을 함께 구성하지만 각 durable 의미는 자기 active surface에 남는다.

## Batch 정의

### Terminal-rule direct scope (3 paths)

| 상태 | 경로 | 역할 |
|---|---|---|
| A | `rule_docs/repository-change-safety/repository-change-safety_design.md` | 선택 의미·counterexample·owner·non-goal |
| A | `rule_docs/repository-change-safety/repository-change-safety_plan.md` | exact scope·검증·review focus·closeout 경계 |
| M | `snippets/rules/repository-change-safety.md` | adopter-universal commit-readiness active rule |

### Aggregate coordination (Review 7 paths)

| 상태 | 경로 | aggregate 역할 |
|---|---|---|
| A | `docs/review/review_design.md` | Review owner의 선택 의미 |
| A | `docs/review/review_plan.md` | Review owner의 exact scope·검증 |
| M | `docs/review/review_spec.md` | Review target-state 1:1 sync와 lifecycle marker |
| M | `snippets/claude-skills/ai-harness-review/SKILL.md` | engine eligibility·rational-`no`·disposition·closure operative contract |
| M | `scripts/review-run.ps1` | reviewer runtime preamble direct sync |
| M | `tests/review-run.Tests.ps1` | preamble contract regression |
| M | `tests/review-input-verify.Tests.ps1` | skill contract regression |

위 일곱 경로는 aggregate/dependency scope이며 이 terminal-rule revision의 foreign-Spec direct-sync target이 아니다. 이 revision이 실제로 직접 동기화한 foreign-Spec thin-interface path set은 `actual = ∅`, Plan이 선언한 foreign-Spec direct-sync-target path set은 `declared = ∅`이므로 `actual = declared = ∅`다. `docs/review/review_spec.md`는 Review owner가 독립적으로 수정한다.

### Hard boundary

- Commit-readiness는 승인된 source/Git 사실로 판단한다.
- 완료 review를 다시 증명하기 위한 per-file hash·preimage·byte/content binding 또는 별도 persistent proof bundle을 요구하거나 생성하지 않는다.
- Root·branch·status, 실제 staged target, conflict·누락·오염 staging, 명시 commit 승인, staging 뒤 index-sensitive recheck를 유지한다.
- Review 재증명과 독립된 concrete consumer와 failure가 있는 hash/content 계약을 유지한다.
- B2 direct-read transport, 새 parser/H2/schema/artifact/retry cap, bootstrap snippet, evidence rule, template, config를 수정하지 않는다.
- exact10 밖 source mutation, Work Packet, rule Spec, full Pester, commit, push, deploy, re-adoption은 포함하지 않는다.

### Validation expectation

1. `tests/review-run.Tests.ps1`과 `tests/review-input-verify.Tests.ps1`을 affected-first로 실행한다.
2. `.ps1` 변경 전체에 `scripts/verify-ps1.ps1`을 실행하고, `scripts/docs-working-model-check.ps1 -ProjectRoot .` 진단을 실행한다.
3. `git diff --check`, exact10 status/index, Markdown UTF-8 no-BOM+LF, PowerShell UTF-8 BOM+CRLF, reference/residue를 확인한다.
4. Review target-state와 terminal rule을 포함한 동일 corrected state에서 local-correctness와 system-coherence fresh canonical dual review를 수행한다.
5. Full Pester는 landing 승인 뒤 final unchanged candidate 경계로 보류한다. Commit/push/deploy/re-adoption은 각각 별도 사용자 승인 없이는 수행하지 않는다.

### Review focus와 counterexample

- 완료 review 재증명만을 위해 per-file SHA, blob preimage 또는 byte/content seal 표를 새 persistent evidence로 요구하는 금지 반례
- Direct source/Git fact를 읽지 않고 worker narrative나 별도 proof bundle만 commit-readiness 근거로 소비하는 반례
- 새 금지를 `git status`, staged diff, conflict 확인 또는 staging 뒤 index-sensitive recheck까지 넓혀 정상 안전 검사를 제거하는 반례
- Installer·release consumer가 실제로 소비하는 integrity checksum처럼 독립 contract가 있는 hash까지 전칭 금지하는 반례
- Review Spec이 commit-gate 규칙을 복제하거나 terminal rule이 reviewer verdict·transport 의미를 흡수하는 owner 침범
- Review 7경로를 foreign-Spec direct-sync target으로 잘못 선언하거나 exact10 밖 surface를 함께 고치는 scope 확대

Work Packet은 만들지 않는다. 필요한 boundary, owner, counterexample와 aggregate coordination이 Design과 이 Plan에 충분히 흡수됐으며 별도 round-scoped 조사 artifact가 필요하지 않다.

## Open decision의 close 지점

- 재증명 금지 범위: 완료 review의 적용을 다시 입증하기 위한 추가 per-file binding과 persistent proof bundle로 한정해 Design에서 닫혔다.
- 현행 Git 안전 확인: root·branch·status, staged target, conflict/staging, approval, index-sensitive recheck를 모두 유지하는 것으로 닫혔다.
- Hash 계약 예외: 별도의 concrete consumer와 보호할 failure가 있는 active contract는 유지하는 것으로 닫혔다.
- Owner 분리: commit-readiness는 terminal rule, review validity·closure는 Review owner가 소유하는 것으로 닫혔다.
- Foreign-Spec direct sync: `actual = declared = ∅`로 닫혔다.

## Stage rewind 조건

- Rule이 current source/Git inspection이나 staging 뒤 recheck를 금지하면 Design으로 rewind한다.
- Rule이 모든 hash/content 계약을 전칭 금지하거나 concrete consumer 예외를 잃으면 Design으로 rewind한다.
- Review owner가 commit-readiness 의미를 복제하거나 terminal rule이 review procedure를 흡수하면 각 owner boundary로 교정한다.
- Actual foreign-Spec direct-sync set이 빈 집합이 아니게 되거나 exact10 밖 owner 의미가 필요하면 즉시 멈추고 scope를 상신한다.
- Affected validation 또는 fresh dual에서 exact10 안 concrete blocker가 나오면 candidate를 교정·재검증하고, 새 가치판단이나 scope 확대가 필요할 때만 멈춘다.

## Lifecycle / pre-amendment self-closeout

Terminal rule 자체가 target-state spec이므로 별도 rule Spec은 없다. 이 Design과 Plan은 corrected-state review와 landing 승인 전까지 current-bearing이며, 승인된 retirement-only closeout에서 삭제된다.

이 rule 개정 changeset의 lifecycle closeout과 landing readiness는 개정 전 `repository-change-safety.md` 문면과 이미 적용 중인 DWM 구조 검사를 따른다. 새 commit-readiness 제한을 그 제한을 도입하는 changeset에 소급해 self-proof로 사용하지 않으며, closeout 뒤 후속 changeset부터 개정 문면이 active 의미로 작동한다. Pre-amendment에서 이미 적용되던 root·branch·status, staging 뒤 index-sensitive recheck, explicit approval은 이 changeset에도 계속 적용한다.
