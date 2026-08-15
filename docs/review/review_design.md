# review Design — 합리적 `no`와 저비용 review 경계

## Header

이 문서는 review engine 적격성 확인, `no`의 근거 품질, blocker 처분, 후속 pass 조건을 함께 바로잡는 review 도메인 revision의 Design이다.

이 체인이 끝나면 reviewer는 구체 실패에 근거한 `no`를 발행하고, operator는 기존 read-only 사실로 engine을 선택하며, 같은 상태를 반복 심사하지 않는다.

이 문서는 구현 절차서나 Work Packet이 아니며 mutation·commit·push를 승인하지 않는다.

## 왜 바꾸는가 / 무엇을 바꾸는가

현행 계약은 review-system self-modification의 engine 적격성을 보수적으로 다루지만, exact-state 비교 문면이 새 checkout·hash·preimage·byte binding 또는 별도 evidence artifact를 만들어 이미 끝난 상태를 다시 증명하라는 요구로 소비될 수 있다. 이는 reviewer가 직접 읽을 수 있는 Git 상태·이력·설치 metadata·기존 checkout을 충분히 활용하지 못하게 하고, 적격 engine이 없는 상황을 단순한 환경 gap 대신 증명 생산 작업으로 확장한다.

또한 현행 `no`는 blocking finding의 존재를 요구하지만, 무엇을 망가뜨리는지 특정하지 않은 unknown·missing·unperformed-check 진술이 blocker로 승격되는 것을 충분히 막지 않는다. 그 결과 실제 correction, 승인 scope 밖 문제, reviewer overreach, false-positive/evidence gap이 한 흐름으로 섞이고, 새 상태나 evidence 없이 같은 주장을 다시 심사하는 loop가 생길 수 있다.

목표 방향은 다음과 같다.

- engine 적격성은 이미 존재하며 승인된 read-only inspection으로 확인 가능한 사실에서 판단한다. 그 사실이 대상 review-machinery 변경을 배제하는 pre-change engine을 확립하지 못하면 새 증명물을 만들지 않고 engine gap으로 보고한다.
- `no`의 각 blocker는 구체적인 failure mode/path 또는 직접적인 contract/acceptance 위반, 영향받는 consumer 또는 decision, 실패한 function·outcome·contract를 연결한다. unknown이나 missing 자체는 명시적 필수 계약의 부재가 아닌 한 blocker가 아니다.
- operator는 blocker를 `in-scope correction`, `out-of-scope stop`, `reviewer overreach`, `false-positive or evidence gap`의 네 경로로 처분한다. 뒤의 두 경로도 근거와 사용자 처분 없이 자동 기각하지 않는다.
- 후속 pass에는 변경된 candidate, 새 evidence, 정정·명확화된 material claim/input, 또는 허용된 next action을 바꾸는 blocker-bound 명시적 사용자 disposition 중 하나의 closure basis가 선행한다. 횟수 상한은 두지 않지만 상태·evidence·주장·blocker disposition이 같은 재시도는 중단·보고한다.
- prior `no`는 write-once canonical history로 보존한다. 후속 correction이나 다른 처분은 과거 결과를 지우거나 재작성하지 않는다.

## Owner surface model

- `snippets/claude-skills/ai-harness-review/SKILL.md`는 engine 선택과 semantic intake, 네 가지 blocker 처분, follow-up closure basis, 역사 보존을 operator point-of-use에서 소유한다.
- `scripts/review-run.ps1`의 reviewer preamble은 reviewer가 작성할 rational-`no` 최소 의미를 self-contained runtime 지시로 소유한다. parser는 그 의미를 기계 판정하지 않는다.
- `docs/review/review_spec.md`는 위 active behavior의 목표 상태와 소유 경계를 대조한다.
- `snippets/rules/repository-change-safety.md`는 completed review 뒤 commit gate가 새 byte/content 증명을 요구하지 않는 repository-change 경계를 소유한다. 해당 의미와 lifecycle은 terminal rule 및 그 rule-local Design/Plan이 소유한다.
- 직접 관련된 review tests는 배포 skill 문면과 runner preamble의 지속 계약을 검증하되 semantic parser gate를 신설하지 않는다.

## 수정 대상

review 도메인의 live Spec, 배포 review skill, reviewer preamble과 직접 계약 테스트를 수정한다. 같은 승인 묶음에서 repository-change-safety terminal rule의 commit-gate 경계를 그 rule-local lifecycle로 동기화한다. 전체 candidate의 exact10 경계와 검증 순서는 Plan이 소유한다.

## 하지 않을 것 (non-goals)

- reviewer의 read-only posture, 세 verdict 어휘, canonical 2-file layout, write-once pass를 바꾸지 않는다.
- rational-`no` 의미를 새 H2·schema·parser lint·자동 disposition으로 기계화하지 않는다.
- 새 checkout, hash/preimage/byte-binding artifact, 별도 evidence bundle, 자동 provenance checker를 만들지 않는다.
- sibling/off-repo 경로를 직접 전달하는 B2 transport를 선점하지 않는다. 현 exact-path read + inline fallback 경계는 유지한다.
- template/config/bootstrap/evidence rule/Brief/consultation/blind-advisory로 범위를 넓히지 않는다.
- full-suite 실행, canonical review, lifecycle closeout, commit·push·publish·deploy·re-adoption을 이 Design이 승인하지 않는다.

## Plan readiness / open risks

방향 결정은 닫혔다. Plan은 exact10 candidate 경계, affected-first validation, corrected-state fresh dual review, full landing의 별도 승인 경계를 명시하면 된다. Work Packet은 필요하지 않다. 구현 중 exact10 밖 active owner가 새로 필요하거나 B2 transport 변경이 필요해지면 scope expansion으로 중단·보고한다.
