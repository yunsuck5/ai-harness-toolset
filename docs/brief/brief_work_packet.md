# brief Work Packet

> batch B(brief pilot)의 class-2 **temporary work document** — 회차성 분석 전용. live 문서가 아니고 Spec 을 대체하지 않으며, closeout 시 current-bearing 내용이 brief_spec(cross-domain interface 절의 지속 경계만) / closeout report 로 흡수된 뒤 **이 파일은 삭제**된다(보존 = git history). 어떤 문장도 spec 으로 복사되지 않는다 — 지속 결정은 spec 의 normative 문장으로 재서술된다. 이 문서는 mutation/commit/push 승인이 아니다(1회 진술).

## 1. Cross-domain inbound reference 분류 (line-level)

조사 기준: retire 예정 3문서(`docs/contracts/brief/BRIEF_CONTRACT.md` · `docs/systems/brief/STATUS.md` · `docs/systems/brief/DEFERRED.md`)의 경로 참조 + bare-token ID(`BR-01~03`/`BR-D-01~03`). repo tracked 전수(git grep), gitignored `log/**` 는 시점 기록으로 제외. batch B 는 아래 분류의 **pointer 갱신만** 수행하고, 타 도메인 문서의 brief 의미 재진술 정리는 소유 batch(R/I/S/P) 소관으로 미접촉.

### 1a. batch B 가 직접 갱신해야 하는 표면 (routing·orientation·자기 도메인)

| 표면 | 참조 | 갱신 방향 (분석) |
|---|---|---|
| `CLAUDE.md` L24 / `AGENTS.md` L24 | trigger map Brief 행의 contract 경로 1곳씩 | brief_spec 경로로 교체 — **mirror-edit + 별도 승인 + `global-file-mutation-boundary.md` 선독 필요** |
| `README.md` (3+2곳) | public landing 의 Brief 설명이 contract 를 source-of-truth 로 지명 | spec 경로로 교체(landing 기능 보존, 문장 재서술 최소) |
| `docs/current/REPO_READING_GUIDE.md` Q4 (2+2곳) | brief routing 항목 전체 | Q4 를 `docs/README.md` 로 이관·제거(가이드 자체 retire 는 P 소관). Q5 의 Brief 언급(runtime restore evidence)은 경로 정의가 아니므로 존치 가능 — Spec 작성 시 재확인 |
| `docs/README.md` | (layer 표가 `contracts/`·`systems/` 계층 기술) | closeout Level-1 gate 에서 mixed-state 반영 + Q4 이관분 수용 |
| `docs/backlog/INDEX.md` (1) · `docs/roadmap/INDEX.md` (1) | brief DEFERRED/STATUS 분류 routing 각 1곳 | brief_backlog.md / brief_spec 으로 교체 |
| `docs/brief/brief_design.md` (자기 참조 6곳) | 처분 대상 명명 | design 은 closeout 에서 retire — 별도 갱신 불요 |

### 1b. pointer 수준만 갱신 (소유 도메인 별도 — 의미 재진술 미접촉)

| 표면 | 건수(경로/계열) | note |
|---|---|---|
| `docs/systems/install-update/GLOBAL_INSTALL_UPDATE_MODEL.md` | 6 + systems/brief 2 + ID 2 | 그 중 1건 = §5 의 stale 문장(아래 §5)과 동일 위치. 나머지는 3차 reconciliation note 류의 contract 지명 — spec 경로 교체 또는 직접 결정 문장 재서술 |
| `docs/decisions/POST_MVP_PLAN.md` | 5 + 6 + 4 | §3/§5/§10 의 contract·STATUS·DEFERRED 지명 — pointer 교체 |
| `docs/decisions/GLOBAL_ADOPTION_DECISION.md` | 5 + 1 + 1 | superseded note·§4·§7·§8 의 contract 지명 — pointer 교체 |
| `docs/contracts/global-invocation/SHARED_GLOBAL_INVOCATION_CONTRACT.md` | 3 | contract 지명 — pointer 교체 |
| `docs/policies/REVIEW_EFFORT_GUIDE.md` | 5 | review 도메인 소유(R) — pointer 만 |
| `docs/systems/skills/FUNCTION_LEVEL_SKILL_ARCHITECTURE_PLAN.md` (5+5+ID) · `docs/systems/skills/STATUS.md` (1+1+1) | skills 도메인(S) — pointer 만 | |
| `docs/decisions/DECISIONS.md` (1+1+1) · `docs/systems/install-update/STEP3_…GUIDE.md` (1+1+1) · `docs/systems/install-update/STATUS.md` (1) · architecture 3종(각 1) | pointer 만 | |

### 1c. 갱신 불요 (조사 note)

- `docs/contracts/README.md` — `brief/` 폴더 명명: 구형 brief 폴더 retire 시 함께 갱신(1a 계열로 흡수).
- 의미 재진술(예: GLOBAL_ADOPTION_DECISION §2 의 BF Level 설명, POST_MVP_PLAN §3/§5 본문)은 **내용상 현행과 정합** — 소유 batch 전까지 존치(존속하되 확장 금지).

