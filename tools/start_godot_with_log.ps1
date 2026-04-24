[CmdletBinding()]
param(
    [ValidateSet("editor", "run")]
    [string]$Mode = "editor",
    [string]$GodotPath,
    [switch]$Wait,
    [switch]$Headless,
    [switch]$Detach,
    [string[]]$ExtraArgs = @()
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectDir = Split-Path -Parent $scriptDir
$logDir = Join-Path $projectDir ".codex\godot"
$latestLogPath = Join-Path $logDir "latest.log"
$metaPath = Join-Path $logDir "latest-session.json"
$sessionId = "{0}-{1}" -f (Get-Date -Format "yyyyMMdd-HHmmss"), $PID
$sessionLogPath = Join-Path $logDir ("session-{0}.log" -f $sessionId)

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

function Get-FallbackGodotCandidates {
    $candidates = New-Object System.Collections.Generic.List[string]
    $searchRoots = @(
        "E:\Godot",
        "G:\Godot",
        "D:\Godot",
        "C:\Godot",
        (Join-Path $env:ProgramFiles "Godot"),
        (Join-Path ${env:ProgramFiles(x86)} "Godot")
    ) | Where-Object { $_ }

    foreach ($root in $searchRoots) {
        if (-not (Test-Path $root)) {
            continue
        }

        $preferred = Get-ChildItem -LiteralPath $root -Filter "Godot*_win64.exe" -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -notmatch "_console" } |
            Sort-Object LastWriteTime -Descending

        foreach ($file in $preferred) {
            $candidates.Add($file.FullName)
        }
    }

    return $candidates
}

