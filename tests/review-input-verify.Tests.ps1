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
        $body += '- Reviewer model: test-model-x'
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

Describe 'templates/review-input.md compact authoring reference' {
    It 'AC-IV-OC1: template keeps the input skeleton without duplicating the result runtime shape' {
        $repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).ProviderPath
        $templatePath = Join-Path $repoRoot 'templates/review-input.md'
        Test-Path -LiteralPath $templatePath -PathType Leaf | Should -BeTrue

        $enc = New-Object System.Text.UTF8Encoding($false)
        $content = [System.IO.File]::ReadAllText($templatePath, $enc)

        foreach ($heading in @('## Context', '## Required inspection paths', '## Review questions', '## Constraints', '## Final verdict')) {
            $content | Should -Match ('(?m)^' + [regex]::Escape($heading) + '$')
        }
        $content | Should -Match '\{\{AI_TO_FILL_CONTEXT\}\}'
        $content | Should -Match '(?m)^yes / no / yes with risk$'
        $content | Should -Match 'runner preamble'
        $content | Should -Match 'transient라는 이유만으로 finding을 자동 nonblocking 처리하지 않으며'
        $content | Should -Match 'committed temporary artifact도 존재하는 동안 실제 review target이다'
        $content | Should -Match '원본 path/section에서 exact text를 확인하고'
        $content | Should -Match '변동 가능한 count는 작성 직전 현재 상태에서 기계 재계산하며'
        $content | Should -Match 'false-positive 판정에는 evidence와 사용자의 명시 결정을 요구한다'
        $content | Should -Match '`-ExternalReadDirectory` / `-ExternalReadFile`'
        $content | Should -Match '직접 읽게 하며'
        $content | Should -Match 'Load-bearing target을 읽을 수 없으면 verdict를 만들지 않고 review unavailable'
        $content | Should -Not -Match 'verbatim inline|inline fallback'
        $content | Should -Not -Match '(?m)^## (Blocking findings|Non-blocking concerns|Review limitations|Assumptions relied on|Findings|Risks)$'
    }
}

