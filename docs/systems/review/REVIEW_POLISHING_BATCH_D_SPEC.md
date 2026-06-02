# 리뷰 시스템 폴리싱 — Batch D 조사 + implementation spec (report schema / run-fact wiring, 2026-06-02)

## Document character

본 문서는 implementation plan(`docs/systems/review/REVIEW_POLISHING_IMPLEMENTATION_PLAN.md`)의 **Batch D** 산출물 — final report schema 와 run-fact output wiring 의 **조사 결과 + implementation spec** 이다. plan §6 이 Batch D 를 "report schema / run-fact wiring"(final report 10-field 분리, `artifact pass-NN`/corrective loop/invocation count 분리 표기, reviewer guard status, (B/C 통과 후) effort·safety run-fact 반영, parser enforcement 확대는 narrow 유지)로 정의했으나 별도 spec 으로 분해된 적이 없다 — 본 문서가 그 분해다.

- **성격**: Batch D = 조사 + spec. source/script/test/config 변경을 동반하지 않는다. Batch D implementation(별도 scoped `/goal` + review gate)이 본 spec 을 입력으로 삼는다.
- **이것이 아닌 것**: implementation 아님 / operational claim 아님 / 승인 문서 아님. 본 문서의 어떤 조사 결과도 source/script/test/config 의 변경을 수행하거나 승인하지 않는다. "필요해 보임" 은 구현 확정이 아니라 spec 후보다.
- **정직성 분리**: 아래 모든 사실은 **현재 출력함 / 현재 출력하지 않음 / inferred(미확정)** 로 분리 표기한다. "current runner 가 이미 emit 하는 run-fact" 와 "Batch D 가 추가로 emit 하도록 제안하는 run-fact" 는 다른 층이다 — 섞지 않는다.
- **source of truth**: `docs/systems/review/REVIEW_POLISHING_DECISION_RECORD.md` §"Final report schema decision"(10-field schema 의 상위 권위) + `docs/systems/review/REVIEW_POLISHING_IMPLEMENTATION_PLAN.md` §6(Batch 정의). 충돌 시 decision record 가 이긴다.

## 0. 조사 환경 (provenance)

- repo HEAD `ba84065`("Anchor review engine independence in review contract"), branch `main`, working tree clean. Codex CLI `0.132.0`, Windows 11.
- 조사 방식: repo 파일 read-only inspection — `scripts/review-run.ps1`(success-path Write-Host 라인 enumeration), `scripts/review-verify.ps1`, `scripts/review-input-verify.ps1`, `tests/review-run.Tests.ps1`, decision record §Final report schema, contract §6/§6a, `snippets/claude-skills/ai-harness-review/SKILL.md` step 5·6·7, `templates/review-{input,result}.md`, `docs/policies/REVIEWER_CONFIG_POLICY.md`.
- 본 spec 작성 자체는 구현/검증을 수행하지 않는다 — review-run 을 새로 실행하지 않았고, run-fact 출력 변경을 만들지 않았다. 현재 출력은 `scripts/review-run.ps1` 의 success-path Write-Host 라인(아래 §1a)에서 직접 읽었다.

## 1. 조사 결과 — 현재 reporting surface

### 1a. review-run.ps1 가 현재 emit 하는 run-fact (verified, inspection)

`scripts/review-run.ps1` success-path 의 Write-Host 라인은 정확히 다음 9개다(`review-run.ps1` 끝부분 inspection):

- `review-run: PASS`
- `review-task-id: <id>`
- `pass: <pass-NN>`
- `verdict: <yes|no|yes with risk>`
- `requested-effort: <effort>` — Batch B
- `effort-source: <explicit|config|default>` — Batch B
- `applied-effort: <value|not-observed|...(WARNING: differs from requested ...)>` — Batch B, Codex stderr 헤더에서 캡처
- `pass-dir: <repo-relative>`
- `result: <repo-relative>`

> **D-V1**: 즉 **effort run-fact 3종(requested/source/applied)은 Batch B 에서 이미 wiring 되어 runner 가 emit 한다.** Batch D 가 이 부분을 새로 만들 필요는 없으며, 남은 일은 이 값들이 final human report 에도 surface 되도록 보장하는 것(§3 candidate 4).

### 1b. review-run.ps1 가 현재 emit 하지 않는 것 (verified, inspection)

다음은 runner 가 내부적으로 resolve/전달하지만 **stdout 으로 보고하지 않는** 것이다:

