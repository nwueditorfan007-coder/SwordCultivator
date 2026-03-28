@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\launch_godot_easy.ps1"
if errorlevel 1 pause
