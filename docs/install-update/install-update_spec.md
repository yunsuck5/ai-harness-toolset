# install-update Spec

## Header

**이 문서는 무엇인가.** ai-harness-toolset 의 install-update 도메인 — global install / update / restore / uninstall / activation lifecycle — 의 목표 상태 명세(spec-of-record)다. 구계열 모델·설계·계약 문서(GLOBAL_INSTALL_UPDATE_MODEL·STEP3 guide·UNINSTALL_LIFECYCLE_DESIGN·SHARED_GLOBAL_INVOCATION_CONTRACT·상태 4종)의 current-bearing 의미는 본 spec 으로 수렴되고, 원문은 git history 로 보존된다.

**이 체인이 끝나면 무엇이 되는가.** install-update 도메인이 `docs/install-update/` 안에서 본 spec(목표 상태) + `install-update_backlog.md`(open/deferred/idea)의 두 live 문서로 닫히고, 본 spec 은 구현물과 1:1 동기화된 live 명세가 된다.

**이 문서가 아닌 것.** install/update/uninstall 의 실행 operative contract 가 아니다 — 실행 권위는 repo root `INSTALL.md` 하나이며, 모델/설계와 실행이 충돌하면 실행은 `INSTALL.md` 를 따른다. 본 spec 은 mutation/commit/push 승인이 아니다(1회 진술).

## 목표 상태

### 설치 모델

- install / update / restore 는 같은 primitive 의 서로 다른 source/ref resolution path 다 — **source-authoritative overwrite materialization**: source/ref 를 resolve 한 뒤 destination 을 결정론적으로 덮어쓰고, metadata 를 기록하고, 검증하고, 보고한다. destination diff 분석·partial patch·ad-hoc repair 는 이 모델에 존재하지 않는다.
- 사용자는 파일을 직접 배치하지 않는다 — AI operator(Claude Code)가 source repo 를 기준으로 global Claude layer 를 install / update 하며, 모든 global/user mutation 은 inspect → propose → 명시 승인 → apply → verify 위에서만 수행된다.
- source 획득은 2-mode 다(git-url / local-clone). 두 mode 는 source 획득 단계만 다르고 이후 materialization·metadata write·verify·report 경로는 동일하다.
- update 는 **metadata-dispatched re-materialization** 이다 — 최초 install 이 기록한 metadata 가 update 경로를 결정하며 사용자가 source 를 매번 재지정하지 않는다. 사용자 업데이트 명령은 의미상 두 종류다 — source 를 먼저 최신화한 뒤 갱신하는 것과, 현재 local HEAD 기준으로 global layer 만 갱신하는 것(후자의 no-source-touch 경로는 local-clone mode 에만 존재 — 아래 git-url acquisition invariant). 명령 수준의 지원 매트릭스와 절차는 `INSTALL.md` 소유다.
- restore 는 **user-specified ref 만으로** dispatch 된다 — metadata 는 source 위치의 descriptive hint 로만 쓰이고, metadata-derived known-good ref 의 자동 추출·자동 fallback 은 금지다. invalid ref 는 fallback 없이 fail-fast 한다.

### 계층 모델과 invocation channel

