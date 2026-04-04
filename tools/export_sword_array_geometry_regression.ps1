param()

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectDir = Split-Path -Parent $scriptDir
$settingsPath = Join-Path $projectDir '.vscode\settings.json'
$godotPath = $null

if (Test-Path $settingsPath) {
    try {
        $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
        $godotPath = $settings.'godotTools.editorPath.godot4'
    }
    catch {
        $godotPath = $null
    }
}

if (-not $godotPath) {
    $godotPath = $env:GODOT4
}

if (-not $godotPath) {
    throw 'Godot path not found. Configure .vscode/settings.json or GODOT4.'
}

if (-not (Test-Path $godotPath)) {
    throw "Godot executable not found: $godotPath"
}

& $godotPath '--path' $projectDir '--headless' '--script' 'res://tools/export_sword_array_geometry_regression.gd'
exit $LASTEXITCODE
