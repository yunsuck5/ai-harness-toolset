# Review Effort Guide

> **현행 status routing.** 본 문서는 review effort/cost 운영 권고 (active reference) 다. review subsystem 의 current 상태는 `docs/systems/review/STATUS.md`, contract 는 `docs/contracts/review/REVIEW_RESULT_CONTRACT.md` 가 authoritative 다 (전체 routing: `docs/current/SOURCE_OF_TRUTH.md`).

> **Wired safe-default vs. cost guidance (reconciliation, Batch B).** review subsystem 의 *wired* safe-default reasoning effort 는 이제 `xhigh` 다 — 채택된 `docs/systems/review/REVIEW_POLISHING_DECISION_RECORD.md` (default = latest model + xhigh) 에 따라 `scripts/review-run.ps1` 가 `-c model_reasoning_effort=<value>` 로 전달한다 (`docs/systems/review/REVIEW_POLISHING_BATCH_A_SPEC.md` Batch B). 본 가이드의 cost-control 권고는 그 safe-default 로부터 *언제 downgrade 할지* 를 다루는 운영 가이드로 읽는다: 명확히 단순한 `local correctness review` packet 만 `-Effort` 로 downgrade 하고, cross-subsystem / contract / boundary / ambiguous 변경은 high/xhigh 를 유지한다. 따라서 아래 §6 / §8 의 표·checklist·examples 에서 말하는 "downgrade 여지" 는 *safe-default(xhigh)에서 명확히 단순한 packet 을 의식적으로 낮추는* 판단을 뜻하며, low/medium 은 그 downgrade target 이지 baseline 이 아니다. effort ⟂ coverage 는 불변이다 (effort 로 coverage 를 줄이지 않는다). 이 wiring 자체는 `U9 operational` 을 성립시키지 않는다 (Batch C reviewer-safety 검증이 함께 필요).

> **Config-backed category policy (reconciliation, U9).** 본 가이드의 effort tier 와 phase 권고는 이제 `config/reviewer.json` 의 `categoryPolicy` (`category → {model, reasoningEffort}` lookup) 로 **config-backed** 다 — operator 가 `scripts/review-run.ps1 -EffortCategory <key>` 로 category 를 **명시 선택**하면 review-run 이 그 category 의 {model, effort} 를 적용한다 (`docs/policies/REVIEWER_CONFIG_POLICY.md` "Category policy"). 두 가지를 분명히 한다. **(1) 여전히 자동이 아니다.** category 분류는 operator judgment 이며 review-run 은 changed files / `-Stage` / LLM 으로 category 를 추론하지 않는다 — §2 non-goals 의 "강제 자동 적용" 금지는 그대로다. 본 category policy 는 그 non-goal 을 깨지 않는 *explicit operator 선택* 채널이다. **(2) 현재 모든 category 는 safe-default(`xhigh`) 다.** 이번 batch 는 category map 의 *메커니즘*(config lookup + per-invocation override)만 도입했고, 개별 category 의 effort 를 floor 아래로 낮추는 *값 튜닝*은 first-cycle 운용 데이터 후의 별도 단계로 deferred 다 (decision record U9: 세부 category 는 운용 데이터 후). 따라서 아래 표의 effort tier 는 *향후 각 category 가 튜닝될 수 있는 목표 범위*를 설명하는 운영 가이드이지, 현재 shipped category 값이 아니다 (현재 전부 `xhigh`). effort ⟂ coverage 불변.

본 문서는 `ai-harness-toolset` 의 CLI-only MVP 종료 이후, Codex review 를 여러 실제 프로젝트에 적용할 때 review effort 와 cost 를 어떻게 통제할지에 대한 가이드다. 사용자 운용 권고이며, tooling 의 자동 게이트가 아니다.

본 문서는 review subsystem 의 contract 자체를 재정의하지 않는다. 권위 source-of-truth 는 그대로다.

- review record 계약: `docs/contracts/review/REVIEW_RESULT_CONTRACT.md`
- subsystem scope: `docs/project/AI_HARNESS_TOOLSET_SCOPE.md`
- operator 운용: `docs/user_guide/OPERATOR_GUIDE_KR.md`
- reviewer config: `docs/policies/REVIEWER_CONFIG_POLICY.md`
- post-MVP 결정 기록: `docs/decisions/POST_MVP_PLAN.md`

