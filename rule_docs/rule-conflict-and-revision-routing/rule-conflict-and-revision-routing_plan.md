# rule-conflict-and-revision-routing Plan

> 이 Plan은 승인된 G-1 narrow-retain 변경의 batch 경계와 closeout 결정을 담는 committed-temporary 문서다. 실행 기록이나 최종 normative wording이 아니며 mutation/commit/push/adoption/activation 승인이 아니다.

## Header

- 이 lifecycle은 planning anchor와 terminal landing + closeout 두 changeset으로 구성한다.
- 최종 상태는 축소된 terminal rule과 동기화된 distributed index만 남기고 Design/Plan을 삭제하는 것이다.
- 별도 Work Packet은 만들지 않는다. 이번 회차의 의미·범위·검증이 Design과 Plan에서 충분히 닫히며 round-scoped inventory를 추가할 필요가 없다.

## Batch 순서와 의존

1. **Planning anchor:** 새 Design과 Plan을 기록하고 이전 Work Packet을 삭제한다. active distributed behavior는 바꾸지 않는다.
2. **Terminal landing + closeout:** terminal rule을 승인된 네 핵심 의미로 축소하고 index 설명을 동기화한 뒤 Design/Plan을 삭제한다.

두 번째 changeset은 구현·기계 검증·fresh canonical dual·독립 오탐 감사에서 current-scope blocker가 없을 때만 진행한다. 새 blocker가 나오면 closeout과 push를 중단한다.

## Batch 정의

### Planning anchor

- **목적:** authority 축소의 이유, owner model, non-goal, terminal 의미를 active rule 변경 전에 reachable history에 결박한다.
- **scope:** `rule-conflict-and-revision-routing_design.md`, `rule-conflict-and-revision-routing_plan.md`, 기존 `rule-conflict-and-revision-routing_work_packet.md` 삭제다.
- **hard boundary:** terminal rule, distributed index, bootstrap, backlog, test와 runtime surface를 수정하지 않는다.
- **validation expectation:** DWM role·altitude·placement와 encoding이 맞고 exact three-path changeset이다.
- **review focus:** 이전 B04 확장 방향이 남아 있지 않은지, 네 핵심 의미가 foreign owner lifecycle을 재도입하지 않는지, Work Packet 부재가 current-bearing 의미를 유실하지 않는지 확인한다.
- **Work Packet:** 사용하지 않는다. 별도 packet이 필요한 새 investigation 또는 line-level decision이 발생하면 범위 확대로 중단한다.

### Terminal landing + closeout

- **목적:** terminal rule의 authority를 genuine-conflict admission과 사용자 선택 경계로 제한한다.
- **scope:** `snippets/rules/rule-conflict-and-revision-routing.md` 전체 문면 교체, `snippets/rules/README.md`의 해당 index line 동기화, Design/Plan 삭제다.
- **hard boundary:** 두 bootstrap, 다른 distributed/repo-only rule, DWM/GFM/PFE backlog, form/checker, runtime script와 test를 수정하지 않는다.
- **validation expectation:** rule은 vendor-neutral·public-safe·docs-free·self-contained하고 네 핵심 의미만 소유한다. index는 그 action class를 정확히 요약한다. bootstrap route는 기존 문면으로 새 rule을 계속 정확히 가리키므로 checked-no-change다.
- **review focus:** genuine conflict admission의 과대·과소 범위, rule binding의 지속, revision을 waiver로 오독할 가능성, foreign owner lifecycle/taxonomy의 잔존, index와 payload의 의미 일치를 확인한다.
- **Work Packet:** 없음. closeout에서 새 packet을 만들지 않는다.

## Validation 및 review gate

- DWM checker, PowerShell verifier, encoding과 diff hygiene를 확인한다.
- distributed payload/index와 두 bootstrap의 trigger parity를 확인한다.
- affected Pester와 full Pester를 수행한다.
- corrected working tree에 fresh canonical dual review와 별도 false-positive audit를 수행한다.
- 수정 후 review가 stale이 되면 재검토한다. blocker가 남으면 terminal commit과 push를 하지 않는다.

## Closeout surface 대조

- **Level 1 — orientation:** `docs/README.md`와 affected unmigrated orientation surface를 확인한다. 이번 distributed rule 의미를 위한 새 docs routing이 없으면 checked-no-change로 보고한다.
- **Level 2 — owner-local:** terminal rule은 updated로, 기존 rule backlog는 존재 여부와 current-scope future work 필요성을 확인해 checked-no-change 또는 해당 사실을 보고한다.
- `snippets/rules/README.md`는 active distribution index이므로 updated로 보고한다.
- `snippets/CLAUDE_SNIPPET.md`와 `snippets/AGENTS_SNIPPET.md`는 기존 trigger route가 새 action class를 포괄하는지 각각 checked-no-change로 보고한다.

## Open decision의 close 지점

- terminal rule의 최종 영어 문면은 approved semantic target을 넘지 않는 범위에서 landing changeset에서 닫는다.
- bootstrap 수정, backlog 추가, test/form/checker 추가가 필요하다는 새 evidence가 나오면 현재 batch에서 결정하지 않고 scope expansion으로 중단한다.
- global ToolRoot update는 source landing 뒤 별도 사용자 gate다. managed-block activation은 bootstrap bytes가 불변이므로 이번 lifecycle에 포함하지 않는다.

## Stage rewind 조건

- implementation이 conflict outcome, cross-owner status, queue 또는 completion protocol을 다시 도입하면 Design 경계를 넘은 것이므로 중단한다.
- bootstrap이나 다른 owner rule을 수정해야만 acceptance를 만족할 수 있으면 scope expansion으로 중단한다.
- canonical review 또는 독립 감사에서 current-scope blocker가 확인되면 수정 가능성을 먼저 판별하고, 새 owner 결정이 필요하면 사용자에게 돌린다.
- 원격 main 또는 relay branch가 승인 시점의 예상 ref에서 달라지면 push하지 않는다.
