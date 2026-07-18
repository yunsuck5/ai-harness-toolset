# review Spec

## Header

**이 문서는 무엇인가.** review 도메인의 **목표 상태 명세**(spec-of-record)다 — Codex review subsystem 이 무엇이고, 어떤 active surface 가 그 행동을 소유하며, 어떤 경계가 항구적으로 유지되는지를 normative 문장으로 명세한다.

**이 체인이 끝나면 무엇이 되는가.** 이 spec 과 `review_backlog.md` 가 review 도메인의 live 표면이 되고, 구계열 review 문서(contracts·policies·systems 의 17파일)는 retire 되어 도메인이 `docs/review/` 안에서 닫힌다.

**이 문서가 아닌 것.** 구현 절차서 아님 · operative authority 아님(behavior 는 active surface 가 소유하고 이 spec 은 명세·대조될 뿐) · 프로젝트 공용으로 채택·기각된 용어의 한 줄 의미 home 아님(`rules/terminology-glossary.md`; review-local 의미는 이 owner가 소유). 이 spec 은 mutation/commit/push 승인이 아니다(1회 진술).

## 목표 상태

**Review 의 정체.** review 는 한 작업(`/goal`) 또는 한 review gate 에 대한 **독립 reviewer 의 검토를 canonical artifact 쌍으로 닫는 quality gate** 다. 어떤 verdict 도 commit / push / publish / merge / release / deployment / adoption / config mutation 을 자동 승인하지 않는다 — 다음 단계는 항상 사용자의 별도 명시 결정이다. review subsystem 은 **maintenance mode** 로 운영된다: 신규 기능·reviewer adapter·multi-reviewer orchestration·review-history DB·cross-run 집계·자동 retention 은 별도 scoped 승인 없이 도입되지 않으며, bug fix 와 계약 명확화는 in-scope 다.

**Canonical artifact 모델.** 한 review 기록은 `<ProjectRoot>/log/review/<review-task-id>/<perspective>/pass-NN/` 의 **three-level layout** 으로 닫힌다. `<review-task-id>` 는 작업/gate 단위이고 세션 id 가 아니다. `<perspective>` 는 review 관점(예: `local-correctness` / `system-coherence`)으로 **필수**이며 operator 가 명시한다 — 자동 추론과 two-level fallback 은 없고, single path segment 안전 규칙(charset/length·`..`·separator 금지)을 따른다. `pass-NN` 은 그 perspective 안의 corrective attempt 로 **per-perspective** 로 증가하고, 각 pass 디렉터리는 **write-once** 다 — 보완은 새 pass 로만 한다. pass 당 canonical record 는 `input.md` + `result.md` **두 파일뿐**이며 sidecar(JSON·hash·외부 staging)는 계약의 일부가 아니다. strict 도입 이전의 two-level 기록은 tool 이 발급/검증하지 않는 manual-readable 과거 기록이다(이주·삭제 없음).

**input.md (operator 작성).** `input.md` 는 operator-role AI 가 작성하고 reviewer 입력 전체를 한 파일로 담는다. required H2 5종(Context / Required inspection paths / Review questions / Constraints / Final verdict)의 본문은 비어 있지 않아야 하고, informational section 들이 의미를 보탠다 — `## Target files` 는 source-managed 파일만 담고, `## Validation evidence` 는 validation 실행 claim 의 근거 evidence 경로를 담으며(부적용 round 는 짧은 N/A), `## Known concerns` 는 **confirmed disclosure** 와 **open hypothesis** 두 종류를 구분해 담고(확정 사실을 가설로 위장하지 않는다 — disclosure 회피 금지), `## Framing self-check` 는 operator 가 자기 input 의 verdict 유도 여부를 사전 점검한 기록을, `## Reference sweep` 은 이름/위치/식별자/구조를 바꾸는 round 의 sweep 증거를 담는다. 활성 placeholder 는 `AI_TO_FILL_` namespace 로 한정되고 미치환 시 기계 거부된다. 정확한 heading 집합·placeholder regex·금지 문구의 값은 active surface(template + input verifier)가 소유한다.

