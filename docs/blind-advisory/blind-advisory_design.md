# blind-advisory Design

> Design 은 변경의 방향성 문서다 — 영구 live 아님: closeout 시 current-bearing 내용이 Spec(또는 올바른 owner surface)으로 흡수된 뒤 retire(삭제). 이 Design 은 mutation/commit/push 승인이 아니다.

## Header

- 이 문서 = `blind-advisory` candidate 의 **promote Design**(entry promoted artifact) — incubation 에서 정규 domain 으로 승격하는 Design → Plan → Spec lifecycle 의 첫 산출. promotion transition 의 원자적 `_incubation.md` → `_design.md` swap 으로 landing 하고, **promoted-lifecycle closeout 시 retire**.
- 이 체인이 끝나면 = `docs/blind-advisory/` 가 domain home 으로 성립하고 `blind-advisory_spec.md` 가 target-state blueprint 가 된다. **live domain authority 는 이 promote 가 아니라 implementation closeout 시 성립**(blueprint track 진입 ≠ live authority).
- 이 문서가 아닌 것 = Spec 아님 · 작동 skill 아님(skill build 은 final Spec 의 Implementation, 후속) · input contract 필드와 status 전이의 최종 규범 명세 아님(그것은 Spec).

## 왜 바꾸는가 / 무엇을 바꾸는가

- **문제(신규 domain — 기존 live Spec 없음).** canonical review 는 최종 verdict gate 라 승인성 판단과 결합돼 있고 비용이 크며, operator 가 작성한 review input 이라는 강한 boundary anchor 에 의존한다 — 이 anchor 가 **framing 오염의 단일 고위험점**이다(operator 의 완료·해결·검증통과 서술이 reviewer 를 승인 쪽으로 기울인다). 한편 consultation 은 *의도적으로 framing 을 제공*하는 레이어다. 따라서 **operator framing 을 제거한 변경 파일의 현재 상태 기반 비-판정 결함 prefilter** 의 단일 home 이 어디에도 없다 — review 가 흡수하면 scope/anchor 모델이 넓어지고, consultation 은 framing 축이 정반대라 담을 수 없다. 방치되면 이 활동이 review 로 오인돼 승인 효과를 갖거나 임의 관행으로 흩어져 권한 경계가 불명확해진다.
- **판단을 바꾼 evidence(유형).** ① canonical gate 가 통과시킨 대상에서 독립 blind 검토가 blocking 성 결함을 잡은 반복 관측(판정 *전* 비권위 계층이 기존 review gate 로 환원되지 않음). ② 라운드당 전량 나열이 canonical 의 패스당-최중대-1건 모델이 구조적으로 하지 못하는 shallow-class 일괄 걷기를 수행. ③ 상보성이 **양방향**임 — blind 통과가 기계 검증(테스트 스위트)을 면제하지 않는 역방향 관측. ④ **입력 계약이 산출을 지배** — 검토 대상을 한 파일로 suppressive 하게 좁히면 경계 사이에 사는 미이행-의무를 구조적으로 못 본다. (결과 기록은 runtime 소관 — 여기서는 승격을 정당화한 *증거 유형*.)
- **무엇을(큰 그림).** 이 결함 prefilter 를 정규 domain 으로 승격한다: framing 을 제거한 변경 파일 현재상태(+ 의무가 사는 인접 surface) → 독립 reviewer → 결함 후보의 verbatim transport. verdict 없음, 비-판정 status 3값, operator 는 transporter. **정밀 boundary·input contract 필드·status 전이 명세는 Spec 이 소유.**
- **단일 닻(scope guard).** "모든 skeptical review"·"모든 AI 결함 탐색"·"quality gate 일반" 으로 확장하지 않고 **framing 을 제거한 변경분 결함 prefilter** 하나에만 닻을 박는다(broad-bucket 확장 = discard 기준).
- **정체성(domain vs rule).** blind-advisory 는 **domain** 이다(owner surface = skill, home = `docs/blind-advisory/`). 자연어 UX 와 read-only advisory workflow 를 소유하는 skill-first surface 및 domain-local closure 로 domain 선택이 정합적이다.

## Owner surface model

