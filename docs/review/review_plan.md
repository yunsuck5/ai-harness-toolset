# Review input 작성 요구사항 enforcement class Plan

> 이 문서는 W-44/F14의 임시 Plan이다. still-relevant 의미는 최종 corrected-state review 전에 기존 owner에 흡수하고, closeout에서는 이 문서를 삭제한다. 이 문서는 구현·commit·push 승인이 아니다.

## Header

이 Plan은 재승인 대상인 수정된 Design을 source target state, validation, canonical review로 내리는 batch와 경계를 정한다.
완료 후보는 기존 표면의 의미를 보존하면서 class 구분을 재구성하고, 검증과 fresh dual 결과를 읽은 상태에서 commit 직전에 멈춘다.
사용자의 planning 승인과 이후 commit 승인은 서로 별도이며, 이 Plan 자체는 어느 것도 승인하지 않는다.

## Batch 순서와 의존

1. **Planning gate** — 사용자가 이 Design/Plan의 class allocation, actual verifier 탐색·계산 범위, owner, exact scope와 same-wave 권고안을 승인하기 전에는 content-bearing source를 더 수정하지 않는다.
2. **Batch 1: target-state sync** — Spec과 skill을 하나의 atomic candidate로 수정한다. class wording과 길이·duty 보존은 서로 의존하므로 분리하지 않는다.
3. **Batch 2: validation과 canonical review** — Batch 1 전체를 한 번에 검증하고, 통과한 동일 candidate에 canary-first fresh dual을 수행한다. review 뒤 candidate가 바뀌면 기존 결과를 stale로 처리하고 이 batch를 다시 수행한다.
4. **Commit gate** — 결과와 잔여 risk를 보고하고 commit 전에 멈춘다. 명시적 승인 없이는 commit·push·global mutation을 하지 않는다.

## Batch 정의

### Batch 1 — target-state sync

목적은 네 class를 atomic duty 기준으로 재구성하고, 특히 machine-required overlay를 actual verifier의 packet-global placeholder 탐색과 required-H2-delimited body 범위보다 넓히거나 좁히지 않으면서 현재 의미를 잃지 않는 것이다.

Source-managed scope는 이 Design/Plan을 포함한 다음 exact four다.

- `docs/review/review_design.md`
- `docs/review/review_plan.md`
- `docs/review/review_spec.md`
- `snippets/claude-skills/ai-harness-review/SKILL.md`

`review_spec.md`는 marker를 `live`에서 `sync-required`로 바꾸고 active owner와 target state만 얇게 기록한다. Skill §3은 Design에서 승인한 class allocation의 단일 home으로 고친다. Compact machine-required 문구는 required H2 각각의 exactly-once, packet-global active-placeholder 부재, required-H2-delimited 계산 범위의 non-final trim 후 non-whitespace·Final 대소문자 비구분 phrase substring·exact-case legacy-phrase substring 검사를 구분하고, direct semantic body·Final exact-case/whole-body·packet-global legacy-phrase 부재를 기계 보장으로 주장하지 않는다. Baseline은 skill §3 raw UTF-8 3,233 bytes, template 전체 4,180 bytes, 합계 7,413 bytes, skill §3 bullets 5, template H2 11, active placeholders 10이다. template을 그대로 두고 합산 raw UTF-8 bytes를 7,413 이하로 유지하며, pre/post atomic-duty matrix에서 기존 작성 의무가 빠지거나 새 의무가 생기지 않아야 한다.

Hard boundary는 `templates/review-input.md`, `scripts/review-input-verify.ps1`, `tests/review-input-verify.Tests.ps1` 및 나머지 source의 byte 불변이다. 새 checklist/H2/placeholder/parser field/verifier heading/test hard gate, class-map 중복, B5 의미 변경은 허용하지 않는다. verifier 변경이 필요해 보이면 실행하지 않고 stop/report한다.

별도 Work Packet은 만들지 않는다. taxonomy와 N/A 경계 자체가 Design의 decision-grade 내용이고, 구현에 필요한 owner와 exact scope가 이 Plan에서 닫혀 있어 별도 조사 inventory가 필요하지 않다.

### Batch 2 — validation과 canonical review

한 번에 다음을 확인한다.

