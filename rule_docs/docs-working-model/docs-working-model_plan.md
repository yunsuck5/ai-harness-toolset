# docs-working-model: incubation ↔ terminology lifecycle 정정 — Plan

> Plan 은 승인 대상 의사결정만 담는다(작업 메모 아님 — 분류·구현 노트는 `docs-working-model_work_packet.md`, 실행 기록은 `log/**`). closeout 시 흡수 후 retire(삭제). 이 Plan 은 mutation/commit/push 승인이 아니다(1회 진술).

## Header

- **무엇의 Plan 인가.** docs-working-model 규칙의 **두 coordinated 변경**의 batch·경계·검증 결정: **batch-1 = incubation↔terminology lifecycle 정정**(Design (A)~(F)), **batch-2 = rule_docs 모델 일반화 + 그 3-state check**(세션 중 사용자 지시로 cs1 에 추가 — 아래 batch-2).
- **체인이 끝나면 무엇이 되는가.** `docs-working-model.md` 가 두 변경을 반영한 상태로 수정되고(rule = 자기 spec-of-record), `docs-working-model-check.ps1`(+tests)가 rule_docs 3-state 를 검사하며, Design/Plan/Work Packet 은 closeout 에서 retire.
- **이 문서가 아닌 것.** candidate 콘텐츠(4 stashed 파일) 재정렬 아님(cs2) · glossary 용어항목 realignment 아님(cs2) · 별도 `_spec.md` 생성 아님(rule 은 자기 spec-of-record) · **incubation↔terminology 의 terminology-registration 검사 enablement 아님(cs2, transition-aware)** · mutation/commit/push 승인 아님. (**rule_docs 3-state check 는 cs1 포함** — batch-2.)

## Batch 순서와 의존

- **단일 batch (batch-1 = rule 텍스트 편집).** (A)~(F)는 incubation↔terminology lifecycle 이라는 *하나의 coherent normative 변경*이고 모두 `docs-working-model.md` 의 인접 절(Incubation tier · Spec identity · Cross-domain semantics restriction)을 건드린다 → 쪼개면 transient 자기-모순(한 절만 새 모델, 다른 절은 구 모델)이 생기므로 **한 단위로 묶는다**(JOIN).
- **batch-1 ↔ batch-2 의존.** 둘 다 `docs-working-model.md` Incubation tier 의 인접 절을 건드리므로 한 changeset(cs1)으로 묶되, 내용상 batch-1=incubation↔terminology, batch-2=rule_docs 모델로 구분한다.
- **check 의 두 부분 분리(이 Plan 의 결정).** (a) **rule_docs 3-state purity check(+tests)는 cs1(batch-2)에 포함** — rule_docs 의 새 구조(persistent 폴더 · idle `.gitkeep` · orphan)는 *지금* 강제되어야 오배치·orphan 을 막는다(사용자 지시: 구조 보장). (b) **incubation↔terminology 의 terminology-registration 검사 enablement 는 cs2 로 이연**(R1: 격리되어 곧 재정렬될 in-flight 후보·glossary 에 소급 실패하므로 candidate 재정렬과 함께 transition-aware 로 켠다) — rule 텍스트에 그 transition 한 줄을 박는다("mechanical 검사 자동화는 candidate landing(cs2) 이후 transition-aware 적용; 영구 면제 아님").
- **lifecycle 문서 retire 시점(이 Plan 의 결정).** Design/Plan/WorkPacket 은 terminal closeout 에서 rule text 만 남기고 **같은 closeout 에서 retire(삭제)** — 별도 cleanup changeset 으로 미루지 않는다. 그때까지 헤더의 temporary/non-authoritative 표기를 유지한다.

## Batch 정의

**batch-1 — `docs-working-model.md` incubation↔terminology lifecycle 정정**
- **목적(한 줄).** glossary 를 incubation 하위 절차에서 분리하고, 의미확정을 finalization-owner close(review 직전)로 옮기며, incubation applicability·contrast 허용선·transition 을 명문화.
- **scope.** *다루는 것* = Design (A)~(F) 의 규칙 텍스트 반영. *안 다루는 것* = candidate 콘텐츠(4 stashed 파일) · incubation↔terminology 검사 enablement(cs2) · 완전 apply/relax matrix · glossary lifecycle 전면 재구조화. (rule_docs 모델 + 그 check 는 batch-2.)
- **hard boundary(불가침).** ① stash 된 4파일 미수정. ② 별도 `docs-working-model_spec.md` 생성 금지(rule = 자기 spec-of-record). ③ accepted-term 의 glossary=의미 home 모델 불변(over-correction 금지). ④ pending = owner-identity 만, `_incubation.md` 경로 durable pointer 금지(E2). ⑤ rejected umbrella 부활 금지. ⑥ E5(이 rule 의 incubation-tier 추가는 one-time bootstrap)·Final hard rule(docs 비-authority) 위반 금지.
- **validation expectation(무엇이 성립해야).** blind(diff, framing 제거) 무결 + canonical review PASS. 내부 정합: (B)의 finalization-before-review 가 기존 `corrected-state Codex review` 어휘·closeout 게이트와 모순 없음 / (A)의 accepted 모델 불변 / 새 문장이 Spec identity 의 "closeout 에서 live" 와 정합 / "promotion 시 확정" 잔존 0.
- **review focus.** glossary↔incubation 분리가 over-correction 없이 됐는가 · contrast 허용선(허용/차단)이 판정가능하게 날카로운가 · default=strict 와 완화 목록이 명확한가 · transition clause 가 in-flight 후보를 결함처리 안 하게 하는가 · scope-creep(matrix/재구조화) 침범 0 · rule=자기 spec 유지(별도 spec 문서 0).
- **Work Packet 필요 = 예.** 목적 = `docs-working-model.md` 의 어느 절을 어떻게 고치는지 line-level 분류 + 삽입 초안. 흡수 대상 = batch-1 의 rule 편집(= spec-of-record). retire 조건 = closeout 시 편집이 rule 에 반영되면 삭제.

