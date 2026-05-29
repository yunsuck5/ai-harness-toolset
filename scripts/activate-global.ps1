[CmdletBinding()]
param(
    [ValidateSet('Claude', 'Codex', 'Skill', 'All')] [string] $Scope = 'All',
    [string] $ClaudeHome,
    [string] $CodexHome,
    [switch] $Apply,
    # Dry-run only: forward -ShowFullDiff to apply-managed-block so each managed-block surface prints
    # the full managed-block before/after dump instead of the default compact change summary. No effect
    # with -Apply, and no effect on the canonical-overwrite (skill) surface.
    [switch] $ShowFullDiff,
    # Optional: require an interactive two-choice (Yes/No) confirmation before -Apply mutates
    # (direct-terminal use). Default OFF — the explicit -Apply invocation is the command-implied
    # approval. With -ConfirmInteractive set but no interactive terminal, the apply ABORTS (it does
    # not silently fall through). It is strictly two-state; there is NO multi-choice menu.
    [switch] $ConfirmInteractive
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'lib/native-process.ps1')
. (Join-Path $PSScriptRoot 'lib/hash.ps1')
. (Join-Path $PSScriptRoot 'lib/activation-surface.ps1')

# Full 3-surface activation apply orchestrator (Phase 4a).
#
# It applies the SAME three activation surfaces that scripts/install-update.ps1 VERIFIES, resolved
# through the shared scripts/lib/activation-surface.ps1 helper so apply coverage == verify coverage
# (no apply-vs-verify destination drift, including the Codex AGENTS.override.md precedence).
#
# Two mutation classes (INSTALL.md §9.1 / §10) handled by DIFFERENT mechanisms:
#   - managed-block surfaces  (Claude CLAUDE.md, Codex effective AGENTS.md / AGENTS.override.md):
#       marker-bounded splice via the hardened scripts/apply-managed-block.ps1 in a child process.
#       User-authored content OUTSIDE the marker pair is preserved. The .amb-backup / rollback
#       lifecycle lives ENTIRELY inside that primitive and is scoped to this class only.
#   - canonical-overwrite surface  (review skill mirror SKILL.md):
#       whole-file overwrite from the canonical payload + post-write SHA-256 verify. No merge, no
#       marker parsing, no .amb-backup, no rollback, no backup sidecar. A post-write verify failure
#       is fail-fast + report + reinstall guidance (the canonical source is the recovery source).
#
# Default-safe: with no -Apply this previews every selected surface in dry-run mode (no target write,
# no backup). Real writes happen ONLY with -Apply, and only after an all-surface preflight passes.
# This orchestrator does NOT fold activation into update-source, does NOT auto-apply from a
# natural-language update, does NOT create a missing managed-block destination (separate explicit
# boundary — it fails/reports), and implements NO cross-surface transaction (per-surface semantics).
#
# Snippet/source -> destination mapping (source of truth: scripts/lib/activation-surface.ps1):
#   - snippets/CLAUDE_SNIPPET.md                          -> <ClaudeHome>/CLAUDE.md          (managed-block)
#   - snippets/AGENTS_SNIPPET.md                          -> <CodexHome>/AGENTS.md|override   (managed-block)
#   - snippets/claude-skills/ai-harness-review/SKILL.md   -> <ClaudeHome>/skills/ai-harness-review/SKILL.md (canonical-overwrite)
# Where (overridable for tests so real %USERPROFILE% is never touched):
#   - ClaudeHome default = %USERPROFILE%\.claude
#   - CodexHome  default = %CODEX_HOME% if set, else %USERPROFILE%\.codex
#
# Forbidden destination (§10): %USERPROFILE%\.claude\AGENTS.md is not a global instruction path for
# any agent; this orchestration refuses to ever target it (guard normalizes . / .. first).

$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).ProviderPath
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

