Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

BeforeAll {
    $script:RepoRoot   = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).ProviderPath
    $script:RunScript     = Join-Path $script:RepoRoot 'scripts/review-run.ps1'
    $script:PrepareScript = Join-Path $script:RepoRoot 'scripts/review-prepare.ps1'
    $script:VerifyScript  = Join-Path $script:RepoRoot 'scripts/review-verify.ps1'

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

    function script:Write-Utf8BomCrlfFile {
        param([string] $Path, [string] $Content)
        $parent = Split-Path -LiteralPath $Path
        if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
            $null = New-Item -ItemType Directory -Path $parent -Force
        }
        $resolved = [System.IO.Path]::GetFullPath($Path)
        $normalized = $Content -replace "`r`n", "`n"
        $normalized = $normalized -replace "`r", "`n"
        $normalized = $normalized -replace "`n", "`r`n"
        $encoding = New-Object System.Text.UTF8Encoding($true)
        [System.IO.File]::WriteAllText($resolved, $normalized, $encoding)
    }

    function script:New-RunCase {
        param([string] $CaseName)
        $caseRoot = Join-Path $TestDrive ('pester-review-run-' + $CaseName)
        if (Test-Path -LiteralPath $caseRoot) {
            Remove-Item -LiteralPath $caseRoot -Recurse -Force
        }
        $null = New-Item -ItemType Directory -Path $caseRoot -Force
        return ([System.IO.Path]::GetFullPath($caseRoot))
    }

    function script:Write-CodexStub {
        param(
            [string] $StubName,
            [string] $Mode = 'verdict-yes'
        )
        $stubDir = Join-Path $TestDrive 'pester-review-run-stubs'
        if (-not (Test-Path -LiteralPath $stubDir -PathType Container)) {
            $null = New-Item -ItemType Directory -Path $stubDir -Force
        }
        $stubPath = Join-Path $stubDir ($StubName + '.ps1')

        $body = @()
        $body += '[CmdletBinding()]'
        $body += 'param('
        $body += '    [Parameter(Mandatory = $true)]'
        $body += '    [string] $CodexArgsFile'
        $body += ')'
        $body += 'Set-StrictMode -Version Latest'
        $body += '$ErrorActionPreference = ''Stop'''
        $body += 'if (-not (Test-Path -LiteralPath $CodexArgsFile -PathType Leaf)) {'
        $body += '    Write-Host ''codex-stub: FAIL CodexArgsFile not found''; exit 90'
        $body += '}'
        $body += '$enc = New-Object System.Text.UTF8Encoding($false)'
        $body += '$jsonText = [System.IO.File]::ReadAllText($CodexArgsFile, $enc)'
        $body += '$argsObj = $jsonText | ConvertFrom-Json'
        $body += '$argv = @($argsObj.argv)'
        $body += '$out = '''''
        $body += '$model = '''''
        $body += '$hasExec = $false'
        $body += '$hasStdinMarker = $false'
        $body += '$hasWebSearchDisabled = $false'
        $body += '$hasReadOnly = $false'
        $body += '$hasApprovalNever = $false'
        $body += 'for ($i = 0; $i -lt $argv.Count; $i++) {'
        $body += '    $a = [string]$argv[$i]'
        $body += '    if ($a -ceq ''exec'') { $hasExec = $true }'
        $body += '    elseif ($a -ceq ''-'') { if ($i -eq $argv.Count - 1) { $hasStdinMarker = $true } }'
        $body += '    elseif ($a -ceq ''--ask-for-approval'') { if ($i + 1 -lt $argv.Count -and ([string]$argv[$i+1]) -ceq ''never'') { $hasApprovalNever = $true } }'
        $body += '    elseif ($a -ceq ''--sandbox'') { if ($i + 1 -lt $argv.Count -and ([string]$argv[$i+1]) -ceq ''read-only'') { $hasReadOnly = $true } }'
        $body += '    elseif ($a -ceq ''-c'') { if ($i + 1 -lt $argv.Count -and ([string]$argv[$i+1]) -ceq ''web_search=disabled'') { $hasWebSearchDisabled = $true } }'
        $body += '    elseif ($a -ceq ''--model'') { if ($i + 1 -lt $argv.Count) { $model = [string]$argv[$i+1] } }'
        $body += '    elseif ($a -ceq ''--output-last-message'') { if ($i + 1 -lt $argv.Count) { $out = [string]$argv[$i+1] } }'
        $body += '}'
        $body += 'if (-not $hasApprovalNever) { Write-Host ''codex-stub: FAIL --ask-for-approval never missing''; exit 91 }'
        $body += 'if (-not $hasExec) { Write-Host ''codex-stub: FAIL exec missing''; exit 92 }'
        $body += 'if (-not $hasReadOnly) { Write-Host ''codex-stub: FAIL --sandbox read-only missing''; exit 93 }'
        $body += 'if ([string]::IsNullOrEmpty($model)) { Write-Host ''codex-stub: FAIL --model missing''; exit 94 }'
        $body += 'if (-not $hasWebSearchDisabled) { Write-Host ''codex-stub: FAIL -c web_search=disabled missing''; exit 95 }'
        $body += 'if ([string]::IsNullOrEmpty($out)) { Write-Host ''codex-stub: FAIL --output-last-message missing''; exit 96 }'
        $body += 'if (-not $hasStdinMarker) { Write-Host ''codex-stub: FAIL stdin marker - missing''; exit 97 }'
        $body += '[System.IO.File]::WriteAllText(($out + ''.argv.txt''), ($argv -join "`n"), $enc)'
        # Capture the stdin payload review-run.ps1 pipes to Codex so tests can assert the
        # deterministic reviewer-mode preamble is injected ahead of the input.md content.
        $body += '$stdinText = [Console]::In.ReadToEnd()'
        $body += '[System.IO.File]::WriteAllText(($out + ''.stdin.txt''), $stdinText, $enc)'

        switch ($Mode) {
            'verdict-yes' {
                $body += '$content = "# Review Result`r`n`r`n## Verdict`r`n`r`nyes`r`n"'
                $body += '[System.IO.File]::WriteAllText($out, $content, $enc)'
                $body += 'exit 0'
            }
            'verdict-no' {
                $body += '$content = "# Review Result`r`n`r`n## Verdict`r`n`r`nno`r`n"'
                $body += '[System.IO.File]::WriteAllText($out, $content, $enc)'
                $body += 'exit 0'
            }
            'verdict-yes-with-risk' {
                $body += '$content = "# Review Result`r`n`r`n## Verdict`r`n`r`nyes with risk`r`n"'
                $body += '[System.IO.File]::WriteAllText($out, $content, $enc)'
                $body += 'exit 0'
            }
            'no-verdict' {
                $body += '$content = "# Review Result`r`n`r`nNo Verdict heading present.`r`n"'
                $body += '[System.IO.File]::WriteAllText($out, $content, $enc)'
                $body += 'exit 0'
            }
            'verdict-maybe' {
                $body += '$content = "# Review Result`r`n`r`n## Verdict`r`n`r`nmaybe`r`n"'
                $body += '[System.IO.File]::WriteAllText($out, $content, $enc)'
                $body += 'exit 0'
            }
            'verdict-title-yes' {
                $body += '$content = "# Review Result`r`n`r`n## Verdict`r`n`r`nYes`r`n"'
                $body += '[System.IO.File]::WriteAllText($out, $content, $enc)'
                $body += 'exit 0'
            }
            default {
                throw "Unknown stub mode: $Mode"
            }
        }

        $text = ($body -join "`r`n") + "`r`n"
        script:Write-Utf8BomCrlfFile -Path $stubPath -Content $text
        return $stubPath
    }

    function script:Invoke-ReviewPrepare {
        param(
            [string] $ProjectRoot,
            [string] $ReviewTaskId,
            [string] $Pass
        )
        $procArgs = @(
            '-NoProfile', '-ExecutionPolicy', 'Bypass',
            '-File', $script:PrepareScript,
            '-Stage', 'implementation',
            '-Purpose', 'pester review-run prepare',
            '-ProjectRoot', $ProjectRoot,
            '-ToolRoot', $script:RepoRoot,
            '-ReviewTaskId', $ReviewTaskId
        )
        if (-not [string]::IsNullOrEmpty($Pass)) {
            $procArgs += @('-Pass', $Pass)
        }
        $combined = & powershell.exe @procArgs 2>&1
        $exitCode = $LASTEXITCODE
        $text = ($combined | ForEach-Object { [string]$_ }) -join "`n"
        return [pscustomobject]@{
            ExitCode = $exitCode
            Output   = $text
        }
    }

    function script:Build-FilledInput {
        $body = @()
        $body += '# Review Input'
        $body += ''
        $body += '## Stage'
        $body += ''
        $body += 'implementation'
        $body += ''
        $body += '## Purpose'
        $body += ''
        $body += 'pester run.'
        $body += ''
        $body += '## Target files'
        $body += ''
        $body += '- pester/target.txt'
        $body += ''
        $body += '## Context'
        $body += ''
        $body += 'pester context line.'
        $body += ''
        $body += '## Required inspection paths'
        $body += ''
        $body += 'pester inspection path.'
        $body += ''
        $body += '## Review questions'
        $body += ''
        $body += 'pester review question.'
        $body += ''
        $body += '## Constraints'
        $body += ''
        $body += 'pester constraint.'
        $body += ''
        $body += '## Final verdict'
        $body += ''
        $body += 'yes / no / yes with risk'
        $body += ''
        return ($body -join "`n")
    }

    function script:Set-InputFilled {
        param([string] $InputPath)
        script:Write-Utf8NoBomFile -Path $InputPath -Content (script:Build-FilledInput)
    }

    function script:Invoke-ReviewRun {
        param(
            [string] $ProjectRoot,
            [string] $ReviewTaskId,
            [string] $Pass,
            [string] $StubPath,
            [string] $Reviewer = 'codex',
            [string] $Model
        )
        $procArgs = @(
            '-NoProfile', '-ExecutionPolicy', 'Bypass',
            '-File', $script:RunScript,
            '-ReviewTaskId', $ReviewTaskId,
            '-Pass', $Pass,
            '-Reviewer', $Reviewer,
            '-ProjectRoot', $ProjectRoot,
            '-ToolRoot', $script:RepoRoot
        )
        if (-not [string]::IsNullOrEmpty($Model)) {
            $procArgs += @('-Model', $Model)
        }

        $previousEnv = $env:AI_HARNESS_CODEX_COMMAND
        $previousStubFlag = $env:AI_HARNESS_CODEX_ARGS_FILE_STUB
        if (-not [string]::IsNullOrEmpty($StubPath)) {
            $env:AI_HARNESS_CODEX_COMMAND = $StubPath
            $env:AI_HARNESS_CODEX_ARGS_FILE_STUB = '1'
        }
        try {
            $combined = & powershell.exe @procArgs 2>&1
            $exitCode = $LASTEXITCODE
        }
        finally {
            $env:AI_HARNESS_CODEX_COMMAND = $previousEnv
            $env:AI_HARNESS_CODEX_ARGS_FILE_STUB = $previousStubFlag
        }
        $text = ($combined | ForEach-Object { [string]$_ }) -join "`n"
        return [pscustomobject]@{
            ExitCode = $exitCode
            Output   = $text
        }
    }
}

