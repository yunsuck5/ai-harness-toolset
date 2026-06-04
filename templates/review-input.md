# Review Input

이 파일은 `log/review/<review-task-id>/pass-NN/input.md` 의 형식 기준이다. Claude Code (operator-role AI) 가 본 template 을 기반으로 한 pass directory 의 `input.md` 본문을 직접 작성한다. Codex reviewer 는 결과로 같은 pass directory 의 `result.md` 한 파일만 생성한다.

`<review-task-id>` 는 하나의 Claude Code `/goal` 작업 또는 하나의 review gate 단위다. Claude Code chat / session id 가 아니다. 한 세션 안에서 서로 다른 주제의 `/goal` 이 여러 개 진행되면 각각 별도의 `<review-task-id>` 디렉터리를 사용한다. `pass-NN` (예: `pass-01`, `pass-02`) 는 같은 review task 안에서의 corrective loop 의 각 Codex review attempt 다. 각 pass directory 는 write-once 다 — input / result 가 stale 또는 부적절하면 새 pass 를 만들고, 기존 pass 의 파일을 손으로 보정해 review 를 닫지 않는다.

본 template 의 `{{AI_TO_FILL_*}}` placeholder 는 모두 AI 가 실제 내용으로 교체해야 한다. unfilled active placeholder 가 남아 있으면 `scripts/review-input-verify.ps1` 의 `\{\{AI_TO_FILL_[A-Za-z0-9_]+\}\}` regex 가 거부한다. 본 verifier 는 `AI_TO_FILL_` prefix 의 active placeholder 만 검사하므로, 본문에 generic `{{TOKEN}}` 형태 (예: `{{REAL}}`, `{{example}}`) 는 documentation literal 로 자유롭게 인용할 수 있다.

informational sections (`## Stage` / `## Purpose` / `## Target files` / `## Validation evidence` / `## Known concerns` / `## Framing self-check` / `## Reference sweep`) 는 `scripts/review-input-verify.ps1` 의 strict shape gate 대상이 아니지만 reviewer 가 본문을 읽는다. validation execution claim (예: Pester pass count, `verify-ps1` PASS, `git diff --check` clean) 이 있는 round 에서는 `## Validation evidence` 본문에 그 근거 Markdown evidence 의 path (예: `log/evidence/<scope>/<case>/validation-evidence.md`) 를 적어 reviewer 가 read-only inspect 할 수 있도록 한다. claim 자체가 부적용인 round 에서는 `N/A — no validation execution claims in this round.` 같은 짧은 명시를 본문에 둔다. 본 evidence 는 reviewer-readable runtime supporting material 이며 command re-execution 또는 deterministic truth oracle 이 아니다 — freshness binding 도 아니고 source-of-truth 로 승격되지도 않는다. reviewer 의 기본 동작은 이 evidence 를 *읽는* 것이지 operator 의 validation / build / test command 를 재실행하는 것이 아니다 — reviewer reproduction 은 opportunistic default 가 아니라 opt-in 이다. reviewer 가 특정 command 를 재실행하도록 하려면 review input 에서 그것을 명시적으로 authorize 하고 최소한 exact command · working directory · expected read/write behavior · allowed temp/output path · dependency assumptions · timeout expectation · interpretation boundary · how to report sandbox limitation 을 적는다. authorize 하지 않으면 reviewer 는 local evidence 를 inspect 하고, 재실행하지 못한 사실은 자동 target risk 가 아니라 `## Review limitations` 의 limitation 으로 보고한다 (target risk 승격에는 missing / stale evidence, scope mismatch, static contradiction, explicit high-risk gap 같은 독립 근거 필요). Visual Studio / MSBuild / C++ / CMake / Unity / Unreal / network restore / generated output / repo-external SDK 같은 target-project validation 은 sandbox 에서 실행 가능해 보여도 기본 재실행 대상이 아니다. 정책 source-of-truth: `docs/contracts/review/REVIEW_RESULT_CONTRACT.md` §3d. operator 측 validation scope 는 change class 에 따른다 — 모든 round 가 full suite 를 요구하지 않으며, full suite (또는 기대 validation) 를 실행하지 않았으면 change class / 수행한 validation / 미수행 validation / 미수행 사유 / 잔여 위험을 본 section 에 적는다. `git diff --check` 는 tracked / staged 만 cover 하므로 신규 / untracked 파일은 `git add -N <path>` 후 점검한다. reviewer 는 이 evidence 와 scope 근거를 *읽으며* full suite 를 직접 실행하지 않는다 (operator 가 실행 주체). 이 operator-side closeout scope 의 source-of-truth: `docs/contracts/review/REVIEW_RESULT_CONTRACT.md` §6c.

