#!/usr/bin/env python3
"""Manage Sylphrena extensions: from a terminal, and what Things calls (`sylph ext …` runs it).
The shell owns the extension contract, so this is the one implementation of installing and removing
(see AGENTS.md, «Contrato con Things»).

  ext.py list [--json]       the extensions found (JSON: id, name, version, local, source, enabled, error)
  ext.py info                {"running", "shellVersion", "apiVersion"} of the shell that is running
  ext.py inspect <zip>       what a local zip would install, without installing: JSON {ok, id, name, version,
                             description, system, requires, incompatible} (what Things shows before asking)
  ext.py install <zip>       a local zip: unpack (checked), install its system pieces if it has them
                             (sudo), enable it. It stays "local" (no hub receipt)
  ext.py install-hub <id> --url <zip url> --sha256 <hex> --version <v>
  ext.py update-hub <id>     install the version the hub's catalog has now (what the shell's updates run)
  ext.py <id>                the commands an extension offers
  ext.py <id> <command> [args]   run one of them (sylph ext hydration show, sylph ext hydration add 250)
                             what Things runs: download from the hub, check the sha256 and the
                             compatibility with this shell, install, write the receipt, enable it
  ext.py remove <id> [--purge]  the extension forgets its data in the shell, its system pieces go, then its files.
                             --purge also deletes its settings and data (the paths its manifest `data` lists)
  ext.py enable <id> | disable <id>
  ext.py rescan

Root: the system pieces run with `sudo`; with SUDO_ASKPASS set (Things sets it) as `sudo -A`, so the
password is asked by the caller's own dialog and never reaches this script.

The shell must be running for rescan / enable / disable and for the extension to forget its data
(`qs -c sylphrena ipc …`); without it the files are still installed or removed and the shell picks
them up when it starts. Progress goes to stdout as «==> …» lines.
"""
import datetime
import shutil
import hashlib
import json
import os
import re
import subprocess
import sys
import tempfile
import urllib.error
import urllib.request
from pathlib import Path

HERE = Path(__file__).resolve().parent
SHELL = HERE.parent
USER_DIR = Path(os.environ.get("XDG_DATA_HOME") or Path.home() / ".local/share") / "sylphrena" / "extensions"
BUILTIN = SHELL / "extensions"

# Zips of the hub live in the releases of its repository. Anything else is refused (defence in depth:
# the URL comes from a catalog). Tests may point SYLPHRENA_HUB_TEST_PREFIX at a local folder (file://…).
HUB_RELEASES = "https://github.com/iMacnucintosh/sylphrena-hub/releases/download/"
HUB_INDEX = "https://raw.githubusercontent.com/iMacnucintosh/sylphrena-hub/main/index.json"
HUB_INDEX_API = "https://api.github.com/repos/iMacnucintosh/sylphrena-hub/contents/index.json?ref=main"
MAX_ZIP = 50 * 1024 * 1024
ID_RE = re.compile(r"^[a-z0-9-]+$")
SHA_RE = re.compile(r"^[0-9a-f]{64}$")


def step(msg: str) -> None:
    print(f"==> {msg}", flush=True)


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


def sudo() -> list[str]:
    return ["sudo", "-A"] if os.environ.get("SUDO_ASKPASS") else ["sudo"]


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
    step(f"running {path.relative_to(path.parents[1])} as root")
    return subprocess.run([*sudo(), "bash", str(path)]).returncode == 0


# ── Compatibility (mirrors Extensions.qml: apiVersion, requires.sylphrena) ──────────────────────────

def _parts(v: str) -> list[int] | None:
    m = re.match(r"^v?(\d+)(?:\.(\d+))?(?:\.(\d+))?", str(v))
    return [int(m.group(1)), int(m.group(2) or 0), int(m.group(3) or 0)] if m else None


def satisfies(version: str, spec: str) -> bool:
    """Space separated comparators, all must hold. Empty spec or unknown version always passes;
    a spec that does not parse never does."""
    if not spec or not version:
        return True
    have = _parts(version)
    for part in str(spec).split():
        m = re.match(r"^(>=|<=|>|<|=)?(\d+(?:\.\d+){0,2})$", part)
        if not m or not have:
            return False
        want = _parts(m.group(2))
        c = (have > want) - (have < want)
        ok = {">=": c >= 0, "<=": c <= 0, ">": c > 0, "<": c < 0, "=": c == 0}[m.group(1) or "="]
        if not ok:
            return False
    return True


