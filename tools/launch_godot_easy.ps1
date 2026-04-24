[CmdletBinding()]
param(
    [ValidateSet("editor", "run")]
    [string]$Mode = "editor",
    [switch]$NoWatcher,
    [switch]$Wait,
    [switch]$Headless,
    [switch]$Detach,
    [string[]]$ExtraArgs = @()
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectDir = Split-Path -Parent $scriptDir
$startScript = Join-Path $scriptDir "start_godot_with_log.ps1"
$watchScript = Join-Path $scriptDir "show_godot_errors.ps1"
$pwshPath = "C:\Program Files\PowerShell\7\pwsh.exe"
$powerShellExe = if (Test-Path $pwshPath) { $pwshPath } else { "powershell.exe" }

function Start-WatcherWindow {
    param(
        [string]$ProjectRoot,
        [string]$WatcherPath
    )

    $watchCommand = "& { Set-Location -LiteralPath '$ProjectRoot'; & '$WatcherPath' -Watch }"
    Start-Process -FilePath $powerShellExe `
        -ArgumentList @("-NoExit", "-ExecutionPolicy", "Bypass", "-Command", $watchCommand) `
        -WorkingDirectory $ProjectRoot | Out-Null
}

if (-not $NoWatcher) {
    if ($Headless -or $Wait) {
        $NoWatcher = $true
    }
}

if (-not $NoWatcher) {
    Start-WatcherWindow -ProjectRoot $projectDir -WatcherPath $watchScript
    Start-Sleep -Milliseconds 400
}

& $startScript -Mode $Mode -Wait:$Wait -Headless:$Headless -Detach:$Detach -ExtraArgs $ExtraArgs
exit $LASTEXITCODE
