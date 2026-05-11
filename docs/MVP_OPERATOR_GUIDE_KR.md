# MVP Operator Guide (Korean)

이 문서는 `ai-harness-toolset` 의 MVP 가 사용자 관점에서 사용 가능한지 직접 평가하기 위한 operator-facing 가이드다.

대상 독자는 이 toolset 을 자기 프로젝트에 copy-only / CLI-only 로 적용해 보려는 사용자다. 내부 개발자 문서가 아니다. 자세한 contract / policy / migration 은 `docs/` 의 다른 파일을 참고한다.

설명은 한국어, 경로 / 파일명 / 스크립트명 / 명령어 / config key / verdict 문자열 등 식별자는 영문 그대로 둔다.

---

## 1. MVP 의 의미

이 repo 의 MVP 는 다음을 만족하는 상태를 가리킨다.

- source repo 의 `config/`, `scripts/`, `snippets/`, `templates/` 만 다른 프로젝트에 복사하면 동작한다.
- 사용자가 단일 PowerShell 명령 (`scripts/review-cycle.ps1`) 으로 review packet 준비 → input 검증 → Codex CLI 1회 실행 → verdict parsing → result 기록 → freshness / binding 검증을 모두 수행한다.
- 결과는 `<project-root>/log/review/<run-id>/` 아래 read-only 파일로 보존된다.
- 자동 commit / push / release 는 하지 않는다. verdict 는 사용자 판단 input 일 뿐 자동 게이트가 아니다.

MVP 는 productization 이 아니다. installer, watcher, hook, daemon, auto-fix loop, retention automation 은 명시적으로 out-of-scope 이다 (`docs/AI_HARNESS_TOOLSET_SCOPE.md`).

---

## 2. source repo vs target repo

이 toolset 에는 두 가지 운용 모드가 있다.

| 모드 | 의미 | tool root |
|---|---|---|
| source repo | 이 repo 자체 (`ai-harness-toolset`) 안에서 직접 사용 | `<repo-root>/` |
| target payload | 다른 프로젝트에 copy-only 로 배포한 경우 | `<project-root>/.ai-harness/` |

스크립트 호출 경로만 다르고, 동작 contract 는 같다.

- source repo 모드에서는 `scripts/<name>.ps1` 을 직접 실행한다.
- target payload 모드에서는 `<project-root>/.ai-harness/scripts/<name>.ps1` 을 실행한다.

source repo 의 `docs/`, `tests/`, `log/` 는 target 으로 복사되지 않는다. target 에서 `docs/*.md` 가 필요하면 source repo 쪽 파일을 본다.

---

## 3. `.ai-harness/` payload 구조

target project 에 복사해야 하는 4개 폴더는 다음과 같다. 그 외 항목은 복사하지 않는다.

| Source path | Target path |
|---|---|
| `config/` | `<project-root>/.ai-harness/config/` |
| `scripts/` | `<project-root>/.ai-harness/scripts/` |
| `snippets/` | `<project-root>/.ai-harness/snippets/` |
| `templates/` | `<project-root>/.ai-harness/templates/` |

규칙:

- `docs/`, `tests/`, `log/`, `README.md`, `.gitattributes` 등은 복사하지 않는다.
- `.ai-harness/` 디렉터리만 지우면 deployment 가 사라진다 (no global mutation).
- 글로벌 파일 (`~/.claude/`, 글로벌 `CLAUDE.md` / `AGENTS.md`) 은 어떤 경우에도 자동으로 변경되지 않는다.

`snippets/` 는 root 의 `CLAUDE.md` / `AGENTS.md` 에 사용자가 의도적으로 managed block 형태로 붙여 넣는 영문 payload 다. 자동 주입은 하지 않는다 (`README.md` 의 Snippets 절 참조).

---

## 4. `log/` runtime output 구조

runtime artifact 는 항상 `<project-root>/log/` 아래에만 생성된다.

```
<project-root>/log/
├── chatlog/   # 세션 작업 로그 (docs/CHATLOG_CONTRACT.md)
├── evidence/  # 명령 / 테스트 / 실행 사실 (docs/EVIDENCE_CONTRACT.md)
└── review/    # review packet 과 review record (docs/REVIEW_RESULT_CONTRACT.md)
    └── <run-id>/
        ├── meta.json
        ├── input.md
        ├── result.md
        └── result.json
```

- `log/` 는 runtime artifact tree 다. 절대 commit 하지 않는다.
- target project 의 `.gitignore` 에 `log/` 가 들어가 있는지 사용자가 직접 확인한다. toolset 은 target 의 `.gitignore` 를 만들지 않는다.
- review record 의 retention 단위는 `<run-id>` 디렉터리 전체다. 사용자가 손으로 지운다. 자동 prune / rotate 는 없다.

