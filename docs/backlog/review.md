# Review Backlog

본 파일은 review subsystem 및 review 운영 관련 open 후보 항목을 기록한다. 본 파일의 어떤 항목도 implementation, scheduling, release 의 자동 승인이 아니다. 본 파일과 다른 contract 문서가 충돌하면 contract 문서가 우선한다 (`./README.md` 참조).

---

## Review 2-pass / profile for user-facing instruction text

- **Status**: trial / candidate

### Context

`SHARED_GLOBAL_INVOCATION_CONTRACT.md` §6 step 3 / D4 (`snippets/CLAUDE_SNIPPET.md`, `snippets/AGENTS_SNIPPET.md` 의 mode-neutral body rewrite) 진행 중, single-pass Codex review 는 contract / consistency 문제는 catch 했지만, "source-managed files always live under `<ToolRoot>`" 같은 **fresh adopter 시점의 reader-risk ambiguity** 는 single pass 에서 단정적으로 잡히지 않았다. 추가 supervisor 단계에서 발견되어 commit 전에 wording 보정 ("Toolset-owned source/config/template/snippet files live under `<ToolRoot>`. Target-owned project files and runtime artifacts live under `<ProjectRoot>`.") 이 이루어졌다.

latest related commit: `8234bf1 Align snippets with shared global layout`.

이런 reader-risk ambiguity 는 user-facing instruction (`snippets/CLAUDE_SNIPPET.md`, `snippets/AGENTS_SNIPPET.md`, `snippets/claude-skills/**/SKILL.md`, 운영 가이드성 docs) 변경에 특히 자주 발생할 수 있다. handoff packet 에만 남기면 유실 가능하므로 repo-visible backlog 항목으로 보존한다.

### Trial

당분간 user-facing 변경에서는 **수동 2-pass review** 를 운용한다.

- **Pass 1 — contract review.** 현재의 single-pass Codex review 그대로. acceptance criteria, target artifact consistency, contract 충족 여부에 집중한다.
- **Pass 2 — reader-risk / adoption ambiguity review.** fresh target-project adopter 관점에서 semantic ambiguity 를 점검한다. 아래 checklist 를 input 으로 한다.

각 pass 는 별도 scoped 호출이며, 별도 run-id / 별도 `meta.json` / 별도 `result.md` / 별도 `result.json` 을 생성한다. 기존 result binding / freshness 검증 contract 는 그대로 따른다.

### Reader-risk checklist

본 checklist 는 trial 단계의 draft 다. 운영 중 다듬어질 수 있다. 모두 yes 일 필요는 없고, 검토자가 의미 ambiguity 후보를 명시적으로 점검하기 위한 prompt 다.

```text
[ ] Toolset-owned files, target-owned tracked files, runtime artifacts 의 구분이 명확한가?
[ ] "always", "only", "default", "source", "runtime", "global", "local" 등 강한 단어가 contract 가 보장하는 범위보다 넓게 사용되지 않았는가?
[ ] Project layout / Review flow / Brief / Chatlog / SKILL flow 사이에 semantic conflict 가 없는가?
[ ] Fresh target-project adopter 가 shared / global mode 와 project-local legacy mode 를 혼동할 만한 표현이 있는가?
[ ] Trigger phrase / 자연어 hook 의 source-of-truth 가 `SKILL.md` frontmatter 라는 점이 명확한가 (snippet body 의 illustrative aside 와 혼동되지 않는가)?
```

### Future decision

본 항목은 design contract 가 아니라 backlog 후보다. 실제 review data 가 한두 round 더 쌓인 뒤 다음 중 하나로 결정한다.

- documented two-pass convention 으로 유지한다.
- explicit CLI-only `ReviewProfile` 기능으로 구현한다.
- 사례를 더 쌓고 재평가한다.

### Non-goals

- daemon / watcher / background automation / implicit multi-run behavior 는 도입하지 않는다.
- 본 backlog 항목 자체는 어떤 구현도 자동 승인하지 않는다.
- `ReviewProfile` 구현이 미래에 채택되더라도, 그 implementation 은 별도 scoped 승인과 별도 review subsystem 변경 (`docs/roadmap/REVIEW_EFFORT_GUIDE.md` §4 의 review-required 항목) 을 거친다.

---

## Review-cycle file-backed request input

- **Status**: candidate — **next primary implementation candidate** (2026-05-16). `docs/backlog/operations.md` §"Review-cycle invocation quoting hardening" §"Stage 2 / Stage 3 decision (2026-05-16)" 가 단순 operator-direct PowerShell wrapper 와 cmd / batch helper 를 safe solution 으로 not adopt 하고, 본 항목의 file-backed request input 채널 (Stage 3) 을 next primary implementation candidate 로 elevation 했다. 두 backlog item 의 통합 / 분리, `-ReviewRequestPath` (또는 동등) 의 정확한 parameter 이름 / shape, request 파일 포맷 (plain text / JSON / template) / 위치 / containment / `-Context` 등 기존 채널과의 conflict 규칙, Pester case set, docs 정합화는 별도 scoped implementation goal 의 explicit user approval 까지 deferred 다. 본 Status 변경 자체가 어떤 구현, commit, push, criteria 변경도 자동 승인하지 않는다.

