# review engine eligibility·target wording 정정 Plan

## 목표

Design에서 고른 엔진 적격성, Mode A target, task-id, input gate, B2 설명, canary 경계를 하나의 coherence batch로 active skill·Spec에 동기화한다.

## 변경 단위

1. Spec을 target state와 `sync-required` lifecycle로 전환한다.
2. 배포 `SKILL.md`의 기존 위치에서 의미를 compact하게 정정한다. 새 section이나 runtime layer는 만들지 않는다.
3. Design/Plan은 working-tree candidate에 존치하고 Work Packet은 만들지 않는다.
4. F7·동시 실행 수단·corrective-loop count는 이번 구현에서 제외한다. off-repo agenda에는 non-authoritative observation record만 남기고, backlog 채택 또는 명시적 비채택·폐기를 closeout 전 사용자 결정 지점으로 둔다.

## 검증

- affected Pester: `tests/review-input-verify.Tests.ps1`
- PowerShell encoding/lint: `.ps1` mutation이 없으므로 `scripts/verify-ps1.ps1`은 N/A
- DWM lifecycle 진단, UTF-8/LF 직접 검사, `git diff --check`, exact-scope/status 검사
- current installed payload head의 canonical 3-way cross-binding(`payload-manifest.json.head == payload-marker.json.head == install.json.lastUpdatedHead`, history `installedHead` 제외)을 직접 읽어 기록하되 이를 eligibility로 과장하지 않음; 선택 component별 pre-change baseline·reviewed state의 normalized payload 대조로 모든 대상 변경이 배제됨을 확인하고 비동일성만으로 적격을 선언하지 않음
- 변경 전 stable engine의 독립성 확인 뒤 local-correctness + system-coherence 두 focused review unit

docs/wording 변경이므로 full suite는 기본 범위가 아니다. 기존 source-skill contract를 읽는 affected Pester를 실행하고, 미실행 범위와 잔여 위험을 review input과 보고에 명시한다.

## Rewind 조건

다음 중 하나가 필요하면 진행을 멈추고 Design/Plan을 다시 조정한다.

- payload identity 외의 새 엔진 자격 메타데이터나 자동 판정 도구가 필요함
- workflow가 pre-change checkout을 생성·수정해야 함
- parser, verdict, artifact topology, B2/B3 substance가 바뀜
- 이번 batch에서 제외한 세 관측을 구현 scope에 포함해야 함
- 사용자 승인 없는 stage/commit/push/global/stable mutation이 필요함

## Closeout

후속 사용자 착륙 게이트가 열리고 corrected candidate가 승인되더라도, 제외 관측 3건의 사용자 disposition이 먼저 필요하다: future work로 채택하면 별도 승인 scope에서 `review_backlog.md`에 reopen/start condition과 함께 흡수하고, 아니면 명시적으로 비채택·폐기한다. disposition 전에는 stop/request하고 Spec을 `live`로 복귀하거나 Design/Plan을 retire하지 않는다. 그 뒤 closeout state에서만 temporary Design/Plan을 retire하며, 해당 artifact 변경의 review freshness를 별도로 처리한다.
