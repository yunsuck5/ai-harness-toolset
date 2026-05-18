Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

BeforeAll {
    $script:RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).ProviderPath
    $script:EntryScript = Join-Path $script:RepoRoot 'scripts/install-pipeline.ps1'

    . (Join-Path $script:RepoRoot 'scripts/lib/encoding.ps1')
    . (Join-Path $script:RepoRoot 'scripts/lib/path.ps1')
    . (Join-Path $script:RepoRoot 'scripts/lib/install-pipeline-core.ps1')

    function script:New-FixtureSourceRepo {
        param(
            [string] $CaseName,
            [string] $MarkerSuffix = 'v1',
            [switch] $WithoutSourceRepoMarkers
        )
        $root = Join-Path $TestDrive ('source-' + $CaseName)
        if (Test-Path -LiteralPath $root) {
            Remove-Item -LiteralPath $root -Recurse -Force
        }
        $null = New-Item -ItemType Directory -Path $root -Force
        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        Push-Location $root
        try {
            & git init -q 2>&1 | Out-Null
            # Disable line-ending conversion locally so fixture writes (LF) do not
            # trigger git's CRLF warnings on systems with core.autocrlf enabled.
            & git config core.autocrlf false 2>&1 | Out-Null
            & git config core.safecrlf false 2>&1 | Out-Null
            & git config user.email 'test@example.com' 2>&1 | Out-Null
            & git config user.name  'install-pipeline-test' 2>&1 | Out-Null
            foreach ($r in 'config','scripts','snippets','templates') {
                $null = New-Item -ItemType Directory -Path (Join-Path $root $r) -Force
                $marker = Join-Path $root ("$r/marker.txt")
                [System.IO.File]::WriteAllText($marker, "marker-$r-$MarkerSuffix", $utf8NoBom)
            }
            # D3 source-repo multi-marker: parent §2.2 / SHARED D3 — required for
            # local-clone validation. Tests can opt out via -WithoutSourceRepoMarkers
            # to exercise the install-pipeline dispatcher's rejection path.
            if (-not $WithoutSourceRepoMarkers) {
                [System.IO.File]::WriteAllText((Join-Path $root 'scripts/verify-ps1.ps1'),    '# marker', $utf8NoBom)
                [System.IO.File]::WriteAllText((Join-Path $root 'templates/review-input.md'), '# marker', $utf8NoBom)
                [System.IO.File]::WriteAllText((Join-Path $root 'config/reviewer.json'),      '{}',       $utf8NoBom)
            }
            & git add . 2>&1 | Out-Null
            & git commit -q -m ('seed ' + $MarkerSuffix) 2>&1 | Out-Null
            $head = (& git rev-parse HEAD 2>&1 | Out-String).Trim()
        }
        finally { Pop-Location }
        return [pscustomobject]@{
            Root = ([System.IO.Path]::GetFullPath($root))
            Head = $head
        }
    }

    function script:Add-FixtureCommit {
        param(
            [string] $SourceRoot,
            [string] $MarkerSuffix
        )
        Push-Location $SourceRoot
        try {
            foreach ($r in 'config','scripts','snippets','templates') {
                $marker = Join-Path $SourceRoot ("$r/marker.txt")
                [System.IO.File]::WriteAllText($marker, "marker-$r-$MarkerSuffix", (New-Object System.Text.UTF8Encoding($false)))
            }
            & git add . 2>&1 | Out-Null
            & git commit -q -m ('commit ' + $MarkerSuffix) 2>&1 | Out-Null
            return (& git rev-parse HEAD 2>&1 | Out-String).Trim()
        }
        finally { Pop-Location }
    }

    function script:New-InstallArea {
        param([string] $CaseName)
        $root = Join-Path $TestDrive ('install-area-' + $CaseName)
        if (Test-Path -LiteralPath $root) {
            Remove-Item -LiteralPath $root -Recurse -Force
        }
        $null = New-Item -ItemType Directory -Path $root -Force
        return ([System.IO.Path]::GetFullPath($root))
    }

    function script:New-ProjectRoot {
        param([string] $CaseName)
        $root = Join-Path $TestDrive ('project-' + $CaseName)
        if (Test-Path -LiteralPath $root) {
            Remove-Item -LiteralPath $root -Recurse -Force
        }
        $null = New-Item -ItemType Directory -Path $root -Force
        $null = New-Item -ItemType Directory -Path (Join-Path $root '.git') -Force
        return ([System.IO.Path]::GetFullPath($root))
    }

    function script:Invoke-InstallPipeline {
        param([hashtable] $Params)
        $procArgs = @(
            '-NoProfile',
            '-ExecutionPolicy', 'Bypass',
            '-File', $script:EntryScript
        )
        foreach ($k in $Params.Keys) {
            $v = $Params[$k]
            if ($null -eq $v) { continue }
            if ($v -is [System.Management.Automation.SwitchParameter] -or $v -is [bool]) {
                if ([bool]$v) { $procArgs += ('-' + $k) }
            }
            else {
                $procArgs += @(('-' + $k), [string]$v)
            }
        }
        $combined = & powershell.exe @procArgs 2>&1
        $exitCode = $LASTEXITCODE
        $text = ($combined | ForEach-Object { [string]$_ }) -join "`n"
        return [pscustomobject]@{
            ExitCode = $exitCode
            Output   = $text
        }
    }

    function script:Read-MetadataFromArea {
        param([string] $InstallArea)
        $path = Join-Path $InstallArea 'install.json'
        $raw = [System.IO.File]::ReadAllText($path, (New-Object System.Text.UTF8Encoding($false)))
        return ($raw | ConvertFrom-Json)
    }
}

