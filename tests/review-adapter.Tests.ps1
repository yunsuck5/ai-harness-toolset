Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

BeforeAll {
    $script:RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).ProviderPath
    $script:ScriptsDir = Join-Path $script:RepoRoot 'scripts'

    function script:Find-BashExecutable {
        # The adapters target Git Bash-compatible Bash on Windows (per the
        # Candidate A decision packet). Resolution order:
        #   1. AI_HARNESS_BASH_EXE env override (test-isolation hook).
        #   2. `bash` on PATH via Get-Command.
        #   3. Known Git for Windows install locations.
        # If none resolve, throw — per the goal, missing Bash must surface as a
        # loud test failure, not be silently replaced with a direct .ps1 call.
        $override = $env:AI_HARNESS_BASH_EXE
        if (-not [string]::IsNullOrEmpty($override) -and (Test-Path -LiteralPath $override -PathType Leaf)) {
            return $override
        }

        $cmd = Get-Command bash -ErrorAction SilentlyContinue
        if ($null -ne $cmd -and -not [string]::IsNullOrEmpty($cmd.Source) -and (Test-Path -LiteralPath $cmd.Source -PathType Leaf)) {
            return $cmd.Source
        }

        $candidates = @(
            (Join-Path $env:ProgramFiles      'Git\usr\bin\bash.exe'),
            (Join-Path $env:ProgramFiles      'Git\bin\bash.exe'),
            (Join-Path ${env:ProgramFiles(x86)} 'Git\usr\bin\bash.exe'),
            'C:\msys64\usr\bin\bash.exe'
        )
        foreach ($p in $candidates) {
            if (-not [string]::IsNullOrEmpty($p) -and (Test-Path -LiteralPath $p -PathType Leaf)) {
                return $p
            }
        }

        throw 'Find-BashExecutable: no Git Bash-compatible bash.exe found. The adapter tests require Bash on Windows. Searched PATH, $env:AI_HARNESS_BASH_EXE, and common Git for Windows install paths.'
    }

    $script:BashExe = script:Find-BashExecutable

    function script:New-StubArea {
        # Build an isolated working directory with the adapter under test plus a
        # PowerShell stub that records the parameters PowerShell binds. The stub
        # filename matches what the adapter expects to invoke (e.g. review-prepare.sh
        # invokes review-prepare.ps1 in the same directory).
        param(
            [Parameter(Mandatory = $true)] [string] $AdapterName,
            [Parameter(Mandatory = $true)] [string] $PsScriptName
        )
        $area = Join-Path $TestDrive ('adapter-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
        $null = New-Item -ItemType Directory -Path $area -Force

        $sourceAdapter = Join-Path $script:ScriptsDir $AdapterName
        if (-not (Test-Path -LiteralPath $sourceAdapter -PathType Leaf)) {
            throw "New-StubArea: adapter not found in repo scripts dir: $sourceAdapter"
        }
        Copy-Item -LiteralPath $sourceAdapter -Destination (Join-Path $area $AdapterName) -Force

        $stubBody = @'
[CmdletBinding()]
param(
    [string] $ReviewTaskId,
    [string] $Pass,
    [string] $Stage,
    [string] $Purpose,
    [string] $ProjectRoot,
    [string] $ToolRoot,
    [string] $Reviewer,
    [string] $Model,
    [switch] $RequireResult
)

$dump = $env:STUB_ARGS_DUMP
if (-not [string]::IsNullOrEmpty($dump)) {
    $lines = @(
        ('ReviewTaskId='   + $ReviewTaskId),
        ('Pass='           + $Pass),
        ('Stage='          + $Stage),
        ('Purpose='        + $Purpose),
        ('ProjectRoot='    + $ProjectRoot),
        ('ToolRoot='       + $ToolRoot),
        ('Reviewer='       + $Reviewer),
        ('Model='          + $Model),
        ('RequireResult='  + $RequireResult.IsPresent)
    )
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllLines($dump, $lines, $utf8NoBom)
}

Write-Host 'STUB_STDOUT_LINE'
[Console]::Error.WriteLine('STUB_STDERR_LINE')

$code = $env:STUB_EXIT_CODE
if ([string]::IsNullOrEmpty($code)) { exit 0 }
exit ([int]$code)
'@

        # Match the repo .ps1 file convention: UTF-8 with BOM, CRLF line endings.
        $body = $stubBody -replace "`r`n", "`n" -replace "`n", "`r`n"
        $stubPath = Join-Path $area $PsScriptName
        $utf8WithBom = New-Object System.Text.UTF8Encoding($true)
        [System.IO.File]::WriteAllText($stubPath, $body, $utf8WithBom)

        return [pscustomobject]@{
            Area    = $area
            Adapter = (Join-Path $area $AdapterName)
            Stub    = $stubPath
        }
    }

    function script:Invoke-Adapter {
        # Invoke the bash adapter with the supplied argument list, capturing
        # stdout / stderr / exit code. Environment variables passed in $EnvMap
        # are set on the current process so the child bash and powershell
        # inherit them, and restored afterward.
        param(
            [Parameter(Mandatory = $true)] [string] $AdapterPath,
            [object[]] $AdapterArgs = @(),
            [hashtable] $EnvMap = @{}
        )

        $outFile = Join-Path $TestDrive ('out-' + [guid]::NewGuid().ToString('N').Substring(0, 8) + '.txt')
        $errFile = Join-Path $TestDrive ('err-' + [guid]::NewGuid().ToString('N').Substring(0, 8) + '.txt')

        $prevEnv = @{}
        foreach ($k in $EnvMap.Keys) {
            $prevEnv[$k] = [System.Environment]::GetEnvironmentVariable($k, 'Process')
            [System.Environment]::SetEnvironmentVariable($k, [string]$EnvMap[$k], 'Process')
        }

        try {
            $callArgs = @($AdapterPath) + $AdapterArgs
            # Windows PowerShell 5.1 wraps every stderr line from a native exe
            # in an ErrorRecord (NativeCommandError) and, under the script-level
            # $ErrorActionPreference = 'Stop', that aborts the call before we
            # can inspect the exit code. We need both the non-zero-exit cases
            # (e.g. stub returning 7) and the orphan-stderr case to flow back
            # as data, so suppress the per-call error preference locally.
            $prevPref = $ErrorActionPreference
            $ErrorActionPreference = 'Continue'
            try {
                & $script:BashExe @callArgs 1> $outFile 2> $errFile
                $exit = $LASTEXITCODE
            }
            finally {
                $ErrorActionPreference = $prevPref
            }
        }
        finally {
            foreach ($k in $EnvMap.Keys) {
                [System.Environment]::SetEnvironmentVariable($k, $prevEnv[$k], 'Process')
            }
        }

        $utf8 = New-Object System.Text.UTF8Encoding($false)
        $stdout = [System.IO.File]::ReadAllText($outFile, $utf8)
        $stderr = [System.IO.File]::ReadAllText($errFile, $utf8)

        return [pscustomobject]@{
            ExitCode = $exit
            Stdout   = $stdout
            Stderr   = $stderr
        }
    }

    function script:Read-ArgsDump {
        param([Parameter(Mandatory = $true)] [string] $Path)
        if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
            throw "Read-ArgsDump: dump file not found: $Path"
        }
        $utf8 = New-Object System.Text.UTF8Encoding($false)
        $text = [System.IO.File]::ReadAllText($Path, $utf8)
        $map = @{}
        foreach ($line in ($text -split "`r?`n")) {
            if ($line -match '^([^=]+)=(.*)$') {
                $map[$Matches[1]] = $Matches[2]
            }
        }
        return $map
    }
}

