# consultation Work Packet

> 회차성 조사·구현 보조 문서다. 승인 대상·live 문서·Spec 대체가 아니며 실행 명령, staging, validation/review 결과, readiness 판단을 담지 않는다. promoted-lifecycle closeout에서 흡수 후 삭제한다.

## Current-source disposition

| ID | Current surface | Disposition | Target / question |
|---|---|---|---|
| C-01 | read-only · advisory · no-verdict invariants | `reuse` | user escalation과 no-action boundary가 Spec/skill에 같은 의미인가 |
| C-02 | `독립 의견` fresh one-shot | `correct` | anchoring-exclusion 목록과 factual-frame 보존이 함께 드러나는가 |
| C-03 | `재조율` persistent session | `correct` | observable explicit session·guard reapply·no-auto-resume가 없는 adapter를 fail-closed하는가 |
| C-04 | packaging enum | `reuse` + `correct` | counterpoint의 third-party target과 required coverage가 추가되는가 |
| C-05 | status 이름만 있는 current text | `correct` | exactly-one success와 firing/provenance, mechanical unavailable 분리가 닫히는가 |
| C-06 | conflict-default reconciliation | `correct` | `conflicting-opinions`가 reconciliation residue/human residual에서만 발동하는가 |
| C-07 | request-owned inspection scope | `correct` | authorized/actual/skipped self-report와 payload trust가 붙는가 |
| C-08 | web posture 부재/고정 adapter posture | `correct` | default-off authority provenance·별도 outbound query·fallback·source disclosure가 닫히는가 |
| C-09 | no-file/inline-only output | `discard` | U3 four-mode managed media로 대체하되 inline-full은 계속 file-free인가 |
| C-10 | prompt scratch / response transcript 예외 | `correct` | prompt scratch는 sequential-foreground bounded cleanup으로, 큰 output은 managed run home으로 귀속되는가 |
| C-11 | timeout에서 timeout 상승 | `discard` | completion notification JOIN과 definitively-terminated failure 뒤 1회 recovery로 대체되는가 |
| C-12 | operator synthesis 3-part shape | `reuse` + `correct` | unavailable set·predicate·actual scope·raw-read basis가 추가되는가 |
| C-13 | foreign domain 대비 | `discard` | bare name + C가 수행/입력소비하지 않는다는 C-owned boundary만 남는가 |
| C-14 | 가정된 review preflight interface | `correct` | 현재는 neutralized manual handoff, future interface는 owner landing 후 조건부인가 |
| C-15 | lifecycle maturity narrative | `correct` | compact `prelive` marker만 남고 시점성 후속 경로가 제거되는가 |

## Decision-to-surface mapping

| Decision | Design | Plan | Spec | SKILL | Backlog / orientation |
|---|---|---|---|---|---|
| F2 hybrid coverage | semantic target·defaults | batch/failure gate | run contract·coverage·status | request freeze·JOIN·synthesis | — |
| F3/F3b web | authority/outbound direction | owner boundary | normative permission/fallback | request fields·adapter posture | consultation external-adapter non-web mechanics only |
| F4 owner-local | identity·non-goal | foreign-edit prohibition | name-only interface | trigger/body boundary | cross-domain home 복제 0 |
| F6 payload/coverage/status | decision-grade ability | review focus | durable semantics | concrete request/output | — |
| U3 managed output | four-mode choice | media/retention decision | mode/artifact contract | run directory·read/write/join | future tuning을 current blocker로 큐잉 0 |
| current execution rule | owner interface | no-timeout-as-validity/no-hidden boundary | session/recovery/JOIN | cap·canary·completion-notification mechanics | rule revision 복제 0 |

## Managed artifact layout analysis

Artifact mode의 purpose root 후보는 `<ProjectRoot>/log/consultation/<run-id>/`다.

