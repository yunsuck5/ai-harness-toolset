Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

BeforeAll {
    $script:RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).ProviderPath
    . (Join-Path $script:RepoRoot 'scripts/lib/native-process.ps1')
    $script:ApplyScript = Join-Path $script:RepoRoot 'scripts/apply-managed-block.ps1'
    $script:RealClaudeSnippet = Join-Path $script:RepoRoot 'snippets/CLAUDE_SNIPPET.md'

    $script:Begin = '<!-- BEGIN AI_HARNESS_TOOLSET_GLOBAL -->'
    $script:End   = '<!-- END AI_HARNESS_TOOLSET_GLOBAL -->'

    function script:Write-Utf8NoBomFile {
        param([string] $Path, [string] $Content)
        $parent = Split-Path -LiteralPath $Path
        if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
            $null = New-Item -ItemType Directory -Path $parent -Force
        }
        $resolved = [System.IO.Path]::GetFullPath($Path)
        $encoding = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($resolved, $Content, $encoding)
    }

    function script:Write-Utf8BomFile {
        param([string] $Path, [string] $Content)
        $parent = Split-Path -LiteralPath $Path
        if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
            $null = New-Item -ItemType Directory -Path $parent -Force
        }
        $resolved = [System.IO.Path]::GetFullPath($Path)
        $encoding = New-Object System.Text.UTF8Encoding($true)
        [System.IO.File]::WriteAllText($resolved, $Content, $encoding)
    }

    function script:Read-Utf8NoBomFile {
        param([string] $Path)
        $resolved = (Resolve-Path -LiteralPath $Path).ProviderPath
        $encoding = New-Object System.Text.UTF8Encoding($false)
        return [System.IO.File]::ReadAllText($resolved, $encoding)
    }

    function script:Read-Bytes {
        param([string] $Path)
        return [System.IO.File]::ReadAllBytes((Resolve-Path -LiteralPath $Path).ProviderPath)
    }

    function script:New-CaseDir {
        param([string] $CaseName)
        $dir = Join-Path $TestDrive ('pester-apply-mb-' + $CaseName)
        if (Test-Path -LiteralPath $dir) {
            Remove-Item -LiteralPath $dir -Recurse -Force
        }
        $null = New-Item -ItemType Directory -Path $dir -Force
        return ([System.IO.Path]::GetFullPath($dir))
    }

    function script:Invoke-Apply {
        param([string] $SnippetPath, [string] $TargetPath, [switch] $DryRun, [switch] $ShowFullDiff)
        $procArgs = @(
            '-NoProfile',
            '-ExecutionPolicy', 'Bypass',
            '-File', $script:ApplyScript,
            '-SnippetPath', $SnippetPath,
            '-TargetPath', $TargetPath
        )
        if ($DryRun) { $procArgs += '-DryRun' }
        if ($ShowFullDiff) { $procArgs += '-ShowFullDiff' }
        $proc = Invoke-NativeProcess -Executable 'powershell.exe' -Arguments $procArgs
        $exitCode = $proc.ExitCode
        $text = (($proc.Stdout + $proc.Stderr) -replace "`r`n", "`n").TrimEnd("`n")
        return [pscustomobject]@{ ExitCode = $exitCode; Output = $text }
    }

    # A managed-block snippet/target pair that differs by exactly ONE middle line, with a
    # large ASCII common prefix and suffix — exercises the compact dry-run summary's
    # prefix/suffix trim (a one-line drift should report as -1/+1, not a full block dump).
    function script:New-OneLineDriftPair {
        $lines = @('alpha','bravo','charlie','delta','echo','foxtrot')
        $proposed = $lines.Clone()
        $proposed[3] = 'delta-CHANGED'   # change exactly the 4th block line
        $snippetBlock = ($script:Begin + "`n" + ($proposed -join "`n") + "`n" + $script:End + "`n")
        $targetBlock  = ("head`n" + $script:Begin + "`n" + ($lines -join "`n") + "`n" + $script:End + "`ntail`n")
        return [pscustomobject]@{ Snippet = $snippetBlock; Target = $targetBlock }
    }

    # A minimal, well-formed snippet block (BEGIN .. END inclusive). Includes an
    # em-dash to confirm non-ASCII survives the UTF-8 read/write round-trip.
    function script:New-SnippetContent {
        return ($script:Begin + "`n# managed payload — v2`nbody line`n" + $script:End + "`n")
    }
}

Describe 'apply-managed-block happy path' {
    It 'AC-AMB-HAPPY-1: replaces the block, preserves outside content byte-exact, exits 0' {
        $dir = script:New-CaseDir -CaseName 'happy-1'
        $snippet = Join-Path $dir 'snippet.md'
        $target  = Join-Path $dir 'CLAUDE.md'

        script:Write-Utf8NoBomFile -Path $snippet -Content (script:New-SnippetContent)

        # Outside-block content carries Korean + em-dash — exactly the data the
        # 2026-05-21 incident corrupted. It must survive byte-identical.
        $before = "# 사용자 개인 메모리 — 보존되어야 함`n자유 텍스트`n`n"
        $after  = "`n## 블록 뒤 사용자 내용 — 보존`n끝줄`n"
        $oldBlock = $script:Begin + "`n# managed payload — v1`nOLD body`n" + $script:End
        script:Write-Utf8NoBomFile -Path $target -Content ($before + $oldBlock + $after)

        $beforeBytes = [System.Text.Encoding]::UTF8.GetBytes($before)
        $afterBytes  = [System.Text.Encoding]::UTF8.GetBytes($after)

        $result = script:Invoke-Apply -SnippetPath $snippet -TargetPath $target
        $result.ExitCode | Should -Be 0 -Because $result.Output
        $result.Output | Should -Match 'apply-managed-block: PASS'

        $finalBytes = script:Read-Bytes -Path $target

        # before-region bytes preserved exactly at the head.
        $head = $finalBytes[0..($beforeBytes.Length - 1)]
        [System.Linq.Enumerable]::SequenceEqual([byte[]]$head, [byte[]]$beforeBytes) | Should -BeTrue

        # after-region bytes preserved exactly at the tail.
        $tail = $finalBytes[($finalBytes.Length - $afterBytes.Length)..($finalBytes.Length - 1)]
        [System.Linq.Enumerable]::SequenceEqual([byte[]]$tail, [byte[]]$afterBytes) | Should -BeTrue

        # New block content present; old block body gone.
        $finalText = script:Read-Utf8NoBomFile -Path $target
        $finalText | Should -Match 'managed payload — v2'
        $finalText | Should -Not -Match 'OLD body'

        # No corruption sentinels (literal '?' replacement / U+FFFD).
        $finalText.Contains([char]0xFFFD) | Should -BeFalse
    }

    It 'AC-AMB-HAPPY-2: real CLAUDE_SNIPPET.md applies cleanly (inline-code marker mentions ignored)' {
        $dir = script:New-CaseDir -CaseName 'happy-real'
        $target = Join-Path $dir 'CLAUDE.md'

        $before = "# project instructions`nkeep me`n`n"
        $oldBlock = $script:Begin + "`nstale managed body`n" + $script:End
        $after = "`n# trailer kept`n"
        script:Write-Utf8NoBomFile -Path $target -Content ($before + $oldBlock + $after)

        $result = script:Invoke-Apply -SnippetPath $script:RealClaudeSnippet -TargetPath $target
        $result.ExitCode | Should -Be 0 -Because $result.Output

        $finalText = script:Read-Utf8NoBomFile -Path $target
        $finalText | Should -Match 'ai-harness-toolset instructions for CLAUDE.md-compatible agents'
        $finalText | Should -Match 'keep me'
        $finalText | Should -Match 'trailer kept'
        $finalText | Should -Not -Match 'stale managed body'
    }
}

