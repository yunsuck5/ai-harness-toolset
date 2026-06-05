# 리뷰 시스템 — validation evidence vs reviewer reproduction opt-in policy (planning/design doc, 2026-06-04)

> **Status (implemented — done) — 구현 commit `fdb9fe1`(작성 plan-doc commit `9d77986`).** 이 문서가 정한 reviewer-reproduction opt-in 정책(기본 *local validation evidence inspection*; broad reproduction 은 review input 에서 명시 authorize 시에만)은 **구현됐다** — `docs/contracts/review/REVIEW_RESULT_CONTRACT.md` §3d + `templates/review-input.md` + `snippets/claude-skills/ai-harness-review/SKILL.md` 에 반영(현 상태 source-of-truth: `docs/systems/review/STATUS.md` governance increments bullet; Batch-D deferred "validation reproducibility in sandbox" 신호 deferred→done). 본 문서는 그 정책의 **durable design source-of-truth** 로 보존된다. 아래 본문의 plan-time 표현(예: "Status (planning — not implemented)", "아직 수정되지 않았다", deferred 신호, "STATUS 는 이것을 deferred 후보로 명시한다", 조건부-closeout)은 **작성 시점 design-time 기록**이며 current-state claim 이 아니다 — 현재 상태는 위 STATUS bullet 이 권위다.

## Document character

- **성격**: design/plan 문서. **implementation 아님 / parser·verifier·runtime 변경 아님 / operational claim 아님 / 승인 문서 아님.** 이 문서의 어떤 분석도 implementation surface 변경을 수행하거나 commit/push 를 승인하지 않는다. "권장(recommended)" 은 구현 확정이 아니라 design 후보다.
- **track 위치 (중요)**: 이 작업은 review subsystem 의 **RV-B-04 ("Review subsystem no-exec / no-write reviewer contract")** 우산 아래의 후속 batch 다 — reviewer 가 *무엇을 하지 않는가*(no opportunistic exec)를 reviewer-role boundary 로 명문화하는 작업으로, RV-B-04 의 R1 first batch(Markdown validation evidence convention, `2997bb3`)가 evidence **inspection** 측을 닫은 데 이어 **reproduction/execution** 측을 정한다. opt-in authorization 의 *input-측 shape* 은 **RV-B-05 (review input governance)** 와 인접하다. 구체적 deferred 신호는 `docs/systems/review/STATUS.md` Batch D 마무리 항목의 "validation reproducibility inside the reviewer's read-only sandbox (Pester / `verify-ps1` / `git check-attr` not re-runnable there)" 다(이 문서가 그 deferred 신호의 design home — 그 후 본 트랙 구현으로 deferred→done, contract §3d). **RV-B-06(reviewer runtime provenance) 재오픈 아님**, **`.md` EOL/autocrlf 트랙 아님**, **full-suite-green closeout policy 아님**, **design verdict vocabulary 아님**(§2, §10).
- **source of truth / 권위 순서**: 상위 권위는 `docs/contracts/review/REVIEW_RESULT_CONTRACT.md`(특히 §3a Markdown validation evidence convention, §3b mechanical behavior claim verification, §6 blocking 정의 중 sandbox/capability 한계 항목)이며, 그 다음이 `templates/review-input.md`(`## Validation evidence` guidance)와 `snippets/claude-skills/ai-harness-review/SKILL.md`(reviewer/operator-facing wording)다. 충돌 시 contract 가 이긴다. evidence file 본문 shape 의 권위는 `docs/contracts/evidence/EVIDENCE_CONTRACT.md` 다. 이 문서는 그 위에 얹히는 **track design home** 이며, contract/template/skill 의 기존 의미를 재정의하지 않고 **명시되지 않은 boundary(opt-in reproduction)를 추가로 codify** 한다.
- **single-home-plus-pointers (docs operating model 준수)**: 이 문서는 `docs/systems/review/STATUS.md`(completed/deferred ledger)·`docs/systems/review/BACKLOG.md`(RV-B-04/RV-B-05 triage row) 의 내용을 **복제하지 않는다**. 그 두 곳의 ledger/triage 항목은 pointer 로만 참조하고, 이 문서는 *design/plan* 만 담는다 (`docs/policies/DOCS_OPERATING_MODEL.md` §1 single-home, §3 layer roles, §4 STATUS altitude).
- **placement / naming 근거**: 위치 `docs/systems/review/` 는 이 subsystem 의 track design/spec/plan 문서가 모이는 곳이다(`REVIEW_RESULT_PROVENANCE_SPEC.md` / `REVIEW_POLISHING_IMPLEMENTATION_PLAN.md` / `REVIEW_INPUT_KNOWN_CONCERNS_HYPOTHESIS_FORM_PLAN.md` / `REVIEW_RUNNER_STDOUT_ANCHOR_TEST_PLAN.md`; `docs/README.md` §5 `docs/systems/` 레이어, §6 신규 문서 위치). 파일명은 그 docs 의 `REVIEW_<subject>_<KIND>` 패턴을 따른다 — `VALIDATION_EVIDENCE_REPRODUCTION_POLICY` 는 기존 `## Validation evidence` surface 와 새 reviewer-reproduction 정책을 동시에 가리키고, `_PLAN` 은 본 문서의 planning 성격을 나타낸다. 대안으로 `REVIEW_REVIEWER_REPRODUCTION_OPT_IN_POLICY_PLAN.md` 도 고려했으나, 정책의 anchor 가 기존 `## Validation evidence` convention(reviewer 가 *inspect* 하는 대상)이고 그것과의 대비(evidence-inspect vs reproduction)가 이 트랙의 핵심이므로 evidence 를 파일명에 두는 쪽을 택했다.

