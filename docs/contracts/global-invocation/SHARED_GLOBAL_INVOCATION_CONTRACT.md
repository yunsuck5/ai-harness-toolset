# Shared / Global Invocation Contract

> **현행 status routing.** 본 문서는 install/update/global-adoption 의 design/model/record source 다. **current 상태 / completed-ledger / deferred** 의 authoritative 자리는 `docs/systems/install-update/STATUS.md` + `docs/systems/install-update/DEFERRED.md` 다 (전체 routing 진입점: `docs/current/REPO_READING_GUIDE.md`; roadmap index: `docs/roadmap/INDEX.md`). 본 문서 본문과 system STATUS 가 충돌하면 current 판단은 STATUS 를 따른다.

본 문서는 `ai-harness-toolset` 의 shared / global mode invocation contract 의 **design** 을 기록한다. **design 의 기록이며, implementation 승인이 아니다.**

본 문서가 존재한다는 사실만으로 어떤 script / config / template / snippet 의 수정, ToolRoot discovery 채널의 자동 도입, env var 의 활성화, snippet body 재작성, claude-skill SKILL.md 의 변경, shared / global mode 의 actual implementation 이 자동 승인되지 않는다. 후속 작업은 분할 단위로 별도 scoped 승인을 거친다.

본 문서는 다음 source-of-truth 들과 충돌하지 않는다.

- 운영 계층 결정: `docs/decisions/GLOBAL_ADOPTION_DECISION.md`
- post-MVP 결정 기록: `docs/decisions/POST_MVP_PLAN.md`
- path handling audit: preserved in git history (its decisions are carried in this contract)
- Claude skill global 절차: `docs/user_guide/GLOBAL_ADOPTION_PROCEDURE.md`
- global install / update 운영 모델: `docs/systems/install-update/GLOBAL_INSTALL_UPDATE_MODEL.md`
- subsystem scope: `docs/project/AI_HARNESS_TOOLSET_SCOPE.md`
- review record 계약: `docs/contracts/review/REVIEW_RESULT_CONTRACT.md`

위 문서와 본 문서가 상충하면 위 문서들의 보수적 해석을 우선한다.

> **Review-cycle wording supersede note (3rd reconciliation, 문서 전체 적용).** 본 design doc 의 §2 inputs, §5 channel chain example, §6 implementation split, §8 D7 untracked-detection branch, §10 verification scenarios 의 wording 은 `scripts/review-cycle.ps1` 와 그 sidecar artifact (`meta.json`, `result.json`, `<run-id>` flat layout, `log/review-targets/`, `log/review-requests/`, `-TargetFiles` / `-TargetFilesPath` / `-ReviewRequestPath` parameter contracts) 을 기준으로 작성된 design 시점의 record 다. 그 design 위에 이뤄진 implementation 은 canonical task/pass topology 채택 (POST_MVP_PLAN.md §10 Completed `c81fe45`) 으로 갱신되었으며, 현행 normal operator path 는 두 단계 entry (`scripts/review-prepare.ps1 -ReviewTaskId <id> -Perspective <viewpoint> [-Pass <pass-NN>]` → `scripts/review-run.ps1 -ReviewTaskId <id> -Perspective <viewpoint> -Pass <pass-NN>`; `-Perspective` required) 와 canonical record `<ProjectRoot>/log/review/<review-task-id>/<perspective>/pass-NN/{input.md, result.md}` 두 파일이다 (strict C1 three-level; 이전 two-level 은 legacy manual-readable only). `scripts/review-cycle.ps1`, `meta.json`, `result.json`, `target-files.list`, `<run-id>` flat layout, `log/review-targets/`, `log/review-requests/`, `-TargetFiles` / `-TargetFilesPath` / `-ReviewRequestPath` 은 normal operator path 가 아니며 git history 의 historical reason 으로 보존된다. D1–D9 결정 자체 (channel chain 정의, mode-neutral snippet body, SKILL.md script root resolution, verifier toolRoot binding, untracked exclusion, self-target enforcement, ProjectRoot CWD advisory 등) 는 본 supersede 와 무관하게 그대로 유효하다 — wording 안의 review-cycle / sidecar artifact 참조만 현행 contract 기준으로 읽는다.

---

## 1. Purpose

earlier ToolRoot/ProjectRoot path-handling audit work (preserved in git history) §8 은 D1–D9 의 결정 없이는 shared / global mode 의 invocation contract 가 확정되지 않는다고 기록했다. 본 문서는 그 D1–D9 에 대한 design 단계의 제안 결정을 기록하고, 그 결정 위에 invocation contract 의 shape 를 정의한다.

본 design 의 책임은 다음으로 한정된다.

- D1–D9 각각에 대한 design-level 결정의 명문화.
- shared / global mode 가 어떻게 invoke 되는지 contract level 의 정의 (parameter shape, discovery 순서, fail-fast 의미, mis-diagnosis 예방).
- 현재 project-local copy mode 와의 backward compatibility 경계의 명문화.
- implementation 의 분할 단위와 그 단위별 scoped 승인 경계의 명문화.

본 design 의 책임이 **아닌** 항목.

- 실제 `scripts/`, `config/`, `templates/`, `snippets/` 의 수정. 본 문서는 어떤 source file 도 수정하지 않는다.
- 글로벌 instruction file (Claude `%USERPROFILE%\.claude\CLAUDE.md`, Codex `%USERPROFILE%\.codex\AGENTS.md` 또는 `%CODEX_HOME%\AGENTS.md`, Codex user-global `AGENTS.override.md`, project-root `CLAUDE.md` / `AGENTS.md`) 의 변경. `%USERPROFILE%\.claude\AGENTS.md` 는 valid destination 이 아니며 어느 scope 에서도 본 design 으로 생성되지 않는다. path / marker 정책은 `docs/decisions/GLOBAL_ADOPTION_DECISION.md` §6 이 source-of-truth 다.
- claude-skill SKILL.md 의 실제 수정.
- 새 env var 의 실제 활성화.
- shared / global mode 의 actual implementation.
- clean target smoke test 의 실행.
- legacy ai-harness 의 path handling 재활용.

---

## 2. Inputs

본 design 은 다음을 input 으로 사용한다.

