#!/usr/bin/env bash
# Compatibility entry. The installer lives in scripts/install-system.sh
# and asks for root once for every system step (greeter today).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
exec "$ROOT/scripts/install-system.sh" "$@"
