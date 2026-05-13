Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

BeforeAll {
    $script:RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).ProviderPath
    $script:RealVerifyScript = Join-Path $script:RepoRoot 'scripts/verify-ps1.ps1'
    $script:RealLibPath      = Join-Path $script:RepoRoot 'scripts/lib/path.ps1'
    $script:RealLibGit       = Join-Path $script:RepoRoot 'scripts/lib/git.ps1'

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

    function script:New-VerifyCase {
        param([string] $CaseName)
        $caseRoot = Join-Path $TestDrive ('pester-verify-ps1-' + $CaseName)
        if (Test-Path -LiteralPath $caseRoot) {
            Remove-Item -LiteralPath $caseRoot -Recurse -Force
        }
        $null = New-Item -ItemType Directory -Path $caseRoot -Force
        return ([System.IO.Path]::GetFullPath($caseRoot))
    }

    function script:Initialize-FakeSourceRepoForVerify {
        param(
            [string] $CaseName,
            [switch] $OmitMarkers
        )
        $repo = script:New-VerifyCase -CaseName $CaseName

        # Copy the script under test plus its lib dependencies into <repo>/scripts/.
        $scriptsTarget = Join-Path $repo 'scripts'
        $null = New-Item -ItemType Directory -Path $scriptsTarget -Force
        $null = New-Item -ItemType Directory -Path (Join-Path $scriptsTarget 'lib') -Force

        Copy-Item -LiteralPath $script:RealVerifyScript -Destination (Join-Path $scriptsTarget 'verify-ps1.ps1') -Force
        Copy-Item -LiteralPath $script:RealLibPath      -Destination (Join-Path $scriptsTarget 'lib/path.ps1') -Force
        Copy-Item -LiteralPath $script:RealLibGit       -Destination (Join-Path $scriptsTarget 'lib/git.ps1') -Force

        if (-not $OmitMarkers) {
            # The other two dogfooding markers required by Test-IsSourceRepoRoot.
            script:Write-Utf8NoBomFile -Path (Join-Path $repo 'templates/review-input.md') -Content "# fake review-input`n"
            script:Write-Utf8NoBomFile -Path (Join-Path $repo 'config/reviewer.json')      -Content "{}`n"
        }

        # Initialize a git repo so `git ls-files` works.
        $null = & git -C $repo init --quiet 2>&1
        $null = & git -C $repo config user.email 'pester@local' 2>&1
        $null = & git -C $repo config user.name 'pester' 2>&1

        return $repo
    }

    function script:Add-TrackedLogFile {
        param(
            [string] $Repo,
            [string] $RelativePath,
            [string] $Content = "log artifact body`n"
        )
        $abs = Join-Path $Repo $RelativePath
        script:Write-Utf8NoBomFile -Path $abs -Content $Content
        $null = & git -C $Repo add -- $RelativePath 2>&1
    }

    function script:Invoke-VerifyPs1Copy {
        param([string] $Repo)
        $copyPath = Join-Path $Repo 'scripts/verify-ps1.ps1'
        $procArgs = @(
            '-NoProfile', '-ExecutionPolicy', 'Bypass',
            '-File', $copyPath
        )
        $combined = & powershell.exe @procArgs 2>&1
        $exitCode = $LASTEXITCODE
        $text = ($combined | ForEach-Object { [string]$_ }) -join "`n"
        return [pscustomobject]@{
            ExitCode = $exitCode
            Output   = $text
        }
    }
}

Describe 'verify-ps1 D8 self-target enforcement' {
    It 'AC-VPS1-D8-CLEAN-SOURCE-PASS: source repo with no tracked log/ files passes' {
        $repo = script:Initialize-FakeSourceRepoForVerify -CaseName 'clean-source'

        $r = script:Invoke-VerifyPs1Copy -Repo $repo
        $r.ExitCode | Should -Be 0 -Because $r.Output
        $r.Output | Should -Match 'verify-ps1: PASS'
        $r.Output | Should -Not -Match 'D8 self-target enforcement'
    }

    It 'AC-VPS1-D8-TRACKED-LOG-FAIL: source repo with tracked log/ file fails and lists it' {
        $repo = script:Initialize-FakeSourceRepoForVerify -CaseName 'tracked-log'
        script:Add-TrackedLogFile -Repo $repo -RelativePath 'log/leaked.txt'

        $r = script:Invoke-VerifyPs1Copy -Repo $repo
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'FAIL D8 self-target enforcement'
        $r.Output | Should -Match 'git-tracked file\(s\) found under log/ in source repo'
        $r.Output | Should -Match 'log/leaked\.txt'
    }

    It 'AC-VPS1-D8-MULTIPLE-FAIL: multiple tracked log/ files are all listed' {
        $repo = script:Initialize-FakeSourceRepoForVerify -CaseName 'multiple-tracked'
        script:Add-TrackedLogFile -Repo $repo -RelativePath 'log/a.txt'
        script:Add-TrackedLogFile -Repo $repo -RelativePath 'log/sub/b.txt'

        $r = script:Invoke-VerifyPs1Copy -Repo $repo
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'FAIL D8 self-target enforcement'
        $r.Output | Should -Match 'log/a\.txt'
        $r.Output | Should -Match 'log/sub/b\.txt'
    }

    It 'AC-VPS1-D8-TARGET-SKIP: non-source/target context skips D8 even with tracked log/' {
        # Omit the templates/ and config/ markers so Test-IsSourceRepoRoot returns false.
        $repo = script:Initialize-FakeSourceRepoForVerify -CaseName 'target-skip' -OmitMarkers
        script:Add-TrackedLogFile -Repo $repo -RelativePath 'log/legit.txt'

        $r = script:Invoke-VerifyPs1Copy -Repo $repo
        $r.ExitCode | Should -Be 0 -Because $r.Output
        $r.Output | Should -Match 'verify-ps1: PASS'
        $r.Output | Should -Not -Match 'FAIL D8 self-target enforcement'
    }
}
