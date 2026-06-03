# 리뷰 입력 거버넌스 — `## Known concerns` hypothesis-form convention (planning/design doc, 2026-06-04)

> **Status (planning — not implemented) — 2026-06-04.** 이 문서는 review-input 의 `## Known concerns` informational section 을 *확정 결함처럼* 쓰지 않고 *confirmed disclosures* 와 *open concerns / hypotheses to verify* 로 구분하는 convention 의 **durable design/plan source-of-truth** 다. 작성 시점에 어떤 implementation surface(`templates/review-input.md` / `snippets/claude-skills/ai-harness-review/SKILL.md` / `docs/contracts/review/REVIEW_RESULT_CONTRACT.md`)도 **아직 수정되지 않았다**. 구현은 이 문서를 입력으로 삼는 **별도 scoped batch** 이며, 각 단계마다 별도 Codex review gate + 사용자 commit/push 승인을 거친다. 이 문서 작성 자체는 source/script/test/config/contract/template/verifier/skill 변경을 동반하지 않는다.

## Document character

- **성격**: design/plan 문서. **implementation 아님 / operational claim 아님 / 승인 문서 아님.** 이 문서의 어떤 분석도 implementation surface 변경을 수행하거나 commit/push 를 승인하지 않는다. "권장(recommended)" 은 구현 확정이 아니라 design 후보다.
- **track 위치 (중요)**: 이 작업은 review subsystem 의 **RV-B-05 ("Review input governance")** 우산 아래의 **deferred polishing item** 이다 — **RV-B-06 (reviewer runtime provenance) 의 재오픈이 아니다.** 근거는 §2.
- **source of truth / 권위 순서**: 상위 권위는 `docs/contracts/review/REVIEW_RESULT_CONTRACT.md`(특히 §2 input.md informational sections, §5 AI responsibility, §7 stale-by-omission, §10 non-goals)이며, 그 다음이 `templates/review-input.md` 와 `snippets/claude-skills/ai-harness-review/SKILL.md` 의 operator-facing wording 이다. 충돌 시 contract 가 이긴다. 이 문서는 그 위에 얹히는 **track design home** 이며, contract/template/skill 의 의미를 재정의하지 않는다.
- **single-home-plus-pointers (docs operating model 준수)**: 이 문서는 `docs/systems/review/STATUS.md`(completed/deferred ledger)·`docs/systems/review/BACKLOG.md`(RV-B-05 triage row) 의 내용을 **복제하지 않는다**. 그 두 곳의 ledger/triage 항목은 pointer 로만 참조하고, 이 문서는 *design/plan* 만 담는다 (`docs/policies/DOCS_OPERATING_MODEL.md` §1 single-home, §3 layer roles, §4 STATUS altitude).
- **placement / naming 근거**: 위치 `docs/systems/review/` 는 이 subsystem 의 track design/spec/plan 문서가 모이는 곳이다(예: `REVIEW_RESULT_PROVENANCE_SPEC.md`, `REVIEW_POLISHING_IMPLEMENTATION_PLAN.md`, `REVIEW_POLISHING_BATCH_*_SPEC.md`; `docs/README.md` §5 `docs/systems/` 레이어). 파일명은 그 docs 의 `REVIEW_<subject>_<KIND>` 패턴을 따른다 — `INPUT` 은 review **입력** 측 거버넌스임을 `RESULT`(provenance) 측과 대비시키고, `_PLAN` 은 본 문서의 planning 성격을 나타낸다.

## 1. 목적 (Purpose)

1. `input.md` 의 `## Known concerns` informational section 이 **확정된 결함(confirmed defect)처럼 작성되어 confirmation-oriented review input 이 되는 것을 방지**한다. operator 가 *미확정 의심(open suspicion)* 을 가졌을 때 그것을 확정 사실처럼 적으면, reviewer 는 그 항목을 *독립적으로 평가할 가설* 이 아니라 *확인할 finding* 으로 읽게 되어 review 의 독립성이 약해진다.
2. `## Known concerns` 안에서 **confirmed disclosures** 와 **open concerns / hypotheses to verify** 를 명시적으로 **구분하는 convention** 을 정한다 — 전자는 사실로 기재(disclosure duty 유지), 후자는 `verify whether…` / `check whether…` 같은 중립 검증 표현으로 기재.

