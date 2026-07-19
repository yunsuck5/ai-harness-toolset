# Promotion checklist — docs-working-model lifecycle

> Design 진입 이후 promotion/discard/withdrawal의 의미 누락을 찾는 **self-review aid**다. Incubation 문서 자체에 review gate를 소급 적용하지 않는다. 체크 누락 자체는 blocker가 아니며, blocker에는 underlying E1–E3·absorption·authority violation evidence가 필요하다.

- [ ] **E1:** candidate/prelive 상태를 live·closeout-verified authority로 소비하지 않았는가(runtime dogfood는 그 자체로 authority가 아님) — 관찰 + evidence 한 줄
- [ ] **E2:** canonical surface가 `_incubation.md` 경로/content를 durable input으로 소비하지 않고, 필요한 current-bearing idea가 promoted artifact에 자족적으로 흡수됐는가 — 관찰 + evidence 한 줄
- [ ] **E3:** promotion changeset이 `_incubation` 제거/rename과 entry `_design` 생성을 함께 수행하며, incubation 중 `_design`/`_plan`/`_spec` sibling 또는 canonical default가 없었는가 — 관찰 + evidence 한 줄
- [ ] Design이 candidate identity와 실제로 살아남은 current-bearing idea를 의미 보존해 흡수했는가(raw log·abandoned thought·고정 evidence-field 운반은 요구하지 않음) — 관찰 + evidence 한 줄
- [ ] current-correctness blocker는 해결되고, not-yet-started future work는 owner backlog가 존재하는 시점에 reopen condition과 함께 이관됐는가 — 관찰 + evidence 한 줄
- [ ] discard면 `_incubation.md`가 삭제되고, rule candidate면 빈 `rule_docs/<candidate>/` 폴더도 제거됐는가 — 관찰 + evidence 한 줄
- [ ] withdrawal이면 stale해진 promoted status/reference만 정정하고 promoted artifacts를 처분한 뒤 `_incubation`을 기록된 방식으로 재개했는가; live artifact에는 withdrawal을 사용하지 않았는가 — 관찰 + evidence 한 줄
- [ ] name-only candidate mention이 있다면 non-authoritative candidate 상태를 정직하게 표시하고 discovery index나 foreign-semantics copy가 되지 않는가 — 관찰 + evidence 한 줄
- [ ] 새 project-wide term/meaning change/name collision/rejected-term revival이라는 glossary trigger가 실제로 발생했는지 별도로 판단했는가 — 관찰 + evidence 한 줄
