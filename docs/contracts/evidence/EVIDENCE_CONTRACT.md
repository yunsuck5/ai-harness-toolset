# Evidence Minimal Capture Contract

`log/evidence/` 아래에 command 또는 test 실행 사실을 어떤 최소 형식으로 남길지 정의한다.

이 문서는 **manual convention first** 문서다. script, wrapper, framework는 포함하지 않는다.

## 목적

- 실행 사실을 단순한 file 형태로 보존한다.
- 실패 재현, 수동 review, 후속 조사에 충분한 단서를 남긴다.
- 자동화 도구가 강제하는 schema 없이도 사람이 읽고 쓸 수 있는 형식을 유지한다.

이 contract는 evidence가 무엇을 보장하는가가 아니라, evidence 파일을 **어디에**, **어떤 이름으로** 남길지에 관한 합의다.

## 범위

`log/evidence/`는 project-local runtime artifact 영역이다.

- source repo 모드: `<repo-root>/log/evidence/`
- target payload 모드: `<project-root>/log/evidence/`

두 경우 모두 `log/`는 gitignored runtime artifact 트리이며 source snapshot에 포함하지 않는다.

이 contract는 다음을 규정하지 **않는다**:

- evidence 자동 수집 도구
- evidence schema 강제
- review subsystem이 사용하는 packet freshness 판단
- CI integration

## 경로 규약

기본 path 형태:

```
<ProjectRoot>/log/evidence/<scope>/<case>/
```

- `<scope>` — workstream, feature, hardening pass 등 한 묶음의 evidence가 모이는 단위. 예: `review-hardening`, `path-resolution`, `encoding-policy`.
- `<case>` — 그 scope 내 개별 실행 단위. 예: `ac2`, `ac11`, `repro-001`. 이름은 manual convention이며 강제 schema는 없다.

`<scope>/<case>/`는 해당 case의 workspace이다. 권장 evidence 파일과 함께, case가 필요로 하는 fixture, intermediate state, file snapshot 등 보조 artifact도 같은 디렉터리에 둘 수 있다.

## 권장 파일 구성

각 case 디렉터리 아래에 다음 file 이름을 사용한다.

| 파일 | 역할 | MVP 위치 |
|---|---|---|
| `command.txt` | 실행한 command line 한 줄 또는 다줄 캡처 | recommended |
| `exit-code.txt` | command 종료 코드 한 줄 (예: `0`) | recommended |
| `stdout.txt` | command 표준 출력 캡처 | optional |
| `stderr.txt` | command 표준 에러 캡처 | optional |
| `notes.md` | 자유형 사람이 쓴 메모, 재현 절차, 해석 | optional |
| `files/` | file snapshot 또는 부속 자료가 들어가는 하위 디렉터리 | optional |

위 이름은 권장이다. 이름이 다르면 안 된다는 의미가 아니라, 같은 의도의 파일이라면 이 이름을 쓰라는 합의다.

## Single Markdown evidence bundle (R1 convention)

위 5-file recipe (`command.txt` / `exit-code.txt` / `stdout.txt` / `stderr.txt` / `notes.md`) 외에 본 contract 는 **single Markdown evidence bundle** 도 accepted form 으로 인정한다. R1 Markdown evidence convention (`docs/contracts/review/REVIEW_RESULT_CONTRACT.md` §3a) 의 referencing 대상이다.

- file path: `<ProjectRoot>/log/evidence/<scope>/<case>/validation-evidence.md` (또는 case directory 안의 동등 `.md` filename).
- 본문 구성: command / exit-code / stdout / stderr / notes 항목을 한 Markdown file 안의 명확한 heading section 으로 누적한다. 별도 file 로 분리하지 않는다.
- 권장 본문 skeleton:

  ```markdown
  # Validation evidence — <scope>/<case>

  ## Command
  <command line; multi-line 허용>

  ## Exit code
  <integer>

  ## Stdout
  <captured stdout; fenced code block 권장>

  ## Stderr
  <captured stderr; stderr 가 비었어도 빈 section 으로 남긴다>

  ## Notes
  <free-form 해석 / 재현 절차 / environment fingerprint>
  ```

- 5-file recipe 와 single-Markdown bundle 은 **양립**한다. 같은 case 안에서 둘 중 한 형식만 두어도 되고, 두 형식이 공존해도 본 contract 의 위반 아니다. 운영자 / 사용자가 case 단위로 형식을 선택한다.
- 단, **R1 Markdown evidence convention** (`docs/contracts/review/REVIEW_RESULT_CONTRACT.md` §3a) 의 `## Validation evidence` referencing 대상은 **single Markdown bundle 한 form 으로 한정** 된다 — 5-file form 은 본 contract 의 일반 evidence 로 보존되지만 R1 convention 의 path referencing target 은 아니다. 5-file form 의 case directory 또는 그 안의 개별 file 이 reviewer inspection 에 필요하면 `input.md` 의 `## Required inspection paths` 에 일반 inspection path 로 적는다.
- single-Markdown bundle 의 본문은 `input.md` 가 referencing 할 수 있는 reviewer-readable supporting material 이다. 그 referencing 의 의미와 boundary 는 `docs/contracts/review/REVIEW_RESULT_CONTRACT.md` §3a 가 source-of-truth.
- 본 form 도 manual convention first 다. wrapper / runner / schema validator 를 추가하지 않는다. 본문 정직성은 운영자 책임이며 본 contract 의 script gate 는 이를 enforcement 하지 않는다.

