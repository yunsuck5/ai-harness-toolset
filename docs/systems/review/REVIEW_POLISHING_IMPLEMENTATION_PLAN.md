# 리뷰 시스템 폴리싱 — implementation planning document (plan/spec 진입 문서, 2026-06-02)

## Document character

본 문서는 리뷰 시스템 폴리싱 트랙의 **implementation planning document** 다 — adopted decision record 를 실제 구현으로 옮기기 위한 **plan/spec 진입 문서**이며, `docs/systems/review/` 아래에 배치된다.

- **성격**: plan/spec **entry** document. 무엇을 먼저 검증·설계·spec 해야 하는지를 정의한다.
- **이것이 아닌 것**: implementation 지시서 아님 / 구현 spec 아님 / decision record 아님 / 승인 문서 아님. 본 문서는 구체 파일·라인 단위의 변경 지시를 내리지 않는다. concrete agent/tool 에 operative policy 를 bind 하지 않는다(현재 구현 관찰은 provenance/예시로만 표기).
- **decision phase = CLOSED.** 본 문서는 닫힌 결정을 다시 열지 않는다. 두 user-decision(packet enforcement, effort/model strategy)은 incorporated constraint 로 취급한다.
- **위치 정합**: review subsystem maintenance posture(`docs/systems/review/STATUS.md`)와 정합한다 — 정책은 채택됐고, 실제 source/script/test 변경은 본 plan → impl spec → 구현(별도 scoped `/goal` + review gate)으로만 진행된다.

## 1. Source of truth

- **1순위(상위 권위)**: `docs/systems/review/REVIEW_POLISHING_DECISION_RECORD.md` — adopted decision record. 본 plan 의 모든 항목은 이 문서를 상위 기준으로 따른다. 충돌 시 decision record 가 이긴다.
- **계약/정책 surface**: `docs/contracts/review/REVIEW_RESULT_CONTRACT.md`, `docs/policies/REVIEWER_CONFIG_POLICY.md`, `docs/policies/REVIEW_EFFORT_GUIDE.md`, `config/reviewer.json`, `scripts/review-*.ps1`, `snippets/claude-skills/ai-harness-review/SKILL.md`.
- 본 plan 은 위 문서들의 결정을 **재서술하지 않고 참조**한다. 특히 decision record §"Key invariants to preserve downstream"(17개 문장)은 본 plan 의 모든 후속 작업에서 그대로 유지된다.

## 2. Layered readiness (불변 — 본 plan 진입 시점 기준)

decision record §Final readiness 를 그대로 승계한다. 단일 verdict 아님:

| 축 | 상태 |
|---|---|
| Final decision adoption readiness | `yes` (정책 채택 완료) |
| Implementation readiness | **`no — plan/spec required`** (구현은 문서만으로 시작하지 않는다) |
| U9 operational claim | **`blocked until U10 is verified`** |
| Reviewer-safe invocation guarantee | **`blocked until reviewer-safety override is verified`** |

**non-approval boundary**: 이 readiness 와 본 plan 의 존재는 implementation 을 승인하지 않으며, commit/push/release/adoption/merge/publication/deployment 를 승인하지 않는다. U10 이 검증됐다거나, U9 가 operational 이라거나, reviewer-safe invocation 이 보장됐다고 **주장하지 않는다.** 이 사실들은 미검증이며 숨기지 않는다.

## 3. 이 plan 의 범위 / 비범위

**In scope (본 plan 이 정의하는 것)**:
- U10 + reviewer-safety 두 검증을 **first hard gate** 로 묶어 plan/spec 진입 항목으로 분해(§4).
- 각 gate 의 evidence plan — 무엇이 "verified" 이고 무엇이 "not verified" 보고 대상인지(§5).
- plan → impl spec → 구현을 batch 로 분할하고 순서를 정의(§6).
- approval boundary 명시(§7).
- 현 시점(HEAD `1107566`)에서 실제 사용 가능한 caller-side 2-pass review closeout 방식 서술(§8).

**Out of scope (본 plan 이 하지 않는 것)**:
- 실제 source/script/test/config 변경 — 별도 scoped `/goal` + review gate.
- 두 closed user-decision 재개.
- operative policy 의 concrete agent/tool binding.
- 세부 effort/model category **값 튜닝** 확정 — 개별 category 의 effort 를 safe floor(xhigh) 아래로 낮추는 값 확정은 운용 데이터 후 refine (decision record). **단, category map *메커니즘* 자체(config-backed `category → {model, effort}` lookup, 1차 safe-default 전부 xhigh)는 본 plan 이후 별도 recovery batch 에서 구현됨 — 아래 §6 Batch B as-built note 참조. 따라서 "category 는 future work" 는 *값 튜닝* 에만 해당하며 map 골격에는 더 이상 해당하지 않는다.**
- commit/push.

