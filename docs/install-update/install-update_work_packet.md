# install-update Work Packet

> 회차 한정 임시 작업 문서(class-2 committed temporary) — batch I 의 분석·분류 대조표. 승인 대상 아님 · live 문서 아님 · Spec 대체 아님 · closeout 시 삭제(보존 = git history). 어떤 내용도 live 문서로 복사·승격되지 않는다 — 지속 결정만 Spec 의 normative 문장으로 재서술된다(1회 진술). 실행 메커닉(명령 시퀀스·staging·review/validation result·readiness 판정)은 담지 않는다 — operator report(`log/**`) 소관.

## 0. 분류 축 (Design·Plan 이 확정한 기준의 적용형)

- **분류값**: `spec` = current-bearing normative/interface → install-update_spec 의 normative 문장으로 재서술 · `owner` = 이미 active surface(INSTALL.md/scripts/schema/snippet/tests)가 소유 → spec 은 invariant+owner 명명으로 갈음 · `backlog` = open/deferred/idea 항목 → install-update_backlog.md row · `hist` = historical narrative/superseded/당시 기록 → git history 보존(비흡수).
- **MODEL 특칙**: 본문에 1차/2차/3차 reconciliation·source-cache supersede 가 의도 보존되어 있으므로 current 의미는 **3차 note 우선순위로만** 추출한다(1차/2차 framing wording 은 전부 hist).
- **CONTRACT 특칙**: 상단 supersede note 기준 — D1–D9 결정 자체는 유효하되 review-cycle/sidecar wording 은 hist; **D6/D7 은 mechanism 자체가 제거된 superseded — spec 부활 금지**.
- **STEP3 특칙**: 상단 superseded note(source-cache canonicalization) 기준 — §10/§15/§16/§17/§18 의 source-cache canonical-persistent-sibling 계열 wording 은 전부 hist 이고 current 의미는 note 의 정합 규칙으로만 추출하며 그 operative 소유는 INSTALL.md. anchor 절(§10~§19)의 "작업 후보 아님"/forbidden enumeration 은 standing 금지로만 1회 합류(절차 단계·field 세부는 owner) — 같은 경계의 절간 반복 재진술은 중복분으로 hist.
- **INSTALL.md 점유 특칙**: 명령·필드 값·status 문자열 enumeration·단계 순서·승인 절차 단계는 INSTALL.md/scripts 점유 — spec 으로 가져오지 않는다(§8).

## 1. GLOBAL_INSTALL_UPDATE_MODEL.md (617줄) — 절별 분류

