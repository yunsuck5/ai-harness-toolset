Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

BeforeAll {
    $script:RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).ProviderPath
    . (Join-Path $script:RepoRoot 'scripts/lib/native-process.ps1')
    $script:RealVerifyScript = Join-Path $script:RepoRoot 'scripts/verify-ps1.ps1'
    $script:RealLibPath      = Join-Path $script:RepoRoot 'scripts/lib/path.ps1'
    $script:RealLibGit       = Join-Path $script:RepoRoot 'scripts/lib/git.ps1'

    function script:Write-Utf8NoBomFile {
        param([string] $Path, [string] $Content)
        $parent = Split-Path -LiteralPath $Path
        if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
            $null = New-Item -ItemType Directory -Path $parent -Force
        }
        $resolved = [System.IO.Path]::GetFullPath($Path)
        $encoding = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($resolved, $Content, $encoding)
    }

    function script:New-VerifyCase {
        param([string] $CaseName)
        $caseRoot = Join-Path $TestDrive ('pester-verify-ps1-' + $CaseName)
        if (Test-Path -LiteralPath $caseRoot) {
            Remove-Item -LiteralPath $caseRoot -Recurse -Force
        }
        $null = New-Item -ItemType Directory -Path $caseRoot -Force
        return ([System.IO.Path]::GetFullPath($caseRoot))
    }

    function script:Initialize-FakeSourceRepoForVerify {
        param(
            [string] $CaseName,
            [switch] $OmitMarkers
        )
        $repo = script:New-VerifyCase -CaseName $CaseName

        # Copy the script under test plus its lib dependencies into <repo>/scripts/.
        $scriptsTarget = Join-Path $repo 'scripts'
        $null = New-Item -ItemType Directory -Path $scriptsTarget -Force
        $null = New-Item -ItemType Directory -Path (Join-Path $scriptsTarget 'lib') -Force

        Copy-Item -LiteralPath $script:RealVerifyScript -Destination (Join-Path $scriptsTarget 'verify-ps1.ps1') -Force
        Copy-Item -LiteralPath $script:RealLibPath      -Destination (Join-Path $scriptsTarget 'lib/path.ps1') -Force
        Copy-Item -LiteralPath $script:RealLibGit       -Destination (Join-Path $scriptsTarget 'lib/git.ps1') -Force

        if (-not $OmitMarkers) {
            # The other two dogfooding markers required by Test-IsSourceRepoRoot.
            script:Write-Utf8NoBomFile -Path (Join-Path $repo 'templates/review-input.md') -Content "# fake review-input`n"
            script:Write-Utf8NoBomFile -Path (Join-Path $repo 'config/reviewer.json')      -Content "{}`n"
        }

        # Initialize a git repo so `git ls-files` works. Invoke git through the
        # Invoke-NativeProcess containment shim (separate stdout/stderr capture)
        # rather than `& git ... 2>&1`: under Win PS 5.1 with file-level
        # $ErrorActionPreference = 'Stop' and system core.autocrlf=true, git's
        # stderr (e.g. the LF/CRLF auto-convert warning) crossing 2>&1 is promoted
        # to a terminating NativeCommandError that aborts setup before the exit
        # code can be read. The shim captures the streams separately, so failure
        # is driven off the child exit code instead.
        $initResult = Invoke-NativeProcess -Executable 'git' -Arguments @('-C', $repo, 'init', '--quiet')
        if ($initResult.ExitCode -ne 0) { throw ("git init failed (exit {0}): {1}" -f $initResult.ExitCode, $initResult.Stderr) }
        $emailResult = Invoke-NativeProcess -Executable 'git' -Arguments @('-C', $repo, 'config', 'user.email', 'pester@local')
        if ($emailResult.ExitCode -ne 0) { throw ("git config user.email failed (exit {0}): {1}" -f $emailResult.ExitCode, $emailResult.Stderr) }
        $nameResult = Invoke-NativeProcess -Executable 'git' -Arguments @('-C', $repo, 'config', 'user.name', 'pester')
        if ($nameResult.ExitCode -ne 0) { throw ("git config user.name failed (exit {0}): {1}" -f $nameResult.ExitCode, $nameResult.Stderr) }

        return $repo
    }

    function script:Add-TrackedLogFile {
        param(
            [string] $Repo,
            [string] $RelativePath,
            [string] $Content = "log artifact body`n"
        )
        $abs = Join-Path $Repo $RelativePath
        script:Write-Utf8NoBomFile -Path $abs -Content $Content
        # Stage via the Invoke-NativeProcess shim (see Initialize-FakeSourceRepoForVerify):
        # `git add` emits the core.autocrlf LF/CRLF warning on stderr, which under
        # `& git ... 2>&1` + EAP=Stop becomes a terminating NativeCommandError.
        $addResult = Invoke-NativeProcess -Executable 'git' -Arguments @('-C', $Repo, 'add', '--', $RelativePath)
        if ($addResult.ExitCode -ne 0) { throw ("git add failed (exit {0}): {1}" -f $addResult.ExitCode, $addResult.Stderr) }
    }

    function script:Add-TestsFixtureFile {
        # Writes a .ps1 under <Repo>/tests/ for the Step F lint test cases.
        # The file content is the literal $Body string; the caller composes the
        # exact pattern (forbidden / allowed / pragma) being exercised.
        param(
            [string] $Repo,
            [string] $RelativePath,
            [string] $Body
        )
        $abs = Join-Path $Repo $RelativePath
        script:Write-Utf8NoBomFile -Path $abs -Content $Body
    }

    function script:Invoke-VerifyPs1Copy {
        param([string] $Repo)
        $copyPath = Join-Path $Repo 'scripts/verify-ps1.ps1'
        $procArgs = @(
            '-NoProfile', '-ExecutionPolicy', 'Bypass',
            '-File', $copyPath
        )
        $proc = Invoke-NativeProcess -Executable 'powershell.exe' -Arguments $procArgs
        $exitCode = $proc.ExitCode
        $text = (($proc.Stdout + $proc.Stderr) -replace "`r`n", "`n").TrimEnd("`n")
        return [pscustomobject]@{
            ExitCode = $exitCode
            Output   = $text
        }
    }
}

