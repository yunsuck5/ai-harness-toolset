Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-ProjectRoot {
    [CmdletBinding()]
    param(
        [string] $ProjectRoot
    )

    if ([string]::IsNullOrEmpty($ProjectRoot)) {
        $ProjectRoot = (Get-Location).ProviderPath
        $gitPath = Join-Path -Path $ProjectRoot -ChildPath '.git'
        # Accept both .git directory (standard repo) and .git file pointer
        # (git worktree / submodule). Only advise when neither shape is present.
        $gitIsDir  = Test-Path -LiteralPath $gitPath -PathType Container
        $gitIsFile = Test-Path -LiteralPath $gitPath -PathType Leaf
        if (-not ($gitIsDir -or $gitIsFile)) {
            Write-Host ('Get-ProjectRoot: WARN ProjectRoot resolved to CWD without a .git entry: {0}' -f $ProjectRoot)
        }
    }
    if (-not (Test-Path -LiteralPath $ProjectRoot -PathType Container)) {
        throw "Get-ProjectRoot: directory not found: $ProjectRoot"
    }
    return [System.IO.Path]::GetFullPath($ProjectRoot)
}

function Test-IsSourceRepoRoot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path
    )

    $markers = @(
        'scripts/verify-ps1.ps1',
        'templates/review-input.md',
        'config/reviewer.json'
    )
    foreach ($m in $markers) {
        $full = Join-Path -Path $Path -ChildPath $m
        if (-not (Test-Path -LiteralPath $full -PathType Leaf)) {
            return $false
        }
    }
    return $true
}

function Get-StableInstallAreaCandidate {
    [CmdletBinding()]
    param()

    # Global stable INSTALL AREA (install root): %USERPROFILE%\ai-harness-toolset.
    # Single source of truth for the default install area — the directory that CONTAINS
    # current/, install.json, payload-manifest.json, payload-marker.json, and the managed
    # root README. It is vendor-neutral (NOT under %USERPROFILE%\.claude): the activation
    # surfaces (Claude CLAUDE.md / skills, Codex AGENTS.md) keep their vendor-specific homes
    # under .claude / .codex, but the toolset payload itself lives here. install / update /
    # uninstall all derive their default InstallArea from this one function, and the stable
    # ToolRoot below derives from it too.
    #
    # The user-profile base is read from $env:USERPROFILE — the SAME convention every lifecycle
    # wrapper already uses for its ClaudeHome / CodexHome defaults (Join-Path $env:USERPROFILE
    # '.claude' / '.codex'), so the install area and the activation homes share one profile base.
    # This is also the single lower-level test-isolation seam: a child process launched with an
    # overridden %USERPROFILE% resolves a sandbox canonical area, so the destructive uninstall guard
    # is testable without any operator-facing override parameter.
    $userProfile = $env:USERPROFILE
    if ([string]::IsNullOrEmpty($userProfile)) {
        return $null
    }
    $candidate = Join-Path -Path $userProfile -ChildPath 'ai-harness-toolset'
    return [System.IO.Path]::GetFullPath($candidate)
}

function Get-StableToolRootCandidate {
    [CmdletBinding()]
    param()

    # Global stable ToolRoot: <stable install area>\current
    # (= %USERPROFILE%\ai-harness-toolset\current). Derived from
    # Get-StableInstallAreaCandidate so the install-area location has a single definition.
    # This is the default ToolRoot for shared / global mode. The -ToolRoot parameter and the
    # AI_HARNESS_TOOL_ROOT env var are higher-priority overrides; this path is the standing
    # default when no override is in play.
    $area = Get-StableInstallAreaCandidate
    if ([string]::IsNullOrEmpty($area)) {
        return $null
    }
    $candidate = Join-Path -Path $area -ChildPath 'current'
    return [System.IO.Path]::GetFullPath($candidate)
}

