# Brief / BF Level 3 Contract

`brief/BRIEF.md` 라는 단일 파일을 사용해 target project 의 **durable project restore** 상태를 어떤 최소 형식으로 남길지 정의한다.

이 문서는 **manual convention first** 문서다. hook, parser, daemon, watcher, scheduler, retention automation 은 포함하지 않는다.

이 문서는 generated artifact 의 schema 를 강제하지 않는다. `scripts/brief-init.ps1` 과 `scripts/brief-check.ps1` 의 책임 경계를 정의하고, 사람이 읽고 쓰는 `brief/BRIEF.md` 의 minimum shape 만 합의한다.

## 목적

- `brief/BRIEF.md` 는 target project 의 **durable project restore file** 이다. 새로운 사람이나 새로운 AI agent 가 그 project 를 처음 잡을 때 가장 먼저 읽는 long-lived brief 다.
- session 단위 restore 가 아니다. 한 session 끝에 갱신되거나 매일 갱신될 필요는 없다. project 의 durable 한 방향, 현재 phase, do-not-do, 다음 단일 action 처럼 **여러 session 에 걸쳐 의미가 유지되는 사실** 을 담는다.
- 본 contract 는 `brief/BRIEF.md` 의 위치, 이름, 작성 원칙, 최소 구조, 그리고 그것을 다루는 두 script 의 책임 경계에 관한 합의다.

## BF Level 1 / 2 / 3 정의

본 contract 가 사용하는 BF (Brief) Level 표현은 다음 의미다. 각 Level 은 **자리** 와 **trigger 방식** 으로 구분된다.

| Level | 자리 | trigger | 자동화 정도 |
|---|---|---|---|
| BF Level 1 | `log/chatlog/current/resume.md`, `log/chatlog/current/summary.md` | 사용자 자연어 발화 (snippet protocol) | manual convention only |
| BF Level 2 | 위와 같은 자리, 같은 자연어 trigger 에 대한 더 일관된 적용 | snippet 기반 restore-offer / save protocol | semi-conventional, snippet-driven |
| BF Level 3 | `<project-root>/brief/BRIEF.md` | 명시적 CLI 호출 (`brief-init.ps1`) + 사람의 손편집 | deterministic CLI primitive only |

세 Level 은 **자리** 와 **trigger** 가 다르고, 한쪽이 다른 쪽을 대체하지 않는다.

## brief/BRIEF.md 의 위치와 독자

`brief/BRIEF.md` 는 target project 트리 안에서 다음 경로에 둔다.

```
<ProjectRoot>/brief/BRIEF.md
```

독자 우선순위:

- 제 1 독자는 **사람** 이다. 새로운 collaborator 또는 새로운 maintainer 가 가장 먼저 열어 project 의 durable 상태를 파악한다.
- 제 2 독자는 **AI** 다. 새로운 CLI agent session 또는 long context 손실 후 복원 시 추가 진입점이 된다.

`brief/BRIEF.md` 는 짧고 자족적이어야 한다. 누적 history, 자세한 review payload, evidence 본문, raw transcript 는 BRIEF 안에 옮겨 적지 않고 path 만 가리킨다.

## source repo vs target repo 경계

본 toolset (`ai-harness-toolset`) source repo 는 자기 자신의 source tree 안에 root `brief/` 디렉터리를 두지 않는다.

- source repo 안에 `brief/BRIEF.md` 를 tracked source artifact 로 commit 하지 않는다.
- source repo 의 `templates/brief/BRIEF.md` 는 template 자리이며, 실제 BRIEF artifact 가 아니다.
- target project 가 source repo 의 4 개 폴더 (`config/`, `scripts/`, `snippets/`, `templates/`) 를 `.ai-harness/` payload 로 복사한 뒤, 그 target project 의 root 에 `brief/BRIEF.md` 를 둔다.
- `<source-repo-root>/log/brief/`, `<target-project-root>/log/brief/` 는 **모두 만들지 않는다.** `log/` 는 runtime artifact 트리이고 BRIEF 의 자리가 아니다.

이 경계는 `docs/AI_HARNESS_TOOLSET_SCOPE.md` 의 source-vs-target 경계와 같은 정신이다. BRIEF 는 target-side durable artifact 이며, source repo 는 그것을 만들 수 있는 template + script 만 ship 한다.

## tracked vs gitignored 기본값

`<project-root>/brief/BRIEF.md` 의 default 기대값은 **target repo 의 git history 에 tracked 된다** 이다.

근거:

- BRIEF 는 durable project restore 다. 협업자, 다음 maintainer, 새 machine 의 새 clone 에서도 같은 BRIEF 를 보고 시작할 수 있어야 한다.
- 가벼운 markdown 한 파일이므로 commit noise 부담이 작다.
- session 단위 high-frequency 갱신은 BF Level 1/2 (`log/chatlog/current/`) 의 책임이며 그쪽은 gitignored 다.

