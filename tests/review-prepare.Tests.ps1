Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

BeforeAll {
    $script:RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).ProviderPath
    $script:ReviewPrepareScript = Join-Path $script:RepoRoot 'scripts/review-prepare.ps1'

    function script:New-PrepareCaseRoot {
        param([string] $CaseName)
        $caseRoot = Join-Path $TestDrive ('pester-review-prepare-' + $CaseName)
        if (Test-Path -LiteralPath $caseRoot) {
            Remove-Item -LiteralPath $caseRoot -Recurse -Force
        }
        $null = New-Item -ItemType Directory -Path $caseRoot -Force
        return ([System.IO.Path]::GetFullPath($caseRoot))
    }

    function script:Invoke-ReviewPrepare {
        param(
            [string] $ProjectRoot,
            [string] $ReviewTaskId,
            [string] $Pass,
            [string] $Stage = 'implementation',
            [string] $Purpose = 'pester prepare',
            [string[]] $ExtraArgs
        )
        $procArgs = @(
            '-NoProfile',
            '-ExecutionPolicy', 'Bypass',
            '-File', $script:ReviewPrepareScript,
            '-Stage', $Stage,
            '-Purpose', $Purpose,
            '-ProjectRoot', $ProjectRoot,
            '-ToolRoot', $script:RepoRoot,
            '-ReviewTaskId', $ReviewTaskId
        )
        if (-not [string]::IsNullOrEmpty($Pass)) {
            $procArgs += @('-Pass', $Pass)
        }
        if ($null -ne $ExtraArgs -and $ExtraArgs.Count -gt 0) {
            $procArgs += $ExtraArgs
        }
        # The child powershell.exe may emit on stderr — notably the parameter
        # binder error path that AC-PR7 exercises by passing legacy
        # -TargetFilesPath / -ReviewRequestPath. Under Windows PowerShell 5.1,
        # each native stderr line crossing `2>&1` is wrapped as a
        # NativeCommandError ErrorRecord; the file-level
        # $ErrorActionPreference = 'Stop' would otherwise abort this helper
        # before $LASTEXITCODE could be read. Pin EAP to Continue for the
        # duration of the child capture (mirrors the prior-art pattern in
        # tests/install-pipeline.Tests.ps1 and the in-script
        # Invoke-InstallPipelineNativeGit helper in
        # scripts/lib/install-pipeline-core.ps1).
        $prevPref = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        try {
            $combined = & powershell.exe @procArgs 2>&1   # verify-ps1-allow: step-1-eap-continue-mitigated (intentional pre-Invoke-NativeProcess Step 1 pattern; synthesis report §10 excluded this site from Step D Invoke-NativeProcess migration)
            $exitCode = $LASTEXITCODE
        }
        finally {
            $ErrorActionPreference = $prevPref
        }
        $text = ($combined | ForEach-Object { [string]$_ }) -join "`n"
        return [pscustomobject]@{
            ExitCode = $exitCode
            Output   = $text
        }
    }
}

