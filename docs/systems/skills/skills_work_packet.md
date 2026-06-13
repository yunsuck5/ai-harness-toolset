# skills Work Packet

> 사용법 주: 이 Work Packet 은 batch S 의 **round-scoped 임시 작업 문서**다 — 참조 분류·흡수 증명·backlog 행 초안을 담는다. approval target 도 live 도메인 문서도 아니고 Spec 대체도 아니다. 실행 명령·staging·review/validation 결과·readiness 판정은 담지 않는다(operator report `log/**` 소관). closeout 에서 current-bearing 결론이 Implementation/Closeout report 로 흡수된 뒤 **삭제**(보존 = git history). mutation/commit/push 승인이 아니다.

분류·수치는 **as-measured 조사값**이며, dangling 0 의 authoritative 판정은 Stage 4 의 변형-enumeration 전수 sweep(case-insensitive · `docs/systems/skills` · `FUNCTION_LEVEL_SKILL` · `SK-0[0-9]` · bare `STATUS.md SK-` · 약칭/공백 변형)과 그 재sweep 이다.

## §1. Inbound 참조 분류표 (reconcile-방식별)

삭제 대상: `docs/systems/skills/STATUS.md` · `docs/systems/skills/FUNCTION_LEVEL_SKILL_ARCHITECTURE_PLAN.md`. 두 파일을 가리키는 모든 inbound 참조를 **pointer-only reconcile** 한다(dangling 0). 방식: **M1** = deleted docs 를 live path 처럼 가리키는 참조 제거 또는 current owner 가 명확할 때 active owner 로 retarget · **M2** = git-history/former-path/then-path 주석화·사실 직접 진술. 참조 성격 3종: (a) authority/routing 포인터, (b) SK-NN status/provenance 인용, (c) closeout-report 역사 기록("checked: … no change / intentionally not edited").

### A. Active orientation/routing/instruction 표면 (S 가 reconcile)

