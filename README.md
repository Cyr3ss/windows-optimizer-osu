# Windows Gaming & Tablet Latency Optimizer (osu! Edition)
### 🎯 Tailored & Optimized for XP-Pen Deco 640 (IT640) & OpenTabletDriver

[ English ](#-english) | [ Русский ](#-русский)

---

<a name="-english"></a>
## 🇬🇧 English

An automated, universal PowerShell optimization toolkit designed to eliminate input lag, tune graphics tablets (**XP-Pen Deco 640 / OpenTabletDriver / Wacom / Huion / Gaomon**), optimize system timers, improve network responsiveness, and safely debloat background Windows telemetry.

Works out-of-the-box on any Windows 10/11 PC with visual real-time status reporting (`[  OK  ]`, `[ WARN ]`, `[ FAIL ]`).

### ⚡ Quick Start (One-Click Setup)

1. Open **PowerShell as Administrator** (`Win + X` -> **Terminal (Admin)** or **PowerShell (Admin)**).
2. Navigate to the directory and run:
   ```powershell
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
   .\apply_all_tweaks.ps1
   ```

### 📂 Repository Structure

```text
├── apply_all_tweaks.ps1               # Master runner (Auto-UAC + Real-time visual report)
├── scripts/
│   ├── 01_tablet_pen_latency.ps1      # Eliminates tablet lag, Windows Ink & TabletInputService
│   ├── 02_gaming_system_latency.ps1   # BCD timers, Win32Priority 0x26, CSRSS/DWM, Game Mode
│   ├── 03_network_ping_tweaks.ps1     # Low ping tweaks (disables Nagle's Algorithm & QoS reserve)
│   └── 04_debloat_services_tasks.ps1  # Debloats telemetry, SysMain, SSD LastAccess
└── README.md                          # Bilingual documentation
```

### 📊 Diagnostic Status Indicators

During execution, each tweak provides clear visual feedback:
* `[  OK  ]` **Green**: Feature/tweak applied completely and successfully.
* `[ WARN ]` **Yellow**: Optional tweak skipped (e.g., service/OEM app not installed on this machine).
* `[ FAIL ]` **Red**: Action failed due to insufficient permissions or system lock.

---

<a name="-русский"></a>
## 🇷🇺 Русский

Универсальный набор скриптов автоматической настройки Windows, оптимизации графических планшетов (**XP-Pen Deco 640 / OpenTabletDriver / Wacom / Huion / Gaomon**), устранения задержек ввода (Input Lag), оптимизации сети и безопасного деблоатинга фоновых служб.

Работает на любом компьютере с Windows 10/11 и выводит наглядный статус каждого действия (`[  OK  ]`, `[ WARN ]`, `[ FAIL ]`).

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
├── apply_all_tweaks.ps1               # Главный мастер-скрипт (Auto-UAC + Итоговый отчет)
├── scripts/
│   ├── 01_tablet_pen_latency.ps1      # Инпут-лаг планшета, Group Policies, Windows Ink и USB
│   ├── 02_gaming_system_latency.ps1   # BCD таймеры, кванты CPU (0x26), CSRSS/DWM, Game Mode
│   ├── 03_network_ping_tweaks.ps1     # Снижение пинга (отключение Nagle's Algorithm и лимитов QoS)
│   └── 04_debloat_services_tasks.ps1  # Отключение телеметрии, SysMain и тяжелых задач
└── README.md                          # Двуязычная документация
```

### 📊 Наглядные статусы выполнения:
* `[  OK  ]` 🟢 **Зеленый:** Параметр или твик успешно применен.
* `[ WARN ]` 🟡 **Желтый:** Предупреждение или пропуск (например, служба отсутствует в данной версии Windows).
* `[ FAIL ]` 🔴 **Красный:** Ошибка применения или нехватка прав доступа.

---

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
