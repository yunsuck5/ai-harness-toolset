[CmdletBinding()]
param(
    [string] $SnippetPath,
    [Parameter(Mandatory = $true)] [string] $TargetPath,
    [switch] $DryRun,
    # Dry-run only: print the full managed-block before/after dump (legacy behavior). Without it,
    # dry-run prints a COMPACT change summary (line counts + unchanged prefix/suffix + changed window
    # + first differing line), which keeps a one-line drift readable instead of dumping the whole
    # block twice. Has no effect outside -DryRun; does not change apply behavior.
    [switch] $ShowFullDiff,
    # -Remove: REMOVE the managed block (marker span) from the target instead of applying a snippet.
    # Used by uninstall (IU-B-08 batch 3). This reuses THIS tool's hardened IO unchanged — BOM
    # refusal, U+FFFD sentinel, the single `.amb-backup` create/rollback/cleanup lifecycle, and the
    # post-write verify — so there is no separate or drifting removal IO path. In -Remove mode
    # SnippetPath is ignored; the new content is computed by lib/managed-block.ps1 Remove-ManagedBlock
    # (marker span excised, marker-outside content preserved byte-for-byte); the post-write verify
    # becomes "ZERO marker pairs remain"; a target that already has 0 marker pairs is an idempotent
    # no-op (no write, no backup); and the file is NEVER deleted (an emptied file is left as empty
    # content). Marker fail-fast cases (2+/incomplete/ordering/malformed) fail before any write.
    [switch] $Remove,
    # -Insert: FIRST-TIME insertion of the snippet's managed block into a target that does NOT already
    # carry one (IU-B-09 fresh-install regression closeout). This is the deterministic CLI for the
    # fresh-install bootstrap that previously required a manual operator splice. It is the complement
    # of the default (replace) mode and does NOT weaken it: the new content is computed by
    # lib/managed-block.ps1 Add-ManagedBlock, which acts ONLY on a 0-marker-pair (or absent) target and
    # FAIL-FASTS when the target already has exactly 1 marker pair (steady-state replacement territory
    # owned by the default mode). It reuses THIS tool's hardened IO — BOM refusal, U+FFFD sentinel, and
    # the post-write block==snippet verify — and, when the target already EXISTS (0-pair append), the
    # single `.amb-backup` create/rollback/cleanup lifecycle. When the target is ABSENT a new file is
    # CREATED (no backup exists to roll back; a failed create/verify deletes the just-created file so no
    # partial artifact is left). -Insert and -Remove are mutually exclusive.
    [switch] $Insert
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

if ($Insert -and $Remove) {
    Write-Host 'apply-managed-block: FAIL -Insert and -Remove are mutually exclusive.'
    exit 1
}
if (-not $Remove) {
    # Both the default (replace) and -Insert modes carry a snippet; only -Remove omits it.
    if ([string]::IsNullOrEmpty($SnippetPath) -or -not (Test-Path -LiteralPath $SnippetPath -PathType Leaf)) {
        Write-Host ('apply-managed-block: FAIL snippet not found: {0}' -f $SnippetPath)
        exit 1
    }
}
# -Insert is the ONLY mode that may target an absent file (first-time create). Every other mode
# requires an existing target.
$targetExists = Test-Path -LiteralPath $TargetPath -PathType Leaf
# A path that EXISTS but is NOT a leaf file (e.g. a directory) is never a valid managed-block target.
# Refuse it for EVERY mode before any write — otherwise -Insert would treat it as "absent" (Test-Path
# -PathType Leaf is false for a directory), route into the create path, and on a write failure delete
# foreign content (e.g. a pre-existing empty directory) at that path.
if ((Test-Path -LiteralPath $TargetPath) -and -not $targetExists) {
    Write-Host ('apply-managed-block: FAIL target path exists but is not a file (refusing to treat a non-file path as a managed-block target): {0}' -f $TargetPath)
    exit 1
}
if (-not $targetExists -and -not $Insert) {
    Write-Host ('apply-managed-block: FAIL target not found: {0}' -f $TargetPath)
    exit 1
}

# BOM policy: managed activation files are UTF-8 without a BOM. Refuse a BOM-prefixed target rather
# than flip its byte shape under the user. Only meaningful when the target exists; an absent -Insert
# target has no bytes to inspect (and is created without a BOM via Write-Utf8NoBom).
$resolvedTarget = $null
$targetBytes = $null
if ($targetExists) {
    $resolvedTarget = (Resolve-Path -LiteralPath $TargetPath).ProviderPath
    $targetBytes = [System.IO.File]::ReadAllBytes($resolvedTarget)
    if ($targetBytes.Length -ge 3 -and $targetBytes[0] -eq 0xEF -and $targetBytes[1] -eq 0xBB -and $targetBytes[2] -eq 0xBF) {
        Write-Host ('apply-managed-block: FAIL target has a UTF-8 BOM; expected UTF-8 without BOM: {0}' -f $TargetPath)
        exit 1
    }
}

# Compute the full new content first. Any marker / structural failure throws here,
# before the single write below, so a failed apply never leaves a partial write.
$noopRemoval = $false
try {
    if ($targetExists) {
        $target = Read-Utf8 -Path $TargetPath
        # A-2b corruption sentinel gate: refuse already-corrupted input (U+FFFD) before
        # any write, so a prior lossy decode persisted on disk cannot be laundered into a
        # freshly rewritten file. Runs before content construction, inside this pre-write try.
        Assert-NoCorruptionSentinel -Content $target -Label 'target'
    }
    else {
        # Absent -Insert target: nothing on disk to read or sentinel-gate; the snippet is the
        # only input and is sentinel-gated below.
        $target = ''
    }
    if ($Insert) {
        # First-time insertion. Add-ManagedBlock acts only on a 0-pair (or absent) target and throws
        # on a 1-pair target (caught here -> FAIL, no write), preserving the default mode's replace-only
        # semantics. The snippet's own block is sentinel-gated before construction.
        $snippet = Read-Utf8 -Path $SnippetPath
        Assert-NoCorruptionSentinel -Content $snippet -Label 'snippet'
        $insertion = Add-ManagedBlock -TargetContent $target -SnippetContent $snippet -TargetExists $targetExists
        $newContent = $insertion.Content
    }
    elseif ($Remove) {
        # Removal: marker span excised, marker-outside content preserved. 0 pairs -> no-op success;
        # 2+/incomplete/ordering/malformed -> Remove-ManagedBlock throws (caught below, no write).
        $removal = Remove-ManagedBlock -TargetContent $target
        if (-not $removal.Removed) {
            $noopRemoval = $true
            $newContent  = $target
        }
        else {
            $newContent = $removal.Content
        }
    }
    else {
        $snippet = Read-Utf8 -Path $SnippetPath
        Assert-NoCorruptionSentinel -Content $snippet -Label 'snippet'
        $newContent = Set-ManagedBlock -TargetContent $target -SnippetContent $snippet
    }
}
catch {
    Write-Host ('apply-managed-block: FAIL {0}' -f $_.Exception.Message)
    exit 1
}

# -Remove on a target that has no managed block is an idempotent no-op: nothing to write, no backup,
# file untouched (and never deleted).
if ($Remove -and $noopRemoval) {
    Write-Host ('apply-managed-block: target has no managed block; nothing to remove (no-op): {0}' -f $TargetPath)
    Write-Host 'apply-managed-block: PASS'
    exit 0
}

# A-2d dry-run / diff preview. By this point every pre-write gate has run (existence,
# BOM, strict UTF-8, U+FFFD sentinel, marker validation) and the would-be new content
# is constructed. Dry-run reuses that exact path, then prints a COMPACT change summary
# (default) or the whole managed-block before/after dump (-ShowFullDiff), and exits WITHOUT
# writing the target or creating a backup — the backup/write section below is never reached.
if ($DryRun) {
    if ($Insert) {
        # Reaching here means Add-ManagedBlock already validated the insert (absent or 0-pair target);
        # a 1-pair / malformed target threw above and exited FAIL. The snippet block is what would land.
        $newBlock = Get-ManagedBlockContent -Content $snippet -Label 'snippet'
        $insertMode = if ($targetExists) { 'append (existing target, 0 marker pairs)' } else { 'create (absent target)' }
        Write-Host 'apply-managed-block: DRY-RUN -Insert (no file written, no backup created)'
        Write-Host ('apply-managed-block: target {0}' -f $TargetPath)
        Write-Host ('apply-managed-block: source snippet {0}' -f $SnippetPath)
        Write-Host ('apply-managed-block: managed block WOULD be inserted [{0}] ({1} line(s)); marker-outside content preserved' -f $insertMode, $newBlock.Count)
        Write-Host 'apply-managed-block: DRY-RUN PASS (managed block WOULD be inserted)'
        exit 0
    }
    if ($Remove) {
        # No-op removal already exited above, so here exactly one marker pair exists and would go.
        $oldBlock = Get-ManagedBlockContent -Content $target -Label 'destination'
        Write-Host 'apply-managed-block: DRY-RUN -Remove (no file written, no backup created)'
        Write-Host ('apply-managed-block: target {0}' -f $TargetPath)
        Write-Host ('apply-managed-block: managed block WOULD be removed ({0} line(s), BEGIN..END inclusive); marker-outside content preserved; file not deleted' -f $oldBlock.Count)
        Write-Host 'apply-managed-block: DRY-RUN PASS (managed block WOULD be removed)'
        exit 0
    }
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

# -Insert into an ABSENT target: CREATE a new file. There is no original on disk, so there is NO
# backup to roll back to. On any write/verify failure, delete the just-created file so a failed
# first-time create leaves no partial artifact. (The 0-pair APPEND case has an existing target and
# falls through to the shared backup/rollback section below.)
if ($Insert -and -not $targetExists) {
    try {
        Write-Utf8NoBom -Path $TargetPath -Content $newContent
        # Verify: the created file's managed block must equal the snippet's block (terminator-agnostic).
        # Get-ManagedBlockContent on the destination also asserts exactly one marker pair (it throws
        # otherwise), so a malformed create is caught and the file is removed below.
        $snippetBlock = Get-ManagedBlockContent -Content $snippet -Label 'snippet'
        $writtenBlock = Get-ManagedBlockContent -Content (Read-Utf8 -Path $TargetPath) -Label 'destination'
        $mismatch = $false
        if ($snippetBlock.Count -ne $writtenBlock.Count) {
            $mismatch = $true
        }
        else {
            for ($i = 0; $i -lt $snippetBlock.Count; $i++) {
                if ($snippetBlock[$i] -cne $writtenBlock[$i]) { $mismatch = $true; break }
            }
        }
        if ($mismatch) {
            throw 'post-insert verification: created file block does not equal snippet block.'
        }
    }
    catch {
        $failMessage = $_.Exception.Message
        # Delete only a leaf FILE (the one we just tried to create). The pre-write guard above already
        # refused a non-file path, so this can only remove our own partial create — never a directory.
        if (Test-Path -LiteralPath $TargetPath -PathType Leaf) {
            Remove-Item -LiteralPath $TargetPath -Force -ErrorAction SilentlyContinue
        }
        Write-Host ('apply-managed-block: FAIL {0}' -f $failMessage)
        Write-Host 'apply-managed-block: created file removed; no partial artifact left.'
        exit 1
    }
    Write-Host ('apply-managed-block: created {0} with managed block (first-time insertion)' -f $TargetPath)
    Write-Host ('apply-managed-block: source snippet {0}' -f $SnippetPath)
    Write-Host 'apply-managed-block: PASS'
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

    # Post-write verification. A mismatch — or a failure reading the file back — means the write
    # produced unexpected content, so raise an error the rollback handles instead of leaving the bad
    # write in place.
    if ($Remove) {
        # Removal verify: ZERO marker pairs must remain (the marker lines themselves were excised,
        # so this is NOT "block == snippet"; it is "no managed block left").
        $writtenSegments = @(Split-ManagedBlockLines -Content (Read-Utf8 -Path $TargetPath))
        $writtenScan = Find-ManagedBlockMarkers -Segments $writtenSegments
        if (($writtenScan.BeginIndices.Count + $writtenScan.EndIndices.Count) -ne 0) {
            throw 'post-removal verification: marker pair(s) still present after removal.'
        }
    }
    else {
        # Apply (replace) AND -Insert append verify: the destination's managed block must now equal the
        # snippet's managed block (line content, terminator-agnostic). Get-ManagedBlockContent on the
        # destination also asserts exactly one marker pair, so an insert that produced more than one
        # pair is caught here and rolled back.
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
            $verifyLabel = if ($Insert) { 'post-insert verification' } else { 'post-apply verification' }
            throw ('{0}: destination block does not equal snippet block.' -f $verifyLabel)
        }
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

if ($Remove) {
    Write-Host ('apply-managed-block: removed managed block from {0}' -f $TargetPath)
}
elseif ($Insert) {
    Write-Host ('apply-managed-block: inserted managed block into {0} (first-time insertion, appended after existing content)' -f $TargetPath)
    Write-Host ('apply-managed-block: source snippet {0}' -f $SnippetPath)
}
else {
    Write-Host ('apply-managed-block: applied managed block to {0}' -f $TargetPath)
    Write-Host ('apply-managed-block: source snippet {0}' -f $SnippetPath)
}
Write-Host 'apply-managed-block: PASS'
exit 0
