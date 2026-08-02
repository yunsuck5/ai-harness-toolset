# rule-authority Design — 규범 저작 전 최소 대조

## Header

- 이 문서는 `rule-authority`의 규범 저작 admission을 개정하는 방향을 정한다.
- 완료 시 규범적 rule 신규 저작·의미 개정의 저작자는 저작 전에 현재 작업에서 식별된 정책급 전제·영향받는 foreign owner·이미 알려진 반례를 최소 한 번 대조한다.
- 실행 기록이나 terminal rule 문면이 아니며 mutation·commit·push 승인이 아니다.

## 왜 바꾸는가 / 무엇을 바꾸는가

현행 rule은 완성된 claim의 권위와 처분을 평가하지만, 저작을 시작하기 전에 이미 식별된 상위 전제·owner 경계·반례를 대조하는 시점을 두지 않는다. `RA-B-01`이 지적한 이 공백을 별도 의례나 영구 구조 없이 현재 작업 안의 최소 admission으로 닫는다.

Admission은 규범적 rule을 새로 쓰거나 기존 의미를 개정할 때만 적용한다. 오탈자·stale pointer·그 밖의 meaning-preserving correction은 proportionality에 따라 직접 처리할 수 있다.

## Owner surface model

- `rules/rule-authority.md`: admission의 actor·시점·범위와 권위 분류·처분 의미를 소유한다.
- 각 개별 rule owner: 자기 규범 의미와 정상 Design → Plan lifecycle을 계속 소유한다.
- `rule_docs/rule-authority/rule-authority_backlog.md`: 아직 시작하지 않은 future work만 소유하며, 흡수된 `RA-B-01`은 삭제한다.

## 수정 대상

- `rules/rule-authority.md`: 규범 저작 전 최소 대조 문면 추가
- `rule_docs/rule-authority/rule-authority_backlog.md`: `RA-B-01` 소비, `next ID: RA-B-03` 유지

## 하지 않을 것 (non-goals)

- admission을 hard gate, 영구 checklist·rubric·registry·scanner, 필수 corpus 또는 작업 간 필수 load로 만들지 않는다.
- 모든 경미한 edit나 meaning-preserving correction에 별도 의례를 요구하지 않는다.
- foreign owner의 구체 의미나 절차를 이 rule로 옮기지 않는다.
- 이 admission이 자신의 introducing changeset을 소급 govern했다고 주장하지 않는다.

## Plan readiness / open risks

Plan으로 진행할 준비가 됐다. actor·적용 시점·범위의 reconstructibility는 terminal rule 문면과 corrected-state review에서 닫고, 과도한 절차화 여부는 기존 최소화 문면과 함께 대조한다. 새 admission은 이 changeset 이후의 rule work부터 적용한다.