`scripts/log-init.ps1` 을 한 번 실행하면 `log/`, `log/chatlog/`, `log/evidence/`, `log/review/` 4개 디렉터리가 생성된다.

---

## 5. 전체 pipeline diagram

```mermaid
flowchart TD
    A[user or AI changes files in project] --> B{review required?}
    B -- no --> Z1[no review needed]
    B -- yes --> C[run scripts/review-cycle.ps1<br/>single CLI call]
    C --> D[review-prepare.ps1<br/>seed meta.json + input.md<br/>under log/review/&lt;run-id&gt;/]
    D --> E[review-cycle fills placeholders<br/>from -Context / -ReviewQuestions / etc]
    E --> F[review-input-verify.ps1<br/>required headings + no leftover placeholders]
    F -- fail --> X1[FAIL: start a new run<br/>with corrected CLI args]
    F -- pass --> G[Codex CLI exec, one-shot<br/>stdin = input.md<br/>--output-last-message = result.md]
    G --> H[parse '## Verdict' heading<br/>from result.md]
    H -- parse fail --> X2[FAIL: result.json not written<br/>failed run preserved for inspection<br/>start a new run-id]
    H -- parse ok --> I[review-cycle writes result.json<br/>verdict + sha bindings]
    I --> J[review-verify.ps1 default<br/>target SHA freshness check]
    J --> K[review-verify.ps1 -RequireResult<br/>completed-record binding check]
    K --> L{verdict}
    L -- yes --> M1[user decides next step]
    L -- yes with risk --> M2[user weighs risk and decides]
    L -- no --> M3[user fixes and runs new run-id]
    M1 --> N[commit / push / release<br/>STILL require explicit user approval]
    M2 --> N
    M3 --> N
```

핵심 포인트:

- 한 번의 사용자 호출 = 한 번의 Codex 실행. retry / fallback model / auto-fix loop 없음.
- verdict 가 `yes` 여도 commit / push / publish / merge / release 자동 트리거 없음.
- parsing 실패한 run 은 디스크에 그대로 남는다. 사람이 같은 run-id 안의 파일을 손으로 보정하지 않고, 새 run-id 로 다시 만든다.

---

## 6. `review-cycle.ps1` sequence diagram

```mermaid
sequenceDiagram
    participant U as User
    participant RC as review-cycle.ps1
    participant RP as review-prepare.ps1
    participant RIV as review-input-verify.ps1
    participant CX as Codex CLI
    participant RV as review-verify.ps1

    U->>RC: invoke with -Stage / -Purpose / -TargetFiles / ...
    RC->>RC: resolve project / tool / log root
    RC->>RC: detect or accept -TargetFiles
    RC->>RC: allocate fresh <run-id>
    RC->>RP: spawn (-File review-prepare.ps1 -RunId <id>)
    RP-->>RC: writes log/review/<run-id>/meta.json + input.md
    RC->>RC: fill placeholders in input.md
    RC->>RIV: spawn (-File review-input-verify.ps1 -InputPath input.md)
    RIV-->>RC: PASS or FAIL
    alt input verify FAIL
        RC-->>U: FAIL, start a new run with corrected args
    else input verify PASS
        RC->>CX: codex exec --sandbox read-only --model <m><br/>--output-last-message result.md, stdin = input.md
        CX-->>RC: writes result.md, exit 0
        RC->>RC: parse exactly one "## Verdict" heading
        alt parse FAIL
            RC-->>U: FAIL, result.json not written,<br/>preserved <run-id> for inspection
        else parse OK
            RC->>RC: write result.json with verdict + sha bindings
            RC->>RV: spawn default mode (-RunId)
            RV-->>RC: target SHA freshness OK
            RC->>RV: spawn -RequireResult mode
            RV-->>RC: completed-record binding OK
            RC-->>U: PASS, run-id, verdict, result path
        end
    end
```

`Codex CLI` 인자는 `--ask-for-approval never`, `--sandbox read-only`, `--output-last-message <result.md>`, `-c web_search=disabled`, `--model <model>` 로 호출된다 (`scripts/review-cycle.ps1` 의 `Invoke-CodexExec` 참조).

---

## 7. 일상 운용 UX 는 Claude Code CLI 자연어 의도다

`ai-harness-toolset` 의 일상 운용 진입점은 사용자가 Claude Code CLI 안에서 한국어 또는 영문으로 자연어 의도를 표현하는 것이다. 사용자는 일반적으로 raw PowerShell 명령을 직접 입력하지 않는다.

