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
        # A promoted domain spec must (EN-2) carry a Lifecycle state section with exactly one
        # bolded lifecycle marker; the plain-prose "sync-required" mention must NOT count.
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'docs/review/review_spec.md') -Content "# review spec`n`n## Lifecycle state`n`n- spec to implementation: **live** - synced 1:1; later changes follow the sync-required transition.`n"

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
        $result.Output | Should -Match 'all \.md under snippets/rules/'
        $result.Output | Should -Match 'snippets/rules/ IS now mechanically scanned for E2'
        $result.Output | Should -Match 'NOT mechanically scanned'
        $result.Output | Should -Match 'PASS \(no E1/E2/E3/EN-2/DOCS-PURITY/BACKLOG-NEXTID/TERM-RESERVE/rule_docs-purity/orphan/file violations in the mechanically-scanned subset\)'
        $result.Output | Should -Match 'DOCS-PURITY = every PROMOTED docs domain'
        $result.Output | Should -Match 'BACKLOG-NEXTID = every domain backlog'
        $result.Output | Should -Match 'TERM-RESERVE = the transition-aware terminology-registration check'
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

Describe 'docs-working-model-check rule_docs (rule candidates)' {
    It 'AC-DWM-RULE-PASS-1: a rule_docs/<candidate>/ with only _incubation.md exits 0' {
        $project = script:New-CaseRoot -CaseName 'rule-pass'
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'rule_docs/swo/swo_incubation.md') -Content "# swo incubation`n`nnon-authoritative; owner: x; review-date: 2026-07-01.`n"

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 0 -Because $result.Output
        $result.Output | Should -Match 'docs-working-model-check: PASS'
        $result.Output | Should -Match 'found 1 incubation candidate folder'
    }

    It 'AC-DWM-RULE-E3-1: a _spec.md sibling in a rule_docs candidate fails, message names rule_docs/' {
        $project = script:New-CaseRoot -CaseName 'rule-e3-spec'
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'rule_docs/swo/swo_incubation.md') -Content "# swo incubation`n"
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'rule_docs/swo/swo_spec.md') -Content "# premature spec`n"

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 1 -Because $result.Output
        $result.Output | Should -Match 'E3 FAIL'
        $result.Output | Should -Match 'rule_docs/swo/'
    }

    It 'AC-DWM-RULE-E2-1: a rules file durably linking a rule_docs _incubation.md fails' {
        $project = script:New-CaseRoot -CaseName 'rule-e2-link'
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'rule_docs/swo/swo_incubation.md') -Content "# swo incubation`n"
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'rules/some-rule/some-rule.md') -Content "# some rule`n`nSee [the candidate](../../rule_docs/swo/swo_incubation.md) for detail.`n"

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 1 -Because $result.Output
        $result.Output | Should -Match 'E2 FAIL'
        $result.Output | Should -Match 'swo_incubation.md'
    }

    It 'AC-DWM-RULE-E1-1: rules/README linking a rule_docs candidate folder as a discovery target fails' {
        $project = script:New-CaseRoot -CaseName 'rule-e1-readme'
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'rule_docs/swo/swo_incubation.md') -Content "# swo incubation`n"
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'rules/README.md') -Content "# rules index`n`nSee [swo](../rule_docs/swo/) candidate.`n"

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 1 -Because $result.Output
        $result.Output | Should -Match 'E1 FAIL'
        $result.Output | Should -Match 'rule_docs/swo/'
    }

    It 'AC-DWM-RULE-E1-2: a slash-less docs-relative link [x](swo) does NOT fire for a rule candidate' {
        $project = script:New-CaseRoot -CaseName 'rule-e1-noslash-docsrel'
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'rule_docs/swo/swo_incubation.md') -Content "# swo incubation`n"
        # The docs-relative-link slash-less form is docs-candidates-only; it must NOT match a
        # rule candidate whose home is rule_docs/, not docs/.
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'docs/README.md') -Content "# docs orientation`n`nUnrelated: [swo](swo) is not a docs domain here.`n"

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 0 -Because $result.Output
        $result.Output | Should -Match 'docs-working-model-check: PASS'
        $result.Output | Should -Not -Match 'E1 FAIL'
    }

    It 'AC-DWM-RULE-MIX-1: a docs candidate and a rule candidate together are both discovered and pass clean' {
        $project = script:New-CaseRoot -CaseName 'rule-mix'
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'docs/scopeguard/scopeguard_incubation.md') -Content "# scopeguard incubation`n"
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'rule_docs/swo/swo_incubation.md') -Content "# swo incubation`n"

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 0 -Because $result.Output
        $result.Output | Should -Match 'found 2 incubation candidate folder'
        $result.Output | Should -Match 'docs-working-model-check: PASS'
    }
}

