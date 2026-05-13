[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $RunId,

    [string] $ProjectRoot,

    [string] $ToolRoot,

    [switch] $RequireResult
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'lib/encoding.ps1')
. (Join-Path $PSScriptRoot 'lib/path.ps1')
. (Join-Path $PSScriptRoot 'lib/hash.ps1')
. (Join-Path $PSScriptRoot 'lib/json.ps1')

$project = Get-ProjectRoot -ProjectRoot $ProjectRoot
$logRoot = Get-ProjectLogRoot -ProjectRoot $project

try {
    [void] (Assert-ValidRunId -Value $RunId)
}
catch {
    Write-Host ('review-verify: FAIL invalid RunId: {0}' -f $RunId)
    exit 1
}

$runDir = Join-Path -Path $logRoot -ChildPath ('review/' + $RunId)
try {
    [void] (Assert-InReviewRunRoot -Path $runDir -ProjectLogRoot $logRoot)
}
catch {
    Write-Host ('review-verify: FAIL run directory outside review root: {0}' -f $runDir)
    exit 1
}

if (-not (Test-Path -LiteralPath $runDir -PathType Container)) {
    Write-Host ('review-verify: FAIL run directory not found: {0}' -f $runDir)
    exit 1
}

$metaPath = Join-Path -Path $runDir -ChildPath 'meta.json'
if (-not (Test-Path -LiteralPath $metaPath -PathType Leaf)) {
    Write-Host ('review-verify: FAIL meta.json not found: {0}' -f $metaPath)
    exit 1
}

$meta = Read-JsonFile -Path $metaPath

$metaProjectRoot = ''
if ($null -ne $meta.PSObject.Properties['projectRoot']) {
    $metaProjectRoot = [string]$meta.projectRoot
}
if ([string]::IsNullOrEmpty($metaProjectRoot)) {
    Write-Host 'review-verify: FAIL meta.projectRoot missing'
    exit 1
}

$metaProjectLogRoot = ''
if ($null -ne $meta.PSObject.Properties['projectLogRoot']) {
    $metaProjectLogRoot = [string]$meta.projectLogRoot
}
if ([string]::IsNullOrEmpty($metaProjectLogRoot)) {
    Write-Host 'review-verify: FAIL meta.projectLogRoot missing'
    exit 1
}

$sep = [System.IO.Path]::DirectorySeparatorChar
$metaProjectFull = ([System.IO.Path]::GetFullPath($metaProjectRoot)).TrimEnd($sep)
$metaLogFull     = ([System.IO.Path]::GetFullPath($metaProjectLogRoot)).TrimEnd($sep)
$projectNorm     = $project.TrimEnd($sep)
$logRootNorm     = $logRoot.TrimEnd($sep)
$cmp = [System.StringComparison]::OrdinalIgnoreCase

if (-not [string]::Equals($metaProjectFull, $projectNorm, $cmp)) {
    Write-Host ('review-verify: FAIL projectRoot mismatch. meta={0} runtime={1}' -f $metaProjectFull, $projectNorm)
    exit 1
}
if (-not [string]::Equals($metaLogFull, $logRootNorm, $cmp)) {
    Write-Host ('review-verify: FAIL projectLogRoot mismatch. meta={0} runtime={1}' -f $metaLogFull, $logRootNorm)
    exit 1
}

$metaToolRoot = ''
if ($null -ne $meta.PSObject.Properties['toolRoot']) {
    $metaToolRoot = [string]$meta.toolRoot
}
if ([string]::IsNullOrEmpty($metaToolRoot)) {
    Write-Host 'review-verify: FAIL meta.toolRoot missing'
    exit 1
}

$runtimeTool = ''
try {
    $runtimeTool = Get-ToolRoot -ToolRoot $ToolRoot -ProjectRoot $project
}
catch {
    Write-Host ('review-verify: FAIL toolRoot binding could not be re-resolved at runtime: {0}' -f $_.Exception.Message)
    exit 1
}

$metaToolFull    = ([System.IO.Path]::GetFullPath($metaToolRoot)).TrimEnd($sep)
$runtimeToolFull = ([System.IO.Path]::GetFullPath($runtimeTool)).TrimEnd($sep)
if (-not [string]::Equals($metaToolFull, $runtimeToolFull, $cmp)) {
    Write-Host ('review-verify: FAIL toolRoot mismatch. meta={0} runtime={1}' -f $metaToolFull, $runtimeToolFull)
    exit 1
}

$targetPath = [string]$meta.targetPath
if (-not (Test-Path -LiteralPath $targetPath -PathType Leaf)) {
    Write-Host ('review-verify: FAIL target file not found: {0}' -f $targetPath)
    exit 1
}

