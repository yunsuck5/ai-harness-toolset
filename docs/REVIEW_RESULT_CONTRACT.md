# Review Result Artifact Contract

`log/review/<run-id>/` 아래에 reviewer 실행이 끝난 뒤 어떤 최소 형식으로 결과를 남길지 정의한다.

이 문서는 **manual convention first** 문서다. 기본 mode는 prepared packet freshness 검증을 유지하고, completed review record enforcement는 명시적 `-RequireResult` mode에서만 수행한다. MVP에서는 single-shot CLI `scripts/review-cycle.ps1` 이 verdict parsing 성공 시 result.json을 자동으로 작성하지만, parsing 실패 시 result.json은 만들어지지 않으며 사람이 manual convention에 따라 작성해야 cycle 이 닫힌다. review-run productization wrapper, watcher, hook, daemon, DB-backed history, retention automation은 포함하지 않는다.

## 목적

- reviewer (사람 또는 AI)가 내린 최종 판단을 사람이 읽는 file 형태로 보존한다.
- 어떤 input을 기준으로 판단했는지, 어떤 target을 검토했는지 추적 가능하게 한다.
- 자동화 schema 강제 없이도 사람이 읽고 쓸 수 있는 형식을 유지한다.

이 contract는 review result가 무엇을 보장하는가가 아니라, result 파일을 **어디에**, **어떤 이름으로**, **어떤 최소 필드로** 남길지에 관한 합의다.

## 범위

`log/review/<run-id>/`는 project-local runtime artifact 영역이다.

- source repo 모드: `<repo-root>/log/review/<run-id>/`
- target payload 모드: `<project-root>/log/review/<run-id>/`

두 경우 모두 `log/`는 gitignored runtime artifact 트리이며 source snapshot에 포함하지 않는다.

이 contract는 다음을 규정하지 **않는다**:

- reviewer productization wrapper, watcher, git hook, daemon, workflow engine
- multi-reviewer orchestration
- review history DB 또는 index
- review result schema 강제 검증
- review result retention 정책
- default review-verify mode에서 result.md / result.json을 실패 조건으로 만드는 것
- evidence subsystem과의 cross-tree 보장
- chatlog subsystem과의 cross-tree 보장

`review-cycle.ps1` 은 single-shot CLI이며 위 productization wrapper 범주에 들어가지 않는다. cycle 이 result.json 을 작성하더라도 contract 의 minimum field set, verdict vocabulary, hash binding 의미는 그대로다.

## review / evidence / chatlog subsystem 경계

`log/` 아래에는 세 종류의 트리가 공존한다. 책임이 서로 다르다.

| 트리 | 책임 | 검증 주체 |
|---|---|---|
| `log/review/<run-id>/` | review packet과 freshness 검증, review result 보존 | `scripts/review-prepare.ps1`, `scripts/review-verify.ps1` (freshness; optional `-RequireResult` binding verification), 사람 (result 작성) |
| `log/evidence/` | command 실행 사실, output, 재현 단서 보존 | 사람 (manual convention, `docs/EVIDENCE_CONTRACT.md`) |
| `log/chatlog/` | session 작업 기록과 resume brief 보존 | 사람 (manual convention, `docs/CHATLOG_CONTRACT.md`) |

- review subsystem은 evidence subsystem의 input이 아니며, output도 아니다.
- review subsystem은 chatlog subsystem의 input이 아니며, output도 아니다.
- 셋은 같은 `log/` 아래에 있지만 서로 enforce하지 않는다.

review result가 evidence file이나 chatlog summary를 **참조**하는 것은 권장된다. 그러나 review subsystem이 evidence나 chatlog의 정합성을 담당하지는 않는다.

## prepared review packet vs completed review record

같은 `log/review/<run-id>/` 디렉터리는 시간에 따라 두 단계 상태를 가진다.

**Prepared review packet** — `review-prepare.ps1` 또는 `review-cycle.ps1` 의 prepare 단계 직후 상태:

- `meta.json` required
- `input.md` required
- `result.md` absent 가능
- `result.json` absent 가능

