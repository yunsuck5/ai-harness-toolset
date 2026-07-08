# consultation Design

> Design 은 변경의 방향성 문서다 — 영구 live 아님: closeout 시 current-bearing 내용이 Spec(또는 올바른 owner surface)으로 흡수된 뒤 retire(삭제). 이 Design 은 mutation/commit/push 승인이 아니다.

## Header

- 이 문서 = `consultation` candidate 의 **promote Design**(entry promoted artifact) — incubation 에서 정규 domain 으로 승격하는 Design → Plan → Spec lifecycle 의 첫 산출. promotion transition 의 원자적 `_incubation.md` → `_design.md` swap 으로 landing 하고, **promoted-lifecycle closeout 시 retire**.
- 이 체인이 끝나면 = `docs/consultation/` 가 domain home 으로 성립하고 `consultation_spec.md` 가 target-state blueprint 가 된다. **live domain authority 는 이 promote 가 아니라 implementation closeout 시 성립**(blueprint track 진입 ≠ live authority).
- 이 문서가 아닌 것 = Spec 아님 · 작동 skill 아님(skill build 은 final Spec 의 Implementation, 후속) · operating model 최종 규범 명세 아님(loop 제어 MUST·필드 정의는 Spec).

## 왜 바꾸는가 / 무엇을 바꾸는가

- **문제(신규 domain — 기존 live Spec 없음).** consultation 은 임시 실험 도구로 pilot 돼 왔고, incubation Admission 이 명시한 gap — "operator 가 판정·승인·변경 *전에* 복수 AI 의 read-only 관점·반론·조사를 수집하고 이를 비권위 advisory 입력으로 다루는 단일 규칙 home 이 없다" — 은 review(verdict gate)·blind advisory(결함 prefilter)·brief·install-update·docs-working-model 어디에도 흡수되지 않는다. 방치되면 그 활동이 review 로 오인돼 승인 효과를 갖거나 임의 sub-agent 관행으로 흩어져 권한 경계가 불명확해진다.
- **판단을 바꾼 evidence(유형).** ① canonical gate 가 통과시킨 대상에서 독립 advisory 층이 결함성 지적을 내는 관측(판정 *전* 비권위 계층이 기존 review gate 로 환원되지 않음). ② pre-focus 독립 호출(`독립 의견`)과 stance-공유 반론 호출(`재조율`)이 각각 다른 종류 기여(질문 밖 새 축 발굴 vs 입장의 실질 반박·정밀화)를 내는 반복 관측. (결과 기록은 runtime 소관 — 여기서는 승격을 정당화한 *증거 유형*.)
- **무엇을(큰 그림).** 이 advisory workflow 거버넌스를 정규 domain 으로 승격한다: read-only 자문 수집 → operator synthesis 종합, verdict 없음, framing 축 2 operation(`독립 의견`/`재조율`)과 packaging 축의 직교 구조. **정밀 boundary·invariant·operating model 최종 명세는 Spec 이 소유.**
- **단일 닻(scope guard).** "AI 에게 묻는 모든 것"·"모든 sub-agent orchestration"·"general research" 로 확장하지 않고 **판정 없는 read-only 자문 호출의 거버넌스** 하나에만 닻을 박는다(broad-bucket 확장 = discard 기준).
- **정체성(domain vs rule 재확인).** consultation 은 **domain** 이다(owner surface = skill, home = `docs/consultation/`). 내용 일부가 운영 규율에 가깝다는 관점이 있으나, 자연어 UX·advisory workflow 를 소유하는 skill-first surface 와 domain-local closure 로 domain 선택이 정합적이다(규칙 *End-state placement* 의 domain 계열).

## Owner surface model

