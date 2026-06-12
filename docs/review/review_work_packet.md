# review Work Packet

**이 문서는 무엇인가.** batch R(review 도메인 마이그레이션)의 round-scoped 분석 임시 문서다 — 구계열 17파일의 절/행 단위 처분 분류, inbound 참조 4-class 지도, `log/evidence/**` 소비자 분류, STATUS ledger 시점성 기재의 대조 입력을 담는다. **committed temporary document** — closeout 시 삭제되고 보존은 git history 다.

**이 문서가 아닌 것.** 승인 대상 아님 · live 도메인 문서 아님 · Spec 의 대체물 아님 — 지속 결정은 `review_spec.md` 의 normative 문장으로만 들어가고, 이 문서의 어떤 내용도 live 문서로 복사·승격되지 않는다. 실행 명령 시퀀스·staging 절차·review 결과·readiness 판정은 담지 않는다(operator report `log/**` 소관). 이 문서는 mutation/commit/push 승인이 아니다(1회 진술).

분류 어휘: **S** = review_spec 의 normative 문장으로 재구성 이주 · **O** = active surface 가 이미 소유(spec 은 owner 명명으로 갈음) · **H** = narrative/튜토리얼 — git history 보존(흡수 없음) · **B** = `review_backlog.md` row · **I** = cross-domain interface 로 참조만(재정의 없음).

## 1. 구계열 17파일 처분 분류 대조표

### 1.1 `docs/contracts/review/REVIEW_RESULT_CONTRACT.md` (665줄) — 절별

| 절 | 내용 | 분류 | 비고 |
|---|---|---|---|
| intro | three-level canonical layout·2-file·dual-authorship·spec-of-record 선언·active-mirror 우선 authority 모델 | S | layout 불변식·authority 모델은 spec Header/목표 상태로; "spec-of-record" 역할 자체가 review_spec 으로 승계 |
| §1 | task/perspective/pass 의미·write-once·2-file·gitignored·task 분리 | S(+O) | 외부 관찰 불변식은 S; 검증 규칙 세부(`Test-ValidPerspective` 동형 등)는 O(`scripts/lib/path.ps1`) |
| §2 | input.md 5-H2 + informational sections(Stage/Purpose/Target files/Validation evidence/Known concerns 2종/Framing self-check/Reference sweep) + placeholder namespace | S(+O) | "AI-authored·5-H2·informational 의미·Known concerns 2종 구분·stale-by-omission 연동"은 S; 정확 heading/regex/금지 문구는 O(`templates/review-input.md`+`review-input-verify.ps1`) |
| §3 | result.md dual-authorship·verdict 어휘 shape·4 disclosure H2·provenance 블록(non-gate) | S(+O) | dual-authorship·verdict 어휘·4-H2 invariant·provenance=machine run-fact 는 S; 정확 shape 는 O(`templates/review-result.md`+`review-verify.ps1`+`review-run.ps1`) |
| §3a | R1 Markdown evidence convention — referencing 의미·4중 부정(재실행/oracle/freshness/SoT 아님) | S | evidence 의미 경계의 정의 소비자 = review 흐름(§3 분류 참조) |
| §3b | mechanical behavior claim 의 minimal reproducible check(reviewer 측 P4 + operator 측 O1=§5.7) | S | narrow probe vs broad reproduction 경계 포함 |
| §3c | Counter-argument convention(optional·non-parser)·boilerplate 완화·mirror 목록 | S(+O) | convention 의미·non-parser 지위는 S; point-of-use 문안은 O(templates/skill) |
| §3d | reviewer reproduction opt-in — 역할 분리·opt-in 최소 boundary 8요소·default·non-repro=limitation·narrow/broad 경계·예시 | S | §3d.7 예시 열거는 H(원리 문장만 S) |
| §4/§4a | script 책임 = deterministic gate only(7 gate)·하지 않는 일·entry point 3종 동작 | S(+O) | "기계는 의미 판단 없음·7 gate 의 의미·sidecar 금지"는 S; per-script 분기/인자 세부는 O(scripts) |
| §5 | operator-role AI 책임 7항 | S(+O) | 의무의 invariant 는 S; operative 절차는 O(SKILL) |
| §5a | operator stance 7규칙(target 정확성/off-repo/stop-report/retraction/4-boundary/4-class sweep/engine 독립) | S | §5a.6 sweep 의 4-class 는 repo 공통 규칙(docs-working-model·glossary)과 의미 일치 — spec 은 review 도메인 적용면(점검 기록 자리 = input `## Reference sweep`)만 명세해 이중 정의 회피 |
| §6 | verdict 어휘 3종 + blocking 정의 | S | 어휘 불변(hard boundary) |
| §6a | verdict→next-action mapping + output consumption + staleness 연동 | S(+O) | mapping 의무는 S; operator 행동 mirror 는 O(SKILL step 7) |
| §6b | 10-field final report schema + reviewer guard status + surfacing | S(+O) | 축 분리(invocation/artifact-pass/corrective 3축) invariant 는 S; "policy origin = DECISION_RECORD" 문구는 retire 와 함께 소멸(spec 이 schema 의 spec-of-record 승계, 기록 = git history) |
| §6c | change-class validation matrix + 미실행 보고 규약 + 용어 home=tests/README | S(+O) | 정책 invariant·보고 규약은 S; suite 용어 정의는 O(tests/README.md — 존속) |
| §7 | staleness·stale-by-omission | S | |
| §8 | source/target/runtime 경계(log/ gitignored) | S+I | log/ footprint 는 I(cross-domain interface) |
| §9 | retention = manual 단위 삭제·auto-prune 없음 | S | |
| §10 | non-goals 열거(sidecar/aggregation/multi-reviewer/lint 비도입 등) | S | durable 금지 경계로 재구성(개별 역사 사유는 H) |

