Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# install-pipeline-core library — Step 3 3-2~3-5 runtime pipeline (temp-only skeleton).
# Dot-sourced from scripts/install-pipeline.ps1 (CLI entry) and from
# tests/install-pipeline.Tests.ps1 (Pester suite).
#
# Implements the contract from docs/roadmap/global-install-update/
#   STEP3_INSTALL_UPDATE_DECISION_GUIDE.md §12 (runtime pipeline grouping):
#   - 3-2 source / ref resolver (resolved tuple shape).
#   - 3-3 overwrite materialization core (deterministic copy into current/).
#   - 3-4 dispatcher (4 action labels routed through one pipeline shape).
#   - 3-5 verify (minimal: payload roots exist + metadata core fields).
#
# Boundaries kept by this library:
#   - resolver tuple `toolRoot` is source-side canonical local ToolRoot
#     (parent §6 Layer 1 / §11.1 metadata `toolRoot`), NOT the materialization
#     destination. Destination is global install area's current/ — kept as a
#     separate path concept inside Invoke-InstallMaterialization.
#   - metadata schema follows §11 (install.json sibling-of-current/, JSON).
#   - source-cut is detection only; this library never auto-resolves it.
#   - this library never writes outside the caller-supplied InstallArea.

$script:InstallPipelineSchemaVersion = 1
$script:InstallPipelineTool          = 'ai-harness-toolset'
$script:InstallPipelineManagedBy     = 'claude-code'
$script:InstallPipelineFootprint     = 'log-only'
$script:InstallPipelinePayloadRoots  = @('config', 'scripts', 'snippets', 'templates')
$script:InstallPipelineMetadataName  = 'install.json'

function Get-InstallPipelinePayloadRoots {
    return ,$script:InstallPipelinePayloadRoots
}

function Get-InstallPipelineMetadataPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallArea
    )
    return Join-Path -Path $InstallArea -ChildPath $script:InstallPipelineMetadataName
}

function Get-InstallPipelineCurrentDir {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallArea
    )
    return Join-Path -Path $InstallArea -ChildPath 'current'
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

    $output = & git -C $SourceLocation rev-parse HEAD 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Get-InstallPipelineSourceHead: git rev-parse HEAD failed: $output"
    }
    return ($output -join "`n").Trim()
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
    $output = & git -C $SourceLocation rev-parse --verify $verifyArg 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Resolve-InstallPipelineRef: ref not found in source: $Ref (source=$SourceLocation; output=$output)"
    }
    return ($output -join "`n").Trim()
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
    $sourceLoc = [string]$Tuple.sourceLocation
    if (-not (Test-Path -LiteralPath $sourceLoc -PathType Container)) {
        throw "Invoke-InstallMaterialization: source not found: $sourceLoc"
    }
    $gitPath = Join-Path -Path $sourceLoc -ChildPath '.git'
    if (-not (Test-Path -LiteralPath $gitPath)) {
        throw "Invoke-InstallMaterialization: source is not a git repo (missing .git): $sourceLoc"
    }

    # Destination = global install area's current/ payload directory.
    # This is intentionally a different path concept from the resolver tuple's
    # `toolRoot` (= source-side canonical local ToolRoot, parent §6 Layer 1).
    $currentDir = Get-InstallPipelineCurrentDir -InstallArea $InstallArea

    if (Test-Path -LiteralPath $currentDir) {
        Remove-Item -LiteralPath $currentDir -Recurse -Force
    }
    $null = New-Item -ItemType Directory -Path $currentDir -Force

    $refSha = [string]$Tuple.resolvedRefSha
    $tmpZip = Join-Path $InstallArea ('extract-' + [Guid]::NewGuid().ToString('N') + '.zip')
    $tmpExtract = Join-Path $InstallArea ('extract-' + [Guid]::NewGuid().ToString('N'))

    try {
        $arOut = & git -C $sourceLoc archive --format=zip --output $tmpZip $refSha 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "Invoke-InstallMaterialization: git archive failed for ref $refSha (source=$sourceLoc; output=$arOut)"
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

    return [PSCustomObject]([ordered]@{
        schemaVersion         = $script:InstallPipelineSchemaVersion
        tool                  = $script:InstallPipelineTool
        installMode           = [string]$Tuple.installMode
        repoUrl               = $repoUrl
        sourcePath            = $sourcePath
        toolRoot              = [string]$Tuple.toolRoot
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

    if ($Tuple.installMode -eq 'local-clone') {
        # local-clone sourceLocation must be a valid ai-harness source repo
        # (D3 multi-marker, parent §2.2 — "Claude Code 가 현재 repo 검증 ... 하고 canonical local ToolRoot 로 등록한다").
        # Arbitrary git repos must not pass the install / update / restore pipeline.
        $srcLoc = [string]$Tuple.sourceLocation
        if (-not (Test-IsSourceRepoRoot -Path $srcLoc)) {
            throw "Invoke-InstallPipelineDispatch: local-clone sourceLocation is not a valid ai-harness source repo (D3 multi-marker check failed): $srcLoc. Required markers: scripts/verify-ps1.ps1, templates/review-input.md, config/reviewer.json."
        }
    }

    Invoke-InstallMaterialization -Tuple $Tuple -InstallArea $InstallArea

    $now = [DateTimeOffset]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ')
    if ($Tuple.action -eq 'install') {
        $md = New-InstallPipelineMetadata -Tuple $Tuple -Branch $Branch -Remote $Remote
        Write-InstallPipelineMetadata -InstallArea $InstallArea -Metadata $md
    }
    else {
        $existing.lastUpdatedHead = [string]$Tuple.resolvedRefSha
        $existing.lastUpdatedAt   = $now
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

    if ($null -ne $md) {
        if ($md.tool -ne $script:InstallPipelineTool) {
            $errors.Add("metadata.tool mismatch: $($md.tool) (expected $script:InstallPipelineTool)")
        }
        if (@('git-url', 'local-clone') -notcontains $md.installMode) {
            $errors.Add("metadata.installMode invalid: $($md.installMode)")
        }
        if ([string]::IsNullOrEmpty([string]$md.toolRoot)) {
            $errors.Add('metadata.toolRoot empty')
        }
        if ([string]::IsNullOrEmpty([string]$md.installedHead)) {
            $errors.Add('metadata.installedHead empty')
        }
        if ([string]::IsNullOrEmpty([string]$md.lastUpdatedHead)) {
            $errors.Add('metadata.lastUpdatedHead empty')
        }
        if ($md.installMode -eq 'git-url' -and [string]::IsNullOrEmpty([string]$md.repoUrl)) {
            $errors.Add('metadata.repoUrl empty for git-url mode')
        }
        if ($md.installMode -eq 'local-clone' -and [string]::IsNullOrEmpty([string]$md.sourcePath)) {
            $errors.Add('metadata.sourcePath empty for local-clone mode')
        }
        if ($md.targetFootprintPolicy -ne $script:InstallPipelineFootprint) {
            $errors.Add("metadata.targetFootprintPolicy mismatch: $($md.targetFootprintPolicy) (expected $script:InstallPipelineFootprint)")
        }
        if ($md.managedBy -ne $script:InstallPipelineManagedBy) {
            $errors.Add("metadata.managedBy mismatch: $($md.managedBy) (expected $script:InstallPipelineManagedBy)")
        }
    }

    return [PSCustomObject]@{
        ok     = ($errors.Count -eq 0)
        errors = @($errors)
    }
}