**result.md (dual-authored).** `result.md` 의 verdict/disclosure 본문은 active reviewer adapter 가 작성하고, runner 가 그 끝에 machine run-fact 인 provenance 블록을 append 한다 — 이 블록은 reviewer 의 판단이 아니고 새 parser gate 를 도입하지 않으며, 값의 출처는 runtime/config/adapter/self-report 이지 caller 선언이 아니다. reviewer 산출 실패 시 provenance 를 발명하지 않는다. verdict 는 `## Verdict` heading 1개 아래 첫 비어있지 않은 줄의 **lowercase 정확 일치** 로만 읽는다. 4개 disclosure H2(Blocking findings / Non-blocking concerns / Review limitations / Assumptions relied on)는 각각 정확히 1회 존재해야 한다(기계 gate). `## Counter-argument` 는 verdict 에 대한 strongest case AGAINST 를 적는 **non-parser, strongly-recommended** 관례다 — substance 없는 round 는 짧은 literal 로 두고 ceremonial boilerplate 를 피하며, boilerplate 누적은 escalation 의 증거 입력이다. 정확한 shape 의 값은 active surface(result template + verifier)가 소유한다.

**Verdict 어휘와 next-action.** verdict 는 정확히 세 값이다: `yes`(blocking 없음 — 후속은 사용자 결정, 자동 진행 금지), `no`(blocking 있음 — 승인 scope 안 finding 은 corrective 후 같은 task·perspective 아래 새 pass 로 corrected-state re-review, scope 밖 finding 은 stop/report; `no` 만으로 batch 를 닫지 않는다), `yes with risk`(`yes` 의 동의어가 아니다 — risk substance 의 명시적 사용자 수용 또는 re-review 경로가 필요하다). blocking 여부의 source-of-truth 는 `## Blocking findings` 본문이며, blocking/non-blocking 경계는 review scope 와 finding substance 가 함께 결정한다. operator 는 verdict line 만으로 다음 행동을 정하지 않고 4 disclosure 본문을 함께 읽는다 — shape PASS 는 commit fitness 의 자동 보증이 아니다.

**Coverage 어휘 (축 분리).** `dual-perspective coverage` 는 local correctness review + system coherence review 두 관점의 충족을 뜻하는 **coverage 정책**이며 reviewer 호출 횟수가 아니다. 한 packet 으로 두 관점을 다루면 `single-invocation dual-perspective packet`, 관점별 분리 호출이면 `two focused invocations`, 한 관점의 의도적 생략/축소는 `coverage-limited review`(caller rationale + 최종 보고 disclosure 필수), reviewable 변경 없음은 `no-reviewable-change report`(caller-side 보고, verdict 아님)다. **invocation count · artifact pass count · corrective loop count 는 서로 다른 축**이며 한 토큰으로 합쳐 표기하지 않는다.

**Operator stance.** operator-role AI 는: ① target file set 을 실제 변경 집합(또는 호명된 subsystem 의 tracked 집합)과 대조해 정확히 잡고 의도적 제외는 disclose 한다 ② off-repo/참고 자료를 source-of-truth 로 승격하지 않고, reviewer 가 읽어야 하면 본문을 input 에 inline 한다 ③ 승인 scope 밖 source mutation·runtime/외부/user-global 영역 mutation·설치 payload refresh·commit 류 실행이 필요해 보이면 stop/report 한다 ④ 이전 판단·작성·주장의 오류를 발견하면 무엇을/왜/현재 상태로 분리해 **retraction 보고** 한다 ⑤ source repo / runtime artifact / 외부 참고 / user-global 의 네 경계를 구분해 다룬다 ⑥ 이름/위치/식별자/구조를 바꾸는 round 에는 4-class reference sweep(점검 기록 자리 = input 의 `## Reference sweep`; 삭제 변경은 case-insensitive·변형·bare-section 까지)을 수행한다 ⑦ review tooling 자체를 수정하는 작업의 review 는 변경 중인 in-dev runner 가 아니라 **안정 엔진**(글로벌 stable ToolRoot 또는 pre-change 독립 checkout)으로 실행하고, 안정 엔진 실패 시 임의 fallback 없이 stop/report 한다 ⑧ mechanical behavior claim(regex/parser/script 동작 주장)은 작성 전 minimal reproducible check 로 점검하고 불가하면 unverified 로 disclose 한다.

