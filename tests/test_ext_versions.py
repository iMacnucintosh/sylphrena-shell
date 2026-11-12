import unittest

from helpers import load

ext = load("ext")


class Satisfies(unittest.TestCase):
    def test_comparators(self):
        ok = ext.satisfies
        self.assertTrue(ok("0.3.0", ">=0.2.0"))
        self.assertTrue(ok("0.3.0", ">=0.3.0 <1.0.0"))
        self.assertFalse(ok("0.2.9", ">=0.3.0"))
        self.assertFalse(ok("1.0.0", ">=0.3.0 <1.0.0"))
        self.assertTrue(ok("0.3.1", "=0.3.1"))
        self.assertFalse(ok("0.3.1", "=0.3.0"))
        self.assertTrue(ok("0.3.0", ">0.2.9"))
        self.assertTrue(ok("0.3.0", "<=0.3.0"))

    def test_empty_spec_or_unknown_version_passes(self):
        self.assertTrue(ext.satisfies("0.3.0", ""))
        self.assertTrue(ext.satisfies("", ">=9.0.0"))

    def test_a_spec_that_does_not_parse_never_passes(self):
        self.assertFalse(ext.satisfies("0.3.0", "newer"))
        self.assertFalse(ext.satisfies("0.3.0", ">=0.2.0 banana"))

    def test_version_with_a_v_and_missing_parts(self):
        self.assertTrue(ext.satisfies("v0.3", ">=0.3.0"))
        self.assertTrue(ext.satisfies("0.3.0", ">=0.3"))


class Incompatibility(unittest.TestCase):
    shell = {"running": True, "shellVersion": "0.3.0", "apiVersion": 1}

    def test_compatible(self):
        self.assertEqual(ext.incompatibility({"apiVersion": 1, "requires": ">=0.2.0"}, self.shell), "")

    def test_newer_api(self):
        self.assertIn("newer", ext.incompatibility({"apiVersion": 2}, self.shell))

    def test_version_too_low(self):
        why = ext.incompatibility({"apiVersion": 1, "requires": ">=0.4.0"}, self.shell)
        self.assertIn(">=0.4.0", why)
        self.assertIn("0.3.0", why)

    def test_a_shell_that_is_not_running_says_nothing(self):
        down = {"running": False, "shellVersion": "", "apiVersion": 1}
        self.assertEqual(ext.incompatibility({"apiVersion": 9, "requires": ">=9"}, down), "")


class DataPaths(unittest.TestCase):
    def test_only_inside_config_and_state(self):
        paths = [str(p) for p in ext.data_paths("demo", {"data": [
            "state:demo.json", "config:vpn/x.conf", "state:../escape", "state:/abs", "other:thing", "state:", "nothing"]})]
        self.assertTrue(any(p.endswith("extensions/demo.json") for p in paths))
        self.assertTrue(any(p.endswith(".local/state/sylphrena/demo.json") or p.endswith("sylphrena/demo.json") for p in paths))
        self.assertFalse(any("escape" in p or "/abs" in p or "thing" in p for p in paths))


class Hardening(unittest.TestCase):
    def test_purge_never_takes_what_the_shell_owns(self):
        paths = [str(p) for p in ext.data_paths("demo", {"data": [
            "config:shell.json", "config:extensions", "config:keybinds.json", "state:scheme.json", "state:theme/kitty.conf",
            "state:demo.json"]})]
        self.assertFalse(any(p.endswith(("shell.json", "keybinds.json", "scheme.json", "kitty.conf"))
                             or p.endswith("sylphrena/extensions") for p in paths))
        self.assertTrue(any(p.endswith("demo.json") and "/state/" in p.replace(".local/state", "/state/") for p in paths))

    def test_remove_refuses_something_that_is_not_an_id(self):
        import io
        from contextlib import redirect_stderr

        with redirect_stderr(io.StringIO()):
            self.assertEqual(ext.cmd_remove("../../etc"), 2)


if __name__ == "__main__":
    unittest.main()
