# Post-MVP Plan

본 문서는 `ai-harness-toolset` 의 CLI-only MVP 종료 시점에 합의된 post-MVP 결정 사항을 추적 가능한 형태로 보존한다. **결정의 기록이며, 구현 승인이 아니다.**

post-MVP 항목 어느 것도 본 문서가 존재한다는 사실만으로 implementation, scoped work, scheduling, 또는 release 가 자동 승인되지 않는다. 각 항목은 별도 scoped 승인을 거친 뒤에만 작업이 시작된다.

> **현행 routing (docs taxonomy reset).** 본 문서의 current status / next action / completed / deferred 판단은 이제 다음 current 자리가 authoritative 다 — `docs/current/PROJECT_STATE.md` (top-level summary), `docs/current/NEXT_ACTIONS.md` (active queue), `docs/current/SOURCE_OF_TRUTH.md` (question→authority), system status (`docs/systems/install-update/STATUS.md` + `DEFERRED.md`, `docs/systems/review/STATUS.md`, `docs/systems/brief/STATUS.md` + `DEFERRED.md`), 그리고 §11 numbered order 의 1:1 routing view `docs/roadmap/CURRENT_MILESTONES.md`. 본 POST_MVP_PLAN.md 는 post-MVP **decision record (§1–§9)** 와 numbered remaining order (§11) 의 authority 로 유지된다. §10 의 상세 commit-bound completed narrative 는 `docs/archive/old-roadmaps/POST_MVP_COMPLETED_NARRATIVE.md` 로 이동(verbatim 보존)했다. current 판단에는 위 current/system 자리를 먼저 본다.

---

## 1. MVP closeout 상태

- `ai-harness-toolset` 의 CLI-only MVP 는 **closed** 상태다.
- closeout 은 다음을 의미한다.
  - source repo 의 `config/`, `scripts/`, `snippets/`, `templates/` 4 개 폴더만 copy-only / CLI-only 로 다른 프로젝트에 적용 가능하다.
  - 사용자가 `scripts/review-cycle.ps1` 한 번의 호출로 review packet 준비 → input 검증 → Codex CLI 1 회 실행 → verdict parsing → result 기록 → freshness / binding 검증을 모두 마칠 수 있다.
  - `<project-root>/log/review/<run-id>/` 아래 `meta.json`, `input.md`, `result.md`, `result.json` 4 개가 read-only record 로 보존된다.
- **Post-MVP refactor note.** 위 두 번째 / 세 번째 bullet 은 MVP closeout 시점의 historical fact 다. post-MVP 단계에서 canonical review task/pass topology 가 채택되어 현행 normal operator path 와 canonical review record 가 다음과 같이 변경되었다. (a) normal operator entrypoint 는 `scripts/review-prepare.ps1` → `scripts/review-run.ps1` 두 스텝이며 `scripts/review-verify.ps1` 가 post-hoc canonical-artifact check 로 동작한다. (b) canonical review record 는 `<ProjectRoot>/log/review/<review-task-id>/pass-NN/input.md` + `result.md` 두 파일이다. (c) `scripts/review-cycle.ps1`, `meta.json`, `result.json`, `target-files.list`, `log/review-targets/`, `log/review-requests/`, `-TargetFilesPath`, `-ReviewRequestPath` 는 normal operator path / normal contract 에서 제거되었다. 자세한 contract / implementation / global apply 진행 상황은 §2 와 §10 Completed (`a5d94a5`, `c81fe45`) 에 기록된다. 본 note 는 closeout fact 를 부정하지 않으며 historical statement 는 그대로 보존된다.
- closeout 은 다음을 의미하지 **않는다**.
  - post-MVP 항목의 implementation 승인.
  - 새 subsystem 도입 승인.
  - 기존 docs / scripts / templates 의 광범위한 재구성 승인.
  - commit / push / publish / merge / release / deployment 의 자동 승인.
- MVP scope 자체를 다시 넓히는 변경은 본 문서의 범위가 아니다. MVP 의 in-scope / out-of-scope 정의는 `docs/project/AI_HARNESS_TOOLSET_SCOPE.md` 가 source-of-truth 다.

---

## 2. Codex review system — maintenance mode

- Codex review subsystem 의 MVP-시점 operational 묶음은 (`scripts/review-cycle.ps1`, `scripts/review-prepare.ps1`, `scripts/review-run.ps1`, `scripts/review-verify.ps1`, `scripts/review-input-verify.ps1`, `templates/review-input.md`, `templates/review-meta.json`, `templates/review-result.*`, `config/reviewer.json`) 이었다 (closeout 시점 historical record). post-MVP 단계에서 canonical review task/pass topology 가 채택되어 normal operator path 와 canonical record 가 다음과 같이 갱신되었다 — 자세한 진행 기록은 §10 Completed 의 `a5d94a5` / `c81fe45` 항목을 따른다.
  - 현행 normal operator entrypoint: `scripts/review-prepare.ps1` → `scripts/review-run.ps1` 두 스텝. `scripts/review-verify.ps1` 는 post-hoc canonical-artifact check (Codex 미호출). `scripts/review-input-verify.ps1` 는 input gate 로 유지.
  - 현행 canonical review record: `<ProjectRoot>/log/review/<review-task-id>/pass-NN/input.md` + `result.md` 두 파일.
  - 현행 canonical template: `templates/review-input.md`, `templates/review-result.md`. `config/reviewer.json` 은 reviewer config 로 유지.
  - normal operator path / normal contract 에서 제거된 항목: `scripts/review-cycle.ps1`, `meta.json`, `result.json`, `target-files.list`, `log/review-targets/`, `log/review-requests/`, `-TargetFilesPath`, `-ReviewRequestPath`, `templates/review-meta.json`, `templates/review-result.json` (또는 동등 sidecar JSON).
- post-MVP 단계에서 review subsystem 은 **maintenance mode** 로 진입한다.
  - 새 feature, 새 reviewer adapter, multi-reviewer orchestration, review history DB, cross-run aggregation, automatic retention 은 별도 scoped 승인 없이 추가하지 않는다.
  - bug fix, contract clarification, 기존 행동의 정합성 보정은 maintenance scope 안에서 가능하다. 단, 새 feature 와 maintenance fix 의 경계가 모호한 변경은 별도 scoped 승인을 받는다.
  - canonical review task/pass topology 채택 (a5d94a5 contract alignment + c81fe45 implementation) 은 maintenance scope 안의 contract clarification + 그에 정합한 implementation 이며, 새 feature 의 추가가 아니다 (§10 Completed 참조).