**batch-2 — rule_docs 모델 일반화 + 3-state check (세션 중 사용자 지시로 cs1 에 추가)**
- **목적(한 줄).** `rule_docs/` 를 candidate-incubation 전용에서 *rule 개정/추가의 in-repo 기획 workspace*(per-rule persistent 폴더, 3-state)로 일반화하고, `docs-working-model-check.ps1`(+tests)가 그 구조를 강제하게 한다.
- **동기.** 이 cs1 작업 중 rule 기획서를 `rules/`(산출물 자리)에 *실제로 오배치*했고 사용자가 잡았다 — text-only placement 규칙이 skip-prone 함을 실증. persistent `rule_docs/<rule>/` 폴더 = 물리적 guardrail.
- **scope.** *다루는 것* = `docs-working-model.md` 의 rule_docs 절 + Candidate lifecycle 폴더-fate + `docs-working-model-check.ps1` rule_docs 3-state 로직 + `tests/docs-working-model-check.Tests.ps1` + `docs/README.md` 의 rule_docs 설명 정정. *안 다루는 것* = glossary `rule-candidate incubation` 항목 재정렬(cs2).
- **hard boundary.** ① rule = 자기 spec-of-record(rule_docs 에 spec 없음) ② persistent `.gitkeep` = rule-defined anchor(retire=삭제는 planning docs 에만; archive/bucket 부활 금지) ③ 1:1 rule-bound(broad bucket 금지) ④ idle = 기존 rule(`rules/<id>/<id>.md` 또는 `snippets/rules/<id>.md`) 전용; discard candidate=폴더 삭제 ⑤ check 는 snapshot-structural(삭제 안 함); 삭제의무는 closeout 게이트.
- **validation expectation.** rule text ↔ check 정합(promotion snapshot 의 E3 / idle backing 위치) · `_incubation`+`_design/_plan` 비공존(E3 무결) · verify-ps1 PASS · 전체 Pester green · check 가 현 repo 에 PASS · canonical review PASS.
- **review focus.** rule_docs bullet(폴더 persist) ↔ Candidate lifecycle bullet(폴더 fate) 정합 · E3 ↔ active-state 정합(공존 0) · idle backing 위치가 rule/check/tests 일치 · check 가 rule text 3-state 를 정확히 구현 · 이 lifecycle docs 가 실제 cs1 scope 를 승인.
- **Work Packet.** batch-1 WorkPacket 에 rule_docs 모델 섹션을 함께 둔다(별도 WP 불요).

**batch-3 — `docs-working-model.md` promotion incubation 처분 정합 (E4-centered; orchestration 검증)**
- **목적(한 줄).** promotion 에서 `_incubation` 처분을 E4 흡수완전성 + "closeout" 중의성 해소로 정합화 + state-migration 절 신설(line-18↔90 외형모순 · 체크리스트 누락 · closeout 분절 · 미retire-중-새revision gap 해소).
- **scope.** *다루는 것* = Design batch-3 (1)~(4) + re-blind/relay-B refinement 의 rule 텍스트 반영. *안 다루는 것* = candidate 콘텐츠(stash) · workflow-altitude 흡수 · taxonomy 변경 · check 로직 변경(file/material 재해석 없으니 최소) · (b)/(c)/(d).
- **batch 단위 = 단일 JOIN.** artifact-classes #2 · Incubation-tier(candidate lifecycle · 3-state) · Closeout 절(2개)은 한 묶음(쪼개면 transient 자기모순); state-migration 절은 같은 closeout/role-slot vocab 에 물려 같은 batch(독립 운영규칙 아님 — relay-B 의존성 점검 통과). batch-1/2 는 landed(`40bffd2`).
- **hard boundary(불가침; relay-B 보강 포함).** ① taxonomy 불변(file/material 재해석 금지) ② **E4 흡수완전성 = `_incubation.md` removal 의 *precondition***(같은 atomic promotion transition 내 완료; closeout 으로 미루기 금지) ③ **"ALL current-bearing content" = E4 형식 대표**(raw carryover 아님) ④ **no committed coexistence**(`_incubation.md` ↔ `_design`/`_plan`/`_spec`) ⑤ **Work Packet ≠ incubation-evidence sink**(흡수처 = promoted tracked file) ⑥ **closeout 용어 = local 중의성 해소이지 global 재정의 아님** ⑦ **state-migration = 같은 role-slot 한정**(병행 revision 안 막음 · archive/subfolder 0) ⑧ 별도 spec 금지 · rejected umbrella 금지 · Final hard rule 준수.
- **validation expectation.** relay-B(완료 = no-rewind) + **full-scope blind(실제 coordinated diff) 무결** + **canonical dual PASS(최종 1회, load-bearing).** 구현 중 lightweight local clause-map 점검(각 closeout 용어 → 어느 lifecycle); 중간 canonical 금지(반쯤 바뀐 모델 검증 = 나쁜 신호).
- **review focus.** 중의성 명시 새 모순 0 · E4=removal precondition(closeout-지연 함정 차단) · "ALL current-bearing"=E4형식(손실·raw 둘 다 아님) · state-migration scope(per-domain batch 모델 보존) · closeout primitive 과통합 0(discard 폴더삭제·idle 유지 구분 보존) · taxonomy/Final-hard-rule 불변.
- **Work Packet 필요 = 예.** batch-1 WP 에 batch-3 작업노트(절 분류 + 삽입 초안) 병치. 흡수 = rule 편집. retire = closeout.

