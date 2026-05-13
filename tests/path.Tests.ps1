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

Describe 'Get-ToolRoot channel 3 (dogfooding multi-marker)' {
    BeforeEach { script:Clear-EnvToolRoot }

    It 'AC-PATH-CH3-1: returns ProjectRoot when all three markers present' {
        $project = script:New-MultiMarkerSourceRepo -Name 'ch3-multi-marker'
        $result = Get-ToolRoot -ProjectRoot $project
        $result.TrimEnd('/','\') | Should -Be ($project.TrimEnd('/','\'))
    }

    It 'AC-PATH-CH3-2: does NOT match dogfooding when only single legacy marker present' {
        $project = script:New-CaseDir -Name 'ch3-single-marker'
        script:Write-Utf8NoBomFile -Path (Join-Path $project 'scripts/verify-ps1.ps1') -Content "# fake`n"
        # Without all three markers + no .ai-harness/ legacy dir, channel chain should throw.
        $threw = $false
        $msg = ''
        try {
            Get-ToolRoot -ProjectRoot $project | Out-Null
        }
        catch {
            $threw = $true
            $msg = [string]$_.Exception.Message
        }
        $threw | Should -BeTrue
        $msg | Should -Match 'no ToolRoot channel could be resolved'
        $msg | Should -Match 'channel 3'
    }
}

Describe 'Get-ToolRoot channel 4 (legacy .ai-harness)' {
    BeforeEach { script:Clear-EnvToolRoot }

    It 'AC-PATH-CH4-1: returns ProjectRoot/.ai-harness when that directory exists' {
        $project = script:New-CaseDir -Name 'ch4-legacy'
        $legacy = Join-Path $project '.ai-harness'
        $null = New-Item -ItemType Directory -Path $legacy -Force
        $result = Get-ToolRoot -ProjectRoot $project
        $result.TrimEnd('/','\') | Should -Be ((Resolve-Path -LiteralPath $legacy).ProviderPath.TrimEnd('/','\'))
    }

    It 'AC-PATH-CH4-2: dogfooding marker wins over legacy .ai-harness' {
        $project = script:New-MultiMarkerSourceRepo -Name 'ch4-dogfood-wins'
        $legacy = Join-Path $project '.ai-harness'
        $null = New-Item -ItemType Directory -Path $legacy -Force
        $result = Get-ToolRoot -ProjectRoot $project
        $result.TrimEnd('/','\') | Should -Be ($project.TrimEnd('/','\'))
    }
}

Describe 'Get-ToolRoot channel 5 (no channel resolved)' {
    BeforeEach { script:Clear-EnvToolRoot }

    It 'AC-PATH-CH5-1: throws with channel trace listing all attempted channels' {
        $project = script:New-CaseDir -Name 'ch5-empty-project'
        $threw = $false
        $msg = ''
        try {
            Get-ToolRoot -ProjectRoot $project | Out-Null
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
        $result = Get-ToolRoot -ProjectRoot $project
        $joined = Join-Path -Path $result -ChildPath 'config/reviewer.json'
        Test-Path -LiteralPath $joined -PathType Leaf | Should -BeTrue
    }
}
