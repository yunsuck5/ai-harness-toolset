# Plan conformance checklist — docs-working-model lifecycle

> 산출된 `<domain>_plan.md` 가 Plan 형틀·lifecycle 규칙을 따랐는지 점검한다. "있음/없음 + 한 줄 evidence".

- [ ] 필수 section 존재: Batch decomposition / Per-batch scope / Hard boundaries / Reference sweep requirement / Owner absorption proof requirement / Validation gate / Codex review gate / Approval boundary / Rollback-rewind / Readiness — evidence: ___
- [ ] 각 batch 가 4-class reference sweep + owner absorption proof + Codex review gate 를 요구함 — evidence: ___
- [ ] Design 일관성: Plan 이 Design hard decision 을 위반하지 않음(위반 시 rewind 표시) — evidence: ___
- [ ] Approval boundary(분류 ≠ mutation 승인; commit/push 별개) 명시 — evidence: ___
- [ ] 미치환 채움 표시 0 — evidence: ___
