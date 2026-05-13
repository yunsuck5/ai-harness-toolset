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
            'no-verdict' {
                $body += '$content = "# Review Result`r`n`r`nNo Verdict heading present.`r`n"'
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
            [string] $RunId,
            [string] $TargetPath,
            [string] $Stage = 'implementation',
            [string] $Purpose = 'pester review-run prepare'
        )
        $procArgs = @(
            '-NoProfile', '-ExecutionPolicy', 'Bypass',
            '-File', $script:PrepareScript,
            '-Stage', $Stage,
            '-Purpose', $Purpose,
            '-ProjectRoot', $ProjectRoot,
            '-ToolRoot', $script:RepoRoot,
            '-RunId', $RunId,
            '-Reviewer', 'codex',
            '-TargetFiles', $TargetPath
        )
        $combined = & powershell.exe @procArgs 2>&1
        $exitCode = $LASTEXITCODE
        $text = ($combined | ForEach-Object { [string]$_ }) -join "`n"
        return [pscustomobject]@{
            ExitCode = $exitCode
            Output   = $text
        }
    }

    function script:Set-InputFilled {
        param([string] $InputPath)
        $enc = New-Object System.Text.UTF8Encoding($false)
        $text = [System.IO.File]::ReadAllText($InputPath, $enc)
        $text = $text.Replace('(Replace this placeholder with review context.)', 'pester run context line.')
        $text = $text.Replace('(Replace this placeholder with paths the reviewer must inspect.)', 'pester run inspection path.')
        $text = $text.Replace('(Replace this placeholder with review questions.)', 'pester run review question.')
        $text = $text.Replace('(Replace this placeholder with explicit constraints.)', 'pester run constraint.')
        [System.IO.File]::WriteAllText($InputPath, $text, $enc)
    }

    function script:Invoke-ReviewRun {
        param(
            [string] $ProjectRoot,
            [string] $RunId,
            [string] $StubPath,
            [string] $Reviewer = 'codex',
            [switch] $Force
        )
        $procArgs = @(
            '-NoProfile', '-ExecutionPolicy', 'Bypass',
            '-File', $script:RunScript,
            '-RunId', $RunId,
            '-Reviewer', $Reviewer,
            '-ProjectRoot', $ProjectRoot,
            '-ToolRoot', $script:RepoRoot
        )
        if ($Force) {
            $procArgs += '-Force'
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

Describe 'review-run' {
    It 'AC-RR1: happy path on a prepared run produces result.md/result.json, PASS, and both review-verify modes succeed' {
        $project = script:New-RunCase -CaseName 'rr1'
        $target = Join-Path $project 'a.txt'
        script:Write-Utf8NoBomFile -Path $target -Content "rr1 body`n"

        $runId = '20260510-120000-rr1aaa'
        $prep = script:Invoke-ReviewPrepare -ProjectRoot $project -RunId $runId -TargetPath $target
        $prep.ExitCode | Should -Be 0 -Because $prep.Output

        $inputPath = Join-Path $project ('log/review/' + $runId + '/input.md')
        script:Set-InputFilled -InputPath $inputPath

        $stub = script:Write-CodexStub -StubName 'rr1-yes' -Mode 'verdict-yes'
        $r = script:Invoke-ReviewRun -ProjectRoot $project -RunId $runId -StubPath $stub
        $r.ExitCode | Should -Be 0 -Because $r.Output
        $r.Output | Should -Match 'review-run: PASS'
        $r.Output | Should -Match 'verdict: yes'
        $r.Output | Should -Match 'review-verify: PASS'

        $runDir = Join-Path $project ('log/review/' + $runId)
        Test-Path -LiteralPath (Join-Path $runDir 'result.md')   -PathType Leaf | Should -BeTrue
        Test-Path -LiteralPath (Join-Path $runDir 'result.json') -PathType Leaf | Should -BeTrue

        $resultJson = [System.IO.File]::ReadAllText((Join-Path $runDir 'result.json'), (New-Object System.Text.UTF8Encoding($false))) | ConvertFrom-Json
        $resultJson.verdict | Should -Be 'yes'
        $resultJson.runId | Should -Be $runId

        $meta = [System.IO.File]::ReadAllText((Join-Path $runDir 'meta.json'), (New-Object System.Text.UTF8Encoding($false))) | ConvertFrom-Json
        $expectedTargetSha   = (Get-FileHash -LiteralPath $target                            -Algorithm SHA256).Hash.ToLowerInvariant()
        $expectedInputSha    = (Get-FileHash -LiteralPath $inputPath                         -Algorithm SHA256).Hash.ToLowerInvariant()
        $expectedResultMdSha = (Get-FileHash -LiteralPath (Join-Path $runDir 'result.md')   -Algorithm SHA256).Hash.ToLowerInvariant()

        $resultJson.schemaVersion                   | Should -Be 1
        $resultJson.stage                           | Should -Be ([string]$meta.stage)
        $resultJson.purpose                         | Should -Be ([string]$meta.purpose)
        $resultJson.reviewer                        | Should -Be ([string]$meta.reviewer)
        ($resultJson.targetPath -replace '\\', '/') | Should -Be ($meta.targetPath -replace '\\', '/')
        $resultJson.targetSha256                    | Should -Be $expectedTargetSha
        $resultJson.targetSha256                    | Should -Be ([string]$meta.targetSha256)
        $resultJson.inputSha256                     | Should -Be $expectedInputSha
        $resultJson.resultMarkdownSha256            | Should -Be $expectedResultMdSha
        $resultJson.createdAtUtc                    | Should -Match '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{7}Z$'
        $resultJson.sourceHead                      | Should -Be $meta.sourceHead
        $resultJson.PSObject.Properties.Name        | Should -Contain 'notes'
    }

    It 'AC-RR2: missing run directory fails before Codex and produces no result artifact' {
        $project = script:New-RunCase -CaseName 'rr2'
        $stub = script:Write-CodexStub -StubName 'rr2-yes' -Mode 'verdict-yes'

        $runId = '20260510-120000-rr2aaa'
        $r = script:Invoke-ReviewRun -ProjectRoot $project -RunId $runId -StubPath $stub
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'review-run: FAIL run not prepared'

        $runDir = Join-Path $project ('log/review/' + $runId)
        Test-Path -LiteralPath $runDir -PathType Container | Should -BeFalse
    }

    It 'AC-RR3: missing input.md fails before Codex and produces no result artifact' {
        $project = script:New-RunCase -CaseName 'rr3'
        $target = Join-Path $project 'a.txt'
        script:Write-Utf8NoBomFile -Path $target -Content "rr3 body`n"

        $runId = '20260510-120000-rr3aaa'
        $prep = script:Invoke-ReviewPrepare -ProjectRoot $project -RunId $runId -TargetPath $target
        $prep.ExitCode | Should -Be 0 -Because $prep.Output

        $inputPath = Join-Path $project ('log/review/' + $runId + '/input.md')
        Remove-Item -LiteralPath $inputPath -Force

        $stub = script:Write-CodexStub -StubName 'rr3-yes' -Mode 'verdict-yes'
        $r = script:Invoke-ReviewRun -ProjectRoot $project -RunId $runId -StubPath $stub
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'review-run: FAIL input\.md not found'

        $runDir = Join-Path $project ('log/review/' + $runId)
        Test-Path -LiteralPath (Join-Path $runDir 'result.md')   -PathType Leaf | Should -BeFalse
        Test-Path -LiteralPath (Join-Path $runDir 'result.json') -PathType Leaf | Should -BeFalse
    }

    It 'AC-RR4: placeholder-only input.md fails through review-input-verify and does not call Codex' {
        $project = script:New-RunCase -CaseName 'rr4'
        $target = Join-Path $project 'a.txt'
        script:Write-Utf8NoBomFile -Path $target -Content "rr4 body`n"

        $runId = '20260510-120000-rr4aaa'
        $prep = script:Invoke-ReviewPrepare -ProjectRoot $project -RunId $runId -TargetPath $target
        $prep.ExitCode | Should -Be 0 -Because $prep.Output

        $stub = script:Write-CodexStub -StubName 'rr4-yes' -Mode 'verdict-yes'
        $r = script:Invoke-ReviewRun -ProjectRoot $project -RunId $runId -StubPath $stub
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'review-run: FAIL input\.md not ready'
        $r.Output | Should -Match 'review-input-verify'

        $runDir = Join-Path $project ('log/review/' + $runId)
        Test-Path -LiteralPath (Join-Path $runDir 'result.md')   -PathType Leaf | Should -BeFalse
        Test-Path -LiteralPath (Join-Path $runDir 'result.json') -PathType Leaf | Should -BeFalse
        Test-Path -LiteralPath (Join-Path $runDir 'result.md.argv.txt') -PathType Leaf | Should -BeFalse
    }

    It 'AC-RR5: missing or empty meta.reviewerConfig.model fails before Codex' {
        $project = script:New-RunCase -CaseName 'rr5'
        $target = Join-Path $project 'a.txt'
        script:Write-Utf8NoBomFile -Path $target -Content "rr5 body`n"

        $runId = '20260510-120000-rr5aaa'
        $prep = script:Invoke-ReviewPrepare -ProjectRoot $project -RunId $runId -TargetPath $target
        $prep.ExitCode | Should -Be 0 -Because $prep.Output

        $metaPath = Join-Path $project ('log/review/' + $runId + '/meta.json')
        $enc = New-Object System.Text.UTF8Encoding($false)
        $metaText = [System.IO.File]::ReadAllText($metaPath, $enc)
        $meta = $metaText | ConvertFrom-Json
        $meta.reviewerConfig.model = ''
        $rewritten = ($meta | ConvertTo-Json -Depth 32)
        $rewritten = $rewritten -replace "`r`n", "`n"
        [System.IO.File]::WriteAllText($metaPath, $rewritten, $enc)

        $inputPath = Join-Path $project ('log/review/' + $runId + '/input.md')
        script:Set-InputFilled -InputPath $inputPath

        $stub = script:Write-CodexStub -StubName 'rr5-yes' -Mode 'verdict-yes'
        $r = script:Invoke-ReviewRun -ProjectRoot $project -RunId $runId -StubPath $stub
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'review-run: FAIL reviewer model missing'

        $runDir = Join-Path $project ('log/review/' + $runId)
        Test-Path -LiteralPath (Join-Path $runDir 'result.md')   -PathType Leaf | Should -BeFalse
        Test-Path -LiteralPath (Join-Path $runDir 'result.json') -PathType Leaf | Should -BeFalse
    }

    It 'AC-RR6: existing result.md/result.json blocks re-run without -Force and preserves prior record' {
        $project = script:New-RunCase -CaseName 'rr6'
        $target = Join-Path $project 'a.txt'
        script:Write-Utf8NoBomFile -Path $target -Content "rr6 body`n"

        $runId = '20260510-120000-rr6aaa'
        $prep = script:Invoke-ReviewPrepare -ProjectRoot $project -RunId $runId -TargetPath $target
        $prep.ExitCode | Should -Be 0 -Because $prep.Output

        $inputPath = Join-Path $project ('log/review/' + $runId + '/input.md')
        script:Set-InputFilled -InputPath $inputPath

        $stub = script:Write-CodexStub -StubName 'rr6-yes' -Mode 'verdict-yes'
        $first = script:Invoke-ReviewRun -ProjectRoot $project -RunId $runId -StubPath $stub
        $first.ExitCode | Should -Be 0 -Because $first.Output

        $runDir = Join-Path $project ('log/review/' + $runId)
        $resultMdBefore = [System.IO.File]::ReadAllText((Join-Path $runDir 'result.md'),   (New-Object System.Text.UTF8Encoding($false)))
        $resultJsBefore = [System.IO.File]::ReadAllText((Join-Path $runDir 'result.json'), (New-Object System.Text.UTF8Encoding($false)))

        $second = script:Invoke-ReviewRun -ProjectRoot $project -RunId $runId -StubPath $stub
        $second.ExitCode | Should -Not -Be 0
        $second.Output | Should -Match 'review-run: FAIL existing result\.md/result\.json present'
        $second.Output | Should -Match '-Force'

        $resultMdAfter = [System.IO.File]::ReadAllText((Join-Path $runDir 'result.md'),   (New-Object System.Text.UTF8Encoding($false)))
        $resultJsAfter = [System.IO.File]::ReadAllText((Join-Path $runDir 'result.json'), (New-Object System.Text.UTF8Encoding($false)))
        $resultMdAfter | Should -Be $resultMdBefore
        $resultJsAfter | Should -Be $resultJsBefore
    }

    It 'AC-RR7: -Force overwrites existing result.md/result.json and records the new verdict' {
        $project = script:New-RunCase -CaseName 'rr7'
        $target = Join-Path $project 'a.txt'
        script:Write-Utf8NoBomFile -Path $target -Content "rr7 body`n"

        $runId = '20260510-120000-rr7aaa'
        $prep = script:Invoke-ReviewPrepare -ProjectRoot $project -RunId $runId -TargetPath $target
        $prep.ExitCode | Should -Be 0 -Because $prep.Output

        $inputPath = Join-Path $project ('log/review/' + $runId + '/input.md')
        script:Set-InputFilled -InputPath $inputPath

        $stubYes = script:Write-CodexStub -StubName 'rr7-yes' -Mode 'verdict-yes'
        $first = script:Invoke-ReviewRun -ProjectRoot $project -RunId $runId -StubPath $stubYes
        $first.ExitCode | Should -Be 0 -Because $first.Output

        $stubNo = script:Write-CodexStub -StubName 'rr7-no' -Mode 'verdict-no'
        $second = script:Invoke-ReviewRun -ProjectRoot $project -RunId $runId -StubPath $stubNo -Force
        $second.ExitCode | Should -Be 0 -Because $second.Output
        $second.Output | Should -Match 'verdict: no'

        $runDir = Join-Path $project ('log/review/' + $runId)
        $resultJson = [System.IO.File]::ReadAllText((Join-Path $runDir 'result.json'), (New-Object System.Text.UTF8Encoding($false))) | ConvertFrom-Json
        $resultJson.verdict | Should -Be 'no'

        $meta = [System.IO.File]::ReadAllText((Join-Path $runDir 'meta.json'), (New-Object System.Text.UTF8Encoding($false))) | ConvertFrom-Json
        $expectedTargetSha   = (Get-FileHash -LiteralPath $target                            -Algorithm SHA256).Hash.ToLowerInvariant()
        $expectedInputSha    = (Get-FileHash -LiteralPath $inputPath                         -Algorithm SHA256).Hash.ToLowerInvariant()
        $expectedResultMdSha = (Get-FileHash -LiteralPath (Join-Path $runDir 'result.md')   -Algorithm SHA256).Hash.ToLowerInvariant()

        $resultJson.schemaVersion                   | Should -Be 1
        $resultJson.runId                           | Should -Be $runId
        $resultJson.stage                           | Should -Be ([string]$meta.stage)
        $resultJson.purpose                         | Should -Be ([string]$meta.purpose)
        $resultJson.reviewer                        | Should -Be ([string]$meta.reviewer)
        ($resultJson.targetPath -replace '\\', '/') | Should -Be ($meta.targetPath -replace '\\', '/')
        $resultJson.targetSha256                    | Should -Be $expectedTargetSha
        $resultJson.targetSha256                    | Should -Be ([string]$meta.targetSha256)
        $resultJson.inputSha256                     | Should -Be $expectedInputSha
        $resultJson.resultMarkdownSha256            | Should -Be $expectedResultMdSha
        $resultJson.createdAtUtc                    | Should -Match '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{7}Z$'
        $resultJson.sourceHead                      | Should -Be $meta.sourceHead
        $resultJson.PSObject.Properties.Name        | Should -Contain 'notes'
    }

    It 'AC-RR8: verdict parse failure does not create result.json and preserves the failed run' {
        $project = script:New-RunCase -CaseName 'rr8'
        $target = Join-Path $project 'a.txt'
        script:Write-Utf8NoBomFile -Path $target -Content "rr8 body`n"

        $runId = '20260510-120000-rr8aaa'
        $prep = script:Invoke-ReviewPrepare -ProjectRoot $project -RunId $runId -TargetPath $target
        $prep.ExitCode | Should -Be 0 -Because $prep.Output

        $inputPath = Join-Path $project ('log/review/' + $runId + '/input.md')
        script:Set-InputFilled -InputPath $inputPath

        $stub = script:Write-CodexStub -StubName 'rr8-nv' -Mode 'no-verdict'
        $r = script:Invoke-ReviewRun -ProjectRoot $project -RunId $runId -StubPath $stub
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'Could not parse verdict'
        $r.Output | Should -Match 'result\.json was not created'

        $runDir = Join-Path $project ('log/review/' + $runId)
        Test-Path -LiteralPath $runDir                              -PathType Container | Should -BeTrue
        Test-Path -LiteralPath (Join-Path $runDir 'result.md')      -PathType Leaf      | Should -BeTrue
        Test-Path -LiteralPath (Join-Path $runDir 'result.json')    -PathType Leaf      | Should -BeFalse
    }

    It 'AC-RR9: review-verify -RequireResult succeeds independently after review-run PASS' {
        $project = script:New-RunCase -CaseName 'rr9'
        $target = Join-Path $project 'a.txt'
        script:Write-Utf8NoBomFile -Path $target -Content "rr9 body`n"

        $runId = '20260510-120000-rr9aaa'
        $prep = script:Invoke-ReviewPrepare -ProjectRoot $project -RunId $runId -TargetPath $target
        $prep.ExitCode | Should -Be 0 -Because $prep.Output

        $inputPath = Join-Path $project ('log/review/' + $runId + '/input.md')
        script:Set-InputFilled -InputPath $inputPath

        $stub = script:Write-CodexStub -StubName 'rr9-yes' -Mode 'verdict-yes'
        $r = script:Invoke-ReviewRun -ProjectRoot $project -RunId $runId -StubPath $stub
        $r.ExitCode | Should -Be 0 -Because $r.Output

        $verifyArgs = @(
            '-NoProfile', '-ExecutionPolicy', 'Bypass',
            '-File', $script:VerifyScript,
            '-RunId', $runId,
            '-ProjectRoot', $project,
            '-ToolRoot', $script:RepoRoot,
            '-RequireResult'
        )
        $combined = & powershell.exe @verifyArgs 2>&1
        $verifyExit = $LASTEXITCODE
        $verifyText = ($combined | ForEach-Object { [string]$_ }) -join "`n"
        $verifyExit | Should -Be 0 -Because $verifyText
        $verifyText | Should -Match 'review-verify: PASS'
        $verifyText | Should -Match 'result\.json present and binding verified'
    }

    It 'AC-RR10: non-codex reviewer fails with the MVP boundary message' {
        $project = script:New-RunCase -CaseName 'rr10'
        $target = Join-Path $project 'a.txt'
        script:Write-Utf8NoBomFile -Path $target -Content "rr10 body`n"

        $runId = '20260510-120000-rr10aa'
        $prep = script:Invoke-ReviewPrepare -ProjectRoot $project -RunId $runId -TargetPath $target
        $prep.ExitCode | Should -Be 0 -Because $prep.Output

        $inputPath = Join-Path $project ('log/review/' + $runId + '/input.md')
        script:Set-InputFilled -InputPath $inputPath

        $stub = script:Write-CodexStub -StubName 'rr10-yes' -Mode 'verdict-yes'
        $r = script:Invoke-ReviewRun -ProjectRoot $project -RunId $runId -StubPath $stub -Reviewer 'claude'
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'review-run: FAIL only -Reviewer codex is supported'

        $runDir = Join-Path $project ('log/review/' + $runId)
        Test-Path -LiteralPath (Join-Path $runDir 'result.md')   -PathType Leaf | Should -BeFalse
        Test-Path -LiteralPath (Join-Path $runDir 'result.json') -PathType Leaf | Should -BeFalse
    }
}
