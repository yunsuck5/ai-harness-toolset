# Rule: PowerShell and file-encoding discipline (repo-only)

Applies to developing the `ai-harness-toolset` repository. The rules below are the binding active-surface form (per the root *Final hard rule*); the predecessor execution-policy rationale is preserved in git history.

## `.ps1` encoding and line endings

- `.ps1` files must be **UTF-8 with BOM + CRLF**. Run `scripts/verify-ps1.ps1` after creating or modifying any `.ps1`.

## Native-executable output capture

- Native-exe output must keep **stdout / stderr / exit code separate** — no `2>&1` / `Out-String` / `Out-Null` merged capture for correctness checks. Under Windows PowerShell 5.1 with `$ErrorActionPreference = 'Stop'`, a merged capture aborts before `$LASTEXITCODE` can be read.
- Affirmative form: native output **captured for assertion or downstream use** MUST go through `Invoke-NativeProcess` (`scripts/lib/native-process.ps1`) — the containment shim that pins `$ErrorActionPreference = 'Continue'` inside its own try/finally, writes child stdout and stderr to separate temp files, captures `$LASTEXITCODE` immediately after the native call, and returns `[pscustomobject]@{ ExitCode; Stdout; Stderr }`. The raw `& <native> ... 2>&1` capture-for-use shape is forbidden in `tests/**/*.ps1` by the `scripts/verify-ps1.ps1` Step F lint.

## Other repo artifacts

- `.md` / `.json` / `.txt` = **UTF-8 without BOM + LF**. Controlled file IO uses `scripts/lib/encoding.ps1`.

These are repo-development rules for this repo only; they are **not** adopter-universal and are **not** part of the global distribution (an adopter project may not even use PowerShell). They are not duplicated into `snippets/rules/`.
