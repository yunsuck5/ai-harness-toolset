# {{DOMAIN}} Design — docs-working-model lifecycle

> 사용법: 이 형틀을 복제해 `<domain>_design.md` 로 채운다. 모든 `{{...}}` 를 실제 값으로 치환/제거한다. 이 형틀 파일 자체는 편집하지 않는다. Design 은 영구 live 아님 — closeout 시 Spec(또는 올바른 owner surface)으로 흡수 후 retire(`../checklists/docs-working-model_closeout_checklist.md`).

## Why (왜 변경)

{{변경이 필요한 이유 — 현행 live Spec/구현의 어떤 문제를 푸는가}}

## What (무엇을 변경)

{{무엇을 바꾸는가 — 방향의 큰 그림(정확한 파일 목록은 Spec)}}

## Owner surface model

{{이 변경이 owner 로 삼는 active surface(scripts/templates/snippets/skills/config/tests/rules/INSTALL.md 등). rules 는 target class·invariant·approval boundary 만 명명하고 behavior 를 흡수하지 않는 경계를 명시}}

## Non-goals

{{명시적으로 하지 않는 것 — rejected terms 부활 / broad cleanup / scope creep 차단}}

## Targets to modify (기존 live Spec/구현 수정 대상)

{{이 변경이 수정·대체하는 기존 live Spec·구현·docs}}

## Readiness judgment

- ready for Plan: {{yes | no | yes with risk}}
- open risks: {{열린 risk 목록}}

## Review gate note

글로벌 stable engine Codex review 로 닫는다(dual-perspective 권장). verdict(`yes` / `no` / `yes with risk`)는 commit/mutation 승인이 아니다.
