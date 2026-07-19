# Design conformance checklist — docs-working-model lifecycle

> Design 의미 누락을 찾는 **self-review aid**다. 체크 누락 자체는 blocker가 아니며, blocker에는 underlying rule violation evidence가 필요하다. evidence는 이 본문에 축적하지 않는다.

- [ ] 왜/무엇을 바꾸는가가 **결정**으로 진술되는가(현행 live Spec·구현의 어떤 문제를 푸는지가 드러나는가) — 충족/미충족 + evidence 한 줄
- [ ] Owner surface model 이 의미 있게 정의되는가(rules 가 behavior 를 흡수하지 않는 경계 포함) — 충족/미충족 + evidence 한 줄
- [ ] Non-goals 가 실질적인가(rejected terms/domains 부활 · broad cleanup · scope creep 차단) — 충족/미충족 + evidence 한 줄
- [ ] 수정 대상이 기존 live Spec·구현·구조물을 특정하는가 — 충족/미충족 + evidence 한 줄
- [ ] Plan readiness 판단과 open risk 목록(각각의 close 예정지 포함)이 있는가 — 충족/미충족 + evidence 한 줄
- [ ] 회차성 내용 0(작업 로그 / review result / 시점성 상태) — 충족/미충족 + evidence 한 줄
- [ ] Detail 이 Design altitude 를 넘지 않는가 — 제외(lower-grade) 0: round/line-level 분석·execution sequence/staging/mechanics·exhaustive enumeration/inventory·final normative(MUST/forbid) wording(각자 WP/Spec/log 로 흐른다); 허용(decision-grade): semantic target·conceptual model·trade-off·ownership boundary·deciding target-state invariant·decision-critical identifier/interface 명·closed enum/taxonomy(그 taxonomy 자체가 결정일 때)·대표/경계 예시 — 충족/미충족 + evidence 한 줄
- [ ] Header 권장 구조가 문서 정체성·결과·비승인 경계를 충분히 전달하고 미치환 채움 표시가 없는가 — 관찰 + evidence 한 줄
