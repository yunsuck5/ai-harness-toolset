# chatlog contract — manual acceptance criteria

`docs/CHATLOG_CONTRACT.md`, `docs/MVP_OPERATOR_GUIDE_KR.md`, `templates/session-summary.md`, `templates/session-resume.md`, `templates/decision-log.md`, `snippets/AGENTS_SNIPPET.md`, `snippets/CLAUDE_SNIPPET.md`, `README.md` 가 chatlog MVP contract 의 핵심 invariant 를 담고 있는지 확인하는 수동 검증 항목.

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

## AC-chatlog-7 — snippets 에 BF 우선 read 순서 / closeout update protocol 반영

`snippets/AGENTS_SNIPPET.md` 와 `snippets/CLAUDE_SNIPPET.md` 둘 다 chatlog runtime 절을 포함해야 하며, 두 snippet 의 policy substance 는 동일해야 한다.

snippets 는 positive runtime protocol 만 담는다. 사용자 원문 / AI 작성물 분리 directive 와 5개 verbatim 보존 동사 (summarize / compress / rephrase / translate / interpret) 같은 contract substance 는 snippets 가 아니라 `docs/CHATLOG_CONTRACT.md` 가 carrier 다 (이 substance 는 AC-chatlog-3 / AC-chatlog-4 가 검사한다).

Expected:

- 양쪽 snippet 에 chatlog runtime heading (예: `## Chatlog (BF and CL)`) 이 존재한다.
- 양쪽에 BF 우선 read 순서가 명시되어 있다 — `log/chatlog/current/resume.md` 가 default session context 이고, `summary.md` 가 compact companion fallback 이며, 다른 chatlog 파일은 CL / history context 로만 참조된다는 점이 양쪽에서 합치한다.
- 양쪽에 BF 가 compact 하고 review / evidence / CL 을 path 로만 참조한다는 진술이 존재한다.
- 양쪽에 meaningful work 이후 `summary.md` 와 `resume.md` 를 갱신하라는 closeout directive 가 BF save 절차의 일부로 존재한다.
- Claude-specific 표현 (예: 정확한 한국어 ask 문구) 은 `CLAUDE_SNIPPET.md` 에만 추가될 수 있으나, 위 항목들의 substance 는 두 snippet 모두에서 충족되어야 한다.

## AC-chatlog-8 — BF (Brief) 와 CL (Chat Log) 책임 분리 명시

`docs/CHATLOG_CONTRACT.md` 가 BF 와 CL 의 책임 분리를 명시해야 한다.

Expected:

- 본문에 BF (Brief) 가 functional session restore / handoff / phase transition state 의 책임을 진다는 정의가 존재한다.
- 본문에 CL (Chat Log) 가 cumulative work history / portfolio / audit / decision trace 의 책임을 진다는 정의가 존재한다.
- 본문에 BF 가 MVP-required 이고 CL 의 fuller implementation 은 MVP scope 밖 (concept-boundary only) 이라는 진술이 존재한다.
- 본문에 BF 와 CL 의 책임이 서로 교환 가능하지 않다는 점이 명시되어 있다.
- 본문에 BF 의 canonical current 파일 경로가 `log/chatlog/current/resume.md` 라는 진술이 존재한다.
- 본문에 `log/chatlog/current/summary.md` 가 BF 의 compact companion 이며 full transcript store 가 아니라는 진술이 존재한다.

## AC-chatlog-9 — BF 가 path-only 참조 정책을 따르고 review / evidence canonical 위치 보존

`docs/CHATLOG_CONTRACT.md` 가 BF 의 compact 원칙과 path-only 참조 원칙을 명시해야 한다.

Expected:

- 본문에 BF 가 compact 해야 한다는 진술이 존재한다.
- 본문에 BF 가 review 결과 / evidence payload / 누적 CL 본문을 옮겨 적지 않고 path / link 로만 참조한다는 진술이 존재한다.
- 본문에 review artifact 의 canonical 위치가 `log/review/<run-id>/` 라는 진술이 존재한다.
- 본문에 evidence artifact 의 canonical 위치가 `log/evidence/` 라는 진술이 존재한다.

