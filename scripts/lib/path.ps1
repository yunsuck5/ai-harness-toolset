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

function Get-StableToolRootCandidate {
    [CmdletBinding()]
    param()

    # Global stable install location: %USERPROFILE%\.claude\ai-harness-toolset\current.
    # This is the default ToolRoot for shared / global mode. The -ToolRoot parameter
    # and the AI_HARNESS_TOOL_ROOT env var are higher-priority overrides; this path is
    # the standing default when no override is in play.
    $userProfile = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::UserProfile)
    if ([string]::IsNullOrEmpty($userProfile)) {
        return $null
    }
    $candidate = Join-Path -Path $userProfile  -ChildPath '.claude'
    $candidate = Join-Path -Path $candidate    -ChildPath 'ai-harness-toolset'
    $candidate = Join-Path -Path $candidate    -ChildPath 'current'
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
        # %USERPROFILE%\.claude\ai-harness-toolset\current; tests inject a
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

    # channel 3 — global stable install (%USERPROFILE%\.claude\ai-harness-toolset\current).
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
        throw "Get-NextPassName: pass-NN range exhausted (max 99) under $TaskDir. Use a fresh ReviewTaskId."
    }
    return ('pass-{0:00}' -f $next)
}
