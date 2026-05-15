# Global Adoption Procedure

본 문서는 `ai-harness-toolset` 의 Claude skill 자산을 사용자 글로벌 environment 에 채택 / 업데이트 / 제거하는 절차를 기록한다. **절차의 기록이며, implementation 승인이 아니다.**

본 문서가 존재한다는 사실만으로 어떤 skill 의 실제 install, update, removal 도 자동 승인되지 않는다. 각 행위는 사용자 명시 trigger 와 scoped 승인을 거친 뒤에만 실행된다.

본 문서는 다음 source-of-truth 들과 충돌하지 않는다.

- 운영 계층 결정: `docs/roadmap/GLOBAL_ADOPTION_DECISION.md`
- post-MVP 결정 기록: `docs/roadmap/POST_MVP_PLAN.md`
- review record 계약: `docs/REVIEW_RESULT_CONTRACT.md`
- subsystem scope: `docs/AI_HARNESS_TOOLSET_SCOPE.md`

위 문서와 본 문서가 상충하면 위 문서들의 보수적 해석을 우선한다.

---

## 1. Purpose

`docs/roadmap/GLOBAL_ADOPTION_DECISION.md` §5 는 adoption / update 의 operator 가 AI 라는 방향을 결정했다. 본 문서는 그 방향을 Claude skill 자산에 한정하여 절차로 풀어낸 운영 가이드다.

본 가이드의 책임은 다음으로 한정된다.

- Claude skill 자산 (`snippets/claude-skills/**`) 을 사용자 글로벌 environment (`~/.claude/skills/<name>/`) 에 채택할 때 따르는 단계.
- 동일 자산의 업데이트 / 제거 단계.
- 각 단계에서 요구되는 사용자 trigger 와 명시적 승인 규칙.

본 가이드의 책임이 **아닌** 항목.

- 글로벌 instruction file (Claude `%USERPROFILE%\.claude\CLAUDE.md`, Codex `%USERPROFILE%\.codex\AGENTS.md` 또는 `%CODEX_HOME%\AGENTS.md`, Codex user-global `AGENTS.override.md`, project-root `CLAUDE.md` / `AGENTS.md`) 의 managed block update. 본 동작의 marker 정책과 path enumeration 은 `docs/roadmap/GLOBAL_ADOPTION_DECISION.md` §6 이 source-of-truth 다 — generic 한 "global `AGENTS.md`" wording 만 사용하면 `%USERPROFILE%\.claude\AGENTS.md` 같은 forbidden path 로 오인될 수 있으므로 §6 의 path table 을 참조한다.
- shared / global script invocation 의 path handling implementation. 본 동작의 audit 요구 사항은 `docs/roadmap/GLOBAL_ADOPTION_DECISION.md` §8 다.
- target project 의 `.gitignore`, `brief/`, `log/` 의 변경. 본 동작들은 다른 계약이 source-of-truth 다.
- installer 자동화. 본 단계에서 `install.ps1` 등 productized installer 는 명시적으로 out of scope 다 (`docs/roadmap/GLOBAL_ADOPTION_DECISION.md` §10).

---

## 2. Scope of skill assets

본 문서가 다루는 skill 자산은 source repo 의 다음 트리에 한정된다.

- `snippets/claude-skills/<skill-name>/SKILL.md`

현재 source repo 에 존재하는 skill 자산.

- `snippets/claude-skills/ai-harness-review/SKILL.md`

추가 skill 이 source repo 에 도입되는 경우 본 문서의 동일 절차가 동일하게 적용된다. 각 skill 의 자산은 자체 디렉터리로 격리된다 (`<skill-name>/` 단위).

본 문서는 source repo 의 skill 자산 자체를 수정하지 않는다. 그 책임은 일반 source repo 편집 절차에 속한다.

---

## 3. Paths

본 절은 절차에서 참조하는 경로의 conceptual split 을 기록한다. 본 split 은 `docs/roadmap/GLOBAL_ADOPTION_DECISION.md` §8 의 ToolRoot / ProjectRoot 모델과 정합되며, 본 문서가 새 path 모델을 도입하지 않는다.

- `ToolRoot` — `ai-harness-toolset` source repo root (예: `H:/Work/ai-harness-toolset/ai-harness-toolset`).
- `SkillSourceRoot` — `<ToolRoot>/snippets/claude-skills`.
- `GlobalSkillRoot` — 사용자 글로벌 Claude environment 의 skill 디렉터리 (예: `~/.claude/skills`).
- `GlobalSkillDir(name)` — `<GlobalSkillRoot>/<skill-name>`.
- `GlobalSkillFile(name)` — `<GlobalSkillDir(name)>/SKILL.md`.

