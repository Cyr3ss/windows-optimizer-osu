<#
.SYNOPSIS
    Оптимизация сетевых адаптеров, отключение алгоритма Нейгла и снятие лимитов QoS.
#>

if (-not $global:CountOK) { $global:CountOK = 0 }
if (-not $global:CountWarn) { $global:CountWarn = 0 }
if (-not $global:CountFail) { $global:CountFail = 0 }

function Log-OK($msg) { Write-Host "  [  OK  ] " -ForegroundColor Green -NoNewline; Write-Host $msg; $global:CountOK++ }
function Log-Warn($msg) { Write-Host "  [ WARN ] " -ForegroundColor Yellow -NoNewline; Write-Host $msg; $global:CountWarn++ }
function Log-Fail($msg) { Write-Host "  [ FAIL ] " -ForegroundColor Red -NoNewline; Write-Host $msg; $global:CountFail++ }

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "   [3/4] Оптимизация сети, пинга и TCP/IP (Nagle's Algorithm / QoS)" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

# 1. Disable Nagle's Algorithm (TCPNoDelay & TcpAckFrequency)
Write-Host "`n[*] Отключение алгоритма Нейгла на сетевых адаптерах..." -ForegroundColor White
try {
    $interfaces = Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" -ErrorAction SilentlyContinue
    if ($interfaces) {
        $count = 0
        foreach ($i in $interfaces) {
            Set-ItemProperty -Path $i.PSPath -Name "TcpAckFrequency" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $i.PSPath -Name "TCPNoDelay" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $i.PSPath -Name "TcpDelAckTicks" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            $count++
        }
        Log-OK "TCPNoDelay = 1 и TcpAckFrequency = 1 настроены для $count сетевых интерфейсов."
    } else {
        Log-Warn "Сетевые интерфейсы Tcpip не найдены в реестре (пропущено)."
    }
} catch {
    Log-Warn "Не удалось настроить интерфейсы Tcpip в HKLM: $_"
}

# 2. Disable Windows 20% QoS Reserved Bandwidth
Write-Host "[*] Разблокировка 100% пропускной способности сети (QoS NonBestEffortLimit = 0)..." -ForegroundColor White
try {
    $pschedPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Psched"
    if (-not (Test-Path $pschedPath)) { New-Item -Path $pschedPath -Force -ErrorAction SilentlyContinue | Out-Null }
    Set-ItemProperty -Path $pschedPath -Name "NonBestEffortLimit" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
    Log-OK "Резерв пропускной способности QoS отключен (100% канала разблокировано)."
} catch {
    Log-Warn "Не удалось записать параметры Psched в HKLM: $_"
}

# 3. Disable Windows Delivery Optimization P2P Seeding
Write-Host "[*] Отключение фоновой P2P-раздачи обновлений (Delivery Optimization)..." -ForegroundColor White
try {
    $doPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\DeliveryOptimization"
    if (-not (Test-Path $doPath)) { New-Item -Path $doPath -Force | Out-Null }
    Set-ItemProperty -Path $doPath -Name "DODownloadMode" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

    $doPolicy = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization"
    if (-not (Test-Path $doPolicy)) { New-Item -Path $doPolicy -Force | Out-Null }
    Set-ItemProperty -Path $doPolicy -Name "DODownloadMode" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
    Log-OK "Фоновая раздача обновлений P2P отключена (DODownloadMode = 0)."
} catch {
    Log-Fail "Ошибка при отключении Delivery Optimization: $_"
}
