# Project Brief

`<ProjectRoot>/log/brief/BRIEF.md` 의 시작 template 이다. 이 파일은 그 project 를 지금 운영하는 operator 의 **operator-local durable restore state** 다 (BF Level 3). 현재 operator 또는 새 AI agent session 이 작업을 (재)개할 때 가장 먼저 읽는 local restore entrypoint 이며, shared project source-of-truth 나 human handoff 문서가 아니다.

이 template 은 source repo (`ai-harness-toolset`) 의 `templates/brief/BRIEF.md` 이며, source tree 의 tracked source artifact 다. 실제 BRIEF artifact 는 그 project 의 `<ProjectRoot>/log/brief/BRIEF.md` 에 둔다 — 이는 `log/` 아래 operator-local runtime state 이며 `.gitignore` 의 `log/` 규칙에 의해 기본적으로 ignored 된다. 두 자리는 다르며, root `<ProjectRoot>/brief/` 는 ai-harness 용도로 만들지 않는다 (`docs/BRIEF_CONTRACT.md` 의 source-vs-target 경계 절 참조).

`scripts/brief-init.ps1` 가 이 template 을 그 project 의 `<ProjectRoot>/log/brief/BRIEF.md` 로 한 번 seed 한다. 이후 갱신은 사람이 손으로 한다. tooling 은 본문을 자동으로 채우거나 보정하지 않는다.

채택 직후, 사용자는 아래 각 required section 에 들어 있는 한 줄짜리 replace-me sentinel 문장을 자기 project 의 사실로 교체한다. sentinel 의 정확한 문구는 각 required section 본문 안에 한 번씩만 등장한다. 본 preamble 에서는 sentinel 문구 자체를 인용하지 않는다 (`scripts/brief-check.ps1` 가 sentinel 문자열을 forbidden string 으로 거부하기 때문에, preamble 에서 인용하면 채워진 BRIEF 도 영구 FAIL 이 된다). sentinel 이 한 곳이라도 남아 있으면 `scripts/brief-check.ps1` 는 FAIL 한다.

`> 안내` 형태의 한 줄 guidance 는 작성 보조 메모다. 사용자는 작성 후에도 guidance 를 남겨 둘 수 있고, project 에 더 적합한 형태로 바꾸어도 된다. 단, replace-me sentinel 문장은 반드시 제거해야 한다.

`> optional` 표시가 붙은 section 은 필요할 때만 채운다. 표시가 없는 section 은 required 다. 내용이 없는 required section 은 `none` 으로 채워 둔다.

heading set 은 `templates/session-resume.md` 와 동일하지만 의미 해석은 durable-project 지향이다 (`docs/BRIEF_CONTRACT.md` 의 interpretation table 참조). 임의의 새 top-level heading 은 만들지 않는다.

## Current state

> project 의 durable 상태. branch, 최근 milestone, 현재 phase 등을 사실 위주로 기록한다. session-단위 변동 사항은 `log/chatlog/current/resume.md` 에 두고 여기로 옮기지 않는다.

(Replace this section with project-specific content.)

## Last completed action

> 가장 최근의 durable milestone. PR 단위가 아니라 phase 종결 / 핵심 결정 채택 / release 같은 의미 있는 단위.

(Replace this section with project-specific content.)

## Current scope

> 지금 phase 또는 workstream 의 범위. 한 줄 요약 + 필요 시 bullet 몇 개.

(Replace this section with project-specific content.)

## Next single action

> 다음 durable 단계의 단일 action. 여러 개를 적지 않는다. 정해지지 않았다면 그렇게 명시한다.

(Replace this section with project-specific content.)

## Do not do

> project 차원에서 명시적으로 금지된 항목 (scope guardrail). 예: 특정 subsystem 자동화 금지, 특정 폴더 생성 금지, 특정 tooling 도입 금지.

(Replace this section with project-specific content.)

## Files to inspect first

> 현재 operator / 새 AI agent session 이 가장 먼저 읽을 path. 경로 위주로 짧게.

(Replace this section with project-specific content.)

## Open risks

> project 차원의 알려진 위험, 가정, unknown. 사실 / 추정을 구분해 적는다.

(Replace this section with project-specific content.)

## Pending user decision

> project 방향에 영향을 주는 미결 결정. 없으면 `none`.

(Replace this section with project-specific content.)

## Relevant artifacts

> optional. project 의 durable artifact 위치. 예: 핵심 contract 문서, 핵심 template, 누적 review record root, 대표 evidence case root. path 만 적고 본문은 옮기지 않는다.

## Carry-over

> optional. phase 또는 workstream 사이에서 다음 phase 로 이월되는 항목. session-단위 carry-over 가 아니다. 없으면 생략.

## Notes

> optional. project 차원의 운영 메모. canonical heading 에 들어가지 않는 durable 사실만 남긴다. session-단위 잡담은 `log/chatlog/current/` 에 두고 여기로 옮기지 않는다.
