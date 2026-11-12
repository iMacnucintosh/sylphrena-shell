"""installer.py: what it plans for different systems, and that --dry-run changes nothing."""
import io
import sys
import unittest
from contextlib import redirect_stdout
from pathlib import Path

from helpers import load

inst = load("installer")


def bare() -> "inst.Facts":
    """Arch with nothing of ours: no AUR helper, no Hyprland, a desktop (no built-in screen), another display manager."""
    return inst.Facts(arch=True, helper=None, installed={"git"}, in_aur=set(inst.AUR_DEPS) | {"ttf-rubik-vf"}, backlight=False,
                      display_manager="sddm")


def ids(items, **where):
    return [i.id for i in items if all(getattr(i, k) == v for k, v in where.items())]


class Plan(unittest.TestCase):
    def test_a_bare_system_needs_everything_in_order(self):
        items = inst.build_plan(bare())
        order = ids(items)
        self.assertLess(order.index("aur-helper"), order.index("aur-deps"))
        self.assertLess(order.index("aur-deps"), order.index("sylphrena-cli-git"))
        pkgs = [i for i in order if i.endswith("-git")]
        self.assertEqual(pkgs, ["sylphrena-cli-git", "seeker-git", "things-git", "sylphrena-shell-git"])  # the shell last
        for i in items:
            if i.group == "Required":
                self.assertTrue(i.required)
                self.assertTrue(i.on, i.id)

    def test_nothing_is_required_twice(self):
        f = bare()
        f.helper = "yay"
        f.installed |= {"git", "base-devel", "hyprland", *inst.AUR_DEPS}
        items = inst.build_plan(f)
        todo = {i.id for i in items if i.todo and i.group == "Required"}
        self.assertEqual(todo, {"sylphrena-cli-git", "seeker-git", "things-git", "sylphrena-shell-git"})

    def test_our_packages_come_from_the_aur_when_they_are_there_and_from_github_when_not(self):
        f = bare()
        f.in_aur.add("seeker-git")
        steps = {i.id: i.steps[0] for i in inst.build_plan(f) if i.id.endswith("-git")}
        self.assertEqual(steps["seeker-git"].kind, "aur")
        self.assertEqual(steps["things-git"].kind, "build")
        self.assertTrue(steps["things-git"].args[1].endswith("/things"))

    def test_the_stable_quickshell_is_removed_first(self):
        f = bare()
        f.installed |= {"quickshell"}
        order = ids(inst.build_plan(f))
        self.assertIn("quickshell-conflict", order)
        self.assertLess(order.index("quickshell-conflict"), order.index("aur-deps"))
        f.installed |= {"quickshell-git"}
        self.assertNotIn("quickshell-conflict", ids(inst.build_plan(f)))

    def test_ddcutil_is_on_by_default_only_without_a_built_in_screen(self):
        desktop = {i.id: i for i in inst.build_plan(bare())}
        self.assertTrue(desktop["ddcutil"].on)
        laptop = bare()
        laptop.backlight = True
        self.assertFalse({i.id: i for i in inst.build_plan(laptop)}["ddcutil"].on)

    def test_the_login_screen_is_one_root_script_and_can_be_left_out(self):
        items = {i.id: i for i in inst.build_plan(bare())}
        login = items["login-screen"]
        self.assertTrue(login.on and login.root)
        self.assertIn("sddm", inst.describe(login, bare()))  # it says which display manager it replaces
        scripts = [s.args[0] for s in login.steps if s.kind == "root"]
        self.assertTrue(any(a.endswith("install-system.sh") for a in scripts))
        self.assertNotIn("login-screen", ids(inst.build_plan(bare(), login_screen=False)))

    def test_the_login_screen_script_does_what_the_installer_relies_on(self):
        script = (Path(__file__).resolve().parent.parent / "scripts/system/10-greeter.sh").read_text()
        # greetd becomes the display manager (the one in use is disabled, nothing is restarted)
        self.assertIn("systemctl enable -f greetd.service", script)
        self.assertIn('systemctl disable "$current.service"', script)
        self.assertNotIn("systemctl restart", script)
        # the logind drop-ins are installed and only the legacy names are removed
        self.assertIn("/etc/systemd/logind.conf.d/sylphrena-greeter.conf", script)
        rm = [l for l in script.splitlines() if "rm -f" in l or l.strip().startswith("/etc/systemd") and "caelestia" in l]
        self.assertTrue(rm and all("sylphrena-" not in l for l in rm if "rm -f" in l))
        import subprocess
        self.assertEqual(subprocess.run(["bash", "-n", str(Path(__file__).resolve().parent.parent / "scripts/system/10-greeter.sh")]).returncode, 0)

    def test_extensions_are_optional_and_off(self):
        ext = {i.id: i for i in inst.build_plan(bare())}["extensions"]
        self.assertFalse(ext.on)
        self.assertEqual(ext.group, "Optional")

    def test_what_is_done_is_not_offered(self):
        f = bare()
        f.hyprland_needed = False
        f.first_run_needed = False
        f.greeter_installed = True
        items = {i.id: i for i in inst.build_plan(f)}
        for i in ("hyprland-config", "first-run", "login-screen"):
            self.assertFalse(items[i].todo)
            self.assertFalse(items[i].on)


