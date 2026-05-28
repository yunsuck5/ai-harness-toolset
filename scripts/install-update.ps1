[CmdletBinding()]
param(
    # inspect / verify are READ-ONLY (no mutation, no approval). update-source is the mutation
    # mode (INSTALL.md §7.1.1 / §13): it rewrites the InstallArea payload + metadata under
    # command-implied approval (the explicit update-source invocation on an existing valid
    # install is the approval), gated by the hard guards; -ConfirmInteractive optionally adds
    # the two-choice terminal selector. Not Mandatory so the script can be dot-sourced for
    # testing without prompting; Invoke-Main enforces -Mode / -InstallArea for real invocations.
    [ValidateSet('inspect', 'verify', 'update-source')]
    [string] $Mode,

    [string] $InstallArea,

    [string] $SourcePath,
    [string] $RepoUrl,
    [string] $Branch,
    [string] $Remote,
    [string] $Ref,

    [string] $ClaudeHome,
    [string] $CodexHome,

    [switch] $SkipSmoke,
    # Optional: require an interactive two-choice (Yes/No) confirmation before update-source
    # mutates (direct-terminal use). Default OFF — update-source uses command-implied approval
    # (the explicit invocation is the approval). With -ConfirmInteractive set but no interactive
    # terminal available, update-source aborts (it does not silently fall through to apply).
    [switch] $ConfirmInteractive,
    [switch] $Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# install/update operator entrypoint (post-MVP hardening). See INSTALL.md §7.1, §11 (b),
# and §13 for the operative contract codified by this script.
#
# Modes:
#   - inspect  : READ-ONLY. Classify install state vs source + activation byte-identity.
#   - verify   : READ-ONLY. Canonical schema/manifest/marker/cross-binding + activation.
#   - update-source : APPROVAL-GATED MUTATION. Rewrites the InstallArea payload + metadata
#                     via the canonical pipeline (New-InstallPipelineTuple action=update-source
#                     → Invoke-InstallPipelineDispatch), preserving installedHead/installedAt and
#                     updating lastUpdatedHead/lastUpdatedAt, then post-apply verify + activation
#                     byte-identity + cleanup + optional operational smoke.
#
# Mutation invariant:
#   - inspect / verify never write any file (stdout/stderr only).
#   - update-source mutates ONLY the supplied -InstallArea payload (current/ + install.json +
#     payload-manifest.json + payload-marker.json). It does NOT write activation surfaces
#     (managed blocks / skill mirror) — those are VERIFIED by byte-identity, not applied here
#     (managed-block / skill apply is scripts/activate-global.ps1 + scripts/apply-managed-block.ps1,
#     a separate explicit step). It writes no run.json global file (INSTALL.md §13.4 contract-only).
#   - update-source uses COMMAND-IMPLIED approval (INSTALL.md §7.1.1 / §13.8): the operator's
#     explicit update-source invocation on an existing identity-consistent install is the approval,
#     so a normal noninteractive Claude Code shell is not blocked. The hard guards still gate the
#     mutation (source-cut / missing-or-invalid metadata / missing source identity / unresolved
#     HEAD → failed, no mutation). The interactive two-choice (Yes/No) selector is an OPTIONAL
#     secondary path (-ConfirmInteractive) for direct-terminal use; it is not the mandatory gate,
#     and with -ConfirmInteractive but no terminal the run aborts rather than auto-applying.
#     command-implied approval applies ONLY to update-source of an existing install — never to
#     fresh install, new destination creation, activation apply, or a source-cut override.
#   - The legacy installer/framework/rollback/wizard/package-manager/daemon classes remain out of
#     scope (INSTALL.md §11 (a)); this is a deterministic narrow entrypoint (INSTALL.md §11 (b)).
#
# Install source-of-truth is the install.json / payload-manifest.json / payload-marker.json
# cross-binding (INSTALL.md §4); run evidence is evidence only.

. (Join-Path $PSScriptRoot 'lib/encoding.ps1')
. (Join-Path $PSScriptRoot 'lib/hash.ps1')
. (Join-Path $PSScriptRoot 'lib/git.ps1')
. (Join-Path $PSScriptRoot 'lib/path.ps1')
. (Join-Path $PSScriptRoot 'lib/managed-block.ps1')
. (Join-Path $PSScriptRoot 'lib/install-pipeline-core.ps1')
. (Join-Path $PSScriptRoot 'lib/native-process.ps1')

# Resolve activation surface home defaults (overridable so tests can point at
# TestDrive without touching the real user-global instruction roots).
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
# Production guard — the mutation surface is the explicit `update-source` mode only
# (command-implied approval; optionally gated by -ConfirmInteractive). There is NO mutation
# FLAG; this guard fail-fasts if a future mutation flag is wired in without explicit handling
# here, so a stray flag can never trigger a mutation the entrypoint did not intend. Exercised
# by the Pester regression suite so a regression that drops the throw is caught at source review.
# ---------------------------------------------------------------------------
function script:Assert-NoMutationPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Mode,
        [hashtable] $RequestedFlags = @{}
    )
    # These names are reserved future mutation FLAGS that are intentionally NOT implemented.
    # update-source is a MODE (handled with approval), not a flag, so it is not listed here.
    $mutationFlags = @('ApplyActivation', 'ApplyPayload', 'RefreshSkill')
    foreach ($flag in $mutationFlags) {
        if ($RequestedFlags.ContainsKey($flag) -and $RequestedFlags[$flag]) {
            throw "install-update: FAIL mutation flag '$flag' is not allowed (use -Mode update-source with explicit approval)."
        }
    }
}

# ---------------------------------------------------------------------------
# Path / source-of-truth resolution helpers.
# ---------------------------------------------------------------------------

function script:Get-ActivationSurfacePaths {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)] [string] $InstallArea,
        [Parameter(Mandatory = $true)] [string] $ClaudeHome,
        [Parameter(Mandatory = $true)] [string] $CodexHome
    )

    $currentDir = Get-InstallPipelineCurrentDir -InstallArea $InstallArea
    $sourceClaudeSnippet = Join-Path $currentDir 'snippets/CLAUDE_SNIPPET.md'
    $sourceCodexSnippet  = Join-Path $currentDir 'snippets/AGENTS_SNIPPET.md'
    $sourceSkillFile     = Join-Path $currentDir 'snippets/claude-skills/ai-harness-review/SKILL.md'

    $destClaudeMd  = Join-Path $ClaudeHome 'CLAUDE.md'
    $destSkillFile = Join-Path $ClaudeHome 'skills/ai-harness-review/SKILL.md'

    # Codex effective destination: AGENTS.override.md takes precedence over AGENTS.md
    # when present (INSTALL.md §10 valid-destination rule + AGENTS snippet adoption
    # destination). Verifying only AGENTS.md would let a stale/malformed override file
    # pass as clean, so the activation surface binds to whichever is effective.
    $codexAgentsMd  = Join-Path $CodexHome 'AGENTS.md'
    $codexOverride  = Join-Path $CodexHome 'AGENTS.override.md'
    $destCodexMd    = if (Test-Path -LiteralPath $codexOverride -PathType Leaf) { $codexOverride } else { $codexAgentsMd }

    return [pscustomobject]@{
        Surfaces = @(
            [pscustomobject]@{
                Name        = 'claude-user-global-managed-block'
                Destination = $destClaudeMd
                Source      = $sourceClaudeSnippet
                CompareMode = 'managed-block'
            },
            [pscustomobject]@{
                Name        = 'codex-user-global-managed-block'
                Destination = $destCodexMd
                Source      = $sourceCodexSnippet
                CompareMode = 'managed-block'
            },
            [pscustomobject]@{
                Name        = 'review-skill-mirror'
                Destination = $destSkillFile
                Source      = $sourceSkillFile
                CompareMode = 'whole-file'
            }
        )
    }
}