Describe 'scripts/review-prepare.sh thin Bash adapter' {
    It 'forwards PowerShell-style parameters unchanged to the canonical .ps1' {
        $area = script:New-StubArea -AdapterName 'review-prepare.sh' -PsScriptName 'review-prepare.ps1'
        $dumpPath = Join-Path $area.Area 'args.txt'
        $result = script:Invoke-Adapter -AdapterPath $area.Adapter -AdapterArgs @(
            '-ReviewTaskId', 'task-1',
            '-Pass', 'pass-01',
            '-Stage', 'design',
            '-Purpose', 'this is a purpose with spaces'
        ) -EnvMap @{ STUB_ARGS_DUMP = $dumpPath; STUB_EXIT_CODE = '0' }

        $result.ExitCode | Should -Be 0
        $dump = script:Read-ArgsDump -Path $dumpPath
        $dump['ReviewTaskId'] | Should -Be 'task-1'
        $dump['Pass']         | Should -Be 'pass-01'
        $dump['Stage']        | Should -Be 'design'
        $dump['Purpose']      | Should -Be 'this is a purpose with spaces'
    }

    It 'propagates the underlying script exit code' {
        $area = script:New-StubArea -AdapterName 'review-prepare.sh' -PsScriptName 'review-prepare.ps1'
        $result = script:Invoke-Adapter -AdapterPath $area.Adapter -AdapterArgs @(
            '-ReviewTaskId', 'task-2',
            '-Stage', 'implementation',
            '-Purpose', 'x'
        ) -EnvMap @{ STUB_EXIT_CODE = '7' }
        $result.ExitCode | Should -Be 7
    }

    It 'preserves stdout and stderr from the underlying script' {
        $area = script:New-StubArea -AdapterName 'review-prepare.sh' -PsScriptName 'review-prepare.ps1'
        $result = script:Invoke-Adapter -AdapterPath $area.Adapter -AdapterArgs @(
            '-ReviewTaskId', 'task-3',
            '-Stage', 'design',
            '-Purpose', 'x'
        ) -EnvMap @{ STUB_EXIT_CODE = '0' }
        $result.Stdout | Should -Match 'STUB_STDOUT_LINE'
        $result.Stderr | Should -Match 'STUB_STDERR_LINE'
    }

    It 'normalizes a CWD-relative -ProjectRoot to an absolute Windows-native path' {
        $area = script:New-StubArea -AdapterName 'review-prepare.sh' -PsScriptName 'review-prepare.ps1'
        $dumpPath = Join-Path $area.Area 'args.txt'
        $expected = [System.IO.Path]::GetFullPath($area.Area).TrimEnd([System.IO.Path]::DirectorySeparatorChar)

        Push-Location $area.Area
        try {
            $result = script:Invoke-Adapter -AdapterPath $area.Adapter -AdapterArgs @(
                '-ReviewTaskId', 'task-4',
                '-Stage', 'design',
                '-Purpose', 'x',
                '-ProjectRoot', '.'
            ) -EnvMap @{ STUB_ARGS_DUMP = $dumpPath; STUB_EXIT_CODE = '0' }
        }
        finally {
            Pop-Location
        }

        $result.ExitCode | Should -Be 0
        $dump = script:Read-ArgsDump -Path $dumpPath
        $dump['ProjectRoot'].TrimEnd([System.IO.Path]::DirectorySeparatorChar) | Should -Be $expected
    }

    It 'normalizes a POSIX-style absolute -ToolRoot to a Windows-native path' {
        $area = script:New-StubArea -AdapterName 'review-prepare.sh' -PsScriptName 'review-prepare.ps1'
        $dumpPath = Join-Path $area.Area 'args.txt'
        $winPath = [System.IO.Path]::GetFullPath($area.Area).TrimEnd([System.IO.Path]::DirectorySeparatorChar)

        # Convert "H:\Work\..." to "/h/Work/..." without relying on cygpath being
        # visible from this PowerShell process. The adapter's own conversion
        # (case "${abs#/}" != "$abs") is the unit under test; this just shapes
        # an input that the adapter must then convert back to Windows-native.
        if ($winPath -notmatch '^([A-Za-z]):\\(.*)$') {
            Set-ItResult -Skipped -Because "test area is not on a drive letter path: $winPath"
            return
        }
        $drive = $Matches[1].ToLowerInvariant()
        $rest  = $Matches[2] -replace '\\', '/'
        $posixPath = "/$drive/$rest"

        $result = script:Invoke-Adapter -AdapterPath $area.Adapter -AdapterArgs @(
            '-ReviewTaskId', 'task-5',
            '-Stage', 'design',
            '-Purpose', 'x',
            '-ToolRoot', $posixPath
        ) -EnvMap @{ STUB_ARGS_DUMP = $dumpPath; STUB_EXIT_CODE = '0' }

        $result.ExitCode | Should -Be 0
        $dump = script:Read-ArgsDump -Path $dumpPath
        $dump['ToolRoot'].TrimEnd([System.IO.Path]::DirectorySeparatorChar) | Should -Be $winPath
    }

    It 'forwards a non-ASCII -Purpose value verbatim (Korean + CJK)' {
        $area = script:New-StubArea -AdapterName 'review-prepare.sh' -PsScriptName 'review-prepare.ps1'
        $dumpPath = Join-Path $area.Area 'args.txt'
        $korean = '한국어 테스트 文字'

        $result = script:Invoke-Adapter -AdapterPath $area.Adapter -AdapterArgs @(
            '-ReviewTaskId', 'task-6',
            '-Stage', 'design',
            '-Purpose', $korean
        ) -EnvMap @{ STUB_ARGS_DUMP = $dumpPath; STUB_EXIT_CODE = '0' }

        $result.ExitCode | Should -Be 0
        $dump = script:Read-ArgsDump -Path $dumpPath
        $dump['Purpose'] | Should -Be $korean
    }

    It 'normalizes two consecutive -ProjectRoot / -ToolRoot path flags in one invocation' {
        $area = script:New-StubArea -AdapterName 'review-prepare.sh' -PsScriptName 'review-prepare.ps1'
        $dumpPath = Join-Path $area.Area 'args.txt'

        $winPath = [System.IO.Path]::GetFullPath($area.Area).TrimEnd([System.IO.Path]::DirectorySeparatorChar)
        if ($winPath -notmatch '^([A-Za-z]):\\(.*)$') {
            Set-ItResult -Skipped -Because "test area is not on a drive letter path: $winPath"
            return
        }
        $drive = $Matches[1].ToLowerInvariant()
        $rest  = $Matches[2] -replace '\\', '/'
        $posixPath = "/$drive/$rest"

        # CWD-relative for -ProjectRoot, POSIX-rooted for -ToolRoot, both back-to-back.
        Push-Location $area.Area
        try {
            $result = script:Invoke-Adapter -AdapterPath $area.Adapter -AdapterArgs @(
                '-ReviewTaskId', 'consecutive-1',
                '-Stage', 'design',
                '-Purpose', 'x',
                '-ProjectRoot', '.',
                '-ToolRoot', $posixPath
            ) -EnvMap @{ STUB_ARGS_DUMP = $dumpPath; STUB_EXIT_CODE = '0' }
        }
        finally {
            Pop-Location
        }

        $result.ExitCode | Should -Be 0
        $dump = script:Read-ArgsDump -Path $dumpPath
        $dump['ProjectRoot'].TrimEnd([System.IO.Path]::DirectorySeparatorChar) | Should -Be $winPath
        $dump['ToolRoot'].TrimEnd([System.IO.Path]::DirectorySeparatorChar)    | Should -Be $winPath
    }

    It 'forwards path flags interleaved with ordinary parameters in arbitrary order' {
        $area = script:New-StubArea -AdapterName 'review-prepare.sh' -PsScriptName 'review-prepare.ps1'
        $dumpPath = Join-Path $area.Area 'args.txt'

        $winPath = [System.IO.Path]::GetFullPath($area.Area).TrimEnd([System.IO.Path]::DirectorySeparatorChar)
        if ($winPath -notmatch '^([A-Za-z]):\\(.*)$') {
            Set-ItResult -Skipped -Because "test area is not on a drive letter path: $winPath"
            return
        }
        $drive = $Matches[1].ToLowerInvariant()
        $rest  = $Matches[2] -replace '\\', '/'
        $posixPath = "/$drive/$rest"

        # Path flags scattered among non-path flags; -ProjectRoot is CWD-relative,
        # -ToolRoot is POSIX-rooted, -Pass is interleaved between them.
        Push-Location $area.Area
        try {
            $result = script:Invoke-Adapter -AdapterPath $area.Adapter -AdapterArgs @(
                '-ReviewTaskId', 'interleave-1',
                '-Stage', 'design',
                '-ProjectRoot', '.',
                '-Purpose', 'mid-purpose',
                '-Pass', 'pass-03',
                '-ToolRoot', $posixPath
            ) -EnvMap @{ STUB_ARGS_DUMP = $dumpPath; STUB_EXIT_CODE = '0' }
        }
        finally {
            Pop-Location
        }

        $result.ExitCode | Should -Be 0
        $dump = script:Read-ArgsDump -Path $dumpPath
        $dump['ReviewTaskId']  | Should -Be 'interleave-1'
        $dump['Stage']         | Should -Be 'design'
        $dump['Purpose']       | Should -Be 'mid-purpose'
        $dump['Pass']          | Should -Be 'pass-03'
        $dump['ProjectRoot'].TrimEnd([System.IO.Path]::DirectorySeparatorChar) | Should -Be $winPath
        $dump['ToolRoot'].TrimEnd([System.IO.Path]::DirectorySeparatorChar)    | Should -Be $winPath
    }

    It 'forwards a quote-heavy -Purpose verbatim when invoked from a real Bash shell (literal $, backtick, single + double quote, spaces)' {
        # Bash callers use bash-side quoting to assemble the -Purpose value.
        # We isolate the adapter from PowerShell 5.1''s known native-exe argv
        # quoting bugs by running the adapter through a small Bash launcher
        # script that holds the value as a bash single-quoted literal. This
        # is the actual round-trip an operator using `bash` sees, and it
        # exercises the bash -> adapter -> powershell boundary that the
        # adapter is responsible for; the PowerShell -> bash launcher boundary
        # only transports file paths, not the quote-heavy value.
        $area = script:New-StubArea -AdapterName 'review-prepare.sh' -PsScriptName 'review-prepare.ps1'
        $dumpPath = Join-Path $area.Area 'args.txt'

        # Expected value byte-for-byte:  a b 'c' "d" $e `f` g
        # Contains: spaces, single quote, double quote, literal dollar sign
        # (must not be variable-expanded), literal backtick (must not act as
        # a PowerShell escape).
        $expected = "a b 'c' `"d`" `$e ``f`` g"

        # The launcher's -Purpose argument uses bash single-quote literal form.
        # Each embedded single quote is split out as  '\''  (close quote,
        # escaped literal quote, reopen quote), which is the standard idiom
        # for embedding a single quote inside a bash single-quoted string.
        # The resulting argv element bash hands to the adapter is exactly
        # the value of $expected above.
        $launcherBody = @'
#!/usr/bin/env bash
set -e
# The launcher inherits the parent shell's PATH; when invoked from Windows
# PowerShell that PATH typically lacks /usr/bin, so `bash` itself is not
# resolvable by name. Mirror the adapter's PATH bootstrap so the explicit
# `exec bash "$1"` below can find the bash interpreter.
case ":$PATH:" in
    *:/usr/bin:*) ;;
    *) PATH="/usr/bin:/bin:$PATH" ;;
