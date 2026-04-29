Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-GitCapture {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]] $Arguments,
        [string] $WorkingDirectory
    )

    $stdoutFile = [System.IO.Path]::GetTempFileName()
    $stderrFile = [System.IO.Path]::GetTempFileName()
    try {
        $startParams = @{
            FilePath               = 'git'
            ArgumentList           = $Arguments
            NoNewWindow            = $true
            PassThru               = $true
            Wait                   = $true
            RedirectStandardOutput = $stdoutFile
            RedirectStandardError  = $stderrFile
        }
        if (-not [string]::IsNullOrEmpty($WorkingDirectory)) {
            $startParams['WorkingDirectory'] = $WorkingDirectory
        }
        $proc = Start-Process @startParams
        $stdout = [System.IO.File]::ReadAllText($stdoutFile)
        $stderr = [System.IO.File]::ReadAllText($stderrFile)
        return [pscustomobject]@{
            ExitCode = $proc.ExitCode
            StdOut   = $stdout
            StdErr   = $stderr
        }
    }
    finally {
        if (Test-Path -LiteralPath $stdoutFile) {
            Remove-Item -LiteralPath $stdoutFile -Force -ErrorAction SilentlyContinue
        }
        if (Test-Path -LiteralPath $stderrFile) {
            Remove-Item -LiteralPath $stderrFile -Force -ErrorAction SilentlyContinue
        }
    }
}

function Get-GitRoot {
    [CmdletBinding()]
    param(
        [string] $WorkingDirectory
    )

    $result = Invoke-GitCapture -Arguments @('rev-parse', '--show-toplevel') -WorkingDirectory $WorkingDirectory
    if ($result.ExitCode -ne 0) {
        return $null
    }
    return $result.StdOut.Trim()
}

function Get-GitHead {
    [CmdletBinding()]
    param(
        [string] $WorkingDirectory
    )

    $result = Invoke-GitCapture -Arguments @('rev-parse', 'HEAD') -WorkingDirectory $WorkingDirectory
    if ($result.ExitCode -ne 0) {
        return $null
    }
    $head = $result.StdOut.Trim()
    if ([string]::IsNullOrEmpty($head)) {
        return $null
    }
    return $head
}

function Get-GitStatusShort {
    [CmdletBinding()]
    param(
        [string] $WorkingDirectory
    )

    $result = Invoke-GitCapture -Arguments @('status', '--short') -WorkingDirectory $WorkingDirectory
    if ($result.ExitCode -ne 0) {
        return ''
    }
    return $result.StdOut
}