function script:Test-ActivationSurface {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)] [pscustomobject] $Surface
    )

    $name = $Surface.Name
    $dest = $Surface.Destination
    $src  = $Surface.Source
    $mode = $Surface.CompareMode

    if (-not (Test-Path -LiteralPath $dest -PathType Leaf)) {
        return [pscustomobject]@{
            Name          = $name
            Path          = $dest
            Exists        = $false
            ByteIdentical = $false
            Reason        = 'absent'
        }
    }
    if (-not (Test-Path -LiteralPath $src -PathType Leaf)) {
        return [pscustomobject]@{
            Name          = $name
            Path          = $dest
            Exists        = $true
            ByteIdentical = $false
            Reason        = ('read-error: source payload absent: ' + $src)
        }
    }

    try {
        if ($mode -eq 'managed-block') {
            $destText  = Read-Utf8 -Path $dest
            $srcText   = Read-Utf8 -Path $src
            $destBlock = Get-ManagedBlockContent -Content $destText -Label 'destination'
            $srcBlock  = Get-ManagedBlockContent -Content $srcText  -Label 'source-snippet'

            if ($destBlock.Count -ne $srcBlock.Count) {
                return [pscustomobject]@{
                    Name          = $name
                    Path          = $dest
                    Exists        = $true
                    ByteIdentical = $false
                    Reason        = ('byte-mismatch: line count differs ({0} vs {1})' -f $destBlock.Count, $srcBlock.Count)
                }
            }
            for ($i = 0; $i -lt $destBlock.Count; $i++) {
                if ($destBlock[$i] -cne $srcBlock[$i]) {
                    return [pscustomobject]@{
                        Name          = $name
                        Path          = $dest
                        Exists        = $true
                        ByteIdentical = $false
                        Reason        = ('byte-mismatch: line {0} differs' -f ($i + 1))
                    }
                }
            }
            return [pscustomobject]@{
                Name          = $name
                Path          = $dest
                Exists        = $true
                ByteIdentical = $true
                Reason        = $null
            }
        }
        elseif ($mode -eq 'whole-file') {
            $destSha = Get-FileSha256 -Path $dest
            $srcSha  = Get-FileSha256 -Path $src
            if ($destSha -ne $srcSha) {
                return [pscustomobject]@{
                    Name          = $name
                    Path          = $dest
                    Exists        = $true
                    ByteIdentical = $false
                    Reason        = ('byte-mismatch: sha256 differs ({0} vs {1})' -f $destSha, $srcSha)
                }
            }
            return [pscustomobject]@{
                Name          = $name
                Path          = $dest
                Exists        = $true
                ByteIdentical = $true
                Reason        = $null
            }
        }
        else {
            return [pscustomobject]@{
                Name          = $name
                Path          = $dest
                Exists        = $true
                ByteIdentical = $false
                Reason        = ('read-error: unknown CompareMode: ' + $mode)
            }
        }
    }
    catch {
        return [pscustomobject]@{
            Name          = $name
            Path          = $dest
            Exists        = $true
            ByteIdentical = $false
            Reason        = ('read-error: ' + $_.Exception.Message)
        }
    }
}

function script:Test-MetadataSchemaOk {
    # Focused install.json schema check for inspect-mode classification (INSTALL.md §13.1:
    # schema mismatch → inspect_mode_unknown). This validates the 14-field set + the constant
    # / mode-conditional value rules using the canonical field-set + constants dot-sourced from
    # install-pipeline-core.ps1. It is metadata-schema validation only — it does not duplicate
    # apply-managed-block.ps1 / activate-global.ps1 logic, and verify mode still runs the full
    # canonical Invoke-InstallPipelineVerify (manifest digest + marker + cross-binding).
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)] [psobject] $Metadata,
        [System.Collections.Generic.List[string]] $Reasons
    )

    $ok = $true
    $actualFields = @($Metadata.PSObject.Properties.Name)
    $expected = $script:InstallPipelineMetadataFields
    foreach ($f in $expected) {
        if ($actualFields -cnotcontains $f) { $Reasons.Add("metadata missing required field: $f"); $ok = $false }
    }
    foreach ($f in $actualFields) {
        if ($expected -cnotcontains $f) { $Reasons.Add("metadata has unexpected field: $f"); $ok = $false }
    }
    # Do not read values until the field set is structurally complete (StrictMode-safe).
    if (-not $ok) { return $false }

    if ($Metadata.tool -ne $script:InstallPipelineTool) {
        $Reasons.Add("metadata.tool mismatch: $($Metadata.tool)"); $ok = $false
    }
    if (@('git-url', 'local-clone') -notcontains $Metadata.installMode) {
        $Reasons.Add("metadata.installMode invalid: $($Metadata.installMode)"); $ok = $false
    }
    if ($Metadata.targetFootprintPolicy -ne $script:InstallPipelineFootprint) {
        $Reasons.Add("metadata.targetFootprintPolicy mismatch: $($Metadata.targetFootprintPolicy)"); $ok = $false
    }
    if ($Metadata.managedBy -ne $script:InstallPipelineManagedBy) {
        $Reasons.Add("metadata.managedBy mismatch: $($Metadata.managedBy)"); $ok = $false
    }
    foreach ($shaField in @('installedHead', 'lastUpdatedHead')) {
        $v = [string]$Metadata.$shaField
        if ([string]::IsNullOrEmpty($v) -or ($v -notmatch '^[0-9a-f]{40}$')) {
            $Reasons.Add("metadata.$shaField is not a 40-hex sha: $v"); $ok = $false
        }
    }
    # Mode-conditional source-identity fields — full INSTALL.md §4 / §5 schema rule
    # (both the non-empty requirement AND the complementary must-be-empty requirement),
    # so a schema-mismatched install.json is classified inspect_mode_unknown rather than
    # proceeding to payload/source classification.
    if ($Metadata.installMode -eq 'git-url') {
        if ([string]::IsNullOrEmpty([string]$Metadata.repoUrl))        { $Reasons.Add('metadata.repoUrl empty for git-url mode'); $ok = $false }
        if (-not [string]::IsNullOrEmpty([string]$Metadata.sourcePath)) { $Reasons.Add('metadata.sourcePath must be empty for git-url mode'); $ok = $false }
        if (-not [string]::IsNullOrEmpty([string]$Metadata.toolRoot))   { $Reasons.Add('metadata.toolRoot must be empty for git-url mode'); $ok = $false }
    }
    elseif ($Metadata.installMode -eq 'local-clone') {
        if ([string]::IsNullOrEmpty([string]$Metadata.sourcePath))     { $Reasons.Add('metadata.sourcePath empty for local-clone mode'); $ok = $false }
        if ([string]::IsNullOrEmpty([string]$Metadata.toolRoot))       { $Reasons.Add('metadata.toolRoot empty for local-clone mode'); $ok = $false }
        if (-not [string]::IsNullOrEmpty([string]$Metadata.repoUrl))    { $Reasons.Add('metadata.repoUrl must be empty for local-clone mode'); $ok = $false }
    }
    return $ok
}

