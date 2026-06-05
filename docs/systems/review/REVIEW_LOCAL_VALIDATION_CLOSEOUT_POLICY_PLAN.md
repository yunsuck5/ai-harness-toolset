# 리뷰 시스템 — local validation closeout policy: validation scope by change class (planning/design doc, 2026-06-04)

> **Status (implemented — done) — 구현 commit `94f375c`(작성 plan-doc commit `028f8dc`).** 이 문서가 정한 local validation closeout scope(change class 별 closeout validation obligation; "full suite 항상 green" 무조건 요구 아님)은 **구현됐다** — `docs/contracts/review/REVIEW_RESULT_CONTRACT.md` §6c + `tests/README.md` + `templates/review-input.md` + `snippets/claude-skills/ai-harness-review/SKILL.md` 에 반영(현 상태 source-of-truth: `docs/systems/review/STATUS.md` governance increments bullet). 본 문서는 그 정책의 **durable design source-of-truth** 로 보존된다. 아래 본문의 plan-time 표현(예: "Status (planning — not implemented)", "아직 수정되지 않았다", deferred 신호, "STATUS 는 이것을 deferred 후보로 명시한다", 조건부-closeout)은 **작성 시점 design-time 기록**이며 current-state claim 이 아니다 — 현재 상태는 위 STATUS bullet 이 권위다.

## Document character

- **성격**: design/plan 문서. **implementation 아님 / parser·verifier·runtime 변경 아님 / operational claim 아님 / 승인 문서 아님.** 이 문서의 어떤 분석도 implementation surface 변경을 수행하거나 commit/push 를 승인하지 않는다. "권장(recommended)" / "expected" 은 구현 확정이 아니라 design 후보이자 operator discipline 의 기대치다.
- **track 위치 (중요)**: 이 작업은 직전 `validation evidence / reviewer reproduction opt-in policy` 트랙(`docs/systems/review/REVIEW_VALIDATION_EVIDENCE_REPRODUCTION_POLICY_PLAN.md`, 구현 `fdb9fe1`, contract §3d)이 §2·§10 에서 명시적으로 **별도 정책으로 분리한** "full-suite-green closeout policy" 그 트랙이다. 그 정책은 **reviewer 의 reproduction 경계**(reviewer 가 sandbox 에서 무엇을 재실행하는가)를 다루었고, 본 트랙은 그 반대편 — **local operator 의 validation obligation**(operator 가 closeout 전에 무엇을 직접 실행하는가)을 다룬다. 두 트랙은 짝(operator-side ↔ reviewer-side)이며 섞이지 않는다(§10).
- **source of truth / 권위 순서**: 상위 권위는 `docs/contracts/review/REVIEW_RESULT_CONTRACT.md`(특히 §3a Markdown validation evidence convention, §3d reviewer reproduction opt-in, §6b Operator final report schema — 특히 field 8 validation evidence)와 `docs/contracts/evidence/EVIDENCE_CONTRACT.md`(evidence file 본문 shape 의 권위)다. testing convention 의 권위 home 은 `tests/README.md` 다. 충돌 시 contract 가 이긴다. 이 문서는 그 위에 얹히는 **track design home** 이며, 기존 contract/evidence/test convention 의 의미를 재정의하지 않고 **명시되지 않은 boundary(change class 별 closeout validation obligation)를 추가로 codify** 할 설계를 담는다.
- **single-home-plus-pointers (docs operating model 준수)**: 이 문서는 `docs/systems/review/STATUS.md`(completed/deferred ledger)·`docs/systems/review/BACKLOG.md`(triage row)·`tests/README.md`(testing convention)의 내용을 **복제하지 않는다**. 그 위치의 ledger/triage/convention 항목은 pointer 로만 참조하고, 이 문서는 *design/plan* 만 담는다(`docs/policies/DOCS_OPERATING_MODEL.md` §1 single-home, §3 layer roles, §4 STATUS altitude).
- **placement / naming 근거**: 위치 `docs/systems/review/` 는 이 subsystem 의 track design/spec/plan 문서가 모이는 곳이다(`REVIEW_RESULT_PROVENANCE_SPEC.md` / `REVIEW_POLISHING_IMPLEMENTATION_PLAN.md` / `REVIEW_INPUT_KNOWN_CONCERNS_HYPOTHESIS_FORM_PLAN.md` / `REVIEW_RUNNER_STDOUT_ANCHOR_TEST_PLAN.md` / `REVIEW_VALIDATION_EVIDENCE_REPRODUCTION_POLICY_PLAN.md`; `docs/README.md` §5 `docs/systems/` 레이어, §6 신규 문서 위치). 파일명은 그 docs 의 `REVIEW_<subject>_<KIND>` 패턴을 따른다 — `LOCAL_VALIDATION_CLOSEOUT_POLICY` + `_PLAN`. **`LOCAL` 과 `CLOSEOUT` 토큰이 직전 트랙의 `VALIDATION_EVIDENCE_REPRODUCTION`(reviewer-side reproduction)과 본 트랙(operator-side local closeout)을 파일명 차원에서 구분** 해 §10 의 혼입 금지를 이름으로 강화한다. 대안 `REVIEW_VALIDATION_SCOPE_BY_CHANGE_CLASS_PLAN.md` 도 고려했으나, 정책의 anchor 가 "closeout 전 operator 가 무엇을 돌리는가" 이고 reviewer-reproduction 트랙과의 대비(closeout obligation vs reproduction boundary)가 핵심이므로 `CLOSEOUT_POLICY` 를 파일명에 두는 쪽을 택했다(사용자 권장 후보와 일치).

