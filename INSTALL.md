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

위 네 항목 (`current/` + 세 sibling 파일) 은 **base payload install phase 의 persistent canonical output** 이다 — operational install (§2A) 의 phase 1 결과이며, 사용자-facing "설치해줘" 의 **최종 완료 상태가 아니다.** base payload install phase 자체의 success criterion 은 이 runtime payload + metadata / integrity artifacts 의 정합 상태이고, 그 위에서 operational install 은 §2A 의 staged activation / smoke / cleanup phase 까지 진행해 실제 운용 가능 상태에 도달한다. GitHub URL 을 source 로 쓰는 install / update / reinstall 의 경우 acquisition 단계에서 `git clone` / `git fetch` 가 사용할 임시 work area 가 필요하지만 — 본 도구는 그것을 **run-scoped temporary work area** 로 운영한다. 즉 (a) operator 는 임의의 폴더에 조용히 clone 하지 않는다. propose 단계에서 사용할 temporary work area path 와 acquisition 완료 후의 cleanup 계획을 함께 사용자에게 보고한다. (b) install / update / reinstall 이 성공하여 destination payload + metadata / integrity artifacts 가 정합 상태로 닫히면 operator 는 그 temporary work area 를 제거한다. (c) cleanup 자체가 실패해도 installed payload identity 의 실패는 아니다 — destination 의 정합 상태가 install 의 success criterion 이다. 다만 operator 는 cleanup 이 끝나지 않은 leftover path 를 사용자에게 보고하고, 정리 진행 여부에 대한 명시적 승인을 받는다. 따라서 temporary work area 는 어느 install 동작에서도 persistent canonical sibling 으로 남지 않는다. local clone path source 는 임시 work area 없이 사용자가 가진 기존 clone path 를 그대로 source 로 사용하므로 본 policy 의 propose / cleanup 단계가 적용되지 않는다 (사용자의 기존 clone path 는 operator 가 정리할 대상이 아니다). 어느 source input 이든 base payload install phase 의 success criterion 은 runtime payload 와 metadata / integrity artifacts 의 정합이지 source clone / cache 의 존재가 아니다 (operational install 전체의 완료 조건은 §2A).

위 네 destination artifact 들 사이에는 cross-binding 이 있다. install / update / reinstall 후 verify 단계에서 `payload-manifest.json.head` == `payload-marker.json.head` == `install.json.lastUpdatedHead` 가 검증된다 — manifest 와 marker 의 `head` 는 항상 metadata 의 `lastUpdatedHead` (= 가장 최근에 적용된 source SHA) 에 binding 된다. `install.json.installedHead` 는 **최초 install 시점의 source SHA 를 보존하는 history field** 이며 update / restore 후에도 그대로 유지된다 (즉 fresh install 직후에만 `installedHead == lastUpdatedHead` 이고, update / restore 후에는 두 값이 다를 수 있다). 또한 manifest 의 각 file 의 size / SHA-256 이 `current/` 의 실제 파일과 일치해야 한다.

target project 안에는 ai-harness payload 를 두지 않는다. target project 의 persistent footprint 는 `<ProjectRoot>/log/` 아래의 runtime artifact (BRIEF / Chatlog / Evidence / Review) 뿐이다.

## 2A. Operational install — 사용자-facing "설치해줘" 의 기본 완료 조건

사용자가 "설치해줘" 라고 말할 때의 기본 완료 조건은 **operational install** — 실제로 toolset 을 운용할 수 있는 상태 — 이다. §2 의 base payload install (`current/` + 세 sibling 파일) 은 operational install 의 **내부 phase (phase 1)** 이며 그 자체로 최종 완료가 아니다. payload 가 materialize 되었다는 사실만으로 install 을 "끝났다" 고 보고 payload phase 에서 멈추지 않는다.

**plain "설치해줘" (별도 customization 요청 없음) 의 default plan 은 full operational install** 이며, 다음 phase 흐름 전체를 포함한다. operator 는 발생할 global / user mutation 의 **전체 목록**을 inspect 해서 사용자에게 한 번에 설명한 뒤, 그 full plan 에 대해 **단 하나의 yes/no 승인**을 받는다 (아래 "Default install UX"). 사용자가 승인하면 operator 는 payload phase 에서 임의로 멈추지 말고 approved full operational install flow 를 끝까지 수행한다 — phase 마다 다시 묻지 않으며, 어느 surface 를 설치할지 사용자에게 고르게 하지 않는다.