Describe 'install-pipeline library — resolved tuple shape' {
    It 'AC-IP-TUPLE-1: builds tuple with all required fields' {
        $t = New-InstallPipelineTuple `
            -Action 'install' `
            -InstallMode 'local-clone' `
            -SourceLocation 'C:\src' `
            -ResolvedRefSha 'deadbeef' `
            -RefKind 'commit' `
            -ToolRoot 'C:\src' `
            -ProjectRoot 'C:\proj' `
            -SourceUpdatePolicy 'read-current-only'

        $t.action             | Should -Be 'install'
        $t.installMode        | Should -Be 'local-clone'
        $t.sourceLocation     | Should -Be 'C:\src'
        $t.resolvedRefSha     | Should -Be 'deadbeef'
        $t.refKind            | Should -Be 'commit'
        $t.toolRoot           | Should -Be 'C:\src'
        $t.projectRoot        | Should -Be 'C:\proj'
        $t.sourceUpdatePolicy | Should -Be 'read-current-only'
        $t.sourceCutDetected  | Should -BeFalse
    }
}

Describe 'install-pipeline library — source-cut detection' {
    It 'AC-IP-CUT-1: detects repoUrl mismatch' {
        $md = [pscustomobject]@{ installMode='git-url'; repoUrl='https://x'; sourcePath=''; toolRoot='a'; branch='b'; remote='c' }
        Test-InstallPipelineSourceCut -Metadata $md -InvocationParams @{ repoUrl = 'https://y' } | Should -BeTrue
    }
    It 'AC-IP-CUT-2: detects installMode mismatch' {
        $md = [pscustomobject]@{ installMode='git-url'; repoUrl='x'; sourcePath=''; toolRoot='a'; branch='b'; remote='c' }
        Test-InstallPipelineSourceCut -Metadata $md -InvocationParams @{ installMode = 'local-clone' } | Should -BeTrue
    }
    It 'AC-IP-CUT-3: case-insensitive match returns false' {
        $md = [pscustomobject]@{ installMode='git-url'; repoUrl='HTTPS://X'; sourcePath=''; toolRoot='a'; branch='b'; remote='c' }
        Test-InstallPipelineSourceCut -Metadata $md -InvocationParams @{ repoUrl = 'https://x' } | Should -BeFalse
    }
    It 'AC-IP-CUT-4: null metadata returns false' {
        Test-InstallPipelineSourceCut -Metadata $null -InvocationParams @{ repoUrl='x' } | Should -BeFalse
    }
    It 'AC-IP-CUT-5: empty invocation values are ignored' {
        $md = [pscustomobject]@{ installMode='git-url'; repoUrl='x'; sourcePath=''; toolRoot='a'; branch='b'; remote='c' }
        Test-InstallPipelineSourceCut -Metadata $md -InvocationParams @{ repoUrl = '' } | Should -BeFalse
    }
}

Describe 'install-pipeline library — dogfooding detection' {
    It 'AC-IP-DOG-1: same path AND source-repo markers = dogfooding' {
        $root = Join-Path $TestDrive 'dogfood-1'
        $null = New-Item -ItemType Directory -Path $root -Force
        foreach ($p in @('scripts/verify-ps1.ps1','templates/review-input.md','config/reviewer.json')) {
            $full = Join-Path $root $p
            $parent = Split-Path -LiteralPath $full
            $null = New-Item -ItemType Directory -Path $parent -Force
            [System.IO.File]::WriteAllText($full, '# marker', (New-Object System.Text.UTF8Encoding($false)))
        }
        Test-InstallPipelineDogfoodingSource -SourcePath $root -ProjectRoot $root | Should -BeTrue
    }
    It 'AC-IP-DOG-2: different paths = not dogfooding' {
        $a = Join-Path $TestDrive 'dogfood-2a'; $null = New-Item -ItemType Directory -Path $a -Force
        $b = Join-Path $TestDrive 'dogfood-2b'; $null = New-Item -ItemType Directory -Path $b -Force
        Test-InstallPipelineDogfoodingSource -SourcePath $a -ProjectRoot $b | Should -BeFalse
    }
    It 'AC-IP-DOG-3: same path but no source markers = not dogfooding' {
        $r = Join-Path $TestDrive 'dogfood-3'; $null = New-Item -ItemType Directory -Path $r -Force
        Test-InstallPipelineDogfoodingSource -SourcePath $r -ProjectRoot $r | Should -BeFalse
    }
}

