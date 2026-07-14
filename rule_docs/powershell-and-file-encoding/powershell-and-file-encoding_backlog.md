# powershell-and-file-encoding — backlog (future-work queue)

next ID: PFE-B-05

`powershell-and-file-encoding` 규칙의 non-authoritative future-work queue다. 각 row는 별도 scoped Design → Plan과 review gate 없이 구현 승인을 부여하지 않는다. 상세 incident/evidence 원장은 이 파일에 복제하지 않는다.

## Open rows

| ID | Row (one line) | Reopen / start condition |
|---|---|---|
| PFE-B-01 | repo-wide `.ps1` UTF-8 BOM+CRLF MUST와 `verify-ps1.ps1`의 `scripts/**`-only BOM 검사·CRLF warning-only 동작을 같은 범위와 강도로 정합화 | 규칙 전반 정비 batch 착수 또는 `tests/**` 인코딩 false-pass가 관측될 때 |
| PFE-B-02 | simple stdout-only·partial-stream·admitted raw-merged capture의 실제 위험과 structured three-field contract 적용 경계를 전수 분류하고 유지·migration을 결정 | 규칙 전반 정비 batch 착수, 해당 capture site 변경, 또는 새 native-capture realization 추가 시 |
| PFE-B-03 | Step F의 physical-line lexical matcher에서 fixture false-block·same-line false-exemption·dynamic/multiline 미검출을 측정하고 guardrail 유지·축소·대체를 결정 | Step F false block/exemption이 재현되거나 matcher 범위 변경이 필요할 때 |
| PFE-B-04 | helper-local byte-stdin observable contract와 terminal rule의 descriptive realization 요약 사이 finalization owner·single-home 경계를 확정 | `Invoke-NativeProcess`에 다음 public parameter/realization이 추가되거나 두 표면이 drift할 때 |
