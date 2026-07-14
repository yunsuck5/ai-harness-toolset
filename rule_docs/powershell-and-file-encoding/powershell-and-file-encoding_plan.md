# powershell-and-file-encoding Plan — native capture contract revision

> 이 Plan은 위 Design을 terminal rule과 owner surface에 반영하기 위한 approval-target 결정만 담는다. 실행 기록은 operator report 소관이며, 이 문서는 closeout에서 삭제된다. 이 Plan은 mutation/commit/push 승인이 아니다.

## Header

- 대상: native capture invariant/realization 분리를 한 개 existing-rule revision으로 정합화한다.
- 도착점: terminal rule, root mirrored summary, helper 설명, helper/lint 검증이 같은 contract를 가리키고 corrected-state review가 이를 함께 본다.
- 제외: Work Packet, `docs/blind-advisory/` 및 해당 skill surface 변경, broader rule cleanup, commit 구성의 선결정.

## Batch 순서와 의존

- 단일 revision unit으로 진행한다. terminal rule의 의미와 helper·검증 표면이 상호의존하므로 구현·검증 경계를 분리하지 않는다.
- 현 rule 초안은 이 Design의 semantic target과 아래 결정을 만족하는지 다시 판정한 뒤 terminal 문안으로 승계한다. pre-lifecycle 초안이었다는 사실만으로 정당화하지 않는다.
- Work Packet은 만들지 않는다. 새 round-scoped 조사나 line inventory를 보존할 필요가 없고, 기존 evidence 및 실행 결과는 operator report가 소유한다.

## Batch 정의

- **목적**: 안정된 capture contract와 `scripts/lib/native-process.ps1`의 byte-stdin 경로를 포함한 현재 realization을 분리하고 terminal rule과의 1:1 정합을 회복한다.
- **scope**: terminal rule native-output 문단; root `CLAUDE.md`/`AGENTS.md`의 동일 shared-summary 1문장; helper 상단의 stale EAP 설명과 observable contract; `native-process.Tests.ps1`의 contract·pipe-pressure 회귀; Step F script/test의 actual-comment exception 판별과 음성 회귀; planning home의 active-lifecycle 구조와 rule-specific future-work backlog.
- **hard boundary**: structured separate-stream capture를 표방하는 surface의 적합성은 분리된 stdout/stderr/exit와 정상 결과의 `ExitCode`/`Stdout`/`Stderr` three-field capability로 판정하고, `Invoke-NativeProcess`는 preferred default realization로 둔다. conforming alternate realization을 helper-membership만으로 금지하지 않는다. simple stdout-only capture와 승인된 Step F raw-merged site를 conforming structured capture로 재분류하지 않으며 유지·migration 판단은 별도 규칙정비로 이관한다. Step F의 명시적·사유기록형 physical-line comment exception을 보존하되 literal single-line 위험형을 찾는 부분 guardrail보다 넓게 주장하지 않는다. command data의 marker text는 exception으로 취급하지 않는다. root는 두 파일의 동일 shared-body 문장만 수정하고 vendor header·그 밖의 bytes를 보존하며 managed block을 삽입하지 않는다. 이 exact root 편집은 별도 사용자 scoped approval을 받은 범위에만 결박한다. 기존 호출부·`docs/blind-advisory/` 및 해당 skill surface·global-distribution tier·다른 rule은 수정하지 않는다. `review-adapter.Tests.ps1`의 alternate realization은 three-field capability를 만족하므로 수정하지 않고, `install-pipeline-core.ps1`의 weaker two-field capture는 별도 규칙정비 위험으로 이관해 이번 unit에서 수정하지 않는다.
- **helper contract 결정**: 상단 설명을 no-stdin 경로의 EAP containment와 byte-stdin 경로의 .NET containment로 나누고, byte-stdin의 bound/unbound 분기·byte-exact 전송과 EOF·동시 drain·strict decode·cleanup·three-field result를 helper 표면의 explicit observable contract로 둔다. terminal rule에는 이 mechanics를 흡수하지 않는다.
- **Step F 결정**: production lint는 `tests/**/*.ps1`의 물리 행을 대상으로 literal native raw-merged text, 비-capture discard, actual comment에 기록된 사유가 필수인 pragma, 보수적 matcher 범위를 계속 시행한다. terminal rule은 이를 제한적 lexical guardrail로만 가리키며 AST/capture-site proof, exhaustive enforcement, broader compliance evidence를 주장하지 않는다. tests는 forbidden text, discard, reason-bearing comment의 허용, bare/whitespace-only comment와 command string 내부 marker의 거부를 결박한다. current matcher가 command data marker를 exception으로 오인하므로 script와 test를 함께 교정한다.
- **validation expectation**: rule의 모든 문장이 structured-contract conformance·partial guardrail·current-realization description으로 단일 분류됨; 모든 native capture에 three-field를 강제하는 전칭, helper-membership 전칭, 제3 경로를 금지하는 closed enumeration 없음; helper의 두 경로가 정상 결과 contract를 공유하고 byte-stdin observable contract가 tests와 대응함; helper 20 tests와 Step F의 reason-bearing comment positive·bare/whitespace-only·string-marker negative coverage, `repo-local-instruction-parity.Tests.ps1` AC-RLIS-3/4, affected/full Pester, `verify-ps1`, `docs-working-model-check` 통과; root shared body byte parity·marker 0/0·vendor header/그 밖의 bytes 보존; `.ps1` BOM+CRLF 및 `.md` no-BOM+LF; `docs/blind-advisory/` 및 해당 skill surface byte 불변. repo-wide encoding MUST와 verifier 범위의 차이는 별도 규칙정비 대상으로 공개 제외하며 이 validation으로 해소됐다고 주장하지 않는다.
- **review focus**: invariant 완화·신설 과잉, descriptive 문장의 de facto allow-list화, exception qualifier·comment-token 오인, rule/test owner 혼선, root scoped-exception 범위·mirror parity, stale source 설명, lifecycle home/closeout 누락.

