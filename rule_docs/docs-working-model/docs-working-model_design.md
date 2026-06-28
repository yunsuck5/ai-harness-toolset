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

## Phase 1: 규칙 candidate-agnostic settle — P0 고정 불변식 + DAG (5-D/5-K/5-B/5-G/5-X/5-T/5-E)

> **roadmap Phase 1** = `docs-working-model` 규칙을 *임의 candidate 의 일반 lifecycle* 로 전부 settle 한 뒤 freeze 하는 단계다. 동기 = **규칙↔후보 양방향 순환**(후보가 규칙/용어에 묶여 promote 막힘 ↔ 규칙/용어 변경이 후보를 stale 로 만듦)을 **phase 경계로 끊는다**. Phase 1 은 *규칙만* settle 하고 **후보 문서(consultation/blind/orchestration)는 미터치**(realign 은 Phase 2 cs2 의 단방향 1회 conform). 운용방식 = **mode-2**(Claude-first 작업 → batch/phase 경계에서만 Codex 오케스트레이션). 이 절은 batch-1~4 와 같은 cs1 revision 의 continuation 이며 cs1 을 닫지 않는다.

### P0 — 고정 불변식 선언 (Phase-1 전체 frozen; batch 상호 재litigate 차단)

> Phase-1 의 여러 규칙 batch(5-K…5-E)가 *서로* 같은 토대를 다시 흔들지 않도록, 아래 불변식을 **개정 전 고정 선언**한다(normative-design 「메타 자기참조 순환 → 고정 불변식 선언」 + batch-3 「고정 불변식」의 Phase 확대). Phase-1 batch 는 이 불변식을 **전제로 그 위에 쌓을 뿐**, 그 자체를 재정의하지 않는다. 불변식 변경이 필요하다고 판단되면 그것은 batch 내 ad-hoc 수정이 아니라 *명시 Stage rewind*(이 P0 선언으로의 되돌림)다.

- **P0-1 artifact-class taxonomy 불변.** 5 document artifact classes 와 그 file 단위 individuation 은 불변. `_incubation` / `_design` / `_plan` / `_spec` / `_work_packet` 은 각각 *file artifact* 그대로다 — "file = state-token, artifact = material" 식 재해석은 *taxonomy 변경*이라 금지(batch-3 고정 불변식 계승). 5-K 가 만지는 것은 이 artifact 들의 *전이 시점/처분*이지 그 individuation 이 아니다.
- **P0-2 single-home-plus-pointers 불변.** 모든 fact 는 정확히 하나의 authoritative home, 나머지는 pointer(복사 금지). 통합 단위는 *좁게* 유지(normative-design 과통합 가드 — 분리 시 맥락 잃는 것만 묶고, 별개 사실은 별개 home).
- **P0-3 active-surface = authority 불변.** rule 은 자기 spec-of-record(별도 `_spec` 금지), `docs/**` 는 load-bearing authority 아님(root *Final hard rule*). Phase-1 산출은 모두 `docs-working-model.md` 규칙 본문(+필요 시 check/tests/template/README)이며 어떤 `docs/**` 페이지에도 behavior 를 위임하지 않는다.
- **P0-4 E1~E5 정신 불변.** discovery = promoted canonical artifact only(E1) · canonical→candidate durable reference 금지(E2) · *incubation 중* canonical sibling 금지(E3) · 흡수 = raw link 없이 재검토 가능한 형식(E4) · incubation-tier 추가는 one-time bootstrap(E5). **5-K 는 E3 를 transition-aware 로 *정밀화*하되 그 정신("incubation 중에는 sibling 없음")은 불변** — 정밀화는 "incubation 의 *끝*(=swap)이 어디냐"를 고정하는 것이지 E3 완화가 아니다.
- **P0-5 batch-1~4 landed 모델 불변.** conditional terminology registration(batch-1) · rule_docs 3-state(batch-2) · closeout 중의성 해소 = candidate-lifecycle ≠ promoted-lifecycle ≠ discard, 각 임시 artifact 는 *자기* closeout 에 처분(batch-3) · `pending`/`owner-pending`(가등록) finalization-owner-live 축(batch-4). Phase-1 batch 는 이들을 *재litigate 하지 않고* 그 위에 정합한다.
- **P0-6 candidate-agnostic 불변.** Phase-1 규칙은 *임의 candidate 의 일반 lifecycle* 로만 settle 한다 — 특정 후보(consultation/blind/orchestration) 본문 내용에 규칙을 굽히지 않으며, 후보 문서를 이 phase 에서 편집하지 않는다(순환 차단). 후보 고유 정합은 Phase 2(cs2)에서 *규칙 → 후보* 단방향으로 conform.

