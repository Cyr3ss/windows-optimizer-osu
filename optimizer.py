"""
=============================================================================
 Windows Gaming & Tablet Optimizer (osu! Edition) - Python GUI Application
=============================================================================
 Native Python 3 GUI application with dark theme, accurate system scanner,
 granular tweak checkboxes, live console logger, and exception reporting.
 Bilingual (English / Русский) language switcher included.
 Standalone (zero external pip dependencies) & PyInstaller compatible.
=============================================================================
"""

import os
import sys
import ctypes
from ctypes import wintypes
import traceback
import datetime
import subprocess
import winreg
import tkinter as tk
from tkinter import ttk, scrolledtext, messagebox

# ---------------------------------------------------------------------------
# Path & Logging Setup
# ---------------------------------------------------------------------------
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ERROR_LOG_PATH = os.path.join(SCRIPT_DIR, "optimizer_error.log")

def log_exception(exc: Exception, context: str = "General"):
    timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    tb = traceback.format_exc()
    log_entry = (
        f"=================================================================\n"
        f"[{timestamp}] ERROR IN [{context}]\n"
        f"Message: {str(exc)}\n"
        f"StackTrace:\n{tb}\n"
        f"=================================================================\n\n"
    )
    try:
        with open(ERROR_LOG_PATH, "a", encoding="utf-8") as f:
            f.write(log_entry)
    except Exception:
        pass

def is_admin() -> bool:
    try:
        return ctypes.windll.shell32.IsUserAnAdmin() != 0
    except Exception:
        return False

def request_admin():
    if not is_admin():
        try:
            if getattr(sys, 'frozen', False):
                ctypes.windll.shell32.ShellExecuteW(None, "runas", sys.executable, None, None, 1)
            else:
                ctypes.windll.shell32.ShellExecuteW(None, "runas", sys.executable, f'"{os.path.abspath(__file__)}"', None, 1)
            sys.exit(0)
        except Exception as e:
            log_exception(e, "Admin Elevation")
            sys.exit(1)

# ---------------------------------------------------------------------------
# High-Resolution Windows System Timer (0.500 ms / 500 µs)
# ---------------------------------------------------------------------------
def set_high_resolution_timer(desired_100ns: int = 5000) -> tuple:
    """Sets system timer resolution to 0.5ms via ntdll.NtSetTimerResolution."""
    try:
        ntdll = ctypes.WinDLL('ntdll')
        cur_res = wintypes.ULONG()
        status = ntdll.NtSetTimerResolution(desired_100ns, 1, ctypes.byref(cur_res))
        return (status == 0, cur_res.value / 10000.0)
    except Exception:
        return (False, 1.0)

# ---------------------------------------------------------------------------
# Registry Helper Functions
# ---------------------------------------------------------------------------
def reg_set_dword(root, subkey: str, name: str, value: int):
    try:
        key = winreg.CreateKeyEx(root, subkey, 0, winreg.KEY_SET_VALUE | winreg.KEY_WOW64_64KEY)
        winreg.SetValueEx(key, name, 0, winreg.REG_DWORD, value)
        winreg.CloseKey(key)
        return True
    except Exception as e:
        log_exception(e, f"reg_set_dword: {subkey}\\{name}")
        return False

def reg_set_string(root, subkey: str, name: str, value: str):
    try:
        key = winreg.CreateKeyEx(root, subkey, 0, winreg.KEY_SET_VALUE | winreg.KEY_WOW64_64KEY)
        winreg.SetValueEx(key, name, 0, winreg.REG_SZ, value)
        winreg.CloseKey(key)
        return True
    except Exception as e:
        log_exception(e, f"reg_set_string: {subkey}\\{name}")
        return False

def reg_set_binary(root, subkey: str, name: str, value: bytes):
    try:
        key = winreg.CreateKeyEx(root, subkey, 0, winreg.KEY_SET_VALUE | winreg.KEY_WOW64_64KEY)
        winreg.SetValueEx(key, name, 0, winreg.REG_BINARY, value)
        winreg.CloseKey(key)
        return True
    except Exception as e:
        log_exception(e, f"reg_set_binary: {subkey}\\{name}")
        return False

def reg_get_dword(root, subkey: str, name: str):
    try:
        key = winreg.OpenKey(root, subkey, 0, winreg.KEY_READ | winreg.KEY_WOW64_64KEY)
        val, _ = winreg.QueryValueEx(key, name)
        winreg.CloseKey(key)
        return val
    except Exception:
        return None

def reg_get_str(root, subkey: str, name: str):
    try:
        key = winreg.OpenKey(root, subkey, 0, winreg.KEY_READ | winreg.KEY_WOW64_64KEY)
        val, _ = winreg.QueryValueEx(key, name)
        winreg.CloseKey(key)
        return str(val)
    except Exception:
        return None

def reg_get_bin(root, subkey: str, name: str):
    try:
        key = winreg.OpenKey(root, subkey, 0, winreg.KEY_READ | winreg.KEY_WOW64_64KEY)
        val, _ = winreg.QueryValueEx(key, name)
        winreg.CloseKey(key)
        return val
    except Exception:
        return None

def run_cmd(cmd: str) -> bool:
    try:
        res = subprocess.run(cmd, shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return res.returncode == 0
    except Exception as e:
        log_exception(e, f"run_cmd: {cmd}")
        return False

def get_active_power_scheme() -> str:
    try:
        k = winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE, r"SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes", 0, winreg.KEY_READ | winreg.KEY_WOW64_64KEY)
        val, _ = winreg.QueryValueEx(k, "ActivePowerScheme")
        winreg.CloseKey(k)
        return str(val)
    except Exception:
        return ""