1. **base payload install** — `%USERPROFILE%\.claude\ai-harness-toolset\` 아래에 §2 의 네 항목 (`current/` + `install.json` + `payload-manifest.json` + `payload-marker.json`) 을 materialize 한다 (§4–§9 의 install model 본체).
2. **activation apply** — 실제 운용에 필요한 **global / user integration surface** 를 적용한다. operational install 의 activation 은 §2 footprint 규칙 (target project 의 persistent footprint = `<ProjectRoot>/log/` only) 과 정합하도록 **global / user 영역의 surface 만** 대상으로 한다. default plan 은 아래 세 surface 를 **모두** 포함하며, phase 1 / 3 / 4 / 5 와 함께 하나의 full operational install plan 으로 묶여 단일 yes/no 로 승인된다 (아래 "Default install UX"). operator 는 사용자에게 어느 surface 를 설치할지 고르게 묻지 않는다.
   - **Claude integration** — `snippets/CLAUDE_SNIPPET.md` 의 managed block 을 user-global `%USERPROFILE%\.claude\CLAUDE.md` 에 insert / replace (§10 의 managed-block apply 규칙).
   - **Codex integration** — `snippets/AGENTS_SNIPPET.md` 의 managed block 을 Codex user-global `%USERPROFILE%\.codex\AGENTS.md` (또는 `%CODEX_HOME%\AGENTS.md` / 그 scope 의 `AGENTS.override.md`) 에 insert / replace (§10 의 managed-block apply 규칙). `%USERPROFILE%\.claude\AGENTS.md` 는 어느 경우에도 destination 이 아니다.
   - **Claude skill adoption** — `snippets/claude-skills/ai-harness-review/SKILL.md` 를 user-global `%USERPROFILE%\.claude\skills\ai-harness-review\SKILL.md` 로 install / update (§10 의 skill adoption 규칙).

   project-root `CLAUDE.md` / `AGENTS.md` 의 managed-block 이나 project-local `<ProjectRoot>/.claude/skills/...` 채택은 operational install 의 phase 가 **아니다** — 이는 target project 별로 사용자가 선택하는 **project-specific adoption** 이며, §2 footprint 규칙 (target 은 `log/` only) 과 §10 의 target adoption 분리에 따라 operational install (global / user 영역) 과 별개의 explicit user-approved 동작으로 처리한다. (project-root 포함 destination 전체의 marker 규칙은 §10 의 managed-block apply 규칙이 정의한다.)
3. **verification** — base payload 의 §5 verify (14-field schema + manifest + marker + cross-binding) 에 더해, 적용된 activation surface 의 verify: managed-block 은 marker pair 가 정확히 1 개 정합하고 block 내용이 적용된 snippet 과 일치하는지, skill 은 destination `SKILL.md` 가 존재하고 content 가 source 와 일치하는지 (§10 의 activation 규칙이 정의).
4. **operational smoke** — usable state 를 증명하는 minimal smoke. source repo 가 아닌 **별도의 throwaway target smoke workspace** 에서 두 가지를 확인한다. (a) **ToolRoot channel-3 resolution** — `brief-init.ps1` 을 `-ToolRoot` 인자 / `AI_HARNESS_TOOL_ROOT` 없이 실행해, seed 된 `<workspace>/log/brief/BRIEF.md` 가 channel 3 (`%USERPROFILE%\.claude\ai-harness-toolset\current\templates\brief\BRIEF.md`) 의 template 과 byte-identical (SHA-256 일치) 한지로 channel 3 resolution 을 증명한다. (b) **runtime artifact 격리** — 위 `brief-init.ps1` 과 `log-init.ps1` 이 그 workspace 의 `log/` 아래에만 runtime artifact 를 쓰고 source repo / global `current/` payload 를 mutate 하지 않는지 확인한다. 주의: `log-init.ps1` 은 `Get-ProjectRoot` / `Get-ProjectLogRoot` 만 사용하고 `Get-ToolRoot` 를 호출하지 않으므로 그 자체로는 ToolRoot resolution 의 증거가 아니다 — channel-3 resolution 의 증거는 (a) 의 `brief-init.ps1` byte-identity 다. operational install 의 완료에 필요한 smoke 는 위 (a) + (b) 가 전부다. 더 광범위한 clean-target smoke suite 는 본 minimal smoke 와 별개인 future scoped work 이며 install 실행에 필요하지 않다.
5. **acquisition / work directory cleanup** — GitHub URL source 의 run-scoped temporary work area (§2) 와 smoke workspace 등 acquisition / 작업 디렉터리를 정리한다. cleanup 의 성공 / 실패는 보고에 포함하되, cleanup 실패가 installed payload identity 의 실패는 아니다 (§9).

### Default install UX — full operational install 을 하나의 yes/no 로 승인

plain "설치해줘" (또는 동등한 install 의도) 에 대한 default 는 위 5 phase 전체 (base payload + Claude managed-block + Codex managed-block + review skill + activation verify + operational smoke + cleanup) 를 수행하는 **full operational install** 이다. 보통 사용자에게 노출되는 install UX 는 다음과 같다.

1. operator 는 발생할 **global / user mutation 전체 목록**을 inspect 해서 사용자에게 한 번에 설명한다 — 최소한 다음을 묶어서 보여준다.
   - base payload → `%USERPROFILE%\.claude\ai-harness-toolset\` (`current/` + `install.json` + `payload-manifest.json` + `payload-marker.json`).
   - Claude managed-block → user-global `%USERPROFILE%\.claude\CLAUDE.md`.
   - Codex managed-block → Codex user-global `%USERPROFILE%\.codex\AGENTS.md` (또는 `%CODEX_HOME%\AGENTS.md` / `AGENTS.override.md`).
   - review skill → user-global `%USERPROFILE%\.claude\skills\ai-harness-review\SKILL.md`.
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
- **Local clone path.** 예: `H:\Work\ai-harness-toolset\ai-harness-toolset`. operator 가 이미 clone 한 source repo 위에서 시작할 때 사용한다. clone 단계 없이 그 path 를 source 로 사용한다.

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
- 성공한 URL install 은 verify 가 정합 상태로 닫힌 뒤 §2 policy 에 따라 그 work area / acquisition clone 을 제거한다. cleanup 의 성공 / 실패는 verify 보고에 포함하되, work area 의 존재 여부는 install identity 의 success criterion 이 아니다.

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

**`scripts/install-pipeline.ps1` 의 scope (혼동 방지 — production global installer 가 아니다).** 본 §5.1 의 첫 bullet 이 verify 의 canonical helper 로 `scripts/install-pipeline.ps1` 를 가리키므로 그 CLI 의 scope 를 여기서 명시한다. `scripts/install-pipeline.ps1` 는 install / update / restore deterministic core contract — resolver tuple → materialization → install metadata / `payload-manifest.json` / `payload-marker.json` write → verify — 의 회귀를 보호하는 **fixture-only deterministic core validation entry** 다. CLI 의 `Assert-NotForbiddenInstallArea` guard 가 `-InstallArea` 가 `%USERPROFILE%\.claude` / `%USERPROFILE%\.codex` 또는 그 descendants (특히 global stable install area `%USERPROFILE%\.claude\ai-harness-toolset\`) 와 일치하거나 그 아래일 때 fail-fast 거부하므로 — 본 CLI 로는 actual global / user filesystem apply 를 수행할 수 없다 (구조적 boundary). 실제 global / user filesystem apply — `%USERPROFILE%\.claude\ai-harness-toolset\current\` materialize / refresh, sibling install metadata / `payload-manifest.json` / `payload-marker.json` write, managed-block apply, Claude skill install / update / removal — 는 §10 의 explicit user-approved scope 위에서 **AI-guided global apply** 절차 (`docs/systems/install-update/STEP3_INSTALL_UPDATE_DECISION_GUIDE.md` §19.4) 로 수행되며, 본 CLI 가 그 apply 를 묶음으로 자동 수행하지 않는다 (§11 out-of-scope, productized installer / one-liner wrapper 미도입). production 영역에서 본 CLI 의 호출은 `Invoke-InstallPipelineVerify` 같은 verify / 진단 helper 성격으로 제한된다 — 아래 첫 bullet 이 그 verify helper 의 우선 사용을 가리킨다.

- **canonical CLI / repo helper 우선.** 검증은 `scripts/install-pipeline.ps1` 의 verify (`Invoke-InstallPipelineVerify`), managed-block 비교는 `scripts/lib/managed-block.ps1` 의 marker-bounded 추출, git 호출은 `scripts/lib/git.ps1` 의 capture helper 를 우선 사용한다. 즉석에서 작성한 점검은 보조 수단일 뿐이며, canonical helper result 와 충돌하면 신뢰 근거가 되지 않는다.
- **managed-block boundary 는 standalone line marker 기준이다.** managed block 의 경계는 자체 줄에 단독으로 있는 `<!-- BEGIN AI_HARNESS_TOOLSET_GLOBAL -->` / `<!-- END AI_HARNESS_TOOLSET_GLOBAL -->` 두 줄뿐이다 (§10 의 Managed-block apply 규칙). inline code / prose 안에 인용된 동일 텍스트나 fenced code block 안의 동일 텍스트는 boundary 로 세지 않는다. 단순 substring / `IndexOf` 비교는 본문에 인용된 marker 문자열에 걸려 false negative 를 낼 수 있으므로, 경계 판정에는 항상 §10 의 Managed-block apply 규칙이 정한 whole-line trim 매칭 (standalone line marker extraction) 을 쓴다.
- **raw git stderr progress 만으로 실패 판정하지 않는다.** `git clone` / `git fetch` / `git log` 는 progress 를 stderr 로 쓰며, 그 출력이 빨갛게 보여도 그 자체가 실패가 아니다. 성공 / 실패는 git 의 exit code, helper 의 capture result, 그리고 후속 verify 로 판정한다 (`scripts/lib/git.ps1` 의 capture helper 는 stderr 를 분리해 둔다).
- **PowerShell inline verification 의 `$LASTEXITCODE` unset artifact.** native command 를 돌리지 않은 PowerShell-only 검증을 inline 으로 실행하면, harness 의 exit-code probe 가 미설정 `$LASTEXITCODE` 를 읽어 "Exit code 1" / "cannot be retrieved because it has not been set" 처럼 보일 수 있다. 이는 wrapper artifact 이며 검증 결과가 아니다 — 판정은 canonical verify result (`ok = True`) 와 cross-binding (`payload-manifest.json.head` == `payload-marker.json.head` == `install.json.lastUpdatedHead`) 을 우선한다.
- **충돌 시 재검증.** ad-hoc 점검 결과가 canonical helper result 와 충돌하면, canonical helper (verify / managed-block 추출) 또는 §10 Managed-block apply 규칙의 standalone marker extraction 으로 다시 검증하고 그 canonical 결과를 판정으로 채택한다.

본 §5.1 은 install / update 의 PASS 판정을 뒤집는 규칙이 **아니다.** 위와 같은 관찰 (git stderr 색, `$LASTEXITCODE` 메시지, inline marker 에 걸린 substring 비교 등) 은 repo-owned defect 가 아니라 검증 절차의 표시 / 방법 문제이며, 본 절은 그 표시에 속지 않도록 하는 **operator-side verification discipline 보강**일 뿐이다. canonical verify 가 정합 (`ok = True` + cross-binding 일치) 이면 install / update 는 PASS 다.

## 6. Fresh install procedure

호스트에 ai-harness install 이 아직 없는 경우 (또는 `current/` + `install.json` 이 모두 부재인 경우) 의 절차다. 본 절은 operational install 의 **base payload phase (phase 1)** 를 상세화한다. default "설치해줘" 에서는 §2A "Default install UX" 가 overall propose + 단일 yes/no 승인을 관장하며, 그 하나의 승인이 본 절의 base payload 와 이어지는 activation / smoke / cleanup 까지 한꺼번에 cover 한다 — 아래 step 4 의 "사용자 승인" 은 그 단일 승인을 가리키며, base payload 만을 위한 별도 승인이 아니다.

1. operator 는 Claude Code 안에서 의도를 사용자에게 표시한다. 이때 mode 는 §3.1 대로 **사용자가 제공한 source input 의 형태가 결정** 하며, operator 가 두 mode 를 양자택일로 제시하지 않는다.
   - 사용자가 GitHub URL 을 제공한 경우 → `git-url`: 예 — "이 URL 로 ai-harness-toolset 을 설치한다 (`git-url` mode): `https://github.com/yunsuck5/ai-harness-toolset`." (URL 만 주어졌을 때 `local-clone` 을 함께 묻지 않는다.)
   - 사용자가 local clone path 를 명시적으로 source 로 제공한 경우 → `local-clone`: 예 — "이 local clone 을 source 로 설치한다 (`local-clone` mode): `H:\Work\ai-harness-toolset\ai-harness-toolset`."
