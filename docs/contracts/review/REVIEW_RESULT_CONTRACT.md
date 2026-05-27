# Review Artifact Contract

본 문서는 한 번의 review task 가 어떤 artifact 로 닫히는지의 canonical contract 다. canonical artifact 는 두 파일이며 다른 sidecar 파일은 contract 의 일부가 아니다.

```text
<ProjectRoot>/log/review/<review-task-id>/
  pass-01/
    input.md
    result.md
  pass-02/
    input.md
    result.md
```

`input.md` 는 operator-role AI (Claude Code) 가 작성한다. `result.md` 는 Codex reviewer 가 작성한다. script 는 위 두 파일에 대한 deterministic gate 만 담당하고, 의미 판단은 하지 않는다.

본 contract 는 source-of-truth 이며, `templates/review-input.md` · `templates/review-result.md` · `snippets/claude-skills/ai-harness-review/SKILL.md` · `docs/user_guide/OPERATOR_GUIDE_KR.md` · `README.md` 는 이 contract 를 mirror 한다. 본문이 충돌하면 본 contract 가 우선한다.

## 1. Review task and pass directory

review record 는 두 단계 디렉터리로 닫힌다.

- `<review-task-id>` — 하나의 Claude Code `/goal` 작업 또는 하나의 review gate 단위. **Claude Code chat / session id 가 아니다.** 한 Claude Code 세션 안에서 서로 다른 주제의 `/goal` 이 여러 개 진행되면 각각 별도의 `<review-task-id>` 디렉터리를 사용한다. 자리: `<ProjectRoot>/log/review/<review-task-id>/`.
- `pass-NN` — 같은 review task 안에서 corrective loop 의 각 Codex review attempt. 첫 review attempt 는 `pass-01`, 두 번째 attempt 는 `pass-02`, 이렇게 zero-padded 두 자리로 증가한다. 자리: `<ProjectRoot>/log/review/<review-task-id>/pass-NN/`.
- canonical artifact per pass: 같은 `pass-NN/` 디렉터리 안의 `input.md` + `result.md` 한 쌍. 한 pass 의 record 는 외부 staging folder, sidecar JSON, hash sidecar 어디로도 분산되지 않는다.
- `<ProjectRoot>/log/` 는 gitignored runtime tree 다. canonical artifact 도 commit 대상이 아니다.
- 각 `pass-NN/` 디렉터리는 **write-once** 다. AI 또는 운영자가 같은 pass directory 안의 파일을 손으로 보정하여 review 를 닫지 않는다. 보완은 같은 `<review-task-id>/` 아래에 새 `pass-NN/` 를 만들어 수행한다.
- 다른 review task 의 record 는 다른 `<review-task-id>/` 아래에 둔다. 한 task 의 corrective loop 와 다른 task 의 attempt 를 같은 `<review-task-id>/` 에 섞지 않는다.

## 2. `input.md` — AI-authored review request

`input.md` 는 reviewer 에게 전달되는 모든 입력을 한 파일로 담는다. 본문은 운영 자연어로 작성한다.

required H2 heading set (정확 매치):

- `## Context`
- `## Required inspection paths`
- `## Review questions`
- `## Constraints`
- `## Final verdict`

각 required heading 의 본문 (다음 required heading 직전까지 또는 EOF 까지) 은 비어 있지 않아야 한다. `## Final verdict` section 의 본문에는 정확히 `yes / no / yes with risk` 문자열이 포함되어야 한다.

input.md 안에는 위 5 개의 required heading 외에 다음 informational section 을 추가로 둘 수 있다 (script 가 본문 검사 대상이 아니지만 reviewer 가 본문을 읽는다).

- `## Stage` — design | implementation | test | review | release.
- `## Purpose` — 한 줄 의도.
- `## Target files` — repo-relative path 의 bullet list. forward slash. reviewer 가 읽어야 할 코어 파일 집합. source-managed file 만 담는 자리이며 `log/` 하위 runtime artifact 는 적지 않는다.
- `## Validation evidence` — operator 가 validation execution claim (예: Pester pass count, `verify-ps1` PASS, `git diff --check` clean 등) 의 근거 evidence Markdown file path 를 명시할 자리. 의미와 boundary 는 §3a (R1 Markdown evidence convention) 가 source-of-truth.
- `## Known concerns` — operator 가 review 호출 전에 인지한 compromise / convention deviation / skipped alternative / baseline failure / validation limitation / operator assumption 을 reviewer 에게 사전 disclose 할 자리. recommended sub-categories: convention deviation, skipped alternatives, validation limitations, baseline failures, direct verification not performed, operator assumptions. operator 가 본 section 에 disclose 하지 않은 known concern 이 사후에 발견되면 §7 의 stale-by-omission 규칙이 발동한다.

active review-input placeholder 는 `{{AI_TO_FILL_*}}` namespace (regex `\{\{AI_TO_FILL_[A-Za-z0-9_]+\}\}`) 로 한정된다. operator 가 본 prefix 의 placeholder 를 채우지 않은 채 남겨두면 `scripts/review-input-verify.ps1` 가 `FAIL unreplaced active placeholder` 로 거부한다. 또한 forbidden placeholder phrase (`Replace this placeholder`, `(Provide context here.)`, `(Provide review questions here.)`) 가 본문에 남아 있으면 같은 script 가 거부한다. 본 prefix 외의 generic `{{TOKEN}}` 형태 (예: `{{REAL}}`, `{{example}}`) 는 documentation literal 로 취급되어 verifier 가 거부하지 않는다 — 본 단순화는 Markdown parser / inline-code-span exemption / fenced-code-block exemption / HTML-comment exemption 의 도입이 아니라 active placeholder 와 documentation literal 의 syntax namespace 분리다. 미래의 review-input 활성 placeholder 는 반드시 `AI_TO_FILL_` prefix 를 사용해야 한다 (본 규칙이 active-placeholder safety invariant 다).

