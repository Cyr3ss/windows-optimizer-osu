<#
.SYNOPSIS
    Disables background telemetry, SysMain, heavy diagnostic scheduled tasks, enables NTFS SSD optimizations, and removes UI delays.
#>

Write-Host "=== [5/5] Деблоатинг фоновых служб, оптимизация SSD и интерфейса ===" -ForegroundColor Cyan

# 1. Disable Windows Telemetry & SysMain
Write-Host "[*] Отключение DiagTrack и SysMain..." -ForegroundColor Yellow
Stop-Service -Name "DiagTrack" -Force -ErrorAction SilentlyContinue
Set-Service -Name "DiagTrack" -StartupType Disabled -ErrorAction SilentlyContinue

Stop-Service -Name "SysMain" -Force -ErrorAction SilentlyContinue
Set-Service -Name "SysMain" -StartupType Disabled -ErrorAction SilentlyContinue

# 2. Set OEM / Secondary services to Manual (including Wallpaper Engine, HP, AnyDesk, WerSvc)
$manualServices = @(
    "Wallpaper Engine Service",
    "HPAppHelperCap",
    "HPDiagsCap",
    "HPNetworkCap",
    "HPSysInfoCap",
    "AnyDesk",
    "WerSvc"
)
foreach ($s in $manualServices) {
    Stop-Service -Name $s -Force -ErrorAction SilentlyContinue
    Set-Service -Name $s -StartupType Manual -ErrorAction SilentlyContinue
}
Write-Host "  [+] Фоновые OEM, Wallpaper Engine и служебные процессы переведены в ручной режим." -ForegroundColor Green

# 3. Disable Heavy Scheduled Tasks
Write-Host "[*] Отключение фоновых задач телеметрии и сканирования..." -ForegroundColor Yellow
$tasksToDisable = @(
    "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser",
    "\Microsoft\Windows\Application Experience\ProgramDataUpdater",
    "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator",
    "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip",
    "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector",
    "\Microsoft\Windows\Power Efficiency Diagnostics\AnalyzeSystem",
    "\Microsoft\Windows\Windows Error Reporting\QueueReporting"
)

foreach ($t in $tasksToDisable) {
    try {
        Disable-ScheduledTask -TaskName $t.Split('\')[-1] -TaskPath ($t.Substring(0, $t.LastIndexOf('\')+1)) -ErrorAction SilentlyContinue | Out-Null
    } catch {}
}
Write-Host "  [+] Фоновые планировщики телеметрии отключены." -ForegroundColor Green

# 4. NTFS SSD Optimization (Disable Last Access Timestamps)
Write-Host "[*] Оптимизация файловой системы SSD (NTFS)..." -ForegroundColor Yellow
try {
    fsutil behavior set disablelastaccess 1 2>$null | Out-Null
    Write-Host "  [+] Отключена перезапись времени последнего доступа при чтении." -ForegroundColor Green
} catch {}

# 5. UI Responsiveness Tweaks
Write-Host "[*] Устранение задержек интерфейса Windows..." -ForegroundColor Yellow
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -Value "0" -Force -ErrorAction SilentlyContinue
$wm = "HKCU:\Control Panel\Desktop\WindowMetrics"
if (-not (Test-Path $wm)) { New-Item -Path $wm -Force | Out-Null }
Set-ItemProperty -Path $wm -Name "MinAnimate" -Value "0" -Force -ErrorAction SilentlyContinue
Write-Host "  [+] Задержка меню установлена в 0 мс, анимация окон оптимизирована." -ForegroundColor Green

Write-Host "=== Деблоатинг и оптимизация служб завершены ===" -ForegroundColor Cyan