- **D-NV1 model / model-source**: `Get-ReviewerModel`(explicit `-Model` > config `model` > fail-fast)로 `$model` 을 resolve 하고 Codex `--model` 로 전달하지만, **어떤 model 이 어느 source(explicit/config)에서 왔는지 출력하는 라인이 없다.** effort 는 `effort-source:` 를 출력하는데 model 은 source 대칭물이 없다.
- **D-NV2 reviewer-safe posture**: `$codexArgs` 에 `--ask-for-approval never` / `--sandbox read-only` / `--ignore-user-config`(Batch C) / `-c web_search=disabled` 를 hardcode 로 전달하지만, **이 posture 를 보고하는 라인이 없다.**
- **D-NV3 review engine identity**: `$tool`(`Get-ToolRoot`) / `$project`(`Get-ProjectRoot`) / `$toolRootSource`(`Get-ToolRootSource`)를 resolve 하지만, **engine ToolRoot / ProjectRoot / tool-root-source 를 출력하는 라인이 없다.** §5a.7 engine-independence 규율이 review-subsystem self-modification 에서 engine identity 를 중요하게 만들지만 runner 는 자기 engine 위치를 emit 하지 않는다.

### 1c. final report schema 의 현재 위치 (verified, inspection)

decision record §"Final report schema decision" 의 **10-field schema** 는 다음 표다:

| # | 필드 | 내용 |
|---|---|---|
| 1 | perspective coverage | `dual-perspective coverage` / `coverage-limited review`(+생략 관점·rationale) / `no-reviewable-change report` |
| 2 | invocation packaging | `single-invocation dual-perspective packet` / `two focused invocations` / 기타 disclosed packaging |
| 3 | invocation count | reviewer 실제 호출 횟수(품질 보증 아님) |
| 4 | artifact pass count | `artifact pass-NN` attempt 수; 없으면 `N/A — no artifact pass-NN`(발명 금지) |
| 5 | corrective loop count | `corrective review loop` 반복 횟수(별도 축) |
| 6 | re-review status | `not needed` / `needed` / `completed` / `stale due to mutation` / `not applicable` |
| 7 | verdict / risk handling | `yes`/`no`/`yes with risk` 소비 방식 |
| 8 | validation evidence | 사용한 validation evidence + 한계 |
| 9 | final git status | 최종 worktree 상태 + changed files |
| 10 | commit/push recommendation | next-action recommendation, approval 아님 |

보조(optional): invocation path·run id·corrections applied·remaining risks·**reviewer execution guard status**.

> **D-V2 (gap)**: 이 10-field schema 는 **현재 decision record 에만 존재한다.** operative contract(`docs/contracts/review/REVIEW_RESULT_CONTRACT.md`)에는 final-report schema section 이 없다(contract §6a 는 *verdict → next-action mapping* 이지 *final report 10-field schema* 가 아니다). SKILL.md step 7 의 operator 최종보고는 **다른 9-item 목록**(entry-point error / retry decision / review task / final pass / corrective loop count / final reviewer result / (intent2) self-review+merged / next-action handling / next decision points)이며 10-field schema 와 1:1 정합하지 않는다.

### 1d. 10-field schema ↔ SKILL step 7 정합성 분석 (verified, inspection)

decision record 10-field 각각이 SKILL step 7 에서 명시 필드로 다뤄지는지:

| field | SKILL step 7 현황 |
|---|---|
| 1 perspective coverage | **명시 필드 없음** (gap) |
| 2 invocation packaging | **명시 필드 없음** (gap) |
| 3 invocation count | **명시 필드 없음**; step 5 "one invocation per user request" 는 있으나 보고 필드 아님 (gap) |
| 4 artifact pass count | item 4 "Final pass" 가 부분 대응 |
| 5 corrective loop count | item 5 존재. **단 SKILL 은 "corrective loop count = number of passes consumed" 로 정의**(item 5) — decision record 는 `corrective loop count`(field 5)와 `artifact pass count`(field 4)와 `invocation count`(field 3)를 **서로 다른 축**으로 분리. 즉 SKILL 은 세 축을 conflate 한다 (axis-conflation gap) |
| 6 re-review status | **명시 필드 없음** (gap) |
| 7 verdict / risk handling | item 6(verdict 축어) + item 8(next-action) 으로 대응 |
| 8 validation evidence | **보고 필드 없음** (gap) |
| 9 final git status | **보고 필드 없음** (gap) |
| 10 commit/push recommendation | item 9(next decision points; verdict ≠ approval) 로 framing 대응 |
| (opt) reviewer guard status | **보고 필드 없음** (gap) |

> **D-V3 (핵심 gap)**: decision record reporting 의 가장 구체적 기여 — *"`pass-02 yes` 식 단일 표기 금지(coverage/attempt/corrective 구분 불가)"* 와 invocation count / artifact pass count / corrective loop count 의 **3축 분리** — 가 operator-facing 보고 surface(SKILL step 7)에 codify 되어 있지 않다. 이것이 Batch D 의 가장 단단한 작업 항목이다.

