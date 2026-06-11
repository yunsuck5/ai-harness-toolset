# {{DOMAIN}} Spec — docs-working-model lifecycle ({{BATCH}})

> 사용법: 이 형틀을 복제해 `<domain>_spec.md` 로 채운다. 모든 `{{...}}` 를 치환/제거한다. Spec 이 Plan 을 위반하면 stop → Plan 재설계 후 Spec 재시작(rewind). Implementation 이 Spec boundary 를 초과하면 stop → ask user. Spec 은 closeout 후 live.

## Scope (batch 한정)

{{이 Spec 이 다루는 batch / 다루지 않는 batch}}

## Candidate files

- create: {{...}}
- move/rename: {{...}}
- delete/remove: {{...}}
- modify: {{...}}
- validate-only: {{...}}
- not touched: {{...}}

## Owner absorption proof

{{삭제/이동 대상마다 current-bearing 내용의 흡수처를 section 단위로 대조(누락 0)}}

## 4-class reference sweep

{{filename·path / bare-token·ID / folder-as-bucket / semantic-phrasing sweep commands + before/after 수치}}

## Allowed / forbidden active-surface changes

{{허용하는 active surface 변경 / 금지하는 변경(not-touched 표면)}}

## Validation commands (로컬 실행 가능한 것만)

{{PowerShell-first; path 검사 Test-Path; 본문 검사 Select-String(실제 파일 기준); staged byte/EOL; Pester. 로컬 불가 validation 도입 금지}}

## Corrected-state Codex review gate

{{corrected working tree 기준 글로벌 stable Codex review(dual 권장) goal. review 후 source/doc 재수정 시 stale → 재리뷰}}

## Rollback / rewind

{{Spec 이 Plan 위반 시 rewind; Implementation 이 Spec 초과 시 stop+ask; validation/review 실패 시 stop}}

## Approval boundary

순서: Spec review → 명시 승인 → implementation(final Spec only) → validation → corrected-state Codex review → (별도 명시 승인 시) commit/push. verdict 는 mutation/commit/push 승인이 아니다.

## Reconstructibility note

{{구현 결과만으로 이 Spec 을 역검증할 수 있고, 이 Spec 만으로 구현을 재수행할 수 있음을 명시}}
