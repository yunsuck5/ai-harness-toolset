# subagent-work-orchestration Incubation (rule candidate — non-authoritative)

## Header

**이 문서는 무엇인가.** `subagent-work-orchestration` **rule candidate** 의 단일·자족 planning home 이다 — docs-working-model 의 *Incubation tier*(pre-promotion candidate stage)에 있는 **rule candidate** 가, branching-agnostic 운영 규율로서 글로벌 배포 rule 로 승격할지 dogfood 로 검증하는 동안 쓰는 유일한 committed-temporary 문서다. **이 문서 하나만 읽고 작업을 시작할 수 있도록 자족적으로 적는다**(별도 seed 문서 불요).

**무엇을 해결하는가(problem).** 도메인/서페이스가 다른 독립 작업을 메인 세션 한 곳에서 직렬 처리하면 (a) 컨텍스트 오염·용량, (b) 작업속도(리뷰가 순수 작업보다 무거움)가 필연적 병목이 된다. 한 선행 실험(서브에이전트 오케스트레이션 파일럿)이 이 오케스트레이션(서브 위임 + perspective별 병렬 codex 리뷰)의 실현가능성·컨텍스트 오프로드·가드 유지를 **n=1**(단일 세션·머신·reviewer, 통제 벤치마크 아님)로 실증했다 — 그 실측이 이 candidate 의 motivating evidence 다. 측정 상세(병렬 단축률·재시도 수 등 수치)는 measurement `log/**` 소관이고, 원 실험 lineage 는 git history / Brief 로 추적한다(committed doc 은 out-of-repo 경로를 durable pointer 로 두지 않는다). 이 candidate 는 그 실험을 **"메인=오케스트레이터/감독, 서브=실행자"** 기본 운영 규율로 정식화할지 검증한다.

**non-authoritative.** canonical authority 없음(form early / authority late). canonical rules/indexes 는 이 문서를 durable reference 하지 않으며(E2), 이 문서를 읽어야만 동작하는 canonical 표면은 없다(E1/E3). 본문 결정은 후보 수준이고, promote 시점엔 `_design` active lifecycle 로 진입하되 정규 authority 는 그 뒤 **terminal rule landing**(`snippets/rules/subagent-work-orchestration.md`)에서 생긴다.

**owner / review-date / discard.**
- **owner** = 사용자.
- **review-date** = orchestration pilot **3회** 누적 후 첫 판정(promote / discard / continue; count=트리거지 자동종료 아님; continue 시 **새 review-date 필수**).
- **discard 기준** = §Measurement 의 실패 기준이 반복 관측될 때(메인이 실제 감독 못 하고 요약만 신뢰 / join 시간이 절감분 잠식 / 단일세션 대비 wall-clock 미감소 / out-of-scope·권한경계 위반 / 작은 작업에도 의례적 overhead).

**promote 시 무엇이 되는가.** promote 되면 이 문서의 current-bearing 내용이 **E4 로 entry 승격 아티팩트(`_design.md`)에 흡수**된다 — promotion transition 은 `_incubation.md` 를 제거하며 `_design.md` 를 쓰는 하나의 atomic swap 이고(그것이 candidate-lifecycle closeout), 이후 **Design → Plan → 글로벌 배포 rule `snippets/rules/subagent-work-orchestration.md`**(branching-agnostic; **별도 Spec 없음** — rule 은 자기 자신이 spec-of-record)로 진행한다. `rule_docs/subagent-work-orchestration/` 폴더는 promote 시 삭제되지 않고 now-existing rule 의 planning home 으로 존속한다(promoted-lifecycle closeout 에서 planning docs 삭제 후 idle `.gitkeep`). **배포 rule 은 universal core 만** 담는다 — branching / Regime-2 / 재귀는 배포 제외(§Regime 2).

**discard 시.** 이 문서와 `rule_docs/subagent-work-orchestration/` 폴더 전체가 흡수 없이 삭제되고(discard 된 candidate 는 rule 이 되지 않으므로 idle 폴더도 남기지 않는다), 폐기 사유(끝낸 negative evidence)는 discard commit message 에 남겨 git history 가 보존한다.

## 목표 상태 (Regime-1 운영 모델)

메인 오퍼레이터 세션 = **오케스트레이터/감독관**. 독립·무거운 작업 단위는 서브에이전트(=실행자)에 위임하고, 각 실행자는 작업 + 가용한 독립 리뷰(이 프로젝트에선 codex review skill 또는 blind)로 **정합성을 갖춰** 반환한다. 메인은 위임 전 기대값 확정 + 의존/분할 판정 + 통합레벨 calibrated 검증 + 사용자 대화 정렬을 한다.