Describe 'install-pipeline entry — install / verify / metadata' {
    It 'AC-IP-INSTALL-1: install materializes payload roots + writes valid install.json' {
        $src = script:New-FixtureSourceRepo -CaseName 'install-1' -MarkerSuffix 'v1'
        $area = script:New-InstallArea -CaseName 'install-1'
        $proj = script:New-ProjectRoot -CaseName 'install-1'

        $r = script:Invoke-InstallPipeline -Params @{
            Action          = 'install'
            InstallArea     = $area
            InstallMode     = 'local-clone'
            SourcePath      = $src.Root
            Branch          = 'main'
            Remote          = 'origin'
            ProjectRoot     = $proj
            RuntimeToolRoot = $proj
        }
        $r.ExitCode | Should -Be 0 -Because $r.Output
        $r.Output   | Should -Match 'install-pipeline: PASS'

        foreach ($pr in 'config','scripts','snippets','templates') {
            $f = Join-Path $area "current/$pr/marker.txt"
            Test-Path -LiteralPath $f -PathType Leaf | Should -BeTrue
            [System.IO.File]::ReadAllText($f, (New-Object System.Text.UTF8Encoding($false))) | Should -Be "marker-$pr-v1"
        }
        $md = script:Read-MetadataFromArea -InstallArea $area
        $md.schemaVersion         | Should -Be 1
        $md.tool                  | Should -Be 'ai-harness-toolset'
        $md.installMode           | Should -Be 'local-clone'
        $md.sourcePath            | Should -Be $src.Root
        $md.toolRoot              | Should -Be $src.Root
        $md.installedHead         | Should -Be $src.Head
        $md.lastUpdatedHead       | Should -Be $src.Head
        $md.targetFootprintPolicy | Should -Be 'log-only'
        $md.managedBy             | Should -Be 'claude-code'
        $md.branch                | Should -Be 'main'
        $md.remote                | Should -Be 'origin'
    }
}

