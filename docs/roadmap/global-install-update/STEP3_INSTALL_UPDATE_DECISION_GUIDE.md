# Step 3 Install / Update Decision Guide

본 문서는 `ai-harness-toolset` 의 **Step 3 install / update / restore implementation** 방향이 흔들리지 않도록 보존하는 **Step 3-specific decision guide** 다. 본 문서는 부모 문서 `docs/roadmap/GLOBAL_INSTALL_UPDATE_MODEL.md` 의 **subordinate** 이며, 본 문서가 부모 모델을 대체하지 않는다.

본 문서의 존재만으로 어떤 implementation, validation, adoption, release, publish, global / user filesystem mutation, commit / push / merge / release 도 자동 승인되지 않는다.

---

## 1. Role of this document

본 문서는 `docs/roadmap/GLOBAL_INSTALL_UPDATE_MODEL.md` 의 **Step 3-specific decision guide** 다. 다음 역할을 갖는다.

- ChatGPT Web 세션, 사용자, Claude Code, Codex reviewer 가 향후 Step 3 관련 scope 정의 prompt / handoff / review input 을 작성할 때 참조할 **stable reference** 다.
- `POST_MVP_PLAN.md` §11 step 3 (`install / update implementation`) 작업이 어떤 방향성·boundary·decomposition·caveat 을 따라야 하는지를 한 자리에 모아 둔 **planning guide** 다.

본 문서는 다음이 **아니다**.

- 부모 모델 `docs/roadmap/GLOBAL_INSTALL_UPDATE_MODEL.md` 의 대체.
- `docs/roadmap/POST_MVP_PLAN.md` 의 대체.
- final docs taxonomy declaration. 본 문서가 위치한 `docs/roadmap/global-install-update/` 는 **proposed / temporary topic namespace** 이며 (`docs/roadmap/README.md` §4, §7), final docs taxonomy 가 정해지면 이름 / 위치 / 분류가 다시 결정될 수 있다.
- Step 3 implementation 의 승인. 본 문서는 plan / direction guide 일 뿐, scoped implementation approval 은 별도로 받는다.
- `yes` / `no` / `yes with risk` 어느 verdict 의 자동 승인도 아니다.

**Root-level parent docs remain authoritative where they define source-of-truth responsibilities.** 본 문서의 wording 이 부모 root-level docs (`GLOBAL_INSTALL_UPDATE_MODEL.md`, `POST_MVP_PLAN.md`, `GLOBAL_ADOPTION_DECISION.md`, `GLOBAL_ADOPTION_PROCEDURE.md`, `SHARED_GLOBAL_INVOCATION_CONTRACT.md`, `TOOLROOT_PROJECTROOT_AUDIT.md`, `CLEAN_TARGET_SMOKE_CRITERIA.md`) 의 contract / decision 과 충돌하면 root-level docs 가 우선한다. 또한 본 문서는 `docs/REVIEW_RESULT_CONTRACT.md`, `docs/BRIEF_CONTRACT.md`, `docs/CHATLOG_CONTRACT.md` 등 repo contract docs 의 source-of-truth 지위를 격하하지 않는다.

`docs/roadmap/README.md` 가 `docs/roadmap/` 의 **interim routing rule** 을 정의한다. 본 문서가 속한 topic namespace 의 생성·운영 boundary 는 그 routing rule (특히 §4 temporary topic namespace 조건, §5 parent 와의 boundary, §7 `global-install-update/` example) 을 따른다.

---

## 2. Decision lineage

본 문서는 다음 세 단계의 논의를 **repo docs 안에 정규화한 결과** 다.

- **Step 3 planning discussion** — install / update / restore 를 같은 source-authoritative overwrite materialization primitive 로 묶고, layer 분리·non-goal·Step 3 decomposition 을 정리한 ChatGPT Web 세션의 planning 단계.
- **Claude Code / Codex cross-review** — 위 planning 결과에 대해 Claude Code 의 independent review 와 Codex 의 independent / final cross-review 가 수행된 단계. 최종 verdict 은 **`yes with risk`** 였고, 그 verdict 와 carry-forward caveats 는 본 가이드 §7 / §9 에 그대로 보존된다.
- **ChatGPT Web supervisor judgment** — 위 cross-review 결과를 repo docs 로 anchoring 하라는 판단. 본 가이드의 작성을 트리거한 step.

위 세 단계의 정규화 순서는 다음과 같다.

```
Step 3 planning discussion
  → Claude / Codex cross-review
  → ChatGPT Web supervisor judgment
  → repo docs guide (본 문서, 그리고 부모 root-level docs 의 concise pointer)
```

본 가이드는 위 세 단계의 raw transcript 또는 임시 planning / review artifact 를 그대로 옮기지 않는다. 그 안의 decision 과 carry-forward caveats 를 **non-source-of-truth planning material** 로 취급한 뒤, 본 repo doc 의 정합성을 위해 정리·압축·boundary 화한 결과만 남긴다.

**Repo 밖 임시 planning / review artifact 는 stable source-of-truth 가 아니며, future handoff / future sessions 에서 접근 가능하다고 전제하지 않는다.** 본 가이드는 그 임시 artifact 의 파일 경로 / 파일명을 long-lived 참조 대상으로 보존하지 않는다. 위 세 단계의 결정과 verdict 이 향후에도 유효하다는 사실은 본 가이드 본문과 부모 root-level docs (특히 `docs/roadmap/GLOBAL_INSTALL_UPDATE_MODEL.md`) 에 anchored 되어 있다.

