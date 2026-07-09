# consultation Spec

> Spec 은 목표 상태 명세다 — 작성 완료 시 = 구현할 목표 상태의 청사진, closeout 후 = 구현물과 1:1 동기화된 live 명세. 담으면 안 되는 것: 회차 candidate-file 목록·실행 명령 시퀀스·staging 절차·review result·readiness 판정·시점성 작업 상태(분석·분류 → Work Packet, 실행 메커닉·기록 → operator report `log/**`). 승인 경계는 Header 에서 1회만 진술한다.

## Header

- 이 문서 = `consultation` domain 의 **target-state Spec** — operator 가 판정·승인·mutation 전에 복수 AI 의 read-only 의견을 수집·종합하는 advisory workflow 거버넌스가 정규 domain 으로서 무엇이어야 하는가의 명세. closeout 시 owner surface(skill)와 1:1 sync.
- 이 체인이 끝나면 = `consultation` domain 이 live 로 성립하고 skill 이 이 Spec 에 1:1 대조된다. skill 의 Implementation 은 promote 후 단계로 **구현됐고**(정규 skill 존재), domain 이 `live` 가 되는 것은 closeout(1:1 sync) 시점이다 — 지금은 `prelive`(구현 존재·closeout 前·implementation-authority 아님).
- 이 문서가 아닌 것 = 작동 skill 아님(Spec 은 명세, skill 이 behavior 소유) · 회차 작업 문서 아님 · review verdict·blind 산출 아님. 이 Spec 은 mutation/commit/push 승인이 아니다.

## 목표 상태

consultation 은 operator 가 판정·승인·mutation 하기 전에 하나 이상의 consultant(외부·서브 AI)에게 read-only 로 의견·반론·조사를 위임하고 그 응답을 operator synthesis 로 종합하는 advisory workflow 거버넌스다. 아래 normative 요구가 성립해야 한다:

- **read-only.** consultant 는 inspection 만 하고 mutation 하지 않는다. consultation 진행 중 mutation 또는 별도 승인이 필요해지면 그 지점에서 진행을 멈추고 operator 가 escalate 한다(escalate 의 구체 대상·흐름은 skill build 소관이다).
- **advisory only · no verdict.** consultation 산출은 advisory 이며 commit/push/release/adoption 을 승인하지 않고, review 의 verdict(`yes`/`no`/`yes with risk`)를 내지 않는다.
- **operator synthesis 필수.** consultant 응답은 그대로 source-of-truth 가 되지 않고 operator 가 우려·가설·대안·확인질문으로 종합한다. consultant output 은 truth oracle 이 아니며, 시점·절차·문면 사실은 operator 가 원문으로 재검증한다(인용이 정확해도 개념-표현이 부정확할 수 있다). synthesis 산출은 consultant 응답을 **왜곡 없이 표면화**해야 하며 이견을 합의로 paraphrase 하지 않는다(합의로 요약해 원 응답을 지우지 않는다 — 이 도메인의 anti-capture 투명성). operator 가 consultant 의 한 점을 **기각할 때는 그 기각의 근거 type**(repo invariant / 선례 / 명시규약)을 표기한다.
- **framing 축 operation 은 정확히 둘이다:**
  - **`독립 의견`(id `independent`).** pre-focus 독립 자문. 입력 = 질문 + 배경만(operator 의 stance·결론 유도 미포함), 질문은 성립·불성립 양쪽이 열린 양방향으로 구성한다. 이 양방향 구성은 consultant 가 **잔여 framing pressure 를 self-report** 하게 요청하는 것을 가능하게 하며, request 는 그 self-report 를 요청할 수 있다. 한 run 은 **one-shot terminal**(run 내부에 round 루프가 없다); operator 의 재호출은 이전 run 의 연장이 아니라 새 독립 run 이다.
  - **`재조율`(id `reconcile`).** stance-공유 적대 재조율. 입력 = operator 의 진행 중 stance 필수. **multi-round**(고정 round cap 없음; operator 가 수렴/종료를 판정하는 circuit-breaker 이며 consultant 가 스스로 종결하지 않는다). 끝에 operator 의 독립 평가를 붙이며, 상대 의견을 verbatim 으로 transport 하지 않는다.
  - 두 operation 은 packaging 축과 직교하며 어느 packaging 으로도 실린다.
