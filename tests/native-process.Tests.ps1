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