- **owner surface = skill(정규).** 자연어 UX + read-only advisory workflow 가 핵심이라 script-heavy 로 시작하지 않는다; invocation adapter 안정화 후 script/config 로 낮출 수 있다.
- **rules 는 behavior 를 흡수하지 않는다** — class/invariant/approval boundary(read-only·advisory·no-verdict·vocab 분리)만 명명하고 실제 동작은 skill surface 가 소유(root *Final hard rule*).
- **JOIN/책임선(이름-참조만).** review(live domain)의 preflight-input interface 와 subagent-work-orchestration(아직 incubating rule candidate — 정규 owner surface 는 promote 후에야 성립하며 지금은 discovery/authority 대상이 아니다)의 close-the-loop JOIN guarantee 는 각자 owner surface 가 소유하고, consultation 은 이를 status-honest name-identity 로 **이름-참조**만 한다(그 semantics 를 여기서 재서술하지 않는다 — 계약 내용은 각 owner surface 소유; 형제 candidate 참조는 authority/discovery 함의 없음). consultation 은 자기 산출(advisory 의견·operator synthesis)만 소유.
- **reversibility 불변식.** 첫 build target 은 *삭제가능 skill* 이며 canonical review/install 표면을 비가역 변경하지 않는다(review 통합은 로드맵 최후·실험 namespace 유지).

## 수정 대상

- **생성**: `docs/consultation/` 정규 domain(Design → Plan → Spec lifecycle 진입). 신규 domain 이라 수정할 기존 live Spec 이 없다.
- **삭제(promotion transition, 같은 changeset)**: `consultation_incubation.md` — E4 흡수(아래)를 전제조건으로 제거. *삭제(파일 전환)* 와 *흡수(내용 이전)* 는 별개 축.
- **이름-참조(수정 아님)**: subagent-work-orchestration(아직 incubating rule candidate) close-the-loop JOIN guarantee · review(live domain) preflight-input interface(review 표면은 로드맵 최후라 불변경). 형제 candidate 는 status-honest name-identity 참조로만(authority/discovery 함의 없음).
- **discovery(`docs/README.md` §5·`rules/README.md`)**: blueprint 단계 노출 여부·표기는 **이 batch 에서 결정/등재하지 않는 open decision**(promotion 후 governance-discoverable 이나 implementation-authority 아님 — E1 two-layer; governance-discoverability 는 promoted artifact 존재로 이미 성립하고, §5 map 등재는 promoted-lifecycle closeout 의 Level-1 orientation gate 소관이지 별도 backlog row 가 아니다).
- **sibling-mention sweep(같은 changeset)**: canonical 표면의 consultation 이름-참조 상태문구 갱신(candidate→promoted 전환) + 형제 후보(blind-advisory·subagent-work-orchestration)의 consultation 이름-참조 전수 확인.
- **glossary**: consultation 소유 pending term(`consultation`·`operator synthesis`·`consultation status vocabulary`·`독립 의견`·`재조율`)은 domain 의 finalization-owner close(Spec/implementation closeout)에서 finalize; promotion 시점엔 **final terminology 미요구**(pending 유지 정당) — sweep 과 별개의 per-term 결정.

## 하지 않을 것 (non-goals)

- canonical review(verdict gate) · blind advisory(framing 제거·별개 레이어) · implementation delegation · 모든 sub-agent orchestration 전반 · 모든 외부 AI 호출 전반 · general research/debate · 모든 operator 의사결정 보조 · evidence/validation/approval 대체 — 전부 아니다.
- **rejected coinage do-not-revive(E4 ②에서 승계)**: `consultation verdict`·`consultation pass`·`multi-reviewer consensus`·`consensus gate`·`AI review council`·`AI approval`·`soft review`·`review-lite`·`pre-review approval`·`recommendation gate`·`council/panel decision` 류(verdict/approval 함의를 advisory 에 이식). glossary 미등재·domain-local 소유.
- 이번 promote scope 밖(연기): 실 skill build(Implementation 후속) · review skill 통합(로드맵 최후) · blind-advisory·subagent-work-orchestration promote(별도 단계).
- broad cleanup · scope creep 금지.

## E4 absorption (promote — "왜 살아남았나" raw-link 없이 재검토 가능)