Describe 'verify-ps1 D8 self-target enforcement' {
    It 'AC-VPS1-D8-CLEAN-SOURCE-PASS: source repo with no tracked log/ files passes' {
        $repo = script:Initialize-FakeSourceRepoForVerify -CaseName 'clean-source'

        $r = script:Invoke-VerifyPs1Copy -Repo $repo
        $r.ExitCode | Should -Be 0 -Because $r.Output
        $r.Output | Should -Match 'verify-ps1: PASS'
        $r.Output | Should -Not -Match 'D8 self-target enforcement'
    }

    It 'AC-VPS1-D8-TRACKED-LOG-FAIL: source repo with tracked log/ file fails and lists it' {
        $repo = script:Initialize-FakeSourceRepoForVerify -CaseName 'tracked-log'
        script:Add-TrackedLogFile -Repo $repo -RelativePath 'log/leaked.txt'

        $r = script:Invoke-VerifyPs1Copy -Repo $repo
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'FAIL D8 self-target enforcement'
        $r.Output | Should -Match 'git-tracked file\(s\) found under log/ in source repo'
        $r.Output | Should -Match 'log/leaked\.txt'
    }

    It 'AC-VPS1-D8-MULTIPLE-FAIL: multiple tracked log/ files are all listed' {
        $repo = script:Initialize-FakeSourceRepoForVerify -CaseName 'multiple-tracked'
        script:Add-TrackedLogFile -Repo $repo -RelativePath 'log/a.txt'
        script:Add-TrackedLogFile -Repo $repo -RelativePath 'log/sub/b.txt'

        $r = script:Invoke-VerifyPs1Copy -Repo $repo
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'FAIL D8 self-target enforcement'
        $r.Output | Should -Match 'log/a\.txt'
        $r.Output | Should -Match 'log/sub/b\.txt'
    }

    It 'AC-VPS1-D8-TARGET-SKIP: non-source/target context skips D8 even with tracked log/' {
        # Omit the templates/ and config/ markers so Test-IsSourceRepoRoot returns false.
        $repo = script:Initialize-FakeSourceRepoForVerify -CaseName 'target-skip' -OmitMarkers
        script:Add-TrackedLogFile -Repo $repo -RelativePath 'log/legit.txt'

        $r = script:Invoke-VerifyPs1Copy -Repo $repo
        $r.ExitCode | Should -Be 0 -Because $r.Output
        $r.Output | Should -Match 'verify-ps1: PASS'
        $r.Output | Should -Not -Match 'FAIL D8 self-target enforcement'
    }
}

