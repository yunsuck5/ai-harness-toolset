# consultation Incubation (candidate — non-authoritative)

## Header

**이 문서는 무엇인가.** `consultation` **candidate** 의 단일 planning home 이다 — docs-working-model 의 *Incubation tier*(pre-promotion candidate stage)에 있는 domain candidate 가, domain 으로 승격할지 평가받는 동안 사용하는 유일한 committed-temporary 문서다. 이 candidate 는 read-only advisory consultation 을 정규 domain 으로 둘 가치가 있는지 dogfood 로 검증한다.

**non-authoritative.** 이 문서는 **canonical authority 가 없다** — canonical *form* 을 쓰더라도 §*Spec identity* 의 canonical Spec 으로 해석되지 않는다. canonical rules/indexes 는 이 문서를 durable reference 하지 않으며(E2), 이 문서를 읽어야만 동작하는 canonical 표면은 없다(E1/E3). 본문의 결정은 모두 후보 수준이며, 정규 authority 는 promote 시점에야 생긴다("form early, authority late").

**promote 시 무엇이 되는가.** review-date 판정에서 **promote** 되면 `docs/consultation/` 가 새 domain 의 home 이 되고, 이 문서의 current-bearing 내용이 E4 로 흡수되어 도메인-prefixed role 파일(`consultation_design.md` / `consultation_plan.md` / `consultation_spec.md`)의 Design → Plan → Spec lifecycle 로 들어간 뒤, 이 `_incubation.md` 는 삭제된다.

**discard 시 무엇이 삭제되는가.** **discard** 되면 유일한 committed artifact 인 `docs/consultation/consultation_incubation.md` 가 흡수 없이 삭제되고, 폐기 사유(끝낸 negative evidence)는 discard commit message 에 남아 git history 가 보존한다.

**owner.** 사용자(operator) — review-date 마다 promote / discard / continue 를 결정하는 주체.

**review-date.** 최초 consultation pilot **3회**(조정가능) 누적 시점에 첫 판정을 한다. 이 count 는 *판정 트리거*일 뿐 자동 종료가 아니며(판정 결과는 promote / discard / **continue** 모두 가능; *No round cap*), operator 가 그 전에 ready / dead 로 판단하면 조기 판정한다. pilot 누적의 측정은 gitignored runtime 영역에 두며 이 문서가 경로로 durable 참조하지 않는다.

**open questions.** promote 전에 닫아야 할 주요 미해결 결정은 §Open questions 에 둔다(이 Header 는 pointer, 내용 home 은 그 절).

**이 문서가 아닌 것.** canonical Spec 아님 · operative authority 아님(behavior 는 active surface 가 소유) · 용어 정의의 single home 아님(`rules/terminology-glossary.md`) · code review 아님 · blind advisory 아님. 이 문서는 어떤 mutation / commit / push / release 도 승인하지 않는다(1회 진술).

## Admission record (incubation tier 진입 요건)

- **기존 domain/rule 이 못 덮는 구체 문제.** 현 모델에는 최종 verdict 를 내리는 review(canonical artifact gate, `yes` / `no` / `yes with risk`)와, changeset 결함 pre-filter 인 blind advisory 가 있다. 그러나 operator 가 변경·승인·판정을 하기 *전에* 복수 AI 의 관점·반론·조사 의견을 read-only 로 수집하고 이를 **비권위 advisory 입력으로 어떻게 다룰지**에 대한 단일 규칙 home 이 없다. 그 결과 이 활동이 review 처럼 오인되어 승인 효과를 갖거나, 반대로 임의의 sub-agent / research 관행으로 흩어져 권한 경계와 산출물 지위가 불명확해진다. 이 gap 은 review·blind·brief·install-update·docs-working-model 어디에도 흡수하기 어렵다.
- **candidate shape.**
  - single authoritative home(promote 시): `docs/consultation/`.
  - incubation file(현재): `docs/consultation/consultation_incubation.md` — 단일 planning home(별도 `_design` / `_plan` / `_spec` 없음).
  - success-absorption artifact(promote): `docs/consultation/consultation_design.md` / `consultation_plan.md` / `consultation_spec.md` lifecycle 로 흡수.
  - failure-deletion target(discard): `docs/consultation/consultation_incubation.md`.
  - **broad bucket 아님** — scope 는 아래 §목표 상태로 강하게 잠근다.