### 1.2 `docs/contracts/evidence/EVIDENCE_CONTRACT.md` — 두 층 분리(Design 판정)

| 절 | 분류 | 비고 |
|---|---|---|
| 목적/범위(log/evidence = log/ 하위 runtime·gitignored·snapshot 비포함) | I | generic 자리·성격 — footprint 경계의 일반 성격(owner 불변); spec 은 cross-domain interface 로 참조 |
| 경로 규약(`<scope>/<case>/`)·권장 파일 구성(5-file)·single-Markdown bundle(R1 form)·양립 규칙·R1 referencing 한정 | S | evidence 파일 형식 규약 — 정의 소비자 = review 흐름 |
| MVP 규칙(강제 없음·품질 게이트 아님·shape gate 는 scripts 책임) | S | |
| Manual capture recipe(사전 결정·절차 6단계·PowerShell snippet) | H | 튜토리얼 서사 — spec 은 실행 명령 시퀀스를 담지 않음; 단 "evidence 는 review record 의 input/output 이 아니다·sidecar 아니다" 경계 문장은 S |
| review subsystem 경계·source vs runtime 경계·non-goals·향후 확장 | S | 향후 확장 절의 "경로·파일명 default 유지" 의도는 S 의 durable boundary 로 |

### 1.3 `docs/policies/REVIEWER_CONFIG_POLICY.md` — 절별

| 절 | 분류 | 비고 |
|---|---|---|
| Config location(ToolRoot 해석 위임) | S+I | ToolRoot 해석은 install-update/global-invocation interface |
| Precedence·Defaults(no built-in model·fail-fast·safe default xhigh·downgrade 한정) | S(+O) | invariant 는 S; 분기표 세부는 O(`scripts/review-run.ps1`+`config/reviewer.schema.json`) |
| Config key schema and enforcement status(per-key 표) | O | owner = `config/reviewer.schema.json` description(이미 per-key 기술) + scripts |
| Category policy(judgment/lookup/application 분리·soft-miss vs fail-fast·generic 12종·safe floor) | S(+O) | 분리 원칙·자동 추론 금지·safe floor 는 S; 분기 세부는 O |
| Output location·Reviewer boundary | S | canonical layout 한정·`-Reviewer codex` 단일 지원·verdict 비승인 |
| Reviewer-safe invocation(구조적 posture 3 flag·trade-off·verification status tested-vectors-only) | S | 구조적 safety + tested-vectors-only caveat 는 S |
| Run-fact reporting(H1 라인 열거) | O | owner = `scripts/review-run.ps1` emit + tests |
| Diagnostic Codex invocation reference | H | 진단 예시 |

