# install-update Design — 네이티브 스킬 배포 정합과 wrapper 상태 보존

## Header

- 이 문서는 install-update 도메인의 host 지원 문면, Claude/Codex 네이티브 스킬 배포, update wrapper 상태 전달을 함께 정합화하는 방향을 정한다.
- 완료 시 지원 주장은 검증된 Windows PowerShell 5.1 기준에 결박되고, 하나의 source skill inventory가 두 vendor activation home으로 전개되며, wrapper는 delegate의 `activation_pending`을 실패로 뭉개지 않는다.
- 실행 기록이나 terminal Spec이 아니며 mutation·commit·push·global activation 승인이 아니다.

## 왜 바꾸는가 / 무엇을 바꾸는가

현재 문서에는 실증되지 않은 `PowerShell 7+` 지원 주장이 있고, shared activation resolver는 source skill마다 Claude destination만 만든다. 또한 `update-global.ps1`은 delegate의 nonzero 결과를 모두 `FAIL`로 접어 `activation_pending`이라는 미완료 상태를 잃고, JSON mode에서도 wrapper prose가 stdout을 오염시킨다.

세 문제를 각 owner에서 최소 교정한다. host 문면은 Windows PowerShell 5.1 검증 기준만 주장한다. source inventory와 payload는 하나로 유지하되 resolver가 각 skill을 Claude와 Codex destination으로 fan-out한다. wrapper는 delegate의 구조화 상태를 읽어 `activation_pending`을 `INCOMPLETE`로 보존하고 JSON stdout에는 machine result만 남긴다.

## Owner surface model

- `INSTALL.md`와 root `README.md`: 설치 전제와 operator-facing 지원·배포 계약을 소유한다.
- `docs/install-update/install-update_spec.md`: 구현과 1:1 동기화된 install-update 목표 상태를 소유한다.
- `scripts/lib/activation-surface.ps1`: 한 source skill에서 vendor별 destination과 stable surface ID를 만드는 single home이다.
- install/update/activate/uninstall consumer: resolver 결과를 소비하되 별도 inventory·registry를 만들지 않는다.
- `scripts/update-global.ps1`: delegate 상태와 stream을 wrapper 표현으로 손실 없이 전달한다.
- 해당 Pester suites: 두 vendor fan-out, owned uninstall target, wrapper status/stream 경계를 잠근다.

## 수정 대상

- host/lifecycle prose: `INSTALL.md`, root `README.md`, install-update Spec, installed-root README template
- activation: shared resolver와 그 영향을 받는 install/update/activate/uninstall tests 및 필요한 consumer prose
- wrapper: `scripts/update-global.ps1`, wrapper tests, `INSTALL.md`
- backlog: 구현으로 흡수되는 `IU-B-04`만 제거

## 하지 않을 것 (non-goals)

- vendor별 source payload, registry, sidecar, junction/symlink를 추가하지 않는다.
- 기존 Claude ID `skill-mirror:<name>`나 `Scope Skill` 의미를 바꾸지 않는다. Codex ID는 `skill-mirror:codex:<name>`으로 추가한다.
- uninstall finalizer/result/output을 재설계하거나 `IU-B-14`~`IU-B-17`을 소비하지 않는다. B02의 uninstall 범위는 owned Codex skill target의 preview·remove·verify·sibling-preservation뿐이다.
- wrapper의 exit-code 체계, reinstall-first 복구 자세, native process helper를 바꾸지 않는다.
- review skill의 adoption 문면은 수정하지 않고 B05에서 처리한다.
- global install, managed-block activation, fresh vendor runtime discovery를 이번 source changeset의 완료로 주장하지 않는다.

## Plan readiness / open risks

owner와 최소 경계가 정해져 Plan으로 진행할 수 있다. resolver fan-out이 모든 consumer에 전파되는지와 wrapper의 human/JSON stream 분리는 affected tests와 deterministic preview/smoke로 닫는다. 실제 vendor discovery는 source landing 뒤 별도 사용자 gate에서만 검증하며, 그 전에는 source-side 정합으로만 보고한다.
