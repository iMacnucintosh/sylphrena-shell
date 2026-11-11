#!/usr/bin/env bash
# Push current Sylphrena palette into all open Kitty windows.
state="${XDG_STATE_HOME:-$HOME/.local/state}"
theme="$state/sylphrena/theme/kitty.conf"
# Legacy caelestia path kept until every CLI/runtime path is renamed.
[[ -r "$theme" ]] || theme="$state/caelestia/theme/kitty.conf"
[[ -r "$theme" ]] || exit 0
runtime="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
shopt -s nullglob
for sock in "$runtime"/kitty-*.sock; do
  kitty @ --to "unix:${sock}" set-colors --all --configured "$theme" >/dev/null 2>&1 || true
done
