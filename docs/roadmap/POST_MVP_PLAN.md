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

---

## 3. Brief system — post-MVP core

- Brief system 은 post-MVP 의 core 항목이다. 단, 본 문서는 Brief system 의 implementation 시점, 우선순위, owner, deadline 을 확정하지 않는다.
- canonical Brief 위치 결정.
  - target repo 의 canonical restore source 는 `brief/BRIEF.md` 다.
  - source repo (이 toolset 의 source 트리) 에는 `brief/` 를 두지 않는다.
  - target project 에 적용되는 시점에 한해 `brief/BRIEF.md` 가 canonical 위치다.
- 금지 항목.
  - `log/brief/` 디렉터리는 만들지 않는다. `log/` 는 runtime artifact 트리이고, Brief 의 canonical 위치가 아니다.
  - 기존 `log/chatlog/current/resume.md` / `log/chatlog/current/summary.md` 를 `log/brief/` 아래로 옮기는 reorganization 은 본 결정 범위 밖이다.
- 기존 `log/chatlog/current/resume.md` / `log/chatlog/current/summary.md` 는 BF Level 1/2 artifact 로 계속 동작한다. 이 두 파일이 곧 Chatlog system 의 implementation 은 아니다 (다음 절 참조).

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

---

## 7. GJMNet adoption — deferred

- 별도 프로젝트인 GJMNet 으로의 ai-harness-toolset 적용은 **defer** 한다.
- defer 의 조건은 다음 세 항목 모두가 ready 상태에 도달할 때까지다.
  - Brief system (canonical 위치, restore-offer behavior, BF Level 3 boundary 포함) 의 방향이 정해진 시점.
  - BF Level 3 의 design boundary 가 정해진 시점.
  - packaging (`package-toolset.ps1` 의 책임 / shape) 방향이 정해진 시점.
- 위 세 항목 중 하나라도 미정인 동안에는 GJMNet 적용은 시작하지 않는다.
- legacy ai-harness 의 GJMNet 적용 흐름과 별도로, 본 결정은 **새 ai-harness-toolset** 의 GJMNet 적용을 defer 한다는 의미다.

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
