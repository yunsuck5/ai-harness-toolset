# rule-conflict-and-revision-routing Work Packet

> 이 문서는 promotion transition과 G-1 terminal landing을 위한 round-scoped 조사·구현 매핑이다. approval target, live rule, final normative wording, 실행 기록 또는 readiness 판정이 아니며 mutation/commit/push/adoption/activation을 승인하지 않는다.

## 이번 회차의 분석 범위

- incubation의 current-bearing content가 Design에 E4로 흡수됐는지 추적할 reference map.
- terminal rule, distributed index, bootstrap trigger, glossary, validation, rule-folder closeout의 exact surface map.
- final wording 전에 재확인할 edge case와 reviewer 질문.
- source-repo residue와 foreign-owner semantics가 terminal rule로 유입되지 않게 하는 분리 메모.

## E4 / open-question reference map

| incubation source locus | current-bearing 내용 | 흡수·처분 위치 |
|---|---|---|
| 문제와 입장 근거 | hard-immutability와 instant-bypass의 대칭 실패, current source-set gap | Design `왜 바꾸는가` / `판단 근거` |
| 후보 정체성 및 single-home shape | one-rule-group, terminal owner surface, no Spec | Design Header / Owner model; Plan G-1 |
| 후보 운영 모델 1~3 | genuine-conflict admission, binding state, 두 dependency classification | Design 설계 결정; terminal rule core sections |
| 후보 운영 모델 4~6 | same-tier conflict set, inline disclosure, user revision gate | Design 설계 결정; terminal rule report/handoff sections |
| Owner interfaces / Non-goals | owner-local completion criterion, no arbitration·hidden state·source-repo dependency | Design Owner model / Non-goals; terminal rule interface/non-goals |
| promotion/discard/continue evidence | static counterexample threshold, known negative evidence, discard conditions | Design 판단 근거·failure risk; Plan validation/rewind |
| Open questions 7개 | 전부 resolved 또는 terminal close 지점 배정 | Design 처분 표; Plan open-decision close 지점 |

## Promotion-transition surface map

| surface | 분석 메모 |
|---|---|
| `rule_docs/rule-conflict-and-revision-routing/rule-conflict-and-revision-routing_incubation.md` | candidate-lifecycle closeout에서 삭제. shadow/archive 사본을 repo에 남기지 않음 |
| `rule_docs/rule-conflict-and-revision-routing/rule-conflict-and-revision-routing_design.md` | E4 decision-grade absorption의 single home. round 로그·최종 normative 문면 배제 |
| `rule_docs/rule-conflict-and-revision-routing/rule-conflict-and-revision-routing_plan.md` | transition 이후 terminal landing을 한 batch로 결박. micro-batch·실행 mechanics 배제 |
| `rule_docs/rule-conflict-and-revision-routing/rule-conflict-and-revision-routing_work_packet.md` | exact path/reference/edge-case만 보유. review·validation 결과는 보유하지 않음 |
| `rules/terminology-glossary.md` | Design/Plan/WP에 노출되는 candidate id와 두 분류값을 thin `pending`으로 예약. positive meaning·procedure·schema 금지 |
| `scripts/docs-working-model-check.ps1` | 기존 per-candidate bound set에 G를 추가한다. bound id가 pure label=value prefix(candidate field 순서 무관) 또는 complete legacy form으로 식별된 행만 검사하고, positive prose/non-provenance/unbound form은 manual로 남긴다. 식별된 행의 separator/schema/collision/common-pointer 구조는 hard gate에서 닫음 |
| `tests/docs-working-model-check.Tests.ps1` | unbound exemption 유지 + bound G legacy failure/thin-form + known/unknown prose FP + separator/field-order/empty/duplicate/case/collision/common-pointer + slash-marker/term-token 회귀를 고정 |
| `rule_docs/docs-working-model/docs-working-model_backlog.md` | DWM-B-02에서 이미 구현된 candidate Pending 검사를 제거하고 남은 owner-pending 전이·schema·monotonicity와 새 start condition만 future work로 유지 |

Pre-transition tracked reference 조사에서 candidate id와 내부 분류값의 canonical sibling mention은 없었고, candidate 문서 외부의 durable reference도 없었다. 따라서 promotion sibling sweep의 변경 대상은 별도로 발견되지 않았으며, transition 자체가 만드는 Design/Plan/WP/glossary usage는 promoted 상태에 맞는 새 usage로 분류한다.

## G-1 exact target inventory

