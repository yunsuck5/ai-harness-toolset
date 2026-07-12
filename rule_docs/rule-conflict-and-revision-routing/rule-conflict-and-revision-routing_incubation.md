# rule-conflict-and-revision-routing Incubation (rule candidate — non-authoritative)

## Header

**이 문서는 무엇인가.** `rule-conflict-and-revision-routing` **rule candidate**의 단일·자족 planning home이다. 적용 중인 규칙과 요청된 작업이 충돌할 때 현재 규칙을 즉석에서 우회하지 않으면서, 영향 범위를 격리하고 규칙 개정 여부를 사용자 결정으로 보내는 adopter-universal 운영 규율이 별도 global-distribution rule로 필요한지 평가한다.

**non-authoritative.** 이 후보는 정규 규칙도, 기존 규칙의 예외도, 구현 승인의 근거도 아니다. canonical rules/indexes는 이 문서나 경로를 durable reference 또는 동작 입력으로 사용하지 않는다. 이 문서가 존재해도 현재 active rule은 그대로 binding이며, 후보의 판단 모델은 promotion 전 canonical authority를 갖지 않는다.

**owner / review-date.** owner는 사용자다. 첫 review-date는 **2026-08-12**다. 사용자는 그 전에 promote / discard / continue를 판단할 수 있다. continue하면 그 결정에서 다음 review-date를 새로 정해야 하며, 날짜를 넘긴 미결 후보는 새 판단 전까지 stale·non-conformant 상태다.

**open questions.** 이 후보가 독립 rule로 살아남을 만큼 cross-owner gap을 갖는지, 내부 분류값 `conflict-isolated` / `conflict-unit-blocking`의 경계를 preference가 아니라 dependency facts로 재현 가능하게 판정할 수 있는지, 그리고 runtime trigger/report가 source-repo governance 없이도 자족할 수 있는지가 열려 있다. 구체 질문은 아래 *Open questions*에 모은다.

## 문제와 입장 근거

### 해결하려는 문제

적용 중인 active rule이 요청된 작업을 금지하거나 서로 양립할 수 없는 조건을 요구할 때, 흔한 실패는 두 방향이다.

1. 규칙 문면을 불변의 최종 목적처럼 취급해, 그 규칙을 정식으로 재검토·개정할 필요까지 “위반”으로 닫는다.
2. 반대로 규칙의 취지가 오래됐거나 불편하다는 이유로 즉석 예외·재해석·force를 만들어 현재 binding 상태를 조용히 무력화한다.

필요한 것은 양쪽의 중간 타협이 아니라, **현재 규칙을 지키는 상태에서 충돌을 분리·보고하고 규칙의 owner lifecycle을 다시 열 수 있게 하는 routing**이다. 현재 global-distribution tier에는 이 일반 경로의 single home이 없다.

- `repository-change-safety`는 instruction과 machine-enforced repository invariant가 충돌할 때 중단하고 force bypass를 금지하는 좁은 repository-mutation 경계를 소유한다. 일반 active-rule conflict나 규칙 개정 routing 전체를 소유하지 않는다.
- `no-background-or-hidden-state`는 trigger / execution / hidden-state 안전 의미를 소유한다. 그 의미가 새 정당한 작업 필요와 충돌할 때 어느 부분을 멈추고 어떻게 revision gate로 보낼지는 소유하지 않는다.
- `global-file-mutation-boundary`는 global/user instruction file의 mutation과 managed-block 경계를 소유한다. 다른 규칙의 충돌 중재 owner가 아니다.
- source repository의 docs-working lifecycle은 이 저장소의 규칙을 추가·개정하는 governance다. 배포된 adopter runtime이 따라야 할 일반 conflict-routing 의미는 아니다.

따라서 특정 기존 규칙에 이 경로를 graft하면 그 규칙의 도메인 고유 의미를 넓히고, 여러 규칙에 반복하면 routing 자체가 복제된다. 후보는 **규칙 의미나 우선순위를 소유하지 않고, conflict event의 containment / disclosure / revision handoff만 소유하는 한 rule-group**으로 입장한다.

### motivating evidence와 한계

