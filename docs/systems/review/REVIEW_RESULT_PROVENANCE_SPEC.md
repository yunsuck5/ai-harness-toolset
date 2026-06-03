# 리뷰 시스템 — result 아티팩트 reviewer runtime provenance 기록 (planning/design spec, 2026-06-03)

> **Implementation status (P2+P3+P4 implemented) — 2026-06-03.** 본 문서의 본문(§0–§14)은 **P1 설계시점(design-time) 기록**으로 유지된다 — 설계 근거·옵션·조사 결과의 출처다. 그 이후 **P2·P3·P4 가 모두 구현·리뷰·커밋·push 되었다 (RV-B-06 트랙 전부; P1 `77691c2` / P2 `fdde410` / P3 `fbd295e` / P4 `cfac1ed`). RV-B-06 은 closeout 되어 `docs/systems/review/STATUS.md` Completed ledger 로 이관(BACKLOG tombstone)됐고, activation/global update 만 pending 이다.**
>
> - **P2 (구현됨)**: `scripts/review-run.ps1` 이 active reviewer adapter 의 **kind** 와 **version** 을 runtime 에서 관측해 두 개의 H1 stdout run-fact `reviewer:` / `reviewer-version:` 를 (기존 Batch D2 run-fact 에 **additive** 로) emit 한다. adapter version 은 **P2 전에는 미관측**이었고, **P2 이후 active adapter 의 run banner 에서 관측**되어 H1 stdout 으로 emit 되며, 관측 불가 시 `not-observed`(no silent success). 관측은 adapter-isolated reader(`Get-CodexAdapterVersion`) 뒤에 격리.
> - **P3 (구현됨)**: `review-run.ps1` 이 verdict shape 가 usable 함을 확인한 뒤 **`result.md` 끝에 runner-authored `## Reviewer run provenance` 블록을 append** 한다 — runtime 관측값(adapter kind / version-or-`not-observed` / model / model-source / requested+effort-source+applied-effort / reviewer-safe posture / engine identity)을 machine 기록. 블록 heading·key:value 는 parser-gated heading(`## Verdict` + 4 disclosure H2)과 충돌하지 않아 **`review-verify.ps1 -RequireResult` 가 그대로 통과**하고 **새 parser gate 를 도입하지 않는다(informational)**. reviewer 산출 실패 시 provenance 를 발명하지 않으며, valid verdict 후 append 실패는 verdict 를 무효화하지 않되 loud 보고(`provenance-persisted: FAILED`). **result.md 는 dual-authored** — reviewer-adapter body + runner-appended provenance 블록(machine run-fact, reviewer judgment 아님; `docs/contracts/review/REVIEW_RESULT_CONTRACT.md` §3/§4, `templates/review-result.md`). source 는 runtime/config/adapter/self-report 이며 **`input.md` caller declaration 이 아니다.**
> - **P4 (구현됨)**: operator surfacing + mirror-label reconciliation (**docs-only**). `snippets/claude-skills/ai-harness-review/SKILL.md` step 6/7 가 persist 된 `## Reviewer run provenance` 블록을 읽어 reviewer-guard-status(adapter kind / version-or-`not-observed` / model·model-source / requested·effort-source·applied-effort / reviewer-safe posture[tested-vectors-only caveat 유지] / engine identity)로 surface 한다 — informational, not parser-gated; verdict ≠ commit/push 승인. README / OPERATOR_GUIDE_KR / CHATLOG_CONTRACT 의 single-author mirror 라벨을 dual-authored 로 정합(CHATLOG 은 mirror 문구만; chatlog 구현/스키마 불변). **runner(`scripts/review-run.ps1`)·`tests/review-run.Tests.ps1`·result-block shape·parser gate 불변**, activation 없음.
> - **여전히 binding**: **vendor/adapter/version neutrality**(concrete version durable hardcode 없음; codex 는 현재-adapter 사실).
>
> 따라서 본문이 P2/P3 를 "권고/미래" 로, version 을 "미관측" 으로, result.md 를 "self-describing 불가" 로, run-fact 를 "미persist" 로, 또는 "P2–P4 전부 미구현" 으로 기술하는 부분은 **P2/P3 전 설계시점 baseline** 으로 읽는다(§1.2·§1.3·§6·§8·§12·§13·§14 에 이후 표기를 병기). 현재 구현 상태의 single-home 은 `docs/systems/review/STATUS.md`·`docs/systems/review/BACKLOG.md`(둘 다 RV-B-06)이며 본 banner 가 그것과 정합한다. 구현/리뷰 출처: P2 `review-result-provenance-p2-2026-06-03`(pass-01..04, yes); P3 코드 `scripts/review-run.ps1`(`Add-ReviewerProvenanceBlock`) + `tests/review-run.Tests.ps1`(AC-RR27/28) + contract/template/STATUS/BACKLOG, review `review-result-provenance-p3-2026-06-03`; P4 docs(SKILL / README / OPERATOR_GUIDE_KR / CHATLOG_CONTRACT / STATUS / BACKLOG) review `review-result-provenance-p4-2026-06-03`(§5a.7 global stable engine).

## Document character

본 문서는 review subsystem 의 **새 deferred scoped track** — review **result 아티팩트(result.md)** 만 보고도 *"어떤 reviewer adapter 종류 / reviewer version / model / effort 로 실제 실행됐는가"* 를 판단할 수 있게 하는 **reviewer runtime provenance 기록 기능**의 planning/design spec 이다. 이 기능은 Batch D 의 run-fact emission / final-report surfacing 위에 얹히지만 **Batch D 의 일부가 아니며 Batch D 를 재오픈하지 않는다** (Batch D mainline 은 `docs/systems/review/STATUS.md` line 39 "Batch D mainline complete" 로 닫혀 있고 spec §4 가 "no D4" 를 명시).

