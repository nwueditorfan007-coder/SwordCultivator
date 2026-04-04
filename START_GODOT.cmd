@echo off
setlocal
set "PWSH=C:\Program Files\PowerShell\7\pwsh.exe"
if exist "%PWSH%" (
    "%PWSH%" -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\launch_godot_easy.ps1"
) else (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\launch_godot_easy.ps1"
)
if errorlevel 1 pause
