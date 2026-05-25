Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

BeforeAll {
    $script:RepoRoot   = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).ProviderPath
    . (Join-Path $script:RepoRoot 'scripts/lib/native-process.ps1')
    $script:Script     = Join-Path $script:RepoRoot 'scripts/activate-global.ps1'
    $script:ClaudeSnip = Join-Path $script:RepoRoot 'snippets/CLAUDE_SNIPPET.md'
    $script:AgentsSnip = Join-Path $script:RepoRoot 'snippets/AGENTS_SNIPPET.md'

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

    function script:Read-Bytes {
        param([string] $Path)
        return [System.IO.File]::ReadAllBytes((Resolve-Path -LiteralPath $Path).ProviderPath)
    }

    function script:New-CaseDir {
        param([string] $CaseName)
        $dir = Join-Path $TestDrive ('pester-activate-' + $CaseName)
        if (Test-Path -LiteralPath $dir) { Remove-Item -LiteralPath $dir -Recurse -Force }
        $null = New-Item -ItemType Directory -Path $dir -Force
        $null = New-Item -ItemType Directory -Path (Join-Path $dir '.claude') -Force
        $null = New-Item -ItemType Directory -Path (Join-Path $dir '.codex') -Force
        return ([System.IO.Path]::GetFullPath($dir))
    }

    # A target carrying a single valid managed-block pair plus surrounding user content.
    function script:Write-MarkedTarget {
        param([string] $Path, [string] $BlockBody = 'OLD body')
        script:Write-Utf8NoBomFile -Path $Path -Content (
            "# user content`n" + $script:Begin + "`n" + $BlockBody + "`n" + $script:End + "`ntail`n")
    }

    function script:Invoke-Activate {
        param(
            [string] $Scope,
            [string] $ClaudeHome,
            [string] $CodexHome,
            [switch] $Apply
        )
        $procArgs = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $script:Script)
        if ($Scope)      { $procArgs += @('-Scope', $Scope) }
        if ($ClaudeHome) { $procArgs += @('-ClaudeHome', $ClaudeHome) }
        if ($CodexHome)  { $procArgs += @('-CodexHome', $CodexHome) }
        if ($Apply)      { $procArgs += '-Apply' }
        $proc = Invoke-NativeProcess -Executable 'powershell.exe' -Arguments $procArgs
        $exitCode = $proc.ExitCode
        $text = (($proc.Stdout + $proc.Stderr) -replace "`r`n", "`n").TrimEnd("`n")
        return [pscustomobject]@{ ExitCode = $exitCode; Output = $text }
    }
}

Describe 'activate-global snippet -> target mapping' {
    It 'AC-AG-MAPPING: dry-run prints a deterministic snippet->target plan for both scopes' {
        $dir = script:New-CaseDir -CaseName 'mapping'
        $ch  = Join-Path $dir '.claude'
        $cx  = Join-Path $dir '.codex'
        script:Write-MarkedTarget -Path (Join-Path $ch 'CLAUDE.md')
        script:Write-MarkedTarget -Path (Join-Path $cx 'AGENTS.md')

        $result = script:Invoke-Activate -Scope 'All' -ClaudeHome $ch -CodexHome $cx
        $result.ExitCode | Should -Be 0 -Because $result.Output
        $result.Output | Should -Match 'mode=DRY-RUN'
        # Deterministic mapping: CLAUDE_SNIPPET -> <ClaudeHome>/CLAUDE.md
        $result.Output | Should -Match ([regex]::Escape('CLAUDE_SNIPPET.md'))
        $result.Output | Should -Match ([regex]::Escape((Join-Path $ch 'CLAUDE.md')))
        # AGENTS_SNIPPET -> <CodexHome>/AGENTS.md
        $result.Output | Should -Match ([regex]::Escape('AGENTS_SNIPPET.md'))
        $result.Output | Should -Match ([regex]::Escape((Join-Path $cx 'AGENTS.md')))
        $result.Output | Should -Match 'activate-global: PASS'
    }
}

Describe 'activate-global dry-run safety (no write, no backup)' {
    It 'AC-AG-DRYRUN-NOWRITE: default dry-run leaves targets byte-unchanged and creates no .amb-backup' {
        $dir = script:New-CaseDir -CaseName 'dryrun'
        $ch  = Join-Path $dir '.claude'
        $cx  = Join-Path $dir '.codex'
        $ct  = Join-Path $ch 'CLAUDE.md'
        $at  = Join-Path $cx 'AGENTS.md'
        script:Write-MarkedTarget -Path $ct
        script:Write-MarkedTarget -Path $at
        $cBefore = script:Read-Bytes -Path $ct
        $aBefore = script:Read-Bytes -Path $at

        $result = script:Invoke-Activate -Scope 'All' -ClaudeHome $ch -CodexHome $cx
        $result.ExitCode | Should -Be 0 -Because $result.Output
        $result.Output | Should -Match 'DRY-RUN \(no file written, no backup created\)'

        [System.Linq.Enumerable]::SequenceEqual([byte[]](script:Read-Bytes -Path $ct), [byte[]]$cBefore) | Should -BeTrue
        [System.Linq.Enumerable]::SequenceEqual([byte[]](script:Read-Bytes -Path $at), [byte[]]$aBefore) | Should -BeTrue
        @(Get-ChildItem -Path $dir -Recurse -Filter '*.amb-backup' -ErrorAction SilentlyContinue).Count | Should -Be 0
    }
}

