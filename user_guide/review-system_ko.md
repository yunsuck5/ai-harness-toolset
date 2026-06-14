# ai-harness-toolset 리뷰 시스템 가이드

> **이 문서의 성격 (먼저 읽어 주세요).**
> 이 문서는 `ai-harness-toolset`의 리뷰 시스템을 처음 보는 사람이 이해하고 사용할 수 있도록 돕는 **사용자 가이드**입니다.
> 이 문서는 source-of-truth도, active surface도 아닙니다. 실제 동작 계약은 repo의 active surface — 대표적으로 `scripts/**`, `templates/**`, `snippets/**`, `rules/**`, skill payload, `config/**`, `tests/**`, root `CLAUDE.md` / `AGENTS.md` 등 — 가 소유합니다.
> 이 문서의 설명과 active surface가 다르면 **언제나 active surface가 우선**하며, 이 문서가 정정 대상입니다.

## 1. 이 문서의 목적

이 가이드는 다음을 돕습니다.

- 리뷰 시스템이 무엇을 하는지 빠르게 이해하기
- 어떤 상황에서 리뷰를 요청하면 좋은지 알기
- 리뷰 결과(특히 verdict)를 올바르게 해석하기
- 리뷰 결과를 commit/push 승인과 혼동하지 않기

리뷰 시스템의 세부 동작이 궁금하면 이 문서가 아니라 repo의 해당 active surface를 보면 됩니다.

## 2. 리뷰 시스템을 한 문장으로

`ai-harness-toolset`의 리뷰 시스템은 AI가 만든 변경을 "좋아 보인다" 정도로 판단하지 않고, **정해진 관점과 기록 형식에 따라 검토한 뒤 그 결과를 추적 가능한 파일로 남기는 품질 게이트**입니다.

이 시스템은 독립 reviewer의 검토를 `input.md` / `result.md` 한 쌍으로 닫고, 검토를 두 관점(`local-correctness`, `system-coherence`)으로 나누어 작은 정확성과 큰 구조 정합성을 따로 봅니다.

## 3. 언제 리뷰를 요청하는가

다음과 같은 순간이 리뷰를 요청하기 좋은 시점입니다.

- 변경을 commit하기 전에 점검하고 싶을 때
- 큰 구조 변경(이동/삭제/이름 변경)을 한 뒤 빠진 참조가 없는지 확인하고 싶을 때
- 한 파일은 맞아 보이는데 전체 구조와 충돌하지 않는지 걱정될 때
- 어떤 단계로 넘어가도 되는지(예: 다음 작업 단계, closeout) 판단 근거가 필요할 때

리뷰는 "통과 도장"이 아니라 **의사결정을 돕는 구조화된 근거**입니다. 그래서 commit/push가 급하지 않아도, 판단이 필요할 때 부담 없이 요청할 수 있습니다.

## 4. 자연어 요청 예시

사용자는 CLI 인자를 직접 구성하지 않습니다. 자연어로 요청하면 AI agent가 repo 상태와 목적을 해석해 리뷰 입력을 준비합니다.

```text
현재 진행한 작업 코덱스 리뷰 진행해
지금까지 한 작업 리뷰해 줘
이 변경 commit 전에 리뷰해줘. commit은 하지 마.
현재 작업을 local-correctness와 system-coherence 두 관점으로 리뷰해줘.
```

요청할 때 다음을 분명히 하면 결과가 더 정확해집니다.

- 무엇을 판단하고 싶은가 (commit 가능성, 단계 진입 등)
- 어떤 범위를 봐야 하는가 (현재 변경, 특정 모듈, 특정 문서)
- 어떤 행동은 하지 말아야 하는가 (수정 금지, commit 금지 등)

## 5. review artifact 구조

리뷰 기록은 대상 프로젝트의 runtime log 아래에 남습니다.

```text
<ProjectRoot>/log/review/<review-task-id>/<perspective>/pass-NN/
  input.md
  result.md
```

- `<review-task-id>`: 하나의 작업 또는 하나의 리뷰 게이트를 식별하는 이름입니다. 채팅 세션 id가 아닙니다.
- `<perspective>`: 리뷰 관점입니다. 대표적으로 `local-correctness`, `system-coherence`. 필수 값이며 생략하면 실패합니다.
- `pass-NN`: 같은 관점 안에서의 재검토 시도 번호입니다(`pass-01`, `pass-02`, ...). 리뷰 "종류"가 아니라 수정 후 다시 본 횟수입니다.

각 `pass-NN` 디렉터리는 한 번 쓰면 끝(write-once)입니다. 입력이나 결과가 틀렸거나 오래되면 같은 관점 아래 새 `pass-NN`을 만들고, 기존 pass를 고쳐 덮어쓰지 않습니다.

보조적으로, 프로젝트 상태 전달용 Brief는 다음 경로에 남습니다.

```text
<ProjectRoot>/log/brief/BRIEF.md
```

