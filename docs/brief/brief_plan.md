# brief Plan

## Header

**이 문서는 무엇의 Plan 인가.** 채택된 `docs/brief/brief_design.md` 를 실행 가능한 batch 구조로 분해하는 Plan 이다 — batch B(brief pilot)의 scope / hard boundary / validation expectation / review focus / Work Packet 선언과 open decision 의 close 지점을 확정한다.

**이 체인이 끝나면 무엇이 되는가.** brief_spec(목표 상태 명세) 작성과 구현(문서 수렴 mutation)이 승인 가능한 단위로 정의되고, closeout 후 brief 도메인이 `docs/brief/` 안에서 닫힌다(spec + backlog live, 구계열 retire).

**이 문서가 아닌 것.** Design 아님 · Spec 아님 · Work Packet 아님 · 작업 메모 아님 — 조사 결과·line 분류·candidate-file 분석은 Work Packet 소관, 실행 순서 세부·실행 기록은 operator report(`log/**`) 소관. 이 Plan 은 mutation/commit/push 승인이 아니다(1회 진술).

## Batch 순서와 의존

- **단일 batch(B) 로 통합한다.** 분리(예: spec 생산과 구계열 retire 를 별도 batch 로) 근거 없음 — 구현 표면이 문서 한정(behavior 변경 0)이고, 분리하면 contract↔spec 이중 표면(mixed-state) 기간만 연장되어 single-home 위반 노출이 늘어난다. retire 는 spec 생산과 같은 mutation 라운드에서 닫는다(additive-only 차단).
- **상위 의존**: batch M(모델 형틀) 완료가 전제(충족 — `b51acde`). B 는 R/I 의 선행 — pilot 이 모델 자체를 검증하며, 모델 결함 발견 시 B 에서 멈춰 후속 batch 로 전파를 차단한다.
- **batch 내부 승인 의존**(상세 절차는 공통 lifecycle 을 따르고 여기 재기술하지 않는다): terminology 재검증 제안 → 사용자 결정 → Spec 작성·review → 사용자 승인 → 구현 mutation → corrected-state review → closeout. 각 mutation·commit·push 는 별도 명시 승인.

## Batch 정의

### Batch B — brief pilot (단일)

- **목적(한 줄)**: `docs/brief/brief_spec.md` 를 목표 상태 명세로 생산하고 brief 도메인을 자기 폴더 안에서 닫는다 — pilot 성공 기준이자 모델 검증.
- **scope — 다루는 것**: Design "수정 대상" 절의 처분 실행 — BRIEF_CONTRACT 절 단위 이주(소비자 기준 판정) 후 retire · STATUS 3분리 후 retire · DEFERRED→`brief_backlog.md` 통합 후 retire · REPO_READING_GUIDE Q4 routing 의 `docs/README.md` 이관·제거 · 구계열 retire 가 남기는 inbound pointer 갱신(stale 1건의 meaning-preserving 정정 포함) · terminology 4건 재검증 close · closeout 시 brief_design/brief_plan 자체의 retire.
- **scope — 다루지 않는 것**: 비-brief 소유 문서의 brief 의미 재진술 정리(pointer 수준 초과분 — 소유 batch R/I/S/P) · REPO_READING_GUIDE 자체 retire(P) · glossary 본문 mutation(별도 결정·승인 영역; 이 Plan 이 승인하지 않는다는 진술은 Header 1회로 갈음) · skills 도메인성 판정(S) · BF Level 3 구현.
- **hard boundary(불가침 표면)**: brief scripts/skill/template/tests 의 behavior 불변(docs-stale 판별 시 구현이 기준, docs 측 정정만) · `INSTALL.md` 불가침 · `snippets/**` 글로벌 배포 티어 불변 · install-update 문서는 interface/포인터 정합 수준만 — **[이월 risk 1]** stale 1건 정정은 pointer / false-current wording 수준의 meaning-preserving 정정에만 한정하고, install-update 의 의미나 `INSTALL.md` 계약 영역으로 번지는 순간 owner boundary 위반으로 stop · 새 routing 내용은 `docs/README.md` 만 · rejected 도메인(`handoff/snapshot`)·용어 부활 금지.
- **validation expectation(무엇이 성립해야 하는가)**: brief_spec 이 spec checklist 를 의미 수준에서 통과 · Spec↔구현 1:1 normative 문장 동기화(대조 대상 = brief scripts 3종·template·skill·tests 의 외부 관찰 가능 행동; 근거 기록처 = closeout report / `log/evidence/`) · 4-class reference sweep — 적용 표면 한정어: **repo tracked 파일 기준** dangling 참조 0(gitignored `log/**` 런타임 기록은 시점 기록으로 제외) · brief Pester 3 suites 회귀 PASS(scripts 무변경 확인용) · `.md` encoding 규약(UTF-8 no BOM + LF) · 비례성 출구(meaning-preserving 직접 수정) 사용 횟수의 closeout 1줄 보고.
- **review focus(지속 관점)**: ① brief_spec 이 목표 상태 명세인가 — 작업통제 패킷 재발 여부(pilot 의 핵심 검증점) ② contract↔spec 이중화 0(single-home) ③ retire 의 owner absorption proof 무누락 ④ **[이월 risk 2]** spec 의 concrete path 문안이 path 소유로 읽히지 않는가 — `<ProjectRoot>/log/brief/BRIEF.md` 는 active surface 가 소유한 현재 값으로 1회만 명시되었는가 ⑤ **[이월 risk 1 재검]** stale 정정 diff 가 meaning-preserving 경계 안인가.
- **Work Packet**: **필요.** 목적 = cross-domain line-level 분류(brief 의미가 외부 문서에 재진술된 지점의 지도 — 옛 lineage 지도의 재검증 포함) + BRIEF_CONTRACT 절→spec 문장 대응표 + STATUS ledger 행별 처분 대조 + terminology 4건의 실사용 증거 수집. 흡수 대상 = brief_spec 의 cross-domain interface 절(지속 경계만) + closeout report. retire 조건 = B closeout 시 삭제. 위치 = `docs/brief/brief_work_packet.md`(committed temporary document — closeout 시 삭제, 보존 = git history; Design 의 승격 금지 조건 — live 문서로 복사·승격 금지, 지속 결정만 spec normative 문장으로 재서술 — 을 그대로 적용).
- **실행 주의 통제(이월 risk 3건의 배정)**: risk 1 → 본 batch hard boundary(구현 시 적용) + review focus ⑤(corrected-state review 에서 diff 검증). risk 2 → Spec 작성 시 durable boundary 절의 문안 규칙 + review focus ④. risk 3 → closeout Level-1 gate 의 명시 검사 항목(아래 close 지점 4).

