# Operations Backlog

본 파일은 review subsystem 외 운영 영역 — smoke 운영, long-lived docs hygiene, evidence preservation 등 — 의 open 후보 항목을 기록한다. 본 파일의 어떤 항목도 implementation, scheduling, release 의 자동 승인이 아니다. 본 파일과 다른 contract 문서가 충돌하면 contract 문서가 우선한다 (`./README.md` 참조).

---

## Long-lived docs commit hash hygiene

- **Status**: candidate

### Context

Long-lived criteria docs (예: `docs/roadmap/CLEAN_TARGET_SMOKE_CRITERIA.md`) 및 execution scope proposal 본문에 절대 commit hash 를 하드코딩하면, 후속 commit 이후 stale 한 reference 가 남는다. 본 라운드의 SC5 round 1 → round 2 보정 과정에서 실제로 이 incident 가 발생했다: 초기 execution scope proposal 이 execution pin 으로 `595d35d` (당시 criteria 본문이 historical context 로 인용하던 commit; 이후 별도 doc-hygiene pass 로 본문에서 제거됨) 를 사용했다가, 그 다음 round 에서 `85433e5` 를 execution pin 으로 재지정해야 했고, 최종 round 에서는 본문 hash 를 모두 제거하고 "restored clean HEAD" preconditions (branch == main, HEAD == origin/main, working tree clean) 로 전환했다.

### Candidate direction

long-lived doc 에서 execution / precondition 정의 시 다음 패턴을 따른다.

- 본문에는 절대 commit hash 를 두지 않는다. 대신 "current restored clean HEAD" 또는 "branch == main, HEAD == origin/main, working tree clean" preconditions 로 표현한다.
- 절대 commit hash 는 handoff, manifest, snapshot metadata, evidence report (per-run `SUITE_REPORT.md` 등) 같은 short-lived per-run artifact 에만 기록한다.
- 기존 long-lived doc 에 잔존하는 literal hash references 의 식별과 정리는 별도 doc-hygiene pass 의 대상이다. `docs/roadmap/CLEAN_TARGET_SMOKE_CRITERIA.md` 의 §Target / §1 Terminology / §4 evidence / §7 source-of-truth 절에 잔존하던 `595d35d` 인용은 doc-hygiene pass 1 회를 거쳐 정리되었다 — criteria binding 은 "현재 checked-out source snapshot" 표현으로, 개별 실행의 HEAD 기록 책임은 per-run "execution HEAD" evidence 로 분리되었다 (snapshot HEAD / execution HEAD / evidence-recorded HEAD 의 책임 구분은 criteria §Target / §4 / §7 참조). 다른 long-lived docs 에 남아 있을 수 있는 hash references (예: backlog 본문 자체의 incident anchor, contract docs 의 historical 참조) 의 case-by-case 판정은 추가 라운드의 대상이다.

### Non-goals

- 본 항목은 backlog candidate 다. 즉각 doc-hygiene 변경은 자동 승인되지 않는다.
- hash-hygiene 점검 linter / 자동 검사 tool 도입을 자동 승인하지 않는다.
- contract docs 의 per-doc source-of-truth commit anchoring 은 본 backlog 의 대상이 아니다 (의도된 historical anchor 는 본 항목의 정리 대상이 아님).
- 본 항목 implementation 은 별도 scoped goal 을 거친다.

---

## PowerShell smoke invocation quoting hardening

- **Status**: (W) wrapper-script 채택 / 구현 완료. `scripts/smoke/invoke-review-cycle.ps1` thin wrapper + `tests/invoke-review-cycle-smoke.Tests.ps1` Pester test 가 본 라운드에서 추가되었다. (R) runbook-only / (S) helper-snippet 은 채택하지 않았다 — (W) 가 driver layer 의 결정론적 재현을 제공하므로 운영자가 매 호출마다 quoting 규약을 수동 재현할 필요를 줄이는 (R)/(S) 의 목표를 (W) 가 흡수한다. 본 closeout 은 wrapper 추가 자체에 한정되며 install / update automation 본체 구현, `scripts/review-cycle.ps1` parameter contract 변경, CH3-D 실행, 또는 SC1–SC7 / CH3-A / CH3-B / CH3-C 의 criteria 변경 어느 것도 자동 승인하지 않는다.
- **Classification**: Claude Code local operator → Codex reviewer handoff 경로의 CLI invocation reliability 문제. ChatGPT Web review hand-off / packet packaging 편의 작업 (예: snapshot zip path-preserving 등) 과는 별개의 영역이다. 본 항목은 운영자 머신 위에서 PowerShell 이 lifecycle script 를 호출하는 단계 한 곳을 다룬다.

### (W) wrapper implementation summary

- **Path**: `scripts/smoke/invoke-review-cycle.ps1`. UTF-8 with BOM + CRLF (`verify-ps1.ps1` policy 통과).
- **Test**: `tests/invoke-review-cycle-smoke.Tests.ps1`. Pester 6 tests (parameter passthrough, unbound omission, stderr resilience, exit-0 passthrough, exit-N passthrough, fail-fast on invalid child path). 실제 Codex CLI 미호출 — fake child script + `$TestDrive` fixture 로 wrapper invocation behavior 만 검증.
- **Responsibility (intentionally narrow)**: review-cycle.ps1 의 동일 parameter contract 를 받아 PowerShell parameter splatting (`& $child @args`) 으로 forward + child exit code passthrough. `Start-Process -ArgumentList <array>` 패턴과 `2>&1 | Select-Object` 등의 native-output pipeline wrapper 패턴을 의도적으로 사용하지 않는다 (둘 다 본 backlog 의 incident 분류에 등록된 driver failure 원인).
- **Out of scope (의도적으로 미포함)**: `scripts/review-cycle.ps1` parameter contract 변경, lifecycle script stdout / stderr 의 변형 / 요약 / filtering, retry / fallback / auto-fix 로직, generic PowerShell quoting framework / cross-shell quoting helper, daemon / watcher / scheduler / background automation. wrapper 는 smoke driver invocation use case 전용 stub 이며 lifecycle script 자체의 책임을 흡수하지 않는다.

### Context

SC5 rerun 의 첫 시도 (suite `ahts-smoke-sc5\20260514T024655Z`) 에서, smoke driver 가 `review-cycle.ps1` 를 `Start-Process -ArgumentList <array>` 로 호출하면서 multi-word substitution 값 (`-Context 'Clean target smoke verification of D6 ...'`) 의 quoting 을 PowerShell 5.1 의 array 형태가 자동 보존하지 않아, `'of'` 가 positional argument 로 거부되었다 (`A positional parameter cannot be found that accepts argument 'of'`). parser 단계에서 종료되어 Codex 호출 / run-dir 생성 / fixture mutation 모두 발생하지 않았고, SC7 invariant 는 hold 했다.

본 incident 는 smoke contract failure 가 **아니다** — criteria 의 prescribed invocation 자체는 정상이며, 두 번째 시도 (suite `ahts-smoke-sc5\20260514T024818Z`) 에서 manually-quoted single-string command line 으로 동일 invocation 을 통과시켰다 (verdict `yes`). 그러나 smoke 의 반복적 / 후속 실행에서 driver 의 quoting 규약이 매번 수동으로 재현되어야 한다는 점은 fragility 다.

**추가 incident reference (CH3-B/CH3-C reaffirming round).** 채널 3 review-cycle smoke 의 첫 시도에서 driver 가 `& $cycle ... 2>&1 | Select-Object -Last 40` 패턴으로 native Codex output 을 redirect + pipe 했고, PowerShell 5.1 의 NativeCommandError 변환과 buffered pipeline interaction 으로 Codex 의 첫 stderr 라인 (banner) 직후 pipeline 이 죽어 `result.md` / `result.json` 까지 도달하지 못했다. prepare 까지는 정상 (run-dir + `meta.json` + `input.md` + `target-files.list` 생성됨) 이라 본 분류의 driver failure 표지 (c) "run-dir 부재" 와 정확히 일치하진 않으나, 동일 root cause (driver 가 native command stderr 를 PowerShell pipeline 에서 안전하게 다루지 못함) 로 본 분류에 binding 한다. 두 번째 시도에서 wrapper-free 직접 `& $cycle ...` invocation 으로 동일 호출을 통과시켰다 (review-verify default + `-RequireResult` PASS, verdict `yes`). 본 incident 도 위 SC5 케이스와 동일하게 (R) / (S) / (W) 결정 시 evidence 입력이 된다.

### Failure mode classification

본 항목이 hardening 대상으로 삼는 fragility 는 다음 3 계층 중 **driver failure** 한 가지다. 나머지 두 계층은 별도 정정 경로다.

- **driver failure (본 항목 대상)** — local operator / smoke driver 의 PowerShell invocation 단계에서 argument tokenization / binding 이 깨진다. 결과: Codex 호출 자체가 발생하지 않고, `<ProjectRoot>/log/review/<run-id>/` 가 생성되지 않으며, `meta.json` / `input.md` / `result.md` / `result.json` 어느 것도 만들어지지 않는다. SC7 같은 fixture invariant 는 hold 한다 (작업이 시작 전에 죽었기 때문). 표지 — (a) PowerShell 측 parser / binder error message (`A positional parameter cannot be found that accepts argument 'X'` 등), (b) 동일 호출이 manually-quoted single-string 형태로는 통과, (c) run-dir 부재.
- **smoke contract failure (본 항목 대상 아님)** — `CLEAN_TARGET_SMOKE_CRITERIA.md` 의 prescribed invocation, fixture lifecycle, ToolRoot channel resolution, evidence schema 정의 자체가 잘못이거나 lifecycle script 의 실제 동작과 어긋난 경우. 정정 경로: criteria 또는 lifecycle script 변경 (별도 scoped goal). 표지 — driver 가 정상 호출했음에도 lifecycle script 가 spec 과 다른 동작.
- **Codex review failure (본 항목 대상 아님)** — driver 가 Codex 까지 도달했고 run-dir 가 생성되었으나, downstream review / result / verify 단계 어느 한 곳에서 fail 또는 malformed 인 경우. 정정 경로: input 본문 보정, criteria 보정, reviewer 설정 변경 — 본 항목과 무관. 표지 — (a) `<ProjectRoot>/log/review/<run-id>/` 가 존재하여 driver failure 와 결정적으로 구분되고, (b) 그 안의 `meta.json` / `input.md` / `result.md` / `result.json` 은 **부분적으로만** 존재할 수 있다 (특히 Codex 응답이 `result.md` contract 를 위반하면 `result.md` 는 있으나 `result.json` 이 생성되지 않는 parser-shape failure 도 본 분류의 sub-case 다), (c) 실제 fail 형태는 verdict 가 non-approve, 또는 `result.md` shape 위반으로 `result.json` 미생성, 또는 `review-verify` 의 freshness / binding / hash 검증 fail 중 하나.

위 3 계층은 evidence 측면에서 즉시 구분 가능하다 — driver failure 는 `log/review/<run-id>/` 자체가 없고, 나머지 둘은 run-dir 가 존재한 채 다른 단계에서 fail 한다. 본 항목의 hardening 은 driver failure 분류만 줄이는 것을 책임으로 한다.

### Cross-reference and layer separation

- `docs/backlog/review.md` "Review-cycle file-backed request input" 항목 — 운영자가 `review-cycle.ps1` 의 inline `-Context` / `-ReviewQuestions` / `-Constraints` 인자에 quote-heavy / multilingual 본문을 직접 전달할 때의 fragility 를 review-cycle **내부** input 채널 변경으로 root-cause hardening 한다.
- 본 항목은 한 layer **위** — review-cycle 외부의 호출자 (smoke driver, 운영자 단계의 wrapper) 가 review-cycle 또는 다른 lifecycle script 로 args 를 전달하는 invocation 패턴 자체의 reliability 를 다룬다. file-backed request input 이 채택되어도 (a) driver 가 review-cycle 외 lifecycle script (예: `brief-init`, `log-init`) 를 호출할 때의 quoting fragility, (b) driver 가 `Start-Process` array vs single-string command 중 어느 패턴을 쓰는지의 결정 — 둘 다 자동 해결되지 않는다.
- 두 항목은 동일 root cause (PowerShell quote-discipline) 를 공유하지만 작동 layer 가 다르므로, 한 batch 에 묶어서 구현하지 않는다 (각 항목 Non-goals 참조).

### Decision boundary — (R) runbook-only / (S) helper-snippet / (W) wrapper-script

다음 implementation goal 은 아래 3 후보 중 **정확히 1 개** 만 채택한다. 본 scope 단계에서는 어느 것도 결정하지 않는다.

- **(R) runbook-only** — 1 개 docs 파일 추가 (위치 후보: `docs/runbooks/smoke-invocation.md` — implementation 단계에서 확정). SC 별 prescribed invocation 의 안전 호출 패턴 (single-string command line, manual quote 규약, 강한 단어 / 한국어 본문에 대한 ASCII fallback 권장 등) 을 명문화. 새 .ps1 / 새 helper / 새 test 0. 비용 가장 낮음. trade-off — hardening 강도 가장 약함; 운영자가 매 호출마다 runbook 을 참조해야 하며, runbook 본문이 lifecycle script 변경에 따라 stale 화될 위험.
- **(S) helper-snippet** — 1 개 reference snippet 추가 (위치 후보: `snippets/` 또는 `snippets/smoke-invocation/` 아래; 형식은 markdown sample 또는 비실행 `.ps1` example — implementation 단계에서 결정). 운영자가 SC 별로 copy / paste 하여 placeholder 만 substitute. 비용 중간. trade-off — snippet 은 정식 entry point 가 아니므로 운영자 substitute 단계에서 quoting fragility 가 다시 노출될 수 있다. 형식이 실행 가능한 `.ps1` sample 이 되더라도 정식 lifecycle script 로 분류하지 않는 한 review trigger 정책 (CLAUDE.md MUST) 적용 여부는 implementation goal 에서 명시.
- **(W) wrapper-script** — 1 개 정식 stub `.ps1` 추가 (위치 후보: `scripts/` 또는 별도 `tools/` — implementation 단계에서 결정). 본 stub 이 SC 별 invocation 을 single-string command line 으로 결정론적으로 구성하여 lifecycle script 를 호출. 운영자는 stub 만 호출. 비용 가장 높음. 새 .ps1 1, Pester test 의무, CLAUDE.md MUST 트리거 (codex review 필수). trade-off — hardening 강도 가장 강함; 그 대신 stub 책임은 thin pass-through (single-string 구성 + 호출 + exit code 전달) 한 가지로 한정되어야 하며, `review-cycle.ps1` 등의 parameter contract 변경 권한은 없다.

