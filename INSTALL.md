# Install — ai-harness-toolset

본 문서는 `ai-harness-toolset` 의 **unified install guide** 다. GitHub repo URL 또는 local clone path 어느 source input 으로 시작하더라도 install 의 model 과 절차가 동일하다는 사실을 본 문서 하나로 self-contained 하게 설명한다. 본 문서는 thin pointer 가 아니라 install 수행에 필요한 절차 전부를 본문에 포함한다 — install / update / reinstall / operational install 의 **유일한 operative contract** 다. install 실행 중에는 repo 의 `docs/` 문서를 읽을 필요가 없다 (아래 anti-coupling 규칙).

본 문서의 존재만으로 어떤 install / update / global filesystem mutation / managed-block apply / commit / push / publish / merge / release 도 자동 승인되지 않는다.

## Anti-coupling — INSTALL.md 는 self-contained install contract 다

본 INSTALL.md 는 install / update / reinstall / operational install 의 **유일한 operative contract** 다. install 실행 중 적용되는 모든 규칙 — source acquisition, install identity, 5-phase operational install flow, activation surface 와 그 적용 방식 (managed-block markers / skill adoption), verify, smoke, cleanup, metadata schema, mutation boundary — 은 본 문서 본문 안에 self-contained 하게 들어 있다.

- **install 실행 중 repo `docs/` 를 열지 않는다.** Claude Code 는 install / update / operational install 을 완료하기 위해 `docs/roadmap/**`, `docs/user_guide/OPERATOR_GUIDE_KR.md`, 또는 그 밖의 repo 문서를 읽을 필요가 없으며, 읽어서 install 동작을 결정해서도 안 된다. 사용자가 명시적으로 design / background review 를 요청한 경우에만 그 문서들을 연다 — 그것은 install 실행이 아니라 별도의 review 작업이다.
- **docs 변경만으로 install 동작이 바뀌지 않는다.** `docs/` 파일이 stale / 누락 / rename / 삭제되어도 install semantics 는 전적으로 본 INSTALL.md 본문이 결정한다. install 에 필요한 규칙 중 어느 것도 "see docs/..." 로 위임되어 있지 않다.
- **docs/ 는 install-time input 이 아니다.** `docs/` 문서는 historical / design / background material 로 존재할 수 있으나 install-time input 이 아니다. 어떤 `docs/` 파일도 본 INSTALL.md 를 override 하거나 install source-of-truth 가 아니다 — install source-of-truth 는 본 INSTALL.md 하나다.
- **installed payload 경로는 참조해도 된다.** 본 문서는 실제 install artifact 인 `scripts/` / `snippets/` / `templates/` 경로 (예: 적용할 managed-block snippet `snippets/CLAUDE_SNIPPET.md` / `snippets/AGENTS_SNIPPET.md`, skill payload `snippets/claude-skills/ai-harness-review/SKILL.md`) 를 참조한다 — 이는 install 의 대상 / 입력 artifact 이며 docs coupling 이 아니다. install 의 *결정 규칙* 자체는 본 문서 본문에 있다.
- **본 문서의 갱신 시점.** INSTALL.md 는 install process, activation surface, installed `scripts/` / `templates/` / `snippets/`, metadata schema, 또는 smoke contract 가 바뀔 때에만 갱신한다. 그 외의 docs 변경은 INSTALL.md 를 건드리지 않는다.

## 1. Prerequisites

install 을 시작하기 전 호스트 환경에 다음이 갖춰져 있어야 한다.

- **Claude Code.** install 의 operator 는 Claude Code (CLI / desktop / web / IDE extension 어느 채널이든) 다. 본 도구에는 system-wide CLI 도 productized installer 도 없다.
- **git.** source acquisition 에 사용된다. `git --version` 이 정상 동작해야 한다.
- **PowerShell.** install / update 시 호출되는 script 가 PowerShell (Windows PowerShell 5.1 또는 PowerShell 7+) 로 작성되어 있다. 본 도구는 PowerShell 환경을 가정한다.
- **`%USERPROFILE%\.claude\` 의 사용자 read / write 권한.** materialized runtime ToolRoot 가 이 경로 아래에 만들어진다.
- **(GitHub URL 사용 시) repo 접근 권한.** repo 가 public 이면 별도 credential 이 필요 없고, private 이면 호스트의 git credential 이 해당 repo 를 clone 할 수 있어야 한다.

위 어느 항목이 충족되지 않으면 install 을 시작하지 않는다 — Claude Code 가 inspect 단계에서 결손을 보고하고 멈춘다.

## 2. What "install" produces

install 의 결과는 **global Claude install layer 안의 deterministic runtime payload** 와 그것에 정합 binding 된 metadata / integrity artifact 들이다. 같은 install area (`%USERPROFILE%\.claude\ai-harness-toolset\`) 아래에 다음 항목이 생성 / 갱신된다.

- **runtime payload directory** — `%USERPROFILE%\.claude\ai-harness-toolset\current\` 아래에 `config/` / `scripts/` / `snippets/` / `templates/` 의 deterministic overwrite materialization.
- **install metadata** — `current/` 와 sibling 위치의 `install.json`. install / update / restore 의 source / ref / SHA / 시각 정보를 기록한다.
- **payload integrity manifest** — `current/` 와 sibling 위치의 `payload-manifest.json`. payload 의 모든 regular file 에 대한 `{ path, size, sha256 }` 목록 + `head` (source HEAD SHA) 를 기록한다.
- **payload completeness marker** — `current/` 와 sibling 위치의 `payload-marker.json`. presence flag + integrity binding. marker 의 `head` 는 manifest 의 `head` 및 `install.json.lastUpdatedHead` 와 일치해야 한다 (`installedHead` 가 아니다 — 아래 cross-binding 문단 참조).
- **managed root README (operator landing page)** — install area root 의 `README.md` (`current/` 의 sibling). 위 4-artifact cross-binding 과는 **별개의 managed root artifact** 이며, in-payload template (`current/templates/install-root/AI_HARNESS_TOOLSET_ROOT_README.md`) 의 byte-identical 복사본이다 (verify 가 그 byte-identity 를 검사한다 — unmanaged/orphan 파일이 아니다). 정상 install / payload-rewrite update-source 의 **canonical output** 이며 self-healing 대상이 아니다 — missing / stale / corrupt 는 install integrity failure 로서 §9 의 reinstall-first deterministic overwrite 로 회복한다 (no-op self-heal 아님). 이것은 full operative source contract 가 아니라 **operator landing page** 이며, full contract 는 update 시 재채택하는 latest source clone 의 `INSTALL.md` 다. 자세한 contract 는 §7.3.

위 네 항목 (`current/` + 세 sibling 파일) 은 **base payload install phase 의 persistent canonical output** 이다 — operational install (§2A) 의 phase 1 결과이며, 사용자-facing "설치해줘" 의 **최종 완료 상태가 아니다.** base payload install phase 자체의 success criterion 은 이 runtime payload + metadata / integrity artifacts 의 정합 상태이고, 그 위에서 operational install 은 §2A 의 staged activation / smoke / cleanup phase 까지 진행해 실제 운용 가능 상태에 도달한다. GitHub URL 을 source 로 쓰는 install / update / reinstall 의 경우 acquisition 단계에서 `git clone` 이 사용할 임시 work area 가 필요하지만 — 본 도구는 그것을 **run-scoped temporary work area** 로 운영한다 (action 사이에 persistent cache 가 보존되지 않으므로 `git fetch` 는 정상 lifecycle 에서 호출하지 않는다). 즉 (a) operator 는 임의의 폴더에 조용히 clone 하지 않는다. propose 단계에서 사용할 temporary work area path 와 acquisition 완료 후의 cleanup 계획을 함께 사용자에게 보고한다. (b) install / update / reinstall 이 성공하여 destination payload + metadata / integrity artifacts 가 정합 상태로 닫히면 operator 는 그 temporary work area 를 제거한다. (c) cleanup 자체가 실패해도 installed payload identity 의 실패는 아니다 — destination 의 정합 상태가 install 의 success criterion 이다. 다만 operator 는 cleanup 이 끝나지 않은 leftover path 를 사용자에게 보고하고, 정리 진행 여부에 대한 명시적 승인을 받는다. 따라서 temporary work area 는 어느 install 동작에서도 persistent canonical sibling 으로 남지 않는다. local clone path source 는 임시 work area 없이 사용자가 가진 기존 clone path 를 그대로 source 로 사용하므로 본 policy 의 propose / cleanup 단계가 적용되지 않는다 (사용자의 기존 clone path 는 operator 가 정리할 대상이 아니다). 어느 source input 이든 base payload install phase 의 success criterion 은 runtime payload 와 metadata / integrity artifacts 의 정합이지 source clone / cache 의 존재가 아니다 (operational install 전체의 완료 조건은 §2A).

위 네 destination artifact 들 사이에는 cross-binding 이 있다. install / update / reinstall 후 verify 단계에서 `payload-manifest.json.head` == `payload-marker.json.head` == `install.json.lastUpdatedHead` 가 검증된다 — manifest 와 marker 의 `head` 는 항상 metadata 의 `lastUpdatedHead` (= 가장 최근에 적용된 source SHA) 에 binding 된다. `install.json.installedHead` 는 **최초 install 시점의 source SHA 를 보존하는 history field** 이며 update / restore 후에도 그대로 유지된다 (즉 fresh install 직후에만 `installedHead == lastUpdatedHead` 이고, update / restore 후에는 두 값이 다를 수 있다). 또한 manifest 의 각 file 의 size / SHA-256 이 `current/` 의 실제 파일과 일치해야 한다.

target project 안에는 ai-harness payload 를 두지 않는다. target project 의 persistent footprint 는 `<ProjectRoot>/log/` 아래의 runtime artifact (BRIEF / Evidence / Review) 뿐이다.

## 2A. Operational install — 사용자-facing "설치해줘" 의 기본 완료 조건

사용자가 "설치해줘" 라고 말할 때의 기본 완료 조건은 **operational install** — 실제로 toolset 을 운용할 수 있는 상태 — 이다. §2 의 base payload install (`current/` + 세 sibling 파일) 은 operational install 의 **내부 phase (phase 1)** 이며 그 자체로 최종 완료가 아니다. payload 가 materialize 되었다는 사실만으로 install 을 "끝났다" 고 보고 payload phase 에서 멈추지 않는다.

**plain "설치해줘" (별도 customization 요청 없음) 의 default plan 은 full operational install** 이며, 다음 phase 흐름 전체를 포함한다. operator 는 발생할 global / user mutation 의 **전체 목록**을 inspect 해서 사용자에게 한 번에 설명한 뒤, 그 full plan 에 대해 **단 하나의 yes/no 승인**을 받는다 (아래 "Default install UX"). 사용자가 승인하면 operator 는 payload phase 에서 임의로 멈추지 말고 approved full operational install flow 를 끝까지 수행한다 — phase 마다 다시 묻지 않으며, 어느 surface 를 설치할지 사용자에게 고르게 하지 않는다.

1. **base payload install** — `%USERPROFILE%\.claude\ai-harness-toolset\` 아래에 §2 의 네 항목 (`current/` + `install.json` + `payload-manifest.json` + `payload-marker.json`) 을 materialize 한다 (§4–§9 의 install model 본체).
2. **activation apply** — 실제 운용에 필요한 **global / user integration surface** 를 적용한다. operational install 의 activation 은 §2 footprint 규칙 (target project 의 persistent footprint = `<ProjectRoot>/log/` only) 과 정합하도록 **global / user 영역의 surface 만** 대상으로 한다. default plan 은 아래 surface 들을 **모두** 포함하며 (skill adoption 은 각 source skill 당 하나의 mirror — 현재 ship 되는 것은 `ai-harness-review` 와 `ai-harness-brief` 둘 — 둘 다 source skill 이므로 동일하게 mirror·verify 대상), phase 1 / 3 / 4 / 5 와 함께 하나의 full operational install plan 으로 묶여 단일 yes/no 로 승인된다 (아래 "Default install UX"). operator 는 사용자에게 어느 surface 를 설치할지 고르게 묻지 않는다.
   - **Claude integration** — `snippets/CLAUDE_SNIPPET.md` 의 managed block 을 user-global `%USERPROFILE%\.claude\CLAUDE.md` 에 insert / replace (§10 의 managed-block apply 규칙).
   - **Codex integration** — `snippets/AGENTS_SNIPPET.md` 의 managed block 을 Codex user-global `%USERPROFILE%\.codex\AGENTS.md` (또는 `%CODEX_HOME%\AGENTS.md` / 그 scope 의 `AGENTS.override.md`) 에 insert / replace (§10 의 managed-block apply 규칙). `%USERPROFILE%\.claude\AGENTS.md` 는 어느 경우에도 destination 이 아니다.
   - **Claude skill adoption** — 각 source skill `snippets/claude-skills/<name>/SKILL.md` 를 user-global `%USERPROFILE%\.claude\skills\<name>\SKILL.md` 로 install / update (현재 ship: `ai-harness-review` + `ai-harness-brief` 둘; §10 의 skill adoption 규칙).

   project-root `CLAUDE.md` / `AGENTS.md` 의 managed-block 이나 project-local `<ProjectRoot>/.claude/skills/...` 채택은 operational install 의 phase 가 **아니다** — 이는 target project 별로 사용자가 선택하는 **project-specific adoption** 이며, §2 footprint 규칙 (target 은 `log/` only) 과 §10 의 target adoption 분리에 따라 operational install (global / user 영역) 과 별개의 explicit user-approved 동작으로 처리한다. (project-root 포함 destination 전체의 marker 규칙은 §10 의 managed-block apply 규칙이 정의한다.)
3. **verification** — base payload 의 §5 verify (14-field schema + manifest + marker + cross-binding) 에 더해, 적용된 activation surface 의 verify: managed-block 은 marker pair 가 정확히 1 개 정합하고 block 내용이 적용된 snippet 과 일치하는지, skill 은 destination `SKILL.md` 가 존재하고 content 가 source 와 일치하는지 (§10 의 activation 규칙이 정의).
4. **operational smoke** — usable state 를 증명하는 minimal smoke. source repo 가 아닌 **별도의 throwaway target smoke workspace** 에서 두 가지를 확인한다. (a) **ToolRoot channel-3 resolution** — `brief-init.ps1` 을 `-ToolRoot` 인자 / `AI_HARNESS_TOOL_ROOT` 없이 실행해, seed 된 `<workspace>/log/brief/BRIEF.md` 가 channel 3 (`%USERPROFILE%\.claude\ai-harness-toolset\current\templates\brief\BRIEF.md`) 의 template 과 byte-identical (SHA-256 일치) 한지로 channel 3 resolution 을 증명한다. (b) **runtime artifact 격리** — 위 `brief-init.ps1` 이 그 workspace 의 `log/` 아래 (`log/brief/`) 에만 runtime artifact 를 쓰고 source repo / global `current/` payload 를 mutate 하지 않는지 확인한다. operational install 의 완료에 필요한 smoke 는 위 (a) + (b) 가 전부다. 더 광범위한 clean-target smoke suite 는 본 minimal smoke 와 별개인 future scoped work 이며 install 실행에 필요하지 않다.
5. **acquisition / work directory cleanup** — GitHub URL source 의 run-scoped temporary work area (§2) 와 smoke workspace 등 acquisition / 작업 디렉터리를 정리한다. cleanup 의 성공 / 실패는 보고에 포함하되, cleanup 실패가 installed payload identity 의 실패는 아니다 (§9). 또한 operator 가 INSTALL.md 를 읽거나 진입점을 실행하려고 script **밖에서** 먼저 만든 **bootstrap / source clone** 도 성공 경로에서는 묻지 않고 자동 삭제한다 — 이는 script 가 정리하는 run-scoped work area 와 구분되는 **operator workflow cleanup** 이며, 그 규칙은 §6.1 "Operator bootstrap clone cleanup 규칙 (fresh install)" (= §7.1 update 규칙과 동일 discipline) 이 정의한다.

### Default install UX — full operational install 을 하나의 yes/no 로 승인

plain "설치해줘" (또는 동등한 install 의도) 에 대한 default 는 위 5 phase 전체 (base payload + Claude managed-block + Codex managed-block + 각 source skill mirror + activation verify + operational smoke + cleanup) 를 수행하는 **full operational install** 이다. 보통 사용자에게 노출되는 install UX 는 다음과 같다.

1. operator 는 발생할 **global / user mutation 전체 목록**을 inspect 해서 사용자에게 한 번에 설명한다 — 최소한 다음을 묶어서 보여준다.
   - base payload → `%USERPROFILE%\.claude\ai-harness-toolset\` (`current/` + `install.json` + `payload-manifest.json` + `payload-marker.json`).
   - Claude managed-block → user-global `%USERPROFILE%\.claude\CLAUDE.md`.
   - Codex managed-block → Codex user-global `%USERPROFILE%\.codex\AGENTS.md` (또는 `%CODEX_HOME%\AGENTS.md` / `AGENTS.override.md`).
   - 각 source skill mirror → user-global `%USERPROFILE%\.claude\skills\<name>\SKILL.md` (현재 ship: `ai-harness-review` + `ai-harness-brief` 둘).
   - 그리고 이어질 activation verify / operational smoke (throwaway workspace) / acquisition·work cleanup.
2. operator 는 **단 하나의 승인 질문**만 하고, 그 approval surface 는 **정확히 두 응답 (`yes` / `no`) 만** 받는다 (canonical 문구):
   > 위 global/user 변경을 적용해서 ai-harness-toolset 설치를 완료할까요? yes/no

   이 approval 질문에는 menu / checkbox / multi-select / numbered option list 를 붙이지 않으며, `yes` 와 `no` 외의 어떤 선택지 label 도 approval surface 에 노출하지 않는다 — 구체적으로 `"yes — 전체 설치"`, `"base payload만"` / `"base payload only"`, `"전체 설치"`, `"custom"`, `"partial"`, `"Type something"`, `"Chat about this"`, 그 밖의 제3 옵션을 포함하지 않는다. 선택지를 강제하는 UI 라면 허용되는 선택지는 **정확히 `yes` 와 `no` 둘뿐**이다 (설치 범위에 대한 설명은 step 1 에서 이미 텍스트로 제시했으므로 approval 은 그 full plan 에 대한 단일 yes/no 다).
3. 사용자가 `yes` / `proceed` / `진행해` 등 명시적 진행 의도를 표시하면 — 그 단일 승인이 위 full plan 전체에 대한 explicit approval 이다 — operator 는 approved full operational install flow 를 끝까지 수행한다. phase 마다, surface 마다 다시 묻지 않는다.
4. 사용자가 `no` 또는 모호한 응답을 하면 어떤 mutation 도 수행하지 않고 중단한다.

**금지 (default path).** 어느 surface 를 설치할지 고르는 checkbox / menu / multi-select, "activation surface 를 선택하세요", "base payload 만 설치할까요" 같은 선택지를 default install 에서 제시하지 않는다. Claude / Codex / skill 중 무엇을 적용할지 사용자에게 고르게 하지 않는다.

**Custom / partial install.** 사용자가 **승인 질문 전에 스스로 명시적으로** customization 을 요청한 경우에만 부분 설치를 한다 — 예: "Codex 는 제외", "skill 은 나중에", "base payload 만". 그 경우 operator 는 요청된 범위로 plan 을 좁혀, 동일하게 그 좁힌 plan 의 전체 mutation 목록을 설명하고 (역시) 단일 `yes` / `no` 승인을 받는다. custom / partial 경로는 **approval 질문의 선택지로 광고하거나 노출하지 않는다** — 사용자가 먼저 요청하지 않는 한 default approval surface 에는 등장하지 않는다. **"base payload only" 는 troubleshooting / deferred 모드이지 default install 선택지가 아니며**, default install 의 approval UI 에 절대 나타나지 않는다 — 사용자가 명시적으로 요청할 때만 사용한다.

각 global / user mutation 이 explicit user approval 을 요구한다는 boundary (§10) 는 그대로 유지된다. 다만 default install 에서 그 승인은 full operational install plan 에 대한 **하나의 yes/no** 로 수집되며, 사용자가 customization 을 명시적으로 요청하지 않는 한 surface 별로 쪼개 묻지 않는다.

### mutation boundary (operational install 의 세 영역)

operational install 은 서로 다른 세 mutation 영역을 명확히 구분한다.

- **source repo** (`<ToolRoot>` / source clone) — **read-only.** install / activation / smoke 어느 phase 도 source repo working tree 를 mutate 하지 않는다. URL source input 이면 git-url mode 를 유지하며, inspect / acquisition clone 은 §3.2 대로 source identity 가 아니다.
- **global install layer** (`%USERPROFILE%\.claude\` — Codex integration 의 경우 `%USERPROFILE%\.codex\`) — operational install 의 **mutation target.** base payload + activation surface 가 이 영역에 만들어지며, 모든 write 는 §10 의 explicit user-approved global / user filesystem mutation scope 다.
- **target smoke workspace** — operational smoke 가 사용하는 **별도의 throwaway project 디렉터리.** source repo 도 global install layer 도 아니며, smoke 의 runtime artifact 는 이 workspace 의 `<ProjectRoot>/log/` 아래에만 생성된다. smoke 종료 후 cleanup phase (phase 5) 가 정리한다.

### operational install 에 포함되는 것 / 포함되지 않는 것

- **포함 (operational install completion phase):** base payload install, activation apply (Claude / Codex managed-block, skill adoption), verification, operational smoke, cleanup. managed-block / skill adoption / smoke 는 install 과 무관한 별도 future work 가 **아니라** operational install completion flow 의 staged activation / verification phase 다. 각 global / user mutation 이 explicit user approval 을 요구한다는 boundary (§10) 는 유지되지만, default install 에서 그 승인은 full operational install plan 에 대한 **하나의 yes/no** 로 수집된다 (위 "Default install UX") — surface 별 multi-select 가 아니다.
- **불포함 (out-of-scope future work — §11):** productized installer / bootstrap wrapper, recovery / doctor / repair framework, daemon / watcher / scheduler, 그리고 **승인 없이 자동으로** 이뤄지는 global mutation / managed-block apply / skill refresh / target update / commit / push. 즉 out-of-scope 인 것은 activation 자체가 아니라 그것의 *자동 (무승인)* 적용과 productization 이다.

## 3. Supported source inputs

install 의 source 입력은 두 가지 형태를 동등하게 지원한다. 어느 쪽을 쓰더라도 (5) destination, (6) install identity, (7) flow, (8) failure handling 의 model 은 같다.

- **GitHub repo URL.** 예: `https://github.com/yunsuck5/ai-harness-toolset`. operator 가 URL 만 가지고 있을 때 사용한다. install 시 Claude Code 가 그 URL 을 source 로 `git clone` 한다.
- **Local clone path.** 예: `<local-clone>` (이미 clone 해 둔 `ai-harness-toolset` source repo 의 local path). operator 가 이미 clone 한 source repo 위에서 시작할 때 사용한다. clone 단계 없이 그 path 를 source 로 사용한다.

