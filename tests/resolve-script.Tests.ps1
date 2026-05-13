Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

BeforeAll {
    $script:RepoRoot       = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).ProviderPath
    $script:ResolveLib     = Join-Path $script:RepoRoot 'scripts/lib/resolve-script.ps1'

    . $script:ResolveLib

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
        $p = Join-Path $TestDrive ('pester-resolve-' + $Name)
        if (Test-Path -LiteralPath $p) {
            Remove-Item -LiteralPath $p -Recurse -Force
        }
        $null = New-Item -ItemType Directory -Path $p -Force
        return ([System.IO.Path]::GetFullPath($p))
    }

    function script:Clear-EnvToolRoot {
        $env:AI_HARNESS_TOOL_ROOT = $null
    }
}

Describe 'Get-ToolRootSource' {
    BeforeEach { script:Clear-EnvToolRoot }

    It 'AC-RS-SRC-1: returns explicit when -ToolRoot is non-empty' {
        Get-ToolRootSource -ToolRoot 'H:/somewhere' | Should -Be 'explicit'
    }

    It 'AC-RS-SRC-2: returns explicit when AI_HARNESS_TOOL_ROOT is set and -ToolRoot is empty' {
        $env:AI_HARNESS_TOOL_ROOT = 'H:/somewhere'
        try {
            Get-ToolRootSource -ToolRoot '' | Should -Be 'explicit'
        }
        finally {
            $env:AI_HARNESS_TOOL_ROOT = $null
        }
    }

    It 'AC-RS-SRC-3: returns implicit when both -ToolRoot and env are empty' {
        Get-ToolRootSource -ToolRoot '' | Should -Be 'implicit'
    }

    It 'AC-RS-SRC-4: -ToolRoot non-empty wins over env even when env is also set' {
        $env:AI_HARNESS_TOOL_ROOT = 'H:/env-value'
        try {
            Get-ToolRootSource -ToolRoot 'H:/param-value' | Should -Be 'explicit'
        }
        finally {
            $env:AI_HARNESS_TOOL_ROOT = $null
        }
    }
}

Describe 'Resolve-CycleScript (D2: explicit ToolRoot suppresses PSScriptRoot fallback)' {
    BeforeEach { script:Clear-EnvToolRoot }

    It 'AC-RS-CYC-EXPLICIT-OK: returns ToolRoot/RelativePath when it exists under explicit ToolRoot' {
        $tool  = script:New-CaseDir -Name 'cyc-exp-ok-tool'
        $local = script:New-CaseDir -Name 'cyc-exp-ok-local'
        $target = Join-Path $tool 'scripts/foo.ps1'
        script:Write-Utf8NoBomFile -Path $target -Content "# fake script`n"

        $result = Resolve-CycleScript -Tool $tool -RelativePath 'scripts/foo.ps1' -LocalDir $local -ToolRootSource 'explicit'

        ([System.IO.Path]::GetFullPath($result)) | Should -Be ([System.IO.Path]::GetFullPath($target))
    }

    It 'AC-RS-CYC-EXPLICIT-MISSING: throws and does NOT fall back when missing under explicit ToolRoot' {
        $tool  = script:New-CaseDir -Name 'cyc-exp-miss-tool'
        $local = script:New-CaseDir -Name 'cyc-exp-miss-local'
        # PSScriptRoot fallback exists but must be suppressed.
        script:Write-Utf8NoBomFile -Path (Join-Path $local 'foo.ps1') -Content "# would be fallback`n"

        $threw = $false
        $msg = ''
        try {
            Resolve-CycleScript -Tool $tool -RelativePath 'scripts/foo.ps1' -LocalDir $local -ToolRootSource 'explicit' | Out-Null
        }
        catch {
            $threw = $true
            $msg = [string]$_.Exception.Message
        }

        $threw | Should -BeTrue
        $msg | Should -Match 'review-cycle'
        $msg | Should -Match 'explicit ToolRoot'
        $msg | Should -Match ([regex]::Escape($tool))
        $msg | Should -Match 'scripts/foo.ps1'
    }
}

Describe 'Resolve-CycleScript (D2: implicit ToolRoot allows PSScriptRoot fallback with warning)' {
    BeforeEach { script:Clear-EnvToolRoot }

    It 'AC-RS-CYC-IMPLICIT-OK: returns ToolRoot/RelativePath when it exists under implicit ToolRoot' {
        $tool  = script:New-CaseDir -Name 'cyc-imp-ok-tool'
        $local = script:New-CaseDir -Name 'cyc-imp-ok-local'
        $target = Join-Path $tool 'scripts/foo.ps1'
        script:Write-Utf8NoBomFile -Path $target -Content "# fake`n"

        $result = Resolve-CycleScript -Tool $tool -RelativePath 'scripts/foo.ps1' -LocalDir $local -ToolRootSource 'implicit'

        ([System.IO.Path]::GetFullPath($result)) | Should -Be ([System.IO.Path]::GetFullPath($target))
    }

    It 'AC-RS-CYC-IMPLICIT-FALLBACK: falls back to PSScriptRoot leaf when missing under implicit ToolRoot and emits WARN' {
        $tool  = script:New-CaseDir -Name 'cyc-imp-fb-tool'
        $local = script:New-CaseDir -Name 'cyc-imp-fb-local'
        $fallback = Join-Path $local 'foo.ps1'
        script:Write-Utf8NoBomFile -Path $fallback -Content "# fallback`n"

        $informational = (& {
            Resolve-CycleScript -Tool $tool -RelativePath 'scripts/foo.ps1' -LocalDir $local -ToolRootSource 'implicit' 6>&1
        } | Out-String -Width 8192)

        # Strip line breaks so long paths that Out-String may have wrapped match cleanly.
        $flat = ($informational -replace "`r?`n", ' ')

        $flat | Should -Match 'WARN component script resolved via \$PSScriptRoot fallback'
        $flat | Should -Match ([regex]::Escape($tool))
        $flat | Should -Match 'scripts/foo.ps1'
    }

    It 'AC-RS-CYC-IMPLICIT-NOTFOUND: throws when missing under both ToolRoot and PSScriptRoot' {
        $tool  = script:New-CaseDir -Name 'cyc-imp-nf-tool'
        $local = script:New-CaseDir -Name 'cyc-imp-nf-local'

        $threw = $false
        $msg = ''
        try {
            Resolve-CycleScript -Tool $tool -RelativePath 'scripts/foo.ps1' -LocalDir $local -ToolRootSource 'implicit' | Out-Null
        }
        catch {
            $threw = $true
            $msg = [string]$_.Exception.Message
        }

        $threw | Should -BeTrue
        $msg | Should -Match 'review-cycle'
        $msg | Should -Match 'required script not found'
        $msg | Should -Match 'scripts/foo.ps1'
    }
}

