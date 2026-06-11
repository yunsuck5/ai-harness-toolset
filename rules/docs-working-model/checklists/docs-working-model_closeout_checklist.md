# Closeout checklist — docs-working-model lifecycle

> lifecycle closeout(흡수·retire·1:1 sync·gate 보고)이 끝났는지 **의미 기준으로** 점검한다. 판정 = "충족/미충족 + 한 줄 evidence". **evidence 는 이 checklist 본문에 축적하지 않는다** — normative 문장 대응표·검증 결과 등 실제 evidence 는 closeout report / `log/evidence/**` 에 기록하고 여기서는 그 존재만 확인한다.

- [ ] Spec ↔ 구현 1:1 sync — **normative 문장 단위 대응 확인이 evidence 로 기록**되어 있는가(방향 1: Spec 문장→구현 확인 / 방향 2: 구현의 외부 관찰 행동·소유 경계→Spec 문장) — 충족/미충족 + evidence 위치 한 줄
- [ ] Design 의 current-bearing 결정이 Spec(또는 올바른 owner surface)에 표현됨 — 충족/미충족 + evidence 한 줄
- [ ] Plan 의 still-relevant 결정이 Spec(또는 owner)에 표현됨 — 충족/미충족 + evidence 한 줄
- [ ] Work Packet 의 current-bearing 내용이 흡수되고 **Work Packet 이 삭제**됨 — 충족/미충족 + evidence 한 줄
- [ ] Design/Plan 에만 남은 unique live 의미 없음 → **retire(삭제) 수행**(archive/`consumed/` 미사용; 보존 = git history) — 충족/미충족 + evidence 한 줄
- [ ] inbound reference 갱신/제거(4-class sweep; 닫힌 backlog ID 의 tombstone 예외 판별 포함) — 충족/미충족 + evidence 한 줄
- [ ] `<domain>_backlog.md` 반영(닫힌 행 처리 + `next ID` 단조 증가 유지) — 충족/미충족 + evidence 한 줄
- [ ] **축소 2단 gate 보고** — Level 1(`docs/README.md` + 영향 받은 미이주 orientation 표면)과 Level 2(domain spec/backlog) 의 모든 표면에 `updated:` 또는 `checked: — no change required` 가 기록됨(조용한 생략 0) — 충족/미충족 + evidence 한 줄
- [ ] corrected-state Codex review 로 닫힘(verdict 는 commit/push 승인 아님) — 충족/미충족 + evidence 한 줄
