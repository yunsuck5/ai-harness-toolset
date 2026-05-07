Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

BeforeAll {
    $script:RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).ProviderPath
    $script:ReviewPrepareScript = Join-Path $script:RepoRoot 'scripts/review-prepare.ps1'

    function script:Write-Utf8NoBomFile {
        param(
            [string] $Path,
            [string] $Content
        )
        $parent = Split-Path -LiteralPath $Path
        if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
            $null = New-Item -ItemType Directory -Path $parent -Force
        }
        $resolved = [System.IO.Path]::GetFullPath($Path)
        $encoding = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($resolved, $Content, $encoding)
    }

    function script:New-PrepareCaseRoot {
        param([string] $CaseName)
        $caseRoot = Join-Path $TestDrive ('pester-review-prepare-' + $CaseName)
        if (Test-Path -LiteralPath $caseRoot) {
            Remove-Item -LiteralPath $caseRoot -Recurse -Force
        }
        $null = New-Item -ItemType Directory -Path $caseRoot -Force
        return ([System.IO.Path]::GetFullPath($caseRoot))
    }

    function script:Get-Sha256Lower {
        param([string] $Path)
        return ((Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant())
    }

    function script:Invoke-ReviewPrepare {
        param(
            [string] $ProjectRoot,
            [string] $TargetPath,
            [string[]] $TargetFiles,
            [string] $RunId,
            [string] $Stage = 'design',
            [string] $Purpose = 'pester regression'
        )
        $procArgs = @(
            '-NoProfile',
            '-ExecutionPolicy', 'Bypass',
            '-File', $script:ReviewPrepareScript,
            '-Stage', $Stage,
            '-Purpose', $Purpose,
            '-ProjectRoot', $ProjectRoot,
            '-ToolRoot', $script:RepoRoot,
            '-RunId', $RunId
        )
        if (-not [string]::IsNullOrEmpty($TargetPath)) {
            $procArgs += @('-TargetPath', $TargetPath)
        }
        if ($null -ne $TargetFiles -and $TargetFiles.Count -gt 0) {
            $listDir = Join-Path $ProjectRoot 'log/staging'
            if (-not (Test-Path -LiteralPath $listDir -PathType Container)) {
                $null = New-Item -ItemType Directory -Path $listDir -Force
            }
            $listPath = Join-Path $listDir ('pester-prepare-targets-' + ([guid]::NewGuid().ToString('N')) + '.list')
            $listContent = ($TargetFiles -join "`n") + "`n"
            $enc = New-Object System.Text.UTF8Encoding($false)
            [System.IO.File]::WriteAllText($listPath, $listContent, $enc)
            $procArgs += @('-TargetFilesPath', $listPath)
        }

        $combined = & powershell.exe @procArgs 2>&1
        $exitCode = $LASTEXITCODE
        $text = ($combined | ForEach-Object { [string]$_ }) -join "`n"
        return [pscustomobject]@{
            ExitCode = $exitCode
            Output   = $text
        }
    }
}

