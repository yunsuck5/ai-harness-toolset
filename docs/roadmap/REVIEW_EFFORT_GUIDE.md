# Review Effort Guide

본 문서는 `ai-harness-toolset` 의 CLI-only MVP 종료 이후, Codex review 를 여러 실제 프로젝트에 적용할 때 review effort 와 cost 를 어떻게 통제할지에 대한 가이드다. 사용자 운용 권고이며, tooling 의 자동 게이트가 아니다.

본 문서는 review subsystem 의 contract 자체를 재정의하지 않는다. 권위 source-of-truth 는 그대로다.

- review record 계약: `docs/REVIEW_RESULT_CONTRACT.md`
- subsystem scope: `docs/AI_HARNESS_TOOLSET_SCOPE.md`
- operator 운용: `docs/MVP_OPERATOR_GUIDE_KR.md`
- reviewer config: `docs/REVIEWER_CONFIG_POLICY.md`
- post-MVP 결정 기록: `docs/roadmap/POST_MVP_PLAN.md`

본 문서의 모든 권고는 위 contract 들과 모순되지 않도록 작성한다. 충돌이 발생하면 위 contract 가 우선한다.

---

## 1. Purpose

post-MVP 단계에서 ai-harness-toolset 을 복수의 real project 에 적용하기 시작하면, 별도 조치 없이는 Codex review 의 effort 와 cost 가 빠르게 누적된다. 본 가이드는 다음을 줄이는 것을 목적으로 한다.

- 의미 없는 over-reviewing (한 cycle 로 충분한 변경에 대해 반복 review).
- 기본값으로의 `xhigh` 남용.
- 지나치게 큰 `TargetFiles` 묶음.
- verdict 미정의 상태에서의 불필요한 review loop (no verdict 인데 다음 단계를 자동으로 시도하는 패턴).
- review subsystem 이 commit / push / release 의 자동 게이트인 것처럼 다뤄지는 오해.

본 가이드는 위 다섯 가지를 사용자가 운영 시점에 스스로 인식하고 통제할 수 있도록 돕는다.

---

## 2. Non-goals

본 문서는 다음을 다루지 않는다.

- review subsystem 의 contract 변경. minimum field set, verdict vocabulary, hash binding 의미는 `docs/REVIEW_RESULT_CONTRACT.md` 가 source-of-truth 다.
- effort level 의 강제 자동 적용 (예: 정책에 따라 `xhigh` 를 자동 차단). 본 문서는 사용자 권고이며 tooling 의 자동 게이트가 아니다.
- review verdict 를 commit / push / release 의 자동 게이트로 만드는 것. 그런 wrapper 는 `docs/REVIEW_RESULT_CONTRACT.md` 의 non-goals 에 명시되어 있다.
- packaging (`package-toolset.ps1`), adoption / link mode, public release distribution 의 구체적 책임. 이는 별도 scoped 승인이 필요한 post-MVP 항목이다 (`docs/roadmap/POST_MVP_PLAN.md` §6, §7).
- GJMNet 등 특정 target project 의 채택 일정. GJMNet adoption 은 별도 결정으로 defer 되어 있다 (`docs/roadmap/POST_MVP_PLAN.md` §7).
- BF Level 1/2 / Level 3 또는 chatlog subsystem 의 운영 규칙. `docs/BRIEF_CONTRACT.md`, `docs/CHATLOG_CONTRACT.md` 가 source-of-truth 다.
- automatic retention 정책 (auto-prune, rotate, expire). 현재 retention 은 manual per-run-id deletion 으로 고정되어 있다 (`docs/REVIEW_RESULT_CONTRACT.md`).

---

## 3. Review cost principles

본 가이드의 효력은 다음 다섯 가지 원칙 위에 있다.