## 4. First hard gate — 두 검증 (U10 + reviewer-safety)

decision record §"U10 hard gate for U9 operationalization (+ reviewer-safety override)" 에 따라, 두 검증은 **함께** plan/spec 의 first hard gate 다. 이 gate 는 **adoption blocker 가 아니라** operational/safety claim 전의 첫 plan/spec + impl/review gate 다.

### 4.1 Gate 1 — U10 per-invocation effort override 검증

목표: current reviewer tool 의 per-invocation effort override 가 실제 동작함을 확인하기 전에는 U9 를 operational 로 보고하지 않는다.

plan/spec 이 다뤄야 할 항목(검증 대상):
1. **override surface 식별** — reviewer invocation 단에서 effort/reasoning level 을 per-invocation 으로 지정하는 정확한 surface(config 키 / invocation 인자)를 식별한다.
2. **허용값 확인** — xhigh 를 포함한 허용값 집합을 확인한다.
3. **실패 거동 확인** — override 가 missing / invalid / unsupported 일 때의 거동을 확인한다.
4. **run-fact 확보** — 의도한 model/effort 가 실제 per-invocation 적용됐음을 보이는 run-fact 를 확보한다. 확보 불가 시 `not verified` 로 명시 보고(성공 암시 금지).
5. **reviewer tool 교체 규칙** — reviewer tool 이 바뀌면 이 mechanism 은 재도출 대상임을 spec 에 명시.

**현재 구현 관찰(provenance/예시, operative policy 주어 아님)**: HEAD `1107566` 의 `scripts/review-run.ps1` 가 Codex 에 넘기는 인자는 `--ask-for-approval never`, `exec`, `--sandbox read-only`, `--model <config/reviewer.json>`, `-c web_search=disabled`, `--output-last-message`, `-`(stdin)이다. **per-invocation effort/reasoning override 인자는 현재 넘기지 않는다** — 즉 effort 는 reviewer tool 의 전역 프로필/기본값에 묶여 있다. 이것이 U10 이 아직 미구현·미검증인 구체 근거이며, U9 가 operational 이 아니라는 사실의 직접 증거다. (이 관찰은 현재 구현 예시일 뿐, 정책 주어가 아니다. reviewer tool 교체 시 무효.)

### 4.2 Gate 2 — reviewer-safe invocation override 검증

목표: reviewer invocation 의 read-only / no-silent-fix 보장이 permissive global user config 에 의해 무력화되지 않음을 확인하기 전에는 reviewer-safe invocation 이 보장된다고 주장하지 않는다.

plan/spec 이 다뤄야 할 항목(검증 대상):
1. **override 명시 확인** — review runner / reviewer invocation path 가 permissive global config 가 있어도 reviewer-safe override(read-only / no auto-approval / writable surface = review output location 한정)를 명시·강제하는지 확인한다.
2. **무력화 경로 점검** — permissive global user config(예: full-access / never-approval 류 설정)가 그 override 를 무력화할 수 있는 경로가 있는지 점검한다. 즉 **CLI invocation 단 flag 와 global config 의 precedence** 를 확인한다.
3. **mutation-capable 보고** — reviewer 가 구조적 read-only guard 없이(mutation-capable) 실행될 수밖에 없는 경우, 그 사실이 보고·disclosure 되는지 확인한다.
4. **writable surface 한정** — reviewer 가 result artifact 를 직접 써야 하는 구조라면 source tree·review target 은 read-only 로 유지되고 writable surface 가 review output location 으로 제한되는지 확인한다(preferred pattern: 판단=reviewer stdout/controlled output, 기록=caller/review runner).

**현재 구현 관찰(provenance/예시)**: `scripts/review-run.ps1` 는 invocation 단에서 `--sandbox read-only` 와 `--ask-for-approval never` 를 **명시적으로** 넘긴다(전역 기본값에 기대지 않음). 그러나 permissive global Codex config(예: `~/.codex/config.toml` 의 sandbox/approval 설정 또는 full-access 류)가 이 CLI flag 보다 우선해 무력화하는지 여부는 **아직 검증되지 않았다.** flag 가 존재한다는 사실과 그 flag 가 permissive global config 를 실제로 이긴다는 보장은 별개다 — 후자가 Gate 2 의 검증 대상이다.

