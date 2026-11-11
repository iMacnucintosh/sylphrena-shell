#!/usr/bin/env python3
"""Manage Sylphrena extensions from a terminal: the fallback when Things is not there (and what
`sylph ext` will call). Things uses the same contract (see AGENTS.md, «Contrato con Things»).

  ext.py list
  ext.py install <zip>      unpack (checked), install its system pieces if it has them (asks for sudo
                            in this terminal), enable it
  ext.py remove <id>        the extension forgets its data in the shell, its system pieces go, then its files
  ext.py enable <id> | disable <id>
  ext.py rescan

The shell must be running for rescan / enable / disable and for the extension to forget its data
(`qs -c sylphrena ipc …`); without it the files are still installed or removed and the shell picks
them up when it starts.
"""
import json
import os
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
SHELL = HERE.parent
USER_DIR = Path(os.environ.get("XDG_DATA_HOME") or Path.home() / ".local/share") / "sylphrena" / "extensions"
BUILTIN = SHELL / "extensions"


def run(cmd: list[str], check: bool = True) -> subprocess.CompletedProcess:
    return subprocess.run(cmd, capture_output=True, text=True, check=check)


def ipc(*args: str) -> str | None:
    """Result of `qs -c sylphrena ipc call extensions …`, or None if the shell is not running."""
    try:
        r = run(["qs", "-c", "sylphrena", "ipc", "call", "extensions", *args], check=False)
    except FileNotFoundError:
        return None
    out = r.stdout.strip()
    # qs answers "Target not found" / "Function not found" with exit code 0 when the shell is too old
    return out if r.returncode == 0 and "not found" not in out.lower()[:40] else None


def installer(*args: str) -> dict:
    r = run([sys.executable, str(HERE / "install-extension.py"), *args], check=False)
    try:
        return json.loads(r.stdout)
    except ValueError:
        return {"ok": False, "error": (r.stderr or r.stdout).strip() or "installer failed"}


def system_script(ext_dir: Path, key: str) -> Path | None:
    try:
        manifest = json.loads((ext_dir / "manifest.json").read_text())
    except (OSError, ValueError):
        return None
    rel = (manifest.get("system") or {}).get(key)
    if not rel or ".." in rel or rel.startswith("/") or not rel.endswith(".sh"):
        return None
    path = ext_dir / rel
    return path if path.is_file() else None


def sudo_script(path: Path) -> bool:
    print(f"  running {path.relative_to(path.parents[1])} as root…")
    return subprocess.run(["sudo", "bash", str(path)]).returncode == 0


def cmd_list() -> int:
    raw = ipc("list")
    if raw:
        items = json.loads(raw)
    else:  # the shell is not running: read the folders
        r = run([sys.executable, str(HERE / "list-extensions.py"), str(BUILTIN), str(USER_DIR)])
        items = [{"id": d["manifest"]["id"], "version": d["manifest"].get("version", ""), "local": not d.get("source"), "enabled": None, "error": ""} for d in json.loads(r.stdout)]
    for i in items:
        origin = "local" if i["local"] else "hub"
        state = "" if i["enabled"] is None else ("on" if i["enabled"] else "off")
        print(f"{i['id']:<22} {i['version']:<8} {origin:<6} {state:<4} {i.get('error') or ''}".rstrip())
    return 0


def cmd_install(zip_path: str) -> int:
    info = installer("inspect", zip_path, str(BUILTIN))
    if not info.get("ok"):
        print(f"error: {info.get('error')}", file=sys.stderr)
        return 1
    print(f"{info['name']} {info['version']}: {info.get('description', '')}")
    result = installer("install", zip_path, str(USER_DIR), str(BUILTIN))
    if not result.get("ok"):
        print(f"error: {result.get('error')}", file=sys.stderr)
        return 1
    ext_dir = USER_DIR / result["id"]
    script = system_script(ext_dir, "install")
    if script:
        print("It needs administrator rights.")
        if not sudo_script(script):
            print("The system part failed: run the same command again to retry.", file=sys.stderr)
            return 1
    running = ipc("rescan") is not None
    enabled = running and ipc("enable", result["id"]) == "ok"
    print("installed" + (" and enabled" if enabled else "") + ("" if running else " (the shell is not running: it will find it when it starts)"))
    return 0


def cmd_remove(ext_id: str) -> int:
    ext_dir = USER_DIR / ext_id
    if not (ext_dir / "manifest.json").is_file():
        print(f"error: '{ext_id}' is not installed in {USER_DIR}", file=sys.stderr)
        return 1
    ipc("prepareRemoval", ext_id)
    script = system_script(ext_dir, "uninstall")
    if script and not sudo_script(script):
        print("error: its system part could not be removed; nothing else was touched", file=sys.stderr)
        return 1
    ipc("disable", ext_id)
    result = installer("remove", ext_id, str(USER_DIR))
    if not result.get("ok"):
        print(f"error: {result.get('error')}", file=sys.stderr)
        return 1
    ipc("rescan")
    print("removed")
    return 0


def main() -> int:
    a = sys.argv[1:]
    if a[:1] == ["list"] and len(a) == 1:
        return cmd_list()
    if a[:1] == ["install"] and len(a) == 2:
        return cmd_install(a[1])
    if a[:1] == ["remove"] and len(a) == 2:
        return cmd_remove(a[1])
    if a[:1] in (["enable"], ["disable"]) and len(a) == 2:
        answer = ipc(a[0], a[1])
        print(answer if answer is not None else "the shell is not running (or is too old for this command)")
        return 0 if answer == "ok" else 1
    if a == ["rescan"]:
        return 0 if ipc("rescan") is not None else 1
    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main())