Describe 'docs-working-model-check rule_docs structure (3-state model)' {
    It 'AC-DWM-PURITY-1: a loose file directly under rule_docs/ fails' {
        $project = script:New-CaseRoot -CaseName 'purity-loose-file'
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'rule_docs/swo/swo_incubation.md') -Content "# swo incubation`n"
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'rule_docs/notes.md') -Content "# stray top-level file`n"

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 1 -Because $result.Output
        $result.Output | Should -Match 'RULE_DOCS-PURITY FAIL'
        $result.Output | Should -Match 'loose file directly under rule_docs/'
        $result.Output | Should -Match 'notes\.md'
    }

    It 'AC-DWM-PURITY-2: a rule_docs child folder with only a stray non-candidate file fails (disallowed file + no valid state)' {
        $project = script:New-CaseRoot -CaseName 'purity-noncandidate-folder'
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'rule_docs/random/draft.md') -Content "# not a candidate`n"

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 1 -Because $result.Output
        # draft.md is not .gitkeep nor random_{incubation,design,plan,work_packet}.md -> disallowed file.
        $result.Output | Should -Match 'RULE_DOCS-FILE FAIL'
        $result.Output | Should -Match 'draft\.md'
        # And the folder is in no valid state (no .gitkeep, no recognized state file).
        $result.Output | Should -Match 'RULE_DOCS-PURITY FAIL: rule_docs/random/ is in no valid state'
    }

    It 'AC-DWM-PURITY-3: a folder whose _incubation.md id mismatches the folder is a disallowed file' {
        $project = script:New-CaseRoot -CaseName 'purity-name-mismatch'
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'rule_docs/mismatchdir/other_incubation.md') -Content "# mismatched name`n"

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 1 -Because $result.Output
        # other_incubation.md != mismatchdir_incubation.md -> disallowed (id must match folder).
        $result.Output | Should -Match 'RULE_DOCS-FILE FAIL'
        $result.Output | Should -Match 'mismatchdir'
        $result.Output | Should -Match 'other_incubation\.md'
    }

    It 'AC-DWM-STATE-INCUBATION-1: candidate incubation (only <id>_incubation.md) passes, no rule output needed' {
        $project = script:New-CaseRoot -CaseName 'state-incubation'
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'rule_docs/swo/swo_incubation.md') -Content "# swo incubation`n"

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 0 -Because $result.Output
        $result.Output | Should -Match 'docs-working-model-check: PASS'
        $result.Output | Should -Not -Match 'RULE_DOCS-.*FAIL'
    }

    It 'AC-DWM-STATE-ACTIVE-1: active lifecycle work (_design/_plan/_work_packet, no _incubation) passes for an existing rule' {
        $project = script:New-CaseRoot -CaseName 'state-active'
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'rules/swo/swo.md') -Content "# swo rule`n"
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'rule_docs/swo/swo_design.md') -Content "# swo design`n"
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'rule_docs/swo/swo_plan.md') -Content "# swo plan`n"
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'rule_docs/swo/swo_work_packet.md') -Content "# swo work packet`n"

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 0 -Because $result.Output
        $result.Output | Should -Match 'docs-working-model-check: PASS'
        $result.Output | Should -Not -Match 'RULE_DOCS-.*FAIL'
        # A _design/_plan folder with NO _incubation.md is not an incubation folder, so E3 must not fire.
        $result.Output | Should -Not -Match 'E3 FAIL'
    }

    It 'AC-DWM-STATE-INCUBATION-2: candidate incubation may also carry a round-scoped work packet — passes, no rule output needed (_incubation.md present means candidate incubation)' {
        $project = script:New-CaseRoot -CaseName 'state-incubation-workpacket'
        # _incubation.md present => candidate incubation (the rule's state discriminator); a round-scoped
        # work packet is allowed during incubation, and a candidate needs no rule output yet (no rules/swo/swo.md).
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'rule_docs/swo/swo_incubation.md') -Content "# swo incubation`n"
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'rule_docs/swo/swo_work_packet.md') -Content "# swo work packet`n"

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 0 -Because $result.Output
        $result.Output | Should -Match 'docs-working-model-check: PASS'
        $result.Output | Should -Not -Match 'RULE_DOCS-.*FAIL'
    }

    It 'AC-DWM-STATE-IDLE-1: idle (.gitkeep only) with a matching rules/<id>/<id>.md output passes' {
        $project = script:New-CaseRoot -CaseName 'state-idle-nested'
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'rules/swo/swo.md') -Content "# swo rule`n"
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'rule_docs/swo/.gitkeep') -Content ''

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 0 -Because $result.Output
        $result.Output | Should -Match 'docs-working-model-check: PASS'
        $result.Output | Should -Not -Match 'RULE_DOCS-.*FAIL'
    }

    It 'AC-DWM-STATE-IDLE-2: idle (.gitkeep only) backed by snippets/rules/<id>.md output passes' {
        $project = script:New-CaseRoot -CaseName 'state-idle-snippet'
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'snippets/rules/swo.md') -Content "# swo distributed rule`n"
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'rule_docs/swo/.gitkeep') -Content ''

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 0 -Because $result.Output
        $result.Output | Should -Match 'docs-working-model-check: PASS'
        $result.Output | Should -Not -Match 'RULE_DOCS-.*FAIL'
    }

    It 'AC-DWM-ORPHAN-1: idle (.gitkeep only) with NO corresponding rule output is an ORPHAN violation' {
        $project = script:New-CaseRoot -CaseName 'orphan-idle'
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'rule_docs/swo/.gitkeep') -Content ''

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 1 -Because $result.Output
        $result.Output | Should -Match 'RULE_DOCS-ORPHAN FAIL'
        $result.Output | Should -Match 'swo'
        $result.Output | Should -Match 'has no corresponding rule output'
    }

    It 'AC-DWM-FILE-1: a disallowed file (README.md) alongside a valid state file fails RULE_DOCS-FILE' {
        $project = script:New-CaseRoot -CaseName 'file-readme'
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'rule_docs/swo/swo_incubation.md') -Content "# swo incubation`n"
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'rule_docs/swo/README.md') -Content "# stray readme`n"

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 1 -Because $result.Output
        $result.Output | Should -Match 'RULE_DOCS-FILE FAIL'
        $result.Output | Should -Match 'README\.md'
    }

    It 'AC-DWM-FILE-2: a disallowed subfolder under a per-rule folder fails RULE_DOCS-FILE' {
        $project = script:New-CaseRoot -CaseName 'file-subfolder'
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'rule_docs/swo/swo_incubation.md') -Content "# swo incubation`n"
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'rule_docs/swo/archive/old.md') -Content "# archived`n"

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 1 -Because $result.Output
        $result.Output | Should -Match 'RULE_DOCS-FILE FAIL'
        $result.Output | Should -Match 'disallowed subfolder'
        $result.Output | Should -Match 'archive'
    }

    It 'AC-DWM-FILE-3: a non-.md allowed-base name still fails (only .md role files + .gitkeep allowed)' {
        $project = script:New-CaseRoot -CaseName 'file-nonmd'
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'rule_docs/swo/swo_incubation.md') -Content "# swo incubation`n"
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'rule_docs/swo/swo_incubation.txt') -Content "stray txt"

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 1 -Because $result.Output
        $result.Output | Should -Match 'RULE_DOCS-FILE FAIL'
        $result.Output | Should -Match 'swo_incubation\.txt'
    }

    It 'AC-DWM-PURITY-4: a well-formed rule_docs/<x>/<x>_incubation.md has no rule_docs violation' {
        $project = script:New-CaseRoot -CaseName 'purity-clean'
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'rule_docs/swo/swo_incubation.md') -Content "# swo incubation`n"

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 0 -Because $result.Output
        $result.Output | Should -Match 'docs-working-model-check: PASS'
        $result.Output | Should -Not -Match 'RULE_DOCS-.*FAIL'
    }
}

Describe 'docs-working-model-check EN-1 snippets/rules E2 scope' {
    It 'AC-DWM-EN1-1: a snippets/rules file durably linking a candidate _incubation.md fails E2' {
        $project = script:New-CaseRoot -CaseName 'en1-snippets-link'
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'docs/scopeguard/scopeguard_incubation.md') -Content "# scopeguard incubation`n"
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'snippets/rules/some-dist-rule.md') -Content "# some distributed rule`n`nSee [the candidate](../../docs/scopeguard/scopeguard_incubation.md) for detail.`n"

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 1 -Because $result.Output
        $result.Output | Should -Match 'E2 FAIL'
        $result.Output | Should -Match 'scopeguard_incubation.md'
    }

    It 'AC-DWM-EN1-2: a clean snippets/rules file with no candidate ref passes' {
        $project = script:New-CaseRoot -CaseName 'en1-snippets-clean'
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'docs/scopeguard/scopeguard_incubation.md') -Content "# scopeguard incubation`n"
        # A bare "_incubation" concept token (no concrete path) is not a durable reference.
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'snippets/rules/some-dist-rule.md') -Content "# some distributed rule`n`nThe _incubation document is a class-2 lifecycle role.`n"

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 0 -Because $result.Output
        $result.Output | Should -Match 'docs-working-model-check: PASS'
        $result.Output | Should -Not -Match 'E2 FAIL'
    }
}

