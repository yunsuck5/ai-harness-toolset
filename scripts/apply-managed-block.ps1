[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)] [string] $SnippetPath,
    [Parameter(Mandatory = $true)] [string] $TargetPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Deterministic managed-block apply tool. Replaces the AI_HARNESS_TOOLSET_GLOBAL
# managed block inside an existing destination file (e.g. CLAUDE.md / AGENTS.md)
# with the block carried by a snippet, preserving everything outside the block.
#
# It exists to remove the ad-hoc PowerShell splice that caused the 2026-05-21
# UTF-8 corruption incident: all reads/writes go through lib/encoding.ps1
# (UTF-8 explicit), never Get-Content / Set-Content.
#
# Encoding / newline / BOM policy:
#   - Read/write are UTF-8 (no BOM). The destination MUST be UTF-8 without a BOM
#     (the activation-file convention); a BOM-prefixed target is refused rather
#     than silently rewritten.
#   - Content outside the managed block is preserved byte-for-byte. The block
#     region is rendered with the destination's detected newline convention.
#   - On any validation failure the tool fails fast BEFORE writing — no partial write.
#
# Scope guard: this tool edits a caller-supplied destination path only. It does not
# resolve, target, or apply to %USERPROFILE%\.claude or %USERPROFILE%\.codex on its
# own; choosing the destination (and approving a global/user activation apply) is a
# separate, explicit, user-approved step outside this primitive.

. (Join-Path $PSScriptRoot 'lib/encoding.ps1')
. (Join-Path $PSScriptRoot 'lib/managed-block.ps1')

if (-not (Test-Path -LiteralPath $SnippetPath -PathType Leaf)) {
    Write-Host ('apply-managed-block: FAIL snippet not found: {0}' -f $SnippetPath)
    exit 1
}
if (-not (Test-Path -LiteralPath $TargetPath -PathType Leaf)) {
    Write-Host ('apply-managed-block: FAIL target not found: {0}' -f $TargetPath)
    exit 1
}

# BOM policy: managed activation files are UTF-8 without a BOM. Refuse a
# BOM-prefixed target rather than flip its byte shape under the user.
$resolvedTarget = (Resolve-Path -LiteralPath $TargetPath).ProviderPath
$targetBytes = [System.IO.File]::ReadAllBytes($resolvedTarget)
if ($targetBytes.Length -ge 3 -and $targetBytes[0] -eq 0xEF -and $targetBytes[1] -eq 0xBB -and $targetBytes[2] -eq 0xBF) {
    Write-Host ('apply-managed-block: FAIL target has a UTF-8 BOM; expected UTF-8 without BOM: {0}' -f $TargetPath)
    exit 1
}

# Compute the full new content first. Any marker / structural failure throws here,
# before the single write below, so a failed apply never leaves a partial write.
try {
    $snippet    = Read-Utf8 -Path $SnippetPath
    $target     = Read-Utf8 -Path $TargetPath
    $newContent = Set-ManagedBlock -TargetContent $target -SnippetContent $snippet
}
catch {
    Write-Host ('apply-managed-block: FAIL {0}' -f $_.Exception.Message)
    exit 1
}

Write-Utf8NoBom -Path $TargetPath -Content $newContent

# Post-apply verification: the destination's managed block must now equal the
# snippet's managed block (line content, terminator-agnostic).
try {
    $snippetBlock = Get-ManagedBlockContent -Content $snippet -Label 'snippet'
    $writtenBlock = Get-ManagedBlockContent -Content (Read-Utf8 -Path $TargetPath) -Label 'destination'
}
catch {
    Write-Host ('apply-managed-block: FAIL post-apply verification: {0}' -f $_.Exception.Message)
    exit 1
}

$mismatch = $false
if ($snippetBlock.Count -ne $writtenBlock.Count) {
    $mismatch = $true
}
else {
    for ($i = 0; $i -lt $snippetBlock.Count; $i++) {
        if ($snippetBlock[$i] -cne $writtenBlock[$i]) {
            $mismatch = $true
            break
        }
    }
}
if ($mismatch) {
    Write-Host 'apply-managed-block: FAIL post-apply verification: destination block does not equal snippet block.'
    exit 1
}

Write-Host ('apply-managed-block: applied managed block to {0}' -f $TargetPath)
Write-Host ('apply-managed-block: source snippet {0}' -f $SnippetPath)
Write-Host 'apply-managed-block: PASS'
exit 0