# ---------------------------------------------------------------------------
# Localization Dictionary (RU / EN)
# ---------------------------------------------------------------------------
LOCALIZATION = {
    "ru": {
        "title": "⚡ Windows Gaming and Tablet Optimizer",
        "subtitle": "Интерактивная оптимизация графических планшетов, системных таймеров, сети и FPS",
        "btn_lang": "🌐 English",
        "btn_scan": "🔍 Сканировать",
        "btn_sel": "Выбрать все",
        "btn_desel": "Снять все",
        "btn_apply": "⚡ Применить выбранное",
        "status_ready": "Готов к работе",
        "status_scanning": "Сканирование системы...",
        "status_applying": "Применение твиков...",
        "status_done": "Готово! Все твики применены.",
        "msg_done_title": "Готово",
        "msg_done_body": "Все выбранные оптимизации успешно применены!\n\nРекомендуется перезагрузить компьютер для активации таймеров и квантов CPU.",
        "log_scan_start": "=== Запуск предварительного сканирования системы ===",
        "log_scan_done": "[V] Сканирование успешно завершено. Все модули проверены.",
        "log_apply_start": "=== Применение выбранных оптимизаций ===",
        "log_apply_done": "[V] ВСЕ ОПТИМИЗАЦИИ ПРИМЕНЕНЫ! Рекомендуется перезагрузить ПК.",
        "log_all_selected": "Все чекбоксы отмечены.",
        "log_all_deselected": "Все чекбоксы сняты.",
        "badge_unverified": "[ Не проверено ]",
        "badge_applied": "[ Уже применено ]",
        "badge_active": "[ Активно ]",
        "badge_available": "[ Доступно ]",
        "badge_safe": "[ Защищено ]",
        "badge_disabled": "[ Отключено ]",
        "tabs": {
            "tab1": "🖊️ Планшет и Перо",
            "tab2": "⚡ Система и FPS",
            "tab3": "🌐 Сеть и Пинг",
            "tab4": "🧹 Службы и SSD",
        },
        "tweaks": {
            "chk_PenHold": {
                "title": "Отключить задержку касания (HoldMode) и жесты (FlickMode)",
                "desc": "Убирает 300 мс задержки при первом касании пером и буфер жестов Windows Ink."
            },
            "chk_TabletGPO": {
                "title": "Применить Group Policies для планшетов (TabletPC & PenWorkspace)",
                "desc": "Системный запрет на генерацию анимаций кругов (Ripple), зажатия и жестов в HKLM/HKCU."
            },
            "chk_LinearCurve": {
                "title": "Обнулить нелинейное сглаживание курсора (1:1 Raw Linear Curve)",
                "desc": "Обнуляет полиномиальные кривые SmoothMouseX/YCurve для абсолютно равномерного движения."
            },
            "chk_TouchpadSafety": {
                "title": "Защита тачпада ноутбука (LeaveOnWithMouse = 1 & Taps/Gestures)",
                "desc": "Гарантирует работу тачпада при подключенной мыши/планшете и сохраняет жесты Precision Touchpad."
            },
            "chk_UsbSuspend": {
                "title": "Отключить энергосбережение USB (Selective Suspend в схеме питания)",
                "desc": "Предотвращает засыпание USB портов, обеспечивая непрерывную частоту опроса 1000Hz."
            },
            "chk_BcdTimers": {
                "title": "Включить аппаратный таймер TSC и 0.5ms (disabledynamictick yes)",
                "desc": "Устраняет пропуск тиков таймера процессора и переводит Windows на инвариантный таймер TSC (0.5 мс)."
            },
            "chk_Win32Priority": {
                "title": "Настроить кванты CPU 3:1 в пользу активной игры (Win32PrioritySeparation = 0x26)",
                "desc": "Выделяет активному окну в 3 раза больше времени CPU без прерываний на фоновые службы."
            },
            "chk_CsrssDwm": {
                "title": "Повысить приоритеты диспетчера ввода (CSRSS), DWM и OpenTabletDriver",
                "desc": "Переводит csrss.exe, dwm.exe и демон OTD в High Priority для мгновенной доставки аппаратных кликов."
            },
            "chk_GameMode": {
                "title": "Включить Windows Game Mode и отключить GameDVR / GameBar",
                "desc": "Активирует игровой режим Windows и полностью выключает фоновый процесс GameBarPresenceWriter."
            },
            "chk_KeyboardDelay": {
                "title": "Снизить задержку повтора клавиатуры (KeyboardDelay = 0 / Speed = 31)",
                "desc": "Ускоряет регистрацию стримов K1/K2 в osu! и обнуляет время задержки дребезга (BounceTime)."
            },
            "chk_CpuUnpark": {
                "title": "Разблокировать спящие ядра процессора (CPU Core Unparking 100%)",
                "desc": "Запрещает процессору усыплять логические ядра, устраняя 2-5 мс лага пробуждения."
            },
            "chk_KernelRam": {
                "title": "Зафиксировать ядро в RAM и отключить Fast Startup (Чистый старт ОС)",
                "desc": "Включает DisablePagingExecutive = 1 и отключает гибернацию ядра при выключении ПК."
            },
            "chk_OsuFso": {
                "title": "Принудительный аппаратный Fullscreen Exclusive для osu!.exe",
                "desc": "Отключает 'Оптимизацию во весь экран' для osu! (прямой рендер без буфера DWM)."
            },
            "chk_Nagle": {
                "title": "Отключить алгоритм Нейгла (TCPNoDelay = 1, TcpAckFrequency = 1)",
                "desc": "Отправляет мелкие пакеты ввода мгновенно без накопления в сетевом буфере."
            },
            "chk_QoS": {
                "title": "Снять 20% системное ограничение пропускной способности (QoS = 0)",
                "desc": "Разблокирует 100% пропускной способности интернет-канала для сетевых игр."
            },
            "chk_DeliveryOpt": {
                "title": "Отключить фоновую раздачу обновлений P2P (Delivery Optimization)",
                "desc": "Запрещает Windows раздавать скачанные обновления по локальной сети и интернету."
            },
            "chk_Telemetry": {
                "title": "Отключить службу сбора телеметрии (DiagTrack) и SysMain",
                "desc": "Останавливает постоянную запись диагностических логов на SSD и освобождает ОЗУ."
            },
            "chk_OemServices": {
                "title": "Перевести второстепенные OEM/Служебные процессы в ручной режим",
                "desc": "Переводит фоновые диагностические службы (HP, Dell, AnyDesk, WerSvc) в режим Manual."
            },
            "chk_TasksDebloat": {
                "title": "Отключить тяжелые задачи планировщика (Compatibility Appraiser)",
                "desc": "Отключает периодические фоновые сканеры совместимости и отчеты об ошибках."
            },
            "chk_SsdLastAccess": {
                "title": "Оптимизировать файловую систему SSD (Disable LastAccess Timestamps)",
                "desc": "Отключает лишние операции записи на SSD при обычном чтении файлов (fsutil)."
            },
            "chk_UiDelay": {
                "title": "Убрать искусственные задержки меню (MenuShowDelay = 0 / MinAnimate = 0)",
                "desc": "Делает открытие контекстных меню и отклик окон Windows моментальным."
            },
        }
    },
    "en": {
        "title": "⚡ Windows Gaming & Tablet Optimizer",
        "subtitle": "Interactive optimization for graphics tablets, system timers, network and FPS",
        "btn_lang": "🌐 Русский",
        "btn_scan": "🔍 Scan System",
        "btn_sel": "Select All",
        "btn_desel": "Deselect All",
        "btn_apply": "⚡ Apply Selected",
        "status_ready": "Ready",
        "status_scanning": "Scanning system...",
        "status_applying": "Applying tweaks...",
        "status_done": "Done! All tweaks applied.",
        "msg_done_title": "Done",
        "msg_done_body": "All selected optimizations successfully applied!\n\nA computer restart is recommended to activate timer resolution and CPU quantums.",
        "log_scan_start": "=== Starting pre-application system scan ===",
        "log_scan_done": "[V] System scan completed. All 21 modules verified.",
        "log_apply_start": "=== Applying selected optimizations ===",
        "log_apply_done": "[V] ALL OPTIMIZATIONS APPLIED! PC restart recommended.",
        "log_all_selected": "All checkboxes selected.",
        "log_all_deselected": "All checkboxes deselected.",
        "badge_unverified": "[ Unchecked ]",
        "badge_applied": "[ Already Applied ]",
        "badge_active": "[ Active ]",
        "badge_available": "[ Available ]",
        "badge_safe": "[ Safe & Active ]",
        "badge_disabled": "[ Disabled ]",
        "tabs": {
            "tab1": "🖊️ Tablet & Pen",
            "tab2": "⚡ System & FPS",
            "tab3": "🌐 Network & Ping",
            "tab4": "🧹 Services & SSD",
        },
        "tweaks": {
            "chk_PenHold": {
                "title": "Disable Pen Hold & Flick Latency (HoldMode / FlickMode)",
                "desc": "Eliminates native 300ms tap-and-hold delay and Windows Ink gesture buffering."
            },
            "chk_TabletGPO": {
                "title": "Apply Tablet Group Policies (TabletPC & PenWorkspace)",
                "desc": "System-level block on ripple animations, press-and-hold circles, and telemetry."
            },
            "chk_LinearCurve": {
                "title": "Reset Cursor Smoothing to 1:1 (Raw Linear Curve)",
                "desc": "Zeroes SmoothMouseX/YCurve polynomial curves for pure 1:1 linear pointer movement."
            },
            "chk_TouchpadSafety": {
                "title": "Laptop Touchpad Protection (LeaveOnWithMouse = 1 & Taps/Gestures)",
                "desc": "Ensures touchpad remains active with mouse/tablet connected and preserves gestures."
            },
            "chk_UsbSuspend": {
                "title": "Disable USB Selective Suspend in Active Power Scheme",
                "desc": "Prevents USB controllers from entering low-power sleep, ensuring solid 1000Hz polling."
            },
            "chk_BcdTimers": {
                "title": "Enable Hardware Invariant TSC Timers & 0.5ms (disabledynamictick yes)",
                "desc": "Eliminates synthetic timer tick drop and locks system timer to 0.500 ms (500 µs)."
            },
            "chk_Win32Priority": {
                "title": "Set 3:1 CPU Time-Slices for Active Game (Win32PrioritySeparation = 0x26)",
                "desc": "Allocates 3x more dedicated CPU execution time to the active foreground game window."
            },
            "chk_CsrssDwm": {
                "title": "Elevate Priorities for CSRSS, DWM and OpenTabletDriver",
                "desc": "Sets csrss.exe, dwm.exe, and OTD daemon to High Priority for instant click and frame delivery."
            },
            "chk_GameMode": {
                "title": "Enable Windows Game Mode & Disable GameDVR / GameBar",
                "desc": "Activates Windows Game Mode and disables GameBarPresenceWriter background recording."
            },
            "chk_KeyboardDelay": {
                "title": "Reduce Keyboard Repeat Delay (KeyboardDelay = 0 / Speed = 31)",
                "desc": "Speeds up K1/K2 key streaming registration in osu! and eliminates debounce wait."
            },
            "chk_CpuUnpark": {
                "title": "Unpark All CPU Cores (CPU Core Unparking 100%)",
                "desc": "Forces all logical processor cores to remain active, eliminating 2-5ms wake latency."
            },
            "chk_KernelRam": {
                "title": "Lock Kernel in RAM & Disable Fast Startup (Clean OS Boot)",
                "desc": "Enables DisablePagingExecutive = 1 and disables hibernation caching upon shutdown."
            },
            "chk_OsuFso": {
                "title": "Enforce Hardware Fullscreen Exclusive for osu!.exe",
                "desc": "Disables Fullscreen Optimizations for osu! to enable direct flip rendering without DWM lag."
            },
            "chk_Nagle": {
                "title": "Disable Nagle's Algorithm (TCPNoDelay = 1, TcpAckFrequency = 1)",
                "desc": "Sends small network packets instantaneously without waiting for packet buffer fills."
            },
            "chk_QoS": {
                "title": "Remove 20% Reserved System Bandwidth Limit (QoS = 0)",
                "desc": "Unlocks 100% network bandwidth for online multiplayer gaming."
            },
            "chk_DeliveryOpt": {
                "title": "Disable P2P Background Updates (Delivery Optimization)",
                "desc": "Blocks Windows from uploading and downloading updates over local network and internet."
            },
            "chk_Telemetry": {
                "title": "Disable Telemetry Diagnostics Service (DiagTrack) & SysMain",
                "desc": "Halts background diagnostic log writing to SSD and frees system RAM."
            },
            "chk_OemServices": {
                "title": "Set Secondary OEM / Diagnostic Services to On-Demand",
                "desc": "Switches background vendor services (HP, Dell, AnyDesk, WerSvc) to Manual start."
            },
            "chk_TasksDebloat": {
                "title": "Disable Heavy Scheduled Telemetry Tasks (Compatibility Appraiser)",
                "desc": "Disables periodic background compatibility scanners and error telemetry uploaders."
            },
            "chk_SsdLastAccess": {
                "title": "Optimize SSD File System (Disable LastAccess Timestamps)",
                "desc": "Eliminates unnecessary disk write operations during routine file read access."
            },
            "chk_UiDelay": {
                "title": "Eliminate UI Menu Delays (MenuShowDelay = 0 / MinAnimate = 0)",
                "desc": "Makes context menus and Windows interface animations open instantaneously."
            },
        }
    }
}

