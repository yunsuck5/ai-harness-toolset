Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-ProjectRoot {
    [CmdletBinding()]
    param(
        [string] $ProjectRoot
    )

    if ([string]::IsNullOrEmpty($ProjectRoot)) {
        $ProjectRoot = (Get-Location).ProviderPath
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

function Get-ToolRoot {
    [CmdletBinding()]
    param(
        [string] $ToolRoot,
        [string] $ProjectRoot
    )

    $tried = New-Object System.Collections.Generic.List[string]

    if (-not [string]::IsNullOrEmpty($ToolRoot)) {
        if (-not (Test-Path -LiteralPath $ToolRoot -PathType Container)) {
            throw ('Get-ToolRoot: channel 1 (-ToolRoot parameter): directory not found: {0}. Provide a valid existing directory or omit -ToolRoot to fall back to env / dogfooding / legacy channels.' -f $ToolRoot)
        }
        return [System.IO.Path]::GetFullPath($ToolRoot)
    }
    $tried.Add('channel 1 (-ToolRoot parameter): not provided') | Out-Null

    $envTool = [System.Environment]::GetEnvironmentVariable('AI_HARNESS_TOOL_ROOT')
    if (-not [string]::IsNullOrEmpty($envTool)) {
        if (-not (Test-Path -LiteralPath $envTool -PathType Container)) {
            throw ('Get-ToolRoot: channel 2 (env AI_HARNESS_TOOL_ROOT): directory not found: {0}. Set AI_HARNESS_TOOL_ROOT to an existing directory or unset it to fall back to dogfooding / legacy channels.' -f $envTool)
        }
        return [System.IO.Path]::GetFullPath($envTool)
    }
    $tried.Add('channel 2 (env AI_HARNESS_TOOL_ROOT): not set or empty') | Out-Null

    $project = Get-ProjectRoot -ProjectRoot $ProjectRoot

    if (Test-IsSourceRepoRoot -Path $project) {
        return $project
    }
    $tried.Add(('channel 3 (dogfooding multi-marker on ProjectRoot={0}): markers missing' -f $project)) | Out-Null

    $legacy = Join-Path -Path $project -ChildPath '.ai-harness'
    if (Test-Path -LiteralPath $legacy -PathType Container) {
        return [System.IO.Path]::GetFullPath($legacy)
    }
    $tried.Add(('channel 4 (legacy <ProjectRoot>/.ai-harness): not present at {0}' -f $legacy)) | Out-Null

    $trace = $tried -join '; '
    throw ('Get-ToolRoot: no ToolRoot channel could be resolved. Tried: {0}. Set AI_HARNESS_TOOL_ROOT or pass -ToolRoot.' -f $trace)
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
