Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

BeforeAll {
    $script:RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).ProviderPath
    $script:BriefInitScript = Join-Path $script:RepoRoot 'scripts/brief-init.ps1'
    $script:RealTemplatePath = Join-Path $script:RepoRoot 'templates/brief/BRIEF.md'

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

    function script:Read-Utf8NoBomFile {
        param([string] $Path)
        $resolved = (Resolve-Path -LiteralPath $Path).ProviderPath
        $encoding = New-Object System.Text.UTF8Encoding($false)
        return [System.IO.File]::ReadAllText($resolved, $encoding)
    }

    function script:New-CaseRoot {
        param([string] $CaseName)
        $caseRoot = Join-Path $TestDrive ('pester-brief-init-' + $CaseName)
        if (Test-Path -LiteralPath $caseRoot) {
            Remove-Item -LiteralPath $caseRoot -Recurse -Force
        }
        $null = New-Item -ItemType Directory -Path $caseRoot -Force
        return ([System.IO.Path]::GetFullPath($caseRoot))
    }

    function script:New-FakeToolRoot {
        param(
            [string] $CaseName,
            [string] $TemplateContent
        )
        $toolRoot = Join-Path $TestDrive ('pester-brief-init-tool-' + $CaseName)
        if (Test-Path -LiteralPath $toolRoot) {
            Remove-Item -LiteralPath $toolRoot -Recurse -Force
        }
        $null = New-Item -ItemType Directory -Path $toolRoot -Force
        if (-not [string]::IsNullOrEmpty($TemplateContent)) {
            $tmpl = Join-Path $toolRoot 'templates/brief/BRIEF.md'
            script:Write-Utf8NoBomFile -Path $tmpl -Content $TemplateContent
        }
        return ([System.IO.Path]::GetFullPath($toolRoot))
    }

    function script:New-FakeSourceRepo {
        param([string] $CaseName)
        $srcRoot = Join-Path $TestDrive ('pester-brief-init-src-' + $CaseName)
        if (Test-Path -LiteralPath $srcRoot) {
            Remove-Item -LiteralPath $srcRoot -Recurse -Force
        }
        $null = New-Item -ItemType Directory -Path $srcRoot -Force
        $marker = Join-Path $srcRoot 'scripts/verify-ps1.ps1'
        script:Write-Utf8NoBomFile -Path $marker -Content "# fake marker for Test-IsSourceRepoRoot`n"
        $tmpl = Join-Path $srcRoot 'templates/brief/BRIEF.md'
        script:Write-Utf8NoBomFile -Path $tmpl -Content "# fake brief template`n"
        return ([System.IO.Path]::GetFullPath($srcRoot))
    }

    function script:Invoke-BriefInit {
        param(
            [string] $ProjectRoot,
            [string] $ToolRoot,
            [switch] $AllowSourceRepoSeed
        )
        $procArgs = @(
            '-NoProfile',
            '-ExecutionPolicy', 'Bypass',
            '-File', $script:BriefInitScript,
            '-ProjectRoot', $ProjectRoot
        )
        if (-not [string]::IsNullOrEmpty($ToolRoot)) {
            $procArgs += @('-ToolRoot', $ToolRoot)
        }
        if ($AllowSourceRepoSeed) {
            $procArgs += @('-AllowSourceRepoSeed')
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

Describe 'brief-init happy path' {
    It 'AC-BI-HAPPY-1: seeds <project>/brief/BRIEF.md from real template and exits 0' {
        $project = script:New-CaseRoot -CaseName 'happy-1'

        $result = script:Invoke-BriefInit -ProjectRoot $project -ToolRoot $script:RepoRoot
        $result.ExitCode | Should -Be 0 -Because $result.Output

        $briefPath = Join-Path $project 'brief/BRIEF.md'
        Test-Path -LiteralPath $briefPath -PathType Leaf | Should -BeTrue

        $expected = script:Read-Utf8NoBomFile -Path $script:RealTemplatePath
        $actual   = script:Read-Utf8NoBomFile -Path $briefPath
        $actual | Should -Be $expected

        $bytes = [System.IO.File]::ReadAllBytes($briefPath)
        ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) | Should -BeFalse

        $result.Output | Should -Match 'brief-init: PASS'

        $logBrief = Join-Path $project 'log/brief'
        Test-Path -LiteralPath $logBrief | Should -BeFalse
    }

    It 'AC-BI-HAPPY-2: creates <project>/brief/ directory when missing' {
        $project = script:New-CaseRoot -CaseName 'happy-2'
        $briefDir = Join-Path $project 'brief'
        Test-Path -LiteralPath $briefDir | Should -BeFalse

        $result = script:Invoke-BriefInit -ProjectRoot $project -ToolRoot $script:RepoRoot
        $result.ExitCode | Should -Be 0 -Because $result.Output

        Test-Path -LiteralPath $briefDir -PathType Container | Should -BeTrue
    }
}

Describe 'brief-init refuse-overwrite' {
    It 'AC-BI-REFUSE-OVERWRITE-1: pre-existing BRIEF.md is not overwritten and exit is non-zero' {
        $project = script:New-CaseRoot -CaseName 'refuse-1'
        $briefDir = Join-Path $project 'brief'
        $null = New-Item -ItemType Directory -Path $briefDir -Force

        $sentinelContent = "# sentinel BRIEF`nuser-authored content that must survive.`n"
        $briefPath = Join-Path $briefDir 'BRIEF.md'
        script:Write-Utf8NoBomFile -Path $briefPath -Content $sentinelContent

        $result = script:Invoke-BriefInit -ProjectRoot $project -ToolRoot $script:RepoRoot
        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match 'already exists'

        $afterContent = script:Read-Utf8NoBomFile -Path $briefPath
        $afterContent | Should -Be $sentinelContent
    }
}

Describe 'brief-init source-repo guard' {
    It 'AC-BI-GUARD-1: ProjectRoot that looks like the source repo is refused without -AllowSourceRepoSeed' {
        $srcRoot = script:New-FakeSourceRepo -CaseName 'guard-1'

        $result = script:Invoke-BriefInit -ProjectRoot $srcRoot -ToolRoot $srcRoot
        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match 'source repo'

        $briefDir = Join-Path $srcRoot 'brief'
        Test-Path -LiteralPath $briefDir | Should -BeFalse
    }

    It 'AC-BI-GUARD-2: -AllowSourceRepoSeed lets a source-repo-shaped ProjectRoot proceed' {
        $srcRoot = script:New-FakeSourceRepo -CaseName 'guard-2'

        $result = script:Invoke-BriefInit -ProjectRoot $srcRoot -ToolRoot $srcRoot -AllowSourceRepoSeed
        $result.ExitCode | Should -Be 0 -Because $result.Output

        $briefPath = Join-Path $srcRoot 'brief/BRIEF.md'
        Test-Path -LiteralPath $briefPath -PathType Leaf | Should -BeTrue
    }
}

Describe 'brief-init missing template' {
    It 'AC-BI-MISSING-TEMPLATE-1: ToolRoot without templates/brief/BRIEF.md fails with diagnostic' {
        $project  = script:New-CaseRoot -CaseName 'missing-1'
        $toolRoot = script:New-FakeToolRoot -CaseName 'missing-1' -TemplateContent ''

        $result = script:Invoke-BriefInit -ProjectRoot $project -ToolRoot $toolRoot
        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match 'template not found'

        $briefDir = Join-Path $project 'brief'
        Test-Path -LiteralPath $briefDir | Should -BeFalse
    }
}
