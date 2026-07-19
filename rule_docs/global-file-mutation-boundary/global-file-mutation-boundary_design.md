# global-file-mutation-boundary Design — managed-marker fence 판정 정합

## Header

- 이 문서는 `global-file-mutation-boundary`가 소유하는 marker 의미와 공유 parser·apply·root parity 소비자의 정합 방향을 정한다.
- 완료 시 fenced code의 delimiter 종류와 opener 길이를 보존해 실제 managed marker만 판정한다.
- terminal rule이나 실행 기록이 아니며 mutation·commit·push 승인이 아니다.

## 왜 바꾸는가 / 무엇을 바꾸는가

앞선 revision은 root parity checker를 shared-body raw-byte identity와 공유 managed-marker predicate에 맞췄다. 그러나 공유 parser는 fenced code의 delimiter 종류와 opener 길이를 기억하지 않고 backtick 또는 tilde run마다 fence 상태를 뒤집는다. opposite delimiter나 shorter closer 뒤의 marker-looking line을 fence 밖으로 오인하고, 뒤따르는 실제 marker를 fence 안으로 숨길 수 있다.

공유 parser는 opener의 delimiter 종류와 길이를 보존하고, 같은 종류이면서 opener 이상 길이인 run만 closer로 인정한다. primitive와 apply의 replace/remove, root parity checker는 이 한 predicate를 함께 소비한다. Root pair의 authored content와 distributed rule의 adoption 계약은 바꾸지 않는다.

## Owner surface model

- distributed rule: 실제 marker 의미와 adoption 경계
- managed-block primitive: whole-line·fence-aware marker 판정의 실행 single home
- root `CLAUDE.md`·`AGENTS.md`: authored shared-body byte parity와 public-safe 계약
- apply entrypoint와 repo-local parity checker: 공유 predicate의 replace/remove 및 root 부재 판정 소비자

## 수정 대상

- `scripts/lib/managed-block.ps1`
- `tests/managed-block.Tests.ps1`
- `tests/apply-managed-block.Tests.ps1`
- `tests/repo-local-instruction-parity.Tests.ps1`
- `rule_docs/global-file-mutation-boundary/`의 현재 lifecycle 문서

권위 평가 단위는 다음과 같다.

- shared body byte parity: **Binding rule**, scope = 이 repo의 root pair, enforcement = 원시 byte 비교
- actual managed marker 판정: **Binding rule**, scope = managed-block 대상과 이 repo의 root pair, enforcement = 공유 parser의 whole-line·fence-aware predicate
- mixed delimiter와 shorter closer를 독립 fence transition으로 보는 기존 boolean toggle: owner 계약을 충족하지 못하는 parser defect이므로 교정

## 하지 않을 것 (non-goals)

- distributed rule·root instruction 본문을 바꾸지 않는다.
- marker admission이나 root mutation 권한을 새로 만들지 않는다.
- 범용 instruction checker나 새 registry를 만들지 않는다.

## Plan readiness / open risks

Plan으로 진행할 준비가 됐다.

- parser 교정은 delimiter 종류와 opener 길이만 보존하며 별도 Markdown parser로 확장하지 않는다.
- primitive·apply replace/remove·parity 세 계층에서 mixed-delimiter와 shorter-closer의 양방향 반례로 marker span 오선택과 실제 marker 은닉을 함께 닫는다.
