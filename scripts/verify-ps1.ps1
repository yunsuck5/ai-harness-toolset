Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'lib/path.ps1')
. (Join-Path $PSScriptRoot 'lib/git.ps1')

$scriptsDir = $PSScriptRoot
$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).ProviderPath

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

# D8 self-target enforcement: in the source repo, no git-tracked file is allowed
# under log/. The check is skipped in target/project-local contexts (no multi-marker).
# This is commit-time discipline; no hook/watcher/daemon is registered.
if (Test-IsSourceRepoRoot -Path $repoRoot) {
    $lsResult = Invoke-GitCapture -Arguments @('ls-files', '--', 'log') -WorkingDirectory $repoRoot
    if ($lsResult.ExitCode -ne 0) {
        Write-Host ('verify-ps1: WARN D8 self-target check skipped (git ls-files exit {0})' -f $lsResult.ExitCode)
    }
    else {
        $trackedLog = @($lsResult.StdOut -split "`r?`n" | Where-Object { -not [string]::IsNullOrEmpty($_) })
        if ($trackedLog.Count -gt 0) {
            Write-Host 'verify-ps1: FAIL D8 self-target enforcement: git-tracked file(s) found under log/ in source repo:'
            foreach ($t in $trackedLog) {
                Write-Host ('  {0}' -f $t)
            }
            exit 1
        }
    }
}

Write-Host ('verify-ps1: PASS ({0} files)' -f $ps1Files.Count)
exit 0