## 1. 목적 (Purpose)

1. **closeout 전 local validation scope 를 change class 별로 정한다.** 한 작업(batch)을 닫기 전에 operator 가 자기 local 환경에서 수행할 validation 의 *범위* 는 변경의 성격(docs-only wording, runtime behavior, parser gate, test code 등)에 따라 다르다. 본 정책은 그 매핑을 durable 하게 codify 한다.
2. **"full suite green" 을 무조건 요구하지 않고, 언제 필요한지를 정의한다.** 모든 변경에 전체 Pester suite green 을 의무화하면 docs-only wording 변경 같은 저위험 작업에 과도한 비용을 부과하고, 반대로 아무 validation 없이 closeout 하면 runtime/gate 변경의 regression 을 놓친다. 본 정책은 그 사이에서 *change class 별 기대치* 를 명시한다.
3. **full suite 를 돌리지 않은 경우의 정직한 보고 규약을 정한다.** "full suite not run" 자체는 결함이 아니다 — 단, operator 는 change class · 수행한 validation · 수행하지 않은 validation · 미수행 이유 · (있다면) 잔여 위험을 보고해야 한다. 이는 `REVIEW_RESULT_CONTRACT.md` §6b operator final report(field 8 validation evidence)와 정합한다.

이 정책은 reviewer 가 무엇을 재실행하는가(§3d)를 바꾸지 않는다. 그것은 이미 별도 정책으로 닫혀 있다(operator-side ↔ reviewer-side 짝, §10).

## 2. Track 위치 — umbrella / adjacency / 무엇이 아닌가

- **umbrella (확정 아님 — 구현 closeout 결정)**: 본 트랙은 review subsystem 의 *operator-side validation discipline* 정책으로, `docs/systems/review/BACKLOG.md` 의 **RV-B-05(review input governance — operator-side honest-framing conventions)** 와 가장 인접하다. 동시에 §3d reviewer reproduction opt-in(**RV-B-04** 우산)의 operator-side 대응이다. 현재 BACKLOG 에는 이 정책에 해당하는 **번호 행이 없다** — "full-suite-green closeout policy" 라벨은 직전 plan 의 §2·§10 forward-reference 로만 존재한다. 새 BACKLOG 행(예: 신규 RV-B-NN)으로 승격할지, 아니면 RV-B-05 하위로 둘지는 **구현/closeout 시점의 결정**이며 본 planning 단계에서 확정하지 않는다(§14 — 실제로는 RV-B-05 하위 편입으로 닫힘; ID RV-B-07 은 별건 U9 에 배정됨).
- **adjacency (우산 아님)**: `tests/README.md`(testing convention home), `EVIDENCE_CONTRACT.md`(evidence shape), §6b(final report field 8). 본 트랙은 이들을 재정의하지 않고 *closeout validation 의 scope 결정* 이라는 새 layer 를 그 위에 얹는다.
- **무엇이 아닌가 (혼입 금지, §11)**:
  - **reviewer reproduction opt-in policy(§3d) 재오픈 아님** — reviewer 가 sandbox 에서 무엇을 재실행하는가의 경계는 §3d 가 source-of-truth 이며 불변. 본 트랙은 operator-side 만 다룬다.
  - **reviewer 가 full suite 를 실행하는 정책 아님** — 본 정책은 reviewer 의 실행 의무를 *늘리지 않는다*. reviewer 는 여전히 validation evidence 와 scope rationale 을 *inspect* 한다(§5, §10).
  - **모든 변경에 full suite 의무화 아님** — 핵심 목적(§1.2)에 정면 위배.
  - **CI / test runner / validation runner / automation 생성 아님**(§11).
  - **parser / verifier / lint gate 추가 아님** — 본 정책은 wording/convention/operator-discipline 이며 어떤 deterministic gate 도 추가하지 않는다.
  - **design verdict vocabulary 변경 아님**(`yes` / `no` / `yes with risk` 불변), **RV-B-06 재오픈 아님**, **`.md` EOL/autocrlf 트랙 아님**, **evidence archive automation 아님**.