- **① adopted conclusion**: 위 §왜 바꾸는가·§Owner surface model + operation 2축(framing `독립 의견`/`재조율` · packaging `single-consultant`/`parallel-consultation`/`role-split-consultation`/`counterpoint`) · status vocabulary(`synthesized`/`needs-follow-up`/`conflicting-opinions`/`insufficient-context`) · loop state(`재조율` 소유: `needs_reply`/`converged`/`human_residual`; `독립 의견`=one-shot terminal — closed 값집합·정체성은 Design, 어느 조건→어느 상태 전이 MUST 는 Spec) · no-file 런타임 · 7 정체 불변식(read-only 기본[mutation/승인 필요가 드러나면 그 지점에서 멈추고 operator escalate — read-only 경계의 절차 결정; 구체 escalation 절차는 Spec]·advisory only·operator synthesis 필수·consultant≠truth oracle·secret 경계·vocab 분리·타domain interface만) · **consultation↔blind 입력-독립**(consultation 은 blind 산출을 입력으로 받지 않고 두 레이어는 operator synthesis 에서만 결합) · advisory-항목 shape(confidence+assumption). **최종 규범 명세·필드 정의·loop 제어 MUST 는 Spec 소유**(여기선 존재·구별·closed 값집합 결정까지). 정밀 구분 보존: loop state ≠ status vocabulary(별 필드) · `needs_reply`(loop) ≠ `needs-follow-up`(status) · `counterpoint`(packaging) ≠ review `Counter-argument` 절 · `재조율`(framing 제공) ↔ blind(framing 제거) 정반대 동작원리.
- **② rejected alternatives**: `not-run` 상태 기각 · per-run runtime 저장 기각 · review-흡수/consultation-흡수 기각 · 위 rejected coinage do-not-revive.
- **③ 판단을 바꾼 evidence type**: 위 §왜의 유형 ①② + [실측 검증] decision-grade 판단(빠른 무저항 수렴=경계신호 · 사실-frame 제공≠결론 주입 · request 가 inspection scope 소유 · run 지속성 purpose-bound · consultant≠truth oracle · 양방향 질문 구성). raw 결과는 log 소관.
- **④ scope**: 좁은 single-home(판정 없는 read-only 자문 거버넌스) + broad-bucket 명시 제외.
- **⑤ failure(discard) criteria**: 독립가치 미입증 · advisory 경계 붕괴 · scope broad 확장 · cross-cutting 흩어짐 · consultation↔blind 구분 불명 · domain-local closure 실패 · read-only 주장뿐.
- **⑥ negative evidence**: 현재 치명적 negative evidence 없음 — 단 잔여 한계 동반(tooling-only pilot 수준 · 측정이 gitignored runtime 이라 durable 재검토 제한). 임시스킬 운용·프로젝트 메모리 노하우·6경로 회고(non-durable 원천 — 결론만 흡수, raw 는 log/git-history 소관)의 outcome(mode A/B 독립가치·canonical 비용 절감·경계 견고성)이 위 evidence type 을 뒷받침하고, read-only 준수·경계 견고성(위반 시 즉각 교정)은 ⑤ discard criteria 의 반증으로 관측됐다.

## Plan readiness / open risks

