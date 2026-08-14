# review Plan

> 이 문서는 W-18 aggregate candidate 중 review-domain behavior·staleness interface의 승인 대상 scope·검증·review 경계를 정한다.
> DWM predicate는 `rule_docs/docs-working-model/docs-working-model_plan.md`가 소유하고, 이 Plan은 review consumer 의미와 두 owner-local lifecycle의 coordination만 소유한다.
> 이 Plan은 commit/push/배포 승인이 아니며 W-18 자기 closeout은 개정 전 DWM과 별도 사용자 landing gate에 남는다.

## Batch 순서와 의존

1. **Owner-local planning 정합**: DWM Design/Plan은 retirement-only exact predicate를, Review Design/Plan은 no-reviewable/stale 분기를 각각 소유한다. 어느 Plan도 foreign owner의 결정을 대신 승인하지 않는다.
2. **Review 소비 표면 정합**: root mirror·review SKILL·Review Spec·사용자 가이드·기존 contract test를 Review Design의 thin interface에 맞춘다.
3. **Aggregate candidate 검증과 corrected-state review**: DWM owner의 form 변경, glossary owner의 term 변경, review owner의 consumer 변경을 exact 20-path candidate로 결합해 affected-first 검증한 뒤 같은 W-18 campaign의 local/system 두 관점을 실행한다.

Review consumer는 DWM이 제공하는 qualification 의미가 먼저 확정되어야 정합할 수 있으므로 두 lifecycle은 한 aggregate candidate에서 함께 검증한다. 그러나 approval ownership은 합쳐지지 않는다. Review finding이 approved scope 안의 실제 결함이면 worker가 수정·재검증·새 pass를 이어가며, 사용자가 직접 횟수 상한을 정하지 않은 한 review 횟수 제한을 만들지 않는다. Scope 확대·새 가치판단·semantic-unusable 결과만 중단 사유다.

## Exact aggregate path scope

| 상태 | 경로 | owner-local 역할 |
|---|---|---|
| A | `docs/review/review_design.md` | Review Design |
| A | `docs/review/review_plan.md` | Review Plan |
| A | `rule_docs/docs-working-model/docs-working-model_design.md` | DWM Design |
| A | `rule_docs/docs-working-model/docs-working-model_plan.md` | DWM Plan |
| A | `rule_docs/terminology-glossary/terminology-glossary_design.md` | Glossary Design |
| A | `rule_docs/terminology-glossary/terminology-glossary_plan.md` | Glossary Plan |
| M | `rules/docs-working-model/docs-working-model.md` | DWM behavior owner |
| M | `rules/docs-working-model/templates/docs-working-model_design_template.md` | DWM form |
| M | `rules/docs-working-model/templates/docs-working-model_plan_template.md` | DWM form |
| M | `rules/docs-working-model/templates/docs-working-model_spec_template.md` | DWM form |
| M | `rules/docs-working-model/checklists/docs-working-model_plan_checklist.md` | DWM form |
| M | `rules/docs-working-model/checklists/docs-working-model_spec_checklist.md` | DWM form |
| M | `rules/docs-working-model/checklists/docs-working-model_closeout_checklist.md` | DWM form |
| M | `rules/terminology-glossary.md` | 공용 채택 용어 |
| M | `AGENTS.md` | Review repo interface mirror |
| M | `CLAUDE.md` | Review repo interface mirror |
| M | `snippets/claude-skills/ai-harness-review/SKILL.md` | Review behavior owner |
| M | `docs/review/review_spec.md` | Review target-state Spec |
| M | `user_guide/review-system_ko.md` | Review 사용자 설명 |
| M | `tests/review-input-verify.Tests.ps1` | Review contract regression |

위 20경로는 W-18 aggregate transaction의 경계다. 이 Plan은 Review 8경로만 승인하며, DWM 9경로와 glossary 3경로는 각 owner-local Plan이 승인한다. 사용자 직접 재정으로 DWM Plan checklist 1경로가 추가됐다. Review·DWM·glossary 밖의 Brief·consultation·blind-advisory 등 다른 도메인 source mutation이 필요하면 즉시 중단하고 보고한다. Work Packet은 만들지 않는다.

## Batch 1 — Review owner-local 정합

- 목적: exact retirement-only closeout을 review target에서 제외하되 review-bound artifact set/source-managed bytes/content/path/Git mode/target-relevant meaning의 ordinary staleness를 그대로 유지한다.
- scope: Review Design/Plan, root mirror 2면, review SKILL/Spec, 사용자 가이드, 기존 review-input test.
- hard boundary: applicable project rule의 qualification을 thin interface로 소비하고 DWM predicate를 복제하지 않는다. `no-reviewable-change`는 verdict가 아니며 commit/push/배포 권한도 아니다.
- validation expectation: qualified transaction은 prepare/run/pass 없이 caller report로 끝나고, predicate miss나 review-bound artifact set/source-managed bytes/content/path/Git mode/target-relevant meaning 변경은 candidate rewind와 ordinary stale/re-review로 분기해야 한다. Validation evidence bundle 자체는 freshness binding이 아니고, 잘못된 claim·citation·count와 누락 concern은 기존 retraction·stale-by-omission 규율로 처리한다.
- review focus: 광범위 stale 면제, file-kind heuristic, closeout pass 생성, self-contained distribution 위반, root mirror 비대칭, W-18 자기적용.