Describe 'Resolve-RunScript (D2 mirror, review-run prefix)' {
    BeforeEach { script:Clear-EnvToolRoot }

    It 'AC-RS-RUN-EXPLICIT-MISSING: throws with review-run prefix under explicit ToolRoot' {
        $tool  = script:New-CaseDir -Name 'run-exp-miss-tool'
        $local = script:New-CaseDir -Name 'run-exp-miss-local'
        script:Write-Utf8NoBomFile -Path (Join-Path $local 'foo.ps1') -Content "# would be fallback`n"

        $threw = $false
        $msg = ''
        try {
            Resolve-RunScript -Tool $tool -RelativePath 'scripts/foo.ps1' -LocalDir $local -ToolRootSource 'explicit' | Out-Null
        }
        catch {
            $threw = $true
            $msg = [string]$_.Exception.Message
        }

        $threw | Should -BeTrue
        $msg | Should -Match 'review-run'
        $msg | Should -Match 'explicit ToolRoot'
    }

    It 'AC-RS-RUN-IMPLICIT-FALLBACK: implicit fallback uses review-run WARN prefix' {
        $tool  = script:New-CaseDir -Name 'run-imp-fb-tool'
        $local = script:New-CaseDir -Name 'run-imp-fb-local'
        script:Write-Utf8NoBomFile -Path (Join-Path $local 'foo.ps1') -Content "# fallback`n"

        $informational = & {
            Resolve-RunScript -Tool $tool -RelativePath 'scripts/foo.ps1' -LocalDir $local -ToolRootSource 'implicit' 6>&1
        } | Out-String

        $informational | Should -Match 'review-run: WARN'
    }
}

Describe 'Caller contract (callsite consumption)' {
    BeforeEach { script:Clear-EnvToolRoot }

    It 'AC-RS-CALL-1: Resolve-CycleScript default ToolRootSource is implicit (backward compat)' {
        $tool  = script:New-CaseDir -Name 'call-default-tool'
        $local = script:New-CaseDir -Name 'call-default-local'
        script:Write-Utf8NoBomFile -Path (Join-Path $local 'foo.ps1') -Content "# default fallback`n"

        $informational = & {
            Resolve-CycleScript -Tool $tool -RelativePath 'scripts/foo.ps1' -LocalDir $local 6>&1
        } | Out-String

        $informational | Should -Match 'WARN component script resolved via \$PSScriptRoot fallback'
    }

    It 'AC-RS-CALL-2: returned path is a single non-empty string usable directly' {
        $tool  = script:New-CaseDir -Name 'call-string-tool'
        $local = script:New-CaseDir -Name 'call-string-local'
        script:Write-Utf8NoBomFile -Path (Join-Path $tool 'scripts/foo.ps1') -Content "# fake`n"

        $result = Resolve-CycleScript -Tool $tool -RelativePath 'scripts/foo.ps1' -LocalDir $local -ToolRootSource 'explicit'

        $result | Should -BeOfType [string]
        [string]::IsNullOrEmpty($result) | Should -BeFalse
        Test-Path -LiteralPath $result -PathType Leaf | Should -BeTrue
    }

    It 'AC-RS-CALL-3: Resolve-CycleScript output is a scalar (Count 1, [0] echoes the value, not null or empty)' {
        $tool  = script:New-CaseDir -Name 'call-scalar-cyc-tool'
        $local = script:New-CaseDir -Name 'call-scalar-cyc-local'
        script:Write-Utf8NoBomFile -Path (Join-Path $tool 'scripts/foo.ps1') -Content "# fake`n"

        $result = Resolve-CycleScript -Tool $tool -RelativePath 'scripts/foo.ps1' -LocalDir $local -ToolRootSource 'explicit'

        $wrapped = @($result)
        $wrapped.Count | Should -Be 1
        $wrapped[0] | Should -Be $result
        $result | Should -Not -BeNullOrEmpty
        $result | Should -BeOfType [string]
    }

    It 'AC-RS-CALL-4: Resolve-RunScript output is a scalar (Count 1, [0] echoes the value, not null or empty)' {
        $tool  = script:New-CaseDir -Name 'call-scalar-run-tool'
        $local = script:New-CaseDir -Name 'call-scalar-run-local'
        script:Write-Utf8NoBomFile -Path (Join-Path $tool 'scripts/foo.ps1') -Content "# fake`n"

        $result = Resolve-RunScript -Tool $tool -RelativePath 'scripts/foo.ps1' -LocalDir $local -ToolRootSource 'explicit'

        $wrapped = @($result)
        $wrapped.Count | Should -Be 1
        $wrapped[0] | Should -Be $result
        $result | Should -Not -BeNullOrEmpty
        $result | Should -BeOfType [string]
    }
}
