# 리뷰 시스템 폴리싱 — adopted decision record (agent-blind / role-neutral, reviewer invocation safety 반영, 2026-06-01)

## Document character

본 문서는 리뷰 시스템 폴리싱 트랙의 **adopted decision record** 다 — review subsystem 의 durable decision record 로서 `docs/systems/review/` 아래에 배치돼 있다. 자체 완결적으로 읽히며, 이전 draft/report 파일을 열지 않아도 결정 전체를 이해할 수 있다.

- **성격**: review subsystem 의 채택된 decision record. operative policy 는 `caller` / `reviewer` role 기준이며 concrete agent/tool 에 bind 되지 않는다.
- **이것이 아닌 것**: plan 아님 / implementation spec 아님. **Implementation readiness: `no — plan/spec required`** — 구현은 본 문서만으로 시작하지 않는다. 본 record 의 채택은 implementation 승인이 아니다.
- **정직성 전제**: 어떤 결정도 방어하지 않는다. **U10 은 아직 검증되지 않았다**, 그리고 **reviewer-safe invocation 도 아직 보장되지 않았다** — 두 사실 모두 숨기지 않는다. final decision adoption `yes` 를 implementation approval 처럼 쓰지 않는다. reviewer read-only/no-silent-fix·packet hard requirements 를 약화하지 않고, hard requirements 를 broad semantic automation 으로 번역하지 않는다. operative policy 를 concrete agent/tool 이름에 bind 하지 않는다.
- **위치(maintenance 정합)**: 본 record 는 review subsystem maintenance posture(`docs/systems/review/STATUS.md`) 와 정합한다 — 정책 차원 adopted decision 이며, 실제 source/script/test 변경(plan → impl spec → 구현 + review gate)은 별도 scoped 작업이다.

## Provenance

Derived from the review-system polishing standalone decision record, 2026-06-01.

## Agent-blind / role-neutral policy

policy 는 agent 나 tool 이 아니라 **role 에 묶인다.**

- **`caller`** — review purpose 결정, baseline 재도출, packet preparation, validation evidence·Known concerns 제공, coverage selection, invocation packaging, effort/model selection, correction 적용, `corrected-state re-review` triggering, result artifact 기록, 최종 보고. *write/exec/approval capability 를 요구하는 profile.*
- **`reviewer`** — focused packet 을 받아 reviewed scope 안에서 independent findings·risks·limitations·assumptions·verdict/opinion 제공. orchestration 미소유. *read-only 또는 동등 guard profile; fixing·packet repair·approval 미포함.*

**agent-blind constraints**:
- operative policy 는 `caller`·`reviewer`·`reviewer invocation`·`reviewer output`·`reviewer verdict/opinion`·`caller packet`·`caller responsibility` 만 주어로 쓴다.
- current implementation 은 특정 CLI reviewer·local operator workflow·review-run pipeline 을 쓸 수 있으나, **본 policy 는 그 tool 에 bind 되지 않는다.**
- **reviewer tool 이 바뀌면 effort/model override mechanism·output/result shape·execution guard·artifact convention 은 재도출 대상.**
- 어떤 workflow 가 특정 artifact convention 을 갖지 않으면, final report 는 그 부재를 *disclose* 하고 동등물을 발명하지 않는다.

**role separation**: caller capability 와 reviewer guard 는 다른 profile 이다 — caller 는 baseline/validation 실행·packet 작성·correction·re-review orchestration·result artifact 기록을 위해 write/exec/approval 이 필요하고, reviewer 는 read-only/동등 guard 여야 하며 fixing·packet repair·approval 을 포함하지 않는다. role 을 교차 배치하는 workflow 는 role-model design space 이지 current capability claim 이 아니다.

## Canonical terminology

operative term 은 아래만 사용. `2-pass review`(familiar/legacy label), `vertical/horizontal`(폐기), `single-pass`(폐기)는 operative term 으로 쓰지 않으며 과거 표현 언급 시 legacy 로 표시.

- **`dual-perspective coverage`** = `local correctness review` + `system coherence review` 두 관점 충족. *coverage 정책, reviewer invocation count 아님.*
- **`local correctness review`** — 변경 파일/단위/구현 단위의 local correctness.
- **`system coherence review`** — 전체 goal·운영 흐름·cross-doc/contract/skill/script/test/policy coherence.
- **`single-invocation dual-perspective packet`** — 1회 reviewer invocation packet 으로 두 관점을 다룸. coverage 손실 0.
- **`two focused invocations`** — 두 관점을 별도 focused reviewer invocation 2개로 분리(보통 관점당 하나). coverage 손실 0.
- **`coverage-limited review`** — 한 관점 의도적 생략/축소. 진짜 coverage downgrade. caller rationale + final-report disclosure 필수.
- **`no-reviewable-change report`** — clean tree / reviewable diff 없음. caller-side report(reviewer verdict 아님).
- **`corrected-state re-review`** — `no`·caller 가 넘기기 어려운 `yes with risk`·relevant post-review mutation 이후 corrected state 재검토.
- **`corrective review loop`** — `corrected-state re-review` 의 반복. coverage·invocation count 와 다른 축.
- **`artifact pass-NN`** — review artifact attempt 번호. coverage·invocation count·`corrective review loop` 와 다른 축.

