Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

BeforeAll {
    $script:RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).ProviderPath
    . (Join-Path $script:RepoRoot 'scripts/lib/native-process.ps1')
    $script:CheckScript = Join-Path $script:RepoRoot 'scripts/docs-working-model-check.ps1'

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

    function script:New-CaseRoot {
        param([string] $CaseName)
        $caseRoot = Join-Path $TestDrive ('pester-dwm-check-' + $CaseName)
        if (Test-Path -LiteralPath $caseRoot) {
            Remove-Item -LiteralPath $caseRoot -Recurse -Force
        }
        $null = New-Item -ItemType Directory -Path $caseRoot -Force
        # A minimal docs/ + rules/ skeleton with non-referencing READMEs so the
        # default case is a clean PASS; individual cases add the violating shape.
        script:Write-Utf8NoBomFile -Path (Join-Path $caseRoot 'docs/README.md') -Content "# docs orientation`n`nplacement + routing map.`n"
        script:Write-Utf8NoBomFile -Path (Join-Path $caseRoot 'rules/README.md') -Content "# rules index`n`nthe _incubation role is a committed-temporary candidate lifecycle role.`n"
        return ([System.IO.Path]::GetFullPath($caseRoot))
    }

    function script:Invoke-Check {
        param([string] $ProjectRoot)
        $procArgs = @(
            '-NoProfile',
            '-ExecutionPolicy', 'Bypass',
            '-File', $script:CheckScript,
            '-ProjectRoot', $ProjectRoot
        )
        $proc = Invoke-NativeProcess -Executable 'powershell.exe' -Arguments $procArgs
        $text = (($proc.Stdout + $proc.Stderr) -replace "`r`n", "`n").TrimEnd("`n")
        return [pscustomobject]@{
            ExitCode = $proc.ExitCode
            Output   = $text
        }
    }
}

Describe 'docs-working-model-check happy path' {
    It 'AC-DWM-PASS-NONE-1: no incubation docs at all exits 0' {
        $project = script:New-CaseRoot -CaseName 'pass-none'
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'docs/review/review_spec.md') -Content "# review spec`n"

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 0 -Because $result.Output
        $result.Output | Should -Match 'docs-working-model-check: PASS'
    }

    It 'AC-DWM-PASS-INCUBATION-1: valid incubation folder (only _incubation.md, no canonical ref) exits 0' {
        $project = script:New-CaseRoot -CaseName 'pass-incubation'
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'docs/scopeguard/scopeguard_incubation.md') -Content "# scopeguard incubation`n`nnon-authoritative; owner: x; review-date: 2026-07-01.`n"

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 0 -Because $result.Output
        $result.Output | Should -Match 'docs-working-model-check: PASS'
        $result.Output | Should -Match 'found 1 incubation candidate folder'
    }
}

Describe 'docs-working-model-check E3 sibling' {
    It 'AC-DWM-E3-1: a _spec.md sibling next to an _incubation.md fails' {
        $project = script:New-CaseRoot -CaseName 'e3-spec'
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'docs/scopeguard/scopeguard_incubation.md') -Content "# scopeguard incubation`n"
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'docs/scopeguard/scopeguard_spec.md') -Content "# premature spec`n"

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 1 -Because $result.Output
        $result.Output | Should -Match 'E3 FAIL'
        $result.Output | Should -Match 'scopeguard_spec.md'
    }

    It 'AC-DWM-E3-2: a _design.md sibling next to an _incubation.md fails' {
        $project = script:New-CaseRoot -CaseName 'e3-design'
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'docs/scopeguard/scopeguard_incubation.md') -Content "# scopeguard incubation`n"
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'docs/scopeguard/scopeguard_design.md') -Content "# premature design`n"

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 1 -Because $result.Output
        $result.Output | Should -Match 'E3 FAIL'
        $result.Output | Should -Match 'scopeguard_design.md'
    }

    It 'AC-DWM-E3-3: a _plan.md sibling next to an _incubation.md fails' {
        $project = script:New-CaseRoot -CaseName 'e3-plan'
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'docs/scopeguard/scopeguard_incubation.md') -Content "# scopeguard incubation`n"
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'docs/scopeguard/scopeguard_plan.md') -Content "# premature plan`n"

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 1 -Because $result.Output
        $result.Output | Should -Match 'E3 FAIL'
        $result.Output | Should -Match 'scopeguard_plan.md'
    }
}

