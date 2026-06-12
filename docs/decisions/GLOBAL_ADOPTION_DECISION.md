# Global Adoption Decision

> **현행 status routing.** 본 문서는 install/update/global-adoption 의 design/model/record source 다. **current 상태 / completed-ledger / deferred** 의 authoritative 자리는 `docs/systems/install-update/STATUS.md` + `docs/systems/install-update/DEFERRED.md` 다 (전체 routing 진입점: `docs/current/REPO_READING_GUIDE.md`; roadmap index: `docs/roadmap/INDEX.md`). 본 문서 본문과 system STATUS 가 충돌하면 current 판단은 STATUS 를 따른다.

본 문서는 `ai-harness-toolset` 의 운영 계층 전환 방향을 추적 가능한 형태로 보존한다. **결정의 기록이며, implementation 승인이 아니다.**

본 문서가 존재한다는 사실만으로 어떤 implementation, scoped work, scheduling, release 도 자동 승인되지 않는다. 각 항목은 별도 scoped 승인을 거친 뒤에만 작업이 시작된다.

이 문서는 `docs/decisions/POST_MVP_PLAN.md` 의 closeout 진술과 충돌하지 않는다. MVP closeout 은 그대로 유효하며, 본 문서는 그 이후 단계의 전환 방향만 기록한다.

> **Superseded (BRIEF posture reconciliation).** 본 문서가 target-local state / footprint 를 기술할 때
> `brief/` 를 별도 footprint 항목으로 언급하는 부분 (예: §4 의 target-local state 목록, §6 의 BriefRoot 정의)
> 은 이후의 BRIEF posture reconciliation 으로 superseded 되었다. 현재 BRIEF 는 `<ProjectRoot>/log/brief/BRIEF.md`
> 의 operator-local runtime state 이며, target 의 persistent footprint 는 `log/` only 다. root `<ProjectRoot>/brief/`
> 는 ai-harness 용도로 금지된다. canonical source-of-truth 는 `docs/brief/brief_spec.md` 다. 본문은 결정 기록으로 보존한다.

---

## 1. Decision summary

- `ai-harness-toolset` 을 **global/common AI development operating layer** 로 전환하는 방향을 문서화한다.
- target project 의 `CLAUDE.md` / `AGENTS.md` 는 **project-specific layer** 로 본다.
- 두 계층은 책임이 다르며, 한쪽이 다른 쪽을 대체하지 않는다.
- copy-only / project-local MVP 방식은 MVP 검증 단계에서는 유효했다. 다만 다중 프로젝트 운용에서는 배포 / 업데이트 / 정합성 유지 비용이 누적되므로, 동일 방식을 계속 확장하는 것은 본 방향이 아니다.
- 본 결정은 legacy `ai-harness` 의 installer-first 설계로 회귀하는 것이 아니다. legacy 의 global install 아이디어 자체는 틀린 것이 아니었고, 문제는 core functionality 보다 installer / rollback / global mutation 에 먼저 집중한 sequencing 이었다.

---

## 2. Background

- legacy `ai-harness` 단계.
  - global 도구화 의도 자체는 본 toolset 의 현재 방향과 정합적이다.
  - 단, core functionality 검증 이전에 installer / rollback / global mutation 을 먼저 productize 하려 한 sequencing 이 문제였다.
- `ai-harness-toolset` MVP 단계.
  - copy-only / CLI-only / project-local 방식으로 핵심 기능을 먼저 검증하기 위해 유효한 선택이었다.
  - MVP closeout 이후, core functionality (review subsystem, brief primitive, BF Level 1/2 manual save/restore discipline) 는 운영 가능 상태에 도달했다 (`POST_MVP_PLAN.md` §1, §2, §3 참조). 여기서 brief primitive 는 `scripts/brief-init.ps1` / `scripts/brief-check.ps1` 라는 narrow source-side primitive 를 가리키며, BF Level 3 capability (deterministic Brief maintenance / validation / stale warning / session-start guidance) 자체는 **미구현 future scoped work** 다 (`docs/brief/brief_spec.md` + `docs/brief/brief_backlog.md`). 무요청 session-start restore-offer 의 source-side automation 은 폐기되었다.
- 다중 프로젝트 운용 관점.
  - 동일 운영 규칙을 N 개의 target repo 에 각각 복제 / 동기화 하는 cost 가 누적된다.
  - shared/global 방식이 더 자연스러운 단계에 도달했다.