| 사용자 발화 (예시) | TargetFiles 모드 | Claude Code 가 수행하는 동작 |
|---|---|---|
| `현재 진행한 작업 코덱스 리뷰 진행해` | Mode A — changed files | git status / diff 확인 → 변경된 tracked 파일을 TargetFiles 로 결정 → review-cycle.ps1 인자 합성 → 1회 실행 → result.md / result.json 확인 → review-verify -RequireResult 확인 → yes / no / yes with risk 보고. 변경 파일이 0 개면 중단 (Mode B 로 자동 전환하지 않음). |
| `현재 구현된 서버의 소켓 라이브러리를 니가 직접 리뷰하고, 그후에 코덱스 리뷰로 한번 더 리뷰후 최종 결론 도출해` | Mode B — tracked subsystem files | 호명된 subsystem 의 tracked 파일을 (현재 변경 여부와 무관하게) TargetFiles 로 결정 → Claude 자체 리뷰 1회 → 위와 같은 코덱스 cycle 1회 → 두 결과를 병합하여 단일 최종 verdict 도출. |

Mode 선택 규칙은 SKILL.md step 2 에 명시되어 있다. subsystem 명이 너무 넓거나 매칭되는 파일이 없을 때만 Claude 가 1회 clarification 을 묻고, 그 외에는 자율로 진행한다. 어느 mode 에서도 review-cycle.ps1 은 정확히 1회만 실행되고, commit / push 는 하지 않는다.

이 자연어 UX 의 명세는 optional skill template `snippets/claude-skills/ai-harness-review/SKILL.md` 에 정의되어 있다. 아래 8 절을 참고한다.

8 절 이후의 raw PowerShell 명령은 다음 용도로만 사용한다.

- fallback (skill / Claude Code 가 없는 환경, 또는 비활성 상태)
- debug (특정 인자 조합을 직접 검증해야 할 때)
- 참고 reference (skill 이 내부적으로 합성하는 인자 형태를 사람이 읽기 위해)

raw 명령을 그대로 외워서 매번 입력하는 것은 권장하지 않는다.

---

## 7b. Chatlog BF Level 2 UX — 자연어 의도

`ai-harness-toolset` 의 chatlog 운용도 일상에서는 사용자가 raw PowerShell 명령을 직접 입력하지 않는다. 사용자는 Claude Code 안에서 자연어 의도를 표현하고, Claude Code 가 BF (Brief) 영역인 `log/chatlog/current/resume.md` 와 companion `summary.md` 를 직접 갱신한다.

이 절은 chatlog 의 두 책임 영역 중 BF 의 Level 2 UX 만 다룬다. CL (Chat Log — 누적 work history / portfolio / audit) 영역의 fuller automation 은 MVP scope 밖이며 본 가이드는 BF 만 운용 대상으로 본다. 자세한 책임 분리는 `docs/CHATLOG_CONTRACT.md` 의 BF / CL 책임 분리 절을 본다.

### BF 저장 (사용자 발화)

다음 형태의 사용자 발화는 모두 BF 저장 / checkpoint 의도로 해석된다.

```text
현재 진행 지점을 복구 시점으로 저장해
BF 저장해
복구 지점 저장해
handoff 지점 만들어줘
다음 세션에서 이어갈 수 있게 정리해
현재 phase checkpoint 남겨줘
```

이 의도가 감지되면 Claude Code 는 다음 절차를 따른다.

1. repo 상태 확인 (`pwd`, git top-level, branch, HEAD, origin/main, status).
2. 현재 상태 / 마지막 완료 action / 다음 단일 action / do-not-do / pending user decision 을 정리.
3. `log/chatlog/current/resume.md` 갱신 (BF canonical current).
4. `log/chatlog/current/summary.md` 갱신 (BF compact companion).
5. 관련 review / evidence / CL artifact 는 path / link 로만 참조 — 본문 인라인 금지.
6. BF 는 짧게 유지. 상세 내용이 필요하면 path 만 가리킨다.
7. 갱신된 파일과 남은 risk 를 사용자에게 보고.

이 절차에서 Claude Code 는 사용자가 어떤 raw PowerShell 명령도 직접 입력하지 않도록 한다. 사용자가 명시적으로 "직접 PowerShell 로 갱신하겠다" 라고 의사를 밝히지 않는 한 자연어 발화 한 줄로 BF 저장이 완료되어야 한다.

### 새 Claude Code 세션 진입 시 — restore-offer

사용자가 같은 프로젝트에서 새 Claude Code 세션을 열면 Level 2 동작은 다음과 같다.

1. Claude Code 가 `log/chatlog/current/resume.md` 존재 여부를 확인.
2. 존재하면 그 파일을 읽고, 한국어로 현재 상태 / 다음 단일 action / do-not-do / pending user decision 을 요약 보고.
3. 사용자에게 `이 복구 지점에서 이어서 진행할까요?` 라고 묻는다.
4. 사용자 확인 전에는 의미 있는 작업을 실행하지 않는다.

