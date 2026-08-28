@echo off
title Windows Gaming & Tablet Optimizer (GUI Launcher)
:: Batch Launcher with automatic Administrator privilege escalation

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [*] Requesting Administrator Privileges...
    powershell -Command "Start-Process '%~dpnx0' -Verb RunAs"
    exit /b
)

cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0optimizer_gui.ps1"
