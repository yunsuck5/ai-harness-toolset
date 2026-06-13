# skills Plan

> 사용법 주: 이 Plan 은 batch S(skills 서브시스템 docs 의 owner 흡수 + retire)의 **승인 대상 의사결정**만 담는다 — 조사/line 분류/inbound 참조 분류는 Work Packet, 실행 명령·staging·실행 기록은 operator report(`log/**`) 소관. Plan 이 Design 을 위반하면 stop → Design 재설계(rewind). 영구 live 아님 — closeout 시 흡수 후 retire(삭제). 이 Plan 은 mutation/commit/push 승인이 아니다(1회 진술).

## Header

이 문서는 batch S — `docs/systems/skills/` 두 legacy 문서(STATUS.md · FUNCTION_LEVEL_SKILL_ARCHITECTURE_PLAN.md)의 owner 흡수 + retire — 의 Plan 이다.
이 체인이 끝나면 두 문서는 retire 되고, skills 서브시스템 상태는 active surface + `review_backlog.md` 한 줄로 on-demand 답변되며, 삭제 파일을 가리키는 모든 inbound 참조는 pointer-only reconcile 되어(dangling 0) active surface 는 불변이다.
이 문서가 아닌 것: 새 skills/instruction-surface spec 이 아니고, `docs/architecture/instruction-surface/**` 전체 처분(Batch P)이 아니며, active surface 변경 결정이 아니다.

## Batch 순서와 의존

batch S 는 단일 batch 이며 내부 단계 순서는 **Design → Plan → Work Packet → Implementation → Closeout** 다(Spec 단계 없음 — 흡수+retire 판정의 귀결). 의존: WP 의 흡수 증명·참조 분류가 Implementation 의 삭제·reconcile 의 전제이고, Implementation 의 corrected tree 가 Closeout 의 전제다.

