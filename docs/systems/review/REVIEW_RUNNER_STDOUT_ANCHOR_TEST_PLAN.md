# 리뷰 시스템 — runner stdout exact-line-anchor test authoring discipline (planning/design doc, 2026-06-04)

> **Status (planning — not implemented) — 2026-06-04.** 이 문서는 runner stdout run-fact 의 **stdout contract test 작성 규율** — line-oriented run-fact 를 loose substring 이 아니라 exact-line anchor(`(?m)^key: value$`)로 검증한다 — 를 codify 하기 위한 **durable design/plan source-of-truth** 다. 작성 시점에 어떤 test / script / doc 도 이 규율을 위해 **수정되지 않았다**. 구현은 이 문서를 입력으로 삼는 **별도 scoped batch** 이며 각 단계마다 Codex review gate + 사용자 commit/push 승인을 거친다. 이 문서 작성 자체는 parser / verifier / runtime behavior 를 바꾸지 않고 기존 test 를 rewrite 하지 않는다.

## Document character

- **성격**: design/plan 문서. **implementation 아님 / test rewrite 아님 / operational claim 아님 / 승인 문서 아님.** "recommended" 는 구현 확정이 아니라 design 후보다.
- **track 위치 (중요)**: 이 작업은 Batch D 의 **non-mainline deferred/optional polishing 후보** "runner-stdout test exact-line-anchor discipline"(STATUS Batch D 마무리 항목에 등재)의 design home 이다. **RV-B-06(reviewer runtime provenance) 의 재오픈이 아니며**(RV-B-06 은 run-fact 를 *emit/persist* 하는 feature 이고, 본 트랙은 그 stdout 을 *test* 하는 방식의 규율이다 — feature/emission 불변), 직전 `## Known concerns` hypothesis-form 트랙(RV-B-05, review **input** 측)과도 독립이다(본 트랙은 runner **stdout/test** 측).
- **source of truth / 권위 순서**: run-fact emission 의 사실 근거는 `scripts/review-run.ps1` success-path 의 run-fact 출력이고, "H1 runner stdout run-fact" layer 의 개념 권위는 `docs/contracts/review/REVIEW_RESULT_CONTRACT.md` §6b.2 + `docs/systems/review/REVIEW_POLISHING_BATCH_D_SPEC.md` §2(세 home 분류: H1 runner stdout / H2 final report / H3 docs-only)다. 본 트랙은 그 H1 run-fact 를 검증하는 **test 작성 규율** 을 더하며, emission format / contract / parser 를 바꾸지 않는다. 충돌 시 contract 가 이긴다.
- **single-home-plus-pointers**: 이 문서는 STATUS/BACKLOG ledger 를 복제하지 않고 pointer 로만 참조한다(`docs/policies/DOCS_OPERATING_MODEL.md` §1/§3/§4).
- **placement / naming 근거**: 위치 `docs/systems/review/` 는 이 subsystem 의 track design/spec/plan 문서가 모이는 곳(`REVIEW_RESULT_PROVENANCE_SPEC.md` / `REVIEW_POLISHING_IMPLEMENTATION_PLAN.md` / `REVIEW_INPUT_KNOWN_CONCERNS_HYPOTHESIS_FORM_PLAN.md`; `docs/README.md` §5). 파일명은 그 docs 의 `REVIEW_<subject>_<KIND>` 패턴을 따른다.

## 1. 목적 (Purpose)

runner stdout 의 line-oriented run-fact(예: `reviewer:`, `reviewer-version:`, `model-source:`, `applied-effort:` …)를 검증하는 stdout contract test 가 **loose substring 매치에 의존하지 않도록** 하고, 가능한 한 **exact-line anchor**(`(?m)^key: value$`)로 검증하도록 하는 **authoring discipline 을 codify** 한다. 의도는 stdout contract 의 강도를 line 단위로 pin 하는 것이며, 기존 test 전체를 rewrite 하는 것도 parser/verifier/runtime 을 바꾸는 것도 아니다.

## 2. Track 위치 — Batch D deferred polishing, RV-B-06/RV-B-05 재오픈 아님

