#!/usr/bin/env bash
# Run a compositor with no controlling TTY and no stdout on the VT.
# Hyprland prints its ASCII logo *before* reading config; if that hits tty1,
# the kernel flashes it for one frame when DRM is handed between compositors.
set -u

if (( $# < 1 )); then
  echo "usage: quiet-exec.sh command [args...]" >&2
  exit 2
fi

log="${CAELESTIA_QUIET_LOG:-/tmp/caelestia-quiet.log}"
mkdir -p "$(dirname "$log")" 2>/dev/null || log=/tmp/caelestia-quiet.log

exec /usr/bin/python3 - "$log" "$@" <<'PY'
import fcntl
import os
import signal
import sys
import termios

log = sys.argv[1]
args = sys.argv[2:]
if not args:
    sys.exit("quiet-exec: missing command")

signal.signal(signal.SIGHUP, signal.SIG_IGN)

# Drop the controlling TTY first, while /dev/tty still resolves.
try:
    tty = os.open("/dev/tty", os.O_RDWR)
    fcntl.ioctl(tty, termios.TIOCNOTTY)
    os.close(tty)
except OSError:
    pass

fd = os.open(log, os.O_WRONLY | os.O_CREAT | os.O_APPEND, 0o644)
os.dup2(fd, 1)
os.dup2(fd, 2)
os.close(fd)

devnull = os.open(os.devnull, os.O_RDONLY)
os.dup2(devnull, 0)
os.close(devnull)

try:
    tty1 = os.open("/dev/tty1", os.O_WRONLY)
    os.write(tty1, b"\033c\033[2J\033[3J\033[H\033[?25l")
    os.close(tty1)
except OSError:
    pass

os.execvp(args[0], args)
PY
