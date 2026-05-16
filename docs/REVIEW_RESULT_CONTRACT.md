# Review Artifact Contract

본 문서는 한 번의 review task 가 어떤 artifact 로 닫히는지의 canonical contract 다. canonical artifact 는 두 파일이며 다른 sidecar 파일은 contract 의 일부가 아니다.

```text
<ProjectRoot>/log/review/<review-task-id>/
  pass-01/
    input.md
    result.md
  pass-02/
    input.md
    result.md
```

`input.md` 는 operator-role AI (Claude Code) 가 작성한다. `result.md` 는 Codex reviewer 가 작성한다. script 는 위 두 파일에 대한 deterministic gate 만 담당하고, 의미 판단은 하지 않는다.

본 contract 는 source-of-truth 이며, `templates/review-input.md` · `templates/review-result.md` · `snippets/claude-skills/ai-harness-review/SKILL.md` · `docs/OPERATOR_GUIDE_KR.md` · `README.md` 는 이 contract 를 mirror 한다. 본문이 충돌하면 본 contract 가 우선한다.

## 1. Review task and pass directory

review record 는 두 단계 디렉터리로 닫힌다.

- `<review-task-id>` — 하나의 Claude Code `/goal` 작업 또는 하나의 review gate 단위. **Claude Code chat / session id 가 아니다.** 한 Claude Code 세션 안에서 서로 다른 주제의 `/goal` 이 여러 개 진행되면 각각 별도의 `<review-task-id>` 디렉터리를 사용한다. 자리: `<ProjectRoot>/log/review/<review-task-id>/`.
- `pass-NN` — 같은 review task 안에서 corrective loop 의 각 Codex review attempt. 첫 review attempt 는 `pass-01`, 두 번째 attempt 는 `pass-02`, 이렇게 zero-padded 두 자리로 증가한다. 자리: `<ProjectRoot>/log/review/<review-task-id>/pass-NN/`.
- canonical artifact per pass: 같은 `pass-NN/` 디렉터리 안의 `input.md` + `result.md` 한 쌍. 한 pass 의 record 는 외부 staging folder, sidecar JSON, hash sidecar 어디로도 분산되지 않는다.
- `<ProjectRoot>/log/` 는 gitignored runtime tree 다. canonical artifact 도 commit 대상이 아니다.
- 각 `pass-NN/` 디렉터리는 **write-once** 다. AI 또는 운영자가 같은 pass directory 안의 파일을 손으로 보정하여 review 를 닫지 않는다. 보완은 같은 `<review-task-id>/` 아래에 새 `pass-NN/` 를 만들어 수행한다.
- 다른 review task 의 record 는 다른 `<review-task-id>/` 아래에 둔다. 한 task 의 corrective loop 와 다른 task 의 attempt 를 같은 `<review-task-id>/` 에 섞지 않는다.

## 2. `input.md` — AI-authored review request

`input.md` 는 reviewer 에게 전달되는 모든 입력을 한 파일로 담는다. 본문은 운영 자연어로 작성한다.

required H2 heading set (정확 매치):

- `## Context`
- `## Required inspection paths`
- `## Review questions`
- `## Constraints`
- `## Final verdict`

각 required heading 의 본문 (다음 required heading 직전까지 또는 EOF 까지) 은 비어 있지 않아야 한다. `## Final verdict` section 의 본문에는 정확히 `yes / no / yes with risk` 문자열이 포함되어야 한다.

input.md 안에는 위 5 개의 required heading 외에 다음 informational section 을 추가로 둘 수 있다 (script 가 본문 검사 대상이 아니지만 reviewer 가 본문을 읽는다).

- `## Stage` — design | implementation | test | review | release.
- `## Purpose` — 한 줄 의도.
- `## Target files` — repo-relative path 의 bullet list. forward slash. reviewer 가 읽어야 할 코어 파일 집합.

`{{TOKEN}}` 형태의 unfilled template token, 또는 forbidden placeholder phrase (`Replace this placeholder`, `(Provide context here.)`, `(Provide review questions here.)`) 가 본문에 남아 있으면 `scripts/review-input-verify.ps1` 가 거부한다.

작성 주체는 operator-role AI 다. 사용자는 자연어 의도만 표현하고 raw template 을 손으로 채우지 않는다. AI 는 conversation context · git status · diff · 사용자 의도 · 해당 작업의 scope 를 종합해 input.md 본문을 직접 작성한다.

`input.md` 의 shape 기준은 `templates/review-input.md` 다.

## 3. `result.md` — Codex-authored review result

`result.md` 는 Codex CLI 가 `--output-last-message log/review/<review-task-id>/pass-NN/result.md` 로 한 번 작성한다. operator-role AI 또는 운영자가 손으로 작성하지 않는다.

required shape:

- 정확히 1 개의 top-level `## Verdict` heading 이 있다.
- `## Verdict` heading 다음의 첫 비어있지 않은 줄 (앞뒤 whitespace trim 후) 이 lowercase 정확히 다음 셋 중 하나다:
  - `yes`
  - `no`
  - `yes with risk`

