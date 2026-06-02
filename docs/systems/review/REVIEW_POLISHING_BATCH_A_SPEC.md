# 리뷰 시스템 폴리싱 — Batch A 조사 + implementation spec (Gate 1 / Gate 2, 2026-06-02)

## Document character

본 문서는 implementation plan(`docs/systems/review/REVIEW_POLISHING_IMPLEMENTATION_PLAN.md`)의 **Batch A** 산출물 — first hard gate 두 축(Gate 1 effort override / Gate 2 reviewer-safe invocation)의 **조사 결과 + implementation spec** 이다.

- **성격**: Batch A = 조사 + spec. source/script/test/config 변경을 동반하지 않는다. Batch B/C(구현)가 본 spec 을 입력으로 삼는다.
- **이것이 아닌 것**: implementation 아님 / operational claim 아님 / 승인 문서 아님. 본 문서의 어떤 조사 결과도 "U9 operational" 이나 "reviewer-safe invocation 보장됨" 을 의미하지 않는다.
- **정직성 분리**: 아래 모든 사실은 **verified / not verified / unknown(inferred)** 로 분리 표기한다. Codex CLI *capability* 의 verified 와 review 시스템 *operational* 은 다른 층이다 — 섞지 않는다.
- **source of truth**: `docs/systems/review/REVIEW_POLISHING_DECISION_RECORD.md`(상위) + `docs/systems/review/REVIEW_POLISHING_IMPLEMENTATION_PLAN.md`(Batch 정의). 충돌 시 decision record 가 이긴다.

## 0. 조사 환경 (provenance)

- Codex CLI `0.132.0`, Windows 11, repo HEAD `1fdcefd`, reviewer model `gpt-5.5`(config/reviewer.json).
- 조사 방식: `codex --help` / `codex exec --help` (read-only), `~/.codex/config.toml` read-only 점검, read-only sandbox 하의 minimal Codex probe 3건.
- 모든 probe 산출물은 **runtime supporting material**: `log/evidence/batchA/validation-evidence.md`(번들) + `log/evidence/batchA-gate1/*`, `log/evidence/batchA-gate2/*`(per-case stdout/stderr/exit). source-of-truth 아님.
- **관찰된 global config(permissive, 실재)**: `~/.codex/config.toml` 에 `model_reasoning_effort = "xhigh"`, `sandbox_mode = "danger-full-access"`, `approval_policy = "never"`, `[windows] sandbox = "elevated"`. 즉 decision record 가 경고한 permissive global config 가 이 머신에 실제로 존재 — precedence 를 가상이 아닌 실제 baseline 에 대해 시험했다.

## 1. Gate 1 — per-invocation effort override 조사 결과

### 1a. 조사한 surface
- invocation argument: `-c, --config <key=value>`(config.toml override; nested dotted; TOML 파싱), `-m/--model`, `-p/--profile`, `--profile-v2`.
- config key: `model_reasoning_effort`(global config 에서 확인).
- environment variable: 별도 effort 전용 env 미발견(조사 범위 내). `CODEX_HOME` 은 config 위치 지정용.
- CLI help / observable run output: `codex exec` 헤더(stderr)에 `reasoning effort: <value>` 출력.

### 1b. verified (run-fact / inspection)
- **G1-V1** effort override surface = `-c model_reasoning_effort=<value>`. global profile 값을 per-invocation 으로 override 한다. (Probe 1: `-c model_reasoning_effort=low` → 헤더 `reasoning effort: low`, global=xhigh)
- **G1-V2** 허용값 집합 = `{none, minimal, low, medium, high, xhigh}` — **xhigh 포함**. (Probe 2 invalid-value 에러가 enumeration 을 노출)
- **G1-V3** 적용 effort 는 **observable** 하다 — `codex exec` 헤더 `reasoning effort:` 줄(단, **stderr**).
- **G1-V4** invalid/unsupported 값 → codex **fail-fast**: config-load 단계에서 `unknown variant` 에러, exit 1, 모델 run 없음, silent fallback 없음. (Probe 2: exit=1)

### 1c. not verified
- **G1-NV1** `scripts/review-run.ps1` 는 현재 `-c model_reasoning_effort` 를 **넘기지 않는다** → review 시스템의 적용 effort 는 global profile 값(현재 xhigh). 즉 per-invocation effort override 는 **review-run 에 아직 wiring 되지 않음**. → **U9 operational = not verified / not operational.** (CLI capability 는 verified, review-run 통합은 미구현 — Batch B)
- **G1-NV2** review-run 이 적용 effort run-fact(stderr 헤더)를 **capture/record 하지 않음** → 특정 review pass 에 어떤 effort 가 적용됐는지 입증하는 artifact 부재. (Batch B)

