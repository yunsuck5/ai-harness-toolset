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
