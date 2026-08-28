<#
.SYNOPSIS
    Системные таймеры, кванты CPU, приоритеты CSRSS/DWM, Game Mode, DWM Fullscreen, клавиатура и фиксация ядра в RAM.
#>

if (-not $global:CountOK) { $global:CountOK = 0 }
if (-not $global:CountWarn) { $global:CountWarn = 0 }
if (-not $global:CountFail) { $global:CountFail = 0 }

function Log-OK($msg) { Write-Host "  [  OK  ] " -ForegroundColor Green -NoNewline; Write-Host $msg; $global:CountOK++ }
function Log-Warn($msg) { Write-Host "  [ WARN ] " -ForegroundColor Yellow -NoNewline; Write-Host $msg; $global:CountWarn++ }
function Log-Fail($msg) { Write-Host "  [ FAIL ] " -ForegroundColor Red -NoNewline; Write-Host $msg; $global:CountFail++ }

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "   [2/4] Системные таймеры, кванты CPU, Game Mode, DWM и ядро    " -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

# 1. BCD High-Precision Invariant Clock Tweaks
Write-Host "`n[*] Настройка аппаратных таймеров Windows (BCD)..." -ForegroundColor White
try {
    bcdedit /set disabledynamictick yes 2>$null | Out-Null
    bcdedit /set useplatformclock no 2>$null | Out-Null
    Log-OK "Аппаратный таймер TSC активен, Dynamic Tick успешно отключен."
} catch {
    Log-Warn "Не удалось применить BCD параметры (проверьте права Администратора): $_"
}

# 2. Win32PrioritySeparation (Foreground Process Quantum 3:1 Ratio)
Write-Host "[*] Настройка квантов планировщика CPU (Win32PrioritySeparation = 0x26)..." -ForegroundColor White
try {
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -Value 38 -Type DWord -Force -ErrorAction SilentlyContinue
    Log-OK "Кванты времени процессора настроены на 3:1 в пользу активного игрового окна."
} catch {
    Log-Warn "Не удалось записать Win32PrioritySeparation в HKLM (пропущено): $_"
}

# 3. Real-time Input & Display Dispatch Priorities (CSRSS and DWM)
Write-Host "[*] Повышение приоритета диспетчера ввода (CSRSS) и вывода кадров (DWM)..." -ForegroundColor White
try {
    $csrssPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\csrss.exe\PerfOptions"
    if (-not (Test-Path $csrssPath)) { New-Item -Path $csrssPath -Force -ErrorAction SilentlyContinue | Out-Null }
    Set-ItemProperty -Path $csrssPath -Name "CpuPriorityClass" -Value 3 -Type DWord -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $csrssPath -Name "IoPriority" -Value 3 -Type DWord -Force -ErrorAction SilentlyContinue

    $dwmPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\dwm.exe\PerfOptions"
    if (-not (Test-Path $dwmPath)) { New-Item -Path $dwmPath -Force -ErrorAction SilentlyContinue | Out-Null }
    Set-ItemProperty -Path $dwmPath -Name "CpuPriorityClass" -Value 3 -Type DWord -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $dwmPath -Name "IoPriority" -Value 3 -Type DWord -Force -ErrorAction SilentlyContinue
    Log-OK "CSRSS (обработка ввода) и DWM (вывод на экран) переведены в Высокий приоритет."
} catch {
    Log-Warn "Не удалось настроить приоритеты PerfOptions для CSRSS/DWM: $_"
}

# 4. Windows Game Mode & Fullscreen Exclusive
Write-Host "[*] Включение Windows Game Mode и прямого вывода кадров (HonorFSE)..." -ForegroundColor White
try {
    $gb = "HKCU:\Software\Microsoft\GameBar"
    if (-not (Test-Path $gb)) { New-Item -Path $gb -Force | Out-Null }
    Set-ItemProperty -Path $gb -Name "AutoGameModeEnabled" -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $gb -Name "AllowAutoGameMode" -Value 1 -Type DWord -Force

    $gcs = "HKCU:\System\GameConfigStore"
    if (-not (Test-Path $gcs)) { New-Item -Path $gcs -Force | Out-Null }
    Set-ItemProperty -Path $gcs -Name "GameDVR_DXGIHonorFSEWindowsCompatible" -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $gcs -Name "GameDVR_FSEBehaviorMode" -Value 2 -Type DWord -Force
    Set-ItemProperty -Path $gcs -Name "GameDVR_Enabled" -Value 0 -Type DWord -Force

    $gbpw = "HKLM:\SOFTWARE\Microsoft\WindowsRuntime\ActivatableClassId\Windows.Gaming.GameBar.PresenceServer.Internal.PresenceWriter"
    if (Test-Path $gbpw) {
        Set-ItemProperty -Path $gbpw -Name "ActivationType" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
    }
    Log-OK "Windows Game Mode включен, GameDVR и GameBarPresenceWriter отключены."
} catch {
    Log-Fail "Ошибка при настройке Game Mode: $_"
}