운영 규칙:

- toolset 은 target project 의 `.gitignore` 를 **자동으로 수정하지 않는다.**
- target adopter 가 `brief/BRIEF.md` 를 **gitignore 하기로** 결정한 경우, 본 contract 는 그 결정을 막지 않는다. 단, 그 경우 협업자/새 clone 환경에서 BRIEF 가 부재하다는 점을 adopter 가 직접 책임진다.
- `brief-init.ps1` / `brief-check.ps1` 모두 tracked 여부를 검사하지 않는다. tracked 여부는 운영 정책일 뿐 contract 의 hard rule 이 아니다.

## log/chatlog/current/resume.md 와의 관계

`brief/BRIEF.md` (BF Level 3) 와 `log/chatlog/current/resume.md` (BF Level 1/2) 는 **coexist / no-mirror** 관계다.

| 자리 | 시간 단위 | 갱신 주체 | source-of-truth 영역 |
|---|---|---|---|
| `<ProjectRoot>/brief/BRIEF.md` | durable (project-level) | 사람 또는 명시적 CLI 호출 | project 전체의 long-lived restore 상태 |
| `<ProjectRoot>/log/chatlog/current/resume.md` | volatile (current session) | snippet protocol / 사용자 자연어 발화 / AI agent | 현재 session 단위 restore / handoff state |
| `<ProjectRoot>/log/chatlog/current/summary.md` | volatile (current session) | 위와 동일 | session 한 묶음의 결론 / 결정 / 변경 범위 |

규칙:

- 두 자리는 **공존** 한다. 한쪽이 다른 쪽을 대체하지 않는다.
- toolset 은 두 자리 사이에 **자동 mirror 를 수행하지 않는다.** 사람이 두 자리를 동시에 갱신할 수도, 한쪽만 갱신할 수도 있다.
- `brief/BRIEF.md` 는 project 의 durable 사실을 담고, `log/chatlog/current/resume.md` 는 직전 session 의 next-single-action 을 담는다. 충돌이 발생하면 사람이 명시적으로 둘 중 어느 쪽을 우선할지 결정한다.
- BRIEF 가 다른 artifact (review record, evidence case, chatlog session 디렉터리, CL 누적 history) 를 참조할 때는 path 만 적는다. 본문을 옮겨 적지 않는다 (`docs/CHATLOG_CONTRACT.md` 의 BF compact 원칙과 같은 정신).
- 새 collaborator / 새 agent 의 read 순서 권장:
  1. `<ProjectRoot>/brief/BRIEF.md` (durable project restore — BF Level 3)
  2. `<ProjectRoot>/log/chatlog/current/resume.md` (current session restore — BF Level 1/2)
  3. `<ProjectRoot>/log/chatlog/current/summary.md` (current session compact companion — BF Level 1/2)
  4. 그 외 review / evidence / CL artifact 는 BRIEF 또는 resume.md 가 path 로 가리킨 항목만 추가로 읽는다.

## brief/BRIEF.md required / optional headings

`brief/BRIEF.md` 는 다음 canonical heading 을 사용한다. 이 heading set 은 의도적으로 `templates/session-resume.md` 의 heading set 과 동일하다. 의미 해석만 durable-project 지향으로 다르게 적용한다 (아래 표 참조).

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

durable-project interpretation (session-resume 와의 차이):

| heading | session-resume 의미 | BRIEF (BF Level 3) 의미 |
|---|---|---|
| Current state | 직전 session 끝 시점의 repo / project 상태 | project 의 durable 상태. branch, 최근 milestone, 현재 phase |
| Last completed action | 직전에 끝낸 의미 있는 작업 단위 | 가장 최근의 durable milestone (예: phase 종결, 핵심 결정 채택) |
| Current scope | 지금 묶음의 범위 | 지금 phase / workstream 의 범위 |
| Next single action | 다음에 정확히 한 가지로 해야 할 행동 | 다음 durable 단계의 단일 action |
| Do not do | 이 시점에 명시적으로 하지 말 것 | project 차원에서 명시적으로 금지된 항목 (scope guardrail) |
| Files to inspect first | 다음 agent 가 가장 먼저 읽을 파일 | 새 collaborator / 새 agent 가 가장 먼저 읽을 path |
| Open risks | 알고 있는 위험 / unknown | project 차원의 알려진 위험, 가정, unknown |
| Pending user decision | 사용자 판단 대기 항목 | project 방향에 영향을 주는 미결 결정 |

optional heading 의 durable-project interpretation:

| heading | session-resume 의미 | BRIEF (BF Level 3) 의미 |
|---|---|---|
| Relevant artifacts | session 관련 산출물 위치 | project 의 durable artifact 위치 (예: 핵심 contract 문서, 핵심 template, 누적 review record root, 대표 evidence case root). path 만 적고 본문은 옮기지 않는다. |
| Carry-over | 이번 session 에서 다음 session 으로 넘어가는 항목 | phase 또는 workstream 사이에서 다음 phase 로 이월되는 항목. session-단위 carry-over 가 아니라 phase-단위 carry-over. |
| Notes | session 운영 메모 | project 차원의 운영 메모. canonical heading 에 들어가지 않는 durable 사실만 남긴다. session 단위 잡담은 BF Level 1/2 의 `log/chatlog/current/` 자리에 두고, 여기로 옮기지 않는다. |

required heading 중 내용이 없으면 `none` 으로 채운다. optional heading 은 필요할 때만 추가한다. 임의의 새 top-level heading 은 만들지 않는다. ad-hoc 정보는 canonical heading 아래 bullet 또는 subsection 으로 흡수한다.

이 heading 정책은 `docs/CHATLOG_CONTRACT.md` 의 canonical heading 정책 / ad-hoc heading mapping 과 같은 정신이다.

## brief-init.ps1 책임

`scripts/brief-init.ps1` 은 target project 의 root 에 BRIEF artifact 를 한 번 seed 하는 idempotent CLI 다.

required behavior:

- `ProjectRoot`, `ToolRoot` 를 resolve 한다.
- `<ToolRoot>/templates/brief/BRIEF.md` 를 read 한다.
- `<ProjectRoot>/brief/` 디렉터리가 없으면 생성한다.
- `<ProjectRoot>/brief/BRIEF.md` 가 없으면 template 으로부터 seed 한다.
- `<ProjectRoot>/brief/BRIEF.md` 가 이미 존재하면 default 동작은 **거부 (no overwrite)** 다. 사용자가 명시적으로 overwrite 의도를 표시하지 않는 한 덮어쓰지 않는다.
- 작성 IO 는 `scripts/lib/encoding.ps1` 의 함수만 사용한다. 결과 파일은 UTF-8 without BOM.

forbidden behavior:

- `.gitignore` 변경 (target / source 양쪽 모두).
- 글로벌 파일 변경 (`~/.claude/`, root `CLAUDE.md`, root `AGENTS.md`).
- `<ProjectRoot>/log/` 또는 `<ProjectRoot>/log/brief/` 생성.
- daemon, watcher, scheduler, hook, background process 등록.
- BRIEF 내용 자동 생성 (template 그대로의 placeholder 만 seed; 사람이 채운다).
- source repo 모드에서 source repo root 에 `brief/` 를 만드는 것. test fixture 는 `$TestDrive` 안에서만 그러한 시나리오를 simulate 한다.
- commit / push / publish / merge / release 자동 실행.

`brief-init` 의 종료 코드는 file IO 결과만 반영한다. verdict 의미를 갖지 않는다.

## brief-check.ps1 책임

`scripts/brief-check.ps1` 은 BRIEF artifact 의 shape 만 검증하는 read-only CLI 다.

required behavior:

- `ProjectRoot` 를 resolve 한다.
- default target 은 `<ProjectRoot>/brief/BRIEF.md` 다. 명시적 path argument 가 있으면 해당 path 를 사용하되 ProjectRoot 안쪽이어야 한다.
- target 파일이 없으면 FAIL exit non-zero.
- required canonical heading 8 개가 모두 존재하는지 검증.
- duplicate required heading 거부.
- required heading 의 본문이 비어있지 않은지 검증 (`none` 도 본문으로 본다).
- `{{TOKEN}}` 형태의 unreplaced placeholder 거부.
- template 의 placeholder-only sample 문장 (예: `(Replace this placeholder ...)`) 잔존 거부.
- PASS / FAIL 메시지를 명시적으로 stdout 에 출력.
- read 만 한다. 어떤 파일도 mutate 하지 않는다.

forbidden behavior:

- `yes` / `no` / `yes with risk` verdict 생성. BRIEF 검증은 review verdict 가 아니다.
- commit / push / publish / merge / release 승인 또는 차단.
- 다른 자리 (`log/chatlog/current/`, `log/review/`, `log/evidence/`) 의 정합성 검증.
- BRIEF 내용 자동 보정 (auto-fix loop 금지).
- daemon, watcher, scheduler, hook, background process.
- 글로벌 파일 변경.

## review / commit / push 경계

