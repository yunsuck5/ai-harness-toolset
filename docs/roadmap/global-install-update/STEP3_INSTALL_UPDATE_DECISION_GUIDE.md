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

---

## 12. Recorded 3-2~3-5 runtime pipeline contract grouping

본 절은 §6 canonical decomposition 의 **3-2 (source / ref resolver)**, **3-3 (overwrite materialization core)**, **3-4 (install / update / restore dispatcher)**, **3-5 (verify path)** 의 네 sub-step 을 **하나의 implementation-facing runtime pipeline category** 로 묶어 contract 수준에서 anchor 한다. 네 sub-step 은 §6 의 canonical 9 단계 안에서 각각 별도로 enumerate 되어 있지만, 운영상은 하나의 source-authoritative overwrite materialization pipeline 의 인접 layer 다 — 본 grouping anchor 는 그 인접성을 implementation 시점의 reference 로 보존한다.

본 grouping anchor 는 §10 (3-0 layer layout), §11 (3-1 install metadata contract) 위에 build 되며 그 결정을 약화하지 않는다. §6 의 canonical decomposition 항목 자체 (9 단계의 ordering / numbering) 도 변경하지 않는다 — 본 §12 는 **운영 / implementation 시점의 grouping reference** 이지 §6 의 재구성이 아니다.

본 grouping anchor 는 schema 의 contract 의미 (pipeline shape / action labels / sub-step boundary / forbidden / failure 요약) 만 기록한다. resolver / materialization / dispatcher / verifier 의 실제 함수 signature, parser code, JSON validator, git plumbing 호출, payload integrity manifest 의 algorithm / 위치 / 이름, payload completeness marker 의 entrypoint set 확정 — 모두 본 anchor 범위 밖이며 후속 implementation goal 의 일이다.

본 anchor 는 implementation, install / update / restore 의 actual 실행, global / user filesystem mutation, target adoption, commit / push / publish / merge / release / Step 4 validation 어느 것도 자동 승인하지 않는다.

### 12.1 Pipeline shape (4 sub-step 의 공통 흐름)

§3 의 source-authoritative overwrite materialization 원칙을 본 grouping 의 pipeline shape 로 풀어 적는다.

```
[3-2 resolver]
  invocation params + metadata? + resolved invocation context (D1 runtime ToolRoot + D9 ProjectRoot)
     → resolved tuple (action, installMode, sourceLocation, resolvedRefSha, refKind,
                       toolRoot, projectRoot, sourceUpdatePolicy, sourceCutDetected)

[3-3 materialization core]
  resolved tuple → deterministic overwrite materialization of current/ runtime payload

[3-4 dispatcher]
  one shared pipeline; 4 action labels (install / update-source / update-current / restore)
  routed by action; mode differences are only in 3-2 resolution path

[metadata lifecycle write (per §11.5)]
  install/update/restore 성공 후 metadata 의 lastUpdatedHead / lastUpdatedAt 갱신

[3-5 verify path]
  materialized current/ payload 와 metadata, 그리고 manifest 또는 entrypoint marker 의 일치성 검증
```

본 pipeline 은 4 action 모두 공유한다. action 별 차이는 **3-2 source/ref resolution path 에 한정** 되며, 그 이후의 materialization / metadata write / verify / report 단계는 동일하다 (§3 와 정합).

### 12.2 Action labels (canonical names)

본 grouping 의 4 action 은 다음 canonical label 로 표기한다. 향후 prompt / handoff / scope definition / Codex review input 도 본 label 을 carry 한다.

- **`install`** — 최초 설치 (install-from-git-url 또는 install-from-local-clone; 부모 §2 와 정합).
- **`update-source`** — "업데이트 받아" (source update + global install update; 부모 §4.4 와 정합).
- **`update-current`** — "현재 최신 버전 기준으로 update 설치해" (current local HEAD 기준 global install update only; source 건드리지 않음; 부모 §4.4 와 정합).
- **`restore`** — user-specified ref-only restore (§11.4 의 (b) 와 정합).

### 12.3 3-2 source / ref resolver — contract level

- **입력**: invocation params, metadata (update / restore 시 필수), **resolved invocation context** — D1 runtime ToolRoot + D9 ProjectRoot (`SHARED_GLOBAL_INVOCATION_CONTRACT.md` §5.1 channel chain 결과). D1 runtime ToolRoot 는 channel 3 default 에서 global install area 의 `current/` (= §12.4 materialization destination 과 동일 path) 다. 본 입력의 D1 runtime ToolRoot 는 **본 §12.3 의 resolved tuple field `toolRoot` 와 별개 concept** 이다 — tuple `toolRoot` 는 §11.1 metadata `toolRoot` 와 동일한 source-side canonical local ToolRoot (parent §6 Layer 1) 이며 materialization destination 이 아니다. 두 개념을 같은 이름의 동일 의미로 conflated 시키지 않도록 §12 본문 전체에서 분리 표기한다.
- **출력**: resolved tuple 형식 (contract 수준 — 정확한 field 표현 / serialization 은 3-3 / 3-4 implementation 시점에 확정).

  | field | 의미 |
  |---|---|
  | `action` | `install` / `update-source` / `update-current` / `restore` |
  | `installMode` | `git-url` / `local-clone` (§11.1 와 정합) |
  | `sourceLocation` | git-url mode 의 `repoUrl` 또는 local-clone mode 의 `sourcePath` |
  | `resolvedRefSha` | resolve 된 commit SHA (reproducible 보장을 위해 항상 SHA 로 정규화) |
  | `refKind` | 입력의 ref 형식 기록 — `commit` / `branch` / `tag` |
  | `toolRoot` | **source 측 canonical local ToolRoot 절대경로** (parent §6 Layer 1; §11.1 metadata `toolRoot` 와 동일 의미). update / restore 시 source 를 읽는 위치이며, materialization 의 destination 이 **아니다**. destination 은 §12.4 의 runtime payload directory 로 별도 path. |
  | `projectRoot` | resolved ProjectRoot 절대경로 |
  | `sourceUpdatePolicy` | `fetch-and-update` (update-source) / `read-current-only` (update-current, restore, install 의 read 단계) |
  | `sourceCutDetected` | bool — true 면 STOP / 별도 explicit scope (§12.7) |

- **mode-별 resolution path**:
  - **git-url**: `repoUrl` / `branch` / `remote` / `toolRoot` 가 source resolution 의 입력. `update-source` 는 fetch 후 new HEAD 를 ref 로 resolve. `update-current` 는 fetch 없이 현재 HEAD 만 read. `restore` 는 user-specified `--ref` 가 필수.
  - **local-clone**: `sourcePath` / `toolRoot` 가 입력. `sourcePath` 는 valid source repo (D3 multi-marker 통과) 여야 한다. `update-source` 는 §12.8 의 dogfooding 제약 안에서만 source 갱신 허용. `update-current` 는 read-only. `restore` 는 user-specified `--ref` 필수.
- **금지** (resolver level):
  - metadata write (§11.5 의 lifecycle 의 별도 단계가 담당).
  - `current/` overwrite (3-3 의 영역).
  - global / user filesystem mutation (§10.6 / `GLOBAL_ADOPTION_DECISION.md` §6 와 정합).
  - destination (`current/`) 의 diff / 상태를 ref resolution 입력으로 사용 (§3).
  - metadata-derived known-good ref 자동 추출 / 자동 fallback (§11.4 (b)).

### 12.4 3-3 overwrite materialization core — contract level

