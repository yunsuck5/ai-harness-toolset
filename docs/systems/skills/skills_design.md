# skills Design

> 사용법 주: 이 Design 은 skills 서브시스템 docs 의 **owner 흡수 + retire** 방향 문서다 — 영구 live 아님: closeout 시 current-bearing 내용이 올바른 owner surface 로 흡수됨이 확인된 뒤 retire(삭제). 이 Design 은 mutation/commit/push 승인이 아니다(1회 진술).

## Header

이 문서는 `docs/systems/skills/` 의 두 legacy 문서(STATUS.md · FUNCTION_LEVEL_SKILL_ARCHITECTURE_PLAN.md)를 **새 도메인 spec 을 만들지 않고 owner 흡수 + retire** 하는 변경의 Design 이다.
이 체인이 끝나면 두 문서는 retire 되어 git history 가 보존하고, skills 서브시스템 상태는 active surface + review_backlog 한 줄로 on-demand 답변되며, 그 외 active behavior 는 불변이다.
이 문서가 아닌 것: 새 skills/instruction-surface spec 이 아니고, instruction-surface concern(`docs/architecture/instruction-surface/**`) 전체 migration 이 아니며(그것은 Batch P 소관), active surface 변경 결정이 아니다.

## 왜 바꾸는가 / 무엇을 바꾸는가

`docs/systems/skills/` 의 두 문서는 docs-working-model 의 end-state 와 충돌하는 retirement-bound 구조물이다:

- **STATUS.md** 는 per-subsystem **status board** 다. docs-working-model 의 *on-demand status-briefing model* 은 committed status mirror 자체를 제거한다(상태는 active surface + backlog 에서 on-demand 합성). SK-00~SK-06 ledger 는 전부 closed(구현 완료)이고 잔여 risk 는 없으며, 유일한 forward 항목은 **Batch 4**(review-polishing selective-capture vehicle 결정 — instruction vs skill, non-hook) 하나뿐이다.
- **FUNCTION_LEVEL_SKILL_ARCHITECTURE_PLAN.md** 는 자기 선언상 "design-stage planning source. NOT an implementation-approval document" — Design/Plan class 산출물이다. Batch 0~3 은 landing 됐고 Batch 4 만 deferred 다. lifecycle 상 Plan 은 current-bearing 내용이 owner surface 로 흡수된 뒤 retire(삭제)된다.

변경의 큰 그림: 두 문서를 retire 하되, 그 안의 current-bearing 불변식이 **이미 owner surface 에 실재함을 1:1 로 증명**(누락 0)하고, 유일한 live forward 항목(Batch 4)만 backlog 한 줄로 이관한다. 정확한 reconcile 경계는 Plan/Work Packet 의 일이다.

## Owner surface model

이 변경 후 skills 서브시스템의 의미를 소유하는 곳(root *Final hard rule*: behavior 의 authority 는 active surface 이고 docs 는 기록일 뿐):

- **snippet↔skill 책임 분담** — 실제 배포 표면이 소유한다: `snippets/CLAUDE_SNIPPET.md`·`snippets/AGENTS_SNIPPET.md`(2-H2 always-loaded bootstrap), 두 function-level skill(`snippets/claude-skills/ai-harness-review`·`ai-harness-brief`), two-tier rules(`snippets/rules/*` + repo `rules/*`). 이 표면들이 "무엇이 always-loaded 이고 무엇이 on-demand skill 인가"를 **embody** 한다 — 별도 docs 진술 없이 행동으로 성립한다.
- **skill discovery / 무-routing-pointer 불변** — 각 skill 의 `description`(Claude Code 가 description 으로 매칭) + snippet 이 skill index/routing 을 담지 않는다는 사실 자체가 active 표면의 상태로 성립한다.
- **adoption(skill 이 runtime 목적지에 force-mirror + final-verify)** — install-update 도메인이 소유: `INSTALL.md` + `scripts/lib/activation-surface.ps1` + 관련 lifecycle scripts/tests(install-update_spec 의 activation surface 정책).
- **유일한 forward 결정(Batch 4)** — `docs/review/review_backlog.md` 의 한 줄(reopen 조건 포함)이 소유한다. review-polishing selective-capture 는 review 워크플로우 인접 capability 이므로 cross-domain 위반이 아니다.
- **설계 rationale / 이력(SK ledger·설계 서사·snippet 8→2 H2 축약 history)** — git history 가 소유한다(별도 archive 트리 없음). `docs/architecture/instruction-surface/**`(코렉티브 문서 포함)는 이 rationale 의 현 거처이나 **load-bearing authority 가 아니라 design-stage 기록**이며, 그 전체 처분은 Batch P 소관이다.

rules 는 이 변경에서 어떤 behavior 도 흡수하지 않는다 — 새 rule 을 만들지 않으며, docs-working-model rule 의 lifecycle/closeout/end-state 규율을 적용할 뿐이다.

