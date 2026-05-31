Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Focused Pester suite for the pure managed-block library primitives, specifically
# Remove-ManagedBlock (IU-B-08 batch 1). These exercise the pure string-in / result-out
# contract only -- NO file IO, NO .amb-backup / rollback, NO uninstall flow (those are
# later batches). The library itself performs no file IO (scripts/lib/managed-block.ps1).

BeforeAll {
    $script:RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).ProviderPath
    . (Join-Path $script:RepoRoot 'scripts/lib/managed-block.ps1')

    $script:Begin = '<!-- BEGIN AI_HARNESS_TOOLSET_GLOBAL -->'
    $script:End   = '<!-- END AI_HARNESS_TOOLSET_GLOBAL -->'

    # Count residual marker lines in a piece of content (used to prove a removal left
    # ZERO marker pairs -- i.e. it deleted the marker lines, not just inner content).
    function script:Get-MarkerCounts {
        param([string] $Content)
        $segments = @(Split-ManagedBlockLines -Content $Content)
        $scan = Find-ManagedBlockMarkers -Segments $segments
        return [pscustomobject]@{ Begin = $scan.BeginIndices.Count; End = $scan.EndIndices.Count }
    }
}

Describe 'Remove-ManagedBlock' {

    Context '0 marker pair -> idempotent no-op success' {
        It 'returns Removed=$false and unchanged content when no markers are present' {
            $nl = "`n"
            $content = "line 1${nl}line 2${nl}line 3${nl}"
            $r = Remove-ManagedBlock -TargetContent $content
            $r.Removed | Should -BeFalse
            $r.Content | Should -Be $content
        }

        It 'treats empty input as a no-op success' {
            $r = Remove-ManagedBlock -TargetContent ''
            $r.Removed | Should -BeFalse
            $r.Content | Should -Be ''
        }

        It 'is idempotent: removing again after a successful removal is a no-op' {
            $nl = "`n"
            $content = "head${nl}$script:Begin${nl}body${nl}$script:End${nl}tail${nl}"
            $r1 = Remove-ManagedBlock -TargetContent $content
            $r1.Removed | Should -BeTrue
            $r2 = Remove-ManagedBlock -TargetContent $r1.Content
            $r2.Removed | Should -BeFalse
            $r2.Content | Should -Be $r1.Content
        }
    }

    Context 'exactly 1 marker pair -> excise span, preserve outside content' {
        It 'removes the BEGIN..END span (inclusive) and preserves outside content byte-for-byte (LF)' {
            $nl = "`n"
            $content = "before A${nl}before B${nl}$script:Begin${nl}block 1${nl}block 2${nl}$script:End${nl}after A${nl}after B${nl}"
            $r = Remove-ManagedBlock -TargetContent $content
            $r.Removed | Should -BeTrue
            $r.Content | Should -Be "before A${nl}before B${nl}after A${nl}after B${nl}"
        }

        It 'preserves CRLF outside terminators verbatim' {
            $crlf = "`r`n"
            $content = "x${crlf}$script:Begin${crlf}blk${crlf}$script:End${crlf}y${crlf}"
            $r = Remove-ManagedBlock -TargetContent $content
            $r.Removed | Should -BeTrue
            $r.Content | Should -Be "x${crlf}y${crlf}"
        }

        It 'deletes the marker lines themselves (zero marker pairs remain) -- not an empty-snippet stub' {
            $nl = "`n"
            $content = "head${nl}$script:Begin${nl}body${nl}$script:End${nl}tail${nl}"
            $r = Remove-ManagedBlock -TargetContent $content
            $r.Content | Should -Not -Match 'AI_HARNESS_TOOLSET_GLOBAL'
            $counts = script:Get-MarkerCounts -Content $r.Content
            $counts.Begin | Should -Be 0
            $counts.End   | Should -Be 0
        }

        It 'preserves a fenced code-block mention of the markers (not counted, not removed)' {
            $nl = "`n"
            $fence = '```'
            $content = "$script:Begin${nl}real body${nl}$script:End${nl}${fence}${nl}$script:Begin${nl}${fence}${nl}"
            $r = Remove-ManagedBlock -TargetContent $content
            $r.Removed | Should -BeTrue
            # The real pair is gone; the fenced (uncounted) BEGIN mention is preserved verbatim.
            $r.Content | Should -Be "${fence}${nl}$script:Begin${nl}${fence}${nl}"
        }
    }

    Context 'removal that empties the file -> no file-deletion intent (empty content, never $null)' {
        It 'returns Removed=$true with empty-string Content when the block is the whole file' {
            $nl = "`n"
            $content = "$script:Begin${nl}only block${nl}$script:End${nl}"
            $r = Remove-ManagedBlock -TargetContent $content
            $r.Removed | Should -BeTrue
            $r.Content | Should -Be ''
            # The primitive returns content (empty string); it has no file-deletion concept.
            $null -eq $r.Content | Should -BeFalse
        }
    }

    Context 'fail-fast cases (throw; no content produced)' {
        It '2+ marker pairs -> fail-fast' {
            $nl = "`n"
            $content = "$script:Begin${nl}a${nl}$script:End${nl}$script:Begin${nl}b${nl}$script:End${nl}"
            { Remove-ManagedBlock -TargetContent $content } | Should -Throw
        }

        It 'incomplete pair (BEGIN only) -> fail-fast' {
            $nl = "`n"
            $content = "head${nl}$script:Begin${nl}body${nl}"
            { Remove-ManagedBlock -TargetContent $content } | Should -Throw
        }

        It 'incomplete pair (END only) -> fail-fast' {
            $nl = "`n"
            $content = "body${nl}$script:End${nl}tail${nl}"
            { Remove-ManagedBlock -TargetContent $content } | Should -Throw
        }

        It 'ordering violation (END before BEGIN) -> fail-fast' {
            $nl = "`n"
            $content = "$script:End${nl}mid${nl}$script:Begin${nl}"
            { Remove-ManagedBlock -TargetContent $content } | Should -Throw
        }

        It 'structurally malformed (unbalanced fenced code block) -> fail-fast' {
            $nl = "`n"
            $fence = '```'
            $content = "before${nl}${fence}${nl}$script:Begin${nl}body${nl}$script:End${nl}"
            { Remove-ManagedBlock -TargetContent $content } | Should -Throw
        }
    }

    Context 'newline / LF handling does not conflict with managed-block convention' {
        It 'does not introduce or rewrite outside terminators (round-trip of the outside region)' {
            # Mixed: LF outside, the removal must not normalize the surviving outside bytes.
            $nl = "`n"
            $content = "a${nl}${nl}$script:Begin${nl}blk${nl}$script:End${nl}${nl}b${nl}"
            $r = Remove-ManagedBlock -TargetContent $content
            $r.Removed | Should -BeTrue
            # The blank lines that sat OUTSIDE the marker pair are preserved exactly.
            $r.Content | Should -Be "a${nl}${nl}${nl}b${nl}"
        }

        It 'preserves a no-trailing-newline EOF outside the block' {
            $nl = "`n"
            $content = "head${nl}$script:Begin${nl}body${nl}$script:End${nl}tail-no-eol"
            $r = Remove-ManagedBlock -TargetContent $content
            $r.Removed | Should -BeTrue
            $r.Content | Should -Be "head${nl}tail-no-eol"
        }
    }
}

