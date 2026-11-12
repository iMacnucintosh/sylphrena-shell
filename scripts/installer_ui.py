"""Terminal look of the Sylphrena installer: banner, checklist, spinner. Plain text when there is no colour terminal
(a pipe, NO_COLOR, TERM=dumb), so logs and CI stay readable."""
from __future__ import annotations

import os
import re
import shutil
import sys
import textwrap
import threading
import time
from collections import deque

COLOR = sys.stdout.isatty() and not os.environ.get("NO_COLOR") and os.environ.get("TERM", "") != "dumb"
TRUECOLOR = COLOR and os.environ.get("COLORTERM", "") in ("truecolor", "24bit")
LAVENDER, ROSE = (207, 188, 255), (255, 177, 200)
GREEN, RED, AMBER = (160, 220, 170), (255, 150, 150), (240, 200, 130)

# Calvin S, three lines per letter
FONT = {
    "S": ("╔═╗", "╚═╗", "╚═╝"), "Y": ("╦ ╦", "╚╦╝", " ╩ "), "L": ("╦  ", "║  ", "╩═╝"), "P": ("╔═╗", "╠═╝", "╩  "),
    "H": ("╦ ╦", "╠═╣", "╩ ╩"), "R": ("╦═╗", "╠╦╝", "╩╚═"), "E": ("╔═╗", "║╣ ", "╚═╝"), "N": ("╔╗╔", "║║║", "╝╚╝"),
    "A": ("╔═╗", "╠═╣", "╩ ╩"),
}


def rgb(color: tuple[int, int, int], text: str, bold: bool = False) -> str:
    if not COLOR:
        return text
    r, g, b = color
    code = f"38;2;{r};{g};{b}" if TRUECOLOR else f"38;5;{16 + 36 * (r * 5 // 255) + 6 * (g * 5 // 255) + (b * 5 // 255)}"
    return f"\033[{'1;' if bold else ''}{code}m{text}\033[0m"


def style(text: str, bold: bool = False, dim: bool = False, reverse: bool = False) -> str:
    if not COLOR:
        return text
    codes = [c for c, on in (("1", bold), ("2", dim), ("7", reverse)) if on]
    return f"\033[{';'.join(codes)}m{text}\033[0m" if codes else text


def width() -> int:
    return max(50, min(100, shutil.get_terminal_size((90, 24)).columns - 2))


def mix(a: tuple[int, int, int], b: tuple[int, int, int], t: float) -> tuple[int, int, int]:
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3))  # type: ignore[return-value]


def banner(tagline: str, version: str = "") -> None:
    word = "SYLPHRENA"
    rows = ["", "", ""]
    for idx, ch in enumerate(word):
        color = mix(LAVENDER, ROSE, idx / (len(word) - 1))
        for r in range(3):
            rows[r] += rgb(color, FONT[ch][r]) + " "
    print()
    for r in rows:
        print("   " + r.rstrip())
    sub = f"✦  {tagline}" + (f"  ·  {version}" if version else "")
    print("\n   " + rgb(LAVENDER, sub) + "\n")


def rule(title: str) -> None:
    line = "─" * max(4, width() - len(title) - 6)
    print(f"\n  {rgb(LAVENDER, '◆', True)} {style(title, bold=True)} {style(line, dim=True)}")


def ok(text: str) -> str:
    return rgb(GREEN, "✔") + " " + text


def bad(text: str) -> str:
    return rgb(RED, "✘") + " " + text


def wrap(text: str, indent: int, first: str = "") -> str:
    return textwrap.fill(text, width=width(), initial_indent=first.ljust(indent), subsequent_indent=" " * indent,
                         break_long_words=False, break_on_hyphens=False)


# ── The checklist ────────────────────────────────────────────────────────────────────────────────

def read_key() -> str:
    """One key: up, down, space, enter, q, or the character."""
    import termios
    import tty

    fd = sys.stdin.fileno()
    old = termios.tcgetattr(fd)
    try:
        tty.setcbreak(fd)
        ch = sys.stdin.read(1)
        if ch == "\x1b":
            nxt = sys.stdin.read(1)
            if nxt == "[":
                return {"A": "up", "B": "down"}.get(sys.stdin.read(1), "")
            return "esc"
        if ch in ("\r", "\n"):
            return "enter"
        if ch == "\x03":
            raise KeyboardInterrupt
        return "space" if ch == " " else ch
    finally:
        termios.tcsetattr(fd, termios.TCSADRAIN, old)


def can_interact() -> bool:
    if not (sys.stdin.isatty() and sys.stdout.isatty() and COLOR):
        return False
    try:
        import termios  # noqa: F401
    except ImportError:
        return False
    return shutil.get_terminal_size((90, 24)).lines >= MIN_LINES


ANSI = re.compile(r"\x1b\[[0-9;?]*[A-Za-z]")
MIN_LINES = 24      # the list scrolls, but it needs room for the panel and the keys
PANEL_LINES = 8     # border, space, up to three lines of explanation, space, the password line, border
FOOTER_LINES = 3    # blank, count, keys


def title_words(text: str) -> str:
    """The first letter of every word in capitals; the rest is left as it is (DDC/CI, sylph…)."""
    return " ".join(w[:1].upper() + w[1:] for w in text.split(" "))


def visible(text: str) -> int:
    return len(ANSI.sub("", text))


def box(title: str, lines: list[str], w: int) -> list[str]:
    """A rounded box `w` wide; `title` goes into the top border."""
    inner = w - 6      # two spaces of margin on each side
    head = f"╭─ {title} "
    out = [rgb(LAVENDER, head + "─" * max(1, w - len(head) - 1) + "╮")]
    for line in lines:
        out.append(rgb(LAVENDER, "│") + "  " + line + " " * max(0, inner - visible(line)) + "  " + rgb(LAVENDER, "│"))
    out.append(rgb(LAVENDER, "╰" + "─" * (w - 2) + "╯"))
    return out