- **성격**: 본 문서 = 조사(현 구현 read-only inspection) + design spec. **이 design 문서 자체는 source/script/test/config/contract/template/verifier/skill 변경을 동반하지 않는다** — 구현은 별도 scoped `/goal` + review gate + 사용자 commit/push 승인을 거치는 별도 batch 이며 본 spec 을 입력으로 삼는다. *(그 중 **P2·P3·P4 가 모두 구현됐다** — 상단 Implementation status; RV-B-06 트랙 전부.)*
- **이것이 아닌 것**: implementation 아님 / operational claim 아님 / 승인 문서 아님. 본 문서의 어떤 조사 결과도 source 변경을 수행하거나 승인하지 않는다. "필요해 보임" 은 구현 확정이 아니라 spec 후보다.
- **정직성 분리**: 아래 모든 사실은 **현재 관측/emit 함 / 현재 관측/emit 하지 않음 / inferred(미확정)** 로 분리 표기한다. "현재 runner 가 stdout 으로 emit 하는 run-fact" 와 "현재 어디에도 persist 되지 않는 사실" 과 "현재 아예 관측조차 되지 않는 사실" 은 서로 다른 층이다 — 섞지 않는다.
- **source of truth**: 본 spec 의 상위 권위는 `docs/contracts/review/REVIEW_RESULT_CONTRACT.md`(artifact 계약, §3 result.md authorship / §4 script responsibility / §6b final report schema / §10 non-goals), `docs/systems/review/REVIEW_POLISHING_BATCH_D_SPEC.md`(세 home 분류 §2, run-fact 현황 §1), `docs/policies/REVIEWER_CONFIG_POLICY.md`(reviewer-safe / model resolution), `docs/policies/DOCS_OPERATING_MODEL.md`(docs 변경/배치). 충돌 시 contract 가 이긴다.
- **maintenance-mode 위치 (중요)**: review subsystem 은 maintenance mode 다 (STATUS line 7: "No new feature ... without a separate scoped approval. Bug fix and contract clarification are in-scope"). reviewer version 의 신규 관측 + result.md authorship 모델 확장은 단순 bug fix 보다 **새 기능(feature)에 가깝다** — 따라서 본 planning/design 자체가 사용자의 *별도 scoped 승인*(설계+리뷰 한정)이며, 구현 진입은 각 단계마다 별도 명시 승인이 필요하다 (§7 approval boundary).

### Document character — vendor / adapter / version neutrality 원칙 (binding)

repo 규칙상 durable docs / scripts / templates 는 **특정 AI vendor / tool / model / version 에 결합되지 않아야 한다** (예: contract §4a 의 "특정 model version 은 external lifecycle 에 종속되므로 코드/문서에 하드코딩하지 않는다 / built-in default·fallback 없음", STATUS 의 model-fallback-removal corrective, `docs/policies/REVIEWER_CONFIG_POLICY.md`). 본 spec 은 그 규칙을 따르며, 다음을 invariant 로 둔다:

- **provenance 설계는 adapter-neutral** 이다. provenance field schema / 기록 위치 / 관측 일반론은 어떤 특정 reviewer tool 도 전제하지 않는다 — *active reviewer adapter* 가 무엇이든 그 adapter 의 runtime 으로부터 값을 얻는다.
- 필요한 runtime 값의 **source 는 넷 중 하나**다: **(a) config**(예: `config/reviewer.json` 의 model/effort), **(b) active reviewer adapter / runtime**(adapter 가 보고하는 kind·version·posture), **(c) runtime observation**(runner 가 resolver branch·전달 flag 등에서 직접 관측), **(d) reviewer self-report**(reviewer 프로세스가 자기 실행에 대해 보고하는 값, 예: applied-effort). caller 가 input.md 에 적는 *선언값* 은 provenance source 가 아니다(§4).
- **concrete vendor / tool / version 이름**(예: 특정 CLI 이름, `codex-cli 0.132.0`, vendor-specific subcommand/flag)은 **(i) 현재 MVP adapter 의 inspection 사실** 또는 **(ii) 동기 사건(historical incident) 설명** 으로만 등장한다. durable schema / implementation rule / template requirement / script default 처럼 읽히면 안 된다.
- **현재 사실 (inspection)**: 현 구현의 **유일한 MVP reviewer adapter 는 codex** 다(`scripts/review-run.ps1` 의 `-Reviewer` 가 `codex` 외를 거부, 라인 7/294). 본 spec 이 코드 inspection 을 기술할 때 codex 를 명명하는 것은 *현재 adapter 의 사실* 을 적는 것이지 codex 를 영구 전제로 삼는 것이 아니다. 새 adapter 가 추가되면 관측 메커니즘은 그 adapter 별로 re-derive 된다(contract 의 "reviewer-tool-specific: re-derive if the reviewer tool changes" 와 정합).

## 0. 조사 환경 (provenance)

- repo HEAD `0128de1`("Mark Batch D mainline complete in review status"), branch `main`, working tree clean. 조사 환경의 active reviewer adapter = codex(현재 유일 MVP adapter), 관측된 adapter version 문자열 = `codex-cli 0.132.0`(adapter 의 version-reporting 으로 1회 read-only 확인), Windows 11. (이 concrete 값은 조사 환경 record 이지 durable rule 이 아니다.)
- 조사 방식: repo 파일 read-only inspection — `scripts/review-run.ps1`(success-path Write-Host 라인 + 실행 wrapper 의 stderr 캡처 경로 enumeration), `scripts/review-verify.ps1`/`scripts/review-input-verify.ps1`(parser surface), `tests/review-run.Tests.ps1`(현 AC 범위), `docs/contracts/review/REVIEW_RESULT_CONTRACT.md`(§3/§4/§6b/§10), `templates/review-result.md`, `docs/systems/review/REVIEW_POLISHING_BATCH_D_SPEC.md`(§1/§2), `docs/policies/REVIEWER_CONFIG_POLICY.md`.
- 본 spec 작성 자체는 구현/검증을 수행하지 않는다 — review-run 을 새로 실행하지 않았고, run-fact 출력이나 result.md authorship 을 변경하지 않았다. active adapter 의 version-reporting 을 1회 실행해 version 문자열의 관측 가능성만 확인했다(read-only).

## 1. 문제 정의 (required content #1)

### 1.1 동기 사건 (historical incident)

최근 현재 adapter(codex) CLI 의 한 version(v0.134.0)에서 Windows sandbox spawn 회귀가 있었고, 직전 version(v0.132.0)으로의 다운그레이드로 운영상 해소됐다(`docs/systems/review/STATUS.md` Accepted residual risks / Brief 참조). 그 상황 판단의 핵심은 *"이 review 가 실제로 어떤 reviewer version / model / effort 로 실행됐는가"* 였다 — 회귀가 의심되는 review 결과를 사후에 검토할 때, 그 결과를 **만든 실행의 정체**를 알아야 신뢰성을 판단할 수 있다. reviewer tool 은 auto-update 로 version 이 바뀔 수 있으므로, 호출자가 사전에 적은 선언값은 실제 실행을 보장하지 못한다. (위 concrete version 들은 동기 사건의 historical 설명이며 본 spec 의 어떤 규칙도 그 version 에 결합되지 않는다 — §2 N2.)

