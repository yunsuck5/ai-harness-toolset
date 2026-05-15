# Brief Contract

본 contract 는 ai-harness-toolset 의 **Brief** 책임 영역, 그리고 그것을 다루는 두 source-side primitive (`scripts/brief-init.ps1`, `scripts/brief-check.ps1`) 의 책임 경계를 정의한다.

본 문서는 **manual convention first** 문서다. hook, parser, daemon, watcher, scheduler, retention automation 은 포함하지 않는다.

## 핵심 정의 — Brief vs Chatlog

- **Brief** 는 한 project 의 **durable restore source-of-truth** 다. 작업을 (재)개할 때 가장 먼저 읽는 한 자리이며, 여러 session 에 걸쳐 의미가 유지된다.
- **Chatlog** 는 Brief 가 아니다. Chatlog 는 history / decision rationale / Brief reconstruction evidence 다. 현재 restore source 가 아니다 (`docs/CHATLOG_CONTRACT.md`).
- 두 책임은 분리되어 있고 한쪽이 다른 쪽을 대체하지 않는다. Brief 가 오염 / 삭제 / stale 인 경우 Chatlog 가 Brief 재구성의 evidence 가 될 수 있으나, 그 자체가 Brief 의 자리는 아니다.

## BF Level — save/restore capability maturity

본 contract 가 사용하는 **BF Level** 표현은 path 가 아니라 **save / restore capability maturity** 를 가리킨다. 어떤 BF Level 도 특정 파일 경로의 의미가 아니다.

| Level | 의미 | 현재 상태 |
|---|---|---|
| BF Level 1 | manual save / restore discipline. operator (또는 operator role 의 AI agent) 가 durable restore 상태를 사람이 읽기 좋은 형태로 직접 작성하고, 새 session 진입 시 그 자리를 직접 다시 읽어 작업을 복원한다. 자동화 없음. | 운영 중. 사람 / AI agent 가 수행. |
| BF Level 2 | 같은 manual save / restore discipline 을, snippet protocol 또는 합의된 자연어 trigger 로 더 일관되게 적용하는 단계. 여전히 자동화는 없고, agent 가 protocol 을 따른다는 의미만 있다. | 운영 중. snippet / protocol 채택 시 활성. |
| BF Level 3 | **deterministic Brief maintenance / validation / stale warning / session-start guidance / restore-offer** 의 자동화. agent 또는 사람이 BRIEF 본문을 직접 손편집하는 모델이 아니다. deterministic writer 가 BRIEF 의 갱신 / 점검 / 경고 / restore-offer 를 일관되게 수행한다. | **현재 미구현.** future scoped work. |

핵심:

- BF Level 은 maturity 다. 같은 자리에서 더 일관되고 더 deterministic 한 운영으로 올라가는 layer 다. Level 별로 다른 path 를 두지 않는다.
- BF Level 3 의 목표는 **사람이 BRIEF 본문을 손편집하는 모델의 안정화가 아니다.** 반대로, BRIEF 의 유지 / 검증 / restore-offer 를 deterministic 하게 수행해 손편집 의존을 줄이는 방향이다.
- 현재 `scripts/brief-init.ps1` / `scripts/brief-check.ps1` 는 BF Level 3 의 **full implementation 이 아니라** source-side primitive 다 (아래 §"source-side primitive 책임" 참조). 두 script 가 존재한다고 해서 BF Level 3 capability 가 갖춰진 상태는 아니다.
- BF Level 1/2 에서 사람이 BRIEF 를 손으로 작성하는 부분은 BF Level 3 가 deterministic writer 로 흡수해야 할 대상이다. 본 contract 는 그 흡수의 완료를 강제하지 않는다.

## target repo canonical Brief 자리