Describe 'activate-global explicit apply (temp targets only)' {
    It 'AC-AG-APPLY: -Apply writes the snippet block to temp targets and leaves no .amb-backup' {
        $dir = script:New-CaseDir -CaseName 'apply'
        $ch  = Join-Path $dir '.claude'
        $cx  = Join-Path $dir '.codex'
        $ct  = Join-Path $ch 'CLAUDE.md'
        $at  = Join-Path $cx 'AGENTS.md'
        script:Write-MarkedTarget -Path $ct
        script:Write-MarkedTarget -Path $at

        $result = script:Invoke-Activate -Scope 'All' -ClaudeHome $ch -CodexHome $cx -Apply
        $result.ExitCode | Should -Be 0 -Because $result.Output
        $result.Output | Should -Match 'mode=APPLY'
        $result.Output | Should -Match 'activate-global: PASS'

        # Targets now carry the real snippet payload; user content preserved.
        $cText = [System.IO.File]::ReadAllText($ct, (New-Object System.Text.UTF8Encoding($false)))
        $aText = [System.IO.File]::ReadAllText($at, (New-Object System.Text.UTF8Encoding($false)))
        $cText | Should -Match 'ai-harness-toolset instructions for CLAUDE.md-compatible agents'
        $cText | Should -Match 'user content'
        $cText | Should -Not -Match 'OLD body'
        $aText | Should -Match 'ai-harness-toolset instructions for AGENTS.md-compatible agents'
        $aText | Should -Match 'user content'

        # A-2c cleanup preserved: no stale backup after a successful apply.
        @(Get-ChildItem -Path $dir -Recurse -Filter '*.amb-backup' -ErrorAction SilentlyContinue).Count | Should -Be 0
    }
}

Describe 'activate-global surfaces apply failures without writing' {
    It 'AC-AG-FAIL-FFFD: a U+FFFD target fails through orchestration, target unchanged, no write' {
        $dir = script:New-CaseDir -CaseName 'fffd'
        $ch  = Join-Path $dir '.claude'
        $ct  = Join-Path $ch 'CLAUDE.md'
        $fffd = [string][char]0xFFFD
        script:Write-Utf8NoBomFile -Path $ct -Content (
            "# user " + $fffd + "`n" + $script:Begin + "`nold`n" + $script:End + "`ntail`n")
        $before = script:Read-Bytes -Path $ct

        $result = script:Invoke-Activate -Scope 'Claude' -ClaudeHome $ch -Apply
        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match 'U\+FFFD replacement character'
        $result.Output | Should -Match 'activate-global: FAIL'
        [System.Linq.Enumerable]::SequenceEqual([byte[]](script:Read-Bytes -Path $ct), [byte[]]$before) | Should -BeTrue
        @(Get-ChildItem -Path $dir -Recurse -Filter '*.amb-backup' -ErrorAction SilentlyContinue).Count | Should -Be 0
    }

    It 'AC-AG-FAIL-INVALID-UTF8: an invalid-UTF-8 target fails through orchestration, target unchanged' {
        $dir = script:New-CaseDir -CaseName 'utf8'
        $ch  = Join-Path $dir '.claude'
        $ct  = Join-Path $ch 'CLAUDE.md'
        $head = [System.Text.Encoding]::UTF8.GetBytes("head`n")
        $bad  = [byte[]]@(0xFF, 0xFE)
        $blk  = [System.Text.Encoding]::UTF8.GetBytes("`n" + $script:Begin + "`nold`n" + $script:End + "`ntail`n")
        $bytes = New-Object byte[] ($head.Length + $bad.Length + $blk.Length)
        [System.Array]::Copy($head, 0, $bytes, 0, $head.Length)
        [System.Array]::Copy($bad, 0, $bytes, $head.Length, $bad.Length)
        [System.Array]::Copy($blk, 0, $bytes, $head.Length + $bad.Length, $blk.Length)
        [System.IO.File]::WriteAllBytes($ct, $bytes)
        $before = script:Read-Bytes -Path $ct

        $result = script:Invoke-Activate -Scope 'Claude' -ClaudeHome $ch -Apply
        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match 'invalid UTF-8 byte sequence'
        [System.Linq.Enumerable]::SequenceEqual([byte[]](script:Read-Bytes -Path $ct), [byte[]]$before) | Should -BeTrue
        @(Get-ChildItem -Path $dir -Recurse -Filter '*.amb-backup' -ErrorAction SilentlyContinue).Count | Should -Be 0
    }

    It 'AC-AG-FAIL-MARKER: a target with no marker pair fails through orchestration, target unchanged' {
        $dir = script:New-CaseDir -CaseName 'marker'
        $ch  = Join-Path $dir '.claude'
        $ct  = Join-Path $ch 'CLAUDE.md'
        $original = "# no markers here`njust user content`n"
        script:Write-Utf8NoBomFile -Path $ct -Content $original

        $result = script:Invoke-Activate -Scope 'Claude' -ClaudeHome $ch -Apply
        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match 'no AI_HARNESS_TOOLSET_GLOBAL marker pair'
        ([System.IO.File]::ReadAllText($ct, (New-Object System.Text.UTF8Encoding($false)))) | Should -Be $original
    }
}