Describe 'docs-working-model-check EN-2 promoted domain Spec lifecycle marker' {
    It 'AC-DWM-EN2-PASS-1: a domain _spec.md with exactly one bolded **live** marker (plain "sync-required" prose present) passes' {
        $project = script:New-CaseRoot -CaseName 'en2-live-ok'
        # The bolded **live** is the sole marker; the plain-prose "sync-required" mention must NOT be counted.
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'docs/widget/widget_spec.md') -Content "# widget spec`n`n## 목표 상태`n`nwidget is a thing.`n`n## Lifecycle state`n`n- lifecycle docs: none.`n- spec to implementation: **live** - synced 1:1; later changes follow the sync-required transition.`n"

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 0 -Because $result.Output
        $result.Output | Should -Match 'docs-working-model-check: PASS'
        $result.Output | Should -Not -Match 'EN-2 FAIL'
    }

    It 'AC-DWM-EN2-PASS-PRELIVE-1: a promoted domain _spec.md whose sole bolded marker is **prelive** passes' {
        $project = script:New-CaseRoot -CaseName 'en2-prelive-ok'
        # A newly-promoted domain Spec carries **prelive** (written, not yet made live by closeout).
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'docs/widget/widget_spec.md') -Content "# widget spec`n`n## 목표 상태`n`nwidget is a thing.`n`n## Lifecycle state`n`n- lifecycle docs: _design + _plan present (promoted, not yet closed out).`n- spec to implementation: **prelive** - written, not yet made live by closeout.`n"

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 0 -Because $result.Output
        $result.Output | Should -Match 'docs-working-model-check: PASS'
        $result.Output | Should -Not -Match 'EN-2 FAIL'
    }

    It 'AC-DWM-EN2-PASS-SYNCREQ-1: a promoted domain _spec.md whose sole bolded marker is **sync-required** passes' {
        $project = script:New-CaseRoot -CaseName 'en2-syncreq-ok'
        # A previously-live Spec updated in place is **sync-required** (awaiting re-sync).
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'docs/widget/widget_spec.md') -Content "# widget spec`n`n## 목표 상태`n`nwidget is a thing.`n`n## Lifecycle state`n`n- lifecycle docs: none.`n- spec to implementation: **sync-required** - live Spec updated in place, awaiting re-sync.`n"

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 0 -Because $result.Output
        $result.Output | Should -Match 'docs-working-model-check: PASS'
        $result.Output | Should -Not -Match 'EN-2 FAIL'
    }

    It 'AC-DWM-EN2-MISSING-1: a domain _spec.md with no Lifecycle state section fails' {
        $project = script:New-CaseRoot -CaseName 'en2-missing'
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'docs/widget/widget_spec.md') -Content "# widget spec`n`n## 목표 상태`n`nwidget is a thing.`n"

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 1 -Because $result.Output
        $result.Output | Should -Match 'EN-2 FAIL'
        $result.Output | Should -Match 'no "## Lifecycle state" section'
    }

    It 'AC-DWM-EN2-ZERO-1: a Lifecycle state section with no bolded marker (only plain prose) fails' {
        $project = script:New-CaseRoot -CaseName 'en2-zero'
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'docs/widget/widget_spec.md') -Content "# widget spec`n`n## Lifecycle state`n`n- spec to implementation: live (plain, not bolded); sync-required later.`n"

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 1 -Because $result.Output
        $result.Output | Should -Match 'EN-2 FAIL'
        $result.Output | Should -Match 'found 0'
    }

    It 'AC-DWM-EN2-TWO-1: a Lifecycle state section with two bolded markers fails' {
        $project = script:New-CaseRoot -CaseName 'en2-two'
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'docs/widget/widget_spec.md') -Content "# widget spec`n`n## Lifecycle state`n`n- spec to implementation: **live**`n- also somehow: **sync-required**`n"

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 1 -Because $result.Output
        $result.Output | Should -Match 'EN-2 FAIL'
        $result.Output | Should -Match 'found 2'
    }

    It 'AC-DWM-EN2-INVALID-1: a bolded token that is not one of the three valid markers fails (counts as zero valid markers)' {
        $project = script:New-CaseRoot -CaseName 'en2-invalid'
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'docs/widget/widget_spec.md') -Content "# widget spec`n`n## Lifecycle state`n`n- spec to implementation: **archived**`n"

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 1 -Because $result.Output
        $result.Output | Should -Match 'EN-2 FAIL'
        $result.Output | Should -Match 'found 0'
    }

    It 'AC-DWM-EN2-CANDIDATE-1: a candidate folder with only _incubation.md (no _spec.md) does not fire EN-2' {
        $project = script:New-CaseRoot -CaseName 'en2-candidate'
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'docs/scopeguard/scopeguard_incubation.md') -Content "# scopeguard incubation`n"

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 0 -Because $result.Output
        $result.Output | Should -Match 'docs-working-model-check: PASS'
        $result.Output | Should -Not -Match 'EN-2 FAIL'
    }

    It 'AC-DWM-EN2-FENCE-1: a **live** marker that appears ONLY inside a fenced code block is not counted (EN-2 FAIL, found 0)' {
        $project = script:New-CaseRoot -CaseName 'en2-fence-only'
        # The only **live** lives inside a ```-fenced example; the section has no real bolded marker,
        # so the fenced marker must NOT be counted -> found 0.
        $content = "# widget spec`n`n## Lifecycle state`n`n- lifecycle docs: none.`n`n" + '```text' + "`nexample marker: **live**`n" + '```' + "`n"
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'docs/widget/widget_spec.md') -Content $content

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 1 -Because $result.Output
        $result.Output | Should -Match 'EN-2 FAIL'
        $result.Output | Should -Match 'found 0'
    }

    It 'AC-DWM-EN2-FENCE-2: a real bolded marker plus a fenced example marker counts only the real one (PASS)' {
        $project = script:New-CaseRoot -CaseName 'en2-fence-plus-real'
        # One real **live** marker line, and a fenced code example that also shows **sync-required**;
        # only the real (non-fenced) marker is counted -> exactly one -> PASS.
        $content = "# widget spec`n`n## Lifecycle state`n`n- spec to implementation: **live** - synced 1:1.`n`n" + '```text' + "`nexample of another state: **sync-required**`n" + '```' + "`n"
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'docs/widget/widget_spec.md') -Content $content

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 0 -Because $result.Output
        $result.Output | Should -Match 'docs-working-model-check: PASS'
        $result.Output | Should -Not -Match 'EN-2 FAIL'
    }

    It 'AC-DWM-EN2-FENCE-3: a fenced example block containing a different fence delimiter inside it does not break the fence; the real **live** marker after it counts (PASS)' {
        $project = script:New-CaseRoot -CaseName 'en2-fence-inner-delim'
        # A ```-fenced example block contains ~~~ delimiter lines (a DIFFERENT delimiter char)
        # plus bolded markers inside it. The inner ~~~ lines must NOT close the backtick fence,
        # so the fenced **sync-required**/**prelive** are not counted; only the real **live**
        # marker after the fence closes is counted -> exactly one -> PASS. (Under the old
        # toggle-on-any-fence logic the first inner ~~~ would wrongly close the fence and the
        # fenced markers would leak out -> found 2 -> FAIL; this case locks the new behavior.)
        $content = "# widget spec`n`n## Lifecycle state`n`n" + '```text' + "`n~~~`nfenced: **sync-required**`n~~~`nalso fenced: **prelive**`n" + '```' + "`n`n- spec to implementation: **live** - synced 1:1.`n"
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'docs/widget/widget_spec.md') -Content $content

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 0 -Because $result.Output
        $result.Output | Should -Match 'docs-working-model-check: PASS'
        $result.Output | Should -Not -Match 'EN-2 FAIL'
    }

    It 'AC-DWM-EN2-DUP-1: two "## Lifecycle state" sections fail (ambiguous lifecycle state)' {
        $project = script:New-CaseRoot -CaseName 'en2-duplicate-section'
        # Two Lifecycle state sections, each with one marker; the duplicate itself is the violation.
        $content = "# widget spec`n`n## Lifecycle state`n`n- spec to implementation: **live**`n`n## Lifecycle state`n`n- spec to implementation: **sync-required**`n"
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'docs/widget/widget_spec.md') -Content $content

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 1 -Because $result.Output
        $result.Output | Should -Match 'EN-2 FAIL'
        $result.Output | Should -Match 'more than one "## Lifecycle state" section'
    }
}

