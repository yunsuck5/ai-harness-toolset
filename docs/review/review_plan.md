# Review caller timeout and cancellation Plan

## Header

이 Plan은 Design의 결정을 W-38 lifecycle로 동기화하고 corrected-state review까지 가져가는 approval-target 기록이다. Work Packet은 필요하지 않으며 이 문서는 commit·push·배포 승인이 아니다.

## Scope와 경로 집합

W-38 source 경로 집합은 다음 exact5다.

- `docs/review/review_design.md`
- `docs/review/review_plan.md`
- `docs/review/review_spec.md`
- `snippets/claude-skills/ai-harness-review/SKILL.md`
- `tests/review-input-verify.Tests.ps1`

W-37A의 `README.md`와 `user_guide/review-system_ko.md`는 이 lifecycle 밖의 별도 direct-edit change set이다. 두 작업이 같은 working tree에 있으면 corrected-state review target에는 aggregate exact7로 공개한다.

## Batch order

1. Review Spec에 target-state 의미를 동기화하고 marker를 `sync-required`로 둔다.
2. Skill의 기존 timeout 두 문장을 사용자 exact 한 줄로 교체하고 기존 test case를 positive assertion 하나로 정합화한다.
3. 변경 `.ps1`의 UTF-8 BOM + CRLF를 복구하고, affected/full Pester·PowerShell 형식·DWM 진단·Skill 형식·diff/encoding 검사를 확인한다.
4. stable pre-change engine으로 aggregate corrected-state local-correctness/system-coherence review를 수행한다.
5. review 뒤 사용자가 content landing과 lifecycle closeout을 각각 결정한다. Closeout은 Design/Plan 삭제와 applicable Spec marker disposition만 포함하는 retirement-only transaction이어야 한다.

## Boundaries

사용자 exact 문면과 three-space separator를 바꾸지 않는다. runner timeout parameter, 새 rule·H2·gate·test case, install/global surface, `tests/install-update.Tests.ps1`, README 지정 2곳 밖을 변경하지 않는다. Source correction이 발생하면 기존 review를 stale로 처리한다.

## Validation과 review focus

검증은 exact 문면, Spec↔Skill meaning sync, positive-only 기존 assertion, EOL/BOM, W-37A 참조 제거를 확인한다. Review는 exact5 lifecycle 내부 정합과 aggregate exact7의 unintended delta·stale reference를 독립 관점으로 판단한다.

## Open decision과 stage rewind

Commit·closeout·push·deploy·global mutation은 사용자 결정으로 남는다. exact5 밖의 W-38 변경이나 Design 결정 변경이 필요하면 구현을 확대하지 않고 해당 단계로 되돌린다.