**Reviewer 경계.** reviewer 는 read-only 또는 동등 guard 아래에서 판단만 한다 — review 중 어떤 표면도 mutate 하지 않고, fix 하지 않으며, packet 결함을 silent repair 하지 않고, 누락 evidence 를 재구성하지 않으며, scope 를 확장하지 않는다. 누락/stale/모호는 limitation·gap·risk·finding·re-review 요구로 **보고** 한다. mechanical claim 에는 좁은 합성 probe(수 초)가 기대되지만, target 의 broad validation/build/test 재실행은 **opt-in** 이다 — review input 이 exact command·작업 디렉터리·read/write 기대·허용 산출 경로·의존 가정·timeout·해석 경계·sandbox 한계 보고 방식을 명시해 authorize 한 경우에만 하고, 그렇지 않으면 evidence 를 inspect 하고 비재현 사실을 limitation 으로 보고한다. 비재현은 자동으로 target risk 가 아니다 — 승격에는 독립 근거(누락/stale evidence·scope mismatch·정적 모순·명시적 고위험 공백)가 필요하다.

**Validation evidence (형식 규약).** evidence 는 `<ProjectRoot>/log/evidence/<scope>/<case>/` 에 남기는 **reviewer-readable runtime supporting material** 이다. 형식은 5-file recipe(command/exit-code/stdout/stderr/notes + files/)와 single-Markdown bundle(`validation-evidence.md` — command/exit/stdout/stderr/notes 를 한 파일의 heading 으로) 이 양립하고, input 의 `## Validation evidence` referencing 대상은 **single bundle 한 형식으로 한정** 된다(5-file 은 일반 inspection path 로만). evidence 는 command 재실행이 아니고, deterministic truth oracle 이 아니며, freshness binding 이 아니고, source-of-truth 로 승격되지 않는다 — canonical review record 의 input/output/sidecar 도 아니다. 작성은 자발 관례이고 본문 정직성은 operator 책임이며 어떤 script gate 도 이를 강제하지 않는다. **operator-side validation scope 는 change class 에 비례한다**: script/runtime·parser gate·test code·install 경로 변경은 full suite 가 기대되고, docs/wording/formatting 류는 targeted 검증으로 충분하다 — 기대 validation 을 하향하면 change class·수행/미수행·사유·잔여 위험을 분리해 보고한다(미수행 자체는 결함이 아니고 정직 disclosure 가 요건이다). validation scope 용어의 정의 home 은 `tests/README.md` 다.

**Staleness.** pass 작성 후 그 review 가 묶인 source/docs/template/snippet/test 가 수정되면 그 pass 는 stale 이고, 같은 task·perspective 아래 새 pass 로 재검토한다. operator 가 호출 전에 알았던 concern 을 disclose 하지 않았음이 사후 발견되면 그 verdict 는 **stale-by-omission** 으로 후속 결정의 근거가 될 수 없다. stale 판단은 operator 와 사용자 책임이며 기계 검출은 도입하지 않는다.

**Script 책임 (deterministic gate only).** review scripts 는 의미 판단을 하지 않는다. 기계 책임은: pass 경로의 review-root + task-root containment 검증 · input 의 required H2/본문/placeholder 기계 gate · reviewer CLI 의 정확히 1회 실행 · result 존재와 verdict shape · 4 disclosure H2 의 1회 존재 · 종료 코드 전달 — 이것뿐이다. scripts 는 finding 의 의미·재검토 필요·후속 단계를 판단하지 않고, verdict 를 읽어 어떤 것도 자동 트리거하지 않으며, 본문을 sidecar 파일로 분산하지 않는다. runner 는 성공 시 단일 invocation 의 **H1 run-fact**(verdict·model/model-source·effort 3종·category 2종·reviewer-safe posture·engine identity·adapter kind/version)를 stdout 으로 emit 하고 동일 사실을 provenance 블록으로 result 에 append 한다.

