#!/usr/bin/env bash
# Noninteractive system update for the bar/Nexus installers.
# The sudo password arrives via stdin (first line) and is kept ONLY in the
# askpass helper process' memory (unix socket in $XDG_RUNTIME_DIR). Nothing
# with the password is written to disk — a previous temp file lived for the
# whole installation. yay/pacman use `-A` so each sudo call hits askpass
# (the sudo timestamp is per-TTY and does not survive a Quickshell Process).
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
HELPER="${SCRIPT_DIR}/sudo-askpass-helper.py"
ASKPASS="${SCRIPT_DIR}/sudo-askpass-socket.py"
SOCK="${XDG_RUNTIME_DIR:-/tmp}/sylphrena-sudo-$$.sock"
helper_pid=""

IFS= read -r PASSWORD || true
if [[ -z "${PASSWORD}" ]]; then
    echo "Password required" >&2
    exit 2
fi

cleanup() {
    if [[ -n "${helper_pid}" ]]; then
        kill "${helper_pid}" 2>/dev/null || true
        wait "${helper_pid}" 2>/dev/null || true
        helper_pid=""
    fi
    rm -f "${SOCK}"
}
trap cleanup EXIT

printf '%s\n' "$PASSWORD" | python3 "$HELPER" "$SOCK" &
helper_pid=$!
PASSWORD=""

for _ in $(seq 1 50); do
    if [[ -S "$SOCK" ]]; then
        break
    fi
    if ! kill -0 "${helper_pid}" 2>/dev/null; then
        echo "Failed to start sudo askpass helper" >&2
        exit 2
    fi
    sleep 0.05
done
if [[ ! -S "$SOCK" ]]; then
    echo "Failed to start sudo askpass helper" >&2
    exit 2
fi

export SUDO_ASKPASS="$ASKPASS"
export SYLPHRENA_SUDO_ASKPASS_SOCK="$SOCK"

do_aur=0
do_arch=0
do_flatpak=0
wrapper="yay"
aur_flags=()
flatpak_flags=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --aur)
            do_aur=1
            wrapper="${2:-yay}"
            shift 2
            ;;
        --arch)
            do_arch=1
            shift
            ;;
        --flatpak)
            do_flatpak=1
            shift
            ;;
        --aur-flag)
            aur_flags+=("$2")
            shift 2
            ;;
        --flatpak-flag)
            flatpak_flags+=("$2")
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

if [[ "$do_aur" -eq 1 ]]; then
    echo "→ ${wrapper} -Syu --noconfirm --sudoflags=-A ${aur_flags[*]-}"
    "$wrapper" -Syu --noconfirm --sudoflags=-A ${aur_flags[@]+"${aur_flags[@]}"}
fi

if [[ "$do_arch" -eq 1 ]]; then
    echo "→ sudo -A pacman -Syu --noconfirm"
    sudo -A pacman -Syu --noconfirm
fi

if [[ "$do_flatpak" -eq 1 ]]; then
    echo "→ flatpak update -y ${flatpak_flags[*]-}"
    flatpak update -y ${flatpak_flags[@]+"${flatpak_flags[@]}"}
fi

echo "Update finished."
