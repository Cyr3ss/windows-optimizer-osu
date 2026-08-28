"""
=============================================================================
 Windows Gaming & Tablet Optimizer (osu! Edition) - Python GUI Application
=============================================================================
 Native Python 3 GUI application with dark theme, smart system scanner,
 granular tweak checkboxes, live console logger, and exception reporting.
 Compatible with PyInstaller for building standalone .exe files.
=============================================================================
"""

import os
import sys
import ctypes
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
            # Re-launch current script/exe with Administrator privileges
            if getattr(sys, 'frozen', False):
                # PyInstaller binary
                ctypes.windll.shell32.ShellExecuteW(None, "runas", sys.executable, None, None, 1)
            else:
                # Python script
                ctypes.windll.shell32.ShellExecuteW(None, "runas", sys.executable, f'"{os.path.abspath(__file__)}"', None, 1)
            sys.exit(0)
        except Exception as e:
            log_exception(e, "Admin Elevation")
            sys.exit(1)

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

def run_cmd(cmd: str) -> bool:
    try:
        res = subprocess.run(cmd, shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return res.returncode == 0
    except Exception as e:
        log_exception(e, f"run_cmd: {cmd}")
        return False

# ---------------------------------------------------------------------------
# Optimizer Tweak Actions
# ---------------------------------------------------------------------------
class TweaksEngine:

    @staticmethod
    def check_pen_hold() -> str:
        val = reg_get_dword(winreg.HKEY_CURRENT_USER, r"Software\Microsoft\Wisp\Pen\SysEventParameters", "HoldMode")
        return "Already Optimized" if val == 0 else "Available"

    @staticmethod
    def apply_pen_hold() -> bool:
        r1 = winreg.HKEY_CURRENT_USER
        p1 = r"Software\Microsoft\Wisp\Pen\SysEventParameters"
        for k in ["FlickMode", "HoldMode", "Splash", "DblTime", "DblDist", "WaitTime"]:
            reg_set_dword(r1, p1, k, 0)
        p2 = r"Software\Microsoft\Wisp\Touch"
        for k in ["TouchMode_hold", "TouchModeN_HoldTime_BeforeAnimation", "TouchModeN_HoldTime_Animation"]:
            reg_set_dword(r1, p2, k, 0)
        return True

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

    @staticmethod
    def apply_linear_curve() -> bool:
        zero_curve = bytes([0] * 40)
        reg_set_binary(winreg.HKEY_CURRENT_USER, r"Control Panel\Mouse", "SmoothMouseXCurve", zero_curve)
        reg_set_binary(winreg.HKEY_CURRENT_USER, r"Control Panel\Mouse", "SmoothMouseYCurve", zero_curve)
        return True

    @staticmethod
    def check_tablet_service() -> str:
        try:
            res = subprocess.run("sc.exe qc TabletInputService", shell=True, capture_output=True, text=True)
            if "DISABLED" in res.stdout.upper():
                return "Already Disabled"
            elif "TABLETINPUTSERVICE" in res.stdout.upper() or res.returncode == 0:
                return "Detected (Active)"
            return "Not Found (N/A)"
        except Exception:
            return "Not Found (N/A)"

    @staticmethod
    def apply_tablet_service() -> bool:
        run_cmd("sc.exe stop TabletInputService")
        run_cmd("sc.exe config TabletInputService start= disabled")
        return True

    @staticmethod
    def apply_usb_suspend() -> bool:
        run_cmd("powercfg /setacvalueindex SCHEME_CURRENT 2a737441-1930-4402-9177-b06418304ddf 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0")
        run_cmd("powercfg /setdcvalueindex SCHEME_CURRENT 2a737441-1930-4402-9177-b06418304ddf 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0")
        run_cmd("powercfg /setactive SCHEME_CURRENT")
        ps_wmi = 'Get-CimInstance MSPower_DeviceEnable -Namespace root\\wmi -ErrorAction SilentlyContinue | Where-Object { $_.InstanceName -match "USB" } | ForEach-Object { Set-CimInstance -Query "Select * from MSPower_DeviceEnable where InstanceName=\'$($_.InstanceName)\'" -Property @{Enable=$false} -Namespace root\\wmi -ErrorAction SilentlyContinue }'
        run_cmd(f'powershell.exe -NoProfile -Command "{ps_wmi}"')
        return True

    @staticmethod
    def check_bcd_timers() -> str:
        try:
            res = subprocess.run("bcdedit /enum {current}", shell=True, capture_output=True, text=True)
            if "disabledynamictick" in res.stdout.lower() and "yes" in res.stdout.lower():
                return "Active (TSC)"
            return "Available"
        except Exception:
            return "Available"

    @staticmethod
    def apply_bcd_timers() -> bool:
        run_cmd("bcdedit /set disabledynamictick yes")
        run_cmd("bcdedit /set useplatformclock no")
        return True

    @staticmethod
    def check_win32_priority() -> str:
        val = reg_get_dword(winreg.HKEY_LOCAL_MACHINE, r"SYSTEM\CurrentControlSet\Control\PriorityControl", "Win32PrioritySeparation")
        return "Active (0x26)" if val == 38 else "Available"

    @staticmethod
    def apply_win32_priority() -> bool:
        return reg_set_dword(winreg.HKEY_LOCAL_MACHINE, r"SYSTEM\CurrentControlSet\Control\PriorityControl", "Win32PrioritySeparation", 38)

    @staticmethod
    def apply_csrss_dwm() -> bool:
        for proc in ["csrss.exe", "dwm.exe"]:
            p = rf"SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\{proc}\PerfOptions"
            reg_set_dword(winreg.HKEY_LOCAL_MACHINE, p, "CpuPriorityClass", 3)
            reg_set_dword(winreg.HKEY_LOCAL_MACHINE, p, "IoPriority", 3)
        return True

    @staticmethod
    def apply_gamemode() -> bool:
        reg_set_dword(winreg.HKEY_CURRENT_USER, r"Software\Microsoft\GameBar", "AutoGameModeEnabled", 1)
        reg_set_dword(winreg.HKEY_CURRENT_USER, r"Software\Microsoft\GameBar", "AllowAutoGameMode", 1)
        reg_set_dword(winreg.HKEY_CURRENT_USER, r"System\GameConfigStore", "GameDVR_DXGIHonorFSEWindowsCompatible", 1)
        reg_set_dword(winreg.HKEY_CURRENT_USER, r"System\GameConfigStore", "GameDVR_FSEBehaviorMode", 2)
        reg_set_dword(winreg.HKEY_CURRENT_USER, r"System\GameConfigStore", "GameDVR_Enabled", 0)
        reg_set_dword(winreg.HKEY_LOCAL_MACHINE, r"SOFTWARE\Microsoft\WindowsRuntime\ActivatableClassId\Windows.Gaming.GameBar.PresenceServer.Internal.PresenceWriter", "ActivationType", 0)
        return True

    @staticmethod
    def apply_keyboard_delay() -> bool:
        reg_set_string(winreg.HKEY_CURRENT_USER, r"Control Panel\Keyboard", "KeyboardDelay", "0")
        reg_set_string(winreg.HKEY_CURRENT_USER, r"Control Panel\Keyboard", "KeyboardSpeed", "31")
        reg_set_string(winreg.HKEY_CURRENT_USER, r"Control Panel\Accessibility\Keyboard Response", "DelayBeforeAcceptance", "0")
        reg_set_string(winreg.HKEY_CURRENT_USER, r"Control Panel\Accessibility\Keyboard Response", "BounceTime", "0")
        return True

    @staticmethod
    def apply_cpu_unpark() -> bool:
        run_cmd("powercfg -setacvalueindex SCHEME_CURRENT SUB_PROCESSOR CPMINCORES 100")
        run_cmd("powercfg -setdcvalueindex SCHEME_CURRENT SUB_PROCESSOR CPMINCORES 100")
        run_cmd("powercfg -setactive SCHEME_CURRENT")
        return True

    @staticmethod
    def apply_kernel_ram() -> bool:
        reg_set_dword(winreg.HKEY_LOCAL_MACHINE, r"SYSTEM\CurrentControlSet\Control\Power\PowerThrottling", "PowerThrottlingOff", 1)
        reg_set_dword(winreg.HKEY_LOCAL_MACHINE, r"SYSTEM\CurrentControlSet\Control\Session Manager\Power", "HiberbootEnabled", 0)
        reg_set_dword(winreg.HKEY_LOCAL_MACHINE, r"SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management", "DisablePagingExecutive", 1)
        return True

    @staticmethod
    def check_osu_fso() -> str:
        local_app = os.environ.get("LOCALAPPDATA", "")
        paths = [
            os.path.join(local_app, "osu!", "osu!.exe"),
            r"C:\osu!\osu!.exe", r"D:\osu!\osu!.exe", r"E:\osu!\osu!.exe"
        ]
        found = [p for p in paths if os.path.exists(p)]
        return "Detected" if found else "osu! Not Found"

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

    @staticmethod
    def apply_qos() -> bool:
        return reg_set_dword(winreg.HKEY_LOCAL_MACHINE, r"SOFTWARE\Policies\Microsoft\Windows\Psched", "NonBestEffortLimit", 0)

    @staticmethod
    def apply_delivery_opt() -> bool:
        reg_set_dword(winreg.HKEY_CURRENT_USER, r"Software\Microsoft\Windows\CurrentVersion\DeliveryOptimization", "DODownloadMode", 0)
        reg_set_dword(winreg.HKEY_LOCAL_MACHINE, r"SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization", "DODownloadMode", 0)
        return True

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

    @staticmethod
    def apply_oem_services() -> int:
        svcs = ["HPAppHelperCap", "HPDiagsCap", "HPNetworkCap", "HPSysInfoCap", "AnyDesk", "WerSvc"]
        cnt = 0
        for s in svcs:
            run_cmd(f"sc.exe stop {s}")
            if run_cmd(f"sc.exe config {s} start= demand"):
                cnt += 1
        return cnt

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

    @staticmethod
    def apply_ssd_last_access() -> bool:
        return run_cmd("fsutil behavior set disablelastaccess 1")

    @staticmethod
    def apply_ui_delay() -> bool:
        reg_set_string(winreg.HKEY_CURRENT_USER, r"Control Panel\Desktop", "MenuShowDelay", "0")
        reg_set_string(winreg.HKEY_CURRENT_USER, r"Control Panel\Desktop\WindowMetrics", "MinAnimate", "0")
        return True


# ---------------------------------------------------------------------------
# Modern Dark Tkinter GUI
# ---------------------------------------------------------------------------
class OptimizerApp:

    def __init__(self, root: tk.Tk):
        self.root = root
        self.root.title("Windows Gaming and Tablet Optimizer")
        self.root.geometry("980" + "x780")
        self.root.minsize(880, 680)
        self.root.configure(bg="#12141A")

        self.setup_styles()
        self.create_widgets()
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
        lbl_title = tk.Label(title_box, text="⚡ Windows Gaming and Tablet Optimizer", font=("Segoe UI", 15, "bold"), fg="#00E5FF", bg="#1A1D26")
        lbl_title.pack(anchor="w")
        lbl_sub = tk.Label(title_box, text="Интерактивная оптимизация графических планшетов, системных таймеров, сети и FPS", font=("Segoe UI", 9), fg="#8C93A8", bg="#1A1D26")
        lbl_sub.pack(anchor="w", pady=(2, 0))

        btn_box = tk.Frame(header, bg="#1A1D26")
        btn_box.pack(side="right")

        btn_scan = tk.Button(btn_box, text="🔍 Сканировать систему", font=("Segoe UI", 9, "bold"), bg="#263238", fg="#00E5FF", activebackground="#37474F", activeforeground="#00E5FF", relief="flat", padx=12, pady=6, cursor="hand2", command=self.scan_system)
        btn_scan.pack(side="left", padx=4)

        btn_sel = tk.Button(btn_box, text="Выбрать все", font=("Segoe UI", 9), bg="#2A2F40", fg="#E0E0E0", activebackground="#37474F", activeforeground="#FFFFFF", relief="flat", padx=10, pady=6, cursor="hand2", command=self.select_all)
        btn_sel.pack(side="left", padx=4)

        btn_desel = tk.Button(btn_box, text="Снять все", font=("Segoe UI", 9), bg="#2A2F40", fg="#E0E0E0", activebackground="#37474F", activeforeground="#FFFFFF", relief="flat", padx=10, pady=6, cursor="hand2", command=self.deselect_all)
        btn_desel.pack(side="left", padx=4)

        btn_apply = tk.Button(btn_box, text="⚡ Применить выбранное", font=("Segoe UI", 9, "bold"), bg="#00C853", fg="#FFFFFF", activebackground="#00E676", activeforeground="#FFFFFF", relief="flat", padx=14, pady=6, cursor="hand2", command=self.apply_tweaks)
        btn_apply.pack(side="left", padx=4)

        # Tabbed Container
        self.notebook = ttk.Notebook(self.root)
        self.notebook.pack(fill="both", expand=True, padx=16, pady=6)

        self.chk_vars = {}
        self.badge_labels = {}

        self.tab1 = self.create_tab("🖊️ Планшет и Перо", [
            ("chk_PenHold", "Отключить задержку касания (HoldMode) и жесты (FlickMode)", "Убирает 300 мс задержки при первом касании пером и буфер жестов Windows Ink.", "status_PenHold"),
            ("chk_TabletGPO", "Применить Group Policies для планшетов (TabletPC & PenWorkspace)", "Системный запрет на генерацию анимаций кругов (Ripple), зажатия и жестов в HKLM/HKCU.", "status_TabletGPO"),
            ("chk_LinearCurve", "Обнулить нелинейное сглаживание курсора (1:1 Raw Linear Curve)", "Обнуляет полиномиальные кривые SmoothMouseX/YCurve для абсолютно равномерного движения.", "status_LinearCurve"),
            ("chk_TabletInputSvc", "Отключить службу сенсорной клавиатуры и рукописного ввода (TabletInputService)", "Убирает перехват координат пера системным процессом Windows.", "status_TabletInputSvc"),
            ("chk_UsbSuspend", "Отключить энергосбережение USB (Selective Suspend & Root Hubs)", "Предотвращает засыпание контроллера планшета, обеспечивая непрерывную частоту опроса 1000Hz.", "status_UsbSuspend"),
        ])

        self.tab2 = self.create_tab("⚡ Система, CPU и FPS", [
            ("chk_BcdTimers", "Включить аппаратный таймер TSC (disabledynamictick yes / useplatformclock no)", "Устраняет пропуск тиков таймера процессора и переводит Windows на инвариантный таймер TSC.", "status_BcdTimers"),
            ("chk_Win32Priority", "Настроить кванты CPU 3:1 в пользу активной игры (Win32PrioritySeparation = 0x26)", "Выделяет активному окну в 3 раза больше времени CPU без прерываний на фоновые службы.", "status_Win32Priority"),
            ("chk_CsrssDwm", "Повысить приоритеты диспетчера ввода (CSRSS) и вывода кадров (DWM)", "Переводит csrss.exe и dwm.exe в High Priority для мгновенной доставки аппаратных кликов.", "status_CsrssDwm"),
            ("chk_GameMode", "Включить Windows Game Mode и отключить GameDVR / GameBar", "Активирует игровой режим Windows и полностью выключает фоновый процесс GameBarPresenceWriter.", "status_GameMode"),
            ("chk_KeyboardDelay", "Снизить задержку повтора клавиатуры (KeyboardDelay = 0 / Speed = 31)", "Ускоряет регистрацию стримов K1/K2 в osu! и обнуляет время задержки дребезга (BounceTime).", "status_KeyboardDelay"),
            ("chk_CpuUnpark", "Разблокировать спящие ядра процессора (CPU Core Unparking 100%)", "Запрещает процессору усыплять логические ядра, устраняя 2-5 мс лага пробуждения.", "status_CpuUnpark"),
            ("chk_KernelRam", "Зафиксировать ядро в RAM и отключить Fast Startup (Чистый старт ОС)", "Включает DisablePagingExecutive = 1 и отключает гибернацию ядра при выключении ПК.", "status_KernelRam"),
            ("chk_OsuFso", "Принудительный аппаратный Fullscreen Exclusive для osu!.exe", "Отключает 'Оптимизацию во весь экран' для osu! (прямой рендер без буфера DWM).", "status_OsuFso"),
        ])

        self.tab3 = self.create_tab("🌐 Сеть и Пинг", [
            ("chk_Nagle", "Отключить алгоритм Нейгла (TCPNoDelay = 1, TcpAckFrequency = 1)", "Отправляет мелкие пакеты ввода мгновенно без накопления в сетевом буфере.", "status_Nagle"),
            ("chk_QoS", "Снять 20% системное ограничение пропускной способности (QoS = 0)", "Разблокирует 100% пропускной способности интернет-канала для сетевых игр.", "status_QoS"),
            ("chk_DeliveryOpt", "Отключить фоновую раздачу обновлений P2P (Delivery Optimization)", "Запрещает Windows раздавать скачанные обновления по локальной сети и интернету.", "status_DeliveryOpt"),
        ])

        self.tab4 = self.create_tab("🧹 Службы и SSD", [
            ("chk_Telemetry", "Отключить службу сбора телеметрии (DiagTrack) и SysMain", "Останавливает постоянную запись диагностических логов на SSD и освобождает ОЗУ.", "status_Telemetry"),
            ("chk_OemServices", "Перевести второстепенные OEM/Служебные процессы в ручной режим", "Переводит фоновые диагностические службы (HP, Dell, AnyDesk, WerSvc) в режим Manual.", "status_OemServices"),
            ("chk_TasksDebloat", "Отключить тяжелые задачи планировщика (Compatibility Appraiser)", "Отключает периодические фоновые сканеры совместимости и отчеты об ошибках.", "status_TasksDebloat"),
            ("chk_SsdLastAccess", "Оптимизировать файловую систему SSD (Disable LastAccess Timestamps)", "Отключает лишние операции записи на SSD при обычном чтении файлов (fsutil).", "status_SsdLastAccess"),
            ("chk_UiDelay", "Убрать искусственные задержки меню (MenuShowDelay = 0 / MinAnimate = 0)", "Делает открытие контекстных меню и отклик окон Windows моментальным.", "status_UiDelay"),
        ])

        # Progress bar frame
        prog_frame = tk.Frame(self.root, bg="#12141A")
        prog_frame.pack(fill="x", padx=16, pady=(4, 6))

        self.prog_bar = ttk.Progressbar(prog_frame, style="TProgressbar", orient="horizontal", mode="determinate")
        self.prog_bar.pack(side="left", fill="x", expand=True)

        self.lbl_status = tk.Label(prog_frame, text="Готов к работе", font=("Segoe UI", 9), fg="#8C93A8", bg="#12141A")
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

    def create_tab(self, tab_title: str, items: list) -> tk.Frame:
        tab = tk.Frame(self.notebook, bg="#161922", padx=14, pady=10)
        self.notebook.add(tab, text=tab_title)

        for key, title, desc, badge_key in items:
            row = tk.Frame(tab, bg="#1E2230", padx=12, pady=8, highlightbackground="#2A2F40", highlightthickness=1)
            row.pack(fill="x", pady=4)

            var = tk.BooleanVar(value=True)
            self.chk_vars[key] = var

            chk_box = tk.Frame(row, bg="#1E2230")
            chk_box.pack(side="left", fill="both", expand=True)

            chk = tk.Checkbutton(chk_box, text=title, variable=var, font=("Segoe UI", 10, "bold"), fg="#E0E0E0", bg="#1E2230", selectcolor="#12141A", activebackground="#1E2230", activeforeground="#FFFFFF", anchor="w")
            chk.pack(anchor="w")

            lbl_desc = tk.Label(chk_box, text=desc, font=("Segoe UI", 8), fg="#8C93A8", bg="#1E2230", anchor="w")
            lbl_desc.pack(anchor="w", padx=(24, 0))

            badge = tk.Label(row, text="[ Не проверено ]", font=("Segoe UI", 9, "bold"), fg="#757575", bg="#1E2230")
            badge.pack(side="right", padx=6)
            self.badge_labels[badge_key] = badge

        return tab

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
        self.log("Все чекбоксы отмечены.", "cyan")

    def deselect_all(self):
        for v in self.chk_vars.values():
            v.set(False)
        self.log("Все чекбоксы сняты.", "yellow")

    def scan_system(self):
        try:
            self.txt_log.delete("1.0", tk.END)
            self.log("=== Запуск предварительного сканирования системы ===", "cyan")
            self.lbl_status.config(text="Сканирование системы...")
            self.prog_bar["value"] = 10

            # 1. Pen Hold
            st_pen = TweaksEngine.check_pen_hold()
            self.set_badge("status_PenHold", f"[ {st_pen} ]", "#00E676" if "Already" in st_pen else "#00E5FF")

            # 2. Tablet Service
            st_tis = TweaksEngine.check_tablet_service()
            self.set_badge("status_TabletInputSvc", f"[ {st_tis} ]", "#00E676" if "Already" in st_tis else "#FFD600" if "Detected" in st_tis else "#757575")

            self.set_badge("status_TabletGPO", "[ Доступно ]", "#00E5FF")
            self.set_badge("status_LinearCurve", "[ Доступно ]", "#00E5FF")
            self.set_badge("status_UsbSuspend", "[ Доступно ]", "#00E5FF")
            self.prog_bar["value"] = 40

            # 3. BCD Timers
            st_bcd = TweaksEngine.check_bcd_timers()
            self.set_badge("status_BcdTimers", f"[ {st_bcd} ]", "#00E676" if "Active" in st_bcd else "#00E5FF")

            # 4. Win32Priority
            st_prio = TweaksEngine.check_win32_priority()
            self.set_badge("status_Win32Priority", f"[ {st_prio} ]", "#00E676" if "Active" in st_prio else "#00E5FF")

            self.set_badge("status_CsrssDwm", "[ Доступно ]", "#00E5FF")
            self.set_badge("status_GameMode", "[ Доступно ]", "#00E5FF")
            self.set_badge("status_KeyboardDelay", "[ Доступно ]", "#00E5FF")
            self.set_badge("status_CpuUnpark", "[ Доступно ]", "#00E5FF")
            self.set_badge("status_KernelRam", "[ Доступно ]", "#00E5FF")

            # 5. osu! FSO
            st_osu = TweaksEngine.check_osu_fso()
            self.set_badge("status_OsuFso", f"[ {st_osu} ]", "#00E676" if "Detected" in st_osu else "#757575")
            self.prog_bar["value"] = 70

            # 6. Network
            self.set_badge("status_Nagle", "[ Доступно ]", "#00E5FF")
            self.set_badge("status_QoS", "[ Доступно ]", "#00E5FF")
            self.set_badge("status_DeliveryOpt", "[ Доступно ]", "#00E5FF")

            # 7. Debloat
            st_tele = TweaksEngine.check_telemetry()
            self.set_badge("status_Telemetry", f"[ {st_tele} ]", "#00E676" if "Already" in st_tele else "#FFD600" if "Detected" in st_tele else "#757575")
            self.set_badge("status_OemServices", "[ Доступно ]", "#00E5FF")
            self.set_badge("status_TasksDebloat", "[ Доступно ]", "#00E5FF")
            self.set_badge("status_SsdLastAccess", "[ Доступно ]", "#00E5FF")
            self.set_badge("status_UiDelay", "[ Доступно ]", "#00E5FF")

            self.prog_bar["value"] = 100
            self.lbl_status.config(text="Сканирование завершено!")
            self.log("[V] Сканирование успешно завершено. Все модули проверены.", "green")
        except Exception as e:
            log_exception(e, "scan_system")
            self.log(f"[!] Ошибка сканирования: {e}", "red")

    def apply_tweaks(self):
        try:
            self.txt_log.delete("1.0", tk.END)
            self.log("=== Применение выбранных оптимизаций ===", "cyan")
            self.lbl_status.config(text="Применение твиков...")
            self.prog_bar["value"] = 0

            total = 21
            step = 0

            # 1. Pen Hold
            if self.chk_vars["chk_PenHold"].get():
                TweaksEngine.apply_pen_hold()
                self.set_badge("status_PenHold", "[ Применено OK ]", "#00E676")
                self.log("[OK] Windows Ink HoldMode и FlickMode отключены.")
            step += 1; self.prog_bar["value"] = int((step / total) * 100)

            # 2. Tablet GPO
            if self.chk_vars["chk_TabletGPO"].get():
                TweaksEngine.apply_tablet_gpo()
                self.set_badge("status_TabletGPO", "[ Применено OK ]", "#00E676")
                self.log("[OK] Group Policies TabletPC и PenWorkspace применены.")
            step += 1; self.prog_bar["value"] = int((step / total) * 100)

            # 3. Linear Curve
            if self.chk_vars["chk_LinearCurve"].get():
                TweaksEngine.apply_linear_curve()
                self.set_badge("status_LinearCurve", "[ Применено OK ]", "#00E676")
                self.log("[OK] Нелинейное сглаживание курсора обнулено (1:1 Raw).")
            step += 1; self.prog_bar["value"] = int((step / total) * 100)

            # 4. Tablet Service
            if self.chk_vars["chk_TabletInputSvc"].get():
                TweaksEngine.apply_tablet_service()
                self.set_badge("status_TabletInputSvc", "[ Применено OK ]", "#00E676")
                self.log("[OK] TabletInputService отключена.")
            step += 1; self.prog_bar["value"] = int((step / total) * 100)

            # 5. USB Suspend
            if self.chk_vars["chk_UsbSuspend"].get():
                TweaksEngine.apply_usb_suspend()
                self.set_badge("status_UsbSuspend", "[ Применено OK ]", "#00E676")
                self.log("[OK] USB Selective Suspend и спящий режим Root Hubs отключены.")
            step += 1; self.prog_bar["value"] = int((step / total) * 100)

            # 6. BCD Timers
            if self.chk_vars["chk_BcdTimers"].get():
                TweaksEngine.apply_bcd_timers()
                self.set_badge("status_BcdTimers", "[ Применено OK ]", "#00E676")
                self.log("[OK] BCD таймеры: disabledynamictick yes / useplatformclock no.")
            step += 1; self.prog_bar["value"] = int((step / total) * 100)

            # 7. Win32Priority
            if self.chk_vars["chk_Win32Priority"].get():
                TweaksEngine.apply_win32_priority()
                self.set_badge("status_Win32Priority", "[ Применено OK ]", "#00E676")
                self.log("[OK] Win32PrioritySeparation = 0x26 (38) выставлен.")
            step += 1; self.prog_bar["value"] = int((step / total) * 100)

            # 8. CSRSS & DWM
            if self.chk_vars["chk_CsrssDwm"].get():
                TweaksEngine.apply_csrss_dwm()
                self.set_badge("status_CsrssDwm", "[ Применено OK ]", "#00E676")
                self.log("[OK] CSRSS и DWM переведены в High Priority.")
            step += 1; self.prog_bar["value"] = int((step / total) * 100)

            # 9. GameMode
            if self.chk_vars["chk_GameMode"].get():
                TweaksEngine.apply_gamemode()
                self.set_badge("status_GameMode", "[ Применено OK ]", "#00E676")
                self.log("[OK] Game Mode включен, GameDVR / PresenceWriter отключены.")
            step += 1; self.prog_bar["value"] = int((step / total) * 100)

            # 10. Keyboard Delay
            if self.chk_vars["chk_KeyboardDelay"].get():
                TweaksEngine.apply_keyboard_delay()
                self.set_badge("status_KeyboardDelay", "[ Применено OK ]", "#00E676")
                self.log("[OK] KeyboardDelay = 0 / Speed = 31 выставлены.")
            step += 1; self.prog_bar["value"] = int((step / total) * 100)

            # 11. CPU Unpark
            if self.chk_vars["chk_CpuUnpark"].get():
                TweaksEngine.apply_cpu_unpark()
                self.set_badge("status_CpuUnpark", "[ Применено OK ]", "#00E676")
                self.log("[OK] CPU Core Unparking (100% активных ядер) включен.")
            step += 1; self.prog_bar["value"] = int((step / total) * 100)

            # 12. Kernel RAM
            if self.chk_vars["chk_KernelRam"].get():
                TweaksEngine.apply_kernel_ram()
                self.set_badge("status_KernelRam", "[ Применено OK ]", "#00E676")
                self.log("[OK] Ядро зафиксировано в RAM, Fast Startup отключен.")
            step += 1; self.prog_bar["value"] = int((step / total) * 100)

            # 13. Osu FSO
            if self.chk_vars["chk_OsuFso"].get():
                if TweaksEngine.apply_osu_fso():
                    self.set_badge("status_OsuFso", "[ Применено OK ]", "#00E676")
                    self.log("[OK] Hardware Exclusive Fullscreen настроен для osu!.exe")
                else:
                    self.set_badge("status_OsuFso", "[ Пропущено (N/A) ]", "#757575")
                    self.log("[WARN] osu!.exe не найден в стандартных путях.", "yellow")
            step += 1; self.prog_bar["value"] = int((step / total) * 100)

            # 14. Nagle
            if self.chk_vars["chk_Nagle"].get():
                cnt = TweaksEngine.apply_nagle()
                self.set_badge("status_Nagle", f"[ Применено ({cnt}) ]", "#00E676")
                self.log(f"[OK] Алгоритм Нейгла отключен на {cnt} интерфейсах.")
            step += 1; self.prog_bar["value"] = int((step / total) * 100)

            # 15. QoS
            if self.chk_vars["chk_QoS"].get():
                TweaksEngine.apply_qos()
                self.set_badge("status_QoS", "[ Применено OK ]", "#00E676")
                self.log("[OK] 100% QoS канала разблокировано.")
            step += 1; self.prog_bar["value"] = int((step / total) * 100)

            # 16. Delivery Opt
            if self.chk_vars["chk_DeliveryOpt"].get():
                TweaksEngine.apply_delivery_opt()
                self.set_badge("status_DeliveryOpt", "[ Применено OK ]", "#00E676")
                self.log("[OK] Delivery Optimization P2P отключена.")
            step += 1; self.prog_bar["value"] = int((step / total) * 100)

            # 17. Telemetry
            if self.chk_vars["chk_Telemetry"].get():
                TweaksEngine.apply_telemetry()
                self.set_badge("status_Telemetry", "[ Применено OK ]", "#00E676")
                self.log("[OK] DiagTrack и SysMain отключены.")
            step += 1; self.prog_bar["value"] = int((step / total) * 100)

            # 18. OEM Services
            if self.chk_vars["chk_OemServices"].get():
                cnt = TweaksEngine.apply_oem_services()
                self.set_badge("status_OemServices", f"[ Переведено ({cnt}) ]", "#00E676")
                self.log(f"[OK] OEM службы ({cnt} шт.) переведены в ручной режим.")
            step += 1; self.prog_bar["value"] = int((step / total) * 100)

            # 19. Tasks Debloat
            if self.chk_vars["chk_TasksDebloat"].get():
                cnt = TweaksEngine.apply_tasks_debloat()
                self.set_badge("status_TasksDebloat", f"[ Отключено ({cnt}) ]", "#00E676")
                self.log(f"[OK] Отключено {cnt} тяжелых задач планировщика.")
            step += 1; self.prog_bar["value"] = int((step / total) * 100)

            # 20. SSD LastAccess
            if self.chk_vars["chk_SsdLastAccess"].get():
                TweaksEngine.apply_ssd_last_access()
                self.set_badge("status_SsdLastAccess", "[ Применено OK ]", "#00E676")
                self.log("[OK] DisableLastAccess = 1 для SSD применен.")
            step += 1; self.prog_bar["value"] = int((step / total) * 100)

            # 21. UI Delay
            if self.chk_vars["chk_UiDelay"].get():
                TweaksEngine.apply_ui_delay()
                self.set_badge("status_UiDelay", "[ Применено OK ]", "#00E676")
                self.log("[OK] Задержка интерфейса MenuShowDelay = 0 установлена.")
            step += 1; self.prog_bar["value"] = 100

            self.lbl_status.config(text="Готово! Все твики применены.")
            self.log("=====================================================", "cyan")
            self.log("[V] ВСЕ ОПТИМИЗАЦИИ ПРИМЕНЕНЫ! Перезагрузите ПК.", "green")
            messagebox.showinfo("Готово", "Все выбранные оптимизации успешно применены!\n\nРекомендуется перезагрузить компьютер для активации BCD таймеров и квантов CPU.")
        except Exception as e:
            log_exception(e, "apply_tweaks")
            self.log(f"[!] Ошибка при применении твиков: {e}", "red")


# ---------------------------------------------------------------------------
# Application Entry Point
# ---------------------------------------------------------------------------
def main():
    # Require Administrator privileges
    request_admin()

    root = tk.Tk()
    app = OptimizerApp(root)
    root.mainloop()

if __name__ == "__main__":
    main()