- the earlier path-handling audit (preserved in git history) §6 의 gap G1–G10.
- 그 earlier audit (git history) §7 의 blocker B1–B5.
- 그 earlier audit (git history) §8 의 required decisions D1–D9.
- `docs/decisions/GLOBAL_ADOPTION_DECISION.md` §1 의 layer decision, §4 의 adoption direction, §6 의 marker policy, §7 의 explicit-trigger discipline, §8 의 ToolRoot / ProjectRoot conceptual split, §10 의 non-goals.
- `docs/user_guide/GLOBAL_ADOPTION_PROCEDURE.md` §4–§7 의 Claude skill global / update / removal 절차.
- `scripts/lib/path.ps1` 의 현재 path 모델 (read-only inspection).
- 본 audit 가 design 시점에 식별한 lifecycle script 들의 `-ProjectRoot` / `-ToolRoot` 사용 (`scripts/review-cycle.ps1` — **removed-legacy**, 현행 review entry 는 `review-prepare` / `review-run` / `review-verify`, 상단 Review-cycle wording supersede note 참조; `scripts/review-prepare.ps1`, `scripts/review-run.ps1`, `scripts/review-verify.ps1`, `scripts/brief-init.ps1`, `scripts/brief-check.ps1`).

본 design 은 위 input 의 사실을 변경하지 않는다.

---

## 3. Layer model recap

본 design 은 `docs/decisions/GLOBAL_ADOPTION_DECISION.md` §8 의 path model 을 그대로 사용한다.

- `ToolRoot` — source-managed file (`scripts/`, `templates/`, `config/`, `snippets/`) 의 위치.
- `ProjectRoot` — 적용 대상 project repo 의 root.
- `LogRoot` — `<ProjectRoot>/log`.
- `BriefRoot` — `<ProjectRoot>/log/brief`. Under the **3rd reconciliation (현행)** of the BRIEF contract this is also the canonical Brief location per `docs/contracts/brief/BRIEF_CONTRACT.md` — `<ProjectRoot>/log/brief/BRIEF.md` is the project-local, operator-local, source-control-excluded runtime Brief artifact (gitignored under `log/`). Three reconciliations applied to this name historically: (1) 1st — canonical at `<ProjectRoot>/log/brief/BRIEF.md`, root `brief/` forbidden; (2) 2nd (superseded) — canonical at `<ProjectRoot>/brief/BRIEF.md`, `<ProjectRoot>/log/brief/BRIEF.md` reduced to a not-canonical seed destination; (3) 3rd (현행) — canonical returned to `<ProjectRoot>/log/brief/BRIEF.md`, root `<ProjectRoot>/brief/` rejected, user-home operator-local runtime root rejected, target persistent footprint = `<ProjectRoot>/log/` only. The path-resolution role of `BriefRoot` itself does not change across the three reconciliations — only the canonical-claim framing did. See `docs/contracts/brief/BRIEF_CONTRACT.md`, `docs/decisions/DECISIONS.md`, `docs/decisions/POST_MVP_PLAN.md` §3 for canonical wording.
- `ConfigRoot` — `<ToolRoot>/config`.
- `TemplateRoot` — `<ToolRoot>/templates`.
- `ScriptRoot` — `<ToolRoot>/scripts`.

세 layout 의 framing 은 그 earlier audit (git history) §2 와 동일하다.

- **Project-local copy mode** — `ToolRoot == <ProjectRoot>/.ai-harness`. legacy / transitional.
- **Shared / global mode** — `ToolRoot` 가 ProjectRoot 와 독립적인 경로. preferred direction. as-built 의 default 연결 방식은 D1 channel 3 (global stable install) 이다.
- **Self-target / dogfooding mode** — `ToolRoot == ProjectRoot` (source repo 자체).

---

## 4. Decisions on D1–D9

본 절은 각 결정 항목에 대해 design-level 의 proposed decision 과 그 rationale 을 기록한다. 본 결정은 본 문서의 존재만으로 implementation 을 자동 승인하지 않는다. implementation 은 §6 의 분할 단위마다 별도 scoped 승인이 필요하다.

### D1 — ToolRoot discovery 채널

**Decision (as-built — Batch 1 구현 반영).** 명시 우선의 6-channel priority chain 을 채택한다. 본 절은 design 단계의 제안이 아니라, Batch 1 (`commit f37c91c` — `Add stable global ToolRoot resolution channel`) 에서 실제 구현되어 push 된 `scripts/lib/path.ps1` 의 `Get-ToolRoot` 동작을 그대로 기록한다.

1. **channel 1 — CLI parameter `-ToolRoot <path>`** (lifecycle script 의 직접 invocation). 최우선. 디렉터리가 존재하지 않으면 throw.
2. **channel 2 — env var `AI_HARNESS_TOOL_ROOT`** (override / debug / development validation 용). 디렉터리가 존재하지 않으면 throw.
3. **channel 3 — global stable install `%USERPROFILE%\.claude\ai-harness-toolset\current`.** shared / global mode 의 default 연결 방식. 디렉터리가 **부재** 하면 다음 channel 로 skip 한다. 디렉터리는 존재하지만 **payload 가 불완전** 하면 (entrypoint `scripts/review-cycle.ps1` 부재) fail-fast throw 한다.
4. **channel 4 — dogfooding detection** (D3 의 multi-marker 가 ProjectRoot 에서 모두 발견된 경우, `ToolRoot = ProjectRoot`). source repo 운영자 전용.
5. **channel 5 — legacy `<ProjectRoot>/.ai-harness`** (해당 디렉터리가 실제 존재할 때만; project-local copy mode 의 backward compat).
6. **channel 6 — 위 어느 것도 충족되지 않으면** 명시 error 후 exit non-zero. error message 는 시도된 channel 의 목록과 각 channel 이 왜 활성화되지 않았는지를 포함한다.

**Rationale.** 명시 > env override > stable default > implicit fallback. channel 3 (global stable install) 이 shared / global mode 의 **기본 연결 방식** 이다 — 사용자가 매 invocation 마다 `-ToolRoot` 를 넘기거나 env var 를 set 할 필요 없이, `%USERPROFILE%\.claude\ai-harness-toolset\current` 에 materialize 된 payload 가 standing default 로 동작한다. `AI_HARNESS_TOOL_ROOT` (channel 2) 는 그 default 를 가리는 **override** 이며, 평소에는 unset 으로 두고 디버그 / 개발 repo 검증 시에만 process-scope 로 set 하는 용도다 — User / Machine scope 에 고정 설정하면 channel 2 가 항상 channel 3 을 가려 stable default 모델 자체가 무력화된다. user-level config 파일 (예: `~/.ai-harness-toolset/config.json`) 은 채택하지 않는다 — 새 state 파일을 도입하지 않는 운영 원칙과 정합한다. snippet body 에 ToolRoot 절대경로를 기록하는 case 도 채택하지 않는다 — snippet 은 cross-machine portable 해야 하며, machine-specific 절대경로를 적재하면 다른 운영자에게 깨지기 때문.