### 1.2 현재 구현의 gap (verified, inspection)

canonical review record 는 `input.md`(operator-authored) + `result.md`(reviewer-adapter-authored; 현재 adapter = codex) 두 파일이다(contract §1/§3). 실행 provenance 가 이 두 파일 어디에도 남지 않는다:

- **PV-V1 (run-fact 는 stdout 휘발)**: `scripts/review-run.ps1` success-path 는 model / model-source / requested-effort / effort-source / applied-effort / reviewer-safe-posture / tool-root / project-root / tool-root-source 를 **`Write-Host` 로 stdout 에만 emit** 한다(라인 401–425, Batch D2). 이 값들은 **canonical artifact 어디에도 persist 되지 않는다** — console 출력이라 세션 종료/스크롤아웃과 함께 사라지며, `log/review/<id>/pass-NN/` 의 두 파일을 사후에 열어도 보이지 않는다.
- **PV-V2 (result.md body 는 reviewer-adapter 가 작성 — *P3 전 baseline은 "runner 가 안 씀"*)**: `result.md` 의 verdict/disclosure **body** 는 active reviewer adapter 가 자기 result-output mechanism(현재 codex adapter 의 경우 `--output-last-message $ResultMdPath`)으로 쓴다(라인 95). P3 전에는 runner 가 verdict 파싱 read-back 만 하고(`Get-VerdictFromResultMd`) result.md 에 쓰지 않아 실행 provenance 가 전혀 없었다. *(**P3 이후**: runner 가 reviewer body 는 그대로 두고 끝에 `## Reviewer run provenance` 블록을 append 한다 — result.md 는 dual-authored 가 됐다; reviewer body 는 여전히 adapter 가 작성, provenance 블록은 runner 가 machine-emit. 상단 Implementation status / contract §3.)*
- **PV-NV1 (reviewer kind 미surface — *P2 전 baseline*)**: `-Reviewer` 파라미터는 현재 `codex` 만 허용하고 그 외는 fail 한다(라인 7, 294) — 즉 active adapter kind 는 runner 가 알지만 **run-fact 라인으로 emit 되지 않고**(`reviewer:` 라인 없음) artifact 에도 없다. *(**P2 이후 해소**: active adapter kind 를 `reviewer:` H1 run-fact 로 emit — 상단 Implementation status.)*
- **PV-NV2 (reviewer version 아예 미관측 — *P2 전 baseline*)**: runner 는 **active adapter 의 version 을 어디서도 관측하지 않는다.** adapter 의 version-reporting mechanism 을 호출하는 코드가 없고(현재 codex adapter 의 경우 `codex --version` 류 호출 부재), 실행 wrapper 의 stderr 캡처는 오직 `reasoning effort:\s*(...)` 만 추출한다(라인 179). 동기 사건의 가장 중요한 datum 인 reviewer version 이 이 구조에 전혀 들어오지 않는다 — 이것이 **신규 관측이 필요한 유일한 datum** 이다. *(**P2 이후 해소(stdout 한정)**: active adapter 의 run banner 에서 version 을 관측해 `reviewer-version:` H1 run-fact 로 emit; 미관측 시 `not-observed`. result.md persist 는 여전히 P3 — 상단 Implementation status.)*

### 1.3 결과 (*P3 전 baseline*)

P3 전에는 `result.md`(또는 review result artifact) **단독**으로 그 결과를 만든 실행의 reviewer kind / version / model / effort / safety posture 를 판단할 수 없었다 — 동기 사건 같은 사후 신뢰성 판단이 불가능했다. *(**P3 이후 해소**: runner 가 result.md 에 `## Reviewer run provenance` 블록을 persist 하므로 result.md 단독으로 그 실행 provenance 를 판단할 수 있다 — G1 달성. 상단 Implementation status.)*

## 2. 목표와 non-goals (required content #2)

### 2.1 목표 (goal)

- **G1**: `result.md`(또는 result artifact) **단독**으로 실제 실행 provenance(reviewer adapter kind / version / model / requested+applied effort / reviewer-safe posture)를 판단 가능하게 한다.
- **G2**: provenance 값은 호출자가 input.md 에 적는 **선언값이 아니라**, **config / active reviewer adapter / runtime observation / reviewer self-report** 에서 얻은 값이어야 한다 (§6 source 구분 참조).
- **G3**: (P2 전) 미관측이던 datum(reviewer kind/version)을 active adapter 의 runtime 으로부터 관측하고(**P2 가 이를 H1 stdout 으로 달성**), 그 값과 이미 stdout 으로만 emit 되는 Batch D run-fact 를 canonical record 에 **persist**(**P3 — 미구현**) 한다 — 즉 휘발성 H1 stdout 의 신뢰 subset 을 canonical record 에 남긴다.
- **G4**: 위를 **canonical 2-file contract 를 깨지 않고**(sidecar 금지 §10), **기존 parser surface(`## Verdict` + 4 H2)를 깨지 않고**, **Batch D 의 stdout emission 을 제거하지 않고**, **특정 vendor/tool/version 에 결합하지 않고**(neutrality 원칙) 달성한다.

### 2.2 non-goals (이번 scope 가 다루지 않는 것 — required content #12)

사용자 명시 non-goals:

- **N1**: `input.md` 에 reviewer version / provenance 를 기록하지 **않는다** (input.md 은 caller declaration 자리이며 runtime observation 자리가 아니다 — §4).
- **N2**: 특정 reviewer-tool / vendor version pin 정책을 도입하지 **않는다** (version 은 외부/사용자 환경 관리 사안; 본 track 은 *관측·기록* 만 다루고 *강제·고정* 은 다루지 않는다). 어떤 concrete version 도 durable rule 로 박지 않는다.
- **N3**: Batch D 를 재오픈하지 **않는다** (Batch D mainline complete; "no D4"). 본 track 은 Batch D 산출물 위에 얹히는 별도 track 이다.
- **N4**: 다음을 본 scope 에 **섞지 않는다** — `## Known concerns` framing-tilt convention, operator stance fold-in, `.md` EOL normalization, design/analysis review mode, full-suite-green closeout policy. (각각 STATUS line 39 / Brief 의 별도 deferred 후보이며 본 track 과 독립.)

convention 파생 non-goals (contract §10 / decision record invariant 7 / neutrality 원칙 정합):

