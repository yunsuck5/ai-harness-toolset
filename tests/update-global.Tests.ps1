Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Focused integration suite for scripts/update-global.ps1 (IU-B-09 lifecycle entrypoint split).
# update-global is a THIN existing-install wrapper over install-update.ps1 -Mode update-source; these
# tests assert the fail-fast guidance for a missing/invalid install and that a valid install delegates.
# Every path runs against TestDrive homes/areas — no real %USERPROFILE% is touched.

BeforeAll {
    $script:RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).ProviderPath
    . (Join-Path $script:RepoRoot 'scripts/lib/native-process.ps1')
    . (Join-Path $script:RepoRoot 'tests/support/lifecycle-fixture.ps1')
    $script:InstallGlobal = Join-Path $script:RepoRoot 'scripts/install-global.ps1'
    $script:UpdateGlobal  = Join-Path $script:RepoRoot 'scripts/update-global.ps1'

    function script:Update {
        param([hashtable] $Params)
        return Invoke-LifecycleScript -ScriptPath $script:UpdateGlobal -Params $Params
    }
    function script:Install {
        param([hashtable] $Params)
        return Invoke-LifecycleScript -ScriptPath $script:InstallGlobal -Params $Params
    }
}

Describe 'update-global.ps1 (IU-B-09)' {

    It 'AC-UG-1: missing install area -> fail-fast pointing to install-global; no mutation' {
        $h = New-LifecycleHomes -TestDriveRoot $TestDrive -CaseName 'ug-missing'
        # Area path under $h.Area does not exist yet.
        $r = script:Update -Params @{ InstallArea = $h.Area; ClaudeHome = $h.Claude; CodexHome = $h.Codex; SkipSmoke = $true }
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'update_failed'
        $r.Output | Should -Match 'install-global.ps1'
        (Test-Path -LiteralPath (Join-Path $h.Area 'install.json')) | Should -BeFalse
    }

    It 'AC-UG-2: area exists but no install.json -> fail-fast pointing to install-global' {
        $h = New-LifecycleHomes -TestDriveRoot $TestDrive -CaseName 'ug-noinstall'
        $null = New-Item -ItemType Directory -Path $h.Area -Force
        $r = script:Update -Params @{ InstallArea = $h.Area; ClaudeHome = $h.Claude; CodexHome = $h.Codex; SkipSmoke = $true }
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'no install.json'
        $r.Output | Should -Match 'install-global.ps1'
    }

    It 'AC-UG-3: invalid install.json (unparseable) -> fail-fast (not silently delegated)' {
        $h = New-LifecycleHomes -TestDriveRoot $TestDrive -CaseName 'ug-invalid'
        $null = New-Item -ItemType Directory -Path $h.Area -Force
        [System.IO.File]::WriteAllText((Join-Path $h.Area 'install.json'), '{ this is not valid json', (New-Object System.Text.UTF8Encoding($false)))
        $r = script:Update -Params @{ InstallArea = $h.Area; ClaudeHome = $h.Claude; CodexHome = $h.Codex; SkipSmoke = $true }
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'update_failed'
        $r.Output | Should -Match 'invalid'
    }

    It 'AC-UG-5: parseable install.json with valid schemaVersion but missing required fields -> clean fail-fast (not a StrictMode crash)' {
        $h = New-LifecycleHomes -TestDriveRoot $TestDrive -CaseName 'ug-missingfields'
        $null = New-Item -ItemType Directory -Path $h.Area -Force
        # Parses fine, schemaVersion matches, but installMode (and every other field) is missing.
        # Without the structural guard this would dereference $md.installMode under StrictMode and crash.
        [System.IO.File]::WriteAllText((Join-Path $h.Area 'install.json'), '{ "schemaVersion": 1 }', (New-Object System.Text.UTF8Encoding($false)))
        $r = script:Update -Params @{ InstallArea = $h.Area; ClaudeHome = $h.Claude; CodexHome = $h.Codex; SkipSmoke = $true }
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'update_failed'
        $r.Output | Should -Match 'invalid \(missing required field'
        $r.Output | Should -Match 'install-global.ps1'
        # It must NOT have reached delegation.
        $r.Output | Should -Not -Match 'delegating to install-update'
    }

    It 'AC-UG-4: valid existing install -> delegates to install-update.ps1 -Mode update-source' {
        $src = New-LifecycleFixtureSource -TestDriveRoot $TestDrive -CaseName 'ug-delegate'
        $h   = New-LifecycleHomes -TestDriveRoot $TestDrive -CaseName 'ug-delegate'
        # Establish a real install first.
        $ri = script:Install -Params @{ InstallArea = $h.Area; SourcePath = $src; ClaudeHome = $h.Claude; CodexHome = $h.Codex; SkipSmoke = $true }
        $ri.ExitCode | Should -Be 0

        # update-global with no new commit -> update-source is a no-op-already-current; delegate exit 0.
        $r = script:Update -Params @{ InstallArea = $h.Area; SourcePath = $src; ClaudeHome = $h.Claude; CodexHome = $h.Codex; SkipSmoke = $true }
        $r.ExitCode | Should -Be 0
        $r.Output | Should -Match 'delegating to install-update.ps1 -Mode update-source'
        $r.Output | Should -Match 'install-update: mode=update-source'
        $r.Output | Should -Match 'delegated_ok'
    }
}