channel 3 의 absent-skip / present-but-incomplete-fail-fast 분기 의도: stable install 이 아직 materialize 되지 않은 환경에서는 dogfooding / legacy fallback 이 그대로 동작해야 하므로 absent 는 skip 한다. 반대로 디렉터리는 있는데 payload 가 깨진 경우는 운영자 오류이므로 silent skip 하지 않고 fail-fast 하여 진단성을 확보한다.

본 결정은 channel 의 도입이지, env var 의 자동 활성화나 user shell config 변경이 아니다. channel 3 의 실제 global materialization 은 본 문서 범위 밖이며 별도 scoped 작업이다 (`docs/systems/install-update/GLOBAL_INSTALL_UPDATE_MODEL.md`).

> **Design history note.** 본 문서의 초기 design 은 4-channel chain (`-ToolRoot` → env → dogfooding → legacy → fail) 이었고 global stable install channel 이 없었다. channel 3 (global stable install) 은 global stable ToolRoot 모델 결정에 따라 Batch 1 구현 단계에서 추가되었고, 본 D1 은 그 as-built 결과로 rewrite 되었다 (R1 decision). 이전 4-channel 서술은 git history 가 권한이다.

### D2 — `Resolve-CycleScript` / `Resolve-RunScript` fallback 정책

**Decision.** 후보 (c) — fallback 시 명시적 warning 출력 후 진행. 단, ToolRoot 가 explicit source (CLI param / env var / global stable install) 로 결정된 경우에는 fallback 없이 throw.

구체적으로 다음 분기를 따른다.

- ToolRoot 가 D1 의 channel 1 / channel 2 / channel 3 으로 결정된 경우 (explicit — `-ToolRoot` param, `AI_HARNESS_TOOL_ROOT` env var, global stable install).
  - `<ToolRoot>/<RelativePath>` 가 없으면 throw. `$PSScriptRoot` fallback 을 사용하지 않는다.
  - throw message 는 ToolRoot 경로, missing relative path, 그리고 explicit source 세 종류 (`-ToolRoot` / `AI_HARNESS_TOOL_ROOT` / global stable install) 를 모두 포함한다.
- ToolRoot 가 channel 4 (dogfooding) 또는 channel 5 (legacy `.ai-harness/`) 로 결정된 경우 (implicit).
  - `<ToolRoot>/<RelativePath>` 가 있으면 그대로 사용.
  - 없으면 `$PSScriptRoot` 의 동일 leaf 파일로 fallback. fallback 발동 시 stderr 또는 informational host line 으로 `WARN component script resolved via $PSScriptRoot fallback (ToolRoot=<...>, missing=<...>)` 를 명시적으로 출력한다.

**Rationale.** audit Gap G3 의 narrowed risk (mis-diagnosis 품질) 를 직접 다룬다. explicit ToolRoot 에 대한 fail-fast 는 misconfiguration 의 진단 메시지가 root cause 를 가리키게 한다. global stable install (channel 3) 은 payload 무결성이 보장되어야 하는 default 연결 경로이므로 explicit 로 분류되어 동일하게 fail-fast 한다. implicit ToolRoot (dogfooding / legacy) 에서는 fallback 이 운영적으로 유용하므로 유지하되, warning 으로 silent 성을 제거한다.

### D3 — source repo detection 강화

**Decision.** 후보 (b) — 다중 marker. `Test-IsSourceRepoRoot` 는 다음 모두가 ProjectRoot 에 존재할 때에만 true 를 반환한다.

- `scripts/verify-ps1.ps1`
- `templates/review-input.md`
- `config/reviewer.json`

세 marker 중 하나라도 빠지면 false. 명시 `-AllowDogfood` 같은 추가 flag 는 도입하지 않는다 (운영 단순성).

**Rationale.** 단일 marker (`scripts/verify-ps1.ps1`) 의 false positive 가능성을 낮춘다. 세 marker 의 동시 존재는 target repo 에서 우연히 발생하기 어렵다 (특히 `templates/review-input.md` 의 정확한 file shape 이 다른 repo 와 충돌할 가능성은 매우 낮다). 향후 source repo 에 새 marker 가 추가되면 그 시점에 본 decision 을 한 번 더 갱신한다.

### D4 — snippet body rewrite scope

**Decision.** 후보 (a) — mode-neutral rewrite. `snippets/CLAUDE_SNIPPET.md` 와 `snippets/AGENTS_SNIPPET.md` 의 marker block 안 본문을 다음 framing 으로 재작성한다.

- shared / global mode 가 preferred direction 임을 명시.
- project-local copy mode 는 transitional / legacy 로 언급하되, 폐기되었다고 단정하지 않는다.
- self-target / dogfooding mode 는 source repo 운영자만 사용하는 경로로 언급.
- 각 mode 의 path layout 을 짧게 정리 (`<ToolRoot>` / `<ProjectRoot>` 표기 사용).
- 사용자가 자기 환경에서 invocation channel 을 어떻게 결정하는지는 본 design 문서 (`docs/contracts/global-invocation/SHARED_GLOBAL_INVOCATION_CONTRACT.md`) 와 `docs/user_guide/GLOBAL_ADOPTION_PROCEDURE.md` 를 참조하도록 안내.

본 rewrite 는 marker block 외부에는 영향을 주지 않는다 (marker 정책 §6 of `GLOBAL_ADOPTION_DECISION.md` 와 정합).

**Rationale.** Batch A 의 `yes with risk` 항목 (snippet body 가 `.ai-harness/` copy-only 전제를 유지) 의 해소 경로다. 본문을 별도 보조 문서로 분리하는 후보 (c) 는 운영자 입장에서 "snippet 만 보면 모른다" 의 마찰이 그대로 남으므로 채택하지 않는다. shared-global 우선 / project-local 보조의 후보 (b) 는 backward compat 메시지가 약해질 수 있어 채택하지 않는다.