- **N5**: 새 **sidecar 파일**(provenance.json / .md, hash binding, freshness sidecar, machine-readable verdict 사본)을 만들지 **않는다** (contract §1/§4/§10). provenance 는 canonical artifact *안*에 들어가야 한다.
- **N6**: parser/gate 를 **확대하지 않는다** — `review-verify.ps1 -RequireResult` 의 4-H2 disclosure gate, `review-input-verify.ps1` 의 5-H2 gate 를 변경하지 않는다. provenance 의 존재를 deterministic 강제 대상으로 만들지 않는다(user-decision 1). 단, provenance 블록이 기존 gate 를 **깨지 않음**은 검증 대상이다(§9).
- **N7**: **concrete model version / vendor / tool 이름을 durable schema·rule·default 로 박지 않는다** — model 은 `config/reviewer.json` source-of-truth 에서 runtime resolve 하고, provenance 는 그 runtime resolve 값을 *기록*하는 것이지 doc 본문/스크립트 default 에 version·vendor 를 박는 것과 다르다. version-observation 메커니즘도 특정 vendor command(예: 특정 CLI 의 `--version`)를 일반 설계 규칙으로 두지 않고 "active adapter 의 version-reporting(지원 시)" 으로 일반화한다.
- **N8**: multi-reviewer orchestration / reviewer adapter *확장* 을 하지 않는다 (maintenance-mode exclude). reviewer kind field 는 현재 MVP adapter 가 codex 단일이라는 사실을 *기록*만 하며, 새 adapter 를 도입하지 않는다.

## 3. 기존 Batch D run-fact emission / final-report surfacing 과의 관계 (required content #3)

Batch D 는 **세 home 모델**(`REVIEW_POLISHING_BATCH_D_SPEC.md` §2)을 도입했다:

- **H1 — runner stdout run-fact**: 단일 invocation 이 deterministic 관측 가능한 사실. Batch D2 가 model/effort/posture/engine 을 emit.
- **H2 — operator final human report**: operator 가 사용자에게 내는 closeout 보고(contract §6b). Batch D3 가 reviewer-guard-status field 로 H1 run-fact 를 surface.
- **H3 — docs-only guidance**: contract/policy/skill wording.

본 track 의 관계:

- **재사용**: provenance 의 model / requested+applied effort / reviewer-safe posture / engine identity 값은 **Batch D2 가 이미 관측하는 run-fact 와 동일 datum** 이다. 본 track 은 이 값들을 *새로 계산*하지 않고 그 관측을 *persist* 한다.
- **신규**: reviewer kind / reviewer version 은 Batch D 가 다루지 않은(PV-NV1/NV2) **신규 관측** 이다.
- **새 home 의 명료화**: Batch D 의 H1 은 **휘발성(console)** 이고 H2 는 **operator-authored prose(artifact 아님)** 다. 본 track 은 H1 run-fact 의 신뢰 subset 을 **canonical result 아티팩트에 persist** 하는 것 — 즉 "result artifact 가 스스로를 설명(self-describing)하게" 한다. 이를 세 home 모델에 대한 **확장(H1-persisted / artifact-resident provenance)** 으로 본다. H2(operator 집계·판단)와 혼동하지 않는다: persist 되는 것은 runner 의 단일-pass 관측이며 operator 의 집계가 아니다.
- **충돌 없음 (verified, design)**: Batch D 의 stdout emission(라인 401–425)은 그대로 유지된다. 본 track 은 그 위에 persist 를 *추가* 할 뿐 emission 을 제거하지 않는다(G4). reviewer-guard-status final-report field(§6b.2)는 이제 휘발성 stdout 대신(또는 그와 더불어) **persist 된 artifact provenance** 를 인용할 수 있어 H2 surfacing 의 근거가 더 견고해진다 — 이는 §6b 의 강화이지 재정의가 아니다.

## 4. `input.md` 가 아니라 `result.md`/result artifact 에 기록해야 하는 이유 (required content #4)

contract 는 두 파일의 책임을 명확히 분리한다(§2, §3, §5):

- **`input.md` = caller declaration**: operator-role AI 가 *호출 전에* 작성하는 입력(§2, §5). 호출자의 **의도·선언**이다.
- **`result.md` = 실행 산출물**: active reviewer adapter 가 *호출 후에* 만드는 결과(§3). 실행의 **사실**에 가까운 자리다.

provenance 를 input.md 에 두면 안 되는 이유:

- **R1 — runtime observation ≠ caller declaration**: reviewer version / applied effort 는 **호출자가 사전에 알 수 없다.** reviewer tool 의 auto-update 로 version 이 바뀌고(동기 사건), applied effort 는 reviewer 프로세스의 self-report 에서만 관측된다. caller 가 input.md 에 "특정 version 으로 실행" 이라 적어도 그것은 *주장*이지 *관측*이 아니며, 실제 실행과 어긋날 수 있다(stale-by-declaration).
- **R2 — provenance 는 "이 결과를 만든 실행"의 속성**: provenance 가 답하려는 질문은 "이 **result** 를 만든 실행은 무엇인가" 다. 그 답은 논리적으로 result 와 함께 있어야 한다. input.md 은 그 result 가 생기기 전의 입력이라 자리상 맞지 않는다.
- **R3 — 사후 단독 판단 가능성(G1)**: 목표는 result artifact *단독* 으로 판단하는 것이다. provenance 가 input.md 에 있으면 result 를 볼 때 input 도 교차 참조해야 하고, 게다가 input 의 값은 선언이라 신뢰도가 낮다.
- **R4 — write-once / authorship 정합**: input.md 은 operator-authored, result.md 은 실행 산출물이다. runtime-observed provenance 는 실행이 만든 사실이므로 result 측 자리가 authorship 모델과 정합한다(단 §5 의 authorship 확장 필요 — runner-written 블록).

> 결론: provenance 는 **result.md(또는 result artifact)에 runtime-observed 사실로 기록**한다. input.md 에는 기록하지 않는다(N1). 이 책임 분리는 본 corrective 후에도 유지된다.

## 5. 기록 위치 설계 — result.md authorship 모델의 긴장과 옵션

이 track 의 핵심 설계 난점은 **result.md 가 현재 active reviewer adapter 에 의해서만 작성된다(§3, 현재 adapter = codex)** 는 점인데, **runtime provenance 는 runner 만 관측 가능**하다는 것이다. 동시에 **sidecar 는 금지(§10/N5)** 다. 가능한 옵션:

| opt | 위치 | 장점 | 단점 / 계약 충돌 |
|---|---|---|---|
| A | **runner 가 result.md 에 provenance 블록을 append**(adapter 가 쓴 본문 + runner-written 블록) | sidecar 없음(§10 준수); result 단독 self-describing(G1); 2-file contract 유지 | §3 "result.md 는 reviewer-adapter-authored" 를 **dual-authored 로 확장** 필요; parser(§3 `## Verdict`+4 H2)와 heading 충돌 회피 필요; write-once/ordering 정의 필요 |
| B | runner 가 result.md **선두에 provenance 블록을 prepend** | A 와 동일 | A 와 동일 + verdict 가 첫 heading 이라는 reader 기대 깨질 수 있음 |
| C | input.md 에 기록 | 구현 단순 | **N1/R1–R4 로 기각** (caller declaration ≠ runtime observation) |
| D | 별도 sidecar(provenance.json/md) | runner 가 자유롭게 작성 | **N5/§10 으로 기각** (sidecar 금지) |

**권고(inferred, implementation batch 가 확정)**: **Option A** — runner 가 adapter 산출(adapter 의 result-output mechanism) + verdict 파싱 성공 후, result.md 끝에 명확히 **runner-authored 로 표시된 provenance 블록**(권고 heading: `## Reviewer run provenance` — adapter-neutral 명칭)을 append. 제약:

- provenance 블록은 `## Verdict` 또는 4 required disclosure H2(`## Blocking findings` / `## Non-blocking concerns` / `## Review limitations` / `## Assumptions relied on`)와 **heading 이 충돌하지 않아야** 한다(parser 는 정확 count 검사 — N6). `## Reviewer run provenance` 는 그 집합과 분리된다.
- 블록은 **runner-written, machine-emitted** 임을 본문에 명시(active reviewer adapter 가 쓴 것이 아님). reviewer/operator 가 손으로 작성하지 않는다.
- adapter 산출 실패 시 provenance 블록도 없다(부분 상태 정의 필요 — §11 open question).
- contract §3 을 "result.md = reviewer-adapter-authored verdict body + (optional) runner-appended runtime provenance block" 로 amend. §4 의 "script 가 본문을 provenance 파일로 분산 금지" 와의 구분 명문화: 이것은 *별도 sidecar 파일로의 분산이 아니라*, *canonical result.md 안의 machine run-fact 블록* 이며 semantic judgment 가 아니다.

## 6. 기록 후보 field 목록 + source 구분 (required content #5, #6)

각 field 의 **source 가 config / active reviewer adapter / runtime observation / reviewer self-report 중 무엇인지**(caller declaration 이 아님 — G2), 그리고 **현재 관측/persist 상태**를 분리한다. **모든 field 는 adapter-neutral 하게 정의**되며, "값 예" 의 concrete 문자열은 *현재 codex adapter 가 내는 예시* 일 뿐 durable schema 가 아니다.

| # | field | 값 예 (현재 adapter, 예시일 뿐) | source | 현재 상태 (verified) |
|---|---|---|---|---|
| F1 | reviewer adapter kind/type | `codex` | **active reviewer adapter** identity (어떤 adapter 가 실제 실행됐는지의 runtime observation) | **P2 이후 stdout emit**(`reviewer:`)·**미persist** (P2; 이전 PV-NV1 = 미emit) |
| F2 | reviewer version | (adapter 가 보고하는 version 문자열) | **active reviewer adapter / runtime observation** — adapter 가 version-reporting 을 **support 할 때** runtime-resolved observation 으로 기록; 미지원이면 `unknown`/`not-observed` | **P2 이후 stdout 관측·emit**(`reviewer-version:`; support 시, 아니면 `not-observed`)·**미persist** (P2; 이전 PV-NV2 = 아예 미관측) |
| F3 | model | (config 의 resolve 값) | **config**(`config/reviewer.json` model; 또는 explicit override) + **runtime observation**(resolver 결과) | stdout emit(D2)·**미persist** (PV-V1) |
| F4 | model-source | `explicit` / `config` | **runtime observation** (실제 resolver branch) | stdout emit(D2)·미persist |
| F5 | requested effort | `xhigh` 등 | **config / runtime observation** — 값은 config(또는 explicit) 에서 오고, *어느 source 로 어떻게 해소됐는지* 는 runner 가 관측 | stdout emit(D2)·미persist |
| F6 | effort-source | `explicit` / `config` / `default` | **runtime observation** (resolver branch) | stdout emit(D2)·미persist |
| F7 | applied effort | (adapter 가 보고하는 값) / `not-observed` | **reviewer self-report** — reviewer 프로세스가 자기 실행에 적용한 effort 를 보고할 때 캡처(미보고/in-process stub 은 not-observed) | stdout emit(D2)·미persist |
| F8 | reviewer-safe posture | (현재 adapter 가 적용한 posture flags) | **runtime observation** (runner 가 active adapter 에 실제 전달한 posture flag 집합에서 derive) | stdout emit(D2)·미persist; **tested-vectors-only caveat 유지(N7 인접)** |
| F9 | review engine identity (선택) | tool-root / project-root / tool-root-source | **runtime observation** (해소된 roots) | stdout emit(D2)·미persist; self-modification closeout 에서 §5a.7 와 짝 |

> **P3 이후 (위 "현재 상태" 열은 P2 시점 기록).** P3 가 "미persist" 상태를 해소했다 — **F1–F8 + engine identity(F9)가 모두 `## Reviewer run provenance` 블록으로 result.md 에 persist** 된다. 즉 OQ5(F9 persist 범위)는 **engine identity 포함**으로 결정됐다(run 식별 완전성 + §5a.7 self-modification provenance). version 미관측 시 `not-observed`. 상단 Implementation status / §5 Option A.

source 구분 요약 (모두 caller declaration 아님 — G2):

- **F1/F2 는 active reviewer adapter 로부터** 온다 — F1 은 어떤 adapter 가 실제 돌았는지, F2 는 그 adapter 가 보고하는 version(지원 시). 특히 F2(version)·F7(applied effort)는 caller 가 원천적으로 사전에 알 수 없는 값이라 input.md 자리가 불가능함을 가장 강하게 보여준다(R1).
- **F3/F5 는 config 가 1차 source** 이고 그 적용 사실을 runtime 관측한다. **F4/F6 는 순수 runtime observation**(resolver branch). **F7 은 reviewer self-report**. **F8/F9 는 runtime observation**(runner 가 실제 전달/해소한 값).
- **F5 requested effort 의 미묘함**: 값 자체는 config(또는 explicit `-Effort`) 입력에서 온다. 그러나 provenance 가 기록하는 것은 *"이번 실행에서 어느 source 로 어떤 값이 적용됐는지"* 의 관측(F5+F6)이지, caller 의 input.md 선언 사본이 아니다.
- **F9 engine identity** 는 self-modification 외 일반 review 에선 부수적이다. persist 대상에 포함할지 over-scope 여부는 §11 open question.