## 1. 목적 (Purpose)

1. **local validation evidence 와 reviewer reproduction 의 역할을 명시적으로 분리한다.** local operator 는 validation / build / test 를 *자신의 환경에서 실행* 하고 그 사실을 evidence 로 남기며(§3a R1 convention, `docs/contracts/evidence/EVIDENCE_CONTRACT.md`), reviewer 는 그 evidence 와 diff/contract 를 *inspect* 한다. 이 둘은 서로 다른 책임이다.
2. **reviewer reproduction 은 opt-in 이며 opportunistic default 가 아님을 명문화한다.** reviewer 는 read-only sandbox 가 *실행 가능해 보인다는 이유만으로* validation / build / test command 를 재실행하지 않는다. reviewer 의 command 실행은 review input 에서 **명시적으로 authorize** 된 경우에만 가능하며, 그 authorization 은 command scope·side-effect boundary·interpretation rule 을 함께 명시해야 한다.
3. **reviewer 의 sandbox 재실행 불가(또는 미실행)가 자동으로 target risk 가 되지 않음을 codify 한다.** 기본은 evidence inspection 이고, 재실행하지 못한 사실은 `## Review limitations` 에 기록되는 review limitation 이지 target defect 가 아니다 — target risk 로 승격하려면 별도의 독립 근거(§7)가 필요하다.

이 정책은 RV-B-04 R1 이 이미 닫은 *evidence-inspection* 측(§3, criteria 1·2)을 약화하지 않고, 거기에 명시되지 않은 *reproduction/execution* 측 boundary 를 더한다. 또한 §3b 의 *minimal reproducible check*(mechanical behavior claim 에 대해 reviewer 가 *기대* 되는 narrow inspection-grade 점검)와 **모순 없이 구분** 되도록 경계를 그리는 것이 본 트랙의 핵심 design subtlety 다(§3.4).

## 2. Track 위치 — RV-B-04 우산, RV-B-05 인접, 무엇이 아닌가

