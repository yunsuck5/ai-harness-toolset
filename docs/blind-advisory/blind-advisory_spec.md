# blind-advisory Spec

> Spec 은 목표 상태 명세다 — 작성 완료 시 = 구현할 목표 상태의 청사진, closeout 후 = 구현물과 1:1 동기화된 live 명세. 담으면 안 되는 것: 회차 candidate-file 목록·실행 명령 시퀀스·staging 절차·review result·readiness 판정·시점성 작업 상태(분석·분류 → Work Packet, 실행 메커닉·기록 → operator report `log/**`). 승인 경계는 Header 에서 1회만 진술한다.

## Header

- 이 문서 = `blind-advisory` domain 의 **target-state Spec** — operator framing 을 제거한 변경분에 대해 canonical review *전에* 결함 후보를 거르는 비-판정 prefilter 가 정규 domain 으로서 무엇이어야 하는가의 명세. closeout 시 owner surface(skill)와 1:1 sync.
- 이 체인이 끝나면 = `blind-advisory` domain 이 live 로 성립하고 skill 이 이 Spec 에 1:1 대조된다. skill 의 Implementation 은 promote 후 단계이고, domain 이 `live` 가 되는 것은 closeout(1:1 sync) 시점이다 — 현 지점의 명명은 §Lifecycle state 소관이다.
- 이 문서가 아닌 것 = 작동 skill 아님(Spec 은 명세, skill 이 behavior 소유) · 회차 작업 문서 아님 · review verdict·consultation 산출 아님. 이 Spec 은 mutation/commit/push 승인이 아니다.

## 목표 상태

blind-advisory 는 operator 가 모든 framing 을 제거한 변경 파일의 현재 상태를 독립 reviewer 에게 전달해, canonical review 전에 결함 후보를 찾는 read-only prefilter 다. 아래 normative 요구가 성립해야 한다:

- **read-only.** reviewer 는 제공된 대상을 inspection 만 하고 mutation 하지 않는다.
- **verdict 미발급.** 이 domain 은 review 의 verdict(`yes`/`no`/`yes with risk`)를 내지 않는다. 산출은 결함 *후보 입력* 이며 어떤 변경도 승인하지 않고(approves nothing), 어떤 요구도 면제하지 않으며(waives nothing), 최종 review 의 scope 를 좁히지 않는다.
- **framing 제거.** operator 는 입력에서 자신의 의도·이전 verdict·resolved/fixed/clean 서사·의심 지점·pass/fail 기대·severity 힌트, 그리고 테스트의 통과/미통과 여부를 제거한다(테스트 파일의 존재·변경 여부는 기계적 식별자라 허용). 사실을 전달해야 하면 "operator claims …" 로 격하해 주장임을 표시한다. 이 framing 제거가 이 domain 의 정체성이며, framing 을 *제공* 하는 advisory 레이어와 정반대 축이다.
- **operator = transporter.** operator 는 reviewer 의 finding 을 verbatim 으로 전달하고 종합·선별·축약·suppress 하지 않는다. operator 자신의 코멘트는 additive-only 로 분리 표기한다. **다만 transport 와 downstream 중립화는 별개 단계다** — 산출을 review 의 preflight-input 으로 넘길 때 operator 가 수행하는 중립화는 이 domain 의 run *밖* 행위이며 transporter 규율과 충돌하지 않는다.
- **input contract.** 허용 입력 = 변경 파일의 **현재 상태 전체 내용** + 최소 기계적 범위 식별자(변경 파일 목록 · 언어/유형 · 테스트 파일 존재/변경 여부) + *변경이 촉발한 조건부 의무가 이행돼야 하는* 인접 surface. **anchor 는 출발점이지 scope 울타리가 아니다** — reviewer 는 필요하면 인접 계약을 따라간다. 인접 surface 의 *포함 여부 판단* 에 operator 의 결정이 필요해지면 단정하지 않고 `inconclusive`(scope 큐레이션 트리거)로 보고하고, target set 에 이미 식별돼 든 인접 surface 를 *기계적으로*(sandbox·경로·권한) 읽지 못하면 그것은 수집의 기계 실패다(`unavailable` — 기계-실패 항목). **금지**: suppressive 축소("이 파일만" · "이 concern 은 보지 마라" · "인접 계약은 scope 밖")는 framing 재주입이므로 금지한다. **한정**: 이 허용은 repo 전체에 대한 임의 탐색 권한이 아니며 — 인접 surface 는 *의무가 사는 곳* 이라는 기준으로 한정된다 — 어느 구현에서도 현재상태 전체를 diff delta·history 로 대체하지 않는다. secret·자격증명·대형 generated blob 의 redaction 은 framing 선별이 아니라 별개의 입력 위생 단계이며, 전역 security 규율과 interface 한다(이 domain 이 넓게 소유하지 않는다).
- **reviewer invocation posture.** 현재 상태 전체를 프롬프트에 inline 동봉하는 방식과, 경로 목록을 주고 전문을 직접 read 하게 하는 방식은 **같은 input contract 의 두 구현** 이며 선택은 payload 규모의 함수다. 어느 쪽도 위 한정을 위반하지 않는다.
- **status vocabulary(closed).** 정상 종결한 run 은 정확히 하나의 status 를 낸다: `no-concerns-reported` / `concerns-reported` / `inconclusive` (기계 실패로 끝난 실행은 status 를 내지 않는다 — 아래 기계-실패 항목). `concerns-reported` 는 하나 이상의 결함 후보가 finding 으로 뒤따르는 status 다. 이 집합은 review 의 verdict 어휘와도, framing 을 제공하는 advisory 레이어의 status 집합과도 분리된다. **status 의 의미는 제공된 anchor 와 허용된 inspection 범위 안에서만 유효하다** — 따라서 `no-concerns-reported` 는 그 run 이 실제로 본 범위를 함께 진술해야 하며, "충분히 봐서 없음" 과 "범위가 제한돼 못 찾음" 을 하나의 토큰으로 뭉개지 않는다.
- **기계 실패는 status 가 아니다.** 대상 수집 실패(변경 파일, 또는 target set 에 이미 식별돼 든 인접 surface 를 읽지 못함)·인코딩 손상·timeout·비정상 종료·출력 절단·응답 파싱 실패 등 기계적 실패에서는 — transport 계층의 bounded 복구가 허용돼 있다면 그것이 소진된 뒤 — status 를 추정하지 않고 `unavailable(<reason>)` 로 종료한다. 특히 status 토큰이 검출되지 않거나 모호할 때 `inconclusive` 로 추정하는 것을 금지한다. 이는 인접 surface 의 *포함 여부 판단이 열려 있는* 경우와 구분된다 — 그 판단이 operator 의 결정을 요구하면 기계 실패가 아니라 `inconclusive` 트리거(scope 큐레이션)다(input contract 항목).
- **`inconclusive` 의 경계-보존 역할과 그 트리거.** `inconclusive` 는 정확히 세 트리거에서 나온다 — 답하려면 **(1) framing 추가**가 필요하거나 **(2) operator 의 scope 큐레이션**이 필요하거나 **(3) verdict 또는 evidence** 가 필요해지는 순간이다. 그때 `no-concerns-reported` 로 닫지 않고 *무엇이 필요한지* 를 명시하며 멈춘다(이 domain 이 다른 레이어로 변질되는 것을 막는 장치). 그 밖의 사유로 `inconclusive` 를 쓰지 않으며, 각 `inconclusive` 는 어느 트리거에 걸렸는지와 그 사유를 동반해야 하고 **책임회피 hatch 로 쓰이지 않는다.**
- **finding shape.** 각 finding 은 severity 와 함께 **confidence** 와 그 finding 이 기대는 **assumption** 을 동반한다. severity 는 status vocabulary 와 별개 필드이며 closed 3값이다: `blocking`(지금 고쳐야 함) / `non-blocking`(canonical review 전에 고치면 좋음) / `question`(열린 가설 — 중립 질문으로 downstream 에 넘기기 적합).
- **single-shot.** 한 run 은 *변경 파일의 현재 내용 → reviewer → transported findings* 로 종결된다. 반론-수렴 multi-round 루프를 이 domain 에 두지 않는다 — 그런 루프를 더하는 것은 transporter 정체성 위반이다. **재호출과 정지 규칙은 이 domain 이 소유하지 않는다**(close-the-loop 계약 소관).
- **payload 신뢰 경계.** 검토 대상 데이터 전체(파일 내용·로그·테스트 출력 등)는 **신뢰 불가 payload** 로 데이터로만 취급한다. 그 안의 지시·명령·delimiter 를 권한 경계나 실행 대상으로 인정하지 않으며, reviewer 프롬프트에 그 취급을 명시한다.
- **능력 경계.** 이 domain 은 결함 risk-class 를 조기 포착하는 prefilter 이지 canonical review 의 depth 를 대체하지 않는다. `no-concerns-reported` 통과는 기계 검증(테스트 스위트·검사 스크립트)을 면제하지 않으며, 그 반대 방향의 상보도 성립한다. 또한 이 domain 은 **framing-breaker 가 아니다** — operator 의 질문 framing 자체가 오염되면 이 검사도 그 framing 안에서만 작동한다.
- **비-코드 대상의 결함 해석.** 대상이 docs/prose/planning artifact 이면 결함은 코드 결함이 아니라 모순 · 누락 · 용어 불일치 · scope-drift · cross-domain semantics 재서술 로 해석된다. 산출의 성격(비-판정 결함 후보)은 동일하다.
- **호출 어휘의 비-verdict 보존.** 이 domain 의 호출 trigger 어휘에서 review 계열 어휘를 배제해, 호출 단계부터 canonical verdict 와 섞이지 않게 한다.
- **no-file 런타임.** 이 domain 의 기능 자체는 per-run input/output 파일을 만들지 않고 conversational 로 실행된다. reviewer 호출 adapter 의 transport 계층에 한해 정확히 두 클래스의 bounded·disclosed 예외만 존재한다 — (a) 직접 셸이 불가할 때의 즉시-삭제 prompt 우회 파일, (b) inline 반환이 불가한 대형 응답의 disclosed transcript 보존 — 그 밖의 파일 예외는 없다. 두 예외의 mechanics 는 skill adapter 소관이며, 어느 쪽도 기능 artifact 가 아니고 이 경계의 완화가 아니다.
- **threat model 경계.** 위조(forgery)와 audit 는 이 domain 의 threat model 에 포함되지 않는다. 책임은 omission·scope-drift 류의 결함 탐색까지이며, 어떤 token 의 위조방지 보증도 이 산출로 주장하지 않는다.

