# ============================================================================
# DO NOT ADD `Set-StrictMode -Version Latest` OR `$ErrorActionPreference = 'Stop'`
# AT FILE TOP. THE ABSENCE OF THESE DIRECTIVES IS INTENTIONAL AND LOAD-BEARING.
# ============================================================================
#
# This is the one exception to the scripts/lib/*.ps1 convention. Every other
# file under scripts/lib/ (encoding.ps1, git.ps1, hash.ps1, install-pipeline-
# core.ps1, json.ps1, managed-block.ps1, path.ps1, resolve-script.ps1) sets
# both directives at the top. This file does not, on purpose. If a future
# maintainer "normalizes" this file to match the convention, the regressions
# below WILL reappear.
#
# Why this file is the exception:
#   This is a containment shim for native process invocation, not a pure
#   utility library. It is dot-sourced from 11 Pester test files (the helper's
#   own native-process.Tests.ps1 plus 10 sibling test files that exercise the
#   migrated callers) and from 2 production scripts. Setting StrictMode v3 or
#   pinning EAP=Stop at the top of THIS file applies those directives in the
#   dot-sourcing scope (Pester BeforeAll) and Pester preserves that scope's
#   state into the It-block scope. The resulting ambient-semantics leak breaks
#   tests that are not even calling Invoke-NativeProcess.
#
# Concrete failure modes that re-adding the directives WILL resurrect:
#   1. StrictMode v3 propagation breaks Pester's scope-chain visibility of
#      $TestDrive when called from script:* helper functions. Tests fail
#      immediately at first `$x = script:NewFoo` line with a "variable not
#      set" RuntimeException, even though the line is an assignment, not a
#      read. (Reproduced in tests/brief-init.Tests.ps1 AC-BI-HAPPY-1/2.)
#   2. EAP=Stop propagation turns downstream `& git ... 2>&1` warning output
#      (e.g. git's LF-vs-CRLF auto-convert warning during `git add`) into a
#      terminating NativeCommandError, even when the test code itself sets
#      EAP locally. (Reproduced in tests/verify-ps1.Tests.ps1 D8 cases.)
#
# Why the helper's contract is unaffected by the absence:
#   The Invoke-NativeProcess function below sets `$ErrorActionPreference =
#   'Continue'` inside its own try/finally and restores the caller's previous
#   EAP before returning. That self-managed EAP is what gives the helper its
#   documented containment behaviour. The file-top EAP=Stop directive was
#   never load-bearing for the function's own behaviour - it was lib-template
#   cosmetics that happened to be wrong for this file's role.
#   The function body is also StrictMode-clean: callers that set StrictMode
#   at their own script top will get StrictMode applied to the helper's body
#   via the dynamic call-site scope chain, with no behaviour difference.
#
# Alternatives that were considered and rejected during Step B re-review:
#   - `& { . path } | Out-Null` sub-scope dot-source: would define the
#     function in the child scope only, making it invisible to callers.
#   - `Set-StrictMode -Version 1` workaround in each Pester BeforeAll after
#     the dot-source: addresses StrictMode only, not EAP, and pushes the
#     constraint into every test file instead of documenting it once here.
#   - Fixing the test side to be tolerant of ambient EAP=Stop: would require
#     changing 10 test files for a problem caused by 1 lib file's directives.
#
# Containment shim for native process invocation under Windows PowerShell 5.1.
#
# Background: in PS 5.1, capturing or merging a native executable's stderr
# (e.g. `& git ... 2>&1`, `& powershell.exe ... 2>&1`) wraps every stderr line
# into a NativeCommandError ErrorRecord. Under file-level
# $ErrorActionPreference = 'Stop' that record becomes a terminating error and
# aborts the call BEFORE the caller can inspect $LASTEXITCODE. See
# the active rule rules/powershell-and-file-encoding.md (Native-executable
# output capture).
#
# This helper pins $ErrorActionPreference = 'Continue' for the duration of the
# native call, redirects child stdout and stderr to separate temp files, and
# returns { ExitCode; Stdout; Stderr } so the caller drives all decisions from
# the child's exit code, not from PS-side stderr promotion.
#
# Scope: containment shim for the PowerShell MVP closeout. Not a general-purpose
# process framework. Timeout, stdin, environment, encoding, and cross-shell
# behaviour are intentionally out of scope; add a parameter only when a concrete
# caller requires it.
function Invoke-NativeProcess {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Executable,

        [Parameter(Mandatory = $false)]
        [string[]] $Arguments = @(),

        [Parameter(Mandatory = $false)]
        [string] $WorkingDirectory
    )

    $tempOut = [System.IO.Path]::GetTempFileName()
    $tempErr = [System.IO.Path]::GetTempFileName()
    Write-Verbose ('Invoke-NativeProcess: tempOut={0}' -f $tempOut)
    Write-Verbose ('Invoke-NativeProcess: tempErr={0}' -f $tempErr)

    $prevPref = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $pushed = $false
    $exitCode = $null
    $stdout = ''
    $stderr = ''
    try {
        if ($PSBoundParameters.ContainsKey('WorkingDirectory') -and -not [string]::IsNullOrEmpty($WorkingDirectory)) {
            Push-Location -LiteralPath $WorkingDirectory -ErrorAction Stop
            $pushed = $true
        }

        & $Executable @Arguments 1> $tempOut 2> $tempErr
        $exitCode = $LASTEXITCODE

        $utf8 = New-Object System.Text.UTF8Encoding($false)
        $stdout = [System.IO.File]::ReadAllText($tempOut, $utf8)
        $stderr = [System.IO.File]::ReadAllText($tempErr, $utf8)
    }
    finally {
        if ($pushed) { Pop-Location -ErrorAction SilentlyContinue }
        $ErrorActionPreference = $prevPref
        if (Test-Path -LiteralPath $tempOut) {
            Remove-Item -LiteralPath $tempOut -Force -ErrorAction SilentlyContinue
        }
        if (Test-Path -LiteralPath $tempErr) {
            Remove-Item -LiteralPath $tempErr -Force -ErrorAction SilentlyContinue
        }
    }

    return [pscustomobject]@{
        ExitCode = $exitCode
        Stdout   = $stdout
        Stderr   = $stderr
    }
}
