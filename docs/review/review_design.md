# review Design

> 이 문서는 W-18에서 review workflow가 `retirement-only closeout`을 소비하는 방식과 staleness 경계를 정하는 review-domain Design이다.
> DWM은 lifecycle transaction의 exact predicate를 소유하고, review 도메인은 그 결과를 `no-reviewable-change` 또는 ordinary stale review로 분기하는 thin interface만 소유한다.
> 이 문서는 mutation/commit/push/배포 승인이 아니며, W-18 자기 closeout에는 개정 전 DWM의 비소급 경계가 계속 적용된다.

## 왜 바꾸는가 / 무엇을 바꾸는가

현재 review staleness 문면은 review 뒤의 모든 source/docs 변경을 일괄 stale로 취급한다. 이 문면은 최종 content-bearing candidate가 이미 검토된 뒤 temporary Design/Plan을 삭제하고 lifecycle marker token만 전이하는 transaction까지 새 review target으로 만들 수 있다. 그 결과 새 target-state meaning이 없는 retirement 행위에 canonical pass와 verdict가 반복된다.

변경의 목적은 일반 staleness를 완화하는 것이 아니다. Applicable project lifecycle rule이 exact transaction shape를 정의하고 proposed closeout 전체 delta가 그 predicate를 충족하는 경우에만 review workflow가 `no-reviewable-change`로 보고한다. 조건을 하나라도 벗어나면 내용 변경을 candidate 단계로 되돌려 ordinary stale/corrected-state review를 적용한다.

## 선택 의미

1. **Review 도메인은 reviewability만 판정한다.** retirement-only의 자격·exact source-delta predicate·candidate rewind·사용자 closeout gate는 project lifecycle rule이 소유한다. Review SKILL과 Spec은 그 predicate를 복제하지 않고 적용 가능한 rule의 qualification 결과만 소비한다.
2. **Exact qualification에는 새 pass가 없다.** 최종 content readiness와 corrected-state review가 끝난 뒤 제안된 transaction 전체가 applicable rule의 retirement-only predicate와 일치하면 reviewed target-state meaning이 변하지 않는다. Review workflow는 prepare/run을 호출하거나 verdict를 발급하지 않고 caller-side `no-reviewable-change`만 보고한다.
3. **Predicate miss는 ordinary change다.** Applicable predicate가 없거나 적용할 수 없거나 extra path·byte·mode·source-managed untracked delta가 있으면 content-bearing correction으로 candidate 단계에 되돌린다. 기존 pass는 영향에 따라 stale 처리하고 corrected candidate를 review한다. Closeout pass로 predicate miss를 정당화하지 않는다.
4. **일반 staleness는 유지한다.** Review-bound source-managed artifact set이 달라지거나 reviewed artifact의 source-managed bytes/content·path·Git mode·target-relevant meaning이 바뀌면 계속 stale 대상이다. Validation evidence bundle 자체의 변경은 freshness binding이 아니며, 잘못된 claim·citation·count나 누락된 known concern은 active retraction·stale-by-omission 규율을 따른다. Retirement-only 분기는 모든 post-review edit의 예외가 아니라 project rule이 좁게 정의한 terminal transaction에만 적용된다.
5. **권한과 진위 보증은 확대하지 않는다.** Predicate 충족은 user approval·commit·push·배포 권한을 만들지 않고, review log나 source tree를 tamper-proof하게 증명하지 않는다. 새 hook·deny gate·hash/mtime binding·sidecar·자동 stale detector를 만들지 않는다.
6. **W-18에는 비소급이다.** 새 reviewability 분기는 다음 qualified lifecycle부터 적용한다. 이 정의를 도입하는 W-18 changeset의 자기 closeout은 개정 전 DWM이 지배하며, 이번 candidate 범위에는 그 closeout·commit·push가 포함되지 않는다.

## Owner surface model

- `docs/review/review_spec.md`는 ordinary staleness와 project-rule-qualified retirement-only interface의 review-domain target state를 명세한다.
- `snippets/claude-skills/ai-harness-review/SKILL.md`는 operator point-of-use에서 exact qualification이면 prepare/run을 생략하고 `no-reviewable-change`를 보고하며, miss이면 ordinary stale/re-review로 되돌리는 portable behavior를 소유한다.
- root `AGENTS.md`/`CLAUDE.md`는 repo source/docs gate에서 같은 thin interface를 공유한다. 두 파일의 shared body는 byte-identical하게 유지한다.
- `user_guide/review-system_ko.md`는 사용자 운용 설명만 소유하고 predicate의 단일 owner가 아니다.
- `tests/review-input-verify.Tests.ps1`는 SKILL의 좁은 no-reviewable/stale 분기를 회귀 고정한다.
- `rules/docs-working-model/docs-working-model.md`와 그 lifecycle Design/Plan은 retirement-only predicate를 소유한다. 이 Review Design/Plan은 그 rule 의미를 승인하거나 재정의하지 않고 aggregate candidate의 foreign consumer 정합만 소유한다.

## 하지 않을 것 (non-goals)

- Review-bound artifact set/source-managed bytes/content/path/Git mode/target-relevant meaning 변경의 일반 staleness를 완화하지 않는다.
- candidate promotion/discard/withdrawal이나 일반 docs-only 수정을 `no-reviewable-change`로 분류하지 않는다.
- DWM 문서를 review runtime dependency로 만들거나 repo-only predicate를 배포 SKILL에 복제하지 않는다.
- 새 script·checker·schema·sidecar·hook·deny rule·hash/mtime binding·automatic stale detector를 만들지 않는다.
- review 횟수 상한, verdict 유도, automatic retry/fix loop를 만들지 않는다.
- W-18의 self-closeout·commit·push·deploy 또는 Q-10을 이번 candidate에 포함하지 않는다.

## Trade-off와 반례

문서 삭제라는 파일 종류만 보고 면제하면 content-bearing 수정이나 잘못된 owner artifact 삭제를 숨길 수 있다. 반대로 모든 삭제와 marker 전이를 stale로 보면 이미 검토된 내용을 같은 이유로 반복 검토한다. 따라서 review 도메인은 자체 heuristic을 만들지 않고 applicable project lifecycle rule의 exact whole-transaction predicate에만 의존한다. Predicate가 성립하지 않으면 closeout review를 추가하는 것이 아니라 content correction을 candidate 단계로 되돌린다.

이 분기는 tampering을 불가능하게 만드는 보안 장치가 아니다. 사용자가 review 뒤 bytes나 log를 임의 수정할 수 있다는 사실은 reviewability 분기를 더 넓은 surveillance/hardening 계약으로 확장할 근거가 되지 않는다. 권한·진위·변경 추적의 별도 강화는 별도 안건에서 결정한다.

## Plan readiness / open risks

방향 결정은 닫혔다. Plan은 W-18 aggregate 20-path candidate에서 Review·DWM·glossary owner-local scope를 분리하고, affected-first validation과 same-campaign corrected-state dual을 고정한다. 이 세 도메인 안의 usable review finding은 worker가 수정·재검증·재리뷰할 수 있으며, Brief·consultation·blind-advisory 등 다른 도메인 확대나 새 가치판단·semantic-unusable review가 필요할 때만 중단하고 상신한다. Work Packet은 만들지 않는다.