| 절 | 분류 | 근거/흡수 내용 |
|---|---|---|
| Header 3 note(status routing·실행 authority·비승인 목록) | spec(부분) | "실행 operative contract = INSTALL.md 하나, 모델/설계 충돌 시 실행은 INSTALL.md" → spec 점유 경계 문장. 나머지 self-routing 은 문서 retire 로 소멸 |
| Path notation | spec(1줄) | placeholder 표기 규율(실사용자 폴더명·maintainer 경로 비기재) — durable 문서 규율 |
| §1 exec summary + 2 reconciliation note | spec(결론만)+hist | 모델 요지(Claude-operated install/update·metadata-dispatch·footprint log/ only)는 spec; source-cache/BRIEF 3단 lineage 는 hist(현행 결론만 spec: run-scoped fresh acquisition 은 INSTALL.md owner) |
| §2 source 획득 2-mode | spec | 2-mode 공통 구조(획득만 다르고 최종 구조 동일) — normative |
| §3 method 비교 + §3.1 | spec(결정만)+hist | 목표 방식 결정 + reinstall-first recovery posture(+activation surface 별도 영역 2분류: managed-block=marker-bounded replace·skill mirror=canonical-overwrite, no pre-write backup) → spec; 비교표·legacy 서사 hist |
| §4 update modes | spec(invariant)+owner | metadata-dispatch invariant + 두 사용자 명령의 의미 경계 → spec; git-url "clone recovery" wording 은 superseded(hist), 현행 동작은 INSTALL.md owner |
| §5 metadata | spec(invariant)+owner | 위치/성격 invariant(instance 는 global layer only·target 비생성·source 에는 schema/example 만) → spec; 필드 표·example JSON → owner(INSTALL.md 14-field schema·scripts) |
| §6 layer model L0–L4 | spec | 계층 경계와 소유 의미(channel 2 override 경계·channel 3 default 포함) → spec; Layer 4 의 1차/2차 잔재 wording 은 hist |
| §7 validation-before-impl | hist | sequencing 결정은 이행 완료된 당시 기록(§7.2 검증 4축은 §9.4 와 중복) |
| §8 footprint contract | spec(전체) | allowed(log/ only)/forbidden 목록 — cross-domain interface 의 home. brief/review spec 이 참조하는 경계 |
| §8A activation-surface 정책 | spec(전체) | STATUS 지정 single home — forced-copy+final-verification·generic inventory model·신규 extension checklist·hook 시 동일 적용. status 문자열 값 자체는 owner(INSTALL.md §13) |
| §9 self-adoption | spec(결정만)+hist | source payload vs project-local state 분리·검증의 의미(global entrypoint 기준)·§9.5 separate state root not-default → spec; §9.3 reconciliation list·BRIEF note lineage → hist |
| §10 diagrams | hist | 정보는 §6/§8 의 spec 문장으로 충분 — spec 은 다이어그램 비운반 |
| §11 relationship | hist | 관계는 spec 의 owner 지도·cross-domain interface 절이 새로 정의 |
| §12 non-goals | spec(standing 만) | transaction/rollback/tamper-detection 미도입·auto daemon/watcher/scheduler 금지·installer-first productization 금지·automation 본체 vs managed-block apply 승인 scope 분리·`%USERPROFILE%\.claude\AGENTS.md` 금지 경로 → spec durable boundary; "본 문서는 승인 아님" 류는 retire 로 소멸 |
| §13 execution status note | hist | 당시 시점 기록(이후 IU-13 으로 self-adoption 수행됨 — posture 는 spec 의 lifecycle 사실로) |

## 2. UNINSTALL_LIFECYCLE_DESIGN.md (259줄) — 절별 분류

| 절 | 분류 | 근거/흡수 내용 |
|---|---|---|
| §0 status header + provenance | hist | as-built 사실(구현 완료)은 spec posture 1줄로 |
| §1 scope + separate entrypoint | spec | entrypoint 분리 invariant(uninstall 은 install-update.ps1 의 mode 가 아니다 + 근거: 좁은 mutation surface 보존) |
| §2 success criterion | spec | footprint-zero 4-target 정의 + effective-surface 한정(비-effective Codex 파일의 stale pair = detect-warn) + "verified end state" 의미 |
| §3 trampoline(3.1–3.3) | spec(invariant)+owner | main entrypoint 는 install root 를 직접 삭제하지 않음·finalizer 는 parent 종료 대기·path re-guard·best-effort self-clean+exact-path 보고 → spec invariant; 단계 세부 → scripts owner |
| §4 marker-span excision | spec(invariant)+owner | file 비삭제(빈 파일도 보존)·0-pair idempotent no-op·2+/malformed fail-fast(preflight 전체 차단)·`.amb-backup` 비삭제 보존 → spec; 함수 분기 세부 → scripts |
| §5 expected-footprint enumeration | spec(invariant) | blind delete 금지·expected-set 대조·unexpected fail-fast·path guard(leaf/parent 정확 일치) |
| §6 skill mirror removal | spec(invariant)+owner | owned-set 은 installed payload 에서 enumeration(비-owned sibling 보존); 절차는 INSTALL.md §10 owner |
| §7 non-targets | spec(전체) | durable boundary(project log/·source repo·sibling skills·marker-outside·.claude/.codex 자체·project-root block) |
| §8 dry-run/apply/verify + §8.1 | spec(invariant)+owner | 3-분리 invariant + preflight-all-then-act + 어휘의 standalone 성격 → spec; status 값 표 → owner(scripts emission; INSTALL.md §11(b) 서술) — open decision #3 적용점 |
| §9 failure policy | spec(invariant) | 2-tier(preflight=전체 차단 vs post-preflight=per-surface partial·무 cross-surface transaction)·already-absent idempotent |
| §10 governance §11(b) | owner | INSTALL.md §11 이 operative — spec 은 "§11(a) class 로 자라지 않는다" 경계만 interface 진술 |
| §11 decisions O1–O7 | hist | current 효과는 §2~§9 분류에 이미 포함(O6 비대상·O7 effective-surface 는 §2 로) |
| §12 relationship | hist | — |
| §13(+13.1/13.2) dogfood + IU-B-09 update | hist | first-time insertion 해소의 current 의미는 INSTALL.md §6.1/§10·scripts 가 owner — spec 비재진술 |
| §14 incident IU-B-10 | hist | current 의미(installed-root README 의 uninstall discovery 절) owner = `templates/install-root/...README.md` + INSTALL.md §7.3 |

