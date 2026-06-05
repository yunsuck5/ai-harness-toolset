Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# IU-B-08 batch 2 — read-only uninstall target resolver + dry-run entrypoint.
# Everything runs in TestDrive; the real %USERPROFILE%\.claude / %USERPROFILE%\.codex are NEVER
# read-for-write or modified (ClaudeHome / CodexHome / InstallArea are always overridden to
# TestDrive). The resolver/entrypoint are read-only; tests also assert read-only behavior.

BeforeAll {
    $script:RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).ProviderPath
    . (Join-Path $script:RepoRoot 'scripts/lib/native-process.ps1')
    . (Join-Path $script:RepoRoot 'scripts/lib/encoding.ps1')
    . (Join-Path $script:RepoRoot 'scripts/lib/managed-block.ps1')
    . (Join-Path $script:RepoRoot 'scripts/lib/activation-surface.ps1')
    . (Join-Path $script:RepoRoot 'scripts/lib/install-pipeline-core.ps1')
    . (Join-Path $script:RepoRoot 'scripts/lib/uninstall-target.ps1')
    $script:Entry = Join-Path $script:RepoRoot 'scripts/uninstall-global.ps1'

    $script:Begin = '<!-- BEGIN AI_HARNESS_TOOLSET_GLOBAL -->'
    $script:End   = '<!-- END AI_HARNESS_TOOLSET_GLOBAL -->'

    function script:Write-File {
        param([string] $Path, [string] $Content)
        $parent = Split-Path -LiteralPath $Path
        if (-not (Test-Path -LiteralPath $parent -PathType Container)) { $null = New-Item -ItemType Directory -Path $parent -Force }
        $enc = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText([System.IO.Path]::GetFullPath($Path), $Content, $enc)
    }

    function script:New-Dir { param([string] $Path); if (-not (Test-Path -LiteralPath $Path)) { $null = New-Item -ItemType Directory -Path $Path -Force }; return ([System.IO.Path]::GetFullPath($Path)) }

    function script:New-Case { param([string] $Name); return (script:New-Dir (Join-Path $TestDrive $Name)) }

    function script:Write-InstallJson {
        param([string] $Area, [string] $ManagedBy = 'claude-code', [int] $SchemaVersion = 1)
        $md = [ordered]@{
            schemaVersion = $SchemaVersion; tool = 'ai-harness-toolset'; installMode = 'local-clone'
            repoUrl = ''; sourcePath = 'X:\src'; toolRoot = 'X:\src'; branch = 'main'; remote = 'origin'
            installedHead = ('0' * 40); lastUpdatedHead = ('0' * 40)
            installedAt = '2026-05-28T00:00:00Z'; lastUpdatedAt = '2026-05-28T00:00:00Z'
            targetFootprintPolicy = 'log-only'; managedBy = $ManagedBy
        }
        script:Write-File (Join-Path $Area 'install.json') ($md | ConvertTo-Json)
    }

    function script:New-ExpectedInstallRoot {
        # install root with the full expected footprint (no source-cache/log unless asked). The OWNED
        # skill inventory lives under current/snippets/claude-skills/<name>/SKILL.md — this is what
        # uninstall enumerates to know which skill dirs it owns; default = the single shipped review skill.
        param([string] $Area, [string] $ManagedBy = 'claude-code', [switch] $WithSourceCache, [switch] $WithLog, [string[]] $Skills = @('ai-harness-review'))
        $null = script:New-Dir (Join-Path $Area 'current')
        $null = script:New-Dir (Join-Path $Area 'current/scripts')
        script:Write-File (Join-Path $Area 'current/scripts/x.ps1') '# payload'
        foreach ($sk in $Skills) { script:Write-File (Join-Path $Area ('current/snippets/claude-skills/' + $sk + '/SKILL.md')) ('# ' + $sk + ' skill') }
        script:Write-InstallJson -Area $Area -ManagedBy $ManagedBy
        script:Write-File (Join-Path $Area 'payload-manifest.json') '{}'
        script:Write-File (Join-Path $Area 'payload-marker.json') '{}'
        script:Write-File (Join-Path $Area 'README.md') '# landing'
        if ($WithSourceCache) { $null = script:New-Dir (Join-Path $Area 'source-cache') ; script:Write-File (Join-Path $Area 'source-cache/clone.txt') 'x' }
        if ($WithLog) { $null = script:New-Dir (Join-Path $Area 'log/install-update') ; script:Write-File (Join-Path $Area 'log/install-update/run.json') '{}' }
    }

    function script:New-Homes {
        param([string] $Case)
        return [pscustomobject]@{
            ClaudeHome = (script:New-Dir (Join-Path $TestDrive ($Case + '-claude')))
            CodexHome  = (script:New-Dir (Join-Path $TestDrive ($Case + '-codex')))
        }
    }

    function script:Write-MarkedFile { param([string] $Path, [int] $Pairs = 1)
        $nl = "`n"; $body = "# user content$nl"
        for ($i = 0; $i -lt $Pairs; $i++) { $body += "$script:Begin${nl}block $i$nl$script:End$nl" }
        $body += "tail$nl"
        script:Write-File -Path $Path -Content $body
    }

    function script:Get-Target { param($Plan, [string] $Name); return @($Plan.Targets | Where-Object { $_.Name -eq $Name })[0] }

    function script:Snapshot {
        param([string] $Root)
        if (-not (Test-Path -LiteralPath $Root)) { return @() }
        return @(Get-ChildItem -LiteralPath $Root -Recurse -Force -File | ForEach-Object {
            '{0}|{1}|{2}' -f $_.FullName.Substring($Root.Length), $_.Length, (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
        } | Sort-Object)
    }
}

