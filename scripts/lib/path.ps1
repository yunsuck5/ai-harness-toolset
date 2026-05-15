Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-ProjectRoot {
    [CmdletBinding()]
    param(
        [string] $ProjectRoot
    )

    if ([string]::IsNullOrEmpty($ProjectRoot)) {
        $ProjectRoot = (Get-Location).ProviderPath
        $gitPath = Join-Path -Path $ProjectRoot -ChildPath '.git'
        # Accept both .git directory (standard repo) and .git file pointer
        # (git worktree / submodule). Only advise when neither shape is present.
        $gitIsDir  = Test-Path -LiteralPath $gitPath -PathType Container
        $gitIsFile = Test-Path -LiteralPath $gitPath -PathType Leaf
        if (-not ($gitIsDir -or $gitIsFile)) {
            Write-Host ('Get-ProjectRoot: WARN ProjectRoot resolved to CWD without a .git entry: {0}' -f $ProjectRoot)
        }
    }
    if (-not (Test-Path -LiteralPath $ProjectRoot -PathType Container)) {
        throw "Get-ProjectRoot: directory not found: $ProjectRoot"
    }
    return [System.IO.Path]::GetFullPath($ProjectRoot)
}

function Test-IsSourceRepoRoot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path
    )

    $markers = @(
        'scripts/verify-ps1.ps1',
        'templates/review-input.md',
        'config/reviewer.json'
    )
    foreach ($m in $markers) {
        $full = Join-Path -Path $Path -ChildPath $m
        if (-not (Test-Path -LiteralPath $full -PathType Leaf)) {
            return $false
        }
    }
    return $true
}

function Get-StableToolRootCandidate {
    [CmdletBinding()]
    param()

    # Global stable install location: %USERPROFILE%\.claude\ai-harness-toolset\current.
    # This is the default ToolRoot for shared / global mode. The -ToolRoot parameter
    # and the AI_HARNESS_TOOL_ROOT env var are higher-priority overrides; this path is
    # the standing default when no override is in play.
    $userProfile = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::UserProfile)
    if ([string]::IsNullOrEmpty($userProfile)) {
        return $null
    }
    $candidate = Join-Path -Path $userProfile  -ChildPath '.claude'
    $candidate = Join-Path -Path $candidate    -ChildPath 'ai-harness-toolset'
    $candidate = Join-Path -Path $candidate    -ChildPath 'current'
    return [System.IO.Path]::GetFullPath($candidate)
}

function Test-IsValidToolRootPayload {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path
    )

    # A ToolRoot payload is valid when the primary entrypoint script is present.
    # An existing-but-incomplete payload is an operator error that must fail fast
    # rather than be silently skipped.
    $entry = Join-Path -Path $Path -ChildPath 'scripts/review-cycle.ps1'
    return (Test-Path -LiteralPath $entry -PathType Leaf)
}

