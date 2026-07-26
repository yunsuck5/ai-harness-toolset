# Closeout checklist — docs-working-model lifecycle

> closeout 의미 누락을 찾는 **self-review aid**다. 체크 누락 자체는 blocker가 아니며, blocker에는 underlying closeout rule violation evidence가 필요하다. listed surface의 inspect/report는 anti-omission 경계로 계속 무조건 수행한다. evidence는 이 본문에 축적하지 않는다.

- [ ] Spec/rule ↔ 구현 meaning-level sync — durable target-state behavior/owner → 구현, 구현의 외부 관찰 behavior/owner → target-state 의미가 양방향으로 확인됐는가(literal 문장/코드 대응 아님). Terminal rule 전체 처분이면 승인된 부재/replacement target과 실제 old terminal·전용 source enforcement/discovery·planning/backlog residue의 부재, retained meaning의 destination owner를 대조했는가 — 관찰 + evidence 위치 한 줄
- [ ] Design 의 current-bearing 결정이 Spec(또는 올바른 owner surface)에 표현됨 — 충족/미충족 + evidence 한 줄
- [ ] Plan 의 still-relevant 결정이 Spec(또는 owner)에 표현됨 — 충족/미충족 + evidence 한 줄
- [ ] 배포 tier(`snippets/rules/`) rule 작업이면 tier admission 또는 affected index/source-disposition owner를 따르고, lifecycle이 다룬 project residue가 repo-side로 re-home되거나 명시 discard되어 planning-doc 삭제 때 silent loss가 없는가; 해당 없으면 N/A — 관찰 + evidence 한 줄
- [ ] Work Packet 의 current-bearing 내용이 흡수되고 **Work Packet 이 삭제**됨 — 충족/미충족 + evidence 한 줄
- [ ] Design/Plan 에만 남은 unique live 의미 없음 → **retire(삭제) 수행**(archive/`consumed/` 미사용; 보존 = git history) — 충족/미충족 + evidence 한 줄
- [ ] 실제로 stale해지는 inbound reference가 갱신/제거됐는가(무차별 sweep이 아니라 영향 reference 기준; 닫힌 backlog ID tombstone 예외 포함) — 관찰 + evidence 한 줄
- [ ] **도메인 변경**이면 `<domain>_backlog.md` 반영(닫힌 행 처리 + `next ID` 단조 증가 유지); **identity·placement 를 유지하는 terminal-rule 변경**이면 terminal rule 1:1 reconcile + existing `rule_docs/<id>/<id>_backlog.md` rows/floor 반영; **같은 identity의 placement 변경**이면 old source placement·tier route 처분, new placement admission/discovery, existing backlog identity, distributed runtime 후속을 함께 보고; **terminal rule 전체 retire/replacement**이면 old terminal, backlog/idle folder, 전용 source enforcement/discovery, 실제 stale reference의 제거·이관과 retained future work의 destination owner를 함께 보고(rule = 자기 자신이 spec-of-record — 별도 `<domain>_spec.md` 없음) — 충족/미충족 + evidence 한 줄
- [ ] **Rule lifecycle 공통 terminal** — entry와 governing text를 재구성하고, 영향받은 원 작업마다 새 owner interface의 `resume` 또는 명시적 `drop`/`rescope` terminal을 확인했는가(영향 작업이 없으면 N/A) — 관찰 + evidence 한 줄
- [ ] **축소 2단 gate 보고** — Level 1(`docs/README.md` + 영향 받은 미이주 orientation 표면)과 Level 2 의 모든 표면에 `updated:` 또는 `checked: — no change required` 가 기록됨(조용한 생략 0). Level 2 surface 는 변경 종류로 결정된다: 도메인 변경이면 domain spec/backlog; identity·placement 를 유지하는 rule 변경이면 terminal rule 파일 자체(`rules/<id>/<id>.md`, flat `rules/<id>.md`, 또는 `snippets/rules/<id>.md`)와 existing backlog; 같은 identity의 placement 변경이면 old/new terminal placement와 affected tier route/runtime 후속; terminal rule 전체 retire/replacement이면 old terminal identity의 source disposition과 replacement/destination owner를 old file 부재를 포함해 보고한다 — 충족/미충족 + evidence 한 줄
- [ ] **규칙 자기개정**이면 개정 전 텍스트가 자기 closeout까지 지배한다는 governing version과, 이미 적용되던 pre-amendment structural check 결과가 기록됐는가; 자기개정 아니면 N/A — 관찰 + evidence 한 줄
- [ ] rule 본문의 form-bound 의미가 바뀌었으면 이를 직접 embody/enforce하는 forms/checker/tests만 같은 changeset에서 정합화하고 파일별 `updated`/`checked — no change required`를 보고했는가(키워드 유사성은 dependency가 아니며 8-heading은 diagnostic) — 관찰 + evidence 한 줄
- [ ] corrected-state review가 필요한 단계이면 수행됐는가(verdict는 commit/push 승인 아님; `_incubation.md` 자체는 review carve-out) — 관찰 + evidence 한 줄
