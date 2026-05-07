# Review Input

- Run ID: {{RUN_ID}}
- Target path: {{TARGET_PATH}}
- Target SHA-256: {{TARGET_SHA256}}
- Stage: {{STAGE}}
- Purpose: {{PURPOSE}}
- Reviewer: {{REVIEWER}}
- Source HEAD: {{SOURCE_HEAD}}
- Reviewer model: {{REVIEWER_MODEL}}
- Reasoning effort: {{REASONING_EFFORT}}

## Context

(Replace this placeholder with review context.)

## Required inspection paths

(Replace this placeholder with paths the reviewer must inspect.)

## Review questions

(Replace this placeholder with review questions.)

## Constraints

(Replace this placeholder with explicit constraints.)

## Final verdict

yes / no / yes with risk

Do not approve commit, push, publish, merge, release, or deployment unless explicitly scoped.

### Required result.md output contract

Your final response is captured by Codex `--output-last-message` and saved as `result.md` in the review run directory. The `review-cycle` parser is strict about this file. Follow this contract exactly so automatic parsing succeeds.

- The output must contain exactly one top-level `## Verdict` heading. Do not use `## Final verdict`, `### Verdict`, or any other heading variant. Zero or multiple `## Verdict` headings cause parsing to fail.
- The first non-empty line after the `## Verdict` heading must be exactly one of these three values, written in lowercase:
  - yes
  - no
  - yes with risk
- Do not use inline forms such as `Verdict: yes`, `Final verdict: yes`, or prose-only verdicts. The parser rejects them.
- Do not add adjectives, qualifiers, punctuation, or trailing text on the verdict line itself.

If the result.md shape is invalid, `review-cycle` fails and `result.json` is not produced automatically. A human can complete the review record by manual fallback (edit `result.md` to match this contract, then run `review-verify -RequireResult` directly), but you should produce a contract-compliant `result.md` so manual fallback is unnecessary.