| Artifact | Creation point | Unique content | Consumer |
|---|---|---|---|
| `request.md` | dispatch 전 | resolved run contract·authority provenance·expected set·coverage·mode·retention | operator / member dispatcher |
| `members/<member-id>.md` | current dispatched turn의 member-terminal response 뒤 | capsule 1개 + full body 1개; 다음 reconcile round는 새 run-id | operator |
| `index.md` | launched-member JOIN·unlaunched-expected accounting·read-time hash demotion 뒤 | final outcome·path·bytes·SHA-256·actual scope 요약, response body 없음 | operator / user handoff |
| `synthesis.md` | durable synthesis가 실제 요청된 경우만 | operator synthesis, raw body 복제 없음 | user / follow-up |

중복 방지 질문:

- request payload가 이미 읽을 수 있는 source file이면 `request.md`에 전문을 다시 복제해야 하는가.
- capsule과 full body를 별도 파일로 나누지 않고 한 member file에 두어 anchor가 같은 write-once object를 가리키는가.
- index가 response를 재요약해 두 번째 capsule이 되지 않는가.
- inline output이 retained synthesis와 같은 본문을 불필요하게 이중 저장하지 않는가.

## Capsule and full-body review notes

- capsule candidate fields: item id, claim/counterpoint, confidence, assumption, limitation, full-body anchor, decision-bearing coverage statement.
- mandatory main reads: 모든 usable capsule 전량.
- mandatory body checks: operator가 기각할 item, current decision을 바꾸는 item, capsule 간 모순 item, 그리고 위 범주가 없는 member의 최소 anchor 1개.
- disclosure candidate: `raw-not-fully-read-by-main`, inspected member/anchor set, synthesis basis.
- false assurance question: hash/spot-check가 semantic completeness proof처럼 표현되지 않는가.

## Failure and JOIN edge cases

- expected set 일부가 running인 상태에서 다른 member의 usable response만으로 aggregate를 만드는 경로.
- fan-out을 파일 수로 세거나 동시 member가 3개를 넘는 경로, 새 run shape에서 canary 검증 전 남은 wave를 여는 경로.
- timeout 후 선행 process 종료 확인 없이 새 retry를 시작해 동일 member가 두 개 running이 되는 경로.
- completion notification 유실 또는 종료 불명 상태를 terminal unavailable로 세탁하거나, 취소 시 unlaunched expected member를 process처럼 terminate/JOIN하려는 경로.
- canary recovery attempt의 completion/JOIN이 미확정인데 `unavailable(canary-gate-failed)`로 닫거나 다음 wave·retry를 여는 경로.
- prompt create/write/flush 실패가 member recovery budget을 잘못 소비하거나 leftover accounting을 잃는 경로.
- dispatch 전 safe input·required source·role·contract·`request.md`가 불완전한데 member를 launch하는 경로.
- complete member body는 생성됐지만 managed-artifact handoff가 실패한 response를 usable로 부르거나 consultant를 재호출하는 경로. canary면 recovery-ineligible gate failure이고 non-canary면 별도 run-level failure가 없는 한 member-scoped unavailable인지 대조한다.
- artifact write가 partial인데 path 존재만으로 usable로 분류하는 경로.
- capsule/anchor·actual-scope 이유가 빠지거나 read-time hash가 달라졌는데 usable로 분류하는 경로.
- dispatch source가 synthesis 전에 바뀌었는데 기존 fingerprint로 synthesis하는 경로.
- role-split의 한 role 실패를 supplemental failure로 낮추는 경로.
- optional role을 role-split distinct required role로 숨겨 의도와 반대로 전체 실패시키는 경로.
- coverage 충족 뒤 unavailable member를 synthesis에서 누락하는 경로.
- supplemental member의 mechanical/parse/artifact failure를 coverage 평가 없이 run-level unavailable로 승격하는 경로.
- canary의 advisory-content 부족을 run-shape gate failure로 오인하거나, 반대로 sandbox/loader/JOIN/output/required-shape gate 실패 뒤 남은 wave를 실행하는 경로.
- canary transport/artifact failure에서 recovery-ineligible 전이가 빠져 member-scoped coverage 경로와 `canary-gate-failed` 경로가 동시에 열리는 경우.
- 겹치는 status 조건에서 precedence 없이 임의 status를 선택하는 경로.
- `insufficient-context`로 mechanical failure·coverage miss를 숨기거나 request-gap을 consultant 탓으로 돌리는 경로.
- `run-bound-delete`를 final response 뒤 cleanup하려 하거나 cleanup 실패에도 성공 status를 발행하는 경로.
- primary failure 뒤 cleanup failure가 원 reason을 지우거나 exact leftover를 누락하는 경로.
- canary primary failure 뒤 index failure가 대표 reason을 덮거나, verified index 뒤 hash mismatch의 stale divergence를 숨기는 경로.
- supplemental capsule을 index 뒤 처음 읽어 동일 hash mismatch의 terminal outcome이 read 순서에 따라 달라지는 경로.
- first-read hash 뒤 mandatory anchor 또는 index 전 변경을 놓치거나, terminal 전 post-index recheck 없이 mismatch 분기를 선언만 하는 경로.
- `needs_reply` loop state가 aggregate status를 대체하거나 `needs-follow-up`과 같은 token으로 취급되는 경로.
- `runtime-retained` artifact가 다음 run의 자동 context로 들어가거나 cleanup ownership/operator/machine identity metadata를 갖는 경로.

