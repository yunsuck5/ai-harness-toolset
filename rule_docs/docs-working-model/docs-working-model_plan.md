# docs-working-model Plan

> 이 문서는 NC-05의 승인 대상 batch·경계·검증 기대를 정하는 Plan이다.
> 이 체인이 끝나면 승인된 inventory 처분만 terminal rule과 직접 구현 표면에 반영된다.
> 조사 내용은 Work Packet에 두며, 이 Plan은 mutation/commit/push 승인이 아니다.

## Batch 순서와 의존

1. **Inventory**: 현재 DWM의 강한 의미 조항을 유한 열거하고 각 기계 검사의 실제 배선을 분류한다.
2. **Disposition**: 독립 완전성 대조와 타당성 감사 뒤 다툼 있는 처분을 사용자가 재정한다.
3. **Implementation**: 승인된 처분만 규칙·직접 form/check 표면에 비례 반영한다.
4. **Validation and closeout**: 의미 대응·직접 검사·review를 거쳐 planning artifact를 흡수·retire한다.

Inventory가 처분의 입력이고, 처분이 구현 범위를 고정하므로 순서를 바꾸지 않는다.

## Batch 정의

### Batch 1 — Inventory

- 목적: 강한 조항과 검사 배선을 빠짐없이 현재 바이트에 결박한다.
- scope: DWM 조항, Step F, 열거된 DWM checker 검사만 다룬다.
- hard boundary: terminal rule·checker 수정, 다른 도메인/규칙 하강, 새 enforcement 체계 도입 금지.
- validation expectation: section coverage가 닫히고 모든 검사에 실제 call-site 근거와 두 호칭 중 하나가 있다.
- review focus: 누락, 복합 조항의 부당한 단일화, 배선 과대주장.
- Work Packet: 필요. 목적은 line-level inventory와 배선 근거 보관, 흡수 대상은 승인된 terminal rule·직접 구현 표면·후속 backlog, retire 조건은 implementation closeout이다.

### Batch 2 — Disposition

- 목적: `retain/narrow/demote/remove/transfer` 제안을 승인 가능한 처분으로 닫는다.
- scope: Batch 1 항목별 처분만 다룬다.
- hard boundary: 다수결을 규범 근거로 사용하지 않고, 미열거 조항을 조용히 변경하지 않는다.
- validation expectation: 유지·축소 조항마다 판정자·근거·반증·회색 통로가 비례하며, 이관·제거는 owner 또는 폐기 이유가 닫힌다.
- review focus: 형태 전칭의 원자 지위 오인, 핵심 안전 경계의 과강등, 역사 문면의 영구 규범화.
- Work Packet: Batch 1의 같은 파일을 사용한다.

### Batch 3 — Implementation

- 목적: 승인된 처분을 최소 changeset으로 구현한다.
- scope: DWM rule과 처분에 직접 결박된 forms/checker/tests만 다룬다.
- hard boundary: 새 schema/registry/scanner/hook/scheduler, HN-02/07/10/12, 타 도메인 의미 변경 금지.
- validation expectation: 규칙 문면과 실제 배선 호칭이 일치하고 직접 구현 표면이 1:1이다.
- review focus: 승인되지 않은 의미 확대, 진단을 gate로 오칭, form 자체의 독립 blocker화.
- Work Packet: 같은 파일을 구현 대조표로 사용한 뒤 closeout에서 흡수·삭제한다.

### Batch 4 — Validation and closeout

- 목적: corrected tree를 검증·review하고 임시 artifact를 retire한다.
- scope: 이번 lifecycle의 직접 표면과 inbound reference만 다룬다.
- hard boundary: unrelated cleanup, commit/push/global mutation은 각각 별도 승인 전 금지.
- validation expectation: 직접 검사 PASS, 의미 대응 확인, review의 blocker 0, Design/Plan/WP의 고유 live 의미 0.
- review focus: inventory 누락으로 인한 조용한 의미 손실과 stale form/check 문면.
- Work Packet: closeout 시 terminal rule·올바른 owner·backlog에 흡수한 뒤 삭제한다.

## Open decision 의 close 지점

- 각 조항 최종 처분과 다툼 있는 경계는 Batch 2 사용자 재정에서 닫는다.
- 실제로 수정할 form/check 범위는 Batch 2 처분의 직접 의존성으로 Batch 3 시작 전에 닫는다.
- accepted risk와 후속 future work는 Batch 4에서 해당 rule backlog 소유 여부를 정한다.

## Stage rewind 조건

- inventory가 고정 불변식이나 유한 전수 범위를 위반하면 Design을 재검토하고 Batch 1을 다시 작성한다.
- 처분이 inventory에 없는 의미를 새로 만들거나 Design의 권위 정직화 방향을 위반하면 Batch 2로 되돌린다.
- 구현이 승인 처분 또는 봉인 scope를 넘으면 중단하고 사용자에게 보고한다.
