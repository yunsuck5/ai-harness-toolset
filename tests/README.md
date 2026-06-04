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

- Test files (current canonical task/pass review topology — `docs/contracts/review/REVIEW_RESULT_CONTRACT.md`):
  - `tests/review-prepare.Tests.ps1` — `review-prepare` allocating `<ProjectRoot>/log/review/<review-task-id>/pass-NN/` and seeding `input.md` from `templates/review-input.md`.
  - `tests/review-run.Tests.ps1` — `review-run` Codex invocation surface driven by a Codex stub, plus `## Verdict` shape validation. The stub is generated under Pester's `$TestDrive` physical path at test time and never invokes the real Codex CLI.
  - `tests/review-input-verify.Tests.ps1` — five-section readiness gate: filled-PASS, missing-heading FAIL, placeholder-remains FAIL.
  - `tests/review-verify.Tests.ps1` — `review-verify` default and `-RequireResult` paths against the canonical `input.md` + `result.md` pair.
  - `tests/brief-init.Tests.ps1`, `tests/brief-check.Tests.ps1`, `tests/brief-status.Tests.ps1` — source-side Brief primitive surfaces.
  - `tests/path.Tests.ps1`, `tests/resolve-script.Tests.ps1`, `tests/verify-ps1.Tests.ps1` — supporting library / encoding policy checks.
- Pester test fixtures live under Pester's `$TestDrive` physical path, not under the repo's `log/`. Real review runtime artifacts live under `<ProjectRoot>/log/review/<review-task-id>/pass-NN/` when the scripts are invoked outside tests.
- Interruption behavior: Pester fixtures never write into the repo's `log/`, so Ctrl+C, parent process kill, or other mid-run interruptions cannot leave residue under `<repo>/log/`. On normal `Invoke-Pester` completion the `$TestDrive` directory is cleaned up by Pester itself. On interruption, the OS temp copy of `$TestDrive` may remain until the next normal Pester run or until OS-level temp cleanup; that is an OS temp housekeeping concern, not repo `log/` pollution. The toolset does not ship a cleanup script, watcher, daemon, hook, or installer for this case.

## stdout run-fact test authoring discipline

When writing a **new** stdout contract test for `review-run`'s success-path output, verify each line-oriented run-fact / status line with an **exact-line anchor** — `(?m)^key: value$` — not a loose substring match. A loose `Should -Match 'key: value'` matches the substring anywhere in the output, so it cannot pin that the fact is its own full line with exactly that value.

- **Applies to** the line-oriented `key: value` run-facts / status lines emitted by `scripts/review-run.ps1` — e.g. `reviewer:`, `reviewer-version:`, `model:`, `model-source:`, `requested-effort:`, `effort-source:`, `applied-effort:`, `reviewer-safe-posture:`, `tool-root:`, `project-root:`, `tool-root-source:`, and other status lines such as `verdict:`, `pass:`, `pass-dir:`, `result:`, `provenance-persisted:`.
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

The Batch D2 / RV-B-06 run-fact assertions already in `tests/review-run.Tests.ps1` (the `(?m)^...$` style) follow this discipline and serve as the reference examples. Design rationale: `docs/systems/review/REVIEW_RUNNER_STDOUT_ANCHOR_TEST_PLAN.md`.

## Manual acceptance criteria

Manual AC documents are read-only checklists; they describe what to verify by hand, not scripts to run.
