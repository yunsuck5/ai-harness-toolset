# Review Artifact Perspective Layout Plan

> **Status (implemented — strict C1, done) — 2026-06-05.** 이 문서가 정한 **C1** target layout (`log/review/<review-task-id>/<perspective>/pass-NN/` — 작업 식별자 / perspective / corrective attempt 를 별도 path segment 로 분리)이 **현재 working tree 에 구현되었다.** 초기 구현(commit `5da6664`)은 perspective 를 optional 로 두고 two-level 을 backward-compatible default 로 남겼으나, **사용자 판단으로 그 legacy compatibility 를 폐기하는 strict C1 follow-up 이 후속 적용됐다(이 Status 가 최신 상태):** `-Perspective` 는 `review-prepare/run/verify` 에서 **필수**(미지정 / 빈 값 fail-fast, **two-level fallback 없음**), canonical layout 은 **three-level only**, 과거 two-level artifact 는 legacy manual-readable runtime record 일 뿐 tool 이 발급/검증하지 않는다(migration / 삭제 없음). 구현 surface: `scripts/lib/path.ps1`(`Test-ValidPerspective` / `Assert-ValidPerspective` / `Get-ReviewPassParent` / `Assert-InTaskRoot` + `Get-ReviewPassDir` — perspective **required**, empty-as-omitted 제거), `scripts/review-prepare.ps1` / `review-run.ps1` / `review-verify.ps1`(`-Perspective` 필수, no-perspective fail-fast), `tests/{path,review-prepare,review-run,review-verify}.Tests.ps1`(three-level + no-perspective-fails + perspective validation + task-root containment TC), `docs/contracts/review/REVIEW_RESULT_CONTRACT.md`, `templates/review-input.md`(+ `## Review perspective` informational section) / `templates/review-result.md`, `snippets/claude-skills/ai-harness-review/SKILL.md`, `README.md`, `docs/user_guide/OPERATOR_GUIDE_KR.md`, `tests/README.md`, **그리고 managed-block snippet source `snippets/CLAUDE_SNIPPET.md` / `snippets/AGENTS_SNIPPET.md`(strict three-level canonical 로 정합 — Q8 reversed: repo source snippet 을 이번 batch 에서 갱신, 더 이상 후속 batch 로 미루지 않음).** **Codex review: 초기 구현 task `s6-c1-perspective-impl-2026-06-05`(pass-01 no → … → pass-05 yes; commit `5da6664`), strict C1 follow-up task `s6-strict-c1-canonical-layout-2026-06-05`(final pass-07 `yes`, blocking 0 / non-blocking 0; commit `460ee3e`).** Status / detail home: `docs/systems/review/STATUS.md`. **Closeout (done):** commit `460ee3e`(28파일) + push 완료; **global (channel 3) engine + Claude/Codex managed-block + deployed skill 사본 전부 strict three-level 로 갱신(adoption 완료).** verify_pass(pre-commit guard + `verify-ps1` + full Pester + `review-verify -RequireResult`). 아래 본문(§1–§12)은 채택된 C1 **design 기록**으로 보존한다(누적 narrative 는 git history).

## Document character

- **성격**: design 기록 문서(이 subsystem 의 design home). 이 문서가 정한 C1-first design 은 **현재 working tree 에 구현되었다**(위 Status 블록; 구현 surface + Codex 재검토 task 는 거기에 열거). 본문 §1–§12 는 그 채택된 design 의 기록으로 보존된다 — 문서 자체는 코드가 아니며(읽기/쓰기로 runtime 을 바꾸지 않음), 구현된 target = **C1-first** 다. "권장(recommended)" / "추천(recommendation)" 은 design 시점의 표현이며 최종 채택은 C1-first 다. commit / push / global update 완료(commit `460ee3e`; adoption 완료).
- **무엇을 결정하려는가**: review artifact 의 의미 축(작업 식별자 / perspective / corrective attempt)을 path 구조에서 어떻게 분리할지(이하 **S6**). 이 문서는 선택지(C1 / C2 / C3 / hybrid)를 비교하고, **사용자 design constraint** 를 만족하는 추천(C1-first)을 제시한다. **구현 batch 도, 구현 승인도 아니다.**
- **사용자 design constraint (2026-06-05, 권위 입력)**: (1) 폴더 이름 하나에 작업 식별자와 review perspective 두 의미를 같이 넣지 않는다. (2) `<review-task-id>` 는 작업 / goal / review gate 를 의미한다. (3) perspective 는 **별도 path segment** 로 분리된다. (4) `pass-NN` 은 해당 perspective 안의 corrective attempt 를 의미한다. (5) AI 는 긴 설명보다 path/name/artifact shape 를 먼저 보고 판단하므로, 의미 축은 **path 구조에서 분리되어 보여야** 한다.
- **이전 버전 대비 변경(stale 사유)**: 직전 pass(`log/review/s6-perspective-artifact-layout-design-2026-06-05/pass-01`)는 추천을 H1(C2 + C3b)로 둔 문서를 review 했고 `yes with risk` 를 받았다. 그 verdict 의 risk 는 "H1 은 convention-only tradeoff(파서 없음·64자 예산·`--` 해석)를 사용자가 명시 수용해야 함" 이었다. 사용자가 위 design constraint 를 명시함으로써 **그 tradeoff 를 수용하지 않고 의미 축 분리를 우선** 하기로 결정했다. 따라서 이전 review 는 stale 이며, 본 개정판은 C1-first 로 corrected-state re-review 대상이다.
- **source of truth / 권위 순서**: 상위 권위는 사용자 design constraint, 그리고 `docs/contracts/review/REVIEW_RESULT_CONTRACT.md`(§1 canonical artifact layout, §3 dual-authorship, §10 non-goal)와 `docs/systems/review/REVIEW_POLISHING_DECISION_RECORD.md`(`dual-perspective coverage` 및 5개 축 정의)다. 충돌 시: 사용자 constraint 가 design 방향을, contract 가 기존 기계적 규약을 규정한다. 이 문서는 그 위에 얹히는 track design home 이다.
- **single-home-plus-pointers**: 이 문서는 `STATUS.md` / `BACKLOG.md` / `SKILL.md` 내용을 복제하지 않고 pointer 로만 참조한다(`docs/policies/DOCS_OPERATING_MODEL.md` §1, §3).
- **placement / naming 근거**: 위치 `docs/systems/review/` 는 이 subsystem 의 track design/spec/plan 문서가 모이는 곳이다(`docs/README.md` §5). 파일명은 `REVIEW_<subject>_<KIND>` 패턴 — `ARTIFACT_PERSPECTIVE_LAYOUT` + `_PLAN`.

## 1. Problem (historical design-time problem statement)

