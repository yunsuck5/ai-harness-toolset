# Closeout checklist — docs-working-model lifecycle

> lifecycle closeout(흡수·retire·1:1 sync·gate 보고)이 끝났는지 **의미 기준으로** 점검한다. 판정 = "충족/미충족 + 한 줄 evidence". **evidence 는 이 checklist 본문에 축적하지 않는다** — normative 문장 대응표·검증 결과 등 실제 evidence 는 closeout report / `log/evidence/**` 에 기록하고 여기서는 그 존재만 확인한다.

- [ ] Spec ↔ 구현 1:1 sync — **normative 문장 단위 대응 확인이 evidence 로 기록**되어 있는가(방향 1: Spec 문장→구현 확인 / 방향 2: 구현의 외부 관찰 행동·소유 경계→Spec 문장) — 충족/미충족 + evidence 위치 한 줄
- [ ] Design 의 current-bearing 결정이 Spec(또는 올바른 owner surface)에 표현됨 — 충족/미충족 + evidence 한 줄
- [ ] Plan 의 still-relevant 결정이 Spec(또는 owner)에 표현됨 — 충족/미충족 + evidence 한 줄
- [ ] 이 lifecycle 이 배포 tier(`snippets/rules/`)에 rule 콘텐츠를 landing 했으면(candidate 의 terminal landing 또는 기존 배포 rule 의 revision) — universal-core↔project-residue split 이 수행됐고(배포 rule 본문 = tier 입장 기준 통과분만; 기준 본문 = tier README 소관), 이 changeset 이 다루는 모든 residue(rule 파일로 향하던 콘텐츠의 입장-기준 탈락분, 또는 revision 이 rule 파일에서 추출한 잔존분)가 같은 changeset 에서 재-home(repo-side) 또는 명시 discard(근거 = commit message)로 처분되어 planning-doc retire 전에 완결됐는가(silent drop 0); 배포 tier landing 이 없는 변경(도메인 변경·repo-only tier rule)은 N/A — 충족/미충족 + evidence 한 줄
- [ ] Work Packet 의 current-bearing 내용이 흡수되고 **Work Packet 이 삭제**됨 — 충족/미충족 + evidence 한 줄
- [ ] Design/Plan 에만 남은 unique live 의미 없음 → **retire(삭제) 수행**(archive/`consumed/` 미사용; 보존 = git history) — 충족/미충족 + evidence 한 줄
- [ ] inbound reference 갱신/제거(4-class sweep; 닫힌 backlog ID 의 tombstone 예외 판별 포함) — 충족/미충족 + evidence 한 줄
- [ ] **도메인 변경**이면 `<domain>_backlog.md` 반영(닫힌 행 처리 + `next ID` 단조 증가 유지); **rule_docs/terminal-rule 변경**이면 terminal rule 1:1 reconcile + 그 rule 의 `rule_docs/<id>/<id>_backlog.md` 가 존재하면 rows added/closed/carried 반영 + `next ID` 단조 증가 유지(rule = 자기 자신이 spec-of-record — 별도 `<domain>_spec.md` 없음; Level-2 item 과 일관; backlog 없으면 그 부분만 N/A) — 충족/미충족 + evidence 한 줄
- [ ] **축소 2단 gate 보고** — Level 1(`docs/README.md` + 영향 받은 미이주 orientation 표면)과 Level 2 의 모든 표면에 `updated:` 또는 `checked: — no change required` 가 기록됨(조용한 생략 0). Level 2 surface 는 변경 종류로 결정된다: 도메인 변경이면 domain spec/backlog; **rule_docs/terminal-rule 변경이면 terminal rule 파일 자체**(`rules/<id>/<id>.md`, flat `rules/<id>.md`, 또는 `snippets/rules/<id>.md`)를 1:1 reconcile 로 보고하고, 그 rule 의 `rule_docs/<id>/<id>_backlog.md` 가 존재하면 함께 보고(rule 은 별도 `<domain>_spec.md` 가 없다) — 충족/미충족 + evidence 한 줄
- [ ] **규칙 자기개정(lifecycle/governance 조항 변경)** 이면 그 self-revision 의 governing version(개정-전 텍스트가 changeset 자기 closeout 까지 지배 — *Self-amendment — transitional applicability* 조항)이 선언됐는가; 자기개정 아니면 N/A — 충족/미충족 + evidence 한 줄
- [ ] **rule 본문이 form-bound 진술을 변경**했으면(Spec-identity 열거·lifecycle-marker·rule-output 형태·artifact content-boundary·checklist 의무·backlog 구조 불변식·rule_docs purity/naming·E1–E3/EN-2), 그 rule 의 package implementation surfaces(forms = templates/·checklists/ + validation = check script·tests)가 같은 changeset 에서 정합화되어 `updated`/`checked — no change required` 로 보고됐는가(spec-template 8-section + 3-marker 구조검사 = 즉시-binding); form-bound 진술 미변경이면 N/A — 충족/미충족 + evidence 한 줄
- [ ] corrected-state Codex review 로 닫힘(verdict 는 commit/push 승인 아님) — 충족/미충족 + evidence 한 줄
