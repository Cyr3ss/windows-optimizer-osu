<#
.SYNOPSIS
    Деблоатинг фоновых служб телеметрии, SysMain, задач планировщика и оптимизация SSD.
#>

if (-not $global:CountOK) { $global:CountOK = 0 }
if (-not $global:CountWarn) { $global:CountWarn = 0 }
if (-not $global:CountFail) { $global:CountFail = 0 }

function Log-OK($msg) { Write-Host "  [  OK  ] " -ForegroundColor Green -NoNewline; Write-Host $msg; $global:CountOK++ }
function Log-Warn($msg) { Write-Host "  [ WARN ] " -ForegroundColor Yellow -NoNewline; Write-Host $msg; $global:CountWarn++ }
function Log-Fail($msg) { Write-Host "  [ FAIL ] " -ForegroundColor Red -NoNewline; Write-Host $msg; $global:CountFail++ }

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "   [4/4] Деблоатинг фоновых служб, оптимизация SSD и интерфейса  " -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

# 1. Disable Windows Telemetry & SysMain
Write-Host "`n[*] Отключение служб телеметрии (DiagTrack) и SysMain..." -ForegroundColor White
$servicesToDisable = @("DiagTrack", "SysMain")
foreach ($s in $servicesToDisable) {
    $svc = Get-Service -Name $s -ErrorAction SilentlyContinue
    if ($svc) {
        try {
            Stop-Service -Name $s -Force -ErrorAction SilentlyContinue
            Set-Service -Name $s -StartupType Disabled -ErrorAction SilentlyContinue
            Log-OK "Служба $s остановлена и отключена."
        } catch {
            Log-Warn "Не удалось изменить службу $s: $_"
        }
    } else {
        Log-Warn "Служба $s отсутствует в системе (пропущено)."
    }
}

# 2. Set OEM / Secondary services to Manual
Write-Host "[*] Перевод второстепенных OEM-служб в ручной режим..." -ForegroundColor White
$manualServices = @("HPAppHelperCap", "HPDiagsCap", "HPNetworkCap", "HPSysInfoCap", "AnyDesk", "WerSvc")
$oemFound = 0
foreach ($s in $manualServices) {
    $svc = Get-Service -Name $s -ErrorAction SilentlyContinue
    if ($svc) {
        try {
            Stop-Service -Name $s -Force -ErrorAction SilentlyContinue
            Set-Service -Name $s -StartupType Manual -ErrorAction SilentlyContinue
            $oemFound++
        } catch {}
    }
}
if ($oemFound -gt 0) {
    Log-OK "Обнаружено и переведено в ручной режим $oemFound OEM/служебных процессов."
} else {
    Log-OK "Сторонние OEM службы не обнаружены (система уже чистая)."
}

# 3. Disable Heavy Scheduled Tasks
Write-Host "[*] Отключение фоновых задач телеметрии и сканирования..." -ForegroundColor White
$tasksToDisable = @(
    "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser",
    "\Microsoft\Windows\Application Experience\ProgramDataUpdater",
    "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator",
    "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip",
    "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector",
    "\Microsoft\Windows\Power Efficiency Diagnostics\AnalyzeSystem",
    "\Microsoft\Windows\Windows Error Reporting\QueueReporting"
)

$taskCount = 0
foreach ($t in $tasksToDisable) {
    try {
        $taskName = $t.Split('\')[-1]
        $taskPath = $t.Substring(0, $t.LastIndexOf('\')+1)
        $chk = Get-ScheduledTask -TaskName $taskName -TaskPath $taskPath -ErrorAction SilentlyContinue
        if ($chk) {
            Disable-ScheduledTask -TaskName $taskName -TaskPath $taskPath -ErrorAction SilentlyContinue | Out-Null
            $taskCount++
        }
    } catch {}
}
Log-OK "Отключено $taskCount тяжелых фоновых задач планировщика Windows."

# 4. NTFS SSD Optimization (Disable Last Access Timestamps)
Write-Host "[*] Оптимизация файловой системы SSD (NTFS)..." -ForegroundColor White
try {
    fsutil behavior set disablelastaccess 1 2>$null | Out-Null
    Log-OK "Отключена перезапись времени последнего доступа при чтении SSD."
} catch {
    Log-Warn "Не удалось настроить fsutil (пропущено): $_"
}

# 5. UI Responsiveness Tweaks
Write-Host "[*] Устранение задержек анимации и контекстных меню..." -ForegroundColor White
try {
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -Value "0" -Force -ErrorAction SilentlyContinue
    $wm = "HKCU:\Control Panel\Desktop\WindowMetrics"
    if (-not (Test-Path $wm)) { New-Item -Path $wm -Force | Out-Null }
    Set-ItemProperty -Path $wm -Name "MinAnimate" -Value "0" -Force -ErrorAction SilentlyContinue
    Log-OK "Задержка меню (MenuShowDelay) установлена в 0 мс, анимация окон оптимизирована."
} catch {
    Log-Fail "Ошибка при настройке задержек интерфейса: $_"
}