## 2. 세 home 분류 (organizing principle)

Batch D 의 모든 datum 은 다음 세 home 중 하나에 속한다. 이 분류가 Batch D spec 의 조직 원리이며, plan §6 의 "report schema / run-fact wiring" 을 구체화한 것이다.

- **(H1) Runner stdout** — `review-run.ps1` 의 단일 invocation 이 deterministic 하게 관측할 수 있는 run-fact. machine-emittable. 예: verdict, effort 3종, model, model-source, reviewer-safe posture, engine ToolRoot/ProjectRoot, pass-dir, result. **단일 pass 의 사실에 한정** — 여러 pass 를 가로지르는 집계나 caller 판단은 runner 가 알 수 없다.
- **(H2) Final human report** — operator(SKILL step 7)가 사용자에게 내는 최종보고. decision record 10-field schema 의 대부분이 여기 속한다. coverage·packaging·invocation count·artifact pass count·corrective loop count·re-review status·verdict/risk handling·validation evidence·final git status·commit/push recommendation. 이 중 다수는 **multi-pass 집계 또는 caller 판단**이라 단일 runner invocation 이 알 수 없다(예: corrective loop count 는 여러 pass 를 가로지르고, coverage 는 caller 결정이다).
- **(H3) Docs-only guidance** — contract/policy/skill 의 wording. schema 를 *정의*하지만 runtime 에 emit 하지 않는다.

> **분류 원칙**: runner 가 단일 실행에서 관측 가능한 deterministic 사실은 H1; multi-pass 집계·caller judgment·coverage 결정은 H2; schema 정의 자체는 H3. 같은 개념이 H1 run-fact 와 H2 report 필드에 둘 다 나타날 수 있다(예: applied-effort 는 H1 에서 emit 되고 H2 report 의 validation/effort 항목으로 재인용). H1 과 H2 가 중복될 때 H1 은 runner 의 단일-pass 관측이고 H2 는 operator 의 집계/판단이라는 역할 차이를 보존한다.

## 3. Candidate scope 분류 표

plan §6 Batch D 와 본 조사 task 의 10 candidate 를 분류한다. 각 candidate 의 **현재 상태**, **home**, **Batch D 권고**를 분리한다.

| # | candidate | 현재 상태 | home | Batch D 권고 |
|---|---|---|---|---|
| 1 | final report schema / closeout report fields | 10-field schema 가 **decision record 에만** 존재; contract/SKILL/templates 와 비정합 (D-V2) | H2 + H3 | **Batch D 핵심.** schema 를 단일 durable home(권고: contract 신규 section)에 codify + SKILL step 7 을 mirror 로 정합화 |
| 2 | run-fact output wiring | effort 3종은 emit(D-V1); model/safe/engine 미emit(D-NV1~3) | H1 | runner 에 model·model-source·reviewer-safe posture·engine identity run-fact 추가 |
| 3 | review engine identity / ToolRoot vs ProjectRoot disclosure | resolve 하나 미emit (D-NV3) | H1 (+ H2 인용) | runner 가 engine ToolRoot / ProjectRoot / tool-root-source emit; §5a.7 self-modification 시 final report 가 engine 위치를 disclose |
| 4 | requested/effort-source/applied-effort reporting | **이미 emit(Batch B, D-V1)** | H1 (이미) + H2 | runner 변경 불필요; final report(H2)가 이 값을 surface 하도록 SKILL step 7 정합화만 |
| 5 | model source reporting (explicit/-config/fail-fast/no-fallback) | model fail-fast·no-fallback 로직은 구현됨(corrective); **source 출력은 없음**(D-NV1) | H1 | runner 가 `model:` + `model-source:`(explicit/config) emit. **주의: durable doc 에 concrete model version literal 추가 금지** — runtime 에 resolve 된 model 값을 emit 하는 것은 run-fact(허용)이고, spec/doc 본문에 version 을 박는 것과는 다르다 |
| 6 | reviewer-safe invocation reporting (read-only / never / ignore-user-config / tested-vectors caveat) | flag 는 전달(Batch C); **posture 출력 없음**(D-NV2) | H1 (posture) + H3 (caveat) | runner 가 reviewer-safe posture run-fact emit; **tested-vectors-only, not-blanket caveat 는 docs/report 문구로 유지**(REVIEWER_CONFIG_POLICY 의 verification-status 와 정합) |
| 7 | review target vs review engine independence | §5a.7 + SKILL step 1 에 이미 codify(docs) | H3 (done) + H1/H2 (surfacing gap) | runner engine run-fact(candidate 3)로 surfacing; 새 docs 규율 추가 불필요 |
| 8 | dirty working tree vs round-delta disclosure | runner 는 git state 미캡처; final git status 는 operator 보고(field 9) | H2 | final report field 9(final git status + changed files)가 working-tree dirtiness 와 pass 간 delta 를 disclose 하도록 schema 에 명시. runner 가 git state 를 캡처할지는 **inferred — over-scope 회피 위해 H2 operator 보고로 두는 것을 권고** |
| 9 | verdict is not commit/push approval | contract §6/§6a, vocabulary, SKILL step 7, templates 에 **이미 강하게 codify** | H3 (done) | schema field 10(commit/push recommendation, approval 아님) framing 정합성만 확인; 새 작업 거의 없음 |
| 10 | runner output vs final human report vs docs-only | §2 의 세 home 분류가 이 candidate 의 답 | (meta) | §2 분류를 schema 의 조직 원리로 채택 |