**batch-4 — `docs-working-model.md` + `terminology-glossary.md`: terminology 등록 lifecycle owner-pending(가등록) 도입**
- **목적(한 줄).** 용어 등록 타임라인의 "finalization-owner live-but-deferred" 구간을 `owner-pending` 상태로 정립해 live-but-deferred 용어의 incubation-`pending` 오배치를 해소.
- **scope.** 다루는 것 = glossary status split(finalization-owner-live 축) · closeout 2건 이동 · 형제 갱신 · `finalization-owner` 등록 + rule owner-pending 등록 규칙 · 용어 통일(`owner-surface close`→`finalization-owner close`). 안 다루는 것 = pending thin-vs-fuller residual(별도 batch) · pre-existing 2 desync · candidate 콘텐츠.
- **batch 단위 = 단일 JOIN.** rule terminology-registration 계열 절 + glossary status/Pending/형제 = 한 묶음(쪼개면 cross-surface transient desync).
- **hard boundary.** ① pending 내용규칙 미터치(Path 1) ② finalization-owner ≠ active `owner surface`(Spec 격상 금지) ③ finalization-owner = owner id / tracked path(E2; runtime state 금지) ④ closeout 2건만 이동 ⑤ rule = 자기 spec-of-record.
- **validation expectation.** relay-B 수렴 + diff-blind self-introduced 0 + canonical dual(blocking 0). docs-working-model-check PASS · EOL LF · ws 0.
- **review focus.** owner-pending 축이 Spec identity·sync-required 와 정합 / cross-surface(rule↔glossary) 일관 / single-home·E2·batch-3 closeout 중의성 유지 / self-ref 순환 없음.
- **Work Packet.** batch-1 WP 에 batch-4 작업노트 병치(B4-1~7).

## Open decision 의 close 지점

- **R1**(check-script 가 in-flight 에 걸림) → **이 Plan 이 닫음**: check-script 는 cs2 로 이연(transition-aware).
- **R2**(finalization-before-review 정합) → batch-1 구현 중 규칙 본문 대조로 닫음.
- **R3**("충돌 가능 이름"/"완화" 모호성) → batch-1 규칙 본문 (A)/(C)(최소 기준 + default strict + 중재자 = glossary rule owner).
- **R4**(rule candidate closeout 경계) → batch-1 규칙 본문 (B)(terminal rule landing changeset 내 + exposed pending term 처리).
- **R6**(α 폐기·E4-centered) → **Design 에서 닫힘**(relay→blind→relay→re-blind; α 가 E4·taxonomy·Work Packet 과 3 hard 충돌 → flip). Plan 은 re-blind 4 refinement 만 정밀 잠금.
- **R7**(E4 흡수완전성 강도) → **이 Plan 이 닫음**: E4 완료 = `_incubation.md` removal precondition(같은 atomic transition) + 결과는 later closeout 에서 judgeable; *새 검증머신 금지*. ("judgeable at closeout"만이면 함정 — relay-B.)
- **R8**(state-migration scope) → **이 Plan 이 닫음**: 같은 role-slot 한정 + Stable filename rule · rule_docs purity(no archive/subfolder) 대조. 전역 병행 revision 안 막음.

## Stage rewind 조건

- **Plan 이 Design 위반**(예: 완전 matrix/재구조화로 확장) → stop, Design 재설계 후 Plan 재시작.
- **구현이 Spec(=rule) boundary 초과**(예: stash 된 candidate 콘텐츠 수정 · 별도 `_spec.md` 생성 · rejected umbrella 부활) → stop & 사용자에 확인, 조용한 scope 확대 금지.

## Phase-1 — Plan (cs1 revision 의 continuation; 규칙 candidate-agnostic settle)

> Phase-1 = `docs-working-model` 규칙을 *임의 candidate 의 일반 lifecycle* 로 settle 후 freeze(규칙↔후보 양방향 순환을 phase 경계로 차단). 각 item 의 Design = direction-level(별도 `_design.md`). **이 Plan 의 일 = batch 순서·번호 부여 + 각 item 의 승인대상 결정 close**(Design 은 item-label+DAG 만 줬다). cs1 닫지 않음. 운용 = mode-2. **mutation/commit/push 승인 아님.**

### batch 순서/번호 (이 Plan 의 결정)
- **실행 DAG**: 5-D(토대·최선두) → 5-K → 5-B → 5-X; 5-G 는 5-K 와 병렬; 5-T 는 5-K 뒤; 5-E 는 본문 settle 후 최후.
- **번호 = landing 순서 기준**: batch-5 = 5-D · batch-6 = 5-K · batch-7 = 5-B (이후 5-G/5-X/5-T/5-E 는 그 시점에 부여). **한 changeset 에 여러 item JOIN 안 함**(SPLIT lock — 5-K↔5-B 분리 결정 계승).
- **per-item lifecycle**: 각 item = Design(완료) → Plan → (Work Packet) → rule 편집 → closeout. **5-D landing 후 그 규칙이 5-K/5-B Plan 작성을 규율**(5-D Plan 자신은 bootstrap 수동 적용 — E5 동형). 이번 산출 = **5-D Plan + Work Packet** 까지; 5-K/5-B Plan 은 5-D settle 후 이어서.