### 4.3 두 gate 의 결합

- 두 검증은 **함께** first hard gate 를 이룬다. U10 검증 범위에 reviewer-safety override 검증이 포함된다.
- **gate 통과 전 금지**: U9 operational 주장 / latest+xhigh 가 per-reviewer-invocation 실제 적용된다는 주장 / downgrade 규칙이 running invocation 에서 강제된다는 주장 / reviewer-safe invocation 이 보장된다는 주장 / U9 를 reviewer quality 개선 evidence 로 사용.
- **gate 통과 전 허용**: U9 를 policy 로 채택(완료), safe default 문서화, config schema 설계, reviewer-safe invocation 설계, implementation sequencing 계획.

## 5. Evidence plan

각 gate 의 "verified" / "not verified" 판정 기준과 산출물:

**Gate 1 (effort override) evidence**:
- *verified 조건*: (a) override surface(config 키/인자) 식별 문서 + (b) 허용값 집합(xhigh 포함) 확인 + (c) missing/invalid/unsupported 거동 확인 + (d) 의도한 effort 가 실제 적용됐음을 보이는 run-fact(reviewer 실행 산출물에서 관측 가능한 형태) + (e) 설정 거동에 대한 테스트/동등 evidence.
- *not verified 처리*: 위 중 하나라도 확보 불가 시 final report / review-run output 에 `not verified` 로 명시(성공 암시 금지). 특히 effort 적용이 reviewer tool 산출물에서 관측 불가하면 그 한계를 그대로 보고.
- *evidence 위치*: 실행 evidence 는 `<ProjectRoot>/log/evidence/<scope>/<case>/validation-evidence.md`(reviewer-readable, source-of-truth 아님). repo 변경을 수반하는 검증은 별도 scoped 작업의 review gate 에서.

**Gate 2 (reviewer-safety override) evidence**:
- *verified 조건*: (a) invocation 단 reviewer-safe override 명시 확인 + (b) **negative test** — permissive global config 하에서도 reviewer 가 review output location 밖(source/docs/scripts/tests)에 write/approve 할 수 없음을 보이는 run-fact + (c) precedence(CLI flag vs global config) 확인 + (d) mutation-capable 강제 시 disclosure 경로 확인.
- *not verified 처리*: precedence 를 실증하지 못하면 reviewer-safe invocation 은 `not verified` — 구조적 guard 부재 가능성을 risk 로 disclosure 하고, 그 전까지 reviewer 는 read-only posture·no-silent-fix·no-commit/push·boundary stop/report 를 명시 self-impose.
- *evidence 위치*: Gate 1 과 동일 규약.

**공통**: 검증은 본 plan 채택 후 별도 scoped 작업에서 수행한다(본 plan 작성 자체는 검증을 수행하지 않는다). evidence 는 reviewer-readable runtime supporting material 이지 deterministic truth oracle / freshness binding / source-of-truth 가 아니다.

## 6. Batch split (plan → impl spec → 구현 sequencing)

각 batch 는 별도 scoped `/goal` + 정상 review gate 를 가진다. batch 경계를 넘는 변경은 stop/report.

- **Batch A — gate investigation + impl spec (source 변경 없음)**: Gate 1·Gate 2 의 override surface·허용값·실패거동·precedence 를 조사하고, 구현 spec(어떤 surface 를 어떻게 강제할지, config schema, run-fact 캡처 형태)을 작성. 산출물은 spec 문서. **이 batch 는 검증을 시작점으로 하되 source/script 변경은 하지 않는다.**
- **Batch B — per-invocation effort override 구현(U10/U9)**: Batch A spec 기준으로 review-run 측 per-invocation effort override + config `category→{model,effort}` mapping(1차 safe-default 만: default latest+xhigh, 명확히 단순한 local correctness packet 만 downgrade) 구현 + 테스트 + run-fact 캡처. **이 batch 단독 통과는 U9 operational 보고를 가능케 하지 않는다** — U9 operational 보고는 first hard gate 의 두 축(Batch B effort override + Batch C reviewer-safety override)이 **함께** 검증된 후에만 가능하다(decision record §U10 hard gate: U10 검증 범위는 reviewer-safety override 를 포함; U10 검증 전 어떤 보고도 U9 operational 주장 금지).
  - **As-built note (recovery batch, post-plan).** 실제 Batch B 구현은 위 두 부분 중 **per-invocation effort override(scalar)** 만 구현했고 **config `category→{model,effort}` mapping** 부분은 누락한 채 닫혔다 — 이것이 audit 이 식별한 U9 traceability gap 이다. 그 누락된 category-map 부분(1차 safe-default 만: 전 category `xhigh`)은 본 plan 이후 별도 **recovery implementation batch** 에서 schema/config/runtime/tests/docs/status/backlog 까지 구현되어 닫혔다(STATUS completed-ledger "U9 config-backed category effort policy implemented"; BACKLOG RV-B-07 closed). 따라서 Batch B 의 category-map scope 는 *이 plan 의 원래 sequencing 과 다르게* 후속 batch 에서 완결됐으며, 남은 deferred 는 per-category **값 튜닝**(운용 데이터 후)뿐이다. shipped category 는 **generic change-class 만**(install-update 등 프로젝트 전용 category 미포함, global-install portability) 이다.
