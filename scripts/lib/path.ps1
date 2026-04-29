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
    return Join-Path -Path $project -ChildPath 'log'
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
