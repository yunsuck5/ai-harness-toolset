# Chatlog Minimal Retention and Resume Contract

`log/chatlog/` 아래에 AI-assisted development session의 작업 기록과 작업 재개용 brief를 어떤 최소 형식으로 남길지 정의한다.

이 문서는 **manual convention first** 문서다. hook, parser, browser automation, DB, retention automation은 포함하지 않는다.

## 목적

- AI CLI agent (Claude Code, Codex CLI 등)가 진행한 한 묶음의 작업을 사람이 읽는 file 형태로 보존한다.
- 다음 CLI agent 또는 다음 사람이 작업을 **재개**할 때 가장 먼저 읽을 짧은 brief를 남긴다.
- 자동화 schema 없이도 사람이 읽고 쓸 수 있는 형식을 유지한다.

이 contract는 chatlog 자동화를 보장하는 문서가 아니라, project-local chatlog 파일의 위치, 이름, 작성 원칙, 최소 구조에 관한 합의다.

## chatlog의 위치와 독자

chatlog는 `ai-harness-toolset`의 **first-class subsystem**이다. review subsystem이 만든 부산물도 아니고, evidence subsystem의 하위 트리도 아니다. review / evidence와 같은 `log/` 트리 아래에 살지만, 책임 영역이 독립이다.

독자 우선순위:

- 제1독자는 **사람**이다. 다음 사람이 작업을 이어받을 때 가장 먼저 열어 즉시 상황을 파악할 수 있어야 한다.
- 제2독자는 **AI**다. CLI agent가 새 session 시작이나 context 손실 후 복원을 위해 chatlog를 읽는다.

따라서 chatlog 작성 우선순위는 "AI가 다시 읽어 자기 자신을 복원하기 좋은 형식"이 아니라 "사람이 먼저 읽고 즉시 상황을 파악할 수 있는 형식"이다. AI-friendly 구조는 사람-friendly 구조의 부산물로 충족되면 충분하다.

## chatlog가 담당하지 않는 것

- AI CLI raw transcript의 자동 capture
- session 경계 자동 감지
- 80% context trigger 또는 pre-compact resume packet 자동 생성
- browser 기반 ChatGPT Web 대화 capture
- session DB 또는 index 관리
- retention / prune 자동화
- review subsystem이 사용하는 packet freshness 판단
- evidence 자동 수집
- CI integration