`## Known concerns` informational section 은 operator 가 review 호출 전에 이미 인지한 compromise / convention deviation / skipped alternative / baseline failure / validation limitation / operator assumption 을 reviewer 에게 사전 disclose 하는 자리다. recommended sub-categories: convention deviation, skipped alternatives, validation limitations, baseline failures, direct verification not performed, operator assumptions. operator 가 본 section 에 disclose 하지 않은 known concern 이 사후에 발견되면 그 verdict 는 stale-by-omission 으로 간주되어 commit/push 결정의 근거로 사용할 수 없으며 omitted concerns 가 disclosed 된 새 pass 의 re-review 가 필요하다. concerns 가 없는 round 에서는 본문을 `N/A — no known concerns disclosed.` 같은 짧은 명시로 둔다.

`## Known concerns` 는 두 종류를 담는다. **(1) confirmed disclosures** — 위 sub-category 처럼 operator 가 **확정적으로 인지한** 사실(이미 내린 compromise, 실제 baseline failure, 알고 있는 validation limitation 등). 사실로 기재하며 위 stale-by-omission 규칙이 전면 적용된다. **(2) open concerns / hypotheses to verify** — operator 가 의심하지만 **아직 확정하지 못한** 사항. 확정 결함처럼 단정하지 말고 `verify whether…` / `check whether…` 같은 중립 가설 표현으로 적어, reviewer 가 추정-결함을 confirm 하지 않고 독립적으로 평가하도록 한다 (`## Review questions` 의 neutral-phrasing convention 과 평행). **guard**: 진짜 알고 있는 compromise / limitation 은 반드시 (1) confirmed disclosure 로 적으며 hypothesis 로 위장하거나 완화하지 않는다 — hypothesis 표현은 미확정 의심에만 쓰고, 알려진 사실의 disclosure duty(stale-by-omission)를 회피하는 데 쓰지 않는다.

`## Framing self-check` informational section 은 operator 가 review 호출 전에 자신이 작성한 input (특히 `## Context` / `## Known concerns`) 이 reviewer 를 특정 verdict 로 유도하지 않는지 스스로 점검한 결과를 기록하는 자리다. 이는 `## Review questions` 의 *reviewer* framing self-audit question (reviewer 가 input 의 tilt 를 `## Notes` 로 표면화) 과 구분되는 *operator* 자신의 사전 self-check 다. 최소한 — (1) confirmed disclosure 와 open hypothesis 가 구분되어 있는지 (위 `## Known concerns` 의 (1)/(2) 참조), (2) input 이 결론을 선제시(conclusion-forward / closeout-framed / advocacy-framed)하지 않는지, (3) confirmatory 표현을 neutral 로 다시 쓴 부분이 있으면 무엇인지 — 가 드러나게 적는다. 이는 self-check 의 *기록* 이지 "input 이 중립적임" 을 검증된 사실로 주장하는 것이 아니다 — tilt 가 남아 있다고 판단되면 그대로 적어 reviewer 가 알 수 있게 한다. tilt 가 없다고 판단한 round 에서도 무엇을 점검했는지 한 줄로 적고 `done` 한 단어로 두지 않는다. 본 section 은 verifier 의 strict shape gate 대상이 아니며, framing 의 중립성은 기계적으로 판정되지 않는다 (operator self-check 이지 semantic lint 가 아니다).

