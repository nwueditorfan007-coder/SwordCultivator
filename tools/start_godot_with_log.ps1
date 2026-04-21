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