> **Design-time problem statement — historical, NOT a current-state claim.** 본 §1 은 이 design 을 시작한 시점의 문제 상황(당시의 two-level layout)을 기록한다. **현행 canonical 상태가 아니다.** 현재의 canonical layout 은 strict C1 three-level (`log/review/<review-task-id>/<perspective>/pass-NN/`, `-Perspective` required) 이며, current source-of-truth 는 이 문서 상단의 **Status block** 과 `docs/contracts/review/REVIEW_RESULT_CONTRACT.md` 다. 아래의 "현재 artifact layout" / "두 축뿐이다" 같은 표현과 인용된 옛 `SKILL.md` 문구는 design 시점 기준의 historical 기록으로 읽는다.

- **현재 artifact layout**: `<ProjectRoot>/log/review/<review-task-id>/pass-NN/` — 두 축뿐이다(`REVIEW_RESULT_CONTRACT.md` §1; `SKILL.md` "scripts emit the canonical two-level `<review-task-id>/pass-NN/` layout directly"). pass 마다의 canonical record 는 같은 pass 디렉터리 안의 `input.md` + `result.md` 한 쌍이다.
- **`pass-NN` 은 perspective 가 아니라 corrective-loop attempt 축이다**: `pass-NN` 은 정의상 "같은 review task 안에서 corrective loop 의 각 Codex review attempt"(`REVIEW_RESULT_CONTRACT.md` §1; `templates/review-input.md`; `SKILL.md`)다. 따라서 `pass-NN` 의 증가는 *동일 관점에서의 수정-재리뷰* 이지 *다른 관점* 이 아니다.
- **perspective 축에는 native slot 이 없다**: `REVIEW_POLISHING_DECISION_RECORD.md` 는 `perspective coverage` / `invocation packaging` / `invocation count` / `artifact pass count` / `corrective loop count` 를 **서로 다른 축** 으로 명시한다(§2 인용). 그러나 layout 은 그중 `artifact pass count`(=`pass-NN`)만 native 로 표현하고, `local correctness review` vs `system coherence review` 같은 **perspective** 는 디렉터리 어디에도 1급으로 드러나지 않는다.
- **path/name-first AI behavior 논거는 C1(별도 path segment)을 더 강하게 지지한다**: AI(operator-role / reviewer-role 모두)는 긴 prose 보다 **path / name / artifact shape 를 먼저 보고** 판단한다. 의미 축이 path 구조에서 *분리된 segment* 로 보이면(즉 `<task>/<perspective>/pass-NN/`) 무엇이 작업 식별자이고 무엇이 perspective 이고 무엇이 corrective attempt 인지 경로만으로 즉시 식별된다. 반대로 perspective 를 *이름 접미사* 나 *prose* 에만 두면 AI 는 매번 그것을 분해/재확인해야 한다 — 이는 path-first 판단 경향과 정면으로 어긋난다. 즉 이 논거는 **이름 접미사(C2)보다 path segment 분리(C1)를 더 강하게 지지** 한다.
- **task-id 에 perspective 를 suffix 로 붙이는 방식(`foo--local-correctness`)도 의미를 섞는 convention-only workaround 다**: 한 폴더 이름(`<review-task-id>`)에 *작업 식별자* 와 *perspective* 두 의미를 동시에 담는다. 이는 사용자 design constraint (1)("폴더 이름 하나에 두 의미를 넣지 않는다")을 **위반** 하며, 분해는 파서 없는 문서 규약("마지막 `--` 이후 = perspective")에만 의존한다. 따라서 task-id suffix 는 **target design 이 아니라 convention-only workaround** 다(§5 C2, §6).
- **이 마찰의 origin(증거)**: `log/review_polishing/deferred/revpolish-plan-local-2026-06-02/pass-01.md` 신호 1 — `dual-perspective coverage` 를 `two focused invocations` 로 수행할 때 "두 관점을 표현할 native 슬롯이 없다" 가 기록됐고, 그때의 우회는 관점별 별도 task-id(`...-local` / `...-coherence`)였다(= C2 의 informal 선례, 즉 위의 의미-섞임 workaround). 동일 task-id 의 `pass-01`=local / `pass-02`=coherence 안은 perspective 를 corrective 축에 올려 decision record 가 경고한 축 혼동을 일으키므로 기각됐다.

## 2. Current Semantics

현재 의미를 repo 의 source-of-truth(실제 script / contract / decision-record) 기준으로 고정한다.