# ---------------------------------------------------------------------------
# Two-choice (Yes/No) approval for -ConfirmInteractive. There is NO multi-choice menu and NO
# auto-yes: a noninteractive context resolves to abort (never 'yes'), and confirmation requires an
# explicit Enter on the highlighted choice (Esc / Ctrl+C = No / abort). The console selector below
# is source-reviewed; default highlight is Yes but no timeout can auto-select it.
# ---------------------------------------------------------------------------

function script:Test-ActivateApprovalInteractive {
    [CmdletBinding()]
    param()
    try {
        if ([Console]::IsInputRedirected) { return $false }
    }
    catch {
        return $false
    }
    if (-not [Environment]::UserInteractive) { return $false }
    return $true
}

function script:Read-ActivateApproval {
    [CmdletBinding()]
    param([string] $Prompt = 'Apply this activation mutation to your global/user files?')

    $highlight = 'yes'
    $render = {
        param($h)
        $yesMark = if ($h -eq 'yes') { '>' } else { ' ' }
        $noMark  = if ($h -eq 'no')  { '>' } else { ' ' }
        [Console]::Error.WriteLine('')
        [Console]::Error.WriteLine($Prompt)
        [Console]::Error.WriteLine(('  {0} Yes' -f $yesMark))
        [Console]::Error.WriteLine(('  {0} No'  -f $noMark))
        [Console]::Error.WriteLine('(Up/Down to move, Enter to confirm, Esc = No)')
    }
    & $render $highlight
    while ($true) {
        $keyInfo = [Console]::ReadKey($true)
        switch ($keyInfo.Key) {
            'UpArrow'   { $highlight = 'yes'; & $render $highlight }
            'DownArrow' { $highlight = 'no';  & $render $highlight }
            'Enter'     { return $highlight }
            'Escape'    { return 'no' }
            default     { }
        }
    }
}

# ---------------------------------------------------------------------------
# Managed-block surface (marker-bounded splice via apply-managed-block.ps1 child process).
# ---------------------------------------------------------------------------

function script:Invoke-ManagedBlockSurface {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)] [pscustomobject] $Surface,
        [switch] $Apply,
        [switch] $ShowFullDiff
    )

    $procArgs = @(
        '-NoProfile',
        '-ExecutionPolicy', 'Bypass',
        '-File', $script:applyScript,
        '-SnippetPath', $Surface.Source,
        '-TargetPath', $Surface.TargetFull
    )
    if (-not $Apply) {
        $procArgs += '-DryRun'
        if ($ShowFullDiff) { $procArgs += '-ShowFullDiff' }
    }

    $proc = Invoke-NativeProcess -Executable 'powershell.exe' -Arguments $procArgs
    $combinedText = ($proc.Stdout + $proc.Stderr).TrimEnd("`r", "`n")
    if (-not [string]::IsNullOrEmpty($combinedText)) {
        foreach ($line in ($combinedText -split "`r?`n")) {
            Write-Host $line
        }
    }
    $ok = ($proc.ExitCode -eq 0)
    return [pscustomobject]@{
        Ok       = $ok
        ExitCode = $proc.ExitCode
        # In APPLY mode apply-managed-block performs its own post-apply block==snippet verification
        # and rolls back (restoring original bytes) on mismatch, so exit 0 IS the verified state.
        Verify   = if (-not $Apply) { 'n/a' } elseif ($ok) { 'ok' } else { 'failed' }
        Action   = if (-not $Apply) { 'preview' } elseif ($ok) { 'applied' } else { 'failed' }
    }
}

# ---------------------------------------------------------------------------
# Canonical-overwrite surface (whole-file overwrite + post-write SHA-256 verify). No backup,
# no rollback, no sidecar, no marker parsing, no merge. Fail-fast + report on verify failure.
# ---------------------------------------------------------------------------

