# Clean Target Smoke Test Criteria — Shared / Global Mode

> **현행 status routing.** 본 문서는 clean-target smoke criteria (SC1–SC7) 의 **record** 이며 Step 4 fixture 검증 형식의 still-referenced baseline 이다 (SC5/CH3 review-cycle body 등 일부 superseded). install/update 의 current 상태는 `docs/systems/install-update/STATUS.md` (IU-07/IU-12) + `docs/systems/install-update/DEFERRED.md` 가 authoritative 다 (전체 routing: `docs/current/SOURCE_OF_TRUTH.md`; roadmap index: `docs/roadmap/INDEX.md`). 본 문서 본문과 system STATUS 가 충돌하면 current 판단은 STATUS 를 따른다.

본 문서는 `ai-harness-toolset` 의 shared / global mode 동작을 fresh / clean target 환경에서 검증하기 위한 smoke test criteria 의 정의다. **criteria 의 기록이며, smoke 실행 / target 채택 / script 변경 / global mutation / commit 어느 것도 자동 승인하지 않는다.**

본 문서가 존재한다는 사실만으로 다음 행위가 승인되지 않는다.

- 실제 smoke test 의 실행.
- target project 의 자동 생성 또는 변경.
- `scripts/`, `config/`, `templates/`, `snippets/`, `tests/` 의 변경.
- global / user 환경 (`~/.claude/`, root `CLAUDE.md`, root `AGENTS.md`, user shell config) 의 mutation.
- backlog 항목의 implementation.
- commit / push / publish / merge / release.

각 단계는 별도 scoped 승인이 필요하다.

본 문서는 다음 source-of-truth 들과 충돌하지 않는다.

- shared / global mode invocation contract: `docs/contracts/global-invocation/SHARED_GLOBAL_INVOCATION_CONTRACT.md`
- ToolRoot / ProjectRoot audit: `docs/archive/audits/TOOLROOT_PROJECTROOT_AUDIT.md`
- 운영 계층 결정: `docs/decisions/GLOBAL_ADOPTION_DECISION.md`
- Claude skill global 절차: `docs/user_guide/GLOBAL_ADOPTION_PROCEDURE.md`
- subsystem scope: `docs/project/AI_HARNESS_TOOLSET_SCOPE.md`
- review record 계약: `docs/contracts/review/REVIEW_RESULT_CONTRACT.md`
- BRIEF 계약: `docs/contracts/brief/BRIEF_CONTRACT.md`
- evidence 계약: `docs/contracts/evidence/EVIDENCE_CONTRACT.md`

위 문서와 본 문서가 상충하면 위 문서들의 보수적 해석을 우선한다.

> **Review-cycle smoke criteria — superseded note (3rd reconciliation).** 본 criteria 의 SC5 / SC5' / CH3-B / CH3-B' / CH3-C 의 Action / Pass / Evidence body 는 `scripts/review-cycle.ps1` 와 그 sidecar artifact (`meta.json`, `result.json`, `target-files.list`, `log/review-targets/`, flat `log/review/<run-id>/`) 을 기준으로 작성된 historical record 다. canonical review task/pass topology 채택 (POST_MVP_PLAN.md §10 Completed `c81fe45`) 이후 normal operator path 는 두 단계 entry (`scripts/review-prepare.ps1 -ReviewTaskId <id> [-Pass <pass-NN>]` → `scripts/review-run.ps1 -ReviewTaskId <id> -Pass <pass-NN>`) 와 canonical record `<ProjectRoot>/log/review/<review-task-id>/pass-NN/{input.md, result.md}` 두 파일로 변경되었으며, `review-cycle.ps1` / `meta.json` / `result.json` / `target-files.list` / `<run-id>` flat layout 은 `docs/archive/backlog/review.md` 의 "Removed legacy review artifacts" 분류로 이동했다. 본 criteria 의 SC5 / SC5' / CH3-B / CH3-B' / CH3-C 의 historical PASS 기록 (POST_MVP_PLAN.md §10 Completed 참조) 은 그 prior script generation 기준 evidence 로서 그대로 유효하다. 본 case 들을 current script 기준으로 다시 실행하려면 canonical task/pass topology 위에서 동등한 binding 검증 (예: `input.md` informational target file section, `result.md` `## Verdict` shape, `review-verify -RequireResult` PASS) 을 다루는 새 criteria 가 필요하며, 그 신규 criteria 의 작성 / 실행 / commit 어느 것도 본 문서가 자동 승인하지 않는다 — 별도 scoped 승인이 필요하다. SC1 / SC2 / SC3 / SC4 / SC6 / SC7 / CH3-A 는 본 supersede 와 무관하다 (그 case 들은 `scripts/log-init.ps1`, `scripts/brief-init.ps1`, `Get-ToolRoot` channel chain 등 review-cycle 외 경로를 다룬다).

> **BRIEF wording — three-step reconciliation (note for partial readers).** 본 문서의 BRIEF 관련 assertion
> (precondition A5 / A6, SC2 / SC3 / SC4, §1.1 fixture 절차, §3 BriefRoot, §4 evidence) 은 세 단계의 reconciliation
> 을 거친 BRIEF 모델 framing 안에서 읽는다.
> **(1) 1차 reconciliation (historical):** canonical 을 `<ProjectRoot>/log/brief/BRIEF.md` 로 두고 root
> `<ProjectRoot>/brief/` 를 forbidden 으로 둔 framing.
> **(2) 2차 reconciliation (historical, superseded):** target repo product canonical Brief 를
> `<ProjectRoot>/brief/BRIEF.md` 로 두고 `<ProjectRoot>/log/brief/BRIEF.md` 를 not-canonical 한 seed destination 으로
> 분류한 framing.
> **(3) 3차 reconciliation (현행 기준):** 2차 framing 이 정정되어 **canonical Brief 는 다시 `<ProjectRoot>/log/brief/BRIEF.md`**
> — project-local, operator-local, source-control-excluded runtime artifact under `<ProjectRoot>/log/` (gitignored).
> **root `<ProjectRoot>/brief/` 는 rejected**, user-home operator-local runtime root (예:
> `%USERPROFILE%\.ai-harness\projects\<project-key>\...`) 도 rejected, target persistent footprint =
> `<ProjectRoot>/log/` only. BF Level 은 path 가 아니라 save / restore capability maturity 다; BF Level 3
> (deterministic Brief maintenance / validation / stale warning / session-start guidance / restore-offer) 는
> 미구현 future scoped work 다.
> **본 criteria 의 SC2 / SC3 / SC4 / §1.1 / §3 / §4 assertion 자체는 세 reconciliation 어느 단계에서도 modify 하지 않는다.**
> 그 assertion 들은 현재 `scripts/brief-init.ps1` 가 `<ProjectRoot>/log/brief/BRIEF.md` 에 seed 한다는 사실을
> 검증하는 primitive-behavior smoke 다 — 그 동작은 세 reconciliation 모두에서 그대로다. 본문에 등장하는
> "canonical BRIEF artifact" wording 은 3차 reconciliation 기준 그대로 canonical 자리를 의미한다 (1차 의미와 일치;
> 2차 단계의 "primitive destination 이며 not-canonical" 해석은 superseded). canonical source-of-truth 는
> `docs/contracts/brief/BRIEF_CONTRACT.md` 와 `docs/contracts/chatlog/CHATLOG_CONTRACT.md` 다.

---

## Target

본 criteria 의 target 은 다음 한 가지 질문에 대한 observable answer 를 정의하는 것이다.

> shared / global mode 에서 `ai-harness-toolset` 의 lifecycle script 가 ToolRoot 와 ProjectRoot 를 독립 경로로 두고도 결정론적으로 동작하는가? — runtime artifact 가 ProjectRoot 안에만 생성되고, ToolRoot working tree 는 어느 case 에서도 mutate 되지 않는가? — channel resolution 의 positive / negative case 가 모두 contract 와 일치하는가?

