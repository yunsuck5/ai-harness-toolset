Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Shared activation-surface resolver.
#
# Single source of truth for the three activation surfaces and their canonical
# source -> destination mapping + mutation class. Both the install-update.ps1
# VERIFY path (byte-identity check) and the activate-global.ps1 APPLY path
# resolve surfaces through this helper, so apply coverage and verify coverage
# cannot drift on WHICH files are the surfaces (e.g. the Codex
# AGENTS.override.md precedence is decided here, once).
#
# Two mutation classes (INSTALL.md §9.1 / §10):
#   - managed-block        : marker-bounded splice; user-authored content OUTSIDE
#                            the marker pair is preserved. Apply is the hardened
#                            scripts/apply-managed-block.ps1 primitive (its
#                            .amb-backup / rollback lifecycle is scoped to that
#                            primitive ALONE).
#   - canonical-overwrite  : whole-file overwrite from the canonical payload, with
#                            post-write byte/hash verify. No merge, no marker
#                            parsing, no backup / rollback / sidecar. Failure is
#                            fail-fast + report + reinstall guidance.
#
# PayloadRoot is the directory that CONTAINS snippets/ (the install area's current/
# for verify; the repo root for an apply run from a source clone). ClaudeHome /
# CodexHome are the user-global instruction roots (overridable so tests never
# touch the real %USERPROFILE%).

function Get-ActivationSurfacePlan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)] [string] $PayloadRoot,
        [Parameter(Mandatory = $true)] [string] $ClaudeHome,
        [Parameter(Mandatory = $true)] [string] $CodexHome
    )

    $sourceClaudeSnippet = Join-Path $PayloadRoot 'snippets/CLAUDE_SNIPPET.md'
    $sourceCodexSnippet  = Join-Path $PayloadRoot 'snippets/AGENTS_SNIPPET.md'
    $sourceSkillFile     = Join-Path $PayloadRoot 'snippets/claude-skills/ai-harness-review/SKILL.md'

    $destClaudeMd  = Join-Path $ClaudeHome 'CLAUDE.md'
    $destSkillFile = Join-Path $ClaudeHome 'skills/ai-harness-review/SKILL.md'

    # Codex effective destination: AGENTS.override.md takes precedence over
    # AGENTS.md when present (INSTALL.md §10 valid-destination rule). Resolving it
    # here means VERIFY and APPLY bind to the same effective file — applying to
    # AGENTS.md while verify inspects an existing AGENTS.override.md would be an
    # apply-vs-verify gap.
    $codexAgentsMd = Join-Path $CodexHome 'AGENTS.md'
    $codexOverride = Join-Path $CodexHome 'AGENTS.override.md'
    $destCodexMd   = if (Test-Path -LiteralPath $codexOverride -PathType Leaf) { $codexOverride } else { $codexAgentsMd }

    return @(
        [pscustomobject]@{
            Name        = 'claude-user-global-managed-block'
            Scope       = 'Claude'
            Destination = $destClaudeMd
            Source      = $sourceClaudeSnippet
            CompareMode = 'managed-block'
            Class       = 'managed-block'
        },
        [pscustomobject]@{
            Name        = 'codex-user-global-managed-block'
            Scope       = 'Codex'
            Destination = $destCodexMd
            Source      = $sourceCodexSnippet
            CompareMode = 'managed-block'
            Class       = 'managed-block'
        },
        [pscustomobject]@{
            Name        = 'review-skill-mirror'
            Scope       = 'Skill'
            Destination = $destSkillFile
            Source      = $sourceSkillFile
            CompareMode = 'whole-file'
            Class       = 'canonical-overwrite'
        }
    )
}