- **Batch C — reviewer-safe invocation override 구현/검증**: review runner 가 permissive global config 와 무관하게 reviewer-safe override 를 강제함을 구현·테스트(negative test 포함). 통과 후에야 reviewer-safe invocation 보장 보고 가능. **U9 operational 보고는 Batch B 와 Batch C 두 축이 모두 검증된 후에만 가능하다**(어느 한 batch 단독 통과로는 불가; 위 Batch B 참조).
- **Batch D — report schema / run-fact wiring**: final report 10-field 분리, `artifact pass-NN`/corrective loop/invocation count 분리 표기, reviewer guard status, (B/C 통과 후) effort·safety run-fact 반영. parser enforcement 확대는 narrow 유지(user-decision 1: 새 semantic gate 금지).

**순서**: A 선행(두 gate 공통 spec). B·C 는 first hard gate 의 두 축이므로 함께 또는 연속으로 진행하되 각자 review gate 를 가진다. D 는 B/C 통과 후. 각 batch 는 decision record §"Script / config candidate decisions" 의 conservative·범용·비특화 기준을 따른다.

## 7. Approval boundary

- **본 plan 채택 ≠ implementation 승인.** 본 문서는 plan/spec 진입 문서일 뿐이다.
- 각 batch 구현 진입은 **별도 scoped `/goal` + 정상 review gate** 를 요구한다.
- commit/push/release/adoption/merge 는 **사용자 명시 승인** 후에만. reviewer verdict/opinion 은 그 승인이 아니다.
- global user config / user-global instruction file / channel 3 install payload 변경 금지(이 plan 작업으로도, 후속 batch 로도 — 별도 explicit-approval 경계).
- 두 closed user-decision 을 unresolved wording 으로 되돌리지 말 것. conservative enforcement 를 weak requirement 로 낮추지 말 것. hard requirement 를 broad semantic automation 으로 번역하지 말 것.

## 8. HEAD `1107566` 에서 가능한 caller-side 2-pass review closeout 방식

> **Superseded / historical (strict C1 이후).** 본 절은 HEAD `1107566` 시점의 **pre-strict-C1 implementation-plan 기록**이다 — 아래 "현 시점에서 실제 사용 가능한" 서술과 `review-prepare`/`review-run`/`review-verify` 예시는 그 시점 기준이며 현행 가이드가 아니다. **현행 canonical review flow 는 strict C1**(three-level `log/review/<review-task-id>/<perspective>/pass-NN/`)이고, `review-prepare.ps1` / `review-run.ps1` / `review-verify.ps1` 는 이제 **`-Perspective <viewpoint>` 를 필수**로 요구한다(미지정 시 fail-fast; two-level fallback 없음). 현행 source-of-truth 는 `docs/contracts/review/REVIEW_RESULT_CONTRACT.md` 와 `docs/systems/review/STATUS.md` 의 **S6 strict C1 항목**이다.

본 절은 **현 시점에서 실제 사용 가능한** review closeout 메커니즘을 서술한다. 새로 정의한 자동 "2-pass review" 기능이 존재한다고 가정하지 않는다 — closeout 은 **caller-side orchestration** 으로 reviewer 를 두 관점으로 분리해 수행한다.

**canonical terminology 매핑**: 여기서 말하는 "2-pass" 는 decision record 의 `dual-perspective coverage`(= `local correctness review` + `system coherence review`)를 `two focused invocations` packaging 으로 충족하는 것이다. reviewer invocation count(2)·`artifact pass-NN`·`corrective review loop` 는 서로 **다른 축**이다(`2-pass` 는 legacy/familiar label).