function script:Resolve-SourceHead {
    [CmdletBinding()]
    param(
        [psobject] $Metadata,
        [string] $SourcePath,
        [string] $RepoUrl,
        [string] $Branch,
        [string] $Ref
    )

    # Argument > metadata-derived. If neither is available, return null with reason.
    $useLocal = $false
    $localPath = $null
    $useUrl = $false
    $urlValue = $null

    if (-not [string]::IsNullOrEmpty($SourcePath)) {
        $useLocal = $true
        $localPath = $SourcePath
    }
    elseif (-not [string]::IsNullOrEmpty($RepoUrl)) {
        $useUrl = $true
        $urlValue = $RepoUrl
    }
    elseif ($null -ne $Metadata) {
        $mdMode = $null
        if (@($Metadata.PSObject.Properties.Name) -ccontains 'installMode') {
            $mdMode = [string]$Metadata.installMode
        }
        if ($mdMode -eq 'local-clone' -and (@($Metadata.PSObject.Properties.Name) -ccontains 'sourcePath')) {
            $mdSrc = [string]$Metadata.sourcePath
            if (-not [string]::IsNullOrEmpty($mdSrc)) {
                $useLocal = $true
                $localPath = $mdSrc
            }
        }
        elseif ($mdMode -eq 'git-url' -and (@($Metadata.PSObject.Properties.Name) -ccontains 'repoUrl')) {
            $mdUrl = [string]$Metadata.repoUrl
            if (-not [string]::IsNullOrEmpty($mdUrl)) {
                $useUrl = $true
                $urlValue = $mdUrl
            }
        }
    }

    if ($useLocal) {
        if (-not (Test-Path -LiteralPath $localPath -PathType Container)) {
            return [pscustomobject]@{ Head = $null; Reason = ('local source path not found: ' + $localPath) }
        }
        $head = Get-GitHead -WorkingDirectory $localPath
        if ([string]::IsNullOrEmpty($head)) {
            return [pscustomobject]@{ Head = $null; Reason = ('git rev-parse HEAD failed at ' + $localPath) }
        }
        if ($head -notmatch '^[0-9a-f]{40}$') {
            return [pscustomobject]@{ Head = $null; Reason = ('local HEAD is not a 40-hex sha: ' + $head) }
        }
        return [pscustomobject]@{ Head = $head; Reason = $null }
    }
    elseif ($useUrl) {
        # ref precedence: explicit -Ref → explicit -Branch → install.json.branch → 'main' fallback.
        # Without metadata.branch derivation, a git-url install tracking a non-main branch would
        # be resolved against the wrong ref and falsely reported as drifted/clean (INSTALL.md §7.1
        # step 1 reads branch/remote from install.json).
        $refArg = $null
        if (-not [string]::IsNullOrEmpty($Ref)) {
            $refArg = $Ref
        }
        elseif (-not [string]::IsNullOrEmpty($Branch)) {
            $refArg = $Branch
        }
        elseif ($null -ne $Metadata -and (@($Metadata.PSObject.Properties.Name) -ccontains 'branch') -and -not [string]::IsNullOrEmpty([string]$Metadata.branch)) {
            $refArg = [string]$Metadata.branch
        }
        else {
            $refArg = 'main'
        }
        $result = Invoke-GitCapture -Arguments @('ls-remote', $urlValue, $refArg)
        if ($result.ExitCode -ne 0) {
            return [pscustomobject]@{ Head = $null; Reason = ('git ls-remote {0} {1} failed (exit {2})' -f $urlValue, $refArg, $result.ExitCode) }
        }
        $lines = @($result.StdOut -split "`r?`n" | Where-Object { -not [string]::IsNullOrEmpty($_) })
        if ($lines.Count -eq 0) {
            return [pscustomobject]@{ Head = $null; Reason = ('git ls-remote returned no refs for ' + $refArg) }
        }
        $firstSha = ($lines[0] -split "\s+")[0].Trim()
        if ($firstSha -notmatch '^[0-9a-f]{40}$') {
            return [pscustomobject]@{ Head = $null; Reason = ('git ls-remote returned non-sha first token: ' + $firstSha) }
        }
        return [pscustomobject]@{ Head = $firstSha; Reason = $null }
    }
    else {
        return [pscustomobject]@{ Head = $null; Reason = 'no source identity available (no -SourcePath/-RepoUrl, and install.json missing or installMode unknown)' }
    }
}

# ---------------------------------------------------------------------------
# Mode dispatch.
# ---------------------------------------------------------------------------

function script:Invoke-InspectMode {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)] [string] $InstallArea,
        [string] $ClaudeHome,
        [string] $CodexHome,
        [string] $SourcePath,
        [string] $RepoUrl,
        [string] $Branch,
        [string] $Remote,
        [string] $Ref
    )

    $reasons = New-Object System.Collections.Generic.List[string]
    $installAreaResolved = [System.IO.Path]::GetFullPath($InstallArea)

    # 1. install.json read + schema check (lenient — we only need basic shape here;
    #    full 14-field strictness lives in verify mode via Invoke-InstallPipelineVerify).
    $metadata = $null
    $installState = 'absent'
    $metadataValid = $false
    $installMode = $null
    $lastUpdatedHead = $null

    $metadataPath = Get-InstallPipelineMetadataPath -InstallArea $installAreaResolved
    if (-not (Test-Path -LiteralPath $metadataPath -PathType Leaf)) {
        $reasons.Add('install.json missing at ' + $metadataPath)
        return [pscustomobject]@{
            Status                       = 'inspect_mode_unknown'
            ExitCode                     = 0
            InstallAreaPath              = $installAreaResolved
            InstallState                 = $installState
            MetadataValid                = $false
            InstallMode                  = $null
            LastUpdatedHead              = $null
            SourceResolvedHead           = $null
            PayloadDeltaRequired         = $false
            ManifestMarkerCrossBindingOk = $false
            ActivationSurfaces           = @()
            Reasons                      = @($reasons)
        }
    }
    try {
        $metadata = Read-InstallPipelineMetadata -InstallArea $installAreaResolved
        $installState = 'present'
    }
    catch {
        $reasons.Add('install.json read failed: ' + $_.Exception.Message)
        return [pscustomobject]@{
            Status                       = 'inspect_mode_unknown'
            ExitCode                     = 0
            InstallAreaPath              = $installAreaResolved
            InstallState                 = 'partial'
            MetadataValid                = $false
            InstallMode                  = $null
            LastUpdatedHead              = $null
            SourceResolvedHead           = $null
            PayloadDeltaRequired         = $false
            ManifestMarkerCrossBindingOk = $false
            ActivationSurfaces           = @()
            Reasons                      = @($reasons)
        }
    }
    if ($null -eq $metadata) {
        $reasons.Add('install.json returned null')
        return [pscustomobject]@{
            Status                       = 'inspect_mode_unknown'
            ExitCode                     = 0
            InstallAreaPath              = $installAreaResolved
            InstallState                 = 'partial'
            MetadataValid                = $false
            InstallMode                  = $null
            LastUpdatedHead              = $null
            SourceResolvedHead           = $null
            PayloadDeltaRequired         = $false
            ManifestMarkerCrossBindingOk = $false
            ActivationSurfaces           = @()
            Reasons                      = @($reasons)
        }
    }
    # Schema mismatch → inspect_mode_unknown (INSTALL.md §13.1). The metadata reader only
    # checks schemaVersion; a missing / unexpected / invalid mode-conditional field must not
    # silently proceed to payload/source classification.
    $schemaReasons = New-Object System.Collections.Generic.List[string]
    if (-not (script:Test-MetadataSchemaOk -Metadata $metadata -Reasons $schemaReasons)) {
        foreach ($sr in $schemaReasons) { $reasons.Add($sr) }
        return [pscustomobject]@{
            Status                       = 'inspect_mode_unknown'
            ExitCode                     = 0
            InstallAreaPath              = $installAreaResolved
            InstallState                 = 'partial'
            MetadataValid                = $false
            InstallMode                  = $null
            LastUpdatedHead              = $null
            SourceResolvedHead           = $null
            PayloadDeltaRequired         = $false
            ManifestMarkerCrossBindingOk = $false
            ActivationSurfaces           = @()
            Reasons                      = @($reasons)
        }
    }
    $metadataValid = $true
    $installMode     = [string]$metadata.installMode
    $lastUpdatedHead = [string]$metadata.lastUpdatedHead

    # 2. manifest + marker presence + cross-binding (lenient — Invoke-InstallPipelineVerify
    #    does the strict version; here we only need to classify payload-drift).
    $manifestPath = Get-InstallPipelineManifestPath -InstallArea $installAreaResolved
    $markerPath   = Get-InstallPipelineMarkerPath   -InstallArea $installAreaResolved
    $manifest = $null
    $marker   = $null
    $payloadDrift = $false
    try {
        $manifest = Read-InstallPipelineManifest -InstallArea $installAreaResolved
    }
    catch {
        $reasons.Add('payload-manifest.json read failed: ' + $_.Exception.Message)
        $payloadDrift = $true
    }
    if ($null -eq $manifest -and -not $payloadDrift) {
        if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
            $reasons.Add('payload-manifest.json missing at ' + $manifestPath)
            $payloadDrift = $true
        }
    }
    try {
        $marker = Read-InstallPipelineMarker -InstallArea $installAreaResolved
    }
    catch {
        $reasons.Add('payload-marker.json read failed: ' + $_.Exception.Message)
        $payloadDrift = $true
    }
    if ($null -eq $marker -and -not $payloadDrift) {
        if (-not (Test-Path -LiteralPath $markerPath -PathType Leaf)) {
            $reasons.Add('payload-marker.json missing at ' + $markerPath)
            $payloadDrift = $true
        }
    }

    $manifestMarkerCrossBindingOk = $true
    if (-not $payloadDrift -and $null -ne $manifest -and $null -ne $marker) {
        $manHead = if (@($manifest.PSObject.Properties.Name) -ccontains 'head') { [string]$manifest.head } else { '' }
        $mrkHead = if (@($marker.PSObject.Properties.Name)   -ccontains 'head') { [string]$marker.head   } else { '' }
        if ($manHead -ne $mrkHead) {
            $reasons.Add(('cross-binding mismatch: manifest.head ({0}) != marker.head ({1})' -f $manHead, $mrkHead))
            $manifestMarkerCrossBindingOk = $false
            $payloadDrift = $true
        }
        elseif (-not [string]::IsNullOrEmpty($lastUpdatedHead) -and $manHead -ne $lastUpdatedHead) {
            $reasons.Add(('cross-binding mismatch: manifest.head ({0}) != install.json.lastUpdatedHead ({1})' -f $manHead, $lastUpdatedHead))
            $manifestMarkerCrossBindingOk = $false
            $payloadDrift = $true
        }
    }
    else {
        $manifestMarkerCrossBindingOk = $false
    }

    if ($payloadDrift) {
        return [pscustomobject]@{
            Status                       = 'inspect_payload_drift'
            ExitCode                     = 0
            InstallAreaPath              = $installAreaResolved
            InstallState                 = $installState
            MetadataValid                = $metadataValid
            InstallMode                  = $installMode
            LastUpdatedHead              = $lastUpdatedHead
            SourceResolvedHead           = $null
            PayloadDeltaRequired         = $false
            ManifestMarkerCrossBindingOk = $manifestMarkerCrossBindingOk
            ActivationSurfaces           = @()
            Reasons                      = @($reasons)
        }
    }

    # 3. source HEAD resolve + source-drift check.
    $srcResolved = script:Resolve-SourceHead -Metadata $metadata -SourcePath $SourcePath -RepoUrl $RepoUrl -Branch $Branch -Ref $Ref
    $sourceResolvedHead = $srcResolved.Head
    $payloadDeltaRequired = $false
    if ($null -eq $sourceResolvedHead) {
        $reasons.Add('source HEAD resolve failed: ' + $srcResolved.Reason)
        return [pscustomobject]@{
            Status                       = 'inspect_source_drift'
            ExitCode                     = 0
            InstallAreaPath              = $installAreaResolved
            InstallState                 = $installState
            MetadataValid                = $metadataValid
            InstallMode                  = $installMode
            LastUpdatedHead              = $lastUpdatedHead
            SourceResolvedHead           = $null
            PayloadDeltaRequired         = $true
            ManifestMarkerCrossBindingOk = $manifestMarkerCrossBindingOk
            ActivationSurfaces           = @()
            Reasons                      = @($reasons)
        }
    }
    if ($sourceResolvedHead -ne $lastUpdatedHead) {
        $payloadDeltaRequired = $true
        $reasons.Add(('source HEAD ({0}) differs from install.json.lastUpdatedHead ({1})' -f $sourceResolvedHead, $lastUpdatedHead))
        return [pscustomobject]@{
            Status                       = 'inspect_source_drift'
            ExitCode                     = 0
            InstallAreaPath              = $installAreaResolved
            InstallState                 = $installState
            MetadataValid                = $metadataValid
            InstallMode                  = $installMode
            LastUpdatedHead              = $lastUpdatedHead
            SourceResolvedHead           = $sourceResolvedHead
            PayloadDeltaRequired         = $true
            ManifestMarkerCrossBindingOk = $manifestMarkerCrossBindingOk
            ActivationSurfaces           = @()
            Reasons                      = @($reasons)
        }
    }

    # 4. activation surface byte-identity check (3 surfaces).
    $surfacesObj = script:Get-ActivationSurfacePaths -InstallArea $installAreaResolved -ClaudeHome $ClaudeHome -CodexHome $CodexHome
    $surfaceResults = @()
    $activationDrift = $false
    foreach ($s in $surfacesObj.Surfaces) {
        $r = script:Test-ActivationSurface -Surface $s
        $surfaceResults += $r
        if (-not $r.ByteIdentical) {
            $activationDrift = $true
            $reasons.Add(('activation surface drift: {0} ({1})' -f $r.Name, $r.Reason))
        }
    }

    if ($activationDrift) {
        return [pscustomobject]@{
            Status                       = 'inspect_activation_drift'
            ExitCode                     = 0
            InstallAreaPath              = $installAreaResolved
            InstallState                 = $installState
            MetadataValid                = $metadataValid
            InstallMode                  = $installMode
            LastUpdatedHead              = $lastUpdatedHead
            SourceResolvedHead           = $sourceResolvedHead
            PayloadDeltaRequired         = $payloadDeltaRequired
            ManifestMarkerCrossBindingOk = $manifestMarkerCrossBindingOk
            ActivationSurfaces           = $surfaceResults
            Reasons                      = @($reasons)
        }
    }

    # 5. all green.
    return [pscustomobject]@{
        Status                       = 'inspect_clean'
        ExitCode                     = 0
        InstallAreaPath              = $installAreaResolved
        InstallState                 = $installState
        MetadataValid                = $metadataValid
        InstallMode                  = $installMode
        LastUpdatedHead              = $lastUpdatedHead
        SourceResolvedHead           = $sourceResolvedHead
        PayloadDeltaRequired         = $payloadDeltaRequired
        ManifestMarkerCrossBindingOk = $manifestMarkerCrossBindingOk
        ActivationSurfaces           = $surfaceResults
        Reasons                      = @()
    }
}

