Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Read-only uninstall target resolver (IU-B-08).
#
# Pure INSPECTION: it reads the filesystem to classify what the uninstall WOULD touch, and writes
# NOTHING (no deletion, no -Apply, no .amb-backup, no instruction-file mutation, no finalizer). This
# resolver is SHARED by both paths in scripts/uninstall-global.ps1: the default read-only dry-run and
# the destructive -Apply preflight. The destructive apply itself (managed-block removal via
# scripts/apply-managed-block.ps1 -Remove, skill-dir removal) and the install-root deletion
# (scripts/uninstall-finalizer.ps1) live in those scripts, not here.
#
# Dependencies are dot-sourced by the caller (scripts/uninstall-global.ps1 / the test harness):
#   lib/encoding.ps1              (Read-Utf8)
#   lib/path.ps1                  (Get-StableInstallAreaCandidate — default expected canonical install area)
#   lib/managed-block.ps1         (Split-ManagedBlockLines, Find-ManagedBlockMarkers, Resolve-ManagedBlockSpan)
#   lib/activation-surface.ps1    (Get-ActivationSurfacePlan — shared resolver; the SAME effective
#                                  Codex surface precedence that activation apply/verify uses)
#   lib/install-pipeline-core.ps1 (Read-InstallPipelineMetadata)
#
# Target status vocabulary (read-only classification of a hypothetical future apply):
#   absent     — nothing to remove (target not present / no managed block).
#   removable  — a future apply WOULD remove this (WouldRemove = $true).
#   blocked    — a future apply would REFUSE this target (unexpected content, malformed marker,
#                managed-install not confirmed); WouldRemove = $false, Blocked = $true.
#   warn       — detect-only signal (non-effective Codex stale marker); NOT a removal target.

# Expected top-level footprint of the install ROOT: the canonical persistent outputs (sibling of
# current/), plus the known-transient git-url work area (source-cache) and the reserved in-root
# run-evidence tree (log/install-update/). Anything else at the top level is unexpected.
$script:UninstallExpectedRootEntries       = @(
    'current', 'install.json', 'payload-manifest.json', 'payload-marker.json',
    'README.md', 'source-cache', 'log'
)
$script:UninstallKnownTransientRootEntries = @('source-cache')
$script:UninstallReservedRootEntries       = @('log')
$script:UninstallExpectedManagedBy         = 'claude-code'

function Get-UninstallExpectedRootEntries {
    # Single source of truth for the install-root top-level expected footprint allow-list. The
    # apply entrypoint passes this to the (self-contained) temp finalizer so the finalizer's
    # defensive unexpected-content re-check uses the SAME list — no re-hardcoding / drift.
    # Return WITHOUT a unary-comma wrapper: callers consume this via @(...), and `,$array` would
    # nest into a single-element array (the finalizer then saw one Object[] and flagged everything
    # as unexpected). Emitting the elements lets @() collect the full list.
    return $script:UninstallExpectedRootEntries
}