- **positive evidence type:** 여러 작업 세션에서, 오래된 안전 default와 현재의 정당한 운용 필요가 긴장할 때 “닫힌 규칙이므로 작업 자체를 기각”하거나 “취지를 추정해 사실상 우회”하는 두 실패 모드가 반복 관측됐다. 사용자 제공 운용 맥락은 현재 세션에서 같은 현상을 재현하지 못했다는 이유만으로 negative evidence가 되지 않는다.
- **repository evidence:** 현재 distributed rules 중 일반 conflict stop 문면은 machine-enforced repository invariant에 한정된 owner-local 규칙이며, cross-rule revision routing은 발견되지 않았다.
- **known negative evidence:** 아직 이 일반 rule이 originating case 밖의 여러 owner에서 실제 결과를 개선했다는 통제 실측은 없다. `conflict-isolated` / `conflict-unit-blocking` 분류도 live use에서 안정성을 입증하지 않았다. 새 always-on rule은 인지 비용과 과도한 stop 가능성을 추가한다.
- **judgment-changing evidence:** 향후 사례가 모두 기존 owner-local 규칙으로 자족적으로 닫히거나, dependency 기반 분류가 반복해서 주관적 정책 중재로 변하면 독립 rule 필요성 판단은 discard 쪽으로 바뀐다.

## 후보 정체성 및 single-home shape

### 후보 한 문장

> 적용 중인 rule을 준수하면서 요청된 acceptance condition을 달성할 수 없는 genuine conflict가 발견되면, 현재 rule을 binding으로 유지한 채 영향 범위를 dependency 기준으로 격리하고, blocked 상태와 대안을 공개한 뒤 사용자에게 compliant alternative 또는 owner-local rule revision 선택을 요청한다.

### 예상 owner surface

후보가 살아남으면 최종 single home은 self-contained global-distribution rule `snippets/rules/rule-conflict-and-revision-routing.md`다. 그 terminal rule은 adopter가 이 source repository를 전혀 몰라도 읽고 따를 수 있어야 한다. `rule_docs/**`, `docs/**`, repo glossary, review trace, relay, `log/**`는 runtime 의미나 준수 절차의 의존성이 될 수 없다.

### success-absorption / failure-deletion

- **promote 선택 시:** 이 문서의 current-bearing 판단을 E4 형태로 entry `rule-conflict-and-revision-routing_design.md`에 흡수하면서, 같은 promotion changeset에서 이 `_incubation.md`를 삭제한다. 이후 별도 사용자 gate 아래 Design → Plan → terminal rule 순서로 진행한다. rule candidate에는 별도 Spec이 없다.
- **discard 선택 시:** 이 문서와 `rule_docs/rule-conflict-and-revision-routing/` 폴더 전체를 삭제한다. canonical surface로 흡수하지 않으며, 끝낸 negative evidence와 discard 이유는 승인된 discard commit message가 보존한다.
- **continue 선택 시:** 문서는 계속 non-authoritative이며 새 review-date를 반드시 정한다.

## 후보 운영 모델

### 1. genuine conflict를 먼저 입증한다

다음 세 가지가 모두 있어야 이 후보가 다루는 conflict다.

1. **applicable owner surface:** 현재 작업에 실제로 적용되는 active rule과 충돌 조항을 식별할 수 있다.
2. **requested operation / acceptance condition:** 무엇을 실행하거나 무엇을 완료로 주장하려는지 구체적이다.
3. **incompatibility:** rule을 지키는 compliant path로는 그 operation 또는 acceptance condition을 달성할 수 없다.

비용 증가, 불편, 선호 차이, “규칙이 오래돼 보임”, 현재 세션에서 위험을 재현하지 못함은 그 자체로 conflict 입증도 rule 폐기 근거도 아니다. 반대로 rule이 명시적으로 허용한 branch나 scoped exception gate가 있으면 그것은 conflict가 아니라 그 rule의 정상 경로다. 먼저 해당 owner의 자족 의미를 따른다. rule의 applicability 자체가 불명확하면 이 후보가 적용 범위를 넓히거나 줄이지 않고 해당 owner로 되돌려 확인하며, 확인 전 conflict 판정은 `unknown`으로 둔다.

### 2. 현재 binding 상태를 보존한다

