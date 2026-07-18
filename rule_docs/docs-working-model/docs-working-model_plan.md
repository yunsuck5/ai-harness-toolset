# docs-working-model Plan — 후보 용어 lifecycle 분리

## Header

- 이 문서는 docs-working-model self-revision의 한 changeset 경계를 정한다.
- 완료 시 terminal rule, checklist, backlog가 같은 후보-local trigger 모델을 따르고 Authoring language의 repo-internal/distribution tier가 분리된다.
- 작업 로그가 아니며 mutation·commit·push 승인이 아니다.

## Batch 순서와 의존

1. terminal rule에서 glossary reservation/status 결합을 제거하고 후보-local/trigger 모델을 규정한다.
2. promotion checklist를 네 decision trigger 질문에 맞춘다.
3. terminology-glossary revision이 소유한 `TERM-RESERVE` 제거와 `GLOSSARY-POINTER` 미도입 결과를 interface 입력으로 소비하고, DWM이 독립 제거 scope나 대체 진단을 만들지 않는지 확인한다.
4. backlog를 semantic boundary와 실제 future work에 맞춘다.
5. candidate life-event의 trigger 열거를 promotion checklist의 네 trigger와 맞추고, 직접 소비 표면과 planning package를 대조한 뒤 review gate를 수행한다.
6. Authoring language 조항과 `CONTRIBUTING.md` 요약을 repo 내부 `rules/**`의 한국어 본문+영어 기술 anchor, `snippets/rules/**`와 두 root bootstrap의 영어, 그 밖의 `snippets/**` active-owner 언어로 분리하고 재검토 신호를 backlog에 둔다.

개정 전 DWM은 closeout까지 적용하되, 이 changeset이 제거하는 status mechanism을 자기 자신에게 다시 요구하지 않는 범위만 terminal rule의 transitional carve-out으로 분리한다.

## Batch 정의

| 목적 | Scope | Hard boundary | Validation expectation | Review focus | Work Packet |
|---|---|---|---|---|---|
| DWM terminology 연동 축소 | terminal rule, promotion checklist, backlog | glossary 의미·진단 제거 작업·generic scanner·E1–E5를 흡수하지 않음 | status 의존 제거, semantic binding, terminology owner의 처분 결과와 queue 정합 | self-amendment, 제거 잔여, hard-gate 대체물 유입 | 불필요 — 경계와 처분이 이 Plan에 충분함 |
| Authoring language scope 교정 | terminal rule의 Authoring language 조항, `CONTRIBUTING.md`, DWM backlog | 배포 rule 의미 변경·repo 전체 번역을 섞지 않음 | repo 내부/배포 tier 독자 경계와 기술 anchor 보존 | tier 오분류, 번역으로 인한 semantic drift | 불필요 — 사용자 재정과 좁은 문면 교정으로 닫힘 |

## Open decision 의 close 지점

- self-amendment carve-out은 terminal rule 문면과 canonical dual에서 닫는다.
- `pending`·`owner-pending`·`finalization-owner`·transition-aware reservation 의존이 제거됐는지 reference sweep에서 닫는다.
- `TERM-RESERVE` 제거는 terminology-glossary lineage의 checker diff와 full validation을 참조해 닫는다. `GLOSSARY-POINTER`는 tracked HEAD에 들어온 적 없는 WIP 시범안이므로 HEAD/current의 `scripts/**`·`tests/**` 부재와 대체 진단 미도입 sweep으로 닫고, DWM은 두 처분을 독립 소유하지 않는다.
- DWM-B-01은 semantic durable-pointer boundary의 기계화를 재검토할 엄격한 실증 조건만 남긴다.
- B02/B11은 reservation lifecycle 제거로 소멸하고, B03은 rejected-term revival semantic trigger로 닫는다.
- Authoring language는 repo 내부 `rules/**`의 한국어 본문+고정 영어 기술 anchor, `snippets/rules/**`와 두 root bootstrap의 영어 문면, 그 밖의 `snippets/**` active-owner 언어로 닫고 정책 교체는 DWM-B-17의 실사용 신호가 발생할 때만 별도 revision으로 연다.

## Stage rewind 조건

- Plan이 glossary 항목 의미나 foreign owner semantics를 흡수하면 Design으로 돌아간다.
- checker가 새 terminology/pointer hard diagnostic을 만들면 Plan으로 돌아간다.
- 구현이 E1–E5나 다른 lifecycle 의미까지 바꾸면 중단하고 별도 revision으로 분리한다.
- 언어 교정이 배포 rule의 의미를 바꾸거나 기존 repo 문서의 일괄 번역으로 확대되면 중단한다.