- **입력**: 3-2 의 resolved tuple.
- **동작**: source-side canonical local ToolRoot (= resolver tuple 의 `toolRoot`, parent §6 Layer 1; §15.5 / §16.5 와 정합 — git-url mode 에서는 `<InstallArea>/source-cache/`, local-clone mode 에서는 user-supplied sourcePath 의 absolute path) 에서 `resolvedRefSha` 의 source content 를 **global install area 의 runtime payload directory `current/`** (parent §6 Layer 2; §10.1 layer table; §11.2 location boundary) 의 runtime payload roots (`config/` / `scripts/` / `snippets/` / `templates/` — §10.1) 로 deterministic overwrite 한다. tuple 의 `sourceLocation` 은 user-facing identifier (git-url mode 의 URL 또는 local-clone mode 의 sourcePath) 로서 metadata write 의 입력 (§11.5 lifecycle 의 metadata field) 이며, materialization 의 archive source 가 아니다 (§16.5 와 정합 — 두 개념을 같은 이름으로 conflated 시키지 않는다). 본 destination 은 channel 3 default 운영에서 `%USERPROFILE%\.claude\ai-harness-toolset\current\` 다. resolver tuple 의 `toolRoot` (= materialization source) 와 destination (= `<InstallArea>/current/`) 은 별개의 path 이며, 두 path 는 같은 디렉터리를 가리키지 않는다 — 본 anchor 는 destination 을 `<toolRoot>/...` 의 child path 로 표기하지 않는다. overwrite 의 byte-identity 보장은 implementation level 의 검증이며 본 anchor 가 algorithm 을 fix 하지 않는다.
- **금지**:
  - destination diff / patch 기반 변경 (§3 / §4).
  - partial patch update (§4).
  - user-edit preservation (destination 의 user 편집 보존을 위한 conditional skip / merge — §4).
  - interactive file-by-file decision UX (§4).
  - `current/` 안에 runtime payload 외의 항목 (install metadata instance / installer source / source-cache / tests / docs / runtime artifact) 추가 (§10.2).

### 12.5 3-4 install / update / restore dispatcher — contract level

- **입력**: 사용자 invocation + 3-2 resolved tuple.
- **동작**: 4 action 을 동일 pipeline 으로 routing 한다.
  - install / update-source / update-current / restore 의 차이는 3-2 resolution path 와 (metadata 의 read / write 시점) 에 한정.
  - 4 action 모두 `resolve → materialize → write metadata → verify → report` 의 공통 sequence 를 따른다.
- **금지**:
  - 사용자 명시 결정 없이 mode 간 자동 전환 (예: install 실패 시 자동 restore — `POST_MVP_PLAN.md` §5 "automatic decision-maker 금지" 와 정합).
  - corrupted / incomplete `current/` payload 발견 시 자동 restore default (§7 #5 의 open question 으로 carry; 본 anchor 가 default 를 fix 하지 않는다).
  - 별도 explicit user-approved scope 의 source-cut path 를 dispatcher 가 자동 처리 (§12.7).

### 12.6 3-5 verify path — contract level

- **입력**: materialized `current/` payload, metadata (post-write 상태), payload integrity manifest (도입 시) 또는 entrypoint marker (도입 시).
- **동작**: 세 입력의 일치성을 검증.
  - install metadata (§11.1 의 minimum field set) 의 binding 검증 — `tool` / `installMode` / `toolRoot` (source-side, parent §6 Layer 1) / `installedHead` / `lastUpdatedHead` / `branch` / `remote` / mode-conditional `repoUrl` 또는 `sourcePath` 등 §11.1 field 의 일치 / 유효성 확인. **install metadata 는 `projectRoot` field 를 포함하지 않는다** (§11.1). review subsystem 의 `meta.json` 에 대한 `SHARED_GLOBAL_INVOCATION_CONTRACT.md` D6 의 toolRoot binding 검증 패턴은 **별개 subsystem** 의 concept (review-verify) 이며 본 install verify path 와 직접 결합되지 않는다 — conceptual parallel 일 뿐이다.
  - payload 의 무결성 (integrity manifest 또는 per-file digest 와의 일치).
  - payload completeness marker (channel 3 활성 조건의 entrypoint set 존재) 의 검증.
- **detail deferred**:
  - payload integrity manifest 의 algorithm / 위치 / 이름 / schema 는 별도 backlog scope (`docs/backlog/operations.md` "Aggregate digest reproducibility — install/update verification scope debt").
  - payload completeness marker 의 entrypoint set 확정은 별도 implementation 결정 (현행 SHARED_GLOBAL_INVOCATION_CONTRACT.md 의 supersede note 기준 `scripts/review-cycle.ps1` 식별자는 canonical task/pass topology 이후 갱신 필요).

### 12.7 Source-cut detection — resolver level only

source-cut change = invocation params 가 metadata 의 다음 field 중 하나라도 변경하려는 경우.

- `installMode` (git-url ↔ local-clone)
- `repoUrl`
- `sourcePath`
- `toolRoot`
- `branch`
- `remote`

본 grouping anchor 의 resolver / dispatcher 의 처리:

- **resolver**: source-cut 후보를 감지 (URL normalization 후 비교) 하여 `sourceCutDetected=true` 로 표시하고 **STOP / 사용자 보고** 만 한다.
- **dispatcher**: `sourceCutDetected=true` 인 resolved tuple 을 자동 처리하지 않는다.
- **처리 path**: source-cut path 의 실제 처리 (재install / metadata 갱신 / new install 등) 는 **별도 explicit user-approved scope** 의 일이다. 본 §12 가 그 path 를 fix 하지 않는다 (§11.5 lifecycle 의 "별도 explicit scope" 와 정합).

### 12.8 Dogfooding mode boundary

dogfooding mode (SHARED_GLOBAL_INVOCATION_CONTRACT §4 D1 의 channel 4 — source repo = ToolRoot = ProjectRoot, user dev checkout 인 경우) 에서의 안전 boundary:

- `update-source` 는 user dev checkout 의 working tree 를 **silent 하게 mutate 하지 않는다**.
- default 동작은 **STOP / 사용자 보고** 또는 **explicit confirmation 요구**.
- `update-current` 는 source 를 건드리지 않으므로 dogfooding mode 에서도 그대로 허용.
- `install` 은 dogfooding mode 에서 의미상 발생하지 않음 (이미 source repo 가 ToolRoot 인 상태).
- `restore` 의 user-specified `--ref` 가 user dev checkout 의 working tree 를 변경할 가능성이 있으면 동일 보호 적용.

본 boundary 의 정확한 enforcement mechanism (warning prompt / `--allow-dogfood-mutation` flag 등) 은 implementation 시점에 결정 — 본 anchor 가 fix 하지 않는다.

### 12.9 Failure summary (key cases)

본 grouping 의 failure 처리는 (a) exit non-zero, (b) 명시적 사유 메시지, (c) 다음 사용자 행동 안내 의 3 항목을 모든 fail-fast 가 포함한다. 상세 failure case 는 implementation 시점의 책임이며 본 anchor 는 다음 key cases 만 명시 보존한다.

- **missing metadata** — update / restore 호출 시 metadata file 부재 → fail-fast; "install 먼저 수행" 보고.
- **unknown schemaVersion** — metadata 의 `schemaVersion` 이 reader 미지원 → fail-fast (§11.3; silent downgrade 금지).
- **invalid explicit ref** — restore 의 `--ref` 가 source 에 존재하지 않음 → fail-fast; 자동 known-good fallback 금지 (§11.4 (b)).
- **auth / network failure** — `git fetch` / `git pull` / `git clone` 실패 → fail-fast; 자동 retry 금지.
- **source-cut detected** — §12.7 의 source-cut 후보 감지 → STOP / 별도 explicit scope.
- **dogfooding mutation risk** — §12.8 의 dogfooding mode 에서 `update-source` 호출 → STOP / explicit confirmation 요구.

기타 failure case (ambiguous `--repoUrl`/`--sourcePath`, invalid `sourcePath`, overwrite-risk non-empty ToolRoot, dirty / mid-rebase source 의 reproducibility risk 등) 는 implementation 시점에 정합화. 본 anchor 가 모두 enumerate 하지 않는다.

### 12.10 Out-of-pipeline categories (별도 carry)

다음 항목은 본 grouping 의 runtime pipeline **밖** 의 별도 category 다. 본 §12 가 자동 승인하지 않는다.

- **3-6 managed block / skill replace boundary** (§6) — global instruction file managed-block apply, Claude skill SKILL.md install / update / removal. install / update automation core 본체 밖이며 `GLOBAL_ADOPTION_DECISION.md` §6 / `GLOBAL_ADOPTION_PROCEDURE.md` 의 explicit user-approved scope (§10.6 / §11.7 의 forbidden enumeration 과 정합).
- **3-7 dry-run tests** (§6) — temp destination 대상의 dry-run; 실제 `%USERPROFILE%\.claude\` / `%USERPROFILE%\.codex\` mutation 의 validation 은 Step 4 또는 별도 scoped approval 의 영역.
- **3-8 minimal docs closeout** (§6) — Step 3 완료 시의 docs 보강 단계.
- **Step 4 install / update validation** (`POST_MVP_PLAN.md` §11) — 실제 글로벌 mutation 검증.
- **Actual global apply / target adoption** — 글로벌 channel 3 install / update / refresh / payload mutation; `POST_MVP_PLAN.md` §11 의 step 단위 별도 scoped approval.

### 12.11 본 anchor 의 scope 와 non-goals

본 anchor 는 다음을 **포함한다**.

- §12.1 의 pipeline shape (4 action 의 공통 sequence).
- §12.2 의 4 canonical action labels (`install` / `update-source` / `update-current` / `restore`).
- §12.3 의 3-2 resolver contract (입력 / 출력 tuple / mode-별 resolution path / 금지).
- §12.4 의 3-3 materialization core contract (입력 / 동작 / 금지).
- §12.5 의 3-4 dispatcher contract (공통 routing / 금지).
- §12.6 의 3-5 verify path contract (입력 / 동작 / detail deferred).
- §12.7 의 source-cut detection-only boundary.
- §12.8 의 dogfooding mode boundary.
- §12.9 의 key failure cases.
- §12.10 의 out-of-pipeline categories enumeration.

본 anchor 는 다음을 **포함하지 않는다**.

- 실제 resolver / materialization / dispatcher / verifier 의 함수 signature, parser code, JSON validator, git plumbing 호출의 implementation.
- payload integrity manifest 의 algorithm / 위치 / 이름 / schema 결정.
- payload completeness marker 의 entrypoint set 확정.
- source-cut path 의 실제 처리 (재install / metadata 갱신 / new install 등).
- dogfooding mode 의 enforcement mechanism 의 정확한 형태 (warning prompt / flag 등) 결정.
- corrupted / incomplete `current/` payload 발견 시의 default 동작 결정 (§7 #5 의 open question 으로 carry).
- 부모 `GLOBAL_INSTALL_UPDATE_MODEL.md` 본문 mutation.
- §6 canonical decomposition 9 단계의 ordering / numbering 변경.
- install / update / restore 의 actual 실행, global / user filesystem mutation, target adoption, commit / push / publish / merge / release, Step 4 validation.

본 anchor 는 `yes` / `no` / `yes with risk` 어느 verdict 의 자동 승인도 아니다. anchor 의 source / doc mutation 자체는 본 도구의 정상 review gate 를 거치며, review verdict 이후의 commit / push / global apply / payload refresh 는 사용자 명시 결정으로 처리한다 (§8, §10.7, §11.8 와 정합).

---

## 13. Recorded 3-8 minimal docs closeout

본 절은 §6 canonical decomposition 의 9 번째 sub-step — **3-8 minimal docs closeout** — 을 수행한다. Step 3 의 현재 완료 상태를 한 자리에 모으고, 남은 deferred scope 를 분리해 기록한다. 본 절의 존재로 어떤 새 implementation, validation, adoption, release, publish, global / user filesystem mutation, commit / push / merge / release 도 자동 승인되지 않는다.

§6 canonical decomposition 9 단계 중 본 §13 은 3-8 자리의 anchor 이며, 3-2~3-5 의 grouped runtime pipeline 본문은 §12 에, 3-6 boundary 의 § anchor 는 §14 에, payload integrity manifest + payload completeness marker minimum contract 는 §15 에, git-url mode minimum source acquisition contract 는 §16 에, source-cut path actual handling decision anchor 는 §17 에, dogfooding enforcement final shape decision anchor 는 §18 에 보존된다. 본 §13 은 §6 의 ordering / numbering 을 변경하지 않는다. 본 §13 작성 시점에는 §14 / §15 / §16 / §17 / §18 가 아직 작성되지 않았으나, 후속 anchor 라운드 (3-6 anchor / manifest+marker minimum contract / git-url minimum source acquisition / source-cut path decision anchor / dogfooding enforcement final shape) 에서 본 §13.1 의 Completed 와 §13.2 의 Deferred 가 함께 갱신되었다.

### 13.1 Completed

본 라운드까지 누적된 Step 3 의 anchored decisions + skeleton implementation + dry-run coverage 의 commit 시리즈:

- **3-0 layer layout decision** — §10 anchor. commit `c055ea5`.
- **3-1 install metadata contract** — §11 anchor. commit `bb9b832`.
- **3-2~3-5 runtime pipeline contract grouping** — §12 anchor (resolver / materialization / dispatcher / verify boundary 와 4 canonical action labels, source-cut detection-only, dogfooding 보호, key failure cases, out-of-pipeline categories). commit `f11ed27`.
- **temp-only install-pipeline skeleton implementation** — `scripts/install-pipeline.ps1` (CLI entry), `scripts/lib/install-pipeline-core.ps1` (library), `tests/install-pipeline.Tests.ps1` (Pester tests) 3 파일 신규. local-clone mode 의 `install` / `update-source` / `update-current` / `restore` 4 action 을 `$TestDrive` fixture 기준으로 end-to-end 동작. install.json (§11.1 14-field schema), source-cut detection-only, dogfooding silent-mutation 보호, forbidden InstallArea guard (`%USERPROFILE%\.claude` / `%USERPROFILE%\.codex` 및 descendants), git-archive 기반 ref-specific materialization 포함. commit `84d1126`.
- **3-7 dry-run coverage extension** — install → update-current → restore 연속 flow + per-step metadata + invariant 9 fields 비-드리프트 (`installedAt` 보존, `lastUpdatedAt` lifecycle 포함), source-cut 거부 후 `current/` byte-identity 보존, dogfooding `update-source` 거부 후 source repo HEAD 무변경, `%USERPROFILE%\.codex` reject, `%USERPROFILE%\.claude` descendant reject + 디렉터리 미생성. 5 신규 Pester tests. commit `3bff209`.
- **3-6 managed-block / skill replace boundary anchor** — §14 anchor (boundary statement, in-scope / out-of-scope enumeration, deferred items). §7 #2 carry-forward caveat 의 §anchor 정착 + §10.6 / §11.7 / §12.10 enumeration 의 상위 §종합 자리. install / update automation core (§12 의 4 action) ≠ managed-block / skill replace apply (`GLOBAL_ADOPTION_DECISION.md` §6 / `GLOBAL_ADOPTION_PROCEDURE.md`) 의 scope 분리를 한 줄 boundary 로 anchor. commit `9cf2000` (`Anchor Step 3 3-6 managed-block boundary`). 본 anchor 는 boundary 정의에 한정되며 actual managed-block / skill apply 또는 진단 helper / actual writer 의 도입을 자동 승인하지 않는다.
- **payload integrity manifest + payload completeness marker minimum contract + temp-only implementation + dry-run tests** — §15 anchor + `scripts/lib/install-pipeline-core.ps1` 구현 + `tests/install-pipeline.Tests.ps1` 9 신규 tests. backlog "Aggregate digest reproducibility" candidate (b) per-file manifest 채택; `payload-manifest.json` (sibling-of-`current/`, JSON UTF-8 no-BOM, per-file `{path, size, sha256}` sorted ascending) + `payload-marker.json` (sibling-of-`current/`, presence flag + integrity binding). write hook 은 materialization 직후 / metadata write 이전 단계로, verify hook 은 `Invoke-InstallPipelineVerify` 안의 metadata 검증과 함께 manifest per-file diff (tamper / missing / extra) + marker presence + head cross-binding 을 fail-fast. commit `1273afe` (`Anchor Step 3 payload manifest and marker minimum contract`). 본 anchor 는 local-clone mode 의 `install` / `update-source` / `update-current` / `restore` 4 action 만 cover 하며 git-url mode actual network fetch / actual global install area mutation / entrypoint set finalize / aggregate digest algorithm (candidate (a)) / schema bump migration writer / 외부 검증 tool / channel 3 활성 hook 의 actual implementation / target adoption 은 자동 승인하지 않는다.
- **git-url mode minimum source acquisition contract + temp-only implementation + dry-run tests** — §16 anchor + `scripts/lib/install-pipeline-core.ps1` 구현 + `scripts/install-pipeline.ps1` entry wiring + `tests/install-pipeline.Tests.ps1` 9 신규 tests (AC-IP-GITURL-*). §10.5 의 deferred source-cache layer 결정을 reassessment 결과로 §16 에서 채택 — canonical location `<InstallArea>/source-cache/` (sibling-of-`current/`), normal-clone format, single-cache-per-InstallArea. per-action lifecycle: install → `git clone -q`, update-source → `git fetch -q origin <branch>` + resolve `origin/<branch>`, update-current → cache-local `git rev-parse HEAD` (no network), restore → cache-local `git rev-parse --verify <user-ref>^{commit}` (no network). failure preservation: fetch / resolve / clone 실패가 모두 materialization 이전 단계라 deliverable artifact (install.json / manifest / marker / current/) 의 byte-identity 가 보존된다. tuple.toolRoot = cache absolute path (§16.5 — install.json `toolRoot` 와 정합); tuple.sourceLocation = URL (user-facing identifier). `Invoke-InstallPipelineNativeGit` helper 가 `$ErrorActionPreference` 를 함수 scope 내 'Continue' 로 pin 해 NativeCommandError-on-stderr 가 LASTEXITCODE-driven throw 를 preempt 하는 PS 5.1 quirk 를 우회. test fixture 는 `git clone --bare -q` 로 만든 local bare repo 만 사용 (`-RepoUrl` = bare absolute path; file:// URL 도 동등하게 동작하나 path 만 사용). 본 anchor 의 commit hash 는 본 closeout 라운드의 후속 commit (사용자 명시 결정 후) 으로 carry. 본 anchor 는 credential / auth handling / clone recovery / multi-cache / per-ref subdirectory / bare cache / cache identity verification / fetch retry / submodule / actual global apply / source-cut path 실제 처리 / schemaVersion migration writer / Step 4 시작 / managed-block apply / Claude skill install/update/removal / 외부 GitHub network reachability 의존 test 어느 것도 자동 승인하지 않는다.
- **Step 3 source-cut path actual handling decision anchor** — §17 anchor. §12.7 detection-only / dispatcher non-process / STOP behavior 위에서, source-cut path 의 actual handling 을 **`deferred with exact boundary`** 로 고정한다. `explicit unsupported fail-fast now` 도 `minimum support now` 도 채택하지 않는다 — future implementation 가능성은 보존하되 본 라운드의 자동 승인은 거부. 본 anchor 는 (a) 3 concept (local-clone mode / git-url mode / source-cut path) 의 boundary separation 을 본 자리에서 한 번 종합 — local-clone / git-url 은 mutually exclusive 한 두 mode 이며 source-cut 은 세 번째 mode 가 아니라 metadata mutation class. (b) §12.7 의 6 trigger field (`installMode` / `repoUrl` / `sourcePath` / `toolRoot` / `branch` / `remote`) 를 본 anchor 에 복제 anchor (재정의 아님). (c) §17.4 in-scope behavior 보존 (§12.7 unchanged + 3-7 dry-run 의 byte-identity case 유지). (d) §17.5 deferred boundary 8 항목 enumeration — 재install handler / metadata mutation writer / new install path 및 cutover 절차 / approve UX / source-cache lifecycle on mode change / `schemaVersion` source-cut-related field 추가 / dogfooding mode interaction enforcement / source-cut 처리 후 manifest+marker 재작성 절차. (e) §17.6 forbidden enumeration. 본 anchor 는 docs-only 이며 `scripts/install-pipeline.ps1` / `scripts/lib/install-pipeline-core.ps1` / `tests/install-pipeline.Tests.ps1` 어느 것도 변경하지 않는다. 본 anchor 의 commit hash 는 commit `9308f3d` (`Anchor Step 3 source-cut path actual handling decision`). 본 anchor 는 source-cut handler 의 신규 implementation, install-pipeline 의 source-cut 자동 처리, 신규 Pester test 추가, metadata in-place mutation, actual global apply, managed-block apply, Claude skill install / update / removal, Step 4 validation 시작, snapshot / manifest 생성, commit / push 어느 것도 자동 승인하지 않았다.
- **Step 3 dogfooding enforcement final shape decision anchor** — §18 anchor. §12.8 의 마지막 문장 ("본 boundary 의 정확한 enforcement mechanism (warning prompt / `--allow-dogfood-mutation` flag 등) 은 implementation 시점에 결정 — 본 anchor 가 fix 하지 않는다") 의 closeout 으로, dogfooding enforcement final shape 를 docs-only 로 고정. 5 명제 anchor — (1) explicit-flag bypass 모델 (`-AllowDogfoodSource` switch); warning-only / interactive prompt / env var / config file bypass 거부, (2) strict mode confinement — local-clone mode 에만 적용, git-url 은 구조적으로 dogfooding-irrelevant (§16.2 source-cache 가 InstallArea 안), (3) action × mode × dogfooding boundary matrix (§18.4 — install ALLOWED, update-source BLOCKED-default / explicit-confirm-required via flag, update-current ALLOWED, restore ALLOWED git-archive 한정), (4) 5 tree separation invariant (source repo working tree / global current / InstallArea / source-cache / ProjectRoot.log 의 비-overlap), (5) docs-only 결정 — 현행 skeleton 의 as-built 동작 (`Test-InstallPipelineDogfoodingSource`, `-AllowDogfoodSource` switch, 3-7 dry-run "dogfooding `update-source` 거부 후 source repo HEAD 무변경" Pester case) 을 final shape 로 anchor. dogfooding detection 의 두 detection point 분리 — invocation-time ToolRoot resolution (`SHARED_GLOBAL_INVOCATION_CONTRACT.md` D1 channel 4) 와 action-time source-side dogfooding (`Test-InstallPipelineDogfoodingSource` 의 `SourcePath == ProjectRoot` + `Test-IsSourceRepoRoot` 조건) 의 별개 detection 의미. §18.6 deferred items 8 항목 enumeration (dirty source guard / restore implementation 변경 시 재anchor / install 의 explicit-confirm 도입 여부 / source-cut × dogfooding interaction (§17.5 와 정합) / dogfooding enforcement actual implementation 확장 / bypass audit log / Claude Code agent-driven invocation 의 dogfooding boundary / InstallArea placement 의 source-repo subtree 거부 enforcement). §18.7 forbidden enumeration. 본 anchor 는 docs-only 이며 `scripts/install-pipeline.ps1` / `scripts/lib/install-pipeline-core.ps1` / `tests/install-pipeline.Tests.ps1` 어느 것도 변경하지 않는다. 본 anchor 의 commit hash 는 본 closeout 라운드의 후속 commit (사용자 명시 결정 후) 으로 carry. 본 anchor 는 dogfooding enforcement 의 신규 implementation, install-pipeline 의 새 함수 / 새 flag 추가, 신규 Pester test 추가, metadata schema 변경, actual global apply, managed-block apply, Claude skill install / update / removal, Step 4 validation 시작, snapshot / manifest 생성, commit / push 어느 것도 자동 승인하지 않는다.

본 commit 시리즈의 최신 HEAD: `3bff2093ee3cfb0996633007efed717b64ace631` (3-7 dry-run coverage extension 시점). 본 §14 anchor 가 commit 되면 HEAD 는 그 후속 commit hash 로 carry — 본 §13.1 의 commit hash 표기는 본 §14 anchor 의 commit 시점에 갱신되지 않으며 ("baseline commit hash 는 review context only" — §7 #6 와 정합), 위 3-7 시점의 baseline 표기로 historical 보존된다.

본 라운드까지의 implementation surface 는 §10.2 의 `current/` runtime-payload-only, §11.1 의 14-field install metadata, §11.4 의 (b) user-specified ref-only restore, §11.7 의 forbidden enumeration, §12.2 의 4 canonical action labels, §12.7 의 source-cut detection-only, §12.8 의 dogfooding 보호, §12.10 의 out-of-pipeline categories 와 1:1 정합한다. Pester 전체 suite 는 본 closeout 작성 시점에 회귀 없이 통과한다.

### 13.2 Deferred (Step 3 outside / Step 4+ 영역)

다음 항목은 본 §13 closeout 이 **자동 승인하지 않는** deferred scope 다. 각 항목은 별도 scoped goal 의 explicit user-approved decision 으로 진행한다.

- **git-url mode 의 후속 deferred 항목** — §16 anchor 가 minimum source acquisition contract (local git operations 기반의 cache / clone / fetch / ref resolve + temp-only implementation + dry-run tests) 를 정착시키므로 본 §13.2 의 deferred 잔여는 §16.6 의 후속 deferred 항목 (credential / auth handling, clone recovery, multi-cache / per-ref subdirectory, bare clone 채택, cache identity verification, fetch retry / backoff / shallow clone, HTTP/HTTPS/SSH/git protocol specific 처리, submodule, schemaVersion migration writer / source-cut path 실제 처리 / actual global apply 등) 으로 좁아진다. 모두 별도 scoped goal 의 explicit user-approved decision 으로 진행한다 (`GLOBAL_INSTALL_UPDATE_MODEL.md` §2.1 / §4.2 와 정합).
- **payload integrity manifest / payload completeness marker 의 후속 deferred 항목** — §15 anchor 가 minimum contract (per-file manifest + presence marker) 와 temp-only local-clone implementation + dry-run tests 를 정착시키므로 본 §13.2 의 deferred 잔여는 §15.6 의 6 항목 (entrypoint set finalize, aggregate digest algorithm (candidate (a)) 의 별도 도입, manifest / marker schema bump migration writer, manifest 외부 검증 tool / linter, `Get-ToolRoot` channel 3 활성 hook 의 actual implementation, target adoption / external target 에 대한 manifest / marker) 으로 좁아진다. 모두 별도 scoped goal 의 explicit user-approved decision 으로 진행한다 (`docs/backlog/operations.md` "Aggregate digest reproducibility — install/update verification scope debt" 와 정합).
- **3-6 boundary 의 후속 implementation 항목** — §14 anchor 가 boundary 정의를 마치므로 본 §13.2 의 deferred 잔여는 §14.4 의 5 항목 (boundary 진단 helper / check-only helper 의 도입 여부 + spec + 위치 + 이름, managed-block apply 의 actual writer surface, Claude skill install / update / removal 의 actual writer surface, boundary violation detection mechanism, 3-6 의 implementation-level closeout) 으로 좁아진다. 본 항목들은 boundary 정의가 아니라 boundary 의 후속 implementation / helper 단계이며, 모두 별도 scoped goal (`GLOBAL_ADOPTION_DECISION.md` §6 / `GLOBAL_ADOPTION_PROCEDURE.md`) 의 explicit user-approved decision 으로 진행한다.
- **Step 4 actual install / update validation** — `POST_MVP_PLAN.md` §11 step 4. 본 §13 closeout 이 자동 승인하지 않는다.
- **Actual global / user filesystem apply** — global stable install (`%USERPROFILE%\.claude\ai-harness-toolset\current\`) 의 실제 materialize / refresh, install metadata instance write, managed-block apply, Claude skill assets install 어느 것도 본 commit 시리즈로 자동 승인되지 않는다.
- **source-cut path 의 실제 처리** — §17 anchor 가 본 항목을 **`deferred with exact boundary`** 로 정착시키므로 본 §13.2 의 deferred 잔여는 §17.5 의 8 항목 (재install handler / metadata mutation writer / new install path 및 cutover 절차 / approve UX / source-cache lifecycle on mode change / `schemaVersion` source-cut-related field 추가 / dogfooding mode interaction enforcement / source-cut 처리 후 manifest+marker 재작성 절차) 으로 좁아진다. §12.7 의 resolver detection-only / dispatcher non-process / STOP behavior 는 그대로 유지된다 (§17.4). 본 항목들은 별도 scoped goal 의 explicit user-approved decision 으로만 진행한다 (`docs/roadmap/GLOBAL_INSTALL_UPDATE_MODEL.md` §4 와 정합).
- **dogfooding enforcement mechanism 의 final shape** — §18 anchor 가 본 항목을 docs-only 로 정착시키므로 본 §13.2 의 deferred 잔여는 §18.6 의 8 항목 (dirty source guard / restore implementation 변경 시 재anchor / install 의 explicit-confirm 도입 여부 / source-cut × dogfooding interaction (§17.5 와 정합) / dogfooding enforcement actual implementation 확장 / bypass audit log / Claude Code agent-driven invocation 의 dogfooding boundary / InstallArea placement 의 source-repo subtree 거부 enforcement) 으로 좁아진다. §12.8 의 dogfooding mode boundary 정의와 §12.9 의 "dogfooding mutation risk" failure case 형태는 그대로 유지되며 본 final shape 는 explicit-flag bypass (`-AllowDogfoodSource` switch) — warning-only / interactive prompt / env var / config file bypass 거부. 본 항목들은 별도 scoped goal 의 explicit user-approved decision 으로만 진행한다.
- **`schemaVersion` bump migration writer** — §11.3 / §11.6 그대로 deferred.
- **post-MVP closeout 결정 (`POST_MVP_PLAN.md` §11 step 6)**, **`ai-harness-toolset` self-adoption (`POST_MVP_PLAN.md` §11 step 5)**, **new GJMNet clean adoption (`POST_MVP_PLAN.md` §11 step 7)** — 모두 별도 scoped goal.

### 13.3 본 closeout 의 boundary

본 §13 은 다음을 **포함한다**.

- §13.1 의 Step 3 completed 누적 기록 (anchor / skeleton / dry-run coverage 의 commit 시리즈).
- §13.2 의 deferred scope 분리 기록.

본 §13 은 다음을 **포함하지 않는다**.

- 신규 implementation / 새 contract field 도입 / source code 변경 / tests 변경.
- §6 canonical decomposition 의 ordering / numbering 변경.
- 부모 `GLOBAL_INSTALL_UPDATE_MODEL.md` 본문 mutation (본 closeout 은 STEP3 guide subordinate scope 안에서 닫는다; 부모 docs 의 변경은 본 closeout 의 영역이 아니다).
- 다른 roadmap docs / backlog docs / global filesystem mutation (단, `POST_MVP_PLAN.md` §10 Completed 의 본 closeout 진입 entry 는 본 closeout 의 sibling 작업으로 같은 라운드에 함께 진행될 수 있다 — 본 entry 의 추가도 새 contract 도입이 아니라 누적 진행 사실의 기록이다).
- actual global / user filesystem mutation, target adoption, commit / push / publish / merge / release.
- Step 4 validation 의 시작.

본 §13 은 `yes` / `no` / `yes with risk` 어느 verdict 의 자동 승인도 아니다. closeout 의 source / doc mutation 자체는 본 도구의 정상 review gate 를 거치며, review verdict 이후의 commit / push / global apply / payload refresh / Step 4 validation 시작 등은 사용자 명시 결정으로 처리한다 (§8 / §10.7 / §11.8 / §12.11 와 정합).

---

## 14. Recorded 3-6 managed-block / skill replace boundary

본 절은 §6 canonical decomposition 의 7 번째 sub-step — **3-6 managed-block / skill replace boundary** — 의 결정 shape 를 repo source-of-truth 로 anchor 한다. 본 anchor 는 §10 (3-0 layer layout) / §11 (3-1 install metadata contract) / §12 (3-2~3-5 runtime pipeline contract grouping) 위에 build 되며 그 결정을 약화하지 않는다. 본 anchor 는 boundary 의 **정의** 만 기록한다 — managed-block / skill apply 의 actual 실행은 본 anchor 의 범위 밖이며, 부모 root-level docs (`GLOBAL_ADOPTION_DECISION.md` §6, `GLOBAL_ADOPTION_PROCEDURE.md`) 가 source-of-truth 인 별도 explicit user-approved scope 다.

본 anchor 는 §7 #2 (managed-block / skill refresh 는 install / update automation 본체 밖) 의 carry-forward caveat 을 본 §14 의 §anchor 자리로 정착시키며, §10.6 / §11.7 / §12.10 에 enumerate 되어 있던 boundary 진술을 본 자리에서 한 번 종합한다. §10.6 / §11.7 / §12.10 본문은 변경하지 않으며, 본 §14 는 그 enumeration 의 **상위 §anchor** 다. §6 canonical decomposition 의 ordering / numbering 도 변경하지 않는다 — 본 §14 는 doc 본문의 §순서상 §13 (3-8 closeout) 뒤에 위치하지만 (anchor 작성 시점이 §13 이후이기 때문), §6 의 9 단계에서는 여전히 3-6 의 7 번째 위치다.

본 anchor 는 implementation, managed-block / skill 의 actual install / update / removal, global / user filesystem mutation, target adoption, commit / push / publish / merge / release / Step 4 validation 어느 것도 자동 승인하지 않는다.

### 14.1 Boundary statement

**3-6 boundary 의 한 줄 요약.**

```
install / update / restore automation core (§12 runtime pipeline)
  ≠
