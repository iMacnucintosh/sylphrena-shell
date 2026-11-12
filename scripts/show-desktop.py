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
import time

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
        saved.append({"address": c["address"], "floating": c["floating"], "at": c["at"], "size": c["size"]})
    if not saved:
        return
    state[str(ws)] = saved
    save(state)
    # Float + restore the size + park all windows in one go: a window turned floating comes with another
    # size, which must not be seen. Only the final slide is animated.
    batch_cmds = ['eval hl.config({ animations = { enabled = false } })']
    slides = []
    for c in wins:
        m = mons.get(c["monitor"])
        scale = (m.get("scale") or 1) if m else 1
        left = m["x"] if m else 0
        width = m["width"] / scale if m else 2560
        centre = c["at"][0] + c["size"][0] / 2
        # Left half slides out to the left, right half to the right.
        x = left - c["size"][0] - 20 if centre < left + width / 2 else left + width + 20
        a = win(c["address"])
        if not c["floating"]:
            batch_cmds.append(f'dispatch hl.dsp.window.float({{ action = "enable", {a} }})')
        batch_cmds.append(f'dispatch hl.dsp.window.resize({{ x = {c["size"][0]}, y = {c["size"][1]}, exact = true, {a} }})')
        batch_cmds.append(f'dispatch hl.dsp.window.move({{ x = {c["at"][0]}, y = {c["at"][1]}, {a} }})')
        slides.append((a, x, c["at"][1]))
    anim = option("animations:enabled")
    batch_cmds.append(f"eval hl.config({{ animations = {{ enabled = {'false' if anim is False else 'true'} }} }})")
    for a, x, y in slides:
        batch_cmds.append(f"dispatch hl.dsp.window.move({{ x = {int(x)}, y = {int(y)}, {a} }})")
    batch(batch_cmds)


def cut(rects, vertical):
    """Split rects (dicts with at/size) in two groups separated by a straight line; None if impossible."""
    key = (lambda w: w["at"][0]) if vertical else (lambda w: w["at"][1])
    end = (lambda w: w["at"][0] + w["size"][0]) if vertical else (lambda w: w["at"][1] + w["size"][1])
    order = sorted(rects, key=key)
    for i in range(1, len(order)):
        first, rest = order[:i], order[i:]
        if max(end(w) for w in first) <= min(key(w) for w in rest):
            return first, rest
    return None


def plan(group, out, anchor=None):
    """Order tiled windows the way dwindle would have built them: each window is tiled while focusing the
    one whose region it splits. Appends (window, window-to-focus) to out."""
    if anchor is None:
        anchor = group[0]
        out.append((anchor, None))
    if len(group) == 1:
        return
    left, top = min(w["at"][0] for w in group), min(w["at"][1] for w in group)
    width = max(w["at"][0] + w["size"][0] for w in group) - left
    height = max(w["at"][1] + w["size"][1] for w in group) - top
    halves = cut(group, width >= height) or cut(group, width < height)
    if not halves:
        for w in group:
            if w is not anchor:
                out.append((w, anchor))
        return
    first, second = halves
    out.append((second[0], first[0]))
    plan(first, out, first[0])
    plan(second, out, second[0])


def batch(cmds):
    if cmds:
        hypr("--batch", " ; ".join(cmds))


def option(name):
    try:
        d = json.loads(hypr("getoption", name, "-j"))
        return d.get("bool", d.get("int"))
    except (ValueError, AttributeError):
        return None


SLIDE_SECONDS = 0.75


def show(ws, state):
    saved = state.pop(str(ws), [])
    save(state)
    alive = {c["address"] for c in clients()}
    saved = [w for w in saved if w["address"] in alive]
    active = (json.loads(hypr("activewindow", "-j") or "{}") or {}).get("address")

    # 1. Slide everything back to its place (smooth: they are all floating) ...
    for w in saved:
        move(w["address"], w["at"][0], w["at"][1])
    # hyprctl reports the target position at once, so the end of the animation can only be waited for
    time.sleep(SLIDE_SECONDS)

    # 2. ... then put the tiled ones back in the layout in one go, with animations and cursor warps off,
    #    so the swap from floating to tiled is not visible (positions already match).
    tiled = [w for w in saved if not w["floating"]]
    steps = []
    if tiled:
        tiled.sort(key=lambda w: (w["at"][0], w["at"][1]))
        plan(tiled, steps)
    anim = option("animations:enabled")
    warps = option("cursor:no_warps")
    split = option("dwindle:force_split") or 0
    # force_split = 2: a new window always goes to the right/bottom, whatever the pointer position
    hypr("eval", "hl.config({ animations = { enabled = false }, cursor = { no_warps = true }, dwindle = { force_split = 2 } })")
    cmds = []
    for w, focus_on in steps:
        if focus_on:
            cmds.append(f"dispatch hl.dsp.focus({{ {win(focus_on['address'])} }})")
        cmds.append(f'dispatch hl.dsp.window.float({{ action = "disable", {win(w["address"])} }})')
    if active and active in alive:
        cmds.append(f'dispatch hl.dsp.focus({{ window = "address:{active}" }})')
    batch(cmds)
    time.sleep(0.05)
    hypr("eval", f"hl.config({{ animations = {{ enabled = {'false' if anim is False else 'true'} }}, cursor = {{ no_warps = {'true' if warps else 'false'} }}, dwindle = {{ force_split = {split} }} }})")


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
