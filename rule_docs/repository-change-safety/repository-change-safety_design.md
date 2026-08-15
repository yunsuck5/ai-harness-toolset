# Repository change safety Design

> 이 문서는 commit-readiness 판단에서 완료된 review를 재증명하기 위한 별도 결박 산출물을 요구하지 않도록 `repository-change-safety` terminal rule을 개정하는 Design이다. 최종 active 의미는 `snippets/rules/repository-change-safety.md`가 소유하며, 이 Design은 closeout 때 삭제되는 planning artifact다. 이 문서는 mutation/commit/push/deploy/adoption 승인이 아니다.

## Header

현재 규칙은 commit 전에 repository root·branch·status를 확인하고 staging 뒤 index-sensitive 검사를 다시 실행하도록 요구하지만, 이 사실 확인과 별개로 review 완료 상태를 재증명하는 per-file hash·preimage·byte/content binding이나 persistent proof bundle을 추가로 요구할 수 있는 해석 여지를 닫지 않는다. 이번 변경은 commit-readiness를 승인된 작업 범위에서 직접 읽을 수 있는 source/Git 사실로 판단하게 하고, 별도 consumer가 없는 재증명 산출물은 금지한다.

## 왜 바꾸는가 / 무엇을 바꾸는가

작업자가 candidate를 만들고 review가 완료된 뒤 source와 Git 상태를 직접 확인할 수 있는데도, commit gate가 같은 review의 유효성을 다시 증명한다는 이유로 파일별 hash·preimage·byte/content 결박이나 별도 persistent proof bundle을 요구하면 안전 판단에 새 사실을 더하지 않으면서 비용과 framing artifact만 늘어난다. 이 문제는 현재 사실을 읽지 않는 것을 허용하자는 뜻이 아니다. Commit-readiness는 repository coordinate, 현재 status, 실제 staged target, conflict와 staging 이상, 명시 승인, staging 뒤 index-sensitive 검사 결과처럼 제안된 changeset에 직접 관련된 사실로 판단한다.

선택한 경계는 “모든 hash나 content binding 금지”가 아니다. 완료 review 재증명만을 목적으로 한 추가 결박을 금지하며, 별도의 concrete consumer와 보호할 실패가 있는 기존 integrity·distribution·acceptance 계약은 유지한다.

## 선택한 의미와 counterexample

1. **직접 사실 우선** — commit-readiness는 승인된 source/Git read-only 사실을 사용한다. Root·branch·status뿐 아니라 실제 staged target, conflict, 누락·오염된 staging, 명시 commit 승인, staging 뒤 다시 읽어야 하는 index-sensitive 결과를 확인한다.
2. **완료 review 재증명 산출물 금지** — review가 완료된 candidate를 commit하기 전에 완료 review의 적용을 다시 증명하기 위해 per-file hash, blob preimage, byte/content binding 또는 별도 persistent proof bundle을 요구하거나 생성하지 않는다.
3. **구체적 consumer 계약 보존** — installer가 배포 payload 변조를 검출하기 위해 소비하는 checksum manifest처럼, review 재증명과 독립된 current consumer와 failure가 있는 hash/content 계약은 계속 유효하다.

금지되는 반례는 source와 index를 직접 읽을 수 있고 완료 review 뒤 target-relevant 변경도 없는데, commit gate 자체를 만족시키기 위해 파일별 SHA와 preimage 표를 새 evidence bundle로 만드는 경우다. 허용되는 반례는 staging 뒤 `git status`와 staged diff를 다시 읽어 잘못된 branch, conflict, 빠진 파일 또는 의도하지 않은 staging을 찾는 경우다. 또 다른 허용 반례는 실제 제품 consumer가 검증하는 release checksum 계약이다. 이 두 허용 사례는 완료 review를 별도 artifact로 재증명하는 일이 아니다.

## Owner surface model

- `snippets/rules/repository-change-safety.md`가 commit/push approval, repository/staging 확인, index-sensitive recheck와 이번 재증명 산출물 금지의 adopter-universal active owner다.
- Review의 stale 판단과 reviewer 결과 소비는 Review Spec·skill·runner가 소유한다. 이 rule은 review verdict 의미나 reviewer transport를 복제하지 않는다.
- `snippets/rules/evidence-and-claim-discipline.md`는 일반적인 추가 evidence admission 규칙으로 남고 이번 변경에서 수정하지 않는다. `repository-change-safety`는 commit-readiness라는 더 좁은 action class의 구체 경계를 소유한다.
- Git working tree와 index는 현재 changeset 사실의 원천이지 별도 persistent proof registry가 아니다.

## 수정 대상과 aggregate 경계

이 terminal-rule owner의 직접 수정 대상은 Design, Plan, `snippets/rules/repository-change-safety.md` 세 경로다. 같은 dependency-atomic exact10 candidate에서 Review owner의 일곱 경로가 독립적으로 동기화되지만, Review Spec은 이 rule의 foreign-Spec direct-sync target이 아니며 commit-readiness 의미를 복제하지 않는다. 정확한 aggregate scope와 검증 배치는 Plan이 소유한다.

## 하지 않을 것 (non-goals)

- Root·branch·status, 실제 staged target, conflict·staging 이상, 명시 승인, staging 뒤 index-sensitive recheck를 약화하거나 없애지 않는다.
- 모든 hash, preimage, byte/content 비교 또는 integrity manifest를 전칭 금지하지 않는다.
- Reviewer cwd 고정, external-root transport, direct-read wiring 같은 B2 구현을 선점하지 않는다.
- 새 proof bundle, evidence registry, hash table, hook, scanner, sidecar 또는 automatic stale detector를 만들지 않는다.
- Review Spec·skill·runner의 의미를 이 rule이 소유하거나 중복 정의하지 않는다.
- Work Packet, rule Spec, backlog를 만들지 않는다.
- Full Pester, commit, push, deploy, re-adoption을 candidate 구현 범위에 포함하지 않는다.

## Plan readiness / open risks

선택 의미, counterexample, owner boundary는 Plan으로 내릴 수 있다. Plan은 exact10 aggregate에서 terminal-rule 3경로와 Review 7경로를 구별하고, foreign-Spec direct-sync set이 빈 집합임을 명시하며, affected validation과 corrected-state fresh dual까지 배정한다. 문면이 current Git inspection까지 금지하거나 별도 consumer의 hash 계약을 무효화하면 Design으로 rewind한다.
