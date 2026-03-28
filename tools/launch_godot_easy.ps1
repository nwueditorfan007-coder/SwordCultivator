[CmdletBinding()]
param(
    [ValidateSet("editor", "run")]
    [string]$Mode = "editor",
    [switch]$NoWatcher,
    [switch]$Wait,
    [switch]$Headless,
    [string[]]$ExtraArgs = @()
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectDir = Split-Path -Parent $scriptDir
$startScript = Join-Path $scriptDir "start_godot_with_log.ps1"
$watchScript = Join-Path $scriptDir "show_godot_errors.ps1"

function Start-WatcherWindow {
    param(
        [string]$ProjectRoot,
        [string]$WatcherPath
    )

    $watchCommand = "& { Set-Location -LiteralPath '$ProjectRoot'; & '$WatcherPath' -Watch }"
    Start-Process -FilePath "powershell.exe" `
        -ArgumentList @("-NoExit", "-ExecutionPolicy", "Bypass", "-Command", $watchCommand) `
        -WorkingDirectory $ProjectRoot | Out-Null
}

if (-not $NoWatcher) {
    Start-WatcherWindow -ProjectRoot $projectDir -WatcherPath $watchScript
    Start-Sleep -Milliseconds 400
}

& $startScript -Mode $Mode -Wait:$Wait -Headless:$Headless -ExtraArgs $ExtraArgs
exit $LASTEXITCODE