- Batch D mainline 은 closed("no D4"); 본 트랙은 그 마무리에서 **deferred/optional non-mainline polishing 후보** 로 명시된 "runner-stdout test exact-line-anchor discipline" 이다(`docs/systems/review/STATUS.md` Batch D 마무리 항목). 전용 RV-B backlog row 는 없다.
- **RV-B-06 재오픈 아님**: RV-B-06 은 `## Reviewer run provenance` run-fact 를 emit/persist 하는 feature 다. 본 트랙은 그 stdout run-fact 를 **어떻게 test 하느냐** 의 규율이며 emission/persistence/parser 를 건드리지 않는다.
- **`## Known concerns` 트랙과 독립**: 그 트랙은 review **input** 의 disclosure framing(RV-B-05)이고, 본 트랙은 runner **stdout/test** 다.

## 3. 현재 surface 분류 + 현재 assertion 방식

### surface 분류

- **Test surface(현재 assertion 위치)**: `tests/review-run.Tests.ps1`.
- **Emission source(context, 미변경)**: `scripts/review-run.ps1` success-path 는 여러 line-oriented `key: value` stdout 줄을 emit 한다. 그 중 **reviewer-guard / provenance run-fact 11 종** — `reviewer` / `reviewer-version` / `model` / `model-source` / `requested-effort` / `effort-source` / `applied-effort` / `reviewer-safe-posture` / `tool-root` / `project-root` / `tool-root-source` — 이 본 트랙이 가장 직접적으로 다루는 대상이다. success-path 는 이 외에도 `review-task-id` / `pass` / `verdict` / `pass-dir` / `result` / `provenance-persisted` 같은 다른 line-oriented status 줄도 emit 한다. 즉 "11" 은 전체 stdout 줄 수가 아니라 guard/provenance subset 이며, 본 규율(§5)은 이들 11 종을 포함한 **line-oriented run-fact / status 줄 일반**에 적용된다.
- **Testing-convention home(implementation 후보)**: `tests/README.md`.
- **Contract awareness(context, 미변경)**: `REVIEW_RESULT_CONTRACT.md` §6b.2 + `REVIEW_POLISHING_BATCH_D_SPEC.md` §2 — "H1 runner stdout run-fact" layer 를 인지하나 test 작성 방식을 규정하지 않는다.
- **Tracking**: `docs/systems/review/STATUS.md`(deferred 신호). `BACKLOG.md` — 전용 row 없음.
- **Home 아님**: `snippets/claude-skills/ai-harness-review/SKILL.md`(run-fact 를 operator report 로 surface 할 뿐 test 작성 규율 아님).

### 현재 assertion 방식 (`tests/review-run.Tests.ps1`)

- **Exact-line anchored(다수)**: `Should -Match '(?m)^key: value$'` — RV-B-06 P2/P3 및 Batch D2 run-fact AC(AC-RR21–28 계열 + provenance persistence 검증). 최근 사실상의 관행이며 본 규율의 모범이다.
- **Loose substring(소수, 잔존)**: effort run-fact AC(AC-RR13 / AC-RR14 / AC-RR16)의 `Should -Match 'applied-effort: xhigh'` 류 — anchor 없는 부분 문자열 매치.
- 다른 test 파일에는 stdout run-fact assertion 이 없다 → scope 는 review-run 으로 contained.

## 4. exact-line anchor 가 필요한 이유

loose substring 매치는 line-oriented run-fact contract 를 약화시킨다.

- **결정적 예 (applied-effort 의 3 변형)**: `scripts/review-run.ps1` 는 `applied-effort` 를 세 형태로 emit 한다 — `applied-effort: not-observed`, `applied-effort: <v> (WARNING: differs from requested <r>)`, 그리고 평문 `applied-effort: <v>`. loose `Should -Match 'applied-effort: xhigh'` 는 **WARNING 변형(`applied-effort: xhigh (WARNING: ...)`)도 통과**시켜 clean run-fact 와 degraded run-fact 를 구별하지 못한다. exact-line `(?m)^applied-effort: xhigh$` 만이 그 run-fact 가 자기 한 줄 전체로 정확히 그 값임을 pin 한다.
- **prefix 충돌 취약성**: run-fact key 가 늘어날수록 loose 부분 매치는 인접 key prefix(예: 가상의 `requested-applied-effort: xhigh`)나 prose 안 substring 에도 우연히 통과할 수 있다.
- **회귀 방지**: 규율을 명문화하면 run-fact 가 추가될 때 신규 test 가 loose 매치로 회귀하는 것을 막는다(최근 AC 들은 이미 anchored 이지만 규율로 기록돼 있지 않다).

