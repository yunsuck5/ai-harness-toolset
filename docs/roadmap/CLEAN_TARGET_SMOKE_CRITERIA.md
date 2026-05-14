# Clean Target Smoke Test Criteria — Shared / Global Mode

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

- shared / global mode invocation contract: `docs/roadmap/SHARED_GLOBAL_INVOCATION_CONTRACT.md`
- ToolRoot / ProjectRoot audit: `docs/roadmap/TOOLROOT_PROJECTROOT_AUDIT.md`
- 운영 계층 결정: `docs/roadmap/GLOBAL_ADOPTION_DECISION.md`
- Claude skill global 절차: `docs/roadmap/GLOBAL_ADOPTION_PROCEDURE.md`
- subsystem scope: `docs/AI_HARNESS_TOOLSET_SCOPE.md`
- review record 계약: `docs/REVIEW_RESULT_CONTRACT.md`
- BRIEF 계약: `docs/BRIEF_CONTRACT.md`
- evidence 계약: `docs/EVIDENCE_CONTRACT.md`

위 문서와 본 문서가 상충하면 위 문서들의 보수적 해석을 우선한다.

> **BRIEF posture reconciliation — applied.** 본 문서의 BRIEF 관련 assertion (precondition A5 / A6,
> SC2 / SC3 / SC4, §1.1 fixture 절차, §3 BriefRoot, §4 evidence) 은 canonical BRIEF 위치인
> `<ProjectRoot>/log/brief/BRIEF.md` (`log/` 아래 operator-local runtime state) 기준으로 정리되었다.
> root `<ProjectRoot>/brief/` 는 ai-harness 용도로 금지되며, target project 의 persistent footprint 는
> `log/` 뿐이다. BRIEF 는 `log/` 규칙에 의해 default 로 ignored (untracked) 된다. canonical
> source-of-truth 는 `docs/BRIEF_CONTRACT.md` 다.

---

## Target

본 criteria 의 target 은 다음 한 가지 질문에 대한 observable answer 를 정의하는 것이다.

> shared / global mode 에서 `ai-harness-toolset` 의 lifecycle script 가 ToolRoot 와 ProjectRoot 를 독립 경로로 두고도 결정론적으로 동작하는가? — runtime artifact 가 ProjectRoot 안에만 생성되고, ToolRoot working tree 는 어느 case 에서도 mutate 되지 않는가? — channel resolution 의 positive / negative case 가 모두 contract 와 일치하는가?

본 문서는 위 질문을 case 단위로 분해하고, 각 case 의 pre-condition / action / observable pass / observable fail / required evidence 를 정의한다. 실제 실행은 별도 execution goal 에서 별도 scoped 승인을 거쳐 진행한다.

authoritative contract: `docs/roadmap/SHARED_GLOBAL_INVOCATION_CONTRACT.md` §5.1–§5.4 (D1, D2, D6 결정).

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
- **A2.** `<ProjectRoot>/.ai-harness/` 가 **존재하지 않는다** (channel 4 비활성).
- **A3.** `<ProjectRoot>` 가 dogfooding multi-marker (`scripts/verify-ps1.ps1`, `templates/review-input.md`, `config/reviewer.json`) 를 **모두 보유하지 않는다** (channel 3 비활성).
- **A4.** `<ProjectRoot>/log/` 가 존재하지 않거나, 존재해도 tracked file 0 개.
- **A5.** `<ProjectRoot>/log/brief/BRIEF.md` 가 존재하지 않는다.
- **A6.** `<ProjectRoot>/.gitignore` 가 `log/` 를 무시한다. canonical BRIEF artifact (`<ProjectRoot>/log/brief/BRIEF.md`) 는 이 `log/` 규칙에 의해 default 로 ignored (untracked) 된다 (`docs/BRIEF_CONTRACT.md` 의 tracked vs gitignored 기본값과 정합). root `<ProjectRoot>/brief/` 는 ai-harness 용도로 생성하지 않는다.
- **A7a — positive-channel 가정 (SC2, SC3, SC5, SC6 에 적용).** ToolRoot 가 적어도 하나의 channel 로 resolve 가능해야 한다. case 별 명시:
  - channel 1 사용 케이스: 모든 호출에 `-ToolRoot <source-repo-absolute-path>` 를 명시. `AI_HARNESS_TOOL_ROOT` 는 unset 권장 (혼선 방지).
  - channel 2 사용 케이스: `AI_HARNESS_TOOL_ROOT = <source-repo-absolute-path>`. `-ToolRoot` 미명시.
  - 각 SC 가 channel 1 / channel 2 중 어느 쪽을 사용하는지는 §2 각 case 의 Pre 절에 명시.
