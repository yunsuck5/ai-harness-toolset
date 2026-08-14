# docs-working-model Plan

> 이 문서는 W-18 closeout 정의 복원의 승인 대상 scope·검증·review 경계를 정한다.
> 이 체인이 끝나면 retirement-only predicate와 모든 직접 소비 표면이 corrected candidate로 정합되고 final dual 결과까지 보고된다.
> 이 Plan은 commit/push/배포 승인이 아니며, 자기 closeout 처분은 landing gate의 별도 사용자 결정으로 남긴다.

## Batch 순서와 의존

1. **Rule와 form 정합**: DWM terminal rule에 readiness/retirement 분리와 exact predicate를 쓰고, 직접 embody하는 templates/checklists를 맞춘다.
2. **Review owner-local 정합과 coordination**: Review Design/Plan이 root mirror·review SKILL·Review Spec·사용자 가이드·기존 contract test의 blanket stale 문구를 좁은 DWM-qualified 분기로 교정한다. 이 DWM Plan은 dependency와 aggregate scope만 조정하고 foreign review behavior를 승인하지 않는다.
3. **Targeted validation과 corrected candidate dual**: 변경을 모두 끝낸 exact candidate에서 affected-first 검증 후 기존 W-18 campaign의 local/system 두 관점을 실행하고 operator completion report로 보고한다.

rule이 먼저 exact class를 소유해야 consumer가 의미를 복제하지 않고 thin interface로 참조할 수 있다. 검증·review는 candidate 단위로 묶되, review가 발견한 승인 scope 내부 결함은 corrected candidate와 새 pass로 이어간다. 사용자가 직접 횟수 상한을 정하지 않은 한 이 Plan의 순서 문구를 review 상한으로 해석하지 않는다.

## Exact path scope

| 상태 | 경로 |
|---|---|
| A | `docs/review/review_design.md` |
| A | `docs/review/review_plan.md` |
| A | `rule_docs/docs-working-model/docs-working-model_design.md` |
| A | `rule_docs/docs-working-model/docs-working-model_plan.md` |
| A | `rule_docs/terminology-glossary/terminology-glossary_design.md` |
| A | `rule_docs/terminology-glossary/terminology-glossary_plan.md` |
| M | `rules/docs-working-model/docs-working-model.md` |
| M | `rules/docs-working-model/templates/docs-working-model_design_template.md` |
| M | `rules/docs-working-model/templates/docs-working-model_plan_template.md` |
| M | `rules/docs-working-model/templates/docs-working-model_spec_template.md` |
| M | `rules/docs-working-model/checklists/docs-working-model_plan_checklist.md` |
| M | `rules/docs-working-model/checklists/docs-working-model_spec_checklist.md` |
| M | `rules/docs-working-model/checklists/docs-working-model_closeout_checklist.md` |
| M | `rules/terminology-glossary.md` |
| M | `AGENTS.md` |
| M | `CLAUDE.md` |
| M | `snippets/claude-skills/ai-harness-review/SKILL.md` |
| M | `docs/review/review_spec.md` |
| M | `user_guide/review-system_ko.md` |
| M | `tests/review-input-verify.Tests.ps1` |

위 20경로는 W-18 aggregate transaction의 경계이며 Review 8경로, DWM 9경로, glossary 3경로로 owner-local approval을 분리한다. 이 DWM Plan은 DWM 9경로의 선택만 소유하고 나머지는 dependency로 조정한다. 사용자 직접 재정으로 DWM Plan checklist 1경로가 추가됐다. Review·DWM·glossary 밖의 Brief·consultation·blind-advisory 등 다른 도메인 source mutation이 필요하면 즉시 중단하고 보고한다. Work Packet은 만들지 않는다.

## Batch 1 — Rule와 form 정합

- 목적: closeout을 final content readiness 뒤의 사용자 승인 retirement transaction으로 정의하고 exact shape를 단일 owner에 둔다.
- scope: DWM rule, 3 templates, Plan/Spec/closeout checklists, 이 lifecycle Design/Plan.
- hard boundary: 새 hard gate·checker·script·schema를 만들지 않고 candidate lifecycle이나 일반 staleness를 완화하지 않는다.
- foreign-Spec direct-sync target: `docs/review/review_spec.md` — final corrected-state reviewed DWM candidate가 실제 직접 동기화한 path set과 이 Plan이 aggregate/dependency 목록과 구별해 선언한 direct-sync target set은 모두 정확히 이 한 path다. Aggregate 20-path 목록에 포함됐다는 사실과 별개인 marker-claimant 분류이며 Review meaning ownership은 Review Design/Plan에 남는다.
- validation expectation: final corrected-state review 전에 terminal-rule Plan declaration과 actual direct-sync set reconciliation이 reviewed pre-transaction candidate에 포함되고 그 뒤 review-bound source-managed artifact set·bytes/content·path·Git mode·target-relevant meaning이 변하지 않았는지, retire되는 terminal-rule revision별 actual direct-sync path set과 declared direct-sync target path set의 빈 집합을 포함한 exact equality, proposed closeout transaction의 전체 source delta, domain/terminal-rule 두 variant, aggregate/dependency scope와 foreign-Spec direct-sync target의 구별, domain-local lifecycle이 0인 affected Spec별 surviving open revision의 declared membership과 current actual membership 재구성 및 exact equality, 재구성 불가·모호·불일치 시 `not retirement-only`, true/true surviving claimant가 있으면 공동 retirement 또는 claim 제거 전까지 현재 closeout 보류, transaction retirement set을 뺀 post-state에서 domain lifecycle/terminal claimant가 모두 0일 때만 mandatory `live`, domain lifecycle이 남으면 marker 유지, owner stable-role deletion, no-other-delta, predicate miss→candidate rewind, user approval과 non-retroactivity가 재구성 가능해야 한다.
- review focus: actual/declared direct-sync set의 누락·stale/false·extra·오지정, surviving open revision의 undeclared actual sync가 claimant에서 빠져 marker가 조기 `live`로 전이되는 반례, declaration-only 또는 actual-only claimant가 marker를 유지시킨 뒤 철회되어 해제 actor가 사라지는 반례, true/true claimant를 남긴 채 다른 closeout을 끝낸 뒤 claimant가 false/false로 철회되어 해제 actor가 사라지는 반례, membership 재구성 불가·모호를 absence나 보수적 claimant로 축약하는 반례, marker-line content smuggling, foreign path 삭제 위장, same-Spec multi-claimant aggregate 뒤 marker가 `sync-required`에 고착되는 반례, aggregate-only Plan이 claimant로 오인되어 종료 순서에 따라 marker가 고착되는 반례, terminal-rule sync 뒤 foreign Spec marker 고착, two-level update가 closeout 뒤로 밀리는 순환, rule의 behavior owner 흡수 여부.