본 문서의 모든 권고는 위 contract 들과 모순되지 않도록 작성한다. 충돌이 발생하면 위 contract 가 우선한다.

---

## 1. Purpose

post-MVP 단계에서 ai-harness-toolset 을 복수의 real project 에 적용하기 시작하면, 별도 조치 없이는 Codex review 의 effort 와 cost 가 빠르게 누적된다. 본 가이드는 다음을 줄이는 것을 목적으로 한다.

- 의미 없는 over-reviewing (한 cycle 로 충분한 변경에 대해 반복 review).
- downgrade 가능한 단순 packet 까지 safe-default(`xhigh`)로 review 하는 비용 낭비 (명확히 단순한 `local correctness review` packet 은 `-Effort` 로 downgrade).
- 지나치게 큰 target file set 묶음.
- verdict 미정의 상태에서의 불필요한 review loop (no verdict 인데 다음 단계를 자동으로 시도하는 패턴).
- review subsystem 이 commit / push / release 의 자동 게이트인 것처럼 다뤄지는 오해.

본 가이드는 위 다섯 가지를 사용자가 운영 시점에 스스로 인식하고 통제할 수 있도록 돕는다.

---

## 2. Non-goals

본 문서는 다음을 다루지 않는다.

- review subsystem 의 contract 변경. minimum field set, verdict vocabulary, hash binding 의미는 `docs/contracts/review/REVIEW_RESULT_CONTRACT.md` 가 source-of-truth 다.
- effort level 의 강제 자동 적용 (예: 정책에 따라 `xhigh` 를 자동 차단), 그리고 effort category 의 자동 추론 (changed files / `-Stage` / LLM 으로 category 를 골라 effort 를 자동 선택). 본 문서는 사용자 권고이며 tooling 의 자동 게이트가 아니다. `categoryPolicy` (U9) 는 이 non-goal 의 예외가 아니다 — category 는 operator 가 `-EffortCategory` 로 *명시 선택*하는 explicit 채널이지 자동 분류가 아니다 (`docs/policies/REVIEWER_CONFIG_POLICY.md` "Category policy").
- review verdict 를 commit / push / release 의 자동 게이트로 만드는 것. 그런 wrapper 는 `docs/contracts/review/REVIEW_RESULT_CONTRACT.md` 의 non-goals 에 명시되어 있다.
- packaging (`package-toolset.ps1`), adoption / link mode, public release distribution 의 구체적 책임. 이는 별도 scoped 승인이 필요한 post-MVP 항목이다 (`docs/decisions/POST_MVP_PLAN.md` §6).
- BF Level 1/2 / Level 3 또는 chatlog subsystem 의 운영 규칙. `docs/contracts/brief/BRIEF_CONTRACT.md`, `docs/contracts/chatlog/CHATLOG_CONTRACT.md` 가 source-of-truth 다.
- automatic retention 정책 (auto-prune, rotate, expire). 현재 retention 은 manual per-`<review-task-id>/` (또는 per-`pass-NN/`) deletion 으로 고정되어 있다 (`docs/contracts/review/REVIEW_RESULT_CONTRACT.md`).

---

## 3. Review cost principles

본 가이드의 효력은 다음 다섯 가지 원칙 위에 있다.

1. **Review 는 quality gate 다. commit / push / release 의 approval 이 아니다.** verdict 가 `yes` / `yes with risk` 라도 commit / push / merge / publish / release / upload 는 사용자가 별도로 결정하고 직접 실행한다 (`docs/contracts/review/REVIEW_RESULT_CONTRACT.md` non-goals).
2. **Reviewer verdict 어휘는 정확히 세 가지다.** `yes`, `no`, `yes with risk`. 다른 표현은 받아들이지 않는다.
3. **Review 는 target-artifact-bound 다.** 각 pass 의 `input.md` 안 informational `## Target files` section 이 그 review 가 검토한 파일 set 을 기록한다. 그 set 외 파일에 대한 verdict 는 본 toolset 의 review 결과가 아니다.
4. **거대한 무관 diff 를 하나의 packet 으로 review 하지 않는다.** subsystem boundary 단위로 분리하여 review 한다.
5. **wired safe-default 는 `xhigh` 다 (위 reconciliation note).** 비용을 위해 *명확히 단순한* `local correctness review` packet 만 의식적으로 한 단계 downgrade 한다. cross-subsystem / contract / boundary / ambiguous 변경은 high/xhigh 를 유지한다 (§6 참조). downgrade 는 coverage 축소가 아니다 (effort ⟂ coverage).

