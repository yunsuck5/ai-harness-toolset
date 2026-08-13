# install-update Plan — git-url exact target 결박

## Header

- 이 문서는 Q-09의 selector·selected-target 계약을 한 coherence batch로 구현·검증하는 경계를 정한다.
- 작업 로그나 Work Packet이 아니며 commit·push·실제 global install/update/activation 승인이 아니다.

## Batch 순서와 의존

1. install-update Spec을 `sync-required`로 전환하고 selector, preflight/apply 시간 경계, selected-SHA D3/archive, metadata 불변과 빈 branch 경로의 target meaning을 기록한다.
2. `INSTALL.md`와 installed-root README template을 verified bootstrap checkout과 같은 operator 계약으로 맞춘다.
3. core selected-tree D3, install/update clone remote alias, inspect 전체 진단과 SHA 결박, self-contained existing-install 안내를 구현한다.
4. 새 회귀 case만 먼저 실행한다. 여기에는 같은 public `install-update.ps1` 호출 안에서 preflight 뒤 advertised branch가 이동해도 exact `-Ref` SHA를 적용하는 결정적 통합 case와 `install-global.ps1`의 custom remote·non-default branch fresh-install 통합 case가 포함된다. PASS 뒤 affected suites(`install-update` / `install-pipeline` / `install-global` / `update-global`)를 실행한다. 이어 `verify-ps1`, DWM checker, diff/encoding 검사를 수행한다. full Pester는 landing gate의 변하지 않은 exact candidate에서 한 번만 수행한다.
5. stable pre-change engine으로 fresh local-correctness/system-coherence dual review를 수행한다. blocker가 없고 별도 사용자 gate가 열릴 때만 landing/closeout을 다룬다.

## Batch 정의

| 목적 | Scope | Hard boundary | Validation expectation | Review focus | Work Packet |
|---|---|---|---|---|---|
| Q-09 git-url target 결박 | `docs/install-update/install-update_design.md`, `docs/install-update/install-update_plan.md`, `docs/install-update/install-update_spec.md`, `INSTALL.md`, `templates/install-root/AI_HARNESS_TOOLSET_ROOT_README.md`, `scripts/install-update.ps1`, `scripts/lib/install-pipeline-core.ps1`, `scripts/install-global.ps1`, `tests/support/install-pipeline-fixture.ps1`, `tests/install-update.Tests.ps1`, `tests/install-pipeline.Tests.ps1`, `tests/install-global.Tests.ps1`, `tests/update-global.Tests.ps1` | status/schema/source-cut/approval 불변; arbitrary historical commit·persistent selector/cache 없음; local-clone checkout 없음; cleanup latent 미흡수; 실제 install/update/activation 없음 | 두 public entrypoint 직접 통합 case를 포함한 new targeted first → affected four suites → `verify-ps1` / DWM / diff / encoding → fresh dual; full Pester는 landing boundary까지 보류 | inspect-time advertised eligibility와 apply-time availability 분리, 같은 호출의 branch-move race에서 exact Ref 유지, selected-SHA D3/archive, exact checkout bootstrap, install-global custom remote·non-default branch, empty remote·branch, full inspect diagnostics, metadata 불변 | 불필요 — 한 lifecycle batch와 직접 fixture/tests에서 닫힌다 |

## Open decision close

- exact selector는 inspect/preflight 시 현재 advertised branch-tip인 40-hex commit만 받는다. apply는 같은 SHA의 clone availability/equality만 요구하고 tip 재광고는 요구하지 않는다.
- branch selector는 recorded branch를 호출자가 같은 값으로 명시하는 tracking 경로다. custom recorded remote는 clone alias와 branch resolve에 동일하게 쓰며 다른 branch/remote는 source-cut이다.
- exact `-Ref`와 `-Branch`는 상호 배타다. exact one-shot은 branch·remote를 빈 값까지 보존한다. recorded branch가 empty이면 remote default HEAD의 advertised tip을 exact `-Ref`로 고정하고 branch를 추정하거나 persist하지 않는다.
- D3 source validity와 archive는 checkout이 아니라 같은 selected SHA tree를 본다. bootstrap은 그 SHA를 detached checkout하고 equality를 확인한 뒤 contract/script를 소비한다.
- metadata-valid inspect는 모든 진단군을 실제 평가하며 payload > source > activation precedence를 유지한다. unresolved git-url target은 어느 status에서도 mutation으로 내려가지 않는다.

## Rewind / closeout

- unadvertised commit acquisition, metadata migration, 새 selector persistence, source-cut override, cleanup ownership 변경이 필요하면 Design으로 돌아가 별도 scope 재정을 요청한다.
- affected test가 실패하면 full suite로 확대하지 않고 해당 실패를 교정한 뒤 targeted/affected-first로 재검증한다.
- candidate 검토 후 수정이 생기면 기존 review는 stale이다. closeout은 Spec 1:1과 two-level docs disposition을 다시 확인한 뒤 별도 사용자 gate에서만 수행한다.