| 파일 | 대표 위치 | 성격 | 방식 |
|---|---|---|---|
| repo-root `README.md` | :87(## Brief 제거 provenance, SK-05) · :126("remaining per-system board … STATUS.md") | b · 상태판 포인터 | :87 → M2(사실 직접: ## Brief 제거는 brief spec + 활성 Brief 표면 소유, 이력 git history) · :126 → M1(상태판 절 제거 — 상태는 per-domain spec/backlog + on-demand) |
| root `CLAUDE.md` + `AGENTS.md` (**mirror-edit**) | :23(Docs trigger map Snippet 행 — FUNCTION_LEVEL+STATUS migration-history 포인터) · :55(Non-goals, SK-03 인용) | a · b | :23 → M1/M2(두 skills-doc 포인터 제거; 잔존 corrective-doc 포인터는 P-bound 이나 삭제 대상 아님이라 유지) · :55 → M2(사실 직접/git-history) |
| `docs/README.md` | :65(§8 "remaining per-system board … STATUS.md") | 상태판 포인터 | M1(절 제거) |
| `docs/contracts/README.md` | :16("current system status → … or skills/STATUS.md") | 상태판 포인터 | M1(skills/STATUS.md fallback 제거) |
| `docs/architecture/README.md` | :11(instruction-surface 행 SK-04/06 인용 + "how this differs from docs/systems … now skills/ only") | a · b · orientation | M1(docs/systems "skills/ only" → 부재 반영) + M2(SK 인용 → git-history). 이 파일은 instruction-surface/ **밖**의 layer orientation 이므로 S 가 정합화 |
| `docs/roadmap/INDEX.md` | :15 · :41("remaining per-system board … STATUS.md") | 상태판 포인터 | M1(절 제거) |
| `docs/decisions/POST_MVP_PLAN.md` | :66(SK-05 provenance) · :146("remaining per-system board") | b · 상태판 | :66 → M2 · :146 → M1 |
| `docs/current/REPO_READING_GUIDE.md` | :13·:51·:76·:95·:96·:97·:105·:106·:107(Q10 routing 의 FUNCTION_LEVEL+STATUS secondary + "remaining per-system board") | a · 상태판 | M1(상태판 절 제거) + Q10 의 skills-doc 포인터 → M2(git-history) 또는 제거. **legacy routing residue 규율**: 기존 routing 의 stale 포인터 정리는 허용(신규 routing 추가 금지). |

### B. `docs/architecture/instruction-surface/**` 내부 (S 가 pointer-only reconcile — disposition 은 P)

9파일·다수 occurrence(as-measured 약 24; Stage 4 가 정확 특정). **disposition(본문 migration·narrative 재작성·문서 retire)은 P** — S 는 삭제 파일을 가리키는 pointer 만 만진다.

> **이 표의 per-file occurrence 는 완전 목록이 아니라 하한/준비 분류다** — 일부 파일(예: `GLOBAL_SNIPPET_RELOCATION_AUDIT.md`)은 표기보다 더 많은 언급을 가질 수 있다. dangling 0 의 authoritative 판정은 Stage 4 의 변형-enumeration **전수** sweep + 재sweep 이며, 구현자는 이 표를 완전 목록으로 오해하지 말 것.

| 파일 | 성격 | 방식 |
|---|---|---|
| `INSTRUCTION_SURFACE_PLAN.md`(:13 "split+batch order → FUNCTION_LEVEL §8 + STATUS" authority 위임, :176 표, :207/:210/:269/:271/:286 SK 인용) | a + b | a → M2/retarget(authority 는 active surface; 이력 git-history) · b → M2(git-history) |
| `REPO_LOCAL_INSTRUCTION_SURFACE_PLAN.md`(:82 Snippet 행 포인터, :100 FUNCTION_LEVEL §4 wording, :104 SK-03) | a + b | M2(git-history)/retarget |
| `GLOBAL_SNIPPET_RELOCATION_AUDIT.md`(SK 인용 2건) | b | M2 |
| `GLOBAL_SNIPPET_HARD_MINIMIZATION_CORRECTIVE.md`(:96 stale-corrected 목록에 STATUS SK-06 + FUNCTION_LEVEL §4) | b | M2(git-history) |
| `GLOBAL_SNIPPET_FIRST_MIGRATION_DESIGN.md`(:84 Q10 authority 표, :299/:300 closeout "checked/not edited") | a + c | a → M2/retarget · c → M2(then-path 주석) |
| `GLOBAL_SNIPPET_FIRST_MIGRATION_PLAN.md`(:23/:24 SK-05, :127/:128 closeout "checked/not edited") | b + c | M2 |
| `GLOBAL_SNIPPET_FIRST_MIGRATION_SPEC_GSF_B1.md`(:267/:269 closeout "checked/not edited") | c | M2(then-path 주석) |
| `GLOBAL_SNIPPET_FIRST_GSF_B2_CLASSIFICATION.md`(:139/:143/:144/:156 STATUS=current-state owner, :217/:218 closeout) | a + c | a → M2/retarget(현재 상태 owner = per-domain spec/backlog + on-demand; SK ledger 는 git-history) · c → M2 |
| `GLOBAL_SNIPPET_FIRST_GSF_B3_RULES_LOADING_DECISION.md`(:118/:119 closeout "checked/not edited") | c | M2 |

**성격 (c) closeout-report 역사 기록 처리 원칙**: "checked: docs/systems/skills/STATUS.md — no change required" 류는 과거 closeout 의 point-in-time 기록이다. 의미를 재작성하지 않고 **then-path/retired 주석**으로 live-path 함의만 제거한다(예: 경로에 "(batch S 에서 retire; 당시 extant)" 표식). 이는 narrative 재작성이 아니라 pointer reconcile 다.

## §2. 흡수 증명 (current-bearing 불변식 → surviving owner, 1:1 · 누락 0)

| 두 문서의 current-bearing 불변식 | surviving owner(삭제 후에도 존속) |
|---|---|
| snippet↔skill 책임 분담(무엇이 always-loaded vs on-demand skill) | active 배포 표면: `snippets/CLAUDE_SNIPPET.md`/`AGENTS_SNIPPET.md`(2-H2) + 두 skill(`snippets/claude-skills/*`) + two-tier rules — 행동으로 성립 |
| snippet = 2-H2 always-loaded bootstrap shape | 실제 파일 `snippets/CLAUDE_SNIPPET.md`/`AGENTS_SNIPPET.md` |
| two-tier rules architecture(`snippets/rules/` + repo `rules/`) | 실제 디렉터리 |
| no-skill-routing-in-snippet · current-capability-only | snippet 실제 내용(routing pointer 0) + 각 skill 의 `description` |
| docs-free distribution | 실제 배포 트리(`snippets/` 안 `docs/` 0) |
| adoption(skill force-mirror + final-verify) | install-update 도메인: `INSTALL.md` + `scripts/lib/activation-surface.ps1` + install-update_spec activation-surface 정책 |
| **function-level granularity(micro/mega skill 금지)** | **design 원칙 — active 행동 불변이 아님(어느 active 표면도 이 rule 을 강제하지 않음). 현 2 skill 이 원칙을 embody; 새 skill 추가는 그 자체 scoped 결정이라 원칙이 재적용된다. 따라서 별도 active home 불요 — rationale 는 git history 보존.** (Design open risk 의 close: active home 불필요로 판정) |
| SK-00~06 ledger · 설계 서사 · supersession 사실(SK-06 supersedes GSF framing 등) | git history. (`docs/architecture/instruction-surface/**` 는 이 rationale 의 현 거처이나 load-bearing authority 아님 — disposition 은 P) |
| Batch 4(review-polishing selective-capture vehicle 결정, deferred — 유일 forward 항목) | `docs/review/review_backlog.md`(§3 행) |

**결론**: 두 문서를 retire 해도 active 행동/소유 경계에서 소실되는 current-bearing 불변식은 없다. function-level granularity 는 active rule 이 아닌 design 원칙이라 git history 보존으로 충분(별도 owner surface 신설 불요).

## §3. Batch 4 → `review_backlog.md` 행 초안

next ID = RV-B-13 → 추가 후 next ID 를 RV-B-14 로 bump.

```
| RV-B-13 | (deferred 결정) review-polishing selective-capture vehicle 결정 — instruction vs skill (non-hook); "leave as caller-judgment instruction" 결론 가능. retired skills 서브시스템 plan(Batch 4; git history)에서 이관 | review-polishing 개선신호의 selective capture 필요가 구체화 + 사용자 결정 + 별도 scoped goal |
```

cross-domain 점검: review-polishing 은 review 워크플로우 인접 capability(runtime home `log/review_polishing/**`, review-caller judgment)이므로 review 도메인 backlog 가 정합 — 타 도메인 semantics 재진술이 아니라 review 도메인 자체의 future-work 항목이다.

## §4. Stage 4 가 닫는 것(이 WP 의 흡수 대상)

- §1 분류의 실제 line 편집(M1/M2 적용) + 변형-enumeration 전수 sweep + 재sweep 으로 dangling 0 확인 → 결론은 Implementation 편집과 Closeout report 로 흡수.
- §2 흡수 증명 결론 → Closeout report(1:1 reconciliation).
- §3 행 → `review_backlog.md` 에 반영.
- 이 WP 는 closeout 에서 삭제(git history 보존).
