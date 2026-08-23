<#
.SYNOPSIS
    Master runner script to apply all Windows Gaming & Tablet Latency optimizations in one click.
#>

Clear-Host
Write-Host "=================================================================" -ForegroundColor Magenta
Write-Host "   Windows Gaming & Tablet Latency Optimizer (osu! Edition)     " -ForegroundColor Magenta
Write-Host "=================================================================" -ForegroundColor Magenta
Write-Host ""

# Check Administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[!] ВНИМАНИЕ: Скрипт не запущен с правами Администратора!" -ForegroundColor Red
    Write-Host "    Пожалуйста, перезапустите PowerShell от имени Администратора." -ForegroundColor Yellow
    Write-Host ""
    Pause
    exit 1
}

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
Write-Host "   [V] Все оптимизации успешно применены!                        " -ForegroundColor Green
Write-Host "=================================================================" -ForegroundColor Green
Write-Host "Рекомендуется перезагрузить компьютер для полного вступления всех настроек в силу." -ForegroundColor Cyan
Write-Host ""
