Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

BeforeAll {
    $script:RepoRoot     = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).ProviderPath
    $script:Entry        = Join-Path $script:RepoRoot 'scripts/install-update.ps1'
    $script:InstallMd    = Join-Path $script:RepoRoot 'INSTALL.md'

    . (Join-Path $script:RepoRoot 'scripts/lib/encoding.ps1')
    . (Join-Path $script:RepoRoot 'scripts/lib/hash.ps1')
    . (Join-Path $script:RepoRoot 'scripts/lib/git.ps1')
    . (Join-Path $script:RepoRoot 'scripts/lib/managed-block.ps1')
    . (Join-Path $script:RepoRoot 'scripts/lib/install-pipeline-core.ps1')
    . (Join-Path $script:RepoRoot 'scripts/lib/native-process.ps1')

    $script:BeginMarker = '<!-- BEGIN AI_HARNESS_TOOLSET_GLOBAL -->'
    $script:EndMarker   = '<!-- END AI_HARNESS_TOOLSET_GLOBAL -->'
    $script:Utf8NoBom   = New-Object System.Text.UTF8Encoding($false)

    function script:Write-TextFile {
        param([string] $Path, [string] $Content)
        $parent = Split-Path -LiteralPath $Path
        if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
            $null = New-Item -ItemType Directory -Path $parent -Force
        }
        [System.IO.File]::WriteAllText($Path, $Content, $script:Utf8NoBom)
    }

    function script:New-FixtureGitRepo {
        param([string] $CaseName)
        $root = Join-Path $TestDrive ('src-' + $CaseName)
        if (Test-Path -LiteralPath $root) { Remove-Item -LiteralPath $root -Recurse -Force }
        $null = New-Item -ItemType Directory -Path $root -Force
        Push-Location $root
        try {
            & git init -q 2>&1 | Out-Null
            & git symbolic-ref HEAD refs/heads/main 2>&1 | Out-Null
            & git config core.autocrlf false 2>&1 | Out-Null
            & git config core.safecrlf false 2>&1 | Out-Null
            & git config user.email 'test@example.com' 2>&1 | Out-Null
            & git config user.name  'install-update-test' 2>&1 | Out-Null
            script:Write-TextFile (Join-Path $root 'README.md') 'seed'
            & git add . 2>&1 | Out-Null
            & git commit -q -m 'seed' 2>&1 | Out-Null
            $head = (Invoke-NativeProcess -Executable 'git' -Arguments @('rev-parse', 'HEAD')).Stdout.Trim()
        }
        finally { Pop-Location }
        return [pscustomobject]@{ Root = ([System.IO.Path]::GetFullPath($root)); Head = $head }
    }

    function script:Add-FixtureGitCommit {
        param([string] $Root, [string] $Suffix)
        Push-Location $Root
        try {
            script:Write-TextFile (Join-Path $Root ('next-' + $Suffix + '.md')) ('next-' + $Suffix)
            & git add . 2>&1 | Out-Null
            & git commit -q -m ('next ' + $Suffix) 2>&1 | Out-Null
            $head = (Invoke-NativeProcess -Executable 'git' -Arguments @('rev-parse', 'HEAD')).Stdout.Trim()
        }
        finally { Pop-Location }
        return $head
    }

    function script:New-FixtureInstallArea {
        param([string] $CaseName)
        $root = Join-Path $TestDrive ('area-' + $CaseName)
        if (Test-Path -LiteralPath $root) { Remove-Item -LiteralPath $root -Recurse -Force }
        $null = New-Item -ItemType Directory -Path $root -Force
        return ([System.IO.Path]::GetFullPath($root))
    }

    function script:New-FixtureHomeRoots {
        param([string] $CaseName)
        $cHome = Join-Path $TestDrive ('claudeHome-' + $CaseName)
        $xHome = Join-Path $TestDrive ('codexHome-'  + $CaseName)
        foreach ($d in @($cHome, $xHome)) {
            if (Test-Path -LiteralPath $d) { Remove-Item -LiteralPath $d -Recurse -Force }
            $null = New-Item -ItemType Directory -Path $d -Force
        }
        return [pscustomobject]@{
            ClaudeHome = ([System.IO.Path]::GetFullPath($cHome))
            CodexHome  = ([System.IO.Path]::GetFullPath($xHome))
        }
    }

    function script:Get-FixtureClaudeSnippetText {
        return ($script:BeginMarker + "`n# fixture claude managed block body`nline2`n" + $script:EndMarker + "`n")
    }
    function script:Get-FixtureCodexSnippetText {
        return ($script:BeginMarker + "`n# fixture codex managed block body`nlineA`nlineB`n" + $script:EndMarker + "`n")
    }
    function script:Get-FixtureSkillText {
        return "---`nname: ai-harness-review`n---`n# fixture skill body`n"
    }

    function script:Get-MarkedDestinationText {
        param([string] $MarkedBlockBody)
        return ("# user content`n" + $script:BeginMarker + "`n" + $MarkedBlockBody + "`n" + $script:EndMarker + "`ntail`n")
    }

    function script:New-FixtureBareRepoWithBranch {
        # Bare repo with main + a second branch whose HEAD differs from main, to exercise
        # the git-url branch-derivation path of inspect mode (Resolve-SourceHead).
        param([string] $CaseName, [string] $BranchName)
        $src = script:New-FixtureGitRepo -CaseName ($CaseName + '-srcbare')
        $bare = Join-Path $TestDrive ('bare-' + $CaseName + '.git')
        if (Test-Path -LiteralPath $bare) { Remove-Item -LiteralPath $bare -Recurse -Force }
        & git clone --bare -q $src.Root $bare 2>&1 | Out-Null
        # Create a divergent branch HEAD in the source, then push it to the bare repo.
        $branchHead = $null
        Push-Location $src.Root
        try {
            & git checkout -q -b $BranchName 2>&1 | Out-Null
            script:Write-TextFile (Join-Path $src.Root ('branch-' + $BranchName + '.md')) ('branch ' + $BranchName)
            & git add . 2>&1 | Out-Null
            & git commit -q -m ('branch commit ' + $BranchName) 2>&1 | Out-Null
            $branchHead = (Invoke-NativeProcess -Executable 'git' -Arguments @('rev-parse', 'HEAD')).Stdout.Trim()
            & git push -q $bare ($BranchName + ':' + $BranchName) 2>&1 | Out-Null
        }
        finally { Pop-Location }
        return [pscustomobject]@{
            BareUrl    = ([System.IO.Path]::GetFullPath($bare))
            MainHead   = $src.Head
            BranchHead = $branchHead
            BranchName = $BranchName
        }
    }

    function script:Initialize-CleanInstallFixture {
        param(
            [Parameter(Mandatory = $true)] [string] $InstallArea,
            [Parameter(Mandatory = $true)] [string] $ClaudeHome,
            [Parameter(Mandatory = $true)] [string] $CodexHome,
            [Parameter(Mandatory = $true)] [string] $SourcePath,
            [Parameter(Mandatory = $true)] [string] $Head,
            [string] $InstallMode = 'local-clone',
            [string] $RepoUrl = '',
            [string] $Branch = 'main'
        )
        # Populate current/<payloadRoots> with payload-snippet activation sources.
        $currentDir = Join-Path $InstallArea 'current'
        foreach ($r in 'config','scripts','snippets','templates') {
            $null = New-Item -ItemType Directory -Path (Join-Path $currentDir $r) -Force
        }
        script:Write-TextFile (Join-Path $currentDir 'snippets/CLAUDE_SNIPPET.md')                                  (script:Get-FixtureClaudeSnippetText)
        script:Write-TextFile (Join-Path $currentDir 'snippets/AGENTS_SNIPPET.md')                                  (script:Get-FixtureCodexSnippetText)
        script:Write-TextFile (Join-Path $currentDir 'snippets/claude-skills/ai-harness-review/SKILL.md')           (script:Get-FixtureSkillText)
        # Optional payload markers in other roots to bulk the manifest.
        script:Write-TextFile (Join-Path $currentDir 'config/reviewer.json')   '{}'
        script:Write-TextFile (Join-Path $currentDir 'scripts/marker.txt')     'marker'
        script:Write-TextFile (Join-Path $currentDir 'templates/marker.txt')   'marker'

        # install.json — hand-built 14-field schema. Mode-conditional source-identity fields
        # follow INSTALL.md §4: git-url keeps repoUrl (sourcePath / toolRoot empty); local-clone
        # keeps sourcePath / toolRoot (repoUrl empty).
        $now = '2026-05-28T00:00:00Z'
        $mdRepoUrl    = if ($InstallMode -eq 'git-url')     { $RepoUrl }    else { '' }
        $mdSourcePath = if ($InstallMode -eq 'local-clone') { $SourcePath } else { '' }
        $mdToolRoot   = if ($InstallMode -eq 'local-clone') { $SourcePath } else { '' }
        $metadata = [PSCustomObject]([ordered]@{
            schemaVersion         = 1
            tool                  = 'ai-harness-toolset'
            installMode           = $InstallMode
            repoUrl               = $mdRepoUrl
            sourcePath            = $mdSourcePath
            toolRoot              = $mdToolRoot
            branch                = $Branch
            remote                = 'origin'
            installedHead         = $Head
            lastUpdatedHead       = $Head
            installedAt           = $now
            lastUpdatedAt         = $now
            targetFootprintPolicy = 'log-only'
            managedBy             = 'claude-code'
        })
        $metaPath = Get-InstallPipelineMetadataPath -InstallArea $InstallArea
        Write-JsonUtf8NoBom -Path $metaPath -Value $metadata

        # manifest + marker via canonical helpers.
        $manifest = New-InstallPipelineManifest -InstallArea $InstallArea -Head $Head
        Write-InstallPipelineManifest -InstallArea $InstallArea -Manifest $manifest
        $marker = New-InstallPipelineMarker -Head $Head
        Write-InstallPipelineMarker -InstallArea $InstallArea -Marker $marker

        # Activation surfaces under temp homes, byte-identical to payload snippets.
        $claudePayloadText = Read-Utf8 -Path (Join-Path $currentDir 'snippets/CLAUDE_SNIPPET.md')
        $codexPayloadText  = Read-Utf8 -Path (Join-Path $currentDir 'snippets/AGENTS_SNIPPET.md')
        $skillPayloadText  = Read-Utf8 -Path (Join-Path $currentDir 'snippets/claude-skills/ai-harness-review/SKILL.md')

        # Managed-block destination = surrounding user content + the same marker-bounded block.
        $claudeBody = (Get-ManagedBlockContent -Content $claudePayloadText -Label 'src') -join "`n"
        $codexBody  = (Get-ManagedBlockContent -Content $codexPayloadText  -Label 'src') -join "`n"
        # Get-ManagedBlockContent returns lines INCLUDING marker lines; strip them so the
        # surrounding wrapper does not double-mark the block.
        $claudeBodyInner = (($claudeBody -split "`n") | Where-Object { $_ -ne $script:BeginMarker -and $_ -ne $script:EndMarker }) -join "`n"
        $codexBodyInner  = (($codexBody  -split "`n") | Where-Object { $_ -ne $script:BeginMarker -and $_ -ne $script:EndMarker }) -join "`n"

        script:Write-TextFile (Join-Path $ClaudeHome 'CLAUDE.md') (script:Get-MarkedDestinationText -MarkedBlockBody $claudeBodyInner)
        script:Write-TextFile (Join-Path $CodexHome  'AGENTS.md') (script:Get-MarkedDestinationText -MarkedBlockBody $codexBodyInner)
        # Skill mirror — whole-file copy.
        script:Write-TextFile (Join-Path $ClaudeHome 'skills/ai-harness-review/SKILL.md') $skillPayloadText
    }

    function script:Invoke-InstallUpdate {
        param([hashtable] $CallParams)
        $argList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $script:Entry)
        foreach ($k in $CallParams.Keys) {
            $v = $CallParams[$k]
            if ($null -eq $v) { continue }
            if ($v -is [System.Management.Automation.SwitchParameter] -or $v -is [bool]) {
                if ([bool]$v) { $argList += ('-' + $k) }
            }
            else {
                $argList += @(('-' + $k), [string]$v)
            }
        }
        $proc = Invoke-NativeProcess -Executable 'powershell.exe' -Arguments $argList
        # Parse the JSON body out of stdout (between BEGIN JSON / END JSON markers).
        $jsonText = $null
        $stdoutLines = $proc.Stdout -split "`r?`n"
        $inJson = $false
        $jsonBuf = New-Object System.Collections.Generic.List[string]
        foreach ($line in $stdoutLines) {
            if ($line -eq '--- BEGIN JSON ---') { $inJson = $true; continue }
            if ($line -eq '--- END JSON ---')   { $inJson = $false; continue }
            if ($inJson) { $jsonBuf.Add($line) }
        }
        if ($jsonBuf.Count -gt 0) {
            $jsonText = ($jsonBuf -join "`n")
        }
        $jsonObj = $null
        if (-not [string]::IsNullOrEmpty($jsonText)) {
            try { $jsonObj = $jsonText | ConvertFrom-Json } catch { $jsonObj = $null }
        }
        return [pscustomobject]@{
            ExitCode = $proc.ExitCode
            Stdout   = $proc.Stdout
            Stderr   = $proc.Stderr
            Json     = $jsonObj
        }
    }

    function script:Get-PathTreeSnapshot {
        # 3-axis identity snapshot: file count + per-file SHA-256 + per-file LastWriteTimeUtc ticks.
        param([string] $Root)
        if (-not (Test-Path -LiteralPath $Root -PathType Container)) {
            return [pscustomobject]@{ Exists = $false; Count = 0; Entries = @() }
        }
        $entries = @()
        $files = @(Get-ChildItem -LiteralPath $Root -Recurse -File -Force -ErrorAction SilentlyContinue)
        foreach ($f in ($files | Sort-Object FullName)) {
            $sha = $null
            try { $sha = (Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash } catch { $sha = $null }
            $entries += [pscustomobject]@{
                Path  = $f.FullName.Substring($Root.Length).TrimStart([char]'\',[char]'/')
                Sha256 = $sha
                Mtime = $f.LastWriteTimeUtc.Ticks
            }
        }
        return [pscustomobject]@{ Exists = $true; Count = $entries.Count; Entries = $entries }
    }

    function script:Assert-PathTreeUnchanged {
        param([pscustomobject] $Before, [pscustomobject] $After, [string] $Label)
        $Before.Exists  | Should -BeExactly $After.Exists -Because ("$Label existence changed")
        $Before.Count   | Should -BeExactly $After.Count  -Because ("$Label file count changed")
        for ($i = 0; $i -lt $Before.Entries.Count; $i++) {
            $b = $Before.Entries[$i]
            $a = $After.Entries[$i]
            $a.Path   | Should -BeExactly $b.Path   -Because ("$Label path ordering changed at index $i")
            $a.Sha256 | Should -BeExactly $b.Sha256 -Because ("$Label sha256 changed: " + $b.Path)
            $a.Mtime  | Should -BeExactly $b.Mtime  -Because ("$Label mtime changed: " + $b.Path)
        }
    }

    function script:Get-InstallMdSection {
        # Dynamic start-level extractor — start heading regex matches H2 or H3; record the
        # match's '#' count and stop at the next heading of the same or higher level.
        param([string] $Content, [string] $HeadingRegex)
        $lines = $Content -split "`r?`n"
        $startIdx = $null
        $startLevel = $null
        for ($i = 0; $i -lt $lines.Length; $i++) {
            if ($lines[$i] -match $HeadingRegex) {
                $startIdx = $i
                if ($lines[$i] -match '^(#{1,6})\s') { $startLevel = $matches[1].Length }
                break
            }
        }
        if ($null -eq $startIdx) { return '' }
        $endIdx = $lines.Length - 1
        for ($j = $startIdx + 1; $j -lt $lines.Length; $j++) {
            if ($lines[$j] -match '^(#{1,6})\s') {
                $level = $matches[1].Length
                if ($level -le $startLevel) { $endIdx = $j - 1; break }
            }
        }
        return ($lines[$startIdx..$endIdx] -join "`n")
    }

    # Allowed terminal-status enumeration per INSTALL.md §13.1.
    $script:AllowedStatuses = @(
        'inspect_clean','inspect_payload_drift','inspect_source_drift','inspect_activation_drift','inspect_mode_unknown',
        'verify_pass','verify_failed',
        'noop_already_current','complete','activation_pending','activation_applied_verify_failed',
        'smoke_failed','cleanup_failed_with_leftover','failed','update_aborted_no_approval'
    )

    # Hygiene scan literal + regex sets (mirror of design §4.7 Tier A / Tier B).
    $script:TierA = @(
        'polishing/','polishing\',
        'repo_snapshot/','repo_snapshot\',
        'H:\Work\','H:/Work/','/h/Work/',
        'C:\Users\','c:\users\',
        '_direction_20','_analysis_20','_merged_analysis_20',
        '_implementation_design_20','_codex_review_20','_polishing_log_20'
    )
    $script:TierB = @(
        '\b\d{8}T\d{6}Z',
        'log[\\/](review|evidence|chatlog|review_polishing|install-update)[\\/][A-Za-z0-9._\\/-]+\.(md|json|ps1|txt|log)',
        '\btests[\\/][A-Za-z0-9._\\/-]+\.(Tests\.ps1|ps1)\b',
        '\bdocs[\\/](systems|contracts|policies|decisions|roadmap|current|user_guide|project|archive)[\\/][A-Za-z0-9._\\/-]+\.md'
    )
}

Describe 'install-update.ps1 — inspect mode' {

    It 'T01: clean install → inspect_clean, exit 0' {
        $src = script:New-FixtureGitRepo -CaseName 't01'
        $area = script:New-FixtureInstallArea -CaseName 't01'
        $homes = script:New-FixtureHomeRoots -CaseName 't01'
        script:Initialize-CleanInstallFixture -InstallArea $area -ClaudeHome $homes.ClaudeHome -CodexHome $homes.CodexHome -SourcePath $src.Root -Head $src.Head

        $r = script:Invoke-InstallUpdate -CallParams @{
            Mode = 'inspect'
            InstallArea = $area
            ClaudeHome = $homes.ClaudeHome
            CodexHome = $homes.CodexHome
            SourcePath = $src.Root
        }
        $r.ExitCode | Should -BeExactly 0
        $r.Json     | Should -Not -BeNullOrEmpty
        $r.Json.status | Should -BeExactly 'inspect_clean'
        $r.Json.payloadDeltaRequired | Should -BeExactly $false
        $r.Json.manifestMarkerCrossBindingOk | Should -BeExactly $true
        (@($r.Json.activationSurfaces | Where-Object { $_.byteIdentical -eq $false })).Count | Should -BeExactly 0
    }

    It 'T02: source-drift (source HEAD ahead of lastUpdatedHead) → inspect_source_drift, exit 0' {
        $src = script:New-FixtureGitRepo -CaseName 't02'
        $area = script:New-FixtureInstallArea -CaseName 't02'
        $homes = script:New-FixtureHomeRoots -CaseName 't02'
        # Initialize fixture with the seed HEAD as lastUpdatedHead.
        script:Initialize-CleanInstallFixture -InstallArea $area -ClaudeHome $homes.ClaudeHome -CodexHome $homes.CodexHome -SourcePath $src.Root -Head $src.Head
        # Move source HEAD forward.
        $newHead = script:Add-FixtureGitCommit -Root $src.Root -Suffix 't02'
        $newHead | Should -Not -BeExactly $src.Head

        $r = script:Invoke-InstallUpdate -CallParams @{
            Mode = 'inspect'
            InstallArea = $area
            ClaudeHome = $homes.ClaudeHome
            CodexHome = $homes.CodexHome
            SourcePath = $src.Root
        }
        $r.ExitCode | Should -BeExactly 0
        $r.Json.status | Should -BeExactly 'inspect_source_drift'
        $r.Json.payloadDeltaRequired | Should -BeExactly $true
        $r.Json.sourceResolvedHead | Should -BeExactly $newHead
        $r.Json.lastUpdatedHead   | Should -BeExactly $src.Head
    }

    It 'T02b: git-url mode derives branch from install.json (non-main) for source HEAD resolve' {
        $bare = script:New-FixtureBareRepoWithBranch -CaseName 't02b' -BranchName 'release-x'
        $bare.BranchHead | Should -Not -BeExactly $bare.MainHead
        $area = script:New-FixtureInstallArea -CaseName 't02b'
        $homes = script:New-FixtureHomeRoots -CaseName 't02b'
        # Installed identity = main HEAD, but the install tracks the 'release-x' branch.
        # No -Branch / -SourcePath is passed to inspect, so the branch must come from
        # install.json.branch; resolving release-x (≠ main) yields source-drift.
        script:Initialize-CleanInstallFixture -InstallArea $area -ClaudeHome $homes.ClaudeHome -CodexHome $homes.CodexHome -SourcePath $bare.BareUrl -Head $bare.MainHead -InstallMode 'git-url' -RepoUrl $bare.BareUrl -Branch 'release-x'

        $r = script:Invoke-InstallUpdate -CallParams @{
            Mode = 'inspect'
            InstallArea = $area
            ClaudeHome = $homes.ClaudeHome
            CodexHome = $homes.CodexHome
        }
        $r.ExitCode | Should -BeExactly 0
        $r.Json.status | Should -BeExactly 'inspect_source_drift'
        $r.Json.sourceResolvedHead | Should -BeExactly $bare.BranchHead
        $r.Json.lastUpdatedHead    | Should -BeExactly $bare.MainHead
    }

    It 'T03: payload-drift (marker.head ≠ install.json.lastUpdatedHead) → inspect_payload_drift, exit 0' {
        $src = script:New-FixtureGitRepo -CaseName 't03'
        $area = script:New-FixtureInstallArea -CaseName 't03'
        $homes = script:New-FixtureHomeRoots -CaseName 't03'
        script:Initialize-CleanInstallFixture -InstallArea $area -ClaudeHome $homes.ClaudeHome -CodexHome $homes.CodexHome -SourcePath $src.Root -Head $src.Head
        # Mutate the marker.head to a different (but well-formed) sha.
        $markerPath = Get-InstallPipelineMarkerPath -InstallArea $area
        $marker = Read-InstallPipelineMarker -InstallArea $area
        $marker.head = ('0' * 40)
        Write-InstallPipelineMarker -InstallArea $area -Marker $marker

        $r = script:Invoke-InstallUpdate -CallParams @{
            Mode = 'inspect'
            InstallArea = $area
            ClaudeHome = $homes.ClaudeHome
            CodexHome = $homes.CodexHome
            SourcePath = $src.Root
        }
        $r.ExitCode | Should -BeExactly 0
        $r.Json.status | Should -BeExactly 'inspect_payload_drift'
        $r.Json.manifestMarkerCrossBindingOk | Should -BeExactly $false
    }

    It 'T04a: activation surface absent → inspect_activation_drift (reason: absent)' {
        $src = script:New-FixtureGitRepo -CaseName 't04a'
        $area = script:New-FixtureInstallArea -CaseName 't04a'
        $homes = script:New-FixtureHomeRoots -CaseName 't04a'
        script:Initialize-CleanInstallFixture -InstallArea $area -ClaudeHome $homes.ClaudeHome -CodexHome $homes.CodexHome -SourcePath $src.Root -Head $src.Head
        # Remove the Claude managed-block destination file.
        Remove-Item -LiteralPath (Join-Path $homes.ClaudeHome 'CLAUDE.md') -Force

        $r = script:Invoke-InstallUpdate -CallParams @{
            Mode = 'inspect'
            InstallArea = $area
            ClaudeHome = $homes.ClaudeHome
            CodexHome = $homes.CodexHome
            SourcePath = $src.Root
        }
        $r.ExitCode | Should -BeExactly 0
        $r.Json.status | Should -BeExactly 'inspect_activation_drift'
        $claudeRow = $r.Json.activationSurfaces | Where-Object { $_.name -eq 'claude-user-global-managed-block' }
        $claudeRow.exists | Should -BeExactly $false
        $claudeRow.reason | Should -BeExactly 'absent'
    }

    It 'T04b: activation surface byte-mismatch → inspect_activation_drift (reason: byte-mismatch)' {
        $src = script:New-FixtureGitRepo -CaseName 't04b'
        $area = script:New-FixtureInstallArea -CaseName 't04b'
        $homes = script:New-FixtureHomeRoots -CaseName 't04b'
        script:Initialize-CleanInstallFixture -InstallArea $area -ClaudeHome $homes.ClaudeHome -CodexHome $homes.CodexHome -SourcePath $src.Root -Head $src.Head
        # Drift the skill mirror content (whole-file SHA-256 will differ).
        $skillDest = Join-Path $homes.ClaudeHome 'skills/ai-harness-review/SKILL.md'
        script:Write-TextFile $skillDest "---`nname: ai-harness-review`n---`n# DRIFTED skill body`n"

        $r = script:Invoke-InstallUpdate -CallParams @{
            Mode = 'inspect'
            InstallArea = $area
            ClaudeHome = $homes.ClaudeHome
            CodexHome = $homes.CodexHome
            SourcePath = $src.Root
        }
        $r.ExitCode | Should -BeExactly 0
        $r.Json.status | Should -BeExactly 'inspect_activation_drift'
        $skillRow = $r.Json.activationSurfaces | Where-Object { $_.name -eq 'review-skill-mirror' }
        $skillRow.exists        | Should -BeExactly $true
        $skillRow.byteIdentical | Should -BeExactly $false
        $skillRow.reason        | Should -Match '^byte-mismatch'
    }

    It 'T04c: activation surface read-error → inspect_activation_drift (reason: read-error)' {
        $src = script:New-FixtureGitRepo -CaseName 't04c'
        $area = script:New-FixtureInstallArea -CaseName 't04c'
        $homes = script:New-FixtureHomeRoots -CaseName 't04c'
        script:Initialize-CleanInstallFixture -InstallArea $area -ClaudeHome $homes.ClaudeHome -CodexHome $homes.CodexHome -SourcePath $src.Root -Head $src.Head
        # Replace the Codex managed-block destination with a malformed marker pair
        # (no END) so Get-ManagedBlockContent throws → script classifies as read-error.
        script:Write-TextFile (Join-Path $homes.CodexHome 'AGENTS.md') ("# user content`n" + $script:BeginMarker + "`nbody`n# no end marker`ntail`n")

        $r = script:Invoke-InstallUpdate -CallParams @{
            Mode = 'inspect'
            InstallArea = $area
            ClaudeHome = $homes.ClaudeHome
            CodexHome = $homes.CodexHome
            SourcePath = $src.Root
        }
        $r.ExitCode | Should -BeExactly 0
        $r.Json.status | Should -BeExactly 'inspect_activation_drift'
        $codexRow = $r.Json.activationSurfaces | Where-Object { $_.name -eq 'codex-user-global-managed-block' }
        $codexRow.exists        | Should -BeExactly $true
        $codexRow.byteIdentical | Should -BeExactly $false
        $codexRow.reason        | Should -Match '^(read-error|byte-mismatch)'
    }

    It 'T04d: Codex AGENTS.override.md precedence → drifted override yields inspect_activation_drift on the effective destination' {
        $src = script:New-FixtureGitRepo -CaseName 't04d'
        $area = script:New-FixtureInstallArea -CaseName 't04d'
        $homes = script:New-FixtureHomeRoots -CaseName 't04d'
        script:Initialize-CleanInstallFixture -InstallArea $area -ClaudeHome $homes.ClaudeHome -CodexHome $homes.CodexHome -SourcePath $src.Root -Head $src.Head
        # AGENTS.md is byte-identical (clean); add AGENTS.override.md as the effective
        # destination with a DRIFTED managed-block body. The effective Codex surface is
        # now the override, so the surface must report drift.
        script:Write-TextFile (Join-Path $homes.CodexHome 'AGENTS.override.md') (script:Get-MarkedDestinationText -MarkedBlockBody '# DRIFTED codex override body')

        $r = script:Invoke-InstallUpdate -CallParams @{
            Mode = 'inspect'
            InstallArea = $area
            ClaudeHome = $homes.ClaudeHome
            CodexHome = $homes.CodexHome
            SourcePath = $src.Root
        }
        $r.ExitCode | Should -BeExactly 0
        $r.Json.status | Should -BeExactly 'inspect_activation_drift'
        $codexRow = $r.Json.activationSurfaces | Where-Object { $_.name -eq 'codex-user-global-managed-block' }
        $codexRow.byteIdentical | Should -BeExactly $false
        $codexRow.path | Should -Match 'AGENTS\.override\.md$'
    }

    It 'T05: install.json absent → inspect_mode_unknown' {
        $src = script:New-FixtureGitRepo -CaseName 't05'
        $area = script:New-FixtureInstallArea -CaseName 't05'
        $homes = script:New-FixtureHomeRoots -CaseName 't05'
        # No initialization — install.json is absent.

        $r = script:Invoke-InstallUpdate -CallParams @{
            Mode = 'inspect'
            InstallArea = $area
            ClaudeHome = $homes.ClaudeHome
            CodexHome = $homes.CodexHome
            SourcePath = $src.Root
        }
        $r.ExitCode | Should -BeExactly 0
        $r.Json.status | Should -BeExactly 'inspect_mode_unknown'
        $r.Json.installState  | Should -BeExactly 'absent'
        $r.Json.metadataValid | Should -BeExactly $false
    }

    It 'T05b: install.json schema mismatch (invalid installMode) → inspect_mode_unknown (not payload/source classification)' {
        $src = script:New-FixtureGitRepo -CaseName 't05b'
        $area = script:New-FixtureInstallArea -CaseName 't05b'
        $homes = script:New-FixtureHomeRoots -CaseName 't05b'
        script:Initialize-CleanInstallFixture -InstallArea $area -ClaudeHome $homes.ClaudeHome -CodexHome $homes.CodexHome -SourcePath $src.Root -Head $src.Head
        # Corrupt install.json with an invalid installMode value (schemaVersion still 1, so the
        # reader passes; only the focused inspect schema check should catch it).
        $metaPath = Get-InstallPipelineMetadataPath -InstallArea $area
        $meta = Read-InstallPipelineMetadata -InstallArea $area
        $meta.installMode = 'bogus-mode'
        Write-JsonUtf8NoBom -Path $metaPath -Value $meta

        $r = script:Invoke-InstallUpdate -CallParams @{
            Mode = 'inspect'
            InstallArea = $area
            ClaudeHome = $homes.ClaudeHome
            CodexHome = $homes.CodexHome
            SourcePath = $src.Root
        }
        $r.ExitCode | Should -BeExactly 0
        $r.Json.status | Should -BeExactly 'inspect_mode_unknown'
        $r.Json.metadataValid | Should -BeExactly $false
        (@($r.Json.reasons) -join "`n") | Should -Match '(?i)installMode'
    }

    It 'T05c: install.json mode-conditional mismatch (git-url with non-empty sourcePath/toolRoot) → inspect_mode_unknown' {
        $src = script:New-FixtureGitRepo -CaseName 't05c'
        $area = script:New-FixtureInstallArea -CaseName 't05c'
        $homes = script:New-FixtureHomeRoots -CaseName 't05c'
        # Clean local-clone fixture (sourcePath / toolRoot non-empty, repoUrl empty), then flip
        # installMode to git-url WITHOUT clearing sourcePath / toolRoot and without setting repoUrl.
        # Under INSTALL.md §4 this is a mode-conditional schema mismatch (git-url requires repoUrl
        # non-empty + sourcePath/toolRoot empty), so inspect must classify inspect_mode_unknown.
        script:Initialize-CleanInstallFixture -InstallArea $area -ClaudeHome $homes.ClaudeHome -CodexHome $homes.CodexHome -SourcePath $src.Root -Head $src.Head
        $metaPath = Get-InstallPipelineMetadataPath -InstallArea $area
        $meta = Read-InstallPipelineMetadata -InstallArea $area
        $meta.installMode = 'git-url'
        Write-JsonUtf8NoBom -Path $metaPath -Value $meta

        $r = script:Invoke-InstallUpdate -CallParams @{
            Mode = 'inspect'
            InstallArea = $area
            ClaudeHome = $homes.ClaudeHome
            CodexHome = $homes.CodexHome
            SourcePath = $src.Root
        }
        $r.ExitCode | Should -BeExactly 0
        $r.Json.status | Should -BeExactly 'inspect_mode_unknown'
        $r.Json.metadataValid | Should -BeExactly $false
        (@($r.Json.reasons) -join "`n") | Should -Match '(?i)(sourcePath|toolRoot|repoUrl).*git-url'
    }
}

Describe 'install-update.ps1 — verify mode' {

    It 'T06: clean install → verify_pass, exit 0' {
        $src = script:New-FixtureGitRepo -CaseName 't06'
        $area = script:New-FixtureInstallArea -CaseName 't06'
        $homes = script:New-FixtureHomeRoots -CaseName 't06'
        script:Initialize-CleanInstallFixture -InstallArea $area -ClaudeHome $homes.ClaudeHome -CodexHome $homes.CodexHome -SourcePath $src.Root -Head $src.Head

        $r = script:Invoke-InstallUpdate -CallParams @{
            Mode = 'verify'
            InstallArea = $area
            ClaudeHome = $homes.ClaudeHome
            CodexHome = $homes.CodexHome
        }
        $r.ExitCode | Should -BeExactly 0
        $r.Json.status | Should -BeExactly 'verify_pass'
        (@($r.Json.activationSurfaces | Where-Object { $_.byteIdentical -eq $false })).Count | Should -BeExactly 0
    }

    It 'T07: cross-binding broken (marker.head ≠ install.json.lastUpdatedHead) → verify_failed, exit 1' {
        $src = script:New-FixtureGitRepo -CaseName 't07'
        $area = script:New-FixtureInstallArea -CaseName 't07'
        $homes = script:New-FixtureHomeRoots -CaseName 't07'
        script:Initialize-CleanInstallFixture -InstallArea $area -ClaudeHome $homes.ClaudeHome -CodexHome $homes.CodexHome -SourcePath $src.Root -Head $src.Head
        $marker = Read-InstallPipelineMarker -InstallArea $area
        $marker.head = ('1' * 40)
        Write-InstallPipelineMarker -InstallArea $area -Marker $marker

        $r = script:Invoke-InstallUpdate -CallParams @{
            Mode = 'verify'
            InstallArea = $area
            ClaudeHome = $homes.ClaudeHome
            CodexHome = $homes.CodexHome
        }
        $r.ExitCode | Should -BeExactly 1
        $r.Json.status | Should -BeExactly 'verify_failed'
        (@($r.Json.reasons) -join "`n") | Should -Match '(?i)marker.*(head|lastUpdatedHead)'
    }

    It 'T08: manifest digest mismatch → verify_failed, exit 1' {
        $src = script:New-FixtureGitRepo -CaseName 't08'
        $area = script:New-FixtureInstallArea -CaseName 't08'
        $homes = script:New-FixtureHomeRoots -CaseName 't08'
        script:Initialize-CleanInstallFixture -InstallArea $area -ClaudeHome $homes.ClaudeHome -CodexHome $homes.CodexHome -SourcePath $src.Root -Head $src.Head
        # Mutate one payload file so its real SHA-256 no longer matches the manifest.
        script:Write-TextFile (Join-Path $area 'current/scripts/marker.txt') 'TAMPERED'

        $r = script:Invoke-InstallUpdate -CallParams @{
            Mode = 'verify'
            InstallArea = $area
            ClaudeHome = $homes.ClaudeHome
            CodexHome = $homes.CodexHome
        }
        $r.ExitCode | Should -BeExactly 1
        $r.Json.status | Should -BeExactly 'verify_failed'
    }

    It 'T08b: activation byte-mismatch → verify_failed (reason: activation)' {
        $src = script:New-FixtureGitRepo -CaseName 't08b'
        $area = script:New-FixtureInstallArea -CaseName 't08b'
        $homes = script:New-FixtureHomeRoots -CaseName 't08b'
        script:Initialize-CleanInstallFixture -InstallArea $area -ClaudeHome $homes.ClaudeHome -CodexHome $homes.CodexHome -SourcePath $src.Root -Head $src.Head
        # Drift the Claude managed-block body inside the destination's marker pair
        # so byte-identity fails while marker structure is still valid.
        script:Write-TextFile (Join-Path $homes.ClaudeHome 'CLAUDE.md') (script:Get-MarkedDestinationText -MarkedBlockBody '# DRIFTED claude body')

        $r = script:Invoke-InstallUpdate -CallParams @{
            Mode = 'verify'
            InstallArea = $area
            ClaudeHome = $homes.ClaudeHome
            CodexHome = $homes.CodexHome
        }
        $r.ExitCode | Should -BeExactly 1
        $r.Json.status | Should -BeExactly 'verify_failed'
        (@($r.Json.reasons) -join "`n") | Should -Match 'activation surface byte-identity fail'
    }

    It 'T08c: verify rejects local-clone metadata with non-empty repoUrl (mode-conditional schema) → verify_failed' {
        $src = script:New-FixtureGitRepo -CaseName 't08c'
        $area = script:New-FixtureInstallArea -CaseName 't08c'
        $homes = script:New-FixtureHomeRoots -CaseName 't08c'
        script:Initialize-CleanInstallFixture -InstallArea $area -ClaudeHome $homes.ClaudeHome -CodexHome $homes.CodexHome -SourcePath $src.Root -Head $src.Head
        # Inject a documented mode-conditional schema mismatch: local-clone with a non-empty
        # repoUrl (INSTALL.md §4/§5 require repoUrl empty for local-clone). The canonical
        # Invoke-InstallPipelineVerify (which verify mode delegates to) now enforces this rule,
        # so verify mode emits verify_failed end-to-end through the entrypoint.
        $metaPath = Get-InstallPipelineMetadataPath -InstallArea $area
        $meta = Read-InstallPipelineMetadata -InstallArea $area
        $meta.repoUrl = 'https://example.invalid/should-be-empty-for-local-clone.git'
        Write-JsonUtf8NoBom -Path $metaPath -Value $meta

        $r = script:Invoke-InstallUpdate -CallParams @{
            Mode = 'verify'
            InstallArea = $area
            ClaudeHome = $homes.ClaudeHome
            CodexHome = $homes.CodexHome
        }
        $r.ExitCode | Should -BeExactly 1
        $r.Json.status | Should -BeExactly 'verify_failed'
        (@($r.Json.reasons) -join "`n") | Should -Match '(?i)repoUrl.*local-clone'
    }
}

Describe 'install-update.ps1 — status vocabulary and exit code mapping (T09)' {

    It 'every emitted status is in the §13.1 enumeration AND exit code matches §13.3 mapping' {
        $src = script:New-FixtureGitRepo -CaseName 't09'
        # T01 (inspect_clean / 0), T07 (verify_failed / 1), T05 (inspect_mode_unknown / 0).
        $cases = @(
            @{ Name = 'clean-inspect'; Mode = 'inspect'; Setup = $true;  Mutate = $null; ExpectedStatus = 'inspect_clean';        ExpectedExit = 0 },
            @{ Name = 'mode-unknown';  Mode = 'inspect'; Setup = $false; Mutate = $null; ExpectedStatus = 'inspect_mode_unknown'; ExpectedExit = 0 },
            @{ Name = 'verify-fail';   Mode = 'verify';  Setup = $true;  Mutate = 'cross-binding'; ExpectedStatus = 'verify_failed'; ExpectedExit = 1 }
        )
        foreach ($c in $cases) {
            $area = script:New-FixtureInstallArea -CaseName ('t09-' + $c.Name)
            $homes = script:New-FixtureHomeRoots -CaseName ('t09-' + $c.Name)
            if ($c.Setup) {
                script:Initialize-CleanInstallFixture -InstallArea $area -ClaudeHome $homes.ClaudeHome -CodexHome $homes.CodexHome -SourcePath $src.Root -Head $src.Head
            }
            if ($c.Mutate -eq 'cross-binding') {
                $marker = Read-InstallPipelineMarker -InstallArea $area
                $marker.head = ('2' * 40)
                Write-InstallPipelineMarker -InstallArea $area -Marker $marker
            }
            $invokeArgs = @{
                Mode = $c.Mode
                InstallArea = $area
                ClaudeHome = $homes.ClaudeHome
                CodexHome = $homes.CodexHome
            }
            if ($c.Mode -eq 'inspect') { $invokeArgs.SourcePath = $src.Root }
            $r = script:Invoke-InstallUpdate -CallParams $invokeArgs
            $r.ExitCode    | Should -BeExactly $c.ExpectedExit -Because $c.Name
            $r.Json.status | Should -BeExactly $c.ExpectedStatus -Because $c.Name
            $script:AllowedStatuses | Should -Contain $r.Json.status -Because ($c.Name + ' — status not in §13.1 enumeration')
        }
    }
}

Describe 'install-update.ps1 — no-write sentinel (T10)' {

    It 'fixture inspect does not write to InstallArea, ClaudeHome, CodexHome, real user-global Claude/Codex' {
        $src = script:New-FixtureGitRepo -CaseName 't10'
        $area = script:New-FixtureInstallArea -CaseName 't10'
        $homes = script:New-FixtureHomeRoots -CaseName 't10'
        script:Initialize-CleanInstallFixture -InstallArea $area -ClaudeHome $homes.ClaudeHome -CodexHome $homes.CodexHome -SourcePath $src.Root -Head $src.Head

        $snapAreaBefore  = script:Get-PathTreeSnapshot -Root $area
        $snapCHomeBefore = script:Get-PathTreeSnapshot -Root $homes.ClaudeHome
        $snapXHomeBefore = script:Get-PathTreeSnapshot -Root $homes.CodexHome
        # Real user-global sanity probe — file count only (full 3-axis would be slow).
        $realClaudeRoot = Join-Path $env:USERPROFILE '.claude'
        $realCodexRoot  = Join-Path $env:USERPROFILE '.codex'
        $realCBefore = if (Test-Path -LiteralPath $realClaudeRoot) { @(Get-ChildItem -LiteralPath $realClaudeRoot -Recurse -File -Force -ErrorAction SilentlyContinue).Count } else { -1 }
        $realXBefore = if (Test-Path -LiteralPath $realCodexRoot)  { @(Get-ChildItem -LiteralPath $realCodexRoot  -Recurse -File -Force -ErrorAction SilentlyContinue).Count } else { -1 }

        $r1 = script:Invoke-InstallUpdate -CallParams @{ Mode = 'inspect'; InstallArea = $area; ClaudeHome = $homes.ClaudeHome; CodexHome = $homes.CodexHome; SourcePath = $src.Root }
        $r2 = script:Invoke-InstallUpdate -CallParams @{ Mode = 'verify';  InstallArea = $area; ClaudeHome = $homes.ClaudeHome; CodexHome = $homes.CodexHome }
        $r1.ExitCode | Should -BeIn @(0, 1)
        $r2.ExitCode | Should -BeIn @(0, 1)

        $snapAreaAfter  = script:Get-PathTreeSnapshot -Root $area
        $snapCHomeAfter = script:Get-PathTreeSnapshot -Root $homes.ClaudeHome
        $snapXHomeAfter = script:Get-PathTreeSnapshot -Root $homes.CodexHome
        $realCAfter = if (Test-Path -LiteralPath $realClaudeRoot) { @(Get-ChildItem -LiteralPath $realClaudeRoot -Recurse -File -Force -ErrorAction SilentlyContinue).Count } else { -1 }
        $realXAfter = if (Test-Path -LiteralPath $realCodexRoot)  { @(Get-ChildItem -LiteralPath $realCodexRoot  -Recurse -File -Force -ErrorAction SilentlyContinue).Count } else { -1 }

        script:Assert-PathTreeUnchanged -Before $snapAreaBefore  -After $snapAreaAfter  -Label 'InstallArea'
        script:Assert-PathTreeUnchanged -Before $snapCHomeBefore -After $snapCHomeAfter -Label 'ClaudeHome (TestDrive)'
        script:Assert-PathTreeUnchanged -Before $snapXHomeBefore -After $snapXHomeAfter -Label 'CodexHome (TestDrive)'
        # Real user-global file count must not increase (best-effort probe; per design §9.4 known
        # limits, this does not catch directory-only creation / ACL / ADS mutation — V7 manual review).
        $realCAfter | Should -BeExactly $realCBefore -Because 'real %USERPROFILE%\.claude file count changed'
        $realXAfter | Should -BeExactly $realXBefore -Because 'real %USERPROFILE%\.codex file count changed'
    }
}

Describe 'install-update.ps1 — deployable-reference hygiene scan' {

    BeforeAll {
        $script:NewArtifactContent = Get-Content -LiteralPath $script:Entry      -Raw -Encoding UTF8
        $script:InstallMdContent   = Get-Content -LiteralPath $script:InstallMd  -Raw -Encoding UTF8
        $script:Section71 = script:Get-InstallMdSection -Content $script:InstallMdContent -HeadingRegex '^#{2,3}\s+7\.1\s'
        $script:Section11 = script:Get-InstallMdSection -Content $script:InstallMdContent -HeadingRegex '^##\s+11\.\s'
        $script:Section13 = script:Get-InstallMdSection -Content $script:InstallMdContent -HeadingRegex '^##\s+13\.\s'
    }

    It 'T11: Tier A literal substrings are absent from new deployable artifact + INSTALL.md §7.1/§11/§13 spans' {
        $script:Section71 | Should -Not -BeNullOrEmpty
        $script:Section11 | Should -Not -BeNullOrEmpty
        $script:Section13 | Should -Not -BeNullOrEmpty
        $bodies = @($script:NewArtifactContent, $script:Section71, $script:Section11, $script:Section13)
        foreach ($body in $bodies) {
            foreach ($lit in $script:TierA) {
                $body | Should -Not -Match ([regex]::Escape($lit))
            }
        }
    }

    It 'T12: Tier B regex patterns do not match new deployable artifact + INSTALL.md §7.1/§11/§13 spans' {
        $script:Section71 | Should -Not -BeNullOrEmpty
        $script:Section11 | Should -Not -BeNullOrEmpty
        $script:Section13 | Should -Not -BeNullOrEmpty
        $bodies = @($script:NewArtifactContent, $script:Section71, $script:Section11, $script:Section13)
        foreach ($body in $bodies) {
            foreach ($rx in $script:TierB) {
                $body | Should -Not -Match $rx
            }
        }
    }

    It 'T12b: section-span extractor recovers §7.1 (H3) / §11 (H2) / §13 (H2) with same/higher-level boundary' {
        # §7.1 — H3 span; no other heading allowed inside (excluding the start heading itself).
        $script:Section71 | Should -Match '^#{2,3}\s+7\.1\s'
        (@(($script:Section71 -split "`n") | Where-Object { $_ -match '^#{1,3}\s' })).Count | Should -Be 1
        # §11 — H2 span; no other H1/H2 inside.
        $script:Section11 | Should -Match '^##\s+11\.\s'
        (@(($script:Section11 -split "`n") | Where-Object { $_ -match '^#{1,2}\s' })).Count | Should -Be 1
        # §13 — H2 span; no other H1/H2 inside.
        $script:Section13 | Should -Match '^##\s+13\.\s'
        (@(($script:Section13 -split "`n") | Where-Object { $_ -match '^#{1,2}\s' })).Count | Should -Be 1
    }
}

Describe 'install-update.ps1 — production guard skeleton (T13)' {

    It 'install-update.ps1 source defines Assert-NoMutationPath with throw on reserved mutation flags (update-source is a mode, not a flag)' {
        $content = Get-Content -LiteralPath $script:Entry -Raw -Encoding UTF8
        $content | Should -Match 'function\s+script:Assert-NoMutationPath'
        # update-source is now a real MODE (approval-gated), so it is intentionally NOT in the
        # reserved-flag list; the remaining names stay reserved-and-unimplemented flags.
        $content | Should -Match 'mutationFlags\s*=\s*@\(\s*''ApplyActivation'',\s*''ApplyPayload'',\s*''RefreshSkill''\s*\)'
        $content | Should -Match 'throw\s+"install-update:\s*FAIL mutation flag'
        foreach ($flag in @('ApplyActivation','ApplyPayload','RefreshSkill')) {
            $content | Should -Match $flag
        }
        # The reserved-flag list must NOT contain 'UpdateSource' anymore (it is a mode).
        $content | Should -Not -Match 'mutationFlags\s*=\s*@\([^\)]*''UpdateSource''[^\)]*\)'
        # Invoke-Main exercises the guard.
        $content | Should -Match 'script:Assert-NoMutationPath\s+-Mode\s+\$Mode\s+-RequestedFlags'
    }
}

Describe 'install-update.ps1 — update-source apply orchestration (Batch 2)' {

    BeforeAll {
        # Dot-source the entrypoint to unit-test its internal functions without running main.
        # The dot-source guard (InvocationName -eq '.') prevents Invoke-Main from executing.
        . $script:Entry

        function script:New-UpdatableFixture {
            # A fixture whose source repo carries the payload roots so update-source can
            # archive a new HEAD into current/. Returns source + install area + homes + seedHead.
            param([string] $CaseName)
            $src = script:New-FixtureGitRepo -CaseName $CaseName
            # Add the 4 payload roots + D3 markers to the source so it is a valid ai-harness source.
            Push-Location $src.Root
            try {
                foreach ($r in 'config','scripts','snippets','templates') {
                    $null = New-Item -ItemType Directory -Path (Join-Path $src.Root $r) -Force
                }
                script:Write-TextFile (Join-Path $src.Root 'scripts/verify-ps1.ps1')    '# marker'
                script:Write-TextFile (Join-Path $src.Root 'templates/review-input.md') '# marker'
                script:Write-TextFile (Join-Path $src.Root 'config/reviewer.json')      '{}'
                script:Write-TextFile (Join-Path $src.Root 'snippets/CLAUDE_SNIPPET.md')                        (script:Get-FixtureClaudeSnippetText)
                script:Write-TextFile (Join-Path $src.Root 'snippets/AGENTS_SNIPPET.md')                        (script:Get-FixtureCodexSnippetText)
                script:Write-TextFile (Join-Path $src.Root 'snippets/claude-skills/ai-harness-review/SKILL.md') (script:Get-FixtureSkillText)
                & git add . 2>&1 | Out-Null
                & git commit -q -m 'payload v1' 2>&1 | Out-Null
                $seedHead = (Invoke-NativeProcess -Executable 'git' -Arguments @('rev-parse','HEAD')).Stdout.Trim()
            }
            finally { Pop-Location }

            $area = script:New-FixtureInstallArea -CaseName $CaseName
            $homes = script:New-FixtureHomeRoots -CaseName $CaseName
            # Materialize the install at seedHead via the canonical fixture entry (install action),
            # so install.json / manifest / marker / current/ are all consistent at seedHead.
            $proj = Join-Path $TestDrive ('proj-' + $CaseName)
            if (Test-Path -LiteralPath $proj) { Remove-Item -LiteralPath $proj -Recurse -Force }
            $null = New-Item -ItemType Directory -Path $proj -Force
            $null = New-Item -ItemType Directory -Path (Join-Path $proj '.git') -Force
            $fixtureEntry = Join-Path $script:RepoRoot 'tests/support/install-pipeline-fixture.ps1'
            $install = Invoke-NativeProcess -Executable 'powershell.exe' -Arguments @(
                '-NoProfile','-ExecutionPolicy','Bypass','-File',$fixtureEntry,
                '-Action','install','-InstallArea',$area,'-InstallMode','local-clone',
                '-SourcePath',$src.Root,'-Branch','main','-Remote','origin',
                '-ProjectRoot',$proj,'-RuntimeToolRoot',$proj
            )
            if ($install.ExitCode -ne 0) { throw ("fixture install failed: " + $install.Stdout + $install.Stderr) }

            # Make activation surfaces byte-identical to the installed payload snippets so the
            # apply reports a clean (no-op) activation rather than drift.
            $curDir = Join-Path $area 'current'
            $claudeText = Read-Utf8 -Path (Join-Path $curDir 'snippets/CLAUDE_SNIPPET.md')
            $codexText  = Read-Utf8 -Path (Join-Path $curDir 'snippets/AGENTS_SNIPPET.md')
            $skillText  = Read-Utf8 -Path (Join-Path $curDir 'snippets/claude-skills/ai-harness-review/SKILL.md')
            $claudeInner = ((Get-ManagedBlockContent -Content $claudeText -Label 'src') | Where-Object { $_ -ne $script:BeginMarker -and $_ -ne $script:EndMarker }) -join "`n"
            $codexInner  = ((Get-ManagedBlockContent -Content $codexText  -Label 'src') | Where-Object { $_ -ne $script:BeginMarker -and $_ -ne $script:EndMarker }) -join "`n"
            script:Write-TextFile (Join-Path $homes.ClaudeHome 'CLAUDE.md') (script:Get-MarkedDestinationText -MarkedBlockBody $claudeInner)
            script:Write-TextFile (Join-Path $homes.CodexHome  'AGENTS.md') (script:Get-MarkedDestinationText -MarkedBlockBody $codexInner)
            script:Write-TextFile (Join-Path $homes.ClaudeHome 'skills/ai-harness-review/SKILL.md') $skillText

            return [pscustomobject]@{ Source = $src; Area = $area; Homes = $homes; SeedHead = $seedHead }
        }
    }

    It 'B2-T1: pure two-choice selector decision logic (no real keypress)' {
        (script:Resolve-TwoChoiceKeySequence -Keys @('Enter'))           | Should -BeExactly 'yes'   # default highlight Yes + Enter
        (script:Resolve-TwoChoiceKeySequence -Keys @('Down','Enter'))    | Should -BeExactly 'no'
        (script:Resolve-TwoChoiceKeySequence -Keys @('Down','Up','Enter'))| Should -BeExactly 'yes'
        (script:Resolve-TwoChoiceKeySequence -Keys @('Escape'))          | Should -BeExactly 'no'
        (script:Resolve-TwoChoiceKeySequence -Keys @('Down'))            | Should -BeExactly 'no'    # no Enter → fail-safe No
        (script:Resolve-TwoChoiceKeySequence -Keys @())                  | Should -BeExactly 'no'    # empty → fail-safe No
    }

    It 'B2-T2: command-implied — update-source via child process (noninteractive) applies the delta → complete (no selector required)' {
        $fx = script:New-UpdatableFixture -CaseName 'b2t2'
        # Advance the source HEAD so a payload delta exists.
        $newHead = script:Add-FixtureGitCommit -Root $fx.Source.Root -Suffix 'b2t2'
        $newHead | Should -Not -BeExactly $fx.SeedHead

        # A child-process invocation has redirected stdin (the normal Claude Code shell shape).
        # Under command-implied approval the explicit update-source invocation IS the approval, so
        # the delta is applied without a terminal selector — this is the dogfood-gap fix.
        $r = script:Invoke-InstallUpdate -CallParams @{
            Mode = 'update-source'
            InstallArea = $fx.Area
            ClaudeHome = $fx.Homes.ClaudeHome
            CodexHome = $fx.Homes.CodexHome
            SourcePath = $fx.Source.Root
            SkipSmoke = $true
        }
        $r.ExitCode | Should -BeExactly 0
        $r.Json.status | Should -BeExactly 'complete'
        # Payload advanced to the new source HEAD.
        [string](Read-InstallPipelineMetadata -InstallArea $fx.Area).lastUpdatedHead | Should -BeExactly $newHead
    }

    It 'B2-T2b: command-implied does NOT override the source-cut guard — noninteractive update-source with a differing -Branch → failed, no mutation' {
        $fx = script:New-UpdatableFixture -CaseName 'b2t2b'   # installed with branch=main
        $null = script:Add-FixtureGitCommit -Root $fx.Source.Root -Suffix 'b2t2b'   # payload delta exists
        $snapBefore = script:Get-PathTreeSnapshot -Root $fx.Area
        $r = script:Invoke-InstallUpdate -CallParams @{
            Mode = 'update-source'
            InstallArea = $fx.Area
            ClaudeHome = $fx.Homes.ClaudeHome
            CodexHome = $fx.Homes.CodexHome
            SourcePath = $fx.Source.Root
            Branch = 'release-x'   # differs from install.json.branch=main → source-cut
            SkipSmoke = $true
        }
        $r.ExitCode | Should -BeExactly 1
        $r.Json.status | Should -BeExactly 'failed'
        (@($r.Json.reasons) -join "`n") | Should -Match '(?i)source-cut'
        $snapAfter = script:Get-PathTreeSnapshot -Root $fx.Area
        script:Assert-PathTreeUnchanged -Before $snapBefore -After $snapAfter -Label 'InstallArea (command-implied + source-cut guard)'
    }

    It 'B2-T2c: -ConfirmInteractive requested but noninteractive child process → update_aborted_no_approval, no mutation (no silent fall-through)' {
        $fx = script:New-UpdatableFixture -CaseName 'b2t2c'
        $null = script:Add-FixtureGitCommit -Root $fx.Source.Root -Suffix 'b2t2c'   # payload delta exists
        $snapBefore = script:Get-PathTreeSnapshot -Root $fx.Area
        $r = script:Invoke-InstallUpdate -CallParams @{
            Mode = 'update-source'
            InstallArea = $fx.Area
            ClaudeHome = $fx.Homes.ClaudeHome
            CodexHome = $fx.Homes.CodexHome
            SourcePath = $fx.Source.Root
            ConfirmInteractive = $true   # explicit confirm requested, but child process has no TTY
            SkipSmoke = $true
        }
        $r.ExitCode | Should -BeExactly 1
        $r.Json.status | Should -BeExactly 'update_aborted_no_approval'
        $snapAfter = script:Get-PathTreeSnapshot -Root $fx.Area
        script:Assert-PathTreeUnchanged -Before $snapBefore -After $snapAfter -Label 'InstallArea (-ConfirmInteractive no TTY)'
    }

    It 'B2-T3: update-source apply (approval implied) mutates payload, preserves installedHead, updates lastUpdatedHead, verify_pass→complete' {
        $fx = script:New-UpdatableFixture -CaseName 'b2t3'
        $mdBefore = Read-InstallPipelineMetadata -InstallArea $fx.Area
        $installedHeadBefore = [string]$mdBefore.installedHead
        $installedAtBefore   = [string]$mdBefore.installedAt
        $newHead = script:Add-FixtureGitCommit -Root $fx.Source.Root -Suffix 'b2t3'
        $newHead | Should -Not -BeExactly $fx.SeedHead

        # Invoke the apply orchestration directly. In production this function is reached under
        # command-implied approval (the explicit update-source invocation is the approval); here
        # the direct call stands in for that command-implied path.
        $res = script:Invoke-UpdateSourceApply -InstallArea $fx.Area -ClaudeHome $fx.Homes.ClaudeHome -CodexHome $fx.Homes.CodexHome -SourcePath $fx.Source.Root -SkipSmoke
        $res.Status   | Should -BeExactly 'complete'
        $res.ExitCode | Should -BeExactly 0

        $mdAfter = Read-InstallPipelineMetadata -InstallArea $fx.Area
        [string]$mdAfter.installedHead   | Should -BeExactly $installedHeadBefore  # preserved
        [string]$mdAfter.installedAt     | Should -BeExactly $installedAtBefore    # preserved
        [string]$mdAfter.lastUpdatedHead | Should -BeExactly $newHead              # advanced
        # Canonical verify passes post-apply (cross-binding consistent).
        (Invoke-InstallPipelineVerify -InstallArea $fx.Area).ok | Should -BeTrue
        # Activation surfaces were byte-identical → reported clean, not rewritten.
        (@($res.ActivationSurfaces | Where-Object { -not $_.byteIdentical })).Count | Should -BeExactly 0
    }

    It 'B2-T4: update-source apply with activation drift → activation_pending (payload updated, not complete), no activation rewrite' {
        $fx = script:New-UpdatableFixture -CaseName 'b2t4'
        $newHead = script:Add-FixtureGitCommit -Root $fx.Source.Root -Suffix 'b2t4'
        # Drift the skill mirror so activation is not byte-identical.
        $skillDest = Join-Path $fx.Homes.ClaudeHome 'skills/ai-harness-review/SKILL.md'
        $skillBefore = Get-FileSha256 -Path $skillDest
        script:Write-TextFile $skillDest "---`nname: ai-harness-review`n---`n# DRIFTED`n"

        $res = script:Invoke-UpdateSourceApply -InstallArea $fx.Area -ClaudeHome $fx.Homes.ClaudeHome -CodexHome $fx.Homes.CodexHome -SourcePath $fx.Source.Root -SkipSmoke
        $res.Status   | Should -BeExactly 'activation_pending'
        $res.ExitCode | Should -BeExactly 1
        # Payload still advanced despite activation_pending.
        [string](Read-InstallPipelineMetadata -InstallArea $fx.Area).lastUpdatedHead | Should -BeExactly $newHead
        # The drifted activation surface was NOT rewritten by the apply (still drifted content).
        (Get-FileSha256 -Path $skillDest) | Should -Not -BeExactly $skillBefore
        $skillRow = $res.ActivationSurfaces | Where-Object { $_.Name -eq 'review-skill-mirror' }
        $skillRow.ByteIdentical | Should -BeExactly $false
    }

    It 'B2-T5: update-source when already current → noop_already_current via the entrypoint (no approval prompt, no mutation)' {
        $fx = script:New-UpdatableFixture -CaseName 'b2t5'
        # No new source commit: source HEAD == installed lastUpdatedHead, activation clean.
        $snapBefore = script:Get-PathTreeSnapshot -Root $fx.Area
        $r = script:Invoke-InstallUpdate -CallParams @{
            Mode = 'update-source'
            InstallArea = $fx.Area
            ClaudeHome = $fx.Homes.ClaudeHome
            CodexHome = $fx.Homes.CodexHome
            SourcePath = $fx.Source.Root
            SkipSmoke = $true
        }
        $r.ExitCode | Should -BeExactly 0
        $r.Json.status | Should -BeExactly 'noop_already_current'
        $snapAfter = script:Get-PathTreeSnapshot -Root $fx.Area
        script:Assert-PathTreeUnchanged -Before $snapBefore -After $snapAfter -Label 'InstallArea (noop update-source)'
    }

    It 'B2-T6: operational smoke passes against the real repo payload (brief-init seeds template-identical BRIEF, isolated + cleaned up)' {
        # The real repo root carries scripts/brief-init.ps1 + templates/brief/BRIEF.md, so it is a
        # valid payload root for the smoke. Exercises Invoke-OperationalSmoke end-to-end.
        $res = script:Invoke-OperationalSmoke -PayloadRoot $script:RepoRoot
        $res.Smoke | Should -BeExactly 'pass'
    }

    It 'B2-T7: operational smoke skips (not fails) when payload lacks brief-init prerequisites' {
        $fx = script:New-UpdatableFixture -CaseName 'b2t7'
        # The fixture payload current/ has no scripts/brief-init.ps1 → smoke must skip, not fail.
        $res = script:Invoke-OperationalSmoke -PayloadRoot (Join-Path $fx.Area 'current')
        $res.Smoke | Should -BeExactly 'skip'
    }

    It 'B2-T8: -Branch differing from install.json.branch is a source-cut → failed, no mutation, no cache leftover' {
        $fx = script:New-UpdatableFixture -CaseName 'b2t8'   # installed with branch=main
        $null = script:Add-FixtureGitCommit -Root $fx.Source.Root -Suffix 'b2t8'  # payload delta exists
        $snapBefore = script:Get-PathTreeSnapshot -Root $fx.Area
        # Passing a branch that differs from the recorded tracking branch is a source-cut; the
        # apply must refuse (failed) and perform no payload mutation.
        $res = script:Invoke-UpdateSourceApply -InstallArea $fx.Area -ClaudeHome $fx.Homes.ClaudeHome -CodexHome $fx.Homes.CodexHome -SourcePath $fx.Source.Root -Branch 'release-x' -SkipSmoke
        $res.Status   | Should -BeExactly 'failed'
        $res.ExitCode | Should -BeExactly 1
        (@($res.Reasons) -join "`n") | Should -Match '(?i)source-cut'
        # No mutation occurred (3-axis identity unchanged), and no source-cache leftover.
        $snapAfter = script:Get-PathTreeSnapshot -Root $fx.Area
        script:Assert-PathTreeUnchanged -Before $snapBefore -After $snapAfter -Label 'InstallArea (source-cut branch mismatch)'
        (Test-Path -LiteralPath (Join-Path $fx.Area 'source-cache')) | Should -BeFalse
    }

    It 'B2-T9: Format-StdoutJson serializes leftoverPaths + smoke for an update-source cleanup-failure result' {
        # Unit-test the serialization fix directly: a cleanup-failure apply result must surface
        # the structured leftoverPaths in the stdout JSON (the current evidence surface).
        $fakeResult = [pscustomobject]@{
            Status               = 'cleanup_failed_with_leftover'
            ExitCode             = 1
            InstallAreaPath      = 'C:\fake\area'
            Reasons              = @('source-cache cleanup left leftover path: C:\fake\area\source-cache')
            ActivationSurfaces   = @()
            InstallMode          = 'git-url'
            LastUpdatedHead      = ('a' * 40)
            SourceResolvedHead   = ('a' * 40)
            PayloadDeltaRequired = $true
            LeftoverPaths        = @('C:\fake\area\source-cache')
            Smoke                = 'skip'
        }
        $json = script:Format-StdoutJson -Mode 'update-source' -Result $fakeResult
        $obj = $json | ConvertFrom-Json
        $obj.status                 | Should -BeExactly 'cleanup_failed_with_leftover'
        # ConvertTo-Json collapses a single-element array to a scalar (PS 5.1), so coerce with @()
        # before indexing — the same convention the codebase uses for reasons / activationSurfaces.
        @($obj.leftoverPaths).Count | Should -BeExactly 1
        @($obj.leftoverPaths)[0]    | Should -BeExactly 'C:\fake\area\source-cache'
        $obj.smoke                  | Should -BeExactly 'skip'
    }

    It 'B2-T10: command-implied update-source on a destination with no install identity (no install.json) → failed, no mutation' {
        # An InstallArea that is NOT an existing install (no install.json) must not be turned into
        # a new install by command-implied update-source — that is fresh install (§6) territory.
        $src = script:New-FixtureGitRepo -CaseName 'b2t10'
        $area = script:New-FixtureInstallArea -CaseName 'b2t10'   # empty area, no install.json
        $homes = script:New-FixtureHomeRoots -CaseName 'b2t10'
        $snapBefore = script:Get-PathTreeSnapshot -Root $area
        $r = script:Invoke-InstallUpdate -CallParams @{
            Mode = 'update-source'
            InstallArea = $area
            ClaudeHome = $homes.ClaudeHome
            CodexHome = $homes.CodexHome
            SourcePath = $src.Root
            SkipSmoke = $true
        }
        $r.ExitCode | Should -BeExactly 1
        $r.Json.status | Should -BeExactly 'failed'
        $snapAfter = script:Get-PathTreeSnapshot -Root $area
        script:Assert-PathTreeUnchanged -Before $snapBefore -After $snapAfter -Label 'InstallArea (no install identity)'
    }

    It 'B2-T11: command-implied update-source recovers a payload-drifted (valid-identity) install via reinstall-first → complete' {
        # install.json identity is valid but the marker is corrupted (cross-binding broken) — a
        # payload drift, not an identity loss. update-source must RECOVER it (deterministic overwrite
        # from the identity-consistent source), not refuse it (§9 reinstall-first), and reach complete.
        $fx = script:New-UpdatableFixture -CaseName 'b2t11'
        $marker = Read-InstallPipelineMarker -InstallArea $fx.Area
        $marker.head = ('0' * 40)   # break cross-binding (payload drift) while metadata stays valid
        Write-InstallPipelineMarker -InstallArea $fx.Area -Marker $marker
        # Confirm preflight sees payload drift.
        $pre = script:Invoke-InstallUpdate -CallParams @{ Mode = 'inspect'; InstallArea = $fx.Area; ClaudeHome = $fx.Homes.ClaudeHome; CodexHome = $fx.Homes.CodexHome; SourcePath = $fx.Source.Root }
        $pre.Json.status | Should -BeExactly 'inspect_payload_drift'

        $res = script:Invoke-UpdateSourceApply -InstallArea $fx.Area -ClaudeHome $fx.Homes.ClaudeHome -CodexHome $fx.Homes.CodexHome -SourcePath $fx.Source.Root -SkipSmoke
        $res.Status | Should -BeExactly 'complete'
        (Invoke-InstallPipelineVerify -InstallArea $fx.Area).ok | Should -BeTrue   # cross-binding restored
    }

    It 'B2-T12: update-source success stdout shows REAL post-apply diagnostics, no misleading false/null (I01)' {
        # Dogfood panic: `complete` emitted next to metadataValid:false / manifestMarkerCrossBindingOk:false
        # / installState:null (unevaluated defaults). After the fix those fields carry real post-apply
        # evidence (present / true / true) and the misleading defaults must not appear next to success.
        $fx = script:New-UpdatableFixture -CaseName 'b2t12'
        $newHead = script:Add-FixtureGitCommit -Root $fx.Source.Root -Suffix 'b2t12'
        $newHead | Should -Not -BeExactly $fx.SeedHead

        $res = script:Invoke-UpdateSourceApply -InstallArea $fx.Area -ClaudeHome $fx.Homes.ClaudeHome -CodexHome $fx.Homes.CodexHome -SourcePath $fx.Source.Root -SkipSmoke
        $res.Status | Should -BeExactly 'complete'

        $json = script:Format-StdoutJson -Mode 'update-source' -Result $res
        $obj = $json | ConvertFrom-Json
        $obj.status                       | Should -BeExactly 'complete'
        $obj.installState                 | Should -BeExactly 'present'
        $obj.metadataValid                | Should -BeExactly $true
        $obj.manifestMarkerCrossBindingOk | Should -BeExactly $true
        # The misleading unevaluated defaults must NOT appear next to a success status.
        $json | Should -Not -Match '"metadataValid"\s*:\s*false'
        $json | Should -Not -Match '"manifestMarkerCrossBindingOk"\s*:\s*false'
        $json | Should -Not -Match '"installState"\s*:\s*null'
    }

    It 'B2-T9b: Format-StdoutJson serializes an EMPTY leftoverPaths as a JSON array [] not {} (I12)' {
        # PowerShell 5.1 ConvertTo-Json renders an empty array returned from an if-EXPRESSION as `{}`.
        # The serializer uses branch-local assignment so an empty leftoverPaths stays a JSON array `[]`.
        $successResult = [pscustomobject]@{
            Status               = 'complete'
            ExitCode             = 0
            InstallAreaPath      = 'C:\fake\area'
            Reasons              = @()
            ActivationSurfaces   = @()
            InstallState         = 'present'
            MetadataValid        = $true
            InstallMode          = 'git-url'
            LastUpdatedHead      = ('a' * 40)
            SourceResolvedHead   = ('a' * 40)
            PayloadDeltaRequired = $true
            ManifestMarkerCrossBindingOk = $true
            LeftoverPaths        = @()
            Smoke                = 'pass'
        }
        $json = script:Format-StdoutJson -Mode 'update-source' -Result $successResult
        $json | Should -Match '"leftoverPaths"\s*:\s*\[\s*\]'
        $json | Should -Not -Match '"leftoverPaths"\s*:\s*\{'
        $obj = $json | ConvertFrom-Json
        @($obj.leftoverPaths).Count | Should -BeExactly 0
    }

    It 'B2-T13: -Json mode puts machine JSON on stdout and human log + PASS/FAIL on stderr (I13)' {
        $src = script:New-FixtureGitRepo -CaseName 'b2t13'
        $area = script:New-FixtureInstallArea -CaseName 'b2t13'
        $homes = script:New-FixtureHomeRoots -CaseName 'b2t13'
        script:Initialize-CleanInstallFixture -InstallArea $area -ClaudeHome $homes.ClaudeHome -CodexHome $homes.CodexHome -SourcePath $src.Root -Head $src.Head

        $r = script:Invoke-InstallUpdate -CallParams @{
            Mode = 'inspect'
            InstallArea = $area
            ClaudeHome = $homes.ClaudeHome
            CodexHome = $homes.CodexHome
            SourcePath = $src.Root
            Json = $true
        }
        $r.ExitCode | Should -BeExactly 0
        # stdout = single machine-readable JSON object: no BEGIN/END wrapper, no human lines, parseable on its own.
        $r.Stdout | Should -Not -Match '--- BEGIN JSON ---'
        $r.Stdout | Should -Not -Match 'install-update: mode='
        # stdout must parse as a single JSON object on its own (throws here if it carries human noise).
        $stdoutObj = $r.Stdout | ConvertFrom-Json
        $stdoutObj.status | Should -BeExactly 'inspect_clean'
        # human log + final PASS/FAIL go to stderr under -Json.
        $r.Stderr | Should -Match 'install-update: mode='
        $r.Stderr | Should -Match 'install-update: PASS'
    }

    It 'B2-T14: operational smoke failure surfaces and preserves the workspace path for debugging (I14)' {
        # A payload whose brief-init seeds a BRIEF that does NOT match the template forces a smoke
        # sha-mismatch failure; the failure result must expose the (preserved) workspace path.
        $payload = Join-Path $TestDrive 'smokefail-payload'
        if (Test-Path -LiteralPath $payload) { Remove-Item -LiteralPath $payload -Recurse -Force }
        $null = New-Item -ItemType Directory -Path (Join-Path $payload 'scripts') -Force
        $null = New-Item -ItemType Directory -Path (Join-Path $payload 'templates/brief') -Force
        script:Write-TextFile (Join-Path $payload 'templates/brief/BRIEF.md') 'CANONICAL TEMPLATE BODY'
        $stub = @'
[CmdletBinding()] param([string] $ToolRoot, [string] $ProjectRoot)
$dest = Join-Path $ProjectRoot 'log/brief/BRIEF.md'
$null = New-Item -ItemType Directory -Path (Split-Path -Parent $dest) -Force
[System.IO.File]::WriteAllText($dest, 'DIFFERENT BODY', (New-Object System.Text.UTF8Encoding($false)))
exit 0
'@
        script:Write-TextFile (Join-Path $payload 'scripts/brief-init.ps1') $stub

        $res = script:Invoke-OperationalSmoke -PayloadRoot $payload
        try {
            $res.Smoke         | Should -BeExactly 'fail'
            $res.WorkspacePath | Should -Not -BeNullOrEmpty
            (Test-Path -LiteralPath $res.WorkspacePath) | Should -BeTrue       # preserved for debugging
            $res.Reason | Should -Match ([regex]::Escape($res.WorkspacePath))  # path surfaced in the reason
        }
        finally {
            if ($res.WorkspacePath -and (Test-Path -LiteralPath $res.WorkspacePath)) {
                Remove-Item -LiteralPath $res.WorkspacePath -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

Describe 'install-update — Phase 2 bootstrap / name-based update discoverability docs' {

    BeforeAll {
        $script:Md  = Get-Content -LiteralPath $script:InstallMd -Raw -Encoding UTF8
        $script:S71 = script:Get-InstallMdSection -Content $script:Md -HeadingRegex '^#{2,3}\s+7\.1\s'
        $script:S72 = script:Get-InstallMdSection -Content $script:Md -HeadingRegex '^#{2,3}\s+7\.2\s'
    }

    It 'P2-T1 (I06): §7.1 carries a self-contained name-based update quickstart (NL request + inspect/update-source/verify)' {
        $script:S71 | Should -Not -BeNullOrEmpty
        $script:S71 | Should -Match 'Name-based update quickstart'
        $script:S71 | Should -Match '최신버전으로 업데이트'
        $script:S71 | Should -Match '-Mode inspect'
        $script:S71 | Should -Match '-Mode update-source'
        $script:S71 | Should -Match '-Mode verify'
    }

    It 'P2-T2 (I02): legacy bootstrap note says run the CLONED latest script, not the installed copy, and not to conclude un-updatable' {
        $script:S71 | Should -Match 'Legacy bootstrap'
        $script:S71 | Should -Match 'install-pipeline\.ps1'
        $script:S71 | Should -Match 'cloned'
        $script:S71 | Should -Match '불가능하다고 결론'
    }

    It 'P2-T3 (I11): operator bootstrap clone cleanup rule is documented and distinct from the internal source-cache cleanup' {
        $script:S71 | Should -Match 'bootstrap clone cleanup'
        $script:S71 | Should -Match 'source-cache'
        $script:S71 | Should -Match '자동 삭제'
        $script:S71 | Should -Match 'leftover path'
    }

    It 'P2-T4 (I07): §7.2 flow matrix distinguishes fresh / name-based update / activation refresh with payload-only update-source' {
        $script:S72 | Should -Not -BeNullOrEmpty
        $script:S72 | Should -Match 'Flow comparison'
        $script:S72 | Should -Match 'Fresh / full operational install'
        $script:S72 | Should -Match 'Name-based existing install update'
        $script:S72 | Should -Match 'Activation refresh'
        $script:S72 | Should -Match 'byte-identity verify only'
        $script:S72 | Should -Match 'command-implied approval'
    }

    It 'P2-T5 (no behavior change): activation apply stays a separate/later explicit step, update-source stays the payload entrypoint' {
        $script:S72 | Should -Match '별도 explicit'
        $script:S72 | Should -Match 'later phase'
        $script:S72 | Should -Match 'activate-global\.ps1'
        $script:S72 | Should -Match 'install-update\.ps1 -Mode update-source'
    }

    It 'P2-T6 (hygiene): §7.2 span carries no Tier A/B deployable-reference violations' {
        $script:S72 | Should -Not -BeNullOrEmpty
        foreach ($lit in $script:TierA) { $script:S72 | Should -Not -Match ([regex]::Escape($lit)) }
        foreach ($rx in $script:TierB)  { $script:S72 | Should -Not -Match $rx }
    }
}

Describe 'install-update — Phase 3 source identity / acquisition ergonomics docs' {

    BeforeAll {
        $script:Md3 = Get-Content -LiteralPath $script:InstallMd -Raw -Encoding UTF8
        $script:S71_3 = script:Get-InstallMdSection -Content $script:Md3 -HeadingRegex '^#{2,3}\s+7\.1\s'
    }

    It 'P3-T1 (I10): §7.1 documents source-identity / -RepoUrl source-cut ergonomics (omit -RepoUrl; no normalization; override outside command-implied)' {
        $script:S71_3 | Should -Not -BeNullOrEmpty
        $script:S71_3 | Should -Match 'Source identity 주의'
        $script:S71_3 | Should -Match '-RepoUrl'
        $script:S71_3 | Should -Match 'omit'
        $script:S71_3 | Should -Match 'install\.json\.repoUrl'
        $script:S71_3 | Should -Match 'URL 정규화'
        $script:S71_3 | Should -Match '\.git'
        # casing alone must NOT be documented as a source-cut trip (comparison is OrdinalIgnoreCase).
        $script:S71_3 | Should -Match '대소문자 차이만으로는 발동하지 않'
        $script:S71_3 | Should -Match 'command-implied approval 범위 밖'
    }

    It 'P3-T2 (I09): §7.1 documents the deliberate double acquisition + distinct cleanup ownership; cache reuse / -AcquisitionClonePath deferred; -SourcePath caveat' {
        $script:S71_3 | Should -Match '이중 acquisition'
        $script:S71_3 | Should -Match 'cleanup ownership'
        $script:S71_3 | Should -Match 'AcquisitionClonePath'
        $script:S71_3 | Should -Match '-SourcePath'
        # the -SourcePath rationale must be accurate: git-url apply IGNORES -SourcePath (no source-cut from it).
        $script:S71_3 | Should -Match '사용하지 않'
    }

    It 'P3-T3 (polish): §7.1 says an installed update-source does not change the cloned-latest-script rule' {
        $script:S71_3 | Should -Match 'installed copy 에 update-source 가 있어도'
        $script:S71_3 | Should -Match 'latest source clone'
        $script:S71_3 | Should -Match 'operative contract'
    }

    It 'P3-T4 (guard intact): the source-cut comparison code is unchanged (normalization-free identity equality; Phase 3 added no code)' {
        $core = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'scripts/lib/install-pipeline-core.ps1') -Raw -Encoding UTF8
        $core | Should -Match 'function Test-InstallPipelineSourceCut'
        # still the same field set + ordinal-insensitive string equality, no URL normalization helper.
        $core | Should -Match "compareFields\s*=\s*@\(\s*'installMode',\s*'repoUrl',\s*'sourcePath',\s*'toolRoot',\s*'branch',\s*'remote'\s*\)"
        $core | Should -Match '\[System\.StringComparison\]::OrdinalIgnoreCase'
        $core | Should -Not -Match '(?i)Normalize-RepoUrl'
    }
}