- **RV-B-04 우산**: `docs/systems/review/BACKLOG.md` 의 RV-B-04 row 는 "contract-level reviewer-role boundary: explicitly frame what the reviewer does **not** do (no exec, no write)" 이며, **R1 first batch 가 evidence convention 으로 닫혔다**(`## Validation evidence` informational input section + reviewer-readable runtime supporting material boundary — not command re-execution / not deterministic truth oracle / not freshness binding / not source-of-truth). 본 트랙은 그 row 의 *exec 측* residual — reviewer 가 *언제 command 를 실행해도 되는가* 를 정한다.
- **STATUS Batch-D deferred 신호**: `docs/systems/review/STATUS.md` 의 Batch D 마무리 항목이 "validation reproducibility inside the reviewer's read-only sandbox (Pester / `verify-ps1` / `git check-attr` not re-runnable there)" 를 **non-mainline deferred/optional polishing 후보** 로 명시했었다(Batch D blocker 아님). 이 문서가 그 deferred 신호의 design home 이다. [정정(post-impl): 이 deferred 신호는 그 후 reviewer-reproduction opt-in 정책 구현으로 **deferred→done** 됨(`docs/contracts/review/REVIEW_RESULT_CONTRACT.md` §3d; STATUS 의 governance increments bullet 에 resolved 기록). STATUS 의 해당 항목명도 그 후 "Batch D mainline complete (D1→D2→D3; no D4)" 로 rename 됨.]
- **RV-B-05 인접(우산 아님)**: opt-in authorization 을 *review input 의 어디에 어떤 모양으로* 적느냐(§5)는 review input governance(RV-B-05) 의 성격을 갖는다. 그러나 본 트랙의 *핵심 정책* 은 reviewer 의 execution boundary(RV-B-04)이며, RV-B-05 의 disclosure-shape / framing-tilt convention 을 재오픈하지 않는다.
- **무엇이 아닌가 (혼입 금지, §10)**: **RV-B-06 reviewer runtime provenance 재오픈 아님**(result.md provenance block / dual-authorship / parser gate 불변). **repo-wide `.md` EOL/autocrlf 트랙 아님.** **full-suite-green closeout policy 아님**(어떤 test 가 green 이어야 closeout 가능한지는 별도 정책이며 본 트랙과 섞지 않는다). **design verdict vocabulary 변경 아님**(`yes` / `no` / `yes with risk` 불변). **evidence archive automation 아님.**

## 3. 현재 surface 분류 + 현재 wording / gap

### 3.1 surface 분류 (역할별 — 줄번호 아닌 파일+섹션/역할)

- **정책 source-of-truth home (구현 batch 변경 대상)**:
  - `docs/contracts/review/REVIEW_RESULT_CONTRACT.md` — §3a(Markdown validation evidence convention; evidence 의 의미 boundary), §3b(mechanical behavior claim 의 minimal reproducible check), §6(blocking 정의에서 "reviewer 의 sandbox / capability 한계로 인한 미검증 영역" 을 non-blocking `## Review limitations` 로 분류). 이 정책의 source-of-truth 가 들어갈 곳.
- **Mirror homes (구현 batch 변경 대상)**:
  - `templates/review-input.md` — `## Validation evidence` informational section 의 guidance prose(R1 convention 의 operator-facing 표현).
  - `snippets/claude-skills/ai-harness-review/SKILL.md` — operator-mode(mechanical claim verify-before-claim guidance, step 4 근처)와 reviewer-mode expectation(step 6 의 "expect the reviewer to have attempted a minimal reproducible check … in the read-only sandbox") mirror.
- **Context surface (미변경)**:
  - `docs/contracts/evidence/EVIDENCE_CONTRACT.md` — evidence file 본문 shape 의 권위(이 정책은 evidence *사용* 의 boundary 만 다루고 evidence shape 은 건드리지 않는다).
  - `scripts/review-run.ps1` 의 **H1 reviewer-mode preamble** — reviewer 를 read-only sandbox(`--sandbox read-only --ask-for-approval never --ignore-user-config`)로 호출하고 verdict shape 를 강제하나, **reproduction/execution 에 대해 현재 침묵** 한다. preamble 은 runtime behavior 이므로 이 트랙의 첫 구현 batch 에서 **변경하지 않는다**(§10). reviewer-safe posture 의 config 측 문서는 `docs/policies/REVIEWER_CONFIG_POLICY.md`(인접, 기본 미변경).
- **Tracking surfaces (가이던스 홈 아님; 구현/closeout 시점에만 갱신)**:
  - `docs/systems/review/STATUS.md` — Batch-D deferred 신호 anchor(구현 closeout 시 deferred→done 이관 결정 + 이 문서로의 inbound pointer).
  - `docs/systems/review/BACKLOG.md` — RV-B-04 / RV-B-05 triage row(우산).

### 3.2 현재 wording 이 이미 codify 한 것 (검사 기준 1·2·6 일부)

