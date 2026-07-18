# consultation Design

> Design은 변경 방향을 소유하는 committed-temporary 문서다. closeout에서 current-bearing 결정을 Spec 또는 올바른 owner surface로 흡수한 뒤 retire한다. 이 문서는 mutation·commit·push 권한을 부여하지 않는다.

## Header

- 이 문서 = 아직 closeout되지 않은 `consultation` promoted lifecycle의 corrective Design이다.
- 이 체인이 끝나면 = owner-local consultation 계약과 source skill이 같은 target state를 가리키고, domain은 `prelive` 상태에서 후속 운용 검증을 받을 수 있다.
- 이 문서가 아닌 것 = live Spec, 실행 기록, review 결과, 다른 advisory domain의 의미 정의가 아니다.

## 왜 바꾸는가 / 무엇을 바꾸는가

- **현재 문제.** source skill은 이미 구현되어 있지만 기존 Design/Plan은 skill build 이전 blueprint를 전제로 한다. 현행 구현은 multi-member 일부 실패를 packaging 의미와 무관하게 처리할 여지가 있고, web 권한의 근원·실제 열람 범위·status 발동 조건이 닫혀 있지 않다. 또한 큰 응답을 모두 main context로 재게시하는 경로와 timeout 상승 문면은 현재 운용 요구 및 active execution rule과 맞지 않는다.
- **domain 독립성 문제.** consultation의 정체성은 자기 operation·request·synthesis 계약으로 닫혀야 한다. 다른 advisory domain의 framing mechanics를 대비 문장으로 재서술하면 그 domain의 변경에 종속되므로, 외부 domain은 bare name과 consultation이 수행하거나 입력으로 소비하지 않는다는 자기 negative boundary로만 남긴다.
- **semantic target.** consultation은 read-only 의견을 수집해 operator synthesis로 정직하게 종합하는 domain이다. run은 dispatch 전에 목적·expected member set·required coverage·output mode·외부 전송 권한을 고정한다. 모든 member의 종료·JOIN과 member output 검증 뒤 coverage를 판정하고, 성공이면 synthesis와 필요한 run artifact를 완성한 뒤 retention 계약을 이행해야만 terminal aggregate를 보고한다. 성공 응답을 보존하면서도 required coverage 미충족을 정상 status로 세탁하지 않는다.
- **managed output 방향.** inline을 유일 매체로 강제하지 않는다. `inline-full` / `artifact-full-read` / `artifact-capsule`과 이를 dispatch 전에 해소하는 `auto`를 closed mode set으로 채택한다. artifact mode는 `<ProjectRoot>/log/consultation/<run-id>/`의 purpose-isolated, write-once 산출만 사용하며 source·global·user surface를 건드리지 않는다.
- **web 방향.** web은 default-off다. 현재 사용자의 명시 요청 또는 active standing delegation만 authorization source가 될 수 있고, operator request는 그 provenance와 목적·범위·required/optional·fallback·별도 outbound query 경계를 구체화한다. consultation external-adapter의 상세 non-web redaction/transmission mechanics는 별도 future work다.

## 승계하는 domain 방향

- consultation은 판정 없는 read-only advisory workflow이며 review verdict나 행동 권한을 발행하지 않는다.
- framing-axis operation은 `독립 의견`(`independent`)과 `재조율`(`reconcile`) 두 개다. packaging axis는 `single-consultant` / `parallel-consultation` / `role-split-consultation` / `counterpoint` 네 개이며 두 축은 직교한다.
- `독립 의견`은 fresh one-shot이고 `재조율`은 operator가 circuit-breaker인 multi-round operation이다. session continuity는 operation 목적이지 숨은 sidecar나 자동 resume 허가가 아니다.
- operator synthesis는 모든 usable response와 한계를 왜곡 없이 표면화한다. consultant는 truth oracle이 아니고, factual claim은 operator가 원문으로 재확인한다.
- broad AI orchestration, general research, implementation delegation, canonical review, approval gate로 확장하지 않는다.

## Owner surface model

- **source skill이 behavior owner다.** request 구성, dispatch, member JOIN, recovery, output-mode 실행, operator synthesis와 user-facing delivery를 소유한다.
- **Spec은 durable target-state owner다.** coverage/status/web/session/artifact 경계를 명세하고 skill과 의미 수준 1:1을 이룬다. rules나 `docs/**`가 runtime behavior를 대신하지 않는다.
- **active execution rule은 execution safety interface다.** parallel/background member는 명시 goal 안에서 read-only로 실행되고 각자 isolated output만 쓰며 expected set 전부를 completion notification으로 JOIN한다. timeout은 validity나 범위축소 근거가 아니다.
- **runtime artifact는 authority가 아니다.** retained artifact도 다음 run의 자동 input·결정 근거·owner state가 되지 않으며, request가 정한 retention purpose·closure trigger만 따른다. cleanup ownership이나 person/operator/machine identity를 artifact metadata로 만들지 않는다.
- **외부 interface는 이름과 경계만 참조한다.** review handoff 형식은 review owner가 실제로 정의한 경우에만 따르고, 그 전에는 operator의 중립화된 수동 전달만 가능하다. `blind-advisory` workflow는 consultation이 수행하거나 request input으로 소비하지 않는다.