1. **Review 는 quality gate 다. commit / push / release 의 approval 이 아니다.** verdict 가 `yes` / `yes with risk` 라도 commit / push / merge / publish / release / upload 는 사용자가 별도로 결정하고 직접 실행한다 (`docs/REVIEW_RESULT_CONTRACT.md` non-goals).
2. **Reviewer verdict 어휘는 정확히 세 가지다.** `yes`, `no`, `yes with risk`. 다른 표현은 받아들이지 않는다.
3. **Review 는 target-artifact-bound 다.** `meta.json.targetFiles[]` 와 SHA-256 binding 으로 어떤 파일 set 을 본 review 인지 묶인다. `TargetFiles` 외 파일에 대한 verdict 는 본 toolset 의 review 결과가 아니다.
4. **거대한 무관 diff 를 하나의 packet 으로 review 하지 않는다.** subsystem boundary 단위로 분리하여 review 한다.
5. **`xhigh` 는 default 가 아니다.** 기본 effort 는 default / low 다. high / xhigh 는 risk 또는 cross-subsystem 영향이 명시적으로 큰 경우에만 선택한다 (§6 참조).

추가 원칙:

- 가능한 한 가장 작은 의미 있는 `TargetFiles` 집합을 사용한다 (§7).
- 한 scoped approval 당 한 번의 review / fix cycle 을 우선한다. corrective pass 반복은 별도 승인 사항이다.
- review-verify 의 `-RequireResult` mode 가 PASS 한 result 만 다음 결정의 input 으로 사용한다 (§9).
- `log/brief/BRIEF.md` 와 `log/chatlog/current/` 의 artifact 는 reviewer verdict 가 아니다. `brief-check.ps1` 의 PASS / FAIL 도 reviewer verdict 가 아니다 (`docs/BRIEF_CONTRACT.md`, `docs/CHATLOG_CONTRACT.md`).

---

## 4. When review is required

다음 경우에는 Codex review 를 권장한다. 본 절은 권고이며 자동 게이트가 아니다.

- review subsystem 자체의 변경:
  - result binding / freshness 로직 (`scripts/review-cycle.ps1`, `scripts/review-run.ps1`, `scripts/review-prepare.ps1`, `scripts/review-verify.ps1`, `scripts/review-input-verify.ps1`).
  - result.md / result.json 작성 책임 또는 verdict parser 동작.
  - `templates/review-input.md`, `templates/review-meta.json`, `templates/review-result.*` 의 contract-영향 변경.
  - `config/reviewer.json` 의 reviewer config 책임 변경.
- review verdict semantics 의 해석 변경 (예: `yes with risk` 처리 방식 재정의).
- commit / push / release / merge / publish gate semantics 에 영향을 줄 수 있는 변경. 본 toolset 자체는 이 게이트를 자동화하지 않지만, 사용자 운영 절차에 미치는 영향이 있으면 review 한다.
- cross-subsystem boundary 변경 (review ↔ chatlog ↔ evidence ↔ brief 사이의 책임 경계).
- packaging / adoption / link 동작 변경 (`package-toolset.ps1` 등 future tool 이 도입되는 경우의 작동 boundary).
- target repo mutation behavior 변경 (toolset 이 target project 의 어떤 파일을 만드는지 / 만들지 않는지에 영향).
- security / privacy sensitive behavior (예: log 에 새로운 종류의 사용자 입력이 보존되도록 바뀌는 경우).
- 복수 target project 에 동시 영향을 줄 수 있는 변경.

위 항목 중 하나라도 해당하면 default / low 보다 한 단계 위의 effort 사용을 검토한다 (§6).

---

## 5. When review can be skipped

다음 경우에는 Codex review 를 호출하지 않아도 된다. skip 결정은 사용자가 한다.

