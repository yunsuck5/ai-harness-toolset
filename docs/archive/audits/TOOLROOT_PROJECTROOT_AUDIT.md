# ToolRoot / ProjectRoot Path Handling Audit

> **현행 status routing.** 본 문서는 완료된 audit / criteria **record (historical)** 다. install/update 의 current 상태는 `docs/systems/install-update/STATUS.md` + `docs/systems/install-update/DEFERRED.md` 가 authoritative 다 (전체 routing: `docs/current/SOURCE_OF_TRUTH.md`; roadmap index: `docs/roadmap/INDEX.md`). 본 문서를 current implementation/operation guidance 로 쓰지 않는다 — current 판단은 STATUS 를 따른다.

본 문서는 `ai-harness-toolset` 을 shared / global mode 로 전환하기 전에 수행해야 하는 **read-only path handling audit** 의 결과를 기록한다. **audit 의 기록이며, implementation 승인이 아니다.**

본 문서가 존재한다는 사실만으로 shared / global mode 의 implementation, path handling refactor, snippet 본문 재작성, scripts / config / templates 변경, clean target smoke test 가 자동 승인되지 않는다. 후속 작업은 각각 별도 scoped 승인을 거친다.

본 문서는 다음 source-of-truth 들과 충돌하지 않는다.

- 운영 계층 결정: `docs/decisions/GLOBAL_ADOPTION_DECISION.md`
- post-MVP 결정 기록: `docs/decisions/POST_MVP_PLAN.md`
- Claude skill global 절차: `docs/user_guide/GLOBAL_ADOPTION_PROCEDURE.md`
- subsystem scope: `docs/project/AI_HARNESS_TOOLSET_SCOPE.md`
- review record 계약: `docs/contracts/review/REVIEW_RESULT_CONTRACT.md`

위 문서와 본 문서가 상충하면 위 문서들의 보수적 해석을 우선한다.

> **BRIEF wording supersede note (3rd reconciliation, 문서 전체 적용).** 본 audit 본문의 BRIEF / BriefRoot 관련 wording — §2 의 `BriefRoot — <ProjectRoot>/brief. durable BRIEF artifact tree`, §4 의 `brief-check.ps1` 행이 `<ProjectRoot>/brief/BRIEF.md` 를 default 검사 대상으로 적은 것, §4 의 `templates/brief/BRIEF.md` 가 `<ProjectRoot>/brief/BRIEF.md` 를 canonical 위치로 적었다는 audit observation, §5 의 `5.2 brief/` 절에서 source repo 의 root `brief/` collision 을 다룬 부분 — 은 audit 시점의 BRIEF model 을 반영한 historical record 다. 그 모델은 이후 reconciliation 라운드를 거쳐 정정되었다. **현행 (3차 reconciliation) 기준**: canonical Brief 는 `<ProjectRoot>/log/brief/BRIEF.md` (project-local, operator-local, source-control-excluded runtime artifact under `<ProjectRoot>/log/`, gitignored), root `<ProjectRoot>/brief/` 는 **rejected**, user-home operator-local runtime root 도 rejected, target persistent footprint = `<ProjectRoot>/log/` only. `BriefRoot` 는 `<ProjectRoot>/log/brief` 다. `scripts/brief-init.ps1` / `scripts/brief-check.ps1` 의 destination 이 정확히 그 자리와 일치한다. canonical source-of-truth 는 `docs/contracts/brief/BRIEF_CONTRACT.md` 와 `docs/contracts/chatlog/CHATLOG_CONTRACT.md` 다. 본 audit 의 process / gap / blocker 결론 자체는 path handling audit 의 read-only 관찰이므로 BRIEF 자리 결정과 독립적으로 유효하다 — wording 의 BRIEF 자리만 본 note 의 3차 framing 으로 읽는다.
>
> **Chatlog template / chatlog AC supersede note.** §4 의 `templates/session-resume.md` / `templates/session-summary.md` / `templates/decision-log.md` 에 대한 path observation 은 audit 시점의 source-tree 사실을 기록한다. 그 세 template 은 이후 Brief/Chatlog/BF drift 정리 라운드에서 source tree 에서 drop 되었다 (Chatlog fuller implementation 미구현 / current contract 와 모순). 본 audit 의 결론에는 영향을 주지 않으며, drop 의 배경은 `docs/archive/backlog/operations.md` 의 "Project-local copy model docs vs global stable runtime ToolRoot model" 항목 Resolved 절 참조.
>
> **Review-cycle observations supersede note (3rd reconciliation).** §4 (4.1 / 4.2 / 4.3 / 4.5 / 5.2 / 5.3), §6 의 Gap G6 / Gap G8 (lines 258–272 인근), §7 의 blocker 본문, §8 의 D1–D9 design seeds 안에 등장하는 `scripts/review-cycle.ps1`, `Resolve-CycleScript`, `meta.json`, `result.json`, `target-files.list`, `<run-id>` flat layout, `log/review-targets/`, `log/review-requests/`, `-TargetFiles` / `-TargetFilesPath` / `-ReviewRequestPath`, `templates/review-meta.json` 등의 observation 은 audit 시점의 source tree 사실이다. 이후 canonical review task/pass topology 채택 (POST_MVP_PLAN §10 Completed `c81fe45`) 으로 normal operator path 가 두 단계 entry (`scripts/review-prepare.ps1` → `scripts/review-run.ps1`) + canonical record `<ProjectRoot>/log/review/<review-task-id>/pass-NN/{input.md, result.md}` 로 갱신되었으며, 위 식별자들은 `docs/archive/backlog/review.md` "Removed legacy review artifacts" historical reason 으로 이동했다. audit 의 read-only gap/blocker 결론 자체 (channel chain, BriefRoot wording, source-vs-runtime 경계 등) 는 본 supersede 와 독립적으로 유효하다 — wording 안의 review-cycle 식별자 / sidecar artifact 참조만 현행 contract 기준으로 읽는다. Gap G6 (`review-cycle.ps1` 의 untracked detection `log/` 제외 범위) 의 동작 결정 (D7) 자체는 `docs/contracts/global-invocation/SHARED_GLOBAL_INVOCATION_CONTRACT.md` 의 D7 supersede note 에 따라 그대로 유효하다.

