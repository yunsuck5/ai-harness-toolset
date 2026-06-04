# PowerShell Policy

## Environment

- Windows 11 Pro first.
- PowerShell 5.1 compatible.
- PS 7 compatible where cheap.

## Encoding and line endings

| File class | Encoding | EOL |
|---|---|---|
| `.ps1` source files | UTF-8 with BOM | CRLF |
| `.ps1` temporary execution files | UTF-8 with BOM | CRLF |
| `.cmd` files (future) | UTF-8 without BOM | LF |
| Generated `.md` / `.json` / `.txt` artifacts | UTF-8 without BOM | LF |

## File IO rules

Controlled file IO must use the helpers in `scripts/lib/encoding.ps1`.

The following are forbidden for controlled artifacts:

- `Set-Content -Encoding UTF8`
- `Add-Content -Encoding UTF8`
- `Out-File`
- `Get-Content -Raw`
- Encoding-unspecified `WriteAllText` / `StreamWriter`

After creating or modifying any `.ps1` file, run `scripts/verify-ps1.ps1`.

## Codepage caveat

Windows PowerShell 5.1 reads BOM-less `.ps1` files using the system code page. Korean UTF-8 bytes interpreted as CP949 cause parser failures. The "UTF-8 with BOM" rule for `.ps1` exists to prevent this category of failure. ASCII-only content is preferred for scripts.

## `.cmd` wrappers

The first seed creates no `.cmd` files. If `.cmd` wrappers are added later:

- They must use a common 3-line template.
- They must not use `pushd`, `popd`, `cd`, or `cd /d`.
- Their encoding must be UTF-8 without BOM with LF.
- A BOM is forbidden because it can break `@echo off` parsing.

## Collection return contract

Each helper that returns collections must document its receiving pattern:

- `collection-contract` — the caller assigns directly and uses array semantics. Use `return ,$collection`.
- `@()-wrapped caller` — the caller wraps the result with `@(...)`. Use plain `return $collection`. A leading comma would double-wrap the result.
- `pipeline-streaming` — the caller consumes via the pipeline. Preserve the normal PowerShell output model.

Do not infer the return contract from the function name alone. Inspect or define the caller usage.

## Native command invocation under `$ErrorActionPreference = 'Stop'`

Windows PowerShell 5.1 wraps each stderr line from a native executable into a `NativeCommandError` `ErrorRecord` when the stream is captured or merged through PowerShell (e.g. `& <exe> ... 2>&1`). Under file-level `$ErrorActionPreference = 'Stop'`, that record becomes a terminating error and aborts execution before `$LASTEXITCODE` can be read. This is a PowerShell 5.1 behavior; PowerShell 7's default does not promote native stderr the same way, but this repo's Tier 1 still mandates PS 5.1 compatibility (`docs/policies/CLI_ENVIRONMENT_ASSUMPTIONS.md`), so the PS 5.1 contract is what code must satisfy.

When invoking a native executable (e.g. `powershell.exe`, `git`, `codex`) from a Pester test or a production script that runs under file-level `$ErrorActionPreference = 'Stop'`, and the child can emit on stderr (success path progress, parameter binder errors, or expected-failure assertions), do one of:

- Save and restore `$ErrorActionPreference = 'Continue'` around the `&` call inside `try { ... } finally { ... }`. Capture `$LASTEXITCODE` inside the `try`. This is the baseline mitigation; the canonical prior art is `Invoke-InstallPipelineNativeGit` in `scripts/lib/install-pipeline-core.ps1` and the local pattern in `tests/install-pipeline.Tests.ps1`.
- When stream identity matters (separate stdout / stderr for assertion or inspection), combine the EAP=Continue save/restore with `1> $outFile 2> $errFile` and read the files back. The canonical prior art is `tests/review-adapter.Tests.ps1`.

`... 2>&1 | Out-String`, `... 2>&1 | Out-Null`, and downstream string joins such as `($combined | ForEach-Object { [string]$_ }) -join "`n"` or `((& <exe> 2>&1) -join "`n").Trim()` are **not** mitigations for the abort. They run downstream of the `& ... 2>&1` evaluation; under PS 5.1 + EAP=Stop the terminating error fires before any downstream pipeline element ever receives input. Treat them as result-normalization patterns (display, success-path stringification) rather than as error-handling patterns. The `scripts/verify-ps1.ps1` Step F lint *allows* these discard forms in `tests/**/*.ps1`, but that allowance is a lint-scope decision — it blocks only reintroduction of the capture-for-use shape, and is not an assertion that the discard form is a mitigation here. A fixture whose native command can emit normal stderr (for example `git add` under system `core.autocrlf=true`) still needs a fixture-repo guard (`core.autocrlf false` / `core.safecrlf false`) or `Invoke-NativeProcess` containment; the discard form alone is not sufficient.

`Out-String` itself is acceptable for human-readable display (always specify `-Width` to avoid the default 80-column wrap) and for broad-regex assertions over PowerShell-internal streams such as `6>&1`. It is discouraged for exact `Should -Be` assertions because the default formatter and width can drift across PS versions and consoles, and it is prohibited as a mitigation for native expected-stderr capture under EAP=Stop.
