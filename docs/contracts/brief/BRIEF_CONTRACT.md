# Brief Contract

본 contract 는 ai-harness-toolset 의 **Brief** 책임 영역, 그리고 그것을 다루는 세 source-side primitive (`scripts/brief-init.ps1`, `scripts/brief-check.ps1`, `scripts/brief-status.ps1`) 의 책임 경계를 정의한다.

본 문서는 **manual convention first** 문서다. hook, parser, daemon, watcher, scheduler, retention automation 은 포함하지 않는다.

## 핵심 정의 — Brief vs Chatlog

- **Brief** 는 한 project 의 **durable restore source-of-truth** 다. 사용자가 명시적으로 복원을 요청할 때 읽는 한 자리이며 (무요청 session-start 자동 읽기는 없다), 여러 session 에 걸쳐 의미가 유지된다.
- **Chatlog** 는 Brief 가 아니다. Chatlog 는 history / decision rationale / Brief reconstruction evidence 다. 현재 restore source 가 아니다 (`docs/contracts/chatlog/CHATLOG_CONTRACT.md`).
- 두 책임은 분리되어 있고 한쪽이 다른 쪽을 대체하지 않는다. Brief 가 오염 / 삭제 / stale 인 경우 Chatlog 가 Brief 재구성의 evidence 가 될 수 있으나, 그 자체가 Brief 의 자리는 아니다.

## BF Level — save/restore capability maturity

본 contract 가 사용하는 **BF Level** 표현은 path 가 아니라 **save / restore capability maturity** 를 가리킨다. 어떤 BF Level 도 특정 파일 경로의 의미가 아니다.

| Level | 의미 | 현재 상태 |
|---|---|---|
| BF Level 1 | manual save / restore discipline. operator 는 BF 저장 / 복원 / 폐기의 **trigger / approve / reject / discard** 주체이며 BRIEF 본문을 손으로 편집하지 않는다. BRIEF 본문의 생성 / 갱신은 명시적 AI-assisted command flow (operator 의 trigger 시 agent 가 본문을 작성) 또는 deterministic tooling 이 담당하고, **사용자가 명시적으로 복원을 요청하면** 그 자리를 다시 읽어 작업을 복원한다 (무요청 session-start 자동 읽기 / 제안은 없다). 자동화 없음. | 운영 중. operator trigger + agent (또는 tooling) 가 본문 작성. |
| BF Level 2 | 같은 manual save / restore discipline 을, `ai-harness-brief` skill protocol 또는 합의된 자연어 trigger 로 더 일관되게 적용하는 단계. operator 의 책임은 여전히 trigger / approve / reject / discard 이며, BRIEF 본문은 agent 가 그 protocol 을 따라 작성한다. 자동 detect / 자동 갱신 은 없다. | 운영 중. `ai-harness-brief` skill / 합의된 trigger 채택 시 활성. |
| BF Level 3 | **deterministic Brief maintenance / validation / stale warning / session-start guidance** 의 자동화. deterministic writer 또는 명시적 AI-assisted command flow 가 BRIEF 의 갱신 / 점검 / 경고 를 일관되게 수행하며, operator 가 BRIEF 본문을 손편집하지 않는 점은 BF Level 1/2 와 동일하다. | **현재 미구현.** future scoped work. (무요청 session-start restore-offer 의 source-side automation 은 BF Level 3 component 가 아니다 — retire 됨; `docs/systems/brief/DEFERRED.md` BR-D-02.) |

핵심:

- BF Level 은 maturity 다. 같은 자리에서 더 일관되고 더 deterministic 한 운영으로 올라가는 layer 다. Level 별로 다른 path 를 두지 않는다.
- BRIEF 본문은 어느 Level 에서도 **사람이 손으로 편집하는 모델에 의존하지 않는다.** operator 는 trigger / approve / reject / discard 의 주체이며, 본문 생성 / 갱신은 deterministic tooling 또는 명시적 AI-assisted command flow 가 담당한다 (clean decision memo D-BRIEF-8). BF Level 3 의 방향은 그 generation / update layer 자체를 deterministic 하게 만드는 것이며, BF Level 1/2 의 hand-edit 운영을 안정화하는 것이 아니다.
- 현재 `scripts/brief-init.ps1` / `scripts/brief-check.ps1` / `scripts/brief-status.ps1` 는 BF Level 3 의 **full implementation 이 아니라** source-side primitive 다 (아래 §"source-side primitive 책임" 참조). 세 script 가 존재한다고 해서 BF Level 3 capability 가 갖춰진 상태는 아니다.
- BF Level 1/2 의 manual save 단계에서 agent 가 본문 작성을 담당하는 흐름은 BF Level 3 의 deterministic writer 가 흡수해야 할 대상이다. 본 contract 는 그 흡수의 완료를 강제하지 않는다. (무요청 session-start restore-offer 자동화는 retire 됨 — 흡수 대상이 아니다; `docs/systems/brief/DEFERRED.md` BR-D-02.)

