Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

BeforeAll {
    $script:RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).ProviderPath
    . (Join-Path $script:RepoRoot 'scripts/lib/native-process.ps1')
    $script:ReviewVerifyScript = Join-Path $script:RepoRoot 'scripts/review-verify.ps1'

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

    function script:New-VerifyCase {
        param([string] $CaseName)
        $caseRoot = Join-Path $TestDrive ('pester-review-verify-' + $CaseName)
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
        $body += '## Stage'
        $body += ''
        $body += 'implementation'
        $body += ''
        $body += '## Purpose'
        $body += ''
        $body += 'pester verify.'
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

    function script:Build-ResultMd {
        param([string] $Verdict = 'yes')
        $body = @()
        $body += '# Review Result'
        $body += ''
        $body += '## Verdict'
        $body += ''
        $body += $Verdict
        $body += ''
        $body += '## Findings'
        $body += ''
        $body += 'No blocking findings.'
        $body += ''
        $body += '## Blocking findings'
        $body += ''
        $body += 'none'
        $body += ''
        $body += '## Non-blocking concerns'
        $body += ''
        $body += 'none'
        $body += ''
        $body += '## Review limitations'
        $body += ''
        $body += 'none'
        $body += ''
        $body += '## Assumptions relied on'
        $body += ''
        $body += 'none'
        $body += ''
        return ($body -join "`n")
    }

    function script:Initialize-CanonicalPass {
        param(
            [string] $CaseName,
            [string] $ReviewTaskId = 'verify-task',
            [string] $Pass = 'pass-01',
            [switch] $WithResult,
            [string] $Verdict = 'yes',
            [string] $ResultBodyOverride
        )
        $projectRoot = script:New-VerifyCase -CaseName $CaseName
        $passDir = Join-Path $projectRoot ('log/review/' + $ReviewTaskId + '/' + $Pass)
        $null = New-Item -ItemType Directory -Path $passDir -Force
        $inputPath = Join-Path $passDir 'input.md'
        script:Write-Utf8NoBomFile -Path $inputPath -Content (script:Build-FilledInput)

        $resultPath = Join-Path $passDir 'result.md'
        if ($WithResult -or -not [string]::IsNullOrEmpty($ResultBodyOverride)) {
            $content = ''
            if (-not [string]::IsNullOrEmpty($ResultBodyOverride)) {
                $content = $ResultBodyOverride
            }
            else {
                $content = script:Build-ResultMd -Verdict $Verdict
            }
            script:Write-Utf8NoBomFile -Path $resultPath -Content $content
        }

        return [pscustomobject]@{
            ProjectRoot   = $projectRoot
            ReviewTaskId  = $ReviewTaskId
            Pass          = $Pass
            PassDir       = $passDir
            InputPath     = $inputPath
            ResultPath    = $resultPath
        }
    }

    function script:Invoke-ReviewVerify {
        param(
            [string] $ProjectRoot,
            [string] $ReviewTaskId,
            [string] $Pass,
            [string] $ToolRoot,
            [switch] $RequireResult
        )
        $procArgs = @(
            '-NoProfile',
            '-ExecutionPolicy', 'Bypass',
            '-File', $script:ReviewVerifyScript,
            '-ReviewTaskId', $ReviewTaskId,
            '-Pass', $Pass,
            '-ProjectRoot', $ProjectRoot
        )
        if ([string]::IsNullOrEmpty($ToolRoot)) {
            $ToolRoot = $script:RepoRoot
        }
        $procArgs += @('-ToolRoot', $ToolRoot)
        if ($RequireResult) { $procArgs += '-RequireResult' }

        $proc = Invoke-NativeProcess -Executable 'powershell.exe' -Arguments $procArgs
        $exitCode = $proc.ExitCode
        $text = (($proc.Stdout + $proc.Stderr) -replace "`r`n", "`n").TrimEnd("`n")

        return [pscustomobject]@{
            ExitCode = $exitCode
            Output   = $text
        }
    }
}