function Test-IsValidToolRootPayload {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path
    )

    # A ToolRoot payload is valid when the canonical entrypoint script is present.
    # An existing-but-incomplete payload is an operator error that must fail fast
    # rather than be silently skipped.
    $entry = Join-Path -Path $Path -ChildPath 'scripts/review-prepare.ps1'
    return (Test-Path -LiteralPath $entry -PathType Leaf)
}

function Get-ToolRoot {
    [CmdletBinding()]
    param(
        [string] $ToolRoot,
        [string] $ProjectRoot,
        # Optional override for the global stable install path (channel 3).
        # Production callers leave this empty so it resolves to
        # %USERPROFILE%\ai-harness-toolset\current; tests inject a
        # controlled path for deterministic isolation.
        [string] $StableToolRoot
    )

    $tried = New-Object System.Collections.Generic.List[string]

    # channel 1 — explicit -ToolRoot parameter (highest priority).
    if (-not [string]::IsNullOrEmpty($ToolRoot)) {
        if (-not (Test-Path -LiteralPath $ToolRoot -PathType Container)) {
            throw ('Get-ToolRoot: channel 1 (-ToolRoot parameter): directory not found: {0}. Provide a valid existing directory or omit -ToolRoot to fall back to env / stable / dogfooding channels.' -f $ToolRoot)
        }
        return [System.IO.Path]::GetFullPath($ToolRoot)
    }
    $tried.Add('channel 1 (-ToolRoot parameter): not provided') | Out-Null

    # channel 2 — AI_HARNESS_TOOL_ROOT env var (override / debug / development validation).
    $envTool = [System.Environment]::GetEnvironmentVariable('AI_HARNESS_TOOL_ROOT')
    if (-not [string]::IsNullOrEmpty($envTool)) {
        if (-not (Test-Path -LiteralPath $envTool -PathType Container)) {
            throw ('Get-ToolRoot: channel 2 (env AI_HARNESS_TOOL_ROOT): directory not found: {0}. Set AI_HARNESS_TOOL_ROOT to an existing directory or unset it to fall back to stable / dogfooding channels.' -f $envTool)
        }
        return [System.IO.Path]::GetFullPath($envTool)
    }
    $tried.Add('channel 2 (env AI_HARNESS_TOOL_ROOT): not set or empty') | Out-Null

    # channel 3 — global stable install (%USERPROFILE%\ai-harness-toolset\current).
    # This is the default ToolRoot for shared / global mode.
    #   - absent directory  -> skip to fallback channels.
    #   - present directory -> must be a complete payload, otherwise fail fast.
    if ([string]::IsNullOrEmpty($StableToolRoot)) {
        $StableToolRoot = Get-StableToolRootCandidate
    }
    if (-not [string]::IsNullOrEmpty($StableToolRoot)) {
        if (Test-Path -LiteralPath $StableToolRoot -PathType Container) {
            if (-not (Test-IsValidToolRootPayload -Path $StableToolRoot)) {
                throw ('Get-ToolRoot: channel 3 (global stable install): directory exists but payload is incomplete: {0}. Expected entrypoint scripts/review-prepare.ps1 was not found. Reinstall the global stable ToolRoot (delete-and-reinstall) or use -ToolRoot / AI_HARNESS_TOOL_ROOT to point at a complete payload.' -f $StableToolRoot)
            }
            return [System.IO.Path]::GetFullPath($StableToolRoot)
        }
        $tried.Add(('channel 3 (global stable install): not present at {0}' -f $StableToolRoot)) | Out-Null
    }
    else {
        $tried.Add('channel 3 (global stable install): user profile path unavailable') | Out-Null
    }

    $project = Get-ProjectRoot -ProjectRoot $ProjectRoot

    # channel 4 — self-target / dogfooding source repo multi-marker.
    if (Test-IsSourceRepoRoot -Path $project) {
        return $project
    }
    $tried.Add(('channel 4 (dogfooding multi-marker on ProjectRoot={0}): markers missing' -f $project)) | Out-Null

    # channel 5 — nothing resolved: no channel produced a ToolRoot, so fail fast with the full trace.
    $trace = $tried -join '; '
    throw ('Get-ToolRoot: no ToolRoot channel could be resolved. Tried: {0}. Set AI_HARNESS_TOOL_ROOT, pass -ToolRoot, or install the global stable ToolRoot.' -f $trace)
}

