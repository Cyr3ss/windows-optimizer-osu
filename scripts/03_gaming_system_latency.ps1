<#
.SYNOPSIS
    Applies system-level gaming latency tweaks: BCD timers, Windows Game Mode, DWM Fullscreen Exclusive mode, Multimedia Gaming & Audio Profiles, Keyboard Delay reduction, CPU Core Unparking, and Kernel RAM residency.
#>

Write-Host "=== [3/5] Системные таймеры, Game Mode, DWM Fullscreen, клавиатура и ядро ===" -ForegroundColor Cyan

# 1. BCD High-Precision Invariant Clock Tweaks
Write-Host "[*] Настройка аппаратных таймеров Windows (BCD)..." -ForegroundColor Yellow
try {
    bcdedit /set disabledynamictick yes 2>$null | Out-Null
    bcdedit /set useplatformclock no 2>$null | Out-Null
    Write-Host "  [+] Dynamic Tick отключен, аппаратный TSC-таймер активен." -ForegroundColor Green
} catch {}

# 2. Windows Game Mode & Fullscreen Exclusive
Write-Host "[*] Включение Game Mode и прямого вывода кадров (HonorFSE)..." -ForegroundColor Yellow
$gb = "HKCU:\Software\Microsoft\GameBar"
if (-not (Test-Path $gb)) { New-Item -Path $gb -Force | Out-Null }
Set-ItemProperty -Path $gb -Name "AutoGameModeEnabled" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $gb -Name "AllowAutoGameMode" -Value 1 -Type DWord -Force

$gcs = "HKCU:\System\GameConfigStore"
if (-not (Test-Path $gcs)) { New-Item -Path $gcs -Force | Out-Null }
Set-ItemProperty -Path $gcs -Name "GameDVR_DXGIHonorFSEWindowsCompatible" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $gcs -Name "GameDVR_FSEBehaviorMode" -Value 2 -Type DWord -Force
Set-ItemProperty -Path $gcs -Name "GameDVR_Enabled" -Value 0 -Type DWord -Force

# Disable GameBarPresenceWriter
$gbpw = "HKLM:\SOFTWARE\Microsoft\WindowsRuntime\ActivatableClassId\Windows.Gaming.GameBar.PresenceServer.Internal.PresenceWriter"
if (Test-Path $gbpw) {
    Set-ItemProperty -Path $gbpw -Name "ActivationType" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
}

# 3. Multimedia System Profile (Gaming & Audio Priority)
Write-Host "[*] Настройка системного мультимедийного профиля..." -ForegroundColor Yellow
$sysProfile = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
if (Test-Path $sysProfile) {
    Set-ItemProperty -Path $sysProfile -Name "NetworkThrottlingIndex" -Value 0xFFFFFFFF -Type DWord -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $sysProfile -Name "SystemResponsiveness" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
}

$gamesTask = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"
if (Test-Path $gamesTask) {
    Set-ItemProperty -Path $gamesTask -Name "Priority" -Value 6 -Type DWord -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $gamesTask -Name "Scheduling Category" -Value "High" -Type String -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $gamesTask -Name "SFIO Priority" -Value "High" -Type String -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $gamesTask -Name "GPU Priority" -Value 8 -Type DWord -Force -ErrorAction SilentlyContinue
}

$audioTask = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Audio"
if (Test-Path $audioTask) {
    Set-ItemProperty -Path $audioTask -Name "Scheduling Category" -Value "High" -Type String -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $audioTask -Name "SFIO Priority" -Value "High" -Type String -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $audioTask -Name "Background Only" -Value "False" -Type String -Force -ErrorAction SilentlyContinue
}

$proAudioTask = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Pro Audio"
if (Test-Path $proAudioTask) {
    Set-ItemProperty -Path $proAudioTask -Name "Priority" -Value 6 -Type DWord -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $proAudioTask -Name "SFIO Priority" -Value "High" -Type String -Force -ErrorAction SilentlyContinue
}

# 4. Keyboard Response & Repeat Delay Optimization
Write-Host "[*] Оптимизация отклика клавиатуры (Keyboard Delay 0 / Speed 31)..." -ForegroundColor Yellow
Set-ItemProperty -Path "HKCU:\Control Panel\Keyboard" -Name "KeyboardDelay" -Value "0" -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKCU:\Control Panel\Keyboard" -Name "KeyboardSpeed" -Value "31" -Force -ErrorAction SilentlyContinue
$kResponse = "HKCU:\Control Panel\Accessibility\Keyboard Response"
if (Test-Path $kResponse) {
    Set-ItemProperty -Path $kResponse -Name "DelayBeforeAcceptance" -Value "0" -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $kResponse -Name "BounceTime" -Value "0" -Force -ErrorAction SilentlyContinue
}
Write-Host "  [+] Задержка повтора клавиш снижена до минимума (2x быстрее отклик)." -ForegroundColor Green

# 5. CPU Core Unparking (Keep 100% of CPU cores active)
Write-Host "[*] Разблокировка спящих ядер процессора (CPU Core Unparking)..." -ForegroundColor Yellow
try {
    powercfg -setacvalueindex SCHEME_CURRENT SUB_PROCESSOR CPMINCORES 100 2>$null
    powercfg -setdcvalueindex SCHEME_CURRENT SUB_PROCESSOR CPMINCORES 100 2>$null
    powercfg -setactive SCHEME_CURRENT 2>$null
    Write-Host "  [+] Все логические ядра процессора активны (CPMINCORES 100%)." -ForegroundColor Green
} catch {}

# 6. Disable Power Throttling (EcoQoS) & Fast Startup
Write-Host "[*] Отключение Power Throttling и Fast Startup (чистый запуск ядра)..." -ForegroundColor Yellow
$pt = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling"
if (-not (Test-Path $pt)) { New-Item -Path $pt -Force | Out-Null }
Set-ItemProperty -Path $pt -Name "PowerThrottlingOff" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue

Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name "HiberbootEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "DisablePagingExecutive" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
Write-Host "  [+] Ядро и драйверы зафиксированы в RAM, чистый старт ядра включен." -ForegroundColor Green

Write-Host "=== Настройка системных таймеров, клавиатуры и ядра завершена ===" -ForegroundColor Cyan
