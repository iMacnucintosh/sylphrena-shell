# BlueZ in experimental mode, so PipeWire can publish the battery of AirPods
# (read from Apple's HFP extension) through the BlueZ battery provider API.
# Sourced as root by scripts/install-system.sh. Defines step_main.
# Safe to re-run; keeps a one-time backup next to the config.
# SYLPHRENA_BLUEZ_CONF points it at another file (tests) and skips the restart.

step_main() {
  local conf="${SYLPHRENA_BLUEZ_CONF:-/etc/bluetooth/main.conf}"

  if grep -qE '^[[:space:]]*Experimental[[:space:]]*=[[:space:]]*true' "$conf"; then
    echo "bluetooth: Experimental already enabled"
    return 0
  fi

  [[ -e "$conf.sylphrena.bak" ]] || cp -a "$conf" "$conf.sylphrena.bak"

  if grep -qE '^[[:space:]]*#?[[:space:]]*Experimental[[:space:]]*=' "$conf"; then
    sed -i -E '0,/^[[:space:]]*#?[[:space:]]*Experimental[[:space:]]*=.*/s//Experimental = true/' "$conf"
  else
    sed -i '0,/^\[General\]/s//[General]\nExperimental = true/' "$conf"
  fi
  echo "bluetooth: Experimental = true in $conf"

  if [[ -z "${SYLPHRENA_BLUEZ_CONF:-}" ]]; then
    # Drops every Bluetooth device for a few seconds; they reconnect on their own.
    systemctl restart bluetooth
  fi
}
