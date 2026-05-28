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
        'smoke_failed','cleanup_failed_with_leftover','failed'
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

    It 'install-update.ps1 source defines Assert-NoMutationPath with throw on mutation flag' {
        $content = Get-Content -LiteralPath $script:Entry -Raw -Encoding UTF8
        $content | Should -Match 'function\s+script:Assert-NoMutationPath'
        $content | Should -Match 'mutationFlags\s*=\s*@\(\s*''ApplyActivation'',\s*''UpdateSource'',\s*''ApplyPayload'',\s*''RefreshSkill''\s*\)'
        $content | Should -Match 'throw\s+"install-update:\s*FAIL mutation flag'
        # Each known mutation flag listed.
        foreach ($flag in @('ApplyActivation','UpdateSource','ApplyPayload','RefreshSkill')) {
            $content | Should -Match $flag
        }
        # Entrypoint exercises the guard on every invocation (no-op in this contract).
        $content | Should -Match 'script:Assert-NoMutationPath\s+-Mode\s+\$Mode\s+-RequestedFlags'
    }
}