---

## 1. Purpose

`docs/decisions/GLOBAL_ADOPTION_DECISION.md` §8 은 shared / global mode 로 전환하기 전에 path handling audit 가 선행되어야 한다고 결정했다. 본 문서는 그 audit 를 수행한 결과다.

본 audit 의 책임은 다음으로 한정된다.

- 현재 source repo 의 `scripts/**`, `config/**`, `templates/**`, `snippets/**` 가 ToolRoot / ProjectRoot / LogRoot / BriefRoot 를 어떻게 가정 / 해석하는지 read-only 로 조사.
- shared / global mode 전환 시 발생할 수 있는 path collision, mismatch, missing-fallback 위험의 식별.
- self-target / dogfooding (source repo 자체가 ProjectRoot 인 경우) 의 path collision 위험 식별.
- shared / global mode implementation 이전에 사용자가 결정해야 하는 항목의 식별.
- audit 결과를 바탕으로 한 safe next steps 의 권고.

본 audit 의 책임이 **아닌** 항목.

- `scripts/`, `config/`, `templates/`, `snippets/` 의 실제 수정. 본 문서는 어떤 source file 도 수정하지 않는다.
- 글로벌 `CLAUDE.md` / `AGENTS.md` 의 변경.
- 실제 skill install / update / removal.
- shared / global mode 의 implementation.
- clean target smoke test 의 실행.
- legacy ai-harness / GJMNet 의 path handling.

---

## 2. Conceptual path model recap

`docs/decisions/GLOBAL_ADOPTION_DECISION.md` §8 의 path model 을 본 audit 의 참조 frame 으로 사용한다.

- `ToolRoot` — source-managed file (`scripts/`, `templates/`, `config/`, `snippets/`) 의 위치.
- `ProjectRoot` — 적용 대상 project repo 의 root.
- `LogRoot` — `<ProjectRoot>/log`. runtime / state artifact tree.
- `BriefRoot` — `<ProjectRoot>/brief`. durable BRIEF artifact tree.
- `ConfigRoot` — `<ToolRoot>/config`.
- `TemplateRoot` — `<ToolRoot>/templates`.
- `ScriptRoot` — `<ToolRoot>/scripts`.

세 가지 가능한 layout 이 본 audit 의 frame 이다.

- **Project-local copy mode** — `ToolRoot == <ProjectRoot>/.ai-harness`. MVP 의 현재 default 동작. snippet 본문이 가정하는 형태.
- **Shared / global mode** — `ToolRoot` 가 ProjectRoot 와 독립적인 경로 (예: `H:/Work/ai-harness-toolset/ai-harness-toolset`). `docs/decisions/GLOBAL_ADOPTION_DECISION.md` §4 의 preferred direction.
- **Self-target / dogfooding mode** — `ToolRoot == ProjectRoot` (즉, ai-harness-toolset source repo 자체가 ProjectRoot). source repo 가 자기 자신을 review 할 때.

---

## 3. Audit method

본 audit 는 read-only inspection 만 수행했다.

- `scripts/**` — 모든 `.ps1` 파일을 grep / read 로 inspect.
- `config/reviewer.json` — 전체 read.
- `templates/**` — 모든 `.md`, `.json` 파일 grep / read.
- `snippets/CLAUDE_SNIPPET.md`, `snippets/AGENTS_SNIPPET.md`, `snippets/claude-skills/ai-harness-review/SKILL.md` — 전체 read.
- `.gitignore`, `.gitattributes` — read.
- source repo root layout 의 read-only 조사 (디렉터리 list, 파일 list).