decision boundary:

- 다음 implementation goal 의 책임이 "운영자가 매번 quoting 을 재발견하지 못해 발생하는 incident 를 줄이는 것" 이면 (R) 또는 (S) 로 충분하다.
- 다음 implementation goal 의 책임이 "smoke 의 반복 / 후속 실행에서 driver 가 결정론적으로 동일 invocation 을 재현하는 것" 이면 (W) 가 후보다.
- (W) 는 새 .ps1 추가에 따른 review / test gate 비용이 발생하므로, (R) / (S) 로 incident 가 충분히 줄지 않는다는 evidence 가 한 차례 더 쌓인 뒤 채택을 검토한다.

### Minimum scope for the next implementation goal

다음 scoped goal 의 boundary:

- (R) / (S) / (W) 중 1 개만 구현. 두 개 이상을 한 batch 에 묶지 않는다.
- (R) 채택 시 — docs 1 개 파일. script / test / runtime 변경 0. 본문은 본 §Failure mode classification 의 driver failure 표지 (a)/(b)/(c) 를 인용하고 안전 호출 패턴을 1 페이지 이내로 명문화.
- (S) 채택 시 — snippet 1 개 entry. script / test / runtime 변경 0 (snippet 이 비실행 sample 인 경우). 책임은 (R) 과 동일하되 copy-paste 가능 형태.
- (W) 채택 시 — 새 .ps1 1 개, 위치 / 이름 implementation 단계 결정. 책임 한정 — single-string command 구성 + lifecycle script 호출 + exit code passthrough. lifecycle script 의 parameter contract 변경 0. Pester test 1 개 이상 (성공 경로 + 대표 실패 경로 + caller contract 직접 검증). codex review MUST 트리거.
- 어느 후보든 review.md "Review-cycle file-backed request input" 항목과 묶지 않는다.
- 어느 후보든 본 operations.md 의 "Smoke evidence preservation" 항목과 묶지 않는다.

### Non-goals

- 본 scope 단계는 (R) / (S) / (W) 중 어느 것도 결정하지 않는다.
- 본 backlog 항목 자체는 어떤 구현도 자동 승인하지 않는다.
- `review-cycle.ps1` 또는 다른 lifecycle script 의 parameter contract 변경 아님.
- review.md "Review-cycle file-backed request input" 항목과 묶어서 한 batch 에 구현하지 않음 (별도 scoped goals).
- "Smoke evidence preservation" 항목과 묶어서 한 batch 에 구현하지 않음.
- PowerShell quoting 일반 추상화 / cross-shell quoting framework / 범용 quoting helper library 도입 아님 — 본 항목 hardening 대상은 smoke driver invocation 한 가지 use case 다.
- 새 daemon / watcher / scheduler / background automation 도입 아님.
- ChatGPT Web review hand-off 의 packaging 편의 (snapshot zip path-preserving, packet 첨부 convention 등) 와 묶지 않음 — 별도 영역.
- smoke rerun, SC5 rerun, evidence archive 생성 아님 — 본 항목은 scope definition 단계까지만.
- 본 항목 implementation 은 별도 scoped goal 을 거친다.

---

## Review-cycle invocation quoting hardening

- **Status**: **removed legacy design / historical reason only / not an operator path**. 본 항목이 다루던 free-text inline argv (`-Context`, `-ReviewQuestions`, `-Constraints`, `-RequiredInspectionPaths`) 의 PowerShell tokenization fragility 와 Stage 3 file-backed request input 채널 (`-ReviewRequestPath`) 은 2026-05-16 이후 단순화된 canonical review artifact topology (canonical 두 단계 layout 의 `log/review/<review-task-id>/pass-NN/input.md` + `log/review/<review-task-id>/pass-NN/result.md` 두 파일만; `docs/REVIEW_RESULT_CONTRACT.md`) 으로 대체되었다. canonical contract 에서는 AI 가 input.md 본문을 직접 작성하므로 free-text 본문이 PowerShell argv layer 를 통과하지 않으며, fragility 의 root cause 가 normal operator path 에서 자연 해소된다. 본 항목은 그 단계까지의 historical reason 만 기록하며, `-ReviewRequestPath`, `log/review-requests/`, Stage 1 inline argv 운영 규율은 현행 normal operator path 의 일부가 아니다.
- **Classification (historical)**: 운영자가 `scripts/review-cycle.ps1` 를 PowerShell 5.1 환경에서 직접 호출할 때의 argument-quoting reliability 문제. smoke driver 가 lifecycle script 를 호출하는 경로 (위 §"PowerShell smoke invocation quoting hardening") 도, review-cycle 내부 input channel 변경 (`docs/backlog/review.md` §"Review-cycle file-backed request input") 도 아닌, **operator → review-cycle.ps1 의 직접 invocation argv** 한 layer 만을 다룬 항목이었다.

> **Historical context only.** 아래 §Context / §Problem / §Observed symptoms / §Impact / §Direction / §Cross-reference / §"Stage 2 / Stage 3 decision (2026-05-16)" / §Non-goals 는 본 항목이 closeout 되었던 2026-05-16 시점의 기록이다. 현행 normal operator path 는 `docs/REVIEW_RESULT_CONTRACT.md` 의 canonical contract 다.

### Context

본 라운드의 BF Level 3 status helper (`scripts/brief-status.ps1`) 도입 작업 중, 후속 review gate 를 위해 운영자가 `review-cycle.ps1` 를 free-text 인자 (`-Context`, `-ReviewQuestions`, `-Constraints`, `-RequiredInspectionPaths`) 와 함께 직접 호출하는 단계에서 두 차례 wrapper-level failure 가 관찰되었다. 두 실패 모두 Codex reviewer evaluation 이전 단계의 driver / wrapper / prepare layer 에서 발생했고, 동일 의미의 invocation 을 wording / quoting 만 단순화한 형태로 재시도해서 정상 review 로 진행했다.

### Problem

PowerShell 5.1 에서 `scripts/review-cycle.ps1` 를 free-text 인자와 함께 직접 호출할 때, 본문이 (a) multi-line here-string 을 포함하거나 (b) embedded ASCII double-quote (`"`) 문자를 포함하면, child `powershell.exe` 의 argument tokenization / parameter binding 단계에서 의도와 다른 분리가 발생할 수 있다. 결과적으로 review-cycle.ps1 자체 또는 그 호출 직전 wrapper layer 에서 실패가 발생하며, Codex reviewer 호출까지 도달하지 못한다. 본 fragility 는 운영자 quote-discipline 권고만으로는 root-cause 가 해결되지 않는다.

### Observed symptoms

- **PathTooLongException in review-prepare path handling.** multi-line here-string 본문을 free-text 인자로 전달하는 직접 invocation 에서 `review-prepare.ps1` 가 path 를 구성하는 과정에 PathTooLongException 이 발생, prepare 자체가 완료되지 못했다. `<ProjectRoot>/log/review/<run-id>/` 디렉터리, `meta.json`, `input.md`, `result.md`, `result.json` 어느 것도 생성되지 않았다.
- **`-Reviewer` validation failure with unintended token (`narrow`).** free-text 인자 안의 embedded ASCII double-quote 문자가 child PowerShell 의 argument tokenizer 단계에서 parameter 경계로 reinterpret 되어, `-Reviewer` 가 본문의 token (`narrow`) 을 받아 `only -Reviewer codex is supported; got narrow` validation error 로 종료되었다. 이 또한 Codex 호출 이전 단계의 실패다.

두 symptom 모두 위 §"PowerShell smoke invocation quoting hardening" 의 driver failure 분류 표지 (parser/binder error, manually-quoted single-string form 으로는 통과, run-id 디렉터리 부재) 와 정확히 동형이며, layer 만 다르다 (smoke driver 가 아니라 operator 의 직접 review-cycle invocation).

### Impact

- **No review verdict corruption.** 실패는 Codex 호출 전 단계 (driver / wrapper / prepare) 에서 발생하므로 final review verdict evidence 를 오염시키지 않는다. 별개의 정상 invocation 으로 진행된 review 만이 evidence 로 사용된다.
- **Operational friction.** 운영자가 동일 의미의 review request 를 wording / quoting 만 다르게 재시도해야 하는 시간 비용이 발생한다.
- **Risk of confusing failure 분류.** wrapper-level invocation failure 를 (a) review-cycle 자체의 결함 또는 (b) Codex reviewer 실패로 오인할 risk 가 있다. 이는 위 §"PowerShell smoke invocation quoting hardening" 의 driver failure / smoke contract failure / Codex review failure 3 계층 분류와 같은 가족이며, operator 직접 invocation 도 동일 분류 위험을 공유한다.

### Direction (closeout)

본 항목은 Stage 1 (docs-only quoting 규율) + Stage 2 decision (단순 wrapper / cmd helper not adopted; PS 7.3+ / EncodedCommand acknowledged but not selected) + Stage 3 implementation (`-ReviewRequestPath` Markdown channel) 로 closeout 되었다. 본 절의 bullet 은 합의된 최종 direction 이며, 더 이상 candidate 가 아니다.

- **inline 사용 시의 quoting 규율 (Stage 1).** 직접 invocation 에서 inline `-Context` / `-RequiredInspectionPaths` / `-ReviewQuestions` / `-Constraints` 를 쓸 때 multi-line here-string / embedded ASCII double-quote / 백틱 / `$variable` 사용을 피하고 single-line / single-quote / ASCII fallback wording 으로 단순화한다. 운영자 docs: `docs/OPERATOR_GUIDE_KR.md` §9.
- **file-backed input 채널 (Stage 3).** complex / quote-heavy / multi-line / multilingual 본문은 `-ReviewRequestPath <path>` 로 전달한다. request 파일은 `<ProjectRoot>/log/review-requests/<name>.md` (UTF-8 Markdown, 4 H2 section) 이며 inline 채널과 mutually exclusive 다. 운영자 docs: `docs/OPERATOR_GUIDE_KR.md` §9b.
- **단순 wrapper / cmd helper (Stage 2) — not adopted.** parent → wrapper 의 argv 단계 fragility 를 보장하지 못하므로 채택하지 않는다. `scripts/smoke/invoke-review-cycle.ps1` 는 smoke-driver-only 그대로 유지된다.
- **direct invocation 의 권장도.** runbook / operator guide 에서 complex review request (long context, multi-line, multilingual, quote-heavy) 의 경우 inline 사용을 권장 패턴에서 제외하고 Stage 3 의 `-ReviewRequestPath` 로 안내한다.

### Cross-reference

- 위 §"PowerShell smoke invocation quoting hardening" — smoke driver layer 의 invocation hardening. 본 항목과 root cause (PowerShell 5.1 의 argument tokenization fragility) 를 공유하지만 layer 가 다르다 (smoke driver vs operator 직접 invocation). 두 항목은 별도 batch 로 closeout 되었다 (smoke 측은 commit `c183c6b` (W) wrapper, operator-direct 측은 본 항목의 Stage 1 / Stage 2 decision / Stage 3 implementation).
- `docs/backlog/review.md` §"Review-cycle file-backed request input" — review-cycle **내부** input channel 변경으로 동일 root cause 를 review-cycle 한 layer 안에서 해결한 항목. 본 항목과 통합 closeout 되었다 (동일 channel, 동일 라운드 — `-ReviewRequestPath` 의 Markdown + fail-fast conflict + `log/review-requests/` containment 가 두 backlog item 의 합의된 final shape).

### Stage 2 / Stage 3 decision (2026-05-16)

본 절은 Stage 1 docs-only mitigation 적용 (commit `53403e9`) 이후의 Stage 2 / Stage 3 방향성을 docs-only 로 기록한다. 어떤 구현, commit, push, global current/ refresh 도 자동 승인하지 않는다. 본 decision 의 적용 / 변경은 별도 scoped goal 의 explicit user approval 을 거친다.

**Stage 2 (단순 operator-direct PowerShell wrapper) — not adopted as a safe solution.**

- 단순 PowerShell wrapper (이전 candidate (X)) 는 parent process → wrapper 의 argv 단계에서 발생하는 PowerShell 5.1 의 argument tokenization fragility 를 honest 하게 흡수하지 못한다. wrapper 내부에서 splatting (`& $child @args`) 으로 child 로 forward 하더라도, parent → wrapper 단계의 embedded ASCII double-quote (`"`) 와 quote-heavy / multi-line free-text 본문은 wrapper 진입 이전에 이미 손상될 수 있다. 이는 위 §"PowerShell smoke invocation quoting hardening" 의 (W) wrapper (`scripts/smoke/invoke-review-cycle.ps1`) 의 Pester contract (`tests/invoke-review-cycle-smoke.Tests.ps1` line 90-98 의 NOTE) 가 embedded double-quote robustness 를 wrapper contract 에서 명시적으로 제외하는 이유와 동일하다.
- cmd / batch helper 후보 (예: 운영자가 `.cmd` 또는 `.bat` 로 review-cycle 을 invoke 하는 thin shim) 도 채택하지 않는다. cmd / batch 는 Windows shell parsing 의 또 다른 layer 를 추가하며 (CommandLineToArgvW 의 quote / escape 규약 + cmd 의 metacharacter 해석), quote-heavy / multi-line free-text argv 의 robustness 를 root-cause 해결하지 못하고 디버깅 경로만 늘린다.
- 결론: 단순 wrapper / cmd helper 는 Failure A (PathTooLongException) / Failure B (`-Reviewer narrow` mis-binding) 의 root cause 인 "free-text 본문이 PowerShell argv layer 를 통과한다는 사실" 자체를 제거하지 못하므로 safe solution 으로 분류하지 않는다.
- `scripts/smoke/invoke-review-cycle.ps1` 는 smoke-driver-only scope 그대로 유지된다. operator-direct fallback 또는 권장 entrypoint 로 승격하지 않는다 (Stage 1 docs-only mitigation 의 wording 과 정합).

