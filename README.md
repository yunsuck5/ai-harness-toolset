# ai-harness-toolset

`ai-harness-toolset`은 Claude Code / Codex CLI 같은 AI coding agent가 프로젝트별 review / brief / evidence workflow를 일관되게 수행하도록 돕는 local-first PowerShell toolset입니다.

이 저장소는 package manager 배포물이나 GitHub Actions CI/CD 프로젝트가 아닙니다. 사용자는 GitHub URL을 AI agent에게 전달하고, agent가 이 저장소를 읽어 설치 / 업데이트 / 삭제 / 검증을 수행하는 사용 방식을 기준으로 설계되어 있습니다.

```text
https://github.com/yunsuck5/ai-harness-toolset 설치해줘
```

설치 후에는 다음과 같은 자연어 요청으로 운용합니다.

```text
ai-harness-toolset 최신 버전으로 업데이트해줘
ai-harness-toolset 언인스톨해줘
ai-harness-toolset 설치 상태를 검증해줘
```

## 현재 상태

`ai-harness-toolset`은 public preview 단계의 개인 유지보수 프로젝트입니다.

- License: MIT
- Usage: 개인 / 학습 / 상업적 사용 가능
- Maintenance: solo-maintained, best-effort
- Warranty: 없음
- Primary lifecycle contract: Claude Code-first
- Codex usage: AGENTS.md-compatible review / brief workflow에서 사용 검증됨

## 핵심 아이디어

기존 개발 도구는 보통 사용자가 설치 명령어를 직접 찾아 실행합니다. 이 프로젝트는 반대로, AI coding agent가 repo를 읽고 필요한 install / update / uninstall / verification 절차를 수행할 수 있도록 저장소 자체를 agent-readable하게 구성합니다.

목표는 다음입니다.

```text
GitHub URL
→ AI coding agent가 repo를 읽음
→ install / update / uninstall entrypoint 확인
→ 사용자 승인 후 global/user surface 적용
→ target project에는 log/ runtime artifact만 생성
→ review / brief workflow를 반복 가능하게 사용
```

## 이 도구가 하는 일

### 1. Global stable ToolRoot 설치

기본 설치 모델은 user profile 아래 vendor-neutral install AREA와 그 하위 stable runtime ToolRoot를 사용합니다.

```text
install AREA:
%USERPROFILE%\ai-harness-toolset\

stable ToolRoot:
%USERPROFILE%\ai-harness-toolset\current\
```

stable ToolRoot에는 다음 payload가 deterministic하게 materialize됩니다.

```text
config/
scripts/
snippets/
templates/
```

설치 metadata / manifest / marker는 install AREA 안에서 sibling artifact로 관리됩니다.

### 2. Claude / Codex instruction surface 적용

운용에 필요한 managed block을 사용자 global instruction surface에 적용합니다.

```text
%USERPROFILE%\.claude\CLAUDE.md
%USERPROFILE%\.codex\AGENTS.md
```

Claude skill mirror는 다음 위치에 생성됩니다.

```text
%USERPROFILE%\.claude\skills\ai-harness-review\SKILL.md
%USERPROFILE%\.claude\skills\ai-harness-brief\SKILL.md
```

Codex의 경우 `%CODEX_HOME%` 또는 `AGENTS.override.md`가 있는 환경에서는 해당 effective destination을 따릅니다. 자세한 install / update / uninstall contract는 `INSTALL.md`가 self-contained operative contract입니다.

### 3. Review workflow

Codex reviewer를 deterministic gate로 호출하기 위한 review artifact layout과 runner scripts를 제공합니다.

대표 artifact 구조는 다음입니다.

```text
<ProjectRoot>/log/review/<review-task-id>/<perspective>/pass-01/
  input.md
  result.md
```

review result의 verdict vocabulary는 다음 세 값입니다.

```text
yes
no
yes with risk
```

중요: review verdict는 commit / push / publish / merge / release 승인이 아닙니다. 최종 결정은 사용자가 별도로 합니다.

### 4. Brief workflow

프로젝트별 `log/brief/BRIEF.md`를 생성 / 갱신 / 검사하기 위한 brief workflow를 제공합니다.

```text
<ProjectRoot>/log/brief/BRIEF.md
```

Brief는 현재 프로젝트 상태를 agent에게 전달하기 위한 runtime artifact이며, source-of-truth가 아니라 운용 보조물입니다.

### 5. Runtime artifact 격리

target project에 남는 persistent footprint는 기본적으로 다음 runtime log tree입니다.

```text
<ProjectRoot>/log/
  brief/
  evidence/
  review/
```

`log/`는 runtime artifact root이며 보통 commit 대상이 아닙니다. target project의 `.gitignore`에서 `log/`를 제외하는 것을 권장합니다.

## 빠른 시작

### 설치

Claude Code 또는 Codex CLI에게 다음처럼 요청합니다.

```text
https://github.com/yunsuck5/ai-harness-toolset 설치해줘
```

권장 흐름은 다음입니다.

