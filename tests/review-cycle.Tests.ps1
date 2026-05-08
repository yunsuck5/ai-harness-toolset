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

    function script:New-CycleCase {
        param([string] $CaseName)
        $caseRoot = Join-Path $TestDrive ('pester-review-cycle-' + $CaseName)
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
        $stubDir = Join-Path $TestDrive 'pester-review-cycle-stubs'
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
            'fail' {
                $body += '$content = "# Review Result`r`nstub forced failure`r`n"'
                $body += '[System.IO.File]::WriteAllText($out, $content, $enc)'
                $body += 'exit 7'
            }
            default {
                throw "Unknown stub mode: $Mode"
            }
        }

        $text = ($body -join "`r`n") + "`r`n"
        script:Write-Utf8BomCrlfFile -Path $stubPath -Content $text
        return $stubPath
    }

    function script:Invoke-ReviewCycle {
        param(
            [string] $ProjectRoot,
            [string] $Stage = 'implementation',
            [string] $Purpose = 'pester cycle',
            [string[]] $TargetFiles,
            [string] $RunId,
            [string] $StubPath,
            [string] $Context = 'pester context line.',
            [string] $RequiredInspectionPaths = 'pester inspection path.',
            [string] $ReviewQuestions = 'pester review question.',
            [string] $Constraints = 'pester constraint.'
        )

        $procArgs = @(
            '-NoProfile', '-ExecutionPolicy', 'Bypass',
            '-File', $script:CycleScript,
            '-Stage', $Stage,
            '-Purpose', $Purpose,
            '-ProjectRoot', $ProjectRoot,
            '-ToolRoot', $script:RepoRoot,
            '-RunId', $RunId,
            '-Reviewer', 'codex',
            '-Context', $Context,
            '-RequiredInspectionPaths', $RequiredInspectionPaths,
            '-ReviewQuestions', $ReviewQuestions,
            '-Constraints', $Constraints
        )
        if ($null -ne $TargetFiles -and $TargetFiles.Count -gt 0) {
            $listDir = Join-Path $ProjectRoot 'log/staging'
            if (-not (Test-Path -LiteralPath $listDir -PathType Container)) {
                $null = New-Item -ItemType Directory -Path $listDir -Force
            }
            $listPath = Join-Path $listDir ('cycle-targets-' + ([guid]::NewGuid().ToString('N')) + '.list')
            $listContent = ($TargetFiles -join "`n") + "`n"
            $enc = New-Object System.Text.UTF8Encoding($false)
            [System.IO.File]::WriteAllText($listPath, $listContent, $enc)
            $procArgs += @('-TargetFilesPath', $listPath)
        }

        $previousEnv = $env:AI_HARNESS_CODEX_COMMAND
        $previousStubFlag = $env:AI_HARNESS_CODEX_ARGS_FILE_STUB
        $env:AI_HARNESS_CODEX_COMMAND = $StubPath
        $env:AI_HARNESS_CODEX_ARGS_FILE_STUB = '1'
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

    function script:Write-NpmShimStub {
        param([string] $StubName)
        $stubDir = Join-Path $TestDrive 'pester-review-cycle-stubs'
        if (-not (Test-Path -LiteralPath $stubDir -PathType Container)) {
            $null = New-Item -ItemType Directory -Path $stubDir -Force
        }
        $stubPath = Join-Path $stubDir ($StubName + '.ps1')

        $body = @()
        $body += 'Set-StrictMode -Version Latest'
        $body += '$ErrorActionPreference = ''Stop'''
        $body += '$enc = New-Object System.Text.UTF8Encoding($false)'
        $body += '$argv = @($args)'
        $body += '$out = '''''
        $body += '$model = '''''
        $body += '$hasExec = $false'
        $body += '$hasStdinMarker = $false'
        $body += '$hasReadOnly = $false'
        $body += '$hasApprovalNever = $false'
        $body += '$hasWebSearchDisabled = $false'
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
        $body += 'if (-not $hasApprovalNever) { Write-Host ''npm-shim-stub: FAIL --ask-for-approval never missing''; exit 91 }'
        $body += 'if (-not $hasExec) { Write-Host ''npm-shim-stub: FAIL exec missing''; exit 92 }'
        $body += 'if (-not $hasReadOnly) { Write-Host ''npm-shim-stub: FAIL --sandbox read-only missing''; exit 93 }'
        $body += 'if ([string]::IsNullOrEmpty($model)) { Write-Host ''npm-shim-stub: FAIL --model missing''; exit 94 }'
        $body += 'if (-not $hasWebSearchDisabled) { Write-Host ''npm-shim-stub: FAIL -c web_search=disabled missing''; exit 95 }'
        $body += 'if ([string]::IsNullOrEmpty($out)) { Write-Host ''npm-shim-stub: FAIL --output-last-message missing''; exit 96 }'
        $body += 'if (-not $hasStdinMarker) { Write-Host ''npm-shim-stub: FAIL stdin marker - missing''; exit 97 }'
        $body += '[System.IO.File]::WriteAllText(($out + ''.argv.txt''), ($argv -join "`n"), $enc)'
        $body += '$stdinReceived = $false'
        $body += 'if ($MyInvocation.ExpectingInput) {'
        $body += '    foreach ($chunk in $input) { if ($null -ne $chunk) { $stdinReceived = $true; break } }'
        $body += '}'
        $body += '[System.IO.File]::WriteAllText(($out + ''.stdin.flag''), ([string]$stdinReceived), $enc)'
        $body += '$content = "# Review Result`r`n`r`n## Verdict`r`n`r`nyes`r`n"'
        $body += '[System.IO.File]::WriteAllText($out, $content, $enc)'
        $body += 'exit 0'

        $text = ($body -join "`r`n") + "`r`n"
        script:Write-Utf8BomCrlfFile -Path $stubPath -Content $text
        return $stubPath
    }
}

