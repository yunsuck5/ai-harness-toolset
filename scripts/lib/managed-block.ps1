Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Deterministic managed-block apply primitive for ai-harness-toolset activation
# surfaces (e.g. CLAUDE.md / AGENTS.md). It replaces the ad-hoc PowerShell splice
# that caused the 2026-05-21 UTF-8 corruption incident
# (docs/archive/backlog/operations.md "Activation managed-block apply tooling hardening").
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
# Marker counting follows GLOBAL_ADOPTION_DECISION.md §6 "Marker detection
# (counting rule)": fenced code blocks are skipped, and a line counts only on a
# whole-line trim match. Inline-code / prose mentions are never counted.

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

    for ($i = 0; $i -lt $Segments.Count; $i++) {
        $trimmed = (Get-ManagedBlockLineContent -Segment $Segments[$i]).Trim()

        # A fence delimiter is at least three backticks or three tildes. The
        # delimiter line and everything inside the fence are excluded from counting.
        if ($trimmed -match '^(`{3,}|~{3,})') {
            $inFence = -not $inFence
            continue
        }
        if ($inFence) {
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
    # non-increase check (docs/archive/backlog/operations.md "비-ASCII 무손실 gate"), which is
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
    # Marker-count branch ordering (mirrors the uninstall design state machine in the
    # install-update UNINSTALL_LIFECYCLE_DESIGN.md design doc, §4):
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