- **owner surface = skill(정규).** 자연어 UX + 짧은 read-only advisory workflow 가 핵심이라 script-heavy 로 시작하지 않는다; invocation adapter 안정화 후 script/config 로 낮출 수 있다.
- **rules 는 behavior 를 흡수하지 않는다** — class/invariant/approval boundary(read-only·advisory·no-verdict·vocab 분리)만 명명하고 실제 동작은 skill surface 가 소유(root *Final hard rule*).
- **blind 는 자기 산출만 소유한다.** 한 blind run = 변경 파일 현재내용 → reviewer → transported findings. 그 run 의 비-verdict 성·transporter 규율·status 의미는 blind 소유이나, **재호출·정지 규칙(reloop / stop-signal)은 blind 소유가 아니다** — 그것은 close-the-loop 계약의 loop 운영 층이다.
- **transport 와 downstream 중립화는 별개 단계다.** blind run 의 산출은 verbatim 으로 전달된다. 그 산출을 review 의 preflight-input 으로 넘길 때 operator 가 수행하는 중립화는 blind run *밖* 의 downstream 행위이며(그 interface 형식은 review 소유), transporter 규율과 충돌하지 않는다.
- **JOIN/책임선(이름-참조만).** review(live domain)의 preflight-input interface 와 `subagent-work-orchestration`(아직 incubating rule candidate — 정규 owner surface 는 promote 후에야 성립하며 지금은 discovery/authority 대상이 아니다)의 close-the-loop 계약은 각자 owner surface 가 소유하고, blind 는 이를 status-honest name-identity 로 **이름-참조**만 한다(그 semantics 를 여기서 재서술하지 않는다). `consultation`(promoted domain — Spec 은 `prelive` 라 implementation-authority 아님)은 framing 축이 정반대인 **별개 레이어**이며, 두 레이어는 입력을 공유하지 않고 operator 의 종합 단계에서만 결합한다.
- **reversibility 불변식.** 첫 build target 은 *삭제가능 skill* 이며 canonical review/install 표면을 비가역 변경하지 않는다(review 통합은 로드맵 최후·실험 namespace 유지).

## 수정 대상

- **생성**: `docs/blind-advisory/` 정규 domain(Design → Plan → Spec lifecycle 진입). 신규 domain 이라 수정할 기존 live Spec 이 없다.
- **삭제(promotion transition, 같은 changeset)**: `blind-advisory_incubation.md` — E4 흡수(아래)를 전제조건으로 제거. *삭제(파일 전환)* 와 *흡수(내용 이전)* 는 별개 축.
- **candidate-status 문구 갱신(같은 changeset) — 두 근거를 분리한다.** **이 축은 consultation promote 때와 방향이 반대다**: 그때는 consultation 을 참조하는 promoted 표면이 없어 전부 checked—no-change 였으나, 지금은 promoted domain `consultation` 의 artifact 와 그 배포 skill 이 blind-advisory 를 "아직 incubating candidate" 로 진술하고, 그 진술은 이 promote 로 사실이 아니게 된다. **(a) promoted artifact(그 domain 의 Spec)의 갱신은 규칙이 promotion 에 부과하는 sibling-mention sweep 의무다. (b) 배포된 skill 의 같은 문구 갱신은 그 sweep 의무가 아니라 *active surface 의 stale status 정정*(의미 보존, behavior 무변경)이다** — skill 은 active implementation surface 이지 canonical sweep 집합의 일원이 아니다. 두 근거를 뭉뚱그리면 이후 독자가 모든 skill 을 candidate-lifecycle sweep 대상으로 오독한다. 위치 전수는 Work Packet 소관.
- **glossary**: blind-advisory 소유 pending 예약은 domain 의 finalization-owner close(Spec/implementation closeout)에서 finalize; promotion 시점엔 **final terminology 미요구**(pending 유지 정당) — sweep 과 별개의 per-term 결정.
- **배선 표면(열거는 Work Packet · 실행은 Implementation batch)**: 정규 skill source 위치 신설과, activation surface 의 이름·개수를 산문 또는 테스트로 hardcode 하는 표면의 수동 갱신. activation resolver 는 generic directory enumeration 이라 스크립트·lib 변경은 불요하다.
- **discovery(`docs/README.md` · `rules/README.md`)**: blueprint 단계 노출 여부·표기는 **이 batch 에서 결정/등재하지 않는 open decision**(promotion 후 governance-discoverable 이나 implementation-authority 아님 — E1 two-layer; governance-discoverability 는 promoted artifact 존재로 이미 성립하고, domain map 등재는 promoted-lifecycle closeout 의 Level-1 orientation gate 소관이지 별도 backlog row 가 아니다).