Describe 'docs-working-model-check FN-2 EN-2 fence length regression' {
    It 'AC-DWM-EN2-FENCE-4: a 3-tilde line does NOT close a 4-tilde fence (inner markers stay fenced -> PASS)' {
        $project = script:New-CaseRoot -CaseName 'en2-fence-tilde-len'
        # Opener ~~~~ (4 tildes); a later ~~~ (3 tildes) must NOT close it, so the two
        # fenced markers stay inside the fence and only the real **live** counts -> PASS.
        # If length-tracking broke (any same-char fence closes), **prelive** would leak -> found 2 -> FAIL.
        $content = "# widget spec`n`n## Lifecycle state`n`n- spec to implementation: **live** - synced 1:1.`n`n~~~~`nfenced: **sync-required**`n~~~`nstill fenced: **prelive**`n~~~~`n"
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'docs/widget/widget_spec.md') -Content $content

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 0 -Because $result.Output
        $result.Output | Should -Match 'docs-working-model-check: PASS'
        $result.Output | Should -Not -Match 'EN-2 FAIL'
    }

    It 'AC-DWM-EN2-FENCE-5: a 3-backtick line does NOT close a 4-backtick fence (inner markers stay fenced -> PASS)' {
        $project = script:New-CaseRoot -CaseName 'en2-fence-backtick-len'
        $content = "# widget spec`n`n## Lifecycle state`n`n- spec to implementation: **live** - ok.`n`n" + '````' + "`nfenced: **sync-required**`n" + '```' + "`nstill fenced: **prelive**`n" + '````' + "`n"
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'docs/widget/widget_spec.md') -Content $content

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 0 -Because $result.Output
        $result.Output | Should -Match 'docs-working-model-check: PASS'
        $result.Output | Should -Not -Match 'EN-2 FAIL'
    }
}

Describe 'docs-working-model-check FN-1 E2 angle-bracket / drive-letter refs' {
    It 'AC-DWM-FN1-1: an angle-bracket markdown link to a real candidate _incubation.md fails E2' {
        $project = script:New-CaseRoot -CaseName 'fn1-angle-link'
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'docs/scopeguard/scopeguard_incubation.md') -Content "# scopeguard incubation`n"
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'rules/some-rule/some-rule.md') -Content "# some rule`n`nSee [the candidate](<../../docs/scopeguard/scopeguard_incubation.md>) for detail.`n"

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 1 -Because $result.Output
        $result.Output | Should -Match 'E2 FAIL'
        $result.Output | Should -Match 'angle-bracket link'
        $result.Output | Should -Match 'scopeguard_incubation.md'
    }

    It 'AC-DWM-FN1-2: a drive-letter absolute path to a real candidate fails E2' {
        $project = script:New-CaseRoot -CaseName 'fn1-drive-letter'
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'docs/scopeguard/scopeguard_incubation.md') -Content "# scopeguard incubation`n"
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'rules/some-rule/some-rule.md') -Content "# some rule`n`nAbsolute: C:/work/repo/docs/scopeguard/scopeguard_incubation.md is durable.`n"

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 1 -Because $result.Output
        $result.Output | Should -Match 'E2 FAIL'
        $result.Output | Should -Match 'scopeguard_incubation.md'
    }

    It 'AC-DWM-FN1-3: an angle-bracket link to a same-leaf file in a DIFFERENT folder is NOT a violation' {
        $project = script:New-CaseRoot -CaseName 'fn1-angle-other-folder'
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'docs/scopeguard/scopeguard_incubation.md') -Content "# scopeguard incubation`n"
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'rules/some-rule/some-rule.md') -Content "# some rule`n`nHistorical: [old](<../../old/scopeguard_incubation.md>) (different folder).`n"

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 0 -Because $result.Output
        $result.Output | Should -Match 'docs-working-model-check: PASS'
        $result.Output | Should -Not -Match 'E2 FAIL'
    }

    It 'AC-DWM-FN1-4: an angle-bracket link to a bare leaf (no folder) is NOT a violation (base-tail)' {
        $project = script:New-CaseRoot -CaseName 'fn1-angle-bare-leaf'
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'docs/scopeguard/scopeguard_incubation.md') -Content "# scopeguard incubation`n"
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'rules/some-rule/some-rule.md') -Content "# some rule`n`nBare: [x](<scopeguard_incubation.md>) has no concrete folder.`n"

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 0 -Because $result.Output
        $result.Output | Should -Match 'docs-working-model-check: PASS'
        $result.Output | Should -Not -Match 'E2 FAIL'
    }

    It 'AC-DWM-FN1-5: an angle-bracket link WITH a CommonMark title to a real candidate fails E2 (D4)' {
        $project = script:New-CaseRoot -CaseName 'fn1-angle-title'
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'docs/scopeguard/scopeguard_incubation.md') -Content "# scopeguard incubation`n"
        # CommonMark allows an optional title after the angle-bracket destination: [text](<dest> "title").
        # The unwrap must still extract the destination (title excluded) and flag the durable link.
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'rules/some-rule/some-rule.md') -Content "# some rule`n`nSee [the candidate](<../../docs/scopeguard/scopeguard_incubation.md> `"Candidate doc`") for detail.`n"

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 1 -Because $result.Output
        $result.Output | Should -Match 'E2 FAIL'
        $result.Output | Should -Match 'angle-bracket link'
        $result.Output | Should -Match 'scopeguard_incubation.md'
    }

    It 'AC-DWM-FN1-6: an angle-bracket link with a trailing #anchor fragment to a real candidate fails E2 (LC FIX-A)' {
        $project = script:New-CaseRoot -CaseName 'fn1-angle-fragment'
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'docs/scopeguard/scopeguard_incubation.md') -Content "# scopeguard incubation`n"
        # A #fragment after the .md must NOT defeat the end-anchor: the path portion still
        # resolves to the discovered candidate tail. (Before FIX-A the dest did not END in
        # "_incubation.md" so the angle-scan skipped it -- a narrow false-negative.)
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'rules/some-rule/some-rule.md') -Content "# some rule`n`nSee [the candidate](<../../docs/scopeguard/scopeguard_incubation.md#anchor>) for detail.`n"

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 1 -Because $result.Output
        $result.Output | Should -Match 'E2 FAIL'
        $result.Output | Should -Match 'angle-bracket link'
        $result.Output | Should -Match 'scopeguard_incubation.md'
    }

    It 'AC-DWM-FN1-7: an angle-bracket link with a trailing ?query to a real candidate fails E2 (LC FIX-A)' {
        $project = script:New-CaseRoot -CaseName 'fn1-angle-query'
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'docs/scopeguard/scopeguard_incubation.md') -Content "# scopeguard incubation`n"
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'rules/some-rule/some-rule.md') -Content "# some rule`n`nSee [the candidate](<../../docs/scopeguard/scopeguard_incubation.md?v=2>) for detail.`n"

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 1 -Because $result.Output
        $result.Output | Should -Match 'E2 FAIL'
        $result.Output | Should -Match 'angle-bracket link'
        $result.Output | Should -Match 'scopeguard_incubation.md'
    }

    It 'AC-DWM-FN1-8: a #fragment angle-link to a same-leaf file in a DIFFERENT folder is still NOT a violation (over-reach stays zero)' {
        $project = script:New-CaseRoot -CaseName 'fn1-angle-fragment-other-folder'
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'docs/scopeguard/scopeguard_incubation.md') -Content "# scopeguard incubation`n"
        # Even with a #fragment, the stripped path tail (old/scopeguard_incubation.md) is not the
        # discovered candidate (scopeguard/scopeguard_incubation.md) -> no hit. FIX-A must not over-reach.
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'rules/some-rule/some-rule.md') -Content "# some rule`n`nHistorical: [old](<../../old/scopeguard_incubation.md#anchor>) (different folder).`n"

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 0 -Because $result.Output
        $result.Output | Should -Match 'docs-working-model-check: PASS'
        $result.Output | Should -Not -Match 'E2 FAIL'
    }
}