## 2. BRIEF_CONTRACT 절 → brief_spec 대응표 (분석)

| contract 절 | 처분 | spec 착지(분석) |
|---|---|---|
| 서두(정의·manual convention first) | 이주 | Header + 목표 상태 |
| 핵심 정의(유일 restore source·compact·inline 금지) | 이주 | 목표 상태 + Durable boundary |
| BF Level 표(1/2/3 = maturity, not path) | 이주 | 목표 상태(maturity 정의) + Lifecycle state(현 수준 compact) |
| canonical Brief 자리(단일 자리·rejected 위치들) | 이주 | Durable boundary(invariant) — concrete path 는 active surface 소유 현재 값으로 1회 명시 |
| Historical lineage(1·2·3차) | git history | 3차의 **결정**만 Durable boundary 문장으로 |
| 현재 source-side primitive 상태(narrow ≠ BF L3) | 이주 | Owner surface 지도 + 목표 상태 |
| Future scoped work(BF L3 항목) | backlog 통합 | `brief_backlog.md`(BR-D-01/03 와 합류; "자동 승인 아님" 반복문은 Header 1회로 갈음) |
| BRIEF 위치와 독자(operator 1st·agent 2nd·not shared handoff) | 이주 | 목표 상태 |
| source vs target repo 경계(self-dogfooding instance) | 이주 | Cross-domain interface(install-update footprint 경계) + 목표 상태 |
| tracked vs gitignored(default untracked; tracked 전환 = contract 미정의 operator 결정) | 이주 | Durable boundary — **열린 문 유지**(Brief tracked 전환 가능성은 별도 결정 트랙) |
| restore source — Brief only | 이주 | 목표 상태(핵심 정의와 합류) |
| required/optional headings 표 | 이주 | 목표 상태 normative 문장(heading set = `brief-check.ps1` 가 enforce 하는 외부 관찰 행동; 표 자체는 template 이 소유) |
| primitive 책임 3절(brief-init/check/status required/forbidden) | 이주 | 목표 상태 — **목록 형식 복제 금지, 외부 관찰 행동의 문장 재구성**(1:1 방향 2 의 핵심 표면) |
| review/commit/push 경계 | 이주 | Durable boundary + Cross-domain interface(review 도메인 비경계) |
| encoding 정책 | 이주 | Validation expectation + Owner surface(`scripts/lib/encoding.ps1`) |
| non-goals(daemon/watcher/state-file/multi-Brief/root brief 부활 금지 등 durable 항목) | 이주 | Durable boundary. 이미 닫힌 회차성 항목(예: 2차 framing 잔재 정리)은 git history |
| 향후 확장 시 고려 | 분할 | durable 한 것(새 wrapper 에도 자리·heading 유지)만 Durable boundary, 나머지 git history |

검증 note: 위 17행이 contract 의 전체 H2 를 누락 없이 커버함(절 수 대조 완료). spec 작성 시 이 표의 "이주" 행마다 normative 문장 초안을 대응시키고 이중화 0 을 재대조한다.

## 3. STATUS / DEFERRED 행별 처분 대조

- STATUS current posture(3 bullet) → spec 목표 상태 + Lifecycle state 로 표현(canonical 자리·BF Level 의미·유일 restore source — §2 와 동일 사실의 중복이므로 spec 에서 1회만).
- ledger BR-01(primitive 구현) → "현재 의미"는 Owner surface 지도가 표현. 행·`POST_MVP_PLAN` detail 포인터는 git history(포인터 비이주).
- ledger BR-02(snippet 정렬→제거; canonical framing 은 contract+skill 에만) → spec 의 Cross-domain interface 문장("글로벌 snippet 은 Brief framing 을 carry 하지 않는다; framing 의 home 은 spec+skill")으로 재서술. 서사는 git history.
- ledger BR-03(target smoke 완료) → Lifecycle state 의 maturity 한 줄("primitive 는 target 에서 operable")로 충분. 행은 git history.
- DEFERRED BR-D-01(deterministic writer)·BR-D-03(stale warning·session-start guidance) → `brief_backlog.md` 행으로 이주(한 줄 + reopen 조건; **기존 ID 보존**).
- DEFERRED BR-D-02(retired) → row 미생성. 인바운드 분석: BR-D-02 인용처는 전부 "restore-offer 자동화는 폐기됨" 사실의 인용(§1b 표면들 + contract 자신) — **직접 결정 문장으로 재서술 가능**하므로 tombstone 불요 예상. 확정은 closeout sweep 의 bare-token 기계 판정.
- DEFERRED 의 금지 목록(daemon/watcher/scheduler/state-machine file/automatic decision-maker) → deferred 가 아니라 spec Durable boundary 로.
- **backlog ID 정책(분석)**: 기존 ID 가 BR-NN(completed)·BR-D-NN(deferred) 두 계열. 옵션 (a) BR-D ID 그대로 보존 + header `next ID: BR-D-04` — 인바운드 bare-token 이 많아 sweep 비용 최소 / (b) 단일 BR 계열로 재채번 — 깔끔하나 재채번 sweep 비용 발생. **제안 = (a)**. 결정은 사용자(Spec 전).

