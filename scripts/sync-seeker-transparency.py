#!/usr/bin/env python3
"""Update transparency in ~/.config/seeker/theme.json without touching colours."""

from __future__ import annotations

import argparse
import json
import os
import tempfile
from pathlib import Path

OUT = Path.home() / ".config" / "seeker" / "theme.json"


def atomic_write(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp = tempfile.mkstemp(dir=str(path.parent), prefix=".theme-", suffix=".tmp")
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as f:
            f.write(text)
        os.replace(tmp, path)
    except Exception:
        try:
            os.unlink(tmp)
        except OSError:
            pass
        raise


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--enabled", action=argparse.BooleanOptionalAction, default=None)
    p.add_argument("--base", type=float, default=None)
    p.add_argument("--layers", type=float, default=None)
    p.add_argument("--wall-luminance", type=float, default=None, dest="wall_luminance")
    args = p.parse_args()

    data: dict = {}
    if OUT.is_file():
        try:
            data = json.loads(OUT.read_text(encoding="utf-8") or "{}")
        except json.JSONDecodeError:
            data = {}
    if not isinstance(data, dict):
        data = {}

    tr = data.get("transparency")
    if not isinstance(tr, dict):
        tr = {}
    if args.enabled is not None:
        tr["enabled"] = bool(args.enabled)
    if args.base is not None:
        tr["base"] = max(0.0, min(1.0, float(args.base)))
    # Same numbers the shell's Colours.layer() uses, so Seeker builds identical translucent layers.
    if args.layers is not None:
        tr["layers"] = max(0.0, min(1.0, float(args.layers)))
    if args.wall_luminance is not None:
        tr["wallLuminance"] = max(0.0, min(1.0, float(args.wall_luminance)))
    tr.setdefault("enabled", False)
    tr.setdefault("base", 0.85)
    tr.setdefault("layers", 0.4)
    tr.setdefault("wallLuminance", 0.5)
    data["transparency"] = tr

    atomic_write(OUT, json.dumps(data, indent=2) + "\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