**Acknowledged but not selected — platform-level escape hatches.**

- **PowerShell 7.3+ native argument passing.** `$PSNativeCommandArgumentPassing` (Standard / Legacy / Windows) 및 PS 7.3 의 native-argument 보존 동작은 PowerShell 5.1 의 fragility 를 한 layer 위에서 줄이는 official platform-level 가능성이다. 그러나 PS 7.3+ requirement 도입은 본 toolset 의 runtime dependency boundary (`docs/CLI_ENVIRONMENT_ASSUMPTIONS.md`) 를 변경하며, 운영자의 PS install 가정과 channel 3 global stable install 의 호환성 평가, snippet / docs / Pester / smoke 전반의 정합화 비용을 수반한다. 본 batch 의 docs-only scope 를 벗어나며, **later portability track / possible Python · Node porting strategy 의 일부로 별도 기록**한다 (본 hardening item 의 즉각 구현 대상 아님).
- **`-EncodedCommand` / `-EncodedArguments` launcher.** PowerShell 의 공식 escape hatch 로, free-text 본문을 base64 encoded UTF-16 payload 로 전달하여 parent shell 의 tokenization 을 bypass 한다. 그러나 launcher 가 base64 변환 / encoding 책임을 떠안으면 readability / debuggability 가 크게 저하되고 (사람이 읽지 못하는 invocation), 운영자 직접 호출 use case 와의 정합도 낮으며, 새로운 launcher 의 contract / Pester / docs 비용이 발생한다. 본 batch 에서 채택하지 않는다 (acknowledged escape hatch 로 기록만 남긴다).

**Stage 3 (file-backed review request input) — implemented.**

- Stage 3 는 본 라운드에서 채택되어 `scripts/review-cycle.ps1` 에 `-ReviewRequestPath <path>` 파라미터로 구현되었다. free-text 본문 (`-Context`, `-RequiredInspectionPaths`, `-ReviewQuestions`, `-Constraints`) 을 argv 가 아닌 request file 로 전달하므로 PowerShell 5.1 의 argv tokenization fragility 의 root cause 가 review-cycle 한 layer 안에서 해소된다.
- 채택된 decisions (이전 deferred 결정들의 최종 형태):
  - **파라미터 이름**: `-ReviewRequestPath`.
  - **파일 포맷**: Markdown plain text (UTF-8). 결정 사유 — JSON 후보는 본문 안 multi-line / embedded double-quote / 한국어 에 대해 추가 escape layer 를 요구하나, Markdown H2 section + 본문 verbatim 방식은 escape 없이 원본을 그대로 보존한다 (Stage 3 의 root-cause 해소 목표와 직접 정합).
  - **Required heading set**: input.md template 의 heading 과 정확히 동일 — `## Context`, `## Required inspection paths`, `## Review questions`, `## Constraints`. body 는 다음 H2 직전까지 (또는 EOF) 의 모든 줄 trim. fail-fast 조건: missing heading / empty body / duplicate heading.
  - **파일 위치 규약**: `<ProjectRoot>/log/review-requests/<purpose-or-timestamp>.md`. `scripts/lib/path.ps1` 의 신규 helper `Assert-InProjectLogReviewRequestsRoot` 가 containment 를 강제하며 그 외 경로는 fail-fast 거부.
  - **inline 채널과의 conflict 규칙**: `-ReviewRequestPath` 와 inline `-Context` / `-RequiredInspectionPaths` / `-ReviewQuestions` / `-Constraints` 는 **mutually exclusive** (둘 다 비어있지 않으면 fail-fast). 우선순위 / partial override 같은 silent merge 은 채택하지 않는다 — 명확한 entrypoint 분리가 audit 가능성을 보존한다.
  - **`-TargetFiles` / `-TargetFilesPath` semantics**: 변경 없음. request 채널은 target 식별과 직교한다.
  - **inline 채널의 backward compatibility**: `-ReviewRequestPath` 미사용 시 기존 inline 동작 그대로. Stage 1 docs-only quoting 규율 (`docs/OPERATOR_GUIDE_KR.md` §9) 은 inline 사용 시 그대로 적용된다.
  - **review-prepare 와 binding**: prepare 단계에서 request file 의 `path` (project-relative, forward-slash) + `sha256` 이 `meta.json.reviewRequest` 에 기록된다. provenance binding 이며, reviewer 가 실제로 받은 input 텍스트의 freshness 는 `result.json.inputSha256` 가 input.md 단위에서 이미 다룬다 (`docs/REVIEW_RESULT_CONTRACT.md` "meta.json" 의 reviewRequest 절 참조).
  - **review-input-verify / review-verify**: 별도 변경 없음. input.md 의 4 section 채움 여부는 review-input-verify 가 이미 검증하며, request file 의 본문이 input.md 의 placeholder 를 그대로 채우므로 기존 검증이 그대로 적용된다.
  - **두 backlog item 의 관계**: 본 항목 (`docs/backlog/operations.md` §"Review-cycle invocation quoting hardening") 와 `docs/backlog/review.md` §"Review-cycle file-backed request input" 는 **통합 closeout** 된다 — 동일 channel 의 layer 별 framing 으로 보고 한 batch 에서 implementation closeout 했다.
  - **Pester 케이스**: `tests/review-cycle-request.Tests.ps1` (11 case) — multi-line body, embedded ASCII double-quote, Korean+English mix, markdown bullets, missing heading, empty body, duplicate heading, outside-log containment, missing path, inline-vs-file conflict (Context / ReviewQuestions), inline-only backward compatibility.
  - **운영자 docs**: `docs/OPERATOR_GUIDE_KR.md` §9b 가 사용법 / 예시를 다룬다. `README.md` "Single-shot review cycle" 가 high-level 안내를 다룬다.
- 본 implementation 자체가 commit / push / global current/ refresh / criteria 변경 어느 것도 자동 승인하지 않는다.

**Later portability / Python · Node porting (deferred, separate track).**

- 본 hardening item 은 review-cycle 의 input channel 한 layer 만을 다룬다. PS 7.3+ 도입, EncodedCommand launcher, 그리고 Python / Node 로의 부분 또는 전체 porting (예: `review-cycle` 의 일부 단계 또는 entire CLI 를 cross-platform language 로 다시 작성) 은 본 hardening item 과 분리된 portability track 의 별도 scoped 결정이다.
- 본 절은 그 portability track 의 존재 가능성만 기록하며 (a) 어느 언어로의 porting 도 자동 승인하지 않고, (b) 본 hardening item 의 Stage 3 implementation 과 portability track 을 한 batch 에 묶지 않는다.

### Non-goals

- 본 라운드 closeout 후에도 review subsystem 의 redesign 은 본 항목 scope 가 아니다.
- 광범위한 PowerShell quoting abstraction layer / cross-shell quoting helper / 범용 quoting framework 도입 아님.
- verdict semantics 변경 아님.
- `review-verify` binding 또는 freshness / hash 검증 규칙 변경 아님 — Stage 3 implementation 도 review-verify 를 건드리지 않는다. `meta.json.reviewRequest` 는 provenance binding 일 뿐 freshness 검증 대상이 아니다.
- background / detached review execution 도입 아님.
- `scripts/review-cycle.ps1` 의 parameter contract 변경 중 `-ReviewRequestPath` 도입 외의 항목 (예: 새 verdict mode, 새 reviewer, 새 sandbox 모드 등) 아님.
- 단순 operator-direct PowerShell wrapper 신설 아님 (Stage 2 decision §"Stage 2 / Stage 3 decision (2026-05-16)" 에서 not adopted).
- 새 cmd / batch helper 신설 아님 (같은 §에서 not adopted).
- `scripts/smoke/invoke-review-cycle.ps1` 의 operator-direct fallback 승격 아님.
- PowerShell 7.3+ requirement 도입 아님 (portability track 별도).
- `-EncodedCommand` / `-EncodedArguments` launcher 도입 아님 (escape hatch acknowledged 만).
- Python / Node 로의 porting 착수 아님 (portability track 별도).
- 본 backlog 항목 자체는 commit / push / global current/ refresh / criteria 변경 어느 것도 자동 승인하지 않는다 — Stage 3 implementation 의 commit / push / global refresh 결정은 별도 explicit user approval.

---

## Smoke evidence preservation

- **Status**: scope-defined; implementation candidate decision (runbook-only / helper-script / archive manifest; §Future implementation candidates 참조) 는 별도 scoped goal 로 deferred.
- **Classification**: smoke run 이 산출한 evidence 를 round 종료 이후에도 참조 가능하게 만드는 **repo-external archive / export convention** 의 정의. evidence *capture* convention (`docs/EVIDENCE_CONTRACT.md` — `<ProjectRoot>/log/evidence/` 트리) 의 한 layer 아래 / downstream 이며, capture contract 자체를 변경하지 않는다.

### Context

본 라운드의 smoke evidence 는 `%TEMP%\ahts-smoke\<utc>\` 및 `%TEMP%\ahts-smoke-sc5\<utc>\` 아래에 저장되었다. 이는 `docs/EVIDENCE_CONTRACT.md` 가 정의하는 `<ProjectRoot>/log/evidence/` 트리도, `CLEAN_TARGET_SMOKE_CRITERIA.md` §4 가 권장하는 `<ProjectRoot>/log/evidence/clean-target-smoke/<case>/` 또는 source-repo 외부 evidence 저장소도 아닌, **OS 임시 디렉터리** 다.

### Why preservation is needed — `%TEMP%` evidence loss risk

- `%TEMP%` 는 OS / disk-cleanup utility / 재부팅 정리 대상이다. 정리 시점은 운영자가 통제하지 않으며 사전 통지도 없다. 따라서 `%TEMP%` 아래의 smoke evidence 는 round 종료 시점부터 silent loss risk 에 노출된다.
- smoke evidence 의 일부는 round 종료 이후에도 참조 가치가 있다 — 예: SC5 round 1 → round 2 incident 의 재현 단서, partial coverage 분류 (`SC5' substitute`) 의 근거, ToolRoot channel resolution 의 case 별 transcript. 이들은 후속 라운드의 escalation 판단 / re-evaluation 의 input 이 될 수 있다.
- 동시에 raw smoke evidence (transcript, run-dir, directory snapshot) 는 bulky / transient 하여 source repo 에 default 로 두면 source snapshot 을 오염시킨다 (`docs/EVIDENCE_CONTRACT.md` §source vs runtime 경계와 일관).
- 따라서 필요한 것은: `%TEMP%` 의 transient 위치에서 **결정론적이고 운영자가 통제하는 repo-external 위치** 로 중요 evidence 를 옮기는 export 경로의 합의다.

### Repo-external archive convention candidates

