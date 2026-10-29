#!/usr/bin/env bash
# Keep compositor startup chatter off tty1 during the greetd DRM handoff.
set -u
# A 27 GiB Cursor coredump held user@1000 for ~55s and blocked the next login.
ulimit -c 0 2>/dev/null || true

state_dir="${XDG_STATE_HOME:-${HOME:-/tmp}/.local/state}/caelestia"
if ! mkdir -p "$state_dir" 2>/dev/null; then
  state_dir=/tmp
fi
export CAELESTIA_QUIET_LOG="$state_dir/session-startup.log"

here="$(cd "$(dirname "$0")" && pwd)"
exec "$here/quiet-exec.sh" "$@"