본 결정은 design 단계의 합의이며, 실제 snippet 본문 수정은 별도 scoped batch 에서 수행한다 (§6 step 3).

### D5 — claude-skill SKILL.md script root branching

**Decision.** 후보 (a) — 새 mode 를 step 1 에 추가. 검사 순서는 D1 의 6-channel chain 과 정합하며 다음과 같다.

1. `-ToolRoot` 가 명시되면 그 경로를 ToolRoot 로 사용한다 (channel 1). SKILL.md 는 사용자에게 raw arg 를 묻지 않으므로 이 경로는 보통 활성화되지 않는다.
2. env var `AI_HARNESS_TOOL_ROOT` 가 set 되어 있고 그 값이 존재하는 디렉터리면 그 경로를 ToolRoot 로 사용한다 (channel 2 — override / debug / development validation). set 되어 있으나 디렉터리가 존재하지 않으면 throw 하며 다음 channel 로 fall-through 하지 않는다.
3. global stable install `%USERPROFILE%\.claude\ai-harness-toolset\current` 가 존재하고 payload 가 완전하면 그 경로를 ToolRoot 로 사용한다 (channel 3 — shared / global mode 의 default 연결 방식). 디렉터리는 있으나 payload 가 불완전하면 fail-fast.
4. 그 외에는 ProjectRoot 가 D3 의 multi-marker 모두를 만족하면 ProjectRoot 를 ToolRoot 로 사용한다 (channel 4 — dogfooding mode).
5. 그 외에는 `<ProjectRoot>/.ai-harness/` 디렉터리가 존재하면 그 디렉터리를 ToolRoot 로 사용한다 (channel 5 — project-local copy mode, legacy).
6. 위 어느 것도 충족되지 않으면 사용자에게 toolset payload 가 적용되지 않았다고 알리고 중단한다 (channel 6). skill 은 자동 install / copy 를 시도하지 않는다.

**Rationale.** D1 / D3 의 결정과 정합한다. SKILL.md 는 사용자에게 raw PowerShell args 를 묻지 않는다는 기존 contract 를 유지하며, ToolRoot 결정만 추가로 명시한다. 사용자 prompt 로 매번 ToolRoot 를 묻는 후보 (b) 는 마찰이 크므로 채택하지 않는다.

본 결정은 design 단계의 합의이며, 실제 SKILL.md 본문 수정은 Batch 3 에서 수행되었다 (§6 step 4). `snippets/claude-skills/ai-harness-review/SKILL.md` 의 step 1 은 Batch 3 에서 위 6-channel 모델로 정합화되었다.

### D6 — ToolRoot binding in `review-verify`

**Decision.** `review-verify.ps1` 에 `toolRoot` 일치 검증을 추가하되, ToolRoot 의 runtime 재현을 위해 verifier 의 parameter / call-site contract 를 함께 확장한다.

Parameter contract.

- `scripts/review-verify.ps1` 가 새 optional parameter `-ToolRoot <path>` 를 받는다.
- runtime 의 `Get-ToolRoot` 는 D1 의 priority chain 을 그대로 사용하되, verifier 안에서는 `-ToolRoot` 인자가 첫 번째 channel (channel 1) 의 입력이다. 즉, 호출자가 `-ToolRoot` 를 명시하면 그 값으로 channel 1 이 결정되고, 명시하지 않으면 channel 2 (env var) → channel 3 (global stable install) → channel 4 (dogfooding) → channel 5 (legacy `.ai-harness/`) 순으로 fallback 한다.

Call-site contract.

- `scripts/review-cycle.ps1` 와 `scripts/review-run.ps1` 가 verifier 를 호출할 때, 자신이 prepare/run 단계에서 resolve 한 ToolRoot 값을 `-ToolRoot $tool` 로 verifier 에 forward 한다. 본 forward 는 default 와 `-RequireResult` 두 호출 모두에 적용된다.
- 이로써 D1 channel 1 (explicit `-ToolRoot`) 로 prepare/run 된 packet 이 동일 invocation 안에서 verify 될 때, verifier 가 동일 ToolRoot context 를 재현한다. channel 2 (env var), 3 (global stable install), 4 (dogfooding), 5 (legacy) 로 resolve 된 ToolRoot 도 동일하게 forward 된다.
- 사용자가 packet 생성 이후 별도 invocation 으로 `review-verify.ps1` 만 직접 실행하는 경우, `-ToolRoot` 를 명시하지 않으면 verifier 안에서 channel 2/3/4/5 가 그대로 동작한다. meta.json 의 `toolRoot` 와 runtime resolution 이 mismatch 면 FAIL.

검증 동작.

- meta.json 의 `toolRoot` 와 runtime 에서 결정된 ToolRoot 를 normalize 한 뒤 case-insensitive ordinal 비교.
- mismatch 면 FAIL.
- meta.json 에 `toolRoot` 가 없으면 FAIL (이미 review-prepare 가 채워 넣고 있으므로 기존 packet 도 호환된다).

**Rationale.** audit Gap G8 가 식별한 binding gap 을 닫는다. 단순히 verifier 안에서 `Get-ToolRoot` 만 재호출하면 D1 channel 1 (explicit `-ToolRoot`) 로 만든 packet 이 verifier 입장에서 channel 2/3/4/5 로 fallback 하여 false-fail 할 수 있다. 새 `-ToolRoot` parameter 와 cycle/run 단계의 forward 는 그 false-fail 을 차단한다.

backward compat 영향. 기존 source repo 에서 만든 review packet 은 `toolRoot` 가 이미 meta.json 에 기록되어 있으므로 본 변경으로 retroactive 한 FAIL 이 발생하지 않는다 (`scripts/review-prepare.ps1:208` 의 `toolRoot = $tool` 라인 참조). cycle/run 단계의 forward 도 기존 호출 site 의 행위를 보존한다 (channel 2/3/4/5 가 동일 ToolRoot 로 resolve 되는 환경에서는 forward 여부와 무관하게 mismatch 가 발생하지 않는다). 단, 본 결정의 implementation 단계에서 기존 sample packet 의 회귀 test 를 한 번 더 확인한다.

### D7 — untracked exclusion policy

