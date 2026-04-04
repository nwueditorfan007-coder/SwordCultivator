@echo off
setlocal
set "PWSH=C:\Program Files\PowerShell\7\pwsh.exe"
if exist "%PWSH%" (
    "%PWSH%" -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\show_godot_errors.ps1"
) else (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\show_godot_errors.ps1"
)
pause