- target repo 의 **product canonical restore source** 는 `<ProjectRoot>/brief/BRIEF.md` 다.
- 이 자리는 target repo 가 자기 자신의 durable restore state 를 두는 product-level location 이다. 어느 BF Level 의 운영이라도 target repo 의 restore entrypoint 는 이 한 자리다.
- 현재 source-side primitive 의 writer destination 은 이 자리와 일치하지 않는다 (`<ProjectRoot>/log/brief/BRIEF.md` 로 seed). 그 불일치는 아래 §"현재 source-side primitive 상태" 에서 다룬다.
- target repo 의 canonical 자리를 `brief/BRIEF.md` 로 정합화하고 deterministic writer 를 그쪽으로 routing 하는 작업은 BF Level 3 의 일부 future scoped work 다.

## 현재 source-side primitive 상태

`scripts/brief-init.ps1` / `scripts/brief-check.ps1` 은 현재 시점의 narrow source-side primitive 다. BF Level 3 의 full capability 가 아니다.

- `brief-init.ps1` — `<ProjectRoot>/log/brief/BRIEF.md` 에 template artifact 를 한 번 seed. 이미 존재하면 default 동작은 거부 (no overwrite).
- `brief-check.ps1` — 지정된 BRIEF artifact 의 shape (canonical heading 8 종, placeholder / sentinel 잔존, duplicate, empty body) 만 검증. read-only.

위 두 primitive 의 writer destination 은 현재 `<ProjectRoot>/log/brief/BRIEF.md` 다. 이는 다음의 의미를 갖는다.

- `ai-harness-toolset` 가 자기 자신을 dogfooding ProjectRoot 로 동작할 때, 그 결과로 생기는 `<ToolsetRepoRoot>/log/brief/BRIEF.md` 는 **ai-harness-toolset 내부 runtime artifact** 다. operator-local 이며 source payload 도 install payload 도 아니다.
- 같은 primitive 를 target repo 에 적용해도 현재 동작상 writer 는 `<TargetRoot>/log/brief/BRIEF.md` 에 쓴다. 이 자리에 생긴 파일은 **target repo 의 product canonical restore source 로 승격되지 않는다.** product canonical 은 `<ProjectRoot>/brief/BRIEF.md` 이며, 그 routing 은 위에서 적은 대로 future scoped work 다.
- 따라서 본 contract 는 `<ProjectRoot>/log/brief/BRIEF.md` 의 존재를 금지하지 않는다. 단, 그 자리를 product 의 canonical restore source 로 해석하는 것은 금지한다.

## Future scoped work — 본 contract 가 자동 승인하지 않는 항목

아래는 BF Level 3 capability 의 완성에 필요하지만 본 contract 가 자동 승인하지 않는 항목이다. 각각 별도 scoped 승인이 필요하다.

- deterministic save / update writer — agent 또는 사람이 BRIEF 본문을 손편집하지 않고도 정해진 trigger 에 따라 BRIEF 를 갱신하는 writer.
- restore-offer behavior — 새 session 진입 시 BRIEF 를 읽고 현재 상태 / 다음 단일 action / do-not-do / pending user decision 을 사용자에게 요약 보고하고, "이 복구 지점에서 이어서 진행할까요?" 류의 확인을 받는 흐름. 본 contract 는 그 흐름의 source-side automation 을 강제하지 않는다.
- stale warning — BRIEF 가 일정 시간 / 일정 작업 단위 이상 갱신되지 않은 상태를 감지하고 사용자에게 알리는 메커니즘.
- session-start guidance — 새 agent session 이 BRIEF 를 가장 먼저 읽도록 일관되게 유도하는 deterministic guidance.
- writer routing 의 target canonical (`brief/BRIEF.md`) 정합화 — 현재 source-side primitive 의 writer destination 을 target canonical 자리로 옮기는 작업.
- 위 항목들의 source-side automation 을 ai-harness-toolset 내부에 도입할지, 외부 의도에 위임할지의 decision.

이 항목들이 implementation 되기 전까지, BRIEF 작성 / 유지 자체는 BF Level 1/2 의 manual discipline 으로 운영된다. 본 contract 는 그 manual discipline 을 영구화하는 것이 아니라, BF Level 3 에서 흡수할 대상으로 명시한다.

## BRIEF 의 위치와 독자

