#!/usr/bin/env bash
# greetd default_session entrypoint: Hyprland for the greeter, with no VT chatter.
set -u
ulimit -c 0 2>/dev/null || true

export HOME="${HOME:-/var/lib/regreet}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/cache}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/config}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/state}"
export QT_QPA_PLATFORM="${QT_QPA_PLATFORM:-wayland}"
# greetd does not hand the system's language and keyboard to the greeter: take them from the system
# (the login screen is translated with LANG; the keyboard of the password field follows the system's layout)
if [ -z "${LANG:-}" ] && [ -r /etc/locale.conf ]; then
  LANG="$(sed -n 's/^LANG=//p' /etc/locale.conf | tr -d '"' | head -n1)"
  export LANG
fi
if [ -z "${XKB_DEFAULT_LAYOUT:-}" ]; then
  layout="$(localectl status 2>/dev/null | sed -n 's/.*X11 Layout: *//p' | head -n1)"
  if [ -z "$layout" ] && [ -r /etc/vconsole.conf ]; then
    layout="$(sed -n 's/^KEYMAP=//p' /etc/vconsole.conf | tr -d '"' | cut -d- -f1)"
  fi
  export XKB_DEFAULT_LAYOUT="${layout:-us}"
fi
export SYLPHRENA_GREETER_DIR="${SYLPHRENA_GREETER_DIR:-${SYLPHRENA_GREETER_DIR:-/etc/greetd/sylphrena}}"
unset QT_QPA_PLATFORMTHEME || true

mkdir -p "$XDG_STATE_HOME" "$XDG_CACHE_HOME" "$XDG_CONFIG_HOME" 2>/dev/null || true
export SYLPHRENA_QUIET_LOG="$XDG_STATE_HOME/hyprland-greeter.log"

exec "$SYLPHRENA_GREETER_DIR/quiet-exec.sh" \
  /usr/bin/start-hyprland -- -c /etc/greetd/hyprland-greeter.lua
