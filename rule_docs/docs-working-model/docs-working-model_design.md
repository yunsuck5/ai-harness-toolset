# docs-working-model: incubation ↔ terminology(glossary) lifecycle 정정 — Design

> 이 Design 은 `docs-working-model` 규칙 변경의 방향성 문서다 — 영구 live 아님. closeout 시 current-bearing 내용이 `docs-working-model.md`(rule = 자기 spec-of-record)로 흡수된 뒤 이 문서·`_plan.md`·`_work_packet.md` 는 retire(삭제, 보존=git history). 이 Design 은 mutation/commit/push 승인이 아니다(1회 진술).

> **★ 열린 thread 갱신 (2026-06-27).** cs1(`40bffd2`)은 *deferred closeout* 상태다 — closeout 요건(candidate 운용검증을 새 모델로 완료 + relay/blind 정규기능화)이 아직 미충족. 그 운용검증(Stage 2 promote dogfood)이 cs1 자기 모델의 **disposal-timing 자기모순**(아래 **batch-3**)을 표면화 → **Stage rewind 로 batch-3 추가**. batch-3 는 cs1 을 닫지 않는다(closeout 요건 불변).

## Header

- **무엇의 Design 인가.** `docs-working-model` 규칙의 *incubation tier ↔ terminology(glossary) lifecycle 결합*을 정정한다. 현 규칙은 "용어 등록"을 incubation 의 하위 절차로 묶고 의미확정을 promotion 에 두어, incubating 후보 인코딩이 glossary 와 lockstep 으로 cross-reconcile 되며 교착(integration 리뷰 3라운드 no/no)을 일으킨다.
- **체인이 끝나면 무엇이 되는가.** `docs-working-model.md` 가 (A) pending 용어 = owner-identity thin reservation, (B) 의미확정 = finalization-owner close(corrected-state review 직전), (C) incubation applicability(default strict + 명시 완화/유지), (D) cross-domain contrast 허용선, (E) transition clause 를 담도록 수정된다. 이후 cs2 에서 격리(stash)된 3 incubation + glossary 후보가 새 규칙에 맞춰 재정렬된다.
- **이 문서가 아닌 것.** glossary lifecycle 전면 first-class 재구조화 아님 · 완전 apply/relax matrix 정식화 아님(둘 다 deferred) · candidate 콘텐츠(consultation/blind/orchestration 본문) 수정 아님(cs2).

## 왜 바꾸는가 / 무엇을 바꾸는가

**문제(현행 규칙 — Design-작성 시점 기준; ★ batch-1 은 이후 landed, 이하 historical).**
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

## Phase 1: 규칙 candidate-agnostic settle — P0 고정 불변식 + DAG (5-D/5-K/5-B/5-PF/5-G/5-X/5-T/5-E/5-F)

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

> 아래는 *순환 아님*(DAG) — **item-label + 의존성**만 선언한다. 구체 **batch 번호·실행순서는 Plan 소관**("Plan — batch order"; Design 에 번호 박으면 그 자체가 altitude 누수). 이 선언은 **direction-level** 이며 각 item 의 detail 은 그 item 의 Plan/Work Packet 에서 잠근다(detail front-load 금지). 이 Design 의 본체는 **5-D + 5-K + 5-B** 의 direction-level Design 으로 시작했고, 이후 **5-E**(별도 절, landed `78e3a17`)·**5-F**(이 절 하단 — 5-E 잔여 closer)·**5-G**(이 절 하단 — 5-PF 위 잔여 정렬, batch-11 에서 REALIGNED; coupling-특성화는 5-PF 가 supersede)·**5-PF**(이 절 하단 — 5-G coupling 의 root-fix, landed `e0e9657`+`304855b`)·**5-X**(이 절 하단 — promoted→incubating 참조 규칙 + 3후보 promotion 순서)가 동형으로 추가됐다; **5-T** 는 후속 phase-iteration 에서 동형으로 설계한다.

