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
        # entrypoint scripts/review-cycle.ps1 (a complete payload); without it the
        # directory exists but the payload is incomplete.
        param(
            [string] $Name,
            [switch] $Valid
        )
        $root = script:New-CaseDir -Name $Name
        if ($Valid) {
            script:Write-Utf8NoBomFile -Path (Join-Path $root 'scripts/review-cycle.ps1') -Content "# fake entrypoint`n"
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
        $stableInvalid = script:New-StableInstall -Name 'ch3-incomplete'   # no scripts/review-cycle.ps1
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
        $msg | Should -Match 'review-cycle\.ps1'
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
        # Without all three markers + no .ai-harness/ legacy dir, channel chain should throw.
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

Describe 'Get-ToolRoot channel 5 (legacy .ai-harness)' {
    BeforeEach { script:Clear-EnvToolRoot }

    It 'AC-PATH-CH5-1: returns ProjectRoot/.ai-harness when that directory exists' {
        $project = script:New-CaseDir -Name 'ch5-legacy'
        $legacy = Join-Path $project '.ai-harness'
        $null = New-Item -ItemType Directory -Path $legacy -Force
        $result = Get-ToolRoot -ProjectRoot $project -StableToolRoot (script:AbsentStablePath)
        $result.TrimEnd('/','\') | Should -Be ((Resolve-Path -LiteralPath $legacy).ProviderPath.TrimEnd('/','\'))
    }

    It 'AC-PATH-CH5-2: dogfooding marker wins over legacy .ai-harness' {
        $project = script:New-MultiMarkerSourceRepo -Name 'ch5-dogfood-wins'
        $legacy = Join-Path $project '.ai-harness'
        $null = New-Item -ItemType Directory -Path $legacy -Force
        $result = Get-ToolRoot -ProjectRoot $project -StableToolRoot (script:AbsentStablePath)
        $result.TrimEnd('/','\') | Should -Be ($project.TrimEnd('/','\'))
    }
}

Describe 'Get-ToolRoot channel 6 (no channel resolved)' {
    BeforeEach { script:Clear-EnvToolRoot }

    It 'AC-PATH-CH6-1: throws with channel trace listing all attempted channels' {
        $project = script:New-CaseDir -Name 'ch6-empty-project'
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
        $msg | Should -Match 'channel 5'
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