본 단계는 따라서 "MVP 가 끝났으니 installer 를 만들자" 가 아니라, "core 가 검증되었으니 운영 계층의 위치를 다시 정한다" 의 단계다.

---

## 3. Layer model

두 계층은 책임이 다르다. 본 문서는 분리 자체를 결정 사항으로 기록한다.

### Global/common layer

`ai-harness-toolset` 이 책임지는 범위.

- common AI development operating rules
- review / brief / evidence protocols
- Codex reviewer discipline
- verdict handling
- commit / push approval separation
- BF save / explicit Brief restore discipline
- global/shared toolset usage

### Project-specific layer

target project 의 `CLAUDE.md` / `AGENTS.md` 가 책임지는 범위.

- project architecture
- build / test commands
- coding conventions
- domain constraints
- repo-specific workflows
- phase / backlog state
- project-specific AI tools

### Boundary rule — global layer

Global layer 는 project-specific 사실을 포함하지 않는다. 다음은 명시적 금지 항목이다.

- 특정 project 의 architecture 설명
- 특정 project 의 현재 phase / backlog state
- per-repo run-id 또는 target-specific identifier
- target-specific build / test command (단, generic example 로 명시되어 있다면 예외)

### Boundary rule — project layer

Project-local layer 는 `ai-harness-toolset` 의 core safety contract 를 별도 승인 없이 재정의하지 않는다.

- review verdict handling
- commit / push approval separation
- BF / review / evidence 책임 분리
- explicit scoped approval rules

target project 가 위 contract 를 보강 / 강화하는 것은 가능하다. 약화 / 우회 / 무효화는 별도 scoped 승인이 필요하다.

---

## 4. Adoption direction

본 절은 방향만 기록한다. 구체적인 invocation 형식, script signature, error handling, fallback 동작은 별도 audit (§8) 와 별도 scoped 승인을 거친 뒤에 결정한다.

### Preferred direction

- `ai-harness-toolset` 의 source of truth 는 본 git repo 로 유지한다.
- update flow 는 `git clone` / `git pull` 을 기본으로 본다.
- `scripts/`, `config/`, `templates/`, `snippets/`, Claude skill 자산은 shared/global candidate 다.
- target project 는 기본적으로 `.ai-harness/` 같은 copied tool 폴더를 포함하지 않는 것이 선호 형태다.

### Target-local state / result boundary

target project 안에 남아야 하는 runtime artifact 는 다음 트리로 제한한다.

- `log/brief/`
- `log/evidence/`
- `log/review/`

위 3 개 트리는 모두 `<ProjectRoot>/log/` 아래의 target 별 state / result 이고, shared/global mode 에서도 target repo 안에 그대로 남는다 (3차 reconciliation 기준; canonical Brief = `<ProjectRoot>/log/brief/BRIEF.md`, root `<ProjectRoot>/brief/` 는 rejected — `docs/brief/brief_spec.md`).

### Preferred target repo shape

- `.ai-harness/` 없음 (default).
- scripts / templates / config / snippets 복사본 없음 (default).
- target-local state / result artifact 만 target repo 에 남는다.

### Fallback candidate

- 직접 shared script invocation 의 변경 폭이 너무 크다고 판단되는 시점이 오면, symlink / junction / link mode 가 후속 후보로 고려될 수 있다.
- 본 fallback 도 별도 scoped 승인이 필요하며, 본 문서가 자동 승인하지 않는다.

---

## 5. AI-guided adoption / update

adoption / update 의 preferred operator 는 AI 다. installer-first productization 이 아니다.

- 본 단계에서 `install.ps1` 같은 productized installer 를 서둘러 만들지 않는다.
- Claude Code 가 adoption / update 의 operator 역할을 한다.
- 절차는 inspectable, diff-based, approval-based 여야 한다.

기대되는 AI 절차 (개념 수준 기술).

1. 기존 global / target 파일 상태를 inspect 한다.
2. 충돌 / 이미 존재하는 marker block / 누락 항목을 detect 한다.
3. merge 또는 replacement 후보를 사용자에게 제안한다.
4. 사용자 승인을 명시적으로 받는다.
5. 승인된 변경만 적용한다.
6. 적용 후 verify 한다.

deterministic helper script (예: inspect-only, check-only) 는 후속 단계에서 추가될 수 있다. 단, 본 단계의 핵심은 installer-first productization 이 아니다.

