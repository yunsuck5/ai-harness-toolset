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

    It 'AC-IV4: fails when an active lowercase-suffix placeholder {{AI_TO_FILL_token}} remains (I2 active-placeholder grammar regression)' {
        $caseRoot = script:New-InputVerifyCase -CaseName 'iv4'
        $content = script:Build-FilledInput
        $content = $content.Replace('- Reasoning effort: medium', "- Reasoning effort: medium`n- Custom: {{AI_TO_FILL_token}}")
        $inputPath = Join-Path $caseRoot 'input.md'
        script:Write-Utf8NoBomFile -Path $inputPath -Content $content

        $r = script:Invoke-InputVerify -InputPath $inputPath
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'FAIL unreplaced active placeholder'
    }

    It 'AC-IV5: fails when an active mixed-case-suffix placeholder {{AI_TO_FILL_Token}} remains (I2 active-placeholder grammar regression)' {
        $caseRoot = script:New-InputVerifyCase -CaseName 'iv5'
        $content = script:Build-FilledInput
        $content = $content.Replace('- Reasoning effort: medium', "- Reasoning effort: medium`n- Custom: {{AI_TO_FILL_Token}}")
        $inputPath = Join-Path $caseRoot 'input.md'
        script:Write-Utf8NoBomFile -Path $inputPath -Content $content

        $r = script:Invoke-InputVerify -InputPath $inputPath
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'FAIL unreplaced active placeholder'
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

    It 'AC-IV8: fails when an active uppercase-suffix placeholder {{AI_TO_FILL_TOKEN}} remains (I2 active-placeholder grammar regression)' {
        $caseRoot = script:New-InputVerifyCase -CaseName 'iv8'
        $content = script:Build-FilledInput
        $content = $content.Replace('- Reasoning effort: medium', "- Reasoning effort: medium`n- Custom: {{AI_TO_FILL_TOKEN}}")
        $inputPath = Join-Path $caseRoot 'input.md'
        script:Write-Utf8NoBomFile -Path $inputPath -Content $content

        $r = script:Invoke-InputVerify -InputPath $inputPath
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'FAIL unreplaced active placeholder'
    }

    It 'AC-IV9: fails on the active placeholder when a generic documentation literal is also present (I2 mixed-form regression)' {
        $caseRoot = script:New-InputVerifyCase -CaseName 'iv9'
        $content = script:Build-FilledInput
        $content = $content.Replace('- Reasoning effort: medium', "- Reasoning effort: medium`n- Cite: {{IDENT}}`n- Real: {{AI_TO_FILL_REAL}}")
        $inputPath = Join-Path $caseRoot 'input.md'
        script:Write-Utf8NoBomFile -Path $inputPath -Content $content

        $r = script:Invoke-InputVerify -InputPath $inputPath
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'FAIL unreplaced active placeholder: \{\{AI_TO_FILL_REAL\}\}'
    }

    It 'AC-IV10: fails when a required input H2 appears only in wrong case (H2 case-sensitivity regression)' {
        $caseRoot = script:New-InputVerifyCase -CaseName 'iv10'
        $content = script:Build-FilledInput
        # Lower-case the ## Context heading. With case-sensitive matching the verifier
        # must see "## Context" as missing even though "## context" is on the line.
        $content = $content.Replace('## Context', '## context')
        $inputPath = Join-Path $caseRoot 'input.md'
        script:Write-Utf8NoBomFile -Path $inputPath -Content $content

        $r = script:Invoke-InputVerify -InputPath $inputPath
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'FAIL missing heading: ## Context'
    }

    It 'AC-IV11: passes when a generic documentation literal {{TOKEN}} appears in prose (I2 documentation-literal freedom)' {
        $caseRoot = script:New-InputVerifyCase -CaseName 'iv11'
        $content = script:Build-FilledInput
        $content = $content.Replace('- Reasoning effort: medium', "- Reasoning effort: medium`n- Doc literal: {{TOKEN}}")
        $inputPath = Join-Path $caseRoot 'input.md'
        script:Write-Utf8NoBomFile -Path $inputPath -Content $content

        $r = script:Invoke-InputVerify -InputPath $inputPath
        $r.ExitCode | Should -Be 0 -Because $r.Output
        $r.Output | Should -Match 'review-input-verify: PASS'
    }

    It 'AC-IV12: passes when a generic documentation literal {{TOKEN}} appears inside inline backticks (I2 documentation-literal freedom; not a Markdown exemption)' {
        $caseRoot = script:New-InputVerifyCase -CaseName 'iv12'
        $content = script:Build-FilledInput
        $content = $content.Replace('- Reasoning effort: medium', "- Reasoning effort: medium`n- Doc literal in backticks: ``{{TOKEN}}``")
        $inputPath = Join-Path $caseRoot 'input.md'
        script:Write-Utf8NoBomFile -Path $inputPath -Content $content

        $r = script:Invoke-InputVerify -InputPath $inputPath
        $r.ExitCode | Should -Be 0 -Because $r.Output
        $r.Output | Should -Match 'review-input-verify: PASS'
    }

    It 'AC-IV13: fails when an active placeholder appears inside inline backticks (I2 active-placeholder safety; not a Markdown exemption)' {
        $caseRoot = script:New-InputVerifyCase -CaseName 'iv13'
        $content = script:Build-FilledInput
        $content = $content.Replace('- Reasoning effort: medium', "- Reasoning effort: medium`n- Active in backticks: ``{{AI_TO_FILL_X}}``")
        $inputPath = Join-Path $caseRoot 'input.md'
        script:Write-Utf8NoBomFile -Path $inputPath -Content $content

        $r = script:Invoke-InputVerify -InputPath $inputPath
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'FAIL unreplaced active placeholder: \{\{AI_TO_FILL_X\}\}'
    }

    It 'AC-IV14: fails on the active placeholder when a generic documentation literal is also present (I2 mixed-form precedence)' {
        $caseRoot = script:New-InputVerifyCase -CaseName 'iv14'
        $content = script:Build-FilledInput
        $content = $content.Replace('- Reasoning effort: medium', "- Reasoning effort: medium`n- Doc literal: {{example}}`n- Active: {{AI_TO_FILL_MIXED}}")
        $inputPath = Join-Path $caseRoot 'input.md'
        script:Write-Utf8NoBomFile -Path $inputPath -Content $content

        $r = script:Invoke-InputVerify -InputPath $inputPath
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'FAIL unreplaced active placeholder: \{\{AI_TO_FILL_MIXED\}\}'
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
