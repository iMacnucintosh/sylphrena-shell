#!/usr/bin/env bash
# Keep compositor startup chatter off tty1 during the greetd DRM handoff.
set -u

state_dir="${XDG_STATE_HOME:-${HOME:-/tmp}/.local/state}/caelestia"
if ! mkdir -p "$state_dir" 2>/dev/null; then
  state_dir=/tmp
fi
log="$state_dir/session-startup.log"

exec >>"$log" 2>&1
printf '\n==== %s ====\n' "$(date -Is)"
exec "$@"
