Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Deterministic managed-block apply primitive for ai-harness-toolset activation
# surfaces (e.g. CLAUDE.md / AGENTS.md). It replaces the ad-hoc PowerShell splice
# that caused the 2026-05-21 UTF-8 corruption incident
# (closeout recorded as STATUS ledger IU-OPS-05; incident detail in git history).
#
# Encoding policy:
#   - This library performs NO file IO. Callers MUST pass already-decoded UTF-8
#     text (read via lib/encoding.ps1 Read-Utf8) and write the result via
#     Write-Utf8NoBom. Get-Content / Set-Content are forbidden on this path:
#     their default ANSI-codepage decoding (cp949 on KR Windows PowerShell 5.1)
#     is exactly what corrupted the global instruction files.
#
# Newline / BOM policy (see Set-ManagedBlock):
#   - Content OUTSIDE the managed block is preserved byte-for-byte, including its
#     original line terminators. The splice never rewrites outside bytes.
#   - The replaced managed-block region is rendered with the destination's detected
#     newline convention (CRLF if the destination contains any CRLF, else LF). Its
#     trailing terminator is matched to the original END-marker line's terminator,
#     so the file's trailing-newline shape is unchanged.
#   - BOM handling is the caller's responsibility (apply-managed-block.ps1 requires
#     UTF-8 without BOM, the activation-file convention).
#
# Marker counting rule (self-contained here): fenced code blocks are skipped, and
# a line counts only on a whole-line trim match. Inline-code / prose mentions are
# never counted.

$script:ManagedBlockBeginMarker = '<!-- BEGIN AI_HARNESS_TOOLSET_GLOBAL -->'
$script:ManagedBlockEndMarker   = '<!-- END AI_HARNESS_TOOLSET_GLOBAL -->'

function Split-ManagedBlockLines {
    # Split into physical line segments, each retaining its trailing terminator.
    # Concatenating the result reproduces the input exactly (round-trip safe), so
    # the splice can preserve outside-block bytes verbatim.
    param([string] $Content)

    if ([string]::IsNullOrEmpty($Content)) {
        return @()
    }
    return [regex]::Split($Content, '(?<=\n)')
}

function Get-ManagedBlockLineContent {
    # Strip a single trailing CRLF / LF / CR from a physical line segment.
    param([string] $Segment)

    return ($Segment -replace '(\r\n|\n|\r)$', '')
}

function Find-ManagedBlockMarkers {
    # Walk physical line segments, tracking fenced-code state, and return the
    # 0-based indices of every valid BEGIN / END marker line per the whole-line
    # trim match rule. Throws on an unbalanced fence (structurally malformed).
    param([string[]] $Segments)

    $beginIndices = New-Object System.Collections.Generic.List[int]
    $endIndices   = New-Object System.Collections.Generic.List[int]
    $inFence = $false
    $fenceCharacter = $null
    $fenceLength = 0

    for ($i = 0; $i -lt $Segments.Count; $i++) {
        $trimmed = (Get-ManagedBlockLineContent -Segment $Segments[$i]).Trim()

        # A fence opens with at least three backticks or tildes. Once open, only
        # the same delimiter character with a run at least as long as the opener
        # closes it. An opposite delimiter or a shorter same-character run is
        # ordinary fenced content and must not expose marker-looking lines.
        if (-not $inFence -and $trimmed -match '^(`{3,}|~{3,})') {
            $delimiter = $Matches[1]
            $fenceCharacter = $delimiter.Substring(0, 1)
            $fenceLength = $delimiter.Length
            $inFence = $true
            continue
        }
        if ($inFence) {
            $closerPattern = '^' + [regex]::Escape($fenceCharacter) + '{' + $fenceLength + ',}$'
            if ($trimmed -match $closerPattern) {
                $inFence = $false
                $fenceCharacter = $null
                $fenceLength = 0
            }
            continue
        }
        if ($trimmed -eq $script:ManagedBlockBeginMarker) {
            $beginIndices.Add($i)
            continue
        }
        if ($trimmed -eq $script:ManagedBlockEndMarker) {
            $endIndices.Add($i)
            continue
        }
    }

    if ($inFence) {
        throw 'managed-block: unbalanced fenced code block; file is structurally malformed for managed-block detection.'
    }

    return [pscustomobject]@{
        BeginIndices = $beginIndices.ToArray()
        EndIndices   = $endIndices.ToArray()
    }
}