- 5-layer 분리: Layer 0 GitHub remote source / Layer 1 canonical local ToolRoot(source/build input — shared/global mode 의 default runtime ToolRoot 아님) / Layer 2 global Claude install layer(`%USERPROFILE%\.claude`) / Layer 3 ProjectRoot(작업 대상 — payload 설치처 아님) / Layer 4 project-local runtime artifacts(`<ProjectRoot>/log/`).
- shared/global mode 의 materialized runtime ToolRoot 는 `%USERPROFILE%\.claude\ai-harness-toolset\current`(Layer 2 아래)이며 default 연결 경로다.
- ToolRoot 해소는 **명시 우선 6-channel chain** 이다 — ① CLI `-ToolRoot` ② env `AI_HARNESS_TOOL_ROOT` ③ global stable install ④ dogfooding 판정 ⑤ legacy `<ProjectRoot>/.ai-harness` ⑥ 명시 error + exit non-zero(시도한 channel 목록 포함). channel 3 은 디렉터리 **부재 시 skip**, 존재하나 payload **불완전 시 fail-fast** 한다(completeness 판정 entrypoint 는 owner 소유). channel 2 는 process-scope 의 override/debug 용이며 default 연결 방식이 아니다. user-level config 파일과 snippet 내 ToolRoot 절대경로 기록은 channel 로 채택되지 않는다.
- component script 해소는 explicit ToolRoot(channel 1/2/3)에서 fallback 없이 fail-fast, implicit(channel 4/5)에서 `$PSScriptRoot` fallback + 명시 warning 이다.
- source repo(dogfooding) 판정은 **다중 marker 의 동시 존재(AND)** 로만 true 다 — 단일 marker 로 판정하지 않는다(marker 집합 값은 owner 소유).
- ProjectRoot 는 CWD default 이며, `.git` entry(directory/file 모두 유효) 부재 시 advisory warning 만 출력한다(fail 아님).
- backward compatibility: channel 5(legacy)의 유지와 channel 3 의 absent-skip 으로 stable install 도입 전 환경의 운영이 깨지지 않는다.

### install metadata 와 산출물 identity

- 성공한 install 의 **persistent canonical output 은 `current/` + sibling `install.json` + `payload-manifest.json` + `payload-marker.json` 네 항목까지** 다.
- metadata instance 는 global install layer 에만 존재한다 — target project 에 생성하지 않고, source repo 에는 schema/example 만 둔다. 필드 집합·값·mode-conditional 의미는 `INSTALL.md`·scripts 가 소유한다.
- payload 무결성 검증은 **per-file SHA-256 manifest** 채택이다(aggregate digest 비채택 — 도입은 별도 결정). marker 는 materialization 완료의 presence flag + integrity binding 이다. verify 는 manifest per-file 대조 + marker presence + head cross-binding 을 fail-fast 로 검사하며, 한쪽 부재가 다른 쪽 검증을 생략시키지 않는다.
- unknown `schemaVersion` 은 reader fail-fast 다 — silent downgrade 금지.

### git-url source acquisition

- git-url acquisition 은 **run-scoped temporary work area** 에서 매 action **fresh clone** 으로 수행되고 action 종료 시(성공/실패 모두) 제거된다 — action 사이에 persistent cache 를 보존하지 않는다. 따라서 git-url 에는 no-source-touch 재설치 경로가 구조적으로 존재하지 않는다(명령 수준 지원 매트릭스는 `INSTALL.md` 소유).
- clone/ref-resolve 실패는 materialization 이전 단계다 — persistent canonical output 4항목의 byte-identity 가 보존된다. work area cleanup 실패는 installed payload identity failure 가 아니며 exact leftover 경로 보고 + 사용자 명시 cleanup 으로 처리하고, leftover 가 남은 상태의 다음 action 은 fail-fast 한다.
- work area 는 persistent identity 가 아니다 — metadata 에 stable source path 로 기록되지 않는다.
- 도메인 테스트는 외부 network 도달성·credential 에 의존하지 않는다(local fixture 한정).

### source-cut

- source identity(acquisition mode 또는 source 지정 필드)의 변경은 **mutation class** 이며 제3의 mode 가 아니다. resolver 는 감지·표시·STOP 만 하고 dispatcher 는 처리하지 않는다(**detection-only**). actual handling 은 exact boundary 와 함께 deferred 다 — 처리 경로는 manual source 재준비 + deterministic overwrite reinstall 이며, metadata in-place mutation·자동 전환 handler 는 도입되지 않는다.

### dogfooding 보호

