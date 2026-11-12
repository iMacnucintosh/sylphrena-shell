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

    def test_the_login_screen_replaces_the_display_manager_and_can_be_left_out(self):
        items = {i.id: i for i in inst.build_plan(bare())}
        login = items["login-screen"]
        self.assertTrue(login.on and login.root)
        cmds = [s.args for s in login.steps if s.kind == "root"]
        self.assertIn(["systemctl", "disable", "sddm.service"], cmds)
        self.assertIn(["systemctl", "enable", "-f", "greetd.service"], cmds)
        self.assertNotIn("login-screen", ids(inst.build_plan(bare(), login_screen=False)))

    def test_the_login_screen_does_not_disable_greetd_itself(self):
        f = bare()
        f.display_manager = "greetd"
        login = {i.id: i for i in inst.build_plan(f)}["login-screen"]
        self.assertFalse([s for s in login.steps if s.args[:2] == ["systemctl", "disable"]])

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
        self.assertTrue(all(s in ("done", "skipped") for _, s in results))
        flat = [" ".join(c) for c in calls]
        self.assertTrue(any(c.startswith("sudo pacman -S --needed --noconfirm") for c in flat))
        self.assertTrue(any(c.startswith("yay -S") for c in flat))

    def test_a_required_failure_stops_the_rest(self):
        r = inst.Runner(dry=True, helper="yay", log=None)
        r.run = lambda cmd, **k: False
        with redirect_stdout(io.StringIO()):
            results = inst.execute(inst.build_plan(bare()), r)
        self.assertEqual([s for _, s in results if s == "failed"], ["failed"])
        self.assertLess(len(results), len(inst.build_plan(bare())))

    def test_an_optional_failure_does_not_stop_the_rest(self):
        f = bare()
        f.helper = "yay"
        f.installed |= {"base-devel", "hyprland", *inst.AUR_DEPS, *(p for p, _ in inst.PACKAGES)}
        r = inst.Runner(dry=True, helper="yay", log=None)
        r.run = lambda cmd, **k: False
        with redirect_stdout(io.StringIO()):
            results = inst.execute(inst.build_plan(f), r)
        self.assertGreater(len([1 for _, s in results if s == "failed"]), 1)


class Options(unittest.TestCase):
    def test_parse(self):
        o = inst.parse(["--yes", "--dry-run", "--skip", "ddcutil,rubik", "--no-login-screen"])
        self.assertTrue(o["yes"] and o["dry"] and not o["login"])
        self.assertEqual(o["skip"], {"ddcutil", "rubik"})

    def test_refuses_what_it_does_not_know(self):
        with self.assertRaises(SystemExit):
            inst.parse(["--format-disk"])


if __name__ == "__main__":
    unittest.main()