**실제 사용 가능한 경로(HEAD `1107566`)**:
1. caller(=AI 에이전트)가 `scripts/review-prepare.ps1 -ReviewTaskId <id> -Pass <pass-NN> -Stage <stage> -Purpose <line>` 로 pass 디렉터리 할당 + `input.md` seed.
2. caller 가 `input.md` 를 관점별로 작성(local correctness packet / system coherence packet) — required H2 + Known concerns + validation evidence 규율 포함.
3. `scripts/review-run.ps1 -ReviewTaskId <id> -Pass <pass-NN>` 가 `review-input-verify` 후 Codex CLI 를 **1회** 호출(`--sandbox read-only`, `--ask-for-approval never`, `--model <configured reviewer model>`(`config/reviewer.json` `model` source-of-truth; concrete version 은 이 doc 에 박지 않음), `web_search=disabled`)하고 `result.md` 생성 + verdict shape 검증.
4. `scripts/review-verify.ps1 ... -RequireResult` 로 canonical artifact + 4개 disclosure H2 검증.
5. 두 관점을 분리하려면 위를 **두 focused invocation** 으로 수행한다(관점별 독립 task-id 또는 동일 task-id 의 별도 pass — 관점 축이 artifact pass-NN 축과 혼동되지 않도록 caller 가 packaging 을 disclosure).

**현 시점의 정직한 한계(closeout 자체에 적용)**:
- effort: review-run 은 per-invocation effort override 를 넣지 않는다(Gate 1 미검증). 따라서 closeout review 의 effort 는 reviewer tool 전역 프로필 값이며, **U9 operational 로 기술하지 않는다.**
- reviewer-safe: `--sandbox read-only`/`--ask-for-approval never` 는 invocation 단에서 넘기지만, permissive global config 와의 precedence 는 미검증(Gate 2). 따라서 **reviewer-safe invocation 이 보장된다고 기술하지 않는다** — 구조적 sandbox flag 가 존재한다는 사실까지만 보고한다.
- review 후 source/doc 변경이 발생하면 기존 review 는 stale 로 취급하고 `corrected-state re-review` 로 닫는다.

## 9. 반드시 보존할 invariants

decision record §"Key invariants to preserve downstream"(17개 문장)을 본 plan 의 모든 후속 batch 에서 그대로 유지한다. 특히:
- layered readiness 4축(adoption yes / impl no / U9 blocked / reviewer-safe blocked)과 non-approval boundary.
- policy 는 `caller`·`reviewer` role 에 묶이며 concrete agent/tool 에 bind 되지 않는다(현재 구현은 provenance/예시).
- `dual-perspective coverage` 는 coverage policy 이지 invocation count 아님.
- first-cycle packet enforcement = skill-text checklist + 기존 narrow mechanical gate(새 semantic gate 없음); semantic adequacy·concern completeness·evidence sufficiency 는 reviewer/operator judgment.
- effort/model default = latest+xhigh, 명확히 단순한 local packet 만 downgrade; effort ⟂ coverage.
- U10 은 plan/spec 의 first hard gate(adoption blocker 아님, vague detail 아님).
- reviewer read-only / no-silent-fix; reviewer 는 stdout/controlled output, 기록은 caller/runner.
- `yes with risk` ≠ `yes`; reviewer verdict 은 commit/push approval 아님.
- reviewer invocation safety 는 global user config 에 의존하지 않는다.

## 10. 이 plan 이 해결하지 않는 것 / open risks

- **U10·reviewer-safety 는 본 plan 으로 검증되지 않는다** — 검증은 Batch A 이후 별도 scoped 작업. 본 plan 은 검증 항목·기준·순서만 정의한다.
- 가장 강한 residual risk 는 결정 모호성이 아니라 **구현 fidelity** — 구현이 U10·reviewer-safety override·conservative enforcement·reviewer read-only 를 충실히 옮기는지(decision record §Remaining risks C).
- fresh-evidence ↔ contract-as-source-of-truth reconcile 형식, result artifact 작성 책임 분리(reviewer stdout vs caller/runner write)의 구현 형태는 Batch A/D 의 spec 대상.
- reviewer tool 교체 시 effort/safety override mechanism·output shape·artifact convention 재도출 필요(현재 mechanism 은 Codex CLI 0.132.0 기준 관찰).

## 11. 다음 single action

본 plan 채택(사용자 검토) 후 → **Batch A**(Gate 1·Gate 2 override surface·precedence 조사 + impl spec 작성, source 변경 없음)를 별도 scoped `/goal` 로 진입. 그 전까지 source/script/test/config 변경 및 implementation 진입 금지.