function Get-ProjectLogRoot {
    [CmdletBinding()]
    param(
        [string] $ProjectRoot
    )

    $project = Get-ProjectRoot -ProjectRoot $ProjectRoot
    $logPath = Join-Path -Path $project -ChildPath 'log'
    return [System.IO.Path]::GetFullPath($logPath)
}

function Assert-InProjectLogRoot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path,
        [Parameter(Mandatory = $true)]
        [string] $ProjectLogRoot
    )

    if ([string]::IsNullOrEmpty($ProjectLogRoot)) {
        throw 'Assert-InProjectLogRoot: -ProjectLogRoot is required.'
    }

    $logFull = [System.IO.Path]::GetFullPath($ProjectLogRoot)
    $full    = [System.IO.Path]::GetFullPath($Path)

    $sep = [System.IO.Path]::DirectorySeparatorChar
    $baseNorm = $logFull.TrimEnd($sep)
    $cmp = [System.StringComparison]::OrdinalIgnoreCase

    if ([string]::Equals($full, $baseNorm, $cmp)) {
        return $true
    }
    $prefix = $baseNorm + $sep
    if ($full.StartsWith($prefix, $cmp)) {
        return $true
    }
    throw "Assert-InProjectLogRoot: path is outside ProjectLogRoot. Path=$full ProjectLogRoot=$baseNorm"
}

function Resolve-ProjectRelativePath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path,
        [string] $ProjectRoot
    )

    $project = Get-ProjectRoot -ProjectRoot $ProjectRoot
    $full = [System.IO.Path]::GetFullPath($Path)

    $sep = [System.IO.Path]::DirectorySeparatorChar
    $projectNorm = $project.TrimEnd($sep)
    $cmp = [System.StringComparison]::OrdinalIgnoreCase

    if ([string]::Equals($full, $projectNorm, $cmp)) {
        return '.'
    }
    $prefix = $projectNorm + $sep
    if ($full.StartsWith($prefix, $cmp)) {
        return $full.Substring($prefix.Length)
    }
    return $full
}

function Assert-InProjectRoot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path,
        [string] $ProjectRoot
    )

    $project = Get-ProjectRoot -ProjectRoot $ProjectRoot
    $full = [System.IO.Path]::GetFullPath($Path)

    $sep = [System.IO.Path]::DirectorySeparatorChar
    $projectNorm = $project.TrimEnd($sep)
    $cmp = [System.StringComparison]::OrdinalIgnoreCase

    if ([string]::Equals($full, $projectNorm, $cmp)) {
        return $true
    }
    $prefix = $projectNorm + $sep
    if ($full.StartsWith($prefix, $cmp)) {
        return $true
    }
    throw "Assert-InProjectRoot: path is outside ProjectRoot. Path=$full ProjectRoot=$projectNorm"
}

function Test-ValidReviewTaskId {
    [CmdletBinding()]
    param(
        [string] $Value
    )

    if ([string]::IsNullOrEmpty($Value)) { return $false }
    if ($Value.Contains('..')) { return $false }
    return ($Value -match '^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$')
}

function Assert-ValidReviewTaskId {
    [CmdletBinding()]
    param(
        [string] $Value
    )

    if (-not (Test-ValidReviewTaskId -Value $Value)) {
        throw "Assert-ValidReviewTaskId: invalid ReviewTaskId: '$Value'"
    }
    return $true
}

function Test-ValidPass {
    [CmdletBinding()]
    param(
        [string] $Value
    )

    if ([string]::IsNullOrEmpty($Value)) { return $false }
    return ($Value -cmatch '^pass-(0[1-9]|[1-9][0-9])$')
}

