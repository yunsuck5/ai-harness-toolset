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

- **Status**: 완료 — `docs/OPERATOR_GUIDE_KR.md` (이전 라운드), `README.md`, `docs/AI_HARNESS_TOOLSET_SCOPE.md`, `docs/roadmap/POST_MVP_PLAN.md` 의 wording 정합화 완료. `brief/` vs `log/brief/BRIEF.md` historical wording 은 contract docs (`docs/BRIEF_CONTRACT.md`, `docs/CHATLOG_CONTRACT.md`) 및 roadmap docs (`docs/roadmap/GLOBAL_INSTALL_UPDATE_MODEL.md` §9, `docs/roadmap/SHARED_GLOBAL_INVOCATION_CONTRACT.md` D7) 양쪽 모두 정리 완료. docs-wording scope 는 전부 closeout 이고, 실제 BF Level 3 기능 검증도 완료 (아래 마지막 bullet). 남은 것은 operator 판단의 runtime fixture cleanup 뿐이며 이는 본 항목 완료 조건이 아니다.
- **Classification**: long-lived docs hygiene. global runtime ToolRoot 전환 (6-channel stable resolution; latest commits `f37c91c` / `e699c07` / `e9f2a00` 계열) 이후, 일부 docs 가 아직 구 project-local `.ai-harness/` copy model 기준 wording 을 유지하고 있어 부분 독해 시 두 모델이 혼동될 수 있다.

### Context

global stable runtime ToolRoot 모델로의 전환이 snippets / skill / resolution docs 에는 반영되었고, 아래 named docs 의 정합화 진행 상태는 각 bullet 에 기록한다 — `docs/OPERATOR_GUIDE_KR.md`, `README.md`, `docs/AI_HARNESS_TOOLSET_SCOPE.md`, `docs/roadmap/POST_MVP_PLAN.md` 는 정합화 완료이고, `brief/` 관련 historical wording 은 contract docs 와 roadmap docs 부분이 모두 정리 완료되었고, BF Level 3 기능 검증도 완료되어 본 항목의 추적 대상은 모두 closeout 되었다.

