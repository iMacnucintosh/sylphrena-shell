#!/usr/bin/env bash
# Install / refresh the Caelestia Quickshell greeter for greetd.
# Safe to re-run. Needs sudo only for the root-owned greetd compositor config.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GREETER_DIR="${CAELESTIA_GREETER_DIR:-/etc/greetd/caelestia}"
QS_DST="$GREETER_DIR/qs"
LUA_SRC="$ROOT/greeter/hyprland-greeter.lua"
LAUNCH_SRC="$ROOT/greeter/launch-qs.sh"

if [[ ! -d "$GREETER_DIR" ]]; then
  echo "Missing $GREETER_DIR — create it (chown to your user) before installing." >&2
  exit 1
fi

mkdir -p "$QS_DST"
rsync -a --delete \
  --exclude 'install-greeter.sh' \
  --exclude 'hyprland-greeter.lua' \
  --exclude 'launch-qs.sh' \
  --exclude 'config.toml.snippet' \
  "$ROOT/greeter/" "$QS_DST/"

cp -f "$LUA_SRC" "$GREETER_DIR/hyprland-greeter.lua"
cp -f "$LAUNCH_SRC" "$GREETER_DIR/launch-qs.sh"
chmod 755 "$GREETER_DIR/launch-qs.sh"

# Palette / wallpaper / face / font (also refreshes qs via _sync_greeter_ui).
python3 - <<'PY'
from pathlib import Path

quiet = Path.home() / ".config/quickshell/caelestia/scripts/caelestia-quiet.py"
src = quiet.read_text()
cut = src.find('\nif __name__')
ns: dict = {"__name__": "caelestia_quiet", "__file__": str(quiet)}
exec(compile(src if cut < 0 else src[:cut], str(quiet), "exec"), ns)
ns["_sync_greeter"]()
print(f"Synced greeter assets into {ns['_GREETER_DIR']}")
PY

# Keep launch wrapper after quiet sync (which only mirrors qs/).
cp -f "$LAUNCH_SRC" "$GREETER_DIR/launch-qs.sh"
chmod 755 "$GREETER_DIR/launch-qs.sh"

elevate() {
  if sudo -n true 2>/dev/null; then
    sudo "$@"
  elif command -v pkexec >/dev/null; then
    pkexec "$@"
  else
    sudo "$@"
  fi
}

echo "Installing compositor + greetd config (needs elevation)…"
elevate cp -f "$GREETER_DIR/hyprland-greeter.lua" /etc/greetd/hyprland-greeter.lua

# greeter passwd HOME is `/` — Hyprland must start with a real HOME or it
# tries to write /hyprland.log and the greeter looks like a black void.
# Do not wrap this in dbus-run-session: its private bus kept the greeter PAM
# session alive for ~5.3 s after qs/Hyprland exited, exposing the old VT.
# pam_systemd already provides the greeter user's normal runtime/user bus.
GREETD_CMD='env HOME=/var/lib/regreet XDG_CACHE_HOME=/var/lib/regreet/cache XDG_CONFIG_HOME=/var/lib/regreet/config XDG_STATE_HOME=/var/lib/regreet/state QT_QPA_PLATFORM=wayland XKB_DEFAULT_LAYOUT=es /usr/bin/start-hyprland -- -c /etc/greetd/hyprland-greeter.lua'
elevate tee /etc/greetd/config.toml >/dev/null <<EOF
[terminal]
vt = 1

# Primera sesión del boot: autologin directo a Hyprland (como plasmalogin).
[initial_session]
command = "/usr/bin/start-hyprland"
user = "manu"

# Tras cerrar sesión desde Hyprland: greeter Quickshell (Material You) sobre Hyprland.
# HOME/XDG se fijan aquí porque el usuario greeter tiene HOME=/ en passwd.
[default_session]
command = "${GREETD_CMD}"
# Rollback a CLI: sustituir por tuigreet.
# command = "/usr/bin/tuigreet --time --cmd /usr/bin/start-hyprland"
user = "greeter"
EOF

echo "Done. Boot autologin unchanged; after logout you get the Quickshell greeter."
echo "Logs: /var/lib/regreet/state/qs.log and /tmp/caelestia-greeter-qs.log"
echo "Rollback: restore regreet exec — see comments in greeter/hyprland-greeter.lua"
