# review — idea-only notes

> **이 문서는 idea-only notes 다.**
>
> - **Not planned work.**
> - **Not implementation backlog.** `docs/systems/review/BACKLOG.md` 의 RV-B-* row 가 아니다.
> - **Not deferred implementation scope.** "deferred-until-evidence" backlog 항목 (예: Counter-argument H2 Option A) 와도 분리된 class.
> - **No planning / design / implementation 진행 — 별도 user 명시 결정 (별도 scoped `/goal` + Codex review gate) 없이는 어떤 작업도 시작하지 않는다.**
>
> 본 문서의 목적은 review subsystem 의 heavier-mechanism candidate 중 **deferred backlog 도 아니고 implementation 대상도 아닌** idea 들을 durable source-managed 문서에 기록하여 future operator turnover / long-term governance review 시점에서 누락되지 않도록 하는 것이다 (Phase 2 Implementation Plan (`polishing/review/review_lts_phase2_implementation_plan_20260527.md`) §11.2.2 의 idea-only durability mitigation).

## What is NOT in this document

본 IDEAS.md 의 항목과 혼동되지 말아야 할 인접 class:

- **Counter-argument H2 Option B 는 본 IDEAS.md 의 항목이 아니다.** Phase 2 Batch 1A (commit `76033f4`) 에서 이미 codified — source-of-truth 는 `docs/contracts/review/REVIEW_RESULT_CONTRACT.md` §3c (Counter-argument convention; optional, strongly-recommended; non-parser), mirror 는 `templates/review-result.md` / `templates/review-input.md` / `snippets/claude-skills/ai-harness-review/SKILL.md`. 본 IDEAS.md 의 항목은 §3c 의 light-mechanism codification 보다 heavier mechanism class.
- **Counter-argument H2 Option A (parser-required form) 는 본 IDEAS.md 의 항목이 아니다.** Option B 의 evidence accumulation 후의 escalation candidate — "deferred-until-evidence backlog" class. escalation threshold (~5-10 review pass + 2+ reviewer omission/boilerplate + 1+ false-yes/blocking miss tied to lack of dedicated section) 는 Phase 2 Implementation Plan §2.4.1 가 명시. 본 IDEAS.md 의 idea-only class 와 분리.
- **Vertical-vs-horizontal review mode 는 본 IDEAS.md 의 항목이 아니다.** Phase 2 Implementation Plan §10.4 에서 **later candidate** 로 분류 — 별도 future batch 의 implementation candidate. idea-only 와도 deferred-until-evidence backlog 와도 다른 class. 본 IDEAS.md 의 의의는 본 candidate 의 idea-only 강등이 아니라 본 candidate 와의 명시적 분리. 본 문서에서 설계 / 구현 / 계획 없음.

## Relationship to other surfaces

- `docs/systems/review/BACKLOG.md` (RV-B-* row) — implementation candidate 의 entry point. 본 IDEAS.md 의 항목은 BACKLOG row 가 아니다. 본 IDEAS.md item 의 promotion-to-implementation 은 (1) reopen criteria 충족 + (2) BACKLOG row 의 explicit entry + (3) user 의 별도 scoped `/goal` + (4) Codex review gate 의 4 단계 모두 충족 시에만 가능.
- `docs/systems/review/STATUS.md` — review subsystem 의 current status + maintenance-mode exclude list. line 7 의 "No new feature / reviewer adapter / multi-reviewer orchestration / review-history DB / cross-run aggregation / automatic retention without a separate scoped approval" 은 본 IDEAS.md 항목 2 (multi-reviewer consensus / calibration loop) 의 transitive mechanical guard.
- `docs/contracts/review/REVIEW_RESULT_CONTRACT.md` §3c (Counter-argument convention, codified in Phase 2 Batch 1A; commit `76033f4`) — 본 IDEAS.md 의 idea-only 항목과 별개의 light-mechanism. §3c.5 의 non-goals list 가 명시 — devil's advocate / multi-reviewer 는 §3c 의 도입 batch 의 scope 외부.
- Phase 1 historical context (`docs/systems/review/BACKLOG.md` RV-B-05 row 의 Eighth batch closed 부분) — 본 IDEAS.md 의 idea-only item 들이 Phase 1 Batch II close 시점에서 "Phase 2 candidates remain deferred" 로 framed 되어 있다. 본 frame 은 Phase 1 Batch II commit (`e6027ca`) 의 historical snapshot 으로 정합; current-state framing 의 source-of-truth 는 STATUS.md ledger + 본 IDEAS.md + commit history (`76033f4` Counter-argument Option B codification) 다.

