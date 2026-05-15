Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

BeforeAll {
    $script:RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).ProviderPath
    $script:BriefStatusScript = Join-Path $script:RepoRoot 'scripts/brief-status.ps1'

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
        $caseRoot = Join-Path $TestDrive ('pester-brief-status-' + $CaseName)
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
land brief-status helper.

## Do not do
do not introduce daemon or watcher.

## Files to inspect first
docs/BRIEF_CONTRACT.md
templates/brief/BRIEF.md

## Open risks
none.

## Pending user decision
none.
"@
    }

    function script:Get-SentinelLeftBriefBody {
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
docs/BRIEF_CONTRACT.md

## Open risks
none.

## Pending user decision
none.
"@
    }

    function script:Get-BlankPrefixBriefBody {
        return @"
# Project Brief

## Current state


project is at phase 1 with leading blanks.

## Last completed action
adopted post-MVP decision guide.

## Current scope
slice 1.

## Next single action
land tests.

## Do not do
no daemon.

## Files to inspect first
docs/BRIEF_CONTRACT.md

## Open risks
none.

## Pending user decision
none.
"@
    }

    function script:Invoke-BriefStatus {
        param(
            [string] $ProjectRoot,
            [string] $BriefPath
        )
        $procArgs = @(
            '-NoProfile',
            '-ExecutionPolicy', 'Bypass',
            '-File', $script:BriefStatusScript,
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

Describe 'brief-status happy path' {
    It 'AC-BS-PASS-1: filled BRIEF exits 0, prints PASS line and Korean-labeled summary for every required heading' {
        $project = script:New-CaseRoot -CaseName 'pass-1'
        $briefPath = Join-Path $project 'log/brief/BRIEF.md'
        script:Write-Utf8NoBomFile -Path $briefPath -Content (script:Get-FilledBriefBody)

        $r = script:Invoke-BriefStatus -ProjectRoot $project
        $r.ExitCode | Should -Be 0 -Because $r.Output
        $r.Output | Should -Match 'brief-status: PASS '
        $r.Output | Should -Match 'brief-status: brief-check: brief-check: PASS '
        $r.Output | Should -Match 'brief-status: summary \(Korean labels\)'
        $r.Output | Should -Match 'brief-status: 현재 상태:'
        $r.Output | Should -Match 'brief-status: 마지막 완료 action:'
        $r.Output | Should -Match 'brief-status: 현재 scope:'
        $r.Output | Should -Match 'brief-status: 다음 단일 action:'
        $r.Output | Should -Match 'brief-status: Do not do:'
        $r.Output | Should -Match 'brief-status: 먼저 읽을 파일:'
        $r.Output | Should -Match 'brief-status: Open risks:'
        $r.Output | Should -Match 'brief-status: Pending user decision:'
        $r.Output | Should -Match 'brief-status: 현재 상태: project is at phase 0; baseline 6916f55 on main\.'
        $r.Output | Should -Match 'brief-status: 다음 단일 action: land brief-status helper\.'
    }
}

Describe 'brief-status missing-file' {
    It 'AC-BS-MISSING-1: missing BRIEF.md exits non-zero with diagnostic' {
        $project = script:New-CaseRoot -CaseName 'missing-1'
        $briefPath = Join-Path $project 'log/brief/BRIEF.md'
        Test-Path -LiteralPath $briefPath | Should -BeFalse

        $r = script:Invoke-BriefStatus -ProjectRoot $project
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'BRIEF.md not found'
        $r.Output | Should -Not -Match 'brief-status: PASS '
    }
}

Describe 'brief-status containment' {
    It 'AC-BS-CONTAINMENT-1: -BriefPath outside ProjectRoot is refused' {
        $project = script:New-CaseRoot -CaseName 'containment-1'
        $outsidePath = Join-Path $TestDrive ('pester-brief-status-outside-' + ([guid]::NewGuid().ToString('N')) + '.md')
        script:Write-Utf8NoBomFile -Path $outsidePath -Content (script:Get-FilledBriefBody)

        $r = script:Invoke-BriefStatus -ProjectRoot $project -BriefPath $outsidePath
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'outside ProjectRoot'
        $r.Output | Should -Not -Match 'brief-status: PASS '
    }
}

Describe 'brief-status delegates shape FAIL' {
    It 'AC-BS-SHAPE-FAIL-1: sentinel left in BRIEF surfaces brief-check failure and shape FAIL summary' {
        $project = script:New-CaseRoot -CaseName 'shape-fail-1'
        $briefPath = Join-Path $project 'log/brief/BRIEF.md'
        script:Write-Utf8NoBomFile -Path $briefPath -Content (script:Get-SentinelLeftBriefBody)

        $r = script:Invoke-BriefStatus -ProjectRoot $project
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'brief-status: brief-check: brief-check: FAIL'
        $r.Output | Should -Match 'sentinel remains'
        $r.Output | Should -Match 'brief-status: FAIL shape validation'
        $r.Output | Should -Not -Match 'brief-status: PASS '
        $r.Output | Should -Not -Match 'brief-status: summary'
    }
}

Describe 'brief-status body-line extraction' {
    It 'AC-BS-FIRST-NONEMPTY-1: skips leading blank lines under heading' {
        $project = script:New-CaseRoot -CaseName 'first-nonempty-1'
        $briefPath = Join-Path $project 'log/brief/BRIEF.md'
        script:Write-Utf8NoBomFile -Path $briefPath -Content (script:Get-BlankPrefixBriefBody)

        $r = script:Invoke-BriefStatus -ProjectRoot $project
        $r.ExitCode | Should -Be 0 -Because $r.Output
        $r.Output | Should -Match 'brief-status: 현재 상태: project is at phase 1 with leading blanks\.'
    }
}

Describe 'brief-status no verdict vocabulary' {
    It 'AC-BS-NO-VERDICT-1: does not emit reviewer verdict vocabulary on its own status lines' {
        $project = script:New-CaseRoot -CaseName 'no-verdict-1'
        $briefPath = Join-Path $project 'log/brief/BRIEF.md'
        script:Write-Utf8NoBomFile -Path $briefPath -Content (script:Get-FilledBriefBody)

        $r = script:Invoke-BriefStatus -ProjectRoot $project
        $r.ExitCode | Should -Be 0 -Because $r.Output

        $statusLines = @(($r.Output -split "`n") | Where-Object {
            $_ -match '^brief-status:\s' -and $_ -notmatch '^brief-status:\s+brief-check:'
        })

        ($statusLines | Where-Object { $_ -match '(?i)^brief-status:\s+yes\b' }).Count | Should -Be 0
        ($statusLines | Where-Object { $_ -match '(?i)^brief-status:\s+no\b' }).Count | Should -Be 0
        ($statusLines | Where-Object { $_ -match '(?i)^brief-status:\s+yes with risk\b' }).Count | Should -Be 0
        ($statusLines | Where-Object { $_ -match '(?i)^brief-status:\s+verdict\b' }).Count | Should -Be 0
    }
}