본 문서는 위 질문을 case 단위로 분해하고, 각 case 의 pre-condition / action / observable pass / observable fail / required evidence 를 정의한다. 실제 실행은 별도 execution goal 에서 별도 scoped 승인을 거쳐 진행한다.

authoritative contract: `docs/contracts/global-invocation/SHARED_GLOBAL_INVOCATION_CONTRACT.md` §5.1–§5.4 (D1, D2, D6 결정).

본 criteria 의 binding target 은 위 contract 문서들의 **현재 checked-out source snapshot** 이다. 본 문서 본문은 특정 commit hash 에 pin 하지 않는다. 본 문서 자체의 authoring 시점 source snapshot HEAD 는 git history 가 권한이며, 별도로 본문에 인용하지 않는다. 개별 smoke 실행이 어느 source repo HEAD 에서 수행되었는지 (execution HEAD) 와 그 HEAD 가 evidence 에 어떻게 기록되는지 (evidence-recorded HEAD) 는 §4 항목 4 와 §7 에 정의되어 있다.

---

## 1. Minimum clean target project assumptions

clean target 은 본 source repo 와 **다른 절대경로** 의 신규 디렉터리다. 본 repo 의 working tree 를 mutate 해서는 안 된다.

### Terminology — `<SourceRepoRoot>` vs `<ToolRoot>`

본 criteria 는 두 path 개념을 명시적으로 구분한다.

- **`<SourceRepoRoot>`** — `ai-harness-toolset` source repo 의 working tree (현재 checked-out source snapshot). 본 path 는 모든 SC 에서 정의되며 read-only invariant 의 대상 (SC7) 이다. channel resolution 결과와 무관하게 본 path 의 상태는 변화하지 않아야 한다. 실행 시점에 관찰된 HEAD (execution HEAD) 자체는 per-run evidence 에 기록한다 (§4 항목 4). 본 terminology 는 특정 commit hash 에 binding 하지 않는다.
- **`<ToolRoot>`** — 각 SC 의 호출 시점에 `Get-ToolRoot` 가 channel chain 으로 resolve 한 결과. 케이스에 따라 `<SourceRepoRoot>` 와 같을 수도 있고 (SC2 / SC3 / SC5 의 정상 호출), 다른 디렉터리일 수도 있고 (SC6 의 빈 임시 directory), 정의되지 않을 수도 있다 (SC4 의 throw).
- SC7 의 invariant 는 `<ToolRoot>` 가 아니라 **`<SourceRepoRoot>`** 를 대상으로 한다. channel resolution 결과와 별개로 source repo working tree 의 git 상태가 mutate 되지 않음을 보장한다.

이 구분이 적용된 이후 항목들에서, "source repo 가 mutate 되지 않음" 의 의미는 모두 `<SourceRepoRoot>` 기준이며, "ToolRoot 가 ... 로 resolve" 의 의미는 모두 `<ToolRoot>` (channel-resolved) 기준이다.

- **A1.** `<ProjectRoot>` 가 존재하며 `<ProjectRoot>/.git/` (directory 또는 file pointer) 가 존재한다.
- **A2.** `<ProjectRoot>/.ai-harness/` 가 **존재하지 않는다** (channel 5 — legacy `.ai-harness` — 비활성).
- **A3.** `<ProjectRoot>` 가 dogfooding multi-marker (`scripts/verify-ps1.ps1`, `templates/review-input.md`, `config/reviewer.json`) 를 **모두 보유하지 않는다** (channel 4 — dogfooding — 비활성).
- **A3b — global stable install 비활성 (SC4 에 필수, A7a 케이스에는 무관).** smoke host 에 channel 3 (`%USERPROFILE%\.claude\ai-harness-toolset\current`) 의 global stable install 이 **존재하지 않는다** (또는 존재하더라도 payload 가 불완전하지 않은 상태가 보장되지 않으므로, SC4 의 channel-exhaustion 검증에는 부재가 요구된다). SC2 / SC3 / SC5 / SC6 (A7a positive-channel 케이스) 는 channel 1 (`-ToolRoot`) 또는 channel 2 (`AI_HARNESS_TOOL_ROOT`) 를 사용하며 이 둘은 channel 3 보다 우선하므로, A7a 케이스의 결정성은 global stable install 의 존재 여부와 무관하다. 본 assumption 의 "A1–A6" 범위 표기는 A3b 를 포함하는 것으로 읽는다.
- **A4.** `<ProjectRoot>/log/` 가 존재하지 않거나, 존재해도 tracked file 0 개.
- **A5.** `<ProjectRoot>/log/brief/BRIEF.md` 가 존재하지 않는다.
- **A6.** `<ProjectRoot>/.gitignore` 가 `log/` 를 무시한다. canonical BRIEF artifact (`<ProjectRoot>/log/brief/BRIEF.md`) 는 이 `log/` 규칙에 의해 default 로 ignored (untracked) 된다 (`docs/contracts/brief/BRIEF_CONTRACT.md` 의 tracked vs gitignored 기본값과 정합). root `<ProjectRoot>/brief/` 는 ai-harness 용도로 생성하지 않는다.
- **A7a — positive-channel 가정 (SC2, SC3, SC5, SC6 에 적용).** ToolRoot 가 적어도 하나의 channel 로 resolve 가능해야 한다. case 별 명시:
  - channel 1 사용 케이스: 모든 호출에 `-ToolRoot <source-repo-absolute-path>` 를 명시. `AI_HARNESS_TOOL_ROOT` 는 unset 권장 (혼선 방지).
  - channel 2 사용 케이스: `AI_HARNESS_TOOL_ROOT = <source-repo-absolute-path>`. `-ToolRoot` 미명시.
  - 각 SC 가 channel 1 / channel 2 중 어느 쪽을 사용하는지는 §2 각 case 의 Pre 절에 명시.
- **A7b — negative-channel 가정 (SC4 에만 적용).** 모든 ToolRoot resolution channel 이 비활성이어야 한다.
  - 호출에 `-ToolRoot` **미명시** (channel 1 비활성).
  - `AI_HARNESS_TOOL_ROOT` **unset** (channel 2 비활성).
  - A3b (global stable install 부재) 가 충족 (channel 3 비활성).
  - A3 (multi-marker 부재) 가 충족 (channel 4 비활성).
  - A2 (`.ai-harness/` 부재) 가 충족 (channel 5 비활성).
- **A8.** Source repo (`<SourceRepoRoot>`) 의 working tree 가 smoke 시작 시점에 clean 상태다 — `git status --porcelain=v1` 결과가 빈 문자열이며, `git rev-parse HEAD` 의 결과를 본 smoke run 의 **execution HEAD** 로 기록한다 (§4 항목 4). smoke 도중 `<SourceRepoRoot>` 안에 새 / 변경 파일이 발생하거나 HEAD 가 shift 하면 SC7 fail (§5 의 stop trigger 와 함께 다룬다).

SC1 은 `Get-ToolRoot` 를 호출하지 않는다. SC1 의 가정은 A1, A2, A4, A5, A6 만 요구한다 (A7a / A7b 모두 불필요).

### 1.1 Fixture lifecycle

**Default (recommended): independent fresh fixture per numbered SC.**

- 각 numbered SC 시작 전, 새 임시 디렉터리를 만들고 `git init` 으로 초기화, A1–A6 baseline 을 다시 구성한다.
- SC 간 inter-case state coupling 이 없으므로, 한 SC 의 산출물 (예: SC2 가 seed 한 untracked `log/brief/BRIEF.md`) 이 다음 SC (예: SC5 의 untracked-clean 요구) 를 오염시키지 않는다.
- evidence 수집 비용이 증가하지만, 진단성과 재현성에서 우위.

**Alternative: sequenced fixture with explicit reset steps.**

evidence 통합이 필요한 경우 한 fixture 를 재사용할 수 있다. 그 경우 SC 사이에 아래 절차를 명시한다.