> `dual-perspective coverage` 는 업계 표준어가 아니라 *이 toolset 이 오해(횟수 혼동)를 줄이려 채택한 canonical operating term* 이다.

## User decisions incorporated

> 두 결정은 **CLOSED** — open risk 아님, incorporated decision constraint.

1. **Packet enforcement — CLOSED**: first-cycle enforcement = skill-text checklist + 기존 narrow mechanical gate. **새 semantic adequacy gate / concern completeness gate / evidence sufficiency gate / heavy automation 없음.** reviewer-side hard requirements 유지. semantic adequacy·concern completeness·evidence sufficiency 는 reviewer/operator judgment.
2. **Effort/model strategy — CLOSED**: first implementation 은 safe default 시작. **default = latest model + xhigh.** 명확히 단순한 `local correctness review` packet 만 downgrade. `system coherence review`-heavy / contract-sensitive / ambiguous / boundary-sensitive 변경은 high/xhigh 유지. 세부 category 는 first-cycle 운용 데이터 후 refine. **U10 이 실제 동작해야 U9 가 operational 로 보고될 수 있음.**

## Final readiness

> **layered — 단일 verdict 아님.**

- **Final decision adoption readiness: `yes`.** policy content 가 user-adopted final decision document 의 기반으로 쓸 수 있는 수준.
- **Implementation readiness: `no — plan/spec required`.** 구현은 본 문서만으로 시작하지 않는다.
- **U9 operational claim: `blocked until U10 is verified`.** U9 는 policy 로 채택 가능하나, U10 검증 성공 전엔 operational 로 기술하지 않는다.
- **Reviewer-safe invocation guarantee: `blocked until reviewer-safety override is verified`.** reviewer invocation 이 permissive global config 에 의해 무력화되지 않는다는 보장은 그 override 가 검증되기 전엔 주장하지 않는다(아래 §Reviewer invocation safety, §U10 hard gate).

**non-approval boundary**: 이 readiness 는 implementation 을 승인하지 않으며, commit/push/release/adoption/merge/publication/deployment 를 승인하지 않고, U10 이 이미 검증됐다거나 U9 가 operational 이라거나 reviewer-safe invocation 이 보장됐다고 주장하지 않는다.

> readiness 축 분리: adoption 축과 implementation/operational 축은 별개다. 두 user-decision 이 닫혀 *adoption 축* 은 `yes` 다. 남은 U10·reviewer-safety 불확실성은 실재하나 *adoption blocker 가 아니라* — 본 decision 이 이들을 plan/spec 의 first hard gate 로 명시했기에 — implementation/verification gate 다.

## U1~U10 decisions

> 분류: U1·U2·U4·U5·U6·U8 = split; U3·U7·U9·U10 = accept.