작성 주체는 operator-role AI 다. 사용자는 자연어 의도만 표현하고 raw template 을 손으로 채우지 않는다. AI 는 conversation context · git status · diff · 사용자 의도 · 해당 작업의 scope 를 종합해 input.md 본문을 직접 작성한다.

`input.md` 의 shape 기준은 `templates/review-input.md` 다.

## 3. `result.md` — Codex-authored review result

`result.md` 는 Codex CLI 가 `--output-last-message log/review/<review-task-id>/pass-NN/result.md` 로 한 번 작성한다. operator-role AI 또는 운영자가 손으로 작성하지 않는다.

required shape:

- 정확히 1 개의 top-level `## Verdict` heading 이 있다.
- `## Verdict` heading 다음의 첫 비어있지 않은 줄 (앞뒤 whitespace trim 후) 이 lowercase 정확히 다음 셋 중 하나다:
  - `yes`
  - `no`
  - `yes with risk`

거부되는 형태 (의도된 strict parsing):

- 0 개 또는 2 개 이상의 `## Verdict` heading.
- inline 형태 (`Verdict: yes`, `Final verdict: yes`).
- prose 안에 verdict 토큰이 섞인 형태.
- `## Verdict` heading 다음 줄에 verdict 와 다른 토큰이 함께 있는 형태.
- `Yes`, `YES`, `yes.`, `yes with notes` 등 lowercase 정확 매치를 벗어나는 변형.

required disclosure section (각각 정확히 1 회 존재해야 함, parser-enforced):

- `## Blocking findings` — **required (parser-enforced).** blocking finding 으로 판단되는 항목들을 항목별로 기록 (§6 의 blocking finding 정의 참조). verdict `no` 면 1 개 이상 존재; verdict `yes` 또는 `yes with risk` 면 비어 있거나 `none`.
- `## Non-blocking concerns` — **required (parser-enforced).** blocking 은 아니지만 supervisor / 사용자 가 알아야 할 우려 사항을 항목별로 기록. 없으면 `none`.
- `## Review limitations` — **required (parser-enforced).** reviewer 가 직접 검증하지 못한 영역 (예: read-only sandbox 안에서 mutating 명령 실행 불가, operator 가 작성한 evidence file 본문의 시점적 사실성을 reviewer 가 cross-execute 하지 못함) 을 명시. 없으면 `none`.
- `## Assumptions relied on` — **required (parser-enforced).** reviewer 가 verdict 도출 시 신뢰한 전제 (예: operator prose 의 validation result claim 의 truthfulness, R1 evidence file 본문의 정직 작성). 전제가 깨지면 verdict 도 stale. 없으면 `none`.

추가로 자유롭게 둘 수 있는 section (의무 아님):

- `## Findings` — 권장. 발견 사항을 항목별로 기록.
- `## Risks` — `yes with risk` 가 verdict 일 때 권장. supervisor / 사용자 의 explicit acceptance 가 필요한 risk substance.
- `## Notes` — 자유 형식 참고.

위 4 개 required disclosure section (`## Blocking findings`, `## Non-blocking concerns`, `## Review limitations`, `## Assumptions relied on`) 은 `scripts/review-verify.ps1 -RequireResult` 의 deterministic gate 다 — 각 heading 이 정확히 1 회 존재해야 한다. 부재 (count == 0) 또는 중복 (count > 1) 이면 verify FAIL. 본 enforcement 는 mechanical presence/count check 이며, 각 section 본문의 sub-shape (예: `## Known concerns` 의 sub-categories) lint 는 본 enforcement 의 범위가 아니다 — `## Known concerns` 의 sub-shape lint 와 `## Validation evidence` 의 sub-shape lint 는 §10 non-goals 에 기록된 대로 deterministic-lint scope 로 도입하지 않는 결정이다 (reopen 은 concrete evidence 에 한정).

`result.md` 의 shape 기준은 `templates/review-result.md` 다.

### 3b. Mechanical behavior claim verification (P4)

reviewer 의 verdict 가 input.md (또는 review 대상 source) 안의 **mechanical behavior claim** — 특정 regex, parser, verifier, 또는 script 가 특정 input 에 대해 실제로 어떻게 동작하는지에 대한 claim — 에 의존할 때, reviewer 는 그 claim 을 prose 만으로 수용하지 않는다. read-only sandbox 안에서 가능한 한 그 claim 의 **minimal reproducible check** 을 수행한다 — literal string 에 대한 tiny regex match, small parser input, small verifier fixture, any available scripting environment 에서의 isolated string / character inspection, one-line shell exit-code check 등. 본 check 는 의도적으로 narrow 다 — 수 초의 점검이지 full test suite 실행이 아니다. check 가 sandbox 환경 제약으로 불가능한 경우 (가용 scripting environment 부재, mutation 없이 artifact 를 exercise 할 수 없음 등) reviewer 는 미검증 mechanical claim 을 `## Review limitations` 에 기록한다 — prose 를 증명으로 취급하지 않는다. check 가 수행된 경우 그 결과는 `## Notes` 또는 `## Assumptions relied on` 에 surface 한다.

## 3a. Markdown validation evidence convention (R1)

input.md 가 validation execution 결과 (예: Pester pass count, `verify-ps1` PASS, `git diff --check` clean 등) 를 본문 prose 로 기록할 때, 그 prose 만으로는 reviewer 가 truthfulness 를 직접 확인할 수단이 좁다. R1 convention 은 그 claim 의 근거가 되는 evidence 를 별도 Markdown file 로 두고, input.md 가 그 file path 를 referencing 하여 reviewer 가 read-only sandbox 안에서 직접 본문을 inspect 할 수 있게 한다.

