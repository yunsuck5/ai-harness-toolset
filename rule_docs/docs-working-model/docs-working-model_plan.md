# docs-working-model — late finding containment and resume Plan

> 이 문서는 existing DWM rule revision의 승인 대상 Plan이다. 실행 중 late finding을 기존 owner로 route하고, cross-owner handoff와 minimum-affected rewind·resume 결과를 닫는다. 실행 기록은 담지 않으며 closeout에서 삭제된다.

## Batch 순서와 의존

1. **Late-finding selector**
   - exact finding, active/inactive 상태, affected operation·decision, current-correctness dependency, existing owner를 식별한다.
   - inactive policy, owner-local defect, foreign-owner finding, actual active conflict, explicit user target change, concrete safety risk, unknown owner를 구분해 controlling existing owner/route를 정한다. 보조 evidence transport는 새 authority 없이 병존할 수 있다.
2. **Cross-owner handoff**
   - source owner가 target owner에게 전달할 최소 evidence와 requested target action을 정의한다.
   - target receipt와 completion, source closure와 target closure, joint changeset과 independent continuation을 분리한다.
3. **Rewind, resume, forward correction**
   - explicit target change와 late finding이 무효화한 dependency-proven slice만 rewind한다.
   - preserved material의 비권위 상태, resume point, 필요한 user/owner decision과 정확한 forward-correction 범위를 남긴다.
4. **Form alignment and closeout**
   - 직접 form 한 항목을 정렬하고 template/checker/test·backlog의 no-change 근거를 재검증한 뒤 Design/Plan을 삭제한다.

## Batch 정의

### Late-finding selector

- 목적: 뒤늦게 발견한 사실을 결론이나 새 authority로 소비하기 전에 exact existing owner와 현재 작업 영향으로 분류한다.
- scope: DWM의 compact selector/result contract.
- hard boundary: permanent schema·registry·새 lifecycle state·inactive authority 승격 금지.
- validation expectation: 겹치는 finding class에도 controlling route를 하나 정하고 필요한 보조 evidence transport만 병존시키는 반례 대조. Inactive backlog/incubation, owner-local correction, evidence handoff, conflict containment, Stage rewind, safety stop/repair, user clarification을 ordinary continuation 우선순위와 함께 구분한다.
- review focus: 예상 충돌과 actual conflict, 일반 품질 finding과 concrete safety risk, unknown owner와 broad owner invention의 혼동.
- Work Packet: 없음.

### Cross-owner handoff

- 목적: foreign-owner finding을 evidence-bound transport로 제한하면서 source의 current correctness와 target disposition을 독립적으로 닫는다.
- scope: source owner, target owner, reproducible evidence, affected stable interface, source current impact, requested target action, target의 실제 disposition/status와 근거, independence basis.
- hard boundary: foreign mutation·priority·completion 승인, target receipt의 completion 승격, shared file을 dependency/independence proof로 사용 금지.
- validation expectation: target change 불필요·필요, future nonblocking·active correction, shared physical file의 coupled·independent 반례를 대조.
- review focus: source가 target correction 없이도 current-correct함을 입증했는지, target owner가 inspect/backlog/owner-local revision/reject 중 자기 disposition을 소유하는지.
- Work Packet: 없음.

### Rewind, resume, forward correction

- 목적: late finding이나 explicit target change 뒤 affected work만 멈추고 stale output을 재사용하지 않으며 재개 조건을 명확히 한다.
- scope: DWM Stage rewind와 existing State migration·Self-amendment의 thin reuse.
- hard boundary: owner/role-slot 차이만으로 independent 판정, unaffected work의 broad rewind, history rewriting, introducing changeset에 새 rule 소급 금지.
- validation expectation: 최소 affected owner/stage, invalidated output+exact dependency, non-authoritative preserved material, resume point+needed decision 네 결과와 independence basis·stale correction range를 scenario로 대조.
- review focus: dependency-proven affected slice, active conflict 발생 시 conflict owner로의 전환, current pointer와 historical evidence의 구분.
- Work Packet: 없음.

### Form alignment and closeout

- 목적: 새 result interface의 omission-detection form만 직접 정렬하고 contract-only 완료 범위를 정직하게 남긴다.
- scope: DWM 본문, closeout checklist, planning artifacts.
- hard boundary: dummy finding/conflict/foreign mutation, semantic checker 과장, 미해결 work가 없는 backlog row 생성 금지.
- validation expectation: DWM checker, affected Pester, full Pester, corrected-state review, two-level closeout.
- review focus: conflict/rule-authority/State migration/Self-amendment 중복, N/A 가능 form, planning residue.
- Work Packet: 없음.

## Open decision의 close 지점