**batch-5 — 5-D: lifecycle artifact content/altitude 할당 + detail-flow 원칙**
- **목적(한 줄).** Design 에 content/altitude 경계를 부여하고 계층-횡단 detail-flow 원칙을 명문화해 "Design=방향, detail 은 아래로, 구현 직전 확정"을 규칙으로 강제(현재 Design 만 경계 부재).
- **scope.** 다루는 것 = ① Design 정의에 content/altitude 경계 ② 신규 detail-flow 원칙(계층-횡단) ③ Proportionality 와의 축-구분 cross-ref. *안 다루는 것* = 기존 Plan/Spec/WP 경계 재정의 · Proportionality 본문 재정의 · checklist/check 기계화(5-E) · 후보 콘텐츠.
- **batch 단위 = 단일 JOIN.** Design 경계 + detail-flow 원칙 + 축 cross-ref 는 한 coherent normative 추가(같은 lifecycle 절 군) — 쪼개면 transient(경계만·원칙 없음).
- **hard boundary(불가침).** ① 기존 Plan/Spec/WP content 경계 미변경(Design 경계 *신설*만) ② Proportionality rule 본문 미변경(축 cross-ref 한 줄만) ③ rule=자기 spec-of-record(별도 `_spec.md` 금지) ④ candidate-agnostic(후보 미터치) ⑤ taxonomy 불변(P0-1) ⑥ 새 enforcement 머신 안 만듦(5-E 소관) ⑦ Final hard rule(docs 비-authority) 준수.
- **open decision close(이 Plan 이 닫음; phase-경계 blind+relay-B 정렬 반영).**
  - **detail-flow 위치 = *Design / Plan / Spec lifecycle* 절 *최상단* 의 "Lifecycle invariant"**(독립 top-level 절 신설 안 함 = single-home, 단 절 맨 앞에 둬 *묻히지 않게* — relay-B B). **모든 lifecycle artifact 에 거는 invariant 로 서술**(특정 5-D 목록 설명 아님 — 후속 artifact 도 상속).
  - **Design 경계 = *detail-grade 별* 제외, *decision-grade* 유지**(relay-B A — "direction-only"는 과무딤). 제외 = round/line-level analysis · execution 순서/staging/mechanics · exhaustive enumeration · 정확 marker/field/token 명 · final exact wording. **유지(Design 이 담아야) = semantic target · 개념모델 · chosen trade-off · ownership boundary · target-state invariant · non-goal scope · 대표/경계 예시(exhaustive 아님) · 왜 그 source-of-truth 인지.**
  - **home-routing = *종류별*(버킷 금지; blind C2 + relay-B D).** approval-target→Plan · direction-rationale/개념모델→Design · round-scoped 조사/대안/line-level→Work Packet · durable target-state/normative text→Spec(또는 rule_docs=terminal rule) · execution record/evidence→`log/**` · final wording→Spec/terminal rule. "Plan+WP" 한 버킷 금지(round-scoped 가 Plan 으로 새는 것 차단).
  - **Proportionality = 다른 축 + 핵심 예외.** proportionality = *어느 artifact 를 만드나*(meaning-change 면 lifecycle) / detail-flow invariant = *만든 artifact 가 무엇 담나*. **예외(relay-B C): artifact 생략 ≠ content 승격** — proportionality 가 한 artifact 를 생략해도 그 content 를 다른 home 으로 밀어넣지 않는다(만들거나 버리거나, 밀반입 금지). proportionality 본문 미변경, cross-ref 한 줄.
  - **rule_docs 확정지점 = terminal rule 파일**(domain=Spec 와 대칭; execution-grade 는 여전히 `log/**`, Spec/rule 에 실행순서 lock 금지 — blind C1).
- **validation expectation.** blind(framing-stripped, **Plan-altitude anchor**) + relay-B 정합 + 구현 시 canonical. 내부 정합: Design 경계가 over-restrict(decision-grade 까지 막음) 0 & under(detail 샘) 0 · home-routing 종류별 누수 0 · execution-grade 가 Spec/rule 로 안 샘(blind C1) · detail-flow 가 Proportionality 와 충돌 0(다른 축+예외) · single-home(lifecycle 절) 유지 · candidate-agnostic.
- **review focus.** Design 경계가 decision-grade 까지 over-restrict 안 하는가(relay-B A) · home-routing 이 종류별로 새는 곳 없나 · invariant 가 묻히지 않고 모든 artifact 상속하나 · execution↔target-state grade 혼동 0 · Proportionality 축+예외 정합 · candidate 무관 · rule=자기 spec.
- **Work Packet 필요 = 예.** 편집 대상 절 분류 + 삽입 초안(Design 경계·detail-flow 원칙·축 cross-ref). 흡수 = rule 편집. retire = closeout.

### Open decision close 지점 (5-D)
- **5-D-1**(detail-flow 위치) → **이 Plan 이 닫음**: 기존 lifecycle 절 확장(독립 절 아님).
- **5-D-2**(Proportionality 축) → **이 Plan 이 닫음**: 다른 축, cross-ref 한 줄(본문 미변경).
- **5-D-3**(Design 경계 정확 문구) → Work Packet 삽입 초안 → 구현이 확정.
- **5-D-4**(rule_docs 확정지점 표현) → Work Packet.
- **5-D-5**(altitude 게이트의 checklist 화) → **5-E item**(이 batch 밖).

