# docs-working-model — late finding containment and resume Design

> 이 문서는 existing `docs-working-model` 규칙에 late finding의 owner routing, cross-owner handoff, 최소 rewind·resume 결과를 보강하는 임시 Design이다. 이 문서는 새 정책 owner, 중앙 registry, 실제 foreign-owner mutation, mutation/commit/push 승인이 아니며 closeout에서 삭제된다.

## 왜 바꾸는가 / 무엇을 바꾸는가

현재 DWM은 Proportionality, Stage rewind, State migration, domain-local closure, Self-amendment를 이미 소유한다. Distributed `rule-conflict-and-revision-routing` rule은 concrete required operation과 active rule의 실제 양립 불가능을 별도로 소유한다. 그러나 실행 중 뒤늦게 발견한 policy·owner·safety 사실을 이 owner들 중 어디로 보낼지, foreign-owner finding이 현재 작업을 언제 막는지, rewind 뒤 무엇을 무효화하고 어디서 재개할지를 한 번에 판별할 최소 interface가 없다.

이번 변경은 기존 owner를 보존하면서 다음 공백만 닫는다.

- inactive policy, owner-local current defect, foreign-owner finding, actual active-rule conflict, explicit user target change, concrete safety risk, unknown owner를 구분하고 controlling existing owner/route를 정한다. Evidence handoff 같은 보조 transport는 병존할 수 있지만 새 authority를 만들지 않는다.
- cross-owner finding은 재현 가능한 evidence handoff일 뿐 foreign mutation·priority·completion 권한이 아님을 명시한다.
- source 작업은 target owner의 변경이 없어도 source correctness가 독립적으로 성립한다는 evidence가 있을 때만 닫는다. Handoff 수신은 target completion이 아니다.
- Stage rewind 결과에 affected owner/stage, invalidated output와 정확한 dependency, preserved material의 비권위 상태, resume point와 필요한 user/owner decision을 남긴다.
- forward correction은 dependency로 stale해진 current pointer·status·acceptance claim에만 적용하고 Git history·고정 hash 인용·완료 시점 evidence는 다시 쓰지 않는다.

## Owner surface model

- `rules/docs-working-model/docs-working-model.md`: late finding의 최소 selector/result, owner-local routing/lifecycle, cross-owner evidence transport, affected slice의 rewind·resume와 forward correction
- `rules/docs-working-model/checklists/docs-working-model_closeout_checklist.md`: 실제 late finding/rewind가 있었을 때만 결과 누락을 확인하는 N/A 가능 direct form
- `snippets/rules/rule-conflict-and-revision-routing.md`: concrete required operation과 branch-local binding active rule의 실제 비양립, compliant path 부재, conflict disclosure·containment
- `rules/rule-authority.md`: rule claim의 authority classification과 revise·retire·remove disposition
- 각 foreign owner: 전달받은 finding의 pending, inspect 결과, backlog+reopen condition, owner-local revision 또는 reject disposition과 그 근거
- 각 relevant safety owner: concrete safety risk의 stop·repair 경계
- DWM `State migration`·`Self-amendment`: carried material의 비권위 상태와 introducing changeset의 pre-revision governance
- current work item 또는 `<ProjectRoot>/log/**` operator/closeout report: selector·handoff·rewind의 point-in-time evidence와 status. Checklist는 이를 확인할 뿐 evidence를 저장하지 않는다.

## 수정 대상

- `rules/docs-working-model/docs-working-model.md`
- `rules/docs-working-model/checklists/docs-working-model_closeout_checklist.md`

Distributed conflict rule, `rules/rule-authority.md`, DWM State migration·Self-amendment, Design/Plan/Spec templates와 checklists, checker/tests, DWM backlog는 직접 dependency나 미해결 future work가 생길 때만 수정한다.

## 하지 않을 것 (non-goals)

- 모든 finding을 담는 permanent schema, registry, sidecar, decision ledger, routing daemon을 만들지 않는다.
- inactive policy나 ordinary foreign-owner finding을 current authority 또는 자동 blocker로 승격하지 않는다. Concrete safety stop과 admission을 충족한 actual active conflict의 containment는 ordinary continuation보다 우선한다.
- 실제 active conflict의 containment schema를 DWM에 복제하거나 예상 충돌을 이유로 rule을 선제 수정·삭제하지 않는다.
- 같은 physical file, 다른 owner 이름, 다른 role slot만으로 dependency 또는 independence를 단정하지 않는다.
- target owner의 수신을 completion으로, source closeout을 foreign-owner closeout으로 확대하지 않는다.
- actual foreign owner, global/user file, deployed runtime을 이 changeset에서 수정하지 않는다.
- 역사적 evidence, fixed-hash citation, 완료된 point-in-time 기록을 current-state correction 명목으로 다시 쓰지 않는다.

## Plan readiness / open risks

방향 결정은 닫혔으며 Plan으로 진행할 수 있다.

- B04에서 관측된 것은 DWM의 contract 공백이며, 현재 작업과 active rule의 실제 비양립은 없다. Conflict owner revision을 열지 않는다.
- DWM 안에 existing State migration·Self-amendment 의미가 있으므로 새 state나 소급 규칙을 만들지 않고 thin pointer로 소비한다.
- actual late finding/rewind 사례가 없어 contract-only로 검증한다. Dummy foreign owner나 conflict를 만들지 않는다.
- semantic dependency와 independence는 generic checker로 완전 기계화하지 않는다.
- Work Packet은 만들지 않는다. 수정 파일 두 개와 owner·route·resume 결정이 이 Design/Plan에서 line-level로 닫혀 별도 implementation inventory가 필요하지 않다.
- governance self-revision closeout까지는 `74081f85992b1d26493c0922f371c8a9f72d3397`의 DWM이 지배한다.