## 3. Terminology — validation scope 용어 (검사 기준 1·2·3·4)

본 정책이 사용하는 validation scope 용어를 **repo 기준으로** 정의한다. 이 용어들은 현재 repo 에서 *named convention 으로 정의돼 있지 않다* — `change class` / `validation scope` 표현은 review docs 에 선례가 없다(novel). 본 트랙이 처음 명문화한다.

- **`full suite`** — `tests/` 하위 **모든 `*.Tests.ps1`**. `tests/README.md` 의 권장 command `Invoke-Pester -Path .\tests -Output Detailed` 가 discover 하는 전체 집합이다(작성 시점 기준 `tests/*.Tests.ps1` 23개 파일 — 이는 snapshot orientation 이며 test 가 추가/삭제되면 변한다; 정확한 test *case* 수는 고정 literal 로 박지 않고 `Invoke-Pester -Path .\tests` 가 discover 하는 값으로 둔다). **주의(검사 기준 2): 최근 작업에서 반복된 "Pester 88/88" 는 full suite 가 아니다.** 그것은 아래 `review-system suite` 의 5개 파일(88 tests)을 가리키며, full suite(작성 시점 23개 파일 전체)의 부분집합이다. 두 숫자를 conflate 하지 않는다.
- **`review-system suite`** — review subsystem 의 test 파일 부분집합. 최근 batch 들이 guard 로 실행한 5개 파일: `tests/review-adapter.Tests.ps1`, `tests/review-input-verify.Tests.ps1`, `tests/review-prepare.Tests.ps1`, `tests/review-run.Tests.ps1`, `tests/review-verify.Tests.ps1`(= 88 tests, `log/evidence/validation-evidence-reproduction-policy-impl/validation/validation-evidence.md` 에 기록된 관측값). `tests/review-safety-negtest.Tests.ps1` 는 **실제 Codex CLI 를 띄워 reviewer-safe write-blocking 을 검증하는 통합 테스트**라 routine guard 에서 의도적으로 제외된다 — review-system 변경이라도 doc/template/skill wording 변경이면 이 통합 테스트는 무관하다. (gap: `tests/README.md` 의 "review topology" 목록(현재 review-prepare/run/input-verify/verify + brief/path/resolve/verify-ps1 나열)은 `review-adapter` 와 `review-safety-negtest` 를 누락하고 있어 *실제 review-system 파일 집합* 과 어긋난다 — §4 gap 참조.)
- **`affected tests`** — 변경된 surface 를 직접 대상으로 하는 `tests/*.Tests.ps1` 부분집합. 예: `scripts/review-run.ps1` 변경 → `tests/review-run.Tests.ps1`(+ 영향받는 `review-adapter`/`review-verify`); `scripts/install-update.ps1` 변경 → `tests/install-update.Tests.ps1` 등. "affected" 의 판정은 operator 의 의미 판단이며 deterministic 매핑 도구를 만들지 않는다(§11).
- **`smoke / verify`** — 빠른 무결성 점검류. 구체적으로: `scripts/verify-ps1.ps1`(`.ps1` 의 BOM/CRLF/encoding policy 점검), `git diff --check`(whitespace/EOL 충돌 — 단 **tracked/staged 변경만 cover** 하므로 신규/untracked 파일은 `git add -N <path>`(intent-to-add) 후 `git diff --check`, 또는 staging 후 `git diff --cached --check` 로 점검 대상에 포함시킨다; plain `git diff --check` 는 untracked 파일에 no-op 이다), install path 의 `Invoke-OperationalSmoke`(payload brief-init+template 정합, `INSTALL.md` §13.7), review packet 의 shape gate(`scripts/review-input-verify.ps1` / `scripts/review-verify.ps1`). 이들은 full suite 보다 좁고 빠르다.
- **`manual AC`** — `tests/README.md` "Manual acceptance criteria" 가 정의하는 **손으로 점검하는 read-only checklist**. "what to verify by hand, not scripts to run." 자동 실행 대상이 아니다.
- **`validation evidence`** — validation 실행 사실의 보존 형식. 권위는 `docs/contracts/evidence/EVIDENCE_CONTRACT.md`(single Markdown bundle `validation-evidence.md` 또는 5-file recipe `command.txt`/`exit-code.txt`/`stdout.txt`/`stderr.txt`/`notes.md`)이며, review input 이 그 path 를 referencing 하는 규약은 §3a(R1 Markdown evidence convention)이 source-of-truth. 본 정책은 evidence *shape* 를 바꾸지 않고, *어떤 change class 에서 어떤 evidence 가 기대되는가* 만 정한다.

