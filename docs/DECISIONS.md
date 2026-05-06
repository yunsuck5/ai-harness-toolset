# Decisions

## Bootstrap and historical decisions

- repo name: ai-harness-toolset
- remote created
- local clone created
- branch: main
- previous v0.1 seed attempt discarded
- ai-harness.zip is the initial migration source only
- legacy knowledge transfer must be explicit
- `.gitattributes` policy migrated from legacy ai-harness
- PowerShell encoding/codepage rules migrated as policy
- reviewer config externalized into `config/reviewer.json`
- no Claude Code project init
- no Codex project init
- v2 bootstrap packet remains archival/reference

## Active policy decisions

- new human-facing docs are Korean by default (technical identifiers stay English)
- evidence capture is a manual convention first (`docs/EVIDENCE_CONTRACT.md`) — no script, wrapper, or schema enforcement in MVP
- chatlog retention is summary-first and resume-first (`docs/CHATLOG_CONTRACT.md`)
- raw transcript retention is optional
- handoff.md is an external Web/session handoff artifact, not a repo source artifact
- context-pressure trigger / pre-compact capture is a future optional candidate, not MVP implementation
- review result artifacts are manual convention first (`docs/REVIEW_RESULT_CONTRACT.md`)
- completed review records use `result.md` plus `result.json`; missing result artifacts are not a default `review-verify` failure in MVP
- review-verify gains an optional `-RequireResult` mode for completed review records; default mode behavior, messages, and exit codes remain unchanged
- `review-verify -RequireResult` now performs completed-record binding beyond SHA-256: normalized `targetPath` match, `createdAtUtc` exact `yyyy-MM-ddTHH:mm:ss.fffffffZ` shape with ASCII-digit-only policy and parseable UTC offset, and conditional `sourceHead` exact match when both meta and result `sourceHead` are non-empty
- broader review result policies remain future candidates: full JSON schema validation, `createdAtUtc` wall-clock / ordering checks, unconditional `sourceHead` requirement, `review-run` wrapper, and CI integration
- minimal Pester regression tests now cover `review-verify` default and `-RequireResult` paths; broader CI integration and wrapper-driven gates remain future candidates
- 첫 real target adoption은 payload 적용, log-init, review-prepare / review-verify default-mode dry run, stale detection, restore PASS, legacy workflow cleanup, source untouched 검증을 통과해도 adoption smoke test로만 분류한다
- reviewer가 input.md를 읽고 `result.md` / `result.json`을 작성하지 않았다면 actual reviewer workflow test가 아니다
- 실제 개발 변경 1건을 review / evidence / chatlog 반복 cycle로 처리하지 않았다면 actual development workflow usage test가 아니다
- actual reviewer workflow test와 actual development workflow usage test는 separate future milestones로 둔다
