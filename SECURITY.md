# Security Policy

## 지원 범위

`ai-harness-toolset`은 solo-maintained public preview 프로젝트입니다. 별도의 SLA, 보안 보증, 유료 support contract는 제공하지 않습니다.

현재 보안 검토 대상은 이 저장소의 public source에 포함된 다음 범위입니다.

```text
scripts/
snippets/
templates/
config/
INSTALL.md
README.md
AGENTS.md
CLAUDE.md
```

다음 항목은 이 저장소의 보안 지원 범위가 아닙니다.

```text
사용자 개인 환경의 Claude Code / Codex CLI 자체 문제
사용자 global CLAUDE.md / AGENTS.md의 기존 내용
adopter project의 비공개 prompt / log / evidence
회사 내부망 / 회사 계정 / 회사 전용 설정
third-party package / external service
```

## 신고 대상

다음이 의심되면 신고해 주세요.

```text
secret / token / password / private endpoint 노출
의도하지 않은 global/user filesystem mutation
install / update / uninstall 중 안전하지 않은 path handling
managed-block marker 손상 또는 예기치 않은 삭제
runtime log가 source repo에 commit될 수 있는 구조적 문제
```

## 신고 방법

민감정보가 포함될 수 있는 내용은 public issue에 직접 올리지 마십시오.

보안 관련 신고는 아래 이메일로 보내 주세요.

```text
yunsuck5@gmail.com
```

민감하지 않은 일반 버그, 문서 오류, 사용성 제안은 GitHub Issues를 사용해도 됩니다.

## 신고 시 포함하면 좋은 정보

가능하면 다음 정보를 포함해 주세요.

```text
사용 OS / PowerShell version
Claude Code 또는 Codex CLI 사용 여부
실행한 자연어 요청 또는 script command
예상 동작
실제 동작
변경된 path 목록
민감정보를 제거한 최소 재현 정보
```

API key, password, 회사 내부 정보, private prompt, private log, private evidence는 보내지 마십시오.

## 처리 방침

이 프로젝트는 개인 유지보수 프로젝트이므로 응답 시간은 보장하지 않습니다. 다만 실제 보안 리스크로 판단되는 내용은 우선순위를 높여 검토합니다.

필요한 경우 maintainer는 다음 방식으로 대응할 수 있습니다.

```text
문서 경고 추가
script 수정
managed-block / install boundary 수정
release note 또는 issue로 공지
```

## 보안 모델의 기본 원칙

`ai-harness-toolset`은 다음 원칙을 유지합니다.

```text
명시적 사용자 승인 없는 global/user mutation 금지
target project의 persistent footprint는 log/ 중심으로 제한
runtime log / evidence는 source repo에 commit하지 않음
secret scanning replacement로 사용하지 않음
commit / push / publish / merge / release 자동 승인 없음
```