- SC1 → SC2: 추가 절차 없음. SC1 이 생성한 `<ProjectRoot>/log/` 는 A6 의 `.gitignore log/` 로 untracked 가드를 통과한다.
- SC2 → SC3: SC3 의 action 이 brief-init 이면, SC2 가 seed 한 `<ProjectRoot>/log/brief/BRIEF.md` 가 이미 존재해 "already exists" 로 refuse 된다. 그 경우 다음 중 하나를 적용한다. (BRIEF 는 `log/` 아래 operator-local runtime state 이고 A6 의 `.gitignore log/` 규칙으로 ignored 되므로, 제거에 git tracked 전환 / commit 단계는 필요하지 않다.)
  1. SC3 직전에 `Remove-Item <ProjectRoot>\log\brief\BRIEF.md` 로 seed 된 파일만 제거한다.
  2. SC3 만 fresh fixture 로 분리.
- SC3 → SC4: 추가 절차 없음.
- **SC2 또는 SC3 → SC5 (review-cycle).** SC2 / SC3 가 seed 한 `log/brief/BRIEF.md` 는 untracked 이지만 `log/` 트리 아래에 있고, review-cycle 의 untracked 가드 (`scripts/review-cycle.ps1` 의 `Get-TrackedChangedFiles`) 는 `log/` prefix 의 untracked 항목을 제외한다. 따라서 seed 된 BRIEF 는 SC5 의 untracked-clean 요구를 오염시키지 않으며, SC5 호출 전 별도의 reset / commit 절차가 필요하지 않다. evidence 통합 목적상 SC5 만 fresh fixture 로 분리하는 것도 여전히 가능하다.
- **SC5 → SC6 (Resolve-CycleScript fail-fast).** SC5 가 생성한 `log/review/<run-id>/` 는 A6 로 untracked 가드를 통과한다. 단 SC6 는 `AI_HARNESS_TOOL_ROOT` 를 invalid path 로 set 하므로 환경변수 재설정이 필요하다.
- SC7 (cross-tree write isolation) 은 다른 모든 SC 의 umbrella invariant 다. fresh / sequenced 어느 쪽이든 매 case before / after snapshot 을 비교한다.

sequenced 운영을 채택하면 evidence 보고에 `sequenced fixture; reset steps applied between SCx and SCy` 를 명시한다.

---

## 2. Smoke test cases — observable pass / fail criteria

각 case 는 Pre / Action / Pass / Fail / Evidence 형식. `<SourceRepoRoot>` 안에 어떠한 write 도 발생해서는 안 된다 (SC7 umbrella; channel resolution 결과로서의 `<ToolRoot>` 는 SC6 처럼 별도 임시 directory 일 수 있으며 그 directory 의 read-only 여부는 본 invariant 의 대상이 아니다).

### SC1 — LogRoot creation via log-init (ProjectRoot-only)

본 case 는 `Get-ToolRoot` 를 검증하지 않는다. `log-init.ps1` 는 `Get-ProjectRoot` / `Get-ProjectLogRoot` 만 사용한다 (`scripts/log-init.ps1`). channel 검증은 SC2 / SC3 / SC4 에서 다룬다.

본 case 는 A7a / A7b (positive / negative channel 가정) 어느 것도 요구하지 않는다. `Get-ToolRoot` 가 호출되지 않으므로 channel 조건은 무관하다. 단, suite-level 의 **A8 / SC7 `<SourceRepoRoot>` read-only invariant 는 SC1 에도 그대로 적용된다.** SC1 실행 전 · 후로 `<SourceRepoRoot>` 의 git 상태가 변하지 않아야 하며, SC7 umbrella 가 본 case 도 포함한다.

- **Pre.** A1, A2, A4, A5, A6 충족. **A8 (suite-level)**. CWD = `<ProjectRoot>`. A7a / A7b 는 본 case 에서 요구되지 않는다.
- **Action.** `powershell -NoProfile -ExecutionPolicy Bypass -File <source-repo>/scripts/log-init.ps1 -ProjectRoot <ProjectRoot>`.
  - 호출 path 안의 `<source-repo>` 는 단순한 shell-level path 이며 `Get-ToolRoot` 의 입력이 아니다. `AI_HARNESS_TOOL_ROOT` 환경변수의 set 여부는 본 case 의 관찰 대상이 아니다.
- **Pass.**
  - exit 0.
  - `<ProjectRoot>/log/`, `<ProjectRoot>/log/chatlog/`, `<ProjectRoot>/log/evidence/`, `<ProjectRoot>/log/review/` 가 모두 존재.
  - host log 에 `log-init: done. ProjectRoot=<ProjectRoot>` 출력.
- **Fail.** non-zero exit, 디렉터리 누락, `<ProjectRoot>` 밖에 `log/` 생성.
- **Evidence.** stdout, `<ProjectRoot>/log/` 재귀 listing, `<SourceRepoRoot>` 의 `git status --porcelain=v1` (SC7 input).

### SC2 — ToolRoot channel 1 (explicit `-ToolRoot`) via brief-init

- **Pre.** A1–A6 + A7a (channel 1 모드: `-ToolRoot` 명시, env var unset). A8.
- **Action.** `powershell -NoProfile -ExecutionPolicy Bypass -File <source-repo>/scripts/brief-init.ps1 -ProjectRoot <ProjectRoot> -ToolRoot <source-repo-absolute-path>`.
- **Pass.**
  - exit 0.
  - `<ProjectRoot>/log/brief/BRIEF.md` 가 생성됨. SHA-256 이 `<source-repo>/templates/brief/BRIEF.md` 와 일치.
  - host log `brief-init: PASS`.
- **Fail.** non-zero exit, BRIEF.md 미생성, hash mismatch, 또는 ToolRoot mis-resolution 증거 (예: 다른 template path 가 stdout 에 등장).
- **Evidence.** stdout, 양쪽 BRIEF.md 의 SHA-256, `<SourceRepoRoot>` 의 `git status`.

### SC3 — ToolRoot channel 2 (env var) via brief-init

본 case 가 `AI_HARNESS_TOOL_ROOT` 의 channel 2 활성을 검증한다.

- **Pre.** A1–A6 + A7a (channel 2 모드: `AI_HARNESS_TOOL_ROOT = <source-repo-absolute-path>`, `-ToolRoot` 미명시). A8. (sequenced 사용 시 §1.1 의 SC2 → SC3 절차에 따라 fresh BRIEF 상태 확보.)
- **Action.** `powershell -NoProfile -ExecutionPolicy Bypass -File $env:AI_HARNESS_TOOL_ROOT/scripts/brief-init.ps1 -ProjectRoot <ProjectRoot>` (즉 `-ToolRoot` 미명시).
- **Pass.**
  - exit 0.
  - `<ProjectRoot>/log/brief/BRIEF.md` 가 생성되고 hash 일치.
  - `Get-ToolRoot` 가 channel 2 로 resolve 되었음을 다음 방식으로 간접 확인: ToolRoot 가 명시되지 않았는데 (channel 1 비활성) BRIEF seed 가 성공했고 — channel 2 (env var) 가 최우선 활성 channel 이며 그보다 후순위인 channel 3 (global stable install, A3b 로 부재) / channel 4 (dogfooding, A3 로 비활성) / channel 5 (legacy, A2 로 비활성) 는 모두 비활성 —, 동일 fixture 에서 환경변수 unset 시 SC4 가 throw 함.
- **Fail.** non-zero exit, BRIEF.md 미생성, hash mismatch.
- **Evidence.** stdout, BRIEF.md SHA-256, 환경변수 dump, `<SourceRepoRoot>` 의 `git status`.

### SC4 — Channel exhaustion (no resolvable channel)

