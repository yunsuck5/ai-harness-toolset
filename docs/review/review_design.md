# review Design — byte-faithful reviewer 입력과 usable-result 경계

## Header

- 이 문서는 review 도메인의 reviewer 입력 transport와 결과 소비 경계를 정합화하는 Design이다.
- 완료 시 caller가 조립한 UTF-8 payload가 Windows PowerShell 5.1 경로에서도 byte-faithful하게 전달되고, usable reviewer judgment가 없을 때 세 verdict 중 하나가 제조되지 않는다.
- 실행 기록이나 terminal Spec이 아니며 mutation·commit·push·global activation 승인이 아니다.

## 왜 바꾸는가 / 무엇을 바꾸는가

현재 runner는 UTF-8 `input.md`를 문자열로 읽은 뒤 PowerShell pipeline으로 reviewer CLI에 전달한다. Windows PowerShell 5.1의 실제 native 경계에서 non-ASCII가 `?`로 치환되고 payload 뒤에 CRLF가 추가되는 것이 재현됐지만, runner는 parse 가능한 synthetic result를 받으면 이 transport 손상을 알지 못한 채 성공을 보고한다.

결과 쪽에서는 CLI nonzero·result 부재·verdict parse 실패가 이미 실패로 닫히지만, reviewer preamble과 operator workflow 일부 문면은 판단 불능까지 `no` 또는 `yes with risk`로 접거나 failure-only 흐름에도 최종 verdict를 요구하는 것으로 읽힐 수 있다. transport/execution failure와 evidence 부족에 대한 실제 review judgment를 구분하고, usable judgment가 없으면 source verdict도 없다는 경계를 명확히 한다.

두 문제를 하나의 review-owner changeset에서 닫는다. caller가 reviewer preamble과 canonical input을 합친 payload bytes를 소유하고, 기존 byte-stdin structured capture를 사용해 text pipeline을 우회한다. result shape와 세 verdict는 유지하되 오직 usable reviewer judgment에만 적용한다.

## Owner surface model

- `scripts/review-run.ps1`: reviewer payload의 strict UTF-8 byte 조립, byte-safe adapter invocation, invocation/result failure와 judgment 발행의 분리를 소유한다.
- `scripts/lib/native-process.ps1`: raw stdin bytes와 stdout/stderr/exit code의 structured capture capability를 제공한다. review 의미나 verdict를 소유하지 않는다.
- `scripts/review-verify.ps1`: 성공 result의 기존 verdict/disclosure shape만 기계 검증한다. invocation 성공이나 semantic sufficiency를 증명하지 않는다.
- `snippets/claude-skills/ai-harness-review/SKILL.md`: operator가 runner/verify/body를 순서대로 소비하고 unavailable failure와 usable verdict를 구분해 보고하는 workflow를 소유한다. 배포·adoption 설명은 현행 Claude/Codex native installation과 정합해야 한다.
- `templates/review-input.md` / `templates/review-result.md`: 성공 judgment를 요청·기록하는 기존 two-file shape를 소유한다. unavailable을 네 번째 verdict나 새 result H2로 만들지 않는다.
- `docs/review/review_spec.md`: 위 target-state 의미와 owner 경계를 명세한다.
- review/PFE backlogs: 이번 변경이 실제로 소비한 future-work만 삭제하고 ID floor는 유지한다.

## 수정 대상

- review live Spec, review skill, runner, review input/result template와 affected tests
- transport capture site 변경에 따라 해당하는 PowerShell native-capture backlog 회계
- review backlog의 input-fidelity/result-integrity/open-channel 항목
- operator-facing review 사용 설명 중 failure/verdict 경계

## 하지 않을 것 (non-goals)

- PowerShell 7 지원 확대, 새 범용 transport framework, 새 reviewer adapter를 도입하지 않는다.
- verdict를 추가하거나 `unavailable`을 verdict·result H2·canonical sidecar로 만들지 않는다.
- semantic evidence sufficiency나 disclosure 본문을 parser lint로 기계 판정하지 않는다.
- result Markdown heading/fence/wrapper를 재설계하지 않고 canonical two-file layout을 유지한다.
- retry/auto-fix/fallback, multi-reviewer orchestration, global ToolRoot update나 activation을 이 source changeset에 포함하지 않는다.

## Plan readiness / open risks

방향과 owner가 정해져 Plan으로 진행할 수 있다. 기존 byte-stdin helper를 실제 Codex PowerShell shim 경로에 적용했을 때 payload bytes가 추가·손실 없이 전달되는지는 구현 전 synthetic raw-byte probe로 닫는다. helper 경계만으로 해결되지 않아 새 framework나 adapter contract가 필요하면 구현하지 않고 Design으로 되돌아온다.

evidence 부족은 두 경우로 나눈다. reviewer가 누락 evidence 자체를 구체적 blocker/risk로 판단할 수 있으면 기존 verdict를 발행할 수 있다. blocker 존재 여부 자체를 판단할 수 없거나 invocation/result가 usable하지 않으면 verdict를 발행하지 않고 failure로 보고한다.