Describe 'review-cycle' {
    It 'AC-CY1: happy path with stub verdict yes generates result.json and PASS' {
        $project = script:New-CycleCase -CaseName 'cy1'
        $target = Join-Path $project 'a.txt'
        script:Write-Utf8NoBomFile -Path $target -Content "cy1 body`n"
        $stub = script:Write-CodexStub -StubName 'cy1-yes' -Mode 'verdict-yes'

        $runId = '20260506-120000-cy1aaa'
        $r = script:Invoke-ReviewCycle -ProjectRoot $project -TargetFiles @($target) -RunId $runId -StubPath $stub
        $r.ExitCode | Should -Be 0
        $r.Output | Should -Match 'review-cycle: PASS'
        $r.Output | Should -Match 'verdict: yes'

        $runDir = Join-Path $project ('log/review/' + $runId)
        Test-Path -LiteralPath (Join-Path $runDir 'result.md')   -PathType Leaf | Should -BeTrue
        Test-Path -LiteralPath (Join-Path $runDir 'result.json') -PathType Leaf | Should -BeTrue

        $resultJson = [System.IO.File]::ReadAllText((Join-Path $runDir 'result.json'), (New-Object System.Text.UTF8Encoding($false))) | ConvertFrom-Json
        $resultJson.verdict | Should -Be 'yes'
        $resultJson.runId | Should -Be $runId
    }

    It 'AC-CY2: Codex non-zero exit fails review-cycle and does not create result.json' {
        $project = script:New-CycleCase -CaseName 'cy2'
        $target = Join-Path $project 'a.txt'
        script:Write-Utf8NoBomFile -Path $target -Content "cy2 body`n"
        $stub = script:Write-CodexStub -StubName 'cy2-fail' -Mode 'fail'

        $runId = '20260506-120000-cy2aaa'
        $r = script:Invoke-ReviewCycle -ProjectRoot $project -TargetFiles @($target) -RunId $runId -StubPath $stub
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'FAIL Codex CLI exit'

        $runDir = Join-Path $project ('log/review/' + $runId)
        Test-Path -LiteralPath (Join-Path $runDir 'result.json') -PathType Leaf | Should -BeFalse
    }

    It 'AC-CY3: verdict parse failure fails review-cycle, does not create result.json, and emits the new contract message' {
        $project = script:New-CycleCase -CaseName 'cy3'
        $target = Join-Path $project 'a.txt'
        script:Write-Utf8NoBomFile -Path $target -Content "cy3 body`n"
        $stub = script:Write-CodexStub -StubName 'cy3-noverdict' -Mode 'no-verdict'

        $runId = '20260506-120000-cy3aaa'
        $r = script:Invoke-ReviewCycle -ProjectRoot $project -TargetFiles @($target) -RunId $runId -StubPath $stub
        $r.ExitCode | Should -Not -Be 0

        $r.Output | Should -Match 'Could not parse verdict'
        $r.Output | Should -Match 'result\.json was not created'
        $r.Output | Should -Match 'failed run is preserved for inspection'

        $r.Output | Should -Not -Match '[Ee]dit .*result\.md'
        $r.Output | Should -Not -Match 'resume manually'
        $r.Output | Should -Not -Match 'review-verify'

        $runDir = Join-Path $project ('log/review/' + $runId)
        Test-Path -LiteralPath $runDir                              -PathType Container | Should -BeTrue
        Test-Path -LiteralPath (Join-Path $runDir 'result.md')      -PathType Leaf      | Should -BeTrue
        Test-Path -LiteralPath (Join-Path $runDir 'result.json')    -PathType Leaf      | Should -BeFalse
    }

    It 'AC-CY4: stub receives full Codex CLI argument contract (B1 boundary regression)' {
        $project = script:New-CycleCase -CaseName 'cy4'
        $target = Join-Path $project 'a.txt'
        script:Write-Utf8NoBomFile -Path $target -Content "cy4 body`n"
        $stub = script:Write-CodexStub -StubName 'cy4-yes' -Mode 'verdict-yes'

        $runId = '20260506-120000-cy4aaa'
        $r = script:Invoke-ReviewCycle -ProjectRoot $project -TargetFiles @($target) -RunId $runId -StubPath $stub
        $r.ExitCode | Should -Be 0

        $argvDump = Join-Path $project ('log/review/' + $runId + '/result.md.argv.txt')
        Test-Path -LiteralPath $argvDump -PathType Leaf | Should -BeTrue
        $enc = New-Object System.Text.UTF8Encoding($false)
        $argvText = [System.IO.File]::ReadAllText($argvDump, $enc)
        $argvLines = $argvText -split "`n"

        $argvLines | Should -Contain '--ask-for-approval'
        $argvLines | Should -Contain 'never'
        $argvLines | Should -Contain 'exec'
        $argvLines | Should -Contain '--sandbox'
        $argvLines | Should -Contain 'read-only'
        $argvLines | Should -Contain '-c'
        $argvLines | Should -Contain 'web_search=disabled'
        $argvLines | Should -Contain '--model'
        $argvLines | Should -Contain '--output-last-message'
        $argvLines[$argvLines.Count - 1] | Should -Be '-'
    }

    It 'AC-CY-CONTAINMENT-1: -TargetFilesPath outside ProjectLogRoot is rejected before list is read' {
        $project = script:New-CycleCase -CaseName 'cy-containment-1'
        $target = Join-Path $project 'a.txt'
        script:Write-Utf8NoBomFile -Path $target -Content "cy containment body`n"
        $stub = script:Write-CodexStub -StubName 'cy-containment-1-yes' -Mode 'verdict-yes'

        $scriptsDir = Join-Path $project 'scripts'
        $null = New-Item -ItemType Directory -Path $scriptsDir -Force
        $badList = Join-Path $scriptsDir 'foo.list'
        $enc = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($badList, ($target + "`n"), $enc)

        $runId = '20260506-120000-cyc1aa'
        $procArgs = @(
            '-NoProfile', '-ExecutionPolicy', 'Bypass',
            '-File', $script:CycleScript,
            '-Stage', 'implementation',
            '-Purpose', 'pester containment cycle',
            '-ProjectRoot', $project,
            '-ToolRoot', $script:RepoRoot,
            '-RunId', $runId,
            '-Reviewer', 'codex',
            '-Context', 'pester context line.',
            '-RequiredInspectionPaths', 'pester inspection path.',
            '-ReviewQuestions', 'pester review question.',
            '-Constraints', 'pester constraint.',
            '-TargetFilesPath', $badList
        )

        $previousEnv = $env:AI_HARNESS_CODEX_COMMAND
        $previousStubFlag = $env:AI_HARNESS_CODEX_ARGS_FILE_STUB
        $env:AI_HARNESS_CODEX_COMMAND = $stub
        $env:AI_HARNESS_CODEX_ARGS_FILE_STUB = '1'
        try {
            $combined = & powershell.exe @procArgs 2>&1
            $exitCode = $LASTEXITCODE
        }
        finally {
            $env:AI_HARNESS_CODEX_COMMAND = $previousEnv
            $env:AI_HARNESS_CODEX_ARGS_FILE_STUB = $previousStubFlag
        }
        $text = ($combined | ForEach-Object { [string]$_ }) -join "`n"

        $exitCode | Should -Not -Be 0
        $text | Should -Match 'TargetFilesPath outside ProjectLogRoot'

        $runDir = Join-Path $project ('log/review/' + $runId)
        Test-Path -LiteralPath $runDir -PathType Container | Should -BeFalse
    }

    It 'AC-CY6: input-readiness failure preserves run, does not run Codex, and emits the new contract message' {
        $project = script:New-CycleCase -CaseName 'cy6'
        $target = Join-Path $project 'a.txt'
        script:Write-Utf8NoBomFile -Path $target -Content "cy6 body`n"

        $runId = '20260506-120000-cy6aaa'
        $procArgs = @(
            '-NoProfile', '-ExecutionPolicy', 'Bypass',
            '-File', $script:CycleScript,
            '-Stage', 'implementation',
            '-Purpose', 'pester input-not-ready',
            '-ProjectRoot', $project,
            '-ToolRoot', $script:RepoRoot,
            '-RunId', $runId,
            '-Reviewer', 'codex',
            '-RequiredInspectionPaths', 'pester inspection path.',
            '-ReviewQuestions', 'pester review question.',
            '-Constraints', 'pester constraint.',
            '-TargetFiles', $target
        )

        $combined = & powershell.exe @procArgs 2>&1
        $exitCode = $LASTEXITCODE
        $text = ($combined | ForEach-Object { [string]$_ }) -join "`n"

        $exitCode | Should -Not -Be 0
        $text | Should -Match 'FAIL input\.md not ready'
        $text | Should -Match 'Start a new review run'
        $text | Should -Not -Match '[Ee]dit .*input\.md'
        $text | Should -Not -Match 'resume manually'
        $text | Should -Not -Match 'review-verify'

        $runDir = Join-Path $project ('log/review/' + $runId)
        Test-Path -LiteralPath $runDir                           -PathType Container | Should -BeTrue
        Test-Path -LiteralPath (Join-Path $runDir 'result.md')   -PathType Leaf      | Should -BeFalse
        Test-Path -LiteralPath (Join-Path $runDir 'result.json') -PathType Leaf      | Should -BeFalse
    }

    It 'AC-CY-TARGETFILES-COMMA-1: comma-joined single TargetFiles is rejected with explicit diagnostic' {
        $project = script:New-CycleCase -CaseName 'cy-targetfiles-comma-1'
        $a = Join-Path $project 'a.txt'
        $b = Join-Path $project 'b.txt'
        script:Write-Utf8NoBomFile -Path $a -Content "cy comma a body`n"
        script:Write-Utf8NoBomFile -Path $b -Content "cy comma b body`n"

        $runId = '20260508-120000-cytfc1'
        $procArgs = @(
            '-NoProfile', '-ExecutionPolicy', 'Bypass',
            '-File', $script:CycleScript,
            '-Stage', 'implementation',
            '-Purpose', 'pester comma-joined targetfiles',
            '-ProjectRoot', $project,
            '-ToolRoot', $script:RepoRoot,
            '-RunId', $runId,
            '-Reviewer', 'codex',
            '-Context', 'pester context line.',
            '-RequiredInspectionPaths', 'pester inspection path.',
            '-ReviewQuestions', 'pester review question.',
            '-Constraints', 'pester constraint.',
            '-TargetFiles', 'a.txt,b.txt'
        )

        $combined = & powershell.exe @procArgs 2>&1
        $exitCode = $LASTEXITCODE
        $text = ($combined | ForEach-Object { [string]$_ }) -join "`n"

        $exitCode | Should -Not -Be 0
        $text | Should -Match 'review-cycle: FAIL TargetFiles appears to be a comma-separated single string'
        $text | Should -Match '-TargetFilesPath'
        $text | Should -Not -Match 'TargetPath not found'

        $runDir = Join-Path $project ('log/review/' + $runId)
        Test-Path -LiteralPath $runDir                              -PathType Container | Should -BeFalse
        Test-Path -LiteralPath (Join-Path $runDir 'result.md')      -PathType Leaf      | Should -BeFalse
        Test-Path -LiteralPath (Join-Path $runDir 'result.json')    -PathType Leaf      | Should -BeFalse
    }

    It 'AC-CY5: comma in target path is preserved end-to-end through cycle (B2 regression)' {
        $project = script:New-CycleCase -CaseName 'cy5'
        $sub = Join-Path $project 'docs'
        $null = New-Item -ItemType Directory -Path $sub -Force
        $commaPath = Join-Path $sub 'a,b.md'
        script:Write-Utf8NoBomFile -Path $commaPath -Content "cy5 comma body`n"
        $stub = script:Write-CodexStub -StubName 'cy5-yes' -Mode 'verdict-yes'

        $runId = '20260506-120000-cy5aaa'
        $r = script:Invoke-ReviewCycle -ProjectRoot $project -TargetFiles @($commaPath) -RunId $runId -StubPath $stub
        $r.ExitCode | Should -Be 0

        $metaPath = Join-Path $project ('log/review/' + $runId + '/meta.json')
        $enc = New-Object System.Text.UTF8Encoding($false)
        $meta = [System.IO.File]::ReadAllText($metaPath, $enc) | ConvertFrom-Json
        $files = @($meta.targetFiles)
        $files.Count | Should -Be 1
        $files[0].path | Should -Be 'docs/a,b.md'
    }

    It 'AC-CY-NOGIT-1: explicit -TargetFiles + non-Git ProjectRoot does not invoke git status and records meta.sourceHead = null' {
        $project = script:New-CycleCase -CaseName 'cy-nogit-1'
        $target = Join-Path $project 'a.txt'
        script:Write-Utf8NoBomFile -Path $target -Content "cy nogit body`n"
        $stub = script:Write-CodexStub -StubName 'cy-nogit-1-yes' -Mode 'verdict-yes'

        $runId = '20260506-120000-cyn1aa'
        $r = script:Invoke-ReviewCycle -ProjectRoot $project -TargetFiles @($target) -RunId $runId -StubPath $stub
        $r.ExitCode | Should -Be 0 -Because $r.Output
        $r.Output | Should -Match 'review-cycle: PASS'
        $r.Output | Should -Not -Match 'git status failed'
        $r.Output | Should -Not -Match 'no tracked changes detected'

        $metaPath = Join-Path $project ('log/review/' + $runId + '/meta.json')
        $enc = New-Object System.Text.UTF8Encoding($false)
        $meta = [System.IO.File]::ReadAllText($metaPath, $enc) | ConvertFrom-Json

        $meta.PSObject.Properties['sourceHead'] | Should -Not -BeNullOrEmpty
        $meta.sourceHead | Should -Be $null
    }

    It 'AC-CY-NPM-SHIM-1: .ps1 codex shim takes the stdin-pipe branch when AI_HARNESS_CODEX_ARGS_FILE_STUB is unset' {
        $project = script:New-CycleCase -CaseName 'cy-npm-shim-1'
        $target = Join-Path $project 'a.txt'
        script:Write-Utf8NoBomFile -Path $target -Content "cy npm shim body`n"
        $stub = script:Write-NpmShimStub -StubName 'cy-npm-shim-1-yes'

        $stub | Should -Match '\.ps1$'

        $runId = '20260508-120000-cynsh1'
        $procArgs = @(
            '-NoProfile', '-ExecutionPolicy', 'Bypass',
            '-File', $script:CycleScript,
            '-Stage', 'implementation',
            '-Purpose', 'pester npm shim regression',
            '-ProjectRoot', $project,
            '-ToolRoot', $script:RepoRoot,
            '-RunId', $runId,
            '-Reviewer', 'codex',
            '-Context', 'pester context line.',
            '-RequiredInspectionPaths', 'pester inspection path.',
            '-ReviewQuestions', 'pester review question.',
            '-Constraints', 'pester constraint.',
            '-TargetFiles', $target
        )

        $previousEnv = $env:AI_HARNESS_CODEX_COMMAND
        $previousStubFlag = $env:AI_HARNESS_CODEX_ARGS_FILE_STUB
        $env:AI_HARNESS_CODEX_COMMAND = $stub
        if (Test-Path env:AI_HARNESS_CODEX_ARGS_FILE_STUB) {
            Remove-Item env:AI_HARNESS_CODEX_ARGS_FILE_STUB -ErrorAction SilentlyContinue
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

        $exitCode | Should -Be 0 -Because $text
        $text | Should -Match 'review-cycle: PASS'
        $text | Should -Match 'verdict: yes'

        $runDir = Join-Path $project ('log/review/' + $runId)
        Test-Path -LiteralPath (Join-Path $runDir 'result.md')   -PathType Leaf | Should -BeTrue
        Test-Path -LiteralPath (Join-Path $runDir 'result.json') -PathType Leaf | Should -BeTrue

        $argvDump = Join-Path $runDir 'result.md.argv.txt'
        Test-Path -LiteralPath $argvDump -PathType Leaf | Should -BeTrue
        $enc = New-Object System.Text.UTF8Encoding($false)
        $argvText = [System.IO.File]::ReadAllText($argvDump, $enc)
        $argvLines = $argvText -split "`n"
        $argvLines | Should -Contain '--ask-for-approval'
        $argvLines | Should -Contain 'never'
        $argvLines | Should -Contain 'exec'
        $argvLines | Should -Contain '--sandbox'
        $argvLines | Should -Contain 'read-only'
        $argvLines | Should -Contain '-c'
        $argvLines | Should -Contain 'web_search=disabled'
        $argvLines | Should -Contain '--model'
        $argvLines | Should -Contain '--output-last-message'
        $argvLines[$argvLines.Count - 1] | Should -Be '-'

        $stdinFlag = Join-Path $runDir 'result.md.stdin.flag'
        Test-Path -LiteralPath $stdinFlag -PathType Leaf | Should -BeTrue
        ([System.IO.File]::ReadAllText($stdinFlag, $enc)).Trim() | Should -Be 'True'
    }
}