### ★ 구현 시 정정 (full-scope orchestration; 위 결정 보강)
구현 단계 full-scope blind+relay-B(Codex 규칙 *전문* read — diff 아님; "diff 는 scope 좁혀 놓침" 사용자 교정 반영)가 초안의 **over-absolute invariant** 를 잡아, 위 결정을 다음으로 보강(번복 아님 — scope·예외 추가):
- **invariant scope = *Design→Plan→Spec/terminal-rule lifecycle***(전 artifact 절대 아님). 다른 artifact class(`log/**`·backlog·glossary·active-surface)는 *자기 절이 소유*, invariant 가 재라우팅 안 함(single-home 보존).
- **special-paths carve-out**: `_incubation`(의도적 multi-grade 후보 dossier — *Incubation tier* 소유) · *State migration* carried-over(non-authoritative until judged, 자동결함 아님)는 invariant 밖.
- **Design 경계 nuance**: decision-critical identifier/interface name·*결정 그 자체인* closed enum/taxonomy 는 direction-grade 로 **허용**; exhaustive inventory·final normative(MUST/forbid) wording 만 제외. semantic target = *paraphrasable* statement(Spec 문장 선작성 아님).
- **axis note = proportionality 는 *lifecycle 발동 여부*** 한정(WP/incubation/backlog 는 자기 creation trigger, 여기 미주관).
- **deferred(5-D 밖)**: rule_docs/terminal-rule 의 *Closeout 2-level gate* 부재(blind C2) = 기존 *Closeout* 절의 pre-existing gap → 별도 item(5-E 또는 closeout 보강).
- 정정 후 full-scope re-blind = no-concerns(수렴). final wording single-home = live rule.

**batch-6 — 5-K: promotion 전이 (transition event vs promoted lifecycle; E3/E4 on entry artifact)**
- **목적(한 줄).** promote 의 이중정의(다단계 D→P→S lifecycle ↔ 단일 atomic changeset)를 "전이 이벤트(=`_incubation`→entry artifact swap) vs promoted lifecycle" 분리로 해소하고, E4 흡수 대상·E3 경계를 entry promoted artifact 기준으로 명확화.
- **scope.** 다루는 것 = *Incubation tier* 의 Candidate lifecycle(promote 문단)·3-state(active)·E3 문단의 promotion-transition 정정. 안 다루는 것 = 5-B blueprint 상태머신(별도 item) · 후보 콘텐츠 · Proportionality 의 Design-collapse 재정의(reference만) · taxonomy.
- **batch 단위 = 단일 JOIN.** 세 문단은 한 transition 의 인접 진술(쪼개면 transient 모순).
- **hard boundary.** ① taxonomy 불변(`_incubation`=file artifact; 5-D 가 `_incubation` 을 Lifecycle-invariant special-path 로 carve-out 한 것과 정합) ② E4 흡수 = removal 의 precondition 보존(batch-3) ③ no committed coexistence(E3 intact) ④ atomicity = E3-intact 보장에만(상태 marker 는 5-B; 5-K 는 그 자리 안 만듦) ⑤ 5-D landed 모델(Lifecycle invariant·Design decision-grade) 정합 ⑥ rule=자기 spec-of-record.
- **open decision close(이 Plan 이 닫음).**
  - **entry promoted artifact = `_design.md`** — domain·rule candidate 둘 다 Design 으로 시작(현 규칙 "Design→Plan→Spec"/"Design→Plan→rule"). 전이 = `_incubation`→`_design` swap. (trivial candidate 의 proportional collapse 는 *Proportionality rule*+5-D axis 소관 — 5-K 재정의 안 함, reference만.)
  - **E4 흡수 대상(swap 시점) = entry promoted artifact(`_design`)**, swap 시점 *완전*(removal precondition). 현 "the promoted Design / Plan / Spec, or the terminal rule file" 나열 → "the entry promoted artifact" 로 정밀화. 나머지 current-bearing 은 정규 lifecycle carry(Design→…→Spec/rule, promoted-lifecycle closeout 이 1:1).
  - **E3 transition-aware** — binding window = `_incubation.md` 존재 기간; swap = incubation 종료 경계(공존0 = E3 intact).
  - **atomicity 역할 한정** — "single changeset that writes the promoted artifacts and removes `_incubation`" → **swap(`_incubation` out, `_design` in)**으로 명확화. atomicity 는 *공존0(E3-intact)* 보장이고, 전이 산출물이 어떤 *상태*인가는 5-B marker 소관(미landing).
  - **transient 봉합 fallback** — 5-K landing 시 post-swap pre-live 상태는 기존 *Spec identity* time-phasing(writing-completion blueprint → implementer reference → closeout live)을 따른다는 보수적 한 줄(5-B 가 명시 marker 로 승격할 자리).
- **validation expectation.** full-scope blind+relay-B(규칙 전문, diff 아님) + canonical dual. 정합: batch-3 atomic-transition·E4-precondition / 5-D invariant 의 `_incubation` carve-out / *Incubation tier* 다른 문단(`_incubation` 정의·E1·E4·E5)·*State migration* / Document artifact classes #2.
- **review focus.** swap 재정의가 batch-3 와 정합(정밀화·번복 아님) · entry-artifact 가 lifecycle("Design→…")과 정합 · E4-precondition 보존(손실/raw 둘 다 아님) · atomicity 과적재 0 · 5-D `_incubation` carve-out 과 충돌 0.
- **Work Packet 필요 = 예.**

### Open decision close 지점 (5-K)
- 5-K-1(entry artifact) → 이 Plan: `_design.md`(domain·rule 공통); collapse=Proportionality 소관.
- 5-K-2(E4 대상·precondition) → 이 Plan: entry artifact, swap 시 완전(batch-3 보존).
- 5-K-3(atomicity 역할) → 이 Plan: E3-intact 보장만; 상태=5-B.
- 5-K-4(transient fallback 문구) → Work Packet → 구현 확정.
- 5-K-5(batch-3/5-D 정합 clause-map) → Work Packet(구현 시 lightweight).
- **★ 구현 정정(full-scope orchestration)**: rule-candidate entry 일관화(entry=`_design`, terminal rule=eventual output) · Proportionality-collapse hedge 제거(promotion=normative→min `_design`; collapse 미위임) · E4 흡수 by-kind(decision-grade→`_design`·never WP / round-scoped→WP) · filename↔live-authority 분리. 전체 discovery/state-machine·rename-lineage = **5-B**. 상세 = WP 5-K 노트.

