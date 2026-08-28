<#
.SYNOPSIS
    Универсальный мастер-скрипт применения всех оптимизаций Windows & графического планшета в 1 клик.
    Выводит наглядный статус каждого действия: [  OK  ], [ WARN ], [ FAIL ] и итоговую сводку.
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

$global:CountOK = 0
$global:CountWarn = 0
$global:CountFail = 0

$scriptDir = $PSScriptRoot
if (-not $scriptDir) { $scriptDir = "." }

$scripts = @(
    "$scriptDir\scripts\01_tablet_pen_latency.ps1",
    "$scriptDir\scripts\02_gaming_system_latency.ps1",
    "$scriptDir\scripts\03_network_ping_tweaks.ps1",
    "$scriptDir\scripts\04_debloat_services_tasks.ps1"
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
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "                     ИТОГОВЫЙ ОТЧЕТ ВЫПОЛНЕНИЯ                   " -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "  [  OK  ] Успешно примененных твиков:        $global:CountOK" -ForegroundColor Green
Write-Host "  [ WARN ] Предупреждений / Пропущено:        $global:CountWarn" -ForegroundColor Yellow
Write-Host "  [ FAIL ] Ошибок выполнения:                 $global:CountFail" -ForegroundColor $(if ($global:CountFail -gt 0) { "Red" } else { "Gray" })
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host ""

if ($global:CountFail -eq 0) {
    Write-Host "[V] Все модули успешно отработали!" -ForegroundColor Green
} else {
    Write-Host "[!] Некоторые параметры завершились с ошибкой (см. лог выше)." -ForegroundColor Yellow
}

Write-Host "Рекомендуется перезагрузить компьютер для применения параметров ядра и BCD." -ForegroundColor Cyan
Write-Host ""
Write-Host "Нажмите любую клавишу для завершения..."
[void][System.Console]::ReadKey($true)
