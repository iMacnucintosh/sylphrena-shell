#!/usr/bin/env python3
"""Install or remove an extension in the user's extension folder (Nexus → Complements).

  install-extension.py install <zip> <user_dir> <builtin_dir>
  install-extension.py remove <id> <user_dir>

install: the zip holds one extension, its manifest.json either at the root or inside a single top
folder. It is checked before anything is written: no absolute paths, no "..", no symlinks or other
special files, at most 2000 files and 50 MiB unpacked, a manifest with a valid id ([a-z0-9-]+) that
is not one shipped with the shell. It is unpacked to a temporary folder next to the destination and
then swapped in, so an update replaces the old version in one step (its config and state, which
live elsewhere, are kept). Files keep their executable bit; nothing else from the zip's modes.

Prints one JSON object: {"ok": true, "id", "name", "version", "updated"} or {"ok": false, "error"}.
"""
import json
import os
import re
import shutil
import stat
import sys
import tempfile
import zipfile
from pathlib import Path, PurePosixPath

MAX_FILES = 2000
MAX_BYTES = 50 * 1024 * 1024
ID_RE = re.compile(r"[a-z0-9-]+")


class Bad(Exception):
    pass


def fail(msg: str) -> None:
    print(json.dumps({"ok": False, "error": msg}))
    sys.exit(1)


def members(zf: zipfile.ZipFile) -> list[tuple[zipfile.ZipInfo, PurePosixPath]]:
    infos = zf.infolist()
    if len(infos) > MAX_FILES:
        raise Bad("too many files in the zip")
    total = 0
    out = []
    for info in infos:
        name = info.filename
        path = PurePosixPath(name)
        if name.startswith("/") or "\\" in name or ".." in path.parts or re.match(r"^[A-Za-z]:", name):
            raise Bad(f"unsafe path in the zip: {name}")
        mode = info.external_attr >> 16
        if mode and not (stat.S_ISREG(mode) or stat.S_ISDIR(mode)):
            raise Bad(f"links and special files are not allowed: {name}")
        total += info.file_size
        if total > MAX_BYTES:
            raise Bad("the zip is too big once unpacked")
        out.append((info, path))
    return out


def find_root(paths: list[PurePosixPath]) -> PurePosixPath:
    files = [p for p in paths if str(p) and not str(p).endswith("/")]
    if PurePosixPath("manifest.json") in files:
        return PurePosixPath("")
    tops = {p.parts[0] for p in files if len(p.parts) > 1}
    if len(tops) == 1:
        top = PurePosixPath(next(iter(tops)))
        if top / "manifest.json" in files:
            return top
    raise Bad("no manifest.json at the root of the zip or of its only folder")


def install(zip_path: str, user_dir: str, builtin_dir: str) -> dict:
    try:
        zf = zipfile.ZipFile(zip_path)
    except (OSError, zipfile.BadZipFile) as e:
        raise Bad(f"not a valid zip: {e}")
    with zf:
        items = members(zf)
        root = find_root([p for _, p in items])
        try:
            manifest = json.loads(zf.read(str(root / "manifest.json")))
        except (KeyError, ValueError) as e:
            raise Bad(f"invalid manifest.json: {e}")
        if not isinstance(manifest, dict):
            raise Bad("invalid manifest.json")
        ext_id = manifest.get("id")
        if not isinstance(ext_id, str) or not ID_RE.fullmatch(ext_id):
            raise Bad("the manifest id must match [a-z0-9-]+")
        if (Path(builtin_dir) / ext_id / "manifest.json").exists():
            raise Bad(f"'{ext_id}' is an extension shipped with the shell")

        base = Path(user_dir)
        base.mkdir(parents=True, exist_ok=True)
        dest = base / ext_id
        tmp = Path(tempfile.mkdtemp(prefix=f".{ext_id}.", dir=base))
        try:
            for info, path in items:
                rel = path.relative_to(root) if root.parts else path
                if not rel.parts or (root.parts and path == root):
                    continue
                target = tmp.joinpath(*rel.parts)
                if info.is_dir():
                    target.mkdir(parents=True, exist_ok=True)
                    continue
                target.parent.mkdir(parents=True, exist_ok=True)
                with zf.open(info) as src, open(target, "wb") as dst:
                    shutil.copyfileobj(src, dst)
                mode = info.external_attr >> 16
                os.chmod(target, 0o755 if mode & 0o111 else 0o644)
            updated = dest.exists()
            old = None
            if updated:
                old = base / f".{ext_id}.old"
                if old.exists():
                    shutil.rmtree(old)
                dest.rename(old)
            tmp.rename(dest)
            if old is not None:
                shutil.rmtree(old, ignore_errors=True)
        except BaseException:
            shutil.rmtree(tmp, ignore_errors=True)
            raise
    return {"ok": True, "id": ext_id, "name": manifest.get("name", ext_id), "version": manifest.get("version", ""), "updated": updated}


def remove(ext_id: str, user_dir: str) -> dict:
    if not ID_RE.fullmatch(ext_id):
        raise Bad("invalid id")
    dest = Path(user_dir) / ext_id
    if not (dest / "manifest.json").is_file() or dest.is_symlink():
        raise Bad(f"'{ext_id}' is not installed in {user_dir}")
    shutil.rmtree(dest)
    return {"ok": True, "id": ext_id}


def main() -> None:
    try:
        if len(sys.argv) == 5 and sys.argv[1] == "install":
            result = install(sys.argv[2], sys.argv[3], sys.argv[4])
        elif len(sys.argv) == 4 and sys.argv[1] == "remove":
            result = remove(sys.argv[2], sys.argv[3])
        else:
            fail("usage: install-extension.py install <zip> <user_dir> <builtin_dir> | remove <id> <user_dir>")
            return
    except Bad as e:
        fail(str(e))
        return
    except OSError as e:
        fail(str(e))
        return
    print(json.dumps(result))


if __name__ == "__main__":
    main()
