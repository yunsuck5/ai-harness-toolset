# terminology-glossary Design

> 이 문서는 W-18이 바꾸는 project-wide lifecycle 용어의 채택 의미를 `rules/terminology-glossary.md`에 정합시키는 owner-local Design이다.
> DWM은 lifecycle과 retirement-only predicate의 전체 의미를 소유하고, glossary는 공유 용어의 한 줄 채택 의미만 소유한다.
> 이 문서는 mutation/commit/push/배포 승인이 아니며, W-18 자기 closeout에는 개정 전 DWM의 비소급 경계가 계속 적용된다.

## 왜 바꾸는가 / 무엇을 바꾸는가

W-18은 content readiness와 terminal retirement를 분리하고, exact retirement-only transaction을 reviewable content change에서 제외한다. 이 의미는 기존 glossary의 `Implementation`·`Work Packet`·`sync-required`·`promoted-lifecycle closeout` 정의와 맞지 않고, 새 공용 용어 `retirement-only closeout`도 glossary에 아직 채택되어 있지 않았다.

Glossary는 `# 규칙: 프로젝트 용어집`인 독립 terminal rule이다. DWM Design/Plan이 glossary 의미를 대신 승인하지 않는다. 이 lifecycle은 다섯 용어 disposition과 single-home 경계만 결정하며, DWM predicate를 복제하거나 새 behavior authority를 만들지 않는다.

## 선택 의미

1. **`Implementation`**은 final Spec을 구현하고 final corrected-state review 전에 Spec과 의미 수준으로 reconcile된다. Retirement-only closeout은 새 reconciliation 단계가 아니라 그 정합을 전제로 한 terminal lifecycle 행위다.
2. **`Work Packet`**의 current-bearing 의미는 final corrected-state review 전에 올바른 owner/report/backlog로 흡수된다. Work Packet 자체는 retirement-only closeout에서 삭제된다.
3. **`sync-required`**는 revised target-state/implementation alignment를 `live`로 돌리는 승인 closeout 전까지의 Spec 상태다. 단순히 implementation 작업이 끝나지 않았다는 진행상태로 축소하지 않는다.
4. **`promoted-lifecycle closeout`**은 promoted artifact의 current-bearing 의미를 final review 전에 owner에 흡수한 뒤 temporary Design·Plan·Work Packet을 retire하는 상위 closeout 의미다.
5. **`retirement-only closeout`**을 project-wide adopted term으로 추가한다. 한 줄 의미는 최종 content readiness와 corrected-state review 뒤, DWM-qualified planning deletion과 affected Spec lifecycle-marker disposition 외 source delta가 0인 사용자 승인 closeout이다.
6. **Single home을 유지한다.** Exact transaction predicate, affected Spec 판정, post-transaction remaining-lifecycle 알고리즘, predicate miss 처리의 전체 semantics는 DWM이 소유한다. Glossary는 `DWM-qualified`라는 얇은 참조 의미만 사용하고 전체 조건을 복제하지 않는다.
7. **W-18에는 비소급이다.** 새 용어 의미를 도입하는 W-18 changeset의 자기 closeout은 개정 전 DWM이 지배한다. 이번 candidate 범위에는 self-closeout·commit·push가 없다.

## Owner surface model

- `rules/terminology-glossary.md`는 위 다섯 project-wide term의 한 줄 채택 의미와 분류를 소유하는 terminal rule이다.
- `rules/docs-working-model/docs-working-model.md`는 lifecycle·readiness·retirement-only exact predicate의 behavior owner다.
- `rule_docs/docs-working-model/docs-working-model_design.md`와 Plan은 DWM rule 변경을 소유하고, 이 Design/Plan은 glossary meaning 변경을 소유한다. 어느 lifecycle도 foreign owner의 결정을 대신 승인하지 않는다.
- Review Design/Plan·Spec·SKILL·root·guide·test는 glossary 용어를 일관 사용하지만 glossary classification의 owner가 아니다.

## 하지 않을 것 (non-goals)

- 다섯 용어 밖의 glossary 분류·뜻·배열을 재설계하지 않는다.
- DWM predicate나 review workflow의 전체 semantics를 glossary에 복제하지 않는다.
- 새 registry·scanner·parser·checker·schema·sidecar·hook·자동 stale detector를 만들지 않는다.
- 새 backlog row나 Work Packet을 만들지 않는다.
- W-18 self-closeout·commit·push·deploy·Q-10을 포함하지 않는다.

## Trade-off와 반례

Glossary 변경을 DWM form sync로만 취급하면 독립 terminal rule의 meaning owner가 사라진다. 반대로 DWM의 전체 predicate를 glossary에 풀어 쓰면 두 규칙이 경쟁하는 복제 owner가 된다. 따라서 다섯 한 줄 의미만 glossary lifecycle에서 승인하고, 세부 알고리즘은 `DWM-qualified`로 단일 owner에 남긴다.

`retirement-only closeout`을 glossary에서 제거하면 이미 여러 active surface가 공용으로 쓰는 용어가 candidate-local label처럼 남는다. 기존 네 정의를 원복하면 새 DWM target meaning과 모순된다. 의미를 유지하는 최소 경로는 이 owner-local lifecycle이다.

## Plan readiness / open risks

방향 결정은 닫혔다. Plan은 glossary owner-local 3-path scope, W-18 aggregate 20-path coordination, Work Packet 없음, affected-first와 same-campaign corrected review, 비소급·landing 제외 경계를 고정한다.