- **`재조율` loop state(operator 가 붙이는 wrapper 값 — consultant 산출 필드가 아니다):** `needs_reply`(turn-terminal — operator 응답을 기다리는 라운드 경계, 루프는 계속된다) / `converged`(operator 가 advisory 로 더 다툴 점이 없다고 판단) / `human_residual`(operator 가 남은 미결을 사람 몫으로 넘김). 뒤 둘은 loop-terminal 이다. `needs_reply` 에서 멈춰 종결로 취급하지 않는다 — 1회 반론 후 complete 는 미완료다.
- **loop state 는 status vocabulary 와 별개 축이며 합치지 않는다.** status vocabulary = operator 가 advisory 산출을 분류한 라벨 `synthesized` / `needs-follow-up` / `conflicting-opinions` / `insufficient-context`(consultation 자신의 어휘로 유지; review verdict·blind concern 과 분리). `needs_reply`(loop) 와 `needs-follow-up`(status)는 철자만 비슷한 다른 축이다.
- **packaging 축:** `single-consultant` / `parallel-consultation` / `role-split-consultation` / `counterpoint`(반론 생성). `roundtable`(1차 종합 후 2차 반론)은 비용·contamination 위험이 커 후속 후보이고, `council` 은 domain 명이 아니라 pending packaging alias 다.
- **run 지속성은 purpose-bound.** multi-round `재조율` 은 세션-지속으로 도는 것이 기본이며(라운드마다 operator 가 누적 맥락을 재패키징하면 그 편향이 실리므로 지속이 그것을 제거), `독립 의견` 등 독립 검사는 fresh 로 돈다(앵커링 0). 지속성은 우열이 아니라 operation 목적에 묶인 파라미터다.
- **충돌 시 디폴트 = 재조율 루프.** consultant 응답이 서로 충돌하거나 operator 초안을 반박할 때 디폴트는 재조율 루프(재-relay·재질의)이지 fiat 종결이 아니다. 멈춤은 양쪽 AI 가 모두 답을 못 내는 크리티컬 미결일 때뿐이며 operator 가 외부 circuit-breaker 다. 수렴은 advisory 일 뿐 어떤 행동도 승인하지 않으며(수렴 ≠ commit/promote 승인), **빠른 무저항 수렴은 종결 신호가 아니라 경계 신호다.**
- **request 가 inspection scope 를 소유한다.** consultation request 의 허용 inspection scope 는 추론-only 부터 consultant 가 대상 파일을 직접 읽는 full-scope 조사까지의 스펙트럼이며, 어느 지점인지는 도구 환경이 아니라 request 가 명시로 결정한다.
- **사실-frame 제공 ≠ 결론 주입.** 대상의 계층·altitude·역할 같은 사실-frame 을 request 에 제공하는 것은 framing 오염이 아니라 판정 정확도의 결정변수다; 금지되는 것은 결론·선호의 주입이며, 이는 `독립 의견` 의 stance-미포함 원칙과 양립한다(stance 와 사실-frame 은 다르다).
- **no-file 런타임.** consultation 기능 자체는 per-run input/output 파일을 만들지 않고 conversational synthesis 로 실행된다. (pilot 측정은 gitignored runtime scaffolding 에 사는 별개 실험 영역이며 기능 파일이 아니다.)
- **advisory-항목 shape.** 각 advisory 항목은 자기 출력에 confidence 와 (근거가 된) assumption 을 함께 단다.
- **secret / redaction 최소 원칙.** 외부 상용 AI 를 consultant 로 호출할 때 민감정보가 consultant 에 전달되지 않도록 입력을 중립화하고 전송 경계를 지킨다(전역 security 규율과 interface 하며 consultation 이 넓게 소유하지 않는다). redaction 의 세부 메커니즘·전송 승인 정책은 backlog 소관이다.
- **vocabulary 분리.** consultation 은 review 의 verdict/pass/finding 어휘, blind advisory 의 concern 어휘와 섞지 않는다.

이 절 + 아래 Owner surface 지도만으로 동일 행동의 consultation 구현을 재작성할 수 있어야 한다(reconstructibility).

## Owner surface 지도