## 3. SHARED_GLOBAL_INVOCATION_CONTRACT.md (409줄) — D1–D9·절별 분류 + 거취 판정 입력

| 항목 | 분류 | 근거 |
|---|---|---|
| Header notes + supersede note | hist | 분류 기준으로 소비 완료(§0 특칙); 문서 retire 로 소멸 |
| §1 purpose · §2 inputs · §3 layer recap | hist | layer model 은 MODEL §6→spec 이 흡수; BriefRoot current framing 은 brief_spec owner |
| D1 channel chain(+history note) | spec(invariant)+owner | 6-channel 우선순위·channel 3 absent-skip/incomplete-fail-fast·channel 2 는 process-scope override 한정·user-level config 비채택·snippet 절대경로 비채택 → spec; 구현 = `scripts/lib/path.ps1`(`Get-ToolRoot`·`Test-IsValidToolRootPayload`) owner |
| D2 resolver fallback | spec(invariant)+owner | explicit(ch1/2/3) = fail-fast·implicit(ch4/5) = fallback+명시 warning → spec; pseudo-code → owner |
| D3 multi-marker dogfooding | spec(invariant)+owner | 다중 marker 동시 존재 시에만 source-repo 판정 invariant → spec; marker 3종 값 → owner(`Test-IsSourceRepoRoot`) |
| D4 snippet rewrite · D5 SKILL.md 분기 | owner(hist 절반) | 이행 완료 — 현행 효과는 snippets/SKILL.md 가 self-contained 소유. spec 은 "deployed snippet 이 topology 를 self-contained 운반한다" interface 진술만 |
| D6 review-verify binding · §5.4 | hist(superseded) | mechanism 제거 — **spec 부활 금지**(corrective 로 확정된 경계) |
| D7 untracked exclusion · §5.5 | hist(superseded) | 동일 |
| D8 self-target enforcement · §5.6 | spec(interface) | "source repo 의 git-tracked `log/**` 금지 + 비-zero exit" — 의미 owner 는 verify-ps1(D8 검사)·배포 rule; spec 은 cross-domain interface 진술만 |
| D9 ProjectRoot CWD + §5.3 | spec(invariant)+owner | CWD default + `.git` 부재 시 advisory warning(fail 아님) → spec; pseudo-code → owner |
| §5.1/§5.2 pseudo-code | owner | scripts/lib/path.ps1·resolve-script.ps1 소유 — spec 은 invariant 문장만 |
| §5.7 snippet/SKILL.md framing | hist+**stale 발견** | "두 곳 모두 본 design 문서를 참조하도록 명시한다" 는 **현행과 불일치**(hard-minimization 후 snippet/SKILL.md 는 docs 경로 참조 0 — self-contained). 흡수 지지 증거이자 비흡수 대상 |
| §6 implementation split + 현황 note | hist | batch 이행 기록 |
| §7 backward compat | spec(부분) | channel 5 legacy 유지·channel 3 absent-skip 호환 → D1 흡수와 합류; D6/D7 항목 hist |
| §8 open questions | 판정: O1 resolved·O3 moot → 소멸; **O4 → resolved 확인**(D8 은 verify-ps1 sub-check 로 as-built — `scripts/verify-ps1.ps1` D8 검사 실재); **O2(env/global 이 dogfooding 을 가리는 마찰 관찰) → backlog row 후보**; **O5(D9 advisory→strict 격상 기준 미정) → spec 이 "advisory 유지, 격상은 별도 결정" 을 durable boundary 로 적고 row 비생성 권고** |
| §9 non-goals | spec(standing 만, MODEL §12 와 합류) | 중복분은 1곳으로 |
| §10 source-of-truth 관계 | hist | — |

