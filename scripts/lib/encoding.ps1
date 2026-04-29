Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Read-Utf8 {
    param(
        [string] $Path
    )

    if ([string]::IsNullOrEmpty($Path)) {
        throw 'Read-Utf8: -Path is required.'
    }
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Read-Utf8: file not found: $Path"
    }

    $resolved = (Resolve-Path -LiteralPath $Path).ProviderPath
    $encoding = New-Object System.Text.UTF8Encoding($false)
    return [System.IO.File]::ReadAllText($resolved, $encoding)
}

function Write-Utf8NoBom {
    param(
        [string] $Path,
        [string] $Content = ''
    )

    if ([string]::IsNullOrEmpty($Path)) {
        throw 'Write-Utf8NoBom: -Path is required.'
    }

    $parent = Split-Path -LiteralPath $Path
    if (-not [string]::IsNullOrEmpty($parent) -and -not (Test-Path -LiteralPath $parent -PathType Container)) {
        $null = New-Item -ItemType Directory -Path $parent -Force
    }

    $resolved = [System.IO.Path]::GetFullPath($Path)
    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($resolved, $Content, $encoding)
}

function Append-Utf8NoBom {
    param(
        [string] $Path,
        [string] $Content = ''
    )

    if ([string]::IsNullOrEmpty($Path)) {
        throw 'Append-Utf8NoBom: -Path is required.'
    }

    $existing = ''
    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        $existing = Read-Utf8 -Path $Path
    }
    Write-Utf8NoBom -Path $Path -Content ($existing + $Content)
}

function Write-JsonUtf8NoBom {
    param(
        [string] $Path,
        $Value,
        [int] $Depth = 32
    )

    if ([string]::IsNullOrEmpty($Path)) {
        throw 'Write-JsonUtf8NoBom: -Path is required.'
    }

    $json = [string]($Value | ConvertTo-Json -Depth $Depth)
    $json = $json -replace "`r`n", "`n"
    $json = $json -replace "`r", "`n"
    Write-Utf8NoBom -Path $Path -Content $json
}

function Write-Utf8BomCrlf {
    param(
        [string] $Path,
        [string] $Content = ''
    )

    if ([string]::IsNullOrEmpty($Path)) {
        throw 'Write-Utf8BomCrlf: -Path is required.'
    }

    $parent = Split-Path -LiteralPath $Path
    if (-not [string]::IsNullOrEmpty($parent) -and -not (Test-Path -LiteralPath $parent -PathType Container)) {
        $null = New-Item -ItemType Directory -Path $parent -Force
    }

    $resolved = [System.IO.Path]::GetFullPath($Path)
    $normalized = $Content -replace "`r`n", "`n"
    $normalized = $normalized -replace "`r", "`n"
    $normalized = $normalized -replace "`n", "`r`n"
    $encoding = New-Object System.Text.UTF8Encoding($true)
    [System.IO.File]::WriteAllText($resolved, $normalized, $encoding)
}
