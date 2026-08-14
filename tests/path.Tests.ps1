Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

BeforeAll {
    $script:RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).ProviderPath
    $script:PathLib  = Join-Path $script:RepoRoot 'scripts/lib/path.ps1'

    . $script:PathLib

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

    function script:New-CaseDir {
        param([string] $Name)
        $p = Join-Path $TestDrive ('pester-path-' + $Name)
        if (Test-Path -LiteralPath $p) {
            Remove-Item -LiteralPath $p -Recurse -Force
        }
        $null = New-Item -ItemType Directory -Path $p -Force
        return ([System.IO.Path]::GetFullPath($p))
    }

    function script:New-TestJunction {
        param(
            [string] $LinkPath,
            [string] $TargetPath
        )

        $parent = Split-Path -LiteralPath $LinkPath
        if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
            $null = New-Item -ItemType Directory -Path $parent -Force
        }
        $null = New-Item -ItemType Junction -Path $LinkPath -Target $TargetPath -ErrorAction Stop
        $item = Get-Item -LiteralPath $LinkPath -Force -ErrorAction Stop
        if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -eq 0) {
            throw "New-TestJunction: created path is not a reparse point: $LinkPath"
        }
        return $item.FullName
    }

    function script:Try-NewTestFileSymbolicLink {
        param(
            [string] $LinkPath,
            [string] $TargetPath
        )

        try {
            $null = New-Item -ItemType SymbolicLink -Path $LinkPath -Target $TargetPath -ErrorAction Stop
            $item = Get-Item -LiteralPath $LinkPath -Force -ErrorAction Stop
            return (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0)
        }
        catch {
            Remove-Item -LiteralPath $LinkPath -Force -ErrorAction SilentlyContinue
            return $false
        }
    }

    function script:New-MultiMarkerSourceRepo {
        param([string] $Name)
        $root = script:New-CaseDir -Name $Name
        script:Write-Utf8NoBomFile -Path (Join-Path $root 'scripts/verify-ps1.ps1') -Content "# fake`n"
        script:Write-Utf8NoBomFile -Path (Join-Path $root 'templates/review-input.md') -Content "# fake`n"
        script:Write-Utf8NoBomFile -Path (Join-Path $root 'config/reviewer.json') -Content "{}`n"
        return $root
    }

    function script:New-StableInstall {
        # Builds a channel-3 global stable install dir. With -Valid it carries the
        # canonical entrypoint scripts/review-prepare.ps1 (a complete payload);
        # without it the directory exists but the payload is incomplete.
        param(
            [string] $Name,
            [switch] $Valid
        )
        $root = script:New-CaseDir -Name $Name
        if ($Valid) {
            script:Write-Utf8NoBomFile -Path (Join-Path $root 'scripts/review-prepare.ps1') -Content "# fake entrypoint`n"
        }
        return $root
    }

    function script:AbsentStablePath {
        # A path under TestDrive that is intentionally never created, so the
        # channel-3 global stable install is deterministically absent regardless
        # of the host machine's real %USERPROFILE%\.claude state.
        return ([System.IO.Path]::GetFullPath((Join-Path $TestDrive 'pester-path-absent-stable-NEVER')))
    }

    function script:Clear-EnvToolRoot {
        $env:AI_HARNESS_TOOL_ROOT = $null
    }
}

Describe 'Test-IsSourceRepoRoot multi-marker (D3)' {
    BeforeEach { script:Clear-EnvToolRoot }

    It 'AC-PATH-D3-1: returns true only when all three markers exist' {
        $root = script:New-MultiMarkerSourceRepo -Name 'd3-all-three'
        Test-IsSourceRepoRoot -Path $root | Should -BeTrue
    }

    It 'AC-PATH-D3-2: returns false when scripts/verify-ps1.ps1 is missing' {
        $root = script:New-MultiMarkerSourceRepo -Name 'd3-missing-scripts'
        Remove-Item -LiteralPath (Join-Path $root 'scripts/verify-ps1.ps1') -Force
        Test-IsSourceRepoRoot -Path $root | Should -BeFalse
    }

    It 'AC-PATH-D3-3: returns false when templates/review-input.md is missing' {
        $root = script:New-MultiMarkerSourceRepo -Name 'd3-missing-template'
        Remove-Item -LiteralPath (Join-Path $root 'templates/review-input.md') -Force
        Test-IsSourceRepoRoot -Path $root | Should -BeFalse
    }

    It 'AC-PATH-D3-4: returns false when config/reviewer.json is missing' {
        $root = script:New-MultiMarkerSourceRepo -Name 'd3-missing-config'
        Remove-Item -LiteralPath (Join-Path $root 'config/reviewer.json') -Force
        Test-IsSourceRepoRoot -Path $root | Should -BeFalse
    }

    It 'AC-PATH-D3-5: returns false when only legacy single marker exists' {
        $root = script:New-CaseDir -Name 'd3-legacy-only'
        script:Write-Utf8NoBomFile -Path (Join-Path $root 'scripts/verify-ps1.ps1') -Content "# fake`n"
        Test-IsSourceRepoRoot -Path $root | Should -BeFalse
    }
}

Describe 'Get-StableInstallAreaCandidate / Get-StableToolRootCandidate (vendor-neutral relocation)' {
    BeforeEach { script:Clear-EnvToolRoot }

    It 'AC-PATH-AREA-1: install area candidate is %USERPROFILE%\ai-harness-toolset (not under .claude)' {
        $userProfile = $env:USERPROFILE
        $area = Get-StableInstallAreaCandidate
        $expected = [System.IO.Path]::GetFullPath((Join-Path $userProfile 'ai-harness-toolset'))
        $area | Should -Be $expected
        (Split-Path -Leaf $area) | Should -Be 'ai-harness-toolset'
        # The install area is a DIRECT child of the user profile — its parent is NOT .claude.
        (Split-Path -Leaf (Split-Path -Parent $area)) | Should -Not -Be '.claude'
    }

    It 'AC-PATH-AREA-1b: install area candidate is derived from $env:USERPROFILE (lower-level test seam)' {
        # The canonical area reads $env:USERPROFILE (the same base every wrapper uses for its homes), so
        # a child process with an overridden %USERPROFILE% resolves a sandbox canonical area — this is
        # the ONLY isolation seam (there is no operator-facing override parameter).
        $orig = $env:USERPROFILE
        try {
            $sandbox = [System.IO.Path]::GetFullPath((Join-Path $TestDrive 'seam-userprofile'))
            $env:USERPROFILE = $sandbox
            $area = Get-StableInstallAreaCandidate
            $area | Should -Be ([System.IO.Path]::GetFullPath((Join-Path $sandbox 'ai-harness-toolset')))
            # ToolRoot derivation follows the overridden base too.
            (Get-StableToolRootCandidate) | Should -Be ([System.IO.Path]::GetFullPath((Join-Path $sandbox 'ai-harness-toolset/current')))
        }
        finally {
            $env:USERPROFILE = $orig
        }
    }

    It 'AC-PATH-AREA-2: stable ToolRoot candidate derives from the install area + current (single definition)' {
        $area = Get-StableInstallAreaCandidate
        $tool = Get-StableToolRootCandidate
        $tool | Should -Be ([System.IO.Path]::GetFullPath((Join-Path $area 'current')))
        (Split-Path -Leaf $tool) | Should -Be 'current'
        # ToolRoot is exactly <install area>\current — derived from the area, not independently defined.
        (Split-Path -Parent $tool) | Should -Be $area
    }
}

