# {{DOMAIN}} Spec

> 사용법: 이 형틀을 복제해 `<domain>_spec.md` 로 채운다. 모든 `{{...}}` 를 치환한다. Spec 은 **목표 상태 명세**다 — 작성 완료 시 = 구현할 목표 상태의 청사진, closeout 후 = 구현물과 1:1 동기화된 live 명세. **담으면 안 되는 것**: 회차 candidate-file 목록 · 실행 명령 시퀀스 · staging 절차 · review result · readiness 판정 · 시점성 작업 상태(→ Work Packet / operator report 소관). Spec 이 Plan 을 위반하면 stop → re-plan(rewind); 구현이 boundary 를 초과하면 stop → ask user. 승인 경계는 Header 에서 1회만 진술한다(절마다 반복 금지).

## Header

{{이 문서는 무엇인가 — 3줄 이내}}
{{이 체인이 끝나면 무엇이 되는가 — 3줄 이내}}
{{이 문서가 아닌 것 — 3줄 이내. 이 Spec 은 mutation/commit/push 승인이 아니라는 1회 진술 포함}}

## 목표 상태

{{이 도메인이 무엇인가/무엇이어야 하는가 — normative 문장으로. 각 문장은 구현에서 확인 가능해야 하며(1:1 의 단위), 이 절+Owner surface 지도만으로 동일 행동의 구현을 재작성할 수 있는 수준(reconstructibility)이어야 한다}}

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

{{compact 상태 절: design/plan 존재 여부 · spec↔implementation sync 상태(live / sync-required) · capability/maturity 한 줄}}
