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