Describe 'Get-UninstallPlan — install root footprint' {

    It 'expected footprint only -> all removable, managedByOk, uninstall_preview' {
        $area = script:New-Case 'c-expected'; script:New-ExpectedInstallRoot -Area $area
        $h = script:New-Homes 'c-expected'
        $plan = Get-UninstallPlan -InstallArea $area -ClaudeHome $h.ClaudeHome -CodexHome $h.CodexHome
        $plan.ManagedByOk | Should -BeTrue
        $plan.OverallStatus | Should -Be 'uninstall_preview'
        (script:Get-Target $plan 'install-root').Status | Should -Be 'removable'
        @($plan.Targets | Where-Object { $_.Kind -eq 'install-root-entry' -and $_.Blocked }).Count | Should -Be 0
    }

    It 'source-cache present -> classified known-transient, removable, still preview' {
        $area = script:New-Case 'c-sc'; script:New-ExpectedInstallRoot -Area $area -WithSourceCache -WithLog
        $h = script:New-Homes 'c-sc'
        $plan = Get-UninstallPlan -InstallArea $area -ClaudeHome $h.ClaudeHome -CodexHome $h.CodexHome
        $sc = script:Get-Target $plan 'source-cache'
        $sc.Status | Should -Be 'removable'
        $sc.KnownTransient | Should -BeTrue
        $sc.WouldRemove | Should -BeTrue
        (script:Get-Target $plan 'log').Status | Should -Be 'removable'
        $plan.OverallStatus | Should -Be 'uninstall_preview'
    }

    It 'unexpected top-level content -> that entry blocked, install-root blocked, uninstall_blocked' {
        $area = script:New-Case 'c-unexp'; script:New-ExpectedInstallRoot -Area $area
        script:Write-File (Join-Path $area 'surprise.txt') 'not ours'
        $h = script:New-Homes 'c-unexp'
        $plan = Get-UninstallPlan -InstallArea $area -ClaudeHome $h.ClaudeHome -CodexHome $h.CodexHome
        (script:Get-Target $plan 'surprise.txt').Blocked | Should -BeTrue
        (script:Get-Target $plan 'surprise.txt').WouldRemove | Should -BeFalse
        (script:Get-Target $plan 'install-root').Blocked | Should -BeTrue
        $plan.OverallStatus | Should -Be 'uninstall_blocked'
    }

    It 'missing install root -> single absent target, preview' {
        $area = [System.IO.Path]::GetFullPath((Join-Path $TestDrive 'c-missing-root'))  # never created
        $h = script:New-Homes 'c-missing'
        $plan = Get-UninstallPlan -InstallArea $area -ClaudeHome $h.ClaudeHome -CodexHome $h.CodexHome
        $plan.InstallRootPresent | Should -BeFalse
        (script:Get-Target $plan 'install-root').Status | Should -Be 'absent'
        $plan.OverallStatus | Should -Be 'uninstall_preview'
    }

    It 'install.json missing -> install-root blocked (managed not confirmed)' {
        $area = script:New-Case 'c-nometa'; $null = script:New-Dir (Join-Path $area 'current'); script:Write-File (Join-Path $area 'README.md') 'x'
        $h = script:New-Homes 'c-nometa'
        $plan = Get-UninstallPlan -InstallArea $area -ClaudeHome $h.ClaudeHome -CodexHome $h.CodexHome
        $plan.ManagedByOk | Should -BeFalse
        (script:Get-Target $plan 'install-root').Blocked | Should -BeTrue
        $plan.OverallStatus | Should -Be 'uninstall_blocked'
    }

    It 'invalid install.json (bad schemaVersion) -> install-root blocked' {
        $area = script:New-Case 'c-badmeta'; script:New-ExpectedInstallRoot -Area $area
        script:Write-InstallJson -Area $area -SchemaVersion 99
        $h = script:New-Homes 'c-badmeta'
        $plan = Get-UninstallPlan -InstallArea $area -ClaudeHome $h.ClaudeHome -CodexHome $h.CodexHome
        $plan.ManagedByOk | Should -BeFalse
        (script:Get-Target $plan 'install-root').Blocked | Should -BeTrue
    }

    It 'managedBy mismatch -> install-root blocked' {
        $area = script:New-Case 'c-mb'; script:New-ExpectedInstallRoot -Area $area -ManagedBy 'someone-else'
        $h = script:New-Homes 'c-mb'
        $plan = Get-UninstallPlan -InstallArea $area -ClaudeHome $h.ClaudeHome -CodexHome $h.CodexHome
        $plan.ManagedBy | Should -Be 'someone-else'
        $plan.ManagedByOk | Should -BeFalse
        (script:Get-Target $plan 'install-root').Blocked | Should -BeTrue
        $plan.OverallStatus | Should -Be 'uninstall_blocked'
        # When the managed install is not confirmed, expected entries must be Status-consistent with
        # WouldRemove: blocked + WouldRemove=$false (never a contradictory removable/false).
        $cur = script:Get-Target $plan 'current'
        $cur.Status | Should -Be 'blocked'
        $cur.WouldRemove | Should -BeFalse
    }
}