- **U1 (split)**: `dual-perspective coverage` default coverage posture + caller-side planner-as-guidance accept; `single-invocation dual-perspective packet`·`two focused invocations` packaging accept; disclosed `coverage-limited review`(저위험·caller rationale+disclosure) accept; **fixed two-invocation policy·reviewer-side self-selected coverage mode reject**; full auto-planner/auto-orchestrator defer. `dual-perspective coverage` 는 coverage policy 이지 reviewer invocation count 아님.
- **U2 (split)**: `no-reviewable-change report`(clean tree/no reviewable diff) accept; semantic auto-skip·undisclosed coverage reduction defer; **reviewer 가 caller disclosure 회피용으로 packet defect 를 silent repair 하지 않음.**
- **U3 (accept)**: approved scope 안 `no` → correction + `corrected-state re-review`; caller 가 넘기기 어려운 `yes with risk` → risk 감소 + re-review 또는 명시적 caller/user risk acceptance; relevant post-review source/doc/script/test mutation → evidence stale → `corrected-state re-review`; **reviewer mutation 이 발생하면 review invalidation risk.** `yes with risk` ≠ `yes`.
- **U4 (split)**: first-cycle packet enforcement = skill-text checklist + 기존 narrow mechanical gate(heading/field/path 존재, parser/result shape, reference closure) accept; 새 broad stale-review automation defer; **새 semantic adequacy gate·concern completeness gate·evidence sufficiency gate·auto-fix·auto-approval·heavy automation reject.**
- **U5 (split)**: fresh inspected evidence > stale summary + 충돌 surface accept; validation evidence 는 caller 제공·reviewer-readable; **missing evidence 는 limitation/risk 이지 reviewer 가 silent 재구성하는 것 아님**; broad formal source-of-truth hierarchy defer.
- **U6 (split)**: repo root·branch·HEAD·origin/main(가능 시)·changed files·final git status·intended target boundary 의 hard packet/report requirement accept; repo/baseline ambiguity 는 reviewer quality risk; 자동 primary/target/global detection mechanism defer.
- **U7 (accept)**: 10-field final report schema 요구(아래) + **`artifact pass-NN` 없으면 `N/A — no artifact pass-NN`(발명 금지)**.
- **U8 (split)**: 신규 규율 portable-first + role-neutral policy 언어 accept; 기존 toolset-specific wording 대규모 retrofit defer; **agent/tool 이름은 source provenance / current implementation note 로만.**
- **U9 (accept)**: role-neutral effort/model tiering policy + implementation intent. first implementation default = latest model + xhigh; 명확히 단순한 `local correctness review` packet 만 downgrade; `system coherence review`-heavy·contract-sensitive·ambiguous·boundary-sensitive 는 high/xhigh; 세부 category 는 운용 데이터 후. **U10 검증 전 U9 operational 아님.**
- **U10 (accept)**: per-invocation effort override = U9 operationalization 의 **first hard gate**(current reviewer tool target). **U10 검증 전 어떤 보고도 U9 operational 주장 금지.** 정확한 override surface·허용값·실패거동·run-fact 검증 = plan/spec + implementation/review gate. **U10 의 검증 범위에는 reviewer invocation safety override 가 permissive global config 에 의해 무력화되지 않는지도 포함된다(아래 §Reviewer invocation safety).** **reviewer tool 교체 시 mechanism 재도출.**

## Accepted invariants

1. `dual-perspective coverage` = `local correctness review` + `system coherence review`; coverage policy 이지 invocation count 아님.
2. caller 가 orchestration·packet preparation·coverage selection·invocation packaging·correction·`corrected-state re-review` trigger·result artifact 기록 소유.
3. reviewer 는 받은 focused packet 에 대한 independent judgment 소유; caller-side orchestration 미소유.
4. fixed reviewer invocation count 미요구.
5. `single-invocation dual-perspective packet` 은 한 packet 에서 두 관점이 독립 review 가능하면 coverage 손실 없음.
6. `two focused invocations` 는 packet 크기·위험·coherence surface·evidence 복잡도가 결합 packet 의 독립 판단 품질을 떨어뜨릴 때 선호.
7. `coverage-limited review` 는 진짜 coverage downgrade — caller rationale + final-report disclosure 필요.
8. `no-reviewable-change report` 는 caller-side status, reviewer verdict 아님.
9. `corrective review loop`·reviewer invocation count·`artifact pass-NN` attempt count 는 별개 축.
10. `yes with risk` 를 `yes` 로 소비 금지; 명시적 risk acceptance 또는 re-review path 필요.
11. reviewer verdict/opinion 은 commit/push/release/adoption/merge/publication 승인 아님.
12. high effort/model 선택은 missing evidence·poor packet framing·stale baseline·omitted Known concerns·unclear scope 를 보상하지 못함.
13. repo boundary·baseline ambiguity 는 reviewer quality risk 이며 caller 가 disclose.
14. **role-neutrality binding**: policy 는 `caller`·`reviewer` role 에 묶이며 어떤 agent/tool binding 도 정책 요건 아님.
15. semantic adequacy·concern completeness·evidence sufficiency 는 reviewer/operator judgment(기계화 금지).
16. effort/model ⟂ coverage; effort 로 coverage 줄이지 않음; downgrade 금지 class 보존.
17. Known concerns·validation evidence 의 정직성은 기계로 대체 불가 — caller honesty 전제.
18. reviewer read-only / no-silent-fix(아래 별도 절).
19. **U9 operational status 는 U10 검증 전까지 blocked.**
20. **reviewer invocation safety 는 global user config 에 의존하지 않는다 — reviewer 의 read-only/no-silent-fix 보장은 permissive global config 가 있어도 review runner / reviewer invocation path 가 명시한 reviewer-safe override 로부터 와야 한다(아래 §Reviewer invocation safety).** (accepted invariant 19개 + 본 safety invariant.)

## Reviewer read-only / no-silent-fix invariants

reviewer execution 은 **read-only 또는 동등하게 guard 된** 환경이어야 한다.