Describe 'docs-working-model-check FN-3 docs domain purity' {
    It 'AC-DWM-FN3-1: a topic-named file under a promoted docs domain fails DOCS-PURITY' {
        $project = script:New-CaseRoot -CaseName 'fn3-topic-file'
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'docs/widget/widget_spec.md') -Content "# widget spec`n`n## Lifecycle state`n`n- spec to implementation: **live** - synced 1:1.`n"
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'docs/widget/random_topic.md') -Content "# a topic-named file`n"

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 1 -Because $result.Output
        $result.Output | Should -Match 'DOCS-PURITY FAIL'
        $result.Output | Should -Match 'random_topic.md'
    }

    It 'AC-DWM-FN3-2: a filename-evading subfolder under a promoted docs domain fails DOCS-PURITY' {
        $project = script:New-CaseRoot -CaseName 'fn3-work-subfolder'
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'docs/widget/widget_spec.md') -Content "# widget spec`n`n## Lifecycle state`n`n- spec to implementation: **live** - synced 1:1.`n"
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'docs/widget/work/notes.md') -Content "# evading subfolder`n"

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 1 -Because $result.Output
        $result.Output | Should -Match 'DOCS-PURITY FAIL'
        $result.Output | Should -Match 'disallowed subfolder'
        $result.Output | Should -Match 'work'
    }

    It 'AC-DWM-FN3-3: an auxiliary domain_policy.md is ACCEPTED under a promoted docs domain (its Design/Plan approval is not a structural fact the check can verify)' {
        $project = script:New-CaseRoot -CaseName 'fn3-aux-policy'
        # The auxiliary roles (_policy/_contract/_state/_status/_guide) are deferred by the rule
        # (introduced only by an explicit Design/Plan decision); the check cannot verify approval,
        # so rather than over-strictly forbid an approved auxiliary doc it accepts the known role names.
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'docs/widget/widget_spec.md') -Content "# widget spec`n`n## Lifecycle state`n`n- spec to implementation: **live** - synced 1:1.`n"
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'docs/widget/widget_policy.md') -Content "# auxiliary policy doc`n"

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 0 -Because $result.Output
        $result.Output | Should -Match 'docs-working-model-check: PASS'
        $result.Output | Should -Not -Match 'DOCS-PURITY FAIL'
    }

    It 'AC-DWM-FN3-4: an in-flight candidate (incubation, no spec) with an extra file is conform-pass (no DOCS-PURITY)' {
        $project = script:New-CaseRoot -CaseName 'fn3-candidate-passthrough'
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'docs/cand/cand_incubation.md') -Content "# cand incubation`n"
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'docs/cand/cand_scratch.md') -Content "# scratch (allowed during incubation; folder not promoted)`n"

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 0 -Because $result.Output
        $result.Output | Should -Match 'docs-working-model-check: PASS'
        $result.Output | Should -Not -Match 'DOCS-PURITY FAIL'
    }

    It 'AC-DWM-FN3-5: a clean promoted domain (README + spec + backlog) passes' {
        $project = script:New-CaseRoot -CaseName 'fn3-clean-promoted'
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'docs/widget/README.md') -Content "# widget orientation`n"
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'docs/widget/widget_spec.md') -Content "# widget spec`n`n## Lifecycle state`n`n- spec to implementation: **live** - synced 1:1.`n"
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'docs/widget/widget_backlog.md') -Content "# widget backlog`n`nnext ID: WG-B-01`n"

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 0 -Because $result.Output
        $result.Output | Should -Match 'docs-working-model-check: PASS'
        $result.Output | Should -Not -Match 'DOCS-PURITY FAIL'
    }

    It 'AC-DWM-FN3-6: a mid-promotion domain (only _design.md, no _spec) with a work/ subfolder fails DOCS-PURITY (promotion-entry binding)' {
        $project = script:New-CaseRoot -CaseName 'fn3-midpromo-subfolder'
        # Promotion-entry: a _design.md (no _spec yet) BINDS DOCS-PURITY (a candidate in incubation can
        # only carry _incubation.md, so a _design sibling means the domain has entered promotion). The
        # filename-evading work/ subfolder is then forbidden.
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'docs/widget/widget_design.md') -Content "# widget design`n"
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'docs/widget/work/notes.md') -Content "# evading subfolder`n"

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 1 -Because $result.Output
        $result.Output | Should -Match 'DOCS-PURITY FAIL'
        $result.Output | Should -Match 'disallowed subfolder'
        $result.Output | Should -Match 'work'
    }
}

