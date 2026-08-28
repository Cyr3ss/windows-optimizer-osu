@echo off
title Windows Gaming and Tablet Optimizer
cd /d "%~dp0"

:: Check Administrator Privileges and auto-elevate
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [*] Requesting Administrator Privileges (UAC)...
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell.exe -ArgumentList '-NoProfile -STA -ExecutionPolicy Bypass -File \"\"%~dp0optimizer_gui.ps1\"\"' -Verb RunAs"
    exit /b
)

echo =================================================================
echo   Windows Gaming and Tablet Optimizer - Launching GUI...
echo =================================================================
echo [*] Directory: %~dp0
echo.

powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File "%~dp0optimizer_gui.ps1"
set EXIT_CODE=%errorLevel%

echo.
if %EXIT_CODE% neq 0 (
    echo =================================================================
    echo [!] Application exited with code: %EXIT_CODE%
    echo [*] Details logged to: optimizer_error.log
    echo =================================================================
    echo.
    pause
)