- **저장 위치 후보** — `<USERPROFILE>\ai-harness-evidence\<utc>\` 또는 그와 평행한 source-repo 외부 절대경로. ToolRoot / ProjectRoot working tree 안에 두지 않는다. 정확한 base path 는 implementation 단계에서 확정.
- **archive 단위** — smoke suite 1 회 실행 (`<utc>` run) 을 1 archive 단위로 본다. 한 archive 는 그 run 의 per-SC evidence 를 포함한다.
- **archive 포맷** — 결정론적 zip / tar 등. 결정론성 (동일 입력 → 동일 archive 내용 구조) 을 만족하는 포맷이면 무엇이든 후보. 정확한 포맷은 implementation 단계 결정.
- **path-preserving** — archive 는 relative path 구조를 보존해야 한다 (flatten 금지). archive 안에서 per-SC / per-case 디렉터리 구조가 그대로 복원 가능해야 한다.

### Archive trigger model

- archive 시점은 **운영자의 명시적 action** 이다. round 종료 후 운영자가 보존 가치가 있다고 판단한 run 에 대해서만 archive 한다.
- 자동 archive / 자동 retention / 자동 cleanup 은 본 항목이 제안하지 않는다 (§Non-goals).
- archive 대상 선택 (어느 run 을 보존할지) 도 운영자 판단이며, 본 convention 은 "보존하기로 한 run 을 어디에 / 어떤 형태로 두는지" 만 규정한다.

### Source repo inclusion boundary

- `log/` 는 gitignored runtime artifact 트리다 (`.gitignore` 의 `log/` 규칙, `docs/EVIDENCE_CONTRACT.md` §source vs runtime 경계). raw transcript / run-dir / directory snapshot 은 **source repo 에 commit 하지 않는다** — repo-external archive 가 그 보존 자리다.
- source repo 안으로 들어갈 수 있는 것은 **sanitized summary / reference 뿐** 이다. 예: per-SC `SUITE_REPORT.md` 의 sanitized snippet, archive 위치를 가리키는 reference 한 줄. 이 인용도 자동이 아니라 별도 scoped 절차를 거친다.
- 즉 경계는: **raw evidence → repo-external archive**, **sanitized summary / reference → (별도 scoped 절차로만) source repo**. 이 경계는 본 항목이 새로 만드는 것이 아니라 `docs/EVIDENCE_CONTRACT.md` 의 source/runtime 경계를 archive layer 로 연장한 것이다.

### Future implementation candidates

다음 implementation goal 은 아래 후보를 과확장 없이 분리하여 검토한다. 세 후보는 상호 배타가 아니다 — archive manifest 는 runbook-only 또는 helper-script 어느 쪽과도 결합 가능한 format 계층이다. 본 scope 단계에서는 어느 것도 결정하지 않는다.

- **(A) runbook-only** — `docs/runbooks/` 아래 1 개 docs 파일. 운영자가 `%TEMP%` evidence 를 repo-external archive 위치로 옮기는 수동 절차 (경로 규약, naming, 결정론적 포맷, path-preserving 주의) 를 명문화. 새 .ps1 / 새 helper / 새 test 0. 비용 가장 낮음. trade-off — 매 archive 마다 운영자가 절차를 수동 재현.
- **(B) helper-script** — 운영자가 명시적으로 호출하는 CLI helper 1 개 (예: `tools/archive-smoke-evidence.ps1` — 위치 / 이름 implementation 단계 결정). 본 helper 는 지정된 run 의 evidence 를 결정론적 archive 로 packaging 하여 repo-external 위치로 export. 운영자 명시 호출만; 자동 trigger 없음. 새 .ps1 1, Pester test 의무, CLAUDE.md MUST 트리거 (codex review 필수). 비용 가장 높음.
- **(C) archive manifest** — archive 와 동행하는 결정론적 manifest 파일 1 개의 convention. 최소 내용 후보: archive 대상 run-id 목록, smoke 실행 시점 source repo HEAD (execution HEAD), per-SC pass / fail / skip 요약, sanitized summary 로의 pointer. format 계층이므로 (A) 또는 (B) 와 결합 가능하며 단독으로도 정의 가능. 새 .ps1 없음 (manifest 는 데이터 파일 convention).

decision boundary:

- 다음 implementation goal 의 책임이 "운영자가 archive 절차를 일관되게 재현하도록 문서화" 이면 (A) 로 충분하다.
- "archive packaging 을 결정론적으로 자동 구성" 이 필요하면 (B) 가 후보이며, 새 .ps1 / test / review gate 비용을 수반한다.
- (C) 는 (A) 또는 (B) 중 무엇을 채택하든 archive 의 self-describing 성을 위해 함께 검토할 수 있으나, 단독 goal 로 분리해도 된다.
- 한 implementation goal 에서 (A) / (B) 중 둘을 동시에 구현하지 않는다. (C) 는 채택된 후보에 부속시키거나 별도 goal 로 분리한다.

### Cross-reference

- `docs/EVIDENCE_CONTRACT.md` — evidence *capture* convention (`<ProjectRoot>/log/evidence/<scope>/<case>/`, manual-convention-first, gitignored). 본 항목은 그 contract 를 변경하지 않으며, capture 이후의 *archive / export* 단계만 다룬다.
- `docs/roadmap/CLEAN_TARGET_SMOKE_CRITERIA.md` §4 — smoke execution goal 이 보존해야 할 per-case evidence 목록과 권장 위치 (`<ProjectRoot>/log/evidence/clean-target-smoke/<case>/` 또는 source-repo 외부 저장소) 를 정의. 본 항목은 그 "source-repo 외부 저장소" 의 convention 을 구체화하는 자리다.

### Non-goals

- 본 scope 단계는 runbook-only / helper-script / archive manifest 중 어느 것도 결정하지 않는다.
- 본 backlog 항목 자체는 어떤 구현도 자동 승인하지 않는다.
- evidence 의 자동 retention / 자동 archival / 자동 cleanup 도입 아님 — archive trigger 는 운영자 명시 action.
- 새 daemon / watcher / scheduler / background automation 도입 아님.
- `docs/EVIDENCE_CONTRACT.md` 의 변경 아님 (별도 scoped change).
- bulk / raw evidence 의 source-repo 채택 아님 — source repo 에 들어갈 수 있는 것은 sanitized summary / reference 뿐.
- smoke rerun, SC5 rerun, evidence archive 생성 아님 — 본 항목은 scope definition 단계까지만.
- review.md "Review-cycle file-backed request input" / operations.md "PowerShell smoke invocation quoting hardening" 의 scope 와 묶지 않음 (cross-reference consistency 외).
- 본 항목 implementation 은 별도 scoped goal 을 거친다.

---

## Brief / Chatlog location reconciliation — project-local log runtime model

- **Status**: docs-only correction 완료 (본 라운드). scripts / tests / snippets / templates / global / user files 의 정합화는 deferred.
- **Classification**: long-lived docs hygiene + Brief / Chatlog / footprint contract clarification. 본 라운드의 docs correction 이 Brief / Chatlog location 결정의 reconciliation 을 정리하고, 직전 라운드의 root `<ProjectRoot>/brief/` canonical 모델과 미발효된 user-home operator-local runtime root 모델을 동시에 reject 한다.

### Context

본 라운드 직전까지 Brief / Chatlog location 모델은 두 단계의 reconciliation 을 거쳤다 (`Project-local copy model docs vs global stable runtime ToolRoot model` 항목 status / framing 참조). 별도 read-only 점검 라운드에서 root `<ProjectRoot>/brief/` 와 user-home operator-local runtime root (`%USERPROFILE%\.ai-harness\projects\<project-key>\...`) 두 후보가 함께 논의되었으나, 본 라운드의 authoritative decision 은 두 후보를 모두 reject 하고 `<ProjectRoot>/log/` 단일 runtime root 로 회귀하는 것이다.

### Authoritative decision (현행 — 3차 reconciliation)

- ai-harness tool payload 는 global install 로 제공되며 target repo 에 복사하지 않는다.
- ai-harness runtime artifacts 는 target project checkout 내부의 `<ProjectRoot>/log/` 아래에 둔다.
- `<ProjectRoot>/log/` 는 project-local, operator-local, source-control-excluded runtime root 다.
- Brief: `<ProjectRoot>/log/brief/BRIEF.md`.
- Chatlog: `<ProjectRoot>/log/chatlog/`.
- Evidence: `<ProjectRoot>/log/evidence/`.
- Review: `<ProjectRoot>/log/review/<review-task-id>/pass-NN/` (canonical 두 단계 layout per `docs/REVIEW_RESULT_CONTRACT.md`; 현행 script `review-prepare.ps1` / `review-run.ps1` / `review-verify.ps1` 가 이 layout 을 그대로 emit 한다 — `docs/roadmap/POST_MVP_PLAN.md` §10 Completed `c81fe45` 참조).
- 위 네 트리는 source-of-truth repo artifact, product source, 팀 공유 산출물, commit / push 대상이 아니다.
- root `<ProjectRoot>/brief/BRIEF.md` 모델은 폐기 (rejected).
- `%USERPROFILE%\.ai-harness\projects\<project-key>\...` 모델은 폐기 (rejected).
- "project-local" 은 그 project 의 checkout 안에 있다는 의미이지 "repo-tracked" 라는 의미가 아니다.
- "operator-local" 은 각 운영자의 local checkout 안의 instance 라는 의미이지 user-home 의 global state 라는 의미가 아니다.

### 본 라운드에서 변경된 docs

- `README.md` — §"Evidence and chatlog" / §"Documentation map" 의 Brief / Chatlog 경로 wording 을 `<ProjectRoot>/log/brief/BRIEF.md` 기준으로 정정. source snippet alignment note 도 3차 framing 기준으로 갱신.
- `docs/BRIEF_CONTRACT.md` — §"canonical Brief 자리" (구 §"target repo canonical Brief 자리") rewrite, §"현재 source-side primitive 상태" / §"BRIEF 의 위치와 독자" / §"source repo vs target repo 경계" / §"tracked vs gitignored" / §"BRIEF required / optional headings" / §"non-goals" / §"향후 확장 시 고려 사항" 정정. Historical lineage (1차, 2차, 3차 reconciliation) 보존.
- `docs/CHATLOG_CONTRACT.md` — §"current restore source 는 Brief 다" / §"Brief reconstruction evidence — 사용 흐름" 의 Brief 경로 정정.
- `docs/OPERATOR_GUIDE_KR.md` — §7b BF save / restore-offer 자연어 UX (Note, BF save 절차, restore-offer read order), §12b acceptance 표, §17 reviewer-verdict-가-아닌-artifact 목록 정정.
- `docs/roadmap/POST_MVP_PLAN.md` — §3 canonical Brief 위치 결정, §4 / §5 / §10 의 BRIEF / canonical / routing wording 정정. §11 numbered order 는 변경하지 않음 (POST_MVP_PLAN.md §11 의 order-change 금지 규칙 준수).
- `docs/roadmap/GLOBAL_INSTALL_UPDATE_MODEL.md` — §1 executive summary 최상단에 3rd reconciliation top note 삽입, §1 executive bullets 정정, §5.2 / §5.3 metadata `targetFootprintPolicy` 값 갱신 (`log-brief-only` → `log-only`), §6 Layer 4 superseded note 를 three-step reconciliation 으로 확장, §7.2 validation target footprint goal 정정, §8 target footprint contract Allowed / Forbidden 재정의, §9 BRIEF wording note 를 three-step reconciliation 으로 확장, §11 clarified model 표현 정정. §9 body / §10 diagrams 의 historical wording 은 historical record 로 보존 (§9 wording note 와 §1 top note 가 우선).
- `docs/roadmap/SHARED_GLOBAL_INVOCATION_CONTRACT.md` — §3 `BriefRoot` 정의 정정, D7 Decision 본문 / Superseded note 를 three-step reconciliation 으로 확장.
- `docs/backlog/operations.md` — 본 entry 추가, `Project-local copy model docs vs global stable runtime ToolRoot model` entry 의 Status / framing bullets 갱신.

### Resolved in the follow-up Brief/Chatlog/BF drift cleanup round

후속 정리 라운드에서 다음 항목들이 정합화 / 정리되었다.

- `snippets/CLAUDE_SNIPPET.md`, `snippets/AGENTS_SNIPPET.md` source body — 3차 reconciliation framing + BF Level 1/2 no-hand-edit wording 적용. canonical Brief = `<ProjectRoot>/log/brief/BRIEF.md`, root `<ProjectRoot>/brief/` rejected, legacy chatlog/current 분류 보존. destination `CLAUDE.md` / `AGENTS.md` 의 managed block refresh 는 자동 적용되지 않으며 별도 사용자 명시 승인이 필요하다 (`docs/roadmap/GLOBAL_ADOPTION_DECISION.md` §6).
- `templates/brief/BRIEF.md` preamble — current canonical Brief contract 와 일치하도록 정리되었고, 삭제된 `templates/session-resume.md` 로의 cross-reference 가 제거되었다.
- Obsolete chatlog-fuller-implementation 자료 drop — `templates/session-resume.md`, `templates/session-summary.md`, `templates/decision-log.md`, `tests/chatlog-contract-manual.md` 가 삭제되었다. 이 파일들은 `log/chatlog/current/resume.md` 를 canonical 자리로 가정하고 multi-file chatlog layout 을 current workflow 처럼 기록하던 자료로, current Chatlog contract (later-track only) 와 직접 모순되었다. Chatlog fuller implementation 의 future scoped work 가 시작될 때는 본 round 의 삭제와 관계 없이 별도 scope / 별도 design 으로 출발한다.
- `README.md`, `docs/OPERATOR_GUIDE_KR.md`, `docs/roadmap/POST_MVP_PLAN.md` — "source snippet 본문이 2차 framing 으로 남아 있다" stale 진술 정정.
- `docs/roadmap/TOOLROOT_PROJECTROOT_AUDIT.md` — 본 라운드에서 drop 된 chatlog template 에 대한 audit-body observation 을 historical superseded note 안에 포함.
- `docs/roadmap/REVIEW_EFFORT_GUIDE.md` — legacy review-cycle / `meta.json` / `result.json` / `target-files.list` / flat run-id / `-TargetFiles` / `log/review-targets/` / `templates/review-meta.json` / "BF Level 2" wording 을 current canonical task/pass topology + BF Level 1/2 wording 으로 정합화.
- `tests/README.md` — 삭제된 `tests/chatlog-contract-manual.md` 에 대한 manual AC reference 제거.

### Deferred (별도 scoped work)

본 backlog 항목은 어느 것도 자동 승인하지 않는다.

- `scripts/brief-init.ps1`, `scripts/brief-check.ps1`, `scripts/lib/path.ps1`, 기타 lifecycle scripts. (현재 writer destination 과 default check path 는 이미 canonical 자리와 일치하므로 기능 변경이 필요한지 자체가 별도 scoped 판단.)
- `tests/brief-init.Tests.ps1`, `tests/brief-check.Tests.ps1`, 기타 test fixtures. (현재 fixture path 가 canonical 자리이므로 마찬가지로 변경 필요 여부가 별도 scoped 판단.)
- destination `CLAUDE.md` / `AGENTS.md` 의 managed block refresh (project-root / user-global). user-approved 별도 작업.
- `docs/DECISIONS.md`, `docs/roadmap/CLEAN_TARGET_SMOKE_CRITERIA.md`, `docs/roadmap/GLOBAL_ADOPTION_DECISION.md` 의 BRIEF / footprint wording 잔여 점검 (현행 contract docs 와 충돌 시 contract docs 우선).
- BF Level 3 capability (deterministic Brief maintenance / validation / stale warning / session-start guidance / restore-offer) 의 implementation.

### Non-goals

- 본 backlog 항목은 어떤 구현 / 새 packaging / 새 distribution / commit / push / global mutation 도 자동 승인하지 않는다.
- `<ProjectRoot>/log/` 의 tracked / gitignored 정책 자체를 본 항목이 변경하지 않는다 (`log/` 는 `.gitignore` 의 `log/` 규칙 기준이며, target operator 가 그 규칙을 깨고 BRIEF 를 tracked 로 두는 것은 본 contract 가 정의하지 않는 운영 결정).
- `<ProjectRoot>/log/chatlog/current/resume.md` / `summary.md` 의 deletion / migration / path 변경 (별도 scoped 승인 필요; `docs/CHATLOG_CONTRACT.md` 의 deprecation candidate 분류 유지).
- `<ProjectRoot>/brief/` 디렉터리의 자동 정리 / migration. 운영자의 명시 cleanup 대상.
- 본 항목 implementation 은 별도 scoped goal 을 거친다.

---

## Project-local copy model docs vs global stable runtime ToolRoot model

- **Status**: 부분 완료 + Brief / BF Level / footprint contract 3차 reconciliation 완료 + source snippets / templates / tests 정리 완료. global stable runtime ToolRoot 모델로의 docs wording 정합화 (`docs/OPERATOR_GUIDE_KR.md`, `README.md`, `docs/AI_HARNESS_TOOLSET_SCOPE.md`, `docs/roadmap/POST_MVP_PLAN.md` 의 channel 3 / channel 5 framing) 자체는 closeout 이다. Brief / Chatlog / footprint location 결정은 세 단계의 reconciliation 을 거쳤다: (1차) `log/brief/BRIEF.md` canonical + root `brief/` forbidden, footprint = `log/` only; (2차) target product canonical Brief 를 `<ProjectRoot>/brief/BRIEF.md` 로 두고 `log/brief/BRIEF.md` 를 not-canonical 한 seed destination 으로 분류, footprint = `log/` + `brief/`; **(3차, 현행)** 2차 framing 이 정정되어 canonical Brief 가 다시 `<ProjectRoot>/log/brief/BRIEF.md` 이고 root `<ProjectRoot>/brief/` 는 rejected, user-home operator-local runtime root 도 rejected, target persistent footprint = `<ProjectRoot>/log/` only (BRIEF / Chatlog / Evidence / Review 모두 `log/` 아래). 본 라운드에서 contract docs (`docs/BRIEF_CONTRACT.md`, `docs/CHATLOG_CONTRACT.md`), 그리고 named docs 의 wording (위 4 개 + `docs/roadmap/GLOBAL_INSTALL_UPDATE_MODEL.md`, `docs/roadmap/SHARED_GLOBAL_INVOCATION_CONTRACT.md`) 이 3차 reconciliation 으로 정정 완료되었다. 후속 Brief/Chatlog/BF drift 정리 라운드에서 source `snippets/CLAUDE_SNIPPET.md` / `snippets/AGENTS_SNIPPET.md` 본문도 3차 framing + BF Level 1/2 no-hand-edit wording 으로 정합화되었고, current canonical workflow 와 모순되던 obsolete chatlog-fuller-implementation 자료 (`templates/session-resume.md`, `templates/session-summary.md`, `templates/decision-log.md`, `tests/chatlog-contract-manual.md`) 와 그 cross-reference 가 drop 되었다. 현재 contract 의 framing 은 다음과 같다 (자세한 내용은 `docs/BRIEF_CONTRACT.md`, `docs/CHATLOG_CONTRACT.md`): (a) BF Level 은 path 가 아니라 save / restore capability maturity 다. (b) canonical Brief 는 `<ProjectRoot>/log/brief/BRIEF.md` — project-local, operator-local, source-control-excluded runtime artifact under `<ProjectRoot>/log/`. (c) `scripts/brief-init.ps1` / `scripts/brief-check.ps1` 가 seed / 검증하는 자리가 정확히 canonical 자리와 일치한다. (d) `log/chatlog/current/resume.md` / `summary.md` 는 canonical 자리가 아니라 failed intermediate / legacy migration source / deprecation candidate 다. (e) BF Level 3 의 full capability — deterministic Brief maintenance / validation / stale warning / session-start guidance / restore-offer — 은 미구현 future scoped work 다. (f) BF Level 1/2 manual save / restore discipline 에서 operator 는 trigger / approve / reject / discard 주체이며, BRIEF 본문은 사람의 손편집에 의존하지 않는다 — content generation / update 는 deterministic tooling 또는 명시적 AI-assisted command flow (agent) 가 담당한다 (clean decision memo D-BRIEF-8). 운영자가 이전 라운드에 destination `CLAUDE.md` / `AGENTS.md` 의 managed block 에 적용한 본문은 그 시점의 snippet 본문 그대로다. destination managed block refresh 는 별도 사용자 명시 승인이 필요한 managed-block replacement step (`docs/roadmap/GLOBAL_ADOPTION_DECISION.md` §6) 으로 남는다 — 본 backlog 항목이 자동 승인하지 않는다.
- **Classification**: long-lived docs hygiene. global runtime ToolRoot 전환 (6-channel stable resolution; latest commits `f37c91c` / `e699c07` / `e9f2a00` 계열) 이후, 일부 docs 가 아직 구 project-local `.ai-harness/` copy model 기준 wording 을 유지하고 있어 부분 독해 시 두 모델이 혼동될 수 있다.

### Context

global stable runtime ToolRoot 모델로의 전환이 snippets / skill / resolution docs 에는 반영되었고, 아래 named docs 의 정합화 진행 상태는 각 bullet 에 기록한다 — `docs/OPERATOR_GUIDE_KR.md`, `README.md`, `docs/AI_HARNESS_TOOLSET_SCOPE.md`, `docs/roadmap/POST_MVP_PLAN.md` 의 channel 3 / channel 5 framing 정합화는 완료이고, Brief / Chatlog / BF Level contract 의 재정합화는 별도 round 에서 contract docs (`docs/BRIEF_CONTRACT.md`, `docs/CHATLOG_CONTRACT.md`) 와 본 backlog 항목 status 줄에 반영되었다. 본 backlog 항목 안의 channel-3 wording 정합화 추적은 closeout 이지만, 그 라운드의 BRIEF posture reconciliation framing 자체는 이후 정정되었다 (status 줄 참조).

- `docs/AI_HARNESS_TOOLSET_SCOPE.md` — **완료 (wording 정합성).** §"Source repo vs target project payload" 가 현행 adoption = shared / global channel 3 로 lead 하도록 재작성되었고, `.ai-harness/` payload 표는 "legacy project-local copy mode (channel 5)" 로 명시 강등되었으며, 본 절이 channel-3 adoption 판단의 primary source-of-truth 가 아님이 본문에 명시되었다. §"Path concepts" 의 `ToolRoot` 정의도 channel 3 / source-repo dogfooding / legacy channel 5 의 3-form 으로 갱신되었다. (`docs/backlog/README.md` 탐색 규칙상 본 문서의 contract 우선순위 위상 자체는 재정의하지 않았다 — wording 정합성 정리만 수행.)
- `docs/roadmap/POST_MVP_PLAN.md` — **완료 (stale status / next-action wording).** §6 의 "현재 active default 는 copy-only adoption" 진술이 historical record 로 보정되고 현행 default = channel 3 임이 명시되었다. §11 의 next-action wording 이 갱신되어, step 1 (`GLOBAL_INSTALL_UPDATE_MODEL.md` 확정) 은 §10 Completed 기준 이미 충족된 baseline checkpoint 로 표기되고 다음 실제 milestone 은 step 2 (global behavior validation) 로 정정되었다. §11 numbered order 의 항목 / 순서 구조 자체는 변경하지 않았다 (POST_MVP_PLAN.md §11 의 order-change 금지 규칙 준수). 큰 순서 / 단계 구분은 그대로 유효하다.
- `README.md` — **완료.** front-door pointer (이전 라운드) 에 더해, 본 라운드에서 body 가 shared / global channel 3 first 구조로 재구성되었다 — intro 단락이 channel 3 adoption 으로 lead 하고, 구 "Quick start: copy-only target project adoption" 절이 "Quick start" (shared / global) + "Legacy project-local copy mode (channel 5)" 하위 절로 분리되었으며, log-init / review-cycle 경로 설명이 channel 3 default + source-repo dogfooding + legacy channel 5 의 3-form 으로 정합화되었고, "What this toolset does not do" 의 "no `~/.claude/` files written" 진술이 channel 3 deliberate materialization 과 정합하도록 보정되었다. front-door pointer 의 "not yet been rewritten" 단서도 제거되었다.
- `docs/OPERATOR_GUIDE_KR.md` (구 `docs/MVP_OPERATOR_GUIDE_KR.md`, rename 완료) — **active operator guide 정합화 대상** (superseded-note-only 가 아니다). 본 문서는 사용자가 실제로 toolset 을 운용하는 operator-facing guide 이므로 상단 pointer 만으로는 부족하며 본문 live 절차 자체가 current shared/global model 기준이어야 한다. **완료된 보정**: §1–§2 의 모드 정의가 shared/global default + source-repo/dogfooding + legacy project-local copy 의 3-mode 로 정합화되었고, §3 / §9 의 `.ai-harness/` 절차가 legacy channel 5 전용으로 강등되었으며, §9 에 shared/global (channel 3) invocation 이 primary 예시로 추가되었고, §13 acceptance checklist 가 shared/global 기준으로 재작성되고 legacy checklist 는 §13a 부록으로 분리되었으며, §14 평가 절차와 §15 non-goals (`~/.claude/` / global install 표현) 이 current adoption 과 정합하도록 보정되었다. 또한 파일이 `docs/MVP_OPERATOR_GUIDE_KR.md` 에서 `docs/OPERATOR_GUIDE_KR.md` 로 rename 되고 title / opening identity 가 current operator guide 로 보정되었다. **완료된 reference 정리**: `tests/chatlog-contract-manual.md` 의 구 파일명 (`docs/MVP_OPERATOR_GUIDE_KR.md`) reference 6 건이 commit `f1b25e0` 에서 `docs/OPERATOR_GUIDE_KR.md` 로 갱신 완료되었다. **완료된 본문 정밀화**: §5–§6 diagram 에 mode-neutral note 가 추가되어 diagram 의 channel/global/local 관계가 §2 channel resolution 으로 명시되었고, §17 opening 의 "MVP guide + post-MVP addendum" framing 이 active operator guide 정체성에 맞게 보정되었다. 이로써 본 항목의 `docs/OPERATOR_GUIDE_KR.md` 관련 deferred wording 은 모두 해소되었다 (broader docs hygiene 중 `docs/AI_HARNESS_TOOLSET_SCOPE.md`, `docs/roadmap/POST_MVP_PLAN.md`, `README.md` body 는 본 라운드에서 정합화 완료 — 위 해당 bullet 참조; 잔여 추적 대상은 `brief/` 관련 historical wording 한 항목이다).
- `brief/` vs `log/brief/BRIEF.md` 관련 framing (contract docs) — **3차 reconciliation 완료.** 본 backlog 항목의 1차 reconciliation 라운드에서 contract docs 가 `log/brief/BRIEF.md` 를 canonical 자리로 격상하고 root `brief/` 를 forbidden 으로 둔 framing 은, 2차 reconciliation 라운드에서 target product canonical 을 `<ProjectRoot>/brief/BRIEF.md` 로 옮기는 framing 으로 정정되었다. 본 라운드 (3차 reconciliation) 에서 그 2차 framing 도 정정되었다 — 현재 `docs/BRIEF_CONTRACT.md` 는 canonical Brief 를 `<ProjectRoot>/log/brief/BRIEF.md` (project-local, operator-local, source-control-excluded runtime artifact under `log/`) 한 자리로 두고 root `<ProjectRoot>/brief/` 를 rejected, user-home operator-local runtime root 도 rejected 로 명시한다. `docs/CHATLOG_CONTRACT.md` 는 `log/chatlog/current/resume.md` / `summary.md` 를 canonical 자리에서 demote 하여 failed intermediate / legacy migration source / deprecation candidate 로 분류한다 (분류 자체는 2차 / 3차 모두 동일). target persistent footprint 는 `<ProjectRoot>/log/` only — BRIEF / Chatlog / Evidence / Review 의 네 runtime artifact 트리는 모두 `log/` 아래 들어간다. 두 contract 의 정합 자체는 closeout 이며, 본 backlog 항목 status 줄의 (a)–(e) framing 도 그 갱신과 일치한다.
- `brief/` historical wording (roadmap docs) — **3차 reconciliation 라벨 적용 완료.** `docs/roadmap/GLOBAL_INSTALL_UPDATE_MODEL.md` §1 (3rd reconciliation 최상단 note), §6 Layer 4 superseded note, §9 BRIEF wording note, §11 clarified model 표현, §8 footprint contract; `docs/roadmap/SHARED_GLOBAL_INVOCATION_CONTRACT.md` 의 D7 Decision 줄 / Superseded note / BriefRoot 정의; `docs/roadmap/POST_MVP_PLAN.md` §3 / §4 / §5 / §10 의 BRIEF / canonical / routing wording; `docs/CHATLOG_CONTRACT.md` 의 current restore source 자리; `docs/OPERATOR_GUIDE_KR.md` §7b BF save / restore-offer 자연어 UX, §12b acceptance, §17 reviewer-verdict-가-아닌-artifact 목록; `README.md` §"Evidence and chatlog", §"Documentation map"; 모두 3차 reconciliation framing 으로 정정되었다. CLEAN_TARGET_SMOKE_CRITERIA.md 의 SC body assertion 자체는 본 라운드에서 변경되지 않았다 — primitive-behavior smoke 의 정의가 세 reconciliation 모두에서 동일하기 때문이다 (canonical Brief 가 `<ProjectRoot>/log/brief/BRIEF.md` 에 있는 상태). 1차 / 2차 framing 의 wording 잔재는 historical lineage 보존 목적의 superseded note / 3-step reconciliation note 안에서 그대로 보존되며, contract docs 와 충돌 시 contract docs 우선이다. canonical source-of-truth 는 `docs/BRIEF_CONTRACT.md` 와 `docs/CHATLOG_CONTRACT.md` 다.
- BF Level 3 기능 검증 — **재분류.** 이전 라운드의 source-repo dogfooding 검증은 `scripts/brief-init.ps1` / `scripts/brief-check.ps1` 라는 **source-side primitive 의 동작** 을 확인한 것이며, BF Level 3 capability (deterministic Brief maintenance / validation / stale warning / session-start guidance / restore-offer) 의 full feature completion 을 의미하지 않는다. 본 분류는 `docs/BRIEF_CONTRACT.md` §"BF Level — save/restore capability maturity" 와 정합이다. 검증 중 생성된 `log/brief/BRIEF.md` seed 와 `log/brief-validation/` fixture 의 정리는 operator 판단의 별도 cleanup 대상이며 본 항목 완료 조건이 아니다.

### Latest-judgment priority order

아래는 본 docs-debt 항목에 한정된 reading 가이드이며, 새 global precedence contract 가 아니다. backlog 항목은 design contract 가 아니라는 `docs/backlog/README.md` 의 규칙이 그대로 적용된다. 그 전제 위에서, 위 docs 중 어느 것이라도 현재 모델과 충돌하게 읽히면 다음 순서로 해석한다.

1. 현재 handoff / snapshot identity (해당 라운드의 packet)
2. `docs/roadmap/SHARED_GLOBAL_INVOCATION_CONTRACT.md`
3. `docs/roadmap/GLOBAL_INSTALL_UPDATE_MODEL.md`
4. `docs/roadmap/CLEAN_TARGET_SMOKE_CRITERIA.md`

### Candidate direction

- 위 docs 의 구 project-local copy model wording 을 현재 6-channel global stable runtime ToolRoot model 과 정합하도록 보정하거나, 명시적 "superseded by …" pointer 를 본문 상단에 단다.
- 보정 시 `SHARED_GLOBAL_INVOCATION_CONTRACT.md` / `GLOBAL_INSTALL_UPDATE_MODEL.md` 의 현재 model 정의를 기준으로 한다.

### Non-goals

- 본 항목은 backlog candidate 다. 즉각 docs 변경은 자동 승인되지 않는다.
- 위 docs 의 전체 prose rewrite / model 재정의 아님 — wording 정합성 보정, adoption-framing 절의 구조 정리, superseding pointer 정리 범위다.
- global runtime ToolRoot model 자체의 재정의 아님 (model 정의는 contract docs 가 source-of-truth).
- 본 항목은 controlled global materialization 자체의 blocker 가 **아니다** — materialization / smoke 이후 적절한 시점에 docs cleanup 으로 처리한다.
- 본 항목 implementation 은 별도 scoped goal 을 거친다.

---

## Aggregate digest reproducibility — install/update verification scope debt

- **Status**: candidate
- **Classification**: install / update automation 의 verification scope. global runtime ToolRoot channel 3 (`%USERPROFILE%\.claude\ai-harness-toolset\current`) payload 무결성 검증 방법의 정의에 관한 debt 다.

### Context

channel 3 payload 검증 시, 단일 aggregate digest 값으로 payload 전체 무결성을 한 번에 확인하려는 시도가 있었으나, 그 digest 를 산출한 알고리즘이 repo docs / scripts 어디에도 명문화되어 있지 않고 `current/` 안에 동행 manifest 도 없어 재현 / 검증이 불가능했다. 동일 payload 에 대해 서로 다른 산출 방식 (relpath:hash 라인 집계, content-only concat 등) 이 서로 다른 값을 내므로, 알고리즘이 고정되지 않으면 "expected digest" 는 verifiable 한 기준이 되지 못한다. 해당 라운드에서는 per-file SHA-256 비교 (`current/` vs source HEAD, 27/27 byte-identical) 라는 method-independent 방식으로 content equality 를 확인하여 우회했다.

### Candidate direction

- install / update automation 의 verification scope (`GLOBAL_INSTALL_UPDATE_MODEL.md` §1 의 automation 본체 scope 정의 참조) 에 payload 무결성 검증 방식을 명시적으로 포함한다. 다음 중 하나로 좁힌다.
  - (a) **deterministic aggregate digest algorithm 의 문서화** — 입력 파일 집합, 정렬 규칙, 경로 정규화, 줄바꿈 / BOM 처리, 해시 결합 순서를 명문화하고, 그 알고리즘으로 산출한 digest 를 `current/` 동행 manifest 에 기록한다.
  - (b) **per-file manifest** — aggregate digest 대신 relative path → SHA-256 의 명시적 목록을 manifest 로 두고, 검증은 파일 단위 비교로 수행한다.
- 어느 쪽이든 검증 알고리즘 / manifest schema 는 install metadata (`GLOBAL_INSTALL_UPDATE_MODEL.md` §5) 와 정합해야 한다.

### Non-goals

- 본 항목은 backlog candidate 다. 즉각 algorithm / manifest 도입은 자동 승인되지 않는다.
- install / update automation 본체 구현의 승인이 아니다 — `GLOBAL_INSTALL_UPDATE_MODEL.md` §7 sequencing (validation 먼저) 이 우선한다.
- digest 검증 linter / 자동 검사 tool 도입을 자동 승인하지 않는다.
- 본 항목 implementation 은 별도 scoped goal 을 거친다.

---

## Managed block marker detection — whole-line trim match algorithm

- **Status**: 완료 — `GLOBAL_ADOPTION_DECISION.md` §6 에 "Marker detection (counting rule)" sub-section 을 추가하여 marker counting 알고리즘을 whole-line trim match 로 명시. 후속 모든 분기 (0 개, 1 개, 여러 개, incomplete pair, malformed, nested) 가 본 정의에 binding.
- **Classification**: long-lived docs / contract precision (managed block apply policy 의 algorithm-level clarification).

### Context — false-positive incident

이전 global activation apply round 에서 `%USERPROFILE%\.claude\CLAUDE.md` 의 `AI_HARNESS_TOOLSET_GLOBAL` marker pair 가 BEGIN=2 / END=2 로 카운트되어 §6 의 "여러 개" 분기에 의해 fail-fast / manual-review 로 abort 되었다. 그러나 실제로는 managed block 이 **단 1 개** (BEGIN line 59 → END line 222) 였고, line 62 의 snippet body description prose 안에 "delimited by `<!-- BEGIN AI_HARNESS_TOOLSET_GLOBAL -->` and `<!-- END AI_HARNESS_TOOLSET_GLOBAL -->`" 라는 markdown inline code 형태로 marker text 가 literal 인용되어 substring count 가 2/2 로 나왔다.

근본 원인: §6 가 marker counting 알고리즘을 명시하지 않아 substring count 만 사용하는 naive scanner 가 inline literal 인용까지 marker 로 잡았다. snippet body 의 inline 인용은 intentional documentation (human reader 에게 marker 가 어떻게 생겼는지 보여주는 prose) 이므로 detection 에서 제외되어야 한다.

### Corrective closeout

- `GLOBAL_ADOPTION_DECISION.md` §6 의 "Recommended marker" 직후에 새 sub-section **"Marker detection (counting rule)"** 추가. valid BEGIN/END marker 의 정의를 **whole-line trim match** 로 명시:
  - line 의 leading / trailing ASCII whitespace 를 trim 한 결과가 정확히 `<!-- BEGIN AI_HARNESS_TOOLSET_GLOBAL -->` (또는 `<!-- END AI_HARNESS_TOOLSET_GLOBAL -->`) 와 일치하는 경우에만 valid marker 로 count.
  - markdown inline code spans (backticked), markdown fenced code blocks, prose / descriptive text 안의 literal 인용은 valid marker 가 아니며 **count 에 포함되지 않는다.**
  - substring count 만 사용하는 detection 은 정의에서 제외됨.
- §6 본문의 후속 분기 (0 개 / 정확히 1 개 / 여러 개 / incomplete / malformed / nested) 는 모두 본 whole-line counting rule 에 binding 되도록 decision-equivalent statement 를 함께 명시.
- snippet body 의 inline literal 인용 (description prose) 은 본 detection rule 에 의해 자연히 무시되므로 `snippets/CLAUDE_SNIPPET.md` / `snippets/AGENTS_SNIPPET.md` 본문 변경은 불필요.

### Non-goals

- 본 closeout 은 install / update automation 본체 구현을 자동 승인하지 않는다 (automation 본체에서 본 algorithm 을 implement 하는 작업은 별도 scoped goal).
- `scripts/` / `tests/` / `config/` 변경 아님.
- global / user filesystem mutation 아님.
- target project 변경 아님.

---

## Global instruction file path semantics — Codex vs Claude / forbidden `.claude\AGENTS.md`

- **Status**: 완료 — docs / snippet contract clarification 으로 정리. snippet 본문, README, `GLOBAL_ADOPTION_DECISION.md` §6, `GLOBAL_INSTALL_UPDATE_MODEL.md` §1 / §6 Layer 2 / §12 / §13, `CLEAN_TARGET_SMOKE_CRITERIA.md` §5 stop trigger / §6 non-goals, `snippets/claude-skills/ai-harness-review/SKILL.md` 의 install-path / forbidden-list wording 이 모두 path-explicit / dual-role-safe 형태로 정합화되었다. 실제 file 생성 / 삭제는 본 라운드에서 발생하지 않았다 (docs / snippet only).
- **Classification**: long-lived docs hygiene + snippet safety contract.

### Context

이전 라운드에서 controlled global materialization apply 도중 `%USERPROFILE%\.claude\AGENTS.md` 가 잘못 생성된 incident 가 발생했다. 그 path 는 어떤 agent (Claude Code, Codex CLI 등) 의 global instruction location 도 아니다. 사실 관계:

- Claude Code 의 user-global instruction path 는 `%USERPROFILE%\.claude\CLAUDE.md` 다.
- Codex CLI 의 user-global instruction path 는 `%USERPROFILE%\.codex\AGENTS.md` 이고, `CODEX_HOME` 환경변수가 설정되어 있으면 `%CODEX_HOME%\AGENTS.md` 다.
- 동일 Codex user-global scope 에서 `AGENTS.override.md` (예: `%USERPROFILE%\.codex\AGENTS.override.md`) 가 존재하면 `AGENTS.md` 보다 우선한다.
- `%USERPROFILE%\.claude\AGENTS.md` 는 valid destination 이 아니며 어느 agent 도 그 path 를 load 하지 않는다.

기존 repo docs / snippets 는 "global `AGENTS.md`" 같은 generic wording 만 사용했기 때문에, 운영자 또는 AI 가 이를 `.claude\AGENTS.md` 로 잘못 해석할 risk 가 있었다. 또한 두 snippet 의 opening 이 각각 "for Claude Code" / "for Codex CLI" 로 단정하여, 같은 agent 가 operator / reviewer / auditor / supervisor 등 다른 role 로 작동할 때 reviewer independence 가 약화될 위험이 있었다.

### Corrective closeout

본 라운드에서 다음을 정합화했다.

- **Snippet path explicitness.** `snippets/CLAUDE_SNIPPET.md` 와 `snippets/AGENTS_SNIPPET.md` 의 "Adoption destination" 절을 새로 추가하여 valid destination path 를 명시 enumerate 하고, `%USERPROFILE%\.claude\AGENTS.md` 가 forbidden 임을 명시.
- **Snippet dual-role safety.** 두 snippet 의 "Role neutrality" 절을 신설. loaded agent 가 operator / reviewer / auditor / supervisor 어느 role 이든 무관하게 same payload 를 load 하며, role-specific 동작 (BF save trigger, restore-offer, `review-cycle.ps1` execution discipline) 은 operator role 에서만 적용된다는 점을 명시. reviewer 는 artifact evidence 만으로 verdict 를 형성하고 operator report 를 evidence 대신 받아들이지 않는다는 점, snippet 안의 어떤 wording 도 force accept / approve, reviewer independence 약화, 또는 whole-file overwrite 를 허용하지 않는다는 점을 명시.
- **Snippet forbidden-list path enumeration.** 두 snippet 의 "Forbidden in this toolset" 절에서 generic 표현을 path-explicit 으로 교체하고, `%USERPROFILE%\.claude\AGENTS.md` 의 생성 금지를 별도 bullet 으로 추가.
- **Roadmap docs path enumeration.** `GLOBAL_ADOPTION_DECISION.md` §6 Update policy 에 path table 추가 (Claude project / Claude user-global / Codex project / Codex user-global default / Codex user-global with `CODEX_HOME` / Codex user-global override / Forbidden). `GLOBAL_INSTALL_UPDATE_MODEL.md` §1 / §6 Layer 2 / §12 / §13 의 generic "global `CLAUDE.md` / `AGENTS.md`" wording 을 path-explicit 으로 교체. Layer 2 description 에 user-owned managed-block instruction vs tool-payload 분류와 forbidden path 명시 추가.
- **Smoke criteria stop trigger 확장.** `CLEAN_TARGET_SMOKE_CRITERIA.md` §5 stop trigger 와 §6 non-goals 에서 `~/.claude/` 만 watch 하던 표현을 `%USERPROFILE%\.codex\` / `%CODEX_HOME%` 까지 확장. `%USERPROFILE%\.claude\AGENTS.md` 의 신규 생성도 erroneous mutation 으로 명시 분류.
- **Skill install-path wording.** `snippets/claude-skills/ai-harness-review/SKILL.md` 의 adoption path 안내에서 user-global Claude skills directory 의 Windows 표기 (`%USERPROFILE%\.claude\skills\ai-harness-review\SKILL.md`) 를 명시. "Out of scope" 의 global file mutation 항목도 path-explicit 으로 교체.
- **README.md.** "Snippets for CLAUDE.md / AGENTS.md" 절에 valid destination path 와 forbidden path 를 명시. snippet 이 dual-role safe 라는 점을 명시.

### Stale wording 잔존 확인

본 closeout 이후 다음 stale 표현은 repo 에서 valid 한 destination 으로 더 이상 사용되지 않는다.

- "global `AGENTS.md`" 만 단독으로 사용한 표현 — path-explicit enumeration 으로 교체되었다. 단, snippet / docs 안의 historical / forbidden / generic 한 언급 (예: forbidden path 를 명시할 때의 reference, 또는 path enumeration 안의 entry) 은 정합 wording 으로 그대로 유지된다.
- `%USERPROFILE%\.claude\AGENTS.md` 가 valid 임을 시사하는 표현 — 본 closeout 이후 모든 reference 는 "forbidden" / "valid destination 아님" 으로만 등장한다.
- Whole-file overwrite of global `CLAUDE.md` / `AGENTS.md` 가 허용된다고 읽힐 wording — repo 본문 어디에도 잔존하지 않는다 (모든 mention 은 "forbidden" 으로 명시).

### Non-goals

- 본 closeout 은 실제 `%USERPROFILE%\.codex\AGENTS.md`, `%USERPROFILE%\.claude\CLAUDE.md`, 또는 어느 global instruction file 의 생성 / 변경을 자동 승인하지 않는다. managed-block insert / replace 는 별도 explicit user-approved scope 다.
- 본 closeout 은 install / update automation 본체 구현을 자동 승인하지 않는다.
- 본 closeout 은 target project 변경 / log/ 정리 / snapshot 생성 / commit / push 어느 것도 자동 승인하지 않는다.
- 본 closeout 은 docs / snippet wording 정합화로 한정된다.

---

## `timeoutSeconds` enforcement decision debt

- **Status**: candidate
- **Classification**: reviewer config 의 key semantics. `config/reviewer.json` 의 `timeoutSeconds` 가 현재 metadata-only / unenforced 인 상태를 어떻게 정리할지에 관한 decision debt 다.

### Context

`config/reviewer.json` 의 `timeoutSeconds` (현재 값 `300`) 는 `review-prepare.ps1` 가 `meta.json` 의 `reviewerConfig.timeoutSeconds` 로 기록할 뿐, 어떤 script 도 다시 읽어 적용하지 않는다 — `review-run.ps1` / `review-cycle.ps1` 의 `Invoke-CodexExec` 는 Codex CLI 를 process timeout 없이 실행한다. 즉 `timeoutSeconds` 는 Codex review process 를 bound 하지 않는다. 각 key 의 nominal 의미·읽히는 위치·enforcement 상태는 `config/reviewer.schema.json` 에 description 으로 문서화되었고, 현재 status 표는 `docs/REVIEWER_CONFIG_POLICY.md` 의 "Config key schema and enforcement status" 절에 정리되었다. `timeoutSeconds` 는 review quality guarantee 도, Claude Code harness tool timeout 도, background-conversion control 도 아니다 — 별개 layer 다.

### Decision boundary

다음 implementation goal 은 아래 3 후보 중 **정확히 1 개** 만 채택한다. 본 backlog 항목은 어느 것도 결정하지 않는다.

- **(a) enforce** — `Invoke-CodexExec` 에 process timeout 을 wiring 한다. 초과 시 Codex process 를 종료하고, 그 run 을 `docs/REVIEW_RESULT_CONTRACT.md` 의 failed/incomplete record 경로 (result.json 미생성, run-id 디렉터리 보존, fresh run-id 재실행) 로 떨어뜨린다. 채택 시 `REVIEW_RESULT_CONTRACT.md` 에 timeout → incomplete result semantics 를 명시하는 doc 변경이 함께 필요하다.
- **(b) demote** — `timeoutSeconds` 를 명시적 metadata-only 로 강등하고, schema / policy 문서의 현재 wording 을 그대로 두되 "기록 전용, runtime 미enforce" 를 canonical 상태로 확정한다. script / config 값 변경 없음.
- **(c) remove** — `config/reviewer.json` / `templates/review-meta.json` / `meta.json` reviewerConfig schema 에서 `timeoutSeconds` 를 제거한다. `review-prepare.ps1` 의 해당 read/write 도 제거된다.

### Cross-reference

- `config/reviewer.schema.json` — 각 reviewer config key 의 의미와 enforcement 상태.
- `docs/REVIEWER_CONFIG_POLICY.md` "Config key schema and enforcement status" / "`timeoutSeconds` status".
- `docs/REVIEW_RESULT_CONTRACT.md` — 현재 failed/incomplete record 를 "parsing 실패 또는 Codex 실패" 로 정의하며 timeout 을 별도로 언급하지 않는다. 후보 (a) 채택 시에만 timeout → incomplete semantics 의 doc 보강이 필요하다.

### Non-goals

- 본 항목은 backlog candidate 다. (a) / (b) / (c) 중 어느 것도 자동 승인되지 않는다.
- `config/reviewer.json` 의 `timeoutSeconds` 값 변경 아님.
- review runtime behavior 변경 아님 — 본 항목 자체는 doc / schema 기록까지만.
- Claude Code harness tool timeout / background-conversion 동작 변경 아님 — 별개 layer.
- 본 항목 implementation 은 별도 scoped goal 을 거친다.

---

## Channel 3 smoke validation closeout (CH3-A / CH3-B / CH3-C)

- **Status**: 완료 — `docs/roadmap/CLEAN_TARGET_SMOKE_CRITERIA.md` §2A (I) 에 reaffirming-round note 가 추가되어 CH3-A / CH3-B / CH3-C 가 후속 라운드에서 동일하게 PASS 로 관찰되었음이 명시. CH3-B 의 verifier-half (`meta.json` 의 `toolRoot` / `projectRoot` binding + `review-verify` default + `-RequireResult` PASS + valid verdict vocabulary) 도 함께 충족. CH3-C 의 isolation invariant (fixture/`log/` only, source repo + global `current/` payload + forbidden path absent + env var 모두 unchanged) 도 동일 round 에서 관찰. CH3-D 는 `CLEAN_TARGET_SMOKE_CRITERIA.md` §2A (III) Future deferred items 에 따라 **여전히 deferred** 다.
- **Classification**: smoke observed-status update. criteria 본문에 commit hash / fixture path / run-id 를 박지 않고 per-run evidence 위임 (Long-lived docs commit hash hygiene 항목과 정합).

### Context

전 라운드들에서 다음이 관찰되었다 (criteria binding 이 아니라 observed status):

- **CH3-A** — clean target fixture (`-ToolRoot` 미명시, `AI_HARNESS_TOOL_ROOT` unset, source markers 부재, `.ai-harness/` 부재) 에서 `brief-init.ps1` 가 `Get-ToolRoot` 를 channel 3 (`%USERPROFILE%\.claude\ai-harness-toolset\current`) 로 resolve. seeded `<fixture>/log/brief/BRIEF.md` 가 channel 3 의 `templates/brief/BRIEF.md` 와 byte-identical (SHA-256 비교).
- **CH3-B** — 동일 clean target 조건에서 `review-cycle.ps1` 가 channel 3 로 resolve. `meta.json.toolRoot` 가 channel 3 경로에 bind, `meta.json.projectRoot` 가 fixture path 에 bind, `meta.json.projectLogRoot` 가 fixture `log/` 에 bind. `review-verify` default + `-RequireResult` 모두 PASS, `result.json.verdict` 가 `yes` / `no` / `yes with risk` 중 하나.
- **CH3-C** — 위 두 case 의 runtime artifact 가 fixture `log/` 트리 안에만 생성되고, source repo working tree, global `current/` 28-file aggregate digest, `%USERPROFILE%\.claude\AGENTS.md` (forbidden, absent), `%USERPROFILE%\.claude\CLAUDE.md` (managed-block 외부 content), Codex AGENTS.md (managed-block 외부 content), `AI_HARNESS_TOOL_ROOT` / `CODEX_HOME` env var 모두 unchanged. fixture 에 `.ai-harness/`, `scripts/`, `config/`, `templates/`, `snippets/` payload 생성 없음.

본 closeout 은 위 관찰을 `CLEAN_TARGET_SMOKE_CRITERIA.md` §2A (I) 의 reaffirming-round note 로 doc 화한 것만이다. 정식 criteria 화 (Pre / Action / Pass / Fail / Evidence 형식 편입), CH3-D 실행, install / update automation 본체 구현, evidence archive 생성 어느 것도 자동 승인하지 않는다.

CH3-B reaffirming round 의 driver-failure 사례는 본 backlog 의 "PowerShell smoke invocation quoting hardening" 항목 §Context 의 추가 incident reference 로 분리 기록되었다.

### Non-goals

- 본 closeout 은 install / update automation 본체 구현을 자동 승인하지 않는다.
- **CH3-D (incomplete-payload negative guard) 의 실행을 자동 승인하지 않는다** — `CLEAN_TARGET_SMOKE_CRITERIA.md` §2A (III) Future deferred items 에 deferred 항목으로 유지되며, 별도 scoped goal 의 explicit approval 이 필요하다. 본 closeout 이 CH3-D 의 PASS 또는 status change 를 의미하지 않는다.
- `CLEAN_TARGET_SMOKE_CRITERIA.md` §2A 의 정식 criteria 화 (Pre / Action / Pass / Fail / Evidence 형식 편입) 는 본 closeout 작성 시점에는 deferred 였으나, 후속 round 에서 §2A (II) Formalized criteria 로 편입 완료되었다 (CH3-A / CH3-B / CH3-B' / CH3-C). 본 closeout 자체는 그 정식 criteria 의 implementation / automation 을 추가로 자동 승인하지 않는다. CH3-D 는 §2A (III) Future deferred items 에 여전히 deferred 다.
- smoke evidence preservation convention 결정 (runbook-only / helper-script / archive manifest 중 어느 후보) 을 자동 승인하지 않는다 — 별도 backlog 항목.
- target fixture cleanup, evidence archive 생성, %TEMP% 정리 어느 것도 자동 승인하지 않는다.
- repo working tree 의 commit / push 를 의미하지 않는다.
- 본 closeout 본문에 execution HEAD / fixture path / run-id 같은 per-run 세부를 박지 않는다 (Long-lived docs commit hash hygiene 항목과 정합).

---

## Review result wrapper / fence artifact hygiene

- **Status**: candidate (future hardening). 즉시 implementation 승인 아님.
- **Classification**: review subsystem 의 `result.md` artifact hygiene. canonical contract (`docs/REVIEW_RESULT_CONTRACT.md` 의 `## Verdict` shape) 자체의 변경이 아니라, Codex CLI `--output-last-message` 가 reviewer 의 last message 본문을 그대로 dump 하는 경로에서 발생할 수 있는 wrapper / fence rendering ambiguity 의 후속 정리에 대한 debt 다.