Describe 'apply-managed-block block-equals-snippet verification' {
    It 'AC-AMB-VERIFY-1: post-apply destination block equals snippet block' {
        $dir = script:New-CaseDir -CaseName 'verify-1'
        $snippet = Join-Path $dir 'snippet.md'
        $target  = Join-Path $dir 'AGENTS.md'
        script:Write-Utf8NoBomFile -Path $snippet -Content (script:New-SnippetContent)
        script:Write-Utf8NoBomFile -Path $target -Content ("head`n" + $script:Begin + "`nx`n" + $script:End + "`ntail`n")

        $result = script:Invoke-Apply -SnippetPath $snippet -TargetPath $target
        $result.ExitCode | Should -Be 0 -Because $result.Output

        # Compare extracted blocks (BEGIN..END inclusive, terminator-stripped).
        $snippetLines = (script:Read-Utf8NoBomFile -Path $snippet) -split '\r\n|\n|\r'
        $targetText = script:Read-Utf8NoBomFile -Path $target
        $targetLines = $targetText -split '\r\n|\n|\r'

        $sBegin = [array]::IndexOf($snippetLines, $script:Begin)
        $sEnd   = [array]::IndexOf($snippetLines, $script:End)
        $tBegin = [array]::IndexOf($targetLines, $script:Begin)
        $tEnd   = [array]::IndexOf($targetLines, $script:End)

        $snippetBlock = $snippetLines[$sBegin..$sEnd] -join "`n"
        $targetBlock  = $targetLines[$tBegin..$tEnd] -join "`n"
        $targetBlock | Should -Be $snippetBlock
    }
}

Describe 'apply-managed-block newline preservation' {
    It 'AC-AMB-EOL-1: CRLF destination keeps CRLF in the rewritten block' {
        $dir = script:New-CaseDir -CaseName 'eol-crlf'
        $snippet = Join-Path $dir 'snippet.md'
        $target  = Join-Path $dir 'CLAUDE.md'
        script:Write-Utf8NoBomFile -Path $snippet -Content (script:New-SnippetContent)
        # CRLF throughout the destination.
        $crlf = ("head" + "`r`n" + $script:Begin + "`r`n" + "x" + "`r`n" + $script:End + "`r`n" + "tail" + "`r`n")
        script:Write-Utf8NoBomFile -Path $target -Content $crlf

        $result = script:Invoke-Apply -SnippetPath $snippet -TargetPath $target
        $result.ExitCode | Should -Be 0 -Because $result.Output

        $finalText = script:Read-Utf8NoBomFile -Path $target
        # The block body line should be terminated by CRLF, not bare LF.
        $finalText | Should -Match "body line`r`n"
        $finalText | Should -Match "head`r`n"
        $finalText | Should -Match "tail`r`n"
    }

    It 'AC-AMB-EOL-2: LF destination keeps LF (no CR introduced)' {
        $dir = script:New-CaseDir -CaseName 'eol-lf'
        $snippet = Join-Path $dir 'snippet.md'
        $target  = Join-Path $dir 'CLAUDE.md'
        script:Write-Utf8NoBomFile -Path $snippet -Content (script:New-SnippetContent)
        script:Write-Utf8NoBomFile -Path $target -Content ("head`n" + $script:Begin + "`nx`n" + $script:End + "`ntail`n")

        $result = script:Invoke-Apply -SnippetPath $snippet -TargetPath $target
        $result.ExitCode | Should -Be 0 -Because $result.Output

        $finalText = script:Read-Utf8NoBomFile -Path $target
        $finalText.Contains("`r") | Should -BeFalse
    }

    It 'AC-AMB-EOL-3: destination without a trailing newline stays without one' {
        $dir = script:New-CaseDir -CaseName 'eol-noeof'
        $snippet = Join-Path $dir 'snippet.md'
        $target  = Join-Path $dir 'CLAUDE.md'
        script:Write-Utf8NoBomFile -Path $snippet -Content (script:New-SnippetContent)
        # END marker is the last line, no trailing newline.
        script:Write-Utf8NoBomFile -Path $target -Content ("head`n" + $script:Begin + "`nx`n" + $script:End)

        $result = script:Invoke-Apply -SnippetPath $snippet -TargetPath $target
        $result.ExitCode | Should -Be 0 -Because $result.Output

        $finalText = script:Read-Utf8NoBomFile -Path $target
        $finalText.EndsWith($script:End) | Should -BeTrue
    }
}

Describe 'apply-managed-block marker ambiguity fail-fast (target unchanged, no partial write)' {
    It 'AC-AMB-FAIL-0PAIR: target with no marker pair fails fast and is left unchanged' {
        $dir = script:New-CaseDir -CaseName 'fail-0'
        $snippet = Join-Path $dir 'snippet.md'
        $target  = Join-Path $dir 'CLAUDE.md'
        script:Write-Utf8NoBomFile -Path $snippet -Content (script:New-SnippetContent)
        $original = "# no markers here`njust user content`n"
        script:Write-Utf8NoBomFile -Path $target -Content $original

        $result = script:Invoke-Apply -SnippetPath $snippet -TargetPath $target
        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match 'no AI_HARNESS_TOOLSET_GLOBAL marker pair'
        (script:Read-Utf8NoBomFile -Path $target) | Should -Be $original
    }

    It 'AC-AMB-FAIL-2PAIR: target with two marker pairs fails fast and is left unchanged' {
        $dir = script:New-CaseDir -CaseName 'fail-2'
        $snippet = Join-Path $dir 'snippet.md'
        $target  = Join-Path $dir 'CLAUDE.md'
        script:Write-Utf8NoBomFile -Path $snippet -Content (script:New-SnippetContent)
        $original = ($script:Begin + "`na`n" + $script:End + "`nmid`n" + $script:Begin + "`nb`n" + $script:End + "`n")
        script:Write-Utf8NoBomFile -Path $target -Content $original

        $result = script:Invoke-Apply -SnippetPath $snippet -TargetPath $target
        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match 'ambiguous markers'
        (script:Read-Utf8NoBomFile -Path $target) | Should -Be $original
    }

    It 'AC-AMB-FAIL-MISMATCH: BEGIN without END fails fast and is left unchanged' {
        $dir = script:New-CaseDir -CaseName 'fail-mismatch'
        $snippet = Join-Path $dir 'snippet.md'
        $target  = Join-Path $dir 'CLAUDE.md'
        script:Write-Utf8NoBomFile -Path $snippet -Content (script:New-SnippetContent)
        $original = ($script:Begin + "`nbody without end`n")
        script:Write-Utf8NoBomFile -Path $target -Content $original

        $result = script:Invoke-Apply -SnippetPath $snippet -TargetPath $target
        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match 'ambiguous markers'
        (script:Read-Utf8NoBomFile -Path $target) | Should -Be $original
    }

    It 'AC-AMB-FAIL-ORDER: END before BEGIN fails fast and is left unchanged' {
        $dir = script:New-CaseDir -CaseName 'fail-order'
        $snippet = Join-Path $dir 'snippet.md'
        $target  = Join-Path $dir 'CLAUDE.md'
        script:Write-Utf8NoBomFile -Path $snippet -Content (script:New-SnippetContent)
        $original = ($script:End + "`nbody`n" + $script:Begin + "`n")
        script:Write-Utf8NoBomFile -Path $target -Content $original

        $result = script:Invoke-Apply -SnippetPath $snippet -TargetPath $target
        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match 'does not follow BEGIN'
        (script:Read-Utf8NoBomFile -Path $target) | Should -Be $original
    }
}

