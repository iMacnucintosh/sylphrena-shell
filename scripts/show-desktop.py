#!/usr/bin/env python3
"""Show desktop: slide every window of a workspace off the screen (left half to the left, right half to
the right; they stay on the workspace, so the bar keeps their icons); run again to slide them back.

    show-desktop.py toggle <workspace-id>
    show-desktop.py status

Both print a JSON list with the workspaces whose windows are currently hidden.

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
        scale = (m.get("scale") or 1) if m else 1
        left = m["x"] if m else 0
        width = m["width"] / scale if m else 2560
        centre = c["at"][0] + c["size"][0] / 2
        # Left half slides out to the left, right half to the right.
        x = left - c["size"][0] - 20 if centre < left + width / 2 else left + width + 20
        if not c["floating"]:
            set_float(c["address"], True)
        move(c["address"], x, c["at"][1])


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


def prune(state):
    """Forget workspaces whose hidden windows are all gone (closed meanwhile)."""
    alive = {c["address"] for c in clients()}
    for ws in list(state):
        if not any(w["address"] in alive for w in state[ws]):
            del state[ws]
    save(state)


def main():
    args = sys.argv[1:]
    if not (args == ["status"] or (len(args) == 2 and args[0] == "toggle")):
        print(__doc__, file=sys.stderr)
        return 2
    state = load()
    if args[0] == "toggle":
        ws = int(args[1])
        if str(ws) in state:
            show(ws, state)
        else:
            hide(ws, state)
        state = load()
    prune(state)
    print(json.dumps(sorted(int(k) for k in state)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