**Decision.** `review-cycle.ps1` 의 untracked detection 에 `.ai-harness/` 도 추가 제외 대상으로 포함한다. `brief/` 는 제외하지 않는다. (D7 의 `brief/` 관련 rationale 의 변천사는 아래 **Superseded** note 참조. **D7 의 동작 결정 자체는 그대로 유효하다.**)

매칭 의미는 **exact-or-strict-child** 다. directory name 과 일치하거나 그 directory 의 child path 만 제외하며, sibling path (`log-old/`, `.ai-harness-backup/` 등) 는 제외 대상이 아니다.

- `log` exclusion (현재 동작 유지).
  - `$rest -eq 'log'` (exact)
  - `$rest.StartsWith('log/')` (strict child, forward slash)
  - `$rest.StartsWith('log\')` (strict child, back slash)
- `.ai-harness` exclusion (신규).
  - `$rest -eq '.ai-harness'` (exact)
  - `$rest.StartsWith('.ai-harness/')` (strict child, forward slash)
  - `$rest.StartsWith('.ai-harness\')` (strict child, back slash)
- 그 외 untracked 는 fail 동작 유지.
- 명시적으로 제외 대상이 **아닌** 예: `log-old`, `log_archive/`, `.ai-harness-backup`, `.ai-harness.zip`. 이들은 sibling path 로 간주되어 현재처럼 untracked fail 을 유지한다.

`brief/` 는 BRIEF 가 의도적으로 tracked 인 source-of-truth 이므로 제외하지 않는다. BRIEF artifact 가 untracked 상태로 존재한다는 사실 자체가 운영 이슈 (commit 되지 않은 BRIEF) 이므로 그대로 fail 신호를 유지한다. (**이 문단은 historical rationale 이다** — 아래 **Superseded** note 의 three-step reconciliation 참조. 현행 기준 (3차 reconciliation): canonical Brief 는 `<ProjectRoot>/log/brief/BRIEF.md` 이며 root `<ProjectRoot>/brief/` 는 rejected. canonical Brief 가 `log/` 아래 있으므로 `log/` exclusion 으로 이미 untracked-fail 에서 자연 제외되고, root `brief/` 자체가 만들어지지 않는다.)

**Rationale.** shared / global mode 전환기에는 target 에 `.ai-harness/` 가 untracked 로 잠시 남을 수 있다 (legacy copy 가 제거되기 전). 본 exclusion 은 그 전환기의 마찰을 줄인다. exact-or-strict-child 매칭은 prefix-only 매칭이 sibling path 까지 widening 하는 ambiguity 를 차단한다. BRIEF 는 정책적으로 tracked 이어야 하므로 동일 exclusion 을 적용하지 않는다.

> **Superseded — D7 rationale only (three-step reconciliation).** 위 D7 의 "`brief/` 는 BRIEF 가
> 의도적으로 tracked 인 source-of-truth 이므로 제외하지 않는다" 는 rationale 은 세 단계의 reconciliation 을
> 거쳤다. (1) 1차 BRIEF posture reconciliation 에서 canonical 을 `<ProjectRoot>/log/brief/BRIEF.md` 로 옮기고
> root `brief/` 를 forbidden 으로 둔 framing 이 채택되었다. (2) 그 framing 이 정정되어 target repo product canonical Brief 를
> `<ProjectRoot>/brief/BRIEF.md` 로 두고 `<ProjectRoot>/log/brief/BRIEF.md` 를 not-canonical 한 seed destination
> 으로 분류한 framing 이 채택되었다. **(3) 3차 reconciliation (현행 기준):** 2차 framing 도 정정되어
> canonical Brief 는 다시 `<ProjectRoot>/log/brief/BRIEF.md` — project-local, operator-local,
> source-control-excluded runtime artifact (gitignored under `log/`) — 이며 **root `<ProjectRoot>/brief/` 는
> rejected**, user-home operator-local runtime root 도 rejected, target persistent footprint = `<ProjectRoot>/log/` only 다.
> **D7 의 동작 결정 자체는 세 단계의 변천에도 그대로 유효하다**: `review-cycle.ps1` 의 untracked detection 은
> `log/` 를 이미 제외하므로 canonical Brief (`<ProjectRoot>/log/brief/BRIEF.md`) 가 자연히 제외되고, root
> `<ProjectRoot>/brief/` 는 어차피 만들어지지 않으므로 untracked-fail 에 걸릴 수 없다. 따라서
> `review-cycle.ps1` 변경은 불필요하다. canonical source-of-truth 는 `docs/contracts/brief/BRIEF_CONTRACT.md` 다.

### D8 — self-target enforcement

**Decision.** `scripts/verify-ps1.ps1` 또는 별도의 검증 helper 가 다음 invariant 를 enforce 한다.

- source repo 에서 git-tracked file 이 `log/` 아래에 존재해서는 안 된다.

violation 발견 시 비-zero exit. message 는 위반 file 의 list 를 포함한다.

본 enforcement 는 commit-time discipline 으로 운영되며, daemon / watcher / hook 자동 등록은 도입하지 않는다 (`docs/decisions/POST_MVP_PLAN.md` §5 의 BF Level 3 forbidden 항목과 정합).

**Rationale.** audit Gap G10 의 자동화 후보. `.gitignore` 의 `log/` 패턴이 source-managed file 을 silent 하게 삼키는 risk 를 commit 전에 잡는다. 운영 규약을 tooling 이 보조하는 형태이며, 사용자 결정을 대신하지 않는다.

### D9 — ProjectRoot CWD default

**Decision.** CWD default 를 유지하되, 다음 advisory 검증을 추가한다.

- `-ProjectRoot` 가 비어 있고 CWD 가 git repo root 가 아닌 경우 (i.e., `<CWD>/.git/` 이 존재하지 않는 경우), informational warning 을 출력한다.
- warning 만 출력하고 동작은 그대로 진행한다 (호환성 유지).
- 명시적으로 fail 시키지는 않는다.

**Rationale.** breaking change 를 피하면서 mis-invocation 의 signal 을 추가한다. `.git/` 의 부재만으로 fail 시키면 git 외부의 환경 (예: detached export, archive) 에서 본 toolset 을 쓰는 case 가 깨질 수 있다. warning 으로 충분한 신호를 준다.

본 결정은 추후 사용자 피드백에 따라 strict mode (fail) 로 격상될 수 있다. 현 단계에서는 advisory 만.

