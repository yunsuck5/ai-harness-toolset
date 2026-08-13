Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Focused integration suite for scripts/install-global.ps1 (IU-B-09 fresh-install regression closeout).
# Every destructive path runs against TestDrive homes/areas — no real %USERPROFILE%\.claude or
# %USERPROFILE%\.codex is ever touched.

BeforeAll {
    $script:RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).ProviderPath
    . (Join-Path $script:RepoRoot 'scripts/lib/native-process.ps1')
    . (Join-Path $script:RepoRoot 'tests/support/lifecycle-fixture.ps1')
    $script:InstallGlobal = Join-Path $script:RepoRoot 'scripts/install-global.ps1'

    $script:Begin = '<!-- BEGIN AI_HARNESS_TOOLSET_GLOBAL -->'
    $script:End   = '<!-- END AI_HARNESS_TOOLSET_GLOBAL -->'

    function script:Read-NoBom {
        param([string] $Path)
        return [System.IO.File]::ReadAllText((Resolve-Path -LiteralPath $Path).ProviderPath, (New-Object System.Text.UTF8Encoding($false)))
    }
    function script:Write-NoBom {
        param([string] $Path, [string] $Content)
        $parent = Split-Path -Parent $Path
        if (-not (Test-Path -LiteralPath $parent -PathType Container)) { $null = New-Item -ItemType Directory -Path $parent -Force }
        [System.IO.File]::WriteAllText([System.IO.Path]::GetFullPath($Path), $Content, (New-Object System.Text.UTF8Encoding($false)))
    }
    function script:Install {
        param([hashtable] $Params)
        return Invoke-LifecycleScript -ScriptPath $script:InstallGlobal -Params $Params
    }

    function script:Invoke-InstallGlobalFixtureGit {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory = $true)]
            [string[]] $Arguments
        )

        $proc = Invoke-NativeProcess -Executable 'git' -Arguments $Arguments
        if ($proc.ExitCode -ne 0) {
            $detail = (([string] $proc.Stdout) + "`n" + ([string] $proc.Stderr)).Trim()
            throw ('install-global fixture git 실패: git {0}; exitCode={1}; output={2}' -f
                ($Arguments -join ' '), $proc.ExitCode, $detail)
        }

        return (([string] $proc.Stdout).Trim())
    }
}