managed-block / skill replace apply (GLOBAL_ADOPTION_DECISION.md §6 / GLOBAL_ADOPTION_PROCEDURE.md)
```

두 scope 는 분리된다. 한쪽의 trigger / verdict / 승인이 다른 쪽을 자동 승인하지 않는다. install / update automation 본체 (§12 의 4 action `install` / `update-source` / `update-current` / `restore`) 는 destination 의 byte-identity overwrite materialization 만 다루며, managed-block / skill destination 으로 wording / SKILL.md 를 묶음 apply 하지 않는다. 반대로 managed-block / skill replace 도 `current/` runtime payload 의 materialization 을 자동 수행하지 않는다.

### 14.2 In-scope (3-6 boundary 의 정의로 본 anchor 가 포함하는 항목)

본 anchor 는 다음을 **포함한다**.

- **automation core 본체와 managed-block / skill apply 의 scope 분리 statement.** §14.1 의 한 줄 boundary + §14.3 의 forbidden coupling.
- **boundary 의 governing source-of-truth 표기.** managed-block 정책의 source-of-truth 는 `GLOBAL_ADOPTION_DECISION.md` §6 (marker / detection algorithm / destination path table / update policy), Claude skill 절차의 source-of-truth 는 `GLOBAL_ADOPTION_PROCEDURE.md` (skill 의 first install / update / removal 절차).
- **install / update automation 본체의 scope 한정 재진술.** automation 본체는 `current/` runtime payload 의 materialize / refresh + install metadata (§11.1) + update dispatch (§12) + verify (§12.6) 로 제한된다 (`GLOBAL_INSTALL_UPDATE_MODEL.md` §1 / §12 와 정합).
- **managed-block apply destination path enumeration 의 boundary 보존.** `GLOBAL_ADOPTION_DECISION.md` §6 의 path table (Claude project-root `<ProjectRoot>/CLAUDE.md`, Claude user-global `%USERPROFILE%\.claude\CLAUDE.md`, Codex project-root `<ProjectRoot>/AGENTS.md`, Codex user-global default `%USERPROFILE%\.codex\AGENTS.md`, `CODEX_HOME` 설정 시 `%CODEX_HOME%\AGENTS.md`, Codex user-global override `AGENTS.override.md`) 와 forbidden path `%USERPROFILE%\.claude\AGENTS.md` 는 본 anchor 의 boundary 가 governing 인정한다. 본 anchor 는 그 enumeration 을 복제하지 않으며, 변경하지도 않는다.
- **Claude skill asset 의 source / destination shape boundary 보존.** source 는 `<ToolRoot>/snippets/claude-skills/<skill-name>/SKILL.md`, destination 은 `%USERPROFILE%\.claude\skills\<skill-name>\SKILL.md` (`GLOBAL_ADOPTION_PROCEDURE.md` §3). skill SKILL.md 는 `current/` runtime payload 안에 두지 않는다 (§10.2 와 정합).
- **deferred 후속 결정의 raise 자리 명시.** boundary 진단 helper (check-only / inspect-only) 는 본 anchor 가 fix 하지 않는다 (§14.4 참조).

### 14.3 Out-of-scope (본 anchor 가 자동 승인하지 않는 항목)

본 anchor 는 다음을 **포함하지 않는다**.

- **actual managed-block insert / replace** 의 실행. `%USERPROFILE%\.claude\CLAUDE.md` / `%USERPROFILE%\.codex\AGENTS.md` / `%CODEX_HOME%\AGENTS.md` / `AGENTS.override.md` / project-root `CLAUDE.md` / `AGENTS.md` 의 어떤 marker-bounded block insert / replace 도 본 §14 의 doc 변경으로 자동 승인되지 않는다. `GLOBAL_ADOPTION_DECISION.md` §6 의 explicit user-approved managed-block insert / replace scope 가 governing.
- **actual Claude skill install / update / removal** 의 실행. `%USERPROFILE%\.claude\skills\<skill-name>\` 의 어떤 생성 / 덮어쓰기 / 삭제도 본 §14 의 doc 변경으로 자동 승인되지 않는다. `GLOBAL_ADOPTION_PROCEDURE.md` §5 / §6 / §7 의 절차가 governing.
- **install / update automation core 본체에서의 managed-block / skill apply 호출.** §12 의 4 action 어느 것도 managed-block apply 나 skill refresh 를 묶음으로 자동 실행하지 않는다. `install` / `update-source` / `update-current` / `restore` 의 dispatcher (§12.5) 에서 managed-block 또는 skill destination 으로의 추가 mutation 이 발생하지 않는다.
- **`%USERPROFILE%\.claude\AGENTS.md`** 의 생성. forbidden path (`GLOBAL_ADOPTION_DECISION.md` §6 의 forbidden row, §10.6 forbidden enumeration, `GLOBAL_INSTALL_UPDATE_MODEL.md` §1 / §12) — 본 anchor 도 어떤 경우에도 이 path 를 생성하지 않는다.
- **whole-file overwrite** 의 자동 승인. `GLOBAL_ADOPTION_DECISION.md` §6 의 marker-bounded block 전면 교체 정책 (whole-file overwrite 금지, marker-bounded block 바깥 보존) 이 governing. 본 §14 가 그 정책을 약화하지 않는다.
- **managed-block marker / detection algorithm** 의 재정의 또는 복제. `GLOBAL_ADOPTION_DECISION.md` §6 (counting rule / whole-line trim match / fence-pair pathology / decision-equivalent statements / destination 분기) 가 source-of-truth. 본 anchor 가 그 algorithm 을 복제하거나 재정의하지 않는다.
- **diagnostic helper / check-only helper** 의 spec / 위치 / 이름 finalize (§14.4 의 deferred 항목 참조).
- **§6 canonical decomposition** 의 ordering / numbering 변경 (3-6 의 위치는 §6 의 7 번째 sub-step 그대로다).
- **부모 root-level docs** (`GLOBAL_ADOPTION_DECISION.md`, `GLOBAL_ADOPTION_PROCEDURE.md`, `GLOBAL_INSTALL_UPDATE_MODEL.md`) 의 본문 mutation. 본 anchor 는 STEP3 guide subordinate scope 안에서 닫는다.
- **`POST_MVP_PLAN.md` §11 step 4** 의 시작 (install / update validation), step 5–7 의 시작.
- **commit / push / publish / merge / release / adoption**.

본 anchor 는 `yes` / `no` / `yes with risk` 어느 verdict 의 자동 승인도 아니다.

### 14.4 Deferred items (3-6 boundary 의 후속 결정)

본 anchor 는 다음을 fix 하지 않는다. 각각은 별도 scoped goal 의 대상으로 carry 한다.

- **boundary 진단 helper / check-only helper 의 도입 여부 / spec / 위치 / 이름.** managed-block 상태 inspect (BEGIN / END pair count, whole-line vs fenced quotation 구분, malformed / nested 보고) 및 skill destination 상태 inspect (`<GlobalSkillFile(name)>` 존재 / hash 비교) 의 read-only 진단 helper 는 본 anchor 가 도입을 자동 승인하지 않는다. `GLOBAL_ADOPTION_DECISION.md` §6 의 detection algorithm 과 `GLOBAL_ADOPTION_PROCEDURE.md` §5.1 / §6.1 의 pre-flight inspect 단계가 이미 procedural source-of-truth 이며, 이를 deterministic helper script (예: `scripts/managed-block-inspect.ps1`, `scripts/skill-status-inspect.ps1`) 로 풀어낼지 / 풀어내지 말지 / 풀어낸다면 어떤 surface 로 풀어낼지는 별도 scoped decision 으로 carry 한다. 본 anchor 는 helper 의 도입을 자동 승인하지 **않는다** 동시에 도입을 자동 금지하지도 **않는다** — helper 도입은 별도 explicit user-approved scope 의 사안이다.
- **managed-block apply 의 actual implementation script / surface** (예: `scripts/managed-block-apply.ps1` 또는 동등 surface). `GLOBAL_ADOPTION_DECISION.md` §6 의 destination 분기 (file 부재 / marker 0 개 / 정확히 1 개 / 불완전 / 여러 개 / malformed / nested) 를 따르는 actual writer 의 도입 여부 / 이름 / 위치 / signature / approval prompt UX 는 별도 scoped goal.
- **Claude skill install / update / removal 의 actual implementation script / surface** (예: `scripts/skill-apply.ps1` 또는 동등 surface). `GLOBAL_ADOPTION_PROCEDURE.md` §5 / §6 / §7 의 procedural source-of-truth 를 deterministic writer 로 풀어낼지의 결정은 별도 scoped goal.
- **boundary violation 의 detection / report mechanism.** install / update automation 본체가 실수로 managed-block / skill destination 을 건드리는 경우의 fail-fast detection (예: dispatcher 단계의 destination path allowlist check 또는 forbidden path guard 의 확장) 은 본 anchor 가 도입하지 않는다 — 본 anchor 는 `install-pipeline-core.ps1` 의 현행 `Get-ForbiddenInstallAreaPaths` 기반 guard 가 boundary 위반의 일부 (= `%USERPROFILE%\.claude` / `%USERPROFILE%\.codex` 의 descendant 로 `current/` 외 경로를 install 하려는 시도) 를 이미 감지함을 인정하지만, managed-block / skill destination 의 전체 enumeration 을 install-pipeline guard 로 promote 할지는 별도 scoped decision 이다.
- **3-6 의 implementation-level closeout** (actual managed-block / skill writer 가 도입된 뒤의 dry-run tests, evidence 보존, regression smoke). 본 anchor 가 boundary 정의로만 닫히므로, automation core 안의 dry-run 처럼 boundary-side 의 dry-run 도 deferred 다.

위 deferred 항목은 STEP3 guide §13.2 의 deferred enumeration 과 정합한다. 본 §14.4 가 그 enumeration 을 대체하거나 복제하지 않으며, §13.2 와 함께 보존된다 (§13.2 의 "3-6 managed block / skill replace boundary" 항목은 본 §14 anchor 의 부재 시점의 기록으로 historical 보존되며, 본 §14 가 그 항목의 핵심을 anchor 자리로 promote 한 결과 §13.2 의 동 항목은 §13.1 Completed 자리로 carry 됨 — §13 update 작업과 정합).

### 14.5 본 anchor 의 scope 와 non-goals

본 anchor 는 다음을 **포함한다**.

- §14.1 의 한 줄 boundary statement.
- §14.2 의 in-scope (boundary 정의 / governing source-of-truth 표기 / automation 본체 scope 한정 재진술 / managed-block destination path enumeration boundary 보존 / Claude skill source / destination shape boundary 보존 / deferred raise 자리 명시).
- §14.3 의 out-of-scope enumeration (actual apply 의 자동 승인 거부, automation core 의 묶음 apply 호출 금지, forbidden path, whole-file overwrite, marker detection algorithm 의 재정의 / 복제 거부 등).
- §14.4 의 deferred items (boundary 진단 helper, actual writer surface, boundary violation detection mechanism, implementation-level closeout).

본 anchor 는 다음을 **포함하지 않는다**.

- managed-block / skill 의 actual apply, mutation, refresh, install, update, removal.
- `GLOBAL_ADOPTION_DECISION.md` §6 의 marker / detection algorithm / destination path table / update policy 의 재정의 또는 복제.
- `GLOBAL_ADOPTION_PROCEDURE.md` 의 first install / update / removal 절차의 재정의 또는 복제.
- §6 canonical decomposition 의 ordering / numbering 변경.
- 부모 root-level docs 본문 mutation.
- install / update / restore 의 actual 실행, global / user filesystem mutation, target adoption, commit / push / publish / merge / release / Step 4 validation.

본 anchor 의 source / doc mutation 자체는 본 도구의 정상 review gate 를 거치며, review verdict 이후의 commit / push / global apply / managed-block apply / skill install / Step 4 validation 시작 등은 사용자 명시 결정으로 처리한다 (§8 / §10.7 / §11.8 / §12.11 / §13.3 와 정합).

---

## 15. Recorded payload integrity manifest + payload completeness marker contract

본 절은 §12.6 (3-5 verify path) 와 §11.6 (3-1 deferred items — payload integrity manifest, payload completeness marker) 에서 deferred 로 carry 되어 있던 두 항목 — **payload integrity manifest** 와 **payload completeness marker** — 의 최소 contract 를 anchor 한다. 본 anchor 는 install-pipeline temp-only skeleton (`scripts/install-pipeline.ps1` + `scripts/lib/install-pipeline-core.ps1`) 안에서 동작하는 contract 를 기록하며, actual `%USERPROFILE%\.claude` / `%USERPROFILE%\.codex` mutation 어느 것도 자동 승인하지 않는다.

본 anchor 는 §10 (3-0 layer layout) / §11 (3-1 install metadata contract) / §12 (3-2~3-5 runtime pipeline grouping) / §14 (3-6 managed-block / skill replace boundary) 위에 build 되며 그 결정을 약화하지 않는다. `docs/backlog/operations.md` 의 "Aggregate digest reproducibility — install/update verification scope debt" 항목과 정합하며, 본 anchor 는 그 backlog candidate (a) / (b) 중 **(b) per-file manifest** 를 채택한다. (a) deterministic aggregate digest algorithm 의 문서화 / 도입은 본 anchor 가 자동 승인하지 않으며, 별도 scoped goal 의 대상이다.

본 anchor 는 schema 의 contract 의미 (위치 / 이름 / 필드 / lifecycle / verify hook / failure 의미 / boundary) 만 기록한다. 실제 JSON Schema 파일 작성, validator implementation, network-based git-url mode 의 manifest 처리, payload completeness marker 의 entrypoint set finalize (= 어떤 구체 entrypoint 파일이 channel 3 활성 조건의 marker 안에 enumerate 되어야 하는지) 는 본 anchor 의 범위 밖이며 후속 scoped goal 의 일이다.

### 15.1 Algorithm choice (backlog candidate (b))

`docs/backlog/operations.md` "Aggregate digest reproducibility" 의 후보 (a) aggregate digest 와 (b) per-file manifest 중 **(b)** 를 채택한다.

근거:

- (a) 는 정렬 규칙 / 경로 정규화 / 줄바꿈 / BOM 처리 / 해시 결합 순서를 모두 명문화해야 하며, 한 항목이라도 변하면 expected digest 가 바뀐다. 본 backlog 항목이 직접 지목한 "재현 / 검증 불가" 문제의 원인이다.
- (b) 는 파일 단위 SHA-256 비교라서 단일 algorithm 결정으로 재현 가능하며, manifest schema 가 곧 검증 contract 다.
- (b) 채택은 (a) 의 도입을 금지하지 않는다. 후속 scoped goal 에서 (a) 를 도입하려면 본 §15 의 (b) 와 공존하거나 superseded note 를 두는 별도 scoped decision 이 필요하다 — 본 anchor 는 그 decision 을 자동 승인하지 않는다.

### 15.2 Payload integrity manifest

본 anchor 가 정의하는 manifest 의 최소 contract.

- **canonical filename**: `payload-manifest.json`.
- **위치**: global install area 의 `current/` 와 **sibling** (§10.4 boundary 와 정합 — `current/` 안에 두지 않는다, target project 안에 두지 않는다, source repo 의 tracked instance 로 두지 않는다, user-home 의 ai-harness-specific 별도 root 에 두지 않는다).
- **format**: JSON, UTF-8 no-BOM (`install.json` 과 동일 convention).
- **field set (minimum required)**:

  | 필드 | 의미 |
  |---|---|
  | `schemaVersion` | manifest schema 버전. initial value `1`. unknown 값은 reader fail-fast (silent downgrade 금지 — §11.3 와 동일 semantics). |
  | `tool` | `ai-harness-toolset` (constant). install.json `tool` 과 일치. |
  | `head` | manifest 생성 시점의 source HEAD commit SHA. install.json `lastUpdatedHead` 와 일치해야 한다 (verify 에서 검사). |
  | `createdAt` | manifest 생성 UTC 시각 (ISO 8601 `yyyy-MM-ddTHH:mm:ssZ`). |
  | `payloadRoots` | runtime payload root 이름 배열. constant `["config","scripts","snippets","templates"]` (§10.1 와 정합). |
  | `files` | manifest 본체 — `{ path, size, sha256 }` object 배열. `path` 는 forward-slash relative path from `current/` (예: `config/marker.txt`). `size` 는 byte 단위. `sha256` 은 lowercase hex (no separator). 배열은 `path` ascending sort (determinism 보장). |

- **entry 대상**: `current/<payloadRoots[i]>/**` 아래의 모든 regular file. directory 자체는 entry 가 아니다 (path 가 file path 인 경우만 enumerate).
- **금지**:
  - manifest 에 destination 의 diff 정보 / patch 정보 / user-edit metadata 도입 (§4 drift exclusion 과 정합).
  - manifest 에 release identifier (`releaseVersion`, `releaseTag` 등) 도입 (§11.7 forbidden enumeration 과 정합).
  - manifest 를 `current/` 안에 두는 것 (§10.2 와 정합).

### 15.3 Payload completeness marker

본 anchor 가 정의하는 marker 의 최소 contract.

- **canonical filename**: `payload-marker.json`.
- **위치**: global install area 의 `current/` 와 **sibling** (§10.4 boundary 와 정합).
- **format**: JSON, UTF-8 no-BOM.
- **field set (minimum required)**:

  | 필드 | 의미 |
  |---|---|
  | `schemaVersion` | marker schema 버전. initial value `1`. unknown 값은 reader fail-fast. |
  | `tool` | `ai-harness-toolset` (constant). |
  | `head` | marker 생성 시점의 source HEAD commit SHA. install.json `lastUpdatedHead` 와 일치해야 한다. |
  | `createdAt` | marker 생성 UTC 시각. |
  | `manifestPath` | manifest 의 sibling 경로 — constant `payload-manifest.json`. |
  | `payloadRoots` | constant `["config","scripts","snippets","templates"]`. manifest 의 `payloadRoots` 와 일치해야 한다. |

- **semantic**: marker 의 존재 == 본 라운드의 materialization 이 manifest 작성까지 완료되었다는 presence flag. marker 가 부재하면 channel 3 활성은 fail-fast 의 근거가 된다 (§11.6 의 "channel 3 활성 조건의 marker" framing 과 정합).
- **entrypoint set finalize 는 본 anchor 의 범위 밖**: marker 는 본 anchor 에서 **단순 presence flag + integrity binding** 이다. "어떤 구체 entrypoint 파일이 marker 안에 enumerate 되어야 channel 3 가 활성되는가" 의 finalize 는 별도 scoped goal (§11.6 / §12.6 의 deferred 항목 그대로). 본 anchor 는 entrypoint set 도입을 자동 승인하지 않으며, 도입을 자동 금지하지도 않는다.
- **금지**:
  - marker 에 user-edit preservation flag / 자동 managed-block apply trigger / 자동 skill refresh trigger 도입 (§11.7 / §14.3 와 정합).
  - marker 를 `current/` 안에 두는 것 (§10.2 와 정합).

### 15.4 Lifecycle (write / verify hook)

manifest / marker 의 lifecycle 은 §12.1 pipeline 의 metadata write 단계와 verify 단계에 정합 hook 된다.

- **write hook (materialization 직후, metadata write 이전)**:
  1. `Invoke-InstallMaterialization` 가 `current/` 의 payload root 들을 source ref 기준으로 deterministic overwrite materialize.
  2. 본 hook 가 `current/` 아래의 모든 regular file 을 enumerate 하고 `path` ascending sort 한 뒤 각 file 의 size + SHA-256 을 계산.
  3. manifest 와 marker 를 sibling-of-`current/` 자리에 write (둘 다 JSON UTF-8 no-BOM).
  4. 그 뒤에 install.json (metadata) 를 write — install.json 의 `installedHead` / `lastUpdatedHead` 와 manifest / marker 의 `head` 가 일치해야 한다.
- **verify hook (`Invoke-InstallPipelineVerify` 안)**:
  1. metadata read (§12.6 의 metadata binding 검증 그대로).
  2. manifest read — schemaVersion / tool / head / payloadRoots constant 검증.
  3. manifest 의 `files` 각 entry 에 대해 `current/<path>` 의 실제 size + SHA-256 을 재계산하여 비교. 불일치 / missing entry / extra entry 모두 verify error.
  4. marker read — schemaVersion / tool / head / manifestPath / payloadRoots constant 검증.
  5. marker.head == manifest.head == metadata.lastUpdatedHead 의 cross-binding 검증.
- **failure semantics**:
  - manifest 부재 / unreadable / unknown schemaVersion / head mismatch / files mismatch → verify error 로 보고 (fail-fast; silent skip 금지).
  - marker 부재 / unreadable / unknown schemaVersion / head mismatch → verify error 로 보고.
  - manifest 와 marker 가 모두 부재면 두 error 모두 report (어느 한쪽의 부재로 다른 쪽 검증을 skip 하지 않는다).

### 15.5 Mode coverage

본 anchor 가 cover 하는 mode 와 cover 하지 않는 mode 의 분리.

- **cover (본 anchor 의 contract 가 적용되는 범위)**:
  - local-clone mode 의 `install` / `update-source` / `update-current` / `restore` 4 action — 본 라운드의 implementation 이 모두 manifest + marker 를 write / verify 한다.
- **not cover (별도 scoped goal)**:
  - git-url mode 의 actual network fetch 경로 (clone / fetch / pull / clone recovery). 본 anchor 의 manifest contract 는 git-url mode 에도 동일하게 적용 가능한 schema 이지만, network-based source 처리의 implementation 은 별도 scoped goal (STEP3 guide §13.2 deferred 의 "git-url mode 의 actual source acquisition / network fetch" 와 정합).
  - source-cut path 의 실제 처리 후의 manifest 재작성 (§12.7 의 detection-only boundary 와 정합).
  - actual global install area (`%USERPROFILE%\.claude\ai-harness-toolset\current`) 에 대한 manifest / marker write — actual mutation 은 별도 explicit user-approved scope (§10.6 / §14 와 정합).

### 15.6 Deferred items (본 anchor 의 범위 밖)

본 anchor 는 다음을 fix 하지 않는다.

- **entrypoint set finalize** (§11.6 / §12.6 의 deferred 항목 그대로). marker 가 단순 presence flag 인지 / 어떤 entrypoint 파일을 enumerate 해야 하는지의 final decision 은 후속 scoped goal.
- **aggregate digest algorithm** (backlog candidate (a)). 본 anchor 가 (b) per-file manifest 만 채택하므로, (a) 는 별도 scoped goal 의 대상.
- **manifest / marker schema version bump migration writer** (§11.3 와 동일 framing — bump 시 기존 manifest 의 자동 conversion 절차).
- **manifest 외부 검증 tool / linter / 자동 검사 mechanism**. backlog "Aggregate digest reproducibility" §Non-goals 와 정합.
- **payload-marker.json 의 channel 3 활성 조건 hook 의 actual implementation** — `Get-ToolRoot` channel 3 resolver 가 marker 부재를 fail-fast 조건으로 사용할지의 결정은 별도 scoped goal.
- **target adoption / external target 에 대한 manifest / marker** — target project 는 payload destination 이 아니다 (§5 / §10.3 / §14 와 정합).

### 15.7 본 anchor 의 scope 와 non-goals

본 anchor 는 다음을 **포함한다**.

- §15.1 의 algorithm choice (backlog candidate (b) per-file manifest 채택).
- §15.2 의 manifest contract (filename / 위치 / format / field set / 금지).
- §15.3 의 marker contract (filename / 위치 / format / field set / semantic / 금지).
- §15.4 의 lifecycle (write hook + verify hook + failure semantics).
- §15.5 의 mode coverage (local-clone cover, git-url / source-cut / actual global apply 별도 scoped).
- §15.6 의 deferred items (entrypoint set finalize, aggregate digest algorithm, schema bump migration writer, 외부 검증 tool, channel 3 활성 hook 의 actual, target adoption).

본 anchor 는 다음을 **포함하지 않는다**.

- actual global / user filesystem mutation (`%USERPROFILE%\.claude\ai-harness-toolset\current` 또는 그 sibling 의 manifest / marker write).
- git-url mode 의 actual network fetch 동작 implementation.
- source-cut path 의 실제 처리.
- managed-block apply / Claude skill install / update / removal.
- Step 4 validation 시작.
- 부모 root-level docs (`GLOBAL_INSTALL_UPDATE_MODEL.md`, `GLOBAL_ADOPTION_DECISION.md`, `GLOBAL_ADOPTION_PROCEDURE.md`) 본문 mutation. 본 anchor 는 STEP3 guide subordinate scope 안에서 닫는다.
- §6 canonical decomposition 의 ordering / numbering 변경. manifest / marker contract 는 §6 의 9 단계 중 어느 단일 sub-step 의 재정의가 아니라 §11.6 / §12.6 deferred 의 closeout 이다.
- commit / push / publish / merge / release / adoption.

본 anchor 는 `yes` / `no` / `yes with risk` 어느 verdict 의 자동 승인도 아니다. anchor 의 source / doc / test mutation 자체는 본 도구의 정상 review gate 를 거치며, review verdict 이후의 commit / push / global apply / Step 4 validation 시작 등은 사용자 명시 결정으로 처리한다 (§8 / §10.7 / §11.8 / §12.11 / §13.3 / §14.5 와 정합).

---

## 16. Recorded git-url mode minimum source acquisition contract

본 절은 §12.3 의 3-2 resolver 의 git-url mode resolution path 와 §13.2 deferred 의 "git-url mode 의 실제 source acquisition / network fetch" 항목 중 **deterministic 한 local repository 기반 source acquisition 의 최소 contract** 를 anchor 한다. 본 anchor 는 §10.5 의 source-cache layer "본 anchor 가 layer 도입 자체를 채택하지 않는다 — 3-3 / 3-4 단계에서 드러나면 그때 layer 신설 여부를 재평가" 의 후속 reassessment 결과로, **source-cache layer 를 본 §16 에서 채택** 한다. 본 anchor 는 implementation, actual `%USERPROFILE%\.claude` / `%USERPROFILE%\.codex` mutation, credential / auth / network failure recovery / clone recovery, Step 4 validation 어느 것도 자동 승인하지 않는다.

본 anchor 는 §10 (3-0 layer layout) / §11 (3-1 install metadata contract) / §12 (3-2~3-5 runtime pipeline grouping) / §14 (3-6 managed-block / skill replace boundary) / §15 (manifest + marker minimum contract) 위에 build 되며 그 결정을 약화하지 않는다.

### 16.1 Algorithm choice (minimum 범위)

본 anchor 는 git-url mode 의 acquisition 을 **local git repository operations only** 로 좁힌다 — `git clone <repoUrl>` / `git -C <cache> fetch` / `git -C <cache> rev-parse` / `git -C <cache> archive`. external GitHub / public network 대역 자체에 대한 actual reachability / 인증 / credential / proxy / mirror 정책은 본 anchor 의 범위가 아니다. 본 anchor 는 user environment 가 이미 git CLI 에서 `repoUrl` 에 도달 가능하다는 것을 전제로 한 deterministic 한 local git operation contract 만 정의한다.

### 16.2 Source cache layer (`source-cache/`)

본 anchor 가 §10.5 의 deferred source-cache layer 결정을 마감한다.

- **canonical location**: `<InstallArea>/source-cache/` — `current/` / `install.json` / `payload-manifest.json` / `payload-marker.json` 와 **sibling** (§10.4 boundary 와 정합).
- **layout**: 하나의 git clone (normal clone, not bare) 이 directly under `<InstallArea>/source-cache/`. multi-cache / per-ref subdirectory 는 본 anchor 가 도입하지 않는다 (single-cache-per-InstallArea).
- **format**: standard git repo (working tree + `.git/`). bare clone 채택은 deferred (working tree 가 있는 normal clone 이 `git archive` / `git rev-parse` 양쪽에 가장 단순하므로 minimum 채택).
- **identification**: cache 는 implicit 하게 InstallArea 의 metadata.repoUrl 과 일치한다. 본 anchor 는 cache 자체에 origin URL identity 검증 (cache 의 `git config remote.origin.url` 이 metadata.repoUrl 과 일치하는지) 을 도입하지 **않는다** — drift 가 발생하면 source-cut detection (§12.7) 의 영역이다.
- **금지** (§10.6 / §14 / §15 와 정합):
  - cache 를 `current/` 안에 두는 것.
  - cache 를 target project 안에 두는 것.
  - cache 를 source repo 의 tracked 항목으로 두는 것.
  - cache 안의 파일을 manifest / marker entry 대상에 포함하는 것 (§15 의 manifest 는 `current/<payloadRoots>/**` 만 enumerate; cache 는 enumeration 범위 밖).

### 16.3 Per-action lifecycle (git-url mode)

| action | cache 상태 전제 | network operation | ref resolve source | materialization source |
|---|---|---|---|---|
| **install** | cache 없거나 비어 있음 (fresh) | `git clone <repoUrl> <cache>` (single clone) | cache 의 `git rev-parse HEAD` | cache `git archive` |
| **update-source** | cache 가 valid git repo (fail-fast otherwise) | `git -C <cache> fetch origin <branch>` | cache 의 `git rev-parse origin/<branch>` (fetch 후) | cache `git archive` |
| **update-current** | cache 가 valid git repo (fail-fast otherwise) | **없음** — network 호출 안 함 | cache 의 `git rev-parse HEAD` | cache `git archive` |
| **restore** | cache 가 valid git repo (fail-fast otherwise) | **없음** — network 호출 안 함 | cache 의 `git rev-parse --verify <user-ref>^{commit}` | cache `git archive` |

본 lifecycle 의 명시 boundary:

- install 이 아닌 action 에서 cache 가 부재하면 **clone recovery 를 수행하지 않는다** — 본 minimum 에서는 fail-fast 만 보장한다. **clone recovery 는 deferred** (§16.6 / `GLOBAL_INSTALL_UPDATE_MODEL.md` §4.2 의 "ToolRoot 가 사라졌으면 `repoUrl` 로 clone recovery 를 수행한다" wording 의 actual 구현이 본 anchor 의 범위 밖).
- update-current / restore 는 network 호출이 없다 (§12.3 의 "update-current 는 fetch 없이 현재 HEAD 만 read" / "restore 는 user-specified `--ref` 가 필수" 와 정합).
- restore 의 ref 가 cache 에 존재하지 않으면 (예: fetch 되지 않은 remote-only ref) fail-fast — 자동 fetch fallback 금지 (§7 #1 / §11.4 (b) 와 정합).

### 16.4 Failure preservation (atomicity)

본 anchor 의 fail-fast 는 다음 invariant 를 유지한다.

- **fresh install (clone) 실패**: cache 디렉터리가 partial 상태로 남을 수 있으나, `current/` / `install.json` / manifest / marker 는 아직 작성 전 단계 이므로 본 InstallArea 의 deliverable artifact 는 영향 없음. 후속 install attempt 는 cache 를 clean up 한 뒤 진행해야 한다 (운영자 명시 cleanup).
- **update-source 의 fetch 실패**: fetch 가 ref resolve / materialization **이전** 에 실행되며, 실패 시 그 단계에서 throw → dispatcher 가 진행하지 않으므로 `current/` / `install.json` / manifest / marker 의 **byte-identity 보존**.
- **ref resolve 실패** (restore 의 사용자 ref 가 cache 에 없는 경우, 또는 update-source 의 fetched ref 가 invalid): `Resolve-InstallPipelineRef` / `Get-InstallPipelineSourceHead` 가 throw → `Invoke-InstallMaterialization` 진입 전 이므로 `current/` 와 그 sibling artifact 모두 byte-identity 보존.
- **clone 자체 실패 (install)**: cache 가 partial 일 수 있으나 deliverable artifact 는 아직 작성되지 않은 단계.

본 invariant 는 §12.4 (materialization core) 의 "destination 의 byte-identity overwrite materialization" boundary 와 정합한다. fetch / resolve 단계는 materialization 이전 의 read-only / network-only / cache-only operation 이며, destination 의 partial mutation 을 발생시키지 않는다.

### 16.5 toolRoot semantics (git-url mode)

`install.json` 의 `toolRoot` field (§11.1) 의 git-url mode 값은 **cache 의 absolute path** (`<InstallArea>/source-cache/`) 다 — 부모 §6 Layer 1 의 "canonical local ToolRoot = local clone of the GitHub repo" 와 정합. local-clone mode 의 toolRoot 가 사용자 supply 의 sourcePath 였던 것과 달리, git-url mode 의 toolRoot 는 본 도구가 deterministic 하게 install area 안에 cache 한 path 다.

resolver tuple 의 `toolRoot` field 도 동일한 cache absolute path 다. `sourceLocation` 은 사용자 facing identifier (URL 자체) 다 — 둘은 별개 concept 이며, `Invoke-InstallMaterialization` 의 git-archive source 는 **tuple.toolRoot (= cache path)** 를 사용한다. 이 분리는 §12.3 의 "tuple `toolRoot` 는 §11.1 metadata `toolRoot` 와 동일한 source-side canonical local ToolRoot" framing 과 정합한다.

### 16.6 Deferred items (§16 의 범위 밖)

본 anchor 는 다음을 fix 하지 않는다.

- **credential / auth handling** — HTTPS basic auth, SSH key, PAT, Windows credential helper, proxy 처리 등의 actual implementation. user environment 가 이미 git CLI 에서 `repoUrl` 에 도달 가능하다는 것을 전제로 한다.
- **clone recovery** — non-install action 에서 cache 가 부재한 경우의 자동 re-clone. 본 anchor 는 fail-fast 만 보장하며, recovery 는 별도 scoped goal.
- **multi-cache / per-ref cache subdirectory** — 다양한 ref 의 동시 cache 보존. 본 anchor 는 single-cache-per-InstallArea 만 채택.
- **bare clone 채택** — cache 의 bare repo 변환. 본 anchor 는 normal clone (working tree + `.git/`) 만 채택.
- **cache identity verification** — cache 의 `remote.origin.url` 이 metadata.repoUrl 과 일치하는지의 자동 검증. drift 는 source-cut detection (§12.7) 의 영역.
- **fetch retry / backoff / partial fetch / shallow clone** — network 신뢰성 / 효율성을 위한 정책. 본 anchor 는 single-attempt fetch 만 채택.
- **HTTP / HTTPS / SSH / git protocol** 의 specific 처리 — 본 anchor 는 git CLI 가 알아서 처리하는 것으로 가정.
- **submodule** 처리 — `ai-harness-toolset` 자체가 submodule 을 사용하지 않으므로 본 anchor 는 submodule clone / update / fetch 를 다루지 않는다.
- **`schemaVersion` migration writer** (§11.3 / §11.6 / §15.6 deferred 그대로).
- **source-cut path 의 실제 처리** (§12.7 와 정합).
- **actual `%USERPROFILE%\.claude` / `%USERPROFILE%\.codex` 안의 git-url install / update** — actual global apply 는 별도 explicit user-approved scope.

### 16.7 Test fixture boundary

본 anchor 의 Pester dry-run tests 는 다음 fixture 만 사용한다.

- **local bare repo** — `git clone --bare <local-source-repo> <local-bare-repo>` 로 만든 bare repo 의 absolute path 를 `-RepoUrl` 로 전달.
- **file URL fixture** — 동일 local bare repo 를 `file:///<path>` URL 로 전달 (optional; git CLI 가 path 만으로 처리 가능하면 path 만 사용).

본 anchor 는 다음을 **금지** 한다.

- 외부 GitHub / 외부 network remote 에 대한 actual reachability 의존.
- Pester test 의 PASS / FAIL 이 외부 network 상태에 좌우되는 fixture.
- credential / auth 가 필요한 fixture.

### 16.8 본 anchor 의 scope 와 non-goals

본 anchor 는 다음을 **포함한다**.

- §16.1 의 algorithm choice (local git repository operations only).
- §16.2 의 source-cache layer (canonical location / layout / format / identification / 금지).
- §16.3 의 per-action lifecycle (install / update-source / update-current / restore 4 action 의 cache 전제 / network / ref resolve / materialization source).
- §16.4 의 failure preservation invariant (fetch / resolve 실패 시 deliverable artifact byte-identity 보존).
- §16.5 의 toolRoot semantics (cache absolute path).
- §16.6 의 deferred items (credential / auth / clone recovery / multi-cache / bare / identity / retry / protocol / submodule / migration writer / source-cut / actual global apply).
- §16.7 의 test fixture boundary (local bare repo / file URL only).

본 anchor 는 다음을 **포함하지 않는다**.

- actual `%USERPROFILE%\.claude` / `%USERPROFILE%\.codex` 안의 git-url install / update / refresh / mutation.
- external GitHub / network reachability 에 의존하는 test.
- credential / auth / proxy / mirror 처리.
- clone recovery / multi-cache / shallow clone / bare clone / submodule / migration writer.
- source-cut path 의 실제 처리.
- managed-block apply / Claude skill install / update / removal.
- Step 4 validation 시작.
- 부모 root-level docs 본문 mutation. 본 anchor 는 STEP3 guide subordinate scope 안에서 닫는다.
- §6 canonical decomposition (9 단계 ordering / numbering) 변경.
- commit / push / publish / merge / release / adoption.

본 anchor 는 `yes` / `no` / `yes with risk` 어느 verdict 의 자동 승인도 아니다. anchor 의 source / doc / test mutation 자체는 본 도구의 정상 review gate 를 거치며, review verdict 이후의 commit / push / global apply / Step 4 validation 시작 등은 사용자 명시 결정으로 처리한다 (§8 / §10.7 / §11.8 / §12.11 / §13.3 / §14.5 / §15.7 와 정합).

---

## 17. Recorded Step 3 source-cut path actual handling decision anchor

본 절은 §12.7 (source-cut detection — resolver level only) 와 §13.2 deferred 의 "source-cut path 의 실제 처리" 항목에 대한 **decision anchor** 다. 본 anchor 는 actual handling 의 처리 방식을 **"deferred with exact boundary"** 로 고정한다 — 즉, 본 라운드의 Step 3 어디서도 source-cut path 의 actual handling implementation 으로 확장하지 않으며, deferred 의 boundary 를 본 §17 에서 한 번 종합한다.

본 anchor 는 §10 (3-0 layer layout) / §11 (3-1 install metadata contract) / §12 (3-2~3-5 runtime pipeline grouping) / §14 (3-6 managed-block / skill replace boundary) / §15 (manifest + marker minimum contract) / §16 (git-url mode minimum source acquisition contract) 위에 build 되며 그 결정을 약화하지 않는다. 본 anchor 는 source-cut handler 의 신규 implementation, install-pipeline 의 source-cut 자동 처리 함수 추가, 신규 test 추가, actual `%USERPROFILE%\.claude` / `%USERPROFILE%\.codex` mutation, Step 4 validation 어느 것도 자동 승인하지 않는다.

### 17.1 Decision

source-cut path 의 actual handling 은 **deferred with exact boundary** 다. 본 anchor 는 다음 두 가지를 동시에 anchor 한다.

- **현 라운드의 in-scope behavior 는 §12.7 의 resolver detection-only / dispatcher non-process / STOP 그대로** — 본 anchor 가 그 behavior 를 변경하지 않는다.
- **actual handling 의 future scope 는 별도 explicit user-approved goal 로 carry** — 본 anchor 가 future handler 의 신규 함수 surface / 명령 / approve UX / metadata mutation 절차 / source-cache lifecycle 어느 것도 fix 하지 않는다.

`explicit unsupported fail-fast now` 는 본 anchor 의 선택지가 **아니다** — source-cut 의 future implementation 자체를 영구히 무지원으로 닫지 않는다. 본 anchor 는 future implementation 의 **자동 승인을 거부** 할 뿐이며, future scoped goal 의 가능성을 보존한다. `minimum support now` 도 본 anchor 의 선택지가 아니다 — 본 라운드는 어떤 minimal source-cut handler 의 도입도 자동 승인하지 않는다.

### 17.2 Mode separation (3 concept boundary)

**local-clone mode / git-url mode / source-cut path** 의 의미를 본 anchor 가 한 자리에 명시한다. 셋의 의미가 섞이지 않도록 boundary 를 분리한다.

- **local-clone mode** — `installMode == "local-clone"` 인 single source acquisition channel. metadata 의 `sourcePath` (+ `toolRoot`) 가 source resolution 의 입력이며, `Invoke-InstallPipelineNativeGit` 으로 `git archive` 가 그 source 에서 ref-specific snapshot 을 만든다 (§12.3 / §16.5 와 정합). cache-free behavior 다.
- **git-url mode** — `installMode == "git-url"` 인 single source acquisition channel. metadata 의 `repoUrl` (+ `branch` / `remote` / `toolRoot=<InstallArea>/source-cache/`) 가 source resolution 의 입력이며, `<InstallArea>/source-cache/` 의 single normal clone 이 §16 의 lifecycle (clone / fetch / cache-local ref resolve / cache `git archive`) 을 수행한다.
- **source-cut path** — source acquisition mode 의 **변경** 또는 동일 mode 안의 source identity (`repoUrl` / `sourcePath` / `toolRoot` / `branch` / `remote`) 의 변경. 이는 **세 번째 mode 가 아니다** — local-clone 과 git-url 은 mutually exclusive 한 두 mode 이며, source-cut 은 한 InstallArea 의 metadata 가 그 두 mode 사이를 옮기거나 동일 mode 안의 source identity field 가 바뀌려는 **mutation class** 다.

두 mode 의 lifecycle 은 본 anchor 의 결정과 독립적이다. 본 anchor 는 두 mode 의 어느 lifecycle (§12 / §15 / §16) 도 약화하지 않는다 — 본 anchor 가 anchor 하는 것은 **mutation class 의 deferred boundary** 뿐이다.

### 17.3 Source-cut trigger fields (재anchor)

§12.7 가 enumerate 한 source-cut trigger field 6 개를 본 anchor 가 그대로 보존한다 (재정의가 아니며, §12.7 의 enumeration 을 본 anchor 에 복제 anchor 한다).

- `installMode` (git-url ↔ local-clone)
- `repoUrl`
- `sourcePath`
- `toolRoot`
- `branch`
- `remote`

invocation params 가 위 field 중 어느 하나라도 metadata 와 다르면 source-cut 으로 분류되어 §12.7 의 resolver STOP / dispatcher non-process 가 발생한다. 본 anchor 는 위 enumeration 의 추가 / 삭제 / 재정의를 자동 승인하지 않는다.

### 17.4 In-scope behavior at this anchor (no change from §12.7)

본 anchor 는 다음 behavior 를 보존만 한다 — 추가 / 변경 어느 것도 도입하지 않는다.

- resolver 가 source-cut 을 감지 (URL normalization 후 §17.3 의 6 field 비교) 하여 `sourceCutDetected=true` 로 표시 (§12.3 / §12.7 와 정합).
- dispatcher 가 `sourceCutDetected=true` 인 resolved tuple 을 진행하지 않음 — STOP / 사용자 보고 (§12.5 / §12.7 와 정합).
- destination artifact (`current/` / `install.json` / `payload-manifest.json` / `payload-marker.json`) 의 byte-identity 보존 (§12.4 의 materialization core atomicity, §15.4 의 manifest / marker write hook 의 metadata-write-이전 단계, §16.4 의 fetch / resolve 실패의 materialization-이전 단계 invariant 와 정합).
- §12.9 의 key failure cases 중 "source-cut detected" 의 exit non-zero / 사유 message / 다음 사용자 행동 안내 형식 그대로.
- §13.1 의 3-7 dry-run coverage extension (commit `3bff209`) 에 이미 anchored / tested 인 "source-cut 거부 후 `current/` byte-identity 보존" Pester case 그대로 유지.

본 in-scope behavior 는 §12 라운드 (commit `f11ed27`) 와 3-7 dry-run coverage extension (commit `3bff209`) 에서 이미 anchored / tested 상태다. 본 §17 anchor 는 그 behavior 에 어떠한 implementation 변경도 추가하지 않는다.

### 17.5 Deferred boundary (별도 explicit user-approved goal 의 대상)

본 anchor 가 deferred 로 carry 하는 항목은 다음과 같다. 각 항목은 별도 scoped goal 의 explicit user-approved decision 으로만 진행한다. 본 enumeration 은 §13.2 의 "source-cut path 의 실제 처리" 항목을 본 자리에서 한 번 종합한 결과이며, §12.7 의 "별도 explicit user-approved scope" wording 의 boundary closeout 이다.

- **재install handler** — source-cut detected 시 invocation params 에 정합한 새 install 절차로 자동 전환할지의 결정 / 형태 / approve UX. 본 anchor 는 어떠한 자동 전환도 거부한다.
- **metadata mutation writer** — `installMode` / `repoUrl` / `sourcePath` / `toolRoot` / `branch` / `remote` 중 일부 또는 전부의 in-place 갱신 절차 (§11.1 14-field schema 위에서의 partial mutation 형태). 본 anchor 는 어떤 in-place mutation 도 자동 승인하지 않는다.
- **new install path / cutover 절차** — 기존 InstallArea 를 보존하면서 별도 InstallArea 로 install 하는 절차, 또는 기존 InstallArea 를 retire 하고 새 InstallArea 로 cutover 하는 절차. 본 anchor 는 어떤 cutover 도 자동 승인하지 않는다.
- **approve UX / explicit confirmation prompt** — source-cut 처리의 사용자 명시 승인 UX (warning prompt / `--allow-source-cut` flag / 별도 explicit command surface 등) 의 final shape. 본 anchor 는 어떤 UX 도 fix 하지 않는다.
- **source-cache lifecycle on mode change** — git-url ↔ local-clone mode 변경 또는 git-url 안의 `repoUrl` / `branch` / `remote` 변경 시 기존 `<InstallArea>/source-cache/` 의 cleanup / 보존 / 재clone 절차 (§16.2 single-cache-per-InstallArea boundary 위에서의 lifecycle 결정). 본 anchor 는 어떤 cleanup 절차도 자동 승인하지 않는다.
- **`schemaVersion` 의 source-cut-related field 추가** — 별도 field (예: `sourceCutHistory`, `previousInstallMode`, `cutoverAt` 등) 의 도입은 별도 scoped decision (§11.3 / §11.6 의 schema bump migration writer deferred 그대로 와 정합).
- **source-cut path 와 dogfooding mode (§12.8) 의 interaction** — dogfooding mode 에서의 source-cut 처리의 추가 보호 layer 도입 여부 / final shape. 본 anchor 는 §12.8 의 dogfooding silent-mutation 보호를 그대로 보존하며, source-cut 과의 interaction enforcement 는 별도 scoped goal.
- **source-cut path 의 manifest / marker 재작성 절차** — source-cut handling 후 §15 의 `payload-manifest.json` / `payload-marker.json` 의 재작성 hook 의 정확한 순서 / boundary. 본 anchor 는 §15.5 의 "source-cut path 의 실제 처리 후의 manifest 재작성" deferred 그대로 와 정합.

### 17.6 Forbidden in this anchor

본 anchor 는 다음을 금지한다 (§10.6 / §11.7 / §12.11 / §13.3 / §14.3 / §15.7 / §16.8 와 정합).

- source-cut handler 의 신규 implementation. `scripts/install-pipeline.ps1`, `scripts/lib/install-pipeline-core.ps1` 에 source-cut 자동 처리 함수 / branch / parameter 추가.
- `tests/install-pipeline.Tests.ps1` 의 source-cut handling test 신규 추가 (현행 source-cut detection / STOP / byte-identity preservation tests 그대로 유지).
- 어떤 invocation flag / parameter 도입으로 source-cut 의 자동 처리를 활성화하는 변경.
- §12.7 의 resolver detection-only / dispatcher non-process / STOP boundary 의 약화.
- metadata 의 `installMode` / `repoUrl` / `sourcePath` / `toolRoot` / `branch` / `remote` 의 in-place mutation.
- §11.1 의 14-field install metadata schema 변경.
- §15 의 manifest / marker schema 변경, §16 의 source-cache lifecycle 변경.
- actual `%USERPROFILE%\.claude` / `%USERPROFILE%\.codex` mutation.
- managed-block apply / Claude skill install / update / removal (§14 boundary 와 정합).
- Step 4 validation 시작.
- snapshot / payload manifest / payload marker 생성 (본 anchor 는 docs-only).
- 부모 root-level docs (`GLOBAL_INSTALL_UPDATE_MODEL.md`, `GLOBAL_ADOPTION_DECISION.md`, `GLOBAL_ADOPTION_PROCEDURE.md`) 본문 mutation.
- `docs/backlog/operations.md` 의 기존 항목 status 변경.
- §6 canonical decomposition (9 단계 ordering / numbering) 변경.
- commit / push / publish / merge / release / adoption.

### 17.7 본 anchor 의 scope 와 non-goals

본 anchor 는 다음을 **포함한다**.

- §17.1 의 decision (`deferred with exact boundary`) anchor.
- §17.2 의 3 concept (local-clone mode / git-url mode / source-cut path) boundary separation.
- §17.3 의 trigger field 6 개 재anchor (§12.7 와 1:1 정합).
- §17.4 의 in-scope behavior 보존 (§12.7 unchanged).
- §17.5 의 deferred boundary enumeration (별도 scoped goal 의 대상 항목 8 개).
- §17.6 의 forbidden enumeration.

본 anchor 는 다음을 **포함하지 않는다**.

- source-cut 처리의 actual implementation / 신규 함수 / 신규 test.
- §12.7 의 resolver / dispatcher behavior 변경.
- §11.1 의 install metadata schema 변경.
- §15 의 manifest / marker contract 변경.
- §16 의 git-url mode source-cache lifecycle 변경.
- 부모 root-level docs 본문 mutation. 본 anchor 는 STEP3 guide subordinate scope 안에서 닫는다.
- §6 canonical decomposition 의 ordering / numbering 변경. source-cut path 의 deferred boundary 는 §6 의 9 단계 중 어느 단일 sub-step 의 재정의가 아니라 §12.7 deferred 의 closeout anchor 다.
- actual global / user filesystem mutation, target adoption, commit / push / publish / merge / release / Step 4 validation.

본 anchor 는 `yes` / `no` / `yes with risk` 어느 verdict 의 자동 승인도 아니다. anchor 의 source / doc mutation 자체는 본 도구의 정상 review gate 를 거치며, review verdict 이후의 commit / push / global apply / Step 4 validation 시작 등은 사용자 명시 결정으로 처리한다 (§8 / §10.7 / §11.8 / §12.11 / §13.3 / §14.5 / §15.7 / §16.8 와 정합).

---

## 18. Recorded Step 3 dogfooding enforcement final shape decision anchor

본 절은 §12.8 (Dogfooding mode boundary) 의 마지막 문장 ("본 boundary 의 정확한 enforcement mechanism (warning prompt / `--allow-dogfood-mutation` flag 등) 은 implementation 시점에 결정 — 본 anchor 가 fix 하지 않는다") 과 §13.2 deferred 의 "dogfooding enforcement mechanism 의 final shape" 항목에 대한 **decision anchor** 다. 본 anchor 는 dogfooding mode 에서의 silent-mutation 보호의 **final shape** 를 docs-only 로 고정한다.

본 anchor 는 §10 (3-0 layer layout) / §11 (3-1 install metadata contract) / §12 (3-2~3-5 runtime pipeline grouping) / §14 (3-6 managed-block / skill replace boundary) / §15 (manifest + marker minimum contract) / §16 (git-url mode minimum source acquisition contract) / §17 (source-cut path actual handling decision anchor) 위에 build 되며 그 결정을 약화하지 않는다. 본 anchor 는 dogfooding enforcement 의 신규 implementation, install-pipeline 에 새 함수 / 새 flag 추가, 신규 Pester test 추가, actual `%USERPROFILE%\.claude` / `%USERPROFILE%\.codex` mutation, Step 4 validation 어느 것도 자동 승인하지 않는다.

### 18.1 Decision

dogfooding enforcement 의 final shape 는 다음 5 개 명제로 docs-only 고정된다.

- **explicit-flag bypass 모델** — silent mutation 위험 action 은 default fail-fast STOP 이며, 사용자 명시 flag (`-AllowDogfoodSource`) 가 있을 때만 진행한다. warning-only mode (메시지 출력 후 그대로 진행), 자동 stash / 자동 commit / 자동 dirty-tree cleanup, interactive prompt 어느 것도 final shape 가 아니다.
- **strict mode confinement** — dogfooding enforcement 는 **local-clone mode 에만 적용** 된다. git-url mode 의 source 는 `<InstallArea>/source-cache/` 의 normal clone 이므로 user dev checkout 과 구조적으로 분리되어 있다 (§16.2 / §16.5 와 정합). git-url mode 에서는 dogfooding detection 이 발생하지 않는다.
- **action × mode 별 boundary 명시** — `install` / `update-source` / `update-current` / `restore` 4 action 각각에 대해 dogfooding mode 에서의 allowed / blocked / explicit-confirm-required 결정이 §18.4 에서 한 자리에 enumerate 된다.
- **5 tree separation invariant** — source repo working tree, global current, InstallArea, source-cache, ProjectRoot.log 이 서로 섞이지 않는 invariant 를 §18.3 에서 한 자리에 anchor 한다.
- **docs-only anchor** — 본 anchor 는 신규 implementation / 새 함수 / 새 test / 새 flag 어느 것도 도입하지 않는다. 현행 skeleton (`-AllowDogfoodSource` switch, `Test-InstallPipelineDogfoodingSource` helper, 3-7 dry-run coverage extension 의 "dogfooding `update-source` 거부 후 source repo HEAD 무변경" Pester case) 의 as-built 행동을 final shape 로 anchor 한다.

`warning-then-proceed` 모델도 `interactive prompt` 모델도 본 anchor 의 final shape 가 **아니다** — 이유: (a) prompt 는 non-interactive operation (CI / scripted invocation / Claude Code agent-driven invocation) 을 깨뜨린다. (b) warning-only 는 silent mutation 의 실질 방지가 되지 않는다 — warning 출력 후에도 mutation 이 진행되면 사용자가 stop 할 수 있는 명시 boundary 가 없다. (c) explicit flag 는 shell history / agent invocation log 에 그대로 남아 audit / replay 가능한 명시 결정 기록이다.

### 18.2 Dogfooding detection (re-anchor of §12.8)

dogfooding mode 의 정의는 §12.8 의 "source repo = ToolRoot = ProjectRoot, user dev checkout" 그대로다. 본 anchor 는 그 정의의 두 detection point 를 한 자리에 anchor 한다.

- **runtime ToolRoot resolution** — `SHARED_GLOBAL_INVOCATION_CONTRACT.md` §4 D1 의 channel 4 (dogfooding marker). 즉 `Get-ToolRoot` 가 channel 1 / 2 / 3 으로 resolve 되지 않고 ProjectRoot 가 D3 multi-marker (`scripts/verify-ps1.ps1`, `templates/review-input.md`, `config/reviewer.json`) 를 모두 만족할 때 `ToolRoot = ProjectRoot`. 본 detection 은 invocation-time 의 ToolRoot 결정에 한정되며, install-pipeline action 의 dogfooding 보호와 직접 연결되지는 않는다 (install-pipeline 은 자체적으로 `Test-InstallPipelineDogfoodingSource` 로 source-side dogfooding 을 검사).
- **install-pipeline source-side dogfooding** — `Test-InstallPipelineDogfoodingSource` 의 contract: (a) `SourcePath` 와 `ProjectRoot` 가 모두 directory, (b) full-path normalized 비교에서 `SourcePath == ProjectRoot` (case-insensitive on Windows), (c) `Test-IsSourceRepoRoot(SourcePath)` true. `Test-IsSourceRepoRoot` 의 marker 는 `SHARED_GLOBAL_INVOCATION_CONTRACT.md` §4 D3 의 multi-marker 와 동일한 3 file (`scripts/verify-ps1.ps1`, `templates/review-input.md`, `config/reviewer.json`) 의 **AND** 조건이다 — 셋 모두 존재해야 source repo root 로 판정 (현행 `scripts/lib/path.ps1` 의 `Test-IsSourceRepoRoot` 함수). 위 (a) / (b) / (c) 가 모두 true 면 dogfooding source. 본 contract 는 현행 `scripts/lib/install-pipeline-core.ps1` 의 as-built 동작이며, 본 anchor 는 이를 변경하지 않는다.

위 두 detection 의 분리는 **invocation-time ToolRoot resolution** 과 **action-time source-side dogfooding** 이 별개 concept 임을 명시한다. 사용자가 channel 1 / 2 / 3 으로 ToolRoot 를 resolve 한 상태에서도 (예: 글로벌 install 의 `current/` 가 ToolRoot 인 상태) install-pipeline 에 `-SourcePath <user dev checkout>` 을 직접 넘기면 action-time dogfooding detection 이 발생한다. 두 detection 이 모두 false 일 때만 dogfooding 보호가 적용되지 않는다.

### 18.3 Tree separation invariants

dogfooding mode 의 semantic 정합을 위해 다음 5 tree 가 서로 다른 path subtree 여야 한다 — 본 anchor 가 design intent invariant 로 anchor 한다. install-pipeline 의 어느 action 도 본 invariant 를 자체적으로 위배하지 않는다 (= as-built pipeline 의 destination 은 항상 InstallArea 의 `current/` 이며 source repo working tree 가 아니다). 단, 본 invariant 의 enforcement 는 현행 skeleton 이 일부만 강제하며 (아래 InstallArea 항목 참조), full enforcement 는 §18.6 의 deferred 범위에 속한다.

- **source repo working tree** — dogfooding mode 의 `SourcePath == ProjectRoot`. **pipeline 은 어떤 action 에서도 source repo 의 git-tracked ref content 를 mutate 하지 않는다** — `git archive` 는 ref-specific snapshot 을 만들 뿐 working tree 를 건드리지 않는다. `update-source` 의 fetch/pull 만이 잠재적 mutation 경로 (remote ref / `.git/` 갱신) 이며, 이 경로가 §18.4 의 explicit-flag 보호의 대상이다.
- **global current** (`<InstallArea>/current/`) — materialization 의 destination. as-built pipeline 의 destination 은 항상 본 path 다. 본 path 가 source repo working tree subtree 안에 있게 되는 경우 (InstallArea 가 source repo subtree 에 위치한 경우) 는 본 anchor 의 semantic invariant 가 invariant 로 권고하는 분리 상태가 아니다 — 그 경우에도 destination 의 write 는 untracked path 에 일어나므로 git-tracked ref content 는 변하지 않으나, 5 tree 의 path 분리는 깨진다 (full enforcement 는 §18.6 의 deferred 범위).
- **InstallArea** — `current/` + `install.json` + `payload-manifest.json` + `payload-marker.json` + (git-url only) `source-cache/` 의 parent directory. as-built guard 는 `scripts/install-pipeline.ps1` 의 `Assert-NotForbiddenInstallArea` 함수 — 본 함수는 (a) `%USERPROFILE%\.claude` 와 (b) `%USERPROFILE%\.codex` 와 (c) global stable install scope (`<%USERPROFILE%>\.claude\ai-harness-toolset` 와 그 parent) descendant 만 reject 한다. **source repo working tree subtree 안에 InstallArea 를 두는 placement 는 본 함수가 자동 거부하지 않는다** — Pester `$TestDrive` fixture 는 `$TestDrive` 자체가 source repo 외부이므로 본 invariant 와 충돌하지 않으나, 사용자가 직접 InstallArea 를 source repo 안에 두는 경우 (예: 운영자 오류) 의 자동 거부는 별도 scoped goal (§18.6) 의 대상이다.
- **source-cache** (`<InstallArea>/source-cache/`, git-url only) — git-url mode 의 cache. local-clone mode 에서는 source-cache 가 만들어지지 않으며, 따라서 dogfooding mode 와도 무관하다. git-url mode 가 dogfooding 과 만나는 경우는 구조적으로 발생하지 않는다 (§18.1 의 strict mode confinement 와 정합).
- **ProjectRoot.log** (`<ProjectRoot>/log/`) — runtime artifact tree (BRIEF / Chatlog / Evidence / Review). source repo 의 `.gitignore` 가 `log/` 를 ignore 하므로 source-managed file 과 섞이지 않는다 (`TOOLROOT_PROJECTROOT_AUDIT.md` §5.1 와 정합). install-pipeline 의 어느 action 도 `<ProjectRoot>/log/` 에 write 하지 않는다 — pipeline 의 destination 은 InstallArea 의 `current/` 뿐이며 ProjectRoot 의 runtime artifact 와 분리된다.

### 18.4 Action × mode × dogfooding boundary

dogfooding mode 에서의 4 action 각각의 allowed / blocked / explicit-confirm-required 결정을 한 자리에 anchor 한다. 본 매트릭스는 현행 `scripts/install-pipeline.ps1` + `scripts/lib/install-pipeline-core.ps1` 의 as-built 동작이며, 본 anchor 는 그 동작을 final shape 로 고정한다.

| action | local-clone (dogfooding source) | local-clone (non-dogfooding source) | git-url | 비고 |
|---|---|---|---|---|
| **install** | **ALLOWED** — `git archive` read-only. metadata 의 `sourcePath` 가 user dev checkout 이 됨; 이후 `update-source` 가 §18.4 의 fail-fast 진입점이 됨. | ALLOWED | ALLOWED | install 은 source mutation 을 일으키지 않으며, dogfooding metadata 가 기록되는 행위 자체는 silent mutation 이 아니다. |
| **update-source** | **BLOCKED (default)** — `-AllowDogfoodSource` flag 부재 시 fail-fast STOP (§12.8 / §12.9). flag 있을 때만 진행 = **explicit-confirm-required**. | ALLOWED — fetch/pull 의 대상이 user dev checkout 이 아닌 일반 local-clone source 이므로 silent mutation 위험이 §18 의 보호 대상이 아니다. | ALLOWED — fetch 의 대상이 `<InstallArea>/source-cache/` 의 cache, user dev checkout 이 아님 (§16.3). | 본 row 가 §18 의 핵심 보호 지점. |
| **update-current** | **ALLOWED** — `git rev-parse HEAD` + `git archive` 모두 read-only. source 의 fetch/pull 을 수행하지 않으므로 dogfooding 에서도 안전. | ALLOWED | ALLOWED | §12.8 의 "`update-current` 는 source 를 건드리지 않으므로 dogfooding 에서도 그대로 허용" 와 정합. |
| **restore** | **ALLOWED (git-archive 기반 한정)** — 현행 implementation 은 `git rev-parse --verify <user-ref>^{commit}` + `git archive <ref>` 로 destination 을 ref-specific 하게 re-materialize 하며, source working tree 를 건드리지 않는다. 만약 future implementation 이 `git checkout <ref>` 같은 working-tree-mutating 경로로 변경되면, 그 변경은 본 anchor 의 final shape 를 변경하는 별도 scoped decision 의 대상이다. | ALLOWED | ALLOWED | §12.8 의 "restore 의 user-specified `--ref` 가 user dev checkout 의 working tree 를 변경할 가능성이 있으면 동일 보호 적용" 의 implementation-time 결정을 본 anchor 가 git-archive 기반으로 고정. checkout-based restore 는 본 anchor 가 자동 승인하지 않는다. |

본 매트릭스의 BLOCKED row 의 enforcement 절차 (§18.5 의 bypass mechanism 과 정합):

1. resolver 가 invocation 의 `sourceLocation` / `projectRoot` 로 dogfooding source 를 감지.
2. dispatcher 가 action 분기 안에서 dogfooding source + `-AllowDogfoodSource` 부재 + `update-source` 의 3 조건이 모두 참이면 §12.9 의 "dogfooding mutation risk" failure case 발생.
3. exit non-zero + 명시 사유 message + 다음 사용자 행동 안내 (e.g., "explicit `-AllowDogfoodSource` flag 를 명시할 때만 진행").
4. destination artifact (`current/` / `install.json` / `payload-manifest.json` / `payload-marker.json`) 의 byte-identity 보존 (§12.4 atomicity + §15.4 metadata-write-이전 hook + §16.4 fetch-이전 단계 invariant 와 정합).

### 18.5 Bypass mechanism — `-AllowDogfoodSource` final shape

본 anchor 는 §18.4 의 BLOCKED row 의 bypass 를 다음 한 mechanism 으로 고정한다.

- **mechanism**: install-pipeline CLI 의 `-AllowDogfoodSource` switch (현행 as-built; `scripts/install-pipeline.ps1` 의 parameter). 사용자가 명시적으로 본 switch 를 invocation 에 포함할 때만 BLOCKED row 의 진행을 허용한다.
- **scope**: 본 switch 는 **`update-source` action 의 dogfooding source case 에만 적용** 된다. 본 switch 가 다른 action 의 동작을 변경하지 않는다 — `install` / `update-current` / `restore` 는 본 switch 와 무관하게 동일 동작 (§18.4).
- **non-mechanism (rejected)**:
  - interactive prompt (e.g., `Read-Host`) — non-interactive operation (CI / scripted / Claude Code agent-driven) 을 깨뜨림.
  - warning-only message (mutation 이 그대로 진행되는 형태) — silent mutation 의 실질 방지가 아님.
  - environment variable bypass (e.g., `$env:AI_HARNESS_ALLOW_DOGFOOD = '1'`) — process-environment 의 잔재 effect 가 후속 invocation 에 의도치 않게 carry 됨.
  - config file bypass (e.g., `config/dogfood.json` 의 `allow=true`) — config 변경이 source repo 의 tracked state 로 commit 되어 audit / replay 의 명시성을 약화시킴.
- **future flag name / surface 변경**: 본 anchor 는 `-AllowDogfoodSource` 라는 현행 switch 이름 / surface 를 final shape 로 anchor 한다. 이름 / surface 의 후속 변경 (예: `-AllowDogfoodMutation`, `--allow-dogfood-source`, subcommand 분리 등) 은 별도 scoped decision 의 대상이다 — 본 anchor 가 자동 승인하지 않는다.

### 18.6 Deferred items (별도 explicit user-approved goal 의 대상)

본 anchor 는 다음 항목을 fix 하지 않는다. 각각은 별도 scoped goal 의 explicit user-approved decision 으로만 진행한다.

- **dirty source working tree guard** — `-AllowDogfoodSource` flag 가 있어도 source working tree 가 dirty / mid-rebase / mid-merge / detached HEAD 인 상태에서 `update-source` 를 추가 보호할지의 결정 / 형태. 본 anchor 는 reproducibility risk 의 추가 guard 도입을 자동 승인하지 않는다 (§12.9 "기타 failure case" 의 dirty / mid-rebase reproducibility risk 의 implementation-time 결정 그대로).
- **restore implementation strategy 변경 시의 dogfooding 보호 재anchor** — 만약 future implementation 이 `restore` 를 git-archive 기반에서 checkout-based / worktree-based 로 변경하면, working tree mutation 경로가 발생하므로 §18.4 의 restore row 가 BLOCKED row 가 된다. 그 시점의 anchor 는 별도 scoped decision 의 대상.
- **install 의 dogfooding source 에 대한 explicit-confirm 도입 여부** — 현행 anchor 는 `install` 을 ALLOWED 로 둔다 (read-only git-archive). 그러나 dogfooding metadata 가 자동 기록되는 행위 자체에 대해 explicit confirmation 을 요구하는 future shape 는 별도 scoped decision 의 대상.
- **source-cut path 와 dogfooding mode 의 interaction enforcement** — §17.5 의 동일 항목 그대로 deferred. 본 anchor 가 source-cut handling 의 actual implementation 을 도입하지 않으므로 두 anchor 의 interaction enforcement 도 동시에 deferred.
- **dogfooding enforcement 의 actual implementation 확장** — `Test-InstallPipelineDogfoodingSource` 의 detection 범위 확장 (예: symlink / junction / case-fold path / UNC path 등의 edge case), `Assert-NotForbiddenInstallArea` 와의 추가 cross-check, 신규 Pester test 추가는 별도 scoped goal.
- **InstallArea placement 의 source-repo subtree 거부 enforcement** — `Assert-NotForbiddenInstallArea` 가 source repo working tree subtree 안의 InstallArea placement 를 자동 reject 하도록 확장할지의 결정. 본 anchor 는 그 확장을 자동 승인하지 않는다 — 운영 규약 (사용자가 InstallArea 를 source repo 외부에 둠) 으로 §18.3 의 5 tree separation invariant 가 유지되며, 자동 enforcement 는 별도 scoped goal.
- **dogfooding enforcement bypass 의 audit log** — `-AllowDogfoodSource` 가 사용된 invocation 의 install metadata / manifest / marker 안에 기록할지의 결정. 본 anchor 는 §11.1 14-field schema 의 변경을 도입하지 않는다.
- **Claude Code agent-driven invocation 의 dogfooding boundary** — agent (Claude Code SKILL.md 기반 invocation) 가 dogfooding mode 에서 `-AllowDogfoodSource` 를 자동으로 전달하지 않도록 강제하는 SKILL.md 측 정책. 본 anchor 는 `snippets/claude-skills/...` 본문 mutation 을 도입하지 않는다 — 본 항목은 §14 의 managed-block / skill replace boundary 의 후속 항목 (§14.4) 과 함께 별도 scoped goal.

### 18.7 Forbidden in this anchor

본 anchor 는 다음을 금지한다 (§10.6 / §11.7 / §12.11 / §13.3 / §14.3 / §15.7 / §16.8 / §17.6 와 정합).

- dogfooding enforcement 의 신규 implementation. `scripts/install-pipeline.ps1`, `scripts/lib/install-pipeline-core.ps1` 에 새 dogfooding 보호 함수 / branch / parameter 추가.
- `tests/install-pipeline.Tests.ps1` 의 dogfooding handling test 신규 추가 (현행 "dogfooding `update-source` 거부 후 source repo HEAD 무변경" Pester case 그대로 유지).
- `-AllowDogfoodSource` switch 이름 / surface 변경 또는 새 bypass mechanism (env var / config / prompt / warning-only mode) 도입.
- §12.8 의 dogfooding mode boundary 정의 변경.
- §12.9 의 "dogfooding mutation risk" failure case 형태 변경.
- §11.1 의 14-field install metadata schema 변경 (dogfooding bypass audit field 도입 포함).
- §15 의 manifest / marker schema 변경, §16 의 source-cache lifecycle 변경.
- §17 의 source-cut path decision boundary 약화.
- actual `%USERPROFILE%\.claude` / `%USERPROFILE%\.codex` mutation.
- managed-block apply / Claude skill install / update / removal (§14 boundary 와 정합).
- Step 4 validation 시작.
- snapshot / payload manifest / payload marker 생성 (본 anchor 는 docs-only).
- 부모 root-level docs (`GLOBAL_INSTALL_UPDATE_MODEL.md`, `GLOBAL_ADOPTION_DECISION.md`, `GLOBAL_ADOPTION_PROCEDURE.md`, `SHARED_GLOBAL_INVOCATION_CONTRACT.md`, `TOOLROOT_PROJECTROOT_AUDIT.md`) 본문 mutation.
- `docs/backlog/operations.md` 의 기존 항목 status 변경.
- §6 canonical decomposition (9 단계 ordering / numbering) 변경.
- commit / push / publish / merge / release / adoption.

### 18.8 본 anchor 의 scope 와 non-goals

본 anchor 는 다음을 **포함한다**.

- §18.1 의 5 명제 decision (explicit-flag bypass / strict mode confinement / action 별 boundary / 5 tree separation invariant / docs-only).
- §18.2 의 dogfooding detection 의 두 detection point 재anchor (invocation-time ToolRoot resolution + action-time source-side dogfooding).
- §18.3 의 5 tree separation invariant.
- §18.4 의 action × mode × dogfooding boundary matrix.
- §18.5 의 `-AllowDogfoodSource` final shape (mechanism / scope / non-mechanism enumeration).
- §18.6 의 deferred items (별도 scoped goal 의 대상 항목 8 개).
- §18.7 의 forbidden enumeration.

본 anchor 는 다음을 **포함하지 않는다**.

- dogfooding 처리의 actual implementation / 신규 함수 / 신규 test.
- §12.8 의 dogfooding mode boundary 정의 변경.
- §11.1 의 install metadata schema 변경.
- §15 의 manifest / marker contract 변경.
- §16 의 git-url mode source-cache lifecycle 변경.
- §17 의 source-cut path decision boundary 변경.
- 부모 root-level docs 본문 mutation. 본 anchor 는 STEP3 guide subordinate scope 안에서 닫는다.
- §6 canonical decomposition 의 ordering / numbering 변경. dogfooding enforcement final shape 는 §6 의 9 단계 중 어느 단일 sub-step 의 재정의가 아니라 §12.8 의 implementation-time deferred wording 의 closeout anchor 다.
- actual global / user filesystem mutation, target adoption, commit / push / publish / merge / release / Step 4 validation.

본 anchor 는 `yes` / `no` / `yes with risk` 어느 verdict 의 자동 승인도 아니다. anchor 의 source / doc mutation 자체는 본 도구의 정상 review gate 를 거치며, review verdict 이후의 commit / push / global apply / Step 4 validation 시작 등은 사용자 명시 결정으로 처리한다 (§8 / §10.7 / §11.8 / §12.11 / §13.3 / §14.5 / §15.7 / §16.8 / §17.7 와 정합).