target repo 의 BRIEF artifact 자리는 `<ProjectRoot>/brief/BRIEF.md` 한 곳이다.

독자 우선순위:

- 제 1 독자는 그 project 를 지금 운영하는 **operator** 다. 작업 (재)개 시 가장 먼저 열어 durable 상태를 복원한다.
- 제 2 독자는 **AI agent** 다. 새 CLI agent session, long context 손실 후 복원, 또는 cross-session handoff 시 첫 진입점이다.
- BRIEF 는 shared human handoff 문서가 아니다. 다른 사람에게 넘길 durable project 정보는 BRIEF 가 아니라 그 project 의 정식 docs 가 담는다.

BRIEF 는 짧고 자족적이어야 한다. 누적 history, 자세한 review payload, evidence 본문, raw transcript 는 BRIEF 본문에 옮겨 적지 않고 path / link 로만 가리킨다.

## source repo vs target repo 경계

- source repo (`ai-harness-toolset`) 의 source 트리에는 target 의 BRIEF artifact 를 두지 않는다. `templates/brief/BRIEF.md` 는 template 자리이며 실제 BRIEF artifact 가 아니다.
- target repo 의 product canonical Brief artifact 는 `<ProjectRoot>/brief/BRIEF.md` 다. 본 contract 는 그 자리의 운영 책임을 target repo 의 operator 에게 둔다.
- `ai-harness-toolset` 가 자기 자신을 dogfooding ProjectRoot 로 동작할 때 생기는 `log/brief/BRIEF.md` 는 ai-harness-toolset 내부 runtime artifact 다. target 의 product canonical 자리로 해석되지 않는다.

## tracked vs gitignored — target canonical 자리

`<ProjectRoot>/brief/BRIEF.md` 의 tracked 여부는 본 contract 의 hard rule 이 아니다. target repo 의 operator 가 결정한다.

- target repo 의 운영자가 `brief/BRIEF.md` 를 tracked 로 두면, 그 BRIEF 는 그 project 의 shared restore state 가 된다.
- 운영자가 untracked / gitignored 로 두면 그 BRIEF 는 operator-local restore state 다.
- 둘 중 어느 쪽이든 본 contract 는 BRIEF 를 "shared project source-of-truth" 로 격상하지 않는다. 협업 공유가 필요한 durable project 정보는 BRIEF 가 아니라 그 project 의 정식 docs 가 담는다.

`<ProjectRoot>/log/brief/BRIEF.md` (= 현재 source-side primitive 의 writer destination) 의 default 기대값은 **gitignored (untracked)** 이다. 이는 `<ProjectRoot>/log/` 가 runtime artifact tree 이고 `.gitignore` 의 `log/` 규칙으로 ignored 되기 때문이다.

## Chatlog 와의 관계

- Chatlog (`<ProjectRoot>/log/chatlog/`) 는 Brief 가 아니다. 본 contract 는 Chatlog 의 자리를 정의하지 않는다 — Chatlog 의 contract 는 `docs/CHATLOG_CONTRACT.md` 다.
- 과거 docs 가 `log/chatlog/current/resume.md` / `summary.md` 를 "canonical BF Level 1/2 artifact" 로 묶어 부르던 형태는 본 contract 에서 더 이상 유효하지 않다. 두 파일은 **failed intermediate / legacy migration source / deprecation candidate** 다 (`docs/CHATLOG_CONTRACT.md`).
- Chatlog 는 Brief 가 오염 / 삭제 / stale 인 경우 Brief 재구성을 위한 evidence 로 사용될 수 있다. 그러나 Chatlog 자체가 현재 restore source 로 승격되지 않는다.
- Brief 와 Chatlog 사이의 자동 mirror 는 본 contract 의 책임이 아니며, 어느 future scoped work 도 mirror 자동화를 자동 승인하지 않는다.

## BRIEF required / optional headings

BRIEF artifact (`<ProjectRoot>/brief/BRIEF.md`, 그리고 현재 source-side primitive 가 seed 하는 `<ProjectRoot>/log/brief/BRIEF.md`) 는 다음 canonical heading 을 사용한다.