사용자 측에서 예상되는 자연어 요청 예시 (예시일 뿐 contract 가 아니다).

- "ai-harness-toolset global adoption 진행해줘"
- "ai-harness-toolset 설치해줘"
- "ai-harness-toolset 업데이트해줘"

이 trigger 는 항상 §7 의 explicit approval 규칙을 따른다. 즉, global mutation, snippet 적용, skill install / update 등은 trigger 하나로 모두 자동 실행되지 않는다.

---

## 6. Managed block marker policy

본 절은 향후 source snippet 및 global 파일 update 에 적용할 marker 정책을 **방향 결정** 으로 기록한다. 다만 본 문서 자체에는 marker 가 적용되지 않으며, `snippets/CLAUDE_SNIPPET.md`, `snippets/AGENTS_SNIPPET.md` 에 실제 marker 를 삽입하는 작업은 본 문서 합의 이후의 별도 scoped 작업으로 남긴다.

### Recommended marker

```
<!-- BEGIN AI_HARNESS_TOOLSET_GLOBAL -->
...
<!-- END AI_HARNESS_TOOLSET_GLOBAL -->
```

### Marker detection (counting rule)

본 절은 위 marker 의 **detection algorithm** 을 명시한다. 본 절 이후의 모든 분기 (0 개, 정확히 1 개, 여러 개, incomplete pair, malformed, nested) 의 marker count 는 본 정의를 기준으로 판단한다.

**Algorithm.** Walk the destination file line by line, maintaining a single `in_fence` boolean (initially `false`). For each line:

1. If the line's trimmed content (leading / trailing ASCII whitespace removed) starts with at least three consecutive backticks (`` ``` ``) or three consecutive tildes (`~~~`), toggle `in_fence` and **do not count** this line as a marker. (This is the standard markdown fenced code block delimiter; the delimiter itself and every line inside the fence are excluded from counting.)
2. Otherwise, if `in_fence` is `true`, **do not count** this line as a marker.
3. Otherwise (line is outside any fenced code block), apply **whole-line trim match**: the line counts as a valid BEGIN marker if and only if its trimmed content is **exactly** the string `<!-- BEGIN AI_HARNESS_TOOLSET_GLOBAL -->`, with no other non-whitespace characters before or after on the same line. Similarly for END.

The following occurrences of the marker text are therefore **not** valid markers and are **never** counted:

- lines **inside any markdown fenced code block** (between matching ` ``` ` or `~~~` delimiters) — counted as code, not as marker delimiters. This is intentional, so that documentation files like this one can include a Recommended marker example in a fenced code block (see "Recommended marker" above, where the BEGIN / END lines appear inside ` ``` ` fence and must be ignored by detection).
- **markdown inline code spans** (backticked text on a non-fence line, e.g., a sentence containing `` `<!-- BEGIN AI_HARNESS_TOOLSET_GLOBAL -->` ``) — the line's trimmed content includes surrounding prose or backticks, so whole-line trim match fails.
- **prose / descriptive text** that mentions the marker as a literal example (e.g., a sentence that says "...delimited by `<!-- BEGIN AI_HARNESS_TOOLSET_GLOBAL -->` and `<!-- END AI_HARNESS_TOOLSET_GLOBAL -->`...") — surrounding non-whitespace on the same line prevents whole-line trim match.
- any line where the marker text appears as part of a longer line, anywhere other than as the sole non-whitespace content.

**Substring count** (naive count of marker text anywhere in the file, ignoring fences and line structure) is **not** the detection rule. It can produce false positives because the snippet bodies (`snippets/CLAUDE_SNIPPET.md` and `snippets/AGENTS_SNIPPET.md`) intentionally quote the marker text within their description prose as inline literal documentation, and because this very §6 includes a fenced Recommended marker example whose BEGIN / END lines must be ignored by detection. The prose / fence quotation is by design — the documentation explains what the markers look like to a human reader, while the actual marker lines on a real destination file are the unfenced, unquoted lines that bracket the managed block.