## 5. Recommended scope

`tests/README.md` 에 **stdout run-fact test authoring discipline** 를 명문화한다(authoring convention, docs):

- **(a) 규율**: runner stdout 의 line-oriented run-fact 를 검증하는 신규 stdout contract test 는 loose substring 이 아니라 **exact-line anchor** `(?m)^key: value$` 로 검증한다.
- **(b) 적용 범위 한정**: 본 규율은 *line-oriented run-fact*(한 줄 = 하나의 `key: value` fact)에 적용된다. error message / argv 부분 문자열(예: `model_reasoning_effort=xhigh`) / 비-run-fact 진단 문자열에는 exact-line anchor 가 적절하지 않을 수 있으며 강제하지 않는다.
- **(c) 변형이 있는 run-fact 주의**: `applied-effort` 처럼 변형(not-observed / WARNING / 평문)이 있는 run-fact 는 exact-line anchor 로 의도한 변형을 정확히 pin 한다(§4).
- **(d) no mass-rewrite**: 기존 loose assertion(AC-RR13/14/16)을 **대규모 rewrite 하지 않는다.** 이는 신규 test 작성 규율이며, 기존 loose case 의 선택적 tightening 은 별도의 작은 cleanup(본 scope 밖)이다.
- **(e) docs/convention only**: parser / verifier / runtime behavior / run-fact emission format 을 바꾸지 않는다.

선택적으로 `tests/review-run.Tests.ps1` 의 run-fact assertion 블록 근처에 짧은 pointer 주석을 둘 수 있으나, 주 home 은 `tests/README.md` 다.

## 6. Expected implementation surfaces

구현 batch(별도 scoped /goal)에서 수정할 후보 — **이번 작업에서는 수정하지 않는다**:

- `tests/README.md` — "stdout run-fact test authoring discipline" 소절 추가(주 surface).
- (선택) `tests/review-run.Tests.ps1` — run-fact assertion 블록 근처 짧은 pointer 주석.

조건부(구현 closeout 시점, core 와 분리): `docs/systems/review/STATUS.md` deferred 신호 처리(deferred→done) + 이 문서로의 inbound pointer.

## 7. Scope exclusions

- 기존 loose assertion(AC-RR13/14/16) **대규모 rewrite**(선택적 tightening 은 별도/제외).
- parser / verifier / runtime behavior 변경, run-fact **emission format**(`scripts/review-run.ps1`) 변경.
- repo-wide test cleanup(다른 test 파일의 매치 습관).
- RV-B-06 reopen, EOL normalization, global/user file·memory·shell·git config 변경, snapshot/manifest 생성, commit/push.

## 8. Validation & review plan

구현 batch 시점(이번 planning 단계 미실행):

- `git diff --check`(whitespace/EOL). `.md` EOL 미변경. 신규 `.ps1` 없음.
- review-system Pester(`tests/*.Tests.ps1`) — `tests/README.md` 만 바뀌면 무영향이나 guard 로 실행. (만약 선택적 loose tightening 을 포함하면 `review-run.Tests.ps1` 재실행으로 tightened assertion 통과 확인.)
- anti-pattern sweep(첫 re-review 전): convention 진술 일관성 + "기존 loose test 를 rewrite 하지 않았다"는 진술이 실제 diff 와 일치하는지 확인.
- Codex reviewer gate: review-system self-modification(review-system docs/tests) 이므로 **global stable ToolRoot engine**. finding → approved scope 내 수정 → corrected-state re-review.

## 9. 직전 inline proposal 과의 관계

이 트랙의 scope 는 본 문서 작성 *이전에* 대화 안의 **inline plan proposal** 로 사용자에게 제시되어 durable doc 작성 승인을 받았다. 그 inline proposal 은 runtime/대화 산출물이며 **durable source-of-truth 가 아니다** — 이 문서가 durable planning source 이고, **이 문서 자체가 corrected working tree 기준 Codex review 를 받는다**(inline proposal 은 그 review 를 대체하지 않는다). 이 문서의 권위는 그 대화 proposal 의 존재에 의존하지 않는다.

---

*이 문서는 open track 의 design/plan 이다. 구현·리뷰·commit/push 는 각각 별도 사용자 승인이 필요한 후속 단계다.*