본 문서는 위 경로들의 실제 구현 / 자동 해결을 강제하지 않는다. 절차 안에서 사용자 / AI 가 해당 경로를 inspect 할 때의 reference 다.

---

## 4. Trigger discipline

본 절차는 사용자 명시 trigger 가 있을 때에만 시작된다. trigger 가 없는 동안에는 skill install / update / removal 행위가 발생하지 않는다.

기대되는 자연어 trigger 예시 (`docs/roadmap/GLOBAL_ADOPTION_DECISION.md` §5 의 예시와 정합).

- "ai-harness-toolset global adoption 진행해줘"
- "ai-harness-toolset skill 설치해줘"
- "ai-harness-toolset skill 업데이트해줘"
- "ai-harness-toolset skill 제거해줘"

위 예시는 contract 가 아니다. 동일 의도의 다른 자연어 표현도 trigger 로 인식될 수 있다. 단, 다음 항목은 trigger 하나로 자동 진행되지 않는다.

- 실제 file 생성 / 덮어쓰기 / 삭제.
- 글로벌 `CLAUDE.md` / `AGENTS.md` 의 managed block update (별도 절차).
- 다른 source repo 파일의 변경.

각 행위는 §5–§7 의 단계별 명시 승인 규칙을 따른다.

---

## 5. Adoption — first install

skill 이 글로벌 environment 에 존재하지 않을 때의 절차다.

### 5.1 Pre-flight inspect

1. `<SkillSourceRoot>/<skill-name>/SKILL.md` 의 존재를 확인한다. 없으면 중단한다.
2. `<GlobalSkillRoot>` 의 존재를 확인한다. 없으면 사용자에게 알리고 디렉터리 생성 승인을 받는다. 승인 없으면 중단한다.
3. `<GlobalSkillDir(name)>` 의 존재를 확인한다.
   - 존재하지 않으면 first install 경로로 진행한다.
   - 존재하면 §6 update 경로로 분기한다.

### 5.2 Propose

다음 항목을 사용자에게 명시적으로 보여준다.

- source skill 경로: `<SkillSourceRoot>/<skill-name>/SKILL.md`.
- 대상 글로벌 경로: `<GlobalSkillFile(name)>`.
- skill 의 `description` field (frontmatter) 와 trigger 의도 요약.
- 생성 예정인 디렉터리 (`<GlobalSkillDir(name)>`).
- 복사 예정 파일 목록과 각 파일의 크기.

위 항목은 사용자가 install 의 효과를 사전에 확인할 수 있도록 제공된다.

### 5.3 Explicit approval

사용자의 명시적 yes / proceed / 진행해 등의 승인을 받는다. 모호한 응답은 진행 사유로 해석하지 않는다. 사용자가 거부하거나 응답하지 않으면 중단한다.

### 5.4 Apply

승인된 항목만 적용한다.

1. `<GlobalSkillDir(name)>` 을 생성한다.
2. `<SkillSourceRoot>/<skill-name>/SKILL.md` 를 `<GlobalSkillFile(name)>` 로 복사한다.
3. 본 단계에서는 frontmatter 의 임의 수정을 수행하지 않는다.

### 5.5 Verify

1. `<GlobalSkillFile(name)>` 가 실제로 존재하고 content 가 source 와 일치하는지 확인한다.
2. 결과를 사용자에게 보고한다. 본 절차는 verdict 가 아니다. install 의 결과는 commit / push / publish / merge / release / 자동 reload 를 자동 승인하지 않는다.

---

## 6. Update — existing skill present

skill 이 이미 글로벌 environment 에 존재할 때의 절차다.

### 6.1 Pre-flight inspect

1. `<SkillSourceRoot>/<skill-name>/SKILL.md` 의 존재와 hash 를 확인한다. 없으면 중단한다.
2. `<GlobalSkillFile(name)>` 의 존재와 hash 를 확인한다. 없으면 §5 first install 경로로 분기한다.
3. 두 hash 가 동일하면 변경 사항이 없다는 사실을 사용자에게 보고하고 중단한다.

### 6.2 Diff propose

1. source 와 글로벌 사이의 textual diff 를 사용자에게 보여준다.
2. diff 가 다음 항목을 포함하는지 명시한다.
   - trigger 의도 (description) 의 변경 여부.
   - "Required behavior" / "Failure handling" / "Out of scope" 등 주요 섹션의 변경 여부.
   - 새 hard rule 의 추가 여부.
