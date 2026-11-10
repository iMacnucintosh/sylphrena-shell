#!/usr/bin/env python3
"""Sync sylphrena cli.json theme hooks for shell-dark / apps-light mode."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

# After colours apply, restore prefer-light when the shell asked for light apps.
# GTK/Thunar CSS still updates (enableGtk stays on) so the file manager follows
# the activity scheme; color-scheme prefer-light covers Adwaita/Qt apps.
POST_HOOK = (
    'test -f "${XDG_STATE_HOME:-$HOME/.local/state}/sylphrena/force-apps-light" '
    '&& dconf write /org/gnome/desktop/interface/color-scheme "\'prefer-light\'"'
    ' ; "$HOME/.config/sylphrena/scripts/kitty-reload-colours.sh" || true'
)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--light-apps", action=argparse.BooleanOptionalAction, required=True)
    args = parser.parse_args()

    path = Path.home() / ".config/sylphrena/cli.json"
    cfg: dict = {}
    if path.exists():
        try:
            cfg = json.loads(path.read_text() or "{}")
        except json.JSONDecodeError:
            cfg = {}

    theme = cfg.setdefault("theme", {})
    theme["postHook"] = POST_HOOK
    # The CLI keeps running for GTK (dconf icon theme, Papirus colours); with light apps the CSS it
    # writes is filtered down to the accent colours (sylphrena-quiet.py / gtk-light-css.py).
    theme["enableGtk"] = True
    # Skip Qt colour engine while apps should stay light.
    theme["enableQt"] = not args.light_apps

    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(cfg, indent=4) + "\n")

    if args.light_apps:
        # Turning light apps ON: clean the dark GTK CSS that is already on disk right now instead of
        # waiting for the next scheme apply.
        import subprocess
        import sys

        subprocess.run([sys.executable, str(Path(__file__).with_name("gtk-light-css.py"))], check=False)


if __name__ == "__main__":
    main()
