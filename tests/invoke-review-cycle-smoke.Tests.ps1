Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

BeforeAll {
    $script:RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).ProviderPath
    $script:Wrapper  = Join-Path $script:RepoRoot 'scripts/smoke/invoke-review-cycle.ps1'

    function script:Write-Utf8NoBomFile {
        param([string] $Path, [string] $Content)
        $parent = Split-Path -LiteralPath $Path
        if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
            $null = New-Item -ItemType Directory -Path $parent -Force
        }
        $resolved = [System.IO.Path]::GetFullPath($Path)
        $encoding = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($resolved, $Content, $encoding)
    }

    function script:New-CaseRoot {
        param([string] $CaseName)
        $caseRoot = Join-Path $TestDrive ('pester-smoke-' + $CaseName)
        if (Test-Path -LiteralPath $caseRoot) {
            Remove-Item -LiteralPath $caseRoot -Recurse -Force
        }
        $null = New-Item -ItemType Directory -Path $caseRoot -Force
        return ([System.IO.Path]::GetFullPath($caseRoot))
    }

    function script:Invoke-Wrapper {
        # Run the wrapper as a separate powershell.exe process via PowerShell's `&`
        # call operator. Direct invocation preserves multi-word arguments as single
        # arguments — Start-Process -ArgumentList <array> does NOT (it was the exact
        # SC5 driver failure recorded in docs/backlog/operations.md). Tests of this
        # wrapper exist precisely to guard against that pattern, so the tests
        # themselves must not regress into it.
        #
        # The child's stdout is forwarded to the host via Out-Host so that the
        # function's pipeline return is solely the integer $LASTEXITCODE — otherwise
        # `return $LASTEXITCODE` would emit an array containing any child stdout
        # lines followed by the int.
        param(
            [string[]] $WrapperArgs
        )
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $script:Wrapper @WrapperArgs | Out-Host
        return $LASTEXITCODE
    }

    function script:Get-FakeChild-DumpArgs {
        param([string] $ArgDumpPath)
        # Fake child: receives review-cycle parameters and dumps PSBoundParameters to JSON.
        # The ArgDumpPath is baked into the script body via -f to avoid PS variable expansion
        # of $arg-dump path inside the here-string.
        $template = @'
[CmdletBinding()]
param(
    [string]   $Stage,
    [string]   $Purpose,
    [string[]] $TargetFiles,
    [string]   $TargetFilesPath,
    [string]   $Context,
    [string]   $RequiredInspectionPaths,
    [string]   $ReviewQuestions,
    [string]   $Constraints,
    [string]   $Reviewer,
    [string]   $RunId,
    [string]   $ProjectRoot,
    [string]   $ToolRoot
)
Set-StrictMode -Version Latest
$dump = [ordered]@{}
foreach ($k in $PSBoundParameters.Keys) {
    $dump[$k] = $PSBoundParameters[$k]
}
$json = $dump | ConvertTo-Json -Depth 4
[System.IO.File]::WriteAllText('__DUMP__', $json, [System.Text.UTF8Encoding]::new($false))
exit 0
'@
        return $template -replace '__DUMP__', ([System.IO.Path]::GetFullPath($ArgDumpPath).Replace('\','\\'))
    }
}

Describe 'invoke-review-cycle wrapper' {
    Context 'parameter passthrough' {
        It 'preserves multi-word string parameters as single arguments to the child' {
            $caseRoot = New-CaseRoot 'multi-word'
            $fakeChild = Join-Path $caseRoot 'fake-cycle.ps1'
            $argDump = Join-Path $caseRoot 'args.json'
            Write-Utf8NoBomFile -Path $fakeChild -Content (Get-FakeChild-DumpArgs -ArgDumpPath $argDump)

            # NOTE on test fidelity: the strings below intentionally contain spaces,
            # semicolons, commas, and other delimiters that PowerShell argument
            # parsing has historically mishandled. They do NOT contain literal
            # double-quote characters because cross-process invocation via
            # `& powershell.exe -File ...` does not preserve embedded double-quotes
            # in argument values (a separate PowerShell issue, unrelated to the
            # wrapper's contract). The wrapper's actual contract is to preserve
            # whatever string the parent process gives it; embedded double-quote
            # robustness in the parent is out of scope for the wrapper.
            $multiWordPurpose = 'this purpose has many words'
            $multiWordContext = 'context with multiple words and several delimiters'
            $multiWordQuestions = 'question one with words; question two also with words'
            $multiWordConstraints = 'constraint with several words and a comma, like so'

            $exit = Invoke-Wrapper -WrapperArgs @(
                '-Stage', 'implementation',
                '-Purpose', $multiWordPurpose,
                '-Context', $multiWordContext,
                '-ReviewQuestions', $multiWordQuestions,
                '-Constraints', $multiWordConstraints,
                '-ReviewCyclePath', $fakeChild
            )

            $exit | Should -Be 0
            Test-Path -LiteralPath $argDump | Should -BeTrue

            $captured = Get-Content -LiteralPath $argDump -Raw | ConvertFrom-Json
            $captured.Stage           | Should -Be 'implementation'
            $captured.Purpose         | Should -Be $multiWordPurpose
            $captured.Context         | Should -Be $multiWordContext
            $captured.ReviewQuestions | Should -Be $multiWordQuestions
            $captured.Constraints     | Should -Be $multiWordConstraints
        }

        It 'does not forward unbound optional parameters' {
            $caseRoot = New-CaseRoot 'unbound-omitted'
            $fakeChild = Join-Path $caseRoot 'fake-cycle.ps1'
            $argDump = Join-Path $caseRoot 'args.json'
            Write-Utf8NoBomFile -Path $fakeChild -Content (Get-FakeChild-DumpArgs -ArgDumpPath $argDump)

            $exit = Invoke-Wrapper -WrapperArgs @(
                '-Stage', 'design',
                '-Purpose', 'minimal purpose',
                '-ReviewCyclePath', $fakeChild
            )

            $exit | Should -Be 0
            $captured = Get-Content -LiteralPath $argDump -Raw | ConvertFrom-Json
            $names = ($captured | Get-Member -MemberType NoteProperty).Name
            $names | Should -Contain 'Stage'
            $names | Should -Contain 'Purpose'
            $names | Should -Not -Contain 'Context'
            $names | Should -Not -Contain 'ReviewQuestions'
            $names | Should -Not -Contain 'Constraints'
            $names | Should -Not -Contain 'ToolRoot'
        }
    }

    Context 'child stderr resilience' {
        It 'does not die when the child writes to stderr before exiting 0' {
            $caseRoot = New-CaseRoot 'stderr-ok'
            $fakeChild = Join-Path $caseRoot 'fake-cycle.ps1'
            Write-Utf8NoBomFile -Path $fakeChild -Content @'
[CmdletBinding()]
param(
    [string] $Stage,
    [string] $Purpose
)
Set-StrictMode -Version Latest
[Console]::Error.WriteLine('emulated native stderr banner line 1')
[Console]::Error.WriteLine('emulated native stderr banner line 2')
[Console]::Out.WriteLine('child stdout completed')
exit 0
'@

            $exit = Invoke-Wrapper -WrapperArgs @(
                '-Stage', 'implementation',
                '-Purpose', 'p',
                '-ReviewCyclePath', $fakeChild
            )

            $exit | Should -Be 0
        }
    }

    Context 'exit code passthrough' {
        It 'passes a non-zero child exit code through verbatim' {
            $caseRoot = New-CaseRoot 'exit-42'
            $fakeChild = Join-Path $caseRoot 'fake-cycle.ps1'
            Write-Utf8NoBomFile -Path $fakeChild -Content @'
[CmdletBinding()]
param(
    [string] $Stage,
    [string] $Purpose
)
Set-StrictMode -Version Latest
exit 42
'@

            $exit = Invoke-Wrapper -WrapperArgs @(
                '-Stage', 'implementation',
                '-Purpose', 'p',
                '-ReviewCyclePath', $fakeChild
            )

            $exit | Should -Be 42
        }

        It 'passes exit 0 through verbatim' {
            $caseRoot = New-CaseRoot 'exit-0'
            $fakeChild = Join-Path $caseRoot 'fake-cycle.ps1'
            Write-Utf8NoBomFile -Path $fakeChild -Content @'
[CmdletBinding()]
param(
    [string] $Stage,
    [string] $Purpose
)
Set-StrictMode -Version Latest
exit 0
'@

            $exit = Invoke-Wrapper -WrapperArgs @(
                '-Stage', 'implementation',
                '-Purpose', 'p',
                '-ReviewCyclePath', $fakeChild
            )

            $exit | Should -Be 0
        }
    }

    Context 'fail-fast on invalid child path' {
        It 'exits non-zero when the child path does not exist' {
            $caseRoot = New-CaseRoot 'missing-child'
            $nonExistent = Join-Path $caseRoot 'definitely-not-here.ps1'

            $exit = Invoke-Wrapper -WrapperArgs @(
                '-Stage', 'implementation',
                '-Purpose', 'p',
                '-ReviewCyclePath', $nonExistent
            )

            $exit | Should -Not -Be 0
        }
    }
}
