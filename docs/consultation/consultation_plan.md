# consultation Plan

> Plan 은 승인 대상인 의사결정만 담는다 — 작업 메모가 아니다(조사·분류·구현 노트는 Work Packet, 실행 순서·기록은 operator report `log/**`). Plan 이 Design 을 위반하면 stop → Design 재설계 후 재시작. closeout 시 흡수 후 retire(삭제). 이 Plan 은 mutation/commit/push 승인이 아니다.

## Header

- 이 문서 = consultation candidate promote 의 **Plan** — Design(방향)을 승인-대상 결정(batch 순서·scope·boundary·validation·review focus·Work Packet 선언·open decision close)으로 구체화한다.
- 이 체인이 끝나면 = `consultation_spec.md` 저작으로 내려가고 이번 promote changeset 의 실행 경계가 확정된다. promoted-lifecycle closeout 시 retire.
- 이 문서가 아닌 것 = Design(방향) 아님 · Spec(target-state 명세) 아님 · 작업 메모(조사·분류는 WP) 아님.

## Batch 순서와 의존

- 이번 promote 는 **단일 blueprint-track batch**(Design → Plan → Spec)로 진행하고, 실 skill build(Implementation)는 **후속 별도 batch**다(Design non-goal). 형제 후보(blind-advisory·subagent-work-orchestration) promote 도 별도 단계.
- batch 내부 순서(의존 선언): ① promotion transition(원자적 `_incubation.md`→`_design.md` swap + E4 흡수) → ② Plan(이 문서) → ③ Spec 저작 → ④ sibling-mention sweep + glossary pending 확인 → ⑤ canonical review(Spec 도달 후 1회, relay/blind/독립감사 선행 통과 후) → ⑥ 이 blueprint-track batch 종료(commit). **retire(Design/Plan/WP 삭제)·`consultation_backlog.md` 생성·Spec `live` 승격은 이 batch 가 아니라 구현(후속 별도 batch) 이후의 *promoted-lifecycle closeout* 단계다**(Plan Header·§Batch 정의 WP retire 조건·Design·Spec §Lifecycle state 와 동일 — 이 batch 에서는 아무것도 retire 하지 않는다).
- 의존: Spec 은 Design 확정 후 · canonical 은 Spec 도달 후(Design 의 방향 결정) · sweep/glossary/원자적 swap 은 이 promotion-transition changeset(이번 changeset) 안에서 수행한다.

## Batch 정의 (단일 batch — consultation promote blueprint-track)

- **목적**: consultation candidate 를 정규 domain blueprint(Design → Plan → Spec)로 승격.
- **scope — 다루는 것**: promotion transition · Plan · Spec 저작 · sibling-mention sweep · glossary pending 확인 · canonical(Spec 후) · 이 blueprint-track batch 종료 commit. **다루지 않는 것**: 실 skill build(후속) · review skill 통합(로드맵 최후) · 형제 후보 promote · **promoted-lifecycle closeout(retire·backlog 생성·Spec `live` 승격 — 구현 후 별도 단계)** · framing input 위생(형제 후보 blind-advisory·subagent-work-orchestration 가 모두 정규화된 후 독립 안건).
- **hard boundary(불가침)**: canonical review/install 표면 비가역 변경 금지(reversibility 불변식) · 형제 후보·타 domain semantics 재서술 금지(이름-참조만) · glossary pending term 강제 finalize 금지(promotion 시점 미요구) · commit/push 는 사용자 승인 게이트.
- **validation expectation**: Design/Plan/(WP)/Spec 각 conformance checklist 통과 · promotion checklist 통과 · E4 흡수 완결(독립감사 대조) · closeout 에서 `docs-working-model-check` + `verify-ps1` green · 원자적 swap 실증(incubation 삭제 = design 작성, 같은 changeset) · sibling-mention sweep 실행 보고 · canonical dual(Spec 후) local-correctness/system-coherence.
- **review focus**: Design → Plan+WP → Spec 은 relay-A/B + blind + 독립감사(상보 3-lens, 상류 수정 시 Stage rewind) · **canonical = Spec 이 상보 3-lens(relay/blind/독립감사)로 선행 통과한 뒤 Spec 단계 1회**(Design 방향 결정) · loop-state closed 값집합 대칭 closure 추적.
- **Work Packet 필요**: 예. **목적** = round-scoped 조사(sibling-mention sweep 대상 인벤토리 · glossary pending 상태 · 원자적 swap 검증 노트 · incubation→design E4 대조). **흡수 대상** = closeout report(실행 결과) · Spec(해당 시). **retire 조건** = promoted-lifecycle closeout 시 삭제.

## Open decision 의 close 지점

- **discovery 노출(`docs/README.md` §5 · `rules/README.md`)** — 이 batch 에서는 **결정하지 않고 park 한다**(park 하기로 한 것 자체가 이 open decision 에 대한 Plan 의 처리다): 이번 changeset 은 **§5 미변경**(E1 — `_incubation` 만 있던 폴더가 이제 promoted 이나 blueprint-track 이라 implementation-authority 아님; prelive Spec 은 governance-discoverable 이나 live 아님, 그리고 그 discoverability 는 promoted artifact 존재로 이미 성립한다). **§5 domain map 에 consultation 을 등재하는 것은 이 batch 에서 하지 않는다** — 이 등재는 **별도 backlog row 로 park 하지 않는다**(그 row 는 생성 시점과 reopen 시점이 같아 중복이다). 대신 **promoted-lifecycle closeout 의 Level-1 orientation gate**(docs-working-model *Closeout — reduced two-level gate*)가 그 시점에 `docs/README.md` 를 live domain 반영으로 이미 강제하므로 그 gate 가 이 등재의 owner다.
- **게이트 cadence 세부** — 위 *review focus* 에서 확정(Design 은 "canonical=Spec 후" 방향만, 단계별 cadence 는 Plan 소유).
- **Deferred Questions → `consultation_backlog.md`** — **promoted-lifecycle closeout**(구현 후 · Design/Plan retire 시점)에서 backlog 파일을 **생성**하고(그 전까지 이 항목들은 Design §Deferred Questions 가 보유) Design §Deferred Questions 의 구현-후-defer 항목을 각각 one line + reopen/start condition 으로 흡수한다(§5 domain map 등재는 backlog row 가 아니라 위 open decision 대로 promoted-lifecycle closeout 의 Level-1 gate 소관). **ID prefix = `CONS`**(consultation domain 약어; `next ID: CONS-NN` 단조 증가). **framing input 위생(C부류)은 consultation domain 밖 독립 안건이라 backlog 대상 아님** — Design 에 명시된 대로 별도 tracking.

## Stage rewind 조건

- Plan 이 Design 의 end-state·경계·결정 위반 → stop · Design 재설계 · Plan 재시작.
- Spec 이 이 Plan 위반 → stop · Plan 재계획 · Spec 재시작.
- 구현이 Spec boundary 초과 → stop · 사용자에게 확인(scope 무단 확장 금지).
