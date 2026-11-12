#!/usr/bin/env python3
"""Hook Sylphrena into the user's Hyprland configuration (once, safely).

  setup-hyprland.py [--check] [--shell-dir DIR]

Adds to ~/.config/hypr/hyprland.lua a block between markers that
  - starts the shell with the session (unless the file already starts it),
  - sets QT_QPA_PLATFORMTHEME=qt6ct (unless the file sets it),
  - loads the files Sylphrena writes from Nexus (sylphrena-monitors, -input, -binds, -activity-rules, -animation), each
    through pcall because they do not exist until the shell has run once.
If there is no hyprland.lua yet it starts from Hyprland's own default (/usr/share/hypr/hyprland.lua). An existing
file keeps everything it has: the block goes at the end, a copy is left in hyprland.lua.sylphrena-backup (once), and
if the result does not pass `Hyprland --verify-config` (or luac) the original is put back. Running it again changes
nothing. Remove the block to disconnect. Prints {"status": "done"|"already"|"needed"|"failed", "changed": [...],
"notes": [...]}. --check changes nothing.
"""
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
BEGIN = "-- >>> sylphrena (added by Sylphrena: remove this block to disconnect it) >>>"
END = "-- <<< sylphrena <<<"
FILES = ["sylphrena-monitors", "sylphrena-input", "sylphrena-binds", "sylphrena-activity-rules", "sylphrena-animation"]
DEFAULT_CONFIG = Path("/usr/share/hypr/hyprland.lua")
MINIMAL = "-- Hyprland configuration (created by Sylphrena). See https://wiki.hypr.land/Configuring/\n"


def config_path() -> Path:
    return Path(os.environ.get("XDG_CONFIG_HOME") or Path.home() / ".config") / "hypr" / "hyprland.lua"


def outside(text: str) -> str:
    """The configuration without our own block."""
    return re.sub(re.escape(BEGIN) + r".*?" + re.escape(END) + r"\n?", "", text, flags=re.S)


def starts_shell(text: str) -> bool:
    return bool(re.search(r"start-shell-with-tray-watcher|sylph\s+shell|qs\s+-c\s+sylphrena", text))


def system_keyboard() -> tuple[str, str]:
    """The keyboard layout (and variant) of the system, as set when Arch was installed: localectl's X11 layout,
    or else the console keymap (es, de-latin1, uk… → es, de, gb). ("", "") if there is none."""
    test = os.environ.get("SYLPHRENA_TEST_KEYBOARD")
    if test is not None:
        layout, _, variant = test.partition(":")
        return layout, variant
    layout = variant = ""
    out = _run(["localectl", "status"])
    if out and out[0] == 0:
        for line in out[1].splitlines():
            key, _, value = line.strip().partition(":")
            if key == "X11 Layout":
                layout = value.strip().split(",")[0]
            elif key == "X11 Variant":
                variant = value.strip().split(",")[0]
    if not layout:
        try:
            keymap = next((l.split("=", 1)[1].strip().strip('"') for l in Path("/etc/vconsole.conf").read_text().splitlines()
                           if l.startswith("KEYMAP=")), "")
        except OSError:
            keymap = ""
        layout = {"uk": "gb"}.get(keymap.split("-")[0], keymap.split("-")[0])
    return layout, variant


def keyboard_line(rest: str) -> str | None:
    """Hyprland's own default is "us": use the system's layout unless the configuration chose one of its own."""
    layout, variant = system_keyboard()
    if not layout or layout == "us":
        return None
    configured = re.search(r'kb_layout\s*=\s*"([^"]*)"', rest)
    if configured and configured.group(1) not in ("", "us"):
        return None
    return f'hl.config({{ input = {{ kb_layout = "{layout}", kb_variant = "{variant}" }} }})'