## 4. 현재 surface 분류 + 현재 wording / gap (검사 기준 1·5·6)

### 4.1 surface 분류 (역할별)

- **정책 source-of-truth home 후보 (구현 batch 변경 대상)**:
  - `docs/contracts/review/REVIEW_RESULT_CONTRACT.md` — §6b operator final report(field 8 validation evidence)가 closeout reporting 의 operative home. change class 별 closeout validation obligation + reporting rule(§9)의 자리 후보. 자리 형태는 §6b 의 field 8 확장 또는 신규 절(예: 가칭 §6c "Local validation closeout scope")이며 구현 batch 가 정한다.
  - `tests/README.md` — testing convention home. `full suite` / `review-system suite` / `affected tests` 용어(§3)의 정의가 들어갈 자연스러운 자리.
- **Mirror homes (구현 batch 변경 대상)**:
  - `snippets/claude-skills/ai-harness-review/SKILL.md` — step 7 final report field 8(validation evidence) operator-facing 표현. **deployed self-contained surface 이므로 repo-doc `§N` pointer 를 재도입하지 않는다**(기존 SKILL 규약).
  - `templates/review-input.md` — `## Validation evidence` informational section guidance(operator 가 change class + 수행/미수행 validation 을 적는 자리).
- **Context surface (미변경)**:
  - `docs/contracts/evidence/EVIDENCE_CONTRACT.md` — evidence shape 권위(이 정책은 evidence *사용* 의 scope 만 다루고 shape 는 건드리지 않는다).
- **Tracking surfaces (가이던스 홈 아님; 구현/closeout 시점에만 갱신)**:
  - `docs/systems/review/STATUS.md` — completed/deferred ledger(구현 closeout 시 ledger bullet + 이 문서로의 inbound pointer).
  - `docs/systems/review/BACKLOG.md` — triage row(승격 여부는 §14).

### 4.2 현재 wording 이 이미 codify 한 것

- **evidence inspection 측(§3a)**: validation execution claim(Pester pass count, `verify-ps1` PASS, `git diff --check` clean 등)의 근거를 Markdown evidence 로 두고 reviewer 가 *읽는* 규약은 이미 있다. 그러나 이는 *증거를 어떻게 남기고 reviewer 가 어떻게 읽는가* 이지 *operator 가 closeout 전에 무엇을 돌려야 하는가* 가 아니다.
- **reviewer reproduction 측(§3d)**: reviewer 가 broad validation/build/test 를 default 로 재실행하지 않고 opt-in 으로만 한다는 경계도 이미 있다. operator-side 의 대응(짝)이 본 트랙이다.
- **final report field 8(§6b, SKILL step 7)**: "validation evidence — the validation evidence used and its limitations." closeout report 에 validation 을 적는 자리는 있으나, *change class 별 기대치* 와 *full suite 미수행 시 reason/residual-risk 보고 구조* 는 명시돼 있지 않다.

### 4.3 gap / risk (검사 기준 5·6)

- **(gap 1) change class 별 validation 기대치의 부재**: 어떤 surface 를 바꾸면 어떤 validation 이 기대되는지에 대한 durable 매핑이 없다. 현재는 각 batch 마다 operator 판단으로 scope 를 정하고 evidence 에 기록할 뿐, *기준* 이 문서화돼 있지 않다. (직전 두 트랙이 "review-system 5-file 88/88 + git diff --check" 를 guard 로 쓴 것은 *관행* 이지 codified policy 가 아니다.)
- **(gap 2) "full suite" / "review-system suite" 용어 미정의 + tests/README.md 목록의 불일치**: §3 에서 본 대로 두 용어가 명시 정의되지 않았고, `tests/README.md` 의 review topology 목록이 실제 review-system 파일 집합과 어긋난다(review-adapter / review-safety-negtest 누락). 이는 "88/88 이 무엇인가" 를 모호하게 만든다.
- **(gap 3) full suite 미수행 보고 구조의 부재**: "full suite not run" 을 어떻게 정직하게 보고하는지(change class / run / not-run / reason / residual risk)의 규약이 없다. 현재는 evidence notes 에 자유서술로 들어간다(예: 직전 impl evidence 의 "비-review subsystem test 는 이번 변경 scope 밖이라 미실행"). 이를 정형 reporting rule(§9)로 끌어올리는 것이 본 트랙의 핵심 산출이다.
- **보조 관찰**: 이 gap 들은 모두 *wording/convention* 차원이다 — 어떤 것도 parser/runtime/test 변경을 요구하지 않으며, 본 정책도 그 차원에서만 닫는다(§11).

