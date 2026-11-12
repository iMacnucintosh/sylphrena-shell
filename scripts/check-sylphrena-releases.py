#!/usr/bin/env python3
"""Is there a newer release of Sylphrena? Prints JSON for the shell (services/SylphrenaUpdates.qml):

    {"updates": [{"pkg", "name", "repo", "installed", "latest", "notes", "url"}], "checked": <unix time>}

Only the packages that are installed and behind their latest release are listed; a machine that runs the shell from a
clone (no packages) gets an empty list. The tag comes from the web page of the release (not limited like the API, which
allows 60 requests an hour without an account); the API is only asked for the notes of a tag not seen before.
"""
from __future__ import annotations

import json
import os
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from installer import PACKAGES, behind, installed_version, latest_release as latest_tag  # noqa: E402

NAMES = {"sylphrena-shell-git": "Sylphrena", "sylphrena-cli-git": "sylphrena-cli", "seeker-git": "Seeker", "things-git": "Things"}
CACHE = Path(os.environ.get("XDG_CACHE_HOME") or Path.home() / ".cache") / "sylphrena" / "releases.json"


def load_cache() -> dict:
    try:
        return json.loads(CACHE.read_text())
    except (OSError, ValueError):
        return {}


def save_cache(cache: dict) -> None:
    CACHE.parent.mkdir(parents=True, exist_ok=True)
    tmp = CACHE.with_suffix(".tmp")
    tmp.write_text(json.dumps(cache))
    os.replace(tmp, CACHE)


def latest(repo: str, cache: dict) -> dict | None:
    """{"tag", "notes", "url"} of the latest release. The notes come from the API, asked only when the tag is new."""
    known = cache.get(repo) or {}
    tag = latest_tag(repo)
    if not tag:
        return known or None
    if tag != known.get("tag"):
        known = {"tag": tag, "notes": "", "url": f"https://github.com/iMacnucintosh/{repo}/releases/tag/{tag}"}
        req = urllib.request.Request(f"https://api.github.com/repos/iMacnucintosh/{repo}/releases/tags/{tag}",
                                     headers={"Accept": "application/vnd.github+json", "User-Agent": "sylphrena-updates"})
        try:
            with urllib.request.urlopen(req, timeout=8) as r:
                known["notes"] = json.load(r).get("body") or ""
        except (OSError, ValueError, urllib.error.URLError):
            pass                                # without notes this time; the tag is what matters
        cache[repo] = known
    return known


def main() -> int:
    cache = load_cache()
    updates = []
    # Tests only: {"sylphrena-shell-git": "0.3.0.r0.g0-1"} pretends those versions are installed
    pretend = json.loads(os.environ.get("SYLPHRENA_TEST_INSTALLED") or "{}")
    for pkg, repo in PACKAGES:
        have = pretend.get(pkg) if pretend else installed_version(pkg)
        if not have:
            continue
        rel = latest(repo, cache)
        if rel and behind(have, rel["tag"]):
            updates.append({"pkg": pkg, "name": NAMES.get(pkg, pkg), "repo": repo,
                            "installed": have.split(".r")[0].split("-")[0], "latest": rel["tag"].lstrip("v"),
                            "notes": rel["notes"], "url": rel["url"]})
    save_cache(cache)
    print(json.dumps({"updates": updates, "checked": int(time.time())}))
    return 0


if __name__ == "__main__":
    sys.exit(main())
