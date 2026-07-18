# global-file-mutation-boundary Plan — root parity checker 정합

## Header

- 이 문서는 root parity checker 정합의 한 changeset을 정한다.
- 완료 시 checker가 shared-body byte parity와 actual managed-marker 부재만 판정한다.
- 작업 메모가 아니며 mutation·commit·push 승인이 아니다.

## Batch 순서와 의존

Checker 구현과 양방향 회귀를 한 changeset으로 맞추고, root pair·distributed rule·managed-block primitive는 current bytes를 대조해 무변경으로 닫는다.

## Batch 정의

| 목적 | Scope | Hard boundary | Validation expectation | Review focus | Work Packet |
|---|---|---|---|---|---|
| parity predicate 정합 | parity checker + GFM lifecycle/backlog | root pair·distributed rule·primitive·도메인 표면 무변경, 새 registry 없음 | 원시 byte 비교, actual-marker 판정, harmless mention 음성·whole-line marker 양성 회귀, targeted/full Pester·verify-ps1·DWM·diff/encoding | decoded equality 잔존, token blacklist 잔존, primitive semantics 복제, root shared-body drift | 불필요 — line-level inventory가 작고 이 Plan에 충분함 |

## Open decision 의 close 지점

- shared body는 marker부터 EOF까지 raw byte 길이와 각 byte를 비교해 닫는다.
- managed-block 부재는 `Find-ManagedBlockMarkers`의 실제 BEGIN/END count 0으로 닫고, malformed fence는 fail-fast를 유지한다.
- `GFM-B-01`은 구현·검증과 함께 queue에서 제거한다.

## Stage rewind 조건

- 구현이 root content·distributed rule·managed-block primitive를 수정하면 Design으로 돌아간다.
- checker가 token blacklist나 permissive decoded equality를 다른 형태로 유지하면 구현 단계로 돌아간다.
- unrelated instruction validation까지 확장되면 중단하고 별도 lifecycle로 분리한다.