try {
    [void] (Assert-InProjectRoot -Path $targetPath -ProjectRoot $project)
}
catch {
    Write-Host ('review-verify: FAIL target outside ProjectRoot: {0}' -f $targetPath)
    exit 1
}

$expectedSha = [string]$meta.targetSha256
$actualSha   = Get-FileSha256 -Path $targetPath
if ($expectedSha -ne $actualSha) {
    Write-Host ('review-verify: FAIL stale. expected={0} actual={1}' -f $expectedSha, $actualSha)
    exit 1
}

if ($null -ne $meta.PSObject.Properties['targetFiles']) {
    $targetFilesArr = @($meta.targetFiles)
    if ($targetFilesArr.Count -gt 0) {
        foreach ($entry in $targetFilesArr) {
            $entryPath = ''
            if ($null -ne $entry.PSObject.Properties['path']) {
                $entryPath = [string]$entry.path
            }
            $entrySha = ''
            if ($null -ne $entry.PSObject.Properties['sha256']) {
                $entrySha = [string]$entry.sha256
            }
            if ([string]::IsNullOrEmpty($entryPath)) {
                Write-Host 'review-verify: FAIL targetFiles entry missing path'
                exit 1
            }
            if ([string]::IsNullOrEmpty($entrySha)) {
                Write-Host ('review-verify: FAIL targetFiles entry missing sha256: {0}' -f $entryPath)
                exit 1
            }
            $resolvedEntry = $entryPath
            if (-not [System.IO.Path]::IsPathRooted($resolvedEntry)) {
                $resolvedEntry = Join-Path -Path $project -ChildPath $resolvedEntry
            }
            $resolvedEntry = [System.IO.Path]::GetFullPath($resolvedEntry)
            try {
                [void] (Assert-InProjectRoot -Path $resolvedEntry -ProjectRoot $project)
            }
            catch {
                Write-Host ('review-verify: FAIL targetFiles path escapes ProjectRoot: {0}' -f $entryPath)
                exit 1
            }
            if (-not (Test-Path -LiteralPath $resolvedEntry -PathType Leaf)) {
                Write-Host ('review-verify: FAIL targetFiles file missing: {0}' -f $entryPath)
                exit 1
            }
            $entryActual = Get-FileSha256 -Path $resolvedEntry
            if ($entryActual -ne $entrySha) {
                Write-Host ('review-verify: FAIL targetFiles stale: {0} expected={1} actual={2}' -f $entryPath, $entrySha, $entryActual)
                exit 1
            }
        }
    }
}

$resultPath = Join-Path -Path $runDir -ChildPath 'result.md'
if (Test-Path -LiteralPath $resultPath -PathType Leaf) {
    Write-Host 'review-verify: result.md present (informational)'
}
else {
    Write-Host 'review-verify: result.md not present (informational)'
}

