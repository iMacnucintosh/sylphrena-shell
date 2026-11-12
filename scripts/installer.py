#!/usr/bin/env python3
"""Sylphrena installer: from a bare Arch + Hyprland to the complete experience, in one terminal session.

  ./install.sh [options]            (install.sh makes sure git, base-devel and python are there, then runs this)

It looks at the system, shows what is missing and why, asks, and does it with a single password:
  Required      an AUR helper (yay) if there is none, the AUR packages the shell builds on, and the four
                packages of Sylphrena: sylphrena-cli, seeker, things and the shell itself
  Recommended   the font of the clock, the screen recorder, DDC/CI brightness for an external monitor
  Setup         hook the shell into Hyprland, create the first-run settings, connect kitty
  Login screen  greetd with the Sylphrena greeter (replaces the display manager you have)
Nothing is changed before you confirm. It can be run again: it only does what is still missing.
Extensions are not part of it: they are installed later from Things.

Packages are built from the latest release of each repository; --main builds the latest commit instead.
--update only brings the installed packages and their setup up to date (what the shell runs when it offers a new version).

Options:  --yes (accept the defaults)   --dry-run (show the commands, run nothing)   --list (what it found, JSON)
          --only ID[,ID]   --skip ID[,ID]   --no-login-screen   --demo (preview on a bare system)   --verbose (show the output of every command)   --help
Log: ~/.local/state/sylphrena/install.log
"""
from __future__ import annotations

import json
import os
import re
import shutil
import subprocess
import sys
import threading
import time
from collections import deque
import urllib.error
import urllib.request
from dataclasses import dataclass, field
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import installer_ui as ui  # noqa: E402
ROOT = HERE.parent
INSTALLED_SHELL = Path("/etc/xdg/quickshell/sylphrena")
GITHUB = "https://github.com/iMacnucintosh"
# Our packages, in the order they have to be installed (the shell depends on the other three)
PACKAGES = [("sylphrena-cli-git", "sylphrena-cli"), ("seeker-git", "seeker"), ("things-git", "things"),
            ("sylphrena-shell-git", "sylphrena-shell")]
# Commands of the usual web browsers: with one of them there, Zen is offered but not selected
BROWSERS = ["zen-browser", "firefox", "chromium", "google-chrome-stable", "brave", "librewolf", "vivaldi-stable", "epiphany"]
# Dependencies of the shell package that are not in the Arch repositories (makepkg -s cannot install them)
AUR_DEPS = ["quickshell-git", "qt6-m3shapes-git", "python-materialyoucolor", "libcava"]
STATE = Path(os.environ.get("XDG_STATE_HOME") or Path.home() / ".local/state") / "sylphrena"
CACHE = Path(os.environ.get("XDG_CACHE_HOME") or Path.home() / ".cache") / "sylphrena-install"

# makepkg installs with "sudo -k", which throws away the password the installer already checked, so sudo
# asks again where nobody sees it and gives up after five minutes. This configuration keeps everything
# from the system's makepkg.conf and only makes it use plain sudo (the cached password, kept alive).
MAKEPKG_CONF = """source /etc/makepkg.conf
for _conf in /etc/makepkg.conf.d/*.conf; do [[ -f $_conf ]] && source "$_conf"; done
PACMAN_AUTH=(sudo)
"""


