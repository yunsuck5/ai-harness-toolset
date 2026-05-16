# Chatlog Contract

본 contract 는 ai-harness-toolset 의 **Chatlog** 책임 영역을 정의한다.

본 문서는 **manual convention first** 문서다. hook, parser, browser automation, DB, retention automation 은 포함하지 않는다.

## 핵심 정의 — Chatlog ≠ Brief

- **Chatlog** 는 AI-assisted development session 의 작업 기록 / 결정 근거 / forensic trace 를 사람이 읽는 file 형태로 보존하는 영역이다.
- Chatlog 는 **Brief 가 아니다.** Brief 는 작업 (재)개 시 가장 먼저 읽는 durable restore source 이며 그 contract 는 `docs/BRIEF_CONTRACT.md` 다.
- Chatlog 의 책임은 **history / decision rationale / Brief reconstruction evidence** 이다. 현재 restore source 의 자리가 아니다.
- 두 책임은 분리되어 있고 한쪽이 다른 쪽을 대체하지 않는다. 본 contract 는 Chatlog 를 Brief 의 대용으로 쓰는 model 을 정의하지 않는다.

## current restore source 는 Brief 다

- 어떤 session 이든 작업 (재)개 시 **가장 먼저 읽는 자리는 Brief** 다 (`docs/BRIEF_CONTRACT.md`). canonical Brief 는 `<ProjectRoot>/log/brief/BRIEF.md` — 그 project 의 checkout 안 `log/` 트리 아래 project-local, operator-local, source-control-excluded runtime artifact. root `<ProjectRoot>/brief/` 와 user-home operator-local runtime root 는 Brief 자리가 아니다.
- Chatlog 는 새 session 의 default context 가 아니다. AI agent 가 raw transcript / 누적 Chatlog 본문을 읽어 자체 요약으로 restore 를 시도하는 우회는 권장되지 않는다.
- Chatlog 가 사용되는 정상 경로는 두 가지뿐이다.
  - Brief 가 가리키는 path 를 따라가 특정 결정 / 근거 / 인용 wording 을 확인할 때.
  - Brief 가 오염 / 삭제 / stale 인 경우 Brief 를 재구성하기 위한 evidence 로 사용할 때 (아래 §"Brief reconstruction evidence" 참조).

## `log/chatlog/current/resume.md` 와 `summary.md` 의 분류

`<ProjectRoot>/log/chatlog/current/resume.md` 와 `<ProjectRoot>/log/chatlog/current/summary.md` 는 **canonical 자리가 아니다.** 본 contract 의 분류는 다음과 같다.

- **failed intermediate** — 두 파일은 과거 시점에 Brief 의 자리를 부분적으로 대신하려던 시도의 잔재이며, 본 contract 의 Brief vs Chatlog 책임 분리에 맞지 않는 형태로 운영되어 왔다.
- **legacy migration source** — 두 파일에 사람이 작성한 wording 이 남아 있는 경우, 그 본문은 향후 Brief 재구성 / Chatlog reorganization 의 input 으로 참조될 수 있다. 즉, 본 contract 가 그 wording 자체를 자동 폐기하라고 명령하지 않는다.
- **deprecation candidate** — 두 파일의 자리는 본 contract 의 정상 운영 흐름에서 제거 대상이다. 다만 실제 파일 삭제 / 경로 정리 / 자동화는 별도 scoped 승인이 필요하다 (본 contract 는 deletion 또는 path migration 을 자동 승인하지 않는다).

따라서 두 파일은:

- Brief 가 아니다. current restore source 가 아니다. 새 session 진입 시 default 로 읽는 자리가 아니다.
- 본 contract 는 두 파일을 reviewer verdict, commit gate, push gate, release gate 의 input 으로 쓰지 않는다.
- 두 파일을 갱신하라는 자동 trigger 를 본 contract 가 정의하지 않는다. 과거 docs / snippet 에 남아 있는 "사용자 자연어 trigger → resume.md / summary.md 갱신" 흐름은 본 contract 의 정상 운영 흐름이 아니다.

## Chatlog 의 책임

Chatlog 는 다음 한 가지 역할을 갖는다.

- **history / decision rationale / Brief reconstruction evidence** — session 단위의 의사결정, 사용자 원문 인용, 작업 단위 trace, 결정 근거를 사람이 읽을 수 있는 형태로 누적 보존한다.

본 책임의 운영 우선순위는 다음과 같다.

- 제 1 독자는 **사람** 이다. 후속 작업자 / 운영자가 결정 근거를 찾을 때 빠르게 읽을 수 있어야 한다.
- 제 2 독자는 **AI agent** (대개 Brief 재구성 시) 다. AI 가 Chatlog 본문을 통째로 읽어 매번 restore 를 시도하는 것은 default 흐름이 아니다.

