#!/usr/bin/env python3
"""Show desktop: slide every window of a workspace off the bottom of the screen (they stay on the
workspace, so the bar keeps their icons); run again to slide them back.

    show-desktop.py toggle <workspace-id>

State lives in $XDG_RUNTIME_DIR/sylphrena/show-desktop.json so it survives a shell restart.
"""
import json
import os
import subprocess
import sys

STATE = os.path.join(os.environ.get("XDG_RUNTIME_DIR", "/tmp"), "sylphrena", "show-desktop.json")


def hypr(*args):
    return subprocess.run(["hyprctl", *args], capture_output=True, text=True, timeout=5, stdin=subprocess.DEVNULL).stdout


def clients():
    return json.loads(hypr("clients", "-j") or "[]")


def monitors():
    return {m["id"]: m for m in json.loads(hypr("monitors", "-j") or "[]")}


def win(addr):
    return f'window = "address:{addr}"'


def move(addr, x, y):
    hypr("dispatch", f"hl.dsp.window.move({{ x = {int(x)}, y = {int(y)}, {win(addr)} }})")


def set_float(addr, on):
    hypr("dispatch", f'hl.dsp.window.float({{ action = "{"enable" if on else "disable"}", {win(addr)} }})')


def load():
    try:
        with open(STATE) as f:
            return json.load(f)
    except (OSError, ValueError):
        return {}


def save(state):
    os.makedirs(os.path.dirname(STATE), exist_ok=True)
    tmp = STATE + ".tmp"
    with open(tmp, "w") as f:
        json.dump(state, f)
    os.replace(tmp, STATE)


def hide(ws, state):
    mons = monitors()
    saved = []
    wins = [c for c in clients() if c["workspace"]["id"] == ws and c["mapped"] and not c["hidden"]]
    for c in wins:
        saved.append({"address": c["address"], "floating": c["floating"], "at": c["at"]})
    # Restore right to left: each window re-tiled lands on the left of the previous one.
    saved.sort(key=lambda w: (-w["at"][0], -w["at"][1]))
    if not saved:
        return
    state[str(ws)] = saved
    save(state)
    for c in wins:
        m = mons.get(c["monitor"])
        bottom = (m["y"] + m["height"] / (m.get("scale") or 1)) if m else 2000
        if not c["floating"]:
            set_float(c["address"], True)
        move(c["address"], c["at"][0], bottom + 20)


def show(ws, state):
    saved = state.pop(str(ws), [])
    save(state)
    alive = {c["address"] for c in clients()}
    for w in saved:
        if w["address"] not in alive:
            continue
        move(w["address"], w["at"][0], w["at"][1])
        if not w["floating"]:
            set_float(w["address"], False)


def main():
    if len(sys.argv) != 3 or sys.argv[1] != "toggle":
        print(__doc__, file=sys.stderr)
        return 2
    ws = int(sys.argv[2])
    state = load()
    if str(ws) in state:
        show(ws, state)
    else:
        hide(ws, state)
    return 0


if __name__ == "__main__":
    sys.exit(main())