## canonical Brief 자리 — project-local runtime under `<ProjectRoot>/log/`

- 한 project 의 **canonical Brief 자리** 는 `<ProjectRoot>/log/brief/BRIEF.md` 다.
- 이 자리는 **project-local, operator-local, source-control-excluded** runtime artifact 다.
  - **project-local** — 그 project 의 checkout 안 (`<ProjectRoot>/log/` 트리 안) 에 위치한다. 다른 project 의 Brief 와 섞이지 않는다. user-home global runtime root (예: `%USERPROFILE%\.ai-harness\projects\<project-key>\...`) 는 canonical 이 아니며 본 contract 가 도입하지 않는다.
  - **operator-local** — 각 운영자의 local checkout 안에 존재한다는 의미다. team-shared 가 아니다. 같은 project 의 다른 운영자 / 다른 machine 의 Brief 는 별개 instance 다.
  - **source-control-excluded** — `<ProjectRoot>/log/` 는 target project 의 `.gitignore` 의 `log/` 규칙으로 ignored 되며, Brief 는 그 아래의 runtime artifact 다. commit / push / merge / release / publish 대상이 아니고 product source 의 일부도 아니다. "project-local" 은 "repo-tracked" 의 동의어가 아니다.
- 현재 source-side primitive (`scripts/brief-init.ps1`) 의 writer destination 이 정확히 이 자리이며, `scripts/brief-check.ps1` 의 default check path 도 이 자리다. canonical 자리와 primitive 의 destination 은 일치한다.
- `<ProjectRoot>/brief/BRIEF.md` (root `brief/`) 는 **rejected** 다. 본 contract 의 canonical Brief 자리가 아니며, 어떤 BF Level 의 운영에서도 ai-harness 용도로 root `<ProjectRoot>/brief/` 를 생성하지 않는다.

### Historical lineage (preserved, not current)

본 자리의 결정은 두 단계의 reconciliation 을 거쳐 왔다.

- **1차 reconciliation (historical, superseded)** — 한때 canonical 을 `<ProjectRoot>/log/brief/BRIEF.md` 로 두고 root `<ProjectRoot>/brief/` 를 forbidden 으로 표기한 framing.
- **2차 reconciliation (historical, superseded)** — 그 framing 이 정정되어 target repo product canonical Brief 를 `<ProjectRoot>/brief/BRIEF.md` 로 두고, `<ProjectRoot>/log/brief/BRIEF.md` 를 narrow source-side primitive 의 seed destination (operator-local runtime artifact, not promoted to canonical) 으로 분류한 framing.
- **3차 reconciliation (현행, 본 contract 본문)** — 위 2차 framing 도 정정되었다. canonical Brief 는 `<ProjectRoot>/log/brief/BRIEF.md` 한 자리이며, root `<ProjectRoot>/brief/` 는 rejected, user-home operator-local runtime root 도 rejected, target persistent footprint = `<ProjectRoot>/log/` only. 본 본문의 모든 정의가 우선한다.

위 lineage 표기는 silent deletion 을 피하기 위한 기록이다. 다른 docs / snippet / template / script / test 에 남아 있는 1차 또는 2차 wording 은 본 본문의 정의로 읽는다. 그 wording 자체의 정합화는 별도 scoped work 다.

## 현재 source-side primitive 상태

`scripts/brief-init.ps1` / `scripts/brief-check.ps1` / `scripts/brief-status.ps1` 은 현재 시점의 narrow source-side primitive 다. BF Level 3 의 full capability 가 아니다.