Chatlog 가 담당하지 **않는** 것:

- AI CLI raw transcript 의 자동 capture.
- session 경계 자동 감지.
- 80% context trigger, pre-compact resume packet 자동 생성.
- browser 기반 ChatGPT Web 대화 capture.
- session DB / index 관리.
- retention / prune 자동화.
- review subsystem 의 gate 판단.
- evidence subsystem 의 자동 수집.
- CI integration.
- 새 session 의 default restore source.

## Chatlog fuller implementation 은 later track

- Chatlog 의 fuller implementation — 누적 work history 자동화, 자체 schema, retention, browse UI, RND-style heavy workflow — 은 본 contract 의 범위가 아니라 **later track** 이다.
- 본 contract 는 Chatlog 영역이 **존재한다는 사실** 과 Brief 와 분리된 책임을 갖는다는 점만 정의한다.
- 향후 Chatlog fuller implementation 이 별도 scoped 승인을 받아 진행되는 경우에도, 그 implementation 이 Brief 의 자리를 침범하거나 Chatlog 를 current restore source 로 승격하지 않는다.

## Brief reconstruction evidence — 사용 흐름

Brief (`<ProjectRoot>/log/brief/BRIEF.md`) 가 오염 / 삭제 / stale 로 신뢰할 수 없는 경우, Chatlog 본문이 Brief 재구성의 evidence 로 사용될 수 있다. 이 사용은 다음 흐름을 따른다.

- 운영자가 명시적으로 "Brief 가 신뢰할 수 없다" 고 판단한 경우에만 시작한다. 본 contract 는 그 판단을 자동 trigger 로 만들지 않는다.
- AI agent 가 Chatlog 를 읽고 Brief 의 required heading set 에 맞춰 사람이 검토 가능한 draft 를 만든다. agent 가 직접 Brief artifact 를 commit / overwrite 하지 않는다.
- 최종 Brief 본문은 운영자의 확인을 거쳐 적용된다. 본 contract 는 그 적용 자체를 자동 승인하지 않는다.
- Brief 재구성이 끝나면 Chatlog 는 원래의 history / decision rationale 역할로 되돌아간다. Chatlog 가 current restore source 로 승격되는 일은 일어나지 않는다.

## review / evidence subsystem 과의 경계

`log/` 아래에는 세 종류 트리가 공존한다. 책임이 서로 다르다.

| 트리 | 책임 | 검증 주체 |
|---|---|---|
| `log/chatlog/` | session history / decision rationale / Brief reconstruction evidence 보존 | 사람 (manual convention) |
| `log/evidence/` | command 실행 사실, output, 재현 단서 보존 | 사람 (manual convention, `docs/EVIDENCE_CONTRACT.md`) |
| `log/review/<review-task-id>/pass-NN/` | canonical review record per pass — `input.md` (AI-authored) + `result.md` (Codex-authored) (`docs/REVIEW_RESULT_CONTRACT.md`). canonical 두 단계 layout 이며 현행 script 가 이 layout 을 그대로 emit 한다. | 두 단계 entry: `scripts/review-prepare.ps1`, `scripts/review-run.ps1` |

- Chatlog 는 review subsystem 의 input 이 아니며 output 도 아니다.
- Chatlog 는 evidence subsystem 의 input 이 아니며 output 도 아니다.
- 셋은 같은 `log/` 아래에 있지만 서로 enforce 하지 않는다.

Chatlog 가 evidence 또는 review artifact 를 path 로 참조하는 것은 권장된다. 그러나 Chatlog 가 evidence / review 의 정합성을 담당하지는 않는다.

## acceptance scenario 와 Chatlog 의 관계

Chatlog artifact 의 존재 / 부재는 review subsystem 의 acceptance 판정과 별개 평가 축이다.

- pure review-loop acceptance 흐름은 같은 review task 의 final pass 의 `log/review/<review-task-id>/pass-NN/{input.md, result.md}` 만 검증한다 (`docs/REVIEW_RESULT_CONTRACT.md` 의 canonical artifact 두 파일). Chatlog tree 의 부재는 review subsystem 의 실패가 아니다.
- review artifact 축과 Chatlog 축은 서로 분리된 평가 축이다. 한 축의 부재로 다른 축을 fail 처리하지 않는다.
- source snapshot 한 묶음에는 `log/` runtime artifact 를 포함하지 않는다 (§"source vs runtime 경계"). snapshot 안에 Chatlog 가 없는 것은 본 contract 의 위반이 아니다.

본 contract 는 `log/chatlog/current/resume.md` / `summary.md` 의 갱신을 acceptance 평가 축으로 두지 않는다. 위 §"`log/chatlog/current/resume.md` 와 `summary.md` 의 분류" 에 따라 두 파일은 canonical 자리가 아니기 때문이다.

