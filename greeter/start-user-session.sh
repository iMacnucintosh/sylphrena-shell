#!/usr/bin/env bash
# Keep compositor startup chatter off tty1 during the greetd DRM handoff.
set -u

state_dir="${XDG_STATE_HOME:-${HOME:-/tmp}/.local/state}/caelestia"
if ! mkdir -p "$state_dir" 2>/dev/null; then
  state_dir=/tmp
fi
export CAELESTIA_QUIET_LOG="$state_dir/session-startup.log"

here="$(cd "$(dirname "$0")" && pwd)"
exec "$here/quiet-exec.sh" "$@"