- **Pre.** A1–A6 + A7b (env var unset, `-ToolRoot` 미명시, A2 / A3 충족). A8.
- **Action.** `powershell -NoProfile -ExecutionPolicy Bypass -File <source-repo>/scripts/brief-init.ps1 -ProjectRoot <ProjectRoot>`.
- **Pass.**
  - non-zero exit.
  - host transcript (stdout + stderr 결합 캡처) 에 `Get-ToolRoot` 의 channel-trace throw 가 포함됨: `channel 1 (-ToolRoot parameter): not provided`, `channel 2 (env AI_HARNESS_TOOL_ROOT): not set or empty`, `channel 3 (global stable install): not present`, `channel 4 (dogfooding multi-marker ...): markers missing`, `channel 5 (legacy <ProjectRoot>/.ai-harness): not present` 의 다섯 항목. PowerShell 의 uncaught `throw` 는 일반적으로 stderr 로 emit 되므로 stdout-only 캡처로는 channel trace 가 보이지 않아 정상 실패가 fail 로 오판될 수 있다. 따라서 본 case 의 evidence 는 stdout 과 stderr 를 모두 캡처하거나 결합 transcript 를 수집해야 한다.
  - `<ProjectRoot>/log/brief/` 가 생성되지 않음.
- **Fail.** exit 0, channel trace 누락 (stdout + stderr 결합 transcript 기준), BRIEF 디렉터리 (`<ProjectRoot>/log/brief/`) 생성.
- **Evidence.** host transcript 전문 (stdout + stderr 결합), `<ProjectRoot>` directory listing before / after diff (변화 없음).

### SC5 — review-cycle ToolRoot binding (D6)

본 case 는 외부 Codex CLI 가용성에 의존한다. CLI 부재 환경에서는 **SC5'** (review-prepare-only) 로 대체한다.

- **Pre.** A1–A6 + A7a (channel 1 또는 channel 2 중 택일; case 절에 명시). A8. §1.1 의 SC2 → SC5 / SC3 → SC5 절 참조 — SC2 / SC3 가 seed 한 `log/brief/BRIEF.md` 는 `log/` 가드 제외로 SC5 의 untracked-clean 요구를 오염시키지 않으므로 별도 reset / commit 절차는 불필요하다 (fresh fixture 사용도 가능).
- **Action.** `<source-repo>/scripts/review-cycle.ps1 -Stage implementation -Purpose 'smoke' -TargetFiles <single-existing-tracked-file> -Context '<C>' -RequiredInspectionPaths '<P>' -ReviewQuestions '<Q>' -Constraints '<X>'` 1 회 호출. ProjectRoot / ToolRoot 인자는 채택한 channel 에 맞춰 전달. `<C>` / `<P>` / `<Q>` / `<X>` 는 `templates/review-input.md` 의 4 개 placeholder 섹션 (`## Context`, `## Required inspection paths`, `## Review questions`, `## Constraints`) 을 채우기 위한 non-empty 문자열이며, `review-input-verify` 가 거부하는 forbidden 토큰 (`Replace this placeholder`, `(Provide context here.)`, `(Provide review questions here.)`) 을 포함해서는 안 된다. minimum-viable 예시:
  - `<C>`: `Clean target smoke verification of D6 verifier binding under channel-resolved ToolRoot.`
  - `<P>`: `<single-existing-tracked-file>` 의 path (TargetFiles 와 동일 path).
  - `<Q>`: `Is the target file syntactically intact for smoke purposes? Respond with the verdict vocabulary only.`
  - `<X>`: `Smoke only. Do not approve commit, push, publish, merge, release, or deployment.`

  위 4 개 파라미터가 미명시되면 `review-cycle.ps1` 이 `input.md` 를 substitution 없이 그대로 두고, `review-input-verify` 의 placeholder / empty-section 게이트가 fire 하여 Codex 가 호출되지 않는다. 그 경우 D6 verifier binding 의 VERIFY half (`review-verify.ps1` 의 `meta.toolRoot` ↔ runtime mismatch FAIL 검증) 가 exercise 되지 않으며 본 case 는 본 §2 의 Pass 조건을 충족할 수 없다.
- **Pass.**
  - exit 0.
  - `<ProjectRoot>/log/review/<run-id>/meta.json` 의 `projectRoot`, `toolRoot`, `projectLogRoot` 가 runtime 값과 case-insensitive ordinal equality.
  - `review-cycle.ps1` 이 자체적으로 호출하는 `review-verify.ps1` default + `-RequireResult` 두 모드 모두 PASS.
  - `result.json.verdict` 가 `yes` / `no` / `yes with risk` 중 하나.
- **Fail.** non-zero exit, root field mismatch, verify FAIL, verdict vocabulary 위반.
- **Evidence.** `meta.json`, `input.md`, `result.md`, `result.json`, verify stdout, `<SourceRepoRoot>` 의 `git status`.

#### SC5' — review-prepare-only fallback (Codex CLI 부재 시)

본 case 의 ProjectRoot / ToolRoot channel 가정은 **SC5 와 동일하다** (A1–A6 + A7a; channel 1 또는 channel 2 중 SC5 가 채택한 동일 channel). Codex CLI 미가용 환경에서 `review-prepare.ps1` 만 호출하여 prepare 산출물의 ToolRoot binding 만 검증한다. Codex 실행 / verdict / `review-verify` 검증은 본 case 의 범위 밖이다.

본 case 는 SC5 의 §5.4 D6 verifier binding 검증 (`meta.toolRoot` ↔ runtime ToolRoot mismatch FAIL) 을 **포함하지 않는다.** Codex CLI 가 부재한 환경에서는 `review-cycle` 이 `review-verify` 단계까지 진행하지 않기 때문이다. 따라서 SC5' 는 SC5 의 **partial substitute** 이며, D6 binding 의 완전 충족은 별도 fixture (Codex CLI 가 가용한 환경) 에서 SC5 를 직접 실행해야 한다. suite-level 결과 분류는 §5 의 partial 분류 규칙을 따른다.

- **Pre.** SC5 와 동일.
- **Action.** `<source-repo>/scripts/review-prepare.ps1 -Stage implementation -Purpose 'smoke' -TargetFiles <single-existing-tracked-file>` 1 회 호출.
- **Pass.** `<ProjectRoot>/log/review/<run-id>/meta.json` 의 root field 가 runtime 일치. `input.md` seed 됨. Codex 미호출.
- **Fail.** root field mismatch, prepare 자체 실패.
- **Evidence.** `meta.json`, `input.md`, stdout, `<SourceRepoRoot>` 의 `git status`.

evidence 보고에 SC5 / SC5' 중 어느 쪽이 실행되었는지 명시한다. SC5' 가 실행된 경우 suite-level 결과를 `partial: SC5 D6 verifier binding not covered` 로 분류한다.

### SC6 — `Resolve-CycleScript` explicit fail-fast (D2)

- **Pre.** A1–A6 + A7a 의 변형: `AI_HARNESS_TOOL_ROOT` 가 **유효한 디렉터리이지만 toolset payload 가 없는** 빈 임시 directory 로 set 됨. A8.
- **Action.** `<source-repo>/scripts/review-cycle.ps1 -Stage implementation -Purpose 'smoke' -TargetFiles <file>` 호출. `-ToolRoot` 미명시 (env var 가 channel 2 로 활성).
- **Pass.**
  - non-zero exit.
  - host transcript (stdout + stderr 결합 캡처) 에 `component script not found under explicit ToolRoot` 류 throw. `$PSScriptRoot` fallback **미발동** (explicit channel ToolRoot 이므로). PowerShell 의 uncaught `throw` 는 일반적으로 stderr 로 emit 되므로 stdout-only 캡처로는 정상 실패가 fail 로 오판될 수 있다.
- **Fail.** exit 0, silent fallback 으로 source repo 의 component 가 사용되었음을 시사하는 transcript, `<ProjectRoot>/log/review/<run-id>/` 생성.
- **Evidence.** host transcript (stdout + stderr 결합), env var dump, `<ProjectRoot>/log/review/` listing.

### SC7 — Cross-tree write isolation invariant (D8 umbrella)

