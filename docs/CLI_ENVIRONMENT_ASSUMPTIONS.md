# CLI Environment Assumptions

ai-harness-toolset의 CLI 환경 의존성은 동일 tier가 아니다. 아래 4개 tier로 분리하여 기술한다.

## Tier 1 — Required script runtime

- PowerShell

`scripts/` 아래의 모든 진입점은 `.ps1` 파일이며 PowerShell 호스트가 있어야 실행된다. 현재 MVP는 Windows PowerShell 5.1과 PowerShell 7.x에서 동작한다.

## Tier 2 — Reviewer execution dependency

- Codex CLI

`scripts/review-run.ps1` 가 1회 비대화형 실행하는 reviewer 백엔드다. PATH 에 있거나 `$env:AI_HARNESS_CODEX_COMMAND` 로 명시되어야 한다. canonical 두 단계 entry 의 첫 단계 (`scripts/review-prepare.ps1`) 와 input.md heading 검증 단독 호출 (`scripts/review-input-verify.ps1`) 은 Codex CLI 가 없어도 동작한다.

Codex CLI는 shim 파일 확장자(`.ps1`, `.cmd`, `.exe`, extensionless)와 무관하게 stdin-pipe 방식으로 호출된다. Windows에서 npm으로 설치된 `codex.ps1` shim 또한 real CLI 로 취급되어 동일한 경로를 탄다. `$env:AI_HARNESS_CODEX_COMMAND` 는 PATH 가 아닌 위치의 shim 을 명시하는 escape hatch 이지 일상적인 wrapper 지정 수단이 아니다.

테스트 격리용 stub-args-file protocol (`-CodexArgsFile`) 은 `tests/review-cycle.Tests.ps1` 전용이며 `$env:AI_HARNESS_CODEX_ARGS_FILE_STUB = '1'` 로만 활성화된다. 운영 환경에서는 이 환경 변수를 설정하지 않는다.

## Tier 3 — Optional convenience / provenance

- Git

Git은 본 toolset의 기능적 prerequisite가 아니다. 두 가지 보조 역할을 한다.

- Changed-file convenience: operator-role AI 가 review scope 를 잡을 때 `git status --porcelain=v1` 로 tracked 변경 파일 집합을 식별하고 `input.md` 의 `## Target files` section 에 반영한다.

Explicit target files 가 `input.md` 안에 명시되면 비-Git 프로젝트에서도 first-class 로 동작한다. `input.md` 본문 자체가 review request 의 단일 운반 매체이므로, target file 목록을 외부 staging file 로 분산하지 않는다 (`docs/REVIEW_RESULT_CONTRACT.md` 의 canonical artifact contract).

canonical 두 단계 entry (`scripts/review-prepare.ps1` / `scripts/review-run.ps1`) 중 어느 단계라도 0 이 아닌 코드로 종료되면 자동 재실행하지 않는다. wrapper failure 를 보고하고 별도의 scoped 사용자 승인을 받은 뒤에만 다시 invocation 한다. 자연어 운용 경로에서는 `snippets/claude-skills/ai-harness-review/SKILL.md` 의 retry discipline 절을 따른다.

## Tier 4 — External operator ecosystem

External operator tools may exist in the user's environment but are not invoked by this toolset and are not installed/configured/PATH-modified by this toolset.