function Assert-ValidPass {
    [CmdletBinding()]
    param(
        [string] $Value
    )

    if (-not (Test-ValidPass -Value $Value)) {
        throw "Assert-ValidPass: invalid pass identifier (expected pass-NN with NN in 01..99): '$Value'"
    }
    return $true
}

function Test-ValidPerspective {
    [CmdletBinding()]
    param(
        [string] $Value
    )

    # A <perspective> is operator-supplied and becomes a single filesystem path
    # segment in the C1 three-level layout (<task>/<perspective>/pass-NN/). It must
    # therefore pass the SAME safety rules as Test-ValidReviewTaskId, plus a pass-NN
    # exclusion so a perspective directory can never be confused with a pass directory:
    #   (i)   single path segment (no nesting),
    #   (ii)  no parent-dir traversal token ('..'),
    #   (iii) no path separators ('/' or '\'),
    #   (iv)  safe charset + length (same shape as Test-ValidReviewTaskId),
    #   (v)   not the pass-NN shape (pass-\d\d), which would make old/new layout
    #         resolution ambiguous (a perspective named like a pass directory).
    if ([string]::IsNullOrEmpty($Value)) { return $false }
    if ($Value.Contains('..')) { return $false }
    if ($Value.Contains('/') -or $Value.Contains('\')) { return $false }
    # Case-insensitive so PASS-01 / Pass-99 are rejected too (Windows filesystem
    # comparisons are case-insensitive, so a wrong-case pass-shaped name would still
    # collide with a real pass directory).
    if ($Value -imatch '^pass-\d\d$') { return $false }
    return ($Value -match '^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$')
}

function Assert-ValidPerspective {
    [CmdletBinding()]
    param(
        [string] $Value
    )

    if (-not (Test-ValidPerspective -Value $Value)) {
        throw "Assert-ValidPerspective: invalid Perspective (expected a single safe path segment, not '..'/separator/pass-NN, charset [A-Za-z0-9._-], max 64): '$Value'"
    }
    return $true
}

function Get-ReviewTaskRoot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $ProjectLogRoot,
        [Parameter(Mandatory = $true)]
        [string] $ReviewTaskId
    )

    [void] (Assert-ValidReviewTaskId -Value $ReviewTaskId)
    $reviewBase = Join-Path -Path $ProjectLogRoot -ChildPath 'review'
    $taskDir = Join-Path -Path $reviewBase -ChildPath $ReviewTaskId
    return [System.IO.Path]::GetFullPath($taskDir)
}

function Get-ReviewPassParent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $ProjectLogRoot,
        [Parameter(Mandatory = $true)]
        [string] $ReviewTaskId,
        # Required review viewpoint (strict C1 — there is no two-level fallback). Empty /
        # missing is rejected here (Assert-ValidPerspective rejects empty), never silently
        # resolved to the task dir.
        [string] $Perspective
    )

    # The directory that directly holds pass-NN children for this (task, perspective):
    # <taskDir>/<perspective>. There is no two-level (task-dir-direct) form — the canonical
    # layout is always three-level. Get-NextPassName scans this dir, so pass numbering is
    # per-perspective. operator-supplied perspective is validated; no inference here.
    [void] (Assert-ValidPerspective -Value $Perspective)
    $taskDir = Get-ReviewTaskRoot -ProjectLogRoot $ProjectLogRoot -ReviewTaskId $ReviewTaskId
    $perspectiveDir = Join-Path -Path $taskDir -ChildPath $Perspective
    return [System.IO.Path]::GetFullPath($perspectiveDir)
}

