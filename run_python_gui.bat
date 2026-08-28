@echo off
title Windows Gaming and Tablet Optimizer (Python Launcher)
cd /d "%~dp0"

python "%~dp0optimizer.py"
if %errorLevel% neq 0 (
    echo.
    echo =================================================================
    echo [!] Python script exited with error code: %errorLevel%
    echo [*] Check "optimizer_error.log" for details.
    echo =================================================================
    echo.
    pause
)