Describe 'Get-UninstallPlan — activation surfaces' {

    It 'managed-block 0 pair -> absent; 1 pair -> removable; 2 pairs -> blocked' {
        $area = script:New-Case 'c-mbsurf'; script:New-ExpectedInstallRoot -Area $area

        $h0 = script:New-Homes 'c-mb0'; script:Write-File (Join-Path $h0.ClaudeHome 'CLAUDE.md') "no markers here`n"
        (script:Get-Target (Get-UninstallPlan -InstallArea $area -ClaudeHome $h0.ClaudeHome -CodexHome $h0.CodexHome) 'claude-user-global-managed-block').Status | Should -Be 'absent'

        $h1 = script:New-Homes 'c-mb1'; script:Write-MarkedFile (Join-Path $h1.ClaudeHome 'CLAUDE.md') 1
        $t1 = script:Get-Target (Get-UninstallPlan -InstallArea $area -ClaudeHome $h1.ClaudeHome -CodexHome $h1.CodexHome) 'claude-user-global-managed-block'
        $t1.Status | Should -Be 'removable'; $t1.WouldRemove | Should -BeTrue

        $h2 = script:New-Homes 'c-mb2'; script:Write-MarkedFile (Join-Path $h2.ClaudeHome 'CLAUDE.md') 2
        $plan2 = Get-UninstallPlan -InstallArea $area -ClaudeHome $h2.ClaudeHome -CodexHome $h2.CodexHome
        (script:Get-Target $plan2 'claude-user-global-managed-block').Blocked | Should -BeTrue
        $plan2.OverallStatus | Should -Be 'uninstall_blocked'
    }

    It 'managed-block surface with a pre-existing .amb-backup -> blocked (preflight parity)' {
        $area = script:New-Case 'c-amb'; script:New-ExpectedInstallRoot -Area $area
        $h = script:New-Homes 'c-amb'
        $cm = Join-Path $h.ClaudeHome 'CLAUDE.md'
        script:Write-MarkedFile $cm 1
        script:Write-File ($cm + '.amb-backup') 'orig bytes'
        $plan = Get-UninstallPlan -InstallArea $area -ClaudeHome $h.ClaudeHome -CodexHome $h.CodexHome
        (script:Get-Target $plan 'claude-user-global-managed-block').Blocked | Should -BeTrue
        $plan.OverallStatus | Should -Be 'uninstall_blocked'
    }

    It 'managed-block surface with a .amb-backup DIRECTORY -> blocked (parity with apply-managed-block)' {
        $area = script:New-Case 'c-ambdir'; script:New-ExpectedInstallRoot -Area $area
        $h = script:New-Homes 'c-ambdir'
        $cm = Join-Path $h.ClaudeHome 'CLAUDE.md'
        script:Write-MarkedFile $cm 1
        $null = script:New-Dir ($cm + '.amb-backup')   # a DIRECTORY at the sidecar path, not a file
        $plan = Get-UninstallPlan -InstallArea $area -ClaudeHome $h.ClaudeHome -CodexHome $h.CodexHome
        (script:Get-Target $plan 'claude-user-global-managed-block').Blocked | Should -BeTrue
        $plan.OverallStatus | Should -Be 'uninstall_blocked'
    }

    It 'managed-block surface with a UTF-8 BOM -> blocked (preflight parity)' {
        $area = script:New-Case 'c-bom'; script:New-ExpectedInstallRoot -Area $area
        $h = script:New-Homes 'c-bom'
        $cm = Join-Path $h.ClaudeHome 'CLAUDE.md'
        $nl = "`n"; $body = "# user$nl$script:Begin${nl}b$nl$script:End$nl"
        [System.IO.File]::WriteAllText([System.IO.Path]::GetFullPath($cm), $body, (New-Object System.Text.UTF8Encoding($true)))
        $plan = Get-UninstallPlan -InstallArea $area -ClaudeHome $h.ClaudeHome -CodexHome $h.CodexHome
        (script:Get-Target $plan 'claude-user-global-managed-block').Blocked | Should -BeTrue
    }

    It 'Codex effective surface = AGENTS.override.md when present (override precedence)' {
        $area = script:New-Case 'c-cdxeff'; script:New-ExpectedInstallRoot -Area $area
        $h = script:New-Homes 'c-cdxeff'
        script:Write-MarkedFile (Join-Path $h.CodexHome 'AGENTS.md') 1
        script:Write-MarkedFile (Join-Path $h.CodexHome 'AGENTS.override.md') 1
        $plan = Get-UninstallPlan -InstallArea $area -ClaudeHome $h.ClaudeHome -CodexHome $h.CodexHome
        $eff = script:Get-Target $plan 'codex-user-global-managed-block'
        $eff.Path | Should -Match 'AGENTS\.override\.md$'
        $eff.Status | Should -Be 'removable'
    }

    It 'non-effective Codex file with stale marker -> detect-warn only (not removable, not blocked)' {
        $area = script:New-Case 'c-cdxne'; script:New-ExpectedInstallRoot -Area $area
        $h = script:New-Homes 'c-cdxne'
        # override is effective; AGENTS.md is non-effective but carries a stale marker pair.
        script:Write-MarkedFile (Join-Path $h.CodexHome 'AGENTS.override.md') 1
        script:Write-MarkedFile (Join-Path $h.CodexHome 'AGENTS.md') 1
        $plan = Get-UninstallPlan -InstallArea $area -ClaudeHome $h.ClaudeHome -CodexHome $h.CodexHome
        $warn = script:Get-Target $plan 'codex-non-effective-stale-marker'
        $warn | Should -Not -BeNullOrEmpty
        $warn.Status | Should -Be 'warn'
        $warn.WouldRemove | Should -BeFalse
        $warn.Blocked | Should -BeFalse
        $warn.Path | Should -Match 'AGENTS\.md$'
    }

    It 'no non-effective warn when only the effective Codex file exists' {
        $area = script:New-Case 'c-cdxsingle'; script:New-ExpectedInstallRoot -Area $area
        $h = script:New-Homes 'c-cdxsingle'
        script:Write-MarkedFile (Join-Path $h.CodexHome 'AGENTS.md') 1   # effective, no override
        $plan = Get-UninstallPlan -InstallArea $area -ClaudeHome $h.ClaudeHome -CodexHome $h.CodexHome
        @($plan.Targets | Where-Object { $_.Kind -eq 'codex-non-effective' }).Count | Should -Be 0
    }

    It 'skill mirror present -> removable; absent -> absent' {
        $area = script:New-Case 'c-skill'; script:New-ExpectedInstallRoot -Area $area
        $hP = script:New-Homes 'c-skillP'
        script:Write-File (Join-Path $hP.ClaudeHome 'skills/ai-harness-review/SKILL.md') "---`nname: ai-harness-review`n---`n"
        (script:Get-Target (Get-UninstallPlan -InstallArea $area -ClaudeHome $hP.ClaudeHome -CodexHome $hP.CodexHome) 'skill-mirror:ai-harness-review').Status | Should -Be 'removable'

        $hA = script:New-Homes 'c-skillA'
        (script:Get-Target (Get-UninstallPlan -InstallArea $area -ClaudeHome $hA.ClaudeHome -CodexHome $hA.CodexHome) 'skill-mirror:ai-harness-review').Status | Should -Be 'absent'
    }

    It 'skill mirror removal-target Path is the ai-harness-review DIRECTORY (not the SKILL.md file)' {
        $area = script:New-Case 'c-skilldir'; script:New-ExpectedInstallRoot -Area $area
        $h = script:New-Homes 'c-skilldir'
        script:Write-File (Join-Path $h.ClaudeHome 'skills/ai-harness-review/SKILL.md') 'skill'
        $t = script:Get-Target (Get-UninstallPlan -InstallArea $area -ClaudeHome $h.ClaudeHome -CodexHome $h.CodexHome) 'skill-mirror:ai-harness-review'
        $t.Path | Should -Match 'ai-harness-review$'
        $t.Path | Should -Not -Match 'SKILL\.md$'
    }

    It 'skill dir present WITHOUT SKILL.md -> still removable (footprint-zero)' {
        $area = script:New-Case 'c-skillnomd'; script:New-ExpectedInstallRoot -Area $area
        $h = script:New-Homes 'c-skillnomd'
        $null = script:New-Dir (Join-Path $h.ClaudeHome 'skills/ai-harness-review')   # dir, no SKILL.md
        $t = script:Get-Target (Get-UninstallPlan -InstallArea $area -ClaudeHome $h.ClaudeHome -CodexHome $h.CodexHome) 'skill-mirror:ai-harness-review'
        $t.Status | Should -Be 'removable'
        $t.WouldRemove | Should -BeTrue
        $t.Path | Should -Match 'ai-harness-review$'
    }

    It 'generic enumeration: multiple owned skills each get a removable surface; a non-owned sibling is not enumerated' {
        $area = script:New-Case 'c-multiskill'
        script:New-ExpectedInstallRoot -Area $area -Skills @('ai-harness-review', 'ai-harness-extra')
        $h = script:New-Homes 'c-multiskill'
        script:Write-File (Join-Path $h.ClaudeHome 'skills/ai-harness-review/SKILL.md') 'a'
        script:Write-File (Join-Path $h.ClaudeHome 'skills/ai-harness-extra/SKILL.md') 'b'
        script:Write-File (Join-Path $h.ClaudeHome 'skills/other-skill/SKILL.md') 'sibling'   # present but NOT in the installed payload
        $plan = Get-UninstallPlan -InstallArea $area -ClaudeHome $h.ClaudeHome -CodexHome $h.CodexHome
        (script:Get-Target $plan 'skill-mirror:ai-harness-review').Status | Should -Be 'removable'
        (script:Get-Target $plan 'skill-mirror:ai-harness-extra').Status  | Should -Be 'removable'
        # Exactly the two owned skills are enumerated; the non-owned sibling produces no surface.
        @($plan.Targets | Where-Object { $_.Kind -eq 'skill-mirror' }).Count | Should -Be 2
        @($plan.Targets | Where-Object { $_.Name -match 'other-skill' }).Count | Should -Be 0
        ((script:Get-Target $plan 'skill-mirror:ai-harness-extra').Path) | Should -Match 'ai-harness-extra$'
    }

    It 'present + managed install root WITHOUT current/ → blocked (owned skill inventory unknowable; no silent orphan)' {
        # Corrupt/partial install: valid install.json + expected top-level footprint, but current/ is
        # ABSENT, so the owned skill inventory cannot be enumerated. Removing the install root while
        # skipping skill cleanup would orphan the owned runtime skill dir → must block, not silently
        # enumerate zero skills.
        $area = script:New-Case 'c-nocurrent'
        script:Write-InstallJson -Area $area
        script:Write-File (Join-Path $area 'payload-manifest.json') '{}'
        script:Write-File (Join-Path $area 'payload-marker.json') '{}'
        script:Write-File (Join-Path $area 'README.md') '# landing'
        $h = script:New-Homes 'c-nocurrent'
        script:Write-File (Join-Path $h.ClaudeHome 'skills/ai-harness-review/SKILL.md') 'owned but unknowable'
        $plan = Get-UninstallPlan -InstallArea $area -ClaudeHome $h.ClaudeHome -CodexHome $h.CodexHome
        $inv = script:Get-Target $plan 'skill-inventory'
        $inv | Should -Not -BeNullOrEmpty
        $inv.Blocked | Should -BeTrue
        $inv.WouldRemove | Should -BeFalse
        $plan.OverallStatus | Should -Be 'uninstall_blocked'
    }

    It 'present + managed install root with current/ but NO snippets/claude-skills/ → blocked (inventory source damaged; no silent orphan)' {
        # current/ exists but the skill-inventory source (current/snippets/claude-skills/) is missing —
        # the OWNED skill set still cannot be determined, so this narrower partial-install shape must
        # block too (same footprint-zero failure class as an absent current/).
        $area = script:New-Case 'c-noinv'
        $null = script:New-Dir (Join-Path $area 'current/scripts')
        script:Write-File (Join-Path $area 'current/scripts/x.ps1') '# payload'
        script:Write-InstallJson -Area $area
        script:Write-File (Join-Path $area 'payload-manifest.json') '{}'
        script:Write-File (Join-Path $area 'payload-marker.json') '{}'
        script:Write-File (Join-Path $area 'README.md') '# landing'
        $h = script:New-Homes 'c-noinv'
        script:Write-File (Join-Path $h.ClaudeHome 'skills/ai-harness-review/SKILL.md') 'owned but unknowable'
        $plan = Get-UninstallPlan -InstallArea $area -ClaudeHome $h.ClaudeHome -CodexHome $h.CodexHome
        (script:Get-Target $plan 'skill-inventory').Blocked | Should -BeTrue
        $plan.OverallStatus | Should -Be 'uninstall_blocked'
    }

    It 'present + managed install root with claude-skills/ present but yielding ZERO skills (no SKILL.md) → blocked (untrusted inventory)' {
        # claude-skills/ exists and even holds a candidate dir, but it has NO SKILL.md, so the resolver
        # enumerates zero owned skills. A removable managed install with zero trustworthy owned skills
        # must still block (the broadest footprint-zero-safe case: absent OR empty OR malformed).
        $area = script:New-Case 'c-emptyinv'
        $null = script:New-Dir (Join-Path $area 'current/scripts')
        script:Write-File (Join-Path $area 'current/scripts/x.ps1') '# payload'
        $null = script:New-Dir (Join-Path $area 'current/snippets/claude-skills/broken-skill')   # dir, NO SKILL.md
        script:Write-InstallJson -Area $area
        script:Write-File (Join-Path $area 'payload-manifest.json') '{}'
        script:Write-File (Join-Path $area 'payload-marker.json') '{}'
        script:Write-File (Join-Path $area 'README.md') '# landing'
        $h = script:New-Homes 'c-emptyinv'
        script:Write-File (Join-Path $h.ClaudeHome 'skills/ai-harness-review/SKILL.md') 'owned but untrusted'
        $plan = Get-UninstallPlan -InstallArea $area -ClaudeHome $h.ClaudeHome -CodexHome $h.CodexHome
        (script:Get-Target $plan 'skill-inventory').Blocked | Should -BeTrue
        $plan.OverallStatus | Should -Be 'uninstall_blocked'
    }
}

