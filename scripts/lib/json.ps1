Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'encoding.ps1')

function Read-JsonFile {
    param(
        [string] $Path
    )

    if ([string]::IsNullOrEmpty($Path)) {
        throw 'Read-JsonFile: -Path is required.'
    }
    $text = Read-Utf8 -Path $Path
    return ($text | ConvertFrom-Json)
}

function Write-JsonFile {
    param(
        [string] $Path,
        $Value,
        [int] $Depth = 32
    )

    if ([string]::IsNullOrEmpty($Path)) {
        throw 'Write-JsonFile: -Path is required.'
    }
    Write-JsonUtf8NoBom -Path $Path -Value $Value -Depth $Depth
}