본 audit 는 다음을 수행하지 않았다.

- 어떤 source file 의 수정.
- 새 script / config / template 의 작성.
- 외부 target repo 에서의 실제 실행.
- shared / global mode 의 dry-run.
- runtime artifact 의 생성 / 삭제.

---

## 4. Findings

### 4.1 `scripts/lib/path.ps1` 의 path 모델

현재 source repo 의 `scripts/lib/path.ps1` 는 다음 함수들을 export 한다.

- `Get-ProjectRoot -ProjectRoot <path?>` — 인자가 비면 `Get-Location` (CWD) 를 사용. 디렉터리 존재 확인 후 `[System.IO.Path]::GetFullPath` 로 normalize.
- `Test-IsSourceRepoRoot -Path <path>` — `<Path>/scripts/verify-ps1.ps1` 의 존재 여부로 source repo 식별.
- `Get-ToolRoot -ToolRoot <path?> -ProjectRoot <path?>` — 세 가지 branch:
  1. `-ToolRoot` 가 명시되면 그대로 사용.
  2. ProjectRoot 가 source repo (위 marker file 존재) 면 ToolRoot = ProjectRoot (dogfooding).
  3. 그 외에는 ToolRoot = `<ProjectRoot>/.ai-harness` (project-local copy).
- `Get-ProjectLogRoot -ProjectRoot <path?>` — `<ProjectRoot>/log`.
- `Assert-InProjectRoot` / `Assert-InProjectLogRoot` / `Assert-InReviewRunRoot` — path 가 root 안에 있는지 boundary 검증. case-insensitive ordinal compare, `..` traversal 방지.
- `Test-ValidRunId` / `Assert-ValidRunId` — run-id 패턴 (`^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$`) 강제. `..` 거부.
- `Resolve-ProjectRelativePath` — full path → project-relative path. project 외부 path 는 원본 full path 그대로 반환.

이 모델은 이미 ToolRoot / ProjectRoot 의 conceptual split 을 구현했다. 즉, **shared / global mode 의 기본 entry point 는 이미 존재한다** (호출자가 `-ToolRoot`, `-ProjectRoot` 를 명시하면 동작한다).

### 4.2 lifecycle script 들의 path 사용

`-ProjectRoot` / `-ToolRoot` parameter 를 받는 lifecycle script 들.

| script | `-ProjectRoot` | `-ToolRoot` | 비고 |
|---|---|---|---|
| `scripts/log-init.ps1` | yes | — | `Get-ProjectLogRoot` 만 사용. ToolRoot 불필요. |
| `scripts/brief-init.ps1` | yes | yes | source repo 에서는 `Test-IsSourceRepoRoot` 로 refuse (테스트용 `-AllowSourceRepoSeed` switch 만 예외). |
| `scripts/brief-check.ps1` | yes | — | `<ProjectRoot>/brief/BRIEF.md` (또는 `-BriefPath` 로 override) 검사. ToolRoot 불필요. |
| `scripts/review-cycle.ps1` | yes | yes | `Resolve-CycleScript` 가 ToolRoot 에서 component script 를 찾고, 없으면 `$PSScriptRoot` 로 fallback. |
| `scripts/review-prepare.ps1` | yes | yes | `<ToolRoot>/templates/review-input.md` 를 강제로 요구. 없으면 throw. |
| `scripts/review-run.ps1` | yes | yes | review-cycle 와 동일한 fallback 패턴. |
| `scripts/review-verify.ps1` | yes | — | meta.json 의 `projectRoot` 와 runtime `Get-ProjectRoot` 가 일치하는지 검증. |
| `scripts/review-input-verify.ps1` | — | — | 본 audit 에서는 path 모델 사용 없음. |
| `scripts/verify-ps1.ps1` | — | — | `$PSScriptRoot` 기준. ToolRoot / ProjectRoot 와 무관. |

핵심 관찰.

- `scripts/lib/path.ps1` 의 모델이 모든 lifecycle script 의 single source of truth 다. inconsistent path 해석은 발견되지 않았다.
- ToolRoot misconfiguration 의 fail-fast 경로는 이미 두 곳에 존재한다. (a) `Get-ToolRoot` (`scripts/lib/path.ps1:39`) 는 명시 `-ToolRoot` 가 존재하지 않는 디렉터리이면 즉시 throw 한다. (b) `review-prepare.ps1:243` 은 `<ToolRoot>/templates/review-input.md` 가 없으면 throw 한다.
- 다만 `Resolve-CycleScript` / `Resolve-RunScript` 는 ToolRoot 에서 component script (`scripts/review-prepare.ps1` 등) 를 찾지 못하면 `$PSScriptRoot` (현재 실행 중인 cycle/run script 와 같은 디렉터리) 로 fallback 한다. 이 fallback 은 component script resolution 단계 자체에서는 ToolRoot misconfiguration 을 드러내지 않는다. 즉, 결과적으로 review 가 실패하더라도 실패 메시지가 ToolRoot 가 아닌 후속 단계 (template 부재 등) 를 가리키게 되어 운영자의 diagnosis 가 흐려질 수 있다.
- `review-cycle.ps1` 의 unTracked file detection (lines 163–169) 은 `log/` 만 명시적으로 제외한다. target project 가 `.ai-harness/` 를 직접 가지고 있고 untracked 라면 `review-cycle: FAIL untracked files outside log/` 로 fail 한다.

