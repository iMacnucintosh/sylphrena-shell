#!/usr/bin/env python3
"""Sylphrena installer: from a bare Arch + Hyprland to the complete experience, in one terminal session.

  ./install.sh [options]            (install.sh makes sure git, base-devel and python are there, then runs this)

It looks at the system, shows what is missing and why, asks, and does it with a single password:
  Required      an AUR helper (yay) if there is none, the AUR packages the shell builds on, and the four
                packages of Sylphrena: sylphrena-cli, seeker, things and the shell itself
  Recommended   the font of the clock, the screen recorder, DDC/CI brightness for an external monitor
  Setup         hook the shell into Hyprland, create the first-run settings, connect kitty
  Login screen  greetd with the Sylphrena greeter (replaces the display manager you have)
  Optional      the recommended extensions (Tasks, Hydration)
Nothing is changed before you confirm. It can be run again: it only does what is still missing.

Options:  --yes (accept the defaults)   --dry-run (show the commands, run nothing)   --list (what it found, JSON)
          --only ID[,ID]   --skip ID[,ID]   --no-login-screen   --help
Log: ~/.local/state/sylphrena/install.log
"""
from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
import textwrap
import threading
import time
import urllib.error
import urllib.request
from dataclasses import dataclass, field
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent
INSTALLED_SHELL = Path("/etc/xdg/quickshell/sylphrena")
GITHUB = "https://github.com/iMacnucintosh"
# Our packages, in the order they have to be installed (the shell depends on the other three)
PACKAGES = [("sylphrena-cli-git", "sylphrena-cli"), ("seeker-git", "seeker"), ("things-git", "things"),
            ("sylphrena-shell-git", "sylphrena-shell")]
AUR_DEPS = ["quickshell-git", "qt6-m3shapes-git", "python-materialyoucolor"]
HUB_INDEX = "https://raw.githubusercontent.com/iMacnucintosh/sylphrena-hub/main/index.json"
RECOMMENDED_EXTENSIONS = ["tasks", "hydration"]
STATE = Path(os.environ.get("XDG_STATE_HOME") or Path.home() / ".local/state") / "sylphrena"
CACHE = Path(os.environ.get("XDG_CACHE_HOME") or Path.home() / ".cache") / "sylphrena-install"

