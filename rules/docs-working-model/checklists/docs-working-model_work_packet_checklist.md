# Work Packet conformance checklist — docs-working-model lifecycle

> Work Packet 역할 누락을 찾는 **self-review aid**다. 체크 누락 자체는 blocker가 아니며, blocker에는 underlying role/authority/content-boundary violation evidence가 필요하다. Incubation은 별도 Work Packet을 만들지 않는다. evidence는 이 본문에 축적하지 않는다.

- [ ] **금지 content 0** — 실행 command sequence·staging 절차·review 결과·validation 결과·readiness 판정이 없는가(이들은 실행 mechanics/기록 → operator report `log/**`, 또는 미기록) — 충족/미충족 + evidence 한 줄
- [ ] **회차성 작업 content 만** — line-level reference 분류·조사/구현 노트·evidence 제안·reviewer 질문 준비·edge-case 노트로 구성되는가 — 충족/미충족 + evidence 한 줄
- [ ] **승급 대상·normative 텍스트 0** — approval-target 결정(→ Plan)·durable target-state/normative rule wording(→ Spec/terminal rule)이 WP 에 들어있지 않은가 — 충족/미충족 + evidence 한 줄
- [ ] **승인 추적만 허용** — 승인 owner와 이미 승인된 결정을 가리킬 수는 있지만, 새 결정을 만들거나 승인된 결정을 바꾸거나 WP 자신을 승인 근거로 쓰지 않는가 — 충족/미충족 + evidence 한 줄
- [ ] **non-authoritative·non-live** — 승인 대상도, live 도메인 문서도, Spec 대체도 아님이 유지되는가(승인 경계 1회 진술; 미치환 채움 표시 0) — 충족/미충족 + evidence 한 줄