function Resolve-ManagedBlockSpan {
    # Resolve the single BEGIN/END index pair, or throw a precise fail-fast reason.
    # Rejects 0 pairs, mismatched / multiple markers, and END-before-BEGIN ordering.
    param(
        [string[]] $Segments,
        [string] $Label = 'file'
    )

    $scan = Find-ManagedBlockMarkers -Segments $Segments
    $nb = $scan.BeginIndices.Count
    $ne = $scan.EndIndices.Count

    if ($nb -eq 0 -and $ne -eq 0) {
        throw ("managed-block: no AI_HARNESS_TOOLSET_GLOBAL marker pair found in {0} (expected exactly 1)." -f $Label)
    }
    if ($nb -ne 1 -or $ne -ne 1) {
        throw ("managed-block: ambiguous markers in {0}: found {1} BEGIN and {2} END (expected exactly 1 each)." -f $Label, $nb, $ne)
    }

    $b = $scan.BeginIndices[0]
    $e = $scan.EndIndices[0]
    if ($e -le $b) {
        throw ("managed-block: END marker does not follow BEGIN marker in {0} (BEGIN at line {1}, END at line {2})." -f $Label, ($b + 1), ($e + 1))
    }

    return [pscustomobject]@{
        BeginIndex = $b
        EndIndex   = $e
    }
}

function Get-ManagedBlockContent {
    # Return the managed block as an array of line-content strings (terminators
    # stripped), from the BEGIN marker line through the END marker line inclusive.
    param(
        [string] $Content,
        [string] $Label = 'file'
    )

    $segments = @(Split-ManagedBlockLines -Content $Content)
    $span = Resolve-ManagedBlockSpan -Segments $segments -Label $Label

    $out = New-Object System.Collections.Generic.List[string]
    for ($i = $span.BeginIndex; $i -le $span.EndIndex; $i++) {
        $out.Add((Get-ManagedBlockLineContent -Segment $segments[$i]))
    }
    return $out.ToArray()
}

function Assert-NoCorruptionSentinel {
    # A-2b corruption sentinel gate. Hard-fail if decoded apply input carries the
    # Unicode replacement character U+FFFD.
    #
    # Why this is needed on top of the A-2a strict reader: the bytes EF BF BD are a
    # *valid* UTF-8 encoding of U+FFFD, so Read-Utf8's strict decoder passes them
    # through without error. Their presence in an instruction file is not legitimate
    # content here — it means an earlier lossy decode (e.g. the cp949 mis-decode
    # behind the 2026-05-21 incident) already replaced a non-ASCII character with the
    # replacement char and persisted it. Splicing / rewriting such input would launder
    # corruption into a freshly written file, so refuse before any write.
    #
    # Literal ASCII '?' (0x3F) is deliberately NOT gated here: it is ordinary content
    # (the repo's own CLAUDE_SNIPPET.md contains a '?'), so an input-presence reject
    # would be a false positive. The intended '?' contract is a before/after
    # non-increase check (the "비-ASCII 무손실 gate" rationale; see git history), which is
    # a separate, narrower mechanism left for a follow-up.
    param(
        [string] $Content,
        [string] $Label = 'input'
    )

    if (-not [string]::IsNullOrEmpty($Content) -and $Content.Contains([char]0xFFFD)) {
        throw ("managed-block: U+FFFD replacement character found in {0}; input is already corrupted, refusing to apply." -f $Label)
    }
}

function Set-ManagedBlock {
    # Pure function: return new destination content with its managed block replaced
    # by the snippet's managed block. Performs NO file IO and leaves NO partial
    # state. All marker validation happens before any content is produced, so a
    # caller that writes only the return value never produces a partial write.
    param(
        [string] $TargetContent,
        [string] $SnippetContent
    )

    # Validate + extract the snippet block (snippet must contain exactly one pair).
    $snippetBlockLines = Get-ManagedBlockContent -Content $SnippetContent -Label 'snippet'

    # Locate the destination span (destination must contain exactly one pair).
    $segments = @(Split-ManagedBlockLines -Content $TargetContent)
    $span = Resolve-ManagedBlockSpan -Segments $segments -Label 'destination'
    $b = $span.BeginIndex
    $e = $span.EndIndex

    # Destination newline convention: CRLF wins if any CRLF is present, else LF.
    if ($TargetContent -match '\r\n') {
        $eol = "`r`n"
    }
    else {
        $eol = "`n"
    }

    # Preserve the END line's original trailing terminator (including none at EOF).
    $endTerminator = ''
    if ($segments[$e] -match '(\r\n|\n|\r)$') {
        $endTerminator = $Matches[1]
    }

    $block = ($snippetBlockLines -join $eol) + $endTerminator

    # Splice. Outside-block segments keep their original terminators verbatim.
    $before = ''
    if ($b -gt 0) {
        $before = -join $segments[0..($b - 1)]
    }
    $after = ''
    if ($e -lt ($segments.Count - 1)) {
        $after = -join $segments[($e + 1)..($segments.Count - 1)]
    }

    return ($before + $block + $after)
}