## Open decision 의 close 지점

Design 의 open decision 5건의 배정(+ 이 Plan 이 닫는 결정):

| # | open decision | close 지점 |
|---|---|---|
| 1 | terminology 4건(`checkpoint`/`restore point`/`continuation`/`handoff`) 재검증 채택 | **Spec 작성 전 사용자 결정** — Work Packet 이 active surface 실사용 증거를 수집하고 operator 가 재검증 제안을 보고, 사용자가 채택을 결정한다(glossary 본문 반영은 별도 승인). 이 Plan 이 닫는 부분: 재검증의 입력(실사용 증거 + glossary 단일-상태 규칙)과 절차 위치(Work Packet→사용자 제안) 확정 |
| 2 | BRIEF_CONTRACT 절→spec 문장 line-level 대응 | Work Packet 작성 후 **Spec 에서**(이중화 0 을 review focus ② 로 대조) |
| 3 | BR-D-02 tombstone 필요 여부 | **closeout reference sweep** 의 bare-token 기계 판정(재량 아님) |
| 4 | `docs/README.md` 혼합 상태 문안 | **closeout Level-1 gate** — **[이월 risk 3]** Q4 이관·제거 후 README 가 mixed-state routing 을 충분히 대신하는지를 이 gate 의 명시 검사 항목으로 확인하고 `checked/updated` 로 보고 |
| 5 | pilot 모델-결함 신호 | close 지점 없음 — 상시 감시(아래 rewind 조건) |

이 Plan 이 추가로 닫는 결정: 단일 batch 통합(분리 기각) · 4-class sweep 의 적용 표면 한정어(repo tracked 기준) · stale 1건 정정의 실행 위치(구현 mutation 라운드의 inbound pointer sweep 안에서 수행).

## Stage rewind 조건

- **이 Plan 이 Design 을 위반** → stop, Design 재설계 후 Plan 재시작. (Design 은 채택본이므로, 위반 발견 자체를 결함 신호로 보고한다.)
- **brief_spec 이 이 Plan 을 위반** → stop, re-plan 후 Spec 재시작.
- **구현이 Spec boundary 를 초과** → stop + ask user(조용한 scope 확장 금지). 특히 stale 정정이 meaning-preserving 경계를 벗어나는 경우(이월 risk 1)가 이 경로다.
- **모델-결함 신호**(brief_spec 이 회차 candidate 목록·실행 시퀀스·staging·readiness 판정을 요구하기 시작) → batch 중단 → 외부 Design rewind(외부 v2 lineage 의 model-rework Design; read-only 보존본 — batch 안에서 repo 형틀을 수정하지 않는다).
- **검증/리뷰 실패** → 해당 단계 rewind(corrective loop; 새 pass).