- **5-D (foundational; 가장 이른 settle)** — lifecycle artifact 별 *content/altitude 할당* + 계층-횡단 *detail-flow* 원칙. Design 에 content/altitude 경계 부여(현재 Plan/Spec/WP 만 경계 보유) + "각 계층 자기 altitude·detail 흘러내림·구현직전 확정(domain=Spec / rule_docs=rule 파일, Spec 없음)" 명문화. **dogfood 산**(이번 Design 의 altitude-drift 가 이 gap 의 표면화). 모든 lifecycle 문서 작성법을 규정하므로 *토대* — 5-K 보다 앞/병렬. **(이 Design 본체 #1 — 아래.)**
- **5-K (keystone)** — promotion-transition atomicity(transition event vs promoted lifecycle; E3/E4 를 *entry promoted artifact* 기준으로 고정; + transient 봉합 fallback 한 줄). **(이 Design 본체 #2 — 아래.)**
- **5-B (5-K 뒤)** — swap 이 낳는 promoted-but-not-live 상태머신: 상태 marker · 2층 discovery(governance vs implementation-authority) · de-promotion(history-preservation 축) · open-Q routing. 상태가 swap 산출이라 5-K 의존. **(이 Design 본체 #3 — 아래.)**
- **5-PF (5-G coupling 의 root; 5-G 보다 앞; landed `e0e9657`)** — 규칙 pending-form governance clarify(under-specification 해소): *비-candidate 출처* pending 의 천장-안 form 미명세(L97 candidate-scope·L103 governed-elsewhere 무명 유보)를 C1(scope surface)·C2(부분 home 식별+gap 명시)·C3(직교성 본문화)·S3(명시 bound-defer)로 명세. 5-G coupling-특성화(5G-c1 bijection·5G-c3 deliberate-invariant)를 supersede — 5-G coupling-element 는 이 위 downstream. **(이 Design 절 — 하단.)**
- **5-G (5-K 와는 독립; 순서는 5-PF 뒤)** — terminology-registration 정합의 **잔여 정렬**: 비-coupling desync fix(L8 status-axis · L66 route · 필드명 L101↔L66 · close-condition desync) + coupling-element 의 5-PF-위 downstream 정렬(축-구분 surface 는 5-PF C1/C3 가 처리) + 5-G 절 형제 전수 realign(5-PF Plan 의 PF-R3 배정). rule↔glossary **cross-surface**. → 별도 item. **(이 Design 절 — 하단, batch-11 에서 REALIGNED 재기술; coupling-특성화는 **5-PF 가 supersede**[권위 = 5-PF 절 + landed rule], 원 진단·폐기 특성화·1차 framing-오염 철회의 lineage 는 git history 가 보존[그 절 REALIGNED 배너 참조].)**
- **5-X (5-B 뒤)** — promoted canonical → still-incubating sibling 참조 규칙 + 3후보 promotion *순서*(상호 name-ref = E2 순환). 상태/discovery 모델 의존. → 별도 item. **(이 Design 절 — 하단.)**
- **5-T (5-K 뒤)** — 글로벌 `snippets/rules/` universal-core ↔ project-residue split(orchestration 배포용; repo-only 후보 name-ref·codex-binding 혼재). → 별도 item.
- **5-E (settle-pass 끝의 enforcement; landed `78e3a17`)** — enforcement: `docs-working-model-check.ps1`(E2 스캔 `snippets/` 제외 false PASS·transition-awareness 미구현) + tests + checklists(5-D altitude-게이트 포함) + templates. 규칙 본문 settle 후 그 위에서 기계화. → 별도 item. **(그 deferred 잔여 hardening = 5-F.)**
- **5-F (5-E 뒤; enforcement-hardening)** — 5-E 의 채택된 yes-with-risk(deferred enforcement 잔여)를 닫는 **named closer**: 정적-강제 가능·hermetic·저위험 subset(E2 precision·docs/ purity·durable-pointer 일반 scan·WP-content checklist·EN-2 fence test·backlog next-ID)만 강제하고 나머지는 **residual 보존**(bounded subset — 사용자 결정). **terminology-enforcement subset 은 5-G 에 blocked-by**(schema 미정합). → 별도 item. **(이 Design 절 — 하단.)**
- **의존 요약(DAG):** 5-D → 5-K → 5-B → 5-X; **5-PF → 5-G**(5-PF = 5-G coupling-element 의 root-fix 선행; 5-G 는 5-K 와는 독립); 5-T 는 5-K 뒤; 5-E 는 본문 settle 후; **5-F 는 5-E 뒤(잔여 closer), 단 terminology-enforcement subset 은 5-G 에 blocked-by**. (batch 번호 부여·세부 순서 = Plan.)
- **★ 5-E 후 deferred-enforcement follow-on = 이제 named item 5-F 가 소유**(catalogue→named closer 승격; normative §2 DAG-residual: closer 없는 catalogue=executor 없는 부채 → 명명해야 healthy phasing). 전체 catalogue·tier 라우팅·bounded-subset·residual split·5-G dependency = **5-F Design 절(하단)**. (no silent drop — adversarial §11; rule-text 아님; 행선지 = roadmap follow-on → cs1-closeout migration; 5-G/5-X/5-T 와 동일 운명의 일부는 5-F 로 흡수, 본질-NSE·schema-의존분은 5-F residual·5-G 로.)
- **★ SPLIT lock (이 Design 의 결정 — 사용자 2026-06-28; triangulation 의 JOIN 권고를 phase-경계 relay-B 적대검증으로 *뒤집음*):** 5-K 와 5-B 를 **분리**한다(한 item 으로 JOIN 안 함). 근거 = (a) transient 는 5-K 에 *보수적 fallback 한 줄*("post-swap pre-live 상태는 기존 *Spec identity* time-phasing[writing-completion blueprint → implementer reference → closeout live]을 따른다")로 **봉합** 가능 → 모순 아님, 덜-명시일 뿐 → 5-B 가 이후 명시 상태로 승격 (b) **atomicity(5-K)와 state-marker(5-B)는 분리 가능한 별개 관심사**(relay-B 추가지적: atomicity 는 E3-intact 보장에만, "상태"는 marker 의 책임 — SCM-mechanic 에 lifecycle semantics 과적재 금지) (c) normative-method §2(통합단위 좁게) (d) 5-B 의 discovery 위험(prelive 가 live 로 오소비)을 clean 한 5-K 와 *격리*. = over-join 회피.

## 5-D: lifecycle artifact 별 content/altitude 할당 + detail-flow 원칙 — Design (direction-level)

> Phase-1 의 *토대* item(가장 이른 settle). **dogfood 산** — 이번 5-K/5-B Design 작성 중 발생한 altitude-drift(Design 에 구현-detail front-load)가 이 규칙 gap 을 표면화(batch-3 가 운용으로 disposal 자기모순을 잡은 것과 같은 패턴: dogfood=결함탐지·설계=결함해결). **direction-level** — 정확 문구·절 배치는 Plan/WP. **rule 미편집.**

### Header
- **무엇의 Design 인가.** lifecycle 문서(Design / Plan / Work Packet / Spec)가 *각각 무엇을·어느 altitude 로* 담는지의 규칙 gap 을 메운다. 현 규칙은 **Plan**("approval-target only, not a work memo") · **Spec**("must not contain …") · **Work Packet**(content boundary)에는 경계를 주지만 **Design 에는 content 나열만 있고 altitude 경계가 없다**; 또한 *계층을 횡단하는* "detail 흘러내림·구현직전 확정" 원칙이 명문화돼 있지 않다.
- **체인이 끝나면 무엇이 되는가(방향).** 규칙이 (1) **Design 에 content/altitude 경계**를 부여하고(Design = 방향 정렬: why/what/owner-surface/non-goals/which-spec; round-scoped 분석·정확 문구·enumeration·절차·mechanic 은 *담지 않음* — Plan+WP/Spec), (2) **계층-횡단 detail-flow 원칙**을 명문화한다(각 계층은 자기 altitude 만, detail 은 다음 계층으로 단계 확정, *구현 직전* 최종 확정 계층에서 잠금 — domain=Spec / rule_docs=terminal rule 파일[Spec 없음]).
- **이 문서가 아닌 것.** 기존 Plan/Spec/WP 경계 재정의 아님(Design 경계 신설 + 횡단원칙) · Proportionality rule 대체 아님(다른 축) · checklist 기계화 아님(5-E) · 후보 미터치 · taxonomy 변경 아님(P0-1) · 별도 `_spec.md` 아님(P0-3).

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
- 기존 Plan/Spec/WP content 경계 재정의 · Proportionality rule 재정의 · checklist/check 기계화(5-E) · 후보 미터치 · taxonomy 변경.

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
- **이 문서가 아닌 것.** 5-B(상태머신) 설계 아님(별도 item) · 후보 콘텐츠 수정 아님(Phase 2) · 세부 mechanic/문구/enumeration 잠금 아님(Plan+WP) · taxonomy 변경 아님(P0-1) · 별도 `_spec.md` 아님(P0-3).

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
- 5-B 상태머신(별도 item) · 후보 미터치(P0-6) · batch-1~4 재litigate(P0-5) · taxonomy 변경(P0-1) · entry-artifact 정확 enumeration·proportionality Design-collapse·fallback 정확 문구(전부 Plan/WP).

### Plan-readiness (이 방향에서 Plan/WP 가 닫을 detail)
- 전이가 쓰는 **entry promoted artifact** 의 정확한 판정(domain `_design` / rule 직행 시 무엇 / narrow candidate 의 proportional collapse 허용 여부) — Plan.
- **fallback 문구** 정확화 + batch-3 "atomic promotion transition·E4=precondition" 과의 정합 clause-map(번복 아니라 정밀화 확인) — Work Packet.
- "promotion"/"closeout" 전수 용처 점검(중의성 0) — Work Packet.

## 5-B: promote-but-not-live 상태머신 — Design (direction-level)

> 5-K landed 후. swap 이 *낳는* 상태를 규칙에 명시. **direction-level**(5-D 원칙 적용) — marker 명·discovery 구조·de-promotion 절차는 Plan+WP 로 내려보낸다.

### Header
- **무엇의 Design 인가.** 전이 산출물(**promote 됐지만 closeout 전 = not-live**)의 상태를 규칙에 명명·정의한다 — 현 규칙은 이 상태를 정의하지 않는다(discovery? marker? 되돌리기? 미해결 open-Q?).
- **체인이 끝나면 무엇이 되는가(방향).** 규칙이 그 상태를 **명명**하고, **discovery ≠ live-authority** 를 분리하며, de-promotion 을 **기록된 되돌림**으로, 미해결 open-Q 를 **보존·라우팅**으로 둔다.
- **이 문서가 아닌 것.** 5-K 재litigate 아님 · marker 기계검사 아님(5-E) · de-promotion 완전 절차 codify 아님(방향·경계만) · 후보 미터치.

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

## 5-E: enforcement — settled 모델의 강제/게이트 — Design (direction-level)

> Phase-1 의 *(본문 settle 후) enforcement* item(DAG: 본문 settle 후 그 위에서 기계화; 그 deferred 잔여 hardening 은 후속 **5-F**). 5-D/5-K/5-B 가 settle 한 의무를 *강제/게이트*만 하고 새 normative 의미는 안 만든다(5E-c1; 의미변경 필요 시 Stage rewind). **`09aced5` 의 yes-with-risk(5-B enforcement deferral)를 닫는다.** **direction-level** — 정확 check 로직·regex·checklist 문구·test 케이스는 Plan/WP. **mode-2 + full-scope orchestration. `.ps1` 변경이라 verify-ps1(UTF-8 BOM+CRLF) + full Pester 도.** 독립 gap 인벤토리(Claude 자체 + codex relay-A 병합 — 4대 축 수렴)는 *Work Packet* 소관(여기엔 카테고리·direction·fork 만; enumeration front-load 금지 — 5-D altitude).

### 5-E 고정 불변식 (이 라운드 상수; P0-1~6 상속)
- **5E-c1 — enforcement ≠ 새 normative 의미.** 이미 settle 된 의무를 *강제/게이트*만; 강제하려다 규칙 의미가 바뀌면 Stage rewind(해당 item).
- **5E-c2 — 3-tier routing(새 머신 금지; 기존 3층 정렬).** 단위 = *검증 명제*(verification proposition), tier = ① 기계 hard-check(정적 구조) ② checklist 의미게이트 ③ closeout 프로세스게이트. **한 검증 명제 = 정확히 한 owner tier**(같은 명제 중복강제 금지 — single-home 의 enforcement 판); 단 **한 *hazard* 는 여러 tier 의 서로 다른 명제로 방어 가능**(relay-B 보정 — 'obligation=tier 하나'는 잘못된 granularity; 예: lifecycle-state hazard = marker 존재[MS] + 올바른 값[SC] + live-전환 timing[PCG]). check 의 `SCOPE INFO`("MECHANICAL subset only") honesty 보존.
- **5E-c3 — 정적 불가능은 정직 분류.** 런타임 소비자 행동(prelive 가 live 로 *소비됨*)은 어떤 정적 check 도 못 봄 → marker-presence proxy 까지만 + over-claim 금지(false safety).
- **5E-c4 — candidate-agnostic + transition 완결(★ dual-lens dialectic 으로 재확정 — 이전 'deferred 일반 mechanism' framing 회수).** in-flight 후보 3종 미터치(P0-6). **구조검사 E1/E2/E3 는 *지금* binding**(line 105 "E1–E5 bind as rule requirements now")이며 anchored 후보에도 즉시 — 후보 3종은 *conform 하여 pass*(exempt 아님). 5-E 의 새 *구조* check(E2 snippets·lifecycle-state marker)도 즉시 binding, 후보는 *conform-pass*(`_spec` 없음·durable snippets ref 없음 → newly-fail 0 = 회피 아닌 통과). transition clause(line 104) 유예 = **오직 conditional-terminology-registration *check*(미구축·5-E 비대상)** → 5-E 는 transition *완결*(미이행 의무 0). exemption registry 불요. *유일 잔여* = line 104 parenthetical `(docs-working-model-check.ps1)` 용어 애매(structural-only script ↔ terminology 문단) = wording residual(5E-R3).
- **5E-c5 — `.ps1` 실행규율.** UTF-8 BOM+CRLF + verify-ps1 + full Pester.

### Header
- **무엇의 Design 인가.** docs-working-model 규칙의 *enforcement 표면*(mechanical check `docs-working-model-check.ps1` + checklists + templates + closeout 절)을 settled 모델(5-D/5-K/5-B + batch-1~4)에 맞춰 정합화한다. 현재 다수 의무가 text-only 수동 conformance.
- **체인이 끝나면 무엇이 되는가(방향).** enforcement 표면이 **3-tier routing** 으로 정합된다 — 각 검증 명제가 제 tier(MS/SC/PCG)로 라우팅되고, 정적 불가능은 marker-presence proxy + 정직 disclose. 구체: `09aced5` risk 의 **구조적 enforcement gap**(lifecycle-state marker 존재·E2 `snippets/` scope·withdrawal/open-Q closeout 절차)이 닫힌다 + 5-D altitude-gate + 명시 check gap(transition-awareness 정합). **★ 단 'prelive 가 live 로 *소비*되는' 위험 *자체*는 정적으로 못 닫음(NSE — marker-proxy 까지; over-claim 금지, 5E-c3)** — 5-E 는 *구조적* gap 을 닫지 consumer-behavior 를 닫는다 주장 안 함(blind/relay-B 보정).
- **이 문서가 아닌 것.** *전체* 인벤토리 강제 아님(broader gap = catalogued defer) · 새 normative 규칙 의미 아님(5E-c1) · 후보 미터치(P0-6) · taxonomy 변경 아님(P0-1) · 별도 `_spec.md` 아님(P0-3) · 정확 로직/문구/케이스 잠금 아님(Plan/WP).

### 결함 (방향 수준 — risk-closure + dogfood)
1. **`09aced5` enforcement 공백**(1차 동기): 5-B 상태 모델은 rule text 에 완결됐으나 *기계적 강제* 부재 — lifecycle-state header(현재 3-state 추론)·prelive same-path 소비방지·withdrawal lineage. live 전환이 자동해소 아님(다음 promotion 이 같은 창 재개방 — 구조적 원인 그대로).
2. **명시 check gap 2종**: (a) E2 content-scan = `rules/**`+`docs/README.md` 만 → **`snippets/rules/` 미스캔 = false-PASS**(rule candidate 의 promotion target 이 바로 거기인데 E2 가 못 봄; SCOPE INFO 자기천명). (b) **transition-awareness 미구현** — 규칙 transition clause 가 "realigning changeset 에서 transition-aware enable" 약속하나 현 구조검사(E1/E2/E3)는 즉시-binding → *불일치*.
3. **5-D altitude-gate 미기계화**: detail-flow invariant(front-load=결함)가 checklist 게이트로 없음.
4. **(인벤토리 추가 surface)** prelive 가 *가장 논의됐는데 가장 미게이트*(Spec checklist 가 Lifecycle-state 절을 *묻지도 않음*) · rule_docs/terminal-rule **closeout Level-2 surface 부재**(closeout gate 가 domain-Spec 형상 end-to-end — 양 인벤토리 독립 포착, 최대 구조 gap).

### 방향 (direction — 세부는 Plan/WP)
- **3-tier routing 으로 *제 tier* 강제(5E-c2).** *transition 의무*(atomic swap·retire=deletion·withdrawal·finalize-before-review)는 snapshot 이 못 보므로 **PCG(closeout gate)로 정직 라우팅** — 정적 check 에 욱여넣지 않음(인벤토리 "the trap"; 규칙도 "E3 guarantees only non-coexistence" 인정).
- **(MS) check 확장**: E2 scan 에 `snippets/rules/` 추가(false-PASS 닫음) + promoted `_spec.md` 의 **Lifecycle-state marker presence** 검사. (그 외 MS-가능 항목 선별 = Plan; over-mechanize 경계.)
- **(SC) checklist 정합**: 5-D altitude/detail-flow 게이트 + Spec checklist 에 **Lifecycle-state 절** 추가 + prelive 소비-인식·withdrawal-기록·open-Q-routing 의미게이트. (신규 candidate-lifecycle/promotion checklist vs 기존 확장 = Plan.)
- **(PCG) closeout 게이트**: rule_docs/terminal-rule **Level-2 변종** + withdrawal=기록된 reversal + open-Q-blocks-live 를 closeout 절차의무로.
- **(D) template**: Lifecycle-state 를 *testable required convention* 으로(이미 prelive/sync-required/live 명명; checklist 가 검사 가능하게).
- **transition-awareness(★ dual-lens dialectic 으로 *재확정*; codex 양 lens[중립 blind + Reading-1 refute relay-B] 모두 Reading 1 지지·refute 실패→CONCEDE)**: 구조검사(E1/E2/E3, 5-E 신규 포함)는 즉시 binding(line 105), anchored 후보는 conform-pass. transition 유예 = terminology-registration check 한정(5-E 비대상) → 5-E transition 완결. exemption registry 불요. 잔여 = line 104 parenthetical 용어 애매(WP/5E-R3).
- **broader 인벤토리 = catalogued defer(no silent drop — adversarial §11)**: durable-pointer 일반 scan·docs/ 도메인 purity·terminology state-machine·rejected-term sweep·review-date staleness·WP checklist 등은 5-E 밖 — *후속 enforcement 항목으로 보존*(행선지 = Plan; 규칙엔 backlog 없음). **★ E3 cross-folder rename-lineage = known hard residual(relay-B)**: 규칙은 lineage 금지하나 script 는 same-folder sibling 만 봄 — promotion-integrity/rename-evasion 이지 prelive-소비 아니라 5-E narrow 밖 defer 가능하되 *명시 잔여*로 둔다(silent drop 금지). 5-E 는 Phase-1 *최후 settle* 이지 enforcement-전수완성이 아님(과통합 차단 — normative §2).

### Owner surface / 수정 대상 (방향)
- **3 verification tier**: `scripts/docs-working-model-check.ps1`(+`tests/docs-working-model-check.Tests.ps1`) = MS · `rules/docs-working-model/checklists/*` = SC · `rules/docs-working-model/docs-working-model.md` *Closeout* 절 = PCG(terminal-rule Level-2; 5E-R1). **+ form surface**(검증 tier 아님): `rules/docs-working-model/templates/*` = Lifecycle-state field 등 *생성 form*(SC checklist 가 그 form 을 검사 — re-blind 보정으로 D 를 4번째 검증 tier 로 안 씀). rule = 자기 spec-of-record.

### non-goals
- 전체 인벤토리 강제 · 새 normative 의미(5E-c1) · 후보 realign(Phase 2) · 5-G/5-X/5-T · taxonomy 변경 · exemption-registry 신설 · 정확 로직/regex/문구/케이스(Plan/WP).

### Open risk / direction fork (orchestration adjudicate)
- **(5E-R1) terminal-rule closeout Level-2 — relay-B adjudicate = 조건부 (a) 의미-완성.** rule *Closeout* Level-2 가 domain `_spec`/`_backlog` 만 명명 → rule closeout 의 Level-2 surface 공백. terminal-rule variant 추가 = *이미 정해진 owner surface(terminal rule 파일)를 closeout gate 에 매핑*하는 의미-완성(새 의미 아님). **단 tight 제약(이걸 넘으면 5E-c1 위반→별도 item/Stage rewind)**: terminal rule 파일 *자체*가 Level-2 surface, rule 은 backlog 없어 open-Q 는 terminal landing 전 resolve; **새 파일/backlog/state-store/의미-field 만들면 즉시 별도 item**. close 확인 = Plan.
- **(5E-R2) MS vs over-mechanize.** 인벤토리 MS-가능 항목 중 *어디까지가 5-E scope* (09aced5 risk+명시 gap) vs defer. **close = Plan.**
- **(5E-R3) transition-awareness — ★ dual-lens dialectic 으로 *해소*.** blind(중립 textual) + relay-B(Reading 1 refute-attempt) 둘 다 Reading 1 지지(codex CONCEDE: 구조검사 즉시-binding, transition 은 terminology-check 한정). 5-E 는 transition 완결. 잔여(parenthetical 애매) → **사용자 결정 = (a): 5-E 가 bounded 명료화 포함** — line 104 의 "the mechanical check for this model" → *terminology-registration model* 임을 명시(meaning-preserving disambiguation; 새 의미/gate 0 — 이 애매함이 *내 오독을 유발*했으니 5-E 가 닫음). R1 보다 가벼운 rule-text 터치(proportionality = wording cleanup 급).

### Plan-readiness (Plan/WP 가 닫을 detail)
- MS 선별(5-E scope 경계) · SC 구조(신규 vs 확장 checklist) · PCG terminal-rule Level-2 fork(5E-R1) · transition-awareness 표현(5E-R3) · deferred 인벤토리 행선지 · 정확 check 로직/regex/marker 토큰/test 케이스/checklist 문구 — Plan/Work Packet/구현.

## 5-F: enforcement-hardening — deferred-enforcement 잔여 closer — Design (direction-level)

> Phase-1 의 5-E 후속. **5-E 의 채택된 yes-with-risk(`78e3a17`, deferred enforcement 잔여)를 닫는 named closer.** normative §2 DAG-residual 기준 — risk 의 closer 가 DAG 에 명시되면 healthy phasing(5-K→5-B→5-E 가 그랬음), 없으면 catalogue=executor 없는 부채 → **named item 으로 승격**(이 절). 5-E 와 동일 운용(mode-2 + full-scope orchestration + canonical) · 동일 lifecycle(`rule_docs/docs-working-model/` Design→Plan→WP→check/rule→canonical). enforcement ≠ 새 normative 의미(5E-c1 계승; 의미변경 필요 시 Stage rewind/별도 item). **direction-level** — 정확 check 로직·regex·checklist 문구·test 케이스·item 최종선별은 Plan/WP(독립 gap 인벤토리 = WP 소관, 5-D altitude — enumeration front-load 금지). **rule/`.ps1` 변경 → verify-ps1(UTF-8 BOM+CRLF) + full Pester.**

### 5-F 고정 불변식 (P0-1~6 + 5E-c1~c5 상속; 이 라운드 상수)
- **5F-c1 — bounded subset + 명시 residual (사용자 결정).** 5-F 는 *정적-강제 가능·hermetic·저위험*인 enforcement 잔여만 닫는다. terminology-enforcement·본질적-NSE·rename-evasion 등은 **residual catalogue 로 명시 보존**(no silent drop — adversarial §11). 5-E 가 "Phase-1 최후 settle ≠ enforcement 전수완성"이었듯 5-F 도 *전수완성 아님*(normative §2 과통합 차단).
- **5F-c2 — check hermeticity 불변.** 현 `docs-working-model-check.ps1` 은 *주어진 tree 만으로 순수·재현가능*(wall-clock·환경 비의존; CHECK 머리말). 5-F 의 MS 추가는 이 속성을 깨지 않는다 — **wall-clock 의존 검사(review-date staleness)는 MS 가 아니라 SC/PCG 로 라우팅**(idempotency 보존: 오늘 PASS→파일변경0인데 다음달 FAIL 금지).
- **5F-c3 — terminology-enforcement 는 5-G 에 blocked-by.** terminology state-machine check(pending↔owner-pending·field-schema·monotonicity)는 *성격상* enforcement(5-F-class)이나, rule reservation 필드(*Terminology registration* — `candidate`/`facet`/`not-this`/`eventual-owner-surface`/`collision-note`)와 glossary 실제 pending 필드(`owner`/`facet`/`not-this`/`close`/`promotion-target`)가 **desync** — check 가 "use only these fields"를 강제하려면 schema 를 *골라야* 하고, 고르는 행위가 normative 결정이라 5E-c1 위반. ∴ **schema 정합(5-G normative) 선행 필수** → 그 위에서 기계화. 5-F 는 terminology *field-schema* check 를 만들지 않고 *5-G 의존으로 명시*한다. **단 rejected-term 의 좁은 *section-confinement*(rejected heading 이 glossary *Rejected terms* section *밖*에서 accepted-looking 으로 부활 금지 — 정체성을 Rejected-section heading 에서 취득, pending-field schema 와 *독립*)은 schema-비의존이라 5-F MS/SC 재검토 대상**(over-defer 회피; relay-B special-target). owner-pending-field 존재검사처럼 schema 를 *전제*하는 것만 5-G.
- **5F-c4 — docs/ purity = 규칙 명시 금지만(over-strict 금지) + transition-aware.** docs/ 는 규칙상 *intentionally looser*(live Spec+README+backlog 보유)이고 end-state 도 *"declared now, executed only per-domain"*(RULE:25)·legacy 는 *"persist but do not grow"*(RULE:40). ∴ docs/ structural check 는 (i) *Stable filename rule* 이 *이미* 금지한 것(`<topic>_*.md` topic-named · `docs/<domain>/work/` subfolder 분할 · 비-role `<domain>_*.md`)만 강제하는 **blacklist 접근**(합법 set 을 새로 안 좁힘 — allowed-set 은 illustrative 이며 `<candidate>_incubation.md`·domain-candidate `docs/<cand>/`·**auxiliary role `_policy/_contract/_state/_status/_guide`[규칙 :176 상 deferred=Design/Plan 승인 필요이나 *승인 여부는 비-구조적(NSE)* → check 가 over-strict 금지 대신 role-name *accept*; 승인=manual/SC residual]** 를 포함), (ii) **transition-aware** — migrated/end-state 도메인에만 binding, legacy residue·in-flight 후보는 conform-pass(5-E in-flight conform-pass 정신 계승; newly-fail 0). 합법 set 명문 강도는 meaning-preserving 수준(5F-R2/Plan). (rule_docs purity 와 *유사 구조*이되 그 purity 는 binds-only-`rule_docs/`·docs/ 는 looser·allowed-set 도 다름.)

### Header
- **무엇의 Design 인가.** 5-E 가 의도적으로 *deferred* 한 enforcement 잔여(roadmap follow-on catalogue) 중 *정적-강제 가능·저위험* subset 을, settled 모델(5-D/5-K/5-B + batch-1~4)의 3-tier(MS/SC/PCG)로 마저 강제·게이트한다.
- **체인이 끝나면 무엇이 되는가(방향).** enforcement 표면이 (a) **E2 matcher precision**(angle-bracket link·absolute/drive path 형식 미매칭 — 대표 boundary 예, 정확 패턴=WP; base-tree tail 모호는 *FP/FN 아닌 메시지 attribution* 이라 저우선/선택), (b) **docs/ structural purity**(rule_docs purity 와 유사 구조이되 docs/-looser·transition-aware·5F-c4), (c) **durable-pointer 일반 scan**(`_incubation` 특수사례 → `log/**`·`polishing/**`·`repo_snapshot/**` 등 *Durable-pointer prohibition* 일반; E2 의 path-vs-concept discriminator 재사용 — discriminator 강건성이 *편입 전제*, 5F-R3), (d) **WP-content checklist**(현 5 checklist 의 누락 form; *WP 파일 자체*만 대상=5E-c2 중복-tier 회피), (e) **EN-2 fence char/length 회귀 테스트** 까지 닫고, (f) **backlog next-ID *floor* check**(조사발견 신규 MS *후보* — per-prefix next-ID > max present row id; 'monotonicity'의 history-의존분[삭제행 재사용]은 NSE·snapshot 불가, multi-prefix 헤더 처리 필요; 5F-R4 에서 편입 확정)를 더한다 — 나머지는 **residual catalogue 로 명시 보존**.
- **이 문서가 아닌 것.** enforcement 전수완성 아님(5F-c1) · 새 normative 의미 아님(5E-c1) · terminology schema 정합 아님(5-G) · 후보 미터치(P0-6) · taxonomy 변경 아님(P0-1) · 별도 `_spec` 아님(P0-3) · 정확 로직/regex/문구/케이스/최종 item 선별 아님(Plan/WP).

### 결함 (방향 수준 — risk-closure)
- 5-E 의 채택된 yes-with-risk = deferred enforcement 잔여(catalogue). 현 DAG(5-G/X/T = rule/schema-side)에 *이 잔여를 닫을 item 이 없었다* → catalogue=executor 없는 부채(normative §2 실측: closer 명시였던 5-K→5-B→5-E 체인은 healthy phasing 이었으나, 5-E 잔여는 closer 부재 → 5-F 명명 필요).
- 잔여의 성격은 *균질하지 않다*(이 세션 codex relay-A landscape + Claude 독립 lens 병합): 일부는 깔끔한 MS(matcher precision·structural purity·next-ID) / 일부는 SC checklist(WP content) / 일부는 schema 미정합으로 *지금 기계화 불가*(terminology — 5-G 의존) / 일부는 *원리상 정적 불가*(E4/E5 semantic·런타임 소비) / 일부는 check hermeticity 와 충돌(review-date wall-clock). → 단일 강제 아니라 *성격별 tier 라우팅 + residual 분리* 필요.

### 방향 (direction — 세부는 Plan/WP)
- **bounded MS subset 강제**: E2 precision(angle-bracket·absolute/drive path; *pre-existing 일반-E2 — rules/**·docs/README 동일, 5-E EN-1 은 snippets/rules reach 만 넓힘·로직 불변이라 5-E 산 아님; durable scan 과 일부 겹침*) · docs/ structural purity(5F-c4) · durable-pointer 일반 scan(path-vs-concept discriminator 재사용 — discriminator 강건성 = *편입 전제조건*, open-risk 로만 두지 않음; 미확보 시 SC 강등/defer, 5F-R3) · backlog next-ID floor check(신규 MS 후보; per-prefix next-ID > max present row id, multi-prefix 헤더 처리; 5F-R4). (정확 선별·로직 = Plan/WP; 5F-R1·R3·R4.)
- **SC checklist 보강**: WP-content checklist 신규(**대상 = *WP 파일 자체*만** — 규칙 *Work Packet* content boundary·Plan checklist 와 *중복 owner-tier 금지* [5E-c2 single-home-of-enforcement]; content boundary 의 의미게이트; 금지=실행 command sequence·staging·review/validation 결과·readiness 판정 — reviewer-question prep 등 허용은 보존) + **cross-surface 배선 동시**(*Package note* manifest + *conformance gate* application-trigger + forms-list — orphaned-deliverable 차단; 5-E EN-6-wiring 선례·review_ops §4 add-case).
- **MS-test 보강**: EN-2 fence char/length edge 회귀(예: same-char 짧은 close-fence 가 긴 opener 미닫힘) — shipped check(5-E EN-2)의 회귀 안전망. test-only(form 무관).
- **명시 residual (no silent drop)**:
  - *terminology field-schema state-machine* = **5-G blocked-by**(field desync, 5F-c3); **단 rejected-term *section-confinement*(schema-독립)은 5-F MS/SC 재검토**(over-defer 회피, relay-B); owner-pending-field 존재검사 등 schema-전제분만 5-G.
  - *review-date staleness* = **SC/PCG**(비-hermetic, 5F-c2; 진짜 위반 = "새 review-date 없이 continue"이지 단순 날짜경과 아님 — process gate 적합).
  - *E3 cross-folder rename-lineage* = **known hard residual**(규칙은 lineage 금지하나 snapshot 은 rename intent/changeset atomicity 를 원리상 모름·machine-readable lineage field 부재): same-id cross-folder 검출은 *anomaly-check*(duplicate/이상 — rename intent 증명 아님)로만 5-F MS 후보, 진짜 rename-evasion 은 **PCG-assertion(promotion checklist) 또는 lineage-field 신설 시 별도 item**(5F-R5).
  - *E4(이미 5-E promotion-checklist SC-게이트)·E5(무게이트)·script MS-advisory* = **본질 NSE — advisory 유지**(catalogue 의 "advisory only" 진술보다 잔여 좁음).
  - *조사 발견 추가군*(single-home dup·lifecycle altitude·1:1 sync·cross-domain semantics·domain-local closure·state-migration·no-mirror·authoring-language·proportionality abuse-guard·incubation admission-completeness checklist) = **차기 enforcement 인벤토리**(대부분 SC/NSE; 단 backlog next-ID floor check 만 MS 라 위 (f)의 5-F 편입 *후보*[5F-R4 확정]). 행선지 = 이 5-F residual 절(roadmap home) → cs1-closeout roadmap-migration.
- candidate-agnostic(P0-6) · transition-aware(신규 구조검사도 in-flight 후보에 conform-pass 확인 — 5-E 동형, newly-fail 0).

### Owner surface / 수정 대상 (방향)
- **MS** = `scripts/docs-working-model-check.ps1`(+`tests/docs-working-model-check.Tests.ps1`) · **SC** = `rules/docs-working-model/checklists/*`(+WP-content checklist 신규) · **배선** = `docs-working-model.md` *Package note* / *Template / checklist conformance gate* 절 · (필요 시 form = `templates/`). rule = 자기 spec-of-record.

### non-goals
- enforcement 전수완성 · 새 normative 의미 · terminology schema(5-G) · review-date 의 MS 화(5F-c2) · E3 rename lineage-field 신설(별도 item) · 후보 realign(Phase 2) · 5-G/5-X/5-T 본체 · taxonomy 변경 · 정확 로직/regex/문구/케이스.

### Open risk / direction fork (orchestration adjudicate)
- **(5F-R1) MS subset 경계** — 어디까지가 5-F MS scope(precision·purity·next-ID) vs defer. close = Plan.
- **(5F-R2) docs/ allowed-set 명문화 강도 + transition-awareness** — 규칙 명시 금지만 강제(blacklist; `<candidate>_incubation.md`·domain-candidate 포함)하되 allowed-set confirm 강도(meaning-preserving vs 신규 normative) + **migrated 도메인만 binding·legacy residue/in-flight conform-pass** 조항(5F-c4). over-strict/소급-fail 시 5E-c1/5F-c4 위반. close = Plan + 규칙 본문 대조.
- **(5F-R3) durable-pointer scan scope** — 어느 surface(canonical only? 전 tracked .md? rule_docs planning docs 포함?) + path-vs-concept discriminator 정밀도. close = Plan/WP.
- **(5F-R4) backlog next-ID floor check 편입 여부 + 정밀화** — 조사 발견 신규 MS gap(snapshot floor check, 'monotonicity' 아님 — history-의존분 NSE); 5-F 편입 vs residual + multi-prefix 헤더 파싱·개명. close = Plan.
- **(5F-R5) E3 rename-evasion 처리** — PCG-assertion(promotion checklist) vs lineage-field 신설(별도 item) vs residual 유지. close = Plan.

### Plan-readiness (Plan/WP 가 닫을 detail)
- MS subset 최종 선별(5F-R1·R4) · docs/ allowed-set 표현(5F-R2) · durable-scan scope+discriminator(5F-R3) · E3 rename-evasion 행선지(5F-R5) · WP checklist 문구 + 배선(EN-6 동형) · EN-2 fence test 케이스 · residual catalogue 의 durable home(이 5-F 절 = roadmap; cs1-closeout migration) · **독립 gap 인벤토리**(이 세션 codex relay-A landscape + Claude 독립 lens 병합 — file:line 인용)는 **Work Packet 소관**(enumeration front-load 금지, 5-D altitude).

## 5-PF: 규칙 pending-form governance clarify (under-specification 해소) — Design, direction-level

> 별개 normative lifecycle item·5-G coupling-element 의 root. survey(4 lens)가 표면화하고 게이트(2 lens)가 확증한 *근본* — docs-working-model 규칙이 *비-candidate 출처* pending term 의 form 을 under-specify — 을 세우고 정렬한다. 폐기된 5-G coupling sub-Design(5G-c1 bijection·5G-c3 deliberate-invariant)은 이 근본의 *증상-패치*였고 이 item 이 supersede; 5-G coupling-element 는 clarified 규칙 위 *downstream* 정렬. **direction-level** — 정확 규칙 wording·위치·필드 = Plan/WP/구현(규칙 텍스트 무touch). meta-circular(규칙이 자기 개정) → 자기 규율 엄격. evidence base = 규칙 clause(arbiter); 폐기 framing(bijection·(a)/(b)·deliberate-invariant) 봉인(§0.1/§1.2). **★ 구현됨 — batch-10 `304855b` 가 C1/C2/C3/S3 를 rule 에 반영(이 절 = direction-시점 기록; "규칙 텍스트 무touch" 는 Design-단계 진술).**

### 진단 (게이트 2 lens 확증 — under-specification, 모순 아님)
규칙은 form 을 *각각* 명시한다: candidate-introduced pending = thin (L97 "a candidate introduces" scope + L101 "Define no meaning") · 보편 천장 = ≤ one-line meaning + classification (L96 single-home) · owner-pending = one-line meaning (L103). **그러나 *비-candidate 출처*(L96 "several sources … a candidate's incubation is only one such source") pending 의 *천장-안* form(thin 이냐 one-line 이냐)을 어느 절도 결정하지 않는다 = gap.** L97 의 리터럴 scope("a candidate introduces")가 비-candidate 를 제외하고, L103 "thin-vs-fuller form governed elsewhere" 가 *무명으로* 유보 → **모순이 아니라 미명세**(L97↔L103 비충돌; 게이트 Q1 = no-clash-leaves-a-gap 2/2·clause-독립 도출). owner-pending⟹meaning 은 clean.

### clarification 방향 (gap 명세 + 위치 교정; 정확 wording = Plan/WP)
- **C1 — L97 candidate-도입 scope 를 prominent 하게 surface.** "a candidate introduces" 한정이 *놓치기 쉬워*(survey 4 lens 가 (A)-내부 분열로, 게이트 prompt-leak 가 별도로 입증) "모든 pending = thin" 오독·bijection 확산을 낳았다 → 이 scope 를 등록 reader 시선 경로에 명시(괄호·묻힘 금지). 게이트: descriptive(L97 주어 한정은 *이미* wording).
- **C2 — "governed elsewhere" 의 *부분* home 식별 + gap 명시(descriptive).** L103 dangling 을 *현존 governance*(L96 천장 + L97 candidate-조임)로 식별하되, **비-candidate 의 천장-안 form 은 그 둘로 닫히지 않음(gap)을 명시** — "elsewhere = L96+L97 complete" 로 *닫지 않는다*(게이트 divergence: 닫으면 mildly-normative). gap 자체는 fork(S3)가 처리.
- **C3 — L103 직교성("the split is only the finalization-owner-live axis")을 괄호→prominent 본문**(wording 불변; 게이트: descriptive/editorial).

### fork 해소 = S3 (명시 bound-defer; 사용자 settle 확정)
게이트 확인: 규칙은 비-candidate pending form 을 현재 **S3(미settle)**로 둔다 — S1("비-candidate 도 thin")·S2("one-line 허용") *둘 다* the rule does not establish(L96 천장은 *상한*이지 carry 허용 명시 아님; 2/2). → **구조 진술(천장 settled · candidate=thin) + 비-candidate pending 의 천장-안 thin-vs-one-line = *명시 bound-deferred*(named open question · 천장-capped · 현 instance 0 · 실례 등장 시 settle).** silent gap 아님 = *implicit 확산 차단*(survey 가 입증한 실패모드 = 미명세가 읽기로 전파). settle(S1/S2)은 별도 future normative 결정.

### supersede (5-G coupling 증상-패치 — silent 방치 금지)
- **5G-c1(form=f(status) bijection)·5G-c3(deliberate-invariant 선언) 및 의존 형제**(Header(a)(b)·방향의 "허용 조합표"·Owner/Open-risk 의 "governed-elsewhere home 명명") = 오염된 coupling-특성화(게이트: bijection·deliberate-invariant 는 (A) goes-beyond) → **이 5-PF 가 supersede**. 권위 = 5-PF. 5-G 절 그 진술은 lineage 보존하되 *비-authoritative*(5-G 배너 참조).
- **5-G coupling-element 재정의 = downstream** — "clarified 규칙(5-PF)에 정렬". 축-구분 surface 는 C1/C3 로 5-PF 가 처리; 5-G 는 그 위 glossary/cross-surface 정렬만. 5-G 의 *비-coupling* 부분(L8 status-axis·L66 route·필드명 L101↔L66·close-condition desync)은 유효.

### Frozen / non-goals / altitude
- frozen: candidate-agnostic · taxonomy 불변 · rule = 자기 spec-of-record · owner-pending⟹meaning 불변 · L96 천장 불변.
- non-goal: enforcement/기계화 · 정확 규칙 wording/위치/필드(Plan/WP) · 5-G glossary realign(downstream 별도).
- **direction only — 규칙 텍스트 무touch.** gate-confirmed = 방향만; 정확 wording = 구현-게이트(자기인증 금지·m4 fix).

### Open risk / Plan-readiness
- **(PF-R1)** C2 의 정확 문구가 "elsewhere 를 닫음"으로 새지 않게(descriptive 유지 — 게이트 divergence) = Plan/WP wording 가드.
- **(PF-R2)** C1 surface 위치·C3 이동 위치·S3 bound-defer 문구(named open question·천장-cap·instance-trigger) = Plan/WP.
- **(PF-R3)** 5-G 절 supersede 의 형제 전수 realign(Header/방향/Open-risk) — 이 land 는 *배너*로 1차 차단(비-authoritative 표기), 전수 정합 = 5-G downstream 단계.
- **(meta-circular)** docs-working-model 자기 normative 개정 = E5 bootstrap → 규칙 자신 lifecycle(rule_docs Design→Plan→landing) 경유.

## 5-G: terminology-registration 잔여 정렬 — cross-surface desync 정합 (5-PF 위 downstream; Design, direction-level)

> ★★ REALIGNED (batch-11) — 이 절의 원본은 "pending status/form 축-구분" Design(`9fa415c`)이었다. 그 coupling-특성화(superseded coupling sibling set — 열거는 5-PF 절·Plan batch-10 hard boundary ② 참조)는 survey+게이트가 *오염된 증상-패치*로 확인해 **5-PF 가 supersede** 했고(권위 = 5-PF 절 + landed rule `304855b`), batch-11 이 이 절을 **clarified 규칙(5-PF) 위 downstream(잔여 정렬)** 으로 재기술했다. 원 절 전문(원 진단·폐기 특성화 포함)과 1차 framing-오염 Design 의 폐기·철회 lineage 는 git history(`9fa415c`~`304855b` 구간)가 보존한다.

> Phase-1 의 5-PF-후행 item(5-K 와는 독립). **clarified 규칙 위에서 rule↔glossary↔planning 의 잔여 desync 를 정합하고, 이 절 자신을 포함한 5-G 표면을 5-PF 정렬로 재기술한다.** 5-F 가 terminology field-schema enforcement 를 5-G blocked-by(5F-c3)로 명시했으므로 이 정합이 그 선행조건. 정합 = normative·비수렴(normative §1) ≠ enforcement(기계화 = 후속·check 무변경). **direction-level** — 정확 문구·per-hit 처분 = Plan(batch-11)/WP. rule/glossary(.md) 변경 → `.md` EOL=LF.

### 5-G 고정 불변식 (P0-1~6·5F-c3 상속 + 5-PF frozen 상속; 이 라운드 상수)
- **S3 open question 보존** — 비-candidate pending 의 천장-안 form 은 rule 이 명시로 열어둔 named open question(settle = 실례 등장 시 별도 normative 사용자 결정). 5-G 의 어떤 정합 문구도 이를 어느 쪽으로도 결정하지 않는다(의미 기준 tripwire — Plan batch-11 hard boundary ①).
- **frozen 상속** — L96 천장 불변 · candidate=thin(L97/L101) 불변 · owner-pending⟹meaning 불변 · taxonomy 불변(P0-1) · rule=자기 spec-of-record(P0-3) · candidate-agnostic(P0-6).
- **glossary 권위 보존** — glossary = term 의 one-line meaning + classification + status vocabulary 의 home; rule = 등록 lifecycle 절차/트리거/전이조건(rule L100 이 분류 중재를 glossary rule owner 에 귀속). 소비자-격하 계열은 폐기 상태 유지.
- **transition-aware** — candidate-도입 pending entry 본문(glossary L70–81)의 realign 은 각 candidate 의 realigning changeset(cs2) 소관 — 본문 미터치(newly-broken 0). owner-pending entry(L86–89)는 이미 rule-정합(편집 예정 0).
- **시간축 토대 위생** — tier1~2 토대 표면의 모호함은 *읽기*로 상속(semantic blast radius) → enforcement 0 이어도 "지금이 가장 싼 교정 창".

### Header
- **무엇의 Design 인가.** 5-PF 가 명세한 clarified 규칙(candidate-scope surface·부분-home+gap 명시·직교성 본문·S3 bound-defer) 위에서, 그 규칙과 어긋나게 남은 **잔여 표면**을 정합한다 — glossary 의 출처-단정/close-서술/필드명/form-암시 desync + rule 의 국소 잔여(L103 괄호 과단정·L99 열거 누락) + 이 절 자신의 superseded 특성화.
- **체인이 끝나면 무엇이 되는가(방향).** rule↔glossary 가 같은 사실(출처·close=decision point·필드 체계·S3 open)을 같은 수위로 진술하고, planning 표면이 landed 상태를 정확히 기술하며, 그 위에서 5-F-class terminology enforcement 가 unblock 된다(5F-c3 전제 해소 — 기계화 자체는 후속).
- **이 문서가 아닌 것.** S1/S2 settle 아님(S3 유지) · candidate entry 본문 realign 아님(cs2) · enforcement/기계화 아님(후속) · 5-PF landed wording 재-litigate 아님 · taxonomy 변경·별도 `_spec` 아님(P0) · 정확 문구/token 아님(Plan/WP).

### 잔여 결함 (방향 수준 — batch-11 착수 인벤토리가 file:line 전수 확증; 상세 = WP batch-11 절)
- **glossary 출처-단정 수위차**: 서두(L8)가 pending 을 candidate-전용처럼 단정 — rule 은 비-candidate 출처를 본문으로 인정(3수위 형제: L8 단정·L17 hedge·L66 무-hedge).
- **glossary close-서술**: 확정-종결형(L17·L138) — rule L102 는 close = decision point(finalize or carry-forward).
- **glossary 필드 체계 분열**: L66 필드 명명 ↔ rule L101 명명(같은 파일 L88 은 rule 명명 — 한 파일 2체계) + 조건부 carry-forward reason 부재 + "past promotion" 근거가 owner-pending 발생원 정의와 불일치.
- **L66 form-암시**: status 별 단일 필드셋의 일반 서술이 S3 open question 을 봉합하는 형태로 읽힘.
- **rule 국소 잔여**: L103 괄호(carry-forward 선택지 배제로 읽힘 — pre-existing)·L99 상태 열거 누락.
- **planning stale**: landed 마커 부재·rule-landed 로 소멸한 옛 결함 서술의 잔존.

### 방향 (direction — 세부 = Plan batch-11 close·WP)
- **glossary = rule 현행의 미러로 정합(신규 normative 0)**: 출처-수위(L8 완화 = meaning-preserving clarification, 사용자 확정 2026-07-03) · close = decision point · 필드명 glossary→rule 정렬 · L66 은 candidate-도입 entry 의 기술로 한정 + form 거버넌스는 rule 로 route(S3 봉합 0) · 신규 fold(L34/L36/L129·L11↔L139·closed/not-adopted 관계 — 사용자 승인 2026-07-03, 전부 descriptive).
- **rule 은 최소 편집**: L103 괄호 완화(사실 유지·선택지-배제만 해소) + L99 descriptive completion; 기타 관찰 = per-item WP 판정(landed wording 재-litigate 금지·no silent drop).
- **이 절 자신 = 5-PF 위 downstream 재기술** — 이 REALIGNED 절이 그 결과(원문 lineage = git history).

### Owner surface / 수정 대상
- **glossary** `rules/terminology-glossary.md`: 서두(L8·L11) · Status vocab(L17) · Pending/owner-pending preamble(L66) · Term ownership(L138–139) · accepted/rejected entry 서술(L34·L36·L129). candidate-도입 pending entry 본문(L70–81) 미터치.
- **rule** `rules/docs-working-model/docs-working-model.md`: L99·L103(괄호만).
- **planning**: 이 절(realign) + landed-마커 hygiene(WP batch-11 목록). check `.ps1`/tests 무변경.

### Open risk / fork — batch-11 Plan 이 close
- **5G-R1** → 재정의 close: rule-측 축-구분 surface 는 5-PF C1/C3 로 소진 — 잔여 = glossary 가 rule 현행을 미러하는 표현 정합만. **5G-R2** → meaning-preserving clarification(사용자 확인 2026-07-03). **5G-R3** → 질문 소멸: 5-PF C2 가 부분-home 식별+gap 명시로 옛 dangling 을 해소 — 별도 form-축 home 명명 작업은 남아 있지 않다(이 기록이 그 close). **5G-R4** → 필드명 glossary→rule(`candidate`·`eventual-owner-surface`); entry 는 transition. **5G-R5** → 5F-c3 unblock 선언까지(기계화 subset·구현 = 5-F residual catalogue 소유 후속).
- **(meta-circular)** → rule_docs lifecycle 경유(E5 bootstrap 동형) — batch-11 이 그 경유 자체.

### Plan-readiness
- batch-11 Plan(같은 changeset)이 batch 단위·scope·hard boundary·5G-R1~R5 close·신규 fold 를 확정; file:line 전수 인벤토리·삽입 초안·tripwire 대조표·rule 관찰 per-item 판정표·hygiene 목록 = WP batch-11 절.

## 5-X: promoted canonical → still-incubating sibling 참조 규칙 + 3후보 promotion 순서 — Design (direction-level)

> Phase-1 의 5-B-후행 item(상태/discovery 모델 의존; DAG 5-D→5-K→5-B→5-X). **direction-level** — 정확 규칙 문구·적용 표면 열거·표기 형식·checklist 항목·per-hit 처분은 Plan/WP 소관(**rule 미편집 — 이 절은 방향만**). 방향은 다층 독립 lens 의 착수 인벤토리가 확증한 사실 위에서 사용자 fork 3건(참조 형식·순서·scope; 2026-07-04)으로 결정됐다 — 인벤토리의 file:line 전수·실행/검증 기록은 이 절 소관이 아니다(Plan 단계 WP·`log/**`).

### 5-X 고정 불변식 (P0-1~6 상속; 이 라운드 상수)
- **5X-c1 — E2 원 금지 불변 + 허용형 절의 중의성 명시 해소 (bounded normative 정직 인정).** 경로/durable 참조 금지(E2 첫 절)·candidate 의 canonical default/input 화 금지(E3(a))·absorbed-conclusion summary 요건(promote 된 artifact → *자기 과거* candidate 방향)은 불변. 단 E2 둘째 절("a canonical→candidate reference is only an absorbed-conclusion summary")은 *durable 문서-참조의 허용형만* 말하는 좁은 독법과 *모든 canonical→candidate 참조를 제한*하는 넓은 독법의 **중의성**이 확인됨 — 5-X 의 rule 편집은 이 중의성을 명시 해소하며, 이름-참조 sanctioned 형식의 신설은 (넓은 독법 기준) **bounded normative 변경**임을 정직 인정한다(proportionality: allow boundary 신설 = normative — 그래서 본 item 이 full lifecycle[Design→Plan→rule]로 진행). 기존 금지의 *묵시적* 완화가 아니라 *명시적·검토된* 규칙 변경이며, 어느 독법에서도 경로 금지·semantics-소비 금지는 불변(P0-4).
- **5X-c2 — 참조 규칙은 candidate-agnostic, 순서는 rule 밖 + 확정은 Plan.** 참조 규칙은 임의 후보의 일반 lifecycle 규칙으로 rule 본문에 settle 한다(P0-6). **3후보 promotion 순서는 rule 텍스트에 박지 않으며**, 이 Design 은 순서의 *방향 권고와 결정 근거*까지만 소유한다 — 순서의 **확정은 Plan 의 approval-target 결정**(규칙의 Plan 소유 = batch order 동류; 5-D altitude). rule 본문은 후보 이름·순서를 보유하지 않는다.
- **5X-c3 — 새 머신 금지, 기존 장치 정렬.** 참조 형식은 기존 장치(foreign-semantics pointer-only 의 name-never-path 원칙·glossary not-this 선례·E1 2층 discovery·4-class reference sweep)의 정렬/확장으로 만들고, 새 registry·state-store·lineage-field 는 만들지 않는다(normative §2 손잡이 1; 5F-R5 의 lineage-field 신설은 별도 item 으로 남음 — 이 item 이 아니다).
- **5X-c4 — frozen 상속.** taxonomy 불변(P0-1) · rule=자기 spec-of-record(P0-3) · batch-1~4/5-D/5-K/5-B/5-PF/5-G landed 모델 불변(P0-5) · S3 named open question 보존 · 후보 본문 미터치(cs2 — 후보 문서의 마커 적용/realign 은 각 realigning changeset 소관).

### Header
- **무엇의 Design 인가.** promoted canonical 산출물(promotion 전이의 entry `_design` 부터 landed terminal rule / live Spec 까지)이 **아직 incubating 인 sibling candidate 를 참조**하는 상황의 규칙 gap 을 메우고, 후보 생애-이벤트(discard/rename/de-promotion) 시 그 참조의 처분 의무를 규정하며, 현 3후보(consultation·blind-advisory·subagent-work-orchestration)의 **promotion 순서 방향과 근거**를 고정한다(확정 = 후속 Plan — 5X-c2).
- **체인이 끝나면 무엇이 되는가(방향).** 규칙이 (1) promoted→incubating **이름-참조의 sanctioned 형식**(이름-정체성 only·상태-정직 표기·경로 금지 불변)과 (2) 후보 **생애-이벤트 시 기존 이름-참조의 sweep 의무**를 담고, (3) 3후보 promotion 순서의 **방향(consultation → blind-advisory → subagent-work-orchestration)과 결정 근거**가 이 Design 에 고정되고, 그 **확정은 후속 Plan 의 approval-target 결정**으로 내려간다(rule 텍스트 밖·Design 은 방향까지 — 5X-c2).
- **이 문서가 아닌 것.** 후보 본문 수정 아님(cs2) · promotion 실행 아님(순서 방향 결정만) · E2/E3 완화 아님(5X-c1) · glossary entry 편집 아님(candidate entry 는 transition 소관) · 정확 문구/표기 형식/표면 열거 잠금 아님(Plan/WP) · terminology-enforcement 기계화 아님(5-F residual catalogue 소유).

### 결함 (방향 수준 — 착수 인벤토리 다층 확증; file:line 전수는 Plan 단계 WP 소관)
1. **방향 비대칭.** 참조 규율이 incubating→foreign 방향(define-by-contrast·pointer-only)과 canonical→`_incubation` **경로**-참조(E2) 만 존재 — **promoted 산출물 → incubating sibling 의 이름-언급/contrast 는 어느 조항의 주어도 아니다.** promoted-but-not-live 상태(prelive Spec·entry `_design`/`_plan`)의 artifact 가 sibling 을 참조할 때의 규칙도 미봉합(5-B 는 authority 축만 정의).
2. **E4 가 참조 발생을 강제하는데 허용 형식이 없다.** 3후보의 정체성 진술 자체가 sibling-contrast 로 구성돼 있고(상호 status-vocab 대비·역할 대비·framing 축 대비), E4 는 그 current-bearing 내용을 유실 없이 승격 산출물로 운반하라고 요구한다 — **sibling-이름 참조는 회피 대상이 아니라 lifecycle 이 만들어내는 필연**이다. 그런데 E2 의 유일 허용형(absorbed-conclusion summary)은 그 후보의 promote 시점에만 생길 수 있어 still-incubating sibling 에는 정의상 존재 불가 = 형식 공백.
3. **생애-이벤트 sweep 부재.** 후보 discard/rename(-at-promotion)/de-promotion 시, 그때까지 타 canonical 표면(승격된 sibling 포함)에 생긴 그 후보 이름-참조의 처분 의무가 규칙·promotion checklist 어디에도 없다(유일한 전-표면 sweep 의무는 glossary term 의 `rejected` finalize 경로뿐; candidate discard ↔ term rejection 연결도 미기술).
4. **순서 미규정 + 구조적 제약 실재.** 3쌍 전부 양방향 name-ref 라 어느 순서든 위 1·2 의 미규정 상황에 진입한다. 제약 사실: subagent-work-orchestration 은 계약-provider(두 domain 후보의 finding shape 존재 이유가 그 close-the-loop 계약)이나 **landing 조건이 구조적으로 가장 늦다**(promotion target 이 글로벌 배포 tier `snippets/rules/` = self-contained 요구 + rule 후보는 terminal landing 전 open-Q 전부 resolve 필요한데 그 open-Q 들이 sibling 실측-성숙에 얽힘 + universal-core↔residue 분리는 5-T 소관); consultation↔blind-advisory 간에는 blind-advisory 가 consultation 을 정체성 성립에 더 깊게 사용(참조 부담 비대칭).
5. **(부수 — 이 item 의 배경 사실)** 규칙이 정의한 inter-candidate thin 관계 마커는 3후보 표면에서 실사용 0(전부 prose contrast; transition 면제 중), glossary 의 pending↔pending not-this 상호 참조는 canonical 표면 위에 이미 sanctioned 로 현존(승격 후 accepted↔pending 국면의 형식만 미규정). 또한 subagent-work-orchestration 후보 문서의 promotion lifecycle 표면(promote 시 폴더 fate 서술)이 landed rule 의 rule_docs 3-state 모델과 desync 인 pre-existing stale 이 확인됨 — transition 면제 중이며 realign 은 그 후보의 realigning changeset(cs2) 소관; 이 절의 순서 근거는 폴더 fate 에 의존하지 않으나 Plan/WP 가 그 처분을 명시 route 한다(no silent drop).

### 방향 (direction — 세부는 Plan/WP)
- **(1) 참조 규칙 = sanctioned 이름-참조 형식 명문화 (사용자 fork 확정).** promoted canonical 산출물이 still-incubating sibling 을 참조할 때 — **이름-정체성 only**(경로/durable 참조 금지 불변 = E2) + **상태-정직 표기**(참조 대상이 non-authoritative 후보임이 읽는 자리에서 드러남 — E1 2층 discovery 와 정합: 이름-언급이 후보를 discovery target·canonical input 으로 만들지 않음을 형식이 보증) + **semantics 소비 금지 불변**(E3(a)) + foreign-semantics pointer-only 원칙의 promoted-관점 확장 + **운반 상한**(E4 가 승격 산출물로 운반하는 sibling-contrast 는 identity/contrast 성립에 필요한 current-bearing 내용으로 한정 — E4 의 기존 완전성 요건을 넘는 과잉-운반 아님). 적용 국면은 promoted-but-not-live 와 live 를 모두 커버(수위 분화 여부 = Plan). 표기의 구체 형식(기존 thin 마커 확장 vs prose 규정)과 적용 표면의 정확 열거 = Plan/WP.
- **(2) 생애-이벤트 sweep 의무 (사용자 fork 확정 — scope 포함).** 후보의 discard / rename-at-promotion / de-promotion 을 수행하는 changeset 은 기존 promoted 표면의 그 후보 이름-참조를 sweep(정정/제거/재-home)한다 — 4-class reference sweep 의 후보-생애판. 참조를 sanction 하는 규칙과 그 참조의 소멸-처분은 한 fact 의 양면(참조만 허용하고 stale 처분을 안 정하면 규칙이 미완). candidate discard ↔ 그 후보 pending term 처분의 연결 여부·sweep 의 tier 배치(PCG closeout vs SC checklist) = Plan.
- **(3) promotion 순서 방향 = consultation → blind-advisory → subagent-work-orchestration (사용자 fork 확정; rule 텍스트 밖 — 확정은 Plan).** 이 Design 은 순서의 *방향과 근거*를 고정하고, 순서의 *확정*(approval-target 결정)과 durable 배선은 후속 Plan 소관(5X-c2·5X-R5). 근거: (a) subagent-work-orchestration 의 landing 전제(open-Q 실측-성숙·5-T 선행·배포 tier 진입)가 구조적으로 가장 늦다 — 두 domain 이 먼저 닫히며 그 실측이 rule 후보의 open-Q 를 성숙시키는 방향이 조건과 정합, (b) consultation 이 blind-advisory 보다 참조 부담이 얇다(비대칭), (c) 먼저 승격된 Spec 이 incubating 계약을 name-ref 하는 구간은 방향 (1) 의 형식이 커버. 각 promote 는 그 후보의 realigning changeset 의무(transition 조항)와 동시 발생. 실측이 전제를 뒤집으면 Stage rewind 가 아니라 Plan-level 재결정으로 갱신(그 조건 명문화 = Plan).
- **(4) glossary accepted↔pending 국면 = (1) 의 적용례로 정렬.** 한 후보의 승격으로 accepted 가 된 glossary entry 가 still-pending sibling term 을 언급하는 형식은 (1) 의 sanctioned 형식을 따른다 — 별도 glossary 재설계 없음(세부 = Plan; candidate entry 본문은 transition 소관 불변).

### Owner surface / 수정 대상 절 (방향)
- `docs-working-model.md`(rule=자기 spec-of-record): *Incubation tier* E1/E2 문단(이름-참조 축 명세의 1차 후보 위치) · *Cross-domain semantics restriction* 의 incubating-candidates bullet(promoted-관점 확장) · *Candidate lifecycle*(discard/rename 시 sweep 의무) · *State migration* De-promotion(sweep 연결). + SC tier: promotion checklist(신규 promoted artifact 의 outbound sibling-참조 점검 + 생애-이벤트 sweep 점검 항목). 정확 절 배치·신규 절 신설 여부 = Plan. check `.ps1` 는 이 item 에서 무변경(기계화 = 5-F residual catalogue 소유 후속).

### non-goals
- 후보 본문·후보 마커 적용(cs2 realign) · promotion 실행 · E2/E3 완화 · rule 본문에 후보명/순서 박기(5X-c2) · glossary candidate entry 편집(transition) · lineage-field/registry 신설(5X-c3; 5F-R5 별도 item 불변) · terminology-enforcement 기계화(5-F residual) · taxonomy 변경 · 5-T 본체.

### Open risk / direction fork (Plan 이 close)
- **(5X-R1) 적용 표면의 정확 열거** — sanctioned 형식이 걸리는 promoted 표면(entry `_design`/`_plan`·prelive Spec·live Spec·landed rule·canonical index) 의 열거와 E2 "canonical rules/indexes"·E3(a) 열거와의 정합(열거 확장이 필요한지, 필요하면 descriptive completion 인지 normative 인지 판정). close = Plan.
- **(5X-R2) 상태-정직 표기의 형식** — 기존 thin 마커 어휘 확장 vs prose 문구 규정; 어느 쪽이든 새 머신 금지(5X-c3) 경계 안이며, **표기의 집합이 사실상 candidate discovery index 로 기능하지 않아야 한다**(E1 정합의 형식-측 경계). close = Plan/WP.
- **(5X-R3) 생애-이벤트 sweep 의 tier 배치와 terminology 연결** — PCG(closeout/promotion 절차의무) vs SC(checklist); candidate discard 가 그 후보 pending term 의 처분을 강제하는지 — **방향: 이름-참조 sweep 과 terminology finalization 은 같은 changeset 에서 함께 점검하되 별개 결정(sweep 이 term 의 reject/finalize/carry-forward 를 자동 결정하지 않음 — finalization-owner close 의 per-term 결정 보존).** close = Plan.
- **(5X-R4) 순서 재검토 조건** — 순서 방향(방향 (3))의 갱신 트리거(예: rule 후보 open-Q 가 예상보다 빨리 닫힘)를 Plan 이 명문화(무기록 뒤집기 금지 — 기록된 재결정만). close = Plan.
- **(5X-R5) 순서 확정·durable home 의 Plan 배선** — 순서의 확정은 Plan 의 approval-target 결정(5X-c2)이며, 이 Design 절은 promoted-lifecycle closeout 에서 retire(삭제)되므로 확정된 순서가 closeout 후 어디에 carry 되는지(Plan 배선·cs1-closeout roadmap-migration·또는 각 promote changeset 의 자기 기록)까지 Plan 이 함께 닫는다 — Design 에만 두면 소실. close = Plan.

### Plan-readiness (Plan/WP 가 닫을 detail)
- 참조 형식의 정확 문구·표기 방법(5X-R2) · 적용 표면 열거(5X-R1) · sweep 의 tier·항목 문구(5X-R3) · 순서 재검토 조건(5X-R4) · 순서 결정의 durable home 배선(5X-R5) · promotion checklist 항목 초안 · subagent-work-orchestration 후보 문서의 폴더-fate pre-existing desync 처분 route(결함 5 — cs2 소관 명시) · 착수 인벤토리의 file:line 전수 정리(상호참조 지도·시나리오 판정표·생애-이벤트 미커버 목록)는 Plan 단계의 Work Packet 소관(enumeration front-load 금지 — 5-D altitude).