### 4.3 templates 의 path 가정

- `templates/review-meta.json` — `projectRoot`, `toolRoot`, `projectLogRoot` 의 placeholder 빈 문자열을 가진다. shape level 의 가정은 없다. runtime 에서 채워진다.
- `templates/review-input.md` — placeholder 만 가진다. path 가정 없음.
- `templates/brief/BRIEF.md` — preamble 본문이 `<ProjectRoot>/brief/BRIEF.md` 를 canonical 위치로 명시한다. `scripts/brief-init.ps1` 가 이 template 을 target ProjectRoot 의 `brief/BRIEF.md` 로 seed 한다는 사실을 본문에 기록한다. ToolRoot 위치 자체는 `templates/brief/BRIEF.md` 라는 source-side path 로 한 번 언급된다.
- `templates/session-resume.md` / `templates/session-summary.md` — `log/chatlog/current/` 등을 본문에 언급. 모두 project-local runtime path. ToolRoot 가정 없음.
- `templates/decision-log.md` — `log/chatlog/...`, `log/evidence/...` 등 ProjectRoot 기반 path 만 본문에 언급.

template 에는 `.ai-harness/` 같은 copy-only 전제 path 가 발견되지 않았다.

### 4.4 config

- `config/reviewer.json` — `provider`, `model`, `fallbackModel`, `reasoningEffort`, `timeoutSeconds`, `sandbox`, `outputFormat`, `resultFile` 만 포함. path 가정 없음.

### 4.5 snippets / claude-skill 의 path 가정

본 audit 의 가장 중요한 finding 영역이다. snippet 본문은 `.ai-harness/` copy-only 전제를 유지하고 있다. 다음은 식별된 인스턴스다 (Batch A 까지의 상태).

`snippets/CLAUDE_SNIPPET.md` 본문 (marker block 안):

- L15 — "`.ai-harness/` is the project-local, copy-only payload. No global files are modified."
- L16 — "Runtime output root is `<project-root>/log/`."
- L19 — "Reviewer config comes from `.ai-harness/config/reviewer.json`."
- L23 — "Default user-facing entrypoint is the single-shot CLI `.ai-harness/scripts/review-cycle.ps1`."
- L25 — "`.ai-harness/scripts/review-prepare.ps1` and `.ai-harness/scripts/review-verify.ps1`."
- L40 — "`<project-root>/brief/BRIEF.md` is the durable project restore file."
- L43 — "`.ai-harness/templates/brief/BRIEF.md` is the source-side template."
- L47 — "`<project-root>/brief/BRIEF.md` is expected to be tracked by default."
- L62 — restore-offer order 의 "`<project-root>/brief/BRIEF.md`".

`snippets/AGENTS_SNIPPET.md` 본문 (marker block 안): 동일한 9 개 인스턴스. CLAUDE 와 AGENTS 의 차이는 어휘 (Codex / generic agents) 이며, path 가정은 동일하다.

`snippets/claude-skills/ai-harness-review/SKILL.md`:

- L39 — "If `<project-root>/.ai-harness/scripts/review-cycle.ps1` exists, that is the script root (target payload mode)."
- L40 — "Otherwise, if running inside the `ai-harness-toolset` source repo itself, use `<repo-root>/scripts/review-cycle.ps1` (source repo mode)."
- L41 — "If neither exists, stop and tell the user the toolset payload has not been copied to this project."

위 path 가정은 두 가지 의미를 가진다.

- 사실 (a). project-local copy mode (현재 MVP default) 와 self-target / dogfooding mode 의 두 가지 layout 만을 명시적으로 다룬다.
- 사실 (b). shared / global mode (ToolRoot 가 ProjectRoot 와 독립적인 경로) 는 본문에 명시적 분기가 없다.

즉, 사용자가 shared / global mode 로 invoke 하려 해도, snippet 본문에는 "어디서 script 를 찾아야 하는지" 가 기록되어 있지 않다. 결과적으로 사용자 또는 AI 가 직접 ToolRoot 를 알아야 하거나, snippet 본문 외부의 정보 (예: `docs/decisions/GLOBAL_ADOPTION_DECISION.md`) 를 참조해야 한다.

이는 Batch A 의 `yes with risk` finding 과 정합한다.

---

## 5. Self-target / dogfooding collision audit

