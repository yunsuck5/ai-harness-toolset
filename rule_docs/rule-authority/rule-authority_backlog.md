# rule-authority — backlog (future-work queue)

next ID: RA-B-02

`rule-authority` 규칙의 non-authoritative future-work queue다. 각 row는 별도 scoped Design → Plan과 review gate 없이 구현 승인을 부여하지 않는다.

## Open rows

| ID | Row (one line) | Reopen / start condition |
|---|---|---|
| RA-B-01 | 규칙 저작·개정 착수 전에 정책급 전제, cross-owner 참조, 이미 알려진 반례를 대조하는 최소 절차를 이 rule에 흡수할지 심사 | 규칙 전반 정비 batch가 시작되거나, 이미 알려진 owner 충돌·참조가 canonical review에서 처음 발견되는 사례가 다시 관측될 때 |
