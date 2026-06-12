# install-update Plan

## Header

**이 문서는 무엇의 Plan 인가.** 채택된 `docs/install-update/install-update_design.md` 를 실행 가능한 batch 구조로 분해하는 Plan 이다 — batch I(install-update 도메인 마이그레이션)의 scope / hard boundary / validation expectation / review focus / Work Packet 선언과 open decision 의 close 지점을 확정한다.

**이 체인이 끝나면 무엇이 되는가.** install-update_spec(목표 상태 명세) 작성과 구현(문서 수렴 mutation)이 승인 가능한 단위로 정의되고, closeout 후 install-update 도메인이 `docs/install-update/` 안에서 닫힌다(spec + backlog live, 구계열 7파일 + contract 1파일 retire).

**이 문서가 아닌 것.** Design 아님 · Spec 아님 · Work Packet 아님 · 작업 메모 아님 — 조사 결과·line 분류·candidate-file 분석은 Work Packet 소관, 실행 순서 세부·실행 기록은 operator report(`log/**`) 소관. 이 Plan 은 mutation/commit/push 승인이 아니다(1회 진술).

## Batch 순서와 의존

- **단일 batch(I) 로 통합한다.** 분리(예: contract 거취와 systems 7파일 처분을 별도 batch 로) 근거 없음 — 구현 표면이 문서 한정(behavior 변경 0; scripts 주석 3건의 비-behavior 갱신 포함)이고, contract 거취 판정이 도메인 spec 의 존재를 전제하므로 분리하면 spec-of-record 이중 표면(mixed-state) 기간만 연장된다. 잔재 retire 는 spec 생산과 같은 mutation 라운드에서 닫는다(additive-only 차단).
- **상위 의존**: batch M(모델 형틀)·B(pilot 검증)·R(review 도메인) 완료가 전제(충족). I 는 S 의 선행 — skills 해체 시 착지점 중 하나가 install-update_spec 이다. P(project-level 정리)는 I 이후.
- **batch 내부 승인 의존**(상세 절차는 공통 lifecycle 을 따르고 여기 재기술하지 않는다): Work Packet(분석) → Spec 작성·review → 사용자 승인 → 구현 mutation → corrected-state review → closeout. 각 mutation·commit·push 는 별도 명시 승인.

## Batch 정의

### Batch I — install-update 도메인 마이그레이션 (단일)

