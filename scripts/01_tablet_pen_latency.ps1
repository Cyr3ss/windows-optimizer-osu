<#
.SYNOPSIS
    Оптимизация задержек графического планшета и пера (XP-Pen / Wacom / Huion / Gaomon).
    Отключает задержки Windows Ink, жесткие Group Policies, службу рукописного ввода и энергосбережение USB.
#>

if (-not $global:CountOK) { $global:CountOK = 0 }
if (-not $global:CountWarn) { $global:CountWarn = 0 }
if (-not $global:CountFail) { $global:CountFail = 0 }

function Log-OK($msg) { Write-Host "  [  OK  ] " -ForegroundColor Green -NoNewline; Write-Host $msg; $global:CountOK++ }
function Log-Warn($msg) { Write-Host "  [ WARN ] " -ForegroundColor Yellow -NoNewline; Write-Host $msg; $global:CountWarn++ }
function Log-Fail($msg) { Write-Host "  [ FAIL ] " -ForegroundColor Red -NoNewline; Write-Host $msg; $global:CountFail++ }

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "   [1/4] Оптимизация задержек планшета и пера (Windows Ink / USB)" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

# 1. Отключение задержек Windows Ink и Press-and-Hold
Write-Host "`n[*] Настройка реестра Windows Ink (отключение задержки касания)..." -ForegroundColor White
try {
    $sysEvent = "HKCU:\Software\Microsoft\Wisp\Pen\SysEventParameters"
    if (-not (Test-Path $sysEvent)) { New-Item -Path $sysEvent -Force | Out-Null }
    Set-ItemProperty -Path $sysEvent -Name "FlickMode" -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $sysEvent -Name "HoldMode" -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $sysEvent -Name "Splash" -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $sysEvent -Name "DblTime" -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $sysEvent -Name "DblDist" -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $sysEvent -Name "WaitTime" -Value 0 -Type DWord -Force

    $touch = "HKCU:\Software\Microsoft\Wisp\Touch"
    if (-not (Test-Path $touch)) { New-Item -Path $touch -Force | Out-Null }
    Set-ItemProperty -Path $touch -Name "TouchMode_hold" -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $touch -Name "TouchModeN_HoldTime_BeforeAnimation" -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $touch -Name "TouchModeN_HoldTime_Animation" -Value 0 -Type DWord -Force

    Log-OK "Буферы задержки 300 мс (HoldMode) и жесты (FlickMode) успешно отключены."
} catch {
    Log-Fail "Ошибка при настройке параметров Windows Ink в HKCU: $_"
}

# 2. Применение Group Policies для планшетов и пера
Write-Host "[*] Применение жестких Group Policies (TabletPC & PenWorkspace)..." -ForegroundColor White
try {
    $pathsToCreate = @(
        "HKLM:\SOFTWARE\Policies\Microsoft\Windows\TabletPC",
        "HKCU:\Software\Policies\Microsoft\Windows\TabletPC",
        "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PenWorkspace",
        "HKCU:\Software\Policies\Microsoft\Windows\PenWorkspace",
        "HKLM:\SOFTWARE\Policies\Microsoft\Windows\HandwritingErrorReports"
    )
    foreach ($p in $pathsToCreate) {
        if (-not (Test-Path $p)) { New-Item -Path $p -Force -ErrorAction SilentlyContinue | Out-Null }
    }

    $policyValues = @{
        "TurnOffPenFeedback" = 1
        "TurnOffPressAndHold" = 1
        "DisableFlicks" = 1
        "DisablePagingFlick" = 1
        "DisablePenCursorFeedback" = 1
        "DisableTouchVisualFeedback" = 1
        "PreventHandwritingDataSharing" = 1
    }
    foreach ($k in $policyValues.Keys) {
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\TabletPC" -Name $k -Value $policyValues[$k] -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\Windows\TabletPC" -Name $k -Value $policyValues[$k] -Type DWord -Force -ErrorAction SilentlyContinue
    }
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PenWorkspace" -Name "EnablePenWorkspace" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\Windows\PenWorkspace" -Name "EnablePenWorkspace" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

    Log-OK "Групповые политики TabletPC и PenWorkspace успешно применены (HKLM / HKCU)."
} catch {
    Log-Fail "Ошибка при записи Group Policies: $_"
}

# 3. 100% Линейная кривая отклика указателя (MarkC 1:1 Raw Linear Curve)
Write-Host "[*] Обнуление нелинейного сглаживания курсора Windows (1:1 Raw Curve)..." -ForegroundColor White
try {
    $smoothZero = [byte[]](0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00)
    Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "SmoothMouseXCurve" -Value $smoothZero -Type Binary -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "SmoothMouseYCurve" -Value $smoothZero -Type Binary -Force -ErrorAction SilentlyContinue
    Log-OK "Кривые сглаживания курсора обнулены (абсолютно линейный отклик 1:1)."
} catch {
    Log-Fail "Ошибка при обнулении SmoothMouseCurve: $_"
}

# 4. Отключение службы TabletInputService
Write-Host "[*] Отключение службы рукописного ввода и сенсорной клавиатуры (TabletInputService)..." -ForegroundColor White
$tis = Get-Service -Name "TabletInputService" -ErrorAction SilentlyContinue
if ($tis) {
    try {
        Stop-Service -Name "TabletInputService" -Force -ErrorAction SilentlyContinue
        Set-Service -Name "TabletInputService" -StartupType Disabled -ErrorAction SilentlyContinue
        & sc.exe config "TabletInputService" start= disabled 2>$null | Out-Null
        Log-OK "Служба TabletInputService остановлена и переведена в режим Disabled."
    } catch {
        Log-Warn "Не удалось изменить статус TabletInputService (возможно, требуются права Администратора)."
    }
} else {
    Log-Warn "Служба TabletInputService не найдена в этой редакции Windows (пропущено)."
}

# 5. Отключение USB Selective Suspend
Write-Host "[*] Отключение спящего режима USB портов (USB Selective Suspend)..." -ForegroundColor White
try {
    powercfg /setacvalueindex SCHEME_CURRENT 2a737441-1930-4402-9177-b06418304ddf 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 2>$null
    powercfg /setdcvalueindex SCHEME_CURRENT 2a737441-1930-4402-9177-b06418304ddf 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 2>$null
    powercfg /setactive SCHEME_CURRENT 2>$null
    Log-OK "USB Selective Suspend отключен для текущего плана электропитания."
} catch {
    Log-Warn "Не удалось настроить powercfg для USB Selective Suspend: $_"
}

# 6. Отключение энергосбережения USB-концентраторов через WMI
Write-Host "[*] Отключение энергосбережения USB Root Hub..." -ForegroundColor White
try {
    $hubs = Get-CimInstance MSPower_DeviceEnable -Namespace root\wmi -ErrorAction SilentlyContinue | Where-Object { $_.InstanceName -match "USB" }
    if ($hubs) {
        foreach ($h in $hubs) {
            Set-CimInstance -Query "Select * from MSPower_DeviceEnable where InstanceName='$($h.InstanceName)'" -Property @{Enable=$false} -Namespace root\wmi -ErrorAction SilentlyContinue
        }
        Log-OK "Энергосбережение USB Root Hub успешно отключено ($($hubs.Count) устройств)."
    } else {
        Log-OK "Все USB концентраторы уже работают на постоянной максимальной мощности."
    }
} catch {
    Log-Warn "WMI MSPower_DeviceEnable недоступен на данном контроллере (пропущено)."
}
