# Work Packet conformance checklist — docs-working-model lifecycle

> 산출된 `<domain>_work_packet.md` / `<id>_work_packet.md` 가 Work Packet 역할(회차성 작업 문서)을 지켰는지 **의미 기준으로** 점검한다 — *이 파일 자체의 content boundary* 만 본다(Plan 의 WP 선언·closeout 의 WP 흡수/삭제·promotion 의 E4 흡수는 각자의 checklist 소관이며 여기서 중복하지 않는다). 판정 = "충족/미충족 + 한 줄 evidence". **evidence 는 이 checklist 본문에 축적하지 않는다** — operator report / closeout report 소관.

- [ ] **금지 content 0** — 실행 command sequence·staging 절차·review 결과·validation 결과·readiness 판정이 없는가(이들은 실행 mechanics/기록 → operator report `log/**`, 또는 미기록) — 충족/미충족 + evidence 한 줄
- [ ] **회차성 작업 content 만** — line-level reference 분류·조사/구현 노트·evidence 제안·reviewer 질문 준비·edge-case 노트로 구성되는가 — 충족/미충족 + evidence 한 줄
- [ ] **승급 대상·normative 텍스트 0** — approval-target 결정(→ Plan)·durable target-state/normative rule wording(→ Spec/terminal rule)이 WP 에 들어있지 않은가 — 충족/미충족 + evidence 한 줄
- [ ] **non-authoritative·non-live** — 승인 대상도, live 도메인 문서도, Spec 대체도 아님이 유지되는가(승인 경계 1회 진술; 미치환 채움 표시 0) — 충족/미충족 + evidence 한 줄