required:

- `## Current state`
- `## Last completed action`
- `## Current scope`
- `## Next single action`
- `## Do not do`
- `## Files to inspect first`
- `## Open risks`
- `## Pending user decision`

optional:

- `## Relevant artifacts`
- `## Carry-over`
- `## Notes`

durable-project interpretation:

| heading | BRIEF 의미 |
|---|---|
| Current state | project 의 durable 상태. branch, 최근 milestone, 현재 phase |
| Last completed action | 가장 최근의 durable milestone |
| Current scope | 지금 phase / workstream 의 범위 |
| Next single action | 다음 durable 단계의 단일 action |
| Do not do | project 차원에서 명시적으로 금지된 항목 (scope guardrail) |
| Files to inspect first | 새 session 이 가장 먼저 읽을 path |
| Open risks | project 차원의 알려진 위험 / 가정 / unknown |
| Pending user decision | project 방향에 영향을 주는 미결 결정 |
| Relevant artifacts (optional) | durable artifact 위치 (path 만; 본문 인라인 금지) |
| Carry-over (optional) | phase / workstream 간 이월 항목 |
| Notes (optional) | durable 운영 메모. session 단위 잡담은 여기로 옮기지 않는다. |

required heading 중 내용이 없으면 `none` 으로 채운다. optional heading 은 필요할 때만 추가한다. 임의의 새 top-level heading 은 만들지 않는다. ad-hoc 정보는 canonical heading 아래 bullet 또는 subsection 으로 흡수한다.

## source-side primitive 책임

### brief-init.ps1

`scripts/brief-init.ps1` 은 BRIEF artifact 를 한 번 seed 하는 idempotent CLI 다. BF Level 3 capability 의 full implementation 이 아니다.

required behavior:

- `ProjectRoot`, `ToolRoot` 를 resolve.
- `<ToolRoot>/templates/brief/BRIEF.md` 를 read.
- 현재 default writer destination 은 `<ProjectRoot>/log/brief/BRIEF.md` 다. 이 destination 을 target canonical (`<ProjectRoot>/brief/BRIEF.md`) 로 옮기는 작업은 future scoped work 다.
- destination directory 가 없으면 생성. 이미 BRIEF 가 있으면 default 동작은 거부 (no overwrite).
- 작성 IO 는 `scripts/lib/encoding.ps1` 의 함수만 사용. 결과 파일은 UTF-8 without BOM.

forbidden behavior:

- `.gitignore` 변경.
- 글로벌 파일 변경 (`~/.claude/`, root `CLAUDE.md`, root `AGENTS.md`).
- daemon / watcher / scheduler / hook / background process 등록.
- BRIEF 내용 자동 생성 (template 의 placeholder 만 seed; 사람이 채운다 — 이 점은 본 primitive 의 한계이며, BF Level 3 가 흡수해야 할 대상이다).
- commit / push / publish / merge / release 자동 실행.

종료 코드는 file IO 결과만 반영한다. verdict 의미를 갖지 않는다.

### brief-check.ps1

`scripts/brief-check.ps1` 은 BRIEF artifact 의 shape 만 검증하는 read-only CLI 다.

required behavior:

- `ProjectRoot` 를 resolve.
- 명시적 path argument 가 있으면 그 path 를 사용하되 ProjectRoot 안쪽이어야 한다. 명시 path 없으면 현재 primitive 의 default target 인 `<ProjectRoot>/log/brief/BRIEF.md` 를 검사한다.
- target 파일이 없으면 FAIL exit non-zero.
- canonical heading 8 종이 모두 존재하는지 검증.
- duplicate required heading 거부.
- required heading 의 본문이 비어있지 않은지 검증 (`none` 도 본문으로 본다).
- `{{TOKEN}}` 형태의 unreplaced placeholder 거부.
- template 의 placeholder-only sample 문장 잔존 거부.
- PASS / FAIL 메시지를 stdout 에 출력.
- read 만 한다. 어떤 파일도 mutate 하지 않는다.

forbidden behavior:

