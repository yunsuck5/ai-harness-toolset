# Install — ai-harness-toolset

본 문서는 `ai-harness-toolset` 의 **unified install guide** 다. GitHub repo URL 또는 local clone path 어느 source input 으로 시작하더라도 install 의 model 과 절차가 동일하다는 사실을 본 문서 하나로 self-contained 하게 설명한다. 본 문서는 thin pointer 가 아니라 install 수행에 필요한 절차를 본문에 포함한다. `docs/roadmap/` 의 model / decision 문서들은 **reference only** 이며, install 을 실행하기 위해 그 문서들을 읽을 필요는 없다.

본 문서의 존재만으로 어떤 install / update / global filesystem mutation / managed-block apply / commit / push / publish / merge / release 도 자동 승인되지 않는다.

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

성공한 install 의 **persistent canonical install output 은 위 네 항목 (`current/` + 세 sibling 파일) 까지** 다. GitHub URL 을 source 로 쓰는 install / update / reinstall 의 경우 acquisition 단계에서 `git clone` / `git fetch` 가 사용할 임시 work area 가 필요하지만 — 본 도구는 그것을 **run-scoped temporary work area** 로 운영한다. 즉 (a) operator 는 임의의 폴더에 조용히 clone 하지 않는다. propose 단계에서 사용할 temporary work area path 와 acquisition 완료 후의 cleanup 계획을 함께 사용자에게 보고한다. (b) install / update / reinstall 이 성공하여 destination payload + metadata / integrity artifacts 가 정합 상태로 닫히면 operator 는 그 temporary work area 를 제거한다. (c) cleanup 자체가 실패해도 installed payload identity 의 실패는 아니다 — destination 의 정합 상태가 install 의 success criterion 이다. 다만 operator 는 cleanup 이 끝나지 않은 leftover path 를 사용자에게 보고하고, 정리 진행 여부에 대한 명시적 승인을 받는다. 따라서 temporary work area 는 어느 install 동작에서도 persistent canonical sibling 으로 남지 않는다. local clone path source 는 임시 work area 없이 사용자가 가진 기존 clone path 를 그대로 source 로 사용하므로 본 policy 의 propose / cleanup 단계가 적용되지 않는다 (사용자의 기존 clone path 는 operator 가 정리할 대상이 아니다). 어느 source input 이든 install 의 success criterion 은 runtime payload 와 metadata / integrity artifacts 이지 source clone / cache 의 존재가 아니다.

위 네 destination artifact 들 사이에는 cross-binding 이 있다. install / update / reinstall 후 verify 단계에서 `payload-manifest.json.head` == `payload-marker.json.head` == `install.json.lastUpdatedHead` 가 검증된다 — manifest 와 marker 의 `head` 는 항상 metadata 의 `lastUpdatedHead` (= 가장 최근에 적용된 source SHA) 에 binding 된다. `install.json.installedHead` 는 **최초 install 시점의 source SHA 를 보존하는 history field** 이며 update / restore 후에도 그대로 유지된다 (즉 fresh install 직후에만 `installedHead == lastUpdatedHead` 이고, update / restore 후에는 두 값이 다를 수 있다). 또한 manifest 의 각 file 의 size / SHA-256 이 `current/` 의 실제 파일과 일치해야 한다.

target project 안에는 ai-harness payload 를 두지 않는다. target project 의 persistent footprint 는 `<ProjectRoot>/log/` 아래의 runtime artifact (BRIEF / Chatlog / Evidence / Review) 뿐이다.

## 3. Supported source inputs

install 의 source 입력은 두 가지 형태를 동등하게 지원한다. 어느 쪽을 쓰더라도 (5) destination, (6) install identity, (7) flow, (8) failure handling 의 model 은 같다.