**Completed review record** — reviewer 실행이 끝나고 사람이 결과를 정리한 뒤 상태:

- `meta.json` required
- `input.md` required
- `result.md` required
- `result.json` required

prepared 상태에서 completed 상태로 전환하는 경로는 두 가지다.

1. `review-cycle.ps1` single-shot path — verdict parsing 성공 시 cycle 이 같은 run-id 디렉터리에 `result.md` (Codex CLI 가 작성) 와 `result.json` (cycle 이 작성) 을 두고 `review-verify -RequireResult` 까지 호출한다. 이 자동 작성은 user-triggered single-shot 안에서 일어난다. background trigger 가 아니다.
2. Manual fallback — `review-cycle.ps1` 이 parsing 실패로 종료했거나 component path 만 사용한 경우, 사람이 `result.md` 를 손으로 보정하고 `result.json` 을 작성한 뒤 `review-verify -RequireResult` 를 직접 실행한다.

어느 경로든 review-record 의 minimum field set 과 검증 surface 는 동일하다.

## 권장 layout

```
<ProjectRoot>/log/review/<run-id>/
  meta.json
  input.md
  result.md
  result.json
```

같은 `<run-id>` 디렉터리 아래에 네 파일이 모두 존재할 때 그 review record는 completed로 본다.

## 파일 역할

### meta.json

`review-prepare.ps1`이 만든 packet metadata. run-id, target path, target SHA-256, source HEAD, stage, purpose, reviewer config, freshness policy 등이 들어 있다. 형식은 `templates/review-meta.json`과 `scripts/review-prepare.ps1`이 함께 정한다. 이 contract는 meta.json을 새로 정의하지 않는다.

### input.md

`review-prepare.ps1`이 `templates/review-input.md`를 기반으로 렌더링한 reviewer 입력. reviewer는 이 파일을 보고 판단을 내린다. 이 contract는 input.md를 새로 정의하지 않는다.

### result.md

reviewer가 내린 최종 판단을 사람이 읽기 위한 markdown. 권장 template은 `templates/review-result.md`다.

- verdict (`yes` / `no` / `yes with risk`)
- 어떤 target을 보았는가 (path, SHA-256, run-id)
- 어떤 input.md에 묶이는가 (input SHA-256)
- findings, risks, required changes, notes

reviewer가 AI인 경우, AI 출력 본문을 정리해 result.md에 붙인다. reviewer가 사람인 경우, 사람이 직접 작성한다.

### result.json

같은 review record의 machine-readable 최종 판단. 권장 template은 `templates/review-result.json`다.

- `verdict`은 machine-readable 최종 판단이다. 값: `yes` / `no` / `yes with risk`.
- `inputSha256`은 어떤 input.md를 기준으로 판단했는지 묶기 위한 값이다.
- `resultMarkdownSha256`은 result.md와 result.json을 묶기 위한 값이다.
- `targetPath`, `targetSha256`, `runId`, `stage`, `purpose`, `reviewer` 등은 meta.json과 일치해야 한다 (사람이 채운다).

자동 일치 검증의 범위는 mode에 따라 다르다.

- 기본 mode (`-RequireResult` 미지정): result artifact 자체를 요구하지 않으며 result.json 필드의 일치를 검증하지 않는다.
- `-RequireResult` mode: 아래 "review-verify의 현재 책임과 한계" 절에 열거된 부분 집합 (`runId`, `targetSha256`, `inputSha256`, `resultMarkdownSha256`, `verdict`, `targetPath`, `createdAtUtc`, conditional `sourceHead`) 만 자동 검증한다.
- 위 부분 집합에 들어 있지 않은 필드 (`stage`, `purpose`, `reviewer`, `schemaVersion`, `notes` 등) 는 여전히 manual convention 영역이며 사람이 직접 맞춘다.

## result.json 최소 필드