**Config (전부 config-driven).** reviewer model 과 effort 는 config 가 source-of-truth 다. model 은 내장 default/fallback 없이 결손 시 **fail-fast** 하고, 구체 model version 은 외부 lifecycle 에 종속되므로 config 한 곳 외의 durable 표면에 적지 않는다. effort 의 유일한 내장 default 는 safe default(`xhigh`)다. `categoryPolicy` 는 **분류 = operator 명시 선택(judgment), 매핑 = config 기계 lookup, 적용 = runner** 의 분리를 따른다 — 자동 추론(변경 파일/Stage/LLM 기반)은 없다. 공급되었으나 부재한 key 는 soft miss(스칼라 fallback)이고, 존재하는 entry 의 결함은 fail-fast 다. 출하 key set 은 범용 변경 class 로 generic 하고 모든 entry 가 safe floor 로 출하된다 — floor 아래 값 튜닝은 운용 데이터 후의 별도 결정이다. per-key 의미·강제 상태의 기술 home 은 config schema 다.

**Reviewer-safe invocation (구조적).** reviewer 호출의 안전은 global user config 에 의존하지 않는다 — runner 가 매 호출에 read-only sandbox·승인 없음·user-config 무시·통제된 output channel 을 명시 강제하고, 결과 기록은 runner 가 통제한다(model 의 source-tree write 가 아니다). 이 보장은 **시험된 write vector 에 한정**되며 blanket guarantee 가 아니다 — 미시험 vector·타 플랫폼·도구 버전 변경은 한계로 남고, reviewer tool 교체 시 effort/model override·output shape·safety override 는 재도출 대상이다.

**보고 계층(H1/H2/H3).** 단일 invocation 이 deterministic 하게 관측한 사실은 **H1**(runner stdout run-fact + provenance), 여러 pass 를 가로지르는 집계와 caller 판단(coverage·packaging·세 count·re-review status·validation·git status·권고)은 **H2**(operator 의 최종 보고 — 10-field 분리, 없는 artifact 의 발명 금지, guard status 의 surfacing 은 권장이되 review-subsystem self-modification closeout 에서는 기대), schema 의 정의 자체는 **H3**(문서 wording)다. 같은 datum 이 H1 과 H2 에 나타날 때 역할 차이(관측 vs 집계·판단)를 보존한다. operator 최종 보고의 operative home 은 skill 이다.

**Retention.** 기록의 보존 단위는 task 디렉터리 또는 개별 pass 디렉터리이고, 삭제는 사용자의 수동 결정이다 — auto-prune/rotate/expire 는 없다. 실패한 pass 도 디스크에 남기고 보완은 새 pass 로 한다.

## Owner surface 지도

| active surface | 소유 행동 |
|---|---|
| `scripts/review-prepare.ps1` | three-level pass 디렉터리 발급 + input seed(기본; `-NoSeed` 시 빈 input 생성) + write-once 거부 + 다음 pass 번호 산정 |
| `scripts/review-input-verify.ps1` | input.md 의 required H2·본문·placeholder·금지 문구의 기계 gate |
| `scripts/review-run.ps1` | reviewer CLI 1회 실행 · reviewer-safe posture 강제 · model/effort/category 해소(분기의 구체 값 포함) · verdict shape 확인 · H1 run-fact emit · provenance append |
| `scripts/review-verify.ps1` | input shape + (RequireResult) result 존재·verdict shape·4 disclosure H2 count 의 기계 gate |
| `scripts/review-safety-negtest.ps1` | reviewer-safe posture 의 부정 시험(의도된 실 실행; 통상 suite 밖) |
| `scripts/lib/path.ps1` | task-id/perspective/pass 의 segment 검증과 review-root/task-root containment |
| `templates/review-input.md` / `templates/review-result.md` | 두 artifact 의 shape 기준 + point-of-use 작성 guidance(Known concerns 2종·Framing self-check·Reference sweep·Counter-argument 문안) |
| `snippets/claude-skills/ai-harness-review/SKILL.md` | operator workflow(타깃 선정 Mode A/B·root 해석·엔진 독립·단계 절차·verdict→next-action·H2 최종 보고) — self-contained 배포 표면 |
| `config/reviewer.json` + `config/reviewer.schema.json` | model/effort/categoryPolicy 의 **값** + per-key 의미·강제 상태 기술 |
| `tests/review-*.Tests.ps1` · `tests/path.Tests.ps1` | 위 행동의 지속 검증(suite 용어의 정의 home 은 `tests/README.md`) |