Describe 'install-pipeline entry — update-source / update-current / restore' {
    It 'AC-IP-UPDATE-SOURCE-1: update-source picks up new HEAD; preserves installedHead' {
        $src = script:New-FixtureSourceRepo -CaseName 'us-1' -MarkerSuffix 'v1'
        $area = script:New-InstallArea -CaseName 'us-1'
        $proj = script:New-ProjectRoot -CaseName 'us-1'

        $r1 = script:Invoke-InstallPipeline -Params @{
            Action=  'install'; InstallArea = $area; InstallMode = 'local-clone';
            SourcePath = $src.Root; Branch = 'main'; Remote = 'origin';
            ProjectRoot = $proj; RuntimeToolRoot = $proj
        }
        $r1.ExitCode | Should -Be 0 -Because $r1.Output

        $headV2 = script:Add-FixtureCommit -SourceRoot $src.Root -MarkerSuffix 'v2'

        $r2 = script:Invoke-InstallPipeline -Params @{
            Action = 'update-source'; InstallArea = $area; SourcePath = $src.Root;
            ProjectRoot = $proj; RuntimeToolRoot = $proj
        }
        $r2.ExitCode | Should -Be 0 -Because $r2.Output

        $md = script:Read-MetadataFromArea -InstallArea $area
        $md.installedHead   | Should -Be $src.Head
        $md.lastUpdatedHead | Should -Be $headV2
        [System.IO.File]::ReadAllText((Join-Path $area 'current/config/marker.txt'), (New-Object System.Text.UTF8Encoding($false))) | Should -Be 'marker-config-v2'
    }

    It 'AC-IP-UPDATE-CURRENT-1: update-current reflects current source HEAD without source mutation' {
        $src = script:New-FixtureSourceRepo -CaseName 'uc-1' -MarkerSuffix 'v1'
        $area = script:New-InstallArea -CaseName 'uc-1'
        $proj = script:New-ProjectRoot -CaseName 'uc-1'

        script:Invoke-InstallPipeline -Params @{
            Action='install'; InstallArea=$area; InstallMode='local-clone';
            SourcePath=$src.Root; Branch='main'; Remote='origin';
            ProjectRoot=$proj; RuntimeToolRoot=$proj
        } | Out-Null

        $headV2 = script:Add-FixtureCommit -SourceRoot $src.Root -MarkerSuffix 'v2'

        $r = script:Invoke-InstallPipeline -Params @{
            Action='update-current'; InstallArea=$area; SourcePath=$src.Root;
            ProjectRoot=$proj; RuntimeToolRoot=$proj
        }
        $r.ExitCode | Should -Be 0 -Because $r.Output

        $md = script:Read-MetadataFromArea -InstallArea $area
        $md.installedHead   | Should -Be $src.Head
        $md.lastUpdatedHead | Should -Be $headV2
    }

    It 'AC-IP-RESTORE-1: restore requires explicit -Ref' {
        $src = script:New-FixtureSourceRepo -CaseName 'r-1' -MarkerSuffix 'v1'
        $area = script:New-InstallArea -CaseName 'r-1'
        $proj = script:New-ProjectRoot -CaseName 'r-1'

        script:Invoke-InstallPipeline -Params @{
            Action='install'; InstallArea=$area; InstallMode='local-clone';
            SourcePath=$src.Root; Branch='main'; Remote='origin';
            ProjectRoot=$proj; RuntimeToolRoot=$proj
        } | Out-Null

        $r = script:Invoke-InstallPipeline -Params @{
            Action='restore'; InstallArea=$area; SourcePath=$src.Root;
            ProjectRoot=$proj; RuntimeToolRoot=$proj
        }
        $r.ExitCode | Should -Not -Be 0
        $r.Output   | Should -Match 'requires -Ref'
    }

    It 'AC-IP-RESTORE-2: restore with explicit ref re-materializes to that ref' {
        $src = script:New-FixtureSourceRepo -CaseName 'r-2' -MarkerSuffix 'v1'
        $headV1 = $src.Head
        $area = script:New-InstallArea -CaseName 'r-2'
        $proj = script:New-ProjectRoot -CaseName 'r-2'

        script:Invoke-InstallPipeline -Params @{
            Action='install'; InstallArea=$area; InstallMode='local-clone';
            SourcePath=$src.Root; Branch='main'; Remote='origin';
            ProjectRoot=$proj; RuntimeToolRoot=$proj
        } | Out-Null

        [void] (script:Add-FixtureCommit -SourceRoot $src.Root -MarkerSuffix 'v2')

        $r = script:Invoke-InstallPipeline -Params @{
            Action='restore'; InstallArea=$area; SourcePath=$src.Root; Ref=$headV1;
            ProjectRoot=$proj; RuntimeToolRoot=$proj
        }
        $r.ExitCode | Should -Be 0 -Because $r.Output

        $md = script:Read-MetadataFromArea -InstallArea $area
        $md.installedHead   | Should -Be $headV1
        $md.lastUpdatedHead | Should -Be $headV1
        [System.IO.File]::ReadAllText((Join-Path $area 'current/config/marker.txt'), (New-Object System.Text.UTF8Encoding($false))) | Should -Be 'marker-config-v1'
    }
}

