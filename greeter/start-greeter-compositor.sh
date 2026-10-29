#!/usr/bin/env bash
# greetd default_session entrypoint: Hyprland for the greeter, with no VT chatter.
set -u
ulimit -c 0 2>/dev/null || true

export HOME="${HOME:-/var/lib/regreet}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/cache}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/config}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/state}"
export QT_QPA_PLATFORM="${QT_QPA_PLATFORM:-wayland}"
export XKB_DEFAULT_LAYOUT="${XKB_DEFAULT_LAYOUT:-es}"
export CAELESTIA_GREETER_DIR="${CAELESTIA_GREETER_DIR:-/etc/greetd/caelestia}"
unset QT_QPA_PLATFORMTHEME || true

mkdir -p "$XDG_STATE_HOME" "$XDG_CACHE_HOME" "$XDG_CONFIG_HOME" 2>/dev/null || true
export CAELESTIA_QUIET_LOG="$XDG_STATE_HOME/hyprland-greeter.log"

exec "$CAELESTIA_GREETER_DIR/quiet-exec.sh" \
  /usr/bin/start-hyprland -- -c /etc/greetd/hyprland-greeter.lua
