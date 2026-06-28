# Spec conformance checklist — docs-working-model lifecycle

> 산출된 `<domain>_spec.md` 가 Spec 정체성(목표 상태 + durable boundary)을 지켰는지 **의미 기준으로** 점검한다. 판정 = "충족/미충족 + 한 줄 evidence". **evidence 는 이 checklist 본문에 축적하지 않는다** — 실행/closeout evidence 는 operator report / closeout report 소관이다.

- [ ] 목표 상태가 **normative 문장**으로 진술되어 있는가(작업 절차·명령 나열이 아니라 "도메인이 무엇인가/무엇이어야 하는가") — 충족/미충족 + evidence 한 줄
- [ ] 목표 상태 + Owner surface 지도만으로 동일 행동의 구현을 재작성할 수 있는 수준인가(reconstructibility) — 충족/미충족 + evidence 한 줄
- [ ] **회차성 내용이 0인가** — candidate-file 목록 / 실행 명령 시퀀스 / staging 절차 / review result / readiness 판정 / 시점성 작업 상태(lifecycle state 절의 compact 표시 제외) — 충족/미충족 + evidence 한 줄
- [ ] Durable boundary 가 **지속 경계**인가(이번 회차가 끝나도 참인가; 회차 통제가 아닌가) — 충족/미충족 + evidence 한 줄
- [ ] Cross-domain 참조가 interface 에 한정되는가(다른 도메인 semantics 재진술 0) — 충족/미충족 + evidence 한 줄
- [ ] `## Lifecycle state` 절이 존재하고 그 marker 가 prelive / sync-required / live 중 **정확히 하나**(bolded `**…**`; plain-prose 언급은 marker 아님)인가 — 충족/미충족 + evidence 한 줄
- [ ] Header 3개 항목이 각 3줄 이내이고, 승인 경계가 문서당 1회만 진술되는가(절마다 반복 0) — 충족/미충족 + evidence 한 줄
- [ ] Plan 일관성: Spec 이 Plan 의 batch boundary 를 위반하지 않는가(위반 시 rewind 표시) — 충족/미충족 + evidence 한 줄
- [ ] stable filename 준수(`<domain>_spec.md`; package-local 형틀명과 혼동 0) + 미치환 채움 표시 0 — 충족/미충족 + evidence 한 줄
