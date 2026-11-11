#!/usr/bin/env python3
"""Writes the translatable strings of every extension manifest as Tr.tr() calls, for xgettext.

Manifests are JSON, which xgettext cannot read. The base translates these fields at runtime with
Tr.tr(<manifest value>) (ExtensionCard, DashWidgets, the dashboard tabs, the VPN provider types), so
they must reach raw.pot like any literal. Usage: manifest-strings.py <out_dir> <extensions_dir>...
One file per manifest, at <out_dir>/<id>/manifest.json.js (that path is the location in the .pot).
"""
import json
import pathlib
import sys

TOP = ("name", "description", "offNote")
LISTS = {"widgets": ("title", "subtext", "offNote"), "dashboardTabs": ("text",), "statusIcons": ("title",)}


def strings(m: dict) -> list[str]:
    out = [m.get(k) for k in TOP]
    c = m.get("contributes") or {}
    for key, fields in LISTS.items():
        for item in c.get(key) or []:
            out += [item.get(f) for f in fields]
    out.append((c.get("vpnProviderType") or {}).get("name"))
    # Programs it needs / can use: shown by Things before installing
    req = m.get("requires") or {}
    for key in ("apps", "optional"):
        out += [x for x in req.get(key) or []]
    seen = []
    for s in out:
        if isinstance(s, str) and s and s not in seen:
            seen.append(s)
    return seen


def main() -> None:
    out_dir = pathlib.Path(sys.argv[1])
    for root in sys.argv[2:]:
        for mf in sorted(pathlib.Path(root).glob("*/manifest.json")):
            m = json.loads(mf.read_text())
            dst = out_dir / m["id"] / "manifest.json.js"
            dst.parent.mkdir(parents=True, exist_ok=True)
            dst.write_text("".join(f"Tr.tr({json.dumps(s, ensure_ascii=False)});\n" for s in strings(m)))


if __name__ == "__main__":
    main()
