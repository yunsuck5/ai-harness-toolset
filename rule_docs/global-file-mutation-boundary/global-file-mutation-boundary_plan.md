# global-file-mutation-boundary Plan — managed adoption과 authored source 유지보수 분리

## Header

- 이 문서는 global-file mutation 경계 개정의 한 changeset을 정한다.
- 완료 시 terminal rule, 두 global snippet, distributed index, root pair가 같은 경로 분리를 표현한다.
- 작업 메모가 아니며 mutation·commit·push 승인이 아니다.

## Batch 순서와 의존

1. 배포 tier의 terminal rule을 영어로 유지하면서 managed payload 작업과 authored source 영역 유지보수의 scope를 분리한다.
2. 두 global snippet과 distributed index를 같은 경계로 맞춘다.
3. 명시 승인된 root instruction pair의 terminology trigger corrective를 mirror-edit로 포함한다.
4. 전체 reference sweep·parity·review를 수행한다.

규칙이 정상 경로를 먼저 정의해야 root pair corrective를 예외가 아닌 유지보수로 검토할 수 있다. 다만 landing은 하나의 atomic changeset이며, 세 번째 단계의 권한은 두 root 파일의 해당 row에만 적용된다.

## Batch 정의

| 목적 | Scope | Hard boundary | Validation expectation | Review focus | Work Packet |
|---|---|---|---|---|---|
| mutation 경로 분리 | distributed rule, 두 snippet, index, root pair corrective | adoption marker·stop·approval 불변, 임의 project-root 전체수정 금지, parity-checker 정비 제외, 언어 재작성으로 의미를 바꾸지 않음 | 작업·영역 판별, repo-specific confidentiality/publication 경계, 영어 terminal wording, 요약, trigger, 현재 repo mirror parity가 1:1 | 같은 파일의 영역 오분류, 승인 확장, source/adopter 의미 혼합, 번역 drift | 불필요 — 결정과 경계가 이 Plan에 충분함 |

## Open decision 의 close 지점

- authored source 판별은 managed block 밖의 repo-authored 영역 + tracked source + 사용자의 source-product 지위 명시 + 대상 root instruction surface 밖의 tracked active product surface가 주는 corroborating 근거 + 명시 repo-local maintenance contract를 요구하고, repo 내부 문면만으로 추론하거나 불명확하면 stop하는 문면으로 닫는다.
- managed adoption은 기존 marker·fail-fast·기계 enforcement를 그대로 유지하는 대조로 닫는다.
- universal authored-source 경로는 paired/parity를 강제하지 않고 각 repo-local 계약에 맡긴다. 이 repo의 root pair 전환은 exact corrective 범위, public-safe 확인, byte-identical shared body, canonical review로 닫는다.
- terminal rule은 repo 내부 한국어 Design/Plan의 조건을 빠짐없이 보존한 영어 문면이고, 두 영어 bootstrap 요약·영어 distributed index와 의미 정합한지 대조해 닫는다.
- parity checker 정비는 이 batch가 닫지 않으며 `GFM-B-01`의 별도 revision으로 남긴다.

## Stage rewind 조건

- Plan이 adoption 보호를 약화하면 Design으로 돌아간다.
- terminal rule이 tracked authored source의 판별 기준을 넓히거나 자동 mutation을 허용하면 Plan으로 돌아간다.
- 영어 재작성에서 한국어 WIP의 조건이 누락·완화·확장되면 Design 결정부터 다시 대조한다.
- 구현이 `GFM-B-01`이나 unrelated global-file behavior까지 확장되면 중단하고 별도 lifecycle로 분리한다.
