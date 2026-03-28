[CmdletBinding()]
param(
    [string]$LogPath,
    [switch]$Watch,
    [int]$Tail = 120
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectDir = Split-Path -Parent $scriptDir

if (-not $LogPath) {
    $LogPath = Join-Path $projectDir ".codex\godot\latest.log"
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
        Write-Host "等待日志文件: $LogPath"
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
    throw "日志文件不存在: $LogPath"
}

$lines = Get-Content -Path $LogPath -Tail $Tail
$matches = $lines | Where-Object { Test-InterestingLine $_ }

if ($matches.Count -gt 0) {
    $matches | ForEach-Object { Write-InterestingLine $_ }
    return
}

Write-Host "没有发现明显错误，下面是最后 $Tail 行日志："
$lines
