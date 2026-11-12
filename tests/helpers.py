"""Shared bits of the tests: load a script of scripts/ as a module, build zips and sandboxed HOMEs."""
import importlib.util
import json
import os
import subprocess
import sys
import tempfile
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SCRIPTS = ROOT / "scripts"


def load(name: str):
    """scripts/<name>.py as a module (the file names have dashes)."""
    spec = importlib.util.spec_from_file_location(name.replace("-", "_"), SCRIPTS / f"{name}.py")
    mod = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = mod  # dataclasses and friends look the module up by name
    spec.loader.exec_module(mod)
    return mod


def make_zip(path: Path, files: dict[str, str | bytes], links: dict[str, str] | None = None) -> Path:
    """A zip with the given files; `links` adds symlinks (name -> target)."""
    with zipfile.ZipFile(path, "w") as z:
        for name, data in files.items():
            z.writestr(name, data)
        for name, target in (links or {}).items():
            info = zipfile.ZipInfo(name)
            info.external_attr = (0o120777) << 16
            z.writestr(info, target)
    return path


def manifest(**over) -> str:
    m = {"id": "demo", "type": "widget", "name": "Demo", "icon": "extension", "version": "0.1.0", "apiVersion": 1}
    m.update(over)
    return json.dumps(m)


def sandbox_env(home: Path) -> dict:
    """An environment whose HOME, config, state and data live in `home` (nothing of the real ones is seen)."""
    env = {k: v for k, v in os.environ.items() if not k.startswith(("XDG_", "SYLPHRENA"))}
    env.update(HOME=str(home), XDG_CONFIG_HOME=str(home / ".config"), XDG_STATE_HOME=str(home / ".local/state"),
               XDG_DATA_HOME=str(home / ".local/share"), SYLPHRENA_TEST_KEYBOARD="")   # no system layout unless a test sets one
    return env


def run_script(name: str, args: list[str], home: Path, env: dict | None = None) -> subprocess.CompletedProcess:
    return subprocess.run([sys.executable, str(SCRIPTS / name), *args], env={**sandbox_env(home), **(env or {})},
                          capture_output=True, text=True, check=False)


def tmpdir() -> tempfile.TemporaryDirectory:
    return tempfile.TemporaryDirectory(prefix="sylph-test-")
