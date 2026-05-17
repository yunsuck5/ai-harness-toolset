# docs/roadmap/ — Interim Routing Note

본 파일은 `docs/roadmap/` 의 현재 구조에 대한 **짧은 routing note** 다. final docs taxonomy 의 선언이 아니며, 본 README 자체가 운영 규칙 문서로 비대해지지 않도록 의도적으로 짧게 유지한다.

본 README 가 존재한다는 사실만으로 어떤 implementation, source/doc mutation, install / update / restore 실행, global / user filesystem mutation, commit / push / publish / merge / release / adoption 도 자동 승인되지 않는다.

---

## 1. 현재 `docs/roadmap/` 의 성격

`docs/roadmap/` 는 현 시점 **mixed roadmap area** 다. 다음 두 종류의 문서가 같은 directory 안에 공존한다.

- post-MVP 결정 / current source-of-truth 성격의 root-level roadmap docs. 예: `POST_MVP_PLAN.md`, `GLOBAL_INSTALL_UPDATE_MODEL.md`, `GLOBAL_ADOPTION_DECISION.md`, `GLOBAL_ADOPTION_PROCEDURE.md`, `SHARED_GLOBAL_INVOCATION_CONTRACT.md`, `TOOLROOT_PROJECTROOT_AUDIT.md`, `CLEAN_TARGET_SMOKE_CRITERIA.md`, `REVIEW_EFFORT_GUIDE.md`.
- 같은 directory 가 향후 follow-up planning guide 류를 받아낼 가능성이 있는 generic roadmap surface.

mixed 의 의미는 단순하다 — 본 directory 는 현재 한 종류의 문서만 모아 둔 정렬된 taxonomy 가 아니라, post-MVP roadmap 의 routing layer 와 향후 보강될 수도 있는 follow-up planning surface 를 동시에 담고 있다.

---

## 2. Full docs taxonomy restructuring — deferred

`docs/` 전체의 full docs taxonomy restructuring (`docs/roadmap/` 내부 재배치 포함) 은 **deferred** 다. 다음을 의미한다.

- 본 README 가 final docs taxonomy 를 declare 하지 않는다.
- 기존 `docs/roadmap/` root-level 문서의 이동, rename, split, rewrite, 통폐합은 본 README 의 존재로 승인되지 않는다.
- full taxonomy restructuring 은 별도 scoped approval (설계 → 승인 → scoped execute) 절차를 거친다.

---

## 3. Existing root-level roadmap docs — 현재 routing layer

§1 에 enumerate 된 root-level roadmap docs 는 본 README 의 존재와 무관하게 **현재 routing layer** 로 그대로 유지된다.

- 각 root-level 문서의 source-of-truth 책임은 해당 문서 자체의 본문이 정의한다. 본 README 가 그 책임을 대체하거나 재정의하지 않는다.
- 특히 `POST_MVP_PLAN.md` 는 본 README 의 존재와 무관하게 **post-MVP cursor / status** 역할을 유지한다 — completed / deferred / numbered remaining order 의 single source-of-truth 가 그 문서 본문이다.

본 README 는 root-level 문서의 reading order 를 declare 하지 않는다. reading order 는 각 문서의 본문이 안내한다.

---

## 4. Temporary topic namespace — not final taxonomy

`docs/roadmap/` 내부에 향후 등장할 수 있는 **topic subfolder** (예: `docs/roadmap/<topic-name>/`) 는 **temporary topic namespace** 다. final taxonomy 가 아니다.

다음 기준이 동시에 충족될 때에만, 별도 scoped decision 하에 한 개의 topic subfolder 를 만들 수 있다.

- 그 subfolder 가 담을 follow-up planning guide 가 **large** 한 단위라서, 단일 file 로 root-level 에 두면 가독성 / 관리성이 손상된다.
- 그 follow-up planning guide 가 **existing root-level parent document 에 명확히 subordinate** 하다. 즉, 해당 parent 문서가 source-of-truth 이고 subfolder docs 는 그것의 detail / breakdown 이다.
- 그 follow-up planning guide 를 parent 문서에 **직접 병합하면 source-of-truth ambiguity 가 커진다**. (예: parent 문서가 짧은 contract 인데 long-form planning detail 을 그 안에 inline 으로 끌어들이면, 어느 부분이 contract 이고 어느 부분이 derived planning 인지 모호해진다.)

