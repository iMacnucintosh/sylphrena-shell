#!/usr/bin/env bash
# Install Sylphrena pieces that live under /etc.
#
# Asks for root once (re-exec via sudo) and runs every step in
# scripts/system/NN-name.sh. A step is a file that defines step_main.
# Drop a new file there to add another privileged install; the next run
# of this script picks it up. User-owned refresh (theme, wallpaper) stays
# outside sudo: the greeter dir is chowned back to the invoking user.
#
#   scripts/install-system.sh
#   greeter/install-greeter.sh    # same entry, kept for the old path
set -euo pipefail

SELF="$(readlink -f "${BASH_SOURCE[0]}")"
ROOT="$(cd "$(dirname "$SELF")/.." && pwd)"

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Sylphrena system install. One root prompt."
  if [[ -t 0 ]] || sudo -n true 2>/dev/null; then
    exec sudo -- "$SELF" "$@"
  elif command -v pkexec >/dev/null; then
    exec pkexec "$SELF" "$@"
  else
    exec sudo -- "$SELF" "$@"
  fi
fi

OWNER="${SUDO_USER:-}"
if [[ -z "$OWNER" && -n "${PKEXEC_UID:-}" ]]; then
  OWNER="$(id -nu "$PKEXEC_UID")"
fi
if [[ -z "$OWNER" || "$OWNER" == "root" ]]; then
  echo "Run this from your user account so the greeter dir stays yours." >&2
  exit 1
fi
OWNER_HOME="$(getent passwd "$OWNER" | cut -d: -f6)"
if [[ -z "$OWNER_HOME" || ! -d "$OWNER_HOME" ]]; then
  echo "No home directory for $OWNER." >&2
  exit 1
fi

export SYLPHRENA_ROOT="$ROOT"
export SYLPHRENA_OWNER="$OWNER"
export SYLPHRENA_OWNER_HOME="$OWNER_HOME"

shopt -s nullglob
steps=("$ROOT"/scripts/system/[0-9]*.sh)
if [[ ${#steps[@]} -eq 0 ]]; then
  echo "No steps in $ROOT/scripts/system." >&2
  exit 1
fi

for step in "${steps[@]}"; do
  echo "== $(basename "$step") =="
  (
    # shellcheck disable=SC1090
    source "$step"
    step_main
  )
done

echo "Done."