1. agent가 repo를 clone 또는 fetch합니다.
2. `INSTALL.md`를 읽습니다.
3. 현재 host 상태와 mutation target을 inspect합니다.
4. 사용자에게 변경될 global/user path와 cleanup 계획을 보고합니다.
5. 사용자가 명시적으로 승인하면 install을 수행합니다.
6. verification / operational smoke를 수행합니다.
7. 결과와 변경 path를 보고합니다.

### 업데이트

이미 설치된 상태에서는 다음처럼 요청합니다.

```text
ai-harness-toolset 최신 버전으로 업데이트해줘
```

### 삭제

```text
ai-harness-toolset 언인스톨해줘
```

삭제 역시 사용자 승인 없이 자동 수행되어서는 안 됩니다. agent는 제거 대상과 남길 항목을 먼저 보고해야 합니다.

## 지원 환경

현재 primary target은 Windows + PowerShell 환경입니다.

- Windows PowerShell 5.1 또는 PowerShell 7+
- git
- Claude Code 또는 Codex CLI
- 사용자 profile 아래 `.claude` / `.codex` 경로에 대한 read/write 권한

이 저장소의 scripts는 PowerShell 중심입니다. 다른 OS나 shell은 best-effort이며, 현재 public preview의 primary support target은 아닙니다.

## Claude Code / Codex CLI 지원 범위

| 영역 | Claude Code | Codex CLI |
|---|---:|---:|
| install / update / uninstall lifecycle | Primary / Claude Code-first contract | 호환 경로로 사용 가능하나, operative install contract는 현재 Claude Code-first |
| global instruction surface | `CLAUDE.md` managed block | `AGENTS.md` managed block |
| review workflow | 사용 가능 | 주요 검증 경로 |
| brief workflow | 사용 가능 | 사용 가능 |
| package manager 배포 | 없음 | 없음 |
| GitHub Actions CI/CD | 사용하지 않음 | 사용하지 않음 |

이 저장소는 Claude Code와 Codex CLI를 대체하지 않습니다. 두 agent가 더 안정적으로 프로젝트별 workflow를 수행하도록 돕는 deterministic toolset입니다.

## 이 도구가 아닌 것

`ai-harness-toolset`은 다음이 아닙니다.

- AI orchestrator
- autonomous coding framework
- GitHub Actions CI/CD pipeline
- cloud service
- daemon / watcher / scheduler
- package manager 배포물
- telemetry 수집 도구
- secret scanning replacement
- commit / push / publish 자동 승인 시스템

## 저장소 구조

주요 경로는 다음입니다.

```text
INSTALL.md                         # install / update / uninstall self-contained operative contract
AGENTS.md                          # repo-local Codex instruction surface
CLAUDE.md                          # repo-local Claude instruction surface

config/                            # reviewer config / schema
scripts/                           # deterministic PowerShell scripts
snippets/                          # global instruction snippets / skills / rules
templates/                         # review / brief / install-root templates
tests/                             # Pester tests

docs/
  README.md                        # docs tree orientation
  brief/                           # brief domain spec / backlog
  install-update/                  # install-update domain spec / backlog
  review/                          # review domain spec / backlog

rules/                             # repo-development rules
```

## 문서 읽기 기준

- 설치 / 업데이트 / 삭제를 수행할 때는 `INSTALL.md`를 우선합니다.
- 내부 문서 구조와 세부 spec 위치는 `docs/README.md`를 참고하십시오.

## 검증

이 저장소는 GitHub Actions를 primary validation path로 사용하지 않습니다.

검증의 중심은 local agent execution과 PowerShell/Pester 기반 테스트입니다.

대표적으로 다음 범위를 확인합니다.

```text
install / update / uninstall lifecycle
managed block apply / verify
review input / result verification
brief init / status / check
PowerShell script syntax / encoding discipline
repo-local instruction parity
```

실제 테스트 명령은 현재 repo의 `tests/README.md`와 각 script/test 파일을 기준으로 확인하십시오.

## 보안 / 민감정보

이 저장소는 API key, password, private endpoint, 회사 내부 정보, 개인 runtime log를 포함하지 않는 것을 원칙으로 합니다.

Public repo에 넣으면 안 되는 것:

```text
API key / token / password
회사 내부 코드 / 문서 / prompt / log / evidence
개인 machine-specific path
private model endpoint
runtime log payload
```

보안 이슈나 민감정보 노출이 의심되면 `SECURITY.md`를 참고하십시오.

## 기여 정책

이 프로젝트는 solo-maintained입니다. Issues나 제안은 환영하지만, Pull Request나 기능 요청은 선택적으로만 검토됩니다.

큰 설계 변경, lifecycle 변경, global/user filesystem mutation 변경은 maintainer의 명시적 승인 없이 받아들이지 않습니다.

자세한 내용은 `CONTRIBUTING.md`를 참고하십시오.

## License

MIT License.

개인 / 학습 / 상업적 사용이 가능합니다. 단, 이 소프트웨어는 어떠한 보증도 제공하지 않습니다. 자세한 내용은 `LICENSE.md`를 참고하십시오.
