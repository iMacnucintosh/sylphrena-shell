#!/usr/bin/env bash
# Sylphrena installer entry point: makes sure git, base-devel and python are there, then runs scripts/installer.py.
#   ./install.sh [--yes] [--dry-run] [--list] [--only ID,ID] [--skip ID,ID] [--no-login-screen]
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ "$(id -u)" -eq 0 ]]; then
  echo "Do not run this as root: the AUR packages cannot be built as root. Run it as your user; it asks for sudo when it needs it." >&2
  exit 1
fi
if [[ ! -e /etc/arch-release ]] && ! command -v pacman >/dev/null; then
  echo "This installer is for Arch Linux and its derivatives." >&2
  exit 1
fi

# python is what the installer is written in; git and base-devel are what building from the AUR needs
missing=()
command -v python3 >/dev/null || missing+=(python)
command -v git >/dev/null || missing+=(git)
pacman -Qq base-devel >/dev/null 2>&1 || missing+=(base-devel)
if [[ ${#missing[@]} -gt 0 && " $* " != *" --dry-run "* && " $* " != *" --list "* ]]; then
  echo "Installing the base tools first: ${missing[*]}"
  sudo pacman -S --needed --noconfirm "${missing[@]}"
fi

exec python3 "$ROOT/scripts/installer.py" "$@"