Describe 'review-prepare canonical layout' {
    It 'AC-PR1: explicit -Pass pass-01 creates canonical pass directory and seeds input.md from template' {
        $project = script:New-PrepareCaseRoot -CaseName 'pr1'
        $taskId  = 'topology-simplification-2026-05-16'

        $r = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01'
        $r.ExitCode | Should -Be 0 -Because $r.Output
        $r.Output | Should -Match 'review-prepare: PASS'
        $r.Output | Should -Match ('review-task-id: ' + [regex]::Escape($taskId))
        $r.Output | Should -Match 'pass: pass-01'

        $passDir = Join-Path $project ('log/review/' + $taskId + '/pass-01')
        Test-Path -LiteralPath $passDir -PathType Container | Should -BeTrue

        $inputPath = Join-Path $passDir 'input.md'
        Test-Path -LiteralPath $inputPath -PathType Leaf | Should -BeTrue

        $enc = New-Object System.Text.UTF8Encoding($false)
        $body = [System.IO.File]::ReadAllText($inputPath, $enc)
        # Body comes from templates/review-input.md
        $templatePath = Join-Path $script:RepoRoot 'templates/review-input.md'
        $expected = [System.IO.File]::ReadAllText($templatePath, $enc)
        $body | Should -Be $expected
    }

    It 'AC-PR2: pass auto-allocation picks pass-01 first, then pass-02 on the next call' {
        $project = script:New-PrepareCaseRoot -CaseName 'pr2'
        $taskId  = 'pass-allocation-task'

        $first = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId
        $first.ExitCode | Should -Be 0 -Because $first.Output
        $first.Output | Should -Match 'pass: pass-01'

        $second = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId
        $second.ExitCode | Should -Be 0 -Because $second.Output
        $second.Output | Should -Match 'pass: pass-02'

        Test-Path -LiteralPath (Join-Path $project ('log/review/' + $taskId + '/pass-01/input.md')) -PathType Leaf | Should -BeTrue
        Test-Path -LiteralPath (Join-Path $project ('log/review/' + $taskId + '/pass-02/input.md')) -PathType Leaf | Should -BeTrue
    }

    It 'AC-PR3: pass-NN write-once — re-running with the same -Pass fails and preserves prior pass body' {
        $project = script:New-PrepareCaseRoot -CaseName 'pr3'
        $taskId  = 'write-once-task'

        $first = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01'
        $first.ExitCode | Should -Be 0 -Because $first.Output

        $inputPath = Join-Path $project ('log/review/' + $taskId + '/pass-01/input.md')
        $enc = New-Object System.Text.UTF8Encoding($false)

        # Operator hand-edits input.md after seeding (this is the normal authoring step).
        [System.IO.File]::WriteAllText($inputPath, "edited body`n", $enc)
        $beforeRetry = [System.IO.File]::ReadAllText($inputPath, $enc)

        $second = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01'
        $second.ExitCode | Should -Not -Be 0
        $second.Output | Should -Match 'pass directory already exists'
        $second.Output | Should -Match 'write-once'

        $afterRetry = [System.IO.File]::ReadAllText($inputPath, $enc)
        $afterRetry | Should -Be $beforeRetry
    }

    It 'AC-PR4: review-task-id is operator-supplied (not auto-derived from a session id)' {
        # The script must require -ReviewTaskId explicitly. There is no fallback
        # that derives the id from a Claude Code chat / session id, environment
        # variable, or git state. Omitting -ReviewTaskId fails before any
        # filesystem mutation.
        $project = script:New-PrepareCaseRoot -CaseName 'pr4'
        $procArgs = @(
            '-NoProfile', '-ExecutionPolicy', 'Bypass',
            '-File', $script:ReviewPrepareScript,
            '-Stage', 'implementation',
            '-Purpose', 'no taskid',
            '-ProjectRoot', $project,
            '-ToolRoot', $script:RepoRoot
        )
        # Pin EAP=Continue around the native call so a stderr line from the
        # child does not abort this It block before $LASTEXITCODE is captured.
        # Same rationale as Invoke-ReviewPrepare above.
        $prevPref = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        try {
            $combined = & powershell.exe @procArgs 2>&1   # verify-ps1-allow: step-1-eap-continue-mitigated (intentional pre-Invoke-NativeProcess Step 1 pattern; synthesis report §10 excluded this site from Step D Invoke-NativeProcess migration)
            $exitCode = $LASTEXITCODE
        }
        finally {
            $ErrorActionPreference = $prevPref
        }
        $text = ($combined | ForEach-Object { [string]$_ }) -join "`n"
        $exitCode | Should -Not -Be 0 -Because $text
        # No log/review subtree created.
        Test-Path -LiteralPath (Join-Path $project 'log/review') -PathType Container | Should -BeFalse
    }

    It 'AC-PR5: invalid -Pass value (not pass-NN shape) is rejected before any directory is created' {
        $project = script:New-PrepareCaseRoot -CaseName 'pr5'
        $taskId  = 'invalid-pass-task'

        $r = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-1'
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'invalid Pass'

        Test-Path -LiteralPath (Join-Path $project ('log/review/' + $taskId)) -PathType Container | Should -BeFalse
    }

    It 'AC-PR6: invalid -ReviewTaskId (path traversal) is rejected' {
        $project = script:New-PrepareCaseRoot -CaseName 'pr6'
        $r = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId '../escape' -Pass 'pass-01'
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'invalid ReviewTaskId'
    }

    It 'AC-PR7: legacy -TargetFilesPath / -ReviewRequestPath parameters are not accepted' {
        # The canonical operator path does not stage target files or review
        # requests via external sidecar files. The script must not accept these
        # legacy parameter names.
        $project = script:New-PrepareCaseRoot -CaseName 'pr7'
        $taskId  = 'no-legacy-task'

        $sidecar = Join-Path $project 'log/staging/foo.list'
        $parent = Split-Path -LiteralPath $sidecar
        $null = New-Item -ItemType Directory -Path $parent -Force
        $enc = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($sidecar, "x.txt`n", $enc)

        $r1 = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01' -ExtraArgs @('-TargetFilesPath', $sidecar)
        $r1.ExitCode | Should -Not -Be 0

        $r2 = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-02' -ExtraArgs @('-ReviewRequestPath', $sidecar)
        $r2.ExitCode | Should -Not -Be 0
    }

    It 'AC-PR8: only canonical artifact (input.md) is written — no meta.json / target-files.list / result.json sidecars' {
        $project = script:New-PrepareCaseRoot -CaseName 'pr8'
        $taskId  = 'no-sidecar-task'

        $r = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01'
        $r.ExitCode | Should -Be 0 -Because $r.Output

        $passDir = Join-Path $project ('log/review/' + $taskId + '/pass-01')
        Test-Path -LiteralPath (Join-Path $passDir 'input.md')          -PathType Leaf | Should -BeTrue
        Test-Path -LiteralPath (Join-Path $passDir 'meta.json')         -PathType Leaf | Should -BeFalse
        Test-Path -LiteralPath (Join-Path $passDir 'target-files.list') -PathType Leaf | Should -BeFalse
        Test-Path -LiteralPath (Join-Path $passDir 'result.json')       -PathType Leaf | Should -BeFalse
        Test-Path -LiteralPath (Join-Path $passDir 'result.md')         -PathType Leaf | Should -BeFalse

        # No legacy staging trees are created in log/.
        Test-Path -LiteralPath (Join-Path $project 'log/review-targets')  -PathType Container | Should -BeFalse
        Test-Path -LiteralPath (Join-Path $project 'log/review-requests') -PathType Container | Should -BeFalse
    }

    It 'AC-PR9: pass directories for different ReviewTaskIds are isolated' {
        $project = script:New-PrepareCaseRoot -CaseName 'pr9'

        $a = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId 'task-alpha' -Pass 'pass-01'
        $a.ExitCode | Should -Be 0 -Because $a.Output
        $b = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId 'task-beta' -Pass 'pass-01'
        $b.ExitCode | Should -Be 0 -Because $b.Output

        Test-Path -LiteralPath (Join-Path $project 'log/review/task-alpha/pass-01/input.md') -PathType Leaf | Should -BeTrue
        Test-Path -LiteralPath (Join-Path $project 'log/review/task-beta/pass-01/input.md')  -PathType Leaf | Should -BeTrue
    }
}