## 4. terminology 4건 — active surface 실사용 evidence + 제안

조사 표면: `snippets/claude-skills/ai-harness-brief/SKILL.md` · `templates/brief/BRIEF.md` · `scripts/brief-*.ps1` · `tests/brief-*.Tests.ps1` (git grep, case-insensitive).

| 용어 | 실사용 evidence | 옛 disposition | operator 제안 |
|---|---|---|---|
| `checkpoint` | SKILL.md 5곳 — workflow 절 제목("Save / checkpoint"), trigger 문안("현재 phase checkpoint 남겨줘"). scripts/template/tests 0 | accept | **accept 유지** — workflow 명칭으로 실사용 |
| `restore point`(복구 지점/복구 시점) | SKILL.md 5곳 — trigger 문안 2종 + **canonical confirm 문장**("이 복구 지점에서 이어서 진행할까요?") + "Summarize the restore point" | defer | **accept 로 상향 제안** — 옛 defer 와 달리 workflow 의 핵심 UX 문장에 박혀 있음(재검증의 실증 사례) |
| `continuation` | 영문 용어 0건. 한국어 "이어갈/이어서"는 trigger 문안의 일반어(용어 아님) | reject | **reject 유지** — 용어로서의 표면 사용 없음 |
| `handoff` | SKILL.md trigger 동의어 1곳("handoff 지점 만들어줘") + **부정문 2곳**(SKILL "not a shared handoff document" · template "human handoff 문서가 아니다") | reject-as-canonical | **reject-as-canonical 유지** — trigger 동의어로는 잔존 허용, canonical 어휘 채택 금지(rejected `handoff/snapshot` 도메인과 정합) |

glossary 반영은 별도 mutation 승인(채택 결정과 분리).

## 5. stale 1건 — evidence 정리

- 대상: `docs/systems/install-update/GLOBAL_INSTALL_UPDATE_MODEL.md` §9.3 의 한 문장(L423 부근).
- evidence ①(구현): `scripts/brief-init.ps1` 전문(47줄)에 `Test-IsSourceRepoRoot` 호출 없음 — 유일한 거부는 기존 BRIEF.md no-overwrite.
- evidence ②(자기-정정): 같은 §9.3 후반부(L430 부근)가 "1차 reconciliation 에서 제거된 refuse guard 는 제거된 상태 유지"라고 명시 — L423 의 현재형 주장과 같은 절 안에서 모순.
- evidence ③(이중 stale): L423 은 `BRIEF_CONTRACT.md` 와 `POST_MVP_PLAN.md` §3 의 "literal wording 이 이전 posture 반영"이라고도 주장하나, 두 문서 모두 현재 3차 reconciliation 본문이다.
- evidence ④(경계): 이 문장의 주제는 brief 도메인 사실(스크립트 행동 + brief 문서 wording)이며 install-update 모델의 의미가 아님. 또한 문장 자체가 `BRIEF_CONTRACT.md` 경로를 인용하므로 contract retire 의 pointer sweep 필수 갱신 대상에 이미 포함됨.
- **처리 제안**: pointer sweep 에서 이 문장을 현행 사실로 재서술 — guard 부재·두 문서의 현행화·"별도 scoped work" 예고가 brief_spec 이주로 닫힘을 1~2문장으로. pointer / false-current wording 수준 meaning-preserving 한정; install-update 의미·`INSTALL.md` 접촉 0. 문안에서 의미 변화 의심 시 abuse-guard 에스컬레이션.

## 6. Evidence proposal (closeout 시)

- `log/evidence/brief-pilot/batch-b/validation-evidence.md` 에 기록 제안: spec↔구현 1:1 normative 문장 대응표(방향 1·2), 4-class sweep 결과(repo tracked 기준), brief Pester 3 suites 결과, 비례성 출구 사용 횟수.
- closeout report 에 §1 분류의 `checked/updated` 전수 보고(조용한 생략 0).

## 7. Reviewer question 준비 (Spec review 용 중립 후보)

1. brief_spec 과 retire 된 contract 사이에 의미 이중화가 남았는가, 누락이 생겼는가(§2 대응표 기준)?
2. spec 의 Durable boundary 에 회차성 내용이 섞였는가("이번 회차가 끝나도 참인가" 판별식)?
3. concrete path 문안이 path 소유로 읽히는가, active surface 소유 현재 값 1회 명시로 읽히는가?
4. backlog 의 ID 정책(채택안)이 일관 적용되었고 bare-token 인바운드가 재서술/갱신되었는가?
5. BR-D-02 인바운드의 직접 결정 문장 재서술이 의미를 보존하는가?
