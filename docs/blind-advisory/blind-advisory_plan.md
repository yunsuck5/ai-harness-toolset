# blind-advisory Plan

> Plan 은 승인 대상인 의사결정만 담는다 — 작업 메모가 아니다(조사·분류·구현 노트는 Work Packet, 실행 순서·기록은 operator report `log/**`). Plan 이 Design 을 위반하면 stop → Design 재설계 후 재시작. closeout 시 흡수 후 retire(삭제). 이 Plan 은 mutation/commit/push 승인이 아니다.

## Header

- 이 문서 = `blind-advisory` candidate promote 의 **Plan** — Design(방향)을 승인-대상 결정(batch 순서·scope·boundary·validation·review focus·Work Packet 선언·open decision close)으로 구체화한다.
- 이 체인이 끝나면 = `blind-advisory_spec.md` 저작으로 내려가고 이번 promote changeset 의 실행 경계가 확정된다. promoted-lifecycle closeout 시 retire.
- 이 문서가 아닌 것 = Design(방향) 아님 · Spec(target-state 명세) 아님 · 작업 메모(조사·분류는 WP) 아님.

## Batch 순서와 의존

- 이번 promote 는 **단일 blueprint-track batch**(Design → Plan → Spec)로 진행하고, 실 skill build(Implementation)와 배포 배선은 **후속 별도 batch** 다(Design non-goal). 형제 후보 `subagent-work-orchestration` 의 promote 도 별도 단계.
- batch 내부 순서(의존 선언): ① promotion transition(원자적 `_incubation.md`→`_design.md` swap + E4 흡수) → ② Plan(이 문서) → ③ Spec 저작 → ④ candidate-status 문구 갱신 + glossary pending 확인 → ⑤ canonical review(Spec 도달 후 1회, 상보 lens 선행 통과 후) → ⑥ 이 blueprint-track batch 종료(commit).
- **retire 의 두 층을 구분한다.** **promoted-lifecycle artifact 의 retire**(Design/Plan/WP 삭제)·`blind-advisory_backlog.md` 생성·Spec `live` 승격은 이 batch 가 아니라 구현(후속 별도 batch) 이후의 *promoted-lifecycle closeout* 단계다. 반면 candidate 의 `_incubation.md` 삭제는 **이 changeset 안의 candidate-lifecycle closeout**(promotion)이며 E4 흡수를 전제조건으로 수행된다. 즉 이 batch 는 promoted-lifecycle artifact 를 하나도 retire 하지 않되, candidate 문서는 dispose 한다.
- 의존: Spec 은 Design 확정 후 · canonical 은 Spec 도달 후(Design 의 방향 결정) · sweep/glossary/원자적 swap 은 이 promotion-transition changeset(이번 changeset) 안에서 수행한다.

## Batch 정의 (단일 batch — blind-advisory promote blueprint-track)

- **목적**: blind-advisory candidate 를 정규 domain blueprint(Design → Plan → Spec)로 승격.
- **scope — 다루는 것**: promotion transition · Plan · Spec 저작 · sibling-mention sweep(실행) · glossary pending 확인 · canonical(Spec 후) · 이 blueprint-track batch 종료 commit. **다루지 않는 것**: 실 skill build 와 activation 배선(후속) · review skill 통합(로드맵 최후) · 형제 후보 promote · **promoted-lifecycle closeout(retire·backlog 생성·Spec `live` 승격 — 구현 후 별도 단계)** · blind-at-close scope 확장(Design §Deferred Questions) · framing input 위생(형제 후보가 모두 정규화된 후 독립 안건).
- **hard boundary(불가침)**: canonical review/install 표면 비가역 변경 금지(reversibility 불변식) · 형제 후보·타 domain semantics 재서술 금지(이름-참조만) · glossary pending term 강제 finalize 금지(promotion 시점 미요구) · **건드리는 표면은 blind-advisory 의 candidate-status 진술에 한정**하며 타 domain 의 normative 내용·lifecycle-state·owner surface 정의를 바꾸지 않는다 · **배포된 skill 의 문구 수정은 sibling-mention sweep 의무가 아니라 active surface 의 stale status 정정으로 수행**하며 그 domain 의 behavior 를 바꾸지 않는다(의미 보존) · commit/push 는 사용자 승인 게이트 · **배포된 skill 파일의 수정이 이 changeset 에 포함되더라도 설치본 재배포(activation apply)는 이 batch 밖의 별도 사용자 승인**이다.
- **validation expectation**: Design/Plan/(WP)/Spec 각 conformance checklist 통과 · promotion checklist 통과 · E4 흡수 완결(독립 lens 대조) · closeout 에서 `docs-working-model-check` + `verify-ps1` green · full Pester green · 원자적 swap 실증(incubation 삭제 = design 작성, 같은 changeset) · **sibling-mention sweep 의 실행 보고**(각 대상마다 `updated` 또는 `checked — no change required`, 조용한 생략 0) · 갱신된 표면이 status-honest 인지 재확인 · canonical dual(Spec 후) local-correctness/system-coherence.
- **review focus**: Design → Plan+WP → Spec 은 재조율 + blind + 독립감사(상보 3-lens, 상류 수정 시 Stage rewind) · **canonical = Spec 이 상보 3-lens 로 선행 통과한 뒤 Spec 단계 1회** · canonical 과 **독립 blind 리뷰어를 상호 blind 로 병렬** 배치(오탐 격리·외부감사) · status/severity closed 값집합의 대칭 closure 추적 · sweep 대상의 batch-시점 서술 vs 현재-상태 주장 판별.
- **Work Packet 필요**: 예. **목적** = round-scoped 조사(sibling-mention sweep 대상 인벤토리와 그 판별축 · glossary pending 상태 · 원자적 swap 검증 노트 · incubation→design E4 대조 대상 · Implementation batch 가 소비할 배선 표면 인벤토리). **흡수 대상** = closeout report(실행 결과) · Spec(해당 시) · Implementation batch(배선 인벤토리). **retire 조건** = promoted-lifecycle closeout 시 삭제.

