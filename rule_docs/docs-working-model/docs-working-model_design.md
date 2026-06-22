# docs-working-model: incubation ↔ terminology(glossary) lifecycle 정정 — Design

> 이 Design 은 `docs-working-model` 규칙 변경의 방향성 문서다 — 영구 live 아님. closeout 시 current-bearing 내용이 `docs-working-model.md`(rule = 자기 spec-of-record)로 흡수된 뒤 이 문서·`_plan.md`·`_work_packet.md` 는 retire(삭제, 보존=git history). 이 Design 은 mutation/commit/push 승인이 아니다(1회 진술).

## Header

- **무엇의 Design 인가.** `docs-working-model` 규칙의 *incubation tier ↔ terminology(glossary) lifecycle 결합*을 정정한다. 현 규칙은 "용어 등록"을 incubation 의 하위 절차로 묶고 의미확정을 promotion 에 두어, incubating 후보 인코딩이 glossary 와 lockstep 으로 cross-reconcile 되며 교착(integration 리뷰 3라운드 no/no)을 일으킨다.
- **체인이 끝나면 무엇이 되는가.** `docs-working-model.md` 가 (A) pending 용어 = owner-identity thin reservation, (B) 의미확정 = owner-surface close(corrected-state review 직전), (C) incubation applicability(default strict + 명시 완화/유지), (D) cross-domain contrast 허용선, (E) transition clause 를 담도록 수정된다. 이후 cs2 에서 격리(stash)된 3 incubation + glossary 후보가 새 규칙에 맞춰 재정렬된다.
- **이 문서가 아닌 것.** glossary lifecycle 전면 first-class 재구조화 아님 · 완전 apply/relax matrix 정식화 아님(둘 다 deferred) · candidate 콘텐츠(consultation/blind/orchestration 본문) 수정 아님(cs2) · mutation/commit/push 승인 아님.

## 왜 바꾸는가 / 무엇을 바꾸는가

**문제(현행 규칙).**
1. **False coupling.** `Mandatory terminology registration` 이 *Incubation tier 섹션의 하위 bullet* 로 박혀 있어 규칙이 "용어집 변경 ⟸ incubation" 으로 묶는다. 그러나 glossary 변경 source 는 다양하다(기존 기능/rule 개선 · 순수 운용개념 변화 · rejected term 추가 · accepted owner-boundary 조정 · 명명 정리). 용어집은 독립된 중립 표면이어야 한다.
2. **Finalization 오배치.** 규칙은 용어를 "promotion 시 확정" 한다. 그러나 같은 규칙의 *Spec identity* 상 Spec 은 **closeout(구현과 1:1 sync)에서야 live authority** 를 가진다(그 전엔 청사진). 의미를 담을 Spec 이 초안인데 용어가 먼저 확정되는 모순. 게다가 현 문장 안에 "promotion 확정"·"promotion·discard 확정"·"아무 때나 decouple" 세 타이밍이 정리 안 된 채 공존.
3. **귀결 = 교착.** incubating 후보 3개를 인코딩하는데 integration 리뷰가 "glossary second owner"·"cross-domain restatement" 를 반복 차단. 닫힌 정규 도메인 strictness 를 *incubating* 후보에 적용한 데서 옴.