### 1.4 `docs/policies/REVIEW_EFFORT_GUIDE.md` — 절별

| 절 | 분류 | 비고 |
|---|---|---|
| 상단 reconciliation note 2개(wired safe-default·config-backed category) | O/S | 실태는 scripts/config 가 소유; "safe-default 에서 의식적 downgrade 만" invariant 는 §1.3 의 S 와 합류(이중 진술 회피) |
| §3 원칙 5(quality gate≠approval·어휘 3종·target-bound·거대 diff 금지·effort ⟂ coverage) | S | contract 흡수분과 합류 — spec 한 곳에서 1회 진술 |
| §4 review-required / §5 skip 분류 | S(축약) | "review subsystem 자체 변경·contract 의미 변경·cross-subsystem 경계는 review + downgrade 금지 / 의미 무변경 docs·runtime artifact 는 skip 가능" 수준의 원칙 문장만 S; 항목 열거는 H |
| §6 effort 표·§7 target scoping 규칙·§8 phase 표·§10 checklist·§11 examples | H | advisory 서사 — 운영 가이드 상세는 git history(추후 필요 시 deployed skill 보강은 별도 round) |
| §9 verdict handling | S(합류) | contract §6/§6a 흡수분과 동일 내용 — 별도 흡수 없음(이중화 방지) |
| §12 final rules | H | 재진술 모음 |

### 1.5 `docs/systems/review/STATUS.md` — 3분리

| 항목 | 분류 | 비고 |
|---|---|---|
| Current state 5건(maintenance mode·LTS closed·strict C1 topology·entrypoint·verdict 비승인) | S | spec 목표 상태/lifecycle state 로 |
| Completed ledger 11행 | H | 행 자체는 git history; "현재 의미" 열 중 현행 사실은 contract→spec 경유로 이미 흡수됨을 행별 확인 — RV-05(§5a/§6a)·RV-06(§3c)·RV-07(IDEAS→§1.7)·RV-B-04(R1)(§3a)·RV-B-06(§3 provenance)·RV-B-07(category policy)·RV-B-08(strict C1) 전부 contract/active surface 에 현존 |
| ledger RV-B-06·RV-B-07 의 "Global activation a separate pending action (not performed)" | §4 | 시점성 기재 — 아래 §4 대조 입력으로 처분 |
| Open/historical(BACKLOG 포인터·idea-only 포인터·S6 done·closed history 포인터) | H | 포인터들은 retire 와 함께 소멸; open 실체는 §1.6 |
| Accepted residual risks 2건(operator narrow-scope over-confidence · bash chain final-exit-code false-fail) | B | row 문안 후보 = §1.6 |

### 1.6 `docs/systems/review/BACKLOG.md` — 행별 이주(+신규 row 문안 후보)

`review_backlog.md` 형식: `ID | item | reopen/start condition`, header `next ID:` 단조.

| ID | 이주/신설 | row 문안 후보(한 줄 + reopen 조건) |
|---|---|---|
| RV-B-01 | 이주 | Review 2-pass/profile(user-facing 텍스트용 2차 profiling pass) — start: 별도 scoped goal + profiling 가치 입증 |
| RV-B-03 | 이주 | result.md wrapper/fence 렌더링 정규화 여부 — start: fence 로 인한 실독 사례 누적 시 별도 scoped goal |
| RV-B-04 | 이주 | no-exec/no-write reviewer 의 잔여 role-boundary framing(R1 은 closed) — start: 별도 scoped goal |
| RV-B-05 | 이주 | review input governance open channel(누적 governance 신호의 묶음 처리 + verdict-vocabulary 추가 이행) — start: 명확한 패턴 누적 시 별도 scoped goal |
| RV-B-09(신설) | STATUS residual risk 1 | operator narrow-scope over-confidence(좁힌 input 작성) — 수용된 잔여 위험; mitigation = 독립 Codex review + SKILL step 4 + retraction 규율; reopen: 현 패턴을 넘는 구체 신규 증거 |
| RV-B-10(신설) | STATUS residual risk 2 | `;`-chain 마지막 비-0 종료가 review-verify 성공을 가리는 보고 관례 위험 — reopen: 현 패턴을 넘는 구체 신규 증거 |
| RV-B-11(신설) | IDEAS 1 | (idea-only — implementation backlog 아님) devil's-advocate pre-pass orchestration — reopen: 반복 false-negative 또는 model-bias 증거 + 별도 사용자 결정 + 별도 scoped goal |
| RV-B-12(신설) | IDEAS 2 | (idea-only — implementation backlog 아님) multi-reviewer consensus/calibration loop — reopen: RV-B-11 과 동일 증거 + maintenance-mode exit 의 별도 승인(2조건 동시) |