## AC-chatlog-10 — BF Level 2 restore-offer 동작이 snippets / operator guide 에 문서화

새 Claude Code 세션 진입 시의 restore-offer 동작이 `snippets/CLAUDE_SNIPPET.md`, `snippets/AGENTS_SNIPPET.md`, `docs/MVP_OPERATOR_GUIDE_KR.md` 에 모두 문서화되어 있어야 한다.

Expected:

- `snippets/CLAUDE_SNIPPET.md` 와 `snippets/AGENTS_SNIPPET.md` 가 모두 새 session 진입 시 `log/chatlog/current/resume.md` 존재 여부 확인 → 읽기 → 한국어 요약 → 사용자에게 이어서 진행할지 묻기 → 사용자 확인 후에만 진행의 순서를 명시한다.
- 양쪽 snippet 모두 step 3 또는 동등 위치에서 요약을 한국어로 한다는 점을 명시한다 (CLAUDE 측은 한국어 ask 문구 verbatim 가능).
- `snippets/CLAUDE_SNIPPET.md` 에 사용자에게 묻는 단계의 한국어 ask 문구 (예: `이 복구 지점에서 이어서 진행할까요?`) 가 verbatim 으로 존재한다.
- `snippets/AGENTS_SNIPPET.md` 는 agent-neutral 표현으로 같은 ask 단계를 갖되, 한국어 요약 요구는 명시한다.
- 양쪽 snippet 모두 `resume.md` 가 없을 때 `summary.md` 로 fallback 하고 누락 / 미흡함을 보고한다는 positive 진술을 포함한다.
- `docs/MVP_OPERATOR_GUIDE_KR.md` 에 같은 BF Level 2 restore-offer 절이 존재한다.
- raw transcript / 누적 CL 을 통째로 읽어 BF 를 임의로 재구성하지 말라는 contract 차원의 directive 는 `docs/CHATLOG_CONTRACT.md` 의 `## 다음 agent의 read 순서` 절이 carrier 다. snippets 가 carrier 일 필요는 없다.

## AC-chatlog-11 — BF save natural-language protocol 문서화

BF 저장이 Claude Code (또는 agent) 의 자연어 의도 protocol 으로 정의되어 있어야 한다 — 사용자 PowerShell workflow 가 아니다.

본 AC 의 6개 정식 trigger 발화 (verbatim Korean, 정확한 글자열 일치):

```text
현재 진행 지점을 복구 시점으로 저장해
BF 저장해
복구 지점 저장해
handoff 지점 만들어줘
다음 세션에서 이어갈 수 있게 정리해
현재 phase checkpoint 남겨줘
```

Expected:

- `snippets/CLAUDE_SNIPPET.md` 가 위 6개 발화를 모두 verbatim 으로 포함한다. 누락 / 변형 / 의역은 fail 이다.
- `snippets/AGENTS_SNIPPET.md` 가 위 6개 발화를 모두 verbatim 으로 포함한다. 누락 / 변형 / 의역은 fail 이다. agent-neutral 표현이라도 이 6개 trigger 자체는 그대로 노출되어야 manual acceptance criteria 가 두 snippet 사이의 drift 를 잡을 수 있다.
- 두 snippet 의 trigger set 이 substance 상 동일하다 (위 6개와 같은 집합, 같은 순서일 필요는 없으나 항목 set 이 동일).
- `snippets/CLAUDE_SNIPPET.md` 에 BF 저장 절차 (repo 상태 확인 → resume.md / summary.md 갱신 → review / evidence / CL 은 path 로만 참조 → BF compact 유지 → 보고) 가 positive runtime 형식으로 명시된다.
- `snippets/AGENTS_SNIPPET.md` 에 동일한 BF save 절차가 agent-neutral 표현으로 존재한다.
- `docs/MVP_OPERATOR_GUIDE_KR.md` 에 같은 BF save 자연어 protocol 절이 존재한다 (위 6개 발화 verbatim 포함 권장).
- BF save 가 사용자 PowerShell workflow 가 아니고 자연어 protocol 임을 명시하는 contract substance 는 `docs/MVP_OPERATOR_GUIDE_KR.md` 와 `docs/CHATLOG_CONTRACT.md` 가 carrier 다. snippets 는 trigger + 절차 자체로 그 의미를 운반하므로 별도 명시 진술을 강제하지 않는다.
- 본 AC 는 manual acceptance 항목이며 자동 Pester 테스트로 대체하지 않는다.