## Batch 2 — Review·glossary owner-local 정합 coordination

- 목적: 현 blanket stale 문구가 retirement-only closeout을 다시 포착하지 않게 하면서 실제 내용 변경의 stale gate는 유지하고, Review Spec lifecycle prose를 round-independent하게 완성한다.
- owner: `docs/review/review_design.md`와 `docs/review/review_plan.md`가 이 behavior 선택·scope·validation을 소유한다. 이 절은 aggregate dependency를 위한 coordination summary다.
- scope: Review Design/Plan, root mirror 2면, review SKILL/Spec, 사용자 가이드, 기존 review-input test.
- glossary owner: `rule_docs/terminology-glossary/terminology-glossary_design.md`와 Plan이 다섯 공용 term의 meaning delta를 소유한다. DWM Plan은 glossary rule을 대신 승인하지 않는다.
- hard boundary: 배포 SKILL은 project-rule-qualified interface만 요약하고 repo-only DWM 전체 정의나 docs 경로를 runtime dependency로 삼지 않는다. root shared body는 byte-identical하게 함께 수정한다.
- validation expectation: exact retirement-only는 caller-side `no-reviewable-change`, predicate miss나 review-bound artifact set/source-managed bytes/content/path/Git mode/target-relevant meaning 변경은 ordinary stale/re-review로 분기한다.
- review focus: 광범위 stale 면제, `no-reviewable-change`를 verdict로 오용, self-contained distribution 위반, root mirror 비대칭.

## Batch 3 — Targeted validation과 corrected candidate dual

- targeted: `tests/review-input-verify.Tests.ps1`, `tests/repo-local-instruction-parity.Tests.ps1`.
- structural: 환경에서 resolve한 skill-creator `quick_validate.py`로 Review SKILL의 frontmatter/package shape만 검사하고, `scripts/docs-working-model-check.ps1 -ProjectRoot .`, `scripts/verify-ps1.ps1`, `git diff --check`, strict encoding/EOL 및 exact 20-path/reference sweep을 수행한다. Quick validator와 DWM diagnostic을 body-semantic proof로 과장하지 않는다.
- full Pester: candidate correction loop에서는 실행하지 않는다. landing이 승인되면 변경 없는 final candidate boundary에서 한 번만 판단·실행한다.
- canonical review: 기존 `w18-q04-retirement-closeout-20260814` campaign의 `local-correctness`와 `system-coherence` 두 unit을 `-ContinueCampaign`으로 같은 corrected candidate에서 실행한다. Source 수정은 기존 pass를 stale하게 하므로 새 pass로 이어가며, 사용자 직접 상한이 없으면 횟수 제한을 만들지 않는다. 이 review는 W-18의 내용 변경을 대상으로 하며 closeout dual이 아니다.
- completion: 결과·적용/미적용 검증·미실행 항목을 operator completion report에 기록한다. per-file SHA, blob preimage, evidence hash 표는 만들지 않는다.

## Open decision의 close 지점

- exact predicate와 owner 분리는 Batch 1에서 닫는다.
- staleness/no-reviewable consumer 정합은 Batch 2에서 닫는다.
- candidate fitness는 Batch 3의 targeted validation과 final dual에서 닫는다.
- W-18 introducing changeset은 개정 전 DWM이 자기 closeout까지 지배한다. 실제 landing·self-closeout 처리, commit/push/배포는 이번 범위 밖이며 사용자 landing gate에서 정한다.
- Q-10은 별도 발주되며 이번 batch에 흡수하지 않는다.

## Stage rewind 조건

- exact predicate가 marker 외 Spec prose나 다른 path 수정을 허용해야 한다면 Design으로 되돌아간다.
- 의미를 구현하려면 새 checker/script/sidecar/automatic stale detection이 필요하면 중단하고 scope 확대를 상신한다.
- Review Spec/SKILL 변경이 DWM의 좁은 interface를 넘어 일반 staleness·artifact 계약을 바꾸면 재계획한다.
- 후보 수정 뒤 기존 review를 재사용하거나 retirement-only closeout을 W-18 자기 changeset에 소급 적용하려는 경우 중단하고 사용자 gate로 돌린다.
