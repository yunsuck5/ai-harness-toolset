# Spec conformance checklist — docs-working-model lifecycle

> Spec 의미 누락을 찾는 **self-review aid**다. 체크 누락이나 여덟 heading 형식 이탈 자체는 blocker가 아니며, blocker에는 underlying target-state/owner/boundary/marker violation evidence가 필요하다. evidence는 이 본문에 축적하지 않는다.

- [ ] 목표 상태가 **normative 문장**으로 진술되어 있는가(작업 절차·명령 나열이 아니라 "도메인이 무엇인가/무엇이어야 하는가") — 충족/미충족 + evidence 한 줄
- [ ] 목표 상태와 Owner surface 지도가 externally observable behavior·owner 의미를 복원할 만큼 충분한가(reconstructibility는 review aid, literal 문장/코드 대응 아님) — 관찰 + evidence 한 줄
- [ ] **회차성 내용이 0인가** — candidate-file 목록 / 실행 명령 시퀀스 / staging 절차 / review result / readiness 판정 / 시점성 작업 상태(lifecycle state 절의 compact 표시 제외) — 충족/미충족 + evidence 한 줄
- [ ] Durable boundary 가 **지속 경계**인가(이번 회차가 끝나도 참인가; 회차 통제가 아닌가) — 충족/미충족 + evidence 한 줄
- [ ] Cross-domain 참조가 interface 에 한정되는가(다른 도메인 semantics 재진술 0) — 충족/미충족 + evidence 한 줄
- [ ] `## Lifecycle state` 절이 존재하고 그 marker 가 prelive / sync-required / live 중 **정확히 하나**(bolded `**…**`; plain-prose 언급은 marker 아님)인가 — 충족/미충족 + evidence 한 줄
- [ ] Header가 문서 정체성·결과·비승인 경계를 충분히 전달하며 승인 경계를 반복하지 않는가 — 관찰 + evidence 한 줄
- [ ] Plan 일관성: Spec 이 Plan 의 batch boundary 를 위반하지 않는가(위반 시 rewind 표시) — 충족/미충족 + evidence 한 줄
- [ ] 권장 stable filename과 package-local 형틀 구분이 명확하고 미치환 채움 표시가 없는가 — 관찰 + evidence 한 줄
