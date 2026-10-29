#!/usr/bin/env bash
# Show the greeter snapshot as soon as the user Hyprland owns DRM.
# Returns immediately so caelestia shell can start in parallel.
set -u

img=/tmp/caelestia-handoff.png
[[ -f $img ]] || exit 0

conf="${XDG_RUNTIME_DIR:-/tmp}/caelestia-handoff-hyprpaper.conf"
printf 'preload = %s\nwallpaper = ,%s\n' "$img" "$img" >"$conf"
/usr/bin/hyprpaper -c "$conf" >/dev/null 2>&1 &
disown || true
exit 0
