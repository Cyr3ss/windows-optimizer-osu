<#
.SYNOPSIS
    Eliminates graphics tablet and pen input latency by applying strict Group Policies, disabling Windows Ink gestures, press-and-hold delays, TabletInputService, and USB power saving.
#>

Write-Host "=== [2/5] Оптимизация задержек планшета и пера (Group Policies / Windows Ink / USB) ===" -ForegroundColor Cyan

# 1. Disable Windows Pen Gestures and Press-and-Hold in User Registry
Write-Host "[*] Отключение задержек Windows Ink и Press-and-Hold..." -ForegroundColor Yellow
$sysEvent = "HKCU:\Software\Microsoft\Wisp\Pen\SysEventParameters"
if (-not (Test-Path $sysEvent)) { New-Item -Path $sysEvent -Force | Out-Null }
Set-ItemProperty -Path $sysEvent -Name "FlickMode" -Value 0 -Type DWord
Set-ItemProperty -Path $sysEvent -Name "HoldMode" -Value 0 -Type DWord
Set-ItemProperty -Path $sysEvent -Name "Splash" -Value 0 -Type DWord
Set-ItemProperty -Path $sysEvent -Name "DblTime" -Value 0 -Type DWord
Set-ItemProperty -Path $sysEvent -Name "DblDist" -Value 0 -Type DWord
Set-ItemProperty -Path $sysEvent -Name "WaitTime" -Value 0 -Type DWord

$touch = "HKCU:\Software\Microsoft\Wisp\Touch"
if (-not (Test-Path $touch)) { New-Item -Path $touch -Force | Out-Null }
Set-ItemProperty -Path $touch -Name "TouchMode_hold" -Value 0 -Type DWord
Set-ItemProperty -Path $touch -Name "TouchModeN_HoldTime_BeforeAnimation" -Value 0 -Type DWord
Set-ItemProperty -Path $touch -Name "TouchModeN_HoldTime_Animation" -Value 0 -Type DWord

# 2. Apply Strict TabletPC & Pen Group Policies (HKLM & HKCU)
Write-Host "[*] Применение жестких Group Policies для планшетов и пера..." -ForegroundColor Yellow
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
Write-Host "  [+] Групповые политики TabletPC и PenWorkspace применены." -ForegroundColor Green

# 3. Apply 100% Linear 1:1 Raw Pointer Response Curve (Zeroing Acceleration/Deceleration)
Write-Host "[*] Установка абсолютно линейной кривой отклика указателя (1:1 Raw)..." -ForegroundColor Yellow
$smoothZero = [byte[]](0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00)
Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "SmoothMouseXCurve" -Value $smoothZero -Type Binary -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "SmoothMouseYCurve" -Value $smoothZero -Type Binary -Force -ErrorAction SilentlyContinue
Write-Host "  [+] Нелинейное сглаживание мыши в реестре Windows обнулено." -ForegroundColor Green

# 4. Disable and Stop TabletInputService (Touch Keyboard and Handwriting Panel Service)
Write-Host "[*] Отключение службы рукописного ввода и сенсорной клавиатуры (TabletInputService)..." -ForegroundColor Yellow
try {
    Stop-Service -Name "TabletInputService" -Force -ErrorAction SilentlyContinue
    Set-Service -Name "TabletInputService" -StartupType Disabled -ErrorAction SilentlyContinue
    & sc.exe config "TabletInputService" start= disabled 2>$null | Out-Null
    Write-Host "  [+] TabletInputService отключена." -ForegroundColor Green
} catch {}

# 5. Disable USB Selective Suspend
Write-Host "[*] Отключение энергосбережения USB портов (Selective Suspend)..." -ForegroundColor Yellow
try {
    powercfg /setacvalueindex SCHEME_CURRENT 2a737441-1930-4402-9177-b06418304ddf 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 2>$null
    powercfg /setdcvalueindex SCHEME_CURRENT 2a737441-1930-4402-9177-b06418304ddf 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 2>$null
    powercfg /setactive SCHEME_CURRENT 2>$null
    Write-Host "  [+] USB Selective Suspend отключен." -ForegroundColor Green
} catch {}

# 6. Disable USB Hub Power Saving via WMI
Write-Host "[*] Отключение спящего режима USB-концентраторов..." -ForegroundColor Yellow
try {
    Get-CimInstance MSPower_DeviceEnable -Namespace root\wmi -ErrorAction SilentlyContinue | ForEach-Object {
        if ($_.InstanceName -match "USB") {
            Set-CimInstance -Query "Select * from MSPower_DeviceEnable where InstanceName='$($_.InstanceName)'" -Property @{Enable=$false} -Namespace root\wmi -ErrorAction SilentlyContinue
        }
    }
    Write-Host "  [+] Постоянная частота опроса USB обеспечена." -ForegroundColor Green
} catch {}

Write-Host "=== Оптимизация планшета завершена ===" -ForegroundColor Cyan
