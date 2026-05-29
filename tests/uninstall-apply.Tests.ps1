Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# IU-B-08 batch 3 — destructive uninstall apply path + temp finalizer trampoline.
# EVERYTHING runs in TestDrive. The real %USERPROFILE%\.claude / %USERPROFILE%\.codex are NEVER
# read-for-write or mutated: every invocation overrides -ClaudeHome / -CodexHome / -InstallArea /
# -FinalizerTempRoot to TestDrive paths. Install-root fixtures are built as
# <TestDrive>\<case>\.claude\ai-harness-toolset so the real <...>\.claude\ai-harness-toolset path
# guard passes against a sandbox path.

BeforeAll {
    $script:RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).ProviderPath
    . (Join-Path $script:RepoRoot 'scripts/lib/native-process.ps1')
    . (Join-Path $script:RepoRoot 'scripts/lib/encoding.ps1')
    . (Join-Path $script:RepoRoot 'scripts/lib/managed-block.ps1')
    . (Join-Path $script:RepoRoot 'scripts/lib/activation-surface.ps1')
    . (Join-Path $script:RepoRoot 'scripts/lib/install-pipeline-core.ps1')
    . (Join-Path $script:RepoRoot 'scripts/lib/uninstall-target.ps1')

    $script:ApplyMB    = Join-Path $script:RepoRoot 'scripts/apply-managed-block.ps1'
    $script:Entry      = Join-Path $script:RepoRoot 'scripts/uninstall-global.ps1'
    $script:Finalizer  = Join-Path $script:RepoRoot 'scripts/uninstall-finalizer.ps1'
    $script:Begin = '<!-- BEGIN AI_HARNESS_TOOLSET_GLOBAL -->'
    $script:End   = '<!-- END AI_HARNESS_TOOLSET_GLOBAL -->'

    function script:Write-File { param([string] $Path, [string] $Content)
        $parent = Split-Path -LiteralPath $Path
        if (-not (Test-Path -LiteralPath $parent -PathType Container)) { $null = New-Item -ItemType Directory -Path $parent -Force }
        [System.IO.File]::WriteAllText([System.IO.Path]::GetFullPath($Path), $Content, (New-Object System.Text.UTF8Encoding($false)))
    }
    function script:New-Dir { param([string] $Path); if (-not (Test-Path -LiteralPath $Path)) { $null = New-Item -ItemType Directory -Path $Path -Force }; return ([System.IO.Path]::GetFullPath($Path)) }
    function script:Write-Marked { param([string] $Path, [int] $Pairs = 1)
        $nl = "`n"; $b = "# user before$nl"
        for ($i = 0; $i -lt $Pairs; $i++) { $b += "$script:Begin${nl}block $i$nl$script:End$nl" }
        $b += "# user after$nl"
        script:Write-File -Path $Path -Content $b
    }
    function script:Write-InstallJson { param([string] $Area, [string] $ManagedBy = 'claude-code')
        $md = [ordered]@{
            schemaVersion = 1; tool = 'ai-harness-toolset'; installMode = 'local-clone'
            repoUrl = ''; sourcePath = 'X:\src'; toolRoot = 'X:\src'; branch = 'main'; remote = 'origin'
            installedHead = ('0' * 40); lastUpdatedHead = ('0' * 40)
            installedAt = '2026-05-28T00:00:00Z'; lastUpdatedAt = '2026-05-28T00:00:00Z'
            targetFootprintPolicy = 'log-only'; managedBy = $ManagedBy
        }
        script:Write-File (Join-Path $Area 'install.json') ($md | ConvertTo-Json)
    }
    function script:New-InstallRoot { param([string] $Area, [string] $ManagedBy = 'claude-code', [switch] $WithSourceCache, [switch] $WithLog)
        $null = script:New-Dir (Join-Path $Area 'current/scripts')
        script:Write-File (Join-Path $Area 'current/scripts/x.ps1') '# payload'
        script:Write-InstallJson -Area $Area -ManagedBy $ManagedBy
        script:Write-File (Join-Path $Area 'payload-manifest.json') '{}'
        script:Write-File (Join-Path $Area 'payload-marker.json') '{}'
        script:Write-File (Join-Path $Area 'README.md') '# landing'
        if ($WithSourceCache) { script:Write-File (Join-Path $Area 'source-cache/clone.txt') 'x' }
        if ($WithLog) { script:Write-File (Join-Path $Area 'log/install-update/run.json') '{}' }
    }

    # Full apply fixture: <case>/.claude/{ai-harness-toolset, CLAUDE.md, skills/...} + <case>/.codex.
    function script:New-ApplyFixture { param([string] $Case)
        $root   = script:New-Dir (Join-Path $TestDrive $Case)
        $claude = script:New-Dir (Join-Path $root '.claude')
        $codex  = script:New-Dir (Join-Path $root '.codex')
        $area   = script:New-Dir (Join-Path $claude 'ai-harness-toolset')
        script:New-InstallRoot -Area $area -WithSourceCache -WithLog
        script:Write-Marked (Join-Path $claude 'CLAUDE.md') 1
        script:Write-Marked (Join-Path $codex 'AGENTS.md') 1
        script:Write-File (Join-Path $claude 'skills/ai-harness-review/SKILL.md') "---`nname: ai-harness-review`n---`n"
        script:Write-File (Join-Path $claude 'skills/other-skill/SKILL.md') "---`nname: other-skill`n---`n"
        $tmp = script:New-Dir (Join-Path $root 'fin-temp')
        return [pscustomobject]@{ Root=$root; Claude=$claude; Codex=$codex; Area=$area; Tmp=$tmp;
            ClaudeMd=(Join-Path $claude 'CLAUDE.md'); CodexMd=(Join-Path $codex 'AGENTS.md');
            Skill=(Join-Path $claude 'skills/ai-harness-review'); Sibling=(Join-Path $claude 'skills/other-skill') }
    }

    function script:Invoke-Apply { param($Fx, [string[]] $Extra = @())
        $args = @('-NoProfile','-ExecutionPolicy','Bypass','-File',$script:Entry,
            '-ClaudeHome',$Fx.Claude,'-CodexHome',$Fx.Codex,'-Apply','-FinalizerTempRoot',$Fx.Tmp) + $Extra
        return Invoke-NativeProcess -Executable 'powershell.exe' -Arguments $args
    }
    function script:Invoke-Remove { param([string] $Target)
        return Invoke-NativeProcess -Executable 'powershell.exe' -Arguments @(
            '-NoProfile','-ExecutionPolicy','Bypass','-File',$script:ApplyMB,'-Remove','-TargetPath',$Target)
    }
    function script:Count-MarkerPairs { param([string] $Path)
        $scan = Find-ManagedBlockMarkers -Segments (@(Split-ManagedBlockLines -Content (Read-Utf8 -Path $Path)))
        return [pscustomobject]@{ Begin=$scan.BeginIndices.Count; End=$scan.EndIndices.Count }
    }
    function script:Wait-Until { param([scriptblock] $Cond, [int] $TimeoutSec = 20)
        $deadline = (Get-Date).AddSeconds($TimeoutSec)
        while ((Get-Date) -lt $deadline) { if (& $Cond) { return $true }; Start-Sleep -Milliseconds 200 }
        return (& $Cond)
    }
    function script:New-DeadPid {
        $p = Start-Process -FilePath 'powershell.exe' -ArgumentList @('-NoProfile','-Command','exit 0') -WindowStyle Hidden -PassThru
        $p.WaitForExit(5000) | Out-Null
        Start-Sleep -Milliseconds 100
        return $p.Id
    }
    function script:Run-Finalizer { param([string] $InstallRoot, [int] $ParentPid, [string] $SelfDir, [string] $ResultPath, [int] $TimeoutSec = 5, [int] $PollMs = 100)
        $inputPath = Join-Path (script:New-Dir $SelfDir) 'finalizer-input.json'
        $obj = [ordered]@{ installRoot=$InstallRoot; parentPid=$ParentPid; expectedEntries=@(Get-UninstallExpectedRootEntries); resultPath=$ResultPath; selfDir=$SelfDir; timeoutSec=$TimeoutSec; pollMs=$PollMs }
        ($obj | ConvertTo-Json -Depth 6) | Out-File -LiteralPath $inputPath -Encoding utf8
        $proc = Invoke-NativeProcess -Executable 'powershell.exe' -Arguments @('-NoProfile','-ExecutionPolicy','Bypass','-File',$script:Finalizer,'-InputPath',$inputPath)
        $res = $null
        if (Test-Path -LiteralPath $ResultPath) { $res = Get-Content -LiteralPath $ResultPath -Raw | ConvertFrom-Json }
        return [pscustomobject]@{ Proc=$proc; Result=$res }
    }
}