ES = {
    "Sylphrena installer": "Instalador de Sylphrena",
    "This computer": "Este equipo",
    "Required": "Necesario", "Recommended": "Recomendado", "Setup": "Configuración", "Login screen": "Pantalla de inicio de sesión",
    "Optional": "Opcional",
    "Already done": "Ya hecho",
    "Nothing to do: everything is already in place.": "Nada que hacer: todo está ya en su sitio.",
    "Administrator password: asked once": "Contraseña de administrador: se pide una vez",
    "Type the number of an item to switch it on or off, Enter to continue, q to quit": "Escribe el número de un elemento para activarlo o desactivarlo, Intro para continuar, q para salir",
    "Nothing has been changed yet.": "Todavía no se ha cambiado nada.",
    "Continue?": "¿Continuar?",
    "Cancelled. Nothing was changed.": "Cancelado. No se ha cambiado nada.",
    "Run without a password prompt: not possible here": "Ejecutar sin pedir contraseña: no es posible aquí",
    "Done": "Hecho", "Failed": "Falló", "Skipped": "Omitido",
    "It did not finish: %s": "No terminó: %s", "See the log: %s": "Mira el registro: %s",
    "Everything is ready.": "Todo está listo.",
    "Start it now with: sylph shell -d  (or log out and back in: Hyprland starts it)": "Arráncala ahora con: sylph shell -d  (o cierra sesión y vuelve a entrar: Hyprland la arranca)",
    "A copy of your Hyprland configuration is in %s": "Hay una copia de tu configuración de Hyprland en %s",
    "Do not run this as root: the AUR packages cannot be built as root. Run it as your user; it asks for sudo when it needs it.": "No lo ejecutes como root: los paquetes del AUR no se pueden construir como root. Ejecútalo con tu usuario; pide sudo cuando lo necesita.",
    "This installer is for Arch Linux and its derivatives.": "Este instalador es para Arch Linux y derivados.",
    "sudo does not work for this user: it is needed to install packages.": "sudo no funciona con este usuario: hace falta para instalar paquetes.",
    "Base tools": "Herramientas base", "to build packages from the AUR and run this installer": "para construir paquetes del AUR y ejecutar este instalador",
    "Hyprland": "Hyprland", "the compositor Sylphrena runs on": "el compositor sobre el que corre Sylphrena",
    "AUR helper (yay)": "Ayudante del AUR (yay)", "to install packages that are only in the AUR": "para instalar paquetes que solo están en el AUR",
    "Libraries from the AUR": "Librerías del AUR", "Quickshell (git version), the Material shapes and the colour library the shell is built on": "Quickshell (versión git), las formas Material y la librería de color sobre las que se construye la shell",
    "Remove the stable Quickshell": "Quitar el Quickshell estable", "it conflicts with the git version the shell needs": "choca con la versión git que necesita la shell",
    "sylphrena-cli": "sylphrena-cli", "the sylph command (shell, themes, wallpapers, screenshots)": "el comando sylph (shell, temas, fondos, capturas)",
    "Seeker": "Seeker", "the file manager of Sylphrena": "el explorador de archivos de Sylphrena",
    "Things": "Things", "the package manager and extension manager": "el gestor de paquetes y de extensiones",
    "Sylphrena shell": "Shell de Sylphrena", "the shell itself, with its icons, GTK theme, fonts and tools": "la shell, con sus iconos, tema GTK, fuentes y herramientas",
    "Clock font (Rubik)": "Fuente del reloj (Rubik)", "the font of the clock and the workspaces": "la fuente del reloj y de los escritorios",
    "Screen recorder": "Grabador de pantalla", "so that sylph record works": "para que funcione sylph record",
    "External monitor brightness (ddcutil)": "Brillo del monitor externo (ddcutil)", "this computer has no built-in screen, so its monitor is controlled over DDC/CI": "este equipo no tiene pantalla integrada, así que su monitor se controla por DDC/CI",
    "lets the brightness slider reach an external monitor over DDC/CI": "deja que el control de brillo llegue a un monitor externo por DDC/CI",
    "Hook Sylphrena into Hyprland": "Enganchar Sylphrena a Hyprland", "starts the shell with the session and loads its shortcuts and rules; your configuration is only added to, and copied first": "arranca la shell con la sesión y carga sus atajos y reglas; a tu configuración solo se le añade, y se copia antes",
    "First-run settings": "Ajustes del primer arranque", "the recommended settings, one activity with its wallpaper, and kitty connected to the colours": "los ajustes recomendados, una actividad con su fondo y kitty conectado a los colores",
    "Sylphrena login screen": "Pantalla de inicio de sesión de Sylphrena", "greetd with the Material You greeter; it replaces %s": "greetd con el greeter Material You; sustituye a %s",
    "greetd with the Material You greeter": "greetd con el greeter Material You",
    "Recommended extensions": "Extensiones recomendadas", "Tasks and Hydration, from the Sylphrena Hub": "Tareas e Hidratación, del Sylphrena Hub",
    "asks for the password": "pide contraseña", "no password": "sin contraseña",
    "Hyprland needs to be installed first: it will be added.": "Primero hace falta Hyprland: se añadirá.",
    "yes": "sí", "no": "no",
}


def tr(text: str) -> str:
    lang = ""
    for key in ("LC_ALL", "LC_MESSAGES", "LANG"):
        v = os.environ.get(key, "")
        if v and v != "C" and not v.startswith("C."):
            lang = v.replace("-", "_").split(".")[0].split("_")[0].lower()
            break
    return ES.get(text, text) if lang == "es" else text