function Get-ToolRoot {
    [CmdletBinding()]
    param(
        [string] $ToolRoot,
        [string] $ProjectRoot,
        # Optional override for the global stable install path (channel 3).
        # Production callers leave this empty so it resolves to
        # %USERPROFILE%\.claude\ai-harness-toolset\current; tests inject a
        # controlled path for deterministic isolation.
        [string] $StableToolRoot
    )

    $tried = New-Object System.Collections.Generic.List[string]

    # channel 1 — explicit -ToolRoot parameter (highest priority).
    if (-not [string]::IsNullOrEmpty($ToolRoot)) {
        if (-not (Test-Path -LiteralPath $ToolRoot -PathType Container)) {
            throw ('Get-ToolRoot: channel 1 (-ToolRoot parameter): directory not found: {0}. Provide a valid existing directory or omit -ToolRoot to fall back to env / stable / dogfooding / legacy channels.' -f $ToolRoot)
        }
        return [System.IO.Path]::GetFullPath($ToolRoot)
    }
    $tried.Add('channel 1 (-ToolRoot parameter): not provided') | Out-Null

    # channel 2 — AI_HARNESS_TOOL_ROOT env var (override / debug / development validation).
    $envTool = [System.Environment]::GetEnvironmentVariable('AI_HARNESS_TOOL_ROOT')
    if (-not [string]::IsNullOrEmpty($envTool)) {
        if (-not (Test-Path -LiteralPath $envTool -PathType Container)) {
            throw ('Get-ToolRoot: channel 2 (env AI_HARNESS_TOOL_ROOT): directory not found: {0}. Set AI_HARNESS_TOOL_ROOT to an existing directory or unset it to fall back to stable / dogfooding / legacy channels.' -f $envTool)
        }
        return [System.IO.Path]::GetFullPath($envTool)
    }
    $tried.Add('channel 2 (env AI_HARNESS_TOOL_ROOT): not set or empty') | Out-Null

    # channel 3 — global stable install (%USERPROFILE%\.claude\ai-harness-toolset\current).
    # This is the default ToolRoot for shared / global mode.
    #   - absent directory  -> skip to fallback channels.
    #   - present directory -> must be a complete payload, otherwise fail fast.
    if ([string]::IsNullOrEmpty($StableToolRoot)) {
        $StableToolRoot = Get-StableToolRootCandidate
    }
    if (-not [string]::IsNullOrEmpty($StableToolRoot)) {
        if (Test-Path -LiteralPath $StableToolRoot -PathType Container) {
            if (-not (Test-IsValidToolRootPayload -Path $StableToolRoot)) {
                throw ('Get-ToolRoot: channel 3 (global stable install): directory exists but payload is incomplete: {0}. Expected entrypoint scripts/review-cycle.ps1 was not found. Reinstall the global stable ToolRoot (delete-and-reinstall) or use -ToolRoot / AI_HARNESS_TOOL_ROOT to point at a complete payload.' -f $StableToolRoot)
            }
            return [System.IO.Path]::GetFullPath($StableToolRoot)
        }
        $tried.Add(('channel 3 (global stable install): not present at {0}' -f $StableToolRoot)) | Out-Null
    }
    else {
        $tried.Add('channel 3 (global stable install): user profile path unavailable') | Out-Null
    }

    $project = Get-ProjectRoot -ProjectRoot $ProjectRoot

    # channel 4 — self-target / dogfooding source repo multi-marker.
    if (Test-IsSourceRepoRoot -Path $project) {
        return $project
    }
    $tried.Add(('channel 4 (dogfooding multi-marker on ProjectRoot={0}): markers missing' -f $project)) | Out-Null

    # channel 5 — legacy <ProjectRoot>/.ai-harness.
    $legacy = Join-Path -Path $project -ChildPath '.ai-harness'
    if (Test-Path -LiteralPath $legacy -PathType Container) {
        return [System.IO.Path]::GetFullPath($legacy)
    }
    $tried.Add(('channel 5 (legacy <ProjectRoot>/.ai-harness): not present at {0}' -f $legacy)) | Out-Null

    # channel 6 — nothing resolved.
    $trace = $tried -join '; '
    throw ('Get-ToolRoot: no ToolRoot channel could be resolved. Tried: {0}. Set AI_HARNESS_TOOL_ROOT, pass -ToolRoot, or install the global stable ToolRoot.' -f $trace)
}

function Get-ProjectLogRoot {
    [CmdletBinding()]
    param(
        [string] $ProjectRoot
    )

    $project = Get-ProjectRoot -ProjectRoot $ProjectRoot
    $logPath = Join-Path -Path $project -ChildPath 'log'
    return [System.IO.Path]::GetFullPath($logPath)
}

function Assert-InProjectLogRoot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path,
        [Parameter(Mandatory = $true)]
        [string] $ProjectLogRoot
    )

    if ([string]::IsNullOrEmpty($ProjectLogRoot)) {
        throw 'Assert-InProjectLogRoot: -ProjectLogRoot is required.'
    }

    $logFull = [System.IO.Path]::GetFullPath($ProjectLogRoot)
    $full    = [System.IO.Path]::GetFullPath($Path)

    $sep = [System.IO.Path]::DirectorySeparatorChar
    $baseNorm = $logFull.TrimEnd($sep)
    $cmp = [System.StringComparison]::OrdinalIgnoreCase

    if ([string]::Equals($full, $baseNorm, $cmp)) {
        return $true
    }
    $prefix = $baseNorm + $sep
    if ($full.StartsWith($prefix, $cmp)) {
        return $true
    }
    throw "Assert-InProjectLogRoot: path is outside ProjectLogRoot. Path=$full ProjectLogRoot=$baseNorm"
}

