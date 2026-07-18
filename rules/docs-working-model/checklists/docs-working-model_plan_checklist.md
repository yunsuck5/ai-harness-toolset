# Plan conformance checklist — docs-working-model lifecycle

> 산출된 `<domain>_plan.md` 가 Plan 정체성(승인 대상 의사결정만)을 지켰는지 **의미 기준으로** 점검한다. 판정 = "충족/미충족 + 한 줄 evidence". **evidence 는 이 checklist 본문에 축적하지 않는다** — operator report / closeout report 소관.

- [ ] 본문이 **승인 대상 의사결정**으로만 구성되는가 — 조사 로그 / 실행 순서 세부 / candidate-file 작업 목록 / reviewer 질문 목록 0 (분석·분류·reviewer 질문 준비 → Work Packet, 실행 순서 세부·실행 기록 → operator report `log/**` 소관) — 충족/미충족 + evidence 한 줄
- [ ] 승인 owner·승인 대상 결정·하위 추적이 분리되는가 — 이 Plan이 자기 문면을 승인 근거로 쓰지 않고, 하위 산출물에 새 결정이나 승인된 결정의 변경을 넘기지 않는가 — 충족/미충족 + evidence 한 줄
- [ ] 각 batch 가 목적 / scope / hard boundary / validation expectation / review focus 를 **의미 있게** 정의하는가(형식 충족이 아니라 결정이 실제로 내려졌는가) — 충족/미충족 + evidence 한 줄
- [ ] Work Packet 선언이 필요한 batch 마다 3요소(목적 / 흡수 대상 / retire 조건)가 있는가 — 충족/미충족 + evidence 한 줄
- [ ] 상위 Design 의 open decision 각각에 close 지점이 배정되었는가 — 충족/미충족 + evidence 한 줄
- [ ] Design 일관성: Plan 이 Design 의 end-state·경계·결정을 위반하지 않는가(위반 시 rewind 표시) — 충족/미충족 + evidence 한 줄
- [ ] Header 3개 항목 각 3줄 이내 + 승인 경계 1회 진술 + 미치환 채움 표시 0 — 충족/미충족 + evidence 한 줄
