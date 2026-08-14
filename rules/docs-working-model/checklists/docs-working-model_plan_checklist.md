# Plan conformance checklist — docs-working-model lifecycle

> Plan 의미 누락을 찾는 **self-review aid**다. 체크 누락 자체는 blocker가 아니며, blocker에는 underlying rule violation evidence가 필요하다. evidence는 이 본문에 축적하지 않는다.

- [ ] 본문이 **승인 대상 의사결정**으로만 구성되는가 — 조사 로그 / 실행 순서 세부 / candidate-file 작업 목록 / reviewer 질문 목록 0 (분석·분류·reviewer 질문 준비 → Work Packet, 실행 순서 세부·실행 기록 → operator report `log/**` 소관) — 충족/미충족 + evidence 한 줄
- [ ] 승인 owner·승인 대상 결정·하위 추적이 분리되는가 — 이 Plan이 자기 문면을 승인 근거로 쓰지 않고, 하위 산출물에 새 결정이나 승인된 결정의 변경을 넘기지 않는가 — 충족/미충족 + evidence 한 줄
- [ ] 각 batch 가 목적 / scope / hard boundary / validation expectation / review focus 를 **의미 있게** 정의하는가(형식 충족이 아니라 결정이 실제로 내려졌는가) — 충족/미충족 + evidence 한 줄
- [ ] 각 terminal-rule revision은 최종 corrected-state review 전에 actual foreign-Spec thin-interface direct-sync path set과 Plan의 declared `foreign-Spec direct-sync target` path set을 빈 집합까지 정확히 비교하고 그 declaration/reconciliation을 reviewed pre-transaction Plan/current candidate에 포함했는가 — review 뒤 해당 set·declaration·target-relevant meaning이 바뀌면 retirement-only가 아니라 candidate correction/review로 복귀하고, actual set이 비어 있지 않으면 aggregate/dependency mention과 target declaration을 구별하며 누락·stale/false·extra·오지정은 predicate miss로 처리하는가 — 다른 closeout에서 domain-local lifecycle이 0인 affected Spec의 marker disposition을 판정할 때 이 revision이 surviving open 상태이면 declared membership과 current actual membership을 재구성해 정확히 비교하고 재구성 불가·모호·불일치이면 `not retirement-only`로 reconcile/보류 후 재판정하며, 둘 다 참이면 같은 transaction에서 함께 retire하거나 claim을 먼저 제거할 때까지 현재 closeout을 끝내지 않는가 — 충족/미충족 + evidence 한 줄
- [ ] Work Packet 선언이 필요한 batch 마다 3요소(목적 / 흡수 대상 / retire 조건)가 있는가 — 충족/미충족 + evidence 한 줄
- [ ] 상위 Design 의 open decision 각각에 close 지점이 배정되었는가 — 충족/미충족 + evidence 한 줄
- [ ] Design 일관성: Plan 이 Design 의 end-state·경계·결정을 위반하지 않는가(위반 시 rewind 표시) — 충족/미충족 + evidence 한 줄
- [ ] Header 권장 구조가 문서 정체성·결과·비승인 경계를 충분히 전달하고 미치환 채움 표시가 없는가 — 관찰 + evidence 한 줄
