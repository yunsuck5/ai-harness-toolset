# Post-MVP Plan

본 문서는 `ai-harness-toolset` 의 CLI-only MVP 종료 시점에 합의된 post-MVP 결정 사항을 추적 가능한 형태로 보존한다. **결정의 기록이며, 구현 승인이 아니다.**

post-MVP 항목 어느 것도 본 문서가 존재한다는 사실만으로 implementation, scoped work, scheduling, 또는 release 가 자동 승인되지 않는다. 각 항목은 별도 scoped 승인을 거친 뒤에만 작업이 시작된다.

---

## 1. MVP closeout 상태

- `ai-harness-toolset` 의 CLI-only MVP 는 **closed** 상태다.
- closeout 은 다음을 의미한다.
  - source repo 의 `config/`, `scripts/`, `snippets/`, `templates/` 4 개 폴더만 copy-only / CLI-only 로 다른 프로젝트에 적용 가능하다.
  - 사용자가 `scripts/review-cycle.ps1` 한 번의 호출로 review packet 준비 → input 검증 → Codex CLI 1 회 실행 → verdict parsing → result 기록 → freshness / binding 검증을 모두 마칠 수 있다.
  - `<project-root>/log/review/<run-id>/` 아래 `meta.json`, `input.md`, `result.md`, `result.json` 4 개가 read-only record 로 보존된다.
- closeout 은 다음을 의미하지 **않는다**.
  - post-MVP 항목의 implementation 승인.
  - 새 subsystem 도입 승인.
  - 기존 docs / scripts / templates 의 광범위한 재구성 승인.
  - commit / push / publish / merge / release / deployment 의 자동 승인.
- MVP scope 자체를 다시 넓히는 변경은 본 문서의 범위가 아니다. MVP 의 in-scope / out-of-scope 정의는 `docs/AI_HARNESS_TOOLSET_SCOPE.md` 가 source-of-truth 다.

---

## 2. Codex review system — maintenance mode

- Codex review subsystem (`scripts/review-cycle.ps1`, `scripts/review-prepare.ps1`, `scripts/review-run.ps1`, `scripts/review-verify.ps1`, `scripts/review-input-verify.ps1`, `templates/review-input.md`, `templates/review-meta.json`, `templates/review-result.*`, `config/reviewer.json`) 은 MVP 시점에 operational 이다.
- post-MVP 단계에서 review subsystem 은 **maintenance mode** 로 진입한다.
  - 새 feature, 새 reviewer adapter, multi-reviewer orchestration, review history DB, cross-run aggregation, automatic retention 은 별도 scoped 승인 없이 추가하지 않는다.
  - bug fix, contract clarification, 기존 행동의 정합성 보정은 maintenance scope 안에서 가능하다. 단, 새 feature 와 maintenance fix 의 경계가 모호한 변경은 별도 scoped 승인을 받는다.
- review verdict (`yes` / `no` / `yes with risk`) 는 commit / push / publish / merge / release / deployment 를 자동 승인하지 않는다는 contract 가 그대로 유지된다 (`docs/REVIEW_RESULT_CONTRACT.md` 의 non-goals).
- 사용자 운영 권고 문서로서 `docs/roadmap/REVIEW_EFFORT_GUIDE.md` 가 추가되어 post-MVP 단계의 review effort / cost 통제 가이드를 제공한다. 본 가이드는 review subsystem 의 contract 를 재정의하지 않으며, 어떤 자동 게이트도 도입하지 않는다.

---

## 3. Brief system — post-MVP core

> **Superseded (BRIEF posture reconciliation).** 본 §3 의 canonical Brief 위치 결정 (`brief/BRIEF.md` 가 canonical,
> `log/brief/` 디렉터리는 만들지 않는다) 은 이후의 BRIEF posture reconciliation 으로 superseded 되었다.
> 현재 canonical BRIEF 위치는 `<ProjectRoot>/log/brief/BRIEF.md` 이며, BRIEF 는 `log/` 아래 operator-local
> runtime state 다. root `<ProjectRoot>/brief/` 는 ai-harness 용도로 금지된다. source-of-truth 는
> `docs/BRIEF_CONTRACT.md` 다. 아래 §3 본문은 reconciliation 이전 시점의 결정 기록으로 보존한다.

