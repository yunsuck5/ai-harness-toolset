# Operator Guide (Korean)

> **현행 adoption 모델 안내.** 현재 adoption / default 방향은 **shared / global stable runtime ToolRoot** — channel 3, 즉 `%USERPROFILE%\.claude\ai-harness-toolset\current` 의 global stable install 이며 invocation 마다 resolve 된다. 본 guide 의 live 절차는 이 shared / global model 기준으로 정합화되어 있다. `.ai-harness/` project-local copy mode 절차는 **legacy project-local copy mode (channel 5)** 로 명확히 한정되어 남아 있다 — backward compatibility 로 계속 지원되지만 신규 프로젝트의 권장 adoption 형태는 아니다. 현행 모델의 source-of-truth 는 `docs/contracts/global-invocation/SHARED_GLOBAL_INVOCATION_CONTRACT.md`, `docs/systems/install-update/GLOBAL_INSTALL_UPDATE_MODEL.md`, 그리고 `README.md` 상단의 current adoption pointer 다.

이 문서는 `ai-harness-toolset` 의 **current / latest operator guide** 다 — 사용자 관점에서 toolset 을 운용하고 평가하기 위한 operator-facing 가이드다. 현행 shared / global 운용 절차를 본문 live 절차로 담고, MVP acceptance 절차는 §13–§16 의 acceptance section 으로 유지한다 (문서 전체 identity 는 MVP 전용이 아니다 — 이 파일은 `docs/MVP_OPERATOR_GUIDE_KR.md` 에서 `docs/user_guide/OPERATOR_GUIDE_KR.md` 로 rename 되었다).

대상 독자는 이 toolset 을 Claude Code 중심 워크플로에서 운용하려는 사용자다. 내부 개발자 문서가 아니다. 현행 adoption 은 shared / global stable runtime ToolRoot (channel 3) 이며, 일상 진입점은 §7 의 Claude Code 자연어 UX 다. raw PowerShell 명령은 §9 의 fallback / debug / reference 용이다. 자세한 contract / policy / migration 은 `docs/` 의 다른 파일을 참고한다.

설명은 한국어, 경로 / 파일명 / 스크립트명 / 명령어 / config key / verdict 문자열 등 식별자는 영문 그대로 둔다.

---

## 1. MVP 의 의미

이 repo 의 MVP 는 다음을 만족하는 상태를 가리킨다.

- toolset 의 lifecycle script 가 `<ToolRoot>` (현행 default: channel 3 global stable install) 에서 실행되면서, runtime artifact 는 `<ProjectRoot>` 의 `log/` 아래에만 생성된다.
- 한 번의 review pass 는 두 단계 entry script 호출로 닫힌다: `review-prepare.ps1 -ReviewTaskId <id> [-Pass <pass-NN>]` 가 canonical pass directory 를 발급하고 `input.md` 를 seed → AI 가 `input.md` 본문을 직접 작성 → `review-run.ps1 -ReviewTaskId <id> -Pass <pass-NN>` 가 `review-input-verify.ps1` 로 heading shape 를 검증한 뒤 Codex CLI 를 1 회 실행해 같은 pass directory 에 `result.md` 를 작성한다.
- 결과 record 는 `<project-root>/log/review/<review-task-id>/pass-NN/` 의 canonical pair (`input.md`, `result.md`) 두 파일로 닫힌다 (`docs/contracts/review/REVIEW_RESULT_CONTRACT.md`). `<review-task-id>` 는 하나의 `/goal` 작업 또는 하나의 review gate 단위이며 Claude Code chat / session id 가 아니다. `pass-NN` 는 같은 task 의 corrective loop 안에서의 각 Codex review attempt 다.
- 자동 commit / push / release 는 하지 않는다. verdict 는 사용자 판단 input 일 뿐 자동 게이트가 아니다.

MVP 는 productization 이 아니다. installer, watcher, hook, daemon, auto-fix loop, retention automation 은 명시적으로 out-of-scope 이다 (`docs/project/AI_HARNESS_TOOLSET_SCOPE.md`).

---

## 2. ToolRoot / ProjectRoot 와 운용 모드

이 toolset 은 `<ToolRoot>` (lifecycle script / config / templates / snippets 가 사는 위치) 와 `<ProjectRoot>` (작업 대상 repo, runtime artifact 가 `log/` 아래 생기는 위치) 를 분리한다. `<ToolRoot>` 는 invocation 마다 channel chain 으로 resolve 된다 (`docs/contracts/global-invocation/SHARED_GLOBAL_INVOCATION_CONTRACT.md`).

| 모드 | 의미 | `<ToolRoot>` | 위상 |
|---|---|---|---|
| shared / global | global stable install 을 모든 프로젝트가 공유 | `%USERPROFILE%\.claude\ai-harness-toolset\current` (channel 3) | **현행 default** |
| source-repo / dogfooding | `ai-harness-toolset` repo 자체에서 직접 사용 | `<repo-root>/` — channel 4 (multi-marker) 는 channel 3 이 부재할 때만 도달하므로, global stable install 이 있는 환경에서는 explicit `-ToolRoot <repo-root>` (channel 1) 로 지정 | source repo 운영자용 |
| legacy project-local copy | target 안에 payload 사본을 둔 경우 | `<project-root>/.ai-harness/` (channel 5) | legacy / backward compatibility (§3, §9 의 legacy 절) |

세 모드는 `<ToolRoot>` 가 어디로 resolve 되는지만 다르고 동작 contract 는 같다. channel resolution 순서는 channel 1 (`-ToolRoot`) → channel 2 (`AI_HARNESS_TOOL_ROOT` env) → channel 3 (global stable install) → channel 4 (dogfooding multi-marker) → channel 5 (legacy `.ai-harness/`) 다 (`docs/contracts/global-invocation/SHARED_GLOBAL_INVOCATION_CONTRACT.md`). 현행 default 인 shared / global 모드에서는 사용자가 `-ToolRoot` 인자나 `AI_HARNESS_TOOL_ROOT` 환경변수를 지정하지 않아도 channel 3 이 자동 resolve 된다. **channel 3 이 channel 4 보다 앞서므로**, source repo 운영자가 global stable install 이 materialize 된 환경에서 dogfooding 하려면 explicit `-ToolRoot` 로 repo root 를 지정해야 channel 3 이 channel 4 를 가리지 않는다. 일상 운용에서는 §7 의 Claude Code 자연어 UX 가 진입점이고, 사용자가 ToolRoot 경로를 직접 다룰 일은 없다.

