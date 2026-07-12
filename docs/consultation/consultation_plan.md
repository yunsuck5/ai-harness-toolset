# consultation Plan

> Plan은 승인 대상인 의사결정만 담는 committed-temporary 문서다. 조사·line-level 분류는 Work Packet, 실행 기록은 `log/**` 소관이다. 이 문서는 mutation·commit·push 권한을 부여하지 않는다.

## Header

- 이 문서 = consultation promoted lifecycle의 current corrective Plan이다.
- 이 체인이 끝나면 = C-only target state가 Spec과 source skill에 함께 반영되고 current bytes가 독립 검토 경계로 고정된다.
- 이 문서가 아닌 것 = Design, Spec, 실행 순서 메모, validation/review 결과가 아니다.

## Batch와 의존

- 이번 revision은 **단일 C owner batch**다. Design 정합을 상류로 삼아 Plan을 재시작하고, target Spec을 먼저 확정한 뒤 source skill과 Work Packet/backlog/orientation을 동기화한다.
- 다른 domain·rule unit은 의존 입력이 아니다. G의 promoted-but-not-live 산출, E0-1 봉인본, 과거 review 결과를 behavior 근거나 current correctness 근거로 사용하지 않는다.
- source skill의 carried-over 문면은 non-authoritative input으로 분류해 `reuse` / `correct` / `discard`를 Work Packet에서 판단한다. 구현은 final Spec만을 normative target으로 삼는다.

## Batch 정의 — consultation owner-local corrective

- **목적**: packaging-specific failure integrity, request-authorized web, owner-local identity, C-owned graft, managed output을 하나의 reconstructible consultation 계약으로 맞춘다.
- **scope**: consultation lifecycle artifacts·source skill·domain backlog, 그리고 prelive backlog로 가는 최소 docs orientation route.
- **hard boundary**: B/IU/rule/review behavior 수정 0 · foreign semantics 재서술 0 · G semantics 소비 0 · scheduler/hook/service/sidecar 0 · installed/global activation 0 · revision-admission canary 선결 0 · commit/push는 별도 사용자 gate. 새 run shape의 runtime canary-first는 source skill 계약으로 구현한다.
- **validation expectation**: Design/Plan/Spec/WP checklist · Spec↔SKILL 1:1 · F2/F3/F4/F6/U3/current-rule decision→surface matrix · foreign-semantics sweep · docs-working-model checker · skill frontmatter validation · activation mirror regression · full Pester · encoding/diff hygiene.
- **review focus**: required coverage의 사후 완화·subset 세탁 · status laundering · capsule omission/미독 은폐 · web authorization과 outbound query 권한 혼동 · timeout-상승/미JOIN · hidden auto-resume · foreign domain 대비 재유입.
- **Work Packet 필요**: 예. 목적 = current source line/section disposition, decision→surface mapping, artifact/session/failure edge-case와 backlog ownership 조사. 흡수 대상 = Spec·source skill·backlog 또는 operator report. retire 조건 = consultation promoted-lifecycle closeout.

## Output-mode 결정

- supported mode는 `inline-full`, `artifact-full-read`, `artifact-capsule`, pre-dispatch `auto`다.
- mode·fallback·retention은 dispatch 전에 run-level contract로 해소하고 실패 뒤 바꾸지 않는다. multi-member 또는 예상 output budget이 크거나 불명확하면 `artifact-capsule`, exhaustive/high-assurance 요청이면 `artifact-full-read`를 선택한다. 수치 threshold는 이번 Plan에서 요구하지 않는다.
- managed home은 `<ProjectRoot>/log/consultation/<run-id>/`다. artifact mode에 실제 필요한 request/member/index/optional synthesis만 만들고 payload·raw body·synthesis를 중복 저장하지 않는다.
- `run-bound-delete`와 `runtime-retained` retention class를 사용한다. 전자는 terminal user response 전에 synthesis·run accounting을 마치고 cleanup하며 최종 응답에는 historical path/hash와 cleaned state를 공개한다. 후자는 명시 purpose·closure trigger를 가진다. cleanup ownership metadata는 기록하지 않는다. 어느 artifact도 다음 run의 자동 input이 아니다.

## Failure·session 결정

- expected member set·required coverage·member purpose·recovery budget은 dispatch 전에 고정한다. 모든 process 종료, completion notification JOIN, write completion, scratch/artifact accounting 뒤에만 aggregate를 판정한다.
- fan-out unit은 독립 concern/role이고 동시 실행은 최대 3개다. expected set이 더 크면 3개 이하 wave로 나눈다. 새 run shape는 required coverage에 기여하는 expected member 하나를 canary로 먼저 실행하고 sandbox·loader·output·JOIN mechanics가 usable일 때만 남은 wave를 연다.
- timeout은 새 retry·범위축소·status 추정 근거가 아니다. 선행 invocation 종료가 확정된 동일 전달의 기계 실패에만 member당 1회 recovery를 허용한다.
- `독립 의견` recovery는 동일 request의 새 fresh invocation이고, `재조율` recovery는 observable session identity를 operator가 명시 선택하고 read-only guard를 다시 적용할 수 있을 때만 same-session resume다. 자동 resume나 permissive fallback은 없다.
- complete response body가 생성됐지만 artifact handoff가 실패하면 아직 usable response가 아니며 consultant를 다시 호출하지 않는다. canary에서는 recovery-ineligible gate failure로, non-canary에서는 별도 run-level failure가 없는 한 member-scoped unavailable로 처리한다. process 종료/JOIN 미확정은 이 terminal 분류보다 앞서는 non-terminal 상태다.

## Web·payload 결정

- web은 default-off다. current user-explicit 또는 active standing delegation provenance가 있을 때만 request가 목적·scope·required/optional·fallback을 구체화한다.
- web 사용 권한과 outbound query 전송 권한을 분리한다. payload body·private path·secret을 query로 보내지 않고 실제 source와 미사용 fallback을 synthesis에 공개한다.
- inspection payload는 data지만 실제 system/developer/repo instruction은 계속 binding이다. 외부 CLI의 loader shield가 실패하면 sole-request authority를 주장하지 않고 member를 unavailable로 닫는다.

## Open decision의 close 지점

- **coverage/status**: Spec에서 normative semantics를, skill에서 request/dispatch/synthesis mechanics를 닫는다.
- **capsule/full-body**: Spec에서 mandatory contents·spot-check·disclosure를, skill에서 file layout·read/join/cleanup mechanics를 닫는다.
- **vendor continuity**: Spec에서 observable/explicit/no-auto-resume boundary를, skill에서 adapter별 guard 재적용을 닫는다.
- **backlog**: 첫 queued item과 함께 지금 생성한다. closeout에서 처음 만든다는 과거 Plan 문면은 폐기한다.
- **docs orientation**: §5 live-domain map은 closeout 전 변경하지 않고, 현재 존재하는 prelive consultation backlog의 read-first route만 반영한다.
- **future threshold**: 현재 landing에는 수치 threshold나 revision-admission canary 실측이 필요하지 않다. 실제 mode-selection 실패나 별도 사용자 요청이 있을 때 별도 evidence goal로 재개한다. 새 run shape의 runtime canary-first는 현재 skill에 남는다.

## Stage rewind 조건

- Spec이 Design의 owner·coverage·mode·web·ability boundary를 위반하면 Plan을 다시 세운다.
- source skill이 Spec 의미를 초과하면 구현을 멈추고 Spec/Plan 경계를 재판단한다.
- C correctness가 B/IU/G semantics나 수정에 의존하게 되면 owner-local batch를 중단하고 scope를 다시 확인한다.