function Get-ReviewPassDir {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $ProjectLogRoot,
        [Parameter(Mandatory = $true)]
        [string] $ReviewTaskId,
        [Parameter(Mandatory = $true)]
        [string] $Pass,
        # Required review viewpoint. The pass dir is always the three-level canonical layout
        # <taskDir>/<perspective>/<pass>. Empty / missing perspective fails fast (via
        # Get-ReviewPassParent -> Assert-ValidPerspective); there is no two-level fallback.
        [string] $Perspective
    )

    [void] (Assert-ValidPass -Value $Pass)
    $parent = Get-ReviewPassParent -ProjectLogRoot $ProjectLogRoot -ReviewTaskId $ReviewTaskId -Perspective $Perspective
    $passDir = Join-Path -Path $parent -ChildPath $Pass
    $full = [System.IO.Path]::GetFullPath($passDir)
    # Task-root containment (defense-in-depth). Perspective segment validation already
    # blocks '..' and separators, but the plan requires proving the constructed pass dir
    # stayed inside the INTENDED <taskDir>/ — review-root containment alone is necessary
    # but not sufficient (it cannot prove the path did not traverse into a sibling task).
    [void] (Assert-InTaskRoot -Path $full -ProjectLogRoot $ProjectLogRoot -ReviewTaskId $ReviewTaskId)
    return $full
}

function Assert-InReviewRoot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path,
        [Parameter(Mandatory = $true)]
        [string] $ProjectLogRoot
    )

    if ([string]::IsNullOrEmpty($ProjectLogRoot)) {
        throw 'Assert-InReviewRoot: -ProjectLogRoot is required.'
    }

    [void] (Assert-InProjectLogRoot -Path $Path -ProjectLogRoot $ProjectLogRoot)

    $logFull = [System.IO.Path]::GetFullPath($ProjectLogRoot)
    $reviewBase = [System.IO.Path]::GetFullPath((Join-Path -Path $logFull -ChildPath 'review'))
    $full = [System.IO.Path]::GetFullPath($Path)

    $sep = [System.IO.Path]::DirectorySeparatorChar
    $baseNorm = $reviewBase.TrimEnd($sep)
    $cmp = [System.StringComparison]::OrdinalIgnoreCase

    if ([string]::Equals($full, $baseNorm, $cmp)) {
        return $true
    }
    $prefix = $baseNorm + $sep
    if ($full.StartsWith($prefix, $cmp)) {
        return $true
    }
    throw "Assert-InReviewRoot: path is outside review root. Path=$full ReviewRoot=$baseNorm"
}

function Assert-InTaskRoot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path,
        [Parameter(Mandatory = $true)]
        [string] $ProjectLogRoot,
        [Parameter(Mandatory = $true)]
        [string] $ReviewTaskId
    )

    if ([string]::IsNullOrEmpty($ProjectLogRoot)) {
        throw 'Assert-InTaskRoot: -ProjectLogRoot is required.'
    }

    # Review-root containment is necessary but NOT sufficient: it only proves the path is
    # somewhere under <logRoot>/review/, not that it stayed inside the intended task. So
    # first assert review-root containment, then assert the stricter <taskDir>/ containment.
    [void] (Assert-InReviewRoot -Path $Path -ProjectLogRoot $ProjectLogRoot)

    $taskDir = Get-ReviewTaskRoot -ProjectLogRoot $ProjectLogRoot -ReviewTaskId $ReviewTaskId
    $full = [System.IO.Path]::GetFullPath($Path)

    $sep = [System.IO.Path]::DirectorySeparatorChar
    $baseNorm = $taskDir.TrimEnd($sep)
    $cmp = [System.StringComparison]::OrdinalIgnoreCase

    if ([string]::Equals($full, $baseNorm, $cmp)) {
        return $true
    }
    $prefix = $baseNorm + $sep
    if ($full.StartsWith($prefix, $cmp)) {
        return $true
    }
    throw "Assert-InTaskRoot: path is outside task root (would traverse out of the intended task). Path=$full TaskRoot=$baseNorm"
}