- `docs/AI_HARNESS_TOOLSET_SCOPE.md` — **완료 (wording 정합성).** §"Source repo vs target project payload" 가 현행 adoption = shared / global channel 3 로 lead 하도록 재작성되었고, `.ai-harness/` payload 표는 "legacy project-local copy mode (channel 5)" 로 명시 강등되었으며, 본 절이 channel-3 adoption 판단의 primary source-of-truth 가 아님이 본문에 명시되었다. §"Path concepts" 의 `ToolRoot` 정의도 channel 3 / source-repo dogfooding / legacy channel 5 의 3-form 으로 갱신되었다. (`docs/backlog/README.md` 탐색 규칙상 본 문서의 contract 우선순위 위상 자체는 재정의하지 않았다 — wording 정합성 정리만 수행.)
- `docs/roadmap/POST_MVP_PLAN.md` — **완료 (stale status / next-action wording).** §6 의 "현재 active default 는 copy-only adoption" 진술이 historical record 로 보정되고 현행 default = channel 3 임이 명시되었다. §11 의 next-action wording 이 갱신되어, step 1 (`GLOBAL_INSTALL_UPDATE_MODEL.md` 확정) 은 §10 Completed 기준 이미 충족된 baseline checkpoint 로 표기되고 다음 실제 milestone 은 step 2 (global behavior validation) 로 정정되었다. §11 numbered order 의 항목 / 순서 구조 자체는 변경하지 않았다 (POST_MVP_PLAN.md §11 의 order-change 금지 규칙 준수). 큰 순서 / 단계 구분은 그대로 유효하다.
- `README.md` — **완료.** front-door pointer (이전 라운드) 에 더해, 본 라운드에서 body 가 shared / global channel 3 first 구조로 재구성되었다 — intro 단락이 channel 3 adoption 으로 lead 하고, 구 "Quick start: copy-only target project adoption" 절이 "Quick start" (shared / global) + "Legacy project-local copy mode (channel 5)" 하위 절로 분리되었으며, log-init / review-cycle 경로 설명이 channel 3 default + source-repo dogfooding + legacy channel 5 의 3-form 으로 정합화되었고, "What this toolset does not do" 의 "no `~/.claude/` files written" 진술이 channel 3 deliberate materialization 과 정합하도록 보정되었다. front-door pointer 의 "not yet been rewritten" 단서도 제거되었다.
- `docs/OPERATOR_GUIDE_KR.md` (구 `docs/MVP_OPERATOR_GUIDE_KR.md`, rename 완료) — **active operator guide 정합화 대상** (superseded-note-only 가 아니다). 본 문서는 사용자가 실제로 toolset 을 운용하는 operator-facing guide 이므로 상단 pointer 만으로는 부족하며 본문 live 절차 자체가 current shared/global model 기준이어야 한다. **완료된 보정**: §1–§2 의 모드 정의가 shared/global default + source-repo/dogfooding + legacy project-local copy 의 3-mode 로 정합화되었고, §3 / §9 의 `.ai-harness/` 절차가 legacy channel 5 전용으로 강등되었으며, §9 에 shared/global (channel 3) invocation 이 primary 예시로 추가되었고, §13 acceptance checklist 가 shared/global 기준으로 재작성되고 legacy checklist 는 §13a 부록으로 분리되었으며, §14 평가 절차와 §15 non-goals (`~/.claude/` / global install 표현) 이 current adoption 과 정합하도록 보정되었다. 또한 파일이 `docs/MVP_OPERATOR_GUIDE_KR.md` 에서 `docs/OPERATOR_GUIDE_KR.md` 로 rename 되고 title / opening identity 가 current operator guide 로 보정되었다. **완료된 reference 정리**: `tests/chatlog-contract-manual.md` 의 구 파일명 (`docs/MVP_OPERATOR_GUIDE_KR.md`) reference 6 건이 commit `f1b25e0` 에서 `docs/OPERATOR_GUIDE_KR.md` 로 갱신 완료되었다. **완료된 본문 정밀화**: §5–§6 diagram 에 mode-neutral note 가 추가되어 diagram 의 channel/global/local 관계가 §2 channel resolution 으로 명시되었고, §17 opening 의 "MVP guide + post-MVP addendum" framing 이 active operator guide 정체성에 맞게 보정되었다. 이로써 본 항목의 `docs/OPERATOR_GUIDE_KR.md` 관련 deferred wording 은 모두 해소되었다 (broader docs hygiene 중 `docs/AI_HARNESS_TOOLSET_SCOPE.md`, `docs/roadmap/POST_MVP_PLAN.md`, `README.md` body 는 본 라운드에서 정합화 완료 — 위 해당 bullet 참조; 잔여 추적 대상은 `brief/` 관련 historical wording 한 항목이다).
- `brief/` vs `log/brief/BRIEF.md` 관련 historical wording (contract docs) — **완료.** `docs/BRIEF_CONTRACT.md` 는 이미 `log/brief/BRIEF.md` 를 canonical operator-local runtime state 로, root `brief/` 를 "source repo 모드 / target payload 모드 어느 쪽에서도 만들지 않는" forbidden artifact 로 명시하고 있어 본문 일부만 읽어도 repo-root `brief/` 를 live source-of-truth 로 오인하지 않는다 (별도 변경 불필요). `docs/CHATLOG_CONTRACT.md` 는 "BF 와 CL 책임 분리" 절에 cross-reference note 를 추가하여, 본 contract 의 "BF" 가 `log/chatlog/` 트리의 session 단위 (BF Level 1/2) Brief 이고 `log/brief/BRIEF.md` (BF Level 3) 는 `docs/BRIEF_CONTRACT.md` 가 source-of-truth 인 별도 durable artifact 이며, 두 자리 모두 `log/` 아래 operator-local runtime state 이지 repo-root `brief/` tracked source artifact 가 아님을 self-sufficient 하게 명시했다. `docs/OPERATOR_GUIDE_KR.md` §"Reviewer verdict 가 아닌 artifact" 는 `log/brief/BRIEF.md` (BF Level 3) / `log/chatlog/current/resume.md` · `summary.md` (BF Level 1/2) / reviewer verdict (`log/review/<run-id>/result.json.verdict`) 의 역할 차이를 이미 정합하게 분리하고 있어 변경하지 않았다.
- `brief/` historical wording (roadmap docs) — **완료.** `docs/roadmap/GLOBAL_INSTALL_UPDATE_MODEL.md` §9 에 §9 heading 직후 section-top "BRIEF wording note" 를 추가하고 §9.1 / §9.2 / §9.4 의 standalone-misleading 한 `brief/` 줄에 짧은 inline pointer 를 달아, §9 를 단독·부분 독해해도 root `brief/` 를 current live artifact 로 오인하지 않고 현행 canonical 이 `log/brief/BRIEF.md` (`log/` 아래 operator-local runtime state) 임이 드러나게 했다 (§9.3 의 historical 본문은 design contract 재정의 없이 그대로 보존; §9.3 의 기존 "Reconciliation 완료" note 와 정합). `docs/roadmap/SHARED_GLOBAL_INVOCATION_CONTRACT.md` D7 에는 Decision 줄과 historical rationale 문단에 기존 **Superseded** note 로의 inline pointer 를 달아, D7 을 단독·부분 독해해도 동일하게 오인하지 않게 했다. 두 변경 모두 superseding-note 의존도를 줄이는 pointer 정리이며 design contract / model 재정의가 아니다. BF Level 1/2 (`log/chatlog/current/resume.md` · `summary.md`) 와 BF Level 3 (`log/brief/BRIEF.md`) 의 역할 구분, 그리고 `docs/BRIEF_CONTRACT.md` / `docs/CHATLOG_CONTRACT.md` 의 최근 정합화 내용과 충돌하지 않는다.
- BF Level 3 기능 검증 — **완료.** source-repo dogfooding 으로 (explicit `-ProjectRoot` / `-ToolRoot` = repo root) `scripts/brief-init.ps1` / `scripts/brief-check.ps1` 의 실제 동작을 검증했다: brief-init seed PASS (`log/brief/BRIEF.md` 를 template 과 byte-identical 하게 seed, UTF-8 without BOM, `.gitignore` 미변경 · root `brief/` 미생성), brief-init no-overwrite PASS (기존 BRIEF 존재 시 거부 exit 1, hash 불변), brief-check valid-artifact PASS (exit 0), 그리고 expected FAIL 경로 — replace-me sentinel / missing file / missing heading / duplicate heading / unreplaced token / empty section — 6 종 모두 정확한 메시지와 exit 1 로 동작. 생성된 runtime artifact 는 전부 `log/` 아래 (gitignored) 이며 tracked working tree 는 clean 유지. 동작이 `docs/BRIEF_CONTRACT.md` 의 brief-init / brief-check 책임 정의 및 canonical 경로 (`log/brief/BRIEF.md`) 와 일치하여 docs 수정 불필요. 검증 중 생성된 `log/brief/BRIEF.md` seed 와 `log/brief-validation/` fixture 의 정리는 operator 판단의 별도 cleanup 대상이며 본 항목 완료 조건이 아니다.

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