source repo 가 ProjectRoot 인 경우 (즉, ai-harness-toolset 자기 자신을 review / brief 대상으로 사용하는 경우) 의 collision 위험을 항목별로 본다.

### 5.1 `log/`

- 현재 동작. `Get-ProjectLogRoot` 가 `<ProjectRoot>/log` 를 반환. dogfooding 에서는 source repo 의 `log/` 가 LogRoot 가 된다.
- collision 위험. source repo 의 `log/` 는 `.gitignore` 에 등재되어 있어 git tracked 가 되지 않는다 (확인됨: `.gitignore` 첫 줄 `log/`). 따라서 review run artifact (`log/review/<run-id>/...`), chatlog artifact, evidence artifact 가 source-managed file 과 섞이지 않는다.
- 잔여 risk. 사용자가 실수로 `log/` 안에 source-managed file 을 두면 gitignore 가 그 파일도 무시한다. source-managed file 을 `log/` 아래에 두지 않는 운영 규약이 유지되어야 한다.

### 5.2 `brief/`

- 현재 동작. `scripts/brief-init.ps1` 는 `Test-IsSourceRepoRoot` 가 true 일 때 `-AllowSourceRepoSeed` 가 없으면 refuse 하고 exit 1.
- collision 위험. source repo 에는 `brief/` 디렉터리 자체가 존재하지 않는다. `templates/brief/BRIEF.md` 는 source-side template 으로만 존재한다.
- 잔여 risk. 외부 운영자가 source repo 에 `brief/BRIEF.md` 를 수동으로 commit 하면 `BRIEF_CONTRACT.md` 의 source-vs-target 경계가 깨진다. tooling 은 brief-init 의 refuse 로만 막는다. 사용자가 직접 commit 하는 행위를 막는 자동화는 없다.

### 5.3 `.ai-harness/`

- 현재 동작. source repo 에는 `.ai-harness/` 디렉터리가 존재하지 않는다 (`Get-ToolRoot` 가 source repo branch 로 빠지므로 fallback 으로 `<repo>/.ai-harness` 를 만들지도 않는다).
- collision 위험. source repo 가 `.ai-harness/` 를 가지는 경우는 (a) 사용자가 수동 생성, (b) 다른 target 의 사본을 잘못 복사한 경우뿐이다. 이는 자동으로 발생하지 않는다.

### 5.4 `tests/`

- source repo 의 `tests/` 는 source-managed (commit 대상). Pester test 가 들어 있다.
- collision 위험. dogfooding 에서 lifecycle script 가 `tests/` 를 stage 대상으로 잡지 않는다 (script 가 `tests/` 에 쓰지 않는다). 본 audit 에서 `tests/` 에 대한 runtime write 는 발견되지 않았다.
- 잔여 risk. test fixture 가 `$TestDrive` 를 사용한다는 점이 `scripts/brief-init.ps1` 의 `-AllowSourceRepoSeed` switch 의 사용 맥락이다. test 가 source-tracked 파일을 직접 mutate 하지 않는지 별도 확인이 필요할 수 있다.

### 5.5 review run / evidence / chatlog 트리

- 모두 `log/` 아래로 들어가며 `.gitignore` 의 영향을 받는다. dogfooding 에서도 source-managed file 과 collision 하지 않는다.

### 5.6 `Test-IsSourceRepoRoot` 의 detection marker

- 현재 marker 는 `<ProjectRoot>/scripts/verify-ps1.ps1` 의 존재 여부.
- false positive 가능성. target project 가 우연히 `scripts/verify-ps1.ps1` 라는 파일을 가지고 있으면 source repo 로 오인된다. 결과: ToolRoot 가 target ProjectRoot 로 설정되어, source-managed file (`scripts/`, `templates/`, `config/`) 을 ToolRoot 의 `<ProjectRoot>` 에서 찾는다. target 에 그 파일이 없으면 review-prepare 가 throw.
- false negative 가능성. source repo 에서 `scripts/verify-ps1.ps1` 가 제거되거나 rename 되면 dogfooding detection 이 실패. `Get-ToolRoot` 가 `<ProjectRoot>/.ai-harness` fallback 으로 빠져 NotFound 가 된다.

### 5.7 self-target 결론

- self-target / dogfooding 의 path collision 은 현재 시점에서 실제 손상으로 이어지지 않는다 (위 5.1–5.6 모두 mitigations 가 존재).
- 단, **mitigations 의 일부는 명시적 운영 규약** 에 의존한다 (e.g. "log/ 아래에 source-managed file 을 두지 말 것", "source repo 에 brief/ 를 직접 commit 하지 말 것"). 이 규약은 tooling 의 자동 enforcement 가 아니다.

---

## 6. Identified gaps for shared / global mode

본 절은 shared / global mode 로 전환하기 전에 후속 작업에서 다루어야 하는 항목을 식별한다. 본 audit 는 항목을 식별할 뿐, fix 를 제시하지 않는다.

### Gap G1 — snippet 본문의 `.ai-harness/` 경로 전제

