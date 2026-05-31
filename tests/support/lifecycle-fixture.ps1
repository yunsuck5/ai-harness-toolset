Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Shared fixture helpers for the IU-B-09 lifecycle entrypoint integration tests
# (install-global.Tests.ps1 / update-global.Tests.ps1). Dot-sourced from each test's BeforeAll, so
# these functions land in the test's script scope.
#
# Everything here writes ONLY under the caller-supplied TestDrive base — no real %USERPROFILE%\.claude
# or %USERPROFILE%\.codex is ever touched (the entrypoints are always invoked with overridden
# -InstallArea / -ClaudeHome / -CodexHome pointing into TestDrive).

$script:LifecycleBeginMarker = '<!-- BEGIN AI_HARNESS_TOOLSET_GLOBAL -->'
$script:LifecycleEndMarker   = '<!-- END AI_HARNESS_TOOLSET_GLOBAL -->'

function New-LifecycleFixtureSource {
    # Build a minimal but COMPLETE ai-harness source repo (git-committed) carrying everything the
    # fresh-install + activation bootstrap needs: D3 source-repo markers, two managed-block snippets,
    # and the review-skill mirror source. Returns the absolute source root path.
    param(
        [Parameter(Mandatory = $true)] [string] $TestDriveRoot,
        [Parameter(Mandatory = $true)] [string] $CaseName
    )
    $root = Join-Path $TestDriveRoot ('lifecycle-src-' + $CaseName)
    if (Test-Path -LiteralPath $root) { Remove-Item -LiteralPath $root -Recurse -Force }
    $null = New-Item -ItemType Directory -Path $root -Force
    $utf8 = New-Object System.Text.UTF8Encoding($false)

    foreach ($r in 'config', 'scripts', 'snippets', 'templates') {
        $null = New-Item -ItemType Directory -Path (Join-Path $root $r) -Force
    }
    # D3 source-repo multi-marker (required by the install pipeline dispatcher).
    [System.IO.File]::WriteAllText((Join-Path $root 'scripts/verify-ps1.ps1'),    '# marker', $utf8)
    [System.IO.File]::WriteAllText((Join-Path $root 'templates/review-input.md'), '# marker', $utf8)
    [System.IO.File]::WriteAllText((Join-Path $root 'config/reviewer.json'),      '{}',       $utf8)

    # Activation sources (each a valid single managed-block pair) + the skill mirror source.
    $b = $script:LifecycleBeginMarker
    $e = $script:LifecycleEndMarker
    [System.IO.File]::WriteAllText((Join-Path $root 'snippets/CLAUDE_SNIPPET.md'), "$b`n# CLAUDE payload`nclaude body line`n$e`n", $utf8)
    [System.IO.File]::WriteAllText((Join-Path $root 'snippets/AGENTS_SNIPPET.md'), "$b`n# AGENTS payload`ncodex body line`n$e`n", $utf8)
    $skillDir = Join-Path $root 'snippets/claude-skills/ai-harness-review'
    $null = New-Item -ItemType Directory -Path $skillDir -Force
    [System.IO.File]::WriteAllText((Join-Path $skillDir 'SKILL.md'), "# ai-harness-review skill`nmirror body`n", $utf8)

    Push-Location $root
    try {
        & git init -q 2>&1 | Out-Null
        & git symbolic-ref HEAD refs/heads/main 2>&1 | Out-Null
        & git config core.autocrlf false 2>&1 | Out-Null
        & git config core.safecrlf false 2>&1 | Out-Null
        & git config user.email 'lifecycle-test@example.com' 2>&1 | Out-Null
        & git config user.name  'lifecycle-test' 2>&1 | Out-Null
        & git add . 2>&1 | Out-Null
        & git commit -q -m 'seed lifecycle fixture' 2>&1 | Out-Null
    }
    finally { Pop-Location }
    return ([System.IO.Path]::GetFullPath($root))
}

function New-LifecycleHomes {
    # Allocate isolated TestDrive Claude/Codex homes + the install area path (NOT created — fresh
    # install creates it). Returns Base / Claude / Codex / Area.
    param(
        [Parameter(Mandatory = $true)] [string] $TestDriveRoot,
        [Parameter(Mandatory = $true)] [string] $CaseName
    )
    $base   = Join-Path $TestDriveRoot ('lifecycle-homes-' + $CaseName)
    if (Test-Path -LiteralPath $base) { Remove-Item -LiteralPath $base -Recurse -Force }
    $claude = Join-Path $base '.claude'
    $codex  = Join-Path $base '.codex'
    $null = New-Item -ItemType Directory -Path $claude -Force
    $null = New-Item -ItemType Directory -Path $codex -Force
    return [pscustomobject]@{
        Base   = ([System.IO.Path]::GetFullPath($base))
        Claude = ([System.IO.Path]::GetFullPath($claude))
        Codex  = ([System.IO.Path]::GetFullPath($codex))
        Area   = ([System.IO.Path]::GetFullPath((Join-Path $claude 'ai-harness-toolset')))
    }
}

function Invoke-LifecycleScript {
    # Invoke a lifecycle entrypoint (install-global.ps1 / update-global.ps1) as a child process and
    # return its exit code + merged (stdout+stderr) text. Booleans/switches in -Params are emitted as
    # flags only when true.
    param(
        [Parameter(Mandatory = $true)] [string] $ScriptPath,
        [Parameter(Mandatory = $true)] [hashtable] $Params
    )
    $procArgs = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $ScriptPath)
    foreach ($k in $Params.Keys) {
        $v = $Params[$k]
        if ($null -eq $v) { continue }
        if ($v -is [bool] -or $v -is [System.Management.Automation.SwitchParameter]) {
            if ([bool]$v) { $procArgs += ('-' + $k) }
        }
        else {
            $procArgs += @(('-' + $k), [string]$v)
        }
    }
    $proc = Invoke-NativeProcess -Executable 'powershell.exe' -Arguments $procArgs
    $text = (($proc.Stdout + $proc.Stderr) -replace "`r`n", "`n").TrimEnd("`n")
    return [pscustomobject]@{ ExitCode = $proc.ExitCode; Output = $text }
}