- `brief-init.ps1` — `<ProjectRoot>/log/brief/BRIEF.md` 에 template artifact 를 한 번 seed. 이미 존재하면 default 동작은 거부 (no overwrite).
- `brief-check.ps1` — 지정된 BRIEF artifact 의 shape (canonical heading 8 종, placeholder / sentinel 잔존, duplicate, empty body) 만 검증. read-only.
- `brief-status.ps1` — canonical Brief 자리의 존재 여부를 확인하고, shape 검증은 `brief-check.ps1` 에 delegate 한 뒤, shape PASS 인 경우 required heading 8 종 각각의 첫 비어있지 않은 본문 줄을 Korean label 과 함께 stdout 으로 출력. read-only. explicit user-requested Brief restore / status discipline 의 deterministic input 으로 호출자가 활용한다. 호출 시점, confirm UX, stale 판단은 본 primitive 의 책임이 아니다.

세 primitive 의 destination / default check path / default read path 는 canonical Brief 자리 (`<ProjectRoot>/log/brief/BRIEF.md`) 와 일치한다. 위 §"canonical Brief 자리" 의 정의가 primitive 의 동작과 정합한다.

- `ai-harness-toolset` 가 자기 자신을 dogfooding ProjectRoot 로 동작할 때, 그 결과로 생기는 `<ToolsetRepoRoot>/log/brief/BRIEF.md` 는 ai-harness-toolset 자신의 self-dogfooding canonical Brief instance 다. operator-local runtime artifact 이며 source payload / install payload / 다른 project 의 Brief 와 무관하다.
- 외부 target repo 에 primitive 를 적용해도 같은 자리 (`<TargetRoot>/log/brief/BRIEF.md`) 가 canonical 이다. routing 변경 future scoped work 는 없다 — destination 자체가 이미 canonical 이다.

primitive 의 narrow 성격은 destination 의 문제가 아니라 capability 의 문제다 — deterministic save / update writer, stale warning, deterministic session-start guidance (호출 시점의 자동화) 같은 BF Level 3 의 자동화는 세 primitive 가 제공하지 않는다 (§"Future scoped work" 참조). `brief-status.ps1` 은 explicit user-requested Brief restore / status discipline 이 사용할 수 있는 deterministic summary input 만 제공하며, 그 자체가 호출 시점이나 confirm UX 를 자동화하지 않는다. (무요청 session-start restore-offer 의 source-side automation 은 retire 됨 — `docs/systems/brief/DEFERRED.md` BR-D-02.)

## Future scoped work — 본 contract 가 자동 승인하지 않는 항목

아래는 BF Level 3 capability 의 완성에 필요하지만 본 contract 가 자동 승인하지 않는 항목이다. 각각 별도 scoped 승인이 필요하다.

- deterministic save / update writer — agent 또는 사람이 BRIEF 본문을 손편집하지 않고도 정해진 trigger 에 따라 BRIEF 를 갱신하는 writer.
- ~~restore-offer behavior~~ — **retired (not future scoped work).** 무요청 session-start restore-offer 의 source-side automation 은 폐기됨 (`docs/systems/skills/FUNCTION_LEVEL_SKILL_ARCHITECTURE_PLAN.md` §3 / `docs/systems/brief/DEFERRED.md` BR-D-02). 명시적 user-requested Brief restore — 사용자가 직접 복원을 요청할 때 BRIEF 를 읽고 현재 상태 / 다음 단일 action / do-not-do / pending user decision 을 요약 보고하고 "이 복구 지점에서 이어서 진행할까요?" 류의 확인을 받는 흐름 — 은 현행 manual capability (BF Level 1/2) 로 유지되며, `brief-status.ps1` 이 그 manual discipline 의 deterministic summary input 을 제공한다. 무요청 자동 제안의 source-side automation 만 retire 된 것이며, BR-D-01 (deterministic writer) · BR-D-03 (stale warning · session-start guidance) 는 future scoped work 로 유지된다.
- stale warning — BRIEF 가 일정 시간 / 일정 작업 단위 이상 갱신되지 않은 상태를 감지하고 사용자에게 알리는 메커니즘.
- session-start guidance — 새 agent session 이 BRIEF 를 가장 먼저 읽도록 일관되게 유도하는 deterministic guidance. `brief-status.ps1` 의 deterministic summary 출력은 그 guidance 가 호출 시점에 활용할 수 있는 input 일 뿐이며, 호출 자체를 강제하거나 자동화하지 않는다.
- 위 항목들의 source-side automation 을 ai-harness-toolset 내부에 도입할지, 외부 의도에 위임할지의 decision.

