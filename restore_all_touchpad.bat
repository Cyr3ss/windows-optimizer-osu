@echo off
title Complete Laptop Touchpad & Input Subsystem Restoration
cd /d "%~dp0"

:: Check Administrator Privileges and auto-elevate
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [*] Requesting Administrator Privileges (UAC)...
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process cmd.exe -ArgumentList '/c cd /d `\"%~dp0`\" ^& \"%~dpnx0\"' -Verb RunAs"
    exit /b
)

echo =================================================================
echo   COMPLETELY RESTORING TOUCHPAD, SERVICES & POLICIES...
echo =================================================================
echo.

:: 1. Remove all TabletPC and PenWorkspace Group Policies
echo [*] 1. Removing TabletPC and PenWorkspace Group Policies...
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\TabletPC" /f 2>nul
reg delete "HKCU\Software\Policies\Microsoft\Windows\TabletPC" /f 2>nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\PenWorkspace" /f 2>nul
reg delete "HKCU\Software\Policies\Microsoft\Windows\PenWorkspace" /f 2>nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\HandwritingErrorReports" /f 2>nul

:: 2. Restore TabletInputService and HP Services
echo [*] 2. Enabling and starting Services...
sc.exe config "TabletInputService" start= auto
sc.exe start "TabletInputService"
sc.exe config "HPAppHelperCap" start= auto
sc.exe start "HPAppHelperCap"
sc.exe config "HPSysInfoCap" start= auto
sc.exe start "HPSysInfoCap"
sc.exe config "HPDiagsCap" start= demand
sc.exe config "HPNetworkCap" start= demand

:: 3. Restore Wisp Touch & Pen parameters
echo [*] 3. Restoring Windows Touch and Pen subsystem...
reg delete "HKCU\Software\Microsoft\Wisp\Pen\SysEventParameters" /f 2>nul
reg delete "HKCU\Software\Microsoft\Wisp\Touch" /f 2>nul
reg add "HKCU\Software\Microsoft\Wisp\Touch" /v "TouchUI" /t REG_DWORD /d 1 /f

:: 4. Force Precision Touchpad Enable and LeaveOnWithMouse
echo [*] 4. Enabling Precision Touchpad...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\PrecisionTouchPad" /v "LeaveOnWithMouse" /t REG_DWORD /d 1 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\PrecisionTouchPad" /v "TapsEnabled" /t REG_DWORD /d 4294967295 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\PrecisionTouchPad" /v "PanEnabled" /t REG_DWORD /d 4294967295 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\PrecisionTouchPad" /v "ZoomEnabled" /t REG_DWORD /d 4294967295 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\PrecisionTouchPad\Status" /v "Enabled" /t REG_DWORD /d 1 /f

:: 5. Restore Default SmoothMouse Curve
echo [*] 5. Restoring Default Windows SmoothMouse Curve...
reg add "HKCU\Control Panel\Mouse" /v "SmoothMouseXCurve" /t REG_BINARY /d 0000000000000000156e000000000000004001000000000029dc0300000000000000280000000000 /f
reg add "HKCU\Control Panel\Mouse" /v "SmoothMouseYCurve" /t REG_BINARY /d 0000000000000000fd11010000000000002404000000000000fc1200000000000000c00000000000 /f

:: 6. Restart Synaptics I2C Touchpad Device via PowerShell
echo [*] 6. Re-initializing Synaptics Touchpad Driver...
powershell.exe -NoProfile -Command "Get-PnpDevice | Where-Object { $_.InstanceId -like '*SYNA32C7*' } | ForEach-Object { Disable-PnpDevice -InstanceId $_.InstanceId -Confirm:$false -ErrorAction SilentlyContinue; Start-Sleep -Milliseconds 500; Enable-PnpDevice -InstanceId $_.InstanceId -Confirm:$false -ErrorAction SilentlyContinue }"

echo.
echo =================================================================
echo [V] COMPLETE RESTORATION FINISHED!
echo [*] Check your touchpad now. If needed, press Fn+F11 (or HP Touchpad Hotkey).
echo =================================================================
echo.
pause