def render(shell_dir: Path, rest: str) -> str:
    """The block, leaving out what the rest of the file already does."""
    lines = [BEGIN, "-- Sylphrena writes the files below from Nexus; they do not exist until the shell has run once (pcall)."]
    if "QT_QPA_PLATFORMTHEME" not in rest:
        lines.append('hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")')
    if not starts_shell(rest):
        watcher = shell_dir / "scripts" / "start-shell-with-tray-watcher.sh"
        cmd = str(watcher) if watcher.is_file() else "sylph shell -d"
        lines += ['hl.on("hyprland.start", function()', f'  hl.exec_cmd("{cmd}")', "end)"]
    if not re.search(r"disable_hyprland_logo\s*=\s*true", rest):
        # Hyprland's own wallpaper (logo, mascot, a random line) flashes until the shell draws its own: plain black
        lines += ["-- No Hyprland wallpaper while the shell starts (it draws its own)",
                  "hl.config({ misc = { disable_hyprland_logo = true, disable_splash_rendering = true, "
                  "force_default_wallpaper = 0, background_color = 0xff000000 } })"]
    kb = keyboard_line(rest)
    if kb:
        lines += ["-- The keyboard layout of the system (Hyprland's default is \"us\")", kb]
    wanted = [n for n in FILES if f'"{n}"' not in rest and f"'{n}'" not in rest]
    if wanted:
        names = ", ".join(f'"{n}"' for n in wanted)
        lines += [f"for _, name in ipairs({{ {names} }}) do", "  pcall(require, name)", "end"]
    if len(lines) == 2:
        return ""  # the file already does everything: no block at all
    lines.append(END)
    return "\n".join(lines) + "\n"


def _run(cmd: list[str]) -> tuple[int, str] | None:
    if not shutil.which(cmd[0]):
        return None
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
    except (OSError, subprocess.SubprocessError):
        return None
    out = re.sub(r"\x1b\[[0-9;]*m", "", r.stdout + r.stderr).strip()
    # Hyprland is chatty (DEBUG lines): keep what says something is wrong
    return r.returncode, "\n".join(l for l in out.splitlines() if "DEBUG" not in l and l.strip()) or out


def verify(path: Path) -> str:
    """"" if the configuration is fine (or cannot be checked), else what is wrong. Hyprland's own check says
    "config ok"; when it cannot run (no session, no runtime dir) luac still catches a Lua syntax error."""
    hypr = _run(["Hyprland", "--verify-config", "-c", str(path)])
    if hypr and "config ok" in hypr[1].lower():
        return ""
    lua = _run(["luac", "-p", str(path)])
    if lua:
        return lua[1] if lua[0] else ""
    # Neither could vouch for it: refuse only if Hyprland explicitly reported an error
    if hypr and hypr[0] != 0 and "error" in hypr[1].lower():
        return hypr[1]
    return ""


def main() -> int:
    check = "--check" in sys.argv
    shell_dir = HERE.parent
    if "--shell-dir" in sys.argv:
        shell_dir = Path(sys.argv[sys.argv.index("--shell-dir") + 1])
    path = config_path()
    existed = path.is_file()
    if existed:
        try:
            text = path.read_text()
        except OSError as e:
            print(json.dumps({"status": "failed", "changed": [], "notes": [str(e)]}))
            return 1
    else:
        text = DEFAULT_CONFIG.read_text() if DEFAULT_CONFIG.is_file() else MINIMAL
    rest = outside(text)
    block = render(shell_dir, rest)
    new = rest.rstrip("\n") + "\n\n" + block if block else rest
    notes = []
    if starts_shell(rest):
        notes.append("the configuration already starts the shell")
    if new == text:
        print(json.dumps({"status": "already", "changed": [], "notes": notes}))
        return 0
    if check:
        print(json.dumps({"status": "needed", "changed": [str(path)], "notes": notes}))
        return 0
    path.parent.mkdir(parents=True, exist_ok=True)
    backup = path.with_name(path.name + ".sylphrena-backup")
    if existed and not backup.exists():
        shutil.copy2(path, backup)
    tmp = path.with_name(path.name + ".sylphrena-tmp")
    tmp.write_text(new)
    problem = verify(tmp)
    if problem:
        tmp.unlink(missing_ok=True)
        print(json.dumps({"status": "failed", "changed": [], "notes": notes + [f"the result was not a valid configuration: {problem[:300]}"]}))
        return 1
    os.replace(tmp, path)
    changed = [str(path)] + ([str(backup)] if existed else [])
    print(json.dumps({"status": "done", "changed": changed, "notes": notes + ([] if existed else ["created from Hyprland's default configuration"])}))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
