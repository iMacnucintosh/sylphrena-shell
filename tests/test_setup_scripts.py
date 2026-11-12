"""setup-defaults.py and setup-kitty.py in a sandboxed HOME: what they write, and what they never touch."""
import json
import unittest
from pathlib import Path

from helpers import run_script, tmpdir


def status(proc):
    return json.loads(proc.stdout)["status"]


class Defaults(unittest.TestCase):
    def test_fresh_home_gets_the_defaults_once(self):
        with tmpdir() as d:
            home = Path(d)
            self.assertEqual(status(run_script("setup-defaults.py", ["--check"], home)), "needed")
            self.assertFalse((home / ".config/sylphrena/shell.json").exists())  # --check writes nothing
            self.assertEqual(status(run_script("setup-defaults.py", [], home)), "done")
            cfg = json.loads((home / ".config/sylphrena/shell.json").read_text())
            acts = cfg["activities"]["activities"]
            self.assertEqual([a["id"] for a in acts], ["principal"])
            self.assertEqual(acts[0]["workspaceCount"], 2)
            self.assertTrue(Path(acts[0]["wallpaper"]).is_file())  # the wallpaper that ships with the shell
            self.assertNotIn("@", acts[0]["wallpaper"])
            self.assertEqual(status(run_script("setup-defaults.py", [], home)), "seen")

    def test_nothing_personal_in_the_template(self):
        text = (Path(__file__).resolve().parent.parent / "assets/defaults/shell.json").read_text()
        for word in ("/home/", "weatherLocation", "favouriteApps", "provider", "lastList"):
            self.assertNotIn(word, text)

    def test_never_replaces_an_existing_configuration(self):
        with tmpdir() as d:
            home = Path(d)
            cfg = home / ".config/sylphrena/shell.json"
            cfg.parent.mkdir(parents=True)
            cfg.write_text('{"bar": {"dragThreshold": 5}}')
            self.assertEqual(status(run_script("setup-defaults.py", [], home)), "kept")
            self.assertEqual(status(run_script("setup-defaults.py", ["--force"], home)), "kept")
            self.assertEqual(json.loads(cfg.read_text()), {"bar": {"dragThreshold": 5}})

    def test_an_empty_json_object_counts_as_no_configuration(self):
        with tmpdir() as d:
            home = Path(d)
            cfg = home / ".config/sylphrena/shell.json"
            cfg.parent.mkdir(parents=True)
            cfg.write_text("{}")
            self.assertEqual(status(run_script("setup-defaults.py", [], home)), "done")

    def test_a_file_that_is_not_json_is_left_alone(self):
        with tmpdir() as d:
            home = Path(d)
            cfg = home / ".config/sylphrena/shell.json"
            cfg.parent.mkdir(parents=True)
            cfg.write_text("{broken")
            self.assertEqual(status(run_script("setup-defaults.py", [], home)), "kept")
            self.assertEqual(cfg.read_text(), "{broken")


class Kitty(unittest.TestCase):
    BLOCK = "# >>> sylphrena"

    def test_connects_kitty_idempotently_and_keeps_the_user_content(self):
        with tmpdir() as d:
            home = Path(d)
            conf = home / ".config/kitty/kitty.conf"
            conf.parent.mkdir(parents=True)
            conf.write_text("font_size 12\n")
            self.assertEqual(status(run_script("setup-kitty.py", ["--check"], home)), "needed")
            self.assertEqual(status(run_script("setup-kitty.py", [], home)), "done")
            text = conf.read_text()
            self.assertIn("font_size 12", text)
            self.assertIn(self.BLOCK, text)
            self.assertEqual(text.count("allow_remote_control yes"), 1)
            self.assertEqual((conf.parent / "kitty.conf.sylphrena-backup").read_text(), "font_size 12\n")
            self.assertEqual(status(run_script("setup-kitty.py", [], home)), "seen")
            run_script("setup-kitty.py", ["--force"], home)
            self.assertEqual(conf.read_text().count("allow_remote_control yes"), 1)

    def test_respects_a_remote_control_setting_of_the_user(self):
        with tmpdir() as d:
            home = Path(d)
            conf = home / ".config/kitty/kitty.conf"
            conf.parent.mkdir(parents=True)
            conf.write_text("allow_remote_control no\n")
            run_script("setup-kitty.py", [], home)
            text = conf.read_text()
            self.assertIn("allow_remote_control no", text)
            self.assertNotIn("allow_remote_control yes", text)


if __name__ == "__main__":
    unittest.main()