이 convention 은 이미 존재하는 `## Review questions` 의 neutral-phrasing + framing-tilt self-audit convention(`templates/review-input.md` 의 `## Review questions` guidance; SKILL step 4)과 **평행 구조** 이며, 그 입력-측 비대칭(§4 참조)을 메운다.

## 2. Track 위치 — RV-B-05 우산, RV-B-06 재오픈 아님

- 이 작업은 **RV-B-05 "Review input governance"** 의 open residual scope 에 속한다: `docs/systems/review/BACKLOG.md` 의 RV-B-05 row 는 "reviewer-side disclosure shape + operator-side honest-framing conventions" 와 "leading-question / framing-tilt / `## Known concerns` sub-shape" 계열 신호를 그 우산으로 명시한다.
- `docs/systems/review/STATUS.md` 의 Batch D 마무리 항목은 "review-input framing-tilt / hypothesis-form `## Known concerns` convention" 을 **non-mainline deferred/optional polishing 후보** 로 명시한다 (이 문서가 그 deferred 신호의 design home 이다).
- **RV-B-06 (reviewer runtime provenance) 와 명시적으로 분리**: `docs/systems/review/REVIEW_RESULT_PROVENANCE_SPEC.md` 의 non-goal 항목(N4)은 "`## Known concerns` framing-tilt convention" 을 그 트랙의 scope 에 **섞지 않는** 별도 독립 deferred 후보로 못박는다. 따라서 이 batch 는 **RV-B-06 을 재오픈하지 않으며**, RV-B-06 의 산출물(result.md dual-authorship / provenance block / parser gate)을 변경하지 않는다.

## 3. 현재 surface 분류

`## Known concerns` 또는 그 guidance 가 실제로 존재하는 surface 를 역할별로 분류한다.

- **Active convention homes** (이 convention 이 정의되는 곳 — 구현 batch 의 변경 대상):
  - `templates/review-input.md` — `## Known concerns` informational section 의 fill 위치 + 그 guidance prose.
  - `snippets/claude-skills/ai-harness-review/SKILL.md` — step 4 의 `## Known concerns` 설명 bullet (deployed self-contained surface).
  - `docs/contracts/review/REVIEW_RESULT_CONTRACT.md` — §2 의 section 정의(이것이 **source-of-truth**); §5/§7 은 disclosure duty / stale-by-omission; §10 은 sub-shape lint non-goal.
- **Mirror / managed-block guard surfaces** (Tier-D 최소 guard; 기본 미변경 — §7):
  - `snippets/CLAUDE_SNIPPET.md` / `snippets/AGENTS_SNIPPET.md` — 글로벌 payload 의 managed-block guard. disclosure duty 의 최소 mirror 만 담으며, 상세 convention 은 contract 가 소유한다(contract §5a precedence).
- **Tracking surfaces** (가이던스 홈 아님; 구현/closeout 시점에만 갱신):
  - `docs/systems/review/STATUS.md` — deferred 신호 anchor(+ 구현 시 completed ledger 로 이관 여부 결정).
  - `docs/systems/review/BACKLOG.md` — RV-B-05 triage row(우산).
- **Historical / closed / out-of-scope surfaces** (편집 금지):
  - `templates/review-result.md` — `## Known concerns` 를 *result-측 sub-shape lint 예시* 로만 언급(input convention 아님).
  - `docs/systems/review/REVIEW_RESULT_PROVENANCE_SPEC.md` — closed RV-B-06 spec(N4 가 이 트랙을 분리).
  - `docs/systems/review/REVIEW_POLISHING_IMPLEMENTATION_PLAN.md` / `REVIEW_POLISHING_DECISION_RECORD.md` — historical design/decision 기록.

> 줄번호는 brittle 하므로 이 문서는 surface 를 **파일 + 섹션/역할** 로만 가리킨다(과거 한 spec 이 "STATUS line N" 으로 가리켰다가 stale 된 전례 회피).

## 4. 현재 wording 문제

세 active home 은 `## Known concerns` 를 동일하게 정의한다 — operator 가 호출 전 **이미 인지한** compromise / convention deviation / skipped alternative / baseline failure / validation limitation / operator assumption 을 사전 disclose 하는 자리.

