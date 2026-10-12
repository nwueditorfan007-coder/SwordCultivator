Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$godotPath = 'E:\Godot\Godot_v4.6.1-stable_win64_console.exe'
$projectPath = 'E:\SwordCultivator'
$testScript = 'res://tools/start_menu_smoke_test.gd'

& $godotPath --headless --path $projectPath --script $testScript
$exitCode = [int]$LASTEXITCODE
Write-Output ("START_MENU_TEST_EXIT_CODE={0}" -f $exitCode)
if ($exitCode -ne 0) {
    exit $exitCode
}
