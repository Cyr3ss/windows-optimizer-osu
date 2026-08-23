<#
.SYNOPSIS
    Cleans up leftover Linux/GRUB/systemd bootloader files from EFI partition and deletes Linux UEFI NVRAM entries.
#>

# Check Administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Этот скрипт должен быть запущен от имени Администратора!"
    exit 1
}

Write-Host "=== [1/5] Очистка GRUB / Linux из EFI и NVRAM ===" -ForegroundColor Cyan

# 1. Mount EFI partition
Write-Host "[*] Монтирование системного раздела EFI..." -ForegroundColor Yellow
mountvol S: /s
if (-not (Test-Path "S:\EFI")) {
    Write-Error "Не удалось подключить раздел EFI!"
    exit 1
}

# 2. Delete leftover Linux/GRUB folders & kernels
$linuxItems = @(
    "S:\grub",
    "S:\loader",
    "S:\EFI\systemd",
    "S:\EFI\Linux",
    "S:\EFI\refind",
    "S:\EFI\ubuntu",
    "S:\EFI\debian",
    "S:\EFI\arch",
    "S:\EFI\fedora",
    "S:\EFI\kali",
    "S:\EFI\manjaro",
    "S:\intel-ucode.img",
    "S:\amd-ucode.img",
    "S:\vmlinuz-linux",
    "S:\initramfs-linux.img",
    "S:\initramfs-linux-fallback.img"
)

foreach ($item in $linuxItems) {
    if (Test-Path $item) {
        Remove-Item -Path $item -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "  [-] Удалено: $item" -ForegroundColor Green
    }
}

# Delete any machine-id subfolders in root S:\ (systemd-boot kernels)
Get-ChildItem -Path "S:\" -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -match "^[0-9a-f]{32}$" } | ForEach-Object {
    Remove-Item -Path $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  [-] Удалена папка ядер systemd-boot: $($_.Name)" -ForegroundColor Green
}

# 3. Synchronize fallback bootloader with Windows
if (Test-Path "S:\EFI\Microsoft\Boot\bootmgfw.efi") {
    if (-not (Test-Path "S:\EFI\BOOT")) { New-Item -Path "S:\EFI\BOOT" -ItemType Directory -Force | Out-Null }
    Copy-Item -Path "S:\EFI\Microsoft\Boot\bootmgfw.efi" -Destination "S:\EFI\BOOT\BOOTX64.EFI" -Force
    Write-Host "  [+] Fallback-загрузчик BOOTX64.EFI синхронизирован с Windows bootmgfw.efi" -ForegroundColor Green
}

# 4. Unmount EFI partition
mountvol S: /d
Write-Host "  [+] Раздел EFI отмонтирован." -ForegroundColor Green

# 5. Clean up BCD NVRAM Entries
Write-Host "[*] Проверка и очистка записей UEFI NVRAM..." -ForegroundColor Yellow
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
    bcdedit /delete "$($e.Id)"
}

# Ensure Windows Boot Manager is primary
bcdedit /set "{fwbootmgr}" displayorder "{bootmgr}" /addfirst 2>$null | Out-Null
Write-Host "[+] Windows Boot Manager установлен 1-м приоритетом загрузки." -ForegroundColor Green
Write-Host "=== Очистка GRUB / EFI завершена успешно ===" -ForegroundColor Cyan