- DWM checker, `git diff --check`, source exact-four 및 hard-boundary diff 확인
- raw UTF-8 byte 수, bullet/H2/placeholder 수, pre/post atomic-duty matrix
- affected Pester인 `tests/review-input-verify.Tests.ps1`, 전체 Pester, `scripts/verify-ps1.ps1`
- Design/Skill machine-required wording과 verifier의 packet-global placeholder 탐색, required-H2 exactly-once, required-H2-delimited non-final trim/non-whitespace·Final case-insensitive substring·exact-case legacy-phrase substring 범위, 첫 required H2 이전 제외 경계의 직접 일치
- 기존 verifier contract, template test literal, B5 `Known concerns`/input+result/same-wave 의미 보존

그 뒤 설치된 pre-change `b6f516446a24ff5c1245c6022d05eb77ba634e0a` review engine과 Codex CLI 0.153.0을 사용한다. 먼저 local-correctness의 `contract-sensitive` unit 하나를 fresh canary로 실행하고, terminal-accounted 결과를 읽은 뒤에만 system-coherence의 `system-coherence-heavy` remainder unit을 fresh로 실행한다. 각 packet은 새 `Known concerns` 의미를 사용하고 caller conclusion·previous verdict를 evidence로 넣지 않는다. 각 unit의 authored input과 full result를 함께 읽어 evidence/risk/verdict를 재구성한다.

이번 first-use observation은 version, effort, session/posture, `Known concerns`, input+result intake, canary terminal accounting을 기록한다. 권고안 승인 시 canary를 wave 밖에서 소비하고 cardinality 1 remainder도 terminal accounting 뒤에만 의미상 소비한다. Same-wave contract와 applicability는 정적으로 확인하되 multi-member rule과 interleaving의 runtime exercise는 `not exercised`로 공개한다. 사용자가 실제 multi-member exercise를 요구하면 제3 unit을 추가하기 전에 Plan scope로 돌아간다.

Unit이 차단되거나 예측 밖 `no`를 내면 canonical artifact와 provenance를 보존하고 해당 reviewer session에 원인을 evidence-bound로 질의한다. 그 회신은 verdict가 아니라 관측으로 분리하고, changed input/evidence/disposition이라는 closure basis와 사용자의 scoped 승인이 있을 때만 corrected retry를 수행한다. 같은 차단이 새 evidence 없이 반복되면 verdict를 완화하지 않고 정지·보고한다.

결과가 새 source 수정으로 이어지면 review는 stale이며 같은 candidate 검증부터 되풀이한다. 새 evidence 없는 verdict 완화나 반복이 생기면 진행하지 않고 보고한다.

### Closeout boundary

Corrected-state review 뒤에도 Design/Plan과 `sync-required` Spec은 commit 전 candidate에 남는다. 사용자의 별도 commit 승인 이후에만 content commit을 만들 수 있다. DWM closeout은 다시 exact retirement-only predicate를 판정하고 별도 승인 아래 Design/Plan 삭제와 Spec marker의 `live` 전환만 수행한다. push와 global mutation은 어느 단계에도 포함하지 않는다.

## Open decision 의 close 지점

- atomic duty별 class 배정과 machine-required의 actual verifier 탐색·계산 범위는 이번 수정된 Design의 재승인에서 닫고, 그 배정과 범위를 바꾸지 않는 exact 문구만 Batch 1에서 닫는다. heading마다 하나의 class를 강제하지 않는다.
- same-wave first-use 범위는 planning gate에서 권고안(`not exercised` 공개) 또는 별도 multi-member scope 중 하나로 닫는다.
- `Validation evidence`와 `Known concerns`의 좁은 `N/A` 조건 및 미실행 validation 공개 경계는 Batch 1에서 문구로 닫는다.
- 의미 보존과 duty 수 불변은 Batch 2의 pre/post matrix로 닫는다.
- 합산 길이 비증가 요구는 Batch 2의 raw UTF-8 byte 측정으로 닫는다.
- B5 first-use 관찰과 canonical risk closure는 Batch 2의 input+result intake에서 닫는다.

## Stage rewind 조건

class 정의, active owner, exact-four scope, template/verifier/tests 불변 중 하나를 바꿔야 하면 구현을 멈추고 Design으로 돌아간다. Spec이 Plan에 없는 새 의무·예외·surface를 만들면 Plan으로 돌아간다. 구현이 scope를 넘거나 duty를 증감시키면 Batch 1 후보를 폐기하고 재구성한다. review-bound artifact 또는 그 의미가 review 뒤 바뀌면 commit으로 가지 않고 Batch 2로 돌아간다. 검증 근거가 부족하거나 framing pressure를 배제할 수 없으면 `inconclusive`로 보고하고 사용자 결정을 기다린다.