`log/review/`와 `log/brief/`는 모두 **runtime artifact**이며 source control(commit/push) 대상이 아닙니다.

## 6. input.md와 result.md

### input.md (AI가 작성)

`input.md`는 operator 역할의 AI가 작성하는 reviewer 입력 파일입니다. 무엇을 왜 리뷰하는지, 어떤 파일을 봐야 하는지, 어떤 질문에 답해야 하는지를 담습니다. 핵심 섹션 예시는 다음과 같습니다.

- 어떤 작업을 왜 리뷰하는가 (맥락)
- reviewer가 실제로 읽어야 할 파일과 경로
- reviewer가 답해야 할 중립적 질문
- reviewer가 하면 안 되는 일 (제약)
- `yes / no / yes with risk` 중 하나를 요구하는 최종 verdict 지시

좋은 입력은 검증 근거를 과장하지 않고, 이미 알고 있는 제한과 위험을 숨기지 않습니다.

### result.md (reviewer + runner)

`result.md`는 두 부분으로 이루어집니다. verdict와 finding 본문은 reviewer가 작성하고, 실행 사실(provenance) 블록은 runner가 끝에 덧붙입니다.

결과를 읽을 때는 verdict 한 줄만 보지 말고, 함께 기록되는 disclosure 섹션을 같이 읽어야 합니다.

- `## Blocking findings`
- `## Non-blocking concerns`
- `## Review limitations`
- `## Assumptions relied on`

이 네 섹션이 실제 판단 근거이며, verdict는 그 결론을 담은 짧은 결론 값일 뿐입니다.

## 7. verdict의 의미

verdict는 정확히 세 값만 사용합니다.

```text
yes
no
yes with risk
```

- **yes** — 진행을 막는 blocking finding이 없다는 뜻입니다. **commit/push/배포 승인이 아닙니다.**
- **no** — blocking finding이 있다는 뜻입니다. 승인된 작업 범위 안의 finding이면 수정 후 같은 작업·관점 아래 새 pass로 다시 리뷰합니다.
- **yes with risk** — blocking finding은 없지만 명시된 위험이 있다는 뜻입니다. **`yes`의 동의어가 아닙니다.** 사람이 그 위험을 이해하고 수용하거나, 위험을 줄이는 추가 수정·재리뷰가 필요합니다.

어떤 verdict도 commit / push / publish / release를 자동으로 승인하지 않습니다. 다음 단계는 항상 사용자가 별도로 결정합니다.

## 8. local-correctness와 system-coherence

리뷰는 두 관점으로 나뉩니다. 두 관점은 서로를 대체하지 않습니다.

### local-correctness

"이 변경 자체가, 지정된 대상 안에서, 말한 대로 정확한가"를 봅니다.

- 대상 파일이 정확히 선정되었는가
- 변경 내용이 자기 내부에서 모순되지 않는가
- 삭제/이동/이름 변경 후 끊긴 참조가 남지 않았는가
- 문서 형식과 결과 형식 같은 artifact 규약이 지켜졌는가

쉽게 말해 "이 변경이 자기 발밑에서 미끄러지지 않는가"를 봅니다.

### system-coherence

"이 변경이 프로젝트 전체의 구조와 경계 안에서 맞는가"를 봅니다.

- 변경이 올바른 owner surface에 흡수되는가
- 설명용 문서를 동작의 권한처럼 잘못 쓰고 있지 않은가
- 여러 표면(scripts, snippets, skill, tests, 설치 표면 등)의 경계를 침범하지 않는가
- commit/push 같은 별도 승인 경계를 흐리지 않는가

이 관점은 파일 수로 쪼개 보기 어렵습니다. 한 파일만 보면 괜찮아도 전체 경계와 충돌할 수 있어, 보통 전체 구조를 함께 봐야 합니다.

`local-correctness`가 `yes`여도 `system-coherence`가 `no`일 수 있고, 그 반대도 가능합니다.

## 9. corrected-state review

리뷰 후 소스나 문서가 바뀌면 이전 리뷰는 더 이상 그 상태를 설명하지 못합니다(stale).

`corrected-state review`는 수정 전 상태를 리뷰하고 끝내는 것이 아니라, **수정이 반영된 working tree를 같은 작업·관점 아래 새 `pass-NN`으로 다시 리뷰**하는 것을 뜻합니다. 그래서 "한 번 리뷰했으니 끝"이 아니라, 변경이 생기면 그 변경된 상태가 다시 검토 대상이 됩니다.

## 10. 사람이 결과를 해석하는 방법

- **verdict 한 줄만 보고 결정하지 않습니다.** disclosure 섹션(특히 blocking/non-blocking, limitations, assumptions)을 함께 읽습니다.
- **`yes`는 승인 버튼이 아닙니다.** commit/push/release가 필요하면 별도 승인을 받습니다.
- **`yes with risk`는 `yes`가 아닙니다.** 위험을 사람이 명시적으로 수용해야 진행합니다.
- **두 관점을 구분해 받아들입니다.** 한 관점이 괜찮아도 다른 관점이 막을 수 있습니다.
- **검증 범위를 확인합니다.** reviewer는 입력에 적힌 evidence를 읽을 뿐, 사용자의 검증 명령(빌드/테스트 등)을 자동으로 다시 실행하지 않습니다. 무엇이 실제로 검증되었는지 결과에서 확인하세요.

