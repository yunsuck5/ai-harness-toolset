# global-file-mutation-boundary Plan — managed-marker fence 판정 정합

## Header

- 이 문서는 공유 managed-marker parser와 세 소비 계층의 한 changeset을 정한다.
- 완료 시 opposite delimiter와 shorter closer가 fenced marker를 노출하거나 실제 marker를 숨기지 않는다.
- 작업 메모가 아니며 mutation·commit·push 승인이 아니다.

## Batch 순서와 의존

공유 parser 교정, primitive·apply·parity 반례 회귀, lifecycle 정직화를 한 changeset으로 맞춘다. root pair와 distributed rule은 current bytes를 대조해 무변경으로 닫는다.

## Batch 정의

| 목적 | Scope | Hard boundary | Validation expectation | Review focus | Work Packet |
|---|---|---|---|---|---|
| fence predicate 정합 | shared parser + primitive/apply/parity tests + GFM lifecycle + RA backlog | root pair·distributed rule·도메인 표면 무변경, 새 registry·별도 parser 없음 | same-delimiter·closer-length 판정, mixed/shorter 양방향 회귀, replace/remove span 보존, targeted/full Pester·verify-ps1·DWM·diff/encoding | delimiter/length 상태 유실, 세 계층 반례 누락, parser 복제, root shared-body drift | 불필요 — line-level inventory가 작고 이 Plan에 충분함 |

## Open decision 의 close 지점

- opener의 delimiter 종류와 길이는 `Find-ManagedBlockMarkers`가 보존하고, same delimiter·length 이상인 closer만 fence를 닫는다.
- primitive와 apply의 replace/remove, root parity는 같은 predicate를 소비하고 mixed/shorter 반례의 fenced marker 비검출·outside marker 검출을 함께 입증한다.
- replace/remove 비소유 span 위험은 같은 parser 교정과 회귀에 포함하며 별도 GFM backlog로 이관하지 않는다.
- P3-F2 history의 owner-model 오류는 `rule-authority` backlog의 RA-B-02로 분리한다.

## Stage rewind 조건

- 구현이 root content·distributed rule을 수정하면 Design으로 돌아간다.
- 소비자별 parser 복제나 marker 의미 확장이 필요하면 Design으로 돌아간다.
- unrelated instruction validation까지 확장되면 중단하고 별도 lifecycle로 분리한다.
