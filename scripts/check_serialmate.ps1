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

Write-Output 'SerialMate health check (discovery, --help, --list-instances only)'
$resolvedExecutable = Resolve-SerialMate

if (-not $resolvedExecutable -or -not (Test-Path -LiteralPath $resolvedExecutable -PathType Leaf)) {
    Write-CheckResult 'Executable' $false 'SerialMate.exe not found. Set SERIALMATE_EXE, add it to PATH, or pass -ExecutablePath.'
    exit 1
}

Write-CheckResult 'Executable' $true $resolvedExecutable

foreach ($argument in @('--help', '--list-instances')) {
    try {
        $output = & $resolvedExecutable $argument 2>&1
        $exitCode = $LASTEXITCODE
        $preview = (($output | Out-String).Trim() -replace '\s+', ' ')
        if ($preview.Length -gt 240) { $preview = $preview.Substring(0, 240) + '…' }
        Write-CheckResult $argument ($exitCode -eq 0) ("exit={0}; {1}" -f $exitCode, $preview)
        if ($exitCode -ne 0) { $script:failed = $true }
    }
    catch {
        Write-CheckResult $argument $false $_.Exception.Message
        $script:failed = $true
    }
}

if ($script:failed) { exit 1 }
exit 0

