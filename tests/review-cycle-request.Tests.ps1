Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

BeforeAll {
    $script:RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).ProviderPath
    $script:CycleScript = Join-Path $script:RepoRoot 'scripts/review-cycle.ps1'

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

    function script:New-RequestCase {
        param([string] $CaseName)
        $caseRoot = Join-Path $TestDrive ('pester-review-request-' + $CaseName)
        if (Test-Path -LiteralPath $caseRoot) {
            Remove-Item -LiteralPath $caseRoot -Recurse -Force
        }
        $null = New-Item -ItemType Directory -Path $caseRoot -Force
        return ([System.IO.Path]::GetFullPath($caseRoot))
    }

    function script:Write-RequestFile {
        param(
            [string] $ProjectRoot,
            [string] $Name,
            [string] $Content
        )
        $requestsDir = Join-Path $ProjectRoot 'log/review-requests'
        if (-not (Test-Path -LiteralPath $requestsDir -PathType Container)) {
            $null = New-Item -ItemType Directory -Path $requestsDir -Force
        }
        $path = Join-Path $requestsDir $Name
        script:Write-Utf8NoBomFile -Path $path -Content $Content
        return ([System.IO.Path]::GetFullPath($path))
    }

    function script:Write-CodexYesStub {
        param([string] $StubName)
        $stubDir = Join-Path $TestDrive 'pester-review-request-stubs'
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
        $body += '$enc = New-Object System.Text.UTF8Encoding($false)'
        $body += '$jsonText = [System.IO.File]::ReadAllText($CodexArgsFile, $enc)'
        $body += '$argsObj = $jsonText | ConvertFrom-Json'
        $body += '$argv = @($argsObj.argv)'
        $body += '$out = '''''
        $body += 'for ($i = 0; $i -lt $argv.Count; $i++) {'
        $body += '    $a = [string]$argv[$i]'
        $body += '    if ($a -ceq ''--output-last-message'') { if ($i + 1 -lt $argv.Count) { $out = [string]$argv[$i+1] } }'
        $body += '}'
        $body += 'if ([string]::IsNullOrEmpty($out)) { exit 96 }'
        $body += '$content = "# Review Result`r`n`r`n## Verdict`r`n`r`nyes`r`n"'
        $body += '[System.IO.File]::WriteAllText($out, $content, $enc)'
        $body += 'exit 0'
        $text = ($body -join "`r`n") + "`r`n"
        script:Write-Utf8BomCrlfFile -Path $stubPath -Content $text
        return $stubPath
    }

    function script:Invoke-Cycle {
        param(
            [string] $ProjectRoot,
            [string] $RunId,
            [string] $StubPath,
            [string[]] $TargetFiles,
            [string] $ReviewRequestPath,
            [hashtable] $Inline,
            [string] $Stage = 'design',
            [string] $Purpose = 'pester request cycle'
        )
        $procArgs = @(
            '-NoProfile', '-ExecutionPolicy', 'Bypass',
            '-File', $script:CycleScript,
            '-Stage', $Stage,
            '-Purpose', $Purpose,
            '-ProjectRoot', $ProjectRoot,
            '-ToolRoot', $script:RepoRoot,
            '-RunId', $RunId,
            '-Reviewer', 'codex'
        )
        if ($null -ne $TargetFiles -and $TargetFiles.Count -gt 0) {
            $listDir = Join-Path $ProjectRoot 'log/staging'
            if (-not (Test-Path -LiteralPath $listDir -PathType Container)) {
                $null = New-Item -ItemType Directory -Path $listDir -Force
            }
            $listPath = Join-Path $listDir ('rr-targets-' + ([guid]::NewGuid().ToString('N')) + '.list')
            $listContent = ($TargetFiles -join "`n") + "`n"
            $enc = New-Object System.Text.UTF8Encoding($false)
            [System.IO.File]::WriteAllText($listPath, $listContent, $enc)
            $procArgs += @('-TargetFilesPath', $listPath)
        }
        if (-not [string]::IsNullOrEmpty($ReviewRequestPath)) {
            $procArgs += @('-ReviewRequestPath', $ReviewRequestPath)
        }
        if ($null -ne $Inline) {
            foreach ($k in $Inline.Keys) {
                $procArgs += @(('-' + $k), [string]$Inline[$k])
            }
        }

        $prevCmd = $env:AI_HARNESS_CODEX_COMMAND
        $prevStub = $env:AI_HARNESS_CODEX_ARGS_FILE_STUB
        $env:AI_HARNESS_CODEX_COMMAND = $StubPath
        $env:AI_HARNESS_CODEX_ARGS_FILE_STUB = '1'
        try {
            $combined = & powershell.exe @procArgs 2>&1
            $exitCode = $LASTEXITCODE
        }
        finally {
            $env:AI_HARNESS_CODEX_COMMAND = $prevCmd
            $env:AI_HARNESS_CODEX_ARGS_FILE_STUB = $prevStub
        }
        $text = ($combined | ForEach-Object { [string]$_ }) -join "`n"
        return [pscustomobject]@{
            ExitCode = $exitCode
            Output   = $text
        }
    }

    function script:Read-Utf8Text {
        param([string] $Path)
        return [System.IO.File]::ReadAllText($Path, (New-Object System.Text.UTF8Encoding($false)))
    }
}

Describe 'review-cycle -ReviewRequestPath' {
    It 'AC-RR1: simple request file is parsed and meta.reviewRequest is recorded' {
        $project = script:New-RequestCase -CaseName 'rr1'
        $target = Join-Path $project 'a.txt'
        script:Write-Utf8NoBomFile -Path $target -Content "rr1 body`n"
        $stub = script:Write-CodexYesStub -StubName 'rr1-yes'

        $reqText = @(
            '## Context',
            '',
            'Simple request context line.',
            '',
            '## Required inspection paths',
            '',
            'a.txt',
            '',
            '## Review questions',
            '',
            'Is the body correct?',
            '',
            '## Constraints',
            '',
            'No further changes.',
            ''
        ) -join "`n"
        $reqPath = script:Write-RequestFile -ProjectRoot $project -Name 'rr1.md' -Content $reqText

        $runId = '20260516-110000-rr1aaa'
        $r = script:Invoke-Cycle -ProjectRoot $project -TargetFiles @($target) -RunId $runId -StubPath $stub -ReviewRequestPath $reqPath
        $r.ExitCode | Should -Be 0
        $r.Output | Should -Match 'review-cycle: PASS'

        $runDir = Join-Path $project ('log/review/' + $runId)
        $metaJson = script:Read-Utf8Text -Path (Join-Path $runDir 'meta.json') | ConvertFrom-Json
        $metaJson.reviewRequest.path | Should -Be 'log/review-requests/rr1.md'
        $expectedSha = (Get-FileHash -LiteralPath $reqPath -Algorithm SHA256).Hash.ToLowerInvariant()
        $metaJson.reviewRequest.sha256 | Should -Be $expectedSha

        $inputText = script:Read-Utf8Text -Path (Join-Path $runDir 'input.md')
        $inputText | Should -Match 'Simple request context line\.'
        $inputText | Should -Match 'Is the body correct\?'
        $inputText | Should -Match 'No further changes\.'
        $inputText | Should -Not -Match 'Replace this placeholder'
    }

    It 'AC-RR2: multi-line body with markdown bullets and Korean+English mix is preserved verbatim' {
        $project = script:New-RequestCase -CaseName 'rr2'
        $target = Join-Path $project 'a.txt'
        script:Write-Utf8NoBomFile -Path $target -Content "rr2 body`n"
        $stub = script:Write-CodexYesStub -StubName 'rr2-yes'

        $contextBody = @(
            'Multi-line context.',
            '- bullet one',
            '- bullet two with 한국어 mixed in',
            '',
            'A second paragraph with multiple lines.'
        ) -join "`n"

        $reqText = @(
            '## Context',
            '',
            $contextBody,
            '',
            '## Required inspection paths',
            '',
            'a.txt; src/foo.cs',
            '',
            '## Review questions',
            '',
            '1. Does the change keep the API stable?',
            '2. 한국어 질문도 같이 들어 있다.',
            '',
            '## Constraints',
            '',
            'Stage 3 docs-only scope. No commit/push.',
            ''
        ) -join "`n"
        $reqPath = script:Write-RequestFile -ProjectRoot $project -Name 'rr2.md' -Content $reqText

        $runId = '20260516-110000-rr2aaa'
        $r = script:Invoke-Cycle -ProjectRoot $project -TargetFiles @($target) -RunId $runId -StubPath $stub -ReviewRequestPath $reqPath
        $r.ExitCode | Should -Be 0

        $runDir = Join-Path $project ('log/review/' + $runId)
        $inputText = script:Read-Utf8Text -Path (Join-Path $runDir 'input.md')
        $inputText | Should -Match 'bullet one'
        $inputText | Should -Match '한국어 mixed in'
        $inputText | Should -Match '한국어 질문도 같이 들어 있다'
        $inputText | Should -Match 'A second paragraph with multiple lines'
        $inputText | Should -Match 'Stage 3 docs-only scope'
    }

    It 'AC-RR3: embedded ASCII double-quote in body survives end-to-end' {
        $project = script:New-RequestCase -CaseName 'rr3'
        $target = Join-Path $project 'a.txt'
        script:Write-Utf8NoBomFile -Path $target -Content "rr3 body`n"
        $stub = script:Write-CodexYesStub -StubName 'rr3-yes'

        $quoteBody = 'The reviewer must inspect the "narrow" path under tests/.'
        $reqText = @(
            '## Context',
            '',
            $quoteBody,
            '',
            '## Required inspection paths',
            '',
            'a.txt',
            '',
            '## Review questions',
            '',
            'Does the body contain "narrow" as a literal token?',
            '',
            '## Constraints',
            '',
            'No "always" or "default" qualifiers in verdict.',
            ''
        ) -join "`n"
        $reqPath = script:Write-RequestFile -ProjectRoot $project -Name 'rr3.md' -Content $reqText

        $runId = '20260516-110000-rr3aaa'
        $r = script:Invoke-Cycle -ProjectRoot $project -TargetFiles @($target) -RunId $runId -StubPath $stub -ReviewRequestPath $reqPath
        $r.ExitCode | Should -Be 0

        $runDir = Join-Path $project ('log/review/' + $runId)
        $inputText = script:Read-Utf8Text -Path (Join-Path $runDir 'input.md')
        $inputText | Should -Match '"narrow"'
        $inputText | Should -Match '"always"'
        $inputText | Should -Match '"default"'
    }

    It 'AC-RR4: missing required heading fails fast' {
        $project = script:New-RequestCase -CaseName 'rr4'
        $target = Join-Path $project 'a.txt'
        script:Write-Utf8NoBomFile -Path $target -Content "rr4 body`n"
        $stub = script:Write-CodexYesStub -StubName 'rr4-yes'

        # Missing ## Constraints
        $reqText = @(
            '## Context','','c','',
            '## Required inspection paths','','p','',
            '## Review questions','','q',''
        ) -join "`n"
        $reqPath = script:Write-RequestFile -ProjectRoot $project -Name 'rr4.md' -Content $reqText

        $runId = '20260516-110000-rr4aaa'
        $r = script:Invoke-Cycle -ProjectRoot $project -TargetFiles @($target) -RunId $runId -StubPath $stub -ReviewRequestPath $reqPath
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'ReviewRequest missing heading'
        $r.Output | Should -Match '## Constraints'

        $runDir = Join-Path $project ('log/review/' + $runId)
        Test-Path -LiteralPath $runDir -PathType Container | Should -BeFalse
    }

    It 'AC-RR5: empty body under required heading fails fast' {
        $project = script:New-RequestCase -CaseName 'rr5'
        $target = Join-Path $project 'a.txt'
        script:Write-Utf8NoBomFile -Path $target -Content "rr5 body`n"
        $stub = script:Write-CodexYesStub -StubName 'rr5-yes'

        # Empty ## Review questions
        $reqText = @(
            '## Context','','c','',
            '## Required inspection paths','','p','',
            '## Review questions','','',
            '## Constraints','','x',''
        ) -join "`n"
        $reqPath = script:Write-RequestFile -ProjectRoot $project -Name 'rr5.md' -Content $reqText

        $runId = '20260516-110000-rr5aaa'
        $r = script:Invoke-Cycle -ProjectRoot $project -TargetFiles @($target) -RunId $runId -StubPath $stub -ReviewRequestPath $reqPath
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'ReviewRequest section is empty'
        $r.Output | Should -Match '## Review questions'
    }

    It 'AC-RR6: duplicate required heading fails fast' {
        $project = script:New-RequestCase -CaseName 'rr6'
        $target = Join-Path $project 'a.txt'
        script:Write-Utf8NoBomFile -Path $target -Content "rr6 body`n"
        $stub = script:Write-CodexYesStub -StubName 'rr6-yes'

        # Duplicate ## Context
        $reqText = @(
            '## Context','','c1','',
            '## Context','','c2','',
            '## Required inspection paths','','p','',
            '## Review questions','','q','',
            '## Constraints','','x',''
        ) -join "`n"
        $reqPath = script:Write-RequestFile -ProjectRoot $project -Name 'rr6.md' -Content $reqText

        $runId = '20260516-110000-rr6aaa'
        $r = script:Invoke-Cycle -ProjectRoot $project -TargetFiles @($target) -RunId $runId -StubPath $stub -ReviewRequestPath $reqPath
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'ReviewRequest duplicate heading'
    }

    It 'AC-RR7: request file outside <ProjectRoot>/log/review-requests/ is rejected' {
        $project = script:New-RequestCase -CaseName 'rr7'
        $target = Join-Path $project 'a.txt'
        script:Write-Utf8NoBomFile -Path $target -Content "rr7 body`n"
        $stub = script:Write-CodexYesStub -StubName 'rr7-yes'

        # Write request file outside log/review-requests/ (under log/staging/ instead)
        $badDir = Join-Path $project 'log/staging'
        $null = New-Item -ItemType Directory -Path $badDir -Force
        $badReq = Join-Path $badDir 'misplaced.md'
        $reqText = @(
            '## Context','','c','',
            '## Required inspection paths','','p','',
            '## Review questions','','q','',
            '## Constraints','','x',''
        ) -join "`n"
        script:Write-Utf8NoBomFile -Path $badReq -Content $reqText

        $runId = '20260516-110000-rr7aaa'
        $r = script:Invoke-Cycle -ProjectRoot $project -TargetFiles @($target) -RunId $runId -StubPath $stub -ReviewRequestPath $badReq
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'ReviewRequestPath outside'

        $runDir = Join-Path $project ('log/review/' + $runId)
        Test-Path -LiteralPath $runDir -PathType Container | Should -BeFalse
    }

    It 'AC-RR8: non-existent request file is rejected' {
        $project = script:New-RequestCase -CaseName 'rr8'
        $target = Join-Path $project 'a.txt'
        script:Write-Utf8NoBomFile -Path $target -Content "rr8 body`n"
        $stub = script:Write-CodexYesStub -StubName 'rr8-yes'

        $missingPath = Join-Path $project 'log/review-requests/does-not-exist.md'
        $null = New-Item -ItemType Directory -Path (Split-Path -LiteralPath $missingPath) -Force

        $runId = '20260516-110000-rr8aaa'
        $r = script:Invoke-Cycle -ProjectRoot $project -TargetFiles @($target) -RunId $runId -StubPath $stub -ReviewRequestPath $missingPath
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'ReviewRequestPath not found'

        $runDir = Join-Path $project ('log/review/' + $runId)
        Test-Path -LiteralPath $runDir -PathType Container | Should -BeFalse
    }

    It 'AC-RR9: -ReviewRequestPath combined with inline -Context fails fast' {
        $project = script:New-RequestCase -CaseName 'rr9'
        $target = Join-Path $project 'a.txt'
        script:Write-Utf8NoBomFile -Path $target -Content "rr9 body`n"
        $stub = script:Write-CodexYesStub -StubName 'rr9-yes'

        $reqText = @(
            '## Context','','c','',
            '## Required inspection paths','','p','',
            '## Review questions','','q','',
            '## Constraints','','x',''
        ) -join "`n"
        $reqPath = script:Write-RequestFile -ProjectRoot $project -Name 'rr9.md' -Content $reqText

        $runId = '20260516-110000-rr9aaa'
        $r = script:Invoke-Cycle -ProjectRoot $project -TargetFiles @($target) -RunId $runId -StubPath $stub -ReviewRequestPath $reqPath -Inline @{ Context = 'inline context' }
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match '-ReviewRequestPath cannot be combined with inline free-text parameters'
        $r.Output | Should -Match '-Context'

        $runDir = Join-Path $project ('log/review/' + $runId)
        Test-Path -LiteralPath $runDir -PathType Container | Should -BeFalse
    }

    It 'AC-RR10: -ReviewRequestPath combined with inline -ReviewQuestions fails fast' {
        $project = script:New-RequestCase -CaseName 'rr10'
        $target = Join-Path $project 'a.txt'
        script:Write-Utf8NoBomFile -Path $target -Content "rr10 body`n"
        $stub = script:Write-CodexYesStub -StubName 'rr10-yes'

        $reqText = @(
            '## Context','','c','',
            '## Required inspection paths','','p','',
            '## Review questions','','q','',
            '## Constraints','','x',''
        ) -join "`n"
        $reqPath = script:Write-RequestFile -ProjectRoot $project -Name 'rr10.md' -Content $reqText

        $runId = '20260516-110000-rr10aa'
        $r = script:Invoke-Cycle -ProjectRoot $project -TargetFiles @($target) -RunId $runId -StubPath $stub -ReviewRequestPath $reqPath -Inline @{ ReviewQuestions = 'inline question' }
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match '-ReviewRequestPath cannot be combined with inline free-text parameters'
        $r.Output | Should -Match '-ReviewQuestions'
    }

    It 'AC-RR11: inline-only invocation remains backward compatible (no -ReviewRequestPath)' {
        $project = script:New-RequestCase -CaseName 'rr11'
        $target = Join-Path $project 'a.txt'
        script:Write-Utf8NoBomFile -Path $target -Content "rr11 body`n"
        $stub = script:Write-CodexYesStub -StubName 'rr11-yes'

        $runId = '20260516-110000-rr11aa'
        $r = script:Invoke-Cycle -ProjectRoot $project -TargetFiles @($target) -RunId $runId -StubPath $stub -Inline @{
            Context = 'inline-only context'
            RequiredInspectionPaths = 'a.txt'
            ReviewQuestions = 'inline-only question'
            Constraints = 'inline-only constraint'
        }
        $r.ExitCode | Should -Be 0
        $r.Output | Should -Match 'review-cycle: PASS'

        $runDir = Join-Path $project ('log/review/' + $runId)
        $metaJson = script:Read-Utf8Text -Path (Join-Path $runDir 'meta.json') | ConvertFrom-Json
        $hasReviewRequest = $metaJson.PSObject.Properties.Match('reviewRequest').Count -gt 0
        $hasReviewRequest | Should -BeFalse

        $inputText = script:Read-Utf8Text -Path (Join-Path $runDir 'input.md')
        $inputText | Should -Match 'inline-only context'
        $inputText | Should -Match 'inline-only question'
        $inputText | Should -Match 'inline-only constraint'
    }
}
