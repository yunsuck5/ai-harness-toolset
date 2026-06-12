Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Helper: run a native command and rely solely on $LASTEXITCODE for success/failure.
# In PS 5.1, $ErrorActionPreference='Stop' combined with 2>&1 (or 2>$null in some scopes)
# wraps each stderr line as a NativeCommandError and terminates BEFORE the caller can
# inspect $LASTEXITCODE. Pinning to 'Continue' inside this helper lets the native exit
# code drive the decision; the caller throws a wrapper message on non-zero.
function Invoke-InstallPipelineNativeGit {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]] $Arguments,
        [switch] $CaptureStdout
    )
    $prev = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        if ($CaptureStdout) {
            $stdout = & git @Arguments
        }
        else {
            & git @Arguments | Out-Null
            $stdout = $null
        }
        $code = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $prev
    }
    return [pscustomobject]@{ ExitCode = $code; Stdout = $stdout }
}

# install-pipeline-core library — install/update/restore runtime pipeline (temp-only skeleton).
# Dot-sourced from tests/support/install-pipeline-fixture.ps1 (fixture / test harness
# entry; moved from the former scripts/install-pipeline.ps1 path to make the role explicit)
# and from tests/install-pipeline.Tests.ps1 (Pester suite).
#
# Runtime pipeline grouping (resolver → materialization → dispatcher → verify). The
#   operative contract is this library plus its Pester suite; the grouping's decision
#   record / rationale is preserved in git history (not an operative authority):
#   - source / ref resolver (resolved tuple shape).
#   - overwrite materialization core (deterministic copy into current/).
#   - dispatcher (4 action labels routed through one pipeline shape).
#   - verify (minimal: payload roots exist + metadata core fields).
#
# Boundaries kept by this library:
#   - resolver tuple `toolRoot` is the source-side canonical local ToolRoot
#     (the install.json `toolRoot` identity hint), NOT the materialization
#     destination. Destination is global install area's current/ — kept as a
#     separate path concept inside Invoke-InstallMaterialization.
#   - metadata schema: install.json sibling-of-current/, JSON (INSTALL.md §4 / §5).
#   - source-cut is detection only; this library never auto-resolves it.
#   - this library never writes outside the caller-supplied InstallArea.

$script:InstallPipelineSchemaVersion        = 1
$script:InstallPipelineTool                 = 'ai-harness-toolset'
# Exact install.json field set (canonical order = New-InstallPipelineMetadata). Verify uses
# this for missing-field / unexpected-field strictness. Keep in sync with the constructor;
# adding a real field is a deliberate schema change that updates both sites together.
$script:InstallPipelineMetadataFields       = @(
    'schemaVersion', 'tool', 'installMode', 'repoUrl', 'sourcePath', 'toolRoot',
    'branch', 'remote', 'installedHead', 'lastUpdatedHead', 'installedAt',
    'lastUpdatedAt', 'targetFootprintPolicy', 'managedBy'
)
$script:InstallPipelineManagedBy            = 'claude-code'
$script:InstallPipelineFootprint            = 'log-only'
$script:InstallPipelinePayloadRoots         = @('config', 'scripts', 'snippets', 'templates')
$script:InstallPipelineMetadataName         = 'install.json'
$script:InstallPipelineManifestSchemaVersion = 1
$script:InstallPipelineManifestName         = 'payload-manifest.json'
$script:InstallPipelineMarkerSchemaVersion  = 1
$script:InstallPipelineMarkerName           = 'payload-marker.json'
$script:InstallPipelineSourceCacheName      = 'source-cache'
$script:InstallPipelineGitUrlDefaultRemote  = 'origin'
# Managed root artifact (Phase 3.5): an operator landing page placed at the InstallArea root
# (sibling of current/). Its source is an in-payload template under current/<this rel path>, so the
# template's bytes are already covered by payload-manifest.json; the root copy is then verified by
# byte-identity (SHA-256) against that manifest-covered template (no manifest-schema change). The
# feature is template-conditional: if the payload does not carry the template, materialization and
# verification skip it (mirrors the operational-smoke skip-on-missing-prerequisite pattern), so a
# source/fixture without the template is unaffected.
$script:InstallPipelineRootReadmeName        = 'README.md'
$script:InstallPipelineRootReadmeTemplateRel = 'templates/install-root/AI_HARNESS_TOOLSET_ROOT_README.md'

function Get-InstallPipelinePayloadRoots {
    return ,$script:InstallPipelinePayloadRoots
}

function Get-InstallPipelineMetadataPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallArea
    )
    return [System.IO.Path]::GetFullPath((Join-Path -Path $InstallArea -ChildPath $script:InstallPipelineMetadataName))
}

function Get-InstallPipelineCurrentDir {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallArea
    )
    return [System.IO.Path]::GetFullPath((Join-Path -Path $InstallArea -ChildPath 'current'))
}

function Get-InstallPipelineManifestPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallArea
    )
    return [System.IO.Path]::GetFullPath((Join-Path -Path $InstallArea -ChildPath $script:InstallPipelineManifestName))
}

function Get-InstallPipelineMarkerPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallArea
    )
    return [System.IO.Path]::GetFullPath((Join-Path -Path $InstallArea -ChildPath $script:InstallPipelineMarkerName))
}

# Installed root artifact path: <InstallArea>/README.md (sibling of current/).
function Get-InstallPipelineRootReadmePath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallArea
    )
    return [System.IO.Path]::GetFullPath((Join-Path -Path $InstallArea -ChildPath $script:InstallPipelineRootReadmeName))
}

# In-payload source template path: current/templates/install-root/AI_HARNESS_TOOLSET_ROOT_README.md.
# This is what the root README is materialized from and verified against. It lives under a payload
# root (templates/), so payload-manifest.json already covers its bytes.
function Get-InstallPipelineRootReadmeTemplatePath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallArea
    )
    $currentDir = Get-InstallPipelineCurrentDir -InstallArea $InstallArea
    $rel = $script:InstallPipelineRootReadmeTemplateRel -replace '/', [System.IO.Path]::DirectorySeparatorChar
    return [System.IO.Path]::GetFullPath((Join-Path -Path $currentDir -ChildPath $rel))
}

