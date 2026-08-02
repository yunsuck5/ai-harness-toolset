Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Focused integration suite for scripts/update-global.ps1 (IU-B-09 lifecycle entrypoint split).
# update-global is a THIN existing-install wrapper over install-update.ps1 -Mode update-source; these
# tests assert the fail-fast guidance for a missing/invalid install and that a valid install delegates.
# Every path runs against TestDrive homes/areas — no real %USERPROFILE% is touched.

BeforeAll {
    $script:RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).ProviderPath
    . (Join-Path $script:RepoRoot 'scripts/lib/native-process.ps1')
    . (Join-Path $script:RepoRoot 'scripts/lib/encoding.ps1')
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

    function script:New-UpdateWrapperStub {
        param(
            [Parameter(Mandatory = $true)] [string] $CaseName,
            [Parameter(Mandatory = $true)] [string] $DelegateStdout,
            [string] $DelegateStderr = '',
            [int] $DelegateExitCode = 1
        )

        $root = Join-Path $TestDrive ('update-wrapper-stub-' + $CaseName)
        $scriptsDir = Join-Path $root 'scripts'
        $libDir = Join-Path $scriptsDir 'lib'
        $null = New-Item -ItemType Directory -Path $libDir -Force
        Copy-Item -LiteralPath $script:UpdateGlobal -Destination (Join-Path $scriptsDir 'update-global.ps1')
        foreach ($name in @('encoding.ps1', 'path.ps1', 'install-pipeline-core.ps1', 'native-process.ps1')) {
            Copy-Item -LiteralPath (Join-Path $script:RepoRoot ('scripts/lib/' + $name)) -Destination (Join-Path $libDir $name)
        }

        $stdout64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($DelegateStdout))
        $stderr64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($DelegateStderr))
        $stubLines = @(
            '[CmdletBinding()]'
            'param('
            '    [string] $Mode, [string] $InstallArea, [string] $SourcePath, [string] $RepoUrl,'
            '    [string] $Branch, [string] $Remote, [string] $Ref, [string] $ClaudeHome,'
            '    [string] $CodexHome, [switch] $SkipSmoke, [switch] $ConfirmInteractive, [switch] $Json'
            ')'
            ('$stdout = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String(''' + $stdout64 + '''))')
            ('$stderr = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String(''' + $stderr64 + '''))')
            'if (-not [string]::IsNullOrEmpty($stdout)) { [Console]::Out.Write($stdout) }'
            'if (-not [string]::IsNullOrEmpty($stderr)) { [Console]::Error.Write($stderr) }'
            ('exit ' + $DelegateExitCode)
        )
        Write-Utf8BomCrlf -Path (Join-Path $scriptsDir 'install-update.ps1') -Content ($stubLines -join "`r`n")
        return (Join-Path $scriptsDir 'update-global.ps1')
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

    It 'AC-UG-6: delegate activation_pending remains wrapper INCOMPLETE rather than FAIL' {
        $src = New-LifecycleFixtureSource -TestDriveRoot $TestDrive -CaseName 'ug-pending'
        $h   = New-LifecycleHomes -TestDriveRoot $TestDrive -CaseName 'ug-pending'
        $ri = script:Install -Params @{ InstallArea = $h.Area; SourcePath = $src; ClaudeHome = $h.Claude; CodexHome = $h.Codex; SkipSmoke = $true }
        $ri.ExitCode | Should -Be 0
        [System.IO.File]::WriteAllText(
            (Join-Path $h.Claude 'skills/ai-harness-review/SKILL.md'),
            "# DRIFTED`n",
            (New-Object System.Text.UTF8Encoding($false)))

        $r = script:Update -Params @{ InstallArea = $h.Area; SourcePath = $src; ClaudeHome = $h.Claude; CodexHome = $h.Codex; SkipSmoke = $true }
        $r.ExitCode | Should -Be 1
        $r.Output | Should -Match 'update-global: updateStatus=activation_pending'
        $r.Output | Should -Match 'update-global: INCOMPLETE \(payload OK; activation follow-up required\)'
        $r.Output | Should -Not -Match 'update-global: FAIL'
    }

    It 'AC-UG-7: -Json keeps stdout as delegate JSON only and sends wrapper prose to stderr' {
        $src = New-LifecycleFixtureSource -TestDriveRoot $TestDrive -CaseName 'ug-json'
        $h   = New-LifecycleHomes -TestDriveRoot $TestDrive -CaseName 'ug-json'
        $ri = script:Install -Params @{ InstallArea = $h.Area; SourcePath = $src; ClaudeHome = $h.Claude; CodexHome = $h.Codex; SkipSmoke = $true }
        $ri.ExitCode | Should -Be 0

        $proc = Invoke-NativeProcess -Executable 'powershell.exe' -Arguments @(
            '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $script:UpdateGlobal,
            '-InstallArea', $h.Area, '-SourcePath', $src,
            '-ClaudeHome', $h.Claude, '-CodexHome', $h.Codex,
            '-SkipSmoke', '-Json')
        $proc.ExitCode | Should -Be 0
        { $proc.Stdout | ConvertFrom-Json -ErrorAction Stop } | Should -Not -Throw
        $json = $proc.Stdout | ConvertFrom-Json
        $json.status | Should -Be 'noop_already_current'
        $proc.Stdout | Should -Not -Match 'update-global:'
        $proc.Stderr | Should -Match 'update-global: mode=UPDATE'
        $proc.Stderr | Should -Match 'update-global: updateStatus=delegated_ok'
    }

    It 'AC-UG-8: -Json activation_pending preserves delegate JSON and wrapper INCOMPLETE' {
        $src = New-LifecycleFixtureSource -TestDriveRoot $TestDrive -CaseName 'ug-json-pending'
        $h   = New-LifecycleHomes -TestDriveRoot $TestDrive -CaseName 'ug-json-pending'
        $ri = script:Install -Params @{ InstallArea = $h.Area; SourcePath = $src; ClaudeHome = $h.Claude; CodexHome = $h.Codex; SkipSmoke = $true }
        $ri.ExitCode | Should -Be 0
        [System.IO.File]::WriteAllText(
            (Join-Path $h.Codex 'skills/ai-harness-review/SKILL.md'),
            "# DRIFTED`n",
            (New-Object System.Text.UTF8Encoding($false)))

        $proc = Invoke-NativeProcess -Executable 'powershell.exe' -Arguments @(
            '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $script:UpdateGlobal,
            '-InstallArea', $h.Area, '-SourcePath', $src,
            '-ClaudeHome', $h.Claude, '-CodexHome', $h.Codex,
            '-SkipSmoke', '-Json')
        $proc.ExitCode | Should -Be 1
        { $proc.Stdout | ConvertFrom-Json -ErrorAction Stop } | Should -Not -Throw
        ($proc.Stdout | ConvertFrom-Json).status | Should -Be 'activation_pending'
        $proc.Stdout | Should -Not -Match 'update-global:'
        $proc.Stderr | Should -Match 'update-global: updateStatus=activation_pending'
        $proc.Stderr | Should -Match 'update-global: INCOMPLETE'
        $proc.Stderr | Should -Not -Match 'update-global: FAIL'
    }

    It 'AC-UG-9: classified general nonzero keeps JSON stdout and reports wrapper FAIL' {
        $src = New-LifecycleFixtureSource -TestDriveRoot $TestDrive -CaseName 'ug-json-nonzero'
        $h   = New-LifecycleHomes -TestDriveRoot $TestDrive -CaseName 'ug-json-nonzero'
        $ri = script:Install -Params @{ InstallArea = $h.Area; SourcePath = $src; ClaudeHome = $h.Claude; CodexHome = $h.Codex; SkipSmoke = $true }
        $ri.ExitCode | Should -Be 0
        $delegateJson = '{"status":"verify_failed","exitCode":1}'
        $wrapper = script:New-UpdateWrapperStub -CaseName 'general-nonzero' -DelegateStdout $delegateJson -DelegateStderr 'delegate failure detail' -DelegateExitCode 1

        $proc = Invoke-NativeProcess -Executable 'powershell.exe' -Arguments @(
            '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $wrapper,
            '-InstallArea', $h.Area, '-ClaudeHome', $h.Claude, '-CodexHome', $h.Codex,
            '-SkipSmoke', '-Json')
        $proc.ExitCode | Should -Be 1
        ($proc.Stdout | ConvertFrom-Json).status | Should -Be 'verify_failed'
        $proc.Stdout | Should -Not -Match 'update-global:'
        $proc.Stderr | Should -Match 'delegate failure detail'
        $proc.Stderr | Should -Match 'update-global: updateStatus=delegated_nonzero'
        $proc.Stderr | Should -Match 'update-global: FAIL'
    }

    It 'AC-UG-10: malformed delegate stdout is quarantined from -Json stdout before FAIL' {
        $src = New-LifecycleFixtureSource -TestDriveRoot $TestDrive -CaseName 'ug-json-malformed'
        $h   = New-LifecycleHomes -TestDriveRoot $TestDrive -CaseName 'ug-json-malformed'
        $ri = script:Install -Params @{ InstallArea = $h.Area; SourcePath = $src; ClaudeHome = $h.Claude; CodexHome = $h.Codex; SkipSmoke = $true }
        $ri.ExitCode | Should -Be 0
        $wrapper = script:New-UpdateWrapperStub -CaseName 'malformed' -DelegateStdout 'not-json' -DelegateStderr 'delegate stderr retained' -DelegateExitCode 1

        $proc = Invoke-NativeProcess -Executable 'powershell.exe' -Arguments @(
            '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $wrapper,
            '-InstallArea', $h.Area, '-ClaudeHome', $h.Claude, '-CodexHome', $h.Codex,
            '-SkipSmoke', '-Json')
        $proc.ExitCode | Should -Be 1
        [string]::IsNullOrEmpty($proc.Stdout) | Should -BeTrue
        $proc.Stderr | Should -Match 'delegate stderr retained'
        $proc.Stderr | Should -Match 'not-json'
        $proc.Stderr | Should -Match 'update-global: updateStatus=delegate_result_unavailable'
        $proc.Stderr | Should -Match 'update-global: FAIL'
    }

    It 'AC-UG-11: human status markers are recognized only as exact standalone lines' {
        $src = New-LifecycleFixtureSource -TestDriveRoot $TestDrive -CaseName 'ug-human-marker-substring'
        $h   = New-LifecycleHomes -TestDriveRoot $TestDrive -CaseName 'ug-human-marker-substring'
        $ri = script:Install -Params @{ InstallArea = $h.Area; SourcePath = $src; ClaudeHome = $h.Claude; CodexHome = $h.Codex; SkipSmoke = $true }
        $ri.ExitCode | Should -Be 0
        $delegateHuman = @(
            'install-update: reason=prefix--- BEGIN JSON ---suffix and prefix--- END JSON ---suffix'
            '--- BEGIN JSON ---'
            '{"status":"activation_pending","exitCode":1}'
            '--- END JSON ---'
        ) -join "`r`n"
        $wrapper = script:New-UpdateWrapperStub -CaseName 'human-marker-substring' -DelegateStdout $delegateHuman -DelegateExitCode 1

        $proc = Invoke-NativeProcess -Executable 'powershell.exe' -Arguments @(
            '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $wrapper,
            '-InstallArea', $h.Area, '-ClaudeHome', $h.Claude, '-CodexHome', $h.Codex,
            '-SkipSmoke')
        $proc.ExitCode | Should -Be 1
        $proc.Stdout | Should -Match 'prefix--- BEGIN JSON ---suffix'
        $proc.Stdout | Should -Match 'update-global: updateStatus=activation_pending'
        $proc.Stdout | Should -Match 'update-global: INCOMPLETE'
        $proc.Stdout | Should -Not -Match 'update-global: FAIL'
    }
}