- comment / 오타 / 문장 정정만 포함된 docs 변경 (contract 의미 변경 없음).
- local scratch / debug / one-off 시도 자료 (commit 대상이 아님).
- format-only docs 변경 (heading rename 없음, contract 영향 없음).
- runtime 으로 생성되는 snapshot / handoff artifact 자체. 이 artifact 들은 `log/` 아래에 보존되거나 별도 외부 자리에 보관되며 source 트리에 commit 되지 않는다 (`docs/REVIEW_RESULT_CONTRACT.md` source snapshot 규칙).
- `log/chatlog/current/` BF 저장 / closeout 동작 자체. BF artifact 는 reviewer verdict 가 아니므로 review 대상이 아니다.

다음 경우는 review 가 아니라 별도 검증으로 충분하다.

- BRIEF 의 shape 확인은 `scripts/brief-check.ps1` 가 담당한다. 그 PASS / FAIL 은 reviewer verdict 가 아니다.
- review packet freshness 확인은 `scripts/review-verify.ps1` default mode 가 담당한다. 별도 Codex 호출을 의미하지 않는다.

skip 한 변경이 후속 작업에서 의미 있는 contract 또는 behavior 변경으로 확대된다면, 그 시점에 review 를 호출한다. skip 결정은 그 시점의 변경 범위에 한정된다.

---

## 6. Effort levels

본 toolset 은 다음 명목 effort 단계를 권고한다. 실제 reviewer 호출 시의 model / sandbox / web search 설정은 `config/reviewer.json` 과 `scripts/review-cycle.ps1` 의 `Invoke-CodexExec` 가 결정한다. 본 문서는 단계의 의미만 정의한다.

| Effort | 의미 | 권장 사용 시점 |
|---|---|---|
| no review | review 호출 없음 | §5 의 skip 조건에 해당 |
| low / default | 표준 single-cycle review | 일반적인 single subsystem 변경, 작은 docs / script 변경 |
| high | 더 큰 비용을 감수하는 single-cycle review | 두 개 이상의 subsystem 에 걸친 변경, contract clarification 의 정합성 risk |
| xhigh | 가장 비용 큰 reviewer 설정 | result binding / verdict semantics / cross-subsystem boundary / security-sensitive 변경 |

권고:

- 기본은 default / low 다. `xhigh` 를 default 로 두지 않는다.
- 한 batch 안에서 동일 diff 에 대해 effort 를 단계적으로 끌어올리는 escalation 패턴은 비용 손실로 이어진다. 한 번의 review 안에서 결판이 나도록 `TargetFiles` 와 effort 를 미리 결정한다.
- effort 를 올린다고 verdict 가 `yes` 가 되는 것은 아니다. effort 는 검토 면적 / 깊이의 비용 척도일 뿐이며, verdict 자체는 reviewer 가 결정한다.
- effort 단계 자체는 자동 게이트가 아니다. 사용자가 본 가이드와 함께 호출 시점의 인자 (CLI argument, reviewer config) 로 표현한다.

---

## 7. TargetFiles sizing rules

`-TargetFiles` (단일 파일) 또는 `-TargetFilesPath` (다중 파일 list) 로 review 대상 파일을 명시적으로 지정한다. 자동 git status 기반 detection 은 fallback 이며, 정합성 있는 review 에는 명시적 지정을 권장한다 (`docs/MVP_OPERATOR_GUIDE_KR.md` §9).

규칙:

- 변경된 동작을 판단하기 위해 **반드시 필요한 파일만** 포함한다.
- 동작이 contract 문서에 의존한다면, 그 direct contract docs (예: `docs/REVIEW_RESULT_CONTRACT.md`, `docs/BRIEF_CONTRACT.md`, `docs/CHATLOG_CONTRACT.md`) 를 함께 포함한다.
- 동작이 test 로 binding 되어 있다면, 해당 test 파일을 포함한다.
- 명시적으로 승인되지 않은 한 **전체 repo review 는 피한다.**
- 큰 변경은 subsystem 단위로 쪼개 별도 review 로 처리한다 (예: review subsystem 변경과 brief subsystem 변경을 동시에 하나의 packet 으로 묶지 않는다).
- docs-only 변경은 무관한 script / template 을 포함하지 않는다. 반대로 script behavior 변경은 그 contract docs 만 적절히 포함하고, 무관한 docs 를 추가하지 않는다.
- `log/` 아래 runtime artifact (`log/review/<run-id>/...`, `log/chatlog/current/...`, `log/evidence/...`) 는 review target 으로 지정하지 않는다. 이는 generated read-only record 이며 source-of-truth 가 아니다.
- 콤마 결합된 단일 `-TargetFiles "a,b"` 는 `review-cycle.ps1` 가 거부한다. 2 개 이상은 `-TargetFilesPath` 의 list 파일로 지정한다.

