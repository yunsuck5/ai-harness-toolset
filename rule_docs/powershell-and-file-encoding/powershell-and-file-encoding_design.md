# powershell-and-file-encoding Design — native capture invariant와 realization 분리

> 이 문서는 기존 repo-only rule revision의 방향을 정한다. 영구 live surface가 아니며 closeout에서 terminal rule로 흡수된 뒤 삭제된다. 이 문서는 mutation/commit/push 승인이 아니다.

## Header

- 대상: `rules/powershell-and-file-encoding.md`의 native-executable output capture 계약.
- 도착점: helper의 안정된 capture contract와 현재 내부 구현 설명이 분리되어, 새 구현 경로도 같은 contract로 판정된다.
- 제외: 범용 process framework 설계, `docs/blind-advisory/` 및 해당 skill surface 수정, global-distribution rule 개정, broader root-instruction cleanup, 최종 normative 문구.

## 왜 바꾸는가 / 무엇을 바꾸는가

현 terminal rule은 capture-for-use의 안정된 stream/result 요구와, 당시 유일했던 `Invoke-NativeProcess` no-stdin 구현의 EAP/temp-file/`$LASTEXITCODE` 방식을 한 문장에 결합했다. helper에 byte-stdin 경로가 추가되면서 특정 helper membership·관찰 가능한 capability·내부 realization의 경계를 분리해야 한다는 문제가 드러났다.

이 revision의 semantic target은 다음이다.

- structured separate-stream capture를 표방하는 surface의 적합성은 특정 helper membership이 아니라 stdout/stderr/exit code를 분리하고 정확한 three-field result shape를 제공하는 capability로 판정한다. `Invoke-NativeProcess`는 preferred default realization이다. simple stdout-only capture와 승인된 Step F raw-merged site를 이 임시 계약의 conforming structured capture로 재분류하지 않으며, 유지·migration 판단은 별도 정비로 남긴다.
- Step F는 `tests/**/*.ps1` 물리 행의 literal raw merged-capture text를 다루는 제한적 lexical guardrail이다. 명시적·사유기록형 physical-line comment exception을 보존하되 AST/capture-site proof나 broader compliance evidence로 과장하지 않는다. command data 안의 marker text는 comment exception이 아니다.
- EAP/temp-file/`$LASTEXITCODE` 및 .NET/raw-byte/in-memory drain은 현재 realization의 설명으로 둔다.
- 허용 구현을 현재 두 경로로 닫지 않는다. 미래 경로는 이름이나 구현 기법이 아니라 위 contract 충족 여부로 판정한다.
- root `CLAUDE.md`와 `AGENTS.md`의 shared summary는 terminal rule을 다시 정의하지 않는 mirrored downstream summary이며, terminal의 명시적 exception을 부정하지 않는다.

## Owner surface model

- terminal rule은 structured capture의 capability-based conformance 기준과 Step F의 부분 enforcement boundary를 소유한다.
- `scripts/lib/native-process.ps1`은 preferred default realization의 실제 분기·전송·정리 behavior와 byte-stdin observable contract를 소유한다.
- `tests/native-process.Tests.ps1`은 helper의 관찰 가능한 contract와 현재 경로의 회귀를 검증한다.
- `scripts/verify-ps1.ps1`과 `tests/verify-ps1.Tests.ps1`은 tests tree의 raw merged-capture lint를 소유한다.
- root `CLAUDE.md`와 `AGENTS.md`는 terminal rule을 가리키는 byte-identical shared summary만 소유한다.
- docs-working-model은 이 revision의 lifecycle만 규율하며 native-process behavior를 흡수하지 않는다.

## 수정 대상

- `rules/powershell-and-file-encoding.md` native-output 문단.
- `scripts/lib/native-process.ps1`의 두 경로와 맞지 않는 상단 EAP 설명 및 byte-stdin observable contract.
- `scripts/verify-ps1.ps1`의 reason-bearing exception 판별과 helper/lint tests의 contract·안전 경계 회귀.
- root `CLAUDE.md`와 `AGENTS.md`의 native-output shared summary 1문장.
- `rule_docs/powershell-and-file-encoding/`는 이 existing-rule revision의 planning home이며, closeout 뒤 Design/Plan은 삭제하고 `.gitkeep`와 future-work backlog를 남긴다.

## 하지 않을 것 (non-goals)

- timeout, environment, cross-shell, text-stdin 또는 범용 process API 추가.
- 기존 no-stdin 호출부의 일괄 수정이나 `docs/blind-advisory/` 및 해당 skill surface 변경.
- root instruction의 native-output shared summary 1문장 밖 정비 또는 managed-block 삽입.
- repo-only rule을 `snippets/rules/`로 승격하거나 다른 PowerShell 규칙을 함께 정비.
- 현재 두 realization을 완결 allow-list로 고정하거나, stream 분리·result shape를 선택 사항으로 완화.
- 별도 terminology 등록: 새 project-specific term을 도입하지 않는다.

## Plan readiness / open risks

- Plan으로 내려갈 준비가 됐다. 문제, owner, semantic target, non-goal이 한 rule revision으로 닫힌다.
- risk 1 — descriptive 목록이 다시 허용 구현의 닫힌 열거로 읽힐 수 있음: terminal 문장 분류와 독립 false-closure 감사에서 닫는다.
- risk 2 — helper 상단의 “함수 전체가 EAP를 pin한다”는 설명이 byte 경로와 어긋남: behavior 변경 없이 branch-aware 설명으로 고칠지를 Plan에서 결정한다.
- risk 3 — rule과 tests가 서로 다른 contract를 소유하는 것으로 읽힐 수 있음: normative-sentence 1:1 대응과 Step F owner 점검으로 closeout 전에 닫는다.
- risk 4 — root summary가 terminal exception을 지우거나 Step F가 command data의 marker를 pragma로 오인할 수 있음: mirrored-summary parity와 comment-token 음성 회귀로 닫는다.
- broad rule 정비는 이 revision 밖이며, 다른 활성 rule blocker가 나오면 cascade 경계에 따라 식별·영향 반경까지만 확인한다.