- **owner / review-date.** 위 Header 참조.
- **discard 기준(review-date 에서 죽일 수 있는 negative evidence).**
  1. 실제 사용 사례가 review · blind advisory · 기존 orchestration 규칙으로 충분히 설명되어 **독립 가치가 미입증**된다.
  2. consultation 산출물이 반복적으로 verdict · approval · merge / push / release 의 근거처럼 사용된다(advisory 경계 붕괴).
  3. scope 가 "AI 협업 전반" · "sub-agent 사용 전반" · "general research" · "debate workflow" 로 계속 확장되어 단일 권한 경계를 유지하지 못한다.
  4. promote artifact 가 하나의 authoritative home 으로 수렴하지 못하고 여러 domain 에 흩어진 cross-cutting policy 가 된다.
  5. consultation 과 blind advisory 의 차이가 사례 수준에서 명확히 유지되지 않는다.
  6. domain-local closure 실패 — consultation 의 의미가 review 의 semantics 를 읽어야만 설명된다(그렇다면 독립 domain 이 아니라 review 하위 기능).
  7. "read-only" 가 문서상 주장뿐이고, 실제 워크플로에서 consultant 가 파일 변경 · verdict 작성 · 승인 판단 · gate 통과 조건을 맡는다.

## 목표 상태 (candidate — non-authoritative)

**좁은 single-home scope.** consultation 은 operator 가 아직 판정·승인·변경(mutation)을 하지 않은 상태에서, 하나 이상의 consultant(외부/서브 AI)에게 **read-only 의견·반론·조사·관점 수집**을 위임하고 그 응답을 **operator synthesis** 로 종합해 후속 작업의 우려·가설·대안·조사 방향을 정리하는 **advisory workflow 의 거버넌스**다. consultation 은 verdict 를 내리지 않고, commit / push / release / adoption 을 승인하지 않으며, 다른 domain 의 source-of-truth 를 대체하지 않는다.

**명시 제외(broad-bucket 방지).** consultation 은 다음을 다루지 **않는다**: code review(= review domain) · blind advisory(= 별개 candidate/레이어) · implementation delegation · 모든 sub-agent orchestration 전반 · 모든 외부 AI 호출 전반 · general research / debate workflow 전반 · 모든 operator 의사결정 보조 · evidence / validation / approval 의 대체. 핵심은 "AI 에게 묻는 모든 것"이 아니라 **판정 없는 read-only 자문 호출의 거버넌스**로 한정하는 것이다.

## consultation 의 정체 (invariants)

- **read-only 기본값** — consultant 는 inspection 만, mutation 없음.
- **advisory only** — 산출은 advisory input 이며 어떤 결정도 승인하지 않는다.
- **operator synthesis 필수** — consultant 응답은 그대로 source-of-truth 가 되지 않고, operator 가 책임지고 우려·가설·대안·확인 질문으로 분류·종합한다.
- **consultant output 은 truth oracle 이 아님** — 외부 AI 주장의 진위는 consultation 이 보증하지 않는다.
- **secret/private boundary** — 외부 상용 AI 호출 시 입력 redaction·민감정보 경계가 필요(전역 security 규율과 interface; consultation 이 넓게 소유하지 않음).
- **vocabulary 분리** — canonical review 의 verdict / pass / finding 어휘, blind advisory 의 concern 어휘와 섞지 않는다.
- **타 domain 으로는 interface 만** — 넘길 때 operator 가 중립화한 형태로만 전달한다(§Cross-domain interface).

## Owner surface 후보 (skill-first)

초기 owner surface 는 **skill** 이 가장 적합하다 — 자연어 UX 와 advisory workflow 가 핵심이므로 script-heavy 로 시작하지 않고, 반복 invocation adapter 가 안정화된 뒤 script / config 로 낮춘다. 현재 운용은 **임시·실험 relay 도구로 pilot** 중이며(정규 기능 아님, 이 문서의 authority 아님), 이 문서는 그 도구에 경로로 의존하지 않는다 — 운용 모델 자체는 아래 §Operating model 에 자기완결로 적는다. blind advisory 는 별개 candidate/레이어로, 이 candidate 의 owner surface 가 아니다.

