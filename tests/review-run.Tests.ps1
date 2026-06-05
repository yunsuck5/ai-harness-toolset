Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

BeforeAll {
    $script:RepoRoot   = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).ProviderPath
    . (Join-Path $script:RepoRoot 'scripts/lib/native-process.ps1')
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

    function script:New-ModellessToolRoot {
        # A temp ToolRoot whose config/reviewer.json has NO model, to exercise the model fail-fast.
        # review-run resolves the model before touching any other ToolRoot file, so the dir only
        # needs config/reviewer.json.
        param([string] $CaseName)
        $tr = Join-Path $TestDrive ('pester-modelless-toolroot-' + $CaseName)
        $cfgDir = Join-Path $tr 'config'
        $null = New-Item -ItemType Directory -Path $cfgDir -Force
        $enc = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText((Join-Path $cfgDir 'reviewer.json'), "{`n  `"reasoningEffort`": `"xhigh`"`n}`n", $enc)
        return ([System.IO.Path]::GetFullPath($tr))
    }

    function script:New-CategoryToolRoot {
        # A temp ToolRoot with a FIXTURE config/reviewer.json that carries a categoryPolicy with
        # DISTINCT per-category values, so the U9 category lookup wiring can be proven end-to-end
        # (a category effort/model that differs from the scalar default flowing into the Codex argv).
        # review-run resolves config/reviewer.json AND review-input-verify.ps1 (+ lib/*) under the
        # ToolRoot, and an explicit -ToolRoot suppresses the $PSScriptRoot script fallback, so the
        # real scripts/ tree is copied in; only config/reviewer.json is fixture-custom. The fixture
        # 'broken' category (out-of-enum effort) exercises the matched-category fail-fast path; it
        # is harmless unless selected. The real repo config (all categories xhigh) is used by the
        # no-category / miss / safety-floor tests instead.
        param([string] $CaseName)
        $tr = Join-Path $TestDrive ('pester-category-toolroot-' + $CaseName)
        if (Test-Path -LiteralPath $tr) {
            Remove-Item -LiteralPath $tr -Recurse -Force
        }
        $null = New-Item -ItemType Directory -Path $tr -Force
        Copy-Item -LiteralPath (Join-Path $script:RepoRoot 'scripts') -Destination (Join-Path $tr 'scripts') -Recurse -Force
        $cfgDir = Join-Path $tr 'config'
        $null = New-Item -ItemType Directory -Path $cfgDir -Force
        $json = @'
{
  "model": "fixture-scalar-model",
  "reasoningEffort": "xhigh",
  "categoryPolicy": {
    "default": { "model": "fixture-scalar-model", "reasoningEffort": "xhigh" },
    "simple-local": { "model": "fixture-simple-model", "reasoningEffort": "medium" },
    "broken": { "model": "fixture-broken-model", "reasoningEffort": "bogus_value" },
    "no-effort": { "model": "fixture-noeffort-model" },
    "null-entry": null
  }
}
'@
        $enc = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText((Join-Path $cfgDir 'reviewer.json'), $json, $enc)
        return ([System.IO.Path]::GetFullPath($tr))
    }

    function script:Write-CodexStub {
        param(
            [string] $StubName,
            [string] $Mode = 'verdict-yes',
            [bool] $EmitEffortHeader = $true,
            [bool] $EmitVersionHeader = $true
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
        $body += '$hasEffort = $false'
        $body += '$effortValue = '''''
        $body += '$hasIgnoreUserConfig = $false'
        $body += 'for ($i = 0; $i -lt $argv.Count; $i++) {'
        $body += '    $a = [string]$argv[$i]'
        $body += '    if ($a -ceq ''exec'') { $hasExec = $true }'
        $body += '    elseif ($a -ceq ''-'') { if ($i -eq $argv.Count - 1) { $hasStdinMarker = $true } }'
        $body += '    elseif ($a -ceq ''--ask-for-approval'') { if ($i + 1 -lt $argv.Count -and ([string]$argv[$i+1]) -ceq ''never'') { $hasApprovalNever = $true } }'
        $body += '    elseif ($a -ceq ''--sandbox'') { if ($i + 1 -lt $argv.Count -and ([string]$argv[$i+1]) -ceq ''read-only'') { $hasReadOnly = $true } }'
        $body += '    elseif ($a -ceq ''--ignore-user-config'') { $hasIgnoreUserConfig = $true }'
        $body += '    elseif ($a -ceq ''-c'') { if ($i + 1 -lt $argv.Count) { $cv = [string]$argv[$i+1]; if ($cv -ceq ''web_search=disabled'') { $hasWebSearchDisabled = $true } elseif ($cv -clike ''model_reasoning_effort=*'') { $hasEffort = $true; $effortValue = $cv.Substring(''model_reasoning_effort=''.Length) } } }'
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
        $body += 'if (-not $hasEffort) { Write-Host ''codex-stub: FAIL -c model_reasoning_effort= missing''; exit 98 }'
        $body += 'if (-not $hasIgnoreUserConfig) { Write-Host ''codex-stub: FAIL --ignore-user-config missing''; exit 99 }'
        $body += '[System.IO.File]::WriteAllText(($out + ''.argv.txt''), ($argv -join "`n"), $enc)'
        # Mimic the real Codex exec header line on stderr so review-run.ps1 can capture
        # the applied reasoning-effort run-fact (the real CLI prints it to stderr).
        # EmitEffortHeader $false exercises review-run's not-observed honesty path.
        if ($EmitEffortHeader) {
            $body += '[Console]::Error.WriteLine(''reasoning effort: '' + $effortValue)'
        }
        # Mimic the codex run banner version line on stderr so review-run.ps1 can observe the
        # adapter-version run-fact (P2). The emitted version is a CONTROLLED, non-real stub
        # value (9.9.9-stub) so tests never bind to a real external version.
        # EmitVersionHeader $false exercises review-run's not-observed honesty path.
        if ($EmitVersionHeader) {
            $body += '[Console]::Error.WriteLine(''codex-cli 9.9.9-stub'')'
        }
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
            'verdict-yes-full' {
                # A complete reviewer body: verdict + the four required disclosure H2s. Used by
                # the P3 tests so that, after review-run appends its provenance block, the result
                # still satisfies review-verify -RequireResult (verdict shape + four H2s).
                $body += '$content = "# Review Result`r`n`r`n## Verdict`r`n`r`nyes`r`n`r`n## Blocking findings`r`n`r`nnone`r`n`r`n## Non-blocking concerns`r`n`r`nnone`r`n`r`n## Review limitations`r`n`r`nnone`r`n`r`n## Assumptions relied on`r`n`r`nnone`r`n"'
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
            'verdict-lowercase-heading' {
                $body += '$content = "# Review Result`r`n`r`n## verdict`r`n`r`nyes`r`n"'
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
            [string] $Pass,
            # Strict C1: -Perspective is required, so the helper defaults it to 'local-correctness'
            # for tests that do not care about the viewpoint. -OmitPerspective drops it entirely
            # (for the "without -Perspective fails" tests).
            [string] $Perspective = 'local-correctness',
            [switch] $OmitPerspective
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
        if ((-not $OmitPerspective) -and (-not [string]::IsNullOrEmpty($Perspective))) {
            $procArgs += @('-Perspective', $Perspective)
        }
        $proc = Invoke-NativeProcess -Executable 'powershell.exe' -Arguments $procArgs
        $exitCode = $proc.ExitCode
        $text = (($proc.Stdout + $proc.Stderr) -replace "`r`n", "`n").TrimEnd("`n")
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
            [string] $Model,
            [string] $Effort,
            [string] $EffortCategory,
            [string] $ToolRoot,
            # Strict C1: -Perspective is required; default 'local-correctness', -OmitPerspective
            # drops it (for the "without -Perspective fails" tests).
            [string] $Perspective = 'local-correctness',
            [switch] $OmitPerspective
        )
        if ([string]::IsNullOrEmpty($ToolRoot)) { $ToolRoot = $script:RepoRoot }
        $procArgs = @(
            '-NoProfile', '-ExecutionPolicy', 'Bypass',
            '-File', $script:RunScript,
            '-ReviewTaskId', $ReviewTaskId,
            '-Pass', $Pass,
            '-Reviewer', $Reviewer,
            '-ProjectRoot', $ProjectRoot,
            '-ToolRoot', $ToolRoot
        )
        if ((-not $OmitPerspective) -and (-not [string]::IsNullOrEmpty($Perspective))) {
            $procArgs += @('-Perspective', $Perspective)
        }
        if (-not [string]::IsNullOrEmpty($Model)) {
            $procArgs += @('-Model', $Model)
        }
        if (-not [string]::IsNullOrEmpty($Effort)) {
            $procArgs += @('-Effort', $Effort)
        }
        if (-not [string]::IsNullOrEmpty($EffortCategory)) {
            $procArgs += @('-EffortCategory', $EffortCategory)
        }

        $previousEnv = $env:AI_HARNESS_CODEX_COMMAND
        $previousStubFlag = $env:AI_HARNESS_CODEX_ARGS_FILE_STUB
        if (-not [string]::IsNullOrEmpty($StubPath)) {
            $env:AI_HARNESS_CODEX_COMMAND = $StubPath
            $env:AI_HARNESS_CODEX_ARGS_FILE_STUB = '1'
        }
        try {
            $proc = Invoke-NativeProcess -Executable 'powershell.exe' -Arguments $procArgs
            $exitCode = $proc.ExitCode
        }
        finally {
            $env:AI_HARNESS_CODEX_COMMAND = $previousEnv
            $env:AI_HARNESS_CODEX_ARGS_FILE_STUB = $previousStubFlag
        }
        $text = (($proc.Stdout + $proc.Stderr) -replace "`r`n", "`n").TrimEnd("`n")
        return [pscustomobject]@{
            ExitCode = $exitCode
            Output   = $text
        }
    }

    function script:Invoke-ReviewVerify {
        param(
            [string] $ProjectRoot,
            [string] $ReviewTaskId,
            [string] $Pass,
            [string] $ToolRoot,
            [string] $Perspective = 'local-correctness',
            [switch] $OmitPerspective
        )
        if ([string]::IsNullOrEmpty($ToolRoot)) { $ToolRoot = $script:RepoRoot }
        $procArgs = @(
            '-NoProfile', '-ExecutionPolicy', 'Bypass',
            '-File', $script:VerifyScript,
            '-ReviewTaskId', $ReviewTaskId,
            '-Pass', $Pass,
            '-ProjectRoot', $ProjectRoot,
            '-ToolRoot', $ToolRoot,
            '-RequireResult'
        )
        if ((-not $OmitPerspective) -and (-not [string]::IsNullOrEmpty($Perspective))) {
            $procArgs += @('-Perspective', $Perspective)
        }
        $proc = Invoke-NativeProcess -Executable 'powershell.exe' -Arguments $procArgs
        $text = (($proc.Stdout + $proc.Stderr) -replace "`r`n", "`n").TrimEnd("`n")
        return [pscustomobject]@{
            ExitCode = $proc.ExitCode
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

        $inputPath = Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-01/input.md')
        script:Set-InputFilled -InputPath $inputPath

        $stub = script:Write-CodexStub -StubName 'rr1-yes' -Mode 'verdict-yes'
        $r = script:Invoke-ReviewRun -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01' -StubPath $stub
        $r.ExitCode | Should -Be 0 -Because $r.Output
        $r.Output | Should -Match 'review-run: PASS'
        $r.Output | Should -Match 'verdict: yes'

        $passDir = Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-01')
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

        $inputPath = Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-01/input.md')
        Remove-Item -LiteralPath $inputPath -Force

        $stub = script:Write-CodexStub -StubName 'rr3-yes' -Mode 'verdict-yes'
        $r = script:Invoke-ReviewRun -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01' -StubPath $stub
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'input\.md not found'

        Test-Path -LiteralPath (Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-01/result.md')) -PathType Leaf | Should -BeFalse
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

        Test-Path -LiteralPath (Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-01/result.md')) -PathType Leaf | Should -BeFalse
    }

    It 'AC-RR5: result.md already present blocks re-run for the same pass (write-once)' {
        $project = script:New-RunCase -CaseName 'rr5'
        $taskId  = 'rr5-task'
        $prep = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01'
        $prep.ExitCode | Should -Be 0 -Because $prep.Output

        $inputPath = Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-01/input.md')
        script:Set-InputFilled -InputPath $inputPath

        $stub = script:Write-CodexStub -StubName 'rr5-yes' -Mode 'verdict-yes'
        $first = script:Invoke-ReviewRun -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01' -StubPath $stub
        $first.ExitCode | Should -Be 0 -Because $first.Output

        $resultMd = Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-01/result.md')
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

        $inputPath = Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-01/input.md')
        script:Set-InputFilled -InputPath $inputPath

        $stub = script:Write-CodexStub -StubName 'rr6-nv' -Mode 'no-verdict'
        $r = script:Invoke-ReviewRun -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01' -StubPath $stub
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'Could not parse verdict'

        $passDir = Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-01')
        Test-Path -LiteralPath $passDir                       -PathType Container | Should -BeTrue
        Test-Path -LiteralPath (Join-Path $passDir 'result.md') -PathType Leaf      | Should -BeTrue
        Test-Path -LiteralPath (Join-Path $passDir 'result.json') -PathType Leaf    | Should -BeFalse
    }

    It 'AC-RR7: corrective loop — pass-02 can run cleanly when pass-01 verdict was no' {
        $project = script:New-RunCase -CaseName 'rr7'
        $taskId  = 'rr7-task'

        $prep1 = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01'
        $prep1.ExitCode | Should -Be 0
        $input1 = Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-01/input.md')
        script:Set-InputFilled -InputPath $input1

        $stubNo = script:Write-CodexStub -StubName 'rr7-no' -Mode 'verdict-no'
        $r1 = script:Invoke-ReviewRun -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01' -StubPath $stubNo
        $r1.ExitCode | Should -Be 0 -Because $r1.Output
        $r1.Output | Should -Match 'verdict: no'

        # Allocate the next pass.
        $prep2 = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId
        $prep2.ExitCode | Should -Be 0 -Because $prep2.Output
        $prep2.Output | Should -Match 'pass: pass-02'
        $input2 = Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-02/input.md')
        script:Set-InputFilled -InputPath $input2

        $stubYes = script:Write-CodexStub -StubName 'rr7-yes' -Mode 'verdict-yes'
        $r2 = script:Invoke-ReviewRun -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-02' -StubPath $stubYes
        $r2.ExitCode | Should -Be 0 -Because $r2.Output
        $r2.Output | Should -Match 'verdict: yes'

        # Both passes exist on disk independently.
        Test-Path -LiteralPath (Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-01/result.md')) -PathType Leaf | Should -BeTrue
        Test-Path -LiteralPath (Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-02/result.md')) -PathType Leaf | Should -BeTrue
    }

    It 'AC-RR8: non-codex reviewer fails with the MVP boundary message' {
        $project = script:New-RunCase -CaseName 'rr8'
        $taskId  = 'rr8-task'
        $prep = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01'
        $prep.ExitCode | Should -Be 0 -Because $prep.Output
        $inputPath = Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-01/input.md')
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
        $inputPath = Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-01/input.md')
        script:Set-InputFilled -InputPath $inputPath

        $stub = script:Write-CodexStub -StubName 'rr10-title' -Mode 'verdict-title-yes'
        $r = script:Invoke-ReviewRun -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01' -StubPath $stub
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'Could not parse verdict'

        $passDir = Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-01')
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

        $inputPath = Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-01/input.md')
        script:Set-InputFilled -InputPath $inputPath

        $stub = script:Write-CodexStub -StubName 'rr11-yes' -Mode 'verdict-yes'
        $r = script:Invoke-ReviewRun -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01' -StubPath $stub
        $r.ExitCode | Should -Be 0 -Because $r.Output

        $resultMd = Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-01/result.md')
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
        # RV-B-05 V2 four required disclosure H2s must be named in the preamble so
        # the reviewer produces them; without this the post-Codex review-verify
        # -RequireResult rejects any result.md missing one.
        $stdin | Should -Match '## Blocking findings'
        $stdin | Should -Match '## Non-blocking concerns'
        $stdin | Should -Match '## Review limitations'
        $stdin | Should -Match '## Assumptions relied on'
        # Each V2 H2 must appear inside the preamble (before the closing BEGIN REVIEW
        # INPUT delimiter line), not only as a side-effect of being mentioned somewhere
        # in the input.md. The delimiter line is anchored with the leading "=====" so it
        # does not collide with the descriptive sentence "...the BEGIN REVIEW INPUT
        # marker below..." earlier in the preamble.
        $beginMarker = $stdin.IndexOf('===== BEGIN REVIEW INPUT')
        $beginMarker | Should -BeGreaterThan 0
        ($stdin.IndexOf('## Blocking findings'))     | Should -BeLessThan $beginMarker
        ($stdin.IndexOf('## Non-blocking concerns')) | Should -BeLessThan $beginMarker
        ($stdin.IndexOf('## Review limitations'))    | Should -BeLessThan $beginMarker
        ($stdin.IndexOf('## Assumptions relied on')) | Should -BeLessThan $beginMarker
        # RV-B-05 Batch II (light P3 wording) + Stage 4-R1 (Counter-argument
        # runtime alignment): the preamble must instruct the reviewer to
        # articulate the strongest case AGAINST its own conclusion in
        # ## Counter-argument (per REVIEW_RESULT_CONTRACT.md §3c, the dedicated
        # pressure-test surface) before issuing the verdict. Wording-only; no
        # new parser-required H2 (## Counter-argument remains optional /
        # strongly-recommended / non-parser).
        $stdin | Should -Match 'strongest case AGAINST'
        $stdin | Should -Match 'pressure-test'
        $stdin | Should -Match '## Counter-argument'
        ($stdin.IndexOf('strongest case AGAINST')) | Should -BeLessThan $beginMarker
        ($stdin.IndexOf('pressure-test'))          | Should -BeLessThan $beginMarker
        ($stdin.IndexOf('## Counter-argument'))    | Should -BeLessThan $beginMarker
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

    It 'AC-RR12: wrong-case ## verdict heading is not treated as the canonical Verdict heading (H2 case-sensitivity regression)' {
        # Mirrors review-verify AC-VF-RR18: review-run's Get-VerdictFromResultMd must
        # reject "## verdict" (lowercase) so it does not silently extract a verdict line
        # from a result.md whose heading would be rejected by review-verify -RequireResult
        # downstream. With case-sensitive matching the function returns '' and review-run
        # reports "Could not parse verdict".
        $project = script:New-RunCase -CaseName 'rr12'
        $taskId  = 'rr12-task'
        $prep = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01'
        $prep.ExitCode | Should -Be 0 -Because $prep.Output
        $inputPath = Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-01/input.md')
        script:Set-InputFilled -InputPath $inputPath

        $stub = script:Write-CodexStub -StubName 'rr12-lower' -Mode 'verdict-lowercase-heading'
        $r = script:Invoke-ReviewRun -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01' -StubPath $stub
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'Could not parse verdict'

        $passDir = Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-01')
        Test-Path -LiteralPath (Join-Path $passDir 'result.md') -PathType Leaf | Should -BeTrue
    }

    It 'AC-RR13: default reasoning effort resolves to config (xhigh) and is passed as -c model_reasoning_effort=xhigh' {
        # Batch B: per-invocation effort override wiring. With no -Effort, review-run
        # resolves config/reviewer.json reasoningEffort (xhigh) and passes it to Codex.
        $project = script:New-RunCase -CaseName 'rr13'
        $taskId  = 'rr13-task'
        $prep = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01'
        $prep.ExitCode | Should -Be 0 -Because $prep.Output
        $inputPath = Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-01/input.md')
        script:Set-InputFilled -InputPath $inputPath

        $stub = script:Write-CodexStub -StubName 'rr13-yes' -Mode 'verdict-yes'
        $r = script:Invoke-ReviewRun -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01' -StubPath $stub
        $r.ExitCode | Should -Be 0 -Because $r.Output
        $r.Output | Should -Match 'requested-effort: xhigh'
        $r.Output | Should -Match 'effort-source: config'
        $r.Output | Should -Match 'applied-effort: xhigh'

        # The effort override is actually present in the argv passed to Codex.
        $resultMd = Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-01/result.md')
        $argvCapture = $resultMd + '.argv.txt'
        Test-Path -LiteralPath $argvCapture -PathType Leaf | Should -BeTrue
        $enc = New-Object System.Text.UTF8Encoding($false)
        $argv = [System.IO.File]::ReadAllText($argvCapture, $enc)
        $argv | Should -Match 'model_reasoning_effort=xhigh'
    }

    It 'AC-RR14: explicit -Effort medium overrides config and is the distinct downgrade path' {
        $project = script:New-RunCase -CaseName 'rr14'
        $taskId  = 'rr14-task'
        $prep = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01'
        $prep.ExitCode | Should -Be 0 -Because $prep.Output
        $inputPath = Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-01/input.md')
        script:Set-InputFilled -InputPath $inputPath

        $stub = script:Write-CodexStub -StubName 'rr14-yes' -Mode 'verdict-yes'
        $r = script:Invoke-ReviewRun -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01' -StubPath $stub -Effort 'medium'
        $r.ExitCode | Should -Be 0 -Because $r.Output
        $r.Output | Should -Match 'requested-effort: medium'
        $r.Output | Should -Match 'effort-source: explicit'
        $r.Output | Should -Match 'applied-effort: medium'

        $resultMd = Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-01/result.md')
        $enc = New-Object System.Text.UTF8Encoding($false)
        $argv = [System.IO.File]::ReadAllText(($resultMd + '.argv.txt'), $enc)
        $argv | Should -Match 'model_reasoning_effort=medium'
        $argv | Should -Not -Match 'model_reasoning_effort=xhigh'
    }

    It 'AC-RR15: invalid -Effort fails fast before Codex is invoked (no silent fallback)' {
        $project = script:New-RunCase -CaseName 'rr15'
        $taskId  = 'rr15-task'
        $prep = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01'
        $prep.ExitCode | Should -Be 0 -Because $prep.Output
        $inputPath = Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-01/input.md')
        script:Set-InputFilled -InputPath $inputPath

        $stub = script:Write-CodexStub -StubName 'rr15-yes' -Mode 'verdict-yes'
        $r = script:Invoke-ReviewRun -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01' -StubPath $stub -Effort 'bogus_value'
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'invalid reasoning effort'

        # Fail-fast is before Codex: no result.md is produced.
        Test-Path -LiteralPath (Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-01/result.md')) -PathType Leaf | Should -BeFalse
    }

    It 'AC-RR16: applied-effort is reported not-observed when the reviewer emits no effort header (no silent success)' {
        # Honesty path: if the applied-effort run-fact cannot be observed in the Codex
        # stderr header, review-run reports not-observed rather than echoing the request.
        $project = script:New-RunCase -CaseName 'rr16'
        $taskId  = 'rr16-task'
        $prep = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01'
        $prep.ExitCode | Should -Be 0 -Because $prep.Output
        $inputPath = Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-01/input.md')
        script:Set-InputFilled -InputPath $inputPath

        $stub = script:Write-CodexStub -StubName 'rr16-yes' -Mode 'verdict-yes' -EmitEffortHeader $false
        $r = script:Invoke-ReviewRun -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01' -StubPath $stub
        $r.ExitCode | Should -Be 0 -Because $r.Output
        $r.Output | Should -Match 'requested-effort: xhigh'
        $r.Output | Should -Match 'applied-effort: not-observed'
    }

    It 'AC-RR17: wrong-case -Effort (e.g. XHIGH) fails fast before Codex (case-sensitive membership)' {
        # The allowed effort set is exact lowercase; PowerShell -notcontains would let a
        # wrong-case value reach Codex. review-run uses -cnotcontains so wrong case fails
        # fast at the runner with no Codex invocation.
        $project = script:New-RunCase -CaseName 'rr17'
        $taskId  = 'rr17-task'
        $prep = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01'
        $prep.ExitCode | Should -Be 0 -Because $prep.Output
        $inputPath = Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-01/input.md')
        script:Set-InputFilled -InputPath $inputPath

        $stub = script:Write-CodexStub -StubName 'rr17-yes' -Mode 'verdict-yes'
        $r = script:Invoke-ReviewRun -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01' -StubPath $stub -Effort 'XHIGH'
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'invalid reasoning effort'

        Test-Path -LiteralPath (Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-01/result.md')) -PathType Leaf | Should -BeFalse
    }

    It 'AC-RR18: reviewer-safe hardening — --ignore-user-config is passed to Codex (Batch C)' {
        # Batch C: review-run must pass --ignore-user-config so the reviewer-safe posture does not
        # depend on flag-precedence over a permissive global config (the config is not loaded).
        $project = script:New-RunCase -CaseName 'rr18'
        $taskId  = 'rr18-task'
        $prep = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01'
        $prep.ExitCode | Should -Be 0 -Because $prep.Output
        $inputPath = Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-01/input.md')
        script:Set-InputFilled -InputPath $inputPath

        $stub = script:Write-CodexStub -StubName 'rr18-yes' -Mode 'verdict-yes'
        $r = script:Invoke-ReviewRun -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01' -StubPath $stub
        $r.ExitCode | Should -Be 0 -Because $r.Output

        $resultMd = Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-01/result.md')
        $enc = New-Object System.Text.UTF8Encoding($false)
        $argv = [System.IO.File]::ReadAllText(($resultMd + '.argv.txt'), $enc)
        $argv | Should -Match '--ignore-user-config'
    }

    It 'AC-RR19: missing config model fails fast before Codex (no built-in model fallback)' {
        # Model fallback removal: with a config that has no "model", review-run must fail fast and
        # not invoke Codex (no hardcoded version masks the missing source-of-truth).
        $project = script:New-RunCase -CaseName 'rr19'
        $taskId  = 'rr19-task'
        $prep = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01'
        $prep.ExitCode | Should -Be 0 -Because $prep.Output
        $inputPath = Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-01/input.md')
        script:Set-InputFilled -InputPath $inputPath

        $modelless = script:New-ModellessToolRoot -CaseName 'rr19'
        $stub = script:Write-CodexStub -StubName 'rr19-yes' -Mode 'verdict-yes'
        $r = script:Invoke-ReviewRun -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01' -StubPath $stub -ToolRoot $modelless
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'reviewer model could not be resolved'

        # Codex was not invoked: no result.md.
        Test-Path -LiteralPath (Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-01/result.md')) -PathType Leaf | Should -BeFalse
    }

    It 'AC-RR20: explicit -Model overrides the config model (precedence: explicit > config)' {
        # explicit -Model > config model > fail-fast. An explicit -Model must win and be the value
        # passed to Codex; the configured model (whatever it currently is) must NOT be passed. The
        # config model is read dynamically so this test is not coupled to a concrete model version.
        $project = script:New-RunCase -CaseName 'rr20'
        $taskId  = 'rr20-task'
        $prep = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01'
        $prep.ExitCode | Should -Be 0 -Because $prep.Output
        $inputPath = Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-01/input.md')
        script:Set-InputFilled -InputPath $inputPath

        $stub = script:Write-CodexStub -StubName 'rr20-yes' -Mode 'verdict-yes'
        $r = script:Invoke-ReviewRun -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01' -StubPath $stub -Model 'explicit-test-model-x'
        $r.ExitCode | Should -Be 0 -Because $r.Output

        $resultMd = Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-01/result.md')
        $enc = New-Object System.Text.UTF8Encoding($false)
        $argv = [System.IO.File]::ReadAllText(($resultMd + '.argv.txt'), $enc)
        $argv | Should -Match 'explicit-test-model-x'
        $cfgModel = (([System.IO.File]::ReadAllText((Join-Path $script:RepoRoot 'config/reviewer.json'), $enc)) | ConvertFrom-Json).model
        $argv | Should -Not -Match ([regex]::Escape([string]$cfgModel))
    }

    It 'AC-RR21: config-resolved model emits model: <value> and model-source: config (Batch D2)' {
        # Batch D2 run-fact expansion: with no -Model, review-run resolves config/reviewer.json
        # and emits both the resolved model value and model-source: config. The model value is
        # read dynamically from config (no concrete version hardcoded in this test or the runner).
        $project = script:New-RunCase -CaseName 'rr21'
        $taskId  = 'rr21-task'
        $prep = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01'
        $prep.ExitCode | Should -Be 0 -Because $prep.Output
        $inputPath = Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-01/input.md')
        script:Set-InputFilled -InputPath $inputPath

        $stub = script:Write-CodexStub -StubName 'rr21-yes' -Mode 'verdict-yes'
        $r = script:Invoke-ReviewRun -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01' -StubPath $stub
        $r.ExitCode | Should -Be 0 -Because $r.Output
        $r.Output | Should -Match '(?m)^model-source: config$'
        $r.Output | Should -Not -Match '(?m)^model-source: explicit$'

        $enc = New-Object System.Text.UTF8Encoding($false)
        $cfgModel = (([System.IO.File]::ReadAllText((Join-Path $script:RepoRoot 'config/reviewer.json'), $enc)) | ConvertFrom-Json).model
        $r.Output | Should -Match ('(?m)^model: ' + [regex]::Escape([string]$cfgModel) + '$')
    }

    It 'AC-RR22: explicit -Model emits model-source: explicit and the explicit model value (Batch D2)' {
        $project = script:New-RunCase -CaseName 'rr22'
        $taskId  = 'rr22-task'
        $prep = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01'
        $prep.ExitCode | Should -Be 0 -Because $prep.Output
        $inputPath = Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-01/input.md')
        script:Set-InputFilled -InputPath $inputPath

        $stub = script:Write-CodexStub -StubName 'rr22-yes' -Mode 'verdict-yes'
        $r = script:Invoke-ReviewRun -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01' -StubPath $stub -Model 'explicit-test-model-x'
        $r.ExitCode | Should -Be 0 -Because $r.Output
        $r.Output | Should -Match '(?m)^model: explicit-test-model-x$'
        $r.Output | Should -Match '(?m)^model-source: explicit$'
        $r.Output | Should -Not -Match '(?m)^model-source: config$'
    }

    It 'AC-RR23: reviewer-safe-posture run-fact lists the structural safety flags only (Batch D2)' {
        # The posture run-fact reflects the structural flags actually passed in this invocation;
        # it is the posture flags only, never a blanket safety guarantee (the tested-vectors-only
        # caveat lives in the docs/report layer). All four flags appear on the single posture line.
        $project = script:New-RunCase -CaseName 'rr23'
        $taskId  = 'rr23-task'
        $prep = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01'
        $prep.ExitCode | Should -Be 0 -Because $prep.Output
        $inputPath = Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-01/input.md')
        script:Set-InputFilled -InputPath $inputPath

        $stub = script:Write-CodexStub -StubName 'rr23-yes' -Mode 'verdict-yes'
        $r = script:Invoke-ReviewRun -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01' -StubPath $stub
        $r.ExitCode | Should -Be 0 -Because $r.Output
        # Exact-line: the posture run-fact is the four structural flags in this fixed order
        # and nothing else (no blanket-guarantee text appended).
        $r.Output | Should -Match '(?m)^reviewer-safe-posture: --ask-for-approval never --sandbox read-only --ignore-user-config web_search=disabled$'
    }

    It 'AC-RR24: engine identity run-facts (tool-root / project-root / tool-root-source) are emitted (Batch D2)' {
        # The engine ToolRoot/ProjectRoot/tool-root-source the runner actually resolved, for
        # operator debugging. -ToolRoot is passed explicitly by the harness, so tool-root-source
        # is 'explicit'. Paths are debugging run-facts, not source-of-truth claims.
        $project = script:New-RunCase -CaseName 'rr24'
        $taskId  = 'rr24-task'
        $prep = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01'
        $prep.ExitCode | Should -Be 0 -Because $prep.Output
        $inputPath = Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-01/input.md')
        script:Set-InputFilled -InputPath $inputPath

        $stub = script:Write-CodexStub -StubName 'rr24-yes' -Mode 'verdict-yes'
        $r = script:Invoke-ReviewRun -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01' -StubPath $stub
        $r.ExitCode | Should -Be 0 -Because $r.Output
        $r.Output | Should -Match '(?m)^tool-root-source: explicit$'
        # Exact-line: assert the engine-identity run-facts carry the actually-resolved path
        # VALUES (not just the labels), anchored so a suffixed value (e.g. <project>\log)
        # cannot match. project-root is the resolved ProjectRoot and tool-root is the
        # resolved (explicit) ToolRoot the harness passed; Get-ProjectRoot / Get-ToolRoot
        # return GetFullPath of those inputs, so the expected values are the GetFullPath forms.
        $expectedProject = [System.IO.Path]::GetFullPath($project)
        $expectedTool    = [System.IO.Path]::GetFullPath($script:RepoRoot)
        $r.Output | Should -Match ('(?m)^project-root: ' + [regex]::Escape($expectedProject) + '$')
        $r.Output | Should -Match ('(?m)^tool-root: ' + [regex]::Escape($expectedTool) + '$')
    }

    It 'AC-RR25: reviewer kind and adapter-version run-facts are emitted, additive to Batch D2 (P2)' {
        # P2: emit the active reviewer adapter kind and a runtime-observed adapter version as
        # H1 stdout run-facts. reviewer = the resolved adapter (codex in MVP); reviewer-version
        # is parsed from the adapter run banner. The stub emits a CONTROLLED non-real version
        # (9.9.9-stub), so this assertion is not coupled to any real external version.
        $project = script:New-RunCase -CaseName 'rr25'
        $taskId  = 'rr25-task'
        $prep = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01'
        $prep.ExitCode | Should -Be 0 -Because $prep.Output
        $inputPath = Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-01/input.md')
        script:Set-InputFilled -InputPath $inputPath

        $stub = script:Write-CodexStub -StubName 'rr25-yes' -Mode 'verdict-yes'
        $r = script:Invoke-ReviewRun -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01' -StubPath $stub
        $r.ExitCode | Should -Be 0 -Because $r.Output
        # Exact-line anchored: new reviewer kind/version run-facts.
        $r.Output | Should -Match '(?m)^reviewer: codex$'
        $r.Output | Should -Match '(?m)^reviewer-version: 9\.9\.9-stub$'
        $r.Output | Should -Not -Match '(?m)^reviewer-version: not-observed$'
        # Additive: existing Batch D2 run-facts are preserved alongside the new lines.
        $r.Output | Should -Match '(?m)^model-source: config$'
        $r.Output | Should -Match '(?m)^applied-effort: xhigh$'
        $r.Output | Should -Match '(?m)^reviewer-safe-posture: --ask-for-approval never --sandbox read-only --ignore-user-config web_search=disabled$'
        $r.Output | Should -Match '(?m)^tool-root-source: explicit$'
    }

    It 'AC-RR26: adapter version falls back to not-observed when the run banner carries no version (no silent success)' {
        # Honesty path: when the active adapter reports no parseable version in its run banner,
        # review-run emits reviewer-version: not-observed rather than inventing or hardcoding one.
        # reviewer kind is still emitted.
        $project = script:New-RunCase -CaseName 'rr26'
        $taskId  = 'rr26-task'
        $prep = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01'
        $prep.ExitCode | Should -Be 0 -Because $prep.Output
        $inputPath = Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-01/input.md')
        script:Set-InputFilled -InputPath $inputPath

        $stub = script:Write-CodexStub -StubName 'rr26-yes' -Mode 'verdict-yes' -EmitVersionHeader $false
        $r = script:Invoke-ReviewRun -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01' -StubPath $stub
        $r.ExitCode | Should -Be 0 -Because $r.Output
        $r.Output | Should -Match '(?m)^reviewer: codex$'
        $r.Output | Should -Match '(?m)^reviewer-version: not-observed$'
    }

    It 'AC-RR27: P3 — result.md gets a runner-appended provenance block and still passes review-verify -RequireResult' {
        # P3: review-run persists runtime provenance INSIDE result.md as a runner-appended block.
        # The reviewer body is a full result (verdict + four disclosure H2s); after the block is
        # appended, review-verify -RequireResult must still pass (the block adds no parser-gated
        # heading and does not duplicate ## Verdict). Provenance values are exact-line asserted
        # against controlled stub values (reviewer-version 9.9.9-stub is non-real).
        $project = script:New-RunCase -CaseName 'rr27'
        $taskId  = 'rr27-task'
        $prep = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01'
        $prep.ExitCode | Should -Be 0 -Because $prep.Output
        $inputPath = Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-01/input.md')
        script:Set-InputFilled -InputPath $inputPath

        $stub = script:Write-CodexStub -StubName 'rr27-full' -Mode 'verdict-yes-full'
        $r = script:Invoke-ReviewRun -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01' -StubPath $stub
        $r.ExitCode | Should -Be 0 -Because $r.Output
        # Stdout reports the persistence (additive H1 run-fact; P2 lines unchanged).
        $r.Output | Should -Match '(?m)^provenance-persisted: '
        $r.Output | Should -Not -Match '(?m)^provenance-persisted: FAILED'

        $resultMd = Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-01/result.md')
        $enc = New-Object System.Text.UTF8Encoding($false)
        $content = [System.IO.File]::ReadAllText($resultMd, $enc)

        # The runner block is present and demarcated.
        $content | Should -Match '(?m)^## Reviewer run provenance$'
        $content | Should -Match 'Machine-emitted by'
        # Exact-line provenance values (controlled stub values; no real external version asserted).
        $content | Should -Match '(?m)^reviewer: codex$'
        $content | Should -Match '(?m)^reviewer-version: 9\.9\.9-stub$'
        $content | Should -Match '(?m)^model-source: config$'
        $content | Should -Match '(?m)^requested-effort: xhigh$'
        $content | Should -Match '(?m)^effort-source: config$'
        $content | Should -Match '(?m)^applied-effort: xhigh$'
        $content | Should -Match '(?m)^reviewer-safe-posture: --ask-for-approval never --sandbox read-only --ignore-user-config web_search=disabled$'
        $content | Should -Match '(?m)^tool-root-source: explicit$'
        # The model value is read dynamically from config (no concrete version hardcoded in this test).
        $cfgModel = (([System.IO.File]::ReadAllText((Join-Path $script:RepoRoot 'config/reviewer.json'), $enc)) | ConvertFrom-Json).model
        $content | Should -Match ('(?m)^model: ' + [regex]::Escape([string]$cfgModel) + '$')

        # The reviewer-authored body is preserved: exactly one ## Verdict, all four disclosure
        # H2s. Count the same way review-verify does (line split + TrimEnd -ceq) so the assertion
        # is EOL-agnostic (the reviewer body may be CRLF while the appended block is LF).
        $lines = $content -split "`r?`n"
        (@($lines | Where-Object { $_.TrimEnd() -ceq '## Verdict' })).Count | Should -Be 1
        (@($lines | Where-Object { $_.TrimEnd() -ceq '## Blocking findings' })).Count | Should -Be 1
        (@($lines | Where-Object { $_.TrimEnd() -ceq '## Non-blocking concerns' })).Count | Should -Be 1
        (@($lines | Where-Object { $_.TrimEnd() -ceq '## Review limitations' })).Count | Should -Be 1
        (@($lines | Where-Object { $_.TrimEnd() -ceq '## Assumptions relied on' })).Count | Should -Be 1
        # The appended runner block must not have introduced a second ## Verdict.
        (@($lines | Where-Object { $_.TrimEnd() -ceq '## Reviewer run provenance' })).Count | Should -Be 1

        # The block does NOT break the canonical-artifact gate.
        $v = script:Invoke-ReviewVerify -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01'
        $v.ExitCode | Should -Be 0 -Because $v.Output
        $v.Output | Should -Match 'result\.md verdict shape valid \(verdict=yes\)'
        $v.Output | Should -Match 'disclosure sections present'
    }

    It 'AC-RR28: P3 — not-observed version is persisted in the provenance block (no silent success)' {
        # Honesty path persisted: with no version banner, the block records reviewer-version:
        # not-observed (not a fabricated or hardcoded value), and review-verify still passes.
        $project = script:New-RunCase -CaseName 'rr28'
        $taskId  = 'rr28-task'
        $prep = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01'
        $prep.ExitCode | Should -Be 0 -Because $prep.Output
        $inputPath = Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-01/input.md')
        script:Set-InputFilled -InputPath $inputPath

        $stub = script:Write-CodexStub -StubName 'rr28-full' -Mode 'verdict-yes-full' -EmitVersionHeader $false
        $r = script:Invoke-ReviewRun -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01' -StubPath $stub
        $r.ExitCode | Should -Be 0 -Because $r.Output

        $resultMd = Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-01/result.md')
        $enc = New-Object System.Text.UTF8Encoding($false)
        $content = [System.IO.File]::ReadAllText($resultMd, $enc)
        $content | Should -Match '(?m)^## Reviewer run provenance$'
        $content | Should -Match '(?m)^reviewer-version: not-observed$'

        $v = script:Invoke-ReviewVerify -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01'
        $v.ExitCode | Should -Be 0 -Because $v.Output
    }

    It 'AC-RR29: no -EffortCategory preserves scalar config behavior and emits none category run-facts (U9)' {
        # U9: with no category supplied, behavior is identical to the pre-U9 scalar path
        # (effort-source: config), and the new run-facts report the not-supplied state.
        $project = script:New-RunCase -CaseName 'rr29'
        $taskId  = 'rr29-task'
        $prep = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01'
        $prep.ExitCode | Should -Be 0 -Because $prep.Output
        $inputPath = Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-01/input.md')
        script:Set-InputFilled -InputPath $inputPath

        $stub = script:Write-CodexStub -StubName 'rr29-yes' -Mode 'verdict-yes'
        $r = script:Invoke-ReviewRun -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01' -StubPath $stub
        $r.ExitCode | Should -Be 0 -Because $r.Output
        $r.Output | Should -Match '(?m)^effort-category: none$'
        $r.Output | Should -Match '(?m)^effort-policy-match: none$'
        # Scalar path unchanged: effort + model still resolve from config (not category).
        $r.Output | Should -Match '(?m)^effort-source: config$'
        $r.Output | Should -Match '(?m)^model-source: config$'
        $r.Output | Should -Not -Match '(?m)^effort-source: category$'
        $r.Output | Should -Not -Match '(?m)^model-source: category$'
    }

    It 'AC-RR30: matched -EffortCategory applies the category {model,effort} and emits matched run-facts (U9)' {
        # U9 end-to-end: a matched category with DISTINCT values (simple-local = fixture-simple-model
        # + medium) must flow into the Codex argv and be reported with source: category. Proves the
        # lookup wires both axes, not just that a run-fact label exists.
        $project = script:New-RunCase -CaseName 'rr30'
        $taskId  = 'rr30-task'
        $prep = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01'
        $prep.ExitCode | Should -Be 0 -Because $prep.Output
        $inputPath = Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-01/input.md')
        script:Set-InputFilled -InputPath $inputPath

        $toolRoot = script:New-CategoryToolRoot -CaseName 'rr30'
        $stub = script:Write-CodexStub -StubName 'rr30-yes' -Mode 'verdict-yes'
        $r = script:Invoke-ReviewRun -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01' -StubPath $stub -EffortCategory 'simple-local' -ToolRoot $toolRoot
        $r.ExitCode | Should -Be 0 -Because $r.Output
        $r.Output | Should -Match '(?m)^effort-category: simple-local$'
        $r.Output | Should -Match '(?m)^effort-policy-match: matched$'
        $r.Output | Should -Match '(?m)^requested-effort: medium$'
        $r.Output | Should -Match '(?m)^effort-source: category$'
        $r.Output | Should -Match '(?m)^applied-effort: medium$'
        $r.Output | Should -Match '(?m)^model: fixture-simple-model$'
        $r.Output | Should -Match '(?m)^model-source: category$'

        # The category values are actually present in the Codex argv.
        $resultMd = Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-01/result.md')
        $enc = New-Object System.Text.UTF8Encoding($false)
        $argv = [System.IO.File]::ReadAllText(($resultMd + '.argv.txt'), $enc)
        $argv | Should -Match 'model_reasoning_effort=medium'
        $argv | Should -Not -Match 'model_reasoning_effort=xhigh'
        $argv | Should -Match 'fixture-simple-model'
        $argv | Should -Not -Match 'fixture-scalar-model'
    }

    It 'AC-RR31: missed -EffortCategory falls back to scalar config and emits missed run-facts (U9, soft fallback)' {
        # U9: a supplied category that is not present in categoryPolicy is a SOFT miss — it falls
        # back to the scalar config (effort-source: config), it does not fail hard. The real repo
        # config has a categoryPolicy but not this key.
        $project = script:New-RunCase -CaseName 'rr31'
        $taskId  = 'rr31-task'
        $prep = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01'
        $prep.ExitCode | Should -Be 0 -Because $prep.Output
        $inputPath = Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-01/input.md')
        script:Set-InputFilled -InputPath $inputPath

        $stub = script:Write-CodexStub -StubName 'rr31-yes' -Mode 'verdict-yes'
        $r = script:Invoke-ReviewRun -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01' -StubPath $stub -EffortCategory 'no-such-category-xyz'
        $r.ExitCode | Should -Be 0 -Because $r.Output
        $r.Output | Should -Match '(?m)^effort-category: no-such-category-xyz$'
        $r.Output | Should -Match '(?m)^effort-policy-match: missed$'
        # Soft fallback to the scalar config default (xhigh), not a hard failure.
        $r.Output | Should -Match '(?m)^requested-effort: xhigh$'
        $r.Output | Should -Match '(?m)^effort-source: config$'
        $r.Output | Should -Match '(?m)^model-source: config$'
    }

    It 'AC-RR32: explicit -Effort wins over a matched -EffortCategory (per-axis precedence; U9)' {
        # Precedence axis 1 (effort): explicit -Effort overrides the matched category effort, but the
        # category MODEL still applies (no -Model). effort-policy-match still reports matched.
        $project = script:New-RunCase -CaseName 'rr32'
        $taskId  = 'rr32-task'
        $prep = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01'
        $prep.ExitCode | Should -Be 0 -Because $prep.Output
        $inputPath = Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-01/input.md')
        script:Set-InputFilled -InputPath $inputPath

        $toolRoot = script:New-CategoryToolRoot -CaseName 'rr32'
        $stub = script:Write-CodexStub -StubName 'rr32-yes' -Mode 'verdict-yes'
        $r = script:Invoke-ReviewRun -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01' -StubPath $stub -EffortCategory 'simple-local' -Effort 'high' -ToolRoot $toolRoot
        $r.ExitCode | Should -Be 0 -Because $r.Output
        $r.Output | Should -Match '(?m)^requested-effort: high$'
        $r.Output | Should -Match '(?m)^effort-source: explicit$'
        $r.Output | Should -Match '(?m)^applied-effort: high$'
        # Category model still applies for the non-overridden axis.
        $r.Output | Should -Match '(?m)^model-source: category$'
        $r.Output | Should -Match '(?m)^effort-policy-match: matched$'

        $resultMd = Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-01/result.md')
        $enc = New-Object System.Text.UTF8Encoding($false)
        $argv = [System.IO.File]::ReadAllText(($resultMd + '.argv.txt'), $enc)
        $argv | Should -Match 'model_reasoning_effort=high'
        $argv | Should -Not -Match 'model_reasoning_effort=medium'
    }

    It 'AC-RR33: explicit -Model wins over a matched -EffortCategory model (per-axis precedence; U9)' {
        # Precedence axis 2 (model): explicit -Model overrides the matched category model, but the
        # category EFFORT still applies (no -Effort).
        $project = script:New-RunCase -CaseName 'rr33'
        $taskId  = 'rr33-task'
        $prep = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01'
        $prep.ExitCode | Should -Be 0 -Because $prep.Output
        $inputPath = Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-01/input.md')
        script:Set-InputFilled -InputPath $inputPath

        $toolRoot = script:New-CategoryToolRoot -CaseName 'rr33'
        $stub = script:Write-CodexStub -StubName 'rr33-yes' -Mode 'verdict-yes'
        $r = script:Invoke-ReviewRun -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01' -StubPath $stub -EffortCategory 'simple-local' -Model 'explicit-model-z' -ToolRoot $toolRoot
        $r.ExitCode | Should -Be 0 -Because $r.Output
        $r.Output | Should -Match '(?m)^model: explicit-model-z$'
        $r.Output | Should -Match '(?m)^model-source: explicit$'
        # Category effort still applies for the non-overridden axis.
        $r.Output | Should -Match '(?m)^requested-effort: medium$'
        $r.Output | Should -Match '(?m)^effort-source: category$'

        $resultMd = Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-01/result.md')
        $enc = New-Object System.Text.UTF8Encoding($false)
        $argv = [System.IO.File]::ReadAllText(($resultMd + '.argv.txt'), $enc)
        $argv | Should -Match 'explicit-model-z'
        $argv | Should -Not -Match 'fixture-simple-model'
    }

    It 'AC-RR34: matched category with an out-of-enum effort fails fast before Codex (source: category)' {
        # A matched category whose reasoningEffort is out of the allowed set is a config error and
        # fails fast at the runner (source: category), exactly like the scalar/explicit path, before
        # any Codex invocation. No silent fallback to the scalar default.
        $project = script:New-RunCase -CaseName 'rr34'
        $taskId  = 'rr34-task'
        $prep = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01'
        $prep.ExitCode | Should -Be 0 -Because $prep.Output
        $inputPath = Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-01/input.md')
        script:Set-InputFilled -InputPath $inputPath

        $toolRoot = script:New-CategoryToolRoot -CaseName 'rr34'
        $stub = script:Write-CodexStub -StubName 'rr34-yes' -Mode 'verdict-yes'
        $r = script:Invoke-ReviewRun -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01' -StubPath $stub -EffortCategory 'broken' -ToolRoot $toolRoot
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'invalid reasoning effort'
        $r.Output | Should -Match 'source: category'

        # Fail-fast is before Codex: no result.md.
        Test-Path -LiteralPath (Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-01/result.md')) -PathType Leaf | Should -BeFalse
    }

    It 'AC-RR35: shipped config/reviewer.json categoryPolicy keeps every category at the safe floor (xhigh)' {
        # Safety regression: this batch ships every category at the safe default (xhigh). A category
        # accidentally tuned below xhigh would lower review effort silently; pin the floor as a test.
        # Per-category VALUE tuning below the floor is a deliberate, separately-reviewed future step.
        $enc = New-Object System.Text.UTF8Encoding($false)
        $cfg = [System.IO.File]::ReadAllText((Join-Path $script:RepoRoot 'config/reviewer.json'), $enc) | ConvertFrom-Json
        $cfg.PSObject.Properties['categoryPolicy'] | Should -Not -BeNullOrEmpty -Because 'shipped config must carry the U9 categoryPolicy map'
        $entries = @($cfg.categoryPolicy.PSObject.Properties)
        $entries.Count | Should -BeGreaterThan 0
        foreach ($p in $entries) {
            ([string]$p.Value.reasoningEffort) | Should -BeExactly 'xhigh' -Because ('category ' + $p.Name + ' must ship at the safe floor xhigh')
        }
        # Scalar default unchanged.
        ([string]$cfg.reasoningEffort) | Should -BeExactly 'xhigh'
    }

    It 'AC-RR36: U9 category run-facts are persisted in the result.md provenance block (P3 parallel)' {
        # The provenance block mirrors the stdout run-facts; the two U9 category lines must appear in
        # the persisted block too, and the block must still pass review-verify -RequireResult.
        $project = script:New-RunCase -CaseName 'rr36'
        $taskId  = 'rr36-task'
        $prep = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01'
        $prep.ExitCode | Should -Be 0 -Because $prep.Output
        $inputPath = Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-01/input.md')
        script:Set-InputFilled -InputPath $inputPath

        $toolRoot = script:New-CategoryToolRoot -CaseName 'rr36'
        $stub = script:Write-CodexStub -StubName 'rr36-full' -Mode 'verdict-yes-full'
        $r = script:Invoke-ReviewRun -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01' -StubPath $stub -EffortCategory 'simple-local' -ToolRoot $toolRoot
        $r.ExitCode | Should -Be 0 -Because $r.Output

        $resultMd = Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-01/result.md')
        $enc = New-Object System.Text.UTF8Encoding($false)
        $content = [System.IO.File]::ReadAllText($resultMd, $enc)
        $content | Should -Match '(?m)^## Reviewer run provenance$'
        $content | Should -Match '(?m)^effort-category: simple-local$'
        $content | Should -Match '(?m)^effort-policy-match: matched$'
        $content | Should -Match '(?m)^effort-source: category$'

        $v = script:Invoke-ReviewVerify -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01'
        $v.ExitCode | Should -Be 0 -Because $v.Output
    }

    It 'AC-RR37: matched category missing required reasoningEffort fails fast before Codex (no silent scalar fallback)' {
        # A matched category entry is authoritative for effort: reasoningEffort is schema-required.
        # If a matched entry omits it, review-run must fail fast (config error) rather than silently
        # falling back to the scalar default while still reporting effort-policy-match: matched — that
        # would hide a category-config typo. Fail-fast is before Codex; no result.md.
        $project = script:New-RunCase -CaseName 'rr37'
        $taskId  = 'rr37-task'
        $prep = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01'
        $prep.ExitCode | Should -Be 0 -Because $prep.Output
        $inputPath = Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-01/input.md')
        script:Set-InputFilled -InputPath $inputPath

        $toolRoot = script:New-CategoryToolRoot -CaseName 'rr37'
        $stub = script:Write-CodexStub -StubName 'rr37-yes' -Mode 'verdict-yes'
        $r = script:Invoke-ReviewRun -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01' -StubPath $stub -EffortCategory 'no-effort' -ToolRoot $toolRoot
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'no usable reasoningEffort'
        $r.Output | Should -Not -Match '(?m)^effort-source: config$'

        Test-Path -LiteralPath (Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-01/result.md')) -PathType Leaf | Should -BeFalse
    }

    It 'AC-RR38: a present category key with a null entry fails fast (matched-but-malformed, not a soft miss)' {
        # Match is by KEY PRESENCE: a present key whose value is JSON null is matched-but-malformed,
        # so review-run fails fast rather than reporting effort-policy-match: missed and soft-falling
        # back to the scalar config (which would hide the typo). Fail-fast is before Codex; no result.md.
        $project = script:New-RunCase -CaseName 'rr38'
        $taskId  = 'rr38-task'
        $prep = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01'
        $prep.ExitCode | Should -Be 0 -Because $prep.Output
        $inputPath = Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-01/input.md')
        script:Set-InputFilled -InputPath $inputPath

        $toolRoot = script:New-CategoryToolRoot -CaseName 'rr38'
        $stub = script:Write-CodexStub -StubName 'rr38-yes' -Mode 'verdict-yes'
        $r = script:Invoke-ReviewRun -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01' -StubPath $stub -EffortCategory 'null-entry' -ToolRoot $toolRoot
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'is present in config/reviewer.json categoryPolicy but its entry is null'
        # Not silently downgraded to a soft miss + scalar fallback.
        $r.Output | Should -Not -Match '(?m)^effort-policy-match: missed$'
        $r.Output | Should -Not -Match '(?m)^effort-source: config$'

        Test-Path -LiteralPath (Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-01/result.md')) -PathType Leaf | Should -BeFalse
    }

    It 'AC-RR39: explicit -Effort does NOT bypass a matched-but-malformed category (fail-fast is unconditional)' {
        # A matched category entry must be well-formed config regardless of overrides: naming a
        # malformed category is a config/usage error worth surfacing even when an explicit -Effort
        # would otherwise win the value. So -EffortCategory broken (out-of-enum reasoningEffort) plus
        # an explicit -Effort high still fails fast before Codex — the malformed entry is validated
        # unconditionally, not bypassed by the override.
        $project = script:New-RunCase -CaseName 'rr39'
        $taskId  = 'rr39-task'
        $prep = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01'
        $prep.ExitCode | Should -Be 0 -Because $prep.Output
        $inputPath = Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-01/input.md')
        script:Set-InputFilled -InputPath $inputPath

        $toolRoot = script:New-CategoryToolRoot -CaseName 'rr39'
        $stub = script:Write-CodexStub -StubName 'rr39-yes' -Mode 'verdict-yes'
        $r = script:Invoke-ReviewRun -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01' -StubPath $stub -EffortCategory 'broken' -Effort 'high' -ToolRoot $toolRoot
        $r.ExitCode | Should -Not -Be 0 -Because $r.Output
        $r.Output | Should -Match 'invalid reasoning effort'
        $r.Output | Should -Match 'source: category'
        # The explicit effort did not silently win past the malformed category.
        $r.Output | Should -Not -Match 'review-run: PASS'

        Test-Path -LiteralPath (Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-01/result.md')) -PathType Leaf | Should -BeFalse
    }
}

Describe 'review-run strict C1 (perspective-required) layout' {
    It 'AC-RR-PERSP1: run resolves the three-level pass dir and writes result.md there' {
        $project = script:New-RunCase -CaseName 'rr-persp1'
        $taskId  = 'rr-persp-task'

        $prep = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01' -Perspective 'local-correctness'
        $prep.ExitCode | Should -Be 0 -Because $prep.Output

        $inputPath = Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-01/input.md')
        script:Set-InputFilled -InputPath $inputPath

        $stub = script:Write-CodexStub -StubName 'rr-persp1-yes' -Mode 'verdict-yes'
        $r = script:Invoke-ReviewRun -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01' -StubPath $stub -Perspective 'local-correctness'
        $r.ExitCode | Should -Be 0 -Because $r.Output
        $r.Output | Should -Match 'review-run: PASS'
        $r.Output | Should -Match 'perspective: local-correctness'
        $r.Output | Should -Match 'verdict: yes'

        $passDir = Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-01')
        Test-Path -LiteralPath (Join-Path $passDir 'result.md') -PathType Leaf | Should -BeTrue
    }

    It 'AC-RR-PERSP2: corrective loop increments pass-NN within a perspective' {
        $project = script:New-RunCase -CaseName 'rr-persp2'
        $taskId  = 'rr-persp-task'

        $prep1 = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01' -Perspective 'local-correctness'
        $prep1.ExitCode | Should -Be 0 -Because $prep1.Output
        script:Set-InputFilled -InputPath (Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-01/input.md'))

        $stubNo = script:Write-CodexStub -StubName 'rr-persp2-no' -Mode 'verdict-no'
        $r1 = script:Invoke-ReviewRun -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01' -StubPath $stubNo -Perspective 'local-correctness'
        $r1.ExitCode | Should -Be 0 -Because $r1.Output
        $r1.Output | Should -Match 'verdict: no'

        # Allocate the next pass under the SAME perspective (per-perspective auto-allocation).
        $prep2 = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -Perspective 'local-correctness'
        $prep2.ExitCode | Should -Be 0 -Because $prep2.Output
        $prep2.Output | Should -Match 'pass: pass-02'
        script:Set-InputFilled -InputPath (Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-02/input.md'))

        $stubYes = script:Write-CodexStub -StubName 'rr-persp2-yes' -Mode 'verdict-yes'
        $r2 = script:Invoke-ReviewRun -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-02' -StubPath $stubYes -Perspective 'local-correctness'
        $r2.ExitCode | Should -Be 0 -Because $r2.Output
        $r2.Output | Should -Match 'verdict: yes'

        Test-Path -LiteralPath (Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-01/result.md')) -PathType Leaf | Should -BeTrue
        Test-Path -LiteralPath (Join-Path $project ('log/review/' + $taskId + '/local-correctness/pass-02/result.md')) -PathType Leaf | Should -BeTrue
    }

    It 'AC-RR-PERSP3: review-verify -RequireResult passes on a three-level pass' {
        $project = script:New-RunCase -CaseName 'rr-persp3'
        $taskId  = 'rr-persp-task'

        $prep = script:Invoke-ReviewPrepare -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01' -Perspective 'system-coherence'
        $prep.ExitCode | Should -Be 0 -Because $prep.Output
        script:Set-InputFilled -InputPath (Join-Path $project ('log/review/' + $taskId + '/system-coherence/pass-01/input.md'))

        $stub = script:Write-CodexStub -StubName 'rr-persp3-full' -Mode 'verdict-yes-full'
        $r = script:Invoke-ReviewRun -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01' -StubPath $stub -Perspective 'system-coherence'
        $r.ExitCode | Should -Be 0 -Because $r.Output

        $v = script:Invoke-ReviewVerify -ProjectRoot $project -ReviewTaskId $taskId -Pass 'pass-01' -Perspective 'system-coherence'
        $v.ExitCode | Should -Be 0 -Because $v.Output
        $v.Output | Should -Match 'perspective: system-coherence'
        $v.Output | Should -Match 'result\.md verdict shape valid \(verdict=yes\)'
        $v.Output | Should -Match 'disclosure sections present'
    }

    It 'AC-RR-PERSP4: invalid perspective is rejected before Codex' {
        $project = script:New-RunCase -CaseName 'rr-persp4'
        # An invalid perspective is rejected at validation, before any pass-dir resolution or
        # Codex invocation — no prepared pass is needed.
        $stub = script:Write-CodexStub -StubName 'rr-persp4-yes' -Mode 'verdict-yes'
        $r = script:Invoke-ReviewRun -ProjectRoot $project -ReviewTaskId 'rr-persp-task' -Pass 'pass-01' -StubPath $stub -Perspective 'pass-02'
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'invalid Perspective'
    }

    It 'AC-RR-PERSP5: review-run without -Perspective fails fast (strict C1 — required) before Codex' {
        $project = script:New-RunCase -CaseName 'rr-persp5'
        $stub = script:Write-CodexStub -StubName 'rr-persp5-yes' -Mode 'verdict-yes'
        $r = script:Invoke-ReviewRun -ProjectRoot $project -ReviewTaskId 'rr-persp-task' -Pass 'pass-01' -StubPath $stub -OmitPerspective
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match '-Perspective is required'
    }

    It 'AC-RR-PERSP6: review-verify without -Perspective fails fast (strict C1 — required)' {
        $project = script:New-RunCase -CaseName 'rr-persp6'
        $v = script:Invoke-ReviewVerify -ProjectRoot $project -ReviewTaskId 'rr-persp-task' -Pass 'pass-01' -OmitPerspective
        $v.ExitCode | Should -Not -Be 0
        $v.Output | Should -Match '-Perspective is required'
    }
}
