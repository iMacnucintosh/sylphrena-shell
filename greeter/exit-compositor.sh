#!/usr/bin/env bash
# Tear down the disposable greeter compositor without Hyprland's slow/crashing
# shutdown path. Killing start-hyprland makes its child die via PDEATHSIG.
set -u

pid="$PPID"
while [[ "$pid" =~ ^[0-9]+$ ]] && (( pid > 1 )); do
  exe="$(readlink -f "/proc/$pid/exe" 2>/dev/null || true)"
  if [[ "${exe##*/}" == "start-hyprland" ]]; then
    kill -KILL "$pid" 2>/dev/null || true
    exit 0
  fi
  pid="$(awk '{print $4}' "/proc/$pid/stat" 2>/dev/null || true)"
done

# Fallback for an unexpected launcher hierarchy.
/usr/bin/hyprctl dispatch exit >/dev/null 2>&1 || true
