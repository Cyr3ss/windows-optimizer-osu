"""
High-Resolution Windows Timer Lock (0.5ms / 0.5000ms) for osu! & Gaming
"""
import ctypes
from ctypes import wintypes
import time
import sys

ntdll = ctypes.WinDLL('ntdll')

def set_timer_resolution(desired_100ns=5000):
    cur_res = wintypes.ULONG()
    status = ntdll.NtSetTimerResolution(desired_100ns, 1, ctypes.byref(cur_res))
    return status == 0, cur_res.value / 10000

if __name__ == '__main__':
    ok, res = set_timer_resolution(5000)
    if ok:
        print(f"[V] System Timer Resolution successfully locked to {res:.4f} ms (High Precision)!")
    else:
        print(f"[!] Failed to set timer resolution.")
