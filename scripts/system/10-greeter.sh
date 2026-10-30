# Greeter Quickshell for greetd.
# Sourced as root by scripts/install-system.sh. Defines step_main.
# Safe to re-run. Migrates /etc/greetd/sylphrena → sylphrena and leaves
# the old name as a symlink.

step_main() {
  local greeter_dir old_dir session_user qs_dst
  greeter_dir="${SYLPHRENA_GREETER_DIR:-/etc/greetd/sylphrena}"
  old_dir="/etc/greetd/sylphrena"
  qs_dst="$greeter_dir/qs"

  if [[ -d "$old_dir" && ! -L "$old_dir" && ! -e "$greeter_dir" ]]; then
    echo "Moving $old_dir → $greeter_dir"
    mv "$old_dir" "$greeter_dir"
  fi
  if [[ -e "$greeter_dir" && -e "$old_dir" && ! -L "$old_dir" && ! -L "$greeter_dir" ]]; then
    echo "Both $old_dir and $greeter_dir are real directories. Not merging." >&2
    exit 1
  fi
  mkdir -p "$greeter_dir"
  if [[ ! -e "$old_dir" ]]; then
    ln -s "$(basename "$greeter_dir")" "$old_dir"
  fi

  mkdir -p "$qs_dst"
  rsync -a --delete \
    --exclude 'install-greeter.sh' \
    --exclude 'hyprland-greeter.lua' \
    --exclude 'launch-qs.sh' \
    --exclude 'exit-compositor.sh' \
    --exclude 'start-user-session.sh' \
    --exclude 'quiet-exec.sh' \
    --exclude 'start-greeter-compositor.sh' \
    --exclude 'systemd' \
    --exclude 'config.toml.snippet' \
    "$SYLPHRENA_ROOT/greeter/" "$qs_dst/"

  install_wrappers() {
    cp -f "$SYLPHRENA_ROOT/greeter/hyprland-greeter.lua" "$greeter_dir/hyprland-greeter.lua"
    cp -f "$SYLPHRENA_ROOT/greeter/launch-qs.sh" "$greeter_dir/launch-qs.sh"
    cp -f "$SYLPHRENA_ROOT/greeter/exit-compositor.sh" "$greeter_dir/exit-compositor.sh"
    cp -f "$SYLPHRENA_ROOT/greeter/start-user-session.sh" "$greeter_dir/start-user-session.sh"
    cp -f "$SYLPHRENA_ROOT/greeter/quiet-exec.sh" "$greeter_dir/quiet-exec.sh"
    cp -f "$SYLPHRENA_ROOT/greeter/start-greeter-compositor.sh" "$greeter_dir/start-greeter-compositor.sh"
    chmod 755 "$greeter_dir/launch-qs.sh" "$greeter_dir/exit-compositor.sh" \
      "$greeter_dir/start-user-session.sh" "$greeter_dir/quiet-exec.sh" \
      "$greeter_dir/start-greeter-compositor.sh"
  }

  install_wrappers
  chown -R "$SYLPHRENA_OWNER:$SYLPHRENA_OWNER" "$greeter_dir"

  # Scheme, wallpaper and face come from the session user. Path.home()
  # would be /root if this ran as root.
  runuser -u "$SYLPHRENA_OWNER" -- env \
    SYLPHRENA_GREETER_DIR="$greeter_dir" \
    SYLPHRENA_ROOT="$SYLPHRENA_ROOT" \
    HOME="$SYLPHRENA_OWNER_HOME" \
    python3 - <<'PY'
import os
from pathlib import Path

quiet = Path(os.environ["SYLPHRENA_ROOT"]) / "scripts" / "sylphrena-quiet.py"
src = quiet.read_text()
cut = src.find("\nif __name__")
ns: dict = {"__name__": "sylphrena_quiet", "__file__": str(quiet)}
exec(compile(src if cut < 0 else src[:cut], str(quiet), "exec"), ns)
ns["_sync_greeter"]()
print(f"Synced greeter assets into {ns['_GREETER_DIR']}")
PY

  install_wrappers
  chown -R "$SYLPHRENA_OWNER:$SYLPHRENA_OWNER" "$greeter_dir"

  install -m 644 "$SYLPHRENA_ROOT/greeter/hyprland-greeter.lua" /etc/greetd/hyprland-greeter.lua

  session_user="$(awk '
    /^\[/ { sec = $0 }
    sec == "[initial_session]" && $0 ~ /^user = / {
      split($0, a, "\"")
      print a[2]
      exit
    }
  ' /etc/greetd/config.toml 2>/dev/null || true)"
  session_user="${session_user:-$SYLPHRENA_OWNER}"

  cat > /etc/greetd/config.toml <<EOF
[terminal]
vt = 1

# Primera sesión del boot: autologin directo a Hyprland (como plasmalogin).
# Wrapped so the ASCII logo/cursor never hits tty1.
[initial_session]
command = "${greeter_dir}/start-user-session.sh /usr/bin/start-hyprland"
user = "${session_user}"

# Tras cerrar sesión desde Hyprland: greeter Quickshell (Material You) sobre Hyprland.
# HOME/XDG se fijan aquí porque el usuario greeter tiene HOME=/ en passwd.
[default_session]
command = "${greeter_dir}/start-greeter-compositor.sh"
# Rollback a CLI: sustituir por tuigreet.
# command = "/usr/bin/tuigreet --time --cmd /usr/bin/start-hyprland"
user = "greeter"
EOF

  mkdir -p /etc/systemd/logind.conf.d /etc/systemd/system/user@.service.d
  install -m 644 "$SYLPHRENA_ROOT/greeter/systemd/logind.conf" \
    /etc/systemd/logind.conf.d/sylphrena-greeter.conf
  install -m 644 "$SYLPHRENA_ROOT/greeter/systemd/user-service.conf" \
    /etc/systemd/system/user@.service.d/sylphrena-timeout.conf
  rm -f /etc/systemd/logind.conf.d/sylphrena-greeter.conf \
    /etc/systemd/system/user@.service.d/sylphrena-timeout.conf
  systemctl daemon-reload
  systemctl reload systemd-logind.service

  echo "Greeter dir: $greeter_dir (symlink $old_dir)"
  echo "greetd initial_session user: $session_user"
  echo "Logs: /var/lib/regreet/state/qs.log and /tmp/sylphrena-greeter-qs.log"
}