# Materialize the managed root README from the in-payload template (template-conditional):
# copy current/templates/install-root/...README.md -> <InstallArea>/README.md. If the payload does
# not carry the template (e.g. a pre-Phase-3.5 source or a minimal test fixture), this is a no-op
# (skip) so such sources are unaffected. Returns the action taken for caller diagnostics.
function Set-InstallPipelineRootReadme {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallArea
    )
    $templatePath = Get-InstallPipelineRootReadmeTemplatePath -InstallArea $InstallArea
    $readmePath   = Get-InstallPipelineRootReadmePath -InstallArea $InstallArea
    if (-not (Test-Path -LiteralPath $templatePath -PathType Leaf)) {
        return 'skipped-no-template'
    }
    # Deterministic overwrite from the in-payload template (byte-for-byte copy).
    Copy-Item -LiteralPath $templatePath -Destination $readmePath -Force
    return 'materialized'
}

# Managed root README integrity state (template-conditional). Single-sources the byte-identity
# check used by both Invoke-InstallPipelineVerify and the inspect-mode classifier so the recovery
# guidance stays consistent. The managed root README is a CANONICAL output of a normal install /
# payload-rewriting update-source — it is NOT a self-healing target: a missing / stale / corrupt
# root README on an otherwise-current install is an install-integrity failure, recovered by the
# standard reinstall-first deterministic overwrite (INSTALL.md section 9), never by a no-op
# in-place repair. Returns a state object:
#   State        : 'skipped-no-template' | 'ok' | 'missing' | 'stale'
#   ReadmePath   : <InstallArea>/README.md
#   TemplatePath : current/templates/install-root/...README.md
#   Reason       : $null for ok/skip; an install-integrity reason (reinstall-first guidance) for missing/stale
function Get-InstallPipelineRootReadmeState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallArea
    )
    $templatePath = Get-InstallPipelineRootReadmeTemplatePath -InstallArea $InstallArea
    $readmePath   = Get-InstallPipelineRootReadmePath -InstallArea $InstallArea
    if (-not (Test-Path -LiteralPath $templatePath -PathType Leaf)) {
        return [pscustomobject]@{ State = 'skipped-no-template'; ReadmePath = $readmePath; TemplatePath = $templatePath; Reason = $null }
    }
    $rel = $script:InstallPipelineRootReadmeTemplateRel
    if (-not (Test-Path -LiteralPath $readmePath -PathType Leaf)) {
        return [pscustomobject]@{
            State        = 'missing'
            ReadmePath   = $readmePath
            TemplatePath = $templatePath
            Reason       = "managed root README missing: $readmePath (expected a byte-identical copy of current/$rel) — install integrity failure; recover by a reinstall-first deterministic overwrite (INSTALL.md section 9), not a no-op update-source"
        }
    }
    $tplBytes = [System.IO.File]::ReadAllBytes($templatePath)
    $rdBytes  = [System.IO.File]::ReadAllBytes($readmePath)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $tplHex = ([System.BitConverter]::ToString($sha.ComputeHash($tplBytes))).Replace('-','').ToLowerInvariant()
        $rdHex  = ([System.BitConverter]::ToString($sha.ComputeHash($rdBytes))).Replace('-','').ToLowerInvariant()
    }
    finally { $sha.Dispose() }
    if ($rdHex -ne $tplHex) {
        return [pscustomobject]@{
            State        = 'stale'
            ReadmePath   = $readmePath
            TemplatePath = $templatePath
            Reason       = "managed root README sha256 mismatch: $readmePath (root=$rdHex; template=$tplHex) — install integrity failure (stale or modified); recover by a reinstall-first deterministic overwrite (INSTALL.md section 9), not a no-op update-source"
        }
    }
    return [pscustomobject]@{ State = 'ok'; ReadmePath = $readmePath; TemplatePath = $templatePath; Reason = $null }
}

# source-cache directory used as a RUN-SCOPED TEMPORARY WORK AREA for git-url mode.
# Per INSTALL.md §2 / §6 / §7 / §9 the cache is NOT a persistent canonical install output;
# the fixture entry script (tests/support/install-pipeline-fixture.ps1) creates it at action start and removes it
# at action end. Within a single action the cache exists transiently so `Invoke-InstallPipeline*`
# helpers below (clone / remote-head / archive) can operate against it. The persistent
# canonical install outputs are: `current/`, `install.json`, `payload-manifest.json`,
# `payload-marker.json`. `install.json.toolRoot` is intentionally empty for git-url (see
# New-InstallPipelineMetadata) because the work area is transient and not a stable identity.
function Get-InstallPipelineSourceCacheDir {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallArea
    )
    $joined = Join-Path -Path $InstallArea -ChildPath $script:InstallPipelineSourceCacheName
    return [System.IO.Path]::GetFullPath($joined)
}

function Test-InstallPipelineSourceCachePresent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallArea
    )
    $cache = Get-InstallPipelineSourceCacheDir -InstallArea $InstallArea
    if (-not (Test-Path -LiteralPath $cache -PathType Container)) { return $false }
    $gitDir = Join-Path $cache '.git'
    return (Test-Path -LiteralPath $gitDir)
}