- **confirmed disclosure 자체는 유지되어야 한다**: 위 6 sub-category 는 진짜 *확정된* operator 결정/한계다. 이것을 사실로 기재하는 것은 옳고, **stale-by-omission 규칙(contract §7)이 바로 이 confirmed disclosure 에 의존**한다(operator 가 알면서 누락한 known compromise 의 사후 발견 → verdict 의 commit-fitness 무효화). 따라서 이 층의 "이미 인지한" framing 은 **약화하면 안 된다**.
- **open suspicion 을 확정된 known concern 처럼 적게 되는 문제**: 현재 section 에는 *미확정 의심* 을 담을 자리/형태가 없다. suspicion 을 가진 operator 는 "known concern" mold 만 가지고 있어 의심을 확정 사실처럼 기재하게 되고, 그 결과 input 이 confirmation-oriented 가 된다(목적 §1).
- **`## Review questions` neutral framing 과의 asymmetry**: `## Review questions` 는 이미 "confirmation-seeking 대신 open-ended" + framing-tilt self-audit 라는 중립-framing convention 을 가진다. `## Known concerns` 에는 그 평행 guidance 가 없다 — 이 비대칭이 본 batch 가 메우려는 gap 이다.

## 5. Recommended scope — `reframe-without-rename`

`## Known concerns` **heading 을 유지**한 채, 세 active home 에 **additive** 하게 다음을 도입한다:

- **(a) two-kind 구분**: 이 section 이 두 종류를 담음을 명시한다.
  - **confirmed disclosures** — 기존 6 sub-category. 사실로 기재하며 stale-by-omission(contract §7)이 전면 적용된다.
  - **open concerns / hypotheses to verify** — operator 가 확신하지 못하는 의심. `verify whether…` / `check whether…` 같은 중립 검증 표현으로 기재해, reviewer 가 추정-결함을 confirm 하지 않고 독립적으로 평가하도록 한다.
- **(b) guard 문장 (필수)**: 진짜 known compromise / limitation 은 **여전히 confirmed disclosure 로 기재**해야 하며 hypothesis 로 위장(완화)해서는 안 된다. 이 guard 가 없으면 two-kind 구분이 stale-by-omission disclosure duty 를 약화시켜, operator 가 실제 known compromise 를 "hypothesis: maybe X" 로 숨길 여지를 만든다.
- **(c) heading rename 배제**: `## Known concerns` → `## Known concerns / hypotheses to verify` 같은 **heading rename 은 하지 않는다**. 이유: 이 section 은 informational(parser-gated 아님 — `scripts/review-input-verify.ps1` 의 required heading set 에 미포함)이라 개념을 본문 prose 로 전달할 수 있고, heading rename 은 모든 mirror surface 로 cascade 하여 최소 batch 원칙과 충돌한다. (rename 은 의도적으로 배제된 대안으로 기록한다.)

contract §5/§7 의 stale-by-omission wording 과 §10 의 "no `## Known concerns` sub-shape lint" non-goal 은 **불변**으로 유지한다 — 이 convention 은 parser/lint 가 아니라 wording/guidance 다.

## 6. Expected implementation surfaces

구현 batch(별도 scoped /goal)에서 수정할 후보 surface — **이번 작업에서는 수정하지 않는다**:

- `templates/review-input.md` — `## Known concerns` guidance 에 §5 (a)/(b) 도입.
- `snippets/claude-skills/ai-harness-review/SKILL.md` — step 4 의 `## Known concerns` bullet 에 동일 내용을 간결히 mirror(deployed self-contained surface).
- `docs/contracts/review/REVIEW_RESULT_CONTRACT.md` — §2 의 section 정의에 §5 (a)/(b) clause 추가(source-of-truth).

조건부(구현 closeout 시점, 위 core 와 분리): `docs/systems/review/STATUS.md` 의 deferred 신호 처리 — §8 의 closeout 항목 참조.

## 7. Scope exclusions

이 planning, 그리고 그것을 따르는 구현 batch 모두에서 다음을 **하지 않는다**:

- **parser / lint / verifier / automation 추가 금지** — `scripts/review-input-verify.ps1` / `scripts/review-verify.ps1` 등 어떤 deterministic gate 도 추가하지 않는다(contract §10 non-goal 재확인). 이 convention 은 wording-only 다.
- **`## Known concerns` heading rename 금지** (§5 (c)).
- **`snippets/CLAUDE_SNIPPET.md` / `AGENTS_SNIPPET.md` 미변경(기본)** — deployed 글로벌 managed-block guard 이며 disclosure duty 의 최소 mirror 만 담는다(상세는 contract 소유, §5a precedence). 만약 구현 batch 가 이 mirror 를 **의도적으로 미변경으로 둔다면**, 그 결정을 구현 batch 의 review `input.md` `## Known concerns` 에 **deliberate mirror asymmetry 로 명시 disclose** 한다(§8).
- **RV-B-06 재오픈 금지** (§2).
- **EOL normalization 금지** — `.md` blob EOL convention(`.gitattributes` `eol=lf` vs 커밋된 CRLF)은 이 batch 의 scope 가 아니다.
- **global / user file 수정 금지**, **snapshot / manifest 생성 금지**, **commit / push 금지** — 모두 별도 사용자 명시 승인 사항.
- **verdict vocabulary / stale-by-omission semantics 변경 금지**, 기존 `## Review questions` neutral convention 재오픈 금지.