```json
{
  "schemaVersion": 1,
  "runId": "<run-id>",
  "createdAtUtc": "yyyy-MM-ddTHH:mm:ss.fffffffZ",
  "reviewer": "<reviewer>",
  "verdict": "yes | no | yes with risk",
  "targetPath": "<absolute-target-path>",
  "targetSha256": "<target-sha256>",
  "sourceHead": null,
  "stage": "design | implementation | test | review | release",
  "purpose": "<purpose>",
  "inputSha256": "<input-md-sha256>",
  "resultMarkdownSha256": "<result-md-sha256>",
  "notes": []
}
```

`templates/review-result.json`의 angle-bracket 값과 format string은 guide placeholder이며, completed `result.json` 작성 시 실제 값으로 교체해야 한다.

`createdAtUtc`는 ASCII digit `0-9`만 사용한다. Arabic-Indic digit (예: `٠`–`٩`) 등 다른 Unicode decimal digit은 거부된다. 7자리 fractional second는 canonical machine-readable contract의 일부이며, 시스템 시계가 100ns 단위 의미 있는 정밀도를 제공한다는 주장은 아니다.

값 채우기 규칙:

- `schemaVersion`은 정수 `1`로 시작한다.
- `verdict`은 위 세 값 중 하나만 사용한다.
- `runId`, `targetPath`, `targetSha256`, `stage`, `purpose`, `reviewer`는 같은 디렉터리의 `meta.json`과 일치하도록 수동으로 옮긴다.
- `inputSha256`은 같은 디렉터리의 `input.md` SHA-256다.
- `resultMarkdownSha256`은 같은 디렉터리의 `result.md` SHA-256다.
- `sourceHead`는 작성 시점의 git HEAD를 옮기되, repo 외부에서 작성된 결과라면 `null`을 둘 수 있다.
- `notes`는 자유형 string 배열이다.

`review-cycle.ps1` single-shot path 에서는 `inputSha256`, `resultMarkdownSha256`, `createdAtUtc`, `runId`, `targetPath`, `targetSha256`, `sourceHead`, `stage`, `purpose`, `reviewer` 를 cycle 이 자동으로 채워 넣고 verdict 만 result.md parsing 결과로 채운다. manual fallback path 에서는 사람이 직접 또는 별도 helper로 SHA-256 값을 계산해 채운다. 어느 경로든 작성된 result.json 의 hash binding 의미는 동일하다.

## verdict 값

result.md와 result.json 모두 다음 세 값만 사용한다:

- `yes` — 검토 범위 내에서 진행 가능.
- `no` — 검토 범위 내에서 진행 불가.
- `yes with risk` — 진행은 가능하나 명시된 risk를 수반함.

이 세 값은 `templates/review-input.md`의 final verdict 표기와 정렬되어 있다.

## reviewer input freshness와 result artifact의 관계

- `meta.json.targetSha256`은 packet 생성 시점의 primary target file SHA-256이다.
- `meta.json.targetFiles[]`는 multi-file change-set review 시 전체 reviewed 파일 set 을 repo-relative path + lowercase SHA-256 으로 기록한다. 단일 파일 review 시 primary entry 1개만 포함될 수 있다.
- `review-verify.ps1` default mode 는 primary target (`targetSha256`) 일치 검증 후, `targetFiles[]` 가 비어있지 않으면 각 entry 의 현재 SHA-256 을 다시 계산해 일치하는지 검증한다. 첫 stale entry path 가 메시지에 포함된다 (`freshnessPolicy.type = "target-sha256-match"`).
- 이 freshness 검증은 **reviewer 입력의 정합성**에 대한 것이다. result artifact 의 정합성에 대한 것이 아니다.
- `result.json.inputSha256`은 result가 어떤 input.md를 보고 작성되었는지 묶기 위한 값이다.
- `result.json.targetSha256` 은 result 작성 시점에 cycle 또는 사람이 `meta.json.targetSha256` 에서 그대로 옮긴 primary target binding 값이다. `meta.json` 의 값과 일치한다는 사실은 result 가 **같은 prepared review input 에 묶였다** 는 binding 정보일 뿐이며, 현재 target file 들이 그 SHA-256 과 같다는 보장은 아니다. multi-file freshness 는 `result.json` 이 mirror 하지 않으며, current target file freshness 는 여전히 `scripts/review-verify.ps1` default mode 로 확인해야 한다. result artifact 자체는 current target freshness 를 자동으로 보장하지 않는다.