- review verdict (`yes` / `no` / `yes with risk`) 는 commit / push / publish / merge / release / deployment 를 자동 승인하지 않는다는 contract 가 그대로 유지된다 (`docs/contracts/review/REVIEW_RESULT_CONTRACT.md` 의 non-goals).
- 사용자 운영 권고 문서로서 `docs/policies/REVIEW_EFFORT_GUIDE.md` 가 추가되어 post-MVP 단계의 review effort / cost 통제 가이드를 제공한다. 본 가이드는 review subsystem 의 contract 를 재정의하지 않으며, 어떤 자동 게이트도 도입하지 않는다.

---

## 3. Brief system — post-MVP core

> **3rd reconciliation (현행).** 본 §3 의 canonical Brief 위치 결정은 세 단계의 reconciliation 을 거쳤다.
> (1) 1차 — canonical 을 `<ProjectRoot>/log/brief/BRIEF.md` 로 두고 root `<ProjectRoot>/brief/` 를 forbidden 으로
> 표기한 framing. (2) 2차 — 그 framing 이 정정되어 target product canonical 을 `<ProjectRoot>/brief/BRIEF.md`
> 로 두고 `<ProjectRoot>/log/brief/BRIEF.md` 를 not-canonical 한 source-side primitive seed destination 으로
> 분류한 framing. **(3) 3차 (현행)** — 위 2차 framing 도 정정되었다. **canonical Brief 는 `<ProjectRoot>/log/brief/BRIEF.md`**
> 한 자리이며, project-local, operator-local, source-control-excluded runtime artifact (gitignored under `log/`)
> 다. **root `<ProjectRoot>/brief/` 는 rejected**, user-home operator-local runtime root (예:
> `%USERPROFILE%\.ai-harness\projects\<project-key>\...`) 도 rejected, target persistent footprint 는
> `<ProjectRoot>/log/` only 다. 현행 source-of-truth 는 `docs/contracts/brief/BRIEF_CONTRACT.md` 다.

- Brief system 은 post-MVP 의 core 항목이다. 단, 본 문서는 Brief system 의 implementation 시점, 우선순위, owner, deadline 을 확정하지 않는다.
- canonical Brief 위치 결정 (3차 reconciliation).
  - canonical Brief 는 `<ProjectRoot>/log/brief/BRIEF.md` — project-local, operator-local, source-control-excluded runtime artifact under `<ProjectRoot>/log/`.
  - source repo (이 toolset 의 source 트리) 에는 어떤 project 의 BRIEF artifact 도 두지 않는다 (template 자리 `templates/brief/BRIEF.md` 는 별개).
  - root `<ProjectRoot>/brief/` 는 rejected. user-home operator-local runtime root 도 rejected.
- source-side primitive 와 canonical 의 관계.
  - `scripts/brief-init.ps1` 의 writer destination 과 `scripts/brief-check.ps1` 의 default check path 는 canonical Brief 자리 (`<ProjectRoot>/log/brief/BRIEF.md`) 와 일치한다. canonical 과 destination 의 routing 정합화는 더 이상 future scoped work 가 아니다 (2차 reconciliation 의 잔재였으며 3차 reconciliation 으로 자연 해소되었다).
  - primitive 의 narrow 성격은 destination 의 문제가 아니라 capability 의 문제다 (deterministic writer / restore-offer / stale warning / session-start guidance 의 미구현 — §5 참조).
  - 기존 `log/chatlog/current/resume.md` / `log/chatlog/current/summary.md` 를 canonical 의 자리로 reorganize 하는 시도는 본 결정 범위 밖이다 — 두 파일은 `docs/contracts/chatlog/CHATLOG_CONTRACT.md` 의 failed intermediate / legacy migration source / deprecation candidate 분류를 따른다.
- 현재 상태 (source repo).
  - source-side primitive (`scripts/brief-init.ps1`, `scripts/brief-check.ps1`, `templates/brief/BRIEF.md`) implementation 완료. 단, 이는 BF Level 3 capability 의 full implementation 이 아니라 narrow primitive 수준이다 (`docs/contracts/brief/BRIEF_CONTRACT.md` §"BF Level — save/restore capability maturity").
  - `snippets/CLAUDE_SNIPPET.md` / `snippets/AGENTS_SNIPPET.md` 본문은 현행 (3차 reconciliation) framing 으로 정합화되어 있다 — canonical Brief = `<ProjectRoot>/log/brief/BRIEF.md`, root `<ProjectRoot>/brief/` rejected, `log/chatlog/current/resume.md` / `summary.md` 가 failed intermediate / legacy migration source / deprecation candidate 임을 명시. 운영자가 이전 라운드에 destination `CLAUDE.md` / `AGENTS.md` 의 managed block 에 적용한 본문은 그 시점의 snippet 을 그대로 가지고 있으며 source snippet 갱신 이후에도 자동으로 refresh 되지 않는다 — destination managed-block refresh 는 사용자 명시 승인이 필요한 별도 managed-block replacement step (`docs/decisions/GLOBAL_ADOPTION_DECISION.md` §6) 이다. source snippet / managed block / docs contract 의 framing 이 충돌하면 docs contract (`docs/contracts/brief/BRIEF_CONTRACT.md`, `docs/contracts/chatlog/CHATLOG_CONTRACT.md`) 가 우선이다. snippet 본문의 BF Level 3 deterministic 자동화 (validation / stale warning / restore-offer) 자체는 여전히 미구현 future scoped work 다.
  - target payload 측 source-side primitive smoke test 완료.
  - 위 항목들은 narrow source-side primitive 가 동작 가능 상태라는 의미다. Brief system 전체 (BF Level 3 deterministic capability 등) 의 완료를 의미하지 않으며, 본 절 첫 줄의 implementation 시점 / 우선순위 / owner / deadline 미확정 진술은 그 broader scope 에 대해 그대로 유효하다. (이전 라운드의 "target-canonical routing" 항목은 §3 의 3차 reconciliation 으로 자연 해소되었다.)

---

## 4. Chatlog system — intended subsystem, not implemented

- Chatlog system 은 ai-harness-toolset 이 향후 다루기로 의도한 subsystem 이다.
- 현재 시점의 사실 인식.
  - Chatlog system 자체의 practical implementation 과 testing 은 **거의 없는 상태** 다.
  - `docs/contracts/chatlog/CHATLOG_CONTRACT.md` 가 Brief 와 Chatlog 의 책임 분리, Chatlog 의 history / decision rationale / Brief reconstruction evidence 책임을 정의하지만, 이는 manual convention 이다.
  - `log/chatlog/current/resume.md`, `log/chatlog/current/summary.md` 는 **canonical 자리가 아니다.** failed intermediate / legacy migration source / deprecation candidate 분류이며, current restore source 가 아니다 (`docs/contracts/chatlog/CHATLOG_CONTRACT.md`). 이는 Chatlog system 의 fuller implementation 도 아니다.