# git-url install acquisition (INSTALL.md §2 run-scoped work area): single
# `git clone <repoUrl> <cache>` into a fresh cache dir.
# Fails fast if the cache already exists with payload — caller is expected to gate this on
# Test-InstallPipelineSourceCachePresent / action == 'install' semantics.
function Invoke-InstallPipelineGitUrlClone {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallArea,
        [Parameter(Mandatory = $true)]
        [string] $RepoUrl
    )

    if (-not (Test-Path -LiteralPath $InstallArea -PathType Container)) {
        throw "Invoke-InstallPipelineGitUrlClone: InstallArea not found: $InstallArea"
    }
    if ([string]::IsNullOrEmpty($RepoUrl)) {
        throw 'Invoke-InstallPipelineGitUrlClone: -RepoUrl is required.'
    }
    $cache = Get-InstallPipelineSourceCacheDir -InstallArea $InstallArea
    if (Test-Path -LiteralPath $cache) {
        # If anything is present (even partial), refuse — operator must clean it up. Atomicity
        # is at the deliverable artifact level (install.json/manifest/marker/current/ —
        # clone/resolve failures precede materialization, so deliverables keep byte-identity);
        # partial cache from a prior failed clone is operator-visible cleanup territory.
        $any = Get-ChildItem -LiteralPath $cache -Force -ErrorAction SilentlyContinue
        if ($null -ne $any) {
            throw "Invoke-InstallPipelineGitUrlClone: cache already exists and is not empty: $cache. Remove it explicitly before re-running fresh install."
        }
    }
    else {
        $null = New-Item -ItemType Directory -Path $cache -Force
    }

    # Invoke-InstallPipelineNativeGit pins $ErrorActionPreference=Continue around the call
    # so NativeCommandError on git stderr does not preempt the exit-code-driven throw below.
    $res = Invoke-InstallPipelineNativeGit -Arguments @('clone', '-q', $RepoUrl, $cache)
    if ($res.ExitCode -ne 0) {
        throw "Invoke-InstallPipelineGitUrlClone: git clone failed (repoUrl=$RepoUrl, dest=$cache; exitCode=$($res.ExitCode))"
    }
    return $cache
}

# git-url post-clone HEAD resolution for install / update-source when
# `-Branch` is supplied. The work area is a per-action fresh clone (INSTALL.md §2),
# so we resolve <remote>/<branch> (the cloned tip) directly. Restore takes a
# user-supplied `--ref` and goes through Resolve-InstallPipelineRef instead;
# update-current is intentionally unsupported for git-url (INSTALL.md §7).
function Get-InstallPipelineGitUrlRemoteHead {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallArea,
        [string] $Remote = '',
        [Parameter(Mandatory = $true)]
        [string] $Branch
    )

    $cache = Get-InstallPipelineSourceCacheDir -InstallArea $InstallArea
    if (-not (Test-InstallPipelineSourceCachePresent -InstallArea $InstallArea)) {
        throw "Get-InstallPipelineGitUrlRemoteHead: source cache missing: $cache."
    }
    if ([string]::IsNullOrEmpty($Branch)) {
        throw 'Get-InstallPipelineGitUrlRemoteHead: -Branch is required for git-url update-source HEAD resolution.'
    }
    $remoteName = $Remote
    if ([string]::IsNullOrEmpty($remoteName)) { $remoteName = $script:InstallPipelineGitUrlDefaultRemote }

    $refspec = "$remoteName/$Branch"
    $res = Invoke-InstallPipelineNativeGit -CaptureStdout -Arguments @('-C', $cache, 'rev-parse', '--verify', "$refspec^{commit}")
    if ($res.ExitCode -ne 0) {
        throw "Get-InstallPipelineGitUrlRemoteHead: git rev-parse failed for $refspec (cache=$cache; exitCode=$($res.ExitCode))"
    }
    return (@($res.Stdout) -join "`n").Trim()
}

# payload-manifest.json — per-file integrity manifest (per-file SHA-256 model;
# design record preserved in git history).
# Enumerates every regular file under current/<payloadRoots>/** with size +
# lowercase-hex SHA-256, sorted by forward-slash path for determinism.
function New-InstallPipelineManifest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallArea,
        [Parameter(Mandatory = $true)]
        [string] $Head
    )

    $currentDir = Get-InstallPipelineCurrentDir -InstallArea $InstallArea
    if (-not (Test-Path -LiteralPath $currentDir -PathType Container)) {
        throw "New-InstallPipelineManifest: current/ directory missing under InstallArea=$InstallArea"
    }

    $entries = New-Object System.Collections.Generic.List[object]
    foreach ($root in $script:InstallPipelinePayloadRoots) {
        $rootDir = Join-Path $currentDir $root
        if (-not (Test-Path -LiteralPath $rootDir -PathType Container)) { continue }
        $files = Get-ChildItem -LiteralPath $rootDir -Recurse -File -Force
        foreach ($f in $files) {
            $rel = $f.FullName.Substring($currentDir.Length + 1).Replace('\','/')
            $bytes = [System.IO.File]::ReadAllBytes($f.FullName)
            $sha = [System.Security.Cryptography.SHA256]::Create()
            try {
                $hashBytes = $sha.ComputeHash($bytes)
            }
            finally { $sha.Dispose() }
            $hex = ([System.BitConverter]::ToString($hashBytes)).Replace('-','').ToLowerInvariant()
            $entries.Add([PSCustomObject]([ordered]@{
                path   = $rel
                size   = [long]$bytes.LongLength
                sha256 = $hex
            }))
        }
    }
    $sorted = @($entries | Sort-Object -Property path)

    return [PSCustomObject]([ordered]@{
        schemaVersion = $script:InstallPipelineManifestSchemaVersion
        tool          = $script:InstallPipelineTool
        head          = $Head
        createdAt     = [DateTimeOffset]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ')
        payloadRoots  = $script:InstallPipelinePayloadRoots
        files         = $sorted
    })
}

function Write-InstallPipelineManifest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallArea,
        [Parameter(Mandatory = $true)]
        $Manifest
    )
    $path = Get-InstallPipelineManifestPath -InstallArea $InstallArea
    Write-JsonUtf8NoBom -Path $path -Value $Manifest
}

function Read-InstallPipelineManifest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallArea
    )
    $path = Get-InstallPipelineManifestPath -InstallArea $InstallArea
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return $null }
    $raw = Read-Utf8 -Path $path
    $m = $raw | ConvertFrom-Json
    if ($m.schemaVersion -ne $script:InstallPipelineManifestSchemaVersion) {
        throw "Read-InstallPipelineManifest: unknown schemaVersion: $($m.schemaVersion) (this reader supports $($script:InstallPipelineManifestSchemaVersion); fail-fast — silent downgrade is forbidden)."
    }
    return $m
}