function Remove-ManagedBlock {
    # Pure function: return the destination content with its single managed block
    # (BEGIN..END marker span, INCLUSIVE of the marker lines) excised, preserving all
    # content OUTSIDE the marker pair byte-for-byte. Performs NO file IO and leaves NO
    # partial state, mirroring Set-ManagedBlock. The caller writes the returned Content
    # via Write-Utf8NoBom; the IO-safety scaffolding (BOM / U+FFFD gate / .amb-backup /
    # rollback / post-write verify) belongs to the apply wrapper, NOT this primitive
    # (it must not be duplicated here). That removal IO is provided by the shared hardened
    # entrypoint `apply-managed-block.ps1 -Remove` (IU-B-08 batch 3), which calls this primitive.
    #
    # Removal is deliberately NOT "Set-ManagedBlock with an empty snippet": that would
    # leave an empty marker pair behind. This deletes the marker lines too, so a
    # successful removal leaves ZERO marker pairs.
    #
    # Marker-count branch ordering (the uninstall marker-removal state machine; the
    # design record is preserved in git history):
    #   - 0 markers (no BEGIN and no END)        -> idempotent no-op SUCCESS
    #                                               (Removed = $false; Content unchanged).
    #   - exactly 1 BEGIN + 1 END, in order      -> excise BEGIN..END inclusive
    #                                               (Removed = $true).
    #   - 2+ pairs / incomplete (count mismatch) / END-before-BEGIN ordering violation /
    #     structurally malformed (unbalanced fence) -> FAIL-FAST (throw); no content
    #     produced, so a caller that writes only the returned Content never mutates on a
    #     fail-fast.
    #
    # The file is NEVER deleted by this primitive: when the managed block is the whole
    # file, the returned Content is the empty string '' (the caller writes an empty
    # file; it does not remove it).
    #
    # Returns: [pscustomobject] @{ Removed = [bool]; Content = [string] }
    param(
        [string] $TargetContent
    )

    $segments = @(Split-ManagedBlockLines -Content $TargetContent)

    # Count markers first. Find-ManagedBlockMarkers also fail-fasts (throws) on an
    # unbalanced fenced code block (structurally malformed for marker detection).
    $scan = Find-ManagedBlockMarkers -Segments $segments
    $nb = $scan.BeginIndices.Count
    $ne = $scan.EndIndices.Count

    # 0 markers: idempotent no-op success. Nothing to remove; return content unchanged
    # (Resolve-ManagedBlockSpan would throw on the 0-pair case, which is why the count
    # branch precedes the resolver -- the absence of a block is success, not failure).
    if ($nb -eq 0 -and $ne -eq 0) {
        return [pscustomobject]@{ Removed = $false; Content = $TargetContent }
    }

    # Any non-zero marker count routes through Resolve-ManagedBlockSpan, which throws on
    # 2+ markers, an incomplete pair (BEGIN/END count mismatch), or an END-before-BEGIN
    # ordering violation. Only an exactly-one-ordered pair returns a span.
    $span = Resolve-ManagedBlockSpan -Segments $segments -Label 'destination'
    $b = $span.BeginIndex
    $e = $span.EndIndex

    # Excise BEGIN..END inclusive. Outside-block segments keep their original terminators
    # verbatim, so 'before + after' is a byte-for-byte-preserving splice of everything
    # outside the marker pair (the same splice contract Set-ManagedBlock uses for the
    # outside region).
    $before = ''
    if ($b -gt 0) {
        $before = -join $segments[0..($b - 1)]
    }
    $after = ''
    if ($e -lt ($segments.Count - 1)) {
        $after = -join $segments[($e + 1)..($segments.Count - 1)]
    }

    return [pscustomobject]@{ Removed = $true; Content = ($before + $after) }
}