- Brief system 은 post-MVP 의 core 항목이다. 단, 본 문서는 Brief system 의 implementation 시점, 우선순위, owner, deadline 을 확정하지 않는다.
- canonical Brief 위치 결정.
  - target repo 의 canonical restore source 는 `brief/BRIEF.md` 다.
  - source repo (이 toolset 의 source 트리) 에는 `brief/` 를 두지 않는다.
  - target project 에 적용되는 시점에 한해 `brief/BRIEF.md` 가 canonical 위치다.
- 금지 항목.
  - `log/brief/` 디렉터리는 만들지 않는다. `log/` 는 runtime artifact 트리이고, Brief 의 canonical 위치가 아니다.
  - 기존 `log/chatlog/current/resume.md` / `log/chatlog/current/summary.md` 를 `log/brief/` 아래로 옮기는 reorganization 은 본 결정 범위 밖이다.
- 기존 `log/chatlog/current/resume.md` / `log/chatlog/current/summary.md` 는 BF Level 1/2 artifact 로 계속 동작한다. 이 두 파일이 곧 Chatlog system 의 implementation 은 아니다 (다음 절 참조).
- 현재 상태 (source repo).
  - source-side primitive (`scripts/brief-init.ps1`, `scripts/brief-check.ps1`, `templates/brief/BRIEF.md`) implementation 완료.
  - `snippets/CLAUDE_SNIPPET.md` / `snippets/AGENTS_SNIPPET.md` 의 BF Level 3 protocol 정합성 정렬 완료.
  - target payload 측 smoke test 완료.
  - 위 항목들은 source-side 가 `docs/BRIEF_CONTRACT.md` 책임 경계를 충족한다는 의미다. Brief system 전체 (target-side rollout, deterministic 자동화 확장 등) 의 완료를 의미하지 않으며, 본 절 첫 줄의 implementation 시점 / 우선순위 / owner / deadline 미확정 진술은 그 broader scope 에 대해 그대로 유효하다.

---

## 4. Chatlog system — intended subsystem, not implemented

- Chatlog system 은 ai-harness-toolset 이 향후 다루기로 의도한 subsystem 이다.
- 현재 시점의 사실 인식.
  - Chatlog system 자체의 practical implementation 과 testing 은 **거의 없는 상태** 다.
  - `docs/CHATLOG_CONTRACT.md` 가 BF / CL 책임 분리, summary-first / resume-first 원칙, canonical heading 등을 정의하지만, 이는 manual convention 이다.
  - `log/chatlog/current/resume.md`, `log/chatlog/current/summary.md` 는 **BF Level 1/2 artifact** 다. Chatlog system 의 CL (Chat Log — 누적 work history / portfolio / audit) 영역의 fuller implementation 이 아니다.
- 따라서 다음 두 개의 명제가 동시에 성립한다.
  - "log/chatlog/current/ 가 갱신되고 있다" 는 사실은 Chatlog system 이 implementation 되었다는 의미가 아니다.
  - "Chatlog system 이 아직 implementation 되지 않았다" 는 사실은 BF artifact 사용을 막지 않는다.
- CL 영역의 자동화 (누적 work history, 자체 schema, retention, browse UI, RND-style heavy workflow) 는 본 결정 범위 밖이며 별도 scoped 승인이 필요하다.

---

## 5. BF Level 3 — allowed scope

- BF Level 3 (사용자 자연어 trigger 가 아닌, 보다 deterministic 하게 BF 를 갱신하는 형태의 자동화) 는 post-MVP 단계에서 **허용 범위 안** 이다.
- 단, 다음 항목은 BF Level 3 의 이름으로도 본 결정 범위에서 명시적으로 **금지** 한다.
  - daemon
  - watcher
  - scheduler
  - `BF_STATE.json` 같은 별도 state machine 파일
  - automatic decision-maker (사용자 동의 없이 다음 action 을 결정하고 실행하는 components)
