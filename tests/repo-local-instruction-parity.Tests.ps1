Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Parity guard for the repo-local instruction surface (Track C).
# Root CLAUDE.md and AGENTS.md share a byte-identical body below the
# "<!-- BEGIN SHARED BODY" marker; only the tool-specific header above it may
# differ. This enforces the mirror-edit rule
# (docs/architecture/instruction-surface/REPO_LOCAL_INSTRUCTION_SURFACE_PLAN.md
# section 4) so a single-file shared-body edit cannot drift silently. It also
# asserts neither file embeds the global managed block (these files are
# repo-local development instructions, not the global snippet adoption target).

BeforeAll {
    $script:RepoRoot   = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).ProviderPath
    $script:ClaudePath = Join-Path $script:RepoRoot 'CLAUDE.md'
    $script:AgentsPath = Join-Path $script:RepoRoot 'AGENTS.md'
    $script:Marker     = '<!-- BEGIN SHARED BODY'

    function script:Get-SharedBody {
        param([string] $Path)
        # Read raw bytes and decode as UTF-8 (the .md files are UTF-8 / no BOM / LF,
        # so an ordinal string comparison of the decoded shared region is equivalent
        # to a byte comparison and also catches any EOL drift). The shared region is
        # the marker line through EOF; the header above the marker is excluded.
        $bytes = [System.IO.File]::ReadAllBytes($Path)
        $text  = [System.Text.Encoding]::UTF8.GetString($bytes)
        $idx   = $text.IndexOf($script:Marker, [System.StringComparison]::Ordinal)
        if ($idx -lt 0) { return $null }
        return $text.Substring($idx)
    }
}

Describe 'repo-local instruction surface parity (CLAUDE.md / AGENTS.md)' {
    It 'AC-RLIS-1: both root instruction files exist' {
        Test-Path -LiteralPath $script:ClaudePath -PathType Leaf | Should -BeTrue
        Test-Path -LiteralPath $script:AgentsPath -PathType Leaf | Should -BeTrue
    }

    It 'AC-RLIS-2: both files carry the shared-body BEGIN marker' {
        script:Get-SharedBody -Path $script:ClaudePath | Should -Not -BeNullOrEmpty
        script:Get-SharedBody -Path $script:AgentsPath | Should -Not -BeNullOrEmpty
    }

    It 'AC-RLIS-3: shared body (BEGIN marker -> EOF) is byte-identical across both files' {
        $claudeShared = script:Get-SharedBody -Path $script:ClaudePath
        $agentsShared = script:Get-SharedBody -Path $script:AgentsPath
        # Ordinal (case-sensitive, culture-invariant) exact match: the mirror-edit
        # rule requires byte-for-byte parity of the shared body.
        ($claudeShared -ceq $agentsShared) | Should -BeTrue -Because 'the shared body must be byte-identical (mirror-edit rule)'
    }

    It 'AC-RLIS-4: neither file embeds the global managed block' {
        $claudeText = [System.Text.Encoding]::UTF8.GetString([System.IO.File]::ReadAllBytes($script:ClaudePath))
        $agentsText = [System.Text.Encoding]::UTF8.GetString([System.IO.File]::ReadAllBytes($script:AgentsPath))
        $claudeText | Should -Not -Match 'AI_HARNESS_TOOLSET_GLOBAL'
        $agentsText | Should -Not -Match 'AI_HARNESS_TOOLSET_GLOBAL'
    }
}