# payload-marker.json — presence flag + integrity binding.
function New-InstallPipelineMarker {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Head
    )
    return [PSCustomObject]([ordered]@{
        schemaVersion = $script:InstallPipelineMarkerSchemaVersion
        tool          = $script:InstallPipelineTool
        head          = $Head
        createdAt     = [DateTimeOffset]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ')
        manifestPath  = $script:InstallPipelineManifestName
        payloadRoots  = $script:InstallPipelinePayloadRoots
    })
}

function Write-InstallPipelineMarker {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallArea,
        [Parameter(Mandatory = $true)]
        $Marker
    )
    $path = Get-InstallPipelineMarkerPath -InstallArea $InstallArea
    Write-JsonUtf8NoBom -Path $path -Value $Marker
}

function Read-InstallPipelineMarker {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallArea
    )
    $path = Get-InstallPipelineMarkerPath -InstallArea $InstallArea
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return $null }
    $raw = Read-Utf8 -Path $path
    $m = $raw | ConvertFrom-Json
    if ($m.schemaVersion -ne $script:InstallPipelineMarkerSchemaVersion) {
        throw "Read-InstallPipelineMarker: unknown schemaVersion: $($m.schemaVersion) (this reader supports $($script:InstallPipelineMarkerSchemaVersion); fail-fast — silent downgrade is forbidden)."
    }
    return $m
}

function New-InstallPipelineTuple {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('install', 'update-source', 'update-current', 'restore')]
        [string] $Action,
        [Parameter(Mandatory = $true)]
        [ValidateSet('git-url', 'local-clone')]
        [string] $InstallMode,
        [Parameter(Mandatory = $true)]
        [string] $SourceLocation,
        [Parameter(Mandatory = $true)]
        [string] $ResolvedRefSha,
        [ValidateSet('commit', 'branch', 'tag', 'unknown')]
        [string] $RefKind = 'commit',
        [Parameter(Mandatory = $true)]
        [string] $ToolRoot,
        [Parameter(Mandatory = $true)]
        [string] $ProjectRoot,
        [Parameter(Mandatory = $true)]
        [ValidateSet('fetch-and-update', 'read-current-only')]
        [string] $SourceUpdatePolicy,
        [bool] $SourceCutDetected = $false
    )

    return [PSCustomObject]([ordered]@{
        action             = $Action
        installMode        = $InstallMode
        sourceLocation     = $SourceLocation
        resolvedRefSha     = $ResolvedRefSha
        refKind            = $RefKind
        toolRoot           = $ToolRoot
        projectRoot        = $ProjectRoot
        sourceUpdatePolicy = $SourceUpdatePolicy
        sourceCutDetected  = $SourceCutDetected
    })
}

function Get-InstallPipelineSourceHead {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SourceLocation
    )

    if (-not (Test-Path -LiteralPath $SourceLocation -PathType Container)) {
        throw "Get-InstallPipelineSourceHead: source path not found: $SourceLocation"
    }
    $gitPath = Join-Path -Path $SourceLocation -ChildPath '.git'
    if (-not (Test-Path -LiteralPath $gitPath)) {
        throw "Get-InstallPipelineSourceHead: source is not a git repo (missing .git): $SourceLocation"
    }

    # Route through Invoke-InstallPipelineNativeGit (not raw `& git ... 2>&1`) so that
    # under PS 5.1 + $ErrorActionPreference='Stop' a git stderr line is not promoted to a
    # terminating NativeCommandError before $LASTEXITCODE can be inspected. Mirrors the
    # helper-routed Resolve-InstallPipelineRef below.
    $res = Invoke-InstallPipelineNativeGit -CaptureStdout -Arguments @('-C', $SourceLocation, 'rev-parse', 'HEAD')
    if ($res.ExitCode -ne 0) {
        throw "Get-InstallPipelineSourceHead: git rev-parse HEAD failed (source=$SourceLocation; exitCode=$($res.ExitCode))"
    }
    return (@($res.Stdout) -join "`n").Trim()
}

function Resolve-InstallPipelineRef {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SourceLocation,
        [Parameter(Mandatory = $true)]
        [string] $Ref
    )

    if (-not (Test-Path -LiteralPath $SourceLocation -PathType Container)) {
        throw "Resolve-InstallPipelineRef: source path not found: $SourceLocation"
    }
    if ([string]::IsNullOrEmpty($Ref)) {
        throw 'Resolve-InstallPipelineRef: -Ref is required (restore must use user-specified ref; metadata-derived known-good fallback is forbidden).'
    }

    $verifyArg = ('{0}^{{commit}}' -f $Ref)
    $res = Invoke-InstallPipelineNativeGit -CaptureStdout -Arguments @('-C', $SourceLocation, 'rev-parse', '--verify', $verifyArg)
    if ($res.ExitCode -ne 0) {
        throw "Resolve-InstallPipelineRef: ref not found in source: $Ref (source=$SourceLocation)"
    }
    return (@($res.Stdout) -join "`n").Trim()
}

function Test-InstallPipelineSourceCut {
    [CmdletBinding()]
    param(
        $Metadata,
        [hashtable] $InvocationParams
    )

    if ($null -eq $Metadata) { return $false }
    if ($null -eq $InvocationParams) { return $false }

    $compareFields = @('installMode', 'repoUrl', 'sourcePath', 'toolRoot', 'branch', 'remote')
    $cmp = [System.StringComparison]::OrdinalIgnoreCase
    foreach ($f in $compareFields) {
        if (-not $InvocationParams.ContainsKey($f)) { continue }
        $iv = [string]$InvocationParams[$f]
        if ([string]::IsNullOrEmpty($iv)) { continue }
        $md = [string]$Metadata.$f
        if (-not [string]::Equals($md, $iv, $cmp)) {
            return $true
        }
    }
    return $false
}