## Batch 2 — DWM owner-local 의존 정합

- 목적: Review consumer가 참조하는 exact predicate와 terminal-rule foreign-Spec 전이 자격을 DWM owner가 확정한다.
- scope와 상세 acceptance는 `rule_docs/docs-working-model/docs-working-model_plan.md`가 소유한다.
- coordination boundary: retire되는 terminal-rule revision별로 final reviewed candidate의 actual foreign-Spec thin-interface direct-sync path set과 Plan이 aggregate/dependency 목록과 구별해 명시한 foreign-Spec direct-sync target set이 빈 집합까지 정확히 같아야 한다. 불일치는 `not retirement-only`다. Marker disposition은 일치한 affected set과 proposed transaction의 모든 planning 삭제를 적용한 뒤 남은 domain-local lifecycle을 기준으로 한다. Domain-local lifecycle이 0이면 surviving open revision의 affected-Spec declared/current-actual membership을 재구성해 일치시켜야 하고, 재구성 불가·모호·불일치 또는 true/true surviving claimant가 있으면 공동 retirement/선행 claim 제거 전까지 현재 closeout을 보류하는 세부 판정은 DWM이 소유한다.
- review focus: Review Plan이 foreign predicate를 승인하거나 DWM Plan이 review behavior를 승인하는 owner inversion이 없는가.

## Batch 3 — Targeted validation과 corrected candidate dual

- targeted-first: `tests/review-input-verify.Tests.ps1`, `tests/repo-local-instruction-parity.Tests.ps1`.
- structural: 환경에서 resolve한 skill-creator `quick_validate.py`로 Review SKILL frontmatter/package shape만 검사하고, `scripts/docs-working-model-check.ps1 -ProjectRoot .`, `scripts/verify-ps1.ps1`, `git diff --check`, strict encoding/EOL, root parity, exact 20-path/reference sweep을 수행한다. Quick validator와 DWM diagnostic을 body-semantic proof로 과장하지 않는다.
- full Pester: correction loop에서는 실행하지 않는다. Landing이 승인되면 변경 없는 final candidate boundary에서 한 번만 판단·실행한다.
- canonical review: 기존 `w18-q04-retirement-closeout-20260814` campaign의 `local-correctness`와 `system-coherence` 두 unit을 `-ContinueCampaign`으로 같은 corrected candidate에서 실행한다. Source 수정은 이전 pass를 stale하게 하므로 실제 next pass를 배정하며 횟수 제한을 만들지 않는다.
- correction loop: usable finding이 exact20과 Review·DWM·glossary 도메인 안에서 기존 선택을 정합하게 구현하는 교정이면 worker가 자체 수정·affected-first 재검증·재리뷰한다. Brief·consultation·blind-advisory 등 다른 도메인 확대, 새 설계 선택, 규칙 충돌, semantic-unusable result만 사용자에게 상신한다.
- completion: 결과·finding disposition·검증·미실행 항목·W-18 비소급 경계를 operator report에 기록한다. Per-file SHA/evidence hash 표를 새 계약으로 만들지 않는다.

## Open decision의 close 지점

- Review staleness/no-reviewable 의미는 Batch 1에서 닫는다.
- DWM predicate와 terminal-rule concurrency 조건은 DWM Plan의 Batch 1에서 닫는다.
- Aggregate candidate fitness는 Batch 3의 affected-first 검증과 corrected-state dual에서 닫는다.
- W-18 introducing changeset은 개정 전 DWM이 자기 closeout까지 지배한다. 이번 20경로에는 self-closeout·commit·push·배포가 없고, later landing gate에서도 새 exemption을 W-18에 소급하지 않는다.
- Q-10은 별도 안건이며 이번 batch에 흡수하지 않는다.

## Stage rewind 조건

- Review consumer가 DWM predicate를 복제하거나 project lifecycle rule 없이 file-kind heuristic으로 retirement-only를 판정해야 하면 Design으로 되돌아간다.
- 의미를 구현하려면 새 checker/script/sidecar/hook/automatic stale detection이 필요하면 중단하고 scope 확대를 상신한다.
- Qualified transaction이 새 verdict/pass를 요구하거나 ordinary content change를 review 없이 착륙시키게 되면 Design으로 되돌아간다.
- W-18 자기 closeout에 새 no-reviewable 분기를 적용하려는 경우 중단하고 개정 전 DWM 경계로 되돌린다.