- BF Level 3 implementation 자체도 본 문서가 자동 승인하지 않는다. design / scoped 승인 / scoped implementation 이 별도로 필요하다.
- 본 절은 BF Level 3 이 후속 작업의 scope 안에 있을 수 있다는 사실만 기록한다.
- 현재 상태 (source repo).
  - BF Level 3 의 source-side primitive (§3 참조) 는 implementation 완료 상태다.
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
  - 현재 active default 는 README 가 명시한 copy-only adoption 이다 (`docs/AI_HARNESS_TOOLSET_SCOPE.md` source-vs-target 경계).
  - link / pinned-link adoption mode 의 도입 여부와 책임 경계는 별도 scoped 승인이 필요한 deferred decision 이다.
  - 본 결정은 packaging (`package-toolset.ps1`) 결정과 sibling 관계이며, 두 결정의 boundary 가 일관성 있게 정해진 뒤에야 implementation 단계로 넘어간다.
  - 본 항목의 framing 은 `docs/roadmap/GLOBAL_ADOPTION_DECISION.md` §1, §4 의 결정에 의해 reframed 되었다. 위 historical enumeration (copy / link / pinned-link) 은 historical record 로 그대로 보존하되, 현 시점의 preferred direction 은 다음과 같이 갱신되었다.
    - global / common AI development operating layer 가 preferred direction 이다.
    - target 안의 `.ai-harness/` copied tool folder 는 default preferred shape 이 아니다.
    - symlink / junction / link 는 direct shared/global invocation 의 변경 폭이 너무 클 때만 검토되는 fallback candidate 다.
    - installer-first productization 은 본 단계에서 out of scope 다.
  - 따라서 본 §6 의 `copy / link / pinned-link` enumeration 이 여전히 primary direction decision 이라고 해석하지 않는다. primary direction 의 source-of-truth 는 `docs/roadmap/GLOBAL_ADOPTION_DECISION.md` 다.

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
- MVP scope 자체의 정의는 `docs/AI_HARNESS_TOOLSET_SCOPE.md`, review subsystem 의 contract 는 `docs/REVIEW_RESULT_CONTRACT.md`, chatlog / BF / CL 책임 분리는 `docs/CHATLOG_CONTRACT.md` 가 source-of-truth 다. 본 문서는 이 contract 들과 상충하는 결정을 내리지 않는다.
- MVP closeout 의 가벼운 기록은 `docs/DECISIONS.md` 에 한 줄로 두고, 자세한 내역은 본 문서를 가리킨다.

---

## 10. Post-MVP status summary

본 절은 post-MVP 잔여 항목의 현재 분류를 한 자리에 모은 요약이다. 다른 절보다 자세하지 않으며, §1–§9 본문과 충돌하면 본문이 우선한다.

### Completed (source repo side)