Describe 'apply-managed-block.ps1 -Remove' {
    It 'removes the marker span, preserves marker-outside content, leaves 0 pairs' {
        $f = Join-Path (script:New-Dir (Join-Path $TestDrive 'r-ok')) 'CLAUDE.md'
        $nl = "`n"; script:Write-File $f "head$nl$script:Begin${nl}body$nl$script:End${nl}tail$nl"
        $p = script:Invoke-Remove $f
        $p.ExitCode | Should -Be 0
        (Read-Utf8 -Path $f) | Should -Be "head${nl}tail$nl"
        (script:Count-MarkerPairs $f).Begin | Should -Be 0
    }
    It 'keeps an emptied instruction file (never deletes it)' {
        $f = Join-Path (script:New-Dir (Join-Path $TestDrive 'r-empty')) 'CLAUDE.md'
        $nl = "`n"; script:Write-File $f "$script:Begin${nl}only$nl$script:End$nl"
        $p = script:Invoke-Remove $f
        $p.ExitCode | Should -Be 0
        (Test-Path -LiteralPath $f -PathType Leaf) | Should -BeTrue
        (Read-Utf8 -Path $f) | Should -Be ''
    }
    It '0-pair target is an idempotent no-op (exit 0, no .amb-backup)' {
        $f = Join-Path (script:New-Dir (Join-Path $TestDrive 'r-noop')) 'CLAUDE.md'
        script:Write-File $f "no markers`n"
        $p = script:Invoke-Remove $f
        $p.ExitCode | Should -Be 0
        ($p.Stdout) | Should -Match 'no-op'
        (Test-Path -LiteralPath ($f + '.amb-backup')) | Should -BeFalse
    }
    It 'malformed (2 pairs) blocks removal (exit 1, file untouched)' {
        $f = Join-Path (script:New-Dir (Join-Path $TestDrive 'r-bad')) 'CLAUDE.md'
        script:Write-Marked $f 2
        $before = Read-Utf8 -Path $f
        $p = script:Invoke-Remove $f
        $p.ExitCode | Should -Be 1
        (Read-Utf8 -Path $f) | Should -Be $before
        (Test-Path -LiteralPath ($f + '.amb-backup')) | Should -BeFalse
    }
    It 'happy-path removal leaves no .amb-backup' {
        $f = Join-Path (script:New-Dir (Join-Path $TestDrive 'r-bak')) 'CLAUDE.md'
        script:Write-Marked $f 1
        (script:Invoke-Remove $f).ExitCode | Should -Be 0
        (Test-Path -LiteralPath ($f + '.amb-backup')) | Should -BeFalse
    }
}