- reviewer 는 review 중 source·docs·scripts·tests·global files·user files·review packet·evidence·runtime artifact 를 **mutate 하지 않는다.**
- reviewer 는 review 중 **fix 하지 않는다.**
- reviewer 는 **packet defect 를 silent repair 하지 않는다.**
- reviewer 는 **missing evidence 를 local context 로 silent 재구성하지 않는다.**
- reviewer 는 **scope 를 silent 확장하지 않는다.**
- reviewer 는 missing path·missing evidence·stale evidence·unclear baseline·omitted concern·scope ambiguity 를 **limitation / evidence gap / risk / finding / re-review requirement 로 보고** 한다.
- reviewer output 은 commit/push/release/adoption approval 이 아니며, caller/user risk acceptance 를 암묵 가정하지 않는다.

**execution-environment requirement**: reviewer 는 read-only 또는 동등 guard 환경에서 동작해야 한다. **이 guard 는 global user config 에 의존해선 안 된다 — review runner / reviewer invocation path 가 명시한 reviewer-safe override 로 보장돼야 한다(아래 §Reviewer invocation safety).** **구조적 read-only guard 가 없으면 reviewer 는 read-only posture·no-silent-fix·no-commit/push·boundary stop/report 를 명시적으로 self-impose 하고, *구조적 guard 부재* 자체를 risk 로 disclosure 한다.** mutation-capable reviewer tool 은 overreach risk 가 구조적으로 더 크다 — 이 risk 를 숨기지 않는다(role-model design space 이며 capability claim 아님).

## Reviewer invocation safety (no reliance on permissive global config)

> reviewer 의 read-only/no-silent-fix invariant 는 *환경* 이 그것을 구조적으로 보장할 때 가장 강하다. 그러나 global user config 가 operator 편의로 wide-open 이면 그 보장이 무력화될 수 있다 — 이 절은 그 경로를 닫는다.

원칙(role-neutral):

1. **reviewer invocation 은 safety 를 global user config 에 의존하지 않는다.**
2. **review runner / reviewer invocation path 는 global config 가 permissive 하더라도 reviewer-safe override 를 명시해야 한다.** (즉 safety 는 *기본값에 기대지 않고* invocation 단에서 강제된다.)
3. reviewer 는 **read-only 또는 동등하게 guard 된** 환경에서 동작해야 한다.
4. reviewer 가 source/docs/scripts/tests 를 직접 mutate 할 수 있는 권한으로 실행되는 경우, **구조적 guard 없는 상태로 보고하고 그 risk 를 disclosure** 한다(조용히 진행 금지).
5. **preferred pattern**: reviewer 는 판단 결과를 stdout 또는 controlled output 으로 내고, **caller / review runner 가 result artifact 를 기록** 한다(result artifact 작성 책임을 reviewer 에서 분리).
6. reviewer 가 result artifact 를 *써야 하는* 구조라면, **source tree·review target 은 read-only 로 유지** 하고 writable surface 는 **review output location 으로 제한** 한다.
7. 이 safety override 는 **U10 hard gate 와 함께 plan/spec 의 first hard gate** 로 취급한다.
8. **U10 검증은 effort/model override 뿐 아니라 reviewer invocation safety override 가 global config 에 의해 무력화되지 않는지도 확인** 해야 한다.
9. **U10 검증 전에는 U9 operational claim 뿐 아니라 reviewer-safe invocation 이 보장된다고도 주장하지 않는다.**

> **Current implementation note(provenance/example only, operative policy 주어 아님)**: 현재 reviewer 로 쓰이는 CLI tool 의 global user config 가 operator 편의상 full-access / never-approval 류(예: `danger-full-access`, `approval_policy = never`)로 설정될 수 있음이 관찰됐다. 그런 설정은 operator 작업엔 편리하나 reviewer invocation 에 그대로 적용되면 위 read-only/no-silent-fix invariant 를 구조적으로 약화한다 — 그래서 review runner 가 reviewer-safe override 를 *명시* 해야 한다. 이 토큰들은 현재 구현 예시일 뿐 정책 주어가 아니다.

**result artifact 작성 책임 분리(요약)**: *판단* 은 reviewer(stdout/controlled output), *기록* 은 caller/review runner. reviewer 가 직접 써야 하는 구조면 writable surface 를 review output location 으로 한정하고 source tree·review target 은 read-only 유지.

## Skill behavior decisions

review skill(+ 관련 contract) 1차 skill-text(프로젝트 비종속, role-neutral):
- **self-gate**: reference class 열거·sweep 결과를 packet 의 Known concerns/validation evidence 에 보고 강제; citation-provenance 본문 확인; baseline 재도출; 정직 framing; scope residue disclose.
- **planner-as-guidance 체크리스트**(judgment-guiding, 자동 orchestration 아님): baseline → 변경 class → coverage 결정 → packaging 결정 → effort/model 선택 → packet 작성 + reviewer 호출(reviewer-safe override 명시) → finding 분류 + `corrected-state re-review` → result artifact 기록(caller/runner) → 표준 보고.
- **packet 구성 규율**(아래 §Reviewer input packet requirements) — *skill-text checklist 로*(새 gate 아님).
- **짧은 review 명령 최소 확장**: baseline + self-gate + coverage/packaging 판단 + reviewer-safe focused 호출 + 표준 보고.
- **finding framing + freshness invariant + reviewer read-only/no-silent-fix 문구 + reviewer invocation safety 문구**; **output contract 처방**(verdict vocabulary·shape 중앙화 + 말미 1회; output/result shape 는 reviewer-tool-specific → tool 교체 시 재도출); **표준 최종보고 schema**(아래 §Final report schema).