Describe 'install-pipeline entry — source-cut detection / dogfooding guard' {
    It 'AC-IP-SOURCE-CUT-1: update with mismatched sourcePath stops with source-cut' {
        $src = script:New-FixtureSourceRepo -CaseName 'sc-1' -MarkerSuffix 'v1'
        $area = script:New-InstallArea -CaseName 'sc-1'
        $proj = script:New-ProjectRoot -CaseName 'sc-1'

        script:Invoke-InstallPipeline -Params @{
            Action='install'; InstallArea=$area; InstallMode='local-clone';
            SourcePath=$src.Root; Branch='main'; Remote='origin';
            ProjectRoot=$proj; RuntimeToolRoot=$proj
        } | Out-Null

        $other = Join-Path $TestDrive 'other-src-sc-1'
        $null = New-Item -ItemType Directory -Path $other -Force

        $r = script:Invoke-InstallPipeline -Params @{
            Action='update-current'; InstallArea=$area; SourcePath=$other;
            ProjectRoot=$proj; RuntimeToolRoot=$proj
        }
        $r.ExitCode | Should -Not -Be 0
        $r.Output   | Should -Match 'source-cut detected'
    }

    It 'AC-IP-DOG-ENTRY-1: update-source refused when source equals dogfooding ProjectRoot' {
        # Set up a single dir that is both source repo (multi-marker) AND ProjectRoot
        $shared = Join-Path $TestDrive 'dogfood-entry-1'
        $null = New-Item -ItemType Directory -Path $shared -Force
        # Add .git so Get-ProjectRoot does not warn
        $null = New-Item -ItemType Directory -Path (Join-Path $shared '.git') -Force
        Push-Location $shared
        try {
            & git init -q 2>&1 | Out-Null
            & git config user.email 'test@example.com' 2>&1 | Out-Null
            & git config user.name  'test' 2>&1 | Out-Null
            $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
            foreach ($r in 'config','scripts','snippets','templates') {
                $null = New-Item -ItemType Directory -Path (Join-Path $shared $r) -Force
                [System.IO.File]::WriteAllText((Join-Path $shared "$r/marker.txt"), "marker-$r-v1", $utf8NoBom)
            }
            # Multi-marker for source-repo detection.
            [System.IO.File]::WriteAllText((Join-Path $shared 'scripts/verify-ps1.ps1'),    '# marker', $utf8NoBom)
            [System.IO.File]::WriteAllText((Join-Path $shared 'templates/review-input.md'), '# marker', $utf8NoBom)
            [System.IO.File]::WriteAllText((Join-Path $shared 'config/reviewer.json'),      '{}',       $utf8NoBom)
            & git add . 2>&1 | Out-Null
            & git commit -q -m 'seed' 2>&1 | Out-Null
        }
        finally { Pop-Location }

        $area = script:New-InstallArea -CaseName 'dogfood-entry-1'

        # First install must succeed (install does not trigger dogfooding guard).
        script:Invoke-InstallPipeline -Params @{
            Action='install'; InstallArea=$area; InstallMode='local-clone';
            SourcePath=$shared; Branch='main'; Remote='origin';
            ProjectRoot=$shared; RuntimeToolRoot=$shared
        } | Out-Null

        # update-source against the same dogfooding source must be refused.
        $r = script:Invoke-InstallPipeline -Params @{
            Action='update-source'; InstallArea=$area; SourcePath=$shared;
            ProjectRoot=$shared; RuntimeToolRoot=$shared
        }
        $r.ExitCode | Should -Not -Be 0
        $r.Output   | Should -Match 'dogfooding source'
    }
}

Describe 'install-pipeline entry — source-repo marker validation (F1)' {
    It 'AC-IP-MARKER-1: install rejects local-clone sourcePath lacking D3 multi-marker' {
        $src  = script:New-FixtureSourceRepo -CaseName 'marker-1' -MarkerSuffix 'v1' -WithoutSourceRepoMarkers
        $area = script:New-InstallArea -CaseName 'marker-1'
        $proj = script:New-ProjectRoot -CaseName 'marker-1'

        $r = script:Invoke-InstallPipeline -Params @{
            Action='install'; InstallArea=$area; InstallMode='local-clone';
            SourcePath=$src.Root; Branch='main'; Remote='origin';
            ProjectRoot=$proj; RuntimeToolRoot=$proj
        }
        $r.ExitCode | Should -Not -Be 0
        $r.Output   | Should -Match 'multi-marker check failed'

        # current/ must not be created on rejection.
        Test-Path -LiteralPath (Join-Path $area 'current') | Should -BeFalse
    }
}

Describe 'install-pipeline library — fail-fast missing metadata before materialization (F2)' {
    It 'AC-IP-FAILFAST-1: dispatcher rejects update-* with missing metadata BEFORE wiping current/' {
        $area = script:New-InstallArea -CaseName 'failfast-1'
        $curr = Join-Path $area 'current'
        $sentinelDir = Join-Path $curr 'config'
        $null = New-Item -ItemType Directory -Path $sentinelDir -Force
        $sentinelFile = Join-Path $sentinelDir 'sentinel.txt'
        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($sentinelFile, 'preserve-me', $utf8NoBom)

        $src  = script:New-FixtureSourceRepo -CaseName 'failfast-1' -MarkerSuffix 'v1'
        $proj = script:New-ProjectRoot -CaseName 'failfast-1'

        $tuple = New-InstallPipelineTuple `
            -Action 'update-current' `
            -InstallMode 'local-clone' `
            -SourceLocation $src.Root `
            -ResolvedRefSha $src.Head `
            -RefKind 'commit' `
            -ToolRoot $src.Root `
            -ProjectRoot $proj `
            -SourceUpdatePolicy 'read-current-only'

        { Invoke-InstallPipelineDispatch -Tuple $tuple -InstallArea $area } |
            Should -Throw -ExpectedMessage '*requires existing install metadata*'

        # Sentinel must still be intact — fail-fast happened BEFORE materialization.
        Test-Path -LiteralPath $sentinelFile -PathType Leaf | Should -BeTrue
        [System.IO.File]::ReadAllText($sentinelFile, $utf8NoBom) | Should -Be 'preserve-me'
    }
}

