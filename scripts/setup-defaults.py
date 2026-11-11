#!/usr/bin/env python3
"""First run: give a new install the recommended settings.

  setup-defaults.py [--check] [--force]

If there is no ~/.config/sylphrena/shell.json (or it holds nothing), write assets/defaults/shell.json there:
the settings Sylphrena is meant to be used with (bar, dashboard, launcher, notifications, utilities…), one
activity (Principal, two desktops) and its wallpaper, which ships with the shell (assets/wallpapers/). It
never touches an existing configuration, and it runs once: ~/.local/state/sylphrena/defaults.json remembers it.
--force ignores that memory (still without overwriting a configuration that has content); --check only reports.
Prints {"status": "done" | "kept" | "seen" | "needed", "wallpaper": <path or "">}.
"""
import json
import os
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
SHELL = HERE.parent
TEMPLATE = SHELL / "assets" / "defaults" / "shell.json"
WALLPAPER = SHELL / "assets" / "wallpapers" / "trail-of-footprints.jpg"
PLACEHOLDER = "@DEFAULT_WALLPAPER@"


def dirs() -> tuple[Path, Path]:
    config = Path(os.environ.get("XDG_CONFIG_HOME") or Path.home() / ".config") / "sylphrena"
    state = Path(os.environ.get("XDG_STATE_HOME") or Path.home() / ".local/state") / "sylphrena"
    return config, state


def has_content(path: Path) -> bool:
    try:
        data = json.loads(path.read_text())
    except OSError:
        return False
    except ValueError:
        return True  # something is there that is not ours to replace
    return bool(data)


def render() -> str:
    """The template with the wallpaper of this shell; without the file the activity keeps no wallpaper."""
    doc = json.loads(TEMPLATE.read_text())
    for act in doc.get("activities", {}).get("activities", []):
        if act.get("wallpaper") == PLACEHOLDER:
            if WALLPAPER.is_file():
                act["wallpaper"] = str(WALLPAPER)
            else:
                act.pop("wallpaper")
    return json.dumps(doc, indent=4, ensure_ascii=False) + "\n"


def write_atomic(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp = tempfile.mkstemp(dir=path.parent, prefix=".shell.json.")
    with os.fdopen(fd, "w") as f:
        f.write(text)
    os.replace(tmp, path)


def main() -> int:
    check = "--check" in sys.argv
    force = "--force" in sys.argv
    config, state = dirs()
    target = config / "shell.json"
    marker = state / "defaults.json"
    wall = str(WALLPAPER) if WALLPAPER.is_file() else ""

    def out(status: str) -> int:
        print(json.dumps({"status": status, "wallpaper": wall}))
        return 0

    if marker.exists() and not force:
        return out("seen")
    if has_content(target):
        if not check:
            write_atomic(marker, json.dumps({"applied": False, "reason": "existing configuration"}) + "\n")
        return out("kept")
    if check:
        return out("needed")
    write_atomic(target, render())
    write_atomic(marker, json.dumps({"applied": True}) + "\n")
    return out("done")


if __name__ == "__main__":
    raise SystemExit(main())
