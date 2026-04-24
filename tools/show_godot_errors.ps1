[CmdletBinding()]
param(
    [string]$LogPath,
    [switch]$Watch,
    [int]$Tail = 120
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectDir = Split-Path -Parent $scriptDir
$metaPath = Join-Path $projectDir ".codex\godot\latest-session.json"

function Get-LatestSessionInfo {
    if (-not (Test-Path $metaPath)) {
        return $null
    }

    try {
        return Get-Content $metaPath -Raw | ConvertFrom-Json
    }
    catch {
        return $null
    }
}

function Resolve-DefaultLogPath {
    param(
        [switch]$WaitForFreshSession,
        [datetime]$NotBefore = [datetime]::MinValue
    )

    while ($true) {
        $sessionInfo = Get-LatestSessionInfo
        if ($sessionInfo -and $sessionInfo.log_path) {
            $startedAt = $null
            try {
                $startedAt = [datetime]$sessionInfo.started_at
            }
            catch {
                $startedAt = $null
            }

            if (-not $WaitForFreshSession -or $null -eq $startedAt -or $startedAt -ge $NotBefore.AddSeconds(-2)) {
                return [string]$sessionInfo.log_path
            }
        }

        if (-not $WaitForFreshSession) {
            break
        }

        Start-Sleep -Milliseconds 300
    }

    return Join-Path $projectDir ".codex\godot\latest.log"
}

if (-not $LogPath) {
    if ($Watch) {
        $LogPath = Resolve-DefaultLogPath -WaitForFreshSession -NotBefore (Get-Date)
    }
    else {
        $LogPath = Resolve-DefaultLogPath
    }
}

$patterns = @(
    "SCRIPT ERROR",
    "Parser Error",
    "Parse Error",
    "Invalid call",
    "Attempt to call",
    "Node not found",
    "Null",
    "ERROR:",
    "Failed",
    "Condition .* is true"
)

function Test-InterestingLine {
    param([string]$Line)

    foreach ($pattern in $patterns) {
        if ($Line -match $pattern) {
            return $true
        }
    }

    return $false
}

function Write-InterestingLine {
    param([string]$Line)

    if (Test-InterestingLine $Line) {
        Write-Host $Line -ForegroundColor Red
    }
}

if ($Watch) {
    if (-not (Test-Path $LogPath)) {
        Write-Host "Waiting for log file: $LogPath"
        while (-not (Test-Path $LogPath)) {
            Start-Sleep -Milliseconds 500
        }
    }

    Write-Host "Watching $LogPath"
    Get-Content -Path $LogPath -Wait | ForEach-Object {
        Write-InterestingLine $_
    }
    return
}

if (-not (Test-Path $LogPath)) {
    throw "Log file does not exist: $LogPath"
}

$lines = Get-Content -Path $LogPath -Tail $Tail
$matches = $lines | Where-Object { Test-InterestingLine $_ }

if ($matches.Count -gt 0) {
    $matches | ForEach-Object { Write-InterestingLine $_ }
    return
}

Write-Host "No obvious errors found. Showing last $Tail log lines:"
$lines