Describe 'activate-global forbidden destination guard' {
    It 'AC-AG-FORBIDDEN: refuses an AGENTS.md under a .claude directory and writes nothing' {
        $dir = script:New-CaseDir -CaseName 'forbidden'
        # Point CodexHome at a .claude dir so the resolved target would be
        # <...>/.claude/AGENTS.md — the section-6 forbidden path.
        $badCodex = Join-Path $dir '.claude'
        $forbiddenTarget = Join-Path $badCodex 'AGENTS.md'

        $result = script:Invoke-Activate -Scope 'Codex' -CodexHome $badCodex -Apply
        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match 'forbidden destination'
        # The guard runs before any apply, so the forbidden file is never created.
        (Test-Path -LiteralPath $forbiddenTarget) | Should -BeFalse
    }

    It 'AC-AG-FORBIDDEN-DOTSEG: a trailing "." segment cannot smuggle a .claude\AGENTS.md past the guard' {
        $dir = script:New-CaseDir -CaseName 'forbidden-dot'
        # <dir>\.claude\.  -> normalizes to <dir>\.claude, target <dir>\.claude\AGENTS.md.
        $badCodex = Join-Path (Join-Path $dir '.claude') '.'
        $forbiddenTarget = [System.IO.Path]::GetFullPath((Join-Path $badCodex 'AGENTS.md'))

        $result = script:Invoke-Activate -Scope 'Codex' -CodexHome $badCodex -Apply
        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match 'forbidden destination'
        (Test-Path -LiteralPath $forbiddenTarget) | Should -BeFalse
    }

    It 'AC-AG-FORBIDDEN-DOTDOT: a ".." segment cannot smuggle a .claude\AGENTS.md past the guard' {
        $dir = script:New-CaseDir -CaseName 'forbidden-dotdot'
        # <dir>\.claude\child\..  -> normalizes to <dir>\.claude, target <dir>\.claude\AGENTS.md.
        $badCodex = Join-Path (Join-Path (Join-Path $dir '.claude') 'child') '..'
        $forbiddenTarget = [System.IO.Path]::GetFullPath((Join-Path $badCodex 'AGENTS.md'))

        $result = script:Invoke-Activate -Scope 'Codex' -CodexHome $badCodex -Apply
        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match 'forbidden destination'
        (Test-Path -LiteralPath $forbiddenTarget) | Should -BeFalse
    }
}

Describe 'activate-global does not touch real %USERPROFILE%' {
    It 'AC-AG-NO-REAL-USERPROFILE: a temp-homed dry-run and apply leave the real ~/.claude/CLAUDE.md untouched' {
        $realClaude = Join-Path $env:USERPROFILE '.claude\CLAUDE.md'
        $realExisted = Test-Path -LiteralPath $realClaude
        $realBefore = if ($realExisted) { [System.IO.File]::ReadAllBytes($realClaude) } else { $null }

        $dir = script:New-CaseDir -CaseName 'no-userprofile'
        $ch  = Join-Path $dir '.claude'
        $cx  = Join-Path $dir '.codex'
        script:Write-MarkedTarget -Path (Join-Path $ch 'CLAUDE.md')
        script:Write-MarkedTarget -Path (Join-Path $cx 'AGENTS.md')

        $dry = script:Invoke-Activate -Scope 'All' -ClaudeHome $ch -CodexHome $cx
        $dry.ExitCode | Should -Be 0 -Because $dry.Output
        $apply = script:Invoke-Activate -Scope 'All' -ClaudeHome $ch -CodexHome $cx -Apply
        $apply.ExitCode | Should -Be 0 -Because $apply.Output

        # The plan must reference the temp homes, never the real %USERPROFILE% target.
        $dry.Output | Should -Match ([regex]::Escape($dir))
        $dry.Output | Should -Not -Match ([regex]::Escape($realClaude))

        # The real user-global CLAUDE.md is byte-identical (or still absent) afterward.
        if ($realExisted) {
            (Test-Path -LiteralPath $realClaude) | Should -BeTrue
            [System.Linq.Enumerable]::SequenceEqual([byte[]]([System.IO.File]::ReadAllBytes($realClaude)), [byte[]]$realBefore) | Should -BeTrue
        }
        else {
            (Test-Path -LiteralPath $realClaude) | Should -BeFalse
        }
    }
}