list 파일의 자리는 `<project-root>/log/review-targets/` 다. prepare 직후 informational snapshot 은 `log/review/<run-id>/target-files.list` 에 보존되며, 권위 source-of-truth 는 여전히 `meta.json.targetFiles[]` 다 (`docs/REVIEW_RESULT_CONTRACT.md` Retention policy / 권장 layout).

---

## 8. Phase-based review policy

phase 의 성격에 따라 review effort 의 default 를 다르게 잡는다. 사용자 운용 시 참고용이다.

| Phase | 권장 default effort | 비고 |
|---|---|---|
| design | low / default | design proposal 자체에 대한 contract 정합성 검토. 큰 신규 책임 도입이면 high. |
| implementation | low / default | 단일 subsystem 변경. cross-subsystem / contract semantics 변경이면 high 또는 xhigh. |
| test | low / default | 새 test 가 binding 하는 행동의 정합성 확인. binding 범위가 큰 경우 high. |
| review | low | review subsystem 자체의 변경은 별도 trigger (§4) 로 xhigh 까지 올린다. |
| release | high (운영 사정에 따라 xhigh) | release 직전 변경은 cross-subsystem 영향 risk 가 누적되어 있을 가능성이 크다. |

본 phase 분류는 `templates/review-input.md` 의 `Stage` 값 (`design` / `implementation` / `test` / `review` / `release`) 과 정합한다 (`docs/REVIEW_RESULT_CONTRACT.md`). phase 분류는 reviewer 호출 시 `-Stage` 인자에 반영한다.

phase 자체가 자동으로 effort 를 강제하지 않는다. 본 표는 운용 default 권고이며, 실제 effort 는 §4 / §6 의 조건이 우선한다.

---

## 9. Verdict handling

`result.md` 와 `result.json.verdict` 의 값은 정확히 세 가지다. 본 절은 각 verdict 에 대한 운영 권고를 정한다.

| Verdict | 의미 | 사용자 행동 |
|---|---|---|
| `yes` | 검토 범위 내에서 진행 가능 | 다음 operator 결정 (commit / push / release 등) 의 준비 상태를 보고한다. 자동 진행하지 않는다. |
| `yes with risk` | 진행은 가능하나 명시된 risk 동반 | result.md 의 risk 항목을 인용해 사용자에게 보고하고, 명시적 go / no-go 를 묻는다. 사용자가 risk 를 수용한 경우에만 다음 단계로 간다. |
| `no` | 검토 범위 내에서 진행 불가 | scoped fix plan 을 제안하고 사용자 승인을 기다린다. 자동으로 corrective pass 를 실행하지 않는다. |

추가 규칙:

- review-verify 의 `-RequireResult` mode 가 PASS 한 result 만 다음 결정의 input 으로 사용한다. default mode PASS 만으로는 reviewer 판단이 완료되었다는 의미가 아니다 (`docs/REVIEW_RESULT_CONTRACT.md`).
- `log/brief/BRIEF.md` artifact, `brief-check.ps1` PASS / FAIL, `log/chatlog/current/` artifact 는 reviewer verdict 가 아니다. verdict 를 결정하는 root 는 항상 `log/review/<run-id>/result.json.verdict` 다.
- verdict parser 는 strict 하다. `Verdict: yes`, `Final verdict: yes` 같은 inline 형식은 거부된다. parsing 실패한 run-id 는 디스크에 보존되고, 보완은 새 run-id 로 다시 시작한다 (`docs/REVIEW_RESULT_CONTRACT.md` `review-cycle 파서가 강제하는 result.md shape`).
- `no` 후의 corrective pass 는 자동으로 진행하지 않는다. 사용자 명시 승인 하에서만 1 회 시도하고, 사후 보고한다. 2 회 이상 필요해 보이면 재승인을 받는다. 이 절차는 `H:\Work\CLAUDE.md` 의 "Codex review 후 corrective pass 규칙" 과 정합한다.

