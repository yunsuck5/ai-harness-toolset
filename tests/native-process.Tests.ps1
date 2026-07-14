Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

BeforeAll {
    $script:RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).ProviderPath
    . (Join-Path $script:RepoRoot 'scripts/lib/native-process.ps1')

    function script:Invoke-NativeProcessWithVerbose {
        param(
            [Parameter(Mandatory = $true)]
            [hashtable] $Params
        )
        $captured = Invoke-NativeProcess @Params -Verbose 4>&1
        $verboseMessages = @()
        $result = $null
        foreach ($item in $captured) {
            if ($item -is [System.Management.Automation.VerboseRecord]) {
                $verboseMessages += $item.Message
            }
            elseif ($item -is [pscustomobject]) {
                $result = $item
            }
        }
        $tempOutPath = $null
        $tempErrPath = $null
        foreach ($m in $verboseMessages) {
            if ($m -match '^Invoke-NativeProcess: tempOut=(.+)$') { $tempOutPath = $matches[1].Trim() }
            if ($m -match '^Invoke-NativeProcess: tempErr=(.+)$') { $tempErrPath = $matches[1].Trim() }
        }
        return [pscustomobject]@{
            Result      = $result
            Verbose     = $verboseMessages
            TempOutPath = $tempOutPath
            TempErrPath = $tempErrPath
        }
    }
}

Describe 'Invoke-NativeProcess: return contract' {
    It 'AC-NP-1: success child returns ExitCode 0 (axis 1)' {
        $r = Invoke-NativeProcess -Executable 'powershell.exe' -Arguments @('-NoProfile', '-Command', 'exit 0')
        $r.ExitCode | Should -Be 0
        $r.PSObject.Properties.Name | Should -Contain 'ExitCode'
        $r.PSObject.Properties.Name | Should -Contain 'Stdout'
        $r.PSObject.Properties.Name | Should -Contain 'Stderr'
        @($r.PSObject.Properties.Name).Count | Should -Be 3
    }

    It 'AC-NP-2: non-zero exit child returns matching ExitCode (axis 1)' {
        $r = Invoke-NativeProcess -Executable 'powershell.exe' -Arguments @('-NoProfile', '-Command', 'exit 7')
        $r.ExitCode | Should -Be 7
    }

    It 'AC-NP-3: stdout from child is captured (axis 2)' {
        $r = Invoke-NativeProcess -Executable 'powershell.exe' -Arguments @('-NoProfile', '-Command', 'Write-Output "alpha-stdout-marker"')
        $r.Stdout | Should -Match 'alpha-stdout-marker'
        $r.Stderr | Should -Not -Match 'alpha-stdout-marker'
    }

    It 'AC-NP-4: stderr from child is captured under outer EAP=Stop without aborting (axes 3 and 5)' {
        # NOTE: child -Command uses single quotes around the marker, not double
        # quotes. Windows PowerShell 5.1 wraps each `& <exe> @argv` arg that
        # contains spaces in double quotes for the child but does not always
        # re-escape interior double quotes; a literal `"..."` inside the
        # -Command string can be split by the child host's parser. Single-quoted
        # markers avoid that PS 5.1-specific host quirk and exercise only the
        # helper's contract (stderr capture under EAP=Stop).
        $outerPrev = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'
        try {
            $r = Invoke-NativeProcess -Executable 'powershell.exe' -Arguments @('-NoProfile', '-Command', "[Console]::Error.WriteLine('boom-stderr-marker'); exit 0")
            $r.Stderr | Should -Match 'boom-stderr-marker'
            $r.Stdout | Should -Not -Match 'boom-stderr-marker'
            $r.ExitCode | Should -Be 0
        }
        finally {
            $ErrorActionPreference = $outerPrev
        }
    }

    It 'AC-NP-5: stdout and stderr are captured separately when both are written (axis 4)' {
        $cmd = "Write-Output 'out_only_marker'; [Console]::Error.WriteLine('err_only_marker')"
        $r = Invoke-NativeProcess -Executable 'powershell.exe' -Arguments @('-NoProfile', '-Command', $cmd)
        $r.Stdout | Should -Match 'out_only_marker'
        $r.Stderr | Should -Match 'err_only_marker'
        $r.Stdout | Should -Not -Match 'err_only_marker'
        $r.Stderr | Should -Not -Match 'out_only_marker'
    }
}