- **목적(한 줄)**: `docs/install-update/install-update_spec.md` 를 목표 상태 명세로 생산하고(global-invocation contract 거취 확정 포함), 분량 최대 도메인인 install-update 를 자기 폴더 안에서 닫는다.
- **scope — 다루는 것**: Design "수정 대상" 절의 처분 실행 — GLOBAL_INSTALL_UPDATE_MODEL 분리 흡수(current-bearing 은 3차-reconciliation 기준 추출; §8A 정책 전체 포함) 후 retire · STEP3 가이드 anchor 별 선별 흡수(owner 기소유분은 명명 갈음) 후 retire · UNINSTALL_LIFECYCLE_DESIGN durable 흡수 후 retire · SHARED_GLOBAL_INVOCATION_CONTRACT 거취 확정(방향 = 흡수; Work Packet 의 unique-live-meaning·live/superseded 판정이 확정 입력; D6/D7 superseded 부활 금지) 후 확정 시 retire + `docs/contracts/global-invocation/` 빈 폴더 제거 · STATUS 3분리 후 retire · BACKLOG(IU-B-01..06·13, ID 보존)+DEFERRED(IU-D-01/02/03/07/08, deferred 한정어·reopen 조건 보존)+IDEAS(idea-only·RETIRED 한정어 보존) → `install-update_backlog.md`(next ID: IU-B-14) 통합 후 retire · glossary 2종 close(`global-invocation single-home` = spec 귀착 · `run diagnostics` 비채택; glossary 본문 mutation 은 별도 승인) · routing 이관(`docs/README.md` §5 의 systems/contracts 행 정정 + install-update 도메인 행 추가 · REPO_READING_GUIDE 의 install-update 항목 이관·제거 · `docs/contracts/README.md` 행 제거 · `docs/backlog/INDEX.md`·`docs/roadmap/INDEX.md`·`CURRENT_MILESTONES.md` 행 갱신 · root `CLAUDE.md`/`AGENTS.md` trigger map "Install / update / uninstall" 행 mirror-edit) · inbound pointer 갱신(약 34파일/192건 — pointer 수준만; scripts 주석 3건 self-contain 포함) · `INSTALL.md` pointer-only retarget 2곳(152행·455행 — 사용자 기합의 범위, meaning-preserving 명시) · `docs/systems/install-update/` 빈 폴더 제거 · closeout 시 install-update_design/plan retire + Work Packet 삭제.
- **scope — 다루지 않는 것**: `GLOBAL_ADOPTION_DECISION.md`·`POST_MVP_PLAN.md`·`docs/project/AI_HARNESS_TOOLSET_SCOPE.md`·architecture residue·`REPO_READING_GUIDE.md` 자체·`docs/backlog/INDEX.md` 자체의 retire(P 소관 — 여기서는 pointer 정정만) · skills 도메인 판정(S 소관) · `docs/systems/`·`docs/contracts/` 계층 자체의 제거(P 소관) · 글로벌 설치본(channel 3) refresh(별도 명시 결정) · deferred/backlog 항목의 착수·IU-B-07 reopen·§15.6 out-of-scope 입장의 reopen · 외부 v2 lineage 본문 수정.
- **hard boundary(불가침 표면)**: `INSTALL.md` 본문 불가침 — contextual duplication 회수/약화/재작성 금지, 변경은 pointer-only retarget 2곳 한정이며 이 경계를 넘어야 성립하는 상황이 오면 stop · install/update/uninstall/activation **scripts·config·tests behavior 불변**(LTS maintenance) — scripts 갱신은 주석 self-contain 의 비-behavior 한정, 경계 초과 필요 시 stop · payload/manifest 구조 불변 · `snippets/**` 불변 · `log/` footprint 규약 불변 · rejected umbrella(global-invocation/instruction-surface/evidence) 부활 금지 · 새 routing 내용은 `docs/README.md` 만 · retire 예정 구조물에 새 narrative 추가 금지 · **root trigger map 행 갱신은 repo-local instruction surface 변경**이므로 구현 mutation 라운드의 명시 승인 위에서만, mirror-edit 대칭 + parity test 로 검증한다(design 리뷰 인계 조건 ①).
- **validation expectation(무엇이 성립해야 하는가)**: install-update_spec 이 spec checklist 를 의미 수준에서 통과 · Spec↔구현 1:1 normative 문장 동기화(대조 대상 = lifecycle scripts 7종 + `scripts/lib/` 6종의 외부 관찰 가능 행동·소유 경계 + config schema + tests + `INSTALL.md` 와의 점유 경계; 근거 기록처 = operator report / `log/evidence/**`) · **spec 의 `INSTALL.md` operative 영역(명령·필드·status 문자열·단계 순서) 재진술 0**(design 리뷰 인계 조건 ② — Work Packet ③축 대조로 입증) · 4-class reference sweep — 적용 표면 한정어: **repo tracked 파일 기준** dangling 참조 0, retire 대상 **전체 파일명 기준 case-insensitive 전수** + deletion granular technique(변형·bare-section `§N`)(design 리뷰 인계 조건 ④) · **full Pester suite PASS + `scripts/verify-ps1.ps1` PASS**(scripts 주석 갱신의 무행동변경 입증) · `tests/repo-local-instruction-parity.Tests.ps1` PASS(root mirror-edit 대칭 — 인계 조건 ①) · `.md` encoding 규약(UTF-8 no BOM + LF) · 비례성 출구 사용 횟수의 closeout 1줄 보고.
- **review focus(지속 관점)**: ① install-update_spec 이 목표 상태 명세인가 — 회차 candidate 목록·실행 시퀀스·staging·review result·readiness 판정 유입 0 ② **`INSTALL.md` 점유 경계 침범 0** — spec 이 operative 실행 계약을 재진술/요약/약화하지 않는가(인계 조건 ②) ③ **contract 거취의 재확인** — Work Packet 의 unique-live-meaning 판정이 흡수 확정을 지지하는가, D6/D7 superseded mechanism 의 spec 부활 0 인가(인계 조건 ③) ④ 대형 문서 흡수의 양방향 — prose mirror 화 vs 과소 흡수(unique live 의미 누락; 특히 MODEL 의 superseded-framing 본문에서 3차 기준 current 의미 추출의 정확성) ⑤ 구계열 7+1 파일 retire 의 owner absorption proof 무누락 ⑥ interface vs semantics — 타 도메인(review·brief·verify-ps1) semantics 재진술 0, cross-domain 메커니즘 예외는 interface 진술까지 ⑦ scripts 갱신 diff 가 비-behavior 경계 안인가.
- **Work Packet**: **필요.** 목적 = ① 대형 4문서의 절/행 단위 current-bearing(normative/interface) vs historical narrative 분류 대조표 — MODEL 은 3차-reconciliation note 우선순위로 current 의미만 추출, STEP3 는 anchor 별 "owner 기소유 → 명명 갈음 / spec 문장 필요" 선별, CONTRACT 는 D1–D9·§5 의 unique live meaning 유무 + live vs superseded(D6/D7·review-cycle wording) 경계 대조(거취 확정 입력), UNINSTALL 은 durable invariant vs as-run 기록 분리 ② inbound 참조 표면(약 34파일/192건)의 4-class 분류 지도(routing·README·INSTALL.md 2곳·scripts 주석 3건·타 도메인/architecture/decisions/project 문서) ③ **spec 초안 축↔`INSTALL.md` 점유 경계 대조**(operative 재진술 0 의 입증 준비 — 이 도메인 고유 축) ④ `-AcquisitionClonePath`/URL-normalization 결정의 현재 행방 확인(backlog row 화 vs 종결의 판정 입력). 흡수 대상 = install-update_spec(지속 결정만 — normative 문장으로 재서술) + operator report(`log/**`). retire 조건 = I closeout 시 삭제. 위치 = `docs/install-update/install-update_work_packet.md`(committed temporary document — 보존 = git history; Design 의 승격 금지 조건 — live 문서로 복사·승격 금지 — 을 그대로 적용).

