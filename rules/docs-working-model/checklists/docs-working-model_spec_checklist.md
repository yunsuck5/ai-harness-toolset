# Spec conformance checklist — docs-working-model lifecycle

> 산출된 `<domain>_spec.md` 가 Spec 형틀·lifecycle 규칙을 따랐는지 점검한다. "있음/없음 + 한 줄 evidence".

- [ ] 필수 section 존재: Scope / Candidate files / Owner absorption proof / 4-class reference sweep / Allowed-forbidden / Validation commands / Codex review gate / Rollback-rewind / Approval boundary / Reconstructibility — evidence: ___
- [ ] Candidate files 가 create / move / delete / modify / validate-only / not-touched 로 분류됨 — evidence: ___
- [ ] Validation 이 로컬 실행 가능한 것만이고, reference sweep before/after 수치 검증을 포함함 — evidence: ___
- [ ] Plan 일관성: Spec 이 Plan batch boundary 를 위반하지 않음(위반 시 rewind 표시) — evidence: ___
- [ ] stable filename 규약 준수: domain docs 는 `<domain>_design.md` / `_plan.md` / `_spec.md`(domain-prefixed role filename)이며, package-local 형틀명(`_template` / `_checklist`)과 혼동되지 않음 — evidence: ___
- [ ] 미치환 채움 표시 0 — evidence: ___
