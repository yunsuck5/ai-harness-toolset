# Rule: PowerShell and file-encoding discipline (repo-only)

Applies to developing the `ai-harness-toolset` repository. The rules below are the binding active-surface form (per the root *Final hard rule*); the predecessor execution-policy rationale is preserved in git history.

## `.ps1` encoding and line endings

- `.ps1` files must be **UTF-8 with BOM + CRLF**. Run `scripts/verify-ps1.ps1` after creating or modifying any `.ps1`.

## Native-executable output capture

- Under Windows PowerShell 5.1 with `$ErrorActionPreference = 'Stop'`, raw merged capture can abort before `$LASTEXITCODE` can be read. This is the failure mode addressed by the separate stream/exit-code contract below.
- **Structured-capture conformance:** A repo surface that claims the structured native-capture contract MUST preserve stdout, stderr, and exit code as separate values and expose exactly the PowerShell property set `[pscustomobject]@{ ExitCode; Stdout; Stderr }` (property names are case-insensitive). `Invoke-NativeProcess` (`scripts/lib/native-process.ps1`) is the preferred default realization, but conformance is determined by those capabilities rather than helper membership or a closed list of internal realizations. A future or alternate realization may claim this contract only when it preserves the same three-field capability. This clause does not classify a simple stdout-only capture or an admitted Step F raw-merged site as structured capture; whether those weaker forms should be retained or migrated is separate maintenance work.
- **Binding deterministic Step F partial validator:** Step F is a limited physical-line lexical validator over `tests/**/*.ps1`. When the verifier runs, it hard-fails on a line matching the literal single-line `& <native> ... 2>&1` shape unless that physical line carries the validator's explicit, reason-bearing comment pragma or a recognized non-capture discard form. It is not wired as a lifecycle hard gate and is not an AST or capture-site proof: a Step F pass means only that the lexical matcher reported no violation and is not evidence that other native-capture forms satisfy the structured contract above.
- **Current realizations (descriptive, non-exhaustive):** the no-stdin path currently pins `$ErrorActionPreference = 'Continue'` inside its own try/finally, writes child stdout and stderr to separate temp files, and captures `$LASTEXITCODE` immediately after the native call. The explicitly bound byte-stdin path currently uses the .NET process API, writes raw bytes to stdin, drains stdout and stderr separately in memory, decodes both with strict UTF-8, and returns `Process.ExitCode`.

## Other repo artifacts

- `.md` / `.json` / `.txt` = **UTF-8 without BOM + LF**. Controlled file IO uses `scripts/lib/encoding.ps1`.

These are repo-development rules for this repo only; they are **not** adopter-universal and are **not** part of the global distribution (an adopter project may not even use PowerShell). They are not duplicated into `snippets/rules/`.