`## Reference sweep` informational section 은 이름 / 위치 / 식별자 / 구조를 바꾸는 변경 (파일 rename · 이동 · **삭제 / 제거**, 식별자 집합 / range 변경, 폴더 역할 재정의, 용어 교체, fixed-line / fixed-token cleanup) 이 있는 round 에서 operator 가 review 호출 전에 수행한 reference sweep 의 *증거* 를 기록하는 자리다. 정책 source-of-truth 는 `docs/contracts/review/REVIEW_RESULT_CONTRACT.md` §5a.6 (four-class reference-sweep completeness) 다. `swept: yes` 같은 주장만 적지 말고 최소한 — (1) sweep 의 trigger (어떤 rename / move / delete / identifier / structure / fixed-token 변경), (2) 검색한 pattern, (3) 검색한 path 범위, (4) 네 class (filename·path / bare-token·ID / folder-as-bucket / semantic-phrasing) 중 점검한 것과 미점검(unswept) class, (5) grep 으로 잡히지 않는 semantic phrasing class 를 의미 기준으로 점검했는지 — 가 드러나게 적는다. **삭제 / 제거** 변경에서는 §5a.6 의 deletion granular technique 를 적용한다 — case-insensitive 검색, 철자 / 대소문자 변형(variant), 식별자 없이 섹션만 가리키는 bare-section 참조 (`§N`, `narrative §N`). 이름 / 위치 / 식별자 / 구조 변경이 없는 round 에서는 `N/A — no name/path/identifier/structure change this round.` 같은 짧은 명시를 둔다. 본 section 도 verifier 의 strict shape gate 대상이 아니며, sweep 의 완전성은 기계적으로 판정되지 않는다 (operator evidence 기록이지 sweep lint 가 아니다).

`## Review questions` 의 본문 (AI 가 채울 questions) 은 **neutral phrasing** 으로 작성한다. confirmation-seeking (예: `Are exactly N X migrated?`) 보다 open-ended (예: `How many X were migrated, and is that the intended scope?`) 권장. 마지막 권장 question 으로 reviewer 에게 framing-tilt self-audit 을 요청한다 — 예: `Does the input above nudge the reviewer toward a particular verdict? If so, surface the tilt in ## Notes.` 이 question 은 informational 권장이며 강제 아님. reviewer 의 답은 verdict vocabulary 자체를 변경하지 않고 `## Notes` 에 surface 한다.

본문에서 generic placeholder 모양 (예: `{{TOKEN}}`, `{{example}}`, 또는 `AI_TO_FILL_` prefix 가 없는 임의의 double-brace 형태) 을 인용해야 할 때는 별도의 escape / wildcard / brace-less workaround 가 필요 없다 — verifier 가 `AI_TO_FILL_` prefix 의 active placeholder 만 검출하므로 generic 형태는 documentation literal 로 그대로 prose 안에 인용할 수 있다. `AI_TO_FILL_` prefix 의 active placeholder 자체를 인용해야 할 때만 (예: 본 batch 가 그 placeholder 의 의미를 설명하는 경우) `AI_TO_FILL_VALIDATION_EVIDENCE` 같이 brace-less identifier 로 인용한다. RV-B-05 V1 첫 시기의 operator workaround 세 가지 (brace-less / wildcard / backslash-escape) 는 본 grammar narrowing 으로 obsoleted 되었으며 더 이상 maintained operator convention 이 아니다.

> **Effort / model / review category 는 `input.md` section 이 아니라 review-run invocation 선택이다.** reviewer effort 와 model 은 `scripts/review-run.ps1` 의 `-Effort` / `-Model`, `config/reviewer.json`, 그리고 (선택) `-EffortCategory <key>` 로 정해진다 (U9 config-backed category policy; source-of-truth `docs/policies/REVIEWER_CONFIG_POLICY.md`). category 는 operator 가 변경 class 를 알 때 review-run 호출 시 *명시 선택*하는 optional 값이며, 본 template 에 적는 section 도 아니고 모든 review 가 지정할 필요도 없다 (미지정 시 scalar config 경로가 정상 동작). 자동 분류는 없고, 본 note 는 parser/lint 요구가 아니다.