function script:Invoke-VerifyMode {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)] [string] $InstallArea,
        [string] $ClaudeHome,
        [string] $CodexHome
    )

    $reasons = New-Object System.Collections.Generic.List[string]
    $installAreaResolved = [System.IO.Path]::GetFullPath($InstallArea)

    # Canonical verify via the shared library helper. Invoke-InstallPipelineVerify is the
    # single source of truth for full install verification — 14-field schema (including the
    # complete INSTALL.md §4/§5 mode-conditional rule: required-non-empty AND complementary
    # must-be-empty for both git-url and local-clone), manifest digest, marker, and
    # cross-binding. Returns PSCustomObject with .ok (bool) and .errors (array of strings).
    # No supplementary metadata schema check is layered here: that would duplicate the
    # canonical helper's metadata logic, which now covers the full mode-conditional schema.
    $verifyResult = Invoke-InstallPipelineVerify -InstallArea $installAreaResolved
    if (-not $verifyResult.ok) {
        foreach ($e in $verifyResult.errors) { $reasons.Add($e) }
    }

    # Activation surface byte-identity (3 surfaces). verify is the superset of
    # inspect, so the same activation check applies.
    $surfacesObj = script:Get-ActivationSurfacePaths -InstallArea $installAreaResolved -ClaudeHome $ClaudeHome -CodexHome $CodexHome
    $surfaceResults = @()
    foreach ($s in $surfacesObj.Surfaces) {
        $r = script:Test-ActivationSurface -Surface $s
        $surfaceResults += $r
        if (-not $r.ByteIdentical) {
            $reasons.Add(('activation surface byte-identity fail: {0} ({1})' -f $r.Name, $r.Reason))
        }
    }

    $status = if ($reasons.Count -eq 0) { 'verify_pass' } else { 'verify_failed' }
    $exitCode = if ($reasons.Count -eq 0) { 0 } else { 1 }

    return [pscustomobject]@{
        Status             = $status
        ExitCode           = $exitCode
        InstallAreaPath    = $installAreaResolved
        ActivationSurfaces = $surfaceResults
        Reasons            = @($reasons)
    }
}

# ---------------------------------------------------------------------------
# Output formatting.
# ---------------------------------------------------------------------------

