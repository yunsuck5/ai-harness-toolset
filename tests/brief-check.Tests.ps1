Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

BeforeAll {
    $script:RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).ProviderPath
    $script:BriefCheckScript = Join-Path $script:RepoRoot 'scripts/brief-check.ps1'

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
        $caseRoot = Join-Path $TestDrive ('pester-brief-check-' + $CaseName)
        if (Test-Path -LiteralPath $caseRoot) {
            Remove-Item -LiteralPath $caseRoot -Recurse -Force
        }
        $null = New-Item -ItemType Directory -Path $caseRoot -Force
        return ([System.IO.Path]::GetFullPath($caseRoot))
    }

    function script:Get-FilledBriefBody {
        return @"
# Project Brief

## Current state
project is at phase 0; baseline 6916f55 on main.

## Last completed action
adopted post-MVP decision guide.

## Current scope
brief slice 1 implementation review.

## Next single action
land brief-check tests.

## Do not do
do not introduce daemon or watcher.

## Files to inspect first
docs/contracts/brief/BRIEF_CONTRACT.md
templates/brief/BRIEF.md

## Open risks
none.

## Pending user decision
none.
"@
    }

    function script:Get-SentinelLeftBriefBody {
        # Required headings present, but one section still has the replace-me sentinel.
        return @"
# Project Brief

## Current state
project is at phase 0.

## Last completed action
(Replace this section with project-specific content.)

## Current scope
slice 1.

## Next single action
land tests.

## Do not do
no daemon.

## Files to inspect first
docs/contracts/brief/BRIEF_CONTRACT.md

## Open risks
none.

## Pending user decision
none.
"@
    }

    function script:Get-EmptySectionBriefBody {
        # Required heading present but body is whitespace only.
        return @"
# Project Brief

## Current state
project is at phase 0.

## Last completed action
adopted post-MVP decision guide.

## Current scope


## Next single action
land tests.

## Do not do
no daemon.

## Files to inspect first
docs/contracts/brief/BRIEF_CONTRACT.md

## Open risks
none.

## Pending user decision
none.
"@
    }

    function script:Get-MissingHeadingBriefBody {
        # Drops "## Open risks".
        return @"
# Project Brief

## Current state
project is at phase 0.

## Last completed action
adopted post-MVP decision guide.

## Current scope
slice 1.

## Next single action
land tests.

## Do not do
no daemon.

## Files to inspect first
docs/contracts/brief/BRIEF_CONTRACT.md

## Pending user decision
none.
"@
    }

    function script:Get-DuplicateHeadingBriefBody {
        return @"
# Project Brief

## Current state
project is at phase 0.

## Current state
duplicate heading on purpose.

## Last completed action
adopted post-MVP decision guide.

## Current scope
slice 1.

## Next single action
land tests.

## Do not do
no daemon.

## Files to inspect first
docs/contracts/brief/BRIEF_CONTRACT.md

## Open risks
none.

## Pending user decision
none.
"@
    }

    function script:Get-PlaceholderTokenBriefBody {
        # Filled body but contains an unreplaced double-curly placeholder marker.
        return @"
# Project Brief

## Current state
project is at phase {{PHASE_ID}}.

## Last completed action
adopted post-MVP decision guide.

## Current scope
slice 1.

## Next single action
land tests.

## Do not do
no daemon.

## Files to inspect first
docs/contracts/brief/BRIEF_CONTRACT.md

## Open risks
none.

## Pending user decision
none.
"@
    }

    function script:Invoke-BriefCheck {
        param(
            [string] $ProjectRoot,
            [string] $BriefPath
        )
        $procArgs = @(
            '-NoProfile',
            '-ExecutionPolicy', 'Bypass',
            '-File', $script:BriefCheckScript,
            '-ProjectRoot', $ProjectRoot
        )
        if (-not [string]::IsNullOrEmpty($BriefPath)) {
            $procArgs += @('-BriefPath', $BriefPath)
        }
        $combined = & powershell.exe @procArgs 2>&1
        $exitCode = $LASTEXITCODE
        $text = ($combined | ForEach-Object { [string]$_ }) -join "`n"
        return [pscustomobject]@{
            ExitCode = $exitCode
            Output   = $text
        }
    }
}

