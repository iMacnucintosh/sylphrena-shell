# Root helper of the vpn-forticlient extension (FortiClient / openfortivpn connections).
# Sourced as root by scripts/install-system.sh. Defines step_main. Safe to re-run.
# Installs /usr/local/sbin/sylphrena-fortivpn (root-owned copy, so later edits of the repo never
# change what runs as root) and a sudoers rule that lets the installing user run only that file
# without a password. Skipped when openfortivpn is not installed.

step_main() {
  local src="$SYLPHRENA_ROOT/extensions/vpn-forticlient/helper/sylphrena-fortivpn"
  local dst=/usr/local/sbin/sylphrena-fortivpn
  local rule=/etc/sudoers.d/sylphrena-fortivpn
  local tmp

  if ! command -v openfortivpn >/dev/null 2>&1; then
    echo "openfortivpn is not installed: skipping the FortiClient helper."
    return 0
  fi

  install -o root -g root -m 0755 "$src" "$dst"

  tmp="$(mktemp)"
  printf '%s ALL=(root) NOPASSWD: %s\n' "$SYLPHRENA_OWNER" "$dst" >"$tmp"
  if ! visudo -cqf "$tmp"; then
    rm -f "$tmp"
    echo "The sudoers rule did not validate; not installed." >&2
    exit 1
  fi
  install -o root -g root -m 0440 "$tmp" "$rule"
  rm -f "$tmp"
  echo "Installed $dst and $rule (for $SYLPHRENA_OWNER)."
}