## Vocabulary (domain-local 정의 — 후보)

> 용어 의미의 single home 은 promote 시 `rules/terminology-glossary.md` 가 된다. 아래는 incubation 동안의 domain-local 후보 정의이며, 이 문서가 review/blind 의 semantics 를 읽지 않고도 닫히도록 자체 정의를 둔다.

- **consultation** — 위 §목표 상태의 advisory workflow.
- **consultant** — consultation request 에 응답하는 외부 AI · 서브 AI · 도구화된 advisory participant. reviewer 가 아니다; repository mutation 권한이 없다.
- **consultation request** — operator 가 consultant 에게 전달하는 제한된 질문 · context · 허용 inspection scope · 제약의 묶음.
- **consultation response** — consultant 가 반환한 advisory 의견 · 조사 결과 · 반론 · 가설 · caveat.
- **operator synthesis** — operator 가 하나 이상의 response 를 읽고 후속 작업용 우려 · 가설 · 대안 · 확인 질문으로 종합한 결과(외부 AI 응답을 source-of-truth 로 쓰지 않는 경계).
- **advisory preflight** — 최종 review / implementation / decision 전에 read-only advisory 계층을 돌려 risk · open question · alternative 를 확인하는 선택적 사전 단계.
- **status vocabulary** — consultation 자체에는 canonical verdict 를 쓰지 않는다: `synthesized` / `needs-follow-up` / `conflicting-opinions` / `insufficient-context`. 이는 review 의 `yes` / `no` / `yes with risk` 와도, blind advisory 의 `no-concerns-reported` / `concerns-reported` / `inconclusive` 와도 분리된다.
- **packaging mode(consultant topology 축)** — `single-consultant` / `parallel-consultation` / `role-split-consultation` / `counterpoint`(반론 생성). `roundtable`(1차 응답 종합 후 2차 반론)은 비용·contamination 위험이 커 후속 후보. `council` 은 domain 명이 아니라 pending packaging alias 다.
- **relay mode(framing 축 — packaging 과 직교)** — `mode A`(pre-focus 독립: operator 가 자기 초안을 만들기 전에 호출, 자기 입장 미포함) / `mode B`(내-stance 공유: 진행 중인 초안/입장을 공유하고 반론·정렬을 받음). §8 packaging 축과 조합 가능하다.

## Operating model (relay a/b + pre-focus timing)

- **pre-focus 원칙.** advisory 의 가치는 operator 의 포커스가 고정되기 전에 호출할수록 크다 — 이미 작업/설계를 시작한 뒤 호출하면 포커스가 그쪽으로 잡혀 종합이 편향된다.
- **권장 운용.** 방향-설정 지시 수신 즉시 → (백그라운드) mode A 먼저 → operator 독립 정리 → 합쳐 방향 논의 → 진행 → 진행 중 모호/외부관점 필요 지점에서 재호출(A 또는 B).
- **세 시점 모두 유효.** 작업 *전*(pre-focus) · 작업 *중*(모호점) · 작업 *후*(review 전 advisory preflight chain) — 배타가 아니라 추가 타이밍이다.
- **mode B 와 blind 의 분리 근거.** mode B 는 framing 을 *제공*하고, blind advisory 는 framing 을 *제거*한다(operator framing 이 판정을 기울이는 것을 막기 위해). framing 에 대해 **정반대 동작원리**이므로 같은 동작이 아니며, 따라서 별개 레이어로 둔다(원칙: 동작원리가 다르면 구분; 합치려면 하나의 동작임을 입증).

## Cross-domain interface — review (optional advisory preflight only)