# ── What the system has ──────────────────────────────────────────────────────────────────────────

def sh(cmd: list[str], timeout: int = 20) -> tuple[int, str]:
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout, stdin=subprocess.DEVNULL)
        return r.returncode, r.stdout.strip()
    except (OSError, subprocess.SubprocessError):
        return 1, ""


@dataclass
class Facts:
    arch: bool = True
    is_root: bool = False
    helper: str | None = None
    installed: set[str] = field(default_factory=set)
    in_aur: set[str] = field(default_factory=set)         # of the packages we may need from there
    backlight: bool = True                                  # a built-in screen with its own brightness
    display_manager: str | None = None
    hyprland_config: bool = False
    hyprland_needed: bool = True                            # setup-hyprland.py --check says it would change something
    first_run_needed: bool = True                           # same for the first-run settings and kitty
    greeter_installed: bool = False
    extensions: set[str] = field(default_factory=set)       # already installed

    def have(self, pkg: str) -> bool:
        return pkg in self.installed


def provided(pkg: str) -> bool:
    return sh(["pacman", "-Qq", pkg])[0] == 0


def aur_knows(pkgs: list[str]) -> set[str]:
    if not pkgs:
        return set()
    url = "https://aur.archlinux.org/rpc/v5/info?" + "&".join("arg[]=" + p for p in pkgs)
    try:
        with urllib.request.urlopen(url, timeout=8) as r:
            return {i["Name"] for i in json.load(r).get("results", [])}
    except (OSError, ValueError, urllib.error.URLError):
        return set()


def check_status(script: str) -> str:
    """What a setup script (--check: it changes nothing) says it would do: needed | already | seen | kept | ..."""
    path = installed_shell_dir() / "scripts" / script
    code, out = sh([sys.executable, str(path), "--check"], timeout=60)
    try:
        return json.loads(out)["status"]
    except (ValueError, KeyError, TypeError):
        return "needed" if code else "unknown"


def scan() -> Facts:
    f = Facts()
    f.arch = Path("/etc/arch-release").exists() or shutil.which("pacman") is not None
    f.is_root = os.geteuid() == 0
    f.helper = next((h for h in ("yay", "paru") if shutil.which(h)), None)
    names = ["git", "base-devel", "hyprland", "quickshell", "quickshell-git", "greetd", "ddcutil", "gpu-screen-recorder", "ttf-rubik-vf",
             "rsync", *AUR_DEPS, *(p for p, _ in PACKAGES)]
    f.installed = {n for n in dict.fromkeys(names) if provided(n)}
    f.in_aur = aur_knows([*AUR_DEPS, "ttf-rubik-vf", *(p for p, _ in PACKAGES)])
    backlight = Path("/sys/class/backlight")
    f.backlight = backlight.is_dir() and any(backlight.iterdir())
    unit = Path("/etc/systemd/system/display-manager.service")
    if unit.is_symlink():
        f.display_manager = os.path.basename(os.readlink(unit)).removesuffix(".service")
    config = Path(os.environ.get("XDG_CONFIG_HOME") or Path.home() / ".config") / "hypr" / "hyprland.lua"
    f.hyprland_config = config.is_file()
    f.hyprland_needed = check_status("setup-hyprland.py") in ("needed", "failed")
    f.first_run_needed = any(check_status(n) == "needed" for n in ("setup-defaults.py", "setup-kitty.py"))
    f.greeter_installed = Path("/etc/greetd/sylphrena").is_dir() and f.display_manager == "greetd"
    ext_dir = Path(os.environ.get("XDG_DATA_HOME") or Path.home() / ".local/share") / "sylphrena" / "extensions"
    f.extensions = {d.name for d in ext_dir.iterdir() if d.is_dir()} if ext_dir.is_dir() else set()
    return f


# ── The plan ─────────────────────────────────────────────────────────────────────────────────────

