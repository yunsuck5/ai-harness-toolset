# Review Input

이 파일은 `log/review/<review-task-id>/pass-NN/input.md` 의 형식 기준이다. Claude Code (operator-role AI) 가 본 template 을 기반으로 한 pass directory 의 `input.md` 본문을 직접 작성한다. Codex reviewer 는 결과로 같은 pass directory 의 `result.md` 한 파일만 생성한다.

`<review-task-id>` 는 하나의 Claude Code `/goal` 작업 또는 하나의 review gate 단위다. Claude Code chat / session id 가 아니다. 한 세션 안에서 서로 다른 주제의 `/goal` 이 여러 개 진행되면 각각 별도의 `<review-task-id>` 디렉터리를 사용한다. `pass-NN` (예: `pass-01`, `pass-02`) 는 같은 review task 안에서의 corrective loop 의 각 Codex review attempt 다. 각 pass directory 는 write-once 다 — input / result 가 stale 또는 부적절하면 새 pass 를 만들고, 기존 pass 의 파일을 손으로 보정해 review 를 닫지 않는다.

본 template 의 `{{AI_TO_FILL_*}}` placeholder 는 모두 AI 가 실제 내용으로 교체해야 한다. unfilled placeholder 가 남아 있으면 `scripts/review-input-verify.ps1` 의 `\{\{[A-Za-z_][A-Za-z0-9_]*\}\}` regex 가 거부한다.

informational sections (`## Stage` / `## Purpose` / `## Target files` / `## Validation evidence` / `## Known concerns`) 는 `scripts/review-input-verify.ps1` 의 strict shape gate 대상이 아니지만 reviewer 가 본문을 읽는다. validation execution claim (예: Pester pass count, `verify-ps1` PASS, `git diff --check` clean) 이 있는 round 에서는 `## Validation evidence` 본문에 그 근거 Markdown evidence 의 path (예: `log/evidence/<scope>/<case>/validation-evidence.md`) 를 적어 reviewer 가 read-only inspect 할 수 있도록 한다. claim 자체가 부적용인 round 에서는 `N/A — no validation execution claims in this round.` 같은 짧은 명시를 본문에 둔다. 본 evidence 는 reviewer-readable runtime supporting material 이며 command re-execution 또는 deterministic truth oracle 이 아니다 — freshness binding 도 아니고 source-of-truth 로 승격되지도 않는다.

`## Known concerns` informational section 은 operator 가 review 호출 전에 이미 인지한 compromise / convention deviation / skipped alternative / baseline failure / validation limitation / operator assumption 을 reviewer 에게 사전 disclose 하는 자리다. recommended sub-categories: convention deviation, skipped alternatives, validation limitations, baseline failures, direct verification not performed, operator assumptions. operator 가 본 section 에 disclose 하지 않은 known concern 이 사후에 발견되면 그 verdict 는 stale-by-omission 으로 간주되어 commit/push 결정의 근거로 사용할 수 없으며 omitted concerns 가 disclosed 된 새 pass 의 re-review 가 필요하다. concerns 가 없는 round 에서는 본문을 `N/A — no known concerns disclosed.` 같은 짧은 명시로 둔다.

`## Review questions` 의 본문 (AI 가 채울 questions) 은 **neutral phrasing** 으로 작성한다. confirmation-seeking (예: `Are exactly N X migrated?`) 보다 open-ended (예: `How many X were migrated, and is that the intended scope?`) 권장. 마지막 권장 question 으로 reviewer 에게 framing-tilt self-audit 을 요청한다 — 예: `Does the input above nudge the reviewer toward a particular verdict? If so, surface the tilt in ## Notes.` 이 question 은 informational 권장이며 강제 아님. reviewer 의 답은 verdict vocabulary 자체를 변경하지 않고 `## Notes` 에 surface 한다.

본문에서 template placeholder token (예: `AI_TO_FILL_*` 형태) 을 정직히 인용해야 할 때는 review-input-verify 의 token regex `\{\{[A-Za-z_][A-Za-z0-9_]*\}\}` 의 false positive 를 회피하기 위해 다음 셋 중 하나의 operator convention 을 사용한다 — (a) brace-less identifier 만 인용 (예: `AI_TO_FILL_VALIDATION_EVIDENCE`), (b) wildcard form (예: `AI_TO_FILL_*` 같이 specific full name 비포함), (c) backslash-escaped literal form (예: `\{\{TOKEN\}\}`). 세 form 모두 같은 메커니즘으로 mechanical-safe 다 — placeholder regex 의 leading `\{\{` 는 raw file bytes 에서 인접 두 `{` 문자를 요구한다. (a) brace-less 와 (b) wildcard 는 token 자체에 brace 가 없어 두-brace substring 이 input 에 나타나지 않는다. (c) backslash-escaped literal `\{\{TOKEN\}\}` 는 raw file bytes 가 13 char (`\`, `{`, `\`, `{`, `T`, `O`, `K`, `E`, `N`, `\`, `}`, `\`, `}`) 이며 모든 `{` 사이에 `\` 가 끼어 인접 두 `{` 가 나타나지 않는다. 셋 다 regex 의 매칭 시도가 시작될 substring 자체가 input 에 없어 false positive 가 발생하지 않는다. 본 convention 은 operator 책임이며 script-side regex 는 본 first batch 에서 변경되지 않는다.

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
- `## Verdict` 외에 `## Findings`, `## Risks` (선택), `## Notes` (선택) section 을 자유롭게 둘 수 있다. shape 의 source-of-truth 는 `templates/review-result.md` 다.

verdict 는 commit / push / publish / merge / release / deployment 를 자동 승인하지 않는다. 사용자가 별도 명시 결정으로 처리한다.

yes / no / yes with risk
