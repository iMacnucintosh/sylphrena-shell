import json
import unittest
from pathlib import Path

from helpers import load, make_zip, manifest, tmpdir

inst = load("install-extension")


class Validation(unittest.TestCase):
    def check(self, files, links=None, builtin=None):
        with tmpdir() as d:
            z = make_zip(Path(d) / "x.zip", files, links)
            b = builtin or (Path(d) / "builtin")
            b.mkdir(exist_ok=True)
            return inst.inspect(str(z), str(b))

    def raises(self, files, links=None, builtin_ids=()):
        with tmpdir() as d:
            z = make_zip(Path(d) / "x.zip", files, links)
            b = Path(d) / "builtin"
            for i in builtin_ids:
                (b / i).mkdir(parents=True)
                (b / i / "manifest.json").write_text("{}")
            b.mkdir(exist_ok=True)
            with self.assertRaises(inst.Bad) as cm:
                inst.inspect(str(z), str(b))
            return str(cm.exception)

    def test_valid_at_the_root_and_in_its_folder(self):
        for prefix in ("", "demo/"):
            r = self.check({prefix + "manifest.json": manifest(description="Hi", requires={"sylphrena": ">=0.3.0"}),
                            prefix + "Service.qml": "x"})
            self.assertTrue(r["ok"])
            self.assertEqual((r["id"], r["version"], r["requires"]), ("demo", "0.1.0", ">=0.3.0"))
            self.assertFalse(r["system"])

    def test_reports_system_pieces(self):
        r = self.check({"manifest.json": manifest(system={"install": "system/install.sh"})})
        self.assertTrue(r["system"])

    def test_reads_the_catalogs_inside(self):
        r = self.check({"manifest.json": manifest(), "i18n/es.json": json.dumps({"A": "B", "bad": 3})})
        self.assertEqual(r["i18n"], {"es": {"A": "B"}})

    def test_rejects_unsafe_paths(self):
        self.assertIn("unsafe", self.raises({"manifest.json": manifest(), "../evil": "x"}))
        self.assertIn("unsafe", self.raises({"manifest.json": manifest(), "/etc/evil": "x"}))
        self.assertIn("unsafe", self.raises({"manifest.json": manifest(), "a\\b": "x"}))

    def test_rejects_links(self):
        self.assertIn("links", self.raises({"manifest.json": manifest()}, links={"link": "/etc/passwd"}))

    def test_rejects_bad_manifests(self):
        self.assertIn("manifest", self.raises({"Service.qml": "x"}))
        self.assertIn("manifest", self.raises({"manifest.json": "not json"}))
        self.assertIn("id", self.raises({"manifest.json": manifest(id="Bad Id")}))
        self.assertIn("id", self.raises({"manifest.json": manifest(id="../x")}))

    def test_rejects_an_id_the_shell_ships(self):
        self.assertIn("shipped", self.raises({"manifest.json": manifest()}, builtin_ids=("demo",)))

    def test_rejects_something_that_is_not_a_zip(self):
        with tmpdir() as d:
            f = Path(d) / "x.zip"
            f.write_text("hello")
            with self.assertRaises(inst.Bad):
                inst.inspect(str(f), d)


class InstallAndRemove(unittest.TestCase):
    def test_roundtrip_keeps_the_executable_bit_and_replaces_atomically(self):
        with tmpdir() as d:
            d = Path(d)
            (d / "user").mkdir()
            (d / "builtin").mkdir()
            z = make_zip(d / "x.zip", {"demo/manifest.json": manifest(), "demo/Service.qml": "v1"})
            self.assertTrue(inst.install(str(z), str(d / "user"), str(d / "builtin"))["ok"])
            self.assertEqual((d / "user/demo/Service.qml").read_text(), "v1")
            z2 = make_zip(d / "y.zip", {"demo/manifest.json": manifest(version="0.2.0"), "demo/Service.qml": "v2"})
            self.assertTrue(inst.install(str(z2), str(d / "user"), str(d / "builtin"))["ok"])
            self.assertEqual((d / "user/demo/Service.qml").read_text(), "v2")
            self.assertEqual(json.loads((d / "user/demo/manifest.json").read_text())["version"], "0.2.0")
            self.assertTrue(inst.remove("demo", str(d / "user"))["ok"])
            self.assertFalse((d / "user/demo").exists())

    def test_remove_refuses_what_is_not_an_extension_id(self):
        with tmpdir() as d:
            for bad in ("../etc", "a/b", "Demo", ""):
                with self.assertRaises(inst.Bad):
                    inst.remove(bad, d)


if __name__ == "__main__":
    unittest.main()