evidence file 의 자리와 본문 shape:

- evidence path 는 `<ProjectRoot>/log/evidence/<scope>/<case>/validation-evidence.md` 또는 `log/evidence/` 하위의 동등 Markdown path (`.md` 한 파일) 다.
- evidence file 의 본문 shape 의 source-of-truth 는 `docs/contracts/evidence/EVIDENCE_CONTRACT.md` 다. 본 contract 는 path referencing 의 의미만 정의한다.
- R1 convention 의 `## Validation evidence` referencing 대상은 **single Markdown bundle 한 form 으로 한정** 한다 (path 형식: `validation-evidence.md` 또는 case directory 안의 동등 `.md`). EVIDENCE_CONTRACT.md 의 5-file recipe (`command.txt` / `exit-code.txt` / `stdout.txt` / `stderr.txt` / `notes.md`) 는 evidence 의 일반 form 으로 별도 보존되며, **R1 convention 의 path referencing target 은 아니다**. 5-file form 의 case directory 또는 그 안의 개별 file 이 reviewer inspection 에 필요하면 `## Required inspection paths` 에 일반 inspection path 로 명시한다 — 이는 R1 의 Markdown evidence convention 의 일부가 아니다.

input.md 의 referencing 자리:

- `## Validation evidence` informational section (§2 참조) 에 evidence path 를 적는다. reviewer 가 inspect 해야 하면 `## Required inspection paths` 에도 동일 path 를 추가로 명시한다.
- `## Target files` 는 source-managed file 만 담는 자리이므로 evidence path 를 적지 않는다.

Markdown evidence 의 의미적 boundary:

- evidence 는 **reviewer-readable runtime supporting material** 이다. reviewer 는 input.md 가 가리킨 evidence file 의 본문을 read 하여 prose-only claim 의 근거를 확인할 수 있다.
- evidence 는 **command re-execution 이 아니다.** Codex reviewer 는 `--sandbox read-only` 안에서 evidence file 의 본문은 read 할 수 있으나, 그 본문이 시점 t 에 그 command 가 실제로 그렇게 실행되었음을 deterministic 하게 보장하지는 않는다. evidence 는 operator 가 정직히 작성한 file 이며 그 정직성은 운영자 책임이다.
- evidence 는 **deterministic truth oracle 이 아니다.** evidence 의 존재만으로 verdict 가 자동 정당화되지 않는다.
- evidence 는 **freshness binding 이 아니다.** evidence file 의 mtime / 본문 timestamp 와 reviewed source 의 시점 일치를 본 contract 가 자동 검증하지 않는다. staleness 판단은 operator 와 사용자 책임이며, 본 toolset 의 script gate 는 이를 enforcement 하지 않는다.
- evidence 는 **source-of-truth 로 승격되지 않는다.** evidence 는 `log/` 하위 runtime artifact 이며 commit / push 대상이 아니다. canonical review record (input.md + result.md) 의 sidecar 도 아니다 (§1 의 pass-dir sidecar 금지 그대로 유지).

R1 first batch 의 scope 와 boundary:

- evidence file 의 작성 / referencing 은 operator 의 자발적 convention 이다. `scripts/review-input-verify.ps1` 가 본 informational section 의 존재 / 형식을 lint 하지 않는다 (R1 first batch 의 design choice).
- evidence path referencing 은 **conditional** 이다. validation execution claim 이 있는 round 에서 권장된다. claim 자체가 부적용인 round (예: pure design review) 에서는 `## Validation evidence` 본문을 짧은 명시 (예: "N/A — no validation execution claims in this round.") 로 둔다.
- evidence-section 의 required vs optional 강제, sub-shape lint, evidence freshness / hash / mtime binding, deterministic validation runner, automatic validation execution 은 본 R1 batch 의 scope 밖이며 별도 Review input governance 후속 작업에서 결정한다 (§10 참조).

## 4. Script responsibility (deterministic gate only)

review pass 를 다루는 script 는 의미 판단을 하지 않는다. script 의 최소 책임:

1. pass directory `<ProjectRoot>/log/review/<review-task-id>/pass-NN/` 가 `<ProjectRoot>/log/review/` 내부인지 containment 검증.
2. `input.md` 의 5 개 required H2 heading 존재 여부와 본문 비어있지 않음 검증 (`scripts/review-input-verify.ps1` 의 contract).
3. Codex CLI 를 `input.md` 에 대해 정확히 1 회 실행.
4. 같은 pass directory 의 `result.md` 존재 검증.
5. `result.md` 의 `## Verdict` heading 1 개 존재 + 다음 첫 비어있지 않은 줄이 `yes` / `no` / `yes with risk` 중 하나인지 검증.
6. `result.md` 의 4 개 required disclosure H2 heading (`## Blocking findings`, `## Non-blocking concerns`, `## Review limitations`, `## Assumptions relied on`) 가 각각 정확히 1 회 존재하는지 검증 (`scripts/review-verify.ps1 -RequireResult` 의 mechanical presence/count check; 본문 sub-shape 는 검증하지 않음).
7. 위 모든 gate PASS 시 exit 0, 하나라도 실패 시 non-zero exit.

script 가 하지 않는 일:

- finding 의 의미 / 정당성 / 심각도 판단.
- 수정 scope 또는 re-review 필요 여부 판단.
- result 본문의 finding / risk 항목 자동 parsing 또는 후속 단계 트리거.
- verdict 를 읽어 commit / push / publish / merge / release 자동 승인.
- review request 본문을 여러 staging file 로 분산하는 staging step.
- AI 가 자연어로 작성할 수 있는 본문을 JSON / hash / provenance 파일로 추가 분산.