Describe 'uninstall-finalizer.ps1' {
    It 'deletes the install root and absence-verifies (parent already exited)' {
        $case = script:New-Dir (Join-Path $TestDrive 'f-ok')
        $area = script:New-Dir (Join-Path $case '.claude/ai-harness-toolset'); script:New-InstallRoot -Area $area -WithSourceCache -WithLog
        $self = Join-Path $case 'self'; $rp = Join-Path $case 'result.json'
        $r = script:Run-Finalizer -InstallRoot $area -ParentPid (script:New-DeadPid) -SelfDir $self -ResultPath $rp
        $r.Proc.ExitCode | Should -Be 0
        (Test-Path -LiteralPath $area) | Should -BeFalse
        $r.Result.installRootDeleted | Should -BeTrue
        $r.Result.status | Should -Match 'uninstalled'
    }
    It 'refuses a path that is not the canonical .claude\ai-harness-toolset (path guard)' {
        $case = script:New-Dir (Join-Path $TestDrive 'f-guard')
        $bad = script:New-Dir (Join-Path $case 'not-claude/ai-harness-toolset'); script:New-InstallRoot -Area $bad
        $self = Join-Path $case 'self'; $rp = Join-Path $case 'result.json'
        $r = script:Run-Finalizer -InstallRoot $bad -ParentPid (script:New-DeadPid) -SelfDir $self -ResultPath $rp
        $r.Proc.ExitCode | Should -Be 1
        (Test-Path -LiteralPath $bad) | Should -BeTrue
        $r.Result.status | Should -Be 'finalizer_path_guard_failed'
    }
    It 'refuses to delete when unexpected top-level content is present' {
        $case = script:New-Dir (Join-Path $TestDrive 'f-unexp')
        $area = script:New-Dir (Join-Path $case '.claude/ai-harness-toolset'); script:New-InstallRoot -Area $area
        script:Write-File (Join-Path $area 'surprise.txt') 'x'
        $self = Join-Path $case 'self'; $rp = Join-Path $case 'result.json'
        $r = script:Run-Finalizer -InstallRoot $area -ParentPid (script:New-DeadPid) -SelfDir $self -ResultPath $rp
        $r.Proc.ExitCode | Should -Be 1
        (Test-Path -LiteralPath $area) | Should -BeTrue
        $r.Result.status | Should -Be 'finalizer_unexpected_content'
    }
    It 'times out (does not delete) while the parent is still alive' {
        $case = script:New-Dir (Join-Path $TestDrive 'f-timeout')
        $area = script:New-Dir (Join-Path $case '.claude/ai-harness-toolset'); script:New-InstallRoot -Area $area
        $self = Join-Path $case 'self'; $rp = Join-Path $case 'result.json'
        $r = script:Run-Finalizer -InstallRoot $area -ParentPid $PID -SelfDir $self -ResultPath $rp -TimeoutSec 1 -PollMs 100
        $r.Proc.ExitCode | Should -Be 1
        (Test-Path -LiteralPath $area) | Should -BeTrue
        $r.Result.status | Should -Be 'finalizer_parent_wait_timeout'
    }
    It 'reports the exact temp path when self-clean fails (locked file in selfDir)' {
        $case = script:New-Dir (Join-Path $TestDrive 'f-leftover')
        $area = script:New-Dir (Join-Path $case '.claude/ai-harness-toolset'); script:New-InstallRoot -Area $area
        $self = script:New-Dir (Join-Path $case 'self'); $rp = Join-Path $case 'result.json'
        $lock = Join-Path $self 'lock.bin'; script:Write-File $lock 'x'
        $fs = [System.IO.File]::Open($lock, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::None)
        try {
            $r = script:Run-Finalizer -InstallRoot $area -ParentPid (script:New-DeadPid) -SelfDir $self -ResultPath $rp
            (Test-Path -LiteralPath $area) | Should -BeFalse           # install root still deleted
            $r.Result.installRootDeleted | Should -BeTrue
            $r.Result.status | Should -Be 'uninstalled_with_finalizer_leftover'
            $r.Result.selfCleanLeftover | Should -Be ([System.IO.Path]::GetFullPath($self))
        }
        finally { $fs.Close(); $fs.Dispose() }
    }
}

