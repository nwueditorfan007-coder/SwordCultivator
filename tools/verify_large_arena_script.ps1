Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$godotPath = 'E:\Godot\Godot_v4.6.1-stable_win64_console.exe'
$projectPath = 'E:\SwordCultivator'
& $godotPath --headless --path $projectPath --editor --quit
$exitCode = [int]$LASTEXITCODE
Write-Output ("GODOT_PARSE_EXIT_CODE={0}" -f $exitCode)
if ($exitCode -ne 0) {
    exit $exitCode
}

$testScripts = @(
    'res://tools/large_arena_objective_smoke_test.gd',
    'res://tools/large_arena_engagement_smoke_test.gd'
)
foreach ($testScript in $testScripts) {
    & $godotPath --headless --path $projectPath --script $testScript
    $exitCode = [int]$LASTEXITCODE
    Write-Output ("GODOT_TEST_EXIT_CODE={0} TEST={1}" -f $exitCode, $testScript)
    if ($exitCode -ne 0) {
        exit $exitCode
    }
}