## Stage

{{AI_TO_FILL_STAGE}}

## Purpose

{{AI_TO_FILL_PURPOSE}}

## Target files

{{AI_TO_FILL_TARGET_FILES}}

## Validation evidence

{{AI_TO_FILL_VALIDATION_EVIDENCE}}

## Known concerns

{{AI_TO_FILL_KNOWN_CONCERNS}}

## Framing self-check

{{AI_TO_FILL_FRAMING_SELFCHECK}}

## Reference sweep

{{AI_TO_FILL_REFERENCE_SWEEP}}

## Context

{{AI_TO_FILL_CONTEXT}}

## Required inspection paths

{{AI_TO_FILL_REQUIRED_INSPECTION_PATHS}}

## Review questions

{{AI_TO_FILL_REVIEW_QUESTIONS}}

## Constraints

{{AI_TO_FILL_CONSTRAINTS}}

## Final verdict

reviewer (Codex) 는 같은 pass directory 의 `result.md` 한 파일로만 응답한다. `result.md` 는 다음 contract 를 정확히 따른다.

- 정확히 1 개의 top-level `## Verdict` heading 이 있다.
- `## Verdict` heading 다음의 첫 비어있지 않은 줄 (앞뒤 whitespace trim 후) 이 다음 셋 중 하나다:
  - `yes`
  - `no`
  - `yes with risk`
- 비교는 lowercase 정확 일치다. `Verdict: yes`, `Final verdict: yes` 같은 inline 형태, prose 안에 verdict 가 섞인 형태, heading 다음 줄에 verdict 와 다른 토큰을 함께 둔 형태는 모두 거부된다.
- `## Blocking findings`, `## Non-blocking concerns`, `## Review limitations`, `## Assumptions relied on` 4 개의 disclosure H2 는 각각 정확히 1 회 존재해야 한다 (parser-required by `scripts/review-verify.ps1 -RequireResult` since RV-B-05 V2 / commit `107eadc`). substance 가 없는 section 의 본문은 `none` 한 단어로 둔다.
- 위 외에 `## Findings`, `## Risks` (선택), `## Counter-argument` (선택, strongly-recommended; non-parser), `## Notes` (선택) section 을 자유롭게 둘 수 있다. shape 의 source-of-truth 는 `templates/review-result.md` 다.
- `## Counter-argument` 는 verdict 에 대한 strongest case AGAINST 를 dedicated position 으로 articulate 하는 optional disclosure section 이다. verdict 가 `yes` 또는 `yes with risk` 인 round 에서 reviewer 는 substantive 한 본문을 작성하는 것이 권장되며, deliberate pressure-test 후 material counter-argument 가 발견되지 않으면 본문은 짧은 literal (`none` 또는 `no material counter-argument identified`) 로 둔다. ceremonial boilerplate 는 회피한다. parser-required 가 아니며 omission 은 parser FAIL 이 아니다. `## Notes` 와의 substance boundary 와 boilerplate-degeneration mitigation 의 자세한 convention 은 `docs/contracts/review/REVIEW_RESULT_CONTRACT.md` §3c 참조.

operator-role AI 가 verdict 와 4 disclosure section 본문을 읽은 뒤 수행할 next-action mapping (`yes` / `no` / `yes with risk` 각각의 다음 단계) 의 source-of-truth 는 `docs/contracts/review/REVIEW_RESULT_CONTRACT.md` §6a (Verdict → next-action mapping) 다. verdict line 만으로 다음 단계를 결정하지 않으며, 4 disclosure section 본문을 함께 읽는다 (§6a Output consumption guidance).

verdict 는 commit / push / publish / merge / release / deployment 를 자동 승인하지 않는다. 사용자가 별도 명시 결정으로 처리한다.

yes / no / yes with risk
