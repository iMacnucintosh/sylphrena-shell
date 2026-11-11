#!/usr/bin/env bash
# Install an app of the Sylphrena family (Seeker, Things) from its own repository, the Arch way:
# clone it, install its dependencies, build the package of packaging/PKGBUILD with makepkg and
# install it with pacman -U. Used by the welcome assistant.
#
#   install-companion.sh <owner/repo>           the sudo password arrives on stdin (first line)
#   install-companion.sh --dry-run <owner/repo> everything except the two sudo steps (no password)
#
# The password is kept ONLY in the memory of the askpass helper (unix socket in $XDG_RUNTIME_DIR),
# like scripts/run-system-update.sh: nothing with it is written to disk, nor in argv or the
# environment. Progress goes to stdout as "==> …" lines.
#
# Trust: this runs the PKGBUILD of the repository as your user and installs the result as root, so
# only repositories listed in services/Companions.qml are ever passed to it (the name is checked).
# For tests, SYLPHRENA_COMPANION_URL / SYLPHRENA_COMPANION_REF replace the GitHub URL and the branch.
set -euo pipefail

DRY=0
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY=1
    shift
fi
REPO="${1:-}"
if [[ ! "$REPO" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]]; then
    echo "usage: install-companion.sh [--dry-run] <owner/repo>" >&2
    exit 2
fi
URL="${SYLPHRENA_COMPANION_URL:-https://github.com/${REPO}.git}"
REF="${SYLPHRENA_COMPANION_REF:-}"

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
HELPER="${SCRIPT_DIR}/sudo-askpass-helper.py"
ASKPASS="${SCRIPT_DIR}/sudo-askpass-socket.py"
SOCK="${XDG_RUNTIME_DIR:-/tmp}/sylphrena-companion-$$.sock"
WORK=""
helper_pid=""

cleanup() {
    if [[ -n "${helper_pid}" ]]; then
        kill "${helper_pid}" 2>/dev/null || true
        wait "${helper_pid}" 2>/dev/null || true
    fi
    rm -f "${SOCK}"
    [[ -n "${WORK}" ]] && rm -rf "${WORK}"
}
trap cleanup EXIT

step() { echo "==> $*"; }

for tool in git makepkg; do
    command -v "$tool" >/dev/null || { echo "$tool is required (pacman -S base-devel git)" >&2; exit 3; }
done

if [[ $DRY -eq 0 ]]; then
    IFS= read -r PASSWORD || true
    if [[ -z "${PASSWORD}" ]]; then
        echo "Password required" >&2
        exit 2
    fi
    printf '%s\n' "$PASSWORD" | python3 "$HELPER" "$SOCK" &
    helper_pid=$!
    PASSWORD=""
    for _ in $(seq 1 50); do
        [[ -S "$SOCK" ]] && break
        kill -0 "${helper_pid}" 2>/dev/null || { echo "Failed to start sudo askpass helper" >&2; exit 2; }
        sleep 0.05
    done
    [[ -S "$SOCK" ]] || { echo "Failed to start sudo askpass helper" >&2; exit 2; }
    export SUDO_ASKPASS="$ASKPASS"
    export SYLPHRENA_SUDO_ASKPASS_SOCK="$SOCK"
fi

WORK="$(mktemp -d "${XDG_RUNTIME_DIR:-/tmp}/sylphrena-companion.XXXXXX")"

step "Downloading ${REPO}"
if [[ -n "$REF" ]]; then
    git clone --quiet --depth 1 --branch "$REF" "$URL" "$WORK/src"
else
    git clone --quiet --depth 1 "$URL" "$WORK/src"
fi
[[ -f "$WORK/src/packaging/PKGBUILD" ]] || { echo "${REPO} has no packaging/PKGBUILD" >&2; exit 4; }
cd "$WORK/src/packaging"

# Dependencies declared by the PKGBUILD, read in a subshell (it is only sourced to get the arrays)
mapfile -t DEPS < <(bash -c 'source ./PKGBUILD; printf "%s\n" "${depends[@]:-}" "${makedepends[@]:-}"' | sed 's/[<>=].*//' | grep -v '^$' | sort -u)
if [[ ${#DEPS[@]} -gt 0 ]]; then
    step "Dependencies: ${DEPS[*]}"
    if [[ $DRY -eq 1 ]]; then
        echo "(dry run) would run: sudo -A pacman -S --needed --noconfirm ${DEPS[*]}"
    else
        sudo -A -- pacman -S --needed --noconfirm "${DEPS[@]}"
    fi
fi

step "Building the package"
makepkg -f --noconfirm --nocheck 2>&1

mapfile -t PKGS < <(ls -1 ./*.pkg.tar.* 2>/dev/null | grep -v -- '-debug-' || true)
if [[ ${#PKGS[@]} -eq 0 ]]; then
    echo "makepkg did not produce a package" >&2
    exit 5
fi

step "Installing ${PKGS[*]##*/}"
if [[ $DRY -eq 1 ]]; then
    echo "(dry run) would run: sudo -A pacman -U --noconfirm ${PKGS[*]##*/}"
else
    sudo -A -- pacman -U --noconfirm "${PKGS[@]}"
fi
step "Done"
