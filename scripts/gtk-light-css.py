#!/usr/bin/env python3
"""With light apps, keep the scheme's (dark) colours out of GTK apps.

The CLI writes ~/.config/gtk-{3,4}.0/gtk.css (+ thunar.css, mirrored into colors.css for the live
reload module) with the ACTIVITY scheme's named colours (window_bg_color, view_bg_color…). Over the
light adw-gtk3 base that paints headers, lists and inputs black while the rest stays light (DBeaver,
Octopi…). With light apps only the accent colours survive; everything else is the plain light theme.

    gtk-light-css.py            neutralise the existing files (idempotent) and bump the reload stamp
Also importable: light_css(filename, text) is what sylphrena-quiet.py applies while the CLI writes.
"""
from __future__ import annotations

import sys
import time
from pathlib import Path

HOME = Path.home()
VERSIONS = ("gtk-3.0", "gtk-4.0")
MARK = "/* light apps: only the accent colours of the scheme */"


def light_css(filename: str, text: str) -> str:
    """The light-apps version of a CSS file the CLI generated."""
    if filename == "thunar.css":
        return MARK + "\n"
    if filename == "colors.css":
        # Already derived from gtk.css; keep the leading reload stamp comment, filter the rest.
        lines = text.splitlines()
        stamp = lines[0] if lines and lines[0].startswith("/* sylphrena-reload") else ""
        body = "\n".join(lines[1:] if stamp else lines)
        return (stamp + "\n" if stamp else "") + light_css("gtk.css", body)
    kept = [ln for ln in text.splitlines() if ln.startswith("@define-color accent")]
    return MARK + "\n" + "\n".join(kept) + ("\n" if kept else "")


def neutralise() -> int:
    changed = 0
    for ver in VERSIONS:
        base = HOME / ".config" / ver
        for name in ("gtk.css", "thunar.css"):
            path = base / name
            if not path.is_file():
                continue
            old = path.read_text()
            new = light_css(name, old)
            if new != old:
                path.write_text(new)
                changed += 1
        # colors.css is what the colorreload module watches: rebuild it from the filtered gtk.css
        gtk_css = base / "gtk.css"
        if gtk_css.is_file():
            stamp = f"/* sylphrena-reload {time.time_ns()} */\n"
            (base / "colors.css").write_text(stamp + gtk_css.read_text())
    return changed


if __name__ == "__main__":
    print(f"neutralised {neutralise()} file(s)", file=sys.stderr)