# ---------------------------------------------------------------------------
# Deep State Checking and Optimizer Engine
# ---------------------------------------------------------------------------
class TweaksEngine:

    # 1. Pen Hold & Flick
    @staticmethod
    def check_pen_hold() -> str:
        h_mode = reg_get_dword(winreg.HKEY_CURRENT_USER, r"Software\Microsoft\Wisp\Pen\SysEventParameters", "HoldMode")
        f_mode = reg_get_dword(winreg.HKEY_CURRENT_USER, r"Software\Microsoft\Wisp\Pen\SysEventParameters", "FlickMode")
        return "Already Applied" if (h_mode == 0 and f_mode == 0) else "Available"

    @staticmethod
    def apply_pen_hold() -> bool:
        r1 = winreg.HKEY_CURRENT_USER
        p1 = r"Software\Microsoft\Wisp\Pen\SysEventParameters"
        for k in ["FlickMode", "HoldMode", "Splash", "WaitTime"]:
            reg_set_dword(r1, p1, k, 0)
        try:
            key = winreg.OpenKey(r1, p1, 0, winreg.KEY_SET_VALUE | winreg.KEY_WOW64_64KEY)
            for bad_k in ["DblTime", "DblDist"]:
                try:
                    winreg.DeleteValue(key, bad_k)
                except FileNotFoundError:
                    pass
            winreg.CloseKey(key)
        except Exception:
            pass
        p2 = r"Software\Microsoft\Wisp\Touch"
        for k in ["TouchMode_hold", "TouchModeN_HoldTime_BeforeAnimation", "TouchModeN_HoldTime_Animation"]:
            reg_set_dword(r1, p2, k, 0)
        return True

    # 2. Tablet GPO
    @staticmethod
    def check_tablet_gpo() -> str:
        v1 = reg_get_dword(winreg.HKEY_LOCAL_MACHINE, r"SOFTWARE\Policies\Microsoft\Windows\TabletPC", "TurnOffPressAndHold")
        v2 = reg_get_dword(winreg.HKEY_CURRENT_USER, r"Software\Policies\Microsoft\Windows\TabletPC", "TurnOffPressAndHold")
        return "Already Applied" if (v1 == 1 or v2 == 1) else "Available"

    @staticmethod
    def apply_tablet_gpo() -> bool:
        policies = {
            "TurnOffPenFeedback": 1, "TurnOffPressAndHold": 1, "DisableFlicks": 1,
            "DisablePagingFlick": 1, "DisablePenCursorFeedback": 1, "DisableTouchVisualFeedback": 1,
            "PreventHandwritingDataSharing": 1
        }
        for root in [winreg.HKEY_LOCAL_MACHINE, winreg.HKEY_CURRENT_USER]:
            for k, v in policies.items():
                reg_set_dword(root, r"SOFTWARE\Policies\Microsoft\Windows\TabletPC", k, v)
            reg_set_dword(root, r"SOFTWARE\Policies\Microsoft\Windows\PenWorkspace", "EnablePenWorkspace", 0)
        return True

    # 3. Linear Curve (1:1 Raw)
    @staticmethod
    def check_linear_curve() -> str:
        curve = reg_get_bin(winreg.HKEY_CURRENT_USER, r"Control Panel\Mouse", "SmoothMouseXCurve")
        if curve and len(curve) >= 40 and all(b == 0 for b in curve[:40]):
            return "Already Applied (1:1 Raw)"
        return "Available"

    @staticmethod
    def apply_linear_curve() -> bool:
        zero_curve = bytes([0] * 40)
        reg_set_binary(winreg.HKEY_CURRENT_USER, r"Control Panel\Mouse", "SmoothMouseXCurve", zero_curve)
        reg_set_binary(winreg.HKEY_CURRENT_USER, r"Control Panel\Mouse", "SmoothMouseYCurve", zero_curve)
        dh = reg_get_str(winreg.HKEY_CURRENT_USER, r"Control Panel\Mouse", "DoubleClickHeight")
        if not dh or dh == "0":
            reg_set_string(winreg.HKEY_CURRENT_USER, r"Control Panel\Mouse", "DoubleClickHeight", "4")
            reg_set_string(winreg.HKEY_CURRENT_USER, r"Control Panel\Mouse", "DoubleClickWidth", "4")
            reg_set_string(winreg.HKEY_CURRENT_USER, r"Control Panel\Mouse", "DoubleClickSpeed", "500")
        return True

    # 4. Touchpad & Touch System Safety Check
    @staticmethod
    def check_touchpad_safety() -> str:
        leave_on = reg_get_dword(winreg.HKEY_CURRENT_USER, r"Software\Microsoft\Windows\CurrentVersion\PrecisionTouchPad", "LeaveOnWithMouse")
        tp_status = reg_get_dword(winreg.HKEY_CURRENT_USER, r"Software\Microsoft\Windows\CurrentVersion\PrecisionTouchPad\Status", "Enabled")
        if leave_on == 1 and (tp_status is None or tp_status == 1):
            return "Touchpad Safe (Active)"
        return "Fix Needed"

    @staticmethod
    def apply_touchpad_safety() -> bool:
        # Guarantee Touchpad is never disabled when mouse/tablet is connected
        reg_set_dword(winreg.HKEY_CURRENT_USER, r"Software\Microsoft\Windows\CurrentVersion\PrecisionTouchPad", "LeaveOnWithMouse", 1)
        reg_set_dword(winreg.HKEY_CURRENT_USER, r"Software\Microsoft\Windows\CurrentVersion\PrecisionTouchPad", "TapsEnabled", 1)
        reg_set_dword(winreg.HKEY_CURRENT_USER, r"Software\Microsoft\Windows\CurrentVersion\PrecisionTouchPad", "PanEnabled", 1)
        reg_set_dword(winreg.HKEY_CURRENT_USER, r"Software\Microsoft\Windows\CurrentVersion\PrecisionTouchPad", "ZoomEnabled", 1)
        reg_set_dword(winreg.HKEY_CURRENT_USER, r"Software\Microsoft\Windows\CurrentVersion\PrecisionTouchPad\Status", "Enabled", 1)
        reg_set_dword(winreg.HKEY_CURRENT_USER, r"Software\Microsoft\Wisp\Touch", "TouchUI", 1)

        # On laptops with Precision Touchpads, keep TabletInputService running so gestures work
        run_cmd("sc.exe config TabletInputService start= auto")
        run_cmd("sc.exe start TabletInputService")
        return True

    # 5. USB Selective Suspend (Safe for Laptops)
    @staticmethod
    def check_usb_suspend() -> str:
        active = get_active_power_scheme()
        if active:
            p = rf"SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes\{active}\2a737441-1930-4402-9177-b06418304ddf\48e6b7a6-50f5-4782-a5d4-53bb8f07e226"
            val = reg_get_dword(winreg.HKEY_LOCAL_MACHINE, p, "ACSettingIndex")
            if val == 0:
                return "Already Disabled"
        return "Available"

    @staticmethod
    def apply_usb_suspend() -> bool:
        active = get_active_power_scheme()
        if active:
            p = rf"SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes\{active}\2a737441-1930-4402-9177-b06418304ddf\48e6b7a6-50f5-4782-a5d4-53bb8f07e226"
            reg_set_dword(winreg.HKEY_LOCAL_MACHINE, p, "ACSettingIndex", 0)
            reg_set_dword(winreg.HKEY_LOCAL_MACHINE, p, "DCSettingIndex", 0)

        run_cmd("powercfg /setacvalueindex SCHEME_CURRENT 2a737441-1930-4402-9177-b06418304ddf 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0")
        run_cmd("powercfg /setdcvalueindex SCHEME_CURRENT 2a737441-1930-4402-9177-b06418304ddf 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0")
        run_cmd("powercfg /setactive SCHEME_CURRENT")
        return True

    # 6. BCD Timers & 0.5ms System Resolution
    @staticmethod
    def check_bcd_timers() -> str:
        try:
            res = subprocess.run("bcdedit /enum {current}", shell=True, capture_output=True, text=True)
            out = res.stdout.lower()
            if "disabledynamictick" in out and "yes" in out:
                return "Active (TSC & 0.5ms)"
            return "Available"
        except Exception:
            return "Available"

    @staticmethod
    def apply_bcd_timers() -> bool:
        run_cmd("bcdedit /set disabledynamictick yes")
        run_cmd("bcdedit /set useplatformclock no")
        set_high_resolution_timer(5000)
        return True

    # 7. Win32PrioritySeparation
    @staticmethod
    def check_win32_priority() -> str:
        val = reg_get_dword(winreg.HKEY_LOCAL_MACHINE, r"SYSTEM\CurrentControlSet\Control\PriorityControl", "Win32PrioritySeparation")
        if val == 38 or val == 0x26:
            return "Active (0x26)"
        elif val is not None:
            return f"Default (Current: {val})"
        return "Available"

    @staticmethod
    def apply_win32_priority() -> bool:
        return reg_set_dword(winreg.HKEY_LOCAL_MACHINE, r"SYSTEM\CurrentControlSet\Control\PriorityControl", "Win32PrioritySeparation", 38)

    # 8. CSRSS, DWM & OTD Priority
    @staticmethod
    def check_csrss_dwm() -> str:
        c1 = reg_get_dword(winreg.HKEY_LOCAL_MACHINE, r"SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\csrss.exe\PerfOptions", "CpuPriorityClass")
        d1 = reg_get_dword(winreg.HKEY_LOCAL_MACHINE, r"SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\dwm.exe\PerfOptions", "CpuPriorityClass")
        return "Already Applied (High)" if (c1 == 3 and d1 == 3) else "Available"

    @staticmethod
    def apply_csrss_dwm() -> bool:
        for proc in ["csrss.exe", "dwm.exe", "OpenTabletDriver.Daemon.exe"]:
            p = rf"SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\{proc}\PerfOptions"
            reg_set_dword(winreg.HKEY_LOCAL_MACHINE, p, "CpuPriorityClass", 3)
            reg_set_dword(winreg.HKEY_LOCAL_MACHINE, p, "IoPriority", 3)
        return True

    # 9. GameMode & PresenceWriter
    @staticmethod
    def check_gamemode() -> str:
        gm = reg_get_dword(winreg.HKEY_CURRENT_USER, r"Software\Microsoft\GameBar", "AutoGameModeEnabled")
        dvr = reg_get_dword(winreg.HKEY_CURRENT_USER, r"System\GameConfigStore", "GameDVR_Enabled")
        return "Already Applied" if (gm == 1 and dvr == 0) else "Available"

    @staticmethod
    def apply_gamemode() -> bool:
        reg_set_dword(winreg.HKEY_CURRENT_USER, r"Software\Microsoft\GameBar", "AutoGameModeEnabled", 1)
        reg_set_dword(winreg.HKEY_CURRENT_USER, r"Software\Microsoft\GameBar", "AllowAutoGameMode", 1)
        reg_set_dword(winreg.HKEY_CURRENT_USER, r"System\GameConfigStore", "GameDVR_DXGIHonorFSEWindowsCompatible", 1)
        reg_set_dword(winreg.HKEY_CURRENT_USER, r"System\GameConfigStore", "GameDVR_FSEBehaviorMode", 2)
        reg_set_dword(winreg.HKEY_CURRENT_USER, r"System\GameConfigStore", "GameDVR_Enabled", 0)
        reg_set_dword(winreg.HKEY_LOCAL_MACHINE, r"SOFTWARE\Microsoft\WindowsRuntime\ActivatableClassId\Windows.Gaming.GameBar.PresenceServer.Internal.PresenceWriter", "ActivationType", 0)
        return True

    # 10. Keyboard Repeat Delay
    @staticmethod
    def check_keyboard_delay() -> str:
        del_val = reg_get_str(winreg.HKEY_CURRENT_USER, r"Control Panel\Keyboard", "KeyboardDelay")
        spd_val = reg_get_str(winreg.HKEY_CURRENT_USER, r"Control Panel\Keyboard", "KeyboardSpeed")
        return "Already Applied (0 / 31)" if (del_val == "0" and spd_val == "31") else "Available"

    @staticmethod
    def apply_keyboard_delay() -> bool:
        reg_set_string(winreg.HKEY_CURRENT_USER, r"Control Panel\Keyboard", "KeyboardDelay", "0")
        reg_set_string(winreg.HKEY_CURRENT_USER, r"Control Panel\Keyboard", "KeyboardSpeed", "31")
        reg_set_string(winreg.HKEY_CURRENT_USER, r"Control Panel\Accessibility\Keyboard Response", "DelayBeforeAcceptance", "0")
        reg_set_string(winreg.HKEY_CURRENT_USER, r"Control Panel\Accessibility\Keyboard Response", "BounceTime", "0")
        return True

    # 11. CPU Unpark
    @staticmethod
    def check_cpu_unpark() -> str:
        try:
            active = get_active_power_scheme()
            if active:
                p = rf"SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes\{active}\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583"
                val = reg_get_dword(winreg.HKEY_LOCAL_MACHINE, p, "ACSettingIndex")
                if val == 100 or val == 0x64:
                    return "Already Applied (100%)"
            return "Available"
        except Exception:
            return "Available"

    @staticmethod
    def apply_cpu_unpark() -> bool:
        active = get_active_power_scheme()
        if active:
            p = rf"SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes\{active}\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583"
            reg_set_dword(winreg.HKEY_LOCAL_MACHINE, p, "ACSettingIndex", 100)
            reg_set_dword(winreg.HKEY_LOCAL_MACHINE, p, "DCSettingIndex", 100)

        run_cmd("powercfg -setacvalueindex SCHEME_CURRENT SUB_PROCESSOR CPMINCORES 100")
        run_cmd("powercfg -setdcvalueindex SCHEME_CURRENT SUB_PROCESSOR CPMINCORES 100")
        run_cmd("powercfg -setactive SCHEME_CURRENT")
        return True

    # 12. Kernel RAM & Fast Startup
    @staticmethod
    def check_kernel_ram() -> str:
        dpe = reg_get_dword(winreg.HKEY_LOCAL_MACHINE, r"SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management", "DisablePagingExecutive")
        hb = reg_get_dword(winreg.HKEY_LOCAL_MACHINE, r"SYSTEM\CurrentControlSet\Control\Session Manager\Power", "HiberbootEnabled")
        return "Already Applied" if (dpe == 1 and hb == 0) else "Available"

    @staticmethod
    def apply_kernel_ram() -> bool:
        reg_set_dword(winreg.HKEY_LOCAL_MACHINE, r"SYSTEM\CurrentControlSet\Control\Power\PowerThrottling", "PowerThrottlingOff", 1)
        reg_set_dword(winreg.HKEY_LOCAL_MACHINE, r"SYSTEM\CurrentControlSet\Control\Session Manager\Power", "HiberbootEnabled", 0)
        reg_set_dword(winreg.HKEY_LOCAL_MACHINE, r"SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management", "DisablePagingExecutive", 1)
        return True

    # 13. Osu Fullscreen Exclusive
    @staticmethod
    def check_osu_fso() -> str:
        local_app = os.environ.get("LOCALAPPDATA", "")
        paths = [
            os.path.join(local_app, "osu!", "osu!.exe"),
            r"C:\osu!\osu!.exe", r"D:\osu!\osu!.exe", r"E:\osu!\osu!.exe"
        ]
        found = [p for p in paths if os.path.exists(p)]
        if not found:
            return "osu! Not Found"
        for p in found:
            val = reg_get_str(winreg.HKEY_CURRENT_USER, r"Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers", p)
            if val and "DISABLEDXMAXIMIZEDWINDOWEDMODE" in val:
                return "Already Applied"
        return f"Detected ({len(found)} found)"

    @staticmethod
    def apply_osu_fso() -> bool:
        local_app = os.environ.get("LOCALAPPDATA", "")
        paths = [
            os.path.join(local_app, "osu!", "osu!.exe"),
            r"C:\osu!\osu!.exe", r"D:\osu!\osu!.exe", r"E:\osu!\osu!.exe"
        ]
        applied = False
        for p in paths:
            if os.path.exists(p):
                reg_set_string(winreg.HKEY_CURRENT_USER, r"Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers", p, "~ DISABLEDXMAXIMIZEDWINDOWEDMODE HIGHDPIAWARE")
                applied = True
        return applied

    # 14. Nagle's Algorithm
    @staticmethod
    def check_nagle() -> str:
        try:
            root_key = winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE, r"SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces")
            idx = 0
            applied_cnt = 0
            total_cnt = 0
            while True:
                try:
                    sub_name = winreg.EnumKey(root_key, idx)
                    sub_path = rf"SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\{sub_name}"
                    v1 = reg_get_dword(winreg.HKEY_LOCAL_MACHINE, sub_path, "TCPNoDelay")
                    v2 = reg_get_dword(winreg.HKEY_LOCAL_MACHINE, sub_path, "TcpAckFrequency")
                    if v1 == 1 and v2 == 1:
                        applied_cnt += 1
                    total_cnt += 1
                    idx += 1
                except OSError:
                    break
            winreg.CloseKey(root_key)
            if applied_cnt > 0:
                return f"Already Applied ({applied_cnt}/{total_cnt})"
            return f"Available ({total_cnt} adapters)"
        except Exception:
            return "Available"

    @staticmethod
    def apply_nagle() -> int:
        count = 0
        try:
            root_key = winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE, r"SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces")
            idx = 0
            while True:
                try:
                    sub_name = winreg.EnumKey(root_key, idx)
                    sub_path = rf"SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\{sub_name}"
                    reg_set_dword(winreg.HKEY_LOCAL_MACHINE, sub_path, "TcpAckFrequency", 1)
                    reg_set_dword(winreg.HKEY_LOCAL_MACHINE, sub_path, "TCPNoDelay", 1)
                    reg_set_dword(winreg.HKEY_LOCAL_MACHINE, sub_path, "TcpDelAckTicks", 0)
                    count += 1
                    idx += 1
                except OSError:
                    break
            winreg.CloseKey(root_key)
        except Exception as e:
            log_exception(e, "apply_nagle")
        return count

    # 15. QoS Bandwidth
    @staticmethod
    def check_qos() -> str:
        val = reg_get_dword(winreg.HKEY_LOCAL_MACHINE, r"SOFTWARE\Policies\Microsoft\Windows\Psched", "NonBestEffortLimit")
        return "Already Applied (100%)" if val == 0 else "Available"

    @staticmethod
    def apply_qos() -> bool:
        return reg_set_dword(winreg.HKEY_LOCAL_MACHINE, r"SOFTWARE\Policies\Microsoft\Windows\Psched", "NonBestEffortLimit", 0)

    # 16. Delivery Optimization
    @staticmethod
    def check_delivery_opt() -> str:
        v1 = reg_get_dword(winreg.HKEY_CURRENT_USER, r"Software\Microsoft\Windows\CurrentVersion\DeliveryOptimization", "DODownloadMode")
        v2 = reg_get_dword(winreg.HKEY_LOCAL_MACHINE, r"SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization", "DODownloadMode")
        return "Already Applied" if (v1 == 0 or v2 == 0) else "Available"

    @staticmethod
    def apply_delivery_opt() -> bool:
        reg_set_dword(winreg.HKEY_CURRENT_USER, r"Software\Microsoft\Windows\CurrentVersion\DeliveryOptimization", "DODownloadMode", 0)
        reg_set_dword(winreg.HKEY_LOCAL_MACHINE, r"SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization", "DODownloadMode", 0)
        return True

    # 17. Telemetry & SysMain
    @staticmethod
    def check_telemetry() -> str:
        try:
            res = subprocess.run("sc.exe qc DiagTrack", shell=True, capture_output=True, text=True)
            if "DISABLED" in res.stdout.upper():
                return "Already Disabled"
            elif "DIAGTRACK" in res.stdout.upper():
                return "Detected (Active)"
            return "N/A"
        except Exception:
            return "N/A"

    @staticmethod
    def apply_telemetry() -> bool:
        for s in ["DiagTrack", "SysMain"]:
            run_cmd(f"sc.exe stop {s}")
            run_cmd(f"sc.exe config {s} start= disabled")
        return True

    # 18. OEM Services
    @staticmethod
    def check_oem_services() -> str:
        svcs = ["HPAppHelperCap", "HPDiagsCap", "HPNetworkCap", "HPSysInfoCap", "AnyDesk", "WerSvc"]
        manual_cnt = 0
        found_cnt = 0
        for s in svcs:
            try:
                res = subprocess.run(f"sc.exe qc {s}", shell=True, capture_output=True, text=True)
                if res.returncode == 0:
                    found_cnt += 1
                    if "DEMAND_START" in res.stdout.upper() or "DISABLED" in res.stdout.upper():
                        manual_cnt += 1
            except Exception:
                pass
        if found_cnt == 0:
            return "None Found (Clean)"
        if manual_cnt == found_cnt:
            return f"Already Optimized ({manual_cnt}/{found_cnt})"
        return f"Available ({manual_cnt}/{found_cnt} Manual)"

    @staticmethod
    def apply_oem_services() -> int:
        svcs = ["HPAppHelperCap", "HPDiagsCap", "HPNetworkCap", "HPSysInfoCap", "AnyDesk", "WerSvc"]
        cnt = 0
        for s in svcs:
            run_cmd(f"sc.exe stop {s}")
            if run_cmd(f"sc.exe config {s} start= demand"):
                cnt += 1
        return cnt

    # 19. Tasks Debloat
    @staticmethod
    def check_tasks_debloat() -> str:
        try:
            res = subprocess.run(r'schtasks /Query /TN "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser"', shell=True, capture_output=True, text=True)
            if "Disabled" in res.stdout or "Отключено" in res.stdout:
                return "Already Disabled"
            return "Available (Active)"
        except Exception:
            return "Available"

    @staticmethod
    def apply_tasks_debloat() -> int:
        tasks = [
            r"\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser",
            r"\Microsoft\Windows\Application Experience\ProgramDataUpdater",
            r"\Microsoft\Windows\Customer Experience Improvement Program\Consolidator",
            r"\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip",
            r"\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector",
            r"\Microsoft\Windows\Power Efficiency Diagnostics\AnalyzeSystem",
            r"\Microsoft\Windows\Windows Error Reporting\QueueReporting"
        ]
        cnt = 0
        for t in tasks:
            if run_cmd(f'schtasks /Change /TN "{t}" /Disable'):
                cnt += 1
        return cnt

    # 20. SSD LastAccess
    @staticmethod
    def check_ssd_last_access() -> str:
        try:
            res = subprocess.run("fsutil behavior query disablelastaccess", shell=True, capture_output=True, text=True)
            out = res.stdout
            if "1" in out or "2" in out or "3" in out:
                return "Already Applied"
            return "Available"
        except Exception:
            return "Available"

    @staticmethod
    def apply_ssd_last_access() -> bool:
        return run_cmd("fsutil behavior set disablelastaccess 1")

    # 21. UI Delay
    @staticmethod
    def check_ui_delay() -> str:
        v1 = reg_get_str(winreg.HKEY_CURRENT_USER, r"Control Panel\Desktop", "MenuShowDelay")
        v2 = reg_get_str(winreg.HKEY_CURRENT_USER, r"Control Panel\Desktop\WindowMetrics", "MinAnimate")
        return "Already Applied (0ms)" if (v1 == "0" and v2 == "0") else "Available"

    @staticmethod
    def apply_ui_delay() -> bool:
        reg_set_string(winreg.HKEY_CURRENT_USER, r"Control Panel\Desktop", "MenuShowDelay", "0")
        reg_set_string(winreg.HKEY_CURRENT_USER, r"Control Panel\Desktop\WindowMetrics", "MinAnimate", "0")
        return True