### 4a. Script entry points (canonical)

본 contract 의 7 개 gate 는 두 entry point 로 닫힌다.

- `scripts/review-prepare.ps1 -ReviewTaskId <id> [-Pass <pass-NN>] -Stage <stage> -Purpose <line>`
  - canonical pass directory `<ProjectRoot>/log/review/<review-task-id>/pass-NN/` 를 발급한다.
  - 그 안에 `templates/review-input.md` 본문을 그대로 옮긴 `input.md` 를 seed 한다.
  - `-Pass` 가 생략되면 같은 task directory 안의 기존 `pass-NN` 을 스캔해 다음 번호를 할당한다 (`pass-01`, `pass-02`, ...).
  - pass directory 가 이미 존재하면 write-once 위반으로 거부한다.
- `scripts/review-run.ps1 -ReviewTaskId <id> -Pass <pass-NN>`
  - 같은 pass directory 의 `input.md` 를 `scripts/review-input-verify.ps1` 로 검증한 뒤 Codex CLI 를 정확히 1 회 실행해 같은 pass directory 의 `result.md` 를 작성한다.
  - reviewer model 은 `-Model` 명시 → `config/reviewer.json` 의 `model` → built-in default 순으로 해소된다. canonical record 안에는 model / hash / source HEAD 같은 sidecar 가 저장되지 않는다.
  - `result.md` 의 `## Verdict` shape 를 검증한 뒤 PASS / FAIL 을 반환한다.
- `scripts/review-verify.ps1 -ReviewTaskId <id> -Pass <pass-NN> [-RequireResult]`
  - default mode: `input.md` 존재 + shape 만 검증.
  - `-RequireResult`: `input.md` shape + `result.md` 존재 + `## Verdict` shape + 4 개 required disclosure H2 (`## Blocking findings`, `## Non-blocking concerns`, `## Review limitations`, `## Assumptions relied on`) 가 각각 정확히 1 회 존재하는지까지 검증한다.
  - canonical artifact 두 파일만으로 PASS 가 결정되며, 어떤 sidecar JSON / hash binding 파일도 요구하지 않는다.

운영자 / AI 는 `<review-task-id>` 를 사용자의 `/goal` 작업 또는 review gate 단위로 직접 결정한다. Claude Code chat / session id 를 자동으로 받아 쓰지 않는다.

## 5. AI responsibility (semantic judgment)

operator-role AI 는 다음을 담당한다.

1. 사용자의 자연어 의도와 승인 boundary 에서 review scope 를 잡고, 그 작업에 사용할 `<review-task-id>` 를 결정한다 (한 `/goal` 작업 또는 한 review gate 단위).
2. `templates/review-input.md` 기준으로 `log/review/<review-task-id>/pass-NN/input.md` 본문을 직접 작성한다. target files / context / required inspection paths / review questions / constraints / final verdict instruction 을 모두 input.md 한 파일 안에 담는다. 첫 attempt 는 `pass-01`, 이후 corrective loop attempt 는 `pass-02`, `pass-03` ... 으로 증가한다. validation execution claim (예: Pester pass count, `verify-ps1` PASS, `git diff --check` clean) 이 있는 round 에서는 그 근거 Markdown evidence (§3a) 의 path 를 `## Validation evidence` informational section 에 명시하여 reviewer 가 직접 read-only inspect 할 수 있도록 한다. claim 자체가 부적용인 round 에서는 같은 section 본문을 짧은 명시 ("N/A — no validation execution claims in this round." 같은 한 줄) 로 둔다. review 호출 전에 operator 가 인지한 known compromise / convention deviation / skipped alternative / baseline failure / validation limitation / operator assumption 은 `## Known concerns` informational section 에 사전 disclose 한다 — 본 disclose 의 누락은 §7 의 stale-by-omission 규칙에 의해 verdict 의 commit-fitness 를 ex-post 무효화할 수 있다.
3. `result.md` 의 `## Verdict` 다음 첫 줄을 읽어 verdict 값을 확정.
4. `## Blocking findings` / `## Non-blocking concerns` / `## Review limitations` / `## Assumptions relied on` (V2 부터 parser-required 인 4 disclosure section) 그리고 `## Findings` / `## Risks` / `## Notes` (선택 section) 본문을 함께 읽고 finding 의 의미와 정당성, 수정 필요 scope, re-review 필요 여부를 판단. blocking 여부는 `## Blocking findings` section 의 내용이 우선이며, reviewer 의 미검증 영역 / 신뢰 전제는 `## Review limitations` / `## Assumptions relied on` 에서 함께 읽는다. verdict 별 next-action mapping 은 §6a 가 codify 한다.
5. 필요한 수정이 사용자가 승인한 scope 안이면 수정 후 같은 `<review-task-id>` 아래에 새 `pass-NN` 를 만들어 re-review.
6. 사용자에게 review task path, 최종 pass, verdict, corrective loop count, changed files / validation / risk / next decision 을 보고.
7. operator 가 input.md (또는 본 AI 가 commit 하려는 template / snippet / contract) 안에 **mechanical behavior claim** — 특정 regex / parser / verifier / script 가 특정 input 에 대해 실제로 어떻게 동작하는지에 대한 claim — 을 적기 전에, reasoning 만으로 결정하지 않고 **minimal reproducible check** 으로 검증한다 (literal string 에 대한 tiny regex match, small parser input, small verifier fixture, any available scripting environment 에서의 isolated string / character inspection, one-line shell exit-code check 등). 본 check 는 의도적으로 narrow 다 — full test suite 실행이 아니라 prose 가 잘못된 mechanics 를 단언할 확률을 줄이는 좁은 점검이다. claim 이 현재 환경에서 검증 불가능하면 operator 는 `## Known concerns` 에 unverified 로 disclose 한다. 본 의무 (O1) 는 본 contract 의 §3b reviewer-side check (P4) 와 짝을 이룬다.

