# Tests

Local-first test fixtures for ai-harness-toolset.

- No cloud dependency.
- No global config mutation.
- No commit / push from tests.
- A test runner is not bundled in the first seed.

## Fixtures

- `fixtures/meta-with-bom.json` — must start with `EF BB BF`.
- `fixtures/meta-without-bom.json` — must not start with `EF BB BF`.

## Pester regression tests

- Pester tests are optional local regression tests.
- Pester v5+ is required when running them.
- The repo does not auto-install Pester.
- Recommended command (runs all `*.Tests.ps1` under `tests/`):

  ```powershell
  Import-Module Pester -MinimumVersion 5.0.0 -ErrorAction Stop
  Invoke-Pester -Path .\tests -Output Detailed
  ```

- Test files (current canonical review topology — three-level `<review-task-id>/<perspective>/pass-NN/` with `<perspective>` **required**; spec-of-record: `docs/review/review_spec.md`):
  - `tests/review-prepare.Tests.ps1` — `review-prepare` allocating the canonical three-level `<ProjectRoot>/log/review/<review-task-id>/<perspective>/pass-NN/` and creating an empty operator-authored `input.md` (no template seed mode): per-perspective pass allocation, write-once behavior, the `-Perspective`-required failure path, and invalid-perspective rejection.
  - `tests/review-run.Tests.ps1` — controlled Codex stubs로 candidate pre-verification, provenance append attempt, tail final-shape verification, PASS/provenance contract를 검증한다. strict UTF-8 raw-byte stdin, reviewer-safe invocation, unavailable/append/tail-verifier failure semantics, effort/model/category resolution과 persisted run-facts를 포함한다. Stubs는 Pester `$TestDrive` 아래에만 생성되며 real Codex CLI를 호출하지 않는다.
  - `tests/review-input-verify.Tests.ps1` — five-section readiness gate: filled-PASS, missing-heading FAIL, placeholder-remains FAIL.
  - `tests/review-verify.Tests.ps1` — `review-verify` default and `-RequireResult` paths against the canonical `input.md` + `result.md` pair in the three-level layout, including the `-Perspective`-required failure path (omitting it fails fast — no two-level fallback) and invalid-perspective rejection.
  - `tests/review-adapter.Tests.ps1` — reviewer adapter surface (adapter kind / version run-fact resolution).
  - `tests/review-safety-negtest.Tests.ps1` — reviewer-safe write-blocking negative test. It **launches the real Codex CLI**, so it is excluded from the routine `review-system suite` guard (see "Validation scope terms" below) and is run deliberately, not as part of the quick subset.
  - `tests/brief-init.Tests.ps1`, `tests/brief-check.Tests.ps1`, `tests/brief-status.Tests.ps1` — source-side Brief primitive surfaces.
  - `tests/path.Tests.ps1`, `tests/resolve-script.Tests.ps1`, `tests/verify-ps1.Tests.ps1` — supporting library / encoding policy checks (including `Test-ValidPerspective` segment validation, perspective-aware `Get-ReviewPassDir`, and `Assert-InTaskRoot` task-root containment).
- Pester test fixtures live under Pester's `$TestDrive` physical path, not under the repo's `log/`. Real review runtime artifacts live under the canonical three-level `<ProjectRoot>/log/review/<review-task-id>/<perspective>/pass-NN/` when the scripts are invoked outside tests.
- Interruption behavior: Pester fixtures never write into the repo's `log/`, so Ctrl+C, parent process kill, or other mid-run interruptions cannot leave residue under `<repo>/log/`. On normal `Invoke-Pester` completion the `$TestDrive` directory is cleaned up by Pester itself. On interruption, the OS temp copy of `$TestDrive` may remain until the next normal Pester run or until OS-level temp cleanup; that is an OS temp housekeeping concern, not repo `log/` pollution. The toolset does not ship a cleanup script, watcher, daemon, hook, or installer for this case.

## Validation scope terms

These terms name the validation scopes referenced by the local-validation-closeout discipline. Which scope a given change class must run before closeout is operator judgment carried on the active surface — the `ai-harness-review` skill's validation-scope-by-change-class guidance (`snippets/claude-skills/ai-harness-review/SKILL.md`) and the review input template's `## Validation evidence` section (`templates/review-input.md`) are the operative authority; `docs/review/review_spec.md` records that policy (spec-of-record), not its operative home. The definitions below are the testing-convention home for the suite terms those surfaces cite.