## AC-chatlog-12 — MVP scope 밖 자동화 항목이 명시적으로 out-of-scope

본 MVP 가 도입하지 않는 자동화 항목은 contract / 운영 가이드 / README / 본 AC 텍스트가 carrier 다. snippets 는 positive runtime 만 담으므로 본 AC 의 진술이 snippets 안에 있을 필요가 없다.

Carrier 문서 (이 AC 의 진술이 모두 들어 있어야 하는 자리):

- `docs/CHATLOG_CONTRACT.md` (특히 `## non-goals` 절)
- `docs/MVP_OPERATOR_GUIDE_KR.md` (특히 `## 7b` 의 자동화 경계 절)
- `README.md` (chatlog / Snippets / What this toolset does not do 절)
- `tests/chatlog-contract-manual.md` (본 AC 텍스트 자체)

Expected:

- hook, watcher, daemon, scheduler 가 MVP 에 도입되지 않는다는 진술이 위 carrier 문서들에 존재한다.
- session-start automation, on-stop hook, on-prompt-submit hook 이 MVP 에 도입되지 않는다는 진술이 carrier 문서들에 존재한다.
- 자동 user prompt capture, 자동 assistant 응답 capture, 자동 transcript capture, transcript JSONL parser, Claude JSONL parser 가 MVP 에 도입되지 않는다는 진술이 carrier 문서들에 존재한다.
- BF auto-inject 가 MVP 에 도입되지 않는다는 진술이 carrier 문서들에 존재한다.
- `BF_STATE.json` 같은 별도 state machine 이 MVP 에 도입되지 않는다는 진술이 carrier 문서들에 존재한다.
- `~/.claude/settings.json`, 글로벌 `CLAUDE.md`, 글로벌 `AGENTS.md` 의 mutation 이 MVP 에 도입되지 않는다는 진술이 carrier 문서들에 존재한다.
- CL (Chat Log) 영역의 fuller implementation (누적 history 자동화, schema, retention, browse UI) 이 MVP scope 밖이라는 진술이 carrier 문서들에 존재한다.
- RND-style `CHAT_LOG + REPORT + BRIEF` 통합 workflow 가 MVP scope 밖이라는 진술이 carrier 문서들에 존재한다.
- `snippets/CLAUDE_SNIPPET.md` 와 `snippets/AGENTS_SNIPPET.md` 는 본 AC 의 negative 진술을 담지 않는다 (positive runtime 만 담는다). 두 snippet 안에 위 항목 진술이 없다는 사실은 본 AC 의 fail 이 아니다.

## AC-chatlog-13 — README BF 진입점 / 자동화 부재 명시

`README.md` 가 BF 진입점과 자동화 부재를 짧게 명시해야 한다.

Expected:

- `log/chatlog/current/resume.md` 가 현재 BF 의 restore point 라는 진술이 존재한다.
- snippet 채택 시에만 자연어 BF save / restore-offer protocol 이 활성화된다는 진술이 존재한다.
- CL 의 full automation 이 post-MVP 라는 진술이 존재한다.
- 자동 global install / hook / auto-injection 이 제공되지 않는다는 진술이 존재한다.