def shell_info() -> dict:
    raw = ipc("status")
    if raw:
        try:
            d = json.loads(raw)
            return {"running": True, "shellVersion": d.get("shellVersion", ""), "apiVersion": d.get("apiVersion", 1)}
        except ValueError:
            pass
    return {"running": False, "shellVersion": "", "apiVersion": 1}


def incompatibility(info: dict, shell: dict) -> str:
    """Why an extension (inspect output) cannot run on this shell, or "" (also "" if the shell is not running)."""
    if not shell["running"]:
        return ""
    if int(info.get("apiVersion") or 1) > int(shell["apiVersion"] or 1):
        return f"needs a newer Sylphrena (extension API {info['apiVersion']})"
    spec = info.get("requires") or ""
    if not satisfies(shell["shellVersion"], spec):
        return f"needs Sylphrena {spec} (this is {shell['shellVersion']})"
    return ""


# ── Commands ─────────────────────────────────────────────────────────────────────────────────────

def cmd_list(as_json: bool) -> int:
    raw = ipc("list")
    if raw:
        items = json.loads(raw)
    else:  # the shell is not running: read the folders
        r = run([sys.executable, str(HERE / "list-extensions.py"), str(BUILTIN), str(USER_DIR)])
        items = [{"id": d["manifest"]["id"], "name": d["manifest"].get("name", d["manifest"]["id"]), "version": d["manifest"].get("version", ""),
                  "kind": d["manifest"].get("type", ""), "local": not d.get("source"), "source": d.get("source"), "enabled": None, "error": ""}
                 for d in json.loads(r.stdout)]
    if as_json:
        print(json.dumps(items, ensure_ascii=False))
        return 0
    for i in items:
        origin = "local" if i["local"] else "hub"
        state = "" if i["enabled"] is None else ("on" if i["enabled"] else "off")
        print(f"{i['id']:<22} {i['version']:<8} {origin:<6} {state:<4} {i.get('error') or ''}".rstrip())
    return 0


def cmd_info() -> int:
    print(json.dumps(shell_info()))
    return 0


def was_enabled(ext_id: str) -> bool:
    """Is it enabled (so loaded) right now? Then its new files need a reload of the shell to be used."""
    raw = ipc("list")
    try:
        return any(i["id"] == ext_id and i.get("enabled") for i in json.loads(raw)) if raw else False
    except ValueError:
        return False


def finish_install(ext_id: str, receipt: dict | None, reload: bool = False) -> int:
    """After unpacking: receipt, system pieces, rescan, enable (and reload the shell if it was an update of a loaded one)."""
    ext_dir = USER_DIR / ext_id
    if receipt is not None:
        (ext_dir / ".source.json").write_text(json.dumps(receipt, indent=2) + "\n")
    script = system_script(ext_dir, "install")
    if script:
        step("It needs administrator rights")
        if not sudo_script(script):
            print("error: the system part failed: run the same command again to retry", file=sys.stderr)
            return 1
    running = ipc("rescan") is not None
    # "pending": the shell has not listed it yet / is still checking its system pieces; it enables it as soon as it can
    enabled = running and ipc("enable", ext_id) in ("ok", "pending")
    if running and reload:
        step("reloading the shell to use the new code")
        ipc("reload")
    step("installed" + (" and enabled" if enabled else "") + ("" if running else " (the shell is not running: it will find it when it starts)"))
    return 0


def cmd_inspect(zip_path: str) -> int:
    info = installer("inspect", zip_path, str(BUILTIN))
    if info.get("ok"):
        info.pop("i18n", None)
        info["incompatible"] = incompatibility(info, shell_info())
    print(json.dumps(info))
    return 0 if info.get("ok") else 1


def cmd_install(zip_path: str) -> int:
    info = installer("inspect", zip_path, str(BUILTIN))
    if not info.get("ok"):
        print(f"error: {info.get('error')}", file=sys.stderr)
        return 1
    why = incompatibility(info, shell_info())
    if why:
        print(f"error: {info['name']} {info['version']} {why}", file=sys.stderr)
        return 1
    step(f"{info['name']} {info['version']}: {info.get('description', '')}")
    reload = was_enabled(info["id"])
    result = installer("install", zip_path, str(USER_DIR), str(BUILTIN))
    if not result.get("ok"):
        print(f"error: {result.get('error')}", file=sys.stderr)
        return 1
    return finish_install(result["id"], None, reload)


