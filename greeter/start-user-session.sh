#!/usr/bin/env bash
# greetd user-session entrypoint. Hyprland goes through quiet-exec (no TTY,
# no ASCII on tty1). Other compositors (Plasma/KWin) keep the VT — they need
# it to take DRM after the greeter Hyprland was torn down.
set -u
# A 27 GiB Cursor coredump held user@1000 for ~55s and blocked the next login.
ulimit -c 0 2>/dev/null || true

if (( $# < 1 )); then
  echo "usage: start-user-session.sh command [args...]" >&2
  exit 2
fi

state_home="${XDG_STATE_HOME:-${HOME:-/tmp}/.local/state}"
state_dir="$state_home/sylphrena"
if ! mkdir -p "$state_dir" 2>/dev/null; then
  state_dir=/tmp
fi

here="$(cd "$(dirname "$0")" && pwd)"
base="${1##*/}"

if [[ "$base" == "start-hyprland" || "$base" == "Hyprland" ]]; then
  export SYLPHRENA_QUIET_LOG="$state_dir/session-startup.log"
  qml_prefix="${HOME}/.local/lib/qt6/qml"
  systemctl --user set-environment \
    QT_QPA_PLATFORMTHEME=qt6ct \
    QML_IMPORT_PATH="$qml_prefix" \
    QML2_IMPORT_PATH="$qml_prefix" >/dev/null 2>&1 || true
  export QT_QPA_PLATFORMTHEME=qt6ct
  export QML_IMPORT_PATH="$qml_prefix"
  export QML2_IMPORT_PATH="$qml_prefix"
  exec "$here/quiet-exec.sh" "$@"
fi

# Plasma / anything else: do not drop the controlling TTY (KWin needs the VT).
# environment.d forces qt6ct and the Sylphrena QML path for the Hyprland
# session. systemd --user already imported them before this script runs, so
# plasmashell would start without the KDE platform theme. Put them back only
# on the Hyprland branch above.
log="$state_dir/session-startup.log"
{
  echo "==== $(date -Is) uid=$(id -u) launching $* ===="
  echo "XDG_SESSION_DESKTOP=${XDG_SESSION_DESKTOP-} XDG_CURRENT_DESKTOP=${XDG_CURRENT_DESKTOP-}"
  echo "WAYLAND_DISPLAY=${WAYLAND_DISPLAY-} HYPRLAND_INSTANCE_SIGNATURE=${HYPRLAND_INSTANCE_SIGNATURE-}"
  echo "QT_QPA_PLATFORMTHEME=${QT_QPA_PLATFORMTHEME-} QT_QPA_PLATFORM=${QT_QPA_PLATFORM-}"
} >>"$log"

sylph_env=(
  QT_QPA_PLATFORMTHEME
  QT_QPA_PLATFORM
  QML_IMPORT_PATH
  QML2_IMPORT_PATH
  WAYLAND_DISPLAY
  HYPRLAND_INSTANCE_SIGNATURE
  HYPRLAND_CMD
  SWAYSOCK
)
systemctl --user unset-environment "${sylph_env[@]}" >/dev/null 2>&1 || true
unset "${sylph_env[@]}" || true

# Greeter Hyprland may still be dropping DRM master (exit, then SIGKILL).
for _ in $(seq 1 30); do
  if ! pgrep -x Hyprland >/dev/null 2>&1 && ! pgrep -x start-hyprland >/dev/null 2>&1; then
    break
  fi
  sleep 0.1
done
sleep 0.2

exec "$@" >>"$log" 2>&1
