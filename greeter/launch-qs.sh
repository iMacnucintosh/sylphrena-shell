#!/usr/bin/env bash
# Launch the Quickshell greeter under greetd and always leave a log behind.
set -u

export HOME="${HOME:-/var/lib/regreet}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/cache}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/config}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/state}"
export QT_QPA_PLATFORM="${QT_QPA_PLATFORM:-wayland}"
export XKB_DEFAULT_LAYOUT="${XKB_DEFAULT_LAYOUT:-es}"
# Do not pin QML_IMPORT_PATH — qs needs its own Quickshell modules.
unset QT_QPA_PLATFORMTHEME || true
export GDK_DEBUG="${GDK_DEBUG:-no-portals}"
export SYLPHRENA_GREETER_DIR="${SYLPHRENA_GREETER_DIR:-${SYLPHRENA_GREETER_DIR:-/etc/greetd/sylphrena}}"

mkdir -p "$XDG_STATE_HOME" "$XDG_CACHE_HOME" "$XDG_CONFIG_HOME" 2>/dev/null || true
LOG="$XDG_STATE_HOME/qs.log"
# Also mirror to /tmp so we can read it after login even if state perms glitch.
LOG2="/tmp/sylphrena-greeter-qs.log"

{
  echo "==== $(date -Is) pid=$$ uid=$(id -u) HOME=$HOME ===="
  echo "WAYLAND_DISPLAY=${WAYLAND_DISPLAY-} XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR-}"
  echo "qs=$(command -v qs || true)"
  ls -la "$SYLPHRENA_GREETER_DIR/qs/shell.qml" "$SYLPHRENA_GREETER_DIR/wallpaper" 2>&1 || true
} >>"$LOG" 2>&1
cp -f "$LOG" "$LOG2" 2>/dev/null || true

/usr/bin/qs -p "$SYLPHRENA_GREETER_DIR/qs" >>"$LOG" 2>&1
ec=$?

# Clear the backing VT while Hyprland still owns DRM. If the compositor handoff
# exposes tty1 for a frame, it will be solid black instead of old boot/log text.
if [[ -w /dev/tty1 ]]; then
  /usr/bin/setterm --cursor off --foreground black --background black --clear all \
    </dev/tty1 >/dev/tty1 2>/dev/null || true
  # RIS + clear screen + clear scrollback; do this even when setterm succeeds,
  # as KD_GRAPHICS may defer its visible repaint until DRM is released.
  printf '\033c\033[2J\033[3J\033[H\033[?25l' >/dev/tty1 2>/dev/null || true
fi

echo "qs exited $ec at $(date -Is)" >>"$LOG"
cp -f "$LOG" "$LOG2" 2>/dev/null || true
exit "$ec"