function Resolve-GodotExecutable {
    param([string[]]$Candidates)

    foreach ($candidate in ($Candidates | Where-Object { $_ } | Select-Object -Unique)) {
        if (Test-Path $candidate) {
            return $candidate
        }
    }

    return $null
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

function Expand-ExtraArguments {
    param([string[]]$Values)

    $expanded = New-Object System.Collections.Generic.List[string]

    foreach ($value in $Values) {
        if ([string]::IsNullOrWhiteSpace($value)) {
            continue
        }

        $trimmed = $value.Trim()
        if ($trimmed.Length -ge 4 -and $trimmed.StartsWith("'") -and $trimmed.EndsWith("'") -and $trimmed.Contains("','")) {
            $segments = $trimmed.Substring(1, $trimmed.Length - 2) -split "','"
            foreach ($segment in $segments) {
                if (-not [string]::IsNullOrWhiteSpace($segment)) {
                    $expanded.Add($segment)
                }
            }
            continue
        }

        if ($trimmed.Length -ge 4 -and $trimmed.StartsWith('"') -and $trimmed.EndsWith('"') -and $trimmed.Contains('","')) {
            $segments = $trimmed.Substring(1, $trimmed.Length - 2) -split '","'
            foreach ($segment in $segments) {
                if (-not [string]::IsNullOrWhiteSpace($segment)) {
                    $expanded.Add($segment)
                }
            }
            continue
        }

        $expanded.Add($value)
    }

    return $expanded.ToArray()
}

function Normalize-CommandLineText {
    param([string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return ""
    }

    return ($Value.ToLowerInvariant() -replace "\\", "/")
}

function Stop-StaleHeadlessGodotProcesses {
    param(
        [string]$ProjectRoot,
        [TimeSpan]$OlderThan
    )

    $normalizedProjectRoot = Normalize-CommandLineText -Value $ProjectRoot
    $cutoff = (Get-Date).Add(-$OlderThan)

    $staleProcesses = Get-CimInstance Win32_Process -Filter "Name = 'Godot_v4.6.1-stable_win64.exe'" | Where-Object {
        $commandLine = $_.CommandLine
        if ([string]::IsNullOrWhiteSpace($commandLine) -or $null -eq $_.CreationDate) {
            return $false
        }

        $normalizedCommandLine = Normalize-CommandLineText -Value $commandLine
        $isSameProject = $normalizedCommandLine.Contains($normalizedProjectRoot)
        $isHeadless = $normalizedCommandLine.Contains("--headless")
        $isShortLived = $normalizedCommandLine.Contains("--quit-after") -or $normalizedCommandLine.Contains("--script")
        $isOldEnough = $_.CreationDate -lt $cutoff

        return $isSameProject -and $isHeadless -and $isShortLived -and $isOldEnough
    }

    foreach ($process in $staleProcesses) {
        try {
            Stop-Process -Id $process.ProcessId -Force -ErrorAction Stop
            Write-Host ("Cleaned stale headless Godot PID {0}" -f $process.ProcessId) -ForegroundColor Yellow
        }
        catch {
            Write-Warning ("Failed to clean stale headless Godot PID {0}: {1}" -f $process.ProcessId, $_.Exception.Message)
        }
    }
}

$candidateGodotPaths = @(
    $GodotPath,
    (Get-ConfiguredGodotPath -ProjectRoot $projectDir),
    $env:GODOT4
) + (Get-FallbackGodotCandidates)

$resolvedGodotPath = Resolve-GodotExecutable -Candidates $candidateGodotPaths
if (-not $resolvedGodotPath) {
    $checked = ($candidateGodotPaths | Where-Object { $_ } | Select-Object -Unique) -join ", "
    throw "Godot path not found. Checked: $checked"
}

New-Item -ItemType Directory -Path $logDir -Force | Out-Null
$normalizedExtraArgs = Expand-ExtraArguments -Values $ExtraArgs
$shouldWait = [bool]($Wait -or ($Headless -and -not $Detach))

if ($Headless) {
    Stop-StaleHeadlessGodotProcesses -ProjectRoot $projectDir -OlderThan ([TimeSpan]::FromMinutes(5))
}

Set-Content -Path $sessionLogPath -Value "" -Encoding UTF8
try {
    Set-Content -Path $latestLogPath -Value ("Current Godot session log:`r`n{0}`r`n" -f $sessionLogPath) -Encoding UTF8
}
catch {
    Write-Warning ("Could not update latest.log pointer: {0}" -f $_.Exception.Message)
}

$sessionInfo = [ordered]@{
    started_at = (Get-Date).ToString("s")
    mode = $Mode
    headless = [bool]$Headless
    wait = $shouldWait
    detached = [bool](-not $shouldWait)
    project_dir = $projectDir
    godot_path = $resolvedGodotPath
    log_path = $sessionLogPath
    extra_args = $normalizedExtraArgs
}
$sessionInfo | ConvertTo-Json | Set-Content -Path $metaPath -Encoding UTF8

$arguments = @("--path", $projectDir, "--log-file", $sessionLogPath)
if ($Mode -eq "editor") {
    $arguments += "--editor"
}
if ($Headless) {
    $arguments += "--headless"
}
if ($normalizedExtraArgs.Count -gt 0) {
    $arguments += $normalizedExtraArgs
}
$startProcessArguments = $arguments | ForEach-Object { Quote-Argument $_ }

Write-Host "Godot: $resolvedGodotPath"
Write-Host "Mode : $Mode"
Write-Host "Log  : $sessionLogPath"
if ($Headless -and -not $Wait -and -not $Detach) {
    Write-Host "Headless run defaults to waiting. Use -Detach to run it in the background." -ForegroundColor Yellow
}

if ($shouldWait) {
    & $resolvedGodotPath @arguments
    $exitCode = if ($null -eq $LASTEXITCODE) { 0 } else { [int]$LASTEXITCODE }
    $sessionInfo.finished_at = (Get-Date).ToString("s")
    $sessionInfo.exit_code = $exitCode
    $sessionInfo | ConvertTo-Json | Set-Content -Path $metaPath -Encoding UTF8
    exit $exitCode
}

$process = Start-Process -FilePath $resolvedGodotPath -ArgumentList $startProcessArguments -WorkingDirectory $projectDir -PassThru
$sessionInfo.pid = $process.Id
$sessionInfo | ConvertTo-Json | Set-Content -Path $metaPath -Encoding UTF8
Write-Host "PID  : $($process.Id)"