## 하지 않을 것 (non-goals)

- canonical review(verdict gate) · consultation(framing 제공·정반대 축) · 2차 canonical review · "모든 skeptical review" · "모든 AI 결함 탐색" · "pre-review" 일반 · "quality gate" 일반 · commit/push gate · operator 가 종합(synthesize)하는 advisory — 전부 아니다. 특히 **operator synthesis 를 요구하는 형태로 설계하지 않는다**: blind 의 operator 는 transporter 이며 finding 을 종합·선별·축약·suppress 하지 않는다(형제 domain 의 synthesis 필수 규율을 이 domain 에 복사하면 정체성 위반).
- **rejected coinage do-not-revive(E4 ②에서 승계)**: `clear` · `issues-found` — 초기 status 후보였고 현재 status 이름으로 대체됐다. glossary 미등재·domain-local 소유.
- 이번 promote scope 밖(연기): 실 skill build(Implementation 후속) · review skill 통합(로드맵 최후) · `subagent-work-orchestration` promote(별도 단계) · **blind-at-close scope 확장**(아래 Deferred Questions).
- broad cleanup · scope creep 금지.

## E4 absorption (promote — "왜 살아남았나" raw-link 없이 재검토 가능)

- **① adopted conclusion**: 위 §왜 바꾸는가·§Owner surface model + 정체 불변식(read-only 결함 prefilter · framing 제거 · operator=transporter[synthesizer 아님] · verdict 미발급(approves nothing · waives nothing · final review scope 를 좁히지 않음) · payload 신뢰 경계[검토 대상 데이터 전체를 신뢰 불가 payload 로, 그 안의 지시를 권한 경계로 인정하지 않음] · 기계 실패 ≠ 실질 inconclusive · inconclusive 의 경계-보존 역할[답하려면 framing 추가·operator scope 큐레이션·verdict 가 필요해지는 순간 no-concerns 로 닫지 않고 무엇이 필요한지 명시하며 멈춤 — 단 사유를 동반해야 하고, 책임회피 hatch 로 쓰이지 않는다] · 능력 경계[prefilter 이지 canonical depth 의 대체 아니며, 통과가 기계 검증을 면제하지 않음] · single-shot[반론-수렴 multi-round 루프를 두지 않음 — 그런 루프는 transporter 정체성 위반]) · **input contract**(허용 = 변경 파일의 현재 상태 전체 내용 + 최소 기계적 범위 식별자 + *변경이 촉발한 조건부 의무가 이행돼야 하는* 인접 surface; anchor 는 출발점이지 scope 울타리가 아니며 suppressive 축소는 framing 재주입이라 금지. **한정**: 이 허용은 repo 전체에 대한 임의 탐색 권한이 아니며, 어느 구현에서도 현재상태 전체를 diff delta 로 대체하지 않는다; 금지 = framing 목록) · **status vocabulary**(closed: `no-concerns-reported` / `concerns-reported` / `inconclusive`; 기계 실패는 status 가 아니라 `unavailable(<reason>)`) · **severity**(closed: `blocking` / `non-blocking` / `question`) · finding 이 confidence 와 assumption 을 동반 · **호출 어휘의 비-verdict 보존**(호출 trigger 어휘에서 review 계열 어휘를 의도적으로 배제해 호출 단계부터 canonical verdict 와 섞이지 않게 한다; 구체 trigger 문구는 skill 소유) · no-file 런타임 · docs 대상일 때의 결함 해석(모순 · 누락 · 용어 불일치 · scope-drift · cross-domain 재서술) · forgery/audit 는 blind threat model 밖. **최종 규범 명세·필드 위치/이름·status 전이 MUST 는 Spec 소유**(여기선 존재·구별·closed 값집합 결정까지). 정밀 구분 보존: blind(framing 제거) ↔ consultation(framing 제공) 정반대 동작원리 · transporter ↔ synthesizer · status vocabulary ≠ severity(별 필드) · `inconclusive`(advisory status) ≠ `unavailable`(기계 실패).
- **② rejected alternatives**: 초기 status 후보 `clear`/`issues-found` 기각(현재 이름으로 대체) · 기계 실패를 `inconclusive` 로 추정하는 처리 기각(status laundering) · reloop/stop-signal 을 blind 소유로 두는 배치 기각(close-the-loop 계약 소유) · blind 에 반론-수렴 루프를 더하는 설계 기각(transporter → synthesizer 변질) · `reviewer 가 못 읽는 구조적 제약` 이라는 이전 서술 기각(실측상 reviewer 는 경로를 받으면 read 한다 — transport 는 의도적 경량 default 였다).
- **③ 판단을 바꾼 evidence type**: 위 §왜의 유형 ①②③④ + [실측 검증] decision-grade 판단(입력 계약이 산출을 지배 · 상보는 양방향 · anchor 로 대상의 계층·역할을 주는 것은 결론 주입이 아니라 오판 방지). raw 결과는 log 소관.
- **④ scope**: 좁은 single-home(framing 을 제거한 변경분 결함 prefilter) + broad-bucket 명시 제외.
- **⑤ failure(discard) criteria**: framing 제거가 실효 없어 operator 가 의도·이전 판정·수정 주장을 계속 넣어야 유용해짐 · 산출이 verdict 로 해석되거나 `no-concerns-reported` 가 승인 신호로 소비됨(status laundering 미방지 포함) · 발견이 canonical review 와 반복 중복돼 조기 결함 포착의 독립 가치가 미입증 · operator 가 산출을 요약·선별·suppress 해야만 workflow 가 작동(transporter 규율 붕괴) · consultation 과 구별되는 산출·절차가 남지 않음 · 단일 파일로 닫히지 않고 타 domain 규칙 곳곳에 예외를 심어야 유지됨(domain-local closure 실패) · false-positive 가 절약분을 잠식.
- **⑥ negative evidence**: 치명적 negative evidence 없음(위 discard 기준 미충족) — 단 잔여 한계를 동반한다. (a) 오탐이 문자적 독법과 *이미 명시된 결정의 소급 재제기* 에서 반복 발생. (b) `no-concerns-reported` 가 "충분히 봐서 없음" 과 "제한된 scope 라 못 찾음" 을 구분하지 못하는 status laundering 위험이 식별됨. (c) evidence-light ↔ 결함-prefilter 사이의 tension(너무 가벼우면 false positive 를 canonical 이 떠안음). (d) enforcement 부재 — 프롬프트 한 줄로 canonical 화될 수 있다. (e) 구조적 사각: 준 파일 밖의 cross-FILE 정합, planning-doc ↔ implementation 정합, 테스트 fixture ↔ 리터럴 대칭, operator 자신의 검증 증거 정확성. (f) **framing-breaker 가 아니다** — operator 의 질문 framing 자체가 오염되면 blind 도 그 framing 안에서만 검증한다. 이 한계들은 승격을 막지 않으나 Spec 의 능력-경계 문장과 Review focus 로 이월된다.