function Resolve-ProjectRelativePath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path,
        [string] $ProjectRoot
    )

    $project = Get-ProjectRoot -ProjectRoot $ProjectRoot
    $full = [System.IO.Path]::GetFullPath($Path)

    $sep = [System.IO.Path]::DirectorySeparatorChar
    $projectNorm = $project.TrimEnd($sep)
    $cmp = [System.StringComparison]::OrdinalIgnoreCase

    if ([string]::Equals($full, $projectNorm, $cmp)) {
        return '.'
    }
    $prefix = $projectNorm + $sep
    if ($full.StartsWith($prefix, $cmp)) {
        return $full.Substring($prefix.Length)
    }
    return $full
}

function Assert-InProjectRoot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path,
        [string] $ProjectRoot
    )

    $project = Get-ProjectRoot -ProjectRoot $ProjectRoot
    $full = [System.IO.Path]::GetFullPath($Path)

    $sep = [System.IO.Path]::DirectorySeparatorChar
    $projectNorm = $project.TrimEnd($sep)
    $cmp = [System.StringComparison]::OrdinalIgnoreCase

    if ([string]::Equals($full, $projectNorm, $cmp)) {
        return $true
    }
    $prefix = $projectNorm + $sep
    if ($full.StartsWith($prefix, $cmp)) {
        return $true
    }
    throw "Assert-InProjectRoot: path is outside ProjectRoot. Path=$full ProjectRoot=$projectNorm"
}

function Test-ValidRunId {
    [CmdletBinding()]
    param(
        [string] $Value
    )

    if ([string]::IsNullOrEmpty($Value)) { return $false }
    if ($Value.Contains('..')) { return $false }
    return ($Value -match '^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$')
}

function Assert-ValidRunId {
    [CmdletBinding()]
    param(
        [string] $Value
    )

    if (-not (Test-ValidRunId -Value $Value)) {
        throw "Assert-ValidRunId: invalid RunId: '$Value'"
    }
    return $true
}

function Assert-InProjectLogReviewRequestsRoot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path,
        [Parameter(Mandatory = $true)]
        [string] $ProjectLogRoot
    )

    if ([string]::IsNullOrEmpty($ProjectLogRoot)) {
        throw 'Assert-InProjectLogReviewRequestsRoot: -ProjectLogRoot is required.'
    }

    [void] (Assert-InProjectLogRoot -Path $Path -ProjectLogRoot $ProjectLogRoot)

    $logFull = [System.IO.Path]::GetFullPath($ProjectLogRoot)
    $reqBase = [System.IO.Path]::GetFullPath((Join-Path -Path $logFull -ChildPath 'review-requests'))
    $full = [System.IO.Path]::GetFullPath($Path)

    $sep = [System.IO.Path]::DirectorySeparatorChar
    $baseNorm = $reqBase.TrimEnd($sep)
    $cmp = [System.StringComparison]::OrdinalIgnoreCase

    if ([string]::Equals($full, $baseNorm, $cmp)) {
        return $true
    }
    $prefix = $baseNorm + $sep
    if ($full.StartsWith($prefix, $cmp)) {
        return $true
    }
    throw "Assert-InProjectLogReviewRequestsRoot: path is outside review-requests root. Path=$full ReviewRequestsRoot=$baseNorm"
}

function Assert-InReviewRunRoot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path,
        [Parameter(Mandatory = $true)]
        [string] $ProjectLogRoot
    )

    if ([string]::IsNullOrEmpty($ProjectLogRoot)) {
        throw 'Assert-InReviewRunRoot: -ProjectLogRoot is required.'
    }

    [void] (Assert-InProjectLogRoot -Path $Path -ProjectLogRoot $ProjectLogRoot)

    $logFull = [System.IO.Path]::GetFullPath($ProjectLogRoot)
    $reviewBase = [System.IO.Path]::GetFullPath((Join-Path -Path $logFull -ChildPath 'review'))
    $full = [System.IO.Path]::GetFullPath($Path)

    $sep = [System.IO.Path]::DirectorySeparatorChar
    $baseNorm = $reviewBase.TrimEnd($sep)
    $cmp = [System.StringComparison]::OrdinalIgnoreCase

    if ([string]::Equals($full, $baseNorm, $cmp)) {
        return $true
    }
    $prefix = $baseNorm + $sep
    if ($full.StartsWith($prefix, $cmp)) {
        return $true
    }
    throw "Assert-InReviewRunRoot: path is outside review run root. Path=$full ReviewRoot=$baseNorm"
}