## Reviewer input packet requirements

hard requirements(유지; enforcement 는 skill-text checklist):
- **General**: review purpose·정확한 review questions · scope·exclusions·intended target boundary · repo root·branch·HEAD·origin/main(가능 시)·working tree status·changed files · required inspection paths(question 연결, 실제 존재) · reviewer-readable validation evidence(또는 명시적 validation limitation) · Known concerns·assumptions·skipped alternatives·compromises·stale evidence concern·baseline limitation(결론 유도 금지) · 중립 framing(blocking findings·evidence gap·framing tilt 유도) · `coverage-limited review` 면 명시 disclosure.
- **`local correctness review` packet**: 변경 파일·구현 단위; 기대 동작·acceptance criteria; 인접 tests/scripts/docs/contracts; edge case·local 한계; local correctness evidence.
- **`system coherence review` packet**: 전체 goal·운영 흐름; coherence 판단에 필요한 cross-doc/contract/skill/script/test/policy paths; source-of-truth 기대·known conflict; 영향 workflow boundary; system-level evidence(또는 absent 명시); drift/partial-migration/fallback/framing/policy-mismatch 우려.

**packet defect rule**: **missing path·evidence·scope·baseline·Known concern 은 reviewer 가 silent repair 하지 않는다.** caller 가 packet 을 보강하거나 `coverage-limited review` 를 disclosure 하거나 reviewer 의 limitation/risk/re-review output 을 수용한다.

## Packet enforcement decision

[user-decision 1 — CLOSED]
- **accepted first-cycle enforcement**: skill-text checklist + 기존 narrow mechanical gate(required heading 존재, required field 존재, 명시 path 존재, parser/result shape, required evidence bundle 존재, 명시 required-path reference closure).
- **not added(이번 cycle)**: semantic adequacy gate, concern completeness gate, evidence sufficiency gate, broad semantic lint, auto-fix, auto-approval, heavy automation.
- **judgment boundary**: semantic adequacy·concern completeness·evidence sufficiency 는 reviewer/operator judgment. **mechanical pass 는 packet 이 *구조적으로 inspectable* 하다는 뜻일 뿐 *substantively sufficient* 함을 증명하지 않는다.**
- **hard requirements 는 여전히 hard requirements 다 — conservative enforcement 를 packet 품질 의무 약화에 쓰지 않는다.**

## Effort / model tiering decision

[user-decision 2 — CLOSED]
**role-neutral policy**: U9/U10 은 문서만이 아니라 실제 구현까지 이어진다; default = latest model + xhigh; 명확히 단순한 `local correctness review` packet 만 medium/high downgrade; **downgrade 금지(high/xhigh 유지)**: `system coherence review`-heavy, contract-sensitive(parser/machine-readable output·verdict contract), ambiguous, boundary-sensitive(security/permission/sandbox/global·user config), multi-doc+script, skill+contract+script 동시, baseline-failure 검증, 운영규칙+구현 동시, delete/rename/restructure, 다문서 status 정합. **effort/model ⟂ coverage**(effort 로 coverage 안 줄임); downgrade/lower-effort 시 rationale·residual risk 를 final report 에; high effort 는 poor packet 보상 못 함; 세부 category 는 운용 데이터 후.

**current implementation note**: current implementation 은 특정 reviewer tool 의 per-invocation effort override 를 쓸 수 있다. **U10 동작이 U9 operational 의 전제.** 정확한 override surface·허용값·실패거동·run-fact 검증 = plan/spec + impl/review gate.

**reviewer-tool change rule**: reviewer tool 교체 시 effort/model override mechanism 재도출; equivalent override 없으면 final report 에 `not available`/`not applicable`/`not verified`; output/result shape·artifact convention·reviewer-safe override 도 reviewer-tool-specific 일 수 있어 재도출.

## U10 hard gate for U9 operationalization (+ reviewer-safety override)

U10 은 U9 operationalization 의 **first hard gate** 이며, **reviewer invocation safety override 검증을 함께 포함** 한다.

**검증 전 필요한 것(effort/model)**: current reviewer tool 의 per-invocation effort override mechanism 식별; 정확한 config 키/invocation surface 확인; 허용값(xhigh 포함) 확인; override 가 missing/invalid/unsupported 일 때 거동 확인; 의도한 model/effort 적용을 보이는 run-fact 확보(또는 *검증 불가* 명시 보고); 설정 거동에 대한 테스트/동등 evidence; 실패 거동을 final report/review-run output 에 반영.