---

## 10. Cost-control checklist

review 호출 직전에 사용자가 한 번 훑어보는 checklist 다. 자동 게이트가 아니다.

```text
[ ] 이번 변경이 §4 의 review-required 조건에 해당하는가?
[ ] §5 의 skip 조건에 해당하지 않는가?
[ ] TargetFiles 가 변경 동작을 판단하기 위한 최소 set 인가?
[ ] TargetFiles 에 무관한 subsystem 파일이 포함되어 있지 않은가?
[ ] effort 가 default / low 가 아니라면 §4 의 trigger 가 명시적으로 해당하는가?
[ ] phase (-Stage) 가 §8 표의 default 와 부합하는가? 다르면 그 이유가 명시되어 있는가?
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

상황: `docs/MVP_OPERATOR_GUIDE_KR.md` 의 한 문장을 더 명확하게 다듬는 변경. heading 변경 없음, contract 의미 변경 없음.

- 권장 effort: no review 또는 low.
- TargetFiles: 해당 docs 파일 하나만.
- Stage: design (또는 review 가 더 적절하다고 판단되는 경우).
- 비고: 같은 batch 에 다른 subsystem 의 script 변경을 끼워 넣지 않는다. wording 변경이 의미 해석을 살짝이라도 바꾼다면 low review 로 한 cycle 만 돌린다.

### Example 2 — script behavior change

상황: `scripts/review-cycle.ps1` 의 일부 동작을 fix. 예: input verify 실패 메시지 개선.

- 권장 effort: low / default. 행동 변화가 contract 의 보장에 영향을 주면 high.
- TargetFiles: 변경된 `.ps1` 파일 + 그 행동을 직접 binding 하는 test 파일 + 직접 contract docs (`docs/REVIEW_RESULT_CONTRACT.md` 의 관련 절).
- Stage: implementation.
- 비고: 같은 batch 에 BRIEF / chatlog / packaging 변경을 함께 포함하지 않는다.

### Example 3 — review contract change

상황: `docs/REVIEW_RESULT_CONTRACT.md` 의 result binding 또는 verdict semantics 항목을 수정.

- 권장 effort: high 또는 xhigh.
- TargetFiles: 해당 contract docs + `scripts/review-cycle.ps1` / `scripts/review-run.ps1` / `scripts/review-verify.ps1` / `scripts/review-input-verify.ps1` 중 영향 받는 파일 + 그 행동을 binding 하는 test 파일.
- Stage: review.
- 비고: 본 변경은 §4 의 review-required 조건에 정확히 해당한다. effort 를 낮추지 않는다. 한 scoped approval 안에서 cycle 을 1 회로 마치도록 미리 변경 범위를 묶는다.

### Example 4 — Brief / BF guide change

상황: `docs/BRIEF_CONTRACT.md` 또는 `templates/brief/BRIEF.md` 에 영향을 주는 변경.

- 권장 effort: low / default. cross-subsystem 영향 (예: chatlog ↔ brief 사이의 책임 경계 재정의) 이 있으면 high.
- TargetFiles: 변경된 contract docs 또는 template + 영향 받는 `scripts/brief-init.ps1` / `scripts/brief-check.ps1`.
- Stage: design (boundary 재정의) 또는 implementation (script 변경).
- 비고: BRIEF 자체는 reviewer verdict 가 아니다. review 의 대상은 contract / script 의 정합성이지, BRIEF 한 파일의 내용이 아니다.

### Example 5 — Packaging / adoption mode planning

상황: post-MVP 항목 중 `package-toolset.ps1` 또는 adoption / link 동작의 design 문서를 새로 작성하는 변경.

- 권장 effort: design 단계는 low / default 로 충분할 수 있다. 단, `docs/AI_HARNESS_TOOLSET_SCOPE.md` / `docs/REVIEW_RESULT_CONTRACT.md` / `docs/BRIEF_CONTRACT.md` 의 source-vs-target 경계와 충돌 risk 가 있으면 high.
- TargetFiles: 새 design docs + 영향을 받는 scope / boundary docs.
- Stage: design.
- 비고: implementation 자체는 본 review 한 번으로 자동 승인되지 않는다 (`docs/roadmap/POST_MVP_PLAN.md` Hard guardrails). design review 의 verdict 는 implementation start 의 input 일 뿐이다.

### Example 6 — GJMNet clean adoption (later)

상황: 별도 결정으로 defer 되어 있는 GJMNet adoption 이 향후 진행될 때, 본 toolset 의 source repo 쪽에서 어떤 변경이 필요한지를 design.

- 권장 effort: design 자체는 default / low. adoption boundary 가 target repo mutation 또는 packaging 동작에 영향을 준다면 high.
- TargetFiles: source repo 쪽 design docs + boundary docs. **GJMNet 측 repo 의 파일은 본 toolset review 의 TargetFiles 에 포함하지 않는다.** GJMNet 적용 자체는 본 review 가 자동 승인하지 않는다 (`docs/roadmap/POST_MVP_PLAN.md` §7).
- Stage: design.
- 비고: GJMNet adoption 은 Brief system, BF Level 3, packaging 의 방향이 정해진 시점까지 미뤄져 있다 (`docs/roadmap/POST_MVP_PLAN.md` §7). 따라서 본 review 는 그 세 조건이 ready 인지 확인하는 input 역할이 강하다.

---

## 12. Final rules

요약 운영 규칙 (re-statement). 충돌 시 §1 이 가리키는 contract 들이 우선한다.

- review 는 quality gate 다. commit / push / release / merge / publish / upload 의 approval 이 아니다.
- commit / push / release / merge / publish / upload 는 사용자가 별도로 결정하고 직접 실행한다.
- reviewer verdict 어휘는 정확히 `yes`, `no`, `yes with risk` 다.
- review 는 target-artifact-bound 다. `TargetFiles` 외 파일에 대한 verdict 는 본 toolset 의 review 결과로 보지 않는다.
- 거대한 무관 diff 를 하나의 packet 으로 review 하지 않는다.
- `xhigh` 를 default 로 두지 않는다.
- 가능한 한 가장 작은 의미 있는 `TargetFiles` 집합을 사용한다.
- 한 scoped approval 당 한 번의 review / fix cycle 을 우선한다.
- `no` verdict 는 scoped fix plan 을 제안하고 사용자 승인을 기다린다. 자동 corrective pass 를 실행하지 않는다.
- `yes with risk` 는 risk 를 보고하고 사용자에게 명시적 go / no-go 를 묻는다.
- `yes` 는 다음 operator 결정의 준비 상태를 보고한다. 자동 진행하지 않는다.
- review-verify 의 `-RequireResult` mode 가 PASS 한 result 만 다음 결정의 input 으로 사용한다.
- `log/brief/BRIEF.md` 와 `log/chatlog/current/` 의 artifact 는 reviewer verdict 가 아니다.
- `brief-check.ps1` 의 PASS / FAIL 은 reviewer verdict 가 아니다.

본 문서는 권고다. 본 문서의 존재가 어떤 implementation, scoped work, scheduling, release 도 자동 승인하지 않는다 (`docs/roadmap/POST_MVP_PLAN.md` §8 Hard guardrails 와 같은 정신).