Describe 'Invoke-NativeProcess: ErrorActionPreference scope' {
    It 'AC-NP-6: outer EAP=Stop with stderr-emitting child does not throw (axis 5)' {
        $outerPrev = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'
        try {
            { Invoke-NativeProcess -Executable 'powershell.exe' -Arguments @('-NoProfile', '-Command', "[Console]::Error.WriteLine('stderr-line'); exit 0") } | Should -Not -Throw
        }
        finally {
            $ErrorActionPreference = $outerPrev
        }
    }

    It 'AC-NP-7: caller EAP is unchanged after a successful call (axis 6)' {
        $outerPrev = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'
        try {
            Invoke-NativeProcess -Executable 'powershell.exe' -Arguments @('-NoProfile', '-Command', 'exit 0') | Out-Null
            $ErrorActionPreference | Should -Be 'Stop'
        }
        finally {
            $ErrorActionPreference = $outerPrev
        }
    }

    It 'AC-NP-8: caller EAP is unchanged after a non-zero-exit call (axis 6)' {
        $outerPrev = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        try {
            Invoke-NativeProcess -Executable 'powershell.exe' -Arguments @('-NoProfile', '-Command', 'exit 3') | Out-Null
            $ErrorActionPreference | Should -Be 'Continue'
        }
        finally {
            $ErrorActionPreference = $outerPrev
        }
    }

    It 'AC-NP-9: caller EAP is restored after an exception thrown inside the helper try (axis 7)' {
        $badDir = Join-Path $TestDrive ('np-nonexistent-' + [guid]::NewGuid().ToString('N'))
        (Test-Path -LiteralPath $badDir) | Should -BeFalse

        $outerPrev = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'
        $threw = $false
        try {
            try {
                Invoke-NativeProcess -Executable 'powershell.exe' -Arguments @('-NoProfile') -WorkingDirectory $badDir | Out-Null
            }
            catch {
                $threw = $true
            }
            $threw | Should -BeTrue
            $ErrorActionPreference | Should -Be 'Stop'
        }
        finally {
            $ErrorActionPreference = $outerPrev
        }
    }
}

Describe 'Invoke-NativeProcess: argument forwarding' {
    It 'AC-NP-10: -Arguments elements with spaces are forwarded as single args (axis 8)' {
        # Use -File with a TestDrive script. powershell.exe -File <path> <args...>
        # is the canonical way to pass positional args into the child's $args.
        # The script writes each $args element wrapped in arg=[...] so the test
        # can verify spaces inside an element were not split into multiple args.
        $scriptPath = Join-Path $TestDrive 'np-echo-args.ps1'
        $utf8 = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($scriptPath, "`$args | ForEach-Object { Write-Output ('arg=[' + `$_ + ']') }`r`n", $utf8)

        $r = Invoke-NativeProcess -Executable 'powershell.exe' -Arguments @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $scriptPath, 'hello world', 'simple', 'a b c')
        $r.ExitCode | Should -Be 0
        $r.Stdout | Should -Match 'arg=\[hello world\]'
        $r.Stdout | Should -Match 'arg=\[simple\]'
        $r.Stdout | Should -Match 'arg=\[a b c\]'
    }
}

