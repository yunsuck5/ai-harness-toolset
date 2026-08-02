# rule-authority Plan — 규범 저작 전 최소 대조

## Header

- 이 문서는 `RA-B-01`을 소비하는 `rule-authority` 개정의 한 batch 경계를 정한다.
- 완료 시 terminal rule은 규범 저작 전 최소 대조를 소유하고 backlog는 열린 future work만 남긴다.
- 작업 로그가 아니며 mutation·commit·push 승인이 아니다.

## Batch 순서와 의존

1. terminal rule에 actor·시점·범위가 복원 가능한 최소 admission을 추가한다.
2. 의미가 흡수된 `RA-B-01`을 backlog에서 삭제하고 `next ID: RA-B-03`을 유지한다.
3. two-level closeout 표면과 inbound reference를 확인한 뒤 Design/Plan을 삭제하고 corrected-state를 검증·리뷰한다.

## Batch 정의

| 목적 | Scope | Hard boundary | Validation expectation | Review focus | Work Packet |
|---|---|---|---|---|---|
| 규범 저작 admission | terminal rule, rule backlog, lifecycle closeout | hard gate·영구 의례·foreign semantics·경미 edit 확대 금지 | DWM checker, affected tests, full Pester, 인코딩·diff 검사 | actor·시점·범위, 비소급, 기존 최소화 경계와의 정합 | 불필요 — 단일 최소 조항과 backlog 회계로 충분함 |

## Open decision 의 close 지점

- 적용 대상은 규범적 rule 신규 저작과 의미 개정으로 한정하고 terminal rule에서 닫는다.
- 대조 대상은 현재 작업에서 식별된 정책급 전제, 영향을 받는 foreign owner, 이미 알려진 반례로 두되 현재 작업 안의 1회 대조로 한정한다.
- 오탈자·stale pointer·meaning-preserving correction은 별도 의례 대상에서 제외한다.
- 새 조항은 introducing changeset을 소급 govern하지 않고 이후 rule work부터 적용한다.

## Stage rewind 조건

- 별도 영구 artifact·scanner·필수 corpus를 요구하거나 hard gate로 바뀌면 Design으로 돌아간다.
- foreign owner의 구체 규범을 흡수하거나 경미 edit까지 넓히면 Design으로 돌아간다.
- 이 Plan에 열거하지 않은 active owner 수정이 필요해지면 중단하고 해당 owner lifecycle로 분리한다.