class Run(unittest.TestCase):
    def test_dry_run_prints_the_commands_and_runs_nothing(self):
        r = inst.Runner(dry=True, helper="yay", log=None)
        items = inst.build_plan(bare())
        calls = []
        r.run = lambda cmd, **k: calls.append(cmd) or True      # even the printing must not reach a subprocess
        with redirect_stdout(io.StringIO()):
            results = inst.execute(items, r)
        self.assertTrue(calls)
        self.assertTrue(all(s in ("done", "skipped") for _, s, _ in results))
        flat = [" ".join(c) for c in calls]
        self.assertTrue(any(c.startswith("sudo pacman -S --needed --noconfirm") for c in flat))
        self.assertTrue(any(c.startswith("yay -S") for c in flat))

    def test_a_required_failure_stops_the_rest(self):
        r = inst.Runner(dry=True, helper="yay", log=None)
        r.run = lambda cmd, **k: False
        with redirect_stdout(io.StringIO()):
            results = inst.execute(inst.build_plan(bare()), r)
        self.assertEqual([s for _, s, _ in results if s == "failed"], ["failed"])
        self.assertLess(len(results), len(inst.build_plan(bare())))

    def test_an_optional_failure_does_not_stop_the_rest(self):
        f = bare()
        f.helper = "yay"
        f.installed |= {"base-devel", "hyprland", *inst.AUR_DEPS, *(p for p, _ in inst.PACKAGES)}
        r = inst.Runner(dry=True, helper="yay", log=None)
        r.run = lambda cmd, **k: False
        with redirect_stdout(io.StringIO()):
            results = inst.execute(inst.build_plan(f), r)
        self.assertGreater(len([1 for _, s, _ in results if s == "failed"]), 1)


class Options(unittest.TestCase):
    def test_parse(self):
        o = inst.parse(["--yes", "--dry-run", "--skip", "ddcutil,rubik", "--no-login-screen"])
        self.assertTrue(o["yes"] and o["dry"] and not o["login"])
        self.assertEqual(o["skip"], {"ddcutil", "rubik"})

    def test_refuses_what_it_does_not_know(self):
        with self.assertRaises(SystemExit):
            inst.parse(["--format-disk"])



class Look(unittest.TestCase):
    def test_plain_output_when_there_is_no_colour_terminal(self):
        ui = sys.modules["installer_ui"]
        out = io.StringIO()
        with redirect_stdout(out):
            ui.banner("A Material You shell for Hyprland", "v9.9.9")
        text = out.getvalue()
        self.assertNotIn("\x1b", text)            # stdout is not a terminal here
        self.assertIn("╔═╗", text)
        self.assertIn("A Material You shell for Hyprland", text)
        self.assertIn("v9.9.9", text)
        self.assertEqual(len([l for l in text.splitlines() if "╔" in l or "╚" in l or "╠" in l]), 3)

    def test_a_failing_command_shows_its_last_lines_and_stops_a_required_item(self):
        r = inst.Runner(dry=False, helper="yay", log=None)
        item = inst.Item("x", "Required", "Something", "why", False, required=True,
                         steps=[inst.Step("user", ["sh", "-c", "echo building; echo it broke >&2; exit 3"])])
        out = io.StringIO()
        with redirect_stdout(out):
            results = inst.execute([item], r)
        self.assertEqual(results[0][1], "failed")
        self.assertIn("it broke", out.getvalue())
        self.assertIn("Something", out.getvalue())

    def test_a_working_command_is_quiet(self):
        r = inst.Runner(dry=False, helper="yay", log=None)
        item = inst.Item("x", "Setup", "Something", "why", False, steps=[inst.Step("user", ["sh", "-c", "echo secret-output"])])
        out = io.StringIO()
        with redirect_stdout(out):
            results = inst.execute([item], r)
        self.assertEqual(results[0][1], "done")
        self.assertNotIn("secret-output", out.getvalue())   # it goes to the log, not the screen
        r2 = inst.Runner(dry=False, helper="yay", log=None, verbose=True)
        out2 = io.StringIO()
        with redirect_stdout(out2):
            inst.execute([item], r2)
        self.assertIn("secret-output", out2.getvalue())

    def test_the_demo_option_is_a_dry_run(self):
        o = inst.parse(["--demo"])
        self.assertTrue(o["demo"] and o["dry"])

    def test_the_description_box_has_the_same_width_on_every_line(self):
        ui = sys.modules["installer_ui"]
        lines = ui.box("Title", ["short", "a longer line of explanation"], 60)
        self.assertEqual(len({ui.visible(l) for l in lines}), 1)
        self.assertEqual(ui.visible(lines[0]), 60)
        self.assertTrue(lines[0].lstrip("\x1b[0-9;m").startswith("╭") or "╭" in lines[0])

    def test_title_words_capitalises_every_word_and_leaves_the_rest(self):
        ui = sys.modules["installer_ui"]
        self.assertEqual(ui.title_words("lets the brightness reach a monitor over DDC/CI"),
                         "Lets The Brightness Reach A Monitor Over DDC/CI")
        self.assertEqual(ui.title_words("para que funcione sylph record"), "Para Que Funcione Sylph Record")


class Translations(unittest.TestCase):
    def test_every_string_the_installer_shows_has_its_spanish(self):
        import re

        src = (Path(__file__).resolve().parent.parent / "scripts/installer.py").read_text()
        wanted = set(re.findall(r'\btr\(\s*"((?:[^"\\]|\\.)*)"', src)) | set(inst.GROUPS)
        for f in (bare(), inst.Facts(arch=True, helper="yay", installed={"quickshell"}, backlight=True)):
            for it in inst.build_plan(f):
                wanted |= {it.title, it.why}
        self.assertEqual(sorted(w for w in wanted if w not in inst.ES), [])


if __name__ == "__main__":
    unittest.main()