**검증 전 필요한 것(reviewer-safety override)**: review runner / reviewer invocation path 가 **permissive global user config 가 있어도 reviewer-safe override(read-only / no auto-approval / writable surface = review output location 한정)를 명시·강제** 하는지 확인; global config 가 그 override 를 무력화할 수 있는 경로가 있는지 점검; reviewer 가 mutation-capable 로 실행될 수밖에 없는 경우 그 사실이 보고·disclosure 되는지 확인.

**U10/safety 검증 전 허용**: U9 를 policy 로 채택; safe default 문서화; config schema 설계; reviewer-safe invocation 설계; implementation sequencing 계획.

**U10/safety 검증 전 금지**: U9 가 operational 이라는 주장; latest model + xhigh 가 실제 per-reviewer-invocation 적용된다는 주장; downgrade 규칙이 running reviewer invocation 에서 강제된다는 주장; U9 를 reviewer quality 개선 evidence 로 사용; **reviewer-safe invocation 이 보장된다는 주장.**

**이 gate 는 final decision adoption blocker 가 아니다** — operational/safety claim 전의 첫 plan/spec + implementation/review gate 다. **U10 도 reviewer-safe invocation override 도 아직 검증되지 않았다 — 두 사실 모두 숨기지 않으며, agent-blindness 가 이 current implementation risk 를 흐리게 하지 않는다. U10 은 vague implementation detail 이 아니라 명시된 first hard gate 다.**

## Mechanical precheck vs reviewer judgment

**mechanical precheck 가 검증할 수 있는 것(narrow·objective)**: required heading 존재; required field 존재; 명시 path 존재; parser-sensitive result shape; required evidence bundle 존재; (해당 workflow 존재 시) `artifact pass-NN` result binding; 명시 required inspection paths 의 reference closure.

**reviewer/operator judgment 로 남는 것**: evidence 충분성; Known concerns 완전성·정직성; review question 중립성; `single-invocation dual-perspective packet` 이 독립 판단에 과대한지; `two focused invocations` 가 품질 개선하는지; `coverage-limited review` rationale 신뢰성; `yes with risk` 수용 가능성; mutation 이 prior evidence 를 stale 하게 만들어 `corrected-state re-review` 가 필요한지.

원칙: **기계는 packet 을 읽을 수 있는 사건 파일로 만들고, reviewer 는 그 사건 파일이 안전한지 판단한다.** mechanical pass 는 substantive sufficiency 를 증명하지 않는다.

## Script / config candidate decisions

기계적·범용·비특화·conservative:
- **per-invocation effort override(U10)** — review-run 측 enabling; U9 operationalization 의 first hard gate; current reviewer-tool-specific(override surface 실측 plan/spec); reviewer tool 교체 시 재도출.
- **reviewer-safe invocation override(review runner)** — review runner 가 permissive global config 와 무관하게 reviewer invocation 을 read-only / no auto-approval / writable surface = review output location 으로 강제. **U10 과 함께 first hard gate.** override surface·강제 방식은 reviewer-tool-specific → 교체 시 재도출.
- **effort/model config `category→{model,effort}` mapping lookup(U9)** — schema portable, 값 per-project, **1차엔 safe-default 만**(세부 category 후속).
- **reference-closure grep 헬퍼** — case-insensitive full-path + bare-filename, path normalization·`.`/`..` bypass 테스트; semantic 한계 명시.
- **기존 narrow input-verify 게이트 유지/소폭**(semantic gate 확대 금지 — user-decision 1).
- **캡처·보고성**: baseline facts·changed-file list capture, `artifact pass-NN` result binding(해당 workflow 존재 시), (U10 검증 후) per-invocation model/effort run facts, **reviewer-safe invocation 적용 run-fact**.
- **result artifact 기록 책임**: reviewer 는 stdout/controlled output, caller/review runner 가 result artifact 기록(writable surface = review output location).
- **caller capability caveat**: caller 책임은 write/exec/approval capability 요구 — read-only reviewer 와 다른 profile, 혼동 금지.

## Human / caller judgment boundaries

**caller responsibilities**: review scope·purpose 선택; packet 구성 전 baseline 재도출; required inspection paths·evidence 제공; Known concerns·validation limitation disclose; invocation packaging 선택; **reviewer invocation 을 reviewer-safe override 로 실행(global config 비의존); reviewer 가 mutation-capable 로 실행될 수밖에 없으면 그 사실 disclosure**; packet enforcement decision 적용(hard requirement 약화 금지); safe default·downgrade 제한에 따른 effort/model tier 선택; U10 + reviewer-safety 검증을 U9 operational·reviewer-safe claim 전 first hard gate 로 취급; result artifact 기록; `no`·caller-hard `yes with risk`·relevant post-review mutation 후 `corrected-state re-review` trigger; commit/push/release/adoption 을 reviewer verdict/opinion 과 분리 결정.

