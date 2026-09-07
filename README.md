# ⚡ Windows Gaming & Tablet Latency Optimizer (osu! Edition)
### 🎯 Tailored for Graphics Tablets (XP-Pen Deco 640 / Wacom / Huion / Gaomon), OpenTabletDriver & Competitive Gaming

[![Platform](https://img.shields.io/badge/Platform-Windows%2010%20%7C%2011-0078D6?logo=windows&logoColor=white)](https://github.com/Cyr3ss/windows-optimizer-osu)
[![Python](https://img.shields.io/badge/Python-3.8%2B-3776AB?logo=python&logoColor=white)](https://www.python.org/)
[![No Dependencies](https://img.shields.io/badge/Dependencies-Standard%20Library%20Only-brightgreen)](#)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

[ 🇬🇧 English ](#-english) | [ 🇷🇺 Русский ](#-русский)

---

<a name="-english"></a>
## 🇬🇧 English

A modern, standalone, and safe Windows 10/11 optimization suite designed to eliminate input lag, unlock 1000Hz hardware responsiveness for graphics tablets, tune system timers to 0.5ms, optimize network traffic, and debloat intrusive background telemetry — with built-in protection for laptop touchpads (Synaptics / ELAN / Precision Touchpads).

---

### ✨ Architecture & Clean File Structure

```text
windows-optimizer-osu/
├── optimizer.py             # 🐍 Standalone Native Python 3 Dark GUI (Standard Library Only, 0.5ms Timer)
├── run.bat                  # 🚀 1-Click Fast Launcher
├── build_exe.bat            # 📦 1-Click PyInstaller Builder -> dist\WindowsOptimizer.exe
├── restore_touchpad.bat     # 🛡️ Emergency Touchpad & Input Recovery Tool (Auto-UAC)
├── .gitignore               # ⚙️ Git Ignore Rules
└── README.md                # 📖 Bilingual Documentation
```

---

### 🚀 Getting Started

#### 1. Fast Launch (Recommended)
Double-click **`run.bat`** (or run `python optimizer.py`).
> **Note:** Requires Python 3.8+. Uses standard library only (**zero pip packages required**).

#### 2. Standalone `.exe` Compilation (PyInstaller)
Compile `optimizer.py` into a portable, single-file binary with embedded Administrator UAC manifest:
```bat
build_exe.bat
```
*The compiled executable will be generated at:* `dist\WindowsOptimizer.exe`

#### 3. Emergency Touchpad Recovery
If a laptop touchpad ever requires state re-initialization:
```bat
restore_touchpad.bat
```

---

### 🛠️ Detailed Breakdown of the 21 Optimizations

| Category | Optimization Module | Technical Action & Impact |
| :--- | :--- | :--- |
| **🖊️ Tablet & Pen** | **Disable Pen Hold & Flick Latency** | Sets `HoldMode=0`, `FlickMode=0`, `Splash=0`, and `WaitTime=0` in `Wisp\Pen\SysEventParameters`. Removes the native 300ms tap-and-hold delay. |
| **🖊️ Tablet & Pen** | **Tablet PC & PenWorkspace GPO** | Applies system policies to disable ripple animations, press-and-hold circles, and background handwriting data harvesting. |
| **🖊️ Tablet & Pen** | **1:1 Raw Linear Curve** | Zeroes polynomial `SmoothMouseXCurve` and `SmoothMouseYCurve` in registry for absolute linear 1:1 hardware pointer mapping without acceleration. |
| **🖊️ Tablet & Pen** | **Laptop Touchpad Protection** | Enforces `LeaveOnWithMouse = 1` and `Enabled = 1` in `PrecisionTouchPad`, ensuring the laptop touchpad remains fully active when mice/tablets are plugged in. |
| **🖊️ Tablet & Pen** | **USB Power Plan Management** | Disables `USB Selective Suspend` across active power schemes (`ACSettingIndex = 0`) to guarantee continuous 1000Hz polling without sleeping. |
| **⚡ System & FPS** | **Invariant TSC Timers & 0.5ms** | Configures `bcdedit /set disabledynamictick yes` / `useplatformclock no` and locks system timer to 0.500 ms (500 µs) via `ntdll.NtSetTimerResolution`. |
| **⚡ System & FPS** | **3:1 Gaming CPU Quantum (0x26)** | Sets `Win32PrioritySeparation = 38` (0x26) for fixed, short CPU time-slice execution dedicated to the foreground game window. |
| **⚡ System & FPS** | **CSRSS, DWM & OTD High Priority** | Sets `CpuPriorityClass = 3` and `IoPriority = 3` in `Image File Execution Options` for `csrss.exe`, `dwm.exe`, and `OpenTabletDriver.Daemon.exe`. |
| **⚡ System & FPS** | **Game Mode & Disable GameDVR** | Enables Windows Game Mode while completely terminating `GameBarPresenceWriter.exe` and background GameDVR video capture services. |
| **⚡ System & FPS** | **Keyboard Repeat Delay & Rate** | Sets `KeyboardDelay = 0`, `KeyboardSpeed = 31`, and zeroes `BounceTime` to eliminate debounce delay for rapid osu! key tapping. |
| **⚡ System & FPS** | **CPU Core Unparking (100%)** | Configures `CPMINCORES = 100%` in the active power scheme to prevent sleeping CPU cores from causing micro-wake latency spikes. |
| **⚡ System & FPS** | **Kernel in RAM & Fast Startup Off** | Sets `DisablePagingExecutive = 1` and disables `HiberbootEnabled` for a clean kernel boot state without stale pagefile caching. |
| **⚡ System & FPS** | **Hardware Fullscreen Exclusive (osu!)** | Injects `DISABLEDXMAXIMIZEDWINDOWEDMODE HIGHDPIAWARE` into `AppCompatFlags\Layers` to bypass DWM frame buffering. |
| **🌐 Network & Ping**| **Disable Nagle's Algorithm** | Injects `TCPNoDelay = 1`, `TcpAckFrequency = 1`, and `TcpDelAckTicks = 0` across all active network interfaces for instantaneous small packet delivery. |
| **🌐 Network & Ping**| **Remove 20% QoS Bandwidth Limit** | Sets `NonBestEffortLimit = 0` in `SOFTWARE\Policies\Microsoft\Windows\Psched` to unlock 100% bandwidth for low-latency gaming. |
| **🌐 Network & Ping**| **Disable Delivery Optimization P2P** | Disables `DODownloadMode = 0` to prevent Windows from seeding background updates over your local network and internet connection. |
| **🧹 Debloat & SSD** | **Disable Telemetry & SysMain** | Stops and disables `DiagTrack` (Connected User Experiences) and `SysMain` (Superfetch) to eliminate background SSD indexing. |
| **🧹 Debloat & SSD** | **OEM Background Services to Manual** | Sets secondary vendor diagnostics (`HPAppHelperCap`, `HPDiagsCap`, `AnyDesk`, `WerSvc`) to on-demand (Manual/Demand Start). |
| **🧹 Debloat & SSD** | **Scheduled Tasks Debloat** | Disables heavy telemetry tasks including `Microsoft Compatibility Appraiser`, `ProgramDataUpdater`, `Consolidator`, and `UsbCeip`. |
| **🧹 Debloat & SSD** | **SSD LastAccess Timestamp Off** | Executes `fsutil behavior set disablelastaccess 1` to reduce unnecessary disk write cycles on SSDs during file read operations. |
| **🧹 Debloat & SSD** | **Eliminate UI Menus Delay** | Sets `MenuShowDelay = 0` and `MinAnimate = 0` for instantaneous context menu and window animations. |

---

### 🖊️ OpenTabletDriver & Tablet Best Practices

1. **Zero Smoothing Filters**:
   * Open **OpenTabletDriver** -> **Filters** tab.
   * Ensure **all smoothing filters are turned OFF** (no Reconstructor, no Devocub Antichatter).
   * Result: **0 ms hardware raw input latency (1000Hz)**.
2. **High Priority for OTD Daemon**:
   * `OpenTabletDriver.Daemon.exe` is configured with `High` process priority to guarantee real-time packet parsing under heavy CPU load.
3. **Windows Pointer Precision (1:1)**:
   * Ensure Windows pointer speed is set to **`10` (6/11 notch)** with acceleration disabled to ensure exact 1:1 hardware pixel mapping without fractional interpolation.

---

### 🎮 Recommended osu! In-Game Settings

* **Frame Limiter:** `Unlimited (in-game)` (Without FPS caps).
* **Fullscreen:** `Enabled` (`Fullscreen = 1`).
* **Reduce Frame Drops:** `Disabled` (Reduces frame queue delay).
* **Snaking Sliders & Hit Lighting:** `Disabled`.
* **Background Dim:** `100%`.

---

<a name="-русский"></a>
## 🇷🇺 Русский

Современный, автономный и безопасный комплекс оптимизации Windows 10/11 для полного устранения задержек ввода (Input Lag), настройки графических планшетов (**XP-Pen Deco 640 / OpenTabletDriver / Wacom / Huion / Gaomon**), системных таймеров (0.5 мс), сетевых протоколов и фоновых служб — с сохранением штатной работы тачпадов ноутбуков (Synaptics / ELAN / Precision Touchpads).

---

### ✨ Чистая архитектура и файлы проекта

```text
windows-optimizer-osu/
├── optimizer.py             # 🐍 Нативное GUI-приложение на чистом Python 3 (Dark Theme, без pip-зависимостей, таймер 0.5мс)
├── run.bat                  # 🚀 Быстрый запуск программы в 1 клик
├── build_exe.bat            # 📦 1-клик сборщик в автономный .exe (dist\WindowsOptimizer.exe)
├── restore_touchpad.bat     # 🛡️ Аварийный инструмент восстановления тачпада и служб (Авто-UAC)
├── .gitignore               # ⚙️ Правила исключений Git
└── README.md                # 📖 Двуязычная документация
```

---

### 🚀 Быстрый старт

#### 1. Быстрый запуск Python GUI (Рекомендуется)
Дважды кликните по **`run.bat`** (или выполните `python optimizer.py`).
> **Примечание:** Требуется Python 3.8+. Используется только стандартная библиотека (**установка сторонних pip-пакетов не требуется**).

#### 2. Сборка в один автономный `.exe` файл
Скомпилируйте `optimizer.py` в готовый исполняемый файл с автоматическим запросом прав Администратора:
```bat
build_exe.bat
```
*Скомпилированный файл будет создан в папке:* `dist\WindowsOptimizer.exe`

#### 3. Аварийное восстановление тачпада
Если требуется сбросить политики ввода и перезапустить драйвер тачпада:
```bat
restore_touchpad.bat
```

---

### 🛠️ Таблица всех 21 оптимизаций

| Категория | Модуль оптимизации | Что делает и какой эффект даёт |
| :--- | :--- | :--- |
| **🖊️ Планшет и Перо** | **Отключение задержек касания и жестов** | `HoldMode=0`, `FlickMode=0`, `Splash=0`, `WaitTime=0` в `SysEventParameters`. Убирает задержку 300 мс при касании пером. |
| **🖊️ Планшет и Перо** | **Групповые политики TabletPC** | Запрещает генерацию кругов нажатия, зажатия и сбор рукописных данных. |
| **🖊️ Планшет и Перо** | **1:1 Raw Linear Curve** | Обнуляет полиномиальные кривые `SmoothMouseXCurve`/`YCurve` для абсолютно линейного движения курсора без акселерации. |
| **🖊️ Планшет и Перо** | **Защита тачпада ноутбука** | Выставляет `LeaveOnWithMouse = 1` и `Enabled = 1`, предотвращая отключение тачпада при подключении мыши/планшета. |
| **🖊️ Планшет и Перо** | **Энергосбережение USB** | Отключает `USB Selective Suspend` в активной схеме питания (`ACSettingIndex = 0`) для стабильного опроса 1000 Hz. |
| **⚡ Система и FPS** | **Аппаратный таймер TSC и 0.5 мс** | `bcdedit /set disabledynamictick yes` и фиксация таймера Windows на 0.500 мс (500 мкс) через `NtSetTimerResolution`. |
| **⚡ Система и FPS** | **Кванты CPU 3:1 (0x26)** | `Win32PrioritySeparation = 38` (0x26) выделяет активной игре в 3 раза больше времени процессора без прерываний на фон. |
| **⚡ Система и FPS** | **Приоритеты CSRSS, DWM и OTD** | Выставляет `CpuPriorityClass = 3` и `IoPriority = 3` для `csrss.exe`, `dwm.exe` и `OpenTabletDriver.Daemon.exe`. |
| **⚡ Система и FPS** | **Game Mode и отключение GameDVR** | Включает игровой режим Windows и полностью выключает фоновый процесс `GameBarPresenceWriter.exe`. |
| **⚡ Система и FPS** | **Задержка повтора клавиатуры** | `KeyboardDelay = 0`, `KeyboardSpeed = 31`, `BounceTime = 0` для максимальной скорости регистрации стримов K1/K2 в osu!. |
| **⚡ Система и FPS** | **CPU Core Unparking (100%)** | `CPMINCORES = 100%` запрещает процессору усыплять логические ядра, исключая задержку 2–5 мс при их пробуждении. |
| **⚡ Система и FPS** | **Ядро в RAM и чистый запуск** | `DisablePagingExecutive = 1` фиксирует ядро Windows в ОЗУ, а отключение `Hiberboot` гарантирует чистый старт без кэша. |
| **⚡ Система и FPS** | **Аппаратный Fullscreen для osu!** | Добавляет `DISABLEDXMAXIMIZEDWINDOWEDMODE HIGHDPIAWARE` в `AppCompatFlags\Layers` для прямого вывода без буфера DWM. |
| **🌐 Сеть и Пинг** | **Отключение алгоритма Нейгла** | `TCPNoDelay = 1`, `TcpAckFrequency = 1` на всех сетевых адаптерах отправляют пакеты мгновенно без буферизации. |
| **🌐 Сеть и Пинг** | **Снятие 20% лимита QoS** | `NonBestEffortLimit = 0` разблокирует 100% пропускной способности интернет-канала для сетевых игр. |
| **🌐 Сеть и Пинг** | **Отключение Delivery Optimization** | `DODownloadMode = 0` запрещает Windows раздавать обновления по локальной сети и интернету. |
| **🧹 Службы и SSD** | **Отключение DiagTrack и SysMain** | Останавливает постоянную запись диагностических логов и телеметрии на SSD и освобождает оперативную память. |
| **🧹 Службы и SSD** | **OEM-службы в ручной режим** | Переводит фоновые диагностические службы (`HPAppHelperCap`, `HPDiagsCap`, `AnyDesk`, `WerSvc`) в режим Manual. |
| **🧹 Службы и SSD** | **Очистка задач планировщика** | Отключает фоновые сканеры совместимости (`Compatibility Appraiser`, `ProgramDataUpdater`, `Consolidator`, `UsbCeip`). |
| **🧹 Службы и SSD** | **Оптимизация SSD (Disable LastAccess)** | `fsutil behavior set disablelastaccess 1` отключает лишние операции перезаписи времени доступа при чтении файлов. |
| **🧹 Службы и SSD** | **Устранение задержек меню** | `MenuShowDelay = 0` и `MinAnimate = 0` делают отклик окон и контекстных меню Windows моментальным. |

---

### 🖊️ Рекомендации OpenTabletDriver для Deco 640

1. **Отключение фильтров сглаживания:**
   * Откройте **OpenTabletDriver** -> вкладка **Filters**.
   * Убедитесь, что **все фильтры выключены** (список пуст `Filters: []`).
   * Это обеспечивает **чистый аппаратный ввод с частотой 1000 Hz и 0 мс программной задержки**.
2. **Высокий приоритет демона OTD:**
   * Процессу `OpenTabletDriver.Daemon.exe` назначен приоритет **High** для бесперебойного опроса пакетов пера при любой нагрузке на процессор.
3. **Чувствительность Windows (1:1):**
   * В настройках мыши Windows ползунок должен стоять строго на **6-м делении из 11 (`MouseSensitivity = 10`)** с выключенной повышенной точностью. Это исключает дробное масштабирование и сохраняет резкость пиксель-в-пиксель.

---

### 🎮 Рекомендованные настройки в игре osu!

* **Ограничение частоты кадров:** `Без ограничений (в игре)` / `Unlimited`.
* **Полноэкранный режим:** `Включен`.
* **Уменьшать просадку кадров:** `Выключено`.
* **Змейка слайдеров, вспышки комбо, освещение попаданий:** `Выключено`.
* **Затемнение фона:** `100%`.