3. diff 가 사용자가 글로벌 environment 에서 의도적으로 유지하던 customization 을 덮어쓸 가능성을 명시한다. 사용자가 글로벌 SKILL.md 를 별도 수정해 두었던 경우, replacement 는 그 수정을 lose 한다는 사실을 알린다.

### 6.3 Explicit approval

사용자의 명시적 승인을 받는다. 모호한 응답은 진행 사유로 해석하지 않는다.

### 6.4 Apply

승인된 항목만 적용한다.

1. `<GlobalSkillFile(name)>` 를 source content 로 교체한다.
2. 본 단계에서는 partial merge 를 수행하지 않는다. SKILL.md 단위의 전체 교체만 수행한다. partial merge 가 필요하다면 사용자에게 source repo 의 SKILL.md 수정으로 처리할 것을 권한다.

### 6.5 Verify

1. `<GlobalSkillFile(name)>` 의 hash 가 source 와 일치하는지 확인한다.
2. 결과를 사용자에게 보고한다.

---

## 7. Removal

skill 을 글로벌 environment 에서 제거하는 절차다.

### 7.1 Pre-flight inspect

1. `<GlobalSkillDir(name)>` 의 존재를 확인한다. 없으면 사용자에게 알리고 중단한다.
2. `<GlobalSkillDir(name)>` 아래의 파일 목록을 작성한다. SKILL.md 외 다른 파일이 있으면 별도 표시한다.

### 7.2 Propose

1. 삭제 예정 경로 (`<GlobalSkillDir(name)>`) 와 그 안의 파일 목록을 사용자에게 보여준다.
2. 삭제 후 해당 skill 자연어 trigger 가 더 이상 작동하지 않게 된다는 사실을 명시한다.
3. source repo 의 `<SkillSourceRoot>/<skill-name>/` 는 본 절차로 영향받지 않는다는 사실을 명시한다.

### 7.3 Explicit approval

사용자의 명시적 yes / proceed / 진행해 등의 승인을 받는다. 모호한 응답은 진행 사유로 해석하지 않는다.

### 7.4 Apply

승인된 경로만 삭제한다. 디렉터리 밖의 어떤 파일도 삭제하지 않는다.

### 7.5 Verify

1. `<GlobalSkillDir(name)>` 의 부재를 확인한다.
2. 결과를 사용자에게 보고한다.

---

## 8. Multiple skills, partial selection

source repo 에 둘 이상의 skill 자산이 있는 경우의 운영 규칙.

- 사용자가 특정 skill 의 이름을 명시하면 해당 skill 만 처리한다.
- 사용자가 "전부" / "all" 의 의도를 명시하면 모든 skill 을 각각 §5–§7 절차로 개별 처리한다. 즉, 각 skill 마다 별도의 diff propose 와 별도의 승인이 필요하다.
- 모호한 trigger 는 사용자에게 처리 대상을 묻는다. 추정으로 진행하지 않는다.

---

## 9. Non-goals

본 문서는 다음을 **포함하지 않는다**. 본 문서가 존재한다는 사실로 아래 항목이 승인 / 실행되었다고 해석하지 않는다.

- 실제 first install / update / removal 의 자동 실행. 본 문서는 절차 기록일 뿐, 본 commit 으로 어떤 skill file 도 글로벌 environment 에 생성되지 않는다.
- 사용자 승인 없는 글로벌 file 변경.
- 사용자 승인 없는 source repo file 변경.
- 글로벌 `CLAUDE.md` / `AGENTS.md` 의 managed block update.
- target project 의 `.gitignore`, `brief/`, `log/` 변경.
- 다른 IDE / editor 의 plugin / extension 자동 설치.
- 사용자 git config 의 변경.
- automatic commit / push / publish / merge / release.
- rollback framework.
- installer-first productization.
- daemon / watcher / scheduler.

위 항목 중 어느 것이라도 진행하려면 별도 scoped 승인을 거친다. 본 문서는 그 승인 절차의 input 자료일 뿐이다.

---

## 10. Source-of-truth 관계

- 본 문서는 Claude skill 의 글로벌 채택 / 업데이트 / 제거 절차에 한정된다.
- 본 문서가 다루지 않는 영역의 결정은 §1 의 source-of-truth 문서들이 우선한다.
- 본 문서와 위 source-of-truth 문서들이 상충하면 보수적 해석을 우선한다 (= 자동 실행 금지, 명시 승인 요구).
- 본 문서는 review verdict (`yes` / `no` / `yes with risk`) 를 commit / push / publish / merge / release / adoption 의 자동 승인으로 해석하지 않는다는 contract 를 그대로 유지한다.
