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

# Old boolean switch -> id added to a list when it was on. The old key is always removed.
ENABLES = {
    "dashboard.tasksEnabled": ("extensions.enabled", "tasks"),  # Tasks became an extension (v0.2)
    "addons.hydration.enabled": ("extensions.enabled", "hydration"),  # Hydration too (v0.2)
    "addons.fortiVpn.enabled": ("extensions.enabled", "vpn-forticlient"),
    "addons.steam.enabled": ("extensions.enabled", "games"),
}

# Old shell.json setting -> (extension id, key in ~/.config/sylphrena/extensions/<id>.json).
# The value is written to the extension's own config unless that key is already there.
TO_EXTENSION_CONFIG = {
    "addons.hydration.dailyGoalMl": ("hydration", "dailyGoalMl"),
    "addons.hydration.reminderMinutes": ("hydration", "reminderMinutes"),
    "addons.hydration.presetMl0": ("hydration", "presetMl0"),
    "addons.hydration.presetMl1": ("hydration", "presetMl1"),
    "addons.hydration.presetMl2": ("hydration", "presetMl2"),
    "addons.hydration.presetMl3": ("hydration", "presetMl3"),
    "addons.steam.apiKey": ("games", "apiKey"),
    "addons.steam.steamId": ("games", "steamId"),
    "addons.steam.refreshMinutes": ("games", "refreshMinutes"),
}

# Removed features: their settings are dropped, and their id leaves extensions.enabled.
REMOVED_KEYS = [
    "addons.razerMouse",  # the Razer mouse battery was removed (v0.3)
    "paths.sessionGif",  # the animated character of the session menu was removed (v0.5)
    "general.sessionGifSpeed",
    "paths.mediaGif",  # the dancing cat of the dashboard's media card was removed (v0.5)
    "general.mediaGifSpeedAdjustment",
    # options of the old workspace strip of the base, which the activities strip replaced (v0.5)
    "bar.workspaces.shown",
    "bar.workspaces.showUnoccupied",
    "bar.workspaces.showWindowsOnSpecialWorkspaces",
    "bar.workspaces.specialDisplayType",
    "utilities.toasts.kbLimit",  # the "more than four keyboard layouts" toast went with the old keyboard popout (v0.5)
]
REMOVED_EXTENSIONS = ["razer-mouse"]

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
    # Extension settings first: if shell.json is rewritten, the extensions must already find them
    for old, (ext_id, key) in TO_EXTENSION_CONFIG.items():
        value, found = take(data, old)
        if not found:
            continue
        changed = True
        ext_path = base / "sylphrena" / "extensions" / f"{ext_id}.json"
        try:
            ext_cfg = json.loads(ext_path.read_text())
            if not isinstance(ext_cfg, dict):
                ext_cfg = {}
        except (OSError, ValueError):
            ext_cfg = {}
        if key not in ext_cfg:
            ext_cfg[key] = value
            ext_path.parent.mkdir(parents=True, exist_ok=True)
            tmp = ext_path.with_suffix(".json.tmp")
            tmp.write_text(json.dumps(ext_cfg, indent=2, ensure_ascii=False) + "\n")
            tmp.replace(ext_path)
    for old, new in RENAMES.items():
        value, found = take(data, old)
        if found:
            put(data, new, value)
            changed = True
    for old, (list_path, item) in ENABLES.items():
        value, found = take(data, old)
        if not found:
            continue
        changed = True
        if value:
            *parents, leaf = list_path.split(".")
            node = data
            for p in parents:
                node = node.setdefault(p, {})
            items = node.setdefault(leaf, [])
            if item not in items:
                items.append(item)
    for old in REMOVED_KEYS:
        if take(data, old)[1]:
            changed = True
    enabled = data.get("extensions", {}).get("enabled") if isinstance(data.get("extensions"), dict) else None
    if isinstance(enabled, list):
        kept = [i for i in enabled if i not in REMOVED_EXTENSIONS]
        if kept != enabled:
            data["extensions"]["enabled"] = kept
            changed = True
    if changed:
        # Drop sections the migration left empty (e.g. addons.hydration)
        addons = data.get("addons")
        if isinstance(addons, dict):
            for k in [k for k, v in addons.items() if v == {}]:
                del addons[k]
        tmp = path.with_suffix(".json.tmp")
        tmp.write_text(json.dumps(data, indent=4, ensure_ascii=False) + "\n")
        tmp.replace(path)
        print("migrated shell.json", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
