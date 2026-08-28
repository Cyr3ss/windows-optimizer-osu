@echo off
title Windows Gaming and Tablet Optimizer (GUI Launcher)
cd /d "%~dp0"

:: Check Administrator Privileges and auto-elevate
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [*] Requesting Administrator Privileges (UAC)...
    powershell -NoProfile -Command "Start-Process '%~dpnx0' -Verb RunAs"
    exit /b
)

echo =================================================================
echo   Windows Gaming and Tablet Optimizer - Launching GUI...
echo =================================================================
echo [*] Working Directory: %~dp0
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0optimizer_gui.ps1"
set EXIT_CODE=%errorLevel%

echo.
if %EXIT_CODE% neq 0 (
    echo =================================================================
    echo [!] Application exited with error code: %EXIT_CODE%
    echo [*] Check "optimizer_error.log" in this directory for details.
    echo =================================================================
    echo.
    pause
) else (
    echo [V] Application closed cleanly.
    echo Press any key to close this console window...
    pause >nul
)