closed tombstone 3행(RV-B-06/07/08)은 row 미생성(행 삭제 원칙). `next ID: RV-B-13`. tombstone 예외 판정 입력: RV-B-06/07/08 의 live inbound 참조는 `docs/backlog/INDEX.md`(행 갱신 대상)·STATUS·PROVENANCE_SPEC(둘 다 retire)뿐 — sweep 후 잔존 시에만 예외 발동(§2).

### 1.7 `docs/systems/review/IDEAS.md` — 항목별

| 항목 | 분류 | 비고 |
|---|---|---|
| idea-only 2건(devil's advocate·multi-reviewer) | B | §1.6 의 RV-B-11/12 — "idea-only" class 구분과 4단계 승격 gate 는 reopen 조건 문안에 압축 |
| "What is NOT in this document"(Option A/B·vertical-horizontal 분리) | S(축약)+H | "Counter-argument parser 강제(Option A) 비도입·escalation 은 별도 승인" 경계는 contract §3c.5 흡수분과 합류; 나머지 분리 서사는 H |
| Relationship/discipline 절 | H | |

### 1.8 당시 lifecycle 기록 10종 — unique live 의미 판정

| 파일 | unique live 의미 | 처분 |
|---|---|---|
| REVIEW_POLISHING_DECISION_RECORD.md | ① canonical terminology(coverage 5축 + corrected-state re-review 등) — contract §6b 가 압축 사용·SKILL 이 mirror 하나 **정의의 명시 home 은 이 문서뿐** → S(spec 이 5축 어휘 정의 승계) ② role-neutral(caller/reviewer) binding 원칙 → S ③ accepted invariants 20 — 대조 결과 전부 contract(§3/§3c/§5a/§6/§6a/§6b/§10)·정책·구현에 현존, 단 invariant 12("high effort 는 poor packet 보상 못함")·15("semantic 판단 기계화 금지")는 S 로 명시 승계 ④ 17 downstream 보존 문장 — 전부 위 ①~③·contract 흡수분과 동치 ⑤ 10-field schema — contract §6b 로 이전 완료(D1) | 흡수 후 retire |
| REVIEW_POLISHING_IMPLEMENTATION_PLAN.md | 없음 — batch 분해·gate 정의는 구현 완료된 회차 서사; §9 invariants 는 DECISION_RECORD 재진술 | retire |
| REVIEW_POLISHING_BATCH_A_SPEC.md | 없음 — Gate1/2 조사와 Batch B/C spec 은 구현·검증 완료(`review-run.ps1`·`review-safety-negtest.ps1` 가 owner) | retire |
| REVIEW_POLISHING_BATCH_D_SPEC.md | H1/H2/H3 세 home 분류(§2) — contract §6b 가 live 참조 → S(보고 계층의 ownership boundary 문장으로 승계) | 흡수 후 retire |
| REVIEW_RESULT_PROVENANCE_SPEC.md | vendor/adapter/version neutrality binding — contract §3·§4a·정책에 현존(S 합류); 나머지는 P1~P4 회차 기록; "activation pending" → §4 | retire |
| REVIEW_ARTIFACT_PERSPECTIVE_LAYOUT_PLAN.md | 없음 — strict C1 채택·구현 완료(contract §1 + `scripts/lib/path.ps1` 가 owner); C1/C2/C3 비교는 design 서사 | retire |
| REVIEW_INPUT_KNOWN_CONCERNS_HYPOTHESIS_FORM_PLAN.md | 없음 — two-kind convention 은 contract §2 에 현존 | retire |
| REVIEW_LOCAL_VALIDATION_CLOSEOUT_POLICY_PLAN.md | 없음 — §6c + tests/README 에 현존("policy origin" 지위는 git history 로) | retire |
| REVIEW_RUNNER_STDOUT_ANCHOR_TEST_PLAN.md | 없음 — tests/README.md 에 codify 완료(tests/README:67 의 "design rationale" 포인터는 갱신 대상 — §2) | retire |
| REVIEW_VALIDATION_EVIDENCE_REPRODUCTION_POLICY_PLAN.md | 없음 — contract §3d 에 현존 | retire |

## 2. inbound 참조 4-class 지도

조사 방법: retire 대상 17파일명 전체 + 경로 bucket(`docs/contracts/review|evidence`·`docs/systems/review`) 의 case-insensitive 전수 검색(tracked 표면 한정). 잔재 문서 상호 참조는 retire 동반 소멸이라 제외.

**(a) filename/path class — 갱신 대상 표면과 갱신 방식 후보:**

| 표면 | 참조 | 갱신 방식 후보 |
|---|---|---|
| `scripts/review-run.ps1` 주석 4건(:131·:148·:377 정책, :414 DECISION_RECORD) | 배포·비-behavior | 주석을 자기완결 문구 또는 review_spec 경로로 재서술 |
| `scripts/review-safety-negtest.ps1` 주석 1건(:25 BATCH_A_SPEC) | 배포·비-behavior | 동일 |
| `config/reviewer.schema.json` description(경로 1건 + "decision record"/"Batch B"/"U9" 의미 언급 다수) | 배포·비-behavior | description 을 자기완결 문구로 재서술(정책 실질은 이미 본문에 있음) |
| `tests/review-run.Tests.ps1` 주석 1건(:622 contract §3c) | 비-behavior | review_spec 재지향 |
| `tests/README.md` 3건(:27 contract·:41 contract §6c·:67 STDOUT plan) | 문서 | review_spec 재지향(§6c 는 "rationale home" 문구 함께 정리) |
| root `CLAUDE.md`/`AGENTS.md` trigger map Review 행(contract·STATUS) | instruction surface | review_spec/backlog 로 재지향(mirror-edit + parity) |
| `README.md`(:42·:78 contract, :82·:138 EVIDENCE, :140 정책, :141 contract, :150 STATUS+BACKLOG 외 long line 수 곳) | 공개 landing | review_spec/backlog 재지향(landing 기능 보존, 문구 최소 수정) |
| `docs/README.md` §5(contracts 행의 review/·evidence/, systems 행) | orientation | review 도메인 행 신설 + contracts/systems 행의 혼합 상태 반영(Level-1 gate) |
| `docs/current/REPO_READING_GUIDE.md` Q2/Q3(+:34 외 산재 3곳) | 구형 routing | Q2/Q3 의 review 항목 이관·제거(가이드 자체 retire 는 P) |
| `docs/contracts/README.md`(review/·evidence/ 행) · `docs/policies/README.md`(정책 2행) | 계층 README | 행 제거(계층 자체는 존속 — P 소관) |
| `docs/backlog/INDEX.md` 4건(RV-B 행·tombstone 언급) | routing index | review 행을 review_backlog 재지향으로 갱신 |
| 타 도메인/계층 문서(pointer 수준만): `SHARED_GLOBAL_INVOCATION_CONTRACT.md`(2) · `docs/decisions/POST_MVP_PLAN.md`(2+2) · `docs/decisions/DECISIONS.md`(2+1+2) · `docs/decisions/GLOBAL_ADOPTION_DECISION.md`(2) · `docs/project/AI_HARNESS_TOOLSET_SCOPE.md`(1+1) · `docs/project/TOOLING_POSITION.md`(1) · `docs/roadmap/INDEX.md`(1+1) · `docs/policies/CLI_ENVIRONMENT_ASSUMPTIONS.md`(1) · `docs/systems/install-update/STEP3_INSTALL_UPDATE_DECISION_GUIDE.md`(2) · `docs/systems/install-update/IDEAS.md`(1) · `docs/systems/skills/STATUS.md`(3) · `docs/systems/skills/FUNCTION_LEVEL_SKILL_ARCHITECTURE_PLAN.md`(4) · `docs/architecture/instruction-surface/` 7파일(GSF_B2_CLASSIFICATION 12+15+3 포함 약 30건) | legacy 잔존 | 경로만 review_spec(또는 git history 결정 문장)으로 치환 — 의미 재진술 정리는 소유 batch(과거 기록은 "당시/구(현 …)" 주석 규약) |

**(b) bare-token/ID class:** `RV-B-01..08`·`RV-01..07`(backlog INDEX·잔재 내부) — INDEX 행 갱신과 §1.6 이주로 해소, 잔존 시 tombstone 예외 판정 · `U9`/`U10`(config schema description·정책·잔재) — schema 재서술과 함께 자기완결화 · `strict C1`/`S6`/`Batch A~D`/`Phase 1·2`/`LTS`(잔재 내부 + skills STATUS·architecture 기록의 당시-주석) — 과거 기록 표면은 "당시" 주석 수준만.

**(c) folder-as-bucket class:** `docs/contracts/`(README 의 "review/·evidence/" 버킷 산문) · `docs/systems/review/` 산문("그 폴더의 PLAN/SPEC 류") — docs/README·contracts README 갱신으로 해소. 빈 폴더 제거 대상: `docs/contracts/review/`·`docs/contracts/evidence/`.

**(d) semantic-phrasing class:** "the canonical artifact contract"·"adopted decision record"·"review-system polishing implementation plan Batch B"(config schema description) · "review effort/cost operating guidance"(README long line·CLAUDE/AGENTS 행) · "current review system status"(REPO_READING_GUIDE Q2) — 각각 (a) 의 해당 표면 갱신에 동반해 의미 기준으로 재점검(grep 불가 class).

비대상 판정: `tests/install-update.Tests.ps1:320` 의 `review_polishing` 은 `log/` runtime 폴더명 regex(docs 참조 아님) · tests/README 의 "88/88 = review-system suite" 정의는 tests/README 자신이 home(존속).

## 3. `log/evidence/**` 소비자 분류 (Design 두 층 분리의 재확인 입력)

조사 방법: `log/evidence` 토큰의 tracked 표면 전수 검색(26 표면; 잔재·신규 lifecycle 문서 제외 후 분류).

**① 경로 interface 사용(형식 의미 비의존 — 갱신 불필요 또는 pointer 만):**
`snippets/CLAUDE_SNIPPET.md`·`snippets/AGENTS_SNIPPET.md`(bootstrap topology 의 runtime 경로 열거) · `snippets/rules/no-background-or-hidden-state.md` · `rules/docs-working-model/docs-working-model.md`+checklist/template(closeout evidence 기록처) · `docs/brief/brief_spec.md`(대응 근거 기록처) · `docs/systems/install-update/GLOBAL_INSTALL_UPDATE_MODEL.md`(footprint)·`UNINSTALL_LIFECYCLE_DESIGN.md` · `docs/project/AI_HARNESS_TOOLSET_SCOPE.md` · `docs/decisions/GLOBAL_ADOPTION_DECISION.md` · `scripts/review-safety-negtest.ps1`+`tests/review-safety-negtest.Tests.ps1`(negtest evidence 산출 위치 — 경로 사용; 형식 강제 없음) → **전부 ①층과 정합. 분리 판정 유지.**

**② evidence 형식 의미 의존(spec 흡수 후 그 의미의 거처가 review_spec 이 되는 표면):**
`docs/contracts/evidence/EVIDENCE_CONTRACT.md` 자신(retire) · `docs/contracts/review/REVIEW_RESULT_CONTRACT.md` §3a(retire — S) · `templates/review-input.md`+`snippets/claude-skills/ai-harness-review/SKILL.md`(R1 guidance — **self-contained 운반, 계약 경로 미참조 → 무갱신**) · `README.md` :82·:138(EVIDENCE_CONTRACT 광고 — pointer 갱신 대상, §2(a)) · `docs/policies/REVIEW_EFFORT_GUIDE.md`(retire).

**결론(재확인):** 비-review 표면 중 evidence 파일 *형식 의미* 에 의존하는 곳은 없다 — 전부 경로/기록처 interface 사용. Design 의 두 층 분리 판정은 소비자 실태와 정합.

## 4. STATUS ledger "global activation pending" 대조 입력 (open decision #2)

- 대상 기재: STATUS Completed ledger RV-B-06·RV-B-07 의 "Global activation a separate pending action (not performed)."
- 검증 방법: channel 3 글로벌 stable 설치본(`INSTALL.md` 의 채널 정의)의 `scripts/review-run.ps1` 에 provenance append 표면(RV-B-06 P3)이, `config/reviewer.json` 에 `categoryPolicy`(RV-B-07 U9)가 존재하는지 read-only 대조.
- 조사 결과(이 round 의 read-only 대조): **둘 다 존재** — 설치본 runner 는 provenance append 함수를 포함하고, 설치본 config 는 `categoryPolicy` 를 포함한다.
- 처분 입력: 기재는 **stale**(작성 시점 이후의 글로벌 update 로 해소됨) → backlog row 불필요, 기재 없이 종결이 합치. 최종 판정·기록은 구현 단계의 operator report 소관.

## 5. review_spec 8절 골격 매핑 (작성 입력)

| spec 절 | 들어갈 성분(§1 분류의 S 항목) |
|---|---|
| Header | 무엇(spec-of-record 승계)/체인 결과(도메인 폐쇄)/아닌 것(operative authority 아님·승인 아님) |
| 목표 상태 | review 정체(quality gate≠approval)·canonical artifact 모델(three-level·2-file·write-once·dual-authorship)·verdict 어휘·coverage 5축 어휘·operator stance(정확성/정직/retraction/sweep)·reviewer 경계(read-only·no-silent-fix·reproduction opt-in)·staleness 모델·maintenance posture |
| Owner surface 지도 | scripts 5종+lib/path · templates 2종 · SKILL · config+schema · tests (행동별 소유 표) |
| Durable boundary | §10 non-goals 재구성·어휘/규약/계층 불변·config-driven(no hardcode·fail-fast)·reviewer-safe 구조 posture(tested-vectors-only)·retention manual·umbrella 부활 금지·effort ⟂ coverage·downgrade 한정·기계화 금지(semantic 판단) |
| Cross-domain interface | log/ footprint(evidence ①층 포함)·ToolRoot 해석(install-update/global-invocation)·glossary route-only·brief 비경계(Brief≠review input/output)·H1/H2/H3 보고 계층 ownership |
| Validation expectation | review-system suite+관련 Pester·verify-ps1(.ps1 정책)·1:1 방향 1/2·기록처 규약 |
| Review focus | 목표 상태 유지·single-home·비-behavior 경계·absorption proof(향후 변경 시) |
| Lifecycle state | live flip 시점 기재(closeout) + backlog 포인터 |

## 6. 잔여 판정 메모 / edge cases

- `docs/systems/review/` 폴더 자체: 17파일 retire 후 비게 되면 폴더 제거(계층 `docs/systems/` 존속은 P 소관).
- `REVIEW_EFFORT_GUIDE` 의 brief_spec·POST_MVP_PLAN 참조: guide 가 retire 되므로 별도 조치 불요.
- glossary 갱신 범위(구현 단계·별도 승인): pending 2종 행 제거 + "Term ownership and close conditions" 의 close 기록 1줄 + accepted-with-owner-boundary 의 `review owner surface` 항은 존속(변경 없음).
- 신규 lifecycle 문서(review_design/plan/이 문서)의 잔재 참조는 closeout 의 자기-retire 로 해소(별도 sweep 항목 아님).
- contract §6b 의 "policy origin"·§6c 의 "policy origin (design)" 문구: 두 원천 문서가 함께 retire 되므로 spec 재구성 시 흔적 포인터를 만들지 않는다(보존 = git history).