def download(url: str, dest: Path) -> str:
    """Fetch the zip to `dest`, capped, and return its sha256."""
    test_prefix = os.environ.get("SYLPHRENA_HUB_TEST_PREFIX", "")
    if not (url.startswith(HUB_RELEASES) or (test_prefix and url.startswith(test_prefix))):
        raise ValueError("the download is not from the Sylphrena Hub releases")
    h = hashlib.sha256()
    size = 0
    req = urllib.request.Request(url, headers={"User-Agent": "sylphrena-ext"})
    with urllib.request.urlopen(req, timeout=60) as r, open(dest, "wb") as f:
        while True:
            chunk = r.read(65536)
            if not chunk:
                break
            size += len(chunk)
            if size > MAX_ZIP:
                raise ValueError("the zip is too big")
            h.update(chunk)
            f.write(chunk)
    return h.hexdigest()


def cmd_install_hub(args: list[str]) -> int:
    if not args or not ID_RE.match(args[0]):
        print("usage: ext.py install-hub <id> --url <url> --sha256 <hex> --version <v>", file=sys.stderr)
        return 2
    ext_id = args[0]
    opts = dict(zip(args[1::2], args[2::2]))
    url, sha, version = opts.get("--url", ""), opts.get("--sha256", "").lower(), opts.get("--version", "")
    if not url or not SHA_RE.match(sha) or not version:
        print("error: --url, --sha256 (64 hex) and --version are required", file=sys.stderr)
        return 2
    with tempfile.TemporaryDirectory(prefix="sylphrena-hub-") as tmp:
        zip_path = Path(tmp) / f"{ext_id}.zip"
        step(f"Downloading {ext_id} {version}")
        try:
            got = download(url, zip_path)
        except (ValueError, OSError, urllib.error.URLError) as e:
            print(f"error: {e}", file=sys.stderr)
            return 1
        step("Checking the download")
        if got != sha:
            print("error: the sha256 of the download does not match the catalog; nothing was installed", file=sys.stderr)
            return 1
        info = installer("inspect", str(zip_path), str(BUILTIN))
        if not info.get("ok"):
            print(f"error: {info.get('error')}", file=sys.stderr)
            return 1
        if info["id"] != ext_id:
            print(f"error: the zip holds '{info['id']}', not '{ext_id}'", file=sys.stderr)
            return 1
        why = incompatibility(info, shell_info())
        if why:
            print(f"error: {info['name']} {info['version']} {why}", file=sys.stderr)
            return 1
        step("Installing")
        reload = was_enabled(ext_id)
        result = installer("install", str(zip_path), str(USER_DIR), str(BUILTIN))
        if not result.get("ok"):
            print(f"error: {result.get('error')}", file=sys.stderr)
            return 1
    receipt = {"source": "hub", "version": version, "sha256": sha, "installedAt": datetime.datetime.now(datetime.timezone.utc).isoformat(timespec="seconds")}
    return finish_install(ext_id, receipt, reload)


# What the shell itself keeps in those two folders: an extension's `data` can never name them (removing
# an extension with --purge must not take the user's configuration, other extensions' settings or the theme)
SHELL_OWNED = {
    "config": {"shell.json", "shell-tokens.json", "keybinds.json", "cli.json", "templates", "extensions", "monitors",
               "scripts"},
    "state": {"scheme.json", "state.json", "wallpaper", "theme", "welcome.json", "defaults.json", "kitty-setup.json",
              "sequences.txt", "notifs.json", "apps.sqlite", "clipboard", "record", "lyrics", "timers.json",
              "light-apps.json", "force-apps-light", "session-startup.log"},
}


def data_paths(ext_id: str, manifest: dict) -> list[Path]:
    """Settings and data an extension leaves behind: its config file, plus what its manifest `data` lists
    (strings "config:<path>" or "state:<path>", relative to ~/.config/sylphrena or ~/.local/state/sylphrena).
    Anything that would leave those two folders, or that the shell itself owns there, is ignored."""
    roots = {
        "config": Path(os.environ.get("XDG_CONFIG_HOME") or Path.home() / ".config") / "sylphrena",
        "state": Path(os.environ.get("XDG_STATE_HOME") or Path.home() / ".local/state") / "sylphrena",
    }
    out = [roots["config"] / "extensions" / f"{ext_id}.json"]
    for entry in manifest.get("data") or []:
        where, _, rel = str(entry).partition(":")
        parts = Path(rel).parts
        if where not in roots or not rel or rel.startswith("/") or ".." in parts or parts[0] in SHELL_OWNED[where]:
            continue
        out.append(roots[where] / rel)
    return out


def purge(ext_id: str, manifest: dict) -> None:
    step("Deleting its settings and data")
    for path in data_paths(ext_id, manifest):
        try:
            if path.is_dir() and not path.is_symlink():
                shutil.rmtree(path)
            elif path.exists() or path.is_symlink():
                path.unlink()
        except OSError as e:
            print(f"warning: {path}: {e}", file=sys.stderr)


