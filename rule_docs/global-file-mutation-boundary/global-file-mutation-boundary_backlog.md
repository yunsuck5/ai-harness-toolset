# global-file-mutation-boundary — backlog (future-work queue)

next ID: GFM-B-05

이 파일은 아직 시작하지 않은 global-file-mutation-boundary 후속 작업의 non-authoritative queue다. 각 row는 별도 scoped Design→Plan과 review gate 없이 구현 승인을 부여하지 않는다.

## Open rows

| ID | Row (one line) | Reopen / start condition |
|---|---|---|
| GFM-B-02 | managed-block parser의 tilde opener 대칭 사례와 opener보다 긴 valid closer의 positive 회귀를 보강한다 | parser predicate 또는 그 소비자(primitive·apply·root parity)의 별도 scoped 작업이 착수될 때 |
| GFM-B-03 | 현행 PowerShell managed-marker 소비자의 공유 predicate 재사용 경계를 위한 code-local maintenance anchor 필요성을 심사한다 | 새 판정 소비자가 추가되거나 독립 parser 구현이 제안·발견될 때 |
| GFM-B-04 | apply 계층에서 직접 잠기지 않은 mixed×remove·shorter×replace end-to-end 회귀를 보강한다 | fence predicate 또는 apply replace/remove 경로의 별도 scoped 작업이 착수될 때 |