source repo 의 `docs/`, `tests/`, `log/` 는 어떤 모드에서도 `<ProjectRoot>` 로 복사되지 않는다. `docs/*.md` 가 필요하면 source repo (또는 resolved ToolRoot) 쪽 파일을 본다.

---

## 3. (Legacy) `.ai-harness/` project-local copy mode payload 구조

> **legacy project-local copy mode only.** 본 절은 channel 5 — legacy project-local copy mode — 에만 적용된다. 현행 default 인 shared / global 모드 (§2) 에서는 target project 안에 source payload 를 복사하지 않는다. 신규 프로젝트는 본 절의 절차를 쓰지 않는다.

legacy project-local copy mode 를 쓰는 경우에 한해, target project 에 복사하는 4개 폴더는 다음과 같다. 그 외 항목은 복사하지 않는다.

| Source path | Target path |
|---|---|
| `config/` | `<project-root>/.ai-harness/config/` |
| `scripts/` | `<project-root>/.ai-harness/scripts/` |
| `snippets/` | `<project-root>/.ai-harness/snippets/` |
| `templates/` | `<project-root>/.ai-harness/templates/` |

규칙 (legacy mode):

- `docs/`, `tests/`, `log/`, `README.md`, `.gitattributes` 등은 복사하지 않는다.
- `.ai-harness/` 디렉터리만 지우면 그 project-local deployment 가 사라진다.
- 글로벌 `CLAUDE.md` / `AGENTS.md` 는 어떤 모드에서도 implicit / automatic 으로 변경되지 않는다. (explicit user-approved managed-block replacement 는 별도 governed scope 다 — `docs/decisions/GLOBAL_ADOPTION_DECISION.md` §6.)

`snippets/` 는 root 의 `CLAUDE.md` / `AGENTS.md` 에 사용자가 의도적으로 managed block 형태로 붙여 넣는 영문 payload 다. 자동 주입은 하지 않는다 (`README.md` 의 Snippets 절 참조).

---

## 4. `log/` runtime output 구조

runtime artifact 는 항상 `<project-root>/log/` 아래에만 생성된다.

```
<project-root>/log/
├── chatlog/   # 세션 작업 로그 (docs/contracts/chatlog/CHATLOG_CONTRACT.md)
├── evidence/  # 명령 / 테스트 / 실행 사실 (docs/contracts/evidence/EVIDENCE_CONTRACT.md)
└── review/    # review record (docs/contracts/review/REVIEW_RESULT_CONTRACT.md)
    └── <review-task-id>/
        ├── pass-01/
        │   ├── input.md   # AI-authored from templates/review-input.md
        │   └── result.md  # Codex-authored
        └── pass-02/       # only if the corrective loop adds another attempt
            ├── input.md
            └── result.md
```

- `log/` 는 runtime artifact tree 다. 절대 commit 하지 않는다.
- target project 의 `.gitignore` 에 `log/` 가 들어가 있는지 사용자가 직접 확인한다. toolset 은 target 의 `.gitignore` 를 만들지 않는다.
- `<review-task-id>` 는 하나의 `/goal` 작업 또는 하나의 review gate 단위다. Claude Code chat / session id 가 아니다. 한 세션 안에서 여러 `/goal` 이 진행되면 각각 별도의 `<review-task-id>/` 를 사용한다.
- `pass-NN` 은 같은 review task 안의 corrective loop attempt 다. 첫 attempt `pass-01`, 다음 `pass-02`, ... 로 증가한다. `review-prepare.ps1` 가 같은 task directory 의 기존 pass 를 스캔해 다음 번호를 자동 할당하거나, `-Pass <pass-NN>` 로 명시한다.
- review record 의 retention 단위는 `<review-task-id>/` 디렉터리 전체 또는 그 안의 개별 `pass-NN/` 디렉터리다. 사용자가 손으로 지운다. 자동 prune / rotate 는 없다.

`scripts/log-init.ps1` 을 한 번 실행하면 `log/`, `log/chatlog/`, `log/evidence/`, `log/review/` 4개 디렉터리가 생성된다.

---

## 5. 전체 pipeline diagram

```mermaid
flowchart TD
    A[user or AI changes files in project] --> B{review required?}
    B -- no --> Z1[no review needed]
    B -- yes --> P[scripts/review-prepare.ps1<br/>-ReviewTaskId &lt;id&gt; [-Pass &lt;pass-NN&gt;]<br/>allocate canonical pass directory<br/>&lt;review-task-id&gt;/pass-NN,<br/>seed input.md from templates/review-input.md]
    P --> C[Claude Code overwrites<br/>pass input.md<br/>with the actual review request]
    C --> R[scripts/review-run.ps1<br/>-ReviewTaskId &lt;id&gt; -Pass &lt;pass-NN&gt;]
    R --> F[scripts/review-input-verify.ps1<br/>required headings + no leftover placeholders]
    F -- fail --> X1[FAIL: write-once — allocate a new<br/>pass-NN under the same review-task-id<br/>(rerun review-prepare)]
    F -- pass --> G[Codex CLI exec, one-shot<br/>--output-last-message = result.md]
    G --> H[script checks result.md:<br/>exactly one '## Verdict' heading +<br/>first non-empty line is one of<br/>yes / no / yes with risk]
    H -- check fail --> X2[FAIL: failed pass preserved<br/>for inspection; allocate a new pass-NN]
    H -- check ok --> L{verdict}
    L -- yes --> M1[user decides next step]
    L -- yes with risk --> M2[user weighs risk and decides]
    L -- no --> M3[user fixes and allocates new pass-NN<br/>under the same review-task-id]
    M1 --> N[commit / push / release<br/>STILL require explicit user approval]
    M2 --> N
    M3 --> N
```

핵심 포인트:

- canonical review artifact 는 `log/review/<review-task-id>/pass-NN/input.md` 와 `log/review/<review-task-id>/pass-NN/result.md` 두 파일뿐이다. 다른 sidecar 파일은 contract 의 일부가 아니다 (`docs/contracts/review/REVIEW_RESULT_CONTRACT.md`).
- 한 번의 사용자 호출 = 한 번의 Codex 실행. retry / fallback model / auto-fix loop 없음.
- verdict 가 `yes` 여도 commit / push / publish / merge / release 자동 트리거 없음.
- parsing 실패한 pass 는 디스크에 그대로 남는다. 사람이 같은 pass directory 안의 파일을 손으로 보정하지 않고, 같은 `<review-task-id>/` 아래에 새 `pass-NN/` 를 만든다.
- 본 절과 §6 의 diagram 은 review 흐름을 mode-neutral 하게 기술한다. 실제 `<ToolRoot>` 위치 (현행 default: channel 3 global stable install) 는 §2 의 channel resolution 으로 결정된다 — shared / global, source-repo / dogfooding, legacy project-local copy 어느 모드에서도 흐름 자체는 동일하다.

