# Review input 작성 요구사항 enforcement class Design

> 이 문서는 W-44/F14의 임시 Design이다. current-bearing 의미는 최종 corrected-state review 전에 기존 owner에 흡수하고, closeout에서는 이 문서를 삭제한다. 이 문서는 구현·commit·push 승인이 아니다.

## Header

이 Design은 review `input.md` 작성 요구사항을 `machine-required` / `always` / `conditional` / `N/A-allowed`로 재구성하는 방향을 정한다.
이 체인이 끝나면 작성자는 기존 표면만으로 기계적 형식 요구와 의미상 작성 의무를 구별할 수 있고, 현행 B5 의미와 verifier contract는 보존된다.
이 문서는 최종 문구, 실행 순서, 검증 결과 또는 변경 승인을 대신하지 않는다.

## 왜 바꾸는가 / 무엇을 바꾸는가

현행 review skill §3은 verifier가 실제로 강제하는 형식, 매 unit에 필요한 의미, 상황별 정보, 부재 시 `N/A`를 쓸 수 있는 위치를 한 층위에서 설명한다. 반면 template의 H2 수는 verifier의 required-heading 수보다 많고, `when relevant` 같은 표현은 identity 정보의 상시성 및 validation 미실행 공개와 `N/A`의 경계를 유일하게 정하지 못한다. H2마다 단일 label을 붙이면 기계 강제 범위를 과장하거나 한 위치에 공존하는 의무를 잃는다.

목표 모델은 heading이 아니라 **atomic authoring duty**를 분류한다. 같은 위치에도 서로 다른 class가 함께 있을 수 있다.

- `machine-required`: 현행 verifier의 실제 탐색 범위와 required-H2-delimited body-range 계산에 따라 reject되는 packet shape다. 이 class는 semantic completeness의 증명이 아니다.
- `always`: 모든 review unit에서 의미상 채워야 하지만 기계 강제 여부와는 독립인 의무다.
- `conditional`: 명시된 trigger가 존재할 때만 작성하는 의무다.
- `N/A-allowed`: 기존 informational 위치에서 해당 정보가 진정으로 부재할 때만 허용되는 좁은 fallback이다. 적용 가능한 일을 수행하지 않은 경우의 공개를 대체하거나 required semantic content를 비우는 일반 탈출구가 아니다.

승인 대상 class allocation은 다음의 exhaustive default+exception 규칙이다. `machine-required`는 독립적인 shape overlay이고, semantic duty는 명시된 conditional/N/A 예외가 아니면 `always`다. 구현은 문구를 압축할 수 있지만 duty를 재분류할 수 없다.

- **Machine-required shape:** `Context`, `Required inspection paths`, `Review questions`, `Constraints`, `Final verdict` H2는 각각 정확히 한 번 있어야 하고, active `AI_TO_FILL_*` placeholder는 packet 전체에서 없어야 한다. 그 밖의 body·literal·legacy-phrase 검사는 required H2를 실제 위치순으로 놓고 각 heading 직후부터 다음 required H2 또는 EOF까지 계산한 범위에만 적용하며, 그 사이의 informational H2와 내용도 앞선 required H2의 계산 범위에 포함한다. Non-final 계산 범위는 trim 후 non-whitespace여야 하고, Final 계산 범위는 `yes / no / yes with risk` 문구를 대소문자 비구분 substring으로 포함해야 하며, 모든 계산 범위에는 verifier-owned exact-case legacy phrase substring이 없어야 한다. 첫 required H2 앞의 내용은 body·legacy-phrase 검사 범위가 아니다. 따라서 이 overlay는 각 H2의 직접 semantic body가 non-empty라거나 Final 문구가 exact-case·whole-body라거나 legacy phrase가 packet 전체에 없다는 보장을 만들지 않는다.
- **Always semantic default:** Stage, Purpose, Review perspective, Target files와 Context는 unit·stage·exact artifact boundary를 식별하고 planning approval을 implementation acceptance와 합치지 않는다. Required paths는 exact path와 역할을 적고 source target/runtime evidence/off-repo context를 구분하며, questions는 결론을 유도하지 않는 open-ended question, constraints는 mutation·scope·authority를 적는다. Validation scope와 수행·미수행·사유·잔여 risk는 정직하고 change-class-proportional하게 공개한다(`script/runtime/parser/test/install`은 normally full suite, `docs/wording`은 targeted check 가능). Evidence는 supporting material일 뿐 re-execution·truth oracle·freshness binding·source-of-truth가 아니고 cited evidence는 reviewer가 기본적으로 직접 읽는다. Non-reproduction만으로 target risk가 되지 않으며 missing/stale evidence, scope mismatch, static contradiction, explicit high-risk gap 같은 독립 근거가 있어야 승격한다. `git diff --check`는 tracked/index-visible change만 다루며 `git add -N`은 쓰지 않는다. Known concerns는 fact/limit와 question을 분리하고 fact를 약화하지 않으며 caller conclusion·expected/prior verdict·advocacy를 제외한다. Final verdict에는 required literal을 유지하고 실제 verdict를 쓰지 않으며 runner preamble 소유의 output instruction을 복제하지 않는다.
- **Conditional exceptions — complete list:** Context의 material fact/open question은 실제로 material할 때 쓴다. External claim에는 exact provenance를 적고, caller가 확인하지 못한 claim에는 추가로 `unverified`를 표시한다. Persistence가 severity/closure에 영향을 줄 때 transience·committed-temporary 경계를 finding prose에 요구하고 이를 위한 새 verdict/H2/parser field/tag를 만들지 않는다. Task-grade는 사용자가 제공했을 때만 적고, default 발명·사후 threshold 하향·blocker 자동 완화를 하지 않는다. False-positive dismissal을 제안할 때는 evidence와 사용자 결정을 요구한다. Execution claim에는 `log/evidence/**` 아래 reviewer-readable Markdown bundle을 적는다. Broad reproduction은 명시적으로 authorize하고 exact command/cwd/expected read-write/allowed output/dependency/timeout/interpretation boundary/sandbox-failure reporting을 적는다. Tool-native raw report를 쓸 때는 original path와 답할 claim을 Required paths에 적는다. Staging 권한 없이 새 untracked file이 있을 때는 직접 whitespace/encoding을 확인하고 좁은 coverage를 공개한다. Material fact·compromise·validation limitation·open question 또는 target/scope/required-evidence omission이 있으면 Known concerns에 적는다. 그러한 material fact/evidence 또는 omission 사실 자체를 input에서 누락하면 pass가 stale하다. Prior artifact가 target/required evidence일 때 paraphrase 대신 exact direct-read path를 적는다. 그 material이 off-repo/sibling이면 추가로 advisory이자 never-source-of-truth로 한정하고 caller-declared existing absolute path를 `-ExternalReadDirectory`/`-ExternalReadFile`로 전달하며 exact load-bearing target을 열거한다. Reviewer가 이를 직접 읽게 하고 proxy·inline·stage·workspace copy를 금지한다.
- **N/A-allowed branches — complete list:** Validation evidence는 execution·validation claim과 관련 내용이 실제로 없을 때, Known concerns는 material concern과 omission이 없을 때만 `N/A`다. Applicable-but-unperformed validation은 미실행 사실·이유·남은 불확실성을 적는다. 다른 semantic location에는 `N/A`를 새로 허용하지 않는다.

