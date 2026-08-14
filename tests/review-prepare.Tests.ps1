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
            # Strict C1: -Perspective is required, so the helper injects a default
            # ('local-correctness') for tests that do not care about the viewpoint, unless the
            # caller already supplies one via -ExtraArgs or asks to omit it with -OmitPerspective.
            [string] $Perspective = 'local-correctness',
            [switch] $OmitPerspective,
            [switch] $ContinueCampaign,
            [string] $PrepareScriptPath = $script:ReviewPrepareScript,
            [string[]] $ExtraArgs
        )
        $procArgs = @(
            '-NoProfile',
            '-ExecutionPolicy', 'Bypass',
            '-File', $PrepareScriptPath,
            '-Stage', $Stage,
            '-Purpose', $Purpose,
            '-ProjectRoot', $ProjectRoot,
            '-ToolRoot', $script:RepoRoot,
            '-ReviewTaskId', $ReviewTaskId
        )
        if (-not [string]::IsNullOrEmpty($Pass)) {
            $procArgs += @('-Pass', $Pass)
        }
        if ($ContinueCampaign) {
            $procArgs += '-ContinueCampaign'
        }
        $extraHasPerspective = ($null -ne $ExtraArgs) -and ($ExtraArgs -contains '-Perspective')
        if ((-not $OmitPerspective) -and (-not $extraHasPerspective)) {
            $procArgs += @('-Perspective', $Perspective)
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
            $combined = & powershell.exe @procArgs 2>&1   # verify-ps1-allow: test-only-combined-child-output (EAP=Continue 아래 stdout/stderr를 assertion 진단용으로 결합하고 exit code를 별도 보존하며 structured-capture contract를 주장하지 않음)
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
    It 'AC-PR1: explicit -Pass pass-01 creates a canonical pass directory with empty input.md' {
        $project = script:New-PrepareCaseRoot -CaseName 'pr1'
        $taskId  = 'topology-simplification-2026-05-16'

        $r = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01'
        $r.ExitCode | Should -Be 0 -Because $r.Output
        $r.Output | Should -Match 'review-prepare: PASS'
        $r.Output | Should -Match ('review-task-id: ' + [regex]::Escape($taskId))
        $r.Output | Should -Match 'pass: pass-01'
        $r.Output | Should -Match 'perspective: local-correctness'

        $passDir = Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-01')
        Test-Path -LiteralPath $passDir -PathType Container | Should -BeTrue

        $inputPath = Join-Path $passDir 'input.md'
        Test-Path -LiteralPath $inputPath -PathType Leaf | Should -BeTrue

        $enc = New-Object System.Text.UTF8Encoding($false)
        $body = [System.IO.File]::ReadAllText($inputPath, $enc)
        # Default behavior is the only behavior: an empty canvas authored by the operator.
        $body | Should -Be ''
    }

    It 'AC-PR2: pass auto-allocation picks pass-01 first, then pass-02 on the next call' {
        $project = script:New-PrepareCaseRoot -CaseName 'pr2'
        $taskId  = 'pass-allocation-task'

        $first = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId
        $first.ExitCode | Should -Be 0 -Because $first.Output
        $first.Output | Should -Match 'pass: pass-01'

        $second = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -ContinueCampaign
        $second.ExitCode | Should -Be 0 -Because $second.Output
        $second.Output | Should -Match 'pass: pass-02'

        Test-Path -LiteralPath (Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-01/input.md')) -PathType Leaf | Should -BeTrue
        Test-Path -LiteralPath (Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-02/input.md')) -PathType Leaf | Should -BeTrue
    }

    It 'AC-PR3: pass-NN write-once — re-running with the same -Pass fails and preserves prior pass body' {
        $project = script:New-PrepareCaseRoot -CaseName 'pr3'
        $taskId  = 'write-once-task'

        $first = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01'
        $first.ExitCode | Should -Be 0 -Because $first.Output

        $inputPath = Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-01/input.md')
        $enc = New-Object System.Text.UTF8Encoding($false)

        # Operator authors input.md after allocation (this is the normal authoring step).
        [System.IO.File]::WriteAllText($inputPath, "edited body`n", $enc)
        $beforeRetry = [System.IO.File]::ReadAllText($inputPath, $enc)

        $second = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01' -ContinueCampaign
        $second.ExitCode | Should -Not -Be 0
        $second.Output | Should -Match 'directory claim conflict'
        $second.Output | Should -Match 'not retried automatically'

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
            $combined = & powershell.exe @procArgs 2>&1   # verify-ps1-allow: test-only-combined-child-output (EAP=Continue 아래 stdout/stderr를 assertion 진단용으로 결합하고 exit code를 별도 보존하며 structured-capture contract를 주장하지 않음)
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

        $passDir = Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-01')
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

        Test-Path -LiteralPath (Join-Path $project 'log/review/task-alpha/local-correctness/pass-01/input.md') -PathType Leaf | Should -BeTrue
        Test-Path -LiteralPath (Join-Path $project 'log/review/task-beta/local-correctness/pass-01/input.md')  -PathType Leaf | Should -BeTrue
    }

    It 'AC-PR10: prepare without -Perspective fails fast (strict C1 — required) before any directory is created' {
        $project = script:New-PrepareCaseRoot -CaseName 'pr10'
        $taskId  = 'no-perspective-task'

        $r = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01' -OmitPerspective
        $r.ExitCode | Should -Not -Be 0 -Because $r.Output
        $r.Output | Should -Match '-Perspective is required'

        # No task subtree created.
        Test-Path -LiteralPath (Join-Path $project ('log/review/' + $taskId)) -PathType Container | Should -BeFalse
    }

    It 'AC-PR11: legacy -NoSeed is rejected and creates no pass directory' {
        $project = script:New-PrepareCaseRoot -CaseName 'pr11'
        $taskId  = 'no-seed-task'

        $r = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01' -ExtraArgs @('-NoSeed')
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'NoSeed'

        $passDir = Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-01')
        Test-Path -LiteralPath $passDir -PathType Container | Should -BeFalse
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
        # Strict C1: no stray two-level pass dir is ever created directly under the task dir.
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

        $second = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -ExtraArgs @('-Perspective', 'local-correctness') -ContinueCampaign
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
        $null = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -ExtraArgs @('-Perspective', 'local-correctness') -ContinueCampaign

        $sc = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -ExtraArgs @('-Perspective', 'system-coherence') -ContinueCampaign
        $sc.ExitCode | Should -Be 0 -Because $sc.Output
        $sc.Output | Should -Match 'pass: pass-01'
        Test-Path -LiteralPath (Join-Path $project ('log/review/' + $taskId + '/system-coherence/pass-01/input.md')) -PathType Leaf | Should -BeTrue
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

Describe 'review-prepare campaign identity and atomic allocation' {
    It 'AC-PR-CAM1: 같은 key의 두 번째 기본 호출은 new campaign collision으로 실패하고 pass를 추가하지 않는다' {
        $project = script:New-PrepareCaseRoot -CaseName 'campaign-new-collision'
        $taskId = 'campaign-new-collision'

        $first = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId
        $first.ExitCode | Should -Be 0 -Because $first.Output

        $second = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId
        $second.ExitCode | Should -Not -Be 0
        $second.Output | Should -Match 'new campaign claim was not acquired'
        Test-Path -LiteralPath (Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-02')) | Should -BeFalse
    }

    It 'AC-PR-CAM2: task-root-only legacy는 continuation anchor가 아니므로 거부된다' {
        $project = script:New-PrepareCaseRoot -CaseName 'campaign-legacy-root-only'
        $taskId = 'campaign-legacy-root-only'
        $taskDir = Join-Path $project ('log/review/' + $taskId)
        $null = [System.IO.Directory]::CreateDirectory($taskDir)

        $continued = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -ContinueCampaign
        $continued.ExitCode | Should -Not -Be 0
        $continued.Output | Should -Match 'requires an existing anchored campaign'
        Test-Path -LiteralPath (Join-Path $taskDir 'local-correctness') | Should -BeFalse
    }

    It 'AC-PR-CAM3: canonical input anchor가 있는 legacy는 explicit continuation으로 pass-02를 받는다' {
        $project = script:New-PrepareCaseRoot -CaseName 'campaign-legacy-anchored'
        $taskId = 'campaign-legacy-anchored'
        $pass01 = Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-01')
        $null = [System.IO.Directory]::CreateDirectory($pass01)
        $input01 = Join-Path $pass01 'input.md'
        [System.IO.File]::WriteAllText($input01, '', (New-Object System.Text.UTF8Encoding($false)))

        $continued = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -ContinueCampaign
        $continued.ExitCode | Should -Be 0 -Because $continued.Output
        $continued.Output | Should -Match '(?m)^pass: pass-02$'

        $pass02 = Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-02')
        @((Get-ChildItem -LiteralPath $pass02 -File)).Count | Should -Be 1
        (Get-ChildItem -LiteralPath $pass02 -File).Name | Should -Be 'input.md'
    }

    It 'AC-PR-CAM4: anchored campaign의 orphan pass는 auto 번호로 소비되고 explicit 재사용은 거부된다' {
        $project = script:New-PrepareCaseRoot -CaseName 'campaign-orphan'
        $taskId = 'campaign-orphan'
        $first = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId
        $first.ExitCode | Should -Be 0 -Because $first.Output

        $orphan = Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-02')
        $null = [System.IO.Directory]::CreateDirectory($orphan)

        $auto = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -ContinueCampaign
        $auto.ExitCode | Should -Be 0 -Because $auto.Output
        $auto.Output | Should -Match '(?m)^pass: pass-03$'

        $explicit = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-02' -ContinueCampaign
        $explicit.ExitCode | Should -Not -Be 0
        $explicit.Output | Should -Match 'directory claim conflict'
        Test-Path -LiteralPath (Join-Path $orphan 'input.md') -PathType Leaf | Should -BeFalse
    }

    It 'AC-PR-CAM5: pass-98 다음은 pass-99이고 그 뒤에는 exhaustion으로 멈추며 pass-100을 만들지 않는다' {
        $project = script:New-PrepareCaseRoot -CaseName 'campaign-pass99'
        $taskId = 'campaign-pass99'

        $pass98 = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-98'
        $pass98.ExitCode | Should -Be 0 -Because $pass98.Output

        $pass99 = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -ContinueCampaign
        $pass99.ExitCode | Should -Be 0 -Because $pass99.Output
        $pass99.Output | Should -Match '(?m)^pass: pass-99$'

        $exhausted = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -ContinueCampaign
        $exhausted.ExitCode | Should -Not -Be 0
        $exhausted.Output | Should -Match 'range exhausted \(max 99\)'
        $exhausted.Output | Should -Match 'exhausted selected perspective'
        $exhausted.Output | Should -Match 'do not allocate a lower pass or another ReviewTaskId automatically'
        Test-Path -LiteralPath (Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-100')) | Should -BeFalse

        $lowerExplicit = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-97' -ContinueCampaign
        $lowerExplicit.ExitCode | Should -Not -Be 0
        $lowerExplicit.Output | Should -Match 'range exhausted \(max 99\)'
        Test-Path -LiteralPath (Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-97')) | Should -BeFalse
    }

    It 'AC-PR-CAM6: 같은 explicit pass를 두 child process가 요청하면 정확히 하나만 성공한다' {
        $project = script:New-PrepareCaseRoot -CaseName 'campaign-explicit-race'
        $taskId = 'campaign-explicit-race'
        $first = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01'
        $first.ExitCode | Should -Be 0 -Because $first.Output

        $wrapperPath = Join-Path $project 'explicit-race-child.ps1'
        $wrapperTemplate = @'
& '__PREPARE__' `
    -ReviewTaskId '__TASK__' `
    -ContinueCampaign `
    -Pass 'pass-02' `
    -Perspective 'local-correctness' `
    -Stage 'implementation' `
    -Purpose 'explicit-race' `
    -ProjectRoot '__PROJECT__' `
    -ToolRoot '__TOOL__'
exit $LASTEXITCODE
'@
        $wrapperBody = $wrapperTemplate.Replace('__PREPARE__', $script:ReviewPrepareScript.Replace("'", "''"))
        $wrapperBody = $wrapperBody.Replace('__TASK__', $taskId.Replace("'", "''"))
        $wrapperBody = $wrapperBody.Replace('__PROJECT__', $project.Replace("'", "''"))
        $wrapperBody = $wrapperBody.Replace('__TOOL__', $script:RepoRoot.Replace("'", "''"))
        [System.IO.File]::WriteAllText($wrapperPath, $wrapperBody, (New-Object System.Text.UTF8Encoding($false)))

        $stdout1 = Join-Path $project 'explicit-race-1.stdout.txt'
        $stderr1 = Join-Path $project 'explicit-race-1.stderr.txt'
        $stdout2 = Join-Path $project 'explicit-race-2.stdout.txt'
        $stderr2 = Join-Path $project 'explicit-race-2.stderr.txt'
        $arguments = @(
            '-NoProfile',
            '-ExecutionPolicy', 'Bypass',
            '-File', ('"{0}"' -f $wrapperPath)
        )

        $child1 = Start-Process -FilePath 'powershell.exe' -ArgumentList $arguments -RedirectStandardOutput $stdout1 -RedirectStandardError $stderr1 -PassThru -WindowStyle Hidden
        [void] $child1.Handle
        $child2 = Start-Process -FilePath 'powershell.exe' -ArgumentList $arguments -RedirectStandardOutput $stdout2 -RedirectStandardError $stderr2 -PassThru -WindowStyle Hidden
        [void] $child2.Handle
        $exitCodes = @()
        try {
            $child1.WaitForExit(10000) | Should -BeTrue
            $child2.WaitForExit(10000) | Should -BeTrue
            $child1.Refresh()
            $child2.Refresh()
            $exitCodes = @($child1.ExitCode, $child2.ExitCode)
        }
        finally {
            foreach ($child in @($child1, $child2)) {
                if (-not $child.HasExited) {
                    $child.Kill()
                    $child.WaitForExit()
                }
                $child.Dispose()
            }
        }

        @($exitCodes | Where-Object { $_ -eq 0 }).Count | Should -Be 1
        @($exitCodes | Where-Object { $_ -ne 0 }).Count | Should -Be 1
        $passParent = Join-Path $project ('log/review/' + $taskId + '/local-correctness')
        @((Get-ChildItem -LiteralPath $passParent -Directory)).Count | Should -Be 2
        Test-Path -LiteralPath (Join-Path $passParent 'pass-03') | Should -BeFalse
        $input02 = Join-Path $passParent 'pass-02/input.md'
        Test-Path -LiteralPath $input02 -PathType Leaf | Should -BeTrue
        (Get-Item -LiteralPath $input02).Length | Should -Be 0
    }

    It 'AC-PR-CAM7: first explicit pass-99는 허용되지만 이후 lower explicit은 mutation 없이 exhaustion이다' {
        $project = script:New-PrepareCaseRoot -CaseName 'campaign-explicit-pass99'
        $taskId = 'campaign-explicit-pass99'

        $pass99 = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-99'
        $pass99.ExitCode | Should -Be 0 -Because $pass99.Output
        $pass99.Output | Should -Match '(?m)^pass: pass-99$'

        $lower = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01' -ContinueCampaign
        $lower.ExitCode | Should -Not -Be 0
        $lower.Output | Should -Match 'range exhausted \(max 99\)'
        $lower.Output | Should -Match 'exhausted selected perspective'
        $lower.Output | Should -Match 'do not allocate a lower pass or another ReviewTaskId automatically'
        Test-Path -LiteralPath (Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-01')) | Should -BeFalse
    }

    It 'AC-PR-CAM8: pass-99 file도 selected perspective만 exhaust시키고 다른 perspective는 독립적이다' {
        $project = script:New-PrepareCaseRoot -CaseName 'campaign-pass99-file'
        $taskId = 'campaign-pass99-file'

        $first = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId
        $first.ExitCode | Should -Be 0 -Because $first.Output

        $localParent = Join-Path $project ('log/review/' + $taskId + '/local-correctness')
        $pass99File = Join-Path $localParent 'pass-99'
        [System.IO.File]::WriteAllText($pass99File, 'occupied', (New-Object System.Text.UTF8Encoding($false)))

        $blocked = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-02' -ContinueCampaign
        $blocked.ExitCode | Should -Not -Be 0
        $blocked.Output | Should -Match 'range exhausted \(max 99\)'
        Test-Path -LiteralPath (Join-Path $localParent 'pass-02') | Should -BeFalse

        $otherPerspective = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -Perspective 'system-coherence' -Pass 'pass-01' -ContinueCampaign
        $otherPerspective.ExitCode | Should -Be 0 -Because $otherPerspective.Output
        Test-Path -LiteralPath (Join-Path $project ('log/review/' + $taskId + '/system-coherence/pass-01/input.md')) -PathType Leaf | Should -BeTrue
    }

    It 'AC-PR-CAM9: selected perspective junction은 prepare entrypoint에서 pass mutation 전에 거부된다' {
        $project = script:New-PrepareCaseRoot -CaseName 'campaign-write-parent-reparse'
        $taskId = 'campaign-write-parent-reparse'

        $first = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId
        $first.ExitCode | Should -Be 0 -Because $first.Output

        $taskDir = Join-Path $project ('log/review/' + $taskId)
        $outsidePerspective = Join-Path $project 'outside-system-coherence'
        $null = [System.IO.Directory]::CreateDirectory($outsidePerspective)
        $selectedPassParent = Join-Path $taskDir 'system-coherence'
        $null = New-Item -ItemType Junction -Path $selectedPassParent -Target $outsidePerspective -ErrorAction Stop

        $blocked = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -Perspective 'system-coherence' -Pass 'pass-01' -ContinueCampaign
        $blocked.ExitCode | Should -Not -Be 0
        $blocked.Output | Should -Match 'selected review write path is not statically safe'
        $blocked.Output | Should -Match 'static reparse point'
        Test-Path -LiteralPath (Join-Path $outsidePerspective 'pass-01') | Should -BeFalse
    }

    It 'AC-PR-CAM10: log/review junction은 new와 continue 모두 첫 mutation 전에 거부된다' {
        $project = script:New-PrepareCaseRoot -CaseName 'campaign-review-root-reparse'
        $logRoot = Join-Path $project 'log'
        $null = [System.IO.Directory]::CreateDirectory($logRoot)
        $outsideReview = Join-Path $project 'outside-review'
        $null = [System.IO.Directory]::CreateDirectory($outsideReview)
        $reviewLink = Join-Path $logRoot 'review'
        $null = New-Item -ItemType Junction -Path $reviewLink -Target $outsideReview -ErrorAction Stop

        $newTaskId = 'campaign-review-root-new'
        $newBlocked = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $newTaskId
        $newBlocked.ExitCode | Should -Not -Be 0
        $newBlocked.Output | Should -Match 'review/task ancestry is not statically safe'
        $newBlocked.Output | Should -Match 'static reparse point'
        Test-Path -LiteralPath (Join-Path $outsideReview $newTaskId) | Should -BeFalse

        $continueTaskId = 'campaign-review-root-continue'
        $outsideAnchor = Join-Path $outsideReview ($continueTaskId + '/local-correctness/pass-01')
        $null = [System.IO.Directory]::CreateDirectory($outsideAnchor)
        [System.IO.File]::WriteAllText(
            (Join-Path $outsideAnchor 'input.md'),
            '',
            (New-Object System.Text.UTF8Encoding($false))
        )
        $continueBlocked = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $continueTaskId -ContinueCampaign
        $continueBlocked.ExitCode | Should -Not -Be 0
        $continueBlocked.Output | Should -Match 'review/task ancestry is not statically safe'
        Test-Path -LiteralPath (Join-Path $outsideReview ($continueTaskId + '/local-correctness/pass-02')) | Should -BeFalse
    }

    It 'AC-PR-CAM11: explicit pass-02 뒤 새 auto scan의 pass-03은 distinct allocation으로 성공한다' {
        $project = script:New-PrepareCaseRoot -CaseName 'campaign-explicit-then-auto'
        $taskId = 'campaign-explicit-then-auto'

        $explicit = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-02'
        $explicit.ExitCode | Should -Be 0 -Because $explicit.Output
        $explicit.Output | Should -Match '(?m)^pass: pass-02$'

        $auto = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -ContinueCampaign
        $auto.ExitCode | Should -Be 0 -Because $auto.Output
        $auto.Output | Should -Match '(?m)^pass: pass-03$'
        Test-Path -LiteralPath (Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-02/input.md')) -PathType Leaf | Should -BeTrue
        Test-Path -LiteralPath (Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-03/input.md')) -PathType Leaf | Should -BeTrue
    }

    It 'AC-PR-CAM12: selected write parent의 wrong file shape는 pass mutation 전에 거부된다' {
        $project = script:New-PrepareCaseRoot -CaseName 'campaign-write-parent-wrong-shape'
        $taskId = 'campaign-write-parent-wrong-shape'
        $taskDir = Join-Path $project ('log/review/' + $taskId)
        $anchor = Join-Path $taskDir 'system-coherence/pass-01'
        $null = [System.IO.Directory]::CreateDirectory($anchor)
        [System.IO.File]::WriteAllText(
            (Join-Path $anchor 'input.md'),
            '',
            (New-Object System.Text.UTF8Encoding($false))
        )
        $wrongParent = Join-Path $taskDir 'local-correctness'
        [System.IO.File]::WriteAllText(
            $wrongParent,
            'not-a-directory',
            (New-Object System.Text.UTF8Encoding($false))
        )

        $blocked = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01' -ContinueCampaign
        $blocked.ExitCode | Should -Not -Be 0
        $blocked.Output | Should -Match 'selected review write path is not statically safe'
        $blocked.Output | Should -Match 'not a directory'
        Test-Path -LiteralPath (Join-Path $wrongParent 'pass-01') | Should -BeFalse
    }

    It 'AC-PR-CAM13: post-check 직전 concurrent pass-99가 보이면 entrypoint는 no-PASS이고 lower orphan을 보존한다' {
        $project = script:New-PrepareCaseRoot -CaseName 'campaign-pass99-post-check'
        $taskId = 'campaign-pass99-post-check'
        $toolScripts = Join-Path $project 'instrumented-tool/scripts'
        $toolLib = Join-Path $toolScripts 'lib'
        $null = [System.IO.Directory]::CreateDirectory($toolLib)

        $prepareCopy = Join-Path $toolScripts 'review-prepare.ps1'
        $encodingCopy = Join-Path $toolLib 'encoding.ps1'
        $realPathCopy = Join-Path $toolLib 'path-real.ps1'
        $pathWrapper = Join-Path $toolLib 'path.ps1'
        Copy-Item -LiteralPath $script:ReviewPrepareScript -Destination $prepareCopy
        Copy-Item -LiteralPath (Join-Path $script:RepoRoot 'scripts/lib/encoding.ps1') -Destination $encodingCopy
        Copy-Item -LiteralPath (Join-Path $script:RepoRoot 'scripts/lib/path.ps1') -Destination $realPathCopy

        $wrapper = @'
. (Join-Path $PSScriptRoot 'path-real.ps1')
$script:OriginalAssertReviewPass99NotOccupied = ${function:Assert-ReviewPass99NotOccupied}
$script:Pass99CheckCount = 0
function Assert-ReviewPass99NotOccupied {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $PassParent,
        [switch] $RequireExistingParent
    )

    $script:Pass99CheckCount++
    if ($script:Pass99CheckCount -eq 2) {
        $null = New-ReviewPassAllocation -PassDir (Join-Path $PassParent 'pass-99')
    }
    & $script:OriginalAssertReviewPass99NotOccupied `
        -PassParent $PassParent `
        -RequireExistingParent:$RequireExistingParent
}
'@
        [System.IO.File]::WriteAllText(
            $pathWrapper,
            $wrapper,
            (New-Object System.Text.UTF8Encoding($false))
        )

        $blocked = script:Invoke-ReviewPrepare `
            -ProjectRoot $project `
            -ReviewTaskId $taskId `
            -PrepareScriptPath $prepareCopy
        $blocked.ExitCode | Should -Not -Be 0
        $blocked.Output | Should -Match 'pass-99 became occupied while allocating pass-01'
        $blocked.Output | Should -Match 'preserved as an orphan'
        $blocked.Output | Should -Not -Match '(?m)^review-prepare: PASS$'

        $passParent = Join-Path $project ('log/review/' + $taskId + '/local-correctness')
        foreach ($pass in @('pass-01', 'pass-99')) {
            $input = Join-Path $passParent ($pass + '/input.md')
            Test-Path -LiteralPath $input -PathType Leaf | Should -BeTrue
            (Get-Item -LiteralPath $input).Length | Should -Be 0
        }
    }

    It 'AC-PR-CAM14: post-check inspection failure는 점유나 lower 잔존을 단정하지 않고 no-PASS로 끝난다' {
        $project = script:New-PrepareCaseRoot -CaseName 'campaign-pass99-post-check-unavailable'
        $taskId = 'campaign-pass99-post-check-unavailable'
        $toolScripts = Join-Path $project 'instrumented-tool/scripts'
        $toolLib = Join-Path $toolScripts 'lib'
        $null = [System.IO.Directory]::CreateDirectory($toolLib)

        $prepareCopy = Join-Path $toolScripts 'review-prepare.ps1'
        $encodingCopy = Join-Path $toolLib 'encoding.ps1'
        $realPathCopy = Join-Path $toolLib 'path-real.ps1'
        $pathWrapper = Join-Path $toolLib 'path.ps1'
        Copy-Item -LiteralPath $script:ReviewPrepareScript -Destination $prepareCopy
        Copy-Item -LiteralPath (Join-Path $script:RepoRoot 'scripts/lib/encoding.ps1') -Destination $encodingCopy
        Copy-Item -LiteralPath (Join-Path $script:RepoRoot 'scripts/lib/path.ps1') -Destination $realPathCopy

        $wrapper = @'
. (Join-Path $PSScriptRoot 'path-real.ps1')
$script:OriginalAssertReviewPass99NotOccupied = ${function:Assert-ReviewPass99NotOccupied}
$script:Pass99CheckCount = 0
function Assert-ReviewPass99NotOccupied {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $PassParent,
        [switch] $RequireExistingParent
    )

    $script:Pass99CheckCount++
    if ($script:Pass99CheckCount -eq 2) {
        throw 'synthetic post-check inspection unavailable'
    }
    & $script:OriginalAssertReviewPass99NotOccupied `
        -PassParent $PassParent `
        -RequireExistingParent:$RequireExistingParent
}
'@
        [System.IO.File]::WriteAllText(
            $pathWrapper,
            $wrapper,
            (New-Object System.Text.UTF8Encoding($false))
        )

        $blocked = script:Invoke-ReviewPrepare `
            -ProjectRoot $project `
            -ReviewTaskId $taskId `
            -PrepareScriptPath $prepareCopy
        $blocked.ExitCode | Should -Not -Be 0
        $blocked.Output | Should -Match 'post-allocation pass-99 state could not be confirmed after allocating pass-01'
        $blocked.Output | Should -Match 'Do not infer pass-99 occupancy or lower-pass persistence'
        $blocked.Output | Should -Not -Match 'pass-99 became occupied'
        $blocked.Output | Should -Not -Match 'preserved as an orphan'
        $blocked.Output | Should -Not -Match '(?m)^review-prepare: PASS$'
    }

    It 'AC-PR-CAM15: dangling log/review junction은 new campaign claim 전에 no-PASS로 거부된다' {
        $project = script:New-PrepareCaseRoot -CaseName 'campaign-review-root-dangling-reparse'
        $logRoot = Join-Path $project 'log'
        $null = [System.IO.Directory]::CreateDirectory($logRoot)
        $outsideReview = Join-Path $project 'outside-review'
        $null = [System.IO.Directory]::CreateDirectory($outsideReview)
        $reviewLink = Join-Path $logRoot 'review'
        $null = New-Item -ItemType Junction -Path $reviewLink -Target $outsideReview -ErrorAction Stop
        Remove-Item -LiteralPath $outsideReview -Recurse -Force

        $entry = @(Get-ChildItem -LiteralPath $logRoot -Force | Where-Object Name -CEQ 'review')
        $entry.Count | Should -Be 1
        (($entry[0].Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) | Should -BeTrue

        $blocked = script:Invoke-ReviewPrepare `
            -ProjectRoot $project `
            -ReviewTaskId 'campaign-review-root-dangling-reparse'
        $blocked.ExitCode | Should -Not -Be 0
        $blocked.Output | Should -Match 'review/task ancestry is not statically safe'
        $blocked.Output | Should -Match 'static reparse point'
        $blocked.Output | Should -Not -Match '(?m)^review-prepare: PASS$'
    }

    It 'AC-PR-CAM16: anchored campaign의 dangling selected perspective는 pass mutation 전에 no-PASS로 거부된다' {
        $project = script:New-PrepareCaseRoot -CaseName 'campaign-write-parent-dangling-reparse'
        $taskId = 'campaign-write-parent-dangling-reparse'
        $taskDir = Join-Path $project ('log/review/' + $taskId)
        $anchor = Join-Path $taskDir 'system-coherence/pass-01'
        $null = [System.IO.Directory]::CreateDirectory($anchor)
        [System.IO.File]::WriteAllText(
            (Join-Path $anchor 'input.md'),
            '',
            (New-Object System.Text.UTF8Encoding($false))
        )
        $outsidePerspective = Join-Path $project 'outside-local-correctness'
        $null = [System.IO.Directory]::CreateDirectory($outsidePerspective)
        $selectedPassParent = Join-Path $taskDir 'local-correctness'
        $null = New-Item -ItemType Junction -Path $selectedPassParent -Target $outsidePerspective -ErrorAction Stop
        Remove-Item -LiteralPath $outsidePerspective -Recurse -Force

        $entry = @(Get-ChildItem -LiteralPath $taskDir -Force | Where-Object Name -CEQ 'local-correctness')
        $entry.Count | Should -Be 1
        (($entry[0].Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) | Should -BeTrue

        $blocked = script:Invoke-ReviewPrepare `
            -ProjectRoot $project `
            -ReviewTaskId $taskId `
            -Pass 'pass-01' `
            -ContinueCampaign
        $blocked.ExitCode | Should -Not -Be 0
        $blocked.Output | Should -Match 'selected review write path is not statically safe'
        $blocked.Output | Should -Match 'static reparse point'
        $blocked.Output | Should -Not -Match '(?m)^review-prepare: PASS$'
    }
}
