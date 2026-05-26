# Review Input

이 파일은 `log/review/<review-task-id>/pass-NN/input.md` 의 형식 기준이다. Claude Code (operator-role AI) 가 본 template 을 기반으로 한 pass directory 의 `input.md` 본문을 직접 작성한다. Codex reviewer 는 결과로 같은 pass directory 의 `result.md` 한 파일만 생성한다.

`<review-task-id>` 는 하나의 Claude Code `/goal` 작업 또는 하나의 review gate 단위다. Claude Code chat / session id 가 아니다. 한 세션 안에서 서로 다른 주제의 `/goal` 이 여러 개 진행되면 각각 별도의 `<review-task-id>` 디렉터리를 사용한다. `pass-NN` (예: `pass-01`, `pass-02`) 는 같은 review task 안에서의 corrective loop 의 각 Codex review attempt 다. 각 pass directory 는 write-once 다 — input / result 가 stale 또는 부적절하면 새 pass 를 만들고, 기존 pass 의 파일을 손으로 보정해 review 를 닫지 않는다.

본 template 의 `{{AI_TO_FILL_*}}` placeholder 는 모두 AI 가 실제 내용으로 교체해야 한다. unfilled placeholder 가 남아 있으면 `scripts/review-input-verify.ps1` 의 `\{\{[A-Za-z_][A-Za-z0-9_]*\}\}` regex 가 거부한다.

informational sections (`## Stage` / `## Purpose` / `## Target files` / `## Validation evidence`) 는 `scripts/review-input-verify.ps1` 의 strict shape gate 대상이 아니지만 reviewer 가 본문을 읽는다. validation execution claim (예: Pester pass count, `verify-ps1` PASS, `git diff --check` clean) 이 있는 round 에서는 `## Validation evidence` 본문에 그 근거 Markdown evidence 의 path (예: `log/evidence/<scope>/<case>/validation-evidence.md`) 를 적어 reviewer 가 read-only inspect 할 수 있도록 한다. claim 자체가 부적용인 round 에서는 `N/A — no validation execution claims in this round.` 같은 짧은 명시를 본문에 둔다. 의미와 boundary 는 `docs/contracts/review/REVIEW_RESULT_CONTRACT.md` §3a 가 source-of-truth.

## Stage

{{AI_TO_FILL_STAGE}}

## Purpose

{{AI_TO_FILL_PURPOSE}}

## Target files

{{AI_TO_FILL_TARGET_FILES}}

## Validation evidence

{{AI_TO_FILL_VALIDATION_EVIDENCE}}

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
