#!/usr/bin/env python3
"""Rename renamed config keys in the user's shell.json (idempotent).

Run at shell start. The config watcher reloads the file when it changes, so the migrated values
apply live. Each entry maps an old dotted path to its new one; the old value is moved only when the
new key is not already set, and the old key is always removed.
"""
import json
import os
import sys
from pathlib import Path

RENAMES = {
    "addons.madisonVpn": "addons.fortiVpn",  # Madison VPN -> VPN FortiClient (v0.2)
}


def take(d: dict, path: str):
    *parents, leaf = path.split(".")
    for p in parents:
        d = d.get(p)
        if not isinstance(d, dict):
            return None, False
    return (d.pop(leaf), True) if leaf in d else (None, False)


def put(d: dict, path: str, value) -> bool:
    *parents, leaf = path.split(".")
    for p in parents:
        d = d.setdefault(p, {})
    if leaf in d:
        return False
    d[leaf] = value
    return True


def main() -> int:
    base = Path(os.environ.get("XDG_CONFIG_HOME") or Path.home() / ".config")
    path = base / "sylphrena" / "shell.json"
    try:
        data = json.loads(path.read_text())
    except (OSError, ValueError):
        return 0
    changed = False
    for old, new in RENAMES.items():
        value, found = take(data, old)
        if found:
            put(data, new, value)
            changed = True
    if changed:
        tmp = path.with_suffix(".json.tmp")
        tmp.write_text(json.dumps(data, indent=4, ensure_ascii=False) + "\n")
        tmp.replace(path)
        print("migrated shell.json", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