behavior 의 authority 는 위 surface 들이다(root *Final hard rule*) — 이 spec 은 명세하고 대조될 뿐이며, spec 과 구현이 어긋나면 행동 변경이 아닌 한 spec 이 정정 대상이다.

## Durable boundary

- **verdict 어휘는 `yes` / `no` / `yes with risk` 셋으로 불변이다.** 새 token·inline 형태·대소문자 변형은 도입하지 않는다.
- **canonical layout 과 2-file 규약은 불변이다** — three-level·per-perspective pass·write-once·pass 당 input/result 두 파일. sidecar JSON·hash binding·외부 staging·machine-readable verdict 사본·flat run-id layout 은 도입하지 않는다.
- **parser gate 는 확대하지 않는다.** 현행 기계 gate(입력 5-H2·verdict shape·4 disclosure H2 count) 너머의 semantic adequacy/concern completeness/evidence sufficiency lint·sub-shape lint·자동 검증은 도입하지 않는다 — semantic 판단은 reviewer/operator judgment 로 남는다(기계화 금지). 재개는 unsound verdict 를 유발한 구체 증거에 한정된다.
- **자동화 금지 경계**: review history 집계·DB·dashboard·multi-reviewer orchestration·fallback model 자동 사용·retry/auto-fix loop·verdict 로 후속 단계를 트리거하는 wrapper·CI 통합·daemon/watcher/scheduler·자동 retention·stale 자동 검출·evidence freshness/hash/mtime binding·deterministic validation runner 는 도입하지 않는다.
- **effort ⟂ coverage.** effort 는 coverage·evidence·packet 품질의 대체물이 아니다 — 낮은 effort 가 좁은 coverage 를 정당화하지 않고, 높은 effort 가 부실한 packet 을 보상하지 못한다. safe default 에서의 downgrade 는 명확히 단순한 local correctness packet 에 한정되며, review subsystem 자체의 변경·contract 의미·cross-subsystem 경계·보안/권한 민감 변경은 downgrade 하지 않는다.
- **model 비고정.** 구체 reviewer model version 을 scripts/docs/templates 의 durable 기본값으로 박지 않는다 — config 가 유일한 source-of-truth 이고 결손은 fail-fast 다.
- **evidence 는 승격되지 않는다** — runtime artifact 이며 commit/push 대상이 아니고 truth oracle 이 아니다. source 트리에 evidence 파일을 두지 않는다.
- **review 는 Brief 와 비경계다.** Brief 는 review 의 input 도 output 도 아니고, brief shape 검사의 PASS/FAIL 은 verdict 가 아니다.
- **rejected umbrella 의 부활 금지** — evidence/global-invocation/instruction-surface 를 독립 도메인·시스템·공유 계약으로 되살리지 않는다(glossary 의 rejected 분류 유지).
- **`.gitignore` 자동 변경 금지** · target project 의 instruction file/global filesystem 자동 변경 금지 · `log/` 는 release/snapshot 에 포함하지 않는다.
- **idea-only 항목의 승격 경계**: backlog 의 idea-only 행(adversarial pre-pass·multi-reviewer 류)은 implementation 후보가 아니며, reopen 조건 충족 + 사용자 별도 결정 + 별도 scoped goal 없이 구현으로 진입하지 않는다. Counter-argument 의 parser 강제(과거 Option A)는 비도입 결정이 유지된다.

## Cross-domain interface