- 따라서 다음 두 개의 명제가 동시에 성립한다.
  - "log/chatlog/current/ 가 갱신되고 있다" 는 사실은 Chatlog system 이 implementation 되었다는 의미가 아니다.
  - "Chatlog system 이 아직 implementation 되지 않았다" 는 사실은 BF Level 1/2 manual discipline 의 운용을 막지 않는다 — 그 discipline 의 target 자리는 Chatlog 가 아니라 Brief (`<ProjectRoot>/log/brief/BRIEF.md`, canonical) 이며, primitive 의 writer destination 도 이 자리와 일치한다 (§3 의 3차 reconciliation 참조).
- Chatlog fuller implementation (누적 work history, 자체 schema, retention, browse UI, RND-style heavy workflow) 는 본 결정 범위 밖이며 later track 이다 (`docs/contracts/chatlog/CHATLOG_CONTRACT.md`).

---

## 5. BF Level 3 — allowed scope

- BF Level 은 path 가 아니라 **save / restore capability maturity** 다 (`docs/contracts/brief/BRIEF_CONTRACT.md`). BF Level 1/2 는 manual save / restore discipline 이고, BF Level 3 는 deterministic Brief maintenance / validation / stale warning / session-start guidance / restore-offer 의 자동화다.
- BF Level 3 는 post-MVP 단계에서 **허용 범위 안** 이다. 단, 사람이 BRIEF 본문을 직접 손편집하는 모델을 BF Level 3 의 목표로 두지 않는다. 반대로 BF Level 3 는 그 손편집 의존을 줄이는 방향이다.
- 다음 항목은 BF Level 3 의 이름으로도 본 결정 범위에서 명시적으로 **금지** 한다.
  - daemon
  - watcher
  - scheduler
  - `BF_STATE.json` 같은 별도 state machine 파일
  - automatic decision-maker (사용자 동의 없이 다음 action 을 결정하고 실행하는 components)
- BF Level 3 implementation 자체도 본 문서가 자동 승인하지 않는다. design / scoped 승인 / scoped implementation 이 별도로 필요하다.
- 본 절은 BF Level 3 이 후속 작업의 scope 안에 있을 수 있다는 사실만 기록한다.
- 현재 상태 (source repo).
  - `scripts/brief-init.ps1` / `scripts/brief-check.ps1` 라는 **narrow source-side primitive** 가 갖춰져 있다 (§3 참조). 이는 BF Level 3 capability 의 full implementation 이 아니다.
  - BF Level 3 의 미구현 future scoped work 에는 다음이 포함된다 — deterministic save / update writer, restore-offer behavior 의 source-side automation, stale warning, session-start guidance. (이전 라운드의 "writer destination 을 target canonical (`brief/BRIEF.md`) 로 routing 정합화" 항목은 §3 의 3차 reconciliation 으로 더 이상 항목이 아니다 — destination 자체가 canonical 이다.)
  - 본 §5 의 forbidden 항목 (daemon / watcher / scheduler / `BF_STATE.json` / automatic decision-maker) 은 그대로 유지된다.
  - 그 다음 BF Level 3 단계는 본 §5 가 자동 승인하지 않는다. design / scoped 승인을 별도로 거친다.

---

## 6. Packaging — `package-toolset.ps1`

- `package-toolset.ps1` 은 post-MVP 단계에서 필요해질 수 있는 도구다. 책임은 다음으로 한정한다.
  - source repo 의 `config/`, `scripts/`, `snippets/`, `templates/` 4 개 폴더를 **copy-bundle** 형태로 묶는 packaging 스크립트.
  - 현재 README 가 명시한 4 개 폴더 적용 규칙과 동일한 boundary 를 유지한다.
- 명시적으로 책임이 **아닌** 항목.
  - installer behavior (target project 의 글로벌 파일 변경, ~/.claude/ 변경, 시스템 PATH 변경, hook 설치, daemon 등록).
  - target project 의 `.gitignore`, `CLAUDE.md`, `AGENTS.md` 의 자동 변경.
  - copy-bundle 외의 distribution 채널 (public release packaging, registry publish 등).
- `package-toolset.ps1` 이 source repo 에 추가되어야 한다고 본 결정이 명령하지 않는다. 필요 시 별도 scoped 승인을 받은 뒤 design / implementation 한다.
- adoption mode (copy / link / pinned-link) 결정.
  - MVP 시점의 active default 는 README 가 명시한 copy-only adoption 이었다 (`docs/project/AI_HARNESS_TOOLSET_SCOPE.md` 의 legacy project-local copy payload 절). 이 enumeration 은 historical record 이며, 현행 adoption / default 는 shared / global stable runtime ToolRoot (channel 3) 다 — 아래 reframe 항목, §10 / §11, 그리고 `docs/contracts/global-invocation/SHARED_GLOBAL_INVOCATION_CONTRACT.md` 를 따른다.
  - link / pinned-link adoption mode 의 도입 여부와 책임 경계는 별도 scoped 승인이 필요한 deferred decision 이다.
  - 본 결정은 packaging (`package-toolset.ps1`) 결정과 sibling 관계이며, 두 결정의 boundary 가 일관성 있게 정해진 뒤에야 implementation 단계로 넘어간다.
  - 본 항목의 framing 은 `docs/decisions/GLOBAL_ADOPTION_DECISION.md` §1, §4 의 결정에 의해 reframed 되었다. 위 historical enumeration (copy / link / pinned-link) 은 historical record 로 그대로 보존하되, 현 시점의 preferred direction 은 다음과 같이 갱신되었다.
    - global / common AI development operating layer 가 preferred direction 이다.
    - target 안의 `.ai-harness/` copied tool folder 는 default preferred shape 이 아니다.
    - symlink / junction / link 는 direct shared/global invocation 의 변경 폭이 너무 클 때만 검토되는 fallback candidate 다.
    - installer-first productization 은 본 단계에서 out of scope 다.
  - 따라서 본 §6 의 `copy / link / pinned-link` enumeration 이 여전히 primary direction decision 이라고 해석하지 않는다. primary direction 의 source-of-truth 는 `docs/decisions/GLOBAL_ADOPTION_DECISION.md` 다.

