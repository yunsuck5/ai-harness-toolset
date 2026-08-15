# review Plan — 합리적 `no`와 저비용 review 경계

## Header

이 문서는 review Design의 결정을 exact10 candidate로 동기화하기 위한 승인 대상 Plan이다.

이 체인이 끝나면 review 계약, reviewer preamble, commit-gate terminal rule과 직접 테스트가 한 corrected state로 검증·review될 수 있다.

이 문서는 실행 기록이나 Work Packet이 아니며 mutation·commit·push를 승인하지 않는다.

## Batch 순서와 의존

하나의 content-bearing candidate를 세 단계로 다룬다.

1. exact10 active owner·target-state·lifecycle surface를 함께 동기화한다. review의 rational-`no`와 follow-up 의미, runner preamble, repository-change-safety의 commit-gate 경계가 서로 어긋나면 corrected-state review가 유효하지 않으므로 하나의 candidate다.
2. affected-first validation으로 직접 계약, PowerShell 형식, DWM 구조, diff/encoding을 확인한다. 이 단계가 content를 고치면 candidate 전체를 다시 검증한다.
3. 검증된 candidate에 fresh dual-perspective corrected-state review를 수행하고 결과를 보고한다. full Pester와 실제 landing은 이 Plan의 자동 후속이 아니며 별도 landing 결정으로 미룬다.

## Batch 정의

### C1 — exact10 contract synchronization

목적은 Design의 결정을 다음 exact10에 1:1로 반영하는 것이다.

1. `docs/review/review_design.md`
2. `docs/review/review_plan.md`
3. `docs/review/review_spec.md`
4. `snippets/claude-skills/ai-harness-review/SKILL.md`
5. `rule_docs/repository-change-safety/repository-change-safety_design.md`
6. `rule_docs/repository-change-safety/repository-change-safety_plan.md`
7. `snippets/rules/repository-change-safety.md`
8. `scripts/review-run.ps1`
9. `tests/review-run.Tests.ps1`
10. `tests/review-input-verify.Tests.ps1`

Review-domain 직접 owner는 1–4와 8–10이다. 5–7은 aggregate dependency일 뿐 repository-change-safety 의미의 authority를 이 Plan으로 옮기지 않으며, 해당 terminal-rule Plan이 그 revision과 foreign-Spec direct-sync declaration을 소유한다.

Hard boundary는 exact10 밖 source mutation 0이다. 특히 evidence rule, bootstrap snippet, input/result template, config/schema, parser H2 gate, glossary, backlog, user guide를 바꾸지 않는다. reviewer가 sibling/off-repo 경로를 직접 소비하는 B2 transport는 별도 안건이므로 이번 candidate에서 구현·부분 선점하지 않고 현 exact-path read + inline fallback을 유지한다. Work Packet은 만들지 않는다.

Validation expectation은 다음과 같다.

- `tests/review-run.Tests.ps1`과 `tests/review-input-verify.Tests.ps1`의 affected-first Pester가 rational-`no` preamble과 배포 skill 계약을 검증한다.
- `.ps1` 변경은 `scripts/verify-ps1.ps1`로 UTF-8 BOM + CRLF 및 repo script 규율을 확인한다.
- DWM diagnostic으로 review domain과 repository-change-safety rule lifecycle 구조를 확인한다.
- `git diff --check`, exact10 status/diff 대조, 새 Markdown의 UTF-8 no-BOM + LF 확인을 수행한다.
- full Pester는 landing gate로 defer한다. 미실행 사실과 잔여 위험을 corrected-state review input과 operator report에 명시한다.

Review focus는 다음이다.

- existing authorized read-only facts 우선이 새 증명 생성 의무로 되돌아가지 않는가;
- 각 `no` blocker의 세 근거 요소와 unknown/missing 예외가 reviewer preamble·skill·Spec에서 같은 의미인가;
- 네 disposition이 실제 blocker를 자동 무효화하거나 prior `no`를 삭제하는 우회로가 아닌가;
- closure basis가 변경된 target/input/evidence 또는 허용된 next action을 바꾸는 blocker-bound 명시적 사용자 disposition을 운반하면서 same-state/evidence/claim/disposition retry만 막고 횟수 상한을 만들지 않는가;
- commit gate 정정이 일반 Git safety나 explicit commit/push authority를 약화하지 않는가;
- B2 transport, parser/schema, evidence system으로 범위가 확장되지 않았는가.

### C2 — corrected-state review와 landing 경계

Affected-first validation이 통과한 exact10 candidate를 fresh `local-correctness` + `system-coherence` dual review에 건다. Review 결과가 correction을 요구하면 exact10 안에서 고치고 closure basis를 기록한 뒤 새 corrected-state pass를 사용한다. exact10 밖 correction은 scope expansion으로 stop/report한다.

Fresh dual review가 usable하게 닫혀도 full Pester, Design/Plan retirement와 Spec marker 전이, commit·push·publish·deploy·re-adoption은 자동 승인되지 않는다. full Pester와 landing 처분은 사용자의 후속 명시 결정에 둔다.

## Open decision 의 close 지점

- exact10 구성과 no-Work-Packet 선택은 이 Plan에서 닫힌다.
- rational-`no`의 세 요소, 네 disposition, blocker-bound 명시적 사용자 disposition을 포함한 follow-up closure basis, prior-`no` 보존은 Design 결정대로 C1 owner surface에 반영한다.
- repository-change-safety의 foreign-Spec direct-sync target 여부는 그 terminal-rule Plan이 선언·reconcile한다.
- validation 실패나 fresh dual blocker는 C2에서 evidence와 scope에 따라 correction 또는 stop/report로 닫는다.
- B2 transport와 full landing은 이번 Plan에서 결정하지 않는다.

## Stage rewind 조건

Plan이 기존 read-only 사실 우선, rational-`no`, 네 disposition, closure-basis 결정을 바꾸면 Design으로 rewind한다. Spec이나 active owner가 exact10 경계·non-goal을 넘거나 새 parser/transport/evidence mechanism을 도입하면 re-plan 또는 scope approval 전까지 중단한다. 구현 뒤 source content가 바뀌면 corrected-state validation/review로 되돌아가며, review 뒤 content correction을 retirement-only closeout으로 처리하지 않는다.