---

## 5. Invocation contract (formalized)

본 절은 §4 의 결정을 바탕으로 한 invocation contract 의 design-level 명세다. 실제 syntax 와 error message 의 final wording 은 implementation 단계에서 확정된다.

### 5.1 ToolRoot resolution

`Get-ToolRoot` 의 resolution 순서는 D1 의 priority chain 을 따른다.

```
Get-ToolRoot(-ToolRoot $p1, -ProjectRoot $project, -StableToolRoot $stable?)
  # channel 1 — explicit -ToolRoot parameter
  if $p1 is non-empty:
    if -not Test-Path $p1 -PathType Container: throw
    return GetFullPath($p1)                                   # channel 1

  # channel 2 — AI_HARNESS_TOOL_ROOT env var (override / debug / development validation)
  if $env:AI_HARNESS_TOOL_ROOT is non-empty:
    if -not Test-Path $env:AI_HARNESS_TOOL_ROOT -PathType Container: throw
    return GetFullPath($env:AI_HARNESS_TOOL_ROOT)             # channel 2

  # channel 3 — global stable install (default shared/global mechanism).
  #   $stable defaults to %USERPROFILE%\.claude\ai-harness-toolset\current.
  #   The -StableToolRoot parameter is a test-isolation override; production
  #   callers leave it empty.
  if $stable is empty: $stable = Get-StableToolRootCandidate()
  if $stable is non-empty:
    if Test-Path $stable -PathType Container:
      # present but incomplete payload (entrypoint scripts/review-cycle.ps1 missing) -> fail fast
      if -not Test-IsValidToolRootPayload($stable): throw
      return GetFullPath($stable)                              # channel 3
    # absent: fall through to channel 4

  # channel 4 — dogfooding source repo multi-marker (D3)
  if Test-IsSourceRepoRoot($project):
    return $project                                            # channel 4 (dogfooding)

  # channel 5 — legacy <ProjectRoot>/.ai-harness
  $legacy = Join-Path $project '.ai-harness'
  if Test-Path $legacy -PathType Container:
    return GetFullPath($legacy)                                # channel 5 (legacy)

  throw with channel-trace message                             # channel 6
```

channel 6 의 throw message 는 다음을 포함한다.

- 시도된 channel 의 list.
- 각 channel 이 활성화되지 않은 이유 (param empty / env empty / stable install absent / markers missing / legacy dir absent).
- 운영자가 다음에 무엇을 하면 되는지 (예: "set AI_HARNESS_TOOL_ROOT or pass -ToolRoot").

### 5.2 Component script resolution

`Resolve-CycleScript(-Tool $t, -RelativePath $r, -LocalDir $local, -ToolRootSource <explicit|implicit>)` 는 D2 결정을 따른다.

```
$candidate = Join-Path $t $r
if Test-Path $candidate -PathType Leaf:
  return $candidate

if $ToolRootSource == 'explicit':
  throw "component script not found under explicit ToolRoot: <t>, missing=<r>"

$localCandidate = Join-Path $local (Split-Path -Leaf $r)
if Test-Path $localCandidate -PathType Leaf:
  Write-Host "WARN component script resolved via $PSScriptRoot fallback. ToolRoot=<t>, missing=<r>, fallback=<localCandidate>"
  return $localCandidate

throw "component script not found: <r>"
```

`-ToolRootSource` 는 D1 의 channel 1 / channel 2 / channel 3 (`-ToolRoot` param, `AI_HARNESS_TOOL_ROOT` env var, global stable install) 일 때 `explicit`, channel 4 (dogfooding) 또는 channel 5 (legacy) 일 때 `implicit`. resolution context 를 caller 가 전달한다. as-built 구현에서 `Get-ToolRootSource` 는 `-ToolRoot` 가 비어 있고 env var 도 비어 있어도 global stable install 디렉터리가 존재하면 `explicit` 로 분류한다.

### 5.3 ProjectRoot resolution

D9 에 따라 CWD default 를 유지하되, advisory warning 추가.

```
Get-ProjectRoot(-ProjectRoot $p)
  if $p is empty:
    $p = (Get-Location).ProviderPath
    # .git can be either a directory (standard repo) or a file pointer
    # (git worktree / submodule); both count as valid git evidence.
    if -not (Test-Path (Join-Path $p '.git') -PathType Container)
       and -not (Test-Path (Join-Path $p '.git') -PathType Leaf):
      Write-Host "WARN ProjectRoot resolved to CWD without a .git entry: <p>"
  if -not Test-Path $p -PathType Container: throw
  return GetFullPath($p)
```

### 5.4 review-verify ToolRoot binding

D6 에 따라 `review-verify.ps1` 의 parameter contract, call-site forward, 검증 동작이 다음과 같이 정의된다.

Parameter contract (verifier side).

```
review-verify.ps1
  -RunId <string>          (required, existing)
  -ProjectRoot <path?>     (optional, existing)
  -ToolRoot <path?>        (optional, new)
  -RequireResult           (switch, existing)
```

verifier 내부의 ToolRoot resolution 은 §5.1 의 priority chain 을 따른다. `-ToolRoot` 가 verifier 에 forward 된 경우 channel 1 이 활성화된다.

Call-site forward (cycle / run side).

```
review-cycle.ps1 invokes review-verify.ps1:
  -RunId $RunId
  -ProjectRoot $project
  -ToolRoot $tool          # forwarded from cycle's resolved ToolRoot

review-run.ps1 invokes review-verify.ps1:
  -RunId $RunId
  -ProjectRoot $project
  -ToolRoot $tool          # forwarded from run's resolved ToolRoot

(둘 다 default mode 와 -RequireResult 호출 모두에 적용)
```

Verification body.

```
$metaToolRoot = [string]$meta.toolRoot
if empty: FAIL meta.toolRoot missing

$runtimeTool = Get-ToolRoot(-ToolRoot $ToolRoot, -ProjectRoot $project)   # §5.1 chain

$metaToolFull = GetFullPath($metaToolRoot).TrimEnd(sep)
$runtimeToolFull = GetFullPath($runtimeTool).TrimEnd(sep)
if not equal (case-insensitive ordinal):
  FAIL toolRoot mismatch. meta=<metaToolFull> runtime=<runtimeToolFull>
```