Describe 'source ai-harness-review skill compact judgment core' {
    It 'AC-IV-OC2: skill retains compact judgment core and two canonical point-of-use contract lines' {
        $repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).ProviderPath
        $skillPath = Join-Path $repoRoot 'snippets/claude-skills/ai-harness-review/SKILL.md'
        Test-Path -LiteralPath $skillPath -PathType Leaf | Should -BeTrue

        $enc = New-Object System.Text.UTF8Encoding($false)
        $content = [System.IO.File]::ReadAllText($skillPath, $enc)

        $preserveMatch = [regex]::Match($content, '(?ms)^### 0\. Preserve context and resolve roots\r?\n(?<body>.*?)(?=^### 1\. Bind the target accurately$)')
        $runMatch = [regex]::Match($content, '(?ms)^### 4\. Run each review unit once\r?\n(?<body>.*?)(?=^### 5\. Perform semantic intake$)')
        $intakeMatch = [regex]::Match($content, '(?ms)^### 5\. Perform semantic intake\r?\n(?<body>.*?)(?=^### 6\. Reduce and report$)')
        $failureMatch = [regex]::Match($content, '(?ms)^## Failure and non-goals\r?\n(?<body>.*)\z')
        foreach ($match in @($preserveMatch, $runMatch, $intakeMatch, $failureMatch)) {
            $match.Success | Should -BeTrue
        }
        $preserve = $preserveMatch.Groups['body'].Value
        $run = $runMatch.Groups['body'].Value
        $intake = $intakeMatch.Groups['body'].Value
        $failure = $failureMatch.Groups['body'].Value

        $content | Should -Match '`local-correctness` and `system-coherence`'
        $content | Should -Match '`coverage-limited`'
        $content | Should -Match 'caller-side `no-reviewable-change` report, not a verdict'
        $content | Should -Match 'project-rule-qualified retirement-only closeout'
        $content | Should -Match 'apply any active project rule that defines a retirement-only closeout transaction predicate'
        $content | Should -Match 'Inspect the proposed closeout transaction itself and its complete source delta'
        $content | Should -Match 'If it exactly matches the rule''s allowed retirement shape, issue `no-reviewable-change` and stop without prepare/run'
        $content | Should -Match '(?m)^If the review-bound source-managed artifact set changes.*source-managed bytes/content, path, Git mode, or target-relevant meaning.*that unit is stale\.'
        $content | Should -Match 'A predicate miss or any other change to the review-bound artifact set, source-managed bytes/content, path, Git mode, or target-relevant meaning uses ordinary staleness'
        $content | Should -Match 'original path and section and confirm the exact text'
        $content | Should -Match 'Recalculate mutable counts against current state immediately before authoring'
        $content | Should -Match 'false-positive dismissal requires evidence and an explicit user decision'
        $content | Should -Match '`-ExternalReadDirectory` and files with `-ExternalReadFile`'
        $content | Should -Match 'The reviewer reads them directly'
        $content | Should -Match 'consume no verdict and report the review as unavailable'
        $content | Should -Not -Match 'verbatim inline|inline fallback'
        $content | Should -Match 'usable member results conflict'
        $content | Should -Match 'no evidence-bound basis to reduce the conflict'
        $content | Should -Match 'stop and report it; do not merge or conclude'
        $content | Should -Match 'failed or semantically unusable unit'
        $content | Should -Match 'proposed corrected invocation or input'
        $content | Should -Match 'wait for explicit scoped user approval before allocating or running a new pass'
        $content | Should -Match 'Once `review-run` starts, do not edit `input\.md`'
        $content | Should -Match 'newly prepared canonical pass directory is the only runtime artifact location this workflow may write'
        $content | Should -Match 'Do not edit an existing or failed pass'
        $content | Should -Match 'stop and report instead of expanding scope'
        $content | Should -Match 'reviewer CLI is unavailable'
        $content | Should -Match 'do not install or refresh it'
        $preserve | Should -Match 'existing facts available through authorized read-only inspection'
        $preserve | Should -Match 'usable pre-change engine excluding every included review-machinery change'
        $preserve | Should -Match 'Do not create a checkout or generate or persist a hash, preimage, byte/content binding, comparison artifact, or evidence bundle solely to prove engine eligibility\.'
        $preserve | Should -Match 'stop and report an engine-eligibility gap'
        $intake | Should -Match 'concrete failure mode or path, or a direct contract or acceptance breach'
        $intake | Should -Match 'affected consumer or decision'
        $intake | Should -Match 'failed function, outcome, or contract'
        $intake | Should -Match 'Unknown or missing information, or an unperformed check, is not by itself a blocker unless that absence directly breaches an explicit contract requirement\.'
        $intake | Should -Match '`in-scope correction`'
        $intake | Should -Match '`out-of-scope stop`'
        $intake | Should -Match '`reviewer overreach`'
        $intake | Should -Match '`false-positive or evidence gap`'
        $intake | Should -Match 'Classify every rational blocker into exactly one operator disposition'
        $intake | Should -Match 'evidence-bound explanation and explicit user disposition'
        $intake | Should -Match 'neither automatically dismisses the finding or converts `no` into another verdict'
        $intake | Should -Match 'Preserve the prior `no` and its findings in the write-once canonical pass as historical fact'
        $run | Should -Match 'Before any follow-up pass, record its closure basis'
        $run | Should -Match 'corrected or clarified material claim/input that could change the review'
        $run | Should -Match 'blocker-bound explicit user disposition that changes the allowed next action'
        $run | Should -Match 'when the reviewed state, evidence, material claim, and blocker disposition are unchanged, stop and report instead of allocating another pass\.'
        $failure | Should -Match 'repeat a pass with unchanged reviewed state/evidence/material claim/blocker disposition'
        $introMatch = [regex]::Match($content, '(?ms)\A(?<body>.*?)(?=^## Supported intents$)')
        $introMatch.Success | Should -BeTrue
        $intro = $introMatch.Groups['body'].Value
        $verdictGuidanceLines = @($intro -split '\r?\n' | Where-Object { $_ -match 'canonical reviewer verdict' })
        $verdictGuidanceLines.Count | Should -Be 1
        $verdictGuidance = $verdictGuidanceLines[0]
        # 이 두 줄만 배포 SKILL의 canonical contract line으로 정확히 보존한다. 자연어 의미동등성 parser가 아니다.
        ($verdictGuidance -ceq 'Only a semantically usable reviewer-unit result produced through `review-run.ps1` supplies a canonical reviewer verdict; caller self-review supplies packet context and a separate caller judgment, never a substitute reviewer verdict.') | Should -BeTrue

        $allocateMatch = [regex]::Match($content, '(?ms)^### 2\. Allocate one write-once unit\r?\n(?<body>.*?)(?=^### 3\. Author `input\.md`$)')
        $allocateMatch.Success | Should -BeTrue
        $allocate = $allocateMatch.Groups['body'].Value
        $stageGuidanceLines = @($allocate -split '\r?\n' | Where-Object { $_ -match 'for `<stage>`' })
        $stageGuidanceLines.Count | Should -Be 1
        $stageGuidance = $stageGuidanceLines[0]
        ($stageGuidance -ceq 'Use `design`, `implementation`, `test`, `review`, or `release` for `<stage>`; choose `implementation` for an ordinary code change unless a more specific review stage applies.') | Should -BeTrue
    }
}

Describe 'templates/review-result.md compact result skeleton' {
    It 'AC-IV-OC3: result template has no default verdict or generic Findings/Risks buckets' {
        $repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).ProviderPath
        $templatePath = Join-Path $repoRoot 'templates/review-result.md'
        Test-Path -LiteralPath $templatePath -PathType Leaf | Should -BeTrue

        $enc = New-Object System.Text.UTF8Encoding($false)
        $content = [System.IO.File]::ReadAllText($templatePath, $enc)

        (@($content -split "`r?`n" | Where-Object { $_ -ceq '## Verdict' })).Count | Should -Be 1
        $content | Should -Match '(?ms)^## Verdict\r?\n\r?\n\{\{AI_TO_FILL_VERDICT\}\}'
        foreach ($heading in @('## Blocking findings', '## Non-blocking concerns', '## Review limitations', '## Assumptions relied on')) {
            (@($content -split "`r?`n" | Where-Object { $_ -ceq $heading })).Count | Should -Be 1
        }
        $content | Should -Not -Match '(?m)^## (Findings|Risks)$'
        $content | Should -Match '(?m)^## Counter-argument$'
        $content | Should -Match '(?m)^## Notes$'
        $content | Should -Match 'named risk의 단일 위치'
    }
}
