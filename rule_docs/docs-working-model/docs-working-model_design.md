# docs-working-model: incubation ↔ terminology(glossary) lifecycle 정정 — Design

> 이 Design 은 `docs-working-model` 규칙 변경의 방향성 문서다 — 영구 live 아님. closeout 시 current-bearing 내용이 `docs-working-model.md`(rule = 자기 spec-of-record)로 흡수된 뒤 이 문서·`_plan.md`·`_work_packet.md` 는 retire(삭제, 보존=git history). 이 Design 은 mutation/commit/push 승인이 아니다(1회 진술).

> **★ 열린 thread 갱신 (2026-06-27).** cs1(`40bffd2`)은 *deferred closeout* 상태다 — closeout 요건(candidate 운용검증을 새 모델로 완료 + relay/blind 정규기능화)이 아직 미충족. 그 운용검증(Stage 2 promote dogfood)이 cs1 자기 모델의 **disposal-timing 자기모순**(아래 **batch-3**)을 표면화 → **Stage rewind 로 batch-3 추가**. batch-3 는 cs1 을 닫지 않는다(closeout 요건 불변).

## Header

- **무엇의 Design 인가.** `docs-working-model` 규칙의 *incubation tier ↔ terminology(glossary) lifecycle 결합*을 정정한다. 현 규칙은 "용어 등록"을 incubation 의 하위 절차로 묶고 의미확정을 promotion 에 두어, incubating 후보 인코딩이 glossary 와 lockstep 으로 cross-reconcile 되며 교착(integration 리뷰 3라운드 no/no)을 일으킨다.
- **체인이 끝나면 무엇이 되는가.** `docs-working-model.md` 가 (A) pending 용어 = owner-identity thin reservation, (B) 의미확정 = finalization-owner close(corrected-state review 직전), (C) incubation applicability(default strict + 명시 완화/유지), (D) cross-domain contrast 허용선, (E) transition clause 를 담도록 수정된다. 이후 cs2 에서 격리(stash)된 3 incubation + glossary 후보가 새 규칙에 맞춰 재정렬된다.
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

## batch-3 (추가): promotion 의 incubation 처분 정합 (E4-centered) + closeout 중의성 해소 + state-migration

> cs1 의 deferred-closeout 운용검증(Stage 2 promote dogfood, 2026-06-27)이 cs1 자기 모델의 결함을 표면화 → **Stage rewind**(Design 으로 되돌아 교정). canonical dual review 가 통과시킨(`40bffd2`) latent 결함을 *운용*이 잡음 = dogfood=결함탐지기. **방향은 relay→blind→relay→re-blind 로 검증**: 초기 가설 α(incubation 을 promote 동안 보존·`_work_packet` 이관)는 blind 가 E4·artifact-taxonomy·Work Packet 경계와 **3 hard 충돌**로 *폐기* → **E4-centered 로 flip**, re-blind 가 구조 통과(잔여 = clarity 정제 4건). 이 batch-3 는 cs1 을 *닫지 않으며*(closeout 요건 불변), **Design 도 닫히지 않음**(Plan 에서 안 잡히면 Stage rewind 로 재개).

**결함 (현 규칙 = cs1 산출; orchestration 으로 정밀화).**
1. **"closeout" 중의성 → line-18↔90 외형 모순**: *Document artifact classes* #2 는 `_incubation` 을 **"candidate-lifecycle-scoped"** committed-temporary(closeout 까지)로 두는데, *Incubation tier* 3-state 는 promote 시 `_incubation` 을 Design 작성 전 삭제한다. 실은 **`_incubation` 의 closeout = *candidate* closeout(=promotion/discard)** 이고, 이는 Design/Plan/WP 가 죽는 *promoted-lifecycle* closeout 보다 이르다. 두 closeout 이 한 단어로 뭉개져 외형상 모순처럼 보인다(논리 모순이라기보다 *중의성*).
2. **"absorbed" under-application**: promote 시 `_design` 이 `_incubation` 보다 작아 근거 손실 — 보존경로 부재(gap)가 아니라 **E4 흡수완전성 미적용**. E4 가 *이미* "결론·대안·evidence-type·scope·실패기준·negative-evidence 를 raw link 없이 재검토 가능하게 흡수"를 요구.
3. **closeout 개념 분절**: 처분이 ~5곳(two-level gate / lifecycle absorption-retire / rule_docs idle-return / WP 삭제 / incubation discard)에 흩어져 disposal-timing single home 부재 + *Lifecycle closeout* 체크리스트가 `_incubation` 누락(중의성의 증상 — promoted closeout 시점엔 이미 처분됨).
4. **state-migration 부재**: "이전 revision 미retire 중 새 revision 시작" · "stash 산출물 이관(재사용/재검증/폐기)" 미모델링 — 이 batch-3 의 cs1-점유 placement 가 실증.