@dataclass
class Step:
    kind: str            # pacman | aur | build | user | root | write-root | extension
    args: list = field(default_factory=list)


@dataclass
class Item:
    id: str
    group: str
    title: str
    why: str
    root: bool
    todo: bool = True
    default: bool = True
    required: bool = False
    steps: list[Step] = field(default_factory=list)
    on: bool = True


def installed_shell_dir() -> Path:
    return INSTALLED_SHELL if INSTALLED_SHELL.is_dir() else ROOT


def build_plan(f: Facts, login_screen: bool = True) -> list[Item]:
    items: list[Item] = []
    helper = f.helper or "yay"

    def add(*a, **k) -> Item:
        it = Item(*a, **k)
        it.on = it.default and it.todo
        items.append(it)
        return it

    missing_tools = [p for p in ("git", "base-devel") if not f.have(p)]
    add("tools", "Required", "Base tools", "to build packages from the AUR and run this installer", True, todo=bool(missing_tools),
        required=True, steps=[Step("pacman", missing_tools)] if missing_tools else [])
    add("hyprland", "Required", "Hyprland", "the compositor Sylphrena runs on", True, todo=not f.have("hyprland"), required=True,
        steps=[Step("pacman", ["hyprland"])])
    need_aur = [p for p in AUR_DEPS if not f.have(p)]
    own_from_aur = [p for p, _ in PACKAGES if not f.have(p) and p in f.in_aur]
    need_helper = f.helper is None and bool(need_aur or own_from_aur or not f.have("ttf-rubik-vf"))
    add("aur-helper", "Required", "AUR helper (yay)", "to install packages that are only in the AUR", True, todo=need_helper,
        required=True, steps=[Step("build", ["yay-bin", "https://aur.archlinux.org/yay-bin.git"])])
    conflict = f.have("quickshell") and not f.have("quickshell-git") and "quickshell-git" in need_aur
    if conflict:
        add("quickshell-conflict", "Required", "Remove the stable Quickshell", "it conflicts with the git version the shell needs",
            True, required=True, steps=[Step("root", ["pacman", "-Rdd", "--noconfirm", "quickshell"])])
    add("aur-deps", "Required", "Libraries from the AUR",
        "Quickshell (git version), the Material shapes and the colour library the shell is built on", True, todo=bool(need_aur),
        required=True, steps=[Step("aur", need_aur)] if need_aur else [])
    labels = {"sylphrena-cli-git": ("sylphrena-cli", "the sylph command (shell, themes, wallpapers, screenshots)"),
              "seeker-git": ("Seeker", "the file manager of Sylphrena"), "things-git": ("Things", "the package manager and extension manager"),
              "sylphrena-shell-git": ("Sylphrena shell", "the shell itself, with its icons, GTK theme, fonts and tools")}
    for pkg, repo in PACKAGES:
        title, why = labels[pkg]
        step = Step("aur", [pkg]) if pkg in f.in_aur else Step("build", [pkg, f"{GITHUB}/{repo}", "packaging"])
        add(pkg, "Required", title, why, True, todo=not f.have(pkg), required=True, steps=[step])
    add("rubik", "Recommended", "Clock font (Rubik)", "the font of the clock and the workspaces", True, todo=not f.have("ttf-rubik-vf"),
        steps=[Step("aur", ["ttf-rubik-vf"])])
    add("recorder", "Recommended", "Screen recorder", "so that sylph record works", True, todo=not f.have("gpu-screen-recorder"),
        steps=[Step("pacman", ["gpu-screen-recorder"])])
    ddc_steps = [Step("pacman", ["ddcutil"]), Step("write-root", ["/etc/modules-load.d/i2c-dev.conf", "i2c-dev\n"]),
                 Step("root", ["modprobe", "i2c-dev"], ) ]
    add("ddcutil", "Recommended", "External monitor brightness (ddcutil)",
        "this computer has no built-in screen, so its monitor is controlled over DDC/CI" if not f.backlight
        else "lets the brightness slider reach an external monitor over DDC/CI",
        True, todo=not f.have("ddcutil"), default=not f.backlight, steps=ddc_steps)
    shell_dir = installed_shell_dir()
    add("hyprland-config", "Setup", "Hook Sylphrena into Hyprland",
        "starts the shell with the session and loads its shortcuts and rules; your configuration is only added to, and copied first",
        False, todo=f.hyprland_needed,
        steps=[Step("user", [sys.executable, str(shell_dir / "scripts" / "setup-hyprland.py"), "--shell-dir", str(shell_dir)])])
    add("first-run", "Setup", "First-run settings",
        "the recommended settings, one activity with its wallpaper, and kitty connected to the colours", False,
        todo=f.first_run_needed, steps=[Step("user", [sys.executable, str(shell_dir / "scripts" / "setup-defaults.py")]),
               Step("user", [sys.executable, str(shell_dir / "scripts" / "setup-kitty.py")])])
    if login_screen:
        dm = f.display_manager if f.display_manager not in (None, "greetd") else None
        steps = [Step("pacman", [p for p in ("greetd", "rsync") if not f.have(p)])] if not (f.have("greetd") and f.have("rsync")) else []
        steps += [Step("root", [str(shell_dir / "scripts" / "install-system.sh")])]
        if dm:
            steps.append(Step("root", ["systemctl", "disable", f"{dm}.service"]))
        steps.append(Step("root", ["systemctl", "enable", "-f", "greetd.service"]))
        add("login-screen", "Login screen", "Sylphrena login screen",
            f"greetd with the Material You greeter; it replaces {dm}" if dm else "greetd with the Material You greeter",
            True, todo=not f.greeter_installed, steps=steps)
    ext_missing = [e for e in RECOMMENDED_EXTENSIONS if e not in f.extensions]
    add("extensions", "Optional", "Recommended extensions", "Tasks and Hydration, from the Sylphrena Hub", False, todo=bool(ext_missing),
        default=False, steps=[Step("extension", [e]) for e in ext_missing])
    return items


