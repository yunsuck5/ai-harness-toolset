# review Plan

## Header

**이 문서는 무엇의 Plan 인가.** 채택된 `docs/review/review_design.md` 를 실행 가능한 batch 구조로 분해하는 Plan 이다 — batch R(review 도메인 마이그레이션)의 scope / hard boundary / validation expectation / review focus / Work Packet 선언과 open decision 의 close 지점을 확정한다.

**이 체인이 끝나면 무엇이 되는가.** review_spec(목표 상태 명세) 작성과 구현(문서 수렴 mutation)이 승인 가능한 단위로 정의되고, closeout 후 review 도메인이 `docs/review/` 안에서 닫힌다(spec + backlog live, 구계열 17파일 retire).

**이 문서가 아닌 것.** Design 아님 · Spec 아님 · Work Packet 아님 · 작업 메모 아님 — 조사 결과·line 분류·candidate-file 분석은 Work Packet 소관, 실행 순서 세부·실행 기록은 operator report(`log/**`) 소관. 이 Plan 은 mutation/commit/push 승인이 아니다(1회 진술).

## Batch 순서와 의존

- **단일 batch(R) 로 통합한다.** 분리(예: contracts/policies 흡수와 systems 잔재 retire 를 별도 batch 로) 근거 없음 — 구현 표면이 문서 한정(behavior 변경 0; scripts·config·tests 의 비-behavior 참조 갱신 포함)이고, 분리하면 contract↔spec 이중 표면(mixed-state) 기간만 연장되어 single-home 위반 노출이 늘어난다. 잔재 retire 는 spec 생산과 같은 mutation 라운드에서 닫는다(additive-only 차단).
- **상위 의존**: batch M(모델 형틀)·batch B(pilot 의 모델 검증) 완료가 전제(충족). R 은 I 의 선행 — 가장 얽힌 도메인을 모델 검증 직후에 정리하고, skills 판정(S)·project-level 정리(P)에 전파될 결함을 차단한다.
- **batch 내부 승인 의존**(상세 절차는 공통 lifecycle 을 따르고 여기 재기술하지 않는다): Work Packet(분석) → Spec 작성·review → 사용자 승인 → 구현 mutation → corrected-state review → closeout. 각 mutation·commit·push 는 별도 명시 승인.

## Batch 정의

### Batch R — review 도메인 마이그레이션 (단일)

