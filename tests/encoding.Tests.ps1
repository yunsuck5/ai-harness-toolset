Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

BeforeAll {
    $script:RepoRoot     = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).ProviderPath
    $script:EncodingLib  = Join-Path $script:RepoRoot 'scripts/lib/encoding.ps1'

    . $script:EncodingLib

    function script:New-CaseDir {
        param([string] $Name)
        $p = Join-Path $TestDrive ('pester-encoding-' + $Name)
        if (Test-Path -LiteralPath $p) {
            Remove-Item -LiteralPath $p -Recurse -Force
        }
        $null = New-Item -ItemType Directory -Path $p -Force
        return ([System.IO.Path]::GetFullPath($p))
    }
}

Describe 'Read-Utf8 strict UTF-8 decode (A-2a fail-fast)' {
    It 'AC-ENC-STRICT-1: invalid UTF-8 bytes throw instead of decoding to U+FFFD' {
        $dir  = script:New-CaseDir -CaseName 'invalid-bytes'
        $path = Join-Path $dir 'invalid.md'

        # 0xFF / 0xFE are never valid in a UTF-8 byte stream. A replacement-fallback
        # decoder would silently turn these into U+FFFD; a strict decoder must throw.
        [System.IO.File]::WriteAllBytes($path, [byte[]]@(0x68, 0x69, 0xFF, 0xFE, 0x0A))

        { Read-Utf8 -Path $path } | Should -Throw -ErrorId * -Because 'invalid UTF-8 must fail fast'
        { Read-Utf8 -Path $path } | Should -Throw '*invalid UTF-8 byte sequence*'
    }

    It 'AC-ENC-STRICT-2: truncated multi-byte sequence throws (lone lead byte at EOF)' {
        $dir  = script:New-CaseDir -CaseName 'truncated'
        $path = Join-Path $dir 'truncated.md'

        # 0xE2 begins a 3-byte sequence (e.g. the em-dash U+2014 = E2 80 94) but the
        # continuation bytes are missing, so the stream is incomplete / invalid UTF-8.
        [System.IO.File]::WriteAllBytes($path, [byte[]]@(0x61, 0xE2))

        { Read-Utf8 -Path $path } | Should -Throw '*invalid UTF-8 byte sequence*'
    }

    It 'AC-ENC-STRICT-3: never returns a string containing U+FFFD for invalid input' {
        $dir  = script:New-CaseDir -CaseName 'no-replacement-char'
        $path = Join-Path $dir 'invalid2.md'

        [System.IO.File]::WriteAllBytes($path, [byte[]]@(0x80, 0x81, 0x82))

        $threw = $false
        $result = $null
        try {
            $result = Read-Utf8 -Path $path
        }
        catch {
            $threw = $true
        }

        $threw | Should -BeTrue -Because 'strict decode must fail rather than substitute U+FFFD'
        if (-not $threw) {
            # Defensive: if a future regression stops throwing, the substitution
            # sentinel must at minimum not have leaked in silently.
            $result.Contains([char]0xFFFD) | Should -BeFalse
        }
    }

    It 'AC-ENC-STRICT-4: valid UTF-8 (incl. non-ASCII) still round-trips unchanged' {
        $dir  = script:New-CaseDir -CaseName 'valid-roundtrip'
        $path = Join-Path $dir 'valid.md'

        # Korean + em-dash — exactly the kind of content the 2026-05-21 incident
        # corrupted. Strict decoding must NOT reject well-formed UTF-8.
        $content = "# 사용자 메모리 — 보존`n본문 줄`n"
        $bytes   = (New-Object System.Text.UTF8Encoding($false)).GetBytes($content)
        [System.IO.File]::WriteAllBytes($path, $bytes)

        $read = Read-Utf8 -Path $path
        $read | Should -Be $content
        $read.Contains([char]0xFFFD) | Should -BeFalse
    }

    It 'AC-ENC-STRICT-5: the thrown message names the offending file path' {
        $dir  = script:New-CaseDir -CaseName 'message-path'
        $path = Join-Path $dir 'named.md'
        [System.IO.File]::WriteAllBytes($path, [byte[]]@(0xFF))

        $msg = $null
        try {
            Read-Utf8 -Path $path
        }
        catch {
            $msg = $_.Exception.Message
        }
        $msg | Should -Match 'invalid UTF-8 byte sequence'
        $msg | Should -Match ([regex]::Escape('named.md'))
    }
}
