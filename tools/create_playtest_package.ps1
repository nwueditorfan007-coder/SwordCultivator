[CmdletBinding()]
param(
    [string]$GodotPath = "E:\Godot\Godot_v4.6.1-stable_win64.exe",
    [string]$OutputRoot,
    [string]$PackageName = "SwordCultivator_Playtest_Windows"
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectDir = Split-Path -Parent $scriptDir

if (-not $OutputRoot) {
    $OutputRoot = Join-Path $projectDir "dist"
}

if (-not (Test-Path $GodotPath)) {
    throw "Godot executable not found: $GodotPath"
}

$packageDir = Join-Path $OutputRoot $PackageName
$gameDir = Join-Path $packageDir "game"
$zipPath = Join-Path $OutputRoot ($PackageName + ".zip")

if (Test-Path $packageDir) {
    Remove-Item -LiteralPath $packageDir -Recurse -Force
}

New-Item -ItemType Directory -Force -Path $OutputRoot | Out-Null
New-Item -ItemType Directory -Force -Path $gameDir | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $gameDir ".godot") | Out-Null

$rootFiles = @(
    "project.godot",
    "icon.svg",
    "icon.svg.import"
)

foreach ($file in $rootFiles) {
    Copy-Item -LiteralPath (Join-Path $projectDir $file) -Destination (Join-Path $gameDir $file) -Force
}

$runtimeDirs = @(
    "scenes",
    "scripts",
    "resources"
)

foreach ($dir in $runtimeDirs) {
    Copy-Item -LiteralPath (Join-Path $projectDir $dir) -Destination (Join-Path $gameDir $dir) -Recurse -Force
}

$godotFiles = @(
    ".gdignore",
    "global_script_class_cache.cfg",
    "scene_groups_cache.cfg",
    "uid_cache.bin"
)

foreach ($file in $godotFiles) {
    $source = Join-Path $projectDir ".godot\$file"
    if (Test-Path $source) {
        Copy-Item -LiteralPath $source -Destination (Join-Path $gameDir ".godot\$file") -Force
    }
}

$importedSource = Join-Path $projectDir ".godot\imported"
if (Test-Path $importedSource) {
    Copy-Item -LiteralPath $importedSource -Destination (Join-Path $gameDir ".godot\imported") -Recurse -Force
}

Copy-Item -LiteralPath $GodotPath -Destination (Join-Path $packageDir "SwordCultivator.exe") -Force

$launcherPath = Join-Path $packageDir "启动游戏.cmd"
$launcherContent = @'
@echo off
setlocal
cd /d "%~dp0"
start "" "%~dp0SwordCultivator.exe" --path "%~dp0game"
'@
Set-Content -LiteralPath $launcherPath -Value $launcherContent -Encoding ASCII

$logViewerPath = Join-Path $packageDir "查看最近日志.cmd"
$logViewerContent = @'
@echo off
setlocal
set "LOG=%~dp0game\.godot\app_userdata\SwordCultivator\logs\godot.log"
if exist "%LOG%" (
    notepad "%LOG%"
) else (
    echo 还没有发现日志文件：%LOG%
    pause
)
'@
Set-Content -LiteralPath $logViewerPath -Value $logViewerContent -Encoding ASCII

$readmePath = Join-Path $packageDir "README.txt"
$readmeContent = @'
SwordCultivator Windows playtest package

How to run
1. Unzip this folder anywhere.
2. Double-click 启动游戏.cmd

Controls
- WASD: move
- Left mouse: melee slash
- Hold left mouse: fire absorbed bullets
- Right mouse tap: point strike
- Right mouse hold: slicing sword
- Space: absorb frozen bullets
- Q: ultimate

Notes
- This is a portable playtest build, not a formal installer.
- If the game closes unexpectedly, open 查看最近日志.cmd and send the log back.
'@
Set-Content -LiteralPath $readmePath -Value $readmeContent -Encoding ASCII

if (Test-Path $zipPath) {
    Remove-Item -LiteralPath $zipPath -Force
}

Compress-Archive -LiteralPath $packageDir -DestinationPath $zipPath -Force

Write-Host "Package directory: $packageDir"
Write-Host "Zip archive      : $zipPath"