AI 는 verdict 의 의미 정의를 바꾸지 않는다. `yes` / `no` / `yes with risk` 는 본 contract 의 vocabulary 다.

## 5a. Operator stance and discipline

§5 가 operator-role AI (Claude Code) 의 책임 7 items 를 정의한다. 본 §5a 는 review process 안에서 AI 가 지켜야 할 operator stance 와 discipline 을 5 개 rule 로 codify 한다. 본 §5a 는 §5 의 7 items 를 변경하지 않으며 §6 verdict vocabulary 또는 §6a verdict → next-action mapping 의 의미를 재정의하지 않는다 — 또한 commit / push / publish / merge / release / deployment 의 자동 승인 semantics 를 도입하지 않는다. 본 5 rule 은 review 의 discovery / reporting / scope discipline 의 invariant 이며, mirror surfaces (`snippets/claude-skills/ai-harness-review/SKILL.md` step 2 / 4 / 5 / 7, Tier D managed-block snippets 의 최소 guard) 의 wording 이 본 §5a 와 충돌하면 본 §5a 가 우선한다.

### 5a.1 Target file accuracy verification

AI 가 `input.md` 의 `## Target files` 와 `## Required inspection paths` 를 작성할 때, 그 set 이 실제 변경 범위 (Mode A — `git status --porcelain=v1` + `git diff` 의 changed file set) 또는 호명된 subsystem 의 tracked file set (Mode B — `git ls-files` 의 subsystem 일치 file set) 과 정합한지 verify 한다. 변경된 파일이 누락되거나 무관한 파일이 잘못 포함되면 reviewer 가 잘못된 surface 만 보게 되어 verdict 가 잘못된 base 위에서 도출된다. 의도된 차이 (예: 특정 파일을 disclose 후 의도적으로 review 밖으로 두는 결정) 는 `## Known concerns` 에 사전 disclose 한다. sandbox-relative path 의 resolvability 도 함께 확인 — repo-relative forward-slash path 를 사용하며, reviewer sandbox 가 read 할 수 없는 path (예: `log/` 안의 transient runtime artifact 의 stale snapshot, 또는 repo-outside `polishing/` material 의 path 만 인용) 를 source-of-truth 위치로 두지 않는다 — 그런 material 이 review-relevant 하면 §5a.2 의 inline 규칙을 따른다.

### 5a.2 Off-repo / reference material handling

`polishing/`, sibling handoff doc, snapshot, manifest, user-provided text 같은 **off-repo / reference material** 은 source-of-truth 로 승격하지 않는다. 본 material 이 `input.md` 의 `## Context` 또는 `## Required inspection paths` 에 인용 / referencing 될 때는 명시적 reference / advisory / planning / user-provided context 로 그 role 을 disclose 한다. reviewer sandbox 가 repo-outside path 를 read 하지 못할 수 있으므로 외부 reference doc 의 본문이 review-relevant 하면 `## Context` 또는 dedicated `## Anchor draft body` subsection 안에 verbatim inline 한다 (path 만 인용한 채 본문을 sandbox 밖에 두지 않는다). source mutation 의 대상은 항상 repo source-managed 파일이며, 본 boundary 를 넘는 mutation 이 필요해 보이면 §5a.3 stop/report 가 발동한다.

### 5a.3 Stop/report vs self-correct boundary

approved scope 안의 finding 은 corrective patch + repo-local validation + 같은 `<review-task-id>/` 아래 새 `pass-NN/` 로 corrected-state re-review 가 가능하다 (§6a `no` next-action 과 일치). 다음 boundary 중 어느 것에 finding 이 닿으면 **stop / report 후 사용자 결정** 이 필요하다 — 본 batch 안에서 silently 흡수 금지:

- 사용자가 사전 승인한 batch / `/goal` scope 밖의 source mutation.
- `<ProjectRoot>/log/` 아래 runtime artifact 의 mutation (gitignored runtime tree; §8).
- `polishing/`, `repo_snapshot/`, 또는 repo-outside material 의 mutation.
- `%USERPROFILE%\.claude\`, `%USERPROFILE%\.codex\`, user-global `CLAUDE.md` / `AGENTS.md` (managed block 또는 whole-file) 의 mutation.
- `%USERPROFILE%\.claude\ai-harness-toolset\current\` (channel 3 install payload) 의 refresh.
- commit / push / publish / merge / release / deployment / upload / adoption / config mutation.

본 invariant 의 위반 (조용한 scope 확장) 은 review process 의 integrity 손상으로 간주된다.

### 5a.4 Retraction / correction reporting protocol

AI 가 이전 turn 의 판단 / input wording / validation execution claim / review framing / scope classification / target-file selection 이 잘못되었음을 발견하면 (review 진행 중이든 종료 후든) **숨기지 않고 사용자에게 보고한다**. 단순히 고친 결과만 surface 하지 말고 (a) 무엇을 retract / correct 했는지, (b) 왜 이전 판단이 틀렸는지, (c) 현재 상태가 어떤지를 명시한다. 본 retraction 의무는 AI 의 정직성 invariant 의 일부이며 §7 의 stale-by-omission 규칙 (review 호출 전 인지한 사항을 disclose 하지 않은 경우의 ex-post 무효) 의 짝이다 — §7 가 review-time 의 pre-disclosure 의무, §5a.4 가 in-progress / post-discovery 의 retraction 의무.

### 5a.5 Source / runtime / sibling report scope discipline

AI 는 다음 4 boundary 를 구분하여 mutation / referencing 한다:

- **Source repo file** — `templates/`, `docs/`, `snippets/`, `config/`, `scripts/`, `tests/`, `README.md` 같은 source-managed 파일. source mutation batch 의 정상 mutation target.
- **Runtime artifact** — `<ProjectRoot>/log/review/`, `log/evidence/`, `log/chatlog/`, `log/brief/`. gitignored runtime tree (§8). source-of-truth 로 승격하지 않으며 source mutation batch 의 mutation target 도 아니다. 본 batch 의 wording / contract / template 변경에 runtime artifact 의 내용을 source-of-truth 로 inline 하지 않는다 (필요 시 evidence path referencing 으로만 사용 — §3a).
- **Sibling report / planning reference** — `polishing/`, `repo_snapshot/`, snapshot, manifest 같은 repo-outside material. advisory / planning material. source-of-truth 가 아니며 source mutation batch 의 mutation target 도 아니다 (§5a.2 inline 규칙 따라 reviewer 가 sandbox 안에서 read 가능하도록 `## Context` 에 verbatim inline).
- **User / global filesystem** — `%USERPROFILE%\.claude\` / `%USERPROFILE%\.codex\` 등 user-global file, `%USERPROFILE%\.claude\ai-harness-toolset\current\` channel 3 install payload, user-global `CLAUDE.md` / `AGENTS.md` (managed block 포함). source mutation batch 안에서 mutation 하지 않으며 각각 별도 explicit user approval boundary 다.

source mutation batch 안에서 위 4 boundary 중 source repo file 외의 영역에 mutation 이 필요해 보이면 §5a.3 stop/report 가 발동한다.

## 6. Verdict vocabulary

다음 셋이 본 contract 의 vocabulary 다:

- `yes` — **blocking finding 이 없다.** 본 review scope 안에서 진행 가능. commit / push 의 자동 승인 아니다.
- `no` — **blocking finding 이 있다.** 본 review scope 안에서 corrective 가 필요하다.
- `yes with risk` — **blocking finding 은 없으나 명시 risk 가 disclosure 되어야 하고, 그 risk substance 에 대한 supervisor / 사용자 의 explicit acceptance 가 commit / push 전에 필요하다.** `yes` 의 자동 equivalent 가 아니다 — 단순히 yes-with-risk 가 yes 와 같은 다음 단계로 흡수되지 않는다.

verdict 는 review scope 안의 판단만을 담는다. commit / push / publish / merge / release / deployment / upload / adoption / config mutation 의 자동 승인이 아니다. 다음 단계는 사용자가 별도 명시 결정으로 처리한다.

### Blocking finding 의 정의

본 contract 에서 **blocking finding** 은 review scope 안에서 그 finding 을 해결하지 않고는 commit / push / publish / merge / release / adoption 의 다음 단계로 진행하면 안 되는 issue 다. 다음 항목들이 일반적으로 blocking 에 해당한다:

- review scope 안의 명시적 요구 (allowed mutation scope / boundaries / contract wording) 위반.
- review scope 안의 contract / template / snippet / script / test 의 정합성 깨짐 (예: assertion regression, contract self-conflict, wording 의 self-conflict).
- review scope 안의 truthfulness 검증 가능 영역에서 발견된 misstatement.

다음 항목들은 일반적으로 blocking 이 아닌 **non-blocking concern** 으로 분류되며 `yes` 또는 `yes with risk` verdict 에서 함께 disclosure 된다:

- review scope 밖의 wording 보강 권고.
- 후속 batch / 후속 governance 의 input 으로 surface 되어야 할 design 관찰.
- reviewer 의 sandbox / capability 한계로 인한 미검증 영역의 명시 (이는 `## Review limitations` 에 surface).
- operator prose 에 의존한 validation claim 의 truthfulness (이는 `## Assumptions relied on` 에 surface).

blocking 과 non-blocking 의 경계는 review scope 와 finding 의 substance 가 함께 결정한다 — 같은 종류의 finding 이 다른 review scope 에서는 blocking 일 수도 non-blocking 일 수도 있다. reviewer 가 본 contract 의 가이드를 base 로 finding 마다 판단하여 `## Blocking findings` 또는 `## Non-blocking concerns` 중 적절한 section 에 기록한다.

## 6a. Verdict → next-action mapping

§6 는 verdict 의 의미를 정의한다. 본 §6a 는 operator-role AI (Claude Code) 가 result.md 의 verdict 와 4 required disclosure section 본문을 읽은 뒤 수행해야 할 next-action mapping 을 codify 한다. 본 §6a 는 새 verdict token 을 도입하지 않으며 §6 의 narrowing (`yes` / `no` / `yes with risk`) 을 유지한다.

### yes

- 의미: §6 — review scope 안에서 blocking finding 없음.
- AI next action:
  1. `## Non-blocking concerns`, `## Review limitations`, `## Assumptions relied on` 본문 (그리고 선택 `## Findings` / `## Risks` / `## Notes`) 을 함께 읽고 사용자에게 surface — 사용자가 후속 결정의 input 으로 사용한다.
  2. commit / push / publish / merge / release / deployment / upload / adoption / config mutation 의 자동 진행 금지 — 사용자의 별도 명시 결정 필요.
  3. 후속 단계 (배포 / closeout / 다음 batch 진입) 권고가 적합하면 사용자에게 추천만 제시하고, 명시 승인 전에는 실행하지 않는다.

### no

