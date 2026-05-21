Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

BeforeAll {
    $script:RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).ProviderPath
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
        param([string] $SnippetPath, [string] $TargetPath)
        $procArgs = @(
            '-NoProfile',
            '-ExecutionPolicy', 'Bypass',
            '-File', $script:ApplyScript,
            '-SnippetPath', $SnippetPath,
            '-TargetPath', $TargetPath
        )
        $combined = & powershell.exe @procArgs 2>&1
        $exitCode = $LASTEXITCODE
        $text = ($combined | ForEach-Object { [string]$_ }) -join "`n"
        return [pscustomobject]@{ ExitCode = $exitCode; Output = $text }
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
