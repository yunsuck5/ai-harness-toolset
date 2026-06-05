# Project Brief

이 파일은 이 project 의 **canonical Brief** — 이 project 의 local runtime restore summary — 다. 현재 operator 또는 새 AI agent session 이 **명시적으로 복원을 요청할 때** 읽는 local restore entrypoint 이며 (무요청 session-start 자동 읽기는 없다), shared project source-of-truth 나 human handoff 문서가 아니다.

canonical 자리는 `<ProjectRoot>/log/brief/BRIEF.md` 다. project 의 checkout 안 `<ProjectRoot>/log/` 트리 아래 runtime artifact 이며, project 의 `.gitignore` 의 `log/` 규칙에 의해 기본적으로 ignored 된다 — commit / push / merge / release 대상이 아니다. **root `<ProjectRoot>/brief/` 는 canonical 자리가 아니며 만들지 않는다.** user-home 의 operator-local runtime root 도 canonical 자리가 아니다.

본문 채움 / 갱신은 operator 의 trigger 위에 agent 또는 deterministic tooling 이 수행한다. operator 는 trigger / approve / reject / discard 주체이며 BRIEF 본문을 손편집하지 않는다. seed 직후 각 required section 본문의 한 줄짜리 replace-me sentinel 을 그 project 의 사실로 교체한다 — sentinel 이 한 곳이라도 남아 있으면 Brief 검증은 FAIL 한다. 본 preamble 에서는 sentinel 문구 자체를 인용하지 않는다 (인용하면 채워진 BRIEF 도 영구 FAIL 이 된다).

`> 안내` 형태의 한 줄 guidance 는 작성 보조 메모다. 작성 후에도 남겨 두거나 project 에 더 적합한 형태로 바꾸어도 된다. 단, replace-me sentinel 문장은 반드시 제거해야 한다.

`> optional` 표시가 붙은 section 은 필요할 때만 채운다. 표시가 없는 section 은 required 다. 내용이 없는 required section 은 `none` 으로 채워 둔다.

Brief 는 compact 하게 유지한다. review / evidence / chatlog 같은 큰 artifact 는 본문에 inline 하지 않고 경로로만 참조한다.

heading set 은 아래 구조를 그대로 유지한다. 임의의 새 top-level heading 은 만들지 않는다.

## Current state

> project 의 durable 상태. branch, 최근 milestone, 현재 phase 등을 사실 위주로 기록한다. session-단위 변동 사항은 본 Brief 가 아니라 chatlog 영역 (`<ProjectRoot>/log/chatlog/`) 에 둔다.

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

> 복원 시 가장 먼저 확인할 path. 경로 위주로 짧게.

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

> optional. project 차원의 운영 메모. canonical heading 에 들어가지 않는 durable 사실만 남긴다. session-단위 잡담은 본 Brief 가 아니라 chatlog 영역 (`<ProjectRoot>/log/chatlog/`) 에 둔다.