function Get-NextPassName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $TaskDir
    )

    if (-not (Test-Path -LiteralPath $TaskDir -PathType Container)) {
        return 'pass-01'
    }
    $maxN = 0
    $entries = Get-ChildItem -LiteralPath $TaskDir -Directory -ErrorAction SilentlyContinue
    foreach ($entry in $entries) {
        if ($entry.Name -cmatch '^pass-(0[1-9]|[1-9][0-9])$') {
            $n = [int]$Matches[1]
            if ($n -gt $maxN) { $maxN = $n }
        }
    }
    $next = $maxN + 1
    if ($next -gt 99) {
        throw "Get-NextPassName: pass-NN range exhausted (max 99) under $TaskDir. Stop and report the exhausted selected perspective; do not allocate a lower pass or another ReviewTaskId automatically."
    }
    return ('pass-{0:00}' -f $next)
}

function Assert-ReviewPass99NotOccupied {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $PassParent,
        [switch] $RequireExistingParent
    )

    if ([string]::IsNullOrEmpty($PassParent)) {
        throw 'Assert-ReviewPass99NotOccupied: -PassParent is required.'
    }

    $parentFull = [System.IO.Path]::GetFullPath($PassParent)
    try {
        $parentItem = Get-Item -LiteralPath $parentFull -Force -ErrorAction Stop
    }
    catch {
        $isAbsent = ($_.CategoryInfo.Category -eq [System.Management.Automation.ErrorCategory]::ObjectNotFound)
        if ($isAbsent -and (-not $RequireExistingParent)) {
            return $true
        }
        throw ('Assert-ReviewPass99NotOccupied: could not inspect selected perspective parent: {0}. Cause: {1}' -f
            $parentFull, $_.Exception.Message)
    }
    if (-not $parentItem.PSIsContainer) {
        throw "Assert-ReviewPass99NotOccupied: selected perspective parent is not a directory: $parentFull"
    }
    if (Test-ReviewFileSystemInfoIsReparsePoint -Item $parentItem) {
        throw "Assert-ReviewPass99NotOccupied: selected perspective parent is a reparse point: $parentFull"
    }

    $pass99Full = [System.IO.Path]::GetFullPath((Join-Path -Path $parentFull -ChildPath 'pass-99'))
    try {
        foreach ($entry in [System.IO.Directory]::EnumerateFileSystemEntries($parentFull)) {
            if ([string]::Equals(
                [System.IO.Path]::GetFullPath($entry),
                $pass99Full,
                [System.StringComparison]::OrdinalIgnoreCase
            )) {
                $occupied = New-Object System.InvalidOperationException(
                    "Assert-ReviewPass99NotOccupied: pass-NN range exhausted (max 99) under $parentFull. Stop and report the exhausted selected perspective; do not allocate a lower pass or another ReviewTaskId automatically."
                )
                $occupied.Data['AiHarnessReviewPass99Reason'] = 'occupied'
                throw $occupied
            }
        }
    }
    catch {
        if ($_.Exception.Data['AiHarnessReviewPass99Reason'] -eq 'occupied') {
            throw
        }
        throw ('Assert-ReviewPass99NotOccupied: could not inspect pass-99 occupancy under selected perspective: {0}. Cause: {1}' -f
            $parentFull, $_.Exception.Message)
    }

    return $true
}

function Test-ReviewFileSystemInfoIsReparsePoint {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Item
    )

    if ($null -eq $Item) {
        throw 'Test-ReviewFileSystemInfoIsReparsePoint: -Item is required.'
    }

    return (($Item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0)
}