## review-verify의 현재 책임과 한계

`scripts/review-verify.ps1`은 두 가지 mode로 동작한다.

### 기본 mode (`-RequireResult` 미지정)

prepared packet의 freshness를 검증한다.

- run directory와 `meta.json` 존재 여부 검증
- `meta.json.projectRoot`, `meta.json.projectLogRoot`가 현재 실행 환경과 일치하는지 검증
- primary target file 존재와 ProjectRoot 내부 여부 검증
- `meta.json.targetSha256`과 현재 primary target SHA-256 일치 검증
- `meta.json.targetFiles[]`가 비어있지 않으면 각 entry 에 대해: repo-relative path 를 ProjectRoot 기준 절대 경로로 해석, ProjectRoot 외부 escape 거부, missing file 거부, 현재 SHA-256 과 entry SHA-256 일치 검증. 첫 stale path 가 실패 메시지에 포함됨
- `result.md` 존재는 informational 출력만 한다. 실패 조건이 아니다.
- `result.json` 존재 자체를 보지 않는다.

기본 mode에서는 missing `result.md` / missing `result.json`을 실패 조건으로 만들지 않는다.

기본 mode `review-verify`의 PASS는 reviewer 승인 완료를 의미하지 않는다. target artifact freshness / hash 검증 통과만을 의미한다. `result.md` / `result.json`이 없는 채로 PASS가 보고되더라도 reviewer 판단이 이루어졌다는 뜻은 아니다.

### `-RequireResult` mode (completed review record 검증)

기본 mode 검증을 모두 통과한 뒤, completed review record의 binding을 추가 검증한다.

- `input.md` 존재 검증
- `result.md` 존재 검증 (missing이면 실패)
- `result.json` 존재 검증 (missing이면 실패)
- `result.json` JSON valid 검증
- `result.json.runId`과 `meta.json.runId` 일치 검증
- `result.json.targetSha256`과 `meta.json.targetSha256` 일치 검증
- `result.json.inputSha256`과 실제 `input.md` SHA-256 일치 검증
- `result.json.resultMarkdownSha256`과 실제 `result.md` SHA-256 일치 검증
- `result.json.verdict`이 정확히 `yes` / `no` / `yes with risk` 중 하나인지 검증
- `result.json.targetPath` 존재 / 비어있지 않음 검증, 그리고 `meta.json.targetPath`와 normalized full-path 비교 (`[System.IO.Path]::GetFullPath` 후 OrdinalIgnoreCase). source repo / target payload 모드 모두 절대경로 기준이며, 이번 batch에서는 repo-relative 표기는 지원하지 않는다.
- `result.json.createdAtUtc` 존재 / 비어있지 않음 검증, 그리고 정확한 string shape `yyyy-MM-ddTHH:mm:ss.fffffffZ` (예: `2026-04-30T07:12:34.1234567Z`) 인지 검증. 이어서 동일 값이 `DateTimeOffset` parse 가능 여부와 parsed offset이 `TimeSpan.Zero` (UTC) 인지 추가 검증. `+00:00` 표기, 분수 초가 없는 `Z` 표기, RFC 1123 (`Thu, 30 Apr 2026 07:12:34 GMT`) 등 parseable한 UTC 표현이라도 정확한 contract shape이 아니면 거부한다. 현재 wall clock과의 비교나 `meta.json.createdAtUtc`와의 시간 순서 검증은 하지 않는다.
- `meta.json.sourceHead`와 `result.json.sourceHead`가 **둘 다 non-empty** 인 경우에만 정확히 일치하는지 검증. meta 쪽이 null/empty이면 result 쪽 sourceHead는 null/empty / absent 모두 허용한다. short-hash prefix matching은 하지 않는다.

`-RequireResult` mode가 여전히 검증하지 **않는** 것:

- `result.json.sourceHead` required validation (meta가 null/empty이면 result도 null/empty 허용)
- `result.json.sourceHead` short-hash prefix matching
- `result.json.createdAtUtc` 시간 순서 / 현재 시각 비교
- `result.json.stage` / `purpose` / `reviewer` / `schemaVersion` strict validation
- `notes[]` schema enforcement
- verdict 대소문자 / 공백 normalization (strict equality만 enforce)
- default mode에서의 result artifact 요구

위 항목은 future candidate로 남긴다. SHA-256 binding과 위 metadata hardening v1이 MVP에서 completed-record binding의 authority다.

## source snapshot에는 log/를 포함하지 않는다

- `templates/`, `scripts/`, `config/`, `snippets/`, `docs/` 등 source 트리에는 review record 파일을 두지 않는다.
- review record를 source repo에 commit하지 않는다.
- review record가 참조하는 fixture는 `log/review/<run-id>/` 또는 `log/evidence/<scope>/<case>/` 안에서만 생성한다.
- public release packaging이 도입되어도 `log/`는 항상 제외한다.

## non-goals

이 contract가 다루지 않는 것:

- review-run productization wrapper, watcher, git hook, daemon, workflow engine
- multi-reviewer orchestration, fallback model use, retry loop, auto-fix loop
- auto-commit, auto-push, auto-publish, auto-merge, auto-release, auto-deployment
- review history DB 또는 index
- review record 자동 retention 정책
- result schema 자동 validator
- default review-verify mode에서 result.md / result.json을 실패 조건으로 만드는 것
- evidence subsystem과의 cross-tree 보장
- chatlog subsystem과의 cross-tree 보장
- CI integration, 스케쥴 기반 자동 실행
- 다른 toolset과의 review result format 상호운용
- public release packaging

`review-cycle.ps1` single-shot user-triggered CLI 는 위 항목들과 분리된다. cycle 이 Codex 를 1회 실행하고 result.json 을 작성하는 행위는 단일 user 호출 안에서만 일어나며, 위 productization 범주로 확장되지 않는다.

## Future candidate

아래 항목은 버리지 않는다. 다만 이번 MVP scope에서는 구현하지 않는다.

- `result.json.sourceHead` 무조건 required 검증 (현재는 meta / result 양쪽 모두 non-empty일 때만 비교).
- `result.json.sourceHead` short hash / full hash prefix-match 정책.
- `result.json.createdAtUtc` 시간 순서 / 현재 시각 비교.
- `result.json.stage` / `purpose` / `reviewer` / `schemaVersion` strict 비교.
- `result.json.notes[]` schema enforcement.
- `result.json.targetFiles[]` mirror (현재 multi-file freshness 는 meta.json + review-verify default mode 단독 책임이며 result.json 은 primary target 만 미러).
- `result.json.verdict` 을 읽어 후속 단계 (commit gate, push gate 등) 를 막는 productization wrapper.
- review history aggregation.
- review record retention 정책.
- `fix` 등 추가 stage enum.
- `-Reviewer codex` 외 reviewer adapter.

이번 v1 metadata hardening으로 future candidate에서 빠진 항목:

- `result.json.targetPath` 존재 + `meta.json.targetPath`와 normalized full-path match.
- `result.json.createdAtUtc` 존재 + 정확한 string shape `yyyy-MM-ddTHH:mm:ss.fffffffZ` + parseable + UTC offset.
- `result.json.sourceHead` conditional exact match (meta / result 양쪽 모두 non-empty인 경우에 한해).

## 향후 확장 시 고려 사항

- 새 wrapper는 `log/review/<run-id>/result.md`, `result.json`을 만들거나 읽는 형태로 동작한다.
- 새 schema가 도입되어도 본 contract의 최소 필드와 모순되지 않도록 한다.
- 새 retention 정책은 `<run-id>` 단위 prune이 자연스럽게 가능하도록 설계한다.
- review-verify 확장 시에도 freshness 검증 기본 동작은 유지한다.