본 검증은 `projectRoot`, `projectLogRoot` 검증과 동일한 절차 / 동일한 FAIL 출력 형식을 따른다.

### 5.5 untracked exclusion

D7 에 따라 `review-cycle.ps1` 의 untracked branch 가 다음과 같이 확장된다. 매칭은 exact-or-strict-child 다 — directory name 과 일치하거나 child path 만 제외, sibling path 는 제외하지 않는다.

```
foreach untracked path $rest:
  # current: exclude log directory (exact or child)
  if $rest -eq 'log' \
     -or $rest.StartsWith('log/') \
     -or $rest.StartsWith('log\'):
    continue

  # new (D7): exclude .ai-harness directory (exact or child)
  if $rest -eq '.ai-harness' \
     -or $rest.StartsWith('.ai-harness/') \
     -or $rest.StartsWith('.ai-harness\'):
    continue

  add to untracked list

# Examples of paths that are NOT excluded (intentionally):
#   'log-old'              # sibling, not the 'log' directory
#   'log_archive/file'     # different directory
#   '.ai-harness-backup'   # sibling, not the '.ai-harness' directory
#   '.ai-harness.zip'      # sibling file with '.ai-harness' prefix
```

### 5.6 self-target enforcement check

D8 에 따라 추가되는 helper 또는 `verify-ps1.ps1` 의 sub-check 는 다음 조건을 만족한다.

- input. 현재 source repo (또는 명시 path) 의 git tracked file list.
- detection. `log/` 아래에 git-tracked file 이 1 개 이상 존재.
- output. violation 발견 시 비-zero exit + violation file list 출력.
- side-effect 없음. 본 check 는 read-only.

본 check 는 hook 으로 자동 등록되지 않는다. 사용자가 commit 전 또는 verify-ps1 routine 에서 명시적으로 호출한다.

### 5.7 snippet body / SKILL.md 의 mode-neutral framing

D4 / D5 의 결과로 본 contract 가 snippet 본문과 SKILL.md 에서 참조되는 형태는 다음과 같다.

- snippet body 의 `## Project layout` 절은 세 mode 를 짧게 enumerate 하고, ToolRoot 를 결정하는 channel chain 의 요약을 한 줄 정도 적는다.
- SKILL.md 의 step 1 은 §4 의 D5 checklist (`-ToolRoot` → env var → global stable install → dogfooding marker → legacy `.ai-harness/` → stop) 를 그대로 사용한다. 본 정합화는 Batch 3 에서 적용되었다.
- 두 곳 모두 본 design 문서 (`docs/contracts/global-invocation/SHARED_GLOBAL_INVOCATION_CONTRACT.md`) 와 `docs/user_guide/GLOBAL_ADOPTION_PROCEDURE.md` 를 참조하도록 명시한다.

snippet body 와 SKILL.md 의 본문 정합화는 §6 의 분할 단위 (step 3, step 4) 로서 Batch 3 에서 수행되었다.

---

## 6. Implementation split

본 절은 본 design 의 실제 implementation 을 분할 단위로 명문화한다. **분할 자체는 자동 승인이 아니다.** 각 step 은 별도 scoped 승인이 필요하며, 각 step 의 산출물은 독립된 commit 으로 보존된다.

> **Batch 실행 현황 note.** step 1 (`Get-ToolRoot`) 과 step 2 (`Resolve-*Script` fallback) 는 Batch 1 (`commit f37c91c` — `Add stable global ToolRoot resolution channel`) 에서 구현·검증·push 되었다. Batch 1 은 그 과정에서 원래 design 의 4-channel chain 에 channel 3 (global stable install) 을 추가했고, 본 문서의 D1 / §5.1 / §5.2 는 그 as-built 결과로 rewrite 되었다 (R1 decision). step 3 (snippet body) 와 step 4 (SKILL.md) 는 Batch 3 에서 구현되었다 — `snippets/CLAUDE_SNIPPET.md` / `snippets/AGENTS_SNIPPET.md` 의 Project layout 과 `snippets/claude-skills/ai-harness-review/SKILL.md` 의 step 1 이 as-built 6-channel 모델로 정합화되었다. materialize 된 `~/.claude/skills/ai-harness-review/SKILL.md` 사본의 재동기화는 `GLOBAL_ADOPTION_PROCEDURE.md` §6 절차로 수행하는 별도 작업이다. 나머지 step (5–8) 의 현황은 본 문서 범위 밖이며 git history 가 권한이다.

1. `scripts/lib/path.ps1` 의 `Get-ToolRoot` 갱신 (D1, D3 의 channel chain 적용).
2. `Resolve-CycleScript` / `Resolve-RunScript` 의 fallback 정책 갱신 (D2).
3. `snippets/CLAUDE_SNIPPET.md` / `snippets/AGENTS_SNIPPET.md` 의 mode-neutral body 재작성 (D4).
4. `snippets/claude-skills/ai-harness-review/SKILL.md` 의 script root 분기 갱신 (D5).
5. `scripts/review-verify.ps1` 의 toolRoot binding 검증 추가 (D6).
6. `scripts/review-cycle.ps1` 의 untracked exclusion 확장 (D7).
7. self-target enforcement check 의 도입 (D8). `verify-ps1.ps1` 또는 별도 helper.
8. `Get-ProjectRoot` 의 CWD advisory 추가 (D9).

각 step 의 size 권고.

- step 1, 2, 5, 6, 8 — branch-heavy helper change. 변경 폭은 작지만 호출부 contract 검증 필요. 본 도구의 branch-heavy 테스트 게이트 (`CLAUDE.md`) 를 따른다 — 성공 경로, 실패 / skip 경로, 호출부 contract 직접 검증 TC 의 3 개 가이드를 적용한다.
- step 3, 4 — 문서성 변경. tests 추가 없이도 review packet 으로 검증 가능.
- step 7 — 신규 helper / sub-check. 단독 commit 으로 처리. tests 의 추가가 필요하다 (성공 / 실패 / dogfooding skip 의 3 경로 최소).

step 간 ordering 권고.

- step 1, 2, 5, 6, 8 은 path / lifecycle 계층의 변경이므로 먼저 처리한다 (implementation 의 lower layer).
- step 3, 4 는 위 layer 가 안정된 뒤 처리한다 (사용자 facing layer).
- step 7 은 step 1 직후 또는 step 8 직후에 처리한다. 다른 step 과 dependency 없음.