추가 원칙:

- 가능한 한 가장 작은 의미 있는 target file set 집합을 사용한다 (§7).
- 한 scoped approval 당 한 번의 review / fix cycle 을 우선한다. corrective pass 반복은 별도 승인 사항이다.
- review-verify 의 `-RequireResult` mode 가 PASS 한 result 만 다음 결정의 input 으로 사용한다 (§9).
- `<ProjectRoot>/log/brief/BRIEF.md` (canonical Brief) 와 `<ProjectRoot>/log/chatlog/` 의 artifact 는 reviewer verdict 가 아니다. `brief-check.ps1` 의 PASS / FAIL 도 reviewer verdict 가 아니다 (`docs/contracts/brief/BRIEF_CONTRACT.md`, `docs/contracts/chatlog/CHATLOG_CONTRACT.md`). `log/chatlog/current/resume.md` / `summary.md` 는 canonical 자리가 아닌 failed intermediate / legacy migration source / deprecation candidate 분류이며, 본 가이드의 verdict 판단 경로와 무관하다.

---

## 4. When review is required

다음 경우에는 Codex review 를 권장한다. 본 절은 권고이며 자동 게이트가 아니다.

- review subsystem 자체의 변경:
  - pass allocation / verdict shape / 결과 binding 로직 (`scripts/review-prepare.ps1`, `scripts/review-run.ps1`, `scripts/review-verify.ps1`, `scripts/review-input-verify.ps1`).
  - `input.md` / `result.md` 작성 책임 또는 `## Verdict` parser 동작.
  - `templates/review-input.md` / `templates/review-result.md` 의 contract-영향 변경.
  - `config/reviewer.json` 의 reviewer config 책임 변경.
- review verdict semantics 의 해석 변경 (예: `yes with risk` 처리 방식 재정의).
- commit / push / release / merge / publish gate semantics 에 영향을 줄 수 있는 변경. 본 toolset 자체는 이 게이트를 자동화하지 않지만, 사용자 운영 절차에 미치는 영향이 있으면 review 한다.
- cross-subsystem boundary 변경 (review ↔ chatlog ↔ evidence ↔ brief 사이의 책임 경계).
- packaging / adoption / link 동작 변경 (`package-toolset.ps1` 등 future tool 이 도입되는 경우의 작동 boundary).
- target repo mutation behavior 변경 (toolset 이 target project 의 어떤 파일을 만드는지 / 만들지 않는지에 영향).
- security / privacy sensitive behavior (예: log 에 새로운 종류의 사용자 입력이 보존되도록 바뀌는 경우).
- 복수 target project 에 동시 영향을 줄 수 있는 변경.

위 항목 중 하나라도 해당하면 downgrade 대상이 아니다 — wired safe-default(xhigh)를 유지한다 (§6).

---

## 5. When review can be skipped

다음 경우에는 Codex review 를 호출하지 않아도 된다. skip 결정은 사용자가 한다.

- comment / 오타 / 문장 정정만 포함된 docs 변경 (contract 의미 변경 없음).
- local scratch / debug / one-off 시도 자료 (commit 대상이 아님).
- format-only docs 변경 (heading rename 없음, contract 영향 없음).
- runtime 으로 생성되는 snapshot / handoff artifact 자체. 이 artifact 들은 `log/` 아래에 보존되거나 별도 외부 자리에 보관되며 source 트리에 commit 되지 않는다 (`docs/contracts/review/REVIEW_RESULT_CONTRACT.md` source snapshot 규칙).
- BF 저장 / closeout 동작 자체 (BF Level 1/2 manual save discipline 에 따라 `<ProjectRoot>/log/brief/BRIEF.md` 를 갱신하는 흐름). BF artifact 는 reviewer verdict 가 아니므로 review 대상이 아니다.

다음 경우는 review 가 아니라 별도 검증으로 충분하다.

- BRIEF 의 shape 확인은 `scripts/brief-check.ps1` 가 담당한다. 그 PASS / FAIL 은 reviewer verdict 가 아니다.
- review packet freshness 확인은 `scripts/review-verify.ps1` default mode 가 담당한다. 별도 Codex 호출을 의미하지 않는다.