### Observed phenomenon

- Codex CLI 가 read-only sandbox 안에서 자체 write tool 호출이 reject 된 경우, reviewer 가 final response 본문에 result content 를 markdown fenced code block (` ```markdown ... ``` `) 으로 wrap 해 보고할 수 있다.
- `--output-last-message <path>` flag 가 그 wrapper 를 포함한 last message 전체를 그대로 파일로 dump 하므로, result.md 의 첫 비공백 줄이 ` ```markdown ` 가 되고 `## Verdict` 가 fence 안의 plain text 로 등장한다.

### Current impact

- canonical contract (`## Verdict` heading + 다음 첫 비공백 줄 lowercase 일치) 의 machine-parseable check 는 통과한다 — `scripts/review-verify.ps1` 의 verdict shape 검증은 fence-bounded `## Verdict` 도 매칭한다.
- 본 candidate 작성 시점까지 발생 사례는 `log/review/step3-manifest-marker-anchor-2026-05-18/pass-02/result.md` 한 건. 동일 round 의 pass-01 result.md 는 wrapper 없는 정상 shape 였다.
- 본 항목은 어떤 commit / push 의 blocking risk 가 아니다 — 직전 라운드 (`Anchor Step 3 payload manifest and marker minimum contract`) 의 commit 도 wrapper hygiene 과 무관하게 진행되었다.

