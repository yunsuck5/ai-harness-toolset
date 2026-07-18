# no-background-or-hidden-state Design — 명시 권한과 책임 있는 실행

## Header

- 이 문서는 분산 규칙 `no-background-or-hidden-state` 개정의 방향을 정한다.
- 완료 시 규칙은 메커니즘 이름의 전칭 금지 대신 권한·소유·가시성·종료 회계의 공통 판정 기준을 제공한다.
- 실행 기록이나 terminal rule 문면이 아니며 mutation·commit·push 승인이 아니다.

## 왜 바꾸는가 / 무엇을 바꾸는가

현행 규칙은 hook·sidecar·background 같은 형태 자체를 전역에서 금지해, 실제 보호 대상인 무소유·비공개 실행과 정당한 owner-local 운용을 함께 막는다. 그 결과 이미 존재하는 메커니즘의 구체 수명주기 문제까지 상위 규칙이 흡수하고, 정상적인 신규 도입·개정 경로도 닫힌다.

개정 규칙은 네 의미층으로 재단한다.

1. 보편 원자척추: 명시 권한, 사전 식별된 owner·scope·continuation 권한과 상한, 가시성, 실행 사실과 유효성의 분리, 정직한 종료 회계
2. 향후 admission: 새 `managed trigger`는 별도 채택 권한과 inspect·disable·remove·cleanup·terminal 계약을 갖춘 뒤 owner lifecycle에서 판단
3. 비소급 비인증: 선재 메커니즘을 이 개정으로 승인하거나 위험 해소로 간주하지 않음
4. owner-local closure: 구체 실행·상태·보존·정리 방식과 더 엄격한 비도입 정책은 각 active owner가 소유

## Owner surface model

- `snippets/rules/no-background-or-hidden-state.md`: 모든 flow가 공유하는 admission·accountability 원자와 파생 충돌의 판정 기준
- 각 skill·script·domain·repo-local rule: 실제 메커니즘 채택 여부, 구체 lifecycle, 결과 형식, 보존·정리와 더 엄격한 정책
- `rules/terminology-glossary.md`: `managed trigger`의 한 줄 공용 의미와 exact owner pointer만 소유
- `snippets/rules/README.md`와 bootstrap snippet pair: 분산 규칙의 discoverability와 read-before-action route

## 수정 대상

- `snippets/rules/no-background-or-hidden-state.md`의 explicit-prompt-only, 형태 전칭 금지, sidecar·identity 전칭 금지
- 분산 규칙 index와 bootstrap 대칭 pair의 낡은 trigger 설명
- 열린 terminology lifecycle과 glossary의 `managed trigger` 한 줄

## 하지 않을 것 (non-goals)

- 특정 hook·daemon·scheduler·background 작업이나 선재 메커니즘을 승인·인증하지 않는다.
- IU·Brief·Review·Consultation 등 owner-local 계약을 수정하거나 더 엄격한 비도입 정책을 해제하지 않는다.
- 관리형 장기 실행의 구체 mechanics나 고정 수명을 전역 규칙이 정하지 않는다.
- 선재 메커니즘 전수 재평가 프로그램, registry, status schema, parser, sidecar 또는 자동 gate를 만들지 않는다.
- owner의 구체 lifecycle이나 미결 위험을 분산 규칙으로 옮기지 않는다.

## Plan readiness / open risks

Plan으로 진행할 준비가 됐다.

- 원자 의미 누락은 terminal rule과 결정 기록의 1:1 대조에서 닫는다.
- cross-owner 침범은 변경 path inventory와 독립 구조 감사에서 닫는다.
- `managed trigger`의 공용 의미와 exact owner path는 terminology micro-increment에서 닫는다.
- 선재 메커니즘의 구체 적합성은 이번 규칙 개정의 판정 대상이 아니며 각 owner의 후속 lifecycle에 남긴다.
