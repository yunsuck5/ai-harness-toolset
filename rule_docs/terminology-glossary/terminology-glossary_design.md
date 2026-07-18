# terminology-glossary Design — 최소 trigger 모델·reservation 제거와 `managed trigger` 채택

## Header

- 이 문서는 terminology-glossary 규칙 개정의 방향을 정한다.
- 완료 시 glossary는 채택·기각 의미, read-only lookup, 네 decision trigger만 소유한다.
- 실행 기록이나 terminal rule 문면이 아니며 mutation·commit·push 승인이 아니다.

## 왜 바꾸는가 / 무엇을 바꾸는가

현 glossary는 `pending` / `owner-pending` / `finalization-owner`와 reservation schema까지 소유한다. 후보-local 이름을 프로젝트 공용 상태로 너무 일찍 승격하고, 실제 의미 충돌보다 등록·전이 절차가 작업을 지배한다.

Glossary를 채택·기각 의미의 최소 single home으로 축소한다. 채택 의미의 read-only lookup은 항상 열어 두고, 의미·분류 mutation은 새 공용 용어·채택 의미/분류 변경·실제 충돌·기각 용어 부활 위험 네 trigger에만 건다. 더 이상 공용이 아닌 항목의 제거는 두 번째 trigger에 포함하며 새 상태를 만들지 않는다. 의미 보존형 교정은 proportionality에 따른 direct edit다.

이번 micro-increment는 cross-domain admission 경계에서 공통으로 쓰는 `managed trigger`를 한 줄 채택하고 exact owner path만 둔다. 구체 trigger·action·authority·closure 의미는 해당 owner가 계속 소유한다.

## Owner surface model

- `rules/terminology-glossary.md`: 채택·기각된 프로젝트 용어의 최소 의미와 semantic durable-pointer boundary
- `snippets/rules/no-background-or-hidden-state.md`: `managed trigger`의 보편 admission·accountability와 비소급 비인증 경계
- 각 domain/rule/candidate: 자기 상세 의미와 후보-local 이름
- root instruction pair와 `rules/README.md`: lookup·mutation trigger routing
- docs-working-model: 후보 lifecycle와 glossary 호출 경계
- checker/tests: `TERM-RESERVE` 제거는 이 revision이 소유하되 terminology 의미·상태·schema·glossary pointer를 판정하지 않음; tracked HEAD에 없던 `GLOSSARY-POINTER` 시범안은 도입하지 않음
- corrected-state review·Blind·canonical: 산문 안 semantic boundary 검사

## 수정 대상

- glossary의 status/reservation model과 `TERM-RESERVE`
- 12개 pending 항목의 채택·후보-local·제거 처분과 status term `finalization-owner` 제거
- root/index routing, 직접 소비 문서, docs-working-model 연동
- WIP에서 시범 작성됐지만 tracked HEAD에 들어오지 않은 `GLOSSARY-POINTER` hard diagnostic과 전용 tests의 미도입 처분
- 기존 accepted/rejected 항목의 한 줄 축약 표현
- `managed trigger`의 한 줄 의미와 exact owner path

권위 분류는 clause × scope × enforcement path 기준으로 다음과 같다.

- pending/owner-pending/finalization-owner 계약: **Binding rule**, scope = 후보 이름 등록·finalization, enforcement = DWM lifecycle + `TERM-RESERVE`; 정상 작업을 과도하게 결합하므로 제거
- `TERM-RESERVE`: bounded candidate line form을 hard-fail하는 deterministic diagnostic이지만 lifecycle **Hard gate는 아님**; 상태기계 제거와 함께 삭제
- concrete pointer 금지: **Binding rule**, scope = committed glossary의 durable pointer, enforcement = semantic review 계층
- `GLOSSARY-POINTER`: tiny bounded pending-entry predicate를 glossary 산문 전체에 일반화한 WIP 설계 오류다. Drive-root, Markdown/HTML decoration, `?`·`[]` glob, `$ProjectRoot`·`${RUN_ID}` placeholder, normalized-relative/nested directory, POSIX·UNC·비ASCII prefix의 7축 counterexample에서 결정 가능성이 무너졌다. Tracked HEAD에는 존재하지 않았으므로 “tracked diagnostic 제거”가 아니라 **시범안 폐기·미도입**으로 처분한다.

## 하지 않을 것 (non-goals)

- 새 registry, warning 상태, shadow lifecycle을 만들지 않는다.
- 다른 owner의 상세 의미를 glossary로 옮기지 않는다.
- pointer hard diagnostic이나 repo-wide scanner를 만들지 않는다.
- 기존 accepted/rejected 항목의 분류나 semantic core를 바꾸지 않는다.
- `managed trigger`를 registry·상태·schema로 확장하거나 foreign owner의 구체 semantics를 복제하지 않는다.

## Plan readiness / open risks

Plan으로 진행할 준비가 됐다.

- 제거 상태 어휘 잔여: four-class reference sweep과 corrected-state review에서 닫는다.
- 12개 처분 외 기존 항목 의미 보존: HEAD→current 항목 mapping과 canonical review에서 닫는다.
- prelive owner의 `consultation`·`operator synthesis`·`독립 의견`·`재조율`·`blind-advisory`를 현재 프로젝트 공용 의미로 채택하는 리스크를 사용자가 인지·수용했다. 이 분류는 owner implementation에 live authority를 부여하지 않으며, 실제 한 줄 의미·분류 변경이 생기면 정상 mutation trigger로 다시 연다.
- semantic pointer boundary 누락: Blind·canonical·독립 오탐 감사에서 닫는다.
- whole-prose hard diagnostic 미도입은 HEAD/current의 `scripts/**`·`tests/**` 부재, 대체 진단 미도입 sweep과 review input에서 검증한다.
- `managed trigger`의 공용성·최소성·exact owner path는 terminal glossary와 owner rule의 1:1 대조에서 닫는다.