### Risk

- **human-readable markdown rendering 의 ambiguity**: viewer 에서 fence 안의 `## Verdict` 는 heading 으로 렌더링되지 않고 plain text 로 보이며, fence 의 ` ```markdown ` line 이 첫 줄에 노출된다. 사람 reviewer 가 result.md 를 시각적으로 빠르게 검토할 때 verdict heading 의 발견성이 낮아진다.
- **machine-parseable strictness 와 human-readable rendering 의 mismatch**: `review-verify` 는 통과하지만 result artifact 의 hygiene 은 fence 가 stripped 된 상태가 더 안전하다 — 향후 다른 lint / contract docs 가 result.md 의 top-level heading 위치를 가정하면 wrapper 가 있는 result.md 가 unexpected reading 을 유발할 수 있다.
- **재현 조건의 좁음**: 본 wrapper 발생은 Codex CLI 가 자체 file-write tool 호출을 sandbox 로 reject 한 케이스에 한정되며, 일반 review 호출 경로에서는 발생하지 않는다. 단 재현 조건이 sandbox / tool policy 설정에 의존하므로 미래에 발생률이 변할 수 있다.

### Candidate direction

후보는 상호 배타가 아니며 (X) (Y) (Z) 중 하나 또는 복수 채택이 가능하다. 본 backlog 단계에서는 어느 것도 결정하지 않는다.

- **(X) wrapper stripping in `scripts/review-run.ps1`** — `--output-last-message` dump 후, result.md 의 시작이 ` ``` ` fence 이고 마지막 비공백 줄이 닫는 fence 면 두 fence 라인을 제거한 normalized result 를 write. fence 의 info string (예: `markdown`) 도 함께 제거. fence-pair 검증 / nested fence 처리 / fence 없는 정상 case 의 통과 조건을 명시해야 한다.
- **(Y) reviewer prompt / CLI argument 조정** — Codex CLI 가 reject 된 own write 의 fallback 으로 wrapper 를 쓰지 않도록 prompt / invocation 단계에서 안내. 단 CLI 의 sandbox behavior 변화에 의존하므로 deterministic 보장이 어렵다.
- **(Z) `scripts/review-verify.ps1` 에 lint-only warning mode 추가** — verdict shape PASS 는 그대로 두고, result.md 의 첫 비공백 줄이 fence 이면 warning 보고 (verdict shape failure 와는 분리; commit 의 blocking 아닌 hygiene advisory).