**batch-7 — 5-B: promote-but-not-live 상태머신 (5-K 의 yes-with-risk 를 닫음)**
- **목적(한 줄).** swap 이 낳는 promoted-but-not-live 상태를 규칙에 정의 — lifecycle-state marker · 2층 discovery · de-promotion · open-Q routing · E3 rename-lineage. (5-K SC canonical 의 deferred risk 를 닫는다.)
- **scope.** 다루는 것 = *Spec identity*(prelive marker) · *Incubation tier* E1(2층 discovery) · *State migration*(de-promotion) · open-Q routing(*Incubation applicability* §Open → *Future-work queue*) · *E3*(rename-lineage). 안 다루는 것 = 5-K/5-D 재litigate · 후보 콘텐츠 · marker 기계검사(5-E) · taxonomy.
- **batch 단위 = 단일 JOIN.** prelive 상태의 여러 면(marker·discovery·de-promotion·open-Q)은 한 상태머신 — 쪼개면 transient(상태 정의했는데 discovery/되돌리기 미정).
- **hard boundary.** ① 5-K landed(swap·entry·filename↔authority)·5-D(invariant·carve-out) 정합 ② marker 명 ≠ *Spec identity* 형용사 'blueprint'(충돌 회피) ③ de-promotion = history-preservation(identity-monotonic 아님 — candidate 부활 *허용*, 기록된 withdrawal) ④ rule/domain 비대칭(rule=no Spec) ⑤ rule=자기 spec-of-record · taxonomy 불변 · single-home(다른 절 재소유 0).
- **open decision close(이 Plan 이 닫음).**
  - **marker 명 = `prelive`**(promoted-but-not-live). *Spec identity* lifecycle-state = `prelive` / `sync-required` / `live`. ('blueprint'=형용사로 보존.)
  - **2층 discovery**: `governance-discoverable`(prelive 포함 — 리뷰·lifecycle 추적) vs `implementation-authoritative`(live/sync-required only). prelive 는 전자 O 후자 X. E1 에 명시(단순 발견≠live authority).
  - **de-promotion = 기록된 withdrawal**(history-preservation): `promotion-withdrawal` changeset 으로 incubation 재개 *허용*(marker 동반); 무기록 silent rollback 금지; **live 후엔 de-promotion 금지**(repeal/supersede 별도). *State migration* 에. (내 5-K 의 "candidate 부활 불가"는 5-D 에서 이미 retract — 그 모델 계승.)
  - **open-Q routing**: 미해결 incubation open-Q at promotion → 도메인 `<domain>_backlog.md`(있으면) / 없으면 entry-artifact 의 `Deferred Questions` 절(Plan 때 backlog 흡수); **미해결 open-Q = live 전환 차단**.
  - **rule/domain 비대칭**: domain = Spec lifecycle-state 에 prelive marker; rule = 3-state "active lifecycle work" 가 이미 prelive 등가(rule 파일은 terminal landing 까지 부재 → E1 discovery 대상 아님). marker 본체 = domain Spec; rule 은 기존 3-state 로 충분(명시만).
  - **E3 rename-lineage**: E3 의 sibling 금지를 candidate / successor-id / rename-target 로 확장; promotion changeset 이 source `_incubation` disposal/rename + target `_design` creation 을 같은 changeset.
- **validation expectation.** full-scope blind+relay-B(규칙 전문) + canonical dual. 정합: 5-K swap·5-D invariant·*Spec identity*·E1~E5·*Live-Spec update*(sync-required ≠ prelive)·*State migration*·*Future-work queue*.
- **review focus.** prelive 가 'blueprint' 형용사·sync-required 와 구분 · 2층 discovery 가 E1·*Final hard rule* 과 정합 · de-promotion=history-preservation(identity 아님) · open-Q 손실 0 · rule/domain 비대칭 명확 · single-home(재소유 0).
- **Work Packet 필요 = 예.**

### Open decision close 지점 (5-B)
- 5-B-1(marker 명) → 이 Plan: `prelive`.
- 5-B-2(2층 discovery) → 이 Plan: governance vs implementation-authority.
- 5-B-3(de-promotion) → 이 Plan: 기록된 withdrawal(history-preservation), live 후 금지.
- 5-B-4(open-Q routing) → 이 Plan: backlog/Deferred-Questions fallback, live 차단.
- 5-B-5(rule/domain 비대칭) → 이 Plan: domain=Spec marker / rule=기존 3-state.
- 5-B-6(E3 rename-lineage) → 이 Plan: lineage(candidate/successor/rename) 확장.
- 5-B-7(정확 문구) → Work Packet → 구현 확정.

**batch-8 — 5-E: enforcement (settled 모델의 강제/게이트; `09aced5` risk close)**

> 5-E Design(direction-level) settle 후 그 위에서. **이 Plan 의 일 = batch 단위·scope·hard boundary 확정 + Design 의 open(5E-R1/R2/SC/transition/defer-home) close.** 정확 로직·regex·문구·test 케이스 = WP/구현. cs1 닫지 않음. 운용 = mode-2 + full-scope orchestration. **mutation/commit/push 승인 아님.** (sequencing: 사용자가 `09aced5` risk 우선으로 5-E 를 5-G/5-X/5-T *앞에* 둠 — DAG "5-E 최후"는 *본문 settle 후* 의미이고, 5-E 는 *현재 settled* 모델만 강제; 미landing 5-G/5-X/5-T 는 pre-enforce 안 함.)