# ── Doing it ─────────────────────────────────────────────────────────────────────────────────────

class Runner:
    """Runs the steps; `dry` only prints them. Everything goes to the log too."""

    def __init__(self, dry: bool, helper: str | None, log: Path | None):
        self.dry, self.helper, self.log = dry, helper or "yay", log
        self._sudo_alive = False

    def say(self, text: str, out=None) -> None:
        print(text, file=out or sys.stdout, flush=True)
        if self.log:
            with self.log.open("a") as fh:
                fh.write(text + "\n")

    def run(self, cmd: list[str], cwd: Path | None = None, input_text: str | None = None) -> bool:
        self.say("   $ " + " ".join(cmd))
        if self.dry:
            return True
        try:
            p = subprocess.Popen(cmd, cwd=cwd, stdin=subprocess.PIPE if input_text is not None else subprocess.DEVNULL,
                                 stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        except OSError as e:
            self.say(f"   {e}")
            return False
        if input_text is not None:
            p.stdin.write(input_text)
            p.stdin.close()
        for line in p.stdout:
            if self.log:
                with self.log.open("a") as fh:
                    fh.write(line)
            sys.stdout.write("   │ " + line if line.endswith("\n") else line)
        return p.wait() == 0

    def keep_sudo(self) -> bool:
        if self.dry:
            return True
        if subprocess.run(["sudo", "-v"]).returncode != 0:
            return False
        self._sudo_alive = True

        def refresh() -> None:
            while self._sudo_alive:
                time.sleep(50)
                subprocess.run(["sudo", "-n", "-v"], capture_output=True)

        threading.Thread(target=refresh, daemon=True).start()
        return True

    def stop_sudo(self) -> None:
        self._sudo_alive = False

    def step(self, s: Step) -> bool:
        k, a = s.kind, s.args
        if k == "pacman":
            return not a or self.run(["sudo", "pacman", "-S", "--needed", "--noconfirm", *a])
        if k == "aur":
            return not a or self.run([self.helper, "-S", "--needed", "--noconfirm", *a])
        if k == "build":
            name, url = a[0], a[1]
            sub = a[2] if len(a) > 2 else "."
            work = CACHE / name
            if not self.dry:
                shutil.rmtree(work, ignore_errors=True)
                CACHE.mkdir(parents=True, exist_ok=True)
            return self.run(["git", "clone", "--depth", "1", url, str(work)]) and \
                self.run(["makepkg", "-si", "--noconfirm", "--needed"], cwd=(work / sub))
        if k == "user":
            return self.run(a)
        if k == "root":
            return self.run(["sudo", *a])
        if k == "write-root":
            path, content = a
            return self.run(["sudo", "tee", path], input_text=content)
        if k == "extension":
            return install_extension(self, a[0])
        raise ValueError(k)


def install_extension(r: Runner, ext_id: str) -> bool:
    script = installed_shell_dir() / "scripts" / "ext.py"
    if r.dry:
        r.say(f"   $ python3 {script} install-hub {ext_id} --url <zip of the hub> --sha256 <hash> --version <version>")
        return True
    try:
        with urllib.request.urlopen(HUB_INDEX, timeout=15) as resp:
            entry = next(i for i in json.load(resp)["items"] if i["id"] == ext_id)
    except (OSError, ValueError, StopIteration, urllib.error.URLError) as e:
        r.say(f"   could not read the hub: {e}")
        return False
    return r.run([sys.executable, str(script), "install-hub", ext_id, "--url", entry["zip"], "--sha256", entry["sha256"],
                  "--version", entry["version"]])


def execute(items: list[Item], r: Runner) -> list[tuple[Item, str]]:
    results: list[tuple[Item, str]] = []
    for it in items:
        if not it.on or not it.todo:
            results.append((it, "skipped"))
            continue
        r.say(f"\n==> {tr(it.title)}")
        ok = all(r.step(s) for s in it.steps)
        results.append((it, "done" if ok else "failed"))
        if not ok and it.required:
            r.say("\n" + tr("It did not finish: %s") % tr(it.title))
            break
    return results


# ── The conversation ─────────────────────────────────────────────────────────────────────────────

GROUPS = ["Required", "Recommended", "Setup", "Login screen", "Optional"]
BOLD, DIM, RESET = ("\033[1m", "\033[2m", "\033[0m") if sys.stdout.isatty() else ("", "", "")


def show(items: list[Item], f: Facts) -> None:
    print(f"\n{BOLD}{tr('Sylphrena installer')}{RESET}\n")
    for g in GROUPS:
        rows = [(i, it) for i, it in enumerate(items, 1) if it.group == g]
        if not rows:
            continue
        print(f"{BOLD}{tr(g)}{RESET}")
        for i, it in rows:
            mark = "[x]" if it.on else "[ ]"
            if not it.todo:
                mark, why = " ✓ ", tr("Already done")
            else:
                why = tr(it.why) % f.display_manager if "%s" in it.why else tr(it.why)
            lock = f" ({tr('asks for the password') if it.root else tr('no password')})" if it.todo else ""
            head = f"  {mark} {i:>2}. "
            body = f"{tr(it.title)}  {DIM}— {why}{lock}{RESET}"
            width = max(40, shutil.get_terminal_size((100, 24)).columns - 2)
            print(textwrap.fill(head + body, width=width, subsequent_indent=" " * len(head), break_long_words=False,
                                break_on_hyphens=False))
        print()


def conversation(items: list[Item], f: Facts, yes: bool) -> bool:
    show(items, f)
    todo = [i for i in items if i.todo and i.on]
    if not todo:
        print(tr("Nothing to do: everything is already in place."))
        return False
    if yes or not sys.stdin.isatty():
        return True
    while True:
        if any(i.root for i in todo):
            print(tr("Administrator password: asked once"))
        print(tr("Nothing has been changed yet."))
        answer = input(tr("Type the number of an item to switch it on or off, Enter to continue, q to quit") + ": ").strip().lower()
        if answer in ("q", "quit", "n", "no"):
            return False
        if answer == "":
            return True
        for token in answer.replace(",", " ").split():
            if token.isdigit() and 1 <= int(token) <= len(items):
                it = items[int(token) - 1]
                if it.todo and not it.required:
                    it.on = not it.on
        show(items, f)
        todo = [i for i in items if i.todo and i.on]


def parse(argv: list[str]) -> dict:
    opts = {"yes": False, "dry": False, "list": False, "only": None, "skip": set(), "login": True}
    it = iter(argv)
    for a in it:
        if a in ("--yes", "-y"):
            opts["yes"] = True
        elif a == "--dry-run":
            opts["dry"] = True
        elif a == "--list":
            opts["list"] = True
        elif a == "--no-login-screen":
            opts["login"] = False
        elif a == "--only":
            opts["only"] = set(next(it, "").split(","))
        elif a == "--skip":
            opts["skip"] |= set(next(it, "").split(","))
        elif a in ("-h", "--help"):
            print(__doc__)
            raise SystemExit(0)
        else:
            print(f"unknown option: {a}", file=sys.stderr)
            raise SystemExit(2)
    return opts


def main(argv: list[str] | None = None) -> int:
    opts = parse(sys.argv[1:] if argv is None else argv)
    f = scan()
    if f.is_root:
        print(tr("Do not run this as root: the AUR packages cannot be built as root. Run it as your user; it asks for sudo when it needs it."), file=sys.stderr)
        return 1
    if not f.arch:
        print(tr("This installer is for Arch Linux and its derivatives."), file=sys.stderr)
        return 1
    items = build_plan(f, login_screen=opts["login"])
    for it in items:
        if opts["only"] is not None and it.id not in opts["only"] and not it.required:
            it.on = False
        if it.id in opts["skip"] and not it.required:
            it.on = False
    if opts["list"]:
        print(json.dumps([{"id": i.id, "group": i.group, "title": i.title, "root": i.root, "todo": i.todo, "on": i.on, "required": i.required}
                          for i in items]))
        return 0
    if not conversation(items, f, opts["yes"]):
        if any(i.todo and i.on for i in items) or sys.stdin.isatty():
            print(tr("Cancelled. Nothing was changed."))
        return 0
    STATE.mkdir(parents=True, exist_ok=True)
    log = STATE / "install.log"
    r = Runner(opts["dry"], f.helper, log if not opts["dry"] else None)
    if any(i.root and i.on and i.todo for i in items) and not r.keep_sudo():
        print(tr("sudo does not work for this user: it is needed to install packages."), file=sys.stderr)
        return 1
    try:
        results = execute(items, r)
    finally:
        r.stop_sudo()
    print()
    failed = [it for it, s in results if s == "failed"]
    for it, s in results:
        if s != "skipped":
            print(f"  {'✓' if s == 'done' else '✗'} {tr(it.title)}  ({tr('Done') if s == 'done' else tr('Failed')})")
    if failed:
        print("\n" + tr("See the log: %s") % log)
        return 1
    if not opts["dry"]:
        print("\n" + tr("Everything is ready."))
        print(tr("Start it now with: sylph shell -d  (or log out and back in: Hyprland starts it)"))
        backup = Path(os.environ.get("XDG_CONFIG_HOME") or Path.home() / ".config") / "hypr" / "hyprland.lua.sylphrena-backup"
        if backup.exists():
            print(tr("A copy of your Hyprland configuration is in %s") % backup)
    return 0


if __name__ == "__main__":
    sys.exit(main())