function Test-InstallPipelineDogfoodingSource {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SourcePath,
        [Parameter(Mandatory = $true)]
        [string] $ProjectRoot
    )

    if (-not (Test-Path -LiteralPath $SourcePath -PathType Container)) { return $false }
    if (-not (Test-Path -LiteralPath $ProjectRoot -PathType Container)) { return $false }

    $srcFull = [System.IO.Path]::GetFullPath($SourcePath)
    $prFull  = [System.IO.Path]::GetFullPath($ProjectRoot)
    $cmp = [System.StringComparison]::OrdinalIgnoreCase

    if (-not [string]::Equals($srcFull, $prFull, $cmp)) {
        return $false
    }
    return (Test-IsSourceRepoRoot -Path $srcFull)
}

function Invoke-InstallMaterialization {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Tuple,
        [Parameter(Mandatory = $true)]
        [string] $InstallArea
    )

    if (-not (Test-Path -LiteralPath $InstallArea -PathType Container)) {
        throw "Invoke-InstallMaterialization: InstallArea not found: $InstallArea"
    }
    # Relative-InstallArea regression guard (AC-IP-GITURL-TOOLROOT-ABS-1): normalize the
    # InstallArea once so that $tmpZip / $tmpExtract built directly below resolve to absolute
    # paths even when the caller supplied a relative -InstallArea. Get-InstallPipeline*Dir/Path
    # helpers already normalize, but $tmpZip is constructed here without going through them.
    $InstallArea = [System.IO.Path]::GetFullPath($InstallArea)
    # Materialization source = tuple.toolRoot (source-side canonical local
    # ToolRoot). For local-clone that equals tuple.sourceLocation (user-supplied path); for
    # git-url that equals the source cache at <InstallArea>/source-cache (URL goes into
    # tuple.sourceLocation, not into the archive path).
    $sourceLoc = [string]$Tuple.toolRoot
    if (-not (Test-Path -LiteralPath $sourceLoc -PathType Container)) {
        throw "Invoke-InstallMaterialization: source not found: $sourceLoc"
    }
    $gitPath = Join-Path -Path $sourceLoc -ChildPath '.git'
    if (-not (Test-Path -LiteralPath $gitPath)) {
        throw "Invoke-InstallMaterialization: source is not a git repo (missing .git): $sourceLoc"
    }

    # Destination = global install area's current/ payload directory.
    # This is intentionally a different path concept from the resolver tuple's
    # `toolRoot` (= source-side canonical local ToolRoot).
    $currentDir = Get-InstallPipelineCurrentDir -InstallArea $InstallArea

    if (Test-Path -LiteralPath $currentDir) {
        Remove-Item -LiteralPath $currentDir -Recurse -Force
    }
    $null = New-Item -ItemType Directory -Path $currentDir -Force

    $refSha = [string]$Tuple.resolvedRefSha
    $tmpZip = Join-Path $InstallArea ('extract-' + [Guid]::NewGuid().ToString('N') + '.zip')
    $tmpExtract = Join-Path $InstallArea ('extract-' + [Guid]::NewGuid().ToString('N'))

    try {
        # Route through Invoke-InstallPipelineNativeGit (not raw `& git ... 2>&1`): the
        # archive bytes go to $tmpZip via --output, so no stdout capture is needed, but the
        # helper still shields the exit-code check from a PS 5.1 EAP=Stop stderr promotion.
        $res = Invoke-InstallPipelineNativeGit -Arguments @('-C', $sourceLoc, 'archive', '--format=zip', '--output', $tmpZip, $refSha)
        if ($res.ExitCode -ne 0) {
            throw "Invoke-InstallMaterialization: git archive failed for ref $refSha (source=$sourceLoc; exitCode=$($res.ExitCode))"
        }

        $null = New-Item -ItemType Directory -Path $tmpExtract -Force
        Expand-Archive -LiteralPath $tmpZip -DestinationPath $tmpExtract -Force

        foreach ($root in $script:InstallPipelinePayloadRoots) {
            $srcRoot = Join-Path $tmpExtract $root
            if (Test-Path -LiteralPath $srcRoot -PathType Container) {
                $destRoot = Join-Path $currentDir $root
                Copy-Item -LiteralPath $srcRoot -Destination $destRoot -Recurse -Force
            }
        }
    }
    finally {
        if (Test-Path -LiteralPath $tmpZip)     { Remove-Item -LiteralPath $tmpZip -Force -ErrorAction SilentlyContinue }
        if (Test-Path -LiteralPath $tmpExtract) { Remove-Item -LiteralPath $tmpExtract -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

function Read-InstallPipelineMetadata {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallArea
    )

    $path = Get-InstallPipelineMetadataPath -InstallArea $InstallArea
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        return $null
    }
    $raw = Read-Utf8 -Path $path
    $md = $raw | ConvertFrom-Json
    if ($md.schemaVersion -ne $script:InstallPipelineSchemaVersion) {
        throw "Read-InstallPipelineMetadata: unknown schemaVersion: $($md.schemaVersion) (this reader supports $($script:InstallPipelineSchemaVersion); fail-fast — silent downgrade is forbidden)."
    }
    return $md
}

function Write-InstallPipelineMetadata {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallArea,
        [Parameter(Mandatory = $true)]
        $Metadata
    )
    $path = Get-InstallPipelineMetadataPath -InstallArea $InstallArea
    Write-JsonUtf8NoBom -Path $path -Value $Metadata
}

function New-InstallPipelineMetadata {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Tuple,
        [string] $Branch = '',
        [string] $Remote = ''
    )

    $now = [DateTimeOffset]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ')
    $repoUrl = ''
    $sourcePath = ''
    if ($Tuple.installMode -eq 'git-url')     { $repoUrl    = [string]$Tuple.sourceLocation }
    if ($Tuple.installMode -eq 'local-clone') { $sourcePath = [string]$Tuple.sourceLocation }

    # toolRoot semantics under the run-scoped temporary work area policy (INSTALL.md §2):
    # local-clone: source is the user-supplied path → stable, recorded as identity hint.
    # git-url    : source is a transient work area cleaned up at end of action → no stable
    #              local path to record. metadata.toolRoot is intentionally empty for git-url.
    $toolRootForMetadata = ''
    if ($Tuple.installMode -eq 'local-clone') { $toolRootForMetadata = [string]$Tuple.toolRoot }

    return [PSCustomObject]([ordered]@{
        schemaVersion         = $script:InstallPipelineSchemaVersion
        tool                  = $script:InstallPipelineTool
        installMode           = [string]$Tuple.installMode
        repoUrl               = $repoUrl
        sourcePath            = $sourcePath
        toolRoot              = $toolRootForMetadata
        branch                = $Branch
        remote                = $Remote
        installedHead         = [string]$Tuple.resolvedRefSha
        lastUpdatedHead       = [string]$Tuple.resolvedRefSha
        installedAt           = $now
        lastUpdatedAt         = $now
        targetFootprintPolicy = $script:InstallPipelineFootprint
        managedBy             = $script:InstallPipelineManagedBy
    })
}

