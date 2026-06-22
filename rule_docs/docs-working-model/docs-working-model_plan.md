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
- **목적(한 줄).** glossary 를 incubation 하위 절차에서 분리하고, 의미확정을 owner-surface close(review 직전)로 옮기며, incubation applicability·contrast 허용선·transition 을 명문화.
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

## Open decision 의 close 지점

- **R1**(check-script 가 in-flight 에 걸림) → **이 Plan 이 닫음**: check-script 는 cs2 로 이연(transition-aware).
- **R2**(finalization-before-review 정합) → batch-1 구현 중 규칙 본문 대조로 닫음.
- **R3**("충돌 가능 이름"/"완화" 모호성) → batch-1 규칙 본문 (A)/(C)(최소 기준 + default strict + 중재자 = glossary rule owner).
- **R4**(rule candidate closeout 경계) → batch-1 규칙 본문 (B)(terminal rule landing changeset 내 + exposed pending term 처리).

## Stage rewind 조건

- **Plan 이 Design 위반**(예: 완전 matrix/재구조화로 확장) → stop, Design 재설계 후 Plan 재시작.
- **구현이 Spec(=rule) boundary 초과**(예: stash 된 candidate 콘텐츠 수정 · 별도 `_spec.md` 생성 · rejected umbrella 부활) → stop & 사용자에 확인, 조용한 scope 확대 금지.
