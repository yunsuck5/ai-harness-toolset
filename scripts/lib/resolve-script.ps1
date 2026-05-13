Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-ToolRootSource {
    [CmdletBinding()]
    param(
        [string] $ToolRoot
    )

    if (-not [string]::IsNullOrEmpty($ToolRoot)) {
        return 'explicit'
    }
    $envTool = [System.Environment]::GetEnvironmentVariable('AI_HARNESS_TOOL_ROOT')
    if (-not [string]::IsNullOrEmpty($envTool)) {
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
        throw ('{0}: component script not found under explicit ToolRoot. ToolRoot={1} missing={2}. Fallback to $PSScriptRoot was suppressed because ToolRoot was specified via -ToolRoot or AI_HARNESS_TOOL_ROOT.' -f $CallerLabel, $Tool, $RelativePath)
    }

    $local = Join-Path -Path $LocalDir -ChildPath (Split-Path -Leaf $RelativePath)
    if (Test-Path -LiteralPath $local -PathType Leaf) {
        Write-Host ('{0}: WARN component script resolved via $PSScriptRoot fallback. ToolRoot={1} missing={2} fallback={3}' -f $CallerLabel, $Tool, $RelativePath, $local)
        return $local
    }

    throw ('{0}: required script not found: {1}. Tried under ToolRoot={2} and via $PSScriptRoot fallback={3}.' -f $CallerLabel, $RelativePath, $Tool, $local)
}

function Resolve-CycleScript {
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
    return Resolve-ScriptUnderToolRoot -Tool $Tool -RelativePath $RelativePath -LocalDir $LocalDir -ToolRootSource $ToolRootSource -CallerLabel 'review-cycle'
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