- BRIEF 는 review subsystem 의 input 이 아니며 output 도 아니다.
- BRIEF 는 commit 게이트가 아니다.
- BRIEF 는 push 게이트가 아니다.
- BRIEF 는 release 게이트가 아니다.
- `brief-check.ps1` 의 PASS 는 review 통과를 의미하지 않는다. BRIEF artifact 의 shape 만 검증된 상태다.
- `brief-check.ps1` 의 FAIL 은 commit / push / release 를 자동으로 막지 않는다. 사용자가 결과를 읽고 직접 결정한다.
- review verdict (`yes` / `no` / `yes with risk`) 와 brief-check 결과 (PASS / FAIL) 는 다른 축이며 서로 상호 enforcement 하지 않는다 (`docs/REVIEW_RESULT_CONTRACT.md` 의 cross-tree 보장 부재 원칙과 같은 정신).

## 경로 규약

- source repo 모드: `<repo-root>/brief/` 는 만들지 않는다. `templates/brief/BRIEF.md` 는 source 트리에 둔다.
- target payload 모드: `<project-root>/brief/BRIEF.md` 만 BRIEF artifact 다.
- `log/brief/` 는 어떤 모드에서도 만들지 않는다.

## encoding 정책

- `brief/BRIEF.md` runtime artifact 는 UTF-8 without BOM 이다.
- `scripts/brief-init.ps1` / `scripts/brief-check.ps1` 의 파일 IO 는 `scripts/lib/encoding.ps1` 의 함수 (`Read-Utf8`, `Write-Utf8NoBom`) 를 사용한다.
- `Set-Content -Encoding UTF8`, `Add-Content -Encoding UTF8`, `Out-File`, `Get-Content -Raw` 는 사용하지 않는다.
- `.ps1` 소스 파일은 UTF-8 with BOM + CRLF 이다 (`docs/POWERSHELL_POLICY.md` 와 같은 정신).

## non-goals

이 contract 가 다루지 않는 것 (= 본 MVP slice scope 밖):

- BRIEF 자동 retention / prune / rotate / expire / delete.
- BRIEF 자동 mirror to/from `log/chatlog/current/resume.md`.
- BRIEF schema validator (heading shape 외).
- BRIEF 자동 생성 또는 자동 보정 (auto-fill / auto-fix loop).
- BRIEF-driven commit / push / merge / release 게이트.
- `~/.claude/`, 글로벌 `CLAUDE.md` / `AGENTS.md`, target project 의 `.gitignore` 자동 변경.
- daemon, watcher, scheduler, hook installer, background process.
- `BF_STATE.json` 같은 별도 state machine 파일.
- `log/brief/` 디렉터리.
- transcript JSONL parser, 사용자 prompt / assistant 응답 자동 capture.
- review history DB 또는 cross-run aggregation 과의 통합.
- BRIEF 와 evidence / review / CL artifact 간 cross-tree 보장.
- BRIEF 의 한 줄 요약을 commit message / PR body 에 자동 삽입.
- multi-Brief orchestration (한 project 안의 복수 BRIEF 파일).
- public release packaging.
- legacy ai-harness wholesale migration.

## forbidden artifacts

다음은 이 slice 와 후속 BRIEF 작업에서 절대 만들지 않는다.

- `<ProjectRoot>/log/brief/` (어떤 모드에서도)
- `BF_STATE.json` 또는 다른 별도 state machine 파일
- source repo (`ai-harness-toolset`) 의 root `brief/` (template 자리는 `templates/brief/`)
- daemon / watcher / scheduler / hook / background process
- 자동 `.gitignore` 변경 결과
- BRIEF-driven commit / push / release wrapper

## Future candidate

아래 항목은 버리지 않는다. 다만 이번 MVP slice 에서는 구현하지 않으며, 별도 scoped 승인이 필요하다.

- BRIEF 자동 sync hint (사람이 두 자리 (`brief/BRIEF.md` ↔ `log/chatlog/current/resume.md`) 사이에서 stale 여부를 손쉽게 비교할 수 있도록 돕는 read-only CLI).
- `brief-init.ps1` 의 explicit overwrite 옵션 (`-Force`).
- `brief-check.ps1` 의 strict / lenient mode 분리.
- 전용 BRIEF heading set (현재는 session-resume heading set 재사용).
- BRIEF 와 `docs/CHATLOG_CONTRACT.md` 의 통합 cross-link 절.
- BRIEF history retention 가이드.

## 향후 확장 시 고려 사항

- 새 wrapper 또는 새 CLI 가 도입되어도 본 contract 의 path (`<ProjectRoot>/brief/BRIEF.md`), heading set, 두 script 의 책임 경계는 default 로 유지한다.
- 새 schema 가 도입되어도 본 manual convention 과 모순되지 않도록 한다.
- 새 retention 정책은 단일 BRIEF 파일 단위 manual deletion 이 자연스럽게 가능하도록 설계한다.
- BRIEF 가 review / evidence / CL artifact 를 inline 으로 옮겨 적기 시작하면 본 contract 의 compact 원칙 위반이다. 그 경우 새 wrapper 가 아니라 BRIEF 본문이 잘못 작성된 것으로 본다.
