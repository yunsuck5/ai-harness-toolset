[CmdletBinding()]
param(
    [string] $ReviewTaskId,

    [string] $Pass,

    # Required review viewpoint (strict C1 canonical layout). The pass directory is always
    # log/review/<review-task-id>/<perspective>/pass-NN/. The operator names the perspective
    # explicitly; there is no automatic inference and no two-level fallback. Empty / missing
    # fails fast.
    [string] $Perspective,

    [ValidateSet('design', 'implementation', 'test', 'review', 'release')]
    [string] $Stage,

    [string] $Purpose,

    [string] $ProjectRoot,
    [string] $ToolRoot,

    # NoSeed: create the pass dir + an empty input.md WITHOUT seeding the full
    # templates/review-input.md body. The operator authors input.md from scratch
    # (the template body's single home is templates/review-input.md), removing the
    # seed -> read -> overwrite friction. Default (switch absent) keeps the
    # full-template seed unchanged (backward-compatible). All other prepare behavior
    # (pass-dir issue, write-once refusal, path containment, next-pass numbering,
    # PASS stdout lines) is identical in both modes.
    [switch] $NoSeed
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
if ([string]::IsNullOrEmpty($Perspective)) {
    Write-Host 'review-prepare: FAIL -Perspective is required. The canonical review artifact layout is log/review/<review-task-id>/<perspective>/pass-NN/; there is no two-level fallback. Pass an explicit review viewpoint (e.g. -Perspective local-correctness or -Perspective system-coherence).'
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

try {
    [void] (Assert-ValidPerspective -Value $Perspective)
}
catch {
    Write-Host ('review-prepare: FAIL invalid Perspective: {0}' -f $Perspective)
    exit 1
}

$taskDir = Get-ReviewTaskRoot -ProjectLogRoot $logRoot -ReviewTaskId $ReviewTaskId
[void] (Assert-InReviewRoot -Path $taskDir -ProjectLogRoot $logRoot)

# Pass parent = <taskDir>/<perspective> (canonical three-level). Get-NextPassName scans this
# parent, so pass-NN auto-allocation is per-perspective.
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
    Write-Host ('review-prepare: FAIL pass directory already exists: {0}. Each pass is write-once; allocate a new pass-NN under the same ReviewTaskId/Perspective.' -f $passDir)
    exit 1
}

$inputPath = Join-Path -Path $passDir -ChildPath 'input.md'

if ($NoSeed) {
    # No-seed mode: skip the template entirely and write an empty input.md for the
    # operator to author from scratch. The template body's single home is
    # templates/review-input.md; not re-seeding it each pass removes the
    # seed -> read -> overwrite friction. review-input-verify still gates the
    # authored input.md at review-run time, so an empty canvas is intentional.
    $null = New-Item -ItemType Directory -Path $passDir -Force
    Write-Utf8NoBom -Path $inputPath -Content ''
}
else {
    $templatePath = Join-Path -Path $tool -ChildPath 'templates/review-input.md'
    if (-not (Test-Path -LiteralPath $templatePath -PathType Leaf)) {
        Write-Host ('review-prepare: FAIL template not found at {0}. ToolRoot={1}.' -f $templatePath, $tool)
        exit 1
    }

    $null = New-Item -ItemType Directory -Path $passDir -Force

    $template = Read-Utf8 -Path $templatePath
    Write-Utf8NoBom -Path $inputPath -Content $template
}

$relPass = (Resolve-ProjectRelativePath -Path $passDir -ProjectRoot $project) -replace '\\', '/'
$relInput = (Resolve-ProjectRelativePath -Path $inputPath -ProjectRoot $project) -replace '\\', '/'

Write-Host ('review-prepare: PASS')
Write-Host ('review-task-id: {0}' -f $ReviewTaskId)
Write-Host ('perspective: {0}' -f $Perspective)
Write-Host ('pass: {0}' -f $Pass)
Write-Host ('stage: {0}' -f $Stage)
Write-Host ('purpose: {0}' -f $Purpose)
Write-Host ('pass-dir: {0}' -f $relPass)
Write-Host ('input: {0}' -f $relInput)
exit 0