Describe 'apply-managed-block detection rule (whole-line trim match)' {
    It 'AC-AMB-INLINE-1: inline-code / prose marker mentions are not counted' {
        $dir = script:New-CaseDir -CaseName 'inline-1'
        $snippet = Join-Path $dir 'snippet.md'
        $target  = Join-Path $dir 'CLAUDE.md'
        script:Write-Utf8NoBomFile -Path $snippet -Content (script:New-SnippetContent)
        # Prose line literally quotes both markers inline; the only real pair is the
        # whole-line one. Apply must succeed (count == 1), not abort as ambiguous.
        $prose = "see ``$($script:Begin)`` and ``$($script:End)`` for the markers`n"
        $original = ($prose + $script:Begin + "`nreal body`n" + $script:End + "`n")
        script:Write-Utf8NoBomFile -Path $target -Content $original

        $result = script:Invoke-Apply -SnippetPath $snippet -TargetPath $target
        $result.ExitCode | Should -Be 0 -Because $result.Output
        $finalText = script:Read-Utf8NoBomFile -Path $target
        $finalText | Should -Match 'see `'   # prose line preserved
        $finalText | Should -Match 'managed payload — v2'
        $finalText | Should -Not -Match 'real body'
    }

    It 'AC-AMB-FENCE-1: marker text inside a fenced code block is not counted' {
        $dir = script:New-CaseDir -CaseName 'fence-1'
        $snippet = Join-Path $dir 'snippet.md'
        $target  = Join-Path $dir 'CLAUDE.md'
        script:Write-Utf8NoBomFile -Path $snippet -Content (script:New-SnippetContent)
        # A fenced example block containing whole-line markers must be ignored;
        # only the real pair outside the fence is the managed block.
        $fence = "``````" + "`n" + $script:Begin + "`n" + $script:End + "`n" + "``````" + "`n"
        $original = ($fence + $script:Begin + "`nreal body`n" + $script:End + "`n")
        script:Write-Utf8NoBomFile -Path $target -Content $original

        $result = script:Invoke-Apply -SnippetPath $snippet -TargetPath $target
        $result.ExitCode | Should -Be 0 -Because $result.Output
        $finalText = script:Read-Utf8NoBomFile -Path $target
        $finalText | Should -Not -Match 'real body'
        # The fenced example markers remain in the file.
        $finalText | Should -Match '```'
    }

    It 'AC-AMB-FENCE-2: an unbalanced fence fails fast and leaves the target unchanged' {
        $dir = script:New-CaseDir -CaseName 'fence-2'
        $snippet = Join-Path $dir 'snippet.md'
        $target  = Join-Path $dir 'CLAUDE.md'
        script:Write-Utf8NoBomFile -Path $snippet -Content (script:New-SnippetContent)
        # One opening fence, never closed.
        $original = ($script:Begin + "`nbody`n" + $script:End + "`n" + "``````" + "`ndangling fence`n")
        script:Write-Utf8NoBomFile -Path $target -Content $original

        $result = script:Invoke-Apply -SnippetPath $snippet -TargetPath $target
        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match 'unbalanced fenced code block'
        (script:Read-Utf8NoBomFile -Path $target) | Should -Be $original
    }
}