**변경(핵심 포함 항목 — 2회 적대평가 수렴 반영).**
- **(A) glossary 상태별 역할 명문화.** accepted = 용어 의미의 single home(+절차는 owner surface pointer) — *불변*. pending = **owner-identity reservation**(name · owner · facet · not-this · promotion-target · 고정형식 collision-note; **경로 pointer·의미정의 0**; E2 준수). 후보 밖 노출/충돌 가능 시 **조건부 required**(trigger: candidate 밖 tracked surface 사용 · accepted/pending/rejected 와 동일·혼동 · identity 이름이 broad bucket 오해가능 · 2+ candidate 가 다른 의미로 사용; 내부 label·임시 phase·nickname 은 미등록; 애매하면 thin 예약하되 의미금지; 중재 = glossary rule owner).
- **(B) 의미확정 timing.** 확정(accepted/rejected/owner-boundary) = owner surface final state → glossary 반영 → **corrected-state review → 승인 → commit**(확정을 review *뒤*에 두지 않음 — review stale 방지). candidate 종류별: domain = Spec/impl closeout changeset 내 / rule = terminal rule 파일 landing changeset 내(+그 rule 의 exposed pending term 처리; terminal rule 파일 = owner surface) / 비-candidate 용어정리 = 그 변경 자체의 corrected-state review 내. "promotion 시 확정" 폐기, "아무 때나 decouple" tighten.
- **(C) incubation applicability(최소 guardrail; default = strict).** 강하게 적용 = public-safe · durable-pointer 금지 · 위치/파일명 · non-authoritative 명시 · owner/review-date/discard · E1~E5 · 기존 도메인 혼동방지. **요구 금지** = closeout 1:1 sync · accepted-term do-not-repeat 엄격 · production polish · final terminology. **유지 필수** = promote/discard 판정에 필요한 identity·scope·not-this·contrast·discard evidence. 매트릭스에 *없는* 규칙은 strict; 새 완화는 표 변경 자체를 리뷰. (명칭 = `exception zone` 아니라 `incubation applicability` — 과권한 오해 방지.)
- **(D) contrast 허용선(foreign semantics pointer-only).** *허용되는 blocker* = 후보가 타 도메인 lifecycle/status/authority/normative behavior 를 독립적으로 읽히게 서술 · contrast 부족으로 closure/discard 판정불가 · pointer 없는 foreign 설명 · foreign semantics 고쳐쓰기/축약정의. *금지되는 blocker* = incubation 후보에 final terminology·accepted do-not-repeat 엄격·production polish·타 후보 완전복제 요구. 허용 예 = "consultation is not review" / "blind removes framing, consultation provides it" / "issues no verdict". 차단 예 = 타 도메인 status vocabulary 전체 반복 · 전역 self-attestation("이 문서는 X 재서술 안 함") · source 없는 foreign schema/field/절차 독립정의. (결함 잡기는 유지; foreign definition *더 쓰라*는 요구만 금지.)
- **(E) transition clause.** 새 규칙은 현 in-flight 후보(consultation/blind/orchestration)에 *정리 방향*으로 적용하되, 과거 미등록/비정합을 결함으로 보지 않는다.
- **(F) 잡정리(규칙 텍스트).** seed-install 부활 금지 → `incubation anchoring` 고정. owner-boundary 는 status(accepted/pending/rejected) 아닌 별도 필드/closeout 조건. 후보 간 관계는 `depends-on/contrasts-with/independent-of` 얇은 타입 + foreign semantics pointer-only(discard 독립성 보존).

## Owner surface model

- `docs-working-model.md`(rule, 자기 spec-of-record) = lifecycle · terminology-registration · incubation applicability · contrast 경계의 *규칙(class/invariant/timing/boundary)* 소유. behavior 를 흡수하지 않고 timing·boundary·class 만 명명.
- `terminology-glossary.md` = 용어 *의미*의 home(accepted) + pending reservation registry. 그 자신은 mutation/commit 승인 없음(route-only).
- candidate 콘텐츠의 의미 home = 각 incubation 문서(incubating 동안) → promote 시 spec/rule(active surface). glossary 는 owner-identity 로만 가리킨다(경로 아님).
- (옵션) `scripts/docs-working-model-check.ps1` = 구조 invariant 의 mechanical 검사 — 새 규칙 검사는 transition-aware 로, in-flight 후보에 소급 실패하지 않게 적용.

## 수정 대상

`docs-working-model.md` 의 — **Incubation tier** 의 `Mandatory terminology registration` bullet(false coupling · finalization · transition) · `Form early, authority late` 인접(applicability) · **Spec identity** 의 finalization 함의 정합 · **Cross-domain semantics restriction** 의 incubation 적용(contrast 허용선). (+ 필요 시 `docs-working-model-check.ps1`.) **candidate 콘텐츠 4파일은 이 changeset 에서 미수정**(stash 격리, cs2).