---

## 6. Canonical review sequence

```mermaid
sequenceDiagram
    participant U as User
    participant CC as Claude Code (operator AI)
    participant RP as review-prepare.ps1
    participant RR as review-run.ps1
    participant RIV as review-input-verify
    participant CX as Codex CLI

    U->>CC: 자연어 의도 ("코덱스 리뷰 진행해")
    CC->>CC: scope / target files / context / review-task-id 결정
    CC->>RP: invoke once with -ReviewTaskId <id> [-Pass <pass-NN>]
    RP-->>CC: allocate canonical pass directory <review-task-id>/pass-NN;<br/>seed input.md from templates/review-input.md
    CC->>CC: overwrite pass input.md<br/>with the actual review request<br/>(templates/review-input.md as shape)
    CC->>RR: invoke once with -ReviewTaskId <id> -Pass <pass-NN>
    RR->>RIV: spawn -InputPath input.md
    RIV-->>RR: PASS or FAIL
    alt input verify FAIL
        RR-->>CC: FAIL — write-once: allocate new pass-NN<br/>under same review-task-id<br/>(rerun review-prepare)
    else input verify PASS
        RR->>CX: codex exec --sandbox read-only<br/>--output-last-message result.md, stdin = input.md
        CX-->>RR: writes pass result.md, exit 0
        RR->>RR: check exactly one "## Verdict" heading<br/>and first non-empty line is yes / no / yes with risk
        alt check FAIL
            RR-->>CC: FAIL, failed pass preserved
        else check OK
            RR-->>CC: PASS, <review-task-id>/pass-NN, verdict
            CC-->>U: 보고 (review-task path, final pass,<br/>verdict, corrective loop count, next decision)
        end
    end
```

`Codex CLI` 는 `--ask-for-approval never`, `--sandbox read-only`, `--output-last-message <result.md>`, `-c web_search=disabled`, `--model <model>` 로 호출된다. canonical artifact 는 `input.md` 와 `result.md` 두 파일뿐이며, 다른 sidecar 파일은 contract 의 일부가 아니다.

---

## 7. 일상 운용 UX 는 Claude Code CLI 자연어 의도다

`ai-harness-toolset` 의 일상 운용 진입점은 사용자가 Claude Code CLI 안에서 한국어 또는 영문으로 자연어 의도를 표현하는 것이다. 사용자는 일반적으로 raw PowerShell 명령을 직접 입력하지 않는다.

| 사용자 발화 (예시) | Target 모드 | Claude Code 가 수행하는 동작 |
|---|---|---|
| `현재 진행한 작업 코덱스 리뷰 진행해` | Mode A — changed files | git status / diff 확인 → 변경된 tracked 파일을 target 으로 결정 → 이 작업의 `<review-task-id>` 결정 → `review-prepare.ps1 -ReviewTaskId <id> [-Pass <pass-NN>]` 호출 (canonical pass directory 발급 + input.md seed) → pass `input.md` 본문 직접 작성 (`templates/review-input.md` 기준) → `review-run.ps1 -ReviewTaskId <id> -Pass <pass-NN>` 호출 (verify + Codex 1 회 실행) → pass `result.md` 의 `## Verdict` 확인 → review-task path / final pass / verdict / corrective loop count 보고. 변경 파일이 0 개면 중단 (Mode B 로 자동 전환하지 않음). |
| `현재 구현된 서버의 소켓 라이브러리를 니가 직접 리뷰하고, 그후에 코덱스 리뷰로 한번 더 리뷰후 최종 결론 도출해` | Mode B — tracked subsystem files | 호명된 subsystem 의 tracked 파일을 (현재 변경 여부와 무관하게) target 으로 결정 → 이 작업의 `<review-task-id>` 결정 → Claude 자체 리뷰 1회 → 위 Mode A 와 동일하게 `review-prepare` → 자체 리뷰 결과를 `## Context` / `## Review questions` 에 반영한 `input.md` 작성 → `review-run` 1 회 실행 → 두 결과를 병합하여 단일 최종 verdict 도출. |

Mode 선택 규칙은 SKILL.md step 2 에 명시되어 있다. subsystem 명이 너무 넓거나 매칭되는 파일이 없을 때만 Claude 가 1회 clarification 을 묻고, 그 외에는 자율로 진행한다. 어느 mode 에서도 Codex CLI 는 정확히 1 회만 실행되고, commit / push 는 하지 않는다.

이 자연어 UX 의 명세는 optional skill template `snippets/claude-skills/ai-harness-review/SKILL.md` 에 정의되어 있다. 아래 8 절을 참고한다.

8 절 이후의 raw PowerShell 명령은 다음 용도로만 사용한다.

- fallback (skill / Claude Code 가 없는 환경, 또는 비활성 상태)
- debug (특정 인자 조합을 직접 검증해야 할 때)
- 참고 reference (skill 이 내부적으로 합성하는 인자 형태를 사람이 읽기 위해)

raw 명령을 그대로 외워서 매번 입력하는 것은 권장하지 않는다.

---

## 7b. BF save / restore-offer 자연어 UX (현재 snippet protocol)

> **Note — source snippet alignment.** 본 절의 BF save / restore-offer protocol description 과 source `snippets/CLAUDE_SNIPPET.md` / `snippets/AGENTS_SNIPPET.md` 본문은 모두 `docs/contracts/brief/BRIEF_CONTRACT.md` / `docs/contracts/chatlog/CHATLOG_CONTRACT.md` 의 현행 (3차 reconciliation) framing 을 따른다 — canonical Brief 는 `<ProjectRoot>/log/brief/BRIEF.md` 한 자리이고 root `<ProjectRoot>/brief/` 는 rejected, user-home operator-local runtime root 도 rejected, target persistent footprint 는 `<ProjectRoot>/log/` only 다. 운영자가 이전 라운드에 destination `CLAUDE.md` / `AGENTS.md` 의 managed block 에 적용한 본문은 그 시점의 snippet 본문을 그대로 가지고 있으며, source snippet 본문이 갱신된 뒤에도 자동으로 refresh 되지 않는다 — destination managed-block refresh 는 사용자 명시 승인을 요구하는 별도 managed-block replacement step 이다 (`docs/decisions/GLOBAL_ADOPTION_DECISION.md` §6). 본 가이드 / contract docs / source snippet 본문과 destination managed block 의 framing 이 충돌하면, refresh 가 적용될 때까지 **현행 contract docs (`docs/contracts/brief/BRIEF_CONTRACT.md`, `docs/contracts/chatlog/CHATLOG_CONTRACT.md`) 의 framing 이 우선** 한다.