### Cross-reference

- `docs/REVIEW_RESULT_CONTRACT.md` — canonical `## Verdict` shape contract. 본 항목은 이 contract 의 변경 / 약화가 아니다.
- `scripts/review-run.ps1` — `--output-last-message` 사용 위치 (wrapper 발생 경로).
- `scripts/review-verify.ps1` — verdict shape 검증 위치 (현재 wrapper 가 있어도 통과; (Z) 후보의 lint-only warning 도입 위치).

### Non-goals

- 본 항목은 candidate 다. (X) / (Y) / (Z) 어느 후보 implementation 도 자동 승인하지 않는다.
- canonical `## Verdict` shape contract 의 변경 / 약화가 아니다.
- 본 backlog entry 의 존재로 `scripts/review-run.ps1` / `scripts/review-verify.ps1` / `templates/review-result.md` 본문이 변경되지 않는다.
- past round 들의 result.md 를 retroactive 하게 normalize 하는 작업도 자동 승인하지 않는다 — past round artifact 는 write-once 며 별도 scoped goal 의 대상이 아니다.
- 본 항목 implementation 은 별도 scoped goal 을 거친다.

---

## Path normalization edge-case hardening

- **Status**: candidate (future hardening). 즉시 implementation 승인 아님.
- **Classification**: install-pipeline 의 `-InstallArea` path normalization invariant 의 edge-case coverage. STEP3 guide §16.5 (`install.json.toolRoot` = cache absolute path) contract 의 robustness 보강에 관한 debt 다.

