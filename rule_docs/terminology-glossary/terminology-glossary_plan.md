# terminology-glossary Plan — 최소 trigger 모델과 reservation 상태 제거

## Header

- 이 문서는 terminology-glossary 개정의 한 changeset 경계를 정한다.
- 완료 시 glossary와 직접 소비 표면이 lookup·네 trigger·semantic pointer boundary를 함께 표현한다.
- 작업 로그가 아니며 mutation·commit·push 승인이 아니다.

## Batch 순서와 의존

1. glossary에서 status/reservation model을 제거하고 12개 pending 항목을 처분한다.
2. 기존 accepted/rejected 항목의 분류·semantic core를 HEAD→current mapping으로 보존한 채 한 줄 home으로 정리한다. `finalization-owner`만 status model 제거 대상으로 함께 삭제한다.
3. root routing과 직접 소비 문서를 lookup·네 mutation trigger·meaning-preserving direct edit에 맞춘다.
4. `TERM-RESERVE` hard diagnostic과 전용 tests를 제거한다. Tracked HEAD에 없던 시범 `GLOSSARY-POINTER`와 전용 tests는 도입하지 않고 WIP 처분으로 닫는다.
5. docs-working-model self-revision과 corrected-state review를 1:1로 맞춘다.

## Batch 정의

| 목적 | Scope | Hard boundary | Validation expectation | Review focus | Work Packet |
|---|---|---|---|---|---|
| glossary 최소 모델 | glossary, root/index routing, 직접 소비 문서, checker/tests의 제거 대상 | foreign semantics·shadow state·pointer scanner를 추가하지 않음 | 12개 처분, 기존 항목 mapping, lookup/trigger/direct-edit 경계가 1:1 | 의미 보존, 제거 어휘, semantic pointer boundary | 불필요 — 항목 mapping과 decision이 이 Plan에 충분함 |

## Open decision 의 close 지점

- 채택 5개, 후보-local 6개, 제거 1개 처분은 terminal glossary와 owner surface 대조에서 닫는다.
- 기존 settled accepted 39개는 status term `finalization-owner` 제거 뒤 38개를 accepted로 유지하고, rejected 13개는 전부 rejected로 유지한다. accepted↔rejected 전환은 없다. `final Spec only`, `stable filename rule`, `Work Packet`, `rule-candidate incubation`, `future-work queue`, protected `INSTALL.md` owner boundary, narrow-architecture carve-out의 semantic core를 terminal glossary에서 명시적으로 보존한다.
- read-only lookup은 항상 가능하고, 네 trigger만 의미·분류 mutation을 일으키며, meaning-preserving correction은 direct edit라는 문면으로 닫는다.
- concrete runtime/scratch pointer 금지는 Binding rule로 유지하되 hard diagnostic을 두지 않고 Blind·canonical·review에서 닫는다.
- rejected-term revival은 semantic trigger로 유지하고 별도 scanner/SC gate는 만들지 않는다.
- prelive domain에서 채택한 `consultation`·`operator synthesis`·`독립 의견`·`재조율`·`blind-advisory`의 의미가 closeout 전에 바뀔 수 있는 리스크를 사용자가 인지·수용했다. 이 terminology 분류는 두 domain implementation의 live authority를 뜻하지 않는다. 실제 의미·분류 변경이 생기면 기존 mutation trigger로 정상 처리하며 closeout 자체를 자동 trigger로 삼거나 별도 provisional 상태를 만들지 않는다.

`GLOSSARY-POINTER` close evidence는 checker diff가 아니다. Tracked HEAD와 current `scripts/**`·`tests/**`에 식별자·실행 코드·전용 output/test가 없고 대체 hard diagnostic도 도입되지 않았다는 current-byte sweep으로 닫는다.

## Stage rewind 조건

- 기존 accepted/rejected 항목의 분류·semantic core가 달라지면 Design으로 돌아간다.
- 구현이 pointer scanner·warning state·새 registry를 도입하면 Plan으로 돌아간다.
- glossary가 foreign owner의 상세 semantics를 흡수하면 중단하고 owner-local 수정으로 되돌린다.
