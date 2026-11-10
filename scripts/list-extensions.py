#!/usr/bin/env python3
"""List extension manifests found in the given directories, as one JSON array on stdout.

Each entry: {"dir": <absolute folder>, "manifest": <parsed manifest.json>}. Folders without a
readable manifest (or whose id does not match [a-z0-9-]+) are skipped. Later directories do not
override earlier ones: the first folder that claims an id wins.
"""
import json
import re
import sys
from pathlib import Path

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
        out.append({"dir": str(folder.resolve()), "manifest": manifest})
print(json.dumps(out))