각 step 의 acceptance criteria 는 implementation 단계에서 명문화한다. 본 design 은 step 의 scope 만 정의한다.

---

## 7. Backward compatibility

본 절은 본 design 이 기존 운영을 깨지 않도록 명문화한 항목이다.

- D1 channel 5 (legacy `<ProjectRoot>/.ai-harness/`) 의 유지. project-local copy mode 의 사용자는 본 design 적용 후에도 추가 작업 없이 그대로 동작한다.
- D1 channel 3 (global stable install) 의 absent-skip 동작 — `%USERPROFILE%\.claude\ai-harness-toolset\current` 가 아직 materialize 되지 않은 환경에서는 channel 3 이 조용히 skip 되어 channel 4 (dogfooding) / channel 5 (legacy) fallback 이 종전과 동일하게 동작한다. 즉 stable install 도입 전 환경의 기존 운영이 깨지지 않는다.
- D2 의 fallback 분기 — implicit ToolRoot (dogfooding / legacy) 에서는 fallback 이 그대로 동작한다. 사용자가 보는 message 만 추가된다 (warning).
- D3 의 multi-marker — source repo 에 이미 세 marker 가 모두 존재한다 (`scripts/verify-ps1.ps1`, `templates/review-input.md`, `config/reviewer.json`). dogfooding 동작이 깨지지 않는다.
- D6 의 review-verify 검증 — `meta.toolRoot` 는 `scripts/review-prepare.ps1` 가 이미 채워 넣고 있으므로 기존 packet 의 회귀 fail 은 예상되지 않는다. 단, implementation 단계에서 sample packet 한 개를 수동 검증한다.
- D7 의 exclusion — `.ai-harness/` 의 추가 제외는 untracked 가 더 많이 통과한다는 의미일 뿐이고, 기존 통과 패턴이 fail 로 바뀌지는 않는다.
- D9 의 CWD warning — strict fail 이 아니므로 기존 운영이 깨지지 않는다.

design 이 깨는 시나리오 (intentional break).

- D2 의 explicit ToolRoot + missing script. 현재는 `$PSScriptRoot` fallback 으로 silent 하게 진행되던 path 가 throw 로 바뀐다. 단, 이는 mis-diagnosis 를 막기 위한 의도된 변경이며, 정상 운영에서는 해당 경로가 발동하지 않는다.

---

## 8. Open questions

design 단계에서 결정을 내렸지만, implementation / 운영 단계에서 추가 결정이 필요한 항목.

- O1. env var 의 이름. **resolved (as-built).** Batch 1 구현은 env var 이름을 `AI_HARNESS_TOOL_ROOT` 로 확정했고, 본 문서의 D1 / D2 / D5 / §5.1 도 그 이름으로 정합화되었다. 더 이상 implementation 전 미결 항목이 아니다. 향후 다른 이름 (`AI_HARNESS_TOOLSET_ROOT` 등) 으로의 rename 은 별도 scoped design / change 가 필요하며, 본 open question 으로 다루지 않는다.
- O2. D5 의 SKILL.md 분기 우선순위. as-built 6-channel chain 에서 channel 2 (env var) 와 channel 3 (global stable install) 이 모두 channel 4 (dogfooding) 보다 우선한다. 따라서 운영자가 source repo 안에서 dogfooding 으로 작업하려는데 env var 가 set 되어 있거나 global stable install 이 존재하면 dogfooding 이 가려진다. 이 경우 운영자는 env var 를 unset 하거나 `-ToolRoot` 로 source repo 를 명시해야 한다. 이 효과가 실제 운영에서 마찰을 일으키는지 추가 확인이 필요하다.
- O3. D6 의 normalize 정책. case-insensitive ordinal 비교는 Windows / non-Windows 모두에서 OK 인지 implementation 단계에서 한 번 더 확인한다.
- O4. D8 의 check 가 새 helper 인지, `verify-ps1.ps1` 의 sub-check 인지. 본 design 은 둘 중 하나로 두고 implementation 시점에 결정한다.
- O5. D9 의 advisory 가 추후 strict mode 로 격상될지의 기준 (예: 일정 기간 후 default 변경). 본 단계에서는 advisory 만 결정하고, 격상 시점은 미정.

위 open question 들은 본 design 의 핵심 결정 (D1–D9) 를 무효화하지 않는다.

---

## 9. Non-goals

본 design 은 다음을 **포함하지 않는다**. 본 design 의 존재만으로 아래 항목이 승인 / 실행되었다고 해석하지 않는다.

- 실제 `scripts/`, `config/`, `templates/`, `snippets/` 의 수정.
- env var 의 자동 활성화 / user shell config 변경.
- 글로벌 instruction file (Claude `%USERPROFILE%\.claude\CLAUDE.md`, Codex `%USERPROFILE%\.codex\AGENTS.md` 또는 `%CODEX_HOME%\AGENTS.md`, Codex user-global `AGENTS.override.md`, project-root `CLAUDE.md` / `AGENTS.md`) 의 변경. `%USERPROFILE%\.claude\AGENTS.md` 는 valid destination 이 아니다.
- claude-skill SKILL.md 의 실제 수정.
- shared / global mode 의 actual implementation.
- `.gitignore` / `.gitattributes` 의 변경.
- user-level config 파일의 도입.
- daemon / watcher / scheduler / hook 의 자동 등록.
- automatic commit / push / publish / merge / release.
- legacy ai-harness 의 path handling 재활용.
- clean target smoke test 의 실행.

위 항목 중 어느 것이라도 진행하려면 별도 scoped 승인이 필요하다.

---

## 10. Source-of-truth 관계

- 본 문서는 shared / global mode invocation contract 의 design 기록이다.
- D1–D9 의 결정은 본 문서 안에서 명문화되며, the earlier path-handling audit (preserved in git history) §8 의 같은 질문을 닫는다.
- 본 design 이 §1 의 source-of-truth 문서들과 상충하면 위 문서들이 우선한다.
- 본 design 은 review verdict (`yes` / `no` / `yes with risk`) 를 commit / push / publish / merge / release / adoption 의 자동 승인으로 해석하지 않는다는 contract 를 그대로 유지한다.
- §6 의 implementation split 각 step 은 별도 scoped 승인을 필요로 한다. 본 문서가 step 의 implementation 을 자동 승인하지 않는다.