본 case 는 SC1–SC6 의 umbrella invariant 다. 각 numbered SC 의 before / after 로 측정한다. 측정 대상은 channel-resolved `<ToolRoot>` 가 아니라 **`<SourceRepoRoot>`** 다 (Terminology 절 참조). 즉 SC4 처럼 `<ToolRoot>` 가 정의되지 않거나 SC6 처럼 `<ToolRoot>` 가 빈 임시 directory 인 경우에도 본 invariant 는 `<SourceRepoRoot>` 의 mutation 부재를 검증한다.

- **Pre.** A8. 각 SC 시작 전 `<SourceRepoRoot>` 의 `git status --porcelain=v1` 와 (선택) `git ls-files | xargs sha256sum` 의 snapshot 확보.
- **Action.** 본 case 는 단독 action 이 없다. SC1–SC6 의 매 실행 전 · 후로 `<SourceRepoRoot>` snapshot 을 다시 측정한다.
- **Pass.** before == after. `<SourceRepoRoot>` 의 tracked / untracked 양쪽 모두 신규 또는 변경 항목 없음.
- **Fail.** `<SourceRepoRoot>` 안에 1 개 이상의 신규 / 변경 파일.
- **Evidence.** SC 별 before / after snapshot diff (`<SourceRepoRoot>` 대상).

---

*Informational note.* clean target 에는 A2 에 의해 `.ai-harness/` 가 없으므로 D7 의 untracked exclusion path 는 본 smoke 에서 trigger 되지 않는다. 본 사실은 정보성이며 별도 pass / fail 케이스로 다루지 않는다. D7 exclusion 자체의 동작 검증은 별도 fixture (legacy `.ai-harness/` 가 untracked 로 남은 시나리오) 에서 수행되며, 본 clean target smoke 의 범위 밖이다.

---

## 2A. Stable global channel 3 positive smoke (CH3 series)

본 절은 §2 의 SC1–SC7 과 **별개의 케이스 군** 이다. SC1–SC7 은 channel 1 (`-ToolRoot`) / channel 2 (`AI_HARNESS_TOOL_ROOT`) 의 positive 케이스와 channel exhaustion (SC4) 을 다루며, channel 3 (global stable install `%USERPROFILE%\.claude\ai-harness-toolset\current`) 의 **positive resolution** 은 다루지 않는다 — SC4 는 오히려 A3b 로 channel 3 의 부재를 요구한다. 본 §2A 는 그 gap, 즉 stable global channel 3 가 실제로 materialize 된 환경에서의 positive resolution 을 다룬다.

본 절은 세 부분을 명시적으로 구분한다.

- **(I) Current observed pass status** — global stable ToolRoot 가 `%USERPROFILE%\.claude\ai-harness-toolset\current` 에 controlled materialization 된 직후, CH3-A / CH3-B / CH3-C 가 각각 1 회 실행되어 PASS 로 관찰된 기록.
- **(II) Formalized criteria** — 본 케이스 군을 §2 의 SC1–SC7 과 동일한 수준의 Pre / Action / Pass / Fail / Evidence 형식으로 정식화한 contract. (I) 의 observed-status 기록 위에 evaluation contract 의 정식 binding 을 추가한다. 본 절은 implementation / automation 의 자동 승인이 아니다.
- **(III) Future deferred items** — CH3-D 등 본 commit 의 (II) Formalized criteria 에 포함되지 않은 deferred 케이스의 기록. (III) 은 본 절이 실행 / 승인하지 않는 범위다.

### (I) Current observed pass status

아래는 관찰 기록이며 criteria binding 이 아니다. execution HEAD / fixture path / run-id 등 per-run 세부는 per-run evidence 가 권한이다 (§4 항목 4 와 정합). 본 절 본문은 특정 commit hash 에 pin 하지 않는다.

| case | 검증 대상 | 관찰 결과 |
|---|---|---|
| **CH3-A** | clean target fixture (`-ToolRoot` 미명시, `AI_HARNESS_TOOL_ROOT` unset, source markers 부재, `.ai-harness/` 부재) 에서 `brief-init.ps1` 가 ToolRoot 를 channel 3 `%USERPROFILE%\.claude\ai-harness-toolset\current` 로 resolve. seeded `log/brief/BRIEF.md` 가 channel 3 의 `templates/brief/BRIEF.md` 와 SHA-256 identical. | PASS |
| **CH3-B** | 동일 clean target 조건에서 `review-cycle.ps1` 가 channel 3 로 resolve 하고 `meta.json.toolRoot` 가 `%USERPROFILE%\.claude\ai-harness-toolset\current` 에 bind. `review-verify` default + `-RequireResult` 모두 PASS. | PASS |
| **CH3-C** | `brief-init.ps1` / `review-cycle.ps1` 의 runtime output 이 fixture 의 `log/` 아래에만 생성되고, source repo (`<SourceRepoRoot>`) 와 global `current` payload 가 모두 unchanged. global `.claude` layer (`CLAUDE.md` / `AGENTS.md` / `skills/`) 도 unchanged. | PASS |

위 세 케이스는 stable global channel 3 materialization 직후 단일 라운드로 실행되었다. 재실행 / regression 추적은 본 절의 범위가 아니다.

**Reaffirming round.** 별도 후속 round (global activation 의 latest repo HEAD 재동기화 직후) 에서 CH3-A 는 brief-init smoke 로, CH3-B / CH3-C 는 review-cycle smoke 로 재검증되어 동일하게 PASS 로 관찰되었다. CH3-B 의 verifier-half 도 본 reaffirming round 에서 함께 충족되었다 — `meta.json.toolRoot` 가 `%USERPROFILE%\.claude\ai-harness-toolset\current` 에 bind, `meta.json.projectRoot` 가 fixture 에 bind, `review-verify` default + `-RequireResult` 모두 PASS, `result.json.verdict` 가 valid vocabulary (`yes` / `no` / `yes with risk`) 안에 위치. CH3-C 의 isolation invariant (fixture/`log/` only runtime artifact, source repo / global `current/` payload / `%USERPROFILE%\.claude\AGENTS.md` 부재 / env var 모두 unchanged, fixture 에 `.ai-harness/` · `scripts/` · `config/` · `templates/` · `snippets/` payload 부재) 도 동일하게 관찰되었다. 재검증의 execution HEAD / fixture path / run-id 같은 per-run 세부는 본 절 본문이 아니라 per-run evidence 가 권한이다 (§4 항목 4 와 정합, `docs/archive/backlog/operations.md` Long-lived docs commit hash hygiene 항목과도 정합). CH3-D 는 본 절 (III) 에 따라 여전히 deferred 다.

### (II) Formalized criteria — Pre / Action / Pass / Fail / Evidence

본 절은 §2A 의 채널 3 positive smoke 를 §2 의 SC1–SC7 과 동일한 Pre / Action / Pass / Fail / Evidence 형식으로 정식화한다. (I) 의 observed-status 기록과 충돌하지 않으며, (I) 은 본 정식 criteria 의 사전 관찰 기록 역할로 보존된다. 본 정식 criteria 는 implementation / automation 의 자동 승인이 아니라 evaluation contract 의 기록이다.

#### CH3 시리즈에 적용되는 보조 가정

본 §2A 시리즈에만 적용되는 self-contained 가정. §1 의 기존 A1–A8 / A7a / A7b / A3b 는 그대로 유효하며 본 절의 가정은 그와 호환되도록 정의된다.