Describe 'install-pipeline entry — forbidden InstallArea / required inputs' {
    It 'AC-IP-FORBID-1: InstallArea pointing at user .claude is refused' {
        $userProfile = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::UserProfile)
        $forbidden = Join-Path $userProfile '.claude'
        $src = script:New-FixtureSourceRepo -CaseName 'forbid-1' -MarkerSuffix 'v1'
        $proj = script:New-ProjectRoot -CaseName 'forbid-1'

        $r = script:Invoke-InstallPipeline -Params @{
            Action='install'; InstallArea=$forbidden; InstallMode='local-clone';
            SourcePath=$src.Root; ProjectRoot=$proj; RuntimeToolRoot=$proj
        }
        $r.ExitCode | Should -Not -Be 0
        $r.Output   | Should -Match 'forbidden'
    }

    It 'AC-IP-REQ-1: update/restore without metadata fails fast' {
        $area = script:New-InstallArea -CaseName 'req-1'
        $proj = script:New-ProjectRoot -CaseName 'req-1'
        $src = script:New-FixtureSourceRepo -CaseName 'req-1' -MarkerSuffix 'v1'

        $r = script:Invoke-InstallPipeline -Params @{
            Action='update-current'; InstallArea=$area; SourcePath=$src.Root;
            ProjectRoot=$proj; RuntimeToolRoot=$proj
        }
        $r.ExitCode | Should -Not -Be 0
        $r.Output   | Should -Match 'requires existing install metadata'
    }
}