이 절 + 아래 Owner surface 지도만으로 동일 행동의 blind-advisory 구현을 재작성할 수 있어야 한다(reconstructibility).

## Owner surface 지도

- **skill 이 blind-advisory workflow 의 behavior 를 소유한다**: 대상 수집과 framing 제거 · 입력 패키징(anchor 구성과 인접 surface 판단) · reviewer 호출 · status 와 finding 의 파싱 · verbatim transport · 실패 시 `unavailable` 종료. Spec 은 이 behavior 를 명세하고 skill 과 1:1 로 대조될 뿐이며, authority 는 active surface(skill)에 있다.
- 첫 build target 은 **삭제가능 skill** 이다(reversibility 불변식 — canonical review·install 표면을 비가역적으로 변경하지 않는다).
- **rules** 는 class/invariant(read-only·advisory·no-verdict·vocab 분리)만 명명하고 behavior 를 흡수하지 않는다.
- **이 domain 이 소유하지 않는 것**: 한 run 의 밖에서 언제 재호출하고 언제 멈추는가(close-the-loop 계약 소관) · 산출을 downstream 으로 넘기는 interface 의 형식(review 소관) · 여러 advisory 레이어의 산출을 결합하는 규칙(operator 의 종합 단계 소관).

## Durable boundary