**고정 불변식 (메타 순환 차단; orchestration 으로 확정).**
- **artifact-class taxonomy 불변** — `_incubation` 은 *file artifact* 그대로(현 rule 이 artifact 를 document/file 단위로 individuate). "file=state-token, artifact=material" 재해석은 *taxonomy 변경*이라 **폐기**(blind 포착; 고정 조건과 모순).
- 정렬 기준 = "임시 artifact 는 *자기* closeout 에 처분"(per-artifact closeout: incubation=candidate closeout / Design·Plan·WP=promoted-lifecycle closeout / 미promote candidate=discard closeout).

**방향 (E4-centered — relay+blind 검증, α 폐기).**
- **(1) "closeout" 중의성 명시**: candidate closeout(=promotion/discard) ≠ promoted-lifecycle closeout. → line-18↔90 해소 + 체크리스트 `_incubation` 누락 설명.
- **(2) promotion 에서 E4 흡수완전성 강제**: `_incubation` 의 *current-bearing content 전부를 E4 구조로* promoted artifact 에 흡수 → `_incubation.md` 제거(공존 0, E3 유지). 손실=E4 under-application. **raw reference 보존·Work Packet 이관 불요**(Work Packet 은 readiness/decision material 금지).
- **(3) closeout primitive**: disposal-timing single home 호명, 단 per-artifact closeout event 와 file/folder·promote/discard 처분 차이(discard candidate=폴더 전체 삭제 / existing-rule closeout=idle 폴더 유지)는 *보존*(과통합 금지).
- **(4) state-migration (general-minimal)**: 새 revision 시작 시 *같은 role-slot* 의 미retire planning docs 있으면 먼저 disposition / stash·pre-revision 산출물은 판정(재사용/재검증/폐기) 전 non-authoritative. *전역 병행 revision 안 막음*(per-domain/per-rule batch 모델 보존), Stable filename rule·rule_docs purity 와 비충돌(archive/subfolder 0).
- **re-blind refinement (반영)**: 흡수대상=candidate-kind 별(domain→Design/Plan/Spec, 최종 Spec / rule→terminal rule file) · E4=흡수 *요건구조*이지 scope 축소 아님(current-bearing 전부) · "candidate/discard closeout" 명명 정리(discard=candidate closeout 의 variant).

**owner surface (수정 대상 절).** *Document artifact classes* #2 · *Incubation tier*(Candidate lifecycle·3-state) · *Closeout*(two-level gate / lifecycle absorption-retire — `_incubation` 누락 명시) · Work Packet 경계 참조 · **state-migration 신설 절**. (+ 필요시 `docs-working-model-check.ps1` — file/material 재해석 없으니 discriminator 변경 최소.) rule = 자기 spec-of-record(별도 spec 없음).

**non-goals.**
- **workflow-altitude discipline 흡수 안 섞음**(별도 작은 편집 — altitude 자기적용).
- closeout 완전 codify · orchestration 운용모델(b) · promote 재개(c) · disposition rule 승격(d) = 이 stage 밖.
- **cs1 을 닫지 않음**(closeout 요건 불변). **Design 닫지 않음**(Plan rewind 가능). candidate 콘텐츠(stash) 수정 안 함. rejected umbrella 부활 안 함. **taxonomy 변경 안 함**.

**open risks / Plan-readiness (batch-3).**
- **(R6, 갱신)** α 과통합 위험 → **해소**(α 폐기, E4-centered 가 relay+blind 통과). 잔여 = re-blind 4 refinement 를 Plan 에서 정밀 잠금.
- **(R7)** 절 문구 · 흡수완전성 판단 *강도*("closeout 때 판단 가능" 수준 — 약하면 손실/강하면 새 검증머신) · check 변경 = Plan/구현 detail → park(workflow-altitude).
- **(R8, 갱신)** state-migration scope = *같은 role-slot* 한정(전역 아님) — Plan 에서 Stable filename rule·rule_docs purity 대조로 잠금.