esac
# Explicitly invoke the adapter via bash so the shebang interpretation does
# not depend on the file having +x (TestDrive copies on Windows do not).
exec bash "$1" -ReviewTaskId quote-heavy-1 -Stage design -Purpose 'a b '\''c'\'' "d" $e `f` g'
'@
        # Bash scripts use LF line endings.
        $launcherBody = $launcherBody -replace "`r`n", "`n"
        $launcherPath = Join-Path $area.Area 'launch.sh'
        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($launcherPath, $launcherBody, $utf8NoBom)

        # PowerShell only transports two file paths to bash; the quote-heavy
        # value never crosses the PowerShell-to-native-exe argv boundary.
        $result = script:Invoke-Adapter -AdapterPath $launcherPath -AdapterArgs @($area.Adapter) -EnvMap @{ STUB_ARGS_DUMP = $dumpPath; STUB_EXIT_CODE = '0' }

        $result.ExitCode | Should -Be 0
        $dump = script:Read-ArgsDump -Path $dumpPath
        $dump['Purpose'] | Should -Be $expected
    }

    It 'fails fast with a clear stderr message when the sibling .ps1 is missing' {
        $orphan = Join-Path $TestDrive ('orphan-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
        $null = New-Item -ItemType Directory -Path $orphan -Force
        Copy-Item -LiteralPath (Join-Path $script:ScriptsDir 'review-prepare.sh') -Destination (Join-Path $orphan 'review-prepare.sh') -Force

        $result = script:Invoke-Adapter -AdapterPath (Join-Path $orphan 'review-prepare.sh') -AdapterArgs @()

        $result.ExitCode | Should -Not -Be 0
        $result.Stderr | Should -Match 'canonical script not found'
    }
}

