# no-background-or-hidden-state Plan — 명시 권한과 책임 있는 실행

## Header

- 이 문서는 `no-background-or-hidden-state` 규칙 개정의 한 changeset 경계를 정한다.
- 완료 시 terminal rule·분산 route·`managed trigger` 용어가 같은 owner 경계를 표현한다.
- 작업 로그가 아니며 mutation·commit·push 승인이 아니다.

## Batch 순서와 의존

1. terminal rule을 보편 원자척추·향후 admission·비소급 비인증·owner-local closure로 재단하고 분산 index와 bootstrap route를 맞춘다.
2. 열린 terminology lifecycle에 `managed trigger` 한 줄과 exact owner path를 추가한다.
3. 두 batch를 한 changeset으로 검증하되 domain 구현이나 선재 메커니즘의 적합성 판단으로 확장하지 않는다.

## Batch 정의

| 목적 | Scope | Hard boundary | Validation expectation | Review focus | Work Packet |
|---|---|---|---|---|---|
| 분산 규칙 재단 | terminal rule, rules index, bootstrap 대칭 pair | 특정 메커니즘 승인, domain·skill·script 수정, 선재 메커니즘 전수 판정 금지 | 네 의미층, per-firing continuation/result-artifact 회계, persistent active 상태와 control-operation 종료의 구분, validity-independent core가 함께 성립 | 원자성, owner revision·re-approval 분리, false-block·소급 인증 부재 | 불필요 — 결정과 Design이 경계를 충분히 고정함 |
| 용어 micro-increment | glossary와 열린 terminology Design·Plan | owner semantics 복제, 새 registry·상태·검사기 도입 금지 | 한 줄 의미와 exact owner path가 terminal rule과 1:1 | 공용성, 최소성, owner pointer | 불필요 — 단일 용어 한 줄 추가 |

## Open decision 의 close 지점

- 메커니즘 이름이 아니라 권한·owner·가시성·종료 회계를 판정 기준으로 삼는 결정은 첫 batch의 terminal rule에서 닫는다.
- trigger·executor·behavior·scope·continuation·terminal 의미 변경은 owner revision으로, authority·scope 확장은 추가 re-approval로 보내는 결정도 첫 batch에서 닫는다.
- bounded mutating execution의 회계를 hidden sidecar가 아닌 owner result artifact에 두고, 실행 사실과 유효성을 분리하는 결정도 첫 batch에서 닫는다.
- 장기 active mechanism과 각 firing·enable/control operation의 terminal accounting을 분리하는 결정은 첫 batch에서 닫는다.
- 선재 메커니즘 비인증과 전수 재평가 비목표는 owner-boundary 문면에서 닫는다.
- `managed trigger` 채택과 exact owner path는 두 번째 batch에서 닫는다.

## Stage rewind 조건

- global rule이 특정 domain의 구체 lifecycle·상태·미결 위험을 흡수하면 Design으로 돌아간다.
- 새 registry·schema·parser·sidecar·자동 gate 또는 선재 메커니즘 전수 판정을 도입하면 Plan으로 돌아간다.
- owner-local 비도입 정책을 해제하거나 domain 파일 수정이 필요해지면 이 changeset을 중단하고 해당 owner lifecycle로 분리한다.