핵심 invariants:
- **orchestration-assessment-first (default)** — "항상 서브" 가 아니라, *기본적으로 먼저 분해·병렬가능성을 평가*하고 단위가 독립+무거울 때 서브를 띄운다. 사소·결합·대화성 턴은 메인 직접.
- **scoped-delegation** — "서브 사용 허가" 가 아니라 *특정 범위 내 위임 허가*: 서브는 커밋/푸시/글로벌/메모리 변경 금지·지정 파일만; out-of-scope 발견은 *수정 말고 보고*; 대화형 요구사항 확인이 필요하면 fork 금지.
- **calibrated trust, not blind** — 서브의 정합성은 *독립 리뷰어*(서브 자신이 아니라 codex 등)가 만든다 → 메인은 *재리뷰(낭비)가 아니라* ① 리뷰가 실제 통과했는지(verdict 아티팩트 확인) ② 서브가 구조적으로 못 보는 cross-unit/통합 정합성을 판정.
- **read-capacity 천장** — 병렬 상한 = fork 능력이 아니라 메인이 한 턴에 *완전히 읽고 교차검증* 가능한 결과 수(보수 cap **2**, 정당화 시 3). 읽을 수 있는 것보다 많이 fork = 감독 착각.
- **JOIN / 의미 독립성** — 함께 리뷰돼야 할(같은 invariant·API·schema·flow·테스트) multi-file 은 쪼개면 거짓 no → *coherence 단위*로 묶는다. **파일 독립 ≠ 의미 독립.** 쪼개기 전에 *join 을 먼저 상상*하라(join 검증이 애매하면 너무 잘게 쪼갰거나 의존을 오판한 것).

## Operating model (실행 절차 — self-locating)

**Step 0 (메인의 환원불가 첫 일).** 위임 *전에* "내 관리 용량 + 이 일이 어떻게 나뉘는가" 를 먼저 계획한다. 소수-독립 → 세션 내 서브 병렬(Regime 1) / 대규모-독립 → Regime 2(보류) / 결합 → 단일. 비자명 분할은 사용자 대화로 정렬(메인의 distinctive 역할).

절차: 1) 목표·non-goal 고정 → 2) touched surface 후보 나열 → 3) shared invariant/API/schema/config 식별 → 4) coherent review unit 결정(JOIN) → 5) 의존 DAG → 6) 병렬 wave 구성(cap·read-capacity) → 7) wave별 join checklist 선작성 → 8) 서브 발급 → 9) 결과 artifact 직접 확인 → 10) 통합·최종 점검 → 보고/승인.

**양면 self-locating 프레임 (role-partition).** 모든 참여자가 같은 프레임에서 자기 위치를 읽는다:
- **orchestrator stance**(메인) — 분해·의존/JOIN 판정·감독·통합검증·사용자 정렬. operator role 의 *stance* 이지 별도 top-level role 아님.
- **executor stance**(서브) — 지정 작업 + 독립 리뷰로 정합성 → *고정 필드*로 반환(변경대상 / 근거 / 검증 / 남은위험 / 건드린파일 / 의존성). 감독자 아님(커밋 권한 없음), out-of-scope 보고.
- **서브 프롬프트 템플릿**: global objective / local task / non-goals / allowed files / stop conditions / expected output.
- **재작업**: in-frame 교정 = 원래 서브 **resume**(컨텍스트 보존); re-frame = **fresh** 서브(anchoring 오염 회피).
- **로딩(role-partition)**: 작은 always-visible self-location 프레임(나는 orchestrator냐 executor냐 + 경계·산출) + 역할별 depth(orchestrator=full playbook / executor=경계+출력계약) — 서브 컨텍스트는 얇게(오프로드 보존).

**최고위험 = 의존/JOIN 오분류**(의존을 독립으로 → 병렬 서브가 부분상태 보고 → 거짓 pass/충돌). 메인 위임 불가. **서브 pass 불신** — 서브 내부 리뷰 pass 는 "그 서브 컨텍스트 안의 self-contained 결론" 일 뿐. **핵심 위험 한 줄: 메인이 *실제 감독했다는 착각*.**

## Close-the-loop validation contract (cheap-first; executor 소유)

> 값비싼 canonical review 에만 의존하지 않도록 *값싼 사전검사로 먼저 닫는* 운영 규율. 이 절은 orchestration 이 **언제·어떻게 루프를 닫는가**만 소유하고, 각 cheap 도구(blind 결함 prefilter / consultation 의 `독립 의견`·`재조율`)의 semantics 는 그 도구의 도메인이 소유한다(cross-domain 재서술 금지 — 여기서는 이름으로만 참조).