Describe 'apply-managed-block snippet / input guards' {
    It 'AC-AMB-SNIPPET-BAD: a snippet without a marker pair fails fast, target unchanged' {
        $dir = script:New-CaseDir -CaseName 'snippet-bad'
        $snippet = Join-Path $dir 'snippet.md'
        $target  = Join-Path $dir 'CLAUDE.md'
        script:Write-Utf8NoBomFile -Path $snippet -Content "# snippet with no markers`n"
        $original = ("head`n" + $script:Begin + "`nold`n" + $script:End + "`ntail`n")
        script:Write-Utf8NoBomFile -Path $target -Content $original

        $result = script:Invoke-Apply -SnippetPath $snippet -TargetPath $target
        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match 'snippet'
        (script:Read-Utf8NoBomFile -Path $target) | Should -Be $original
    }

    It 'AC-AMB-BOM: a BOM-prefixed target is refused and left unchanged' {
        $dir = script:New-CaseDir -CaseName 'bom'
        $snippet = Join-Path $dir 'snippet.md'
        $target  = Join-Path $dir 'CLAUDE.md'
        script:Write-Utf8NoBomFile -Path $snippet -Content (script:New-SnippetContent)
        $original = ("head`n" + $script:Begin + "`nold`n" + $script:End + "`ntail`n")
        script:Write-Utf8BomFile -Path $target -Content $original

        $beforeBytes = script:Read-Bytes -Path $target

        $result = script:Invoke-Apply -SnippetPath $snippet -TargetPath $target
        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match 'UTF-8 BOM'

        $afterBytes = script:Read-Bytes -Path $target
        [System.Linq.Enumerable]::SequenceEqual([byte[]]$beforeBytes, [byte[]]$afterBytes) | Should -BeTrue
    }

    It 'AC-AMB-INVALID-UTF8: an invalid-UTF-8 target fails fast and is left byte-unchanged' {
        $dir = script:New-CaseDir -CaseName 'invalid-utf8'
        $snippet = Join-Path $dir 'snippet.md'
        $target  = Join-Path $dir 'CLAUDE.md'
        script:Write-Utf8NoBomFile -Path $snippet -Content (script:New-SnippetContent)

        # A well-formed marker pair, but with raw invalid UTF-8 bytes (0xFF 0xFE)
        # spliced into the outside-block content. Strict Read-Utf8 must reject this
        # before the managed-block splice / verify runs, so the corrupted bytes are
        # never read, rewritten, or "verified" — and the file is left untouched.
        $head = [System.Text.Encoding]::UTF8.GetBytes("head`n")
        $bad  = [byte[]]@(0xFF, 0xFE)
        $blk  = [System.Text.Encoding]::UTF8.GetBytes("`n" + $script:Begin + "`nold`n" + $script:End + "`ntail`n")
        $bytes = New-Object byte[] ($head.Length + $bad.Length + $blk.Length)
        [System.Array]::Copy($head, 0, $bytes, 0, $head.Length)
        [System.Array]::Copy($bad, 0, $bytes, $head.Length, $bad.Length)
        [System.Array]::Copy($blk, 0, $bytes, $head.Length + $bad.Length, $blk.Length)
        [System.IO.File]::WriteAllBytes((Join-Path $dir 'CLAUDE.md'), $bytes)

        $beforeBytes = script:Read-Bytes -Path $target

        $result = script:Invoke-Apply -SnippetPath $snippet -TargetPath $target
        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match 'invalid UTF-8 byte sequence'

        $afterBytes = script:Read-Bytes -Path $target
        [System.Linq.Enumerable]::SequenceEqual([byte[]]$beforeBytes, [byte[]]$afterBytes) | Should -BeTrue
    }

    It 'AC-AMB-FFFD-TARGET: a target carrying U+FFFD fails fast and is left byte-unchanged' {
        $dir = script:New-CaseDir -CaseName 'fffd-target'
        $snippet = Join-Path $dir 'snippet.md'
        $target  = Join-Path $dir 'CLAUDE.md'
        script:Write-Utf8NoBomFile -Path $snippet -Content (script:New-SnippetContent)

        # U+FFFD encodes to the valid UTF-8 bytes EF BF BD, so the A-2a strict reader
        # accepts it — the A-2b sentinel gate is what must reject it. Place it OUTSIDE
        # the managed block (the marker pair is well-formed) to prove the gate fires
        # on already-persisted corruption, not on a marker / structural problem.
        $fffd = [string][char]0xFFFD
        $original = ("head with corruption " + $fffd + "`n" + $script:Begin + "`nold`n" + $script:End + "`ntail`n")
        script:Write-Utf8NoBomFile -Path $target -Content $original

        $beforeBytes = script:Read-Bytes -Path $target

        $result = script:Invoke-Apply -SnippetPath $snippet -TargetPath $target
        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match 'U\+FFFD replacement character'
        $result.Output | Should -Match 'target'

        $afterBytes = script:Read-Bytes -Path $target
        [System.Linq.Enumerable]::SequenceEqual([byte[]]$beforeBytes, [byte[]]$afterBytes) | Should -BeTrue
    }

    It 'AC-AMB-FFFD-SNIPPET: a snippet carrying U+FFFD fails fast and leaves the target unchanged' {
        $dir = script:New-CaseDir -CaseName 'fffd-snippet'
        $snippet = Join-Path $dir 'snippet.md'
        $target  = Join-Path $dir 'CLAUDE.md'

        $fffd = [string][char]0xFFFD
        script:Write-Utf8NoBomFile -Path $snippet -Content ($script:Begin + "`n# managed payload " + $fffd + "`nbody`n" + $script:End + "`n")
        $original = ("head`n" + $script:Begin + "`nold`n" + $script:End + "`ntail`n")
        script:Write-Utf8NoBomFile -Path $target -Content $original

        $beforeBytes = script:Read-Bytes -Path $target

        $result = script:Invoke-Apply -SnippetPath $snippet -TargetPath $target
        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match 'U\+FFFD replacement character'
        $result.Output | Should -Match 'snippet'

        # Byte-array equality (matching AC-AMB-FFFD-TARGET) proves the target was not
        # touched at all when the corruption is carried by the snippet.
        $afterBytes = script:Read-Bytes -Path $target
        [System.Linq.Enumerable]::SequenceEqual([byte[]]$beforeBytes, [byte[]]$afterBytes) | Should -BeTrue
    }

    It 'AC-AMB-LITERAL-Q-OK: a target with a legitimate literal "?" still applies (? is not gated)' {
        $dir = script:New-CaseDir -CaseName 'literal-q'
        $snippet = Join-Path $dir 'snippet.md'
        $target  = Join-Path $dir 'CLAUDE.md'
        script:Write-Utf8NoBomFile -Path $snippet -Content (script:New-SnippetContent)

        # Literal ASCII '?' is ordinary content (e.g. the repo's own CLAUDE_SNIPPET.md
        # contains '진행할까요?'). The A-2b gate must NOT reject it as a corruption
        # sentinel; the apply must succeed.
        $before = "# 사용자 메모리`n정말 이어서 진행할까요? 네 또는 아니오`n`n"
        $original = ($before + $script:Begin + "`nold`n" + $script:End + "`ntail?`n")
        script:Write-Utf8NoBomFile -Path $target -Content $original

        $result = script:Invoke-Apply -SnippetPath $snippet -TargetPath $target
        $result.ExitCode | Should -Be 0 -Because $result.Output
        $finalText = script:Read-Utf8NoBomFile -Path $target
        $finalText | Should -Match '진행할까요\?'        # legitimate '?' preserved
        $finalText | Should -Match 'managed payload — v2'
        $finalText | Should -Not -Match 'old'
        $finalText.Contains([char]0xFFFD) | Should -BeFalse
    }

    It 'AC-AMB-MISSING-TARGET: a missing target path fails fast' {
        $dir = script:New-CaseDir -CaseName 'missing-target'
        $snippet = Join-Path $dir 'snippet.md'
        script:Write-Utf8NoBomFile -Path $snippet -Content (script:New-SnippetContent)
        $target = Join-Path $dir 'does-not-exist.md'

        $result = script:Invoke-Apply -SnippetPath $snippet -TargetPath $target
        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match 'target not found'
    }

    It 'AC-AMB-MISSING-SNIPPET: a missing snippet path fails fast, target unchanged' {
        $dir = script:New-CaseDir -CaseName 'missing-snippet'
        $target = Join-Path $dir 'CLAUDE.md'
        $original = ("head`n" + $script:Begin + "`nold`n" + $script:End + "`ntail`n")
        script:Write-Utf8NoBomFile -Path $target -Content $original
        $snippet = Join-Path $dir 'no-snippet.md'

        $result = script:Invoke-Apply -SnippetPath $snippet -TargetPath $target
        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match 'snippet not found'
        (script:Read-Utf8NoBomFile -Path $target) | Should -Be $original
    }
}