`ai-harness-toolset` 의 일상 운용에서 사용자는 raw PowerShell 명령을 직접 입력하지 않고, Claude Code 안에서 자연어 의도를 표현한다. 채택된 snippet 이 활성화되어 있으면 Claude Code 는 그 protocol 에 따라 Brief artifact 를 갱신한다.

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

이 의도가 감지되면 Claude Code 는 현재 source snippet protocol (BF Level 1/2 manual save discipline) 에 따라 다음 절차를 수행한다.

1. repo 상태 확인 (`pwd`, git top-level, branch, HEAD, origin/main, status).
2. 현재 상태 / 마지막 완료 action / 다음 단일 action / do-not-do / pending user decision 을 정리.
3. `<project-root>/log/brief/BRIEF.md` (canonical Brief — project-local runtime artifact, gitignored under `log/`) 를 manual save 로 직접 갱신. `docs/contracts/brief/BRIEF_CONTRACT.md` 의 canonical heading set 을 그대로 사용. root `<project-root>/brief/` 는 만들지 않는다 (rejected).
4. 관련 review / evidence / Chatlog artifact 는 path / link 로만 참조 — 본문 인라인 금지.
5. Brief 는 짧게 유지. 상세 내용이 필요하면 path 만 가리킨다.
6. `log/chatlog/current/resume.md` / `summary.md` 자리는 **갱신하지 않는다** (legacy / deprecation candidate; `docs/contracts/chatlog/CHATLOG_CONTRACT.md`).
7. 갱신된 파일과 남은 risk 를 사용자에게 보고.

이 절차에서 Claude Code 는 사용자가 어떤 raw PowerShell 명령도 직접 입력하지 않도록 한다. 사용자가 명시적으로 "직접 PowerShell 로 갱신하겠다" 라고 의사를 밝히지 않는 한 자연어 발화 한 줄로 BF 저장이 완료되어야 한다.

### 새 Claude Code 세션 진입 시 — restore-offer (manual discipline)

사용자가 같은 프로젝트에서 새 Claude Code 세션을 열면 manual restore-offer discipline 은 다음과 같다. 본 흐름은 채택된 snippet 에 의존하며, deterministic restore-offer automation (BF Level 3) 은 미구현이다.

1. Claude Code 가 canonical Brief 의 존재 여부를 확인한다.
   - 자리: `<project-root>/log/brief/BRIEF.md` (canonical Brief; `docs/contracts/brief/BRIEF_CONTRACT.md`). project-local runtime artifact, gitignored under `log/`. 단일 자리이며 fallback 자리를 두지 않는다. root `<project-root>/brief/` 와 user-home operator-local runtime root 는 자리가 아니다.
2. 어떤 자리에서든 Brief 가 읽히면 그 파일을 기준으로 한국어로 현재 상태 / 다음 단일 action / do-not-do / pending user decision 을 요약 보고.
   - read-only helper `scripts/brief-status.ps1` 가 manual discipline 의 deterministic input 으로 사용 가능하다 (`docs/contracts/brief/BRIEF_CONTRACT.md` §"source-side primitive 책임" 의 `brief-status.ps1`). file presence + shape 결과 (delegated to `brief-check.ps1`) + required heading 별 첫 비어있지 않은 본문 줄을 Korean label 과 함께 stdout 으로 출력한다. 호출 시점, confirm UX, stale 판단은 여전히 agent / 사용자의 책임이며 helper 가 자동화하지 않는다. helper 호출은 강제가 아니다 — Brief 본문을 직접 읽어 요약하는 manual 흐름도 그대로 유효하다.
3. 사용자에게 `이 복구 지점에서 이어서 진행할까요?` 라고 묻는다.
4. 사용자 확인 전에는 의미 있는 작업을 실행하지 않는다.

canonical Brief 가 없으면 **Chatlog 로 default-restore 하지 않는다.** raw transcript / 누적 Chatlog 본문을 읽어 Brief 를 임의로 재구성하지 않고, Brief 부재를 사용자에게 보고한 뒤 다음 행동을 묻는다. 사용자가 명시적으로 Chatlog 로부터의 reconstruction 을 요청한 경우에 한해, Chatlog 를 evidence 로 다루고 사용자가 검토할 Brief draft 를 만들어 제출한다 — Brief 자리를 단정적으로 채우지 않는다.

### BF Level 의 의미와 자동화 경계

BF Level 은 path 가 아니라 **save / restore capability maturity** 다 (`docs/contracts/brief/BRIEF_CONTRACT.md`).

- BF Level 1/2 — manual save / restore discipline. Operator 는 BF 저장 / 복원 시점의 **trigger / approve / reject / discard** 주체이며, BRIEF 본문을 손으로 편집하지 않는다. BRIEF 본문의 생성 / 갱신은 명시적 AI-assisted command flow (snippet protocol 을 따르는 agent 의 직접 작성) 또는 deterministic tooling 이 담당하고, 새 session 진입 시 그 자리를 다시 읽어 작업을 복원한다. snippet protocol 의 BF save / restore-offer 흐름이 그 한 형태다.
- BF Level 3 — deterministic Brief maintenance / validation / stale warning / session-start guidance / restore-offer 의 자동화. **현재 미구현** 이며 future scoped work 다. 본 가이드 범위 밖이다.

본 가이드 / 본 MVP 가 도입하지 않는 것:

- hook, session-start automation, on-stop hook, on-prompt-submit hook, watcher, daemon, scheduler.
- 사용자 prompt 자동 capture, assistant 응답 자동 capture, transcript JSONL parser, `BF_STATE.json` 같은 별도 state machine.
- `~/.claude/settings.json` 또는 글로벌 `CLAUDE.md` / `AGENTS.md` 의 implicit / automatic mutation. 모든 snippet payload 는 사용자가 명시적으로 채택한 경우에만 활성화된다.
- Chatlog fuller implementation — 누적 work history 자동화, 자체 schema, retention, browse UI, RND-style heavy workflow — 는 본 가이드 범위 밖이며 later track 이다 (`docs/contracts/chatlog/CHATLOG_CONTRACT.md`).
- snippet protocol 의 writer destination 정합화는 더 이상 future scoped work 항목이 아니다. canonical Brief 자리 (`<project-root>/log/brief/BRIEF.md`) 와 primitive / contract 의 destination 이 이미 일치한다. (이전 라운드의 "target canonical (`brief/BRIEF.md`) 로 routing" 항목은 2차 reconciliation 의 잔재였으며, 3차 reconciliation 으로 자연 해소되었다 — `docs/contracts/brief/BRIEF_CONTRACT.md` §"canonical Brief 자리" Historical lineage 참조.)