---

## 7. GJMNet adoption — deferred

- 별도 프로젝트인 GJMNet 으로의 ai-harness-toolset 적용은 **defer** 한다.
- defer 의 조건은 다음 세 항목 모두가 ready 상태에 도달할 때까지다.
  - Brief system (canonical 위치, restore-offer behavior, BF Level 3 boundary 포함) 의 방향이 정해진 시점.
  - BF Level 3 의 design boundary 가 정해진 시점.
  - packaging (`package-toolset.ps1` 의 책임 / shape) 방향이 정해진 시점.
- 위 세 항목 중 하나라도 미정인 동안에는 GJMNet 적용은 시작하지 않는다.
- legacy ai-harness 의 GJMNet 적용 흐름과 별도로, 본 결정은 **새 ai-harness-toolset** 의 GJMNet 적용을 defer 한다는 의미다.
- 기존 GJMNet 안의 ai-harness-toolset application state 처리 방침.
  - 기존 GJMNet 안에 남아 있는 ai-harness-toolset 적용 잔여물 (legacy application state) 은 **disposable** 로 간주한다.
  - 그 잔여물에 대한 migration / cleanup 작업은 **post-MVP 항목이 아니다.** 본 toolset 측에서 해당 작업을 수행하지 않는다.
  - GJMNet 자체는 위 세 ready 조건 (Brief system / BF Level 3 / packaging) 이 충족된 뒤 **clean git repo 로 재생성** 한다. 재생성 이후의 GJMNet 운용은 본 toolset 의 CLI-only 운용 규칙을 그대로 따른다.
  - clean GJMNet repo 재생성 자체도 본 문서의 존재로 자동 승인되지 않는다. 별도 scoped 승인을 거친다.

---

## 8. Hard guardrails

본 문서는 post-MVP 결정을 기록하지만, 동시에 다음 guardrail 을 유지한다. 아래 항목은 본 문서가 존재한다는 사실로 절대 자동 승인되지 않는다.

- full docs taxonomy restructuring.
- 기존 docs 파일의 이동 또는 rename.
- Brief system 의 implementation start.
- BF Level 3 의 implementation start.
- `package-toolset.ps1` 의 implementation start.
- legacy ai-harness 의 새로운 migration 시도.
- handoff tooling, review history DB, evidence automation 의 새 implementation.
- daemon, watcher, scheduler, automatic decision-maker 의 도입.
- global install, 글로벌 `CLAUDE.md` / `AGENTS.md` mutation, `~/.claude/` 변경.
- auto-fix loop, auto commit, auto push, auto publish, auto merge, auto release, auto deployment.
- review verdict (`yes` / `yes with risk`) 만으로 commit / push / release 를 진행하는 것.

위 항목 중 어느 것이라도 진행하려면, 별도 scoped 승인 (설계 → 승인 → scoped execute) 절차를 거친다. 본 문서는 그 승인 절차의 input 자료일 뿐이다.

---

## 9. Source-of-truth 관계

- 본 문서는 post-MVP 결정의 ai-harness-toolset 내부 record 다.
- 같은 결정을 외부 web handoff 자료가 함께 다루는 경우, 충돌이 발생하면 **본 문서의 보수적 해석** (= MVP 종료 / 구현 미승인 / guardrail 유지) 을 우선한다.
- MVP scope 자체의 정의는 `docs/project/AI_HARNESS_TOOLSET_SCOPE.md`, review subsystem 의 contract 는 `docs/contracts/review/REVIEW_RESULT_CONTRACT.md`, chatlog / BF / CL 책임 분리는 `docs/contracts/chatlog/CHATLOG_CONTRACT.md` 가 source-of-truth 다. 본 문서는 이 contract 들과 상충하는 결정을 내리지 않는다.
- MVP closeout 의 가벼운 기록은 `docs/decisions/DECISIONS.md` 에 한 줄로 두고, 자세한 내역은 본 문서를 가리킨다.

---

## 10. Post-MVP status summary

본 절은 post-MVP 잔여 항목의 현재 분류를 한 자리에 모은 요약이다. 다른 절보다 자세하지 않으며, §1–§9 본문과 충돌하면 본문이 우선한다.

### Completed (source repo side)

본 §10 Completed 의 상세 commit-bound narrative 는 `docs/archive/old-roadmaps/POST_MVP_COMPLETED_NARRATIVE.md` 로 이동했다(verbatim 보존). 현행 compact completed-ledger 는 system status 가 authoritative 다 — install/update: `docs/systems/install-update/STATUS.md` (IU-01..IU-12), review: `docs/systems/review/STATUS.md` (RV-01..RV-04), brief: `docs/systems/brief/STATUS.md` (BR-01..BR-03). deferred(reopen condition 포함)는 `docs/systems/install-update/DEFERRED.md` / `docs/systems/brief/DEFERRED.md`. 아래 §10 Deferred / Operations backlog track / Decisions reaffirmed 절은 그대로 유지된다.

### Deferred (separate scoped approval required)

본 항목들의 권장 처리 순서는 §11 에 있다. manual global activation 을 포함한 **모든 실제 global mutation 은 별도 scoped 승인이 필요하다.** 본 절은 어떤 global mutation 도 자동 승인하지 않는다.