## 4. 권고 implementation split (Batch D → sub-steps)

> 아래는 Batch D implementation 이 다룰 **권고 분할**이다. 본 문서는 구현하지 않으며, 각 sub-step 은 별도 scoped `/goal` + review gate + 사용자 commit/push 승인이 필요하다. 순서·묶음은 권고이며 확정 지시가 아니다.

- **D1 — final report 10-field schema 의 단일 home codify (docs-only, H3)**: decision record 10-field schema 를 operative contract 의 신규 section(권고 명칭 `## Final report schema`, contract §6a 인접)으로 옮겨 single-home 화하고, decision record 는 policy origin pointer 로 유지. SKILL step 7 을 그 schema 의 operator mirror 로 재작성(특히 invocation count / artifact pass count / corrective loop count **3축 분리**와 `N/A — no artifact pass-NN` 표현, re-review status enum, reviewer guard status 추가 — D-V3 해소). templates 는 input.md/result.md 용이므로 final human report schema 의 mirror 대상이 아님(out of scope; §5 참조). parser enforcement 미확대(user-decision 1).
  - **D1 framing 주의(implementation batch 가 명시할 것)**: 10-field schema 의 contract 이전은 **authority-home move**(operative single home 을 옮기는 것)이지 채택된 결정의 substantive reopening 이 아니다 — decision record 가 policy origin 으로, contract 가 operative home 으로 분리됨을 명문화해 둘 사이 혼동을 막는다.
  - **D1 home 선택 trade-off(implementation batch 가 weigh 할 것)**: final human report 는 operator closeout-report 규약이고 contract 는 input.md/result.md artifact contract 다 — 둘을 한 문서에 두면 artifact-contract 관심사와 operator-report 관심사가 blur 될 risk 가 있다. 권고 mitigation: contract 안에 명확히 구획된 별도 section 으로 두거나, 대안으로 dedicated operator-report 문서를 home 으로 고려. 본 spec 은 contract 를 1순위 권고로 두되 이 분리 의무를 implementation batch 의 결정 input 으로 남긴다.
- **D2 — runner run-fact 확장 (source, H1)**: `review-run.ps1` 에 `model:` + `model-source:`(D-NV1), reviewer-safe posture run-fact(D-NV2), engine `tool-root:` / `project-root:` / `tool-root-source:`(D-NV3) emit 추가 + 대응 Pester 테스트(`tests/review-run.Tests.ps1` 의 stub-argv assertion 패턴 확장). concrete model version 은 doc 에 박지 않고 runtime resolve 값을 emit. effort 3종은 이미 있으므로 미변경.
- **D3 — (B/C 통과 후) effort·safety run-fact 의 final report 반영 (H2)**: B/C 가 tested scope 에서 verified 됐으므로 final report 가 effort applied run-fact + reviewer-safe override 적용 evidence 를 **tested-vectors-only / not-blanket caveat 와 함께** 포함하도록 schema·SKILL 정합화. U9 operational·reviewer-safe 를 verified scope 너머로 주장하지 않는다.

**권고 순서**: D1(schema 단일화 + SKILL mirror)이 선행 — schema 가 정해져야 D2 의 run-fact 가 어느 report 필드로 흘러갈지가 정해진다. D2(runner source)와 D3(report 반영)는 D1 후 연속 또는 함께. 각 sub-step 은 review tooling self-modification 이므로 **closeout review 는 §5a.7 대로 global stable ToolRoot engine 으로** 수행.

## 5. 명시적 제외 (out of scope / non-goals)