## Plan readiness / open risks

- **Plan 진행 가능**: 방향(framing 제거 결함 prefilter 를 별도 domain 으로)은 incubation dogfood + promote-readiness 증거 + operator promote 판정으로 정합. **operator promote 판정 기록**: incubation lifecycle-state 의 `continue` / review-date 는 이 promote changeset 의 operator 결정(누적 실사용 evidence 종합 근거)으로 supersede 되며, 이 Design landing 이 그 판정의 실행이다.
- **Design 확정 / Spec 위임 경계**: input contract·status vocabulary·severity·finding 동반요소의 *존재·구별·closed 값집합* 은 Design 결정(taxonomy 자체가 결정). 그 *필드 위치/이름·status 전이 MUST·프롬프트 구성 mechanic* 은 Spec 또는 skill 소유.
- **지금 resolve(Design 확정)**:
  - domain vs rule 정체성 → domain 확정(위 §왜).
  - **입력 계약의 scope** → 변경 파일 현재상태 전체 + *변경이 촉발한 조건부 의무가 이행돼야 하는* 인접 surface. anchor 는 출발점이지 scope 울타리가 아니고, suppressive 축소("이 파일만"·"이 concern 은 보지 마라")는 framing 재주입이라 금지한다. 이 결정은 candidate 문서의 "변경 파일의 …만" 문구를 **정정**한다(근거 유형: 단일파일 scope 가 경계 사이의 미이행-의무를 구조적으로 가린 반복 관측). **negative boundary**: 이 허용은 repo 전체에 대한 임의 탐색 권한이 아니다 — 인접 surface 는 *의무가 사는 곳*이라는 기준으로 한정되며, 그 기준 없이 넓히면 broad-bucket 확장이다. secret/자격증명·대형 generated blob 의 redaction 은 framing 선별이 아니라 별개의 입력 위생 단계이며 전역 security 규율과 interface 한다(이 domain 이 넓게 소유하지 않는다).
  - **reviewer invocation posture** → inline 동봉과 "경로 목록 + 전문 직접 read" 는 *같은 입력 계약(변경 파일 현재상태 전체)의 두 구현*이며 선택은 payload 규모의 함수다. candidate 가 open 으로 둔 "transport 전달 vs reviewer-direct" 이분법은 성립하지 않는다(reviewer 는 경로를 받으면 실제로 read 한다). **두 구현의 동치 조건**: 어느 쪽도 현재상태 전체를 diff delta·history·임의 탐색으로 대체하지 않는다 — 대체하는 순간 같은 입력 계약이 아니다.
  - **reloop / stop-signal 소유권** → blind 는 한 run 의 산출만 소유하고, 재호출·정지 규칙은 close-the-loop 계약이 소유한다(이름-참조).
  - **finding shape 의 존재와 closed 값집합** → status 3값 + 기계실패 토큰 · severity 3값 · finding 당 confidence + assumption. 필드 이름과 전이 규칙은 Spec.