- **GitHub repo URL.** 예: `https://github.com/yunsuck5/ai-harness-toolset`. operator 가 URL 만 가지고 있을 때 사용한다. install 시 Claude Code 가 그 URL 을 source 로 `git clone` 한다.
- **Local clone path.** 예: `H:\Work\ai-harness-toolset\ai-harness-toolset`. operator 가 이미 clone 한 source repo 위에서 시작할 때 사용한다. clone 단계 없이 그 path 를 source 로 사용한다.

두 source input 의 유일한 차이는 source acquisition 단계 — `git clone` 이 필요한가, 아니면 기존 clone 을 그대로 사용하는가 — 뿐이다.

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
2. **Propose.** operator 는 적용 예정 변경을 사용자에게 명시한다 — fresh install 인가 / update 인가 / reinstall 인가, source 의 어떤 SHA 를 사용할 것인가, destination 의 어떤 path 가 overwrite 되는가, `install.json` 의 어느 field 가 어떻게 갱신되는가.
3. **Explicit approval.** 사용자가 명시적으로 `yes` / `proceed` / `진행해` 의 의도를 표시해야 한다. 모호한 응답은 진행 사유로 해석하지 않는다.
4. **Apply.** 승인된 범위만 destination 에 적용한다. apply 의 본체는 deterministic overwrite materialization (`current/` 를 source 의 resolved SHA 기준으로 다시 작성) + `install.json` 갱신이다.
5. **Verify.** apply 직후 operator 는 결과를 보고한다. 구체적으로 (a) `install.json` 의 §4 14-field schema 가 유효한지 — `schemaVersion` 이 reader 가 지원하는 값인가, `installMode` 가 `git-url` / `local-clone` 중 하나인가, mode-conditional source-identity field (`installMode == git-url` 이면 `repoUrl` non-empty + `sourcePath` empty, `installMode == local-clone` 이면 `sourcePath` non-empty + `repoUrl` empty) 가 충족되는가, `toolRoot` 가 `local-clone` 에서 non-empty / `git-url` 에서 empty 인가, `installedHead` / `lastUpdatedHead` 가 모두 non-empty resolved SHA 인가, `tool` / `targetFootprintPolicy` / `managedBy` 가 정해진 상수값 (`ai-harness-toolset` / `log-only` / `claude-code`) 인가 등, (b) `payload-manifest.json` 이 존재하고 `current/<payloadRoots>/**` 의 실제 파일 size / SHA-256 과 모두 일치하는지, (c) `payload-marker.json` 이 존재하고 `manifestPath` / `payloadRoots` constant 가 맞는지, (d) cross-binding `payload-manifest.json.head` == `payload-marker.json.head` == `install.json.lastUpdatedHead` 가 일치하는지 (`installedHead` 는 binding 대상이 아니다 — update / restore 후에는 `lastUpdatedHead` 와 다를 수 있는 history field 다) 를 확인하고, 다음 사용자 결정 (commit / push / managed-block apply / skill adoption / 실제 global mutation validation 등) 이 무엇인지 함께 명시한다. verify 의 결과는 후속 작업을 자동 승인하지 않는다.

## 6. Fresh install procedure

호스트에 ai-harness install 이 아직 없는 경우 (또는 `current/` + `install.json` 이 모두 부재인 경우) 의 절차다.

1. operator 는 Claude Code 안에서 다음 중 한 가지 의도를 사용자에게 표시한다.
   - GitHub URL 로 설치: 예 — "이 URL 로 ai-harness-toolset 을 설치한다: `https://github.com/yunsuck5/ai-harness-toolset`."
   - local clone path 로 설치: 예 — "이 local clone 을 source 로 설치한다: `H:\Work\ai-harness-toolset\ai-harness-toolset`."
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

대표 케이스.

