# Resume Brief

다음 CLI agent 또는 다음 사람이 작업을 재개할 때 가장 먼저 읽는 짧은 brief.

이 파일은 `summary.md`와 함께 chatlog session 디렉터리(`log/chatlog/current/` 또는 `log/chatlog/<session-id>/`) 아래에 둔다. 자세한 규약은 `docs/CHATLOG_CONTRACT.md`를 참고한다.

`resume.md`는 chatlog의 **첫 진입점**이다. 다음 사람이 가장 먼저 열어 상황을 파악하는 자리이며, AI agent가 새 session을 시작하거나 context를 잃은 뒤 복원할 때에도 이 파일을 첫 번째로 읽는다. read 순서는 `resume.md` → `summary.md` → `decisions.md` → `raw-transcript.md` 순이다.

이 파일은 **AI-authored brief 자리**다. 사용자 원문을 길게 옮기지 않는다. 인용이 꼭 필요하면 짧은 verbatim excerpt와 reference link만 두고, 원문 전문은 `raw-transcript.md` 또는 별도 `User original input` 파일을 가리킨다. 사용자 원문을 resume 안에서 summarize, compress, rephrase, translate, interpret 하지 않는다.

아래 heading은 canonical이다. 임의의 새 top-level heading을 만들지 않는다. ad-hoc 정보는 canonical heading 아래 bullet 또는 subsection으로 흡수한다 (mapping 표는 `docs/CHATLOG_CONTRACT.md`의 `canonical heading 정책과 ad-hoc heading mapping` 절을 참고).

`> optional` 표시가 붙은 section은 필요할 때만 채운다. 표시가 없는 section은 required다. 내용이 없는 required section은 `none`으로 채워 둔다.

## Current state

> 지금 repo / project가 어떤 상태인지 한두 문장으로. branch, HEAD commit, working tree 상태 등을 사실 위주로 기록한다. 'Current repo state', 'Current stop-lines' 같은 ad-hoc heading은 여기 bullet으로 흡수한다.

## Last completed action

> 직전에 무엇을 끝냈는지. PR/commit 단위가 아니라 의미 있는 작업 단위. 'Completed' 같은 ad-hoc heading은 여기 bullet으로 흡수한다.

## Current scope

> 지금 묶음의 범위. 한 줄 요약 + 필요 시 bullet 몇 개.

## Next single action

> 다음에 정확히 한 가지로 해야 할 행동. 여러 개를 적지 않는다. 다음 action이 정해지지 않았다면 그렇게 명시한다.

## Do not do

> 이 시점에서 명시적으로 하지 말 것. 예: 아직 commit 금지, 자동화 script 작성 금지, 특정 파일 수정 금지 등. 'Do not do yet', 'Deferred' 같은 ad-hoc heading은 여기 bullet으로 흡수한다.

## Files to inspect first

> 다음 agent가 가장 먼저 읽어야 할 파일 목록. 경로 위주로 짧게. 'Context needed' 같은 ad-hoc heading은 여기 또는 `Relevant artifacts` bullet으로 흡수한다.

## Open risks

> 알고 있는 위험, 가정, unknown. 사실/추정 구분을 명시한다.

## Pending user decision

> 사용자 판단 대기 중인 항목. 없으면 `none`.

## Relevant artifacts

> optional. 관련 산출물 위치. 예: 관련 doc, 관련 evidence case, 관련 review packet, 관련 template.

## Carry-over

> optional. 이번 session에서 끝내지 못해 다음 session으로 넘어가는 항목. 없으면 생략.

## Notes

> optional. 위 canonical heading에 들어가지 않는 운영 메모. 다음 agent에게 의미 있는 사실만 남긴다.