Describe 'review-prepare targetFiles' {
    It 'AC-PR1: single -TargetPath writes targetFiles[] with one primary entry' {
        $project = script:New-PrepareCaseRoot -CaseName 'pr1'
        $targetPath = Join-Path $project 'target.txt'
        script:Write-Utf8NoBomFile -Path $targetPath -Content "single body`n"
        $expectedSha = script:Get-Sha256Lower -Path $targetPath

        $runId = '20260506-110000-pr1aaa'
        $result = script:Invoke-ReviewPrepare -ProjectRoot $project -TargetPath $targetPath -RunId $runId -Stage 'design'
        $result.ExitCode | Should -Be 0

        $metaPath = Join-Path $project ('log/review/' + $runId + '/meta.json')
        Test-Path -LiteralPath $metaPath -PathType Leaf | Should -BeTrue

        $metaText = [System.IO.File]::ReadAllText($metaPath, (New-Object System.Text.UTF8Encoding($false)))
        $meta = $metaText | ConvertFrom-Json

        $meta.targetSha256 | Should -Be $expectedSha
        $meta.targetFiles | Should -Not -BeNullOrEmpty
        @($meta.targetFiles).Count | Should -Be 1
        @($meta.targetFiles)[0].path | Should -Be 'target.txt'
        @($meta.targetFiles)[0].sha256 | Should -Be $expectedSha
    }

    It 'AC-PR2: -TargetFiles multi writes repo-relative forward-slash paths and lowercase hashes' {
        $project = script:New-PrepareCaseRoot -CaseName 'pr2'
        $sub = Join-Path $project 'src'
        $null = New-Item -ItemType Directory -Path $sub -Force
        $a = Join-Path $project 'a.txt'
        $b = Join-Path $sub 'b.txt'
        $c = Join-Path $sub 'c.txt'
        script:Write-Utf8NoBomFile -Path $a -Content "a body`n"
        script:Write-Utf8NoBomFile -Path $b -Content "b body`n"
        script:Write-Utf8NoBomFile -Path $c -Content "c body`n"
        $shaA = script:Get-Sha256Lower -Path $a
        $shaB = script:Get-Sha256Lower -Path $b
        $shaC = script:Get-Sha256Lower -Path $c

        $runId = '20260506-110000-pr2aaa'
        $result = script:Invoke-ReviewPrepare -ProjectRoot $project -TargetFiles @($a, $b, $c) -RunId $runId -Stage 'implementation'
        $result.ExitCode | Should -Be 0

        $metaPath = Join-Path $project ('log/review/' + $runId + '/meta.json')
        $metaText = [System.IO.File]::ReadAllText($metaPath, (New-Object System.Text.UTF8Encoding($false)))
        $meta = $metaText | ConvertFrom-Json

        $files = @($meta.targetFiles)
        $files.Count | Should -Be 3
        $files[0].path | Should -Be 'a.txt'
        $files[0].sha256 | Should -Be $shaA
        $files[1].path | Should -Be 'src/b.txt'
        $files[1].sha256 | Should -Be $shaB
        $files[2].path | Should -Be 'src/c.txt'
        $files[2].sha256 | Should -Be $shaC

        $meta.targetPath | Should -Match 'a\.txt$'
        $meta.targetSha256 | Should -Be $shaA
    }

    It 'AC-PR-CONTAINMENT-1: -TargetFilesPath under <project>/scripts/foo.list is rejected (outside ProjectLogRoot)' {
        $project = script:New-PrepareCaseRoot -CaseName 'pr-containment-1'
        $target = Join-Path $project 'a.txt'
        script:Write-Utf8NoBomFile -Path $target -Content "containment body`n"

        $scriptsDir = Join-Path $project 'scripts'
        $null = New-Item -ItemType Directory -Path $scriptsDir -Force
        $badList = Join-Path $scriptsDir 'foo.list'
        $enc = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($badList, ($target + "`n"), $enc)

        $runId = '20260506-110000-prc1aa'
        $procArgs = @(
            '-NoProfile',
            '-ExecutionPolicy', 'Bypass',
            '-File', $script:ReviewPrepareScript,
            '-Stage', 'design',
            '-Purpose', 'pester containment',
            '-ProjectRoot', $project,
            '-ToolRoot', $script:RepoRoot,
            '-RunId', $runId,
            '-TargetFilesPath', $badList
        )
        $combined = & powershell.exe @procArgs 2>&1
        $exitCode = $LASTEXITCODE
        $text = ($combined | ForEach-Object { [string]$_ }) -join "`n"

        $exitCode | Should -Not -Be 0
        $text | Should -Match 'TargetFilesPath outside ProjectLogRoot'

        $runDir = Join-Path $project ('log/review/' + $runId)
        Test-Path -LiteralPath $runDir -PathType Container | Should -BeFalse
    }

    It 'AC-PR-CONTAINMENT-2: -TargetFilesPath outside the project entirely is rejected' {
        $project = script:New-PrepareCaseRoot -CaseName 'pr-containment-2'
        $target = Join-Path $project 'a.txt'
        script:Write-Utf8NoBomFile -Path $target -Content "containment body`n"

        $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ('pester-prepare-out-' + ([guid]::NewGuid().ToString('N')))
        $null = New-Item -ItemType Directory -Path $tempDir -Force
        $badList = Join-Path $tempDir 'foo.list'
        $enc = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($badList, ($target + "`n"), $enc)

        try {
            $runId = '20260506-110000-prc2aa'
            $procArgs = @(
                '-NoProfile',
                '-ExecutionPolicy', 'Bypass',
                '-File', $script:ReviewPrepareScript,
                '-Stage', 'design',
                '-Purpose', 'pester containment',
                '-ProjectRoot', $project,
                '-ToolRoot', $script:RepoRoot,
                '-RunId', $runId,
                '-TargetFilesPath', $badList
            )
            $combined = & powershell.exe @procArgs 2>&1
            $exitCode = $LASTEXITCODE
            $text = ($combined | ForEach-Object { [string]$_ }) -join "`n"

            $exitCode | Should -Not -Be 0
            $text | Should -Match 'TargetFilesPath outside ProjectLogRoot'

            $runDir = Join-Path $project ('log/review/' + $runId)
            Test-Path -LiteralPath $runDir -PathType Container | Should -BeFalse
        }
        finally {
            if (Test-Path -LiteralPath $tempDir -PathType Container) {
                Remove-Item -LiteralPath $tempDir -Recurse -Force
            }
        }
    }

    It 'AC-PR-WRITEONCE-1: pre-existing run directory is rejected and seeded meta.json is not overwritten' {
        $project = script:New-PrepareCaseRoot -CaseName 'pr-writeonce-1'
        $target = Join-Path $project 'a.txt'
        script:Write-Utf8NoBomFile -Path $target -Content "writeonce body`n"

        $runId = '20260506-110000-pwo1aa'
        $runDir = Join-Path $project ('log/review/' + $runId)
        $null = New-Item -ItemType Directory -Path $runDir -Force

        $sentinelMeta = Join-Path $runDir 'meta.json'
        $sentinelContent = '{"sentinel":"untouched"}'
        script:Write-Utf8NoBomFile -Path $sentinelMeta -Content $sentinelContent

        $result = script:Invoke-ReviewPrepare -ProjectRoot $project -TargetPath $target -RunId $runId -Stage 'design'

        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match 'run directory already exists'
        $result.Output | Should -Match 'fresh run-id'

        $afterText = [System.IO.File]::ReadAllText($sentinelMeta, (New-Object System.Text.UTF8Encoding($false)))
        $afterText | Should -Be $sentinelContent

        $inputPath = Join-Path $runDir 'input.md'
        Test-Path -LiteralPath $inputPath -PathType Leaf | Should -BeFalse
    }

    It 'AC-PR3: comma in target path is preserved as a single entry (B2 regression)' {
        $project = script:New-PrepareCaseRoot -CaseName 'pr3'
        $sub = Join-Path $project 'docs'
        $null = New-Item -ItemType Directory -Path $sub -Force
        $commaPath = Join-Path $sub 'a,b.md'
        script:Write-Utf8NoBomFile -Path $commaPath -Content "comma body`n"
        $expectedSha = script:Get-Sha256Lower -Path $commaPath

        $runId = '20260506-110000-pr3aaa'
        $result = script:Invoke-ReviewPrepare -ProjectRoot $project -TargetFiles @($commaPath) -RunId $runId -Stage 'design'
        $result.ExitCode | Should -Be 0

        $metaPath = Join-Path $project ('log/review/' + $runId + '/meta.json')
        $metaText = [System.IO.File]::ReadAllText($metaPath, (New-Object System.Text.UTF8Encoding($false)))
        $meta = $metaText | ConvertFrom-Json

        $files = @($meta.targetFiles)
        $files.Count | Should -Be 1
        $files[0].path | Should -Be 'docs/a,b.md'
        $files[0].sha256 | Should -Be $expectedSha
    }
}