- **(기준 1·2) validation execution claim → evidence inspection, 재실행 아님**: `templates/review-input.md` 의 `## Validation evidence` guidance, `REVIEW_RESULT_CONTRACT.md` §3a, `EVIDENCE_CONTRACT.md` 는 일관되게 — operator 가 validation execution claim(Pester pass count, `verify-ps1` PASS, `git diff --check` clean 등)을 적으면 그 근거를 별도 Markdown evidence file 로 두고 reviewer 가 read-only sandbox 에서 *읽는다* — 고 정한다. evidence 는 **reviewer-readable runtime supporting material** 이며 명시적으로 **command re-execution 아님 / deterministic truth oracle 아님 / freshness binding 아님 / source-of-truth 로 승격 안 됨** 이다(§3a). 즉 *validation evidence* 와 *reviewer reproduction* 은 이미 개념적으로 분리돼 있고, evidence 는 inspection 대상이지 재실행 대상이 아니다.
- **(기준 6 일부) sandbox/capability 한계 → review limitation, target risk 아님**: `REVIEW_RESULT_CONTRACT.md` §6 의 non-blocking 분류는 "reviewer 의 sandbox / capability 한계로 인한 미검증 영역의 명시(이는 `## Review limitations` 에 surface)" 를 non-blocking concern 으로 둔다. `## Review limitations` 의 정의 자체가 "read-only sandbox 안에서 mutating 명령 실행 불가, operator 가 작성한 evidence file 본문의 시점적 사실성을 reviewer 가 cross-execute 하지 못함" 을 예시로 든다. 따라서 *재실행 불가 → review limitation* 는 부분적으로 이미 있다.

### 3.3 gap / risk (검사 기준 3·4)

- **(기준 3) reviewer 재실행이 현재 *기대/암시* 되는 곳**: `REVIEW_RESULT_CONTRACT.md` §3b 와 `SKILL.md` step 6 은 **mechanical behavior claim**(특정 regex/parser/verifier/script 의 동작 주장)에 대해 reviewer 가 read-only sandbox 안에서 **minimal reproducible check**(literal 에 대한 tiny regex match, small parser input, small verifier fixture, isolated string/char inspection, one-line shell exit-code check)를 *시도하길 기대* 한다. 이는 의도적으로 **narrow**(수 초의 점검, full test suite 아님)다. 이 기대 자체는 정당하며 본 정책이 약화하지 않는다(§3.4). 문제는 이 기대가 *broad* validation/build/test 실행에까지 번질 여지가 wording 상 막혀 있지 않다는 점이다.
- **(기준 4) "sandbox 에서 실행 가능하면 해도 된다" 해석을 만들 수 있는 wording**: §3b 의 "any available scripting environment 에서의 isolated string / character inspection, one-line shell exit-code check" 표현은, read-only sandbox 가 *write 는 막지만 read-only command 실행은 막지 않는다* 는 사실과 결합하면 — "sandbox 가 실행 가능하니 operator 의 validation command 도 돌려보자" 는 opportunistic 해석을 만들 수 있다. 현재 어떤 surface 도 **"reviewer 는 read-only sandbox 가 실행 가능해 보인다는 이유만으로 validation/build/test command 를 재실행하지 않는다"** 를 명시하지 않는다. 또한 reviewer command 실행이 review input 의 명시 authorization(command scope·side-effect boundary·interpretation rule)을 요구한다는 규칙도 없다. **이 두 가지가 본 트랙이 메우는 gap 이다.**
- 보조 관찰: read-only sandbox 의 reviewer-safe posture(§3.1 context)는 *write 차단* 구조 guard 이지 *execution 금지* 가 아니다 — 그래서 "no-write" 는 구조적으로 보장되지만 "no opportunistic exec" 는 **wording/convention 으로만** 성립한다. 본 정책은 그 wording 을 명문화한다(parser/structural guard 추가 아님, §10).

### 3.4 §3b minimal reproducible check 와의 경계 — 필수 reconciliation (검사 기준 3·8)

본 정책의 "기본은 재실행하지 않는다" 는 §3b 의 "mechanical claim 은 minimal reproducible check 를 시도하라" 와 **모순되지 않도록** 명확히 구분돼야 한다. 구분 기준:

