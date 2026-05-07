[CmdletBinding()]
param(
    [string] $TargetPath,

    [string[]] $TargetFiles,

    [string] $TargetFilesPath,

    [Parameter(Mandatory = $true)]
    [ValidateSet('design', 'implementation', 'test', 'review', 'release')]
    [string] $Stage,

    [Parameter(Mandatory = $true)]
    [string] $Purpose,

    [string] $Reviewer,
    [string] $Model,
    [string] $ReasoningEffort,
    [string] $ProjectRoot,
    [string] $ToolRoot,
    [string] $RunId
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'lib/encoding.ps1')
. (Join-Path $PSScriptRoot 'lib/path.ps1')
. (Join-Path $PSScriptRoot 'lib/hash.ps1')
. (Join-Path $PSScriptRoot 'lib/git.ps1')
. (Join-Path $PSScriptRoot 'lib/json.ps1')

$project = Get-ProjectRoot -ProjectRoot $ProjectRoot
$tool    = Get-ToolRoot -ToolRoot $ToolRoot -ProjectRoot $project
$logRoot = Get-ProjectLogRoot -ProjectRoot $project

if (-not [string]::IsNullOrEmpty($TargetFilesPath)) {
    if (-not (Test-Path -LiteralPath $TargetFilesPath -PathType Leaf)) {
        throw "review-prepare: TargetFilesPath not found: $TargetFilesPath"
    }
    try {
        [void] (Assert-InProjectLogRoot -Path $TargetFilesPath -ProjectLogRoot $logRoot)
    }
    catch {
        throw "review-prepare: TargetFilesPath outside ProjectLogRoot: $($_.Exception.Message)"
    }
    $listText = Read-Utf8 -Path $TargetFilesPath
    foreach ($ln in ($listText -split "`r?`n")) {
        $trim = $ln.Trim()
        if (-not [string]::IsNullOrEmpty($trim)) {
            if ($null -eq $TargetFiles) { $TargetFiles = @() }
            $TargetFiles = $TargetFiles + $trim
        }
    }
}

$reviewedFiles = @()
if ($null -ne $TargetFiles -and $TargetFiles.Count -gt 0) {
    foreach ($tf in $TargetFiles) {
        if (-not [string]::IsNullOrEmpty($tf)) {
            $reviewedFiles += $tf
        }
    }
}

if ([string]::IsNullOrEmpty($TargetPath)) {
    if ($reviewedFiles.Count -eq 0) {
        throw 'review-prepare: at least one of -TargetPath or -TargetFiles is required.'
    }
    $TargetPath = $reviewedFiles[0]
}

if (-not [System.IO.Path]::IsPathRooted($TargetPath)) {
    $TargetPath = Join-Path -Path $project -ChildPath $TargetPath
}
$TargetPath = [System.IO.Path]::GetFullPath($TargetPath)

if (-not (Test-Path -LiteralPath $TargetPath -PathType Leaf)) {
    throw "review-prepare: TargetPath not found: $TargetPath"
}

[void] (Assert-InProjectRoot -Path $TargetPath -ProjectRoot $project)

function Resolve-TargetEntry {
    param(
        [string] $Path,
        [string] $ProjectRoot
    )
    $resolved = $Path
    if (-not [System.IO.Path]::IsPathRooted($resolved)) {
        $resolved = Join-Path -Path $ProjectRoot -ChildPath $resolved
    }
    $resolved = [System.IO.Path]::GetFullPath($resolved)
    if (-not (Test-Path -LiteralPath $resolved -PathType Leaf)) {
        throw "review-prepare: target file not found: $resolved"
    }
    [void] (Assert-InProjectRoot -Path $resolved -ProjectRoot $ProjectRoot)
    $rel = (Resolve-ProjectRelativePath -Path $resolved -ProjectRoot $ProjectRoot) -replace '\\', '/'
    $sha = Get-FileSha256 -Path $resolved
    return [pscustomobject]@{
        FullPath = $resolved
        RelPath  = $rel
        Sha256   = $sha
    }
}

$primaryEntry = Resolve-TargetEntry -Path $TargetPath -ProjectRoot $project

$targetFilesEntries = New-Object System.Collections.Generic.List[object]
$seen = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
$null = $seen.Add($primaryEntry.RelPath)
$targetFilesEntries.Add([ordered]@{
    path   = $primaryEntry.RelPath
    sha256 = $primaryEntry.Sha256
})

foreach ($tf in $reviewedFiles) {
    $entry = Resolve-TargetEntry -Path $tf -ProjectRoot $project
    if ($seen.Add($entry.RelPath)) {
        $targetFilesEntries.Add([ordered]@{
            path   = $entry.RelPath
            sha256 = $entry.Sha256
        })
    }
}

$builtInDefault = [ordered]@{
    provider        = 'openai'
    model           = 'gpt-5.5'
    fallbackModel   = 'gpt-5.4'
    reasoningEffort = 'medium'
    timeoutSeconds  = 300
    sandbox         = 'read-only'
}

$configPath = Join-Path -Path $tool -ChildPath 'config/reviewer.json'
$config = $null
if (Test-Path -LiteralPath $configPath -PathType Leaf) {
    $config = Read-JsonFile -Path $configPath
}

function Get-ConfigValue {
    param($Source, [string] $Name)
    if ($null -eq $Source) { return $null }
    $matched = $Source.PSObject.Properties.Match($Name)
    if ($matched.Count -eq 0) { return $null }
    return $Source.$Name
}