- ~~global behavior validation — manual global activation / controlled global materialization 으로 global entrypoint / ToolRoot·ProjectRoot 분리 / target footprint / runtime artifact 위치가 실제로 성립하는지 검증 (`docs/systems/install-update/GLOBAL_INSTALL_UPDATE_MODEL.md` §7, §11 step 2).~~ — **Resolved** as the §10 Completed "POST_MVP_PLAN §11 step 2 closeout" entry above. d557580 baseline 기준 evidence 로 §7.2 four-axis 가 충족되었음을 기록한다. 새 validation 실행 / 새 evidence 체계 / convention 도입이 아니다.
- install / update automation implementation 의 deferred 잔여 (`docs/systems/install-update/GLOBAL_INSTALL_UPDATE_MODEL.md` §3–§5, §11 step 3; STEP3 guide §13.2 의 git-url actual network fetch / source-cut actual handling / actual global·user filesystem apply 등). **step 4 install / update validation 은 더 이상 deferred 가 아니다 — §10 Completed 의 "POST_MVP_PLAN §11 step 4 install / update validation closeout" (Tier A 100/100 PASS + Tier B mainpc / vanilla pc PASS) 로 닫혔다.** step 3 의 anchored decisions / temp-only skeleton / dry-run / manifest+marker / git-url / source-cut / dogfooding / D-atomicity 진행은 §10 Completed 에 partial-progress closeout 으로 기록되어 있다.
- ~~`ai-harness-toolset` self-adoption (`docs/systems/install-update/GLOBAL_INSTALL_UPDATE_MODEL.md` §9, §11 step 5).~~ — **Resolved** at resolved HEAD `8293878d` (apply 2026-05-25). Closeout ledger: `docs/systems/install-update/STATUS.md` IU-13 / "Self-adoption (Step 5) — performed". Performed via `INSTALL.md` §2A AI-guided operational install; no productized installer / wrapper was adopted. activation surfaces (Claude / Codex managed blocks + Claude `ai-harness-review` skill) recorded as no-op (steady-state at apply time).
- post-MVP closeout 결정 (§11 step 6).
- GJMNet clean adoption (§7, §11 step 7).
- `package-toolset.ps1` implementation (§6).
- Chatlog system 의 CL 영역 fuller implementation (§4).
- ~~docs taxonomy 의 실제 path migration~~ — **Resolved** (access-pattern restructure, 2026-05-23). `docs/` 가 access-pattern scope folders (`contracts/` `policies/` `project/` `decisions/` `user_guide/` 등) 로 재배치되고 `docs/` root 는 `README.md` 만 남았으며, placement authority 는 `docs/README.md` 다. path-reference scan + per-batch Codex review 를 거쳤다. risk-resolution pass(2026-05-23)에서 마지막 roadmap 잔류 문서도 이동했다 — `GLOBAL_ADOPTION_DECISION.md` → `docs/decisions/GLOBAL_ADOPTION_DECISION.md`, `STEP3_INSTALL_UPDATE_DECISION_GUIDE.md` → `docs/systems/install-update/STEP3_INSTALL_UPDATE_DECISION_GUIDE.md`. `docs/roadmap/` 는 이제 milestone routing only (`INDEX.md`, `CURRENT_MILESTONES.md`) 다.
- ~~기존 guide / contract / audit 문서 안의 legacy review-cycle path 참조 정합화~~ — **Resolved** in the follow-up Brief/Chatlog/BF drift cleanup round (continuation). canonical task/pass topology 와 무관한 normal/operator/contract wording (`docs/policies/REVIEW_EFFORT_GUIDE.md`, `docs/policies/REVIEWER_CONFIG_POLICY.md`, `docs/policies/CLI_ENVIRONMENT_ASSUMPTIONS.md`, `docs/project/TOOLING_POSITION.md`, `docs/decisions/DECISIONS.md`, `tests/README.md`, `docs/contracts/evidence/EVIDENCE_CONTRACT.md` 등) 의 legacy review-cycle / `meta.json` / `result.json` / `target-files.list` / `<run-id>` flat layout / `-TargetFiles` / `-TargetFilesPath` / `-ReviewRequestPath` / `templates/review-meta.json` 참조가 현행 canonical task/pass topology 기준으로 정합화되었고, obsolete `tests/review-hardening-manual.md` legacy AC 가 drop 되었다. audit / design / smoke criteria 류 문서 (`docs/archive/audits/TOOLROOT_PROJECTROOT_AUDIT.md`, `docs/contracts/global-invocation/SHARED_GLOBAL_INVOCATION_CONTRACT.md`, `docs/archive/audits/CLEAN_TARGET_SMOKE_CRITERIA.md`, `docs/decisions/GLOBAL_ADOPTION_DECISION.md`) 의 body 안 review-cycle 언급은 각 문서 작성 시점의 historical record 로 그대로 보존되며, 본 라운드에서 각 문서 상단의 supersede note 가 review-cycle 식별자 / sidecar artifact 참조를 현행 contract 기준으로 격리하는 framing 으로 확장되었다. `docs/archive/backlog/review.md` 와 `docs/archive/backlog/operations.md` 의 backlog entries 는 backlog 분류 (historical reason 또는 scope-defined backlog) 이므로 정합화 대상이 아니다 — 그 안의 legacy 식별자는 historical reason 으로 그대로 보존된다.

### Operations backlog track (parallel)

아래 3 항목은 §11 numbered order 와 별개의 **parallel / supporting operational track** 이다. smoke 실행 과정에서 도출된 운영 품질 항목이며, 그 중 Smoke evidence preservation 은 §11 의 global behavior validation (step 2) / self-adoption validation (step 5) 을 지원하는 prerequisite 다. PowerShell smoke invocation quoting hardening 은 (W) wrapper 로 closed 되었다. clean target smoke execution 자체는 §10 Completed 로 이동했고, 그 과정에서 도출된 evidence preservation convention 은 여전히 open scope-defined backlog 항목으로 남는다. 각 open 항목의 implementation 은 별도 scoped 승인을 거친다. (현행 open backlog 진입점: `docs/systems/install-update/BACKLOG.md`; 분류: `docs/backlog/INDEX.md`.)

- **Long-lived docs commit hash hygiene** (candidate) — long-lived doc 의 literal commit hash hygiene. §11 numbered order 와 독립적인 저우선 doc hygiene 항목.
- **PowerShell smoke invocation quoting hardening** — **closed.** (W) wrapper-script 채택 / 구현 완료 (`scripts/smoke/invoke-review-cycle.ps1` thin wrapper + Pester test, commit `c183c6b`); (R) runbook-only / (S) helper-snippet 은 채택하지 않았다. status 는 `docs/archive/backlog/operations.md` 동명 항목 + `docs/systems/install-update/STATUS.md` Operational closeout ledger 가 authoritative 다.
- **Smoke evidence preservation** (scope-defined) — `%TEMP%` evidence loss risk. 미정리 시 §11 의 validation / smoke evidence 가 repo-auditable 형태로 보존되지 않는다. 다음 implementation goal 은 (A) runbook-only / (B) helper-script / (C) archive manifest 중 1 개 채택.

### Decisions reaffirmed