- **A7b — negative-channel 가정 (SC4 에만 적용).** 모든 ToolRoot resolution channel 이 비활성이어야 한다.
  - `AI_HARNESS_TOOL_ROOT` **unset**.
  - 호출에 `-ToolRoot` **미명시**.
  - A2 (`.ai-harness/` 부재) 와 A3 (multi-marker 부재) 가 충족.
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
  - `Get-ToolRoot` 가 channel 2 로 resolve 되었음을 다음 방식으로 간접 확인: ToolRoot 가 명시되지 않았는데 BRIEF seed 가 성공했고 (channel 3 / 4 가 A2 / A3 로 비활성), 동일 fixture 에서 환경변수 unset 시 SC4 가 throw 함.
- **Fail.** non-zero exit, BRIEF.md 미생성, hash mismatch.
- **Evidence.** stdout, BRIEF.md SHA-256, 환경변수 dump, `<SourceRepoRoot>` 의 `git status`.

### SC4 — Channel exhaustion (no resolvable channel)

- **Pre.** A1–A6 + A7b (env var unset, `-ToolRoot` 미명시, A2 / A3 충족). A8.
- **Action.** `powershell -NoProfile -ExecutionPolicy Bypass -File <source-repo>/scripts/brief-init.ps1 -ProjectRoot <ProjectRoot>`.
- **Pass.**
  - non-zero exit.
  - host transcript (stdout + stderr 결합 캡처) 에 `Get-ToolRoot` 의 channel-trace throw 가 포함됨: `channel 1 ... not provided`, `channel 2 ... not set or empty`, `channel 3 ... markers missing`, `channel 4 ... not present` 의 네 항목. PowerShell 의 uncaught `throw` 는 일반적으로 stderr 로 emit 되므로 stdout-only 캡처로는 channel trace 가 보이지 않아 정상 실패가 fail 로 오판될 수 있다. 따라서 본 case 의 evidence 는 stdout 과 stderr 를 모두 캡처하거나 결합 transcript 를 수집해야 한다.
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

## 3. Expected ToolRoot / ProjectRoot / LogRoot / BriefRoot behavior