## MVP 규칙

- 모든 파일을 필수로 강제하지 않는다.
- `command.txt`와 `exit-code.txt`는 recommended로 둔다.
- `stdout.txt`, `stderr.txt`, `notes.md`, `files/`는 필요할 때만 둔다.
- evidence는 review subsystem의 품질 게이트가 아니다.
- review packet 의 shape gate (heading 존재, placeholder / token 잔존, `## Verdict` shape, 4 required disclosure H2 — `## Blocking findings` / `## Non-blocking concerns` / `## Review limitations` / `## Assumptions relied on` — 각각 정확히 1 회 존재) 는 `scripts/review-prepare.ps1` / `scripts/review-input-verify.ps1` / `scripts/review-verify.ps1` 의 deterministic 책임이다. evidence file 의 freshness / 본문 사실성 / staleness 판단은 본 contract 와 review subsystem 의 script gate 가 enforcement 하지 않으며 operator 와 사용자 책임이다 (`docs/contracts/review/REVIEW_RESULT_CONTRACT.md` §3a 참조).
- evidence는 실행 사실, command output, 재현 단서, file snapshot을 보관하는 보조 기록이다.
- source snapshot에는 `log/`를 포함하지 않는다.
- `log/evidence/`는 gitignored runtime artifact로 유지한다 (`.gitignore`의 `log/` 규칙).

## Manual capture recipe

이 recipe는 evidence를 실제로 어떻게 남기는지에 대한 **사람이 손으로 따라가는 절차**다. wrapper, runner, schema validator를 추가하지 않는다. evidence runner를 도입하기 전 단계에서, 같은 입력에 대해 같은 흔적이 남도록 절차를 통일하는 데 목적이 있다.

### 사전 결정

1. `<scope>`를 정한다. 한 묶음의 evidence가 모이는 단위 (예: `review-verify`, `path-resolution`).
2. `<case>`를 정한다. 그 scope 안의 한 실행 단위 (예: `ac30-non-ascii-createdAtUtc`, `repro-001`).
3. case workspace 경로:

   ```
   <ProjectRoot>/log/evidence/<scope>/<case>/
   ```

`<scope>` / `<case>` 이름은 manual convention이다. schema 강제나 자동 검증은 없다.

### 절차

1. case directory를 만든다.
2. 실행할 command를 `command.txt`에 그대로 적는다 (multi-line 가능). 가능하면 **실행 전**에 적어둔다.
3. command를 실행하면서 stdout / stderr를 분리해 캡처한다. PowerShell `1>` / `2>` redirect를 쓰는 경우 `stderr.txt`가 비어 있어도 **0-byte file로 그대로 남기는 것을 권장**한다. "stderr가 비었다"는 사실 자체가 evidence이며, file 부재와 구분되어야 한다. 분리가 필요 없으면 `stdout.txt` 한 곳에만 둬도 된다.
4. process exit code를 `exit-code.txt`에 기록한다. PowerShell에서는 command 실행 **직후 즉시** `$LASTEXITCODE`를 변수(예: `$exitCode`)에 보존한 뒤 file에 쓴다. 그 사이에 다른 명령이 끼면 `$LASTEXITCODE`가 덮인다. file 내용은 exit code 한 줄과 trailing newline (예: `0\n`)으로 한다.
5. 사람이 해석한 요약, 관찰, 한계, 재현 조건을 `notes.md`에 적는다. environment fingerprint (PowerShell edition, OS build, repo HEAD commit 등)은 필요하면 `notes.md`에 자유서술로 함께 적는다. 이번 MVP에서는 environment fingerprint를 위한 별도 표준 file (`env.txt`, `manifest.json` 등)을 추가하지 않는다.
6. 입력 / 출력 file snapshot이 필요하면 `files/` 하위에 둔다 (선택).

### PowerShell reference snippet

아래 snippet은 사람이 손으로 따라 가도 되는 reference이다. evidence runner / wrapper / schema validator로 발전시키지 않는다. file IO는 `scripts/lib/encoding.ps1`의 helper(`Write-Utf8NoBom`, `Read-Utf8` 등)만 사용하며, `Set-Content -Encoding UTF8`, `Out-File` 등은 `docs/policies/POWERSHELL_POLICY.md`에 따라 사용하지 않는다.

따라서 snippet의 첫 줄 `. ./scripts/lib/encoding.ps1`은 **선행 조건**이다. 이 dot-source를 빠뜨리면 `Write-Utf8NoBom`이 정의되지 않아 file IO가 실패한다.

