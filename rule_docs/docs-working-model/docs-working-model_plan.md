# docs-working-model Plan

> 이 문서는 DWM backlog 두 항목의 승인된 처분과 closeout 경계를 정하는 Plan이다.
> 이 체인이 끝나면 종료된 항목과 dangling 참조만 제거되고 나머지 future-work queue와 terminal rule은 보존된다.
> 이 Plan은 조사 기록이나 mutation/commit/push 승인이 아니며 closeout에서 삭제된다.

## Batch 순서와 의존

1. **Queue disposition**: `DWM-B-16`과 `DWM-B-06`을 삭제하고 `DWM-B-07`의 삭제된 overlap 참조만 정리한다.
2. **Validation and closeout**: backlog 회계와 reference 정합을 검증하고 Design/Plan의 고유 live 의미가 없음을 확인한 뒤 두 planning artifact를 retire한다.

처분 결과가 먼저 고정돼야 closeout이 의미 손실 없이 planning artifact를 삭제할 수 있으므로 순서를 바꾸지 않는다.

## Batch 정의

### Batch 1 — Queue disposition

- 목적: 실제 trigger가 소비된 `DWM-B-16`과 결정 불가능한 elapsed-phase catch-all `DWM-B-06`을 future-work queue에서 제거한다.
- scope: DWM backlog의 두 행 삭제와 `DWM-B-07` trigger의 dangling 참조 정정만 다룬다.
- hard boundary: terminal rule·forms·checker·tests와 `DWM-B-14`·next ID를 변경하지 않고, 이번 DWM 처분으로 다른 owner 의미를 변경하거나 흡수하지 않는다.
- validation expectation: 삭제 대상 두 ID가 active queue에서 사라지고, `DWM-B-07`은 자기 독립 reopen condition을 유지하며, `DWM-B-14`와 `next ID: DWM-B-20`이 보존된다.
- review focus: enforcement-inventory framing의 재도입, 살아 있는 항목의 의미 축소, cross-owner 의미 흡수 여부.
- Work Packet: 필요하지 않다. 처분은 두 행과 한 직접 참조로 완결되며 별도 line-level 조사·분류가 없다.

### Batch 2 — Validation and closeout

- 목적: corrected state를 검증·review하고 Design/Plan을 retire한다.
- scope: 이번 DWM lifecycle의 backlog 처분, 직접 inbound reference, 두 planning artifact에 한정한다.
- hard boundary: unrelated backlog 정리, 새 enforcement 수단, commit/push/global mutation의 자동 승격을 금지한다.
- validation expectation: DWM checker·encoding·diff와 corrected-state review가 통과하고, Design/Plan의 current-bearing 의미가 backlog 처분과 closeout 보고에 흡수된다.
- review focus: 삭제된 ID의 dangling 참조, `DWM-B-14` 소급 close, next-ID 감소, planning-only 의미 잔류 여부.
- Work Packet: 필요하지 않다. 실행 결과는 operator report가 소유하고 planning artifact는 closeout에서 삭제한다.

## Open decision 의 close 지점

- `DWM-B-16` 삭제, `DWM-B-06` 삭제와 `DWM-B-07` 참조 정정, `DWM-B-14` 유지 결정은 Batch 1 scope로 고정됐다.
- 실제 corrected bytes가 이 경계를 지키는지는 Batch 2 검증·review에서 닫는다.
- active rule 의미 교정이나 다른 owner 변경 필요성이 새로 발견되면 이 Plan에서 결정하지 않고 별도 사용자 판단으로 돌린다.

## Stage rewind 조건

- backlog 처분이 E1 또는 terminal rule 의미 변경을 요구하면 Design으로 되돌아간다.
- `DWM-B-07` 정정이 독립 reopen condition을 약화하거나 새 조건을 만들면 Batch 1을 다시 계획한다.
- DWM backlog 처분이 `DWM-B-14`, next ID, terminal rule·forms·checker·tests 또는 다른 owner 의미를 변경·흡수하면 중단하고 범위를 다시 승인받는다.
