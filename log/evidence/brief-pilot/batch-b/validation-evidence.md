# batch B implementation round — validation evidence

- date: 2026-06-12 / baseline: local HEAD `6c3fa6b` (origin/main `e97bf3a`, ahead 1) / working tree: implementation mutations applied, uncommitted

## 1. 변경 집합

- **create**: `docs/brief/brief_backlog.md` (BR-D-01·BR-D-03 이주, header `next ID: BR-D-04`)
- **delete**: `docs/contracts/brief/BRIEF_CONTRACT.md` · `docs/systems/brief/STATUS.md` · `docs/systems/brief/DEFERRED.md` (빈 물리 폴더 2개 제거; 상위 `docs/contracts/`·`docs/systems/` 계층은 미접촉 — batch P 소관)
- **modify**: orientation 6 (root `README.md`, `docs/README.md`, `docs/current/REPO_READING_GUIDE.md` Q4 이관·제거, `docs/contracts/README.md`, `docs/backlog/INDEX.md`, `docs/roadmap/INDEX.md`) + pointer sweep 16 (`GLOBAL_INSTALL_UPDATE_MODEL`[stale 1건 포함], `POST_MVP_PLAN`, `GLOBAL_ADOPTION_DECISION`, `SHARED_GLOBAL_INVOCATION_CONTRACT`, `REVIEW_EFFORT_GUIDE`, `FUNCTION_LEVEL_SKILL_ARCHITECTURE_PLAN`, `skills/STATUS`, `DECISIONS`, `STEP3_…GUIDE`, `install-update/STATUS`, `GSF_B1`, `GSF_B2`, `GSHMC`, `RELOCATION_AUDIT`, `INSTRUCTION_SURFACE_PLAN`, `REPO_LOCAL_INSTRUCTION_SURFACE_PLAN`) + `rules/terminology-glossary.md` (terminology 4건 close) + root `CLAUDE.md`/`AGENTS.md` (Brief trigger map row mirror-edit — 별도 승인 B, `global-file-mutation-boundary.md` 선독)
- git status 합계 31 entries (modified 25 + deleted 3 + untracked/intent-to-add 3)

## 2. 4-class reference sweep (repo tracked 기준 + untracked docs/brief 별도)

- patterns: `contracts/brief` · `systems/brief` · `BRIEF_CONTRACT` · `BR-D-02` (+ 사전 단계에서 `log/work`·`never committed`·`비커밋` 0 유지 확인)
- **class 1 (path)**: 삭제된 3경로의 잔존 = `docs/brief/brief_design.md` 내부 5건뿐 — lifecycle 문서가 처분 **대상을 명명**하는 본문이며 closeout 에서 파일째 retire(수정 금지 boundary). 그 외 tracked 표면 0.
- **class 2 (bare-token)**: `BRIEF_CONTRACT`·`brief DEFERRED` 잔존은 전부 ① docs/brief lifecycle 3문서(closeout 삭제 예정) ② "당시/구 … (현 `docs/brief/brief_spec.md` / `brief_backlog.md`)" 주석이 붙은 과거형 batch 기록(GSF_B2·GSHMC·RELOCATION_AUDIT·FLSAP·skills/STATUS·GSF_B1) — 현행 권위로 오인 불가, dangling 아님.
- **class 3 (folder-as-bucket)**: "brief 폴더" 류 bucket 표현 — `docs/contracts/README.md` 행 제거, `docs/README.md` contracts 행에서 `brief/` 제거 + `docs/brief/` 도메인 행 신설로 해소.
- **class 4 (semantic)**: "Brief 의 source-of-truth/계약/owner" 류 의미 표현 전수 재독 — 현재형 진술은 전부 `docs/brief/brief_spec.md`(+backlog)로 swap, 과거형 기록은 당시-주석. BF Level 의미 재진술(GAD §2, PMP §3/§5 본문 등)은 내용상 현행과 정합 — 소유 batch 전까지 존치(존속하되 확장 금지).
- **BR-D-02 tombstone 기계 판정**: 잔존 인용은 전부 (a) lifecycle 문서의 설계 서술 (b) 폐기 결정을 문장 자체가 진술하는 과거형 기록 — "live inbound 참조가 남고 직접 결정 문장으로 재서술 불가"인 건 **0** → **tombstone 불요 확정**. live 문서들의 BR-D-02 인용은 전부 직접 결정 문장("무요청 session-start restore-offer automation 은 폐기됨")으로 재서술됨.
- deletion granular technique: case-insensitive 검색, `브리프 계약` 류 한글 변형·`§"BF Level"` bare-section 인용 확인(POST_MVP_PLAN·GAD 의 §-인용 2건 해소).