두 source input 의 유일한 차이는 source acquisition 단계 — `git clone` 이 필요한가, 아니면 기존 clone 을 그대로 사용하는가 — 뿐이다.

### 3.1 Source input 이 install mode 를 결정한다 (모호한 재-offer 금지)

install mode (`installMode`) 는 operator 의 자유 선택이 아니라 **사용자가 실제로 제공한 source input 의 형태** 가 결정한다. operator 는 두 mode 를 매번 나란히 제시하지 않는다.

- **사용자가 GitHub URL 을 제공하면 `git-url` 이 default 이자 유일하게 제시되는 mode 다.** URL input 에 대해 `local-clone` mode 를 함께 offer 하지 않는다. URL 하나만 주어진 상황에서 "git-url 로 할까요, local clone 으로 할까요" 식의 양자택일을 제시하는 것은 본 계약 위반이다 — `git-url` 로 진행한다.
- **`local-clone` mode 는 사용자가 명시적으로 local clone path 를 source 로 제공했을 때 (또는 "이 local path 를 source 로 써" 라고 명시적으로 지시했을 때) 에만 유효하다.** 사용자가 URL 만 준 경우 operator 가 임의로 local-clone 으로 전환하지 않는다.
- 사용자가 URL 을 준 뒤 별도로 "그 URL 대신 이 local clone path 를 source 로 써" 라고 **명시적으로** 바꾸면 그때 `local-clone` 으로 전환한다. 그 명시 지시 없이는 URL → `git-url` 이 고정이다.

### 3.2 Inspect / acquisition clone 은 source input 이 아니다

operator 가 INSTALL.md 를 읽기 위해서, 또는 payload 를 materialize 하기 위해서 만든 임의의 clone / 작업 사본은 §2 의 **run-scoped temporary work area** 일 뿐이며, source input 도 persistent source identity 도 아니다.

- 그런 inspect / acquisition clone 의 path 를 `local-clone` source 로 재해석하거나 사용자에게 "이미 여기 clone 이 있으니 local-clone 으로 설치할까요" 식으로 다시 제시하지 않는다. URL 로 시작한 install 은 inspect clone 이 디스크에 존재한다는 사실만으로 `local-clone` 후보가 되지 않는다.
- 그 work area 의 path 는 `install.json` 의 `sourcePath` 에도 `toolRoot` 에도 기록되지 않는다. `git-url` mode 의 `install.json.sourcePath` 와 `install.json.toolRoot` 는 §4 대로 항상 empty (`''`) 다 — work area 가 transient 이고 persistent identity 가 아니기 때문이다.
- 성공한 URL install 은 verify 가 정합 상태로 닫힌 뒤 §2 policy 에 따라 그 work area / acquisition clone 을 제거한다. cleanup 의 성공 / 실패는 verify 보고에 포함하되, work area 의 존재 여부는 install identity 의 success criterion 이 아니다. operator 가 만든 bootstrap / acquisition clone 의 제거는 **성공 경로에서 사용자에게 묻지 않고 자동 수행** 한다 (§6.1 "Operator bootstrap clone cleanup 규칙 (fresh install)") — 삭제 여부를 묻는 것은 cleanup contract 위반이다. 삭제가 실패하면 install 은 **success with cleanup leftover** 로 분류하고 exact path + 이유를 보고하되 full lifecycle closeout 으로 보고하지 않는다.

## 4. Install model — the same for both source inputs

source input 이 무엇이든 install 은 다음 단일 model 을 따른다.