skip 한 변경이 후속 작업에서 의미 있는 contract 또는 behavior 변경으로 확대된다면, 그 시점에 review 를 호출한다. skip 결정은 그 시점의 변경 범위에 한정된다.

---

## 6. Effort levels

본 toolset 은 다음 명목 effort 단계를 권고한다. 실제 reviewer 호출 시의 model / sandbox / web search 설정은 `config/reviewer.json` 과 `scripts/review-run.ps1` 의 Codex CLI 호출 라인이 결정한다. 본 문서는 단계의 의미만 정의한다.

| Effort | 의미 | 권장 사용 시점 |
|---|---|---|
| no review | review 호출 없음 | §5 의 skip 조건에 해당 |
| low / medium (downgrade target) | safe-default(xhigh)에서 의식적으로 낮춘 single-cycle review | 명확히 단순한 `local correctness review` packet (작은 단일 subsystem / 작은 docs / script 변경) 에 한해 explicit `-Effort` 로 downgrade |
| high | 더 큰 비용을 감수하는 single-cycle review | 두 개 이상의 subsystem 에 걸친 변경, contract clarification 의 정합성 risk |
| xhigh (wired safe-default) | 가장 비용 큰 reviewer 설정; `review-run.ps1` 의 기본값 | result binding / verdict semantics / cross-subsystem boundary / security-sensitive 변경, 그리고 downgrade 되지 않은 모든 기본 review |

권고:

- wired safe-default 는 `xhigh` 다 (위 reconciliation note). 비용 통제는 그 default 를 *낮추는* 방향의 의식적 판단으로 수행한다 — 명확히 단순한 `local correctness review` packet 만 `-Effort` 로 downgrade 하고, 그 외에는 high/xhigh 를 유지한다.
- 한 batch 안에서 동일 diff 에 대해 effort 를 단계적으로 끌어올리는 escalation 패턴은 비용 손실로 이어진다. 한 번의 review 안에서 결판이 나도록 target file set 와 effort 를 미리 결정한다.
- effort 를 올린다고 verdict 가 `yes` 가 되는 것은 아니다. effort 는 검토 면적 / 깊이의 비용 척도일 뿐이며, verdict 자체는 reviewer 가 결정한다.
- effort 단계 자체는 자동 게이트가 아니다. 사용자가 본 가이드와 함께 호출 시점의 인자 (CLI argument, reviewer config) 로 표현한다. effort/model 은 세 가지 explicit 채널로 표현된다: `-Effort` / `-Model` (per-invocation override), `config/reviewer.json` 의 scalar `reasoningEffort` / `model`, 그리고 `-EffortCategory <key>` 로 선택하는 `categoryPolicy` 의 category entry (U9). 셋 다 operator 의 명시 선택이며 자동 추론이 아니다. precedence 와 category miss/fallback·fail-fast 거동의 source-of-truth 는 `docs/policies/REVIEWER_CONFIG_POLICY.md` 다. **현재 모든 shipped category 는 `xhigh`** 이며, 개별 category 의 downgrade 는 운용 데이터 후의 별도 값 튜닝이다 (위 U9 reconciliation note).

---

## 7. Target file scoping rules

current canonical review topology 에서 review 대상 파일은 각 pass 의 `input.md` 안 informational `## Target files` section (저자: Claude Code) 에 bulleted repo-relative path 로 기록된다. AI 가 자연어 의도와 `git status` 결과에서 derive 하며, 별도 staging file 채널이나 sidecar JSON 은 normal contract 의 일부가 아니다 (`docs/contracts/review/REVIEW_RESULT_CONTRACT.md`).

규칙:

- 변경된 동작을 판단하기 위해 **반드시 필요한 파일만** 포함한다.
- 동작이 contract 문서에 의존한다면, 그 direct contract docs (예: `docs/contracts/review/REVIEW_RESULT_CONTRACT.md`, `docs/contracts/brief/BRIEF_CONTRACT.md`, `docs/contracts/chatlog/CHATLOG_CONTRACT.md`) 를 함께 포함한다.
- 동작이 test 로 binding 되어 있다면, 해당 test 파일을 포함한다.
- 명시적으로 승인되지 않은 한 **전체 repo review 는 피한다.**
- 큰 변경은 subsystem 단위로 쪼개 별도 review 로 처리한다 (예: review subsystem 변경과 brief subsystem 변경을 동시에 하나의 pass 로 묶지 않는다).
- docs-only 변경은 무관한 script / template 을 포함하지 않는다. 반대로 script behavior 변경은 그 contract docs 만 적절히 포함하고, 무관한 docs 를 추가하지 않는다.
- `log/` 아래 runtime artifact (`log/review/<review-task-id>/pass-NN/...`, `log/chatlog/...`, `log/evidence/...`, `log/brief/...`) 는 target 으로 지정하지 않는다. 이는 generated read-only record 이며 source-of-truth 가 아니다.