- conflict를 발견했다는 사실은 rule을 정지시키지 않는다.
- 사용자에게 원래 작업을 승인받았다는 사실도 rule revision 또는 exception 승인을 대신하지 않는다.
- rule이 스스로 명시한 exception mechanism이 없는 한 즉석 예외, 완화 해석, force flag, 임시 우회 구현을 만들지 않는다.
- 변경된 rule이 applicable active surface에 정식으로 landing하기 전까지 기존 rule이 계속 governing state다.
- host instruction priority나 더 높은 안전 경계를 이 후보가 새로 정의하거나 뒤집지 않는다. 상위 경계가 개정 불가능한 범위라면 hard boundary로 보고하고 중단한다.
- revision 근거를 모으는 실험도 현재 rule을 준수해야 한다. 허용된 read-only evidence로 판단할 수 없고 위반 실험만 남으면 실행하지 않고 `unknown` / insufficient evidence로 보고한다.

### 3. 충돌의 영향 범위를 dependency facts로 분류한다

이 분류는 어느 정책이 옳은지 판정하는 arbitration이 아니라, 어디까지 멈춰야 완료 세탁을 막을 수 있는지 정하는 containment 판단이다.

#### `conflict-isolated`

아래 조건이 **모두** 성립할 때만 `conflict-isolated`다. 분리 경계는 conflict 발견 **전**의 목표·acceptance criteria·dependency 구조에서 이미 독립 단위였거나, 사용자가 앞으로의 목표를 명시적으로 재범위해 새 단위로 만든 경우여야 한다. agent가 막힌 뒤 acceptance를 사후 축소해 `conflict-isolated`라고 선언할 수 없고, 사용자 재범위도 과거 blocked unit을 소급 완료시키지 않는다.

- 계속할 work가 blocked output, side effect, assumption과 직접·전이 dependency를 갖지 않는다.
- blocked branch와 shared invariant / mutable state / 두 결과를 함께 구속하는 shared owner contract / validator scope / transaction·commit boundary / acceptance gate / coherence review unit을 공유하지 않는다. 같은 rule 또는 owner surface가 두 work에 적용된다는 사실만으로는 dependency가 아니다.
- 계속할 work의 유효성과 완료 상태가 blocked requirement의 성공을 전제로 하지 않는다.
- 독립 evidence chain과 독립 acceptance를 완성할 수 있다.
- 산출과 상태를 분리해 보고할 수 있고, 전체 task·canonical readiness·commit readiness를 완료로 표시하지 않는다.

처리: blocked branch만 fail-closed하고, 독립성이 입증된 범위는 계속할 수 있다. 보고에는 partial / blocked 경계를 그대로 남긴다.

#### `conflict-unit-blocking`

다음 중 하나라도 해당하면 `conflict-unit-blocking`이다.

- blocked branch가 unit의 acceptance condition, shared invariant, owner contract, validation chain에 필요하다.
- 분리 실행하면 같은 artifact 또는 coherence unit의 부분 상태를 완성된 결과처럼 보이게 한다.
- 후속 work가 blocked 결과나 아직 허가되지 않은 revision을 전제로 한다.
- `conflict-isolated` 조건을 충분히 입증할 수 없다.

처리: affected unit 전체의 mutation / execution / completion claim을 중단한다. conflict를 특성화하는 허용된 read-only 점검은 할 수 있지만, 그것으로 blocked work를 진척 또는 완료로 세지 않는다.

### 4. 충돌 집합을 한 번에 드러낸다

둘 이상의 active rule이 양립할 수 없으면 임의의 승자를 고르지 않는다. 모든 applicable rule을 함께 만족하는 행동의 교집합만 허용한다. 적용되는 owner surface와 조항을 모두 식별하고, host의 기존 priority 규칙으로 해소되지 않는 동일 계층 충돌은 하나의 conflict set으로 평탄화해 `conflict-unit-blocking`으로 취급한다. 한 rule의 의미를 다른 rule의 문면으로 재작성하지 않는다.

후보 자신이 향후 promoted된 뒤 다른 rule과 충돌하더라도 자기 우회 권한을 만들지 않는다. 같은 containment/report 흐름으로 보내되, 한 conflict set을 재귀적으로 무한 보고하지 않는다. 이 rule은 conflict를 해결하는 authority가 아니라 revision decision까지 안전하게 운반하는 경로다.

### 5. 최소 stop/report contract

보고는 기본적으로 현재 대화에 인라인으로 남기며, sidecar state / queue / scheduler / hidden registry를 만들지 않는다. 최소 항목은 다음이다.

```text
Rule Conflict Report:
- Applicable rule / owner:
- Conflicting operation or acceptance condition:
- Exact incompatibility:
- Affected scope:
- Dependency classification: conflict-isolated | conflict-unit-blocking
- Compliant alternatives checked:
- Current binding state:
- Work that may continue, if any:
- User decision needed:
```