## Idea-only items

### 1. Devil's advocate pre-pass orchestration

**What it is.** 본 final Codex review pass 전 별도 adversarial pre-pass 를 두어 operator input / draft / batch scope 에 대한 critical perspective 를 먼저 받는 mechanism. final pass 는 본 input + pre-pass output 모두를 input 으로 사용. canonical 2-file contract (input.md + result.md) 가 pre-pass-NN/ sub-layout 또는 sidecar artifact 로 expand 되어야 함.

**Why it might be useful.** Pre-pass 가 final pass 가 놓칠 가능성을 미리 surface — independent reviewer 의 framing-tilt detection 또는 substantive counter-argument 의 부재를 final pass 전에 catch. light P3 wording (Phase 1 Batch II 의 H1 preamble) + Counter-argument H2 Option B (Phase 2 Batch 1A 의 §3c) 의 measurable effect 가 inadequate 한 case 에서의 escalation 후보.

**Why it is not planned now.**

- **Runtime cost 2x** per review task — solo-maintainable LTS subsystem 의 운영 비용 직접 2 배.
- **Canonical 2-file contract expansion 또는 sub-layout 도입 필수** — `docs/contracts/review/REVIEW_RESULT_CONTRACT.md` §1 의 canonical artifact contract 의 dismantle. RV-02 / RV-03 closure (canonical task/pass topology) 의 일부 reversal.
- **Operator burden 2x** — 매 review 마다 pre-pass result 의 classify / react + final pass authoring.
- **Light mechanism 의 measurable effect 의 unproven inadequacy** — light P3 wording (substance-evidence 7 case 누적, Phase 1 Batch II 부터 Phase 2 Batch 1A pass-03 까지) + Option B codification (Phase 2 Batch 1A) 의 evidence base 가 heavier mechanism 으로의 escalation 을 정당화하지 않는다. premature.

**Reopen criteria.** Phase 2 Implementation Plan §10.3 (carry-over from Phase 2 candidate analysis §10.3) 의 evidence threshold 중 어느 하나 이상 충족 시:

- **Repeated false negatives** — review pass 의 `## Blocking findings = none` 임에도 후속 단계 (commit / push / merge / release) 에서 blocking issue 가 발견되는 pattern 이 반복 (single in-result H2 + light P3 wording 이 catch 못함).
- **Model-bias evidence** — 동일 input 에 대한 다른 reviewer model 의 verdict 가 systematically 다른 pattern 이 관찰됨 (single reviewer 의 bias 가 verdict 를 systematically 왜곡; 본 evidence 의 수집 자체는 본 idea-only item 의 reopen 후의 step 아니라 별도 informal observation 의 결과).

본 evidence 가 누적된 시점에서 user 의 별도 명시 결정 + 별도 scoped `/goal` + Codex review gate 의 표준 cycle 로만 reopen 한다. STATUS.md maintenance-mode 의 implicit 변경 trigger 가 되면 안 된다.

### 2. Multi-reviewer consensus / post-merge calibration loop

**What it is.** 2+ reviewer (예: Codex + 다른 model adapter) 의 verdict aggregation; 또는 post-merge data (commit 후의 실제 issue / regression / hotfix 의 occurrence) 로 reviewer confidence 의 longitudinal calibration loop 운영. 본 idea 는 두 sub-mechanism 의 결합 form (multi-reviewer aggregation + calibration loop) 도 포함하고 각 단독 form 도 포함.

**Why it might be useful.**

- **Model bias 분산** — single reviewer (Codex) 의 systematic 편향을 multi-model aggregation 으로 mitigate.
- **Verdict quality 의 longitudinal 측정** — calibration loop 로 reviewer 의 confidence vs actual outcome 의 alignment evidence 수집.

**Why it is not planned now.**

