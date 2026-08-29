@echo off
title HP & Precision Touchpad Emergency Fix
cd /d "%~dp0"

:: Check Administrator Privileges and auto-elevate
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [*] Requesting Administrator Privileges (UAC)...
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process cmd.exe -ArgumentList '/c cd /d `\"%~dp0`\" ^& \"%~dpnx0\"' -Verb RunAs"
    exit /b
)

echo =================================================================
echo   Restoring Touchpad, TabletInputService and HP Services...
echo =================================================================
echo.

:: 1. Enable and Start TabletInputService
echo [*] Enabling TabletInputService (Touch/Gesture input)...
sc.exe config "TabletInputService" start= auto
sc.exe start "TabletInputService"

:: 2. Enable HP Hardware Support Services (for Touchpad hotkeys/driver)
echo [*] Enabling HP Hardware Support Services...
sc.exe config "HPAppHelperCap" start= auto
sc.exe start "HPAppHelperCap"
sc.exe config "HPSysInfoCap" start= auto
sc.exe start "HPSysInfoCap"
sc.exe config "HPDiagsCap" start= demand
sc.exe config "HPNetworkCap" start= demand

:: 3. Enable LeaveOnWithMouse in Registry
echo [*] Enabling Precision Touchpad with Mouse / Tablet connected...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\PrecisionTouchPad" /v "LeaveOnWithMouse" /t REG_DWORD /d 1 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\PrecisionTouchPad\Status" /v "Enabled" /t REG_DWORD /d 1 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\PrecisionTouchPad" /v "TapsEnabled" /t REG_DWORD /d 4294967295 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\PrecisionTouchPad" /v "PanEnabled" /t REG_DWORD /d 4294967295 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\PrecisionTouchPad" /v "ZoomEnabled" /t REG_DWORD /d 4294967295 /f
reg add "HKCU\Software\Microsoft\Wisp\Touch" /v "TouchUI" /t REG_DWORD /d 1 /f
reg add "HKCU\Software\Microsoft\Wisp\Touch" /v "TouchMode_hold" /t REG_DWORD /d 1 /f

:: 4. Remove global USB driver block
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\USB" /v "DisableSelectiveSuspend" /f 2>nul

echo.
echo =================================================================
echo [V] SUCCESS! Touchpad services and registry restored.
echo [*] If the touchpad is still off, check the checkbox:
echo     "Не отключать сенсорную панель при подключении мыши"
echo =================================================================
echo.
pause