- **§3b minimal reproducible check (기대 유지 — 본 정책이 opt-in 으로 만들지 않음)**: reviewer 가 *직접 구성한 tiny synthetic 입력* 에 대해 claimed mechanism 을 inspection-grade 로 점검하는 것 — literal string 에 대한 regex match, small parser/verifier fixture, isolated string/char inspection, one-line exit-code probe. 특징: (a) 대상이 *작은 합성 입력* 이고 operator 의 실제 validation command 가 아니다, (b) 수 초의 점검이며 **full test suite/build 가 아니다**, (c) side-effect 가 read-only string/regex 수준이다, (d) 이미 §3b 가 자기 infeasibility 를 `## Review limitations` 로 라우팅한다. 이 점검은 reproduction 이라기보다 **inspection 의 연장** 이며 default 로 기대된다.
- **본 정책의 opt-in reproduction (broad)**: target project 의 *실제* validation / build / test pipeline 실행 — full Pester suite, MSBuild/C++ build, CMake configure+build, Unity/Unreal build, network restore, generated-output write, repo-external SDK 호출 등(§8). 특징: (a) operator 환경의 실제 command, (b) side-effect surface 가 큼(writes / network / generated artifacts), (c) read-only sandbox 와 toolchain/SDK 부재로 실패하거나 partial-run 으로 오도, (d) default 로 **시도하지 않으며**, review input 의 명시 authorization 이 있을 때만 opt-in.
- **경계선**: "reviewer 가 합성한 narrow probe 로 claimed mechanic 을 점검"(§3b, 기대) vs "operator 의 실제 validation/build/test pipeline 을 돌림"(본 정책, opt-in). 모호한 가장자리는 §3b 의 "one-line shell exit-code check" 인데 — 이는 *reviewer 가 작성한 synthetic 한 줄 probe* 를 뜻하지 "operator 의 validation command 를 실행" 을 뜻하지 않음을 구현 batch wording 이 명시해야 한다.
- **구현 제약 (중요)**: 구현 batch 는 §3b 의 minimal-check 기대를 **약화하거나 삭제하지 않는다.** 두 규칙을 한 문서(contract) 안에서 서로 cross-reference 하여, "default no-repro 는 broad validation/build/test 에 적용되고 §3b 의 mechanical minimal check 는 그 예외(기대됨)" 임을 self-consistent 하게 둔다. 이 cross-reference 누락이 가장 가능성 높은 self-conflict 원인이므로 review 의 1순위 점검 대상이다.

## 4. Core policy

1. **Local operator owns execution.** validation / build / test 실행은 operator 의 local 환경 책임이다. 그 사실은 evidence(§3a / `EVIDENCE_CONTRACT.md`)로 남는다.
2. **Reviewer owns inspection.** reviewer 는 diff / contract / local validation evidence 를 read 하여 판단한다.
3. **Evidence bridges the two.** local 실행 사실과 reviewer 판단을 잇는 다리는 evidence file 이며, reviewer 는 그것을 *읽는다*(재실행하지 않는다). evidence 는 source-of-truth 가 아니다(§3a, §12).
4. **Reviewer must not run validation / build / test commands just because the sandbox can.** read-only sandbox 의 execution 가능성은 license 가 아니다. broad reproduction 은 review input 의 명시 authorization(§5)이 있을 때만 opt-in 이며, 그 외에는 default 행동(§6)을 따른다. §3b 의 mechanical minimal reproducible check 는 이 규칙의 예외로 기대된다(§3.4).

## 5. Opt-in reproduction rule

reviewer 의 command 실행(broad reproduction)은 **review input 에서 명시적으로 허용된 경우에만** 가능하다. 허용 시 review input(권장 home: `## Validation evidence` 또는 `## Required inspection paths` 인접의 명시 authorization 블록 — 구현 batch 가 정확한 자리를 정한다)은 **최소한** 다음을 명시한다:

- **exact command** — 재실행할 정확한 command line(추정/일반화 금지).
- **working directory** — 실행 기준 디렉터리.
- **expected read/write behavior** — 해당 command 가 read-only 인지, write/side-effect 가 있는지, 있다면 무엇을 쓰는지.
- **allowed temp/output path** — 산출/임시 파일이 허용되는 경로 범위(있다면).
- **dependency assumptions** — 전제되는 toolchain / SDK / runtime / network 가용성.
- **timeout expectation** — 허용 실행 시간 한계(긴/무한 실행 금지; foreground 가정).
- **interpretation boundary** — 결과(특히 partial / nonzero exit)를 어떻게 해석할지의 경계 — 무엇이 PASS/FAIL 신호이고 무엇이 환경 noise 인지.
- **how to report sandbox limitation** — sandbox 제약으로 실행이 불가/부분 실패 시 그 사실을 `## Review limitations` 에 어떻게 기록할지.

이 authorization 은 **wording/convention** 이며 parser/lint gate 가 아니다(§10). authorization 이 없거나 위 항목이 불완전하면 reviewer 는 reproduction 을 시도하지 않고 default 행동(§6)으로 돌아간다.

## 6. Default reviewer behavior

review input 에 broad reproduction authorization(§5)이 없을 때 reviewer 의 default 는:

- **inspect** — diff / contract / 그리고 `## Validation evidence` 가 가리키는 local validation evidence 본문을 read 한다(§3a).
- **do not attempt reproduction by default** — operator 의 validation/build/test command 를 임의로 재실행하지 않는다. (§3b 의 mechanical minimal reproducible check 는 별개로 기대됨 — §3.4.)
- **report non-reproduction as review limitation, not target risk** — reviewer 가 재실행하지 못했거나 하지 않은 사실은 `## Review limitations` 에 기록한다. 이는 non-blocking 이며 그 자체로 verdict 를 `no` 로 만들지 않는다(§7 의 독립 근거가 없는 한). evidence 의 시점적 사실성을 reviewer 가 cross-execute 하지 못함도 같은 자리에 surface 한다(§3a 의 정직성=operator 책임 원칙과 일치).

## 7. Sandbox limitation interpretation

reviewer 가 **재실행하지 못했거나 재실행하지 않은 사실은 자동으로 target risk 가 아니다.** 이는 reviewer 환경의 한계(review limitation)이지 reviewed target 의 결함이 아니다.

reviewer 의 미검증이 **target risk(blocking 또는 risk-bearing)로 승격되려면 sandbox 한계와 *독립된* 근거** 가 있어야 한다. 예:

- **missing local evidence** — validation execution claim 이 있는데 이를 뒷받침할 local evidence 가 부재.
- **stale evidence** — evidence 가 reviewed source 의 현재 상태와 명백히 시점 불일치(예: 변경된 파일을 반영하지 않은 과거 run).
- **scope mismatch** — evidence 가 claim 의 scope 를 cover 하지 못함(예: 다른 surface 의 run 으로 현재 변경을 대신).
- **static contradiction** — diff / contract / template 의 정적 자기모순(재실행 없이 read 만으로 드러나는 inconsistency).
- **explicit high-risk gap** — 명시적으로 고위험인 영역이 어떤 evidence 로도 cover 되지 않음.

이런 독립 근거가 없으면 non-reproduction 은 `## Review limitations` 의 non-blocking 항목으로 남는다(§6). 본 §7 은 `REVIEW_RESULT_CONTRACT.md` §6 의 기존 non-blocking 분류를 **약화하지 않고**, target-risk 승격의 *독립 근거* 를 명명하여 sharpen 한다.

## 8. Target-project examples

다음은 reviewer read-only sandbox 에서 **기본 재실행 대상이 아닌** target-project validation 의 일반화 예다. 공통적으로 (a) sandbox 에 부재한 toolchain/SDK/network 를 요구하거나, (b) write/network/generated-output 의 side-effect 라 read-only sandbox 에서 실패하거나 partial-run 으로 오도하거나, (c) operator 의 local 환경에 속한다.

- **Visual Studio / MSBuild / C++ build** — IDE/컴파일러 toolchain·build artifact write 의존; sandbox 에 부재/과중.
- **CMake / Unity / Unreal / game SDK** — engine·SDK 설치/라이선스 게이트, 대용량, generated output write.
- **network restore** (NuGet / npm / pip / git submodule 등) — read-only sandbox 가 network·write 를 차단; restore 는 본질적으로 side-effecting.
- **generated-output / write-heavy builds** — artifact 를 *쓰는* 작업이라 read-only sandbox 와 비호환; partial run 은 신호를 오도.
- **repo-external tools / SDKs** — repo 안에도 sandbox 안에도 없고 version-specific.