function Invoke-InstallPipelineDispatch {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Tuple,
        [Parameter(Mandatory = $true)]
        [string] $InstallArea,
        [string] $Branch = '',
        [string] $Remote = ''
    )

    if ($Tuple.sourceCutDetected) {
        throw 'Invoke-InstallPipelineDispatch: source-cut detected on resolved tuple. Source-cut handling is a separate explicit user-approved scope and is not auto-resolved here.'
    }

    # Pre-materialization fail-fast checks. None of these may mutate current/.
    $existing = Read-InstallPipelineMetadata -InstallArea $InstallArea

    if ($Tuple.action -ne 'install' -and $null -eq $existing) {
        # update-source / update-current / restore require existing install metadata.
        # Reject BEFORE Invoke-InstallMaterialization so the existing current/ payload
        # (if any) is not wiped by a request that we cannot complete.
        throw "Invoke-InstallPipelineDispatch: action $($Tuple.action) requires existing install metadata; none found at $InstallArea (run -Action install first)."
    }

    # Source-repo multi-marker check (Test-IsSourceRepoRoot, 3-marker AND): the source we are about to
    # archive from must be a valid ai-harness source repo. Apply to both modes — for
    # local-clone the source is tuple.sourceLocation (user-supplied path), for git-url
    # the source is tuple.toolRoot (= cache after clone). Arbitrary git repos / arbitrary
    # URLs must not pass the install / update / restore pipeline.
    $d3Target = [string]$Tuple.toolRoot
    if (-not (Test-IsSourceRepoRoot -Path $d3Target)) {
        $hintLoc = [string]$Tuple.sourceLocation
        throw "Invoke-InstallPipelineDispatch: source is not a valid ai-harness source repo (D3 multi-marker check failed) at $d3Target (sourceLocation=$hintLoc). Required markers: scripts/verify-ps1.ps1, templates/review-input.md, config/reviewer.json."
    }

    Invoke-InstallMaterialization -Tuple $Tuple -InstallArea $InstallArea

    # Phase 3.5: materialize the managed root README (operator landing page) at <InstallArea>/README.md
    # from the just-materialized in-payload template. Template-conditional: a no-op when the payload
    # does not carry the template. Both install and update-source reach this path (dispatch is the
    # single orchestration point), so the root README is created on fresh install and overwritten on
    # update-source. Verified later by Invoke-InstallPipelineVerify (byte-identity vs the template).
    $null = Set-InstallPipelineRootReadme -InstallArea $InstallArea

    # Manifest + marker write hook — right after materialization,
    # before install.json. install.json lastUpdatedHead must equal manifest.head and
    # marker.head; the verify hook re-checks that binding.
    $manifest = New-InstallPipelineManifest -InstallArea $InstallArea -Head ([string]$Tuple.resolvedRefSha)
    Write-InstallPipelineManifest -InstallArea $InstallArea -Manifest $manifest
    $marker = New-InstallPipelineMarker -Head ([string]$Tuple.resolvedRefSha)
    Write-InstallPipelineMarker -InstallArea $InstallArea -Marker $marker

    $now = [DateTimeOffset]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ')
    if ($Tuple.action -eq 'install') {
        $md = New-InstallPipelineMetadata -Tuple $Tuple -Branch $Branch -Remote $Remote
        Write-InstallPipelineMetadata -InstallArea $InstallArea -Metadata $md
    }
    else {
        $existing.lastUpdatedHead = [string]$Tuple.resolvedRefSha
        $existing.lastUpdatedAt   = $now
        # Normalize toolRoot to the current run-scoped policy (INSTALL.md §2).
        # For git-url the work area is transient and metadata.toolRoot must be empty;
        # this also overrides any leftover non-empty toolRoot from a pre-reconciliation
        # install.json so successive update/restore cycles converge on the new policy.
        if ($Tuple.installMode -eq 'git-url') {
            $existing.toolRoot = ''
        }
        Write-InstallPipelineMetadata -InstallArea $InstallArea -Metadata $existing
    }
}