Describe 'Get-ToolRoot channel 1 (explicit -ToolRoot)' {
    BeforeEach { script:Clear-EnvToolRoot }

    It 'AC-PATH-CH1-1: returns explicit ToolRoot when directory exists' {
        $tool = script:New-CaseDir -Name 'ch1-ok'
        $project = script:New-CaseDir -Name 'ch1-ok-project'
        $result = Get-ToolRoot -ToolRoot $tool -ProjectRoot $project
        $result.TrimEnd('/','\') | Should -Be ($tool.TrimEnd('/','\'))
    }

    It 'AC-PATH-CH1-2: throws when explicit ToolRoot does not exist' {
        $project = script:New-CaseDir -Name 'ch1-missing-project'
        $bogus = Join-Path $TestDrive 'pester-path-ch1-missing-tool-NOPE'
        $threw = $false
        $msg = ''
        try {
            Get-ToolRoot -ToolRoot $bogus -ProjectRoot $project | Out-Null
        }
        catch {
            $threw = $true
            $msg = [string]$_.Exception.Message
        }
        $threw | Should -BeTrue
        $msg | Should -Match 'channel 1'
        $msg | Should -Match '-ToolRoot'
        $msg | Should -Match 'not found'
    }

    It 'AC-PATH-CH1-3: explicit ToolRoot wins over env var' {
        $explicitTool = script:New-CaseDir -Name 'ch1-explicit-wins-tool'
        $envTool      = script:New-CaseDir -Name 'ch1-explicit-wins-env'
        $env:AI_HARNESS_TOOL_ROOT = $envTool
        try {
            $project = script:New-CaseDir -Name 'ch1-explicit-wins-project'
            $result = Get-ToolRoot -ToolRoot $explicitTool -ProjectRoot $project
            $result.TrimEnd('/','\') | Should -Be ($explicitTool.TrimEnd('/','\'))
        }
        finally {
            $env:AI_HARNESS_TOOL_ROOT = $null
        }
    }
}

Describe 'Get-ToolRoot channel 2 (env AI_HARNESS_TOOL_ROOT)' {
    BeforeEach { script:Clear-EnvToolRoot }

    It 'AC-PATH-CH2-1: returns env ToolRoot when set and directory exists' {
        $envTool = script:New-CaseDir -Name 'ch2-ok-env'
        $project = script:New-CaseDir -Name 'ch2-ok-project'
        $env:AI_HARNESS_TOOL_ROOT = $envTool
        try {
            $result = Get-ToolRoot -ProjectRoot $project
            $result.TrimEnd('/','\') | Should -Be ($envTool.TrimEnd('/','\'))
        }
        finally {
            $env:AI_HARNESS_TOOL_ROOT = $null
        }
    }

    It 'AC-PATH-CH2-2: throws when env AI_HARNESS_TOOL_ROOT points at missing directory' {
        $project = script:New-CaseDir -Name 'ch2-missing-project'
        $bogus = Join-Path $TestDrive 'pester-path-ch2-missing-env-NOPE'
        $env:AI_HARNESS_TOOL_ROOT = $bogus
        $threw = $false
        $msg = ''
        try {
            try {
                Get-ToolRoot -ProjectRoot $project | Out-Null
            }
            catch {
                $threw = $true
                $msg = [string]$_.Exception.Message
            }
        }
        finally {
            $env:AI_HARNESS_TOOL_ROOT = $null
        }
        $threw | Should -BeTrue
        $msg | Should -Match 'channel 2'
        $msg | Should -Match 'AI_HARNESS_TOOL_ROOT'
        $msg | Should -Match 'not found'
    }

    It 'AC-PATH-CH2-3: env wins over dogfooding marker' {
        $envTool = script:New-CaseDir -Name 'ch2-env-wins-tool'
        $project = script:New-MultiMarkerSourceRepo -Name 'ch2-env-wins-project'
        $env:AI_HARNESS_TOOL_ROOT = $envTool
        try {
            $result = Get-ToolRoot -ProjectRoot $project
            $result.TrimEnd('/','\') | Should -Be ($envTool.TrimEnd('/','\'))
        }
        finally {
            $env:AI_HARNESS_TOOL_ROOT = $null
        }
    }
}

Describe 'Get-ToolRoot channel 3 (global stable install)' {
    BeforeEach { script:Clear-EnvToolRoot }

    It 'AC-PATH-CH3-1: returns stable ToolRoot when present and payload is valid' {
        $stable  = script:New-StableInstall -Name 'ch3-valid' -Valid
        $project = script:New-CaseDir -Name 'ch3-valid-project'
        $result = Get-ToolRoot -ProjectRoot $project -StableToolRoot $stable
        $result.TrimEnd('/','\') | Should -Be ($stable.TrimEnd('/','\'))
    }

    It 'AC-PATH-CH3-2: absent stable directory skips to the dogfooding fallback' {
        $stableAbsent = script:AbsentStablePath
        $project = script:New-MultiMarkerSourceRepo -Name 'ch3-absent-skips'
        # channel 3 absent -> channel 4 dogfooding resolves.
        $result = Get-ToolRoot -ProjectRoot $project -StableToolRoot $stableAbsent
        $result.TrimEnd('/','\') | Should -Be ($project.TrimEnd('/','\'))
    }

    It 'AC-PATH-CH3-3: present-but-incomplete stable payload fails fast with a clear diagnostic' {
        $stableInvalid = script:New-StableInstall -Name 'ch3-incomplete'   # no scripts/review-prepare.ps1
        # Project IS a valid dogfooding repo, proving channel 3 fails fast rather
        # than silently skipping to an available channel-4 fallback.
        $project = script:New-MultiMarkerSourceRepo -Name 'ch3-incomplete-project'
        $threw = $false
        $msg = ''
        try {
            Get-ToolRoot -ProjectRoot $project -StableToolRoot $stableInvalid | Out-Null
        }
        catch {
            $threw = $true
            $msg = [string]$_.Exception.Message
        }
        $threw | Should -BeTrue -Because 'an existing but incomplete stable payload must fail fast, not silently skip'
        $msg | Should -Match 'channel 3'
        $msg | Should -Match 'payload is incomplete'
        $msg | Should -Match 'review-prepare\.ps1'
        $msg | Should -Match ([regex]::Escape($stableInvalid))
    }

    It 'AC-PATH-CH3-4: env var (channel 2) overrides the stable channel' {
        $envTool = script:New-CaseDir -Name 'ch3-env-overrides-env'
        $stable  = script:New-StableInstall -Name 'ch3-env-overrides-stable' -Valid
        $project = script:New-CaseDir -Name 'ch3-env-overrides-project'
        $env:AI_HARNESS_TOOL_ROOT = $envTool
        try {
            $result = Get-ToolRoot -ProjectRoot $project -StableToolRoot $stable
            $result.TrimEnd('/','\') | Should -Be ($envTool.TrimEnd('/','\'))
        }
        finally {
            $env:AI_HARNESS_TOOL_ROOT = $null
        }
    }

    It 'AC-PATH-CH3-5: explicit -ToolRoot (channel 1) overrides the stable channel' {
        $explicitTool = script:New-CaseDir -Name 'ch3-param-overrides-tool'
        $stable       = script:New-StableInstall -Name 'ch3-param-overrides-stable' -Valid
        $project      = script:New-CaseDir -Name 'ch3-param-overrides-project'
        $result = Get-ToolRoot -ToolRoot $explicitTool -ProjectRoot $project -StableToolRoot $stable
        $result.TrimEnd('/','\') | Should -Be ($explicitTool.TrimEnd('/','\'))
    }

    It 'AC-PATH-CH3-6: stable channel wins over the dogfooding multi-marker (channel 4)' {
        $stable  = script:New-StableInstall -Name 'ch3-wins-over-dogfood-stable' -Valid
        $project = script:New-MultiMarkerSourceRepo -Name 'ch3-wins-over-dogfood-project'
        $result = Get-ToolRoot -ProjectRoot $project -StableToolRoot $stable
        $result.TrimEnd('/','\') | Should -Be ($stable.TrimEnd('/','\'))
    }
}

Describe 'Get-ToolRoot channel 4 (dogfooding multi-marker)' {
    BeforeEach { script:Clear-EnvToolRoot }

    It 'AC-PATH-CH4-1: returns ProjectRoot when all three markers present' {
        $project = script:New-MultiMarkerSourceRepo -Name 'ch4-multi-marker'
        $result = Get-ToolRoot -ProjectRoot $project -StableToolRoot (script:AbsentStablePath)
        $result.TrimEnd('/','\') | Should -Be ($project.TrimEnd('/','\'))
    }

    It 'AC-PATH-CH4-2: does NOT match dogfooding when only single legacy marker present' {
        $project = script:New-CaseDir -Name 'ch4-single-marker'
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'scripts/verify-ps1.ps1') -Content "# fake`n"
        # Without all three markers and no other resolvable channel, the chain should throw.
        $threw = $false
        $msg = ''
        try {
            Get-ToolRoot -ProjectRoot $project -StableToolRoot (script:AbsentStablePath) | Out-Null
        }
        catch {
            $threw = $true
            $msg = [string]$_.Exception.Message
        }
        $threw | Should -BeTrue
        $msg | Should -Match 'no ToolRoot channel could be resolved'
        $msg | Should -Match 'channel 4'
    }
}

Describe 'Get-ToolRoot project-local payload is not a ToolRoot fallback (negative invariant)' {
    BeforeEach { script:Clear-EnvToolRoot }

    It 'AC-PATH-NOFB-1: a project-root child payload directory does NOT resolve as a ToolRoot fallback (throws)' {
        # No project-local payload directory is a ToolRoot source. Even if a target project
        # contains a child directory that looks like a copied tool payload (config/scripts/
        # templates under a child), Get-ToolRoot must NOT resolve to it -- project-root-based
        # implicit resolution is allowed ONLY via dogfooding source-repo markers AT the project
        # root (channel 4). A non-source-repo target therefore fails fast at the terminal.
        $project = script:New-CaseDir -Name 'nofb-payload-child'
        $payload = Join-Path $project 'some-local-payload'
        script:Write-Utf8NoBomFile -Path (Join-Path $payload 'scripts/verify-ps1.ps1') -Content "# fake`n"
        script:Write-Utf8NoBomFile -Path (Join-Path $payload 'templates/review-input.md') -Content "# fake`n"
        script:Write-Utf8NoBomFile -Path (Join-Path $payload 'config/reviewer.json') -Content "{}`n"
        $threw = $false
        $msg = ''
        try {
            Get-ToolRoot -ProjectRoot $project -StableToolRoot (script:AbsentStablePath) | Out-Null
        }
        catch {
            $threw = $true
            $msg = [string]$_.Exception.Message
        }
        $threw | Should -BeTrue -Because 'no project-local payload subdirectory is a ToolRoot fallback'
        $msg | Should -Match 'no ToolRoot channel could be resolved'
    }

    It 'AC-PATH-NOFB-2: dogfooding markers AT the project root resolve to the root, not to a payload child' {
        # The ONLY project-root-based implicit resolution is dogfooding: markers AT the project
        # root. A payload-like child dir present at the same time is never consulted -- channel 4
        # resolves to the root that carries the markers.
        $project = script:New-MultiMarkerSourceRepo -Name 'nofb-root-wins-over-child'
        $payload = Join-Path $project 'some-local-payload'
        script:Write-Utf8NoBomFile -Path (Join-Path $payload 'scripts/verify-ps1.ps1') -Content "# fake`n"
        $result = Get-ToolRoot -ProjectRoot $project -StableToolRoot (script:AbsentStablePath)
        $result.TrimEnd('/','\') | Should -Be ($project.TrimEnd('/','\'))
    }
}

Describe 'Get-ToolRoot channel 5 (no channel resolved / terminal)' {
    BeforeEach { script:Clear-EnvToolRoot }

    It 'AC-PATH-CH5-TERM-1: throws with channel trace listing all attempted channels (1..4)' {
        $project = script:New-CaseDir -Name 'ch5-empty-project'
        $threw = $false
        $msg = ''
        try {
            Get-ToolRoot -ProjectRoot $project -StableToolRoot (script:AbsentStablePath) | Out-Null
        }
        catch {
            $threw = $true
            $msg = [string]$_.Exception.Message
        }
        $threw | Should -BeTrue -Because 'no channel should resolve in an empty project'
        $msg | Should -Match 'channel 1'
        $msg | Should -Match 'channel 2'
        $msg | Should -Match 'channel 3'
        $msg | Should -Match 'channel 4'
        $msg | Should -Match 'AI_HARNESS_TOOL_ROOT'
        $msg | Should -Match '-ToolRoot'
    }
}

Describe 'Get-ToolRoot caller contract (callsite consumption)' {
    BeforeEach { script:Clear-EnvToolRoot }

    It 'AC-PATH-CALL-1: result is a single non-empty string (no array wrapping)' {
        $tool = script:New-CaseDir -Name 'call-string-tool'
        $project = script:New-CaseDir -Name 'call-string-project'
        $result = Get-ToolRoot -ToolRoot $tool -ProjectRoot $project
        $result | Should -BeOfType [string]
        [string]::IsNullOrEmpty($result) | Should -BeFalse
    }

    It 'AC-PATH-CALL-2: result is usable directly as a Join-Path base' {
        $project = script:New-MultiMarkerSourceRepo -Name 'call-joinpath-project'
        $result = Get-ToolRoot -ProjectRoot $project -StableToolRoot (script:AbsentStablePath)
        $joined = Join-Path -Path $result -ChildPath 'config/reviewer.json'
        Test-Path -LiteralPath $joined -PathType Leaf | Should -BeTrue
    }
}

Describe 'Get-ProjectRoot D9 CWD advisory' {
    It 'AC-PATH-D9-EXPLICIT-NO-WARN: no warning when -ProjectRoot is explicit (even without .git/)' {
        $project = script:New-CaseDir -Name 'd9-explicit-no-git'
        # No .git/ inside, but explicit -ProjectRoot path should suppress the advisory.
        $informational = (& {
            Get-ProjectRoot -ProjectRoot $project 6>&1
        } | Out-String -Width 8192)
        $flat = ($informational -replace "`r?`n", ' ')
        $flat | Should -Not -Match 'WARN ProjectRoot resolved to CWD'
    }

    It 'AC-PATH-D9-CWD-WITH-GIT-NO-WARN: no warning when CWD default and .git/ container exists' {
        $project = script:New-CaseDir -Name 'd9-cwd-with-git'
        $null = New-Item -ItemType Directory -Path (Join-Path $project '.git') -Force
        Push-Location -LiteralPath $project
        try {
            $informational = (& {
                Get-ProjectRoot 6>&1
            } | Out-String -Width 8192)
        }
        finally {
            Pop-Location
        }
        $flat = ($informational -replace "`r?`n", ' ')
        $flat | Should -Not -Match 'WARN ProjectRoot resolved to CWD'
    }

    It 'AC-PATH-D9-CWD-NO-GIT-WARN: warning when CWD default and .git/ missing; resolution still succeeds' {
        $project = script:New-CaseDir -Name 'd9-cwd-no-git'
        Push-Location -LiteralPath $project
        try {
            $informational = (& {
                Get-ProjectRoot 6>&1
            } | Out-String -Width 8192)
            $result = Get-ProjectRoot
        }
        finally {
            Pop-Location
        }
        $flat = ($informational -replace "`r?`n", ' ')
        $flat | Should -Match 'Get-ProjectRoot: WARN ProjectRoot resolved to CWD without a \.git entry'
        $flat | Should -Match ([regex]::Escape($project))
        # Resolution still succeeds and returns the project full path.
        $result | Should -BeOfType [string]
        ([System.IO.Path]::GetFullPath($result)).TrimEnd('/','\') | Should -Be ($project.TrimEnd('/','\'))
    }

    It 'AC-PATH-D9-CWD-WITH-GIT-FILE-NO-WARN: no warning when .git is a file pointer (git worktree / submodule)' {
        # .git file pointers are valid git evidence (e.g., worktrees, submodules);
        # the advisory accepts both directory and file forms.
        $project = script:New-CaseDir -Name 'd9-cwd-git-file'
        script:Write-Utf8NoBomFile -Path (Join-Path $project '.git') -Content "gitdir: ../somewhere/.git`n"
        Push-Location -LiteralPath $project
        try {
            $informational = (& {
                Get-ProjectRoot 6>&1
            } | Out-String -Width 8192)
        }
        finally {
            Pop-Location
        }
        $flat = ($informational -replace "`r?`n", ' ')
        $flat | Should -Not -Match 'Get-ProjectRoot: WARN'
    }
}

Describe 'Test-ValidPerspective (C1 perspective segment validation)' {
    BeforeEach { script:Clear-EnvToolRoot }

    It 'AC-PERSP-1: accepts the recommended perspective vocabulary' {
        Test-ValidPerspective -Value 'local-correctness' | Should -BeTrue
        Test-ValidPerspective -Value 'system-coherence' | Should -BeTrue
    }

    It 'AC-PERSP-2: accepts other safe single-segment names up to 64 chars' {
        Test-ValidPerspective -Value 'a'            | Should -BeTrue
        Test-ValidPerspective -Value 'review_1.2-x' | Should -BeTrue
        Test-ValidPerspective -Value ('a' * 64)     | Should -BeTrue
    }

    It 'AC-PERSP-3: rejects empty / null' {
        Test-ValidPerspective -Value ''    | Should -BeFalse
        Test-ValidPerspective -Value $null | Should -BeFalse
    }

    It 'AC-PERSP-4: rejects parent-dir traversal token' {
        Test-ValidPerspective -Value '..'        | Should -BeFalse
        Test-ValidPerspective -Value 'foo..bar'  | Should -BeFalse
        Test-ValidPerspective -Value '..\escape' | Should -BeFalse
    }

    It 'AC-PERSP-5: rejects path separators (forward and back slash)' {
        Test-ValidPerspective -Value 'foo/bar' | Should -BeFalse
        Test-ValidPerspective -Value 'foo\bar' | Should -BeFalse
        Test-ValidPerspective -Value '/abs'    | Should -BeFalse
    }

    It 'AC-PERSP-6: rejects the pass-NN shape (old/new ambiguity guard), case-insensitively' {
        Test-ValidPerspective -Value 'pass-01' | Should -BeFalse
        Test-ValidPerspective -Value 'pass-99' | Should -BeFalse
        Test-ValidPerspective -Value 'PASS-01' | Should -BeFalse
        Test-ValidPerspective -Value 'Pass-07' | Should -BeFalse
    }

    It 'AC-PERSP-6b: still allows pass-prefixed names that are not the two-digit pass shape' {
        Test-ValidPerspective -Value 'pass-review' | Should -BeTrue
        Test-ValidPerspective -Value 'pass-1'      | Should -BeTrue
        Test-ValidPerspective -Value 'passing'     | Should -BeTrue
    }

    It 'AC-PERSP-7: rejects over-length (> 64 chars)' {
        Test-ValidPerspective -Value ('a' * 65) | Should -BeFalse
    }

    It 'AC-PERSP-8: rejects invalid characters and a non-alphanumeric leading char' {
        Test-ValidPerspective -Value 'foo bar'  | Should -BeFalse
        Test-ValidPerspective -Value 'foo@bar'  | Should -BeFalse
        Test-ValidPerspective -Value '-leading' | Should -BeFalse
        Test-ValidPerspective -Value '.hidden'  | Should -BeFalse
    }

    It 'AC-PERSP-9: Assert-ValidPerspective throws on invalid, returns true on valid' {
        { Assert-ValidPerspective -Value '..' }      | Should -Throw
        { Assert-ValidPerspective -Value 'pass-01' } | Should -Throw
        Assert-ValidPerspective -Value 'local-correctness' | Should -BeTrue
    }
}

Describe 'Get-ReviewPassDir / Get-ReviewPassParent perspective-aware layout' {
    BeforeEach { script:Clear-EnvToolRoot }

    It 'AC-PERSP-PD1: omitted / empty perspective fails (strict C1 — no two-level fallback)' {
        $logRoot = script:New-CaseDir -Name 'persp-pd1'
        # Strict C1: the canonical layout is always three-level. Get-ReviewPassDir requires a
        # perspective; omitting it (empty string) fails validation rather than producing a
        # two-level path.
        { Get-ReviewPassDir -ProjectLogRoot $logRoot -ReviewTaskId 'task-x' -Pass 'pass-01' }                 | Should -Throw
        { Get-ReviewPassDir -ProjectLogRoot $logRoot -ReviewTaskId 'task-x' -Pass 'pass-01' -Perspective '' } | Should -Throw
    }

    It 'AC-PERSP-PD2: supplied perspective inserts a middle perspective segment (three-level)' {
        $logRoot = script:New-CaseDir -Name 'persp-pd2'
        $passDir = Get-ReviewPassDir -ProjectLogRoot $logRoot -ReviewTaskId 'task-x' -Pass 'pass-01' -Perspective 'local-correctness'
        $expected = [System.IO.Path]::GetFullPath((Join-Path $logRoot 'review/task-x/local-correctness/pass-01'))
        $passDir | Should -Be $expected
    }

    It 'AC-PERSP-PD3: Get-ReviewPassParent requires a perspective and returns task-plus-perspective' {
        $logRoot = script:New-CaseDir -Name 'persp-pd3'
        { Get-ReviewPassParent -ProjectLogRoot $logRoot -ReviewTaskId 'task-x' -Perspective '' } | Should -Throw
        $new = Get-ReviewPassParent -ProjectLogRoot $logRoot -ReviewTaskId 'task-x' -Perspective 'system-coherence'
        $new | Should -Be ([System.IO.Path]::GetFullPath((Join-Path $logRoot 'review/task-x/system-coherence')))
    }

    It 'AC-PERSP-PD4: invalid perspective is rejected before any path is built' {
        $logRoot = script:New-CaseDir -Name 'persp-pd4'
        { Get-ReviewPassDir -ProjectLogRoot $logRoot -ReviewTaskId 'task-x' -Pass 'pass-01' -Perspective '..' }      | Should -Throw
        { Get-ReviewPassDir -ProjectLogRoot $logRoot -ReviewTaskId 'task-x' -Pass 'pass-01' -Perspective 'a/b' }     | Should -Throw
        { Get-ReviewPassDir -ProjectLogRoot $logRoot -ReviewTaskId 'task-x' -Pass 'pass-01' -Perspective 'pass-02' } | Should -Throw
    }

    It 'AC-PERSP-PD5: an empty perspective fails (strict C1 removed the empty-as-omitted fallback)' {
        # Strict C1 removed empty-as-omitted: an empty perspective is rejected, never silently
        # resolved to the task dir / a two-level path.
        $logRoot = script:New-CaseDir -Name 'persp-pd5'
        { Get-ReviewPassParent -ProjectLogRoot $logRoot -ReviewTaskId 'task-x' -Perspective '' }              | Should -Throw
        { Get-ReviewPassDir -ProjectLogRoot $logRoot -ReviewTaskId 'task-x' -Pass 'pass-01' -Perspective '' } | Should -Throw
    }
}

Describe 'Assert-InTaskRoot task-root containment' {
    BeforeEach { script:Clear-EnvToolRoot }

    It 'AC-PERSP-TR1: accepts a pass dir under the intended task root (perspective child; legacy direct child)' {
        $logRoot = script:New-CaseDir -Name 'persp-tr1'
        # Assert-InTaskRoot is a layout-agnostic containment check: any path under <taskDir>/ is
        # accepted — the canonical perspective child, and also a legacy direct child (such a path
        # is no longer tool-created under strict C1, but containment itself does not depend on the
        # perspective segment).
        $direct = [System.IO.Path]::GetFullPath((Join-Path $logRoot 'review/task-x/pass-01'))
        Assert-InTaskRoot -Path $direct -ProjectLogRoot $logRoot -ReviewTaskId 'task-x' | Should -BeTrue
        $new = [System.IO.Path]::GetFullPath((Join-Path $logRoot 'review/task-x/local-correctness/pass-01'))
        Assert-InTaskRoot -Path $new -ProjectLogRoot $logRoot -ReviewTaskId 'task-x' | Should -BeTrue
    }

    It 'AC-PERSP-TR2: rejects a path inside review-root but in a DIFFERENT task (cross-task traversal)' {
        $logRoot = script:New-CaseDir -Name 'persp-tr2'
        # This path is under <logRoot>/review/ (passes review-root containment) but lives under a
        # sibling task, not task-x. Review-root prefix alone would accept it; task-root must reject —
        # this is exactly the gap the plan flags (review-root containment necessary, not sufficient).
        $sibling = [System.IO.Path]::GetFullPath((Join-Path $logRoot 'review/other-task/pass-01'))
        { Assert-InTaskRoot -Path $sibling -ProjectLogRoot $logRoot -ReviewTaskId 'task-x' } | Should -Throw
    }

    It 'AC-PERSP-TR3: rejects a task-name prefix sibling (task-x-evil is not under task-x)' {
        $logRoot = script:New-CaseDir -Name 'persp-tr3'
        $prefix = [System.IO.Path]::GetFullPath((Join-Path $logRoot 'review/task-x-evil/pass-01'))
        { Assert-InTaskRoot -Path $prefix -ProjectLogRoot $logRoot -ReviewTaskId 'task-x' } | Should -Throw
    }
}

Describe 'review campaign anchor and exclusive pass allocation' {
    BeforeEach { script:Clear-EnvToolRoot }

    It 'AC-CAM-PATH1: task root만으로는 anchor가 아니며 canonical input.md가 생기면 anchor가 된다' {
        $taskDir = script:New-CaseDir -Name 'campaign-anchor'

        Test-ReviewCampaignAnchor -TaskDir $taskDir | Should -BeFalse

        $orphanPass = Join-Path $taskDir 'local-correctness/pass-01'
        $null = [System.IO.Directory]::CreateDirectory($orphanPass)
        Test-ReviewCampaignAnchor -TaskDir $taskDir | Should -BeFalse

        script:Write-Utf8NoBomFile -Path (Join-Path $orphanPass 'input.md') -Content ''
        Test-ReviewCampaignAnchor -TaskDir $taskDir | Should -BeTrue
    }

    It 'AC-CAM-PATH1a: task root junction은 외부 canonical-looking input을 campaign anchor로 채택하지 않는다' {
        $caseRoot = script:New-CaseDir -Name 'campaign-anchor-task-reparse'
        $outsideTask = Join-Path $caseRoot 'outside-task'
        $outsidePass = Join-Path $outsideTask 'local-correctness/pass-01'
        $null = [System.IO.Directory]::CreateDirectory($outsidePass)
        script:Write-Utf8NoBomFile -Path (Join-Path $outsidePass 'input.md') -Content ''

        $taskLink = Join-Path $caseRoot 'task-link'
        $null = script:New-TestJunction -LinkPath $taskLink -TargetPath $outsideTask

        Test-ReviewCampaignAnchor -TaskDir $taskLink | Should -BeFalse
    }

    It 'AC-CAM-PATH1b: perspective 또는 pass junction 아래 input은 campaign anchor가 아니다' {
        $caseRoot = script:New-CaseDir -Name 'campaign-anchor-child-reparse'

        $perspectiveTask = Join-Path $caseRoot 'perspective-task'
        $null = [System.IO.Directory]::CreateDirectory($perspectiveTask)
        $outsidePerspective = Join-Path $caseRoot 'outside-perspective'
        $outsidePerspectivePass = Join-Path $outsidePerspective 'pass-01'
        $null = [System.IO.Directory]::CreateDirectory($outsidePerspectivePass)
        script:Write-Utf8NoBomFile -Path (Join-Path $outsidePerspectivePass 'input.md') -Content ''
        $null = script:New-TestJunction `
            -LinkPath (Join-Path $perspectiveTask 'local-correctness') `
            -TargetPath $outsidePerspective
        Test-ReviewCampaignAnchor -TaskDir $perspectiveTask | Should -BeFalse

        $passTask = Join-Path $caseRoot 'pass-task'
        $passParent = Join-Path $passTask 'local-correctness'
        $null = [System.IO.Directory]::CreateDirectory($passParent)
        $outsidePass = Join-Path $caseRoot 'outside-pass'
        $null = [System.IO.Directory]::CreateDirectory($outsidePass)
        script:Write-Utf8NoBomFile -Path (Join-Path $outsidePass 'input.md') -Content ''
        $null = script:New-TestJunction `
            -LinkPath (Join-Path $passParent 'pass-01') `
            -TargetPath $outsidePass
        Test-ReviewCampaignAnchor -TaskDir $passTask | Should -BeFalse
    }

    It 'AC-CAM-PATH1c: input.md reparse path은 campaign anchor가 아니다' {
        $caseRoot = script:New-CaseDir -Name 'campaign-anchor-input-reparse'
        $taskDir = Join-Path $caseRoot 'task'
        $passDir = Join-Path $taskDir 'local-correctness/pass-01'
        $null = [System.IO.Directory]::CreateDirectory($passDir)
        $inputLink = Join-Path $passDir 'input.md'
        $outsideInput = Join-Path $caseRoot 'outside-input.md'
        script:Write-Utf8NoBomFile -Path $outsideInput -Content 'outside'

        $fileLinkCreated = script:Try-NewTestFileSymbolicLink -LinkPath $inputLink -TargetPath $outsideInput
        if (-not $fileLinkCreated) {
            # File symlink creation can require host policy/privilege. A directory junction at the
            # exact input.md token still fixes the fail-closed reparse-path fallback on such hosts.
            $outsideInputDir = Join-Path $caseRoot 'outside-input-dir'
            $null = [System.IO.Directory]::CreateDirectory($outsideInputDir)
            $null = script:New-TestJunction -LinkPath $inputLink -TargetPath $outsideInputDir
        }

        Test-ReviewCampaignAnchor -TaskDir $taskDir | Should -BeFalse
    }

    It 'AC-CAM-PATH1d: input.md가 directory인 wrong-shape record는 campaign anchor가 아니다' {
        $caseRoot = script:New-CaseDir -Name 'campaign-anchor-input-wrong-shape'
        $taskDir = Join-Path $caseRoot 'task'
        $wrongInput = Join-Path $taskDir 'local-correctness/pass-01/input.md'
        $null = [System.IO.Directory]::CreateDirectory($wrongInput)

        Test-ReviewCampaignAnchor -TaskDir $taskDir | Should -BeFalse
    }

    It 'AC-CAM-PATH4: selected pass parent의 static junction을 write 전에 거부하고 외부 target을 건드리지 않는다' {
        $caseRoot = script:New-CaseDir -Name 'write-parent-reparse'
        $taskDir = Join-Path $caseRoot 'task'
        $anchorPass = Join-Path $taskDir 'local-correctness/pass-01'
        $null = [System.IO.Directory]::CreateDirectory($anchorPass)
        script:Write-Utf8NoBomFile -Path (Join-Path $anchorPass 'input.md') -Content ''

        $outsidePerspective = Join-Path $caseRoot 'outside-system-coherence'
        $null = [System.IO.Directory]::CreateDirectory($outsidePerspective)
        $selectedPassParent = Join-Path $taskDir 'system-coherence'
        $null = script:New-TestJunction -LinkPath $selectedPassParent -TargetPath $outsidePerspective
        $outsidePass = Join-Path $outsidePerspective 'pass-01'

        {
            [void] (Assert-NoStaticReparsePointInReviewPath -RootPath $taskDir -Path $selectedPassParent)
            $null = New-ReviewPassAllocation -PassDir $outsidePass
        } | Should -Throw '*static reparse point*'
        Test-Path -LiteralPath $outsidePass | Should -BeFalse
    }

    It 'AC-CAM-PATH4a: log/review junction은 task claim 전에 거부되어 외부 target을 건드리지 않는다' {
        $caseRoot = script:New-CaseDir -Name 'review-root-reparse'
        $logRoot = Join-Path $caseRoot 'log'
        $null = [System.IO.Directory]::CreateDirectory($logRoot)
        $outsideReview = Join-Path $caseRoot 'outside-review'
        $null = [System.IO.Directory]::CreateDirectory($outsideReview)
        $reviewLink = Join-Path $logRoot 'review'
        $null = script:New-TestJunction -LinkPath $reviewLink -TargetPath $outsideReview
        $taskDir = Join-Path $reviewLink 'campaign'

        {
            [void] (Assert-NoStaticReparsePointInReviewPath -RootPath $logRoot -Path $taskDir)
            [void] (New-ExclusiveReviewDirectory -Path $taskDir)
        } | Should -Throw '*static reparse point*'
        Test-Path -LiteralPath (Join-Path $outsideReview 'campaign') | Should -BeFalse
    }

    It 'AC-CAM-PATH4b: selected write ancestry의 file shape는 directory 생성 전에 거부된다' {
        $caseRoot = script:New-CaseDir -Name 'write-parent-wrong-shape'
        $taskDir = Join-Path $caseRoot 'task'
        $null = [System.IO.Directory]::CreateDirectory($taskDir)
        $selectedPassParent = Join-Path $taskDir 'local-correctness'
        script:Write-Utf8NoBomFile -Path $selectedPassParent -Content 'not-a-directory'

        { Assert-NoStaticReparsePointInReviewPath -RootPath $taskDir -Path $selectedPassParent } |
            Should -Throw '*not a directory*'
        Test-Path -LiteralPath (Join-Path $selectedPassParent 'pass-01') | Should -BeFalse
    }

    It 'AC-CAM-PATH4c: dangling log/review junction도 target resolution 없이 task claim 전에 거부된다' {
        $caseRoot = script:New-CaseDir -Name 'review-root-dangling-reparse'
        $logRoot = Join-Path $caseRoot 'log'
        $null = [System.IO.Directory]::CreateDirectory($logRoot)
        $outsideReview = Join-Path $caseRoot 'outside-review'
        $null = [System.IO.Directory]::CreateDirectory($outsideReview)
        $reviewLink = Join-Path $logRoot 'review'
        $null = script:New-TestJunction -LinkPath $reviewLink -TargetPath $outsideReview
        Remove-Item -LiteralPath $outsideReview -Recurse -Force

        $entry = @(Get-ChildItem -LiteralPath $logRoot -Force | Where-Object Name -CEQ 'review')
        $entry.Count | Should -Be 1
        (($entry[0].Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) | Should -BeTrue
        $nativeEntry = Get-ReviewPathEntryAttributes -Path $reviewLink
        $nativeEntry.Exists | Should -BeTrue
        (($nativeEntry.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) | Should -BeTrue

        $taskDir = Join-Path $reviewLink 'campaign'
        { Assert-NoStaticReparsePointInReviewPath -RootPath $logRoot -Path $taskDir } |
            Should -Throw '*static reparse point*'
    }

    It 'AC-CAM-PATH4d: dangling selected perspective junction도 pass allocation 전에 거부된다' {
        $caseRoot = script:New-CaseDir -Name 'write-parent-dangling-reparse'
        $taskDir = Join-Path $caseRoot 'task'
        $null = [System.IO.Directory]::CreateDirectory($taskDir)
        $outsidePerspective = Join-Path $caseRoot 'outside-local-correctness'
        $null = [System.IO.Directory]::CreateDirectory($outsidePerspective)
        $selectedPassParent = Join-Path $taskDir 'local-correctness'
        $null = script:New-TestJunction -LinkPath $selectedPassParent -TargetPath $outsidePerspective
        Remove-Item -LiteralPath $outsidePerspective -Recurse -Force

        $entry = @(Get-ChildItem -LiteralPath $taskDir -Force | Where-Object Name -CEQ 'local-correctness')
        $entry.Count | Should -Be 1
        (($entry[0].Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) | Should -BeTrue
        $nativeEntry = Get-ReviewPathEntryAttributes -Path $selectedPassParent
        $nativeEntry.Exists | Should -BeTrue
        (($nativeEntry.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) | Should -BeTrue

        { Assert-NoStaticReparsePointInReviewPath -RootPath $taskDir -Path $selectedPassParent } |
            Should -Throw '*static reparse point*'
    }

    It 'AC-CAM-PATH2: exclusive pass allocation은 input.md 0-byte를 한 번만 만들고 재호출을 거부한다' {
        $parent = script:New-CaseDir -Name 'exclusive-allocation'
        $passDir = Join-Path $parent 'pass-01'

        $allocation = New-ReviewPassAllocation -PassDir $passDir
        $allocation.PassDir | Should -Be ([System.IO.Path]::GetFullPath($passDir))
        $allocation.InputPath | Should -Be ([System.IO.Path]::GetFullPath((Join-Path $passDir 'input.md')))
        (Get-Item -LiteralPath $allocation.InputPath).Length | Should -Be 0

        { New-ReviewPassAllocation -PassDir $passDir } | Should -Throw '*directory claim conflict*'
        @((Get-ChildItem -LiteralPath $passDir -File)).Count | Should -Be 1
        (Get-ChildItem -LiteralPath $passDir -File).Name | Should -Be 'input.md'
    }

    It 'AC-CAM-PATH2a: lower claim 뒤 pass-99가 보이면 post-check는 실패하고 두 claim을 보존한다' {
        $parent = script:New-CaseDir -Name 'pass99-post-claim'
        $lower = New-ReviewPassAllocation -PassDir (Join-Path $parent 'pass-01')
        $terminal = New-ReviewPassAllocation -PassDir (Join-Path $parent 'pass-99')

        { Assert-ReviewPass99NotOccupied -PassParent $parent } |
            Should -Throw '*range exhausted (max 99)*'
        Test-Path -LiteralPath $lower.InputPath -PathType Leaf | Should -BeTrue
        Test-Path -LiteralPath $terminal.InputPath -PathType Leaf | Should -BeTrue
        (Get-Item -LiteralPath $lower.InputPath).Length | Should -Be 0
        (Get-Item -LiteralPath $terminal.InputPath).Length | Should -Be 0
    }

    It 'AC-CAM-PATH2b: post-check의 required parent가 없거나 검사 불가하면 성공으로 축약하지 않는다' {
        $parent = Join-Path (script:New-CaseDir -Name 'pass99-required-parent') 'missing-perspective'

        { Assert-ReviewPass99NotOccupied -PassParent $parent -RequireExistingParent } |
            Should -Throw '*could not inspect selected perspective parent*'
    }

    It 'AC-CAM-PATH3: 두 child가 동일 preselected auto candidate를 경쟁하면 정확히 하나만 성공하고 retry하지 않는다' {
        $caseRoot = script:New-CaseDir -Name 'allocation-barrier'
        $passParent = Join-Path $caseRoot 'local-correctness'
        $null = [System.IO.Directory]::CreateDirectory($passParent)
        $candidate = Get-NextPassName -TaskDir $passParent
        $candidate | Should -Be 'pass-01'
        $passDir = Join-Path $passParent $candidate

        $childPath = Join-Path $caseRoot 'allocation-child.ps1'
        $childBody = @'
param(
    [string] $PathLib,
    [string] $PassDir,
    [string] $ReadyPath,
    [string] $ReleasePath,
    [string] $ResultPath
)
$ErrorActionPreference = 'Stop'
. $PathLib
[System.IO.File]::WriteAllText($ReadyPath, 'ready')
$deadline = [DateTime]::UtcNow.AddSeconds(10)
while (-not (Test-Path -LiteralPath $ReleasePath -PathType Leaf)) {
    if ([DateTime]::UtcNow -ge $deadline) {
        [System.IO.File]::WriteAllText($ResultPath, 'barrier-timeout')
        exit 2
    }
    Start-Sleep -Milliseconds 10
}
try {
    $null = New-ReviewPassAllocation -PassDir $PassDir
    [System.IO.File]::WriteAllText($ResultPath, 'success')
    exit 0
}
catch {
    [System.IO.File]::WriteAllText($ResultPath, ('failure: ' + $_.Exception.Message))
    exit 1
}
'@
        script:Write-Utf8NoBomFile -Path $childPath -Content $childBody

        $ready1 = Join-Path $caseRoot 'ready-1.txt'
        $ready2 = Join-Path $caseRoot 'ready-2.txt'
        $result1 = Join-Path $caseRoot 'result-1.txt'
        $result2 = Join-Path $caseRoot 'result-2.txt'
        $release = Join-Path $caseRoot 'release.txt'

        function Start-AllocationChild {
            param([string] $ReadyPath, [string] $ResultPath)

            $arguments = @(
                '-NoProfile',
                '-ExecutionPolicy', 'Bypass',
                '-File', ('"{0}"' -f $childPath),
                '-PathLib', ('"{0}"' -f $script:PathLib),
                '-PassDir', ('"{0}"' -f $passDir),
                '-ReadyPath', ('"{0}"' -f $ReadyPath),
                '-ReleasePath', ('"{0}"' -f $release),
                '-ResultPath', ('"{0}"' -f $ResultPath)
            )
            return Start-Process -FilePath 'powershell.exe' -ArgumentList $arguments -PassThru -WindowStyle Hidden
        }

        $child1 = Start-AllocationChild -ReadyPath $ready1 -ResultPath $result1
        $child2 = Start-AllocationChild -ReadyPath $ready2 -ResultPath $result2
        try {
            $deadline = [DateTime]::UtcNow.AddSeconds(10)
            while ((-not (Test-Path -LiteralPath $ready1 -PathType Leaf)) -or
                   (-not (Test-Path -LiteralPath $ready2 -PathType Leaf))) {
                if ([DateTime]::UtcNow -ge $deadline) {
                    throw '두 allocation child가 barrier에 도달하지 못했다.'
                }
                Start-Sleep -Milliseconds 10
            }
            script:Write-Utf8NoBomFile -Path $release -Content 'release'

            $child1.WaitForExit(10000) | Should -BeTrue
            $child2.WaitForExit(10000) | Should -BeTrue
        }
        finally {
            foreach ($child in @($child1, $child2)) {
                if (-not $child.HasExited) {
                    $child.Kill()
                    $child.WaitForExit()
                }
                $child.Dispose()
            }
        }

        Test-Path -LiteralPath $result1 -PathType Leaf | Should -BeTrue
        Test-Path -LiteralPath $result2 -PathType Leaf | Should -BeTrue
        $statuses = @(
            (Get-Content -Raw -Encoding UTF8 -LiteralPath $result1),
            (Get-Content -Raw -Encoding UTF8 -LiteralPath $result2)
        )
        @($statuses | Where-Object { $_ -eq 'success' }).Count | Should -Be 1
        @($statuses | Where-Object { $_ -like 'failure: *directory claim conflict*' }).Count | Should -Be 1

        @((Get-ChildItem -LiteralPath $passParent -Directory)).Count | Should -Be 1
        Test-Path -LiteralPath (Join-Path $passParent 'pass-02') | Should -BeFalse
        $inputPath = Join-Path $passDir 'input.md'
        Test-Path -LiteralPath $inputPath -PathType Leaf | Should -BeTrue
        (Get-Item -LiteralPath $inputPath).Length | Should -Be 0
    }
}