- **delegate-by-default.** 실질 validation 은 기본적으로 executor 에 위임한다 — skip-prone 한 operator(main)를 critical path 에서 뺀다. main 직접 validation 은 최소화한다.
- **executor 가 cheap loop 를 닫고 보고한다.** (이 close-the-loop 은 *changeset 검증*용 절차다; 토론형 advisory operation 은 이 루프에 포함되지 않고 각자 도메인 operating model 이 소유한다.) executor 는 비싼 canonical review *전에* 값싼 사전검사를 먼저 돌려 닫는다(cheap-first): **blind 로 결함을 거르고(concern 보고되면 수정 후 재실행) → 정리되면 canonical review → 반환.** blind 의 입력·status·반복 semantics 는 blind 도메인 소유(여기선 이름으로만 참조; orchestration 은 *순서*[cheap-first → escalate]만 소유). cheap-first 이므로 canonical 의 주의가 obvious 결함이 아니라 hard 문제로 간다.
- **최소 evidence (대화형, no-file).** executor 반환에 포함한다: `blind 실행 여부` · `blind 결과(보고된 concern 과 그 처리; status 어휘 등 blind semantics 는 blind 도메인 소유)` · `canonical 실행 여부 + verdict, 또는 canonical-only 선택 사유`. 파일 로그가 아니다(no-file / no-hidden-state 정합). *미래 경화(현재 미구현)*: file-free fingerprint-bound return-value token — wrapper 가 호출 시 changeset fingerprint 를 토큰에 박고 done-gate 가 현재 changeset 과 일치 확인. omission·scope-drift 방지용이며, 위조·audit 는 이 threat 밖(= canonical review / 완전 독립 세션의 몫).
- **main acceptance + JOIN.** main 은 executor 의 intra-unit verdict 를 재심하지 않는다 — evidence 가 present·coherent 한지 확인하고, executor 가 구조적으로 못 보는 cross-unit 통합 정합(JOIN)만 판정한다.
- **operator-combinable output (JOIN guarantee).** operator reconciliation 대상이 되는 도메인 산출(예: consultation·blind)은 결합·중립화 가능한 shape 로 finding 을 노출해야 한다(해당 시 confidence·assumption 필드 포함). 각 도메인은 *자기 출력 shape* 를 소유하고, 이 계약은 "여러 도메인 산출이 operator 단계에서 결합 가능해야 한다"는 JOIN 규칙만 소유한다(필드 자체를 중앙에서 과소유하지 않는다). **도메인-간 finding 충돌의 표현**은 operator-synthesis 수준(conversational, no-file)이며 — 중앙 conflict schema 를 두지 않는다(탈중앙·no-file 정합) — 각 도메인의 intra-domain 충돌 어휘(예: consultation `conflicting-opinions`)와는 별개 축이다. **결합 대상은 *같은 입력의 병렬 산출*이 아니다** — 각 도메인은 입력·타이밍이 다르다(예: blind = 변경분 post-hoc / consultation = 질문·방향 pre-focus·design-level). JOIN guarantee 는 *operator-synthesis 에서 같은 concern 에 닿는 출력들*이 결합 가능한 shape 를 갖게 보장하는 것이지, 두 도메인이 *동일 입력을 병렬 검토*한다는 보장이 아니다(동일-입력 병렬 가정은 오해).
- **ceiling 정직.** 이 툴셋은 hook 금지라 어떤 게이트도 *강제 실행*되지 않는다(canonical 포함). 위는 "실행하면 검증 가능하나 호출은 선택"인 review-level *nudge* 이지 hard gate 가 아니다. 실질 완화 = delegate-by-default + 호출명이 오용을 가시화(절차형 호출을 1회로 단축하면 가시적 미완료가 되도록 — 각 operation 의 완료 의미는 해당 도메인이 소유).

## Regime 2 / 재귀 (이 프로젝트 한정 개념 — 배포 제외)

> 이 절은 **글로벌 배포 rule 로 가지 않는다.** 브랜칭 전략은 프로젝트/조직 고유라 배포 layer 가 가정해선 안 됨. 개념 예시로만 둔다.