- **목적(한 줄)**: `docs/review/review_spec.md` 를 목표 상태 명세로 생산하고 잔재 최다 도메인인 review 를 자기 폴더 안에서 닫는다.
- **scope — 다루는 것**: Design "수정 대상" 절의 처분 실행 — REVIEW_RESULT_CONTRACT 절 단위 흡수(기계 세부는 active surface owner 명명으로 갈음) 후 retire · EVIDENCE_CONTRACT 두 층 분리 흡수(generic 자리·성격 = cross-domain interface 참조만, 형식 규약·R1 = spec 흡수) 후 retire · REVIEWER_CONFIG_POLICY·REVIEW_EFFORT_GUIDE invariant 흡수 후 retire · STATUS 3분리 후 retire · BACKLOG(RV-B-01/03/04/05, ID 보존)+IDEAS(idea-only 한정어 보존)+STATUS 잔여 risk 2건 → `review_backlog.md`(next ID: RV-B-09) 통합 후 retire · 당시 lifecycle 기록 10종 owner absorption proof 후 retire · routing 이관(`docs/README.md` §5 반영 · REPO_READING_GUIDE Q2/Q3 이관·제거 · contracts/policies README 행 제거 · backlog INDEX 의 review 행 갱신 · root `CLAUDE.md`/`AGENTS.md` trigger map Review 행 mirror-edit) · 구계열 retire 가 남기는 inbound pointer 갱신(Design 의 Owner surface model 이 한정 명시한 scripts·config·tests 의 비-behavior 참조 포함) · glossary 2종 close(`review-support naming` 비채택 · `evidence contract absorption` 분리 판정으로 close; glossary 본문 mutation 은 별도 승인) · 빈 폴더(`docs/contracts/review/`·`docs/contracts/evidence/`) 제거 · closeout 시 review_design/review_plan 의 retire + Work Packet 삭제.
- **scope — 다루지 않는 것**: 비-review 소유 문서의 review 의미 재진술 정리(pointer 수준 초과분 — 소유 batch I/S/P) · `docs/current/REPO_READING_GUIDE.md`·`docs/backlog/INDEX.md` 자체 retire(P) · `SHARED_GLOBAL_INVOCATION_CONTRACT.md` 거취(I; 이 batch 는 pointer 정합만) · 글로벌 설치본(channel 3) refresh(별도 명시 결정) · deployed skill 측 advisory 보강(별도 round) · IDEAS 항목의 implementation 승격 · `docs/contracts/`·`docs/policies/`·`docs/systems/` 계층 자체의 제거(P).
- **hard boundary(불가침 표면)**: review scripts/skill/templates/config/tests 의 **behavior 불변**(maintenance-mode) — scripts·config·tests 의 갱신은 주석·schema description·문서 포인터의 비-behavior 한정이며 이 경계를 넘는 변경이 필요해 보이는 순간 stop · `log/review/` 규약(three-level layout·pass 당 2-file·write-once) 불변 · verdict 어휘(`yes`/`no`/`yes with risk`) 불변 · `INSTALL.md` 불가침 · `snippets/**` 글로벌 배포 티어 불변 · rejected umbrella(evidence/global-invocation/instruction-surface) 부활 금지 · 새 routing 내용은 `docs/README.md` 만 · retire 예정 구조물에 새 narrative 추가 금지.
- **validation expectation(무엇이 성립해야 하는가)**: review_spec 이 spec checklist 를 의미 수준에서 통과 · Spec↔구현 1:1 normative 문장 동기화(대조 대상 = scripts 5종(+`scripts/lib/path.ps1` 의 layout 검증)·templates 2종·skill·config+schema·tests 의 외부 관찰 가능 행동과 소유 경계; 근거 기록처 = operator report / `log/evidence/**`) · 4-class reference sweep — 적용 표면 한정어: **repo tracked 파일 기준** dangling 참조 0(gitignored `log/**` 런타임 기록은 시점 기록으로 제외), 삭제 변경이므로 deletion granular technique(case-insensitive·변형·bare-section 참조) 적용 · **full Pester suite 회귀 PASS + `scripts/verify-ps1.ps1` PASS**(scripts 주석 갱신의 무행동변경 입증; `.ps1` encoding 정책 확인) · `tests/repo-local-instruction-parity.Tests.ps1` PASS(root mirror-edit 대칭) · `.md` encoding 규약(UTF-8 no BOM + LF) · 비례성 출구(meaning-preserving 직접 수정) 사용 횟수의 closeout 1줄 보고.
- **review focus(지속 관점)**: ① review_spec 이 목표 상태 명세인가 — 회차 candidate 목록·실행 시퀀스·staging·review result·readiness 판정의 유입 0 ② contract↔spec 이중화 0 — 흡수 후 같은 normative 사실의 잔존 계약 표면 없음(single-home) ③ 당시 기록 10종 retire 의 owner absorption proof 무누락(이 batch 의 최빈 실패 모드 — 5축 canonical terminology·H1/H2/H3 세 home 분류·downstream 보존 invariant·"policy origin" 지위의 unique live 의미 누락 여부) ④ EVIDENCE_CONTRACT 두 층 분리가 과흡수/과소흡수 없이 실행되었는가 — Work Packet 의 `log/evidence/**` 소비자 재분류 결과와 대조 ⑤ scripts·config·tests 갱신 diff 가 비-behavior 경계 안인가 ⑥ spec 이 기계 세부(H2 enumeration·regex·precedence 분기·run-fact 라인)를 복제하지 않고 active surface owner 명명으로 갈음했는가.
- **Work Packet**: **필요.** 목적 = ① 구계열 17파일의 절/행 단위 current-bearing vs narrative 분류 대조표(contract 절→spec 문장 대응 + 당시 기록 10종의 unique live 의미 유무 판정 — 5축 어휘·H1/H2/H3 분류·downstream 보존 invariant·policy origin 지위 포함) ② inbound 참조 표면의 4-class 분류 지도(routing·README·tests/scripts/config·타 도메인 문서) ③ `log/evidence/**` 언급 표면의 사용 성격 분류(경로 interface 사용 vs evidence 형식 의미 의존 — Design 분리 판정의 재확인 입력) ④ STATUS ledger 의 "global activation pending" 기재의 현재 사실 대조 입력 준비. 흡수 대상 = review_spec(지속 결정만 — normative 문장으로 재서술) + operator report(`log/**`). retire 조건 = R closeout 시 삭제. 위치 = `docs/review/review_work_packet.md`(committed temporary document — 보존 = git history; Design 의 승격 금지 조건 — live 문서로 복사·승격 금지 — 을 그대로 적용).

