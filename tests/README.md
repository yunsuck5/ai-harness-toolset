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

## Manual acceptance criteria

Manual AC documents are read-only checklists; they describe what to verify by hand, not scripts to run.
