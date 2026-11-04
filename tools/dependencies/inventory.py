#!/usr/bin/env python3
"""Record Cargo's locked, target-filtered metadata without compiling anything."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import tomllib
from cyclonedx import build_bom

ROOT = Path(__file__).resolve().parents[2]
TARGETS = (
    "x86_64-pc-windows-msvc", "x86_64-unknown-linux-gnu",
    "aarch64-apple-darwin", "x86_64-apple-darwin", "aarch64-linux-android",
)


def lock_inventory():
    raw = (ROOT / "Cargo.lock").read_bytes()
    lock = tomllib.loads(raw.decode("utf-8"))
    return {
        "sha256": hashlib.sha256(raw).hexdigest(),
        "packages": sorted(lock["package"], key=lambda p: (p["name"], p["version"], p.get("source", ""))),
    }


def target_inventory(target, offline):
    command = ["cargo", "metadata", "--locked", "--format-version", "1", "--filter-platform", target]
    if offline:
        command.append("--offline")
    flags = subprocess.CREATE_NO_WINDOW if hasattr(subprocess, "CREATE_NO_WINDOW") else 0
    result = subprocess.run(command, cwd=ROOT, capture_output=True, encoding="utf-8", check=True, creationflags=flags)
    data = json.loads(result.stdout)
    # Paths and package IDs contain machine-specific absolute paths. Replace the
    # workspace prefix consistently, preserving the relationships in the graph.
    normalized = json.dumps(data, ensure_ascii=False).replace(str(ROOT).replace("\\", "/"), "${WORKSPACE}")
    normalized = normalized.replace(str(ROOT).replace("\\", "\\\\"), "${WORKSPACE}")
    data = json.loads(normalized)
    for package in data["packages"]:
        package.pop("manifest_path", None)
        package.pop("license_file", None)
        package.pop("readme", None)
        for target_item in package["targets"]:
            target_item.pop("src_path", None)
    data.pop("workspace_root", None)
    data.pop("target_directory", None)
    data.pop("build_directory", None)
    return data


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--offline", action="store_true")
    parser.add_argument("--output", type=Path, default=ROOT / "docs/components-cargo.json")
    parser.add_argument("--bom", type=Path, default=ROOT / "docs/components-cargo.cdx.json")
    args = parser.parse_args()
    inventory = {"schema": "openvdr-cargo-inventory-1", "lock": lock_inventory(), "targets": {}}
    for target in TARGETS:
        print(f"Resolving {target}", flush=True)
        inventory["targets"][target] = target_inventory(target, args.offline)
    args.output.write_text(json.dumps(inventory, indent=2, sort_keys=True, ensure_ascii=False) + "\n", encoding="utf-8")
    args.bom.write_text(json.dumps(build_bom(inventory), indent=2, sort_keys=True, ensure_ascii=False) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
