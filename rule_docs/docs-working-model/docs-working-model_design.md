# docs-working-model — live rule lifecycle Design

> 이 문서는 기존 `docs-working-model` 규칙의 whole-rule retire/replacement와 distributed projection을 보강하는 임시 Design이다. 이 체인이 끝나면 기존 add/change 경로를 보존하면서 terminal rule 부재 상태와 재개 지점을 owner-local하게 재구성할 수 있다. 이 문서는 live 규칙, 실제 rule 처분, mutation/commit/push 승인이 아니며 closeout에서 삭제된다.

## 왜 바꾸는가 / 무엇을 바꾸는가

현행 rule lifecycle은 candidate 추가와 terminal rule 변경·closeout을 실제로 지원한다. `rule-authority`도 clause × scope × enforcement 처분과 claim 변경 시 owner/enforcement 동기화를 요구한다. 그러나 DWM은 live artifact를 이름뿐인 “normal repeal/supersede lifecycle”로 보내고, whole terminal identity가 없어지는 경우의 entry, retained meaning 흡수, source surface 처분, terminal, resume를 정의하지 않는다.

이번 변경은 이 공백만 닫는다.

- 기존 incubation → Design → Plan → terminal rule → closeout의 add/change 경로를 유지한다.
- clause 처분과 whole-rule 처분을 구분하되 clause taxonomy는 `rule-authority`에 남긴다.
- whole-rule retire/replacement는 exact identity와 placement, retained/removed meaning, direct source dependency, backlog/planning home, stale inbound reference, terminal/resume를 owner-local lifecycle에서 함께 닫는다.
- distributed rule은 source terminal과 index/trigger projection을 source-side에서 닫되 installed payload와 activation을 별도 owner 상태로 남긴다.
- 실제 안전한 retire 대상이 없으면 계약만 구현하고 실사용을 주장하지 않는다.

## Owner surface model

- `rules/docs-working-model/docs-working-model.md`는 Design/Plan/terminal-rule lifecycle, owner absorption, planning/backlog 처분, closeout, state migration과 source-side terminal/resume를 소유한다.
- `rules/rule-authority.md`는 clause × scope × enforcement 권위 판정과 사용자 처분을 계속 소유하고, artifact·distribution 절차를 복제하지 않은 채 DWM lifecycle로 넘긴다.
- 각 terminal rule은 처분이 발효되기 전까지 자기 claim과 scope를 소유한다.
- replacement owner는 retained meaning을 자기 lifecycle과 active surface에서 소유한다. 여러 owner로 분해되는 meaning을 하나의 새 terminal로 강제 통합하지 않는다.
- `rules/README.md`와 `snippets/rules/README.md`는 tier placement와 현재 source discovery를 소유한다.
- bootstrap snippet은 active action class에서 installed rule로 가는 read-before route만 소유한다.
- install/update/activation owner는 committed source cut의 payload materialization과 별도 activation을 소유한다. source commit은 이 상태를 대신하지 않는다.

## 수정 대상

- `rules/docs-working-model/docs-working-model.md`
- `rules/docs-working-model/checklists/docs-working-model_closeout_checklist.md`
- `rule_docs/docs-working-model/docs-working-model_backlog.md`
- 독립 owner interface인 `rules/rule-authority.md`

repo-only/distribution index, bootstrap snippets, `INSTALL.md`, install/update/activation scripts와 DWM checker/tests는 실제 identity·route·mechanical predicate가 바뀌는 경우에만 수정한다.

## 하지 않을 것 (non-goals)

- 기존 add/change lifecycle을 새 상태기계나 공통 actor로 대체하지 않는다.
- 실제 필요가 없는 terminal rule을 dummy로 추가·삭제하지 않는다.
- 중앙 rule registry, dependency graph, semantic scanner, permanent reference checklist를 만들지 않는다.
- Git history의 old path나 commit citation을 active stale reference로 취급하지 않는다.
- domain Spec의 live repeal 의미, 일반 late-policy 분류, cross-owner rewind 절차를 이 revision에 흡수하지 않는다.
- terminology, no-background, subagent-orchestration의 현재 owner 결정을 대신하지 않는다.
- global/user payload update·activation을 수행하거나 source-side 완료로 주장하지 않는다.

## Plan readiness / open risks

방향 결정은 닫혔으며 Plan으로 내려갈 수 있다.

- closeout은 whole-rule retire에서 terminal file이 계속 존재한다고 전제하지 않아야 한다. 해당 form-bound 문면은 closeout checklist에서 직접 정렬한다.
- semantic reference와 retained meaning은 완전 기계화할 수 없다. checker를 넓히지 않고 owner/evidence 판단으로 남긴다.
- existing checker의 orphan/backlog topology는 terminal 제거 후 남은 physical residue를 이미 잡지만 lifecycle semantic 완료를 증명하지 않는다.
- actual whole-rule retire와 distributed runtime removal은 안전한 대상과 별도 global 승인이 없으므로 이번 revision에서 미실증으로 남는다.
- 이 governance self-revision의 closeout까지는 변경 전 DWM이 지배한다.
