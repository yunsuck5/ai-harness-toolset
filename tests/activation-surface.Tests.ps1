Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Batch 2C-0 — generic deployed-extension (skill) activation-surface resolver unit tests.
# Everything runs in TestDrive. Get-ActivationSurfacePlan is pure (reads the payload + home paths and
# returns the surface plan); these tests exercise the generic skill enumeration directly, independent
# of the install / activate / uninstall entrypoints that consume it.

BeforeAll {
    $script:RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).ProviderPath
    . (Join-Path $script:RepoRoot 'scripts/lib/activation-surface.ps1')

    function script:New-Payload {
        # Build a payload root that CONTAINS snippets/ with the two managed-block snippets and the named
        # skills (each a snippets/claude-skills/<name>/SKILL.md). Returns the payload root path.
        param([string] $Case, [string[]] $Skills = @(), [switch] $NoClaudeSkillsDir, [string[]] $EmptySkillDirs = @())
        $root = Join-Path $TestDrive ('asurf-' + $Case)
        if (Test-Path -LiteralPath $root) { Remove-Item -LiteralPath $root -Recurse -Force }
        $enc = New-Object System.Text.UTF8Encoding($false)
        $null = New-Item -ItemType Directory -Path (Join-Path $root 'snippets') -Force
        [System.IO.File]::WriteAllText((Join-Path $root 'snippets/CLAUDE_SNIPPET.md'), '# claude', $enc)
        [System.IO.File]::WriteAllText((Join-Path $root 'snippets/AGENTS_SNIPPET.md'), '# agents', $enc)
        if (-not $NoClaudeSkillsDir) {
            foreach ($s in $Skills) {
                $d = Join-Path $root ('snippets/claude-skills/' + $s)
                $null = New-Item -ItemType Directory -Path $d -Force
                [System.IO.File]::WriteAllText((Join-Path $d 'SKILL.md'), ('# ' + $s), $enc)
            }
            foreach ($s in $EmptySkillDirs) {
                # a directory under claude-skills with NO SKILL.md — not a skill, must be skipped.
                $null = New-Item -ItemType Directory -Path (Join-Path $root ('snippets/claude-skills/' + $s)) -Force
            }
        }
        return ([System.IO.Path]::GetFullPath($root))
    }

    function script:Homes {
        param([string] $Case)
        return [pscustomobject]@{
            Claude = ([System.IO.Path]::GetFullPath((Join-Path $TestDrive ($Case + '-claude'))))
            Codex  = ([System.IO.Path]::GetFullPath((Join-Path $TestDrive ($Case + '-codex'))))
        }
    }

    # Unary-comma wrap so a single-element (or empty) result is NOT unwrapped to a scalar on return
    # (preserves .Count at every call site).
    function script:Get-SkillSurfaces { param($Plan); return ,@($Plan | Where-Object { $_.Class -eq 'canonical-overwrite' }) }
}

Describe 'Get-ActivationSurfacePlan — managed-block surfaces always present' {
    It 'always returns the two managed-block surfaces regardless of skills' {
        $p = script:New-Payload -Case 'mb' -Skills @('ai-harness-review')
        $h = script:Homes 'mb'
        $plan = Get-ActivationSurfacePlan -PayloadRoot $p -ClaudeHome $h.Claude -CodexHome $h.Codex
        @($plan | Where-Object { $_.Class -eq 'managed-block' }).Count | Should -Be 2
        ($plan | Where-Object { $_.Name -eq 'claude-user-global-managed-block' }) | Should -Not -BeNullOrEmpty
        ($plan | Where-Object { $_.Name -eq 'codex-user-global-managed-block' })  | Should -Not -BeNullOrEmpty
    }

    It 'managed-block surfaces carry SkillName = $null (uniform object shape)' {
        $p = script:New-Payload -Case 'shape' -Skills @('ai-harness-review')
        $h = script:Homes 'shape'
        $plan = Get-ActivationSurfacePlan -PayloadRoot $p -ClaudeHome $h.Claude -CodexHome $h.Codex
        foreach ($mb in @($plan | Where-Object { $_.Class -eq 'managed-block' })) {
            $mb.SkillName | Should -BeNullOrEmpty
        }
    }
}

Describe 'Get-ActivationSurfacePlan — generic skill enumeration (Batch 2C-0)' {
    It 'single skill preserves the ai-harness-review mirror (name, destination, class, SkillName)' {
        $p = script:New-Payload -Case 'single' -Skills @('ai-harness-review')
        $h = script:Homes 'single'
        $plan = Get-ActivationSurfacePlan -PayloadRoot $p -ClaudeHome $h.Claude -CodexHome $h.Codex
        $skills = script:Get-SkillSurfaces $plan
        $skills.Count          | Should -Be 1
        $skills[0].Name        | Should -Be 'skill-mirror:ai-harness-review'
        $skills[0].Scope       | Should -Be 'Skill'
        $skills[0].Class       | Should -Be 'canonical-overwrite'
        $skills[0].CompareMode | Should -Be 'whole-file'
        $skills[0].SkillName   | Should -Be 'ai-harness-review'
        $skills[0].Destination | Should -Be (Join-Path $h.Claude 'skills/ai-harness-review/SKILL.md')
        $skills[0].Source      | Should -Be (Join-Path $p 'snippets/claude-skills/ai-harness-review/SKILL.md')
    }

    It 'multiple skills each become a mirror surface, ordered deterministically by name' {
        # Created out of order; the resolver must sort by skill name so the surface list is stable.
        $p = script:New-Payload -Case 'multi' -Skills @('zeta-skill', 'ai-harness-review', 'ai-harness-brief')
        $h = script:Homes 'multi'
        $plan = Get-ActivationSurfacePlan -PayloadRoot $p -ClaudeHome $h.Claude -CodexHome $h.Codex
        $skills = script:Get-SkillSurfaces $plan
        @($skills | ForEach-Object { $_.Name })      | Should -Be @('skill-mirror:ai-harness-brief', 'skill-mirror:ai-harness-review', 'skill-mirror:zeta-skill')
        @($skills | ForEach-Object { $_.SkillName }) | Should -Be @('ai-harness-brief', 'ai-harness-review', 'zeta-skill')
    }

    It 'a directory under claude-skills WITHOUT a SKILL.md is not a skill (skipped)' {
        $p = script:New-Payload -Case 'emptydir' -Skills @('ai-harness-review') -EmptySkillDirs @('not-a-skill')
        $h = script:Homes 'emptydir'
        $plan = Get-ActivationSurfacePlan -PayloadRoot $p -ClaudeHome $h.Claude -CodexHome $h.Codex
        $skills = script:Get-SkillSurfaces $plan
        $skills.Count | Should -Be 1
        @($skills | Where-Object { $_.Name -match 'not-a-skill' }).Count | Should -Be 0
    }

    It 'no claude-skills directory under the payload root → zero skill surfaces (managed blocks only)' {
        $p = script:New-Payload -Case 'noskills' -NoClaudeSkillsDir
        $h = script:Homes 'noskills'
        $plan = Get-ActivationSurfacePlan -PayloadRoot $p -ClaudeHome $h.Claude -CodexHome $h.Codex
        (script:Get-SkillSurfaces $plan).Count | Should -Be 0
        @($plan).Count | Should -Be 2
    }
}
