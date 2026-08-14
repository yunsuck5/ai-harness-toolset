# docs-working-model Design

> 이 문서는 promoted-lifecycle closeout을 내용 검토와 분리해 retirement 행위로 한정하는 W-18 Design이다.
> 이 체인이 끝나면 최종 내용은 corrected-state candidate에서 검토되고, exact retirement-only closeout은 canonical review 대상이 되지 않는다.
> 이 문서는 mutation/commit/push/배포 승인이 아니며, W-18 자기 closeout에는 개정 전 DWM의 비소급 경계가 계속 적용된다.

## 왜 바꾸는가 / 무엇을 바꾸는가

현행 DWM은 의미 reconciliation·owner absorption·reference correction과 planning artifact retire를 모두 closeout 한 단계에 묶고, review 뒤의 모든 source/docs 수정을 일괄 stale 처리한다. 그 결과 내용이 모두 확정된 뒤에도 Design/Plan 삭제와 Spec lifecycle 상태 변경만을 이유로 같은 내용을 다시 검토하게 된다.

변경의 핵심은 readiness와 closeout을 분리하는 것이다. Spec/rule↔implementation 1:1, planning 의미 흡수, inbound reference·orientation·backlog 정정은 최종 corrected-state review 전에 candidate 안에서 끝낸다. closeout은 사용자 승인 뒤 temporary artifact와 lifecycle marker의 물리 상태만 닫는다.

## 선택 의미

1. **내용 단계가 먼저 끝난다.** 최종 candidate는 Design/Plan/선택적 Work Packet, target-state Spec/terminal rule, active owner, 필요한 reference·orientation·backlog 정정을 모두 포함한다. 이 상태가 적용 가능한 validation과 corrected-state review의 대상이다.
2. **retirement-only closeout은 promoted-lifecycle closeout의 좁은 하위 분류다.** candidate promotion/discard/withdrawal에는 적용하지 않는다. 판정 입력은 readiness 뒤에 제안된 closeout transaction 자체의 전체 source delta다.
3. **domain variant의 exact shape**는 같은 owner의 Design·Plan과, 존재했다면 Work Packet을 stable role path에서 완전히 삭제한다. 그 revision의 target-state content가 corrected-state review에 포함된 Spec은 affected Spec이며 marker disposition은 공통 post-transaction 규칙을 따른다.
4. **terminal-rule variant의 exact shape**는 같은 rule owner의 Design·Plan과, 존재했다면 Work Packet을 stable role path에서 완전히 삭제한다. Terminal rule은 변하지 않는다. Retire되는 각 terminal-rule revision별로 final corrected-state reviewed candidate의 actual foreign-Spec thin-interface direct-sync path set과 그 Plan이 aggregate/dependency 목록과 구별해 선언한 foreign-Spec direct-sync target set이 빈 집합까지 정확히 같아야 한다. 누락·stale/false·extra·오지정 declaration은 `not retirement-only`이고, 일치한 set만 affected Spec이다. 이 분류는 foreign meaning ownership을 이전하지 않는다.
5. **affected Spec marker는 transaction 이후 남은 lifecycle로 결정한다.** Proposed transaction의 모든 planning artifact 삭제를 적용한 뒤 그 Spec의 domain-local Design·Plan·Work Packet이 하나라도 남으면 marker와 Spec whole-file을 유지한다. Domain-local lifecycle이 0이라 marker 전이 자격을 판정할 때는 각 surviving open terminal-rule revision의 Plan-declared membership과 current candidate actual membership을 해당 Spec별로 재구성한다. 재구성 불가·모호 또는 두 membership의 불일치가 있으면 현재 transaction은 `not retirement-only`이며 open revision을 reconcile하거나 closeout을 보류한 뒤 재판정한다. 두 membership이 모두 참인 surviving revision이 있으면 marker만 유지한 채 현재 closeout을 끝내지 않고, 그 revision을 같은 transaction에서 함께 retire하거나 먼저 claim을 제거한 뒤 전체 transaction을 재판정한다. Aggregate/dependency scope에만 Spec을 나열해 둘 다 거짓인 revision은 claimant가 아니다. Domain-local lifecycle과 surviving claimant가 모두 0일 때만 유일한 `**prelive**` 또는 `**sync-required**` marker를 `**live**`로 반드시 한 번 치환한다. 여러 claimant revision을 한 transaction에서 retire할 때도 같은 post-state를 한 번 계산한다.
6. 추가·rename·copy·다른 수정, source-managed untracked path, README/backlog/reference/active-owner 수정, 공통 규칙이 요구한 Spec marker 외 문면 변경이 하나라도 섞이면 retirement-only가 아니다. 그 변경을 candidate 단계로 되돌려 내용 변경으로 검증·review한다.
7. exact shape를 충족한 closeout에는 새 target-state meaning이 없다. 기존 corrected-state review는 stale해지지 않고, review workflow는 pass를 만들지 않은 caller-side `no-reviewable-change`만 보고한다.
8. closeout은 적용 가능한 실사용·검증과 최종 corrected-state review를 거친 candidate에 대해 사용자가 명시 승인하는 lifecycle 행위다. 이 승인은 commit/push/배포 권한을 대신하지 않는다.

## Owner surface model