- 기존 GJMNet 안의 ai-harness-toolset application state 는 disposable. migration / cleanup 작업은 post-MVP 항목이 아니다 (§7).
- GJMNet 은 post-MVP foundation 항목 (Brief system / BF Level 3 / packaging) 이 ready 된 뒤 clean git repo 로 재생성한다. 그 이후의 운용은 CLI-only (§7).
- 설치 / adoption mode 의 방향 결정은 `docs/decisions/GLOBAL_ADOPTION_DECISION.md` §1, §4 에 기록되었고, 그 구체적 layer / path / flow / metadata 모델은 `docs/systems/install-update/GLOBAL_INSTALL_UPDATE_MODEL.md` 가 current source-of-truth 다. `copy / link / pinned-link` framing 은 §6 안 historical record 로 보존되며, implementation 세부 중 managed block marker 적용, Claude skill global / update / removal 절차 문서화, ToolRoot / ProjectRoot path handling audit 문서화, shared / global mode invocation contract design 문서화, shared / global mode implementation (§6 의 8 개 split unit 전부), clean target smoke test criteria 정의, global install/update/self-adoption operating model 문서화는 모두 완료되었다 (§10 Completed). 잔여 항목은 install / update implementation 의 deferred 잔여 (step 3; STEP3 guide §13.2) 이며 (§10 Deferred, §11 의 numbered order; global behavior validation 은 §10 Completed 의 step 2 closeout 항목, install / update validation 은 §10 Completed 의 step 4 closeout 항목, self-adoption 은 §10 Deferred 의 Resolved 표기 + §11 step 5 의 in-place annotation 및 `docs/systems/install-update/STATUS.md` IU-13 참조), 모두 별도 scoped 승인이 필요하다 (§6, `docs/decisions/GLOBAL_ADOPTION_DECISION.md` §6, §8, §9, `docs/systems/install-update/GLOBAL_INSTALL_UPDATE_MODEL.md`, `docs/archive/audits/TOOLROOT_PROJECTROOT_AUDIT.md` §6–§8, `docs/contracts/global-invocation/SHARED_GLOBAL_INVOCATION_CONTRACT.md` §4, §6).
- shared / global mode implementation 완료와 actual install / update / self-adoption 은 구분된다. 전자는 §10 Completed 이고, 후자의 잔여는 §11 의 remaining order step 3 (install / update implementation 의 deferred 잔여) 로서 별도 scoped 승인이 필요하다 (step 2 manual global activation 검증, step 4 install / update validation, step 5 self-adoption 은 §10 Completed / Resolved 의 각 closeout 항목 — step 5 는 resolved HEAD `8293878d` (apply 2026-05-25; STATUS IU-13) 로 닫혔다 — 참조). POST_MVP_PLAN.md 의 어떤 진술도 실제 global install / global mutation 을 자동 승인하지 않는다 — Step 5 closeout 자체도 그 이후의 임의 mutation 을 자동 승인하지 않는다.
- docs taxonomy 의 access-pattern path migration 은 **적용되었다** (2026-05-23; placement authority `docs/README.md`; §10 deferred 표의 해당 항목은 Resolved 로 표기됨). risk-resolution pass 에서 roadmap 잔류 문서까지 모두 access-pattern 자리로 이동 완료되어 `docs/roadmap/` 는 milestone routing only 다.
- review verdict (`yes` / `no` / `yes with risk`) 는 commit / push / release 의 자동 승인이 아니다 (§2, §8, `docs/contracts/review/REVIEW_RESULT_CONTRACT.md`).

---

## 11. Recommended remaining order

> 본 §11 numbered order (1–7) 는 `docs/roadmap/CURRENT_MILESTONES.md` 에 status annotation 과 함께 1:1 로 mirror 되어 있다(routing view). 본 §11 이 numbered order 와 "순서 변경/추가/삭제는 별도 scoped 승인" 규칙의 authority 다 — CURRENT_MILESTONES 는 그 order 를 재정의하지 않고 현행 status 로 라우팅만 한다.

본 절은 post-MVP **잔여 항목** 의 권장 처리 순서다. completed step 들은 §10 Completed (source repo side) 에 기록되어 있고, 본 §11 은 그 이후의 remaining work 만 다룬다. **순서 자체는 자동 승인이 아니다.** 각 단계는 §8 guardrail 을 깨지 않는 범위 안에서 별도 scoped 승인을 거친다. 특히 manual global activation 을 포함한 **모든 실제 global mutation 은 separate scoped approval 이 필요하다** — 본 절은 어떤 global mutation, snippets / scripts / config / templates 변경, global `CLAUDE.md` / `AGENTS.md` mutation, commit, push 도 자동 승인하지 않는다.

본 순서는 `docs/systems/install-update/GLOBAL_INSTALL_UPDATE_MODEL.md` 를 current global install / update / self-adoption 판단 기준으로 참조한다. `docs/decisions/GLOBAL_ADOPTION_DECISION.md` §9 의 step 1–5, shared / global mode invocation contract design, **shared / global mode implementation (§6 의 8 개 split unit 전부)**, **clean target smoke test criteria 정의 및 full SC1–SC7 실행**, 그리고 **global install / update / self-adoption operating model 문서화** 는 모두 §10 Completed 에 기록되어 본 §11 에서는 제외한다. shared / global mode implementation 완료는 source-side path / invocation 동작이 갖춰졌다는 의미이며, 아래 step 들 (actual global activation / install / update / self-adoption) 의 수행과는 구분된다. 또한 본 순서는 내부 roadmap closeout 판단을 보존하기 위해 GJMNet clean adoption 직전에 post-MVP closeout 결정을 별도 step 으로 유지한다.

본 §11 기준 step 1 (`docs/systems/install-update/GLOBAL_INSTALL_UPDATE_MODEL.md` 확정) 과 step 2 (manual global activation / controlled global materialization 을 통한 global behavior validation) 는 §10 Completed 에 기록된 대로 모두 이미 충족되어 있다. step 2 closeout 의 evidence binding 은 §10 Completed 의 step 2 closeout 항목에 정리되어 있으며 새 validation 실행 / 새 evidence 체계 / convention 도입이 아니다. 따라서 **다음 실제 milestone 은 step 3 — validation result 를 기준으로 한 install / update implementation** (`GLOBAL_INSTALL_UPDATE_MODEL.md` §3–§5) 이며, 이는 실제 global mutation 이므로 별도 scoped 승인이 필요하다.

canonical review task/pass topology refactor (a5d94a5 contract alignment + c81fe45 implementation + 그에 정합한 global payload / managed-block / Claude skill refresh) 는 §10 Completed 에 추가된 source-side milestone 이며, 본 §11 의 numbered order 자체를 변경하지 않는다. step 2 (manual global activation 검증) 의 충족이나, step 3–4 (install / update automation implementation 및 validation) 의 implementation, step 5 (self-adoption) 의 수행, step 6 (post-MVP closeout 결정), step 7 (new GJMNet clean adoption) 의 시작 어느 것도 본 refactor 만으로 자동 충족되지 않는다.

