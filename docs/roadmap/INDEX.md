# docs/roadmap/ — Index & Interim Routing

본 파일은 `docs/roadmap/` 의 area index 이자 interim routing note 다 (이전 `docs/roadmap/README.md` 를 흡수). final docs taxonomy 의 선언이 아니며, 본 INDEX 자체가 운영 규칙 문서로 비대해지지 않도록 의도적으로 짧게 유지한다.

본 INDEX 가 존재한다는 사실만으로 어떤 implementation, source/doc mutation, install / update / restore 실행, global / user filesystem mutation, commit / push / publish / merge / release / adoption 도 자동 승인되지 않는다.

> **현행 routing (docs taxonomy reset).** install/update/global-adoption 의 **current 상태**는 `docs/systems/install-update/STATUS.md` + `DEFERRED.md` 가 authoritative 다. review = `docs/systems/review/STATUS.md`, brief = `docs/systems/brief/STATUS.md` + `DEFERRED.md`. 전체 current 진입점: `docs/current/SOURCE_OF_TRUTH.md` (question→authority), `docs/current/PROJECT_STATE.md` (summary), `docs/current/NEXT_ACTIONS.md` (active queue). post-MVP numbered remaining order 의 routing view = `docs/roadmap/CURRENT_MILESTONES.md` (authority = `POST_MVP_PLAN.md` §11). 아래 §3 의 root-level roadmap 문서는 **design / model / completed-audit** source 이며, 각 문서 상단 routing 배너가 해당 system STATUS 로 연결한다.

---

## 1. 현재 `docs/roadmap/` 의 성격

`docs/roadmap/` 는 현 시점 **mixed roadmap area** 다. 다음 두 종류의 문서가 같은 directory 안에 공존한다.

- post-MVP 결정 / current source-of-truth 성격의 root-level roadmap docs. 예: `POST_MVP_PLAN.md`, `GLOBAL_INSTALL_UPDATE_MODEL.md`, `GLOBAL_ADOPTION_DECISION.md`, `GLOBAL_ADOPTION_PROCEDURE.md`, `SHARED_GLOBAL_INVOCATION_CONTRACT.md`, `TOOLROOT_PROJECTROOT_AUDIT.md`, `CLEAN_TARGET_SMOKE_CRITERIA.md`, `REVIEW_EFFORT_GUIDE.md`.
- 같은 directory 가 향후 follow-up planning guide 류를 받아낼 가능성이 있는 generic roadmap surface.

mixed 의 의미는 단순하다 — 본 directory 는 현재 한 종류의 문서만 모아 둔 정렬된 taxonomy 가 아니라, post-MVP roadmap 의 routing layer 와 향후 보강될 수도 있는 follow-up planning surface 를 동시에 담고 있다.

---

## 2. Full docs taxonomy restructuring — deferred

`docs/` 전체의 full docs taxonomy restructuring (`docs/roadmap/` 내부 재배치 포함) 은 **deferred** 다. 다음을 의미한다.

- 본 INDEX 가 final docs taxonomy 를 declare 하지 않는다.
- 기존 `docs/roadmap/` root-level 문서의 이동, rename, split, rewrite, 통폐합은 본 INDEX 의 존재로 승인되지 않는다.
- full taxonomy restructuring 은 별도 scoped approval (설계 → 승인 → scoped execute) 절차를 거친다.

본 docs taxonomy reset 은 그 별도 scoped approval 에 해당하는 진행 중 작업이다 (Batch 0 audit 기준). 따라서 본 reset 안에서의 additive current/system entrypoint 신설, low-risk archive move, POST_MVP_PLAN decomposition, roadmap route/relabel 은 본 INDEX 가 금지하던 "자동 승인" 이 아니라 명시적으로 승인된 scoped 작업이다.

---

## 3. Existing root-level roadmap docs — 현재 routing layer

§1 에 enumerate 된 root-level roadmap docs 는 본 INDEX 의 존재와 무관하게 **현재 routing layer** 로 그대로 유지된다.

