[CmdletBinding()]
param(
    [ValidateSet('Claude', 'Codex', 'All')] [string] $Scope = 'All',
    [string] $ClaudeHome,
    [string] $CodexHome,
    [switch] $Apply,
    # Dry-run only: forward -ShowFullDiff to apply-managed-block so each surface prints the full
    # managed-block before/after dump instead of the default compact change summary. No effect with -Apply.
    [switch] $ShowFullDiff
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'lib/native-process.ps1')

# A-2e global activation apply orchestration.
#
# Maps the repo's activation snippets to their managed-block destinations and drives
# the hardened scripts/apply-managed-block.ps1 for each one. It performs NO text
# splicing of its own — every read/write goes through apply-managed-block.ps1, so the
# A-2a (strict UTF-8 fail-fast), A-2b (U+FFFD fail-fast), A-2c (backup / rollback,
# refuse-on-existing-backup) and A-2d (dry-run no-write / no-backup) safety properties
# are inherited verbatim rather than reimplemented.
#
# Default-safe: with no -Apply switch this previews every mapped change in dry-run mode
# (no target write, no .amb-backup). Real writes happen ONLY with -Apply.
#
# Snippet -> destination mapping (source of truth: docs/decisions/GLOBAL_ADOPTION_DECISION.md
# section 6 path table):
#   - snippets/CLAUDE_SNIPPET.md -> <ClaudeHome>/CLAUDE.md   (Claude user-global)
#   - snippets/AGENTS_SNIPPET.md -> <CodexHome>/AGENTS.md    (Codex user-global)
# Where (overridable for tests so real %USERPROFILE% is never touched):
#   - ClaudeHome default = %USERPROFILE%\.claude
#   - CodexHome  default = %CODEX_HOME% if set, else %USERPROFILE%\.codex
#
# Forbidden destination (section 6): %USERPROFILE%\.claude\AGENTS.md is not a global
# instruction path for any agent; this orchestration refuses to ever target it.
#
# Out of scope (deliberately NOT orchestrated here): project-root CLAUDE.md / AGENTS.md,
# the AGENTS.override.md precedence rule, creating a missing destination file (a separate
# explicit-approval boundary in section 6), and any user-approval / diff-confirmation UX
# (a real -Apply against user-global files is a separate explicit, user-approved step).

$repoRoot   = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).ProviderPath
$snippetsDir = Join-Path $repoRoot 'snippets'
$applyScript = Join-Path $PSScriptRoot 'apply-managed-block.ps1'

if ([string]::IsNullOrEmpty($ClaudeHome)) {
    $ClaudeHome = Join-Path $env:USERPROFILE '.claude'
}
if ([string]::IsNullOrEmpty($CodexHome)) {
    if (-not [string]::IsNullOrEmpty($env:CODEX_HOME)) {
        $CodexHome = $env:CODEX_HOME
    }
    else {
        $CodexHome = Join-Path $env:USERPROFILE '.codex'
    }
}

# Build the explicit, deterministic plan.
$plan = New-Object System.Collections.Generic.List[psobject]
if ($Scope -eq 'Claude' -or $Scope -eq 'All') {
    $plan.Add([pscustomobject]@{
        Name    = 'Claude'
        Snippet = Join-Path $snippetsDir 'CLAUDE_SNIPPET.md'
        # Normalize so the forbidden-path guard below cannot be bypassed by '.' / '..'
        # path segments (e.g. <home>\.claude\. or <home>\.claude\child\..).
        Target  = [System.IO.Path]::GetFullPath((Join-Path $ClaudeHome 'CLAUDE.md'))
    })
}
if ($Scope -eq 'Codex' -or $Scope -eq 'All') {
    $plan.Add([pscustomobject]@{
        Name    = 'Codex'
        Snippet = Join-Path $snippetsDir 'AGENTS_SNIPPET.md'
        Target  = [System.IO.Path]::GetFullPath((Join-Path $CodexHome 'AGENTS.md'))
    })
}

$mode = if ($Apply) { 'APPLY' } else { 'DRY-RUN' }
Write-Host ('activate-global: mode={0}' -f $mode)

# Forbidden-path guard + snippet existence, evaluated before any apply is invoked.
foreach ($item in $plan) {
    Write-Host ('activate-global: plan [{0}] snippet={1} -> target={2}' -f $item.Name, $item.Snippet, $item.Target)

    # Section 6 forbidden path: an AGENTS.md whose parent directory is '.claude'.
    # $item.Target is already normalized via [System.IO.Path]::GetFullPath above, so
    # '.' / '..' segments are collapsed and cannot smuggle the target past this check.
    $targetLeaf  = Split-Path -Leaf $item.Target
    $targetParent = Split-Path -Leaf (Split-Path -Parent $item.Target)
    if ($targetLeaf -ieq 'AGENTS.md' -and $targetParent -ieq '.claude') {
        Write-Host ('activate-global: FAIL forbidden destination (no agent uses %USERPROFILE%\.claude\AGENTS.md): {0}' -f $item.Target)
        exit 1
    }

    if (-not (Test-Path -LiteralPath $item.Snippet -PathType Leaf)) {
        Write-Host ('activate-global: FAIL snippet not found: {0}' -f $item.Snippet)
        exit 1
    }
}

# Execute each mapped apply by delegating to apply-managed-block.ps1 in a child process
# (the apply script calls 'exit', so it must not run in this host). Dry-run unless -Apply.
$failed = 0
foreach ($item in $plan) {
    Write-Host ('activate-global: [{0}] {1} via apply-managed-block...' -f $item.Name, $mode)

    $procArgs = @(
        '-NoProfile',
        '-ExecutionPolicy', 'Bypass',
        '-File', $applyScript,
        '-SnippetPath', $item.Snippet,
        '-TargetPath', $item.Target
    )
    if (-not $Apply) {
        $procArgs += '-DryRun'
        if ($ShowFullDiff) { $procArgs += '-ShowFullDiff' }
    }

    $proc = Invoke-NativeProcess -Executable 'powershell.exe' -Arguments $procArgs
    $code = $proc.ExitCode
    $combinedText = ($proc.Stdout + $proc.Stderr).TrimEnd("`r", "`n")
    if (-not [string]::IsNullOrEmpty($combinedText)) {
        foreach ($line in ($combinedText -split "`r?`n")) {
            Write-Host $line
        }
    }

    if ($code -eq 0) {
        Write-Host ('activate-global: [{0}] OK' -f $item.Name)
    }
    else {
        $failed++
        Write-Host ('activate-global: [{0}] FAIL (exit {1})' -f $item.Name, $code)
    }
}

Write-Host ('activate-global: SUMMARY {0} ok / {1} failed (of {2})' -f ($plan.Count - $failed), $failed, $plan.Count)
if ($failed -gt 0) {
    Write-Host 'activate-global: FAIL'
    exit 1
}
Write-Host 'activate-global: PASS'
exit 0