## 수정 대상

- **retire(삭제)**: `docs/systems/skills/STATUS.md`, `docs/systems/skills/FUNCTION_LEVEL_SKILL_ARCHITECTURE_PLAN.md`.
- **갱신**: `docs/review/review_backlog.md`(Batch 4 한 줄 추가) + **삭제 두 파일을 가리키는 모든 inbound 참조의 pointer-only reconcile**(삭제 파일에 대한 dangling 참조 0 — closeout gate "inbound references updated/removed" 충족). 두 부류:
  - **active orientation/routing/instruction 표면** — repo-root `README.md`(Documentation map·snippet alignment 의 SK 인용) · root `CLAUDE.md`/`AGENTS.md`(Docs trigger map Snippet 행, mirror-edit) · `docs/README.md`(docs/systems 행) · `docs/architecture/README.md`(docs/systems 대비 orientation) · `docs/current/REPO_READING_GUIDE.md`(Q10 routing) · `docs/contracts/README.md` · `docs/roadmap/INDEX.md` · `docs/decisions/POST_MVP_PLAN.md`. (이 열거는 **예시**이며 binding scope 는 위의 "모든 inbound 참조" 다 — 정확한 전수 집합은 Work Packet 분류표 + Stage 4 전수 sweep 이 특정한다.)
  - **`docs/architecture/instruction-surface/**` 내부 참조**(9파일에 걸친 다수 참조 — "약 22" 는 고정 작업목록이 아닌 **범위 신호**이며 정확 수치/행은 Work Packet 분류표가 특정) — 삭제 파일을 가리키지 않도록 git-history/사실-직접-진술로 repoint 한다(**pointer-only reconcile 이며 그 문서군의 전체 처분/retire 가 아니다** — disposition 은 P).

## 하지 않을 것 (non-goals)

- 새 skills 도메인 spec / instruction-surface spec 생성 — 하지 않는다(흡수 + retire 가 판정).
- `docs/architecture/instruction-surface/**` 의 **전체 disposition**(본문 migration·architecture narrative 재작성·그 문서군의 retire/재구조화) — 하지 않는다(Batch P 소관·선점 금지). **단** 삭제 두 파일을 가리키는 **dangling pointer 의 pointer-only reconcile** 은 S 가 수행한다(closeout gate 충족) — 허용 범위는 ① deleted docs 를 live path 처럼 가리키는 참조 제거/retarget ② git-history/former-path/then-path 주석화 ③ current owner 가 명확할 때만 active owner 로 retarget 까지이며, 본문 migration·narrative 재작성·P 처분 선점은 금지다.
- active surface 변경(snippet·skills·`snippets/rules/`·`INSTALL.md`·scripts·tests·payload/manifest) — 하지 않는다. LTS·배포 표면 불변.
- `docs/contracts/` 등 다른 빈 계층 처분 — 하지 않는다(Batch P).
- rejected umbrella(evidence/global-invocation/instruction-surface 의 독립 도메인화)·superseded mechanism 부활 — 하지 않는다.
- S 를 instruction-surface concern 전체 migration 으로 rescope — 하지 않는다. orphan-reference 우려는 rescope 가 아니라 구현 단계 guard 로 통제한다.

## Plan readiness / open risks

이 Design 은 Plan 으로 내려가도 된다 — 판정(흡수 + retire)이 사용자 승인으로 닫혔고 scope 가 두 파일 retire + 삭제 파일을 가리키는 모든 inbound 참조의 pointer-only reconcile 로 한정됐다(instruction-surface disposition 은 P). 남은 open risk(각각 닫히는 곳):

- **흡수 증명의 완전성** — 두 문서의 current-bearing 불변식이 빠짐없이 owner surface 에 실재하는지의 1:1 증명. 특히 *function-level granularity*(micro/mega 금지) 같은 **future-skill 설계 지침**이 active surface 에 명시적으로 필요한지, 아니면 git history(+ 새 skill 추가가 그 자체로 scoped 결정이라는 사실)로 충분한지의 판정. → **Work Packet 의 흡수 증명**에서 닫는다.
- **dangling-reference 통제** — 두 문서로 향하는 모든 inbound 참조(active 표면 + instruction-surface/** 내부 약 22건)를 삭제 후 dangling 이 아니도록 pointer-only reconcile 한다(closeout gate "inbound references updated/removed" 충족). instruction-surface/** 의 disposition 자체는 P 다 — S 는 pointer 만 만진다. → **Work Packet 분류표**(참조별 reconcile 방식: 제거/git-history 주석/active-owner retarget)**와 Stage 4 구현 guard + 전수 재sweep**에서 닫는다.
- **Batch 4 의 backlog 분류** — review_backlog 의 어느 class(open vs idea-only)·어느 ID 인지. → **Work Packet** 에서 review_backlog 실제 구조 확인 후 닫는다.