Describe 'docs-working-model-check E2 canonical reference' {
    It 'AC-DWM-E2-1: a rules file linking an _incubation.md fails' {
        $project = script:New-CaseRoot -CaseName 'e2-rules-link'
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'docs/scopeguard/scopeguard_incubation.md') -Content "# scopeguard incubation`n"
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'rules/some-rule/some-rule.md') -Content "# some rule`n`nSee [the candidate](../../docs/scopeguard/scopeguard_incubation.md) for detail.`n"

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 1 -Because $result.Output
        $result.Output | Should -Match 'E2 FAIL'
        $result.Output | Should -Match 'scopeguard_incubation.md'
    }

    It 'AC-DWM-E2-2: a bare "_incubation" rule-concept token is NOT a violation' {
        $project = script:New-CaseRoot -CaseName 'e2-bare-token'
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'docs/scopeguard/scopeguard_incubation.md') -Content "# scopeguard incubation`n"
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'rules/docs-working-model/docs-working-model.md') -Content "# rule`n`nThe _incubation document is a class-2 lifecycle role.`n"

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 0 -Because $result.Output
        $result.Output | Should -Match 'docs-working-model-check: PASS'
        $result.Output | Should -Not -Match 'E2 FAIL'
    }

    It 'AC-DWM-E2-3: a *_incubation.md path with no matching discovered candidate is NOT a violation' {
        $project = script:New-CaseRoot -CaseName 'e2-dangling-ref'
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'docs/scopeguard/scopeguard_incubation.md') -Content "# scopeguard incubation`n"
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'rules/some-rule/some-rule.md') -Content "# some rule`n`nHistorical note: ../../old/ghost_incubation.md (no such candidate exists).`n"

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 0 -Because $result.Output
        $result.Output | Should -Match 'docs-working-model-check: PASS'
        $result.Output | Should -Not -Match 'E2 FAIL'
    }

    It 'AC-DWM-E2-4: same leaf filename in a different folder than the discovered candidate is NOT a violation' {
        $project = script:New-CaseRoot -CaseName 'e2-same-leaf-other-folder'
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'docs/scopeguard/scopeguard_incubation.md') -Content "# scopeguard incubation`n"
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'rules/some-rule/some-rule.md') -Content "# some rule`n`nHistorical: ../../old/scopeguard_incubation.md (different folder, not the real candidate).`n"

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 0 -Because $result.Output
        $result.Output | Should -Match 'docs-working-model-check: PASS'
        $result.Output | Should -Not -Match 'E2 FAIL'
    }
}