### Phase-1 DAG (방향 선언만 — detail 은 각 batch 자기 단계에서 lock)

> 아래는 *순환 아님*(DAG) — **item-label + 의존성**만 선언한다. 구체 **batch 번호·실행순서는 Plan 소관**("Plan — batch order"; Design 에 번호 박으면 그 자체가 altitude 누수). 이 선언은 **direction-level** 이며 각 item 의 detail 은 그 item 의 Plan/Work Packet 에서 잠근다(detail front-load 금지). 이번 산출은 **5-D + 5-K + 5-B 의 direction-level Design** 까지이고, 5-G/5-X/5-T/5-E 는 후속 phase-iteration 에서 동형으로 설계한다.

- **5-D (foundational; 가장 이른 settle)** — lifecycle artifact 별 *content/altitude 할당* + 계층-횡단 *detail-flow* 원칙. Design 에 content/altitude 경계 부여(현재 Plan/Spec/WP 만 경계 보유) + "각 계층 자기 altitude·detail 흘러내림·구현직전 확정(domain=Spec / rule_docs=rule 파일, Spec 없음)" 명문화. **dogfood 산**(이번 Design 의 altitude-drift 가 이 gap 의 표면화). 모든 lifecycle 문서 작성법을 규정하므로 *토대* — 5-K 보다 앞/병렬. **(이 Design 본체 #1 — 아래.)**
- **5-K (keystone)** — promotion-transition atomicity(transition event vs promoted lifecycle; E3/E4 를 *entry promoted artifact* 기준으로 고정; + transient 봉합 fallback 한 줄). **(이 Design 본체 #2 — 아래.)**
- **5-B (5-K 뒤)** — swap 이 낳는 promoted-but-not-live 상태머신: 상태 marker · 2층 discovery(governance vs implementation-authority) · de-promotion(history-preservation 축) · open-Q routing. 상태가 swap 산출이라 5-K 의존. **(이 Design 본체 #3 — 아래.)**
- **5-G (5-K 와 병렬, 독립)** — terminology-registration 스키마(rule "thin/use-only-these" ↔ glossary fuller; `close=on promotion` 정정; promotion 시 owner dangling; single-home "governed elsewhere" 미명명). rule↔glossary **cross-surface**. → 별도 item.
- **5-X (5-B 뒤)** — promoted canonical → still-incubating sibling 참조 규칙 + 3후보 promotion *순서*(상호 name-ref = E2 순환). 상태/discovery 모델 의존. → 별도 item.
- **5-T (5-K 뒤)** — 글로벌 `snippets/rules/` universal-core ↔ project-residue split(orchestration 배포용; repo-only 후보 name-ref·codex-binding 혼재). → 별도 item.
- **5-E (같은 settle-pass 끝)** — enforcement: `docs-working-model-check.ps1`(E2 스캔 `snippets/` 제외 false PASS·transition-awareness 미구현) + tests + checklists(5-D altitude-게이트 포함) + templates. 규칙 본문 settle 후 그 위에서 기계화. → 별도 item.
- **의존 요약(DAG):** 5-D → 5-K → 5-B → 5-X; 5-G 는 5-K 와 독립 병렬; 5-T 는 5-K 뒤; 5-E 는 본문 settle 후 최후. (batch 번호 부여·세부 순서 = Plan.)
- **★ SPLIT lock (이 Design 의 결정 — 사용자 2026-06-28; triangulation 의 JOIN 권고를 phase-경계 relay-B 적대검증으로 *뒤집음*):** 5-K 와 5-B 를 **분리**한다(한 item 으로 JOIN 안 함). 근거 = (a) transient 는 5-K 에 *보수적 fallback 한 줄*("post-swap pre-live 상태는 기존 *Spec identity* time-phasing[writing-completion blueprint → implementer reference → closeout live]을 따른다")로 **봉합** 가능 → 모순 아님, 덜-명시일 뿐 → 5-B 가 이후 명시 상태로 승격 (b) **atomicity(5-K)와 state-marker(5-B)는 분리 가능한 별개 관심사**(relay-B 추가지적: atomicity 는 E3-intact 보장에만, "상태"는 marker 의 책임 — SCM-mechanic 에 lifecycle semantics 과적재 금지) (c) normative-method §2(통합단위 좁게) (d) 5-B 의 discovery 위험(prelive 가 live 로 오소비)을 clean 한 5-K 와 *격리*. = over-join 회피.

## 5-D: lifecycle artifact 별 content/altitude 할당 + detail-flow 원칙 — Design (direction-level)

> Phase-1 의 *토대* item(가장 이른 settle). **dogfood 산** — 이번 5-K/5-B Design 작성 중 발생한 altitude-drift(Design 에 구현-detail front-load)가 이 규칙 gap 을 표면화(batch-3 가 운용으로 disposal 자기모순을 잡은 것과 같은 패턴: dogfood=결함탐지·설계=결함해결). **direction-level** — 정확 문구·절 배치는 Plan/WP. **rule 미편집.**

### Header
- **무엇의 Design 인가.** lifecycle 문서(Design / Plan / Work Packet / Spec)가 *각각 무엇을·어느 altitude 로* 담는지의 규칙 gap 을 메운다. 현 규칙은 **Plan**("approval-target only, not a work memo") · **Spec**("must not contain …") · **Work Packet**(content boundary)에는 경계를 주지만 **Design 에는 content 나열만 있고 altitude 경계가 없다**; 또한 *계층을 횡단하는* "detail 흘러내림·구현직전 확정" 원칙이 명문화돼 있지 않다.
- **체인이 끝나면 무엇이 되는가(방향).** 규칙이 (1) **Design 에 content/altitude 경계**를 부여하고(Design = 방향 정렬: why/what/owner-surface/non-goals/which-spec; round-scoped 분석·정확 문구·enumeration·절차·mechanic 은 *담지 않음* — Plan+WP/Spec), (2) **계층-횡단 detail-flow 원칙**을 명문화한다(각 계층은 자기 altitude 만, detail 은 다음 계층으로 단계 확정, *구현 직전* 최종 확정 계층에서 잠금 — domain=Spec / rule_docs=terminal rule 파일[Spec 없음]).
- **이 문서가 아닌 것.** 기존 Plan/Spec/WP 경계 재정의 아님(Design 경계 신설 + 횡단원칙) · Proportionality rule 대체 아님(다른 축) · checklist 기계화 아님(5-E) · 후보 미터치 · taxonomy 변경 아님(P0-1) · 별도 `_spec.md` 아님(P0-3) · mutation/commit/push 승인 아님.

### 결함 (방향 수준 — 왜 바꾸나; dogfood)
1. **Design 에 altitude 경계 부재.** Plan/Spec/WP 는 "무엇을 담지 않는가"가 규칙에 있으나 Design 은 content 나열(why/what/owner/non-goals)만 — "Design = 방향, detail 은 아래로"가 규칙에 없어 작성자가 Design 에 구현-detail 을 front-load 해도 규칙상 위반이 아니다.
2. **계층-횡단 원칙 미명문화.** "각 계층은 자기 altitude 만 담고 detail 은 흘러내려 구현 직전 확정"이 단일 원칙으로 없다(개별 경계만 흩어짐) → 계층 간 altitude 일관성을 강제할 single-home 부재.
3. **rule_docs 확정지점 불명시.** domain 은 Spec 이 최종 확정 계층이나 rule_docs 에는 Spec 이 없다(rule=자기 spec-of-record) — detail-flow 관점에서 "rule_docs 에서 detail 이 최종 잠기는 곳 = terminal rule 파일"이 명시 안 됨.
- **dogfood 증거**: 이번 5-K/5-B Design 에 entry-artifact enumeration·marker 명·discovery 2층 mechanic 을 front-load → 사용자 교정. 규칙이 약해 *임시메모리에만 있는* altitude 규율에 의존했고, Codex 는 그 메모리를 몰라 detail concern 을 altitude-blind 로 반환 → 두 결손이 곱해짐(= 사용자 진단).

### 방향 (direction — 세부는 Plan/WP)
- **Design content/altitude 경계 신설** — Design = *방향 정렬*(why/what/owner-surface model/non-goals/which Spec·implementation 수정)만. round-scoped 분석·정확 문구·enumeration·절차·mechanic·정확 marker 명은 Design 에 담지 않는다(→ Plan+WP/Spec). Plan 의 "not a work memo"·Spec 의 "must not contain" 과 *동형* 경계.
- **계층-횡단 detail-flow 원칙 명문화** — 인큐베이션앵커 → Design(방향) → Plan+Work Packet(승인결정+detail) → Spec/rule(구현직전 확정) 흐름에서, 각 계층은 자기 altitude 를 담고 detail 은 다음 계층으로 단계 확정되며, 최종 확정 계층(domain=Spec / rule_docs=terminal rule 파일)에서 구현 직전 세부가 잠긴다. 상위 계층 detail front-load 는 결함.
- candidate-agnostic, P0 정합(P0-3 active-surface=authority · P0-1 taxonomy 불변). E5 bootstrap 동형(이 규칙 부재 동안 작성된 Design 은 수동 적용 — 소급 결함 아님).

### Owner surface / 수정 대상 절 (방향)
- `docs-working-model.md`: *Design / Plan / Spec lifecycle* 절(Design 정의에 경계 추가) · *Proportionality rule* 인접(altitude ↔ proportionality 다른 축 정합) · 신규 *detail-flow* 원칙(독립 절 vs lifecycle 절 확장 = Plan). (*Spec identity* must-not-contain 은 정합 *확인*; 5-E checklist 가 게이트화.)

### non-goals
- 기존 Plan/Spec/WP content 경계 재정의 · Proportionality rule 재정의 · checklist/check 기계화(5-E) · 후보 미터치 · taxonomy 변경 · mutation/commit/push 승인 아님.

### Plan-readiness (Plan/WP 가 닫을 detail)
- Design content/altitude 경계의 **정확 문구**(Plan "not a work memo"·Spec "must not contain" 어휘와 정합) — Plan.
- detail-flow 원칙을 **독립 절 신설 vs 기존 lifecycle 절 확장** — Plan.
- **Proportionality rule 과의 관계** 정합(altitude[계층별 무엇] ≠ proportionality[meaning-preserving vs normative] — 다른 축 명시) — Plan.
- **rule_docs 확정지점**(terminal rule 파일)의 detail-flow 표현 — Work Packet.
- **5-E 연계**(altitude 게이트의 checklist 화) — 5-E item 으로.

## 5-K: promotion 전이 — Design (direction-level)

> docs-working-model revision 의 Phase-1 keystone. **Design = 인큐베이션앵커 이후 *방향 정렬* → Plan 으로 가는 흐름의 문서** — 세부(정확 문구·enumeration·절차·marker 명)는 여기서 잠그지 않고 Plan+Work Packet / 구현 직전으로 내려보낸다(5-D 원칙 적용). 방향은 phase-경계 Codex 오케스트레이션(설계 blind + relay-B 적대)으로 검증·정렬됨. cs1 닫지 않음. **rule 미편집.**

### Header
- **무엇의 Design 인가.** `docs-working-model` 규칙의 **promotion 전이**를 정정한다. 현 규칙은 promote 를 (i) 다단계 D→P→S(또는 D→P→rule) lifecycle *진입*, (ii) `_incubation` 을 promoted artifact 와 함께 제거하는 *한 atomic changeset* 으로 동시 규정해 자기모순적으로 읽힌다.
- **체인이 끝나면 무엇이 되는가(방향).** 규칙이 promotion 을 **전이 이벤트(incubation 종료) ↔ promoted lifecycle(전이 후 정규 D→P→S/rule)** 로 분리하고, E3/E4 의 기준점을 *고정 파일명*이 아니라 **전이가 쓰는 entry promoted artifact** 로 잡으며, transient 를 보수적 fallback 으로 봉합해 5-B(상태머신)를 분리 가능케 한다.
- **이 문서가 아닌 것.** 5-B(상태머신) 설계 아님(별도 item) · 후보 콘텐츠 수정 아님(Phase 2) · 세부 mechanic/문구/enumeration 잠금 아님(Plan+WP) · taxonomy 변경 아님(P0-1) · 별도 `_spec.md` 아님(P0-3) · mutation/commit/push 승인 아님.

### 결함 (방향 수준 — 왜 바꾸나)
1. **promote 이중정의.** Candidate lifecycle = "다단계 lifecycle 진입" ↔ 3-state = "한 atomic changeset 안에서 `_incubation` 제거·공존0". 한 단어("promotion")에 다단계와 단일 changeset 이 겹쳐 모순처럼 읽힌다.
2. **E4 흡수 대상 모호.** 흡수처를 "promoted Design/Plan/Spec, or terminal rule file" 복수 나열하나, 전이 시점엔 promoted lifecycle 의 *첫* artifact 만 존재 → removal precondition 의 기준 artifact 비결정.
3. **E3 경계 모호.** "공존0(E3 intact)"은 전이를 원자적 경계로 봐야 성립하는데 promote 가 "다단계 진입"으로도 읽혀, *incubation 의 끝이 어디냐* 가 모호(E3 정신 자체는 불변).

### 방향 (direction — 세부는 Plan/WP)
- **promotion = 전이 이벤트와 promoted lifecycle 의 분리.** 전이 = incubation 을 끝내고 promoted lifecycle 의 *entry artifact* 로 갈아끼우는 한 changeset; 그 *후* 의 D→P→S/rule 은 incubation 아닌 정규 lifecycle.
- **E3/E4 의 기준 = entry promoted artifact**(고정 파일명에 못박지 않음 — orchestration 이 `_design` 하드코딩의 over-constrain[narrow candidate·rule 직행]을 지적; 정확한 entry-artifact 판정은 Plan). E4 흡수 = **removal 의 precondition**(batch-3 보존; 전이 시점 *완전* — "이후 흡수" 약화 아님).
- **E3 transition-aware** — binding 구간 = `_incubation` 존재 기간, 전이 = 종료 경계. (E3 정신 불변, P0-4.)
- **atomicity 의 역할 한정**(orchestration 핵심 정렬): atomicity 는 *E3-intact(공존0) 보장*에만 쓰고, "전이 산출물이 어떤 *상태*인가"는 atomicity 가 아니라 **5-B 의 marker** 가 맡는다 — SCM-mechanic 에 lifecycle semantics 과적재 금지.
- **transient 봉합**: 5-K landing 시 post-전이 pre-live 상태는 *기존 Spec identity time-phasing* 을 따른다는 보수적 fallback 한 줄 → 명시 marker/discovery/de-promotion 은 5-B 로. (split 가능케 함.)

### Owner surface / 수정 대상 절 (방향)
- `docs-working-model.md`(rule=자기 spec-of-record): *Incubation tier* > Candidate lifecycle(promote 문단)·3-state(active/promotion)·E3 문단; *Document artifact classes* #2 와 *Lifecycle closeout* 은 정합 *확인*. (5-E enforcement·check 는 본 batch 아님.)

### non-goals
- 5-B 상태머신(별도 item) · 후보 미터치(P0-6) · batch-1~4 재litigate(P0-5) · taxonomy 변경(P0-1) · entry-artifact 정확 enumeration·proportionality Design-collapse·fallback 정확 문구(전부 Plan/WP) · mutation/commit/push 승인 아님.

### Plan-readiness (이 방향에서 Plan/WP 가 닫을 detail)
- 전이가 쓰는 **entry promoted artifact** 의 정확한 판정(domain `_design` / rule 직행 시 무엇 / narrow candidate 의 proportional collapse 허용 여부) — Plan.
- **fallback 문구** 정확화 + batch-3 "atomic promotion transition·E4=precondition" 과의 정합 clause-map(번복 아니라 정밀화 확인) — Work Packet.
- "promotion"/"closeout" 전수 용처 점검(중의성 0) — Work Packet.

## 5-B: promote-but-not-live 상태머신 — Design (direction-level)

> 5-K landed 후. swap 이 *낳는* 상태를 규칙에 명시. **direction-level**(5-D 원칙 적용) — marker 명·discovery 구조·de-promotion 절차는 Plan+WP 로 내려보낸다.

### Header
- **무엇의 Design 인가.** 전이 산출물(**promote 됐지만 closeout 전 = not-live**)의 상태를 규칙에 명명·정의한다 — 현 규칙은 이 상태를 정의하지 않는다(discovery? marker? 되돌리기? 미해결 open-Q?).
- **체인이 끝나면 무엇이 되는가(방향).** 규칙이 그 상태를 **명명**하고, **discovery ≠ live-authority** 를 분리하며, de-promotion 을 **기록된 되돌림**으로, 미해결 open-Q 를 **보존·라우팅**으로 둔다.
- **이 문서가 아닌 것.** 5-K 재litigate 아님 · marker 기계검사 아님(5-E) · de-promotion 완전 절차 codify 아님(방향·경계만) · 후보 미터치 · mutation/commit/push 승인 아님.

### 결함 (방향 수준)
- 전이 산출물의 상태가 규칙에 **미정의**: ① lifecycle marker 부재(*Spec identity* 는 live/sync-required 만) ② discovery 대상인가/어떤 권위인가(E1) ③ 잘못된/포기된 promote 의 되돌림 부재 ④ 미해결 incubation open-question 의 행선지 부재.

### 방향 (direction — 세부는 Plan/WP)
- **상태 명명** — promote-but-not-live 상태에 이름을 준다(이름 자체는 Plan; *Spec identity* 의 형용사 'blueprint' 와 충돌 회피 — orchestration 지적).
- **discovery ≠ live-authority 분리** — 전이 산출물은 거버넌스상 *발견 대상*이되 구현 *권위*는 아니다(orchestration 핵심: 단순 발견을 live authority 로 오소비하는 위험 차단). 두 층의 구체 구조는 Plan.
- **de-promotion = 기록된 되돌림**(history-preservation 축) — *내 초안의 "candidate 부활 불가(identity-monotonic)"는 철회*. orchestration 의 진짜 보정 수용: monotonic 은 artifact-identity 가 아니라 *무기록 rollback 금지*에 건다 → 기록된 withdrawal 로 incubation 재개는 *허용*, **live 가 된 뒤엔 de-promotion 금지**(repeal/supersede 별도). 절차 세부는 Plan/WP.
- **open-Q 보존·라우팅** — 미해결 open-Q 는 손실 0 으로 보존하고, **미해결 시 live 전환 차단**. 정확한 행선지(backlog 존재 시/부재 시 fallback)와 형식은 Plan/WP.

### Owner surface / 수정 대상 절 (방향)
- `docs-working-model.md`: *Spec identity*(상태 marker) · *Incubation tier* E1 문단(discovery vs authority) · *Future-work queue*(open-Q routing) · *Live-Spec update*(이 상태 ≠ sync-required) · *State migration*(de-promotion=기록된 withdrawal). (+ 후보: `docs/README.md`·spec template — Plan scope.)

### non-goals
- 5-K 재litigate · marker/2층-discovery/withdrawal 의 *정확한 mechanic·문구*(전부 Plan/WP) · marker 기계검사(5-E) · 후보 미터치.

### Plan-readiness (Plan/WP 가 닫을 detail)
- 상태 **marker 명** 결정(+ 5-G glossary cross-surface 충돌 sweep 과 조율).
- **discovery 2층 구조**의 구체(거버넌스-발견 vs 구현-권위 경계, E1 문구·5-E check 와 정합).
- **de-promotion 기록 절차**(withdrawal changeset·marker; State migration·rule_docs purity 와 정합).
- **rule/domain 비대칭** — rule 은 Spec 이 없어 marker 수용 surface·open-Q 행선지가 domain 과 다름(orchestration 지적). 비대칭의 구체 처리 = Plan.
- **open-Q routing fallback**(backlog 부재 시 행선지) + 형식 의무 — Work Packet.