- CLI-only MVP closed (§1).
- Codex review subsystem operational, maintenance mode 진입 (§2).
- Brief / BF Level 3 의 source-side primitive (`scripts/brief-init.ps1`, `scripts/brief-check.ps1`, `templates/brief/BRIEF.md`) implementation 완료 (§3, §5).
- `snippets/CLAUDE_SNIPPET.md` / `snippets/AGENTS_SNIPPET.md` 의 BF Level 3 protocol 정합성 정렬 완료 (§3, §5).
- target payload 측 BF Level 3 smoke test 완료 (§3, §5).
- post-MVP review effort / cost 운영 권고 문서 `docs/roadmap/REVIEW_EFFORT_GUIDE.md` 추가 완료 (§2).
- global adoption operating layer 방향 결정 `docs/roadmap/GLOBAL_ADOPTION_DECISION.md` 기록 완료 (§6, §11).
- `snippets/CLAUDE_SNIPPET.md` / `snippets/AGENTS_SNIPPET.md` 에 `AI_HARNESS_TOOLSET_GLOBAL` managed block marker 적용 완료 (`docs/roadmap/GLOBAL_ADOPTION_DECISION.md` §6).
- Claude skill 의 global adoption / update / removal 절차 문서화 완료 (`docs/roadmap/GLOBAL_ADOPTION_PROCEDURE.md`, `docs/roadmap/GLOBAL_ADOPTION_DECISION.md` §5).
- ToolRoot / ProjectRoot path handling audit 문서화 완료 (`docs/roadmap/TOOLROOT_PROJECTROOT_AUDIT.md`, `docs/roadmap/GLOBAL_ADOPTION_DECISION.md` §8). self-target / dogfooding path collision sub-scope 포함.
- shared / global mode invocation contract design 문서화 완료 (`docs/roadmap/SHARED_GLOBAL_INVOCATION_CONTRACT.md`). audit §8 의 D1–D9 결정 및 implementation split 포함.
- shared / global mode implementation 완료. `docs/roadmap/SHARED_GLOBAL_INVOCATION_CONTRACT.md` §6 의 8 개 split unit 이 모두 독립 commit 으로 반영됨 — `Get-ToolRoot` channel chain (`bd0ac83`), component script fallback policy (`9130c68`), snippet mode-neutral body (`8234bf1`), SKILL.md script root 분기 (`df09bf5`), review-verify toolRoot binding (`dadff4d`), review-cycle untracked exclusion (`67430c4`), self-target enforcement check (`14ce6c9`), `Get-ProjectRoot` CWD advisory (`bebe7ab`, `043b0e0`). **단, 이 implementation 완료는 source-side 의 path / invocation 동작이 갖춰졌다는 의미이며, actual global activation / install / update / self-adoption 의 수행을 의미하지 않는다 — 후자는 §11 의 remaining order 에 별도 step 으로 남는다.**
- clean target smoke test criteria 정의 완료 (`docs/roadmap/CLEAN_TARGET_SMOKE_CRITERIA.md`). SC1–SC7 의 pre-condition / action / observable pass / fail / required evidence 정의 포함 (`85433e5` 및 후속 정합 commit `9af5f62`, `24d2010`).
- global install / update / validation / self-adoption operating model 문서화 완료 (`docs/roadmap/GLOBAL_INSTALL_UPDATE_MODEL.md`). 설치 source 획득 방식 2 종 (install-from-git-url, install-from-local-clone), metadata-dispatched update, global install metadata schema, validation-before-implementation (manual global activation / controlled global materialization), target footprint contract, self-adoption model 을 포함한다. 본 문서는 global install / update / self-adoption 판단의 **current source-of-truth** 다. 단, 문서화 완료가 actual global install / update 의 수행을 의미하지는 않는다.

### Deferred (separate scoped approval required)

본 항목들의 권장 처리 순서는 §11 에 있다. manual global activation 을 포함한 **모든 실제 global mutation 은 별도 scoped 승인이 필요하다.** 본 절은 어떤 global mutation 도 자동 승인하지 않는다.

- global behavior validation — manual global activation / controlled global materialization 으로 global entrypoint / ToolRoot·ProjectRoot 분리 / target footprint / runtime artifact 위치가 실제로 성립하는지 검증 (`docs/roadmap/GLOBAL_INSTALL_UPDATE_MODEL.md` §7, §11 step 2).
- install / update automation implementation 및 그 validation (`docs/roadmap/GLOBAL_INSTALL_UPDATE_MODEL.md` §3–§5, §11 step 3–4).
- `ai-harness-toolset` self-adoption (`docs/roadmap/GLOBAL_INSTALL_UPDATE_MODEL.md` §9, §11 step 5).
- clean target smoke test 실행 — **partial / not fully repo-auditable.** SC5 / SC5' 관련 실행 evidence 는 존재하나 (`docs/backlog/operations.md` 참조), full SC1–SC7 suite 의 evidence 는 `%TEMP%` 에 흩어져 있어 repo 기준으로 complete 로 승격할 수 없다. 완전 실행 + repo-auditable evidence 확보는 별도 scoped 승인이 필요하다 (§11 step 6).
- post-MVP closeout 결정 (§11 step 7).
- GJMNet clean adoption (§7, §11 step 8).
- `package-toolset.ps1` implementation (§6).
- Chatlog system 의 CL 영역 fuller implementation (§4).
- docs taxonomy 의 실제 path migration. docs taxonomy 자체는 별도로 논의되었으며 향후 잊지 않는다 — 다만 실제 path migration 은 path reference scan 과 별도 scoped 승인이 모두 필요한 deferred 항목이다 (§8).