### Context

D5 commit `df09bf5 Align review skill with shared global ToolRoot resolution` 진행 중, pass 2 reader-risk re-review 의 첫 시도가 PowerShell argument tokenization 오류로 실패했다.

- 호출자: 본 toolset 의 `review-cycle.ps1`. inline `-Context`, `-ReviewQuestions`, `-Constraints` 인자에 quote-heavy + 체크리스트 + Korean/English 혼합 본문을 직접 전달.
- 오류 메시지: `A positional parameter cannot be found that accepts argument 'always'.`
- 원인 후보: quote-heavy / checklist-heavy 본문을 inline PowerShell argument 로 전달하는 과정에서, 호출 문자열 구성 또는 PowerShell tokenization / binding layer 가 `"always"` 를 문자열 일부가 아니라 positional argument 로 해석했다. PowerShell argument escape contract 의 fragility 가 노출되었다.
- 회복: context 본문 wording 을 단순화 (강한 단어 제거 + 일부 구절 재작성) 한 뒤 re-invocation. run-id `20260513-131210-b7c802` 로 정상 수행. 회복된 re-review 는 `yes / findings none` 으로 마무리되었다.

이 회복 경로는 시간 비용을 발생시키고, 더 중요하게는 **reviewer 가 실제로 받는 input 텍스트가 운영자 quote-discipline 에 좌우** 된다. 동일 의미의 입력이 wording 에 따라 PowerShell tokenizer 에서 다르게 처리될 수 있고, 그 결과 reviewer 의 판정에 microscopic 영향이 누적될 risk 가 있다. operator 의 "quote 잘 써라" 가이드만으로는 root-cause 가 해결되지 않는다.

### Problem

- Inline PowerShell 인자 (`-Context`, `-ReviewQuestions`, `-Constraints`) 는 quote-heavy / 체크리스트 / multilingual review prompt 에 fragile 하다.
- D5 incident 가 이 fragility 의 첫 documented evidence 다.
- "operator 가 quote 를 잘 써라" 같은 discipline 권고는 root-cause 가 아니라 mitigation 이다. root-cause hardening (호출 layer 의 tokenization 의존도를 줄이는 것) 과는 구분되어야 한다.

### Candidate direction

- `review-cycle.ps1` 에 명시적 file-backed request input 채널을 추가한다. 후보 이름: `-ReviewRequestPath <path>`.
- request 파일 포맷: 결정론적 local UTF-8 파일. JSON 권장. 최소 fields: `context`, `reviewQuestions`, `constraints`. 위치는 `<ProjectRoot>/log/review-requests/<purpose-or-timestamp>.json` 같은 곳 (현재 `<ProjectRoot>/log/review-targets/` 의 list 파일 규약과 평행).
- 기존 `-Context` / `-ReviewQuestions` / `-Constraints` 는 backward-compatible 로 유지한다. 새 `-ReviewRequestPath` 가 명시되면 그 파일의 fields 가 우선한다. 두 채널을 동시에 명시하는 경우의 우선순위 / 충돌 처리 규칙은 implementation 단계에서 결정한다.
- `review-prepare.ps1` 는 resolved request 텍스트를 generated review packet 안에 그대로 기록해서 freshness / binding 검증에 포함되도록 한다 (예: `log/review/<run-id>/input.md` 또는 `meta.json` 의 추가 field). reviewer 가 실제로 본 텍스트가 read-only record 로 보존되어야 한다.

### Tests considerations

구현 단계에서 다음 input 케이스를 cover 한다.

- Single quote, double quote, backtick 을 포함한 본문.
- Comma 가 본문에 들어 있는 경우.
- Markdown bullet (예: `-`, `*`, 번호 list) 와 줄바꿈이 본문에 들어 있는 경우.
- Korean + ASCII 혼합 본문.
- D5 incident 와 같은 강한 단어 — `"always"`, `"only"`, `"default"`, `"source"`, `"runtime"`, `"global"`, `"local"` — 가 본문에 들어 있는 경우.
- 빈 fields, 누락 fields, 잘못된 JSON shape, 잘못된 UTF-8 인코딩에 대한 명시적 error.

### Non-goals

- 본 항목은 backlog candidate 다. 본 backlog 항목 자체는 어떤 구현도 자동 승인하지 않는다.
- daemon / watcher / background automation 도입하지 않는다.
- implicit retry behavior 도입하지 않는다.
- reviewer model 변경 아니다.
- verdict / result binding semantics 변경 아니다.
- 광범위한 review subsystem redesign 아니다.
- 본 항목의 implementation 이 미래에 채택되더라도, 그 implementation 은 별도 scoped 승인과 별도 review subsystem 변경 (`docs/roadmap/REVIEW_EFFORT_GUIDE.md` §4 의 review-required 항목) 을 거친다.