`resume.md` 가 없으면 `summary.md` 로 fallback 하고 BF 가 비어있거나 미흡함을 보고한다. raw transcript / 누적 CL 본문을 읽어 BF 를 임의로 재구성하지 않는다.

### Level 2 의 의미와 자동화 경계

본 절은 Level 2 MVP 동작이다. 사용자가 자연어로 BF 를 저장 / 복원하는 협업 contract 이지, 자동화된 hook / installer 가 아니다.

- 본 MVP 는 hook, session-start automation, on-stop hook, on-prompt-submit hook, watcher, daemon, scheduler 를 포함하지 않는다.
- 사용자 prompt 자동 capture, assistant 응답 자동 capture, transcript JSONL parser, `BF_STATE.json` 같은 별도 state machine 은 본 MVP scope 밖이다.
- `~/.claude/settings.json` 또는 글로벌 `CLAUDE.md` / `AGENTS.md` 의 mutation 은 본 MVP 가 절대 수행하지 않는다. 모든 chatlog payload 는 project-local 이다.
- CL (Chat Log) 영역의 fuller implementation — 누적 work history 자동화, 자체 schema, retention, browse UI, RND-style `CHAT_LOG + REPORT + BRIEF` heavy workflow — 는 본 MVP 가 다루지 않는다.
- Claude Code snippet 자체는 자동 install 되지 않는다. 사용자가 의도적으로 root `CLAUDE.md` / `AGENTS.md` 의 managed block 에 붙여 넣은 경우에만 활성화된다.

이 절의 UX 는 `snippets/CLAUDE_SNIPPET.md` 와 `snippets/AGENTS_SNIPPET.md` 의 `Chatlog session protocol` / `Restore-offer behavior` / `BF save / checkpoint protocol` 와 substance 가 동일해야 한다. 둘 사이에 의미가 충돌하면 contract 위반이다.

---

## 8. Optional skill adoption path

`snippets/claude-skills/ai-harness-review/SKILL.md` 는 자동 주입되지 않는 optional payload 다. 다른 snippet 들과 마찬가지로 사용자가 의도적으로 채택한다.

채택 위치는 둘 중 하나다. 둘 다 사용자가 직접 복사한다.

| 위치 | 의미 |
|---|---|
| `<project-root>/.claude/skills/ai-harness-review/SKILL.md` | 이 프로젝트에서만 활성. 권장 (project-local 원칙과 일치) |
| `~/.claude/skills/ai-harness-review/SKILL.md` | 모든 프로젝트에서 활성. 글로벌 적용을 명시적으로 원할 때만 사용 |

채택 규칙:

- 자동 install 없음. ai-harness-toolset 은 사용자 동의 없이 `~/.claude/` 또는 `.claude/` 를 만들지 않는다.
- 복사 단위는 `SKILL.md` 한 파일이다. 폴더 이름 `ai-harness-review` 는 그대로 둔다 (Claude Code 가 폴더 이름으로 skill 을 식별한다).
- 업데이트는 source repo 의 `snippets/claude-skills/ai-harness-review/SKILL.md` 를 다시 복사하는 식이다. in-place 수정한 사본은 다음 복사 시 덮어 쓰여진다.
- 제거는 채택한 위치의 `ai-harness-review/` 디렉터리를 지우는 것이다. 그 외 글로벌 상태는 변경되지 않는다.

skill 이 적용된 후의 트리거는 자연어 의도다. `/skill ai-harness-review` 같은 슬래시 명령 형태를 강제하지 않는다. 위 7 절의 두 발화 예시가 그대로 트리거다.

skill 이 채택되어 있지 않은 환경에서도 toolset 자체는 동작한다. 그 경우 사용자는 9 절 이후의 raw PowerShell 명령을 직접 사용한다.

---

## 9. Operator command quickstart (fallback / debug / reference)

이 절의 명령은 일상 운용용이 아니라, 위 7-8 절의 자연어 UX 가 사용 불가능하거나 인자 조합을 직접 디버그해야 할 때를 위한 fallback / reference 다.

### source repo 모드 (이 repo 안에서 사용)

`H:/Work/ai-harness-toolset/ai-harness-toolset/` 안에서 실행한다고 가정한다.

```powershell
# 1. log tree 초기화 (한 번)
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/log-init.ps1

# 2. 단일 review cycle 실행
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/review-cycle.ps1 `
    -Stage implementation `
    -Purpose 'review change to scripts/review-cycle.ps1' `
    -TargetFiles scripts/review-cycle.ps1 `
    -Context '<short context for reviewer>' `
    -RequiredInspectionPaths 'scripts/review-cycle.ps1' `
    -ReviewQuestions '<one or more concrete questions>' `
    -Constraints '<explicit constraints>'