- **`<review-task-id>` 의 의미**: 하나의 `/goal` 작업 또는 하나의 review gate 단위(`REVIEW_RESULT_CONTRACT.md` §1; `SKILL.md`). Claude Code chat / session id 가 아니다. **검증 규칙(실제 구현)**: `scripts/lib/path.ps1` `Test-ValidReviewTaskId` = `^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$` + `..` 포함 금지(영숫자 시작, 허용 문자 `[A-Za-z0-9._-]`, 최대 64자). 하이픈 허용 → `--` 도 문자 차원에서는 valid.
- **`pass-NN` 의 의미**: 같은 review task 안 corrective loop 의 각 Codex review attempt. write-once. **검증 규칙**: `Test-ValidPass` = `^pass-(0[1-9]|[1-9][0-9])$`(대소문자 구분 lowercase, `pass-01`..`pass-99`). `Get-NextPassName` 은 task 디렉터리를 스캔해 다음 번호를 발급한다.
- **path 조립(실제 구현, C1 이 바꾸는 핵심)**: `Get-ReviewTaskRoot` = `<logRoot>/review/<review-task-id>`; `Get-ReviewPassDir` = `<taskDir>/<pass>` — **중간 segment 없이** task 디렉터리 바로 아래에 `pass-NN`. `Get-NextPassName` 은 `<taskDir>` 직하의 `pass-NN` 만 스캔. `Assert-InReviewRoot`(`scripts/lib/path.ps1:321`)는 경로가 `<logRoot>/review/` 내부인지 **review-root prefix** 로만 검증한다(`:347`). 현재 `Test-ValidReviewTaskId`(`:244`)는 `..` 와 path separator 를 막고 charset/length 를 제한해 task-id 가 review-root 밖이나 다른 task 로 새지 못하게 한다. → **C1 의 path-safety 핵심(아래 §6/§8/§10)**: `<perspective>` 는 operator-supplied 로 filesystem path 를 구성하므로 **`Test-ValidReviewTaskId` 와 동급의 segment validation(`..` 금지, path separator(`/`, `\`) 금지, safe charset/length, single segment)** 을 받아야 한다. `Assert-InReviewRoot` 의 review-root prefix 검증은 **필요하지만 충분하지 않다** — `<logRoot>/review/` 안이라는 것만 증명할 뿐 *의도한 `<task>/` 안* 임을 증명하지 못하므로, perspective 가 `..`/separator 를 담으면 같은 review-root 안 **다른 task** 로 traverse 하면서도 containment 를 통과할 수 있다. 따라서 C1 은 perspective segment validation **+ task-root containment**(생성될 pass dir 이 의도한 `<taskDir>/` 하위인지 검증)를 함께 요구한다(§6/§8/§10).
- **canonical record per pass(불변)**: 같은 `pass-NN/` 안의 `input.md` + `result.md` 한 쌍. sidecar JSON / hash / external staging 금지(`REVIEW_RESULT_CONTRACT.md` §1, §10). **C1 은 이 "pass 당 2-file" 규약을 바꾸지 않는다** — path 에 segment 하나를 더할 뿐 pass 디렉터리 내부 구조는 동일하다(그래서 §10 의 2-file non-goal 을 위반하지 않는다; §1 의 layout *서술* 만 2-level→optional 3-level 로 개정 대상).
- **5개 축(`REVIEW_POLISHING_DECISION_RECORD.md`; `REVIEW_RESULT_CONTRACT.md` §6b / `SKILL.md` step 7)**:
  1. **perspective coverage** — `dual-perspective coverage`(`local correctness review` + `system coherence review`) / `coverage-limited review` / `no-reviewable-change report`. *coverage 정책이지 invocation count 아님.*
  2. **invocation packaging** — `single-invocation dual-perspective packet` / `two focused invocations` / 기타.
  3. **invocation count** — reviewer 실제 호출 횟수(품질 보증 아님).
  4. **artifact pass count** — `artifact pass-NN` attempt 수.
  5. **corrective loop count** — `corrected-state re-review` 반복 횟수.
- **"2-pass review" 와 `pass-01`/`pass-02` 는 다른 개념**: 두 관점(축 1) 또는 두 호출(축 3)은 디스크의 `pass-01`/`pass-02`(축 4)와 동의어가 아니다. S6 가 노리는 분리는 perspective(축 1)를 corrective(축 4/5)와 섞지 않는 것이며, 사용자 constraint 는 그 분리를 **path segment 차원** 에서 요구한다.

## 3. Goals

- **세 의미 축을 path 구조에서 분리한다(신규 명시 goal)**: 작업 식별자(`<review-task-id>`) / perspective(`<perspective>`) / corrective attempt(`pass-NN`) 가 **각각 다른 path segment** 로 보이게 한다.
- **design constraint: 폴더 이름 하나에 두 의미를 넣지 않는다(신규)**: 작업 식별자와 perspective 를 한 디렉터리 이름에 합치지 않는다(사용자 constraint (1)).
- perspective(축 1)와 corrective attempt 축(축 4/5)을 혼동 없이 분리한다.
- review viewpoint 를 **path 만 보고 식별 가능** 하게 한다(path/name-first 부합, §1).
- 기존 `log/review/<task>/pass-NN/` artifact 를 **깨지 않는다**(migration 강제 금지; §5/§7).
- **solo-maintainable / local-first** 운용 유지(daemon / DB / cross-run aggregation / sidecar 도입 금지).
- `pass-NN` 의 corrective-attempt 의미를 **보존** 한다(perspective 를 `pass-NN` 에 올리지 않는다).
- 구현 비용을 인정하되, 의미 축 명료성이 비용을 정당화하는지를 staged 하게 검증 가능하게 한다(§9).

## 4. Non-goals

- 기존 `log/review` artifact 의 **migration / rewrite**.
- review system 의 **full redesign**.
- **S8 docs de-dup / tombstone / parallel-docs cleanup**(별도 handoff track; 본 문서 진입 금지).
- **planning-system / sequential-thinking** work.
- **reviewer result contract vocabulary 변경**(`yes` / `no` / `yes with risk` 불변).
- **`pass-NN` 의미 변경**(corrective-loop attempt 로 유지).
- **pass 당 canonical 2-file 규약의 expand 또는 sidecar 도입**(`REVIEW_RESULT_CONTRACT.md` §10 non-goal 그대로; C3a sidecar 배제 근거 — §5 C3). *주의*: C1 은 layout 에 path segment 를 더하지만 pass 내부 2-file 은 그대로이므로 이 non-goal 과 충돌하지 않는다.
- **새 parser / verifier / lint gate 로 perspective 강제**(perspective 는 optional; deterministic gate 신설 안 함).
- **자동 perspective 분류 / inference**(operator 가 명시 지정).

## 5. Design Options

사용자 명명 대응: **A안(no-op)**, **B안 = task-id naming convention = C2**, **C안 = artifact layout perspective axis = C1**.

### No-op (A안 — 추천 아님)

`<review-task-id>` 관행에만 의존. **추천하지 않는다**: §1 의 path/name-first 마찰이 구조적으로 남고, 사용자 constraint (1)/(3)을 전혀 만족하지 못한다.

### C1. Perspective subdirectory (= 사용자 C안, 신규 recommended)

```text
log/review/<review-task-id>/<perspective>/pass-NN/
  예) log/review/foo/local-correctness/pass-01/
      log/review/foo/system-coherence/pass-01/
```

의미: `<review-task-id>` = 작업/goal/review gate, `<perspective>` = review viewpoint, `pass-NN` = 해당 perspective 안의 corrective-loop attempt.

- **장점 (사용자 constraint 와 직접 정합)**:
  - **의미 축 분리**: 작업 식별자 / perspective / corrective attempt 가 각각 별도 segment — 한 폴더 이름에 두 의미를 섞지 않는다(constraint (1)/(2)/(3)/(4) 모두 충족).
  - **path 만 보고 판단 가능**: AI 가 경로만으로 즉시 세 축을 식별(constraint (5)).
  - **`pass-NN` semantics 보존**: 각 perspective 디렉터리 안에서 `pass-NN` 은 그대로 corrective 축이며 perspective 와 섞이지 않는다(decision record 가 경고한 혼동을 구조적으로 차단).
  - **장기 유지보수성**: 의미 축이 구조에 박혀 있어 관점이 늘어나거나 `two focused invocations` 가 빈번해져도 명명 규약 drift 없이 확장된다.
- **단점 (영향 큼, 숨기지 않음)**:
  - `scripts/lib/path.ps1` — `Get-ReviewPassDir`(중간 segment 추가) / `Get-NextPassName`(perspective 디렉터리별 `pass-NN` 스캔) 변경 + `Test-ValidPerspective` 신설.
  - `scripts/review-prepare.ps1` / `review-run.ps1` / `review-verify.ps1` — `-Perspective` 파라미터 추가·전달 + old/new layout 분기.
  - `tests/review-prepare.Tests.ps1` / `review-run.Tests.ps1` / `review-verify.Tests.ps1` — old/new layout TC 추가.
  - `SKILL.md` / `REVIEW_RESULT_CONTRACT.md` §1 / `templates/review-input.md` — layout 서술(2-level→optional 3-level) 갱신.
  - **maintenance mode 기준 구조 변경 = "new feature"** 로 별도 scoped 승인 필요(§8, §10).
- **backward compatibility**: perspective optional → 미지정 시 기존 2-level 발급(§5 fallback, §7).

### C2. Perspective in review-task-id (= 사용자 B안 — fallback / interim 으로 재분류)

```text
log/review/<review-task-id>--local-correctness/pass-01/
log/review/<review-task-id>--system-coherence/pass-01/
```

- **지위 변경(중요)**: 이전 버전의 primary recommendation 에서 **fallback / interim / compatibility convention** 으로 낮춘다.
- **장점**: tooling 변경 0(현재 `Test-ValidReviewTaskId` 가 하이픈을 허용하므로 `foo--local-correctness` 는 그대로 valid 한 task-id; prepare/run/verify/lib 변경 불필요). 경로 이름에 perspective 가 보이긴 한다.
- **단점 (사용자 constraint 미충족)**:
  - **semantic mixing 잔존**: 한 폴더 이름(`<review-task-id>`)에 작업 식별자 + perspective 두 의미를 함께 담는다 → 사용자 constraint (1) 위반.
  - **convention-only**: 구분자(`--`)·perspective 어휘·"마지막 `--` 이후 = perspective" 해석이 파서 없는 문서 규약일 뿐(강제력 없음).
  - **64자 예산**: task-id 전체 ≤64자. 예: base `s6-perspective-artifact-layout-design-2026-06-05`(48자) + `--system-coherence`(18자) = 66자 → `review-prepare` 가 거부(minimal reproducible check 로 확인). 즉 base ≤ ~46자 제약.
  - **base/perspective 경계 모호**: base-task-id 가 이미 하이픈/`--` 를 포함하면 분해가 모호.
- **용도**: old tooling compatibility 나 임시 운용(C1 구현 전 interim)에는 쓸 수 있으나 **target design 은 아니다**.

### C3. Metadata marker

```text
변형 (a) sidecar 파일:  log/review/<review-task-id>/<perspective>/pass-01/perspective.txt   ← rejected
변형 (b) input.md 섹션:  ## Review perspective
                         local-correctness
```

- **변형 (a) sidecar — 계속 rejected**: pass 디렉터리에 별도 파일을 두는 것은 `REVIEW_RESULT_CONTRACT.md` §1("canonical artifact 는 두 파일; 다른 sidecar 파일은 contract 의 일부가 아니다") + §10 non-goal + STATUS "no sidecar JSON / no external staging" 에 위배.
- **변형 (b) input.md `## Review perspective` 섹션 — C1 의 보조 metadata surface 로 유지**: `templates/review-input.md` 의 informational section 관행(`## Stage` 등)과 동일하게, perspective 를 canonical artifact(input.md) *내부* 에 기계 판독 가능하게 기록(sidecar 아님). 단 **path 구조의 보조 기록이지 primary separation mechanism 이 아니다** — 1급 분리는 C1 의 path segment 가 담당한다.
- **C1 과의 관계**: C3b 는 C1 의 path segment 와 *중복적이지만 보완적* 이다(경로의 perspective 를 artifact 안에서도 재확인 가능). C2 의 의미-섞임을 해소하지는 못한다.

### Hybrid option

- **H(target) = C1 + C3b(보조)**: path segment 로 perspective 1급 분리(C1) + input.md `## Review perspective` 보조 기록(C3b). 사용자 constraint 를 충족하는 target.
- **H1 = C2 + C3b (이전 버전 추천 — 이제 rejected-as-primary / fallback)**: 의미-섞임(C2)이 남아 사용자 constraint (1)을 충족하지 못하므로 더 이상 primary 가 아니며, C1 구현 전 interim 으로만 허용.

## 6. Recommended Design

**추천(개정): C1-first — `log/review/<review-task-id>/<perspective>/pass-NN/` 를 target design 으로 한다. 보조로 C3b(input.md `## Review perspective`)를 둔다.**

근거(사용자 design constraint + evidence):

- **사용자 constraint 와의 정합**: C1 은 작업 식별자 / perspective / corrective attempt 를 각각 별도 segment 로 분리하여 constraint (1)~(5)를 모두 충족한다. C2 의 task-id suffix 는 한 폴더 이름에 두 의미를 섞어 constraint (1)을 위반하므로 target 이 될 수 없다.
- **path/name-first 논거 재해석**: §1 의 "AI 는 path/name 을 먼저 본다" 는 논거는 *이름 접미사* 보다 *path segment 분리* 를 더 강하게 지지한다 — 의미 축이 구조 차원에서 직교하게 보이기 때문.
- **이전 H1 추천의 stale 처리**: 직전 review 의 `yes with risk` risk 였던 "convention-only tradeoff 의 사용자 수용 필요" 를, 사용자가 **수용하지 않고 구조 분리를 우선** 하기로 결정함으로써 H1 은 primary 자격을 잃었다. H1 = C2 + C3b 는 **rejected-as-primary** 이며 C1 구현 전 **interim/fallback** 으로만 남는다.

추천안 상세:

- **artifact path shape**: target = `log/review/<base-task-id>/<perspective>/pass-NN/`. perspective 가 무관하거나 미지정인 review 는 기존 `log/review/<base-task-id>/pass-NN/`(2-level) 그대로(backward-compat).
- **staged implementation 필수**: C1 은 구현 비용이 크므로 한 번에 바꾸지 않고 §9 의 staged batch(path primitives → activation+docs/contract → dogfood/global)로 나눈다.
- **source-of-truth coupling invariant(중요)**: 어떤 committed / activated 상태도 *operator-visible* C1 layout 을 노출하면서 **canonical contract(§1 layout)와 그 contract 가 §"본 contract 는 source-of-truth" 절에서 명시 열거하는 mirror 전부** — `templates/review-input.md` · `templates/review-result.md` · `snippets/claude-skills/ai-harness-review/SKILL.md` · `docs/user_guide/OPERATOR_GUIDE_KR.md` · 루트 `README.md` — **및 `tests/README.md` topology 서술** 이 아직 2-level 만 기술하는 **drift 를 만들면 안 된다.** (별도 class: managed-block 글로벌 payload `snippets/CLAUDE_SNIPPET.md` / `snippets/AGENTS_SNIPPET.md` 의 reviewer artifact location 서술 — §8/§9 Batch 3 에서 명시 처리.) 이를 보장하는 두 가지 허용 형태: (a) behavior-exposing(operator-visible) activation 과 위 mirror wording 을 **같은 batch · 같은 review gate · 같은 commit set · 같은 global activation 으로 함께** 착지시킨다; 또는 (b) script/path-primitive batch 를 **dormant/internal** 로 둔다 — 새 3-level code path 와 verify dual-read 는 들어가되 default 는 old 2-level, `-Perspective` 는 아직 operator-facing 으로 광고/문서화하지 않아 operator-visible behavior 가 불변이고 기존 docs 가 여전히 정확. **단 (b)의 한계**: 추가된 `-Perspective` 파라미터는 미문서화여도 *호출 가능한 interface surface* 다 — 따라서 dormant 가 성립하려면 새 3-level path 가 *실제로 도달 불가/genuinely internal* 이어야 하며(예: 파라미터를 노출하지 않거나 internal gate 뒤에 둠), 만약 파라미터가 호출 가능한 채로 노출되면 form (a)로 전환해 wording 을 같은 batch 에 끌어와 함께 착지시킨다(pass-04 non-blocking concern). 둘 중 하나를 §9 batch 가 반드시 지킨다.
- **legacy 2-level backward compatibility 유지**: C1 채택 후에도 기존 2-level layout 은 계속 읽을 수 있어야 한다(§7). migration 은 하지 않는다.
- **perspective optional 시작, 단 명시되면 new layout 강제**: perspective 미지정 review 는 old 2-level 을 쓸 수 있다(optional 도입). 그러나 perspective 가 **명시된** review 는 반드시 new 3-level(`<task>/<perspective>/pass-NN/`)을 사용한다 — 명시된 perspective 를 task-id 에 도로 섞는 것(C2)은 target 에서 허용하지 않는다.
- **perspective naming + path-safety validation(필수)**: `<perspective>` 는 operator-supplied 이며 filesystem path 를 구성하므로 `Test-ValidPerspective` 는 **`Test-ValidReviewTaskId` 와 동급의 안전 규칙** 을 강제한다 — (i) **single path segment**(중첩 금지), (ii) `..` 금지, (iii) path separator(`/`, `\`) 금지, (iv) safe charset + length 정책(예: `Test-ValidReviewTaskId` 와 동형의 `^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$`), (v) `pass-NN` 형태(`pass-\d\d`) 금지(old/new 구분 모호성 차단). 권장 어휘 `local-correctness` / `system-coherence`(decision record `dual-perspective coverage` 와 정합); enum 고정 vs 자유 문자열은 §12 Q1(단 자유 문자열이라도 위 (i)~(v)는 불변).
- **task-root containment(필수)**: 생성될 pass dir 은 review-root containment(`Assert-InReviewRoot`)만으로 부족하다 — **의도한 `<taskDir>/` 하위인지** 검증해야 한다(task-root containment helper, 예: `Assert-InTaskRoot`). 그래야 perspective 가 (검증을 우회하는) traversal 을 담아도 같은 review-root 안 다른 task 로 새지 않는다(§2/§8/§10).
- **per-perspective reporting semantics(필수 동반)**: `pass-NN` 이 이제 perspective 디렉터리 *안* 에서 매겨지므로, final-report 의 `artifact pass count`(`REVIEW_RESULT_CONTRACT.md` §6b field 4) · final-pass path · operator closeout reporting(`SKILL.md` step 7)은 **per-perspective** 의미로 다시 정의되어야 한다 — 각 perspective 가 자기 `pass-NN` 시퀀스를 갖고, 보고는 perspective 별(또는 명시적 aggregate) 로 한다. C1 채택은 이 reporting 의미 변경을 반드시 동반한다(§8 impact, §12 Q6).
- **C3b 보조**: input.md 에 `## Review perspective` informational section 을 두어 artifact 내부에도 perspective 를 기록(보조, non-primary, parser 강제 안 함).
- **operator workflow**: `review-prepare.ps1 -ReviewTaskId <task> -Perspective <viewpoint>` → `<task>/<perspective>/pass-NN/`. perspective 생략 시 기존 `<task>/pass-NN/`.

## 7. Backward Compatibility

- **old layout (`log/review/<task>/pass-NN/`)는 계속 읽을 수 있어야 한다**: 기존 artifact 와 호출은 그대로 동작. `review-verify` 는 old layout 을 변함없이 검증.
- **new layout (`log/review/<task>/<perspective>/pass-NN/`)를 추가 지원한다**: C1 구현이 이 3-level 을 새로 발급/검증.
- **migration 은 하지 않는다**: 과거 artifact 는 과거 layout 으로 남는다(§4 non-goal).
- **`review-verify` 는 old/new 모두 처리해야 한다**: 한 `<task>/` 아래 직하 children 이 `pass-NN` 이면 old 2-level, perspective 디렉터리(=`pass-NN` 정규식에 맞지 않는 이름)이고 그 아래 `pass-NN` 이면 new 3-level 로 해석. 이 분기가 C1 backward-compat 의 핵심 요구.
- **`review-prepare` 분기**: `-Perspective` 미지정 → old 2-level(`<task>/pass-NN/`) 생성; `-Perspective <v>` 지정 → new 3-level(`<task>/<v>/pass-NN/`) 생성. 즉 default behavior 는 오늘과 동일(미지정 = old).
- **혼합 기간**: 한 repo 안에 old/new task 가 공존할 수 있고 verify 가 둘 다 읽으므로 별도 migration window 가 필요 없다.

## 8. Implementation Impact

C1 이 recommended design 이므로 그 영향을 구체화한다(실제 파일 inspection 기반).

| 파일 | C1 영향(recommended) | C2 영향(fallback) | C3b 영향(보조) | risk / test impact |
|---|---|---|---|---|
| `scripts/lib/path.ps1` | **핵심**: `Get-ReviewPassDir`(중간 `<perspective>` segment) / `Get-NextPassName`(perspective 디렉터리별 pass 스캔) 변경 + **`Test-ValidPerspective` 신설 — single segment, `..` 금지, path separator(`/`,`\`) 금지, safe charset/length(`Test-ValidReviewTaskId` 동형), `pass-\d\d` 금지** + **task-root containment helper(예: `Assert-InTaskRoot`)** — review-root prefix 만으로는 다른 task 로의 traversal 을 못 막으므로 생성 pass dir 이 의도한 `<taskDir>/` 하위인지 검증 + old/new 판별 helper | 변경 없음 | 변경 없음 | C1: path 단위 TC(거부 케이스: `..`/separator/`pass-NN`/cross-task traversal); old/new 판별 모호성 회피 |
| `scripts/review-prepare.ps1` | **핵심**: `-Perspective` 파라미터 + 미지정→old / 지정→new 분기 + pass-dir 조립 | 변경 없음 | (선택) seeded input.md 에 `## Review perspective` 추가 | C1: prepare TC(old/new) |
| `scripts/review-run.ps1` | **핵심**: `-Perspective` 전달 + new pass-dir 해석 | 변경 없음 | 변경 없음 | C1: run TC |
| `scripts/review-verify.ps1` | **핵심**: old/new layout dual-read + containment 검증 | 변경 없음 | 변경 없음 | C1: verify TC(old/new) |
| `tests/review-prepare.Tests.ps1` | old/new prepare + 미지정 default + perspective 검증 TC | (선택) 명명 규약 doc TC | 없음 | 광범위 |
| `tests/review-run.Tests.ps1` | new pass-dir 전달/해석 TC | 없음 | 없음 | C1 |
| `tests/review-verify.Tests.ps1` | old/new dual-read TC | 없음 | 없음 | C1 |
| `docs/contracts/review/REVIEW_RESULT_CONTRACT.md` | §1 layout 을 2-level→optional 3-level 로 개정 + §10 2-file non-goal 재확인(불변) + **§6b final-report schema 의 `artifact pass count`(field 4)·final-pass path 를 per-perspective 의미로 개정** | §1 명명 note(interim) | §1/§2 informational section 언급 | contract 의미 변경(§1+§6b); §3 parser 불변 |
| `snippets/claude-skills/ai-harness-review/SKILL.md` | "two-level layout" 서술(11–24행 외) → "two-level 또는 three-level" 재작성 + **step 7 final-report(perspective coverage / artifact pass count / final pass path)를 per-perspective 로 mirror** | 명명 규약 note(interim) | section 언급 | deployed surface — `§N` pointer 재도입 금지 |
| `templates/review-input.md` | layout 서술 갱신 | task-id 명명 규약 note(interim) | `## Review perspective` informational section + intro 가이드 | wording |
| `templates/review-result.md` | **(필수 — contract mirror)** intro 의 `log/review/<review-task-id>/pass-NN/result.md` layout 서술을 optional 3-level 로 갱신(현재 `:3-5` 가 2-level hard-code) | — | — | contract §"source-of-truth" 절이 명시 열거한 mirror; 누락 시 drift(blocking) |
| `docs/user_guide/OPERATOR_GUIDE_KR.md` | **(선택 아님 — 필수, contract mirror)** review 운용 서술의 현재 two-level topology 참조를 perspective segment 반영으로 갱신 | — | — | operator-visible mirror; "optional" 로 두면 drift(blocking) 재발 |
| 루트 `README.md` | **(필수 — contract mirror)** review layout 블록(`:69-80`)·SKILL flow 서술(`:130`)·contract 표 행(`:160`)·retention 서술(`:62`)의 two-level 참조를 optional 3-level 로 갱신 | — | — | contract §"source-of-truth" 절이 명시 열거한 mirror; 누락 시 drift(blocking) |
| `tests/README.md` | **(필수)** review topology / two-level layout 참조를 old/new 로 갱신 | — | — | docs/test convention; layout 변경 시 누락하면 안 됨 |
| `snippets/CLAUDE_SNIPPET.md` / `snippets/AGENTS_SNIPPET.md` | **managed-block 글로벌 payload** — reviewer artifact location 서술(`<review-task-id>/pass-NN/`, 각 `:27-49` / `:28-50`)이 layout 을 hard-code. C1 이 operator/reviewer-visible 이 되면 이들도 stale. 처리: (옵션 A) global activation rollout(Batch 3)에서 managed-block 갱신 — 단 snippet/managed-block 갱신은 **명시적 user-approved adoption boundary**(CLAUDE.md Adoption rules); 또는 (옵션 B) 의도적으로 2-level-only 로 유지하고 **disclosed mirror asymmetry** 로 명시(선례: STATUS 의 known-concerns hypothesis batch 에서 snippet 을 의도적으로 미변경·asymmetry 로 공시). 어느 쪽이든 **명시 결정** 이며 침묵 누락 금지 | — | — | global payload; adoption boundary; §9 Batch 3 + §12 Q8 |
| `scripts/review-input-verify.ps1` | 변경 불요(`## Review perspective` 는 informational; gate 추가 안 함) | — | — | parser 불변(§4 non-goal) |
| `config/reviewer*.json` | 변경 불요(effort/category 와 무관) | — | — | layout 은 config 와 독립 |
| `log/review_polishing/deferred/revpolish-plan-local-2026-06-02/pass-01.md` | S6 origin 신호(read-only) | — | — | 변경 대상 아님 |

**Final-report / closeout reporting semantics(별도 강조 — blocking 대상이었던 누락 surface)**: C1 은 `pass-NN` 을 perspective 디렉터리 *안* 으로 옮기므로, contract §6b 10-field schema 의 field 4 `artifact pass count`(+ SKILL step 7 의 final pass path / perspective coverage)는 **per-perspective** 로 다시 정의되어야 한다 — 각 perspective 가 자기 `pass-NN` 시퀀스를 갖고, closeout report 는 perspective 별(또는 명시적 aggregate)로 pass count·final-pass-path 를 적는다(§6, §12 Q6). 이는 §1 layout 개정과 한 묶음으로 가는 contract/SKILL 변경이며 "optional" 이 아니다.

요지: **C1 은 `scripts/lib/path.ps1` + `review-prepare/run/verify` + 세 test suite + contract §1·§6b + 그 contract 가 명시 열거한 mirror 전부(SKILL step 7 / `templates/review-input.md` / `templates/review-result.md` / 루트 `README.md` / `OPERATOR_GUIDE_KR.md`) + `tests/README.md` wording 까지 가는 class 4/5 급 변경** 이며 maintenance-mode 별도 승인이 필요하다(`REVIEW_LOCAL_VALIDATION_CLOSEOUT_POLICY_PLAN.md` §6 의 class 4 script/runtime + class 5 parser-adjacent + class 6 test). 이 operator/contract-visible mirror 는 §9 의 coupling invariant 에 따라 behavior-exposing activation 과 **함께** 착지한다. managed-block 글로벌 payload(`CLAUDE_SNIPPET.md` / `AGENTS_SNIPPET.md`)는 adoption boundary 가 있는 별도 class 로 §9 Batch 3 + §12 Q8 에서 명시 처리(옵션 A 갱신 or 옵션 B disclosed asymmetry). C2/C3b 는 docs/wording 차원(class 3)으로 닫히지만 target 이 아니다.

## 9. Implementation Batch Plan

C1-first 를 staged batch 로 제안한다(실제 split 은 구현 batch 가 evidence 로 확정; 더 작게 쪼갤 여지 있음). **모든 batch 는 §6 의 source-of-truth coupling invariant 를 지킨다 — operator-visible C1 layout 노출과 canonical contract/SKILL/template/tests-README/operator-guide wording 은 drift 없이 함께 착지한다.** 그래서 Batch 1 은 *dormant/internal* 로, operator-visible activation 은 Batch 2 에서 wording 과 *한 묶음* 으로 둔다:

- **Batch 1 — path primitives + script support, DORMANT/INTERNAL (class 4/5/6, full suite 기대)**:
  - `scripts/lib/path.ps1`: `Get-ReviewPassDir` / `Get-NextPassName` perspective-aware 화 + `Test-ValidPerspective`(single segment · `..` 금지 · path separator 금지 · safe charset/length(`Test-ValidReviewTaskId` 동형) · `pass-\d\d` 금지) + **task-root containment helper(`Assert-InTaskRoot`)** + old/new 판별 helper. validation/containment 거부 케이스(`..`·separator·`pass-NN`·cross-task traversal)를 path 단위 TC 로 강제.
  - `scripts/review-prepare.ps1` / `review-run.ps1` / `review-verify.ps1`: `-Perspective` 지원 + old/new 분기 + backward-compat. **단 default 는 old 2-level 로 두고 `-Perspective` 를 operator-facing 으로 광고/문서화하지 않는다(dormant)** — 그래야 이 batch 단독 commit 이 contract/SKILL 과 drift 를 만들지 않는다(coupling invariant 형태 (b)).
  - `tests/review-prepare.Tests.ps1` / `review-run.Tests.ps1` / `review-verify.Tests.ps1`: old(미지정 default) + new(perspective 지정) + perspective 검증(거부 케이스) + verify dual-read TC. `verify-ps1` + full Pester 기대.
- **Batch 2 — operator-visible ACTIVATION + 모든 source-of-truth wording 을 함께 (class 3 wording + activation)**:
  - `docs/contracts/review/REVIEW_RESULT_CONTRACT.md`: §1 layout 개정(2-level→optional 3-level; §10 2-file non-goal 불변 재확인) **+ §6b final-report `artifact pass count`(field 4)·final-pass path 를 per-perspective 로 개정**.
  - `snippets/claude-skills/ai-harness-review/SKILL.md`: layout 서술 재작성(deployed self-contained; `§N` pointer 금지) **+ step 7 final-report 를 per-perspective 로 mirror**.
  - `templates/review-input.md`: layout 서술 + `## Review perspective` informational section(C3b). `templates/review-result.md`: intro layout 서술 갱신(contract mirror).
  - 루트 `README.md` **(필수, contract mirror)**: review layout 블록·SKILL flow·contract 표 행·retention 서술의 two-level 참조 갱신.
  - `docs/user_guide/OPERATOR_GUIDE_KR.md` **(필수)** + `tests/README.md` **(필수)**: two-level topology 참조 갱신.
  - 그리고 **이 batch 에서** `-Perspective` 를 operator-facing 으로 노출(문서화)한다 — runtime activation 과 contract + 그 명시 mirror 전부(`review-input.md`/`review-result.md`/SKILL/`README.md`/`OPERATOR_GUIDE_KR.md`) + `tests/README.md` 가 동시 착지하므로 drift 가 없다(coupling invariant 형태 (a)).
- **Batch 3 — dogfood / global update + managed-block payload 결정 (payload surface 가 바뀐 경우)**:
  - 채널 3 global stable install 갱신(SKILL/template/contract/script payload 변경 시). dogfood smoke 로 new layout 발급/검증 확인.
  - **managed-block 글로벌 payload `snippets/CLAUDE_SNIPPET.md` / `snippets/AGENTS_SNIPPET.md`** 의 reviewer artifact location 서술을 명시 처리한다 — (옵션 A) 이 rollout 에서 managed-block 을 optional 3-level 로 갱신(snippet/managed-block 갱신은 **명시적 user-approved adoption boundary** 이므로 별도 승인); 또는 (옵션 B) 의도적 2-level-only 유지를 **disclosed mirror asymmetry** 로 공시(선례 있음). 침묵 누락은 금지 — coupling invariant 의 글로벌-payload 대응(§12 Q8). operator/reviewer-visible 한 repo layout 이 3-level 로 활성화됐는데 deployed payload 가 2-level-only 로 남는 비대칭을 택하면, 그 asymmetry 를 반드시 disclose 한다.

각 batch 는 별도 scoped /goal + Codex review gate + 사용자 commit/push 승인. Batch 1 이 구조 핵심이고 가장 무겁다 — 더 작게 쪼개려면 (1a) path.ps1 + 단위 TC, (1b) prepare/run/verify + 통합 TC 로 분할 가능(둘 다 dormant 유지). **Batch 1 을 dormant 로 두지 않고 operator-visible 로 노출한다면, 그때는 Batch 2 의 wording 을 그 batch 안으로 끌어와 함께 착지시켜야 한다(coupling invariant 형태 (a)) — 어느 쪽이든 operator-visible runtime 과 source-of-truth 가 분리 commit 되어선 안 된다.**

## 10. Risks

- **C1 implementation cost(높음, 숨기지 않음)**: path-primitive + 3 스크립트 + 3 test suite + contract/SKILL/template 변경 + maintenance-mode 별도 승인. 가장 큰 risk 는 **implementation complexity** 다.
- **그러나 user design constraint 상 C1 이 H1 보다 정합적**: H1(C2)의 risk 는 **semantic mixing / convention drift**(작업 식별자와 perspective 를 한 이름에 섞고, 분해를 파서 없는 규약에 의존) 이며, 이는 사용자 constraint (1)을 구조적으로 위반한다. 즉 trade-off 는 "C1 = 구현 복잡도 ↑, 구조 명료성 충족" vs "H1 = 구현 비용 ↓, 의미-섞임/규약 drift 잔존" 이고, 사용자 constraint 가 후자를 배제한다.
- **legacy compatibility risk**: C1 은 path 조립을 바꾸므로 old 2-level 을 반드시 dual-read 로 보존해야 한다(누락 시 기존 task 깨짐). → §7 의 dual-read 가 필수 요구.
- **path-traversal / task-boundary safety risk(중요)**: `<perspective>` 는 operator-supplied 로 path 를 구성하므로, 검증 없이 join 하면 `..`/path separator 가 같은 review-root 안 **다른 task** 로 traverse 하면서도 `Assert-InReviewRoot` 의 review-root prefix 검증을 통과할 수 있다(pass-04 blocking finding). → §6/§8 의 `Test-ValidPerspective`(single segment·`..` 금지·separator 금지·safe charset/length, `Test-ValidReviewTaskId` 동형) **+ task-root containment(`Assert-InTaskRoot`)** 로 차단. review-root containment 는 필요하지만 충분하지 않다.
- **old/new 판별 모호성**: perspective 디렉터리 이름이 `pass-NN` 정규식과 겹치면 2-level/3-level 판별이 모호해진다. → `Test-ValidPerspective` 에서 `pass-\d\d` 형태 perspective 를 금지하여 차단.
- **over-engineering risk**: 의미 축 분리 이득이 path-primitive 변경 비용을 정당화하는지에 대한 risk. → staged batch + perspective optional 도입으로 점진 검증, full redesign 회피.
- **maintenance-mode scope risk**: C1 은 구조 변경 "new feature" 로 별도 scoped 승인 없이는 구현 불가(STATUS).
- **source-of-truth ↔ runtime drift risk(batch ordering + mirror 누락)**: behavior-exposing(operator-visible) script 변경이 canonical 문서·mirror 보다 *먼저* commit/activate 되거나, mirror 일부를 빠뜨리면, runtime 은 C1 을 노출하는데 일부 canonical/mirror 문서는 여전히 2-level 만 기술하는 drift 가 생긴다(pass-02 + pass-03 의 blocking finding). drift 위험 surface 는 contract §1/§6b 와 그 contract 가 명시 열거한 mirror 전부(`templates/review-input.md`·`templates/review-result.md`·SKILL·루트 `README.md`·`OPERATOR_GUIDE_KR.md`) + `tests/README.md`, 그리고 별도 class 인 managed-block 글로벌 payload(`CLAUDE_SNIPPET.md`/`AGENTS_SNIPPET.md`)를 모두 포함한다. → §6 의 **coupling invariant**(mirror 전부 열거) + §9 의 Batch 1 dormant / Batch 2 activation+모든 mirror 동시 착지 + Batch 3 의 managed-block 명시 처리(옵션 A 갱신 / 옵션 B disclosed asymmetry)로 차단.
- **per-perspective reporting-semantics 누락 risk**: `pass-NN` 이 perspective 안으로 들어가면서 final-report `artifact pass count`·final-pass path(§6b / SKILL step 7)를 per-perspective 로 재정의하지 않으면 closeout 보고가 모호해진다(이번 corrected-state 이전의 blocking finding). → §6/§8/§9 Batch 2 에서 per-perspective(또는 명시적 aggregate) 의미를 contract/SKILL wording 과 함께 codify.
- **docs drift risk**: layout 서술이 contract §1/§6b / SKILL / template / tests-README / operator-guide 여러 곳에 흩어짐 → single-home + pointer + coupling invariant 로 완화.
- **migration risk**: 추천안은 migration 0(위험 0). dual-read 미구현 시에만 사실상 호환 깨짐.

## 11. Cleanup / Lifecycle

> **Closeout 완료 (commit `460ee3e`).** 아래는 이 design 의 구현-closeout 처리 기록이다. 초안 작성 시점에는 pre-commit 이었고 일부 단계(commit 해시 보강·BACKLOG tombstone·global adoption)를 commit 시점 후속으로 두었으나 **그 후속 단계는 모두 완료됐다** — 각 항목의 괄호는 현재 done-state 를 반영한다.

- **이 문서가 정한 C1-first design 은 구현·closeout 됐다**(working tree → commit `460ee3e`; 위 Status 블록). 본 §11 의 구현-closeout 처리:
  - **STATUS 갱신(완료)**: `docs/systems/review/STATUS.md` Open/historical 의 S6 strict-C1 bullet (+ Completed-ledger RV-B-08) + 이 문서로의 inbound pointer. commit 해시 `460ee3e` 로 보강됨, bullet 은 done 으로 flip(완료).
  - **BACKLOG RV-B-08 tombstone 추가(완료)**: 본 트랙은 원래 open BACKLOG 행이 아니었으므로(설계 plan 출처, BACKLOG triage 아님) RV-B-06/07 식 `[CLOSED]` tombstone 을 commit 시점에 추가하는 것이 natural follow-up 이었다 — 그 RV-B-08 closed tombstone 은 commit `460ee3e` 시점에 `docs/systems/review/BACKLOG.md` 에 추가됨. tracking 의 1차 home 은 STATUS ledger 가 담당한다.
  - **이 PLAN 문서(완료)**: Status 블록을 done 으로 갱신, commit 해시 `460ee3e` 보강. 규약이 contract §1 + SKILL 로 흡수되었으므로 향후 retirement note 로 축소 가능(별도 결정). "latest state 를 docs 가 반영, 누적 서술은 git history" 원칙.
- **STATUS inbound pointer 는 이 구현-closeout 에서 wiring 했다** — 설계-doc commit 단계의 일시적 orphan([[feedback_planning_doc_scope_defer_pointer]])은 해소됨. commit / push / global (channel 3) update / managed-block snippet adoption 은 모두 완료됨(commit `460ee3e`).
- **git history 가 historical source, docs 는 latest state**: 본 문서는 현재 design 안만 담고, 과거 우회(§1 origin)·이전 H1 추천은 §Document character 의 stale 기록 + path pointer 로만 참조한다.
- **S8 는 이번 문서에서 수행하지 않음**: docs de-dup / tombstone 은 별도 handoff track(§4 non-goal).

## 12. Open Questions (resolved by the implementation batch)

> **Resolved — 2026-06-05 (strict C1 follow-up 반영, 이 note 가 최신).** 아래 design-time open questions 의 확정: **Q1** = 자유 문자열 + path-safety 불변(`Test-ValidPerspective`; 권장 어휘 `local-correctness` / `system-coherence`, enum 강제 안 함); **Q2** = `-Perspective <viewpoint>`; **Q3** = **perspective 필수 — two-level default 폐기**(초기 구현 `5da6664` 은 미지정=two-level default 였으나 strict C1 follow-up 에서 제거; 미지정 / 빈 값 fail-fast, two-level fallback 없음, 과거 two-level 은 legacy manual-readable only); **Q4** = 구현 완료(done; commit `460ee3e`, push + global adoption 완료); **Q5** = C2 interim 불채택(C1 직접 구현); **Q6** = per-perspective reporting(contract §6b.1 field 4 / SKILL step 7); **Q7** = form (a) — operator-visible activation + 모든 mirror wording 동시 착지; **Q8** = **option A(반전) — repo source snippet `CLAUDE_SNIPPET.md` / `AGENTS_SNIPPET.md` 을 strict three-level 로 이번 batch 에서 갱신**(초기 구현의 option B disclosed asymmetry 폐기); 단 global/user managed block 의 실제 adoption 은 commit/push 후 별도 boundary. 아래 목록은 design 시점 기록으로 보존한다(누적 narrative 는 git history).

1. **perspective enum 을 고정할지** — 최소 enum(`local-correctness` / `system-coherence`)으로 시작할지, 자유 문자열을 허용할지. (운용 데이터 후 결정; decision record 의 "category 는 운용 데이터 후" 와 동일 보수 자세.)
2. **review CLI option 이름** — `-Perspective <viewpoint>` 를 제안. 다른 이름(`-View`, `-Lens`)을 쓸지.
3. **perspective 미지정 default 를 old layout 으로 둘지** — 추천안은 미지정 = old 2-level(backward-compat). 이를 확정할지, 아니면 일정 시점 후 new layout 으로 default 이동할지.
4. **C1 implementation 을 지금 할지 handoff 후 할지** — 이 문서는 design 만. 구현은 별도 scoped /goal + review gate + 사용자 승인(특히 C1 은 maintenance-mode 별도 승인). S8 track 과의 순서도 사용자 결정.
5. **C2 fallback 을 허용할지** — C1 구현 전 interim 으로 task-id suffix(C2)를 한시 허용할지, 아니면 perspective 분리는 오직 C1 구현 후에만 허용하고 그 전에는 별도 task-id(의미-섞임 인지) 관행을 그대로 둘지.
6. **per-perspective vs aggregate reporting** — final-report `artifact pass count`·final-pass path(§6b / SKILL step 7)를 perspective 별로 보고할지, perspective 별 + 명시적 aggregate 둘 다 둘지, 또는 aggregate 만 둘지. (§6/§8 은 per-perspective 를 기본으로 제안하되 형태는 구현 batch 가 확정.)
7. **batch coupling 형태** — §9 의 coupling invariant 를 (a) activation+wording 동시 batch 로 지킬지, (b) Batch 1 dormant + Batch 2 activation 으로 지킬지. 추천은 (b)(dormant)이나 최종은 구현 batch 결정.
8. **managed-block 글로벌 payload(`CLAUDE_SNIPPET.md`/`AGENTS_SNIPPET.md`) 처리** — C1 activation 시 (옵션 A) global rollout(Batch 3)에서 managed-block 의 reviewer artifact location 서술을 optional 3-level 로 갱신할지(명시적 adoption boundary), 또는 (옵션 B) 의도적 2-level-only 유지를 disclosed mirror asymmetry 로 둘지. 어느 쪽이든 침묵 누락 금지.

---

*이 문서가 정한 C1-first design 은 working tree 에 구현되었고 Codex corrected-state review(초기 task `s6-c1-perspective-impl-2026-06-05`, strict C1 follow-up task `s6-strict-c1-canonical-layout-2026-06-05`)로 수렴했다(Status 블록). 본 문서는 그 채택된 design 의 기록 home 으로 보존된다. commit / push / global (channel 3) update / managed-block snippet adoption 은 모두 완료됐다(commit `460ee3e`).*