- **source acquisition 실패** — source 부재 / 권한 부족 / network 실패 / GitHub URL 의 clone / fetch 실패 등이 원인이면 retry 또는 reset 자동화하지 않는다. operator 는 사용자에게 원인을 보고하고, 사용자가 source 환경을 정리한 뒤 fresh install 을 다시 시도한다. GitHub URL source 의 경우 임시 work area 가 부분적으로 만들어졌다면 operator 는 그 정리도 함께 propose 한다.
- **destination 의 `current/` 가 부재 / 부분 / 손상** — operator 는 fresh install 절차 (§6) 로 다시 시작한다. partial repair 를 시도하지 않는다.
- **`install.json` 의 부재 / corrupt / schema mismatch** — operator 는 사용자에게 상황을 보고하고, 사용자가 명시적으로 승인한 경우에 한해 fresh install 절차 (§6) 로 destination 과 metadata 를 처음부터 다시 만든다.
- **`payload-manifest.json` 또는 `payload-marker.json` 의 부재 / unreadable / unknown schemaVersion / head mismatch / files digest mismatch** — operator 는 사용자에게 보고하고, 사용자가 승인한 경우 §6 fresh install 또는 §7 update / reinstall 로 destination 을 source HEAD 기준으로 다시 작성한다. deterministic overwrite materialization 이 manifest + marker 도 source HEAD 기준으로 재작성하므로 drift 가 자연 해소된다. manifest 의 surgical file 단위 교체는 하지 않는다.
- **cross-binding 불일치 (`payload-manifest.json.head` ≠ `payload-marker.json.head`, 또는 둘 중 어느 한쪽 ≠ `install.json.lastUpdatedHead`)** — 동일 회복 path. 사용자 승인 후 §6 또는 §7 의 deterministic overwrite reinstall 로 manifest / marker 가 `lastUpdatedHead` 와 다시 정합하도록 작성한다. `installedHead` 는 본 cross-binding 의 대상이 아니므로 `installedHead` 와 `lastUpdatedHead` 가 다른 것 자체는 실패가 아니다 (update / restore 후의 정상 상태다).
- **이전 install 의 ref 가 사라짐 (force-push, deleted branch 등)** — operator 는 사용자에게 보고한다. 사용자가 새 ref 를 명시한 경우 그 ref 로 update / reinstall (§7) 을 진행한다. metadata-derived "known-good" ref 의 자동 fallback 은 하지 않는다.
- **(GitHub URL source) temporary work area cleanup 실패** — destination payload + metadata / integrity artifacts 가 정합 상태로 닫혔다면 본 케이스는 **installed payload identity 의 실패가 아니다.** install 의 success criterion 은 destination 의 정합 상태이고, temporary work area 는 §2 policy 에 따라 persistent canonical sibling 이 아니다. 다만 operator 는 cleanup 이 끝나지 않은 **leftover path 를 사용자에게 보고하고, 정리 진행 여부에 대한 명시적 승인을 받는다.** 사용자가 승인하면 operator 가 정리하거나, 또는 사용자가 직접 정리한다. 자동 재시도 / 강제 삭제는 하지 않는다.

요약: install 의 회복 path 는 "source 재준비 → §6 또는 §7 의 deterministic overwrite" 한 줄이다. canonical install output (`current/`, `install.json`, `payload-manifest.json`, `payload-marker.json`) 어느 쪽의 손상이든 이 한 회복 path 로 닫힌다. temporary work area cleanup 실패는 별도 케이스이며 installed payload identity 와 분리된 leftover-path 보고 / 사용자 승인 절차로 처리한다. 자동 clone recovery / surgical file 단위 교체 / repair framework 는 본 도구의 범위가 아니다 (§11 참조).

## 10. Approval boundaries

다음 boundary 는 install / update / reinstall 의 동작과 분리된다.