이들은 sandbox 에서 *실행 가능해 보여도* 기본 재실행 대상이 아니다. reviewer 는 대신 operator 의 local validation evidence 를 inspect 하고, 재실행 불가를 `## Review limitations` 로 보고한다(§6·§7). 본 예시들은 **universal build runner / sandbox capability probe / SDK detection / project-specific build integration 을 만들자는 것이 아니다**(§10) — 정책의 *이유* 를 일반화해 보여줄 뿐이다.

## 9. Expected implementation surfaces

구현 batch(별도 scoped /goal)에서 수정할 후보 surface — **이번 작업에서는 수정하지 않는다**:

- `docs/contracts/review/REVIEW_RESULT_CONTRACT.md` — **source-of-truth.** opt-in reproduction(§5)·default inspect(§6)·sandbox-limitation-not-target-risk(§7)·§3b 와의 경계(§3.4)를 codify. 자리 후보: §3a evidence boundary 의 확장 + §3b mechanical check 의 scope 명시(cross-reference), 또는 신규 절(예: 가칭 §3d "Reviewer reproduction opt-in"). **두 규칙(§3b 기대 ↔ default no-repro)을 한 문서 안에서 cross-reference 하여 self-consistency 를 보장** 하는 것이 핵심.
- `templates/review-input.md` — `## Validation evidence` guidance 에 default(evidence-inspect, no opportunistic reproduction)와 opt-in authorization shape(§5 의 최소 필드)을 간결히 도입.
- `snippets/claude-skills/ai-harness-review/SKILL.md` — operator-mode(evidence 작성 + opt-in 시 authorization 명시)와 reviewer-mode expectation(default no-repro / opt-in / non-repro→review limitation) mirror. **deployed self-contained surface 이므로 repo-doc `§N` pointer 를 재도입하지 않는다**(기존 SKILL 규약).
- (인접·선택) `docs/policies/REVIEWER_CONFIG_POLICY.md` — reviewer-safe invocation(read-only sandbox) 문서에 본 정책으로의 짧은 pointer(선택; core 아님).
- **조건부(구현 closeout 시점, 위 core 와 분리)**: `docs/systems/review/STATUS.md` 의 Batch-D deferred 신호("validation reproducibility inside the reviewer's read-only sandbox …")를 **deferred→done** 으로 이관 + 이 문서로의 inbound pointer wiring. (planning-doc scope 상 이 closeout 은 구현 batch 로 분리되며, 그때까지 일시적 orphan 을 수용한다 — `docs/policies/DOCS_OPERATING_MODEL.md` §4·§7.)

**구현 surface 에서 의도적으로 제외(§10)**: `scripts/review-run.ps1` 의 H1 reviewer-mode preamble — reproduction wording 을 preamble 에 넣는 것은 **runtime behavior 변경** 이므로 첫 구현 batch scope 밖이다. 첫 batch 는 docs/contract/template/skill **wording** 에 한정한다. preamble 정합이 필요하다고 판단되면 별도 runtime-touching batch + 별도 review gate 로 처리한다.

## 10. Scope exclusions

이 planning, 그리고 그것을 따르는 구현 batch 모두에서 다음을 **하지 않는다**:

- **implementation surface 수정**(이번 planning 단계). **parser / verifier / runtime behavior 변경**(`scripts/review-run.ps1` H1 preamble 포함), **reviewer-mode preamble wording 변경.**
- **evidence archive automation** 생성.
- **parser / lint / verifier gate 추가** — 본 정책은 wording/convention 이며 어떤 deterministic gate(`scripts/review-input-verify.ps1` / `scripts/review-verify.ps1` 등)도 추가하지 않는다(RV-B-04 evidence-section 비-lint 결정 및 §10 non-goal 정신과 일치).
- **universal build runner / sandbox capability probe / SDK detection / project-specific build integration** 생성.
- **`log/**` 를 source-of-truth 로 승격**(§12).
- **reviewer sandbox inability 를 target defect 로 자동 승격하는 규칙** 생성 — 본 트랙의 전제(§7)에 정면 위배.
- **full-suite-green closeout policy 와 혼입** — 어떤 test 가 green 이어야 closeout 가능한지는 별도 정책이며 섞지 않는다.
- **EOL / autocrlf normalization** — `.md` blob EOL convention(`.gitattributes` 의 `*.md text eol=lf`)은 본 batch scope 밖이다. (신규 본 문서는 sibling planning doc 과 동일하게 LF/no-BOM 으로 작성됨.) [stale 전제 정정: 이 트랙을 과거 "일부 커밋된 CRLF" 전제로 기술했으나, HEAD `a26f9d4` audit 에서 tracked `.md` 가 전부 LF/no-BOM 으로 normalization no-op 임이 확인됨 — `docs/systems/review/STATUS.md` 의 `.md` EOL audit closeout 참조.]
- **design verdict vocabulary 변경**(`yes` / `no` / `yes with risk` 불변), **RV-B-06 재오픈**, **§3b minimal-check 기대 약화/삭제**(§3.4).
- **global / user file·memory·shell config·git config 수정**, **snapshot / manifest 생성**, **commit / push** — 모두 별도 사용자 명시 승인 사항.

## 11. Validation & review plan

- **planning doc 자체 review (이번 단계)**: 본 문서는 source/doc mutation 이므로 corrected working tree 기준 Codex reviewer review 를 받는다. review-system policy/doc self-modification 이므로 **global stable ToolRoot engine**(`%USERPROFILE%\.claude\ai-harness-toolset\current`)으로 돌린다(`REVIEW_RESULT_CONTRACT.md` §5a.7; SKILL step 1 reviewer-engine independence). finding → approved scope 내 수정 → **corrected-state re-review**. review 이후 문서를 수정하면 기존 review 는 stale 이므로 반드시 re-review. 정규 review path 실패 시 조용히 fallback 하지 말고 실패 자체를 finding/evidence 로 보고하고 멈춘다.
- **구현 batch validation (이번 planning 단계 미실행)**: Pester suite(`tests/*.Tests.ps1`)는 wording-only 변경이라 regression 0 예상이나 guard 로 전수 실행. `scripts/review-input-verify.ps1` 를 template-derived sample input 에 실행(required heading set 불변 + `## Validation evidence` informational 이므로 PASS 예상). `git diff --check`(whitespace/EOL). 신규 `.ps1` 없음(BOM+CRLF 규칙 무관).
- **anti-pattern grep sweep (첫 implementation re-review *전*)**: 본 변경은 wording reconciliation(sibling section 을 건드림)이므로, 한 곳만 고치고 re-review 하면 cascade 가 생긴다 — contract/template/skill 전반에서 "command re-execution" / "minimal reproducible check" / "reproduc*" / "sandbox" 표현을 grep 해 §3b 기대와 default-no-repro 가 **모든 home 에서 self-consistent** 한지 일괄 확인한다(§3.4 self-conflict 가 1순위 점검 대상).
- **corrected-state re-review rule**: 각 단계(planning, implementation)는 자기 corrected working tree 위에서 독립 Codex review 를 받는다. inline 대화 proposal 은 durable review 를 대체하지 않는다.

## 12. Relationship to `log/**`

- `log/evidence/**` 는 **reviewer-readable runtime supporting material** 이다(§3a). review input/result 는 evidence path 를 referencing 할 수 있다.
- 그러나 evidence 는 **source-of-truth 가 아니며 durable pointer 대상이 아니다.** committed docs(이 문서 포함)는 `log/**` 에 권위를 의존하지 않는다 — durable provenance 는 이 문서 + git history + git-tracked source 다. evidence file 이 사라져도 이 문서와 contract 의 권위는 그대로 유효하다.
- `log/review/**`(canonical review record)와 `log/evidence/**`(보조 기록)는 같은 gitignored `log/` 아래지만 책임이 다르다(`EVIDENCE_CONTRACT.md` "review subsystem과의 경계"). 본 정책은 그 분리를 재확인하며 어느 쪽도 source-of-truth 로 승격하지 않는다.

---

*이 문서는 open track 의 design/plan 이다. 구현·리뷰·commit/push 는 각각 별도 사용자 승인이 필요한 후속 단계다.*