- **`full suite`** — every `tests/*.Tests.ps1`, i.e. whatever `Invoke-Pester -Path .\tests` discovers (the recommended command above). Exact file/case counts are runtime observations, not durable literals.
- **`review-system suite`** — the review-subsystem subset used as the recent regression guard: `tests/review-adapter.Tests.ps1`, `tests/review-input-verify.Tests.ps1`, `tests/review-prepare.Tests.ps1`, `tests/review-run.Tests.ps1`, `tests/review-verify.Tests.ps1`. Case counts are runtime observations, not durable literals. `tests/review-safety-negtest.Tests.ps1` launches the real Codex CLI and is **not** part of this routine subset guard (run it deliberately).
- **`affected tests`** — the subset of `tests/*.Tests.ps1` whose subject is the changed surface (e.g., changing `scripts/review-run.ps1` → `tests/review-run.Tests.ps1` plus the adapter / verify tests it touches). "Affected" is an operator judgment; no deterministic change→test mapping tool is provided.
- **`smoke / verify`** — fast integrity checks short of the full suite: `scripts/verify-ps1.ps1` (`.ps1` BOM / CRLF / encoding policy), `git diff --check` (tracked/index-visible whitespace / EOL), staging이 승인되지 않은 신규 untracked 파일의 직접 whitespace/encoding 검사, install-path operational smoke (`Invoke-OperationalSmoke`), review packet shape gates (`scripts/review-input-verify.ps1` / `scripts/review-verify.ps1`).
- **`manual AC`** — the by-hand read-only checklists described under "Manual acceptance criteria" below; not scripts to run.

## stdout run-fact test authoring discipline

When writing a **new** stdout contract test for `review-run`'s success-path output, verify each line-oriented run-fact / status line with an **exact-line anchor** — `(?m)^key: value$` — not a loose substring match. A loose `Should -Match 'key: value'` matches the substring anywhere in the output, so it cannot pin that the fact is its own full line with exactly that value.

- **Applies to** the line-oriented `key: value` run-facts / status lines emitted by `scripts/review-run.ps1` — e.g. `reviewer:`, `reviewer-version:`, `model:`, `model-source:`, `requested-effort:`, `effort-source:`, `applied-effort:`, `effort-category:`, `effort-policy-match:`, `reviewer-safe-posture:`, `tool-root:`, `project-root:`, `tool-root-source:`, and other status lines such as `verdict:`, `pass:`, `pass-dir:`, `result:`, `provenance-persisted:`.
- **Not forced on** error messages, argv substrings (e.g. `model_reasoning_effort=xhigh`), or other non-run-fact diagnostic strings — an exact-line anchor is not always appropriate there.
- **Variant run-facts:** some run-facts have more than one form — e.g. `applied-effort` is emitted as `not-observed`, as `<value> (WARNING: differs from requested <r>)`, or as a plain `<value>`. Use an exact-line anchor to pin the intended form: a loose `applied-effort: xhigh` would also pass the `WARNING` variant, conflating a clean run-fact with a degraded one.
- **Example:**

  ```powershell
  $r.Output | Should -Match '(?m)^reviewer: codex$'
  $r.Output | Should -Match '(?m)^reviewer-version: 9\.9\.9-stub$'
  $r.Output | Should -Match '(?m)^applied-effort: xhigh$'
  ```

- **No mass rewrite.** This is a discipline for **new** tests. The existing loose effort assertions (`AC-RR13` / `AC-RR14` / `AC-RR16` in `tests/review-run.Tests.ps1`) are intentionally left unchanged; tightening them is an optional separate cleanup, not part of this convention.
- **Convention only.** This changes neither the parser/verifier, the runtime behavior, nor the run-fact emission format — it is a test-authoring convention.

The Batch D2 / RV-B-06 run-fact assertions already in `tests/review-run.Tests.ps1` (the `(?m)^...$` style) follow this discipline and serve as the reference examples. Design rationale: preserved in git history (the then `docs/systems/review/REVIEW_RUNNER_STDOUT_ANCHOR_TEST_PLAN.md`).

## Manual acceptance criteria

Manual AC documents are read-only checklists; they describe what to verify by hand, not scripts to run.