- review domain 은 consultation 의 semantics 를 소유하지 않는다. consultation 은 review 의 **optional advisory preflight** 로만 연결된다.
- review 로 넘기는 정보는 operator 가 중립화한 것만: 확정 우려 → `Known concerns`, 열린 반론/의심 → `Review questions`(`verify whether...` 형태), 배경 → `Context`(결론 유도 표현 제거).
- 금지: consultation 결과를 `yes` / `no` / `yes with risk` 로 변환 · consultation 을 review invocation / pass / coverage count 에 합산 · consultation transcript 를 `log/review/**` 에 저장 · consultation concern 을 `Blocking findings` 의 source-of-truth 로 승격 · canonical reviewer 에게 consultation 결론을 신뢰하라고 지시.
- canonical reviewer 는 target 을 독립 검증하며 consultation 결론을 advisory 로만 취급한다.
- review skill 통합은 로드맵상 **최후 단계**다 — consultation 과 blind advisory 가 독립적으로 닫힌 뒤에만 review 가 optional preflight consumer 가 된다(premature integration 금지).

## Open questions

- consultation 결과를 runtime artifact 로 남길지, 아니면 conversational synthesis 로만 둘지 — 초기에는 저장을 강제하지 않는다. 남긴다면 review runtime 영역(`log/review`)과 **분리된 별도 runtime 영역**이어야 하지만, 그 **구체 경로 값은 이 incubation 문서가 정하지 않는다** — durable boundary 원칙상 구체 runtime 경로는 promote 시 active surface 가 소유하므로, 어떤 concrete path 도 여기서 owner-surface 결정으로 굳히지 않는다.
- 외부 상용 AI 호출 시 입력 redaction 과 secret boundary 를 어디에 둘지(전역 security 규율과의 interface).
- sub-agent 만 지원할지, 외부 CLI / API adapter 도 지원할지.
- output vocabulary 를 어디까지 고정할지.
- consultation 과 blind advisory 의 순서가 항상 고정인지, 요청별 선택인지.
- review skill 이 consultation / blind preflight 를 자동 호출하는 기본 조건(있다면).

## Candidate lifecycle state

- **현재 상태**: incubating(non-authoritative). 이 문서는 canonical *form* 으로 성숙해 가지만 authority 는 promote 시점에야 생긴다.
- **review-date trigger**: pilot 3회(조정가능) 누적 후 첫 판정. count 는 트리거일 뿐 자동 종료가 아니다(*No round cap*) — operator 의 ready/dead 판단으로 조기 판정 가능.
- **continue 시 새 review-date 필수**: 판정이 continue 이면 반드시 **새 review-date 를 설정**한다(count 목표 또는 날짜로 갱신). live review-date 없는 candidate 는 non-conformant 이며, review-date 가 미판정으로 지나면 candidate 는 그 시점부터 stale(판정 전까지 비정합)이다.
- **promote 경로**: `docs/consultation/` → domain home; 본문 current-bearing 내용 E4 흡수 → `consultation_{design,plan,spec}.md`; 그 후 `_incubation.md` 삭제.
- **discard 경로**: `_incubation.md` 삭제(흡수 없음); 사유는 discard commit message(git history 보존).

## Incubation invariant conformance (E1~E5)

- **E1** — domain discovery 는 promoted canonical artifact 로만 한다. `docs/README.md` §5 domain map 과 `rules/README.md` 는 `docs/consultation/` 를 discovery / domain target 으로 링크·경로 참조하지 않는다(이 folder 는 `_incubation.md` 만 보유하는 non-domain candidate container). 허용되는 것은 thin candidate-tracking 메타(name / owner / review-date)뿐이며 현재는 추가하지 않는다.
- **E2** — canonical rules / indexes 는 이 `_incubation.md` 를 durable path / link 로 참조하지 않는다. canonical → candidate 참조는 promote 시 E4 의 absorbed-conclusion summary 로만 가능하다.
- **E3** — `docs/consultation/` 에 `_design` / `_plan` / `_spec` sibling 을 incubation 중 생성하지 않는다(이 folder 는 `consultation_incubation.md` 단일).
- **E4** — promote 시 흡수는 adopted conclusion / rejected alternatives / 판단을 바꾼 evidence type / scope / failure(discard) criteria / known negative evidence 를 담아 "왜 살아남았는가"가 raw link 없이 재검토 가능해야 한다(promote 단계에 적용).
- **E5** — 이 문서는 rule 자신의 incubation-tier bootstrap 이 **아니다**. incubation tier 의 첫 정규 candidate dogfood 이며, E1~E4 가 정상 적용된다(E5 의 one-time bootstrap 면제 대상 아님).
