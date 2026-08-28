# Windows Gaming & Tablet Latency Optimizer (osu! Edition)
### 🎯 Tailored & Optimized for XP-Pen Deco 640 (IT640) & OpenTabletDriver

[ English ](#-english) | [ Русский ](#-русский)

---

<a name="-english"></a>
## 🇬🇧 English

An interactive, universal Windows 10/11 desktop optimization suite and CLI toolkit designed to eliminate input lag, tune graphics tablets (**XP-Pen Deco 640 / OpenTabletDriver / Wacom / Huion / Gaomon**), optimize system timers, improve network responsiveness, and safely debloat background Windows telemetry.

### ✨ Key Features

1. **🖥️ Interactive Dark WPF GUI (`launch_gui.bat` / `optimizer_gui.ps1`):**
   * **Smart Pre-Scan Engine**: Automatically scans the system before applying anything to verify whether specific services, hardware controllers, or game executables actually exist on your PC.
   * **Individual Checkboxes**: Toggle individual tweaks per category (Tablet & Pen, System & FPS, Network & Ping, Debloat & SSD).
   * **Visual Status Badges**: Displays real-time status (`[ Detected ]`, `[ Already Active ]`, `[ Applied OK ]`, `[ Not Applicable ]`).
   * **Live Console Logger & Progress Bar**: Clean color-coded logging of all actions.
2. **⚡ 1-Click Console CLI (`apply_all_tweaks.ps1`):**
   * Automated batch runner with auto-UAC escalation and summary report (`[ OK ]`, `[ WARN ]`, `[ FAIL ]`).

### ⚡ Quick Start

#### Option A: Interactive GUI (Recommended)
Double-click **`launch_gui.bat`** (or run `powershell -File optimizer_gui.ps1`).

#### Option B: 1-Click PowerShell CLI
Run in elevated PowerShell:
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\apply_all_tweaks.ps1
```

### 📂 Repository Structure

```text
├── launch_gui.bat                     # 1-Click GUI Launcher (Auto-Admin)
├── optimizer_gui.ps1                  # Interactive WPF GUI Application
├── apply_all_tweaks.ps1               # Automated CLI Runner (All tweaks in 1-click)
├── scripts/
│   ├── 01_tablet_pen_latency.ps1      # Tablet lag, Windows Ink & TabletInputService
│   ├── 02_gaming_system_latency.ps1   # BCD timers, Win32Priority 0x26, CSRSS/DWM, Game Mode
│   ├── 03_network_ping_tweaks.ps1     # Low ping tweaks (disables Nagle's Algorithm & QoS reserve)
│   └── 04_debloat_services_tasks.ps1  # Debloats telemetry, SysMain, SSD LastAccess
└── README.md                          # Bilingual documentation
```

---

<a name="-русский"></a>
## 🇷🇺 Русский

Интерактивное графическое приложение и консольный набор скриптов для настройки Windows, оптимизации графических планшетов (**XP-Pen Deco 640 / OpenTabletDriver / Wacom / Huion / Gaomon**), устранения задержек ввода (Input Lag), оптимизации сети и безопасного деблоатинга фоновых служб.

### ✨ Возможности:

1. **🖥️ Интерактивный Dark GUI интерфейс (`launch_gui.bat` / `optimizer_gui.ps1`):**
   * **Умное предварительное сканирование (Smart Pre-Check):** Перед внесением изменений программа проверяет, существует ли служба, поддерживается ли WMI-метод, найден ли путь к игре или сетевому интерфейсу на данном ПК, и отображает статус бейджем (`[ Обнаружено ]`, `[ Уже включено ]`, `[ Не применимо ]`).
   * **Покнопочный выбор:** Включение и отключение любых конкретных твиков через чекбоксы по категориям (*Планшет и Перо*, *Система и FPS*, *Сеть и Пинг*, *Службы и SSD*).
   * **Живой журнал логов и шкала прогресса:** Наглядный цветной вывод каждого действия.
2. **⚡ Консольный запуск в 1 клик (`apply_all_tweaks.ps1`):**
   * Автоматический мастер-скрипт с автоповышением прав UAC и итоговой таблицей отчета (`[ OK ]`, `[ WARN ]`, `[ FAIL ]`).

### ⚡ Быстрый запуск

#### Вариант 1: Графическое приложение (Рекомендуется)
Дважды кликните по файлу **`launch_gui.bat`**.

#### Вариант 2: Консольный скрипт PowerShell
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\apply_all_tweaks.ps1
```

### 📂 Структура репозитория и модули

```text
├── launch_gui.bat                     # Лаунчер GUI-приложения в 1 клик (Авто-UAC)
├── optimizer_gui.ps1                  # Графическое WPF-приложение
├── apply_all_tweaks.ps1               # Консольный мастер-скрипт
├── scripts/
│   ├── 01_tablet_pen_latency.ps1      # Инпут-лаг планшета, Group Policies, Windows Ink и USB
│   ├── 02_gaming_system_latency.ps1   # BCD таймеры, кванты CPU (0x26), CSRSS/DWM, Game Mode
│   ├── 03_network_ping_tweaks.ps1     # Снижение пинга (отключение Nagle's Algorithm и лимитов QoS)
│   └── 04_debloat_services_tasks.ps1  # Отключение телеметрии, SysMain и тяжелых задач
└── README.md                          # Двуязычная документация
```

### 🖊️ Оптимизации для XP-Pen Deco 640 и планшетов:
1. **Устранение микро-задержек USB-контроллера:**
   * Отключение `USB Selective Suspend` и спящего режима USB Root Hub.
2. **Отключение скрытых буферов Windows Ink и службы рукописного ввода:**
   * `HoldMode = 0`, `FlickMode = 0`, `Splash = 0`.
   * **`TabletInputService = Disabled`**: фоновая служба сенсорного ввода и рукописного текста отключена.
3. **Рекомендации OpenTabletDriver (OTD) для Deco 640:**
   * Отключите `DisablePressure: true` и `DisableTilt: true`.
   * При необходимости используйте плагин **Devocub Filter** (`Anticipate: 8-12 ms`) для компенсации заводского сглаживания чипа XP-Pen.

### 🎮 Рекомендованные настройки osu!
* **Ограничение частоты кадров:** `Без ограничений (в игре)` (Unlimited).
* **Полноэкранный режим:** `Включен`.
* **Уменьшать просадку кадров:** `Выключено`.
* **Змейка слайдеров, вспышки комбо, освещение попаданий:** `Выключено`.
* **Затемнение фона:** `100%`.