Describe 'install-global.ps1 fresh install (IU-B-09)' {

    It 'AC-IG-1: fresh local-clone install reaches verify_pass; payload + both vendor skill mirrors created' {
        $src = New-LifecycleFixtureSource -TestDriveRoot $TestDrive -CaseName 'fresh'
        $h   = New-LifecycleHomes -TestDriveRoot $TestDrive -CaseName 'fresh'
        $r = script:Install -Params @{ InstallArea = $h.Area; SourcePath = $src; ClaudeHome = $h.Claude; CodexHome = $h.Codex; SkipSmoke = $true }
        $r.ExitCode | Should -Be 0
        $r.Output | Should -Match 'installStatus=installed'
        $r.Output | Should -Match 'verify reached verify_pass'

        # Payload artifacts.
        (Test-Path -LiteralPath (Join-Path $h.Area 'install.json') -PathType Leaf) | Should -BeTrue
        (Test-Path -LiteralPath (Join-Path $h.Area 'payload-manifest.json') -PathType Leaf) | Should -BeTrue
        (Test-Path -LiteralPath (Join-Path $h.Area 'payload-marker.json') -PathType Leaf) | Should -BeTrue
        (Test-Path -LiteralPath (Join-Path $h.Area 'current/snippets/CLAUDE_SNIPPET.md') -PathType Leaf) | Should -BeTrue

        # Activation surfaces created by the bootstrap.
        (Test-Path -LiteralPath (Join-Path $h.Claude 'CLAUDE.md') -PathType Leaf) | Should -BeTrue
        (Test-Path -LiteralPath (Join-Path $h.Codex 'AGENTS.md') -PathType Leaf) | Should -BeTrue
        (Test-Path -LiteralPath (Join-Path $h.Claude 'skills/ai-harness-review/SKILL.md') -PathType Leaf) | Should -BeTrue
        (Test-Path -LiteralPath (Join-Path $h.Codex 'skills/ai-harness-review/SKILL.md') -PathType Leaf) | Should -BeTrue

        # Each managed-block surface carries exactly one marker pair.
        $claudeMd = script:Read-NoBom -Path (Join-Path $h.Claude 'CLAUDE.md')
        ([regex]::Matches($claudeMd, '(?m)^' + [regex]::Escape($script:Begin) + '$')).Count | Should -Be 1
        $agentsMd = script:Read-NoBom -Path (Join-Path $h.Codex 'AGENTS.md')
        ([regex]::Matches($agentsMd, '(?m)^' + [regex]::Escape($script:Begin) + '$')).Count | Should -Be 1
    }

    It 'Q09-IG-E2E-1: git-url fresh install은 custom remote와 non-default selected SHA를 end-to-end로 결박한다' {
        $src = New-LifecycleFixtureSource -TestDriveRoot $TestDrive -CaseName 'q09-git-url-e2e'
        $h   = New-LifecycleHomes -TestDriveRoot $TestDrive -CaseName 'q09-git-url-e2e'

        $selectedBranch = 'release-q09'
        $remoteAlias    = 'upstream'
        $sentinelRel    = 'config/q09-selected-target.txt'
        $sentinelText   = 'selected-release-q09'

        # 선택 branch는 D3-valid 상태를 유지하면서 main과 구별되는 payload를 갖는다.
        $null = script:Invoke-InstallGlobalFixtureGit -Arguments @(
            '-C', $src, 'checkout', '-q', '-b', $selectedBranch
        )
        script:Write-NoBom -Path (Join-Path $src $sentinelRel) -Content $sentinelText
        $null = script:Invoke-InstallGlobalFixtureGit -Arguments @(
            '-C', $src, 'add', '--', $sentinelRel
        )
        $null = script:Invoke-InstallGlobalFixtureGit -Arguments @(
            '-C', $src, 'commit', '-q', '-m', 'seed selected release target'
        )
        $selectedSha = script:Invoke-InstallGlobalFixtureGit -Arguments @(
            '-C', $src, 'rev-parse', 'HEAD'
        )

        # clone의 default checkout인 main은 D3-invalid로 만들어 selected-tree 검사를 구별한다.
        $null = script:Invoke-InstallGlobalFixtureGit -Arguments @(
            '-C', $src, 'checkout', '-q', 'main'
        )
        Remove-Item -LiteralPath (Join-Path $src 'scripts/verify-ps1.ps1') -Force
        $null = script:Invoke-InstallGlobalFixtureGit -Arguments @(
            '-C', $src, 'add', '-A', '--', 'scripts/verify-ps1.ps1'
        )
        $null = script:Invoke-InstallGlobalFixtureGit -Arguments @(
            '-C', $src, 'commit', '-q', '-m', 'make default branch D3-invalid'
        )
        $defaultSha = script:Invoke-InstallGlobalFixtureGit -Arguments @(
            '-C', $src, 'rev-parse', 'HEAD'
        )

        $selectedSha | Should -Match '^[0-9a-f]{40}$'
        $defaultSha  | Should -Match '^[0-9a-f]{40}$'
        $selectedSha | Should -Not -BeExactly $defaultSha

        # 외부 network 없이 local bare repo를 실제 RepoUrl로 사용한다.
        $barePath = [System.IO.Path]::GetFullPath(
            (Join-Path $TestDrive 'lifecycle-bare-q09-git-url-e2e.git')
        )
        $null = script:Invoke-InstallGlobalFixtureGit -Arguments @(
            'clone', '--bare', '-q', $src, $barePath
        )

        $r = script:Install -Params @{
            InstallArea = $h.Area
            RepoUrl     = $barePath
            Branch      = $selectedBranch
            Remote      = $remoteAlias
            ClaudeHome  = $h.Claude
            CodexHome   = $h.Codex
            SkipSmoke   = $true
        }

        $r.ExitCode | Should -Be 0 -Because $r.Output
        $r.Output | Should -Match 'installMode=git-url'
        $r.Output | Should -Match 'verify reached verify_pass'
        $r.Output | Should -Match 'installStatus=installed'
        $r.Output | Should -Match ('installedHead=' + [regex]::Escape($selectedSha))

        $metadata = script:Read-NoBom -Path (Join-Path $h.Area 'install.json') |
            ConvertFrom-Json
        [string] $metadata.installMode     | Should -BeExactly 'git-url'
        [string] $metadata.repoUrl         | Should -BeExactly $barePath
        [string] $metadata.sourcePath      | Should -BeExactly ''
        [string] $metadata.toolRoot        | Should -BeExactly ''
        [string] $metadata.branch          | Should -BeExactly $selectedBranch
        [string] $metadata.remote          | Should -BeExactly $remoteAlias
        [string] $metadata.installedHead   | Should -BeExactly $selectedSha
        [string] $metadata.lastUpdatedHead | Should -BeExactly $selectedSha

        $manifest = script:Read-NoBom -Path (Join-Path $h.Area 'payload-manifest.json') |
            ConvertFrom-Json
        $marker = script:Read-NoBom -Path (Join-Path $h.Area 'payload-marker.json') |
            ConvertFrom-Json

        [string] $manifest.head       | Should -BeExactly $selectedSha
        [string] $marker.head         | Should -BeExactly $selectedSha
        [string] $marker.manifestPath | Should -BeExactly 'payload-manifest.json'

        $installedSentinel = Join-Path $h.Area ('current/' + $sentinelRel)
        (Test-Path -LiteralPath $installedSentinel -PathType Leaf) | Should -BeTrue
        (script:Read-NoBom -Path $installedSentinel) | Should -BeExactly $sentinelText
        @($manifest.files | Where-Object {
            [string] $_.path -ceq $sentinelRel
        }).Count | Should -Be 1

        # default main에는 첫 marker가 없으므로, 이 셋의 materialization은 selected SHA D3를 증명한다.
        foreach ($relativePath in @(
            'scripts/verify-ps1.ps1',
            'templates/review-input.md',
            'config/reviewer.json'
        )) {
            $installedPath = Join-Path $h.Area ('current/' + $relativePath)
            (Test-Path -LiteralPath $installedPath -PathType Leaf) | Should -BeTrue
            @($manifest.files | Where-Object {
                [string] $_.path -ceq $relativePath
            }).Count | Should -Be 1
        }

        # run-scoped clone은 성공 경로 종료 시 남지 않는다.
        (Test-Path -LiteralPath (Join-Path $h.Area 'source-cache')) | Should -BeFalse
    }

    It 'AC-IG-MULTISKILL: a second source skill is also force-mirrored + finally verified (generic enumeration)' {
        $src = New-LifecycleFixtureSource -TestDriveRoot $TestDrive -CaseName 'multiskill' -ExtraSkills @('ai-harness-extra')
        $h   = New-LifecycleHomes -TestDriveRoot $TestDrive -CaseName 'multiskill'
        $r = script:Install -Params @{ InstallArea = $h.Area; SourcePath = $src; ClaudeHome = $h.Claude; CodexHome = $h.Codex; SkipSmoke = $true }
        $r.ExitCode | Should -Be 0
        $r.Output | Should -Match 'installStatus=installed'
        # verify_pass requires both vendor mirrors for every source skill to be byte-identical.
        $r.Output | Should -Match 'verify reached verify_pass'

        # BOTH source skills are mirrored to their runtime destinations (forced mirror, not just the payload copy).
        (Test-Path -LiteralPath (Join-Path $h.Claude 'skills/ai-harness-review/SKILL.md') -PathType Leaf) | Should -BeTrue
        (Test-Path -LiteralPath (Join-Path $h.Claude 'skills/ai-harness-extra/SKILL.md') -PathType Leaf)  | Should -BeTrue
        (Test-Path -LiteralPath (Join-Path $h.Codex 'skills/ai-harness-review/SKILL.md') -PathType Leaf) | Should -BeTrue
        (Test-Path -LiteralPath (Join-Path $h.Codex 'skills/ai-harness-extra/SKILL.md') -PathType Leaf)  | Should -BeTrue
        # The extra skill's runtime mirror is byte-identical to its installed payload source.
        $extSrc = script:Read-NoBom -Path (Join-Path $h.Area 'current/snippets/claude-skills/ai-harness-extra/SKILL.md')
        $extDst = script:Read-NoBom -Path (Join-Path $h.Claude 'skills/ai-harness-extra/SKILL.md')
        $extDst | Should -Be $extSrc
        $extCodexDst = script:Read-NoBom -Path (Join-Path $h.Codex 'skills/ai-harness-extra/SKILL.md')
        $extCodexDst | Should -Be $extSrc
    }

    It 'AC-IG-2: pre-existing 0-pair CLAUDE.md content is preserved (append, not overwrite)' {
        $src = New-LifecycleFixtureSource -TestDriveRoot $TestDrive -CaseName 'append'
        $h   = New-LifecycleHomes -TestDriveRoot $TestDrive -CaseName 'append'
        $existing = "# user CLAUDE.md`n`nmy own content`n"
        script:Write-NoBom -Path (Join-Path $h.Claude 'CLAUDE.md') -Content $existing

        $r = script:Install -Params @{ InstallArea = $h.Area; SourcePath = $src; ClaudeHome = $h.Claude; CodexHome = $h.Codex; SkipSmoke = $true }
        $r.ExitCode | Should -Be 0
        $written = script:Read-NoBom -Path (Join-Path $h.Claude 'CLAUDE.md')
        $written.StartsWith($existing) | Should -BeTrue
        ([regex]::Matches($written, '(?m)^' + [regex]::Escape($script:Begin) + '$')).Count | Should -Be 1
    }

    It 'AC-IG-3: existing install (install.json present) -> fail-fast pointing to update-global; no overwrite' {
        $src = New-LifecycleFixtureSource -TestDriveRoot $TestDrive -CaseName 'existing'
        $h   = New-LifecycleHomes -TestDriveRoot $TestDrive -CaseName 'existing'
        $r1 = script:Install -Params @{ InstallArea = $h.Area; SourcePath = $src; ClaudeHome = $h.Claude; CodexHome = $h.Codex; SkipSmoke = $true }
        $r1.ExitCode | Should -Be 0
        $before = script:Read-NoBom -Path (Join-Path $h.Area 'install.json')

        $r2 = script:Install -Params @{ InstallArea = $h.Area; SourcePath = $src; ClaudeHome = $h.Claude; CodexHome = $h.Codex; SkipSmoke = $true }
        $r2.ExitCode | Should -Not -Be 0
        $r2.Output | Should -Match 'install_failed'
        $r2.Output | Should -Match 'update-global'
        $r2.Output | Should -Match 'install\.json\.installMode'
        $r2.Output | Should -Match 'git-url'
        $r2.Output | Should -Match 'exactly one target selector'
        $r2.Output | Should -Match '\-Branch'
        $r2.Output | Should -Match '\-Ref'
        $r2.Output | Should -Match 'advertised 40-hex branch-tip'
        $r2.Output | Should -Match 'local-clone, pass neither selector'
        $r2.Output | Should -Match 'install-update\.ps1 -Mode update-source'
        # install.json byte-unchanged by the refused second install.
        (script:Read-NoBom -Path (Join-Path $h.Area 'install.json')) | Should -Be $before
    }

    It 'AC-IG-4: non-empty area without install.json -> fail-fast (no overwrite of foreign content)' {
        $src = New-LifecycleFixtureSource -TestDriveRoot $TestDrive -CaseName 'nonempty'
        $h   = New-LifecycleHomes -TestDriveRoot $TestDrive -CaseName 'nonempty'
        $null = New-Item -ItemType Directory -Path $h.Area -Force
        script:Write-NoBom -Path (Join-Path $h.Area 'someones-file.txt') -Content 'do not clobber'

        $r = script:Install -Params @{ InstallArea = $h.Area; SourcePath = $src; ClaudeHome = $h.Claude; CodexHome = $h.Codex; SkipSmoke = $true }
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'not empty'
        (Test-Path -LiteralPath (Join-Path $h.Area 'someones-file.txt') -PathType Leaf) | Should -BeTrue
        (Test-Path -LiteralPath (Join-Path $h.Area 'install.json')) | Should -BeFalse
    }

    It 'AC-IG-5: missing source argument -> fail-fast (no install area created)' {
        $h = New-LifecycleHomes -TestDriveRoot $TestDrive -CaseName 'nosrc'
        $r = script:Install -Params @{ InstallArea = $h.Area; ClaudeHome = $h.Claude; CodexHome = $h.Codex; SkipSmoke = $true }
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'source is required'
        (Test-Path -LiteralPath (Join-Path $h.Area 'install.json')) | Should -BeFalse
    }

    It 'AC-IG-6: both -SourcePath and -RepoUrl -> fail-fast (exactly one source)' {
        $src = New-LifecycleFixtureSource -TestDriveRoot $TestDrive -CaseName 'bothsrc'
        $h   = New-LifecycleHomes -TestDriveRoot $TestDrive -CaseName 'bothsrc'
        $r = script:Install -Params @{ InstallArea = $h.Area; SourcePath = $src; RepoUrl = 'https://example.invalid/x.git'; ClaudeHome = $h.Claude; CodexHome = $h.Codex; SkipSmoke = $true }
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'only one of'
    }

    It 'AC-IG-7: pre-existing 1-pair CLAUDE.md -> activation FAILS (refuse silent splice); reported' {
        $src = New-LifecycleFixtureSource -TestDriveRoot $TestDrive -CaseName 'onepair'
        $h   = New-LifecycleHomes -TestDriveRoot $TestDrive -CaseName 'onepair'
        $existing = "head`n$script:Begin`nstale block`n$script:End`ntail`n"
        script:Write-NoBom -Path (Join-Path $h.Claude 'CLAUDE.md') -Content $existing

        $r = script:Install -Params @{ InstallArea = $h.Area; SourcePath = $src; ClaudeHome = $h.Claude; CodexHome = $h.Codex; SkipSmoke = $true }
        $r.ExitCode | Should -Not -Be 0
        $r.Output | Should -Match 'activation_failed'
        $r.Output | Should -Match 'already contains a managed block'
        # The pre-existing CLAUDE.md is left untouched (no silent splice).
        (script:Read-NoBom -Path (Join-Path $h.Claude 'CLAUDE.md')) | Should -Be $existing
    }
}