## 5. Core policy

1. **Local operator owns validation execution.** validation / build / test 의 *실행* 은 operator 의 local 환경 책임이며, closeout 전에 수행된다. 그 사실은 evidence(§3a / `EVIDENCE_CONTRACT.md`)로 남는다.
2. **Reviewer inspects validation evidence and scope rationale.** reviewer 는 diff / contract / local validation evidence 와 *operator 가 밝힌 validation scope 근거* 를 read 하여 판단한다. reviewer 는 full suite 를 직접 실행하는 주체가 아니다.
3. **Reviewer reproduction is the already-codified opt-in policy and is not part of this track.** reviewer 가 broad validation/build/test 를 재실행하는 것은 §3d 의 opt-in 정책 소관이며, 본 트랙은 그것을 바꾸지 않는다. reviewer 가 sandbox 가 실행 가능하다는 이유만으로 full suite 를 opportunistic 하게 돌리지 않는 것은 §3d 가 이미 보장한다.
4. **"Full suite green" is required by change class, not universally.** closeout validation scope 는 변경 class 에 비례한다(§6). full suite 가 강하게 기대되는 class(§7)와 targeted validation 으로 충분한 class(§8)가 구분된다.
5. **Not running the full suite is acceptable when disclosed.** full suite 미수행 자체는 결함이 아니다. 단, operator 는 §9 의 reporting rule 에 따라 change class / run / not-run / reason / residual risk 를 보고한다. 미수행을 숨기면 §7 의 stale-by-omission(`REVIEW_RESULT_CONTRACT.md` §7)·§5a.4 retraction 규율의 대상이 될 수 있다.

## 6. Change class validation matrix (검사 기준 7)

아래는 **설계 후보(design proposal)** 이며 구현 확정이 아니다. 각 row 의 "기대 validation" 은 *최소 기대치* 이고, operator 는 위험이 크다고 판단하면 상향할 수 있다(하향은 §9 보고 대상). full suite 의무화는 어느 class 에도 강제되지 않는다(§1.2, §5.4).

| # | Change class | 대표 예 | 기대 validation (최소) | full suite 기대 |
|---|---|---|---|---|
| 1 | planning/design doc only | 본 문서 같은 `docs/systems/**` plan/spec | `git diff --check`(신규 doc 은 untracked 이므로 `git add -N` 후 점검 — §3 `smoke / verify`); 신규 `.md` 가 sibling 과 동일 LF/no-BOM 인지 확인 | 아니오 |
| 2 | docs-only STATUS / BACKLOG / policy wording | `STATUS.md` ledger, `BACKLOG.md` triage, `docs/policies/**` | `git diff --check`; 인용 citation/count 의 mechanical 확인(§5a.4 discipline) | 아니오 |
| 3 | contract / template / SKILL wording | `REVIEW_RESULT_CONTRACT.md`, `templates/review-input.md`, `SKILL.md` (의미보존 wording) | `git diff --check`; **review-system suite**(input-verify/verify/run shape 영향 시); anti-pattern grep sweep(sibling section reconciliation 시, §13) | 아니오 (단, parser-gated heading/placeholder 에 닿으면 review-system suite 기대) |
| 4 | script / runtime behavior | `scripts/review-run.ps1`, `scripts/*.ps1` 동작 변경, `scripts/lib/**` | **affected tests + full suite**; `verify-ps1`; `git diff --check` | **예** |
| 5 | parser / verifier gate | `review-input-verify.ps1` / `review-verify.ps1` 의 gate 로직 | **affected tests + full suite**(gate 변경은 광범위 영향); positive/negative/skip 경로 TC; `verify-ps1` | **예** |
| 6 | test code | `tests/*.Tests.ps1` 추가/변경 | 변경/추가한 test 파일 실행 + **full suite**(공유 fixture/support 회귀 확인); `verify-ps1` | **예** |
| 7 | install / update / activation path | `scripts/install-*.ps1`, `update-global.ps1`, `activate-global.ps1`, `scripts/lib/install-pipeline-core.ps1`, `INSTALL.md` 의 operative contract | **affected tests + full suite**(repo-wide install pipeline·operational smoke 영향); `Invoke-OperationalSmoke`; `verify-ps1` | **예** |
| 8 | EOL-only / formatting-only | whitespace, EOL, trailing newline 정리 (의미 무변경) | `git diff --check`; 변경이 의미 무변경인지 확인 | 아니오 (단, EOL normalization 은 본 repo 에서 별도 트랙·금지, §11) |

