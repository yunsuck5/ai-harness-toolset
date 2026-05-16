Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Reuse the shared ToolRoot path helpers (Get-StableToolRootCandidate). path.ps1
# defines functions and sets Set-StrictMode / $ErrorActionPreference to the same
# values already set above, so its function definitions are safe to re-source in
# this context even though production callers also dot-source it directly.
. (Join-Path -Path $PSScriptRoot -ChildPath 'path.ps1')

function Get-ToolRootSource {
    [CmdletBinding()]
    param(
        [string] $ToolRoot,
        # Optional override for the global stable install path. Production callers
        # leave this empty so it resolves to the real
        # %USERPROFILE%\.claude\ai-harness-toolset\current; tests inject a
        # controlled path for deterministic isolation.
        [string] $StableToolRoot
    )

    # Explicit ToolRoot sources suppress the $PSScriptRoot component fallback so
    # that misconfiguration fails fast. The explicit sources, in priority order,
    # are: the -ToolRoot parameter (channel 1), the AI_HARNESS_TOOL_ROOT env var
    # (channel 2), and the global stable install (channel 3). The implicit
    # sources (dogfooding source repo, legacy .ai-harness) keep the fallback.
    if (-not [string]::IsNullOrEmpty($ToolRoot)) {
        return 'explicit'
    }
    $envTool = [System.Environment]::GetEnvironmentVariable('AI_HARNESS_TOOL_ROOT')
    if (-not [string]::IsNullOrEmpty($envTool)) {
        return 'explicit'
    }
    if ([string]::IsNullOrEmpty($StableToolRoot)) {
        $StableToolRoot = Get-StableToolRootCandidate
    }
    if (-not [string]::IsNullOrEmpty($StableToolRoot) -and (Test-Path -LiteralPath $StableToolRoot -PathType Container)) {
        return 'explicit'
    }
    return 'implicit'
}

function Resolve-ScriptUnderToolRoot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Tool,
        [Parameter(Mandatory = $true)]
        [string] $RelativePath,
        [Parameter(Mandatory = $true)]
        [string] $LocalDir,
        [ValidateSet('explicit', 'implicit')]
        [string] $ToolRootSource = 'implicit',
        [Parameter(Mandatory = $true)]
        [string] $CallerLabel
    )

    $candidate = Join-Path -Path $Tool -ChildPath $RelativePath
    if (Test-Path -LiteralPath $candidate -PathType Leaf) {
        return $candidate
    }

    if ($ToolRootSource -eq 'explicit') {
        throw ('{0}: component script not found under explicit ToolRoot. ToolRoot={1} missing={2}. Fallback to $PSScriptRoot was suppressed because ToolRoot came from an explicit source: the -ToolRoot parameter, the AI_HARNESS_TOOL_ROOT env var, or the global stable install.' -f $CallerLabel, $Tool, $RelativePath)
    }

    $local = Join-Path -Path $LocalDir -ChildPath (Split-Path -Leaf $RelativePath)
    if (Test-Path -LiteralPath $local -PathType Leaf) {
        Write-Host ('{0}: WARN component script resolved via $PSScriptRoot fallback. ToolRoot={1} missing={2} fallback={3}' -f $CallerLabel, $Tool, $RelativePath, $local)
        return $local
    }

    throw ('{0}: required script not found: {1}. Tried under ToolRoot={2} and via $PSScriptRoot fallback={3}.' -f $CallerLabel, $RelativePath, $Tool, $local)
}

function Resolve-RunScript {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Tool,
        [Parameter(Mandatory = $true)]
        [string] $RelativePath,
        [Parameter(Mandatory = $true)]
        [string] $LocalDir,
        [ValidateSet('explicit', 'implicit')]
        [string] $ToolRootSource = 'implicit'
    )
    return Resolve-ScriptUnderToolRoot -Tool $Tool -RelativePath $RelativePath -LocalDir $LocalDir -ToolRootSource $ToolRootSource -CallerLabel 'review-run'
}