## 경로 규약

`<ProjectRoot>/log/chatlog/` 는 project-local runtime artifact 영역이다.

- `log/chatlog/` 는 gitignored runtime artifact tree 다 (`.gitignore` 의 `log/` 규칙). source snapshot 에 포함하지 않는다.
- 본 contract 는 `log/chatlog/` 하위 layout 의 fuller schema 를 정의하지 않는다. fuller implementation 은 later track 이다.
- `log/chatlog/current/resume.md` / `summary.md` 는 위 §"분류" 에서 정의한 대로 canonical 자리가 아니다.

## 사용자 원문과 AI 작성물의 분리 (legacy 본문 보존 시 적용)

Chatlog 본문에 사용자 원문 인용과 AI 작성물이 혼재할 때는 두 종류 텍스트를 같은 단락에 섞지 않는다. 본 원칙은 legacy migration source 로 남아 있는 본문에도 그대로 적용된다.

- 사용자 원문은 가능한 한 verbatim 으로 보존한다. summarize / compress / rephrase / translate / interpret 하지 않는다.
- AI 작성물 (요약 / 판단 / 결정 기술) 은 별도 section 또는 별도 파일로 분리한다.
- 한 bullet 안에 사용자 원문과 AI 판단을 같이 쓰지 않는다.

## encoding 정책

- Chatlog `.md` runtime artifact 를 PowerShell 로 만들 때는 `scripts/lib/encoding.ps1` 의 `Write-Utf8NoBom` 을 사용한다.
- 모든 Chatlog `.md` runtime artifact 는 UTF-8 without BOM 이다.
- `Set-Content -Encoding UTF8`, `Add-Content -Encoding UTF8`, `Out-File` 은 사용하지 않는다.
- 본 encoding 정책은 manual convention 이다. 새 wrapper / parser / generator / hook 도입의 근거가 되지 않는다.

## source vs runtime 경계

- `templates/`, `scripts/`, `config/`, `snippets/`, `docs/` 등 source 트리에는 Chatlog 파일을 두지 않는다.
- Chatlog 를 source repo 에 commit 하지 않는다.
- Chatlog 가 참조하는 fixture / snapshot 은 `log/chatlog/` 또는 `log/evidence/<scope>/<case>/` 안에서만 생성한다.

## non-goals (본 contract 가 다루지 않는 것)

- AI CLI raw transcript 자동 capture wrapper.
- Chatlog 자동 retention 정책.
- Chatlog schema validator.
- review subsystem 의 gate 검증 (별도 책임; `docs/REVIEW_RESULT_CONTRACT.md` §4).
- evidence subsystem 보장 (별도 책임).
- CI integration.
- 다른 toolset 과의 Chatlog format 상호운용.
- Chatlog fuller implementation — 누적 history 자동화, 자체 schema, retention, browse UI (later track).
- RND-style `CHAT_LOG + REPORT + BRIEF` 통합 workflow.
- Claude Code session-start hook, on-stop hook, on-prompt-submit hook, watcher, daemon, scheduler.
- Chatlog 또는 Brief 의 auto-inject / auto-capture (사용자 prompt / assistant 응답 자동 기록).
- Claude transcript JSONL parser, Claude Code internal state machine 의 자동 해석.
- `BF_STATE.json` 같은 별도 state machine 파일.
- `~/.claude/settings.json` 또는 글로벌 `CLAUDE.md` / `AGENTS.md` 의 mutation.
- `log/chatlog/current/resume.md` / `summary.md` 를 canonical 자리 또는 current restore source 로 승격하는 모든 해석.
- 위 두 legacy 파일의 자동 deletion / migration / path 변경 (별도 scoped 승인이 필요한 future scoped work).

## Future candidate

아래 항목은 버리지 않는다. 본 contract 의 자리는 아니며, 별도 scoped 승인이 필요하다.

- Chatlog fuller implementation (누적 history layout, retention, browse 등) 의 design 과 implementation.
- `log/chatlog/current/resume.md` / `summary.md` legacy 본문의 정리 / migration / archive 절차.
- Brief reconstruction 흐름의 deterministic helper (사람이 trigger 한 경우에 한해 Chatlog 본문을 Brief draft 로 정리하는 read-only assistant).
- Chatlog 와 evidence / review 간 cross-link 보조 도구 (read-only, enforcement 아님).

위 항목들은 BF Level 3 capability (`docs/BRIEF_CONTRACT.md` §"BF Level — save/restore capability maturity") 의 future scoped work 와 sibling 관계다. 어느 항목도 본 contract 가 자동 승인하지 않는다.
