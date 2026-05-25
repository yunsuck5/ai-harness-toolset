Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

BeforeAll {
    $script:RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).ProviderPath
    . (Join-Path $script:RepoRoot 'scripts/lib/native-process.ps1')
    $script:Script = Join-Path $script:RepoRoot 'scripts/review-input-verify.ps1'

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

    function script:New-InputVerifyCase {
        param([string] $CaseName)
        $caseRoot = Join-Path $TestDrive ('pester-review-input-verify-' + $CaseName)
        if (Test-Path -LiteralPath $caseRoot) {
            Remove-Item -LiteralPath $caseRoot -Recurse -Force
        }
        $null = New-Item -ItemType Directory -Path $caseRoot -Force
        return ([System.IO.Path]::GetFullPath($caseRoot))
    }

    function script:Build-FilledInput {
        $body = @()
        $body += '# Review Input'
        $body += ''
        $body += '- Run ID: r1'
        $body += '- Target path: a.txt'
        $body += '- Target SHA-256: deadbeef'
        $body += '- Stage: design'
        $body += '- Purpose: pester'
        $body += '- Reviewer: codex'
        $body += '- Source HEAD: '
        $body += '- Reviewer model: gpt-5.5'
        $body += '- Reasoning effort: medium'
        $body += ''
        $body += '## Context'
        $body += ''
        $body += 'real context line.'
        $body += ''
        $body += '## Required inspection paths'
        $body += ''
        $body += 'real inspection path line.'
        $body += ''
        $body += '## Review questions'
        $body += ''
        $body += 'real review question line.'
        $body += ''
        $body += '## Constraints'
        $body += ''
        $body += 'real constraint line.'
        $body += ''
        $body += '## Final verdict'
        $body += ''
        $body += 'yes / no / yes with risk'
        $body += ''
        return ($body -join "`n")
    }

    function script:Invoke-InputVerify {
        param([string] $InputPath)
        $procArgs = @(
            '-NoProfile', '-ExecutionPolicy', 'Bypass',
            '-File', $script:Script,
            '-InputPath', $InputPath
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

Describe 'review-input-verify' {
    It 'AC-IV1: passes when all 5 sections are filled and no placeholder remains' {
        $caseRoot = script:New-InputVerifyCase -CaseName 'iv1'
        $inputPath = Join-Path $caseRoot 'input.md'
        script:Write-Utf8NoBomFile -Path $inputPath -Content (script:Build-FilledInput)

        $r = script:Invoke-InputVerify -InputPath $inputPath
        $r.ExitCode | Should -Be 0
        $r.Output | Should -Match 'review-input-verify: PASS'
    }

    It 'AC-IV2: fails when the Constraints heading is missing' {
        $caseRoot = script:New-InputVerifyCase -CaseName 'iv2'
        $content = script:Build-FilledInput
        $content = $content.Replace('## Constraints', '## NotConstraints')
        $inputPath = Join-Path $caseRoot 'input.md'
        script:Write-Utf8NoBomFile -Path $inputPath -Content $content

        $r = script:Invoke-InputVerify -InputPath $inputPath
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'FAIL missing heading: ## Constraints'
    }

    It 'AC-IV3: fails when placeholder text remains in a non-verdict section' {
        $caseRoot = script:New-InputVerifyCase -CaseName 'iv3'
        $content = script:Build-FilledInput
        $content = $content.Replace('real inspection path line.', '(Replace this placeholder with paths the reviewer must inspect.)')
        $inputPath = Join-Path $caseRoot 'input.md'
        script:Write-Utf8NoBomFile -Path $inputPath -Content $content

        $r = script:Invoke-InputVerify -InputPath $inputPath
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'FAIL placeholder remains in ## Required inspection paths'
    }

    It 'AC-IV4: fails when lowercase {{token}} remains (B3 regression)' {
        $caseRoot = script:New-InputVerifyCase -CaseName 'iv4'
        $content = script:Build-FilledInput
        $content = $content.Replace('- Reasoning effort: medium', "- Reasoning effort: medium`n- Custom: {{token}}")
        $inputPath = Join-Path $caseRoot 'input.md'
        script:Write-Utf8NoBomFile -Path $inputPath -Content $content

        $r = script:Invoke-InputVerify -InputPath $inputPath
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'FAIL unreplaced template token'
    }

    It 'AC-IV5: fails when mixed-case {{Token}} remains (B3 regression)' {
        $caseRoot = script:New-InputVerifyCase -CaseName 'iv5'
        $content = script:Build-FilledInput
        $content = $content.Replace('- Reasoning effort: medium', "- Reasoning effort: medium`n- Custom: {{Token}}")
        $inputPath = Join-Path $caseRoot 'input.md'
        script:Write-Utf8NoBomFile -Path $inputPath -Content $content

        $r = script:Invoke-InputVerify -InputPath $inputPath
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'FAIL unreplaced template token'
    }

    It 'AC-IV6: fails when placeholder text remains under ## Final verdict (B3 regression)' {
        $caseRoot = script:New-InputVerifyCase -CaseName 'iv6'
        $content = script:Build-FilledInput
        $content = $content.Replace(
            'yes / no / yes with risk',
            "yes / no / yes with risk`n`n(Replace this placeholder with explicit constraints.)"
        )
        $inputPath = Join-Path $caseRoot 'input.md'
        script:Write-Utf8NoBomFile -Path $inputPath -Content $content

        $r = script:Invoke-InputVerify -InputPath $inputPath
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'FAIL placeholder remains in ## Final verdict'
    }
}

Describe 'templates/review-input.md output contract regression' {
    It 'AC-IV-OC1: template includes strict result.md output contract phrases' {
        $repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).ProviderPath
        $templatePath = Join-Path $repoRoot 'templates/review-input.md'
        Test-Path -LiteralPath $templatePath -PathType Leaf | Should -BeTrue

        $enc = New-Object System.Text.UTF8Encoding($false)
        $content = [System.IO.File]::ReadAllText($templatePath, $enc)

        $content | Should -Match '## Verdict'
        $content | Should -Match 'result\.md'
        $content | Should -Match 'yes with risk'
        $content | Should -Match 'inline'
    }
}
