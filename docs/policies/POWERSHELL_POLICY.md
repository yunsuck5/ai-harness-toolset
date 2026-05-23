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
