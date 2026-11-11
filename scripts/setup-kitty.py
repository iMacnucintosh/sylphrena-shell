#!/usr/bin/env python3
"""Connect kitty to Sylphrena so it follows the scheme live. Idempotent; run by the shell at startup
(services/KittySetup.qml) and usable by hand.

  setup-kitty.py            do it (once: after a first run it only reports, unless --force)
  setup-kitty.py --check    only say what is missing, change nothing
  setup-kitty.py --force    do it again even if it was done before (e.g. after removing the block)

What it does, and nothing else:
  1. the colour template ~/.config/sylphrena/templates/kitty.conf, copied from assets/kitty/ if missing
     (an existing one is never touched);
  2. in ~/.config/kitty/kitty.conf, a marked block with what is missing of: the include of the generated
     theme, `allow_remote_control yes` and `listen_on`. A backup of the file is made first (kitty.conf.sylphrena-backup,
     once). If the user already has any of them (or set allow_remote_control to something else) it is left as it is.
Prints one JSON line: {"status", "changed": [...], "notes": [...]}; status is one of
  skipped (kitty is not installed) | done | already (nothing to do) | needed (--check: something is missing) | seen (done before)
"""
import json
import os
import re
import shutil
import sys
from pathlib import Path

HOME = Path(os.environ.get("HOME") or Path.home())
SHELL = Path(__file__).resolve().parent.parent
TEMPLATE_SRC = SHELL / "assets" / "kitty" / "kitty.conf"
TEMPLATE_DST = HOME / ".config" / "sylphrena" / "templates" / "kitty.conf"
KITTY_CONF = HOME / ".config" / "kitty" / "kitty.conf"
STATE = Path(os.environ.get("XDG_STATE_HOME") or HOME / ".local" / "state") / "sylphrena" / "kitty-setup.json"

INCLUDE = "include ~/.local/state/sylphrena/theme/kitty.conf"
REMOTE = "allow_remote_control yes"
LISTEN = "listen_on unix:${XDG_RUNTIME_DIR}/kitty-{kitty_pid}.sock"
BEGIN = "# >>> sylphrena: kitty follows the shell's colours live (remove this block to disconnect it) >>>"
END = "# <<< sylphrena <<<"

REMOTE_OK = {"yes", "y", "true", "socket", "socket-only"}
REMOTE_OFF = {"no", "n", "false"}


def active_lines(text: str) -> list[str]:
    return [ln.strip() for ln in text.splitlines() if ln.strip() and not ln.lstrip().startswith("#")]


def analyse(text: str) -> tuple[list[str], list[str]]:
    """(lines the block must add, notes about what is left alone)."""
    missing, notes = [], []
    lines = active_lines(text)
    if not any(re.match(r"^include\s+.*sylphrena/theme/kitty\.conf\s*$", ln) for ln in lines):
        missing.append(INCLUDE)
    remote = [re.split(r"\s+", ln, maxsplit=1)[1].strip().lower() for ln in lines if re.match(r"^allow_remote_control\s+\S+", ln)]
    if not remote:
        missing.append(REMOTE)
    elif remote[-1] in REMOTE_OFF:
        notes.append("allow_remote_control is off in your kitty.conf: colours cannot change live in open windows (left as it is)")
    elif remote[-1] not in REMOTE_OK:
        notes.append(f"allow_remote_control is '{remote[-1]}': left as it is")
    listen = [ln for ln in lines if re.match(r"^listen_on\s+\S+", ln)]
    if not listen:
        missing.append(LISTEN)
    elif not any("kitty-" in ln and ".sock" in ln for ln in listen):
        notes.append("listen_on in your kitty.conf is not kitty-*.sock under XDG_RUNTIME_DIR: live colours may not reach open windows (left as it is)")
    return missing, notes


def write_atomic(path: Path, text: str) -> None:
    target = path.resolve() if path.is_symlink() else path  # dotfile managers: write through the link
    target.parent.mkdir(parents=True, exist_ok=True)
    mode = target.stat().st_mode & 0o777 if target.exists() else 0o644
    tmp = target.with_name(target.name + ".sylphrena-tmp")
    tmp.write_text(text)
    os.chmod(tmp, mode)
    os.replace(tmp, target)


def out(status: str, changed: list[str], notes: list[str]) -> int:
    print(json.dumps({"status": status, "changed": changed, "notes": notes}, ensure_ascii=False))
    return 0


def main() -> int:
    check, force = "--check" in sys.argv, "--force" in sys.argv
    if not shutil.which("kitty"):
        return out("skipped", [], ["kitty is not installed"])
    if STATE.exists() and not (check or force):
        return out("seen", [], [])

    changed, notes = [], []
    if not TEMPLATE_DST.exists():
        if check:
            changed.append("template")
        elif TEMPLATE_SRC.is_file():
            TEMPLATE_DST.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(TEMPLATE_SRC, TEMPLATE_DST)
            changed.append("template")

    text = KITTY_CONF.read_text() if KITTY_CONF.exists() else ""
    missing, found = analyse(text)
    notes += found
    if missing:
        changed.append("kitty.conf")
        if not check:
            backup = KITTY_CONF.with_name("kitty.conf.sylphrena-backup")
            if KITTY_CONF.exists() and not backup.exists():
                shutil.copyfile(KITTY_CONF, backup)
                notes.append(f"backup of your kitty.conf: {backup.name}")
            # Replace an earlier block of ours (re-run with --force) instead of stacking another one
            text = re.sub(rf"\n?{re.escape(BEGIN)}.*?{re.escape(END)}\n?", "\n", text, flags=re.S)
            block = "\n".join([BEGIN, *missing, END]) + "\n"
            write_atomic(KITTY_CONF, (text.rstrip("\n") + "\n\n" if text.strip() else "") + block)

    if check:
        return out("needed" if changed else "already", changed, notes)
    STATE.parent.mkdir(parents=True, exist_ok=True)
    STATE.write_text(json.dumps({"done": True, "changed": changed}) + "\n")
    return out("done" if changed else "already", changed, notes)


if __name__ == "__main__":
    sys.exit(main())