- **`docs/systems/review/STATUS.md` 의 maintenance-mode exclude list 명시 exclude** — "No new feature / reviewer adapter / multi-reviewer orchestration / review-history DB / cross-run aggregation / automatic retention without a separate scoped approval." 본 idea 의 모든 요소 (reviewer adapter / multi-reviewer orchestration / cross-run aggregation / history DB) 가 exclude list 의 항목.
- **Canonical artifact contract redesign 필수** — canonical 2-file contract (input.md + result.md) 의 expand (`result-codex.md` / `result-<adapter>.md` / `consensus.md` 등) 가 `docs/contracts/review/REVIEW_RESULT_CONTRACT.md` §1 의 "다른 sidecar 파일은 canonical contract 의 일부가 아니다" 와 직접 충돌.
- **Solo-maintainability risk very high** — 다수 reviewer adapter 의 long-term maintenance + aggregation drift + persistence schema evolution + multi-model API surface 변화 대응.
- **Over-engineered for solo-maintainable LTS project** — 본 subsystem 의 framing (solo-maintainable, low-cost, deterministic-gate-only) 에 대비 mechanism 의 complexity 가 비례하지 않는다.
- **Calibration evidence 의 수집 자체가 maintenance-mode exit 의 결과물** — 본 idea 진입의 정당화 evidence 자체가 maintenance-mode 안에서 수집 가능한 종류 아님 (longitudinal post-merge data 와 multi-reviewer A/B 가 모두 maintenance-mode exit 의 별도 batch 의 작업).

**Reopen criteria.** Phase 2 Implementation Plan §10.3 의 evidence threshold + STATUS.md maintenance-mode exit decision 의 **두 조건 동시 충족** 시:

- **Phase 2 Implementation Plan §10.3 의 evidence threshold 중 어느 하나** — repeated false negatives 또는 model-bias evidence (Devil's advocate idea-only item 의 reopen criteria 와 동일 evidence path; 본 evidence 의 누적이 두 idea 의 어느 쪽으로 escalate 되는지의 user 결정은 evidence 누적 후의 별도 결정).
- **STATUS.md maintenance-mode exit 의 별도 scoped approval** — user 가 review subsystem 의 maintenance-mode 를 벗어나서 새 feature class 진입을 명시 결정 (review subsystem 의 active development phase 로의 re-entry).

본 두 조건이 모두 user 의 명시 결정으로 수용된 시점에서 별도 scoped `/goal` + Codex review gate 의 표준 cycle 로만 reopen 한다.

## Idea-only document discipline

- 본 IDEAS.md 는 source-managed (git-tracked) document 이며 `<ProjectRoot>/log/` 하위 runtime tree 아래의 working artifact 가 아니다.
- 본 문서의 추가 idea-only item 또는 기존 item 의 wording 갱신은 별도 source-doc governance batch 의 scope 영역 — 본 IDEAS.md 도입 batch 의 scope 외부.
- 본 문서의 idea-only item 의 promotion-to-implementation 은 (1) reopen criteria 의 evidence 충족 + (2) STATUS.md 또는 BACKLOG.md row 의 explicit entry + (3) user 의 별도 scoped `/goal` + (4) Codex review gate 의 표준 cycle 의 4 단계 모두 충족 시에만 가능. 본 IDEAS.md 안에서 promotion 결정은 없다.
- 본 문서의 reader 가 idea-only item 을 implementation backlog 와 혼동하지 않도록, item 의 "Why it is not planned now" + "Reopen criteria" 의 두 sub-section 은 결정의 substantive base 로 항상 surface 한다.
- 본 문서의 idea-only item 이 `docs/systems/review/BACKLOG.md` RV-B-* row 의 entry 로 변환되거나, `docs/systems/review/STATUS.md` 의 active-development phase 로 entry 되거나, `docs/contracts/review/REVIEW_RESULT_CONTRACT.md` 의 contract 변경으로 entry 되면 본 IDEAS.md 의 해당 항목은 그 시점에서 superseded — 본 IDEAS.md 의 해당 entry 는 historical 기록으로 archive 되거나 (해당 entry 의 promotion-batch 안에서) 별도 governance batch 에서 정리.