## Open decision 의 close 지점

- **discovery 노출(`docs/README.md` · `rules/README.md`)** — 이 batch 에서는 **결정하지 않고 park 한다**(park 하기로 한 것 자체가 이 open decision 에 대한 Plan 의 처리다): 이번 changeset 은 **domain map 미변경**(E1 — promoted 이나 blueprint-track 이라 implementation-authority 아님; prelive Spec 은 governance-discoverable 이나 live 아니고, 그 discoverability 는 promoted artifact 존재로 이미 성립한다). **domain map 등재는 이 batch 에서 하지 않으며 별도 backlog row 로도 park 하지 않는다**(그 row 는 생성 시점과 reopen 시점이 같아 중복이다). 대신 **promoted-lifecycle closeout 의 Level-1 orientation gate** 가 그 시점에 `docs/README.md` 를 live domain 반영으로 이미 강제하므로 그 gate 가 이 등재의 owner 다.
- **promoted-but-not-live 형제 artifact 의 수정 허용 범위 — 두 근거로 분리해 승인한다.** 이번 changeset 은 promoted domain `consultation` 의 Spec(상태 `prelive`)과 그 배포 skill 을 건드린다.
  - **(a) `consultation` 의 promoted artifact 갱신** = 규칙이 promotion 에 부과하는 **sibling-mention sweep 의무**의 이행.
  - **(b) 배포된 skill 의 같은 문구 갱신** = 그 sweep 의무가 아니라 **active surface 의 stale status 정정**이다(의미 보존·behavior 무변경). skill 은 active implementation surface 이며 canonical sweep 집합의 일원이 아니므로, (a) 의 근거로 (b) 를 정당화하지 않는다.
  - 두 경우 모두 `consultation` 의 normative 내용·lifecycle-state·owner surface 정의를 바꾸지 않으므로 그 domain 의 lifecycle 을 진행시키지 않는다(그 Spec 은 `prelive` 로 유지). **승인 대상 결정**: 이 범위를 넘는 어떤 `consultation` 내용 변경도 이 batch 에 포함하지 않는다.
- **게이트 cadence 세부** — 위 *review focus* 에서 확정(Design 은 "canonical=Spec 후" 방향만, 단계별 cadence 는 Plan 소유).
- **Deferred Questions → `blind-advisory_backlog.md`** — **promoted-lifecycle closeout**(구현 후 · Design/Plan retire 시점)에서 backlog 파일을 **생성**하고(그 전까지 이 항목들은 Design §Deferred Questions 가 보유) Design §Deferred Questions 의 구현-후-defer 항목을 각각 one line + reopen/start condition 으로 흡수한다. **ID prefix = `BA`**(blind-advisory domain 약어; `next ID: BA-NN` 단조 증가). **blind-at-close scope 확장**은 Design 이 reopen 조건과 함께 명시 deferral 했으므로 그 조건이 충족되는 시점에 backlog row 또는 별도 scoped Design 으로 재개한다. **framing input 위생은 이 domain 밖 독립 안건이라 backlog 대상 아님.**

## Stage rewind 조건

- Plan 이 Design 의 end-state·경계·결정 위반 → stop · Design 재설계 · Plan 재시작.
- Spec 이 이 Plan 위반 → stop · Plan 재계획 · Spec 재시작.
- 구현이 Spec boundary 초과 → stop · 사용자에게 확인(scope 무단 확장 금지).
