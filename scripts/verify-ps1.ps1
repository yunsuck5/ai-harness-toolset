Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptsDir = $PSScriptRoot

$failures = New-Object System.Collections.Generic.List[psobject]
$ps1Files = @(Get-ChildItem -Path $scriptsDir -Recurse -Filter '*.ps1' -File)

foreach ($file in $ps1Files) {
    $path = $file.FullName

    $bytes = [System.IO.File]::ReadAllBytes($path)
    if ($bytes.Length -lt 3 -or $bytes[0] -ne 0xEF -or $bytes[1] -ne 0xBB -or $bytes[2] -ne 0xBF) {
        $failures.Add([pscustomobject]@{
            Path   = $path
            Reason = 'missing UTF-8 BOM'
        })
        continue
    }

    $content = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
    if ($content -notmatch "`r`n") {
        Write-Warning ("verify-ps1: no CRLF found in {0}" -f $path)
    }

    $tokens = $null
    $errors = $null
    [void] [System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$tokens, [ref]$errors)
    if ($null -ne $errors -and $errors.Count -gt 0) {
        $failures.Add([pscustomobject]@{
            Path   = $path
            Reason = 'parse error: ' + ($errors[0].Message)
        })
    }
}

if ($failures.Count -gt 0) {
    Write-Host 'verify-ps1: FAIL'
    foreach ($f in $failures) {
        Write-Host ('  {0} -- {1}' -f $f.Path, $f.Reason)
    }
    exit 1
}

Write-Host ('verify-ps1: PASS ({0} files)' -f $ps1Files.Count)
exit 0