위 7b 본문의 UX 는 현행 (3차 reconciliation) contract docs (`docs/contracts/brief/BRIEF_CONTRACT.md`, `docs/contracts/chatlog/CHATLOG_CONTRACT.md`) 의 framing 을 따르고, source `snippets/CLAUDE_SNIPPET.md` / `snippets/AGENTS_SNIPPET.md` 본문도 같은 3차 framing 으로 정합화되어 있다. 운영자가 이전 라운드에 destination `CLAUDE.md` / `AGENTS.md` 의 managed block 에 적용한 본문은 그 시점의 snippet 을 가지고 있으며, source snippet 본문이 갱신된 뒤에도 자동으로 refresh 되지 않는다 — destination managed-block refresh 는 사용자 명시 승인이 필요한 별도 managed-block replacement step 이다 (위 절두 note 참조). framing 충돌 시 현행 contract docs 가 우선이다.

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

본 절의 명령은 일상 운용용이 아니라, §7-§8 의 자연어 UX 가 사용 불가능하거나 인자 조합을 직접 디버그해야 할 때를 위한 fallback / reference 다. 일상 운용은 §7 의 자연어 의도가 정식 entrypoint 이며, 진입 script 두 개를 두 단계로 호출한다 — (a) `scripts/review-prepare.ps1 -ReviewTaskId <id> [-Pass <pass-NN>]` 로 canonical pass directory 발급 + input.md seed → (b) AI 가 pass `input.md` 본문 작성 → (c) `scripts/review-run.ps1 -ReviewTaskId <id> -Pass <pass-NN>` 로 verify + Codex 1 회 실행.

canonical artifact 는 `<ProjectRoot>/log/review/<review-task-id>/pass-NN/input.md` 와 `<ProjectRoot>/log/review/<review-task-id>/pass-NN/result.md` 두 파일뿐이다. 다른 sidecar 파일은 contract 의 일부가 아니다 (`docs/contracts/review/REVIEW_RESULT_CONTRACT.md`).

### shared / global 모드 (현행 default)

target project 의 root 디렉터리 안에서 실행한다고 가정한다. channel 3 global stable install (`%USERPROFILE%\.claude\ai-harness-toolset\current`) 이 materialize 되어 있으면 `-ToolRoot` / `AI_HARNESS_TOOL_ROOT` 없이 channel 3 이 자동 resolve 되고, ProjectRoot 는 CWD 로 잡힌다. global stable install 의 materialize / update 자체는 `docs/systems/install-update/GLOBAL_INSTALL_UPDATE_MODEL.md` 의 install / update 모델을 따른다.

```powershell
# 1. log tree 초기화 (한 번, target project 안에서)
powershell -NoProfile -ExecutionPolicy Bypass `
    -File "$env:USERPROFILE\.claude\ai-harness-toolset\current\scripts\log-init.ps1"

# 2. <project-root>/.gitignore 에 log/ 포함 확인 (사용자 책임)

# 3. review 진입 (canonical 두 단계 흐름; 운영자 / AI 가 <review-task-id> 와 pass-NN 을 미리 결정):
#    (a) review-prepare.ps1 -ReviewTaskId <id> [-Pass <pass-NN>] -Stage <stage> -Purpose <line>
#        호출 -- canonical <review-task-id>/pass-NN/ pass directory 를 발급하고
#        input.md 를 templates/review-input.md 로부터 seed.
#        -Pass 가 생략되면 같은 task directory 의 기존 pass 를 스캔해 다음 번호를 자동 할당.
#    (b) AI 가 pass input.md 본문을 review request 로 직접 작성.
#    (c) review-run.ps1 -ReviewTaskId <id> -Pass <pass-NN> 호출 -- review-input-verify.ps1
#        로 heading shape 를 검증한 뒤 Codex CLI 를 1 회 실행, 같은 pass directory 에
#        result.md 를 작성하고 `## Verdict` shape 를 검증.
#    canonical contract 는 두 파일 (input.md, result.md) 외의 어떤 sidecar artifact 도
#    보장하지 않는다.
#    정확한 entry point / 인자 조합 reference 는
#    snippets/claude-skills/ai-harness-review/SKILL.md step 3-5 를 따른다.
```

### source repo 모드 (dogfooding)

`ai-harness-toolset` source repo 자체 안에서 실행하는 경우다. source repo 운영자용이며, target 소비자는 쓰지 않는다. channel 4 (dogfooding multi-marker) 는 channel 3 (global stable install) 이 부재할 때만 도달하므로, global stable install 이 materialize 된 환경에서 source repo 를 ToolRoot 로 쓰려면 explicit `-ToolRoot` (channel 1) 로 repo root 를 지정한다 — 그래야 channel 3 이 channel 4 를 가리지 않는다.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/log-init.ps1
# 위 shared / global 모드의 review 진입 두 단계 흐름과 동일하게:
#   (a) -File scripts/review-prepare.ps1 -ToolRoot (Get-Location).Path `
#       -ReviewTaskId <id> [-Pass <pass-NN>] -Stage <stage> -Purpose <line>
#       (canonical <review-task-id>/pass-NN/ pass directory 가 만들어진다.)
#   (b) AI 가 log/review/<review-task-id>/pass-NN/input.md 본문 직접 작성
#   (c) -File scripts/review-run.ps1 -ToolRoot (Get-Location).Path `
#       -ReviewTaskId <id> -Pass <pass-NN>
# -ToolRoot 로 repo root 를 명시해 channel 3 global stable install 유무와 무관하게
# 결정적으로 dogfooding 한다.
```

### (Legacy) project-local copy mode

> **legacy project-local copy mode only.** 본 절은 channel 5 에만 적용된다. 현행 default 인 shared / global 모드는 위 절을 쓴다. 신규 프로젝트는 본 절을 쓰지 않는다.

§3 의 legacy 절차로 `.ai-harness/` payload 를 복사해 둔 경우, script 경로만 `<project-root>/.ai-harness/scripts/<name>.ps1` 로 바뀌고 두 단계 review 진입 흐름과 input.md / result.md 의 canonical contract 는 위 shared / global 예시와 동일하다.

### 입력 작성 시 주의 사항

- 각 pass directory 안의 `input.md` (canonical 자리: `log/review/<review-task-id>/pass-NN/input.md`) 는 AI 가 직접 본문을 작성한다. `## Context`, `## Required inspection paths`, `## Review questions`, `## Constraints`, `## Final verdict` 5 개의 H2 heading 이 모두 있어야 하고, `## Final verdict` 본문은 `yes / no / yes with risk` 문자열을 포함한다. 빈 본문, `{{TOKEN}}` 잔존, `scripts/review-input-verify.ps1` 의 forbidden-phrase 목록 (`$forbidden` 배열) 의 어떤 substring 도 있으면 거부된다.
- target file 목록은 input.md 안의 informational `## Target files` section 에 둔다. 별도의 staging file 이나 외부 list file 은 본 contract 가 보장하지 않는다.
- AI-to-Codex 의 운반 매체는 input.md (Markdown) 하나다. 본문에 한국어 / multi-line / markdown bullets / 인용 부호가 자유롭게 들어갈 수 있다. PowerShell argv 의 quoting / tokenization 은 운반 경로가 아니다.