- **Global / user filesystem mutation** — 실제 `%USERPROFILE%\.claude\ai-harness-toolset\current\` materialize / refresh, `install.json` write, `%USERPROFILE%\.claude\` / `%USERPROFILE%\.codex\` 어느 경로의 write 도 **explicit user-approved global / user filesystem mutation scope** 다. 본 문서를 읽은 사실, operator 가 propose 한 사실, 어떤 자동화 trigger 의 fact 어느 것도 그 승인을 대체하지 않는다.
- **Managed-block apply** — `%USERPROFILE%\.claude\CLAUDE.md`, `%USERPROFILE%\.codex\AGENTS.md` (또는 `%CODEX_HOME%\AGENTS.md`, Codex user-global `AGENTS.override.md`), project-root `CLAUDE.md` / `AGENTS.md` 의 managed-block insert / replace 는 install / update automation 본체 **밖** 의 별도 explicit user-approved scope 다. install 의 verify 가 끝났다는 사실이 managed-block apply 를 자동 승인하지 않는다. `%USERPROFILE%\.claude\AGENTS.md` 는 어느 scope 에서도 valid destination 이 아니며, 본 도구는 그 path 를 생성하지 않는다.
- **Claude skill adoption** — `snippets/claude-skills/<name>/SKILL.md` 의 사용자 글로벌 환경 (`%USERPROFILE%\.claude\skills\<name>\SKILL.md`) 으로의 install / update / removal 은 install / update automation 본체 **밖** 의 별도 explicit user-approved scope 다.
- **Commit / push / publish / merge / release / target adoption** — install 의 verify 결과가 어떤 verdict 든, 이 작업들을 자동 승인하지 않는다. 모두 사용자가 별도의 명시 결정으로 처리한다.
- **실제 install / update / restore 의 validation** — actual `%USERPROFILE%\.claude\ai-harness-toolset\current\` 와 그 sibling artifact 들에 대한 실제 mutation 검증은 별도 explicit user-approved scope 다. 본 문서의 verify (§5 step 5) 가 끝났다는 사실이 이 validation 을 자동 승인하지 않는다.

## 11. Out of scope

본 install guide 와 install / update automation 본체는 다음을 **포함하지 않는다.** 본 문서의 존재만으로 아래 어느 항목도 자동 승인 / 작성되지 않는다.

- 신규 installer / setup / bootstrap / one-liner wrapper script.
- recovery / repair / doctor / fix-* framework.
- install linter / verifier framework / health-check tool.
- helper / convenience wrapper script.
- install metadata schema 본문 변경 / migration writer.
- CI / release / packaging pipeline.
- daemon / watcher / scheduler.
- automatic global filesystem mutation, automatic managed-block apply, automatic skill refresh.
- automatic target project update, automatic commit, automatic push, automatic publish, automatic merge, automatic release.

위 항목 중 어느 것도 본 도구에서 default 로 제공되지 않는다. 그 도입은 별도 scoped approval 의 일이다.

## 12. References (read only)

본 절은 install 의 수행에 **필수가 아니다.** 아래 문서는 모델 / 결정의 history 와 상세 boundary 를 담은 reference 다 — install 을 시작하기 위해 본 절의 문서를 읽을 필요는 없다. 본 INSTALL.md 만으로 install / update / reinstall 절차가 self-contained 하다.

- `docs/roadmap/GLOBAL_INSTALL_UPDATE_MODEL.md` — install / update / restore operating model 의 source-of-truth.
- `docs/roadmap/global-install-update/STEP3_INSTALL_UPDATE_DECISION_GUIDE.md` — Step 3 install / update / restore implementation decisions.
- `docs/roadmap/GLOBAL_ADOPTION_DECISION.md` — 운영 계층 결정 + managed-block marker policy.
- `docs/roadmap/GLOBAL_ADOPTION_PROCEDURE.md` — Claude skill global adoption / update / removal 절차.
- `docs/OPERATOR_GUIDE_KR.md` — Korean operator day-to-day guide / natural-language UX.

본 INSTALL.md 는 install 수행을 위해 self-contained 하게 작성된 entry 다. 위 reference 와 본문의 wording 이 차이가 있을 경우 install 절차의 기준은 본 INSTALL.md 의 본문이며, reference docs 는 model 의 history / 상세 boundary 를 참고하기 위한 자료다. 차이가 의도된 정정인지 누락인지 모호한 경우는 사용자가 명시적으로 판단한다 — 본 문서가 자동으로 어느 쪽을 source-of-truth 로 결정하지 않는다.