target 목록은 `input.md` 의 informational `## Target files` section 한 곳에만 둔다. 별도 list 파일이나 sidecar artifact (예: 외부 staging `*.list`) 는 본 contract 의 일부가 아니다 — 그 형태의 legacy artifact 는 git history 에 historical reason 으로만 보존된다.

---

## 8. Phase-based review policy

phase 의 성격에 따라 safe-default(xhigh)에서의 downgrade 여지를 다르게 본다. 사용자 운용 시 참고용이며, wired safe-default 는 xhigh 다 (§6 / 상단 reconciliation note).

| Phase | downgrade 여지 (safe-default = xhigh) | 비고 |
|---|---|---|
| design | downgrade 가능 (명확히 단순한 local correctness packet) | design proposal 자체에 대한 contract 정합성 검토. 큰 신규 책임 도입이면 downgrade 하지 않고 xhigh 유지. |
| implementation | downgrade 가능 (명확히 단순한 local correctness packet) | 단일 subsystem 변경. cross-subsystem / contract semantics 변경이면 xhigh 유지. |
| test | downgrade 가능 (명확히 단순한 local correctness packet) | 새 test 가 binding 하는 행동의 정합성 확인. binding 범위가 큰 경우 xhigh 유지. |
| review | downgrade 하지 않음 | review subsystem 자체의 변경은 §4 trigger 에 해당 — xhigh 유지. |
| release | downgrade 하지 않음 (xhigh) | release 직전 변경은 cross-subsystem 영향 risk 가 누적되어 있을 가능성이 크다. |

본 phase 분류는 `templates/review-input.md` 의 `Stage` 값 (`design` / `implementation` / `test` / `review` / `release`) 과 정합한다 (`docs/contracts/review/REVIEW_RESULT_CONTRACT.md`). phase 분류는 reviewer 호출 시 `-Stage` 인자에 반영한다.

phase 자체가 자동으로 effort 를 강제하지 않는다. 본 표는 safe-default(xhigh)에서의 downgrade 여지 권고이며, 실제 effort 는 §4 / §6 의 조건이 우선한다.

---

## 9. Verdict handling

각 pass 의 `result.md` 의 `## Verdict` body 첫 비어있지 않은 줄 값은 정확히 세 가지다. 본 절은 각 verdict 에 대한 운영 권고를 정한다.

| Verdict | 의미 | 사용자 행동 |
|---|---|---|
| `yes` | 검토 범위 내에서 진행 가능 | 다음 operator 결정 (commit / push / release 등) 의 준비 상태를 보고한다. 자동 진행하지 않는다. |
| `yes with risk` | 진행은 가능하나 명시된 risk 동반 | result.md 의 risk 항목을 인용해 사용자에게 보고하고, 명시적 go / no-go 를 묻는다. 사용자가 risk 를 수용한 경우에만 다음 단계로 간다. |
| `no` | 검토 범위 내에서 진행 불가 | scoped fix plan 을 제안하고 사용자 승인을 기다린다. 자동으로 corrective pass 를 실행하지 않는다. |

추가 규칙:

- review-verify 의 `-RequireResult` mode 가 PASS 한 result 만 다음 결정의 input 으로 사용한다. default mode PASS 만으로는 reviewer 판단이 완료되었다는 의미가 아니다 (`docs/contracts/review/REVIEW_RESULT_CONTRACT.md`).
- `<ProjectRoot>/log/brief/BRIEF.md` artifact, `brief-check.ps1` PASS / FAIL, `<ProjectRoot>/log/chatlog/` artifact 는 reviewer verdict 가 아니다. verdict 의 source-of-truth 는 같은 review task 의 final pass 의 `<ProjectRoot>/log/review/<review-task-id>/pass-NN/result.md` 의 `## Verdict` 다.
- verdict parser 는 strict 하다. `Verdict: yes`, `Final verdict: yes` 같은 inline 형식은 거부된다. parsing 실패한 pass directory 는 디스크에 보존되고, 보완은 같은 `<review-task-id>/` 아래에 새 `pass-NN/` 로 다시 시작한다 (`docs/contracts/review/REVIEW_RESULT_CONTRACT.md` 의 `## Verdict` shape). V2 부터 `review-verify.ps1 -RequireResult` 는 4 required disclosure H2 (`## Blocking findings` / `## Non-blocking concerns` / `## Review limitations` / `## Assumptions relied on`) 가 각각 정확히 1 회 존재함도 함께 검증한다 — 부재 또는 중복도 같은 shape-fail 경로다.
- `no` 후의 corrective pass 는 자동으로 진행하지 않는다. 사용자 명시 승인 하에서만 1 회 시도하고, 사후 보고한다. 2 회 이상 필요해 보이면 재승인을 받는다. 이 절차는 `H:\Work\CLAUDE.md` 의 "Codex review 후 corrective pass 규칙" 과 정합한다.

---

## 10. Cost-control checklist

review 호출 직전에 사용자가 한 번 훑어보는 checklist 다. 자동 게이트가 아니다.

```text
[ ] 이번 변경이 §4 의 review-required 조건에 해당하는가?
[ ] §5 의 skip 조건에 해당하지 않는가?
[ ] target file set 이 변경 동작을 판단하기 위한 최소 set 인가?
[ ] target file set 에 무관한 subsystem 파일이 포함되어 있지 않은가?
[ ] safe-default(xhigh)에서 downgrade 한다면, 대상이 명확히 단순한 `local correctness review` packet 이고 §4 의 no-downgrade trigger 에 해당하지 않는가?
[ ] phase (-Stage) 의 downgrade 여지가 §8 표와 부합하는가? 다르면 그 이유가 명시되어 있는가?
[ ] 한 scoped approval 안에서 review/fix 1 cycle 안에 결판이 날 만큼 변경이 정리되어 있는가?
[ ] verdict 가 `no` 일 경우의 fallback 계획 (다음 scoped 승인 절차) 이 사용자와 합의되어 있는가?
[ ] verdict 가 `yes` 또는 `yes with risk` 일지라도 commit / push / release 가 자동으로 진행되지 않는다는 점을 확인했는가?
[ ] 이번 review 가 review-verify -RequireResult 까지 통과해야 함을 인지하고 있는가?
```

위 checklist 의 빠진 항목은 review 를 막지 않는다. 다만 over-reviewing 또는 cost 누적의 신호로 본다.

---

## 11. Examples

본 절의 예시는 운영 권고이며, 실제 결정은 사용자가 한다.

### Example 1 — docs-only wording clarification

상황: `docs/user_guide/OPERATOR_GUIDE_KR.md` 의 한 문장을 더 명확하게 다듬는 변경. heading 변경 없음, contract 의미 변경 없음.

- 권장 effort: no review, 또는 (review 시) 명확히 단순한 local correctness packet 이므로 `-Effort low` 로 downgrade 가능.
- Target files: 해당 docs 파일 하나만.
- Stage: design (또는 review 가 더 적절하다고 판단되는 경우).
- 비고: 같은 batch 에 다른 subsystem 의 script 변경을 끼워 넣지 않는다. wording 변경이 의미 해석을 살짝이라도 바꾼다면 한 cycle 만 돌린다 (downgrade 한 low 라도 무방).

### Example 2 — script behavior change

상황: `scripts/review-run.ps1` 의 일부 동작을 fix. 예: input verify 실패 메시지 개선.

- 권장 effort: safe-default(xhigh); 변경이 명확히 단순한 local correctness 면 `-Effort` 로 downgrade 가능. 행동 변화가 contract 의 보장에 영향을 주면 downgrade 하지 않는다.
- Target files: 변경된 `.ps1` 파일 + 그 행동을 직접 binding 하는 test 파일 + 직접 contract docs (`docs/contracts/review/REVIEW_RESULT_CONTRACT.md` 의 관련 절).
- Stage: implementation.
- 비고: 같은 batch 에 BRIEF / chatlog / packaging 변경을 함께 포함하지 않는다.

### Example 3 — review contract change

상황: `docs/contracts/review/REVIEW_RESULT_CONTRACT.md` 의 result binding 또는 verdict semantics 항목을 수정.