- `yes` / `no` / `yes with risk` verdict 생성. BRIEF 검증은 review verdict 가 아니다.
- commit / push / publish / merge / release 승인 또는 차단.
- 다른 자리 (`log/chatlog/`, `log/review/`, `log/evidence/`) 의 정합성 검증.
- BRIEF 내용 자동 보정 (auto-fix loop 금지).
- daemon / watcher / scheduler / hook / background process.
- 글로벌 파일 변경.

## review / commit / push 경계

- BRIEF 는 review subsystem 의 input 이 아니며 output 도 아니다.
- BRIEF 는 commit / push / release 게이트가 아니다.
- `brief-check.ps1` 의 PASS / FAIL 은 commit / push / release 를 자동으로 막거나 승인하지 않는다.
- review verdict (`yes` / `no` / `yes with risk`) 와 brief-check 결과 (PASS / FAIL) 는 다른 축이며 서로 enforcement 하지 않는다 (`docs/REVIEW_RESULT_CONTRACT.md`).

## encoding 정책

- BRIEF runtime artifact 는 UTF-8 without BOM 이다.
- `scripts/brief-init.ps1` / `scripts/brief-check.ps1` 의 파일 IO 는 `scripts/lib/encoding.ps1` 의 함수 (`Read-Utf8`, `Write-Utf8NoBom`) 를 사용한다.
- `Set-Content -Encoding UTF8`, `Add-Content -Encoding UTF8`, `Out-File`, `Get-Content -Raw` 는 사용하지 않는다.
- `.ps1` 소스 파일은 UTF-8 with BOM + CRLF 이다 (`docs/POWERSHELL_POLICY.md`).

## non-goals (본 contract 가 다루지 않는 것)

- BRIEF 자동 retention / prune / rotate / expire / delete.
- BRIEF 자동 mirror to/from Chatlog artifact.
- BRIEF schema validator (heading shape 외).
- BRIEF 자동 생성 또는 자동 보정 (auto-fill / auto-fix loop).
- BRIEF-driven commit / push / merge / release 게이트.
- `~/.claude/`, 글로벌 `CLAUDE.md` / `AGENTS.md`, project 의 `.gitignore` 자동 변경.
- daemon / watcher / scheduler / hook installer / background process.
- `BF_STATE.json` 같은 별도 state machine 파일.
- per-user log partitioning. operator-id / machine-id / ownership metadata / team sharing semantics.
- transcript JSONL parser, 사용자 prompt / assistant 응답 자동 capture.
- review history DB 또는 cross-run aggregation 과의 통합.
- BRIEF 와 evidence / review / Chatlog artifact 간 cross-tree enforcement.
- BRIEF 의 한 줄 요약을 commit message / PR body 에 자동 삽입.
- multi-Brief orchestration (한 project 안의 복수 BRIEF 파일).
- public release packaging.
- BF Level 3 capability 의 implementation 자체 (위 §"Future scoped work" 참조).
- 현재 source-side primitive 의 writer destination 을 `brief/BRIEF.md` 로 routing 하는 변경.
- `log/brief/BRIEF.md` 를 product canonical restore source 로 승격하는 모든 해석.

## 향후 확장 시 고려 사항

- 새 wrapper 또는 새 CLI 가 도입되어도 본 contract 의 target canonical (`<ProjectRoot>/brief/BRIEF.md`), heading set, 두 primitive 의 책임 경계는 default 로 유지한다.
- 새 schema 가 도입되어도 본 manual convention 과 모순되지 않도록 한다.
- BRIEF 가 review / evidence / Chatlog artifact 를 inline 으로 옮겨 적기 시작하면 본 contract 의 compact 원칙 위반이다. 그 경우 새 wrapper 가 아니라 BRIEF 본문이 잘못 작성된 것으로 본다.
- 위 §"Future scoped work" 항목이 별도 scoped 승인을 받아 implementation 되는 시점에는 본 contract 도 그에 맞춰 갱신된다. 갱신 자체가 본 contract 의 존재만으로 자동 승인되지 않는다.
