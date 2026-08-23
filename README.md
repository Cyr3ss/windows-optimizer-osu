# Windows Gaming & Tablet Latency Optimizer (osu! Edition)
### 🎯 Tailored & Optimized for XP-Pen Deco 640 (IT640) & OpenTabletDriver

[ English ](#-english) | [ Русский ](#-русский)

---

<a name="-english"></a>
## 🇬🇧 English

An automated PowerShell optimization toolkit designed to eliminate input lag, tune graphics tablets (**XP-Pen Deco 640 / OpenTabletDriver / Wacom / Huion**), optimize system timers, improve network responsiveness, clean residual GRUB/EFI files, and debloat background Windows telemetry.

Ideal for freshly installed Windows systems or new gaming PCs.

### ⚡ Quick Start (One-Click Setup)

1. Open **PowerShell as Administrator** (`Win + X` -> **Terminal (Admin)** or **PowerShell (Admin)**).
2. Navigate to the cloned directory and run the master script:
   ```powershell
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
   .\apply_all_tweaks.ps1
   ```

### 📂 Repository Structure

```text
├── apply_all_tweaks.ps1               # Master runner (applies all safe tweaks in 1 click)
├── scripts/
│   ├── 01_grub_efi_cleanup.ps1        # Purges GRUB/Linux from EFI partition & NVRAM
│   ├── 02_tablet_pen_latency.ps1      # Eliminates tablet input lag & Windows Ink delays
│   ├── 03_gaming_system_latency.ps1   # BCD timers, DWM Fullscreen, Game Mode
│   ├── 04_network_ping_tweaks.ps1     # Low ping tweaks (disables Nagle's Algorithm)
│   └── 05_debloat_services_tasks.ps1  # Debloats telemetry, SysMain, SSD LastAccess
└── README.md                          # Bilingual documentation
```

### 🖊️ Specific Optimizations for XP-Pen Deco 640

1. **Eliminates USB Micro-Sleep Latency:**
   * Disables `USB Selective Suspend` and Root Hub power management, forcing the Deco 640 microcontroller to run at maximum steady polling rate.
2. **Disables Windows Ink Delay Buffers:**
   * `HoldMode = 0`: Removes the artificial 300 ms hold-delay on pen tap.
   * `FlickMode = 0`: Disables gesture buffering.
   * `Splash = 0`: Removes visual ripple render overhead.
3. **OpenTabletDriver (OTD) Recommendations for Deco 640:**
   * Keep `DisablePressure: true` and `DisableTilt: true` to reduce packet processing overhead.
   * If you play **Hover** style, set `Tip Button -> None` in Bindings to prevent accidental micro-clicks on tablet tap.
   * Optional: Use **Devocub Filter** (`Anticipate: 5-10 ms`) to compensate for the tablet's built-in hardware smoothing.

### 🛠️ Script Details

* **`01_grub_efi_cleanup.ps1`**: Mounts hidden EFI partition (`S:`), purges leftover Linux folders (`grub`, `loader`, `systemd`, `refind`, kernels), syncs fallback `BOOTX64.EFI` with Windows `bootmgfw.efi`, and deletes orphaned Linux entries from UEFI NVRAM.
* **`02_tablet_pen_latency.ps1`**: Optimizes Windows Pen & Touch subsystem, eliminates Press-and-Hold delays, and disables USB power saving.
* **`03_gaming_system_latency.ps1`**: BCD invariant TSC clock (`disabledynamictick yes`, `useplatformclock no`), DWM Fullscreen Exclusive mode (`HonorFSE`), and Windows Game Mode (`AutoGameModeEnabled = 1`).
* **`04_network_ping_tweaks.ps1`**: Disables Nagle's Algorithm (`TCPNoDelay = 1`, `TcpAckFrequency = 1`) on all network adapters and disables P2P update seeding (`DODownloadMode = 0`).
* **`05_debloat_services_tasks.ps1`**: Disables `DiagTrack`, `SysMain`, sets OEM/AnyDesk services to Manual, disables telemetry scheduled tasks (`Compatibility Appraiser`), optimizes SSD access (`fsutil disablelastaccess 1`), and removes UI menu delays (`MenuShowDelay = 0`).

### 🎮 Recommended In-Game osu! Settings

* **Frame Limiter:** `Unlimited (during gameplay)`.
* **Fullscreen:** `Enabled`.
* **Reduce Dropped Frames:** `Disabled`.
* **Snaking Sliders, Hit Lighting, Combo Bursts:** `Disabled`.
* **Background Dim:** `100%`.

---

<a name="-русский"></a>
## 🇷🇺 Русский

Набор скриптов автоматической настройки Windows, оптимизации графического планшета (**XP-Pen Deco 640 / OpenTabletDriver / Wacom / Huion**), устранения задержек ввода (Input Lag), оптимизации сети и безопасного деблоатинга фоновых служб Windows.

Создан специально для быстрого применения после переустановки Windows или на новом ПК.

### ⚡ Быстрый старт (В один клик)

1. Откройте **PowerShell от имени Администратора**:
   * Нажмите `Win + X` -> выберите **Терминал (Администратор)** или **PowerShell (Администратор)**.
2. Перейдите в папку с репозиторием и запустите мастер-скрипт:
   ```powershell
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
   .\apply_all_tweaks.ps1
   ```

### 📂 Структура репозитория и модули

```text
├── apply_all_tweaks.ps1               # Главный скрипт (применяет все безопасные твики)
├── scripts/
│   ├── 01_grub_efi_cleanup.ps1        # Удаление остатков GRUB / Linux из EFI и NVRAM
│   ├── 02_tablet_pen_latency.ps1      # Устранение инпут-лага планшета и Windows Ink (XP-Pen Deco 640)
│   ├── 03_gaming_system_latency.ps1   # BCD таймеры, DWM Fullscreen, Game Mode
│   ├── 04_network_ping_tweaks.ps1     # Снижение пинга (отключение Nagle's Algorithm)
│   └── 05_debloat_services_tasks.ps1  # Отключение телеметрии, SysMain и тяжелых задач
└── README.md                          # Двуязычная документация
```

### 🖊️ Оптимизации конкретно для XP-Pen Deco 640:

1. **Устранение микро-задержек USB-контроллера:**
   * Отключение `USB Selective Suspend` и спящего режима USB-концентраторов исключает засыпание контроллера XP-Pen Deco 640.
2. **Отключение скрытых буферов Windows Ink:**
   * `HoldMode = 0`: убирает 300 мс задержки при касании наконечником.
   * `FlickMode = 0`: убирает буфер распознавания жестов.
   * `Splash = 0`: убирает анимацию волн вокруг курсора.
3. **Рекомендации OpenTabletDriver (OTD) для Deco 640:**
   * Отключите обработку силы нажатия и наклона (`DisablePressure: true`, `DisableTilt: true`) для снижения нагрузки на обработку пакетов.
   * Для стиля игры **Hover** отключите `Tip Button -> None` в настройках Bindings, чтобы случайные касания поверхности не вызывали кликов мыши.
   * При необходимости используйте плагин **Devocub Filter** (`Anticipate: 5-10 ms`) для компенсации заводского аппаратного сглаживания планшета.

### 🛠️ Что делает каждый модуль

* **`01_grub_efi_cleanup.ps1`**: Монтирует скрытый раздел EFI (`S:`), удаляет остатки Linux (`grub`, `loader`, `systemd`, `refind`, ядра), синхронизирует fallback `BOOTX64.EFI` с `bootmgfw.efi` и удаляет старые записи из памяти UEFI NVRAM.
* **`02_tablet_pen_latency.ps1`**: Отключает задержки жестов, убирает задержку правого клика (Press-and-Hold) и отключает спящий режим USB.
* **`03_gaming_system_latency.ps1`**: Настраивает BCD таймеры (`disabledynamictick yes`, `useplatformclock no`), режим прямого вывода кадров (HonorFSE) и Windows Game Mode (`AutoGameModeEnabled = 1`).
* **`04_network_ping_tweaks.ps1`**: Отключает алгоритм Нейгла (`TCPNoDelay = 1`, `TcpAckFrequency = 1`) на сетевых картах и отключает фоновую P2P-раздачу обновлений Windows (`DODownloadMode = 0`).
* **`05_debloat_services_tasks.ps1`**: Отключает `DiagTrack`, `SysMain`, переводит OEM/AnyDesk службы в ручной режим, отключает сканеры планировщика (`Compatibility Appraiser`), оптимизирует SSD (`fsutil disablelastaccess 1`) и убирает задержки меню (`MenuShowDelay = 0`).

### 🎮 Рекомендованные настройки osu!

* **Ограничение частоты кадров:** `Без ограничений (в игре)` (Unlimited).
* **Полноэкранный режим:** `Включен`.
* **Уменьшать просадку кадров:** `Выключено`.
* **Змейка слайдеров, вспышки комбо, освещение попаданий:** `Выключено`.
* **Затемнение фона:** `100%`.
