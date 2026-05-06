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
- Recommended command:

  ```powershell
  Import-Module Pester -MinimumVersion 5.0.0 -ErrorAction Stop
  Invoke-Pester -Path .\tests\review-verify.Tests.ps1 -Output Detailed
  ```

- Generated runtime test artifacts live under `log/` and are not source artifacts.

## Manual acceptance criteria

Manual AC documents are read-only checklists; they describe what to verify by hand, not scripts to run.

- `tests/chatlog-contract-manual.md` — chatlog MVP contract invariants (`docs/CHATLOG_CONTRACT.md`, `templates/`, `snippets/` 의 핵심 항목).
