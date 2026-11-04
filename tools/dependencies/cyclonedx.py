"""Derive a source-level CycloneDX 1.5 BOM from resolved Cargo metadata."""
import hashlib


def reference(package_id):
    return "cargo-" + hashlib.sha256(package_id.encode("utf-8")).hexdigest()


def build_bom(inventory):
    packages = {}
    targets = {}
    edges = {}
    for triple, metadata in inventory["targets"].items():
        for package in metadata["packages"]:
            package_id = package["id"]
            packages[package_id] = package
            targets.setdefault(package_id, set()).add(triple)
        for node in metadata["resolve"]["nodes"]:
            edges.setdefault(node["id"], set()).update(node["dependencies"])
    components = []
    for package_id, package in sorted(packages.items()):
        item = {
            "type": "library", "bom-ref": reference(package_id),
            "name": package["name"], "version": package["version"],
            "properties": [
                {"name": "openvdr:cargo-id", "value": package_id},
                {"name": "openvdr:targets", "value": ",".join(sorted(targets[package_id]))},
            ],
        }
        if package.get("license"):
            item["licenses"] = [{"license": {"name": package["license"]}}]
        if package.get("description"):
            item["description"] = package["description"]
        components.append(item)
    return {
        "bomFormat": "CycloneDX", "specVersion": "1.5", "version": 1,
        "metadata": {"properties": [
            {"name": "openvdr:scope", "value": "Resolved Cargo source inputs; union of default workspace graphs, not an artifact or complete native SBOM"},
            {"name": "openvdr:cargo-lock-sha256", "value": inventory["lock"]["sha256"]},
        ]},
        "components": components,
        "dependencies": [
            {"ref": reference(package_id), "dependsOn": sorted(reference(dep) for dep in dependencies)}
            for package_id, dependencies in sorted(edges.items())
        ],
    }