- silent mutation 위험 action 의 default 는 fail-fast STOP 이고, bypass 는 **명시 flag(`-AllowDogfoodSource`) 하나** 다 — warning-only·interactive prompt·env var·config file bypass 는 거부된 모델이다.
- enforcement 는 local-clone mode 에 한정된다 — git-url 의 source 는 run-scoped work area 이므로 user dev checkout 과 구조적으로 분리된다.
- **5 tree separation**: source repo working tree / global `current/` / InstallArea / source acquisition work area / `<ProjectRoot>/log/` 는 서로 겹치지 않는다 — design-intent invariant 다(pipeline 자체는 어느 action 에서도 이를 위배하지 않으나, placement 의 전면 자동 거부 enforcement 는 도입하지 않는다 — 운영 규약; 확장은 작업 후보 비보존). pipeline 의 materialization destination 은 항상 InstallArea 의 `current/` 다.
- restore 는 read-only snapshot(git-archive) 기반에 한정된다 — working-tree-mutating 방식으로의 변경은 별도 결정.

### recovery posture

- generated payload 의 source-of-truth 는 기존 installed payload 가 아니라 **trusted source identity(resolved commit SHA)** 다. 손상/drift/partial 상태의 회복은 분석·역행·부분 수리가 아니라 **manual source 재준비 + deterministic overwrite reinstall** 이다 — "복구" 는 별도 mode 가 아니다.
- 본 도메인은 손상/drift 의 **detection 만 보장** 한다 — 자동 recovery/migration/repair writer 는 없다.
- activation surface 는 generated payload 와 별도 영역이며 **2-class** 다 — (a) managed-block instruction file: marker-bounded replace + dry-run/pre-write backup/rollback/post-apply 검증(marker 밖 사용자 content 보존, whole-file overwrite 금지) (b) Claude skill mirror: source 기준 whole-file byte overwrite + post-write SHA-256 verify + 사용자 수정 overwrite 사전 고지(read-only dry-run preview 는 있으나 pre-write backup/rollback/sidecar 없음).

### activation surface 정책 (forced-copy + final-verification)

- deployed runtime extension(= deployed activation surface — source skill, 도입 시 hook 등)은 source payload 복사만으로 설치 완료가 아니다 — runtime 목적지에 실재하고 canonical source 와 **byte-identical** 해야 하며, install/update 후 부재·drift 면 그 install/update 는 미완료다. 어느 경로에서도 missing/drifted surface 가 조용히 "완료" 로 통과하지 않는다(status 값·precedence 는 `INSTALL.md` 소유).
- enumeration 은 **generic inventory model** 이다 — deterministic·local-first(directory enumeration 우선; 별도 registry 는 그 불충분이 입증되기 전 비도입). 모든 source skill 은 자동으로 forced mirror + final-verify 대상이다.
- uninstall 은 **owned surface 만** 회수한다 — installed payload 의 source inventory 로 식별된 surface 만 제거하고 비-owned sibling 은 보존한다.
- 새 deployed runtime extension 의 추가는 **같은 approved scope 안에서** 다음을 모두 점검/갱신해야 한다 — source inventory 규칙 · runtime mirror 목적지 · forced-copy 동작 · final verification · uninstall cleanup · surface 의 count/name/path/class 를 가정하는 tests · 기술 docs · (소유가 바뀌면) status surface. hook 도입 시에도 본 정책이 동일 적용되며, 정책의 존재가 hook 도입을 승인하지 않는다(no-hook 불변의 owner 는 배포 rule).

### uninstall