### Operations backlog track (parallel)

`docs/backlog/operations.md` 의 3 개 항목은 §11 numbered order 와 별개의 **parallel / supporting operational track** 이다. smoke 실행 시도 과정에서 도출된 운영 품질 항목이며, 그 중 2·3 번은 §11 의 global behavior validation (step 2) / clean target smoke execution (step 6) / self-adoption validation (step 5) 을 지원하는 prerequisite 다. 각 항목의 implementation 은 별도 scoped 승인을 거친다.

- **Long-lived docs commit hash hygiene** (candidate) — long-lived doc 의 literal commit hash hygiene. §11 numbered order 와 독립적인 저우선 doc hygiene 항목.
- **PowerShell smoke invocation quoting hardening** (scope-defined) — smoke driver invocation 의 quoting fragility. 미정리 시 §11 의 validation / smoke 실행이 driver failure 로 반복 중단될 risk. 다음 implementation goal 은 (R) runbook-only / (S) helper-snippet / (W) wrapper-script 중 1 개 채택.
- **Smoke evidence preservation** (scope-defined) — `%TEMP%` evidence loss risk. 미정리 시 §11 의 validation / smoke evidence 가 repo-auditable 형태로 보존되지 않는다. 다음 implementation goal 은 (A) runbook-only / (B) helper-script / (C) archive manifest 중 1 개 채택.

### Decisions reaffirmed

- 기존 GJMNet 안의 ai-harness-toolset application state 는 disposable. migration / cleanup 작업은 post-MVP 항목이 아니다 (§7).
- GJMNet 은 post-MVP foundation 항목 (Brief system / BF Level 3 / packaging) 이 ready 된 뒤 clean git repo 로 재생성한다. 그 이후의 운용은 CLI-only (§7).
- 설치 / adoption mode 의 방향 결정은 `docs/roadmap/GLOBAL_ADOPTION_DECISION.md` §1, §4 에 기록되었고, 그 구체적 layer / path / flow / metadata 모델은 `docs/roadmap/GLOBAL_INSTALL_UPDATE_MODEL.md` 가 current source-of-truth 다. `copy / link / pinned-link` framing 은 §6 안 historical record 로 보존되며, implementation 세부 중 managed block marker 적용, Claude skill global / update / removal 절차 문서화, ToolRoot / ProjectRoot path handling audit 문서화, shared / global mode invocation contract design 문서화, shared / global mode implementation (§6 의 8 개 split unit 전부), clean target smoke test criteria 정의, global install/update/self-adoption operating model 문서화는 모두 완료되었다 (§10 Completed). 잔여 항목은 global behavior validation, install / update implementation 및 validation, self-adoption, clean target smoke test 실행 등이며 (§10 Deferred, §11 의 numbered order), 모두 별도 scoped 승인이 필요하다 (§6, `docs/roadmap/GLOBAL_ADOPTION_DECISION.md` §6, §8, §9, `docs/roadmap/GLOBAL_INSTALL_UPDATE_MODEL.md`, `docs/roadmap/TOOLROOT_PROJECTROOT_AUDIT.md` §6–§8, `docs/roadmap/SHARED_GLOBAL_INVOCATION_CONTRACT.md` §4, §6).
- shared / global mode implementation 완료와 actual global activation / install / update / self-adoption 은 구분된다. 전자는 §10 Completed 이고, 후자는 §11 의 remaining order step 2–5 로서 별도 scoped 승인이 필요하다. POST_MVP_PLAN.md 의 어떤 진술도 실제 global install / global mutation 을 자동 승인하지 않는다.
- docs taxonomy 는 planned but deferred 다. 실제 path migration 은 별도 scoped 승인이 필요하다 (§8).
- review verdict (`yes` / `no` / `yes with risk`) 는 commit / push / release 의 자동 승인이 아니다 (§2, §8, `docs/REVIEW_RESULT_CONTRACT.md`).