- `rules/docs-working-model/docs-working-model.md`는 retirement-only의 단일 의미 owner다. exact predicate·candidate rewind·사용자 closeout gate를 소유하되 새 checker나 automatic stale detector를 만들지 않는다.
- DWM package의 Design/Plan/Spec templates와 Plan/Spec/closeout checklists는 최종 review 전 absorption, direct-sync-set reconciliation, marker-only closeout 저작 경계를 직접 반영한다.
- `rules/terminology-glossary.md`는 `retirement-only closeout`의 한 줄 채택 의미만 소유하고 전체 predicate는 복제하지 않는다. `rule_docs/terminology-glossary/`의 Design/Plan이 이번 다섯 term meaning delta를 owner-local하게 승인한다.
- root `AGENTS.md`/`CLAUDE.md`는 repo source/docs gate에서 DWM-qualified closeout을 blanket stale 문구에서 제외한다.
- 배포 review SKILL은 project rule이 exact shape를 정의하고 현재 transaction이 이를 충족할 때만 `no-reviewable-change`로 처리하는 portable interface를 소유한다. DWM의 repo-only 전체 semantics를 배포 payload에 복제하지 않는다.
- `docs/review/review_spec.md`는 review 도메인의 staleness target state와 DWM interface를 명세하며, behavior authority를 흡수하지 않는다. 사용자 가이드는 같은 운용 의미를 설명한다.
- `docs/review/review_design.md`와 `docs/review/review_plan.md`는 review 도메인의 staleness/no-reviewable 선택과 consumer 배치를 소유한다. DWM Plan은 aggregate dependency를 조정할 뿐 이 foreign behavior를 승인하지 않는다.
- 기존 review-input test는 SKILL의 좁은 no-reviewable/stale 분기를 회귀 고정한다. DWM checker는 transaction diff를 자동 판정하지 않는다.

## 수정 대상

- DWM planning: 이 Design과 `docs-working-model_plan.md`.
- DWM owner/forms: terminal rule, Design/Plan/Spec templates, Plan/Spec/closeout checklists.
- 공용 용어 owner-local lifecycle: terminology-glossary Design/Plan과 terminal rule.
- review owner-local lifecycle과 소비 표면: Review Design/Plan, root instruction mirror, review SKILL, review Spec, 사용자 가이드, 기존 SKILL contract test.

## 하지 않을 것 (non-goals)

- 모든 post-review source/docs 변경의 staleness를 완화하지 않는다.
- candidate-lifecycle closeout, promotion/discard/withdrawal을 retirement-only로 분류하지 않는다.
- 새 script·checker mode·schema·sidecar·hash/mtime binding·automatic stale detector·CI gate를 만들지 않는다.
- per-file SHA 표, preimage blob 표, evidence hash 봉인을 새 계약으로 만들지 않는다.
- Q-10과 다른 roadmap 항목, backlog 정리를 흡수하지 않는다.
- W-18의 commit/push/배포 또는 자기 closeout 적용 방식을 선결정하지 않는다.

## Trade-off와 반례

marker line 전체 변경을 허용하면 durable 의미를 closeout에 숨길 수 있으므로 token 한 개 치환만 허용한다. filename suffix만 보고 삭제를 허용하면 foreign/live 문서를 잘못 처분할 수 있으므로 active lifecycle이 소유한 stable-role path의 exact set만 허용한다. Pre-transaction sole-Plan 조건은 domain↔terminal 조합의 조기 `live`와 multi-Plan aggregate의 `sync-required` 고착을 막지 못하고, aggregate scope mention까지 claimant로 세면 실제 direct sync를 하지 않은 마지막 Plan 때문에 종료 순서가 결과를 바꾼다. Actual direct-sync set과 declared target set의 교집합만 affected로 삼아도 누락·허위·과잉 선언이 조용히 사라지므로, retire되는 revision별 exact-set equality를 먼저 요구한다. 이 equality를 retire되는 revision에만 적용한 채 surviving revision의 선언만 세면, surviving candidate의 undeclared actual sync가 marker claimant에서 빠져 조기 `live`가 가능하다. 반대로 surviving revision의 선언과 actual sync를 단순 합집합으로 claimant 처리하면 declaration-only 또는 actual-only 상태가 다른 closeout의 marker를 유지시킨 뒤 철회될 때 marker를 해제할 actor가 사라진다. 두 membership을 일치시켜도 true/true claimant를 남긴 채 다른 closeout을 끝내고 그 claimant가 나중에 false/false로 함께 철회하면 같은 actor 소실이 재발한다. 따라서 domain-local lifecycle이 0인 affected Spec은 surviving membership을 재구성·일치시킨 뒤 true/true claimant가 하나라도 있으면 현재 closeout을 완료하지 않고 같은 transaction에 포함하거나 claim 제거 뒤 재판정한다. post-state에서 domain-local lifecycle과 surviving claimant가 모두 0일 때만 marker를 전이한다. exact transaction shape는 planning 의미 흡수 여부를 증명하지 않으므로, 그 semantic 책임은 candidate readiness와 corrected-state review에 남긴다.

과거 closeout은 lifecycle 설명 문장까지 바꾼 사례가 있어 새 exact shape에 맞지 않을 수 있다. 비소급 원칙에 따라 과거 착륙을 뒤집지 않으며, 다음 lifecycle부터 Spec의 marker 외 prose를 candidate 단계에서 final·state-independent하게 작성한다.

## Plan readiness / open risks

방향 결정은 닫혔다. DWM·Review·glossary Plan은 owner-local 선택을 분리한 exact 20-path aggregate scope, affected-first validation, same-campaign final dual, W-18 자기개정 비소급과 별도 landing gate를 고정한다. 사용자 직접 재정으로 DWM Plan checklist 1경로가 추가됐다. Review·DWM·glossary 밖의 Brief·consultation·blind-advisory 등 다른 도메인 source mutation이나 새 checker·script가 필요하면 즉시 멈추고 보고한다.
