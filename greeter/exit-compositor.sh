#!/usr/bin/env bash
# Tear down the disposable greeter compositor without Hyprland 0.57's ~5s
# shutdown+segfault. Prefer a short `hyprctl exit` so DRM is released cleanly
# (KWin/Plasma cannot steal a SIGKILL'd master); then KILL leftovers and put
# tty1 back in text mode for the next compositor.
set -u

# Drop Adaptive Sync before releasing DRM. KWin's next modeset returns
# EINVAL if this CRTC is still in the VRR state Hyprland left behind
# (HDMI 1440p@144 on this machine).
disable_vrr() {
  /usr/bin/hyprctl -j monitors 2>/dev/null | /usr/bin/python3 -c '
import json, subprocess, sys
try:
    monitors = json.load(sys.stdin)
except Exception:
    sys.exit(0)
for mon in monitors:
    name = mon.get("name")
    width, height = mon.get("width"), mon.get("height")
    if not name or not width or not height:
        continue
    rate = mon.get("refreshRate") or 60
    hz = int(round(float(rate)))
    x, y = int(mon.get("x") or 0), int(mon.get("y") or 0)
    scale = mon.get("scale") or 1
    desc = f"{name},{width}x{height}@{hz},{x}x{y},{scale},vrr,0"
    subprocess.run(["/usr/bin/hyprctl", "keyword", "monitor", desc], check=False)
' || true
  sleep 0.15
}

try_exit() {
  /usr/bin/hyprctl dispatch exit >/dev/null 2>&1 || true
}

kill_start_hyprland() {
  local pid="$PPID"
  while [[ "$pid" =~ ^[0-9]+$ ]] && (( pid > 1 )); do
    local exe
    exe="$(readlink -f "/proc/$pid/exe" 2>/dev/null || true)"
    if [[ "${exe##*/}" == "start-hyprland" ]]; then
      kill -KILL "$pid" 2>/dev/null || true
      return 0
    fi
    pid="$(awk '{print $4}' "/proc/$pid/stat" 2>/dev/null || true)"
  done
  return 1
}

reset_vt() {
  /usr/bin/python3 - <<'PY'
import fcntl
import os
import sys

KDSETMODE = 0x4B3A
KD_TEXT = 0
try:
    fd = os.open("/dev/tty1", os.O_RDWR)
    fcntl.ioctl(fd, KDSETMODE, KD_TEXT)
    os.write(fd, b"\033c\033[2J\033[3J\033[H\033[?25l")
    os.close(fd)
except OSError as exc:
    sys.stderr.write(f"exit-compositor: vt reset: {exc}\n")
PY
}

disable_vrr
try_exit
for _ in 1 2 3 4 5 6 7 8; do
  if ! pgrep -x Hyprland >/dev/null 2>&1 && ! pgrep -x start-hyprland >/dev/null 2>&1; then
    break
  fi
  sleep 0.1
done
kill_start_hyprland || true
# Last resort if the walker missed the parent.
pgrep -x start-hyprland >/dev/null 2>&1 && pkill -KILL -x start-hyprland || true
reset_vt