Describe 'docs-working-model-check FN-7 backlog next-ID floor' {
    It 'AC-DWM-FN7-1: a multi-prefix backlog (install-update shape) with floors above max rows passes' {
        $project = script:New-CaseRoot -CaseName 'fn7-multi-prefix'
        # Real install-update shape: two per-prefix floors separated by a middot (built
        # via char code to keep this test file pure ASCII).
        $mid = [char]0x00B7
        $content = "# iu backlog`n`nnext ID: IU-B-14 (open IU-B-* rows) $mid IU-D-12 (deferred IU-D-* rows)`n`n| ID | item | cond |`n|---|---|---|`n| IU-B-01 | x | y |`n| IU-B-06 | x | y |`n| IU-D-11 | x | y |`n"
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'docs/iu/iu_backlog.md') -Content $content

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 0 -Because $result.Output
        $result.Output | Should -Match 'docs-working-model-check: PASS'
        $result.Output | Should -Not -Match 'BACKLOG-NEXTID FAIL'
    }

    It 'AC-DWM-FN7-2: a single-prefix backlog with a floor above max row passes' {
        $project = script:New-CaseRoot -CaseName 'fn7-single-prefix'
        $content = "# rv backlog`n`nnext ID: RV-B-17`n`n| ID | item | cond |`n|---|---|---|`n| RV-B-01 | x | y |`n| RV-B-16 | x | y |`n"
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'docs/rv/rv_backlog.md') -Content $content

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 0 -Because $result.Output
        $result.Output | Should -Match 'docs-working-model-check: PASS'
        $result.Output | Should -Not -Match 'BACKLOG-NEXTID FAIL'
    }

    It 'AC-DWM-FN7-3: a floor not strictly above the max present row id fails BACKLOG-NEXTID' {
        $project = script:New-CaseRoot -CaseName 'fn7-floor-too-low'
        $content = "# rv backlog`n`nnext ID: RV-B-05`n`n| ID | item | cond |`n|---|---|---|`n| RV-B-09 | x | y |`n"
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'docs/rv/rv_backlog.md') -Content $content

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 1 -Because $result.Output
        $result.Output | Should -Match 'BACKLOG-NEXTID FAIL'
        $result.Output | Should -Match 'not above the max present'
    }

    It 'AC-DWM-FN7-4: a backlog with no next-ID header fails BACKLOG-NEXTID' {
        $project = script:New-CaseRoot -CaseName 'fn7-no-header'
        $content = "# rv backlog`n`n| ID | item | cond |`n|---|---|---|`n| RV-B-01 | x | y |`n"
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'docs/rv/rv_backlog.md') -Content $content

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 1 -Because $result.Output
        $result.Output | Should -Match 'BACKLOG-NEXTID FAIL'
        $result.Output | Should -Match 'no "next ID:" header'
    }

    It 'AC-DWM-FN7-5: a parenthetical-prose id on the next-ID line does NOT inflate the floor (D1 prose-inflation)' {
        $project = script:New-CaseRoot -CaseName 'fn7-prose-inflation'
        # The DECLARED floor is RV-B-05, which is NOT above the present RV-B-09 row -> a real violation.
        # The parenthetical "RV-B-99" is prose, not the declared floor; under the old "match every token"
        # logic it wrongly lifted the floor to 99 and PASSed. Only the segment's leading token is the floor.
        $content = "# rv backlog`n`nnext ID: RV-B-05 (do not reuse RV-B-99)`n`n| ID | item | cond |`n|---|---|---|`n| RV-B-09 | x | y |`n"
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'docs/rv/rv_backlog.md') -Content $content

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 1 -Because $result.Output
        $result.Output | Should -Match 'BACKLOG-NEXTID FAIL'
        $result.Output | Should -Match 'not above the max present'
    }

    It 'AC-DWM-FN7-6: a row id number that overflows a 64-bit integer is a clean FAIL, not a crash (D5)' {
        $project = script:New-CaseRoot -CaseName 'fn7-overflow'
        # A 26-digit id overflows [long]; the old [int] cast aborted the whole run under
        # $ErrorActionPreference='Stop'. The fix reports a clean malformed-id FAIL with no leaked exception.
        $content = "# rv backlog`n`nnext ID: RV-B-17`n`n| ID | item | cond |`n|---|---|---|`n| RV-B-99999999999999999999999999 | x | y |`n"
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'docs/rv/rv_backlog.md') -Content $content

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 1 -Because $result.Output
        $result.Output | Should -Match 'BACKLOG-NEXTID FAIL'
        $result.Output | Should -Match 'too large to parse'
        $result.Output | Should -Not -Match 'Exception'
    }

    It 'AC-DWM-FN7-7: a present-but-tokenless next-ID header is a malformed-header FAIL (D6)' {
        $project = script:New-CaseRoot -CaseName 'fn7-malformed-header'
        # The header line exists but declares no "<PREFIX>-NN" token; silent PASS is forbidden.
        $content = "# rv backlog`n`nnext ID: TBD`n`n| ID | item | cond |`n|---|---|---|`n"
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'docs/rv/rv_backlog.md') -Content $content

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 1 -Because $result.Output
        $result.Output | Should -Match 'BACKLOG-NEXTID FAIL'
        $result.Output | Should -Match 'holds no valid'
    }

    It 'AC-DWM-FN7-8: rows of a prefix with no matching next-ID floor fail BACKLOG-NEXTID' {
        $project = script:New-CaseRoot -CaseName 'fn7-rows-no-floor'
        # The floor declares RV-B only; a RV-C row has no floor tracking its prefix.
        $content = "# rv backlog`n`nnext ID: RV-B-17`n`n| ID | item | cond |`n|---|---|---|`n| RV-B-01 | x | y |`n| RV-C-03 | x | y |`n"
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'docs/rv/rv_backlog.md') -Content $content

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 1 -Because $result.Output
        $result.Output | Should -Match 'BACKLOG-NEXTID FAIL'
        $result.Output | Should -Match 'no matching next-ID floor'
    }

    It 'AC-DWM-FN7-9: a decorated row id (**PFX-NN**) is still counted against the floor (D8 row symmetry)' {
        $project = script:New-CaseRoot -CaseName 'fn7-decorated-row'
        # Floor RV-B-17 is NOT above the decorated **RV-B-20** row. The old exact "^<PFX>-NN$" row scan
        # skipped a decorated/annotated id and falsely PASSed; the leading-token scan must still count it.
        $content = "# rv backlog`n`nnext ID: RV-B-17`n`n| ID | item | cond |`n|---|---|---|`n| **RV-B-20** | x | y |`n"
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'docs/rv/rv_backlog.md') -Content $content

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 1 -Because $result.Output
        $result.Output | Should -Match 'BACKLOG-NEXTID FAIL'
        $result.Output | Should -Match 'not above the max present'
    }

    It 'AC-DWM-FN7-10: a row id with an UNSEPARATED alnum suffix (RV-B-17abc) is NOT counted (malformed; digit-boundary LC FIX-B)' {
        $project = script:New-CaseRoot -CaseName 'fn7-suffix-malformed-row'
        # Floor RV-B-05; the ONLY row is the malformed RV-B-17abc. Before FIX-B the leading-token
        # parser read it as RV-B-17 (digits 17 with the "abc" suffix dangling), so the floor 05 was
        # "not above 17" -> a false FAIL. With the digit-boundary the token is malformed -> $null ->
        # the row is not counted -> no RV-B rows -> PASS.
        $content = "# rv backlog`n`nnext ID: RV-B-05`n`n| ID | item | cond |`n|---|---|---|`n| RV-B-17abc | x | y |`n"
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'docs/rv/rv_backlog.md') -Content $content

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 0 -Because $result.Output
        $result.Output | Should -Match 'docs-working-model-check: PASS'
        $result.Output | Should -Not -Match 'BACKLOG-NEXTID FAIL'
    }

    It 'AC-DWM-FN7-11: a clean RV-B-17 row IS still counted (digit-boundary does not break a well-formed id; LC FIX-B regression-pair)' {
        $project = script:New-CaseRoot -CaseName 'fn7-clean-row-still-counted'
        # The well-formed mirror of FN7-10: floor RV-B-05 is NOT above the present clean RV-B-17 row,
        # so a real id (ending at a non-alnum boundary) must still be counted -> FAIL. This proves the
        # digit-boundary lookahead rejects ONLY the unseparated alnum suffix, not a normal id.
        $content = "# rv backlog`n`nnext ID: RV-B-05`n`n| ID | item | cond |`n|---|---|---|`n| RV-B-17 | x | y |`n"
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'docs/rv/rv_backlog.md') -Content $content

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 1 -Because $result.Output
        $result.Output | Should -Match 'BACKLOG-NEXTID FAIL'
        $result.Output | Should -Match 'not above the max present'
    }
}