function Initialize-ReviewPathEntryNativeType {
    [CmdletBinding()]
    param()

    if ($null -ne ('AiHarnessToolset.Native.ReviewPathEntry' -as [type])) {
        return
    }

    $source = @'
using System.Runtime.InteropServices;

namespace AiHarnessToolset.Native
{
    public static class ReviewPathEntry
    {
        [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        public static extern uint GetFileAttributesW(string path);
    }
}
'@

    Add-Type -TypeDefinition $source -Language CSharp -ErrorAction Stop
}

function Get-ReviewPathEntryAttributes {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path
    )

    if ([string]::IsNullOrEmpty($Path)) {
        throw 'Get-ReviewPathEntryAttributes: -Path is required.'
    }

    $full = [System.IO.Path]::GetFullPath($Path)
    [void] (Initialize-ReviewPathEntryNativeType)
    $attributes = [AiHarnessToolset.Native.ReviewPathEntry]::GetFileAttributesW($full)
    if ($attributes -ne [uint32]::MaxValue) {
        return [pscustomobject]@{
            Exists     = $true
            Attributes = [System.IO.FileAttributes] $attributes
        }
    }

    # Capture the thread-local error immediately. Only actual path absence is safe to collapse into
    # the first-missing-component result; every other inspection failure stays fail-closed.
    $errorCode = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
    if ($errorCode -eq 2 -or $errorCode -eq 3) {
        return [pscustomobject]@{
            Exists     = $false
            Attributes = [System.IO.FileAttributes] 0
        }
    }

    $detail = (New-Object System.ComponentModel.Win32Exception($errorCode)).Message
    throw "Get-ReviewPathEntryAttributes: native entry inspection failed (Win32 error $errorCode): $detail Path=$full"
}

function Assert-NoStaticReparsePointInReviewPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $RootPath,
        [Parameter(Mandatory = $true)]
        [string] $Path
    )

    if ([string]::IsNullOrEmpty($RootPath)) {
        throw 'Assert-NoStaticReparsePointInReviewPath: -RootPath is required.'
    }
    if ([string]::IsNullOrEmpty($Path)) {
        throw 'Assert-NoStaticReparsePointInReviewPath: -Path is required.'
    }

    $rootFull = [System.IO.Path]::GetFullPath($RootPath)
    $pathFull = [System.IO.Path]::GetFullPath($Path)
    $sep = [System.IO.Path]::DirectorySeparatorChar
    $rootNorm = $rootFull.TrimEnd($sep)
    $cmp = [System.StringComparison]::OrdinalIgnoreCase
    $prefix = $rootNorm + $sep

    if ([string]::Equals($pathFull, $rootNorm, $cmp)) {
        $relative = ''
    }
    elseif ($pathFull.StartsWith($prefix, $cmp)) {
        $relative = $pathFull.Substring($prefix.Length)
    }
    else {
        throw "Assert-NoStaticReparsePointInReviewPath: path is outside inspection root. Path=$pathFull Root=$rootNorm"
    }

    # Walk from the caller-selected lexical root toward the selected write parent. Native entry
    # attributes describe a junction/symlink itself even when its target is dangling, so target
    # resolution is never used as the existence test. Once a component entry is actually absent, no
    # deeper static component can exist through that path; a hostile replacement after this check is
    # a separate TOCTOU race and is not claimed here.
    $components = @()
    if (-not [string]::IsNullOrEmpty($relative)) {
        $components = @($relative -split '[\\/]' | Where-Object { -not [string]::IsNullOrEmpty($_) })
    }

    $current = $rootNorm
    foreach ($component in @('') + $components) {
        if (-not [string]::IsNullOrEmpty($component)) {
            $current = Join-Path -Path $current -ChildPath $component
        }

        try {
            $entry = Get-ReviewPathEntryAttributes -Path $current
            if (-not $entry.Exists) {
                return $true
            }
        }
        catch {
            throw ('Assert-NoStaticReparsePointInReviewPath: could not inspect existing path component: {0}. Cause: {1}' -f
                $current, $_.Exception.Message)
        }

        if (($entry.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw "Assert-NoStaticReparsePointInReviewPath: static reparse point is not allowed in the selected review write path: $current"
        }
        if (($entry.Attributes -band [System.IO.FileAttributes]::Directory) -eq 0) {
            throw "Assert-NoStaticReparsePointInReviewPath: existing write-path component is not a directory: $current"
        }
    }

    return $true
}