> **최소 핵심 집합(권고)**: F1(adapter kind) + F2(version) + F3/F4(model+source) + F5/F6/F7(effort 3종) + F8(safe posture). F9 는 optional. 이 집합이 동기 사건("어떤 reviewer/version/model/effort 로 실행됐나")을 result 단독으로 답한다. 모든 field 는 adapter 가 바뀌어도 동일 schema 로 유효하며, 값 source 만 그 adapter 의 runtime 으로 re-derive 된다.

## 7. contract / template / verifier / tests / skill / docs 영향 예상 (required content #7)

각 surface 의 예상 영향. **본 spec 은 아래 어느 것도 변경하지 않는다 — 영향 예측일 뿐이다.**

- **contract (`docs/contracts/review/REVIEW_RESULT_CONTRACT.md`)**:
  - §3 result.md authorship — "reviewer-adapter-authored" → "reviewer-adapter-authored verdict body + runner-appended runtime provenance block(optional, machine-emitted)" 로 확장. provenance 블록이 `## Verdict`/4 H2 와 충돌하지 않음을 명문화. (vendor-neutral wording 유지 — 특정 tool 명 박지 않음.)
  - §4 script responsibility — runner 가 result.md 에 provenance 블록을 쓰는 것은 "본문을 sidecar provenance 파일로 분산"(§4 금지)과 다름을 구분 명문화 (canonical 파일 안의 machine run-fact, semantic judgment 아님).
  - §10 non-goals — provenance 블록이 sidecar/hash-binding/machine-verdict-사본이 아님을 명확화(N5 와 정합).
  - §6b.2 reviewer-guard-status — 인용 근거를 휘발성 stdout 에서 persist 된 artifact provenance 로 강화(재정의 아님).
- **template (`templates/review-result.md`)**: runner-appended provenance 블록의 존재·위치·"runner-written(손으로 작성 안 함)" 를 reviewer/operator 안내로 추가. reviewer 가 그 블록을 직접 쓰지 않음을 명시. (template 도 vendor-neutral 유지.)
- **verifier (`scripts/review-verify.ps1` / `review-input-verify.ps1`)**: **gate 미확대(N6)**. 단 provenance 블록이 있는 result.md 에서도 기존 `## Verdict`(1회)+4 H2(각 1회) count 가 그대로 PASS 함을 보장(회귀 검증 대상). 새 required heading 추가 금지.
- **runner (`scripts/review-run.ps1`)**: (a) active adapter kind 표면화 + version 신규 관측(F1/F2; adapter version-reporting 추상화 — §11 OQ1); (b) adapter 산출 후 result.md 에 provenance 블록 append(§5 Option A); (c) 대칭적으로 `reviewer:` / `reviewer-version:` stdout run-fact 도 추가(H1 일관성). adapter 별 관측 메커니즘은 adapter 추상화 뒤에 둔다(현재 codex 단일이라도 vendor-specific call 을 일반 경로 default 로 하드코딩하지 않는다).
- **tests (`tests/review-run.Tests.ps1`)**: adapter-kind/version 관측 AC, provenance 블록이 result.md 에 기록되는 AC, **provenance 블록 존재 시 verdict/4-H2 parser 통과 회귀 AC**, version-not-observed fallback AC. 기존 AC 유지.
- **skill (`snippets/claude-skills/ai-harness-review/SKILL.md`)**: step 6/7 — operator 가 provenance 를 휘발성 stdout 이 아니라 **persist 된 result.md** 에서 읽어 reviewer-guard-status 를 보고. self-contained deployed surface 유지(repo-doc `§N` pointer 재도입 금지).
- **docs**: STATUS.md ledger(완료 시), REVIEWER_CONFIG_POLICY.md(reviewer version observability 한 줄, vendor-neutral), 본 spec ↔ Batch D spec 관계 pointer.

## 8. 구현 단계 분할안 (required content #8)

> 아래는 **권고 분할**이다. 본 문서는 구현하지 않으며, 각 단계는 별도 scoped `/goal` + review gate + 사용자 commit/push 승인이 필요하다. 순서·묶음은 권고이며 확정 지시가 아니다. review tooling self-modification 이므로 각 단계 closeout review 는 §5a.7 대로 **global stable ToolRoot engine** 으로 수행한다.

- **P1 — 본 planning/design spec + review gate (현재 단계)**. source 변경 없음.
- **P2 — adapter kind/version runtime 관측 + H1 run-fact (source, 최소) — ✅ 구현됨(상단 Implementation status)**: `review-run.ps1` 에 active adapter kind 표면화(F1)와 version 신규 관측(F2; adapter 의 version-reporting 추상화를 통해 — §11 OQ1)을 추가하고 `reviewer:` / `reviewer-version:` 를 stdout 으로 emit + Pester AC. **이 단계는 stdout 만 건드리고 result.md authorship 은 바꾸지 않는다** — 가장 작은 additive 변경. contract 변경 없음(또는 run-fact 목록 mirror 한 줄). vendor-specific version call 은 adapter 추상화 뒤에 둔다. *구현 결과: version 관측은 codex adapter 의 run-banner stderr 파싱을 adapter-isolated reader 뒤에 둔 형태로 실현됐고(별도 vendor `--version` 프로세스 미사용), `tests/review-run.Tests.ps1` AC-RR25(관측)·AC-RR26(not-observed fallback)로 커버됐다.*
- **P3 — result.md provenance 블록 persist (source + contract, artifact 변경) — ✅ 구현됨(상단 Implementation status)**: §5 Option A 구현 — runner 가 adapter 산출(verdict shape usable 확인) 후 result.md 에 `## Reviewer run provenance` 블록(F1–F8 **+ engine identity F9**)을 append. contract §3(dual-authorship)/§4(in-file 블록 ≠ sidecar 파일) amend + template(runner-appended, reviewer 미작성) + tests(`review-verify -RequireResult` 회귀 호환). *구현 결과: `Add-ReviewerProvenanceBlock`(machine-emit, reviewer body 보존 후 append) + `provenance-persisted:` stdout 보고 + AC-RR27(블록 persist + verify 호환, controlled 값)·AC-RR28(not-observed persist). 블록 heading·key:value 가 `## Verdict`+4 H2 와 미충돌이라 parser gate 미확대. reviewer 산출 실패 시 미발명, valid verdict 후 append 실패는 verdict 미무효화·loud 보고(OQ3 결정).*
- **P4 — operator surfacing / mirror 정합 (skill + docs) — ✅ 구현됨(상단 Implementation status)**: SKILL step 6 가 persist 된 `## Reviewer run provenance` 블록을 읽도록, step 7 reviewer-guard-status 가 그 값(kind/version/model/effort/safe-posture/engine identity)을 surface 하도록 정합(persisted 블록 또는 step-5 stdout 출처; informational, not parser-gated; verdict ≠ commit/push). README/OPERATOR_GUIDE_KR/CHATLOG_CONTRACT 의 single-author mirror 라벨 → dual-authored 정합(CHATLOG 은 mirror 문구만). *parser/gate·runner·tests·result-block shape 변경 없음(docs-only). reviewer-safe tested-vectors-only caveat·neutrality 유지.*

