# brief Design

## Header

**이 문서는 무엇의 Design 인가.** brief 도메인의 첫 도메인 마이그레이션(batch B, brief pilot) 방향 문서다 — 구계열 brief 문서(`docs/contracts/brief/BRIEF_CONTRACT.md` · `docs/systems/brief/STATUS.md` · `docs/systems/brief/DEFERRED.md`)와 brief routing 을 새 docs-working-model 의 도메인 구조(`docs/brief/`)로 수렴시키는 변경의 why / what / owner-surface 결정을 담는다.

**이 체인이 끝나면 무엇이 되는가.** `docs/brief/brief_spec.md`(목표 상태 명세, 구현과 1:1 동기화)와 `docs/brief/brief_backlog.md` 가 live 가 되고, 구계열 brief 문서·routing 항목은 retire 되어 brief 도메인이 자기 폴더 안에서 닫힌다. 동시에 이 batch 는 새 모델의 첫 in-repo lifecycle 실증(pilot)이다.

**이 문서가 아닌 것.** Plan 아님 · Spec 아님 · Work Packet 아님 · brief scripts/skill/template/tests 의 behavior 변경 아님. 이 Design 은 mutation/commit/push 승인이 아니다(1회 진술).

## 왜 바꾸는가 / 무엇을 바꾸는가

**왜.** brief 도메인의 normative 사실이 구계열 세 문서에 분산되어 있고, 그 형태가 새 모델의 다섯 산출물 분류와 비정합하다 — contract 는 도메인 자신의 목표 상태 기술과 historical lineage narrative 가 혼합돼 있고, STATUS 는 current posture / capability ledger / narrative 가 한 파일에 있으며, DEFERRED 는 future-work queue 의 변형이고, question routing 은 retire 예정 표면(`docs/current/REPO_READING_GUIDE.md` Q4)에 남아 있다. single-home 원칙 하에서 이 사실들의 단일 거처는 도메인 폴더의 spec/backlog 다.

**또 하나의 왜(pilot).** batch B 는 개정 모델이 자기 기술이 아닌 실제 도메인을 표현할 수 있는지의 첫 시험이다. brief_spec 이 목표 상태 명세로 생산되지 못하고 작업통제 패킷으로 회귀하면 그것은 모델 결함 신호이며, batch 를 중단하고 외부 Design rewind 경로를 탄다(batch 안에서 형틀을 수정하지 않는다).

**무엇을.** ① `docs/brief/` 도메인 폴더에서 brief_spec 을 생산하고(아래 처분 결정에 따라 구계열 내용을 normative 문장으로 재구성), ② DEFERRED 를 brief_backlog.md 로 통합하고, ③ 구계열 brief 문서를 retire 하고, ④ brief routing 을 `docs/README.md` 로 이관하고, ⑤ 옛 brief lineage 의 requirement 4건(stale 1건 · terminology disposition 4건 · cross-domain 지도 · docs-stale vs behavior-change 판별 절차)을 재검증 후 회수한다. 구현 behavior 변경은 0 — 이 변경은 문서 표면의 수렴이다.

## Owner surface model

- **behavior owner 는 변하지 않는다**: `scripts/brief-init.ps1` / `brief-check.ps1` / `brief-status.ps1`(seed · shape 검사 · restore-summary 의 외부 관찰 가능 행동), `templates/brief/BRIEF.md`(canonical heading set seed), `tests/brief-*.Tests.ps1`(지속 검증), `snippets/claude-skills/ai-harness-brief/SKILL.md`(save/restore/update workflow 의 trigger·절차). brief_spec 은 이들을 명세하고 대조될 뿐 operative authority 가 아니다(root *Final hard rule*).
- **concrete path 표현(결정).** spec 의 durable boundary 는 **class/invariant** 를 소유한다 — "canonical Brief 자리는 단일하며 `<ProjectRoot>/log/` runtime 트리 아래다 · root `<ProjectRoot>/brief/` 와 user-home runtime root 는 rejected · Brief 가 유일한 restore source". 구체 경로 값 `<ProjectRoot>/log/brief/BRIEF.md` 는 active surface(scripts)가 소유하는 값이며, spec 은 이를 "구현이 소유한 현재 값"으로 1회 명시하고 검증은 구현 대조로 한다(값의 산문 복제를 늘리지 않는다).
- **SKILL.md 경계(결정).** brief_spec 의 owner surface 지도는 skill 을 **brief workflow 의 active surface** 로만 다룬다 — save/restore/update 의 외부 관찰 가능 경계(explicit-prompt only · operator/reviewer 분리 · missing-file 처리)는 brief 도메인의 1:1 대상이다. skill 의 배포·활성화·discovery 메커니즘과 skills 도메인성 판정은 다루지 않는다(batch S 소관; 충돌 회피 경계).

