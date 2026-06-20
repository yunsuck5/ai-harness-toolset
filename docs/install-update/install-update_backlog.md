# install-update — backlog (future-work queue)

next ID: IU-B-14 (open/idea `IU-B-*` rows) · IU-D-12 (deferred `IU-D-*` rows)

install-update 도메인의 future-work queue — open / deferred / idea-only rows. 각 row 는 한 줄 + reopen/start 조건이다. **이 파일이 install-update 의 open-work entrypoint 다**; spec-of-record 는 `docs/install-update/install-update_spec.md`. 어느 row 도 구현 승인이 아니다 — 각각 별도 scoped goal + Codex review gate 가 필요하다. 닫힌 row 는 기본 삭제한다(보존 = git history). 구계열 ledger(완료·운영 closeout·상세 narrative)는 git history 에 보존된다.

## Open rows

| ID | Row (one line) | Start/reopen condition |
|---|---|---|
| IU-B-01 | Smoke evidence preservation — runbook-only / helper-script / archive-manifest 선택 미정 | scoped goal 승인 시 착수 |
| IU-B-03 | `scripts/lib/path.ps1` path normalization edge-case hardening(cross-cutting — install+review 공용) | scoped goal 승인 시 착수 |
| IU-B-04 | Install validation report evidence hygiene — PASS verdict 와 anomalous wrapper signal 의 분리 | scoped goal 승인 시 착수 |
| IU-B-05 | Snapshot auxiliary evidence exactness wording polish | scoped goal 승인 시 착수 |
| IU-B-06 | Long-lived docs commit hash hygiene(cross-cutting — literal hash 를 장수명 문서에서 배제) | scoped goal 승인 시 착수 |

## Deferred rows (accepted residual risks under LTS — reopen 조건 보존)

deferred ≠ open: 결정으로 미룬 항목이며 각각 reopen 조건을 보존한다. 전부 LTS maintenance 의 accepted residual risk 로 운반되고, 어느 것도 LTS blocker 가 아니다. 실제 global/user filesystem mutation 은 항목과 무관하게 환경별 별도 명시 승인이다.

| ID | Deferred row | Reopen condition |
|---|---|---|
| IU-D-01 | git-url hardening residue — credential/auth/proxy/외부 network 도달성/clone recovery/multi-cache/per-ref subdir/fetch retry/submodule/cache identity verification(현행 = run-scoped fresh acquisition 의 minimum 경로; git-url+update-current 미지원) | git-url hardening scoped goal 승인 |
| IU-D-02 | source-cut path actual handling(현행 = detection-only·dispatcher non-process·STOP·deliverable byte-identity 보존 — "deferred with exact boundary") | reinstall/metadata-mutation handler scoped goal 승인 |
| IU-D-03 | 일상적 actual global/user filesystem apply 의 개별 건(global `current/` refresh·managed-block apply·skill install/update) | 각 apply 의 explicit user-approved scoped step |
| IU-D-07 | `package-toolset.ps1` copy-bundle packaging(이 toolset 은 비패키징이 standing — glossary rejected 참조) | packaging scoped goal 승인 |
| IU-D-08 | literal `?`(0x3F) non-increase encoding regression gate | encoding regression gate scoped goal 승인 |
| IU-D-09 | `-AcquisitionClonePath`/URL-normalization 류 acquisition-cache later-phase 결정(operative standing 은 `INSTALL.md` §7.1·§3.2 소유 — 본 row 는 가시성 보존) | acquisition-cache scoped 결정 승인 |
| IU-D-10 | uninstall skill-mirror 보호의 dynamic-assertion 강화(현행 = 비결함: non-canonical InstallArea 는 uninstall-global preflight 의 ExpectedLocation 가드로 거부, present-root&owned-skill 0 은 uninstall-target 의 skill-inventory blocked 로 전체 거부 — 둘 다 명시적 동적 가드. "static guard-ordering 의존"은 absent-root+canonical 단일 경로에 한하며 제거 대상 root 부재로 orphan 위험 미성립) | skill-mirror 보호를 명시적 동적 단언으로 보강하는 별도 hardening scoped goal 승인 |
| IU-D-11 | `path.Tests.ps1` NOFB-2 fixture 강화(현행 = 비결함: Get-ToolRoot/Test-IsSourceRepoRoot 가 ProjectRoot 자식 미탐색 + NOFB-1 이 full source-repo marker child 음성 케이스 커버 — NOFB-2 child 는 single-marker 라 payload-like 강도가 약하나 동작 회귀 아님) | NOFB-2 child fixture 를 full source-repo shape(3-marker)로 강화하기로 결정 |

## Idea-only rows (RETIRED — open 후보 아님)

- **[RETIRED] IU-B-07** — one-shot natural-language update completion / safe activation auto-apply. post-MVP 작업 목록에서 제외(2026-05-31)·미구현·LTS 범위 밖. activation apply 가 별도 explicit step 인 현행 의도 유지가 결론이며, auto-apply 는 global-mutation 자동 승인 경계를 넘는다. **Reopen 경로(4단계 전부 충족 시에만)**: ① 별도 explicit reopen 결정 ② 본 backlog 의 explicit re-entry ③ 사용자의 별도 scoped goal ④ Codex review gate. 당시 안전-조건 윤곽 등 상세는 git history(구 IDEAS.md 항목 1).

## Closed / retired ID tombstones (ID 연속성 — open 아님)

IU-01..15·IU-OPS-01..05·IU-B-08/09/10/12 는 닫힘 — 완료 ledger 와 상세 narrative 는 git history 보존(앵커: 구 `docs/systems/install-update/STATUS.md` 의 마지막 tracked revision). IU-B-11 은 결번. per-environment 실제 apply 별도-승인 경계와 D8 narrowed residual(Step F lint 한정 — 재개 = lint/policy 강화 또는 잔여 fixture 의 `Invoke-NativeProcess` 이전의 별도 결정)은 row 가 아니라 spec durable boundary/git history 가 운반한다.
