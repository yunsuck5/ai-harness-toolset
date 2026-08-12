# review Plan — canonical review 문면 축소와 pipeline owner 정합

## Header

- 이 문서는 review Design의 owner 재정렬을 한 working-tree candidate로 구현·검증·review하는 Plan이다.
- 완료 시 corrected source/tests와 `sync-required` Spec, temporary Design/Plan이 함께 사용자 gate를 기다린다.
- 실행 로그나 Work Packet이 아니며 mutation·staging·commit·push·global activation 승인이 아니다.

## Batch 순서와 의존

1. live review Spec을 target state로 갱신하고 `sync-required`로 전환한다.
2. prepare의 seed 경로를 제거하고 runner preamble·tail verify, input/result template, compact SKILL을 같은 의미로 정합화한다.
3. 직접 영향 tests와 tests owner 설명을 갱신하고 agenda disposition에 선택·보존·처분을 기록한다.
4. four-class reference sweep, affected/full Pester, PowerShell encoding, tracked/untracked whitespace를 검증한다.
5. 변경 중인 engine을 피하고 global stable ToolRoot로 canary-first local-correctness 후 system-coherence canonical review를 수행한다.
6. Design/Plan을 존치한 index-invariant working-tree candidate를 exact paths·검증·review·잔여 상태와 함께 상신한다.

기계 owner와 operator 문면은 서로의 의미 전제가 되며 P04가 runner와 SKILL 양쪽을 잇기 때문에 하나의 coherence batch로 유지한다. 실제 staging/commit split과 closeout은 후속 사용자 gate 뒤에만 수행한다.

## Batch 정의

| 목적 | Scope | Hard boundary | Validation expectation | Review focus | Work Packet |
|---|---|---|---|---|---|
| B1 canonical review 축소·정정 | review Spec, temporary Design/Plan, review skill, input/result templates, prepare/run, 직접 영향 tests와 tests README, agenda disposition | C5 유지-core와 B2/B3 hold 보존; verdict/layout/parser/sidecar/새 gate 불변; index/branch/commit/push/global 무접촉 | four-class sweep; affected + full Pester; `scripts/verify-ps1.ps1`; tracked `git diff --check`; untracked 파일 직접 whitespace/encoding 검사; stable-engine canary-first dual review | seed 잔존 0, runtime output owner 단일화, generic bucket/default verdict 제거, Counter-argument/risk/once 일관성, tail verify failure semantics, semantic intake와 authority 경계 보존 | 불필요 — 승인된 수렴과 source/tests 대조로 line-level 결정이 닫혀 있음 |

## Open decision 의 close 지점

- **P04:** Design에서 포함으로 닫았다. runner는 pre-verify를 유지하고 append 시도 뒤 같은 verifier를 다시 호출한다. append failure는 기존대로 nonfatal이지만 tail verify failure는 success publication 전 runner nonzero로 닫는다.
- **seed CLI:** full-template seed branch와 `-NoSeed` parameter를 함께 제거한다. prepare의 유일한 성공 동작은 빈 input 발급이다. template은 설치 completeness marker와 operator reference로 존치한다.
- **risk 위치:** `yes with risk`의 named risk는 required `## Non-blocking concerns`에 둔다. generic `## Risks`와 precedence를 일으키는 `## Findings`는 권장 skeleton/runtime 지시에서 제거하되 parser 금지 규칙은 추가하지 않는다.
- **Counter-argument:** optional·strongly-recommended·non-parser로 유지한다. yes 계열에서 deliberate pressure-test를 권하되 omission을 기계 실패로 만들지 않는다.
- **DWM disposition:** `docs/README.md`는 checked-no-change, `docs/review/review_backlog.md`는 checked-no-change, `docs/review/review_spec.md`는 updated다. candidate에서는 Design/Plan과 `sync-required`를 유지하고 closeout에서만 live 복귀·Design/Plan 삭제를 제안한다.

## Stage rewind 조건

- 새 parser gate·required H2·verdict·sidecar·자동화 층이 필요하면 구현을 중단하고 Design으로 돌아간다.
- B2 off-repo fallback 또는 B3 validation 의미를 줄이거나 T2/T3 구현이 필요하면 별도 사용자 gate로 되돌린다.
- P04가 기존 verifier 재사용만으로 failure semantics를 보존하지 못하거나 provenance 내용을 새로 gate해야 하면 Design으로 돌아간다.
- exact-path scope 밖 source 수정, index 변경, branch/checkout/stage/commit/push/global mutation이 필요하면 진행하지 않고 상신한다.
- stable-engine review가 blocker를 내면 candidate closeout을 하지 않고 approved scope 안 corrective 여부를 분류해 보고한다.
