# Review Result

이 파일은 `log/review/<review-task-id>/<perspective>/pass-NN/result.md` 의 형식 기준이다. active reviewer adapter (현재 MVP adapter = codex) 가 `--output-last-message` 로 같은 pass directory 에 result.md 의 verdict/disclosure **body** 를 작성하고, `scripts/review-run.ps1` 가 그 뒤에 `## Reviewer run provenance` 블록을 append 한다 (result.md 는 dual-authored — 아래 note 참조). operator-role AI (Claude Code) 가 `result.md` 본문을 읽고 finding / risk / required change 의 의미를 판단한다.

`<review-task-id>` 는 하나의 Claude Code `/goal` 작업 또는 하나의 review gate 단위이며 Claude Code chat / session id 가 아니다. `<perspective>` 는 review viewpoint 를 나타내는 별도 path segment 로 canonical three-level layout 의 **필수** 요소다 (operator-named, 자동 추론 없음). `pass-NN` 는 같은 review task·perspective 의 corrective loop 안에서의 각 Codex review attempt 다. (strict C1 이전의 perspective 없는 two-level result.md 는 legacy manual-readable record 일 뿐 tool 이 발급/검증하지 않는다.)

결과는 본 한 파일로 닫힌다. 다른 sidecar 파일은 canonical contract 의 일부가 아니다.

> **Runner-appended provenance block (reviewer 가 작성하지 않음).** review 성공 시 `scripts/review-run.ps1` 가 result.md 끝에 `## Reviewer run provenance` 블록을 **자동 append** 한다 — runtime-observed run facts (reviewer adapter kind/version, model, effort, reviewer-safe posture, engine identity) 의 machine 기록이다. 이 블록은 **runner 가 emit** 하며 reviewer 또는 operator 가 손으로 작성하지 않는다. reviewer 는 본 template 의 `## Verdict` + disclosure section 본문만 작성하고 provenance 블록은 건드리지 않는다. 본 블록은 informational 이며 `scripts/review-verify.ps1 -RequireResult` 의 gate 대상이 아니다 (`## Verdict` + 4 disclosure H2 의 count 와 무관). result.md 는 dual-authored — reviewer 가 verdict/disclosure body 를, `scripts/review-run.ps1` 가 provenance 블록을 작성한다.

`## Verdict` heading 직후 첫 비어있지 않은 줄은 lowercase 정확히 다음 셋 중 하나여야 한다 — `yes`, `no`, `yes with risk`. 다른 토큰, qualifier, inline 형태 (`Verdict: yes`, `Final verdict: yes`), prose 안 verdict 는 모두 거부된다. 따라서 본 template 의 `## Verdict` 본문은 그 contract 를 따르는 형태로 비워 두며, reviewer 는 이 첫 비어있지 않은 줄을 실제 verdict 값으로 교체하기만 한다. 본 contract 안내는 `## Verdict` heading 밖 (위 본문 또는 `## Notes`) 에 둔다.

verdict 어휘의 의미 narrowing — `yes` = no blocking finding (commit / push 의 자동 승인 아님); `no` = blocking finding 존재 (review scope 안 corrective 필요); `yes with risk` = blocking finding 은 없으나 명시 risk disclosure 가 필요하고 supervisor / 사용자 의 explicit acceptance 가 commit / push 전에 필요. `yes with risk` 가 `yes` 의 자동 equivalent 가 아니다. blocking finding 의 의미는 본 template 의 `## Blocking findings` section 의 안내 참조.

reviewer 는 verdict 외에 다음 4 required disclosure section 을 본문에 정확히 1 회씩 채워 finding 의 분류 와 reviewer-side limitation / assumption 을 명시 surface 한다 — `## Blocking findings`, `## Non-blocking concerns`, `## Review limitations`, `## Assumptions relied on`. 4 section 은 **required** (parser-enforced) 다 — `scripts/review-verify.ps1 -RequireResult` 가 본 4 H2 의 존재 (각 1 회) 를 parser-required 로 검증한다. 본 section 에 surface 할 substance 가 없을 때는 본문을 `none` 한 줄로 둔다. 본 enforcement 는 mechanical presence/count check 이며, 각 section 본문의 sub-shape (예: `## Known concerns` 의 sub-categories) lint 는 본 enforcement 의 범위가 아니다.

