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

## MVP 규칙

- 모든 파일을 필수로 강제하지 않는다.
- `command.txt`와 `exit-code.txt`는 recommended로 둔다.
- `stdout.txt`, `stderr.txt`, `notes.md`, `files/`는 필요할 때만 둔다.
- evidence는 review subsystem의 품질 게이트가 아니다.
- review packet freshness 판단은 review subsystem이 담당한다 (`scripts/review-prepare.ps1`, `scripts/review-verify.ps1`).
- evidence는 실행 사실, command output, 재현 단서, file snapshot을 보관하는 보조 기록이다.
- source snapshot에는 `log/`를 포함하지 않는다.
- `log/evidence/`는 gitignored runtime artifact로 유지한다 (`.gitignore`의 `log/` 규칙).

## review subsystem과의 경계

review subsystem은 별도 경로를 사용한다:

- review packet은 `<ProjectRoot>/log/review/<run-id>/` 에 생성된다.
- review packet의 freshness, hash 일치, project root 일치 등은 review-prepare / review-verify가 검증한다.

evidence는 review subsystem의 input이 아니며, output도 아니다. 두 트리는 같은 `log/` 아래에 있지만 책임이 다르다:

- `log/review/` — review subsystem이 생성하고 검증하는 packet.
- `log/evidence/` — 사람이 또는 자유형 capture가 남기는 보조 기록.

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