---

## 10. review artifact 역할

canonical review artifact 는 `log/review/<review-task-id>/pass-NN/` 의 두 파일 — `input.md` (Claude Code 작성) 와 `result.md` (Codex 작성) — 뿐이며, 다른 sidecar 는 contract 의 일부가 아니다. 두 파일의 작성자 / required heading / shape 등 **전체 계약은 `docs/contracts/review/REVIEW_RESULT_CONTRACT.md` 가 source-of-truth** 다 — 본 절은 그 계약을 중복 정의하지 않고 그곳으로 routing 한다. removed-legacy artifact shape 의 historical reference 는 `docs/archive/backlog/review.md` / `docs/archive/backlog/operations.md` 에 격리되어 있으며 operator path 가 아니다.

---

## 11. verdict handling

`result.md` 의 `## Verdict` 다음 첫 줄은 `yes` / `no` / `yes with risk` 중 정확히 하나다 (lowercase 정확 매치; `Verdict: yes` 같은 inline 형태 거부). 운영 관점 요약: `yes` → 다음 단계로 진행 (commit / push / release 는 별도 승인), `yes with risk` → `result.md` 의 `## Risks` 를 읽고 사용자가 수용 여부 판단 (자동 게이트 아님), `no` → `## Findings` 를 보정한 뒤 같은 `<review-task-id>` 아래 새 `pass-NN` 으로 재실행. verdict vocabulary 와 parsing 규칙의 source-of-truth 는 **`docs/contracts/review/REVIEW_RESULT_CONTRACT.md`** 다.

---

## 12. commit / push / release 는 별도 승인이다

verdict 가 `yes` / `yes with risk` 라도 `git commit` / `git push` / 어떤 형태의 publish · merge · release · deployment / target 의 글로벌 파일 변경은 자동으로 일어나지 않는다 — 사용자가 직접 결정하고 직접 실행한다. toolset 은 verdict 를 읽어 git 동작이나 release 를 트리거하는 wrapper 를 제공하지 않는다 (**`docs/contracts/review/REVIEW_RESULT_CONTRACT.md`** §10 non-goals).

---

## 12b. Acceptance scenario 분리 — review 와 BF/chatlog 는 별도 평가 축

`ai-harness-toolset` 의 acceptance 는 단일 축이 아니다. 어떤 의도로 toolset 을 적용하느냐에 따라 기대되는 artifact 가 다르다. test repo 또는 dogfooding repo 에서 두 축을 혼동하면 잘못된 fail 판정을 내리기 쉽다.

기본 원칙:

- Pure review-loop acceptance 는 BF artifact 또는 Chatlog artifact 의 존재를 요구하지 않는다.
- BF / Chatlog artifact 는 BF save / closeout / handoff / restore-offer intent 가 명시적으로 scope 안에 있을 때에만 기대된다.
- pure review test repo 에서 `log/chatlog/` 가 비어 있는 것은 review subsystem 의 실패가 아니다.
- dogfooding target repo 라도, 채택한 snippet 또는 사용자 발화에 BF save / closeout 의도가 포함된 경우에만 BF save protocol 이 `<ProjectRoot>/log/brief/BRIEF.md` (canonical Brief — project-local runtime artifact, gitignored under `log/`) 자리에 manual save 를 수행한다. root `<ProjectRoot>/brief/` 는 만들지 않는다 (rejected). `log/chatlog/current/resume.md` / `summary.md` 는 protocol 의 갱신 대상이 아니다 — legacy / deprecation candidate 분류 (`docs/contracts/chatlog/CHATLOG_CONTRACT.md`).
- review artifact 와 BF / Chatlog artifact 는 서로 다른 평가 축이다. 한 축의 부재 또는 fail 로 다른 축을 fail 처리하지 않는다.

시나리오별 기대 artifact:

| Scenario | 기대 artifact |
|---|---|
| Pure review-loop acceptance | `log/review/<review-task-id>/pass-NN/input.md`, `log/review/<review-task-id>/pass-NN/result.md` (canonical two-level layout) |
| BF save / closeout acceptance | `<ProjectRoot>/log/brief/BRIEF.md` (canonical Brief — project-local runtime artifact, gitignored under `log/`). BF save protocol 의 갱신 대상도 이 자리이며, root `<ProjectRoot>/brief/` 는 만들지 않는다 (rejected). `log/chatlog/current/resume.md` / `summary.md` 는 갱신 대상이 아니다 (legacy / deprecation candidate, `docs/contracts/chatlog/CHATLOG_CONTRACT.md`). |
| BF manual evidence acceptance | `log/evidence/<scope>/<case>/` |
| Source snapshot handoff | `snapshot.zip`, `manifest.json` (snapshot 내부에는 `log/` runtime artifact 를 포함하지 않는다) |

따라서 13 절의 checklist 는 review artifact 축만 점검한다. 같은 repo 에서 BF save / closeout 의도까지 dogfooding 하는 경우에만 `<ProjectRoot>/log/brief/BRIEF.md` 갱신을 별도 축으로 점검한다. 두 축의 fail 은 분리해서 보고한다.

BF Level 은 path 가 아니라 save / restore capability maturity 다 (`docs/contracts/brief/BRIEF_CONTRACT.md`). BF Level 1/2 는 manual save / restore discipline 이고, BF Level 3 (deterministic Brief maintenance / validation / stale warning / session-start guidance / restore-offer) 는 미구현 future scoped work 다. daemon / watcher / scheduler / parser / `BF_STATE.json` 같은 자동화는 본 가이드 범위 밖이다 (7b 절).

---

## 13. Acceptance checklist (shared / global 모드)

테스트 프로젝트에서 다음 항목을 실제로 실행하고, 모두 직접 확인되면 운용 가능 상태로 본다. 본 checklist 는 현행 default 인 shared / global 모드 기준이다. legacy project-local copy mode 의 checklist 는 §13a 부록을 본다.