## 하지 않을 것 (non-goals)

- glossary 를 "definition owner 아님" 으로 *전면* 재정의 안 함 — accepted term 의 의미 home 은 glossary 유지(over-correction 방지).
- 완전 apply/relax matrix · glossary lifecycle 전면 first-class 재구조화 = **deferred**(재리뷰 후 남으면). scope-creep 차단.
- candidate 콘텐츠 수정([C] consultation 86↔105 · blind evidence 표현 · orchestration 무결) = **cs2 별도 changeset**.
- source-pointer 를 `_incubation.md` 경로 durable pointer 로 두지 않음(E2; owner-identity 만).
- rejected umbrella(architecture / policy / instruction-surface / evidence / managed-block 등) 부활 안 함.
- mutation/commit/push/release 승인 아님.

## batch-2 (추가): rule_docs 모델 일반화 + 3-state check

> 세션 중 사용자 지시로 cs1 에 추가된 두 번째 coordinated 변경. 동기: 이 cs1 작업 중 rule 기획서를 `rules/`(산출물 자리)에 *실제로 오배치*했고 사용자가 잡았다 — text-only placement 규칙이 skip-prone 함을 실증. relay b + blind 로 조율, 재조율에서 Codex 가 ephemeral 권고를 **persistent-.gitkeep** 로 번복(경험적 반론 + checkability 통찰).

- **왜/무엇.** `rule_docs/` 를 *candidate-incubation 전용*에서 **rule 개정/추가의 in-repo 기획 workspace**(per-rule persistent 폴더, 3-state: idle=`.gitkeep` / candidate=`_incubation.md` / active=`_design`/`_plan`/`_work_packet`)로 일반화. 기획서는 작업 중 commit+push, closeout 시 삭제, 폴더는 `.gitkeep` 으로 잔존. `docs-working-model-check.ps1`(+tests)가 이 구조를 강제.
- **Owner surface.** `docs-working-model.md`(규칙 = 모델 정의) + `docs-working-model-check.ps1`(기계검사). 산출물은 `rules/<rule>/<rule>.md` 또는 `snippets/rules/<rule>.md`(rule = 자기 spec-of-record, rule_docs 에 spec 없음).
- **하지 않을 것.** rule_docs 에 정규 spec-doc 두지 않음(rule stale 리스크 — 사용자 반대) · persistent `.gitkeep` 은 *rule-defined anchor*이지 rejected ad-hoc dead/archive/bucket 폴더가 아님 · 1:1 rule-bound(broad bucket 부활 금지) · glossary `rule-candidate incubation` 항목 재정렬은 cs2.
- **open risk.** **(R5)** rule_docs bullet(폴더 persist) ↔ 기존 Candidate lifecycle bullet(폴더 fate) 정합 필요 + check E3 ↔ active-state 공존 정합. **close = 규칙 본문 + check ↔ canonical 재리뷰.**

## Plan readiness / open risks

Plan 으로 내려가도 됨(방향·경계 확정, 2회 적대평가 수렴). open risks(각 close 예정지):
- **(R1)** `docs-working-model-check.ps1` 가 기존 in-flight glossary 항목에 걸릴 수 있음 → transition-aware 적용. **close = Plan(검사 시점·범위 결정).**
- **(R2)** finalization-before-review ordering 이 기존 `corrected-state Codex review` 규칙·closeout 게이트와 정합해야. **close = 구현 시 규칙 본문 대조.**
- **(R3)** "충돌 가능 이름"/"완화 여부" 판정 모호성 → 최소 기준 + default strict + 중재자(glossary rule owner) 명문화로 닫음. **close = 규칙 본문 (A)/(C).**
- **(R4)** rule candidate closeout 경계(orchestration) ill-defined → "terminal rule 파일 landing changeset 내, exposed pending term 처리 포함" 으로 고정. **close = 규칙 본문 (B).**