Describe 'verify-ps1 Step F tests/** raw native stderr-capture lint' {
    It 'AC-VPS1-F-NO-TESTS-PASS: source repo without any tests/ directory passes the Step F lint' {
        # The lint must not fail when no tests/ directory exists; D8 path is separate.
        $repo = script:Initialize-FakeSourceRepoForVerify -CaseName 'f-no-tests'

        $r = script:Invoke-VerifyPs1Copy -Repo $repo
        $r.ExitCode | Should -Be 0 -Because $r.Output
        $r.Output | Should -Match 'verify-ps1: PASS'
        $r.Output | Should -Not -Match 'Step F'
    }

    It 'AC-VPS1-F-CLEAN-PASS: a tests/ directory whose .ps1 files use only allowed forms passes' {
        $repo = script:Initialize-FakeSourceRepoForVerify -CaseName 'f-clean'
        $clean = @(
            '# tests/clean.Tests.ps1 — only allowed forms',
            '$null = & git -C $repo init --quiet 2>&1',
            '& git add . 2>&1 | Out-Null',
            '& git status'                                       # no stderr-merge at all
        ) -join "`n"
        script:Add-TestsFixtureFile -Repo $repo -RelativePath 'tests/clean.Tests.ps1' -Body $clean

        $r = script:Invoke-VerifyPs1Copy -Repo $repo
        $r.ExitCode | Should -Be 0 -Because $r.Output
        $r.Output | Should -Match 'verify-ps1: PASS'
        $r.Output | Should -Not -Match 'FAIL Step F'
    }

    It 'AC-VPS1-F-CAPTURE-FAIL: $combined = & <exe> ... 2>&1 (captured for use) is a violation' {
        $repo = script:Initialize-FakeSourceRepoForVerify -CaseName 'f-capture-fail'
        $body = @(
            '# tests/forbidden.Tests.ps1',
            '$procArgs = @(''-NoProfile'',''-Command'',''exit 0'')',
            '$combined = & powershell.exe @procArgs 2>&1'        # verify-ps1-allow: lint-self-test-fixture (deliberate forbidden-pattern string written into the fake repo's tests/ tree to exercise AC-VPS1-F-CAPTURE-FAIL; not a real native invocation in this test file)
        ) -join "`n"
        script:Add-TestsFixtureFile -Repo $repo -RelativePath 'tests/forbidden.Tests.ps1' -Body $body

        $r = script:Invoke-VerifyPs1Copy -Repo $repo
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'FAIL Step F tests/\*\* raw native stderr-capture lint'
        $r.Output | Should -Match 'tests[\\/]forbidden\.Tests\.ps1:3:'
        $r.Output | Should -Match '\$combined = & powershell\.exe @procArgs 2>&1'   # verify-ps1-allow: lint-self-test-assertion (regex pattern asserting the FAIL output contains the forbidden snippet)
        $r.Output | Should -Match 'Invoke-NativeProcess'                # remediation hint present
    }

    It 'AC-VPS1-F-NULL-ASSIGN-PASS: $null = & <exe> ... 2>&1 (explicit discard) is allowed' {
        $repo = script:Initialize-FakeSourceRepoForVerify -CaseName 'f-null-assign'
        $body = @(
            '# only $null-discard captures',
            '$null = & git -C $repo init --quiet 2>&1',
            '$null = & powershell.exe -NoProfile -Command "exit 0" 2>&1'
        ) -join "`n"
        script:Add-TestsFixtureFile -Repo $repo -RelativePath 'tests/null-discard.Tests.ps1' -Body $body

        $r = script:Invoke-VerifyPs1Copy -Repo $repo
        $r.ExitCode | Should -Be 0 -Because $r.Output
        $r.Output | Should -Not -Match 'FAIL Step F'
    }

    It 'AC-VPS1-F-OUT-NULL-PIPE-PASS: ... 2>&1 | Out-Null (pipe to null) is allowed' {
        $repo = script:Initialize-FakeSourceRepoForVerify -CaseName 'f-out-null'
        $body = @(
            '# only Out-Null pipes',
            '& git add . 2>&1 | Out-Null',
            '& powershell.exe -NoProfile -Command "exit 0" 2>&1 | Out-Null'
        ) -join "`n"
        script:Add-TestsFixtureFile -Repo $repo -RelativePath 'tests/out-null.Tests.ps1' -Body $body

        $r = script:Invoke-VerifyPs1Copy -Repo $repo
        $r.ExitCode | Should -Be 0 -Because $r.Output
        $r.Output | Should -Not -Match 'FAIL Step F'
    }

    It 'AC-VPS1-F-PRAGMA-PASS: a forbidden line with a # verify-ps1-allow: pragma is exempted' {
        $repo = script:Initialize-FakeSourceRepoForVerify -CaseName 'f-pragma'
        $body = @(
            '# pragma-exempted capture site',
            '$combined = & powershell.exe @procArgs 2>&1   # verify-ps1-allow: documented-known-site' # verify-ps1-allow: lint-self-test-fixture (the actual source-line comment exempts this positive fixture; the fake repo receives the reason-bearing pragma inside the string)
        ) -join "`n"
        script:Add-TestsFixtureFile -Repo $repo -RelativePath 'tests/pragma-allowed.Tests.ps1' -Body $body

        $r = script:Invoke-VerifyPs1Copy -Repo $repo
        $r.ExitCode | Should -Be 0 -Because $r.Output
        $r.Output | Should -Not -Match 'FAIL Step F'
    }

    It 'AC-VPS1-F-PRAGMA-REASON-FAIL: bare or whitespace-only pragma does not exempt a capture' {
        $repo = script:Initialize-FakeSourceRepoForVerify -CaseName 'f-pragma-reason-required'
        $body = @(
            '# missing-reason pragma capture sites',
            '$bare = & powershell.exe @procArgs 2>&1   # verify-ps1-allow:'  # verify-ps1-allow: lint-self-test-fixture (bare pragma written into the fake repo to prove that a reason is required)
            '$spaces = & powershell.exe @procArgs 2>&1   # verify-ps1-allow:    '  # verify-ps1-allow: lint-self-test-fixture (whitespace-only pragma written into the fake repo to prove that a reason is required)
        ) -join "`n"
        script:Add-TestsFixtureFile -Repo $repo -RelativePath 'tests/pragma-missing-reason.Tests.ps1' -Body $body

        $r = script:Invoke-VerifyPs1Copy -Repo $repo
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'FAIL Step F'
        $r.Output | Should -Match 'tests[\\/]pragma-missing-reason\.Tests\.ps1:2:'
        $r.Output | Should -Match 'tests[\\/]pragma-missing-reason\.Tests\.ps1:3:'
    }

    It 'AC-VPS1-F-PRAGMA-STRING-LITERAL-FAIL: marker text inside command data does not exempt a capture' {
        $repo = script:Initialize-FakeSourceRepoForVerify -CaseName 'f-pragma-string-literal'
        $body = @(
            '# marker text inside a command argument is not a pragma',
            '$combined = & powershell.exe -Command ''Write-Output "# verify-ps1-allow: fake-reason"'' 2>&1' # verify-ps1-allow: lint-self-test-fixture (the actual source-line comment exempts this fixture authoring line; the fake repo receives only the string-internal marker)
        ) -join "`n"
        script:Add-TestsFixtureFile -Repo $repo -RelativePath 'tests/pragma-string-literal.Tests.ps1' -Body $body

        $r = script:Invoke-VerifyPs1Copy -Repo $repo
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'FAIL Step F'
        $r.Output | Should -Match 'tests[\\/]pragma-string-literal\.Tests\.ps1:2:'
    }

    It 'AC-VPS1-F-INLINE-CAPTURE-FAIL: ((& <exe> 2>&1) -join ...) inline capture is a violation' {
        # Covers the install-pipeline.Tests.ps1:684/709 shape — captured into an
        # expression rather than into a simple variable. The lint must catch this
        # too because it is the same merged-stream capture-for-use risk.
        $repo = script:Initialize-FakeSourceRepoForVerify -CaseName 'f-inline-capture'
        $body = @(
            '# inline capture into an expression',
            '$status = ((& git status --porcelain=v1 2>&1) -join "`n").Trim()'   # verify-ps1-allow: lint-self-test-fixture (deliberate inline-capture forbidden pattern written into the fake repo's tests/ tree to exercise AC-VPS1-F-INLINE-CAPTURE-FAIL)
        ) -join "`n"
        script:Add-TestsFixtureFile -Repo $repo -RelativePath 'tests/inline-capture.Tests.ps1' -Body $body

        $r = script:Invoke-VerifyPs1Copy -Repo $repo
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'FAIL Step F'
        $r.Output | Should -Match 'tests[\\/]inline-capture\.Tests\.ps1:2:'
    }

    It 'AC-VPS1-F-MULTIPLE-VIOLATIONS: multiple violating lines are all reported with their file:line' {
        $repo = script:Initialize-FakeSourceRepoForVerify -CaseName 'f-multi'
        $body = @(
            '# multiple violations',
            '$a = & git status 2>&1',                          # verify-ps1-allow: lint-self-test-fixture (deliberate forbidden line 1 for AC-VPS1-F-MULTIPLE-VIOLATIONS)
            '$b = & powershell.exe -NoProfile -Command "exit 0" 2>&1',   # verify-ps1-allow: lint-self-test-fixture (deliberate forbidden line 2 for AC-VPS1-F-MULTIPLE-VIOLATIONS)
            '$null = & git init 2>&1'                          # allowed
        ) -join "`n"
        script:Add-TestsFixtureFile -Repo $repo -RelativePath 'tests/multi.Tests.ps1' -Body $body

        $r = script:Invoke-VerifyPs1Copy -Repo $repo
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'FAIL Step F'
        $r.Output | Should -Match 'tests[\\/]multi\.Tests\.ps1:2:'
        $r.Output | Should -Match 'tests[\\/]multi\.Tests\.ps1:3:'
        $r.Output | Should -Not -Match 'tests[\\/]multi\.Tests\.ps1:4:'   # the $null = ... line is allowed
    }

    It 'AC-VPS1-F-COMMENT-ONLY-IGNORED: a comment-only line that quotes the forbidden pattern is not flagged' {
        $repo = script:Initialize-FakeSourceRepoForVerify -CaseName 'f-comment'
        $body = @(
            '# This comment shows the forbidden pattern: & git status 2>&1',   # verify-ps1-allow: lint-self-test-fixture (deliberate comment-only fixture line for AC-VPS1-F-COMMENT-ONLY-IGNORED)
            '# The lint must skip comment-only lines.'
        ) -join "`n"
        script:Add-TestsFixtureFile -Repo $repo -RelativePath 'tests/comment-only.Tests.ps1' -Body $body

        $r = script:Invoke-VerifyPs1Copy -Repo $repo
        $r.ExitCode | Should -Be 0 -Because $r.Output
        $r.Output | Should -Not -Match 'FAIL Step F'
    }

    It 'AC-VPS1-F-TARGET-SKIP: a non-source/target context with a violating tests/ file is NOT linted' {
        # Same gate as D8: outside the source repo context, the lint must not fire.
        $repo = script:Initialize-FakeSourceRepoForVerify -CaseName 'f-target-skip' -OmitMarkers
        $body = @(
            '# this would be a violation in source-repo context',
            '$combined = & powershell.exe -NoProfile -Command "exit 0" 2>&1'   # verify-ps1-allow: lint-self-test-fixture (deliberate forbidden pattern for AC-VPS1-F-TARGET-SKIP; the test verifies the lint does NOT fire in non-source contexts)
        ) -join "`n"
        script:Add-TestsFixtureFile -Repo $repo -RelativePath 'tests/target-skip.Tests.ps1' -Body $body

        $r = script:Invoke-VerifyPs1Copy -Repo $repo
        $r.ExitCode | Should -Be 0 -Because $r.Output
        $r.Output | Should -Match 'verify-ps1: PASS'
        $r.Output | Should -Not -Match 'FAIL Step F'
    }

    It 'AC-VPS1-F-VARIABLE-EXE-IGNORED: `& $exe ... 2>&1` (variable executable) is not flagged' {
        # The migrated-away pattern was `& <literal-identifier>`. Invocations via
        # a variable (& $exe) or scriptblock (& { ... }) are not the targeted shape.
        # This documents the conservative matcher.
        $repo = script:Initialize-FakeSourceRepoForVerify -CaseName 'f-var-exe'
        $body = @(
            '$exe = ''powershell.exe''',
            '$combined = & $exe -NoProfile -Command "exit 0" 2>&1'
        ) -join "`n"
        script:Add-TestsFixtureFile -Repo $repo -RelativePath 'tests/variable-exe.Tests.ps1' -Body $body

        $r = script:Invoke-VerifyPs1Copy -Repo $repo
        $r.ExitCode | Should -Be 0 -Because $r.Output
        $r.Output | Should -Not -Match 'FAIL Step F'
    }
}
