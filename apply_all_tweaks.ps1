<#
.SYNOPSIS
    Универсальный мастер-скрипт применения всех оптимизаций Windows & графического планшета в 1 клик.
    Автоматически запрашивает права Администратора при запуске на любом компьютере.
#>

# Автоматический перезапуск с правами Администратора при необходимости
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[*] Запрос прав Администратора (UAC)..." -ForegroundColor Yellow
    try {
        Start-Process powershell.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"") -Verb RunAs
        exit
    } catch {
        Write-Host "[!] Не удалось автоматически повысить права. Пожалуйста, запустите PowerShell от имени Администратора." -ForegroundColor Red
        Pause
        exit 1
    }
}

Clear-Host
Write-Host "=================================================================" -ForegroundColor Magenta
Write-Host "   Windows Gaming & Tablet Latency Optimizer (Universal Edition) " -ForegroundColor Magenta
Write-Host "=================================================================" -ForegroundColor Magenta
Write-Host ""

$scriptDir = $PSScriptRoot
if (-not $scriptDir) { $scriptDir = "." }

$scripts = @(
    "$scriptDir\scripts\02_tablet_pen_latency.ps1",
    "$scriptDir\scripts\03_gaming_system_latency.ps1",
    "$scriptDir\scripts\04_network_ping_tweaks.ps1",
    "$scriptDir\scripts\05_debloat_services_tasks.ps1"
)

foreach ($s in $scripts) {
    if (Test-Path $s) {
        Write-Host ""
        & $s
    } else {
        Write-Warning "Скрипт не найден: $s"
    }
}

Write-Host ""
Write-Host "=================================================================" -ForegroundColor Green
Write-Host "   [V] Все оптимизации успешно применены ко всей системе!         " -ForegroundColor Green
Write-Host "=================================================================" -ForegroundColor Green
Write-Host "Рекомендуется перезагрузить компьютер для применения параметров BCD и ядра." -ForegroundColor Cyan
Write-Host ""
Write-Host "Нажмите любую клавишу для выхода..."
[void][System.Console]::ReadKey($true)
