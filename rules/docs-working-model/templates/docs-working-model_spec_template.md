# {{DOMAIN}} Spec

> 사용법: 이 형틀은 Spec의 여덟 의미 영역을 여덟 heading으로 제시하는 권장 기본 구조다. heading 수는 명시 호출 시 form diagnostic이며 독립 lifecycle blocker가 아니다. 목표 상태·owner·durable boundary와 정확히 하나의 lifecycle marker는 의미 invariant다. 회차 분석은 Work Packet, 실행 기록은 `log/**` 소관이다. 이 Spec은 mutation/commit/push 승인이 아니다(1회 진술).

## Header

{{이 문서는 무엇인가 — 3줄 이내}}
{{이 체인이 끝나면 무엇이 되는가 — 3줄 이내}}
{{이 문서가 아닌 것 — 3줄 이내}}

## 목표 상태

{{이 도메인이 무엇인가/무엇이어야 하는가 — 구현에서 확인 가능한 durable behavior와 owner 의미로. 문장·코드의 literal 대응은 요구하지 않는다}}

## Owner surface 지도

{{어떤 active surface(scripts/skill/templates/config/tests/rules)가 어떤 행동을 소유하는가. behavior 의 authority 는 active surface 다(Spec 은 명세하고 대조될 뿐)}}

## Durable boundary

{{항구적 허용/금지 경계 — 이번 회차가 끝나도 참인 것만. rules·spec 은 class/invariant 를 소유하고 구체 경로 값은 active surface·INSTALL.md 가 소유한다}}

## Cross-domain interface

{{이 도메인이 노출/의존하는 인터페이스만. 다른 도메인의 semantics 재진술 금지("target 구현이 바뀌면 이 참조도 바뀌나?" — yes 면 semantics)}}

## Validation expectation

{{이 도메인의 지속 검증 수단(suite 목록·조건 — 예: 해당 Pester suites, verify-ps1 조건). 회차 실행 시퀀스가 아니라 무엇이 성립해야 하는가. 근거 기록처는 closeout report / log/evidence}}

## Review focus

{{이 도메인 변경 시 항상 검토할 것(지속 관점). 회차용 reviewer 질문 목록 금지(→ Work Packet)}}

## Lifecycle state

{{compact 상태 절. lifecycle marker를 **정확히 하나** 담는다 — `**prelive**` | `**sync-required**` | `**live**`. plain-prose 언급은 marker가 아니다. checker의 EN-2는 이 marker의 물리 subset만 진단한다.}}