## 8. Validation & review plan

구현 batch 시점에 수행할 계획(이번 planning 단계에서는 미실행):

- **Pester suite** (`tests/*.Tests.ps1`) 실행 — 이 convention 은 script 무변경이라 regression 0 예상이나, guard 로 전수 실행.
- **`scripts/review-input-verify.ps1`** 를 template-derived sample input 에 실행 — required heading set 불변 + `## Known concerns` informational 이므로 PASS 예상.
- **`git diff --check`** (whitespace/EOL). `.md` EOL 은 건드리지 않는다. 신규 `.ps1` 없음(BOM+CRLF 규칙 무관).
- **anti-pattern grep sweep (첫 implementation re-review *전*)**: 모든 active home 에서 옛 framing("이미 인지한" / "already know about" / 6-category 문구)을 grep 해 일괄 갱신 + sibling residual 0 을 확인한다(wording-reconciliation 은 한 곳만 고치고 re-review 하면 cascade 를 부른다).
- **Codex reviewer gate**: 구현 batch 는 review-system self-modification(template/skill/contract = review machinery)이므로 **global stable ToolRoot engine** 으로 Codex review 를 돌린다(reviewer-engine independence). finding → approved scope 내 수정 → corrected-state re-review.
- **closeout 처리(구현 batch 의 일부, 이 core 와 분리)**: 구현이 끝나면 `docs/systems/review/STATUS.md` 의 deferred 신호를 **deferred→completed ledger 로 이관할지 명시 결정**한다 — 구현 후에도 deferred 로 남겨두면 stale tracking 이 되므로, 이관하거나(권장) 또는 의도적으로 deferred 유지 시 그 이유를 disclose 한다(DOCS_OPERATING_MODEL §7 two-level closeout gate). 이 문서로의 inbound pointer(STATUS → 이 plan)도 그 시점에 함께 wiring 한다.

## 9. 직전 planning review 결과 반영 (supporting evidence — non-durable)

이 design 의 scope 는 본 문서 작성 *이전에* 한 차례 design-altitude 에서 Codex review 를 받았고 `yes`(blocking finding 없음)로 닫혔다. 그 review 의 대상은 **inline planning draft** 였고, 그 artifact 는 **gitignored `log/` runtime tree 안에만** 존재한다(runtime review record). 따라서:

- 그것은 **runtime 보조 증거(non-durable)** 일 뿐, durable source-of-truth 가 아니다. **이 문서의 권위는 그 runtime artifact 의 존재에 의존하지 않는다** — 그 artifact 가 사라져도 이 문서는 그대로 유효하다(durable provenance 는 이 문서 + git history 다).
- 그 review 는 `log/` inline planning 을 대상으로 한 것이므로, **이 새 `docs/` planning 문서에 대한 Codex review 를 대체하지 않는다.** 이 문서는 commit-candidate working tree 위에서 자기 자신의 Codex review 를 받는다.
- 그 직전 review 가 남긴 **비차단(non-blocking) concern 3 개** 는 이 문서에 반영되었다:
  1. **STATUS deferred tracking closeout 처리** — §8 closeout 항목에 반영(구현 후 deferred→completed 이관 여부를 명시 결정; 미이관 시 stale tracking).
  2. **confirmed disclosure 를 hypothesis 로 완화하지 말라는 guard** — §5 (b) 의 필수 guard 문장으로 반영.
  3. **snippets 미변경 시 mirror asymmetry disclosure** — §7 에 반영(구현 batch 가 snippets 를 미변경으로 두면 그 결정을 구현 review input 에 deliberate asymmetry 로 disclose).

---

*이 문서는 open track 의 design/plan 이다. 구현·리뷰·commit/push 는 각각 별도 사용자 승인이 필요한 후속 단계다.*
