# Closeout absorption checklist — docs-working-model lifecycle

> Design/Plan → Spec closeout 의 흡수·retire 가 끝났는지 점검한다. "있음/없음 + 한 줄 evidence".

- [ ] Spec ↔ 구현 1:1 sync — evidence: ___
- [ ] Design 의 current-bearing 결정이 Spec(또는 올바른 owner surface)에 표현됨 — evidence: ___
- [ ] Plan 의 still-relevant batch/boundary 결정이 Spec(또는 owner)에 표현됨 — evidence: ___
- [ ] Design/Plan 에만 남은 unique live 의미 없음 — evidence: ___
- [ ] inbound references 갱신/제거됨 (4-class sweep dangling 0) — evidence: ___
- [ ] Design/Plan retire(삭제) 가능 — repo lifecycle 삭제이며 별도 archive / `consumed/` 폴더를 쓰지 않음(historical 은 git history) — evidence: ___
- [ ] (해당 시) corrected-state Codex review 로 닫힘 — evidence: ___
