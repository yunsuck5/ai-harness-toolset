# 규칙: 규칙 권위와 개정 (repo-only)

repo 규칙을 저작·개정하거나 상위 규칙이 정당한 작업과 충돌할 가능성이 있을 때만 이 규칙을 읽는다. 이 파일은 권위 분류와 처분을 소유하며, 각 개별 규칙은 계속해서 자체 의미를 소유한다.

## 자격

권위는 파일 전체나 label이 아니라 **clause × scope × enforcement path** 단위로 평가한다. 실제 차단 효과가 자격 입증 부담을 결정한다.

상위 invariant가 자격을 가지려면 명시적 scope를 가진 원자적이고 상호 충돌하지 않는 보호 primitive, 파생 규칙 간 충돌을 해소하는 판정 기준, 그리고 추가·개정·축소·강등·이관·제거 후 작업을 재개하는 정상적인 열린 채널을 모두 갖춰야 한다. 해당 primitive로 소급되지 않는 강한 파생 규칙은 자동 삭제 대상이 아니라 강등 후보다.

## 권위 등급

- **Hard gate** — 결정 가능한 predicate가 명시된 lifecycle transition에 실제로 연결되어 있고, claim과 실패 단위가 한정되며, 사용할 수 있는 repair 또는 resume 경로와 claim에 비례하는 coverage·차단 비용을 갖춘다.
- **Binding rule** — 사람이나 AI가 준수해야 하는 규범이다. 보호 성질, scope, owner 또는 actor, evidence와 counterevidence, 그리고 효과에 비례하는 모호성 해소·개정·이의·재개 경로를 명시한다.
- **Advisory** — 선택적인 비차단 지침이다. correctness evidence가 아니며, 읽지 않았다는 사실은 결함이 아니다. 필수 registry·scanner·load·의례를 만들지 않으며 stale하면 정리할 수 있다.

결정 가능한 diagnostic은 실행할 때 hard-fail할 수 있지만, 그것만으로 lifecycle hard gate가 되지는 않는다. PASS는 해당 diagnostic이 선언한 predicate만 입증한다.

## 충돌과 처분

상위 규칙이 과잉 적용될 가능성이 있으면 영향받는 mutation을 중단하고 작업을 보존한다. 정확한 clause, scope, enforcement path를 특정한 뒤 downstream workaround를 추가하기 전에 해당 상위 규칙을 감사한다.

사용자 결정 후 claim을 유지하거나 축소·강등·quarantine·제거·이관한다. claim을 변경하거나 제거하는 처분은 active owner와 enforcement를 함께 바꾼다. Quarantine은 권위 등급이 아니라 처분 상태다. 승인된 source 변경 후에만 발효되며, active owner에는 대상·scope·fallback·종료 조건만 기록한다.

전칭 또는 절대 claim을 유지하기 전에 최소 한 개의 정당한 대안 realization이나 counterexample로 시험한다. 견디지 못하면 축소하거나 강등한다.

상세 평가 rubric은 일회성 입력이었다. 이 파일은 영구적으로 남길 최소 문면이며, 이를 위해 영구 rubric·registry·scanner·checklist 또는 작업 간 필수 load를 만들지 않는다.