## Open decision 의 close 지점

Design 의 open decision 7건의 배정(+ 이 Plan 이 닫는 결정):

| # | open decision | close 지점 |
|---|---|---|
| 1 | contract 거취의 최종 확정(방향 = 흡수) | Work Packet 의 unique-live-meaning·live/superseded 판정 후 **Spec 에서** 확정; **Spec review 가 재확인**(review focus ③ — design 리뷰 인계 조건 ③) |
| 2 | 대형 문서 절별 흡수/소거의 line-level 대응 | Work Packet 작성 후 **Spec 에서**(review focus ④·⑤ 로 대조) |
| 3 | uninstall status 어휘 등 standalone 어휘의 spec 문장 수위 | **Spec 에서** — 어휘 값 enumeration 은 owner(scripts·`INSTALL.md`)에 두고 spec 은 invariant+owner 명명까지(review focus ② 가 경계 감시) |
| 4 | residual risk·deferred 의 backlog 문안(한 줄 + reopen 조건 + 한정어) | **Spec/backlog 작성에서** |
| 5 | `-AcquisitionClonePath`/URL-normalization 결정의 행방 | **Work Packet 확인 후 구현 단계에서**(row 화 또는 종결) |
| 6 | `docs/README.md` 혼합 상태 문안 | **closeout Level-1 gate** — install-update 항목 이관·제거 후 README 가 mixed-state routing 을 충분히 대신하는지 명시 검사 후 `checked/updated` 보고 |
| 7 | 모델-결함 신호 | close 지점 없음 — 상시 감시(아래 rewind 조건) |

이 Plan 이 추가로 닫는 결정: 단일 batch 통합(분리 기각) · root trigger map 행 갱신의 실행 위치와 검증(구현 mutation 라운드의 명시 승인 위 + mirror-edit + parity test — 인계 조건 ①) · 4-class sweep 의 적용 표면 한정어(repo tracked 기준 + 전체 파일명 case-insensitive 전수 + deletion granular technique — 인계 조건 ④) · glossary 2종 close 의 실행 위치(구현 mutation 라운드 안에서 별도 mutation 승인으로) · `INSTALL.md` pointer-only retarget 의 실행 위치(구현 라운드; diff 에 meaning-preserving 명시) · scripts 주석 3건 self-contain 의 실행 위치(구현 라운드의 inbound pointer sweep 안에서 수행, full Pester + verify-ps1 로 무행동변경 검증).

## Stage rewind 조건

- **이 Plan 이 Design 을 위반** → stop, Design 재설계 후 Plan 재시작. (Design 은 채택본이므로, 위반 발견 자체를 결함 신호로 보고한다.)
- **install-update_spec 이 이 Plan 을 위반** → stop, re-plan 후 Spec 재시작.
- **구현이 Spec boundary 를 초과** → stop + ask user(조용한 scope 확장 금지). 특히 `INSTALL.md` 변경이 pointer-only 2곳을 벗어나야 성립하거나, scripts 갱신이 비-behavior 경계(주석 self-contain)를 벗어나야 성립하는 상황이 이 경로다.
- **모델-결함 신호**(spec 이 회차 candidate 목록·실행 시퀀스·staging·review result·readiness 판정을 요구하기 시작, 또는 형틀이 cross-domain 메커니즘 도메인을 표현하지 못함) → batch 중단 → 외부 Design rewind(외부 v2 lineage 의 model-rework Design; read-only 보존본 — batch 안에서 repo 형틀을 수정하지 않는다).
- **검증/리뷰 실패** → 해당 단계 rewind(corrective loop; 같은 task·perspective 아래 새 pass).
