@echo off
title Windows Gaming and Tablet Optimizer
cd /d "%~dp0"

:: 1. Check if Python is installed
python --version >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] Python 3 is not found in PATH.
    echo [*] Please install Python 3 or run the compiled executable from dist\WindowsOptimizer.exe
    echo.
    pause
    exit /b 1
)

:: 2. Launch Optimizer Application
python "%~dp0optimizer.py"
if %errorLevel% neq 0 (
    echo.
    echo [!] Application exited with code %errorLevel%.
    if exist "%~dp0optimizer_error.log" (
        echo [*] Details logged to optimizer_error.log
    )
    pause
)