## 수정 대상 (구조물별 처분 결정)

수정하는 기존 live Spec 은 없다(첫 마이그레이션). 처분 대상과 결정:

- **`docs/contracts/brief/BRIEF_CONTRACT.md` — 절 단위 처분 후 retire.** 판정 기준 = 그 절의 소비자가 누구인가. ① 도메인 자신의 목표 상태·durable boundary(핵심 정의, canonical 자리, BF Level 의미, restore source 단일성, primitive 책임 경계, review/commit 비경계, encoding, durable 한 non-goals) → brief_spec 의 normative 문장으로 **재구성 이주**(절 구조·목록 형식의 복제가 아니라 문장 단위 재서술). ② historical lineage(1·2·3차 reconciliation 절) → git history 보존(3차의 **결정**만 spec durable boundary 문장으로). ③ **별도 adopter-interface contract role 존속은 불채택** — 이 contract 의 소비자는 brief 자신의 active surface 와 cross-domain interface(install-update 의 footprint 경계)뿐이므로 spec 본문 + cross-domain interface 절로 충분하다. auxiliary `_contract` 파일을 신설하지 않는다(rule 의 deferred 기본 유지). 절→문장 대응의 line-level 대조는 Work Packet 소관.
- **`docs/systems/brief/STATUS.md` — 3분리 후 retire.** current posture → spec(목표 상태 + lifecycle state 절). completed ledger(BR-01~03) → 각 행의 "현재 의미"가 spec 문장으로 표현되는지 대조 후 흡수(행 자체와 `POST_MVP_PLAN.md` detail 포인터는 git history 보존 — 포인터를 spec 으로 따라가지 않는다). historical narrative → git history.
- **`docs/systems/brief/DEFERRED.md` — `docs/brief/brief_backlog.md` 로 통합 후 retire.** BR-D-01 · BR-D-03 은 한 줄 + reopen 조건으로 이주(기존 ID 보존, header `next ID:` 는 단조 증가 규칙으로 Spec 에서 확정). **retired BR-D-02 는 row 를 만들지 않는다**(closed item = 행 삭제 원칙); tombstone 은 reference sweep 의 bare-token 판정이 "live inbound 참조가 남고 직접 결정 문장으로 재서술 불가"를 확인할 때만 — 재량 판단이 아니다. DEFERRED 가 함께 담고 있는 금지 목록(daemon/watcher/scheduler/state-machine 파일/automatic decision-maker)은 deferred 가 아니라 durable boundary 이므로 spec 으로 간다.
- **routing.** `docs/current/REPO_READING_GUIDE.md` 의 brief 항목(Q4)은 `docs/README.md` 로 이관·제거(과도기 규칙: 새 orientation 은 README 만; 가이드 자체의 retire 는 batch P 소관이라 다루지 않는다). `docs/README.md` 는 closeout Level-1 gate 에서 혼합 상태 반영을 검사·보고한다.
- **inbound pointer.** 구계열 문서 retire 로 깨지는 `BRIEF_CONTRACT.md` / `docs/systems/brief/*` 경로 참조는 **pointer 수준으로만** 갱신한다(소유 도메인 문서의 의미 재진술 정리는 그 도메인 batch 소관). legacy 3문서(`GLOBAL_INSTALL_UPDATE_MODEL.md` · `POST_MVP_PLAN.md` · `GLOBAL_ADOPTION_DECISION.md`)는 Work Packet 분류 입력과 pointer 갱신 대상으로만 취급하고 형틀·문안의 모범으로 삼지 않는다.
- **stale 1건(결정 — batch B 내 처리).** `GLOBAL_INSTALL_UPDATE_MODEL.md` §9.3 의 stale 문장(존재하지 않는 `brief-init.ps1` refuse guard 를 현재형으로 기술; 같은 절 후반부가 이미 자기-정정)은 그 문장이 `BRIEF_CONTRACT.md` 경로를 인용하는 inbound 참조라서 retire 시 pointer sweep 의 필수 갱신 대상에 이미 포함된다 — 그 갱신에서 meaning-preserving 으로 함께 정정한다(batch I 인계 불채택). 문안이 의미 변화로 의심되면 비례성 abuse-guard 에 따라 lifecycle 로 에스컬레이션한다. 이 건은 "docs-stale vs behavior-change 판별 절차"(구현이 기준, docs 측 정정만)의 첫 적용 사례로 기록한다.
- **Work Packet(결정 — 필요; Plan 이 선언).** 목적 = cross-domain line-level 분류(brief 의미가 외부 문서에 재진술된 지점의 지도; 옛 lineage 지도의 재검증 포함) + BRIEF_CONTRACT 절→spec 문장 대응표 + ledger 행별 처분 대조. 위치 `docs/brief/brief_work_packet.md`(committed temporary document — closeout 시 삭제, 보존 = git history). 흡수 대상 = brief_spec 의 cross-domain interface 절(지속 경계만) + closeout report. retire = B closeout 시 삭제. **승격 금지 조건**: Work Packet 의 어떤 내용도 live 문서로 복사·승격되지 않는다 — 지속 결정만 spec 의 normative 문장으로 재서술되어 들어간다.