primitive 의 writer destination 은 이미 canonical (`<ProjectRoot>/log/brief/BRIEF.md`) 이므로 "writer routing 의 target canonical 정합화" 는 더 이상 BF Level 3 의 future scoped work 항목이 아니다. (2차 reconciliation 의 잔재였으며, 3차 reconciliation 으로 자연 해소되었다 — §"canonical Brief 자리" Historical lineage 참조.)

이 항목들이 implementation 되기 전까지, BRIEF 작성 / 유지 자체는 BF Level 1/2 의 manual discipline 으로 운영된다. 본 contract 는 그 manual discipline 을 영구화하는 것이 아니라, BF Level 3 에서 흡수할 대상으로 명시한다.

## BRIEF 의 위치와 독자

target repo 의 BRIEF artifact 자리는 `<ProjectRoot>/log/brief/BRIEF.md` 한 곳이다. root `<ProjectRoot>/brief/` 와 user-home operator-local runtime root 는 BRIEF 자리가 아니다 (§"canonical Brief 자리" 참조).

독자 우선순위:

- 제 1 독자는 그 project 를 지금 운영하는 **operator** 다. 명시적으로 복원을 요청할 때 이 자리를 열어 durable 상태를 복원한다 (무요청 session-start 자동 읽기는 없다).
- 제 2 독자는 **AI agent** 다. 사용자가 명시적으로 복원을 요청하면 (새 CLI agent session, long context 손실 후 복원, 또는 cross-session handoff 시) 이 자리를 진입점으로 삼는다 — 무요청 자동 진입은 아니다.
- BRIEF 는 shared human handoff 문서가 아니다. 다른 사람에게 넘길 durable project 정보는 BRIEF 가 아니라 그 project 의 정식 docs 가 담는다.

BRIEF 는 짧고 자족적이어야 한다. 누적 history, 자세한 review payload, evidence 본문, raw transcript 는 BRIEF 본문에 옮겨 적지 않고 path / link 로만 가리킨다.

## source repo vs target repo 경계

- source repo (`ai-harness-toolset`) 의 source 트리에는 어떤 project 의 BRIEF artifact 도 두지 않는다. `templates/brief/BRIEF.md` 는 template 자리이며 실제 BRIEF artifact 가 아니다.
- target repo 의 canonical Brief artifact 는 `<ProjectRoot>/log/brief/BRIEF.md` 다 — 그 project 의 checkout 안 `log/` 트리 아래 operator-local runtime artifact. 본 contract 는 그 자리의 운영 책임을 target repo 의 operator 에게 둔다.
- `ai-harness-toolset` 가 자기 자신을 dogfooding ProjectRoot 로 동작할 때 생기는 `<ToolsetRepoRoot>/log/brief/BRIEF.md` 는 그 self-dogfooding instance 의 canonical Brief 다. 외부 target 의 Brief 와 동일한 종류의 runtime artifact 이며, source / install payload 가 아니다.

## tracked vs gitignored — canonical Brief 자리

`<ProjectRoot>/log/brief/BRIEF.md` 의 default 기대값은 **gitignored (untracked)** 이다. 이는 `<ProjectRoot>/log/` 가 runtime artifact tree 이고 target project 의 `.gitignore` 의 `log/` 규칙으로 ignored 되기 때문이다. 결과적으로 canonical Brief 는 commit / push / merge / release / publish 대상이 아니며 product source 의 일부도 아니다.

- "project-local" 은 그 project 의 checkout 안에 있다는 의미이지 "repo-tracked" 라는 의미가 아니다.
- "operator-local" 은 각 운영자의 local checkout 안에 instance 가 존재한다는 의미이지 user-home 의 global state 라는 의미가 아니다. 같은 project 라도 운영자마다 / machine 마다 별개 instance 다.
- 협업 공유가 필요한 durable project 정보는 BRIEF 가 아니라 그 project 의 정식 docs 가 담는다. BRIEF 를 "shared project source-of-truth" 로 격상하지 않는다.