```text
[ ] channel 3 global stable install (%USERPROFILE%\.claude\ai-harness-toolset\current) 이 존재하고 lifecycle script 를 보유한다.
[ ] target project 의 .gitignore 에 log/ 가 포함되어 있다.
[ ] target project 안에서 log-init.ps1 (channel 3 경로) 실행 후 log/{chatlog,evidence,review}/ 가 생성된다.
[ ] AI 가 사용자의 자연어 의도로부터 review-prepare.ps1 -ReviewTaskId <id> [-Pass <pass-NN>] 호출 -> pass input.md 본문 직접 작성 -> review-run.ps1 -ReviewTaskId <id> -Pass <pass-NN> 호출의 두 단계로 한 pass review 를 닫는다.
[ ] 두 단계 모두 channel 3 global stable install 로 자동 resolve 되거나 명시적 -ToolRoot 로 결정된다.
[ ] 운영자 / AI 가 <review-task-id> (한 /goal 작업 또는 한 review gate 단위) 와 pass-NN (corrective loop attempt) 을 결정해 보고한다.
[ ] runtime artifact 가 ProjectRoot 의 log/ 아래에만 생성되고, ToolRoot (channel 3 payload) 는 변경되지 않는다.
[ ] 각 pass directory <review-task-id>/pass-NN 아래 canonical artifact 두 파일 (input.md, result.md) 이 모두 존재한다.
[ ] result.md 의 ## Verdict 다음 첫 줄이 yes / no / yes with risk 중 정확히 하나다.
[ ] verdict 가 yes 여도 toolset 이 commit / push / merge / release 를 자동으로 시도하지 않는다.
[ ] Codex 실패 / verdict shape 실패 시 그 pass directory 가 디스크에 보존된다 (자동 삭제 없음).
[ ] global CLAUDE.md / AGENTS.md 가 implicit / automatic 으로 변경되지 않았다.
```

### 13a. (Legacy) project-local copy mode acceptance checklist 부록

legacy project-local copy mode (channel 5) 를 평가하는 경우에만 본 부록을 쓴다. 현행 default 평가에는 사용하지 않는다.

```text
[ ] target project 에 .ai-harness/ payload 4개 폴더만 복사했다.
[ ] target project 의 .gitignore 에 log/ 가 포함되어 있다.
[ ] .ai-harness/scripts/log-init.ps1 실행 후 log/{chatlog,evidence,review}/ 가 생성된다.
[ ] .ai-harness/scripts/review-prepare.ps1 -ReviewTaskId <id> [-Pass <pass-NN>] 호출 -> AI 가 pass input.md 본문 직접 작성 -> .ai-harness/scripts/review-run.ps1 -ReviewTaskId <id> -Pass <pass-NN> 호출의 두 단계로 한 pass review 가 닫힌다.
[ ] 각 pass directory <review-task-id>/pass-NN 아래 canonical artifact 두 파일 (input.md, result.md) 이 모두 존재한다.
[ ] verdict 형식 검증 항목은 위 shared / global checklist 와 동일하다.
```

---

## 14. test project 에서 직접 평가하는 방법

추천 흐름 (shared / global 모드):

1. 임시 git repo 1개를 만든다 (예: `H:/tmp/ai-harness-trial/`).
2. channel 3 global stable install 이 `%USERPROFILE%\.claude\ai-harness-toolset\current` 에 materialize 되어 있는지 확인한다 (없으면 `docs/systems/install-update/GLOBAL_INSTALL_UPDATE_MODEL.md` 의 install 모델에 따라 준비).
3. test repo 의 `.gitignore` 에 `log/` 한 줄을 추가한다.
4. test repo 안에서 channel 3 의 `log-init.ps1` 을 실행한다 (§9 의 shared / global 예시).
5. test repo 안의 임의 파일 1개에 사소한 변경을 만든다 (예: README.md 한 줄 추가).
6. Claude Code 에 자연어로 review 의도를 표현한다 (`현재 진행한 작업 코덱스 리뷰 진행해`). Claude Code 는 이 작업의 `<review-task-id>` 와 `pass-NN` 을 결정한 뒤 `review-prepare.ps1 -ReviewTaskId <id> [-Pass <pass-NN>]` 호출 → pass `input.md` 본문 직접 작성 → `review-run.ps1 -ReviewTaskId <id> -Pass <pass-NN>` 호출의 두 단계 흐름으로 한 pass review 를 닫는다.
7. 해당 pass directory 안의 `input.md` 와 `result.md` 를 직접 열어 본다.
8. 위 §13 checklist 를 한 줄씩 직접 체크한다. legacy project-local copy mode 를 평가할 때만 §13a 부록을 추가로 쓴다.

이 평가는 사용자의 환경과 Codex CLI 설치 상태에 의존한다. CLI 가용성 / 모델 지정은 `docs/policies/CLI_ENVIRONMENT_ASSUMPTIONS.md`, reviewer config 의 우선순위는 `docs/policies/REVIEWER_CONFIG_POLICY.md` 를 참조한다.

---

## 15. Known non-goals

다음은 MVP scope 가 아니다. 기대하지 말고, 그래서 빠진 것이다.

- 시스템 PATH 변경 / system-wide CLI 등록 / packaged installer 자동 실행. (현행 shared / global adoption 의 channel 3 global stable install `%USERPROFILE%\.claude\ai-harness-toolset\current` 은 Claude Code 가 사용자 요청으로 materialize 하는 deliberate install 이지, 시스템 PATH 나 system-wide CLI 등록이 아니다 — `docs/systems/install-update/GLOBAL_INSTALL_UPDATE_MODEL.md`.)
- global `CLAUDE.md` / `AGENTS.md` 의 implicit / automatic / whole-file 변경. explicit user-approved managed-block replacement 는 별도 governed scope 다 (`docs/decisions/GLOBAL_ADOPTION_DECISION.md` §6).
- installer / packaged distribution / public release packaging
- watcher, hook, daemon, scheduler, CI integration
- auto-fix loop / retry / fallback model 자동 전환
- auto-commit, auto-push, auto-publish, auto-merge, auto-release, auto-deployment
- review history DB / cross-run aggregation / index
- review record 자동 retention (auto-prune, rotate, expire)
- multi-reviewer orchestration, `-Reviewer codex` 외 adapter
- target project 의 `CLAUDE.md` / `AGENTS.md` / `.gitignore` 자동 변경
- result schema 자동 validator, fuzzy verdict extraction

이 목록의 원천은 `docs/project/AI_HARNESS_TOOLSET_SCOPE.md` 와 `docs/contracts/review/REVIEW_RESULT_CONTRACT.md` 의 non-goals 절이다.