### 1d. Batch B implementation spec (Gate 1)
> 아래는 Batch B 가 구현할 사항의 **spec** 이다. 본 문서는 구현하지 않는다.
1. **override 주입점**: review-run 의 Codex argument 배열에 `-c model_reasoning_effort=<resolved-effort>` 를 추가하는 형태(현 `-c web_search=disabled` 와 동형). reviewer-tool-specific — tool 교체 시 재도출.
2. **resolved-effort 결정**: config `category→{model,effort}` mapping(U9). **1차 safe-default 만**: default `xhigh`(또는 latest+xhigh policy), 명확히 단순한 `local correctness review` packet 만 medium/high downgrade. downgrade 금지 class(decision record §Effort/model)는 high/xhigh 유지. effort ⟂ coverage.
3. **허용값 검증**: 주입 전 effort ∈ `{none,minimal,low,medium,high,xhigh}` 검증(잘못된 값은 codex 가 fail-fast 하지만, runner 가 더 이른 단계에서 명확히 거르는 편이 낫다).
4. **invalid 거동 보존**: codex 의 fail-fast 를 review-run FAIL 로 표면화(현 Codex exit≠0 → review-run FAIL 경로 활용).
5. **run-fact capture**: review-run 이 codex **stderr** 의 `reasoning effort:` 줄을 캡처해 적용 effort 를 run-fact 로 기록(stdout/stderr/exit 분리 캡처 — POWERSHELL_POLICY 준수). 이 run-fact 가 확보돼야 U9 operational 보고 가능.
6. **U9 operational 보고 조건**: 위 1·5 가 동작하고 + Gate 2(C)도 검증돼야 비로소 U9 operational 보고 가능(plan §6 Batch B/C: 두 축 함께).

## 2. Gate 2 — reviewer-safe invocation override 조사 결과

### 2a. 조사한 surface
- `scripts/review-run.ps1` 가 넘기는 flag: top-level `--ask-for-approval never`, `exec --sandbox read-only`, `-c web_search=disabled`, `--model`, `--output-last-message`, `-`(stdin).
- `-s/--sandbox {read-only, workspace-write, danger-full-access}`; `-a/--ask-for-approval {on-request, on-failure(deprecated), never}`.
- `--ignore-user-config`(global config 미로딩), `--dangerously-bypass-approvals-and-sandbox`(금지), `--add-dir`(writable 확장), `--output-last-message`(runner-controlled output).

### 2b. verified (run-fact / inspection)
- **G2-V1** global `~/.codex/config.toml` 는 permissive(danger-full-access / never / windows elevated) — 실재. (read)
- **G2-V2** review-run 은 invocation 단에서 `-a never` + `-s read-only` 를 **명시 전달**(전역 기본값에 기대지 않음). (script inspection)
- **G2-V3** **precedence 실측**: 위 permissive global config 하에서도 `-s read-only` 가 effective — 모델의 PowerShell `Set-Content` write 가 `blocked by policy` 로 차단됐고 마커 파일은 디스크에 **생성되지 않음**(독립 FS 확인). CLI flag 가 global `sandbox_mode` 를 override 함이 **이 write vector 에 대해** 실측됨. (Probe 3)
- **G2-V4** result.md 는 `--output-last-message`(CLI/runner-controlled output channel)로 생성됨 — 모델 sandbox shell write 가 차단된 상태에서도 result.md 가 산출됨(이전 모든 pass). 즉 **artifact 기록 책임은 이미 runner 측**이며 모델 sandbox write 에 의존하지 않는다 → decision record preferred pattern(판단=reviewer stdout/controlled output, 기록=caller/runner)과 일치.

### 2c. not verified / unknown
- **G2-NV1** Probe 3 은 **단일 write vector(PowerShell Set-Content), 단일 플랫폼(Windows 11), 단일 버전(0.132.0)** 만 시험 — 모든 write/exec/network vector 의 차단을 입증하지 못함. 따라서 reviewer-safe invocation 은 **"tested vector 에 대해 precedence verified"** 이지 **blanket guarantee 아님.**
- **G2-NV2** `[windows] sandbox = "elevated"` 와 read-only exec flag 의 상호작용을 별도 분리 시험하지 않음(헤더는 read-only 보고).
- **G2-U1**(inferred) flag precedence 가 모든 Codex 버전에서 안정적이라는 보장은 추론이며 미입증 — tool 교체/업그레이드 시 재도출 필요.

