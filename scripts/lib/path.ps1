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

    $marker = Join-Path -Path $Path -ChildPath 'scripts/verify-ps1.ps1'
    return (Test-Path -LiteralPath $marker -PathType Leaf)
}

function Get-ToolRoot {
    [CmdletBinding()]
    param(
        [string] $ToolRoot,
        [string] $ProjectRoot
    )

    if (-not [string]::IsNullOrEmpty($ToolRoot)) {
        if (-not (Test-Path -LiteralPath $ToolRoot -PathType Container)) {
            throw "Get-ToolRoot: directory not found: $ToolRoot"
        }
        return [System.IO.Path]::GetFullPath($ToolRoot)
    }

    $project = Get-ProjectRoot -ProjectRoot $ProjectRoot

    if (Test-IsSourceRepoRoot -Path $project) {
        return $project
    }

    $deployed = Join-Path -Path $project -ChildPath '.ai-harness'
    return [System.IO.Path]::GetFullPath($deployed)
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
