[CmdletBinding()]
param(
    [string] $ReviewTaskId,

    [string] $Pass,

    # Optional review viewpoint (C1 three-level layout). Omitted -> the historical
    # two-level layout log/review/<task>/pass-NN/. Supplied -> the three-level layout
    # log/review/<task>/<perspective>/pass-NN/. The operator names the perspective
    # explicitly; there is no automatic inference.
    [string] $Perspective,

    [ValidateSet('design', 'implementation', 'test', 'review', 'release')]
    [string] $Stage,

    [string] $Purpose,

    [string] $ProjectRoot,
    [string] $ToolRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'lib/encoding.ps1')
. (Join-Path $PSScriptRoot 'lib/path.ps1')

if ([string]::IsNullOrEmpty($ReviewTaskId)) {
    Write-Host 'review-prepare: FAIL -ReviewTaskId is required. The script does not derive a review-task-id from chat / session / git state; the operator must pass it explicitly.'
    exit 1
}
if ([string]::IsNullOrEmpty($Stage)) {
    Write-Host 'review-prepare: FAIL -Stage is required (one of design / implementation / test / review / release).'
    exit 1
}
if ([string]::IsNullOrEmpty($Purpose)) {
    Write-Host 'review-prepare: FAIL -Purpose is required.'
    exit 1
}

$project = Get-ProjectRoot -ProjectRoot $ProjectRoot
$tool    = Get-ToolRoot -ToolRoot $ToolRoot -ProjectRoot $project
$logRoot = Get-ProjectLogRoot -ProjectRoot $project

try {
    [void] (Assert-ValidReviewTaskId -Value $ReviewTaskId)
}
catch {
    Write-Host ('review-prepare: FAIL invalid ReviewTaskId: {0}' -f $ReviewTaskId)
    exit 1
}

if (-not [string]::IsNullOrEmpty($Perspective)) {
    try {
        [void] (Assert-ValidPerspective -Value $Perspective)
    }
    catch {
        Write-Host ('review-prepare: FAIL invalid Perspective: {0}' -f $Perspective)
        exit 1
    }
}

$taskDir = Get-ReviewTaskRoot -ProjectLogRoot $logRoot -ReviewTaskId $ReviewTaskId
[void] (Assert-InReviewRoot -Path $taskDir -ProjectLogRoot $logRoot)

# Pass parent = task dir (old two-level) or <taskDir>/<perspective> (new three-level).
# Get-NextPassName scans this parent, so pass-NN auto-allocation is per-perspective.
$passParent = Get-ReviewPassParent -ProjectLogRoot $logRoot -ReviewTaskId $ReviewTaskId -Perspective $Perspective

if ([string]::IsNullOrEmpty($Pass)) {
    $Pass = Get-NextPassName -TaskDir $passParent
}

try {
    [void] (Assert-ValidPass -Value $Pass)
}
catch {
    Write-Host ('review-prepare: FAIL invalid Pass: {0}' -f $Pass)
    exit 1
}

$passDir = Get-ReviewPassDir -ProjectLogRoot $logRoot -ReviewTaskId $ReviewTaskId -Pass $Pass -Perspective $Perspective
[void] (Assert-InReviewRoot -Path $passDir -ProjectLogRoot $logRoot)

if (Test-Path -LiteralPath $passDir -PathType Container) {
    Write-Host ('review-prepare: FAIL pass directory already exists: {0}. Each pass is write-once; allocate a new pass-NN under the same ReviewTaskId.' -f $passDir)
    exit 1
}

$templatePath = Join-Path -Path $tool -ChildPath 'templates/review-input.md'
if (-not (Test-Path -LiteralPath $templatePath -PathType Leaf)) {
    Write-Host ('review-prepare: FAIL template not found at {0}. ToolRoot={1}.' -f $templatePath, $tool)
    exit 1
}

$null = New-Item -ItemType Directory -Path $passDir -Force

$template = Read-Utf8 -Path $templatePath
$inputPath = Join-Path -Path $passDir -ChildPath 'input.md'
Write-Utf8NoBom -Path $inputPath -Content $template

$relPass = (Resolve-ProjectRelativePath -Path $passDir -ProjectRoot $project) -replace '\\', '/'
$relInput = (Resolve-ProjectRelativePath -Path $inputPath -ProjectRoot $project) -replace '\\', '/'

Write-Host ('review-prepare: PASS')
Write-Host ('review-task-id: {0}' -f $ReviewTaskId)
if (-not [string]::IsNullOrEmpty($Perspective)) {
    Write-Host ('perspective: {0}' -f $Perspective)
}
Write-Host ('pass: {0}' -f $Pass)
Write-Host ('stage: {0}' -f $Stage)
Write-Host ('purpose: {0}' -f $Purpose)
Write-Host ('pass-dir: {0}' -f $relPass)
Write-Host ('input: {0}' -f $relInput)
exit 0
