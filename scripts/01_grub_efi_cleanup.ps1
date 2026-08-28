<#
.SYNOPSIS
    Универсальный скрипт очистки остатков Linux/GRUB/systemd bootloader из раздела EFI и удаления старых записей UEFI NVRAM.
#>

# Проверка прав Администратора
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Этот скрипт должен быть запущен от имени Администратора!"
    exit 1
}

Write-Host "=== [1/5] Очистка GRUB / Linux из EFI и NVRAM ===" -ForegroundColor Cyan

# 1. Поиск свободной буквы диска для монтирования EFI
$freeDrive = (Get-ChildItem function:[d-z]: -Name | Where-Object { -not (Test-Path $_) } | Select-Object -First 1)
if (-not $freeDrive) { $freeDrive = "S:" }
Write-Host "[*] Монтирование системного раздела EFI на $freeDrive..." -ForegroundColor Yellow

try {
    mountvol $freeDrive /s
} catch {}

if (-not (Test-Path "$freeDrive\EFI")) {
    Write-Warning "Раздел EFI не обнаружен или система работает в режиме Legacy BIOS (MBR). Очистка EFI пропущена."
    return
}

# 2. Удаление остаточных папок Linux / GRUB и ядер
$linuxItems = @(
    "$freeDrive\grub",
    "$freeDrive\loader",
    "$freeDrive\EFI\systemd",
    "$freeDrive\EFI\Linux",
    "$freeDrive\EFI\refind",
    "$freeDrive\EFI\ubuntu",
    "$freeDrive\EFI\debian",
    "$freeDrive\EFI\arch",
    "$freeDrive\EFI\fedora",
    "$freeDrive\EFI\kali",
    "$freeDrive\EFI\manjaro",
    "$freeDrive\intel-ucode.img",
    "$freeDrive\amd-ucode.img",
    "$freeDrive\vmlinuz-linux",
    "$freeDrive\initramfs-linux.img",
    "$freeDrive\initramfs-linux-fallback.img"
)

foreach ($item in $linuxItems) {
    if (Test-Path $item) {
        Remove-Item -Path $item -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "  [-] Удалено: $item" -ForegroundColor Green
    }
}

# Удаление папок ядер systemd-boot по GUID
Get-ChildItem -Path "$freeDrive\" -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -match "^[0-9a-f]{32}$" } | ForEach-Object {
    Remove-Item -Path $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  [-] Удалена папка ядер systemd-boot: $($_.Name)" -ForegroundColor Green
}

# 3. Синхронизация fallback-загрузчика BOOTX64.EFI с оригинальным Windows bootmgfw.efi
if (Test-Path "$freeDrive\EFI\Microsoft\Boot\bootmgfw.efi") {
    if (-not (Test-Path "$freeDrive\EFI\BOOT")) { New-Item -Path "$freeDrive\EFI\BOOT" -ItemType Directory -Force | Out-Null }
    Copy-Item -Path "$freeDrive\EFI\Microsoft\Boot\bootmgfw.efi" -Destination "$freeDrive\EFI\BOOT\BOOTX64.EFI" -Force
    Write-Host "  [+] Fallback-загрузчик BOOTX64.EFI синхронизирован с Windows bootmgfw.efi" -ForegroundColor Green
}

# 4. Отмонтирование раздела EFI
mountvol $freeDrive /d
Write-Host "  [+] Раздел EFI отмонтирован." -ForegroundColor Green

# 5. Очистка записей UEFI NVRAM
Write-Host "[*] Проверка и очистка записей UEFI NVRAM..." -ForegroundColor Yellow
try {
    $firmware = bcdedit /enum firmware
    $lines = $firmware -split "`r`n"

    $currentId = $null
    $currentDesc = $null
    $entriesToDelete = @()

    foreach ($line in $lines) {
        if ($line -match "^identifier\s+(\{[^}]+\})") {
            $currentId = $matches[1]
            $currentDesc = $null
        }
        if ($line -match "^description\s+(.+)$") {
            $currentDesc = $matches[1]
            if ($currentDesc -match "Linux|ubuntu|debian|fedora|arch|kali|manjaro|systemd-boot|grub" -and $currentId -ne "{bootmgr}") {
                $entriesToDelete += [PSCustomObject]@{
                    Id = $currentId
                    Desc = $currentDesc
                }
            }
        }
    }

    foreach ($e in $entriesToDelete) {
        Write-Host "  [-] Удаление записи UEFI: $($e.Desc) ($($e.Id))..." -ForegroundColor Red
        bcdedit /delete "$($e.Id)" 2>$null | Out-Null
    }

    # Установка Windows Boot Manager первым по умолчанию
    bcdedit /set "{fwbootmgr}" displayorder "{bootmgr}" /addfirst 2>$null | Out-Null
    Write-Host "  [+] Windows Boot Manager установлен 1-м приоритетом загрузки." -ForegroundColor Green
} catch {}

Write-Host "=== Очистка GRUB / EFI завершена успешно ===" -ForegroundColor Cyan