- 의미: §6 — review scope 안에서 blocking finding 존재.
- AI next action:
  1. `## Blocking findings` 본문 각 항목을 읽고, 각 finding 이 사용자가 사전 승인한 batch / `/goal` scope 안인지 분류.
  2. scope 안 finding: corrective patch + repo-local validation + 같은 `<review-task-id>/` 아래 새 `pass-NN/` 로 corrected-state re-review. closure-for-laziness 금지.
  3. scope 밖 finding: 본 batch 안에서 silently 흡수 금지. stop / report 후 사용자의 별도 scoped 승인 요청.
  4. `no` verdict 만으로 batch closure 금지 — concrete re-review 결과 (`yes`, 또는 사용자 명시 risk-acceptance 가 적용된 `yes with risk`) 까지 진행해야 batch 가 닫힌다.

### yes with risk

- 의미: §6 — blocking finding 은 없으나 명시 risk 가 disclosure 됨. `yes` 의 자동 equivalent 아님.
- AI next action:
  1. `## Risks` (있을 시) + `## Review limitations` + `## Assumptions relied on` 의 risk-bearing 항목 (그리고 risk-관련 `## Non-blocking concerns`) 을 사용자에게 summarize 하여 보고.
  2. supervisor / 사용자 의 explicit risk acceptance 요청 — 수용 / 거부 / 수정 / 별도 batch 분리 중 하나의 결정 대기.
  3. risk 가 본 batch 의 approved scope 안에서 correct 가능하면 corrective patch + corrected-state re-review 가 옵션. corrective 가 scope 밖이면 그 사실 자체를 risk acceptance 의 input 으로 surface.
  4. 사용자 / supervisor 의 risk 수용 전에는 commit / push / publish / merge / release / deployment / upload / adoption 진행 금지.
  5. `yes with risk` 는 corrective loop path 가 아니라 risk acceptance path 다 — 사용자가 수용 / 거부 / 별도 batch 분리 중 하나를 결정한다.

### Output consumption guidance (V3)

본 §6a 의 매핑은 verdict line 만으로 결정되지 않는다. AI 는 result.md 를 **structured review artifact** 로 다루어 다음을 모두 읽는다.

- `## Verdict` — vocabulary 안의 lowercase exact match (필요 조건; 충분 조건 아님).
- `## Blocking findings` — `no` verdict 의 corrective scope 분류 input.
- `## Non-blocking concerns` — `yes` / `yes with risk` 의 후속 user-facing surface.
- `## Review limitations` — reviewer 가 미검증한 영역; commit fitness 의 후속 판단 input.
- `## Assumptions relied on` — verdict 가 의존한 전제; 전제가 깨지면 verdict 도 stale (§7).
- 선택 section (`## Findings`, `## Risks`, `## Notes`) 이 있으면 함께 읽는다. V2 4 required disclosure H2 와의 역할 차이: 4 required H2 는 mechanical-enforced disclosure 위치이고, 선택 section 은 reviewer 의 자유 prose narrative 다. **precedence rule**: blocking 여부의 source-of-truth 는 `## Blocking findings` section 의 내용이며, 선택 `## Findings` section 의 본문이 그와 충돌하는 경우에는 `## Blocking findings` 가 우선한다.

result.md 가 shape gate (`review-verify -RequireResult`) 를 통과하더라도, 본문 내용이 commit fitness 에 영향을 주는 limitation / assumption / risk 를 disclose 한다면 AI 는 그 substance 를 사용자에게 surface 해야 한다 — shape PASS 가 commit fitness 의 자동 보증이 아니다.

### Staleness re-review boundary

§7 의 stale-on-source-mutation 과 stale-by-omission 규칙은 본 §6a 의 mapping 위에서 다음과 같이 적용된다.

- 어떤 verdict 든, review pass 후 source / docs / template / snippet / test 가 수정되면 그 pass 는 stale 이며 corrected-state re-review 필요 (§7).
- operator 가 review 호출 전에 인지했지만 `## Known concerns` 에 disclose 하지 않은 compromise / limitation / assumption 이 사후에 발견되면 그 pass 는 stale-by-omission 이며 같은 `<review-task-id>/` 아래 새 `pass-NN/` 로 omitted concerns 가 disclose 된 re-review 필요 (§7 Stale by omission).

### Mirror surfaces

본 §6a 의 mapping mirror 와 cross-reference 관계:

- `templates/review-input.md` `## Final verdict` section — verdict vocabulary + 본 §6a 의 pointer.
- `templates/review-result.md` — verdict / 4 H2 / 선택 section 의 작성 방법 + reader 가 §6a 의 next-action mapping 에 따라 sections 를 읽는다는 pointer.
- `snippets/claude-skills/ai-harness-review/SKILL.md` step 6 (verify and read), step 7 (report) — practical operator behavior mirror.
- `docs/user_guide/OPERATOR_GUIDE_KR.md` §11 (verdict handling), §17 Verdict 처리 (post-MVP 운용 관점) — operator-facing mirror.
- `README.md` — public-facing 1-line pointer to §6a.
- Tier D managed-block snippets (`snippets/CLAUDE_SNIPPET.md` / `snippets/AGENTS_SNIPPET.md`) — minimal guard sentence + cross-reference (mapping table 자체는 포함하지 않음; long-term migration direction = skill / hooks / scripts / contracts).

mirror surface 의 wording 이 본 §6a 와 충돌하면 본 §6a 가 우선한다.

## 7. Re-review on staleness

같은 `pass-NN/` 안의 `input.md` 또는 `result.md` 가 작성된 뒤, 그 review 가 묶인 source / docs / template / snippet 중 어떤 것이라도 수정되면 그 pass 의 record 는 stale 이다. 사용자가 stale pass 의 verdict 를 후속 결정의 근거로 사용하지 않는다.