operator 가 명시적으로 결정해 `<ProjectRoot>/log/` 의 `.gitignore` 규칙을 깨고 BRIEF 를 tracked 로 두는 것은 본 contract 가 정의하지 않는 운영 결정이다. 본 contract 의 default 기대는 untracked 이며, ai-harness 는 그 default 위에서 동작한다.

## Chatlog 와의 관계

- Chatlog (`<ProjectRoot>/log/chatlog/`) 는 Brief 가 아니다. 본 contract 는 Chatlog 의 자리를 정의하지 않는다 — Chatlog 의 contract 는 `docs/contracts/chatlog/CHATLOG_CONTRACT.md` 다.
- 과거 docs 가 `log/chatlog/current/resume.md` / `summary.md` 를 "canonical BF Level 1/2 artifact" 로 묶어 부르던 형태는 본 contract 에서 더 이상 유효하지 않다. 두 파일은 **failed intermediate / legacy migration source / deprecation candidate** 다 (`docs/contracts/chatlog/CHATLOG_CONTRACT.md`).
- Chatlog 는 Brief 가 오염 / 삭제 / stale 인 경우 Brief 재구성을 위한 evidence 로 사용될 수 있다. 그러나 Chatlog 자체가 현재 restore source 로 승격되지 않는다.
- Brief 와 Chatlog 사이의 자동 mirror 는 본 contract 의 책임이 아니며, 어느 future scoped work 도 mirror 자동화를 자동 승인하지 않는다.

## BRIEF required / optional headings

BRIEF artifact (canonical 자리 `<ProjectRoot>/log/brief/BRIEF.md`) 는 다음 canonical heading 을 사용한다.

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
| Files to inspect first | 복원 시 가장 먼저 확인할 path |
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
- writer destination 은 canonical Brief 자리 `<ProjectRoot>/log/brief/BRIEF.md` 다. routing 변경 future scoped work 는 없다 — destination 자체가 canonical 이다 (§"canonical Brief 자리").
- destination directory 가 없으면 생성. 이미 BRIEF 가 있으면 default 동작은 거부 (no overwrite).
- 작성 IO 는 `scripts/lib/encoding.ps1` 의 함수만 사용. 결과 파일은 UTF-8 without BOM.

forbidden behavior:

- `.gitignore` 변경.
- 글로벌 파일 변경 (`~/.claude/`, root `CLAUDE.md`, root `AGENTS.md`).
- daemon / watcher / scheduler / hook / background process 등록.
- BRIEF 내용 자동 생성 (`brief-init.ps1` 는 template 의 placeholder 만 seed 한다; 채워진 본문 / 후속 갱신은 본 primitive 의 책임이 아니다). 본 단계의 placeholder → 사실 채움은 BF Level 1/2 manual save discipline 의 explicit AI-assisted command flow (operator trigger / approve, agent writes) 또는 deterministic tooling 이 담당하며, BF Level 3 가 deterministic writer 로 흡수해야 할 대상이다 — operator 의 손편집에 의존하는 모델이 아니다.
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

### brief-status.ps1

`scripts/brief-status.ps1` 은 canonical Brief 의 존재 여부 + shape 검증 결과 (delegated) + required heading 별 첫 비어있지 않은 본문 줄을 Korean label 과 함께 stdout 으로 출력하는 read-only CLI 다. explicit user-requested Brief restore / status discipline 의 deterministic input 으로만 활용된다.

required behavior:

- `ProjectRoot` 를 resolve.
- 명시적 path argument 가 있으면 그 path 를 사용하되 ProjectRoot 안쪽이어야 한다. 명시 path 없으면 현재 primitive 의 default target 인 `<ProjectRoot>/log/brief/BRIEF.md` 를 검사한다.
- target 파일이 없으면 FAIL exit non-zero. diagnostic 출력에 부재 사실을 명시.
- shape 검증은 `scripts/brief-check.ps1` 를 child process 로 호출해 그 결과 / exit code 를 그대로 사용한다. brief-check 의 책임 / 출력 / verdict-not-verdict 의미를 변경하지 않는다. brief-check 의 출력 각 줄은 `brief-status: brief-check: <line>` 형태로 prefix 를 붙여 stdout 에 그대로 emit 한다.
- shape FAIL 인 경우 그 exit code 를 그대로 전달하고 summary 출력은 하지 않는다.
- shape PASS 인 경우, canonical heading 8 종 각각에 대해 본문의 첫 비어있지 않은 줄 (Trim 후) 을 추출하여 `brief-status: <Korean label>: <line>` 형태로 출력한다. 본문이 모두 비어 있으면 (이 경우는 brief-check PASS 와 상호 모순이므로 정상 흐름에서는 도달 불가) `(empty)` 로 fallback.
- exit code 는 file presence + shape result 로만 결정. verdict 의미 부여 금지.
- 작성 IO 없음. 어떤 파일도 mutate 하지 않는다.

