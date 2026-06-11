# Review Artifact Contract

본 문서는 한 번의 review task 가 어떤 artifact 로 닫히는지의 canonical contract 다. canonical artifact 는 두 파일이며 다른 sidecar 파일은 contract 의 일부가 아니다. canonical layout 은 **three-level** 이다 — 작업 식별자 / perspective / corrective attempt 가 각각 별도 path segment 다:

```text
<ProjectRoot>/log/review/<review-task-id>/<perspective>/
  pass-01/
    input.md
    result.md
  pass-02/
    input.md
    result.md
```

`<perspective>` (review viewpoint — 예: `local-correctness` / `system-coherence`) 는 **필수** 다. `scripts/review-prepare.ps1` / `review-run.ps1` / `review-verify.ps1` 는 `-Perspective <viewpoint>` 를 요구하며, 미지정 / 빈 값이면 fail-fast 한다 — **two-level fallback 은 없다.** pass 당 canonical artifact 는 같은 `pass-NN/` 안의 `input.md` + `result.md` 두 파일이며 (§10 non-goal), perspective segment 는 그 2-file 규약을 바꾸지 않는다.

**Legacy two-level artifacts**: strict C1 이전에 만들어진 `log/review/<review-task-id>/pass-NN/` (perspective segment 없는) artifact 는 disk 에 남아 있을 수 있으나 **legacy manual-readable runtime record** 일 뿐 tool-supported canonical record 가 아니다. 현재 script 는 그것을 발급 / 검증하지 않으며 (필요하면 사람이 직접 `.md` 를 읽는다), migration / 삭제도 하지 않는다 (§9).

`input.md` 는 operator-role AI (Claude Code) 가 작성한다. `result.md` 는 **dual-authored** 다 — verdict/disclosure body 는 active reviewer adapter (현재 MVP adapter = codex) 가 작성하고, 그 뒤에 `scripts/review-run.ps1` 가 machine-emitted `## Reviewer run provenance` 블록을 append 한다 (§3). script 는 두 파일에 대한 deterministic gate 를 담당하고 의미 판단은 하지 않으며, 추가로 그 runner-appended provenance 블록을 emit 한다 — 이 블록은 canonical result.md 안의 machine run-fact 이지 sidecar 파일도 의미 판단도 아니다 (§3 / §4).

본 contract 는 review artifact 의 **specification of record** (의도된 protocol / shape 의 기록) 다 — operative authority 가 아니다. review 동작의 operative authority 는 **active surface** 에 있다: shape / verdict / disclosure 의 런타임 강제는 `scripts/review-verify.ps1` · `scripts/review-input-verify.ps1` (+ `scripts/review-run.ps1`), shape 정의는 `templates/review-input.md` · `templates/review-result.md`, operator 절차 / 보고는 `snippets/claude-skills/ai-harness-review/SKILL.md` 가 가진다. 따라서 **active mirror** (위 templates / skill / scripts) 와 본 contract 가 충돌하면 **active surface 가 우선하고, 본 contract 를 그 active 동작에 맞춰 reconcile 한다** (root *Final hard rule*). **doc mirror** (`README.md`) 는 본 contract 를 read-first record 로 따른다 (doc-vs-doc). 아래 per-section 의 mirror-precedence 도 이 model 을 따른다.

## 1. Review task and pass directory

review record 는 세 단계 디렉터리로 닫힌다.

