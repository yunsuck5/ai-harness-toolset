[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $TargetPath,

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

if (-not [System.IO.Path]::IsPathRooted($TargetPath)) {
    $TargetPath = Join-Path -Path $project -ChildPath $TargetPath
}
$TargetPath = [System.IO.Path]::GetFullPath($TargetPath)

if (-not (Test-Path -LiteralPath $TargetPath -PathType Leaf)) {
    throw "review-prepare: TargetPath not found: $TargetPath"
}

[void] (Assert-InProjectRoot -Path $TargetPath -ProjectRoot $project)

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

$runDir = Join-Path -Path $logRoot -ChildPath ('review/' + $RunId)
[void] (Assert-InProjectRoot -Path $runDir -ProjectRoot $project)
if (-not (Test-Path -LiteralPath $runDir -PathType Container)) {
    $null = New-Item -ItemType Directory -Path $runDir -Force
}

$targetSha  = Get-FileSha256 -Path $TargetPath
$targetRel  = Resolve-ProjectRelativePath -Path $TargetPath -ProjectRoot $project
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
    throw "review-prepare: template not found: $templatePath"
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