function script:Get-UninstallManagedBlockState {
    # Read-only managed-block surface classification. It mirrors the FULL set of pre-write gates that
    # the actual removal (apply-managed-block.ps1 -Remove) enforces, so every statically-detectable
    # unsafe state is caught HERE in preflight (and blocks the whole apply) instead of failing mid-
    # sequence into a partial mutation:
    #   - file absent                                  -> absent
    #   - pre-existing <file>.amb-backup               -> blocked (apply-managed-block refuses it)
    #   - UTF-8 BOM on the target                      -> blocked (apply-managed-block refuses it)
    #   - U+FFFD corruption sentinel in the content    -> blocked (apply-managed-block refuses it)
    #   - 0 marker pairs                               -> absent (nothing to remove; file untouched)
    #   - exactly 1 ordered pair                       -> removable
    #   - 2+ / incomplete / ordering / malformed fence -> blocked
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)] [string] $Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return [pscustomobject]@{ Status = 'absent'; Reason = 'instruction file absent (no managed block to remove)'; WouldRemove = $false; Blocked = $false }
    }
    # Pre-write-gate parity with apply-managed-block.ps1 (these would each make the child -Remove fail,
    # so they are blocked in preflight rather than allowed to produce a partial sequential mutation).
    $ambBackup = $Path + '.amb-backup'
    # Match apply-managed-block.ps1's refusal exactly: it refuses ANY existing path at this sidecar
    # location (Test-Path without -PathType — a file OR a directory), so the preflight must too, or a
    # `.amb-backup` directory would pass here and then fail the child apply mid-sequence.
    if (Test-Path -LiteralPath $ambBackup) {
        return [pscustomobject]@{ Status = 'blocked'; Reason = ('pre-existing .amb-backup at ' + $ambBackup + ' (a prior managed-block apply did not close cleanly) — resolve before uninstall'); WouldRemove = $false; Blocked = $true }
    }
    try {
        $bytes = [System.IO.File]::ReadAllBytes($Path)
        if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
            return [pscustomobject]@{ Status = 'blocked'; Reason = 'target has a UTF-8 BOM (apply-managed-block -Remove requires UTF-8 without BOM)'; WouldRemove = $false; Blocked = $true }
        }
    }
    catch {
        return [pscustomobject]@{ Status = 'blocked'; Reason = ('read error (byte probe): ' + $_.Exception.Message); WouldRemove = $false; Blocked = $true }
    }
    try {
        $text = Read-Utf8 -Path $Path
        if (-not [string]::IsNullOrEmpty($text) -and $text.Contains([char]0xFFFD)) {
            return [pscustomobject]@{ Status = 'blocked'; Reason = 'U+FFFD corruption sentinel present (apply-managed-block -Remove refuses already-corrupted input)'; WouldRemove = $false; Blocked = $true }
        }
        $segments = @(Split-ManagedBlockLines -Content $text)
        $scan = Find-ManagedBlockMarkers -Segments $segments
        $nb = $scan.BeginIndices.Count
        $ne = $scan.EndIndices.Count
        if ($nb -eq 0 -and $ne -eq 0) {
            return [pscustomobject]@{ Status = 'absent'; Reason = '0 marker pairs (file present, nothing to remove; file would be left untouched)'; WouldRemove = $false; Blocked = $false }
        }
        try {
            [void] (Resolve-ManagedBlockSpan -Segments $segments -Label 'destination')
            return [pscustomobject]@{ Status = 'removable'; Reason = 'exactly 1 marker pair (marker span would be excised; marker-outside content preserved)'; WouldRemove = $true; Blocked = $false }
        }
        catch {
            return [pscustomobject]@{ Status = 'blocked'; Reason = ('marker pair not exactly 1 / ordering / malformed: ' + $_.Exception.Message); WouldRemove = $false; Blocked = $true }
        }
    }
    catch {
        return [pscustomobject]@{ Status = 'blocked'; Reason = ('read / structure error: ' + $_.Exception.Message); WouldRemove = $false; Blocked = $true }
    }
}

function script:Test-UninstallMarkerPresence {
    # Read-only: $true if the file exists and contains >= 1 BEGIN or END marker line (fenced-aware
    # count). Used ONLY for the non-effective Codex detect-warn — never to promote a removal target.
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)] [string] $Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $false }
    try {
        $segments = @(Split-ManagedBlockLines -Content (Read-Utf8 -Path $Path))
        $scan = Find-ManagedBlockMarkers -Segments $segments
        return (($scan.BeginIndices.Count + $scan.EndIndices.Count) -gt 0)
    }
    catch {
        # An unbalanced fence / structural anomaly still means there is marker-relevant content
        # worth warning about (detect-warn is conservative).
        return $true
    }
}