- **목적(한 줄).** 5-D/5-K/5-B + batch-1~4 가 settle 한 의무를 3-tier(MS/SC/PCG)로 강제·게이트해 `09aced5` 의 *구조적* enforcement gap 을 닫는다(consumer-behavior 는 NSE — 정직 scope).
- **batch 단위 = 단일 JOIN(R1 은 guarded sub-decision).** check(MS)+checklists(SC)+template(form)+closeout terminal-rule(PCG/R1)은 *한 모델의 enforcement* — 쪼개면 transient(check 가 강제하는데 checklist 미게이트, 또는 역). 한 changeset. **단 R1 rule-text 편집은 *유일한 normative-text 터치*라 hard boundary 로 격리**(tight 제약 위반 시 즉시 split).
- **scope.** *다루는 것* = (MS) `docs-working-model-check.ps1`+`tests/...Tests.ps1`: E2 scan 에 `snippets/rules/` 추가 + promoted `_spec.md` 의 Lifecycle-state marker **validity**(허용 token[`prelive`/`sync-required`/`live`] 정확히 하나 — 단순 section presence 아님; relay-B 보정). (SC) checklists: Design checklist 에 5-D altitude/detail-flow 게이트 + Spec checklist 에 Lifecycle-state 절 + **신규 promotion-boundary/promoted-but-not-live checklist**(prelive-소비 인식·withdrawal 기록[=De-promotion]·open-Q routing/live-block·E4 흡수). (form) spec template Lifecycle-state field convention 확인(이미 prelive/sync-required/live — SC 가 검사가능하게). (PCG/R1) closeout *terminal-rule Level-2 variant*. (rule-text clarify/L104) line 104 parenthetical disambiguation — "the mechanical check for this model" 이 *terminology-registration model* 임을 명시(meaning-preserving; dialectic 산; 새 의미/gate 0). *안 다루는 것* = broader 인벤토리(durable-pointer 일반 scan·docs/ 도메인 purity·terminology state-machine·rejected-term sweep·review-date staleness·WP-content checklist·**E3 cross-folder rename-lineage[known hard residual]**) · 미landing 5-G/5-X/5-T · 후보 realign(Phase 2) · taxonomy.
- **hard boundary(불가침).** ① **enforcement = bounded normative completion at most(5E-c1)**; rule-text 터치 *2건*(둘 다 bounded): **(R1)** *terminal rule 파일=Level-2 surface 매핑*에 한정(이는 *minimal 새 gate-failure 조건 1개*[closeout 이 terminal rule 파일 inspect/report]을 *낳음을 인정* — relay-B: "no meaning change" 과장 철회, "bounded completion"으로 정직히; 새 파일/backlog/state-store/의미-field 만들면 즉시 split/Stage rewind). **(L104)** line 104 parenthetical disambiguation — *meaning-preserving*(새 의미/gate 0; 'this model'='terminology-registration model' 명시; dialectic 으로 확인된 기존 의미를 *명시화*만). proportionality = wording cleanup 급이라 R1 보다 가볍지만 같은 rule-text 라 같은 batch. **(+EN-6-wiring; canonical SC pass-01 corrective)** EN-6 promotion checklist 를 rule package 의 *manifest*(Package note 열거 + conformance gate enumeration) + *application trigger*(promotion-boundary/promoted-but-not-live event 가 promotion checklist 를 통과해야)에 배선 — 이는 **descriptive routing = EN-6 완성**이지 새 normative 규칙 아님(미배선 checklist 는 죽은 deliverable; canonical SC 가 "package routing 미배선"을 blocking 으로 포착). normative touch 는 여전히 EN-8/EN-9 둘. ② **transition clause(line 104) — 5-E *완결*(★ dialectic 확정).** 구조검사 E1/E2/E3(5-E 신규 포함)는 *즉시 binding*(line 105 "rule requirements now"); anchored 후보 3종은 *conform 하여 pass*(`_spec` 없음·durable snippets ref 없음 → newly-fail 0 = 회피 아닌 *통과*). transition 유예 = *terminology-registration check* 한정(5-E 비대상) → 미이행 transition 의무 0("deferred 일반 mechanism" phantom 회수). exemption registry 불요. *유일 잔여* = line 104 parenthetical 용어 애매(wording residual). ③ **명제=tier 하나**(중복강제 금지) · **hazard=多tier 허용**(5E-c2). ④ **over-claim 금지**(prelive 소비 NSE; "구조 gap 닫음"만, "consumer behavior 닫음" 금지). ⑤ 후보 미터치(P0-6) · taxonomy 불변(P0-1) · rule=자기 spec-of-record(P0-3; 별도 `_spec` 금지). ⑥ `.ps1` UTF-8 BOM+CRLF.
- **open decision close(이 Plan 이 닫음).**
  - **5E-R1 → 5-E 내 포함(bounded normative completion).** closeout *Level 2* 에 "rule_docs/terminal-rule path 의 Level-2 surface = **terminal rule 파일 자체**(1:1 sync 확인); rule 은 backlog 없어 open-Q 는 terminal landing 전 resolve" 매핑 한 줄. *minimal 새 gate-failure 조건 1개를 낳음을 인정*(closeout 이 terminal rule 파일 inspect/report) — "no meaning change/no new gate condition" 과장 철회(relay-B). split 안 함(매핑 minimal·mechanism batch 와 응집)이되 **WP review 기준 = "R1 diff 가 이 한-문장 매핑 초과 시 즉시 split"** 박음. tight 제약 = hard boundary ①.
  - **5E-R2(MS scope) → narrow: *구조적* gap 만.** = E2 `snippets/rules/` scope + promoted `_spec.md` Lifecycle-state marker *validity*(허용 token 하나). **닫는 것 = no-marker/wrong-marker 구조 공백**; **닫지 *못하는* 것 = same-path prelive 오소비(NSE — 정적 검사가 소비자 행동 못 봄; 명시 residual)**(relay-B over-claim 철회). 그 외 MS-가능(durable-pointer 일반·docs purity·review-date·rejected-sweep·E3 cross-folder)은 defer(over-mechanize 차단).
  - **SC 구조 → 기존 *확장* + 신규 *1개* 최소.** Spec checklist + Design checklist 확장(Lifecycle-state 절·altitude 게이트); prelive-소비/withdrawal/open-Q/E4 는 **신규 promotion-boundary/promoted-but-not-live checklist 1개** — **범위 = *promotion-boundary / promoted-but-not-live event* 에만 한정** — promotion·discard(candidate-lifecycle closeout) + de-promotion/withdrawal(promoted-but-not-live reversal = *State migration* 소관, candidate-lifecycle closeout *아님*; re-blind 용어 보정) (creep guard: "candidate lifecycle 전반"으로 키우면 mini-rule 化 — relay-B). design/plan/spec/closeout 와 다른 lifecycle event = candidate→promoted 전이 → 별 checklist 가 single-home. WP-content checklist 는 defer.
  - **transition-awareness → 5-E *완결*(★ dual-lens dialectic; codex CONCEDE Reading 1).** 구조검사 즉시-binding·후보 conform-pass; transition 유예 = terminology-check 한정(5-E 비대상). rule 텍스트 추가 0. *유일 잔여* = line 104 parenthetical `(docs-working-model-check.ps1)` 용어 애매 — 5-E 선택적 명료화 가능(Plan; rule-text 라 5E-c1 경계) or 명시 residual; 정확 = WP.
  - **deferred 인벤토리 행선지 → Plan-close = roadmap-listing(WP 조사 완료).** (a) rule thin pointer=*3번째 rule-text 터치*(scope-creep, narrow 위반) 기각 / (b) closeout report=log gitignored(durable 아님) 기각 / (c) 새 backlog mechanism=과통합 기각 → **deferred 목록을 `_design.md` Phase-1 roadmap 의 5-G/5-X/5-T *옆* follow-on 으로**(silent-drop 아님). durable 이전은 *cs1-closeout 의 roadmap-migration*(5-G/5-X/5-T 와 동일 운명 = 기존 cs1 의무이지 5-E 고유 부담 아님). → 5-E rule-text **2건 유지**(R1+L104; deferred-home 은 rule 미터치).