설계 의도: class 4·5·6·7 은 **실행 가능한 동작/게이트/공유 인프라/광범위 파이프라인** 을 건드리므로 regression surface 가 넓어 full suite 가 강하게 기대된다(§7). class 1·2·3·8 은 **wording/형식** 차원이라 targeted validation 으로 충분하다(§8). class 3 은 경계 case — parser-gated heading/placeholder(`review-input-verify` 의 required heading, `{{AI_TO_FILL_*}}`)에 닿으면 review-system suite 가 기대된다.

## 7. Full suite 가 강하게 기대되는 경우 (검사 기준 7·9)

다음 class 에서는 closeout 전 **full suite**(`Invoke-Pester -Path .\tests`) 실행이 강하게 기대된다 — 변경이 공유 인프라/실행 동작/광범위 파이프라인을 건드려 좁은 부분집합만으로는 회귀를 놓칠 수 있기 때문이다:

- **class 4 (script/runtime behavior)** — 실행 경로 변경은 직접 대상 외 test 에도 영향을 줄 수 있다.
- **class 5 (parser/verifier gate)** — gate 로직 변경은 input-verify/verify 를 쓰는 여러 surface 에 cascade 한다.
- **class 6 (broad test infrastructure)** — 공유 fixture/support(`tests/support/**`) 변경은 다수 suite 에 회귀를 일으킬 수 있다.
- **class 7 (install/update/activation path)** — repo-wide install pipeline 과 operational smoke 가 얽혀 있어 full suite + smoke 가 기대된다.

이 class 들에서 full suite 를 *돌리지 않고* closeout 하려면 그것은 §9 의 명시 disclosure 와 잔여 위험 인정을 요구하는 예외이며, 기본 기대치가 아니다.

## 8. Targeted validation 으로 충분한 경우 (검사 기준 7·9)

다음 class 에서는 좁은 targeted validation 으로 closeout 가 충분하다 — full suite 를 돌려도 변경과 무관해 신호가 늘지 않기 때문이다. full suite 미수행은 이 class 에서 정상이며 §9 의 짧은 disclosure 로 충분하다:

- **class 1 (planning/design doc only)** — `git diff --check` + 신규 `.md` 의 LF/no-BOM 확인.
- **class 2 (STATUS/BACKLOG/policy wording)** — `git diff --check` + 인용/count 의 mechanical 확인.
- **class 3 (wording-only contract/template/SKILL)** — `git diff --check`; parser-gated heading/placeholder 에 닿을 때만 review-system suite. (직전 두 트랙이 정확히 이 case 였다: review-system 5-file 88/88 + `git diff --check` 만으로 닫음.)
- **class 8 (EOL/formatting-only, 의미 무변경)** — `git diff --check` + 의미 무변경 확인.
- **manual AC** 는 어느 class 든 자동 실행 대상이 아니라 손 점검 checklist 다(§3).

## 9. Reporting rule — full suite 미수행 시 (검사 기준 10)

full suite 를 돌리지 않았다면 operator 는 closeout report(`REVIEW_RESULT_CONTRACT.md` §6b field 8 / SKILL step 7 / review input `## Validation evidence`)에서 다음을 **분리해** 보고한다:

- **change class** — §6 매트릭스 중 어느 class 인가.
- **validation run** — 실제 수행한 validation(예: `git diff --check` clean, review-system suite 88/88, `verify-ps1` PASS).
- **validation not run** — 수행하지 않은 validation(예: full suite, operational smoke).
- **reason not run** — 미수행 이유(예: "wording-only 변경이라 비-review subsystem test 와 무관").
- **residual risk (있으면)** — 미수행으로 남는 잔여 위험. 없으면 "none" 으로 명시.

이 보고는 정직성 규약과 정합한다: 미수행을 숨기고 closeout 하면 `REVIEW_RESULT_CONTRACT.md` §7 stale-by-omission(review 호출 전 인지한 validation limitation 의 미disclose)·§5a.4 retraction(사후 발견 시) 규율의 대상이 될 수 있다. 본 reporting rule 은 새로운 deterministic gate 가 아니라 operator discipline 이다(§11).

## 10. Relationship to reviewer reproduction opt-in policy (§3d)

본 트랙과 직전 `reviewer reproduction opt-in` 트랙(§3d)은 **한 쌍**이며 개념적으로 연결되지만 책임이 분리된다:

- **local validation = execution source.** operator 가 자기 환경에서 validation 을 *실행* 하는 쪽(본 트랙).
- **reviewer inspects evidence.** reviewer 는 그 실행의 evidence 와 scope rationale 을 *읽는다*(§3a / §3d.4).
- **reviewer does not opportunistically run the full suite.** reviewer 는 sandbox 가 실행 가능해 보인다는 이유만으로 operator 의 full suite/validation 을 재실행하지 않는다 — §3d 가 이미 보장하며 본 트랙이 그것을 *재확인* 할 뿐 변경하지 않는다.