## 결정-grade target

- **required coverage.** dispatch 전에 run-level contract로 고정하고 기본값을 썼으면 `default applied`로 드러낸다. `single-consultant`는 그 member, `parallel-consultation`은 usable member 1개 이상(사전 상향 가능), `role-split-consultation`은 선언된 distinct role 전부, `counterpoint`는 명시 target에 대한 usable counterpoint 1개 이상을 기본으로 한다.
- **failure integrity.** coverage 미충족은 aggregate status 없이 unavailable이다. coverage가 충족되면 usable response를 모두 종합하고 unavailable member·role·reason과 실제 열람 범위를 공개한다. partial 전용 status는 만들지 않는다.
- **status identity.** 성공 aggregate는 `synthesized` / `needs-follow-up` / `conflicting-opinions` / `insufficient-context` 중 정확히 하나다. 기계 실패와 coverage 미충족은 이 집합 밖이다.
- **bounded execution.** fan-out unit은 파일 수가 아니라 독립 concern/role이고 동시 실행 member는 최대 3개다. expected set이 더 크면 3개 이하 wave로 실행한다. adapter·output mode·invocation posture/working root·artifact layout 조합이 새로운 run shape이면 required coverage에 기여하는 첫 expected member를 canary로 먼저 실행해 loader·sandbox·output·JOIN mechanics를 검증한 뒤 남은 wave를 연다.
- **output basis.** artifact member file은 bounded capsule과 full body를 함께 가진다. `artifact-capsule`에서 main은 모든 capsule을 읽고 decision-changing/rejected/conflicting item과 member당 최소 anchor 하나를 full body로 대조한다. exhaustive assurance는 `artifact-full-read`가 소유한다.
- **framing ability boundary.** 양방향 질문·fresh run·framing-pressure self-report는 완화 수단이지 질문틀 밖으로 나갈 시점을 보장하지 않는다. consultation은 framing-breaker가 아니다.
- **counterpoint target.** operator stance뿐 아니라 request가 식별한 제3자 문면·주장·가설도 target이 될 수 있으나 general debate로 확장하지 않는다.

## 수정 대상

- 같은 promoted lifecycle의 Design·Plan·Spec·Work Packet을 현재 결정에 맞게 재정렬한다.
- source consultation skill을 final Spec과 1:1로 동기화한다.
- 첫 실제 future item을 consultation backlog에 두고, orientation에는 prelive backlog read-first 경로만 더한다.
- 다른 candidate의 owner-local 명명, install/activation surface, 다른 domain 파일은 이 change의 수정 대상이 아니다.

## 하지 않을 것

- `blind-advisory`·review·install-update·rule domain의 behavior 또는 schema를 정의하거나 수정하지 않는다.
- shared helper/registry/umbrella status vocabulary를 만들지 않는다.
- managed artifact를 canonical evidence, verdict, 자동 다음-run memory, hidden per-user state로 승격하지 않는다.
- scheduler·hook·service·daemon·sidecar를 추가하지 않는다.
- exact byte threshold를 Design invariant로 만들거나 source revision의 landing을 사전 canary 실측에 결박하지 않는다. 다만 deployed flow가 새 run shape를 실제로 처음 사용할 때 수행하는 runtime canary-first 계약은 이번 target state에 포함한다.
- global installed copy, activation, Brief/handoff, promoted-lifecycle closeout를 이 batch에 포함하지 않는다.

## Plan readiness / open risks

- **Plan 진행 가능.** operation·packaging·coverage·mode·web authority·owner 경계가 decision grade로 닫혔다. Plan은 C-only corrective batch, validation, review focus, Work Packet과 backlog 처분을 고정할 수 있다.
- **capsule residual.** capsule이 full body의 의미를 완전 증명하지는 않는다. Spec/skill은 mandatory spot-check와 미완독 disclosure를 닫고, 고보증 요청은 full-read mode로 보낸다.
- **vendor continuity residual.** observable session identity와 guard 재적용을 제공하지 못하는 adapter는 `재조율` continuity를 제공할 수 없다. Spec에서 fail-closed 계약을, skill에서 concrete adapter 조건을 닫는다.
- **threshold residual.** qualitative mode selection으로 시작한다. 실제 threshold가 필요하다는 관측이 생길 때만 별도 측정으로 재개하며 현재 source landing을 막지 않는다. runtime new-shape canary는 threshold 측정이 아니라 실행 안전 gate다.
- **future work.** consultation external-adapter의 non-web redaction/transmission, `roundtable`, `council` naming만 domain backlog에 둔다. review integration·cross-domain 관계 home·general rule revision은 각 외부 owner의 single home을 따른다.