def cmd_update_hub(ext_id: str) -> int:
    """The catalog's current version of an extension, installed exactly as Things does (install-hub)."""
    if not ID_RE.match(ext_id):
        print("usage: ext.py update-hub <id>", file=sys.stderr)
        return 2
    try:
        # The API, not raw.githubusercontent.com: right after a version is published, the raw file's cache may still
        # give the old catalog for minutes (and install the old version again). This runs rarely: the API's limit is fine.
        url = os.environ.get("SYLPHRENA_HUB_INDEX") or HUB_INDEX_API
        req = urllib.request.Request(url, headers={"Accept": "application/vnd.github.raw", "User-Agent": "sylphrena-ext"})
        with urllib.request.urlopen(req, timeout=15) as r:
            entry = next((i for i in json.load(r).get("items", []) if i.get("id") == ext_id), None)
    except (OSError, ValueError, urllib.error.URLError) as e:
        print(f"error: could not read the hub's catalog: {e}", file=sys.stderr)
        return 1
    if not entry:
        print(f"error: {ext_id} is not in the hub's catalog", file=sys.stderr)
        return 1
    return cmd_install_hub([ext_id, "--url", entry["zip"], "--sha256", entry["sha256"], "--version", entry["version"]])


def cmd_commands(ext_id: str) -> int:
    answer = ipc("commands", ext_id)
    if answer is None:
        print("the shell is not running (or is too old for this command)", file=sys.stderr)
        return 1
    if answer.startswith("error:"):
        print(answer, file=sys.stderr)
        return 1
    commands = json.loads(answer)
    if not commands:
        print(f"{ext_id} has no commands")
        return 0
    width = max(len(c.get("name", "")) for c in commands)
    for c in commands:
        print(f"{c.get('name', ''):<{width}}  {c.get('description', '')}".rstrip())
    return 0


def cmd_run(ext_id: str, command: str, args: list[str]) -> int:
    # Prefixed: a command named like one of qs' own words (show, call…) would be taken by qs, and an empty or
    # bracket-only argument is dropped
    answer = ipc("run", ext_id, "c:" + command, "a:" + json.dumps(args))
    if answer is None:
        print("the shell is not running (or is too old for this command)", file=sys.stderr)
        return 1
    if answer.startswith("error:"):
        print(answer, file=sys.stderr)
        return 1
    if answer != "ok":
        print(answer)
    return 0


def cmd_remove(ext_id: str, do_purge: bool = False) -> int:
    if not ID_RE.match(ext_id):
        print(f"error: '{ext_id}' is not an extension id", file=sys.stderr)
        return 2
    ext_dir = USER_DIR / ext_id
    if not (ext_dir / "manifest.json").is_file():
        print(f"error: '{ext_id}' is not installed in {USER_DIR}", file=sys.stderr)
        return 1
    try:
        manifest = json.loads((ext_dir / "manifest.json").read_text())
    except ValueError:
        manifest = {}
    step("Removing")
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
    if do_purge:
        purge(ext_id, manifest)
    step("removed")
    return 0


def main() -> int:
    a = sys.argv[1:]
    if a[:1] == ["list"] and a[1:] in ([], ["--json"]):
        return cmd_list(a[1:] == ["--json"])
    if a == ["info"]:
        return cmd_info()
    if a[:1] == ["inspect"] and len(a) == 2:
        return cmd_inspect(a[1])
    if a[:1] == ["install"] and len(a) == 2:
        return cmd_install(a[1])
    if a[:1] == ["install-hub"]:
        return cmd_install_hub(a[1:])
    if a[:1] == ["update-hub"] and len(a) == 2:
        return cmd_update_hub(a[1])
    if a[:1] == ["remove"] and len(a) in (2, 3) and (len(a) == 2 or a[2] == "--purge"):
        return cmd_remove(a[1], len(a) == 3)
    if a[:1] in (["enable"], ["disable"]) and len(a) == 2 and ID_RE.match(a[1]):
        answer = ipc(a[0], a[1])
        print(answer if answer is not None else "the shell is not running (or is too old for this command)")
        return 0 if answer == "ok" else 1
    if a == ["rescan"]:
        return 0 if ipc("rescan") is not None else 1
    # Anything else that is an id: the extension's own commands
    if a and ID_RE.match(a[0]):
        return cmd_commands(a[0]) if len(a) == 1 else cmd_run(a[0], a[1], a[2:])
    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main())