---

## 16. MVP complete: yes / no / yes with risk

위 13번 checklist 결과를 가지고 사용자 본인이 다음과 같이 판단한다.

- `yes` — 13번 모든 항목이 직접 확인되었고, 15번 non-goals 가 사용자 운용 시나리오와 충돌하지 않는다. MVP 종료 선언 가능.
- `yes with risk` — 13번 대부분이 통과했으나, Codex CLI 가용성 / 특정 모델 지정 / target project 의 환경 등에 알려진 제약이 남아 있다. 그 risk 를 명시적으로 받아들이는 조건에서 MVP 종료 가능.
- `no` — 13번 중 1개 이상이 실패한다. MVP 종료 선언 불가. 실패 항목을 fix 한 뒤 새 acceptance run 으로 재평가한다.

이 판단은 자동화하지 않는다. toolset 자체는 사용자가 직접 내리는 이 yes / yes with risk / no 결정을 대신하지 않는다.

---

## 17. Post-MVP CLI-only operating notes

본 절은 `ai-harness-toolset` 의 일상 CLI-only 운용 권고를 모은다. §1–§16 의 scope 정의와 acceptance 절차 — 특히 §13–§16 의 MVP acceptance section — 는 본 active operator guide 의 일부로 그대로 유효하며, 본 절은 그 위에 일상 운용 규칙을 정리한다. CLI-only MVP 단계 자체는 closed 상태이고 (`docs/decisions/POST_MVP_PLAN.md` §1 closeout), 본 절의 권고는 그 closeout 이후의 운용을 다룬다.

### Operating mode

- CLI-only MVP 는 **closed** 상태다 (`docs/decisions/POST_MVP_PLAN.md` §1). post-MVP 작업은 MVP scope 를 다시 열지 않는다.
- 일상 작업은 target adoption 시작 시점부터 **CLI-first / CLI-only** 다. 입구는 §7 의 Claude Code CLI 자연어 의도 UX 이고, raw PowerShell 명령은 §9 의 fallback / debug / reference 용이다.
- ChatGPT Web 은 일상 prompt 작성자가 아니다. milestone 감수 / 방향 검증 / handoff 리뷰의 외부 보조 채널로만 쓴다.

### review 의 운영 위치 (재확인)

- toolset 의 review 진입 script 는 quality gate 다. commit / push / publish / merge / release / upload / deployment 의 자동 승인이 아니다 (§12 와 동일).
- canonical artifact 두 파일 (`input.md`, `result.md`) 이 모두 존재하고 `result.md` 의 `## Verdict` 가 본 contract 의 vocabulary 안에 있을 때에만 다음 operator 결정의 input 으로 사용한다 (§10, §13).
- effort / cost 통제는 `docs/policies/REVIEW_EFFORT_GUIDE.md` 의 권고를 따른다. 본 가이드는 그 contract 를 재정의하지 않는다.

### Verdict 처리 (post-MVP 운용 관점)

§11 의 verdict 표를 post-MVP 운용 절차 wording 으로 다시 명시한다.

- `yes` — 다음 operator 결정 (commit / push / release 등) 의 준비 상태를 보고한다. 자동 진행하지 않는다.
- `yes with risk` — result.md 의 risk 항목을 인용해 사용자에게 보고하고, 명시적 go / no-go 를 묻는다.
- `no` — scoped fix plan 을 제안하고 사용자 승인을 기다린다. 자동 corrective pass 는 실행하지 않는다.

### Reviewer verdict 가 아닌 artifact

다음은 reviewer verdict 가 아니다. 운영 중 혼동하지 않는다.

- `<project-root>/log/brief/BRIEF.md` (`docs/contracts/brief/BRIEF_CONTRACT.md`, canonical Brief — project-local, operator-local, source-control-excluded runtime artifact under `<project-root>/log/`, gitignored by default and not a commit / push target). root `<project-root>/brief/` 와 user-home operator-local runtime root 는 Brief 자리가 아니다 (rejected).
- `log/chatlog/current/resume.md` / `summary.md` (`docs/contracts/chatlog/CHATLOG_CONTRACT.md`, canonical 자리가 아닌 legacy / deprecation candidate; reviewer verdict 와 무관).
- `scripts/brief-check.ps1` 의 PASS / FAIL (BRIEF shape 검증, reviewer 판단이 아님).

verdict 의 source-of-truth 는 같은 review task 의 final pass directory `log/review/<review-task-id>/pass-NN/result.md` 의 `## Verdict` 다 (`docs/contracts/review/REVIEW_RESULT_CONTRACT.md`).

### GJMNet 관련 운영

- 기존 GJMNet 안에 남아 있는 ai-harness-toolset 적용 잔여물 (legacy application state) 은 **disposable** 이다. 그 잔여물에 대한 migration / cleanup 작업은 **post-MVP 항목이 아니며**, 본 toolset 측에서 수행하지 않는다 (`docs/decisions/POST_MVP_PLAN.md` §7).
- GJMNet clean adoption 은 post-MVP foundation 항목 (Brief system, BF Level 3 capability, packaging) 이 ready 된 뒤 별도 scoped 승인을 받아 진행한다. 이 결정과 범위의 source-of-truth 는 **`docs/decisions/POST_MVP_PLAN.md` §7** 이며, "BF Level 3" 의 정의·미구현 경계와 narrow source-side primitive (`scripts/brief-init.ps1` / `brief-check.ps1` / `brief-status.ps1`) 의 책임 한계는 **`docs/contracts/brief/BRIEF_CONTRACT.md`** 가 authority 다 — 본 절은 그 내용을 중복 정의하지 않는다.
- 재생성된 clean GJMNet 운용은 본 toolset 의 CLI-only 운용 규칙을 그대로 따른다.

### 별도 scoped 승인 항목

본 가이드 안에서 implementation 을 시작하지 않는다. 모두 deferred 이며, 별도 scoped 승인 절차를 거친다.

- `package-toolset.ps1` implementation 과 link / pinned-link adoption mode 결정 (`docs/decisions/POST_MVP_PLAN.md` §6).
- docs taxonomy 의 access-pattern path migration 은 **적용 완료**되었다 (2026-05-23; placement authority = `docs/README.md`). `docs/` root 는 `README.md` 만 남고 모든 문서가 access-pattern scope folder 아래에 있으며, `docs/roadmap/` 는 milestone routing only 다. 향후 새 문서 배치는 `docs/README.md` 정책을 따른다.
- 어떤 형태의 commit / push / publish / merge / release / upload / deployment.