Describe 'Invoke-NativeProcess: byte stdin' {
    It 'AC-NP-13: UTF-8 CJK bytes reach stdin unchanged while streams and exit stay separate (axis 10)' {
        $scriptPath = Join-Path $TestDrive 'np-read-stdin.ps1'
        $utf8 = New-Object System.Text.UTF8Encoding($false)
        $childScript = @'
$inputStream = [Console]::OpenStandardInput()
$memory = New-Object System.IO.MemoryStream
$buffer = New-Object byte[] 4096
do {
    $read = $inputStream.Read($buffer, 0, $buffer.Length)
    if ($read -gt 0) { $memory.Write($buffer, 0, $read) }
} while ($read -gt 0)
[Console]::Out.WriteLine([Convert]::ToBase64String($memory.ToArray()))
[Console]::Error.WriteLine('byte-stdin-stderr-marker')
exit 23
'@
        [System.IO.File]::WriteAllText($scriptPath, $childScript, $utf8)

        $inputBytes = $utf8.GetBytes("한글 中文 日本語 😀`r`nsecond line`n")
        $previousInputEncoding = [Console]::InputEncoding
        try {
            # BOM을 내보내는 ambient encoding도 raw stdin에 영향을 주면 안 된다.
            $ambientInputEncoding = New-Object System.Text.UTF8Encoding($true)
            [Console]::InputEncoding = $ambientInputEncoding
            $r = Invoke-NativeProcess `
                -Executable 'powershell.exe' `
                -Arguments @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $scriptPath) `
                -StandardInputBytes $inputBytes
            [Console]::InputEncoding.GetPreamble().Length | Should -Be 3
        }
        finally {
            [Console]::InputEncoding = $previousInputEncoding
        }

        $r.ExitCode | Should -Be 23
        $r.Stdout.Trim() | Should -Be ([Convert]::ToBase64String($inputBytes))
        $r.Stderr | Should -Match 'byte-stdin-stderr-marker'
        $r.Stdout | Should -Not -Match 'byte-stdin-stderr-marker'
        $r.PSObject.Properties.Name | Should -Contain 'ExitCode'
        $r.PSObject.Properties.Name | Should -Contain 'Stdout'
        $r.PSObject.Properties.Name | Should -Contain 'Stderr'
        @($r.PSObject.Properties.Name).Count | Should -Be 3
    }

    It 'AC-NP-14: bound-empty stdin sends EOF and preserves difficult argv plus working directory (axis 11)' {
        $workingDirectory = Join-Path $TestDrive 'np cwd with spaces'
        New-Item -ItemType Directory -Path $workingDirectory -Force | Out-Null
        $scriptPath = Join-Path $workingDirectory 'np-echo-stdin-args.ps1'
        $utf8 = New-Object System.Text.UTF8Encoding($false)
        $childScript = @'
$utf8 = New-Object System.Text.UTF8Encoding($false)
foreach ($value in $args) {
    [Console]::Out.WriteLine([Convert]::ToBase64String($utf8.GetBytes([string] $value)))
}
$firstByte = [Console]::OpenStandardInput().ReadByte()
[Console]::Out.WriteLine(('stdin={0}' -f $firstByte))
[Console]::Error.WriteLine([Convert]::ToBase64String($utf8.GetBytes([Environment]::CurrentDirectory)))
'@
        [System.IO.File]::WriteAllText($scriptPath, $childScript, $utf8)
        $argumentValues = @('hello world', '', 'quote"inside', 'tail slash with space\', '한글 인수')

        $r = Invoke-NativeProcess `
            -Executable 'powershell.exe' `
            -Arguments (@('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $scriptPath) + $argumentValues) `
            -WorkingDirectory $workingDirectory `
            -StandardInputBytes ([byte[]] @())

        $r.ExitCode | Should -Be 0
        $actualLines = @($r.Stdout.TrimEnd() -split '\r?\n')
        $expectedLines = @($argumentValues | ForEach-Object { [Convert]::ToBase64String($utf8.GetBytes($_)) }) + 'stdin=-1'
        $actualLines.Count | Should -Be $expectedLines.Count
        for ($i = 0; $i -lt $expectedLines.Count; $i++) {
            $actualLines[$i] | Should -Be $expectedLines[$i]
        }
        $r.Stderr.Trim() | Should -Be ([Convert]::ToBase64String($utf8.GetBytes([System.IO.Path]::GetFullPath($workingDirectory))))
    }

    It 'AC-NP-15: UTF-16 BOM on stdout cannot bypass strict UTF-8 validation (axis 12)' {
        $scriptPath = Join-Path $TestDrive 'np-invalid-utf8.ps1'
        $utf8 = New-Object System.Text.UTF8Encoding($false)
        $childScript = @'
$bytes = [byte[]] @(0xff, 0xfe, 0x41, 0x00)
$stream = [Console]::OpenStandardOutput()
$stream.Write($bytes, 0, $bytes.Length)
$stream.Flush()
'@
        [System.IO.File]::WriteAllText($scriptPath, $childScript, $utf8)

        {
            Invoke-NativeProcess `
                -Executable 'powershell.exe' `
                -Arguments @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $scriptPath) `
                -StandardInputBytes ([byte[]] @()) | Out-Null
        } | Should -Throw
    }

    It 'AC-NP-17: UTF-16 BOM on stderr cannot bypass strict UTF-8 validation (axis 14)' {
        $scriptPath = Join-Path $TestDrive 'np-invalid-stderr-utf8.ps1'
        $utf8 = New-Object System.Text.UTF8Encoding($false)
        $childScript = @'
$bytes = [byte[]] @(0xff, 0xfe, 0x41, 0x00)
$stream = [Console]::OpenStandardError()
$stream.Write($bytes, 0, $bytes.Length)
$stream.Flush()
'@
        [System.IO.File]::WriteAllText($scriptPath, $childScript, $utf8)

        {
            Invoke-NativeProcess `
                -Executable 'powershell.exe' `
                -Arguments @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $scriptPath) `
                -StandardInputBytes ([byte[]] @()) | Out-Null
        } | Should -Throw
    }

    It 'AC-NP-18: malformed UTF-8 without a BOM also fails closed (axis 15)' {
        $scriptPath = Join-Path $TestDrive 'np-malformed-utf8.ps1'
        $utf8 = New-Object System.Text.UTF8Encoding($false)
        $childScript = @'
$bytes = [byte[]] @(0x66, 0x6f, 0x80)
$stream = [Console]::OpenStandardOutput()
$stream.Write($bytes, 0, $bytes.Length)
$stream.Flush()
'@
        [System.IO.File]::WriteAllText($scriptPath, $childScript, $utf8)

        {
            Invoke-NativeProcess `
                -Executable 'powershell.exe' `
                -Arguments @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $scriptPath) `
                -StandardInputBytes ([byte[]] @()) | Out-Null
        } | Should -Throw
    }

    It 'AC-NP-19: stdin write failure terminates and joins the still-running child (axis 16)' {
        $scriptPath = Join-Path $TestDrive 'np-close-stdin-and-wait.ps1'
        $pidPath = Join-Path $TestDrive 'np-close-stdin.pid'
        $utf8 = New-Object System.Text.UTF8Encoding($false)
        $childScript = @'
param([string] $PidPath)
$utf8 = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($PidPath, [string] $PID, $utf8)
$source = @"
using System;
using System.Runtime.InteropServices;
public static class NativeStdinCloser {
    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern IntPtr GetStdHandle(int handle);
    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool CloseHandle(IntPtr handle);
    public static void Close() { CloseHandle(GetStdHandle(-10)); }
}
"@
Add-Type -TypeDefinition $source
[NativeStdinCloser]::Close()
Start-Sleep -Seconds 6
'@
        [System.IO.File]::WriteAllText($scriptPath, $childScript, $utf8)
        $largeInput = New-Object byte[] (4 * 1024 * 1024)

        $childPid = $null
        $outerPrev = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'
        try {
            {
                Invoke-NativeProcess `
                    -Executable 'powershell.exe' `
                    -Arguments @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $scriptPath, $pidPath) `
                    -StandardInputBytes $largeInput | Out-Null
            } | Should -Throw
            $ErrorActionPreference | Should -Be 'Stop'

            Test-Path -LiteralPath $pidPath | Should -BeTrue
            $childPid = [int] [System.IO.File]::ReadAllText($pidPath, $utf8)
            Get-Process -Id $childPid -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
        }
        finally {
            $ErrorActionPreference = $outerPrev
            if ($null -ne $childPid) {
                $leftover = Get-Process -Id $childPid -ErrorAction SilentlyContinue
                if ($null -ne $leftover) {
                    Stop-Process -Id $childPid -Force -ErrorAction SilentlyContinue
                    Wait-Process -Id $childPid -ErrorAction SilentlyContinue
                }
            }
        }
    }

    It 'AC-NP-16: byte-stdin path does not allocate legacy stdout or stderr temp files (axis 13)' {
        $cap = script:Invoke-NativeProcessWithVerbose -Params @{
            Executable         = 'powershell.exe'
            Arguments          = @('-NoProfile', '-Command', '[Console]::OpenStandardInput().ReadByte(); exit 0')
            StandardInputBytes = [byte[]] @()
        }
        $cap.Result.ExitCode | Should -Be 0
        $cap.TempOutPath | Should -BeNullOrEmpty
        $cap.TempErrPath | Should -BeNullOrEmpty
    }

    It 'AC-NP-20: byte-stdin path concurrently drains pipe-pressure stdout and stderr (axis 17)' {
        $scriptPath = Join-Path $TestDrive 'np-dual-pipe-pressure.ps1'
        $utf8 = New-Object System.Text.UTF8Encoding($false)
        $bytesPerStream = 1024 * 1024
        $childScript = @'
$ErrorActionPreference = 'Stop'
$source = @"
using System;
using System.IO;
using System.Threading;

public static class DualPipePressure
{
    private static void Fill(byte[] buffer, byte value)
    {
        for (int i = 0; i < buffer.Length; i++)
        {
            buffer[i] = value;
        }
    }

    private static void WriteRepeated(Stream stream, byte value, int totalBytes, ManualResetEvent startGate)
    {
        byte[] buffer = new byte[8192];
        Fill(buffer, value);
        startGate.WaitOne();
        int remaining = totalBytes;
        while (remaining > 0)
        {
            int count = Math.Min(buffer.Length, remaining);
            stream.Write(buffer, 0, count);
            remaining -= count;
        }
        stream.Flush();
    }

    public static void Run(int totalBytes, int timeoutMilliseconds)
    {
        if (totalBytes < 1048576)
        {
            throw new ArgumentOutOfRangeException("totalBytes");
        }

        ManualResetEvent startGate = new ManualResetEvent(false);
        ManualResetEvent completed = new ManualResetEvent(false);
        Exception stdoutError = null;
        Exception stderrError = null;

        Thread stdoutWriter = new Thread(new ThreadStart(delegate
        {
            try { WriteRepeated(Console.OpenStandardOutput(), (byte)'O', totalBytes, startGate); }
            catch (Exception ex) { stdoutError = ex; }
        }));
        Thread stderrWriter = new Thread(new ThreadStart(delegate
        {
            try { WriteRepeated(Console.OpenStandardError(), (byte)'E', totalBytes, startGate); }
            catch (Exception ex) { stderrError = ex; }
        }));
        Thread watchdog = new Thread(new ThreadStart(delegate
        {
            if (!completed.WaitOne(timeoutMilliseconds))
            {
                Environment.Exit(124);
            }
        }));
        stdoutWriter.IsBackground = false;
        stderrWriter.IsBackground = false;
        watchdog.IsBackground = false;

        try
        {
            watchdog.Start();
            stdoutWriter.Start();
            stderrWriter.Start();
            startGate.Set();
            stdoutWriter.Join();
            stderrWriter.Join();

            if (stdoutError != null) { throw new InvalidOperationException("stdout writer failed", stdoutError); }
            if (stderrError != null) { throw new InvalidOperationException("stderr writer failed", stderrError); }
        }
        finally
        {
            startGate.Set();
            completed.Set();
            if (stdoutWriter.IsAlive) { stdoutWriter.Join(); }
            if (stderrWriter.IsAlive) { stderrWriter.Join(); }
            if (watchdog.IsAlive) { watchdog.Join(); }
            startGate.Close();
            completed.Close();
        }
    }
}
"@
Add-Type -TypeDefinition $source
[DualPipePressure]::Run(1048576, 15000)
exit 37
'@
        [System.IO.File]::WriteAllText($scriptPath, $childScript, $utf8)

        $r = Invoke-NativeProcess `
            -Executable 'powershell.exe' `
            -Arguments @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $scriptPath) `
            -StandardInputBytes ([byte[]] @())

        $r.ExitCode | Should -Be 37 -Because 'exit 124 means the bounded pipe-pressure watchdog fired'
        $r.Stdout.Length | Should -Be $bytesPerStream
        $r.Stderr.Length | Should -Be $bytesPerStream
        ($r.Stdout.Trim([char[]] @('O')).Length) | Should -Be 0
        ($r.Stderr.Trim([char[]] @('E')).Length) | Should -Be 0
    }
}

