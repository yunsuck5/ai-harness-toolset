# docs-working-model Design — 후보 용어 lifecycle 분리

## Header

- 이 문서는 docs-working-model의 terminology 연동을 개정하는 방향을 정한다.
- 완료 시 후보 이름은 owner-local이고 glossary는 lookup 또는 실제 decision trigger에서만 호출된다.
- terminal rule이나 실행 기록이 아니며 mutation·commit·push 승인이 아니다.

## 왜 바꾸는가 / 무엇을 바꾸는가

Docs-working-model이 glossary의 `pending` / `owner-pending` / `finalization-owner`와 reservation schema를 규정하면서 후보 lifecycle과 용어 상태 lifecycle이 결합됐다. 선등록·상태 gate가 실제 의미 충돌보다 먼저 요구되고 checker까지 의미·상태를 판정했다.

후보 이름을 owner-local로 되돌리고, glossary는 채택 의미 조회 또는 네 decision trigger에만 연결한다. 전용 terminology/pointer hard diagnostic은 두지 않는다.

같은 revision에서 Authoring language의 “human-facing docs는 한국어 기본” 문면이 불특정 adopter가 직접 소비하는 distributed rule·root bootstrap까지 확장된 오독도 교정한다. Repo 내부 lifecycle/docs/rules는 한국어 본문+영어 기술 anchor를 유지하고, `snippets/rules/**`와 두 root bootstrap은 영어를 유지하되 그 밖의 `snippets/**` 표면은 각 active owner를 따르게 해 독자와 교체 비용을 분리한다.

## Owner surface model

- docs-working-model rule: 후보 lifecycle, glossary 호출 시점, semantic enforcement 상한
- `CONTRIBUTING.md`: repo 내부/배포 tier Authoring language 경계의 contributor-facing 요약
- terminology glossary: 채택·기각 의미와 실제 항목 처분
- promotion checklist: 네 decision trigger 존재 여부를 사람이 확인
- checker/tests: terminology-glossary revision의 진단 처분 결과를 소비하며, DWM은 독립 제거 scope를 만들지 않음
- corrected-state review·Blind·canonical: glossary meaning/pointer boundary의 문맥 검사
- docs-working-model backlog: 이번 범위 밖 future work

## 수정 대상

- terminal rule의 terminology lifecycle/status 결합
- promotion checklist와 DWM backlog
- terminology-glossary revision이 소유하는 `TERM-RESERVE` 제거 및 `GLOSSARY-POINTER` 미도입 결과와의 interface 정합
- terminal rule의 Authoring language 범위: repo 내부 `rules/**`는 한국어 본문+영어 기술 anchor, `snippets/rules/**`와 두 root bootstrap은 영어, 그 밖의 `snippets/**`는 각 active owner
- `CONTRIBUTING.md`의 Authoring language 요약

권위 분류는 다음과 같다.

- candidate-local registration/status clause: **Binding rule**, scope = candidate terminology, enforcement = lifecycle prose + `TERM-RESERVE`; glossary와 후보 owner를 결합하므로 제거
- `TERM-RESERVE`: deterministic diagnostic이지만 lifecycle **Hard gate는 아님**; 제거 처분은 terminology-glossary revision이 단독 소유하고 DWM은 status coupling을 재도입하지 않음
- durable-pointer prohibition: **Binding rule**, scope = committed docs, enforcement = semantic review와 기존 제한적 E2 scan
- glossary-only pointer diagnostic: whole-prose predicate가 결정 가능하지 않아 제거하며 semantic binding으로 강등하는 것이 아니라, binding은 유지하고 mechanical enforcement만 제거
- candidate life-event trigger 열거: **Binding rule의 정합 교정**, scope = promotion/discard/de-promotion glossary decision, enforcement = terminal rule과 promotion checklist가 같은 네 trigger를 사용
- authoring-language clause: **Binding rule의 scope 교정**, scope = 이 repo의 human-facing 내부 docs와 `rules/**`; 불특정 adopter가 소비하는 `snippets/rules/**`와 두 root bootstrap은 영어를 유지하고 그 밖의 `snippets/**`는 각 active owner를 따름

## 하지 않을 것 (non-goals)

- glossary 항목 의미·12개 처분·root routing을 DWM이 소유하지 않는다.
- generic durable-pointer scanner나 대체 warning을 만들지 않는다.
- E1–E5, authority, promotion, closeout, install-update 의미를 바꾸지 않는다.
- 기존 repo 문서나 rule 전체를 일괄 번역하지 않는다.

## Plan readiness / open risks

Plan으로 진행할 준비가 됐다. Self-revision은 closeout까지 개정 전 DWM의 지배를 받되, 제거 대상 status mechanism만 명시적 transitional carve-out에서 제외한다.

- carve-out 범위: terminal rule과 canonical review
- terminology-glossary revision의 진단 처분 후 semantic coverage: corrected-state review·canonical, 명시 호출된 경우의 Blind
- DWM이 glossary 의미를 재흡수하거나 제거 어휘를 남기는 위험: owner-boundary sweep
- authoring-language tier 경계가 다시 모호해지는 위험: terminal rule 문면과 backlog의 실사용 reopen signal로 닫는다.
