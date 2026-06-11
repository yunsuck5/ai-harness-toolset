# {{DOMAIN}} Plan — docs-working-model lifecycle

> 사용법: 이 형틀을 복제해 `<domain>_plan.md` 로 채운다. 모든 `{{...}}` 를 치환/제거한다. Plan 이 Design 을 위반하면 stop → Design 재설계 후 Plan 재시작(rewind). Plan 은 영구 live 아님 — closeout 시 흡수 후 retire.

## Batch decomposition

{{batch 표 + 통합/분리 근거. 각 batch 의 한 줄 goal·선행·upfront 약속과의 관계}}

## Per-batch scope

{{각 batch 가 다루는 것 / 다루지 않는 것(후속 batch 로 미루는 것)}}

## Hard boundaries (per batch)

{{각 batch 의 불가침 경계 — not-touched 표면, INSTALL.md 불가침 등}}

## Reference sweep requirement (4-class)

{{각 mutation batch 전 4-class sweep(filename·path / bare-token·ID / folder-as-bucket / semantic-phrasing) 요구}}

## Owner absorption proof requirement

{{삭제/이동/retire 시 current-bearing 내용의 흡수처 증명 요구(흡수 없는 broad delete 금지)}}

## Validation gate

{{각 batch closeout 전 validation — 로컬 실행 가능한 것만}}

## Codex review gate

{{corrected working tree 기준 글로벌 stable Codex review(perspective; dual 권장)}}

## Approval boundary

분류/계획은 mutation 승인이 아니다. 실제 mutation 은 batch Spec + 명시 승인 후. commit/push 는 별개 명시 승인.

## Rollback / rewind

{{Plan 이 Design 위반 시 stop + Design rewind; batch shape 가 바뀌면 재검토}}

## Readiness judgment

- ready for Spec: {{yes | no | yes with risk}}
