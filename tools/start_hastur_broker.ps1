[CmdletBinding()]
param(
    [string]$HostName = "localhost",
    [int]$HttpPort = 5302,
    [int]$TcpPort = 5301,
    [switch]$Wait
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectDir = Split-Path -Parent $scriptDir
$hasturRoot = Join-Path $scriptDir "hastur-operation-plugin"
$brokerDir = Join-Path $hasturRoot "broker-server"
$tokenPath = Join-Path $hasturRoot ".hastur-auth-token"
$logDir = Join-Path $projectDir ".codex\godot"
$logPath = Join-Path $logDir "hastur-broker.log"
$errLogPath = Join-Path $logDir "hastur-broker.err.log"

function New-HasturToken {
    $bytes = New-Object byte[] 32
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    try {
        $rng.GetBytes($bytes)
    } finally {
        $rng.Dispose()
    }
    return (($bytes | ForEach-Object { $_.ToString("x2") }) -join "")
}

function Get-HasturToken {
    if (-not (Test-Path $tokenPath)) {
        New-Item -ItemType Directory -Force -Path $hasturRoot | Out-Null
        Set-Content -LiteralPath $tokenPath -Value (New-HasturToken) -NoNewline -Encoding ascii
    }
    return (Get-Content -LiteralPath $tokenPath -Raw).Trim()
}

function Test-NodeExecutable {
    param([string]$Path)

    if (-not $Path -or -not (Test-Path $Path)) {
        return $false
    }

    try {
        & $Path --version *> $null
        return ($LASTEXITCODE -eq 0)
    } catch {
        return $false
    }
}

function Resolve-NodeExecutable {
    $portableNode = Join-Path $projectDir ".codex_tmp\node-v22.22.2-win-x64\node.exe"
    if (Test-NodeExecutable $portableNode) {
        return $portableNode
    }

    $cmd = Get-Command node.exe -ErrorAction SilentlyContinue
    if ($cmd -and (Test-NodeExecutable $cmd.Source)) {
        return $cmd.Source
    }

    throw "No usable node.exe found. Expected portable Node at $portableNode or a working node.exe on PATH."
}

function Resolve-NpmExecutable {
    $portableNpm = Join-Path $projectDir ".codex_tmp\node-v22.22.2-win-x64\npm.cmd"
    if (Test-Path $portableNpm) {
        return $portableNpm
    }

    $cmd = Get-Command npm.cmd -ErrorAction SilentlyContinue
    if ($cmd) {
        return $cmd.Source
    }

    $cmd = Get-Command npm.exe -ErrorAction SilentlyContinue
    if ($cmd) {
        return $cmd.Source
    }

    throw "No usable npm found. Install Node.js 18+ or keep the project portable Node under .codex_tmp."
}

function Invoke-HasturHealth {
    try {
        return Invoke-RestMethod -Uri "http://${HostName}:${HttpPort}/api/health" -TimeoutSec 2
    } catch {
        return $null
    }
}

function Test-HasturToken {
    param([string]$Token)

    try {
        Invoke-RestMethod `
            -Uri "http://${HostName}:${HttpPort}/api/executors" `
            -Headers @{ Authorization = "Bearer $Token" } `
            -TimeoutSec 2 | Out-Null
        return $true
    } catch {
        return $false
    }
}

if (-not (Test-Path $brokerDir)) {
    throw "Hastur broker-server was not found at $brokerDir"
}

New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$token = Get-HasturToken

$health = Invoke-HasturHealth
if ($health -and $health.success) {
    if (-not (Test-HasturToken $token)) {
        throw "A Hastur broker is already listening on http://${HostName}:${HttpPort}, but it does not accept this project's token file."
    }
    Write-Host "Hastur broker already running at http://${HostName}:${HttpPort}"
    Write-Host "Hastur token file: $tokenPath"
    return
}

$nodeExe = Resolve-NodeExecutable
$tsxCli = Join-Path $brokerDir "node_modules\tsx\dist\cli.mjs"
if (-not (Test-Path $tsxCli)) {
    $npmExe = Resolve-NpmExecutable
    Push-Location $brokerDir
    try {
        & $npmExe install
    } finally {
        Pop-Location
    }
}

if (-not (Test-Path $tsxCli)) {
    throw "tsx CLI was not found after dependency install: $tsxCli"
}

$brokerArgs = @(
    $tsxCli,
    (Join-Path $brokerDir "src\index.ts"),
    "--host", $HostName,
    "--http-port", "$HttpPort",
    "--tcp-port", "$TcpPort",
    "--auth-token", $token
)

if ($Wait) {
    & $nodeExe @brokerArgs
    exit $LASTEXITCODE
}

Start-Process `
    -FilePath $nodeExe `
    -ArgumentList $brokerArgs `
    -WorkingDirectory $brokerDir `
    -RedirectStandardOutput $logPath `
    -RedirectStandardError $errLogPath `
    -WindowStyle Hidden | Out-Null

for ($i = 0; $i -lt 30; $i++) {
    Start-Sleep -Milliseconds 250
    $health = Invoke-HasturHealth
    if ($health -and $health.success) {
        Write-Host "Hastur broker started at http://${HostName}:${HttpPort}"
        Write-Host "Hastur token file: $tokenPath"
        return
    }
}

throw "Hastur broker did not become healthy. Check $logPath and $errLogPath"
