# Session Summary

session 한 묶음의 결론, 결정, 변경 범위를 사람이 읽는 형태로 남긴다. 자세한 규약은 `docs/CHATLOG_CONTRACT.md`를 참고한다.

이 파일은 **AI-authored summary 자리**다. 사용자 원문(verbatim)을 이 파일에 옮겨 적지 않는다. 사용자 원문이 필요하면 `raw-transcript.md` 또는 별도 `User original input` section / 파일에 둔다. 사용자 원문을 summary 안에서 summarize, compress, rephrase, translate, interpret 하지 않는다 (자세한 규약은 `docs/CHATLOG_CONTRACT.md`의 `사용자 원문과 AI 작성물의 분리` 절 참고).

아래 heading은 canonical이다. 임의의 새 top-level heading을 만들지 않는다. ad-hoc 정보는 canonical heading 아래 bullet 또는 subsection으로 흡수한다 (mapping 표는 `docs/CHATLOG_CONTRACT.md`의 `canonical heading 정책과 ad-hoc heading mapping` 절을 참고).

`> optional` 표시가 붙은 section은 필요할 때만 채운다. 표시가 없는 section은 required다. 내용이 없는 required section은 `none`으로 채워 둔다.

## Context

> 이번 session이 다룬 작업의 배경과 scope.

## Decisions

> 이번 session에서 내려진 결정. dogfood/실험 결과로 확정된 stop-line, 채택/보류된 안 등을 포함한다. 'Completed', 'Current stop-lines' 같은 ad-hoc heading은 여기 bullet으로 흡수한다.

## Evidence

> 결정과 진행을 뒷받침하는 사실. commit hash, runtime dogfood 결과, evidence path (`log/evidence/<scope>/<case>/`) 등. 'Runtime dogfood' 같은 ad-hoc heading은 여기 bullet으로 흡수한다.

## Next action

> session이 끝나는 시점에서 다음 단계. 한두 줄.

## Carry-over

> 이번 session에서 끝내지 못해 다음 session으로 넘기는 항목. 없으면 `none`. 'Deferred' 같은 ad-hoc heading은 여기 bullet으로 흡수한다.

## Files inspected

> optional. 이번 session에서 실제로 read한 파일 경로. 없으면 생략.

## Session phase

> optional. phase 단위로 쪼갠 session인 경우에만 채운다. 단일 phase면 생략하거나 `single phase`로 표기.

## Pending prompt

> optional. session 종료 시점에 다음 agent에게 전달할 prompt 또는 질문이 있다면 그대로 적는다. 없으면 생략.

## Artifact links

> optional. 관련 산출물 경로. 예: `docs/...`, `templates/...`, `log/evidence/<scope>/<case>/`, `log/review/<run-id>/`. handoff.md는 repo 밖이므로 여기 적지 않아도 된다.

## Notes

> optional. 위 canonical heading에 들어가지 않는 운영 메모. 다음 agent에게 의미 있는 사실만 남긴다.