커밋은 **3-commit 체인**으로 닫는다(순서 = 위 단계 의존):
1. **앵커** — Design + Plan + Work Packet(리뷰 통과한 lifecycle 문서).
2. **implementation** — legacy 2파일 삭제 + `review_backlog.md` Batch 4 행 + 삭제 파일을 가리키는 모든 inbound 참조 pointer-only reconcile(active 표면 + instruction-surface/** 내부).
3. **closeout** — lifecycle 문서 3종 retire(삭제) + orientation 재검증.

각 커밋 지점은 정지 게이트다 — staging 전 정지·내용 보고·명시 승인 후에만 staging(+ index-민감 재검사)·commit·push. 이 Plan 은 그 커밋들을 승인하지 않는다.

## Batch 정의

**batch S — skills 서브시스템 docs owner 흡수 + retire**

- **목적**: docs-working-model 의 on-demand status-briefing·lifecycle 규율에 따라 retirement-bound 인 skills 서브시스템 docs 2종을 흡수+retire 한다.
- **scope (다루는 것)**: ① 두 문서 retire ② current-bearing 불변식의 surviving-owner 1:1 증명(새 문서 미생성) ③ 유일한 forward 항목 Batch 4 의 `review_backlog.md` 이관 ④ **삭제 두 파일을 가리키는 모든 inbound 참조의 pointer-only reconcile** — active orientation/routing/instruction 표면 + `docs/architecture/instruction-surface/**` 내부(약 22 occurrence/9파일) 모두 dangling 0 으로(closeout gate 충족).
- **scope (다루지 않는 것)**: 새 spec 생성 · `docs/architecture/instruction-surface/**` 의 **전체 disposition**(본문 migration·architecture narrative 재작성·그 문서군 retire/재구조화 — Batch P 소관·선점 금지) · active surface(snippet·skills·`snippets/rules/`·`INSTALL.md`·scripts·tests·payload/manifest) 변경 · `docs/contracts/` 등 다른 빈 계층 처분(Batch P) · S 의 instruction-surface concern 전체 migration 으로의 rescope. **참조 reconcile 과 disposition 의 구별**: S 는 instruction-surface/** 안에서 삭제 파일을 가리키는 **pointer 만** reconcile 하고, 그 문서들의 본문·narrative·존속 여부는 건드리지 않는다.
- **hard boundary (불가침)**:
  - 자동 commit/push 금지. `.gitignore`·`snippets/**`·`INSTALL.md` 본문·scripts behavior(LTS)·payload/manifest 불변.
  - root `CLAUDE.md`/`AGENTS.md` 는 **project-root instruction-surface mutation 경계** — 두 파일 shared body 를 **mirror-edit(대칭)** 하고, 이 표면 변경은 별도 명시 승인 영역이며 `tests/repo-local-instruction-parity.Tests.ps1` 로 검증한다(단순 docs-only 로 취급 금지).
  - superseded mechanism·rejected umbrella(evidence/global-invocation/instruction-surface 의 독립 도메인화) 부활 금지. retirement-bound 구조물에 새 narrative 추가 금지.
  - **dangling-reference 통제 (closeout gate)**: 삭제로 dangling 되는 **모든** inbound 참조를 변형-enumeration sweep 으로 전수 식별 → **전부 S 에서 pointer-only reconcile**(active 표면 + instruction-surface/** 내부 약 22건). 허용 = ① deleted docs 를 live path 처럼 가리키는 참조 제거/retarget ② git-history/former-path/then-path 주석화 ③ current owner 가 명확할 때만 active owner 로 retarget. 금지 = instruction-surface 본문 migration · architecture narrative 재작성 · 새 spec · Batch P 소관 disposition 선점 · active surface 변경. 결과: 삭제 두 파일을 가리키는 dangling 참조가 **어느 표면에도 0**.
  - durable-pointer 금지: 이 lifecycle 문서는 `log/**`·Brief 등 gitignored/local 경로를 durable 참조하지 않는다.
- **validation expectation**: 각 단계 dual Codex 리뷰(local-correctness + system-coherence) dual `yes`; implementation 후 변형-enumeration 재sweep 으로 삭제 두 파일을 가리키는 dangling 참조가 **어느 표면(active + instruction-surface/**)에도 0**; 새/수정 `.md` = UTF-8 no BOM + LF; `tests/repo-local-instruction-parity.Tests.ps1` PASS; closeout 의 reduced two-level gate — Level 1 은 `docs/README.md` 및 **영향받은 모든 legacy orientation surface**(REPO_READING_GUIDE·roadmap/INDEX·architecture/README·contracts/README·POST_MVP_PLAN 등)에 대해 `updated:`/`checked:` 보고, Level 2 는 domain spec 없음(Option B)이므로 `review_backlog.md` Batch 4 행 검증.
- **review focus**: 흡수 증명의 완전성(누락 0) · scope 경계 준수(active surface·instruction-surface 처분 불가침) · single-home-plus-pointers(새 중복 home 0) · cross-domain semantics(Batch 4 이관) · orphan-guard 의 실효.
- **Work Packet 필요**: 필요. **(목적)** 삭제 두 파일로 향하는 모든 inbound 참조의 **reconcile-방식별 분류표**(참조별로: 제거 / git-history·then-path 주석화 / active-owner retarget 중 무엇인지 — active 표면 + instruction-surface/** 약 22건) + 두 문서 current-bearing 불변식의 surviving-owner 1:1 흡수 증명 + Batch 4 backlog 행 초안. **(흡수 대상)** 분류·증명의 current-bearing 결론은 Implementation 의 편집과 Closeout report 로 흡수. **(retire 조건)** closeout 에서 흡수 완료 + dangling 0 확인 후 삭제(보존 = git history).

## Open decision 의 close 지점

상위 Design 의 open risk 배정:

- **흡수 증명의 완전성**(function-level granularity 류 future-skill 지침의 거처가 active surface 인지 git history 로 충분한지) → **Work Packet 흡수 증명**에서 닫는다.
- **dangling-reference 통제·분류**(참조별 reconcile 방식) → **Work Packet 분류표**에서 분류, **Implementation guard** 에서 적용, **Closeout** 에서 전수 재sweep 으로 dangling 0 확인.
- **Batch 4 backlog 분류**(class·ID) → **Work Packet** 에서 `review_backlog.md` 실제 구조 확인 후 결정(현 next ID: RV-B-13).

이 Plan 이 자체로 닫는 결정: 커밋 체인(3-commit), Batch 4 의 home(`review_backlog.md`), 참조 reconcile 의 경계(삭제 파일을 가리키는 모든 dangling pointer 는 S 에서 pointer-only reconcile / instruction-surface 문서 **disposition** 만 P), root instruction 표면의 mirror-edit + 별도 승인 처리.

## Stage rewind 조건

- 이 **Plan 이 Design 위반**(예: 흡수+retire 가 아닌 spec 생성으로 흐름) → stop, Design 재설계 후 Plan 재시작.
- 하위 단계가 이 Plan 위반(예: WP 흡수 증명이 active surface 에 없는 불변식 — 즉 retire 시 의미 소실 — 을 발견) → stop, rewind 보고(batch 안에서 scope 를 임의 확장하지 않는다; 새 owner surface 가 필요하면 별도 scoped 결정).
- Implementation 이 scope boundary 초과(active surface·instruction-surface 처분으로 번짐) → stop 후 사용자에게 질의, 절대 silent 확장 금지.