수정 후 동일 review task 안에서 동일 의미의 review 가 필요하면 같은 `<review-task-id>/` 아래에 새 `pass-NN/` 를 만든다 — 같은 task 의 corrective loop 의 다음 attempt 다. 이전 pass directory 안의 파일을 손으로 보정하지 않는다.

review 작업 자체가 바뀌면 (다른 `/goal` 또는 다른 review gate) 새 `<review-task-id>/` 를 사용한다 — 이전 task 의 pass 디렉터리를 재활용하지 않는다.

stale 판단의 책임은 operator-role AI 와 사용자에게 있다. 본 contract 는 stale 자동 detection 을 script 책임으로 두지 않는다.

### Stale by omission

operator 가 review 호출 전에 알았던 compromise / convention deviation / skipped alternative / baseline failure / validation limitation / operator assumption 을 `input.md` 의 `## Known concerns` informational section (또는 동등 본문 위치) 에 disclose 하지 않은 경우, review 가 끝난 후라도 그 verdict 는 commit / push / merge / release / adoption 결정의 근거로 사용할 수 없다. operator 가 사후에 발견 / 명시 announce 한 시점부터 그 pass 는 **stale-by-omission** 으로 간주되며, 같은 `<review-task-id>/` 아래에 새 `pass-NN/` 로 omitted concerns 가 disclose 된 `input.md` 의 re-review 가 필요하다.

본 stale-by-omission 의 mechanical 검증은 script 책임이 아니다 — script 는 operator 가 review 호출 전에 무엇을 알았는지 자동 추론할 수 없다. 본 규칙은 operator 의 정직성 invariant 와 supervisor / 사용자 의 판단에 의존한다. operator 가 review input 작성 시 known compromise / limitation 의 정직 disclosure 는 본 contract 의 §5 AI responsibility 의 implicit 의무이며, 그 의무 위반의 ex-post 발견은 verdict 의 commit-fitness 를 무효화한다.

## 8. Source repo vs target payload, runtime artifact 경계

본 contract 의 `<ProjectRoot>` 는 target project 의 repo root 다. source repo 의 dogfooding 모드에서는 source repo 자체가 `<ProjectRoot>` 다.

- source repo 의 `templates/` · `docs/` · `snippets/` · `config/` · `scripts/` · `tests/` 는 source-managed 다. review record 는 그 트리에 두지 않는다.
- review record 는 항상 `<ProjectRoot>/log/review/<review-task-id>/pass-NN/` 아래에만 만든다. `<ProjectRoot>/log/` 는 gitignored runtime tree 다.
- public release packaging / source snapshot 은 `log/` 를 포함하지 않는다.
- target project 의 `.gitignore` 는 `log/` 를 포함해야 한다. toolset 은 target `.gitignore` 를 자동으로 만들거나 편집하지 않는다.

## 9. Retention

retention 단위는 `<review-task-id>/` 디렉터리 전체, 또는 그 안의 개별 `pass-NN/` 디렉터리다. 더 이상 필요하지 않은 review task / pass 디렉터리는 사용자가 손으로 삭제한다. toolset 은 auto-prune / rotate / expire / schedule 을 제공하지 않는다.

failed / incomplete pass (예: Codex 실패 또는 verdict parsing 실패로 `result.md` 가 contract 를 만족하지 못한 pass) 도 디렉터리 단위로 disk 에 그대로 남는다. 사용자가 같은 `<review-task-id>/` 아래에 새 `pass-NN/` 로 보완하고, 보존 가치를 판단해 이전 pass / 전체 task 를 유지하거나 삭제한다.

## 10. Non-goals

본 contract 가 다루지 않는 것:

- canonical artifact 외의 sidecar 파일 (sidecar JSON, hash binding 파일, 외부 staging folder 등) 에 대한 보장. 그런 파일은 본 contract 의 일부가 아니다.
- review record 에 대한 hash binding / freshness sidecar / machine-readable verdict 사본의 자동 작성.
- review history aggregation, DB, index, cross-run dashboard.
- multi-reviewer orchestration, fallback model 자동 사용, retry / auto-fix loop.
- review verdict 를 read 하여 commit / push / publish / merge / release / deployment 를 트리거하는 wrapper.
- target project 의 `CLAUDE.md` / `AGENTS.md` / `.gitignore` / global filesystem 자동 변경.
- daemon, watcher, scheduler, CI integration.
- evidence / chatlog / brief subsystem 과의 cross-tree 보장.
- `## Validation evidence` informational section 의 required 강제, sub-shape lint, conditional 강제 자동화. R1 first batch 는 convention-by-docs 만 도입하고 script enforcement 는 Review input governance 후속 작업으로 분리된다.
- `## Known concerns` informational section 의 sub-shape lint (recommended sub-categories — convention deviation / skipped alternatives / validation limitations / baseline failures / direct verification not performed / operator assumptions — 의 본문 deterministic check). 본 lint 는 deterministic-lint scope 로 도입하지 않는다. operator 의 정직성 invariant + §7 stale-by-omission rule + supervisor 판단이 currently effective handling path 이며, sub-category 본문의 regex / string lint 는 semantic judgment 없이 brittle / high false-positive 한 surface 로 판단된다. reopen 은 informational disclosure omission 또는 misformatting 이 unsound verdict 를 유발한 concrete evidence 에 한정한다.
- evidence file 의 freshness / hash / mtime binding, source-state staleness 의 자동 검증.
- deterministic validation runner, automatic validation execution, JSON schema for evidence. 본 contract 는 evidence path referencing convention (§3a, Markdown-only) 만을 담는다.

removed legacy artifact design 의 historical reason 은 `docs/archive/backlog/review.md` 및 `docs/archive/backlog/operations.md` 에 격리되어 있다. 그 항목은 operator path 가 아니며 normal workflow 의 일부도 아니다.