`snippets/CLAUDE_SNIPPET.md` 와 `snippets/AGENTS_SNIPPET.md` 본문 (marker block 내부) 이 `.ai-harness/scripts/...`, `.ai-harness/config/...`, `.ai-harness/templates/...` 를 명시적으로 가정한다. shared / global mode 에서는 ToolRoot 가 target 외부 (예: global 위치) 에 있을 수 있으므로 본문이 그 case 를 다루지 못한다.

영향: shared / global mode 를 사용하는 운영자는 snippet 본문 외부 정보 (예: 본 audit / `GLOBAL_ADOPTION_DECISION.md`) 를 별도로 참조해야 한다. snippet 자체로는 layout 분기를 알 수 없다.

### Gap G2 — claude-skill SKILL.md 의 script root 해석

`snippets/claude-skills/ai-harness-review/SKILL.md` 의 step 1 (Inspect repo state) 가 두 mode 만 가정한다: project-local copy mode 와 source-repo (dogfooding) mode. shared / global mode 에서 ToolRoot 가 ProjectRoot 외부에 있는 case 를 다루지 않는다.

영향: skill 이 자동으로 global ToolRoot 를 찾을 수 없다. AI 가 사용자에게 ToolRoot 를 묻거나, 본 audit 의 후속 결정에 따라 추가 분기가 필요하다.

### Gap G3 — component script resolution 의 `$PSScriptRoot` fallback

`Resolve-CycleScript` / `Resolve-RunScript` 가 `<ToolRoot>/<RelativePath>` 에서 component script (예: `scripts/review-prepare.ps1`) 를 찾지 못하면 `$PSScriptRoot` 로 fallback 한다. ToolRoot misconfiguration 자체는 별도 layer 에서 잡힌다 — 명시 `-ToolRoot` 가 존재하지 않는 디렉터리이면 `Get-ToolRoot` 에서 throw 되고, ToolRoot 가 존재하더라도 `<ToolRoot>/templates/review-input.md` 가 없으면 `review-prepare.ps1` 에서 throw 된다. 따라서 ToolRoot 가 잘못 지정되었을 때 review 가 silent 하게 정상 종료까지 도달하는 시나리오는 본 audit 의 범위 안에서 식별되지 않았다.

다만 component script resolution 단계만 보면 `$PSScriptRoot` fallback 이 ToolRoot 의 불일치를 그 시점에 드러내지 않는다. 후속 단계 (template 부재 등) 에서 실패가 발생하면 운영자가 보는 메시지는 ToolRoot misconfiguration 자체가 아닌 그 후속 증상이다. shared / global mode 에서 이런 mis-diagnosis 가 누적되면 운영 비용이 증가할 수 있다.

영향: ToolRoot misconfiguration 의 진단 메시지 품질. 결정 필요: component script resolution 단계의 fallback 을 유지할지, ToolRoot 명시 시에는 fallback 을 끄고 fail-fast 로 바꿀지, 또는 fallback 발동 시 명시적 warning 을 추가할지.

### Gap G4 — `Get-ToolRoot` 의 detection marker

`Test-IsSourceRepoRoot` 가 `scripts/verify-ps1.ps1` 의 단일 marker 에 의존한다. marker 가 변경되거나 target 에 우연히 같은 파일이 존재할 가능성이 있다.

영향: false positive (target → source 로 오인) 와 false negative (source → target 으로 오인) 가 모두 가능. 결정 필요: marker 를 무엇으로 보강할지, 또는 명시적 `-ToolRoot` parameter 를 강제할지.

### Gap G5 — `-ProjectRoot` 의 CWD default

`Get-ProjectRoot` 는 인자가 비면 CWD 를 사용한다. CWD 가 실제 ProjectRoot 가 아닌 경우 (예: ProjectRoot 의 sub-directory 에서 invoke) 에 대한 명시적 검증이 없다.

영향: 사용자가 잘못된 위치에서 invoke 하면 LogRoot 가 엉뚱한 위치로 생성될 수 있다. 결정 필요: CWD default 를 유지할지, 명시 요구할지, `.git` / 다른 marker 로 ProjectRoot 를 자동 탐지할지.

### Gap G6 — `review-cycle.ps1` 의 untracked detection 이 `log/` 만 제외

target 에 untracked `.ai-harness/`, `brief/` 가 있으면 `review-cycle` 이 FAIL 한다. shared / global mode 에서는 target 에 `.ai-harness/` 가 없어야 하므로 발생 빈도가 낮지만, 전환기에는 발생할 수 있다.

영향: 전환기 운영의 마찰. 결정 필요: untracked exclusion 정책을 어떻게 일반화할지.

### Gap G7 — ToolRoot env var / discovery 의 부재

`-ToolRoot` 를 매 invocation 마다 사용자가 전달해야 한다. env var (`AI_HARNESS_TOOL_ROOT` 등) 나 user-level config 의 자동 discovery 는 없다.