- **Destination.** runtime payload 의 자리는 `%USERPROFILE%\.claude\ai-harness-toolset\current\` (sibling `install.json` 포함) 다. 어느 source 도 다른 destination 으로 가지 않는다.
- **Install identity.** install 의 identity 는 **resolved commit SHA** 다. URL / path / branch / remote 는 source dispatch hint 일 뿐이다.

  > **URL이나 local path가 같아도 현재 installed payload / version identity는 resolved commit SHA로 판단한다.**

  즉 같은 URL / 같은 path 라도 두 시점은 별개의 installed content identity 이며, "이미 같은 source 가 install 되어 있다" 만으로 update 가 불필요하다고 결론짓지 않는다.

- **Posture.** install / update / reinstall 은 **deterministic overwrite materialization** 이다. destination 의 diff 를 분석해서 patch 하지 않으며, partial merge 도 하지 않는다. source 의 resolved SHA 기준으로 destination payload 를 통째로 deterministic 하게 다시 만든다.
- **Metadata + integrity artifacts.** install 의 결과는 sibling `install.json` (mode-conditional source-identity field 들 + SHA 기반 history) 외에 sibling `payload-manifest.json` (per-file SHA-256 manifest + `head`) 과 sibling `payload-marker.json` (presence flag + integrity binding, `head` 와 `manifestPath` 포함) 으로 함께 기록된다. `install.json` 은 **단일 `source` field 가 아니라 14-field mode-conditional schema** 다 — source 종류 (GitHub URL / local clone path) 는 `installMode` 가 dispatch 하며, mode-별 source-identity field (`repoUrl` 또는 `sourcePath`, 그리고 `toolRoot`) 가 분기되어 기록된다. core source-identity / history field 6 개의 의미는 다음과 같다. (a) `installMode` — `git-url` 또는 `local-clone` 의 source type dispatch (어느 mode-conditional source-identity field 가 채워지는지를 결정한다). (b) `repoUrl` — `installMode == git-url` 일 때 operator 가 제공한 source URL 을 그대로 보존 (재획득 / 재준비 힌트; `local-clone` 일 때는 empty). (c) `sourcePath` — `installMode == local-clone` 일 때 operator 가 제공한 local clone path 를 그대로 보존 (재획득 / 재준비 힌트; `git-url` 일 때는 empty). (d) `toolRoot` — `installMode == local-clone` 일 때는 사용된 source path 의 identity hint 로 non-empty 이고, `installMode == git-url` 일 때는 source acquisition 이 §2 의 run-scoped temporary work area 안의 fresh clone 으로 이뤄지고 그 work area 가 persistent identity 가 아니므로 의도적으로 empty 다. (e) `installedHead` — 최초 install 시점의 resolved commit SHA history field. (f) `lastUpdatedHead` — 현재 installed content identity (가장 최근에 materialize 된 resolved commit SHA). 나머지 8 field 는 `schemaVersion` (현재 `1`; unknown 은 fail-fast — silent downgrade 금지), `tool` (도구 식별자, 현재 `ai-harness-toolset`), `branch` (추적 branch), `remote` (git remote 이름), `installedAt` (최초 install UTC 시각 history), `lastUpdatedAt` (가장 최근 materialize UTC 시각), `targetFootprintPolicy` (현재 `log-only`), `managedBy` (현재 `claude-code`) 로 — 합쳐서 총 14-field set 을 구성한다. source string 자체는 어느 mode 든 재획득 / 재준비 힌트일 뿐 installed payload identity 가 아니다 (identity 는 `lastUpdatedHead` 의 resolved commit SHA 다); 두 mode 의 source-identity field 는 단일 `source` field 로 합치지 않고 mode-conditional 하게 분기되어 기록된다. cross-binding rule 은 `payload-manifest.json.head` == `payload-marker.json.head` == `install.json.lastUpdatedHead` 다 — manifest / marker 의 `head` 는 항상 `lastUpdatedHead` 에 binding 된다. `installedHead` 는 history field 이므로 update / restore 후에는 `lastUpdatedHead` 와 다를 수 있고, 이 divergence 자체는 정상 상태다 (manifest / marker 가 `lastUpdatedHead` 와 일치하면 정합). 본 cross-binding 은 verify 단계에서 검사된다 — §5. 어느 artifact 라도 schema mismatch / 부재 / corrupt / head mismatch / file digest mismatch 인 경우의 처리는 §9 failure handling 을 따른다.
- **Flow.** install / update / reinstall 어떤 action 이든 operator 가 (5) 의 5 단계를 거친다.

## 5. The five-step flow — inspect → propose → explicit approval → apply → verify

본 도구의 install / update / reinstall 은 항상 다음 다섯 단계를 거친다. 어느 단계도 trigger 한 줄로 자동 진행되지 않는다.

1. **Inspect.** operator 는 현재 호스트 상태를 확인한다 — Claude Code / git / PowerShell 가용 여부, `%USERPROFILE%\.claude\ai-harness-toolset\current\` 의 존재 여부, sibling `install.json` 의 존재 / schema / 내용, source repo (URL clone 위치 또는 local clone path) 의 유효성, source 의 현재 HEAD SHA.
2. **Propose.** operator 는 적용 예정 변경을 사용자에게 명시한다 — fresh install 인가 / update 인가 / reinstall 인가, source 의 어떤 SHA 를 사용할 것인가, destination 의 어떤 path 가 overwrite 되는가, `install.json` 의 어느 field 가 어떻게 갱신되는가. default "설치해줘" (full operational install) 의 경우 propose 는 base payload 변경만이 아니라 §2A "Default install UX" 의 global / user mutation **전체 목록**을 한 번에 제시한다 — surface 별로 나눠 묻지 않는다.
3. **Explicit approval.** 사용자가 명시적으로 `yes` / `proceed` / `진행해` 의 의도를 표시해야 한다. 모호한 응답은 진행 사유로 해석하지 않는다. default operational install 에서는 이 단일 승인이 §2A 의 full plan 전체 (모든 activation surface 포함) 를 cover 하며, surface 별로 따로 승인을 받지 않는다.
4. **Apply.** 승인된 범위만 destination 에 적용한다. apply 의 본체는 deterministic overwrite materialization (`current/` 를 source 의 resolved SHA 기준으로 다시 작성) + `install.json` 갱신이다.
5. **Verify.** apply 직후 operator 는 결과를 보고한다. 구체적으로 (a) `install.json` 의 §4 14-field schema 가 유효한지 — `schemaVersion` 이 reader 가 지원하는 값인가, `installMode` 가 `git-url` / `local-clone` 중 하나인가, mode-conditional source-identity field (`installMode == git-url` 이면 `repoUrl` non-empty + `sourcePath` empty, `installMode == local-clone` 이면 `sourcePath` non-empty + `repoUrl` empty) 가 충족되는가, `toolRoot` 가 `local-clone` 에서 non-empty / `git-url` 에서 empty 인가, `installedHead` / `lastUpdatedHead` 가 모두 non-empty resolved SHA 인가, `tool` / `targetFootprintPolicy` / `managedBy` 가 정해진 상수값 (`ai-harness-toolset` / `log-only` / `claude-code`) 인가 등, (b) `payload-manifest.json` 이 존재하고 `current/<payloadRoots>/**` 의 실제 파일 size / SHA-256 과 모두 일치하는지, (c) `payload-marker.json` 이 존재하고 `manifestPath` / `payloadRoots` constant 가 맞는지, (d) cross-binding `payload-manifest.json.head` == `payload-marker.json.head` == `install.json.lastUpdatedHead` 가 일치하는지 (`installedHead` 는 binding 대상이 아니다 — update / restore 후에는 `lastUpdatedHead` 와 다를 수 있는 history field 다) 를 확인한다. 본 §5 verify 는 base payload phase 의 검증이며, operational install (§2A) 에서는 이어서 activation apply (managed-block / skill) → activation verify → operational smoke → cleanup phase 가 따른다 — operator 는 §2A "Default install UX" 의 단일 yes/no 로 이미 승인된 full operational install plan 의 나머지 phase 를 이어서 수행하고 payload 단계에서 멈추지 않는다 (phase 마다 다시 승인을 묻지 않는다). commit / push 같은 작업은 operational install 의 phase 가 아니며 별도 사용자 결정이다. 어느 경우든 base payload verify 의 결과 자체가 후속 phase 나 후속 작업을 자동 승인하지는 않는다.

### 5.1 Operator verification discipline — canonical helper 우선

install / update / reinstall 후 검증의 판정 근거는 위 §5 verify (base payload 의 14-field schema + manifest + marker + cross-binding) 와 §2A activation verify 다. operator 가 추가로 ad-hoc 점검을 하더라도 그것이 canonical 판정을 대체하지 않는다. 다음 discipline 을 따른다.

**install-pipeline 의 CLI surface 는 fixture / test harness 다 (production global installer 가 아니다).** install / update / restore deterministic core contract — resolver tuple → materialization → install metadata / `payload-manifest.json` / `payload-marker.json` write → verify — 의 회귀를 보호하는 **fixture-only deterministic core validation entry** 는 `tests/support/install-pipeline-fixture.ps1` 에 위치한다 (구버전의 `scripts/install-pipeline.ps1` 에서 동일 코드가 이동했고, path 와 이름이 fixture 역할을 self-document 한다). 본 entry 의 `Assert-NotForbiddenInstallArea` guard 가 `-InstallArea` 가 `%USERPROFILE%\.claude` / `%USERPROFILE%\.codex` 또는 그 descendants (특히 global stable install area `%USERPROFILE%\.claude\ai-harness-toolset\`) 와 일치하거나 그 아래일 때 fail-fast 거부하므로 — 본 CLI 로는 actual global / user filesystem apply 를 수행할 수 없다 (구조적 boundary). 실제 global / user filesystem apply — `%USERPROFILE%\.claude\ai-harness-toolset\current\` materialize / refresh, sibling install metadata / `payload-manifest.json` / `payload-marker.json` write, managed-block apply, Claude skill install / update / removal — 는 §10 의 explicit user-approved scope 위에서 **AI-guided global apply** 절차 (`docs/systems/install-update/STEP3_INSTALL_UPDATE_DECISION_GUIDE.md` §19.4) 로 수행되며, 본 CLI 가 그 apply 를 묶음으로 자동 수행하지 않는다 (§11 out-of-scope, productized installer / one-liner wrapper 미도입). production 영역에서 verify 호출은 `scripts/lib/install-pipeline-core.ps1` 의 `Invoke-InstallPipelineVerify` 함수 (canonical library helper) 를 직접 사용한다 — 아래 첫 bullet 이 그 verify helper 의 우선 사용을 가리킨다.

- **canonical CLI / repo helper 우선.** 검증은 `scripts/lib/install-pipeline-core.ps1` 의 verify 함수 (`Invoke-InstallPipelineVerify`), managed-block 비교는 `scripts/lib/managed-block.ps1` 의 marker-bounded 추출, git 호출은 `scripts/lib/git.ps1` 의 capture helper 를 우선 사용한다. 즉석에서 작성한 점검은 보조 수단일 뿐이며, canonical helper result 와 충돌하면 신뢰 근거가 되지 않는다.
- **managed-block boundary 는 standalone line marker 기준이다.** managed block 의 경계는 자체 줄에 단독으로 있는 `<!-- BEGIN AI_HARNESS_TOOLSET_GLOBAL -->` / `<!-- END AI_HARNESS_TOOLSET_GLOBAL -->` 두 줄뿐이다 (§10 의 Managed-block apply 규칙). inline code / prose 안에 인용된 동일 텍스트나 fenced code block 안의 동일 텍스트는 boundary 로 세지 않는다. 단순 substring / `IndexOf` 비교는 본문에 인용된 marker 문자열에 걸려 false negative 를 낼 수 있으므로, 경계 판정에는 항상 §10 의 Managed-block apply 규칙이 정한 whole-line trim 매칭 (standalone line marker extraction) 을 쓴다.
- **raw git stderr progress 만으로 실패 판정하지 않는다.** `git clone` / `git fetch` / `git log` 는 progress 를 stderr 로 쓰며, 그 출력이 빨갛게 보여도 그 자체가 실패가 아니다. 성공 / 실패는 git 의 exit code, helper 의 capture result, 그리고 후속 verify 로 판정한다 (`scripts/lib/git.ps1` 의 capture helper 는 stderr 를 분리해 둔다).
- **PowerShell inline verification 의 `$LASTEXITCODE` unset artifact.** native command 를 돌리지 않은 PowerShell-only 검증을 inline 으로 실행하면, harness 의 exit-code probe 가 미설정 `$LASTEXITCODE` 를 읽어 "Exit code 1" / "cannot be retrieved because it has not been set" 처럼 보일 수 있다. 이는 wrapper artifact 이며 검증 결과가 아니다 — 판정은 canonical verify result (`ok = True`) 와 cross-binding (`payload-manifest.json.head` == `payload-marker.json.head` == `install.json.lastUpdatedHead`) 을 우선한다.
- **충돌 시 재검증.** ad-hoc 점검 결과가 canonical helper result 와 충돌하면, canonical helper (verify / managed-block 추출) 또는 §10 Managed-block apply 규칙의 standalone marker extraction 으로 다시 검증하고 그 canonical 결과를 판정으로 채택한다.

본 §5.1 은 install / update 의 PASS 판정을 뒤집는 규칙이 **아니다.** 위와 같은 관찰 (git stderr 색, `$LASTEXITCODE` 메시지, inline marker 에 걸린 substring 비교 등) 은 repo-owned defect 가 아니라 검증 절차의 표시 / 방법 문제이며, 본 절은 그 표시에 속지 않도록 하는 **operator-side verification discipline 보강**일 뿐이다. canonical verify 가 정합 (`ok = True` + cross-binding 일치) 이면 install / update 는 PASS 다.

## 6. Fresh install procedure

호스트에 ai-harness install 이 아직 없는 경우 (또는 `current/` + `install.json` 이 모두 부재인 경우) 의 절차다. 본 절은 operational install 의 **base payload phase (phase 1)** 를 상세화한다. default "설치해줘" 에서는 §2A "Default install UX" 가 overall propose + 단일 yes/no 승인을 관장하며, 그 하나의 승인이 본 절의 base payload 와 이어지는 activation / smoke / cleanup 까지 한꺼번에 cover 한다 — 아래 step 4 의 "사용자 승인" 은 그 단일 승인을 가리키며, base payload 만을 위한 별도 승인이 아니다.

1. operator 는 Claude Code 안에서 의도를 사용자에게 표시한다. 이때 mode 는 §3.1 대로 **사용자가 제공한 source input 의 형태가 결정** 하며, operator 가 두 mode 를 양자택일로 제시하지 않는다.
   - 사용자가 GitHub URL 을 제공한 경우 → `git-url`: 예 — "이 URL 로 ai-harness-toolset 을 설치한다 (`git-url` mode): `https://github.com/yunsuck5/ai-harness-toolset`." (URL 만 주어졌을 때 `local-clone` 을 함께 묻지 않는다.)
   - 사용자가 local clone path 를 명시적으로 source 로 제공한 경우 → `local-clone`: 예 — "이 local clone 을 source 로 설치한다 (`local-clone` mode): `<local-clone>`."
2. operator 는 §5 inspect 를 수행한다. prerequisites 점검 + destination 부재 확인 + source 의 현재 HEAD SHA resolve.
3. operator 는 §5 propose 를 수행한다. propose 에는 다음이 포함된다.
   - source input 종류 (URL / local path) 와 값.
   - 사용할 ref 와 그 resolved SHA.
   - 생성될 destination path (`%USERPROFILE%\.claude\ai-harness-toolset\current\`).
   - 작성될 `install.json` 의 핵심 값 — `installMode` (`git-url` 또는 `local-clone`), mode-conditional source-identity field (`installMode == git-url` 일 때 `repoUrl` 에 operator 가 제공한 URL 보존, `sourcePath` 는 empty; `installMode == local-clone` 일 때 `sourcePath` 에 operator 가 제공한 local clone path 보존, `repoUrl` 은 empty), `toolRoot` (`local-clone` 이면 그 source path 의 identity hint 로 non-empty; `git-url` 이면 run-scoped temporary work area 가 persistent identity 가 아니므로 empty), `installedHead` (= resolved SHA, 최초 install 시점의 history field), `lastUpdatedHead` (= 동일 resolved SHA — fresh install 시점에는 `installedHead == lastUpdatedHead`); 나머지 field (`schemaVersion`, `tool`, `branch`, `remote`, `installedAt`, `lastUpdatedAt`, `targetFootprintPolicy`, `managedBy`) 도 함께 기록되어 §4 의 14-field schema 전체를 채운다.
   - (GitHub URL source 일 때만) §2 의 run-scoped temporary work area policy 에 따라 acquisition 에 사용할 **temporary work area 의 구체 path** 와 acquisition 종료 후의 **cleanup 계획** (성공 시 제거, cleanup 실패 시 leftover 보고). local clone path source 는 본 항목을 생략한다 — 사용자의 기존 clone path 를 그대로 source 로 사용하므로 temporary work area 가 없다.
4. 사용자가 명시적으로 승인한 경우에만 §5 apply 를 수행한다.
5. apply 직후 §5 verify 를 수행하고, 정합 상태로 닫혔으면 (GitHub URL source 일 때만) §2 policy 에 따라 temporary work area 를 제거한다. cleanup 자체의 성공 / 실패 결과는 verify 보고에 함께 포함한다.

본 단계의 어떤 부분도 자동 PATH 변경, managed-block apply (`%USERPROFILE%\.claude\CLAUDE.md` 등), Claude skill 의 자동 설치, target project 의 자동 변경을 포함하지 않는다 — 단, 위 base payload + activation / smoke / cleanup 은 §2A 의 단일 yes/no 로 승인된 plan 안에서 결정적 진입점이 수행한다 (아래 §6.1).

### 6.1 Canonical fresh-install entrypoint

base payload materialization 과 activation bootstrap 은 operator 가 library 함수를 손으로 조립하지 않는다 — `update-source` 에 §7.1.1 의 결정적 진입점이 있는 것과 대칭으로, fresh install 의 canonical source-controlled 진입점은 다음 하나다:

```text
scripts/install-global.ps1 [-InstallArea <global install area>] (-SourcePath <local clone> | -RepoUrl <url>) [-Branch <b>] [-Remote <r>] [-SkipSmoke]
```

- 기본 `-InstallArea` 는 `%USERPROFILE%\.claude\ai-harness-toolset` (install ROOT — `current/` 의 부모). source 는 `-SourcePath` (local-clone) **또는** `-RepoUrl` (git-url) 중 **정확히 하나** 다.
- **이미 install 이 있으면 fail-fast.** `-InstallArea` 에 `install.json` 이 이미 있으면 (혹은 비어 있지 않으면) install-global 은 **overwrite 하지 않고 거부** 하며 `scripts/update-global.ps1` (또는 §7.1.1 의 `install-update.ps1 -Mode update-source`) 로 안내한다 — clean-reinstall / overwrite 옵션은 본 진입점에 두지 않는다 (별도 future 결정).
- 내부적으로 canonical pipeline (`New-InstallPipelineTuple` action=`install` → `Invoke-InstallPipelineDispatch` → `Invoke-InstallPipelineVerify`) 으로 `current/` + `install.json` + `payload-manifest.json` + `payload-marker.json` + managed root `README.md` 를 materialize 하고 cross-binding 을 verify 한다.
- **activation bootstrap 까지 닫는다.** materialize 된 payload (`current/snippets/...`) 를 source 로 — Claude managed block 과 Codex managed block 을 `scripts/apply-managed-block.ps1 -Insert` 로 **first-time 삽입** (§10 "first-time insertion" 분기; 부재 → 생성, 0-pair → append, 1-pair → fail-fast 후 replace 안내) 하고, 각 source skill 의 mirror 를 canonical-overwrite 로 생성한다. 그 뒤 `scripts/install-update.ps1 -Mode verify` 가 `verify_pass` (payload + 모든 activation surface byte-identity) 에 도달하는지 최종 확인한다. optional operational smoke (§13.7 helper) 는 `-SkipSmoke` 로 끈다.
- 이로써 fresh install 이 결정적 named CLI 로 닫힌다 — operator 가 `Invoke-InstallPipelineDispatch -Action install` 를 손으로 dot-source 하거나 managed block 을 수동 삽입할 필요가 없다. 이는 본 도구가 새 productized installer framework 를 들이는 것이 **아니라**, 원래 있어야 할 결정적 fresh-install 경로를 복구하는 것이다 (§11 (b) deterministic narrow entrypoint class; 대형 installer / wizard / doctor 는 §11 (a) 그대로 out-of-scope).

##### Operator bootstrap clone cleanup 규칙 (fresh install)

fresh install 에서도 operator 가 source 를 얻기 위해 만든 clone 의 cleanup 은 §7.1 의 update 규칙과 **동일한 discipline** 을 따른다. 두 cleanup 을 구분한다.

- **두 cleanup 은 다르다.** (a) `git-url` 입력일 때 `install-global.ps1 -RepoUrl` 가 payload materialize 를 위해 내부에서 만든 **run-scoped temporary work area** 의 cleanup 은 script (install-global / 내부 pipeline) 가 스스로 수행한다 (§2A phase 5). (b) operator 가 INSTALL.md 를 읽거나 `install-global.ps1` 자체를 실행하려고 script **밖에서** 먼저 만든 **bootstrap / source clone** (예: `%USERPROFILE%` 아래의 임의 clone) 의 cleanup 은 operator workflow 책임이며 (a) 와 별개다 — `-RepoUrl` install 에서 이 bootstrap clone 은 §3.2 대로 source identity 가 아니라 transient acquisition clone 이다 (그러므로 디스크에 남아 있다는 사실만으로 `local-clone` 후보가 되지 않는다).
- **success path 자동 삭제, 묻지 않는다.** install-global 이 `installStatus=installed` / `verify_pass` / (smoke 미skip 시) smoke pass 로 닫히면 operator-created bootstrap clone 을 **자동 삭제** 한다 — 성공 경로에서 "정리할까요? / 삭제할까요?" 를 사용자에게 **묻지 않는다** (일회성 임시 clone 이라 불필요한 재확인이며, 묻는 것은 본 cleanup contract 위반이다). habitual over-cautiousness / post-hoc rationalization 으로 success path 에서 삭제를 보류하거나 재확인하는 것은 guide-based 가 아니다. 묻거나 보존하는 것은 아래 예외에만 해당한다.
- **예외 — leftover path + 이유 보고 (자동 재삭제 안 함).** 다음에만 자동 삭제하지 않고 **leftover path 와 이유** 를 보고해 사용자 결정에 맡긴다: (a) **cleanup 실패** (in-use handle / lock / 삭제 error — exact path + 이유 보고), (b) **investigation-needed** (install 실패 또는 추가 조사 필요), (c) **evidence-preserve-needed** (디버그 evidence 보존이 명시적으로 요청됨). 어느 경우든 path + 이유를 명시한다.
- **cleanup 실패 시 lifecycle 분류.** in-use handle 등으로 bootstrap clone 삭제가 실패하면 install 은 **success with cleanup leftover** 로 분류하고 **full lifecycle closeout 으로 보고하지 않는다** — installed payload identity 자체는 정합이지만 (§3.2 / §9 — work area 존재 여부는 install identity 의 success criterion 이 아니다) operator workflow 의 cleanup 이 닫히지 않았기 때문이다. exact leftover path + 이유를 명시한다.
- **operator workflow 규칙 (mechanize 안 함).** §7.1 과 같이 본 규칙은 operator workflow 규칙이며 이를 강제하는 wrapper / acquisition cache / `install-global.ps1` 의 self-delete 동작은 구현하지 않는다 — bootstrap clone 은 script 밖에서 operator 가 만든 것이라 script 가 그 존재 / path 를 모른다 ((a) 의 script-내부 run-scoped work area 와 구분된다). mechanization 은 closeout stream 의 별도 결정이다.

## 7. Update / reinstall procedure

이미 `current/` + `install.json` 이 있는 경우의 절차다. update 와 reinstall 은 같은 model — deterministic overwrite materialization — 의 두 표현일 뿐이다.

1. operator 는 사용자에게 의도를 표시한다. 두 종류가 있다.
   - **"업데이트 받아"** — source side update + global install update. GitHub URL source 와 local clone path source 모두에 적용된다. GitHub URL source 일 때는 §2 policy 에 따라 새 run-scoped temporary work area 에서 `git clone` 으로 source 를 새로 획득한 뒤 (action 사이에 persistent cache 가 보존되지 않으므로 `git fetch` 는 정상 lifecycle 에서 호출하지 않는다) 그 source 의 HEAD SHA 를 사용한다. local clone path source 일 때는 사용자가 가진 기존 clone 의 fetch / pull 또는 user 가 별도로 정리한 새 HEAD 가 source 로 사용된다 (operator 가 사용자 clone 을 자동으로 fetch / pull 하지는 않으며, propose 단계에서 명시 확인을 받는다).
   - **"현재 최신 버전 기준으로 update / reinstall"** — source side 를 건드리지 않고, 이미 사용자가 원하는 HEAD 에 있다고 보고 그 HEAD SHA 로 destination 만 다시 작성한다. 즉 같은 destination 을 같은 model 로 deterministic 하게 재작성하는 reinstall 이다. 본 의도는 **local clone path source 에만 적용된다.** GitHub URL source 는 본 도구가 persistent source-cache 를 보존하지 않으므로 "건드리지 않을 source side" 가 install area 안에 존재하지 않는다 — 따라서 GitHub URL source 의 reinstall 은 "업데이트 받아" path 로만 수행한다 (새 run-scoped temporary work area 에서 acquisition 후 cleanup). 사용자가 GitHub URL source 에 대해 "현재 최신 버전 기준" 의도를 표시하면 operator 는 그 사실을 설명하고 "업데이트 받아" path 로 진행할지 사용자에게 묻는다.
2. operator 는 §5 inspect 를 수행한다. 기존 `install.json` 읽기 + source 의 새 HEAD SHA resolve + (필요 시) 변경 사항 요약. GitHub URL source 의 경우 새 run-scoped temporary work area 의 path 후보도 inspect 시점에 결정한다.
3. operator 는 §5 propose 를 수행한다. propose 에는 다음이 포함된다.
   - 적용 의도 (위 두 종류 중 어느 쪽인지; GitHub URL source 일 때는 "업데이트 받아" path 만 사용 가능하다는 사실).
   - 새 ref / SHA 와 기존 `lastUpdatedHead` 의 비교 (현재 installed content identity 는 `lastUpdatedHead` 이며, `installedHead` 는 최초 install 시점의 history field 이므로 비교 대상이 아니다).
   - destination 에 overwrite 될 path 들.
   - `install.json` 의 어느 field 가 어떻게 갱신되는가 (예: `lastUpdatedHead`, `lastUpdatedAt`).
   - (GitHub URL source 인 모든 경우 — "업데이트 받아" path) §2 의 run-scoped temporary work area policy 에 따라 acquisition 에 사용할 **temporary work area 의 구체 path** 와 acquisition 종료 후의 **cleanup 계획**. local clone path source 는 본 항목을 생략한다 — local clone path source 의 "업데이트 받아" 는 사용자 기존 clone path 를 source 로 사용하므로 temporary work area 가 없고, "현재 최신 버전 기준" 도 마찬가지다.
4. 사용자가 명시적으로 승인한 경우에만 §5 apply 를 수행한다.
5. apply 직후 §5 verify 를 수행하고, 정합 상태로 닫혔으면 (GitHub URL source 인 모든 update / reinstall 동작에서) §2 policy 에 따라 temporary work area 를 제거한다. cleanup 자체의 성공 / 실패 결과는 verify 보고에 함께 포함한다.

update / reinstall 어느 쪽도 destination 의 사용자 편집을 보존하기 위한 conditional skip / partial merge 를 수행하지 않는다 — destination 은 source SHA 기준의 deterministic copy 다.

### 7.1 Name-based update re-entry (deterministic bootstrap)

사용자가 "ai-harness-toolset 최신버전으로 업데이트해" 같은 **tool-name-only entry** 로 update 를 요청할 때, operator 는 임의의 mutation 을 시작하기 전에 본 5-step bootstrap 을 거친다. 본 절은 §7 본문 (general update / reinstall) 의 entrypoint 가 sourced operator instruction (URL 또는 local clone 명시) 이 아니라 **이름만 주어진** 경우에 적용된다 — payload acquisition 이전에 source 의 INSTALL.md 가 다시 operative contract 로 채택되어야 함을 명시한다.

1. **Read install.json.** installed `install.json` 의 `installMode` / `repoUrl` (또는 `sourcePath`) / `branch` / `remote` / `lastUpdatedHead` 를 읽는다. install.json 이 부재이거나 §4 의 14-field schema 와 mismatch 이면 본 path 가 적용되지 않는다 — operator 는 §6 fresh install 절차로 분기하고 사용자에게 상황을 보고한다.
2. **Acquire source via temporary work area.** `installMode == git-url` 이면 §2 의 run-scoped temporary work area 에 `git clone` 으로 source 를 새로 획득한다 (operator 는 propose 단계에서 work area path 와 cleanup 계획을 사용자에게 함께 보고한다). `installMode == local-clone` 은 사용자 기존 clone path 를 source 로 사용한다 — §7 본문의 standing rule 이 그대로 적용된다.
3. **Re-adopt the cloned INSTALL.md as the operative contract.** 새로 acquire 된 source 의 INSTALL.md 를 update 의 operative contract 로 **재채택**한다. 본 step 이전까지 payload materialize / activation apply / verification / smoke / cleanup 어느 phase 도 시작하지 않는다. cloned INSTALL.md 본문이 후속 step 전체를 결정한다 — 본 도구의 anti-coupling 절 (self-contained operative contract) 와 §3 의 source-input model 과 정합한다.
4. **Propose phase self-check (single line).** operator 는 사용자에게 한 줄을 surface 한다 — "INSTALL.md @ `<resolved-head>` read; operative contract 적용." 본 surface 는 사용자가 operator 의 contract re-adoption 을 확인할 수 있는 minimal evidence 다. 사용자는 본 보고와 propose 의 전체 mutation 목록 (§2A "Default install UX" 의 single yes/no surface) 위에서 yes/no 를 결정한다.
5. **Proceed with the update flow (activation scope per §7.2).** 사용자가 yes 면 §2 / §4 / §5 / §7 의 deterministic overwrite materialization (payload) → §5 verify → operational smoke → cleanup 순으로 진행한다. payload 단계의 승인은 §7.1.1 / §13.8 의 command-implied approval (update-source) 이며 **payload-only** 다. activation surface 는 update-source 가 byte-identity verify 만 하고, drift 가 있으면 `activation_pending` 으로 보고한다 — 그 activation 의 실제 apply 는 §2A phase 2 / §10 의 **별도 explicit 단계** 다 (fresh / full install 의 single yes/no activation bundling 과 구분된다; §7.2 matrix). 즉 name-based update 는 fresh install 처럼 activation 을 같은 승인으로 자동 apply 하지 않는다 — payload update 성공과 activation follow-up 을 구분해서 보고한다.

#### Name-based update quickstart (self-contained)

사용자가 자연어로 update 를 요청할 때 — 예: `ai-harness-toolset 최신버전으로 업데이트해줘` — operator 는 다음 체크리스트를 따른다. 본 quickstart 는 위 5-step bootstrap 의 실행 순서이며 self-contained 다 (외부 문서 참조 없이 본 절 + §7.1.1 + §7.2 + §13 으로 닫힌다).

1. **install.json 확인.** installed `install.json` 의 `installMode` / `repoUrl` (또는 `sourcePath`) / `branch` / `remote` / `lastUpdatedHead` 를 읽는다. 부재 / schema mismatch 면 본 path 가 아니라 §6 fresh install 로 분기한다.
2. **remote / source HEAD 확인.** `git-url` 이면 `install.json.branch` 기준 remote HEAD SHA, `local-clone` 이면 사용자 clone 의 HEAD SHA 를 확인해 `lastUpdatedHead` 와 비교한다 (변경 surface 의 read-only plan-report).
3. **latest source clone.** `git-url` 이면 §2 run-scoped temporary work area 에 최신 source 를 clone 한다 (이것이 operator-created bootstrap clone — cleanup 은 아래 규칙). `local-clone` 이면 사용자 기존 clone 을 source 로 쓴다.
4. **cloned INSTALL.md 재채택.** clone 한 source 의 `INSTALL.md` 를 operative contract 로 다시 채택한다 (§7.1 step 3). 이 단계 전에는 어떤 mutation phase 도 시작하지 않는다.
5. **inspect (read-only).** **clone 한** source 의 `scripts/install-update.ps1 -Mode inspect -InstallArea <global install area>` 로 prev HEAD → resolved HEAD / payload·activation drift 를 chat 에 보고한다.
6. **update (payload mutation) — operator-facing 진입점은 `scripts/update-global.ps1` 다.** **clone 한** source 의 `scripts/update-global.ps1 -InstallArea <global install area>` 를 호출한다 — 이 호출 자체가 command-implied approval 이다 (§7.1.1 / §13.8). `update-global.ps1` 은 thin wrapper 로, 기존 valid install 이 아니면 fail-fast 하여 `install-global.ps1` (§6.1) 로 안내하고, 맞으면 underlying `install-update.ps1 -Mode update-source` 로 delegate 한다 (payload — `current/` + 세 sibling 파일 — 만 갱신, activation surface 는 byte-identity verify only; logic 동일, 이름만 operator-facing). (compat / 직접 경로: `scripts/install-update.ps1 -Mode update-source -InstallArea <global install area>` 를 그대로 호출해도 된다 — 그것이 update-global 이 감싸는 canonical implementation 이다.)
7. **verify (read-only).** 갱신 후 `scripts/install-update.ps1 -Mode verify -InstallArea <global install area>` 로 14-field schema + manifest + marker + cross-binding + activation byte-identity 를 확인한다 (verify 는 read-only 라 update-global wrapper 없이 install-update 로 직접 돈다; installed copy 로 돌려도 동일 판정이다).
8. **cleanup.** operator-created bootstrap clone 을 정리한다 (아래 "Operator bootstrap clone cleanup 규칙"). update-source **내부** 의 run-scoped source-cache 는 update-source 가 스스로 정리한다 (별개; §13.2 / §13.9).
9. **activation_pending 보고.** update-source / verify 가 `activation_pending` (또는 activation-only `verify_failed`) 를 내면 — payload 는 정합이고 activation surface 만 drift 한 상태일 수 있다 (§13.2). 이것은 **payload 실패가 아니라 follow-up** 이다: human 보고는 `payload=ok` / `activation=pending` / `result=INCOMPLETE (payload OK; activation follow-up required)` 로 hard failure 처럼 보이지 않게 하고 (human label 도 `FAIL` 이 아니라 `INCOMPLETE`; machine status·exitCode 는 그대로 — §13.2), activation 의 실제 apply 는 별도 explicit 단계 (§2A phase 2 / §10) 임을 명시한다 — update-source 는 activation 을 자동 apply 하지 않는다. update-source 는 activation drift 시 복붙 가능한 exact next command 를 출력한다 — installed context 기준:
   - dry-run preview (먼저): `powershell.exe -NoProfile -ExecutionPolicy Bypass -File "<InstallArea>\current\scripts\activate-global.ps1" -Scope All`
   - apply (명시 승인 후): `powershell.exe -NoProfile -ExecutionPolicy Bypass -File "<InstallArea>\current\scripts\activate-global.ps1" -Scope All -Apply`
   - apply 는 global/user instruction file 을 mutate 한다 — managed-block surface (Claude / Codex) 는 `.amb-backup` rollback backup 을 만들고, skill mirror (source skill 당 하나) 는 backup 없는 whole-file canonical-overwrite 다 (§10). dry-run 은 managed-block 에 대해 기본적으로 **compact change summary** 를 내며, 전체 before/after 가 필요하면 `-ShowFullDiff` 를 붙인다.

> **`-InstallArea` 는 install ROOT 이지 `current/` 가 아니다.** 위 모든 `-InstallArea <global install area>` 인자는 `current/` + `install.json` + `payload-manifest.json` + `payload-marker.json` 을 **포함하는** 디렉터리 (예: `%USERPROFILE%\.claude\ai-harness-toolset`) 다. `current/` 를 넘기면 `install.json` 을 찾지 못해 `inspect_mode_unknown` 으로 분류되며, "did you mean its parent" hint 가 reasons 에 붙는다. update-source 는 넘긴 InstallArea 를 mutate 하므로 default 추론을 두지 않는다 (잘못된 default 가 실제 global install 을 mutate 하는 것을 막기 위함).

**Note — installed copy 에 update entrypoint 가 있어도 cloned latest 를 쓴다.** installed `current/scripts/` 에 이미 `update-global.ps1` / `install-update.ps1` 의 update-source mode 가 있더라도, name-based update 는 위 quickstart 처럼 **latest source clone** 의 entrypoint 로 실행한다 (installed 사본이 아니다) — update 는 cloned `scripts/update-global.ps1`, read-only inspect / verify 는 cloned `scripts/install-update.ps1`. **legacy installed payload 는 `update-global.ps1` 자체가 없을 수도 있으므로**(IU-B-09 이전 payload) 더더욱 cloned latest 를 써야 한다. 이유: (a) latest source 의 `INSTALL.md` 가 operative contract 이고 (§7.1 step 3), (b) latest source 의 script 가 그 latest contract 와 일치하며, (c) installed payload 는 bootstrap 시점에 아직 old 일 수 있어 source-of-truth 가 아니다. 단 read-only `-Mode verify` 는 installed 사본으로 돌려도 동일 판정이다 (quickstart step 7) — read-only 라 mutation 이 없기 때문이다.

##### Legacy bootstrap note — installed entrypoint 가 update-source 를 못 가질 때

오래된 installed payload 의 `current/scripts/` 에는 update-source 이전의 **read-only** `install-update.ps1` (ValidateSet 가 `inspect` / `verify` 뿐) 이나 구 `install-pipeline.ps1` (global 영역을 hard-FAIL 로 거부) 만 있을 수 있다. 이때:

- installed copy 를 억지로 update-source 로 실행하려 하지 않는다 — 그 entrypoint 에는 그 mode 자체가 없다.
- installed entrypoint 가 ValidateSet / guard 로 update-source 를 거부하는 것은 **legacy bootstrap 상태의 신호** 이지 "global install 은 갱신 불가" 가 아니다.
- 회복 경로는 위 quickstart 그대로다 — 최신 source clone → cloned `INSTALL.md` 재채택 → **cloned** `scripts/update-global.ps1` 실행 (이것이 underlying `install-update.ps1 -Mode update-source` 로 delegate). 즉 update 는 항상 **clone 한 최신 source** 의 operator-facing 진입점 (`update-global.ps1`, 없는 legacy payload 면 cloned latest 에는 있다) 으로 돈다 (installed 사본이 아니라). compat 으로 cloned `install-update.ps1 -Mode update-source` 직접 호출도 동일하다.
- installed `current/scripts/install-pipeline.ps1` 또는 구 read-only `install-update.ps1` 만 보고 update 가 불가능하다고 결론짓지 않는다.

##### Operator bootstrap clone cleanup 규칙

- **두 cleanup 은 다르다.** (a) update-source **내부** 의 run-scoped source-cache cleanup 은 `install-update.ps1` 가 스스로 수행한다 (성공 / 실패는 status / `leftoverPaths` 로 보고; §13). (b) operator 가 위 quickstart step 3 에서 INSTALL.md / 스크립트를 읽으려고 만든 **bootstrap clone** 의 cleanup 은 operator workflow 책임이며 (a) 와 별개다.
- operator-created bootstrap clone 은 update / activation / verify 가 **성공적으로 닫힌 뒤 자동 삭제** 한다 — 성공 경로에서는 "삭제할까요?" 를 사용자에게 **묻지 않는다** (일회성 임시 clone 이므로 불필요한 재확인이다). 삭제 여부를 묻거나 clone 을 보존하는 것은 아래 예외에만 해당한다.
- **예외 — leftover path + 이유 보고 (자동 재삭제하지 않음).** 다음 세 경우에만 bootstrap clone 을 자동 삭제하지 않고 그 **leftover path 와 이유** 를 사용자에게 보고하여 결정에 맡긴다: (a) **cleanup 실패** (삭제 자체가 실패), (b) **investigation-needed** (추가 조사를 위해 보존), (c) **evidence-preserve-needed** (디버그 evidence 보존). 어느 경우든 path + 이유를 명시한다.
- 본 규칙은 **operator workflow 규칙** 이다. 이를 mechanize 하는 wrapper 나 acquisition cache 는 구현하지 않는다 (그 옵션은 closeout stream 의 later phase 결정).
- **이중 acquisition 은 의도된 safety tradeoff 다.** name-based git-url update 에는 두 번의 source 획득이 있을 수 있다 — (a) bootstrap clone (operator 가 최신 `INSTALL.md` / script 를 읽기 위한 acquisition; 위 quickstart step 3) 과 (b) update-source **내부** 의 run-scoped source-cache acquisition (script 가 trusted source 를 materialize 하기 위한 acquisition). 둘은 **목적과 cleanup ownership 이 다르므로** 같은 clone 을 silent 하게 재사용하지 않는다 — persistent source-cache 를 두지 않는다는 §2 / §3.2 원칙의 당연한 귀결이다. cache 재사용 / `-AcquisitionClonePath` 같은 cache-hint feature 는 source trust / cleanup / identity semantics 를 키우므로 closeout stream 의 later phase 결정이며 본 단계에서 구현하지 않는다. double clone 을 줄이려고 update-source 에 `-SourcePath` 를 넘기지 않는다 — git-url install 의 update-source apply 는 `-SourcePath` 를 **사용하지 않고** source 를 `install.json.repoUrl` 기준으로 획득한다 (`-SourcePath` 는 `installMode == local-clone` 일 때만 apply 의 source 다). 따라서 git-url install 에서 `-SourcePath` 로는 double clone 을 줄일 수 없고, preflight `inspect` 만 `-SourcePath` 를 우선해 HEAD 를 resolve 하므로 넘기면 preflight 와 apply 가 서로 다른 source 를 보는 **불일치만** 생긴다 (source-cut 을 유발하는 것은 아니다). local source 로 **실제 전환** 하려면 local-clone install identity 가 필요하며 그건 source identity 변경 = 별도 explicit 결정이다 (아래 "Source identity 주의").

##### Source identity 주의 — `-RepoUrl` 과 source-cut

name-based update 의 source identity 비교 (source-cut hard guard) 는 install.json 의 identity field (`installMode` / `repoUrl` / `sourcePath` / `toolRoot` / `branch` / `remote`) 를 **ordinal, case-insensitive** string 으로 비교한다 (`[System.StringComparison]::OrdinalIgnoreCase`) — `.git` suffix / trailing slash 같은 표현을 동일하게 보는 **URL 정규화는 하지 않지만**, 대소문자는 무시한다. 따라서:

- **가능하면 `-RepoUrl` 을 직접 넘기지 말고 omit 한다** — update-source 는 `-RepoUrl` 이 없으면 source 를 `install.json.repoUrl` 기준으로 획득하므로 비교가 자기 자신과 일치해 source-cut 이 발동하지 않는다. 이것이 가장 안전한 default 다.
- 의미상 **동일한 repo 라도 표현이 다른 URL** — terminal `.git` suffix 유무, trailing slash 유무 — 을 `-RepoUrl` 로 넘기면 URL 정규화가 없으므로 source-cut hard guard 가 **false-positive 로 발동** (`failed`) 할 수 있다. 비교가 case-insensitive 이므로 **대소문자 차이만으로는 발동하지 않는다** — 발동하는 것은 `.git` / trailing slash 같은 문자 차이다 (scheme / host / path 가 실제로 다르면 그건 false-positive 가 아니라 정당한 source-cut 이다). source 를 의도적으로 바꾸는 게 아니라면 `-RepoUrl` 을 재작성하거나 전달하지 않는다.
- source identity 를 **실제로** 바꾸는 source-cut override 는 **command-implied approval 범위 밖** 이다 (§7.1.1 의 command-implied 적용 범위 한정 / §13.8) — 별도의 explicit 사용자 결정으로만 진행한다. update-source 는 source-cut 을 자동 해소하지 않고 `failed` 로 멈춘다.
- (dogfood 관찰) 한 dogfood 에서 `install.json.repoUrl` 에 `.git` 이 있고 operator 가 `.git` 없는 동일 URL 을 넘겼다면 source-cut 으로 막혔을 상황이 확인됐다 — 위 "omit `-RepoUrl`" 가이드가 그 friction 을 해소한다. (정규화를 코드에 넣는 것은 source-cut 비교 semantics 를 키우므로 later phase 결정으로 남긴다.)

### 7.1.1 Canonical update-source apply entrypoint

payload 재작성 단계 (step 5 의 materialization → verify → cleanup → smoke 의 **payload 부분**) 는 operator 가 library 함수를 손으로 조립하지 않는다. canonical 한 source-controlled 진입점은 다음 하나다:

```text
scripts/install-update.ps1 -Mode update-source -InstallArea <global install area> [-SourcePath <local clone> | -RepoUrl <url>] [-Branch <b>] [-Remote <r>] [-Ref <ref>] [-SkipSmoke]
```

- **Operator-facing 이름은 `scripts/update-global.ps1` 다 (이름만 보고 install / update / uninstall 을 구분).** lifecycle entrypoint 는 이름으로 갈린다 — fresh install = `scripts/install-global.ps1` (§6.1), 기존 install update = `scripts/update-global.ps1`, uninstall = `scripts/uninstall-global.ps1`. `update-global.ps1` 은 **thin wrapper** 다: install area 가 없거나 (install.json 부재) invalid 면 fail-fast 하여 `install-global.ps1` 로 안내하고, valid 한 기존 install 이면 위 `install-update.ps1 -Mode update-source` 로 인자를 그대로 전달(delegate)하고 그 exit code / 출력을 투명하게 반환한다 — update-source 로직을 재구현하지 않는다.
- **`install-update.ps1` 은 기존-update 의 internal / compat 구현으로 유지된다.** 본 §7.1.1 의 update-source mutation 본체는 여전히 `install-update.ps1` 이며 (read-only `inspect` / `verify` 포함), `update-global.ps1` 은 그 위의 operator-facing 이름일 뿐이다. `install-update.ps1` 을 직접 호출하는 것도 유효하다 (특히 name-based update quickstart 의 cloned-latest-script 규칙은 `install-update.ps1` 기준이다 — §7.1 Note). `install-update.ps1` 은 fresh install 을 하지 않는다 (그건 `install-global.ps1` 의 일이다).
- `-Mode inspect` / `-Mode verify` 는 **read-only** (mutation / 승인 없음). `-Mode update-source` 가 **유일한 mutation mode** 다.
- **Command-implied approval (existing install 의 update-source approval surface).** 사용자의 명시적 update 지시 ("ai-harness-toolset 최신버전으로 업데이트해" 등) + operator 의 **read-only plan-report** (inspect 로 prev HEAD → resolved HEAD / 변경 surface / destination 을 chat 에 보고) 가 **기존 identity-consistent install 의 update-source mutation 에 대한 explicit approval surface** 다. 즉 operator 가 `-Mode update-source` 를 호출하는 것 자체가 그 승인이며, 별도의 terminal yes/no keystroke 를 강제하지 않는다 — 정규 Claude Code noninteractive shell 에서도 막히지 않는다. (이는 §5 step 3 의 "명시 proceed 의도" 를 자연어 명령으로 충족하는 것이며, terminal selector 는 contract 요구사항이 아니라 선택적 mechanism 이다.)
- **Command-implied approval 의 적용 범위 한정.** 이 모델은 **기존 install 의 update-source** 에만 적용된다 — fresh install, 새 destination 생성, activation apply 자동화, source-cut override 에는 적용되지 않는다 (그것들은 §2A 의 single yes/no / §10 의 별도 explicit approval 그대로). update-source 는 그 한정 범위 안에서, 아래 hard guard 를 통과할 때만 apply 한다.
- **Hard guards (command 가 우회하지 못함; 위반 시 stop/report, mutation 없음).** source-cut (installMode / repoUrl / sourcePath / toolRoot / branch / remote 가 install.json 과 불일치) → `failed`; **destination 에 valid install identity 부재** — install.json 자체가 없거나 §4 14-field schema 와 mismatch 이거나 unknown schemaVersion → `inspect_mode_unknown` / `failed` (update-source 는 identity 가 없는 빈/비-install 디렉터리를 새 install 로 만들지 않는다 — 그건 fresh install §6 의 일이다); source HEAD resolve 실패 → `failed`; payload delta 없음 → `noop_already_current` (mutation 없음); post-apply verify 실패 → `verify_failed` (절대 `complete` 아님); cleanup leftover → `cleanup_failed_with_leftover` + `leftoverPaths`; activation drift → `activation_pending` (자동 activation write 없음). **주의 (reinstall-first 와의 관계).** install.json identity 가 valid 하지만 payload 가 drift / partial / corrupt (manifest/marker/cross-binding 깨짐, `current/` 부분 손상) 한 경우는 **refuse 가 아니라 recover** 된다 — update-source 의 deterministic overwrite 가 trusted source identity (resolved SHA) 기준으로 `current/` + manifest + marker 를 다시 써서 §9 의 reinstall-first 회복을 수행한다 (source-cut guard 가 source identity 일치를 보장하므로 안전). 즉 hard guard 가 막는 것은 **identity 부재/불일치** 이지 **payload 손상** 이 아니다.
- **Optional interactive confirm (`-ConfirmInteractive`).** 직접 터미널 운영자가 추가 confirm 을 원하면 `-ConfirmInteractive` 로 §13.8 의 two-choice (Yes/No) selector 를 켤 수 있다 — default OFF (command-implied). `-ConfirmInteractive` 를 켰는데 interactive terminal 이 없으면 apply 로 silent fall-through 하지 않고 `update_aborted_no_approval` 로 중단한다.
- update-source 는 `New-InstallPipelineTuple` (action=`update-source`) → `Invoke-InstallPipelineDispatch` 로 deterministic overwrite materialization 을 수행하고, `installedHead` / `installedAt` 를 보존하며 `lastUpdatedHead` / `lastUpdatedAt` 를 갱신하고, `current/` + `payload-manifest.json` + `payload-marker.json` 을 정합되게 다시 쓴다. 그 뒤 canonical `Invoke-InstallPipelineVerify` (§5 schema + manifest + marker + cross-binding) 와 모든 activation surface 의 byte-identity verify, run-scoped work area cleanup, optional operational smoke (§13.7) 를 수행하고 §13.1 fixed status 를 emit 한다.
- operator 는 이 진입점을 호출하기 위해 `scripts/lib/install-pipeline-core.ps1` 등 internal library 를 읽을 필요가 없다 — payload apply 의 operative contract 는 본 §7.1.1 + §13 으로 self-contained 하다.
- activation surface 적용 (managed block / skill mirror write) 은 update-source 의 책임이 **아니다** — update-source 는 그것을 byte-identity 로 verify 만 하고 (no-op when identical, `activation_pending` when drifted), 실제 apply 는 §2A phase 2 / §10 의 `scripts/activate-global.ps1` + `scripts/apply-managed-block.ps1` 별도 explicit 단계다.

본 절은 §2A "Default install UX" 와 정합한다 (fresh / full operational install 은 여전히 §2A 의 single yes/no). cleanup 의무 / activation apply 규칙은 §2A / §5 / §10 / §11 standing rule 그대로 적용된다.

### 7.2 Flow comparison — fresh install vs name-based update vs activation refresh

세 flow 의 activation scope 를 한 자리에서 구분한다. Phase 2 는 동작을 바꾸지 않는다 — 본 절은 명료화이며, fresh install 의 "activation 번들" 표현과 name-based update 의 "payload-only update-source" 표현이 모순처럼 읽히지 않게 분리한다.

| Flow | payload mutation | activation mutation | approval model | canonical entrypoint | expected terminal status |
|---|---|---|---|---|---|
| **Fresh / full operational install** (§2A, §6) | yes (`current/` + 세 sibling 생성) | yes — Claude / Codex managed block + skill mirror apply 가 install 에 **번들** | §2A "Default install UX" 의 **단일 yes/no** 가 payload + activation 전체를 cover | §2A AI-guided operational install flow (productized installer 아님; §5.1) | operational install 완료 (payload verify + activation verify + smoke + cleanup 통과) |
| **Name-based existing install update** (§7.1 / §7.1.1) | yes (`current/` + 세 sibling 재작성) | **no** — update-source 는 activation 을 **byte-identity verify only** (apply 안 함) | **command-implied approval** — 기존 identity-consistent install 의 update-source payload mutation 에 **한정** (§13.8) | **cloned** `scripts/update-global.ps1` (operator-facing; → underlying `install-update.ps1 -Mode update-source`) | `complete` (activation 정합) / `activation_pending` (payload OK, activation drift → follow-up) |
| **Activation refresh / apply** (§2A phase 2, §10) | no | yes — **모든 surface** (Claude managed block + Codex managed block + source skill 당 mirror); **두 mutation class** (managed-block / canonical-overwrite) | **별도 explicit** user-approved 단계 (command-implied 적용 안 됨; `-Apply` 가 그 명시 결정, optional `-ConfirmInteractive` 는 two-state confirm) | `scripts/activate-global.ps1` (generic activation orchestrator) → managed block 은 `scripts/apply-managed-block.ps1`, skill mirror 는 canonical-overwrite | `applied` (전 surface 적용+verify) / `activation_applied_verify_failed` (apply 후 surface verify 실패) / dry-run `preview` |

핵심 (모순처럼 보이는 두 표현의 정합):

- **fresh / full install 은 activation 을 번들** 한다 (§2A 단일 yes/no 가 payload + activation 전체 승인). **name-based update 의 update-source 는 payload-only** 이고 activation 은 verify-only 다 — 둘은 모순이 아니라 **다른 flow** 다. 같은 문장처럼 읽히지 않도록 본 matrix 로 분리한다.
- name-based update 에서 activation drift 가 있으면 update-source 는 그것을 자동 apply 하지 않고 `activation_pending` 으로 보고한다 (payload update 성공과 activation follow-up 을 구분). activation 의 실제 apply 는 위 세 번째 행의 **별도 explicit 단계** 다.
- **command-implied approval 의 범위** 는 기존 install 의 update-source payload mutation 뿐이다 — fresh install / 새 destination 생성 / activation apply / source-cut override 에는 적용되지 않는다 (§7.1.1 / §13.8). activation apply automation 을 update-source 에 folding 하는 것은 closeout stream 의 later phase 결정이며 현재 동작이 아니다.
- **apply coverage == verify coverage (Phase 4a).** `update-source` / `verify` 가 검사하는 **모든 activation surface** (Claude managed block, Codex managed block, source skill 당 mirror) 를 `scripts/activate-global.ps1` 가 모두 **apply** 한다 (이전에는 managed block 2 개만 apply 했고 skill mirror 는 수동이었다). apply 와 verify 는 동일한 surface resolver (`scripts/lib/activation-surface.ps1`) 를 공유하므로 destination 해석 (특히 Codex `AGENTS.override.md` 우선순위) 이 어긋나지 않는다. activate-global 은 여전히 **별도 explicit step** 이며 update-source 가 자동 호출하지 않는다.

### 7.3 Managed installed-root README (operator landing page)

cold operator 가 installed area 만 보고도 update 방법을 찾을 수 있도록, install area root 에 짧은 **operator landing page** `README.md` 를 둔다 (dogfood 에서 installed root 에 operator-facing pointer 가 없어 scripts 를 역공학해야 했던 마찰을 닫는다).

- **source template path.** `templates/install-root/AI_HARNESS_TOOLSET_ROOT_README.md` — payload root (`templates/`) 안에 있으므로 materialize 시 `current/templates/install-root/...` 로 복사되고 그 bytes 는 `payload-manifest.json` 이 이미 커버한다.
- **installed path.** `<InstallArea>/README.md` — install area root (`current/` 의 sibling). source repo 에는 `README.md` 라는 이름으로 두지 않고 위 deployable template 이름으로 둔다; install area 에서만 `README.md` 가 된다.
- **역할 — operator landing page (full contract 아님).** 이 installed `README.md` 는 full operative source contract 가 **아니다.** update 의 operative contract 는 여전히 **latest source clone 의 `INSTALL.md` 재채택** (§7.1 step 3 / quickstart) 이며, README 본문도 그 점을 명시한다. README 는 operator-facing update entrypoint (`scripts/update-global.ps1`, underlying / compat 은 `scripts/install-update.ps1 -Mode update-source`), (optional) inspect → update-global → (optional) verify 흐름, `-InstallArea` root / `-RepoUrl` omit default, "installed copy 에 update entrypoint 가 있어도 cloned latest script 사용 (legacy payload 는 `update-global.ps1` 부재일 수 있음)", "update-source 는 payload + activation byte-identity verify only", "activation_pending 이면 activation apply 는 별도 explicit step", 그리고 fresh install = `install-global.ps1` / uninstall = `uninstall-global.ps1` 의 lifecycle 이름 구분을 짧게 안내한다.
- **uninstall discovery 도 README landing page 가 담는다 (install/update 와 대칭; IU-B-10).** cold operator 가 installed area 만 보고 official uninstaller 를 찾도록, README 는 update 와 같은 방식으로 **package hierarchy discovery** 를 안내한다 — official uninstaller 는 install-root 최상위가 아니라 **`current\scripts\uninstall-global.ps1`** (install/update entrypoint 와 같은 `current\scripts\` 안) 에 있으므로 최상위만 보고 "uninstaller 없음" 으로 결론짓지 말 것, dry-run(default) → `-Apply` 흐름, footprint-zero (install root + skill mirror + 두 instruction file 의 managed block; instruction file 은 삭제하지 않고 marker span 만 절제), **Codex surface target set** — default `%USERPROFILE%\.codex\AGENTS.md`, `CODEX_HOME` set 시 `%CODEX_HOME%\AGENTS.md` (그 scope 의 `AGENTS.override.md` 우선) — 을 명시한다. **block-only `AGENTS.md` 는 marker span 절제 후 0-byte 가 정상** (file 미삭제 contract 의 올바른 footprint-zero 결과이며 손상이 아니다) 임을, 그리고 **manual deletion/rewrite 는 official uninstaller 가 부재(legacy payload)/실패일 때의 corrective fallback 일 뿐 official uninstall dogfood 가 아니다** (manual cleanup 은 Codex `%USERPROFILE%\.codex\AGENTS.md` managed block 을 누락하기 쉬움) 를 명시한다. 이로써 main-PC uninstall incident 의 root cause — snippets / global instruction 부족이 아니라 installed package hierarchy discovery 실패 — 를 install/update 와 동일한 landing-page discovery 로 닫는다. 전체 uninstall contract (footprint-zero 기준 / temp-finalizer trampoline / 비대상 / dry-run·apply·verify 분리 / failure tier) 는 §11 (b) + design doc 가 source-of-truth 이며 README 는 discovery pointer 다.
- **materialization (deterministic, managed; canonical output — not self-healing).** fresh install 과 **payload 를 재작성하는 update-source** 에서 canonical pipeline (`Invoke-InstallPipelineDispatch`) 이 materialization 직후 in-payload template 에서 `<InstallArea>/README.md` 로 deterministic overwrite 한다. 따라서 실제 install / update 마다 latest template 으로 갱신되며 old / orphan 상태로 남지 않는다 — root README 는 정상 install / update 의 **canonical output** 이다. **root README 는 self-healing 대상이 아니다.** payload 가 이미 current 라 update-source 가 payload 재작성을 건너뛰는 no-op 경로 (`noop_already_current` / activation-only `activation_pending`) 에서는 root README 를 in-place 로 surgical 복구하지 **않는다** (§9 의 patch-on-destination 금지와 정합). 정상 latest install / update 이후 root README 가 missing / stale / corrupt 라면 그것은 사용자 임의 삭제 또는 설치 손상 — 즉 **install integrity failure** 이며, 회복은 §9 의 **reinstall-first deterministic overwrite** (source 재준비 → §6 fresh install 또는 §7 payload-rewrite update-source) 다.
- **inspect / verify 가 integrity failure 를 드러낸다 (숨기지 않는다).** `verify` 는 missing / stale / corrupt root README 를 `verify_failed` 로 잡는다. `inspect` 는 이 상태를 `inspect_clean` 으로 숨기지 않고 다른 installed-artifact integrity 실패와 함께 **`inspect_payload_drift`** 로 분류한다 (§13.1). 두 mode 의 `reasons` 는 "re-run update-source" 가 아니라 **reinstall-first 회복** (§9) 을 안내한다. README-only drift 의 회복도 별도 surgical repair 가 아니라 standard deterministic-overwrite apply 가 README 를 canonical output 으로 다시 만드는 것이다.
- **manifest / verify coverage (managed artifact).** template 자체는 manifest-covered 이고, root `README.md` 는 canonical verify (`Invoke-InstallPipelineVerify`) 가 in-payload template 과의 **byte-identity (SHA-256)** 로 검사한다 — manifest schema 변경 없이 transitive integrity 를 얻는 별도 managed-root-artifact verification path 다 (helper `Get-InstallPipelineRootReadmeState` 가 inspect / verify 의 integrity 판정을 single-source 한다). payload manifest / marker / cross-binding invariant 와 `installedHead` / `lastUpdatedHead` semantics 는 바뀌지 않는다.
- **template-conditional (legacy-safe).** payload 가 template 을 갖지 않으면 (pre-Phase-3.5 source 또는 minimal fixture) materialization / verify 가 README 를 **skip** 한다 (operational smoke 의 prerequisite-skip 패턴과 동일) — template 없는 source 는 영향받지 않는다. legacy installed area 에는 이 `README.md` 가 없을 수 있으나, latest source (template 보유) 로 **첫 update 후 생성** 된다.
- **command-implied / activation 범위 불변.** 본 절은 managed root artifact 의 materialize/verify 와 그 integrity failure 분류 (inspect_payload_drift / verify_failed) 만 다루며 status / exit-code **vocabulary**, command-implied approval 범위, activation apply (별도 explicit step) 를 바꾸지 않는다 (inspect_payload_drift / verify_failed 는 기존 vocabulary 이고, 그 의미에 managed root README integrity 가 포함됨을 §13.1 이 명시한다).
- **update 안내 위치.** operator 용 update 안내는 이 installed root README (landing page) 에만 둔다. snippets / global instruction managed block (`snippets/CLAUDE_SNIPPET.md` / `snippets/AGENTS_SNIPPET.md`) 에는 update 절차 단락을 **추가하지 않는다** (의도적 — global payload 는 role-neutral instruction 이고 operator-update 절차의 자리가 아니다).

## 8. Install identity = resolved commit SHA (review)

§4 의 identity rule 을 다시 한 번 명시한다.

- install 의 identity 는 **resolved commit SHA** 다.
- URL / local path / branch / remote 는 source dispatch hint 일 뿐 identity 가 아니다.

> **URL이나 local path가 같아도 현재 installed payload / version identity는 resolved commit SHA로 판단한다.**

따라서 operator 는 "이미 같은 URL 로 install 되어 있다" 또는 "이미 같은 local clone path 로 install 되어 있다" 를 update / reinstall 불필요의 근거로 삼지 않는다. 항상 source 의 현재 HEAD SHA 와 `install.json.lastUpdatedHead` 를 비교한다 (`installedHead` 는 최초 install 시점의 history field 이므로 현재 installed content identity 의 비교 대상이 아니다).

## 9. Failure handling

install / update / reinstall 중 발생할 수 있는 실패는 모두 같은 회복 model 로 닫힌다 — **별도의 repair / doctor / linter / verifier framework 없이, source 를 재준비한 뒤 deterministic overwrite reinstall 로 회복한다.** destination 의 ad-hoc 부분 수리, missing file 의 surgical 교체, marker 만 다시 쓰기 같은 patch-on-destination 동작은 지원되지 않는다.

이 회복 model 의 핵심 전제는 **generated payload 의 source-of-truth 가 기존 installed payload 가 아니라 trusted source identity (resolved commit SHA) 라는 것**이다. 따라서 `current/` payload 와 그 sibling metadata / integrity artifact (`install.json` / `payload-manifest.json` / `payload-marker.json`) 가 materialization 도중 끊겨 **partial / unknown 상태**가 되어도, 회복은 그 partial state 를 분석 / 역행 / 부분 수리하는 것이 아니라 trusted source 에서 destination 을 통째로 deterministic 하게 다시 만드는 것이다. install / reinstall / update 의 destination-side 처리는 모두 동일한 overwrite 이므로 "복구" 라는 별도 mode 가 없으며, materialization atomicity 는 **transaction log / rollback framework / tamper detection / partial-state reconciliation 으로 구현하지 않는다** (그런 framework 는 본 도구의 범위가 아니다 — §11). generated payload 에는 pre-write backup / rollback 도 두지 않는다 — 손상 시 trusted source 가 곧 복구원이므로 불필요하다.

대표 케이스.

- **source acquisition 실패** — source 부재 / 권한 부족 / network 실패 / GitHub URL 의 clone 실패 등이 원인이면 retry 또는 reset 자동화하지 않는다. operator 는 사용자에게 원인을 보고하고, 사용자가 source 환경을 정리한 뒤 fresh install 을 다시 시도한다. GitHub URL source 의 경우 임시 work area 가 부분적으로 만들어졌다면 operator 는 그 정리도 함께 propose 한다.
- **destination 의 `current/` 가 부재 / 부분 / 손상** — operator 는 fresh install 절차 (§6) 로 다시 시작한다. partial repair 를 시도하지 않는다.
- **`install.json` 의 부재 / corrupt / schema mismatch** — operator 는 사용자에게 상황을 보고하고, 사용자가 명시적으로 승인한 경우에 한해 fresh install 절차 (§6) 로 destination 과 metadata 를 처음부터 다시 만든다.
- **`payload-manifest.json` 또는 `payload-marker.json` 의 부재 / unreadable / unknown schemaVersion / head mismatch / files digest mismatch** — operator 는 사용자에게 보고하고, 사용자가 승인한 경우 §6 fresh install 또는 §7 update / reinstall 로 destination 을 source HEAD 기준으로 다시 작성한다. deterministic overwrite materialization 이 manifest + marker 도 source HEAD 기준으로 재작성하므로 drift 가 자연 해소된다. manifest 의 surgical file 단위 교체는 하지 않는다.
- **cross-binding 불일치 (`payload-manifest.json.head` ≠ `payload-marker.json.head`, 또는 둘 중 어느 한쪽 ≠ `install.json.lastUpdatedHead`)** — 동일 회복 path. 사용자 승인 후 §6 또는 §7 의 deterministic overwrite reinstall 로 manifest / marker 가 `lastUpdatedHead` 와 다시 정합하도록 작성한다. `installedHead` 는 본 cross-binding 의 대상이 아니므로 `installedHead` 와 `lastUpdatedHead` 가 다른 것 자체는 실패가 아니다 (update / restore 후의 정상 상태다).
- **이전 install 의 ref 가 사라짐 (force-push, deleted branch 등)** — operator 는 사용자에게 보고한다. 사용자가 새 ref 를 명시한 경우 그 ref 로 update / reinstall (§7) 을 진행한다. metadata-derived "known-good" ref 의 자동 fallback 은 하지 않는다.
- **(GitHub URL source) temporary work area cleanup 실패** — destination payload + metadata / integrity artifacts 가 정합 상태로 닫혔다면 본 케이스는 **installed payload identity 의 실패가 아니다.** install 의 success criterion 은 destination 의 정합 상태이고, temporary work area 는 §2 policy 에 따라 persistent canonical sibling 이 아니다. 다만 operator 는 cleanup 이 끝나지 않은 **leftover path 를 사용자에게 보고하고, 정리 진행 여부에 대한 명시적 승인을 받는다.** 사용자가 승인하면 operator 가 정리하거나, 또는 사용자가 직접 정리한다. 자동 재시도 / 강제 삭제는 하지 않는다.

요약: install 의 회복 path 는 "source 재준비 → §6 또는 §7 의 deterministic overwrite" 한 줄이다. canonical install output (`current/`, `install.json`, `payload-manifest.json`, `payload-marker.json`) 어느 쪽의 손상이든 이 한 회복 path 로 닫힌다. temporary work area cleanup 실패는 별도 케이스이며 installed payload identity 와 분리된 leftover-path 보고 / 사용자 승인 절차로 처리한다. 자동 clone recovery / surgical file 단위 교체 / repair framework 는 본 도구의 범위가 아니다 (§11 참조).

### 9.1 회복 class 구분 — generated payload / managed-block file / skill activation surface

회복 model 은 세 mutation class 를 명확히 구분한다. 같은 "손상 / 회복" 단어를 쓰더라도 class 마다 회복 방식이 다르다.

> **Apply 관점의 두 mutation class (Phase 4a activation apply orchestration).** 실제 *적용* (write) 메커니즘은 두 종류뿐이다 — **(1) managed-block** (marker-bounded splice; marker 밖 사용자 content 보존; backup / rollback 은 `scripts/apply-managed-block.ps1` 안에만 존재) 과 **(2) canonical-overwrite** (canonical source 기준 whole-file / whole-payload overwrite + post-write byte/hash verify; merge 없음; **backup / rollback / sidecar 없음**; 실패 시 fail-fast + report + reinstall guidance — canonical source 가 곧 회복원이므로). generated payload + 그 sibling metadata + managed root README + **skill mirror** 는 모두 **canonical-overwrite** class 다. 아래 세 회복 class 는 이 두 apply class 위에 mapping 된다 — generated payload / skill mirror 는 canonical-overwrite, managed-block instruction file 은 managed-block.

- **Generated payload class** — `%USERPROFILE%\.claude\ai-harness-toolset\current\` 와 그 sibling metadata / integrity artifact (`install.json` / `payload-manifest.json` / `payload-marker.json`). 이 class 는 전적으로 source 에서 재생성되는 deterministic output 이며 사용자 편집 대상이 아니다. 따라서 partial / unknown / 손상 상태의 회복은 위 **reinstall-first** 한 줄 — trusted source 재준비 → §6 / §7 deterministic overwrite — 이다. 기존 payload 를 회복 source-of-truth 로 삼지 않고, 이 class 에는 backup / rollback / transaction / partial-state reconciliation 을 두지 않는다 (source 가 곧 truth 이므로 불필요하다).
- **Managed-block instruction file class** — `%USERPROFILE%\.claude\CLAUDE.md`, Codex user-global `%USERPROFILE%\.codex\AGENTS.md` (및 §10 의 다른 valid managed-block destination). 이 파일들은 managed block **바깥** 에 **사용자 소유 content** 를 담으므로 whole-file reinstall-overwrite 대상이 **아니다** — marker 밖 사용자 데이터를 보존해야 하기 때문이다. 안전 적용 / 회복은 §10 의 managed-block apply 규칙 (marker pair validation, marker-bounded block 만 1:1 치환, malformed / 중복 marker 시 fail-fast, marker 밖 content 보존, 적용 후 block == snippet verification) 과, 그 apply 를 수행하는 managed-block tooling 이 제공하는 dry-run (no-write preview) / pre-write backup / 손상 즉시 rollback 으로 처리한다.
- **Claude skill activation surface (canonical-overwrite class)** — skill destination `%USERPROFILE%\.claude\skills\<name>\SKILL.md`. 이것은 managed-block file 이 **아니라** canonical-overwrite activation surface 다. 적용은 `scripts/activate-global.ps1` 의 canonical-overwrite path 가 source `snippets/claude-skills/<name>/SKILL.md` → destination 으로 **whole-file byte overwrite + post-write SHA-256 byte/hash verify** 하며, 사용자가 destination 을 수정해 두었다면 overwrite 로 그 수정이 사라진다는 사실을 **사전 고지** 한다 (dry-run preview 가 source/destination hash 와 `create | overwrite | unchanged` action + overwrite 고지를 보여준다). skill 은 marker-bounded 부분 치환이 아니고 **pre-write backup / rollback / backup sidecar 의 대상이 아니다** — read-only dry-run preview 는 있으나 backup / rollback / sidecar 는 두지 않는다. post-write verify 가 실패하면 rollback 하지 않고 fail-fast + report + reinstall guidance 로 닫는다 (canonical source 가 곧 회복원).

따라서 세 우려가 각각 다른 방식으로 닫힌다: generated payload 의 atomicity 는 reinstall-first 로, managed-block instruction file 의 marker 밖 사용자 데이터 보호는 managed-block tooling 의 dry-run / pre-write backup / rollback / verification 으로, skill activation surface 의 적용은 canonical-overwrite (whole-file byte overwrite + post-write hash verify + read-only dry-run preview + overwrite 사전 고지) 로 닫힌다 — 어느 것도 하나의 transaction / rollback framework 로 묶지 않으며, canonical-overwrite class (generated payload / skill mirror 등) 에는 read-only dry-run preview 외의 backup / rollback / sidecar 를 두지 않는다.

## 10. Approval boundaries

다음 항목은 모두 explicit user-approved boundary 다. managed-block apply / skill adoption / 실제 mutation validation / operational smoke 는 install 과 무관한 별도 작업이 아니라 §2A operational install 의 **staged activation / verification / smoke phase** 이며 (install-pipeline automation 본체에는 포함되지 않는다). base payload phase 의 verify 가 그것들을 자동 승인하지는 않는다. 다만 **default operational install 에서는 이 phase 들이 §2A "Default install UX" 의 하나의 yes/no 로 한꺼번에 승인된다** — operator 는 payload phase 에서 멈추지 않고, surface / phase 별로 다시 묻지 않으며 그 단일 승인된 full plan 을 끝까지 수행한다. 별도 (개별) 승인이 필요한 것은 (a) 사용자가 **명시적으로 요청한** custom / partial install 의 범위, 그리고 (b) operational install phase 가 아닌 **project-specific adoption** (project-root managed-block / project-local skill) 뿐이다. 즉 "explicit approval 필요" 는 유지되되, default install 에서는 full plan 단위의 단일 yes/no 로 충족된다.

- **Global / user filesystem mutation** — 실제 `%USERPROFILE%\.claude\ai-harness-toolset\current\` materialize / refresh, `install.json` write, `%USERPROFILE%\.claude\` / `%USERPROFILE%\.codex\` 어느 경로의 write 도 **explicit user-approved global / user filesystem mutation scope** 다. 본 문서를 읽은 사실, operator 가 propose 한 사실, 어떤 자동화 trigger 의 fact 어느 것도 그 승인을 대체하지 않는다.
- **Managed-block apply** — managed-block insert / replace 는 install-pipeline automation 본체 **밖** 의 explicit user-approved 동작이며, destination 에 따라 operational install 과의 관계가 다르다. (i) **user-global** `%USERPROFILE%\.claude\CLAUDE.md` 와 Codex user-global `%USERPROFILE%\.codex\AGENTS.md` (또는 `%CODEX_HOME%\AGENTS.md`, Codex user-global `AGENTS.override.md`) 는 §2A operational install 의 **activation phase (phase 2)** 다 — default install 에서 이 변경은 §2A 의 단일 yes/no 에 포함되어 함께 승인되며, operator 는 payload phase 에서 멈추지 않고 surface 별 재질문 없이 적용한다. (ii) **project-root** `CLAUDE.md` / `AGENTS.md` 의 managed-block 은 operational install 의 phase 가 **아니라** §2A 가 분류한 project-specific adoption 이며, 별도 explicit user-approved 동작으로 처리한다 (target footprint = `<ProjectRoot>/log/` only 와 정합). 어느 destination 이든 base payload 의 verify 가 managed-block apply 를 자동 승인하지는 않으며, 전체 destination 의 marker 규칙은 아래 **"Managed-block apply 규칙"** 이 정의한다 (self-contained). `%USERPROFILE%\.claude\AGENTS.md` 는 어느 scope 에서도 valid destination 이 아니며, 본 도구는 그 path 를 생성하지 않는다.
- **Claude skill adoption** — `snippets/claude-skills/<name>/SKILL.md` 의 사용자 글로벌 환경 (`%USERPROFILE%\.claude\skills\<name>\SKILL.md`) 으로의 install / update / removal 은 install-pipeline automation 본체 **밖** 의 explicit user-approved 동작이지만, §2A operational install 의 **activation phase (phase 2)** 다. default install 에서 이 변경은 §2A 의 단일 yes/no 에 포함되어 함께 승인되며 (surface 별 재질문 없음), base payload verify 가 자동 승인하지 않는다.
- **Commit / push / publish / merge / release / target adoption** — install 의 verify 결과가 어떤 verdict 든, 이 작업들을 자동 승인하지 않는다. 모두 사용자가 별도의 명시 결정으로 처리한다. (이 항목들은 operational install completion 의 phase 가 **아니다.**)
- **실제 install / update / restore 의 validation 과 operational smoke** — actual `%USERPROFILE%\.claude\ai-harness-toolset\current\` 와 그 sibling artifact 들에 대한 실제 mutation 검증, 그리고 §2A 의 operational smoke 는 §2A operational install 의 **verification / smoke phase (phase 3–4)** 다. base payload 의 §5 verify 가 끝났다는 사실이 이 phase 를 자동 승인하지는 않으며, default install 에서 이 phase 들은 §2A 의 단일 yes/no 승인에 포함되어 수행된다 (phase 별 재승인 없음). operational install 에 필요한 smoke 는 §2A phase 4 의 (a) + (b) 가 전부다; 더 광범위한 smoke suite 는 본 minimal smoke 와 별개인 future scoped work 이며 install 실행에 필요하지 않다.

### Managed-block apply 규칙 (self-contained)

managed-block 적용에 필요한 규칙은 다음이 전부다 — 외부 docs 참조 없이 본 규칙만으로 적용한다. 적용 대상 managed block **본문**은 install artifact `snippets/CLAUDE_SNIPPET.md` (Claude) / `snippets/AGENTS_SNIPPET.md` (Codex) 가 제공하며, 두 snippet 은 자신의 marker 를 포함한다.

- **marker pair.** managed block 은 다음 두 줄 사이에 위치한다 — `<!-- BEGIN AI_HARNESS_TOOLSET_GLOBAL -->` (시작) 과 `<!-- END AI_HARNESS_TOOLSET_GLOBAL -->` (끝). 각 marker 는 자체 줄에 단독으로 있는 경우에만 marker 로 센다 — fenced code block (``` 또는 ~~~) 안의 동일 텍스트, inline code, prose 안에 인용된 동일 텍스트는 marker 로 세지 않는다.
- **destination 상태별 동작** (operator 는 inspect 로 destination 상태를 확인해 해당 case 의 구체 동작을 propose 에 명시한다 — **default operational install 에서는 그 동작이 §2A 단일 yes/no 에 포함되어 cover 되며 case 마다 별도 prompt 를 추가하지 않는다.** 별도 explicit 승인이 필요한 것은 default plan 밖의 동작, 즉 custom / partial 또는 project-specific adoption 일 때다):
  - destination file **부재** → 생성 동작을 propose 에 명시, 승인된 plan 적용 시 snippet 전체 (marker 포함) 기록.
  - file 존재 + matching marker pair **0 개** → 삽입 지점을 propose 에 명시, 승인된 plan 적용 시 snippet 전체 (marker 포함) 삽입.
  - file 존재 + matching marker pair **정확히 1 개** → diff propose, 승인 시 기존 BEGIN 줄부터 END 줄까지 (두 marker 줄 **포함**) 의 marker-bounded block 전체를 snippet (자체 BEGIN / END marker 포함) 으로 통째 1:1 치환한다. inner content 만 갈아끼우고 새 marked snippet 을 그 안에 넣는 것이 **아니다** — 그렇게 하면 marker 가 중첩되므로 금지한다. 결과는 항상 BEGIN / END pair 정확히 1 개를 유지한다.
  - marker pair 가 **불완전 (BEGIN / END 한쪽 누락) / 2 개 이상 / malformed (순서 위반) / nested** → **fail-fast.** 충돌을 보고하고 manual review 로 두며 파일을 편집하지 않는다.
- **first-time insertion 은 결정적 CLI 로 닫힌다 (수동 splice 아님).** 위 처음 두 case — destination file **부재** → 생성, file 존재 + matching marker pair **0 개** → 삽입 — 은 `scripts/apply-managed-block.ps1 -Insert` 가 결정적으로 수행한다 (부재 target 은 marker 1 pair 만 가진 새 file 생성, 0-pair target 은 기존 marker-밖 content 를 byte-for-byte 보존하며 snippet block 을 append). fresh install 진입점 `scripts/install-global.ps1` 이 activation bootstrap 단계에서 이 `-Insert` 를 호출하므로, operator 가 core library 를 직접 dot-source 하거나 snippet 을 손으로 끼워 넣을 필요가 없다. 세 번째 case — matching marker pair **정확히 1 개** → 1:1 치환 — 은 `scripts/apply-managed-block.ps1` 의 **default (replace) mode** 이며 `scripts/activate-global.ps1` (steady-state activation) 가 이를 구동한다. 두 mode 는 **상호 배타적**이다: `-Insert` 는 1-pair target 에서 fail-fast (replace 영역으로 안내) 하고, default(replace) 는 0-pair / 부재 target 에서 fail-fast 한다 — 이 분리가 replace-only semantics 를 깨지 않고 유지한다. 어느 mode 든 BOM 거부 / U+FFFD sentinel / `.amb-backup` (기존 target 일 때) / post-write 검증의 동일한 hardened IO 를 공유한다.
- **금지.** whole-file overwrite 금지. marker bounded block **바깥** 의 기존 사용자 / project 내용은 어떤 경우에도 보존하며 편집하지 않는다.
- **valid destination.** Claude: user-global `%USERPROFILE%\.claude\CLAUDE.md` 또는 project-root `CLAUDE.md`. Codex: user-global `%USERPROFILE%\.codex\AGENTS.md` (default) / `%CODEX_HOME%\AGENTS.md` (`CODEX_HOME` set 시) / 그 scope 의 `AGENTS.override.md` (둘 다 있으면 override 우선), 또는 project-root `AGENTS.md`. **forbidden:** `%USERPROFILE%\.claude\AGENTS.md` — 어느 agent 의 instruction 경로도 아니며 절대 생성하지 않는다.
- operational install (§2A phase 2) 의 activation 은 위 destination 중 **user-global** (Claude `%USERPROFILE%\.claude\CLAUDE.md`, Codex user-global `AGENTS.md`) 만 대상으로 한다. project-root destination 의 managed-block 은 동일 marker 규칙으로 적용하되 operational install phase 가 아니라 별도 explicit-approved project-specific adoption 이다.
- **dry-run preview (apply 전).** `scripts/activate-global.ps1` 를 `-Apply` 없이 실행하면 선택된 **모든 surface** 를 dry-run preview 한다 (target write 없음, backup 없음). managed-block surface (Claude / Codex) 는 기본적으로 **compact change summary** 를 낸다 — current/proposed block line count, 변하지 않은 prefix/suffix line count, changed window (`-current / +proposed`) 와 first differing line; managed block 전체 before/after dump 가 필요하면 `-ShowFullDiff` 를 붙인다 (activate-global → apply-managed-block 로 forward). canonical-overwrite surface (skill mirror) 는 **canonical-overwrite preview** 를 낸다 — source hash, destination hash (존재 시), `create | overwrite | unchanged` action, 그리고 변경이 있을 때 whole-file overwrite 사전 고지 (`-ShowFullDiff` 영향 없음). 실제 write 는 `-Apply` 일 때만 일어나며, `-Apply` 는 모든 surface 를 먼저 **preflight** 한 뒤에만 진행한다 (아래 "Activation apply orchestration"). (dry-run 출력 인코딩은 본 절의 범위가 아니다 — `[Console]::OutputEncoding` 은 바꾸지 않는다.)
- **`.amb-backup` rollback sidecar 의 lifecycle (현재 `scripts/apply-managed-block.ps1` 동작 기준).** `-Apply` 시 각 target 옆에 `<target>.amb-backup` 을 **write 직전에** 만든다 (rollback safety — 원본 bytes 보존). 이후 동작:
  - **성공 apply → backup 자동 삭제.** write + post-write block 검증이 통과하면 apply 가 그 `.amb-backup` 을 스스로 **제거** 한다 (happy path 는 backup 을 남기지 않는다). 따라서 정상 `-Apply` + verify_pass 뒤에는 보통 정리할 `.amb-backup` 이 **없다** — operator 가 따로 지울 대상이 남지 않는다.
  - **실패 시에만 잔존.** rollback 이 일어났는데 그 정리까지 실패했거나 (원본 bytes 가 backup 에 보존됨), apply 도중 프로세스가 죽었거나, 성공 경로의 best-effort 삭제 자체가 실패한 경우에만 `.amb-backup` 이 남는다. 즉 **남아 있는 `.amb-backup` 은 apply 가 깨끗하게 닫히지 않았다는 신호** 이며, 그 파일이 사용자의 원본 bytes 의 유일한 사본일 수 있다.
  - **다음 apply 는 기존 backup 을 발견하면 fail-fast.** `<target>.amb-backup` 이 이미 있으면 apply 는 그것을 **overwrite 하지 않고 refuse (exit 1)** 한다 (timestamped backup 이 아니라 고정 이름이므로 덮어쓰면 복구 사본이 사라진다) — operator 가 그 leftover 를 먼저 해소한 뒤 재-apply 한다.
  - **자동 cleanup 미도입.** 남은 `.amb-backup` 의 자동 삭제는 두지 않는다 (정상 확인 후 operator 가 수동으로 지운다). 본 Phase 는 backup 생성 / rollback 동작을 바꾸지 않으며 자동 cleanup 도 추가하지 않는다.

### Skill adoption 규칙 (self-contained)

skill 적용에 필요한 규칙은 다음이 전부다 — 외부 docs 참조 없이 본 규칙만으로 적용한다.

- **source / destination.** source = install artifact `snippets/claude-skills/<name>/SKILL.md`. operational install 의 destination = user-global `%USERPROFILE%\.claude\skills\<name>\SKILL.md`. (project-local `<ProjectRoot>/.claude/skills/<name>/SKILL.md` 는 project-specific adoption 으로 operational install phase 가 아니다.) 폴더 이름 `<name>` (예: `ai-harness-review`) 은 그대로 유지한다 — Claude Code 가 폴더 이름으로 skill 을 식별한다.
- **first install** (destination dir 부재): `%USERPROFILE%\.claude\skills` 부재 시 그 dir 생성도 skill activation 의 일부로 propose 목록에 포함한다 (default operational install 에서는 §2A 단일 yes/no 가 cover 하며 별도 prompt 를 추가하지 않는다) → 승인된 plan 적용 시 `<name>/` dir 생성 → `SKILL.md` 복사 (frontmatter 임의 수정 금지) → content 가 source 와 일치하는지 verify.
- **update** (destination 존재): source 와 hash 비교. 동일하면 변경 없음을 보고하고 중단. 다르면 diff propose → 승인 시 `SKILL.md` 전체 교체 (partial merge 금지) → hash 일치 verify. 사용자가 destination 을 수정해 두었다면 교체로 그 수정이 사라짐을 사전 고지.
- **removal**: 삭제 대상 `<name>/` dir 와 그 안의 파일 목록을 propose → 승인 시 그 dir 만 삭제 (dir 밖 파일 미삭제) → 부재 verify. source repo 의 `snippets/claude-skills/<name>/` 는 영향받지 않는다.

### Activation apply orchestration 규칙 (self-contained; Phase 4a)

`scripts/activate-global.ps1` 는 `update-source` / `verify` 가 검사하는 **activation surface 전부** (두 managed block + source skill 당 하나의 mirror) 를 적용하는 단일 explicit orchestrator 다 (apply coverage == verify coverage). apply 와 verify 는 동일한 surface resolver (`scripts/lib/activation-surface.ps1`) 를 공유하므로 destination 해석이 어긋나지 않는다.

- **두 mutation class.** managed-block surface (Claude `CLAUDE.md`, Codex effective `AGENTS.md` / `AGENTS.override.md`) 는 `scripts/apply-managed-block.ps1` 로 marker-bounded splice 한다 — marker 밖 사용자 content 보존, `.amb-backup` / rollback 은 그 primitive 안에만 존재. canonical-overwrite surface (skill mirror) 는 whole-file byte overwrite + post-write SHA-256 verify — merge 없음, marker parsing 없음, `.amb-backup` 없음, rollback 없음, backup sidecar 없음. 실패 시 fail-fast + report + reinstall guidance.
- **Codex `AGENTS.override.md` 우선순위.** `AGENTS.override.md` 가 있으면 apply 도 그 effective destination 을 대상으로 한다 (없으면 `AGENTS.md`). forbidden destination `%USERPROFILE%\.claude\AGENTS.md` 는 `.` / `..` 정규화 후 guard 가 거부하며 절대 쓰지 않는다.
- **default-safe dry-run.** `-Apply` 없이는 어떤 file 도 write 하지 않는다 (preview only). 실제 write 는 `-Apply` 일 때만, 그리고 **모든 선택 surface 의 preflight 가 통과한 뒤에만** 진행한다 (한 surface 라도 preflight 실패면 아무것도 쓰지 않는다).
- **missing destination.** managed-block destination file 이 없으면 — 이번 범위에서는 자동 생성하지 않고 fail/report 한다 (생성은 별도 explicit boundary; apply-managed-block 이 target 부재를 fail 로 보고). skill mirror (canonical artifact) 는 부재 시 destination + 부모 dir 생성을 정상 `create` action 으로 수행한다.
- **approval = command-implied (primary).** `-Apply` 호출 자체가 그 명시 결정이다 — natural-language update 가 activation apply 를 자동으로 imply 하지 않으며, `update-source` 가 activate-global 을 자동 호출하지 않는다 (activation apply 는 항상 별도 explicit step). 직접 터미널 운영자가 추가 confirm 을 원하면 `-ConfirmInteractive` 로 **정확히 두 선택지 (Yes / No)** selector 를 켤 수 있다 (제3 선택지 / multi-choice menu 없음; default highlight Yes 이나 Enter 필수; timeout auto-yes 없음). `-ConfirmInteractive` 인데 interactive terminal 이 없으면 apply 로 silent fall-through 하지 않고 중단한다.
- **no cross-surface transaction.** surface 별 semantics 다 — preflight-all-then-apply 이후 surface 별로 적용하고, managed-block 은 apply-managed-block 의 per-surface rollback 을, canonical-overwrite 는 no-rollback fail-fast 를 따른다. 부분 적용 결과는 per-surface result + aggregate `activationStatus` 로 정직하게 보고하며 cross-surface 전체 rollback 은 구현하지 않는다.
- **`-Scope`.** `Claude` / `Codex` / `Skill` / `All` (default `All` = 모든 surface; `Skill` = 모든 source skill mirror). per-surface result 와 aggregate `activationStatus` 를 출력한다.
- **`activationStatus` vocabulary (activate-global 자체 출력).** `preview` (dry-run, 전 surface valid; exit 0) / `applied` (apply, 전 surface verify ok; exit 0) / `activation_applied_verify_failed` (apply 시도 후 한 surface 라도 post-apply write/verify 실패; exit 1) / `failed` (preflight / forbidden / source 부재 — 아무것도 write 안 함; exit 1) / `activation_aborted_no_approval` (`-ConfirmInteractive` 인데 Yes 아님 / terminal 부재; exit 1). 이 vocabulary 는 activate-global 의 출력이며 `install-update.ps1` 의 machine status / stdout JSON contract (§13) 와 별개다 — install-update 의 vocabulary 와 JSON 은 본 Phase 에서 바뀌지 않는다 (§13.1 의 `activation_applied_verify_failed` 는 본 orchestrator 가 emit 하는 것으로 갱신).

## 11. Out of scope

본 install-pipeline automation 본체는 두 class 를 명확히 구분한다. (a) "여전히 out of scope" 의 productization / framework class 는 본 도구의 self-imposed boundary 로 default 로 제공되지 않으며, 그 도입은 별도 scoped approval 의 일이다. (b) "허용" class 의 narrow deterministic entrypoint 는 본 contract 안에서 허용된다. (a) 와 (b) 는 서로 mutually exclusive set 이며, (b) 의 entrypoint 가 (a) 의 framework 로 자라지 않는다는 self-imposed boundary 가 본 절 안에 codify 되어 있다.

본 문서의 존재만으로 (a) class 의 어느 항목도 자동 승인 / 작성되지 않는다. 주의: managed-block apply / skill adoption / smoke 는 §2A operational install 의 staged phase 이므로 out-of-scope 가 **아니다** — 본 절에서 out-of-scope 인 것은 그것의 *자동 (무승인)* 적용과 아래 (a) 의 productization / framework 항목이다.

### (a) 여전히 out of scope (productization / framework class)

- 대형 installer / setup framework. recovery / repair / doctor / fix-* framework. install linter / verifier framework / health-check tool (productization class 전체). 대형 / interactive **uninstaller framework**, uninstall wizard, teardown doctor/repair 도 본 productization class 로 out-of-scope 다 (구현된 narrow deterministic uninstall entrypoint 는 (b) 참조 — 그 narrow entrypoint 가 본 framework class 로 자라지 않는다는 §11 self-imposed boundary invariant 가 적용된다).
- one-liner magic installer / interactive wizard with many choices / multi-option setup UI.
- daemon / watcher / scheduler / hook / background task.
- generated payload 에 대한 transaction log / rollback framework / tamper detection / partial-state reconciliation. generated payload 의 materialization atomicity / partial state 는 §9 / §9.1 의 reinstall-first 로 닫힌다. (managed-block instruction file 의 dry-run / pre-write backup / rollback / verification 은 §9.1 / §10 의 managed-block tooling 영역, canonical-overwrite surface 인 Claude skill mirror 의 whole-file overwrite + hash verification + read-only dry-run preview 는 §9.1 / §10 의 activation apply orchestration 영역으로 각각 별개이며, 본 out-of-scope 항목과 혼동하지 않는다. canonical-overwrite class (skill mirror 등) 에는 read-only dry-run preview 외의 pre-write backup / rollback / sidecar 를 두지 않으며, activation apply 도 cross-surface transaction / rollback framework 로 묶지 않는다.)
- helper / convenience wrapper script 의 productization (자동 PATH 등록, 시스템-와이드 alias, 자동 PATH mutation, system-wide CLI installer).
- install metadata schema 본문 변경 / migration writer.
- CI / release / packaging pipeline.
- automatic global filesystem mutation, automatic managed-block apply, automatic skill refresh. (staged + 명시 승인된 형태의 managed-block apply / skill adoption 은 §2A operational install 의 activation phase 로 수행된다 — out-of-scope 인 것은 그것의 *자동 (무승인)* 적용이다.)
- automatic target project update, automatic commit, automatic push, automatic publish, automatic merge, automatic release.

### (b) 허용 (deterministic narrow entrypoint class)

- **read-only inspect / verify mode** 를 제공하는 source-controlled install/update entrypoint (`scripts/install-update.ps1`). inspect / verify 는 어떤 file 도 write 하지 않는다 — no payload write, no managed-block write, no skill mirror write, no run evidence global write.
- **`update-source` mutation mode** (구현됨, future 아님). `scripts/install-update.ps1 -Mode update-source -InstallArea <area>` 는 canonical pipeline (`New-InstallPipelineTuple` action=`update-source` → `Invoke-InstallPipelineDispatch`) 으로 InstallArea 의 payload (`current/` + `install.json` + `payload-manifest.json` + `payload-marker.json`) 를 deterministic 하게 다시 쓴다 — `installedHead` / `installedAt` 보존, `lastUpdatedHead` / `lastUpdatedAt` 갱신. 이 mutation 의 승인은 **command-implied approval 이 primary** 다 (§7.1.1 / §13.8): operator 의 명시 update-source 호출 (사용자 명시 update 지시 + read-only plan-report 위에서) 이 승인 surface 이며, terminal selector 는 `-ConfirmInteractive` 의 optional 보조 경로다. update-source 는 activation surface (managed block / skill mirror) 를 **write 하지 않는다** — byte-identity 로 verify 만 하며, 실제 activation apply 는 `scripts/activate-global.ps1` + `scripts/apply-managed-block.ps1` 의 별도 explicit 단계다 (§10 / §2A phase 2).
- **Fresh-install / update lifecycle entrypoint split (구현됨, IU-B-09).** lifecycle 진입점을 이름으로 구분한다 — `scripts/install-global.ps1` (fresh global install; §6.1), `scripts/update-global.ps1` (기존 install update operator-facing wrapper; §7.1.1), `scripts/uninstall-global.ps1` (uninstall; 아래 bullet). `install-global.ps1` 은 canonical pipeline (`New-InstallPipelineTuple` action=`install` → `Invoke-InstallPipelineDispatch` → `Invoke-InstallPipelineVerify`) 으로 fresh payload 를 materialize 하고, activation bootstrap 을 `scripts/apply-managed-block.ps1 -Insert` (Claude / Codex managed block first-time 삽입) + skill mirror canonical-overwrite 로 닫은 뒤 `install-update.ps1 -Mode verify` = `verify_pass` 로 검증한다 — 기존 install 이 있으면 overwrite 하지 않고 fail-fast (clean-reinstall/overwrite 옵션 없음). `update-global.ps1` 은 `install-update.ps1 -Mode update-source` 로 delegate 하는 thin wrapper 다 (update-source 로직 재구현 없음; install area 부재/invalid 시 `install-global.ps1` 로 안내). 이는 update polishing 과정에서 deterministic CLI 로 닫히지 않게 된 fresh-install bootstrap 경로의 **regression 복구**이며, 새 productized installer framework 가 아니다 (§11 self-imposed boundary invariant — 좁은 단일-목적 유지, (a) 의 mega installer / wizard / doctor 로 자라지 않음).
- **First-time managed-block insertion primitive (구현됨, IU-B-09).** `scripts/apply-managed-block.ps1 -Insert` 와 pure primitive `Add-ManagedBlock` (`scripts/lib/managed-block.ps1`) 은 0-pair / 부재 target 에 대한 first-time 삽입을 결정적으로 수행한다 (부재 → marker 1 pair 새 file 생성, 0-pair → marker-밖 content byte-for-byte 보존 + append, 1-pair → fail-fast 후 replace 안내). default(replace) mode 의 replace-only semantics 는 그대로다 — `-Insert` 와 default 는 상호 배타 (서로의 영역에서 fail-fast) 이며 동일 hardened IO (BOM 거부 / U+FFFD sentinel / `.amb-backup` / post-write 검증) 를 공유한다. 이는 full uninstall 후 0-pair clean reinstall 의 first-time 삽입을 수동 operator splice 가 아니라 결정적 tooling 으로 닫는다 (아래 uninstall bullet 의 discovered boundary 해소).
- fixed-vocabulary final status 의 stdout emit. status enumeration 과 그 의미는 §13 본문에 codify 된다.
- run evidence contract (§13). evidence shape / status vocabulary 의 docs codification 은 본 contract 안에 포함되며, **run evidence file 의 글로벌 install path 실제 write 는 아직 future scoped batch 영역** (현재 stdout JSON 만; §13.4).
- 미도입 mutation flag (`-ApplyActivation`, `-ApplyPayload`, `-RefreshSkill`) 은 reserved-but-unimplemented 이며 entrypoint 의 production guard 가 그 flag 의 우발적 wiring 을 fail-fast 거부한다. 그 도입은 별도 scoped approval 의 일이며 각 mutation 은 §10 Approval boundaries 와 정합해야 한다.
- **Uninstall / teardown narrow entrypoint (구현됨, IU-B-08 batches 1–3).** global ai-harness footprint 를 zero 로 되돌리는 standalone deterministic uninstall entrypoint `scripts/uninstall-global.ps1` (install/update flow 와 섞지 않은 별도 entrypoint; `install-update.ps1` 의 새 mode 가 **아니다**) 이 본 (b) deterministic narrow entrypoint class 로서 **구현돼 있다**. 구성: pure `Remove-ManagedBlock` primitive (`scripts/lib/managed-block.ps1`, batch 1) + read-only dry-run target resolver (`scripts/lib/uninstall-target.ps1`, batch 2) + destructive `-Apply` + self-contained 임시 finalizer (`scripts/uninstall-finalizer.ps1`, batch 3). 각 batch 는 별도 scoped 작업 + Codex review gate 로 닫혔다. 설계 + as-built 기준은 install-update 시스템 design doc `UNINSTALL_LIFECYCLE_DESIGN.md` (repo-only background; 배포 payload 에 포함되지 않는 install-update systems 문서) 다. **isolated non-primary machine `-Apply` dogfood 는 통과(cleared)** — 실제 `%USERPROFILE%` install 에 대한 `-Apply` + footprint-zero 검증 + clean reinstall 이 **isolated non-primary machine 에서만** 수행됐고 (dry-run `uninstall_preview` blocked=0/warn=0/wouldRemove=9 → `-Apply` exit 0 → finalizer `status=uninstalled` → reinstall `verify_pass`), **primary work machine 은 (이 isolated-machine dogfood 시점 기준) mutate 되지 않았으며 primary-machine 실제 `-Apply` 는 별도 explicit approval boundary 다.** (Update — 이후 main PC 에서 IU-15 main PC lifecycle retest 로 실제 `-Apply` 가 explicit per-action 승인 하에 수행·cleared 됐다: STATUS ledger IU-15; full narrative 는 git history 에 보존. per-environment 별도-승인 boundary 는 불변 — 한 환경 통과가 다른 환경 apply 를 승인하지 않는다.) dogfood 가 드러낸 운영상 경계: uninstall 은 marker pair 를 **완전히 절제**하므로 (footprint-zero = 0 pair), full uninstall **이후** 의 clean reinstall 은 activation tooling 의 steady-state 1-pair 치환이 아니라 **0-pair → first-time managed-block 삽입** case (위 "Managed-block apply 규칙" 의 *marker pair 0 개 → 삽입* 분기) 로 진입한다 — `activate-global.ps1` / `apply-managed-block.ps1` (**default replace mode**) 는 기존 1 pair 만 치환하고 (`Set-ManagedBlock` 이 0-pair 에서 fail-fast), first-time 삽입은 별도 explicit user-approved 동작이다 — **이 first-time 삽입은 IU-B-09 이후 `scripts/apply-managed-block.ps1 -Insert` / fresh-install 진입점 `scripts/install-global.ps1` 으로 결정적으로 닫힌다** (수동 operator splice 가 아니라 결정적 tooling; 여전히 explicit install 승인 하에 수행). 즉 위 dogfood 가 드러낸 "post-uninstall 0-pair reinstall 의 first-time 삽입이 자동화되지 않음" boundary 는 IU-B-09 에서 해소됐다. 핵심 골격: (i) 성공 기준 = global footprint zero (install root 부재 + skill mirror dir 부재 + 두 instruction file 의 marker pair 0개; non-target 미접촉), (ii) installed payload **안에서** uninstall 이 시작될 수 있으므로 apply mode 는 **temp finalizer trampoline** — main entrypoint 는 preflight + managed-block removal + skill mirror removal + temp finalizer 생성/launch 까지만, temp finalizer 는 parent process 종료 대기 후 global install root 삭제 + 부재 verify (finalizer 자기 cleanup 은 best-effort, 실패 시 exact temp path 보고), (iii) managed-block 은 file 삭제가 아니라 marker span 만 제거하고 marker 밖 content 보존 (`Resolve-ManagedBlockSpan` 재사용; 0 pair=no-op / 1 pair=절제 / 2+·malformed=fail-fast), (iv) install root 제거는 broad blind delete 가 아니라 expected-footprint enumeration + unexpected-content fail-fast, (v) dry-run/apply/verify 분리 + failure policy 의 두 tier — preflight 에서 정적으로 탐지되는 조건 (malformed/ambiguous marker, unexpected install-root content, 기존 `.amb-backup`) 은 preflight-all-then-act 로 whole apply 를 차단하고, partial (per-surface, no cross-surface transaction) 은 preflight 통과 후 runtime 실패에서만 발생. project-local `<ProjectRoot>/log/`, source repo / ToolRoot clone, sibling skills, marker-outside instruction content 는 명시적 비대상이다. 본 entrypoint 는 좁고 단일-목적으로 유지되며 (a) 의 대형 / interactive uninstaller framework 로 자라지 않는다 (§11 self-imposed boundary invariant). 실제 `-Apply` 의 user/global 환경 실행은 위에 적은 대로 별도 explicit approval boundary 이며, isolated-machine dogfood 통과 후에도 primary work machine 의 실제 `-Apply` 는 각 환경마다 별도 명시 승인을 요구한다 (한 환경의 dogfood 통과가 다른 환경의 apply 를 승인하지 않는다).

### Self-imposed boundary 의 invariant

(b) class 의 entrypoint 는 (a) class 의 framework 로 자라지 않는다. 본 entrypoint 에 (a) 의 wizard / rollback / doctor / package-manager 동작이 추가 도입되면 그 도입은 본 §11 의 narrow scope 를 침범하므로 별도 scoped approval + 본 §11 자체의 재정의가 prerequisite 다. 본 boundary 의 침식을 막기 위해 entrypoint 의 production guard (미도입 mutation flag 의 명시 거부 helper + update-source 의 §7.1.1 hard guards) 와 fixed-vocabulary status (§13) 가 source-side mechanism 으로 함께 동작한다.

위 (a) 항목 중 어느 것도 본 도구에서 default 로 제공되지 않는다. 그 도입은 별도 scoped approval 의 일이다.

## 12. docs/ 는 install-time input 이 아니다 (background only)

본 INSTALL.md 는 install / update / reinstall / operational install 을 수행하기 위한 self-contained operative contract 다 (상단 anti-coupling 절 참조). repo 의 `docs/` 트리 — `docs/roadmap/**`, `docs/user_guide/OPERATOR_GUIDE_KR.md` 등 — 는 model / decision 의 history / design / background material 일 뿐 **install-time input 이 아니다.** 본 절은 "install 중 읽어야 할 reference 목록" 이 아니다.

- install 실행 중 그 문서들을 읽을 필요가 없고, 읽어서 install 동작을 결정하지 않는다. 사용자가 명시적으로 design / background review 를 요청한 경우에만 연다 (install 실행이 아니라 별도 review 작업).
- 그 문서들이 stale / 누락 / rename / 삭제되어도 install semantics 는 본 INSTALL.md 본문이 전적으로 결정한다.
- 어떤 `docs/` 파일도 본 INSTALL.md 를 override 하지 않으며 install source-of-truth 가 아니다. install source-of-truth 는 본 INSTALL.md 하나다. (background 문서가 자신을 "model source-of-truth" 라 칭하더라도 그것은 그 model 문서들 사이의 우선순위를 가리킬 뿐 install 실행 authority 를 가지지 않는다.)
- 본 문서가 참조하는 실제 install artifact 는 `scripts/` / `snippets/` / `templates/` (적용 대상 payload) 뿐이며, 이는 docs coupling 이 아니다.

## 13. Run evidence and final status vocabulary

본 절은 §11 (b) 의 deterministic narrow entrypoint (`scripts/install-update.ps1`) 가 emit 하는 final status vocabulary 와 run evidence 의 contract 를 정의한다. 본 contract 는 self-contained — 외부 docs 참조 없이 본 절만으로 implementation 이 결정된다. `inspect` / `verify` / `update-source` 는 본 status vocabulary 를 실제 emit 한다. 다만 run evidence **file** 의 글로벌 install path 에 대한 actual write 는 아직 별도 future scoped batch 영역이며, 현재는 stdout JSON (§13.4 의 strict subset) 만 emit 한다.

### 13.1 Final status vocabulary

entrypoint 가 stdout 으로 emit 하는 final status 는 다음 enumeration 의 단일 값으로만 한다. 새 status 가 필요한 경우 본 절 + entrypoint + Pester 회귀 lock 이 함께 갱신되어야 한다.

| Status | Mode | Terminal | 의미 |
|---|---|---|---|
| `inspect_clean` | inspect | yes | source HEAD == `install.json.lastUpdatedHead` AND `payload-manifest.json.head` == `payload-marker.json.head` == `install.json.lastUpdatedHead` (cross-binding ok) AND managed root README (§7.3) 가 byte-identical (template-conditional — payload 에 template 이 있을 때만 검사) AND 모든 activation surface (두 managed block + source skill 당 하나의 mirror) 가 destination 에 존재 + byte-identical 한 상태. 어느 하나라도 fail 이면 본 status 가 아니다. |
| `inspect_payload_drift` | inspect | yes | manifest / marker / install.json 의 cross-binding 불일치, `current/` payload root 부재, **또는 managed root README (§7.3) 의 missing / stale / corrupt** (managed install artifact integrity 실패). 회복은 §9 reinstall-first deterministic overwrite (no-op self-heal 아님; reasons 가 reinstall-first 를 안내). |
| `inspect_source_drift` | inspect | yes | source HEAD ≠ `install.json.lastUpdatedHead` (update 후보). |
| `inspect_activation_drift` | inspect | yes | activation surface 부재 / byte-mismatch / read-error. reasons array 의 각 entry 가 surface 이름 + class (`absent` / `byte-mismatch` / `read-error`) 명시. |
| `inspect_mode_unknown` | inspect | yes | install.json 부재 / schema mismatch / unknown schemaVersion. |
| `verify_pass` | verify | yes | 14-field schema ok + manifest digest ok + cross-binding ok + managed root README (§7.3) byte-identity ok (template-conditional — payload 에 template 이 있을 때만 검사) + 모든 activation surface (두 managed block + source skill 당 하나의 mirror) byte-identical. 어느 하나라도 fail 이면 `verify_failed`. |
| `verify_failed` | verify | yes | cross-binding, manifest digest, managed root README (§7.3) integrity (missing / stale / corrupt), 또는 activation byte-identity 어느 하나라도 fail. reasons array 에 구체 reason 명시. |
| `noop_already_current` | update-source | yes | source HEAD == `lastUpdatedHead`, payload 정합, activation 정합. mutation 불필요 — 승인 prompt 없이 no-op 종료. |
| `complete` | update-source | yes | payload update + post-apply verify ok + activation byte-identical (verify-only no-op) + cleanup ok + smoke ok/skip. 모든 단계가 닫혔을 때만. |
| `activation_pending` | update-source | yes | payload 는 갱신됐으나 (또는 payload 가 이미 current 인데) activation surface 가 byte-identical 이 아님. update-source 는 activation 을 apply 하지 않으므로 (별도 explicit 단계) `complete` 로 보고하지 않는다. |
| `activation_applied_verify_failed` | activate-global (§10) | yes | activation apply 후 한 surface 라도 post-apply write/verify 실패 — Phase 4a 부터 `scripts/activate-global.ps1` (generic activation orchestrator) 가 emit 한다. managed-block surface 는 `apply-managed-block.ps1` 이 rollback 후, canonical-overwrite surface (skill mirror) 는 rollback 없이 overwrite 된 상태로 보고하며 reinstall guidance 를 준다. preflight 실패로 **아무것도 write 안 한** `failed` 와 구별된다 (write 가 시도된 후의 미검증 상태). `update-source` 는 activation 을 apply 하지 않으므로 이 status 를 emit 하지 않는다 (verify-only → `activation_pending`). activate-global 의 전체 `activationStatus` vocabulary (`preview` / `applied` / `activation_applied_verify_failed` / `failed` / `activation_aborted_no_approval`) 와 그 exit code 는 §10 "Activation apply orchestration 규칙" 에 정의되며 `install-update.ps1` 의 stdout JSON contract (§13.4) 와 별개다. |
| `smoke_failed` | update-source | yes | operational smoke 실패 (§13.7). |
| `cleanup_failed_with_leftover` | update-source | yes | run-scoped work area cleanup 실패 (leftover paths 존재). user approval prompt 로 전환 금지 — 본 status + `leftoverPaths` 로 보고. |
| `update_aborted_no_approval` | update-source | yes | `-ConfirmInteractive` 가 켜진 상태에서 two-choice confirm 이 Yes 가 아니었거나 (No / Esc) interactive terminal 이 없어 confirm 을 받을 수 없었음. mutation 미수행. (default command-implied 경로에서는 발생하지 않는다 — §13.8.) |
| `failed` | any | yes | 위 어느 분류에도 해당 안 되는 일반 실패 (예: metadata 부재, source HEAD resolve 실패, source-cut 감지). |

### 13.2 핵심 invariants

- **"payload updated 이나 activation 미적용" 은 `complete` 로 보고 금지** → `activation_pending`. update-source 가 mechanical 하게 enforce 한다 (activation surface — 두 managed block + source skill 당 하나의 mirror — 중 하나라도 byte-mismatch 면 `activation_pending`).
- **cleanup 실패는 user approval prompt 로 전환 금지** → `cleanup_failed_with_leftover`. `leftoverPaths` 에 정리 미완료 path 열거.
- **verify fail 은 `complete` 로 보고 금지** → `verify_failed`.
- **mutation 은 explicit approval surface 위에서만** → default 는 command-implied approval (operator 의 명시 update-source 호출 + 사용자 명시 update 지시 + plan-report; §13.8). hard guards (source-cut / metadata-unknown / identity / destination / resolve-failure) 위반 시 `failed` 로 mutation 차단 — command 가 우회 못 한다. `-ConfirmInteractive` 사용 시 confirm 이 Yes 가 아니거나 terminal 부재면 `update_aborted_no_approval` (mutation 미수행).
- **command-implied 적용 범위 한정** → 기존 identity-consistent install 의 update-source 에만 적용. fresh install / 새 destination 생성 / activation apply 자동화 / source-cut override 에는 적용되지 않는다 (§7.1.1).
- **status 는 단일 terminal value** — 한 run 에 두 status 를 emit 하지 않는다 (§13.9 precedence).
- **`activation_pending` / activation-only `verify_failed` 는 payload corruption 을 의미하지 않을 수 있다 (I03 docs 명료화).** payload integrity (14-field schema + manifest digest + cross-binding) 와 activation byte-identity (두 managed block + source skill 당 mirror) 는 **별개의 검사축** 이다. `update-source` 가 `activation_pending` 을 emit 하거나 `verify` 가 오직 activation surface byte-mismatch 때문에 `verify_failed` 를 emit 한 경우, base payload 는 정합 (`payload-manifest.json.head` == `payload-marker.json.head` == `install.json.lastUpdatedHead`) 일 수 있고 남은 것은 별도 activation apply (§2A phase 2 / §10) 라는 **follow-up 단계** 뿐이다. 즉 `verify_failed` / `activation_pending` + exit 1 이 항상 "payload 가 깨졌다" 를 뜻하지는 않는다 — `reasons` array 가 어느 축이 미충족인지 명시하므로, payload-축 reason 없이 activation-축 reason 만 있으면 payload 는 OK 이고 activation follow-up 만 필요한 상태다. (payloadStatus / activationStatus 같은 별도 top-level field 분리, activation-only drift 의 exit-code 변경은 behavioral schema change 이므로 별도 later phase 결정으로 남긴다 — 본 invariant 는 docs 명료화이며 status / exit-code semantics 를 바꾸지 않는다.)
- **`activation_pending` 의 human output 은 hard failure 가 아니라 follow-up 으로 보인다 (Phase 3.6; human-output-only).** machine status (`activation_pending`) 와 exitCode (`1`) 는 그대로지만, human 보고는 그것을 INCOMPLETE follow-up 으로 명확히 한다: `followUpRequired=activation` / `payload=ok` / `activation=pending` / `result=INCOMPLETE (payload OK; activation follow-up required)` 를 출력하고, 최종 human label 도 `FAIL` 이 아니라 `INCOMPLETE (payload OK; activation follow-up required)` 다 (`verify_failed` / `smoke_failed` / `cleanup_failed_with_leftover` / `failed` / `update_aborted_no_approval` 은 그대로 `FAIL`). 또한 activation drift 가 있는 `activation_pending` 일 때만, 복붙 가능한 **exact next command** 를 출력한다 — installed context 기준 `<InstallArea>\current\scripts\activate-global.ps1` 로, dry-run preview (`-Scope All`) 와 apply (`-Scope All -Apply`) 두 줄. 이 command 는 global/user instruction file 을 **mutate** 한다는 점 (managed-block surface 는 `.amb-backup` rollback backup 생성, skill mirror 는 backup 없는 whole-file canonical-overwrite) 을 명시하며, update-source 가 자동 실행하지 않는다 (별도 explicit step; §2A phase 2 / §10). 이 항목은 human output 과 final label 만 바꾸며 status / exitCode vocabulary 와 machine JSON 은 바꾸지 않는다.
- **평가되지 않은 inspect/verify diagnostic 을 `false`/`null` 로 emit 금지 (I01).** `update-source` 의 stdout JSON 은 inspect/verify diagnostic field (`installState` / `metadataValid` / `manifestMarkerCrossBindingOk` 등) 을 **실제 post-apply 평가값** 으로만 emit 하고, apply 가 평가하지 않은 field 는 `false` / `null` default 로 채우지 않고 **생략** 한다. 따라서 `complete` / `activation_pending` / `noop_already_current` 옆에 `metadataValid:false` / `manifestMarkerCrossBindingOk:false` / `installState:null` 같은 오해성 default 신호가 나타나지 않는다 (성공 / 후속 status 는 실제 `present` / `true` 값을 emit). `inspect` mode 는 항상 전체 diagnostic group 을 평가하므로 영향받지 않는다.
- **`leftoverPaths` 는 항상 JSON array (I12).** empty 여도 `{}` 가 아니라 `[]` 로 직렬화한다 — PowerShell 5.1 의 if-expression empty-array 직렬화 quirk (`$body['leftoverPaths'] = if (...) {} else {}` 가 empty 를 `{}` 로 만든다) 를 피하기 위해 branch-local 할당을 쓴다.

### 13.3 Exit code mapping

| Status class | Exit code |
|---|---|
| `inspect_clean`, `verify_pass`, `noop_already_current`, `complete` | 0 |
| `inspect_payload_drift`, `inspect_source_drift`, `inspect_activation_drift`, `inspect_mode_unknown` | 0 (drift 분류는 inspect 의 정상 결과; script 자체는 성공) |
| `verify_failed`, `activation_pending`, `activation_applied_verify_failed`, `smoke_failed`, `cleanup_failed_with_leftover`, `update_aborted_no_approval`, `failed` | 1 |

### 13.4 Run evidence contract — `run.json` schema

본 contract 단계에서 entrypoint 는 **run evidence 를 file 로 write 하지 않는다** — run evidence 는 stdout JSON 으로만 emit 된다 (update-source 의 payload mutation 은 별개이며 §13.6 참조). **stdout JSON body 는 future `run.json` 의 strict field-name subset** 이다 — stdout 이 emit 하는 field 이름은 모두 아래 `run.json` schema 에 존재하며, `run.json` 은 그 위에 (a) lifecycle field (`runId` / `startedAt` / `finishedAt`) 와 (b) update-source stdout 이 emit 하지 않는 나머지 mutation-outcome field (`payloadUpdated` / `activationRequired` / `activationApproved` / `activationApplied` / `managedBlockVerified` / `skillMirrorVerified` / `cleanup`) 를 추가한다. inspect / verify mode 의 stdout 은 (a)(b) 와 update-source apply-outcome (`leftoverPaths` / `smoke`) 를 모두 emit 하지 않으므로 진부분집합 (proper subset) 이다. future run evidence file 의 write destination path 는 글로벌 install layer 안의 `%USERPROFILE%\.claude\ai-harness-toolset\log\install-update\<runId>\run.json` 이며, 실제 디렉터리는 본 contract 단계에서 생성되지 않는다.

#### 13.4.1 `run.json` shape (future write; placeholder runId 만 example 으로 cite)

field 는 세 group 으로 나뉜다 — **core** (모든 mode 의 stdout + run.json 공통), **inspect/verify diagnostic** (inspect/verify mode 의 stdout + run.json), **run.json-only** (lifecycle + mutation-outcome; stdout 미포함).

```json
{
  "schemaVersion": 1,
  "tool": "ai-harness-toolset",
  "mode": "inspect | verify | update-source | activation-apply | restore",
  "installAreaPath": "<resolved-absolute-path>",
  "status": "<one of §13.1 enumeration>",
  "exitCode": 0,
  "reasons": [],

  "installState": "present | absent | partial | null",
  "metadataValid": false,
  "installMode": "git-url | local-clone | null",
  "lastUpdatedHead": "<sha-or-null>",
  "sourceResolvedHead": "<sha-or-null>",
  "payloadDeltaRequired": false,
  "manifestMarkerCrossBindingOk": false,
  "activationSurfaces": [
    { "name": "<surface-name>", "path": "<dest-path>", "exists": false, "byteIdentical": false, "reason": "<null|absent|byte-mismatch|read-error>" }
  ],

  "runId": "<YYYYMMDDTHHmmssZ>-<short-sha>",
  "startedAt": "<UTC-ISO-8601>",
  "finishedAt": "<UTC-ISO-8601>",
  "branch": "<branch-or-null>",
  "remote": "<remote-or-null>",
  "payloadUpdated": false,
  "activationRequired": false,
  "activationApproved": false,
  "activationApplied": false,
  "managedBlockVerified": false,
  "skillMirrorVerified": false,
  "smoke": "pass | fail | skip | null",
  "cleanup": "pass | fail | skip | null",
  "leftoverPaths": []
}
```

- **core group** (`schemaVersion`, `tool`, `mode`, `installAreaPath`, `status`, `exitCode`, `reasons`): inspect / verify mode 의 stdout JSON 과 run.json 둘 다 emit.
- **inspect/verify diagnostic group** (`installState`, `metadataValid`, `installMode`, `lastUpdatedHead`, `sourceResolvedHead`, `payloadDeltaRequired`, `manifestMarkerCrossBindingOk`, `activationSurfaces`): inspect mode stdout 은 전부, verify mode stdout 은 `activationSurfaces` (+ core) 를 emit. run.json 도 이 group 을 포함한다. `lastUpdatedHead` 는 `install.json.lastUpdatedHead` (현재 installed identity), `sourceResolvedHead` 는 resolve 된 source HEAD 다.
- **run.json-only group** (`runId`, `startedAt`, `finishedAt`, `branch`, `remote`, `payloadUpdated`, `activationRequired`, `activationApproved`, `activationApplied`, `managedBlockVerified`, `skillMirrorVerified`, `cleanup`): future write 시점의 lifecycle + mutation-outcome. inspect / verify mode 의 stdout 은 이 group 을 emit 하지 않는다.
- **update-source apply-outcome (stdout 포함)**: `update-source` mode 의 stdout 은 core + inspect/verify diagnostic group 의 **평가된 subset** 에 더해 `leftoverPaths` 와 `smoke` 를 emit 한다. diagnostic field 는 apply 가 실제로 평가한 것만 real post-apply 값으로 emit 하고, 평가하지 않은 field (예: guard-failure 경로) 는 `false` / `null` 로 채우지 않고 생략한다 (§13.2 I01 invariant). `leftoverPaths` 는 empty 여도 항상 JSON array `[]` 로 emit 하며 (§13.2 I12), `cleanup_failed_with_leftover` 의 §13.2 invariant 가 현재 evidence surface (stdout JSON) 에서 구조적으로 충족되도록 한다. `leftoverPaths` / `smoke` 두 이름 모두 위 run.json schema 에 존재하므로 stdout 의 strict field-name subset 관계는 유지된다 (나머지 run.json-only group 은 stdout 미포함).
- `schemaVersion = 1`. unknown schemaVersion 은 fail-fast — silent downgrade 금지 (§4 standing rule 와 정합).
- `runId` 는 placeholder shape `<YYYYMMDDTHHmmssZ>-<short-sha>` 다. 본 절에는 concrete literal runId 를 cite 하지 않는다 — implementation 시점에 runtime 으로 합성된다.
- `activationSurfaces` 의 각 entry 는 `{ name, path, exists, byteIdentical, reason }` 다 — §13.1 의 activation byte-identity 분류 (Claude managed block / Codex managed block / skill mirror) 가 emit 하는 surface-level 결과다. Codex managed block 의 `path` 는 `AGENTS.override.md` 가 존재하면 그 effective destination 을 가리킨다 (§10 valid-destination precedence).

### 13.5 Run evidence 의 위상 invariants

- **`run.json` 은 evidence 일 뿐 source-of-truth 가 아니다.** install 의 source-of-truth 는 §4 의 `install.json` / `payload-manifest.json` / `payload-marker.json` cross-binding (`payload-manifest.json.head` == `payload-marker.json.head` == `install.json.lastUpdatedHead`) 이다. `run.json` 의 `status` 가 cross-binding 의 정합 검증을 대체하지 않는다.
- **`run.json` 은 append-only / write-once per run-dir.** 한 run 의 `run.json` 이 write 된 뒤에는 그 디렉터리가 mutate 되지 않는다. retention 은 human-managed — 자동 삭제 / 자동 rotation 금지.
- **각 `run.json` 은 그 시점의 forensic 일 뿐 current state representation 이 아니다.** stale `run.json` 의 `status` 가 현재 install state 의 진실로 오인되지 않도록 supervisor 는 commit/push 같은 next action 전에 §5 verify (cross-binding 재확인) 를 별도 수행한다.
- **`status = complete` 가 verify 의 대체가 아니다.** mutation path 도입 batch 에서 `complete` 가 기록되더라도, cross-binding 정합은 그 시점에 별도 verify 로 재확인한다.

### 13.6 Approval boundary 정합

- **`inspect` / `verify` mode 는 어떤 path 에도 file 을 write 하지 않는다** (stdout/stderr only) — §10 mutation boundary 와 충돌하지 않는다.
- **`update-source` mode 는 InstallArea payload (`current/` + `install.json` + `payload-manifest.json` + `payload-marker.json`) 를 write 한다.** 그 InstallArea 가 global install layer (`%USERPROFILE%\.claude\ai-harness-toolset\`) 일 때 이 write 는 §10 의 explicit user-approved global / user filesystem mutation scope 이며, 그 explicit approval surface 는 §13.8 의 **command-implied approval** (operator 의 명시 update-source 호출 + 사용자 명시 update 지시 + plan-report; optional `-ConfirmInteractive` 시 two-choice selector) 다. update-source 는 activation surface (managed block / skill mirror) 와 run evidence file 은 write 하지 않는다.
- run evidence file 의 future write destination (`%USERPROFILE%\.claude\ai-harness-toolset\log\install-update\<runId>\`) 의 도입은 별도 future scoped batch 이며, 그 actual write 도입 시 §10 explicit user-approved scope 가 별도 동작한다. run.json 의 contract 정의 자체가 §10 mutation list 를 자동 확장하지 않는다.

### 13.7 Operational smoke (update-source)

`update-source` 는 payload 갱신 + verify + activation byte-identity + cleanup 후 **operational smoke** 를 수행한다 (`-SkipSmoke` 로 생략 가능). smoke 는 갱신된 payload (`<InstallArea>/current/`) 의 `scripts/brief-init.ps1` 을 **throwaway workspace** 에 대해 실행하고, seed 된 `<workspace>/log/brief/BRIEF.md` 가 payload 의 `templates/brief/BRIEF.md` 와 SHA-256 byte-identical 한지, runtime artifact 가 그 workspace 의 `log/` 아래로만 격리되는지를 확인한 뒤 (성공 시) workspace 를 정리한다 (smoke 실패 시에는 debugging 을 위해 보존하고 path 를 보고한다 — 아래 bullet).

- payload 에 smoke 전제 (`current/scripts/brief-init.ps1` + `current/templates/brief/BRIEF.md`) 가 없으면 smoke 는 **skip** (실패 아님) 으로 보고된다.
- smoke 실패는 `smoke_failed` 로 보고된다 (payload 는 이미 갱신됐어도 `complete` 가 아니다). 실패 시 throwaway workspace 는 debugging 을 위해 **보존** 되고 그 path 가 보고된다 (smoke result 의 `WorkspacePath` + 실패 reason 에 포함되며, caller 가 그 reason 을 `reasons` array 에 fold 한다). pass / skip 에서는 workspace 를 정리한다. 이는 `cleanup_failed_with_leftover` 의 "삭제하지 말고 path 를 보고" 계약과 대칭이며, 보존된 workspace 는 자동 재삭제하지 않고 별도 정리 결정에 맡긴다.
- 본 smoke 는 갱신된 payload 의 brief-init + template 정합을 증명한다. global install 의 channel-3-without-`-ToolRoot` resolution smoke (§2A phase 4a) 는 InstallArea 가 실제 global install 일 때의 operational smoke 이며, 본 entrypoint 의 payload-internal smoke 와 별개다.

### 13.8 Mutation approval — command-implied (primary) + optional two-choice selector

`update-source` 의 mutation 승인은 **command-implied approval 이 primary** 다 (§7.1.1): 기존 identity-consistent install 에 대해 operator 가 사용자의 명시 update 지시 + read-only plan-report 위에서 `-Mode update-source` 를 호출하는 것이 그 승인이다. 별도의 terminal yes/no keystroke 가 강제되지 않으므로 정규 Claude Code noninteractive shell 에서도 막히지 않는다. 안전은 (i) update-source 가 비-default explicit mutation MODE 라는 점, (ii) operator 의 plan-report 의무, (iii) §7.1.1 의 hard guards (위반 시 stop/report, mutation 없음) 가 함께 보장한다.

**Trust 모델 (정직한 disclosure).** command-implied approval 은 "operator 가 사용자의 명시 승인 후에만 update-source 를 호출한다" 는 정책 신뢰에 의존한다 — script 는 invoke 만으로 사람 승인 여부를 자체 검증하지 않는다 (이는 operator 가 어떤 사용자 명령이든 충실히 수행한다는 것과 동일한 신뢰 모델이다). 따라서 raw automation / CI 가 `-Mode update-source` 를 직접 호출하면 hard guards 를 통과하는 한 mutation 이 일어날 수 있다 — 이 entrypoint 는 사용자 승인 흐름 안에서만 호출되어야 한다. command-implied approval 은 **기존 install 의 update-source 에만** 적용되고 fresh install / 새 destination 생성 / activation apply / source-cut override 에는 적용되지 않는다 (§7.1.1).

**Optional interactive confirm (`-ConfirmInteractive`).** 직접 터미널 운영자가 추가 confirm 을 원하면 `-ConfirmInteractive` 로 **정확히 두 선택지 (Yes / No)** 의 terminal selector 를 켤 수 있다 (default OFF). 그 selector 는:

- 선택지는 **정확히 Yes 와 No 둘뿐** — `Other` / `Custom` / `Type something` / `Chat about this` 같은 제3 선택지를 노출하지 않는다.
- **default highlight = Yes**, 그러나 확정에는 **Enter 가 반드시 필요**하다. Up/Down 이 highlight 를 이동, Enter 가 confirm, Esc 는 No (Ctrl+C 는 host default abort — mutation 이전이라 안전한 no-op abort).
- **timeout 으로 Yes 가 자동 선택되지 않는다.**
- `-ConfirmInteractive` 를 켰는데 **interactive terminal 이 없으면** apply 로 silent fall-through 하지 않고 `update_aborted_no_approval` 로 중단한다 (명시 confirm 요청을 임의로 command-implied 로 강등하지 않는다).
- 본 selector 는 **mutation 승인 보조 경로 전용** 이다 — read-only `inspect` / `verify` 는 selector 를 호출하지 않는다.
- selector 의 console key-reading 은 source-review 대상이고, 그 순수 decision 로직 (key sequence → Yes/No) 은 console IO 없이 단위 테스트된다.

### 13.9 Status precedence (single terminal value)

`update-source` 가 단일 terminal status 를 emit 하기 위한 우선순위: payload delta 가 없고 activation 정합이면 `noop_already_current`; payload delta 가 없고 activation drift 면 `activation_pending` (mutation 미수행); `-ConfirmInteractive` 가 켜졌는데 confirm 이 Yes 가 아니거나 interactive terminal 이 없으면 `update_aborted_no_approval` (mutation 미수행); apply 중 예외 / metadata 부재 / source-cut / identity ambiguity / destination 이 기존 install 아님 / source HEAD resolve 실패면 `failed`. payload delta 가 있고 guards 통과 + (`-ConfirmInteractive` 미사용 또는 confirm Yes) 이면 command-implied approval 로 apply 한다. apply 후에는 `verify_failed` > `activation_pending` > `cleanup_failed_with_leftover` > `smoke_failed` > `complete` 순으로 가장 blocking 한 것을 emit 한다 (나머지 reason 은 `reasons` 에 누적, leftover 는 `leftoverPaths` 에).

### 13.10 Pester 회귀 lock

본 절의 enumeration / shape / invariant / selector decision 로직 / update-source apply orchestration 은 source repo 의 Pester suite 가 회귀 lock 으로 보호한다.

### 13.11 Output stream contract (`-Json`)

`scripts/install-update.ps1` 의 출력 stream 계약은 다음과 같다 (모든 mode 공통, I13 명료화). 본 계약은 의도된 동작이며 behavior change 가 아니다.

- **`-Json` 지정 시**: **stdout** 은 machine-readable JSON object **하나만** emit 한다 (단일 `ConvertTo-Json` body). human-readable 진행 / 상태 line (`install-update: mode=... / status=... / exitCode=...` + reasons) 과 최종 human label line (`install-update: PASS` / `INCOMPLETE (...)` / `FAIL`) 은 **stderr** 로 간다. 따라서 `-Json` 호출자는 stdout 을 그대로 JSON parser 에 넣을 수 있고 (stdout 에는 human line 이 섞이지 않는다), stderr 는 사람용 로그로 분리해 읽는다.
- **`-Json` 미지정 시**: human report 와 JSON 을 모두 **stdout** 에 쓴다 — JSON 은 `--- BEGIN JSON ---` / `--- END JSON ---` marker 로 감싸 사람이 구분할 수 있게 하고, 최종 human label line (`install-update: PASS` / `INCOMPLETE (...)` / `FAIL`) 도 stdout 으로 간다.
- **최종 human label 의 세 형태 (human-output-only; Phase 3.6).** `install-update: PASS` = exitCode 0 success (`complete` / `noop_already_current` / `inspect_clean` / `verify_pass`); `install-update: INCOMPLETE (payload OK; activation follow-up required)` = **`activation_pending` 전용** (payload 는 OK 이고 activation apply follow-up 만 남은 상태 — hard failure 가 아니다; §13.2); `install-update: FAIL` = 그 외 모든 non-zero exit (`verify_failed` / `smoke_failed` / `cleanup_failed_with_leftover` / `update_aborted_no_approval` / `failed`). 이 label 은 **human 출력일 뿐**이며 status vocabulary (§13.1) / exitCode (§13.3) / machine JSON schema 를 바꾸지 않는다 — `activation_pending` 은 여전히 machine status `activation_pending` + exitCode 1 이다.
- stderr 출력 자체는 실패 신호가 아니다 (git progress 와 동일 — §5.1). 성공 / 실패 판정은 exit code (§13.3) 와 stdout JSON 의 `status` 로 한다 (human label 의 `INCOMPLETE` 도 exitCode 1 이며, machine 판정은 `status=activation_pending` 으로 한다).