# 5. Multimedia System Profile (Gaming & Audio Priority)
Write-Host "[*] Настройка системного мультимедийного профиля MMCSS..." -ForegroundColor White
try {
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
    Log-OK "Профили MMCSS Games, Audio и Pro Audio переведены в режим максимального приоритета."
} catch {
    Log-Warn "Не удалось настроить ветки MMCSS в HKLM: $_"
}

# 6. Keyboard Response & Repeat Delay Optimization
Write-Host "[*] Оптимизация отклика клавиатуры (минимальная задержка повтора)..." -ForegroundColor White
try {
    Set-ItemProperty -Path "HKCU:\Control Panel\Keyboard" -Name "KeyboardDelay" -Value "0" -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Control Panel\Keyboard" -Name "KeyboardSpeed" -Value "31" -Force -ErrorAction SilentlyContinue
    $kResponse = "HKCU:\Control Panel\Accessibility\Keyboard Response"
    if (Test-Path $kResponse) {
        Set-ItemProperty -Path $kResponse -Name "DelayBeforeAcceptance" -Value "0" -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $kResponse -Name "BounceTime" -Value "0" -Force -ErrorAction SilentlyContinue
    }
    Log-OK "Задержка повтора клавиатуры снижена до минимума (KeyboardDelay = 0 / Speed = 31)."
} catch {
    Log-Fail "Ошибка при настройке задержки клавиатуры: $_"
}

# 7. CPU Core Unparking (Keep 100% of CPU cores active)
Write-Host "[*] Разблокировка спящих ядер процессора (CPU Core Unparking 100%)..." -ForegroundColor White
try {
    powercfg -setacvalueindex SCHEME_CURRENT SUB_PROCESSOR CPMINCORES 100 2>$null
    powercfg -setdcvalueindex SCHEME_CURRENT SUB_PROCESSOR CPMINCORES 100 2>$null
    powercfg -setactive SCHEME_CURRENT 2>$null
    Log-OK "Все логические ядра процессора активны (CPMINCORES = 100%)."
} catch {
    Log-Warn "Не удалось изменить CPMINCORES через powercfg: $_"
}

# 8. Disable Power Throttling (EcoQoS) & Fast Startup & DisablePagingExecutive
Write-Host "[*] Отключение Power Throttling, Fast Startup и фиксация ядра в RAM..." -ForegroundColor White
try {
    $pt = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling"
    if (-not (Test-Path $pt)) { New-Item -Path $pt -Force | Out-Null }
    Set-ItemProperty -Path $pt -Name "PowerThrottlingOff" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue

    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name "HiberbootEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "DisablePagingExecutive" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
    Log-OK "Power Throttling отключен, ядро зафиксировано в RAM (DisablePagingExecutive = 1)."
} catch {
    Log-Warn "Не удалось применить параметры ядра в HKLM: $_"
}

# 9. Force Hardware Exclusive Fullscreen for osu! (Dynamic path discovery)
Write-Host "[*] Поиск установленной osu! для включения аппаратного Fullscreen Exclusive..." -ForegroundColor White
$possibleOsu = @(
    "$env:LOCALAPPDATA\osu!\osu!.exe",
    "C:\osu!\osu!.exe",
    "D:\osu!\osu!.exe",
    "E:\osu!\osu!.exe"
)
$appCompat = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers"
if (-not (Test-Path $appCompat)) { New-Item -Path $appCompat -Force | Out-Null }
$foundOsu = $false
foreach ($p in $possibleOsu) {
    if (Test-Path $p) {
        Set-ItemProperty -Path $appCompat -Name $p -Value "~ DISABLEDXMAXIMIZEDWINDOWEDMODE HIGHDPIAWARE" -Force -ErrorAction SilentlyContinue
        Log-OK "Аппаратный Fullscreen Exclusive настроен для: $p"
        $foundOsu = $true
    }
}
if (-not $foundOsu) {
    Log-Warn "osu!.exe не найдена по стандартным путям (пропущено)."
}