영향: shared / global mode 의 사용자 경험. 사용자가 launcher 를 직접 만들거나, 매번 path 를 입력해야 한다. 결정 필요: discovery 채널을 도입할지, 도입한다면 우선순위는 무엇인지.

### Gap G8 — meta.json 의 `toolRoot` field 의 binding 검증 부재

`review-prepare.ps1` 가 meta.json 에 `toolRoot` 를 기록하지만, `review-verify.ps1` 는 `toolRoot` 의 runtime 일치 여부를 검증하지 않는다 (현재 verify 는 `projectRoot` 와 `projectLogRoot` 만 비교).

영향: ToolRoot 가 변경된 환경에서 verify 가 그 사실을 감지하지 못한다. 결정 필요: ToolRoot binding 을 verify scope 에 추가할지, 또는 명시적으로 informational 로 둘지.

### Gap G9 — snippet body 의 global mode 표기 부재

§4.5 의 finding 과 별도로, snippet body 가 shared / global mode 에 대한 사용자 설명을 포함하지 않는다. Batch A 에서 marker 만 적용했고 본문은 손대지 않았다 (Batch A 의 `yes with risk` 항목).

영향: 사용자가 snippet 만 읽어서는 shared / global mode 의 운영 방식을 알 수 없다. 결정 필요: 본문을 mode-neutral 로 재작성할지, 또는 별도의 보조 문서로 분리할지.

### Gap G10 — self-target mitigations 의 자동 enforcement 부재

§5 의 dogfooding mitigations 중 일부는 운영 규약에만 의존한다. 예: `log/` 아래에 source-managed file 을 두지 말 것. tooling 이 이를 자동으로 막지는 않는다.

영향: source repo 의 운영자가 실수로 source-managed file 을 `log/` 아래에 두면 `.gitignore` 때문에 silent 하게 누락될 수 있다. 결정 필요: enforcement 를 자동화할지 (예: pre-commit, verify-ps1 의 추가 check), 또는 운영 규약으로 유지할지.

---

## 7. Blockers for shared / global mode implementation

본 절의 항목은 shared / global mode implementation 의 scoped 승인 전에 사용자 결정이 필요한 hard blocker 다.

### Blocker B1 — ToolRoot discovery 채널 (Gap G7 와 연결)

shared / global mode 의 사용자가 ToolRoot 를 어떻게 지정할지 결정되지 않았다.

후보 (열거일 뿐, 추천이 아니다).

- a. 매 invocation 의 `-ToolRoot` 명시.
- b. env var (예: `AI_HARNESS_TOOL_ROOT`).
- c. user-level config 파일 (예: `~/.ai-harness-toolset/config.json`).
- d. snippet body 에 ToolRoot 절대경로 기록.
- e. 위 채널의 우선순위 조합.

본 결정 없이 shared / global mode 의 invocation contract 가 확정되지 않는다.

### Blocker B2 — `Resolve-CycleScript` / `Resolve-RunScript` fallback 정책 (Gap G3 와 연결)

ToolRoot 가 잘못 지정될 때 silent fallback 을 허용할지, fail-fast 로 바꿀지가 결정되지 않았다.

후보.

- a. 현재 정책 유지 (`$PSScriptRoot` fallback).
- b. ToolRoot 가 명시적이면 fallback 금지 (명시 ToolRoot 에 없으면 throw).
- c. fallback 시 명시적 warning 출력 후 진행.

### Blocker B3 — source repo detection 강화 (Gap G4 와 연결)

`Test-IsSourceRepoRoot` 의 marker 를 보강할지, 명시 `-ToolRoot` 를 강제할지가 결정되지 않았다.

후보.

- a. 현재 marker 유지.
- b. 다중 marker (`scripts/verify-ps1.ps1` + `templates/review-input.md` + `config/reviewer.json`) 의 동시 존재 요구.
- c. dogfooding mode 는 명시 flag (`-AllowDogfood`) 로만 활성화.

### Blocker B4 — snippet body rewrite 의 scope (Gap G1, G9 와 연결)

`snippets/CLAUDE_SNIPPET.md` / `snippets/AGENTS_SNIPPET.md` 본문을 어떻게 재작성할지 결정되지 않았다.

후보.

- a. 본문을 mode-neutral 로 재작성 (project-local / shared-global / self-target 세 mode 를 모두 다룸).
- b. 본문을 shared-global 우선으로 재작성 (project-local 은 fallback 으로 명시).
- c. 본문은 그대로 두고, 별도 보조 snippet (예: `snippets/SHARED_GLOBAL_NOTES.md`) 으로 분기 정보를 분리.
- d. snippet body 변경은 shared/global mode implementation 이후로 미룸.

### Blocker B5 — claude-skill SKILL.md 의 script root 분기 (Gap G2 와 연결)