forbidden behavior:

- `yes` / `no` / `yes with risk` verdict 생성. commit / push / publish / merge / release / adoption 승인 또는 차단.
- BRIEF 본문 mutation. shape 검증 의미 변경. `brief-check.ps1` 의 책임 확장.
- stale heuristic (mtime 임계, HEAD SHA cross-check, branch 비교 등) 도입.
- session-start restore / confirm-prompt UX 의 자동화 (어떤 형태든; 무요청 restore-offer 포함). session-start hook / SessionStart hook / OnStop hook / OnPromptSubmit hook / 어떤 형태의 background trigger.
- daemon / watcher / scheduler / hook / background process.
- 글로벌 파일 변경, `.gitignore` 변경, snapshot / manifest / handoff 생성.

종료 코드는 file presence + shape result 로만 결정한다. verdict 의미를 갖지 않는다.

## review / commit / push 경계

- BRIEF 는 review subsystem 의 input 이 아니며 output 도 아니다.
- BRIEF 는 commit / push / release 게이트가 아니다.
- `brief-check.ps1` 의 PASS / FAIL 은 commit / push / release 를 자동으로 막거나 승인하지 않는다.
- review verdict (`yes` / `no` / `yes with risk`) 와 brief-check 결과 (PASS / FAIL) 는 다른 축이며 서로 enforcement 하지 않는다 (`docs/contracts/review/REVIEW_RESULT_CONTRACT.md`).

## encoding 정책

- BRIEF runtime artifact 는 UTF-8 without BOM 이다.
- `scripts/brief-init.ps1` / `scripts/brief-check.ps1` / `scripts/brief-status.ps1` 의 파일 IO 는 `scripts/lib/encoding.ps1` 의 함수 (`Read-Utf8`, `Write-Utf8NoBom`) 를 사용한다. `brief-status.ps1` 은 read-only 이므로 `Read-Utf8` 만 사용한다.
- `Set-Content -Encoding UTF8`, `Add-Content -Encoding UTF8`, `Out-File`, `Get-Content -Raw` 는 사용하지 않는다.
- `.ps1` 소스 파일은 UTF-8 with BOM + CRLF 이다 (`docs/policies/POWERSHELL_POLICY.md`).

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
- root `<ProjectRoot>/brief/` 를 canonical Brief 자리로 되살리는 모든 해석. (그 자리는 본 contract 가 reject 했다.)
- user-home operator-local runtime root (예: `%USERPROFILE%\.ai-harness\projects\<project-key>\...`) 를 canonical Brief 자리로 도입하는 변경.
- `<ProjectRoot>/log/brief/BRIEF.md` 외의 자리를 canonical Brief 의 동의어로 부르는 모든 해석.

## 향후 확장 시 고려 사항

- 새 wrapper 또는 새 CLI 가 도입되어도 본 contract 의 canonical Brief 자리 (`<ProjectRoot>/log/brief/BRIEF.md`), heading set, 세 primitive 의 책임 경계는 default 로 유지한다.
- 새 schema 가 도입되어도 본 manual convention 과 모순되지 않도록 한다.
- BRIEF 가 review / evidence / Chatlog artifact 를 inline 으로 옮겨 적기 시작하면 본 contract 의 compact 원칙 위반이다. 그 경우 새 wrapper 가 아니라 BRIEF 본문이 잘못 작성된 것으로 본다.
- 위 §"Future scoped work" 항목이 별도 scoped 승인을 받아 implementation 되는 시점에는 본 contract 도 그에 맞춰 갱신된다. 갱신 자체가 본 contract 의 존재만으로 자동 승인되지 않는다.