따라서 향후 Step 3 scope definition, handoff, Codex review input 은 **본 가이드와 parent repo docs 를 기준으로 한다.** 임시 planning / review artifact 의 별도 조회를 전제하지 않는다.

---

## 3. Fixed Step 3 direction

본 문서가 보존하는 **core principle** 은 다음 한 줄이다.

```
install / update / restore = source-authoritative overwrite materialization
```

세 mode 의 정합 규칙:

- install / update / restore 는 같은 primitive 의 서로 다른 **source/ref resolution path** 다. 별도 철학의 별도 기능이 아니다.
- source-of-truth 는 **GitHub repo URL 또는 local clone** 이다. 그 외 채널 (release asset, package registry, manual copy 등) 은 Step 3 source-of-truth 가 아니다.
- 공통 flow:

  ```
  resolve source/ref
    → deterministic overwrite materialization
    → write/update metadata
    → verify
    → report
  ```

- update 는 **metadata-dispatched re-materialization** 이다. destination 의 diff 를 분석해서 patch 하는 동작이 아니다.
- restore 는 **source/ref-based re-materialization** 이다. 깨진 파일만 ad-hoc 으로 고치는 repair 가 아니다. 본 문서가 채택하는 입장은 다음 두 가지 중 **3-1 단계에서 선택** 한다 — (a) metadata 에 known-good / ref retention 을 정의하여 그 기준으로 re-materialize, 또는 (b) restore 를 user-specified ref-only 로 제한. 자세한 caveat 은 §7 참조.

mode-별 차이는 source/ref 를 어디서 얻는가뿐이며, 그 이후 materialization core / metadata write / verify / report 단계는 동일하다.

---

## 4. Non-goals and drift exclusions

Step 3 는 다음을 명시적으로 **배제** 한다. 본 문서가 존재한다는 사실로 아래 어느 항목도 자동 승인되지 않는다.

운영 / behavior drift:

- manual copy 를 normal / recommended path 로 권고하는 framing.
- destination merge.
- partial patch update.
- user-edit preservation (destination 의 user 편집을 보존하기 위한 conditional skip / merge).
- interactive file-by-file decision UX.

release / packaging drift:

- `releaseVersion`, `releaseTag` 같은 release 식별자.
- GitHub Release asset, release asset checksum.
- CI/CD publish pipeline.
- package registry / package publish.

scope drift:

- Step 4 (install / update validation) 동작의 Step 3 안 수행.
- self-adoption (`ai-harness-toolset` 자체의 self-target 운영) 의 Step 3 안 수행.
- GJMNet adoption 의 Step 3 안 수행.
- BF Level 3 (deterministic Brief maintenance / validation / restore-offer / stale warning / session-start guidance) 의 Step 3 안 implementation.
- Chatlog system 의 fuller implementation.
- 실제 `%USERPROFILE%\.claude` / `%USERPROFILE%\.codex` global / user filesystem mutation 의 수행.
- commit / push / publish / merge / release / adoption 의 승인.

위 항목은 부모 `GLOBAL_INSTALL_UPDATE_MODEL.md` §12 (Explicit non-goals) 및 `POST_MVP_PLAN.md` §8 (Hard guardrails) 의 boundary 와 정합하며, 본 문서가 그것을 약화시키지 않는다.

---

## 5. Layer separation

Step 3 구현물은 다음 5 개 layer 를 명확히 분리한다.

- **source reference layer** — 무엇을 기준으로 덮어쓸 것인가 (GitHub URL 또는 local clone).
- **install control-plane layer** — 누가 덮어쓰기 작업을 수행할 것인가 (installer command / library).
- **runtime payload layer** — 덮어쓰기 결과로 global Claude layer 가 invocation 시 사용하는 것 (현재의 `config/`, `scripts/`, `snippets/`, `templates/`).
- **install metadata layer** — 다음 update / restore 시 기준으로 읽는 기록 (`install.json` 등; `GLOBAL_INSTALL_UPDATE_MODEL.md` §5).
- **tests/docs layer** — 위 layer 의 검증 / 문서.

고정 boundary:

- `%USERPROFILE%\.claude\ai-harness-toolset\current\` 는 **runtime payload only** 다. installer / control-plane 또는 install metadata 가 `current/` **안에** 들어가지 않는다.
- installer / control-plane 은 `current/` 와 sibling 으로 분리한다 (예: `%USERPROFILE%\.claude\ai-harness-toolset\installer\`).
- install metadata 는 `current/` **안에** 두지 않는다. global install area 의 sibling 위치에 둔다 (예: `%USERPROFILE%\.claude\ai-harness-toolset\install.json`).
- **target project 에 installer files 를 설치하지 않는다.**
- **target project 에 install metadata 를 두지 않는다.**
- target project 의 persistent footprint 는 `<ProjectRoot>/log/` only 다 (`GLOBAL_INSTALL_UPDATE_MODEL.md` §8 — 3차 reconciliation 기준; BRIEF / Chatlog / Evidence / Review 모두 `log/` 아래).
- repo runtime payload roots 는 `config/`, `scripts/`, `snippets/`, `templates/` 로 유지된다. 본 문서는 그 root set 을 변경하지 않는다. 향후 변경이 필요하다면 **별도 scoped decision** (예: 3-0 layer layout 결정의 결과로서) 이다.
- installer / control-plane root 의 정확한 경로 (예: repo 안 `installer/`, global install area 안 `installer/`, `source-cache/` 등) 와 global install area 의 새 directory 도입 여부는 **본 가이드에서 finalize 하지 않는다**. 이는 3-0 / 3-1 의 scoped decision 항목이다 (§7 carry-forward caveats 참조).

---

## 6. Step 3 decomposition

Step 3 의 canonical decomposition 은 다음 9 단계다.

```
3-0. install / update layer layout decision
3-1. global install metadata contract
3-2. source / ref resolver
3-3. overwrite materialization core
3-4. install / update / restore dispatcher
3-5. verify path
3-6. managed block / skill replace boundary
3-7. dry-run tests
3-8. minimal docs closeout
```

해석 규칙:

- 위 분해는 Step 3 direction 의 **canonical** decomposition 이다. 향후 prompt / scope definition / Codex review input 은 본 9 단계를 기준선으로 삼는다.
- 실제 implementation 시 operational batch 는 위 단계를 더 잘게 split 하여 운영할 수 있다 (예: source-side script 단위 batch, doc-only batch 등). 단, **operational batch 는 반드시 canonical 9 단계 중 하나 이상에 map back** 되어야 하며, 새 단계를 임의로 추가하지 않는다.
- **3-0 이 metadata contract 보다 먼저** 온다. layer 가 결정되지 않은 상태에서 schema / metadata 설계가 진행되면 layer 가 schema 에 의해 사후 결정되는 역전 위험이 있다. 따라서 layer layout 결정 → metadata / schema 설계 순서를 보존한다.
- 3-6 (managed block / skill replace boundary) 은 install / update automation **본체 밖** 의 explicit user-approved global / user config mutation scope 와 boundary 를 공유한다 (`GLOBAL_INSTALL_UPDATE_MODEL.md` §1, §12; `GLOBAL_ADOPTION_DECISION.md` §6). 본 단계는 boundary 정의이며, automation 본체를 managed block apply 까지 자동 확장하라는 의미가 아니다.
- 3-7 (dry-run tests) 는 실제 `%USERPROFILE%\.claude` / `%USERPROFILE%\.codex` 가 아닌 temp destination 을 대상으로 한다. 실제 global / user mutation 의 validation 은 Step 4 또는 별도 scoped approval 의 영역이다.
- 3-8 (minimal docs closeout) 은 Step 3 완료 시 docs 를 보강하는 단계로, 본 가이드 자체를 포함한 docs taxonomy 의 광범위한 restructuring 을 자동 승인하지 않는다.

---

## 7. Carry-forward caveats from cross-review

본 문서는 §2 의 Claude / Codex cross-review 단계에서 도출된 finding 과 merged conclusion 을 다음 caveat 으로 carry 한다. 향후 Step 3 관련 prompt / handoff / scope definition / Codex review input 은 본 §7 의 caveat 을 명시적으로 함께 운반한다.

1. **restore known-good semantics 의 underspecification.** restore 의 운영 의미가 repo source-of-truth 에서 install / update 보다 덜 구체적이다. **3-1 단계에서 다음 둘 중 하나를 명시적으로 정의** 한다 — (a) metadata 에 known-good / ref retention 을 정의하여 그 기준으로 restore re-materialize, 또는 (b) restore 를 **user-specified ref only** 로 제한 (metadata-derived known-good 자동 추출 금지).
2. **managed block / skill refresh 는 install / update automation 본체 밖.** global `CLAUDE.md`, Codex `AGENTS.md`, Claude skill refresh 의 적용은 automation 본체에 포함되지 않으며, `GLOBAL_INSTALL_UPDATE_MODEL.md` §1 / §12 와 `GLOBAL_ADOPTION_DECISION.md` §6 의 explicit user-approved global / user config mutation scope 로 분리된다. 3-6 단계는 boundary 정의 / source snippet 기준 marker-bounded replace 의 책임 한정이며, automation 본체가 managed block 까지 자동 apply 하라는 의미가 아니다.
3. **metadata 필드 / 예시는 부모 모델과 reconcile.** planning 단계에서 거론된 metadata example (예: `payloadRoot` / `installerRoot` / `metadataPath` 같은 추가 field, `installedAt` / `lastUpdatedAt` / `targetFootprintPolicy` 같은 누락 field) 은 planning-stage example 일 뿐이다. **3-1 단계에서 부모 `GLOBAL_INSTALL_UPDATE_MODEL.md` §5.2 의 minimal field set 과 정합화** 한다. 부모 §5.2 의 field 가 우선이며, 추가 field 는 별도 scoped decision 으로 도입한다.
4. **installer/ 와 source-cache/ 는 fixed directory contract 가 아니다.** planning 단계에서 거론된 `installer/` / `source-cache/` 같은 global install area 신규 directory 후보는 planning example 이며, repo source-of-truth 에 명시되지 않은 신개념이다. 도입 여부 / 정확한 위치 / 이름은 **3-0 (layer layout) 과 3-1 (metadata contract) 의 scoped decision 항목** 으로 carry 한다.
5. **corrupted / incomplete `current/` payload 의 분기는 open question.** dispatcher 가 `current/` payload 가 손상 또는 불완전한 상태로 시작될 때 어떤 mode 로 처리할 것인지 (restore default 여부 포함) 가 명시되지 않았다. **3-4 dispatcher 단계의 open question 으로 carry** 한다.
6. **baseline commit hash 는 review context only.** planning / cross-review 단계에 등장한 baseline commit hash (예: 그 단계의 HEAD 표기), 또는 본 문서가 작성된 시점의 baseline hash 는 review context 로만 허용된다. **long-lived repo doc 의 hardcoded baseline 으로 promote 하지 않는다** (`docs/backlog/operations.md` "Long-lived docs commit hash hygiene" 항목과 정합).
7. **"docs as boundary/reference" wording 의 의미 한정.** planning 단계의 decision checklist 에 등장한 "docs as boundary/reference, not behavior source-of-truth" 식의 표현은 **repo contract docs / parent roadmap docs 의 source-of-truth 지위를 격하하는 의미가 아니다.** 본 문서 §1 의 "root-level parent docs remain authoritative" 와 함께 read 한다.
8. **canonical decomposition (9 단계) vs 권장 operational batch (10 단계) numbering 차이.** planning 단계에서 canonical decomposition (3-0..3-8, 9 단계) 과 권장 operational batch (3-0..3-9, 10 단계) 의 numbering 이 1 단계씩 어긋난 채 제시되었다 — operational batch 쪽이 canonical 3-0 을 "read-only" / "source/doc decision" 두 batch 로 split. 본 가이드 §6 는 **canonical 9 단계를 채택**하며, 10 단계 numbering 은 **operational batch 분해** 로만 사용한다.
9. **"optional control-plane copy" wording 의 의미 한정.** planning 단계에서 거론된 "optional control-plane copy" 표현은 "installer 자체가 optional" 이 아니라 "global install area 에 installer 의 copy 를 materialize 할 것인지가 optional" 의 의미다. 본 문서 §5 의 layer boundary 와 정합한다.

본 §7 의 caveat 은 향후 prompt / handoff / Codex review input 의 carry-forward 대상이다. caveat 누락은 본 가이드의 의도된 사용 방식이 아니다.

---

## 8. Usage rules for future prompts

본 가이드의 사용 / 적용 boundary 는 다음과 같다.

- **source / doc mutation batch 는 Codex review gate 를 거친다.** Step 3 관련 source-file (`installer/`, `tests/installer/`, 또는 본 가이드 / 부모 docs 의 본문) 변경은 정상 review subsystem (`scripts/review-prepare.ps1` → `scripts/review-run.ps1` → `scripts/review-verify.ps1 -RequireResult`) 을 통과한다.
- **review verdict 는 commit / push / publish / merge / release / adoption 을 자동 승인하지 않는다** (`docs/REVIEW_RESULT_CONTRACT.md`, `POST_MVP_PLAN.md` §2, §8).
- **실제 global / user filesystem mutation 은 별도 explicit approval boundary** 다 (`GLOBAL_INSTALL_UPDATE_MODEL.md` §12, `GLOBAL_ADOPTION_DECISION.md` §6). 본 가이드가 그것을 자동 승인하지 않는다.
- **commit / push 는 본 가이드의 verdict 와 무관한 별도 explicit approval boundary** 다. 본 가이드는 commit / push 를 승인하지 않는다.
- **본 가이드는 implementation, validation, adoption, release, publish, push 의 어느 것도 승인하지 않는다.** plan / direction guide 일 뿐이다.
- **향후 Claude Code prompt 는 본 §7 의 carry-forward caveats 를 명시적으로 함께 운반** 한다. caveat 누락 상태로 작성된 Step 3 scope 정의 prompt 는 본 가이드의 의도된 사용 방식이 아니다.
- **Codex review input for Step 3 work 는 본 가이드를 `GLOBAL_INSTALL_UPDATE_MODEL.md` 의 subordinate 로 취급** 한다. 두 문서가 충돌하면 부모 `GLOBAL_INSTALL_UPDATE_MODEL.md` 가 우선한다. 본 가이드가 부모 모델의 결정을 silently override 하지 않는다 (`docs/roadmap/README.md` §5).

---

## 9. Final verdict carried from cross-review

§2 의 Claude / Codex cross-review 단계에서 도출된 최종 verdict 는 다음과 같이 본 가이드에 보존된다.

```
yes with risk
```

verdict 의미: §2 의 planning discussion 결과는 non-source-of-truth Step 3 planning reference 로 사용 가능하다. 단 본 가이드의 §7 carry-forward caveats 가 향후 prompt / handoff / scope definition / Codex review input 에 명시적으로 함께 운반되어야 한다.

위 verdict 는 commit / push / publish / merge / release / adoption 또는 Step 3 implementation 의 자동 승인이 아니다.

---

## 10. Recorded 3-0 layer layout decision

본 절은 §6 의 canonical decomposition 9 단계 중 첫 단계 — **3-0 install / update layer layout decision** — 의 결정 shape 를 repo source-of-truth 로 anchor 한다. 본 anchor 는 §5 (Layer separation) 의 fixed boundary 를 약화하지 않으며, §7 (Carry-forward caveats) 의 항목과 충돌하지 않는다. 본 anchor 는 layer 의 종류 / boundary / mutability / lifecycle 분류만 기록하며, 정확한 file / directory 이름, metadata schema 필드, installer materialization default 등은 본 anchor 의 범위 밖이고 후속 sub-step (3-1 ~ 3-8) 의 scoped decision 으로 carry 된다.

본 anchor 는 implementation, schema design, install / update / restore 의 actual 실행, global / user filesystem mutation, target adoption, commit / push / publish / merge / release / Step 4 validation 어느 것도 자동 승인하지 않는다. 본 anchor 의 source / doc mutation 자체는 본 도구의 정상 review gate 를 거친다 (§8 와 정합).

### 10.1 Layer category 분류

본 anchor 가 인정하는 layer category 는 다음 5 가지다. 각 layer 의 정확한 path-name / directory layout 은 본 anchor 가 fix 하지 않는다 — boundary level 의 분류만 기록한다.

| layer | repo-side 위치 (현행) | global install area 위치 (boundary) | mutability | lifecycle action |
|---|---|---|---|---|
| **runtime payload** | `config/`, `scripts/`, `snippets/`, `templates/` (root set 유지 — 변경은 별도 scoped decision) | `current/` 안 | install 후 read-only | overwrite materialization (§3) |
| **install control-plane** | repo-side root 후보 (path-name 미확정 — 3-1 ~ 3-3 단계 carry) | `current/` 와 **sibling**; global install area 에 control-plane copy 를 materialize 할지는 §7 #9 의 의미상 optional | install 후 read-only | install metadata 기준 dispatch (§3) |
| **install metadata** | source repo 에는 schema / example 만 (instance 금지) | `current/` 와 **sibling**; JSON | append-on-update | install / update 시 write (`GLOBAL_INSTALL_UPDATE_MODEL.md` §5) |
| **source-cache** (optional) | — | layer 도입 여부 자체가 deferred (§7 #4) | — | 본 anchor 가 layer 를 도입하지 않는다 |
| **tests / docs** | `tests/`, `docs/` | runtime payload 아님 → `current/` 외부 | source-managed | install / update payload 대상 아님 |

### 10.2 `current/` 포함 / 제외 명시

`current/` 는 **runtime payload only** 다 (§5 와 정합). 다음 항목은 어느 경우에도 `current/` 안에 들어가지 않는다.

- install control-plane code / installer source.
- install metadata instance (정확한 filename 은 3-1 단계 carry).
- source-cache (layer 도입 시에도 `current/` 밖).
- repo `tests/`, `docs/`.
- runtime / state artifact (`<ProjectRoot>/log/` 아래 — 별개 ProjectRoot tree).
- Claude skill SKILL.md (`%USERPROFILE%\.claude\skills/` 별도 위치).
- global instruction file content (`%USERPROFILE%\.claude\CLAUDE.md`, `%USERPROFILE%\.codex\AGENTS.md` 등 별도 destination).
- ad-hoc backup / archive / snapshot.

`current/` 안에 위 어느 항목이 materialize 되면 §5 의 fixed boundary 위반이다.

### 10.3 Target project footprint 보존

target project 에 대한 footprint 결정은 다음을 보존한다 (`GLOBAL_INSTALL_UPDATE_MODEL.md` §8 와 정합).

- target project 는 install control-plane / installer source 를 **받지 않는다**.
- target project 는 install metadata instance 를 **받지 않는다**.
- target project 의 persistent footprint 는 `<ProjectRoot>/log/` only (3차 reconciliation 기준; BRIEF / Chatlog / Evidence / Review 모두 `log/` 아래).
- forbidden target path: `.ai-harness/`, target 안의 `scripts/` / `config/` / `templates/` / `snippets/` 사본, ai-harness 전용 `CLAUDE.md` / `AGENTS.md`, root `<ProjectRoot>/brief/`, user-home operator-local runtime root.

### 10.4 Install metadata 위치 (boundary level only)

본 anchor 는 metadata 의 정확한 filename / path 를 fix 하지 않고 boundary 만 결정한다.

- metadata instance 는 global install area 의 `current/` 와 **sibling** 위치에 둔다.
- format 은 JSON.
- `current/` **안** 에는 두지 않는다 (§5).
- target project **안** 에는 두지 않는다 (`GLOBAL_INSTALL_UPDATE_MODEL.md` §5.1).
- source repo 의 tracked instance 로 두지 않는다 (`GLOBAL_INSTALL_UPDATE_MODEL.md` §5.1; source repo 에는 schema / example 만 허용).

정확한 filename 과 schema field set 은 **3-1 단계의 scoped decision** 으로 carry (§7 #3 과 정합). 부모 `GLOBAL_INSTALL_UPDATE_MODEL.md` §5.2 의 minimal field set 이 3-1 단계의 baseline 이다.

### 10.5 installer / source-cache 결정 (deferred 범위 보존)

- **installer / control-plane** — layer category 자체는 본 anchor 가 인정한다 (§10.1). global install area 의 정확한 path-name, repo-side control-plane root 의 위치, materialization default (optional materialization 의 on / off default), 모두 **3-1 ~ 3-3 단계의 scoped decision** 으로 carry (§7 #4, #9 와 정합).
- **source-cache** — 본 anchor 가 layer 도입 자체를 채택하지 **않는다.** install-from-git-url mode 의 source clone 위치가 `current/` 와 어떻게 격리될지의 필요성이 3-3 / 3-4 단계에서 드러나면 그때 layer 신설 여부를 재평가 (§7 #4 와 정합).

### 10.6 Managed-block / skill refresh boundary 보존

본 anchor 는 다음 boundary 를 약화시키지 **않는다** (`GLOBAL_INSTALL_UPDATE_MODEL.md` §1 / §12, §7 #2 와 정합).

- global instruction file (`%USERPROFILE%\.claude\CLAUDE.md`, `%USERPROFILE%\.codex\AGENTS.md` 또는 `%CODEX_HOME%\AGENTS.md`, Codex user-global `AGENTS.override.md`, project-root `CLAUDE.md` / `AGENTS.md`) 의 managed-block apply 는 install / update automation **본체 밖** 이다. `GLOBAL_ADOPTION_DECISION.md` §6 의 explicit user-approved managed-block insert / replace scope 가 governing 한다.
- Claude skill SKILL.md install / update / removal 은 `GLOBAL_ADOPTION_PROCEDURE.md` 가 source-of-truth 인 별도 절차다. install / update automation 본체가 자동으로 skill 을 refresh 하지 않는다.
- automation 본체의 trigger / verdict 는 managed-block apply 나 skill refresh 를 묶음으로 자동 승인하지 않는다.
- forbidden path `%USERPROFILE%\.claude\AGENTS.md` 는 어느 scope 에서도 생성하지 않는다.

3-6 (managed block / skill replace boundary) step 은 위 boundary 의 **정의 / 진단 helper** 만 다루며, install / update automation 본체를 managed block apply 까지 확장하라는 의미가 아니다 (§6 와 정합).

### 10.7 본 anchor 의 scope 와 non-goals

본 anchor 는 다음을 **포함한다**.

- §10.1 의 5 layer category 분류 및 그 boundary 결정.
- `current/` 의 runtime-payload-only 경계 (§10.2).
- target footprint = `<ProjectRoot>/log/` only 경계 (§10.3).
- install metadata 의 sibling-of-`current/` + JSON boundary (§10.4).
- installer / source-cache 의 deferred carry (§10.5).
- managed-block / skill refresh 의 automation 본체 밖 boundary (§10.6).

본 anchor 는 다음을 **포함하지 않는다.**

- installer / control-plane 의 정확한 path-name, repo-side control-plane root 위치, materialization default.
- source-cache layer 의 도입 / 미도입 final.
- install metadata 의 정확한 filename, schema field set.
- `current/` payload completeness marker (entrypoint set) 의 finalize.
- payload integrity 검증 알고리즘 (aggregate digest vs per-file manifest; `docs/backlog/operations.md` "Aggregate digest reproducibility" 항목이 별도 carry).
- 3-1 ~ 3-8 단계의 implementation 또는 schema design.
- install / update / restore 의 actual 실행, global / user filesystem mutation, target adoption, commit / push / publish / merge / release.

본 anchor 는 `yes` / `no` / `yes with risk` 어느 verdict 의 자동 승인도 아니다. anchor 의 source / doc mutation 자체는 본 도구의 정상 review gate 를 거치며, review verdict 이후의 commit / push / global apply 는 사용자 명시 결정으로 처리한다 (§8 와 정합).

---

## 11. Recorded 3-1 install metadata contract decision

본 절은 §6 canonical decomposition 의 두 번째 단계 — **3-1 global install metadata contract** — 의 결정 shape 를 repo source-of-truth 로 anchor 한다. 본 anchor 는 §10 의 3-0 layer layout decision 위에 build 되며, 부모 `GLOBAL_INSTALL_UPDATE_MODEL.md` §5 (global install metadata) 의 minimum field set 을 baseline 으로 채택한다. 본 anchor 는 §5 (Layer separation), §7 (Carry-forward caveats), §10 (3-0 anchor) 의 결정을 약화하지 않는다.

본 anchor 는 schema 의 contract 의미 (field 분류 / lifecycle / restore semantics / boundary) 만 기록한다. 실제 schema 파일 작성, JSON validator, writer / reader implementation, dispatcher 통합, payload integrity manifest design 은 본 anchor 의 범위 밖이며 후속 sub-step (3-3 ~ 3-5) 또는 별도 scoped goal 의 일이다.

본 anchor 는 implementation, install / update / restore 의 actual 실행, global / user filesystem mutation, target adoption, commit / push / publish / merge / release / Step 4 validation 어느 것도 자동 승인하지 않는다.

### 11.1 Minimum field set (parent §5.2 baseline)

부모 `GLOBAL_INSTALL_UPDATE_MODEL.md` §5.2 의 14-field set 을 minimum required 의 baseline 으로 채택한다. 본 anchor 는 본 set 에 field 를 추가하거나 제거하지 않는다.

- `schemaVersion`
- `tool`
- `installMode` (`git-url` | `local-clone`)
- `repoUrl`
- `sourcePath`
- `toolRoot`
- `branch`
- `remote`
- `installedHead`
- `lastUpdatedHead`
- `installedAt`
- `lastUpdatedAt`
- `targetFootprintPolicy` (현행값 `log-only` — 3차 reconciliation 기준; 부모 §5.2 와 정합)
- `managedBy` (현행값 `claude-code`)

**Mode-conditional required.**

- `repoUrl` 은 `installMode == git-url` 일 때 required.
- `sourcePath` 는 `installMode == local-clone` 일 때 required.
- 사용되지 않는 mode 의 field 가 absent 인지 `null` 인지의 표현은 3-3 / 3-4 단계 writer / reader 결정이며 본 anchor 가 fix 하지 않는다.

### 11.2 Metadata instance location and canonical filename

본 anchor 는 §10.4 의 boundary 를 그대로 유지하며 filename 을 1 개로 fix 한다.

- **위치**: global install area 의 `current/` 와 **sibling** (예: `%USERPROFILE%\.claude\ai-harness-toolset\install.json`).
- **format**: JSON.
- **canonical filename**: **`install.json`** (본 STEP3 guide §5 example 과 일관).
- **금지**:
  - `current/` **안** 에 두지 않는다 (§5, §10.2).
  - target project **안** 에 두지 않는다 (`GLOBAL_INSTALL_UPDATE_MODEL.md` §5.1, §10.3).
  - source repo 의 tracked instance 로 두지 않는다 (`GLOBAL_INSTALL_UPDATE_MODEL.md` §5.1; source repo 에는 schema / example 만 허용).
  - user-home 의 ai-harness-specific 별도 root (예: `%USERPROFILE%\.ai-harness\...`) 에 두지 않는다.

부모 `GLOBAL_INSTALL_UPDATE_MODEL.md` §5.1 의 placeholder `install-metadata.json` 은 본 anchor 의 filename 결정과 다르지만, 부모 §5.1 본문이 "정확한 파일명 / 위치는 implementation 단계에서 확정한다" 로 placeholder 임을 명시하므로 부모 본문 mutation 없이 본 STEP3 guide 의 canonical 결정이 우선한다 (`docs/roadmap/README.md` §5 의 subordinate-specifies-more-concretely boundary 와 정합). 부모 본문의 placeholder 는 alternative naming example 로 historical 보존되며, 본 anchor 와 충돌 시 본 §11 이 우선한다.

### 11.3 `schemaVersion` semantics

- type: integer.
- initial value: `1` (현행 baseline schema 의 version).
- bump policy: field add / remove / 의미 변경 시 monotonically increment.
- reader 동작: unknown / 미지원 `schemaVersion` 은 **fail-fast**. silent 하게 default 또는 lowest known 으로 downgrade 하지 않는다.
- migration writer (bump 시 기존 metadata 의 자동 conversion 절차) 는 본 anchor 의 범위 밖 — 별도 scoped decision.

### 11.4 Restore semantics

본 anchor 는 §3 + §7 #1 의 binary choice 중 **(b) user-specified ref-only restore** 를 채택한다.

- restore 호출 시 사용자가 명시한 ref (commit SHA / tag / branch) 를 dispatch source 로 사용한다.
- metadata 는 source / ref **descriptive** 만 유지한다. metadata 의 `repoUrl` / `branch` / `sourcePath` / `toolRoot` 는 "어디서 ref 를 받아올지" 의 dispatch hint 로만 사용한다.
- metadata-derived known-good ref 의 **자동 추출 / 자동 fallback 금지** (§7 #1 의 명시 wording 과 정합).
- known-good metadata field (예: `knownGoodHead`, `lastKnownGoodAt`) 는 본 anchor 에 도입하지 않는다. 도입은 §7 #1 (a) option 채택의 별도 scoped decision 이며, 그 결정은 본 anchor 와 분리된다.

본 (b) 채택의 근거: (a) known-good metadata 채택은 writer / state-machine layer 를 도입하며 `POST_MVP_PLAN.md` §5 의 "automatic decision-maker 금지" 와 충돌 risk; (b) 는 metadata 를 단순 descriptive 로 유지하며 §7 #1 의 "자동 추출 금지" wording 과 자연 정렬한다.

### 11.5 Lifecycle

| action | metadata write | metadata read |
|---|---|---|
| **install (최초)** | 14 required field 모두 write. `installedHead == lastUpdatedHead`. `installedAt == lastUpdatedAt`. | (해당 없음 — 신규 instance) |
| **update — "업데이트 받아"** | `lastUpdatedHead`, `lastUpdatedAt` 갱신. `installedHead`, `installedAt` 보존. | `installMode` dispatch (`git-url`: `repoUrl` / `branch` / `remote` / `toolRoot`; `local-clone`: `sourcePath` / `toolRoot`). 부모 §4.2 / §4.3 와 정합. |
| **update — "현재 최신 버전 기준으로"** | source 의 current HEAD 사용. `lastUpdatedHead`, `lastUpdatedAt` 갱신. 나머지 보존. | `installMode` dispatch (source 는 건드리지 않음). 부모 §4.4 와 정합. |
| **restore (§11.4 의 (b))** | restore 진행 중 metadata 변경 없음 (read-only). 성공적 re-materialization 완료 후 `lastUpdatedHead`, `lastUpdatedAt` 갱신 (update path 와 동일). | dispatch hint 로 `repoUrl` / `sourcePath` / `toolRoot` 사용. ref 는 사용자 명시. |
| **source-cut change (`installMode` / `repoUrl` / `sourcePath` / `toolRoot` / `branch` / `remote` 변경)** | 본 라운드 update / restore 의 자동 변경 대상 **아니다**. **별도 explicit user-approved scope** 가 필요하다. | — |

본 lifecycle 은 §3 의 source-authoritative overwrite materialization 원칙과 정합한다 — metadata 는 destination diff 를 분석하지 않으며, source HEAD 의 변화를 그대로 기록한다.

### 11.6 Deferred items (3-1 에서 fix 하지 않음)

본 anchor 는 다음을 fix 하지 않는다. 각각은 후속 단계 또는 별도 scoped decision 으로 carry 된다.

- **payload integrity manifest**: algorithm / 위치 / 이름 / schema 가 본 anchor 의 범위 밖. metadata schema 본체에 inline field 로 들어가지 않으며, 별도 동행 manifest 형태로 분리된다 (`docs/backlog/operations.md` "Aggregate digest reproducibility — install/update verification scope debt" 항목과 정합). manifest 의 위치는 §10.4 boundary (sibling-of-`current/`) 와 정합해야 한다.
- **payload completeness marker (entrypoint set)**: channel 3 활성 조건의 marker 는 dispatcher (3-4) 의 영역이며 metadata schema 의 영역이 아니다.
- **installer 관련 field** (예: `installerRoot`): §10.5 의 installer materialization deferred 와 connection. installer materialization default 가 결정되기 전까지 본 anchor 에 도입하지 않는다.
- **source-cache 관련 field**: §10.5 의 source-cache layer 미도입과 정합. layer 가 도입되지 않으면 metadata field 도 도입하지 않는다.
- **`schemaVersion` migration writer**: bump 시 migration 절차는 별도 scoped decision.

### 11.7 Forbidden fields and semantics

본 anchor 는 다음을 metadata schema 에 도입하는 것을 **금지** 한다 (별도 scoped decision 이 명시적으로 허용하기 전까지).

- `releaseVersion`, `releaseTag`, GitHub Release asset checksum, package registry 식별자 — §4 drift exclusion.
- user-edit preservation flag (target 의 user 편집 보존을 위한 conditional skip / merge 의도) — §4 drift exclusion.
- 자동 managed-block apply trigger field (예: "metadata write 시 global `CLAUDE.md` 도 함께 갱신" 같은 자동화 표시) — `GLOBAL_ADOPTION_DECISION.md` §6 / `GLOBAL_INSTALL_UPDATE_MODEL.md` §1 / §12 / §10.6 의 boundary 와 충돌.
- 자동 skill refresh trigger field — `GLOBAL_ADOPTION_PROCEDURE.md` 의 별도 절차와 충돌.
- `payloadRoot`, `installerRoot`, `metadataPath` 같은 **self-reference layer-fix field** — §7 #3 의 planning-example 단계 wording 과 정합; 도입은 별도 scoped decision.
- `knownGoodHead`, `lastKnownGoodAt` 같은 **known-good 자동 field** — §11.4 의 (b) restore semantics 와 충돌.
- daemon / watcher / scheduler 식별자 — `POST_MVP_PLAN.md` §5 / §8 의 forbidden 항목과 정합.

위 항목은 본 anchor 가 명시적으로 거부하는 set 이며, 향후 schema 변경이 본 set 의 어느 항목이라도 도입하려면 별도 scoped goal 의 explicit user-approved decision 이 필요하다.

### 11.8 본 anchor 의 scope 와 non-goals

본 anchor 는 다음을 **포함한다**.

- §11.1 의 14-field minimum baseline (mode-conditional required 포함).
- §11.2 의 metadata instance location + canonical filename `install.json`.
- §11.3 의 `schemaVersion` semantics.
- §11.4 의 restore (b) user-specified ref-only.
- §11.5 의 lifecycle.
- §11.6 의 deferred items.
- §11.7 의 forbidden fields / semantics.

본 anchor 는 다음을 **포함하지 않는다.**

- 실제 schema 파일 (JSON Schema 등) 의 작성 / commit.
- writer / reader implementation, JSON validator, dispatcher 통합.
- payload integrity manifest 의 algorithm / 위치 / 이름 결정.
- `current/` payload completeness marker 의 entrypoint set 확정.
- `schemaVersion` bump migration writer.
- install / update / restore 의 actual 실행, global / user filesystem mutation, target adoption.
- commit / push / publish / merge / release.
- Step 4 validation.
- 부모 `GLOBAL_INSTALL_UPDATE_MODEL.md` 본문 mutation (filename reconciliation 은 본 §11.2 안에서 닫는다).

본 anchor 는 `yes` / `no` / `yes with risk` 어느 verdict 의 자동 승인도 아니다. anchor 의 source / doc mutation 자체는 본 도구의 정상 review gate 를 거치며, review verdict 이후의 commit / push / global apply / payload refresh 는 사용자 명시 결정으로 처리한다 (§8, §10.7 와 정합).
