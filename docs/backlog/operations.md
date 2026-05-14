# Operations Backlog

본 파일은 review subsystem 외 운영 영역 — smoke 운영, long-lived docs hygiene, evidence preservation 등 — 의 open 후보 항목을 기록한다. 본 파일의 어떤 항목도 implementation, scheduling, release 의 자동 승인이 아니다. 본 파일과 다른 contract 문서가 충돌하면 contract 문서가 우선한다 (`./README.md` 참조).

---

## Long-lived docs commit hash hygiene

- **Status**: candidate

### Context

Long-lived criteria docs (예: `docs/roadmap/CLEAN_TARGET_SMOKE_CRITERIA.md`) 및 execution scope proposal 본문에 절대 commit hash 를 하드코딩하면, 후속 commit 이후 stale 한 reference 가 남는다. 본 라운드의 SC5 round 1 → round 2 보정 과정에서 실제로 이 incident 가 발생했다: 초기 execution scope proposal 이 execution pin 으로 `595d35d` (criteria 가 historical context 로 인용한 commit) 를 사용했다가, 그 다음 round 에서 `85433e5` 를 execution pin 으로 재지정해야 했고, 최종 round 에서는 본문 hash 를 모두 제거하고 "restored clean HEAD" preconditions (branch == main, HEAD == origin/main, working tree clean) 로 전환했다.

### Candidate direction

long-lived doc 에서 execution / precondition 정의 시 다음 패턴을 따른다.

- 본문에는 절대 commit hash 를 두지 않는다. 대신 "current restored clean HEAD" 또는 "branch == main, HEAD == origin/main, working tree clean" preconditions 로 표현한다.
- 절대 commit hash 는 handoff, manifest, snapshot metadata, evidence report (per-run `SUITE_REPORT.md` 등) 같은 short-lived per-run artifact 에만 기록한다.
- 기존 long-lived doc 에 잔존하는 literal hash references 의 식별과 정리는 별도 doc-hygiene pass 의 대상이다. 본 backlog 시점에서 `docs/roadmap/CLEAN_TARGET_SMOKE_CRITERIA.md` 의 §Target / §7 가 `595d35d` 를 historical context anchor 로 인용함 (criteria 의 §0 commit binding 에서 historical anchor 임이 명시되어 있음). 본 reference 가 의도된 historical anchor 인지 stale 한 잔존 hash 인지의 case-by-case 판정은 별도 doc-hygiene round 에서 수행한다.

### Non-goals

- 본 항목은 backlog candidate 다. 즉각 doc-hygiene 변경은 자동 승인되지 않는다.
- hash-hygiene 점검 linter / 자동 검사 tool 도입을 자동 승인하지 않는다.
- contract docs 의 per-doc source-of-truth commit anchoring 은 본 backlog 의 대상이 아니다 (의도된 historical anchor 는 본 항목의 정리 대상이 아님).
- 본 항목 implementation 은 별도 scoped goal 을 거친다.

---

## PowerShell smoke invocation quoting hardening

- **Status**: deferred (현재 round 에서 implementation 없음)

### Context

SC5 rerun 의 첫 시도 (suite `ahts-smoke-sc5\20260514T024655Z`) 에서, smoke driver 가 `review-cycle.ps1` 를 `Start-Process -ArgumentList <array>` 로 호출하면서 multi-word substitution 값 (`-Context 'Clean target smoke verification of D6 ...'`) 의 quoting 을 PowerShell 5.1 의 array 형태가 자동 보존하지 않아, `'of'` 가 positional argument 로 거부되었다 (`A positional parameter cannot be found that accepts argument 'of'`). parser 단계에서 종료되어 Codex 호출 / run-dir 생성 / fixture mutation 모두 발생하지 않았고, SC7 invariant 는 hold 했다.

본 incident 는 smoke contract failure 가 **아니다** — criteria 의 prescribed invocation 자체는 정상이며, 두 번째 시도 (suite `ahts-smoke-sc5\20260514T024818Z`) 에서 manually-quoted single-string command line 으로 동일 invocation 을 통과시켰다 (verdict `yes`). 그러나 smoke 의 반복적 / 후속 실행에서 driver 의 quoting 규약이 매번 수동으로 재현되어야 한다는 점은 fragility 다.

본 항목은 `docs/backlog/review.md` 의 "Review-cycle file-backed request input" 항목과 root cause (PowerShell quote-discipline 의 fragility) 를 공유하나, 작동 layer 가 다르다. file-backed request input 후보가 `review-cycle.ps1` 내부 인자의 fragility 를 root-cause hardening 하는 반면, 본 항목은 그 외부 호출자 (smoke driver) 의 invocation 패턴을 다룬다. 한쪽이 구현되어도 다른 쪽이 자동 해결되지 않는다.

### Candidate direction

- repo 안에 "safe smoke invocation pattern" 을 명문화한 짧은 runbook 또는 helper 스니펫 한 개를 둔다. 위치 후보 — `docs/runbooks/smoke-invocation.md` 또는 `snippets/` 안의 minimum sample. 운영자가 SC 별로 매번 quoting 을 수동 재발견하지 않도록 한다.
- helper 의 구현 후보 — `Start-Process` 에 single-string command 형태로 전달하며 manually quoted; 또는 stub `.ps1` driver 한 개로 SC 별 invocation 을 wrap. 두 후보 중 선택은 implementation 단계에서 결정.

### Cross-reference

- `docs/backlog/review.md` "Review-cycle file-backed request input" 항목 — 동일 root cause (PowerShell quote-discipline) 의 다른 layer.

### Non-goals

- 본 backlog 항목 자체는 어떤 구현도 자동 승인하지 않는다.
- `review-cycle.ps1` 의 parameter contract 변경 아님.
- 새 daemon / watcher / background automation 도입하지 않음.
- 본 항목과 review.md 의 file-backed request input 후보를 묶어서 한 번에 구현하지 않음 (별도 scoped goals).
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
