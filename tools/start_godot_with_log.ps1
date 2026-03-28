[CmdletBinding()]
param(
    [ValidateSet("editor", "run")]
    [string]$Mode = "editor",
    [string]$GodotPath,
    [switch]$Wait,
    [switch]$Headless,
    [string[]]$ExtraArgs = @()
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectDir = Split-Path -Parent $scriptDir
$logDir = Join-Path $projectDir ".codex\godot"
$latestLogPath = Join-Path $logDir "latest.log"
$metaPath = Join-Path $logDir "latest-session.json"

function Get-ConfiguredGodotPath {
    param([string]$ProjectRoot)

    $settingsPath = Join-Path $ProjectRoot ".vscode\settings.json"
    if (-not (Test-Path $settingsPath)) {
        return $null
    }

    try {
        $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
        return $settings.'godotTools.editorPath.godot4'
    }
    catch {
        return $null
    }
}

function Quote-Argument {
    param([string]$Value)

    if ($null -eq $Value -or $Value -eq "") {
        return '""'
    }

    if ($Value -match '[\s"]') {
        return '"' + ($Value -replace '"', '\"') + '"'
    }

    return $Value
}

$resolvedGodotPath = $GodotPath
if (-not $resolvedGodotPath) {
    $resolvedGodotPath = Get-ConfiguredGodotPath -ProjectRoot $projectDir
}
if (-not $resolvedGodotPath) {
    $resolvedGodotPath = $env:GODOT4
}
if (-not $resolvedGodotPath) {
    throw "找不到 Godot 路径。请在 .vscode/settings.json 配置 godotTools.editorPath.godot4，或传入 -GodotPath。"
}
if (-not (Test-Path $resolvedGodotPath)) {
    throw "Godot 不存在: $resolvedGodotPath"
}

New-Item -ItemType Directory -Path $logDir -Force | Out-Null
Set-Content -Path $latestLogPath -Value "" -Encoding UTF8

$sessionInfo = [ordered]@{
    started_at = (Get-Date).ToString("s")
    mode = $Mode
    headless = [bool]$Headless
    project_dir = $projectDir
    godot_path = $resolvedGodotPath
}
$sessionInfo | ConvertTo-Json | Set-Content -Path $metaPath -Encoding UTF8

$arguments = @("--path", $projectDir, "--log-file", $latestLogPath)
if ($Mode -eq "editor") {
    $arguments += "--editor"
}
if ($Headless) {
    $arguments += "--headless"
}
if ($ExtraArgs.Count -gt 0) {
    $arguments += $ExtraArgs
}

$argumentString = ($arguments | ForEach-Object { Quote-Argument $_ }) -join " "

Write-Host "Godot: $resolvedGodotPath"
Write-Host "Mode : $Mode"
Write-Host "Log  : $latestLogPath"

if ($Wait) {
    & $resolvedGodotPath @arguments
    exit $LASTEXITCODE
}

$process = Start-Process -FilePath $resolvedGodotPath -ArgumentList $argumentString -WorkingDirectory $projectDir -PassThru
Write-Host "PID  : $($process.Id)"