Describe 'scripts/review-run.sh thin Bash adapter' {
    It 'forwards run-specific parameters and propagates the exit code' {
        $area = script:New-StubArea -AdapterName 'review-run.sh' -PsScriptName 'review-run.ps1'
        $dumpPath = Join-Path $area.Area 'args.txt'

        $result = script:Invoke-Adapter -AdapterPath $area.Adapter -AdapterArgs @(
            '-ReviewTaskId', 'run-1',
            '-Pass', 'pass-02',
            '-Reviewer', 'codex',
            '-Model', 'gpt-5.5'
        ) -EnvMap @{ STUB_ARGS_DUMP = $dumpPath; STUB_EXIT_CODE = '3' }

        $result.ExitCode | Should -Be 3
        $dump = script:Read-ArgsDump -Path $dumpPath
        $dump['ReviewTaskId'] | Should -Be 'run-1'
        $dump['Pass']         | Should -Be 'pass-02'
        $dump['Reviewer']     | Should -Be 'codex'
        $dump['Model']        | Should -Be 'gpt-5.5'
    }
}

Describe 'scripts/review-verify.sh thin Bash adapter' {
    It 'forwards -RequireResult as a switch (bare token, no value)' {
        $area = script:New-StubArea -AdapterName 'review-verify.sh' -PsScriptName 'review-verify.ps1'
        $dumpPath = Join-Path $area.Area 'args.txt'

        $result = script:Invoke-Adapter -AdapterPath $area.Adapter -AdapterArgs @(
            '-ReviewTaskId', 'verify-1',
            '-Pass', 'pass-01',
            '-RequireResult'
        ) -EnvMap @{ STUB_ARGS_DUMP = $dumpPath; STUB_EXIT_CODE = '0' }

        $result.ExitCode | Should -Be 0
        $dump = script:Read-ArgsDump -Path $dumpPath
        $dump['ReviewTaskId']  | Should -Be 'verify-1'
        $dump['Pass']          | Should -Be 'pass-01'
        $dump['RequireResult'] | Should -Be 'True'
    }
}
