#!/usr/bin/env python3
"""List extension manifests found in the given directories, as one JSON array on stdout.

Each entry: {"dir": <absolute folder>, "manifest": <parsed manifest.json>, "i18n": {<lang>: {...}}}
(`i18n` = the extension's own catalogs, i18n/<lang>.json: msgid or "context\u0004msgid" ->
translation; only string pairs are kept). Folders without a
readable manifest (or whose id does not match [a-z0-9-]+) are skipped. Later directories do not
override earlier ones: the first folder that claims an id wins.
"""
import json
import re
import sys
from pathlib import Path

MAX_CATALOG = 512 * 1024


def catalogs(folder: Path) -> dict:
    out = {}
    for f in sorted((folder / "i18n").glob("*.json")):
        if not re.fullmatch(r"[A-Za-z]{2,3}([_-][A-Za-z0-9]+)?", f.stem) or f.stat().st_size > MAX_CATALOG:
            continue
        try:
            data = json.loads(f.read_text())
        except (OSError, ValueError):
            continue
        if isinstance(data, dict):
            out[f.stem] = {k: v for k, v in data.items() if isinstance(k, str) and isinstance(v, str)}
    return out


seen, out = set(), []
for root in sys.argv[1:]:
    base = Path(root)
    if not base.is_dir():
        continue
    for folder in sorted(p for p in base.iterdir() if p.is_dir()):
        try:
            manifest = json.loads((folder / "manifest.json").read_text())
        except (OSError, ValueError):
            continue
        ext_id = manifest.get("id")
        if not isinstance(ext_id, str) or not re.fullmatch(r"[a-z0-9-]+", ext_id) or ext_id in seen:
            continue
        seen.add(ext_id)
        out.append({"dir": str(folder.resolve()), "manifest": manifest, "i18n": catalogs(folder)})
print(json.dumps(out))