1. `docs/systems/install-update/GLOBAL_INSTALL_UPDATE_MODEL.md` 확정 — **§10 Completed 에 기록된 대로 이미 충족됨.** global install / update / validation / self-adoption operating model 이 current source-of-truth 로 확정되어 있다. 본 step 은 이후 단계의 baseline checkpoint 로 남기며, remaining work 는 step 3 부터다 (step 2 는 아래 항목 참조).
2. manual global activation / controlled global materialization 으로 global behavior validation (`GLOBAL_INSTALL_UPDATE_MODEL.md` §7.2 의 four-axis: global entrypoint / ToolRoot·ProjectRoot 분리 / target footprint / runtime artifact 위치) — **§10 Completed 에 기록된 대로 d557580 baseline 시점의 기존 evidence 로 이미 충족됨.** 본 closeout 은 step 3–7 어느 것도 자동 승인하지 않으며, `docs/archive/backlog/operations.md` 항목의 status 도 변경하지 않는다.
3. validation result 를 기준으로 install / update implementation (`GLOBAL_INSTALL_UPDATE_MODEL.md` §3–§5). 본 step 의 작업은 `GLOBAL_INSTALL_UPDATE_MODEL.md` 의 subordinate 인 `docs/systems/install-update/STEP3_INSTALL_UPDATE_DECISION_GUIDE.md` 를 따른다.
4. install / update validation. 본 step 의 최소 scope (Tier A fixture-local determinism / Tier B real installed-state validation) 와 deferred / 승인 boundary 는 아래 §11.1 에 anchor 한다. — **§10 Completed 의 "POST_MVP_PLAN §11 step 4 install / update validation closeout" 항목에 기록된 대로 Tier A (100/100 PASS) + Tier B (mainpc / vanilla pc pure-UX git-url update + verification PASS, 두 host 모두 resolved HEAD `0a07d90`) 로 닫혔다.** 본 closeout 은 step 5–7 어느 것도 자동 승인하지 않으며, §11.1.3 의 deferred 항목 status 도 변경하지 않는다.
5. `ai-harness-toolset` self-adoption (`GLOBAL_INSTALL_UPDATE_MODEL.md` §9) — **§10 Deferred 표의 self-adoption 항목이 Resolved 로 표기된 대로 resolved HEAD `8293878d` (apply 2026-05-25) 로 닫혔다. Closeout ledger: `docs/systems/install-update/STATUS.md` IU-13 / "Self-adoption (Step 5) — performed".** 본 closeout 은 step 6–7 어느 것도 자동 승인하지 않는다.
6. post-MVP closeout 결정.
7. new GJMNet repo 의 clean adoption. self-adoption (step 5) 과 global behavior validation (step 2) 이후로 유지한다 (§7).

순서 변경, 항목 추가, 또는 항목 삭제는 별도 scoped 승인이 필요하다. operations backlog track (§10) 의 항목은 본 numbered order 와 병렬이다. 그 중 PowerShell smoke invocation quoting hardening 은 closed ((W) wrapper, `c183c6b`) 이고, 남은 open 항목 중 Smoke evidence preservation 이 step 2 / step 5 를 지원하는 prerequisite 다.

### 11.1 Step 4 install / update validation — 최소 scope anchor

본 절은 §11 numbered order 의 step 4 (`install / update validation`) 의 최소 scope 를 anchor 한다. 본 절은 step 4 의 placeholder 를 scope 정의로 구체화하는 docs-only anchor 이며, **step 4 validation 의 실제 실행, 어떤 global / user filesystem mutation, target adoption, commit / push / publish / merge / release 어느 것도 자동 승인하지 않는다.** §11 의 numbered order (1–7) 의 ordering / numbering 도 변경하지 않는다 — 본 절은 step 4 항목의 in-place 구체화다.

본 절이 검증 대상으로 삼는 install / update automation 의 contract surface 는 `docs/systems/install-update/GLOBAL_INSTALL_UPDATE_MODEL.md` §3–§5, §7 과 그 subordinate `docs/systems/install-update/STEP3_INSTALL_UPDATE_DECISION_GUIDE.md` (특히 §10–§19) 다. clean-target fixture 검증 형식 (Pre / Action / Pass / Fail / Evidence) 은 `docs/archive/audits/CLEAN_TARGET_SMOKE_CRITERIA.md` 를 baseline 으로 한다.

#### 11.1.0 Source-of-truth 원칙 (Tier A / Tier B 공통 전제)

step 4 의 모든 tier 는 다음 원칙 위에서 동작한다.

