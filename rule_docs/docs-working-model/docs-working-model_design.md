# docs-working-model Design

> 이 문서는 docs-working-model 규칙의 유한 의미 조항 inventory와 검사 배선 정직화를 위한 Design이다.
> 이 체인이 끝나면 핵심 원자 규범은 보존되고, 과도한 전칭·형식 게이트와 종료된 이행 예외는 비례 조정된다.
> 이 문서는 최종 규칙 문면이나 mutation/commit/push 승인이 아니다.

## 왜 바꾸는가 / 무엇을 바꾸는가

현행 규칙은 문서 소유권·단일 홈·수명주기라는 필요한 원자 규범과, 특정 사고를 봉합하며 누적된 강한 파생 규범을 같은 강도로 담고 있다. 그 결과 후보·정규 개정·closeout에서 실제 의미 결함보다 형식·전칭 적용이 먼저 blocker가 될 수 있고, 수동 실행 전용 검사도 lifecycle에 배선된 hard gate처럼 읽힐 수 있다.

변경의 의미 목표는 규칙을 느슨하게 만드는 것이 아니라 권위 수준을 정직하게 만드는 것이다. 상호 무충돌 원자, 파생 충돌의 해소 기준, 정규 개정·흡수 경로는 유지한다. 그 기준으로 소급되지 않는 강한 파생은 범위를 좁히거나 안내로 강등하고, 끝난 이행 예외는 active rule에서 제거하며, 기계 검사는 실제 호출 배선과 같은 이름으로 부른다.

## Owner surface model

- `rules/docs-working-model/docs-working-model.md`는 문서 artifact의 역할·소유권·수명주기와 의미 판단 기준을 소유한다.
- `rules/docs-working-model/templates/`와 `checklists/`는 규칙의 산출물 형식을 보조하되 독립적인 승인 근거가 되지 않는다.
- `scripts/docs-working-model-check.ps1`와 `scripts/verify-ps1.ps1`는 각자 구현한 결정 가능 부분만 진단한다. lifecycle hard gate라는 지위는 실제 transition 배선이 있을 때만 성립한다.
- 사람 또는 reviewer는 의미 판단을 소유하되, 단순 의심·형식 누락·외부 도메인 언급 자체를 blocker로 승격하지 않고 조항에 명시된 근거·반증·회색 통로를 사용한다.

## 수정 대상

- 의미 owner: `rules/docs-working-model/docs-working-model.md`
- 직접 구현 owner 후보: 같은 rule package의 templates/checklists와 `scripts/docs-working-model-check.ps1` 및 관련 tests
- 정직화 대조 대상: `scripts/verify-ps1.ps1`의 Step F 문면과 실제 호출 배선

## 하지 않을 것 (non-goals)

- 새 schema·registry·scanner·hook·scheduler 또는 공통 gate를 만들지 않는다.
- 다른 도메인·다른 규칙의 의미를 이 규칙으로 흡수하지 않는다.
- 조건부 후속 HN-02/07/10/12를 이 변경에 포함하지 않는다.
- planning artifact 단계에서 terminal rule·checker를 수정하거나 처분 제안을 승인된 결론으로 취급하지 않는다.

## Plan readiness / open risks

유한 조항 inventory와 배선 실측을 Work Packet에 둘 준비가 됐다. 다음 위험은 Plan의 별도 지점에서 닫는다.

- 조항 누락 위험: inventory 검토에서 독립 재열거와 section coverage 대조로 닫는다.
- 과강등·과유지 위험: 조항별 근거·반증·회색 통로 감사와 사용자 재정으로 닫는다.
- 실제 구현 범위: inventory 처분 승인 뒤 별도 implementation batch에서 닫는다.