Describe 'review-verify default mode (canonical)' {
    It 'AC-VF1: passes when only canonical input.md is present (no sidecars required)' {
        $packet = script:Initialize-CanonicalPass -CaseName 'vf1'
        $r = script:Invoke-ReviewVerify -ProjectRoot $packet.ProjectRoot -ReviewTaskId $packet.ReviewTaskId -Pass $packet.Pass
        $r.ExitCode | Should -Be 0 -Because $r.Output
        $r.Output | Should -Match 'review-verify: PASS'
        $r.Output | Should -Match 'result.md not present'
    }

    It 'AC-VF2: fails when input.md is missing' {
        $packet = script:Initialize-CanonicalPass -CaseName 'vf2'
        Remove-Item -LiteralPath $packet.InputPath -Force

        $r = script:Invoke-ReviewVerify -ProjectRoot $packet.ProjectRoot -ReviewTaskId $packet.ReviewTaskId -Pass $packet.Pass
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'input\.md missing'
    }

    It 'AC-VF3: fails when input.md is shape-invalid' {
        $packet = script:Initialize-CanonicalPass -CaseName 'vf3'
        script:Write-Utf8NoBomFile -Path $packet.InputPath -Content "# Review Input`n"   # no required headings

        $r = script:Invoke-ReviewVerify -ProjectRoot $packet.ProjectRoot -ReviewTaskId $packet.ReviewTaskId -Pass $packet.Pass
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'input\.md shape invalid'
    }

    It 'AC-VF4: rejects ReviewTaskId containing path traversal' {
        $packet = script:Initialize-CanonicalPass -CaseName 'vf4'
        $r = script:Invoke-ReviewVerify -ProjectRoot $packet.ProjectRoot -ReviewTaskId '../escape' -Pass $packet.Pass
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'invalid ReviewTaskId'
    }

    It 'AC-VF5: rejects Pass that is not pass-NN shape' {
        $packet = script:Initialize-CanonicalPass -CaseName 'vf5'
        $r = script:Invoke-ReviewVerify -ProjectRoot $packet.ProjectRoot -ReviewTaskId $packet.ReviewTaskId -Pass 'pass-1'
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'invalid Pass'
    }

    It 'AC-VF6: passes when result.md is also present (informational, default mode)' {
        $packet = script:Initialize-CanonicalPass -CaseName 'vf6' -WithResult -Verdict 'yes'
        $r = script:Invoke-ReviewVerify -ProjectRoot $packet.ProjectRoot -ReviewTaskId $packet.ReviewTaskId -Pass $packet.Pass
        $r.ExitCode | Should -Be 0 -Because $r.Output
        $r.Output | Should -Match 'result.md present'
        $r.Output | Should -Match 'review-verify: PASS'
    }

    It 'AC-VF7: pass directory not found is reported as FAIL (no implicit creation)' {
        $project = script:New-VerifyCase -CaseName 'vf7'
        # Create just the log/review/ root so containment checks pass.
        $null = New-Item -ItemType Directory -Path (Join-Path $project 'log/review') -Force
        $r = script:Invoke-ReviewVerify -ProjectRoot $project -ReviewTaskId 'never-prepared' -Pass 'pass-01'
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'pass directory not found'
    }
}