## Owner surface model

- review skill §3이 class allocation과 compact authoring index의 단일 active home을 소유한다.
- template은 기존 point-of-use skeleton과 semantic detail을 유지하며 class map을 중복 소유하지 않는다. 의미는 skill·template·verifier의 결합으로 복원한다.
- verifier는 현행 machine contract를 소유하고, tests는 그 contract를 고정한다. F14는 둘을 변경하지 않는다.
- review Spec은 target state와 active owner 경계를 기록하되 runtime authority를 흡수하지 않는다.
- Design/Plan은 승인과 추적을 위한 임시 planning artifact이며 closeout 뒤 남지 않는다.

## 수정 대상

최종 content-bearing candidate의 source-managed review scope는 이 Design, 이 Plan, `docs/review/review_spec.md`, `snippets/claude-skills/ai-harness-review/SKILL.md`로 이루어진 exact four다. 이 중 closeout 뒤 남는 target-state/active implementation 수정 surface는 Spec과 Skill 두 파일이다. 전자는 lifecycle marker를 `sync-required`로 전환하고 target state를 얇게 기록하며, 후자는 §3의 기존 작성 지침을 class map으로 재조직한다. `templates/review-input.md`, `scripts/review-input-verify.ps1`, 관련 tests는 validation 기준으로만 읽고 byte를 바꾸지 않는다.

## 하지 않을 것 (non-goals)

- 새 문서 종류, checklist, H2, placeholder, parser field/tag, verifier heading 또는 test hard gate를 만들지 않는다.
- template에 class map을 복제하거나 H2별 단일 class 표를 만들지 않는다.
- B5의 `Known concerns`, input+result, same-wave semantics와 review orchestration을 바꾸지 않는다.
- skill §3과 template guidance의 합산 길이 또는 operator atomic duty 수를 늘리지 않는다.
- verifier가 허용한다는 이유로 의미상 불충분한 `N/A`를 승인하지 않는다.
- review 밖의 terminology, install, global payload 또는 broad cleanup으로 scope를 넓히지 않는다.

## Plan readiness / open risks

방향 결정은 Plan으로 내릴 준비가 됐다. Plan은 한 content batch에서 위 allocation의 exact wording, duty 보존, 길이 비증가를 닫고 이어서 validation과 canonical review를 수행한다.

남은 위험은 class wording을 줄이는 과정에서 기존 의무가 탈락하거나, `N/A`가 미실행 공개를 가리거나, template guidance와 중복되어 합산 길이·의무 수가 늘어나거나, machine-required를 범위 없는 `non-empty H2`·packet-global legacy-phrase 금지로 다시 과장하는 것이다. 구현 batch에서 pre/post duty matrix, raw UTF-8 byte 수, verifier 탐색·계산 범위와 compact wording의 직접 대조로 닫는다. verifier 또는 template 변경이 필요하다고 판명되면 이 Design의 owner/boundary를 넘으므로 구현을 멈추고 재설계한다.

B5 first-use의 same-wave 관찰에는 planning 결정 하나가 남는다. Canary-first fresh dual은 두 member 중 하나를 선행 canary로 소비하므로 remainder cardinality가 1이고 multi-member ordering을 실제 자극하지 못한다. 권고안은 review unit을 순증하지 않고 canary-outside-wave와 remainder terminal-accounting 규칙을 적용한 뒤 multi-member ordering을 `not exercised`로 공개하는 것이다. 실제 multi-member exercise가 acceptance에 필요하다면 제3 unit을 조용히 추가하지 않고 scope를 다시 승인받는다.