**reviewer boundaries**: packet 평가 후 findings·risks·assumptions·limitations 보고; 구현 수정·docs patch·packet defect 수리·commit/push 승인 안 함; **판단 결과를 stdout/controlled output 으로 내고 result artifact 작성 책임은 가져오지 않음(구조상 직접 써야 하면 writable surface = review output location 한정)**; packet 이 independently reviewable 아님을 식별 가능; narrower packet·`two focused invocations`·`corrected-state re-review` 권고 가능.

**human/user boundaries**: 최종 adoption·explicit risk acceptance 소유; packet enforcement·effort/model strategy 의 user-decision 은 이미 incorporated; **future implementation risk acceptance(U10·reviewer-safety 포함) 는 plan/spec·impl/review gate 소관이지 final decision adoption readiness 소관 아님.**

## Final report schema decision

10-field 분리(role-neutral):

| # | 필드 | 내용 |
|---|---|---|
| 1 | perspective coverage | `dual-perspective coverage` / `coverage-limited review`(+ 생략·축소 관점·rationale) / `no-reviewable-change report` |
| 2 | invocation packaging | `single-invocation dual-perspective packet` / `two focused invocations` / 기타 disclosed packaging shape |
| 3 | invocation count | reviewer 실제 호출 횟수(품질 보증 아님) |
| 4 | artifact pass count | `artifact pass-NN` attempt 수; 없으면 **`N/A — no artifact pass-NN`(발명 금지)** |
| 5 | corrective loop count | `corrective review loop` 반복 횟수(별도 축) |
| 6 | re-review status | `not needed` / `needed` / `completed` / `stale due to mutation` / `not applicable` |
| 7 | verdict / risk handling | `yes`/`no`/`yes with risk` 소비 방식; `yes with risk` = risk acceptance 또는 re-review path 필요 |
| 8 | validation evidence | 사용한 validation evidence + 한계 |
| 9 | final git status | 최종 worktree 상태 + changed files |
| 10 | commit/push recommendation | next-action recommendation, approval 아님 |

보조(optional): invocation path·run id·corrections applied·remaining risks·**reviewer execution guard status(read-only / mutation-capable+disclosed)**.

**U9/U10·safety reporting**: U10 검증 전 final report 는 U9 를 operational 로, reviewer-safe invocation 을 보장됨으로 기술하지 않는다; 검증 후엔 effort/model 적용 run-fact·reviewer-safe override 적용 evidence 포함; mechanism/override 검증 불가 시 `not verified`(성공 암시 금지). "pass-02 yes" 식 단일 표기 금지(coverage/attempt/corrective 구분 불가).

## Remaining risks / open questions

**A. Final decision adoption risk** — *blocker 없음.* 단 본 decision 을 propagate/승격할 때 (a) 두 closed user-decision 을 정확히 보존하고, (b) final decision adoption readiness ↔ implementation readiness 구분을 보존하며, (c) **reviewer invocation safety / global-config 비의존 원칙을 약화하지 않아야** 한다. propagate 시 U10 hard gate·reviewer read-only·reviewer-safety override·packet hard requirements·`yes with risk` handling 을 약화하면 *새* adoption risk 발생.

**B. plan/spec hard gate** (U10 + reviewer-safety = 첫 hard gate):
- per-invocation effort override surface·허용값·실패거동·run-fact 검증; **reviewer-safe invocation override 가 permissive global config 에 의해 무력화되지 않는지 검증 설계**; config schema(default latest+xhigh, downgrade 제한); report 10-field template/parser enforcement 범위; `N/A — no artifact pass-NN` 표현; U10·safety→U9 sequencing over-scope 회피; packet enforcement narrow 유지하며 hard requirement 보존; fresh-evidence ↔ contract-as-SoT reconcile 형식; result artifact 작성 책임 분리(reviewer stdout vs caller/runner write)의 구현 형태.

**C. implementation / review gate risk**:
- per-invocation override 가 current reviewer workflow 에서 *실제* 동작(run-fact); **review runner 가 wide-open global config 아래서도 reviewer-safe override 를 실제 강제하는지(테스트)**; narrow mechanical gate 가 semantic gate 로 확대되지 않음(테스트); skill-text checklist 가 reviewer hard requirements 보존; 생성 packet 이 Known concerns·validation limitation 정직 disclose; reviewer read-only/no-silent-fix·writable-surface 제한 유지; final report 가 coverage/packaging/invocation count/`artifact pass-NN`/`corrective review loop`/re-review status·**reviewer guard status** 분리; 구현 변경이 `dual-perspective coverage` review 통과(skill+contract+script+tests 동시 = 유지 class, `two focused invocations` 고려).