operator-role AI (Claude Code) 가 본 file 을 읽을 때는 verdict line 만이 아니라 위 4 disclosure section 본문 (그리고 아래 선택 section) 을 함께 읽어 next-action 을 결정한다. 그 mapping 은 `ai-harness-review` skill 의 step 7 (Verdict → next-action mapping) 이 정의한다. **Precedence rule**: blocking 여부의 source-of-truth 는 `## Blocking findings` section 의 내용이며, 선택 `## Findings` 와 충돌 시 `## Blocking findings` 가 우선한다.

## Verdict

yes

## Findings

reviewer 가 발견한 사항을 한 항목씩 나열한다. 본문이 길어도 무방하다. 발견한 사항이 없으면 `No blocking findings.` 와 같이 명시한다.

## Blocking findings

(required, exactly once) commit / push / merge / release 의 다음 단계로 진행하기 전에 반드시 해결되어야 할 finding 을 항목별로 기록한다. verdict `no` 면 1 개 이상이 존재; verdict `yes` 또는 `yes with risk` 면 비어 있거나 `none`. blocking finding 의 일반 정의: review scope 안의 명시적 요구 (allowed mutation scope / boundaries / contract wording) 위반, contract / template / snippet / script / test 의 정합성 깨짐, truthfulness 검증 가능 영역의 misstatement — 본 finding 을 해결하지 않고는 commit / push / merge / release / adoption 의 다음 단계로 진행하면 안 된다.

## Non-blocking concerns

(required, exactly once) blocking 은 아니지만 supervisor / 사용자 가 알아야 할 우려 사항을 항목별로 기록한다. 예: review scope 밖의 wording 보강 권고, 후속 batch 의 input 으로 surface 되어야 할 design 관찰. 없으면 `none`.

## Review limitations

(required, exactly once) reviewer 가 직접 검증하지 못한 영역을 명시한다. 예: `--sandbox read-only` 안에서 mutating 명령 (Pester / verify-ps1 / migration script) 실행 불가, operator 가 작성한 evidence file 본문의 시점적 사실성을 reviewer 가 cross-execute 하지 못함, operator prose 안의 **mechanical behavior claim** (특정 regex / parser / verifier / script 가 특정 input 에 대해 어떻게 동작하는지에 대한 claim) 에 대해 **minimal reproducible check** (literal string 에 대한 tiny regex match 등 narrow 한 점검; full test suite 가 아님) 이 sandbox 환경 제약으로 불가능. 없으면 `none`.

## Assumptions relied on

(required, exactly once) reviewer 가 verdict 도출 시 신뢰한 전제를 명시한다. 예: operator prose 의 validation result claim 의 truthfulness, R1 `## Validation evidence` 본문의 정직 작성, 명시되지 않은 source 의 stale 여부, reviewer 가 수행한 mechanical behavior claim 의 minimal reproducible check 결과 (positive check 결과도 동일 surface 가능). 전제가 깨지면 verdict 도 stale. 없으면 `none`.

## Risks

(선택) verdict 가 `yes with risk` 또는 `yes` 인 경우에 후속 단계에서 인지해야 할 risk 를 나열한다. risk 가 없으면 본 section 을 생략해도 무방하다.

## Counter-argument

(선택, strongly-recommended; non-parser) verdict 에 대한 가장 강한 반대 사례 (strongest case AGAINST the reviewer's own verdict) 를 dedicated position 으로 articulate 한다. verdict 가 `yes` 또는 `yes with risk` 인 round 에서 reviewer 는 substantive 한 본문을 작성한다. deliberate pressure-test 후 material counter-argument 가 발견되지 않으면 본문은 짧은 literal — `none` 또는 `no material counter-argument identified` — 로 두며 ceremonial boilerplate ("the alternative interpretation is X, but I dismiss it because Y" 의 substance 없는 일반적 pattern) 는 회피한다. verdict 가 `no` 인 round 에서는 본 section 을 생략해도 무방하다 — `## Blocking findings` 의 corrective scope 자체가 case-against-yes 의 articulation 이다. 본 section 은 parser-required 가 아니며 `scripts/review-verify.ps1 -RequireResult` 의 4-H2 disclosure gate 와 무관하다. `## Notes` 와의 substance boundary: 본 section = verdict pressure-test 의 dedicated position; `## Notes` = freeform reviewer-narrative bucket. boilerplate-degeneration 는 위 안내(짧은 literal 사용, ceremonial boilerplate 회피)를 따른다.

## Notes

(선택) 추가 코멘트, 참고 evidence path, 후속 inspection 권고 등을 자유 형식으로 기록한다. 본 section 도 생략 가능하다.