Describe 'apply-managed-block A-2c backup / rollback' {
    It 'AC-AMB-BACKUP-CLEAN: a successful apply leaves no .amb-backup sidecar' {
        $dir = script:New-CaseDir -CaseName 'backup-clean'
        $snippet = Join-Path $dir 'snippet.md'
        $target  = Join-Path $dir 'CLAUDE.md'
        script:Write-Utf8NoBomFile -Path $snippet -Content (script:New-SnippetContent)
        script:Write-Utf8NoBomFile -Path $target -Content ("head`n" + $script:Begin + "`nold`n" + $script:End + "`ntail`n")

        $result = script:Invoke-Apply -SnippetPath $snippet -TargetPath $target
        $result.ExitCode | Should -Be 0 -Because $result.Output
        $result.Output | Should -Match 'apply-managed-block: PASS'

        # The happy path must not leave a stale backup artifact next to the target.
        (Test-Path -LiteralPath ($target + '.amb-backup')) | Should -BeFalse
    }

    It 'AC-AMB-BACKUP-NONE-ON-PREWRITE-FAIL: a pre-write failure (U+FFFD) creates no backup and leaves the target byte-unchanged' {
        $dir = script:New-CaseDir -CaseName 'backup-none-prewrite'
        $snippet = Join-Path $dir 'snippet.md'
        $target  = Join-Path $dir 'CLAUDE.md'
        script:Write-Utf8NoBomFile -Path $snippet -Content (script:New-SnippetContent)

        # U+FFFD in the target is rejected by the A-2b gate, which runs BEFORE the
        # backup is created. So no backup sidecar should ever appear for this failure.
        $fffd = [string][char]0xFFFD
        $original = ("head " + $fffd + "`n" + $script:Begin + "`nold`n" + $script:End + "`ntail`n")
        script:Write-Utf8NoBomFile -Path $target -Content $original
        $beforeBytes = script:Read-Bytes -Path $target

        $result = script:Invoke-Apply -SnippetPath $snippet -TargetPath $target
        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match 'U\+FFFD replacement character'

        (Test-Path -LiteralPath ($target + '.amb-backup')) | Should -BeFalse
        $afterBytes = script:Read-Bytes -Path $target
        [System.Linq.Enumerable]::SequenceEqual([byte[]]$beforeBytes, [byte[]]$afterBytes) | Should -BeTrue
    }

    It 'AC-AMB-BACKUP-EXISTS-REFUSE: a pre-existing .amb-backup is left intact and the apply refuses' {
        $dir = script:New-CaseDir -CaseName 'backup-exists'
        $snippet = Join-Path $dir 'snippet.md'
        $target  = Join-Path $dir 'CLAUDE.md'
        script:Write-Utf8NoBomFile -Path $snippet -Content (script:New-SnippetContent)
        $original = ("head`n" + $script:Begin + "`nold`n" + $script:End + "`ntail`n")
        script:Write-Utf8NoBomFile -Path $target -Content $original
        $targetBefore = script:Read-Bytes -Path $target

        # Simulate a recovery artifact left by a prior FAILED rollback: the backup holds
        # the only surviving copy of the user's original bytes. The apply must NOT clobber
        # it; it must refuse and leave both files untouched.
        $bak = $target + '.amb-backup'
        $sentinelBytes = [System.Text.Encoding]::UTF8.GetBytes("PRECIOUS ORIGINAL BYTES — do not overwrite`n")
        [System.IO.File]::WriteAllBytes($bak, $sentinelBytes)

        $result = script:Invoke-Apply -SnippetPath $snippet -TargetPath $target
        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match 'a prior backup already exists'

        # Existing backup preserved byte-for-byte; target unchanged.
        $bakAfter = script:Read-Bytes -Path $bak
        [System.Linq.Enumerable]::SequenceEqual([byte[]]$bakAfter, [byte[]]$sentinelBytes) | Should -BeTrue
        $targetAfter = script:Read-Bytes -Path $target
        [System.Linq.Enumerable]::SequenceEqual([byte[]]$targetAfter, [byte[]]$targetBefore) | Should -BeTrue
    }

    It 'AC-AMB-ROLLBACK-WRITEFAIL: a write failure (read-only target) leaves the target byte-unchanged' {
        # NOTE ON SIMULATION SCOPE: a post-write *verification mismatch* is defensively
        # unreachable with valid inputs — Set-ManagedBlock writes the snippet block and
        # the verifier re-extracts that same block, so they match by construction, and
        # any structural problem is caught pre-write. The closest deterministic failure
        # AFTER the pre-write gates is a failing write itself. A read-only target makes
        # Write-Utf8NoBom throw (the file is not truncated), exercising the rollback
        # branch; the invariant under test is that a failed apply never leaves the
        # target mutated.
        $dir = script:New-CaseDir -CaseName 'rollback-writefail'
        $snippet = Join-Path $dir 'snippet.md'
        $target  = Join-Path $dir 'CLAUDE.md'
        script:Write-Utf8NoBomFile -Path $snippet -Content (script:New-SnippetContent)
        $original = ("head`n" + $script:Begin + "`nold`n" + $script:End + "`ntail`n")
        script:Write-Utf8NoBomFile -Path $target -Content $original
        $beforeBytes = script:Read-Bytes -Path $target

        Set-ItemProperty -LiteralPath $target -Name IsReadOnly -Value $true
        try {
            $result = script:Invoke-Apply -SnippetPath $snippet -TargetPath $target
            $result.ExitCode | Should -Not -Be 0
            $result.Output | Should -Match 'apply-managed-block: FAIL'

            $afterBytes = script:Read-Bytes -Path $target
            [System.Linq.Enumerable]::SequenceEqual([byte[]]$beforeBytes, [byte[]]$afterBytes) | Should -BeTrue
        }
        finally {
            # Clear read-only so TestDrive cleanup (and any retained sidecar) can be removed.
            Set-ItemProperty -LiteralPath $target -Name IsReadOnly -Value $false
            $bak = $target + '.amb-backup'
            if (Test-Path -LiteralPath $bak) { Remove-Item -LiteralPath $bak -Force }
        }
    }
}