- 각 root-level 문서의 design / model / contract 책임은 해당 문서 자체의 본문이 정의한다. 본 INDEX 가 그 책임을 대체하거나 재정의하지 않는다.
- 단, **current 상태 / completed-ledger / deferred 의 authoritative 자리**는 docs taxonomy reset 이후 system STATUS/DEFERRED 로 이동했다 (위 routing 배너 참조). root-level roadmap 문서는 그 status 의 design / model / completed-audit source 다.
- `POST_MVP_PLAN.md` 는 decomposition (Batch 3) 이후 **post-MVP decision record (§1–§9)** 와 **numbered remaining order (§11) 의 authority** 로 유지된다. current status / next action / completed / deferred 의 authoritative 자리는 `docs/current/*` + `docs/systems/*` + `docs/roadmap/CURRENT_MILESTONES.md` 다 (POST_MVP_PLAN 상단 routing 배너 참조). §10 의 상세 completed narrative 는 `docs/archive/old-roadmaps/POST_MVP_COMPLETED_NARRATIVE.md` 로 이동했다.

root-level 문서별 role (current routing 기준):

- `GLOBAL_INSTALL_UPDATE_MODEL.md` — install/update/self-adoption operating **model/design** (실행 SoT = `INSTALL.md`). → `systems/install-update/STATUS.md`.
- `global-install-update/STEP3_INSTALL_UPDATE_DECISION_GUIDE.md` — Step 3 implementation planning, 위 model 의 subordinate. → `systems/install-update/STATUS.md` (IU-11) / `DEFERRED.md`.
- `GLOBAL_ADOPTION_DECISION.md` — operating-layer 전환 decision + managed-block marker policy (§6). → `systems/install-update/STATUS.md`.
- `GLOBAL_ADOPTION_PROCEDURE.md` — Claude skill global adopt/update/remove 절차. → `systems/install-update/STATUS.md`.
- `SHARED_GLOBAL_INVOCATION_CONTRACT.md` — shared/global invocation contract design (D1–D9). → `systems/install-update/STATUS.md`.
- `TOOLROOT_PROJECTROOT_AUDIT.md` — completed read-only path audit (historical). → `systems/install-update/STATUS.md` (IU-04).
- `CLEAN_TARGET_SMOKE_CRITERIA.md` — smoke criteria SC1–SC7 (실행 완료 record / Step 4 fixture baseline). → `systems/install-update/STATUS.md` (IU-07).
- `REVIEW_EFFORT_GUIDE.md` — review effort/cost 운영 권고 (active reference). → `systems/review/STATUS.md`.
- `POST_MVP_PLAN.md` — post-MVP decision record (§1–§9) + numbered order authority (§11). `CURRENT_MILESTONES.md` 가 §11 을 1:1 routing.
- `CURRENT_MILESTONES.md` — §11 numbered order 의 status routing view.

본 INDEX 는 root-level 문서의 reading order 를 declare 하지 않는다. current 판단은 위 routing 배너의 current/system 자리를 먼저 본다.

---

## 4. Temporary topic namespace — not final taxonomy

`docs/roadmap/` 내부에 향후 등장할 수 있는 **topic subfolder** (예: `docs/roadmap/<topic-name>/`) 는 **temporary topic namespace** 다. final taxonomy 가 아니다.

다음 기준이 동시에 충족될 때에만, 별도 scoped decision 하에 한 개의 topic subfolder 를 만들 수 있다.

- 그 subfolder 가 담을 follow-up planning guide 가 **large** 한 단위라서, 단일 file 로 root-level 에 두면 가독성 / 관리성이 손상된다.
- 그 follow-up planning guide 가 **existing root-level parent document 에 명확히 subordinate** 하다. 즉, 해당 parent 문서가 source-of-truth 이고 subfolder docs 는 그것의 detail / breakdown 이다.
- 그 follow-up planning guide 를 parent 문서에 **직접 병합하면 source-of-truth ambiguity 가 커진다**. (예: parent 문서가 짧은 contract 인데 long-form planning detail 을 그 안에 inline 으로 끌어들이면, 어느 부분이 contract 이고 어느 부분이 derived planning 인지 모호해진다.)

