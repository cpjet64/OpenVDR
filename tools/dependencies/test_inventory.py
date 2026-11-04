"""Checks the committed source inventory independently of network access."""
import hashlib
import json
from pathlib import Path
import re
import unittest

from cyclonedx import build_bom

ROOT = Path(__file__).resolve().parents[2]


class InventoryTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.inventory = json.loads((ROOT / "docs/components-cargo.json").read_text(encoding="utf-8"))
        cls.bom = json.loads((ROOT / "docs/components-cargo.cdx.json").read_text(encoding="utf-8"))

    def test_lock_checksum(self):
        actual = hashlib.sha256((ROOT / "Cargo.lock").read_bytes()).hexdigest()
        self.assertEqual(actual, self.inventory["lock"]["sha256"])

    def test_resolved_graphs_reference_known_unique_packages(self):
        for triple, graph in self.inventory["targets"].items():
            with self.subTest(target=triple):
                ids = [package["id"] for package in graph["packages"]]
                self.assertEqual(len(ids), len(set(ids)))
                nodes = graph["resolve"]["nodes"]
                self.assertEqual(set(ids), {node["id"] for node in nodes})
                for node in nodes:
                    self.assertLessEqual(set(node["dependencies"]), set(ids))

    def test_bom_graph_and_source_identity(self):
        self.assertEqual(self.bom, build_bom(self.inventory))
        refs = [item["bom-ref"] for item in self.bom["components"]]
        self.assertEqual(len(refs), len(set(refs)))
        for node in self.bom["dependencies"]:
            self.assertIn(node["ref"], refs)
            self.assertLessEqual(set(node["dependsOn"]), set(refs))

    def test_no_absolute_local_paths(self):
        for document in (self.inventory, self.bom):
            text = json.dumps(document)
            self.assertNotRegex(text, r"(?i)[a-z]:\\\\|file:///[^$]|/Users/|/home/")


if __name__ == "__main__":
    unittest.main()
