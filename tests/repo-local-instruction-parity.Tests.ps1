Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Parity guard for the repo-local instruction surface (Track C).
# Root CLAUDE.md and AGENTS.md share a byte-identical body below the
# "<!-- BEGIN SHARED BODY" marker; only the tool-specific header above it may
# differ. This enforces the mirror-edit rule
# (the root CLAUDE.md / AGENTS.md *Mirror-edit rule*; Track C design
# in git history) so a single-file shared-body edit cannot drift silently. It also
# asserts neither file embeds the global managed block (these files are
# repo-local development instructions, not the global snippet adoption target).

BeforeAll {
    $script:RepoRoot   = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).ProviderPath
    $script:ClaudePath = Join-Path $script:RepoRoot 'CLAUDE.md'
    $script:AgentsPath = Join-Path $script:RepoRoot 'AGENTS.md'
    $script:Marker     = '<!-- BEGIN SHARED BODY'
    . (Join-Path $script:RepoRoot 'scripts/lib/managed-block.ps1')

    function script:Find-ByteSequenceIndex {
        param(
            [byte[]] $Bytes,
            [byte[]] $Needle
        )

        if ($Needle.Length -eq 0 -or $Bytes.Length -lt $Needle.Length) {
            return -1
        }

        for ($i = 0; $i -le ($Bytes.Length - $Needle.Length); $i++) {
            $matched = $true
            for ($j = 0; $j -lt $Needle.Length; $j++) {
                if ($Bytes[$i + $j] -ne $Needle[$j]) {
                    $matched = $false
                    break
                }
            }
            if ($matched) {
                return $i
            }
        }
        return -1
    }

    function script:Get-SharedBodyBytes {
        param([string] $Path)

        $bytes = [System.IO.File]::ReadAllBytes($Path)
        $markerBytes = [System.Text.Encoding]::ASCII.GetBytes($script:Marker)
        $idx = script:Find-ByteSequenceIndex -Bytes $bytes -Needle $markerBytes
        if ($idx -lt 0) { return $null }
        return [byte[]] $bytes[$idx..($bytes.Length - 1)]
    }

    function script:Test-ByteArrayEqual {
        param(
            [byte[]] $Left,
            [byte[]] $Right
        )

        if ($null -eq $Left -or $null -eq $Right -or $Left.Length -ne $Right.Length) {
            return $false
        }
        for ($i = 0; $i -lt $Left.Length; $i++) {
            if ($Left[$i] -ne $Right[$i]) {
                return $false
            }
        }
        return $true
    }

    function script:Get-StrictUtf8Text {
        param([string] $Path)

        $utf8 = New-Object System.Text.UTF8Encoding($false, $true)
        return $utf8.GetString([System.IO.File]::ReadAllBytes($Path))
    }

    function script:Test-ContainsActualManagedMarker {
        param([string] $Content)

        $segments = @(Split-ManagedBlockLines -Content $Content)
        $scan = Find-ManagedBlockMarkers -Segments $segments
        return (($scan.BeginIndices.Count + $scan.EndIndices.Count) -gt 0)
    }
}

Describe 'repo-local instruction surface parity (CLAUDE.md / AGENTS.md)' {
    It 'AC-RLIS-1: both root instruction files exist' {
        Test-Path -LiteralPath $script:ClaudePath -PathType Leaf | Should -BeTrue
        Test-Path -LiteralPath $script:AgentsPath -PathType Leaf | Should -BeTrue
    }

    It 'AC-RLIS-2: both files carry the shared-body BEGIN marker' {
        @(script:Get-SharedBodyBytes -Path $script:ClaudePath).Count | Should -BeGreaterThan 0
        @(script:Get-SharedBodyBytes -Path $script:AgentsPath).Count | Should -BeGreaterThan 0
    }

    It 'AC-RLIS-3: shared body (BEGIN marker -> EOF) is byte-identical across both files' {
        $claudeShared = script:Get-SharedBodyBytes -Path $script:ClaudePath
        $agentsShared = script:Get-SharedBodyBytes -Path $script:AgentsPath
        (script:Test-ByteArrayEqual -Left $claudeShared -Right $agentsShared) |
            Should -BeTrue -Because 'the shared body must be byte-identical (mirror-edit rule)'
    }

    It 'AC-RLIS-4: neither file contains an actual managed-block marker outside fenced code' {
        $claudeText = script:Get-StrictUtf8Text -Path $script:ClaudePath
        $agentsText = script:Get-StrictUtf8Text -Path $script:AgentsPath
        script:Test-ContainsActualManagedMarker -Content $claudeText | Should -BeFalse
        script:Test-ContainsActualManagedMarker -Content $agentsText | Should -BeFalse
    }

    It 'does not treat prose, inline code, or fenced examples as managed markers' {
        $begin = '<!-- BEGIN AI_HARNESS_TOOLSET_GLOBAL -->'
        $end = '<!-- END AI_HARNESS_TOOLSET_GLOBAL -->'
        $content = @"
The token AI_HARNESS_TOOLSET_GLOBAL is ordinary prose here.
Inline: ``$begin``
``````
$begin
$end
``````
"@
        script:Test-ContainsActualManagedMarker -Content $content | Should -BeFalse
    }

    It 'detects a whole-line managed marker outside fenced code' {
        $content = "before`n<!-- BEGIN AI_HARNESS_TOOLSET_GLOBAL -->`nafter`n"
        script:Test-ContainsActualManagedMarker -Content $content | Should -BeTrue
    }

    It 'keeps an opposite delimiter inside the active fence without hiding a later outside marker' {
        $begin = '<!-- BEGIN AI_HARNESS_TOOLSET_GLOBAL -->'
        $insideOnly = [string]::Join("`n", @('```', '~~~', $begin, '```', ''))
        script:Test-ContainsActualManagedMarker -Content $insideOnly | Should -BeFalse
        script:Test-ContainsActualManagedMarker -Content ($insideOnly + $begin + "`n") | Should -BeTrue
    }

    It 'keeps a shorter same-character run inside the active fence without hiding a later outside marker' {
        $begin = '<!-- BEGIN AI_HARNESS_TOOLSET_GLOBAL -->'
        $insideOnly = [string]::Join("`n", @('````', '```', $begin, '````', ''))
        script:Test-ContainsActualManagedMarker -Content $insideOnly | Should -BeFalse
        script:Test-ContainsActualManagedMarker -Content ($insideOnly + $begin + "`n") | Should -BeTrue
    }
}