function Invoke-InstallPipelineVerify {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallArea
    )

    $errors = New-Object System.Collections.Generic.List[string]

    $currentDir = Get-InstallPipelineCurrentDir -InstallArea $InstallArea
    if (-not (Test-Path -LiteralPath $currentDir -PathType Container)) {
        $errors.Add("current/ directory missing under InstallArea=$InstallArea")
    }
    else {
        foreach ($root in $script:InstallPipelinePayloadRoots) {
            $rPath = Join-Path $currentDir $root
            if (-not (Test-Path -LiteralPath $rPath -PathType Container)) {
                $errors.Add("runtime payload root missing: current/$root")
            }
        }
    }

    $md = $null
    try {
        $md = Read-InstallPipelineMetadata -InstallArea $InstallArea
    }
    catch {
        $errors.Add(('metadata read failed: {0}' -f $_.Exception.Message))
    }
    # A missing install.json must fail verify rather than silently skipping all metadata
    # strictness and the manifest/marker-to-metadata binding. Mirrors the manifest/marker
    # missing checks below. The read-failed branch already reported, so do not double-report.
    if ($null -eq $md -and -not ($errors -match 'metadata read failed')) {
        $errors.Add(('metadata missing: {0}' -f (Get-InstallPipelineMetadataPath -InstallArea $InstallArea)))
    }

    if ($null -ne $md) {
        # Exact field-set strictness: install.json must carry exactly the known field set
        # (no missing, no unexpected). Comparison is case-sensitive (-ccontains/-cnotcontains)
        # so JSON key casing is exact — a key like `Branch` does NOT satisfy required `branch`
        # (it is reported as both a missing `branch` and an unexpected `Branch`). schemaVersion
        # mismatch is already fail-fast in Read-InstallPipelineMetadata.
        $actualFields = @($md.PSObject.Properties.Name)
        $missingFields = @($script:InstallPipelineMetadataFields | Where-Object { $actualFields -cnotcontains $_ })
        foreach ($f in $missingFields) {
            $errors.Add("metadata missing required field: $f")
        }
        foreach ($f in $actualFields) {
            if ($script:InstallPipelineMetadataFields -cnotcontains $f) {
                $errors.Add("metadata has unexpected field: $f")
            }
        }

        # Value-level checks read required properties directly; under Set-StrictMode -Version
        # Latest accessing a missing property throws a terminating error. Run them only once
        # the field set is structurally complete, so a missing required field yields a
        # structured ok=false error instead of crashing verify.
        if ($missingFields.Count -eq 0) {
            if ($md.tool -ne $script:InstallPipelineTool) {
                $errors.Add("metadata.tool mismatch: $($md.tool) (expected $script:InstallPipelineTool)")
            }
            if (@('git-url', 'local-clone') -notcontains $md.installMode) {
                $errors.Add("metadata.installMode invalid: $($md.installMode)")
            }
            if ([string]::IsNullOrEmpty([string]$md.installedHead)) {
                $errors.Add('metadata.installedHead empty')
            }
            if ([string]::IsNullOrEmpty([string]$md.lastUpdatedHead)) {
                $errors.Add('metadata.lastUpdatedHead empty')
            }
            # Head fields must be 40-hex commit shas when present. Empty is reported above; this
            # only adds a format error for non-empty malformed values (e.g. truncated/branch name).
            # Match is case-insensitive (PowerShell -notmatch default) — not over-constrained.
            foreach ($shaField in @('installedHead', 'lastUpdatedHead')) {
                $shaVal = [string]$md.$shaField
                if (-not [string]::IsNullOrEmpty($shaVal) -and ($shaVal -notmatch '^[0-9a-f]{40}$')) {
                    $errors.Add("metadata.$shaField is not a 40-hex sha: $shaVal")
                }
            }
            # Mode-conditional source-identity schema (INSTALL.md §4 / §5). Each mode has both
            # a required-non-empty set and a complementary must-be-empty set; the two are kept
            # symmetric so a mismatched install.json (e.g. local-clone carrying a repoUrl) is
            # rejected by canonical verify rather than silently passing.
            if ($md.installMode -eq 'git-url') {
                if ([string]::IsNullOrEmpty([string]$md.repoUrl)) {
                    $errors.Add('metadata.repoUrl empty for git-url mode')
                }
                # git-url records no persistent local identity: source is a transient work area
                # cleaned up at end of action (INSTALL.md §2), so both must be empty.
                if (-not [string]::IsNullOrEmpty([string]$md.sourcePath)) {
                    $errors.Add('metadata.sourcePath must be empty for git-url mode')
                }
                if (-not [string]::IsNullOrEmpty([string]$md.toolRoot)) {
                    $errors.Add('metadata.toolRoot must be empty for git-url mode')
                }
            }
            elseif ($md.installMode -eq 'local-clone') {
                # local-clone records the user-supplied source path identity: sourcePath and
                # toolRoot are required. repoUrl must be empty (mirroring the git-url rule) since
                # the source is a local clone, not a remote URL.
                if ([string]::IsNullOrEmpty([string]$md.sourcePath)) {
                    $errors.Add('metadata.sourcePath empty for local-clone mode')
                }
                if ([string]::IsNullOrEmpty([string]$md.toolRoot)) {
                    $errors.Add('metadata.toolRoot empty for local-clone mode')
                }
                if (-not [string]::IsNullOrEmpty([string]$md.repoUrl)) {
                    $errors.Add('metadata.repoUrl must be empty for local-clone mode')
                }
            }
            if ($md.targetFootprintPolicy -ne $script:InstallPipelineFootprint) {
                $errors.Add("metadata.targetFootprintPolicy mismatch: $($md.targetFootprintPolicy) (expected $script:InstallPipelineFootprint)")
            }
            if ($md.managedBy -ne $script:InstallPipelineManagedBy) {
                $errors.Add("metadata.managedBy mismatch: $($md.managedBy) (expected $script:InstallPipelineManagedBy)")
            }
        }
    }

    # StrictMode-safe snapshot of metadata.lastUpdatedHead for the manifest/marker
    # cross-binding below. $md may be missing required fields (already recorded as field-set
    # errors); reading $md.lastUpdatedHead directly would throw under Set-StrictMode -Version
    # Latest when the field is absent, terminating verify instead of returning ok=false.
    $mdLastUpdatedHead = $null
    if ($null -ne $md -and (@($md.PSObject.Properties.Name) -ccontains 'lastUpdatedHead')) {
        $mdLastUpdatedHead = [string]$md.lastUpdatedHead
    }

    # Manifest + marker verify hook. Both validated independently
    # so a missing manifest does not skip marker reporting, and vice versa.
    $manifest = $null
    try {
        $manifest = Read-InstallPipelineManifest -InstallArea $InstallArea
    }
    catch {
        $errors.Add(('manifest read failed: {0}' -f $_.Exception.Message))
    }
    if ($null -eq $manifest -and -not ($errors -match 'manifest read failed')) {
        $errors.Add(('manifest missing: {0}' -f (Get-InstallPipelineManifestPath -InstallArea $InstallArea)))
    }
    if ($null -ne $manifest) {
        if ($manifest.tool -ne $script:InstallPipelineTool) {
            $errors.Add("manifest.tool mismatch: $($manifest.tool) (expected $script:InstallPipelineTool)")
        }
        if (-not [string]::IsNullOrEmpty($mdLastUpdatedHead)) {
            if ($manifest.head -ne $mdLastUpdatedHead) {
                $errors.Add("manifest.head ($($manifest.head)) does not match metadata.lastUpdatedHead ($mdLastUpdatedHead)")
            }
        }
        $expectedRoots = $script:InstallPipelinePayloadRoots
        $actualRoots = @($manifest.payloadRoots)
        $rootsOk = ($actualRoots.Count -eq $expectedRoots.Count)
        if ($rootsOk) {
            for ($i = 0; $i -lt $expectedRoots.Count; $i++) {
                if ($actualRoots[$i] -ne $expectedRoots[$i]) { $rootsOk = $false; break }
            }
        }
        if (-not $rootsOk) {
            $errors.Add("manifest.payloadRoots mismatch: $($actualRoots -join ',') (expected $($expectedRoots -join ','))")
        }

        if (Test-Path -LiteralPath $currentDir -PathType Container) {
            $manifestPaths = New-Object System.Collections.Generic.HashSet[string]
            foreach ($entry in @($manifest.files)) {
                $rel = [string]$entry.path
                [void]$manifestPaths.Add($rel)
                $abs = Join-Path $currentDir ($rel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
                if (-not (Test-Path -LiteralPath $abs -PathType Leaf)) {
                    $errors.Add("manifest entry missing on disk: $rel")
                    continue
                }
                $bytes = [System.IO.File]::ReadAllBytes($abs)
                if ([long]$bytes.LongLength -ne [long]$entry.size) {
                    $errors.Add("manifest size mismatch: $rel (manifest=$($entry.size); disk=$($bytes.LongLength))")
                    continue
                }
                $sha = [System.Security.Cryptography.SHA256]::Create()
                try { $hashBytes = $sha.ComputeHash($bytes) } finally { $sha.Dispose() }
                $hex = ([System.BitConverter]::ToString($hashBytes)).Replace('-','').ToLowerInvariant()
                if ($hex -ne ([string]$entry.sha256).ToLowerInvariant()) {
                    $errors.Add("manifest sha256 mismatch: $rel (manifest=$($entry.sha256); disk=$hex)")
                }
            }
            # Detect extra files on disk that are not in the manifest.
            foreach ($root in $script:InstallPipelinePayloadRoots) {
                $rootDir = Join-Path $currentDir $root
                if (-not (Test-Path -LiteralPath $rootDir -PathType Container)) { continue }
                $diskFiles = Get-ChildItem -LiteralPath $rootDir -Recurse -File -Force
                foreach ($f in $diskFiles) {
                    $rel = $f.FullName.Substring($currentDir.Length + 1).Replace('\','/')
                    if (-not $manifestPaths.Contains($rel)) {
                        $errors.Add("extra file on disk not in manifest: $rel")
                    }
                }
            }
        }
    }

    $marker = $null
    try {
        $marker = Read-InstallPipelineMarker -InstallArea $InstallArea
    }
    catch {
        $errors.Add(('marker read failed: {0}' -f $_.Exception.Message))
    }
    if ($null -eq $marker -and -not ($errors -match 'marker read failed')) {
        $errors.Add(('marker missing: {0}' -f (Get-InstallPipelineMarkerPath -InstallArea $InstallArea)))
    }
    if ($null -ne $marker) {
        if ($marker.tool -ne $script:InstallPipelineTool) {
            $errors.Add("marker.tool mismatch: $($marker.tool) (expected $script:InstallPipelineTool)")
        }
        if ($marker.manifestPath -ne $script:InstallPipelineManifestName) {
            $errors.Add("marker.manifestPath mismatch: $($marker.manifestPath) (expected $script:InstallPipelineManifestName)")
        }
        # marker.payloadRoots must equal the constant
        # ["config","scripts","snippets","templates"] (manifest 의 payloadRoots 와 동일).
        $expectedRoots = $script:InstallPipelinePayloadRoots
        $markerRoots = @($marker.payloadRoots)
        $markerRootsOk = ($markerRoots.Count -eq $expectedRoots.Count)
        if ($markerRootsOk) {
            for ($i = 0; $i -lt $expectedRoots.Count; $i++) {
                if ($markerRoots[$i] -ne $expectedRoots[$i]) { $markerRootsOk = $false; break }
            }
        }
        if (-not $markerRootsOk) {
            $errors.Add("marker.payloadRoots mismatch: $($markerRoots -join ',') (expected $($expectedRoots -join ','))")
        }
        if ($null -ne $manifest -and $marker.head -ne $manifest.head) {
            $errors.Add("marker.head ($($marker.head)) does not match manifest.head ($($manifest.head))")
        }
        if (-not [string]::IsNullOrEmpty($mdLastUpdatedHead) -and $marker.head -ne $mdLastUpdatedHead) {
            $errors.Add("marker.head ($($marker.head)) does not match metadata.lastUpdatedHead ($mdLastUpdatedHead)")
        }
    }

    # Phase 3.5 / 3.5.1: managed root README verification (template-conditional). The root artifact
    # at <InstallArea>/README.md must be byte-identical (SHA-256) to the in-payload template at
    # current/templates/install-root/...README.md, whose bytes are already covered by the manifest
    # digest above — so this gives the root README transitive integrity without a manifest-schema
    # change. Skip when the payload does not carry the template (pre-Phase-3.5 source / minimal
    # fixture), mirroring the materialization skip. A missing / stale / corrupted root README is an
    # install-integrity failure (verify_failed) recovered by reinstall-first deterministic overwrite
    # (INSTALL.md section 9) — NOT by a no-op self-heal. Single-sourced via Get-InstallPipelineRootReadmeState.
    $rootReadmeState = Get-InstallPipelineRootReadmeState -InstallArea $InstallArea
    if (@('missing','stale') -contains $rootReadmeState.State) {
        $errors.Add($rootReadmeState.Reason)
    }

    return [PSCustomObject]@{
        ok     = ($errors.Count -eq 0)
        errors = @($errors)
    }
}