| target | 구현·흡수 메모 |
|---|---|
| `snippets/rules/rule-conflict-and-revision-routing.md` | self-contained English/vendor-neutral terminal rule. Design의 transport model만 normative form으로 흡수 |
| `snippets/rules/README.md` | distributed admission을 만족하는 한 rule-group으로 index에 추가. 다른 rule 의미를 재서술하지 않음 |
| `snippets/CLAUDE_SNIPPET.md` | rule trigger gate에 좁은 action-class→file route 추가 |
| `snippets/AGENTS_SNIPPET.md` | Claude snippet과 의미·배치 대칭인 route 추가; vendor-specific destination wording 외 차이 금지 |
| `rules/terminology-glossary.md` | finalization-owner close에서 세 pending term을 항목별 finalize하거나 근거·다음 close-condition을 갖춘 owner-pending으로 전환 |
| `tests/**` 및 `scripts/docs-working-model-check.ps1` | prose 의미를 억지로 기계화하지 않음. 기존 lifecycle/index/payload 검사가 새 invariant를 놓치는 실제 gap이 있을 때만 비례 수정 |
| `rule_docs/rule-conflict-and-revision-routing/` | terminal rule과 current-bearing absorption이 corrected-state review를 통과한 closeout에서 planning docs 삭제 + `.gitkeep`; backlog row가 없으면 backlog 파일 미생성 |

기존 `snippets/rules/repository-change-safety.md`, `snippets/rules/no-background-or-hidden-state.md`, `snippets/rules/global-file-mutation-boundary.md`는 interface 대조 입력이지 수정 target이 아니다. terminal 구현 중 이 본문 수정이 필요해 보이면 G-1 범위 확장으로 처리하지 않고 owner-local revision 필요성을 별도 보고한다.

## Terminal content decomposition notes

1. **When to load / admission:** active owner + concrete operation/acceptance + actual incompatibility. 정상 질문, 비용, 불편, 노후 주장만으로 진입하지 않는 negative boundary.
2. **Binding state:** current owner rule과 explicit exception branch를 보존하고 user task approval을 exception과 분리.
3. **Containment:** isolated all-of facts, unit-blocking fallback, prospective rescope와 retroactive completion 금지의 구분.
4. **Conflict set:** same-tier owners를 함께 surface하되 precedence와 joint-batch mandate를 만들지 않음.
5. **Disclosure:** inline-default 최소 report가 evidence/status/decision need를 보이되 completion claim을 만들지 않음.
6. **Revision handoff:** compliant rescope / hold-or-drop / owner-local revision start를 분리하고 downstream mutation gates를 보존.
7. **Owner interfaces:** 더 완전한 owner-local contract 우선, 부분 contract에는 누락 transport만 보충.
8. **Non-goals:** arbitration, exception authority, hidden state, automatic mutation, source-repo governance dependency 배제.

## Trigger 및 classification edge cases

| case | terminal wording에서 확인할 경계 |
|---|---|
| explicit owner exception | conflict가 아니라 owner 정상 경로로 남는가 |
| rule applicability가 unknown | G가 범위를 추정하지 않고 owner clarification으로 되돌리는가 |
| read-only independent investigation | isolated continuation을 허용해도 전체 completion claim이 닫혀 있는가 |
| blocked artifact가 acceptance 필수 | 대체 산출로 완료를 세탁하지 않고 unit-blocking 되는가 |
| post-hoc scope split | 검증 차단 후 이름만 바꾼 unit 분리를 거부하는가 |
| shared validator/state/transaction | 직접 의존뿐 아니라 전이·coherence dependency도 포함하는가 |
| same-tier recursive conflict | 한 conflict set으로 평탄화하고 G 자기 우회·무한 보고를 막는가 |
| user asks to ignore old rule | revision evidence와 current permission을 분리하는가 |
| owner contract has stop/report only | schema 복제 없이 missing revision handoff만 보충하는가 |
| batch split | permission을 만들지 않고 각 owner lifecycle 독립성만 보존하는가 |

## Evidence 및 audit 제안

- **Structural:** active-lifecycle snapshot, atomic incubation removal, rule-folder purity, E2/E3, glossary reservation form, sibling mention sweep.
- **Local correctness:** trigger/admission과 report/revision handoff가 자족하며 contradiction이나 undefined status가 없는지.
- **System coherence:** existing owner rules·approval gates·snippet symmetry·distributed admission·public-safe boundary와 충돌하지 않는지.
- **False-positive attacks:** user approval→exception, post-hoc rescope, shared dependency 누락, batch split bypass, owner-local suppression gap, same-tier recursion, hidden state, source-repo residue.
- **Mechanical proposal:** docs-working-model checker, full Pester, PowerShell verifier, exact snippet payload/index comparison. 새 test는 stable machine-checkable invariant가 기존 suite에 실제로 없을 때만 추가.

## Reviewer 질문 준비

- trigger 문면이 단순 “규칙을 바꾸고 싶다”와 genuine blocked operation을 구분하는가.
- `conflict-isolated`가 continuation permission이 아니라 dependency containment 판정으로만 읽히는가.
- unknown을 unit-blocking으로 두면서도 독립 read-only evidence 수집까지 전역 중단하지 않는가.
- owner-local completion criterion이 generic rule을 무조건 우선하거나 무조건 suppress하지 않는가.
- terminal rule만 읽어도 adopter가 revision decision까지 도달할 수 있고 source repo lifecycle을 알 필요가 없는가.
- glossary finalization이 classification token의 one-line meaning만 소유하고 full procedure를 복제하지 않는가.