## Plan readiness / open risks

Plan 으로 내려가도 됨(방향·경계 확정, 2회 적대평가 수렴). open risks(각 close 예정지):
- **(R1)** `docs-working-model-check.ps1` 가 기존 in-flight glossary 항목에 걸릴 수 있음 → transition-aware 적용. **close = Plan(검사 시점·범위 결정).**
- **(R2)** finalization-before-review ordering 이 기존 `corrected-state Codex review` 규칙·closeout 게이트와 정합해야. **close = 구현 시 규칙 본문 대조.**
- **(R3)** "충돌 가능 이름"/"완화 여부" 판정 모호성 → 최소 기준 + default strict + 중재자(glossary rule owner) 명문화로 닫음. **close = 규칙 본문 (A)/(C).**
- **(R4)** rule candidate closeout 경계(orchestration) ill-defined → "terminal rule 파일 landing changeset 내, exposed pending term 처리 포함" 으로 고정. **close = 규칙 본문 (B).**

## batch-4 (추가): terminology 등록 lifecycle — owner-pending(가등록) 도입

> docs-working-model revision 의 continuation(batch-1 이 이미 incubation↔terminology scope; state-migration "continue the same not-yet-closed-out work" 충족). orchestration(relay-A ×2 → relay-B ×4 → 설계 blind ×4 → 구현 → diff-blind ×3 → canonical dual)로 수렴·검증. cs1 닫지 않음.

**결함 (cs1 모델).** 용어 등록 타임라인이 incubation thin `pending` 과 finalization-owner close finalize 두 점만 규정하고, 그 사이 "finalization-owner 가 이미 live authority 인데 closeout 미완"(=가등록) 구간이 비어, live-but-deferred 용어(이번 revision 의 closeout 2건 — rule 이 commit/push 되어 live·closeout deferred)가 incubation 칸 `pending` 에 오배치됐다.

**방향 (canonical 통과; LC yes-with-risk / SC yes, blocking 0).**
- glossary status 를 **finalization-owner-live 축**으로 `pending`(아직 live 아님) / `owner-pending`(이미 live, finalization deferred)로 분리. pending 내용규칙(thin-vs-fuller)은 *안 건드림*(별도 pre-existing residual; Path 1).
- owner-pending 등록 = finalization-owner go-live(기존-rule revision rule landing / deployed implementation / 기존 live domain sync-required Spec update; 신규 domain Spec 제외; trigger ≠ commit/push 승인). 필드 = one-line meaning + finalization-owner(owner id / tracked path, E2) + facet + close-condition + not-this. monotonic + go-live 오판 정정 예외 + retire-before-close 처리 + rejected 전이(pending/owner-pending 공통) 4-class cross-surface sweep.
- 용어 통일: `owner-surface close` → `finalization-owner close`(이 design/plan/work_packet 의 batch-1 표현도 batch-4 에서 동기화). `finalization-owner` ≠ active-behavior `owner surface`(live Spec 이 finalization-owner 여도 active 격상 아님). `finalization-owner` 를 glossary 에 owner-pending 으로 등록(자기참조 dogfood).
- 이동 = closeout 2건만(finalization-owner=`rules/docs-working-model/docs-working-model.md`, close-condition=deferred 미래 closeout); 나머지 candidate 항목은 pending 유지.

**owner surface.** `terminology-glossary.md`(status·항목) + `docs-working-model.md`(*Terminology registration* 계열 절). rule = 자기 spec-of-record.

**non-goals.** pending thin-vs-fuller residual reconcile(별도 terminology batch) · pre-existing 2 desync(candidate `close=on promotion` / glossary rejected `rule_docs` 의 3-state) 수정 · taxonomy 변경 · candidate 콘텐츠 수정.

**open risk / 상태.** canonical 통과(blocking 0). LC=yes-with-risk 의 risk = 기획서 stale `owner-surface close` 표현 + batch-4 절 부재였고, batch-4 동기화(용어 rename + 이 절)로 해소. cs1 deferred-closeout 유지.
