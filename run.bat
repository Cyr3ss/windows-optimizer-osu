@echo off
title Windows Gaming & Tablet Optimizer
cd /d "%~dp0"

:: Check if Python is installed
python --version >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] Python 3 is not installed or not added to PATH.
    echo [*] Please install Python 3 (3.8+) or use the compiled dist\WindowsOptimizer.exe
    echo.
    pause
    exit /b 1
)

:: Launch Python Optimizer
python optimizer.py
if %errorLevel% neq 0 (
    echo.
    echo [!] Application closed with an error code. Check optimizer_error.log
    pause
)