Describe 'Invoke-NativeProcess: temp file cleanup' {
    It 'AC-NP-11: temp files are removed after a successful call (axis 9, normal path)' {
        $cap = script:Invoke-NativeProcessWithVerbose -Params @{
            Executable = 'powershell.exe'
            Arguments  = @('-NoProfile', '-Command', 'exit 0')
        }
        $cap.Result.ExitCode | Should -Be 0
        $cap.TempOutPath | Should -Not -BeNullOrEmpty
        $cap.TempErrPath | Should -Not -BeNullOrEmpty
        Test-Path -LiteralPath $cap.TempOutPath | Should -BeFalse
        Test-Path -LiteralPath $cap.TempErrPath | Should -BeFalse
    }

    It 'AC-NP-12: temp files are removed after an exception path through the helper (axis 9, exception path)' {
        $badDir = Join-Path $TestDrive ('np-nonexistent-' + [guid]::NewGuid().ToString('N'))
        (Test-Path -LiteralPath $badDir) | Should -BeFalse

        $verboseMessages = @()
        $threw = $false
        try {
            Invoke-NativeProcess -Executable 'powershell.exe' -Arguments @('-NoProfile') -WorkingDirectory $badDir -Verbose 4>&1 | ForEach-Object {
                if ($_ -is [System.Management.Automation.VerboseRecord]) {
                    $verboseMessages += $_.Message
                }
            }
        }
        catch {
            $threw = $true
        }
        $threw | Should -BeTrue

        $tempOutPath = $null
        $tempErrPath = $null
        foreach ($m in $verboseMessages) {
            if ($m -match '^Invoke-NativeProcess: tempOut=(.+)$') { $tempOutPath = $matches[1].Trim() }
            if ($m -match '^Invoke-NativeProcess: tempErr=(.+)$') { $tempErrPath = $matches[1].Trim() }
        }
        $tempOutPath | Should -Not -BeNullOrEmpty
        $tempErrPath | Should -Not -BeNullOrEmpty
        Test-Path -LiteralPath $tempOutPath | Should -BeFalse
        Test-Path -LiteralPath $tempErrPath | Should -BeFalse
    }
}