- **parser enforcement 확대 금지**: final report schema 는 H2 operator 보고 규약이지 deterministic gate 가 아니다. `review-verify -RequireResult` 의 4-H2 disclosure gate(result.md)와 `review-input-verify` 의 5-H2 gate(input.md)는 **변경하지 않는다**. 10-field 를 parser 강제 대상으로 만들지 않는다(user-decision 1: 새 semantic/completeness gate 금지; decision record invariant 7).
- **templates 변경 (대체로 제외)**: `templates/review-{input,result}.md` 는 on-disk artifact(input.md/result.md)의 shape 기준이다. final human report(operator → 사용자)는 on-disk template 이 아니므로 final-report schema 의 mirror 대상이 아니다. result.md 의 verdict/risk/disclosure shape 는 이미 정의돼 있고 Batch D 가 바꾸지 않는다.
- **concrete model version 을 durable doc 에 추가 금지**: `gpt-[0-9]` literal 은 `config/reviewer.json` source-of-truth 1곳에만 존재해야 한다(현재 그러함). model run-fact 는 runtime resolve 값 emit 이며 doc 본문 version 박기와 다르다.
- **effort xhigh safe-default policy 재논의 금지**: default = xhigh, 명확히 단순한 local-correctness packet 만 `-Effort` downgrade, effort ⟂ coverage 는 이미 채택·구현됨. Batch D 는 reporting 만 다룬다.
- **U9 operational / reviewer-safe status 의 caveat 유지**: reviewer-safe 는 tested vectors(create / modify-tracked / modify-existing)에 한해 verified 이며 blanket guarantee 아님. final report 도 이 caveat 를 그대로 유지한다 — verified scope 너머 주장 금지.
- **log/evidence 의 지위**: runtime supporting material 이지 source-of-truth 아님. final report 가 evidence path 를 인용할 수 있으나 deterministic truth oracle 로 승격하지 않는다.
- **새 sidecar / aggregation / DB / multi-reviewer / run-history**: contract §10 non-goals 그대로 유지.
- **dirty-tree 의 runner 측 git 캡처 (inferred, 제외 권고)**: candidate 8 의 final git status 는 H2 operator 보고로 두고, runner 가 git state 를 캡처하도록 확장하는 것은 over-scope 로 보아 Batch D 에서 제외 권고(운용 데이터 후 재검토).

## 6. 정직성 경계 (verified / inferred / not-done)

- **verified(inspection)**: D-V1(effort 3종 이미 emit), D-V2(10-field schema 가 decision record 에만 존재; contract/SKILL 비정합), D-V3(SKILL step 7 의 3축 conflation + 다수 필드 부재), D-NV1~3(model-source / reviewer-safe posture / engine identity 미emit). 이들은 현 repo 파일에서 직접 읽은 사실이다.
- **inferred(미확정, spec 후보일 뿐)**: D1~D3 의 구체 라인·필드 명칭(`## Final report schema`, `model-source:`, `tool-root:` 등)은 **권고 명칭**이며 implementation batch 가 확정한다. candidate 8 의 runner-side git 캡처 제외도 권고이지 확정 아님.
- **not-done(미구현)**: D1~D3 전부 미구현. 본 spec 작성은 source/script/test/config 를 변경하지 않았다. 이 spec 의 채택이 implementation/commit/push 승인이 아니다.

## 7. Approval boundary / 본 spec 이 하지 않은 것

- source/script/test/config 미변경(`review-run.ps1`·`review-verify.ps1`·`review-input-verify.ps1`·tests·`config/reviewer.json`·contract·SKILL·templates·policy 불변). 본 batch 의 mutation 은 본 spec 문서 + STATUS.md 최소 pointer 1줄에 한정.
- Batch D implementation 미진입. global/user config 미변경. activation apply 없음. snapshot/manifest 없음. commit/push 없음.
- D1~D3 구현 진입은 각각 별도 scoped `/goal` + review gate + 사용자 commit/push 승인 필요. reviewer verdict/opinion 은 그 승인이 아니다.
- review tooling self-modification 이므로 본 spec 의 closeout review 는 §5a.7 대로 global stable ToolRoot engine 으로 수행한다(in-dev repo runner 를 engine 으로 쓰지 않는다).

## 8. 다음 single action

본 spec 사용자 검토·채택 후 → **D1**(final report 10-field schema 를 contract 신규 section 으로 single-home 화 + SKILL step 7 mirror 정합화, docs-only)을 별도 scoped `/goal` 로 진입. D2(runner run-fact 확장)·D3(effort·safety run-fact 의 report 반영)는 D1 후 연속 또는 함께. 그 전까지 source/script/test/config 변경·implementation 진입 금지.