어떤 필드도 completion claim을 대신하지 않는다. owner-specific rule이나 deployed skill이 더 강한 report contract를 이미 갖고 있으면 그것을 따르며, 이 후보가 그 schema를 복제하지 않는다.

### 6. 사용자 revision gate

보고 뒤 선택지는 다음 세 종류다.

1. 현 rule 안의 compliant alternative로 작업을 다시 범위화한다.
2. blocked work를 포기하거나 별도 batch로 **보류·격리**한다. batch 분리는 permission이 아니며, 그 batch도 current rule이 binding인 상태에서 동일 conflict가 해소되거나 owner revision이 landing하기 전에는 blocked다.
3. 해당 rule owner의 정규 revision 작업을 착수한다.

세 번째 선택은 사용자가 소유·개정할 수 있는 rule surface에 대한 **revision 착수 승인**이지 rule mutation, commit, push, global adoption, activation의 일괄 승인이 아니다. system/developer instruction, platform security, sandbox처럼 그 사용자가 개정할 수 없는 상위 경계의 우회 창구가 아니다. 실제 변경은 owner surface와 적용되는 repository/global mutation gate를 각각 따른다. 이 후보는 adopter에게 source repository의 Design / Plan 문서 절차를 강제하지 않는다.

## Owner interfaces와 contrast

- **각 active rule:** 자기 trigger, safety property, default, exception, validation 의미를 계속 단독 소유한다. 이 후보는 그 의미를 요약하거나 수정하지 않는다.
- **repository-change-safety:** machine-enforced repository invariant, force bypass, git mutation 승인을 계속 소유한다. owner-specific 경로가 containment + disclosure + 필요한 terminal disposition / revision handoff까지 자족적으로 제공할 때만 이 후보가 중복 절차를 추가하지 않는다. stop/disclosure만 있고 revision handoff가 없으면 이 후보는 빠진 handoff만 이어받고 owner schema를 복제하지 않는다.
- **no-background-or-hidden-state:** autonomous/hidden execution과 supervised work의 의미를 계속 소유한다. 특정 mechanism을 허용할지의 정책 판단은 그 rule revision 소관이다.
- **global-file-mutation-boundary:** managed-block과 global/user instruction mutation의 approval/validation을 계속 소유한다.
- **source-repo docs-working-model:** 이 저장소에서 rule을 add/revise하는 planning lifecycle을 소유한다. distributed runtime rule의 의존성은 아니다.
- **review / advisory flows:** correctness verdict나 정책 선호를 제공할 수 있지만 revision 승인 또는 active-rule replacement authority는 갖지 않는다.

## Non-goals / not-this

이 후보는 다음이 아니다.

- rule precedence engine, generic policy arbitration, 또는 모든 문서·의견 충돌의 중재자
- current rule을 자동 약화하거나 사용자 지시를 즉석 exception으로 바꾸는 bypass mechanism
- rule registry, candidate discovery index, backlog, sidecar state machine, queue, hook, daemon, watcher, scheduler
- 특정 rule의 safety property / default / exception을 중앙에서 재정의하는 umbrella owner
- partial work를 전체 완료로 포장하는 진행 허가
- rule 파일을 자동 편집·commit·push·adopt·activate하는 procedure
- canonical review verdict 또는 correctness proof
- source repository의 governance를 모든 adopter에게 강제하는 meta-policy

## Candidate evaluation contract

### promotion evidence

promotion 판단에는 최소한 다음이 필요하다.

- originating case 밖의 active-rule owner에서도 같은 containment/report gap이 나타나거나, 서로 다른 owner의 counterexample에 이 모델이 의미 복제 없이 적용된다.
- `conflict-isolated` 판정이 pre-conflict scope, blocked output 비소비, coherence·state·validation 분리, 독립 evidence/acceptance, status 분리 조건으로 재현 가능하다.
- 같은-tier multi-rule conflict, explicit rule exception, user bypass 요청, machine-enforced invariant, partial-completion 사례에서 instant bypass와 over-stop을 둘 다 막는다.
- terminal wording이 vendor-neutral / public-safe / self-contained하고 source-repo residue를 요구하지 않는다.
- report가 inline-default로 동작하며 hidden state나 autonomous execution을 만들지 않는다.

### discard criteria

다음 중 하나가 확인되면 discard한다.