- **Plan 진행 가능**: 방향(read-only advisory 거버넌스를 별도 domain 으로)은 incubation dogfood + promote-readiness 검증(6경로) + operator promote 판정으로 정합. **operator promote 판정 기록**: incubation lifecycle-state 의 `continue`/review-date 2026-08-01 은 이 세션의 operator promote 결정(6경로 evidence 종합 근거)으로 supersede 되며, 이 Design landing 이 그 판정의 실행이다.
- **Design 확정 / Spec 위임 경계**: operation 2축·loop state·status vocabulary·packaging 의 *존재·구별·closed 값집합* 은 Design 결정(taxonomy 자체가 결정). 그 *운용 MUST·필드 위치/이름·round-by-round loop 제어 명세* 는 Spec 소유.
- **지금 resolve(Design 확정)**:
  - domain vs rule 정체성 → domain 확정(위 §왜).
  - secret/redaction **최소 원칙** → 외부 상용 AI 호출 시 "무엇을 consultant 에 보내면 안 되나(민감정보)·중립화·전송 경계"의 최소 원칙은 전역 security 규율과 interface 하며 consultation 이 넓게 소유하지 않는다; 최소 경계는 Spec 이 명세, 세부 구현은 Deferred.
  - consultation **종료 조건의 존재(정체성)** → advisory 는 미결 권고로 상주하지 않는다: `재조율` 은 종료 상태(operator=circuit-breaker)를 가지고 `독립 의견` 은 one-shot terminal 이라는 *정체성 결정*까지가 Design 소관이며, 그 loop 제어 MUST(어느 조건에서 어느 상태로 전이하는지)는 Spec 소관.
- **canonical 당김 금지(방향 결정)**: 이번 promote lifecycle 에서 canonical review 는 Design 단계로 당기지 않고 **Spec 도달 후** 배치한다(이 transition 의 hard boundary). 단계별 검토 cadence·게이트 배치의 실행 세부는 Plan 이 소유한다(validation expectation/review focus). 상류 문서 수정 필요 시 Stage rewind.

## Deferred Questions (backlog 부재 → 여기 fallback; Plan 이 `consultation_backlog.md` 로 흡수)

각 항목 = 열린 질문 + 처리 시점 사유(blocker 아님 = 지금 안 닫아도 live 차단 아님). (판단 근거가 된 조사 결론은 아래 각 항목·§E4 에 자기완결로 흡수됐고, raw 조사자료는 non-durable[대화·gitignored log·git history]이라 durable pointer 를 두지 않는다.)

- **구현(Spec/skill) 후 defer**:
  - operator synthesis 최소 산출 형태(concern/question/assumption 재분류 수준) — skill surface 구현 시.
  - approval 오용 방지 표면(상태명/출력 라벨이 approval 냄새 회피) — skill surface 구현 시.
  - secret/redaction 세부 구현(전송 승인 필요 여부·full paste vs 경로+발췌 기본값) — A 의 최소 원칙 위에 Spec/구현.
  - 독립 의견 request 의 framing self-report 기본 포함 여부 — request template 설계 시.
  - close-the-loop/subagent-work-orchestration 계약 경계 안정화 — **O(subagent-work-orchestration) promote 와 맞물림 → O promote 후**.
  - no-file 런타임의 조직 학습(익명화 실패유형 수집) 여부 — 운영 데이터 축적 후.
  - 기존 open questions: sub-agent only vs 외부 CLI/API adapter · output vocabulary 세부 naming · review skill 자동 preflight 호출 조건(로드맵 최후).
  - 미흡수 원료(name-level 8건 — 각각 열린 결정이며 blocker 아님): presentation 형식 · ownership map/seam · 자연어 UX · full preflight pipeline 순서 · advisory preflight chain-owner 문장 · operator synthesis 별칭 · synergy 측정 어휘 · 초기 packaging 지원 범위. **처리 시점** = 각 항목이 걸리는 하류 단계(skill surface 설계 → skill · operating-model 명세 → Spec · 그 외 → `consultation_backlog.md`)에서 착수 시 결정(현 단계 미결정).
- **완전 독립 안건(consultation 과 형제 후보 blind-advisory·subagent-work-orchestration 가 모두 정규화된 후 — consultation domain 밖)**:
  - **framing input 위생 문제**: operator framing 이 검토 input 을 오염시켜 relay·blind·**canonical review 모두**가 그 framing 안에서만 검증하는 한계(6경로 조사에서 caller-frame 을 어느 lens 도 단독으로 못 깬 반복 관측). 세 도구 공통 문제라 별도 독립 안건으로 처리 예정 — 이번 promote/구현 대상 아님.