```

### target payload 모드 (다른 프로젝트에 복사 후 사용)

target project 의 root 디렉터리 안에서 실행한다고 가정한다.

```powershell
# 1. payload 복사 (한 번, 사용자가 직접 수행)
#    config/, scripts/, snippets/, templates/ -> <project-root>/.ai-harness/

# 2. log tree 초기화
powershell -NoProfile -ExecutionPolicy Bypass -File .ai-harness/scripts/log-init.ps1

# 3. <project-root>/.gitignore 에 log/ 포함 확인 (사용자 책임)

# 4a. 단일 파일 review cycle 실행
powershell -NoProfile -ExecutionPolicy Bypass -File .ai-harness/scripts/review-cycle.ps1 `
    -Stage implementation `
    -Purpose '<purpose>' `
    -TargetFiles <single-relative-file> `
    -Context '<context>' `
    -RequiredInspectionPaths '<paths>' `
    -ReviewQuestions '<questions>' `
    -Constraints '<constraints>'

# 4b. 다중 파일 review cycle 실행 — 라인당 한 경로씩 list 파일을 만들고 -TargetFilesPath 로 넘긴다
#     list 파일은 반드시 <project-root>/log/ 아래에 둔다. log-init.ps1 은 log/review-targets/ 를
#     자동 생성하지 않으므로, list 디렉터리는 사용자가 직접 만든다.
New-Item -ItemType Directory -Force -Path log/review-targets | Out-Null
@'
relative/path/one.ps1
relative/path/two.md
'@ | Out-File -FilePath log/review-targets/example.list -Encoding utf8

powershell -NoProfile -ExecutionPolicy Bypass -File .ai-harness/scripts/review-cycle.ps1 `
    -Stage implementation `
    -Purpose '<purpose>' `
    -TargetFilesPath log/review-targets/example.list `
    -Context '<context>' `
    -RequiredInspectionPaths '<paths>' `
    -ReviewQuestions '<questions>' `
    -Constraints '<constraints>'
```

`-TargetFiles` 를 생략하면 git status 의 tracked 변경 파일이 자동 사용된다. untracked 파일이 있으면 실패한다. 결정적 동작이 필요하면 `-TargetFiles` (단일 파일) 또는 `-TargetFilesPath` (다중 파일 list) 를 명시한다.

prepare 가 성공하면 입력 파일 목록은 `log/review/<run-id>/target-files.list` 에 informational snapshot 으로 보존된다. 따라서 외부 입력 `log/review-targets/<slug>.list` 는 prepare 직후 안전하게 삭제할 수 있고, 보존해도 무해하다. snapshot 은 freshness 검증 대상이 아니며 권위 source-of-truth 는 여전히 `meta.json.targetFiles[]` 다.

다중 파일 review 의 정식 입력 shape 은 `-TargetFilesPath` 다. 콤마로 결합된 단일 `-TargetFiles "a.txt,b.txt"` 값은 `review-cycle.ps1` 가 reviewer 호출 전에 거부한다 (`FAIL TargetFiles appears to be a comma-separated single string`). `-TargetFiles` 는 단일 파일만 지정하는 인자이며, 콤마를 포함하는 실제 단일 파일명 (예: `docs/a,b.md`) 은 그대로 허용된다. `review-cycle.ps1` 가 0 이 아닌 코드로 종료되면 자동 재실행하지 않는다. wrapper failure 를 보고하고 별도 scoped 승인을 받은 뒤에만 다시 실행한다. retry discipline 의 정식 출처는 `snippets/claude-skills/ai-harness-review/SKILL.md` 다.

PowerShell 에서 위 here-string 을 `Out-File -Encoding utf8` 로 쓰면 PS 5.1 에서는 기본적으로 BOM 이 붙는다. `review-cycle.ps1` 는 BOM 유무와 무관하게 list 파일을 읽는다. 더 엄격히 BOM 없이 만들고 싶으면 PS 7 이상에서 `-Encoding utf8NoBOM` 을 쓰거나, `[System.IO.File]::WriteAllText($path, $text, (New-Object System.Text.UTF8Encoding($false)))` 를 직접 사용한다.

---

## 9a. 이미 준비된 run-id 에 대해 reviewer 만 실행하는 경우

`scripts/review-run.ps1` 은 이미 prepare 된 `log/review/<run-id>/` 에 대해 reviewer 만 실행하는 보조 경로다. 일반 운용은 `scripts/review-cycle.ps1` 한 번으로 끝나므로, 다음과 같은 좁은 상황에서만 사용한다.

- prepare 와 input.md 채움까지는 별도로 완료해 둔 상태에서 reviewer 만 다시 실행하고 싶을 때.
- `scripts/review-prepare.ps1` 로 `<run-id>` 를 만들고 input.md 를 직접 편집한 뒤 reviewer 호출만 분리해서 수행하고 싶을 때.

소스 repo 모드 예시:

```powershell
# 1. 이미 prepare + input.md 채움이 끝난 <run-id> 가 있다고 가정.
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/review-run.ps1 -RunId <run-id>