- 실제 사례가 기존 owner-local rule만으로 모두 자족적으로 닫혀 별도 cross-cutting gap이 없다.
- `conflict-isolated` / `conflict-unit-blocking` 판정이 dependency facts로 안정화되지 않고 정책 선호 또는 결과 맞추기로 변한다.
- 후보가 rule 우선순위, 예외 허가, 일반 정책 arbitration을 소유해야만 작동한다.
- partial continuation이 반복해서 completion laundering 또는 shared-invariant 누락을 만든다.
- runtime 의미가 source repo의 `rule_docs/**`, `docs/**`, glossary, log, review trace에 의존한다.
- hidden queue/state, 자동 mutation, hook/scheduler 같은 별도 mechanism이 필요해진다.
- always-on 인지 비용과 false stop이 owner-local 중복 제거 이득보다 크다.
- vendor-neutral / one-rule-group / public-safe distribution admission을 만족하지 못한다.

### continue criteria

gap은 남지만 promotion 또는 discard 근거가 부족할 때만 continue한다. 그때는 부족한 evidence type과 다음 review-date를 함께 정하며, 단순히 결정을 미루기 위해 continue하지 않는다.

## Counterexample set for review

1. **명시적 owner exception:** rule이 허용한 scoped branch가 있다면 이 후보는 conflict를 선언하지 않고 그 branch를 따른다.
2. **비필수 독립 조사:** blocked mutation과 결과·invariant를 공유하지 않는 read-only 조사만 남으면 `conflict-isolated`일 수 있으나 전체 task 완료는 금지다.
3. **필수 artifact 생성 차단:** acceptance condition이 그 artifact를 요구하면 `conflict-unit-blocking`이며 우회 산출물로 완료 처리하지 않는다.
4. **사용자 bypass 요청:** 원 작업 승인은 exception이 아니다. compliant alternative 또는 rule revision을 별도 선택한다.
5. **동일 계층 두 rule의 모순:** 임의 우선순위를 만들지 않고 affected unit을 멈춘 뒤 두 owner를 함께 surface한다.
6. **machine-enforced repository invariant:** repository-change-safety의 더 구체적인 owner 절차가 우선 적용되며, 이 후보는 중복 force/approval semantics를 만들지 않는다.
7. **‘오래된 규칙’ 주장:** 낡았다는 맥락은 revision 검토 evidence가 될 수 있지만 현재 rule을 자동 비활성화하지 않는다.
8. **부분 결과 재사용:** blocked branch의 assumption이나 output을 다음 unit이 소비하면 `conflict-isolated`가 아니라 `conflict-unit-blocking`이다.
9. **사후 scope 재분할:** 검증이 막힌 뒤 구현과 검증을 별도 unit으로 다시 이름 붙여도, 원 acceptance가 검증을 요구했다면 전체가 `conflict-unit-blocking`이다.
10. **금지된 측정 실험:** revision 필요성을 입증하려는 실험도 현재 rule을 위반하면 실행하지 않고 evidence 부족으로 남긴다.

## Open questions

- originating case 밖에서 독립 rule 필요성을 입증할 최소 cross-owner evidence는 무엇인가. 정적 counterexample만으로 충분한가, 실제 revision 사례가 하나 더 필요한가.
- `conflict-isolated` 조건이 지나치게 보수적이거나 반대로 shared semantic dependency를 놓치는가.
- owner-specific 경로가 containment + disclosure + terminal disposition / revision handoff를 모두 제공하는지, generic rule이 의미·schema를 복제하지 않고 누락된 handoff만 보충하는 기준을 terminal wording에서 얼마나 짧고 재현 가능하게 만들 수 있는가.
- same-tier rule conflict에서 두 owner를 하나의 revision batch로 묶지 않고도 dependency를 정직하게 표현하는 최소 문면은 무엇인가.
- 후보 id와 내부 분류값 `conflict-isolated` / `conflict-unit-blocking`이 incubation 밖 tracked surface에 노출되거나 collision-prone해질 경우 glossary thin pending reservation이 필요한가. 현재 exact token은 이 문서 내부에서만 사용되고 외부 tracked surface와 collision이 없으므로 등록하지 않는다.
- promotion 시 bootstrap trigger를 어떤 action class로 좁혀야 정상적인 rule 해석 질문마다 과도하게 로드되지 않는가.
- promotion 전까지 어떤 evidence가 부족하면 promote가 아니라 continue 또는 discard가 되는지 review-date에서 명시적으로 판정한다.
