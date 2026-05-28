[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)] [string] $SnippetPath,
    [Parameter(Mandatory = $true)] [string] $TargetPath,
    [switch] $DryRun,
    # Dry-run only: print the full managed-block before/after dump (legacy behavior). Without it,
    # dry-run prints a COMPACT change summary (line counts + unchanged prefix/suffix + changed window
    # + first differing line), which keeps a one-line drift readable instead of dumping the whole
    # block twice. Has no effect outside -DryRun; does not change apply behavior.
    [switch] $ShowFullDiff
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
#   - With -DryRun the tool runs the full pre-write validation path (existence, BOM,
#     strict UTF-8 read, U+FFFD sentinel, marker validation, new-content construction)
#     and prints a COMPACT change summary (line counts + unchanged prefix/suffix + changed
#     window + first differing line) by default, but writes nothing and creates no backup.
#     -ShowFullDiff additionally prints the whole managed-block before/after dump. This is
#     line-position trimming for the summary, not an LCS diff engine.
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
    # A-2b corruption sentinel gate: refuse already-corrupted input (U+FFFD) before
    # any write, so a prior lossy decode persisted on disk cannot be laundered into a
    # freshly rewritten file. Runs before Set-ManagedBlock, inside this pre-write try.
    Assert-NoCorruptionSentinel -Content $target -Label 'target'
    Assert-NoCorruptionSentinel -Content $snippet -Label 'snippet'
    $newContent = Set-ManagedBlock -TargetContent $target -SnippetContent $snippet
}
catch {
    Write-Host ('apply-managed-block: FAIL {0}' -f $_.Exception.Message)
    exit 1
}

# A-2d dry-run / diff preview. By this point every pre-write gate has run (existence,
# BOM, strict UTF-8, U+FFFD sentinel, marker validation) and the would-be new content
# is constructed. Dry-run reuses that exact path, then prints a COMPACT change summary
# (default) or the whole managed-block before/after dump (-ShowFullDiff), and exits WITHOUT
# writing the target or creating a backup — the backup/write section below is never reached.
if ($DryRun) {
    $oldBlock = Get-ManagedBlockContent -Content $target  -Label 'destination'
    $newBlock = Get-ManagedBlockContent -Content $snippet -Label 'snippet'

    $changed = $false
    if ($oldBlock.Count -ne $newBlock.Count) {
        $changed = $true
    }
    else {
        for ($i = 0; $i -lt $oldBlock.Count; $i++) {
            if ($oldBlock[$i] -cne $newBlock[$i]) {
                $changed = $true
                break
            }
        }
    }

    Write-Host 'apply-managed-block: DRY-RUN (no file written, no backup created)'
    Write-Host ('apply-managed-block: target {0}' -f $TargetPath)
    Write-Host ('apply-managed-block: source snippet {0}' -f $SnippetPath)
    if ($changed) {
        # Compact change summary (default). Trim the common prefix/suffix so the reported "changed
        # window" is tight — a one-line drift shows as -1/+1 instead of dumping the whole block twice.
        # This is line-position trimming, not an LCS diff engine, which keeps it small and deterministic.
        $min = [Math]::Min($oldBlock.Count, $newBlock.Count)
        $prefix = 0
        while ($prefix -lt $min -and ($oldBlock[$prefix] -ceq $newBlock[$prefix])) { $prefix++ }
        $suffix = 0
        while ($suffix -lt ($min - $prefix) -and ($oldBlock[$oldBlock.Count - 1 - $suffix] -ceq $newBlock[$newBlock.Count - 1 - $suffix])) { $suffix++ }
        $oldWin = $oldBlock.Count - $prefix - $suffix
        $newWin = $newBlock.Count - $prefix - $suffix

        Write-Host 'apply-managed-block: managed block WOULD change (compact summary; use -ShowFullDiff for full before/after)'
        Write-Host ('apply-managed-block:   block lines: current={0} proposed={1}' -f $oldBlock.Count, $newBlock.Count)
        Write-Host ('apply-managed-block:   unchanged: prefix={0} suffix={1}' -f $prefix, $suffix)
        Write-Host ('apply-managed-block:   changed window: current=-{0} proposed=+{1} at block line {2}' -f $oldWin, $newWin, ($prefix + 1))
        if ($oldWin -gt 0) { Write-Host ('apply-managed-block:   first changed current line: {0}' -f $oldBlock[$prefix]) }
        else               { Write-Host 'apply-managed-block:   first changed current line: (none; lines only added)' }
        if ($newWin -gt 0) { Write-Host ('apply-managed-block:   first changed proposed line: {0}' -f $newBlock[$prefix]) }
        else               { Write-Host 'apply-managed-block:   first changed proposed line: (none; lines only removed)' }

        if ($ShowFullDiff) {
            Write-Host 'apply-managed-block: managed block diff (- current / + proposed):'
            foreach ($line in $oldBlock) { Write-Host ('- {0}' -f $line) }
            foreach ($line in $newBlock) { Write-Host ('+ {0}' -f $line) }
        }
        Write-Host 'apply-managed-block: DRY-RUN PASS (managed block WOULD change)'
    }
    else {
        Write-Host 'apply-managed-block: managed block is already up to date (no change).'
        Write-Host 'apply-managed-block: DRY-RUN PASS (no change)'
    }
    exit 0
}