세 조건 중 어느 하나라도 충족되지 않으면 subfolder 를 만들지 않고 root-level 의 단일 문서로 둔다.

subfolder 의 신설 자체도 본 INDEX 의 존재로 자동 승인되지 않는다. case-by-case 의 scoped decision 이 필요하다.

---

## 5. Subfolder docs — parent 를 silently replace / override 하지 않는다

위 §4 의 조건을 충족하여 만들어진 subfolder docs 는 다음 boundary 를 따른다.

- subfolder docs 는 그 parent document 의 source-of-truth 지위를 **silently replace 하지 않는다**. parent 가 source-of-truth 인 영역에서는 parent 의 본문이 우선한다.
- subfolder docs 는 그 parent document 의 결정 / 진술을 **silently override 하지 않는다**. parent 의 결정을 변경해야 한다면 parent 문서 자체의 별도 scoped 수정으로 처리한다 — subfolder 안에서 새 결정을 내려 parent 를 덮어 쓰는 흐름은 금지.
- subfolder docs 의 본문은 자신이 어느 parent 의 subordinate 인지를 본문 안에서 명시적으로 기록한다.

본 boundary 는 final docs taxonomy 가 정해지기 전까지의 interim 규칙이다.

---

## 6. Codex review gate

본 INDEX 의 존재로 source / doc mutation 의 review gate 가 변하지 않는다. `docs/roadmap/` 안의 어떤 source / doc 변경도 다음을 따른다.

- repo 의 정상 Codex review gate 를 거친다 (`scripts/review-prepare.ps1` → `scripts/review-run.ps1` → `scripts/review-verify.ps1 -RequireResult`).
- verdict (`yes` / `no` / `yes with risk`) 는 commit / push / publish / merge / release / adoption 을 자동 승인하지 않는다.
- review verdict 이후의 모든 mutation / global apply / commit / push 는 사용자 명시 결정으로 처리한다.

본 INDEX 자체의 신설도 본 규약을 따른다.

---

## 7. Example topic namespace — `global-install-update/` (created, temporary)

`docs/roadmap/global-install-update/` 는 §4 의 조건을 충족한다고 판단되어 별도 scoped decision 으로 **이미 생성된** topic namespace 다. 현재 그 안에는 `STEP3_INSTALL_UPDATE_DECISION_GUIDE.md` (Step 3 implementation planning guide) 가 들어 있다. 본 namespace 의 상태는 다음과 같다.

- **created**: §4 의 조건 (large follow-up planning, parent subordinate, parent 병합 시 ambiguity) 가 충족되어 namespace 와 그 안의 Step 3 guide 가 생성되었다. (§3 의 role 표에 routing 되어 있다.)
- **temporary**: final taxonomy 의 선언이 아니다. full docs taxonomy restructuring 단계에서 이름 / 위치 / 분류가 다시 결정될 수 있다.
- **subordinate**: parent 문서는 `docs/roadmap/GLOBAL_INSTALL_UPDATE_MODEL.md` 다. subfolder 안의 docs 는 본 parent 의 source-of-truth 지위를 §5 대로 유지한다 (STEP3 guide 본문이 자신이 parent 의 subordinate 임을 명시).

본 §7 은 namespace 의 현 상태 기록이며, 추가 namespace 신설 / 추가 guide 작성 / 그 외 어떤 mutation 도 본 INDEX 의 존재로 자동 승인되지 않는다.

---

## 8. Source-of-truth 관계

- 본 INDEX 는 `docs/roadmap/` 의 interim routing note 다.
- root-level roadmap 문서의 contract / decision 과 본 INDEX 가 상충하면 root-level 문서가 우선한다.
- full docs taxonomy restructuring 시점에 본 INDEX 의 routing note 는 새 taxonomy 의 framing 으로 흡수되거나 deprecate 될 수 있다 — 그 mutation 도 별도 scoped approval 을 거친다.