- uninstall 은 **별도 entrypoint** 다 — install/update entrypoint 의 mode 로 통합하지 않는다(install/update 의 좁은 mutation surface 와 metadata cross-binding source-of-truth 보존).
- 성공 기준은 **verified footprint-zero 4-target** 이다 — ① install root 부재 ② owned skill mirror 부재 ③ Claude managed-block surface 의 marker pair 0 ④ Codex **effective** managed-block surface 의 marker pair 0(instruction file 자체는 보존). 비-effective Codex 파일의 stale marker pair 는 detect-warn 이며 제거하지 않는다. 성공은 "삭제 명령 발행" 이 아니라 "검증된 end state" 다.
- 자기-삭제 문제는 **temp finalizer trampoline** 으로 닫는다 — main entrypoint 는 install root 를 직접 삭제하지 않고, finalizer 는 parent 종료를 기다린 뒤 install-root path 를 재guard 하고 expected footprint 를 재확인한 후에만 삭제하며, best-effort self-clean 실패 시 exact temp path 를 보고한다(non-fatal).
- managed-block 제거는 **marker-span excision** 이다 — instruction file 은 절대 삭제하지 않고(excision 으로 비어도 보존), 0-pair 는 idempotent no-op, 2+/incomplete/malformed/nested 는 fail-fast, marker 밖 byte 는 verbatim 보존하며, 선재 `.amb-backup` 은 자동 삭제하지 않는다(거취는 별도 사용자 결정).
- install root 삭제는 blind recursive delete 가 아니다 — **expected-footprint enumeration** 과 대조해 unexpected content 는 fail-fast 하고(목록 값은 owner 소유), 모든 destructive op 에 path guard(정규화 후 leaf/parent 정확 일치)를 적용한다.
- non-target 불가침 — `<ProjectRoot>/log/` · source repo/ToolRoot clone · 비-owned sibling skill · marker 밖 content 와 instruction file 자체 · `.claude`/`.codex` 의 비-toolset 파일과 그 디렉터리 자체 · project-root managed block(별도 scope).
- **dry-run(default·read-only) / apply / verify 는 분리** 된다 — apply 는 preflight-all-then-act(정적 fail-fast 조건이 하나라도 성립하면 아무것도 제거하지 않음)이고, failure 는 **2-tier** 다 — preflight tier(정적 감지 → 전체 차단) vs post-preflight tier(runtime 실패 → per-surface partial; cross-surface transaction 없음). already-absent 는 idempotent no-op 다. status 어휘는 standalone 이며 값 집합은 owner 소유다.

### self-adoption

- self repo(source repo 가 ProjectRoot 로도 동작하는 special case)에서 **source payload 와 project-local state 는 분리** 된다 — `<ProjectRoot>/log/` 의 runtime artifact 는 source payload 도 install payload 도 아니며 package/bundle 대상에서 제외된다.
- self-adoption 의 검증은 **global entrypoint(Layer 2) 기준** 이다 — "source repo 안의 local scripts 로 동작한다" 는 목표 모델의 검증이 아니다. self-adoption 은 external target adoption 보다 먼저 수행한다.
- 별도 state root(project-local state 의 source repo 밖 평행 디렉터리)는 default 가 아니다 — 반복 혼동이 관찰될 때의 별도 결정 후보일 뿐이다.

### 표기 규율

- durable 문서에서 global layer 경로는 `%USERPROFILE%\.claude` placeholder 로 표기하고, 실제 사용자 폴더명·maintainer 경로는 기재하지 않는다.

## Owner surface 지도

