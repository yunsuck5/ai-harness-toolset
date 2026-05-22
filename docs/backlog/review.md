# Review Backlog

> **현행 routing (docs taxonomy reset).** 본 파일은 open backlog candidate 와 closed / historical / removed-legacy 항목이 섞여 있다. **현행 open work** 의 진입점은 per-system BACKLOG (`docs/systems/install-update/BACKLOG.md`, `docs/systems/review/BACKLOG.md`) 와 분류 INDEX (`docs/backlog/INDEX.md`) 다. 본 파일 안의 closed 항목은 `docs/systems/*/STATUS.md` 의 completed-ledger 가 authoritative status 이며, removed-legacy 식별자는 historical reason 으로만 보존된다 (operator path 아님). 항목별 status 분류는 `docs/backlog/INDEX.md` 를 본다.

본 파일은 review subsystem 및 review 운영 관련 open 후보 항목을 기록한다. 본 파일의 어떤 항목도 implementation, scheduling, release 의 자동 승인이 아니다. 본 파일과 다른 contract 문서가 충돌하면 contract 문서가 우선한다 (`./INDEX.md` 참조).

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

각 pass 는 별도 scoped 호출이며, canonical 두 단계 layout 에서 `log/review/<review-task-id>/pass-NN/input.md` + `log/review/<review-task-id>/pass-NN/result.md` 한 쌍을 생성한다 (`docs/REVIEW_RESULT_CONTRACT.md`). 본 항목의 "Pass 1 / Pass 2" 는 같은 review task 안의 corrective loop 의 `pass-01` / `pass-02` 와 동일 단위가 아니라, **서로 다른 분석 축의 review profile** 이다 — 즉 Pass 1 (contract review) 과 Pass 2 (reader-risk review) 는 같은 corrective loop 가 아니므로 별도의 `<review-task-id>` 디렉터리에서 진행한다. 각 review profile 안에서 발생하는 corrective loop 는 그 task 의 `pass-NN` 으로 처리된다. 본 trial 항목이 실제 구현으로 채택되더라도 simplified canonical topology 의 두 파일 contract 위에서 운영된다.

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

- **Status**: **removed legacy design / historical reason only / not an operator path**. 본 항목이 다루던 `scripts/review-cycle.ps1` 의 `-ReviewRequestPath <path>` 파라미터, `<ProjectRoot>/log/review-requests/` containment, `meta.json.reviewRequest` provenance binding, inline-vs-file mutually-exclusive 규칙은 2026-05-16 이후 단순화된 canonical review artifact topology (canonical 두 단계 layout 의 `log/review/<review-task-id>/pass-NN/input.md` + `log/review/<review-task-id>/pass-NN/result.md` 두 파일만; `docs/REVIEW_RESULT_CONTRACT.md`) 으로 대체되었다. AI 가 자연어 의도로부터 input.md 본문을 직접 작성하므로, request 본문 운반을 위한 외부 staging file 채널이 normal operator path 에서 불필요해졌다. 본 항목은 그 단계까지의 historical reason 만 기록하며 operator path 가 아니다.

> **Historical context only.** 아래 §Context / §Problem / §Implementation / §Tests / §Cross-reference / §Non-goals 는 본 항목이 implementation 으로 closeout 되었던 2026-05-16 시점의 기록이다. 본 §Status 가 가리키듯 그 implementation 은 이후 canonical artifact topology 단순화로 normal operator path 에서 제거되었으며, 본 §Status 아래의 본문은 historical reason 만 보관한다. 본문에 등장하는 `-ReviewRequestPath`, `log/review-requests/`, `meta.json.reviewRequest` 등의 식별자는 현행 contract 의 일부가 아니다.

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

### Implementation (landed 2026-05-16)

본 항목은 `docs/backlog/operations.md` §"Review-cycle invocation quoting hardening" 와 통합 closeout 되었다. 최종 형태는 다음과 같다 — 이전 §Candidate direction 의 JSON 후보 / 우선순위 규칙 후보는 implementation 단계에서 채택되지 않았고 아래 형태로 결정되었다.