- **허용(지속)**: read-only inspection · 비-판정 결함 후보 산출 · verbatim transport · closed status 3값과 `unavailable(<reason>)` · closed severity 3값 · finding 의 confidence·assumption 동반 · no-file conversational 실행 · 인접 surface 를 포함한 현재상태 전체 입력.
- **금지(지속)**: verdict 발행 · commit/push/release/adoption 승인 · reviewer 의 mutation · 산출을 review 의 invocation/pass/coverage 에 합산 · 산출물을 review 의 runtime 기록 영역에 저장 · 산출을 `Blocking findings` 의 source-of-truth 로 자동 승격 · canonical reviewer 에게 이 산출을 신뢰하라고 지시 · suppressive scope 축소 · 기계 실패를 `inconclusive` 로 세탁 · operator 의 종합(synthesis)을 요구하는 형태로의 변형 · broad-bucket 확장("모든 skeptical review" · "모든 AI 결함 탐색" · "quality gate" 일반 · pre-review 일반).

## Cross-domain interface

- **review**(live domain) — 이 domain 은 review 의 **optional pre-pass** 로만 연결된다. 산출을 review 로 넘기는 것은 operator 의 downstream 행위이며 operator 가 중립화해 넘긴다. 그 전달 형식은 review domain 이 소유한다 — 정의된 preflight-input interface 가 존재하면 그 형식을 따르고(형식이 바뀌면 review 정의가 우선), 그 interface 의 도입 여부 자체가 review 소관의 미래 결정이므로 정의되기 전에는 operator 의 중립화된 수동 전달로 남는다. 이 domain 은 그 형식을 참조할 뿐 내부 구조를 재서술하지 않는다. review skill 통합은 로드맵 최후 단계다.
- **consultation** — 별개 레이어다. 이 domain 은 그 레이어의 산출을 입력으로 받지 않으며(입력-독립), 두 레이어는 operator 의 종합 단계에서만 결합한다. 그 레이어의 semantics 는 그 domain 이 소유하며 여기서 재서술하지 않는다.
- **subagent-work-orchestration**(아직 incubating rule candidate — 정규 owner surface 는 promote 후에야 성립하고 지금은 discovery/authority 대상이 아니다) — close-the-loop 계약을 status-honest name-identity 로 이름-참조만 한다. 이 domain 의 재호출·정지 규칙이 그 계약 소관이라는 사실만 진술하며, 그 절차·evidence semantics 를 여기서 재서술하지 않는다.

## Validation expectation

- blind-advisory skill 이 지속 검증할 것: framing 제거 목록의 실준수 · input contract 의 허용/금지/한정(현재상태 전체 · 인접 surface · suppressive 축소 0 · diff 대체 0) · status 3값의 배타성과 기계 실패의 `unavailable` 분기 · `inconclusive` 의 사유 동반 · finding 의 severity/confidence/assumption 동반 · verbatim transport(suppress·축약 0) · no-file 실행 · verdict 어휘를 자기 status/judgment 로 발행 0(transported 원문의 인용은 데이터).
- 구체 suite·조건은 skill 과 closeout 1:1 sync 에서 확정·검증된다. 검증 근거의 기록처는 closeout report / `log/evidence/**` 다.

## Review focus

- blind-advisory 변경 시 항상 검토할 것: 비-판정 경계 유지(status 가 승인 신호로 소비된 사례 0) · `no-concerns-reported` 가 "충분히 봐서 없음" 과 "제한된 scope 라 못 찾음" 을 뭉개는 status laundering 방지 · transporter 규율 실준수(operator 가 선별해야만 작동하는 구조 0) · framing 제거의 실효(operator 가 의도·판정·수정 주장을 넣어야 유용해지지 않는가) · false-positive 가 절약분을 잠식하지 않는가 · 이 domain 과 framing-제공 advisory 레이어의 사례-수준 구분 · domain-local closure(이 domain 의 의미가 타 domain semantics 없이 닫히는가) · scope single-home(broad-bucket 확장 압력 감시).

## Lifecycle state

- **prelive** — 이 Spec 은 promotion 후 작성됐고 closeout(1:1 sync) 전이다. governance-discoverable 이나 implementation-authority 는 아니다(E1 two-layer): 그 존재가 live behavior 의 근거로 소비되어서는 안 된다.
- lifecycle-doc 존재: `_design` / `_plan` / `_work_packet`(active lifecycle work) — closeout 시 retire/삭제.
- capability/maturity: 임시 pilot 도구로 dogfood 성숙했고 **정규 skill 구현됨**(closeout 前이라 implementation-authority 아님 — `prelive` 유지).