- **A7c — CH3 positive-channel mode**. ToolRoot 가 channel 3 으로 resolve 되어야 한다. 호출에 `-ToolRoot` 미명시, `AI_HARNESS_TOOL_ROOT` Process / User / Machine scope 모두 unset (channel 1, 2 비활성). A3 (multi-marker 부재 → channel 4 비활성), A2 (`.ai-harness/` 부재 → channel 5 비활성) 충족. 따라서 channel 3 가 최우선 활성 channel.
- **A3c — CH3 global stable install 활성**. `%USERPROFILE%\.claude\ai-harness-toolset\current\` 가 존재하고 channel 3 payload completeness 조건 (entrypoint `scripts/review-cycle.ps1` 등) 을 충족. 본 가정은 §1 A3b 의 정반대 — A3b 는 SC4 channel exhaustion 검증을 위해 channel 3 부재를 요구하고, A3c 는 본 §2A 시리즈가 channel 3 positive resolution 을 검증하기 위해 channel 3 존재를 요구한다. 두 가정은 서로 다른 case 군에 적용되므로 충돌하지 않는다.
- **A9 — forbidden path absent**. `%USERPROFILE%\.claude\AGENTS.md` 가 case 시작 시점에 absent. snippet contract 상 valid destination 이 아닌 forbidden path 이며 (`GLOBAL_ADOPTION_DECISION.md` §6 path table 의 Forbidden row 와 정합), case 동안 생성되어서는 안 된다.

#### CH3-A — brief-init seed via channel 3

clean target 에서 `Get-ToolRoot` 가 channel 3 으로 resolve 되었음을 `brief-init.ps1` 이 seed 한 BRIEF.md 가 channel 3 의 template 과 byte-identical 한지로 검증한다.

- **Pre.** A1, A2, A3, A4, A5, A6, A7c, A3c, A8, A9. CWD = `<fixture>`.
- **Action.** `powershell -NoProfile -ExecutionPolicy Bypass -File "%USERPROFILE%\.claude\ai-harness-toolset\current\scripts\brief-init.ps1" -ProjectRoot <fixture>`.
- **Pass.**
  - exit 0.
  - `<fixture>/log/brief/BRIEF.md` 생성.
  - seeded BRIEF.md 의 SHA-256 == `%USERPROFILE%\.claude\ai-harness-toolset\current\templates\brief\BRIEF.md` 의 SHA-256 (byte-identical — channel 3 resolution 의 직접 증거).
  - host stdout 의 `brief-init: source template ...` line 의 path 가 `%USERPROFILE%\.claude\ai-harness-toolset\current\templates\brief\BRIEF.md` (channel 3 경로).
- **Fail.** non-zero exit; BRIEF.md 미생성; SHA-256 mismatch; `source template` path 가 channel 3 외부 (source repo, `<fixture>/.ai-harness/`, `%USERPROFILE%\.codex\` 등) 로 출력.
- **Evidence.** stdout 전문; seeded BRIEF.md SHA-256; channel 3 template SHA-256; `<SourceRepoRoot>` 의 `git status --porcelain=v1` (SC7 입력); fixture 의 forbidden subtree (`<fixture>/.ai-harness/`, `<fixture>/scripts/`, `<fixture>/config/`, `<fixture>/templates/`, `<fixture>/snippets/`) absence; CH3-C umbrella 가 사용하는 global snapshot.

#### CH3-B — review-cycle ToolRoot/ProjectRoot binding via channel 3

본 case 는 외부 Codex CLI 가용성에 의존한다. CLI 부재 환경에서는 CH3-B' (prepare-only fallback) 로 대체한다. clean target 에서 `review-cycle.ps1` 가 channel 3 으로 resolve 되고 `meta.json` 의 root field 가 expected path 에 bind 되며 `review-verify -RequireResult` 가 PASS 하는지 검증한다.

- **Pre.** A1, A2, A3, A4, A5, A6, A7c, A3c, A8, A9. fixture 에 review TargetFiles 후보 tracked file 1 개 이상 존재.
- **Action.** `& "%USERPROFILE%\.claude\ai-harness-toolset\current\scripts\review-cycle.ps1" -Stage implementation -Purpose '<smoke purpose>' -TargetFiles <single-tracked-file> -Context '<C>' -RequiredInspectionPaths '<P>' -ReviewQuestions '<Q>' -Constraints '<X>'` 1 회. `-ToolRoot` / `-ProjectRoot` 모두 미명시 (channel 3 default + CWD default). `<C>` / `<P>` / `<Q>` / `<X>` 는 `review-input-verify` 의 placeholder / empty-section 게이트를 통과하는 minimum-viable 문자열 (SC5 의 동일 prescription 와 동등).
- **Pass.**
  - exit 0.
  - `<fixture>/log/review/<run-id>/meta.json` 의 `toolRoot` field 가 `%USERPROFILE%\.claude\ai-harness-toolset\current` 에 normalized + case-insensitive ordinal equality 로 bind.
  - `meta.json.projectRoot` 가 `<fixture>` 에 bind. `meta.json.projectLogRoot` 가 `<fixture>/log` 에 bind.
  - `review-cycle.ps1` 이 자체적으로 호출하는 `review-verify.ps1` default + `-RequireResult` 두 모드 모두 PASS.
  - `result.json.verdict` 가 `yes` / `no` / `yes with risk` 중 하나.
- **Fail.** non-zero exit; `meta.json.toolRoot` mismatch (예: source repo / `.codex\` / `<fixture>` 내부 등 channel 3 외부); root field mismatch; `review-verify` FAIL; `result.json` / `result.md` 미생성; verdict vocabulary 위반.
- **Evidence.** `meta.json`, `input.md`, `result.md`, `result.json`, `review-verify` 두 모드 stdout; `<SourceRepoRoot>` 의 `git status`; fixture 의 forbidden subtree absence; CH3-C umbrella 가 사용하는 global snapshot.

##### CH3-B' — review-prepare-only fallback (Codex CLI 부재 시)

본 case 의 환경 가정은 CH3-B 와 동일. Codex CLI 가 부재한 환경에서 `review-prepare.ps1` 만 호출하여 prepare 산출물의 ToolRoot binding 만 검증한다. Codex 실행 / verdict / `review-verify` 의 result-binding 검증은 본 case 의 범위 밖이다.

본 case 는 CH3-B 의 verifier-half (`meta.toolRoot` ↔ runtime ToolRoot mismatch FAIL 검증) 를 포함하지 **않는다.** 따라서 CH3-B 의 **partial substitute** 이며, CH3-B 의 완전 충족은 별도 fixture (Codex CLI 가용 환경) 에서 CH3-B 를 직접 실행해야 한다. suite-level 결과 분류는 §5 의 partial 분류 규칙을 따른다 (`partial: CH3-B verifier binding not covered, channel 3 prepare-side ToolRoot binding covered`).

- **Pre.** CH3-B 와 동일.
- **Action.** `& "%USERPROFILE%\.claude\ai-harness-toolset\current\scripts\review-prepare.ps1" -Stage implementation -Purpose '<smoke purpose>' -TargetFiles <single-tracked-file>` 1 회.
- **Pass.** `<fixture>/log/review/<run-id>/meta.json` 의 root field (`toolRoot` / `projectRoot` / `projectLogRoot`) 가 CH3-B Pass 의 첫 3 항목과 동일하게 bind. `input.md` seed 됨. Codex 미호출.
- **Fail.** root field mismatch; prepare 자체 실패.
- **Evidence.** `meta.json`, `input.md`, prepare stdout, `<SourceRepoRoot>` 의 `git status`.

evidence 보고에 CH3-B / CH3-B' 중 어느 쪽이 실행되었는지 명시한다. CH3-B' 가 실행된 경우 suite-level 결과를 `partial: CH3-B verifier binding not covered` 로 분류한다.

#### CH3-C — runtime isolation umbrella (channel 3)

본 case 는 CH3-A 와 CH3-B (또는 CH3-B') 의 umbrella invariant 다. SC7 의 source-tree read-only invariant 를 channel 3 환경의 추가 isolation 까지 확장한다. CH3-A / CH3-B / CH3-B' 의 매 실행 전 · 후로 측정한다.

- **Pre.** A8 (suite-level `<SourceRepoRoot>` `git status` 빈 문자열 + execution HEAD snapshot), A9 (forbidden path absent). case 시작 전에 다음 snapshot 확보:
  - `<SourceRepoRoot>` 의 `git status --porcelain=v1` (SC7 입력).
  - `%USERPROFILE%\.claude\ai-harness-toolset\current\` 의 aggregate digest (per-file SHA-256 rel:hash per-line 후 SHA-256, 또는 이와 등가인 deterministic digest).
  - `%USERPROFILE%\.claude\AGENTS.md` absent 확인 (A9).
  - `%USERPROFILE%\.claude\CLAUDE.md` 의 managed-block 외부 content hash (block 안은 user-approved managed-block insert/replace scope 이므로 외부만 capture).
  - effective Codex global instruction file (`%USERPROFILE%\.codex\AGENTS.md` 또는 `%CODEX_HOME%\AGENTS.md` 또는 그 scope 의 `AGENTS.override.md`) 의 managed-block 외부 content hash.
  - `AI_HARNESS_TOOL_ROOT` 와 `CODEX_HOME` 의 Process / User / Machine scope 값.
  - `<fixture>` 의 forbidden subtree (`<fixture>/.ai-harness/`, `<fixture>/scripts/`, `<fixture>/config/`, `<fixture>/templates/`, `<fixture>/snippets/`) absence 확인.
- **Action.** 본 case 는 단독 action 이 없다. CH3-A / CH3-B / CH3-B' 의 매 실행 전 · 후로 위 snapshot 을 다시 측정한다.
- **Pass.**
  - **fixture/log/ only**: `<fixture>` 의 모든 신규 / 변경 file 이 `<fixture>/log/` 트리 하위에만 위치.
  - **target footprint clean**: `<fixture>/.ai-harness/`, `<fixture>/scripts/`, `<fixture>/config/`, `<fixture>/templates/`, `<fixture>/snippets/` 모두 case 종료 시점에 부재 (Pre snapshot 과 동일).
  - **source repo unchanged (SC7 invariant)**: `<SourceRepoRoot>` 의 tracked / untracked 양쪽 모두 신규 또는 변경 항목 없음.
  - **global current/ unchanged**: aggregate digest 가 Pre snapshot 과 동일 (channel 3 ToolRoot read-only invariant).
  - **forbidden path absent unchanged**: `%USERPROFILE%\.claude\AGENTS.md` 가 case 동안 생성되지 않음 (A9 유지).
  - **global CLAUDE.md / Codex AGENTS.md outside-block unchanged**: managed-block 외부 content hash 가 Pre snapshot 과 동일 (managed-block 자체는 본 case 의 mutation 대상이 아니므로 case 진행 중 변경되지 않으며, 외부 hash 의 동일성으로 boundary 확인).
  - **env var unchanged**: `AI_HARNESS_TOOL_ROOT` / `CODEX_HOME` 의 Process / User / Machine scope 모두 Pre snapshot 과 동일.
- **Fail.** 위 invariant 중 어느 하나라도 위반.
- **Evidence.** case 별 before / after snapshot diff (Pre 의 7 항목 모두), CH3-A / CH3-B (또는 CH3-B') 의 evidence 와 결합.

### (III) Future deferred items

- **CH3-D — incomplete-payload negative guard (deferred).** `%USERPROFILE%\.claude\ai-harness-toolset\current` 가 존재하지만 payload 가 불완전한 경우 (entrypoint `scripts/review-cycle.ps1` 부재) `Get-ToolRoot` 가 channel 3 에서 fallthrough 하지 않고 fail-fast throw 하는지 검증하는 negative 케이스 (`SHARED_GLOBAL_INVOCATION_CONTRACT.md` §5.1 channel 3 분기 참조). 본 케이스는 target 을 의도적으로 불완전 상태로 mutate 해야 하므로 별도 scoped 작업으로 **deferred** 한다. 본 commit 의 (II) Formalized criteria 에 CH3-D 는 포함되지 않으며, 본 절은 CH3-D 를 실행하지 않는다.

### Relationship to SC1–SC7

- 본 §2A 는 SC1–SC7 의 정의를 변경하지 않는다. SC4 의 A3b (channel 3 부재 가정) 는 그대로 유효하다 — SC4 는 channel exhaustion 을, §2A 는 channel 3 positive resolution 을 검증하므로 두 케이스 군의 환경 가정은 의도적으로 다르다.
- SC7 의 `<SourceRepoRoot>` read-only invariant 는 §2A 의 CH3-C 에서 동일하게 관찰되었으며, 추가로 materialized global `current` payload 의 read-only 도 함께 관찰되었다.

---

## 3. Expected ToolRoot / ProjectRoot / LogRoot / BriefRoot behavior

| 개념 | clean target 기대값 | 검증 SC |
|---|---|---|
| `ProjectRoot` | clean target 디렉터리. `Get-ProjectRoot` 가 CWD 를 fullpath 로 반환. `.git/` 존재로 advisory warning 없음. | SC1, SC5 / SC5' (`meta.json.projectRoot`). |
| `ToolRoot` | channel resolution 결과로서의 per-case 값. (a) 정상 positive-channel 케이스 (SC2 의 channel 1, SC3 의 channel 2, SC5 / SC5' 의 channel 1 또는 channel 2) — `<ToolRoot>` 가 `<SourceRepoRoot>` 절대경로로 resolve. channel 3 (global stable install) 은 A3b 로 부재, channel 4 (dogfooding) 는 A3 로 비활성, channel 5 (legacy) 는 A2 로 비활성. (b) SC6 의 의도된 mis-target — `<ToolRoot>` 가 toolset payload 없는 **valid empty temp directory** 로 resolve. `Resolve-CycleScript` 의 explicit fail-fast 가 발동하며, 이 케이스의 `<ToolRoot>` ≠ `<SourceRepoRoot>` 는 fail 이 아니라 의도된 동작. (c) SC4 의 channel exhaustion — 어떤 channel 도 활성화되지 않아 `Get-ToolRoot` 가 throw 하고 `<ToolRoot>` 는 **resolve 되지 않은 상태**. evidence 분류 시 `<ToolRoot>` 와 `<SourceRepoRoot>` 의 등호 / 부등호 / 미정의 상태를 위 (a)/(b)/(c) 에 따라 case 별로 기록한다. | SC2 (ch1), SC3 (ch2), SC4 (exhaustion / unresolved), SC5 / SC5' (`meta.json.toolRoot`), SC6 (fail-fast, intentional non-equality). |
| `LogRoot` | `<ProjectRoot>/log`. log-init 이 생성. lifecycle 스크립트가 `Assert-InProjectLogRoot` 로 격리. | SC1, SC5 / SC5' (`meta.json.projectLogRoot`). |
| `BriefRoot` | `<ProjectRoot>/log/brief`. brief-init 이 한 번 seed. `<ToolRoot>/templates/brief/BRIEF.md` 의 byte-equal copy. BRIEF 는 `log/` 아래 operator-local runtime state 이며 root `<ProjectRoot>/brief/` 는 생성하지 않는다. | SC2, SC3 (SHA-256). |

추가 invariant:

- ToolRoot 와 ProjectRoot 는 서로 다른 절대경로이며 prefix 관계도 아니다.
- ConfigRoot / TemplateRoot / ScriptRoot 는 본 smoke 에서 read-only. write 발생 시 SC7 fail.

---

## 4. Required evidence artifacts (for later execution goal)

execution goal 단계가 별도 scoped 승인 후 진행될 때, 다음을 `<ProjectRoot>/log/evidence/clean-target-smoke/<case>/` 에 보존한다 (또는 source repo 외부의 evidence 저장소 — ToolRoot 측에는 두지 않는다). evidence capture 의 base contract 는 `docs/contracts/evidence/EVIDENCE_CONTRACT.md` 를 따른다.

per-case 필수 evidence:

1. invocation transcript — 명령어 전문, 환경변수 dump (`AI_HARNESS_TOOL_ROOT`, `PSVersion`, `OS`), CWD.
2. exit code, stdout, stderr 전문.
3. case-별 산출물:
   - SC1. `<ProjectRoot>/log/` 재귀 listing.
   - SC2 / SC3. seed 된 `<ProjectRoot>/log/brief/BRIEF.md` 와 `<ToolRoot>/templates/brief/BRIEF.md` 의 SHA-256.
   - SC4. throw message 전문, `<ProjectRoot>` directory listing before / after diff.
   - SC5. `meta.json`, `input.md`, `result.md`, `result.json`, `review-verify` 두 모드 stdout.
   - SC5'. `meta.json`, `input.md`, prepare stdout.
   - SC6. throw message 전문, `<ProjectRoot>/log/review/` listing, env var dump.
   - SC7. SC 별 before / after `<SourceRepoRoot>` `git status --porcelain=v1` 및 (선택) directory hash.
4. test-level meta — `<run-id>` 매핑, UTC 실행 시각, 운영자, **execution HEAD** (실행 시점 `<SourceRepoRoot>` 에서 관찰된 git HEAD; `git rev-parse HEAD` 의 full hash 와 `git status --porcelain=v1` 결과를 evidence 에 그대로 기록한다 — 본 criteria 가 특정 commit 으로 pin 하지 않으므로 evidence 가 유일한 HEAD 기록 권한이다), fixture lifecycle (fresh vs sequenced + 적용된 reset step 의 verbatim 기록).
5. summary table — pass / fail / skip 분포, skip 사유 (예: `SC5 skipped — Codex CLI absent; SC5' executed in its place`).
6. ToolRoot invariant 결과 — SC7 의 SC 별 합산 verdict.