- **파라미터**: `scripts/review-cycle.ps1` 의 `-ReviewRequestPath <path>` (소문자 ㅏ 대문자 동일 한 PowerShell 규약).
- **파일 포맷**: Markdown plain text (UTF-8). JSON 후보는 채택하지 않았다 — multi-line / embedded ASCII double-quote / 한국어 본문에 대해 JSON 은 추가 escape layer 를 요구하나 Markdown H2 section + body verbatim 방식은 escape 없이 원본을 그대로 보존한다 (root-cause 해소 목표와 직접 정합).
- **Required heading set**: `## Context`, `## Required inspection paths`, `## Review questions`, `## Constraints` — input.md template 의 heading set 과 정확히 동일. body 는 다음 H2 직전까지 (또는 EOF) 의 모든 줄 trim 한 텍스트. fail-fast 조건: missing heading / empty body / duplicate heading.
- **위치 / containment**: `<ProjectRoot>/log/review-requests/<purpose-or-timestamp>.md`. `scripts/lib/path.ps1` 의 신규 helper `Assert-InProjectLogReviewRequestsRoot` 가 강제하며 그 외 경로는 review-cycle 이 fail-fast 거부한다.
- **inline 채널 conflict rule**: `-ReviewRequestPath` 와 inline `-Context` / `-RequiredInspectionPaths` / `-ReviewQuestions` / `-Constraints` 는 **mutually exclusive** (둘 중 하나에라도 값이 들어 있으면 fail-fast). 우선순위 / partial override / silent merge 은 채택하지 않았다 — 명확한 entrypoint 분리가 audit 가능성을 보존한다.
- **provenance binding**: prepare 단계에서 request file 의 `path` (project-relative, forward-slash) 와 `sha256` 이 `meta.json.reviewRequest = { path, sha256 }` 에 기록된다. reviewer 가 실제로 받은 input.md 의 freshness 는 기존 `result.json.inputSha256` (`review-verify -RequireResult`) 가 이미 다루므로, `reviewRequest` 는 별도 freshness 검증 대상이 아니라 provenance 만의 binding 이다.
- **review-prepare / review-input-verify / review-verify**: 별도 변경 없음 — request file 의 4 section body 가 prepare 가 만든 input.md placeholder 를 그대로 채우므로 기존 input.md 검증 / freshness / binding 흐름이 그대로 적용된다.
- **inline 채널 backward compatibility**: `-ReviewRequestPath` 미사용 시 기존 inline `-Context` / `-RequiredInspectionPaths` / `-ReviewQuestions` / `-Constraints` 동작 그대로. Stage 1 docs-only quoting 규율 (`docs/OPERATOR_GUIDE_KR.md` §9) 은 inline 사용 시 그대로 적용된다.

### Tests landed

`tests/review-cycle-request.Tests.ps1` (11 Pester case):

- multi-line body with markdown bullets and Korean+English mix preserved verbatim.
- embedded ASCII double-quote in body survives end-to-end.
- missing required heading → fail-fast with explicit heading name in message.
- empty body under required heading → fail-fast.
- duplicate required heading → fail-fast.
- request file outside `<ProjectRoot>/log/review-requests/` → fail-fast before review-prepare; run directory not created.
- non-existent request file → fail-fast; run directory not created.
- inline `-Context` combined with `-ReviewRequestPath` → fail-fast conflict message lists `-Context`.
- inline `-ReviewQuestions` combined with `-ReviewRequestPath` → fail-fast conflict message lists `-ReviewQuestions`.
- inline-only invocation (no `-ReviewRequestPath`) → backward-compatible; meta.json contains no `reviewRequest` field.
- simple request file → run PASS, meta.json.reviewRequest path + sha256 recorded, input.md sections populated.

본 case set 은 이전 §Tests considerations 의 후보 (JSON shape / UTF-8 encoding error 등) 중 implementation 의 실제 contract 와 맞는 것만 유지했다. JSON shape / UTF-8 encoding 검사는 Markdown 채택으로 무의미해졌으므로 빠졌다.

### Cross-reference

- `docs/backlog/operations.md` §"Review-cycle invocation quoting hardening" — operator-direct argv layer 의 hardening. 본 항목과 통합 closeout (동일 channel, 동일 라운드).
- `docs/OPERATOR_GUIDE_KR.md` §9b — 운영자 사용법 / 예시.
- `README.md` "Single-shot review cycle" — high-level 안내.
- `docs/REVIEW_RESULT_CONTRACT.md` "meta.json" — `reviewRequest` schema 와 freshness 범위.

### Non-goals