## Web and payload edge cases

- operator가 스스로 작성한 request를 web authorization source로 순환 사용하는 경우.
- web enable을 outbound transmission permission으로 오독해 private path·payload body를 query에 넣는 경우.
- optional fallback을 dispatch 뒤 발명하거나 required evidence 실패를 일반 synthesis로 닫는 경우.
- 검색 결과 또는 inspected file 안의 instruction을 live instruction으로 따르는 경우.
- 반대로 same-harness system/developer/repo instruction을 payload라며 무효화하는 경우.
- authorized scope를 actual inspection으로 과장하거나 skipped/unavailable source를 숨기는 경우.

## Owner-local reference sweep

- Design: bilateral framing contrast, 외부 domain lifecycle/status 묶음, discard criterion의 foreign identity 의존.
- Spec: vocabulary/operation contrast, foreign output 결합 semantics, 시점성 cross-domain roadmap.
- SKILL: frontmatter do-not-trigger 문구를 name-only routing으로 유지하되 foreign behavior 설명 제거; `What this is not`, status 비교, cross-domain interface도 같은 원칙 적용.
- Work Packet: 과거 promotion sibling inventory를 current C-owned sweep으로 대체.
- 다른 domain source는 C unit에서 수정하지 않는다.

## Backlog ownership

| Candidate | Owner disposition |
|---|---|
| consultation external-adapter non-web redaction/transmission | `CONS-01` |
| `roundtable` support | `CONS-02` |
| `council` alias | `CONS-03` |
| review integration/interface | review owner queue; C에 복제하지 않음 |
| cross-domain relation home / general rule revision | external rule-work owner; C에 복제하지 않음 |
| managed-output threshold | current qualitative contract로 닫음; actual failure evidence 전에는 queue를 만들지 않음 |
| vendor session continuity | current Spec/skill에서 fail-closed; rule revision queue로 복제하지 않음 |

## Fresh review question preparation

- packaging별 defaults가 C purpose에서 너무 느슨하거나 엄격한 반례가 있는가.
- run-level resolved contract가 member request에 불필요한 peer framing을 새로 넣는가.
- artifact-capsule이 selective synthesis를 구조적으로 숨길 경로가 남는가.
- web authority와 outbound query boundary가 서로 독립적으로 검증 가능한가.
- current execution rule 아래 모든 parallel member가 isolated output·expected set·all-JOIN 조건을 충족하는가.
- owner-local sweep이 B semantics를 지운 대신 C identity까지 흐리게 만들지는 않았는가.
