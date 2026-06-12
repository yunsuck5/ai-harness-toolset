Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Shared activation-surface resolver.
#
# Single source of truth for the activation surfaces and their canonical source -> destination
# mapping + mutation class. The surfaces are: two always-present managed-block surfaces (Claude
# CLAUDE.md, Codex effective AGENTS.md/.override.md) plus ONE canonical-overwrite skill mirror per
# source skill under snippets/claude-skills/<name>/SKILL.md (generic, deterministic, local-first
# directory enumeration — no per-skill hardcoding, no registry; Batch 2C-0; the activation-surface
# policy decision record / rationale is preserved in git history — this resolver, not
# any doc, is the operative authority). The install-global / install-update
# VERIFY path (byte-identity check), the activate-global APPLY path, and the uninstall owned-surface
# resolver all resolve surfaces through this helper, so coverage cannot drift on WHICH files are the
# surfaces (e.g. the Codex AGENTS.override.md precedence is decided here, once).
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

    $destClaudeMd  = Join-Path $ClaudeHome 'CLAUDE.md'

    # Codex effective destination: AGENTS.override.md takes precedence over
    # AGENTS.md when present (INSTALL.md §10 valid-destination rule). Resolving it
    # here means VERIFY and APPLY bind to the same effective file — applying to
    # AGENTS.md while verify inspects an existing AGENTS.override.md would be an
    # apply-vs-verify gap.
    $codexAgentsMd = Join-Path $CodexHome 'AGENTS.md'
    $codexOverride = Join-Path $CodexHome 'AGENTS.override.md'
    $destCodexMd   = if (Test-Path -LiteralPath $codexOverride -PathType Leaf) { $codexOverride } else { $codexAgentsMd }

    $plan = New-Object System.Collections.Generic.List[psobject]

    # Two always-present managed-block surfaces.
    $plan.Add([pscustomobject]@{
        Name        = 'claude-user-global-managed-block'
        Scope       = 'Claude'
        Destination = $destClaudeMd
        Source      = $sourceClaudeSnippet
        CompareMode = 'managed-block'
        Class       = 'managed-block'
        SkillName   = $null
    })
    $plan.Add([pscustomobject]@{
        Name        = 'codex-user-global-managed-block'
        Scope       = 'Codex'
        Destination = $destCodexMd
        Source      = $sourceCodexSnippet
        CompareMode = 'managed-block'
        Class       = 'managed-block'
        SkillName   = $null
    })

    # Generic deployed runtime extension (skill) mirrors: every source skill
    # snippets/claude-skills/<name>/SKILL.md becomes a forced-mirror + final-verify surface
    # (canonical-overwrite) at <ClaudeHome>/skills/<name>/SKILL.md. Deterministic, local-first
    # directory enumeration (no registry, no per-skill hardcoding); ordering is by skill name so the
    # surface list is stable across apply / verify / uninstall. A directory without a SKILL.md is not a
    # skill and is skipped. The skill is enumerated only when it exists under PayloadRoot, so callers
    # MUST pass the payload root that actually contains snippets/ (the install area's current/ for
    # verify + uninstall; the repo root for an apply run from a source clone).
    $skillsRoot = Join-Path $PayloadRoot 'snippets/claude-skills'
    if (Test-Path -LiteralPath $skillsRoot -PathType Container) {
        $skillDirs = @(Get-ChildItem -LiteralPath $skillsRoot -Directory |
            Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'SKILL.md') -PathType Leaf } |
            Sort-Object -Property Name)
        foreach ($d in $skillDirs) {
            $skillName = $d.Name
            $plan.Add([pscustomobject]@{
                Name        = ('skill-mirror:' + $skillName)
                Scope       = 'Skill'
                Destination = (Join-Path $ClaudeHome ('skills/' + $skillName + '/SKILL.md'))
                Source      = (Join-Path $d.FullName 'SKILL.md')
                CompareMode = 'whole-file'
                Class       = 'canonical-overwrite'
                SkillName   = $skillName
            })
        }
    }

    return $plan.ToArray()
}
