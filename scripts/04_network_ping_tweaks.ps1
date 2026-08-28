<#
.SYNOPSIS
    Reduces network ping and input packet delay by disabling Nagle's Algorithm, tuning TCP ACK frequencies, unlocking 100% QoS bandwidth, and disabling Delivery Optimization P2P uploads.
#>

Write-Host "=== [4/5] Оптимизация сети, пинга и TCP/IP (Nagle's Algorithm / QoS) ===" -ForegroundColor Cyan

# 1. Disable Nagle's Algorithm (TCPNoDelay & TcpAckFrequency)
Write-Host "[*] Отключение алгоритма Нейгла на всех сетевых интерфейсах..." -ForegroundColor Yellow
$interfaces = Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" -ErrorAction SilentlyContinue

foreach ($i in $interfaces) {
    try {
        Set-ItemProperty -Path $i.PSPath -Name "TcpAckFrequency" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $i.PSPath -Name "TCPNoDelay" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $i.PSPath -Name "TcpDelAckTicks" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
    } catch {}
}
Write-Host "  [+] TCPNoDelay = 1 и TcpAckFrequency = 1 применены." -ForegroundColor Green

# 2. Disable Windows 20% QoS Reserved Bandwidth
Write-Host "[*] Разблокировка 100% пропускной способности сети (QoS NonBestEffortLimit = 0)..." -ForegroundColor Yellow
try {
    $pschedPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Psched"
    if (-not (Test-Path $pschedPath)) { New-Item -Path $pschedPath -Force -ErrorAction SilentlyContinue | Out-Null }
    Set-ItemProperty -Path $pschedPath -Name "NonBestEffortLimit" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
    Write-Host "  [+] Резерв пропускной способности QoS отключен." -ForegroundColor Green
} catch {}

# 3. Disable Windows Delivery Optimization P2P Seeding
Write-Host "[*] Отключение фоновой раздачи обновлений Windows (Delivery Optimization)..." -ForegroundColor Yellow
$doPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\DeliveryOptimization"
if (-not (Test-Path $doPath)) { New-Item -Path $doPath -Force | Out-Null }
Set-ItemProperty -Path $doPath -Name "DODownloadMode" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

$doPolicy = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization"
if (-not (Test-Path $doPolicy)) { New-Item -Path $doPolicy -Force | Out-Null }
Set-ItemProperty -Path $doPolicy -Name "DODownloadMode" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
Write-Host "  [+] DODownloadMode = 0 (P2P раздача отключена)." -ForegroundColor Green

Write-Host "=== Оптимизация сети и пинга завершена ===" -ForegroundColor Cyan
