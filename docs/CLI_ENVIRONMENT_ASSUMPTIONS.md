# CLI Environment Assumptions

ai-harness-toolset의 CLI 환경 의존성은 동일 tier가 아니다. 아래 4개 tier로 분리하여 기술한다.

## Tier 1 — Required script runtime

- PowerShell

`scripts/` 아래의 모든 진입점은 `.ps1` 파일이며 PowerShell 호스트가 있어야 실행된다. 현재 MVP는 Windows PowerShell 5.1과 PowerShell 7.x에서 동작한다.

## Tier 2 — Reviewer execution dependency

- Codex CLI

`scripts/review-cycle.ps1`이 1회 비대화형 실행하는 reviewer 백엔드다. PATH에 있거나 `$env:AI_HARNESS_CODEX_COMMAND`로 명시되어야 한다. component 스크립트(`review-prepare.ps1`, `review-input-verify.ps1`, `review-verify.ps1`)만 단독 사용하는 경우에는 필요하지 않다.

Codex CLI는 shim 파일 확장자(`.ps1`, `.cmd`, `.exe`, extensionless)와 무관하게 stdin-pipe 방식으로 호출된다. Windows에서 npm으로 설치된 `codex.ps1` shim 또한 real CLI 로 취급되어 동일한 경로를 탄다. `$env:AI_HARNESS_CODEX_COMMAND` 는 PATH 가 아닌 위치의 shim 을 명시하는 escape hatch 이지 일상적인 wrapper 지정 수단이 아니다.

테스트 격리용 stub-args-file protocol (`-CodexArgsFile`) 은 `tests/review-cycle.Tests.ps1` 전용이며 `$env:AI_HARNESS_CODEX_ARGS_FILE_STUB = '1'` 로만 활성화된다. 운영 환경에서는 이 환경 변수를 설정하지 않는다.

## Tier 3 — Optional convenience / provenance

- Git

Git은 본 toolset의 기능적 prerequisite가 아니다. 두 가지 보조 역할을 한다.

- Changed-file convenience: `review-cycle.ps1`에서 `-TargetFiles`가 생략된 경우 `git status --porcelain=v1`로 tracked 변경 파일을 자동 추정한다.
- sourceHead provenance: `review-prepare.ps1`이 `git rev-parse HEAD`를 `meta.json.sourceHead`에 기록한다. Git이 없으면 `meta.sourceHead = null`이 정상 값이다.

Explicit `-TargetFiles`가 제공되면 비-Git 프로젝트에서도 first-class로 동작한다.

## Tier 4 — External operator ecosystem

External operator tools may exist in the user's environment but are not invoked by this toolset and are not installed/configured/PATH-modified by this toolset.
