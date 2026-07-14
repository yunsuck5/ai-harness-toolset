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

# Step F tests/** raw native stderr-capture lint.
#
# B/C/D/E migrated tests away from `& <native> ... 2>&1` capture patterns
# toward the Invoke-NativeProcess containment shim (scripts/lib/native-process.ps1)
# because the raw form interacts badly with file-level $ErrorActionPreference = 'Stop'
# (NativeCommandError fires before $LASTEXITCODE can be read). This lint prevents
# accidental reintroduction of the captured-for-use form in tests/**/*.ps1.
#
# Scope: source-repo only (gated by Test-IsSourceRepoRoot). Target / project-local
# contexts don't carry the toolset's own tests/ tree, and even if they have an
# unrelated tests/ dir, that dir is not the toolset's to lint.
#
# Rule: a line in tests/**/*.ps1 matching `& <exe> ... 2>&1` is a violation
# UNLESS the line ALSO matches one of these allowed forms:
#   - `$null = & <exe> ... 2>&1`             explicit-discard via $null
#   - `& <exe> ... 2>&1 | Out-Null`          pipe-to-null discard
#   - a `# verify-ps1-allow: <non-empty reason>` pragma on the same line
#     (the matcher requires at least one non-whitespace character after the
#     colon — a bare `# verify-ps1-allow:` is NOT accepted, so the exemption
#     must always carry a brief free-form reason)
#
# The pragma escape hatch is for known-intentional sites that the synthesis report
# explicitly excluded from Invoke-NativeProcess migration (e.g. Step 1
# EAP=Continue try/finally mitigation, or Step E out-of-scope known sites pending
# a future batch). The required non-empty reason keeps each exemption accountable
# rather than silent.
#
# This lint is intentionally conservative on the matching side. Lines that invoke
# a native command through a variable (`& $exe`) or scriptblock (`& { ... }`) are
# NOT linted because they are not the migrated-away pattern. The matcher targets
# the literal `& <identifier>` shape that the Step D migration replaced.
if (Test-IsSourceRepoRoot -Path $repoRoot) {
    $testsDir = Join-Path $repoRoot 'tests'
    if (Test-Path -LiteralPath $testsDir -PathType Container) {
        $testFiles = @(Get-ChildItem -Path $testsDir -Recurse -Filter '*.ps1' -File)
        $stepFViolations = New-Object System.Collections.Generic.List[psobject]
        foreach ($tf in $testFiles) {
            $tfPath = $tf.FullName
            $tfLines = [System.IO.File]::ReadAllLines($tfPath, [System.Text.Encoding]::UTF8)
            for ($i = 0; $i -lt $tfLines.Count; $i++) {
                $tfLine = $tfLines[$i]
                if ($tfLine -notmatch '2>&1') { continue }
                $parseErrors = $null
                $lineTokens = @([System.Management.Automation.PSParser]::Tokenize($tfLine, [ref] $parseErrors))
                $hasReasonedPragma = $false
                foreach ($token in $lineTokens) {
                    if ($token.Type -eq 'Comment' -and $token.Content -match '^#\s*verify-ps1-allow\s*:\s*\S') {
                        $hasReasonedPragma = $true
                        break
                    }
                }
                if ($hasReasonedPragma) { continue }   # actual same-line comment pragma; marker text inside command data is not an exemption
                if ($tfLine -match '^\s*#') { continue }
                if ($tfLine -notmatch '&\s+[A-Za-z][\w.-]*') { continue }
                if ($tfLine -match '\$null\s*=\s*&\s+[A-Za-z][\w.-]*.*2>&1') { continue }
                if ($tfLine -match '2>&1\s*\|\s*Out-Null') { continue }
                $stepFViolations.Add([pscustomobject]@{
                    Path = $tfPath
                    Line = ($i + 1)
                    Text = $tfLine.Trim()
                })
            }
        }
        if ($stepFViolations.Count -gt 0) {
            Write-Host 'verify-ps1: FAIL Step F tests/** raw native stderr-capture lint: use Invoke-NativeProcess (scripts/lib/native-process.ps1), $null = ... 2>&1, ... 2>&1 | Out-Null, or add a # verify-ps1-allow: <reason> pragma'
            foreach ($v in $stepFViolations) {
                Write-Host ('  {0}:{1}: {2}' -f $v.Path, $v.Line, $v.Text)
            }
            exit 1
        }
    }
}

Write-Host ('verify-ps1: PASS ({0} files)' -f $ps1Files.Count)
exit 0
