# global-file-mutation-boundary Design — root parity checker 정합

## Header

- 이 문서는 `global-file-mutation-boundary`가 소유하는 marker 의미와 repo-local root parity checker의 정합 방향을 정한다.
- 완료 시 shared body의 실제 byte parity와 실제 managed-marker 부재만 검사한다.
- terminal rule이나 실행 기록이 아니며 mutation·commit·push 승인이 아니다.

## 왜 바꾸는가 / 무엇을 바꾸는가

앞선 revision은 managed-block adoption과 authored source 유지보수를 분리했지만 parity checker는 permissive UTF-8 decode 뒤 문자열 동등성을 byte identity로 설명하고, 실제 marker가 아닌 `AI_HARNESS_TOOLSET_GLOBAL` token 언급까지 금지한다. 이는 root의 byte-identical shared-body 계약과 managed-block owner의 whole-line·fence-aware marker 계약보다 넓거나 약한 판정이다.

Checker는 shared-body marker부터 EOF까지의 원시 바이트를 직접 비교한다. Managed-block 부재는 별도 token blacklist가 아니라 배포 primitive와 같은 whole-line·fence-aware marker 판정으로 확인한다. Root pair의 authored content와 distributed rule의 adoption 계약은 바꾸지 않는다.

## Owner surface model

- distributed rule와 managed-block primitive: 실제 marker 의미와 adoption 경계
- root `CLAUDE.md`·`AGENTS.md`: authored shared-body byte parity와 public-safe 계약
- repo-local parity checker: 두 계약의 좁은 교집합만 판정

## 수정 대상

- `tests/repo-local-instruction-parity.Tests.ps1`
- `rule_docs/global-file-mutation-boundary/`의 현재 lifecycle 문서와 `GFM-B-01`

권위 평가 단위는 다음과 같다.

- shared body byte parity: **Binding rule**, scope = 이 repo의 root pair, enforcement = 원시 byte 비교
- actual managed marker 부재: **Binding rule**, scope = 이 repo의 root pair, enforcement = 배포 primitive와 같은 marker predicate
- harmless token 언급 금지와 decoded-string equality: owner 계약으로 소급되지 않는 checker overreach이므로 제거

## 하지 않을 것 (non-goals)

- distributed rule·managed-block primitive·root instruction 본문을 바꾸지 않는다.
- marker admission이나 root mutation 권한을 새로 만들지 않는다.
- 범용 instruction checker나 새 registry를 만들지 않는다.

## Plan readiness / open risks

Plan으로 진행할 준비가 됐다.

- byte slice 경계가 decoded character index로 환산될 위험은 ASCII shared-body marker의 raw byte 위치 탐색으로 닫는다.
- marker parser 중복 drift는 기존 managed-block primitive를 직접 소비하고 harmless prose·inline·fenced mention과 실제 whole-line marker의 양방향 회귀로 닫는다.