Describe 'uninstall-global.ps1 -Apply' {
    It 'blocked preflight (unexpected install-root content) removes NOTHING' {
        $fx = script:New-ApplyFixture 'a-block'
        script:Write-File (Join-Path $fx.Area 'surprise.txt') 'x'
        $beforeClaude = Read-Utf8 -Path $fx.ClaudeMd
        $p = script:Invoke-Apply $fx
        $p.ExitCode | Should -Be 1
        ($p.Stdout) | Should -Match 'uninstallStatus=uninstall_blocked'
        (Read-Utf8 -Path $fx.ClaudeMd) | Should -Be $beforeClaude          # marker still present
        (Test-Path -LiteralPath $fx.Skill) | Should -BeTrue                 # skill untouched
        (Test-Path -LiteralPath $fx.Area)  | Should -BeTrue                 # install root untouched
    }

    It 'removes managed blocks (outside content preserved) and the skill dir; preserves sibling skill' {
        $fx = script:New-ApplyFixture 'a-ok'
        $p = script:Invoke-Apply $fx
        $p.ExitCode | Should -Be 0
        ($p.Stdout) | Should -Match 'uninstallStatus=uninstall_finalizer_launched'
        # managed blocks removed, files kept, outside content preserved
        (Test-Path -LiteralPath $fx.ClaudeMd) | Should -BeTrue
        (script:Count-MarkerPairs $fx.ClaudeMd).Begin | Should -Be 0
        (Read-Utf8 -Path $fx.ClaudeMd) | Should -Match '# user before'
        (script:Count-MarkerPairs $fx.CodexMd).Begin | Should -Be 0
        # skill dir removed; sibling + skills parent preserved
        (Test-Path -LiteralPath $fx.Skill)   | Should -BeFalse
        (Test-Path -LiteralPath $fx.Sibling) | Should -BeTrue
        (Test-Path -LiteralPath (Join-Path $fx.Claude 'skills')) | Should -BeTrue
        # install root deleted by the (async) finalizer
        (script:Wait-Until { -not (Test-Path -LiteralPath $fx.Area) } 25) | Should -BeTrue
    }

    It 'non-effective Codex stale marker is detect-warn only (NOT removed) on apply' {
        $fx = script:New-ApplyFixture 'a-noneff'
        # override is effective; AGENTS.md becomes the non-effective file but still carries a marker.
        script:Write-Marked (Join-Path $fx.Codex 'AGENTS.override.md') 1
        # ($fx.CodexMd = AGENTS.md already has 1 pair from the fixture)
        $p = script:Invoke-Apply $fx
        $p.ExitCode | Should -Be 0
        (script:Count-MarkerPairs (Join-Path $fx.Codex 'AGENTS.override.md')).Begin | Should -Be 0   # effective removed
        (script:Count-MarkerPairs $fx.CodexMd).Begin | Should -Be 1                                  # non-effective preserved
        ($p.Stdout) | Should -Match 'codex-non-effective-stale-marker'
        ($p.Stdout) | Should -Match 'status=warn'
    }

    It 'managedBy mismatch blocks apply (removes nothing)' {
        $fx = script:New-ApplyFixture 'a-mb'
        script:Write-InstallJson -Area $fx.Area -ManagedBy 'someone-else'
        $beforeClaude = Read-Utf8 -Path $fx.ClaudeMd
        $p = script:Invoke-Apply $fx
        $p.ExitCode | Should -Be 1
        ($p.Stdout) | Should -Match 'uninstallStatus=uninstall_blocked'
        (Read-Utf8 -Path $fx.ClaudeMd) | Should -Be $beforeClaude
        (Test-Path -LiteralPath $fx.Area) | Should -BeTrue
    }

    It 'finalizer temp artifacts land under -FinalizerTempRoot (never real %TEMP%)' {
        $fx = script:New-ApplyFixture 'a-temp'
        $p = script:Invoke-Apply $fx
        $p.ExitCode | Should -Be 0
        @(Get-ChildItem -LiteralPath $fx.Tmp -Directory -Filter 'ai-harness-uninstall-*').Count | Should -BeGreaterThan 0
    }

    It 'pre-existing .amb-backup on a surface blocks apply (preflight; removes nothing)' {
        $fx = script:New-ApplyFixture 'a-amb'
        script:Write-File ($fx.ClaudeMd + '.amb-backup') 'orig bytes'
        $beforeClaude = Read-Utf8 -Path $fx.ClaudeMd
        $p = script:Invoke-Apply $fx
        $p.ExitCode | Should -Be 1
        ($p.Stdout) | Should -Match 'uninstallStatus=uninstall_blocked'
        (Read-Utf8 -Path $fx.ClaudeMd) | Should -Be $beforeClaude   # marker still present
        (Test-Path -LiteralPath $fx.Area) | Should -BeTrue
        (Test-Path -LiteralPath $fx.Skill) | Should -BeTrue
    }

    It 'skill dir WITHOUT SKILL.md is still removed by apply (footprint-zero)' {
        $fx = script:New-ApplyFixture 'a-skillnomd'
        Remove-Item -LiteralPath (Join-Path $fx.Skill 'SKILL.md') -Force   # leave the dir, drop SKILL.md
        (Test-Path -LiteralPath $fx.Skill -PathType Container) | Should -BeTrue
        $p = script:Invoke-Apply $fx
        $p.ExitCode | Should -Be 0
        (Test-Path -LiteralPath $fx.Skill) | Should -BeFalse           # dir removed despite no SKILL.md
        (Test-Path -LiteralPath $fx.Sibling) | Should -BeTrue
    }

    It 'finalizer launches correctly when the temp root path contains spaces (no false PASS)' {
        $fx = script:New-ApplyFixture 'a-space'
        $spacedRoot = script:New-Dir (Join-Path $fx.Root 'fin temp with spaces')
        $proc = Invoke-NativeProcess -Executable 'powershell.exe' -Arguments @(
            '-NoProfile','-ExecutionPolicy','Bypass','-File',$script:Entry,
            '-ClaudeHome',$fx.Claude,'-CodexHome',$fx.Codex,'-Apply','-FinalizerTempRoot',$spacedRoot)
        $proc.ExitCode | Should -Be 0
        ($proc.Stdout) | Should -Match 'uninstallStatus=uninstall_finalizer_launched'
        # The finalizer (launched from a spaced path) must actually delete the install root.
        (script:Wait-Until { -not (Test-Path -LiteralPath $fx.Area) } 25) | Should -BeTrue
    }

    It 'finalizer setup failure (temp root is a file) reports uninstall_partial after surfaces removed' {
        $fx = script:New-ApplyFixture 'a-finfail'
        # Point -FinalizerTempRoot at a FILE so the finalizer run-id dir creation throws (caught path).
        $badRoot = Join-Path $fx.Root 'not-a-dir'
        script:Write-File $badRoot 'x'
        $proc = Invoke-NativeProcess -Executable 'powershell.exe' -Arguments @(
            '-NoProfile','-ExecutionPolicy','Bypass','-File',$script:Entry,
            '-ClaudeHome',$fx.Claude,'-CodexHome',$fx.Codex,'-Apply','-FinalizerTempRoot',$badRoot)
        $proc.ExitCode | Should -Be 1
        ($proc.Stdout) | Should -Match 'uninstallStatus=uninstall_partial'
        (Test-Path -LiteralPath $fx.Area) | Should -BeTrue            # install root left intact (finalizer never launched)
    }
}
