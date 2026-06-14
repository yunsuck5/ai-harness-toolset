Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# IU-B-08 batch 3 — destructive uninstall apply path + temp finalizer trampoline.
# EVERYTHING runs in TestDrive. The real %USERPROFILE%\.claude / %USERPROFILE%\.codex / the real
# %USERPROFILE%\ai-harness-toolset install area are NEVER read-for-write or mutated: every invocation
# overrides -ClaudeHome / -CodexHome / -InstallArea / -FinalizerTempRoot to TestDrive paths. Install-root
# fixtures are built as <TestDrive>\<case>\ai-harness-toolset (a sibling of the .claude / .codex
# activation homes, mirroring the relocated vendor-neutral topology). There is NO operator-facing
# -ExpectedInstallArea parameter — the canonical install area is computed from %USERPROFILE%
# (Get-StableInstallAreaCandidate), so a legitimate apply against a sandbox area is made canonical by
# overriding %USERPROFILE% to the fixture root for the child process (the only isolation seam). The
# path-guard tests instead leave %USERPROFILE% pointing elsewhere so the sandbox -InstallArea is
# non-canonical and refused. (Run-Finalizer builds the finalizer input JSON directly — a lower-level
# boundary for the finalizer itself, distinct from the entrypoint's now-removed parameter.)

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
    function script:New-InstallRoot { param([string] $Area, [string] $ManagedBy = 'claude-code', [switch] $WithSourceCache, [switch] $WithLog, [string[]] $Skills = @('ai-harness-review'))
        $null = script:New-Dir (Join-Path $Area 'current/scripts')
        script:Write-File (Join-Path $Area 'current/scripts/x.ps1') '# payload'
        # OWNED skill inventory under current/snippets/claude-skills/<name>/SKILL.md (what uninstall enumerates).
        foreach ($sk in $Skills) { script:Write-File (Join-Path $Area ('current/snippets/claude-skills/' + $sk + '/SKILL.md')) ('# ' + $sk + ' skill') }
        script:Write-InstallJson -Area $Area -ManagedBy $ManagedBy
        script:Write-File (Join-Path $Area 'payload-manifest.json') '{}'
        script:Write-File (Join-Path $Area 'payload-marker.json') '{}'
        script:Write-File (Join-Path $Area 'README.md') '# landing'
        if ($WithSourceCache) { script:Write-File (Join-Path $Area 'source-cache/clone.txt') 'x' }
        if ($WithLog) { script:Write-File (Join-Path $Area 'log/install-update/run.json') '{}' }
    }

    # Full apply fixture: <case>/ai-harness-toolset (install area, sibling of the activation homes) +
    # <case>/.claude/{CLAUDE.md, skills/...} + <case>/.codex/AGENTS.md.
    function script:New-ApplyFixture { param([string] $Case)
        $root   = script:New-Dir (Join-Path $TestDrive $Case)
        $claude = script:New-Dir (Join-Path $root '.claude')
        $codex  = script:New-Dir (Join-Path $root '.codex')
        $area   = script:New-Dir (Join-Path $root 'ai-harness-toolset')
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
        # There is NO operator-facing -ExpectedInstallArea: the canonical install area is computed from
        # %USERPROFILE%. To make the fixture's sandbox area canonical (so the path guard passes for a
        # legitimate apply), override %USERPROFILE% to the fixture root for the child process — the only
        # isolation seam. The fixture area is <root>\ai-harness-toolset, which then equals the canonical
        # the child resolves. -InstallArea is passed explicitly as that same fixture area.
        $args = @('-NoProfile','-ExecutionPolicy','Bypass','-File',$script:Entry,
            '-InstallArea',$Fx.Area,
            '-ClaudeHome',$Fx.Claude,'-CodexHome',$Fx.Codex,'-Apply','-FinalizerTempRoot',$Fx.Tmp) + $Extra
        $orig = $env:USERPROFILE
        try {
            $env:USERPROFILE = $Fx.Root
            return Invoke-NativeProcess -Executable 'powershell.exe' -Arguments $args
        }
        finally { $env:USERPROFILE = $orig }
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
    function script:Run-Finalizer { param([string] $InstallRoot, [int] $ParentPid, [string] $SelfDir, [string] $ResultPath, [int] $TimeoutSec = 5, [int] $PollMs = 100, [string] $ExpectedInstallArea = '', [switch] $OmitExpected)
        # The finalizer guard requires installRoot to EQUAL expectedInstallArea. Default the expected to
        # the install root so the happy-path tests pass; a path-guard test passes a MISMATCHED expected;
        # -OmitExpected drops the field entirely to exercise the fail-closed (no-expectation) path.
        if ([string]::IsNullOrEmpty($ExpectedInstallArea)) { $ExpectedInstallArea = $InstallRoot }
        $inputPath = Join-Path (script:New-Dir $SelfDir) 'finalizer-input.json'
        $obj = [ordered]@{ installRoot=$InstallRoot }
        if (-not $OmitExpected) { $obj['expectedInstallArea'] = $ExpectedInstallArea }
        $obj['parentPid']       = $ParentPid
        $obj['expectedEntries'] = @(Get-UninstallExpectedRootEntries)
        $obj['resultPath']      = $ResultPath
        $obj['selfDir']         = $SelfDir
        $obj['timeoutSec']      = $TimeoutSec
        $obj['pollMs']          = $PollMs
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
        $area = script:New-Dir (Join-Path $case 'ai-harness-toolset'); script:New-InstallRoot -Area $area -WithSourceCache -WithLog
        $self = Join-Path $case 'self'; $rp = Join-Path $case 'result.json'
        $r = script:Run-Finalizer -InstallRoot $area -ParentPid (script:New-DeadPid) -SelfDir $self -ResultPath $rp
        $r.Proc.ExitCode | Should -Be 0
        (Test-Path -LiteralPath $area) | Should -BeFalse
        $r.Result.installRootDeleted | Should -BeTrue
        $r.Result.status | Should -Match 'uninstalled'
    }
    It 'refuses an install root that does not equal the expected canonical install area (path guard)' {
        # The finalizer guard is exact-path equality against the passed expectedInstallArea (vendor-
        # neutral; no .claude parent assumption). Here installRoot != expectedInstallArea, so it refuses.
        $case = script:New-Dir (Join-Path $TestDrive 'f-guard')
        $bad = script:New-Dir (Join-Path $case 'ai-harness-toolset'); script:New-InstallRoot -Area $bad
        $mismatchedExpected = [System.IO.Path]::GetFullPath((Join-Path $case 'different-canonical-area'))
        $self = Join-Path $case 'self'; $rp = Join-Path $case 'result.json'
        $r = script:Run-Finalizer -InstallRoot $bad -ParentPid (script:New-DeadPid) -SelfDir $self -ResultPath $rp -ExpectedInstallArea $mismatchedExpected
        $r.Proc.ExitCode | Should -Be 1
        (Test-Path -LiteralPath $bad) | Should -BeTrue
        $r.Result.status | Should -Be 'finalizer_path_guard_failed'
    }

    It 'fail-closed: refuses to delete when no expected install area is passed (empty guard input)' {
        # Defense-in-depth: a finalizer input WITHOUT expectedInstallArea must never delete (fail-closed).
        $case = script:New-Dir (Join-Path $TestDrive 'f-noexp')
        $area = script:New-Dir (Join-Path $case 'ai-harness-toolset'); script:New-InstallRoot -Area $area
        $self = Join-Path $case 'self'; $rp = Join-Path $case 'result.json'
        $r = script:Run-Finalizer -InstallRoot $area -ParentPid (script:New-DeadPid) -SelfDir $self -ResultPath $rp -OmitExpected
        $r.Proc.ExitCode | Should -Be 1
        (Test-Path -LiteralPath $area) | Should -BeTrue
        $r.Result.status | Should -Be 'finalizer_path_guard_failed'
    }
    It 'refuses to delete when unexpected top-level content is present' {
        $case = script:New-Dir (Join-Path $TestDrive 'f-unexp')
        $area = script:New-Dir (Join-Path $case 'ai-harness-toolset'); script:New-InstallRoot -Area $area
        script:Write-File (Join-Path $area 'surprise.txt') 'x'
        $self = Join-Path $case 'self'; $rp = Join-Path $case 'result.json'
        $r = script:Run-Finalizer -InstallRoot $area -ParentPid (script:New-DeadPid) -SelfDir $self -ResultPath $rp
        $r.Proc.ExitCode | Should -Be 1
        (Test-Path -LiteralPath $area) | Should -BeTrue
        $r.Result.status | Should -Be 'finalizer_unexpected_content'
    }
    It 'times out (does not delete) while the parent is still alive' {
        $case = script:New-Dir (Join-Path $TestDrive 'f-timeout')
        $area = script:New-Dir (Join-Path $case 'ai-harness-toolset'); script:New-InstallRoot -Area $area
        $self = Join-Path $case 'self'; $rp = Join-Path $case 'result.json'
        $r = script:Run-Finalizer -InstallRoot $area -ParentPid $PID -SelfDir $self -ResultPath $rp -TimeoutSec 1 -PollMs 100
        $r.Proc.ExitCode | Should -Be 1
        (Test-Path -LiteralPath $area) | Should -BeTrue
        $r.Result.status | Should -Be 'finalizer_parent_wait_timeout'
    }
    It 'reports the exact temp path when self-clean fails (locked file in selfDir)' {
        $case = script:New-Dir (Join-Path $TestDrive 'f-leftover')
        $area = script:New-Dir (Join-Path $case 'ai-harness-toolset'); script:New-InstallRoot -Area $area
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

    It 'non-canonical -InstallArea is refused by the destructive apply guard regardless of root presence (no mutation)' {
        # The canonical install area is %USERPROFILE%\ai-harness-toolset (no operator override). A
        # non-canonical -InstallArea must be refused BEFORE any surface removal whether its (wrong) root
        # is ABSENT or PRESENT — managed-block + skill-mirror removal targets the activation homes, which
        # are independent of the install root, so a mismatched target must never reach surface removal.
        $fx = script:New-ApplyFixture 'a-noncanon'
        $beforeClaude = Read-Utf8 -Path $fx.ClaudeMd
        $origUP = $env:USERPROFILE

        # (1) ABSENT non-canonical: canonical = $fx.Area (via %USERPROFILE% = $fx.Root); -InstallArea is
        #     an absent path != canonical -> path guard blocks.
        $absent = [System.IO.Path]::GetFullPath((Join-Path $fx.Root 'nonexistent-area'))
        (Test-Path -LiteralPath $absent) | Should -BeFalse
        try {
            $env:USERPROFILE = $fx.Root
            $p1 = Invoke-NativeProcess -Executable 'powershell.exe' -Arguments @(
                '-NoProfile','-ExecutionPolicy','Bypass','-File',$script:Entry,
                '-InstallArea',$absent,'-ClaudeHome',$fx.Claude,'-CodexHome',$fx.Codex,'-Apply','-FinalizerTempRoot',$fx.Tmp)
        }
        finally { $env:USERPROFILE = $origUP }
        $p1.ExitCode | Should -Be 1
        ($p1.Stdout) | Should -Match 'uninstallStatus=uninstall_blocked'
        ($p1.Stdout) | Should -Match 'path guard'

        # (2) PRESENT + VALID non-canonical: $fx.Area is a present valid install, but canonical is
        #     elsewhere (via %USERPROFILE% = <other>), so the plan has no blocked targets yet the path
        #     guard still refuses it -> blocked before any surface removal.
        $elsewhere = script:New-Dir (Join-Path $fx.Root 'elsewhere')
        try {
            $env:USERPROFILE = $elsewhere   # canonical = $elsewhere\ai-harness-toolset (!= $fx.Area)
            $p2 = Invoke-NativeProcess -Executable 'powershell.exe' -Arguments @(
                '-NoProfile','-ExecutionPolicy','Bypass','-File',$script:Entry,
                '-InstallArea',$fx.Area,'-ClaudeHome',$fx.Claude,'-CodexHome',$fx.Codex,'-Apply','-FinalizerTempRoot',$fx.Tmp)
        }
        finally { $env:USERPROFILE = $origUP }
        $p2.ExitCode | Should -Be 1
        ($p2.Stdout) | Should -Match 'uninstallStatus=uninstall_blocked'
        ($p2.Stdout) | Should -Match 'path guard'
        (Test-Path -LiteralPath $fx.Area) | Should -BeTrue   # present valid install untouched

        # Neither invocation mutated the activation surfaces.
        (Read-Utf8 -Path $fx.ClaudeMd) | Should -Be $beforeClaude
        (script:Count-MarkerPairs $fx.ClaudeMd).Begin | Should -Be 1
        (Test-Path -LiteralPath $fx.Skill) | Should -BeTrue
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
        $origUP = $env:USERPROFILE
        try {
            $env:USERPROFILE = $fx.Root   # make the fixture area canonical (no operator override param)
            $proc = Invoke-NativeProcess -Executable 'powershell.exe' -Arguments @(
                '-NoProfile','-ExecutionPolicy','Bypass','-File',$script:Entry,
                '-InstallArea',$fx.Area,
                '-ClaudeHome',$fx.Claude,'-CodexHome',$fx.Codex,'-Apply','-FinalizerTempRoot',$spacedRoot)
        }
        finally { $env:USERPROFILE = $origUP }
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
        $origUP = $env:USERPROFILE
        try {
            $env:USERPROFILE = $fx.Root   # make the fixture area canonical (no operator override param)
            $proc = Invoke-NativeProcess -Executable 'powershell.exe' -Arguments @(
                '-NoProfile','-ExecutionPolicy','Bypass','-File',$script:Entry,
                '-InstallArea',$fx.Area,
                '-ClaudeHome',$fx.Claude,'-CodexHome',$fx.Codex,'-Apply','-FinalizerTempRoot',$badRoot)
        }
        finally { $env:USERPROFILE = $origUP }
        $proc.ExitCode | Should -Be 1
        ($proc.Stdout) | Should -Match 'uninstallStatus=uninstall_partial'
        (Test-Path -LiteralPath $fx.Area) | Should -BeTrue            # install root left intact (finalizer never launched)
    }

    It 'removes ALL owned skill dirs (generic) and preserves a non-owned sibling; skill cleanup is NOT the finalizer' {
        $root   = script:New-Dir (Join-Path $TestDrive 'a-multiskill')
        $claude = script:New-Dir (Join-Path $root '.claude')
        $codex  = script:New-Dir (Join-Path $root '.codex')
        $area   = script:New-Dir (Join-Path $root 'ai-harness-toolset')
        script:New-InstallRoot -Area $area -Skills @('ai-harness-review', 'ai-harness-extra')
        script:Write-Marked (Join-Path $claude 'CLAUDE.md') 1
        script:Write-Marked (Join-Path $codex 'AGENTS.md') 1
        script:Write-File (Join-Path $claude 'skills/ai-harness-review/SKILL.md') 'a'
        script:Write-File (Join-Path $claude 'skills/ai-harness-extra/SKILL.md') 'b'
        script:Write-File (Join-Path $claude 'skills/other-skill/SKILL.md') 'sibling'   # present but NOT in the installed payload
        $tmp = script:New-Dir (Join-Path $root 'fin-temp')

        $origUP = $env:USERPROFILE
        try {
            $env:USERPROFILE = $root   # make the fixture area ($root\ai-harness-toolset) canonical
            $proc = Invoke-NativeProcess -Executable 'powershell.exe' -Arguments @(
                '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $script:Entry,
                '-InstallArea', $area,
                '-ClaudeHome', $claude, '-CodexHome', $codex, '-Apply', '-FinalizerTempRoot', $tmp)
        }
        finally { $env:USERPROFILE = $origUP }
        $proc.ExitCode | Should -Be 0
        ($proc.Stdout) | Should -Match 'uninstallStatus=uninstall_finalizer_launched'
        # Both OWNED skill dirs are removed synchronously by the entrypoint (BEFORE the finalizer is
        # launched — the finalizer only deletes the install root, never the skill surfaces).
        (Test-Path -LiteralPath (Join-Path $claude 'skills/ai-harness-review')) | Should -BeFalse
        (Test-Path -LiteralPath (Join-Path $claude 'skills/ai-harness-extra'))  | Should -BeFalse
        # The non-owned sibling skill (and the skills/ parent) is preserved.
        (Test-Path -LiteralPath (Join-Path $claude 'skills/other-skill/SKILL.md')) | Should -BeTrue
        (Test-Path -LiteralPath (Join-Path $claude 'skills')) | Should -BeTrue
        # The install root is deleted by the (async) finalizer — its sole responsibility.
        (script:Wait-Until { -not (Test-Path -LiteralPath $area) } 25) | Should -BeTrue
    }
}

Describe 'uninstall-global.ps1 — canonical expected-area is internal-only (no operator injection)' {

    It 'exposes NO operator-facing ExpectedInstallArea parameter (public surface)' {
        # The expected canonical install area must never be operator-injectable; otherwise an operator
        # could pass a matching value and bypass the canonical pin. Assert it is absent from the script's
        # param block (and InstallArea IS present, as a sanity check that we parsed the right block).
        $tokens = $null; $perr = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($script:Entry, [ref]$tokens, [ref]$perr)
        $paramNames = @($ast.ParamBlock.Parameters | ForEach-Object { $_.Name.VariablePath.UserPath })
        $paramNames | Should -Contain 'InstallArea'
        $paramNames | Should -Not -Contain 'ExpectedInstallArea'
    }

    It 'rejects a passed -ExpectedInstallArea (unknown parameter; no run)' {
        # Even with a fixture present, passing -ExpectedInstallArea must fail at parameter binding (before
        # any body logic), proving the injection channel is gone.
        $fx = script:New-ApplyFixture 'a-rejectparam'
        $proc = Invoke-NativeProcess -Executable 'powershell.exe' -Arguments @(
            '-NoProfile','-ExecutionPolicy','Bypass','-File',$script:Entry,
            '-InstallArea',$fx.Area,'-ExpectedInstallArea',$fx.Area,
            '-ClaudeHome',$fx.Claude,'-CodexHome',$fx.Codex)
        $proc.ExitCode | Should -Not -Be 0
        # PowerShell line-wraps the binding error text, so assert on the wrap-proof identifier tokens:
        # the unknown parameter name and the NamedParameterNotFound error id.
        (($proc.Stdout + $proc.Stderr)) | Should -Match 'ExpectedInstallArea'
        (($proc.Stdout + $proc.Stderr)) | Should -Match 'NamedParameterNotFound'
        # Nothing destructive happened: the fixture's managed block + install root are intact.
        (script:Count-MarkerPairs $fx.ClaudeMd).Begin | Should -Be 1
        (Test-Path -LiteralPath $fx.Area) | Should -BeTrue
    }

    It 'finalizer input carries only the canonical expected install area (deleted root == canonical)' {
        # No operator override exists, so the finalizer-input expectedInstallArea can only be the canonical
        # area. Proof: run a legitimate apply (the fixture area is made canonical via %USERPROFILE%), then
        # read the finalizer RESULT json (it survives self-clean). The finalizer deletes the install root
        # ONLY when its guard (installRoot == expectedInstallArea from the input JSON) passes — so a
        # deleted canonical root proves the input's expectedInstallArea was the canonical area.
        $fx = script:New-ApplyFixture 'a-finalizer-canonical'
        $origUP = $env:USERPROFILE
        try {
            $env:USERPROFILE = $fx.Root
            $proc = Invoke-NativeProcess -Executable 'powershell.exe' -Arguments @(
                '-NoProfile','-ExecutionPolicy','Bypass','-File',$script:Entry,
                '-InstallArea',$fx.Area,'-ClaudeHome',$fx.Claude,'-CodexHome',$fx.Codex,'-Apply','-FinalizerTempRoot',$fx.Tmp)
        }
        finally { $env:USERPROFILE = $origUP }
        $proc.ExitCode | Should -Be 0
        ($proc.Stdout) | Should -Match 'uninstallStatus=uninstall_finalizer_launched'
        $m = [regex]::Match($proc.Stdout, 'finalizerResult=(.+?) \(written')
        $m.Success | Should -BeTrue
        $resultPath = $m.Groups[1].Value.Trim()
        (script:Wait-Until { Test-Path -LiteralPath $resultPath } 25) | Should -BeTrue
        $res = Get-Content -LiteralPath $resultPath -Raw | ConvertFrom-Json
        $res.installRootDeleted | Should -BeTrue
        ([System.IO.Path]::GetFullPath([string]$res.installRoot)) | Should -Be ([System.IO.Path]::GetFullPath($fx.Area))
        (script:Wait-Until { -not (Test-Path -LiteralPath $fx.Area) } 25) | Should -BeTrue
    }
}