function script:Invoke-SkillMirrorSurface {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)] [pscustomobject] $Surface,
        [switch] $Apply
    )

    $src = $Surface.Source
    $dst = $Surface.TargetFull
    $name = $Surface.Name

    # Source existence is preflighted by the caller, but re-guard defensively.
    if (-not (Test-Path -LiteralPath $src -PathType Leaf)) {
        Write-Host ('activate-global: [{0}] FAIL canonical source not found: {1}' -f $name, $src)
        return [pscustomobject]@{ Ok = $false; Verify = 'failed'; Action = 'failed' }
    }

    $srcHash   = Get-FileSha256 -Path $src
    $dstExists = Test-Path -LiteralPath $dst -PathType Leaf
    $dstHash   = if ($dstExists) { Get-FileSha256 -Path $dst } else { $null }
    $action    = if (-not $dstExists) { 'create' } elseif ($dstHash -cne $srcHash) { 'overwrite' } else { 'unchanged' }

    if (-not $Apply) {
        Write-Host ('activate-global: [{0}] DRY-RUN canonical-overwrite (no file written, no backup created)' -f $name)
        Write-Host ('activate-global: [{0}] target {1}' -f $name, $dst)
        Write-Host ('activate-global: [{0}] source {1}' -f $name, $src)
        Write-Host ('activate-global: [{0}] srcHash={1}' -f $name, $srcHash)
        Write-Host ('activate-global: [{0}] dstHash={1}' -f $name, $(if ($dstExists) { $dstHash } else { 'absent' }))
        Write-Host ('activate-global: [{0}] action={1}' -f $name, $action)
        if ($action -ne 'unchanged') {
            Write-Host ('activate-global: [{0}] NOTE -Apply OVERWRITES the whole destination file from the canonical payload (no merge, no backup, no rollback)' -f $name)
        }
        Write-Host ('activate-global: [{0}] DRY-RUN PASS ({1})' -f $name, $action)
        return [pscustomobject]@{ Ok = $true; Verify = 'n/a'; Action = ('would-' + $action) }
    }

    if ($action -eq 'unchanged') {
        Write-Host ('activate-global: [{0}] unchanged (destination already byte-identical to canonical source; no write)' -f $name)
        return [pscustomobject]@{ Ok = $true; Verify = 'ok'; Action = 'unchanged' }
    }

    # Whole-file byte overwrite from the canonical source. Create the parent directory if the skill
    # surface does not yet exist (canonical artifact; this is NOT a managed-block destination create).
    try {
        $parent = Split-Path -Parent $dst
        if (-not [string]::IsNullOrEmpty($parent) -and -not (Test-Path -LiteralPath $parent -PathType Container)) {
            $null = New-Item -ItemType Directory -Path $parent -Force
        }
        $bytes = [System.IO.File]::ReadAllBytes($src)
        [System.IO.File]::WriteAllBytes($dst, $bytes)
    }
    catch {
        Write-Host ('activate-global: [{0}] FAIL canonical-overwrite write error: {1}' -f $name, $_.Exception.Message)
        Write-Host ('activate-global: [{0}] recovery: re-run apply or perform a clean reinstall from the canonical source' -f $name)
        return [pscustomobject]@{ Ok = $false; Verify = 'failed'; Action = 'failed' }
    }

    # Post-write byte/hash identity verify. No rollback for this class — a mismatch is reported with
    # reinstall guidance (the canonical source is the recovery source-of-truth, INSTALL.md §9 / §9.1).
    $writtenHash = Get-FileSha256 -Path $dst
    if ($writtenHash -cne $srcHash) {
        Write-Host ('activate-global: [{0}] FAIL post-write hash mismatch (src={1} dst={2}); destination was overwritten and is NOT rolled back' -f $name, $srcHash, $writtenHash)
        Write-Host ('activate-global: [{0}] recovery: re-run apply or perform a clean reinstall from the canonical source' -f $name)
        return [pscustomobject]@{ Ok = $false; Verify = 'failed'; Action = $action }
    }

    Write-Host ('activate-global: [{0}] {1} canonical-overwrite OK (post-write hash verified)' -f $name, $action)
    return [pscustomobject]@{ Ok = $true; Verify = 'ok'; Action = $action }
}

# ---------------------------------------------------------------------------
# Build the explicit, deterministic plan (filtered by -Scope) via the shared resolver.
# ---------------------------------------------------------------------------