다른 트리 (review run, chatlog) 로 mirror 하지 않는다.

---

## 5. Stop / escalation triggers

execution goal 단계에서 다음 중 하나라도 발생하면 즉시 중단하고 별도 scoped 승인으로 올린다. 본 criteria 내에서 자동 진행 권한은 없다.

- SC7 fail — `<SourceRepoRoot>` 안에 신규 / 변경 파일.
- `Get-ToolRoot` channel trace 가 intended channel 외의 channel 로 resolve.
- SC5 `meta.json` root field 와 runtime mismatch.
- SC5 `result.json.verdict` 가 `yes` / `no` / `yes with risk` 외의 값.
- global / user 환경 mutation 발견 (`%USERPROFILE%\.claude\`, `%USERPROFILE%\.codex\` 또는 `%CODEX_HOME%`, `%USERPROFILE%\.claude\CLAUDE.md`, `%USERPROFILE%\.codex\AGENTS.md` / `%CODEX_HOME%\AGENTS.md` / Codex user-global `AGENTS.override.md`, project-root `CLAUDE.md` 또는 `AGENTS.md`, user shell config). `%USERPROFILE%\.claude\AGENTS.md` 가 새로 생성된 경우도 본 trigger 에 해당한다 — 그 path 는 어떤 agent 의 global instruction 경로도 아니므로 erroneous mutation 으로 분류한다.
- `<SourceRepoRoot>` working tree 가 smoke 시작 시 기록한 execution HEAD 와 다른 commit 으로 shift 되었거나 (mid-run HEAD shift), uncommitted change 가 발생.
- smoke 도중 script / config / template / snippet / tests 의 변경 필요성이 발견됨 — 본 criteria 의 scope 밖이며 별도 scoped 승인으로 분리.
- review verdict 가 `no` 또는 `yes with risk` 이고 그 finding 이 본 criteria 의 정정 범위를 벗어남 (script / contract 변경 요구, 또는 smoke 실행 요구).

**Partial coverage classification (escalation candidate).**

- SC5 가 SC5' 로 대체된 run 은 suite-level 결과를 `partial: SC5 D6 verifier binding not covered` 로 분류한다. partial 분류 자체는 즉시 stop 이 아니지만, D6 binding 의 완전 충족이 phase 게이트나 release 게이트로 요구되는 경우 본 partial 분류는 escalation trigger 다 — 별도 fixture (Codex CLI 가 가용한 환경) 에서 SC5 를 직접 실행해야 한다.

본 stop trigger 들은 자동 retry / 자동 fix loop 의 근거가 되지 않는다. 모든 회복 경로는 사용자 명시 승인 후 별도 scoped 작업이다.

---

## 6. Non-goals

본 문서는 다음을 **포함하지 않는다**. 본 문서가 존재한다는 사실로 아래 항목이 승인 / 실행되었다고 해석하지 않는다.

- 실제 smoke test 의 실행.
- target project 의 자동 생성, 자동 채택, 자동 변경.
- `scripts/`, `config/`, `templates/`, `snippets/`, `tests/` 의 변경.
- `Get-ToolRoot` channel chain 의 추가 또는 제거.
- 새 env var 의 도입 또는 기존 env var 의 이름 변경.
- `meta.json` schema 의 확장 또는 축소.
- `review-verify` 의 검증 항목 추가 또는 제거.
- `review-cycle.ps1` / `review-prepare.ps1` / `review-run.ps1` / `review-verify.ps1` / `log-init.ps1` / `brief-init.ps1` / `brief-check.ps1` 의 parameter contract 변경.
- global / user 환경 mutation (`%USERPROFILE%\.claude\`, `%USERPROFILE%\.codex\` 또는 `%CODEX_HOME%`, `%USERPROFILE%\.claude\CLAUDE.md`, `%USERPROFILE%\.codex\AGENTS.md` / `%CODEX_HOME%\AGENTS.md` / Codex user-global `AGENTS.override.md`, project-root `CLAUDE.md` 또는 `AGENTS.md`, user shell config, user git config). `%USERPROFILE%\.claude\AGENTS.md` 의 생성도 본 mutation 에 포함된다 (valid destination 이 아님).
- daemon, watcher, scheduler, hook installer, background process 의 도입.
- `BF_STATE.json` 등 별도 state machine 파일의 도입.
- automatic commit / push / publish / merge / release.
- legacy `ai-harness` 의 path handling 재활용.
- `docs/archive/backlog/review.md` 의 candidate 항목 (review 2-pass / file-backed request input 등) 의 implementation.
- review verdict 를 commit / push / publish / merge / release / 채택의 자동 승인 근거로 사용하는 것.

위 항목 중 어느 것이라도 진행하려면 별도 scoped 승인이 필요하다. 본 criteria 의 한 항목으로 위 행위가 묶이지 않는다.

---

## 7. Source-of-truth 관계

- 본 문서는 clean target smoke test 의 criteria 의 정의이며, 실행 / 채택 / script 변경 어느 것도 자동 승인하지 않는다.
- 본 criteria 가 binding 하는 source-of-truth 는 §Target 과 §1 머리에 열거된 contract 문서들 (`SHARED_GLOBAL_INVOCATION_CONTRACT.md`, `TOOLROOT_PROJECTROOT_AUDIT.md`, `GLOBAL_ADOPTION_DECISION.md`, `GLOBAL_ADOPTION_PROCEDURE.md`, `AI_HARNESS_TOOLSET_SCOPE.md`, `REVIEW_RESULT_CONTRACT.md`, `BRIEF_CONTRACT.md`, `EVIDENCE_CONTRACT.md`) 의 **현재 checked-out source snapshot** 이다. 본 문서는 특정 commit hash 에 binding 하지 않는다 — snapshot HEAD 의 권한은 git history 에 있고, 개별 smoke 실행의 execution HEAD 는 §4 항목 4 에 따라 per-run evidence 에 기록된다. 후속 commit 으로 contract 가 변경되면 본 criteria 의 영향 범위를 별도 라운드에서 재평가한다.
- 본 문서가 §1 의 source-of-truth 문서들과 상충하면 위 문서들의 보수적 해석을 우선한다.
- 본 문서는 review verdict (`yes` / `no` / `yes with risk`) 를 commit / push / publish / merge / release / adoption 의 자동 승인으로 해석하지 않는다는 contract 를 그대로 유지한다.