### Context

Step 3 git-url minimum source acquisition round (commit `8eecae0`) 에서 `metadata.toolRoot` 가 relative `-InstallArea` 입력 시 relative path 로 기록되던 §16.5 contract drift 가 수정되었다. `scripts/lib/install-pipeline-core.ps1` 의 5 path / dir helper (`Get-InstallPipelineSourceCacheDir`, `Get-InstallPipelineCurrentDir`, `Get-InstallPipelineMetadataPath`, `Get-InstallPipelineManifestPath`, `Get-InstallPipelineMarkerPath`) 모두 `Join-Path` 결과를 `[System.IO.Path]::GetFullPath()` 로 wrap 하고, `Invoke-InstallMaterialization` 진입 직후 local `$InstallArea` 도 동일 normalize 적용. 신규 regression `AC-IP-GITURL-TOOLROOT-ABS-1` 가 corrective scope 의 대표 case 를 검증한다.

본 regression 의 검증 범위:

- 대표 case: `./<leaf>` (현재 디렉터리 기준 leaf-only) relative path 입력 시 git-url `install` 의 `metadata.toolRoot` 가 absolute `<absArea>/source-cache` path 임을 확인.

### Remaining edge cases (현 regression 범위 밖)

본 backlog 가 후속 hardening 대상으로 보존하는 edge case enumeration:

- **`../` 포함 relative path** — `..` segment 가 포함된 `-InstallArea` (예: `../sibling-area`). `[System.IO.Path]::GetFullPath()` 가 일반적으로 처리하나, fixture 시점의 cwd 의존성 검증이 필요.
- **drive-relative path** — Windows 의 drive-relative form (예: `X:foo` — drive X 의 current directory 기준 `foo`). 운영 환경에서 흔치 않으나 동작 invariant 미검증.
- **UNC path** — `\\server\share\...` 형태. `GetFullPath` 가 UNC 를 그대로 보존하지만 cache directory / git operations 의 UNC 동작 invariant 미검증 (e.g., authentication, network drop 시 fail-fast 보장).
- **symlink / junction** — `-InstallArea` 가 NTFS symlink / directory junction 인 경우. `GetFullPath` 는 symlink 를 resolve 하지 않으나 git operations 의 동작 변동 가능성 (e.g., junction loop, locked symlink target) 미검증.
- **helper-level absolute path assertion 확대** — 현 regression 은 `metadata.toolRoot` 만 검증. 나머지 4 helper (`Get-InstallPipelineCurrentDir`, `Get-InstallPipelineMetadataPath`, `Get-InstallPipelineManifestPath`, `Get-InstallPipelineMarkerPath`) 의 return value 가 absolute path 임을 직접 assert 하는 helper-level regression 부재.

### Candidate direction

후보는 상호 배타 아니며 일부 또는 전부 채택 가능하다. 본 backlog 단계에서는 결정하지 않는다.

- **(X) `tests/install-pipeline.Tests.ps1` 에 edge-case regression 추가** — `AC-IP-GITURL-TOOLROOT-ABS-2/3/...` 형태로 enumerate. `../` 와 helper-level assertion 은 TestDrive 안에서 cover 가능; UNC / symlink / junction 은 Windows admin / dev mode 요구로 fixture 제약 명시.
- **(Y) `docs/roadmap/global-install-update/STEP3_INSTALL_UPDATE_DECISION_GUIDE.md` §16.5 / §16.7 에 supported / unsupported InstallArea path shape 명시** — supported shape (relative `./<leaf>`, `../<sibling>`, absolute drive path) vs unsupported shape (UNC unless authenticated, symlink with implicit resolve 의존성) 의 contract 정합화.
- **(Z) unsupported path fail-fast contract 검토** — 명시적으로 unsupported 한 shape 에 대해 entry 또는 lib 에서 fail-fast detection 추가 여부. 본 단계에서는 implementation 결정 아님.

### Non-goals

- 본 backlog entry 의 존재로 `tests/install-pipeline.Tests.ps1`, `scripts/install-pipeline.ps1`, `scripts/lib/install-pipeline-core.ps1`, STEP3 guide §16 본문 어느 것도 자동 변경되지 않는다.
- `[System.IO.Path]::GetFullPath()` 외 별도 normalization library / canonicalization helper 의 도입을 자동 승인하지 않는다.
- actual global / user filesystem 의 path 검증 (e.g., `%USERPROFILE%\.claude\ai-harness-toolset\current` 의 path shape audit) 어느 것도 자동 승인하지 않는다.
- 본 항목 implementation 은 별도 scoped goal 을 거친다.

---

## Review subsystem no-exec / no-write reviewer contract

- **Status**: candidate (future hardening). 즉시 implementation 승인 아님.
- **Classification**: review subsystem 의 reviewer role boundary 명문화에 관한 contract debt 다. canonical `## Verdict` shape contract (`docs/REVIEW_RESULT_CONTRACT.md`) 의 변경이 아니라, reviewer 가 어떤 actions 를 수행하지 **않는지** 의 명시적 framing 의 후속 정리.

### Core framing

본 후보 backlog 가 명문화 후보로 제안하는 reviewer role boundary:

- Codex reviewer 는 **read-only reasoning reviewer** 다.
- Codex reviewer 는 **Pester / compile / script execution 을 수행하지 않는다**. mutating validation (예: Pester suite run, `scripts/verify-ps1.ps1` 실행, git operations) 은 reviewer 의 책임이 아니다.
- Codex reviewer 는 **`result.md` 를 write tool 로 직접 작성하지 않는다**. `result.md` 의 on-disk materialization 은 별도 mechanism (`scripts/review-run.ps1` 의 `--output-last-message` flag, 또는 후속 deterministic local script) 의 책임이다.
- **validation 은 Claude Code 가 local operator 로 실행한다.** Pester / verify-ps1 / fixture commands 모두 operator 가 review-run 호출 이전에 (또는 이후에) 실행하고 그 결과를 input.md 의 Context / Validation section 에 evidence 로 첨부한다.
- reviewer 는 **operator-provided validation evidence + diff + docs contract + test coverage** 를 검토 대상으로 한다. reviewer 가 그 evidence 의 truthfulness 를 cross-execute 하지는 않는다 — operator 의 정직한 reporting 에 의존한다.
- `result.md` artifact materialization 은 deterministic local script 가 담당하는 방향으로 정리한다 (현재는 Codex CLI `--output-last-message` 가 reviewer 의 final message 를 그대로 file 로 dump 하는 형태 — 이 contract 가 wrapper/fence hygiene 항목 의 후속 보강과도 연관).

### Context

Step 3 git-url round (commit `8eecae0`) 의 5 review pass 에서 Codex reviewer 가 반복적으로 다음 note 를 raise 했다:

- pass-01 / pass-02 / pass-03: 일부 pass 의 result.md 에서 Codex 가 stdout-only response 로 verdict 를 보고 (sandbox 가 write tool 호출 reject).
- pass-04 / pass-05: `scripts/verify-ps1.ps1` 또는 mutating Pester 의 직접 재실행이 sandbox policy 로 차단됨을 명시.

이 note 들은 **commit risk 가 아니다** — operator 가 별도로 verify-ps1 + Pester 를 실행하여 evidence 를 보강했고, 본 round 의 5 pass 모두 그 evidence 위에 verdict 가 안정적으로 도출되었다. 그러나 매 round 마다 동일 note 가 raised 되는 것은 **reviewer role boundary 가 contract 로 명문화되어 있지 않다** 는 운영 신호다.

이전 backlog 항목 "Review result wrapper / fence artifact hygiene" 과 본 항목의 관계:

- wrapper / fence hygiene 항목은 `result.md` artifact 의 **on-disk shape / rendering** 의 후속 정리 (Codex sandbox 가 write tool 을 reject 했을 때 fenced wrapper 가 발생할 수 있는 narrow scenario).
- 본 no-exec / no-write 항목은 더 상위의 **reviewer role boundary** — reviewer 가 어떤 actions 를 수행하지 않는다는 contract 자체.
- 두 항목은 연관되어 있지만 단일 항목으로 합치지 **않는다**. wrapper hygiene 은 artifact-level fix candidate; 본 항목은 contract-level role definition candidate. 후속 scoped goal 에서 둘이 함께 다뤄질 수는 있으나 backlog 단계에서는 분리 보존.

### Candidate direction

후보는 상호 배타 아니며 일부 또는 전부 채택 가능하다. 본 backlog 단계에서는 결정하지 않는다.

- **(P) `docs/REVIEW_RESULT_CONTRACT.md` 에 no-exec / no-write reviewer role 명문화** — "reviewer 는 read-only reasoning reviewer 이며 mutating commands 를 실행하지 않고 `result.md` 를 write tool 로 작성하지 않는다" framing 의 추가. 후속 sub-section 으로 operator-provided validation evidence 의 형식 명시.
- **(Q) reviewer prompt / `snippets/claude-skills/ai-harness-review/SKILL.md` 문구에서 direct execution / direct write expectations 제거** — 현재 SKILL.md 에 reviewer 가 `Invoke Codex CLI exactly once` 등 implementation 단계 wording 이 포함되어 있다면, reviewer 의 role 이 "reasoning" 임을 분명히 하는 wording 으로 정리.
- **(R) `scripts/review-run.ps1` 또는 review input contract 에 operator-provided validation evidence 형식 lint** — input.md 의 Context / Validation section 에 "Pester N/N PASS", "verify-ps1 PASS", "git diff --check clean" 같은 evidence 가 포함되어 있는지의 lint-only check (성공 / 실패의 verdict 검증과는 분리; commit blocking 아님).

### Cross-reference

- `docs/REVIEW_RESULT_CONTRACT.md` — canonical `## Verdict` shape contract. 본 항목의 (P) 후보 implementation 위치.
- `scripts/review-run.ps1` — Codex CLI invocation (`--ask-for-approval never --sandbox read-only --output-last-message`). 본 항목의 (R) 후보 implementation 위치.
- `scripts/review-input-verify.ps1` — input.md shape validation. 본 항목의 (R) lint 후보 implementation 위치.
- `snippets/claude-skills/ai-harness-review/SKILL.md` — reviewer skill 의 자연어 trigger / 절차. 본 항목의 (Q) 후보 implementation 위치.
- `templates/review-input.md` — input.md template. 본 항목의 (R) lint 후보의 evidence section 의 baseline.
- "Review result wrapper / fence artifact hygiene" backlog 항목 — 본 항목의 sibling. wrapper hygiene 은 artifact-level, 본 항목은 contract-level role definition.

### Non-goals

- 본 항목은 candidate 다. (P) / (Q) / (R) 어느 후보 implementation 도 자동 승인하지 않는다.
- canonical `## Verdict` shape contract 의 변경 / 약화가 아니다.
- 본 backlog entry 의 존재로 `scripts/review-run.ps1` / `scripts/review-verify.ps1` / `scripts/review-input-verify.ps1` / `templates/review-result.md` / `templates/review-input.md` / `snippets/claude-skills/ai-harness-review/SKILL.md` 본문이 변경되지 않는다.
- Codex reviewer 의 CLI invocation arguments (`--ask-for-approval`, `--sandbox`, `--output-last-message` 등) 의 변경을 자동 승인하지 않는다.
- `result.md` writer ownership 의 변경 implementation (예: Codex 가 작성 → local script 가 작성) 을 자동 승인하지 않는다 — 본 backlog 는 framing direction 의 후보 기록.
- past round 들의 result.md / input.md 를 retroactive 하게 normalize 하는 작업도 자동 승인하지 않는다 — past round artifact 는 write-once 며 별도 scoped goal 의 대상이 아니다.
- 본 항목 implementation 은 별도 scoped goal 을 거친다.
