# rule-conflict-and-revision-routing Plan

> 이 Plan은 승인된 B04 revision-handoff 종결 변경의 batch 경계와 closeout 결정을 담는 committed-temporary 문서다. 실행 기록이나 최종 normative wording이 아니며 mutation/commit/push/adoption/activation 승인이 아니다.

## Header

- 이 문서는 planning anchor와 terminal landing을 한 lifecycle로 결박하는 Plan이다.
- 이 체인이 끝나면 terminal rule의 종결 공백과 세 owner의 잔여 future work가 분리되고 planning artifacts는 retire된다.
- 이 문서는 B05 이후 작업, global deployment, activation 또는 bootstrap revision의 Plan이 아니다.

## Batch 순서와 의존

1. **Planning anchor:** Design, Plan, Work Packet만 별도 commit으로 보존한다. 이 단계는 active behavior를 바꾸지 않는다.
2. **Terminal landing + closeout:** planning anchor 이후 terminal rule과 세 owner backlog를 한 corrected state로 갱신하고, Design/Plan/Work Packet을 같은 changeset에서 삭제한다.

두 commit은 DWM의 committed-temporary lifecycle과 terminal landing closeout을 분리하기 위해 필요하다. 구현·검증·fresh review가 blocker 없이 끝날 때만 두 번째 commit과 승인된 atomic push로 진행한다.

## Batch 정의

### Planning anchor

- **목적:** 승인된 semantic target, owner model, 잔여 처분 map을 구현 전에 reachable history에 결박한다.
- **scope:** `rule-conflict-and-revision-routing_{design,plan,work_packet}.md` 세 파일만 작성한다.
- **hard boundary:** terminal rule, backlog, bootstrap, index, test와 runtime surface를 수정하지 않는다.
- **validation expectation:** DWM artifact role·altitude·encoding·folder placement가 맞고 세 파일 밖 staged change가 없다.
- **review focus:** Design/Plan/WP 역할 분리, HN-02 재개방 여부, owner-local 잔여 누락, terminal rule 문면 선결 여부.
- **Work Packet:** 필요하다. 목적은 source finding의 처분·surface·edge-case mapping이고, 흡수 대상은 terminal rule·각 owner backlog·closeout report이며, terminal landing에서 current-bearing 내용의 흡수를 확인한 뒤 삭제한다.

### Terminal landing + closeout

- **목적:** revision handoff의 수신 처분과 원 작업 상태 보존을 terminal rule에 추가하고 미착수 잔여를 각 owner backlog로 분리한다.
- **scope:** terminal rule의 좁은 수정, `DWM-B-20`·`GFM-B-05`·`PFE-B-05` 추가와 next-ID 증가, planning artifact 세 파일 삭제다.
- **hard boundary:** HN-02 row·bootstrap 수정·distributed index 변경·generic schema/checker·B05 이후 작업·global/user surface를 포함하지 않는다.
- **validation expectation:** terminal rule이 vendor-neutral·public-safe·self-contained이고, owner outcome과 원 작업 상태가 서로 독립적으로 재구성된다. 세 backlog row는 아직 시작하지 않은 의미와 구체 reopen/start condition만 담고 next-ID를 재사용하지 않는다.
- **review focus:** ordinary handoff 과대 적용, completion laundering, foreign-owner schema 복제, 구체 close point 누락, planning artifact의 unique live 의미 유실.
- **Work Packet:** planning anchor의 packet 하나를 계속 사용하며 새 packet을 만들지 않는다. terminal rule·backlog·보고에 current-bearing 항목이 흡수되고 corrected-state review가 성립할 때 retire한다.

## Open decision 의 close 지점

- HN-02는 사용자 재정으로 현 bootstrap 문면 유지와 과거 backlog 의무 철회가 닫혔다. terminal landing에서는 checked-no-change로 확인한다.
- revision handoff terminal outcome의 최종 normative wording은 terminal rule에서 닫는다.
- I17 provenance, HN-07, HN-10의 아직 시작하지 않은 의미는 각각 DWM/GFM/PFE backlog의 row와 reopen/start condition에서 닫는다.
- 나머지 source finding은 Work Packet 처분 map에서 기존 owner 흡수·기각·reroute와 close point를 대조하고 새 queue를 만들지 않는다.

## Stage rewind 조건

- terminal wording이 ordinary handoff 전반의 schema·registry·queue를 요구하거나 Design의 최소 transport 경계를 넘으면 Design으로 rewind한다.
- owner-local 잔여를 terminal rule이 직접 정의해야 하거나 bootstrap 수정이 필요해지면 범위 확대로 중단하고 사용자에게 돌린다.
- 구현 뒤 `explicitly unresolved`와 원 작업 상태가 구분되지 않거나 close point 없이 영구 미결을 허용하면 terminal landing을 중단하고 Plan 또는 rule wording을 정정한다.
- fresh canonical review나 독립 오탐 감사에서 current-scope blocker가 남으면 두 번째 commit과 push를 수행하지 않는다.
