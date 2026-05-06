# chatlog contract — manual acceptance criteria

`docs/CHATLOG_CONTRACT.md`, `templates/session-summary.md`, `templates/session-resume.md`, `templates/decision-log.md`, `snippets/AGENTS_SNIPPET.md`, `snippets/CLAUDE_SNIPPET.md` 가 chatlog MVP contract 의 핵심 invariant 를 담고 있는지 확인하는 수동 검증 항목.

No Pester. No Codex. No commit. No push. 검증은 사람이 해당 파일을 직접 읽어 항목별 substring / structure 존재 여부를 확인하는 방식이다.

## Conventions

- Run all checks against the source repo root (`H:/Work/ai-harness-toolset/ai-harness-toolset`).
- 각 AC 는 한 가지 invariant 만 검증한다.
- 한 AC 가 fail 하면 chatlog contract 의 일부가 누락된 것이다. 다른 AC 진행 전에 보완한다.

## AC-chatlog-1 — first-class subsystem 명시

`docs/CHATLOG_CONTRACT.md` 가 chatlog 를 first-class subsystem 으로 명시하고, reviewer 의 부산물이 아님을 명시해야 한다.

Expected:

- 본문에 `first-class subsystem` 키워드와 reviewer 부산물이 아니라는 진술이 모두 존재한다.
- review subsystem / evidence subsystem 과의 책임 분리가 명시되어 있다 (기존 `review / evidence subsystem과의 경계` 절 포함).

## AC-chatlog-2 — primary reader = human, secondary reader = AI 명시

`docs/CHATLOG_CONTRACT.md` 가 독자 우선순위를 명시해야 한다.

Expected:

- 본문에 `제1독자` 가 사람이라는 진술이 존재한다.
- 본문에 `제2독자` 가 AI (CLI agent) 이며 session 복원을 위해 chatlog 를 읽는다는 진술이 존재한다.
- 작성 우선순위가 "사람이 먼저 읽고 즉시 상황을 파악할 수 있는 형식" 이라는 취지의 진술이 존재한다.

## AC-chatlog-3 — user-original / AI-authored 분리 명시

`docs/CHATLOG_CONTRACT.md` 가 사용자 원문과 AI 작성물을 섞지 않는다는 원칙을 명시해야 한다.

Expected:

- `사용자 원문과 AI 작성물의 분리` 절이 존재한다.
- "같은 단락에 섞지 않는다" 또는 동등한 진술이 존재한다.
- AI-authored summary / judgment / decision / change description 을 별도 section 또는 별도 파일에 둔다는 진술이 존재한다.

## AC-chatlog-4 — user-original 가공 금지 명시

`docs/CHATLOG_CONTRACT.md` 가 사용자 원문을 가공하지 않는다는 금지 동사 목록을 명시해야 한다.

Expected:

- 본문에 `summarize`, `compress`, `rephrase`, `translate`, `interpret` 다섯 동사가 모두 존재한다.
- 다섯 동사가 모두 "사용자 원문을 original 로 보존할 때" 의 금지 행동으로 명시되어 있다.

## AC-chatlog-5 — canonical layout 과 single-file fallback 모두 명시

`docs/CHATLOG_CONTRACT.md` 가 두 layout 을 모두 문서화해야 한다.

Expected:

- canonical file-separated layout 예시가 존재한다 (`resume.md`, `summary.md`, `decisions.md`, `raw-transcript.md` 가 별도 파일로 나열된 형태).
- single-file fallback layout 예시가 존재한다 (한 파일 안에 `## User original input`, `## AI-authored summary`, `## AI judgment`, `## Decisions` section 으로 나뉜 형태).
- single-file fallback 이 fallback 이며 canonical 로 이행을 권장한다는 진술이 존재한다.

## AC-chatlog-6 — decision-log 가 user reference / AI judgment 분리

`templates/decision-log.md` 가 entry 안에서 사용자 원문 reference 와 AI judgment 를 분리하는 구조를 보여줘야 한다.

Expected:

- `## User original reference` section 이 존재한다.
- `## AI judgment` section 이 존재한다.
- 두 section 이 같은 entry 안에 있고, 같은 bullet 에 섞지 않는다는 안내가 존재한다.
- 사용자 원문 인용 예시가 짧은 verbatim excerpt 형태로 제시되어 있다.

## AC-chatlog-7 — snippets 에 resume-first / closeout update protocol 반영

`snippets/AGENTS_SNIPPET.md` 와 `snippets/CLAUDE_SNIPPET.md` 둘 다 `## Chatlog session protocol` section 을 포함해야 하며, 두 snippet 의 policy substance 는 동일해야 한다.

Expected:

- 양쪽 snippet 에 `## Chatlog session protocol` heading 이 존재한다.
- 양쪽에 resume-first read 순서가 명시되어 있다 (`resume.md` → `summary.md` → `decisions.md` → `raw-transcript.md`).
- 양쪽에 사용자 원문과 AI 작성물을 섞지 말라는 directive 가 존재한다.
- 양쪽에 사용자 원문 가공 금지 동사 (summarize / compress / rephrase / translate / interpret) 가 모두 존재한다.
- 양쪽에 meaningful work 이후 `summary.md` 와 `resume.md` 를 갱신하라는 closeout directive 가 존재한다.
- Claude-specific 표현은 `CLAUDE_SNIPPET.md` 에만 추가될 수 있으나, 위 다섯 항목은 두 snippet 모두에서 충족되어야 한다.