## 11. AI agent가 지켜야 할 것

AI agent는 리뷰 시스템을 단순 실행기로 쓰면 안 됩니다. agent의 역할은 operator입니다 — 리뷰가 올바른 질문을 받도록 준비하고, 결과를 사람이 판단 가능한 형태로 번역합니다.

- 리뷰 대상 범위를 먼저 정하고, 실제 변경 집합과 대조해 정확히 잡습니다. 일부러 뺀 파일이 있으면 그 사실을 밝힙니다.
- 입력 질문을 중립적으로 씁니다. "이거 맞지?"가 아니라 "blocking finding이 있는가?"처럼 묻습니다.
- 검증 근거를 과장하지 않습니다. 실행하지 않은 검증을 암시하지 않습니다.
- 이미 아는 제한·위험을 숨기지 않습니다. 나중에 빠뜨린 게 드러나면 그 결과는 신뢰할 수 없게 됩니다.
- 이름 변경/삭제/이동 시 참조 점검을 실제로 수행하고 기록합니다.
- 결과를 구조적으로 읽습니다. verdict만 보고 끝내지 않습니다.
- verdict를 행동으로 자동 변환하지 않습니다. `yes`여도 commit하지 않고, `yes with risk`면 위험 수용을 먼저 받습니다.

## 12. 하지 말아야 할 것

사람과 AI 모두 다음을 피해야 합니다.

- verdict를 commit/push/publish/release 승인으로 취급하기
- `yes with risk`를 그냥 `yes`로 취급하기
- 결과의 verdict 한 줄만 보고 disclosure를 읽지 않기
- 오래된(stale) pass를 재사용하거나, 실패한 pass를 고쳐 덮어쓰기
- `log/**` runtime artifact를 commit 대상으로 삼기
- reviewer가 검증을 자동으로 다시 실행했을 것이라고 가정하기
- `system-coherence`를 파일 수 기준으로 쪼개 보기
- 설명용 문서에 글이 있다는 이유만으로 그 문서를 동작의 권한처럼 오해하기

## 13. 고급 용어는 어디서 확인하는가

이 문서는 용어집이 아닙니다. 아래 용어들의 정식 의미와 accepted wording은 `rules/terminology-glossary.md`를 기준으로 합니다. 여기서는 처음 읽는 사람이 이 용어들을 주로 어디서 만나는지만 안내합니다.

리뷰 시스템을 사용하다 보면 다음과 같은 용어를 만날 수 있습니다.

| 용어 | 주로 만나는 맥락 |
|---|---|
| `active surface` | 실제 동작을 정의하는 scripts / templates / snippets / rules 등을 설명용 문서와 구분할 때 |
| `owner surface` | 어떤 계약이나 의미를 어느 파일·영역이 소유하는지 가릴 때 |
| `source-of-truth` / `single home` | 같은 의미를 여러 곳에 중복 정의하지 않으려고 기준 위치를 정할 때 |
| `Work Packet` | 특정 작업 라운드의 임시 분석 문서를 가리킬 때 |
| `4-class reference sweep` | 삭제 / 이동 / 이름 변경 후 끊긴 참조를 찾을 때 |
| `dual-perspective coverage` | `local-correctness`와 `system-coherence` 두 관점 충족을 말할 때 |
| `rejected umbrella` | 너무 넓어 owner가 흐려지는 범주를 되살리지 않으려 할 때 |
| `mutation approval` / `commit approval` / `push approval` | 파일 수정·commit·push 승인을 서로 구분할 때 |
| `review owner surface` | 리뷰 verdict와 artifact 규약의 의미를 다른 곳에서 재정의하지 않도록 할 때 |

정식 정의가 필요하면 `rules/terminology-glossary.md`를 확인하십시오.

## 14. 짧은 요약

- 리뷰 기록은 `log/review/<task>/<perspective>/pass-NN/`에 남는 runtime artifact다.
- `local-correctness`는 변경 자체의 정확성을, `system-coherence`는 전체 구조 정합성을 본다.
- `pass-NN`은 리뷰 종류가 아니라 수정 후 재검토 횟수다.
- verdict는 `yes`, `no`, `yes with risk` 세 개뿐이다.
- `yes with risk`는 `yes`가 아니며 위험 수용이 필요하다.
- verdict는 commit/push/publish/release 승인이 아니다.
- 결과는 verdict 한 줄이 아니라 disclosure 섹션까지 함께 읽는다.
- reviewer는 입력 evidence를 읽을 뿐 검증을 자동으로 다시 실행하지 않는다.
- 이 문서는 사용자 가이드이며, 실제 동작 계약은 repo의 active surface가 소유한다.