- **`INSTALL.md`** — 실행 operative contract(self-contained·anti-coupling — install 실행 중 `docs/**` 무참조): 설치/업데이트/재설치/uninstall 발견 절차 · 명령과 단계 순서 · 승인 문답 · metadata schema 필드 값 · final status vocabulary 와 precedence · exit code · run evidence 계약 · managed-block/skill adoption 규칙 · deterministic narrow entrypoint 경계 · bootstrap clone cleanup · acquisition cache 류 later-phase 결정.
- **lifecycle scripts** — `scripts/install-global.ps1`(fresh install + first-time managed-block insertion bootstrap) · `scripts/install-update.ps1`(inspect/verify/update-source + mutation guard) · `scripts/update-global.ps1`(name-based update 재진입) · `scripts/activate-global.ps1`(activation orchestration·canonical-overwrite path) · `scripts/apply-managed-block.ps1`(managed-block replace/insert/remove IO) · `scripts/uninstall-global.ps1` · `scripts/uninstall-finalizer.ps1`.
- **lib** — `scripts/lib/path.ps1`(ToolRoot 6-channel 해소·payload completeness 판정·source-repo 판정·ProjectRoot 해소) · `scripts/lib/resolve-script.ps1`(component script 해소·fallback 정책) · `scripts/lib/activation-surface.ps1`(activation surface plan 의 single home — source→destination map·mutation class) · `scripts/lib/managed-block.ps1`(managed-block primitive — set/add/remove) · `scripts/lib/uninstall-target.ps1`(read-only uninstall plan resolver) · `scripts/lib/install-pipeline-core.ps1`(temp-only pipeline library; entry 는 `tests/support/install-pipeline-fixture.ps1`).
- **tests** — `tests/install-global.Tests.ps1` · `install-update.Tests.ps1` · `update-global.Tests.ps1` · `activate-global.Tests.ps1` · `activation-surface.Tests.ps1` · `apply-managed-block.Tests.ps1` · `managed-block.Tests.ps1` · `install-pipeline.Tests.ps1` · `uninstall-apply.Tests.ps1` · `uninstall-target.Tests.ps1` · `path.Tests.ps1` · `resolve-script.Tests.ps1`(행동 잠금·회귀 보호).
- **templates** — `templates/install-root/AI_HARNESS_TOOLSET_ROOT_README.md`(installed-root landing page — update/uninstall discovery).
- **snippets** — 배포 instruction payload 와 skill(self-contained topology 운반).
- **managed-block 정책**(marker 검출·destination 분기·update 규칙) — `INSTALL.md`(managed-block apply 규칙·skill adoption 규칙, self-contained)와 위 scripts(`apply-managed-block.ps1`·`activate-global.ps1`·`scripts/lib/managed-block.ps1`·`activation-surface.ps1`)가 소유한다. adopter 측 global/user instruction file mutation 경계는 배포 rule(`snippets/rules/global-file-mutation-boundary.md`)이 소유한다. `docs/decisions/GLOBAL_ADOPTION_DECISION.md` 는 채택 결정의 기록(background)이며 behavior authority 가 아니다.

## Durable boundary

- **승인 경계 분리** — install/update automation core(payload materialize/refresh + metadata + dispatch + verification 으로 scope 한정)와 managed-block/skill apply 는 분리 scope 다: 한쪽의 trigger/verdict/승인이 다른 쪽을 승인하지 않는다. 실제 global/user filesystem mutation 은 환경(머신)별로도 각각 별도 명시 승인이다.
- `%USERPROFILE%\.claude\AGENTS.md` 는 어떤 scope 에서도 생성하지 않는다.
- **비도입 standing** — generated payload 에 대한 transaction log/rollback framework/tamper detection/partial-state reconciliation · auto update daemon/watcher/scheduler·hook 자동 등록 · automatic decision-maker(사용자 승인 없는 action 자동 전환 — install 실패 시 자동 restore 포함) · installer-first productization(deterministic narrow entrypoint class 의 허용 경계는 `INSTALL.md` 소유) · release 식별자/release asset checksum/package registry/CI-CD publish · destination merge/partial patch/user-edit preservation/interactive file-by-file 결정 UX · manual copy 를 normal path 로 권고하는 framing · user-level config 파일 · env var 자동 활성화와 user shell config 변경 · known-good metadata 자동 field.
- **superseded mechanism 부활 금지** — D6(review-verify sidecar ToolRoot binding)·D7(untracked exclusion)의 removed mechanism, persistent source-cache canonical framing, 1차/2차 BRIEF/footprint framing 은 historical 이며 어느 것도 재도입하지 않는다.
- ProjectRoot 의 `.git` 부재 검증은 advisory 로 유지된다 — strict(fail) 격상은 별도 결정.
- **추가 hardening 의 작업 후보 비보존** — manifest/marker 외부 검증 tool·schema migration writer·aggregate digest·credential/auth 자체 구현·clone recovery·multi-cache/bare clone·source-cut handler·dogfooding detection 범위 확장·추가 writer/helper(진단 helper·skill writer 등)는 작업 후보로 보존하지 않는다. 재개(reopen)는 별도 명시 결정이며, reopen 조건의 운반처는 `install-update_backlog.md` 다.
- 본 spec 이 **global-invocation 의미의 single home** 이다 — 별도 contract 문서 role 은 채택하지 않는다(invocation 결정의 live invariant 는 본 spec, 구현은 owner surface).