즉 §3d 가 reviewer 의 "재실행하지 않음" 을 정했다면, 본 트랙은 operator 의 "무엇을 실행해야 하는가" 를 정한다. 두 정책을 한 문서에 섞지 않으며, 구현 batch 는 양쪽 contract wording 이 **서로 약화 없이 cross-reference** 되도록 둔다(§6b ↔ §3d). 이 분리 자체가 검사 기준 8·9 의 요구다.

## 11. Scope exclusions

이 planning, 그리고 그것을 따르는 구현 batch 모두에서 다음을 **하지 않는다**:

- **implementation surface 수정**(이번 planning 단계). **parser / verifier / runtime behavior 변경.**
- **automation / CI / test runner / validation runner 생성** — 본 정책은 operator-discipline / convention 이며 어떤 실행 자동화도 만들지 않는다.
- **universal validation runner / change-class detection 도구 / affected-test 자동 매핑** 생성 — "어느 class 인가" / "어느 test 가 affected 인가" 는 operator 의 의미 판단이다.
- **parser / lint / verifier gate 추가** — validation scope 나 closeout reporting 을 강제하는 deterministic gate 를 만들지 않는다(`scripts/review-input-verify.ps1` / `scripts/review-verify.ps1` 불변).
- **evidence archive automation** 생성(§3d/§10 non-goal 과 일치).
- **모든 작업에 full suite 의무화** — 핵심 목적(§1.2)에 위배. full suite 는 change class 별 기대치이지 universal 요구가 아니다.
- **reviewer sandbox reproduction 정책(§3d) 변경 / 재오픈** — reviewer-side 는 본 트랙 밖.
- **reviewer 가 full suite 를 실행하도록 쓰는 wording** — reviewer 의 실행 의무를 늘리지 않는다.
- **EOL / autocrlf normalization** — `.md` blob EOL convention(`.gitattributes` 의 `*.md text eol=lf`)은 본 batch scope 밖이다. 신규 본 문서는 sibling planning doc 과 동일하게 LF/no-BOM 으로 작성됨. [stale 전제 정정: '별도 deferred 트랙' 표현은 plan-time — `.md` EOL 은 그 후 HEAD `a26f9d4` audit 에서 normalization no-op 으로 closed(STATUS `.md` EOL audit closeout 참조).]
- **design verdict vocabulary 변경**(`yes` / `no` / `yes with risk` 불변), **RV-B-06 재오픈**, **`## Validation evidence` / `## Known concerns` sub-shape lint 도입**(§10 non-goal 불변).
- **global / user file·memory·shell config·git config 수정**, **snapshot / manifest 생성**, **commit / push** — 모두 별도 사용자 명시 승인 사항.

## 12. Expected implementation surfaces (검사 기준 — 보고 항목 7)

구현 batch(별도 scoped /goal)에서 수정할 후보 surface — **이번 작업에서는 수정하지 않는다**:

- `docs/contracts/review/REVIEW_RESULT_CONTRACT.md` — **source-of-truth.** change class validation matrix(§6 요지)·full-suite 기대 경계(§7/§8)·reporting rule(§9)·§3d 와의 cross-reference(§10)를 codify. 자리 후보: §6b field 8(validation evidence)의 확장 또는 신규 절(가칭 §6c "Local validation closeout scope"). **§3d 와 양방향 cross-reference 로 self-consistency 보장** 이 핵심.
- `tests/README.md` — `full suite` / `review-system suite` / `affected tests` 용어 정의 추가(§3) + review topology 목록의 review-adapter/review-safety-negtest 불일치(gap 2) 정정.
- `snippets/claude-skills/ai-harness-review/SKILL.md` — step 7 final report field 8 + validation discipline 의 operator mirror. **deployed self-contained surface 이므로 repo-doc `§N` pointer 재도입 금지.**
- `templates/review-input.md` — `## Validation evidence` guidance 에 change class + run/not-run/reason 보고 hint 도입(간결히).
- (인접·선택) `docs/contracts/evidence/EVIDENCE_CONTRACT.md` — evidence *shape* 는 불변; 필요 시 본 정책으로의 짧은 pointer(선택; core 아님).
- **조건부(구현 closeout 시점, 위 core 와 분리)**: `docs/systems/review/STATUS.md` ledger bullet + 이 문서로의 inbound pointer; `docs/systems/review/BACKLOG.md` 행 승격 여부(§14). planning-doc scope 상 이 closeout pointer wiring 은 구현 batch 로 분리되며 그때까지 일시적 orphan 을 수용한다(`docs/policies/DOCS_OPERATING_MODEL.md` §4·§7).