- **canonical 당김 금지(방향 결정)**: 이번 promote lifecycle 에서 canonical review 는 Design 단계로 당기지 않고 **Spec 도달 후** 배치한다(이 transition 의 hard boundary). 단계별 검토 cadence·게이트 배치의 실행 세부는 Plan 이 소유한다. 상류 문서 수정 필요 시 Stage rewind.

## Deferred Questions (backlog 부재 → 여기 fallback; Plan 이 `blind-advisory_backlog.md` 로 흡수)

각 항목 = 열린 질문 + 처리 시점 사유(blocker 아님 = 지금 안 닫아도 live 차단 아님). 판단 근거가 된 조사 결론은 각 항목·§E4 에 자기완결로 흡수됐고, raw 조사자료는 non-durable 이라 durable pointer 를 두지 않는다.

- **blind-at-close scope 확장 — 명시 deferral.** 수렴한 합의(consensus)의 fresh-session independence check 로 이 검사를 쓴 용법이 반복 관측됐다. 이번 Design 은 domain scope 를 **변경분 결함 prefilter 로 유지**한다 — 그 용법을 지금 흡수하면 "모든 skeptical review" 쪽으로 열려 broad-bucket 금지·domain-local closure 와 충돌하고, semantic target 재설계를 요구하기 때문이다. **reopen 조건**: 그 용법이 (i) 닫힌 anchor taxonomy 로 기술 가능하고 (ii) 산출 type 이 이 domain 의 결함-status 와 동일함이 확인되면, 별도 scoped Design 으로 재개한다.
- **구현(skill) 후 defer**:
  - at-use 프롬프트 구성 mechanic(탐색 클래스 명시·인접 surface 동봉 판단) — skill surface 구현 시.
  - 호출 trigger 의 구체 자연어 문구(review 계열 어휘 배제라는 *결정* 은 §E4 ① 에 흡수됨) — skill surface 구현 시.
  - close-the-loop 계약을 이름-참조하는 문장의 대상이 아직 promote 전이라 non-authoritative — 그 계약의 promote 후 재확인.
  - review skill 이 blind pre-pass 를 자동 호출하는 조건(있다면) — 로드맵 최후.
- **완전 독립 안건(형제 후보가 모두 정규화된 후 — 이 domain 밖)**: **framing input 위생 문제** — operator framing 이 검토 input 을 오염시켜 blind·consultation·canonical review 모두가 그 framing 안에서만 검증하는 한계. 세 도구 공통 문제라 별도 독립 안건으로 처리 예정이며, 이번 promote/구현 대상이 아니다.