## Cross-domain interface

- **target footprint** — target project 의 persistent footprint 는 `<ProjectRoot>/log/` only 다(BRIEF/Evidence/Review 트리가 그 아래에 위치하며, 각 트리의 semantics 는 brief/review 도메인 spec 소유). forbidden: `.ai-harness/` · payload root 사본 · ai-harness 전용 `CLAUDE.md`/`AGENTS.md` · root `<ProjectRoot>/brief/` · user-home operator-local runtime root.
- **self-target enforcement** — "source repo 에 git-tracked file 이 `log/` 아래 존재하면 비-zero exit" 검사의 owner 는 `scripts/verify-ps1.ps1`(sub-check)과 배포 rule(repository-change-safety)이다 — 본 도메인은 footprint contract 의 짝 invariant 로 노출만 한다.
- **배포 표면 topology** — deployed snippet/SKILL.md 는 invocation topology 를 self-contained 로 운반한다(`docs/**` 경로 참조 0).

## Validation expectation

- Owner surface 지도의 도메인 Pester suites 전체 PASS — scripts 의 외부 관찰 가능 행동과 본 spec normative 문장의 1:1 이 성립해야 한다.
- `scripts/verify-ps1.ps1` PASS(.ps1 인코딩 규약 + self-target 검사 포함).
- `tests/repo-local-instruction-parity.Tests.ps1` PASS(root instruction 의 mirror 대칭 — install-update trigger map 행 포함).
- 근거 기록처는 closeout report / `log/evidence/**` 다(본 spec 에 비축적).

## Review focus

- **INSTALL.md 점유 경계** — 본 spec(또는 도메인 docs)이 operative 실행 계약(명령·단계 순서·schema field 값·status 문자열·승인 문답)을 재진술/요약/약화하지 않는가.
- **behavior 불변(LTS)** — scripts·config·tests 변경이 maintenance-scoped(scoped goal + review gate) 경계 안인가.
- **superseded 부활 0** — Durable boundary 의 superseded mechanism 목록이 어떤 새 문안으로도 재도입되지 않는가.
- **interface vs semantics** — 타 도메인(brief·review·verify-ps1) semantics 의 재진술이 없는가(interface 진술까지만).
- **activation surface 정책 준수** — 새 skill/hook/extension 추가가 목표 상태의 activation surface 정책 checklist 전 항목을 같은 scope 에서 닫는가.
- **prose-mirror 방지** — spec 갱신이 normative 문장 단위를 유지하는가(서사·diagram·example·pseudo-code 비운반).

## Lifecycle state

- design/plan: `docs/install-update/install-update_design.md` · `install-update_plan.md` 존재(batch I lifecycle — closeout 시 retire).
- spec↔implementation: **sync-required** — 본 spec 은 문서 수렴 mutation(구계열 retire·backlog 생성·routing 이관) 전의 청사진이다. closeout 에서 live 로 flip 한다.
- 도메인 성숙도: install/update/uninstall/activation lifecycle 구현·실호스트 검증·self-adoption 완료 — **LTS maintenance**(이력·ledger 는 git history). 현재 동봉 source skill 2종(ai-harness-review·ai-harness-brief — concrete activation surface 4).
- 동반 live 문서: `install-update_backlog.md`(구현 라운드 생성 — open/deferred/idea rows; ID 연속성과 reopen 조건 보존).