function script:Format-StdoutJson {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)] [string] $Mode,
        [Parameter(Mandatory = $true)] [pscustomobject] $Result
    )

    # Build the strict subset of the run.json contract (INSTALL.md §13.4.1) that
    # applies to inspect/verify stdout — no startedAt/finishedAt/runId since this
    # entrypoint does not own a run lifecycle file.
    $surfaces = @()
    if (@($Result.PSObject.Properties.Name) -ccontains 'ActivationSurfaces') {
        foreach ($s in $Result.ActivationSurfaces) {
            $surfaces += [ordered]@{
                name          = $s.Name
                path          = $s.Path
                exists        = $s.Exists
                byteIdentical = $s.ByteIdentical
                reason        = $s.Reason
            }
        }
    }

    $body = [ordered]@{
        schemaVersion                = 1
        tool                         = 'ai-harness-toolset'
        mode                         = $Mode
        installAreaPath              = $Result.InstallAreaPath
        status                       = $Result.Status
        exitCode                     = $Result.ExitCode
        reasons                      = @($Result.Reasons)
        activationSurfaces           = $surfaces
    }
    # inspect/verify diagnostic group. Emit each field ONLY when the result object actually evaluated
    # it (true property-existence, NO false/null default), so update-source never reports an
    # UNEVALUATED diagnostic as metadataValid:false / manifestMarkerCrossBindingOk:false /
    # installState:null next to a success or follow-up status (I01). inspect always populates all of
    # these, so inspect stdout is unchanged; update-source emits the evaluated subset with real
    # post-apply values, and omits any field it did not evaluate (e.g. on a guard-failure path).
    $names = @($Result.PSObject.Properties.Name)
    if ($Mode -eq 'inspect' -or $Mode -eq 'update-source') {
        if ($names -ccontains 'InstallState')                 { $body['installState']                 = $Result.InstallState }
        if ($names -ccontains 'MetadataValid')                { $body['metadataValid']                = $Result.MetadataValid }
        if ($names -ccontains 'InstallMode')                  { $body['installMode']                  = $Result.InstallMode }
        if ($names -ccontains 'LastUpdatedHead')              { $body['lastUpdatedHead']              = $Result.LastUpdatedHead }
        if ($names -ccontains 'SourceResolvedHead')           { $body['sourceResolvedHead']           = $Result.SourceResolvedHead }
        if ($names -ccontains 'PayloadDeltaRequired')         { $body['payloadDeltaRequired']         = $Result.PayloadDeltaRequired }
        if ($names -ccontains 'ManifestMarkerCrossBindingOk') { $body['manifestMarkerCrossBindingOk'] = $Result.ManifestMarkerCrossBindingOk }
    }
    # update-source apply-outcome fields needed by the §13.2 cleanup invariant: leftoverPaths is
    # always emitted (so cleanup_failed_with_leftover carries the structured paths in the current
    # stdout-JSON evidence surface), and smoke surfaces its result. Both names exist in the §13.4.1
    # run.json schema, so the stdout-subset relationship holds. The assignment is done INSIDE each
    # branch (not `$body['leftoverPaths'] = if (...) {} else {}`) because PowerShell 5.1
    # ConvertTo-Json serializes an empty array returned from an if-EXPRESSION as `{}` rather than
    # `[]`; branch-local assignment preserves an empty leftoverPaths as a JSON array `[]` (I12).
    if ($Mode -eq 'update-source') {
        if ($names -ccontains 'LeftoverPaths') { $body['leftoverPaths'] = @($Result.LeftoverPaths) }
        else                                   { $body['leftoverPaths'] = @() }
        if ($names -ccontains 'Smoke') { $body['smoke'] = $Result.Smoke }
        else                           { $body['smoke'] = $null }
    }

    return ($body | ConvertTo-Json -Depth 8)
}

function script:Write-HumanReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)] [string] $Mode,
        [Parameter(Mandatory = $true)] [pscustomobject] $Result,
        [switch] $ToStderr
    )

    $lines = @(
        ('install-update: mode={0} installArea={1}' -f $Mode, $Result.InstallAreaPath),
        ('install-update: status={0}' -f $Result.Status),
        ('install-update: exitCode={0}' -f $Result.ExitCode)
    )
    if (@($Result.PSObject.Properties.Name) -ccontains 'Reasons' -and $Result.Reasons.Count -gt 0) {
        $lines += 'install-update: reasons:'
        foreach ($r in $Result.Reasons) { $lines += ('  - ' + $r) }
    }

    foreach ($line in $lines) {
        if ($ToStderr) {
            [Console]::Error.WriteLine($line)
        }
        else {
            Write-Host $line
        }
    }
}

# ---------------------------------------------------------------------------
# Approval — exact two-choice (Yes/No) terminal selector for mutation approval.
# Used ONLY by update-source (mutation). inspect / verify never call it.
# ---------------------------------------------------------------------------