## 하지 않을 것 (non-goals)

- brief scripts / skill / template / tests 의 behavior 변경. 판별 절차상 docs-stale 이면 docs 측 정정만 한다(구현이 판정 기준).
- `INSTALL.md` 변경(불가침; brief 언급은 intentional contextual duplication — interface 로 존중). `snippets/**` 글로벌 배포 티어 변경.
- 비-brief 소유 문서의 brief 재진술 일괄 청소(cross-domain 참조 표면 전체 정리) — pointer 갱신 수준을 넘는 정리는 소유 batch(R/I/S/P) 소관.
- `handoff/snapshot` 도메인 부활(glossary rejected 유지 — wording 4건의 재검증과 별개). BF Level 3 구현 착수. 무요청 session-start restore-offer 의 부활.
- `docs/current/REPO_READING_GUIDE.md` 자체의 retire(batch P 소관) · 새 routing 내용의 README 외 추가.
- glossary 본문 mutation 은 이 batch 의 결정 사항이 아닌 별도 결정 영역이다(아래 open decision 의 close 시 함께 결정).

## Plan readiness / open risks

**Plan readiness: 내려갈 수 있다.** 구조물별 처분·owner 경계·Work Packet 필요성이 결정으로 닫혔다. Plan 은 batch scope / hard boundary / validation expectation / review focus / Work Packet 선언과 아래 open 의 close 지점을 확정한다.

**Open decisions (close 예정지 포함):**

1. **terminology 4건 재검증 채택**(`checkpoint` / `restore point` / `continuation` / `handoff`) — 옛 disposition(accept / defer / reject / reject-as-canonical)은 폐기 lineage 산출물이므로 권위를 이월하지 않고 재판정한다. 재검증 기준 = 현행 active surface 의 실사용(SKILL.md trigger 문안 · templates · scripts 출력)과 glossary 단일-상태 규칙. 판정과 채택은 사용자 결정 — close: Plan 승인 시 방향 확정, Spec 에 반영(glossary mutation 은 별도 결정).
2. **BRIEF_CONTRACT 절→spec 문장의 line-level 대응** — close: Work Packet 작성 후 Spec 에서(여기서 누락·중복 0 을 대조).
3. **BR-D-02 tombstone 필요 여부** — close: closeout reference sweep 의 bare-token 판정(기계 판정).
4. **`docs/README.md` 혼합 상태 문안** — close: closeout Level-1 gate 에서.
5. **(상시 조건) pilot 모델-결함 신호** — brief_spec 이 회차성 내용을 요구하기 시작하면 batch 중단 → 외부 Design rewind. close 지점 없음(상시 감시).

**Open risks:** ① contract 의 required/forbidden 목록 형식이 이 repo 의 로컬 모범이라 spec 으로 형식째 복제하려는 인력이 있다 — Spec 의 review focus 가 이를 검증한다("목표 상태 명세인가"). ② durable boundary(항구 금지 경계, 정당)와 작업통제(회차성, 결함)의 혼동 — 판별식 "이번 회차가 끝나도 참인가"를 적용한다. ③ 비례성 출구(meaning-preserving 직접 수정)의 사용 횟수는 closeout 보고에 한 줄로 센다.