**Fence-pair pathology.** If `in_fence` remains `true` after walking the entire file (unbalanced fence — an odd number of ` ``` ` or `~~~` delimiter lines), the file is considered structurally malformed for managed-block purposes. The scanner reports an error and does not proceed; the file is treated as if its marker state were ambiguous, which falls into the manual-review condition below.

**Decision-equivalent statements** (all bind by the same whole-line-outside-fence rule):

- "matching marker pair" — exactly one whole-line BEGIN followed by exactly one whole-line END, both outside any fence, with no other whole-line BEGIN or END (outside any fence) anywhere in the file, and with the END appearing on a later line than the BEGIN.
- "no markers" — zero whole-line BEGIN and zero whole-line END outside any fence.
- "incomplete pair" — whole-line BEGIN count ≠ whole-line END count (both counted outside any fence).
- "duplicated" — whole-line BEGIN count > 1 or whole-line END count > 1 (outside any fence).
- "malformed" — whole-line END (outside any fence) appears before any whole-line BEGIN (outside any fence), or any other ordering violation, or the fence-pair pathology above.
- "nested" — between a whole-line BEGIN and its paired whole-line END (both outside any fence) there exists another whole-line BEGIN or whole-line END outside any fence.

Each of "incomplete pair", "duplicated", "malformed", "nested" is a fail-fast / manual-review condition (see the destination-state branches below). The detection rule does not change those branches; it only specifies the algorithm by which marker counts and ordering are determined.

### Update policy — global CLAUDE.md / AGENTS.md

marker-bounded block 의 전면 교체가 standard 로 허용되는 적용 방식이다. whole-file overwrite 는 금지하며, marker-bounded block 바깥의 기존 사용자 / project 내용은 보존한다. 본 동작은 implicit / automatic mutation 이 아니라, §7 의 explicit user-approved global / user config mutation scope 에서만 수행된다. 즉 "global mutation 금지" 는 implicit / automatic / whole-file mutation 의 금지를 의미하며, explicit user-approved managed-block replacement 와 충돌하지 않는다.

본 정책이 적용되는 instruction file 의 path 는 다음과 같이 명시 enumerate 한다 — generic 한 "global `AGENTS.md`" wording 만 사용하면 `%USERPROFILE%\.claude\AGENTS.md` 같은 잘못된 path 로 오인될 수 있으므로, 본 절은 official 경로를 명시한다.

| 대상 | path |
|---|---|
| Claude project-root | `<ProjectRoot>/CLAUDE.md` |
| Claude user-global | `%USERPROFILE%\.claude\CLAUDE.md` |
| Codex project-root | `<ProjectRoot>/AGENTS.md` |
| Codex user-global default | `%USERPROFILE%\.codex\AGENTS.md` |
| Codex user-global with `CODEX_HOME` | `%CODEX_HOME%\AGENTS.md` |
| Codex user-global override | `AGENTS.override.md` at the same Codex user-global scope (예: `%USERPROFILE%\.codex\AGENTS.override.md`) takes precedence over `AGENTS.md` when both exist |
| **Forbidden** | `%USERPROFILE%\.claude\AGENTS.md` — 어떤 agent 의 global instruction 경로도 아니며, ai-harness 는 절대 이 file 을 생성하지 않는다 |

위 path 들에 대한 managed-block apply 는 모두 동일한 marker policy (아래 destination 분기) 를 따른다. snippet 별 매핑은 `snippets/CLAUDE_SNIPPET.md` → Claude 측 path 군, `snippets/AGENTS_SNIPPET.md` → Codex 측 path 군이다. 두 snippet 은 모두 dual-role safe 로 설계되어 있어 (loaded agent 가 operator / reviewer / auditor / supervisor 어느 역할이든 무관하게 적용), 어느 destination 에 load 되더라도 loaded agent 가 항상 operator 라고 가정하지 않는다 (이 role-neutral framing 은 각 snippet 의 intro 에 명시되며, operator vs reviewer-mode 의 binding 구분은 `ai-harness-review` / `ai-harness-brief` skill 이 소유한다 — snippet 은 minimal bootstrap 으로 축소되었다, `docs/architecture/instruction-surface/GLOBAL_SNIPPET_HARD_MINIMIZATION_CORRECTIVE.md`).

destination 의 파일 존재 여부와 marker pair 상태에 따라 동작이 다르다.

- destination file 자체가 **존재하지 않는** 경우.
  - missing file 의 생성은 별도 explicit approval boundary 다 (아래 marker 0 개 케이스와 구분된다).
  - 생성 예정 경로와 삽입할 내용을 사용자에게 제안한다.
  - 사용자 승인을 받는다.
  - 승인된 경우에만 파일을 생성하고 source snippet 전체 (marker 포함) 를 기록한다.
- destination file 은 존재하지만 matching marker pair 가 **0 개** 인 경우.
  - marker 가 없는 기존 파일에 block 을 삽입하는 행위는 (missing file 생성과 구분되는) 별도 explicit approval boundary 다.
  - 삽입 지점을 사용자에게 제안한다.
  - 사용자 승인을 받는다.
  - source snippet 전체 (marker 포함) 를 삽입한다.
- destination 에 matching marker pair 가 **정확히 1 개** 인 경우.
  - diff 를 사용자에게 보여준다.
  - 사용자 승인을 받는다.
  - marker-bounded block 전체를 source snippet (marker 포함) 으로 교체한다. 이 케이스에서는 marker 안쪽만 교체할 수 있다.
- destination 에 marker pair 가 **불완전 (BEGIN / END 한쪽 누락)**, **여러 개**, **malformed**, **nested** 인 경우.
  - 동작을 중단한다 (fail-fast).
  - 충돌을 보고하고 manual review 대상으로 둔다.
  - 파일을 편집하지 않는다.
- marker-bounded block **바깥** 의 텍스트는 어떤 경우에도 편집하지 않는다.

### Important sequencing

- 본 작업에서는 `snippets/CLAUDE_SNIPPET.md`, `snippets/AGENTS_SNIPPET.md` 에 marker 를 적용하지 **않는다**.
- snippet marker 적용은 본 문서가 합의된 뒤의 후속 작업이다 (§9 의 추천 순서 참조).
- **(현재 상태, historical update — 2026-05-22)** 위 두 bullet 은 본 §6 작성 라운드 기준의 sequencing 기록이다. 그 후속 작업은 완료되었다: `snippets/CLAUDE_SNIPPET.md` / `snippets/AGENTS_SNIPPET.md` 에 marker pair 가 적용되어 있고, deterministic managed-block apply / activation tooling 이 `scripts/apply-managed-block.ps1` / `scripts/activate-global.ps1` 로 존재한다 (closeout: `docs/systems/install-update/STATUS.md` IU-OPS-05; 상세는 git history).

---

## 7. Global default does not mean automatic action

본 절은 본 문서에서 가장 오해되기 쉬운 경계를 명시적으로 기록한다.

```
global default rules: yes
automatic state-changing actions: no
```

### Always-applicable global operating rules

다음은 trigger 없이 항상 적용되는 운영 규칙이다.

- review verdict 는 commit / push 승인이 아니다.
- "no" verdict 는 scoped fix plan 을 제안하고 승인을 기다린다.
- "yes with risk" verdict 는 risk 를 설명하고 go / no-go 를 받는다.
- BF / review / evidence 의 책임은 분리되어 있다.
- global mutation 은 explicit approval 이 필요하다.
- commit / push / publish 는 explicit approval 이 필요하다.
- state-changing 작업 전에 repo root / branch / status 를 확인한다.
- review / evidence / brief runtime artifact 는 모두 target-local `<ProjectRoot>/log/` 아래로 들어간다 (3차 reconciliation 기준; canonical Brief 는 `<ProjectRoot>/log/brief/BRIEF.md`, root `<ProjectRoot>/brief/` 는 rejected — `docs/brief/brief_spec.md`). 이전 라운드의 "brief artifact 는 target-local `brief/` 아래" wording 은 historical/superseded.

### Explicit trigger / approval required

다음 행위는 default 가 아니라, 사용자 명시 trigger 와 scoped 승인을 거친 뒤에만 실행된다.

- review execution (`scripts/review-prepare.ps1` → `scripts/review-run.ps1` canonical two-step entry; spec-of-record: `docs/review/review_spec.md`)
- brief-init execution
- brief-check execution
- BF save
- global `CLAUDE.md` / `AGENTS.md` 의 managed block update
- Claude skill install / update
- script / config / template update
- commit
- push
- release / publish / deploy

"global default" 는 운영 규칙이 항상 적용된다는 의미이지, 어떤 행위가 자동 실행된다는 의미가 아니다.

---

## 8. ToolRoot / ProjectRoot audit requirement

shared/global mode 로 전환하기 전에 path handling audit 가 선행되어야 한다. 본 절은 audit 자체의 요구 사항을 기록한다.

### Conceptual split

- `ToolRoot` — `<canonical-local-toolroot>` (`ai-harness-toolset` source repo root)
- `ProjectRoot` — current target repo root
- `LogRoot` — `<ProjectRoot>/log`
- `BriefRoot` — `<ProjectRoot>/log/brief` (3차 reconciliation 기준; root `<ProjectRoot>/brief` 는 rejected — `docs/brief/brief_spec.md`. 이전 라운드의 `<ProjectRoot>/brief` 표기는 historical/superseded.)
- `ConfigRoot` — `<ToolRoot>/config`
- `TemplateRoot` — `<ToolRoot>/templates`
- `ScriptRoot` — `<ToolRoot>/scripts`

### Potential future invocation example

본 형식은 contract 가 아니라 audit 단계의 검토 대상 예시였다 (not a contract). 현행 normal operator path 는 canonical task/pass topology 채택 (POST_MVP_PLAN §10 Completed `c81fe45`) 이후 두 단계 entry 다. strict C1 에서 현행 script 는 `-Perspective <viewpoint>` 를 **요구** 한다 (미지정 / 빈 값이면 fail-fast; spec-of-record: `docs/review/review_spec.md`) — 예시 형식만 갱신하면 다음과 같다.

```
powershell -NoProfile -ExecutionPolicy Bypass `
  -File <canonical-local-toolroot>/scripts/review-prepare.ps1 `
  -ProjectRoot . `
  -ReviewTaskId <id> `
  -Perspective <viewpoint> `
  -Stage implementation `
  -Purpose '<one-line purpose>'

powershell -NoProfile -ExecutionPolicy Bypass `
  -File <canonical-local-toolroot>/scripts/review-run.ps1 `
  -ProjectRoot . `
  -ReviewTaskId <id> `
  -Perspective <viewpoint> `
  -Pass <pass-NN>
```

### Audit targets

- `scripts/review-prepare.ps1`
- `scripts/review-run.ps1`
- `scripts/review-verify.ps1`
- `scripts/review-input-verify.ps1`
- `scripts/brief-init.ps1`
- `scripts/brief-check.ps1`
- `config/reviewer.json`
- `templates/**`
- `snippets/claude-skills/**`

### Core audit question

```
Can scripts run from global/shared ToolRoot while writing all runtime/state artifacts to target ProjectRoot?
```

### Sequencing

- audit 가 완료되고, 그 결과가 별도 scoped 승인을 받은 뒤에 shared/global script 동작을 implementation 한다.
- **본 audit 이전에 shared/global script behavior 를 implementation 하지 않는다.**

---

## 9. Deferred work / roadmap implication

`clean target smoke test criteria` 작업은 본 문서로 인해 **연기** 된다.

### Reason

- `clean target smoke test criteria` 는 adoption mode 에 의존한다.
- target 이 `.ai-harness/` 를 포함하지 않는 형태로 결정되면, smoke test 기준 자체가 달라진다.
- 따라서 adoption 방향 결정이 먼저다.

### Recommended next order

본 순서는 추천이며, 각 항목은 별도 scoped 승인이 필요하다.

1. 본 문서 (`GLOBAL_ADOPTION_DECISION.md`) 에 대한 Codex review.
2. `POST_MVP_PLAN.md` 의 remaining order update.
3. `snippets/CLAUDE_SNIPPET.md` / `snippets/AGENTS_SNIPPET.md` 에 marker 적용.
4. Claude skill 의 global adoption / update 절차 문서화.
5. ToolRoot / ProjectRoot path handling audit (§8).
6. shared / global mode implementation (별도 승인 시에만).
7. clean target smoke test criteria.
8. clean target smoke test.

본 문서는 위 순서 중 어떤 단계도 자동 승인하지 않는다.

---

## 10. Explicit non-goals

본 결정은 다음 항목들을 **포함하지 않는다**. 본 문서가 존재한다는 사실만으로 아래 항목이 승인 / 실행되었다고 해석하지 않는다.

- automatic global mutation.
- 사용자 diff / 승인 없이 진행되는 global `CLAUDE.md` / `AGENTS.md` 재작성.
- 사용자 diff / 승인 없이 진행되는 기존 skill overwrite.
- installer-first productization.
- rollback framework.
- registry / project list / target inventory.
- daemon / watcher / scheduler.
- automatic target project update.
- automatic commit / push / release.
- 본 단계에서의 path handling implementation.
- 본 단계에서의 clean target smoke test 실행.

위 항목은 별도 scoped 승인 없이 실행 / implementation 되지 않는다.
