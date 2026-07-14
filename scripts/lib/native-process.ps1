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
# 파일 상단 지시가 없어도 helper contract가 유지되는 이유:
#   no-stdin 경로는 자체 try/finally 안에서 `$ErrorActionPreference =
#   'Continue'`를 고정하고 호출자의 이전 EAP를 복원한다. byte-stdin 경로는
#   PowerShell native invocation 대신 .NET process API를 사용하며 호출자의
#   EAP를 바꾸지 않는다. 따라서 파일 상단 EAP=Stop은 어느 경로에도
#   load-bearing하지 않고, 이 파일의 역할과 맞지 않는 lib template 관례였다.
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
# Observable contract:
#   - StandardInputBytes를 바인딩하지 않으면 기존 no-stdin PowerShell 경로를
#     유지한다. 바인딩하면 빈 배열을 포함한 raw byte sequence를 그대로 보내고
#     stdin을 닫아 EOF를 전달한다.
#   - byte-stdin 경로는 자식 실행 중 stdout과 stderr를 동시에 EOF까지 drain하고
#     두 스트림을 섞지 않으며, drain 뒤 strict UTF-8로 decode한다.
#   - 정상 반환은 두 경로 모두 정확히 { ExitCode; Stdout; Stderr }이다. 실패
#     경로는 소유한 child/process/stream/drain 자원을 best-effort로 정리하고
#     예외를 전파하지만, 모든 cleanup failure에서 원래 예외 우선순위를 보장하지
#     않는다.
#
# Current realizations:
# 레거시 no-stdin 경로는 $ErrorActionPreference = 'Continue'를 고정하고 자식의
# stdout과 stderr를 서로 다른 임시 파일로 보낸다. 명시적 byte-stdin 경로는
# .NET process API로 두 출력 스트림을 메모리에서 drain한다.
#
# 범위: 범용 process framework가 아니라 PowerShell MVP closeout용 containment
# shim이다. timeout, environment, cross-shell 동작은 계속 범위 밖이다. 구체적
# 호출자가 byte-safe stdin을 요구하므로 명시적으로 바인딩된 raw bytes만
# 지원하며, text encoding의 소유권은 호출자에게 남긴다.
function Invoke-NativeProcess {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Executable,

        [Parameter(Mandatory = $false)]
        [string[]] $Arguments = @(),

        [Parameter(Mandatory = $false)]
        [string] $WorkingDirectory,

        [Parameter(Mandatory = $false)]
        [AllowEmptyCollection()]
        [ValidateNotNull()]
        [byte[]] $StandardInputBytes
    )

    if ($PSBoundParameters.ContainsKey('StandardInputBytes')) {
        # Windows PowerShell 5.1의 ProcessStartInfo에는 ArgumentList가 없다.
        # 이 분기에서만 Windows command-line 인수 인코딩을 수행하고,
        # stdin 미지정 호출은 기존 PowerShell 전달 경로를 그대로 유지한다.
        $serializedArguments = @()
        foreach ($argumentValue in @($Arguments)) {
            $argument = [string] $argumentValue
            if ($argument.Length -eq 0) {
                $serializedArguments += '""'
                continue
            }
            if ($argument -notmatch '[\s"]') {
                $serializedArguments += $argument
                continue
            }

            $builder = New-Object System.Text.StringBuilder
            [void] $builder.Append('"')
            $backslashCount = 0
            for ($i = 0; $i -lt $argument.Length; $i++) {
                $character = $argument[$i]
                if ($character -eq '\') {
                    $backslashCount++
                    continue
                }

                if ($character -eq '"') {
                    [void] $builder.Append(('\' * (($backslashCount * 2) + 1)))
                    [void] $builder.Append('"')
                    $backslashCount = 0
                    continue
                }

                if ($backslashCount -gt 0) {
                    [void] $builder.Append(('\' * $backslashCount))
                    $backslashCount = 0
                }
                [void] $builder.Append($character)
            }
            if ($backslashCount -gt 0) {
                [void] $builder.Append(('\' * ($backslashCount * 2)))
            }
            [void] $builder.Append('"')
            $serializedArguments += $builder.ToString()
        }

        $strictUtf8 = New-Object System.Text.UTF8Encoding($false, $true)
        $startInfo = New-Object System.Diagnostics.ProcessStartInfo
        $startInfo.FileName = $Executable
        $startInfo.Arguments = [string]::Join(' ', [string[]] $serializedArguments)
        $startInfo.UseShellExecute = $false
        $startInfo.CreateNoWindow = $true
        $startInfo.RedirectStandardInput = $true
        $startInfo.RedirectStandardOutput = $true
        $startInfo.RedirectStandardError = $true
        if ($PSBoundParameters.ContainsKey('WorkingDirectory') -and -not [string]::IsNullOrEmpty($WorkingDirectory)) {
            $startInfo.WorkingDirectory = $WorkingDirectory
        }

        $process = New-Object System.Diagnostics.Process
        $process.StartInfo = $startInfo
        $started = $false
        $stdinStream = $null
        $stdoutBuffer = $null
        $stderrBuffer = $null
        $stdoutTask = $null
        $stderrTask = $null
        try {
            # PS 5.1은 ProcessStartInfo.StandardInputEncoding을 제공하지 않고
            # Process.Start()에서 ambient Console.InputEncoding으로 stdin
            # StreamWriter를 만든다. no-BOM 인코딩으로 생성 구간만 직렬화한다.
            $inputEncodingLock = [System.Console]
            [System.Threading.Monitor]::Enter($inputEncodingLock)
            try {
                $previousInputEncoding = [Console]::InputEncoding
                try {
                    [Console]::InputEncoding = $strictUtf8
                    $started = $process.Start()
                }
                finally {
                    [Console]::InputEncoding = $previousInputEncoding
                }
            }
            finally {
                [System.Threading.Monitor]::Exit($inputEncodingLock)
            }
            if (-not $started) {
                throw "Native process did not start: $Executable"
            }

            # 디코딩은 drain이 끝난 뒤 수행한다. StreamReader의 BOM 자동 감지나
            # 조기 decoder fault가 pipe drain을 중단하지 못하도록 raw bytes를 받는다.
            $stdoutBuffer = New-Object System.IO.MemoryStream
            $stderrBuffer = New-Object System.IO.MemoryStream
            $stdoutTask = $process.StandardOutput.BaseStream.CopyToAsync($stdoutBuffer)
            $stderrTask = $process.StandardError.BaseStream.CopyToAsync($stderrBuffer)
            $stdinStream = $process.StandardInput.BaseStream
            try {
                if ($StandardInputBytes.Length -gt 0) {
                    $stdinTask = $stdinStream.WriteAsync(
                        $StandardInputBytes,
                        0,
                        $StandardInputBytes.Length
                    )
                    [void] $stdinTask.GetAwaiter().GetResult()
                }
                $stdinStream.Flush()
            }
            finally {
                # StreamWriter를 닫으면 ambient InputEncoding의 preamble이 추가될 수
                # 있으므로 raw stream 자체를 닫아 빈 byte[]도 변형 없는 EOF로 보낸다.
                if ($null -ne $stdinStream) { $stdinStream.Dispose() }
            }

            $process.WaitForExit()
            [void] $stdoutTask.GetAwaiter().GetResult()
            [void] $stderrTask.GetAwaiter().GetResult()
            $stdout = $strictUtf8.GetString($stdoutBuffer.ToArray())
            $stderr = $strictUtf8.GetString($stderrBuffer.ToArray())
            $exitCode = $process.ExitCode

            return [pscustomobject]@{
                ExitCode = $exitCode
                Stdout   = $stdout
                Stderr   = $stderr
            }
        }
        finally {
            if ($null -ne $process) {
                if ($started) {
                    $hasExited = $false
                    try { $hasExited = $process.HasExited } catch { }
                    if (-not $hasExited) {
                        try { $process.Kill() } catch { }
                        try { $process.WaitForExit() } catch { }
                    }
                }
                if ($null -ne $stdoutTask) {
                    try { [void] $stdoutTask.GetAwaiter().GetResult() } catch { }
                }
                if ($null -ne $stderrTask) {
                    try { [void] $stderrTask.GetAwaiter().GetResult() } catch { }
                }
                try { $process.Dispose() } catch { }
            }
            if ($null -ne $stdoutBuffer) { $stdoutBuffer.Dispose() }
            if ($null -ne $stderrBuffer) { $stderrBuffer.Dispose() }
        }
    }

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