| 개념 | clean target 기대값 | 검증 SC |
|---|---|---|
| `ProjectRoot` | clean target 디렉터리. `Get-ProjectRoot` 가 CWD 를 fullpath 로 반환. `.git/` 존재로 advisory warning 없음. | SC1, SC5 / SC5' (`meta.json.projectRoot`). |
| `ToolRoot` | channel resolution 결과로서의 per-case 값. (a) 정상 positive-channel 케이스 (SC2 의 channel 1, SC3 의 channel 2, SC5 / SC5' 의 channel 1 또는 channel 2) — `<ToolRoot>` 가 `<SourceRepoRoot>` 절대경로로 resolve. channel 3 / 4 는 A2 / A3 로 비활성. (b) SC6 의 의도된 mis-target — `<ToolRoot>` 가 toolset payload 없는 **valid empty temp directory** 로 resolve. `Resolve-CycleScript` 의 explicit fail-fast 가 발동하며, 이 케이스의 `<ToolRoot>` ≠ `<SourceRepoRoot>` 는 fail 이 아니라 의도된 동작. (c) SC4 의 channel exhaustion — 어떤 channel 도 활성화되지 않아 `Get-ToolRoot` 가 throw 하고 `<ToolRoot>` 는 **resolve 되지 않은 상태**. evidence 분류 시 `<ToolRoot>` 와 `<SourceRepoRoot>` 의 등호 / 부등호 / 미정의 상태를 위 (a)/(b)/(c) 에 따라 case 별로 기록한다. | SC2 (ch1), SC3 (ch2), SC4 (exhaustion / unresolved), SC5 / SC5' (`meta.json.toolRoot`), SC6 (fail-fast, intentional non-equality). |
| `LogRoot` | `<ProjectRoot>/log`. log-init 이 생성. lifecycle 스크립트가 `Assert-InProjectLogRoot` 로 격리. | SC1, SC5 / SC5' (`meta.json.projectLogRoot`). |
| `BriefRoot` | `<ProjectRoot>/log/brief`. brief-init 이 한 번 seed. `<ToolRoot>/templates/brief/BRIEF.md` 의 byte-equal copy. BRIEF 는 `log/` 아래 operator-local runtime state 이며 root `<ProjectRoot>/brief/` 는 생성하지 않는다. | SC2, SC3 (SHA-256). |

추가 invariant:

- ToolRoot 와 ProjectRoot 는 서로 다른 절대경로이며 prefix 관계도 아니다.
- ConfigRoot / TemplateRoot / ScriptRoot 는 본 smoke 에서 read-only. write 발생 시 SC7 fail.

---

## 4. Required evidence artifacts (for later execution goal)

execution goal 단계가 별도 scoped 승인 후 진행될 때, 다음을 `<ProjectRoot>/log/evidence/clean-target-smoke/<case>/` 에 보존한다 (또는 source repo 외부의 evidence 저장소 — ToolRoot 측에는 두지 않는다). evidence capture 의 base contract 는 `docs/EVIDENCE_CONTRACT.md` 를 따른다.

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
- global / user 환경 mutation 발견 (`~/.claude/`, root `CLAUDE.md`, root `AGENTS.md`, user shell config).
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
- global / user 환경 mutation (`~/.claude/`, root `CLAUDE.md`, root `AGENTS.md`, user shell config, user git config).
- daemon, watcher, scheduler, hook installer, background process 의 도입.
- `BF_STATE.json` 등 별도 state machine 파일의 도입.
- automatic commit / push / publish / merge / release.
- legacy `ai-harness` 의 path handling 재활용.
- GJMNet 접근 또는 GJMNet adoption.
- `docs/backlog/review.md` 의 candidate 항목 (review 2-pass / file-backed request input 등) 의 implementation.
- review verdict 를 commit / push / publish / merge / release / 채택의 자동 승인 근거로 사용하는 것.

위 항목 중 어느 것이라도 진행하려면 별도 scoped 승인이 필요하다. 본 criteria 의 한 항목으로 위 행위가 묶이지 않는다.

---

## 7. Source-of-truth 관계

- 본 문서는 clean target smoke test 의 criteria 의 정의이며, 실행 / 채택 / script 변경 어느 것도 자동 승인하지 않는다.
- 본 criteria 가 binding 하는 source-of-truth 는 §Target 과 §1 머리에 열거된 contract 문서들 (`SHARED_GLOBAL_INVOCATION_CONTRACT.md`, `TOOLROOT_PROJECTROOT_AUDIT.md`, `GLOBAL_ADOPTION_DECISION.md`, `GLOBAL_ADOPTION_PROCEDURE.md`, `AI_HARNESS_TOOLSET_SCOPE.md`, `REVIEW_RESULT_CONTRACT.md`, `BRIEF_CONTRACT.md`, `EVIDENCE_CONTRACT.md`) 의 **현재 checked-out source snapshot** 이다. 본 문서는 특정 commit hash 에 binding 하지 않는다 — snapshot HEAD 의 권한은 git history 에 있고, 개별 smoke 실행의 execution HEAD 는 §4 항목 4 에 따라 per-run evidence 에 기록된다. 후속 commit 으로 contract 가 변경되면 본 criteria 의 영향 범위를 별도 라운드에서 재평가한다.
- 본 문서가 §1 의 source-of-truth 문서들과 상충하면 위 문서들의 보수적 해석을 우선한다.
- 본 문서는 review verdict (`yes` / `no` / `yes with risk`) 를 commit / push / publish / merge / release / adoption 의 자동 승인으로 해석하지 않는다는 contract 를 그대로 유지한다.