- **Regime 2** — 대규모-독립 작업을 멀티 clone repo / 브랜치 / 완전 독립 세션으로 나눠 진행하고, 상위 머지 세션이 닫힌 브랜치를 독립 평가·머지. *머지 세션의 집중점(닫힌 단위 판정·머지) ≠ 작업 세션의 집중점(실행)* — Regime-1 감독/실행 분업의 한 레벨 위 재귀(fractal).
- **enabling 조건** — (a) 각 세션이 다른 root 폴더(worktree / remote isolation; 이건 *mechanism* 이지 branching strategy 가 아님) (b) 서브에이전트 중첩 깊이(harness capability — 검증 필요).
- **게이트(보류 사유)** — AI 머지 신뢰 미확립 + 사용자 분할-명확성 선행. **Regime-1 감독 품질이 곧 머지 세션 신뢰의 토대** → Regime-1 견고화가 Regime-2 게이트 해소 경로.
- 재귀(계층0 전략수립 → 계층1 Regime-1 서브 → 계층2 …)도 같은 *배포-제외* 바구니.

## Vocabulary (domain-local 정의 — 후보)

> 용어의 **full domain-local 정의는 incubation 동안 여기** 있다. glossary(`rules/terminology-glossary.md`)는 용어의 **one-line meaning + classification** 의 single home 이고, full semantics 는 finalization-owner — 이 rule candidate 의 경우 promote 후 terminal rule `snippets/rules/subagent-work-orchestration.md` — 가 소유하며, term 의 finalization 은 그 **terminal rule landing changeset** 에서 결정된다(promote 시점 아님). meaning-bearing 용어는 **exposed(후보 자신의 문서 밖 tracked surface 에 노출)이거나 collision-prone 일 때만** glossary 에 thin **`pending` reservation**(candidate / facet / not-this / eventual-owner-surface; collision-prone 이면 collision-note; **define-no-meaning**)으로 등록한다 — full 정의는 여기, glossary 는 name-level 예약(meaning-home 이전 아님). 현재 등록된 용어 = `subagent-work-orchestration` / `orchestrator stance` / `executor stance`(전부 exposed). `Regime 1/2`·계층·calibrated supervision 등 문서-내부 전용 용어는 **미등록**(과등록 금지).

- **subagent-work-orchestration** — 위 §목표 상태 / Operating model 의 운영 규율(메인=오케스트레이터/감독, 서브=실행자; Regime-1, branching-agnostic). `architecture` / `policy` broad bucket 아님.
- **orchestrator stance** — operator 세션이 분해·의존판정·감독·통합검증·사용자 정렬을 수행하는 stance. top-level role(operator/reviewer/supervisor) 아님.
- **executor stance** — 서브에이전트가 지정 작업 + 독립 리뷰로 정합성을 갖춰 고정필드로 반환하는 stance. 감독자/커밋 권한 없음.

## Measurement (pilot — 임시 scaffolding, ship 안 함)

정성 누적(gitignored `log/**` 등 임시 scaffolding, 정규 기능 비포함): fork 수 / join 시간 / conflict 수 / **메인이 재검증에서 잡은 결함 수** / 사용자 재작업 요청 수 / 단일세션 대비 총 wall-clock. **graduate gate = 병렬 성공 *횟수* 가 아니라 join 품질 + 실패 회수 능력이 측정된 뒤.** measurement 는 정규 기능 비포함(graduation 시 폐기).

## Open questions
- 배포 rule 의 universal core ↔ 프로젝트-특정(codex review-to-pass 바인딩) 분리 경계의 최종 형태.
- role-partition 로딩(작은 always-visible self-location 프레임 + 역할별 depth)의 물리적 home(부트스트랩 확장 vs 기존 표면).
- pre-impl 필수 relay 의 scope(substantial only) 정식화 여부.
- close-the-loop 이 hard gate 아닌 nudge(hook 금지)일 때, 누락된 cheap-validation 을 main 이 accept 가능한 조건·중단권 소재(실 사용 측정으로 성숙).
- cross-domain JOIN 의 충돌 *탐지·종료*: 도메인 산출 간 'same concern' 매칭(공유 식별자 없이 operator prose 뿐)과 cross-domain 충돌의 closure 신호(consultation 의 `재조율` terminal[consultation 소유]은 intra-consultation 축이라 cross-domain 엔 미적용) — 실측에서 표면화, 실 운용으로 성숙.
- JOIN 턴의 operator 역할 충돌: 한 operator 가 blind verbatim transport 와 consultation synthesis 를 동시에 수행할 때, 종합이 blind verbatim 을 소급 위반하지 않게 하는 경계.
- severity·confidence 의 cross-domain 가중: blind 가 다는 severity(예: `blocking`)와 consultation 항목의 confidence 를 operator-synthesis 에서 함께 가중하는 방식(중앙 schema 없이; 각 필드 소유는 해당 도메인).
