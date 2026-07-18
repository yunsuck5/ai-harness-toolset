# Contributing

`ai-harness-toolset`은 solo-maintained 프로젝트입니다.

Issues, 사용 후기, 문서 오류 제안은 환영합니다. Pull Request는 선택적으로 검토되며, acceptance를 보장하지 않습니다.

## 기본 원칙

이 프로젝트의 방향은 다음입니다.

```text
local-first
PowerShell 중심
AI coding agent가 읽고 실행 가능한 repo 구조
GitHub URL 기반 자연어 install / update / uninstall
review / brief / evidence workflow의 deterministic support
solo-maintainable
```

다음 방향은 현재 우선순위가 아닙니다.

```text
GitHub Actions CI/CD 추가
cloud service화
daemon / watcher / scheduler 추가
package manager 배포
telemetry 추가
대규모 framework화
```

## Issue 작성

Issue를 열 때는 가능하면 다음 정보를 포함해 주세요.

```text
목적
사용 환경
재현 절차
예상 결과
실제 결과
관련 path
민감정보 제거 여부
```

민감정보, 회사 내부 정보, private prompt, private log, private evidence는 포함하지 마십시오.

## Pull Request 기준

작은 문서 수정, typo 수정, 명확한 bug fix는 비교적 검토하기 쉽습니다.

다음 변경은 사전 논의가 필요합니다.

```text
install / update / uninstall lifecycle 변경
global/user filesystem mutation 변경
managed-block marker 정책 변경
review verdict contract 변경
brief artifact contract 변경
ToolRoot layout 변경
docs-working-model 변경
새 dependency 추가
```

## 테스트 / 검증

PowerShell script를 수정했다면 관련 Pester test와 script verification을 함께 고려해야 합니다.

대표 검증 범위는 다음입니다.

```text
scripts/verify-ps1.ps1
tests/*.Tests.ps1
review-prepare / review-run / review-verify
brief-init / brief-status / brief-check
install-global / update-global / uninstall-global
```

정확한 test command는 현재 repo의 `tests/README.md`와 관련 script를 기준으로 확인하십시오.

## 문서 작성 언어

Repo 내부 human-facing 문서와 `rules/**` 본문은 한국어를 기본으로 작성합니다. 불특정 adopter가 직접 소비하는 `snippets/rules/**`와 root bootstrap payload인 `snippets/CLAUDE_SNIPPET.md` / `snippets/AGENTS_SNIPPET.md`는 영어를 유지하며, 그 밖의 `snippets/**` 표면은 각 active owner를 따릅니다.

단, 식별자, authority grade, technical clause anchor, gate name, path, filename, class/type name, package name, config key, command, commit hash, API/model name, code identifier는 English 그대로 유지하며 일반 설명 제목은 한국어로 쓸 수 있습니다.

## 금지 사항

다음은 contribution에 포함하지 마십시오.

```text
API key / token / password
회사 내부 코드 / 문서 / prompt / log / evidence
개인 machine-specific path
private model endpoint
runtime log payload
third-party code with unclear license
```

## License

기여한 내용은 이 저장소의 `MIT License` 조건으로 제공되는 것으로 간주합니다.