**확실 / 추론**: 확실 — 두 user-decision 닫힘; U1~U10 분류 불변; U10·reviewer-safe override 는 미검증·U9 operational/reviewer-safe claim 전 필수; adoption 차원 blocker 없음. 추론 — 가장 강한 residual 은 decision 모호성이 아니라 *구현 fidelity*(구현이 U10·reviewer-safety override·conservative enforcement·reviewer read-only 를 충실히 옮기는지); layered readiness 가 가장 정직한 표현.

## Key invariants to preserve downstream

downstream plan/spec/implementation/propagation 시 *반드시 유지* 할 문장:
1. "Final decision adoption readiness = `yes`; implementation readiness = `no — plan/spec required`; U9 operational claim = U10 검증 전 blocked; reviewer-safe invocation guarantee = reviewer-safety override 검증 전 blocked. 이 readiness 는 commit/push/release/adoption/implementation 승인 아님."
2. "policy 는 `caller`·`reviewer` role 에 묶이며 어떤 specific agent/tool 에도 bind 되지 않는다."
3. "reviewer tool 이 바뀌면 effort/model override mechanism·output/result shape·artifact convention·reviewer-safe override 는 재도출."
4. "`dual-perspective coverage` 는 coverage policy 이지 reviewer invocation count 아님."
5. "`single-invocation dual-perspective packet` 은 두 관점이 한 packet 에서 독립 review 가능하면 coverage 손실 없음."
6. "`coverage-limited review` 는 진짜 coverage downgrade — caller rationale + final-report disclosure 필요."
7. "first-cycle packet enforcement = skill-text checklist + 기존 narrow mechanical gate; 새 semantic adequacy/concern completeness/evidence sufficiency gate·heavy automation 없음."
8. "semantic adequacy·concern completeness·evidence sufficiency 는 reviewer/operator judgment."
9. "effort/model default = latest model + xhigh; 명확히 단순한 local packet 만 downgrade; `system coherence review`-heavy·contract-sensitive·ambiguous·boundary-sensitive 는 high/xhigh; 세부 category 는 운용 데이터 후."
10. "U10 per-invocation effort override 가 실제 동작해야 U9 가 operational 로 보고될 수 있다; U10 검증 전 U9 operational 주장 금지; U10 은 plan/spec 의 first hard gate 이며 adoption blocker 아님; U10 은 vague implementation detail 아님."
11. "reviewer execution 은 read-only 또는 동등 guard; reviewer 는 fix·silent packet repair·silent evidence reconstruction·silent scope expansion·commit/push approval 하지 않음; 구조적 guard 없으면 self-impose + disclosure."
12. "missing path/evidence/scope/baseline/concern 은 reviewer 가 silent repair 하지 않고 limitation/risk/re-review 로 보고."
13. "final report 10-field 분리; `artifact pass-NN` 없으면 `N/A — no artifact pass-NN`(발명 금지); re-review status enum; post-review(또는 reviewer) mutation → stale → `corrected-state re-review`; corrective loop·invocation count·`artifact pass-NN` 는 별개 축."
14. "`yes with risk` ≠ `yes`; risk acceptance 또는 re-review path 없이 approval 소비 금지; reviewer verdict/opinion 은 commit/push/release/adoption approval 아님."
15. "reviewer invocation 은 safety 를 global user config 에 의존하지 않는다; review runner / reviewer invocation path 는 permissive global config 가 있어도 reviewer-safe override(read-only / no auto-approval / writable surface = review output location 한정)를 명시·강제한다."
16. "reviewer 가 mutation-capable 권한으로 실행될 수밖에 없으면 구조적 guard 부재를 보고·disclosure 한다; preferred pattern 은 reviewer = stdout/controlled output, caller/review runner = result artifact 기록."
17. "reviewer-safety override 검증은 U10 과 함께 plan/spec 의 first hard gate; 검증 전 reviewer-safe invocation 이 보장된다고 주장하지 않는다."

**propagate caution**: 두 accepted user-decision 을 unresolved wording 으로 되돌리지 말 것; **operative policy 를 concrete agent/tool 이름에 bind 하지 말 것**; U10·reviewer-safety override 를 adoption blocker 로도 vague implementation detail 로도 만들지 말 것(first hard gate 유지); conservative enforcement 를 weak requirement 로 낮추지 말 것; hard requirement 를 broad semantic automation 으로 번역하지 말 것; final decision adoption `yes` 를 implementation approval 로 취급하지 말 것; **reviewer invocation safety 를 global config 에 의존하도록 약화하지 말 것**; U10·reviewer-safe override 미검증 사실 은폐 금지.
