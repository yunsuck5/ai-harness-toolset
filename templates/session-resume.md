# Resume Brief

다음 CLI agent 또는 다음 사람이 작업을 재개할 때 가장 먼저 읽는 짧은 brief.

이 파일은 `summary.md`와 함께 chatlog session 디렉터리(`log/chatlog/current/` 또는 `log/chatlog/<session-id>/`) 아래에 둔다. 자세한 규약은 `docs/CHATLOG_CONTRACT.md`를 참고한다.

## Current state

> 지금 repo / project가 어떤 상태인지 한두 문장으로. branch, HEAD commit, working tree 상태 등을 사실 위주로 기록한다.

## Last completed action

> 직전에 무엇을 끝냈는지. PR/commit 단위가 아니라 의미 있는 작업 단위.

## Current scope

> 지금 묶음의 범위. 한 줄 요약 + 필요 시 bullet 몇 개.

## Next single action

> 다음에 정확히 한 가지로 해야 할 행동. 여러 개를 적지 않는다. 다음 action이 정해지지 않았다면 그렇게 명시한다.

## Do not do

> 이 시점에서 명시적으로 하지 말 것. 예: 아직 commit 금지, 자동화 script 작성 금지, 특정 파일 수정 금지 등.

## Files to inspect first

> 다음 agent가 가장 먼저 읽어야 할 파일 목록. 경로 위주로 짧게.

## Relevant artifacts

> 관련 산출물 위치. 예: 관련 doc, 관련 evidence case, 관련 review packet, 관련 template.

## Open risks

> 알고 있는 위험, 가정, unknown. 사실/추정 구분을 명시한다.

## Pending user decision

> 사용자 판단 대기 중인 항목. 없으면 `none`.