$allSurfaces = Get-ActivationSurfacePlan -PayloadRoot $repoRoot -ClaudeHome $ClaudeHome -CodexHome $CodexHome
$plan = New-Object System.Collections.Generic.List[psobject]
foreach ($s in $allSurfaces) {
    if ($Scope -eq 'All' -or $Scope -eq $s.Scope) {
        # Normalize the target so the forbidden-path guard below cannot be bypassed by '.' / '..'
        # path segments (e.g. <home>\.claude\. or <home>\.claude\child\..).
        $targetFull = [System.IO.Path]::GetFullPath($s.Destination)
        $plan.Add([pscustomobject]@{
            Name        = $s.Name
            Scope       = $s.Scope
            Class       = $s.Class
            Source      = $s.Source
            Destination = $s.Destination
            TargetFull  = $targetFull
        })
    }
}

$mode = if ($Apply) { 'APPLY' } else { 'DRY-RUN' }
Write-Host ('activate-global: mode={0}' -f $mode)
Write-Host ('activate-global: scope={0} surfaces={1}' -f $Scope, $plan.Count)

# ---------------------------------------------------------------------------
# Forbidden-path guard + source existence preflight — evaluated before any apply/preview.
# ---------------------------------------------------------------------------
foreach ($item in $plan) {
    Write-Host ('activate-global: plan [{0}] class={1} source={2} -> target={3}' -f $item.Name, $item.Class, $item.Source, $item.TargetFull)

    # Section 6 forbidden path: an AGENTS.md whose parent directory is '.claude'.
    # $item.TargetFull is already normalized via [System.IO.Path]::GetFullPath above, so
    # '.' / '..' segments are collapsed and cannot smuggle the target past this check.
    $targetLeaf   = Split-Path -Leaf $item.TargetFull
    $targetParent = Split-Path -Leaf (Split-Path -Parent $item.TargetFull)
    if ($targetLeaf -ieq 'AGENTS.md' -and $targetParent -ieq '.claude') {
        Write-Host ('activate-global: FAIL forbidden destination (no agent uses %USERPROFILE%\.claude\AGENTS.md): {0}' -f $item.TargetFull)
        Write-Host 'activate-global: activationStatus=failed'
        Write-Host 'activate-global: FAIL'
        exit 1
    }

    if (-not (Test-Path -LiteralPath $item.Source -PathType Leaf)) {
        Write-Host ('activate-global: FAIL source not found: {0}' -f $item.Source)
        Write-Host 'activate-global: activationStatus=failed'
        Write-Host 'activate-global: FAIL'
        exit 1
    }
}

# ---------------------------------------------------------------------------
# DRY-RUN: preview every selected surface (no writes). activationStatus=preview when every
# surface previews valid; failed if any managed-block preview is invalid (bad marker/encoding).
# ---------------------------------------------------------------------------
if (-not $Apply) {
    $results = New-Object System.Collections.Generic.List[psobject]
    foreach ($item in $plan) {
        Write-Host ('activate-global: [{0}] {1} via {2}...' -f $item.Name, $mode, $(if ($item.Class -eq 'managed-block') { 'apply-managed-block' } else { 'canonical-overwrite' }))
        $r = if ($item.Class -eq 'managed-block') {
            script:Invoke-ManagedBlockSurface -Surface $item -ShowFullDiff:$ShowFullDiff
        }
        else {
            script:Invoke-SkillMirrorSurface -Surface $item
        }
        Write-Host ('activate-global: surface name={0} class={1} action={2} verify={3}' -f $item.Name, $item.Class, $r.Action, $r.Verify)
        $results.Add($r)
    }
    $failed = @($results | Where-Object { -not $_.Ok }).Count
    $okCount = $plan.Count - $failed
    Write-Host ('activate-global: SUMMARY {0} ok / {1} failed (of {2})' -f $okCount, $failed, $plan.Count)
    if ($failed -gt 0) {
        Write-Host 'activate-global: activationStatus=failed'
        Write-Host 'activate-global: FAIL'
        exit 1
    }
    Write-Host 'activate-global: activationStatus=preview'
    Write-Host 'activate-global: PASS'
    exit 0
}