- daemon / watcher / background automation 도입하지 않는다.
- implicit retry behavior 도입하지 않는다.
- reviewer model 변경 아니다.
- verdict / result binding semantics 변경 아니다.
- 광범위한 review subsystem redesign 아니다.
- 본 implementation 자체가 commit / push / global current/ refresh / criteria 변경 어느 것도 자동 승인하지 않는다 — 그 결정은 별도 explicit user approval.

---

## Removed legacy review artifacts (historical reason only)

- **Status**: removed legacy design / historical reason only / not an operator path.

본 항목은 simplified review artifact topology 이전에 normal operator path 에서 사용되던 review artifact 들과 layout 들의 historical reason 을 보관한다. 본 항목의 어떤 식별자도 현행 normal operator path 가 아니며, `docs/REVIEW_RESULT_CONTRACT.md` 의 canonical contract (`log/review/<review-task-id>/pass-NN/input.md` + `log/review/<review-task-id>/pass-NN/result.md` 두 파일만, 두 단계 layout) 으로 대체되었다.

removed-legacy 식별자 / layout (current contract 의 일부가 아님):

- **flat `log/review/<run-id>/` 한 단계 layout** — 초기 단순화 round 에서는 한 review record 가 flat 한 단일 timestamp-suffix run-id 디렉터리에 담겼다. 현행 contract 는 `<review-task-id>/pass-NN/` 두 단계 layout 이며 한 review task 의 corrective loop 가 같은 task 디렉터리 아래에서 명시적 pass 단위로 묶인다. 현재 script (`review-prepare.ps1`, `review-run.ps1`, `review-verify.ps1`) 는 여전히 flat layout 을 emit 하는 transitional divergence 상태이며 (`docs/REVIEW_RESULT_CONTRACT.md` §4a), script alignment 는 별도 scoped goal 의 대상이다.
- `log/review/<run-id>/meta.json` — `review-prepare.ps1` 가 작성하던 run-id, target SHA-256, source HEAD, reviewer config, freshness policy, `targetFiles[]`, `reviewRequest` provenance 등을 담은 sidecar JSON. 단순화 이후 contract 는 binding sidecar 없이 input.md / result.md 한 쌍을 한 pass 의 단위로 본다.
- `log/review/<run-id>/result.json` — `review-cycle.ps1` 가 verdict parsing 성공 시 작성하던 machine-readable verdict + hash binding (`inputSha256`, `resultMarkdownSha256`, `targetSha256` 등). 단순화 이후 verdict 의 source-of-truth 는 같은 pass 의 `result.md` 의 `## Verdict` 다.
- `log/review/<run-id>/target-files.list` — informational snapshot 이었으며 freshness 검증 대상은 아니었다. 단순화 이후 target file 목록은 input.md 의 informational `## Target files` section 으로 흡수되었다.
- `log/review-targets/<slug>.list` — `-TargetFilesPath` 의 외부 staging file. 단순화 이후 staging file 채널은 normal operator path 가 아니다.
- `log/review-requests/<purpose-or-timestamp>.md` — Stage 3 `-ReviewRequestPath` 의 외부 staging file. 위 §"Review-cycle file-backed request input" 의 단순화 closeout 과 함께 normal operator path 에서 제거되었다.

운영자가 disk 에서 위 식별자들의 파일을 발견하면, 그 파일은 이전 transitional implementation 의 잔존물이며 본 contract 의 review record 가 아니다. 사용자 판단에 따라 삭제 가능한 runtime noise 다. 본 항목은 그 historical reason 의 단일 보관처다.

scripts 의 실제 동작이 canonical contract 와 정렬되도록 transitional artifact 의 생성을 끄는 alignment 작업은 별도 scoped goal 의 대상이다. 본 항목 자체는 그 alignment 의 commit / push / global current/ refresh / scripts mutation 어느 것도 자동 승인하지 않는다.

### Non-goals

- 본 항목 자체로 scripts / tests / config / global filesystem 을 mutate 하지 않는다.
- canonical artifact (`input.md` / `result.md`) 외 sidecar 파일의 자동 prune / delete 도입 아님 — 운영자 판단으로 삭제한다.
- removed legacy artifact 의 normal operator path 복원 / parallel mode 부활 아님 — 본 항목은 historical reason 만 보관한다.
- 본 항목 자체가 commit / push / global current/ refresh / criteria 변경 어느 것도 자동 승인하지 않는다.