**거취 판정 입력(종합)**: 별도 contract role 을 요구하는 unique live meaning **발견 0** — ① 배포 표면의 본 문서 경로 참조 0(snippet topology 는 self-contained), ② live 결정(D1/D2/D3/D9·D8 interface)은 전부 spec invariant 로 재서술 가능하고 구현 owner 가 명확, ③ D4/D5 는 이행 완료로 active surface 소유, ④ D6/D7 superseded, ⑤ §5.7 의 자기참조 지시는 이미 현행과 어긋난 stale. → **흡수(별도 contract role 불채택) 지지**. 최종 확정은 Spec 에서(Plan open decision #1; Spec review 가 재확인).

## 4. 상태 4종 — 행별 분류

- **STATUS.md(73줄)**: Current state 6 bullet → spec posture(LTS maintenance·entrypoint split 구조·channel 3 default/channel 5 호환·reinstall-first+manifest/marker·activation 별도 명시 단계·change discipline) · Completed ledger 15행+OPS 5행 → hist(commit pointer 포함 git history) · Accepted residual risks 5항목 → backlog rows(IU-B-07 RETIRED 경계·per-environment 승인 경계·IU-D deferred residue 묶음·optional hygiene 묶음·D8 narrowed residual — 각 reopen 조건 보존; 문안은 Spec/구현 단계) · Non-claims 3항목 → spec 승인 경계(durable boundary 합류).
- **BACKLOG.md(31줄)**: open IU-B-01..06·IU-B-13 → backlog 이주(ID·direction 보존) · tombstone 5행(07/08/09/10/12) → row 미생성(예외는 구현 단계 bare-token 전수 sweep 의 기계 판정으로만; IU-B-07 경계는 IDEAS 이주 row 가 운반) · next ID = IU-B-14 승계 · "Where closed items are recorded" 절 → hist.
- **DEFERRED.md(26줄)**: IU-D-01/02/03/07/08 → backlog 이주(deferred 한정어 + reopen 조건 원문 보존; LTS note 의 "accepted residual risk" 성격 포함) · "Not deferred — §15.6 out-of-scope" 절 → spec durable boundary(재개 = 입장 reopen 별도 결정).
- **IDEAS.md(81줄)**: 항목 1(one-shot NL update/activation auto-apply) → backlog idea-only row(RETIRED 한정어 + 4단계 reopen 경로 = reopen 조건) · safe-condition outline·discipline 절 → hist.

## 5. STEP3_INSTALL_UPDATE_DECISION_GUIDE.md (1,359줄) — 절별 분류

원문 §1~§19 전문 정독 완료(총줄수 1,359 — `ReadAllLines().Count` 재측정 일치). 분류는 §0 의 STEP3 특칙(상단 superseded note = 분류 기준; anchor 의 "작업 후보 아님" = standing 금지 1회 합류)을 적용한다.

| 절 | 분류 | 근거/흡수 내용 |
|---|---|---|
| Header(status routing·subordinate 선언·비승인 목록) | hist | self-routing·subordinate·"본 문서는 승인 아님" 류는 문서 retire 로 소멸(MODEL header 처리와 동형) |
| Superseded note(source-cache canonicalization) | hist+owner | 분류 기준으로 소비 완료(§0 STEP3 특칙); 정합 규칙 6항의 operative 소유 = INSTALL.md(§2·§7·§9). durable 결론(persistent canonical output 4항목·run-scoped fresh acquisition·no persistent cache)은 §15/§16 행이 운반 — note 자체는 reconciliation 장치로 retire 와 함께 소멸 |
| §1 role | hist | 자기 역할·위치·계위 서사 — retire 로 소멸 |
| §2 decision lineage | hist | planning→cross-review→supervisor 3단 당시 기록. "임시 planning artifact 는 source-of-truth 아님" 규율의 현행 home 은 docs-working-model rule — 비재진술 |
| §3 fixed direction | spec(결론 합류)+hist | core principle(install/update/restore = source-authoritative overwrite materialization·공통 flow·update = metadata-dispatched re-materialization)은 MODEL §1/§4 흡수와 **합류(1회 진술)**; restore = user-specified ref-only 는 §11 행으로; (a)/(b) 선택지 lineage 서사는 hist |
| §4 non-goals/drift exclusions | spec(standing 만)+hist | 운영 drift(manual-copy 권고 framing·destination merge·partial patch·user-edit preservation·interactive file-by-file UX) + release/packaging drift(release 식별자·release asset·CI/CD publish·registry) 금지는 durable boundary — MODEL §12·CONTRACT §9 합류분과 1곳 진술; Step 3/Step 4 step-구분 wording 은 hist |
| §5 layer separation | spec(합류)+hist | 5-layer 분리·`current/` = runtime payload only·metadata sibling·target 비설치·footprint log/ only 는 MODEL §6/§8 spec 흡수와 합류; installer path-name 미확정 wording 은 후속 §10/§13 으로 닫힌 당시 기록 |
| §6 decomposition(canonical 9단계) | hist | Step 3 종결로 닫힌 당시 planning 분해 — 향후 작업의 기준선 아님 |
| §7 carry-forward caveats | hist(+기존 backlog 합류) | #1/#5 = closed 명기, #3/#4 = §11/§16 에서 닫힘, #2 = §14 행으로, #7/#8/#9 = wording 한정 — 전부 소비 완료. #6(baseline hash hygiene)은 기존 open IU-B-06 이 이미 운반(§4 BACKLOG 이주 — 신규 row 불요) |
| §8 usage rules for future prompts | owner(갈음)+hist | review gate·verdict 비승인·commit/push·global mutation 승인 경계의 현행 소유 = review_spec·배포 rule(repository-change-safety)·snippet safety floor — spec 은 승인 경계 분리 standing 만 MODEL §12 합류분으로 1회; Step 3 prompt 의 caveat-carry 운용 규칙은 hist |
| §9 final verdict 보존 | hist | 당시 cross-review verdict(`yes with risk`) 기록 |
| §10 3-0 layer layout anchor | spec(invariant 합류)+hist | §10.1 layer category·§10.2 `current/` 포함 금지 enumeration·§10.3 forbidden target path 는 MODEL §6/§8 흡수와 합류(중복 1곳); §10.4 metadata sibling+JSON boundary 는 MODEL §5 invariant 합류; §10.5 installer path-name carry·source-cache 미채택 wording 은 §13/§16 으로 닫힌 superseded(hist) |
| §11 3-1 metadata contract anchor | spec(invariant)+owner+hist | **spec**: restore (b) user-specified ref-only + known-good 자동 field 금지 + unknown `schemaVersion` fail-fast(silent downgrade 금지) — durable boundary; §11.7 forbidden 의 의미층(release 식별자·user-edit preservation·자동 managed-block/skill apply trigger 금지)은 §4 행과 합류. **owner**: 14-field 표·mode-conditional required·canonical filename `install.json`·§11.5 lifecycle 표(INSTALL.md 14-field schema·scripts). §11.6 작업 후보 아님 = standing 금지 합류; 부모 placeholder reconciliation 서사 hist |
| §12 3-2~3-5 pipeline grouping anchor | owner(주)+spec(경계만) | **owner**: resolved tuple field 표·§12.3~§12.6 contract 세부·§12.9 failure case(scripts/lib/install-pipeline-core.ps1·tests/support/install-pipeline-fixture.ps1·tests); 4 action label = 사용자 명령 어휘(INSTALL.md §7 점유 특칙). **spec**: source-cut detection-only(§17 행과 합류)·dogfooding 보호(§18 행과 합류)·§12.10 out-of-pipeline 경계(§14 행과 합류)·"사용자 명시 결정 없는 mode 간 자동 전환 금지"(automatic decision-maker 금지 standing) — 각 1회 진술 |
| §13 3-8 closeout | hist | §13.1 commit ledger = git history 보존; §13.2 deferred 는 전원 closed 표기 또는 §19 운영 정책으로 이행 — current 효과는 STATUS→spec posture·backlog 이주(§4)에 이미 포함 |
| §14 3-6 managed-block/skill boundary anchor | spec(invariant+owner 명명)+hist | boundary 한 줄(install/update automation core ≠ managed-block/skill apply; 한쪽 승인이 다른 쪽 비승인)은 MODEL §12 "승인 scope 분리" 흡수와 합류 + owner 명명(GLOBAL_ADOPTION_DECISION §6·INSTALL.md §10); §14.2/§14.3 enumeration 은 §10.6/§11.7/§12.10 의 종합 재진술 — 중복분 hist; §14.4 작업 후보 아님 = standing 금지 합류 |
| §15 manifest+marker contract anchor | spec(invariant)+owner | **사전 식별 후보 확정** — persistent canonical install output 4항목(`current/`+`install.json`+`payload-manifest.json`+`payload-marker.json`)·manifest/marker = sibling-of-`current/`(`current/` 안 금지)·per-file SHA-256 채택(후보 (b); (a) 도입은 별도 결정)·verify fail-fast(per-file diff+marker presence+head cross-binding; 한쪽 부재가 다른 쪽 검증을 skip 하지 않음) → spec invariant. **owner**: field 표·write/verify hook 단계 세부(scripts·INSTALL.md §11(b)/§13 서술 — open decision #3 적용점). §15.6 작업 후보 아님 = DEFERRED "Not deferred — §15.6" 절과 1:1(§4 행의 spec durable boundary 와 동일 대상 — 1회 진술) |
| §16 git-url acquisition contract anchor | spec(invariant)+owner+backlog | **spec**: run-scoped temporary work area(매 action fresh clone·action 간 persistent cache 없음)·failure preservation(clone/ref-resolve 실패 = materialization 이전 → deliverable artifact byte-identity 보존)·테스트의 외부 network 비의존 경계. **owner**: per-action lifecycle 표·git 명령 세부·toolRoot semantics(git-url 에서 empty)·leftover fail-fast 절차(INSTALL.md §2/§7/§9·scripts·tests); git-url+update-current intentionally unsupported 는 명령 지원 매트릭스로 owner(INSTALL.md §7) — spec 은 그 근거 invariant("no persistent cache → no-source-touch path 부재")만. §16.6 작업 후보 아님 = IU-D-01 git-url hardening residue 와 정합 — backlog 이주 row 가 운반(§4) |
| §17 source-cut decision anchor | spec(invariant)+owner+backlog | **사전 식별 후보 확정** — source-cut = metadata mutation class(제3의 mode 아님)·resolver detection-only+dispatcher non-process+STOP·actual handling = **deferred with exact boundary**(처리 경로 = §19 manual 재준비+deterministic reinstall; 자동 처리/in-place mutation 금지) → spec durable boundary. **owner**: 6 trigger field 표·URL normalization 비교 세부(scripts·schema). §17.5 deferred 잔여는 DEFERRED/STATUS 잔여 묶음 이주 row 가 운반(§4); §17.6 forbidden 은 중복 enumeration(hist) |
| §18 dogfooding enforcement anchor | spec(invariant)+owner | **사전 식별 후보 확정** — explicit-flag bypass 모델(`-AllowDogfoodSource`; warning-only/interactive prompt/env var/config bypass 거부)·strict mode confinement(local-clone only — git-url 은 구조적 dogfooding-irrelevant)·**5 tree separation invariant**(source working tree/global current/InstallArea/acquisition work area/ProjectRoot.log 비-overlap) → spec. **owner**: action×mode 매트릭스·`Test-InstallPipelineDogfoodingSource` contract·enforcement 절차(scripts·tests as-built). §18.6 작업 후보 아님 = standing 금지 합류; §18.7 forbidden 중복 hist |
| §19 operating policy | spec(invariant)+owner+hist | **사전 식별 후보 확정** — no automatic recovery(detection-only)·manual source 재준비+deterministic overwrite reinstall(= MODEL §3.1 reinstall-first posture 와 합류)·reinstall-first closeout(D atomicity — transaction/rollback/tamper-detection 미도입; MODEL §12 합류)·activation surface 2-class 분리(managed-block = tooling 절차 / skill = canonical-overwrite — §1 의 MODEL §3 행에 기 분류, 1회 진술) → spec. **owner**: §19.3 5단계 tooling 절차·§19.4 5단계 global apply 절차(INSTALL.md §2A·§10·`scripts/apply-managed-block.ps1`/`activate-global.ps1` — 승인 문답·단계 순서는 INSTALL.md 점유 특칙). A-2 reconciliation note·§19.6 은 hist |

**§5 종합**: ① §1~§9 hist-우세 추정 검증 결과 — §1/§2/§6/§7/§9 hist 확정, §3/§4/§5 는 MODEL 흡수와 **합류하는 spec 결론분만** 보유(STEP3 발 신규 spec 주제 없음), §8 은 owner 갈음. ② 사전 식별 spec 후보 5건(§12.8/§18 dogfooding·§17 source-cut·§15 manifest/marker·§19 operating policy·standing 금지) **전부 확정**; 추가 확정 = §11.4 restore user-specified ref-only(+known-good 금지·schemaVersion fail-fast)와 §16 run-scoped acquisition/failure-preservation invariant. ③ STEP3 발 신규 backlog row 필요 0 — §7 #6 은 기존 IU-B-06, §16.6/§17.5 잔여는 §4 의 DEFERRED/STATUS 이주 묶음이 운반.

## 6. inbound 참조 지도 (예비 grep: 34파일/192건 — 파일·class 수준; 정밀 라인 지도는 구현 게이트의 전수 sweep)

| 그룹 | 파일 | 처리 class |
|---|---|---|
| (a) 도메인 내부(retire 와 함께 소멸) | systems/install-update 7파일 + CONTRACT 자기참조 | — |
| (b) routing/orientation | `docs/current/REPO_READING_GUIDE.md`(Q1 Primary/Secondary/Do-not-use·self-adoption Q·backlog Q·plan Q 의 carve-out 언급 — 11건) · `docs/README.md` §5 행 · `docs/contracts/README.md` 행 · `docs/backlog/INDEX.md` · `docs/roadmap/INDEX.md`·`CURRENT_MILESTONES.md` · root `README.md` | 이관·정정(filename/path class) |
| (c) root instruction | `CLAUDE.md`·`AGENTS.md` trigger map 행 | mirror-edit + parity test(구현 라운드 명시 승인 위) |
| (d) 배포 표면 | `scripts/lib/activation-surface.ps1:11`·`managed-block.ps1:233`·`install-pipeline-core.ps1:40` | 주석 self-contain(비-behavior; full Pester+verify-ps1) |
| (e) INSTALL.md | 152행(STEP3 §19.4)·455행(UNINSTALL) | pointer-only retarget(meaning-preserving 명시) |
| (f) retire-bound/타 도메인(pointer 수준+당시 주석) | `POST_MVP_PLAN.md`(18) · `GLOBAL_ADOPTION_DECISION.md`(2) · `DECISIONS.md`(2)+`decisions/README.md` · `docs/project/AI_HARNESS_TOOLSET_SCOPE.md`(2) · architecture/instruction-surface 6파일 · skills STATUS·PLAN | pointer/당시-주석만, 확장 금지 |
| (g) tests | `tests/install-update.Tests.ps1` 의 `-AcquisitionClonePath` 언급은 INSTALL.md §7.1 wording 잠금 — 도메인 docs 경로 참조 아님(비대상) | — |

## 7. spec↔INSTALL.md 점유 경계 대조 축 (Plan WP ③)

- **spec 이 갖는 것**: 계층 경계(L0–L4)·footprint contract·recovery posture·activation-surface 정책·uninstall invariant(footprint-zero·trampoline·excision·enumeration)·invocation channel invariant·승인 경계 분리·standing 금지(non-goals)·owner 지도.
- **spec 이 갖지 않는 것(INSTALL.md/scripts 점유)**: 설치/업데이트/uninstall 의 명령·단계 순서·quickstart·14-field schema 값·manifest/marker 필드·status 문자열 enumeration(§13·§8.1)·managed-block apply 절차(§10)·승인 문답 절차·bootstrap clone cleanup 규칙(§6.1)·`-AcquisitionClonePath` 류 later-phase 결정(§7.1).
- 대조 방법: Spec 초안의 각 normative 문장에 대해 "이 문장이 INSTALL.md 의 어느 절을 재진술하는가?" 를 검사 — 재진술이면 invariant 수준으로 끌어올리거나 owner 명명으로 대체. (검사 실행과 결과는 operator report/evidence 소관.)

## 8. `-AcquisitionClonePath`/URL-normalization 행방 (Plan open decision #5 입력)

- 현황: INSTALL.md §7.1 이 "cache 재사용/`-AcquisitionClonePath` 는 closeout stream 의 later phase 결정 — 본 단계 비구현"으로 operative 소유; `tests/install-update.Tests.ps1` P3-T2 가 wording 잠금; URL normalization 은 source-cut 감지(§17.3 비교)의 구현 세부로 존재(별도 helper 비도입 명시). DEFERRED 테이블에 독립 row 없음(STATUS 잔여 문장에만 등장).
- 판정 입력(양안): (가) STATUS retire 로 가시성이 사라지므로 backlog 에 deferred-류 1행 신설(reopen = 별도 scoped 결정) — 가시성 보존. (나) INSTALL.md 가 이미 standing 으로 소유하므로 row 비생성·종결 — 중복 회피. **권고 = (가)** — STATUS 의 "deferred residue" 묶음 row 에 포함시키면 신규 ID 없이 운반 가능. 확정은 Spec/구현 단계.

## 9. routing 공백 확인 입력 (plan 리뷰 인계 ①)

- REPO_READING_GUIDE 의 install-update 표면: Q1(install/update/uninstall — Primary `INSTALL.md`·Secondary STATUS/DEFERRED/MODEL(§8A 명기)/STEP3·Do-not-use 의 1차/2차 잔재 경고) · self-adoption Q(Primary MODEL §9·Secondary STATUS IU-13·Historical/Do-not-use) · backlog Q(open=BACKLOG·deferred=DEFERRED) · skills plan Q 의 §8A carve-out 언급.
- 이관 요건: 위 항목들이 가리키던 질문→읽을-곳 응답이 `docs/README.md`(도메인 행: `docs/install-update/` = spec+backlog) + spec 본문으로 대체되어야 함. Do-not-use 경고(1차/2차 잔재)는 원문 retire 로 대상 자체가 소멸 — 이관 불요. self-adoption 의 "performed at `8293878d`" 사실은 ledger→git history, posture 는 spec.
- 공백 검사 항목(구현/closeout): root trigger map 행 ↔ docs/README.md 행 ↔ spec 사이에 "install/update/uninstall 질문의 read-first" 경로가 닫혀 있는가 + 잔존 legacy guide 에 dangling 참조 0.

## 10. 미완 항목 (이 WP 안에서의 잔여 작업)

- §5 STEP3 절별 분류표 — **완료**(원문 §1~§19 전문 정독 후 기입).
- §6 지도의 정밀화(파일별 매치 라인 확인은 구현 게이트 전수 sweep 에서 — WP 는 class 확정까지). WP 단계 잔여 작업 없음.