## 3. Pester

- brief 3 suites + `repo-local-instruction-parity.Tests.ps1`: **23/23 PASS** (parity = mirror-edit 검증)
- 전체 `Invoke-Pester -Path .\tests`: **542/542 PASS** (Failed 0, Skipped 0; 25 파일, 250.2s)

## 4. 기타 검증

- `git diff --check` (신규 3파일 intent-to-add 포함): **clean**
- 변경·신규 `.md` 31개 인코딩 전수: **UTF-8 no BOM + LF (BOM 0, CR 0)**
- stale 1건 정정: GIUM §9.3 의 해당 문장을 현행 사실(guard 부재·정합화 완료·비승인 진술 유지)로 재서술 — pointer/false-current wording 수준, install-update 의미·`INSTALL.md` 접촉 0 (meaning-preserving 선언)
- 비례성 출구(meaning-preserving 직접 수정, lifecycle 생략) 사용 횟수: batch B 누적 **0** (모든 변경이 lifecycle/승인 경로 안에서 수행됨)

## 4a. pass-01 corrective (정정 기록)

- **정정**: 본 문서 §2 의 "그 외 tracked 표면 0" 주장은 **부정확했다** — 최초 sweep 의 git grep 이 `*.md` 로 한정되어 `.ps1` 테스트 fixture 를 누락했다. pass-01 review 가 `tests/brief-check.Tests.ps1` 6곳 + `tests/brief-status.Tests.ps1` 3곳의 sample Brief fixture 문자열(`Files to inspect first` 예시 값)에 남은 구 contract 경로를 발견했다.
- **corrective 적용(사용자 승인; tests 는 별도 승인 — fixture 문자열 한정, assertion/behavior/structure 무변경, `scripts/brief-*.ps1` 무접촉)**: ① fixture 9곳 경로를 `docs/brief/brief_spec.md` 로 교체 ② `brief_backlog.md` 의 blockquote 안내줄 제거(No-narrative 정합) ③ FLSAP L163 현재형 잔존에 당시-주석 부여.
- **sweep 범위 정정**: 이후 sweep 은 `*.md` 한정 없이 **tracked 전체(.ps1 fixture 포함)** 를 검색한다. corrected-state 재검 결과는 아래 §4b.

## 4b. corrected-state 재검 (corrective 적용 후)

- 삭제 경로(`contracts/brief`/`systems/brief`) tracked 전체 잔존: `docs/brief/brief_design.md` 내부 5건(lifecycle 문서, closeout 시 파일째 retire)뿐 — **.ps1 포함 그 외 0**.
- `BRIEF_CONTRACT`/`BR-D-02` bare-token: lifecycle 문서 + 당시-주석 과거 기록뿐(§2 분류 유지; FLSAP L163 도 당시-주석으로 정합).
- Pester: corrective 적용 후 **전체 suite 재실행 542/542 PASS**(brief 3 suites + repo-local parity 포함; Failed 0). `scripts/verify-ps1.ps1` **PASS (28 files)** — 수정된 test .ps1 의 BOM+CRLF 유지 확인.
- `git diff --check` clean · `brief_backlog.md` 인코딩 PASS(no BOM, no CR).
- corrected-state sweep(tracked 전체, 확장자 무제한): 삭제 경로 잔존 = `brief_design.md`(5건) + `brief_work_packet.md`(분석 본문 — intent-to-add 로 grep 에 포착) — 둘 다 lifecycle 문서로 closeout 시 파일째 retire. **테스트 fixture 포함 그 외 0.**

## 5. spec ↔ implementation 1:1 (사전 확인; closeout 에서 재검증)

- behavior 표면(scripts 3종·template·skill·tests)은 이번 라운드 무변경 — spec 의 normative 문장과의 1:1 은 spec review (pass-01 dual) 에서 구현 대조로 확인된 상태 유지. 문서 수렴 구현이 본 라운드로 완료되어 spec lifecycle state 의 sync-required 해소 요건이 갖춰짐(state flip 은 closeout 에서).