# ---------------------------------------------------------------------------
# APPLY: preflight ALL selected surfaces first (no writes); if any fails, write nothing.
# ---------------------------------------------------------------------------
$preflightFailed = 0
foreach ($item in $plan) {
    Write-Host ('activate-global: [{0}] PREFLIGHT via {1}...' -f $item.Name, $(if ($item.Class -eq 'managed-block') { 'apply-managed-block --DryRun' } else { 'canonical-overwrite dry-run' }))
    $pr = if ($item.Class -eq 'managed-block') {
        script:Invoke-ManagedBlockSurface -Surface $item   # dry-run (no -Apply)
    }
    else {
        script:Invoke-SkillMirrorSurface -Surface $item     # dry-run (no -Apply)
    }
    if (-not $pr.Ok) { $preflightFailed++ }
}
if ($preflightFailed -gt 0) {
    Write-Host ('activate-global: SUMMARY preflight failed ({0} of {1} surface(s) invalid); no file written' -f $preflightFailed, $plan.Count)
    Write-Host 'activate-global: activationStatus=failed'
    Write-Host 'activate-global: FAIL'
    exit 1
}

# Optional interactive two-choice confirmation (direct-terminal use). Default OFF: the explicit
# -Apply invocation is the command-implied approval. NO multi-choice menu; NO auto-yes.
if ($ConfirmInteractive) {
    if (-not (script:Test-ActivateApprovalInteractive)) {
        Write-Host 'activate-global: FAIL -ConfirmInteractive requested but no interactive terminal is available; no mutation performed'
        Write-Host 'activate-global: activationStatus=activation_aborted_no_approval'
        Write-Host 'activate-global: FAIL'
        exit 1
    }
    $decision = script:Read-ActivateApproval -Prompt ('Apply activation to {0} surface(s) (scope {1})? This MODIFIES your global/user files.' -f $plan.Count, $Scope)
    if ($decision -ne 'yes') {
        Write-Host 'activate-global: aborted; activation approval not granted; no mutation performed'
        Write-Host 'activate-global: activationStatus=activation_aborted_no_approval'
        Write-Host 'activate-global: FAIL'
        exit 1
    }
}

# Apply each surface. Per-surface semantics; no cross-surface transaction.
$results = New-Object System.Collections.Generic.List[psobject]
foreach ($item in $plan) {
    Write-Host ('activate-global: [{0}] APPLY via {1}...' -f $item.Name, $(if ($item.Class -eq 'managed-block') { 'apply-managed-block' } else { 'canonical-overwrite' }))
    $r = if ($item.Class -eq 'managed-block') {
        script:Invoke-ManagedBlockSurface -Surface $item -Apply
    }
    else {
        script:Invoke-SkillMirrorSurface -Surface $item -Apply
    }
    Write-Host ('activate-global: surface name={0} class={1} action={2} verify={3}' -f $item.Name, $item.Class, $r.Action, $r.Verify)
    $results.Add($r)
}

# Final all-surface verify is the aggregate of each surface's own post-apply verification
# (managed-block: internal block==snippet check via apply-managed-block exit 0; canonical-overwrite:
# post-write SHA-256 identity). A write was attempted, so a residual mismatch is the reserved
# activation_applied_verify_failed status (INSTALL.md §13), distinct from a preflight 'failed'
# (which writes nothing).
$failed = @($results | Where-Object { -not $_.Ok }).Count
$okCount = $plan.Count - $failed
Write-Host ('activate-global: SUMMARY {0} ok / {1} failed (of {2})' -f $okCount, $failed, $plan.Count)
if ($failed -gt 0) {
    Write-Host 'activate-global: activationStatus=activation_applied_verify_failed'
    Write-Host 'activate-global: FAIL'
    exit 1
}
Write-Host 'activate-global: activationStatus=applied'
Write-Host 'activate-global: PASS'
exit 0
