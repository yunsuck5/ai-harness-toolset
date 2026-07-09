# blind-advisory Work Packet

> 회차성 작업 문서 — line-level reference 분류·조사/구현 노트·evidence 제안·edge-case 노트. **승인 대상 아님·live domain 문서 아님·Spec 대체 아님.** 금지 content: 실행 command sequence·staging 절차·review 결과·validation 결과·readiness 판정(이들은 operator report `log/**` 또는 미기록). promoted-lifecycle closeout 시 삭제.

## blind-advisory 이름-참조 전수 인벤토리 (조사 — 실행 결과 아님)

이 changeset 이 checked / updated 를 판정해야 할 blind-advisory 이름-참조의 *위치*. 실제 실행 보고와 최종 판정은 closeout report 소관이며 여기서는 대상과 그 분류 근거만 기록한다.

**전수 근거와 그 단위**: `blind-advisory` · `blind advisory` · `블라인드` 를 대소문자 무시로 검색하되 `log/**`(runtime)과 candidate 자신의 폴더를 제외한 결과 — **11개 파일, 33개 참조 줄**. 여기서 세는 단위는 *참조 줄*(한 문장·한 항목)이지 토큰 occurrence 가 아니다(같은 줄 안의 중복 토큰까지 세면 41 occurrence 이며, 갱신 판정은 줄 단위로 내리므로 줄을 단위로 삼는다). 아래 분류의 합이 그 33 줄을 덮는다.

**분류축 두 개.**
1. *갱신 필요성*: 그 줄이 blind-advisory 의 **현재 candidacy 를 주장**하는가(이 promote 로 거짓이 됨 → 갱신), 아니면 status 를 주장하지 않는 참조이거나 그것을 쓴 batch 시점의 사실인가(그대로 참 → no-change).
2. *갱신의 근거*: 그 표면이 규칙의 sibling-mention **sweep 대상**(promoted artifact / canonical index / accepted glossary entry)인가, 아니면 **active surface 의 stale 정정**인가. 두 근거는 다르며 하나로 뭉뚱그리지 않는다.

- **A. 현재 candidacy 주장 — 갱신 대상 (2 줄)**
  - `docs/consultation/consultation_spec.md` §Cross-domain interface — “아직 incubating domain candidate — live 레이어 아님”. **근거 = sweep 의무**(promoted artifact 의 `prelive` Spec).
  - `snippets/claude-skills/ai-harness-consultation/SKILL.md` §Cross-domain interface — “still an incubating domain candidate — not a live layer”. **근거 = active surface 의 stale status 정정**(sweep 집합 아님; behavior 무변경).
- **B. status 를 주장하지 않는 참조 — no-change 후보 (9 줄)**
  - `consultation_spec.md` §목표 상태(vocabulary 분리) · §Review focus(사례-수준 구분) · §Lifecycle state(후속 작업의 이름으로 언급).
  - `ai-harness-consultation/SKILL.md` frontmatter `description` · §What this is not · §Core invariants(vocabulary separation) · §Loop state and status vocabulary.
  - `consultation_design.md` §왜 바꾸는가(gap 서술) · §non-goals(레이어 대비).
- **C. 그것을 쓴 batch 시점의 사실 — no-change 후보 (10 줄)**
  - `consultation_design.md` §수정 대상(그 batch 의 sweep 열거) · §non-goals scope 밖(형제 promote 는 별도 단계) · §Deferred Questions(“모두 정규화된 후” 미래 조건, O promote 전까지 미충족).
  - `consultation_plan.md` §Batch 순서 · §Batch 정의 scope.
  - `consultation_work_packet.md` §sweep 인벤토리.
  - `rules/docs-working-model/docs-working-model.md` *Incubation tier* Transition 절 — 규칙 landing 시점에 in-flight 였던 candidate 열거(“already in-flight then”). 과거 시점 진술.
  - `rule_docs/docs-working-model/docs-working-model_backlog.md` — promote 순서 row(세 candidate 가 모두 처리될 때까지 열림) · candidate identity/kind transition row.
  - `docs/review/review_backlog.md` — repo 밖 pilot 결과의 review-interface 반영 여부 row(pilot 도구는 여전히 repo 밖).
- **D. glossary `rules/terminology-glossary.md` — per-term 결정 (6 줄)**
  - blind-advisory 소유 pending 예약 3개(`blind advisory` · `transporter` · `blind-advisory status vocabulary`): 전부 `pending` 상태이며 그 finalization-owner 는 아직 live 가 아니다. 처분은 sweep 과 별개의 per-term 결정이고 그 결정 자체는 Design/Plan 이 소유한다.
  - consultation 소유 예약이 blind-advisory 를 이름-참조하는 곳(`not-this` · `collision-note`)과 Pending 절 서두의 형식 서술: contrast/collision 성격이라 promote 후에도 유효(no-change 후보).
