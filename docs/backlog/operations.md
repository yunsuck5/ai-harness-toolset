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

- **Status**: scope-defined; implementation candidate decision (R / S / W; §Decision boundary 참조) 는 별도 scoped goal 로 deferred.
- **Classification**: Claude Code local operator → Codex reviewer handoff 경로의 CLI invocation reliability 문제. ChatGPT Web review hand-off / packet packaging 편의 작업 (예: snapshot zip path-preserving 등) 과는 별개의 영역이다. 본 항목은 운영자 머신 위에서 PowerShell 이 lifecycle script 를 호출하는 단계 한 곳을 다룬다.

### Context

SC5 rerun 의 첫 시도 (suite `ahts-smoke-sc5\20260514T024655Z`) 에서, smoke driver 가 `review-cycle.ps1` 를 `Start-Process -ArgumentList <array>` 로 호출하면서 multi-word substitution 값 (`-Context 'Clean target smoke verification of D6 ...'`) 의 quoting 을 PowerShell 5.1 의 array 형태가 자동 보존하지 않아, `'of'` 가 positional argument 로 거부되었다 (`A positional parameter cannot be found that accepts argument 'of'`). parser 단계에서 종료되어 Codex 호출 / run-dir 생성 / fixture mutation 모두 발생하지 않았고, SC7 invariant 는 hold 했다.

본 incident 는 smoke contract failure 가 **아니다** — criteria 의 prescribed invocation 자체는 정상이며, 두 번째 시도 (suite `ahts-smoke-sc5\20260514T024818Z`) 에서 manually-quoted single-string command line 으로 동일 invocation 을 통과시켰다 (verdict `yes`). 그러나 smoke 의 반복적 / 후속 실행에서 driver 의 quoting 규약이 매번 수동으로 재현되어야 한다는 점은 fragility 다.

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

## Smoke evidence preservation

- **Status**: candidate

### Context

본 라운드의 smoke evidence 는 `%TEMP%\ahts-smoke\<utc>\` 및 `%TEMP%\ahts-smoke-sc5\<utc>\` 아래에 저장되었다. OS / disk-cleanup utility 가 `%TEMP%` 를 정리할 경우 evidence 가 소실될 수 있다. evidence 는 본 source repo 안에 두지 않는 것이 원칙 (bulky binary, transient runtime data) 이지만, 중요 smoke run 의 evidence 가 round 이후에도 참조 가능해야 할 시점이 있다.

### Candidate direction

- repo-external archive convention 을 둔다. 위치 후보 — `<USERPROFILE>\ai-harness-evidence\<utc>\` 또는 평행한 외부 path. archive 포맷은 결정론적 zip / tar 등.
- archive 시점은 운영자 명시적 trigger. 자동 archive 는 본 backlog 항목이 제안하지 않는다. CLI helper (예: `tools/archive-smoke-evidence.ps1`) 의 도입 여부 / 위치는 implementation 단계 결정.
- bulky evidence 는 default 로 source repo 안에 두지 않는다. small per-SC summary file (예: `summary/SUITE_REPORT.md` 의 sanitized snippet) 만 별도 scoped 절차로 repo 에 인용할 수 있으되, raw transcript / run-dir 은 외부 archive 로 보관.

### Non-goals

- 본 backlog 항목 자체는 어떤 구현도 자동 승인하지 않는다.
- evidence 의 자동 retention / 자동 archival / 자동 cleanup 도입하지 않는다.
- `docs/EVIDENCE_CONTRACT.md` 의 변경 아님 (별도 scoped change).
- bulk evidence 의 source-repo 채택 아님.
- 본 항목 implementation 은 별도 scoped goal 을 거친다.