# 2. 이전 reviewer 실행 결과를 명시적으로 덮어쓰며 재실행.
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/review-run.ps1 -RunId <run-id> -Force
```

target payload 모드에서는 `scripts/review-run.ps1` 을 `.ai-harness/scripts/review-run.ps1` 로 치환해 같은 인자로 실행한다.

동작 contract (요약):

- `review-run.ps1` 은 reviewer 실행 직전에 `review-input-verify.ps1` 을 내부적으로 호출한다. 사용자가 별도로 먼저 실행할 필요는 없다. 사용자가 미리 수동으로 `review-input-verify.ps1 -InputPath <run-id>/input.md` 를 실행해도 무방하다.
- `review-input-verify` 가 실패하면 (placeholder 잔존, heading 누락, `{{TOKEN}}` 잔존 등) `review-run` 은 Codex 를 호출하지 않고 FAIL 하며 `result.md` / `result.json` 을 만들지 않는다.
- `review-run` 은 새 `<run-id>` 를 만들지 않는다. 기존 prepare 된 `<run-id>` 위에서만 동작하며 존재하지 않으면 FAIL.
- `meta.json` 과 `input.md` 는 mutate 하지 않는다. write-once 원칙을 지킨다.
- `result.md` / `result.json` 이 이미 존재하면 기본적으로 FAIL 하며 사용자가 `-Force` 를 명시할 때에만 두 파일을 제거하고 재실행한다. 기존 verdict 무음 덮어쓰기는 없다.
- reviewer 실행 후 `review-verify.ps1` 의 default mode 와 `-RequireResult` mode 를 모두 호출하며 두 검증이 모두 PASS 일 때에만 `review-run: PASS` 로 종결한다.
- `log/chatlog/`, `log/evidence/`, source / target repo 의 글로벌 파일 (`~/.claude/`, root `CLAUDE.md`, root `AGENTS.md`) 은 어떤 경우에도 만들거나 수정하지 않는다.
- verdict (`yes` / `no` / `yes with risk`) 는 commit / push / publish / merge / release / deployment 를 자동 승인하지 않는다. 사용자가 별도로 결정하고 직접 실행한다.

`review-cycle.ps1` 과의 차이를 정리하면 다음과 같다.

| 항목 | `review-cycle.ps1` | `review-run.ps1` |
|---|---|---|
| 책임 | prepare + reviewer 실행 + verify 를 1회로 묶음 | 이미 prepare 된 `<run-id>` 에서 reviewer 실행 + verify 만 수행 |
| 새 `<run-id>` 생성 | 함 (없으면 자동 할당) | 안 함. 기존 prepared `<run-id>` 가 반드시 있어야 함 |
| `meta.json` 작성 | 함 (prepare 단계) | 안 함. 기존 값을 그대로 읽기만 함 |
| `input.md` 작성 / 치환 | 함 (placeholder 치환 포함) | 안 함. 사용자가 채운 그대로 사용 |
| `result.md` / `result.json` overwrite 정책 | 새 `<run-id>` 라 충돌 없음 | 이미 있으면 FAIL. `-Force` 명시 시에만 덮어씀 |
| BF / chatlog / evidence 영향 | 없음 | 없음 |

`review-run` 이 0 이 아닌 코드로 종료되면 자동 재실행하지 않는다. 실패 사유 (`review-input-verify` 실패, Codex 실패, verdict parse 실패, `review-verify` 실패) 를 보고하고, 보완 후 별도 scoped 승인을 받아 다시 실행한다. 같은 `<run-id>` 안의 file 을 사람이 직접 보정해 cycle 을 닫지 않는다 — 새 run-id 로 prepare 부터 다시 시작하는 것이 정식 복구 경로다.

---

## 10. review artifact 역할

`log/review/<run-id>/` 아래 4개 파일은 모두 generated read-only record 다. 사람이 손으로 수정하지 않는다.

| 파일 | 작성자 | 역할 |
|---|---|---|
| `meta.json` | `review-prepare.ps1` | run-id, target path, target SHA-256, source HEAD, stage, purpose, reviewer config, freshness policy. `targetFiles[]` 로 multi-file freshness binding 을 함께 기록한다. |
| `input.md` | `review-prepare.ps1` (template) + `review-cycle.ps1` (placeholder fill) | reviewer 가 보고 판단을 내리는 입력. `## Context`, `## Required inspection paths`, `## Review questions`, `## Constraints`, `## Final verdict` 5개 섹션이 채워져야 한다. |
| `result.md` | Codex CLI (`--output-last-message`) | reviewer 의 자유 형식 markdown 응답. 단, 정확히 1개의 `## Verdict` heading 과 그 다음 첫 비어있지 않은 줄에 `yes` / `no` / `yes with risk` 중 하나가 있어야 cycle 이 verdict 를 인정한다. |
| `result.json` | `review-cycle.ps1` (verdict parsing 성공 시) | machine-readable 최종 record. `verdict`, `runId`, `targetPath`, `targetSha256`, `inputSha256`, `resultMarkdownSha256`, `createdAtUtc`, `sourceHead`, `stage`, `purpose`, `reviewer`, `notes[]`, `schemaVersion`. |