거부되는 형태 (의도된 strict parsing):

- 0 개 또는 2 개 이상의 `## Verdict` heading.
- inline 형태 (`Verdict: yes`, `Final verdict: yes`).
- prose 안에 verdict 토큰이 섞인 형태.
- `## Verdict` heading 다음 줄에 verdict 와 다른 토큰이 함께 있는 형태.
- `Yes`, `YES`, `yes.`, `yes with notes` 등 lowercase 정확 매치를 벗어나는 변형.

추가로 자유롭게 둘 수 있는 section (의무 아님):

- `## Findings` — 권장. 발견 사항을 항목별로 기록.
- `## Risks` — `yes with risk` 가 verdict 일 때 권장.
- `## Notes` — 자유 형식 참고.

`result.md` 의 shape 기준은 `templates/review-result.md` 다.

## 4. Script responsibility (deterministic gate only)

review pass 를 다루는 script 는 의미 판단을 하지 않는다. script 의 최소 책임:

1. pass directory `<ProjectRoot>/log/review/<review-task-id>/pass-NN/` 가 `<ProjectRoot>/log/review/` 내부인지 containment 검증.
2. `input.md` 의 5 개 required H2 heading 존재 여부와 본문 비어있지 않음 검증 (`scripts/review-input-verify.ps1` 의 contract).
3. Codex CLI 를 `input.md` 에 대해 정확히 1 회 실행.
4. 같은 pass directory 의 `result.md` 존재 검증.
5. `result.md` 의 `## Verdict` heading 1 개 존재 + 다음 첫 비어있지 않은 줄이 `yes` / `no` / `yes with risk` 중 하나인지 검증.
6. 위 모든 gate PASS 시 exit 0, 하나라도 실패 시 non-zero exit.

script 가 하지 않는 일:

- finding 의 의미 / 정당성 / 심각도 판단.
- 수정 scope 또는 re-review 필요 여부 판단.
- result 본문의 finding / risk 항목 자동 parsing 또는 후속 단계 트리거.
- verdict 를 읽어 commit / push / publish / merge / release 자동 승인.
- review request 본문을 여러 staging file 로 분산하는 staging step.
- AI 가 자연어로 작성할 수 있는 본문을 JSON / hash / provenance 파일로 추가 분산.

### 4a. Script entry points (canonical)

본 contract 의 6 개 gate 는 두 entry point 로 닫힌다.

- `scripts/review-prepare.ps1 -ReviewTaskId <id> [-Pass <pass-NN>] -Stage <stage> -Purpose <line>`
  - canonical pass directory `<ProjectRoot>/log/review/<review-task-id>/pass-NN/` 를 발급한다.
  - 그 안에 `templates/review-input.md` 본문을 그대로 옮긴 `input.md` 를 seed 한다.
  - `-Pass` 가 생략되면 같은 task directory 안의 기존 `pass-NN` 을 스캔해 다음 번호를 할당한다 (`pass-01`, `pass-02`, ...).
  - pass directory 가 이미 존재하면 write-once 위반으로 거부한다.
- `scripts/review-run.ps1 -ReviewTaskId <id> -Pass <pass-NN>`
  - 같은 pass directory 의 `input.md` 를 `scripts/review-input-verify.ps1` 로 검증한 뒤 Codex CLI 를 정확히 1 회 실행해 같은 pass directory 의 `result.md` 를 작성한다.
  - reviewer model 은 `-Model` 명시 → `config/reviewer.json` 의 `model` → built-in default 순으로 해소된다. canonical record 안에는 model / hash / source HEAD 같은 sidecar 가 저장되지 않는다.
  - `result.md` 의 `## Verdict` shape 를 검증한 뒤 PASS / FAIL 을 반환한다.
- `scripts/review-verify.ps1 -ReviewTaskId <id> -Pass <pass-NN> [-RequireResult]`
  - default mode: `input.md` 존재 + shape 만 검증.
  - `-RequireResult`: `input.md` shape + `result.md` 존재 + `## Verdict` shape 까지 검증한다.
  - canonical artifact 두 파일만으로 PASS 가 결정되며, 어떤 sidecar JSON / hash binding 파일도 요구하지 않는다.

운영자 / AI 는 `<review-task-id>` 를 사용자의 `/goal` 작업 또는 review gate 단위로 직접 결정한다. Claude Code chat / session id 를 자동으로 받아 쓰지 않는다.

## 5. AI responsibility (semantic judgment)

operator-role AI 는 다음을 담당한다.

1. 사용자의 자연어 의도와 승인 boundary 에서 review scope 를 잡고, 그 작업에 사용할 `<review-task-id>` 를 결정한다 (한 `/goal` 작업 또는 한 review gate 단위).
2. `templates/review-input.md` 기준으로 `log/review/<review-task-id>/pass-NN/input.md` 본문을 직접 작성한다. target files / context / required inspection paths / review questions / constraints / final verdict instruction 을 모두 input.md 한 파일 안에 담는다. 첫 attempt 는 `pass-01`, 이후 corrective loop attempt 는 `pass-02`, `pass-03` ... 으로 증가한다.
3. `result.md` 의 `## Verdict` 다음 첫 줄을 읽어 verdict 값을 확정.
4. `## Findings` / `## Risks` / `## Notes` 본문을 읽고 finding 의 의미와 정당성, 수정 필요 scope, re-review 필요 여부를 판단.
5. 필요한 수정이 사용자가 승인한 scope 안이면 수정 후 같은 `<review-task-id>` 아래에 새 `pass-NN` 를 만들어 re-review.
6. 사용자에게 review task path, 최종 pass, verdict, corrective loop count, changed files / validation / risk / next decision 을 보고.