**구현 surface 에서 의도적으로 제외(§11)**: `scripts/review-run.ps1` H1 reviewer-mode preamble(runtime), 모든 parser/verifier/runtime, CI/runner. 첫 batch 는 docs/contract/template/skill/test-README **wording** 에 한정한다.

## 13. Validation & review plan (보고 항목 9·10)

- **planning doc 자체 review (이번 단계)**: 본 문서는 source/doc mutation 이므로 corrected working tree 기준 Codex reviewer review 를 받는다. review-system policy/doc self-modification 이므로 **global stable ToolRoot engine**(`%USERPROFILE%\.claude\ai-harness-toolset\current`)으로 돌린다(`REVIEW_RESULT_CONTRACT.md` §5a.7; SKILL step 1 reviewer-engine independence). finding → approved scope 내 수정 → **corrected-state re-review**. review 이후 문서를 수정하면 기존 review 는 stale 이므로 반드시 re-review. 정규 review path 실패 시 조용히 fallback 하지 말고 실패 자체를 finding/evidence 로 보고하고 멈춘다.
- **이 planning doc 의 change class**: 본 문서는 §6 의 **class 1(planning/design doc only)** 이다 — 따라서 자기 정책에 의해 closeout validation 은 whitespace/EOL 점검 + 신규 `.md` 의 LF/no-BOM 확인으로 충분하며 full suite 는 기대되지 않는다(§8). 단, 본 doc 은 untracked 이므로 plain `git diff --check` 는 이 파일을 cover 하지 못한다(no-op) — `git add -N` 후 `git diff --check`(또는 `git diff --cached --check`)로 실제 cover 해야 한다(§3 `smoke / verify` 정의). 이 untracked-cover 요건을 빠뜨리면 §9 가 경고하는 *scope mismatch* 가 되며, 본 트랙 review 의 pass-02 가 정확히 이 함정을 잡아냈다. 이 self-application(과 그 미세 함정)은 본 정책의 self-consistency 점검 지점이다.
- **구현 batch validation (이번 planning 단계 미실행)**: 구현 batch 의 change class 에 따라 본 정책(§6)을 *자기 자신에게* 적용한다 — wording-only(class 3)면 review-system suite + `git diff --check`; tests/README.md 정정이 test 의미를 바꾸지 않으면 class 2/3. anti-pattern grep sweep 은 sibling section reconciliation 시 첫 re-review 전 수행.
- **corrected-state re-review rule**: 각 단계(planning, implementation)는 자기 corrected working tree 위에서 독립 Codex review 를 받는다. inline 대화 proposal 은 durable review 를 대체하지 않는다.

## 14. STATUS / BACKLOG handling (검사 기준 11)

- **현재 deferred 항목 식별**: `docs/systems/review/STATUS.md` 에 "full-suite-green closeout policy" 또는 본 트랙에 해당하는 **deferred 항목은 존재하지 않는다.** 이 라벨은 직전 plan(`REVIEW_VALIDATION_EVIDENCE_REPRODUCTION_POLICY_PLAN.md`)의 §2·§10 **forward-reference(non-goal)** 로만 존재한다(STATUS 의 Batch-D deferred 목록에도 없음 — 거기 남은 deferred 는 optional mirror propagation 뿐; `.md` EOL convention 은 그 후 audited no-op 으로 closed). 따라서 본 트랙은 *기존 deferred 항목의 promotion* 이 아니라 forward-referenced 별도 정책의 **planning 착수**다.
- **closeout pointer 는 implementation-time, not planning-time**: planning-doc scope 규율([[feedback_planning_doc_scope_defer_pointer]]; `docs/policies/DOCS_OPERATING_MODEL.md` §4·§7)에 따라, (a) STATUS ledger bullet + 이 문서로의 inbound pointer, (b) BACKLOG 행 승격(신규 행 신설 vs RV-B-05 하위 편입) 결정은 **구현 batch 의 closeout 에서** 수행한다 [정정: 실제로는 RV-B-05 하위 편입으로 닫힘; ID RV-B-07 은 별건 U9 category-effort policy 에 배정됨]. 이 planning 단계에서는 그 wiring 을 하지 않으며, 일시적 orphan(이 문서를 가리키는 inbound pointer 부재)을 수용한다. 그 이유로 본 단계에서 commit 하면 STATUS/BACKLOG 변경이 함께 가지 않는다 — 이는 의도된 scope 분리다.
- 단, 본 planning 자체가 commit 대상이 되는지(그리고 그 시점)는 사용자 명시 승인 사항이며(§11), 본 문서는 그 승인을 전제하지 않는다.

---

*이 문서는 open track 의 design/plan 이다. 구현·리뷰·commit/push 는 각각 별도 사용자 승인이 필요한 후속 단계다.*
