# Reviewer run-banner provenance correction Plan

## Header

이 Plan은 Design의 W-39 transport correction을 Review Spec·runner·기존 test에 동기화하고 실제 CLI 확인과 corrected-state review까지 가져가는 approval-target 기록이다. Work Packet은 필요하지 않으며 이 문서는 commit·push·배포 승인이 아니다.

## Batch 순서와 의존

1. Review Spec에 session pointer 관측이 기존 version·effort 관측을 보존한다는 target-state 의미를 동기화하고 marker를 `sync-required`로 둔다.
2. runner argv에서 `--json`을 제거하고, 두 번째 separator까지 확인된 공통 `stderr` banner envelope에서 version·effort를 읽으며 그 내부 block의 `session id:` line에서 session pointer를 읽는다. 닫는 separator 뒤의 echoed prompt는 세 field 모두의 관측 범위에서 제외하고 JSONL parser는 제거한다.
3. 기존 runner test stub을 실제 non-JSON banner·separator·prompt echo shape와 맞추고, `--json` 부재·세 run-fact 관측·세 field 미관측 정직성·version/effort/session prompt decoy 배제·canonical provenance 지속을 같은 기존 case들에서 검증한다. JSONL 전용 fixture와 noisy event sequence는 제거한다.
4. runner-equivalent 실제 CLI direct probe, affected/full Pester, PowerShell 형식, DWM 진단, diff·encoding 검사를 수행한 뒤 eligible stable pre-change engine으로 corrected-state dual review를 수행한다.
5. review 뒤 사용자가 content landing과 lifecycle closeout을 각각 결정한다. Closeout은 Design/Plan 삭제와 applicable Spec marker disposition만 포함하는 retirement-only transaction이어야 한다.

## Batch 정의

단일 content batch의 source 경로 집합은 다음 exact5다.

- `docs/review/review_design.md`
- `docs/review/review_plan.md`
- `docs/review/review_spec.md`
- `scripts/review-run.ps1`
- `tests/review-run.Tests.ps1`

목적은 기존 공개 `reviewer-session-id` 목표를 유지하면서 `reviewer-version`·`applied-effort`까지 하나의 실제 reviewer invocation에서 함께 관측되도록 runner transport를 복원하는 것이다. 기존 result verifier, provenance append-failure 의미, 2-file/write-once/verdict·hidden-identity 경계는 바꾸지 않는다.

Work Packet은 만들지 않는다. correction 원인과 target-state 의미가 Design·Plan·Spec·기존 test에 직접 흡수되고 별도 round-scoped current-bearing 재료가 없다.

## Open decision 의 close 지점

W-39의 “JSONL event를 사용해도 기존 run-fact 관측을 보존한다”는 전제는 실제 CLI 관측으로 기각한다. 일반 모드의 같은 banner field를 사용하는 것이 기존 version·effort reader와 같은 fragility class이며, 별도 invocation이나 session-log dependency를 추가하지 않는 최소 correction이다. 공개 session pointer는 계속 정보성 수동 trace-back metadata일 뿐 campaign identity·권한·verdict·자동 후속 trigger가 아니다.

## Stage rewind 조건

세 run-fact를 한 invocation에서 얻기 위해 별도 process, session-log, sidecar/schema/parser gate, skill의 resume 지위 계약, exact5 밖 source 수정이 필요하면 구현을 확대하지 않고 Design 또는 scope 결정으로 되돌린다. 실제 CLI probe가 runner-equivalent posture에서 세 banner field의 co-observation을 반증하거나 구현이 Spec boundary를 넘으면 해당 단계에서 정지한다.