### 2d. safe negative test 설계 (Gate 2)
> Batch C 가 자동화/반복할 negative test 의 spec. (본 문서는 Probe 3 으로 1회 실증했고, Batch C 가 이를 확장·고정한다.)
1. **전제**: 실제 permissive global config(또는 그를 모사한 fixture)가 있는 환경에서 수행해야 의미가 있다(precedence 시험이므로).
2. **차단 시험(write)**: `--sandbox read-only --ask-for-approval never` 하에 모델에게 contained 경로(`log/evidence/.../negtest-*`)로의 write 를 **시도**시키고, (a) 모델 보고가 `WRITE_BLOCKED`/policy rejection 이고 (b) **독립 FS 확인으로 파일이 생성되지 않음** 을 둘 다 확인. 두 신호 corroborate.
3. **vector 확장**: 단일 vector 가 아니라 최소 (i) 파일 write, (ii) 기존 파일 modify, (iii) 임의 바이너리/네트워크 시도(가능하면) 를 포함하도록 확장. 미시험 vector 는 limitation 으로 disclosure.
4. **approval 시험**: `-a never` 가 un-sandboxed escalation 을 만들지 않는지 확인(차단이 escalation 으로 우회되지 않음).
5. **결과 분류**: 모두 차단 → "tested vectors 에 대해 reviewer-safe precedence verified"(여전히 blanket guarantee 아님). 어느 하나라도 통과 → reviewer-safe invocation **not verified**, 구조적 guard 부재 risk 로 즉시 disclosure(조용히 진행 금지).
6. **hardening 후보(Batch C 결정)**: 명시 `-s read-only -a never` 에 더해 `--ignore-user-config` 를 추가 전달해 permissive global config 자체를 미로딩(belt-and-suspenders). 단 `--ignore-user-config` 는 auth 외 user config 를 무시하므로 부작용(필요한 비-permissive 설정 손실) 검토 필요 — Batch C 의 trade-off 분석 대상. `--dangerously-bypass-approvals-and-sandbox` 는 절대 사용 금지.
7. **result-artifact 책임**: G2-V4 에 따라 result.md 기록을 `--output-last-message`(runner) 로 유지하고 source tree·review target 은 read-only 유지. reviewer 가 직접 써야 하는 구조로 바꾸지 말 것.

### 2e. reviewer가 source/docs/scripts/tests에 write/approve 못함을 증명하는 방식
- **차단 증명**: 2d-2(모델 보고 + 독립 FS 확인 corroborate) — 단일 신호(모델 자기보고)만으로 닫지 않는다.
- **approve 증명**: `-a never` + (시험) escalation 부재.
- **범위 한정 증명**: writable surface 가 review output location(또는 `--output-last-message` target)으로 제한되고 source tree 가 read-only 임을 확인.
- 미시험 vector·플랫폼·버전은 항상 limitation 으로 명시.

## 3. Evidence plan (verified / not verified 기준)

- **verified 로 분류하는 조건**: (a) CLI/config inspection 으로 surface·허용값·실패거동을 확인했고, (b) read-only probe 의 run-fact 가 이를 corroborate 하며(해당 시 독립 FS 확인 포함), (c) reviewer-readable evidence 로 보존됨(`log/evidence/batchA/validation-evidence.md`).
- **not verified 로 보고하는 조건**: review-run 통합 미구현(G1-NV1/NV2), vector/플랫폼/버전 미포괄(G2-NV1/NV2), 또는 run-fact 미확보. **effort 적용 run-fact 를 확보 못하면 `not verified`** 로 보고하고 성공처럼 암시하지 않는다. **global config precedence 를 실증 못하면 reviewer-safe invocation 은 `not verified`** 로 보고한다(본 Batch 에서는 단일 vector 한정 verified).
- **evidence 지위**: log/smoke/run output/evidence file 은 runtime supporting material 이지 source-of-truth 아님.

## 4. Non-operational boundary (이 spec 의 결론)

- **U10 effort override**: Codex CLI capability = verified; **review-run 통합 = not verified(미구현)**. → **U9 operational = not verified / not operational.**
- **reviewer-safe invocation**: permissive global config 하 precedence = **tested write vector 에 대해 verified**; **blanket guarantee = not verified.** → reviewer-safe invocation 보장 주장 금지(현 단계).
- 본 Batch A 의 어떤 결과도 implementation/commit/push/release/adoption 승인이 아니며, U9 operational·reviewer-safe 보장을 성립시키지 않는다. "가능해 보임/문제 없어 보임/아마 적용됨" 을 operational claim 으로 번역하지 않는다.

## 5. Batch A 가 하지 않은 것 / approval boundary

- source/script/test/config 미변경(`review-run.ps1`·`config/reviewer.json`·skill·contract·policy·global/user config 불변).
- Batch B/C/D 미진입. implementation 미진입.
- 산출물: 본 spec 문서 1개 + STATUS 최소 pointer + runtime evidence(gitignored).
- 다음 단계(Batch B effort override 구현 / Batch C reviewer-safe hardening+negtest 자동화)는 각각 별도 scoped `/goal` + review gate + 사용자 commit/push 승인 필요.

## 6. 다음 single action

본 spec 사용자 검토·채택 후 → **Batch B**(per-invocation effort override 를 review-run 에 wiring + 1d spec 의 resolved-effort/run-fact capture + 테스트)를 별도 scoped `/goal` 로 진입. Batch C(reviewer-safe hardening + 2d negative test 자동화)는 함께 또는 연속(두 축이 U9 operational 의 공동 전제). 그 전까지 source/script/test/config 변경·implementation 진입 금지.