Describe 'apply-managed-block A-2d dry-run / diff' {
    It 'AC-AMB-DRYRUN-OK: a valid change previews, exits 0, writes nothing, creates no backup' {
        $dir = script:New-CaseDir -CaseName 'dryrun-ok'
        $snippet = Join-Path $dir 'snippet.md'
        $target  = Join-Path $dir 'CLAUDE.md'
        script:Write-Utf8NoBomFile -Path $snippet -Content (script:New-SnippetContent)
        $original = ("head`n" + $script:Begin + "`nOLD body`n" + $script:End + "`ntail`n")
        script:Write-Utf8NoBomFile -Path $target -Content $original
        $beforeBytes = script:Read-Bytes -Path $target

        # Phase 3.6: default dry-run now prints a COMPACT change summary (not the full block dump).
        $result = script:Invoke-Apply -SnippetPath $snippet -TargetPath $target -DryRun
        $result.ExitCode | Should -Be 0 -Because $result.Output
        $result.Output | Should -Match 'DRY-RUN \(no file written, no backup created\)'
        $result.Output | Should -Match 'DRY-RUN PASS \(managed block WOULD change\)'
        # Compact summary surface: header + line counts + changed-window + first changed current line.
        # Get-ManagedBlockContent includes the BEGIN/END marker lines, so the blocks are
        # 3 lines (BEGIN/OLD body/END) -> 4 lines (BEGIN/# managed payload/body line/END); the
        # markers are the common prefix(1)/suffix(1), leaving a -1/+2 changed window at block line 2.
        $result.Output | Should -Match 'compact summary; use -ShowFullDiff'
        $result.Output | Should -Match 'block lines: current=3 proposed=4'
        $result.Output | Should -Match 'unchanged: prefix=1 suffix=1'
        $result.Output | Should -Match 'changed window: current=-1 proposed=\+2 at block line 2'
        # The current side is ASCII; assert it. The proposed first line carries an em-dash whose
        # cross-process console capture is lossy on a non-UTF-8 host (see the AC-AMB-OK file-read
        # cases for the byte-preservation guarantee), so it is NOT asserted here.
        $result.Output | Should -Match 'first changed current line: OLD body'
        # Compact default does NOT emit the full before/after dump.
        $result.Output | Should -Not -Match 'managed block diff \(- current / \+ proposed\)'
        $result.Output | Should -Not -Match '(?m)^\+ body line'                     # second new line only appears in the full dump
        $result.Output | Should -Not -Match 'apply-managed-block: PASS'             # not a real apply

        # Target byte-unchanged and NO backup sidecar created.
        $afterBytes = script:Read-Bytes -Path $target
        [System.Linq.Enumerable]::SequenceEqual([byte[]]$beforeBytes, [byte[]]$afterBytes) | Should -BeTrue
        (Test-Path -LiteralPath ($target + '.amb-backup')) | Should -BeFalse
    }

    It 'AC-AMB-DRYRUN-COMPACT-1LINE: a one-line drift reports a tight changed window, not a full block dump' {
        $dir = script:New-CaseDir -CaseName 'dryrun-compact-1line'
        $snippet = Join-Path $dir 'snippet.md'
        $target  = Join-Path $dir 'CLAUDE.md'
        $pair = script:New-OneLineDriftPair
        script:Write-Utf8NoBomFile -Path $snippet -Content $pair.Snippet
        script:Write-Utf8NoBomFile -Path $target  -Content $pair.Target

        $result = script:Invoke-Apply -SnippetPath $snippet -TargetPath $target -DryRun
        $result.ExitCode | Should -Be 0 -Because $result.Output
        $result.Output | Should -Match 'DRY-RUN PASS \(managed block WOULD change\)'
        # 6 content lines + BEGIN/END markers = 8 block lines; single middle change at the 4th content
        # line => common prefix 4 (BEGIN+alpha+bravo+charlie), suffix 3 (echo+foxtrot+END), window
        # -1/+1 at block line 5.
        $result.Output | Should -Match 'block lines: current=8 proposed=8'
        $result.Output | Should -Match 'unchanged: prefix=4 suffix=3'
        $result.Output | Should -Match 'changed window: current=-1 proposed=\+1 at block line 5'
        $result.Output | Should -Match 'first changed current line: delta'
        $result.Output | Should -Match 'first changed proposed line: delta-CHANGED'
        # Compact: the full dump and the unchanged lines must NOT be printed by default.
        $result.Output | Should -Not -Match 'managed block diff \(- current / \+ proposed\)'
        $result.Output | Should -Not -Match '(?m)^- alpha'
        $result.Output | Should -Not -Match '(?m)^\+ foxtrot'

        (Test-Path -LiteralPath ($target + '.amb-backup')) | Should -BeFalse
    }

    It 'AC-AMB-DRYRUN-FULLDIFF: -ShowFullDiff prints the full managed-block before/after on top of the summary' {
        $dir = script:New-CaseDir -CaseName 'dryrun-fulldiff'
        $snippet = Join-Path $dir 'snippet.md'
        $target  = Join-Path $dir 'CLAUDE.md'
        $pair = script:New-OneLineDriftPair
        script:Write-Utf8NoBomFile -Path $snippet -Content $pair.Snippet
        script:Write-Utf8NoBomFile -Path $target  -Content $pair.Target

        $result = script:Invoke-Apply -SnippetPath $snippet -TargetPath $target -DryRun -ShowFullDiff
        $result.ExitCode | Should -Be 0 -Because $result.Output
        $result.Output | Should -Match 'DRY-RUN PASS \(managed block WOULD change\)'
        # The compact summary is still present...
        $result.Output | Should -Match 'changed window: current=-1 proposed=\+1 at block line 5'
        # ...and the full before/after dump now appears, including the UNCHANGED lines on both sides.
        $result.Output | Should -Match 'managed block diff \(- current / \+ proposed\)'
        $result.Output | Should -Match '(?m)^- alpha'
        $result.Output | Should -Match '(?m)^\+ alpha'
        $result.Output | Should -Match '(?m)^- delta$'
        $result.Output | Should -Match '(?m)^\+ delta-CHANGED'

        (Test-Path -LiteralPath ($target + '.amb-backup')) | Should -BeFalse
    }

    It 'AC-AMB-DRYRUN-NOCHANGE: when the block already matches, dry-run reports no change' {
        $dir = script:New-CaseDir -CaseName 'dryrun-nochange'
        $snippet = Join-Path $dir 'snippet.md'
        $target  = Join-Path $dir 'CLAUDE.md'
        script:Write-Utf8NoBomFile -Path $snippet -Content (script:New-SnippetContent)
        # Target's managed block is identical to the snippet's block (terminator-agnostic).
        $original = ("head`n" + $script:Begin + "`n# managed payload — v2`nbody line`n" + $script:End + "`ntail`n")
        script:Write-Utf8NoBomFile -Path $target -Content $original
        $beforeBytes = script:Read-Bytes -Path $target

        $result = script:Invoke-Apply -SnippetPath $snippet -TargetPath $target -DryRun
        $result.ExitCode | Should -Be 0 -Because $result.Output
        $result.Output | Should -Match 'already up to date \(no change\)'
        $result.Output | Should -Match 'DRY-RUN PASS \(no change\)'

        $afterBytes = script:Read-Bytes -Path $target
        [System.Linq.Enumerable]::SequenceEqual([byte[]]$beforeBytes, [byte[]]$afterBytes) | Should -BeTrue
        (Test-Path -LiteralPath ($target + '.amb-backup')) | Should -BeFalse
    }

    It 'AC-AMB-DRYRUN-FAIL-FFFD: dry-run still rejects a U+FFFD target before any write' {
        $dir = script:New-CaseDir -CaseName 'dryrun-fffd'
        $snippet = Join-Path $dir 'snippet.md'
        $target  = Join-Path $dir 'CLAUDE.md'
        script:Write-Utf8NoBomFile -Path $snippet -Content (script:New-SnippetContent)
        $fffd = [string][char]0xFFFD
        $original = ("head " + $fffd + "`n" + $script:Begin + "`nold`n" + $script:End + "`ntail`n")
        script:Write-Utf8NoBomFile -Path $target -Content $original
        $beforeBytes = script:Read-Bytes -Path $target

        $result = script:Invoke-Apply -SnippetPath $snippet -TargetPath $target -DryRun
        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match 'U\+FFFD replacement character'
        $result.Output | Should -Not -Match 'DRY-RUN PASS'

        $afterBytes = script:Read-Bytes -Path $target
        [System.Linq.Enumerable]::SequenceEqual([byte[]]$beforeBytes, [byte[]]$afterBytes) | Should -BeTrue
        (Test-Path -LiteralPath ($target + '.amb-backup')) | Should -BeFalse
    }

    It 'AC-AMB-DRYRUN-FAIL-INVALID-UTF8: dry-run still rejects invalid UTF-8 before any write' {
        $dir = script:New-CaseDir -CaseName 'dryrun-utf8'
        $snippet = Join-Path $dir 'snippet.md'
        $target  = Join-Path $dir 'CLAUDE.md'
        script:Write-Utf8NoBomFile -Path $snippet -Content (script:New-SnippetContent)

        $head = [System.Text.Encoding]::UTF8.GetBytes("head`n")
        $bad  = [byte[]]@(0xFF, 0xFE)
        $blk  = [System.Text.Encoding]::UTF8.GetBytes("`n" + $script:Begin + "`nold`n" + $script:End + "`ntail`n")
        $bytes = New-Object byte[] ($head.Length + $bad.Length + $blk.Length)
        [System.Array]::Copy($head, 0, $bytes, 0, $head.Length)
        [System.Array]::Copy($bad, 0, $bytes, $head.Length, $bad.Length)
        [System.Array]::Copy($blk, 0, $bytes, $head.Length + $bad.Length, $blk.Length)
        [System.IO.File]::WriteAllBytes($target, $bytes)
        $beforeBytes = script:Read-Bytes -Path $target

        $result = script:Invoke-Apply -SnippetPath $snippet -TargetPath $target -DryRun
        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match 'invalid UTF-8 byte sequence'
        $result.Output | Should -Not -Match 'DRY-RUN PASS'

        $afterBytes = script:Read-Bytes -Path $target
        [System.Linq.Enumerable]::SequenceEqual([byte[]]$beforeBytes, [byte[]]$afterBytes) | Should -BeTrue
        (Test-Path -LiteralPath ($target + '.amb-backup')) | Should -BeFalse
    }

    It 'AC-AMB-DRYRUN-FAIL-MARKER: dry-run still rejects a target with no marker pair before any write' {
        $dir = script:New-CaseDir -CaseName 'dryrun-marker'
        $snippet = Join-Path $dir 'snippet.md'
        $target  = Join-Path $dir 'CLAUDE.md'
        script:Write-Utf8NoBomFile -Path $snippet -Content (script:New-SnippetContent)
        $original = "# no markers here`njust user content`n"
        script:Write-Utf8NoBomFile -Path $target -Content $original

        $result = script:Invoke-Apply -SnippetPath $snippet -TargetPath $target -DryRun
        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match 'no AI_HARNESS_TOOLSET_GLOBAL marker pair'
        $result.Output | Should -Not -Match 'DRY-RUN PASS'

        (script:Read-Utf8NoBomFile -Path $target) | Should -Be $original
        (Test-Path -LiteralPath ($target + '.amb-backup')) | Should -BeFalse
    }
}

