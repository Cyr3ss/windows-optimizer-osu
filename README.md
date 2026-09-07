# ⚡ Windows Gaming & Tablet Latency Optimizer (osu! Edition)
### 🎯 Tailored for Graphics Tablets (XP-Pen / Wacom / Huion / Gaomon), OpenTabletDriver & Competitive Gaming

[![Platform](https://img.shields.io/badge/Platform-Windows%2010%20%7C%2011-0078D6?logo=windows&logoColor=white)](https://github.com/Cyr3ss/windows-optimizer-osu)
[![Python](https://img.shields.io/badge/Python-3.8%2B-3776AB?logo=python&logoColor=white)](https://www.python.org/)
[![No Dependencies](https://img.shields.io/badge/Dependencies-Standard%20Library%20Only-brightgreen)](#)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

[ 🌐 English ](#-english) | [ 🌐 Русский ](#-русский)

---

<a name="-english"></a>
## 🌐 English

A modern, standalone, and safe Windows 10/11 optimization suite designed to eliminate input lag, unlock 1000Hz hardware responsiveness for graphics tablets, tune system timers to 0.5ms, optimize network traffic, and debloat intrusive background telemetry — with built-in protection for laptop touchpads (Synaptics / ELAN / Precision Touchpads).

---

### 📂 Clean Architecture & File Structure

```text
windows-optimizer-osu/
├── optimizer.py             # ⚡ Standalone Native Python 3 Dark GUI (Standard Library Only, 0.5ms Timer)
├── run.bat                  # 🚀 1-Click Fast Launcher
├── build_exe.bat            # 📦 1-Click PyInstaller Builder -> dist\WindowsOptimizer.exe
├── restore_touchpad.bat     # 🛡️ Emergency Touchpad & Input Recovery Tool (Auto-UAC)
├── .gitignore               # ⚙️ Git Ignore Rules
└── README.md                # 📖 Bilingual Documentation
```

---

### 🚀 Quick Start

#### Method 1: Run Python Script Directly (Recommended)
Double-click `run.bat` (it automatically requests Administrator privileges and runs `optimizer.py`).

#### Method 2: Build Standalone EXE
Double-click `build_exe.bat` to create a standalone binary:
```bash
dist\WindowsOptimizer.exe
```

---

### 🎛️ Optimization Modules & Tweaks

| Category | Optimization | Description |
|---|---|---|
| **✏️ Tablet & Pen** | **Disable Pen Hold & Flick Latency** | Disables `HoldMode = 3` and `FlickMode = 3` in registry to eliminate the native 300ms tap-and-hold radial delay and gesture buffering. |
| **✏️ Tablet & Pen** | **Tablet PC Group Policies** | Disables pen ripples, press-and-hold feedback circles, and Windows Ink pen workspace background telemetry. |
| **✏️ Tablet & Pen** | **Reset Cursor Smoothing to 1:1** | Zeroes Windows `SmoothMouseXCurve` and `SmoothMouseYCurve` for purely linear, raw hardware pointer translation. |
| **✏️ Tablet & Pen** | **Laptop Touchpad Protection** | Enforces `LeaveOnWithMouse = 1`, preserving tap-to-click, multi-finger gestures, and double-click speeds for laptop users. |
| **✏️ Tablet & Pen** | **Disable USB Selective Suspend** | Prevents USB hubs and controllers from entering low-power sleep states, guaranteeing a rock-solid 1000Hz polling rate. |
| **⚡ System & FPS** | **High-Resolution Timer (0.500 ms)** | Calls `ntdll.NtSetTimerResolution(5000)` and configures BCD `disabledynamictick = yes` to reduce scheduling jitter. |
| **⚡ System & FPS** | **Win32PrioritySeparation (0x26)** | Allocates maximum CPU quantum slices (Short / Variable) to the active foreground game. |
| **⚡ System & FPS** | **CSRSS, DWM & OTD High Priority** | Grants `CpuPriorityClass = 3` and `IoPriority = 3` to `csrss.exe`, `dwm.exe`, and `OpenTabletDriver.Daemon.exe`. |
| **⚡ System & FPS** | **Game Mode & Disable GameDVR** | Enables Windows GameMode while completely disabling GameDVR screen recording and background presence polling. |
| **⚡ System & FPS** | **Keyboard Repeat Delay & Rate** | Sets `KeyboardDelay = 0`, `KeyboardSpeed = 31`, and zeroes `BounceTime` for ultra-responsive osu! tapping. |
| **⚡ System & FPS** | **CPU Core Unparking (100%)** | Configures `CPMINCORES = 100%` in active power scheme to eliminate micro-wake latency spikes. |
| **⚡ System & FPS** | **Kernel in RAM & Fast Startup Off** | Sets `DisablePagingExecutive = 1` and disables `HiberbootEnabled` for a clean kernel boot state. |
| **⚡ System & FPS** | **Hardware Fullscreen Exclusive (osu!)** | Injects `DISABLEDXMAXIMIZEDWINDOWEDMODE HIGHDPIAWARE` into `AppCompatFlags\Layers` to bypass DWM frame buffering. |
| **🌐 Network & Ping** | **Disable Nagle's Algorithm** | Injects `TCPNoDelay = 1`, `TcpAckFrequency = 1`, and `TcpDelAckTicks = 0` for instantaneous packet delivery. |
| **🌐 Network & Ping** | **Disable Network Throttling** | Sets `NetworkThrottlingIndex = 0xFFFFFFFF` to disable multimedia network limiting. |
| **🌐 Network & Ping** | **Disable SystemResponsiveness Limit** | Sets `SystemResponsiveness = 0` so non-multimedia traffic gets 100% priority. |
| **🌐 Network & Ping** | **Fast DNS Cache Optimization** | Configures negative cache TTL to `0` and expands DNS max cache entries. |
| **🌐 Network & Ping** | **TCP Netsh Stack Tuning** | Configures autotuning to `normal` and enables ECN capabilities. |
| **🔧 Services & SSD** | **Disable Telemetry & DiagTrack** | Disables `DiagTrack`, `dmwappushservice`, and sets telemetry level to 0. |
| **🔧 Services & SSD** | **Disable SysMain (Superfetch)** | Stops random background disk indexing spikes for SSD and NVMe drives. |
| **🔧 Services & SSD** | **Disable Windows Search (Optional)** | Eliminates CPU and I/O background indexing load during gaming. |

---

<a name="-русский"></a>
## 🌐 Русский

Современный, автономный и безопасный комплекс оптимизации для Windows 10/11. Разработан для устранения задержки ввода (input lag), обеспечения аппаратного отклика 1000 Гц для графических планшетов, установки системного таймера на 0.5 мс, снижения пинга и безопасной очистки фоновой телеметрии. Включает встроенную защиту тачпада ноутбуков (Synaptics / ELAN / Precision Touchpads).

---

### 🚀 Быстрый старт

#### Способ 1: Прямой запуск через Python (Рекомендуется)
Запустите `run.bat` двойным кликом (он автоматически запросит права Администратора и откроет приложение `optimizer.py`).

#### Способ 2: Сборка в один автономный EXE
Запустите `build_exe.bat`, чтобы скомпилировать приложение в бинарный файл:
```bash
dist\WindowsOptimizer.exe
```

---

### 🛡️ Безопасность и защита оборудования

- **Тачпады ноутбуков полностью защищены**: Твики гарантируют сохранение настроек `LeaveOnWithMouse = 1`, жестов и скорости двойного клика мыши.
- **Никаких сторонних библиотек**: Написано исключительно на стандартной библиотеке Python 3 (`tkinter`, `ctypes`, `winreg`).
- **Интерактивный GUI**: Возможность сканировать систему, включать и отключать любые твики по отдельности.
- **Аварийное восстановление**: В комплект входит `restore_touchpad.bat` для мгновенного сброса настроек ввода к заводским параметрам.