- **E. id-키 enforcement binding — 갱신 대상 아님, 조용히 생략하지 않고 열거 (6 줄)**
  - `scripts/docs-working-model-check.ps1` — glossary 예약 형식을 강제할 candidate id 목록에 blind-advisory 가 있고, scope 안내 문장이 candidate incubation 폴더를 서술한다. 이 binding 은 후보-status 주장이 아니라 *그 id 의 pending 예약이 존재하는 동안* 유효하며, 이 batch 는 그 예약을 finalize 하지 않으므로 목록은 그대로 참이다.
  - `tests/docs-working-model-check.Tests.ps1` — 위 검사의 회귀 fixture 가 blind-advisory id 를 사용한다. 같은 이유로 그대로 참이다.
- **F. 참조 0** — `docs/README.md` · `rules/README.md` 에 blind-advisory 참조 없음(E1 claim 유지).

## 원자적 swap 검증 노트

- baseline 대조(검증용 스냅샷 — 실행 결과·시점성 상태 판정 아님): **pre-swap committed baseline** = `blind-advisory_incubation.md` 단일. 이 changeset 의 **post-swap committed 상태** = `_design`/`_plan`/`_spec`/`_work_packet`(incubation 삭제).
- **E3 판정 기준 노트(조사)**: E3 의 non-coexistence 는 *committed state* 를 대상으로 하므로 working tree 의 중간 공존은 그 판정 대상이 아니다. 한편 구조 검사 스크립트의 스캔 대상은 working tree 다 — 두 기준의 대상이 다르다는 것이 이 라운드의 edge-case 다.

## incubation → design E4 대조 대상 (조사 — 흡수 *결과* 는 closeout report 소관)

closeout 의 E4 흡수-완결 확인이 대조할 *대상 목록*(무엇을 design 어느 위치와 맞대는지; 확인 결과·판정은 여기 적지 않고 closeout report 로).

- E4 6요소(adopted conclusion / rejected alternatives / evidence type / scope / failure criteria / negative evidence) ↔ design 대응 위치.
- 정체 불변식 8항 ↔ design E4①.
- input contract 의 허용/금지 ↔ design E4① 및 §Plan readiness 의 resolve 항목(candidate 문구를 정정한 지점).
- status vocabulary closed 3값 + `unavailable` 토큰 · severity closed 3값 · finding 의 confidence/assumption ↔ design E4①.
- 호출 trigger 어휘의 review-계열 배제 결정 ↔ design E4①(구체 문구는 skill 소관으로 deferral).
- inconclusive 의 경계-보존 역할 + 책임회피 hatch 방지 가드 ↔ design E4①.
- discard 기준 7개 ↔ design E4⑤. promote-readiness 5개 ↔ design E4⑥ 및 §Plan readiness.
- open question 4개(reviewer invocation posture / finding 표현 naming / blind-at-close scope / review 자동 preflight) ↔ design §Plan readiness 의 resolve 또는 §Deferred Questions.
- 미흡수 원료 4개(reloop 수율역학 / fix→re-blind 용도 / at-use 탐색 클래스·입력 구성 mechanic / 측정 dimension) ↔ design 의 소유권 배정(close-the-loop 계약 · skill · 측정 scaffolding).

## Spec 저작 인수 항목 (Design 이 Spec 으로 위임한 것 — 저작 시 참조)

- input contract 의 필드(허용 입력의 구성요소 · 금지 framing 목록의 형태)와 인접 surface 판정의 명세.
- status vocabulary 의 전이 MUST(무엇이 `inconclusive` 를 정당화하는 트리거인가 · 기계 실패가 `unavailable` 로 가는 조건 · `no-concerns-reported` 가 자기 inspection 범위를 함께 진술해야 하는가).
- severity 각 값의 분류 의미와 finding 동반요소(confidence · assumption)의 필드 위치/이름.
- payload 신뢰 경계의 최종 normative 문장.
- transporter 규율의 normative 표현(무엇이 suppress/축약에 해당하는가)과 downstream 중립화 경계.
- no-file 런타임의 normative 진술.

## 배선 표면 인벤토리 (Implementation batch 가 소비 — 이 batch 의 실행 대상 아님)

정규 skill 하나를 배포에 편입할 때 갱신이 필요한 표면의 조사 결과. activation resolver 는 generic directory enumeration 이라 스크립트·lib 은 대상이 아니다.

- 진입 아티팩트: `snippets/claude-skills/<skill-name>/SKILL.md` 신설(이 위치의 존재가 install/verify/apply/uninstall 의 generic 파이프라인을 활성화한다).
- activation surface 의 개수·이름을 산문으로 hardcode 하는 곳: `docs/install-update/install-update_spec.md` · `INSTALL.md`(두 곳) · `README.md` · `templates/install-root/AI_HARNESS_TOOLSET_ROOT_README.md`(두 곳).
- surface count 와 skill 이름을 단언하는 테스트: `tests/activate-global.Tests.ps1`.
- repo-local 지시 표면의 skill 열거: `CLAUDE.md` / `AGENTS.md`(shared body — mirror-edit 규칙상 동시 수정).
- **edge-case 노트**: 신규 SKILL.md 는 untracked 상태로 존재하므로, 변경분을 대상으로 하는 whitespace/BOM 계열 검사가 기본적으로 그 파일을 보지 않는다.