Describe 'review-verify -RequireResult mode (canonical)' {
    It 'AC-VF-RR1: passes on canonical input.md + result.md alone (no meta.json / result.json needed)' {
        $packet = script:Initialize-CanonicalPass -CaseName 'rr-pass' -WithResult -Verdict 'yes'

        # Prove there are no sidecars on disk.
        Test-Path -LiteralPath (Join-Path $packet.PassDir 'meta.json')         -PathType Leaf | Should -BeFalse
        Test-Path -LiteralPath (Join-Path $packet.PassDir 'result.json')       -PathType Leaf | Should -BeFalse
        Test-Path -LiteralPath (Join-Path $packet.PassDir 'target-files.list') -PathType Leaf | Should -BeFalse

        $r = script:Invoke-ReviewVerify -ProjectRoot $packet.ProjectRoot -ReviewTaskId $packet.ReviewTaskId -Pass $packet.Pass -RequireResult
        $r.ExitCode | Should -Be 0 -Because $r.Output
        $r.Output | Should -Match 'verdict shape valid'
        $r.Output | Should -Match 'verdict=yes'
        $r.Output | Should -Match 'review-verify: PASS'
    }

    It 'AC-VF-RR2: passes when verdict is "no"' {
        $packet = script:Initialize-CanonicalPass -CaseName 'rr-no' -WithResult -Verdict 'no'
        $r = script:Invoke-ReviewVerify -ProjectRoot $packet.ProjectRoot -ReviewTaskId $packet.ReviewTaskId -Pass $packet.Pass -RequireResult
        $r.ExitCode | Should -Be 0 -Because $r.Output
        $r.Output | Should -Match 'verdict=no'
    }

    It 'AC-VF-RR3: passes when verdict is "yes with risk"' {
        $packet = script:Initialize-CanonicalPass -CaseName 'rr-ywr' -WithResult -Verdict 'yes with risk'
        $r = script:Invoke-ReviewVerify -ProjectRoot $packet.ProjectRoot -ReviewTaskId $packet.ReviewTaskId -Pass $packet.Pass -RequireResult
        $r.ExitCode | Should -Be 0 -Because $r.Output
        $r.Output | Should -Match 'verdict=yes with risk'
    }

    It 'AC-VF-RR4: fails when result.md is missing' {
        $packet = script:Initialize-CanonicalPass -CaseName 'rr-missing'
        $r = script:Invoke-ReviewVerify -ProjectRoot $packet.ProjectRoot -ReviewTaskId $packet.ReviewTaskId -Pass $packet.Pass -RequireResult
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'result\.md missing'
    }

    It 'AC-VF-RR5: fails when result.md has no "## Verdict" heading' {
        $packet = script:Initialize-CanonicalPass -CaseName 'rr-noverdict'
        script:Write-Utf8NoBomFile -Path $packet.ResultPath -Content "# Review Result`n`nNo verdict heading.`n"
        $r = script:Invoke-ReviewVerify -ProjectRoot $packet.ProjectRoot -ReviewTaskId $packet.ReviewTaskId -Pass $packet.Pass -RequireResult
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'verdict shape invalid'
        $r.Output | Should -Match 'no "## Verdict" heading found'
    }

    It 'AC-VF-RR6: fails when result.md has two "## Verdict" headings' {
        $packet = script:Initialize-CanonicalPass -CaseName 'rr-twoverdict'
        $body = "# Review Result`n`n## Verdict`n`nyes`n`n## Verdict`n`nyes`n"
        script:Write-Utf8NoBomFile -Path $packet.ResultPath -Content $body
        $r = script:Invoke-ReviewVerify -ProjectRoot $packet.ProjectRoot -ReviewTaskId $packet.ReviewTaskId -Pass $packet.Pass -RequireResult
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'verdict shape invalid'
        $r.Output | Should -Match 'multiple "## Verdict" headings'
    }

    It 'AC-VF-RR7: fails when verdict line is not in the allowed set' {
        $packet = script:Initialize-CanonicalPass -CaseName 'rr-maybe'
        script:Write-Utf8NoBomFile -Path $packet.ResultPath -Content "# Review Result`n`n## Verdict`n`nmaybe`n"
        $r = script:Invoke-ReviewVerify -ProjectRoot $packet.ProjectRoot -ReviewTaskId $packet.ReviewTaskId -Pass $packet.Pass -RequireResult
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'verdict shape invalid'
        $r.Output | Should -Match 'not one of yes / no / yes with risk'
    }

    It 'AC-VF-RR8: fails when verdict line is title-cased ("Yes")' {
        $packet = script:Initialize-CanonicalPass -CaseName 'rr-titlecase'
        script:Write-Utf8NoBomFile -Path $packet.ResultPath -Content "# Review Result`n`n## Verdict`n`nYes`n"
        $r = script:Invoke-ReviewVerify -ProjectRoot $packet.ProjectRoot -ReviewTaskId $packet.ReviewTaskId -Pass $packet.Pass -RequireResult
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'verdict shape invalid'
    }

    It 'AC-VF-RR9: fails on inline verdict form ("Verdict: yes")' {
        $packet = script:Initialize-CanonicalPass -CaseName 'rr-inline'
        script:Write-Utf8NoBomFile -Path $packet.ResultPath -Content "# Review Result`n`nVerdict: yes`n"
        $r = script:Invoke-ReviewVerify -ProjectRoot $packet.ProjectRoot -ReviewTaskId $packet.ReviewTaskId -Pass $packet.Pass -RequireResult
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'verdict shape invalid'
        $r.Output | Should -Match 'no "## Verdict" heading found'
    }

    It 'AC-VF-RR10: legacy sidecar artifacts present in pass dir do not change the verdict' {
        $packet = script:Initialize-CanonicalPass -CaseName 'rr-legacy-noise' -WithResult -Verdict 'yes'
        # Write legacy sidecars as on-disk noise. The contract says these are not part of the record.
        script:Write-Utf8NoBomFile -Path (Join-Path $packet.PassDir 'meta.json')         -Content '{"legacy":true}'
        script:Write-Utf8NoBomFile -Path (Join-Path $packet.PassDir 'result.json')       -Content '{"legacy":true}'
        script:Write-Utf8NoBomFile -Path (Join-Path $packet.PassDir 'target-files.list') -Content "x.txt`n"

        $r = script:Invoke-ReviewVerify -ProjectRoot $packet.ProjectRoot -ReviewTaskId $packet.ReviewTaskId -Pass $packet.Pass -RequireResult
        $r.ExitCode | Should -Be 0 -Because $r.Output
        $r.Output | Should -Match 'review-verify: PASS'
    }

    It 'AC-VF-RR11: passes and surfaces the disclosure-sections-present status line when all 4 required H2s are present (V2 baseline)' {
        $packet = script:Initialize-CanonicalPass -CaseName 'rr-ds-baseline' -WithResult -Verdict 'yes'
        $r = script:Invoke-ReviewVerify -ProjectRoot $packet.ProjectRoot -ReviewTaskId $packet.ReviewTaskId -Pass $packet.Pass -RequireResult
        $r.ExitCode | Should -Be 0 -Because $r.Output
        $r.Output | Should -Match 'disclosure sections present'
        $r.Output | Should -Match 'review-verify: PASS'
    }

    It 'AC-VF-RR12: fails when ## Blocking findings is missing (V2 regression)' {
        $packet = script:Initialize-CanonicalPass -CaseName 'rr-ds-no-blocking' -WithResult -Verdict 'yes'
        $body = (script:Build-ResultMd -Verdict 'yes') -replace "(?ms)^## Blocking findings\r?\n\r?\nnone\r?\n(\r?\n)?", ''
        script:Write-Utf8NoBomFile -Path $packet.ResultPath -Content $body
        $r = script:Invoke-ReviewVerify -ProjectRoot $packet.ProjectRoot -ReviewTaskId $packet.ReviewTaskId -Pass $packet.Pass -RequireResult
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'disclosure sections invalid'
        $r.Output | Should -Match 'missing required disclosure heading: ## Blocking findings'
    }

    It 'AC-VF-RR13: fails when ## Non-blocking concerns is missing (V2 regression)' {
        $packet = script:Initialize-CanonicalPass -CaseName 'rr-ds-no-nonblocking' -WithResult -Verdict 'yes'
        $body = (script:Build-ResultMd -Verdict 'yes') -replace "(?ms)^## Non-blocking concerns\r?\n\r?\nnone\r?\n(\r?\n)?", ''
        script:Write-Utf8NoBomFile -Path $packet.ResultPath -Content $body
        $r = script:Invoke-ReviewVerify -ProjectRoot $packet.ProjectRoot -ReviewTaskId $packet.ReviewTaskId -Pass $packet.Pass -RequireResult
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'missing required disclosure heading: ## Non-blocking concerns'
    }

    It 'AC-VF-RR14: fails when ## Review limitations is missing (V2 regression)' {
        $packet = script:Initialize-CanonicalPass -CaseName 'rr-ds-no-limitations' -WithResult -Verdict 'yes'
        $body = (script:Build-ResultMd -Verdict 'yes') -replace "(?ms)^## Review limitations\r?\n\r?\nnone\r?\n(\r?\n)?", ''
        script:Write-Utf8NoBomFile -Path $packet.ResultPath -Content $body
        $r = script:Invoke-ReviewVerify -ProjectRoot $packet.ProjectRoot -ReviewTaskId $packet.ReviewTaskId -Pass $packet.Pass -RequireResult
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'missing required disclosure heading: ## Review limitations'
    }

    It 'AC-VF-RR15: fails when ## Assumptions relied on is missing (V2 regression)' {
        $packet = script:Initialize-CanonicalPass -CaseName 'rr-ds-no-assumptions' -WithResult -Verdict 'yes'
        $body = (script:Build-ResultMd -Verdict 'yes') -replace "(?ms)^## Assumptions relied on\r?\n\r?\nnone\r?\n(\r?\n)?", ''
        script:Write-Utf8NoBomFile -Path $packet.ResultPath -Content $body
        $r = script:Invoke-ReviewVerify -ProjectRoot $packet.ProjectRoot -ReviewTaskId $packet.ReviewTaskId -Pass $packet.Pass -RequireResult
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'missing required disclosure heading: ## Assumptions relied on'
    }

    It 'AC-VF-RR16: fails when one of the 4 required H2s appears twice (V2 duplicate regression)' {
        $packet = script:Initialize-CanonicalPass -CaseName 'rr-ds-duplicate' -WithResult -Verdict 'yes'
        $body = (script:Build-ResultMd -Verdict 'yes') + "`n## Review limitations`n`nduplicate line.`n"
        script:Write-Utf8NoBomFile -Path $packet.ResultPath -Content $body
        $r = script:Invoke-ReviewVerify -ProjectRoot $packet.ProjectRoot -ReviewTaskId $packet.ReviewTaskId -Pass $packet.Pass -RequireResult
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'duplicate required disclosure heading: ## Review limitations'
    }

    It 'AC-VF-RR17: fails when a required disclosure H2 appears only in wrong case (V2 case-sensitivity regression)' {
        $packet = script:Initialize-CanonicalPass -CaseName 'rr-ds-wrongcase' -WithResult -Verdict 'yes'
        # Replace the exact-cased heading with a lowercase variant. The verifier must reject this as missing.
        $body = (script:Build-ResultMd -Verdict 'yes') -replace '(?m)^## Blocking findings$', '## blocking findings'
        script:Write-Utf8NoBomFile -Path $packet.ResultPath -Content $body
        $r = script:Invoke-ReviewVerify -ProjectRoot $packet.ProjectRoot -ReviewTaskId $packet.ReviewTaskId -Pass $packet.Pass -RequireResult
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'missing required disclosure heading: ## Blocking findings'
    }

    It 'AC-VF-RR18: fails when ## Verdict heading appears only in wrong case (verdict-heading case-sensitivity regression)' {
        $packet = script:Initialize-CanonicalPass -CaseName 'rr-verdict-wrongcase' -WithResult -Verdict 'yes'
        $body = (script:Build-ResultMd -Verdict 'yes') -replace '(?m)^## Verdict$', '## verdict'
        script:Write-Utf8NoBomFile -Path $packet.ResultPath -Content $body
        $r = script:Invoke-ReviewVerify -ProjectRoot $packet.ProjectRoot -ReviewTaskId $packet.ReviewTaskId -Pass $packet.Pass -RequireResult
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'no "## Verdict" heading found'
    }
}