**권고 순서**: P2(관측) → P3(persist) → P4(surface). P3 는 P2 의 관측값 + contract amend 에 의존한다. P2 단독으로도 부분 가치(stdout 에 version 노출)가 있으나 G1(artifact 단독 판단)은 P3 까지 가야 충족된다.

## 9. validation strategy (required content #9)

- **Pester (runner)**: F1/F2 관측 AC; provenance 블록이 result.md 에 정확한 field 로 기록되는 AC; **provenance 블록 존재 result.md 에서 `## Verdict`(1)+4 H2(각1) parser PASS 회귀 AC**(N6 핵심); version-not-observed 시 `not-observed`/`unknown` fallback AC(silent success 금지); 기존 24 AC 유지.
- **verify-ps1**: provenance 블록을 가진 result.md 에 `review-verify.ps1 -RequireResult` PASS 확인(gate 미확대 증명).
- **manual smoke (real reviewer adapter; 현재 codex)**: 실제 adapter 로 1 pass 실행해 version 문자열 파싱과 provenance 블록 append 를 확인(in-dev runner 는 feature smoke 용으로만, closeout engine 으로는 §5a.7 에 따라 global stable 사용).
- **negative**: version 관측 실패 경로(adapter 미지원 포함), adapter 산출 실패 시 부분상태(provenance 미append) 경로.
- **honesty**: 검증된 것/미검증/inferred 분리 보고; reviewer-safe 는 tested-vectors-only caveat 유지(F8).
- **evidence**: validation execution claim 이 있는 review round 는 `## Validation evidence` 로 Markdown evidence(§3a) 참조.

## 10. activation 필요 가능성 판단 기준 (required content #10)

- **판단**: activation(global stable install payload `%USERPROFILE%\.claude\ai-harness-toolset\current` refresh) 이 **필요할 가능성이 높다.** 변경 surface(runner `review-run.ps1` / contract / template / SKILL)가 모두 **deployed reviewer surface(channel 3 payload)** 이기 때문이다 — Batch D 가 "committed, pushed, globally activated" 로 닫힌 것과 동일 패턴(STATUS line 39).
- **기준**: activation 은 (1) 해당 구현 단계(P2/P3/P4)가 완료·리뷰(global stable engine)·커밋되고, (2) 사용자가 **명시적으로 activation 을 승인**한 후에만 수행한다. **본 planning 단계(P1)는 activation 을 수행하지 않으며 판단만 제시한다.**
- self-modification 이라 §5a.7: in-dev runner 를 closeout engine 으로 쓰지 않고 global stable engine 으로 리뷰. activation 으로 deployed surface 가 바뀌면 그 이후 review 의 engine identity(F9)도 새 payload 를 가리킨다.

## 11. open questions / risks (required content #11)

> **P2/P3 구현으로 결정/해소된 항목 (아래는 설계시점 기록).** OQ1(version 관측 방법) = P2 가 adapter run-banner stderr 파싱(adapter-isolated reader)으로 결정. OQ2(dual-authorship 정당성) = contract §3 dual-authorship + machine-run-fact 한정으로 해소. OQ3(append 실패 거동) = verdict 미무효화 + loud 보고로 결정. OQ4(parser 충돌) = fixed heading + key:value 로 회피(verify 통과 확인). OQ5(F9 engine identity persist 범위) = **포함**으로 결정(§6 P3 note). 결정 결과의 single-home 은 상단 Implementation status·§6 P3 note·§8 P3·STATUS/BACKLOG 다. OQ6(maintenance-mode 경계)·OQ7(staleness)은 정책/규율 항목으로 유지.

- **OQ1 — version 관측 방법(adapter-neutral 추상화)**: active adapter 가 version 을 보고하는 mechanism 은 adapter 마다 다르다(전용 version query vs 실행 출력 헤더 파싱 vs 미지원). 설계는 이를 **adapter 추상화** 뒤에 두고, 특정 vendor command 를 일반 default 로 하드코딩하지 않는다(N7). 현재 codex adapter 는 전용 version query 와 실행 헤더 양쪽이 후보지만, 헤더 포맷은 version 간 불안정(동기 사건이 보여준 version-fragility 가 파싱에도 적용). **risk**: adapter 추상화 없이 한 vendor call 을 일반 경로에 박으면 neutrality 위반 + 새 adapter 시 재작업.
- **OQ2 — result.md dual-authorship 의 정당성**: runner 가 adapter 산출 파일에 append 하는 것이 §3 "result.md 는 reviewer-adapter 가 작성" 정신을 침해하는가? **mitigation**: 명확히 runner-authored 로 demarcate + contract amend + machine run-fact(semantic judgment 아님)로 한정. 그래도 reviewer 가 자기 산출 뒤에 무언가 붙는다는 모델 변화는 신중히 리뷰 대상.
- **OQ3 — write-once / 부분상태**: adapter 산출 실패 시 provenance 없음. provenance append 실패가 verdict PASS 를 무효화해야 하는가? **권고(inferred)**: provenance 는 보조 기록이므로 append 실패가 verdict 판정을 깨지 않되 명시 경고. 단 정의 필요.
- **OQ4 — parser 충돌**: provenance 블록 본문이 우연히 `## Verdict`/4 H2 문자열을 포함하면 parser count 가 깨진다. **mitigation**: 블록은 fixed heading + 그 문자열을 본문에 넣지 않도록 runner 가 생성(자유 prose 아님).
- **OQ5 — F9 engine identity persist 범위**: 일반 review 에도 engine path 를 persist 하면 over-scope/노이즈인가? self-modification 한정 expected 로 둘지(§6b.2 패턴) 결정 필요.
- **OQ6 — maintenance-mode 경계**: reviewer version 신규 관측은 "new feature" 인가 "contract clarification/observability" 인가? 본 spec 은 feature-adjacent 로 보고 단계별 명시 승인을 요구한다(§Document character maintenance-mode 위치). 사용자/리뷰가 이 분류를 확인해야 한다.
- **OQ7 — staleness**: provenance 는 "이 result 를 만든 실행" 의 사실이므로 §7 staleness 규칙(source 수정 시 pass stale)은 그대로 적용되며 provenance 가 그것을 바꾸지 않는다(혼동 방지).

