Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

BeforeAll {
    $script:RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).ProviderPath
    $script:ReviewVerifyScript = Join-Path $script:RepoRoot 'scripts/review-verify.ps1'
    $script:FixtureRoot = Join-Path $script:RepoRoot 'log/review'

    function script:Get-Sha256Lower {
        param([string] $Path)
        return ((Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant())
    }

    function script:Write-Utf8NoBomFile {
        param(
            [string] $Path,
            [string] $Content
        )
        $parent = Split-Path -LiteralPath $Path
        if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
            $null = New-Item -ItemType Directory -Path $parent -Force
        }
        $resolved = [System.IO.Path]::GetFullPath($Path)
        $encoding = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($resolved, $Content, $encoding)
    }

    function script:New-PesterTestCaseRoot {
        param([string] $CaseName)
        $caseRoot = Join-Path $script:FixtureRoot ('pester-review-verify-' + $CaseName)
        if (Test-Path -LiteralPath $caseRoot) {
            Remove-Item -LiteralPath $caseRoot -Recurse -Force
        }
        $null = New-Item -ItemType Directory -Path $caseRoot -Force
        return ([System.IO.Path]::GetFullPath($caseRoot))
    }

    function script:New-MetaPayload {
        param(
            [string] $ProjectRoot,
            [string] $RunId,
            [string] $TargetPath,
            [string] $TargetSha256
        )
        $logRoot = [System.IO.Path]::GetFullPath((Join-Path $ProjectRoot 'log'))
        return [ordered]@{
            schemaVersion      = 1
            runId              = $RunId
            createdAtUtc       = (Get-Date).ToUniversalTime().ToString('o')
            projectRoot        = $ProjectRoot
            toolRoot           = $ProjectRoot
            projectLogRoot     = $logRoot
            targetPath         = $TargetPath
            targetRelativePath = 'target.txt'
            targetSha256       = $TargetSha256
            stage              = 'design'
            purpose            = 'pester regression'
            reviewer           = 'codex'
            sourceHead         = $null
            reviewerConfig     = [ordered]@{
                provider        = 'openai'
                model           = 'gpt-5.5'
                fallbackModel   = 'gpt-5.4'
                reasoningEffort = 'medium'
                timeoutSeconds  = 300
                sandbox         = 'read-only'
            }
            freshnessPolicy    = [ordered]@{
                type    = 'target-sha256-match'
                failure = 'fail'
            }
        }
    }

    function script:Initialize-FreshPacket {
        param(
            [string] $CaseName,
            [string] $RunId = '20260430-120000-aaaaaa',
            [string] $TargetContent = "pester target body`n"
        )
        $projectRoot = script:New-PesterTestCaseRoot -CaseName $CaseName

        $targetPath = Join-Path $projectRoot 'target.txt'
        script:Write-Utf8NoBomFile -Path $targetPath -Content $TargetContent
        $resolvedTarget = [System.IO.Path]::GetFullPath($targetPath)
        $targetSha = script:Get-Sha256Lower -Path $resolvedTarget

        $runDir = Join-Path $projectRoot ('log/review/' + $RunId)
        $null = New-Item -ItemType Directory -Path $runDir -Force

        $meta = script:New-MetaPayload `
            -ProjectRoot $projectRoot `
            -RunId $RunId `
            -TargetPath $resolvedTarget `
            -TargetSha256 $targetSha

        $metaPath = Join-Path $runDir 'meta.json'
        $metaJson = $meta | ConvertTo-Json -Depth 32
        script:Write-Utf8NoBomFile -Path $metaPath -Content $metaJson

        $inputPath = Join-Path $runDir 'input.md'
        script:Write-Utf8NoBomFile -Path $inputPath -Content "# Review Input`n- Run ID: $RunId`n"

        return [pscustomobject]@{
            ProjectRoot = $projectRoot
            RunId       = $RunId
            RunDir      = $runDir
            TargetPath  = $resolvedTarget
            TargetSha   = $targetSha
            MetaPath    = $metaPath
            InputPath   = $inputPath
        }
    }

    function script:Add-ResultArtifacts {
        param(
            [pscustomobject] $Packet,
            [string] $Verdict = 'yes',
            [string] $TargetShaOverride = '',
            [string] $RunIdOverride = '',
            [switch] $SkipResultMarkdown
        )

        $resultMdPath = Join-Path $Packet.RunDir 'result.md'
        if (-not $SkipResultMarkdown) {
            script:Write-Utf8NoBomFile -Path $resultMdPath -Content "# Review Result`nVerdict: $Verdict`n"
        }

        $inputSha = script:Get-Sha256Lower -Path $Packet.InputPath
        $resultMdSha = ''
        if (Test-Path -LiteralPath $resultMdPath -PathType Leaf) {
            $resultMdSha = script:Get-Sha256Lower -Path $resultMdPath
        }

        $effectiveTargetSha = $Packet.TargetSha
        if (-not [string]::IsNullOrEmpty($TargetShaOverride)) {
            $effectiveTargetSha = $TargetShaOverride
        }
        $effectiveRunId = $Packet.RunId
        if (-not [string]::IsNullOrEmpty($RunIdOverride)) {
            $effectiveRunId = $RunIdOverride
        }

        $obj = [ordered]@{
            schemaVersion        = 1
            runId                = $effectiveRunId
            targetSha256         = $effectiveTargetSha
            inputSha256          = $inputSha
            resultMarkdownSha256 = $resultMdSha
            verdict              = $Verdict
        }
        $resultJsonPath = Join-Path $Packet.RunDir 'result.json'
        script:Write-Utf8NoBomFile -Path $resultJsonPath -Content (($obj | ConvertTo-Json -Depth 32))
    }

    function script:Invoke-ReviewVerify {
        param(
            [string] $ProjectRoot,
            [string] $RunId,
            [switch] $RequireResult
        )
        $procArgs = @(
            '-NoProfile',
            '-ExecutionPolicy', 'Bypass',
            '-File', $script:ReviewVerifyScript,
            '-RunId', $RunId,
            '-ProjectRoot', $ProjectRoot
        )
        if ($RequireResult) { $procArgs += '-RequireResult' }

        $combined = & powershell.exe @procArgs 2>&1
        $exitCode = $LASTEXITCODE
        $text = ($combined | ForEach-Object { [string]$_ }) -join "`n"

        return [pscustomobject]@{
            ExitCode = $exitCode
            Output   = $text
        }
    }
}

