# review Plan — byte-faithful reviewer 입력과 usable-result 경계

## Header

- 이 문서는 review transport와 result-integrity를 한 lifecycle에서 구현·검증·closeout하는 Plan이다.
- 완료 시 corrected source/tests/skill과 live Spec이 일치하고 관련 backlog가 회계되며, 임시 Design/Plan은 git history에 보존된 뒤 삭제된다.
- 실행 로그나 Work Packet이 아니며 mutation·commit·push·global activation 승인이 아니다.

## Batch 순서와 의존

1. 기존 `Invoke-NativeProcess -StandardInputBytes`를 실제 Codex PowerShell shim 모양에 연결한 synthetic probe로 raw-byte 보존을 먼저 확인한다.
2. live review Spec을 `sync-required`로 전환하고 runner가 caller-owned strict UTF-8 payload bytes를 text pipeline 없이 전달하도록 I01을 구현한다. 현행 native distribution과 어긋난 review skill adoption 문면도 함께 정합화한다.
3. I01의 정상 transport를 전제로, usable judgment일 때만 세 verdict 중 하나를 소비하고 invocation/result-unavailable에는 verdict가 없다는 I02 계약을 Spec·skill·runner·templates/tests에 정합화한다.
4. affected/full 검증과 stable pre-change engine 기반 fresh canonical dual 및 독립 오탐 감사를 수행한다. blocker가 없을 때만 Spec을 `live`로 닫고 Design/Plan을 삭제한다.

I02가 I01 transport 결과에 의존하고 두 item이 하나의 review owner·Spec·검증 체인을 공유하므로 implementation/closeout은 한 coherence unit으로 유지한다. Planning provenance만 별도 anchor commit으로 먼저 보존한다.

## Batch 정의

| 목적 | Scope | Hard boundary | Validation expectation | Review focus | Work Packet |
|---|---|---|---|---|---|
| B05 review transport/result 정합 | review Spec/backlog, skill, runner, 기존 native byte-stdin helper의 소비 지점, input/result templates, affected tests와 operator guide | caller-owned UTF-8 bytes만 전달; PS7·범용 framework 금지; three-verdict/two-file/result rendering 유지; semantic parser lint·fourth verdict 금지; global/activation·B06/B07 무접촉 | pre/post raw-byte probe, review affected Pester, native-process affected test, `verify-ps1`, full Pester, DWM checker, diff/encoding, stable-engine canonical dual, 독립 오탐 감사 | non-ASCII와 말미 byte fidelity, shim invocation의 stdout/stderr/exit 보존, unavailable→verdict 0, usable judgment→verdict 1, failure-only operator 보고, backlog/배포 문면 정합 | 불필요 — 두 좁은 owner 결정을 current source·tests와 runtime probe로 닫을 수 있음 |

## Open decision 의 close 지점

- runner는 reviewer preamble + delimiter + canonical input을 strict UTF-8 no-BOM bytes로 한 번 조립하고 기존 structured byte-stdin helper로 전달한다. PowerShell script shim은 text pipeline으로 재전송하지 않는 child-process 모양으로 호출하며, synthetic probe가 expected payload와 byte-exact임을 보여야 구현을 계속한다.
- byte-stdin capture site를 실제로 사용하므로 `PFE-B-02`를 이번 batch에서 분류한다. review runner는 structured three-field contract로 이동하고, 그 밖의 weaker capture site 전수 migration은 수행하지 않는다.
- 세 verdict는 usable reviewer judgment에만 적용한다. runner invocation 실패, result 부재, verdict parse 실패, post-run canonical verification 실패나 operator가 발견한 verdict/disclosure 의미 모순은 source verdict로 소비하지 않고 `review result unavailable`로 보고한다. 이 표현은 verdict가 아니다.
- evidence 부족이 명시적 blocker/risk라는 판단은 기존 `no`/`yes with risk` 경계에 남긴다. 판단 자체가 불가능하면 reviewer에게 verdict 제조를 요구하지 않는다.
- `RV-B-18`, `RV-B-19`, `RV-B-05`는 target-state 구현과 검증 뒤 소비한다. result rendering을 바꾸지 않으므로 `RV-B-03`은 유지한다. next-ID floor는 재사용하지 않는다.
- `scripts/review-verify.ps1`의 shape-only gate와 canonical result heading 구조는 유지한다. checked-no-change surface도 closeout 보고에 명시한다.

## Stage rewind 조건

- actual shim raw-byte probe가 기존 helper 소비만으로 payload를 보존하지 못하거나 새 transport framework/adapter contract가 필요하면 Design으로 돌아간다.
- 구현이 verdict 어휘, result H2/layout, parser semantic gate, retry/fallback 경계를 바꾸면 Plan을 중단하고 Design으로 돌아간다.
- result rendering 변경이 필요해 `RV-B-03` trigger가 성립하면 범위를 재승인받기 전 중단한다.
- stable-engine canonical review에서 `no` 또는 blocker가 나오면 closeout commit과 push를 하지 않고 corrected working tree를 보존해 상신한다.