## 12. 정직성 경계 (verified / inferred / not-done)

- **verified (inspection) — *spec 작성 시점(= P2 전) 기준***: PV-V1(run-fact stdout-only, 라인 401–425), PV-V2(result.md 는 adapter 의 result-output mechanism 으로 adapter 가 작성, runner read-back only 라인 95/392), PV-NV1(adapter kind 미emit — *P2 전 baseline*), PV-NV2(adapter version 아예 미관측; stderr 에서 effort 만 추출 라인 179 — *P2 전 baseline*), active adapter(codex)의 version-reporting 으로 version 문자열 관측 가능(`codex-cli 0.132.0` 1회 확인). 이들은 spec 작성 시점(P2 전)에 현 repo 파일/1회 read-only 명령에서 직접 확인한 *그 시점 adapter 의 사실* 이다. **PV-V1·PV-V2 는 P2 후에도 유효**(P2 는 stdout run-fact 만 additive 추가, result.md authorship·persist 미변경)하지만, **PV-NV1·PV-NV2 는 P2 가 해소했다** — P2 이후 adapter kind/version 이 `reviewer:`/`reviewer-version:` H1 run-fact 로 emit 된다(상단 Implementation status; §1.2 의 P2-이후 표기). result.md persist 는 여전히 P3.
- **inferred (미확정, spec 후보)**: §5 Option A 권고, `## Reviewer run provenance` heading 명, field 명칭(`reviewer:`/`reviewer-version:` 등), P2→P3→P4 분할·순서, OQ1 의 adapter version 관측 추상화, OQ3/OQ5 의 정책 선택 — 모두 implementation batch 가 확정.
- **not-done (미구현) — *spec 작성 시점 기준; 상단 Implementation status 가 현재 상태를 정정***: spec 작성 당시 P2–P4 전부 미구현이었고, 본 spec 문서 작성/corrective 자체는 source/script/test/config/contract/template/verifier/skill 을 변경하지 않았다(본 spec 문서 + 등록용 STATUS/BACKLOG/INDEX pointer 외 mutation 없음). **그 이후 별도 승인된 P2·P3·P4 구현 batch 가 진행됐다 — P2/P3 가 `scripts/review-run.ps1` + `tests/review-run.Tests.ps1`(P3 는 추가로 contract §3/§4 + template)를, P4 가 SKILL + README/OPERATOR_GUIDE_KR/CHATLOG_CONTRACT mirror 라벨(docs-only)을 변경했다; P2·P3·P4 전부 구현됐다.** 본 spec 채택 자체가 commit/push/activation 승인은 아니다(각 단계 별도 사용자 승인).

## 13. approval boundary / 본 spec 이 하지 않은 것

- source/script/test/config 미변경(`review-run.ps1`·verifier·tests·`config/reviewer.json`·contract·template·SKILL·policy 불변) — ***이 approval-boundary 는 spec 작성/planning batch 기준이다.*** 본 (planning) 작업의 mutation 은 본 spec 문서 + 등록용 BACKLOG RV-B-06 row + STATUS "Open / historical" pointer + `docs/backlog/INDEX.md` enumeration 1줄에 한정한다. **이후 별도 승인된 P2·P3 구현 batch 가 `scripts/review-run.ps1` + `tests/review-run.Tests.ps1` 를 변경했고, P3 는 추가로 `docs/contracts/review/REVIEW_RESULT_CONTRACT.md`(§3 dual-authorship/§4) + `templates/review-result.md` 를 변경했다(상단 Implementation status); `review-verify.ps1`/`review-input-verify.ps1`·`config/reviewer.json`·SKILL·policy 는 P2·P3 에서 불변이고 parser gate 미확대다.**
- implementation: **P2·P3·P4 진입·구현됨**(상단 Implementation status). P4 는 SKILL + mirror docs(docs-only)이며 runner/tests/result-block/parser 불변. global/user config 미변경. snapshot/manifest 없음. **commit/push·activation 상태는 아래 RV-B-06 closeout 줄 참조** — P1–P4 는 commit/push 완료이고, activation/global update 만 미수행(pending)이다.
- RV-B-06 트랙(P1–P4)은 구현·리뷰·커밋·push 완료(P1 `77691c2` / P2 `fdde410` / P3 `fbd295e` / P4 `cfac1ed`)되고 STATUS Completed ledger 로 closeout(BACKLOG tombstone)됐다. 남은 것은 **activation/global update** 뿐이며 사용자의 별도 명시 승인 사항이다. reviewer verdict/opinion 은 그 승인이 아니다.
- review tooling self-modification 이므로 본 spec 및 후속 단계의 closeout review 는 §5a.7 대로 global stable ToolRoot engine 으로 수행한다.

## 14. 다음 single action

**P2·P3·P4 는 모두 구현·리뷰·커밋·push 완료됐다**(상단 Implementation status; P2 `review-result-provenance-p2-2026-06-03`, P3 `review-result-provenance-p3-2026-06-03`, P4 `review-result-provenance-p4-2026-06-03`; commits P1 `77691c2`/P2 `fdde410`/P3 `fbd295e`/P4 `cfac1ed`). **RV-B-06 은 closeout 완료** — BACKLOG row 는 STATUS Completed ledger 로 tombstone 됐다. 남은 single action 은 사용자 결정에 따라 **deployed surface(runner/contract/template/SKILL)의 activation/global update** 여부뿐이며, 사용자의 별도 명시 승인을 요한다.