위 항목 중 일부는 [Future candidate](#future-candidate) 절에 기록한다. MVP에서는 구현하지 않는다.

## review / evidence subsystem과의 경계

`log/` 아래에는 세 종류의 트리가 공존한다. 책임이 서로 다르다.

| 트리 | 책임 | 검증 주체 |
|---|---|---|
| `log/chatlog/` | session 작업 기록과 resume brief 보존 | 사람 (manual convention) |
| `log/evidence/` | command 실행 사실, output, 재현 단서 보존 | 사람 (manual convention, `docs/EVIDENCE_CONTRACT.md`) |
| `log/review/<run-id>/` | review packet과 freshness 검증 | `scripts/review-prepare.ps1`, `scripts/review-verify.ps1` |

- chatlog는 review subsystem의 input이 아니며, output도 아니다.
- chatlog는 evidence subsystem의 input이 아니며, output도 아니다.
- 셋은 같은 `log/` 아래에 있지만 서로 enforce하지 않는다.

chatlog summary가 evidence file을 **참조**하는 것은 권장된다. 그러나 chatlog가 evidence나 review packet의 정합성을 담당하지는 않는다.

## 경로 규약

`log/chatlog/`는 project-local runtime artifact 영역이다.

- source repo 모드: `<repo-root>/log/chatlog/`
- target payload 모드: `<project-root>/log/chatlog/`

두 경우 모두 `log/`는 gitignored runtime artifact 트리이며 source snapshot에 포함하지 않는다.

권장 layout:

```
<ProjectRoot>/log/chatlog/current/
  resume.md
  summary.md
  decisions.md        optional
  raw-transcript.md   optional

<ProjectRoot>/log/chatlog/<session-id>/
  resume.md
  summary.md
  decisions.md        optional
  phases/             optional
  raw-transcript.md   optional
```

- `current/`는 진행 중인 session 또는 가장 최근에 닫힌 session의 작업 영역이다. 다음 agent가 가장 먼저 보는 자리다.
- `<session-id>/`는 닫힌 session을 보존하는 자리다. session-id 형식은 manual convention이며 강제하지 않는다. 권장 형식은 `YYYYMMDD-<short-slug>`이다 (예: `20260430-chatlog-contract`).
- 같은 session을 `current/`에서 `<session-id>/`로 옮기거나 복사하는 것은 사람이 결정한다.

`LATEST.md`는 있으면 편리하지만 이번 scope에서는 강제하지 않는다. 한 줄로 가장 최근 session-id를 가리키는 optional convenience marker로만 활용한다. MVP에서는 도입하지 않아도 된다.

## 권장 파일 구성

각 session 디렉터리 (`current/` 또는 `<session-id>/`) 아래에 다음 file 이름을 사용한다.

| 파일 | 역할 | MVP 위치 |
|---|---|---|
| `resume.md` | 다음 agent가 작업을 재개할 때 가장 먼저 읽는 짧은 brief | recommended |
| `summary.md` | session 한 묶음의 결론, 결정, 변경 범위 요약 | recommended |
| `decisions.md` | session 중 내려진 의사결정 기록 (필요 시) | optional |
| `phases/` | session을 phase 단위로 쪼갤 때 사용하는 하위 디렉터리 | optional |
| `raw-transcript.md` | CLI 또는 chat의 원문 transcript 캡처 | optional |

위 이름은 권장이다. 같은 의도의 파일이라면 이 이름을 쓰라는 합의다.

## 사용자 원문과 AI 작성물의 분리

chatlog는 **사용자 원문**과 **AI 작성물**을 같은 단락에 섞지 않는다. 두 종류의 텍스트는 서로 다른 신뢰도와 권위를 가지므로, 독자(사람과 AI 모두)가 출처를 즉시 구분할 수 있어야 한다.

원칙:

- 사용자 원문(user-original)은 가능한 한 **verbatim**으로 보존한다. summarize, compress, rephrase, translate, interpret 하지 않는다.
- 사용자가 한국어로 입력했다면 한국어 원문 그대로 보존한다. 영문 요약으로 바꾸지 않는다 (그 반대도 동일).
- AI-authored summary, judgment, decision, change description은 **별도 section** 또는 **별도 파일**에 둔다.
- 한 bullet 안에 사용자 원문과 AI 판단을 같이 쓰지 않는다. 짧은 verbatim excerpt를 인용한 다음 별도 줄에서 AI 판단을 기록한다.
- 사용자 원문이 길어 별도 파일이 필요한 경우 `raw-transcript.md` 또는 별도 `user-input.md` 파일에 둔다. 이 파일은 AI 가공을 받지 않는다.

이 분리 원칙은 canonical file-separated layout과 single-file fallback layout 모두에 적용된다.

## canonical layout과 single-file fallback

권장(canonical) 구성은 file 단위 분리다. 각 파일이 한 가지 역할만 담당한다.

```
log/chatlog/current/
  resume.md          # AI-authored. 다음 사람/AI가 가장 먼저 읽는 짧은 brief
  summary.md         # AI-authored. 종료된 작업 한 묶음의 요약
  decisions.md       # 의사결정 기록. user-original reference와 AI judgment를 분리
  raw-transcript.md  # 사용자 원문/CLI 원문의 verbatim 보존 (optional)
```

- `resume.md` / `summary.md` / `decisions.md`는 AI-authored 자리이지만, 사용자 원문 인용이 필요하면 짧은 verbatim excerpt와 reference link만 둔다.
- 사용자 원문 전문을 보존하고 싶다면 `raw-transcript.md` 또는 별도 `user-input.md` 파일을 사용한다.

별도 file 분리가 부담스러운 경우 single-file fallback layout을 허용한다. 단, **section 단위 분리**는 그대로 적용한다.

```markdown
# Session Chatlog

## User original input

> 사용자 원문 verbatim. 가공하지 않는다.

## AI-authored summary

> AI가 작성한 요약. 사용자 원문을 옮겨 적지 않는다.

## AI judgment

> AI가 내린 판단. 사용자 원문 인용이 필요하면 짧은 quote만 사용한다.

## Decisions

> 결정 기록. 각 entry 안에서 `User original reference`와 `AI judgment`를 분리한다.
```

single-file fallback은 어디까지나 fallback이며, 작업이 누적되면 canonical layout으로 이행하는 것을 권장한다.

## summary-first 원칙

session이 의미 있는 작업 단위로 마무리되었다면, **`summary.md`를 먼저 남긴다.**

- 사람이 읽고 무엇이 끝났고 무엇이 남았는지 한 눈에 알 수 있어야 한다.
- raw-transcript의 길이와 무관하게 summary는 짧고 자족적이어야 한다.
- summary는 raw-transcript를 대체할 수 있을 정도로 사실 기반이어야 한다.
- summary template은 `templates/session-summary.md`를 참고한다.

raw-transcript가 없어도 summary만으로 다음 사람이 맥락을 이해할 수 있는 상태가 MVP의 minimum bar다.

## resume-first 원칙

다음 CLI agent가 작업을 이어받을 때, **가장 먼저 열어야 하는 파일은 `resume.md`다.**

- `resume.md`는 "지금 무엇을 해야 하는가"에 대한 single source of truth이다.
- summary가 과거 시제(끝난 것)라면, resume은 현재/미래 시제(이어서 할 것)이다.
- resume template은 `templates/session-resume.md`를 참고한다.

resume.md가 없으면 다음 agent는 summary.md, decisions.md, raw-transcript.md를 순서대로 보면서 직접 brief를 재구성해야 한다. 가능하면 resume.md를 남기는 것이 비용을 가장 낮춘다.

## 다음 agent의 read 순서

다음 사람 또는 다음 CLI agent가 chatlog를 읽을 때 권장 순서는 다음과 같다.

1. `log/chatlog/current/resume.md`가 있으면 먼저 읽는다.
2. 없으면 `summary.md`를 읽는다.
3. 추가 의사결정 맥락이 필요하면 `decisions.md`를 읽는다.
4. 사용자 원문 그대로의 wording이 필요할 때만 `raw-transcript.md`를 읽는다.

이 read 순서는 사람과 AI 모두에게 동일하게 적용된다. AI가 먼저 `raw-transcript.md`를 읽어 자체 요약을 만드는 우회는 권장하지 않는다 — `resume.md` / `summary.md`가 이미 AI-authored 요약 자리다.

## meaningful work 이후 closeout update

agent가 의미 있는 작업으로 session state를 변경했다면, 종료 또는 handoff 직전에 `summary.md`와 `resume.md`를 갱신한다.

- 새로 확정된 사실, 새 결정, 다음 단일 action을 반영한다.
- 사용자 원문은 갱신 대상이 아니다 (verbatim 보존 대상이므로 손대지 않는다).
- 갱신을 미루면 다음 agent가 이미 사실과 어긋난 brief를 신뢰하는 risk가 발생한다.
- 단순 read-only 탐색만 했고 session state가 바뀌지 않았다면 갱신을 강제하지 않는다.

## summary.md required / optional sections

`summary.md`는 다음 canonical heading을 사용한다.

required:

- `## Context` — 이번 session이 다룬 작업의 배경과 scope.
- `## Decisions` — 이번 session에서 내려진 결정.
- `## Evidence` — 결정과 진행을 뒷받침하는 사실 (commit hash, dogfood 결과, evidence path 등).
- `## Next action` — session이 끝나는 시점에서 다음 단계.
- `## Carry-over` — 이번 session에서 끝내지 못해 다음 session으로 넘기는 항목. 없으면 `none`.

optional:

- `## Files inspected`
- `## Session phase`
- `## Pending prompt`
- `## Artifact links`
- `## Notes`

required section 중 내용이 없으면 `none`이라고만 적는다. optional section은 필요할 때만 추가한다. 임의의 새 top-level heading은 만들지 않는다.

## resume.md required / optional sections

`resume.md`는 다음 canonical heading을 사용한다.

required:

- `## Current state`
- `## Last completed action`
- `## Current scope`
- `## Next single action`
- `## Do not do`
- `## Files to inspect first`
- `## Open risks`
- `## Pending user decision`

optional:

- `## Relevant artifacts`
- `## Carry-over`
- `## Notes`

`resume.md`는 짧을수록 좋다. required section 중 내용이 없으면 `none`으로 채운다. optional section은 필요할 때만 추가한다.

## canonical heading 정책과 ad-hoc heading mapping

template의 required section 이름은 canonical heading이다. agent가 매번 새 top-level heading set을 만들지 않도록 한다.

원칙:

- canonical heading은 그대로 유지한다. 의미가 비슷한 임의의 변형 (`## Completed`, `## Deferred`, `## Context needed` 등)을 새 top-level heading으로 도입하지 않는다.
- ad-hoc 정보는 canonical heading 아래 bullet 또는 subsection으로 흡수한다.
- 필요하면 bullet 안에서 `Completed:`, `Stop-lines:`처럼 inline label을 써도 된다. top-level `## Completed`는 만들지 않는다.

`Chatlog current-session dogfood v1`에서 등장한 ad-hoc heading은 다음과 같이 흡수한다.

| ad-hoc heading | canonical 흡수 위치 |
|---|---|
| `Completed` | summary `Decisions` 또는 resume `Last completed action` 아래 bullet |
| `Runtime dogfood` | summary `Evidence` 아래 bullet |
| `Current stop-lines` | summary `Decisions` 또는 resume `Current state` 아래 bullet |
| `Deferred` | summary `Carry-over` 또는 resume `Do not do` 아래 bullet |
| `Context needed` | resume `Files to inspect first` 또는 `Relevant artifacts` 아래 bullet |
| `Notes` | summary / resume의 optional `Notes` (그대로 유지 가능) |

## current/ 와 <session-id>/ 운영 정책

- `log/chatlog/current/`는 active-session resume에 valid한 위치다. `current/` 아래 `summary.md`와 `resume.md`만 있어도 다음 agent가 작업을 재개할 수 있다.
- `log/chatlog/<session-id>/`로의 promotion은 MVP에서 optional이며 사람이 trigger한다.
- MVP에서는 `current/`를 자동으로 `<session-id>/`로 옮기지 않는다. wrapper, hook, scheduler가 promotion을 수행하지 않는다.
- 사람이 promotion을 결정한 시점에만 `<session-id>/`를 만든다. session-id 형식은 manual convention이며 강제하지 않는다 (권장: `YYYYMMDD-<short-slug>`).

## file 이름 scope 정책

- `summary.md`와 `resume.md`라는 이름은 `log/chatlog/` 경로 안에서만 chatlog의 의미를 갖는다.
- 다른 subsystem (review, evidence, scripts, docs, snippets, config 등)은 임의 경로의 `**/summary.md`, `**/resume.md`에서 chatlog의 의미를 추론하지 않는다.
- 외부 grep / 검색 도구가 같은 이름을 다른 의미로 쓸 가능성을 가정하지 않는다. chatlog의 의미는 `log/chatlog/` 아래 path에서만 valid하다.

## encoding 정책

- chatlog `.md` runtime artifact를 PowerShell로 만들 때는 `scripts/lib/encoding.ps1`의 `Write-Utf8NoBom`을 사용한다.
- 이는 manual convention이다. 새 wrapper, parser, generator, hook을 도입하라는 의미가 아니다.
- 모든 chatlog `.md` runtime artifact는 UTF-8 without BOM이다.
- `Set-Content -Encoding UTF8`, `Add-Content -Encoding UTF8`, `Out-File`은 사용하지 않는다.

## raw-transcript.md optional 원칙

`raw-transcript.md`는 **선택**이다.

- summary와 resume이 충실하다면 raw-transcript는 없어도 된다.
- raw-transcript가 있는 경우에도 summary와 resume의 권위를 침범하지 않는다. 두 파일이 우선이다.
- raw-transcript는 사후 forensic 또는 재현 용도로만 활용한다.
- raw-transcript의 자동 capture는 본 contract의 책임이 아니다.

## session phase 와 carryover

긴 session을 phase 단위로 쪼갤 필요가 있을 때만 다음 convention을 쓴다.

- `phases/` 하위 디렉터리에 phase 단위 sub-summary를 둔다 (예: `phases/01-design.md`, `phases/02-impl.md`).
- 끝나지 않은 작업을 다음 session으로 carry-over할 때는 `summary.md`의 carry-over 섹션과 `resume.md`의 next single action에 명시한다.
- phase 분할이 필요 없는 session은 phase 디렉터리를 만들지 않는다.

phase / carryover 개념은 모두 optional이다. MVP의 minimum bar는 `summary.md` + `resume.md` 둘이다.

## handoff.md 와의 구분

`handoff.md`는 **repo source artifact가 아니다.**

- handoff.md는 ChatGPT Web 또는 외부 review 채널로 한 묶음의 진행 상태를 인계하기 위한 외부 artifact다.
- 사용자는 handoff 문서를 Web 대화 세션 단위의 별도 폴더에서 관리한다.
- 본 repo는 handoff folder, handoff template, handoff schema를 두지 않는다.
- chatlog의 `summary.md` / `resume.md`가 handoff.md의 작성 재료로 쓰일 수는 있지만, chatlog가 handoff를 강제하지 않는다.

따라서 본 contract는 handoff의 위치, 형식, 전송 방식을 규정하지 않는다.

## MVP 규칙 요약

- 모든 파일을 필수로 강제하지 않는다.
- `summary.md`와 `resume.md`는 recommended로 둔다.
- `decisions.md`, `phases/`, `raw-transcript.md`는 필요할 때만 둔다.
- chatlog는 review subsystem의 품질 게이트가 아니다.
- chatlog는 evidence subsystem의 품질 게이트가 아니다.
- source snapshot에는 `log/`를 포함하지 않는다.
- `log/chatlog/`는 gitignored runtime artifact로 유지한다 (`.gitignore`의 `log/` 규칙).
- hook, parser, browser automation, DB, retention automation은 도입하지 않는다.

## source vs runtime 경계

- `templates/`, `scripts/`, `config/`, `snippets/`, `docs/` 등 source 트리에는 chatlog 파일을 두지 않는다.
- chatlog를 source repo에 commit하지 않는다.
- chatlog가 참조하는 fixture, snapshot은 `log/chatlog/<session-id>/` 또는 `log/evidence/<scope>/<case>/` 안에서만 생성한다.

## non-goals

이 contract가 다루지 않는 것:

- AI CLI raw transcript 자동 capture wrapper
- chatlog 자동 retention 정책
- chatlog schema validator
- review subsystem freshness 검증 (별도 책임)
- evidence subsystem 보장 (별도 책임)
- CI integration
- 다른 toolset과의 chatlog format 상호운용

## Future candidate

아래 항목은 버리지 않는다. 다만 이번 MVP scope에서는 구현하지 않는다.

```
Future candidate:
- optional context-pressure guard
- optional pre-compact resume packet generation
- optional orchestrator-specific hook integration
- project-local and opt-in only
- no global ~/.claude/settings.json mutation by default
```

추가 메모:

- 80% context trigger는 향후 optional guard로 검토할 수 있다. 본 MVP에서는 사람이 판단한다.
- pre-compact 시점에 resume packet을 자동 생성하는 hook은 향후 candidate이며, 도입 시에도 project-local opt-in으로 한정한다.
- orchestrator-specific hook integration은 도입 시에도 global 설정을 변경하지 않는다.

## 향후 확장 시 고려 사항

이후 자동화 도구가 추가될 때에도 본 contract의 path와 file 이름은 default로 유지되어야 한다. 즉,

- 새 wrapper는 `log/chatlog/current/resume.md`, `summary.md` 등을 만들거나 읽는 형태로 동작한다.
- 새 schema가 도입되어도 이 manual convention과 모순되지 않도록 한다.
- 새 retention 정책은 `<session-id>` 단위 prune이 자연스럽게 가능하도록 설계한다.
