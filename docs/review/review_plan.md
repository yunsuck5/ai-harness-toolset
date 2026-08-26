# Reviewer session trace pointer Plan

## Header

이 Plan은 Design의 공개 reviewer session trace pointer 결정을 Review Spec·runner·기존 test에 동기화하고 corrected-state review까지 가져가는 approval-target 기록이다. Work Packet은 필요하지 않으며 이 문서는 commit·push·배포 승인이 아니다.

## Batch 순서와 의존

1. Review Spec에 공개 pointer의 target-state 의미와 identity/authority 경계를 동기화하고 marker를 `sync-required`로 둔다.
2. runner가 기존 1회 Codex invocation의 JSONL event에서 session id를 읽어 H1 stdout과 provenance에 기록하도록 하고, 기존 runner test 안에서 argv·run-fact·persisted provenance를 함께 검증한다.
3. affected/full Pester, PowerShell 형식, DWM 진단, diff·encoding 검사를 수행한 뒤 stable pre-change engine으로 corrected-state dual review를 수행한다.
4. review 뒤 사용자가 content landing과 lifecycle closeout을 각각 결정한다. Closeout은 Design/Plan 삭제와 applicable Spec marker disposition만 포함하는 retirement-only transaction이어야 한다.

## Batch 정의

단일 content batch의 source 경로 집합은 다음 exact5다.

- `docs/review/review_design.md`
- `docs/review/review_plan.md`
- `docs/review/review_spec.md`
- `scripts/review-run.ps1`
- `tests/review-run.Tests.ps1`

목적은 기존 `result.md` provenance가 공개 `reviewer-session-id`를 담게 하는 것이다. runner는 `--json` event stream의 `thread.started.thread_id`를 같은 invocation에서 읽고, 관측 실패를 `not-observed`로 드러낸다. 기존 result verifier와 append-failure 의미는 바꾸지 않는다. 검증은 추가 invocation 없이 controlled stub으로 argv·session event 해석·H1/provenance 일치와 기존 final shape를 확인한다. Review focus는 공개 metadata가 hidden identity나 authority로 변질되지 않는지, 기존 2-file/write-once/verdict·parser 경계가 유지되는지다.

Work Packet은 만들지 않는다. 조사 결과가 작고 target-state 의미와 기존 test 안에 직접 흡수되며 별도 round-scoped current-bearing 재료가 없다.

## Open decision 의 close 지점

Design의 두 open risk는 이 Plan에서 닫는다. 공개·purpose-bound pointer는 hidden identity가 아니며 campaign identity·권한·verdict·자동 trigger로 소비하지 않는다. session event 미관측은 `not-observed` run-fact로 공개하되 새 hard gate를 만들지 않는다. 실제 reviewer invocation은 구현 전 사실 확인에 사용하지 않고 공식 CLI 계약·로컬 help·controlled test를 근거로 한다. Corrected-state review는 변경을 포함하지 않는 already-proven stable pre-change engine의 canonical dual로 수행하며, candidate engine의 첫 실사용은 이 review가 아니다.

## Stage rewind 조건

session id를 얻기 위해 별도 invocation, session-log 탐색, sidecar/schema/parser gate, skill의 resume 지위 계약, exact5 밖 source 수정이 필요하면 구현을 확대하지 않고 Design 또는 scope 결정으로 되돌린다. Spec이 이 Plan의 공개 pointer·권한 부재 경계를 바꾸거나 구현이 Spec boundary를 넘으면 해당 단계에서 정지한다.