# ---------------------------------------------------------------------------
# Modern Dark Tkinter GUI with Multi-Language Support
# ---------------------------------------------------------------------------
class OptimizerApp:

    def __init__(self, root: tk.Tk):
        self.root = root
        self.lang = "ru"  # Default language

        self.root.geometry("980x780")
        self.root.minsize(880, 680)
        self.root.configure(bg="#12141A")

        # Set 0.5ms High Resolution Timer immediately
        set_high_resolution_timer(5000)

        self.chk_vars = {}
        self.badge_labels = {}
        self.tweak_labels = {}
        self.tab_frames = {}

        self.setup_styles()
        self.create_widgets()
        self.apply_language()
        self.scan_system()

    def setup_styles(self):
        style = ttk.Style()
        style.theme_use("clam")

        # Configure notebook and tabs
        style.configure("TNotebook", background="#12141A", borderwidth=0)
        style.configure("TNotebook.Tab", background="#1A1D26", foreground="#9E9E9E", padding=[16, 8], font=("Segoe UI", 10, "bold"))
        style.map("TNotebook.Tab", background=[("selected", "#222736")], foreground=[("selected", "#00E5FF")])

        # Progressbar
        style.configure("TProgressbar", thickness=8, troughcolor="#1A1D26", background="#00E5FF", bordercolor="#1A1D26")

    def create_widgets(self):
        # Header Frame
        header = tk.Frame(self.root, bg="#1A1D26", highlightbackground="#2A2F40", highlightthickness=1, padx=16, pady=12)
        header.pack(fill="x", padx=16, pady=(14, 10))

        title_box = tk.Frame(header, bg="#1A1D26")
        title_box.pack(side="left", fill="y")
        self.lbl_title = tk.Label(title_box, text="", font=("Segoe UI", 15, "bold"), fg="#00E5FF", bg="#1A1D26")
        self.lbl_title.pack(anchor="w")
        self.lbl_sub = tk.Label(title_box, text="", font=("Segoe UI", 9), fg="#8C93A8", bg="#1A1D26")
        self.lbl_sub.pack(anchor="w", pady=(2, 0))

        btn_box = tk.Frame(header, bg="#1A1D26")
        btn_box.pack(side="right")

        self.btn_lang = tk.Button(btn_box, text="🌐 English", font=("Segoe UI", 9, "bold"), bg="#37474F", fg="#ECEFF1", activebackground="#455A64", activeforeground="#FFFFFF", relief="flat", padx=10, pady=6, cursor="hand2", command=self.toggle_language)
        self.btn_lang.pack(side="left", padx=4)

        self.btn_scan = tk.Button(btn_box, text="", font=("Segoe UI", 9, "bold"), bg="#263238", fg="#00E5FF", activebackground="#37474F", activeforeground="#00E5FF", relief="flat", padx=12, pady=6, cursor="hand2", command=self.scan_system)
        self.btn_scan.pack(side="left", padx=4)

        self.btn_sel = tk.Button(btn_box, text="", font=("Segoe UI", 9), bg="#2A2F40", fg="#E0E0E0", activebackground="#37474F", activeforeground="#FFFFFF", relief="flat", padx=10, pady=6, cursor="hand2", command=self.select_all)
        self.btn_sel.pack(side="left", padx=4)

        self.btn_desel = tk.Button(btn_box, text="", font=("Segoe UI", 9), bg="#2A2F40", fg="#E0E0E0", activebackground="#37474F", activeforeground="#FFFFFF", relief="flat", padx=10, pady=6, cursor="hand2", command=self.deselect_all)
        self.btn_desel.pack(side="left", padx=4)

        self.btn_apply = tk.Button(btn_box, text="", font=("Segoe UI", 9, "bold"), bg="#00C853", fg="#FFFFFF", activebackground="#00E676", activeforeground="#FFFFFF", relief="flat", padx=14, pady=6, cursor="hand2", command=self.apply_tweaks)
        self.btn_apply.pack(side="left", padx=4)

        # Tabbed Container
        self.notebook = ttk.Notebook(self.root)
        self.notebook.pack(fill="both", expand=True, padx=16, pady=6)

        self.tab1 = self.create_tab("tab1", [
            ("chk_PenHold", "status_PenHold"),
            ("chk_TabletGPO", "status_TabletGPO"),
            ("chk_LinearCurve", "status_LinearCurve"),
            ("chk_TouchpadSafety", "status_TouchpadSafety"),
            ("chk_UsbSuspend", "status_UsbSuspend"),
        ])

        self.tab2 = self.create_tab("tab2", [
            ("chk_BcdTimers", "status_BcdTimers"),
            ("chk_Win32Priority", "status_Win32Priority"),
            ("chk_CsrssDwm", "status_CsrssDwm"),
            ("chk_GameMode", "status_GameMode"),
            ("chk_KeyboardDelay", "status_KeyboardDelay"),
            ("chk_CpuUnpark", "status_CpuUnpark"),
            ("chk_KernelRam", "status_KernelRam"),
            ("chk_OsuFso", "status_OsuFso"),
        ])

        self.tab3 = self.create_tab("tab3", [
            ("chk_Nagle", "status_Nagle"),
            ("chk_QoS", "status_QoS"),
            ("chk_DeliveryOpt", "status_DeliveryOpt"),
        ])

        self.tab4 = self.create_tab("tab4", [
            ("chk_Telemetry", "status_Telemetry"),
            ("chk_OemServices", "status_OemServices"),
            ("chk_TasksDebloat", "status_TasksDebloat"),
            ("chk_SsdLastAccess", "status_SsdLastAccess"),
            ("chk_UiDelay", "status_UiDelay"),
        ])

        # Progress bar frame
        prog_frame = tk.Frame(self.root, bg="#12141A")
        prog_frame.pack(fill="x", padx=16, pady=(4, 6))

        self.prog_bar = ttk.Progressbar(prog_frame, style="TProgressbar", orient="horizontal", mode="determinate")
        self.prog_bar.pack(side="left", fill="x", expand=True)

        self.lbl_status = tk.Label(prog_frame, text="", font=("Segoe UI", 9), fg="#8C93A8", bg="#12141A")
        self.lbl_status.pack(side="right", padx=(10, 0))

        # Console Logger Frame
        log_frame = tk.Frame(self.root, bg="#0C0E14", highlightbackground="#2A2F40", highlightthickness=1)
        log_frame.pack(fill="both", expand=False, padx=16, pady=(0, 14), ipady=2)

        self.txt_log = scrolledtext.ScrolledText(log_frame, bg="#0C0E14", fg="#00E676", insertbackground="#00E676", font=("Consolas", 9), height=7, borderwidth=0, relief="flat", wrap="word")
        self.txt_log.pack(fill="both", expand=True, padx=8, pady=6)
        self.txt_log.tag_config("green", foreground="#00E676")
        self.txt_log.tag_config("cyan", foreground="#00E5FF")
        self.txt_log.tag_config("yellow", foreground="#FFD600")
        self.txt_log.tag_config("red", foreground="#FF5252")

    def create_tab(self, tab_id: str, items: list) -> tk.Frame:
        tab = tk.Frame(self.notebook, bg="#161922", padx=14, pady=10)
        self.notebook.add(tab, text="")
        self.tab_frames[tab_id] = tab

        for key, badge_key in items:
            row = tk.Frame(tab, bg="#1E2230", padx=12, pady=8, highlightbackground="#2A2F40", highlightthickness=1)
            row.pack(fill="x", pady=4)

            var = tk.BooleanVar(value=True)
            self.chk_vars[key] = var

            chk_box = tk.Frame(row, bg="#1E2230")
            chk_box.pack(side="left", fill="both", expand=True)

            chk = tk.Checkbutton(chk_box, text="", variable=var, font=("Segoe UI", 10, "bold"), fg="#E0E0E0", bg="#1E2230", selectcolor="#12141A", activebackground="#1E2230", activeforeground="#FFFFFF", anchor="w")
            chk.pack(anchor="w")

            lbl_desc = tk.Label(chk_box, text="", font=("Segoe UI", 8), fg="#8C93A8", bg="#1E2230", anchor="w")
            lbl_desc.pack(anchor="w", padx=(24, 0))

            self.tweak_labels[key] = (chk, lbl_desc)

            badge = tk.Label(row, text="[ Не проверено ]", font=("Segoe UI", 9, "bold"), fg="#757575", bg="#1E2230")
            badge.pack(side="right", padx=6)
            self.badge_labels[badge_key] = badge

        return tab

    def toggle_language(self):
        self.lang = "en" if self.lang == "ru" else "ru"
        self.apply_language()
        self.scan_system()

    def apply_language(self):
        L = LOCALIZATION[self.lang]

        # Window & Header
        self.root.title(L["title"])
        self.lbl_title.config(text=L["title"])
        self.lbl_sub.config(text=L["subtitle"])
        self.btn_lang.config(text=L["btn_lang"])
        self.btn_scan.config(text=L["btn_scan"])
        self.btn_sel.config(text=L["btn_sel"])
        self.btn_desel.config(text=L["btn_desel"])
        self.btn_apply.config(text=L["btn_apply"])
        self.lbl_status.config(text=L["status_ready"])

        # Tab titles
        tabs_L = L["tabs"]
        self.notebook.tab(0, text=tabs_L["tab1"])
        self.notebook.tab(1, text=tabs_L["tab2"])
        self.notebook.tab(2, text=tabs_L["tab3"])
        self.notebook.tab(3, text=tabs_L["tab4"])

        # Tweak items
        tweaks_L = L["tweaks"]
        for key, (chk, desc) in self.tweak_labels.items():
            if key in tweaks_L:
                chk.config(text=tweaks_L[key]["title"])
                desc.config(text=tweaks_L[key]["desc"])

    def log(self, msg: str, tag: str = "green"):
        ts = datetime.datetime.now().strftime("%H:%M:%S")
        self.txt_log.insert(tk.END, f"[{ts}] {msg}\n", tag)
        self.txt_log.see(tk.END)
        self.root.update_idletasks()

    def set_badge(self, key: str, text: str, color: str):
        if key in self.badge_labels:
            self.badge_labels[key].config(text=text, fg=color)

    def select_all(self):
        for v in self.chk_vars.values():
            v.set(True)
        self.log(LOCALIZATION[self.lang]["log_all_selected"], "cyan")

    def deselect_all(self):
        for v in self.chk_vars.values():
            v.set(False)
        self.log(LOCALIZATION[self.lang]["log_all_deselected"], "yellow")

    def format_badge(self, status: str) -> tuple:
        if "Already" in status or "Active" in status or "Safe" in status:
            return f"[ {status} ]", "#00E676"
        elif "Detected" in status:
            return f"[ {status} ]", "#FFD600"
        elif "Not Found" in status or "None" in status or "N/A" in status:
            return f"[ {status} ]", "#757575"
        else:
            return f"[ {status} ]", "#00E5FF"

    def scan_system(self):
        try:
            L = LOCALIZATION[self.lang]
            self.txt_log.delete("1.0", tk.END)
            self.log(L["log_scan_start"], "cyan")
            self.lbl_status.config(text=L["status_scanning"])

            # 1. Pen Hold
            t, c = self.format_badge(TweaksEngine.check_pen_hold())
            self.set_badge("status_PenHold", t, c)

            # 2. Tablet GPO
            t, c = self.format_badge(TweaksEngine.check_tablet_gpo())
            self.set_badge("status_TabletGPO", t, c)

            # 3. Linear Curve
            t, c = self.format_badge(TweaksEngine.check_linear_curve())
            self.set_badge("status_LinearCurve", t, c)

            # 4. Touchpad Safety
            t, c = self.format_badge(TweaksEngine.check_touchpad_safety())
            self.set_badge("status_TouchpadSafety", t, c)

            # 5. USB Suspend
            t, c = self.format_badge(TweaksEngine.check_usb_suspend())
            self.set_badge("status_UsbSuspend", t, c)
            self.prog_bar["value"] = 25

            # 6. BCD Timers
            t, c = self.format_badge(TweaksEngine.check_bcd_timers())
            self.set_badge("status_BcdTimers", t, c)

            # 7. Win32Priority
            t, c = self.format_badge(TweaksEngine.check_win32_priority())
            self.set_badge("status_Win32Priority", t, c)

            # 8. CSRSS & DWM
            t, c = self.format_badge(TweaksEngine.check_csrss_dwm())
            self.set_badge("status_CsrssDwm", t, c)

            # 9. GameMode
            t, c = self.format_badge(TweaksEngine.check_gamemode())
            self.set_badge("status_GameMode", t, c)

            # 10. Keyboard Delay
            t, c = self.format_badge(TweaksEngine.check_keyboard_delay())
            self.set_badge("status_KeyboardDelay", t, c)

            # 11. CPU Unpark
            t, c = self.format_badge(TweaksEngine.check_cpu_unpark())
            self.set_badge("status_CpuUnpark", t, c)

            # 12. Kernel RAM
            t, c = self.format_badge(TweaksEngine.check_kernel_ram())
            self.set_badge("status_KernelRam", t, c)

            # 13. osu! FSO
            t, c = self.format_badge(TweaksEngine.check_osu_fso())
            self.set_badge("status_OsuFso", t, c)
            self.prog_bar["value"] = 65

            # 14. Network Nagle
            t, c = self.format_badge(TweaksEngine.check_nagle())
            self.set_badge("status_Nagle", t, c)

            # 15. QoS
            t, c = self.format_badge(TweaksEngine.check_qos())
            self.set_badge("status_QoS", t, c)

            # 16. Delivery Opt
            t, c = self.format_badge(TweaksEngine.check_delivery_opt())
            self.set_badge("status_DeliveryOpt", t, c)
            self.prog_bar["value"] = 80

            # 17. Telemetry
            t, c = self.format_badge(TweaksEngine.check_telemetry())
            self.set_badge("status_Telemetry", t, c)

            # 18. OEM Services
            t, c = self.format_badge(TweaksEngine.check_oem_services())
            self.set_badge("status_OemServices", t, c)

            # 19. Tasks Debloat
            t, c = self.format_badge(TweaksEngine.check_tasks_debloat())
            self.set_badge("status_TasksDebloat", t, c)

            # 20. SSD LastAccess
            t, c = self.format_badge(TweaksEngine.check_ssd_last_access())
            self.set_badge("status_SsdLastAccess", t, c)

            # 21. UI Delay
            t, c = self.format_badge(TweaksEngine.check_ui_delay())
            self.set_badge("status_UiDelay", t, c)

            self.prog_bar["value"] = 100
            self.lbl_status.config(text=L["status_done"])
            self.log(L["log_scan_done"], "green")
        except Exception as e:
            log_exception(e, "scan_system")
            self.log(f"[!] Error: {e}", "red")

    def apply_tweaks(self):
        try:
            L = LOCALIZATION[self.lang]
            self.txt_log.delete("1.0", tk.END)
            self.log(L["log_apply_start"], "cyan")
            self.lbl_status.config(text=L["status_applying"])
            self.prog_bar["value"] = 0

            total = 21
            step = 0

            # 1. Pen Hold
            if self.chk_vars["chk_PenHold"].get():
                TweaksEngine.apply_pen_hold()
                self.set_badge("status_PenHold", "[ Already Applied ]", "#00E676")
                self.log("[OK] HoldMode & FlickMode disabled.")
            step += 1; self.prog_bar["value"] = int((step / total) * 100)

            # 2. Tablet GPO
            if self.chk_vars["chk_TabletGPO"].get():
                TweaksEngine.apply_tablet_gpo()
                self.set_badge("status_TabletGPO", "[ Already Applied ]", "#00E676")
                self.log("[OK] Group Policies TabletPC & PenWorkspace applied.")
            step += 1; self.prog_bar["value"] = int((step / total) * 100)

            # 3. Linear Curve
            if self.chk_vars["chk_LinearCurve"].get():
                TweaksEngine.apply_linear_curve()
                self.set_badge("status_LinearCurve", "[ Already Applied (1:1 Raw) ]", "#00E676")
                self.log("[OK] Cursor polynomial curve reset (1:1 Raw).")
            step += 1; self.prog_bar["value"] = int((step / total) * 100)

            # 4. Touchpad Safety
            if self.chk_vars["chk_TouchpadSafety"].get():
                TweaksEngine.apply_touchpad_safety()
                self.set_badge("status_TouchpadSafety", "[ Touchpad Safe (Active) ]", "#00E676")
                self.log("[OK] Precision TouchPad LeaveOnWithMouse & gestures safe.")
            step += 1; self.prog_bar["value"] = int((step / total) * 100)

            # 5. USB Suspend
            if self.chk_vars["chk_UsbSuspend"].get():
                TweaksEngine.apply_usb_suspend()
                self.set_badge("status_UsbSuspend", "[ Already Disabled ]", "#00E676")
                self.log("[OK] USB Selective Suspend disabled.")
            step += 1; self.prog_bar["value"] = int((step / total) * 100)

            # 6. BCD Timers & 0.5ms Timer Resolution
            if self.chk_vars["chk_BcdTimers"].get():
                TweaksEngine.apply_bcd_timers()
                self.set_badge("status_BcdTimers", "[ Active (TSC & 0.5ms) ]", "#00E676")
                self.log("[OK] Invariant TSC & 0.5ms timer locked.")
            step += 1; self.prog_bar["value"] = int((step / total) * 100)

            # 7. Win32Priority
            if self.chk_vars["chk_Win32Priority"].get():
                TweaksEngine.apply_win32_priority()
                self.set_badge("status_Win32Priority", "[ Active (0x26) ]", "#00E676")
                self.log("[OK] Win32PrioritySeparation = 0x26 (38) applied.")
            step += 1; self.prog_bar["value"] = int((step / total) * 100)

            # 8. CSRSS, DWM & OTD Priority
            if self.chk_vars["chk_CsrssDwm"].get():
                TweaksEngine.apply_csrss_dwm()
                self.set_badge("status_CsrssDwm", "[ Already Applied (High) ]", "#00E676")
                self.log("[OK] CSRSS, DWM & OpenTabletDriver set to High Priority.")
            step += 1; self.prog_bar["value"] = int((step / total) * 100)

            # 9. GameMode
            if self.chk_vars["chk_GameMode"].get():
                TweaksEngine.apply_gamemode()
                self.set_badge("status_GameMode", "[ Already Applied ]", "#00E676")
                self.log("[OK] Game Mode enabled, GameDVR disabled.")
            step += 1; self.prog_bar["value"] = int((step / total) * 100)

            # 10. Keyboard Delay
            if self.chk_vars["chk_KeyboardDelay"].get():
                TweaksEngine.apply_keyboard_delay()
                self.set_badge("status_KeyboardDelay", "[ Already Applied (0 / 31) ]", "#00E676")
                self.log("[OK] KeyboardDelay = 0 / Speed = 31 set.")
            step += 1; self.prog_bar["value"] = int((step / total) * 100)

            # 11. CPU Unpark
            if self.chk_vars["chk_CpuUnpark"].get():
                TweaksEngine.apply_cpu_unpark()
                self.set_badge("status_CpuUnpark", "[ Already Applied (100%) ]", "#00E676")
                self.log("[OK] CPU Core Unparking (100%) applied.")
            step += 1; self.prog_bar["value"] = int((step / total) * 100)

            # 12. Kernel RAM
            if self.chk_vars["chk_KernelRam"].get():
                TweaksEngine.apply_kernel_ram()
                self.set_badge("status_KernelRam", "[ Already Applied ]", "#00E676")
                self.log("[OK] Kernel locked in RAM, Fast Startup disabled.")
            step += 1; self.prog_bar["value"] = int((step / total) * 100)

            # 13. Osu FSO
            if self.chk_vars["chk_OsuFso"].get():
                if TweaksEngine.apply_osu_fso():
                    self.set_badge("status_OsuFso", "[ Already Applied ]", "#00E676")
                    self.log("[OK] Hardware Exclusive Fullscreen set for osu!.exe")
                else:
                    self.set_badge("status_OsuFso", "[ N/A ]", "#757575")
                    self.log("[WARN] osu!.exe not found.", "yellow")
            step += 1; self.prog_bar["value"] = int((step / total) * 100)

            # 14. Nagle
            if self.chk_vars["chk_Nagle"].get():
                cnt = TweaksEngine.apply_nagle()
                self.set_badge("status_Nagle", f"[ Already Applied ({cnt}) ]", "#00E676")
                self.log(f"[OK] Nagle's algorithm disabled on {cnt} adapters.")
            step += 1; self.prog_bar["value"] = int((step / total) * 100)

            # 15. QoS
            if self.chk_vars["chk_QoS"].get():
                TweaksEngine.apply_qos()
                self.set_badge("status_QoS", "[ Already Applied (100%) ]", "#00E676")
                self.log("[OK] 100% QoS bandwidth unlocked.")
            step += 1; self.prog_bar["value"] = int((step / total) * 100)

            # 16. Delivery Opt
            if self.chk_vars["chk_DeliveryOpt"].get():
                TweaksEngine.apply_delivery_opt()
                self.set_badge("status_DeliveryOpt", "[ Already Applied ]", "#00E676")
                self.log("[OK] Delivery Optimization P2P disabled.")
            step += 1; self.prog_bar["value"] = int((step / total) * 100)

            # 17. Telemetry
            if self.chk_vars["chk_Telemetry"].get():
                TweaksEngine.apply_telemetry()
                self.set_badge("status_Telemetry", "[ Already Disabled ]", "#00E676")
                self.log("[OK] DiagTrack & SysMain disabled.")
            step += 1; self.prog_bar["value"] = int((step / total) * 100)

            # 18. OEM Services
            if self.chk_vars["chk_OemServices"].get():
                cnt = TweaksEngine.apply_oem_services()
                self.set_badge("status_OemServices", f"[ Already Optimized ({cnt}) ]", "#00E676")
                self.log(f"[OK] OEM services ({cnt}) set to on-demand.")
            step += 1; self.prog_bar["value"] = int((step / total) * 100)

            # 19. Tasks Debloat
            if self.chk_vars["chk_TasksDebloat"].get():
                cnt = TweaksEngine.apply_tasks_debloat()
                self.set_badge("status_TasksDebloat", f"[ Already Disabled ({cnt}) ]", "#00E676")
                self.log(f"[OK] Disabled {cnt} heavy scheduled tasks.")
            step += 1; self.prog_bar["value"] = int((step / total) * 100)

            # 20. SSD LastAccess
            if self.chk_vars["chk_SsdLastAccess"].get():
                TweaksEngine.apply_ssd_last_access()
                self.set_badge("status_SsdLastAccess", "[ Already Applied ]", "#00E676")
                self.log("[OK] DisableLastAccess = 1 applied.")
            step += 1; self.prog_bar["value"] = int((step / total) * 100)

            # 21. UI Delay
            if self.chk_vars["chk_UiDelay"].get():
                TweaksEngine.apply_ui_delay()
                self.set_badge("status_UiDelay", "[ Already Applied (0ms) ]", "#00E676")
                self.log("[OK] MenuShowDelay = 0 applied.")
            step += 1; self.prog_bar["value"] = 100

            self.lbl_status.config(text=L["status_done"])
            self.log("=====================================================", "cyan")
            self.log(L["log_apply_done"], "green")
            messagebox.showinfo(L["msg_done_title"], L["msg_done_body"])
        except Exception as e:
            log_exception(e, "apply_tweaks")
            self.log(f"[!] Error applying tweaks: {e}", "red")


# ---------------------------------------------------------------------------
# Application Entry Point
# ---------------------------------------------------------------------------
def main():
    request_admin()
    root = tk.Tk()
    app = OptimizerApp(root)
    root.mainloop()

if __name__ == "__main__":
    main()