function Add-ManagedBlock {
    # Pure function: FIRST-TIME insertion of a managed block into a destination that does NOT already
    # carry one. Mirrors Set-ManagedBlock / Remove-ManagedBlock — performs NO file IO and leaves NO
    # partial state. All marker validation happens before any content is produced, so a caller that
    # writes only the returned Content never produces a partial write. The IO-safety scaffolding
    # (BOM / U+FFFD gate / .amb-backup / rollback / post-write verify / absent-target create) belongs
    # to the apply wrapper (scripts/apply-managed-block.ps1 -Insert), NOT this primitive.
    #
    # Insertion is deliberately NOT "Set-ManagedBlock with a fresh snippet": Set-ManagedBlock REPLACES
    # an existing single marker pair and fail-fasts on 0 pairs. Add-ManagedBlock is the complementary
    # first-time path — it acts ONLY when the destination carries ZERO marker pairs, and REFUSES a
    # destination that already has one (that is steady-state replacement territory owned by
    # Set-ManagedBlock / apply-managed-block.ps1). Keeping the two paths disjoint is what preserves the
    # apply tool's replace-only semantics: this primitive never silently turns a present block into a
    # second one.
    #
    # Marker-count branch ordering (mirrors Remove-ManagedBlock's count-first discipline):
    #   - target ABSENT (TargetExists=$false)        -> CREATE: Content = the snippet block alone
    #                                                   (Created=$true). Caller writes a new file.
    #   - target present, 0 marker pairs             -> APPEND the snippet block AFTER the existing
    #                                                   content, preserving it byte-for-byte
    #                                                   (Created=$false).
    #   - target present, exactly 1 marker pair      -> FAIL-FAST (throw): not a first-time insert;
    #                                                   the caller must use the replace path.
    #   - 2+ pairs / incomplete (count mismatch) /
    #     structurally malformed (unbalanced fence)  -> FAIL-FAST (throw); no content produced, so a
    #                                                   caller that writes only the returned Content
    #                                                   never mutates on a fail-fast.
    #
    # Outside-block content is preserved byte-for-byte on the append path: the existing text is never
    # rewritten; at most a single trailing terminator is added when the file did not already end with
    # one (which does not alter any existing line), followed by one blank-line separator and the block.
    #
    # Returns: [pscustomobject] @{ Created = [bool]; Content = [string] }
    param(
        [string] $TargetContent,
        [string] $SnippetContent,
        [bool] $TargetExists = $true
    )

    # Validate + extract the snippet block (snippet must contain exactly one pair).
    $snippetBlockLines = Get-ManagedBlockContent -Content $SnippetContent -Label 'snippet'

    # Absent target: CREATE a new file carrying ONLY the snippet block. New files use LF with a single
    # trailing newline (the activation-file convention is UTF-8 no-BOM; .md content is LF). The
    # apply wrapper's post-write verify is terminator-agnostic, so this EOL choice never breaks verify.
    if (-not $TargetExists) {
        $content = ($snippetBlockLines -join "`n") + "`n"
        return [pscustomobject]@{ Created = $true; Content = $content }
    }

    # Present target: count markers first. Find-ManagedBlockMarkers also throws on an unbalanced
    # fenced code block (structurally malformed for marker detection).
    $segments = @(Split-ManagedBlockLines -Content $TargetContent)
    $scan = Find-ManagedBlockMarkers -Segments $segments
    $nb = $scan.BeginIndices.Count
    $ne = $scan.EndIndices.Count

    if ($nb -ne 0 -or $ne -ne 0) {
        if ($nb -eq 1 -and $ne -eq 1) {
            throw 'managed-block: destination already contains a managed block (1 marker pair); first-time insertion refuses to act. Use the replace path (scripts/apply-managed-block.ps1 / Set-ManagedBlock) for steady-state update.'
        }
        throw ("managed-block: destination has an ambiguous/incomplete marker state ({0} BEGIN, {1} END); first-time insertion refuses to act (expected exactly 0)." -f $nb, $ne)
    }

    # 0 marker pairs: append the block AFTER the existing content. Destination newline convention:
    # CRLF wins if any CRLF is present, else LF.
    if ($TargetContent -match '\r\n') { $eol = "`r`n" } else { $eol = "`n" }
    $block = ($snippetBlockLines -join $eol) + $eol

    if ([string]::IsNullOrEmpty($TargetContent)) {
        # Empty existing file -> just the block (no separator needed).
        return [pscustomobject]@{ Created = $false; Content = $block }
    }

    # Preserve the existing content verbatim; ensure it ends with a newline (added only if absent),
    # then one blank-line separator, then the block.
    $prefix = $TargetContent
    if ($prefix -notmatch '(\r\n|\n|\r)$') { $prefix += $eol }
    return [pscustomobject]@{ Created = $false; Content = ($prefix + $eol + $block) }
}
