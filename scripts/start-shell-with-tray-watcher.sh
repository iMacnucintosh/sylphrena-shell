#!/usr/bin/env bash
# Ensure the persistent StatusNotifierWatcher is running, then start the
# Sylphrena shell as a StatusNotifierHost. See status-notifier-watcher.py.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WATCHER="${ROOT}/scripts/status-notifier-watcher.py"
SYLPH="${SYLPH:-/home/manu/.local/bin/sylph}"

python3 "$WATCHER"

# On a cold start we own the name immediately. Mid-session qs may still hold
# it until the next `sylph shell -r`; either way the shell can start.
for _ in $(seq 1 50); do
  if [[ -f "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/sylphrena/status-notifier-watcher.pid" ]]; then
    break
  fi
  sleep 0.05
done

exec "$SYLPH" shell -d "$@"