Describe 'review-prepare perspective (C1 three-level) layout' {
    It 'AC-PR-PERSP1: -Perspective local-correctness creates the three-level pass dir and reports the perspective' {
        $project = script:New-PrepareCaseRoot -CaseName 'pr-persp1'
        $taskId  = 'persp-task'

        $r = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01' -ExtraArgs @('-Perspective', 'local-correctness')
        $r.ExitCode | Should -Be 0 -Because $r.Output
        $r.Output | Should -Match 'review-prepare: PASS'
        $r.Output | Should -Match 'perspective: local-correctness'
        $r.Output | Should -Match 'pass-dir: log/review/persp-task/local-correctness/pass-01'

        Test-Path -LiteralPath (Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-01/input.md')) -PathType Leaf | Should -BeTrue
        # The old two-level pass dir is NOT created when a perspective is given.
        Test-Path -LiteralPath (Join-Path $project ('log/review/' + $taskId + '/pass-01')) -PathType Container | Should -BeFalse
    }

    It 'AC-PR-PERSP2: -Perspective system-coherence creates its own perspective subtree' {
        $project = script:New-PrepareCaseRoot -CaseName 'pr-persp2'
        $taskId  = 'persp-task'

        $r = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01' -ExtraArgs @('-Perspective', 'system-coherence')
        $r.ExitCode | Should -Be 0 -Because $r.Output
        $r.Output | Should -Match 'perspective: system-coherence'
        Test-Path -LiteralPath (Join-Path $project ('log/review/' + $taskId + '/system-coherence/pass-01/input.md')) -PathType Leaf | Should -BeTrue
    }

    It 'AC-PR-PERSP3: pass-NN auto-allocation is per-perspective (corrective attempt within a perspective)' {
        $project = script:New-PrepareCaseRoot -CaseName 'pr-persp3'
        $taskId  = 'persp-task'

        $first = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -ExtraArgs @('-Perspective', 'local-correctness')
        $first.ExitCode | Should -Be 0 -Because $first.Output
        $first.Output | Should -Match 'pass: pass-01'

        $second = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -ExtraArgs @('-Perspective', 'local-correctness')
        $second.ExitCode | Should -Be 0 -Because $second.Output
        $second.Output | Should -Match 'pass: pass-02'

        Test-Path -LiteralPath (Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-01/input.md')) -PathType Leaf | Should -BeTrue
        Test-Path -LiteralPath (Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-02/input.md')) -PathType Leaf | Should -BeTrue
    }

    It 'AC-PR-PERSP4: a second perspective starts its own pass-01 sequence (perspectives are independent)' {
        $project = script:New-PrepareCaseRoot -CaseName 'pr-persp4'
        $taskId  = 'persp-task'

        # Two passes on local-correctness, then one on system-coherence: the second perspective
        # must start at pass-01, not continue local-correctness's numbering.
        $null = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -ExtraArgs @('-Perspective', 'local-correctness')
        $null = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -ExtraArgs @('-Perspective', 'local-correctness')

        $sc = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -ExtraArgs @('-Perspective', 'system-coherence')
        $sc.ExitCode | Should -Be 0 -Because $sc.Output
        $sc.Output | Should -Match 'pass: pass-01'
        Test-Path -LiteralPath (Join-Path $project ('log/review/' + $taskId + '/system-coherence/pass-01/input.md')) -PathType Leaf | Should -BeTrue
    }

    It 'AC-PR-PERSP5: old two-level and new three-level layouts coexist under the same task' {
        $project = script:New-PrepareCaseRoot -CaseName 'pr-persp5'
        $taskId  = 'coexist-task'

        $old = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01'
        $old.ExitCode | Should -Be 0 -Because $old.Output
        $new = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01' -ExtraArgs @('-Perspective', 'local-correctness')
        $new.ExitCode | Should -Be 0 -Because $new.Output

        # Both records exist side by side; no migration, no collision.
        Test-Path -LiteralPath (Join-Path $project ('log/review/' + $taskId + '/pass-01/input.md')) -PathType Leaf | Should -BeTrue
        Test-Path -LiteralPath (Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-01/input.md')) -PathType Leaf | Should -BeTrue
    }

    It 'AC-PR-PERSP6: invalid perspective values are rejected before any directory is created' {
        $project = script:New-PrepareCaseRoot -CaseName 'pr-persp6'
        $taskId  = 'persp-task'

        # empty, traversal, separators, pass-NN shape, over-length, invalid char.
        $bad = @('..', 'foo/bar', 'foo\bar', 'pass-01', ('a' * 65), 'foo bar')
        foreach ($p in $bad) {
            $r = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01' -ExtraArgs @('-Perspective', $p)
            $r.ExitCode | Should -Not -Be 0 -Because ("perspective '" + $p + "' must be rejected: " + $r.Output)
            $r.Output   | Should -Match 'invalid Perspective'
        }
        # No task subtree was created by any rejected attempt.
        Test-Path -LiteralPath (Join-Path $project ('log/review/' + $taskId)) -PathType Container | Should -BeFalse
    }
}