전체 contract 는 `docs/REVIEW_RESULT_CONTRACT.md` 가 source-of-truth 다.

---

## 11. verdict handling

`result.md` 와 `result.json.verdict` 는 정확히 다음 세 값만 사용한다.

| verdict | 의미 | 사용자 행동 가이드 |
|---|---|---|
| `yes` | 검토 범위 내에서 진행 가능 | 다음 작업 단계로 이동. commit / push / release 는 여전히 별도 승인. |
| `yes with risk` | 진행 가능하나 명시된 risk 동반 | result.md 의 risk 항목을 읽고 사용자 본인이 risk 수용 여부를 판단. 자동 게이트 아님. |
| `no` | 검토 범위 내에서 진행 불가 | result.md 의 required changes / findings 를 사용자가 읽고 보정한 뒤, 새 `<run-id>` 로 다시 review-cycle 실행. |

parser 는 `Verdict: yes`, `Final verdict: yes`, prose 안의 verdict 등 inline 형태를 받지 않는다. 정확한 shape 만 통과한다.

---

## 12. commit / push / release 는 별도 승인이다

verdict 가 `yes` / `yes with risk` 라도 다음 작업은 자동으로 일어나지 않는다. 사용자가 직접 결정하고 직접 명령을 실행한다.

- `git commit`
- `git push`
- 어떤 형태의 publish, merge, release, deployment
- target project 의 글로벌 파일 변경

toolset 은 verdict 를 읽어서 git 동작이나 release 동작을 트리거하는 wrapper 를 제공하지 않는다 (`docs/REVIEW_RESULT_CONTRACT.md` 의 non-goals 절).

---

## 12b. Acceptance scenario 분리 — review 와 BF/chatlog 는 별도 평가 축

`ai-harness-toolset` 의 acceptance 는 단일 축이 아니다. 어떤 의도로 toolset 을 적용하느냐에 따라 기대되는 artifact 가 다르다. test repo 또는 dogfooding repo 에서 두 축을 혼동하면 잘못된 fail 판정을 내리기 쉽다.

기본 원칙:

- Pure review-loop acceptance 는 `log/chatlog/current/resume.md` 또는 `log/chatlog/current/summary.md` 의 존재를 요구하지 않는다.
- BF / chatlog artifact 는 BF save / closeout / handoff / restore-offer intent 가 명시적으로 scope 안에 있을 때에만 기대된다.
- pure review test repo 에서 `log/chatlog/current/` 가 비어 있는 것은 review subsystem 의 실패가 아니다.
- dogfooding target repo 라도, 채택한 snippet 또는 사용자 발화에 BF save / closeout 의도가 포함된 경우에만 `log/chatlog/current/` 파일이 생긴다.
- review artifact 와 BF / chatlog artifact 는 서로 다른 평가 축이다. 한 축의 부재 또는 fail 로 다른 축을 fail 처리하지 않는다.

시나리오별 기대 artifact:

| Scenario | 기대 artifact |
|---|---|
| Pure review-loop acceptance | `log/review/<run-id>/input.md`, `result.md`, `result.json`, `meta.json` |
| BF save / closeout acceptance | `log/chatlog/current/resume.md`, `log/chatlog/current/summary.md` |
| BF manual evidence acceptance | `log/evidence/<scope>/<case>/` |
| Source snapshot handoff | `snapshot.zip`, `manifest.json` (snapshot 내부에는 `log/` runtime artifact 를 포함하지 않는다) |

따라서 13 절의 checklist 는 review artifact 축만 점검한다. 같은 repo 에서 BF save / closeout 의도까지 dogfooding 하는 경우에만 `log/chatlog/current/resume.md` / `summary.md` 갱신을 별도 축으로 점검한다. 두 축의 fail 은 분리해서 보고한다.

본 MVP 의 BF Level 1/2 는 자동 복구가 아니라 사용자 자연어 trigger 에 의해 동작하는 documented / reviewed / manually accepted protocol 이다 (7b 절). BF Level 3 자동화 (hook / watcher / daemon / parser / `BF_STATE.json`) 는 post-MVP scope 이며 본 가이드 범위 밖이다.

