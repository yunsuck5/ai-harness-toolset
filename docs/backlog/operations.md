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

## Project-local copy model docs vs global stable runtime ToolRoot model

- **Status**: candidate
- **Classification**: long-lived docs hygiene. global runtime ToolRoot 전환 (6-channel stable resolution; latest commits `f37c91c` / `e699c07` / `e9f2a00` 계열) 이후, 일부 docs 가 아직 구 project-local `.ai-harness/` copy model 기준 wording 을 유지하고 있어 부분 독해 시 두 모델이 혼동될 수 있다.

### Context

global stable runtime ToolRoot 모델로의 전환이 snippets / skill / resolution docs 에는 반영되었으나, 다음 docs 는 구 project-local copy model 기준을 그대로 유지하고 있다.

- `docs/AI_HARNESS_TOOLSET_SCOPE.md` — §"Source repo vs target project payload" 가 `config/` / `scripts/` / `snippets/` / `templates/` 를 target project root 의 `.ai-harness/` payload 로 copy 하는 구 MVP / project-local model 을 설명한다. 이는 현재 `%USERPROFILE%\.claude\ai-harness-toolset\current` (channel 3) 판단의 **primary source-of-truth 로 쓰면 안 된다**. (단, `docs/backlog/README.md` 의 탐색 규칙은 여전히 본 문서를 contract 우선순위 목록에 포함하므로, 본 항목은 그 위상 자체의 재정의가 아니라 wording 정합성 정리만 다룬다.)
- `docs/roadmap/POST_MVP_PLAN.md` — 큰 순서 / 단계 구분은 유효하나, 현재 handoff 기준 next action 과 status 를 완전히 반영하지 못할 수 있다. status 절을 현재 handoff 와 대조 없이 단독 인용하면 stale 판단 risk 가 있다.
- `brief/` vs `log/brief/BRIEF.md` 관련 historical wording — 현재는 superseding note 에 의존해 reconcile 되어 있어, 해당 note 를 못 보고 본문 일부만 읽으면 brief 의 위치 / 위상 을 오해할 수 있다 (참고: `brief/` 는 repo root 에 존재하지 않고 `log/brief/` 가 runtime 자리다).

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
- 위 docs 의 전체 rewrite / model 재정의 아님 — wording 정합성 보정 + superseding pointer 정리 범위다.
- global runtime ToolRoot model 자체의 재정의 아님 (model 정의는 contract docs 가 source-of-truth).
- 본 항목은 controlled global materialization 자체의 blocker 가 **아니다** — materialization / smoke 이후 적절한 시점에 docs cleanup 으로 처리한다.
- 본 항목 implementation 은 별도 scoped goal 을 거친다.