Describe 'review-run canonical pass directory' {
    It 'AC-RR1: happy path on a prepared pass writes canonical result.md with the verdict' {
        $project = script:New-RunCase -CaseName 'rr1'
        $taskId  = 'rr1-task'
        $prep = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01'
        $prep.ExitCode | Should -Be 0 -Because $prep.Output

        $inputPath = Join-Path $project ('log/review/' + $taskId + '/pass-01/input.md')
        script:Set-InputFilled -InputPath $inputPath

        $stub = script:Write-CodexStub -StubName 'rr1-yes' -Mode 'verdict-yes'
        $r = script:Invoke-ReviewRun -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01' -StubPath $stub
        $r.ExitCode | Should -Be 0 -Because $r.Output
        $r.Output | Should -Match 'review-run: PASS'
        $r.Output | Should -Match 'verdict: yes'

        $passDir = Join-Path $project ('log/review/' + $taskId + '/pass-01')
        Test-Path -LiteralPath (Join-Path $passDir 'result.md') -PathType Leaf | Should -BeTrue

        # Canonical contract: only input.md + result.md.
        Test-Path -LiteralPath (Join-Path $passDir 'meta.json')         -PathType Leaf | Should -BeFalse
        Test-Path -LiteralPath (Join-Path $passDir 'result.json')       -PathType Leaf | Should -BeFalse
        Test-Path -LiteralPath (Join-Path $passDir 'target-files.list') -PathType Leaf | Should -BeFalse
    }

    It 'AC-RR2: missing pass directory fails before invoking Codex' {
        $project = script:New-RunCase -CaseName 'rr2'
        $stub = script:Write-CodexStub -StubName 'rr2-yes' -Mode 'verdict-yes'

        $r = script:Invoke-ReviewRun -ProjectRoot $project -ReviewTaskId 'no-such-task' -Pass 'pass-01' -StubPath $stub
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'pass directory not prepared'
    }

    It 'AC-RR3: missing input.md inside an otherwise-prepared pass dir fails before Codex' {
        $project = script:New-RunCase -CaseName 'rr3'
        $taskId  = 'rr3-task'
        $prep = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01'
        $prep.ExitCode | Should -Be 0 -Because $prep.Output

        $inputPath = Join-Path $project ('log/review/' + $taskId + '/pass-01/input.md')
        Remove-Item -LiteralPath $inputPath -Force

        $stub = script:Write-CodexStub -StubName 'rr3-yes' -Mode 'verdict-yes'
        $r = script:Invoke-ReviewRun -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01' -StubPath $stub
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'input\.md not found'

        Test-Path -LiteralPath (Join-Path $project ('log/review/' + $taskId + '/pass-01/result.md')) -PathType Leaf | Should -BeFalse
    }

    It 'AC-RR4: placeholder-only input.md fails through review-input-verify and Codex is not invoked' {
        $project = script:New-RunCase -CaseName 'rr4'
        $taskId  = 'rr4-task'
        $prep = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01'
        $prep.ExitCode | Should -Be 0 -Because $prep.Output

        # input.md is the unmodified seeded template, which still contains {{AI_TO_FILL_*}} tokens.
        $stub = script:Write-CodexStub -StubName 'rr4-yes' -Mode 'verdict-yes'
        $r = script:Invoke-ReviewRun -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01' -StubPath $stub
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'input\.md not ready'
        $r.Output | Should -Match 'review-input-verify'

        Test-Path -LiteralPath (Join-Path $project ('log/review/' + $taskId + '/pass-01/result.md')) -PathType Leaf | Should -BeFalse
    }

    It 'AC-RR5: result.md already present blocks re-run for the same pass (write-once)' {
        $project = script:New-RunCase -CaseName 'rr5'
        $taskId  = 'rr5-task'
        $prep = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01'
        $prep.ExitCode | Should -Be 0 -Because $prep.Output

        $inputPath = Join-Path $project ('log/review/' + $taskId + '/pass-01/input.md')
        script:Set-InputFilled -InputPath $inputPath

        $stub = script:Write-CodexStub -StubName 'rr5-yes' -Mode 'verdict-yes'
        $first = script:Invoke-ReviewRun -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01' -StubPath $stub
        $first.ExitCode | Should -Be 0 -Because $first.Output

        $resultMd = Join-Path $project ('log/review/' + $taskId + '/pass-01/result.md')
        $enc = New-Object System.Text.UTF8Encoding($false)
        $before = [System.IO.File]::ReadAllText($resultMd, $enc)

        $second = script:Invoke-ReviewRun -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01' -StubPath $stub
        $second.ExitCode | Should -Not -Be 0
        $second.Output | Should -Match 'result\.md already exists'
        $second.Output | Should -Match 'write-once'

        $after = [System.IO.File]::ReadAllText($resultMd, $enc)
        $after | Should -Be $before
    }

    It 'AC-RR6: verdict parse failure preserves the failed pass on disk; no legacy result.json is written' {
        $project = script:New-RunCase -CaseName 'rr6'
        $taskId  = 'rr6-task'
        $prep = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01'
        $prep.ExitCode | Should -Be 0 -Because $prep.Output

        $inputPath = Join-Path $project ('log/review/' + $taskId + '/pass-01/input.md')
        script:Set-InputFilled -InputPath $inputPath

        $stub = script:Write-CodexStub -StubName 'rr6-nv' -Mode 'no-verdict'
        $r = script:Invoke-ReviewRun -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01' -StubPath $stub
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'Could not parse verdict'

        $passDir = Join-Path $project ('log/review/' + $taskId + '/pass-01')
        Test-Path -LiteralPath $passDir                       -PathType Container | Should -BeTrue
        Test-Path -LiteralPath (Join-Path $passDir 'result.md') -PathType Leaf      | Should -BeTrue
        Test-Path -LiteralPath (Join-Path $passDir 'result.json') -PathType Leaf    | Should -BeFalse
    }

    It 'AC-RR7: corrective loop — pass-02 can run cleanly when pass-01 verdict was no' {
        $project = script:New-RunCase -CaseName 'rr7'
        $taskId  = 'rr7-task'

        $prep1 = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01'
        $prep1.ExitCode | Should -Be 0
        $input1 = Join-Path $project ('log/review/' + $taskId + '/pass-01/input.md')
        script:Set-InputFilled -InputPath $input1

        $stubNo = script:Write-CodexStub -StubName 'rr7-no' -Mode 'verdict-no'
        $r1 = script:Invoke-ReviewRun -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01' -StubPath $stubNo
        $r1.ExitCode | Should -Be 0 -Because $r1.Output
        $r1.Output | Should -Match 'verdict: no'

        # Allocate the next pass.
        $prep2 = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId
        $prep2.ExitCode | Should -Be 0 -Because $prep2.Output
        $prep2.Output | Should -Match 'pass: pass-02'
        $input2 = Join-Path $project ('log/review/' + $taskId + '/pass-02/input.md')
        script:Set-InputFilled -InputPath $input2

        $stubYes = script:Write-CodexStub -StubName 'rr7-yes' -Mode 'verdict-yes'
        $r2 = script:Invoke-ReviewRun -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-02' -StubPath $stubYes
        $r2.ExitCode | Should -Be 0 -Because $r2.Output
        $r2.Output | Should -Match 'verdict: yes'

        # Both passes exist on disk independently.
        Test-Path -LiteralPath (Join-Path $project ('log/review/' + $taskId + '/pass-01/result.md')) -PathType Leaf | Should -BeTrue
        Test-Path -LiteralPath (Join-Path $project ('log/review/' + $taskId + '/pass-02/result.md')) -PathType Leaf | Should -BeTrue
    }

    It 'AC-RR8: non-codex reviewer fails with the MVP boundary message' {
        $project = script:New-RunCase -CaseName 'rr8'
        $taskId  = 'rr8-task'
        $prep = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01'
        $prep.ExitCode | Should -Be 0 -Because $prep.Output
        $inputPath = Join-Path $project ('log/review/' + $taskId + '/pass-01/input.md')
        script:Set-InputFilled -InputPath $inputPath

        $stub = script:Write-CodexStub -StubName 'rr8-yes' -Mode 'verdict-yes'
        $r = script:Invoke-ReviewRun -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01' -StubPath $stub -Reviewer 'claude'
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'only -Reviewer codex is supported'
    }

    It 'AC-RR10: title-cased verdict ("Yes") is rejected by review-run, same as review-verify' {
        $project = script:New-RunCase -CaseName 'rr10'
        $taskId  = 'rr10-task'
        $prep = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01'
        $prep.ExitCode | Should -Be 0 -Because $prep.Output
        $inputPath = Join-Path $project ('log/review/' + $taskId + '/pass-01/input.md')
        script:Set-InputFilled -InputPath $inputPath

        $stub = script:Write-CodexStub -StubName 'rr10-title' -Mode 'verdict-title-yes'
        $r = script:Invoke-ReviewRun -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01' -StubPath $stub
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'Could not parse verdict'

        $passDir = Join-Path $project ('log/review/' + $taskId + '/pass-01')
        Test-Path -LiteralPath (Join-Path $passDir 'result.md') -PathType Leaf | Should -BeTrue
    }

    It 'AC-RR11: reviewer-mode preamble is injected ahead of input.md on the Codex stdin payload' {
        # Regression for the BRIEF restore-offer pollution defect: review-run.ps1 must
        # prepend a deterministic reviewer-mode shield to the content piped to Codex, so a
        # global AGENTS.md/CLAUDE.md restore-offer can never turn a verdict into a question.
        $project = script:New-RunCase -CaseName 'rr11'
        $taskId  = 'rr11-task'
        $prep = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01'
        $prep.ExitCode | Should -Be 0 -Because $prep.Output

        $inputPath = Join-Path $project ('log/review/' + $taskId + '/pass-01/input.md')
        script:Set-InputFilled -InputPath $inputPath

        $stub = script:Write-CodexStub -StubName 'rr11-yes' -Mode 'verdict-yes'
        $r = script:Invoke-ReviewRun -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01' -StubPath $stub
        $r.ExitCode | Should -Be 0 -Because $r.Output

        $resultMd = Join-Path $project ('log/review/' + $taskId + '/pass-01/result.md')
        $stdinCapture = $resultMd + '.stdin.txt'
        Test-Path -LiteralPath $stdinCapture -PathType Leaf | Should -BeTrue -Because 'stub must have received piped stdin'

        $enc = New-Object System.Text.UTF8Encoding($false)
        $stdin = [System.IO.File]::ReadAllText($stdinCapture, $enc)

        # Reviewer-mode declaration + the specific anti-restore-offer guards.
        $stdin | Should -Match 'CODEX REVIEWER MODE'
        $stdin | Should -Match 'BRIEF'
        $stdin | Should -Match 'restore-offer'
        $stdin | Should -Match 'Do NOT ask the user any question'
        $stdin | Should -Match '## Verdict'
        # The original input.md content must still follow the preamble marker.
        $stdin | Should -Match 'BEGIN REVIEW INPUT'
        $stdin | Should -Match 'pester context line\.'
        # Preamble must come before the input content (shield precedes the task).
        ($stdin.IndexOf('CODEX REVIEWER MODE')) | Should -BeLessThan ($stdin.IndexOf('pester context line.'))

        # input.md on disk is unchanged by the injection (canonical artifact preserved).
        $onDisk = [System.IO.File]::ReadAllText($inputPath, $enc)
        $onDisk | Should -Not -Match 'CODEX REVIEWER MODE'
    }

    It 'AC-RR9: invalid -Pass (not pass-NN) is rejected before any Codex invocation' {
        $project = script:New-RunCase -CaseName 'rr9'
        $taskId  = 'rr9-task'

        $stub = script:Write-CodexStub -StubName 'rr9-yes' -Mode 'verdict-yes'
        $r = script:Invoke-ReviewRun -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-1' -StubPath $stub
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'invalid Pass'
    }
}