Describe 'review-verify default mode' {
    It 'AC1: passes for a fresh packet' {
        $packet = script:Initialize-FreshPacket -CaseName 'ac1'
        $result = script:Invoke-ReviewVerify -ProjectRoot $packet.ProjectRoot -RunId $packet.RunId
        $result.ExitCode | Should -Be 0
        $result.Output | Should -Match 'review-verify: PASS'
    }

    It 'AC2: fails when target file is stale (sha mismatch)' {
        $packet = script:Initialize-FreshPacket -CaseName 'ac2'
        script:Write-Utf8NoBomFile -Path $packet.TargetPath -Content "pester target body MUTATED`n"

        $result = script:Invoke-ReviewVerify -ProjectRoot $packet.ProjectRoot -RunId $packet.RunId
        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match 'FAIL stale'
    }

    It 'AC5: rejects RunId containing path traversal' {
        $packet = script:Initialize-FreshPacket -CaseName 'ac5'
        $result = script:Invoke-ReviewVerify -ProjectRoot $packet.ProjectRoot -RunId '../evil'
        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match 'FAIL invalid RunId'
    }

    It 'AC15: passes when result.md and result.json are absent' {
        $packet = script:Initialize-FreshPacket -CaseName 'ac15'
        Test-Path -LiteralPath (Join-Path $packet.RunDir 'result.md')   | Should -BeFalse
        Test-Path -LiteralPath (Join-Path $packet.RunDir 'result.json') | Should -BeFalse

        $result = script:Invoke-ReviewVerify -ProjectRoot $packet.ProjectRoot -RunId $packet.RunId
        $result.ExitCode | Should -Be 0
        $result.Output | Should -Match 'review-verify: PASS'
        $result.Output | Should -Match 'result.md not present'
    }
}

Describe 'review-verify -RequireResult mode' {
    It 'AC16: passes when result.md and result.json are valid and bound to meta' {
        $packet = script:Initialize-FreshPacket -CaseName 'ac16'
        script:Add-ResultArtifacts -Packet $packet -Verdict 'yes'

        $result = script:Invoke-ReviewVerify -ProjectRoot $packet.ProjectRoot -RunId $packet.RunId -RequireResult
        $result.ExitCode | Should -Be 0
        $result.Output | Should -Match 'result.json present and binding verified'
        $result.Output | Should -Match 'review-verify: PASS'
    }

    It 'AC17: fails when result.md is missing' {
        $packet = script:Initialize-FreshPacket -CaseName 'ac17'
        script:Add-ResultArtifacts -Packet $packet -Verdict 'yes' -SkipResultMarkdown

        $result = script:Invoke-ReviewVerify -ProjectRoot $packet.ProjectRoot -RunId $packet.RunId -RequireResult
        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match 'FAIL result\.md missing'
    }

    It 'AC18: fails when result.json targetSha256 does not match meta' {
        $packet = script:Initialize-FreshPacket -CaseName 'ac18'
        $bogusSha = '0000000000000000000000000000000000000000000000000000000000000000'
        script:Add-ResultArtifacts -Packet $packet -Verdict 'yes' -TargetShaOverride $bogusSha

        $result = script:Invoke-ReviewVerify -ProjectRoot $packet.ProjectRoot -RunId $packet.RunId -RequireResult
        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match 'FAIL result\.json targetSha256 mismatch'
    }

    It 'AC19: fails when result.json verdict is not in the allowed set' {
        $packet = script:Initialize-FreshPacket -CaseName 'ac19'
        script:Add-ResultArtifacts -Packet $packet -Verdict 'maybe'

        $result = script:Invoke-ReviewVerify -ProjectRoot $packet.ProjectRoot -RunId $packet.RunId -RequireResult
        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match 'FAIL result\.json verdict invalid'
    }
}