- **skill 이 consultation workflow 의 behavior 를 소유한다**: operation(`독립 의견`/`재조율`) 실행 · operator synthesis 보조 · loop state / status vocabulary 관리 · request 패키징(inspection scope·framing·packaging) · advisory-항목 shape 부착. Spec 은 이 behavior 를 명세하고 skill 과 1:1 로 대조될 뿐이며, authority 는 active surface(skill)에 있다.
- 첫 build target 은 **삭제가능 skill** 이다(reversibility 불변식 — canonical review·install 표면을 비가역적으로 변경하지 않는다).
- **rules** 는 class/invariant(read-only·advisory·no-verdict·vocab 분리)만 명명하고 behavior 를 흡수하지 않는다.

## Durable boundary

- **허용(지속)**: read-only inspection · advisory 산출 · operator synthesis · framing 2 operation · packaging modes · no-file conversational 실행.
- **금지(지속)**: verdict 발행 · commit/push/release/adoption 승인 · consultant mutation · 다른 domain 의 source-of-truth 대체 · consultation 을 review invocation/pass/coverage 에 합산 · consultation transcript 를 `log/review/**` 에 저장 · consultation 산출을 `Blocking findings` 의 source-of-truth 로 승격 · canonical reviewer 에게 consultation 결론을 신뢰하라 지시 · consultation preflight 를 canonical-only 요청에 자동 강제 삽입 · broad-bucket 확장(모든 AI 호출·general research·모든 sub-agent orchestration·모든 operator 의사결정 보조).

## Cross-domain interface

- **review** — consultation 은 review 의 **optional advisory preflight** 로만 연결된다(review 는 consultation 의 semantics 를 소유하지 않는다). operator 가 중립화한 정보를 review 소유의 preflight-input interface 형식으로 넘기며(그 형식이 바뀌면 review 정의가 우선), consultation 은 이를 참조할 뿐 내부 구조를 재서술하지 않는다. review skill 통합은 로드맵 최후 단계다.
- **subagent-work-orchestration**(아직 incubating rule candidate — 정규 owner surface 는 promote 후에야 성립하고 지금은 discovery/authority 대상이 아니다) — close-the-loop JOIN guarantee 를 status-honest name-identity 로 이름-참조만 한다(그 semantics 는 promote 후 해당 owner surface 소유; 여기서 재서술하지 않는다).
- **blind advisory**(아직 incubating domain candidate — live 레이어 아님) — 별개 레이어다. consultation 은 blind 의 산출을 입력으로 받지 않으며 두 레이어는 operator synthesis 에서만 결합한다(입력-독립). `재조율` 은 framing 을 제공하고 blind 는 framing 을 제거하므로(그 framing-제거 semantics 는 promote 후 blind 소유) 정반대 동작원리다.

## Validation expectation

- consultation skill 이 지속 검증할 것(정규 skill 구현됨 — 이 항목들이 skill 이 대조되는 기준이다): 두 operation 의 loop 동작(`독립 의견` one-shot terminal · `재조율` multi-round · operator circuit-breaker · `needs_reply` 에서 미완결 종료 금지) · read-only 경계(mutation 필요 시 escalate) · vocabulary 분리 · no-file 실행 · advisory-항목 shape · secret 중립화 경계. 구체 suite·조건은 skill 과 closeout 1:1 sync 에서 확정·검증된다.
- 검증 근거의 기록처는 closeout report / `log/evidence/**` 다.

## Review focus

- consultation 변경 시 항상 검토할 것: advisory 경계 유지(verdict/approval 오용 0) · read-only 실준수(consultant 가 mutation/verdict/gate 통과를 맡지 않음) · consultation 과 blind advisory 의 사례-수준 구분 · domain-local closure(consultation 의미가 review semantics 없이 닫힘) · scope single-home(broad-bucket 확장 압력 감시).

## Lifecycle state

- **prelive** — 이 Spec 은 promotion 후 작성됐고 closeout(1:1 sync) 전이다. governance-discoverable 이나 implementation-authority 는 아니다(E1 two-layer): 그 존재가 live behavior 의 근거로 소비되어서는 안 된다.
- lifecycle-doc 존재: `_design` / `_plan` / `_work_packet`(active lifecycle work) — closeout 시 retire/삭제.
- capability/maturity: 임시 `relay-lab` pilot 로 dogfood 성숙 후 **정규 skill 구현됨**(closeout 前이라 implementation-authority 아님 — prelive 유지). 이후 경로 = 글로벌 설치·배포 → `blind-advisory` 정규 개발과정서 실사용 검증 → 이상無 시 closeout(1:1 sync·`live`) 안건.