- **trusted source = repo HEAD.** install / update / reinstall / recover 의 회복 source-of-truth 는 trusted repo source identity (resolved commit SHA) 이며, 이미 installed 된 payload 가 아니다 (STEP3 guide §19.2 / §19.5 의 reinstall-first 와 정합).
- **installed state ≠ source-of-truth.** 어떤 installed state — `%USERPROFILE%\.claude\ai-harness-toolset\current\`, managed-block destination, Claude skill destination — 도 step 4 에서 source-of-truth 로 취급하지 않는다. installed state 는 **검증 대상 (validation target)** 이며, legacy / stale / minor-drift / corrupted 일 수 있다고 가정한다.
- **현행 installed state 가정.** 본 anchor 작성 시점의 실제 host 들은 최신 Step 3 / Step 4 구현이 배포된 상태가 아니라고 가정한다. 한 host 는 hot copy 수준의 stale / minor state 이고, 다른 host 는 첫 install 이후 update 검증 중 발견된 이슈를 계기로 repo 측이 수정된 상태라 최신 install / update scripts 가 배포되어 있다고 가정하지 않는다. 따라서 step 4 는 "installed payload 가 곧 최신" 이라는 가정에서 출발하지 않으며, 항상 trusted repo source 기준 deterministic overwrite 로 정합화한다.

#### 11.1.1 Tier A — fixture-local / project-local validation (기본 scope)

repo HEAD 기준 install / update automation 의 **결정성** 을 fixture / temp area 에서 검증하는 범위다. 실제 global / user filesystem 을 건드리지 않는다.

- **대상 automation.** `tests/support/install-pipeline-fixture.ps1` (구 `scripts/install-pipeline.ps1` — fixture entry로 이동) + `scripts/lib/install-pipeline-core.ps1` 의 4 action (`install` / `update-source` / `update-current` / `restore`), `Invoke-InstallPipelineVerify` (payload-manifest per-file size + SHA-256 / payload-marker presence / install metadata cross-binding); `scripts/apply-managed-block.ps1` + `scripts/lib/managed-block.ps1` (dry-run no-write/no-backup → marker-bounded 1:1 치환 → 실패 rollback → 성공 cleanup, BOM / U+FFFD / malformed-marker fail-fast); `scripts/activate-global.ps1` (`-Apply` 미지정 시 default-safe dry-run, snippet→destination 매핑, forbidden-path guard).
- **검증 area.** install-pipeline 의 `Assert-NotForbiddenInstallArea` 가 global / user scope InstallArea 를 거부하므로 temp InstallArea 만 사용한다. activate-global / apply-managed-block 은 overridable `-ClaudeHome` / `-CodexHome` / `-TargetPath` 로 temp / `TestDrive` destination 만 사용한다 — 실제 `%USERPROFILE%` 를 건드리지 않는다.
- **수행 형태.** 본 tier 는 repo 의 기존 Pester suite (`tests/install-pipeline.Tests.ps1`, `tests/apply-managed-block.Tests.ps1`, `tests/activate-global.Tests.ps1` 및 관련 suite) 와 CLEAN_TARGET_SMOKE_CRITERIA 의 fixture-local SC (channel 1 / 2 positive, channel exhaustion, cross-tree write isolation) 의 실행 + read-only 결과 확인으로 닫는다.
- **Tier A 의 mutation 경계.** Tier A 는 source / doc mutation 이 아니라 fixture-local 실행이다. 기존 suite 의 실행 + 결과 보고는 그 자체로 commit / push / global mutation 을 동반하지 않는다. evidence 보존 형태 (어디에 무엇을 남길지) 는 별도 결정이며 본 anchor 가 새 evidence / archive / snapshot 체계를 자동 도입하지 않는다.

#### 11.1.2 Tier B — real installed-state validation (별도 승인 필요)

mainpc / vanilla pc 같은 **실제 installed legacy / stale / corrupted state** 를 trusted repo source 기준으로 update / reinstall / recover 하여 install / update automation 이 실제 global / user 환경에서 결정론적으로 동작하는지 검증하는 actual validation 이다.

- **검증 시나리오.** (a) stale / minor-drift installed `current/` 를 trusted repo source 로 update / reinstall 하여 §19.2 의 deterministic overwrite + `Invoke-InstallPipelineVerify` PASS 로 정합화. (b) 첫 install 이후 update 경로에서 발견된 이슈가 repo HEAD 에서 수정되었을 때, 그 수정된 scripts 로 installed state 를 다시 정합화. (c) 손상 / 부분 적용 상태의 reinstall-first 회복 (STEP3 guide §19.1 detection-only → §19.2 reinstall).
- **mutation 대상 (global / user filesystem).** `%USERPROFILE%\.claude\ai-harness-toolset\current\` 및 sibling install metadata / payload-manifest / payload-marker; `%USERPROFILE%\.claude\CLAUDE.md` 와 Codex user-global `AGENTS.md` 의 managed-block apply (`activate-global.ps1 -Apply` / `apply-managed-block.ps1`); `%USERPROFILE%\.claude\skills\<skill-name>\` 의 Claude skill whole-file copy / update + hash verification (STEP3 guide §19.3 / §19.4, `INSTALL.md` §10, `GLOBAL_ADOPTION_PROCEDURE.md` §3).
- **승인 boundary.** 위 mutation 은 전부 실제 global / user filesystem mutation 이므로 Tier A 와 분리된 **별도 explicit user-approved scoped step** 으로만 진행한다. forbidden 규칙은 그대로 유지한다 — `%USERPROFILE%\.claude\AGENTS.md` 는 어느 경우에도 생성하지 않는다 (`GLOBAL_ADOPTION_DECISION.md` §6 forbidden row). managed-block apply 는 §19.3 의 dry-run → 사용자 승인 → apply → 검증 보고 절차를 따르고, AI operator 의 ad-hoc splice 를 쓰지 않는다.
- **Tier 순서.** Tier B 는 Tier A 통과를 전제로 한다. Tier A 가 repo HEAD automation 의 결정성을 닫지 못한 상태에서 real installed-state mutation 으로 진입하지 않는다.

#### 11.1.3 Step 4 기본 scope 에서 제외 (deferred / non-default)

다음 항목은 step 4 의 기본 scope 에 포함하지 않고 deferred / non-default 로 유지한다. 각 항목은 별도 scoped goal 의 explicit user-approved decision 으로만 진행한다.

- **literal `?` / `0x3F` non-increase gate** — install / update / managed-block apply 가 source 대비 literal `?` (0x3F) 개수를 증가시키지 않는지의 encoding regression gate. step 4 기본 scope 밖 deferred (별도 결정).
- **source-cut actual handling** — source-cut 은 현행 contract 상 detection-only (STEP3 guide §12.7 / §17). source-cut path 의 실제 처리는 step 4 기본 scope 밖 deferred.
- **external git-url / network validation** — git-url mode 의 실제 network fetch / clone / credential / auth / proxy 검증은 step 4 기본 scope 밖 deferred (현 skeleton 은 local-clone 중심).
- **BF Level 3 (deterministic Brief 자동 저장 / 자동 복구)** — §5 의 allowed-but-unimplemented future scoped work. step 4 validation 의 default scope 가 아니다.

#### 11.1.4 실행 진입 전 review gate 와 사용자 승인 boundary

- 본 §11.1 anchor 자체 (POST_MVP_PLAN.md 의 본 절 추가) 는 source / doc mutation 이므로 본 도구의 정상 review gate (Codex reviewer) 를 거친다. review verdict (`yes` / `no` / `yes with risk`) 은 commit / push / global apply / step 4 execution 시작 어느 것도 자동 승인하지 않는다 (§8 / verdict vocabulary 계약과 정합).
- **Tier A 실행 진입** 은 별도 execution goal 의 사용자 승인을 거친다. 새 test case / 새 criteria doc 작성이 동반되면 그 source / doc mutation 은 정상 review gate 대상이다. 기존 suite 의 단순 실행 + read-only 결과 보고는 source mutation 이 아니다.
- **Tier B 실행 진입** 은 Tier A 통과 후, 실제 global / user filesystem mutation 에 대한 **별도 explicit user-approved scoped step** 을 거친다. 어떤 review verdict 도 Tier B 의 real mutation 을 자동 승인하지 않으며, 각 destination 의 apply 는 사용자 명시 결정 + (managed-block 의 경우) dry-run 보고 → 승인 절차를 요구한다.

본 §11.1 은 `yes` / `no` / `yes with risk` 어느 verdict 의 자동 승인도 아니다. 본 anchor 의 doc mutation 이후의 commit / push / Tier A 실행 / Tier B global apply 시작은 모두 사용자 명시 결정으로 처리한다.