2. operator 는 §5 inspect 를 수행한다. prerequisites 점검 + destination 부재 확인 + source 의 현재 HEAD SHA resolve.
3. operator 는 §5 propose 를 수행한다. propose 에는 다음이 포함된다.
   - source input 종류 (URL / local path) 와 값.
   - 사용할 ref 와 그 resolved SHA.
   - 생성될 destination path (`%USERPROFILE%\.claude\ai-harness-toolset\current\`).
   - 작성될 `install.json` 의 핵심 값 — `installMode` (`git-url` 또는 `local-clone`), mode-conditional source-identity field (`installMode == git-url` 일 때 `repoUrl` 에 operator 가 제공한 URL 보존, `sourcePath` 는 empty; `installMode == local-clone` 일 때 `sourcePath` 에 operator 가 제공한 local clone path 보존, `repoUrl` 은 empty), `toolRoot` (`local-clone` 이면 그 source path 의 identity hint 로 non-empty; `git-url` 이면 run-scoped temporary work area 가 persistent identity 가 아니므로 empty), `installedHead` (= resolved SHA, 최초 install 시점의 history field), `lastUpdatedHead` (= 동일 resolved SHA — fresh install 시점에는 `installedHead == lastUpdatedHead`); 나머지 field (`schemaVersion`, `tool`, `branch`, `remote`, `installedAt`, `lastUpdatedAt`, `targetFootprintPolicy`, `managedBy`) 도 함께 기록되어 §4 의 14-field schema 전체를 채운다.
   - (GitHub URL source 일 때만) §2 의 run-scoped temporary work area policy 에 따라 acquisition 에 사용할 **temporary work area 의 구체 path** 와 acquisition 종료 후의 **cleanup 계획** (성공 시 제거, cleanup 실패 시 leftover 보고). local clone path source 는 본 항목을 생략한다 — 사용자의 기존 clone path 를 그대로 source 로 사용하므로 temporary work area 가 없다.
4. 사용자가 명시적으로 승인한 경우에만 §5 apply 를 수행한다.
5. apply 직후 §5 verify 를 수행하고, 정합 상태로 닫혔으면 (GitHub URL source 일 때만) §2 policy 에 따라 temporary work area 를 제거한다. cleanup 자체의 성공 / 실패 결과는 verify 보고에 함께 포함한다.

본 단계의 어떤 부분도 자동 PATH 변경, managed-block apply (`%USERPROFILE%\.claude\CLAUDE.md` 등), Claude skill 의 자동 설치, target project 의 자동 변경을 포함하지 않는다.

## 7. Update / reinstall procedure

이미 `current/` + `install.json` 이 있는 경우의 절차다. update 와 reinstall 은 같은 model — deterministic overwrite materialization — 의 두 표현일 뿐이다.

1. operator 는 사용자에게 의도를 표시한다. 두 종류가 있다.
   - **"업데이트 받아"** — source side update + global install update. GitHub URL source 와 local clone path source 모두에 적용된다. GitHub URL source 일 때는 §2 policy 에 따라 새 run-scoped temporary work area 에서 `git clone` 또는 `git fetch` 로 source 를 새로 획득한 뒤 그 source 의 HEAD SHA 를 사용한다. local clone path source 일 때는 사용자가 가진 기존 clone 의 fetch / pull 또는 user 가 별도로 정리한 새 HEAD 가 source 로 사용된다 (operator 가 사용자 clone 을 자동으로 fetch / pull 하지는 않으며, propose 단계에서 명시 확인을 받는다).
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

- **source acquisition 실패** — source 부재 / 권한 부족 / network 실패 / GitHub URL 의 clone / fetch 실패 등이 원인이면 retry 또는 reset 자동화하지 않는다. operator 는 사용자에게 원인을 보고하고, 사용자가 source 환경을 정리한 뒤 fresh install 을 다시 시도한다. GitHub URL source 의 경우 임시 work area 가 부분적으로 만들어졌다면 operator 는 그 정리도 함께 propose 한다.
- **destination 의 `current/` 가 부재 / 부분 / 손상** — operator 는 fresh install 절차 (§6) 로 다시 시작한다. partial repair 를 시도하지 않는다.
- **`install.json` 의 부재 / corrupt / schema mismatch** — operator 는 사용자에게 상황을 보고하고, 사용자가 명시적으로 승인한 경우에 한해 fresh install 절차 (§6) 로 destination 과 metadata 를 처음부터 다시 만든다.
- **`payload-manifest.json` 또는 `payload-marker.json` 의 부재 / unreadable / unknown schemaVersion / head mismatch / files digest mismatch** — operator 는 사용자에게 보고하고, 사용자가 승인한 경우 §6 fresh install 또는 §7 update / reinstall 로 destination 을 source HEAD 기준으로 다시 작성한다. deterministic overwrite materialization 이 manifest + marker 도 source HEAD 기준으로 재작성하므로 drift 가 자연 해소된다. manifest 의 surgical file 단위 교체는 하지 않는다.
- **cross-binding 불일치 (`payload-manifest.json.head` ≠ `payload-marker.json.head`, 또는 둘 중 어느 한쪽 ≠ `install.json.lastUpdatedHead`)** — 동일 회복 path. 사용자 승인 후 §6 또는 §7 의 deterministic overwrite reinstall 로 manifest / marker 가 `lastUpdatedHead` 와 다시 정합하도록 작성한다. `installedHead` 는 본 cross-binding 의 대상이 아니므로 `installedHead` 와 `lastUpdatedHead` 가 다른 것 자체는 실패가 아니다 (update / restore 후의 정상 상태다).
- **이전 install 의 ref 가 사라짐 (force-push, deleted branch 등)** — operator 는 사용자에게 보고한다. 사용자가 새 ref 를 명시한 경우 그 ref 로 update / reinstall (§7) 을 진행한다. metadata-derived "known-good" ref 의 자동 fallback 은 하지 않는다.
- **(GitHub URL source) temporary work area cleanup 실패** — destination payload + metadata / integrity artifacts 가 정합 상태로 닫혔다면 본 케이스는 **installed payload identity 의 실패가 아니다.** install 의 success criterion 은 destination 의 정합 상태이고, temporary work area 는 §2 policy 에 따라 persistent canonical sibling 이 아니다. 다만 operator 는 cleanup 이 끝나지 않은 **leftover path 를 사용자에게 보고하고, 정리 진행 여부에 대한 명시적 승인을 받는다.** 사용자가 승인하면 operator 가 정리하거나, 또는 사용자가 직접 정리한다. 자동 재시도 / 강제 삭제는 하지 않는다.

요약: install 의 회복 path 는 "source 재준비 → §6 또는 §7 의 deterministic overwrite" 한 줄이다. canonical install output (`current/`, `install.json`, `payload-manifest.json`, `payload-marker.json`) 어느 쪽의 손상이든 이 한 회복 path 로 닫힌다. temporary work area cleanup 실패는 별도 케이스이며 installed payload identity 와 분리된 leftover-path 보고 / 사용자 승인 절차로 처리한다. 자동 clone recovery / surgical file 단위 교체 / repair framework 는 본 도구의 범위가 아니다 (§11 참조).

### 9.1 회복 class 구분 — generated payload / managed-block file / skill activation surface

회복 model 은 세 mutation class 를 명확히 구분한다. 같은 "손상 / 회복" 단어를 쓰더라도 class 마다 회복 방식이 다르다.

- **Generated payload class** — `%USERPROFILE%\.claude\ai-harness-toolset\current\` 와 그 sibling metadata / integrity artifact (`install.json` / `payload-manifest.json` / `payload-marker.json`). 이 class 는 전적으로 source 에서 재생성되는 deterministic output 이며 사용자 편집 대상이 아니다. 따라서 partial / unknown / 손상 상태의 회복은 위 **reinstall-first** 한 줄 — trusted source 재준비 → §6 / §7 deterministic overwrite — 이다. 기존 payload 를 회복 source-of-truth 로 삼지 않고, 이 class 에는 backup / rollback / transaction / partial-state reconciliation 을 두지 않는다 (source 가 곧 truth 이므로 불필요하다).
- **Managed-block instruction file class** — `%USERPROFILE%\.claude\CLAUDE.md`, Codex user-global `%USERPROFILE%\.codex\AGENTS.md` (및 §10 의 다른 valid managed-block destination). 이 파일들은 managed block **바깥** 에 **사용자 소유 content** 를 담으므로 whole-file reinstall-overwrite 대상이 **아니다** — marker 밖 사용자 데이터를 보존해야 하기 때문이다. 안전 적용 / 회복은 §10 의 managed-block apply 규칙 (marker pair validation, marker-bounded block 만 1:1 치환, malformed / 중복 marker 시 fail-fast, marker 밖 content 보존, 적용 후 block == snippet verification) 과, 그 apply 를 수행하는 managed-block tooling 이 제공하는 dry-run (no-write preview) / pre-write backup / 손상 즉시 rollback 으로 처리한다.
- **Claude skill activation surface** — skill destination `%USERPROFILE%\.claude\skills\<name>\SKILL.md`. 이것은 managed-block file 이 **아니라** activation surface (skill activation artifact) 다. 현행 contract (§10 Skill adoption 규칙) 는 source `snippets/claude-skills/<name>/SKILL.md` → destination 의 **whole-file copy / update + hash verification** 이며, 사용자가 destination 을 수정해 두었다면 update 가 그 수정을 overwrite 한다는 사실을 **사전 고지** 하는 모델이다. 따라서 skill 은 marker-bounded 부분 치환도 아니고, 현재 구현 / 문서가 보장하지 않는 pre-write backup / rollback / dry-run tooling 의 대상도 **아니다** — skill 의 적용 / 회복은 source 기준 whole-file copy / update + hash verification + overwrite 사전 고지로 닫힌다.

따라서 세 우려가 각각 다른 방식으로 닫힌다: generated payload 의 atomicity 는 reinstall-first 로, managed-block instruction file 의 marker 밖 사용자 데이터 보호는 managed-block tooling 의 dry-run / pre-write backup / rollback / verification 으로, skill activation surface 의 적용은 source 기준 whole-file copy / update + hash verification + overwrite 사전 고지로 닫힌다 — 어느 것도 하나의 transaction / rollback framework 로 묶지 않으며, skill 에는 별도 backup / rollback / dry-run tooling 을 두지 않는다.

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
- **금지.** whole-file overwrite 금지. marker bounded block **바깥** 의 기존 사용자 / project 내용은 어떤 경우에도 보존하며 편집하지 않는다.
- **valid destination.** Claude: user-global `%USERPROFILE%\.claude\CLAUDE.md` 또는 project-root `CLAUDE.md`. Codex: user-global `%USERPROFILE%\.codex\AGENTS.md` (default) / `%CODEX_HOME%\AGENTS.md` (`CODEX_HOME` set 시) / 그 scope 의 `AGENTS.override.md` (둘 다 있으면 override 우선), 또는 project-root `AGENTS.md`. **forbidden:** `%USERPROFILE%\.claude\AGENTS.md` — 어느 agent 의 instruction 경로도 아니며 절대 생성하지 않는다.
- operational install (§2A phase 2) 의 activation 은 위 destination 중 **user-global** (Claude `%USERPROFILE%\.claude\CLAUDE.md`, Codex user-global `AGENTS.md`) 만 대상으로 한다. project-root destination 의 managed-block 은 동일 marker 규칙으로 적용하되 operational install phase 가 아니라 별도 explicit-approved project-specific adoption 이다.

### Skill adoption 규칙 (self-contained)

skill 적용에 필요한 규칙은 다음이 전부다 — 외부 docs 참조 없이 본 규칙만으로 적용한다.

- **source / destination.** source = install artifact `snippets/claude-skills/<name>/SKILL.md`. operational install 의 destination = user-global `%USERPROFILE%\.claude\skills\<name>\SKILL.md`. (project-local `<ProjectRoot>/.claude/skills/<name>/SKILL.md` 는 project-specific adoption 으로 operational install phase 가 아니다.) 폴더 이름 `<name>` (예: `ai-harness-review`) 은 그대로 유지한다 — Claude Code 가 폴더 이름으로 skill 을 식별한다.
- **first install** (destination dir 부재): `%USERPROFILE%\.claude\skills` 부재 시 그 dir 생성도 skill activation 의 일부로 propose 목록에 포함한다 (default operational install 에서는 §2A 단일 yes/no 가 cover 하며 별도 prompt 를 추가하지 않는다) → 승인된 plan 적용 시 `<name>/` dir 생성 → `SKILL.md` 복사 (frontmatter 임의 수정 금지) → content 가 source 와 일치하는지 verify.
- **update** (destination 존재): source 와 hash 비교. 동일하면 변경 없음을 보고하고 중단. 다르면 diff propose → 승인 시 `SKILL.md` 전체 교체 (partial merge 금지) → hash 일치 verify. 사용자가 destination 을 수정해 두었다면 교체로 그 수정이 사라짐을 사전 고지.
- **removal**: 삭제 대상 `<name>/` dir 와 그 안의 파일 목록을 propose → 승인 시 그 dir 만 삭제 (dir 밖 파일 미삭제) → 부재 verify. source repo 의 `snippets/claude-skills/<name>/` 는 영향받지 않는다.

## 11. Out of scope

본 install-pipeline automation 본체는 다음을 **포함하지 않는다.** 본 문서의 존재만으로 아래 어느 항목도 자동 승인 / 작성되지 않는다. 주의: managed-block apply / skill adoption / smoke 는 §2A operational install 의 staged phase 이므로 out-of-scope 가 **아니다** — 본 절에서 out-of-scope 인 것은 그것의 *자동 (무승인)* 적용과 아래의 productization / framework 항목이다.

- 신규 installer / setup / bootstrap / one-liner wrapper script.
- recovery / repair / doctor / fix-* framework.
- generated payload 에 대한 transaction log / rollback framework / tamper detection / partial-state reconciliation. generated payload 의 materialization atomicity / partial state 는 §9 / §9.1 의 reinstall-first 로 닫힌다. (managed-block instruction file 의 dry-run / pre-write backup / rollback / verification 은 §9.1 / §10 의 managed-block tooling 영역, Claude skill 의 whole-file copy / update + hash verification 은 §10 Skill adoption 규칙 영역으로 각각 별개이며, 본 out-of-scope 항목과 혼동하지 않는다. skill 에는 별도 pre-write backup / rollback / dry-run tooling 을 두지 않는다.)
- install linter / verifier framework / health-check tool.
- helper / convenience wrapper script.
- install metadata schema 본문 변경 / migration writer.
- CI / release / packaging pipeline.
- daemon / watcher / scheduler.
- automatic global filesystem mutation, automatic managed-block apply, automatic skill refresh. (staged + 명시 승인된 형태의 managed-block apply / skill adoption 은 §2A operational install 의 activation phase 로 수행된다 — out-of-scope 인 것은 그것의 *자동 (무승인)* 적용이다.)
- automatic target project update, automatic commit, automatic push, automatic publish, automatic merge, automatic release.

위 항목 중 어느 것도 본 도구에서 default 로 제공되지 않는다. 그 도입은 별도 scoped approval 의 일이다.

## 12. docs/ 는 install-time input 이 아니다 (background only)

본 INSTALL.md 는 install / update / reinstall / operational install 을 수행하기 위한 self-contained operative contract 다 (상단 anti-coupling 절 참조). repo 의 `docs/` 트리 — `docs/roadmap/**`, `docs/user_guide/OPERATOR_GUIDE_KR.md` 등 — 는 model / decision 의 history / design / background material 일 뿐 **install-time input 이 아니다.** 본 절은 "install 중 읽어야 할 reference 목록" 이 아니다.

- install 실행 중 그 문서들을 읽을 필요가 없고, 읽어서 install 동작을 결정하지 않는다. 사용자가 명시적으로 design / background review 를 요청한 경우에만 연다 (install 실행이 아니라 별도 review 작업).
- 그 문서들이 stale / 누락 / rename / 삭제되어도 install semantics 는 본 INSTALL.md 본문이 전적으로 결정한다.
- 어떤 `docs/` 파일도 본 INSTALL.md 를 override 하지 않으며 install source-of-truth 가 아니다. install source-of-truth 는 본 INSTALL.md 하나다. (background 문서가 자신을 "model source-of-truth" 라 칭하더라도 그것은 그 model 문서들 사이의 우선순위를 가리킬 뿐 install 실행 authority 를 가지지 않는다.)
- 본 문서가 참조하는 실제 install artifact 는 `scripts/` / `snippets/` / `templates/` (적용 대상 payload) 뿐이며, 이는 docs coupling 이 아니다.