Describe 'apply-managed-block -Insert (first-time insertion IO, IU-B-09)' {

    BeforeAll {
        function script:Invoke-Insert {
            param([string] $SnippetPath, [string] $TargetPath, [switch] $DryRun)
            $procArgs = @(
                '-NoProfile', '-ExecutionPolicy', 'Bypass',
                '-File', $script:ApplyScript,
                '-Insert', '-SnippetPath', $SnippetPath, '-TargetPath', $TargetPath
            )
            if ($DryRun) { $procArgs += '-DryRun' }
            $proc = Invoke-NativeProcess -Executable 'powershell.exe' -Arguments $procArgs
            $text = (($proc.Stdout + $proc.Stderr) -replace "`r`n", "`n").TrimEnd("`n")
            return [pscustomobject]@{ ExitCode = $proc.ExitCode; Output = $text }
        }
    }

    It 'AC-AMB-INSERT-1: absent target -> CREATES the file with exactly one marker pair (no BOM, no backup)' {
        $dir = script:New-CaseDir -CaseName 'insert-create'
        $snippet = Join-Path $dir 'snippet.md'
        $target  = Join-Path $dir 'AGENTS.md'
        script:Write-Utf8NoBomFile -Path $snippet -Content (script:New-SnippetContent)

        (Test-Path -LiteralPath $target) | Should -BeFalse
        $result = script:Invoke-Insert -SnippetPath $snippet -TargetPath $target
        $result.ExitCode | Should -Be 0
        $result.Output | Should -Match 'created .* with managed block'
        (Test-Path -LiteralPath $target -PathType Leaf) | Should -BeTrue

        $written = script:Read-Utf8NoBomFile -Path $target
        ([regex]::Matches($written, '(?m)^' + [regex]::Escape($script:Begin) + '$')).Count | Should -Be 1
        ([regex]::Matches($written, '(?m)^' + [regex]::Escape($script:End)   + '$')).Count | Should -Be 1
        $bytes = script:Read-Bytes -Path $target
        (($bytes.Length -ge 3) -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) | Should -BeFalse
        (Test-Path -LiteralPath ($target + '.amb-backup')) | Should -BeFalse
    }

    It 'AC-AMB-INSERT-2: existing 0-pair target -> APPENDS, preserving existing content; no backup left' {
        $dir = script:New-CaseDir -CaseName 'insert-append'
        $snippet = Join-Path $dir 'snippet.md'
        $target  = Join-Path $dir 'CLAUDE.md'
        script:Write-Utf8NoBomFile -Path $snippet -Content (script:New-SnippetContent)
        $existing = "# My CLAUDE.md`n`nuser content line`n"
        script:Write-Utf8NoBomFile -Path $target -Content $existing

        $result = script:Invoke-Insert -SnippetPath $snippet -TargetPath $target
        $result.ExitCode | Should -Be 0
        $result.Output | Should -Match 'inserted managed block'

        $written = script:Read-Utf8NoBomFile -Path $target
        $written.StartsWith($existing) | Should -BeTrue
        ([regex]::Matches($written, '(?m)^' + [regex]::Escape($script:Begin) + '$')).Count | Should -Be 1
        (Test-Path -LiteralPath ($target + '.amb-backup')) | Should -BeFalse
    }

    It 'AC-AMB-INSERT-3: target already has 1 marker pair -> FAIL-FAST, no mutation, no backup' {
        $dir = script:New-CaseDir -CaseName 'insert-1pair'
        $snippet = Join-Path $dir 'snippet.md'
        $target  = Join-Path $dir 'CLAUDE.md'
        script:Write-Utf8NoBomFile -Path $snippet -Content (script:New-SnippetContent)
        $existing = "head`n$script:Begin`nold body`n$script:End`ntail`n"
        script:Write-Utf8NoBomFile -Path $target -Content $existing

        $result = script:Invoke-Insert -SnippetPath $snippet -TargetPath $target
        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match 'already contains a managed block'
        (script:Read-Utf8NoBomFile -Path $target) | Should -Be $existing
        (Test-Path -LiteralPath ($target + '.amb-backup')) | Should -BeFalse
    }

    It 'AC-AMB-INSERT-4: malformed marker state (incomplete pair) -> FAIL-FAST before write' {
        $dir = script:New-CaseDir -CaseName 'insert-malformed'
        $snippet = Join-Path $dir 'snippet.md'
        $target  = Join-Path $dir 'CLAUDE.md'
        script:Write-Utf8NoBomFile -Path $snippet -Content (script:New-SnippetContent)
        $existing = "head`n$script:Begin`nbody but no end`n"
        script:Write-Utf8NoBomFile -Path $target -Content $existing

        $result = script:Invoke-Insert -SnippetPath $snippet -TargetPath $target
        $result.ExitCode | Should -Not -Be 0
        (script:Read-Utf8NoBomFile -Path $target) | Should -Be $existing
        (Test-Path -LiteralPath ($target + '.amb-backup')) | Should -BeFalse
    }

    It 'AC-AMB-INSERT-5: pre-existing .amb-backup on a 0-pair target -> FAIL-FAST, refuses to clobber it' {
        $dir = script:New-CaseDir -CaseName 'insert-backup-exists'
        $snippet = Join-Path $dir 'snippet.md'
        $target  = Join-Path $dir 'CLAUDE.md'
        script:Write-Utf8NoBomFile -Path $snippet -Content (script:New-SnippetContent)
        $existing = "user content`n"
        script:Write-Utf8NoBomFile -Path $target -Content $existing
        script:Write-Utf8NoBomFile -Path ($target + '.amb-backup') -Content 'prior backup bytes'

        $result = script:Invoke-Insert -SnippetPath $snippet -TargetPath $target
        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match 'prior backup already exists'
        (script:Read-Utf8NoBomFile -Path $target) | Should -Be $existing
        (script:Read-Utf8NoBomFile -Path ($target + '.amb-backup')) | Should -Be 'prior backup bytes'
    }

    It 'AC-AMB-INSERT-6: BOM-prefixed existing target -> FAIL-FAST (encoding not laundered)' {
        $dir = script:New-CaseDir -CaseName 'insert-bom'
        $snippet = Join-Path $dir 'snippet.md'
        $target  = Join-Path $dir 'CLAUDE.md'
        script:Write-Utf8NoBomFile -Path $snippet -Content (script:New-SnippetContent)
        script:Write-Utf8BomFile -Path $target -Content "user content`n"

        $result = script:Invoke-Insert -SnippetPath $snippet -TargetPath $target
        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match 'UTF-8 BOM'
    }

    It 'AC-AMB-INSERT-7: U+FFFD in the existing target -> FAIL-FAST (corruption sentinel)' {
        $dir = script:New-CaseDir -CaseName 'insert-fffd'
        $snippet = Join-Path $dir 'snippet.md'
        $target  = Join-Path $dir 'CLAUDE.md'
        script:Write-Utf8NoBomFile -Path $snippet -Content (script:New-SnippetContent)
        script:Write-Utf8NoBomFile -Path $target -Content ("user " + [char]0xFFFD + " content`n")

        $result = script:Invoke-Insert -SnippetPath $snippet -TargetPath $target
        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match 'U\+FFFD'
    }

    It 'AC-AMB-INSERT-8: -DryRun on absent target writes nothing and creates no file' {
        $dir = script:New-CaseDir -CaseName 'insert-dryrun'
        $snippet = Join-Path $dir 'snippet.md'
        $target  = Join-Path $dir 'AGENTS.md'
        script:Write-Utf8NoBomFile -Path $snippet -Content (script:New-SnippetContent)

        $result = script:Invoke-Insert -SnippetPath $snippet -TargetPath $target -DryRun
        $result.ExitCode | Should -Be 0
        $result.Output | Should -Match 'DRY-RUN PASS \(managed block WOULD be inserted\)'
        (Test-Path -LiteralPath $target) | Should -BeFalse
    }

    It 'AC-AMB-INSERT-10: a DIRECTORY at the target path -> FAIL-FAST for -Insert, directory NOT deleted' {
        $dir = script:New-CaseDir -CaseName 'insert-dir-target'
        $snippet = Join-Path $dir 'snippet.md'
        script:Write-Utf8NoBomFile -Path $snippet -Content (script:New-SnippetContent)
        # A directory exists where the managed-block target file would be (e.g. a stray AGENTS.md dir).
        $target = Join-Path $dir 'AGENTS.md'
        $null = New-Item -ItemType Directory -Path $target -Force
        # Put a sentinel file inside so we can prove the directory + its content survive.
        script:Write-Utf8NoBomFile -Path (Join-Path $target 'keep.txt') -Content 'do not clobber'

        $result = script:Invoke-Insert -SnippetPath $snippet -TargetPath $target
        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match 'exists but is not a file'
        # The directory and its content must be untouched (no clobber).
        (Test-Path -LiteralPath $target -PathType Container) | Should -BeTrue
        (Test-Path -LiteralPath (Join-Path $target 'keep.txt') -PathType Leaf) | Should -BeTrue
    }

    It 'AC-AMB-INSERT-9: -Insert and -Remove together -> FAIL-FAST (mutually exclusive)' {
        $dir = script:New-CaseDir -CaseName 'insert-remove-conflict'
        $snippet = Join-Path $dir 'snippet.md'
        $target  = Join-Path $dir 'CLAUDE.md'
        script:Write-Utf8NoBomFile -Path $snippet -Content (script:New-SnippetContent)
        script:Write-Utf8NoBomFile -Path $target -Content "x`n"

        $procArgs = @(
            '-NoProfile', '-ExecutionPolicy', 'Bypass',
            '-File', $script:ApplyScript,
            '-Insert', '-Remove', '-SnippetPath', $snippet, '-TargetPath', $target
        )
        $proc = Invoke-NativeProcess -Executable 'powershell.exe' -Arguments $procArgs
        $proc.ExitCode | Should -Not -Be 0
        (($proc.Stdout + $proc.Stderr)) | Should -Match 'mutually exclusive'
    }
}