function Test-ReviewCampaignAnchor {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $TaskDir
    )

    try {
        if (-not (Test-Path -LiteralPath $TaskDir -PathType Container -ErrorAction Stop)) {
            return $false
        }
        $taskItem = Get-Item -LiteralPath $TaskDir -Force -ErrorAction Stop
        if (Test-ReviewFileSystemInfoIsReparsePoint -Item $taskItem) {
            return $false
        }

        $perspectiveDirs = Get-ChildItem -LiteralPath $TaskDir -Directory -Force -ErrorAction Stop
        foreach ($perspectiveDir in $perspectiveDirs) {
            if ((-not (Test-ValidPerspective -Value $perspectiveDir.Name)) -or
                (Test-ReviewFileSystemInfoIsReparsePoint -Item $perspectiveDir)) {
                continue
            }

            $passDirs = Get-ChildItem -LiteralPath $perspectiveDir.FullName -Directory -Force -ErrorAction Stop
            foreach ($passDir in $passDirs) {
                if (($passDir.Name -cnotmatch '^pass-(0[1-9]|[1-9][0-9])$') -or
                    (Test-ReviewFileSystemInfoIsReparsePoint -Item $passDir)) {
                    continue
                }

                $files = Get-ChildItem -LiteralPath $passDir.FullName -File -Force -ErrorAction Stop
                foreach ($file in $files) {
                    if (($file.Name -ceq 'input.md') -and
                        (-not (Test-ReviewFileSystemInfoIsReparsePoint -Item $file))) {
                        return $true
                    }
                }
            }
        }
    }
    catch {
        # Anchor admission is fail-closed: an uninspectable path is not evidence of a canonical
        # campaign and must never cause prepare to join it.
        return $false
    }

    return $false
}

function Initialize-ReviewDirectoryNativeType {
    [CmdletBinding()]
    param()

    if ($null -ne ('AiHarnessToolset.Native.ReviewDirectory' -as [type])) {
        return
    }

    $source = @'
using System;
using System.Runtime.InteropServices;

namespace AiHarnessToolset.Native
{
    public static class ReviewDirectory
    {
        [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool CreateDirectoryW(
            string path,
            IntPtr securityAttributes
        );
    }
}
'@

    Add-Type -TypeDefinition $source -Language CSharp -ErrorAction Stop
}

function New-ExclusiveReviewDirectory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path
    )

    if ([string]::IsNullOrEmpty($Path)) {
        throw 'New-ExclusiveReviewDirectory: -Path is required.'
    }

    $full = [System.IO.Path]::GetFullPath($Path)
    [void] (Initialize-ReviewDirectoryNativeType)

    $created = [AiHarnessToolset.Native.ReviewDirectory]::CreateDirectoryW(
        $full,
        [System.IntPtr]::Zero
    )
    if ($created) {
        return $full
    }

    # Read the native error immediately after the failed call; any intervening native call could
    # replace the thread-local value and misclassify a collision as another failure.
    $errorCode = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
    if ($errorCode -eq 80 -or $errorCode -eq 183) {
        throw "New-ExclusiveReviewDirectory: directory claim conflict (path already exists): $full"
    }

    $detail = (New-Object System.ComponentModel.Win32Exception($errorCode)).Message
    throw "New-ExclusiveReviewDirectory: directory claim failed (Win32 error $errorCode): $detail Path=$full"
}

function New-ReviewPassAllocation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $PassDir
    )

    $claimedPassDir = New-ExclusiveReviewDirectory -Path $PassDir
    $inputPath = Join-Path -Path $claimedPassDir -ChildPath 'input.md'

    try {
        $stream = [System.IO.File]::Open(
            $inputPath,
            [System.IO.FileMode]::CreateNew,
            [System.IO.FileAccess]::Write,
            [System.IO.FileShare]::None
        )
        try {
            # A zero-byte file is the intentional operator-authored canvas and has no BOM.
        }
        finally {
            $stream.Dispose()
        }
    }
    catch {
        throw ('New-ReviewPassAllocation: pass directory was claimed but empty input.md creation failed. ' +
            'The claimed directory is preserved as a write-once orphan and must not be reused: {0}. Cause: {1}' -f
            $claimedPassDir, $_.Exception.Message)
    }

    return [pscustomobject]@{
        PassDir   = $claimedPassDir
        InputPath = $inputPath
    }
}
