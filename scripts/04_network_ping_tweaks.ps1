<#
.SYNOPSIS
    Optimizes network connection latency and ping: disables Nagle's Algorithm (TCPNoDelay) and disables Windows Delivery Optimization P2P upload.
#>

Write-Host "=== [4/5] Оптимизация сети, пинга и TCP-стека ===" -ForegroundColor Cyan

# 1. Disable Nagle's Algorithm on all Network Interfaces
Write-Host "[*] Отключение алгоритма буферизации пакетов (Nagle's Algorithm)..." -ForegroundColor Yellow
$tcpPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces"
if (Test-Path $tcpPath) {
    Get-ChildItem -Path $tcpPath | ForEach-Object {
        $p = $_.PSPath
        Set-ItemProperty -Path $p -Name "TcpAckFrequency" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $p -Name "TCPNoDelay" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $p -Name "TcpDelAckTicks" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
    }
    Write-Host "  [+] TCPNoDelay и TcpAckFrequency активированы." -ForegroundColor Green
}

# 2. Disable Delivery Optimization P2P upload in background
Write-Host "[*] Отключение фоновой P2P-раздачи обновлений Windows..." -ForegroundColor Yellow
$doPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization"
if (-not (Test-Path $doPath)) { New-Item -Path $doPath -Force | Out-Null }
Set-ItemProperty -Path $doPath -Name "DODownloadMode" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
Write-Host "  [+] Фоновая отдача обновлений отключена." -ForegroundColor Green

Write-Host "=== Оптимизация сети завершена ===" -ForegroundColor Cyan