- selector 입력은 exact finding, known owner와 active/inactive 상태, affected operation·decision, current-correctness dependency다. 결과는 controlling route, 병존하는 보조 transport, current work의 continue/stop/rewind 상태, 필요한 user/owner decision이다.
- 고정 priority engine을 만들지 않고 다음 bounded 순서로 중첩을 푼다. Concrete safety risk이면 relevant safety owner가 즉시 stop/repair를 소유한다. Explicit user target change이면 changed target에 의존하는 work를 Stage rewind한다. Concrete required operation과 applicable active rule이 실제로 양립 불가능하고 compliant path가 없다는 admission을 충족하면 conflict owner로 전환한다. 그 밖의 owner-local current defect는 Proportionality 또는 owner-local revision, ordinary foreign-owner finding은 evidence handoff, inactive policy는 approved backlog/incubation으로 보낸다. Unknown owner는 terminal route가 아니라 clarification 뒤 이 selector로 재분류한다. Safety repair나 target change가 나중에 actual conflict admission을 충족해도 같은 전환을 사용한다.
- inactive policy는 current authority나 blocker가 아니며 approved owner backlog/incubation으로만 보낸다. Owner-local current defect는 Proportionality 또는 해당 owner revision을 사용한다.
- foreign-owner finding은 source owner·target owner·재현 evidence·affected stable interface·source current impact·requested target action(`inspect`, backlog 검토 또는 owner-local revision 검토)·target의 실제 disposition/status와 근거·independence basis를 필요한 만큼 남긴다. Target status는 pending, inspect 결과, backlogged+reopen condition, revision entry 또는 reject 중 실제 상태를 보고하며, receipt-only는 `pending, target incomplete`다. 이는 고정 schema가 아니다.
- actual active-rule conflict는 distributed conflict rule을 그대로 소비한다. Concrete safety risk는 relevant safety owner의 stop/repair를 따른다. Owner를 알 수 없으면 사용자가 정할 때까지 broad owner를 만들지 않는다.
- source closeout은 target change가 source correctness에 필요하지 않다는 evidence가 있을 때만 가능하다. Target change가 필요하고 actual conflict admission이 없다면 target lifecycle, dependency/commit order와 owner-local review가 terminal을 충족할 때까지 source도 affected 상태다. Actual conflict이면 conflict owner의 dependency classification을 그대로 소비한다. `conflict-isolated`은 독립 evidence가 있는 해당 source unit만 계속·close할 수 있고, `conflict-unit-blocking`은 compatible active states 또는 명시적 drop/rescope terminal 전까지 close할 수 없다. Containment transport 자체는 completion evidence가 아니다.
- Stage rewind 결과는 affected owner/stage, invalidated output와 exact dependency, non-authoritative preserved material, resume point와 필요한 user/owner decision을 남긴다. 다른 owner/role-slot이라는 사실만으로 계속 진행하지 않고 dependency absence를 입증한다.
- forward correction은 실제로 stale해진 current pointer·status·acceptance claim만 고친다. Git history, fixed-hash citation, 완료 당시 유효했던 point-in-time evidence는 보존한다.
- Selector·handoff·rewind 결과는 실행 중 current work item 또는 `<ProjectRoot>/log/**` operator report에, closeout 시 closeout report에 남긴다. Checklist body는 evidence store가 아니라 누락 확인 form이며 별도 registry·sidecar를 만들지 않는다.
- 새 unresolved future work가 없으므로 DWM backlog를 수정하지 않는다. Templates/checker/tests도 직접 form/check dependency가 없어 no-change로 닫는다.

## Governing version

- Pre-revision governing text는 `74081f85992b1d26493c0922f371c8a9f72d3397`의 `rules/docs-working-model/docs-working-model.md`다.
- 이 문면이 Design 시작부터 implementation closeout 전체를 지배하며, 새 DWM 문면은 이후 work부터 적용한다.
- 기존 DWM checker와 closeout checklist를 pre-amendment structural 기준으로 실행하고 결과를 closeout에 기록한다.

## Stage rewind 조건

- Plan이 새 global owner, fixed schema, permanent registry 또는 새 authority state를 요구하면 Design으로 돌아간다.
- selector가 actual active conflict를 DWM 자체에서 해결하거나 inactive policy를 current authority로 만들면 Plan으로 돌아간다.
- handoff가 foreign mutation·priority·completion을 승인하거나 target receipt를 completion으로 간주하면 Plan으로 돌아간다.
- rewind가 dependency로 영향받지 않은 work를 broad하게 무효화하거나 historical evidence를 다시 쓰면 Plan으로 돌아간다.
- actual foreign-owner·global/user·runtime mutation이 필요해지면 이 generic changeset을 중단하고 해당 owner의 별도 승인 lifecycle로 분리한다.