# A-2c backup / rollback. Every pre-write gate above (snippet/target existence, BOM,
# strict UTF-8 read, U+FFFD sentinel, marker structure) has already passed, so the
# backup is created only here — immediately before the single mutation. A pre-write
# failure therefore never leaves a backup artifact.
#
# The backup is a deterministic sidecar next to the target ('<target>.amb-backup')
# holding the original bytes captured before any write ($targetBytes, read above for
# the BOM check). The write + post-write verification run inside one try: on ANY
# failure (a throwing write, an unreadable read-back, or a block mismatch) the
# original bytes are restored from the backup, so the target is never left mutated by
# a failed apply. On success the backup is removed, so the happy path leaves no stale
# artifact. This is a minimal local backup/rollback, not a transaction / journaling
# design (atomicity across process death is out of scope — see A-2c boundaries).
$backupPath = $resolvedTarget + '.amb-backup'

# Refuse if a backup sidecar already exists. The happy path and a clean rollback both
# delete it, so a leftover '.amb-backup' means a PRIOR rollback failed (or a process was
# killed mid-apply) and this file is the only surviving copy of the user's original
# bytes. Overwriting it with the current (possibly already-mutated) target bytes would
# destroy that recovery artifact, so fail fast and leave both the target and the existing
# backup untouched for manual resolution.
if (Test-Path -LiteralPath $backupPath) {
    Write-Host ('apply-managed-block: FAIL a prior backup already exists (a previous rollback may have failed); resolve it before re-applying: {0}' -f $backupPath)
    exit 1
}

[System.IO.File]::WriteAllBytes($backupPath, $targetBytes)

try {
    Write-Utf8NoBom -Path $TargetPath -Content $newContent

    # Post-apply verification: the destination's managed block must now equal the
    # snippet's managed block (line content, terminator-agnostic). A mismatch — or a
    # failure reading the file back — means the write produced unexpected content, so
    # raise an error the rollback handles instead of leaving the bad write in place.
    $snippetBlock = Get-ManagedBlockContent -Content $snippet -Label 'snippet'
    $writtenBlock = Get-ManagedBlockContent -Content (Read-Utf8 -Path $TargetPath) -Label 'destination'

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
        throw 'post-apply verification: destination block does not equal snippet block.'
    }
}
catch {
    $failMessage = $_.Exception.Message
    try {
        $backupBytes = [System.IO.File]::ReadAllBytes($backupPath)
        [System.IO.File]::WriteAllBytes($resolvedTarget, $backupBytes)
        # Cleanup is best-effort: a stuck deletion must not mask a successful restore.
        Remove-Item -LiteralPath $backupPath -Force -ErrorAction SilentlyContinue
        Write-Host ('apply-managed-block: FAIL {0}' -f $failMessage)
        Write-Host 'apply-managed-block: rolled back; target restored to its original bytes.'
    }
    catch {
        Write-Host ('apply-managed-block: FAIL {0}' -f $failMessage)
        Write-Host ('apply-managed-block: ROLLBACK FAILED ({0}); original bytes preserved at backup: {1}' -f $_.Exception.Message, $backupPath)
    }
    exit 1
}

# Success: apply and verification both passed. Remove the backup so the happy path
# leaves no stale artifact. Best-effort: a failed cleanup must not turn a successful
# apply into a failure (it would only leave a stale sidecar, reported as a tradeoff).
Remove-Item -LiteralPath $backupPath -Force -ErrorAction SilentlyContinue

Write-Host ('apply-managed-block: applied managed block to {0}' -f $TargetPath)
Write-Host ('apply-managed-block: source snippet {0}' -f $SnippetPath)
Write-Host 'apply-managed-block: PASS'
exit 0
