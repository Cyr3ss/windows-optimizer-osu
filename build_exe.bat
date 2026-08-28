@echo off
title Build Windows Optimizer (.exe)
cd /d "%~dp0"

echo =================================================================
echo   Building Standalone Windows Optimizer Executable (.exe)
echo =================================================================
echo.

:: Check for PyInstaller, install if missing
python -c "import PyInstaller" 2>nul
if %errorLevel% neq 0 (
    echo [*] PyInstaller not found. Installing via pip...
    pip install pyinstaller
    if %errorLevel% neq 0 (
        echo [!] Failed to install PyInstaller. Make sure pip is available.
        pause
        exit /b 1
    )
)

echo [*] Compiling optimizer.py into standalone .exe with UAC Administrator manifest...
pyinstaller --onefile --noconsole --uac-admin --name="WindowsOptimizer" optimizer.py

if %errorLevel% equ 0 (
    echo.
    echo =================================================================
    echo [V] BUILD SUCCESSFUL!
    echo [*] Executable created at: %~dp0dist\WindowsOptimizer.exe
    echo =================================================================
    echo.
) else (
    echo.
    echo [!] Build failed. Check the error messages above.
    echo.
)

pause
