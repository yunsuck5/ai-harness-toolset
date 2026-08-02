# install-update Plan — 네이티브 스킬 배포 정합과 wrapper 상태 보존

## Header

- 이 문서는 B02의 세 항목을 한 install-update lifecycle에서 구현·검증·closeout하는 경계를 정한다.
- 완료 시 corrected source/tests/prose와 live Spec이 일치하고 `IU-B-04`가 소비되며, 임시 Design/Plan은 git history에 보존된 뒤 삭제된다.
- 작업 로그나 Work Packet이 아니며 mutation·commit·push·global activation 승인이 아니다.

## Batch 순서와 의존

1. live Spec을 `sync-required`로 전환하고 host 지원 문면을 Windows PowerShell 5.1 검증 기준으로 정정한다.
2. shared activation resolver를 Claude/Codex 두 destination으로 fan-out하고 install/update/activate/uninstall의 affected prose와 tests를 함께 맞춘다.
3. update wrapper가 delegate의 `activation_pending`과 JSON stream 경계를 보존하도록 최소 교정하고 `IU-B-04`를 소비한다.
4. affected/full 검증, deterministic preview/smoke, fresh canonical dual, 독립 오탐 감사를 수행한다. blocker가 없을 때만 Spec을 `live`로 닫고 Design/Plan을 삭제한다.

세 항목은 하나의 install-update Spec과 검증 체인을 공유하므로 closeout changeset은 통합한다. Planning provenance는 별도 anchor commit으로 먼저 보존한다.

## Batch 정의

| 목적 | Scope | Hard boundary | Validation expectation | Review focus | Work Packet |
|---|---|---|---|---|---|
| B02 install-update 정합 | `INSTALL.md`, root `README.md`, install-update Spec/backlog, installed-root README template, shared resolver, update wrapper, affected lifecycle tests | 단일 payload 유지; 기존 Claude ID 보존; Codex ID 최소 추가; uninstall finalizer/result/output 및 `IU-B-14`~`IU-B-17` 무접촉; wrapper exit/recovery/native helper 무변경; global/activation 무실행 | affected Pester, `verify-ps1`, full Pester, DWM checker, diff/encoding, deterministic activation preview와 wrapper smoke | 두 vendor fan-out의 전 consumer 전파, owned-target 삭제 경계, `activation_pending` 보존, JSON stdout 순수성, 과장 없는 host claim | 불필요 — 현재 source와 tests에서 결정 가능한 세 개의 좁은 교정임 |

## Open decision 의 close 지점

- host 지원 표현은 실제 baseline인 Windows PowerShell 5.1 검증·지원으로 한정한다. PowerShell 7의 지원 또는 비지원은 주장하지 않는다.
- source skill 하나는 두 vendor destination으로 전개한다. Claude ID는 `skill-mirror:<name>`, Codex ID는 `skill-mirror:codex:<name>`이며 두 표면 모두 `Scope Skill`이다.
- uninstall은 resolver가 증명한 owned target만 상속하고 두 vendor의 preview·remove·verify·sibling-preservation만 이번 batch에서 잠근다.
- wrapper는 구조화 delegate status를 해석해 `activation_pending`을 `INCOMPLETE`로 나타내고, 그 밖의 nonzero와 parsing failure는 `FAIL`로 닫는다. JSON mode의 wrapper 자체 메시지는 stderr로 보낸다.
- 실제 global deployment와 fresh vendor discovery는 source landing 후 별도 사용자 gate로 남긴다.

## Stage rewind 조건

- 별도 vendor payload·registry·sidecar 또는 새 shared helper가 필요해지면 Design으로 돌아간다.
- uninstall finalizer/result/output이나 `IU-B-14`~`IU-B-17`의 의미를 바꿔야 하면 해당 owner batch로 분리하고 중단한다.
- wrapper exit-code/recovery 계약이나 `Scope Skill` 의미를 바꿔야 하면 Design으로 돌아간다.
- fresh review에서 `no` 또는 blocker가 나오면 closeout commit과 push를 하지 않고 corrected working tree를 보존해 상신한다.