Describe 'Get-UninstallPlan — read-only invariant' {
    It 'computing the plan mutates nothing under the install area or homes' {
        $area = script:New-Case 'c-ro'; script:New-ExpectedInstallRoot -Area $area -WithSourceCache -WithLog
        script:Write-File (Join-Path $area 'surprise.txt') 'x'
        $h = script:New-Homes 'c-ro'
        script:Write-MarkedFile (Join-Path $h.ClaudeHome 'CLAUDE.md') 1
        script:Write-MarkedFile (Join-Path $h.CodexHome 'AGENTS.md') 1
        script:Write-File (Join-Path $h.ClaudeHome 'skills/ai-harness-review/SKILL.md') 'skill'

        $beforeArea = script:Snapshot $area; $beforeC = script:Snapshot $h.ClaudeHome; $beforeX = script:Snapshot $h.CodexHome
        $null = Get-UninstallPlan -InstallArea $area -ClaudeHome $h.ClaudeHome -CodexHome $h.CodexHome
        (script:Snapshot $area)        | Should -Be $beforeArea
        (script:Snapshot $h.ClaudeHome) | Should -Be $beforeC
        (script:Snapshot $h.CodexHome)  | Should -Be $beforeX
    }
}

Describe 'uninstall-global.ps1 — dry-run entrypoint' {

    It '-Apply against a non-canonical install-area path is refused by the path guard (exit 1, no mutation)' {
        # -Apply is implemented as of IU-B-08 batch 3, but the install-root path guard requires the
        # canonical <...>\.claude\ai-harness-toolset shape. This TestDrive area is NOT that shape, so
        # apply must block on the path guard and mutate nothing. (Full apply behavior with a canonical
        # fixture path is covered in tests/uninstall-apply.Tests.ps1.)
        $area = script:New-Case 'e-apply'; script:New-ExpectedInstallRoot -Area $area
        $h = script:New-Homes 'e-apply'
        script:Write-MarkedFile (Join-Path $h.ClaudeHome 'CLAUDE.md') 1
        $before = script:Snapshot $area; $beforeC = script:Snapshot $h.ClaudeHome
        $proc = Invoke-NativeProcess -Executable 'powershell.exe' -Arguments @(
            '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $script:Entry,
            '-InstallArea', $area, '-ClaudeHome', $h.ClaudeHome, '-CodexHome', $h.CodexHome, '-Apply'
        )
        $proc.ExitCode | Should -Be 1
        ($proc.Stdout) | Should -Match 'uninstallStatus=uninstall_blocked'
        ($proc.Stdout) | Should -Match 'path guard'
        (script:Snapshot $area) | Should -Be $before
        (script:Snapshot $h.ClaudeHome) | Should -Be $beforeC
    }

    It 'dry-run reports uninstall_preview, exit 0, and mutates nothing' {
        $area = script:New-Case 'e-dry'; script:New-ExpectedInstallRoot -Area $area -WithSourceCache
        $h = script:New-Homes 'e-dry'
        script:Write-MarkedFile (Join-Path $h.ClaudeHome 'CLAUDE.md') 1
        $before = script:Snapshot $area; $beforeC = script:Snapshot $h.ClaudeHome; $beforeX = script:Snapshot $h.CodexHome
        $proc = Invoke-NativeProcess -Executable 'powershell.exe' -Arguments @(
            '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $script:Entry,
            '-InstallArea', $area, '-ClaudeHome', $h.ClaudeHome, '-CodexHome', $h.CodexHome
        )
        $proc.ExitCode | Should -Be 0
        ($proc.Stdout) | Should -Match 'uninstallStatus=uninstall_preview'
        ($proc.Stdout) | Should -Match 'mode=DRY-RUN'
        (script:Snapshot $area) | Should -Be $before
        (script:Snapshot $h.ClaudeHome) | Should -Be $beforeC
        (script:Snapshot $h.CodexHome) | Should -Be $beforeX
    }

    It 'dry-run surfaces uninstall_blocked on unexpected install-root content (exit 0, no mutation)' {
        $area = script:New-Case 'e-block'; script:New-ExpectedInstallRoot -Area $area
        script:Write-File (Join-Path $area 'surprise.txt') 'x'
        $h = script:New-Homes 'e-block'
        $proc = Invoke-NativeProcess -Executable 'powershell.exe' -Arguments @(
            '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $script:Entry,
            '-InstallArea', $area, '-ClaudeHome', $h.ClaudeHome, '-CodexHome', $h.CodexHome
        )
        $proc.ExitCode | Should -Be 0
        ($proc.Stdout) | Should -Match 'uninstallStatus=uninstall_blocked'
    }
}