AI 는 verdict 의 의미 정의를 바꾸지 않는다. `yes` / `no` / `yes with risk` 는 본 contract 의 vocabulary 다.

## 6. Verdict vocabulary

다음 셋이 본 contract 의 vocabulary 다:

- `yes` — 본 review scope 안에서 진행 가능.
- `no` — 본 review scope 안에서 진행 불가.
- `yes with risk` — 진행은 가능하나 명시된 risk 를 수반.

verdict 는 review scope 안의 판단만을 담는다. commit / push / publish / merge / release / deployment / upload / adoption / config mutation 의 자동 승인이 아니다. 다음 단계는 사용자가 별도 명시 결정으로 처리한다.

## 7. Re-review on staleness

같은 `pass-NN/` 안의 `input.md` 또는 `result.md` 가 작성된 뒤, 그 review 가 묶인 source / docs / template / snippet 중 어떤 것이라도 수정되면 그 pass 의 record 는 stale 이다. 사용자가 stale pass 의 verdict 를 후속 결정의 근거로 사용하지 않는다.

수정 후 동일 review task 안에서 동일 의미의 review 가 필요하면 같은 `<review-task-id>/` 아래에 새 `pass-NN/` 를 만든다 — 같은 task 의 corrective loop 의 다음 attempt 다. 이전 pass directory 안의 파일을 손으로 보정하지 않는다.

review 작업 자체가 바뀌면 (다른 `/goal` 또는 다른 review gate) 새 `<review-task-id>/` 를 사용한다 — 이전 task 의 pass 디렉터리를 재활용하지 않는다.

stale 판단의 책임은 operator-role AI 와 사용자에게 있다. 본 contract 는 stale 자동 detection 을 script 책임으로 두지 않는다.

## 8. Source repo vs target payload, runtime artifact 경계

본 contract 의 `<ProjectRoot>` 는 target project 의 repo root 다. source repo 의 dogfooding 모드에서는 source repo 자체가 `<ProjectRoot>` 다.

- source repo 의 `templates/` · `docs/` · `snippets/` · `config/` · `scripts/` · `tests/` 는 source-managed 다. review record 는 그 트리에 두지 않는다.
- review record 는 항상 `<ProjectRoot>/log/review/<review-task-id>/pass-NN/` 아래에만 만든다. `<ProjectRoot>/log/` 는 gitignored runtime tree 다.
- public release packaging / source snapshot 은 `log/` 를 포함하지 않는다.
- target project 의 `.gitignore` 는 `log/` 를 포함해야 한다. toolset 은 target `.gitignore` 를 자동으로 만들거나 편집하지 않는다.

## 9. Retention

retention 단위는 `<review-task-id>/` 디렉터리 전체, 또는 그 안의 개별 `pass-NN/` 디렉터리다. 더 이상 필요하지 않은 review task / pass 디렉터리는 사용자가 손으로 삭제한다. toolset 은 auto-prune / rotate / expire / schedule 을 제공하지 않는다.

failed / incomplete pass (예: Codex 실패 또는 verdict parsing 실패로 `result.md` 가 contract 를 만족하지 못한 pass) 도 디렉터리 단위로 disk 에 그대로 남는다. 사용자가 같은 `<review-task-id>/` 아래에 새 `pass-NN/` 로 보완하고, 보존 가치를 판단해 이전 pass / 전체 task 를 유지하거나 삭제한다.

## 10. Non-goals

본 contract 가 다루지 않는 것:

- canonical artifact 외의 sidecar 파일 (sidecar JSON, hash binding 파일, 외부 staging folder 등) 에 대한 보장. 그런 파일은 본 contract 의 일부가 아니다.
- review record 에 대한 hash binding / freshness sidecar / machine-readable verdict 사본의 자동 작성.
- review history aggregation, DB, index, cross-run dashboard.
- multi-reviewer orchestration, fallback model 자동 사용, retry / auto-fix loop.
- review verdict 를 read 하여 commit / push / publish / merge / release / deployment 를 트리거하는 wrapper.
- target project 의 `CLAUDE.md` / `AGENTS.md` / `.gitignore` / global filesystem 자동 변경.
- daemon, watcher, scheduler, CI integration.
- evidence / chatlog / brief subsystem 과의 cross-tree 보장.

removed legacy artifact design 의 historical reason 은 `docs/backlog/review.md` 및 `docs/backlog/operations.md` 에 격리되어 있다. 그 항목은 operator path 가 아니며 normal workflow 의 일부도 아니다.