def build_jobs(mem_kib: int | None = None, cpus: int | None = None) -> int:
    """Parallel compile jobs that fit in memory: about 2 GiB each (optimised C++ such as Quickshell)."""
    if mem_kib is None:
        try:
            mem_kib = next(int(l.split()[1]) for l in Path("/proc/meminfo").read_text().splitlines() if l.startswith("MemTotal:"))
        except (OSError, StopIteration, ValueError):
            mem_kib = 0
    cpus = cpus or os.cpu_count() or 1
    if mem_kib <= 0:
        return cpus
    return max(1, min(cpus, mem_kib // (2 * 1024 * 1024)))


def limit_build_jobs() -> int:
    """Without this, a machine with little RAM (a VM) runs out of memory compiling and the compiler is killed.
    makepkg reads MAKEFLAGS; CMake projects built with Ninja read CMAKE_BUILD_PARALLEL_LEVEL. The user's own values win."""
    n = build_jobs()
    os.environ.setdefault("MAKEFLAGS", f"-j{n}")
    os.environ.setdefault("CMAKE_BUILD_PARALLEL_LEVEL", str(n))
    return n


def out_of_memory(lines) -> bool:
    """The compiler was killed (the usual sign of running out of memory while building)."""
    return any("killed" in l.lower() or "signal 9" in l.lower() for l in lines)

ES = {
    "Sylphrena installer": "Instalador de Sylphrena",
    "This computer": "Este equipo",
    "Required": "Necesario", "Recommended": "Recomendado", "Setup": "Configuración", "Login screen": "Pantalla de inicio de sesión",
    "Already done": "Ya hecho",
    "Nothing to do: everything is already in place.": "Nada que hacer: todo está ya en su sitio.",
    "Administrator password: asked once": "Contraseña de administrador: se pide una vez",
    "Type the number of an item to switch it on or off, Enter to continue, q to quit": "Escribe el número de un elemento para activarlo o desactivarlo, Intro para continuar, q para salir",
    "Nothing has been changed yet.": "Todavía no se ha cambiado nada.",
    "Continue?": "¿Continuar?",
    "Cancelled. Nothing was changed.": "Cancelado. No se ha cambiado nada.",
    "Run without a password prompt: not possible here": "Ejecutar sin pedir contraseña: no es posible aquí",
    "Done": "Hecho", "Failed": "Falló", "Skipped": "Omitido",
    "It did not finish: %s": "No terminó: %s",
    "Want more? Extensions (dashboard widgets, your Steam library, a VPN...) are installed from Things, in its Sylphrena section.":
        "¿Quieres más? Las extensiones (widgets del dashboard, tu biblioteca de Steam, una VPN...) se instalan desde Things, en su sección Sylphrena.",
    "The computer ran out of memory while compiling. Give it more RAM, or run the installer again with fewer builds at once: %s":
        "El equipo se quedó sin memoria al compilar. Dale más RAM o vuelve a lanzar el instalador compilando menos cosas a la vez: %s", "See the log: %s": "Mira el registro: %s",
    "Everything is ready.": "Todo está listo.",
    "Start it now with: sylph shell -d  (or log out and back in: Hyprland starts it)": "Arráncala ahora con: sylph shell -d  (o cierra sesión y vuelve a entrar: Hyprland la arranca)",
    "A copy of your Hyprland configuration is in %s": "Hay una copia de tu configuración de Hyprland en %s",
    "Do not run this as root: the AUR packages cannot be built as root. Run it as your user; it asks for sudo when it needs it.": "No lo ejecutes como root: los paquetes del AUR no se pueden construir como root. Ejecútalo con tu usuario; pide sudo cuando lo necesita.",
    "This installer is for Arch Linux and its derivatives.": "Este instalador es para Arch Linux y derivados.",
    "sudo does not work for this user: it is needed to install packages.": "sudo no funciona con este usuario: hace falta para instalar paquetes.",
    "Base tools": "Herramientas base", "to build packages from the AUR and run this installer": "para construir paquetes del AUR y ejecutar este instalador",
    "Hyprland": "Hyprland", "the compositor Sylphrena runs on": "el compositor sobre el que corre Sylphrena",
    "AUR helper (yay)": "Ayudante del AUR (yay)", "to install packages that are only in the AUR": "para instalar paquetes que solo están en el AUR",
    "Libraries from the AUR": "Librerías del AUR", "Quickshell (git version), the Material shapes, the colour library and the audio visualiser the shell is built on": "Quickshell (versión git), las formas Material, la librería de color y el visualizador de audio sobre los que se construye la shell",
    "Remove the stable Quickshell": "Quitar el Quickshell estable", "it conflicts with the git version the shell needs": "choca con la versión git que necesita la shell",
    "sylphrena-cli": "sylphrena-cli", "the sylph command (shell, themes, wallpapers, screenshots)": "el comando sylph (shell, temas, fondos, capturas)",
    "Seeker": "Seeker", "the file manager of Sylphrena": "el explorador de archivos de Sylphrena",
    "Things": "Things", "the package manager and extension manager": "el gestor de paquetes y de extensiones",
    "Sylphrena shell": "Shell de Sylphrena", "the shell itself, with its icons, GTK theme, fonts and tools": "la shell, con sus iconos, tema GTK, fuentes y herramientas",
    "Zen browser": "Navegador Zen",
    "a Firefox-based web browser that suits Sylphrena": "un navegador web basado en Firefox que encaja con Sylphrena",
    "a Firefox-based web browser that suits Sylphrena; not selected because you already have a browser":
        "un navegador web basado en Firefox que encaja con Sylphrena; no viene marcado porque ya tienes un navegador",
    "a new version: %s → %s": "una versión nueva: %s → %s",
    "Sylphrena is up to date.": "Sylphrena está al día.",
    "Clock font (Rubik)": "Fuente del reloj (Rubik)", "the font of the clock and the workspaces": "la fuente del reloj y de los escritorios",
    "Screen recorder": "Grabador de pantalla", "so that sylph record works": "para que funcione sylph record",
    "External monitor brightness (ddcutil)": "Brillo del monitor externo (ddcutil)", "this computer has no built-in screen, so its monitor is controlled over DDC/CI": "este equipo no tiene pantalla integrada, así que su monitor se controla por DDC/CI",
    "lets the brightness slider reach an external monitor over DDC/CI": "deja que el control de brillo llegue a un monitor externo por DDC/CI",
    "Hook Sylphrena into Hyprland": "Enganchar Sylphrena a Hyprland", "starts the shell with the session and loads its shortcuts and rules; your configuration is only added to, and copied first": "arranca la shell con la sesión y carga sus atajos y reglas; a tu configuración solo se le añade, y se copia antes",
    "First-run settings": "Ajustes del primer arranque", "the recommended settings, one activity with its wallpaper, and kitty connected to the colours": "los ajustes recomendados, una actividad con su fondo y kitty conectado a los colores",
    "Sylphrena login screen": "Pantalla de inicio de sesión de Sylphrena", "greetd with the Material You greeter; it replaces %s": "greetd con el greeter Material You; sustituye a %s",
    "greetd with the Material You greeter": "greetd con el greeter Material You",
    "asks for the password": "pide contraseña", "no password": "sin contraseña",
    "Hyprland needs to be installed first: it will be added.": "Primero hace falta Hyprland: se añadirá.",
    "yes": "sí", "no": "no",
    "A Material You shell for Hyprland": "Una shell Material You para Hyprland",
    "This is what Sylphrena needs on this computer. Nothing is changed until you press Enter.": "Esto es lo que Sylphrena necesita en este equipo. No se cambia nada hasta que pulses Intro.",
    "↑↓ move   space switch on or off   enter install   q quit": "↑↓ moverse   espacio activar o desactivar   intro instalar   q salir",
    "%d of %d selected": "%d de %d seleccionados", "required": "necesario",
    "It will ask for your administrator password once.": "Pedirá tu contraseña de administrador una vez.",
    "No password needed.": "No hace falta contraseña.",
    "Installing": "Instalando", "Everything is ready": "Todo está listo", "Something did not go as planned": "Algo no ha salido como se esperaba",
    "Restart the computer to start using Sylphrena": "Reinicia el equipo para empezar a usar Sylphrena",
    "Your Hyprland configuration was copied to": "Tu configuración de Hyprland se copió en", "Details of every step": "Detalle de cada paso",
    "Welcome to Sylphrena.": "Bienvenido a Sylphrena.",
    "The installer will open the welcome guide the first time the shell starts.": "La primera vez que arranque la shell se abrirá la guía de bienvenida.",
    "(dry run: nothing was changed)": "(simulación: no se ha cambiado nada)",
    "Last lines of the output:": "Últimas líneas de la salida:",
    "Nothing is installed yet.": "Todavía no hay nada instalado.",
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
    versions: dict[str, str] = field(default_factory=dict)  # our packages that are installed → their version
    releases: dict[str, str] = field(default_factory=dict)  # our repositories → the tag of their latest release
    browser: str | None = None                              # a web browser that is already there (then Zen is not preselected)

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


class _NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, *args, **kwargs):
        return None


def latest_release(repo: str) -> str | None:
    """The tag of the latest release of one of our repositories (what the installer and the updates install).
    github.com/<repo>/releases/latest redirects to …/releases/tag/<tag>: the web page, unlike the API, is not limited
    to 60 requests an hour without an account (the shell asks every few minutes)."""
    req = urllib.request.Request(f"https://github.com/iMacnucintosh/{repo}/releases/latest", method="HEAD",
                                 headers={"User-Agent": "sylphrena-installer"})
    try:
        urllib.request.build_opener(_NoRedirect).open(req, timeout=8)
    except urllib.error.HTTPError as e:
        location = e.headers.get("Location", "") if e.code in (301, 302, 303, 307, 308) else ""
        return location.rsplit("/tag/", 1)[1] if "/tag/" in location else None
    except (OSError, urllib.error.URLError):
        return None
    return None


def installed_version(pkg: str) -> str | None:
    code, out = sh(["pacman", "-Q", pkg])
    return out.split()[1] if code == 0 and len(out.split()) > 1 else None


def version_tuple(version: str | None) -> tuple[int, int, int] | None:
    """0.4.0.r12.gabc-1 (a -git package) or v0.5.0 (a tag) → (0, 4, 0)."""
    m = re.match(r"v?(\d+)\.(\d+)\.(\d+)", version or "")
    return tuple(int(x) for x in m.groups()) if m else None


def behind(installed: str | None, tag: str | None) -> bool:
    """True when the release is newer than what is installed (a build from main after that release is not behind)."""
    have, latest = version_tuple(installed), version_tuple(tag)
    if installed and latest and not have:
        return True                      # numbered the old way (r32.9d7e99a, by commit): older than any release
    return bool(have and latest and have < latest)


def check_status(script: str) -> str:
    """What a setup script (--check: it changes nothing) says it would do: needed | already | seen | kept | ..."""
    path = installed_shell_dir() / "scripts" / script
    code, out = sh([sys.executable, str(path), "--check"], timeout=60)
    try:
        return json.loads(out)["status"]
    except (ValueError, KeyError, TypeError):
        return "needed" if code else "unknown"


def scan(from_main: bool = False) -> Facts:
    f = Facts()
    f.arch = Path("/etc/arch-release").exists() or shutil.which("pacman") is not None
    f.is_root = os.geteuid() == 0
    f.helper = next((h for h in ("yay", "paru") if shutil.which(h)), None)
    names = ["git", "base-devel", "hyprland", "quickshell", "quickshell-git", "greetd", "ddcutil", "gpu-screen-recorder", "ttf-rubik-vf",
             "rsync", "zen-browser-bin", *AUR_DEPS, *(p for p, _ in PACKAGES)]
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
    f.browser = next((b for b in BROWSERS if shutil.which(b)), None)
    f.versions = {p: v for p, _ in PACKAGES if (v := installed_version(p))}
    # Friends get what has been released, not every commit (--main builds the latest commit instead)
    f.releases = {} if from_main else {repo: tag for _, repo in PACKAGES if (tag := latest_release(repo))}
    return f


# ── The plan ─────────────────────────────────────────────────────────────────────────────────────

@dataclass
class Step:
    kind: str            # pacman | aur | build | user | root | write-root
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
    why_args: tuple = ()


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
    need_helper = f.helper is None and bool(need_aur or own_from_aur or not f.have("ttf-rubik-vf")
                                            or (f.browser is None and not f.have("zen-browser-bin")))
    add("aur-helper", "Required", "AUR helper (yay)", "to install packages that are only in the AUR", True, todo=need_helper,
        required=True, steps=[Step("build", ["yay-bin", "https://aur.archlinux.org/yay-bin.git"])])
    conflict = f.have("quickshell") and not f.have("quickshell-git") and "quickshell-git" in need_aur
    if conflict:
        add("quickshell-conflict", "Required", "Remove the stable Quickshell", "it conflicts with the git version the shell needs",
            True, required=True, steps=[Step("root", ["pacman", "-Rdd", "--noconfirm", "quickshell"])])
    add("aur-deps", "Required", "Libraries from the AUR",
        "Quickshell (git version), the Material shapes, the colour library and the audio visualiser the shell is built on", True, todo=bool(need_aur),
        required=True, steps=[Step("aur", need_aur)] if need_aur else [])
    labels = {"sylphrena-cli-git": ("sylphrena-cli", "the sylph command (shell, themes, wallpapers, screenshots)"),
              "seeker-git": ("Seeker", "the file manager of Sylphrena"), "things-git": ("Things", "the package manager and extension manager"),
              "sylphrena-shell-git": ("Sylphrena shell", "the shell itself, with its icons, GTK theme, fonts and tools")}
    for pkg, repo in PACKAGES:
        title, why = labels[pkg]
        tag = f.releases.get(repo, "")
        step = Step("aur", [pkg]) if pkg in f.in_aur else Step("build", [pkg, f"{GITHUB}/{repo}", "packaging", tag])
        it = add(pkg, "Required", title, why, True, todo=not f.have(pkg) or behind(f.versions.get(pkg), tag), required=True,
                 steps=[step])
        if f.have(pkg) and it.todo:
            it.why, it.why_args = "a new version: %s → %s", (f.versions[pkg].split(".r")[0].split("-")[0], tag.lstrip("v"))
    add("rubik", "Recommended", "Clock font (Rubik)", "the font of the clock and the workspaces", True, todo=not f.have("ttf-rubik-vf"),
        steps=[Step("aur", ["ttf-rubik-vf"])])
    add("recorder", "Recommended", "Screen recorder", "so that sylph record works", True, todo=not f.have("gpu-screen-recorder"),
        steps=[Step("pacman", ["gpu-screen-recorder"])])
    add("zen", "Recommended", "Zen browser",
        "a Firefox-based web browser that suits Sylphrena; not selected because you already have a browser" if f.browser
        else "a Firefox-based web browser that suits Sylphrena",
        True, todo=not f.have("zen-browser-bin") and f.browser != "zen-browser", default=f.browser is None,
        steps=[Step("aur", ["zen-browser-bin"])])
    ddc_steps = [Step("pacman", ["ddcutil"]), Step("write-root", ["/etc/modules-load.d/i2c-dev.conf", "i2c-dev\n"]),
                 Step("root", ["modprobe", "i2c-dev"], ) ]
    add("ddcutil", "Recommended", "External monitor brightness (ddcutil)",
        "this computer has no built-in screen, so its monitor is controlled over DDC/CI" if not f.backlight
        else "lets the brightness slider reach an external monitor over DDC/CI",
        True, todo=not f.have("ddcutil"), default=not f.backlight, steps=ddc_steps)
    # The setup steps run after the packages, so they use the installed shell even though, while planning, it is
    # not there yet (otherwise hyprland.lua and the settings would point at the clone, which may be deleted)
    shell_dir = INSTALLED_SHELL if any(i.id == "sylphrena-shell-git" for i in items) else installed_shell_dir()
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
        # install-system.sh (10-greeter.sh) also makes greetd the display manager: it disables the one in use
        steps += [Step("root", [str(shell_dir / "scripts" / "install-system.sh")])]
        add("login-screen", "Login screen", "Sylphrena login screen",
            "greetd with the Material You greeter; it replaces %s" if dm else "greetd with the Material You greeter",
            True, todo=not f.greeter_installed, steps=steps)
    return items


# ── Doing it ─────────────────────────────────────────────────────────────────────────────────────

class Runner:
    """Runs the steps; `dry` only prints them. Quiet by default (a spinner and the log); `verbose` shows the output."""

    def __init__(self, dry: bool, helper: str | None, log: Path | None, verbose: bool = False):
        self.dry, self.helper, self.log, self.verbose = dry, helper or "yay", log, verbose
        # Run by the shell's updates (no terminal): every sudo asks the password the shell keeps in memory through
        # SUDO_ASKPASS (scripts/run-system-update.sh). From a terminal: sudo's own prompt, once, kept alive.
        self.askpass = bool(os.environ.get("SUDO_ASKPASS")) and not sys.stdin.isatty()
        self.sudo = ["sudo", "-A"] if self.askpass else ["sudo"]
        self._sudo_alive = False
        self.spinner: ui.Spinner | None = None
        self.recent: deque[str] = deque(maxlen=60)

    def _to_log(self, text: str) -> None:
        if self.log:
            with self.log.open("a") as fh:
                fh.write(text if text.endswith("\n") else text + "\n")

    def say(self, text: str) -> None:
        print(text, flush=True)
        self._to_log(text)

    def run(self, cmd: list[str], cwd: Path | None = None, input_text: str | None = None, env: dict | None = None) -> bool:
        line = "$ " + " ".join(cmd)
        self._to_log(line)
        if self.dry:
            print("   " + ui.style(line, dim=True))
            return True
        if self.spinner:
            self.spinner.detail = line
        try:
            p = subprocess.Popen(cmd, cwd=cwd, env={**os.environ, **env} if env else None,
                                 stdin=subprocess.PIPE if input_text is not None else subprocess.DEVNULL,
                                 stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        except OSError as e:
            self._to_log(str(e))
            self.recent.append(str(e))
            return False
        if input_text is not None:
            p.stdin.write(input_text)
            p.stdin.close()
        for out in p.stdout:
            self._to_log(out)
            self.recent.append(out)
            if self.verbose:
                sys.stdout.write("   │ " + out)
            elif self.spinner and out.strip():
                self.spinner.detail = out.strip()
        return p.wait() == 0

    def remove_tree(self, path: Path) -> bool:
        """Remove an earlier build, even with folders it may not read or write; True if it is gone. It never raises:
        whatever stops it goes to the log, and the caller builds somewhere else."""
        if not path.exists():
            return True

        def force(_func, p, _exc):
            try:
                os.chmod(os.path.dirname(p), 0o700)
                if os.path.isdir(p) and not os.path.islink(p):
                    os.chmod(p, 0o700)
                    shutil.rmtree(p, onexc=force)
                else:
                    os.unlink(p)
            except OSError as e:
                self._to_log(f"could not remove {p}: {e}")

        try:
            shutil.rmtree(path, onexc=force)
        except Exception as e:  # noqa: BLE001 — a leftover folder must not stop the installer
            self._to_log(f"could not remove {path}: {e}")
        return not path.exists()

    def keep_sudo(self) -> bool:
        if self.dry:
            return True
        if self.askpass:
            return subprocess.run([*self.sudo, "-v"], stdin=subprocess.DEVNULL).returncode == 0
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
            return not a or self.run([*self.sudo, "pacman", "-S", "--needed", "--noconfirm", *a])
        if k == "aur":
            return not a or self.run([self.helper, "-S", "--needed", "--noconfirm", *(["--sudoflags=-A"] if self.askpass else []), *a])
        if k == "build":
            name, url = a[0], a[1]
            sub = a[2] if len(a) > 2 else "."
            ref = a[3] if len(a) > 3 else ""             # a release tag: its PKGBUILD, and its code (SYLPHRENA_REF)
            work = CACHE / name
            conf = CACHE / "makepkg.conf"
            if not self.dry:
                CACHE.mkdir(parents=True, exist_ok=True)
                conf.write_text(MAKEPKG_CONF.replace("PACMAN_AUTH=(sudo)", "PACMAN_AUTH=(sudo -A)") if self.askpass else MAKEPKG_CONF)
                if not self.remove_tree(work):
                    # Something in an earlier build could not be removed: build somewhere new instead of failing
                    work = CACHE / f"{name}-{int(time.time())}"
            clone = ["git", "clone", "--depth", "1", *(["--branch", ref] if ref else []), url, str(work)]
            return self.run(clone) and \
                self.run(["makepkg", "--config", str(conf), "-si", "--noconfirm", "--needed"], cwd=(work / sub),
                         env={"SYLPHRENA_REF": ref} if ref else None)
        if k == "user":
            return self.run(a)
        if k == "root":
            return self.run([*self.sudo, *a])
        if k == "write-root":
            path, content = a
            return self.run([*self.sudo, "tee", path], input_text=content)
        raise ValueError(k)


def execute(items: list[Item], r: Runner) -> list[tuple[Item, str, int]]:
    """[(item, "done" | "failed" | "skipped", seconds)]. A required item that fails stops the rest."""
    results: list[tuple[Item, str, int]] = []
    todo = [i for i in items if i.on and i.todo]
    for it in items:
        if not it.on or not it.todo:
            results.append((it, "skipped", 0))
            continue
        n = len([x for x in results if x[1] != "skipped"]) + 1
        title = f"[{n}/{len(todo)}] {tr(it.title)}"
        r.recent.clear()
        r._to_log(f"==> {it.title}")
        started = time.time()
        if r.dry or r.verbose:
            print(f"\n  {ui.rgb(ui.LAVENDER, '◆', True)} {ui.style(title, bold=True)}")
            ok = all(r.step(s) for s in it.steps)
        else:
            with ui.Spinner(title) as sp:
                r.spinner = sp
                ok = all(r.step(s) for s in it.steps)
                r.spinner = None
        secs = int(time.time() - started)
        results.append((it, "done" if ok else "failed", secs))
        if not (r.dry or r.verbose):
            took = ui.style(f"{secs}s", dim=True)
            print(("  " + ui.ok(f"{tr(it.title)}  {took}")) if ok else ("  " + ui.bad(f"{tr(it.title)}  {took}")), flush=True)
        if not ok:
            if not (r.dry or r.verbose) and r.recent:
                print("\n  " + ui.style(tr("Last lines of the output:"), dim=True))
                print(ui.tail(r.recent))
            if out_of_memory(r.recent):
                hint = tr("The computer ran out of memory while compiling. Give it more RAM, or run the installer again with fewer builds at once: %s")
                print("\n  " + hint % "MAKEFLAGS=-j1 CMAKE_BUILD_PARALLEL_LEVEL=1 ./install.sh")
            if it.required:
                print("\n  " + ui.bad(tr("It did not finish: %s") % tr(it.title)))
                break
    return results


# ── The conversation ─────────────────────────────────────────────────────────────────────────────

GROUPS = ["Required", "Recommended", "Setup", "Login screen"]


def version() -> str:
    code, out = sh(["git", "-C", str(ROOT), "describe", "--tags", "--match", "v0.*"])
    return out.split("-")[0] if code == 0 and out else ""


def describe(it: Item, f: Facts) -> str:
    if not it.todo:
        return tr("Already done")
    why = tr(it.why)
    if it.why_args:
        return why % it.why_args
    return why % (f.display_manager or "") if "%s" in why else why


def lock_text(it: Item) -> str:
    if not it.todo:
        return ""
    return tr("It will ask for your administrator password once.") if it.root else tr("No password needed.")


def grouped(items: list[Item]) -> list[tuple[str, list[Item]]]:
    return [(tr(g), [i for i in items if i.group == g]) for g in GROUPS if any(i.group == g for i in items)]


def show_plain(items: list[Item], f: Facts) -> None:
    for g in GROUPS:
        rows = [(i, it) for i, it in enumerate(items, 1) if it.group == g]
        if not rows:
            continue
        ui.rule(tr(g))
        for i, it in rows:
            mark = ui.rgb(ui.GREEN, "✔") if not it.todo else (ui.rgb(ui.LAVENDER, "◉") if it.on else ui.style("○", dim=True))
            head = f"    {mark} {i:>2}. "
            print(ui.wrap(f"{tr(it.title)}  {ui.style('— ' + describe(it, f), dim=True)}", 11, head))
    print()


def conversation(items: list[Item], f: Facts, yes: bool) -> bool:
    todo = lambda: [i for i in items if i.todo and i.on]  # noqa: E731
    ui.banner(tr("A Material You shell for Hyprland"), version())
    if not any(i.todo for i in items):
        show_plain(items, f)
        print("  " + tr("Nothing to do: everything is already in place."))
        return False
    print(ui.wrap(tr("This is what Sylphrena needs on this computer. Nothing is changed until you press Enter."), 2, "  "))
    if yes or not sys.stdin.isatty():
        show_plain(items, f)
        return True
    if ui.can_interact():
        groups = grouped(items)
        status = lambda flat: tr("%d of %d selected") % (len([i for i in flat if i.todo and i.on]), len([i for i in flat if i.todo]))  # noqa: E731
        return ui.checklist(groups, lambda it: describe(it, f), lock_text, tr("↑↓ move   space switch on or off   enter install   q quit"), status,
                            label=lambda it: tr(it.title), required_text=tr("required"))
    # A terminal without cursor control: switch items by number
    while True:
        show_plain(items, f)
        print("  " + tr("Nothing has been changed yet."))
        answer = input("  " + tr("Type the number of an item to switch it on or off, Enter to continue, q to quit") + ": ").strip().lower()
        if answer in ("q", "quit", "n", "no"):
            return False
        if answer == "":
            return True
        for token in answer.replace(",", " ").split():
            if token.isdigit() and 1 <= int(token) <= len(items):
                it = items[int(token) - 1]
                if it.todo and not it.required:
                    it.on = not it.on


def parse(argv: list[str]) -> dict:
    opts = {"demo": False, "yes": False, "dry": False, "list": False, "only": None, "skip": set(), "login": True, "verbose": False,
            "main": False, "update": False}
    it = iter(argv)
    for a in it:
        if a in ("--yes", "-y"):
            opts["yes"] = True
        elif a == "--dry-run":
            opts["dry"] = True
        elif a == "--list":
            opts["list"] = True
        elif a == "--demo":
            opts["demo"] = True
            opts["dry"] = True
        elif a == "--verbose":
            opts["verbose"] = True
        elif a == "--main":
            opts["main"] = True
        elif a == "--update":
            opts["update"] = True
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


def finish(results: list[tuple[Item, str, int]], dry: bool, log: Path) -> int:
    failed = [it for it, s, _ in results if s == "failed"]
    done = [it for it, s, _ in results if s == "done"]
    ui.rule(tr("Something did not go as planned") if failed else tr("Everything is ready"))
    for it, s, secs in results:
        if s != "skipped":
            print("  " + (ui.ok if s == "done" else ui.bad)(tr(it.title)))
    print()
    if failed:
        print("  " + tr("See the log: %s") % log)
        return 1
    if dry:
        print("  " + ui.style(tr("(dry run: nothing was changed)"), dim=True))
        return 0
    print("  " + ui.rgb(ui.LAVENDER, tr("Welcome to Sylphrena."), True))
    print(ui.wrap(tr("The installer will open the welcome guide the first time the shell starts."), 2, "  "))
    print()
    print(ui.wrap(tr("Want more? Extensions (dashboard widgets, your Steam library, a VPN...) are installed from Things, in its Sylphrena section."), 2, "  "))
    print()
    # A fresh start, not a shell launched by hand: the login screen, the Hyprland hook and the environment
    # (Qt theme…) only apply cleanly to a new session
    print("  " + ui.style(tr("Restart the computer to start using Sylphrena"), bold=True) + ":  " + ui.rgb(ui.ROSE, "sudo reboot"))
    backup = Path(os.environ.get("XDG_CONFIG_HOME") or Path.home() / ".config") / "hypr" / "hyprland.lua.sylphrena-backup"
    if backup.exists():
        print("\n  " + ui.style(f"{tr('Your Hyprland configuration was copied to')} {backup}", dim=True))
    print("  " + ui.style(f"{tr('Details of every step')}: {log}", dim=True) + "\n")
    return 0


def main(argv: list[str] | None = None) -> int:
    opts = parse(sys.argv[1:] if argv is None else argv)
    f = scan(from_main=opts["main"])
    if opts["demo"]:
        # What a bare Arch looks like (nothing of ours, no AUR helper, a desktop, another display manager); changes nothing
        f = Facts(arch=True, helper=None, installed={"git"}, in_aur=set(AUR_DEPS) | {"ttf-rubik-vf"}, backlight=False,
                  display_manager="sddm")
    if f.is_root:
        print(tr("Do not run this as root: the AUR packages cannot be built as root. Run it as your user; it asks for sudo when it needs it."), file=sys.stderr)
        return 1
    if not f.arch:
        print(tr("This installer is for Arch Linux and its derivatives."), file=sys.stderr)
        return 1
    items = build_plan(f, login_screen=opts["login"])
    if opts["update"]:
        # Updating Sylphrena: new versions of its packages and whatever its setup needs now; nothing new is offered
        for it in items:
            if it.group == "Recommended":
                it.on = False
        if not any(i.todo and i.on for i in items):
            print("\n  " + tr("Sylphrena is up to date.") + "\n")
            return 0
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
            print("\n  " + tr("Cancelled. Nothing was changed.") + "\n")
        return 0
    STATE.mkdir(parents=True, exist_ok=True)
    log = STATE / "install.log"
    r = Runner(opts["dry"], f.helper, log if not opts["dry"] else None, verbose=opts["verbose"])
    print()
    if any(i.root and i.on and i.todo for i in items) and not r.keep_sudo():
        print(tr("sudo does not work for this user: it is needed to install packages."), file=sys.stderr)
        return 1
    r._to_log(f"parallel build jobs: {limit_build_jobs()}")
    ui.rule(tr("Installing"))
    try:
        results = execute(items, r)
    finally:
        r.stop_sudo()
    return finish(results, opts["dry"], log)


if __name__ == "__main__":
    sys.exit(main())