---

## 11. Recommended remaining order

본 절은 post-MVP **잔여 항목** 의 권장 처리 순서다. completed step 들은 §10 Completed (source repo side) 에 기록되어 있고, 본 §11 은 그 이후의 remaining work 만 다룬다. **순서 자체는 자동 승인이 아니다.** 각 단계는 §8 guardrail 을 깨지 않는 범위 안에서 별도 scoped 승인을 거친다. 특히 manual global activation 을 포함한 **모든 실제 global mutation 은 separate scoped approval 이 필요하다** — 본 절은 어떤 global mutation, snippets / scripts / config / templates 변경, global `CLAUDE.md` / `AGENTS.md` mutation, commit, push 도 자동 승인하지 않는다.

본 순서는 `docs/roadmap/GLOBAL_INSTALL_UPDATE_MODEL.md` 를 current global install / update / self-adoption 판단 기준으로 참조한다. `docs/roadmap/GLOBAL_ADOPTION_DECISION.md` §9 의 step 1–5, shared / global mode invocation contract design, **shared / global mode implementation (§6 의 8 개 split unit 전부)**, **clean target smoke test criteria 정의**, 그리고 **global install / update / self-adoption operating model 문서화** 는 모두 §10 Completed 에 기록되어 본 §11 에서는 제외한다. shared / global mode implementation 완료는 source-side path / invocation 동작이 갖춰졌다는 의미이며, 아래 step 들 (actual global activation / install / update / self-adoption) 의 수행과는 구분된다. 또한 본 순서는 내부 roadmap closeout 판단을 보존하기 위해 GJMNet clean adoption 직전에 post-MVP closeout 결정을 별도 step 으로 유지한다.

본 §11 기준 **다음 실제 milestone 은 step 1 (`GLOBAL_INSTALL_UPDATE_MODEL.md` 확정)** 이다.

1. `docs/roadmap/GLOBAL_INSTALL_UPDATE_MODEL.md` 확정. global install / update / validation / self-adoption operating model 을 current source-of-truth 로 확정한다.
2. manual global activation / controlled global materialization 으로 global behavior validation. global entrypoint / ToolRoot·ProjectRoot 분리 / target footprint / runtime artifact 위치가 실제로 성립하는지 검증한다 (`GLOBAL_INSTALL_UPDATE_MODEL.md` §7). 실제 global mutation 이므로 별도 scoped 승인이 필요하다.
3. validation result 를 기준으로 install / update implementation (`GLOBAL_INSTALL_UPDATE_MODEL.md` §3–§5).
4. install / update validation.
5. `ai-harness-toolset` self-adoption (`GLOBAL_INSTALL_UPDATE_MODEL.md` §9).
6. clean target smoke test 실행 / repo-auditable evidence 확보. `docs/roadmap/CLEAN_TARGET_SMOKE_CRITERIA.md` 의 full SC1–SC7 suite 를 실행한다. 현재는 SC5 / SC5' 부분 실행만 evidence 가 존재하며 full suite 는 미완 상태다 (§10 Deferred 참조).
7. post-MVP closeout 결정.
8. new GJMNet repo 의 clean adoption. self-adoption (step 5) 과 global behavior validation (step 2) 이후로 유지한다 (§7).

순서 변경, 항목 추가, 또는 항목 삭제는 별도 scoped 승인이 필요하다. operations backlog track (§10) 의 항목은 본 numbered order 와 병렬이며, 그 중 2·3 번 (PowerShell smoke invocation quoting hardening, Smoke evidence preservation) 은 step 2 / step 5 / step 6 을 지원하는 prerequisite 로 다룬다.