Describe 'brief-check happy path' {
    It 'AC-BC-PASS-1: filled BRIEF with all required headings non-empty exits 0' {
        $project = script:New-CaseRoot -CaseName 'pass-1'
        $briefPath = Join-Path $project 'log/brief/BRIEF.md'
        script:Write-Utf8NoBomFile -Path $briefPath -Content (script:Get-FilledBriefBody)

        $result = script:Invoke-BriefCheck -ProjectRoot $project
        $result.ExitCode | Should -Be 0 -Because $result.Output
        $result.Output | Should -Match 'brief-check: PASS'
    }
}

Describe 'brief-check missing-file' {
    It 'AC-BC-MISSING-1: missing BRIEF.md exits non-zero with diagnostic' {
        $project = script:New-CaseRoot -CaseName 'missing-1'
        $briefPath = Join-Path $project 'log/brief/BRIEF.md'
        Test-Path -LiteralPath $briefPath | Should -BeFalse

        $result = script:Invoke-BriefCheck -ProjectRoot $project
        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match 'BRIEF.md not found'
    }
}

Describe 'brief-check sentinel-remains' {
    It 'AC-BC-SENTINEL-1: replace-me sentinel left in any required section exits non-zero' {
        $project = script:New-CaseRoot -CaseName 'sentinel-1'
        $briefPath = Join-Path $project 'log/brief/BRIEF.md'
        script:Write-Utf8NoBomFile -Path $briefPath -Content (script:Get-SentinelLeftBriefBody)

        $result = script:Invoke-BriefCheck -ProjectRoot $project
        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match 'sentinel remains'
        $result.Output | Should -Match 'Last completed action'
    }
}

Describe 'brief-check empty-section' {
    It 'AC-BC-EMPTY-1: required section body that is whitespace only exits non-zero' {
        $project = script:New-CaseRoot -CaseName 'empty-1'
        $briefPath = Join-Path $project 'log/brief/BRIEF.md'
        script:Write-Utf8NoBomFile -Path $briefPath -Content (script:Get-EmptySectionBriefBody)

        $result = script:Invoke-BriefCheck -ProjectRoot $project
        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match 'required section is empty'
        $result.Output | Should -Match 'Current scope'
    }
}

Describe 'brief-check missing-heading' {
    It 'AC-BC-MISSING-HEADING-1: dropping a required heading exits non-zero' {
        $project = script:New-CaseRoot -CaseName 'missing-heading-1'
        $briefPath = Join-Path $project 'log/brief/BRIEF.md'
        script:Write-Utf8NoBomFile -Path $briefPath -Content (script:Get-MissingHeadingBriefBody)

        $result = script:Invoke-BriefCheck -ProjectRoot $project
        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match 'missing required heading'
        $result.Output | Should -Match 'Open risks'
    }
}

Describe 'brief-check duplicate-heading' {
    It 'AC-BC-DUPLICATE-1: duplicate required heading exits non-zero' {
        $project = script:New-CaseRoot -CaseName 'duplicate-1'
        $briefPath = Join-Path $project 'log/brief/BRIEF.md'
        script:Write-Utf8NoBomFile -Path $briefPath -Content (script:Get-DuplicateHeadingBriefBody)

        $result = script:Invoke-BriefCheck -ProjectRoot $project
        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match 'duplicate required heading'
        $result.Output | Should -Match 'Current state'
    }
}

Describe 'brief-check placeholder-token' {
    It 'AC-BC-PLACEHOLDER-1: unreplaced double-curly placeholder marker exits non-zero' {
        $project = script:New-CaseRoot -CaseName 'placeholder-1'
        $briefPath = Join-Path $project 'log/brief/BRIEF.md'
        script:Write-Utf8NoBomFile -Path $briefPath -Content (script:Get-PlaceholderTokenBriefBody)

        $result = script:Invoke-BriefCheck -ProjectRoot $project
        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match 'unreplaced placeholder marker'
    }
}

Describe 'brief-check containment' {
    It 'AC-BC-CONTAINMENT-1: -BriefPath outside ProjectRoot is refused' {
        $project = script:New-CaseRoot -CaseName 'containment-1'
        $outsidePath = Join-Path $TestDrive ('pester-brief-check-outside-' + ([guid]::NewGuid().ToString('N')) + '.md')
        script:Write-Utf8NoBomFile -Path $outsidePath -Content (script:Get-FilledBriefBody)

        $result = script:Invoke-BriefCheck -ProjectRoot $project -BriefPath $outsidePath
        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match 'outside ProjectRoot'
    }
}