세 조건 중 어느 하나라도 충족되지 않으면 subfolder 를 만들지 않고 root-level 의 단일 문서로 둔다.

subfolder 의 신설 자체도 본 README 의 존재로 자동 승인되지 않는다. case-by-case 의 scoped decision 이 필요하다.

---

## 5. Subfolder docs — parent 를 silently replace / override 하지 않는다

위 §4 의 조건을 충족하여 만들어진 subfolder docs 는 다음 boundary 를 따른다.

- subfolder docs 는 그 parent document 의 source-of-truth 지위를 **silently replace 하지 않는다**. parent 가 source-of-truth 인 영역에서는 parent 의 본문이 우선한다.
- subfolder docs 는 그 parent document 의 결정 / 진술을 **silently override 하지 않는다**. parent 의 결정을 변경해야 한다면 parent 문서 자체의 별도 scoped 수정으로 처리한다 — subfolder 안에서 새 결정을 내려 parent 를 덮어 쓰는 흐름은 금지.
- subfolder docs 의 본문은 자신이 어느 parent 의 subordinate 인지를 본문 안에서 명시적으로 기록한다.

본 boundary 는 final docs taxonomy 가 정해지기 전까지의 interim 규칙이다.

---

## 6. Codex review gate

본 README 의 존재로 source / doc mutation 의 review gate 가 변하지 않는다. `docs/roadmap/` 안의 어떤 source / doc 변경도 다음을 따른다.

- repo 의 정상 Codex review gate 를 거친다 (`scripts/review-prepare.ps1` → `scripts/review-run.ps1` → `scripts/review-verify.ps1 -RequireResult`).
- verdict (`yes` / `no` / `yes with risk`) 는 commit / push / publish / merge / release / adoption 을 자동 승인하지 않는다.
- review verdict 이후의 모든 mutation / global apply / commit / push 는 사용자 명시 결정으로 처리한다.

본 README 자체의 신설도 본 규약을 따른다.

---

## 7. Current example — `global-install-update/` (proposed / temporary)

현 시점에서 **proposed / temporary topic namespace** 로 거론될 수 있는 후보는 `docs/roadmap/global-install-update/` 다. 본 후보의 상태는 다음과 같다.

- **proposed**: §4 의 조건 (large follow-up planning, parent subordinate, parent 병합 시 ambiguity) 가 충족된다고 판단될 때 그 안에 Step 3 관련 follow-up planning guide 가 들어갈 수 있는 후보 namespace 다.
- **temporary**: final taxonomy 의 선언이 아니다. full docs taxonomy restructuring 단계에서 이름 / 위치 / 분류가 다시 결정될 수 있다.
- **현 시점에 namespace 자체가 만들어지지 않았다.** `docs/roadmap/global-install-update/` directory 와 그 안의 Step 3 guide 파일은 본 README 합의 시점에 생성하지 않는다. 실제 namespace 신설과 그 안의 첫 guide 파일 생성은 본 README 와는 별개의 scoped decision 으로 다룬다.
- parent 문서는 `docs/roadmap/GLOBAL_INSTALL_UPDATE_MODEL.md` 다. 향후 `global-install-update/` 가 만들어진다면 그 subfolder 안의 docs 는 본 parent 의 source-of-truth 지위를 §5 대로 유지한다.

본 §7 은 example 의 기록일 뿐이며, namespace 신설 / Step 3 guide 작성 / 그 외 어떤 mutation 도 본 README 의 존재로 자동 승인되지 않는다.

---

## 8. Source-of-truth 관계

- 본 README 는 `docs/roadmap/` 의 interim routing note 다.
- root-level roadmap 문서의 contract / decision 과 본 README 가 상충하면 root-level 문서가 우선한다.
- full docs taxonomy restructuring 시점에 본 README 의 routing note 는 새 taxonomy 의 framing 으로 흡수되거나 deprecate 될 수 있다 — 그 mutation 도 별도 scoped approval 을 거친다.
