"""setup-hyprland.py in a sandboxed HOME: what it adds to hyprland.lua, and what it leaves alone."""
import json
import unittest
from pathlib import Path

from helpers import run_script, tmpdir

SCRIPT = "setup-hyprland.py"


def run(home: Path, *args: str, keyboard: str = "") -> dict:
    p = run_script(SCRIPT, list(args), home, {"SYLPHRENA_TEST_KEYBOARD": keyboard})
    return {**json.loads(p.stdout), "rc": p.returncode}


def conf(home: Path) -> Path:
    return home / ".config/hypr/hyprland.lua"


class Hyprland(unittest.TestCase):
    def test_adds_a_block_once_and_keeps_the_user_content(self):
        with tmpdir() as d:
            home = Path(d)
            conf(home).parent.mkdir(parents=True)
            conf(home).write_text('hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })\n')
            self.assertEqual(run(home, "--check")["status"], "needed")
            self.assertEqual(conf(home).read_text().count("sylphrena"), 0)  # --check writes nothing
            self.assertEqual(run(home)["status"], "done")
            text = conf(home).read_text()
            self.assertIn("hl.monitor(", text)
            self.assertEqual(text.count(">>> sylphrena"), 1)
            self.assertIn('hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")', text)
            self.assertIn("start-shell-with-tray-watcher.sh", text)
            for name in ("sylphrena-monitors", "sylphrena-input", "sylphrena-binds", "sylphrena-activity-rules", "sylphrena-animation"):
                self.assertIn(f'"{name}"', text)
            self.assertIn("pcall(require", text)
            self.assertEqual(Path(str(conf(home)) + ".sylphrena-backup").read_text().count("sylphrena"), 0)
            before = text
            self.assertEqual(run(home)["status"], "already")
            self.assertEqual(conf(home).read_text(), before)

    def test_does_not_repeat_what_the_file_already_does(self):
        with tmpdir() as d:
            home = Path(d)
            conf(home).parent.mkdir(parents=True)
            conf(home).write_text('hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")\n'
                                  'hl.on("hyprland.start", function() hl.exec_cmd("sylph shell -d") end)\n'
                                  'require("sylphrena-binds")\nrequire("sylphrena-monitors")\n')
            self.assertEqual(run(home, "--check")["notes"], ["the configuration already starts the shell"])
            self.assertEqual(run(home)["status"], "done")
            text = conf(home).read_text()
            self.assertEqual(text.count("QT_QPA_PLATFORMTHEME"), 1)
            self.assertEqual(text.count("sylph shell"), 1)
            self.assertEqual(text.count('"sylphrena-binds"'), 1)
            self.assertIn('"sylphrena-input"', text)

    def test_a_file_that_already_has_everything_is_not_touched(self):
        with tmpdir() as d:
            home = Path(d)
            conf(home).parent.mkdir(parents=True)
            text = ('hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")\nhl.exec_cmd("qs -c sylphrena")\n'
                    'hl.config({ misc = { disable_hyprland_logo = true } })\n'
                    + "".join(f'require("{n}")\n' for n in ("sylphrena-monitors", "sylphrena-input", "sylphrena-binds", "sylphrena-activity-rules", "sylphrena-animation")))
            conf(home).write_text(text)
            self.assertEqual(run(home)["status"], "already")
            self.assertEqual(conf(home).read_text(), text)
            self.assertFalse(Path(str(conf(home)) + ".sylphrena-backup").exists())

    def test_creates_the_file_when_there_is_none(self):
        with tmpdir() as d:
            home = Path(d)
            self.assertEqual(run(home)["status"], "done")
            self.assertIn(">>> sylphrena", conf(home).read_text())

    def test_a_result_that_is_not_valid_is_not_written(self):
        with tmpdir() as d:
            home = Path(d)
            conf(home).parent.mkdir(parents=True)
            conf(home).write_text("this is not lua (\n")
            r = run(home)
            if r["status"] == "failed":  # only when luac or Hyprland is there to tell
                self.assertEqual(conf(home).read_text(), "this is not lua (\n")
                self.assertEqual(r["rc"], 1)


if __name__ == "__main__":
    unittest.main()


class Keyboard(unittest.TestCase):
    def test_the_system_layout_replaces_hyprlands_default_us(self):
        with tmpdir() as d:
            home = Path(d)
            conf(home).parent.mkdir(parents=True)
            conf(home).write_text('hl.config({ input = { kb_layout = "us", kb_variant = "" } })\n')
            self.assertEqual(run(home, keyboard="es")["status"], "done")
            self.assertIn('kb_layout = "es"', conf(home).read_text())
            self.assertEqual(run(home, keyboard="es")["status"], "already")

    def test_a_layout_of_your_own_is_left_alone(self):
        with tmpdir() as d:
            home = Path(d)
            conf(home).parent.mkdir(parents=True)
            conf(home).write_text('hl.config({ input = { kb_layout = "de" } })\n')
            run(home, keyboard="es")
            self.assertNotIn('kb_layout = "es"', conf(home).read_text())

    def test_nothing_when_the_system_is_us_or_unknown(self):
        for layout in ("", "us"):
            with tmpdir() as d:
                home = Path(d)
                run(home, keyboard=layout)
                self.assertEqual(conf(home).read_text().count("kb_layout = \"us\", kb_variant = \"\" } })"), 0)

    def test_the_variant_goes_with_it(self):
        with tmpdir() as d:
            home = Path(d)
            run(home, keyboard="es:cat")
            self.assertIn('kb_layout = "es", kb_variant = "cat"', conf(home).read_text())


class Wallpaper(unittest.TestCase):
    def test_hyprlands_wallpaper_is_turned_off(self):
        with tmpdir() as d:
            home = Path(d)
            conf(home).parent.mkdir(parents=True)
            conf(home).write_text('hl.config({ misc = { disable_hyprland_logo = false } })\n')
            run(home)
            self.assertIn("disable_hyprland_logo = true", conf(home).read_text().split(">>> sylphrena")[1])

    def test_left_alone_when_the_configuration_already_does_it(self):
        with tmpdir() as d:
            home = Path(d)
            conf(home).parent.mkdir(parents=True)
            conf(home).write_text('hl.config({ misc = { disable_hyprland_logo = true } })\n')
            run(home)
            self.assertNotIn("disable_splash_rendering", conf(home).read_text())