function Resolve-StringSetting {
    param([string] $Explicit, $ConfigValue, [string] $Default)
    if (-not [string]::IsNullOrEmpty($Explicit)) { return $Explicit }
    if ($null -ne $ConfigValue) {
        $s = [string]$ConfigValue
        if (-not [string]::IsNullOrEmpty($s)) { return $s }
    }
    return $Default
}

$cfgProvider = Get-ConfigValue -Source $config -Name 'provider'
$cfgModel    = Get-ConfigValue -Source $config -Name 'model'
$cfgFallback = Get-ConfigValue -Source $config -Name 'fallbackModel'
$cfgEffort   = Get-ConfigValue -Source $config -Name 'reasoningEffort'
$cfgTimeout  = Get-ConfigValue -Source $config -Name 'timeoutSeconds'
$cfgSandbox  = Get-ConfigValue -Source $config -Name 'sandbox'

$effProvider = Resolve-StringSetting -Explicit '' -ConfigValue $cfgProvider -Default $builtInDefault.provider
$effModel    = Resolve-StringSetting -Explicit $Model -ConfigValue $cfgModel -Default $builtInDefault.model
$effFallback = Resolve-StringSetting -Explicit '' -ConfigValue $cfgFallback -Default $builtInDefault.fallbackModel
$effEffort   = Resolve-StringSetting -Explicit $ReasoningEffort -ConfigValue $cfgEffort -Default $builtInDefault.reasoningEffort
$effSandbox  = Resolve-StringSetting -Explicit '' -ConfigValue $cfgSandbox -Default $builtInDefault.sandbox

if ($null -ne $cfgTimeout) {
    $effTimeout = [int]$cfgTimeout
}
else {
    $effTimeout = $builtInDefault.timeoutSeconds
}

if ([string]::IsNullOrEmpty($RunId)) {
    $stamp = (Get-Date).ToUniversalTime().ToString('yyyyMMdd-HHmmss')
    $suffix = ([guid]::NewGuid().ToString('N')).Substring(0, 6).ToLowerInvariant()
    $RunId = "$stamp-$suffix"
}
[void] (Assert-ValidRunId -Value $RunId)

$runDir = Join-Path -Path $logRoot -ChildPath ('review/' + $RunId)
[void] (Assert-InReviewRunRoot -Path $runDir -ProjectLogRoot $logRoot)
if (-not (Test-Path -LiteralPath $runDir -PathType Container)) {
    $null = New-Item -ItemType Directory -Path $runDir -Force
}

$targetSha  = $primaryEntry.Sha256
$targetRel  = $primaryEntry.RelPath
$sourceHead = Get-GitHead -WorkingDirectory $project

$effReviewer = 'codex'
if (-not [string]::IsNullOrEmpty($Reviewer)) {
    $effReviewer = $Reviewer
}

$meta = [ordered]@{
    schemaVersion      = 1
    runId              = $RunId
    createdAtUtc       = (Get-Date).ToUniversalTime().ToString('o')
    projectRoot        = $project
    toolRoot           = $tool
    projectLogRoot     = $logRoot
    targetPath         = $TargetPath
    targetRelativePath = $targetRel
    targetSha256       = $targetSha
    targetFiles        = $targetFilesEntries.ToArray()
    stage              = $Stage
    purpose            = $Purpose
    reviewer           = $effReviewer
    sourceHead         = $sourceHead
    reviewerConfig     = [ordered]@{
        provider        = $effProvider
        model           = $effModel
        fallbackModel   = $effFallback
        reasoningEffort = $effEffort
        timeoutSeconds  = $effTimeout
        sandbox         = $effSandbox
    }
    freshnessPolicy    = [ordered]@{
        type    = 'target-sha256-match'
        failure = 'fail'
    }
}

$metaPath = Join-Path -Path $runDir -ChildPath 'meta.json'
Write-JsonFile -Path $metaPath -Value $meta

$templatePath = Join-Path -Path $tool -ChildPath 'templates/review-input.md'
if (-not (Test-Path -LiteralPath $templatePath -PathType Leaf)) {
    throw "review-prepare: required template not found at '$templatePath'. ToolRoot='$tool'. Ensure templates/review-input.md exists under ToolRoot."
}
$template = Read-Utf8 -Path $templatePath

$srcHeadStr = ''
if ($null -ne $sourceHead) {
    $srcHeadStr = [string]$sourceHead
}

$rendered = $template
$rendered = $rendered.Replace('{{RUN_ID}}', $RunId)
$rendered = $rendered.Replace('{{TARGET_PATH}}', $TargetPath)
$rendered = $rendered.Replace('{{TARGET_SHA256}}', $targetSha)
$rendered = $rendered.Replace('{{STAGE}}', $Stage)
$rendered = $rendered.Replace('{{PURPOSE}}', $Purpose)
$rendered = $rendered.Replace('{{REVIEWER}}', $effReviewer)
$rendered = $rendered.Replace('{{SOURCE_HEAD}}', $srcHeadStr)
$rendered = $rendered.Replace('{{REVIEWER_MODEL}}', $effModel)
$rendered = $rendered.Replace('{{REASONING_EFFORT}}', $effEffort)

$inputPath = Join-Path -Path $runDir -ChildPath 'input.md'
Write-Utf8NoBom -Path $inputPath -Content $rendered

Write-Host ('review-prepare: created run-id {0}' -f $RunId)
Write-Host ('review-prepare: meta {0}' -f $metaPath)
Write-Host ('review-prepare: input {0}' -f $inputPath)
exit 0