- **validation expectation.** verify-ps1(UTF-8 BOM+CRLF) PASS · **full Pester green**(신규 케이스 포함) · `docs-working-model-check` 가 **현 repo 에 PASS**(in-flight 후보 3종 *conform-pass*, newly-fail 0) · full-scope blind+relay-B(규칙+check+checklist+template 전문) 수렴 · canonical dual PASS.
- **review focus.** E2 snippets-scope 가 false-PASS 닫고 over-reach 0(실제 durable ref 만) · Lifecycle-state marker check 가 후보 newly-fail 0 · R1 이 의미-완성 한도 내(새 surface/backlog 0) · 명제=tier 하나 위반 0 · prelive over-claim 0 · transition: 구조검사 즉시-binding·후보 conform-pass(5-E 완결; terminology-check 만 유예) · candidate-agnostic · rule=자기 spec.
- **Work Packet 필요 = 예.** 편집대상 절/스크립트 라인 분류 + check 로직 초안(marker-token validity 포함) + 신규 test 케이스 + checklist 문구 초안(altitude·Lifecycle-state·promotion) + R1 closeout 한 줄 초안 + **deferred-enforcement 목록의 *durable* 보존처 확정**(Design/Plan/WP 는 closeout 시 retire → 거기 두면 silent-drop; durable home 필수 — blind 보정) + transition 정확 표현. 흡수 = 구현. retire = closeout.

### Open decision close 지점 (5-E)
- 5E-R1 → 이 Plan: 5-E 내 포함(bounded normative completion — minimal 새 gate-failure 조건 인정; WP "diff>한문장→split" 기준).
- 5E-R2 → 이 Plan: MS = E2 snippets + Lifecycle-state marker *validity*(token 하나); no-marker 구조 gap 만 닫음(same-path 오소비 = NSE residual 명시); 그 외 defer.
- 5E-SC → 이 Plan: 기존 확장(Spec/Design) + 신규 promotion-boundary/promoted-but-not-live checklist 1개(promotion·discard + withdrawal[=De-promotion taxonomy]); WP-content checklist defer.
- 5E-transition → 이 Plan: 5-E *완결*(★ dialectic; codex CONCEDE Reading 1) — 구조검사 즉시-binding·후보 conform-pass; transition 유예=terminology-check 한정(5-E 비대상); rule 텍스트 0; *유일 잔여*=line 104 parenthetical 용어 애매(WP).
- 5E-defer-home → 이 Plan(closed): roadmap-listing(`_design.md` 5-G/5-X/5-T 옆 follow-on); rule-text 아님(2건 유지); durable 이전=cs1-closeout roadmap-migration(기존 의무).
- 5E-E3residual → 이 Plan: known hard residual 로 *명시 defer*(silent drop 금지).
- 정확 로직/regex/marker 토큰/test/문구 → Work Packet/구현.