Describe 'docs-working-model-check sibling-mention advisory inventory' {
    It 'AC-DWM-SM-1: a bare candidate name mention on a canonical surface emits an INFO line and stays PASS' {
        $project = script:New-CaseRoot -CaseName 'sm-info'
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'rule_docs/scopeguard/scopeguard_incubation.md') -Content "# scopeguard incubation`n"
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'rules/somerule/somerule.md') -Content "# some rule`n`nthis rule may mention the still-incubating scopeguard candidate by name.`n"

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 0 -Because $result.Output
        $result.Output | Should -Match 'SIBLING-MENTION INFO'
        $result.Output | Should -Match 'candidate "scopeguard"'
        $result.Output | Should -Match 'somerule\.md line\(s\) 3'
        $result.Output | Should -Match 'docs-working-model-check: PASS'
    }

    It 'AC-DWM-SM-2: a longer slug containing the candidate id does not match (standalone-token boundary)' {
        $project = script:New-CaseRoot -CaseName 'sm-boundary'
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'rule_docs/scopeguard/scopeguard_incubation.md') -Content "# scopeguard incubation`n"
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'rules/somerule/somerule.md') -Content "# some rule`n`nscopeguard-extended and scopeguardian and my_scopeguard are different ids.`n"

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 0 -Because $result.Output
        $result.Output | Should -Not -Match 'SIBLING-MENTION INFO'
    }

    It 'AC-DWM-SM-3: no mention anywhere emits no inventory line and the inventory never gates the exit code' {
        $project = script:New-CaseRoot -CaseName 'sm-none'
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'rule_docs/scopeguard/scopeguard_incubation.md') -Content "# scopeguard incubation`n"
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'rules/somerule/somerule.md') -Content "# some rule`n`nno mentions here.`n"

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 0 -Because $result.Output
        $result.Output | Should -Not -Match 'SIBLING-MENTION INFO'
        $result.Output | Should -Match 'docs-working-model-check: PASS'
    }
}