function script:Test-ApprovalInteractive {
    # True only when a real interactive console is available. There is NO auto-approval:
    # a noninteractive / redirected-stdin / CI context returns $false, and the caller then
    # resolves the decision to 'no' (never 'yes'). No environment variable can flip this to
    # an auto-yes — that would be a forbidden noninteractive auto-approval.
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

function script:Resolve-TwoChoiceKeySequence {
    # PURE decision logic (no console IO) so the selector semantics are unit-testable
    # without a real keypress. Models the selector as: default highlight = Yes; 'Up' moves
    # highlight to Yes; 'Down' moves highlight to No; 'Enter' confirms the highlighted option;
    # 'Escape' resolves to No. Any other token is ignored. If the sequence ends with no
    # Enter/Escape, the decision is the fail-safe 'no' (never an implicit 'yes').
    [CmdletBinding()]
    param([string[]] $Keys = @())

    $highlight = 'yes'   # default highlighted option
    foreach ($k in $Keys) {
        switch ($k) {
            'Up'     { $highlight = 'yes' }
            'Down'   { $highlight = 'no' }
            'Enter'  { return $highlight }
            'Escape' { return 'no' }
            default  { }
        }
    }
    return 'no'
}

function script:Read-TwoChoiceApproval {
    # Console driver for the two-choice selector. Renders Yes / No with Yes highlighted by
    # default; Up/Down move the highlight; Enter confirms; Esc resolves to No. No timeout can
    # auto-select. Ctrl+C is left to the host default (process abort) — a safe abort because
    # approval is requested BEFORE any mutation, so aborting performs no mutation. This console
    # key-reading is source-reviewed; the pure mapping it mirrors is Resolve-TwoChoiceKeySequence
    # (unit-tested). Caller MUST gate on Test-ApprovalInteractive before calling.
    [CmdletBinding()]
    param([string] $Prompt = 'Apply this global/user mutation?')

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

function script:Get-MutationApproval {
    # Returns @{ Decision = 'yes'|'no'; Reason = <string|null> }. Decision is 'yes' ONLY when
    # an interactive console returned an explicit Yes from the selector. Noninteractive contexts
    # resolve to 'no' with a reason; there is no auto-approval.
    [CmdletBinding()]
    param([string] $Prompt = 'Apply this global/user mutation?')

    if (-not (script:Test-ApprovalInteractive)) {
        return [pscustomobject]@{
            Decision = 'no'
            Reason   = 'explicit approval required but no interactive terminal is available (noninteractive / redirected stdin); refusing to auto-approve'
        }
    }
    $decision = script:Read-TwoChoiceApproval -Prompt $Prompt
    return [pscustomobject]@{ Decision = $decision; Reason = $null }
}

# ---------------------------------------------------------------------------
# Operational smoke (optional; gated by -SkipSmoke). Runs the UPDATED payload's
# brief-init against a throwaway workspace and asserts the seeded BRIEF.md is
# byte-identical (SHA-256) to the payload template, with runtime artifacts
# isolated to the workspace log/ and the workspace cleaned up afterward.
# ---------------------------------------------------------------------------

function script:Invoke-OperationalSmoke {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)] [string] $PayloadRoot
    )

    $briefInit   = Join-Path $PayloadRoot 'scripts/brief-init.ps1'
    $templateRel = 'templates/brief/BRIEF.md'
    $template    = Join-Path $PayloadRoot $templateRel

    if (-not (Test-Path -LiteralPath $briefInit -PathType Leaf) -or -not (Test-Path -LiteralPath $template -PathType Leaf)) {
        return [pscustomobject]@{ Smoke = 'skip'; Reason = ('smoke prerequisites missing under payload (' + $briefInit + ' / ' + $templateRel + ')'); WorkspacePath = $null }
    }

    $workspace = Join-Path ([System.IO.Path]::GetTempPath()) ('iu-smoke-' + [Guid]::NewGuid().ToString('N'))
    # On smoke FAILURE the throwaway workspace is PRESERVED for debugging and its path is reported
    # (in the result WorkspacePath + in the failure Reason, which the caller folds into reasons[]),
    # mirroring the cleanup_failed_with_leftover "report, don't silently delete" contract (I14).
    # It is removed only on pass. The path is surfaced so a failing smoke can be inspected.
    $preserveForDebug = $false
    try {
        $null = New-Item -ItemType Directory -Path $workspace -Force
        # brief-init resolves ToolRoot from the payload and seeds <ProjectRoot>/log/brief/BRIEF.md.
        $proc = Invoke-NativeProcess -Executable 'powershell.exe' -Arguments @(
            '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $briefInit,
            '-ToolRoot', $PayloadRoot, '-ProjectRoot', $workspace
        )
        if ($proc.ExitCode -ne 0) {
            $preserveForDebug = $true
            return [pscustomobject]@{ Smoke = 'fail'; Reason = ('brief-init exit ' + $proc.ExitCode + ' (workspace preserved: ' + $workspace + '): ' + (($proc.Stdout + ' ' + $proc.Stderr).Trim())); WorkspacePath = $workspace }
        }
        $seeded = Join-Path $workspace 'log/brief/BRIEF.md'
        if (-not (Test-Path -LiteralPath $seeded -PathType Leaf)) {
            $preserveForDebug = $true
            return [pscustomobject]@{ Smoke = 'fail'; Reason = ('seeded BRIEF.md not found at ' + $seeded + ' (workspace preserved: ' + $workspace + ')'); WorkspacePath = $workspace }
        }
        $seededSha   = Get-FileSha256 -Path $seeded
        $templateSha = Get-FileSha256 -Path $template
        if ($seededSha -ne $templateSha) {
            $preserveForDebug = $true
            return [pscustomobject]@{ Smoke = 'fail'; Reason = ('seeded BRIEF.md sha256 differs from payload template (' + $seededSha + ' vs ' + $templateSha + ') (workspace preserved: ' + $workspace + ')'); WorkspacePath = $workspace }
        }
        # Isolation: the only runtime artifact must be under <workspace>/log/.
        $outsideLog = @(Get-ChildItem -LiteralPath $workspace -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne 'log' })
        if ($outsideLog.Count -gt 0) {
            $preserveForDebug = $true
            return [pscustomobject]@{ Smoke = 'fail'; Reason = ('smoke produced artifacts outside log/: ' + (($outsideLog | ForEach-Object { $_.Name }) -join ', ') + ' (workspace preserved: ' + $workspace + ')'); WorkspacePath = $workspace }
        }
        return [pscustomobject]@{ Smoke = 'pass'; Reason = $null; WorkspacePath = $null }
    }
    catch {
        $preserveForDebug = $true
        return [pscustomobject]@{ Smoke = 'fail'; Reason = ('smoke exception: ' + $_.Exception.Message + ' (workspace preserved: ' + $workspace + ')'); WorkspacePath = $workspace }
    }
    finally {
        if (-not $preserveForDebug -and (Test-Path -LiteralPath $workspace)) {
            Remove-Item -LiteralPath $workspace -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

# ---------------------------------------------------------------------------
# update-source apply orchestration (MUTATION). Reached only via Invoke-Main's update-source
# branch under command-implied approval (the explicit update-source invocation is the approval;
# optionally gated by -ConfirmInteractive). This function still enforces the hard guards
# (existing valid install identity, source-cut, resolved HEAD) and never mutates when a guard
# trips. Tests invoke it directly against a temp fixture InstallArea.
# ---------------------------------------------------------------------------

function script:Invoke-UpdateSourceApply {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)] [string] $InstallArea,
        [string] $ClaudeHome,
        [string] $CodexHome,
        [string] $SourcePath,
        [string] $RepoUrl,
        [string] $Branch,
        [string] $Remote,
        [string] $Ref,
        [switch] $SkipSmoke
    )

    $reasons = New-Object System.Collections.Generic.List[string]
    $installAreaResolved = [System.IO.Path]::GetFullPath($InstallArea)

    # 1. Existing metadata is required (update-source is not a fresh install).
    $metadata = $null
    try { $metadata = Read-InstallPipelineMetadata -InstallArea $installAreaResolved } catch { }
    if ($null -eq $metadata) {
        $reasons.Add('cannot update-source: no existing install.json at ' + $installAreaResolved)
        return [pscustomobject]@{ Status = 'failed'; ExitCode = 1; InstallAreaPath = $installAreaResolved; Reasons = @($reasons); ActivationSurfaces = @() }
    }
    $installMode = [string]$metadata.installMode
    $prevLastUpdatedHead = if (@($metadata.PSObject.Properties.Name) -ccontains 'lastUpdatedHead') { [string]$metadata.lastUpdatedHead } else { '' }

    # 2. Acquire source + resolve head + tuple toolRoot, per installMode.
    $cleanupCache = $false
    $cacheDir = $null
    $sourceLocation = $null
    $tupleToolRoot = $null
    $resolvedHead = $null
    try {
        if ($installMode -eq 'local-clone') {
            $sourceLocation = if (-not [string]::IsNullOrEmpty($SourcePath)) { $SourcePath } else { [string]$metadata.sourcePath }
            if ([string]::IsNullOrEmpty($sourceLocation)) {
                $reasons.Add('local-clone update-source needs a source path (-SourcePath or install.json.sourcePath)')
                return [pscustomobject]@{ Status = 'failed'; ExitCode = 1; InstallAreaPath = $installAreaResolved; Reasons = @($reasons); ActivationSurfaces = @() }
            }
            $sourceLocation = [System.IO.Path]::GetFullPath($sourceLocation)
            $resolvedHead = Get-InstallPipelineSourceHead -SourceLocation $sourceLocation
            $tupleToolRoot = $sourceLocation
        }
        elseif ($installMode -eq 'git-url') {
            $url = if (-not [string]::IsNullOrEmpty($RepoUrl)) { $RepoUrl } else { [string]$metadata.repoUrl }
            if ([string]::IsNullOrEmpty($url)) {
                $reasons.Add('git-url update-source needs a repo URL (-RepoUrl or install.json.repoUrl)')
                return [pscustomobject]@{ Status = 'failed'; ExitCode = 1; InstallAreaPath = $installAreaResolved; Reasons = @($reasons); ActivationSurfaces = @() }
            }
            # Full (non-shallow) clone into the run-scoped source-cache work area, so every ref
            # SHA is available; cleaned up after the run regardless of outcome.
            $cacheDir = Invoke-InstallPipelineGitUrlClone -InstallArea $installAreaResolved -RepoUrl $url
            $cleanupCache = $true
            $branchForHead = if (-not [string]::IsNullOrEmpty($Branch)) { $Branch } elseif (@($metadata.PSObject.Properties.Name) -ccontains 'branch') { [string]$metadata.branch } else { '' }
            if (-not [string]::IsNullOrEmpty($Ref)) {
                $resolvedHead = Resolve-InstallPipelineRef -SourceLocation $cacheDir -Ref $Ref
            }
            elseif (-not [string]::IsNullOrEmpty($branchForHead)) {
                $resolvedHead = Get-InstallPipelineGitUrlRemoteHead -InstallArea $installAreaResolved -Remote $Remote -Branch $branchForHead
            }
            else {
                $resolvedHead = Get-InstallPipelineSourceHead -SourceLocation $cacheDir
            }
            $sourceLocation = $url
            $tupleToolRoot = $cacheDir
        }
        else {
            $reasons.Add('install.json.installMode invalid for update-source: ' + $installMode)
            return [pscustomobject]@{ Status = 'failed'; ExitCode = 1; InstallAreaPath = $installAreaResolved; Reasons = @($reasons); ActivationSurfaces = @() }
        }

        if ([string]::IsNullOrEmpty($resolvedHead) -or ($resolvedHead -notmatch '^[0-9a-f]{40}$')) {
            $reasons.Add('could not resolve a 40-hex source HEAD for update-source')
            if ($cleanupCache -and $null -ne $cacheDir -and (Test-Path -LiteralPath $cacheDir)) {
                Remove-Item -LiteralPath $cacheDir -Recurse -Force -ErrorAction SilentlyContinue
            }
            return [pscustomobject]@{ Status = 'failed'; ExitCode = 1; InstallAreaPath = $installAreaResolved; Reasons = @($reasons); ActivationSurfaces = @() }
        }

        # 3. Source-cut guard — a changed source identity is not auto-resolved here. The comparison
        #    must mirror the canonical helper's field set (installMode / repoUrl / sourcePath /
        #    toolRoot / branch / remote): an explicit -Branch / -Remote that differs from the
        #    recorded tracking metadata is a source-cut (e.g. switching the tracked branch), not a
        #    silent one-shot override. Only explicitly-supplied identity values are compared.
        $invocationParams = @{ installMode = $installMode }
        if ($installMode -eq 'git-url')     { $invocationParams['repoUrl']    = $sourceLocation }
        if ($installMode -eq 'local-clone') { $invocationParams['sourcePath'] = $sourceLocation }
        if (-not [string]::IsNullOrEmpty($Branch)) { $invocationParams['branch'] = $Branch }
        if (-not [string]::IsNullOrEmpty($Remote)) { $invocationParams['remote'] = $Remote }
        if (Test-InstallPipelineSourceCut -Metadata $metadata -InvocationParams $invocationParams) {
            $reasons.Add('source-cut detected (source identity — installMode/repoUrl/sourcePath/toolRoot/branch/remote — differs from install.json); not auto-resolved — re-run as a separate explicit decision')
            if ($cleanupCache -and $null -ne $cacheDir -and (Test-Path -LiteralPath $cacheDir)) {
                Remove-Item -LiteralPath $cacheDir -Recurse -Force -ErrorAction SilentlyContinue
            }
            return [pscustomobject]@{ Status = 'failed'; ExitCode = 1; InstallAreaPath = $installAreaResolved; Reasons = @($reasons); ActivationSurfaces = @(); InstallMode = $installMode; LastUpdatedHead = $prevLastUpdatedHead; SourceResolvedHead = $resolvedHead; PayloadDeltaRequired = $true }
        }

        # 4. Canonical deterministic materialization via tuple + dispatch.
        #    Dispatch preserves installedHead/installedAt and updates lastUpdatedHead/lastUpdatedAt,
        #    and rewrites current/ + payload-manifest.json + payload-marker.json consistently.
        $tuple = New-InstallPipelineTuple `
            -Action 'update-source' `
            -InstallMode $installMode `
            -SourceLocation $sourceLocation `
            -ResolvedRefSha $resolvedHead `
            -RefKind 'commit' `
            -ToolRoot $tupleToolRoot `
            -ProjectRoot $installAreaResolved `
            -SourceUpdatePolicy 'fetch-and-update'
        Invoke-InstallPipelineDispatch -Tuple $tuple -InstallArea $installAreaResolved -Branch $Branch -Remote $Remote
    }
    catch {
        $reasons.Add('apply failed: ' + $_.Exception.Message)
        if ($cleanupCache -and $null -ne $cacheDir -and (Test-Path -LiteralPath $cacheDir)) {
            Remove-Item -LiteralPath $cacheDir -Recurse -Force -ErrorAction SilentlyContinue
        }
        return [pscustomobject]@{ Status = 'failed'; ExitCode = 1; InstallAreaPath = $installAreaResolved; Reasons = @($reasons); ActivationSurfaces = @(); InstallMode = $installMode; LastUpdatedHead = $prevLastUpdatedHead; SourceResolvedHead = $resolvedHead; PayloadDeltaRequired = $true }
    }

    # 5. Post-apply canonical verify (schema + manifest digest + marker + cross-binding).
    $verifyResult = Invoke-InstallPipelineVerify -InstallArea $installAreaResolved
    $verifyOk = $verifyResult.ok
    if (-not $verifyOk) { foreach ($e in $verifyResult.errors) { $reasons.Add('verify: ' + $e) } }

    # 6. Activation surfaces — byte-identity verification only (NO rewrite). A byte-identical
    #    surface is a verified no-op; a drifted/absent surface is reported (activation_pending),
    #    not silently applied (managed-block / skill apply is a separate explicit step).
    $surfacesObj = script:Get-ActivationSurfacePaths -InstallArea $installAreaResolved -ClaudeHome $ClaudeHome -CodexHome $CodexHome
    $surfaceResults = @()
    $activationClean = $true
    foreach ($s in $surfacesObj.Surfaces) {
        $r = script:Test-ActivationSurface -Surface $s
        $surfaceResults += $r
        if (-not $r.ByteIdentical) {
            $activationClean = $false
            $reasons.Add(('activation surface not byte-identical (verify-only, not applied): {0} ({1})' -f $r.Name, $r.Reason))
        }
    }

    # 7. Cleanup the run-scoped source-cache (git-url). Cleanup failure is reported as leftover,
    #    never turned into an approval prompt.
    $leftoverPaths = @()
    $cleanupOk = $true
    if ($cleanupCache -and $null -ne $cacheDir) {
        try {
            if (Test-Path -LiteralPath $cacheDir) { Remove-Item -LiteralPath $cacheDir -Recurse -Force }
            if (Test-Path -LiteralPath $cacheDir) { $cleanupOk = $false; $leftoverPaths += $cacheDir }
        }
        catch {
            $cleanupOk = $false
            $leftoverPaths += $cacheDir
            $reasons.Add('cleanup failed: ' + $_.Exception.Message)
        }
        if (-not $cleanupOk) { $reasons.Add('source-cache cleanup left leftover path: ' + $cacheDir) }
    }

    # 8. Operational smoke (optional). Runs the updated payload's brief-init in a throwaway
    #    workspace and asserts BRIEF == template by SHA-256, isolated + cleaned up.
    $smoke = 'skip'
    if (-not $SkipSmoke) {
        $smokeResult = script:Invoke-OperationalSmoke -PayloadRoot (Get-InstallPipelineCurrentDir -InstallArea $installAreaResolved)
        $smoke = $smokeResult.Smoke
        if ($smoke -eq 'fail') { $reasons.Add('smoke: ' + $smokeResult.Reason) }
        elseif ($smoke -eq 'skip' -and -not [string]::IsNullOrEmpty($smokeResult.Reason)) { $reasons.Add('smoke skipped: ' + $smokeResult.Reason) }
    }
    else {
        $reasons.Add('smoke skipped by -SkipSmoke')
    }

    # 9. Post-apply diagnostics from REAL on-disk evidence (I01). These are evaluated, not
    #    unevaluated defaults, so the stdout JSON does not show installState:null /
    #    metadataValid:false / manifestMarkerCrossBindingOk:false next to a success or follow-up
    #    status. installState reflects the materialized payload; metadataValid reuses the canonical
    #    schema check on the post-apply install.json; crossBindingOk re-checks the post-apply
    #    manifest/marker head binding to the just-applied resolved SHA. On a post-apply verify
    #    failure these read their true (possibly false) values, with granular detail in reasons.
    $postInstallState = 'absent'
    $postMetadataValid = $false
    $postCrossBindingOk = $false
    try {
        $postMd = Read-InstallPipelineMetadata -InstallArea $installAreaResolved
        if ($null -ne $postMd) {
            $postInstallState = 'present'
            $schemaCheckReasons = New-Object System.Collections.Generic.List[string]
            $postMetadataValid = [bool](script:Test-MetadataSchemaOk -Metadata $postMd -Reasons $schemaCheckReasons)
        }
    }
    catch { $postInstallState = 'partial' }
    try {
        $postManifest = Read-InstallPipelineManifest -InstallArea $installAreaResolved
        $postMarker   = Read-InstallPipelineMarker   -InstallArea $installAreaResolved
        if ($null -ne $postManifest -and $null -ne $postMarker) {
            $mh = if (@($postManifest.PSObject.Properties.Name) -ccontains 'head') { [string]$postManifest.head } else { '' }
            $kh = if (@($postMarker.PSObject.Properties.Name)   -ccontains 'head') { [string]$postMarker.head }   else { '' }
            $postCrossBindingOk = (-not [string]::IsNullOrEmpty($mh)) -and ($mh -eq $kh) -and ($mh -eq [string]$resolvedHead)
        }
    }
    catch { }

    # 10. Final status by precedence (payload was rewritten; do not over-claim complete).
    $status = 'complete'
    if (-not $verifyOk)            { $status = 'verify_failed' }
    elseif (-not $activationClean) { $status = 'activation_pending' }
    elseif (-not $cleanupOk)       { $status = 'cleanup_failed_with_leftover' }
    elseif ($smoke -eq 'fail')     { $status = 'smoke_failed' }
    else                           { $status = 'complete' }
    $exitCode = if ($status -eq 'complete') { 0 } else { 1 }

    return [pscustomobject]@{
        Status                       = $status
        ExitCode                     = $exitCode
        InstallAreaPath              = $installAreaResolved
        Reasons                      = @($reasons)
        ActivationSurfaces           = $surfaceResults
        InstallState                 = $postInstallState
        MetadataValid                = $postMetadataValid
        InstallMode                  = $installMode
        LastUpdatedHead              = $resolvedHead
        SourceResolvedHead           = $resolvedHead
        PayloadDeltaRequired         = $true
        ManifestMarkerCrossBindingOk = $postCrossBindingOk
        LeftoverPaths                = @($leftoverPaths)
        Smoke                        = $smoke
    }
}