- **install-update (footprint 경계)**: `<ProjectRoot>/log/` 는 target project 의 유일한 persistent footprint 이고 `log/review/`·`log/evidence/` 는 그 아래 runtime 트리다 — gitignored 성격과 channel 구조의 owner 는 install-update 도메인(`INSTALL.md`)이며, 이 spec 은 그 경로 interface 만 의존한다. 타 도메인의 `log/evidence/**` 사용(기록처 지정)은 이 경로 interface 사용이고 evidence 형식 의미에 대한 의존이 아니다.
- **ToolRoot 해석**: review scripts 는 resolved `<ToolRoot>` 의 templates/config 를 읽는다 — channel 해석 순서의 owner 는 install-update/global-invocation 표면이고 이 spec 은 그 결과 경로만 의존한다.
- **terminology**: 프로젝트 공용으로 채택·기각된 용어의 한 줄 의미는 `rules/terminology-glossary.md` 가 single home 이다 — 이 spec 은 그 의미를 일관 사용할 뿐 재정의하지 않는다. coverage 5축 등 review 도메인 고유 운용 어휘의 상세 의미는 이 spec 이 소유한다(`review owner surface`).
- **글로벌 배포 티어**: 배포되는 review 표면(skill·templates·scripts·config)은 review 의미를 **self-contained** 로 운반한다 — 동작의 완성이 repo 의 review 도메인 문서 읽기에 의존하지 않으며, **review 도메인 문서로의 경로 참조를 갖지 않는다.** (비-review 문서로의 비-behavior 주석 참조 — 예: PowerShell 정책 주석 — 는 그 문서를 소유한 도메인의 경계이며 이 spec 의 대상이 아니다.) review 의미의 home 은 이 spec 과 그 active surface 들뿐이다.
- **brief**: 위 Durable boundary 의 비경계 진술 외에 brief 도메인의 semantics 를 참조하지 않는다.

## Validation expectation

- review-system suite(`tests/review-adapter` · `review-input-verify` · `review-prepare` · `review-run` · `review-verify` 의 `.Tests.ps1`)와 `tests/path.Tests.ps1` PASS 가 성립해야 한다. `tests/review-safety-negtest.Tests.ps1` 은 실 reviewer 실행을 동반하므로 의도된 실행에 한한다.
- `.ps1` 표면은 repo 정책(UTF-8 BOM + CRLF, `scripts/verify-ps1.ps1` PASS)을, 이 spec 과 `.md` 표면은 UTF-8 no BOM + LF 를 따른다.
- 이 spec 의 normative 문장은 구현에서 확인 가능해야 하고(방향 1), 구현의 외부 관찰 가능 행동·소유 경계 변경은 spec 문장 변경을 동반해야 한다(방향 2; spec 문장 변경이 불필요한 구현 변경은 리팩토링). 대응 근거의 기록처는 operator report / `log/evidence/**` 다.

## Review focus

- 이 spec 이 **목표 상태 명세로 유지되는가** — 회차 candidate 목록·실행 시퀀스·staging·review result·readiness 판정·시점성 상태가 유입되지 않는가.
- **single home 유지** — review 의미가 spec 밖에서 재진술되지 않는가(타 표면은 interface 참조만), 기계 세부(정확한 H2 enumeration·regex·precedence 분기·run-fact 라인 목록)가 spec 으로 복제되어 prose mirror 가 되지 않는가(그 값들은 active surface 소유).
- **behavior/비-behavior 경계** — review scripts/skill/templates/config 의 변경이 maintenance-mode 와 이 spec 의 행동 명세 안에 있는가; docs 측 정정과 행동 변경을 구분했는가(구현이 판정 기준).
- **어휘·layout·금지 경계의 불변** — verdict 어휘·three-level/2-file/write-once·parser gate 비확대·자동화 금지가 약화되지 않는가.
- **role-neutrality** — 운용 정책이 특정 vendor/tool/version 에 bind 되지 않는가(adapter 사실은 현재-구현 기술로만).

## Lifecycle state

- lifecycle 문서: 없음 — batch R closeout 에서 design / plan 은 retire(삭제)되었고 work packet 은 삭제되었다; 기록은 git history 가 보존한다.
- spec ↔ implementation: **live** — behavior 표면(scripts·templates·skill·config·tests)과 문서 표면(routing·backlog·inbound pointer·배포 표면의 review-문서 self-containment)이 이 spec 과 1:1 동기화되어 있다. 이후의 변경은 live-Spec 갱신(sync-required 전이) 규칙을 따른다.
- future work: open 항목·수용된 잔여 위험·idea-only 항목과 ID 발번(next ID)의 single home 은 `review_backlog.md` 다 — 항목 enumeration 과 next-ID 는 그 backlog 만 소유하며 본 spec 은 pointer 로만 참조한다.