Describe 'docs-working-model-check TERM-RESERVE terminology registration' {
    BeforeAll {
        $script:Em = [string][char]0x2014

        function script:New-GlossaryContent {
            # Build a minimal glossary carrying a "### Pending" subsection (and an
            # optional "### Owner-pending" subsection) in the real file's shape.
            param(
                [string[]] $PendingEntries,
                [string[]] $OwnerPendingEntries = @()
            )
            $lines = @(
                '# Rule: Project terminology glossary',
                '',
                '## Pending / owner-pending terms',
                '',
                ('### Pending ' + $script:Em + ' finalization-owner not yet at live authority'),
                ''
            )
            $lines += $PendingEntries
            if ($OwnerPendingEntries.Count -gt 0) {
                $lines += @('', ('### Owner-pending ' + $script:Em + ' finalization-owner at live authority, finalization deferred'), '')
                $lines += $OwnerPendingEntries
            }
            $lines += @('', '## Rejected terms', '')
            return (($lines -join "`n") + "`n")
        }
    }

    It 'AC-DWM-TR-1: a bound candidate entry still in the pre-model label form fails' {
        $project = script:New-CaseRoot -CaseName 'tr-premodel'
        $entry = '- **`foo`** ' + $script:Em + ' the old fuller definition text. owner = the `consultation` incubation candidate; facet = x; not-this = y; close = on promotion; promotion target = z.'
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'rules/terminology-glossary.md') -Content (script:New-GlossaryContent -PendingEntries @($entry))

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 1 -Because $result.Output
        $result.Output | Should -Match 'TERM-RESERVE FAIL'
        $result.Output | Should -Match 'pre-model label form'
    }

    It 'AC-DWM-TR-2: a bound candidate entry in the conformant reservation-field form passes' {
        $project = script:New-CaseRoot -CaseName 'tr-conform'
        $entry = '- **`foo`** ' + $script:Em + ' candidate = `consultation`; facet = a sample facet; not-this = **not** something else; eventual-owner-surface = the promoted `consultation` domain.'
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'rules/terminology-glossary.md') -Content (script:New-GlossaryContent -PendingEntries @($entry))

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 0 -Because $result.Output
        $result.Output | Should -Not -Match 'TERM-RESERVE FAIL'
        $result.Output | Should -Match 'docs-working-model-check: PASS'
    }

    It 'AC-DWM-TR-3: an unbound candidate entry keeps its pre-model form (transition exemption)' {
        $project = script:New-CaseRoot -CaseName 'tr-exempt'
        $entry = '- **`bar`** ' + $script:Em + ' the old fuller definition text. owner = the `scopeguard` incubation candidate; facet = x; not-this = y; close = on promotion; promotion target = z.'
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'rules/terminology-glossary.md') -Content (script:New-GlossaryContent -PendingEntries @($entry))

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 0 -Because $result.Output
        $result.Output | Should -Not -Match 'TERM-RESERVE FAIL'
        $result.Output | Should -Match 'docs-working-model-check: PASS'
    }

    It 'AC-DWM-TR-4: a stray pre-model label inside a new-form bound entry fails as an unlicensed segment' {
        $project = script:New-CaseRoot -CaseName 'tr-straylabel'
        $entry = '- **`foo`** ' + $script:Em + ' candidate = `consultation`; facet = x; not-this = y; close = on promotion.'
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'rules/terminology-glossary.md') -Content (script:New-GlossaryContent -PendingEntries @($entry))

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 1 -Because $result.Output
        $result.Output | Should -Match 'TERM-RESERVE FAIL'
        $result.Output | Should -Match 'not a licensed reservation field'
    }

    It 'AC-DWM-TR-5: a positive definition segment before the fields fails (define no meaning)' {
        $project = script:New-CaseRoot -CaseName 'tr-definition'
        $entry = '- **`foo`** ' + $script:Em + ' the read-only advisory workflow that does things. candidate = `consultation`; facet = x; not-this = y.'
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'rules/terminology-glossary.md') -Content (script:New-GlossaryContent -PendingEntries @($entry))

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 1 -Because $result.Output
        $result.Output | Should -Match 'TERM-RESERVE FAIL'
        $result.Output | Should -Match 'not a licensed reservation field'
    }

    It 'AC-DWM-TR-6: a durable pointer inside a bound entry fails' {
        $project = script:New-CaseRoot -CaseName 'tr-pointer'
        $entry = '- **`foo`** ' + $script:Em + ' candidate = `consultation`; facet = x; not-this = y; eventual-owner-surface = docs/consultation/consultation_incubation.md.'
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'rules/terminology-glossary.md') -Content (script:New-GlossaryContent -PendingEntries @($entry))

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 1 -Because $result.Output
        $result.Output | Should -Match 'TERM-RESERVE FAIL'
        $result.Output | Should -Match 'durable pointer'
    }

    It 'AC-DWM-TR-7: a collision-note in the fixed wording as the last field passes' {
        $project = script:New-CaseRoot -CaseName 'tr-collision-ok'
        $entry = '- **`foo`** ' + $script:Em + ' candidate = `consultation`; facet = x; not-this = y; collision-note = Potential collision with `bar`; defines no semantics; see this reservation''s candidate.'
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'rules/terminology-glossary.md') -Content (script:New-GlossaryContent -PendingEntries @($entry))

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 0 -Because $result.Output
        $result.Output | Should -Not -Match 'TERM-RESERVE FAIL'
        $result.Output | Should -Match 'docs-working-model-check: PASS'
    }

    It 'AC-DWM-TR-8: a collision-note without the fixed wording fails' {
        $project = script:New-CaseRoot -CaseName 'tr-collision-bad'
        $entry = '- **`foo`** ' + $script:Em + ' candidate = `consultation`; facet = x; not-this = y; collision-note = might collide with bar somehow.'
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'rules/terminology-glossary.md') -Content (script:New-GlossaryContent -PendingEntries @($entry))

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 1 -Because $result.Output
        $result.Output | Should -Match 'TERM-RESERVE FAIL'
        $result.Output | Should -Match 'collision-note without the fixed wording'
    }

    It 'AC-DWM-TR-9: a bound entry missing a required field (not-this) fails' {
        $project = script:New-CaseRoot -CaseName 'tr-required'
        $entry = '- **`foo`** ' + $script:Em + ' candidate = `consultation`; facet = x; eventual-owner-surface = the promoted `consultation` domain.'
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'rules/terminology-glossary.md') -Content (script:New-GlossaryContent -PendingEntries @($entry))

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 1 -Because $result.Output
        $result.Output | Should -Match 'TERM-RESERVE FAIL'
        $result.Output | Should -Match 'missing the required reservation field "not-this"'
    }

    It 'AC-DWM-TR-10: the Owner-pending subsection is not validated by TERM-RESERVE' {
        $project = script:New-CaseRoot -CaseName 'tr-ownerpending'
        $pending = '- **`foo`** ' + $script:Em + ' candidate = `consultation`; facet = x; not-this = y.'
        $ownerPending = '- **`baz`** ' + $script:Em + ' a one-line meaning kept by design. owner = the `consultation` incubation candidate; finalization-owner = a rule; facet = f; close-condition = c; not-this = n.'
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'rules/terminology-glossary.md') -Content (script:New-GlossaryContent -PendingEntries @($pending) -OwnerPendingEntries @($ownerPending))

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 0 -Because $result.Output
        $result.Output | Should -Not -Match 'TERM-RESERVE FAIL'
        $result.Output | Should -Match 'docs-working-model-check: PASS'
    }

    It 'AC-DWM-TR-11: bound conformant and unbound pre-model entries coexist as a PASS (the real transition shape)' {
        $project = script:New-CaseRoot -CaseName 'tr-mixed'
        $bound = '- **`foo`** ' + $script:Em + ' candidate = `consultation`; facet = a sample facet; not-this = **not** something else; eventual-owner-surface = the promoted `consultation` domain.'
        $exempt = '- **`bar`** ' + $script:Em + ' the old fuller definition text. owner = the `scopeguard` incubation candidate; facet = x; not-this = y; close = on promotion; promotion target = z.'
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'rules/terminology-glossary.md') -Content (script:New-GlossaryContent -PendingEntries @($bound, $exempt))

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 0 -Because $result.Output
        $result.Output | Should -Not -Match 'TERM-RESERVE FAIL'
        $result.Output | Should -Match 'docs-working-model-check: PASS'
    }

    It 'AC-DWM-TR-12: a durable pointer with log/ (forward slash) inside a bound entry fails' {
        $project = script:New-CaseRoot -CaseName 'tr-pointer-log-fwd'
        $entry = '- **`foo`** ' + $script:Em + ' candidate = `consultation`; facet = x; not-this = y; eventual-owner-surface = log/blind/runs.md.'
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'rules/terminology-glossary.md') -Content (script:New-GlossaryContent -PendingEntries @($entry))

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 1 -Because $result.Output
        $result.Output | Should -Match 'TERM-RESERVE FAIL'
        $result.Output | Should -Match 'durable pointer'
    }

    It 'AC-DWM-TR-13: a durable pointer with log\ (backslash) inside a bound entry fails' {
        $project = script:New-CaseRoot -CaseName 'tr-pointer-log-back'
        $entry = '- **`foo`** ' + $script:Em + ' candidate = `consultation`; facet = x; not-this = y; eventual-owner-surface = log\blind\runs.md.'
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'rules/terminology-glossary.md') -Content (script:New-GlossaryContent -PendingEntries @($entry))

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 1 -Because $result.Output
        $result.Output | Should -Match 'TERM-RESERVE FAIL'
        $result.Output | Should -Match 'durable pointer'
    }

    It 'AC-DWM-TR-14: a durable pointer with polishing/ (forward slash) inside a bound entry fails' {
        $project = script:New-CaseRoot -CaseName 'tr-pointer-pol-fwd'
        $entry = '- **`foo`** ' + $script:Em + ' candidate = `consultation`; facet = x; not-this = y; eventual-owner-surface = polishing/toolset_direction/x.md.'
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'rules/terminology-glossary.md') -Content (script:New-GlossaryContent -PendingEntries @($entry))

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 1 -Because $result.Output
        $result.Output | Should -Match 'TERM-RESERVE FAIL'
        $result.Output | Should -Match 'durable pointer'
    }

    It 'AC-DWM-TR-15: a durable pointer with polishing\ (backslash) inside a bound entry fails' {
        $project = script:New-CaseRoot -CaseName 'tr-pointer-pol-back'
        $entry = '- **`foo`** ' + $script:Em + ' candidate = `consultation`; facet = x; not-this = y; eventual-owner-surface = polishing\toolset_direction\x.md.'
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'rules/terminology-glossary.md') -Content (script:New-GlossaryContent -PendingEntries @($entry))

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 1 -Because $result.Output
        $result.Output | Should -Match 'TERM-RESERVE FAIL'
        $result.Output | Should -Match 'durable pointer'
    }

    It 'AC-DWM-TR-16: a durable pointer with a drive-letter absolute path inside a bound entry fails' {
        $project = script:New-CaseRoot -CaseName 'tr-pointer-drive'
        $entry = '- **`foo`** ' + $script:Em + ' candidate = `consultation`; facet = x; not-this = y; eventual-owner-surface = C:\work\x.md.'
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'rules/terminology-glossary.md') -Content (script:New-GlossaryContent -PendingEntries @($entry))

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 1 -Because $result.Output
        $result.Output | Should -Match 'TERM-RESERVE FAIL'
        $result.Output | Should -Match 'durable pointer'
    }

    It 'AC-DWM-TR-17: a bound blind-advisory candidate entry still in pre-model form fails (bound-candidate regression)' {
        $project = script:New-CaseRoot -CaseName 'tr-blind-premodel'
        $entry = '- **`foo`** ' + $script:Em + ' the old fuller definition text. owner = the `blind-advisory` incubation candidate; facet = x; not-this = y; close = on promotion; promotion target = z.'
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'rules/terminology-glossary.md') -Content (script:New-GlossaryContent -PendingEntries @($entry))

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 1 -Because $result.Output
        $result.Output | Should -Match 'TERM-RESERVE FAIL'
        $result.Output | Should -Match 'pre-model label form'
    }

    It 'AC-DWM-TR-18: a durable pointer inside a bound blind-advisory entry fails (bound-candidate regression)' {
        $project = script:New-CaseRoot -CaseName 'tr-blind-pointer'
        $entry = '- **`foo`** ' + $script:Em + ' candidate = `blind-advisory`; facet = x; not-this = y; eventual-owner-surface = log/blind/runs.md.'
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'rules/terminology-glossary.md') -Content (script:New-GlossaryContent -PendingEntries @($entry))

        $result = script:Invoke-Check -ProjectRoot $project
        $result.ExitCode | Should -Be 1 -Because $result.Output
        $result.Output | Should -Match 'TERM-RESERVE FAIL'
        $result.Output | Should -Match 'durable pointer'
    }
}