def checklist(groups: list[tuple[str, list]], describe, lock_text, hint: str, status_text, label=None, required_text: str = "required") -> bool:
    """Arrow keys / space / enter. `groups` = [(title, [item…])]; an item has title, on, todo, required.
    `describe(item)` explains the highlighted one (shown in a box under the list). The list scrolls when the terminal is
    short, so the frame always has the same height. Returns False if the user quits."""
    label = label or (lambda it: it.title)
    flat = [it for _, rows in groups for it in rows]
    movable = [i for i, it in enumerate(flat) if it.todo]
    if not movable:
        return True
    pos = movable[0]
    top = 0
    printed = 0
    out = sys.stdout

    def body_lines() -> tuple[list[str], dict[int, int]]:
        lines: list[str] = []
        row_at: dict[int, int] = {}
        n = -1
        for title, rows in groups:
            lines.append(f"  {rgb(LAVENDER, '◆', True)} {style(title, bold=True)}")
            for it in rows:
                n += 1
                if not it.todo:
                    box_, name = rgb(GREEN, "✔"), style(label(it), dim=True)
                elif it.required:
                    box_, name = rgb(LAVENDER, "◉"), label(it)
                else:
                    box_, name = (rgb(LAVENDER, "◉") if it.on else style("○", dim=True)), label(it)
                tag = style("  " + required_text, dim=True) if (it.todo and it.required) else ""
                pointer = rgb(ROSE, "❯", True) if n == pos else " "
                text = f"   {pointer} {box_} {name}{tag}"
                row_at[n] = len(lines)
                lines.append(style(text, bold=True) if n == pos else text)
        return lines, row_at

    def render() -> None:
        nonlocal printed, top
        rows_available = max(8, shutil.get_terminal_size((90, 24)).lines - PANEL_LINES - FOOTER_LINES - 2)
        lines, row_at = body_lines()
        height = min(len(lines), rows_available)
        here = row_at[pos]
        scrolls = len(lines) > height
        # The first and last visible lines carry the "more" marks when the list scrolls: keep the highlighted row clear
        # of them, and show its group title above it when it fits
        low, high = (1, height - 2) if scrolls else (0, height - 1)
        if here - top < low:
            top = here - low
        if here - top > high:
            top = here - high
        if scrolls and here - top == low and here > 0 and ANSI.sub("", lines[here - 1]).strip().startswith("◆"):
            top = max(0, here - low - 1)
        top = max(0, min(top, len(lines) - height))
        view = lines[top:top + height]
        if top > 0:
            view[0] = "  " + style("↑ ...", dim=True)
        if top + height < len(lines):
            view[-1] = "  " + style("↓ ...", dim=True)
        view += [""] * (rows_available - len(view)) if len(lines) >= rows_available else []
        w = min(width(), 80)
        it = flat[pos]
        text = (textwrap.wrap(title_words(describe(it)), w - 8) or [""])[:3]
        # a line of air above and below the explanation, then the password line
        panel_text = [""] + text + ["", style(lock_text(it), dim=True)]
        panel = ["  " + l for l in box(label(it), panel_text, w)]
        # the box is as tall as its text; the space below keeps the whole frame the same height (so it redraws cleanly)
        panel += [""] * (PANEL_LINES - len(panel))
        frame = view + [""] + panel + ["", "  " + style(status_text(flat), dim=True) + "   " + style(hint, dim=True)]
        if printed:
            out.write(f"\033[{printed}F\033[J")
        out.write("\n".join(frame) + "\n")
        out.flush()
        printed = len(frame)

    out.write("\033[?25l")
    try:
        while True:
            render()
            key = read_key()
            if key in ("q", "esc"):
                return False
            if key == "enter":
                return True
            if key in ("up", "k"):
                pos = movable[(movable.index(pos) - 1) % len(movable)]
            elif key in ("down", "j"):
                pos = movable[(movable.index(pos) + 1) % len(movable)]
            elif key == "space" and not flat[pos].required:
                flat[pos].on = not flat[pos].on
    finally:
        out.write("\033[?25h")
        out.flush()


# ── Spinner for the quiet runs ───────────────────────────────────────────────────────────────────

class Spinner:
    FRAMES = "⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"

    def __init__(self, title: str):
        self.title = title
        self.detail = ""
        self.started = time.time()
        self._stop = threading.Event()
        self._thread: threading.Thread | None = None

    def __enter__(self) -> "Spinner":
        if COLOR and sys.stdout.isatty():
            self._thread = threading.Thread(target=self._spin, daemon=True)
            self._thread.start()
        else:
            print(f"  ... {self.title}", flush=True)
        return self

    def _spin(self) -> None:
        i = 0
        while not self._stop.is_set():
            elapsed = int(time.time() - self.started)
            room = max(10, width() - len(self.title) - 14)
            detail = style(self.detail[-room:], dim=True) if self.detail else ""
            sys.stdout.write(f"\r\033[K  {rgb(LAVENDER, self.FRAMES[i % len(self.FRAMES)])} {self.title}  "
                             f"{style(f'{elapsed}s', dim=True)}  {detail}")
            sys.stdout.flush()
            i += 1
            time.sleep(0.1)

    def __exit__(self, *exc) -> None:
        self._stop.set()
        if self._thread:
            self._thread.join()
            sys.stdout.write("\r\033[K")
            sys.stdout.flush()

    def seconds(self) -> int:
        return int(time.time() - self.started)


def tail(lines: "deque[str]", n: int = 25) -> str:
    return "\n".join("    " + style(l.rstrip(), dim=True) for l in list(lines)[-n:])