if ($RequireResult) {
    $inputPath = Join-Path -Path $runDir -ChildPath 'input.md'
    if (-not (Test-Path -LiteralPath $inputPath -PathType Leaf)) {
        Write-Host ('review-verify: FAIL input.md missing: {0}' -f $inputPath)
        exit 1
    }

    if (-not (Test-Path -LiteralPath $resultPath -PathType Leaf)) {
        Write-Host ('review-verify: FAIL result.md missing: {0}' -f $resultPath)
        exit 1
    }

    $resultJsonPath = Join-Path -Path $runDir -ChildPath 'result.json'
    if (-not (Test-Path -LiteralPath $resultJsonPath -PathType Leaf)) {
        Write-Host ('review-verify: FAIL result.json missing: {0}' -f $resultJsonPath)
        exit 1
    }

    $result = $null
    try {
        $result = Read-JsonFile -Path $resultJsonPath
    }
    catch {
        Write-Host ('review-verify: FAIL result.json invalid JSON: {0}' -f $resultJsonPath)
        exit 1
    }

    $metaRunId = ''
    if ($null -ne $meta.PSObject.Properties['runId']) {
        $metaRunId = [string]$meta.runId
    }
    $resultRunId = ''
    if ($null -ne $result.PSObject.Properties['runId']) {
        $resultRunId = [string]$result.runId
    }
    if ($metaRunId -ne $resultRunId) {
        Write-Host ('review-verify: FAIL result.json runId mismatch. meta={0} result={1}' -f $metaRunId, $resultRunId)
        exit 1
    }

    $resultTargetSha = ''
    if ($null -ne $result.PSObject.Properties['targetSha256']) {
        $resultTargetSha = [string]$result.targetSha256
    }
    if ($expectedSha -ne $resultTargetSha) {
        Write-Host ('review-verify: FAIL result.json targetSha256 mismatch. meta={0} result={1}' -f $expectedSha, $resultTargetSha)
        exit 1
    }

    $actualInputSha = Get-FileSha256 -Path $inputPath
    $resultInputSha = ''
    if ($null -ne $result.PSObject.Properties['inputSha256']) {
        $resultInputSha = [string]$result.inputSha256
    }
    if ($actualInputSha -ne $resultInputSha) {
        Write-Host ('review-verify: FAIL result.json inputSha256 mismatch. expected={0} actual={1}' -f $actualInputSha, $resultInputSha)
        exit 1
    }

    $actualResultSha = Get-FileSha256 -Path $resultPath
    $resultMdSha = ''
    if ($null -ne $result.PSObject.Properties['resultMarkdownSha256']) {
        $resultMdSha = [string]$result.resultMarkdownSha256
    }
    if ($actualResultSha -ne $resultMdSha) {
        Write-Host ('review-verify: FAIL result.json resultMarkdownSha256 mismatch. expected={0} actual={1}' -f $actualResultSha, $resultMdSha)
        exit 1
    }

    $verdict = ''
    if ($null -ne $result.PSObject.Properties['verdict']) {
        $verdict = [string]$result.verdict
    }
    $allowedVerdicts = @('yes', 'no', 'yes with risk')
    if ($allowedVerdicts -notcontains $verdict) {
        Write-Host ("review-verify: FAIL result.json verdict invalid: '{0}'" -f $verdict)
        exit 1
    }

    $resultTargetPath = ''
    if ($null -ne $result.PSObject.Properties['targetPath']) {
        $resultTargetPath = [string]$result.targetPath
    }
    if ([string]::IsNullOrEmpty($resultTargetPath)) {
        Write-Host 'review-verify: FAIL result.json targetPath missing or empty'
        exit 1
    }
    $metaTargetFull = ([System.IO.Path]::GetFullPath([string]$meta.targetPath)).TrimEnd($sep)
    $resultTargetFull = $null
    try {
        $resultTargetFull = ([System.IO.Path]::GetFullPath($resultTargetPath)).TrimEnd($sep)
    }
    catch {
        Write-Host ('review-verify: FAIL result.json targetPath could not be normalized: {0}' -f $resultTargetPath)
        exit 1
    }
    if (-not [string]::Equals($resultTargetFull, $metaTargetFull, $cmp)) {
        Write-Host ('review-verify: FAIL result.json targetPath mismatch. meta={0} result={1}' -f $metaTargetFull, $resultTargetFull)
        exit 1
    }

    $resultCreatedAt = ''
    if ($null -ne $result.PSObject.Properties['createdAtUtc']) {
        $resultCreatedAt = [string]$result.createdAtUtc
    }
    if ([string]::IsNullOrEmpty($resultCreatedAt)) {
        Write-Host 'review-verify: FAIL result.json createdAtUtc missing or empty'
        exit 1
    }
    $strictUtcShape = '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{7}Z$'
    if ($resultCreatedAt -cnotmatch $strictUtcShape) {
        Write-Host ('review-verify: FAIL result.json createdAtUtc not exact UTC shape: {0}' -f $resultCreatedAt)
        exit 1
    }
    $parsedCreatedAt = [System.DateTimeOffset]::MinValue
    $invariantCulture = [System.Globalization.CultureInfo]::InvariantCulture
    $createdAtStyles = [System.Globalization.DateTimeStyles]::None
    if (-not [System.DateTimeOffset]::TryParse($resultCreatedAt, $invariantCulture, $createdAtStyles, [ref]$parsedCreatedAt)) {
        Write-Host ('review-verify: FAIL result.json createdAtUtc not parseable: {0}' -f $resultCreatedAt)
        exit 1
    }
    if ($parsedCreatedAt.Offset -ne [System.TimeSpan]::Zero) {
        Write-Host ('review-verify: FAIL result.json createdAtUtc not UTC offset: {0}' -f $resultCreatedAt)
        exit 1
    }

    $metaSourceHead = ''
    if ($null -ne $meta.PSObject.Properties['sourceHead']) {
        $metaSourceHead = [string]$meta.sourceHead
    }
    $resultSourceHead = ''
    if ($null -ne $result.PSObject.Properties['sourceHead']) {
        $resultSourceHead = [string]$result.sourceHead
    }
    if (-not [string]::IsNullOrEmpty($metaSourceHead) -and -not [string]::IsNullOrEmpty($resultSourceHead)) {
        if (-not [string]::Equals($metaSourceHead, $resultSourceHead, [System.StringComparison]::Ordinal)) {
            Write-Host ('review-verify: FAIL result.json sourceHead mismatch. meta={0} result={1}' -f $metaSourceHead, $resultSourceHead)
            exit 1
        }
    }

    Write-Host 'review-verify: result.json present and binding verified'
}

Write-Host ('review-verify: PASS run-id {0}' -f $RunId)
exit 0
