[CmdletBinding()]
param(
    [string] $ReviewTaskId,

    [switch] $ContinueCampaign,

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
if ([string]::IsNullOrEmpty($Perspective)) {
    Write-Host 'review-prepare: FAIL -Perspective is required. The canonical review artifact layout is log/review/<review-task-id>/<perspective>/pass-NN/; there is no two-level fallback. Pass an explicit review viewpoint (e.g. -Perspective local-correctness or -Perspective system-coherence).'
    exit 1
}

$project = Get-ProjectRoot -ProjectRoot $ProjectRoot
[void] (Get-ToolRoot -ToolRoot $ToolRoot -ProjectRoot $project)
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

$hasExplicitPass = -not [string]::IsNullOrEmpty($Pass)
if ($hasExplicitPass) {
    try {
        [void] (Assert-ValidPass -Value $Pass)
    }
    catch {
        Write-Host ('review-prepare: FAIL invalid Pass: {0}' -f $Pass)
        exit 1
    }
}

$taskDir = Get-ReviewTaskRoot -ProjectLogRoot $logRoot -ReviewTaskId $ReviewTaskId
[void] (Assert-InReviewRoot -Path $taskDir -ProjectLogRoot $logRoot)

# The lexical review/task path is not a physical containment proof. Inspect the existing ancestry
# from ProjectLogRoot through review/<ReviewTaskId> before new-campaign claim or continuation so a
# static log/review junction cannot redirect either admission or the first mutation outside log/.
try {
    [void] (Assert-NoStaticReparsePointInReviewPath -RootPath $logRoot -Path $taskDir)
}
catch {
    Write-Host ('review-prepare: FAIL review/task ancestry is not statically safe before campaign admission: {0}' -f $_.Exception.Message)
    exit 1
}

# An omitted -ContinueCampaign means a new public campaign claim. Existing task roots are never
# silently joined. Continuation is admitted only when the task root already carries a canonical
# <perspective>/pass-NN/input.md anchor; directory existence alone is not an anchored campaign.
if ($ContinueCampaign) {
    if (-not (Test-ReviewCampaignAnchor -TaskDir $taskDir)) {
        Write-Host ('review-prepare: FAIL -ContinueCampaign requires an existing anchored campaign with a canonical <perspective>/pass-NN/input.md: {0}' -f $taskDir)
        exit 1
    }
}
else {
    $reviewRoot = [System.IO.Path]::GetDirectoryName($taskDir)
    try {
        $null = [System.IO.Directory]::CreateDirectory($reviewRoot)
        [void] (New-ExclusiveReviewDirectory -Path $taskDir)
    }
    catch {
        Write-Host ('review-prepare: FAIL new campaign claim was not acquired for ReviewTaskId {0}: {1}' -f $ReviewTaskId, $_.Exception.Message)
        exit 1
    }
}

# Pass parent = <taskDir>/<perspective> (canonical three-level). Get-NextPassName scans this
# parent, so pass-NN auto-allocation is per-perspective. The candidate is calculated once;
# allocation conflict never rescans or retries with another pass.
$passParent = Get-ReviewPassParent -ProjectLogRoot $logRoot -ReviewTaskId $ReviewTaskId -Perspective $Perspective

try {
    [void] (Assert-NoStaticReparsePointInReviewPath -RootPath $taskDir -Path $passParent)
}
catch {
    Write-Host ('review-prepare: FAIL selected review write path is not statically safe: {0}' -f $_.Exception.Message)
    exit 1
}

# pass numbering and exhaustion are per-perspective. Once the selected perspective's pass-99
# coordinate is occupied by any filesystem entry, only that perspective is exhausted: neither
# auto allocation nor a lower explicit pass may mutate it or roll over to another identifier.
try {
    [void] (Assert-ReviewPass99NotOccupied -PassParent $passParent)
}
catch {
    Write-Host ('review-prepare: FAIL selected perspective pass range is exhausted or could not be inspected: {0}' -f $_.Exception.Message)
    exit 1
}

if (-not $hasExplicitPass) {
    try {
        $Pass = Get-NextPassName -TaskDir $passParent
        [void] (Assert-ValidPass -Value $Pass)
    }
    catch {
        Write-Host ('review-prepare: FAIL automatic pass candidate unavailable: {0}' -f $_.Exception.Message)
        exit 1
    }
}

$passDir = Get-ReviewPassDir -ProjectLogRoot $logRoot -ReviewTaskId $ReviewTaskId -Pass $Pass -Perspective $Perspective
[void] (Assert-InReviewRoot -Path $passDir -ProjectLogRoot $logRoot)

try {
    $null = [System.IO.Directory]::CreateDirectory($passParent)
}
catch {
    Write-Host ('review-prepare: FAIL could not create the perspective directory: {0}. Cause: {1}' -f $passParent, $_.Exception.Message)
    exit 1
}

# Prepare owns allocation only. The operator authors the complete request; the
# distributed template remains an on-demand writing reference, never an automatic
# reviewer-prompt seed.
try {
    $allocation = New-ReviewPassAllocation -PassDir $passDir
}
catch {
    Write-Host ('review-prepare: FAIL exclusive pass allocation failed; the selected pass is not retried automatically: {0}' -f $_.Exception.Message)
    exit 1
}
$passDir = $allocation.PassDir
$inputPath = $allocation.InputPath

# A pass-99 claim can race the pre-allocation check on a different path. Recheck after a lower
# allocation is fully claimed but before success publication. If pass-99 won that overlapping
# ordering, fail nonzero and preserve this lower allocation as an occupied write-once orphan.
if ($Pass -cne 'pass-99') {
    try {
        [void] (Assert-ReviewPass99NotOccupied -PassParent $passParent -RequireExistingParent)
    }
    catch {
        if ($_.Exception.Data['AiHarnessReviewPass99Reason'] -eq 'occupied') {
            Write-Host ('review-prepare: FAIL pass-99 became occupied while allocating {0}; the claimed lower pass is preserved as an orphan and must not be reused: {1}' -f
                $Pass, $_.Exception.Message)
        }
        else {
            Write-Host ('review-prepare: FAIL post-allocation pass-99 state could not be confirmed after allocating {0}: {1}. Do not infer pass-99 occupancy or lower-pass persistence; do not auto-retry or clean up.' -f
                $Pass, $_.Exception.Message)
        }
        exit 1
    }
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