Describe 'docs-working-model-check E1 discovery target' {
    It 'AC-DWM-E1-1: docs/README linking an incubation-only folder as a domain fails' {
        $project = script:New-CaseRoot -CaseName 'e1-docs-readme'
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'docs/scopeguard/scopeguard_incubation.md') -Content "# scopeguard incubation`n"
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'docs/README.md') -Content "# docs orientation`n`nDomains: [scopeguard](scopeguard/) is a domain home.`n"

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 1 -Because $result.Output
        $result.Output | Should -Match 'E1 FAIL'
        $result.Output | Should -Match 'scopeguard'
    }

    It 'AC-DWM-E1-2: thin name/owner/review-date metadata mention (no path/link) does NOT fail' {
        $project = script:New-CaseRoot -CaseName 'e1-metadata-ok'
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'docs/scopeguard/scopeguard_incubation.md') -Content "# scopeguard incubation`n"
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'docs/README.md') -Content "# docs orientation`n`nCandidate tracking: scopeguard (owner: x, review-date: 2026-07-01).`n"

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 0 -Because $result.Output
        $result.Output | Should -Match 'docs-working-model-check: PASS'
        $result.Output | Should -Not -Match 'E1 FAIL'
    }

    It 'AC-DWM-E1-3: a promoted folder (has _spec.md) linked from README is NOT an E1 violation' {
        $project = script:New-CaseRoot -CaseName 'e1-promoted-ok'
        # Promoted: folder still has an _incubation.md being absorbed but already carries a canonical _spec.md.
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'docs/scopeguard/scopeguard_incubation.md') -Content "# being absorbed`n"
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'docs/scopeguard/scopeguard_spec.md') -Content "# scopeguard spec`n"
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'docs/README.md') -Content "# docs orientation`n`nDomains: [scopeguard](scopeguard/) is a domain home.`n"

        $result = script:Invoke-Check -ProjectRoot $project
        # Note: E3 will still fire here because _spec.md sits next to _incubation.md,
        # but E1 must not, since HasSpec excludes it from E1. Assert E1 absence directly.
        $result.Output | Should -Not -Match 'E1 FAIL'
    }

    It 'AC-DWM-E1-4: a non-docs path ending in <name>/ (e.g. archive/<name>/) is NOT an E1 violation' {
        $project = script:New-CaseRoot -CaseName 'e1-nondocs-path'
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'docs/scopeguard/scopeguard_incubation.md') -Content "# scopeguard incubation`n"
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'docs/README.md') -Content "# docs orientation`n`nSee archive/scopeguard/ and notes/scopeguard/ for old material.`n"

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 0 -Because $result.Output
        $result.Output | Should -Match 'docs-working-model-check: PASS'
        $result.Output | Should -Not -Match 'E1 FAIL'
    }

    It 'AC-DWM-E1-5: a slash-less directory link [x](scopeguard) in docs/README fails' {
        $project = script:New-CaseRoot -CaseName 'e1-slashless-docs'
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'docs/scopeguard/scopeguard_incubation.md') -Content "# scopeguard incubation`n"
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'docs/README.md') -Content "# docs orientation`n`nDomains: [scopeguard](scopeguard) is a domain home.`n"

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 1 -Because $result.Output
        $result.Output | Should -Match 'E1 FAIL'
    }

    It 'AC-DWM-E1-6: a slash-less docs-rooted link [x](../docs/scopeguard) in rules/README fails' {
        $project = script:New-CaseRoot -CaseName 'e1-slashless-rules'
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'docs/scopeguard/scopeguard_incubation.md') -Content "# scopeguard incubation`n"
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'rules/README.md') -Content "# rules index`n`nSee [scopeguard](../docs/scopeguard) candidate.`n"

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 1 -Because $result.Output
        $result.Output | Should -Match 'E1 FAIL'
    }
}

Describe 'docs-working-model-check advisories' {
    It 'AC-DWM-ADVISORY-1: E4 and E5 advisory lines are always emitted' {
        $project = script:New-CaseRoot -CaseName 'advisory'
        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 0 -Because $result.Output
        $result.Output | Should -Match 'E4 INFO'
        $result.Output | Should -Match 'E5 INFO'
    }

    It 'AC-DWM-SCOPE-1: a SCOPE INFO line discloses the scanned subset and PASS is qualified' {
        $project = script:New-CaseRoot -CaseName 'scope-info'
        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 0 -Because $result.Output
        $result.Output | Should -Match 'SCOPE INFO: MECHANICAL subset only'
        $result.Output | Should -Match 'all \.md under rules/'
        $result.Output | Should -Match 'package-local templates/ or checklists/ under a rule ARE included'
        $result.Output | Should -Match 'NOT mechanically scanned'
        $result.Output | Should -Match 'PASS \(no E1/E2/E3 violations in the mechanically-scanned subset\)'
    }

    It 'AC-DWM-ADVISORY-2: E4/E5 advisories do not change a failing exit code' {
        $project = script:New-CaseRoot -CaseName 'advisory-fail'
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'docs/scopeguard/scopeguard_incubation.md') -Content "# scopeguard incubation`n"
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'docs/scopeguard/scopeguard_spec.md') -Content "# premature spec`n"

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 1 -Because $result.Output
        $result.Output | Should -Match 'E4 INFO'
        $result.Output | Should -Match 'E5 INFO'
    }
}