Describe 'Add-ManagedBlock (first-time insertion primitive, IU-B-09)' {

    BeforeAll {
        $nl = "`n"
        # A minimal snippet carrying exactly one marker pair, plus an inline-code prose mention on a
        # mixed line (NOT a whole-line marker, so it is not counted) to mirror the real snippets.
        $script:Snippet = "$script:Begin${nl}# payload heading${nl}body line with a ``$script:Begin`` inline mention${nl}more body${nl}$script:End${nl}"
        $script:SnippetBlockLines = @(Get-ManagedBlockContent -Content $script:Snippet -Label 'snippet')
    }

    Context 'absent target -> CREATE' {
        It 'returns Created=$true and content carrying exactly one marker pair equal to the snippet block' {
            $r = Add-ManagedBlock -TargetContent '' -SnippetContent $script:Snippet -TargetExists $false
            $r.Created | Should -BeTrue
            $counts = script:Get-MarkerCounts -Content $r.Content
            $counts.Begin | Should -Be 1
            $counts.End   | Should -Be 1
            @(Get-ManagedBlockContent -Content $r.Content -Label 'created') | Should -Be $script:SnippetBlockLines
        }
    }

    Context 'present target with 0 marker pairs -> APPEND preserving existing content' {
        It 'preserves the existing content verbatim and appends the block (one marker pair total)' {
            $existing = "# My CLAUDE.md${nl}${nl}user content${nl}"
            $r = Add-ManagedBlock -TargetContent $existing -SnippetContent $script:Snippet -TargetExists $true
            $r.Created | Should -BeFalse
            # Existing bytes appear verbatim at the start.
            $r.Content.StartsWith($existing) | Should -BeTrue
            $counts = script:Get-MarkerCounts -Content $r.Content
            $counts.Begin | Should -Be 1
            $counts.End   | Should -Be 1
            @(Get-ManagedBlockContent -Content $r.Content -Label 'appended') | Should -Be $script:SnippetBlockLines
        }

        It 'adds a trailing newline before appending when the existing content has none' {
            $existing = "no trailing newline"
            $r = Add-ManagedBlock -TargetContent $existing -SnippetContent $script:Snippet -TargetExists $true
            $r.Created | Should -BeFalse
            $r.Content.StartsWith("no trailing newline${nl}") | Should -BeTrue
            ($r.Content -split "`r?`n")[0] | Should -Be 'no trailing newline'
        }

        It 'uses CRLF for the appended block when the existing content is CRLF' {
            $crlf = "`r`n"
            $existing = "head${crlf}body${crlf}"
            $r = Add-ManagedBlock -TargetContent $existing -SnippetContent $script:Snippet -TargetExists $true
            # The appended block region must carry CRLF terminators (destination convention wins).
            $r.Content | Should -Match "$([regex]::Escape($script:Begin))`r`n"
        }

        It 'treats an empty existing file as just the block (no leading separator)' {
            $r = Add-ManagedBlock -TargetContent '' -SnippetContent $script:Snippet -TargetExists $true
            $r.Created | Should -BeFalse
            @(Get-ManagedBlockContent -Content $r.Content -Label 'block') | Should -Be $script:SnippetBlockLines
        }
    }

    Context 'present target that already has a managed block -> FAIL-FAST (replace territory)' {
        It 'refuses a target with exactly 1 marker pair' {
            $existing = "head${nl}$script:Begin${nl}old body${nl}$script:End${nl}tail${nl}"
            { Add-ManagedBlock -TargetContent $existing -SnippetContent $script:Snippet -TargetExists $true } |
                Should -Throw -ExpectedMessage '*already contains a managed block*'
        }
    }

    Context 'malformed / ambiguous marker state -> FAIL-FAST (no content)' {
        It '2+ marker pairs -> fail-fast' {
            $existing = "$script:Begin${nl}a${nl}$script:End${nl}$script:Begin${nl}b${nl}$script:End${nl}"
            { Add-ManagedBlock -TargetContent $existing -SnippetContent $script:Snippet -TargetExists $true } | Should -Throw
        }

        It 'incomplete pair (BEGIN only) -> fail-fast' {
            $existing = "head${nl}$script:Begin${nl}body${nl}"
            { Add-ManagedBlock -TargetContent $existing -SnippetContent $script:Snippet -TargetExists $true } | Should -Throw
        }

        It 'structurally malformed (unbalanced fence) -> fail-fast' {
            $fence = '```'
            $existing = "before${nl}${fence}${nl}$script:Begin${nl}body${nl}"
            { Add-ManagedBlock -TargetContent $existing -SnippetContent $script:Snippet -TargetExists $true } | Should -Throw
        }

        It 'a snippet without a valid single marker pair -> fail-fast' {
            { Add-ManagedBlock -TargetContent '' -SnippetContent 'no markers here' -TargetExists $false } | Should -Throw
        }
    }
}