function Get-UninstallPlan {
    # Resolve the read-only uninstall plan: install-root footprint enumeration + managed-block
    # surfaces + skill mirror + non-effective Codex detect-warn. Returns a structured plan; writes
    # nothing. ClaudeHome / CodexHome are overridable so tests never touch the real %USERPROFILE%.
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)] [string] $InstallArea,
        [Parameter(Mandatory = $true)] [string] $ClaudeHome,
        [Parameter(Mandatory = $true)] [string] $CodexHome,
        # Expected canonical install area for the destructive-op path guard. Production callers leave
        # this empty so it resolves to Get-StableInstallAreaCandidate (the vendor-neutral
        # %USERPROFILE%\ai-harness-toolset); tests inject a controlled path for deterministic
        # isolation. The guard is exact-path equality, NOT a parent-name shape — it does not depend
        # on the install area sitting under .claude.
        [string] $ExpectedInstallArea
    )

    $targets = New-Object System.Collections.Generic.List[psobject]
    $installAreaFull = [System.IO.Path]::GetFullPath($InstallArea)

    # ---- install root footprint (read-only) -------------------------------------------------
    $rootPresent = Test-Path -LiteralPath $installAreaFull -PathType Container

    # Destructive-op path-guard EVIDENCE (recorded, not a dry-run hard block): the future apply
    # requires the install root to be EXACTLY the expected canonical install area
    # (Get-StableInstallAreaCandidate by default; injectable for tests). Exact-path equality
    # replaces the former leaf=='ai-harness-toolset' AND parent=='.claude' shape check so the guard
    # is vendor-neutral and pins the one canonical location rather than any */ai-harness-toolset under
    # any */.claude. Tests inject -ExpectedInstallArea to match their TestDrive area; the destructive
    # batch enforces this evidence.
    if ([string]::IsNullOrEmpty($ExpectedInstallArea)) {
        $ExpectedInstallArea = Get-StableInstallAreaCandidate
    }
    $expectedLocation = $false
    if (-not [string]::IsNullOrEmpty($ExpectedInstallArea)) {
        $expectedAreaFull = [System.IO.Path]::GetFullPath($ExpectedInstallArea)
        $sep = [System.IO.Path]::DirectorySeparatorChar
        $cmp = [System.StringComparison]::OrdinalIgnoreCase
        $expectedLocation = [string]::Equals($installAreaFull.TrimEnd($sep), $expectedAreaFull.TrimEnd($sep), $cmp)
    }

    $managedBy   = $null
    $managedByOk = $false

    if (-not $rootPresent) {
        $targets.Add([pscustomobject]@{ Name = 'install-root'; Kind = 'install-root'; Path = $installAreaFull; Status = 'absent'; Reason = 'install root directory absent (nothing to remove)'; WouldRemove = $false; Blocked = $false })
    }
    else {
        $mdReason = $null
        try {
            $md = Read-InstallPipelineMetadata -InstallArea $installAreaFull
            if ($null -eq $md) {
                $mdReason = 'install.json absent (cannot confirm managed install)'
            }
            else {
                $names = @($md.PSObject.Properties.Name)
                if ($names -ccontains 'managedBy') { $managedBy = [string]$md.managedBy }
                if ($managedBy -eq $script:UninstallExpectedManagedBy) {
                    $managedByOk = $true
                }
                else {
                    $mdReason = ("managedBy != '{0}' (got '{1}')" -f $script:UninstallExpectedManagedBy, $managedBy)
                }
            }
        }
        catch {
            $mdReason = ('install.json read error: ' + $_.Exception.Message)
        }

        $entries = @(Get-ChildItem -LiteralPath $installAreaFull -Force)
        $hasUnexpected = $false
        foreach ($e in $entries) {
            $isExpected  = ($script:UninstallExpectedRootEntries       -icontains $e.Name)
            $isTransient = ($script:UninstallKnownTransientRootEntries -icontains $e.Name)
            $isReserved  = ($script:UninstallReservedRootEntries       -icontains $e.Name)
            if ($isExpected) {
                $baseReason = if ($isTransient) { 'expected footprint (known transient git-url work area)' }
                              elseif ($isReserved) { 'expected footprint (reserved in-root run-evidence tree)' }
                              else { 'expected footprint (canonical install output)' }
                # Per-target Status is kept consistent with WouldRemove: an entry is only 'removable'
                # when the managed install is confirmed (managedByOk). When it is not, the whole root
                # is refused (the install-root target carries the managedBy reason), so each expected
                # entry is 'blocked' (WouldRemove=$false) rather than a contradictory removable/false.
                if ($managedByOk) {
                    $targets.Add([pscustomobject]@{ Name = $e.Name; Kind = 'install-root-entry'; Path = $e.FullName; Status = 'removable'; Reason = ($baseReason + '; would be removed with the install root'); WouldRemove = $true; Blocked = $false; KnownTransient = $isTransient })
                }
                else {
                    $targets.Add([pscustomobject]@{ Name = $e.Name; Kind = 'install-root-entry'; Path = $e.FullName; Status = 'blocked'; Reason = ($baseReason + '; but the managed install is NOT confirmed (see the install-root target) — would NOT be removed'); WouldRemove = $false; Blocked = $true; KnownTransient = $isTransient })
                }
            }
            else {
                $hasUnexpected = $true
                $targets.Add([pscustomobject]@{ Name = $e.Name; Kind = 'install-root-entry'; Path = $e.FullName; Status = 'blocked'; Reason = 'unexpected top-level content (NOT in the expected footprint; would NOT be removed — resolve manually)'; WouldRemove = $false; Blocked = $true; KnownTransient = $false })
            }
        }

        if (-not $managedByOk) {
            $targets.Add([pscustomobject]@{ Name = 'install-root'; Kind = 'install-root'; Path = $installAreaFull; Status = 'blocked'; Reason = ('managed install not confirmed — ' + $mdReason + '; install root NOT proposed for removal'); WouldRemove = $false; Blocked = $true })
        }
        elseif ($hasUnexpected) {
            $targets.Add([pscustomobject]@{ Name = 'install-root'; Kind = 'install-root'; Path = $installAreaFull; Status = 'blocked'; Reason = 'unexpected top-level content present (see blocked entries); install root NOT proposed for removal'; WouldRemove = $false; Blocked = $true })
        }
        else {
            $targets.Add([pscustomobject]@{ Name = 'install-root'; Kind = 'install-root'; Path = $installAreaFull; Status = 'removable'; Reason = "managed install confirmed (managedBy='claude-code'); footprint matches the expected set"; WouldRemove = $true; Blocked = $false })
        }
    }

    # ---- activation surfaces (managed-block) + skill mirrors (read-only) ----------------------
    # OWNED skill inventory comes from the INSTALLED payload (current/snippets/claude-skills/*), so the
    # resolver is given the install area's current/ as PayloadRoot — NOT the install root. With generic
    # skill enumeration the surface SET depends on PayloadRoot, so passing the install root (which has
    # no snippets/ directly) would enumerate ZERO skills and ORPHAN owned skill dirs. Enumerating from
    # current/ means uninstall reclaims exactly the skills this install shipped; skills present under
    # <ClaudeHome>/skills/ that are NOT in the payload (sibling skills) are never enumerated → preserved.
    # (The managed-block surfaces' DESTINATIONS do not depend on PayloadRoot.)
    $currentDir = Join-Path $installAreaFull 'current'
    $skillInventoryRoot = Join-Path $currentDir 'snippets/claude-skills'
    $surfaces = Get-ActivationSurfacePlan -PayloadRoot $currentDir -ClaudeHome $ClaudeHome -CodexHome $CodexHome
    # Owned-skill inventory trust guard: a healthy install always ships >= 1 source skill, so if the
    # install root is present and WOULD be removed (managed install confirmed) but the resolver
    # enumerates ZERO owned skills from the installed payload — for ANY reason: current/ itself,
    # current/snippets/, or current/snippets/claude-skills/ missing; that directory empty; or every
    # candidate dir lacking a SKILL.md — the OWNED skill set cannot be trusted. Removing the install
    # root while cleaning up zero skills would ORPHAN owned runtime skill dirs under <ClaudeHome>/skills/
    # (footprint-zero violation). Refuse rather than risk an orphan. (Treating an unenumerable inventory
    # as a legitimate zero-skill payload would need explicit manifest-backed evidence, which uninstall
    # does not consult — so the safe, recoverable choice is to block and report.)
    $ownedSkillCount = @($surfaces | Where-Object { $_.Class -eq 'canonical-overwrite' }).Count
    if ($rootPresent -and $managedByOk -and $ownedSkillCount -eq 0) {
        $targets.Add([pscustomobject]@{ Name = 'skill-inventory'; Kind = 'skill-inventory'; Path = $skillInventoryRoot; Status = 'blocked'; Reason = 'the installed payload (current/snippets/claude-skills/) yields ZERO owned skills (absent / empty / no SKILL.md), so the OWNED skill set cannot be trusted; refusing to avoid orphaning owned runtime skill dirs under skills/ — resolve manually'; WouldRemove = $false; Blocked = $true })
    }
    foreach ($s in $surfaces) {
        if ($s.Class -eq 'managed-block') {
            $st = script:Get-UninstallManagedBlockState -Path $s.Destination
            $targets.Add([pscustomobject]@{ Name = $s.Name; Kind = 'managed-block'; Path = ([System.IO.Path]::GetFullPath($s.Destination)); Status = $st.Status; Reason = $st.Reason; WouldRemove = $st.WouldRemove; Blocked = $st.Blocked })
        }
        elseif ($s.Class -eq 'canonical-overwrite') {
            # Owned skill mirror: existence + expected-path guard only (read-only). The expected leaf is
            # the surface's own SkillName (NOT a hardcoded skill), so each owned skill is classified
            # against its own skills/<name>/ directory.
            $skillName = $s.SkillName
            $dstFull = [System.IO.Path]::GetFullPath($s.Destination)
            $sleaf  = Split-Path -Leaf $dstFull
            $sparent = Split-Path -Leaf (Split-Path -Parent $dstFull)
            $sgrand  = Split-Path -Leaf (Split-Path -Parent (Split-Path -Parent $dstFull))
            $pathOk = ($sleaf -ieq 'SKILL.md' -and $sparent -ieq $skillName -and $sgrand -ieq 'skills')
            # The removal TARGET is the skill DIRECTORY (the skill-removal rule deletes the <name>/ dir),
            # so Path reports that directory; presence is DETECTED via the canonical SKILL.md artifact
            # inside it. (Reported Path == the thing a future apply removes, so the dry-run plan the
            # apply batch consumes is unambiguous.)
            $skillDir = Split-Path -Parent $dstFull
            # Footprint-zero requires the skill DIRECTORY to be absent, so presence is keyed on the
            # DIRECTORY existing — NOT on SKILL.md. A skills/<name>/ dir that exists without SKILL.md
            # (e.g. a partially-removed mirror) is still removable; otherwise the dir would survive a
            # "successful" uninstall and break footprint-zero.
            if (-not $pathOk) {
                $targets.Add([pscustomobject]@{ Name = $s.Name; Kind = 'skill-mirror'; Path = $dstFull; Status = 'blocked'; Reason = ('unexpected skill-mirror path shape (expected skills/{0}/SKILL.md); NOT proposed for removal' -f $skillName); WouldRemove = $false; Blocked = $true; SkillName = $skillName })
            }
            elseif (Test-Path -LiteralPath $skillDir -PathType Container) {
                $hasSkillMd = Test-Path -LiteralPath $dstFull -PathType Leaf
                $reason = if ($hasSkillMd) { ('{0} skill dir present (with SKILL.md); the skill DIRECTORY would be removed' -f $skillName) }
                          else { ('{0} skill dir present (WITHOUT SKILL.md — partial mirror); the skill DIRECTORY would still be removed for footprint-zero' -f $skillName) }
                $targets.Add([pscustomobject]@{ Name = $s.Name; Kind = 'skill-mirror'; Path = $skillDir; Status = 'removable'; Reason = $reason; WouldRemove = $true; Blocked = $false; SkillName = $skillName })
            }
            else {
                $targets.Add([pscustomobject]@{ Name = $s.Name; Kind = 'skill-mirror'; Path = $skillDir; Status = 'absent'; Reason = ('skill mirror directory absent ({0})' -f $skillDir); WouldRemove = $false; Blocked = $false; SkillName = $skillName })
            }
        }
    }

    # ---- non-effective Codex stale-marker detect-warn (read-only) ----------------------------
    $codexAgents   = [System.IO.Path]::GetFullPath((Join-Path $CodexHome 'AGENTS.md'))
    $codexOverride = [System.IO.Path]::GetFullPath((Join-Path $CodexHome 'AGENTS.override.md'))
    $effectiveCodex    = if (Test-Path -LiteralPath $codexOverride -PathType Leaf) { $codexOverride } else { $codexAgents }
    $nonEffectiveCodex = if ($effectiveCodex -eq $codexOverride) { $codexAgents } else { $codexOverride }
    if (script:Test-UninstallMarkerPresence -Path $nonEffectiveCodex) {
        $targets.Add([pscustomobject]@{ Name = 'codex-non-effective-stale-marker'; Kind = 'codex-non-effective'; Path = $nonEffectiveCodex; Status = 'warn'; Reason = 'stale managed-block marker in a NON-effective Codex file; detect-warn only (NOT removed, NOT promoted to a removal target)'; WouldRemove = $false; Blocked = $false })
    }

    $blockedCount = @($targets | Where-Object { $_.Blocked }).Count
    $overall = if ($blockedCount -gt 0) { 'uninstall_blocked' } else { 'uninstall_preview' }

    return [pscustomobject]@{
        InstallAreaPath    = $installAreaFull
        InstallRootPresent = $rootPresent
        ManagedBy          = $managedBy
        ManagedByOk        = $managedByOk
        ExpectedLocation   = $expectedLocation
        Targets            = $targets.ToArray()
        OverallStatus      = $overall
    }
}