- 권장 effort: high 또는 xhigh.
- Target files: 해당 contract docs + `scripts/review-prepare.ps1` / `scripts/review-run.ps1` / `scripts/review-verify.ps1` / `scripts/review-input-verify.ps1` 중 영향 받는 파일 + 그 행동을 binding 하는 test 파일.
- Stage: review.
- 비고: 본 변경은 §4 의 review-required 조건에 정확히 해당한다. effort 를 낮추지 않는다. 한 scoped approval 안에서 cycle 을 1 회로 마치도록 미리 변경 범위를 묶는다.

### Example 4 — Brief / BF guide change

상황: `docs/contracts/brief/BRIEF_CONTRACT.md` 또는 `templates/brief/BRIEF.md` 에 영향을 주는 변경.

- 권장 effort: safe-default(xhigh); 변경이 명확히 단순한 local correctness 면 `-Effort` 로 downgrade 가능. cross-subsystem 영향 (예: chatlog ↔ brief 사이의 책임 경계 재정의) 이 있으면 downgrade 하지 않는다.
- Target files: 변경된 contract docs 또는 template + 영향 받는 `scripts/brief-init.ps1` / `scripts/brief-check.ps1`.
- Stage: design (boundary 재정의) 또는 implementation (script 변경).
- 비고: BRIEF 자체는 reviewer verdict 가 아니다. review 의 대상은 contract / script 의 정합성이지, BRIEF 한 파일의 내용이 아니다.

### Example 5 — Packaging / adoption mode planning

상황: post-MVP 항목 중 `package-toolset.ps1` 또는 adoption / link 동작의 design 문서를 새로 작성하는 변경.

- 권장 effort: safe-default(xhigh). design 단계의 명확히 단순한 packet 은 `-Effort` 로 downgrade 가능하나, `docs/project/AI_HARNESS_TOOLSET_SCOPE.md` / `docs/contracts/review/REVIEW_RESULT_CONTRACT.md` / `docs/contracts/brief/BRIEF_CONTRACT.md` 의 source-vs-target 경계와 충돌 risk 가 있으면 downgrade 하지 않는다.
- Target files: 새 design docs + 영향을 받는 scope / boundary docs.
- Stage: design.
- 비고: implementation 자체는 본 review 한 번으로 자동 승인되지 않는다 (`docs/decisions/POST_MVP_PLAN.md` Hard guardrails). design review 의 verdict 는 implementation start 의 input 일 뿐이다.

---

## 12. Final rules

요약 운영 규칙 (re-statement). 충돌 시 §1 이 가리키는 contract 들이 우선한다.

- review 는 quality gate 다. commit / push / release / merge / publish / upload 의 approval 이 아니다.
- commit / push / release / merge / publish / upload 는 사용자가 별도로 결정하고 직접 실행한다.
- reviewer verdict 어휘는 정확히 `yes`, `no`, `yes with risk` 다.
- review 는 target-artifact-bound 다. target file set 외 파일에 대한 verdict 는 본 toolset 의 review 결과로 보지 않는다.
- 거대한 무관 diff 를 하나의 packet 으로 review 하지 않는다.
- wired safe-default 는 `xhigh` 다; 비용을 위해 명확히 단순한 `local correctness review` packet 만 의식적으로 downgrade 한다 (effort ⟂ coverage; 위 reconciliation note).
- 가능한 한 가장 작은 의미 있는 target file set 집합을 사용한다.
- 한 scoped approval 당 한 번의 review / fix cycle 을 우선한다.
- `no` verdict 는 scoped fix plan 을 제안하고 사용자 승인을 기다린다. 자동 corrective pass 를 실행하지 않는다.
- `yes with risk` 는 risk 를 보고하고 사용자에게 명시적 go / no-go 를 묻는다.
- `yes` 는 다음 operator 결정의 준비 상태를 보고한다. 자동 진행하지 않는다.
- review-verify 의 `-RequireResult` mode 가 PASS 한 result 만 다음 결정의 input 으로 사용한다.
- `log/brief/BRIEF.md` 와 `log/chatlog/current/` 의 artifact 는 reviewer verdict 가 아니다.
- `brief-check.ps1` 의 PASS / FAIL 은 reviewer verdict 가 아니다.

본 문서는 권고다. 본 문서의 존재가 어떤 implementation, scoped work, scheduling, release 도 자동 승인하지 않는다 (`docs/decisions/POST_MVP_PLAN.md` §8 Hard guardrails 와 같은 정신).