`snippets/claude-skills/ai-harness-review/SKILL.md` 의 step 1 에서 shared / global mode 분기를 어떻게 추가할지가 결정되지 않았다.

후보.

- a. 새 mode 를 step 1 에 추가 (검사 순서: project-local copy → shared/global env var → dogfooding).
- b. shared/global ToolRoot 는 AI 가 사용자에게 묻도록 prompt.
- c. shared/global mode 자체는 자동 감지 대신 사용자 명시 trigger 로만 활성화.

위 B1–B5 가 결정되어야 implementation scoped 승인이 가능하다.

---

## 8. Required decisions (questions awaiting user)

본 절은 §6, §7 의 결정 항목을 사용자에게 묻는 형태로 정리한다. 답을 본 audit 가 정하지 않는다.

D1. ToolRoot discovery 채널 (B1) — 어떤 채널을, 어떤 우선순위로 도입할지.
D2. Script resolution fallback (B2) — `$PSScriptRoot` fallback 의 거취.
D3. Source repo detection (B3) — marker 의 강도와 dogfooding 활성화 방식.
D4. Snippet body rewrite scope (B4) — mode-neutral 재작성 여부와 시점.
D5. Skill SKILL.md script root branching (B5) — shared/global mode 분기 추가 방식.
D6. ToolRoot binding in `review-verify` (G8) — verify scope 에 `toolRoot` 추가 여부.
D7. Untracked exclusion policy (G6) — 전환기에 `.ai-harness/`, `brief/` 의 untracked 처리.
D8. Self-target enforcement (G10) — `log/` 아래 source-managed file 금지의 자동화 여부.
D9. ProjectRoot CWD default (G5) — CWD default 유지 / 명시 요구 / marker 기반 자동 탐지.

D1–D9 가 결정되기 전에는 shared / global mode 의 invocation contract 가 확정되지 않는다.

---

## 9. Safe next steps

본 절은 audit 종료 직후의 안전한 후속 단계 권고다. **순서 자체가 자동 승인은 아니다.** 각 단계는 별도 scoped 승인이 필요하다.

1. 본 audit 문서에 대한 Codex review (본 Batch B 에서 수행).
2. §8 의 결정 항목 D1–D9 의 사용자 결정. 각 결정은 별도 scoped 라운드로 처리해도 좋고, 묶음으로 처리해도 좋다.
3. 결정된 D1–D9 를 토대로 shared / global mode invocation contract 의 design 문서 작성. 본 단계는 implementation 이 아니다.
4. design 문서의 scoped 승인.
5. shared / global mode implementation 의 분할 (예: 먼저 `path.ps1` 와 `Resolve-CycleScript` 의 fallback 정책, 그 다음 snippet body, 그 다음 SKILL.md).
6. 각 implementation 단계마다 별도 scoped 승인 + scoped commit + Codex review.
7. shared / global mode implementation 이 완료된 뒤 clean target smoke test criteria 의 design.
8. clean target smoke test criteria 의 scoped 승인.
9. clean target smoke test 실행.
10. post-MVP closeout 재평가.
11. new GJMNet repo 의 clean adoption.

위 단계 중 어떤 것도 본 audit 가 자동 승인하지 않는다.

---

## 10. Non-goals

본 audit 는 다음을 **포함하지 않는다**. 본 audit 가 존재한다는 사실로 아래 항목이 승인 / 실행되었다고 해석하지 않는다.

- `scripts/`, `config/`, `templates/`, `snippets/` 의 실제 수정.
- shared / global mode 의 implementation.
- snippet body 의 재작성.
- claude-skill SKILL.md 의 변경.
- 글로벌 `CLAUDE.md` / `AGENTS.md` 의 변경.
- 실제 skill install / update / removal.
- `.gitignore` / `.gitattributes` 의 변경.
- ToolRoot env var 의 도입.
- launcher script 의 작성.
- legacy ai-harness 의 path handling 재활용.
- clean target smoke test 의 실행.
- GJMNet 접근.

위 항목 중 어느 것이라도 진행하려면 별도 scoped 승인이 필요하다.

---

## 11. Source-of-truth 관계

- 본 audit 는 path handling 의 read-only 조사 결과 기록이다.
- `docs/decisions/GLOBAL_ADOPTION_DECISION.md` §8 의 audit 요구 사항을 충족한다.
- §2 의 path model 정의는 `docs/decisions/GLOBAL_ADOPTION_DECISION.md` §8 의 정의와 정합한다. 충돌 시 `GLOBAL_ADOPTION_DECISION.md` 가 우선한다.
- §5 self-target / dogfooding audit 는 `docs/decisions/POST_MVP_PLAN.md` §11 step 4 의 mandatory sub-scope 를 충족한다.
- 본 audit 는 review verdict (`yes` / `no` / `yes with risk`) 를 commit / push / publish / merge / release / adoption 의 자동 승인으로 해석하지 않는다는 contract 를 그대로 유지한다.
