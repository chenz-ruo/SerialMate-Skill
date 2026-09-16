[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$ExecutablePath
)

$ErrorActionPreference = 'Stop'

function Write-CheckResult {
    param(
        [string]$Label,
        [bool]$Ok,
        [string]$Detail
    )

    $state = if ($Ok) { 'PASS' } else { 'FAIL' }
    Write-Output ("[{0}] {1}: {2}" -f $state, $Label, $Detail)
}

function Resolve-SerialMate {
    if ($env:SERIALMATE_EXE) {
        $fromEnvironment = Resolve-Path -LiteralPath $env:SERIALMATE_EXE -ErrorAction SilentlyContinue
        if ($fromEnvironment) { return $fromEnvironment.Path }
    }

    $fromPath = Get-Command 'SerialMate.exe' -CommandType Application -ErrorAction SilentlyContinue
    if ($fromPath) { return $fromPath.Source }

    if ($ExecutablePath) {
        return (Resolve-Path -LiteralPath $ExecutablePath -ErrorAction SilentlyContinue).Path
    }

    return $null
}

function Invoke-SerialMateCheck {
    param(
        [string]$Path,
        [string]$Argument
    )

    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $Path
    $startInfo.Arguments = $Argument
    $startInfo.UseShellExecute = $false
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $startInfo.CreateNoWindow = $true

    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $startInfo

    try {
        [void]$process.Start()
        $stdoutTask = $process.StandardOutput.ReadToEndAsync()
        $stderrTask = $process.StandardError.ReadToEndAsync()

        if (-not $process.WaitForExit(10000)) {
            $process.Kill($true)
            $process.WaitForExit()
            return [pscustomobject]@{
                TimedOut = $true
                ExitCode = $null
                Output = $stdoutTask.GetAwaiter().GetResult()
                Error = $stderrTask.GetAwaiter().GetResult()
            }
        }

        return [pscustomobject]@{
            TimedOut = $false
            ExitCode = $process.ExitCode
            Output = $stdoutTask.GetAwaiter().GetResult()
            Error = $stderrTask.GetAwaiter().GetResult()
        }
    }
    finally {
        $process.Dispose()
    }
}

Write-Output 'SerialMate health check (discovery, --help, --list-instances only)'
$resolvedExecutable = Resolve-SerialMate

if (-not $resolvedExecutable -or -not (Test-Path -LiteralPath $resolvedExecutable -PathType Leaf)) {
    Write-CheckResult 'Executable' $false 'SerialMate.exe not found. Set SERIALMATE_EXE, add it to PATH, or pass -ExecutablePath.'
    exit 1
}

Write-CheckResult 'Executable' $true $resolvedExecutable
$versionInfo = (Get-Item -LiteralPath $resolvedExecutable).VersionInfo
$version = if ($versionInfo.ProductVersion) { $versionInfo.ProductVersion } else { $versionInfo.FileVersion }
if ($version) {
    Write-CheckResult 'Version' $true $version
}
else {
    Write-CheckResult 'Version' $false 'No file or product version was found.'
    $script:failed = $true
}

foreach ($argument in @('--help', '--list-instances')) {
    try {
        $result = Invoke-SerialMateCheck -Path $resolvedExecutable -Argument $argument
        if ($result.TimedOut) {
            Write-CheckResult $argument $false 'Timed out after 10 seconds; the executable may not support Automation CLI.'
            $script:failed = $true
            continue
        }

        $preview = (($result.Output + ' ' + $result.Error).Trim() -replace '\s+', ' ')
        if ($preview.Length -gt 240) { $preview = $preview.Substring(0, 240) + '…' }
        Write-CheckResult $argument ($result.ExitCode -eq 0) ("exit={0}; {1}" -f $result.ExitCode, $preview)
        if ($result.ExitCode -ne 0) { $script:failed = $true }
    }
    catch {
        Write-CheckResult $argument $false $_.Exception.Message
        $script:failed = $true
    }
}

if ($script:failed) { exit 1 }
exit 0