## Open decision 의 close 지점

Design 의 open decision 5건의 배정(+ 이 Plan 이 닫는 결정):

| # | open decision | close 지점 |
|---|---|---|
| 1 | contract 절별 흡수/소거의 line-level 대응 | Work Packet 작성 후 **Spec 에서**(review focus ②·⑥ 으로 대조) |
| 2 | STATUS ledger 의 "global activation pending" 기재의 현재 사실 여부 | **구현 단계** — Work Packet 이 대조 입력을 준비하고, 글로벌 설치본 대조 후 처분(stale 이면 기재 없이 종결 / 사실이면 backlog row) |
| 3 | residual risk 2건의 backlog 문안(한 줄 + reopen 조건 압축) | **Spec/backlog 작성에서** |
| 4 | `docs/README.md` 혼합 상태 문안 | **closeout Level-1 gate** — Q2/Q3 이관·제거 후 README 가 mixed-state routing 을 충분히 대신하는지를 명시 검사 항목으로 확인하고 `checked/updated` 로 보고 |
| 5 | 모델-결함 신호 | close 지점 없음 — 상시 감시(아래 rewind 조건) |

이 Plan 이 추가로 닫는 결정: 단일 batch 통합(분리 기각) · 4-class sweep 의 적용 표면 한정어(repo tracked 기준 + deletion granular technique) · glossary 2종 close 의 실행 위치(구현 mutation 라운드 안에서 별도 mutation 승인으로) · `log/evidence/**` 소비자 재분류의 절차 위치(Work Packet ③ → Spec 의 cross-domain interface 절 반영) · scripts·config·tests 비-behavior 참조 갱신의 실행 위치(구현 mutation 라운드의 inbound pointer sweep 안에서 수행, full Pester + verify-ps1 로 검증).

## Stage rewind 조건

- **이 Plan 이 Design 을 위반** → stop, Design 재설계 후 Plan 재시작. (Design 은 채택본이므로, 위반 발견 자체를 결함 신호로 보고한다.)
- **review_spec 이 이 Plan 을 위반** → stop, re-plan 후 Spec 재시작.
- **구현이 Spec boundary 를 초과** → stop + ask user(조용한 scope 확장 금지). 특히 scripts·config·tests 갱신이 비-behavior 경계(주석·schema description·문서 포인터)를 벗어나야 성립하는 상황이 이 경로다.
- **모델-결함 신호**(review_spec 이 회차 candidate 목록·실행 시퀀스·staging·review result·readiness 판정을 요구하기 시작, 또는 형틀이 이 도메인을 표현하지 못함) → batch 중단 → 외부 Design rewind(외부 v2 lineage 의 model-rework Design; read-only 보존본 — batch 안에서 repo 형틀을 수정하지 않는다).
- **검증/리뷰 실패** → 해당 단계 rewind(corrective loop; 같은 task·perspective 아래 새 pass).