# ---------------------------------------------------------------------------
# Main entrypoint flow (only runs when the script is invoked directly, not dot-sourced).
# ---------------------------------------------------------------------------

function script:Invoke-Main {
    [CmdletBinding()]
    param()

    if ([string]::IsNullOrEmpty($Mode)) {
        Write-Host 'install-update: FAIL -Mode is required (inspect | verify | update-source).'
        exit 1
    }
    if ([string]::IsNullOrEmpty($InstallArea)) {
        Write-Host 'install-update: FAIL -InstallArea is required.'
        exit 1
    }
    # Guard: no mutation FLAG may be wired in (mutation is the update-source MODE only).
    script:Assert-NoMutationPath -Mode $Mode -RequestedFlags @{}

    try {
        if ($Mode -eq 'inspect') {
            $result = script:Invoke-InspectMode -InstallArea $InstallArea -ClaudeHome $ClaudeHome -CodexHome $CodexHome -SourcePath $SourcePath -RepoUrl $RepoUrl -Branch $Branch -Remote $Remote -Ref $Ref
        }
        elseif ($Mode -eq 'verify') {
            $result = script:Invoke-VerifyMode -InstallArea $InstallArea -ClaudeHome $ClaudeHome -CodexHome $CodexHome
        }
        elseif ($Mode -eq 'update-source') {
            # Preflight (read-only) to decide whether a payload mutation is actually needed.
            $pre = script:Invoke-InspectMode -InstallArea $InstallArea -ClaudeHome $ClaudeHome -CodexHome $CodexHome -SourcePath $SourcePath -RepoUrl $RepoUrl -Branch $Branch -Remote $Remote -Ref $Ref
            if ($pre.Status -eq 'inspect_mode_unknown') {
                $result = [pscustomobject]@{ Status = 'failed'; ExitCode = 1; InstallAreaPath = $pre.InstallAreaPath; Reasons = @(@('cannot update-source: install metadata unknown') + @($pre.Reasons)); ActivationSurfaces = @() }
            }
            elseif (($pre.Status -eq 'inspect_source_drift') -and ($null -eq $pre.SourceResolvedHead)) {
                $result = [pscustomobject]@{ Status = 'failed'; ExitCode = 1; InstallAreaPath = $pre.InstallAreaPath; Reasons = @(@('cannot update-source: source HEAD could not be resolved') + @($pre.Reasons)); ActivationSurfaces = @() }
            }
            elseif ($pre.Status -eq 'inspect_clean') {
                # No payload delta and activation already byte-identical → nothing to mutate.
                $result = [pscustomobject]@{ Status = 'noop_already_current'; ExitCode = 0; InstallAreaPath = $pre.InstallAreaPath; Reasons = @('already at source HEAD with clean payload + activation; no update needed'); ActivationSurfaces = $pre.ActivationSurfaces; InstallState = $pre.InstallState; MetadataValid = $pre.MetadataValid; InstallMode = $pre.InstallMode; LastUpdatedHead = $pre.LastUpdatedHead; SourceResolvedHead = $pre.SourceResolvedHead; PayloadDeltaRequired = $false; ManifestMarkerCrossBindingOk = $pre.ManifestMarkerCrossBindingOk }
            }
            elseif (($pre.Status -eq 'inspect_activation_drift') -and (-not $pre.PayloadDeltaRequired)) {
                # Payload already current; only activation drifted. update-source does not apply
                # activation surfaces, so it cannot resolve this — report without mutation.
                $result = [pscustomobject]@{ Status = 'activation_pending'; ExitCode = 1; InstallAreaPath = $pre.InstallAreaPath; Reasons = @(@('payload already current; activation drift requires a separate activation apply (out of scope for update-source); no mutation performed') + @($pre.Reasons)); ActivationSurfaces = $pre.ActivationSurfaces; InstallState = $pre.InstallState; MetadataValid = $pre.MetadataValid; InstallMode = $pre.InstallMode; LastUpdatedHead = $pre.LastUpdatedHead; SourceResolvedHead = $pre.SourceResolvedHead; PayloadDeltaRequired = $false; ManifestMarkerCrossBindingOk = $pre.ManifestMarkerCrossBindingOk }
            }
            else {
                # A payload delta exists (source drift or payload drift). Command-implied approval
                # model (INSTALL.md §7.1.1 / §13.8): the operator's explicit update command on an
                # existing identity-consistent install IS the approval surface — the apply proceeds
                # without a mandatory terminal selector, so a normal noninteractive Claude Code shell
                # is no longer blocked. The hard guards (source-cut / metadata-unknown / identity /
                # destination / resolve-failure) still stop the mutation: they are enforced by the
                # read-only preflight above and inside Invoke-UpdateSourceApply (which only mutates an
                # existing identity-consistent install area). The interactive Yes/No selector is an
                # OPTIONAL secondary path for direct-terminal use, requested via -ConfirmInteractive.
                if ($ConfirmInteractive) {
                    if (-not (script:Test-ApprovalInteractive)) {
                        # Explicit interactive confirm was requested but no terminal is available;
                        # do NOT silently fall through to command-implied apply — abort instead.
                        $result = [pscustomobject]@{ Status = 'update_aborted_no_approval'; ExitCode = 1; InstallAreaPath = $pre.InstallAreaPath; Reasons = @('-ConfirmInteractive requested but no interactive terminal is available; no mutation performed'); ActivationSurfaces = @(); InstallMode = $pre.InstallMode; LastUpdatedHead = $pre.LastUpdatedHead; SourceResolvedHead = $pre.SourceResolvedHead; PayloadDeltaRequired = $true }
                    }
                    else {
                        $prompt = ('Apply update-source to {0}? This rewrites current/ + install.json + payload-manifest.json + payload-marker.json.' -f $pre.InstallAreaPath)
                        $approval = script:Get-MutationApproval -Prompt $prompt
                        if ($approval.Decision -ne 'yes') {
                            $abortReasons = @('update-source aborted: interactive approval not granted')
                            if (-not [string]::IsNullOrEmpty($approval.Reason)) { $abortReasons += $approval.Reason }
                            $result = [pscustomobject]@{ Status = 'update_aborted_no_approval'; ExitCode = 1; InstallAreaPath = $pre.InstallAreaPath; Reasons = $abortReasons; ActivationSurfaces = @(); InstallMode = $pre.InstallMode; LastUpdatedHead = $pre.LastUpdatedHead; SourceResolvedHead = $pre.SourceResolvedHead; PayloadDeltaRequired = $true }
                        }
                        else {
                            $result = script:Invoke-UpdateSourceApply -InstallArea $InstallArea -ClaudeHome $ClaudeHome -CodexHome $CodexHome -SourcePath $SourcePath -RepoUrl $RepoUrl -Branch $Branch -Remote $Remote -Ref $Ref -SkipSmoke:$SkipSmoke
                        }
                    }
                }
                else {
                    # Command-implied approval (default): the explicit update-source invocation is the
                    # approval. Guards inside Invoke-UpdateSourceApply (source-cut, missing/invalid
                    # metadata, missing source identity, unresolved HEAD) still return failed without
                    # mutation; verify / activation / cleanup outcomes map to their fixed statuses.
                    $result = script:Invoke-UpdateSourceApply -InstallArea $InstallArea -ClaudeHome $ClaudeHome -CodexHome $CodexHome -SourcePath $SourcePath -RepoUrl $RepoUrl -Branch $Branch -Remote $Remote -Ref $Ref -SkipSmoke:$SkipSmoke
                }
            }
        }
        else {
            Write-Host ('install-update: FAIL unknown mode: ' + $Mode)
            exit 1
        }
    }
    catch {
        Write-Host ('install-update: FAIL unhandled exception: ' + $_.Exception.Message)
        exit 1
    }

    $jsonBody = script:Format-StdoutJson -Mode $Mode -Result $result

    if ($Json) {
        script:Write-HumanReport -Mode $Mode -Result $result -ToStderr
        Write-Host $jsonBody
    }
    else {
        script:Write-HumanReport -Mode $Mode -Result $result
        Write-Host '--- BEGIN JSON ---'
        Write-Host $jsonBody
        Write-Host '--- END JSON ---'
    }

    $finalLabel = if ($result.ExitCode -eq 0) { 'PASS' } else { 'FAIL' }
    if ($Json) {
        [Console]::Error.WriteLine('install-update: ' + $finalLabel)
    }
    else {
        Write-Host ('install-update: ' + $finalLabel)
    }
    exit $result.ExitCode
}

# Run the entrypoint only when executed directly (not when dot-sourced for testing).
# Dot-source sets $MyInvocation.InvocationName to '.'; a -File / call invocation sets it
# to the script path. This lets the Pester suite dot-source the file to unit-test the pure
# selector logic and the apply orchestration without running the main flow.
if ($MyInvocation.InvocationName -ne '.') {
    script:Invoke-Main
}