```powershell
# Precondition: dot-source the encoding helper before any Write-Utf8NoBom call.
. ./scripts/lib/encoding.ps1

$scope = 'review-verify'
$case  = 'ac30-non-ascii-createdAtUtc'
$caseDir = Join-Path 'log/evidence' "$scope/$case"
$null = New-Item -ItemType Directory -Force -Path $caseDir

$command = 'powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Invoke-Pester -Path tests/review-verify.Tests.ps1"'
Write-Utf8NoBom -Path (Join-Path $caseDir 'command.txt') -Content ($command + "`n")

$stdoutPath = Join-Path $caseDir 'stdout.txt'
$stderrPath = Join-Path $caseDir 'stderr.txt'

# 1> / 2> redirect는 stderr가 비어도 stderr.txt를 0-byte file로 남긴다 (권장).
& powershell.exe -NoProfile -ExecutionPolicy Bypass -Command 'Invoke-Pester -Path tests/review-verify.Tests.ps1' 1> $stdoutPath 2> $stderrPath

# Capture $LASTEXITCODE immediately. Any intervening command overwrites it.
$exitCode = $LASTEXITCODE
Write-Utf8NoBom -Path (Join-Path $caseDir 'exit-code.txt') -Content ([string]$exitCode + "`n")

Write-Utf8NoBom -Path (Join-Path $caseDir 'notes.md') -Content "# Notes`n- Expected: 24 / 24 PASS.`n- Observed: ...`n- Limits: ...`n- Repro: ...`n"
```

이 snippet은 PowerShell이 강제는 아니다. bash, cmd, 또는 사람이 직접 손으로 파일을 만들어도 된다. 같은 file 이름과 같은 case directory 위치만 지키면 된다.

### 이 recipe가 명시적으로 하지 않는 것

- script / wrapper / runner를 추가하지 않는다.
- schema validator를 추가하지 않는다.
- review subsystem freshness 판단(`scripts/review-verify.ps1`)과 evidence capture를 자동으로 연결하지 않는다. evidence는 review packet을 freshness-pass / fail로 판정하지 않으며, review-verify는 이 recipe를 호출하지 않는다.
- `log/evidence/<scope>/<case>/`는 `log/`의 일부로 gitignored runtime artifact이며 source snapshot / commit / handoff packet에 포함하지 않는다.

## review subsystem과의 경계

review subsystem은 별도 경로를 사용한다:

- canonical review record는 `<ProjectRoot>/log/review/<review-task-id>/<perspective>/pass-NN/{input.md, result.md}` 의 three-level layout 에 생성된다 (`-Perspective` required; `docs/contracts/review/REVIEW_RESULT_CONTRACT.md`).
- review record 의 shape 검증, `## Verdict` 형식, 4 required disclosure H2 (`## Blocking findings` / `## Non-blocking concerns` / `## Review limitations` / `## Assumptions relied on`) 의 1 회 존재 (`-RequireResult` mode), `-RequireResult` binding 등은 `scripts/review-prepare.ps1` / `scripts/review-run.ps1` / `scripts/review-verify.ps1` / `scripts/review-input-verify.ps1` 가 담당한다.

evidence는 canonical review record 의 input 도 output 도 아니다. canonical review record (`<ProjectRoot>/log/review/<review-task-id>/<perspective>/pass-NN/{input.md, result.md}`) 의 sidecar 가 evidence file 안에 들어가지 않고, evidence file 본문이 canonical record 의 일부도 아니다. 다만 `input.md` 본문이 evidence file 의 path 를 referencing 하여 reviewer 가 그 본문을 read-only 로 inspect 할 수 있다 — 이 referencing 은 R1 Markdown evidence convention 의 일부이며 `docs/contracts/review/REVIEW_RESULT_CONTRACT.md` §3a 가 의미 source-of-truth 다.

두 트리는 같은 `log/` 아래에 있지만 책임이 다르다:

- `log/review/` — review subsystem이 생성하고 검증하는 canonical record.
- `log/evidence/` — 사람이 또는 자유형 capture가 남기는 보조 기록. `input.md` 가 path 로 referencing 할 수 있는 reviewer-readable supporting material.

## source vs runtime 경계

이 contract는 runtime artifact에만 적용된다.

- `templates/`, `scripts/`, `config/`, `snippets/`, `docs/` 등 source 트리에는 evidence 파일을 두지 않는다.
- evidence를 source repo에 commit하지 않는다.
- evidence가 필요해서 case 디렉터리에 fixture를 만드는 경우에도 그 fixture는 `log/evidence/<scope>/<case>/` 안에서만 생성한다.

## non-goals

이 contract가 다루지 않는 것:

- evidence 자동 capture wrapper
- evidence 자동 retention 정책
- evidence schema validator
- review subsystem freshness 검증 (별도 책임)
- CI integration
- 다른 toolset과의 evidence format 상호운용

## 향후 확장 시 고려 사항

이후 자동화 도구가 추가될 때에도 본 contract의 path와 file 이름은 default로 유지되어야 한다. 즉,

- 새 wrapper는 `log/evidence/<scope>/<case>/command.txt`, `exit-code.txt` 등을 만들거나 읽는 형태로 동작한다.
- 새 schema가 도입되어도 이 manual convention과 모순되지 않도록 한다.
- 새 retention 정책은 `<scope>` 단위 prune이 자연스럽게 가능하도록 설계한다.