Describe 'install-pipeline 3-7 dry-run coverage extension' {
    It 'AC-IP-FLOW-1: install -> update-current -> restore sequential flow + per-step metadata + content' {
        $src  = script:New-FixtureSourceRepo -CaseName 'flow-1' -MarkerSuffix 'v1'
        $area = script:New-InstallArea -CaseName 'flow-1'
        $proj = script:New-ProjectRoot -CaseName 'flow-1'
        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        $markerPath = Join-Path $area 'current/config/marker.txt'

        # 1) install at v1.
        $r1 = script:Invoke-InstallPipeline -Params @{
            Action='install'; InstallArea=$area; InstallMode='local-clone';
            SourcePath=$src.Root; Branch='main'; Remote='origin';
            ProjectRoot=$proj; RuntimeToolRoot=$proj
        }
        $r1.ExitCode | Should -Be 0 -Because $r1.Output
        $md1 = script:Read-MetadataFromArea -InstallArea $area
        $md1.installedHead   | Should -Be $src.Head
        $md1.lastUpdatedHead | Should -Be $src.Head
        $installedAt1   = $md1.installedAt
        $lastUpdatedAt1 = $md1.lastUpdatedAt
        $md1.installedAt | Should -Be $md1.lastUpdatedAt   # install sets both to the same UTC stamp
        [System.IO.File]::ReadAllText($markerPath, $utf8NoBom) | Should -Be 'marker-config-v1'

        # 2) source advances to v2; update-current adopts it.
        Start-Sleep -Milliseconds 1100  # ensure lastUpdatedAt resolution differs
        $headV2 = script:Add-FixtureCommit -SourceRoot $src.Root -MarkerSuffix 'v2'

        $r2 = script:Invoke-InstallPipeline -Params @{
            Action='update-current'; InstallArea=$area; SourcePath=$src.Root;
            ProjectRoot=$proj; RuntimeToolRoot=$proj
        }
        $r2.ExitCode | Should -Be 0 -Because $r2.Output
        $md2 = script:Read-MetadataFromArea -InstallArea $area
        $md2.installedHead   | Should -Be $src.Head             # install root preserved
        $md2.installedAt     | Should -Be $installedAt1         # install timestamp preserved
        $md2.lastUpdatedHead | Should -Be $headV2               # head advanced
        # §11.5: update refreshes lastUpdatedAt. ISO 8601 UTC stamps compare correctly as strings.
        $md2.lastUpdatedAt | Should -Not -Be $lastUpdatedAt1
        ($md2.lastUpdatedAt -gt $lastUpdatedAt1) | Should -BeTrue -Because 'update-current must advance lastUpdatedAt forward'
        $lastUpdatedAt2 = $md2.lastUpdatedAt
        [System.IO.File]::ReadAllText($markerPath, $utf8NoBom) | Should -Be 'marker-config-v2'

        # 3) restore to v1 (user-specified ref); content rolls back, installedHead still preserved.
        Start-Sleep -Milliseconds 1100
        $r3 = script:Invoke-InstallPipeline -Params @{
            Action='restore'; InstallArea=$area; SourcePath=$src.Root; Ref=$src.Head;
            ProjectRoot=$proj; RuntimeToolRoot=$proj
        }
        $r3.ExitCode | Should -Be 0 -Because $r3.Output
        $md3 = script:Read-MetadataFromArea -InstallArea $area
        $md3.installedHead   | Should -Be $src.Head             # still preserved
        $md3.installedAt     | Should -Be $installedAt1         # still preserved
        $md3.lastUpdatedHead | Should -Be $src.Head             # rolled back to v1
        # §11.5: restore (option b) refreshes lastUpdatedAt after successful re-materialization.
        $md3.lastUpdatedAt | Should -Not -Be $lastUpdatedAt2
        ($md3.lastUpdatedAt -gt $lastUpdatedAt2) | Should -BeTrue -Because 'restore must advance lastUpdatedAt forward even when rolling content back'
        [System.IO.File]::ReadAllText($markerPath, $utf8NoBom) | Should -Be 'marker-config-v1'

        # Invariants across the entire sequence: identity / footprint / managedBy fields must not drift.
        foreach ($pair in @(@($md1, $md2), @($md2, $md3))) {
            $a, $b = $pair
            $b.schemaVersion         | Should -Be $a.schemaVersion
            $b.tool                  | Should -Be $a.tool
            $b.installMode           | Should -Be $a.installMode
            $b.sourcePath            | Should -Be $a.sourcePath
            $b.toolRoot              | Should -Be $a.toolRoot
            $b.branch                | Should -Be $a.branch
            $b.remote                | Should -Be $a.remote
            $b.targetFootprintPolicy | Should -Be $a.targetFootprintPolicy
            $b.managedBy             | Should -Be $a.managedBy
        }
    }

    It 'AC-IP-SOURCE-CUT-2: source-cut rejection preserves existing current/ payload (no mutation)' {
        $src  = script:New-FixtureSourceRepo -CaseName 'sc-2' -MarkerSuffix 'v1'
        $area = script:New-InstallArea -CaseName 'sc-2'
        $proj = script:New-ProjectRoot -CaseName 'sc-2'
        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)

        $r1 = script:Invoke-InstallPipeline -Params @{
            Action='install'; InstallArea=$area; InstallMode='local-clone';
            SourcePath=$src.Root; Branch='main'; Remote='origin';
            ProjectRoot=$proj; RuntimeToolRoot=$proj
        }
        $r1.ExitCode | Should -Be 0 -Because $r1.Output

        # Snapshot current/ payload before triggering source-cut.
        $currentDir = Join-Path $area 'current'
        $beforeFiles = Get-ChildItem -LiteralPath $currentDir -Recurse -File | Sort-Object FullName
        $beforeMap = @{}
        foreach ($f in $beforeFiles) {
            $rel = $f.FullName.Substring($currentDir.Length + 1).Replace('\','/')
            $beforeMap[$rel] = [System.IO.File]::ReadAllBytes($f.FullName)
        }

        # Trigger source-cut: invocation sourcePath differs from metadata.sourcePath.
        $other = Join-Path $TestDrive 'sc-2-other'
        $null = New-Item -ItemType Directory -Path $other -Force
        $r2 = script:Invoke-InstallPipeline -Params @{
            Action='update-current'; InstallArea=$area; SourcePath=$other;
            ProjectRoot=$proj; RuntimeToolRoot=$proj
        }
        $r2.ExitCode | Should -Not -Be 0
        $r2.Output   | Should -Match 'source-cut detected'

        # current/ payload must be byte-identical to the pre-rejection snapshot.
        $afterFiles = Get-ChildItem -LiteralPath $currentDir -Recurse -File | Sort-Object FullName
        $afterFiles.Count | Should -Be $beforeFiles.Count
        foreach ($f in $afterFiles) {
            $rel = $f.FullName.Substring($currentDir.Length + 1).Replace('\','/')
            $beforeMap.ContainsKey($rel) | Should -BeTrue -Because "unexpected file appeared: $rel"
            $beforeBytes = $beforeMap[$rel]
            $afterBytes  = [System.IO.File]::ReadAllBytes($f.FullName)
            $afterBytes.Length | Should -Be $beforeBytes.Length -Because "size mismatch in $rel"
            $hashBefore = [System.BitConverter]::ToString([System.Security.Cryptography.SHA256]::Create().ComputeHash($beforeBytes))
            $hashAfter  = [System.BitConverter]::ToString([System.Security.Cryptography.SHA256]::Create().ComputeHash($afterBytes))
            $hashAfter | Should -Be $hashBefore -Because "content mismatch in $rel"
        }
    }

    It 'AC-IP-DOG-ENTRY-2: dogfooding update-source rejection does not mutate the source repo HEAD' {
        # Source = ProjectRoot = ai-harness multi-marker source repo.
        $shared = Join-Path $TestDrive 'dog-2-shared'
        $null = New-Item -ItemType Directory -Path $shared -Force
        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        Push-Location $shared
        try {
            & git init -q 2>&1 | Out-Null
            & git config core.autocrlf false 2>&1 | Out-Null
            & git config core.safecrlf false 2>&1 | Out-Null
            & git config user.email 'test@example.com' 2>&1 | Out-Null
            & git config user.name  'test' 2>&1 | Out-Null
            foreach ($r in 'config','scripts','snippets','templates') {
                $null = New-Item -ItemType Directory -Path (Join-Path $shared $r) -Force
                [System.IO.File]::WriteAllText((Join-Path $shared "$r/marker.txt"), "marker-$r-v1", $utf8NoBom)
            }
            [System.IO.File]::WriteAllText((Join-Path $shared 'scripts/verify-ps1.ps1'),    '# marker', $utf8NoBom)
            [System.IO.File]::WriteAllText((Join-Path $shared 'templates/review-input.md'), '# marker', $utf8NoBom)
            [System.IO.File]::WriteAllText((Join-Path $shared 'config/reviewer.json'),      '{}',       $utf8NoBom)
            & git add . 2>&1 | Out-Null
            & git commit -q -m 'seed' 2>&1 | Out-Null
            $script:DogHeadBefore = (& git rev-parse HEAD 2>&1 | Out-String).Trim()
            $script:DogStatusBefore = ((& git status --porcelain=v1 2>&1) -join "`n").Trim()
        }
        finally { Pop-Location }

        $area = script:New-InstallArea -CaseName 'dog-2'

        # Install must succeed (install action does not trigger the dogfooding guard).
        script:Invoke-InstallPipeline -Params @{
            Action='install'; InstallArea=$area; InstallMode='local-clone';
            SourcePath=$shared; Branch='main'; Remote='origin';
            ProjectRoot=$shared; RuntimeToolRoot=$shared
        } | Out-Null

        # Now attempt update-source with the dogfooding source — must be refused.
        $r = script:Invoke-InstallPipeline -Params @{
            Action='update-source'; InstallArea=$area; SourcePath=$shared;
            ProjectRoot=$shared; RuntimeToolRoot=$shared
        }
        $r.ExitCode | Should -Not -Be 0
        $r.Output   | Should -Match 'dogfooding source'

        # Source repo HEAD and working tree must be unchanged.
        Push-Location $shared
        try {
            $headAfter   = (& git rev-parse HEAD 2>&1 | Out-String).Trim()
            $statusAfter = ((& git status --porcelain=v1 2>&1) -join "`n").Trim()
        }
        finally { Pop-Location }
        $headAfter   | Should -Be $script:DogHeadBefore
        $statusAfter | Should -Be $script:DogStatusBefore
    }

    It 'AC-IP-FORBID-2: InstallArea pointing at %USERPROFILE%\.codex is refused' {
        $userProfile = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::UserProfile)
        $forbidden = Join-Path $userProfile '.codex'
        $src  = script:New-FixtureSourceRepo -CaseName 'forbid-2' -MarkerSuffix 'v1'
        $proj = script:New-ProjectRoot -CaseName 'forbid-2'

        $r = script:Invoke-InstallPipeline -Params @{
            Action='install'; InstallArea=$forbidden; InstallMode='local-clone';
            SourcePath=$src.Root; ProjectRoot=$proj; RuntimeToolRoot=$proj
        }
        $r.ExitCode | Should -Not -Be 0
        $r.Output   | Should -Match 'forbidden'
    }

    It 'AC-IP-FORBID-3: InstallArea descendant of %USERPROFILE%\.claude is refused' {
        $userProfile = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::UserProfile)
        $forbidden = Join-Path (Join-Path $userProfile '.claude') 'pester-install-pipeline-forbid-3'
        $src  = script:New-FixtureSourceRepo -CaseName 'forbid-3' -MarkerSuffix 'v1'
        $proj = script:New-ProjectRoot -CaseName 'forbid-3'

        $r = script:Invoke-InstallPipeline -Params @{
            Action='install'; InstallArea=$forbidden; InstallMode='local-clone';
            SourcePath=$src.Root; ProjectRoot=$proj; RuntimeToolRoot=$proj
        }
        $r.ExitCode | Should -Not -Be 0
        $r.Output   | Should -Match 'forbidden'
        # The forbidden path must not have been created by the rejected run.
        Test-Path -LiteralPath $forbidden | Should -BeFalse
    }
}