---

## 13. MVP acceptance checklist

테스트 프로젝트에서 다음 항목을 실제로 실행하고, 모두 직접 확인되면 MVP 운용 가능 상태로 본다.

```text
[ ] target project 에 .ai-harness/ payload 4개 폴더만 복사했다.
[ ] target project 의 .gitignore 에 log/ 가 포함되어 있다.
[ ] .ai-harness/scripts/log-init.ps1 실행 후 log/{chatlog,evidence,review}/ 가 생성된다.
[ ] .ai-harness/scripts/review-cycle.ps1 한 번 호출만으로 한 cycle 이 끝난다.
[ ] log/review/<run-id>/ 아래 meta.json, input.md, result.md, result.json 4개가 모두 생긴다.
[ ] result.json.verdict 가 yes / no / yes with risk 중 정확히 하나다.
[ ] result.json.targetSha256 와 현재 target file SHA-256 이 일치한다 (review-verify default mode PASS).
[ ] result.json.inputSha256, resultMarkdownSha256 binding 이 review-verify -RequireResult mode 에서 PASS 한다.
[ ] verdict 가 yes 여도 toolset 이 commit / push / merge / release 를 자동으로 시도하지 않는다.
[ ] parsing 실패 / Codex 실패 시 그 <run-id> 가 디스크에 보존된다 (자동 삭제 없음).
[ ] 글로벌 파일 (~/.claude/, 글로벌 CLAUDE.md / AGENTS.md) 이 변경되지 않았다.
```

---

## 14. test project 에서 직접 평가하는 방법

추천 흐름:

1. 임시 git repo 1개를 만든다 (예: `H:/tmp/ai-harness-mvp-trial/`).
2. source repo 의 `config/`, `scripts/`, `snippets/`, `templates/` 4개 폴더를 그대로 복사해 `.ai-harness/` 아래에 둔다.
3. test repo 의 `.gitignore` 에 `log/` 한 줄을 추가한다.
4. `.ai-harness/scripts/log-init.ps1` 을 실행한다.
5. test repo 안의 임의 파일 1개에 사소한 변경을 만든다 (예: README.md 한 줄 추가).
6. `.ai-harness/scripts/review-cycle.ps1` 을 위 quickstart 예시처럼 실행한다.
7. `log/review/<run-id>/` 안의 4개 파일을 직접 열어 본다.
8. 위 13번 checklist 를 한 줄씩 직접 체크한다.

이 평가는 사용자의 환경과 Codex CLI 설치 상태에 의존한다. CLI 가용성 / 모델 지정은 `docs/CLI_ENVIRONMENT_ASSUMPTIONS.md`, reviewer config 의 우선순위는 `docs/REVIEWER_CONFIG_POLICY.md` 를 참조한다.

---

## 15. Known non-goals

다음은 MVP scope 가 아니다. 기대하지 말고, 그래서 빠진 것이다.

- 글로벌 install / 시스템 PATH 변경 / `~/.claude/` 파일 생성
- installer / packaged distribution / public release packaging
- watcher, hook, daemon, scheduler, CI integration
- auto-fix loop / retry / fallback model 자동 전환
- auto-commit, auto-push, auto-publish, auto-merge, auto-release, auto-deployment
- review history DB / cross-run aggregation / index
- review record 자동 retention (auto-prune, rotate, expire)
- multi-reviewer orchestration, `-Reviewer codex` 외 adapter
- target project 의 `CLAUDE.md` / `AGENTS.md` / `.gitignore` 자동 변경
- result schema 자동 validator, fuzzy verdict extraction

이 목록의 원천은 `docs/AI_HARNESS_TOOLSET_SCOPE.md` 와 `docs/REVIEW_RESULT_CONTRACT.md` 의 non-goals 절이다.

---

## 16. MVP complete: yes / no / yes with risk

위 13번 checklist 결과를 가지고 사용자 본인이 다음과 같이 판단한다.

- `yes` — 13번 모든 항목이 직접 확인되었고, 15번 non-goals 가 사용자 운용 시나리오와 충돌하지 않는다. MVP 종료 선언 가능.
- `yes with risk` — 13번 대부분이 통과했으나, Codex CLI 가용성 / 특정 모델 지정 / target project 의 환경 등에 알려진 제약이 남아 있다. 그 risk 를 명시적으로 받아들이는 조건에서 MVP 종료 가능.
- `no` — 13번 중 1개 이상이 실패한다. MVP 종료 선언 불가. 실패 항목을 fix 한 뒤 새 acceptance run 으로 재평가한다.

이 판단은 자동화하지 않는다. toolset 자체는 사용자가 직접 내리는 이 yes / yes with risk / no 결정을 대신하지 않는다.