## Open decision의 close 지점

- Design risk 1(false closure) — terminal 문장 분류 셀프리뷰와 독립 감사에서 닫는다.
- Design risk 2(stale EAP 설명) — 이 Plan에서 branch-aware 교정을 채택해 닫는다.
- Design risk 3(rule↔tests owner 혼선) — terminal/implementation normative 대응표와 Step F 점검 결과로 corrected-state review 요청 전에 닫는다.
- Design risk 4(root/Step F exception 오인) — root parity와 command-string marker 음성 회귀로 corrected-state review 전에 닫는다.
- 다른 active rule과의 새 충돌 — 수정하지 않고 rule/조문과 영향 반경만 기록한 뒤 중단한다.

## Closeout / retire 조건

- corrected-state review가 terminal rule + root mirrored summary + `scripts/lib/native-process.ps1` + helper/Step F 검증 + lifecycle 정합을 같은 boundary에서 검토하고, 별도 사용자 commit gate를 거친다. commit 분할/결합은 그 gate에서 정한다.
- closeout은 terminal rule과 implementation의 normative-sentence 1:1 evidence, inbound reference sweep, Level 1 `docs/README.md`, Level 2 terminal rule, `rules/README.md`와 root instruction route summary, Step F owner surfaces를 각각 `updated` 또는 `checked — no change required`로 기록한 뒤 수행한다.
- closeout 전에 Design의 current-bearing 결정과 Plan의 still-relevant 결정이 terminal rule 또는 올바른 owner surface에 모두 흡수되고, Design/Plan에만 남은 unique live meaning이 없음을 확인한다. 그 뒤 Design/Plan을 삭제하고 `rule_docs/powershell-and-file-encoding/.gitkeep`와 `powershell-and-file-encoding_backlog.md`를 남긴다. encoding 검증 gap, weaker/partial/raw capture 처분, Step F lexical residual, helper-contract owner 기준은 backlog에 열린 future work로 유지하며 이 temporary revision의 closeout으로 종결하지 않는다.

## Stage rewind 조건

- 이 Plan이 Design의 capability-based semantic target 또는 non-goal을 위반하면 Design으로 되돌아간다.
- terminal rule이 helper behavior와 맞지 않거나 허용 구현을 다시 닫으면 Plan을 다시 연다.
- 구현 변경이 approved Step F actual-comment 판별과 helper의 기존 byte-stdin 회귀를 넘어 새로운 behavior·호출부·다른 rule로 확장되면 중단하고 사용자에게 범위를 반환한다.