- `<review-task-id>` — 하나의 Claude Code `/goal` 작업 또는 하나의 review gate 단위. **Claude Code chat / session id 가 아니다.** 한 Claude Code 세션 안에서 서로 다른 주제의 `/goal` 이 여러 개 진행되면 각각 별도의 `<review-task-id>` 디렉터리를 사용한다. 자리: `<ProjectRoot>/log/review/<review-task-id>/`.
- `<perspective>` (**required**) — review viewpoint (예: `local-correctness` / `system-coherence`). `<review-task-id>` 와 `pass-NN` 사이의 **별도 path segment** 로, review viewpoint 를 작업 식별자 및 corrective attempt 와 한 폴더 이름에 섞지 않고 분리한다. operator 가 명시하며 자동 추론하지 않는다. **미지정 / 빈 값은 fail-fast** 이며 two-level fallback 은 없다. **single path segment** 여야 하고 `..` / path separator (`/`, `\`) / `pass-NN` 형태를 담지 않으며 safe charset/length 를 따른다 (`Test-ValidReviewTaskId` 동형, `scripts/lib/path.ps1` `Test-ValidPerspective`). 자리: `<ProjectRoot>/log/review/<review-task-id>/<perspective>/`.
- `pass-NN` — corrective loop 의 각 Codex review attempt. 첫 review attempt 는 `pass-01`, 두 번째 attempt 는 `pass-02`, 이렇게 zero-padded 두 자리로 증가한다. 같은 `<perspective>` 안에서 매겨진다 (per-perspective corrective attempt — perspective 마다 자기 `pass-NN` 시퀀스를 갖는다). 자리: `<ProjectRoot>/log/review/<review-task-id>/<perspective>/pass-NN/`.
- **legacy two-level artifacts / migration 없음**: strict C1 이전 two-level `log/review/<review-task-id>/pass-NN/` (perspective segment 없는) artifact 는 legacy manual-readable runtime record 로 disk 에 남을 수 있으나 tool-supported canonical record 가 아니다 — 현재 script 는 three-level 만 발급/검증한다. 과거 artifact 의 migration / rewrite / 삭제는 하지 않는다 (§9).
- canonical artifact per pass: 같은 `pass-NN/` 디렉터리 안의 `input.md` + `result.md` 한 쌍. 한 pass 의 record 는 외부 staging folder, sidecar JSON, hash sidecar 어디로도 분산되지 않는다.
- `<ProjectRoot>/log/` 는 gitignored runtime tree 다. canonical artifact 도 commit 대상이 아니다.
- 각 `pass-NN/` 디렉터리는 **write-once** 다. AI 또는 운영자가 같은 pass directory 안의 파일을 손으로 보정하여 review 를 닫지 않는다. 보완은 같은 `<review-task-id>/<perspective>/` 아래에 새 `pass-NN/` 를 만들어 수행한다.
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
- `## Validation evidence` — operator 가 validation execution claim (예: Pester pass count, `verify-ps1` PASS, `git diff --check` clean 등) 의 근거 evidence Markdown file path 를 명시할 자리. 의미와 boundary 는 §3a (R1 Markdown evidence convention) 가 source-of-truth. reviewer reproduction 의 opt-in boundary (evidence inspect 가 default, broad validation / build / test command 재실행은 review input 의 명시 authorization 필요) 는 §3d 가 source-of-truth.
- `## Known concerns` — operator 가 review 호출 전에 인지한 compromise / convention deviation / skipped alternative / baseline failure / validation limitation / operator assumption 을 reviewer 에게 사전 disclose 할 자리. recommended sub-categories: convention deviation, skipped alternatives, validation limitations, baseline failures, direct verification not performed, operator assumptions. operator 가 본 section 에 disclose 하지 않은 known concern 이 사후에 발견되면 §7 의 stale-by-omission 규칙이 발동한다. 본 section 은 두 종류를 담는다: **(1) confirmed disclosures** (위 sub-category 처럼 operator 가 확정 인지한 사실 — 사실로 기재; §7 stale-by-omission 전면 적용) 와 **(2) open concerns / hypotheses to verify** (미확정 의심 — `verify whether…` / `check whether…` 같은 중립 가설 표현으로 기재해 reviewer 가 추정-결함을 confirm 하지 않고 독립 평가; `## Review questions` neutral-phrasing 과 평행). **guard**: 진짜 known compromise / limitation 은 반드시 (1) 로 기재하며 (2) 로 위장 / 완화하지 않는다 — hypothesis 표현은 미확정 의심에만 쓰고 §7 의 disclosure duty 회피 수단이 아니다. 본 two-kind 구분은 wording / guidance convention 이며 §10 의 `## Known concerns` sub-shape lint non-goal 을 변경하지 않는다 (parser / lint 미도입).
- `## Framing self-check` — operator 가 review 호출 전 자신의 input (특히 `## Context` / `## Known concerns`) 이 reviewer 를 특정 verdict 로 유도하지 않는지 스스로 점검한 *기록*: confirmed disclosure 와 open hypothesis 분리, conclusion-forward / closeout / advocacy framing 회피, neutral 로 다시 쓴 표현. `## Review questions` 의 *reviewer* framing self-audit question 과 구분되는 *operator* 자신의 사전 self-check 이며, framing 의 중립성은 기계적으로 판정되지 않는다 (operator self-check 이지 semantic lint 가 아니다; §10 non-goal 유지). point-of-use guidance home 은 `templates/review-input.md`.
- `## Reference sweep` — 이름 / 위치 / 식별자 / 구조를 바꾸는 변경 (rename / move / **삭제 / 제거** / identifier·range / structure / fixed-line·fixed-token cleanup) 이 있는 round 에서 §5a.6 four-class reference-sweep 의 *증거* (sweep trigger, 검색 pattern, 검색 path 범위, 점검/미점검 class, semantic-phrasing 점검 여부; 삭제 변경은 §5a.6 의 case-insensitive / variant / bare-section deletion granular technique) 를 기록할 자리. `swept: yes` 주장만 적지 않는다. 구조 변경이 없는 round 는 짧은 `N/A` 명시로 둔다. sweep 의 완전성도 기계적으로 판정되지 않는다 (operator evidence 기록이지 lint 가 아니다). 정책 home 은 §5a.6, point-of-use guidance home 은 `templates/review-input.md`.

active review-input placeholder 는 `{{AI_TO_FILL_*}}` namespace (regex `\{\{AI_TO_FILL_[A-Za-z0-9_]+\}\}`) 로 한정된다. operator 가 본 prefix 의 placeholder 를 채우지 않은 채 남겨두면 `scripts/review-input-verify.ps1` 가 `FAIL unreplaced active placeholder` 로 거부한다. 또한 forbidden placeholder phrase (`Replace this placeholder`, `(Provide context here.)`, `(Provide review questions here.)`) 가 본문에 남아 있으면 같은 script 가 거부한다. 본 prefix 외의 generic `{{TOKEN}}` 형태 (예: `{{REAL}}`, `{{example}}`) 는 documentation literal 로 취급되어 verifier 가 거부하지 않는다 — 본 단순화는 Markdown parser / inline-code-span exemption / fenced-code-block exemption / HTML-comment exemption 의 도입이 아니라 active placeholder 와 documentation literal 의 syntax namespace 분리다. 미래의 review-input 활성 placeholder 는 반드시 `AI_TO_FILL_` prefix 를 사용해야 한다 (본 규칙이 active-placeholder safety invariant 다).

작성 주체는 operator-role AI 다. 사용자는 자연어 의도만 표현하고 raw template 을 손으로 채우지 않는다. AI 는 conversation context · git status · diff · 사용자 의도 · 해당 작업의 scope 를 종합해 input.md 본문을 직접 작성한다.

`input.md` 의 shape 기준은 `templates/review-input.md` 다.

## 3. `result.md` — reviewer-adapter-authored body + runner-appended provenance (dual-authored)

`result.md` 의 verdict/disclosure **body** 는 active reviewer adapter (현재 MVP adapter = codex) 가 `--output-last-message log/review/<review-task-id>/<perspective>/pass-NN/result.md` (perspective required, §1) 로 작성한다. operator-role AI 또는 운영자가 손으로 작성하지 않는다. runner 는 그 body 를 보존한 채 끝에 provenance 블록을 append 한다 (아래 dual-authorship).

**result.md authorship 은 dual-authored 다** (RV-B-06 P3):

1. **reviewer-adapter-authored verdict/disclosure body** — active reviewer adapter 가 작성하는 `## Verdict` + 4 required disclosure H2 (+ 선택 section). reviewer 의 semantic judgment 이며 아래 required shape 의 적용 대상이다.
2. **runner-appended runtime provenance block (optional, machine-emitted)** — `scripts/review-run.ps1` 가 verdict shape 가 usable 함을 확인한 뒤 result.md 끝에 append 하는 `## Reviewer run provenance` 블록. 이 블록은 **machine run-fact 이지 reviewer 의 verdict/judgment 가 아니며**, reviewer / operator 가 손으로 작성하지 않는다. 값의 source 는 runtime / config / active reviewer adapter / reviewer self-report 이고 **`input.md` 의 caller declaration 이 아니다**. 블록의 heading 과 key:value 본문은 아래 parser-gated heading (`## Verdict` + 4 disclosure H2) 과 충돌하지 않으므로 `scripts/review-verify.ps1 -RequireResult` 의 count 를 바꾸지 않는다 — 본 블록은 **새 parser gate 를 도입하지 않으며 verify 는 본 블록을 gate 하지 않는다 (informational)**. provenance 블록은 canonical 2-file contract 안의 result.md 본문 일부이지 **별도 sidecar 파일이 아니다** (§1 / §4 / §10). 적용 adapter 가 바뀌어도 동일 schema 로 유효하며 concrete vendor/tool/version 을 durable default 로 박지 않는다 (미관측 version 은 `not-observed`). reviewer 산출 실패 시 provenance 는 append 되지 않는다 (없는 run 에 대해 provenance 를 발명하지 않는다); 유효한 verdict 후 append 실패는 verdict 를 무효화하지 않되 loud 하게 보고된다. operator surfacing (final report 로의 인용) 은 본 §3 의 범위가 아니다 (P4; §6b 참조).

required shape (위 1번 reviewer-adapter-authored body 에 적용):

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
- `## Counter-argument` — strongly-recommended (non-parser). verdict 에 대한 strongest case AGAINST 를 dedicated position 으로 articulate. convention 의 source-of-truth 는 §3c (Counter-argument convention) 다.
- `## Notes` — 자유 형식 참고.

위 4 개 required disclosure section (`## Blocking findings`, `## Non-blocking concerns`, `## Review limitations`, `## Assumptions relied on`) 은 `scripts/review-verify.ps1 -RequireResult` 의 deterministic gate 다 — 각 heading 이 정확히 1 회 존재해야 한다. 부재 (count == 0) 또는 중복 (count > 1) 이면 verify FAIL. 본 enforcement 는 mechanical presence/count check 이며, 각 section 본문의 sub-shape (예: `## Known concerns` 의 sub-categories) lint 는 본 enforcement 의 범위가 아니다 — `## Known concerns` 의 sub-shape lint 와 `## Validation evidence` 의 sub-shape lint 는 §10 non-goals 에 기록된 대로 deterministic-lint scope 로 도입하지 않는 결정이다 (reopen 은 concrete evidence 에 한정).

`result.md` 의 shape 기준은 `templates/review-result.md` 다.

### 3b. Mechanical behavior claim verification (P4)

reviewer 의 verdict 가 input.md (또는 review 대상 source) 안의 **mechanical behavior claim** — 특정 regex, parser, verifier, 또는 script 가 특정 input 에 대해 실제로 어떻게 동작하는지에 대한 claim — 에 의존할 때, reviewer 는 그 claim 을 prose 만으로 수용하지 않는다. read-only sandbox 안에서 가능한 한 그 claim 의 **minimal reproducible check** 을 수행한다 — literal string 에 대한 tiny regex match, small parser input, small verifier fixture, any available scripting environment 에서의 isolated string / character inspection, one-line shell exit-code check 등. 본 check 는 의도적으로 narrow 다 — 수 초의 점검이지 full test suite 실행이 아니다. check 가 sandbox 환경 제약으로 불가능한 경우 (가용 scripting environment 부재, mutation 없이 artifact 를 exercise 할 수 없음 등) reviewer 는 미검증 mechanical claim 을 `## Review limitations` 에 기록한다 — prose 를 증명으로 취급하지 않는다. check 가 수행된 경우 그 결과는 `## Notes` 또는 `## Assumptions relied on` 에 surface 한다. 본 minimal reproducible check 는 reviewer 가 직접 구성한 narrow inspection-grade probe (수 초; full test suite / build 가 아님) 이며, target project 의 broad validation / build / test command 재실행과는 구분된다 — 그 broad reproduction 은 §3d 의 opt-in 정책의 적용을 받는다 (§3d.6).

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

> reviewer 가 evidence inspection 을 넘어 target 의 broad validation / build / test command 를 재실행하는 것은 default 가 아니며, §3d 의 opt-in reproduction 정책의 적용을 받는다. 본 §3a 의 evidence-inspect boundary 자체는 불변이다.

R1 first batch 의 scope 와 boundary:

- evidence file 의 작성 / referencing 은 operator 의 자발적 convention 이다. `scripts/review-input-verify.ps1` 가 본 informational section 의 존재 / 형식을 lint 하지 않는다 (R1 first batch 의 design choice).
- evidence path referencing 은 **conditional** 이다. validation execution claim 이 있는 round 에서 권장된다. claim 자체가 부적용인 round (예: pure design review) 에서는 `## Validation evidence` 본문을 짧은 명시 (예: "N/A — no validation execution claims in this round.") 로 둔다.
- evidence-section 의 required vs optional 강제, sub-shape lint, evidence freshness / hash / mtime binding, deterministic validation runner, automatic validation execution 은 본 R1 batch 의 scope 밖이며 별도 Review input governance 후속 작업에서 결정한다 (§10 참조).

## 3c. Counter-argument convention (optional, strongly-recommended; non-parser)

`result.md` 본문은 §3 의 4 required disclosure H2 외에 verdict 에 대한 strongest case AGAINST 를 dedicated position 으로 articulate 하는 optional disclosure section `## Counter-argument` 를 둘 수 있다. 본 section 은 strongly-recommended 이며 **parser-required 가 아니다** — `scripts/review-verify.ps1 -RequireResult` 의 4-H2 disclosure gate 는 본 convention 의 도입으로 변경되지 않는다. omission 은 parser FAIL 이 아니라 soft governance drift 다.

본 §3c 는 **low-cost trial** 의 codification 이며 empirically proven governance upgrade 가 아니다. light P3 wording (Phase 1 Batch II 의 `scripts/review-run.ps1` H1 reviewer-mode preamble 의 strongest-case-against instruction) 의 substance-evidence 가 positive 한 소수 case 위에서, codified position 으로 한 단계 더 narrowing 한 단계다. 본 convention 의 measurable effect 는 후속 review pass 의 누적 후 측정되며, parser-required gate 또는 heavier mechanism (예: 별도 H2 의 parser enforcement, devil's-advocate pre-pass, multi-reviewer consensus) 의 escalation 은 별도 evidence threshold 충족 후의 별도 batch 결정이다.

### 3c.1 Section 명세

- Heading 명: `## Counter-argument` (case-sensitive Markdown H2; 4 V2 required disclosure H2 와 동일 case-equality rule 적용).
- 위치: `result.md` 안의 optional disclosure section. 권장 위치는 `## Notes` 와 함께 reviewer-narrative section 군 안 (예: `## Risks` 직후, `## Notes` 직전). 본 convention 은 위치를 deterministic 으로 강제하지 않는다.
- Substance contract: verdict 에 대한 가장 강한 반대 사례 (strongest case AGAINST the reviewer's own verdict) 의 articulation. `## Notes` 가 freeform narrative bucket 인 반면 본 section 의 substance 는 verdict pressure-test 으로 좁다.

### 3c.2 Verdict 별 본문 convention

- Verdict `yes` 또는 `yes with risk`: reviewer 는 substantive 한 `## Counter-argument` 본문을 articulate 한다. deliberate pressure-test 후 material counter-argument 가 발견되지 않으면 본문은 짧은 literal — `none` 또는 `no material counter-argument identified` — 로 둔다.
- Verdict `no`: `## Counter-argument` 는 생략 가능하다 (`## Blocking findings` 의 corrective scope 자체가 case-against-yes 의 articulation 이므로). 포함하는 경우, reviewer 가 적용하지 않은 strongest mitigation argument 를 identify 할 수 있다.

### 3c.3 `## Notes` 와의 관계 (substance boundary)

`## Notes` 는 freeform reviewer-narrative bucket 으로 유지된다 — framing-tilt self-audit, evidence path, follow-up inspection, reviewer comment 등 다양한 substance 가 섞인다. `## Counter-argument` 는 verdict pressure-test 의 dedicated position 으로 substance 가 좁다. 두 section 의 substance 가 overlap 할 수 있으나 dedicated H2 는 reviewer articulation 의 consistency (매 round 동일 위치 작성) 와 reader inspection 의 consistency (operator / 사용자 가 동일 위치 read) 를 양쪽으로 상승시킨다.

`## Notes` 안의 strongest-case-against material 이 `## Counter-argument` 와 중복될 때, `## Counter-argument` 가 primary surface 다. `## Notes` 의 강한-반대 substance 는 별도 framing-tilt observation 또는 evidence pointer 로 narrow 시키거나 `## Counter-argument` 로 이동한다.

### 3c.4 Boilerplate-degeneration mitigation

본 convention 의 가장 큰 false-positive risk 는 reviewer 가 `## Counter-argument` 를 substance 없는 ceremonial boilerplate ("the alternative interpretation is X, but I dismiss it because Y" 의 일반적 pattern 만 채워 넣음) 로 채우는 degeneration 이다. 본 risk 의 mitigation:

- substance 가 없는 round 의 본문은 짧은 literal (`none` 또는 `no material counter-argument identified`) 로 두는 것이 권장된다. ceremonial boilerplate 보다 짧은 literal 이 합리적이다 — articulation 의 강요가 substance-없는 round 에 대해 ceremony 화를 유발하면 본 convention 의 measurable effect 를 약화시킨다.
- reviewer 는 substance 를 identify 할 때만 articulate 한다. deliberate pressure-test 후 material counter-argument 가 없으면 그 사실 자체를 짧은 literal 로 surface 하는 것이 올바른 outcome 이다.
- operator (Claude Code) 는 `result.md` 를 읽을 때 `## Counter-argument` 본문이 substantive 한지 평가한다. substance 없는 boilerplate 가 누적되어 발견되면 본 convention 의 escalation evidence input 이 된다 (parser-required gate 또는 heavier mechanism 의 별도 batch 결정 시).

### 3c.5 본 convention 이 추가하지 않는 것 (non-goals)

본 §3c 의 도입은 다음을 동반하지 않는다:

- `scripts/review-verify.ps1 -RequireResult` 의 4-H2 disclosure gate 의 변경 (parser surface unchanged).
- `## Verdict` 또는 4 V2 required disclosure H2 (`## Blocking findings`, `## Non-blocking concerns`, `## Review limitations`, `## Assumptions relied on`) 의 의미 / shape 의 변경.
- 새 verdict token 의 도입.
- `## Counter-argument` 본문의 sub-shape lint (substance vs boilerplate 의 deterministic check). 본 lint 는 §10 non-goals 와 동일 posture — semantic judgment 없이 brittle / high false-positive 한 surface 로 판단된다.
- canonical 2-file contract (input.md + result.md) 의 expand 또는 sidecar 도입.
- `scripts/review-run.ps1` H1 reviewer-mode preamble 의 wording 확장 (본 §3c 의 도입 batch 인 Phase 2 Batch 1A (commit `76033f4`) 에서는 preamble 의 strongest-case-against instruction 을 Phase 1 Batch II 의 light P3 wording — `## Notes` target — 그대로 유지; `## Counter-argument` 로의 redirect 는 별도 scripts/tests batch 의 결정 영역이었으며, Stage 4-R1 (별도 batch) 에서 수행되어 H1 preamble runtime instruction 이 §3c 의 dedicated pressure-test surface 와 정합화 되었다 — `docs/systems/review/STATUS.md` Accepted residual risks 의 'H1 preamble / Counter-argument surface alignment (closed by Stage 4-R1)' 참조).
- 본 §3c 의 mirror 의 operator-facing documentation / public-facing README / Tier D managed-block snippets 로의 확장 (Batch 1B mirror surfaces — 본 §3c 의 도입 batch 의 scope 외부; 별도 batch 의 결정 영역).

### 3c.6 Mirror surfaces

본 §3c 의 mirror 와 cross-reference 관계:

- `templates/review-result.md` — optional `## Counter-argument` section 의 위치 + body convention 의 reviewer-facing template.
- `templates/review-input.md` `## Final verdict` section — reviewer 가 매 round 본 convention 을 적용하도록 operator 가 input.md 안에 instruction 을 전달.
- `snippets/claude-skills/ai-harness-review/SKILL.md` step 4 (input authoring) + step 6 (verify-and-read) — operator workflow mirror.

본 mirror set 외부의 surface (`README.md`, Tier D managed-block snippets `snippets/CLAUDE_SNIPPET.md` / `snippets/AGENTS_SNIPPET.md`) 로의 mirror 확장은 사용자가 명시 결정한 별도 batch 의 scope 영역이다 (본 §3c 의 도입 batch 와 분리). 그 batch 가 entry 되지 않거나 indefinite defer 되면 본 mirror set 만으로 운영되며 reviewer reception path 는 영향을 받지 않는다.

mirror surface 와 본 §3c 가 충돌하면 active mirror (template / skill / scripts) 는 active surface 가 operative authority 로 우선하고 (본 §3c 는 spec-of-record), doc mirror 는 본 §3c 를 record 로 따른다.

## 3d. Reviewer reproduction opt-in (broad validation / build / test execution)

§3a 는 validation execution *claim* 의 근거 evidence 가 reviewer 가 *읽는* runtime supporting material 이며 command re-execution 이 아님을 정한다. §3b 는 mechanical behavior claim 에 대해 reviewer 가 read-only sandbox 안에서 narrow minimal reproducible check 를 *시도하길 기대* 한다. 본 §3d 는 그 사이에 명시되지 않았던 경계 — reviewer 가 target project 의 *broad* validation / build / test command 를 언제 실행해도 되는가 — 를 codify 한다. 본 절은 §3a 의 evidence boundary 와 §3b 의 minimal-check 기대를 **약화하지 않으며**, 그 위에 reproduction / execution 측 boundary 를 더한다.

### 3d.1 역할 분리 (ownership)

- **Local operator owns execution.** validation / build / test 실행은 operator 의 local 환경 책임이며, 그 사실은 evidence 로 남는다 (§3a; `docs/contracts/evidence/EVIDENCE_CONTRACT.md`). operator 가 closeout 전에 *어떤* validation 을 change class 별로 수행해야 하는지는 §6c (local validation closeout scope) 가 정한다 — 본 §3d 의 reviewer-side 경계와 짝을 이루는 operator-side 정책이다.
- **Reviewer owns inspection.** reviewer 는 diff / contract / local validation evidence 를 read 하여 판단한다.
- **Evidence bridges the two.** local 실행 사실과 reviewer 판단을 잇는 다리는 evidence file 이며, reviewer 는 그것을 *읽는다* (재실행하지 않는다). evidence 는 source-of-truth 가 아니다 (§3a, §8).

### 3d.2 Opt-in, not opportunistic

reviewer 는 read-only sandbox 가 *실행 가능해 보인다는 이유만으로* validation / build / test command 를 재실행하지 않는다. reviewer-safe posture (`--sandbox read-only`) 는 *write* 를 막는 구조 guard 이지 read-only command *실행* 자체를 금지하지 않으므로, "sandbox 가 실행 가능하니 돌려보자" 는 opportunistic 해석은 명시적으로 배제된다. broad reproduction 은 review input 의 명시 authorization (§3d.3) 이 있을 때만 가능하다.

### 3d.3 Opt-in authorization 의 최소 boundary

reviewer 의 broad command reproduction 은 **review input 에서 명시적으로 authorize 된 경우에만** 가능하다. authorize 시 review input 은 **최소한** 다음을 명시한다:

- **exact command** — 재실행할 정확한 command line (추정 / 일반화 금지).
- **working directory** — 실행 기준 디렉터리.
- **expected read/write behavior** — read-only 인지, write / side-effect 가 있는지, 있다면 무엇을 쓰는지.
- **allowed temp/output path** — 산출 / 임시 파일이 허용되는 경로 범위 (있다면).
- **dependency assumptions** — 전제되는 toolchain / SDK / runtime / network 가용성.
- **timeout expectation** — 허용 실행 시간 한계 (긴 / 무한 실행 금지).
- **interpretation boundary** — 결과 (특히 partial / nonzero exit) 를 어떻게 해석할지의 경계 — 무엇이 PASS / FAIL 신호이고 무엇이 환경 noise 인지.
- **how to report sandbox limitation** — sandbox 제약으로 실행이 불가 / 부분 실패 시 그 사실을 `## Review limitations` 에 어떻게 기록할지.

authorization 이 없거나 위 항목이 불완전하면 reviewer 는 reproduction 을 시도하지 않고 default 행동 (§3d.4) 으로 돌아간다. 본 authorization 은 wording / convention 이며 어떤 parser / lint gate 도 추가하지 않는다 (§10).

### 3d.4 Default reviewer behavior

broad reproduction authorization 이 없을 때 reviewer 의 default 는:

- diff / contract / `## Validation evidence` 가 가리킨 local validation evidence 를 **inspect** 한다 (§3a).
- operator 의 validation / build / test command 를 임의로 **재실행하지 않는다.**
- 재실행하지 못했거나 하지 않은 사실을 `## Review limitations` 에 review limitation 으로 **보고한다** (§3d.5).

§3b 의 mechanical minimal reproducible check 는 이 default 의 **예외로 기대** 된다 (narrow inspection-grade probe — §3d.6).

### 3d.5 Sandbox non-reproduction is a review limitation, not target risk

reviewer 가 재실행하지 못했거나 하지 않은 사실은 **자동으로 target risk 가 아니다** — reviewer 환경의 한계이지 reviewed target 의 결함이 아니며, §6 의 non-blocking 분류대로 `## Review limitations` 에 surface 한다. target risk (blocking 또는 risk-bearing) 로 승격하려면 sandbox 한계와 **독립된 근거** 가 있어야 한다:

- **missing local evidence** — validation execution claim 이 있는데 이를 뒷받침할 local evidence 가 부재.
- **stale evidence** — evidence 가 reviewed source 의 현재 상태와 명백히 시점 불일치.
- **scope mismatch** — evidence 가 claim 의 scope 를 cover 하지 못함.
- **static contradiction** — diff / contract / template 의 정적 자기모순 (재실행 없이 read 만으로 드러나는 inconsistency).
- **explicit high-risk gap** — 명시적으로 고위험인 영역이 어떤 evidence 로도 cover 되지 않음.

이런 독립 근거가 없으면 non-reproduction 은 `## Review limitations` 의 non-blocking 항목으로 남는다. 본 절은 §6 의 기존 non-blocking 분류를 약화하지 않고 target-risk 승격의 독립 근거를 명명하여 sharpen 한다.

### 3d.6 Narrow mechanical probe (§3b) vs broad reproduction (§3d) 경계

§3b 의 minimal reproducible check 와 본 §3d 의 broad reproduction 은 다음으로 구분된다 — 이 경계를 흐리면 두 절이 self-conflict 한다:

- **§3b narrow mechanical probe (기대; default 예외)**: reviewer 가 *직접 구성한 tiny synthetic 입력* 에 대해 claimed mechanism (regex / parser / verifier / script 동작) 을 inspection-grade 로 점검 — literal 에 대한 regex match, small parser / verifier fixture, isolated string / character inspection, reviewer 가 작성한 one-line synthetic exit-code probe. 수 초의 점검이며 **full test suite / build 가 아니다.** §3b 가 자기 infeasibility 를 이미 `## Review limitations` 로 라우팅한다. 본 §3d 는 이 기대를 약화하지 않는다.
- **§3d broad reproduction (opt-in)**: target project 의 *실제* validation / build / test pipeline 실행 — full test suite, build, network restore, generated-output write, repo-external SDK 호출 등 (§3d.7). default 로 시도하지 않으며 §3d.3 authorization 이 있을 때만.
- **경계선**: "reviewer 가 합성한 narrow probe 로 claimed mechanic 을 점검" (§3b, 기대) vs "operator 의 실제 validation / build / test pipeline 을 돌림" (§3d, opt-in). §3b 의 "one-line shell exit-code check" 는 *reviewer 가 작성한 synthetic 한 줄 probe* 를 뜻하며 "operator 의 validation command 실행" 을 뜻하지 않는다.

### 3d.7 Target-project validation examples (기본 비-재실행)

다음 target-project validation 은 reviewer read-only sandbox 에서 *실행 가능해 보여도* 기본 reproduction 대상이 아니다 — 공통적으로 (a) sandbox 에 부재한 toolchain / SDK / network 를 요구하거나, (b) write / network / generated-output side-effect 라 read-only sandbox 에서 실패하거나 partial-run 으로 오도하거나, (c) operator 의 local 환경에 속한다:

- Visual Studio / MSBuild / C++ build
- CMake / Unity / Unreal / game SDK
- network restore (NuGet / npm / pip / git submodule 등)
- generated-output / write-heavy builds
- repo-external tools / SDKs

reviewer 는 대신 operator 의 local validation evidence 를 inspect 하고 (§3d.4), 재실행 불가를 `## Review limitations` 로 보고한다 (§3d.5). 본 예시는 universal build runner / sandbox capability probe / SDK detection / project-specific build integration 을 도입하자는 것이 아니다 (§10) — 정책의 이유를 일반화해 보여줄 뿐이다.

### 3d.8 Mirror surfaces

본 §3d 의 mirror 와 cross-reference 관계:

- `templates/review-input.md` `## Validation evidence` guidance — operator-facing default (evidence-inspect) + opt-in authorization boundary.
- `snippets/claude-skills/ai-harness-review/SKILL.md` — reviewer / operator workflow mirror (default no-repro / opt-in / non-repro → review limitation; §3b narrow check 예외). deployed self-contained surface 이므로 repo-doc `§N` pointer 없이 prose 로 mirror 한다.

mirror surface 와 본 §3d 가 충돌하면 active mirror (template / skill / scripts) 는 active surface 가 operative authority 로 우선하고 (본 §3d 는 spec-of-record), doc mirror 는 본 §3d 를 record 로 따른다. 본 §3d 는 §3a / §3b / §6 의 기존 wording 을 변경하지 않고 그 위에 reproduction boundary 를 더한다.

## 4. Script responsibility (deterministic gate only)

review pass 를 다루는 script 는 의미 판단을 하지 않는다. script 의 최소 책임:

1. pass directory `<ProjectRoot>/log/review/<review-task-id>/<perspective>/pass-NN/` 가 `<ProjectRoot>/log/review/` 내부인지 containment 검증. perspective 가 operator-supplied path segment 이므로, review-root containment 만으로는 같은 review-root 안 다른 task 로의 traversal 을 막지 못한다 — 추가로 생성/해석되는 pass dir 이 의도한 `<review-task-id>/` 하위인지 task-root containment 로 검증한다 (`scripts/lib/path.ps1` `Assert-InTaskRoot`).
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
- AI 가 자연어로 작성할 수 있는 본문을 JSON / hash / provenance **파일** 로 추가 분산. (이는 별도 sidecar **파일** 로의 분산 금지다. `scripts/review-run.ps1` 가 result.md *안* 에 append 하는 machine run-fact `## Reviewer run provenance` 블록 (§3 dual-authorship) 은 canonical result.md 파일 내부의 runtime 기록이지 sidecar 파일이 아니므로 본 금지에 해당하지 않으며, 의미 판단도 아니다.)

### 4a. Script entry points (canonical)

본 contract 의 7 개 gate 는 두 entry point 로 닫힌다.

- `scripts/review-prepare.ps1 -ReviewTaskId <id> -Perspective <viewpoint> [-Pass <pass-NN>] -Stage <stage> -Purpose <line>`
  - canonical three-level pass directory `<ProjectRoot>/log/review/<review-task-id>/<perspective>/pass-NN/` 를 발급한다. `-Perspective` 는 **필수** — 미지정 / 빈 값이면 fail-fast (two-level fallback 없음).
  - 그 안에 `templates/review-input.md` 본문을 그대로 옮긴 `input.md` 를 seed 한다.
  - `-Pass` 가 생략되면 같은 `<task>/<perspective>/` directory 안의 기존 `pass-NN` 을 스캔해 다음 번호를 할당한다 (`pass-01`, `pass-02`, ... — per-perspective).
  - pass directory 가 이미 존재하면 write-once 위반으로 거부한다.
- `scripts/review-run.ps1 -ReviewTaskId <id> -Perspective <viewpoint> -Pass <pass-NN>`
  - 해당 three-level pass directory 의 `input.md` 를 `scripts/review-input-verify.ps1` 로 검증한 뒤 Codex CLI 를 정확히 1 회 실행해 같은 pass directory 의 `result.md` 를 작성한다. `-Perspective` 는 **필수**.
  - reviewer model 은 `-Model` 명시 → matched `categoryPolicy` entry 의 `model` (U9; entry 당 optional — 없으면 다음 tier) → `config/reviewer.json` 의 `model` → **fail-fast** 순으로 해소된다 (built-in model default/fallback 없음: 특정 model version 은 external lifecycle 에 종속되므로 코드/문서에 하드코딩하지 않고, model 이 없거나 비면 Codex 호출 전에 실패한다; `fallbackModel` 은 자동 사용되지 않는다). canonical record 안에는 model / hash / source HEAD 같은 sidecar 가 저장되지 않는다.
  - `result.md` 의 `## Verdict` shape 를 검증한 뒤 PASS / FAIL 을 반환한다.
- `scripts/review-verify.ps1 -ReviewTaskId <id> -Perspective <viewpoint> -Pass <pass-NN> [-RequireResult]`
  - three-level pass dir 을 해석한다. `-Perspective` 는 **필수** — 미지정 / 빈 값이면 fail-fast (two-level fallback 없음). strict C1 이전 legacy two-level artifact 가 필요하면 tool 이 아니라 사람이 직접 `.md` 를 읽는다.
  - default mode: `input.md` 존재 + shape 만 검증.
  - `-RequireResult`: `input.md` shape + `result.md` 존재 + `## Verdict` shape + 4 개 required disclosure H2 (`## Blocking findings`, `## Non-blocking concerns`, `## Review limitations`, `## Assumptions relied on`) 가 각각 정확히 1 회 존재하는지까지 검증한다.
  - canonical artifact 두 파일만으로 PASS 가 결정되며, 어떤 sidecar JSON / hash binding 파일도 요구하지 않는다.

운영자 / AI 는 `<review-task-id>` 를 사용자의 `/goal` 작업 또는 review gate 단위로 직접 결정하고, `<perspective>` 를 **항상 명시** 한다 (필수). Claude Code chat / session id 를 자동으로 받아 쓰지 않으며 perspective 도 자동 추론하지 않는다.

## 5. AI responsibility (semantic judgment)

operator-role AI 는 다음을 담당한다.

1. 사용자의 자연어 의도와 승인 boundary 에서 review scope 를 잡고, 그 작업에 사용할 `<review-task-id>` 를 결정한다 (한 `/goal` 작업 또는 한 review gate 단위).
2. `templates/review-input.md` 기준으로 `log/review/<review-task-id>/<perspective>/pass-NN/input.md` (perspective required, §1) 본문을 직접 작성한다. target files / context / required inspection paths / review questions / constraints / final verdict instruction 을 모두 input.md 한 파일 안에 담는다. 첫 attempt 는 `pass-01`, 이후 corrective loop attempt 는 `pass-02`, `pass-03` ... 으로 증가한다. validation execution claim (예: Pester pass count, `verify-ps1` PASS, `git diff --check` clean) 이 있는 round 에서는 그 근거 Markdown evidence (§3a) 의 path 를 `## Validation evidence` informational section 에 명시하여 reviewer 가 직접 read-only inspect 할 수 있도록 한다. claim 자체가 부적용인 round 에서는 같은 section 본문을 짧은 명시 ("N/A — no validation execution claims in this round." 같은 한 줄) 로 둔다. review 호출 전에 operator 가 인지한 known compromise / convention deviation / skipped alternative / baseline failure / validation limitation / operator assumption 은 `## Known concerns` informational section 에 사전 disclose 한다 — 본 disclose 의 누락은 §7 의 stale-by-omission 규칙에 의해 verdict 의 commit-fitness 를 ex-post 무효화할 수 있다.
3. `result.md` 의 `## Verdict` 다음 첫 줄을 읽어 verdict 값을 확정.
4. `## Blocking findings` / `## Non-blocking concerns` / `## Review limitations` / `## Assumptions relied on` (V2 부터 parser-required 인 4 disclosure section) 그리고 `## Findings` / `## Risks` / `## Counter-argument` / `## Notes` (선택 section; `## Counter-argument` 의 substance / boilerplate-degeneration 평가는 §3c) 본문을 함께 읽고 finding 의 의미와 정당성, 수정 필요 scope, re-review 필요 여부를 판단. blocking 여부는 `## Blocking findings` section 의 내용이 우선이며, reviewer 의 미검증 영역 / 신뢰 전제는 `## Review limitations` / `## Assumptions relied on` 에서 함께 읽는다. verdict 별 next-action mapping 은 §6a 가 codify 한다.
5. 필요한 수정이 사용자가 승인한 scope 안이면 수정 후 같은 `<review-task-id>/<perspective>/` 아래에 새 `pass-NN` 를 만들어 re-review.
6. 사용자에게 review task path, 최종 pass, verdict, corrective loop count, changed files / validation / risk / next decision 을 보고.
7. operator 가 input.md (또는 본 AI 가 commit 하려는 template / snippet / contract) 안에 **mechanical behavior claim** — 특정 regex / parser / verifier / script 가 특정 input 에 대해 실제로 어떻게 동작하는지에 대한 claim — 을 적기 전에, reasoning 만으로 결정하지 않고 **minimal reproducible check** 으로 검증한다 (literal string 에 대한 tiny regex match, small parser input, small verifier fixture, any available scripting environment 에서의 isolated string / character inspection, one-line shell exit-code check 등). 본 check 는 의도적으로 narrow 다 — full test suite 실행이 아니라 prose 가 잘못된 mechanics 를 단언할 확률을 줄이는 좁은 점검이다. claim 이 현재 환경에서 검증 불가능하면 operator 는 `## Known concerns` 에 unverified 로 disclose 한다. 본 의무 (O1) 는 본 contract 의 §3b reviewer-side check (P4) 와 짝을 이룬다.

AI 는 verdict 의 의미 정의를 바꾸지 않는다. `yes` / `no` / `yes with risk` 는 본 contract 의 vocabulary 다.

## 5a. Operator stance and discipline

§5 가 operator-role AI (Claude Code) 의 책임 7 items 를 정의한다. 본 §5a 는 review process 안에서 AI 가 지켜야 할 operator stance 와 discipline 을 7 개 rule 로 codify 한다. 본 §5a 는 §5 의 7 items 를 변경하지 않으며 §6 verdict vocabulary 또는 §6a verdict → next-action mapping 의 의미를 재정의하지 않는다 — 또한 commit / push / publish / merge / release / deployment 의 자동 승인 semantics 를 도입하지 않는다. 본 rule 들은 review 의 discovery / reporting / scope discipline 의 invariant 이며, mirror surfaces (`snippets/claude-skills/ai-harness-review/SKILL.md` step 1 / 2 / 4 / 5 / 7, Tier D managed-block snippets 의 최소 guard) 와 본 §5a 가 충돌하면 — 이들은 active mirror 이므로 — active surface 가 operative authority 로 우선하고 본 §5a (spec-of-record) 를 그에 맞춰 reconcile 한다.

### 5a.1 Target file accuracy verification

AI 가 `input.md` 의 `## Target files` 와 `## Required inspection paths` 를 작성할 때, 그 set 이 실제 변경 범위 (Mode A — `git status --porcelain=v1` + `git diff` 의 changed file set) 또는 호명된 subsystem 의 tracked file set (Mode B — `git ls-files` 의 subsystem 일치 file set) 과 정합한지 verify 한다. 변경된 파일이 누락되거나 무관한 파일이 잘못 포함되면 reviewer 가 잘못된 surface 만 보게 되어 verdict 가 잘못된 base 위에서 도출된다. 의도된 차이 (예: 특정 파일을 disclose 후 의도적으로 review 밖으로 두는 결정) 는 `## Known concerns` 에 사전 disclose 한다. sandbox-relative path 의 resolvability 도 함께 확인 — repo-relative forward-slash path 를 사용하며, reviewer sandbox 가 read 할 수 없는 path (예: `log/` 안의 transient runtime artifact 의 stale snapshot, 또는 repo-outside `polishing/` material 의 path 만 인용) 를 source-of-truth 위치로 두지 않는다 — 그런 material 이 review-relevant 하면 §5a.2 의 inline 규칙을 따른다.

### 5a.2 Off-repo / reference material handling

`polishing/`, sibling handoff doc, snapshot, manifest, user-provided text 같은 **off-repo / reference material** 은 source-of-truth 로 승격하지 않는다. 본 material 이 `input.md` 의 `## Context` 또는 `## Required inspection paths` 에 인용 / referencing 될 때는 명시적 reference / advisory / planning / user-provided context 로 그 role 을 disclose 한다. reviewer sandbox 가 repo-outside path 를 read 하지 못할 수 있으므로 외부 reference doc 의 본문이 review-relevant 하면 `## Context` 또는 dedicated `## Anchor draft body` subsection 안에 verbatim inline 한다 (path 만 인용한 채 본문을 sandbox 밖에 두지 않는다). source mutation 의 대상은 항상 repo source-managed 파일이며, 본 boundary 를 넘는 mutation 이 필요해 보이면 §5a.3 stop/report 가 발동한다.

### 5a.3 Stop/report vs self-correct boundary

approved scope 안의 finding 은 corrective patch + repo-local validation + 같은 `<review-task-id>/<perspective>/` 아래 새 `pass-NN/` 로 corrected-state re-review 가 가능하다 (§6a `no` next-action 과 일치). 다음 boundary 중 어느 것에 finding 이 닿으면 **stop / report 후 사용자 결정** 이 필요하다 — 본 batch 안에서 silently 흡수 금지:

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
- **Runtime artifact** — `<ProjectRoot>/log/review/`, `log/evidence/`, `log/brief/`. gitignored runtime tree (§8). source-of-truth 로 승격하지 않으며 source mutation batch 의 mutation target 도 아니다. 본 batch 의 wording / contract / template 변경에 runtime artifact 의 내용을 source-of-truth 로 inline 하지 않는다 (필요 시 evidence path referencing 으로만 사용 — §3a).
- **Sibling report / planning reference** — `polishing/`, `repo_snapshot/`, snapshot, manifest 같은 repo-outside material. advisory / planning material. source-of-truth 가 아니며 source mutation batch 의 mutation target 도 아니다 (§5a.2 inline 규칙 따라 reviewer 가 sandbox 안에서 read 가능하도록 `## Context` 에 verbatim inline).
- **User / global filesystem** — `%USERPROFILE%\.claude\` / `%USERPROFILE%\.codex\` 등 user-global file, `%USERPROFILE%\.claude\ai-harness-toolset\current\` channel 3 install payload, user-global `CLAUDE.md` / `AGENTS.md` (managed block 포함). source mutation batch 안에서 mutation 하지 않으며 각각 별도 explicit user approval boundary 다.

source mutation batch 안에서 위 4 boundary 중 source repo file 외의 영역에 mutation 이 필요해 보이면 §5a.3 stop/report 가 발동한다.

### 5a.6 Reference-sweep completeness

이름 / 위치 / 식별자 집합 / 구조를 바꾸는 변경 (파일 rename · 이동 · **삭제 / 제거 (deletion / removal)**, 식별자 집합 / range 변경, 폴더 역할 재정의, 용어 교체 등) 은 review 호출 전에 그 대상에 대한 reference 를 다음 네 class 로 나눠 모두 sweep 한다 — 한 class 만 고치고 나머지를 놓치면 stale reference 가 남아 corrective loop 로 이어진다. **삭제 / 제거는 특히 — 삭제된 파일 / 식별자 / 개념 자체는 더 이상 review 에 올릴 수 없으므로 (§5a.1 의 target 이 비어 있음), 본 dangling-reference sweep 이 삭제 변경의 *주된 review 표면* 이며, 삭제 대상의 직접 인접 reference 만이 아니라 네 class 전반의 2차(second-order) reference 까지 포함한다.** (5a.1 의 target-file accuracy 가 "어떤 파일을 review 에 올릴지" 라면, 본 rule 은 "그 변경의 reference 가 어디에 흩어져 있는지" 의 완전성이다.)

- **filename / path reference** — 옮기거나 지운 파일의 경로를 가리키는 직접 인용 (`docs/...md`, 코드 / 문서 안 path 문자열).
- **bare token / ID** — enumerated 식별자나 range (예: `RV-01..RV-0N`, `IU-NN`), 식별자 약어, marker token.
- **folder-as-bucket wording** — "그 폴더 안", "이 디렉터리는 …" 처럼 위치를 bucket 으로 가리키는 산문.
- **semantic phrasing** — 같은 사실을 식별자 없이 의미로만 가리키는 표현 (예: "현재 다음 단계", "그 mirror 파일", 다른 문서의 독립 status 주장).

앞의 세 class (filename / bare-token / folder-bucket) 는 grep / 검색으로 기계적으로 확인하고, semantic phrasing class 는 grep 으로 잡히지 않으므로 의미 기준으로 함께 점검한다. 본 sweep 은 single-home-plus-pointers 원칙 (`rules/docs-working-model/docs-working-model.md`) 의 운영 측면이다 — duplication 이 staleness 의 엔진이므로, 가능한 경우 reference 를 inline enumeration 대신 single home 으로의 pointer 로 단일화하는 것이 우선이다.

**deletion granular technique** — 특히 **삭제 / 제거** 변경의 sweep 은 case-insensitive 로 수행하고, 철자 / 대소문자 변형(variant)과 식별자 없이 섹션만 가리키는 bare-section 참조 (`§N`, `narrative §N` 처럼 파일 / 식별자명 없이 의미로만 가리키는 형태) 까지 포함한다 — 좁거나 대소문자-고정된 첫 sweep 은 이런 변형 reference 를 놓쳐 corrective loop 로 이어진다. (이 granular technique 는 위 네 class 의 *실행 방식* refinement 이며 새 class 가 아니다.)

mirror: `snippets/claude-skills/ai-harness-review/SKILL.md` step 4 의 reference-sweep 단락 (rename / move / delete / identifier / structure 변경 시 4-class reference sweep) 이 본 규율의 operator-facing 표현이며, step 2 Mode A 의 changed-file 예시에 deleted 가 포함된다. operator 의 point-of-use 기록 표면은 review input 의 `## Reference sweep` slot (`templates/review-input.md`) 이고, 본 §5a.6 가 그 정책 home 이다. 좁은 wording / terminology anti-pattern grep sweep 과는 구분된다.

### 5a.7 Reviewer-engine independence for review-subsystem self-modification

review tooling 자체를 수정하는 batch — review runner (`scripts/review-run.ps1`), review skill (`snippets/claude-skills/ai-harness-review/SKILL.md`), 본 review contract, review verifier (`scripts/review-verify.ps1` / `scripts/review-input-verify.ps1`), reviewer config (`config/reviewer.json` / `config/reviewer.schema.json`), reviewer policy / status docs (`docs/policies/REVIEWER_CONFIG_POLICY.md`, `docs/systems/review/STATUS.md`) 등 — 의 Codex review 는 **변경 중인 repo-local in-dev runner 를 review engine 으로 쓰지 않는다.** 변경 중인 runner 가 자기 자신의 미커밋 self-modification 을 review 하는 self-review 순환을 피하기 위함이다.

- review **target** 은 repo working tree (변경 중인 파일) 일 수 있으나, review **engine** 의 ToolRoot 는 global stable ToolRoot (`%USERPROFILE%\.claude\ai-harness-toolset\current`) 또는 pre-change independent checkout 이어야 한다. engine 과 target 은 분리된다 — 안정 엔진이 변경 중인 working tree 를 read-only 로 review 한다.
- global stable ToolRoot 가 실패하면 **stop / report** 하고, repo-local in-dev runner 또는 direct-codex 로 **임의 fallback 하지 않는다** (§5a.3 의 stop/report 규율과 일치; closeout 의 validity 는 실행 방식이 아니라 complete artifact + valid binding + `scripts/review-verify.ps1 -RequireResult` 로 판단한다).
- 변경 중인 in-dev runner 는 feature smoke / run-fact 증명 (예: applied-effort run-fact 관측) 에는 사용할 수 있으나, closeout review engine 으로는 사용하지 않는다.

**일반화 경계 (중요):** 본 규율은 **review tooling self-modification / review subsystem mutation 에 한정** 한다. review tooling 을 건드리지 않는 일반 작업의 review 에는 적용되지 않으며, 일반 `<ToolRoot>` 해소 순서 (`snippets/claude-skills/ai-harness-review/SKILL.md` step 1; `docs/contracts/global-invocation/SHARED_GLOBAL_INVOCATION_CONTRACT.md` — channel 3 부재 시 dogfood fallback 허용) 를 변경하지 않는다. 본 항목은 그 위에 얹히는 self-modification 한정 overlay 다.

mirror: `snippets/claude-skills/ai-harness-review/SKILL.md` step 1 (resolve roots) 의 review-engine independence bullet 이 본 규율의 operator-facing 표현이다. 관련: §5a.3 (channel 3 install payload refresh 의 stop/report boundary), `docs/policies/REVIEWER_CONFIG_POLICY.md` "Reviewer-safe invocation" (reviewer 호출의 다른 integrity 속성).

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
- reviewer 의 sandbox / capability 한계로 인한 미검증 영역의 명시 (이는 `## Review limitations` 에 surface). 이는 자동으로 target risk 가 아니며, target-risk 승격에는 sandbox 한계와 독립된 근거가 필요하다 (§3d.5).
- operator prose 에 의존한 validation claim 의 truthfulness (이는 `## Assumptions relied on` 에 surface).

blocking 과 non-blocking 의 경계는 review scope 와 finding 의 substance 가 함께 결정한다 — 같은 종류의 finding 이 다른 review scope 에서는 blocking 일 수도 non-blocking 일 수도 있다. reviewer 가 본 contract 의 가이드를 base 로 finding 마다 판단하여 `## Blocking findings` 또는 `## Non-blocking concerns` 중 적절한 section 에 기록한다.

## 6a. Verdict → next-action mapping

§6 는 verdict 의 의미를 정의한다. 본 §6a 는 operator-role AI (Claude Code) 가 result.md 의 verdict 와 4 required disclosure section 본문을 읽은 뒤 수행해야 할 next-action mapping 을 codify 한다. 본 §6a 는 새 verdict token 을 도입하지 않으며 §6 의 narrowing (`yes` / `no` / `yes with risk`) 을 유지한다.

### yes

- 의미: §6 — review scope 안에서 blocking finding 없음.
- AI next action:
  1. `## Non-blocking concerns`, `## Review limitations`, `## Assumptions relied on` 본문 (그리고 선택 `## Findings` / `## Risks` / `## Counter-argument` / `## Notes` — 선택 section 본문 평가는 §3c / §6a Output consumption guidance) 을 함께 읽고 사용자에게 surface — 사용자가 후속 결정의 input 으로 사용한다.
  2. commit / push / publish / merge / release / deployment / upload / adoption / config mutation 의 자동 진행 금지 — 사용자의 별도 명시 결정 필요.
  3. 후속 단계 (배포 / closeout / 다음 batch 진입) 권고가 적합하면 사용자에게 추천만 제시하고, 명시 승인 전에는 실행하지 않는다.

### no

- 의미: §6 — review scope 안에서 blocking finding 존재.
- AI next action:
  1. `## Blocking findings` 본문 각 항목을 읽고, 각 finding 이 사용자가 사전 승인한 batch / `/goal` scope 안인지 분류.
  2. scope 안 finding: corrective patch + repo-local validation + 같은 `<review-task-id>/<perspective>/` 아래 새 `pass-NN/` 로 corrected-state re-review. closure-for-laziness 금지.
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
- 선택 section (`## Findings`, `## Risks`, `## Counter-argument`, `## Notes`) 이 있으면 함께 읽는다. V2 4 required disclosure H2 와의 역할 차이: 4 required H2 는 mechanical-enforced disclosure 위치이고, 선택 section 은 reviewer 의 자유 prose narrative 다. `## Counter-argument` 의 본문 substance 는 verdict pressure-test 의 결과로 읽으며, §3c 의 boilerplate-degeneration mitigation 에 따라 본문이 substantive 한지 평가한다 — recurring boilerplate / omission 의 누적은 후속 batch 의 escalation evidence input 이지만 single case 는 그 자체로 blocking finding 이 아니다. **precedence rule**: blocking 여부의 source-of-truth 는 `## Blocking findings` section 의 내용이며, 선택 `## Findings` section 의 본문이 그와 충돌하는 경우에는 `## Blocking findings` 가 우선한다.

result.md 가 shape gate (`review-verify -RequireResult`) 를 통과하더라도, 본문 내용이 commit fitness 에 영향을 주는 limitation / assumption / risk 를 disclose 한다면 AI 는 그 substance 를 사용자에게 surface 해야 한다 — shape PASS 가 commit fitness 의 자동 보증이 아니다.

### Staleness re-review boundary

§7 의 stale-on-source-mutation 과 stale-by-omission 규칙은 본 §6a 의 mapping 위에서 다음과 같이 적용된다.

- 어떤 verdict 든, review pass 후 source / docs / template / snippet / test 가 수정되면 그 pass 는 stale 이며 corrected-state re-review 필요 (§7).
- operator 가 review 호출 전에 인지했지만 `## Known concerns` 에 disclose 하지 않은 compromise / limitation / assumption 이 사후에 발견되면 그 pass 는 stale-by-omission 이며 같은 `<review-task-id>/<perspective>/` 아래 새 `pass-NN/` 로 omitted concerns 가 disclose 된 re-review 필요 (§7 Stale by omission).

### Mirror surfaces

본 §6a 의 mapping mirror 와 cross-reference 관계:

- `templates/review-input.md` `## Final verdict` section — verdict vocabulary + 본 §6a 의 pointer.
- `templates/review-result.md` — verdict / 4 H2 / 선택 section 의 작성 방법 + reader 가 §6a 의 next-action mapping 에 따라 sections 를 읽는다는 pointer.
- `snippets/claude-skills/ai-harness-review/SKILL.md` step 6 (verify and read), step 7 (report) — practical operator behavior mirror.
- `README.md` — public-facing 1-line pointer to §6a.
- Tier D managed-block snippets (`snippets/CLAUDE_SNIPPET.md` / `snippets/AGENTS_SNIPPET.md`) — minimal guard sentence + cross-reference (mapping table 자체는 포함하지 않음; long-term migration direction = skill / hooks / scripts / contracts).

mirror surface 와 본 §6a 가 충돌하면 active mirror (template / skill / scripts) 는 active surface 가 operative authority 로 우선하고 (본 §6a 는 spec-of-record), doc mirror 는 본 §6a 를 record 로 따른다.

## 6b. Operator final report schema

§6a 가 operator-role AI (Claude Code) 가 result.md 를 읽은 뒤 수행할 next-action mapping 을 codify 한다면, 본 §6b 는 operator 가 그 review task 를 닫으며 **사용자에게 내는 human-facing closeout report** 의 field schema 를 codify 한다. 본 schema 의 policy origin 은 `docs/systems/review/REVIEW_POLISHING_DECISION_RECORD.md` §"Final report schema decision" (10-field schema) 이며, 본 §6b 는 그 schema 의 **specification of record** 다 — decision record 는 정책 origin 으로 남고, operator 가 운영 시 그 schema 를 실제로 적용하는 **operative home 은 active operator surface (`snippets/claude-skills/ai-harness-review/SKILL.md` step 7)** 다 (본 §6b 와 active surface 가 충돌하면 본 contract intro 의 authority model 대로 active 가 우선). 본 §6b 는 decision record 의 채택된 schema 를 재논의하거나 변경하지 않는다 (record 정리이지 decision reopening 이 아니다).

본 schema 의 boundary (관심사 혼동 방지):

- 본 schema 는 **human operator 의 closeout report** 규약이다 — operator-role AI 가 review task 종료 시 사용자에게 제출하는 보고의 field set 이며 자연어 보고다.
- 본 schema 는 **on-disk `result.md` 의 parser contract 가 아니다.** result.md 의 shape (`## Verdict` + 4 required disclosure H2) 는 §3 가 정의하며 본 §6b 와 별개 layer 다. 본 §6b 의 field 는 result.md 의 heading 이 아니다.
- 본 schema 는 **`scripts/review-verify.ps1` 가 enforce 하는 parser gate 가 아니다.** 본 §6b 의 어떤 field 도 deterministic gate 로 강제되지 않는다 — 본 §6b 의 도입은 §4 의 script 책임이나 §3 의 parser surface (`review-verify.ps1 -RequireResult` 의 4-H2 disclosure gate, `review-input-verify.ps1` 의 5-H2 gate) 를 확대하지 않는다 (user-decision 1: 새 semantic / completeness gate 없음; §10 non-goals).
- 본 schema 는 H2 (final human report) home 이며 H1 (runner stdout run-fact) / H3 (docs-only wording) 와 다른 layer 다 (`docs/systems/review/REVIEW_POLISHING_BATCH_D_SPEC.md` §2 세 home 분류). 같은 datum 이 H1 run-fact 와 H2 report field 양쪽에 나타날 수 있으나, H1 은 runner 의 단일-pass 관측이고 H2 는 operator 의 집계 / 판단이다.

### 6b.1 Field schema (10 field)

operator 의 final report 는 다음 field 를 분리해 보고한다. 특히 **field 3 / 4 / 5 (invocation count / artifact pass count / corrective loop count) 는 서로 다른 축** 이며 한 숫자로 conflate 하지 않는다 (decision record invariant 9). `pass-02 yes` 식 단일 표기 (coverage · attempt · corrective loop 를 한 토큰으로 뭉개는 것) 는 금지된다.

| # | field | 내용 |
|---|---|---|
| 1 | perspective coverage | `dual-perspective coverage` / `coverage-limited review` (+ 생략·축소 관점·rationale) / `no-reviewable-change report` |
| 2 | invocation packaging | `single-invocation dual-perspective packet` / `two focused invocations` / 기타 disclosed packaging shape |
| 3 | invocation count | reviewer 실제 호출 횟수. **품질 보증 아님**; field 4 (artifact pass count) · field 5 (corrective loop count) 와 다른 축 |
| 4 | artifact pass count | `artifact pass-NN` attempt 수. **per-perspective 로 보고한다** — 각 perspective 가 자기 `pass-NN` 시퀀스를 가지므로 perspective 별 pass count + 각 perspective 의 final-pass path 를 분리해 적고 (또는 명시적 aggregate 와 함께), 서로 다른 perspective 의 pass 를 한 숫자로 conflate 하지 않는다. 해당 workflow 가 `artifact pass-NN` 을 만들지 않으면 `N/A — no artifact pass-NN` (발명 금지) |
| 5 | corrective loop count | `corrective review loop` (corrected-state re-review) 반복 횟수. field 3 (invocation count) · field 4 (artifact pass count) 와 다른 축 — 한 corrective loop 가 새 artifact pass 와 일치할 수도 아닐 수도 있고, 한 reviewer invocation 이 corrective loop 없이 한 artifact pass 를 낼 수도 있다 |
| 6 | re-review status | `not needed` / `needed` / `completed` / `stale due to mutation` / `not applicable` |
| 7 | verdict / risk handling | `yes` / `no` / `yes with risk` 소비 방식; `yes with risk` = risk acceptance 또는 re-review path 필요 (§6 / §6a). verdict 별 next-action 은 §6a mapping 적용 |
| 8 | validation evidence | 사용한 validation evidence (§3a) + 한계. 어떤 validation 을 수행 / 미수행했는지의 change-class 기대치와 full-suite 미실행 시 보고 규약 (change class / validation run / not run / reason / residual risk) 은 §6c (local validation closeout scope) 가 source-of-truth |
| 9 | final git status | 최종 worktree 상태 + changed files |
| 10 | commit/push recommendation | next-action recommendation 일 뿐 **approval 아님** — verdict 는 commit / push / publish / merge / release / deployment / upload / adoption 을 자동 승인하지 않는다 (§6) |

보조 field: invocation path · run id · corrections applied · remaining risks 는 모두 **optional** 이다. **reviewer guard status** (아래 §6b.2) 만 다른 gradation 을 가진다 — Batch D2 run-fact 가 emit 된 경우 surface 권장 (recommended), review-subsystem self-modification closeout 에서는 §6b.2 Surfacing 대로 expected, 그 외 trivial review 에서는 optional. 어느 경우에도 parser gate 가 아니다.

### 6b.2 Reviewer guard status (optional field — 관측 가능성 분리)

reviewer guard status 는 review 가 어떤 guard / engine 아래에서 수행됐는지를 **과장 없이** 보고하는 optional field 다. 각 항목은 현재 그 값이 어디서 관측되는지 (출처) 를 함께 명시한다 — operator 는 관측되지 않은 값을 관측된 run-fact 처럼 보고하지 않는다.

- **reviewer execution guard** — `read-only` (구조적 guard) 또는 `mutation-capable + disclosed` (구조적 guard 부재를 disclosure). decision record §"Reviewer read-only / no-silent-fix invariants".
- **effort** — `requested-effort` / `effort-source` / `applied-effort`. **현재 `scripts/review-run.ps1` 가 이 3종을 run-fact 로 emit 한다** (Batch B) — present 하면 그 run-fact 에서 보고한다 (report from run-fact when present). `effort-source` 는 실제 resolver branch (`explicit` / `category` / `config` / `default`) 다. `applied-effort` 는 Codex stderr 헤더에서 캡처되므로 외부 프로세스 실행일 때만 관측된다 (in-process stub 은 `not-observed`).
- **effort category (U9)** — `effort-category` / `effort-policy-match`. runner 는 operator 가 `-EffortCategory <key>` 로 선택한 config-backed category policy 의 적용 결과를 run-fact 로 emit 한다: `effort-category` 는 선택된 category (미선택 시 `none`), `effort-policy-match` 는 lookup 결과 (`none` 미선택 / `matched` config `categoryPolicy` 에 존재 / `missed` 선택했으나 부재 → scalar fallback). effort-source / model-source 는 axis 별 실제 winning tier 를 보고한다 (explicit `-Effort` / `-Model` 는 match 여도 axis 별로 우선). `matched` 일 때: explicit `-Effort` 가 없으면 effort-source 가 `category`, 있으면 `explicit`; model-source 는 explicit `-Model` 이 없고 matched entry 에 `model` 이 있을 때만 `category`, 아니면 `explicit`(-`Model` 시) 또는 `config`(category `model` 은 optional). category 분류는 operator judgment 이며 자동 추론이 아니다 (`docs/policies/REVIEWER_CONFIG_POLICY.md` "Category policy"); report from run-fact when present.
- **model / model-source** — runner 가 model 을 resolve 해 reviewer CLI 에 전달하고, **Batch D2 이후 `model:` + `model-source:` 를 run-fact 로 emit 한다** (model-source 는 추론이 아니라 실제 resolver branch — `explicit` / `category` (matched `categoryPolicy` entry 의 `model`, U9) / `config`; missing/empty model 은 fail-fast). report from run-fact when present. **concrete model version 을 본 doc / report 에 literal 로 박지 않는다** — `config/reviewer.json` 가 source-of-truth 이며 report 는 runtime resolve 값(runner stdout 의 `model:` 라인)을 인용한다.
- **reviewer-safe posture** — `--sandbox read-only` / `--ask-for-approval never` / `--ignore-user-config`. **tested vectors (create / modify-tracked / modify-existing) 에 한해 verified 이며 blanket guarantee 아님** (`docs/policies/REVIEWER_CONFIG_POLICY.md`; untested vector · 다른 platform · 다른 reviewer-tool version 은 한계). runner 는 **Batch D2 이후 이 posture 를 `reviewer-safe-posture:` run-fact 로 emit 한다** (posture flags 만; blanket guarantee 아님). report from run-fact when present 하되 tested-vectors-only caveat 는 그대로 유지한다 — run-fact 라인은 어떤 guarantee 도 주장하지 않는다.
- **review engine identity** — engine ToolRoot / ProjectRoot / tool-root-source. review-subsystem self-modification 의 closeout 에서는 §5a.7 대로 engine 이 global stable ToolRoot (또는 pre-change independent checkout) 여야 하며, operator 는 자신이 호출한 engine 위치를 보고한다. runner 도 **Batch D2 이후 `tool-root:` / `project-root:` / `tool-root-source:` 를 run-fact 로 emit 한다** (operator debugging 용 fact 이지 source-of-truth claim 아님).

> 관측 가능성 원칙: effort 3종 · effort category 2종 (`effort-category` / `effort-policy-match`, U9) · model / model-source · reviewer-safe posture · engine identity (tool-root / project-root / tool-root-source) 는 모두 runner 가 run-fact 로 emit 한다 (Batch D2 set + U9 category set; report from run-fact when present). engine identity 는 §5a.7 self-modification 에서 operator 의 invocation 지식으로도 보고된다. reviewer-safe posture run-fact 는 posture flags 만이며, U10 + reviewer-safety 의 verified scope (tested vectors) 를 넘어 U9 operational 또는 reviewer-safe invocation 을 주장하지 않는다 (decision record §"U9/U10·safety reporting").

#### Surfacing (Batch D3 — H1 run-fact → H2 final report)

Batch D2 이후 위 run-fact (effort 3종 · model / model-source · reviewer-safe posture · engine identity) 는 `scripts/review-run.ps1` 의 success output 에 정상적으로 emit 되므로, operator 는 final report 의 reviewer guard status field 에 **그 emit 된 H1 run-fact 를 읽어 surface** 한다. H1(runner 의 단일-pass 관측) 을 H2(operator 의 집계·판단 보고) 로 옮기는 것이며 둘을 혼동하지 않는다 — final report 는 runner stdout 의 사본이 아니라 operator 의 보고다.

- run-fact 가 emit 된 경우(post-D2 의 normal case) reviewer guard status surfacing 은 **권장(recommended)** 이다. trivial 한 비-self-modification review 에서는 생략 가능(여전히 optional).
- **review-subsystem self-modification 의 closeout** 에서는 engine identity (tool-root / project-root / tool-root-source) · reviewer-safe posture · applied-effort 를 surface 하는 것이 **expected** 다 — §5a.7 의 engine disclosure 의무와 짝을 이룬다.
- 본 surfacing 은 operator reporting discipline 이며 **parser gate 가 아니다** — `review-verify.ps1` / `review-input-verify.ps1` 는 이를 강제하지 않으며, 본 §6b boundary(§3 parser contract / §4 deterministic gate 와 분리) 를 그대로 유지한다.
- surfacing 시 caveat 보존: reviewer-safe 는 **tested-vectors-only / not-blanket** 로만 보고(§6b.2 reviewer-safe posture); model 은 runtime-resolved 값을 인용하고 **concrete model version 을 doc / report 에 literal 로 박지 않는다**; engine path 는 operator-debugging fact 이지 source-of-truth claim 이 아니다. verdict 는 commit / push approval 이 아니다(§6).

### 6b.3 Mirror surfaces

- `snippets/claude-skills/ai-harness-review/SKILL.md` step 7 (report) — 본 schema 의 operator-facing mirror. step 7 의 보고 field 가 본 §6b.1 / §6b.2 와 정합한다.
- `docs/systems/review/REVIEW_POLISHING_DECISION_RECORD.md` §"Final report schema decision" — policy origin (본 §6b 는 그 specification-of-record; operative home 은 active surface — `SKILL.md` step 7).

mirror surface 와 본 §6b 가 충돌하면 active mirror (template / skill / scripts) 는 active surface 가 operative authority 로 우선하고 (본 §6b 는 spec-of-record), doc mirror 는 본 §6b 를 record 로 따른다.

## 6c. Local validation closeout scope (validation scope by change class)

§6b 가 closeout report 의 *field schema* 를 정한다면, 본 §6c 는 그 report (특히 §6b.1 field 8 validation evidence) 가 담을 내용을 결정하는 **operator-side 정책** — local operator 가 작업을 closeout 하기 전에 *어떤 validation 을 수행해야 하는가* 를 change class 별로 codify 한다. 본 §6c 는 §3d (Reviewer reproduction opt-in) 의 **operator-side 짝** 이며 §3d 를 재오픈 / 변경하지 않는다: §3d 는 reviewer 가 *무엇을 재실행하지 않는가* (reviewer-side) 를, 본 §6c 는 operator 가 *무엇을 실행해야 하는가* (operator-side) 를 정한다. policy origin (design): `docs/systems/review/REVIEW_LOCAL_VALIDATION_CLOSEOUT_POLICY_PLAN.md` (본 §6c 는 그 specification-of-record; operative home 은 active surface — `SKILL.md` step 7 / `templates/review-input.md` `## Validation evidence`; planning doc 은 design origin).

### 6c.1 Ownership and core

- **Local operator owns validation execution.** validation / build / test 의 실행은 operator 의 local 환경 책임이며 closeout 전에 수행된다. 그 사실은 evidence 로 남는다 (§3a; `docs/contracts/evidence/EVIDENCE_CONTRACT.md`).
- **Reviewer inspects validation evidence and scope rationale.** reviewer 는 diff / contract / local validation evidence 와 *operator 가 밝힌 validation scope 근거* 를 read 하여 판단한다. **reviewer 는 full suite 를 직접 실행하는 주체가 아니다.**
- **Reviewer reproduction stays governed by §3d.** reviewer 의 broad validation / build / test 재실행은 §3d 의 opt-in 정책 소관이다. reviewer 가 read-only sandbox 가 실행 가능해 보인다는 이유만으로 full suite 를 opportunistic 하게 돌리지 않는 것은 §3d.2 가 이미 보장한다. 본 §6c 는 그 reviewer-side 경계를 바꾸지 않는다.
- **"Full suite green" is required by change class, not universally.** closeout validation scope 는 변경 class 에 비례한다 (§6c.3). 모든 작업에 full suite green 을 의무화하지 않는다.

### 6c.2 Terminology

validation scope 용어의 정의 home 은 testing convention home 인 `tests/README.md` 다 (suite topology terms). 본 §6c 는 그 정의를 인용하며 재정의하지 않는다 (single-home; `rules/docs-working-model/docs-working-model.md`):

- **`full suite`** — `tests/` 하위 모든 `*.Tests.ps1` (`Invoke-Pester -Path .\tests` 가 discover 하는 전체). 정의·현재 파일 수 snapshot 은 `tests/README.md`. 주의: 최근 작업의 `Pester 88/88` 은 full suite 가 아니라 `review-system suite` subset 이다 — 두 수를 conflate 하지 않는다.
- **`review-system suite`** — review subsystem 의 test 파일 subset (최근 guard 로 사용); 정의·구성 파일은 `tests/README.md`.
- **`affected tests`** — 변경된 surface 를 직접 대상으로 하는 `tests/*.Tests.ps1` subset. "affected" 판정은 operator 의 의미 판단이며 deterministic 매핑 도구를 만들지 않는다 (§10).
- **`smoke / verify`** — 빠른 무결성 점검류: `scripts/verify-ps1.ps1` (`.ps1` BOM/CRLF/encoding policy), `git diff --check` (whitespace/EOL — §6c.4 의 untracked 주의), install path 의 `Invoke-OperationalSmoke` (`INSTALL.md` §13.7), review packet shape gate (`scripts/review-input-verify.ps1` / `scripts/review-verify.ps1`).
- **`manual AC`** — 손으로 점검하는 read-only checklist (`tests/README.md` "Manual acceptance criteria"); 자동 실행 대상이 아니다.
- **`validation evidence`** — validation 실행 사실의 보존 형식. 권위는 `docs/contracts/evidence/EVIDENCE_CONTRACT.md` + 본 contract §3a (Markdown evidence referencing convention).

### 6c.3 Change class validation matrix

다음은 change class 별 closeout 의 *최소* 기대 validation 이다. operator 는 위험이 크다고 판단하면 상향할 수 있고, 하향 (특히 full-suite-expected class 에서 full suite 미실행) 은 §6c.5 보고 대상이다. full suite 는 어느 class 에도 universal 의무가 아니다.

| change class | 대표 예 | 기대 validation (최소) | full suite 기대 |
|---|---|---|---|
| planning/design doc only | `docs/systems/**` plan/spec, `docs/architecture/**` cross-cutting plan/audit (+ the directly-necessary `docs/README.md` / `docs/current/REPO_READING_GUIDE.md` placement·routing registration such a doc requires) | `git diff --check` (신규 파일은 §6c.4); 신규 `.md` LF/no-BOM 확인 | 아니오 |
| docs-only STATUS/BACKLOG/policy wording | `STATUS.md` / `BACKLOG.md` / `docs/policies/**` | `git diff --check`; 인용 citation / count 의 mechanical 확인 | 아니오 |
| contract/template/SKILL wording | `REVIEW_RESULT_CONTRACT.md` / `templates/` / `SKILL.md` (의미보존) | `git diff --check`; review-system suite (parser-gated heading/placeholder 또는 input-verify / verify / run shape 영향 시); sibling-reconciliation 시 anti-pattern grep sweep | 아니오 (parser-gated heading/placeholder 에 닿으면 review-system suite 기대) |
| script/runtime behavior | `scripts/*.ps1` 동작, `scripts/lib/**` | affected tests + full suite; `verify-ps1`; `git diff --check` | 예 |
| parser/verifier gate | `review-input-verify.ps1` / `review-verify.ps1` gate 로직 | affected tests + full suite; positive / negative / skip 경로 TC; `verify-ps1` | 예 |
| test code | `tests/*.Tests.ps1` 추가 / 변경 | 변경 / 추가 test + full suite (공유 fixture / support 회귀); `verify-ps1` | 예 |
| install/update/activation path | `scripts/install-*.ps1` / `update-global.ps1` / `activate-global.ps1` / `scripts/lib/install-pipeline-core.ps1` / `INSTALL.md` operative contract | affected tests + full suite; `Invoke-OperationalSmoke`; `verify-ps1` | 예 |
| EOL-only / formatting-only (의미 무변경) | whitespace / EOL / trailing-newline 정리 | `git diff --check`; 의미 무변경 확인 | 아니오 (EOL normalization 은 별도 트랙 · §10) |

**full suite 가 강하게 기대되는 class**: script/runtime behavior, parser/verifier gate, test code (특히 공유 fixture / support), install/update/activation path — 실행 동작 / 게이트 / 공유 인프라 / 광범위 파이프라인을 건드려 좁은 subset 만으로는 회귀를 놓칠 수 있다. **targeted validation 으로 충분한 class**: planning/design doc, docs-only wording, wording-only contract/template/SKILL, EOL/formatting-only — wording / 형식 차원이라 full suite 가 변경과 무관해 신호가 늘지 않는다 (full suite 미실행은 §6c.5 의 짧은 disclosure 로 충분).

### 6c.4 `git diff --check` 와 untracked 파일

`git diff --check` 는 **tracked / staged 변경만 cover** 한다. 신규 / untracked 파일은 그대로 `git diff --check` 하면 점검되지 않으므로 (no-op), `git add -N <path>` (intent-to-add) 후 `git diff --check`, 또는 staging 후 `git diff --cached --check` 로 점검 대상에 포함시킨다. 신규 파일을 만든 round 에서 이 단계를 빠뜨리고 "`git diff --check` clean" 을 closeout 근거로 적으면 §6c.5 가 경계하는 *scope mismatch* (§3d.5 의 scope-mismatch 와 동일 개념 — evidence 가 claim 의 scope 를 cover 하지 못함) 가 된다.

### 6c.5 Reporting rule — full suite 미실행 시

full suite 를 실행하지 않았다면 (또는 §6c.3 의 expected validation 을 하향했다면) operator 는 closeout report (§6b.1 field 8) 에서 다음을 분리해 보고한다:

- **change class** — §6c.3 중 어느 class 인가.
- **validation run** — 실제 수행한 validation (예: `git diff --check` clean, review-system suite pass, `verify-ps1` PASS).
- **validation not run** — 수행하지 않은 validation (예: full suite, operational smoke).
- **reason not run** — 미수행 사유.
- **residual risk** — 미수행으로 남는 잔여 위험 (없으면 `none`).

미수행 자체는 결함이 아니다 — 정직한 disclosure 가 요건이다. operator 가 review 호출 전에 알았던 validation limitation 을 disclose 하지 않으면 §7 stale-by-omission 의 대상이 되고, 사후 발견 시 §5a.4 retraction 규율이 적용된다. 본 reporting rule 은 operator discipline 이며 어떤 deterministic gate 도 추가하지 않는다 (§10; §6b 의 parser-gate 비도입 boundary 와 동일).

### 6c.6 Mirror surfaces

- `tests/README.md` — suite terminology (§6c.2) 의 정의 home + testing convention.
- `snippets/claude-skills/ai-harness-review/SKILL.md` step 7 (final report) / `## Validation evidence` guidance — operator-facing mirror (무엇을 validation evidence 에 적는지, full suite 미실행 시 사유 보고, reviewer 가 full suite 를 실행하는 정책이 아님). deployed self-contained surface 이므로 `§N` pointer 없이 prose 로 mirror.
- `templates/review-input.md` `## Validation evidence` guidance — 같은 operator-facing mirror.

mirror surface 와 본 §6c 가 충돌하면 active mirror (template / skill / scripts) 는 active surface 가 operative authority 로 우선하고 (본 §6c 는 spec-of-record), doc mirror 는 본 §6c 를 record 로 따른다. 본 §6c 는 §3a / §3b / §3d / §6b 의 기존 wording 을 변경하지 않고 그 위에 operator-side closeout validation scope 를 더한다.

## 7. Re-review on staleness

같은 `pass-NN/` 안의 `input.md` 또는 `result.md` 가 작성된 뒤, 그 review 가 묶인 source / docs / template / snippet 중 어떤 것이라도 수정되면 그 pass 의 record 는 stale 이다. 사용자가 stale pass 의 verdict 를 후속 결정의 근거로 사용하지 않는다.

수정 후 동일 review task 안에서 동일 의미의 review 가 필요하면 같은 `<review-task-id>/<perspective>/` 아래에 새 `pass-NN/` 를 만든다 — 같은 task·perspective 의 corrective loop 의 다음 attempt 다. perspective 별로 `pass-NN` 시퀀스가 독립이므로, 한 perspective 의 corrective attempt 는 그 perspective 안에서 증가한다. 이전 pass directory 안의 파일을 손으로 보정하지 않는다.

review 작업 자체가 바뀌면 (다른 `/goal` 또는 다른 review gate) 새 `<review-task-id>/` 를 사용한다 — 이전 task 의 pass 디렉터리를 재활용하지 않는다.

stale 판단의 책임은 operator-role AI 와 사용자에게 있다. 본 contract 는 stale 자동 detection 을 script 책임으로 두지 않는다.

### Stale by omission

operator 가 review 호출 전에 알았던 compromise / convention deviation / skipped alternative / baseline failure / validation limitation / operator assumption 을 `input.md` 의 `## Known concerns` informational section (또는 동등 본문 위치) 에 disclose 하지 않은 경우, review 가 끝난 후라도 그 verdict 는 commit / push / merge / release / adoption 결정의 근거로 사용할 수 없다. operator 가 사후에 발견 / 명시 announce 한 시점부터 그 pass 는 **stale-by-omission** 으로 간주되며, 같은 `<review-task-id>/<perspective>/` 아래에 새 `pass-NN/` 로 omitted concerns 가 disclose 된 `input.md` 의 re-review 가 필요하다.

본 stale-by-omission 의 mechanical 검증은 script 책임이 아니다 — script 는 operator 가 review 호출 전에 무엇을 알았는지 자동 추론할 수 없다. 본 규칙은 operator 의 정직성 invariant 와 supervisor / 사용자 의 판단에 의존한다. operator 가 review input 작성 시 known compromise / limitation 의 정직 disclosure 는 본 contract 의 §5 AI responsibility 의 implicit 의무이며, 그 의무 위반의 ex-post 발견은 verdict 의 commit-fitness 를 무효화한다.

## 8. Source repo vs target payload, runtime artifact 경계

본 contract 의 `<ProjectRoot>` 는 target project 의 repo root 다. source repo 의 dogfooding 모드에서는 source repo 자체가 `<ProjectRoot>` 다.

- source repo 의 `templates/` · `docs/` · `snippets/` · `config/` · `scripts/` · `tests/` 는 source-managed 다. review record 는 그 트리에 두지 않는다.
- review record 는 항상 `<ProjectRoot>/log/review/<review-task-id>/<perspective>/pass-NN/` 아래에만 만든다. `<ProjectRoot>/log/` 는 gitignored runtime tree 다.
- public release packaging / source snapshot 은 `log/` 를 포함하지 않는다.
- target project 의 `.gitignore` 는 `log/` 를 포함해야 한다. toolset 은 target `.gitignore` 를 자동으로 만들거나 편집하지 않는다.

## 9. Retention

retention 단위는 `<review-task-id>/` 디렉터리 전체, 또는 그 안의 개별 `pass-NN/` 디렉터리다. 더 이상 필요하지 않은 review task / pass 디렉터리는 사용자가 손으로 삭제한다. toolset 은 auto-prune / rotate / expire / schedule 을 제공하지 않는다.

failed / incomplete pass (예: Codex 실패 또는 verdict parsing 실패로 `result.md` 가 contract 를 만족하지 못한 pass) 도 디렉터리 단위로 disk 에 그대로 남는다. 사용자가 같은 `<review-task-id>/<perspective>/` 아래에 새 `pass-NN/` 로 보완하고, 보존 가치를 판단해 이전 pass / 전체 task 를 유지하거나 삭제한다.

## 10. Non-goals

본 contract 가 다루지 않는 것:

- canonical artifact 외의 sidecar 파일 (sidecar JSON, hash binding 파일, 외부 staging folder 등) 에 대한 보장. 그런 파일은 본 contract 의 일부가 아니다.
- review record 에 대한 hash binding / freshness sidecar / machine-readable verdict 사본의 자동 작성.
- review history aggregation, DB, index, cross-run dashboard.
- multi-reviewer orchestration, fallback model 자동 사용, retry / auto-fix loop.
- review verdict 를 read 하여 commit / push / publish / merge / release / deployment 를 트리거하는 wrapper.
- target project 의 `CLAUDE.md` / `AGENTS.md` / `.gitignore` / global filesystem 자동 변경.
- daemon, watcher, scheduler, CI integration.
- evidence / brief subsystem 과의 cross-tree 보장.
- `## Validation evidence` informational section 의 required 강제, sub-shape lint, conditional 강제 자동화. R1 first batch 는 convention-by-docs 만 도입하고 script enforcement 는 Review input governance 후속 작업으로 분리된다.
- `## Known concerns` informational section 의 sub-shape lint (recommended sub-categories — convention deviation / skipped alternatives / validation limitations / baseline failures / direct verification not performed / operator assumptions — 의 본문 deterministic check). 본 lint 는 deterministic-lint scope 로 도입하지 않는다. operator 의 정직성 invariant + §7 stale-by-omission rule + supervisor 판단이 currently effective handling path 이며, sub-category 본문의 regex / string lint 는 semantic judgment 없이 brittle / high false-positive 한 surface 로 판단된다. reopen 은 informational disclosure omission 또는 misformatting 이 unsound verdict 를 유발한 concrete evidence 에 한정한다.
- evidence file 의 freshness / hash / mtime binding, source-state staleness 의 자동 검증.
- deterministic validation runner, automatic validation execution, JSON schema for evidence. 본 contract 는 evidence path referencing convention (§3a, Markdown-only) 만을 담는다.
- reviewer 의 broad validation / build / test reproduction 을 위한 universal build runner / sandbox capability probe / SDK detection / project-specific build integration. §3d 의 opt-in reproduction 정책은 convention-by-docs 이며 어떤 parser / verifier / runtime / build automation 도 추가하지 않는다.
- operator 의 change-class 별 closeout validation scope (§6c) 에 대한 deterministic gate / validation runner / CI / change-class 자동 detection / affected-test 자동 매핑. §6c 의 정책은 operator-discipline convention 이며 모든 작업에 full suite 를 강제하지 않고 어떤 parser / verifier / runtime / build automation 도 추가하지 않는다.

removed legacy artifact design 의 historical reason 은 git history 에 보존되어 있다. 그 항목은 operator path 가 아니며 normal workflow 의 일부도 아니다.
